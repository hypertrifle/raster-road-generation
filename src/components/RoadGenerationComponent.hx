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
    private var speed:Float = 4000;

    var width:Int;
    var height:Int;

	private var segments:Array<Segment>;

	private var ploy1:Geometry;

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

    function initRoad() {
    	segments = new Array<Segment>();

    	//for(var n = 0 ; n < 500 ; n++) { // arbitrary road length
    	for(n in 0...500){
    	    segments.push({
               looped: false,
    	       index: n, //use this with the segments depth.
               p1: {world:{x:0,y:0,z:n*segmentLength,w:0,scale:0},camera:{x:0,y:0,z:0,w:0,scale:0},screen:{x:0,y:0,z:0,w:0,scale:0}}, //n   *segmentLength,
    	       p2: {world:{x:0,y:0,z:(n+1)*segmentLength,w:0,scale:0},camera:{x:0,y:0,z:0,w:0,scale:0},screen:{x:0,y:0,z:0,w:0,scale:0}}, //n   *segmentLength,
    	       poly: initPoly(n)
    	    });
    	  }

    	  trackLength = segments.length * segmentLength;




        //renderSegment();

    }

    function initPoly(index:Int):Geometry {
    	return Luxe.draw.poly({
    	    solid : true,
    	    color: (Math.floor(index/rumbleLength)%2 == 0) ? new Color().rgb(0xff4b03) : new Color().rgb(0xee4b03),
    	    points : [
    	        new Vector(0, 0),
    	        new Vector(0, 0),
    	        new Vector(0, 0),
    	        new Vector(0, 0)
    	    ]
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

        position = progressPosition(position, dt * speed, trackLength);

        var baseSegment = findSegment(position);
        var maxy        = height;
        var segment:Segment;

        var updatedSegments:Int =0;

        for(n in 0...drawDistance) {
               segment = segments[(baseSegment.index + n) % segments.length];
        	   //segment.poly.visible = false;


               segment.looped = (segment.index < baseSegment.index)? true : false;
               segment.p1 = project(segment.p1, (playerX * roadWidth), cameraHeight, position - (segment.looped ? trackLength : 0), cameraDepth, width, height, roadWidth);
               segment.p2 = project(segment.p2, (playerX * roadWidth), cameraHeight, position - (segment.looped ? trackLength : 0), cameraDepth, width, height, roadWidth);
               

               if ((segment.p1.camera.z <= cameraDepth) || (segment.p2.screen.y >= maxy)) {
                    continue; // clip by (already rendered) segment
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

    function renderSegment(segment:Segment, width:Float){
        //trace("render segment");
        segment.poly.visible = true;
        var x1:Float = segment.p1.screen.x;
        var y1:Float = segment.p1.screen.y;
        var w1:Float = segment.p1.screen.w;
        var x2:Float = segment.p2.screen.x;
        var y2:Float = segment.p2.screen.y;
        var w2:Float = segment.p2.screen.w;

        segment.poly.vertices[0].pos.x = x1-w1;
        segment.poly.vertices[0].pos.y = y1;
        
        segment.poly.vertices[1].pos.x = x1+w1;
        segment.poly.vertices[1].pos.y = y1;

        segment.poly.vertices[2].pos.x = x2+w2;
        segment.poly.vertices[2].pos.y = y2;

        segment.poly.vertices[3].pos.x = x2-w2;
        segment.poly.vertices[3].pos.y = y2;


    }


    /*function renderSegmentOld(width, lanes, x1, y1, w1, x2, y2, w2, fog, color) {

        var r1 = Render.rumbleWidth(w1, lanes),
            r2 = Render.rumbleWidth(w2, lanes),
            l1 = Render.laneMarkerWidth(w1, lanes),
            l2 = Render.laneMarkerWidth(w2, lanes),
            lanew1, lanew2, lanex1, lanex2, lane;
        
        ctx.fillStyle = color.grass;
        ctx.fillRect(0, y2, width, y1 - y2);
        
        Render.polygon(ctx, x1-w1-r1, y1, x1-w1, y1, x2-w2, y2, x2-w2-r2, y2, color.rumble);
        Render.polygon(ctx, x1+w1+r1, y1, x1+w1, y1, x2+w2, y2, x2+w2+r2, y2, color.rumble);

        Render.polygon(ctx, x1-w1,    y1, x1+w1, y1, x2+w2, y2, x2-w2,    y2, color.road);
        
        if (color.lane) {
          lanew1 = w1*2/lanes;
          lanew2 = w2*2/lanes;
          lanex1 = x1 - w1 + lanew1;
          lanex2 = x2 - w2 + lanew2;
          for(lane = 1 ; lane < lanes ; lanex1 += lanew1, lanex2 += lanew2, lane++)
            Render.polygon(ctx, lanex1 - l1/2, y1, lanex1 + l1/2, y1, lanex2 + l2/2, y2, lanex2 - l2/2, y2, color.lane);
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
}

typedef Segment = {
	var p1:SegmentPoint;
	var p2:SegmentPoint;
	var index:Int;
	var poly:Geometry;
    var looped:Bool;
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