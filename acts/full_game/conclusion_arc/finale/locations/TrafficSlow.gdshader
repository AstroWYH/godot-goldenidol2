shader_type canvas_item;

uniform float scrolling_speed = 0.25;

void fragment() {
	vec2 moving_uv = vec2(UV.x+(TIME*scrolling_speed), UV.y);
	vec4 in_tex = texture(TEXTURE, moving_uv);
	COLOR = in_tex;
	}