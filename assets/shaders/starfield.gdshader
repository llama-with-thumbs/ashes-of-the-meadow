shader_type canvas_item;

// Rich procedural starfield — multi-layer parallax, nebula wisps, dust clouds
uniform float scroll_x : hint_range(-1.0, 1.0) = 0.0;
uniform float scroll_y : hint_range(-1.0, 1.0) = 0.0;
uniform float star_density : hint_range(0.0, 1.0) = 0.45;
uniform vec4 bg_color : source_color = vec4(0.015, 0.015, 0.05, 1.0);
uniform vec4 star_color_warm : source_color = vec4(1.0, 0.9, 0.7, 1.0);
uniform vec4 star_color_cool : source_color = vec4(0.7, 0.8, 1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(269.5, 183.3))) * 61247.1927);
}

// Smooth noise for nebula
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smoothstep

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractional Brownian Motion for nebula clouds
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0);
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	vec4 col = bg_color;

	// Nebula wisps — very subtle colored clouds
	vec2 nebula_uv = uv * 3.0 + vec2(scroll_x, scroll_y) * 0.1;
	float n1 = fbm(nebula_uv + TIME * 0.005);
	float n2 = fbm(nebula_uv * 1.3 + vec2(5.2, 1.3) + TIME * 0.003);
	float n3 = fbm(nebula_uv * 0.8 + vec2(8.7, 3.1));

	// Warm nebula — orange/amber tones
	col.rgb += vec3(0.35, 0.15, 0.05) * smoothstep(0.45, 0.75, n1) * 0.06;
	// Cool nebula — purple/blue tones
	col.rgb += vec3(0.1, 0.05, 0.25) * smoothstep(0.5, 0.8, n2) * 0.05;
	// Teal accent
	col.rgb += vec3(0.05, 0.15, 0.2) * smoothstep(0.55, 0.85, n3) * 0.04;

	// Dust lane — darker region
	float dust = fbm(uv * 5.0 + vec2(3.3, 7.7));
	col.rgb *= 1.0 - smoothstep(0.5, 0.7, dust) * 0.08;

	// Stars — four parallax layers
	for (int layer = 0; layer < 4; layer++) {
		float depth = 1.0 + float(layer) * 0.6;
		float size = 250.0 - float(layer) * 45.0;
		float brightness = 0.2 + float(layer) * 0.25;
		float density_threshold = 1.0 - star_density * (0.06 + float(layer) * 0.02);

		vec2 offset = vec2(scroll_x, scroll_y) / depth;
		vec2 grid = floor((uv + offset) * size);
		float h = hash(grid + float(layer) * 137.0);

		if (h > density_threshold) {
			vec2 star_pos = fract((uv + offset) * size);
			vec2 center = vec2(hash(grid + 0.5), hash(grid + 1.5));
			float dist = length(star_pos - center);

			// Star size varies by layer and random
			float star_size = 0.015 + hash2(grid) * 0.025 + float(layer) * 0.008;

			if (dist < star_size) {
				// Twinkle
				float twinkle_speed = 1.0 + h * 4.0;
				float twinkle = sin(TIME * twinkle_speed + h * TAU) * 0.3 + 0.7;
				float star_alpha = (1.0 - dist / star_size) * brightness * twinkle;

				// Star color — mix warm and cool
				float color_mix = hash(grid + 3.5);
				vec4 s_color = mix(star_color_warm, star_color_cool, color_mix);

				// Larger stars get a subtle glow halo
				if (layer >= 2 && dist < star_size * 0.5) {
					star_alpha *= 1.3;
				}

				// Soft glow around brighter stars
				col.rgb = mix(col.rgb, s_color.rgb, clamp(star_alpha, 0.0, 1.0));
			}
			// Extended glow for layer 3 stars
			else if (layer == 3 && dist < star_size * 3.0) {
				float glow = (1.0 - dist / (star_size * 3.0)) * 0.08;
				vec4 s_color = mix(star_color_warm, star_color_cool, hash(grid + 3.5));
				col.rgb += s_color.rgb * glow;
			}
		}
	}

	// Very faint vignette — darker at edges
	vec2 vc = uv - 0.5;
	float vignette = 1.0 - dot(vc, vc) * 0.3;
	col.rgb *= vignette;

	COLOR = col;
}
