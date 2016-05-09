#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D tex0;
uniform sampler2D tex1;

varying vec2 tcoord;
varying vec2 normal;
varying vec4 color;

uniform float distortamount;
uniform vec2 resolution;
uniform float time;

float rand(vec2 co)
{
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}


void main() {

	   vec4 texcolor = texture2D(tex0, tcoord);
	   gl_FragColor = color * texcolor;
}

