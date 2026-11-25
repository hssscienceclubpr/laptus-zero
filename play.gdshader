shader_type canvas_item;

uniform float flip;
uniform float chrom;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if(abs(chrom) >= 0.0001){
		COLOR = vec4(
			texture(TEXTURE, UV + vec2(0.05, 0.05) * chrom).r,
			texture(TEXTURE, UV).g,
			texture(TEXTURE, UV  - vec2(0.05, 0.05) * chrom).b,
			1.0
		);
	}else{
		COLOR = texture(TEXTURE, UV);
	}
	
	if(abs(flip) >= 0.0001){
		vec4 flipped = vec4(1.0) - COLOR;
		flipped = vec4(
			flipped.b,
			flipped.r,
			flipped.g,
			1.0
		);
		flipped.a = 1.0;
		COLOR = COLOR * (1.0 - flip) + flipped * flip;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
