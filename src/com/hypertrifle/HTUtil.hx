package com.hypertrifle;

import luxe.Vector;
import luxe.Color;

class HTUtil {

	static public function randomInt(max:Int):Int{
		return Math.floor(Math.random()*max);
	}

	//increase a value based on dt for varible frame lengths.
	static public function accelerate(v:Float, accel:Float, dt:Float):Float      {
		return v + (accel * dt);
	}

	//returns a value between a nd b and given percent
	static public function interpolate(a:Float,b:Float,percent:Float):Float {
		return a + (b-a)*percent;
	}

	// interpolation with an ease in
	static public function easeIn(a:Float,b:Float,percent:Float):Float{ 
		return a + (b-a)*Math.pow(percent,2);
	}

	// interpolation with an ease out
	static public function easeOut(a:Float,b:Float,percent:Float):Float{
		return a + (b-a)*(1-Math.pow(1-percent,2));
	}

	// interpolation with an ease in and out
	static public function easeInOut(a:Float,b:Float,percent:Float):Float{
		return a + (b-a)*((-Math.cos(percent*Math.PI)/2) + 0.5);
	}


	// returns the pecentage of n to total (0-1)
	static public function percentRemaining(n:Float, total:Float):Float {
		return (n%total)/total;                           
	}

	//incriments a value but wraps in bounds 0 - mac //prev: progressPosition
	static public function incrementWithWrap(start:Float, increment:Float, max:Float):Int {
		return Math.floor((start+increment)%max);
	}


}