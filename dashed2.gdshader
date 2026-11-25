shader_type spatial;

varying vec3 pos;
uniform vec3 col;

void vertex() {
	pos = VERTEX;
}

void fragment() {
	ALBEDO = vec3(0);
	EMISSION = col;
	if (fract(pos.z * 0.8) > 0.4) {
		ALPHA = 0.0;
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
