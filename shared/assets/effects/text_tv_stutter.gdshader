shader_type canvas_item;
// https://www.shadertoy.com/view/4djGzz

// wave frequency in Hz
uniform float wave_freq = 0;

// number of waves per unit distance
uniform float wave_count = 4;

//text color
uniform vec4 color : source_color = vec4(1.0);

// Simple circular wave function
float wave(vec2 pos, float t, float freq, float numWaves, vec2 center) {
	float d = length(pos - center);
	d = log(0.8 + exp(d));
	return 1.0/(1.0+20.0*d*d) *
		   sin(2.0*3.1415*(-numWaves*d + t*freq));
}

// This height map combines a couple of waves
float height(vec2 pos, float t) {
	float w;
	w =  wave(pos, t, wave_freq, wave_count, vec2(0.4, -0.4));
	w += wave(pos, t, wave_freq, wave_count, -vec2(0.4, -0.4));
	return w;
}

// Discrete differentiation
vec2 normal(vec2 pos, float t) {
	return 	vec2(height(pos - vec2(0.01, 0), t) - height(pos, t),
				 height(pos - vec2(0, 0.01), t) - height(pos, t));
}

void fragment() {
	vec2 uv = UV;
	vec2 uvn = 2.0*uv - vec2(1.0);
	float steps = 7.0;
	float timestep = floor(fract(TIME) * steps) / steps;
	uv += normal(uvn, timestep);
	COLOR = texture(TEXTURE,uv)*color;
}
