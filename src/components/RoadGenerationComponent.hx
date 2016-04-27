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
	private var drawDistance:Int = 300;
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

    override function init() {
        width = Luxe.screen.w;
        height = Luxe.screen.h;

        //called when initialising the component
        resetGame();  //initRoad();

    }

    function resetGame(){
    	trace("reset game");
        cameraDepth            = 1 / Math.tan((fieldOfView/2) * Math.PI/180);
        playerZ                = (cameraHeight * cameraDepth);
        resolution             = height/480;

        initRoad();
    }


    function initPoly(index:Int,type:Int):Geometry {
    	var color:Color = null;
    	if(type ==0){
    		//road type
    		color = (Math.floor(index/rumbleLength)%2 == 0) ? new Color().rgb(0xff4b03) : new Color().rgb(0xee4b03);
		} else if(type ==1){
			//background type
			color = (Math.floor(index/rumbleLength)%2 == 0) ? new Color().rgb(0x21a01b) : new Color().rgb(0x21801b);



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
        p.camera.x     = 0 - cameraX;
        p.camera.y     = 0 - cameraY;
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

    override function update(dt:Float) {
        //called every frame for you
        //position = Util.increase(position, dt * speed, trackLength);

        //clear visible segments
        for(i in 0...segments.length){
        	segments[i].roadPoly.visible = false;
        	segments[i].backgroundPoly.visible = false;
        }

        position = progressPosition(position, dt * speed, trackLength);

        var baseSegment = findSegment(position);
        var basePercent = percentRemaining(position, Math.floor(segmentLength));
        var dx = - (baseSegment.curve * basePercent);
        var x  = 0;

        var maxy        = height;
        var segment:Segment;

        var updatedSegments:Int =0;

        for(n in 0...drawDistance) {
               segment = segments[(baseSegment.index + n) % segments.length];
        	   //segment.roadPoly.visible = false;
        	   //segment.backgroundPoly.visible = false;


               segment.looped = (segment.index < baseSegment.index)? true : false;
               //segment.fog    = fog(n/drawDistance, fogDensity);

               segment.p1 = project(segment.p1, (playerX * roadWidth) - x, cameraHeight, position - (segment.looped ? trackLength : 0), cameraDepth, width, height, roadWidth);
               segment.p2 = project(segment.p2, (playerX * roadWidth) - x - dx, cameraHeight, position - (segment.looped ? trackLength : 0), cameraDepth, width, height, roadWidth);
               
               x  += Math.floor(dx);
               dx += segment.curve;


               if ((segment.p1.camera.z <= cameraDepth) || (segment.p2.screen.y >= maxy)) {
                    continue; // clip by (already rendered) segment
                    return;
               }   

               updatedSegments ++;
                      

                renderSegment(segment,width);

               //render segment
               /*Render.segment(width, lanes,
                                      segment.p1.screen.x,
                                      segment.p1.screen.y,
                                      segment.p1.screen.w,
                                      segment.p2.screen.x,
                                      segment.p2.screen.y,
                                      segment.p2.screen.w,
                                      segment.fog,
                                      segment.color);
                */


               maxy = Math.floor(segment.p2.screen.y);


           }

        //clearRender();

        //movePoints();

        //trace("render complete: "+ updatedSegments);
    }

    function fog(distance:Float, density:Float) { 
    	return 1 / (Math.pow(2.71828, (distance * distance * density))); 
    }

    function renderSegment(segment:Segment, width:Float){
        //trace("render segment");

        if(Math.abs(segment.p1.screen.y - segment.p2.screen.y) < 1){
        	trace("skipping small geometry");
        	return;
        }

        segment.roadPoly.visible = true;
        segment.backgroundPoly.visible = true;
        segment.roadPoly.color.a = segment.fog;
        segment.backgroundPoly.color.a = segment.fog;

        var x1:Float = segment.p1.screen.x;
        var y1:Float = segment.p1.screen.y;
        var w1:Float = segment.p1.screen.w;
        var x2:Float = segment.p2.screen.x;
        var y2:Float = segment.p2.screen.y;
        var w2:Float = segment.p2.screen.w;

        segment.roadPoly.vertices[0].pos.x = x1-w1;
        segment.roadPoly.vertices[0].pos.y = y1;
        
        segment.roadPoly.vertices[1].pos.x = x1+w1;
        segment.roadPoly.vertices[1].pos.y = y1;

        segment.roadPoly.vertices[2].pos.x = x2+w2;
        segment.roadPoly.vertices[2].pos.y = y2;

        segment.roadPoly.vertices[3].pos.x = x2-w2;
        segment.roadPoly.vertices[3].pos.y = y2;



        segment.backgroundPoly.vertices[0].pos.x = 0;
        segment.backgroundPoly.vertices[0].pos.y = y1;

        segment.backgroundPoly.vertices[1].pos.x = Luxe.screen.width;
        segment.backgroundPoly.vertices[1].pos.y = y1;

        segment.backgroundPoly.vertices[2].pos.x = Luxe.screen.width;
        segment.backgroundPoly.vertices[2].pos.y = y2;

        segment.backgroundPoly.vertices[3].pos.x = 0;
        segment.backgroundPoly.vertices[3].pos.y = y2;


    }


    /*function renderSegmentOld(width, lanes, x1, y1, w1, x2, y2, w2, fog, color) {

        var r1 = Render.rumbleWidth(w1, lanes),
            r2 = Render.rumbleWidth(w2, lanes),
            l1 = Render.laneMarkerWidth(w1, lanes),
            l2 = Render.laneMarkerWidth(w2, lanes),
            lanew1, lanew2, lanex1, lanex2, lane;
        
        ctx.fillStyle = color.grass;
        ctx.fillRect(0, y2, width, y1 - y2);
        
        Render.roadPolygon(ctx, x1-w1-r1, y1, x1-w1, y1, x2-w2, y2, x2-w2-r2, y2, color.rumble);
        Render.roadPolygon(ctx, x1+w1+r1, y1, x1+w1, y1, x2+w2, y2, x2+w2+r2, y2, color.rumble);

        Render.roadPolygon(ctx, x1-w1,    y1, x1+w1, y1, x2+w2, y2, x2-w2,    y2, color.road);
        
        if (color.lane) {
          lanew1 = w1*2/lanes;
          lanew2 = w2*2/lanes;
          lanex1 = x1 - w1 + lanew1;
          lanex2 = x2 - w2 + lanew2;
          for(lane = 1 ; lane < lanes ; lanex1 += lanew1, lanex2 += lanew2, lane++)
            Render.roadPolygon(ctx, lanex1 - l1/2, y1, lanex1 + l1/2, y1, lanex2 + l2/2, y2, lanex2 - l2/2, y2, color.lane);
        }
        
        Render.fog(ctx, 0, y1, width, y2-y1, fog);
      }*/

    override function onreset() {
        //called when the scene starts or restarts
    }

    function clearRender(){
    	Luxe.renderer.clear(new Color().rgb(0x008800));
    }

    function movePoints(){
    	//ploy1.vertices[0].pos.x += 1;
    }

    function initRoad() {
    	segments = new Array<Segment>();

    	//for(var n = 0 ; n < 500 ; n++) { // arbitrary road length
    	addStraight(Math.floor(ROAD_LENGTH_SHORT/4));
    	addSCurves();
    	addStraight(ROAD_LENGTH_LONG);
    	addCurve(ROAD_LENGTH_MEDIUM, ROAD_CURVE_MEDIUM);
    	addCurve(ROAD_LENGTH_LONG, ROAD_CURVE_MEDIUM);
    	addStraight(ROAD_LENGTH_MEDIUM);
    	addSCurves();
    	addCurve(ROAD_LENGTH_LONG, -ROAD_CURVE_MEDIUM);
    	addCurve(ROAD_LENGTH_LONG, ROAD_CURVE_MEDIUM);
    	addStraight(ROAD_LENGTH_MEDIUM);
    	addSCurves();
    	addCurve(ROAD_LENGTH_LONG, -ROAD_CURVE_EASY);


    	  trackLength = segments.length * segmentLength;


    }

    function addSegment(curve:Float) {
          var n = segments.length;
          segments.push({
	             looped: false,
	             fog: 1,
	             curve: curve,
	  	       index: n, //use this with the segments depth.
	             p1: {world:{x:0,y:0,z:n*segmentLength,w:0,scale:0},camera:{x:0,y:0,z:0,w:0,scale:0},screen:{x:0,y:0,z:0,w:0,scale:0}}, //n   *segmentLength,
	  	       p2: {world:{x:0,y:0,z:(n+1)*segmentLength,w:0,scale:0},camera:{x:0,y:0,z:0,w:0,scale:0},screen:{x:0,y:0,z:0,w:0,scale:0}}, //n   *segmentLength,
	  	       backgroundPoly: initPoly(n,1),
	  	       roadPoly: initPoly(n,0)

	  	    });
        }

   function addRoad(enter:Int, hold:Int, leave:Int, curve:Int) {
        var n;
        for(n in 0...enter)
          addSegment(easeIn(0, curve, n/enter));
        for(n in 0...hold)
          addSegment(curve);
        for(n in 0...leave)
          addSegment(easeInOut(curve, 0, Math.floor(n/leave)));
      }


    function addStraight(num) {
          addRoad(num, num, num, 0);
    }

    function addCurve(num, curve) {
      addRoad(num, num, num, curve);
    }
        
    function addSCurves() {
      addRoad(ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM,  -ROAD_CURVE_EASY);
      addRoad(ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM,   ROAD_CURVE_MEDIUM);
      addRoad(ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM,   ROAD_CURVE_EASY);
      addRoad(ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM,  -ROAD_CURVE_EASY);
      addRoad(ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM, ROAD_LENGTH_MEDIUM,  -ROAD_CURVE_MEDIUM);
    }



    function easeIn(a,b,percent){ return a + (b-a)*Math.pow(percent,2);                           }
    function easeOut(a,b,percent){ return a + (b-a)*(1-Math.pow(1-percent,2));                     }
    function easeInOut(a,b,percent){ return a + (b-a)*((-Math.cos(percent*Math.PI)/2) + 0.5);        }
    function percentRemaining(n, total)          { return (n%total)/total;                           }
    public static inline var ROAD_LENGTH_NONE:Float = 0;
    public static inline var ROAD_LENGTH_SHORT:Float = 25;
    public static inline var ROAD_LENGTH_MEDIUM:Float = 50;
    public static inline var ROAD_LENGTH_LONG:Float = 100;

    public static inline var ROAD_CURVE_NONE:Float = 0;
    public static inline var ROAD_CURVE_EASY:Float = 2;
    public static inline var ROAD_CURVE_MEDIUM:Float = 4;
    public static inline var ROAD_CURVE_HARD:Float = 6;

}

typedef Segment = {
	var p1:SegmentPoint;
	var p2:SegmentPoint;
	var index:Int;
	var roadPoly:Geometry;
	var backgroundPoly:Geometry;
    var looped:Bool;
    var fog:Float;
    var curve:Float;
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




