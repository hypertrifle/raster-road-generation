package components;

import luxe.Component;
import luxe.Vector;
import luxe.Color;
import phoenix.geometry.*;
import com.hypertrifle.*;

class RoadGenerationComponent extends Component {

	private var segmentLength:Float = 300;
	private var trackLength:Float = -1;
	private var roadWidth:Float = 2000;
	private var fieldOfView:Float   = 120;                     // angle (degrees) for field of view
	private var cameraHeight:Float  = 1000;                    // z height of camera
	private var cameraDepth:Float   = -1;                    // z distance camera is from screen (computed)
	private var drawDistance:Int = 700;
	private var postion:Float = 0;
	private var resolution:Float;
	private var playerZ:Float;
    private var position:Int = 0;                       // current camera Z position (add playerZ to get player's absolute Z position)
    private var playerX:Float = 0;                       // player x offset from center of road (-1 to 1 to stay independent of roadWidth)
    public var rumbleLength:Float = 5;                       // player x offset from center of road (-1 to 1 to stay independent of roadWidth)
    private var speed:Float = 12000;
    private var fogDensity:Float    = 5;                       // exponential fog density
    var width:Int;
    var height:Int;


    public var segmentsToRender:Array<Segment>;


    private var segments:Array<Segment>;

    override function init() {
    	width = Luxe.screen.w;
    	height = Luxe.screen.h;

    }


	function project(p:SegmentPoint, cameraX:Float, cameraY:Float, cameraZ:Float, cameraDepth:Float, width:Float, height:Float, roadWidth:Float) {
		p.camera.x     = p.world.x - cameraX;
		p.camera.y     = p.world.y - cameraY;
		p.camera.z     = p.world.z - cameraZ;
		p.screen.scale = cameraDepth/p.camera.z;
		p.screen.x     = Math.round((width/2)  + (p.screen.scale * p.camera.x  * width/2));
		p.screen.y     = Math.round((height/2) - (p.screen.scale * p.camera.y  * height/2));
		p.screen.w     = Math.round(             (p.screen.scale * roadWidth   * width/2));
		return p;
	}

	function findSegment(z) {
		return segments[Math.floor(z/segmentLength) % segments.length];
	}


    override function update(dt:Float) {


        // progress through level
        position = HTUtil.incrementWithWrap(position, dt * speed, trackLength);

        //get the current segment the player is on and 
        var baseSegment = findSegment(position);
        var basePercent = HTUtil.percentRemaining(position, Math.floor(segmentLength));
        var playerSegment = findSegment(Math.floor(position+playerZ));
        var playerPercent = HTUtil.percentRemaining(position+playerZ, segmentLength);
        var playerY       = HTUtil.interpolate(playerSegment.p1.world.y, playerSegment.p2.world.y, playerPercent);
        var maxy          = height;


        var dx = - (baseSegment.curve * basePercent);
        var x  = 0;

        var segment:Segment;

        var updatedSegments:Int =0;

        this.entity.get('road_render').clearRenderer();

        //segmentsToRender = segmentsToRender.splice(0,0);

        for(n in 0...drawDistance) {
        	//get first segment
        	segment = segments[(baseSegment.index + n) % segments.length];

        	
        	segment.looped = (segment.index < baseSegment.index)? true : false;
			segment.fog    = fog(n/drawDistance, fogDensity);

			// project our points
			segment.p1 = project(segment.p1, (playerX * roadWidth) - x, playerY + cameraHeight, position - (segment.looped ? trackLength : 0), cameraDepth, width, height, roadWidth);
			segment.p2 = project(segment.p2, (playerX * roadWidth) - x - dx, playerY + cameraHeight, position - (segment.looped ? trackLength : 0), cameraDepth, width, height, roadWidth);

			//
			x  += Math.floor(dx);
			dx += segment.curve;


			if ((segment.p1.camera.z <= cameraDepth)         || // behind us
            (segment.p2.screen.y >= segment.p1.screen.y) || // back face cull
            (segment.p2.screen.y >= maxy)) {
			    continue; // clip by (already rendered) segment
			    //return;
			}   

			updatedSegments ++;
			segment.n = n;
			//segmentsToRender.push(segment);
			this.entity.get('road_render').renderSegment(segment,width,n);
			maxy = Math.floor(segment.p2.screen.y);
        }
    }

    function fog(distance:Float, density:Float) { 
    	return 1 / (Math.pow(2.71828, (distance * distance * density))); 
    }



    override function onreset() {
        //called when the scene starts or restarts
        trace("reset road gen component");
        setFov(fieldOfView);
        playerZ                = (cameraHeight * cameraDepth);
        resolution             = height/480;

        initRoad();

    }

    public function setFov(newValue:Float):Float{
    	fieldOfView = newValue;
    	cameraDepth= 1 / Math.tan((fieldOfView/2) * Math.PI/180);
    	return fieldOfView;

    }

    function initRoad() {
    	segments = new Array<Segment>();
    	segmentsToRender = new Array<Segment>();
    	//lets just generate a random road, this could be done with a seed?
		for(i in 0...100){ 
			addRoad(HTUtil.randomInt(100),HTUtil.randomInt(100), HTUtil.randomInt(100), HTUtil.randomInt(20)-10, HTUtil.randomInt(150)-75);
		}
		//save the track length based on what we just built
		trackLength = segments.length * segmentLength;


	}

	function lastSegmentY() {
		//just returns the last segments top y value.
	  return (segments.length == 0) ? 0 : segments[segments.length-1].p2.world.y;
	}

	function addSegment(curve:Float,y:Float) {
		//adds a segment to the track
		var n = segments.length;
		segments.push({
			looped: false,
			fog: 1,
			curve: curve,
  	       	index: n,
            p1: {world:{x:0,y:lastSegmentY(),z:n*segmentLength,w:0,scale:0},camera:{x:0,y:0,z:0,w:0,scale:0},screen:{x:0,y:0,z:0,w:0,scale:0}}, //n   *segmentLength,
  	        p2: {world:{x:0,y:y,z:(n+1)*segmentLength,w:0,scale:0},camera:{x:0,y:0,z:0,w:0,scale:0},screen:{x:0,y:0,z:0,w:0,scale:0}}, //n   *segmentLength,
  	    	n:0
  	    });
	}

	function addRoad(enter:Int, hold:Int, leave:Int, curve:Int, y:Int) {
		var startY   = lastSegmentY();
		var endY     = startY + (y * segmentLength);
		var n;
		var total = enter + hold + leave;
		for(n in 0...enter)
			addSegment(HTUtil.easeIn(0, curve, n/enter), HTUtil.easeInOut(Math.floor(startY), Math.floor(endY), n/total));
		for(n in 0...hold)
			addSegment(curve, HTUtil.easeInOut(startY, endY, (enter+n)/total));
		for(n in 0...leave)
			addSegment(HTUtil.easeInOut(curve, 0, Math.floor(n/leave)),  HTUtil.easeInOut(startY, endY, (enter+hold+n)/total));
	}
}


// a segment represents on band of the track
typedef Segment = {
	var p1:SegmentPoint;
	var p2:SegmentPoint;
	var index:Int;
	var looped:Bool;
	var fog:Float;
	var curve:Float;
	var n:Int;
}


//used to calculate the projection of the track.
typedef SegmentPoint = {
	var world:Coord;
	var camera:Coord;
	var screen:Coord;
}

//generic co-ord object that stores with and scale as well.
typedef Coord = {
	var x:Float;
	var y:Float;
	var z:Float;
	var w:Float;
	var scale:Float;
}




