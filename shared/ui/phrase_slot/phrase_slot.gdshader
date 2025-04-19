shader_type canvas_item;

// a temporary solution to indicate hover status

uniform bool active;
uniform vec4 tint: source_color;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	if (!active) {
	    COLOR = color;
	} else {
	    COLOR = vec4((color * tint).rgb, color.a);
	}
}
