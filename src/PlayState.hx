import luxe.States;
import luxe.Input;
import luxe.Text;
import luxe.Entity;
import luxe.Color;
import luxe.Vector;
import phoenix.Texture;
import components.*;


class PlayState extends State {

    var entity : Entity;
    var texture : Texture;

    public function new(_name:String) {

        super({ name:_name });

    } //new

    override function init() {
        //called when added to the state machine


    } //init

    override function onenter<T>(_value:T) {
        //entering this state
        
        //create an entity
        entity = new Entity({
            name : 'road',
            pos : new Vector(0,0)
        }); //

        //add a component to an entity
        entity.add(new RoadGenerationComponent({name:'road_gen'}));
        entity.add(new RoadRenderingComponent({name:'road_render'}));


    } //onenter

    override function onleave<T>(_value:T) {
        //leaving this state
        entity.destroy();
    } //onleave

    override function onkeyup(e:KeyEvent) {
        //machine.set('play_state');
    }

    override function update(dt:Float) {
        //called on each update frame
        
        //if(Luxe.input.keypressed('up')){ };
        //if(Luxe.input.keyreleased('up')){ };
        //if(Luxe.input.keydown('up')){ };

    }


} //MenuState
