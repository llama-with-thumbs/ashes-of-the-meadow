shader_type canvas_item;

// Stylized Hubble deep-field — dense stars, blue nebula wisps, warm/cool star mix
uniform float scroll_x : hint_range(-1.0, 1.0) = 0.0;
uniform float scroll_y : hint_range(-1.0, 1.0) = 0.0;
uniform float star_density : hint_range(0.0, 1.0) = 0.45;
uniform vec4 bg_color : source_color = vec4(0.005, 0.005, 0.015, 1.0);
uniform vec4 star_color_warm : source_color = vec4(1.0, 0.7, 0.35, 1.0);
uniform vec4 star_color_cool : source_color = vec4(0.6, 0.75, 1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(269.5, 183.3))) * 61247.1927);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm3(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * noise(p);
		p = p * 2.0 + vec2(100.0);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	vec3 col = bg_color.rgb;

	// ── BLUE-GREY NEBULA WISPS ──
	vec2 neb_uv = uv * 2.5 + vec2(scroll_x, scroll_y) * 0.08;

	float cloud1 = fbm3(neb_uv * 1.2 + vec2(2.1, 0.7) + TIME * 0.002);
	float mask1 = smoothstep(0.42, 0.72, cloud1);
	float bias1 = smoothstep(0.8, 0.3, length(uv - vec2(0.45, 0.35)));
	col += vec3(0.05, 0.08, 0.15) * mask1 * bias1 * 0.8;

	float cloud2 = fbm3(neb_uv * 1.5 + vec2(7.3, 4.1) + TIME * 0.001);
	float mask2 = smoothstep(0.48, 0.75, cloud2);
	float bias2 = smoothstep(0.7, 0.25, length(uv - vec2(0.5, 0.6)));
	col += vec3(0.04, 0.06, 0.12) * mask2 * bias2 * 0.6;

	// ── DISTANT NEBULAE — faint colored patches scattered across the sky ──
	// Warm rose nebula — upper right
	float neb_r = fbm3(neb_uv * 0.8 + vec2(15.3, 2.1));
	float neb_r_mask = smoothstep(0.5, 0.75, neb_r) * smoothstep(0.9, 0.3, length(uv - vec2(0.78, 0.22)));
	col += vec3(0.12, 0.04, 0.06) * neb_r_mask * 0.5;

	// Purple-violet nebula — lower left
	float neb_p = fbm3(neb_uv * 0.9 + vec2(22.7, 9.4));
	float neb_p_mask = smoothstep(0.48, 0.72, neb_p) * smoothstep(0.85, 0.25, length(uv - vec2(0.18, 0.75)));
	col += vec3(0.08, 0.03, 0.14) * neb_p_mask * 0.55;

	// Faint gold emission nebula — center-right
	float neb_g = fbm3(neb_uv * 1.1 + vec2(31.2, 5.6));
	float neb_g_mask = smoothstep(0.52, 0.78, neb_g) * smoothstep(0.7, 0.2, length(uv - vec2(0.7, 0.5)));
	col += vec3(0.1, 0.07, 0.02) * neb_g_mask * 0.45;

	// Teal-cyan wisp — lower center
	float neb_t = fbm3(neb_uv * 1.3 + vec2(8.9, 18.2));
	float neb_t_mask = smoothstep(0.5, 0.73, neb_t) * smoothstep(0.75, 0.2, length(uv - vec2(0.4, 0.82)));
	col += vec3(0.03, 0.08, 0.1) * neb_t_mask * 0.5;

	// ── ANTENNAE GALAXIES — stylized colliding galaxy pair ──
	{
		// Galaxy center position (upper-left area, distant)
		vec2 gal_center = vec2(0.25, 0.3);
		vec2 gp = (uv - gal_center) * 5.0; // scale up for detail
		float r = length(gp);
		float angle = atan(gp.y, gp.x);

		// Two sweeping spiral arms — offset by PI
		// Arm 1: curves upward and right (the "upper antenna")
		float arm1_r = 0.3 + angle * 0.25 + 0.5;
		float arm1_dist = abs(r - arm1_r);
		float arm1_width = 0.12 + fbm3(vec2(angle * 2.0, 1.0) + vec2(40.0)) * 0.08;
		float arm1 = smoothstep(arm1_width, 0.0, arm1_dist) * smoothstep(2.5, 0.3, r);

		// Arm 2: curves downward and left (the "lower antenna")
		float arm2_angle = angle + 3.14159;
		float arm2_r = 0.3 + arm2_angle * 0.2 + 0.3;
		float arm2_dist = abs(r - arm2_r);
		float arm2_width = 0.1 + fbm3(vec2(arm2_angle * 2.0, 3.0) + vec2(55.0)) * 0.07;
		float arm2 = smoothstep(arm2_width, 0.0, arm2_dist) * smoothstep(2.2, 0.3, r);

		float arms = max(arm1, arm2);

		// Bright golden core where galaxies merge
		float core_glow = exp(-r * r * 8.0) * 0.6;
		float core_inner = exp(-r * r * 40.0) * 0.4;

		// Add noise texture to arms for clumpy structure
		float arm_noise = fbm3(gp * 3.0 + vec2(50.0, 20.0));

		// Pink star-forming knots along arms
		float knots = smoothstep(0.55, 0.7, arm_noise) * arms;
		// Blue-white star clusters
		float clusters = smoothstep(0.6, 0.75, fbm3(gp * 4.0 + vec2(70.0, 30.0))) * arms;

		// Dark dust lanes within the arms
		float gal_dust = fbm3(gp * 5.0 + vec2(12.0, 8.0));
		float dust_darken = smoothstep(0.45, 0.6, gal_dust) * 0.4 * arms;

		// Overall galaxy fade
		float gal_fade = 0.45;

		// Composite: blue-white diffuse arm glow
		col += vec3(0.12, 0.14, 0.22) * arms * arm_noise * gal_fade;
		// Golden core
		col += vec3(0.25, 0.18, 0.06) * core_glow * gal_fade;
		col += vec3(0.35, 0.25, 0.1) * core_inner * gal_fade;
		// Pink star-forming regions
		col += vec3(0.22, 0.08, 0.15) * knots * gal_fade * 1.5;
		// Blue clusters
		col += vec3(0.1, 0.12, 0.25) * clusters * gal_fade;
		// Dust darkening
		col *= 1.0 - dust_darken * gal_fade;
	}

	// Dark dust lanes
	float dust = fbm3(uv * 6.0 + vec2(3.3, 7.7));
	col *= 1.0 - smoothstep(0.48, 0.65, dust) * 0.12;

	// ── STARS — 4 layers ──
	for (int layer = 0; layer < 4; layer++) {
		float depth = 1.0 + float(layer) * 0.5;
		float grid_size = 200.0 + float(layer) * 80.0;
		float bright = 0.1 + float(layer) * 0.22;
		float thresh = 1.0 - star_density * (0.07 + float(layer) * 0.018);

		vec2 offset = vec2(scroll_x, scroll_y) / depth;
		vec2 grid = floor((uv + offset) * grid_size);
		float h = hash(grid + float(layer) * 137.0);

		if (h > thresh) {
			vec2 star_pos = fract((uv + offset) * grid_size);
			vec2 center = vec2(hash(grid + 0.5), hash(grid + 1.5));
			float dist = length(star_pos - center);
			float star_r = 0.01 + hash2(grid) * 0.015 + float(layer) * 0.006;

			if (dist < star_r) {
				float twinkle = sin(TIME * (0.8 + h * 3.0) + h * TAU) * 0.25 + 0.75;
				float alpha = (1.0 - dist / star_r) * bright * twinkle;

				// Color — varied stellar classes
				float cmix = hash(grid + 3.5);
				vec3 s_col;
				if (cmix < 0.15) {
					// Deep red — cool M-type
					s_col = vec3(1.0, 0.35, 0.15);
				} else if (cmix < 0.3) {
					// Warm orange — K-type
					s_col = vec3(1.0, 0.65, 0.3);
				} else if (cmix < 0.45) {
					// Yellow-white — G/F-type (sun-like)
					s_col = vec3(1.0, 0.95, 0.75);
				} else if (cmix < 0.6) {
					// Pure white — A-type
					s_col = vec3(0.95, 0.95, 1.0);
				} else if (cmix < 0.78) {
					// Blue-white — B-type
					s_col = vec3(0.65, 0.78, 1.0);
				} else if (cmix < 0.9) {
					// Pale blue — hot O-type
					s_col = vec3(0.5, 0.6, 1.0);
				} else {
					// Rare teal/green tint
					s_col = vec3(0.55, 0.9, 0.8);
				}

				// Bright white core
				if (dist < star_r * 0.3) {
					s_col = mix(s_col, vec3(1.0), 0.5);
					alpha *= 1.3;
				}

				col = mix(col, s_col, clamp(alpha, 0.0, 1.0));
			}
			// Soft glow for foreground stars
			else if (layer >= 3 && dist < star_r * 3.5) {
				float glow = 1.0 - dist / (star_r * 3.5);
				glow = glow * glow * 0.1;
				float cmix = hash(grid + 3.5);
				vec3 g_col = cmix < 0.4 ? star_color_warm.rgb : star_color_cool.rgb;
				col += g_col * glow;
			}
		}
	}

	// ── A FEW BRIGHT STARS with halo ──
	{
		float bsize = 70.0;
		vec2 offset = vec2(scroll_x, scroll_y) / 3.0;
		vec2 grid = floor((uv + offset) * bsize);
		float h = hash(grid + 500.0);

		if (h > 0.987) {
			vec2 star_pos = fract((uv + offset) * bsize);
			vec2 center = vec2(hash(grid + 10.5), hash(grid + 11.5));
			float dist = length(star_pos - center);

			float core = exp(-dist * dist * 600.0) * 0.8;
			float halo = exp(-dist * dist * 30.0) * 0.15;
			float total = (core + halo) * (sin(TIME * 1.5 + h * TAU) * 0.12 + 0.88);

			vec3 bright_col = h < 0.993 ? vec3(0.65, 0.78, 1.0) : vec3(1.0, 0.85, 0.6);
			bright_col = mix(bright_col, vec3(1.0), 0.3);
			col += bright_col * total;
		}
	}

	// ── VIGNETTE ──
	vec2 vc = uv - 0.5;
	col *= 1.0 - dot(vc, vc) * 0.35;

	COLOR = vec4(col, 1.0);
}
