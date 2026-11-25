shader_type spatial;

uniform float dir = 1.0;
uniform vec3 col0 = vec3(1,0.4,0.4);
uniform vec3 col1 = vec3(1,0.1,0.1);
uniform float len = 3.0;

instance uniform float a = 1.0;

varying vec3 pos;

void vertex() {
	pos = VERTEX;
	pos.x = pos.x / len + 0.5;
}

void fragment() {
	int x;
	
	ALBEDO = vec3(0);
	
	float xx = (pos.x - 0.5) * dir + 0.5;
	float t = xx + abs(pos.z) * 0.4 * (3.0 / len);
	if(pos.x < 0.03 || pos.x > 0.97){
		x = 2;
	}else if(fract(t * 4.0 - TIME * 6.0) < 0.6){
		x = 1;
	}else{
		x = 0;
	}
	
	if(x == 0){
		EMISSION = col0;
	}else if(x == 1){
		ALPHA = 1.0;
		EMISSION = col1;
	}else{
		EMISSION = col1;
	}
	
	EMISSION *= a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
