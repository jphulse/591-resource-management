shader_type canvas_item;

uniform float infection_level : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 tentacle_seed = vec2(0.0, 0.0);

uniform vec4 button_color : source_color = vec4(0.01, 0.01, 0.02, 1.0);
uniform vec4 button_edge_color : source_color = vec4(0.10, 0.10, 0.14, 1.0);
uniform vec4 star_color : source_color = vec4(0.99, 0.95, 0.82, 1.0);
uniform vec4 infected_color : source_color = vec4(0.88, 0.08, 0.15, 1.0);
uniform vec4 infected_soft_color : source_color = vec4(0.96, 0.26, 0.33, 1.0);
uniform vec4 infected_hot_color : source_color = vec4(1.00, 0.53, 0.58, 1.0);
uniform vec4 infected_shadow_color : source_color = vec4(0.44, 0.03, 0.08, 1.0);
uniform vec4 vein_color : source_color = vec4(0.73, 0.11, 0.18, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;

	for (int i = 0; i < 5; i++) {
		value += noise(p) * amplitude;
		p = p * 2.03 + vec2(17.3, 9.2);
		amplitude *= 0.5;
	}

	return value;
}

float wrapped_distance(float a, float b) {
	float d = abs(a - b);
	return min(d, 1.0 - d);
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv - vec2(0.5);
	float time = TIME;
	float dist = length(p);
	float angle = atan(p.y, p.x);
	float tau = 6.28318530718;
	float surface_rotation = time * 0.055;
	float rot_cos = cos(surface_rotation);
	float rot_sin = sin(surface_rotation);
	vec2 surface_p = vec2(
		rot_cos * p.x - rot_sin * p.y,
		rot_sin * p.x + rot_cos * p.y
	);
	vec2 surface_uv = surface_p + vec2(0.5);
	float surface_angle = atan(surface_p.y, surface_p.x);

	float radius = 0.39;
	float sdf = dist - radius;
	float button_mask = 1.0 - smoothstep(0.0, 0.012, sdf);
	float button_border = smoothstep(-0.035, -0.004, sdf) * button_mask;

	float base_noise = fbm(vec2(surface_angle * 1.35, dist * 6.0) + vec2(time * 0.08, -time * 0.16));
	float branch_noise = fbm(vec2(cos(surface_angle), sin(surface_angle)) * 5.0 + surface_p * 7.5 + vec2(-time * 0.28, time * 0.22));
	float fine_noise = fbm(vec2(surface_angle * 4.6, dist * 12.0) + vec2(time * 0.42, -time * 0.30));
	float pulse = sin(time * (2.2 + pulse_strength * 6.0) + branch_noise * 10.0 + surface_angle * 4.0) * 0.5 + 0.5;
	float intensity = clamp(infection_level * 0.85 + pulse_strength * 0.35, 0.0, 1.0);
	float infection_presence = smoothstep(0.015, 0.06, infection_level + pulse_strength * 0.2);

	float spread_progress = pow(clamp(infection_level, 0.0, 1.0), 0.85);
	float invasion_depth = spread_progress * (0.23 + intensity * 0.06);
	float radial_variation = (base_noise - 0.5) * (0.035 + intensity * 0.025);
	float attack_front = radius - invasion_depth + radial_variation;

	float front_shadow = smoothstep(-0.005, 0.001, dist - attack_front) * button_mask * infection_presence;
	float center_distance = dist / radius;
	float normalized_angle = (surface_angle + PI) / tau;
	float tentacles_inside = 0.0;
	float tentacle_core = 0.0;
	float tentacle_soft = 0.0;
	float base_slot_offset = fract(tentacle_seed.x * 0.0137 + tentacle_seed.y * 0.0213);
	float tentacle_count = 10.0;

	for (int i = 0; i < 10; i++) {
		float index = float(i);
		vec2 seed = tentacle_seed + vec2(index * 1.37, index * 2.11);
		float base_slot = fract((index + 0.5) / tentacle_count + base_slot_offset);
		float spacing_jitter = mix(-0.110, 0.110, hash(seed + vec2(2.7, 0.4)));
		float drift_phase = hash(seed + vec2(41.3, 0.6)) * tau;
		float drift_phase_2 = hash(seed + vec2(44.6, 1.3)) * tau;
		float drift_speed = mix(0.035, 0.090, hash(seed + vec2(47.2, 2.1)));
		float drift_speed_2 = mix(0.080, 0.180, hash(seed + vec2(49.9, 3.2)));
		float drift_amp = mix(0.018, 0.085, hash(seed + vec2(52.4, 4.7)));
		float drift_amp_2 = mix(0.008, 0.040, hash(seed + vec2(55.1, 5.9)));
		float root_angle = fract(
			base_slot +
			spacing_jitter +
			sin(time * drift_speed + drift_phase) * drift_amp +
			sin(time * drift_speed_2 + drift_phase_2) * drift_amp_2
		);
		float tentacle_present = step(0.30, hash(seed + vec2(5.4, 0.9)));
		float depth_rand = hash(seed + vec2(8.8, 1.7));
		float root_width = mix(0.014, 0.030, hash(seed + vec2(12.2, 2.6)));
		float tip_width = mix(0.003, 0.008, hash(seed + vec2(15.6, 3.8)));
		float bend_phase = hash(seed + vec2(18.4, 4.4)) * tau;
		float bend_phase_2 = hash(seed + vec2(21.7, 5.2)) * tau;
		float bend_amp = mix(0.010, 0.045, hash(seed + vec2(24.1, 6.3))) * (0.35 + intensity * 0.9);
		float bend_amp_2 = mix(0.004, 0.018, hash(seed + vec2(27.3, 7.4))) * (0.25 + intensity * 0.7);
		float bend_freq = mix(1.8, 3.8, hash(seed + vec2(29.5, 8.6)));
		float bend_freq_2 = mix(4.0, 8.0, hash(seed + vec2(31.9, 9.7)));
		float bend_speed = mix(-0.9, 1.0, hash(seed + vec2(34.2, 10.4)));
		float bend_speed_2 = mix(-1.4, 1.4, hash(seed + vec2(37.6, 11.2)));
		float tip_depth = min(radius - 0.02, 0.010 + invasion_depth * mix(0.75, 1.25, depth_rand));
		tip_depth *= tentacle_present;

		float progress = clamp((radius - dist) / max(tip_depth, 0.0001), 0.0, 1.0);
		float radial_mask = smoothstep(radius - tip_depth - 0.006, radius - tip_depth + 0.010, dist) * button_mask;
		radial_mask *= infection_presence * tentacle_present;

		float curve = sin(progress * bend_freq + time * bend_speed + bend_phase) * bend_amp;
		curve += sin(progress * bend_freq_2 + time * bend_speed_2 + bend_phase_2) * bend_amp_2;
		curve *= mix(0.35, 1.0, progress);

		float centerline = fract(root_angle + curve);
		float width = mix(root_width, tip_width, progress);
		width *= 1.0 + 0.18 * sin(progress * 6.0 + bend_phase);

		float angle_dist = wrapped_distance(normalized_angle, centerline);
		float body = (1.0 - smoothstep(width, width + 0.008, angle_dist)) * radial_mask;
		float soft_body = (1.0 - smoothstep(width * 1.15, width * 1.48, angle_dist)) * radial_mask;
		float core = (1.0 - smoothstep(width * 0.18, width * 0.46, angle_dist)) * radial_mask;

		tentacles_inside = max(tentacles_inside, body);
		tentacle_soft = max(tentacle_soft, soft_body * (0.45 + 0.55 * progress));
		tentacle_core = max(tentacle_core, core * smoothstep(0.08, 1.0, progress));
	}

	float vein_pattern = abs(sin(surface_angle * 14.0 + time * 1.2 + branch_noise * 4.8) + sin(center_distance * 28.0 - fine_noise * 4.1));
	float veins = smoothstep(1.30 - intensity * 0.15, 1.70, vein_pattern) * (front_shadow * 0.06 + tentacles_inside * 0.92);
	float center_pressure = smoothstep(0.08, 0.48, dist) * smoothstep(0.35, 1.0, infection_level) * infection_presence;
	float hotspot = smoothstep(0.58, 1.0, pulse) * (tentacle_core * 0.85 + center_pressure * 0.22) * infection_presence;

	float sphere_mask = clamp(1.0 - center_distance * center_distance, 0.0, 1.0);
	float sphere_light = pow(sphere_mask, 0.65);
	vec2 highlight_offset = p + vec2(0.13, 0.14);
	float highlight = smoothstep(0.18, 0.0, length(highlight_offset)) * 0.28;
	float rim_light = pow(clamp(1.0 - sphere_mask, 0.0, 1.0), 1.8) * 0.18;

	vec2 star_grid_a = surface_uv * 34.0;
	vec2 star_cell_a = floor(star_grid_a);
	vec2 star_local_a = fract(star_grid_a) - 0.5;
	float star_pick_a = step(0.985, hash(star_cell_a + vec2(3.7, 9.1)));
	float star_size_a = mix(0.018, 0.040, hash(star_cell_a + vec2(7.4, 1.8)));
	float star_a = (1.0 - smoothstep(star_size_a, star_size_a + 0.030, length(star_local_a))) * star_pick_a;

	vec2 star_grid_b = surface_uv * 19.0;
	vec2 star_cell_b = floor(star_grid_b);
	vec2 star_local_b = fract(star_grid_b) - 0.5;
	float star_pick_b = step(0.991, hash(star_cell_b + vec2(12.6, 4.3)));
	float star_size_b = mix(0.026, 0.060, hash(star_cell_b + vec2(6.2, 14.1)));
	float star_b = (1.0 - smoothstep(star_size_b, star_size_b + 0.040, length(star_local_b))) * star_pick_b;

	float stars = clamp(star_a * 0.9 + star_b * 1.35, 0.0, 1.0);
	stars *= sphere_mask * button_mask;
	float star_twinkle = 0.88 + 0.12 * sin(time * 1.1 + hash(star_cell_a + vec2(1.0, 5.0)) * 21.0 + hash(star_cell_b + vec2(8.0, 2.0)) * 17.0);

	vec3 button_base = mix(button_color.rgb, button_edge_color.rgb, button_border * 0.9);
	button_base += sphere_light * 0.10;
	button_base += highlight;
	button_base -= rim_light * 0.10;
	button_base += stars * star_color.rgb * (0.38 + sphere_light * 0.30) * star_twinkle;

	vec3 infected_mix = mix(infected_color.rgb, infected_soft_color.rgb, clamp(0.28 + pulse_strength * 0.25 + pulse * 0.18, 0.0, 1.0));
	vec3 color = button_base;
	color = mix(color, infected_shadow_color.rgb, clamp(front_shadow * 0.02 + tentacle_soft * 0.60, 0.0, 1.0));
	color = mix(color, infected_mix, clamp(tentacles_inside * 0.92, 0.0, 1.0));
	color = mix(color, infected_hot_color.rgb, tentacle_core * (0.42 + pulse * 0.20));
	color = mix(color, vein_color.rgb, veins * 0.90);
	color += infected_hot_color.rgb * hotspot * (0.16 + intensity * 0.24);
	color = mix(color, button_base, 1.0 - infection_presence);

	COLOR = vec4(color, button_mask);
}
