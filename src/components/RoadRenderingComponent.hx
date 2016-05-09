package components;

import luxe.Component;
import luxe.Vector;
import luxe.Color;
import phoenix.geometry.*;
import com.hypertrifle.*;
import components.RoadGenerationComponent;
import phoenix.Batcher;
import phoenix.Texture;
import phoenix.Camera;
import phoenix.Vector;
import phoenix.Shader;



//Geos - these contain the geometries for rendering one band.
typedef Geos = {
	var roadPoly:Geometry;
	var backgroundPoly:Geometry;
}


class RoadRenderingComponent extends Component {

	private var geometries:Array<Geos>;
	private var geomertyPoolSize:Int = 100;
	private var rumbleLength:Float = 1;   
	private var batcher:Batcher;
	private var camera:Camera;
	private var maxPolies:Int = 0;
	private var shader:Shader;
	private var shaderTime:Float = 0;

	private var texture:Texture;

	private var _testPoly:Geometry;


	override function init() {

		shader = Luxe.resources.shader('road_shader');
		texture = Luxe.resources.texture('assets/testgrid.png');
		var res = new Vector(Luxe.screen.width,Luxe.screen.height);
		shader.set_vector2("resolution",res);
		shader.set_float("time",shaderTime);
		//shader.shader.set('resolution', current_time);
		
		rumbleLength = this.entity.get("road_gen").rumbleLength;

		//create a hud camera
		camera = new Camera({
		    camera_name: 'hud_camera',
		});


		for(b in Luxe.renderer.batchers){
		    if(b.name == 'road_batcher'){
		        trace('found road_batcher');
		        batcher = b;
		    }
		}
		if(batcher == null){
		    trace('couldnt find road_batcher' );
		    batcher = Luxe.renderer.create_batcher({
		        name : 'road_batcher',
		        layer : 5,
		        no_add : false,
		        camera: camera,
		    });
		}

		//batcher.shader = shader;

		initPolies();


		//_testPoly = initPoly(0,0);
		//_testPoly.visible = true;

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
				new Vector(Luxe.screen.width, Luxe.screen.height),
				new Vector(0, Luxe.screen.height)
			],
			visible: false,
			batcher: batcher
			//texture: texture
			//shader: shader
		});
	}

	override function update(dt:Float) {
		shaderTime += dt;
		shader.set_float("time",shaderTime);

	   //render(dt);
	   /*if(batcher.visible_count > maxPolies){
	   	trace(maxPolies = batcher.visible_count);
	   }*/

	}

	function render(dt:Float) {

		var segments:Array<Segment> = this.entity.get("road_gen").segmentsToRender;

		for(i in 0...segments.length){
			this.renderSegment(segments[i],Luxe.screen.width,segments[i].n);
		}
	   

	}

	public function clearRenderer(){
		//return;
		//clear visible segments
		for(n in 0...geometries.length){
			geometries[n].roadPoly.visible = false;
			geometries[n].backgroundPoly.visible = false;
		}
	}

	function renderSegment(segmentIn:Segment, width:Float, index:Int){
		//return;
		if(index >= geometries.length){
			return; //run out of availible polys
		}

		//set these geos to visible
		var geomerty = geometries[index];
		geomerty.roadPoly.visible = true;
		geomerty.backgroundPoly.visible = true;

		//set the coulours
		geomerty.backgroundPoly.color = (Math.floor(segmentIn.index/rumbleLength)%2 == 0) ? new Color().rgb(0x39c7a5) : new Color().rgb(0x2cb493);
		geomerty.roadPoly.color = (Math.floor(segmentIn.index/rumbleLength)%2 == 0) ? new Color().rgb(0xb144d1) : new Color().rgb(0xa166dc);

		//set alpha based on fog value
		geomerty.roadPoly.color.a = segmentIn.fog;
		geomerty.backgroundPoly.color.a = segmentIn.fog;


		var x1:Float = segmentIn.p1.screen.x;
		var y1:Float = segmentIn.p1.screen.y;
		var w1:Float = segmentIn.p1.screen.w;
		var x2:Float = segmentIn.p2.screen.x;
		var y2:Float = segmentIn.p2.screen.y;
		var w2:Float = segmentIn.p2.screen.w;


		//set road geos
		for(i in 0...4){
			geomerty.roadPoly.vertices[i].pos.y = (i <2)? y1 : y2;
		}
		geomerty.roadPoly.vertices[0].pos.x = x1-w1;
		geomerty.roadPoly.vertices[1].pos.x = x1+w1;
		geomerty.roadPoly.vertices[2].pos.x = x2+w2;
		geomerty.roadPoly.vertices[3].pos.x = x2-w2;


		//set background
		for(i in 0...4){
			geomerty.backgroundPoly.vertices[i].pos.y = (i <2) ? y1: y2;
		}

	}




}