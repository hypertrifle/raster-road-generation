
import luxe.Input;
import luxe.Sprite;
import luxe.Color;
import luxe.Vector;
import luxe.States;


class Main extends luxe.Game {

	public static var machine : States;

	override function config( config:luxe.GameConfig ) {

	    config.preload.textures.push({ id:'assets/test.png' });
	    config.preload.textures.push({ id:'assets/testgrid.png' });
	    //config.preload.texts.push({ id:'assets/text.json' });
	    config.preload.shaders.push({ id:'road_shader', frag_id:'assets/road.glsl', vert_id:'default' });


	    return config;

	} //config


    override function ready() {

    	Luxe.renderer.clear_color.rgb(0xb1a4ff);

    	connect_input();
    	machine = new States({ name:'statemachine' });
    	machine.add(new PlayState('play_state'));
    	
    	Luxe.on(init, function(_) {
    	    machine.set('play_state');
    	});

    } //ready

    override function onkeyup( e:KeyEvent ) {

        if(e.keycode == Key.escape) {
            Luxe.shutdown();
        }

    } //onkeyup

    override function update(dt:Float) {

    } //update


    function connect_input() {

        Luxe.input.bind_key('up', Key.up);
        Luxe.input.bind_key('up', Key.key_w);
        Luxe.input.bind_key('right', Key.right);
        Luxe.input.bind_key('right', Key.key_d);
        Luxe.input.bind_key('down', Key.down);
        Luxe.input.bind_key('down', Key.key_s);
        Luxe.input.bind_key('left', Key.left);
        Luxe.input.bind_key('left', Key.key_a);
        Luxe.input.bind_key('space', Key.space);
        Luxe.input.bind_key('debug', Key.key_q);
        Luxe.input.bind_key('enter', Key.enter);

    } //connect_input


} //Main
