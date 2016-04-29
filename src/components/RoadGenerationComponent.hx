package components;

import luxe.Component;
import luxe.Vector;
import luxe.Color;
import phoenix.geometry.*;

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

        //called when initialising the component
        resetGame();

    }

    function resetGame(){
    	trace("reset game");
    	cameraDepth            = 1 / Math.tan((fieldOfView/2) * Math.PI/180);
    	playerZ                = (cameraHeight * cameraDepth);
    	resolution             = height/480;

    	initRoad();
    	initPolies();
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
				new Vector(0, 0),
				new Vector(0, 0),
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

    function progressPosition(start:Float, increment:Float, max:Float):Int { // with looping
    	var result = start + increment;
    	while (result >= max)
    	result -= max;
    	while (result < 0)
    	result += max;
    	return Math.floor(result);
    }


    function accelerate(v:Float, accel:Float, dt:Float):Float      { return v + (accel * dt);}
    function interpolate(a:Float,b:Float,percent:Float):Float       { return a + (b-a)*percent;}


    override function update(dt:Float) {

        //clear visible segments
        for(n in 0...geometries.length){
        	geometries[n].roadPoly.visible = false;
        	geometries[n].backgroundPoly.visible = false;
        }



        position = progressPosition(position, dt * speed, trackLength);

        var baseSegment = findSegment(position);
        var basePercent = percentRemaining(position, Math.floor(segmentLength));
        var playerSegment = findSegment(Math.floor(position+playerZ));
        var playerPercent = percentRemaining(position+playerZ, segmentLength);
        var playerY       = interpolate(playerSegment.p1.world.y, playerSegment.p2.world.y, playerPercent);
        var maxy          = height;


        var dx = - (baseSegment.curve * basePercent);
        var x  = 0;





        var maxy = height;
        var segment:Segment;

        var updatedSegments:Int =0;

        for(n in 0...drawDistance) {

        	segment = segments[(baseSegment.index + n) % segments.length];

        	
        	segment.looped = (segment.index < baseSegment.index)? true : false;
			segment.fog    = fog(n/drawDistance, fogDensity);

			segment.p1 = project(segment.p1, (playerX * roadWidth) - x, playerY + cameraHeight, position - (segment.looped ? trackLength : 0), cameraDepth, width, height, roadWidth);
			segment.p2 = project(segment.p2, (playerX * roadWidth) - x - dx, playerY + cameraHeight, position - (segment.looped ? trackLength : 0), cameraDepth, width, height, roadWidth);

			x  += Math.floor(dx);
			dx += segment.curve;


			if ((segment.p1.camera.z <= cameraDepth)         || // behind us
            (segment.p2.screen.y >= segment.p1.screen.y) || // back face cull
            (segment.p2.screen.y >= maxy)) {
			    continue; // clip by (already rendered) segment
			    return;
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

    	var geomerty = geometries[index];
    	geomerty.roadPoly.visible = true;
    	geomerty.backgroundPoly.visible = true;


    	geomerty.roadPoly.color = (Math.floor(segmentIn.index/rumbleLength)%2 == 0) ? new Color().rgb(0x0f5848) : new Color().rgb(0x0f4838);
    	geomerty.backgroundPoly.color = (Math.floor(segmentIn.index/rumbleLength)%2 == 0) ? new Color().rgb(0x00da76) : new Color().rgb(0x00ca66);

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



    	geomerty.backgroundPoly.vertices[0].pos.x = 0;
    	geomerty.backgroundPoly.vertices[0].pos.y = y1;

    	geomerty.backgroundPoly.vertices[1].pos.x = Luxe.screen.width;
    	geomerty.backgroundPoly.vertices[1].pos.y = y1;

    	geomerty.backgroundPoly.vertices[2].pos.x = Luxe.screen.width;
    	geomerty.backgroundPoly.vertices[2].pos.y = y2;

    	geomerty.backgroundPoly.vertices[3].pos.x = 0;
    	geomerty.backgroundPoly.vertices[3].pos.y = y2;


    }


    override function onreset() {
        //called when the scene starts or restarts
    }

    function clearRender(){
    	Luxe.renderer.clear(new Color().rgb(0x008800));
    }

    function randomInt(max:Int):Int{
    	return Math.floor(Math.random()*max);
    }


    function initRoad() {
    	segments = new Array<Segment>();

    		for(i in 0...100){ 
    			addRoad(randomInt(100),randomInt(100), randomInt(100), randomInt(20)-10, randomInt(150)-75);
    		}


    		/*addLowRollingHills(ROAD_LENGTH_SHORT, ROAD_HILL_MEDIUM);
    		addSCurves();
    		addLowRollingHills(ROAD_LENGTH_SHORT, ROAD_HILL_MEDIUM);
    		addCurve(ROAD_LENGTH_MEDIUM, ROAD_CURVE_MEDIUM);
    		addLowRollingHills(ROAD_LENGTH_SHORT, ROAD_HILL_MEDIUM);
    		addStraight(ROAD_LENGTH_MEDIUM);
    		addSCurves();
    		addCurve(ROAD_LENGTH_LONG, -ROAD_CURVE_MEDIUM);
    		addLowRollingHills(ROAD_LENGTH_SHORT, ROAD_HILL_MEDIUM);
    		addStraight(ROAD_LENGTH_MEDIUM);
    		addSCurves();
    		addCurve(ROAD_LENGTH_LONG, -ROAD_CURVE_EASY);*/


    		trackLength = segments.length * segmentLength;


    	}

    	function lastY() {
    	  return (segments.length == 0) ? 0 : segments[segments.length-1].p2.world.y;
    	}

    	function addSegment(curve:Float,y:Float) {
    		var n = segments.length;
    		segments.push({
    			looped: false,
    			fog: 1,
    			curve: curve,
	  	       index: n, //use this with the segments depth.
	             p1: {world:{x:0,y:lastY(),z:n*segmentLength,w:0,scale:0},camera:{x:0,y:0,z:0,w:0,scale:0},screen:{x:0,y:0,z:0,w:0,scale:0}}, //n   *segmentLength,
	  	       p2: {world:{x:0,y:y,z:(n+1)*segmentLength,w:0,scale:0},camera:{x:0,y:0,z:0,w:0,scale:0},screen:{x:0,y:0,z:0,w:0,scale:0}}, //n   *segmentLength,
	  	       //backgroundPoly: initPoly(n,1),
	  	       //roadPoly: initPoly(n,0)

	  	       });
    	}

    	function addRoad(enter:Int, hold:Int, leave:Int, curve:Int, y:Int) {
    		var startY   = lastY();
    		var endY     = startY + (y * segmentLength);

    		var n;
    		var total = enter + hold + leave;
    		for(n in 0...enter)
    		addSegment(easeIn(0, curve, n/enter), easeInOut(Math.floor(startY), Math.floor(endY), n/total));
    		for(n in 0...hold)
    		addSegment(curve, easeInOut(startY, endY, (enter+n)/total));
    		for(n in 0...leave)
    		addSegment(easeInOut(curve, 0, Math.floor(n/leave)),  easeInOut(startY, endY, (enter+hold+n)/total));
    	}

    	function easeIn(a:Float,b:Float,percent:Float):Float{ return a + (b-a)*Math.pow(percent,2);                           }
    	function easeOut(a:Float,b:Float,percent:Float):Float{ return a + (b-a)*(1-Math.pow(1-percent,2));                     }
    	function easeInOut(a:Float,b:Float,percent:Float):Float{ return a + (b-a)*((-Math.cos(percent*Math.PI)/2) + 0.5);        }
    	function percentRemaining(n:Float, total:Float):Float          { return (n%total)/total;                           }



    	function addStraight(num) {
    		addRoad(num, num, num, 0,0);
    	}

    	function addCurve(num, curve) {
    		addRoad(num, num, num, curve,0);
    	}

    	function addHill(num, height) {
    	      addRoad(num, num, num, 0, height);
	    }

	    function addLowRollingHills(num, height) {
	          addRoad(num, num, num,  0,  Math.floor(height/2));
	          addRoad(num, num, num,  0, -height);
	          addRoad(num, num, num,  0,  height);
	          addRoad(num, num, num,  0,  0);
	          addRoad(num, num, num,  0,  Math.floor(height/2));
	          addRoad(num, num, num,  0,  0);
        }



    	function addSCurves() {
    		addRoad(ROAD_LENGTH_SHORT, ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM,  -ROAD_CURVE_EASY,0);
    		addRoad(ROAD_LENGTH_SHORT, ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM,   ROAD_CURVE_MEDIUM,0);
    		addRoad(ROAD_LENGTH_SHORT, ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM,   ROAD_CURVE_EASY,0);
    		addRoad(ROAD_LENGTH_SHORT, ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM,  -ROAD_CURVE_EASY,0);
    		addRoad(ROAD_LENGTH_SHORT, ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM,  -ROAD_CURVE_MEDIUM,0);
    	}



    	public static inline var ROAD_LENGTH_NONE:Float = 0;
    	public static inline var ROAD_LENGTH_SHORT:Float = 25;
    	public static inline var ROAD_LENGTH_MEDIUM:Float = 50;
    	public static inline var ROAD_LENGTH_LONG:Float = 100;

    	public static inline var ROAD_CURVE_NONE:Float = 0;
    	public static inline var ROAD_CURVE_EASY:Float = 2;
    	public static inline var ROAD_CURVE_MEDIUM:Float = 4;
    	public static inline var ROAD_CURVE_HARD:Float = 6;


    	public static inline var ROAD_HILL_NONE:Float = 0;
    	public static inline var ROAD_HILL_LOW:Float = 20;
    	public static inline var ROAD_HILL_MEDIUM:Float = 40;
    	public static inline var ROAD_HILL_HIGH:Float = 60;

    	/*
    	HILL:   { NONE: 0, LOW:    20, MEDIUM:  40, HIGH:   60 },
    	*/

    }

    typedef Segment = {
    	var p1:SegmentPoint;
    	var p2:SegmentPoint;
    	var index:Int;
	//var roadPoly:Geometry;
	//var backgroundPoly:Geometry;
	var looped:Bool;
	var fog:Float;
	var curve:Float;
}

typedef Geos = {
	var roadPoly:Geometry;
	var backgroundPoly:Geometry;
}

typedef SegmentPoint = {
	var world:Coord;
	var camera:Coord;
	var screen:Coord;
}

typedef Coord = {
	var x:Float;
	var y:Float;
	var z:Float;
	var w:Float;
	var scale:Float;
}




