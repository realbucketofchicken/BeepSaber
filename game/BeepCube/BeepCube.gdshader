shader_type spatial;
render_mode cull_disabled,diffuse_burley,specular_schlick_ggx;

uniform vec4 color : source_color;
uniform sampler2D texture_emission : hint_default_black;
uniform sampler2D dissolve_texture;

uniform float dissolve;
uniform float dissolve_white_offset = 0.155;
uniform float arrow_dissolve;
uniform float metallic;
uniform float roughness;
uniform float sub_emission_energy;

uniform bool cutted = false;
uniform float cut_dist_from_center = 0.0;
uniform float cut_vanish = 0.0;
uniform float cut_angle = 0.0;
uniform float cut_white_margin = 0.04;

uniform bool is_dot = false;
uniform bool is_chain_head = false;

// [firepal]TODO: Build matrix on CPU (I tried but couldn't')
mat3 rotation3dZ(float angle) {
	float s = sin(angle);
	float c = cos(angle);

	return mat3(
		vec3(c, s, 0.0),
		vec3(-s, c, 0.0),
		vec3(0.0, 0.0, 1.0)
	);
}

varying float cut_interp;
varying float chain_interp;
void vertex() {
	if (is_chain_head) {
		chain_interp = 0.1 + VERTEX.y;
	}
	if (cutted) {
		float cut_line = cut_dist_from_center+(VERTEX*rotation3dZ(cut_angle)).x;
		cut_interp = cut_line;
		cut_interp -= cut_vanish;
	}
}

void fragment() {
	// Discard all pixels "in the cut"
	if (
		(cutted && cut_interp < 0.0)
		|| (is_chain_head && chain_interp < 0.0)
	) {
		discard;
	}
	bool arrow;
	ALBEDO = color.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	if (FRONT_FACING || (dissolve > 0.0)) {
		vec2 dot_uv = vec2(UV.x+0.5, UV.y);
		vec3 arrow_tex = texture(texture_emission, is_dot ? dot_uv : UV).rgb;
		arrow = arrow_tex.r > 0.3;
		EMISSION = (color.rgb * sub_emission_energy) + arrow_tex;
		
		if (is_chain_head) {
			EMISSION += vec3( smoothstep(cut_white_margin+0.01,cut_white_margin,chain_interp) );
		}

		if (cutted){
			// soft white margin
			EMISSION += vec3( smoothstep(cut_white_margin+0.01,cut_white_margin,cut_interp) );
			// hard white margin
			//EMISSION += vec3( float(cut_white_margin < cut_interp) );
		}
	} else {
		EMISSION = vec3(1.0);
	}
	if (dissolve > 0.0 || arrow_dissolve > 0.0){
		float dissolve_tex = texture(dissolve_texture,UV).r;
		if (dissolve_tex<dissolve && !arrow){
			if (dissolve_tex<dissolve-(dissolve_white_offset*(1.0-dissolve))){
				discard;
			}
			EMISSION = vec3(0.9) + color.rgb;
			
		}
		if (arrow && !FRONT_FACING){
			discard;
		}
		if (dissolve_tex<arrow_dissolve && arrow){
			discard;
		}
	}
}
