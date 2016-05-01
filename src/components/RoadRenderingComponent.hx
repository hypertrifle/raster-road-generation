package components;

import luxe.Component;
import luxe.Vector;
import luxe.Color;
import phoenix.geometry.*;
import com.hypertrifle.*;
import components.RoadGenerationComponent;

//Geos - these contain the geometries for rendering one band.
typedef Geos = {
	var roadPoly:Geometry;
	var backgroundPoly:Geometry;
}


class RoadRenderingComponent extends Component {

	private var geometries:Array<Geos>;
	private var geomertyPoolSize:Int = 150;
	private var rumbleLength:Float = 1;                       // player x offset from center of road (-1 to 1 to stay independent of roadWidth)

	override function init() {
		initPolies();
		rumbleLength = this.entity.get("road_gen").rumbleLength;

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

	override function update(dt:Float) {

	   

	}

	public function clearRenderer(){
		//clear visible segments
		for(n in 0...geometries.length){
			geometries[n].roadPoly.visible = false;
			geometries[n].backgroundPoly.visible = false;
		}
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