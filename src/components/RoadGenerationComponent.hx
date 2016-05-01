package components;

import luxe.Component;
import luxe.Vector;
import luxe.Color;
import phoenix.geometry.*;
import com.hypertrifle.*;

class RoadGenerationComponent extends Component {

	private var segmentLength:Float = 200;
	private var trackLength:Float = -1;
	private var roadWidth:Float = 2000;
	private var fieldOfView:Float   = 100;                     // angle (degrees) for field of view
	private var cameraHeight:Float  = 1000;                    // z height of camera
	private var cameraDepth:Float   = -1;                    // z distance camera is from screen (computed)
	private var drawDistance:Int = 500;
	private var postion:Float = 0;
	private var resolution:Float;
	private var playerZ:Float;
    private var position:Int = 0;                       // current camera Z position (add playerZ to get player's absolute Z position)
    private var playerX:Float = 0;                       // player x offset from center of road (-1 to 1 to stay independent of roadWidth)
    private var rumbleLength:Float = 3;                       // player x offset from center of road (-1 to 1 to stay independent of roadWidth)
    private var speed:Float = 12000;
    private var fogDensity:Float    = 5;                       // exponential fog density
    var width:Int;
    var height:Int;


    private var segments:Array<Segment>;
    private var geometries:Array<Geos>;

    private var geomertyPoolSize:Int = 100;

    override function init() {
    	width = Luxe.screen.w;
    	height = Luxe.screen.h;

    }

    function initPolies(){
    	geometries = new Array<Geos>();
    	for(i in 0...geomertyPoolSize){
    		geometries.push({
    			backgroundPoly: initPoly(i,1),
    			roadPoly: initPoly(i,0)
    			});
    	}
    }


    function initPoly(index:Int,type:Int):Geometry {
    	var color:Color = null;
    	if(type ==0){
    		//road type
    		color = new Color().rgb(0xff4b03);
    		} else if(type ==1){
			//background type
			color = new Color().rgb(0x21a01b);


		}

		return Luxe.draw.poly({
			solid : true,
			color: color,
			points : [
				new Vector(0, 0),
				new Vector(Luxe.screen.width, 0),
				new Vector(Luxe.screen.width, 0),
				new Vector(0, 0)
			],
			visible: false
		});
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

        //clear visible segments
        for(n in 0...geometries.length){
        	geometries[n].roadPoly.visible = false;
        	geometries[n].backgroundPoly.visible = false;
        }


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
			renderSegment(segment,width,n);
			maxy = Math.floor(segment.p2.screen.y);
        }
    }

    function fog(distance:Float, density:Float) { 
    	return 1 / (Math.pow(2.71828, (distance * distance * density))); 
    }

    function renderSegment(segmentIn:Segment, width:Float, index:Int){

    	if(index >= geometries.length){
    		return; //run out of availible polys
    	}

    	//set these geos to visible
    	var geomerty = geometries[index];
    	geomerty.roadPoly.visible = true;
    	geomerty.backgroundPoly.visible = true;

    	//set the coulours
    	geomerty.roadPoly.color = (Math.floor(segmentIn.index/rumbleLength)%2 == 0) ? new Color().rgb(0x0f5848) : new Color().rgb(0x0f4838);
    	geomerty.backgroundPoly.color = (Math.floor(segmentIn.index/rumbleLength)%2 == 0) ? new Color().rgb(0x00da76) : new Color().rgb(0x00ca66);

    	//set alpha based on fog value
    	geomerty.roadPoly.color.a = segmentIn.fog;
    	geomerty.backgroundPoly.color.a = segmentIn.fog;


    	var x1:Float = segmentIn.p1.screen.x;
    	var y1:Float = segmentIn.p1.screen.y;
    	var w1:Float = segmentIn.p1.screen.w;
    	var x2:Float = segmentIn.p2.screen.x;
    	var y2:Float = segmentIn.p2.screen.y;
    	var w2:Float = segmentIn.p2.screen.w;

    	geomerty.roadPoly.vertices[0].pos.x = x1-w1;
    	geomerty.roadPoly.vertices[0].pos.y = y1;

    	geomerty.roadPoly.vertices[1].pos.x = x1+w1;
    	geomerty.roadPoly.vertices[1].pos.y = y1;

    	geomerty.roadPoly.vertices[2].pos.x = x2+w2;
    	geomerty.roadPoly.vertices[2].pos.y = y2;

    	geomerty.roadPoly.vertices[3].pos.x = x2-w2;
    	geomerty.roadPoly.vertices[3].pos.y = y2;


    	//set background
    	for(i in 0...4){
    		geomerty.backgroundPoly.vertices[i].pos.y = (i <2) ? y1: y2;
    	}

    }


    override function onreset() {
        //called when the scene starts or restarts
        trace("reset road gen component");
        cameraDepth            = 1 / Math.tan((fieldOfView/2) * Math.PI/180);
        playerZ                = (cameraHeight * cameraDepth);
        resolution             = height/480;

        initRoad();
        initPolies();

    }

    function initRoad() {
    	segments = new Array<Segment>();
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
}

//Geos - these contain the geometries for rendering one band.
typedef Geos = {
	var roadPoly:Geometry;
	var backgroundPoly:Geometry;
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




