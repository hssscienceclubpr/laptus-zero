shader_type spatial;

instance uniform float a = 1.0;

varying vec3 pos;

void vertex() {
	pos = VERTEX;
	pos.x = (pos.x + 1.0) * 0.5;
	pos.y = (pos.y + 0.4) / 0.8;
}

void fragment() {
	if(fract(pos.x * 3.0 + abs(pos.y - 0.5) + 0.5) < 0.5){
		ALPHA = a;
	}else{
		ALPHA = 0.0;
	}
	EMISSION = vec3(1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
