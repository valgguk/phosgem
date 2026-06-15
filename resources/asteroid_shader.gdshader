shader_type canvas_item;

uniform float time_offset : hint_range(0.0, 100.0) = 0.0;
uniform float pixel_size : hint_range(1.0, 32.0) = 4.0;
uniform vec4 base_color : source_color = vec4(0.65, 0.55, 0.42, 1.0);
uniform vec4 dark_color : source_color = vec4(0.32, 0.24, 0.16, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.92, 0.78, 0.58, 1.0);
uniform float crack_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float roughness : hint_range(1.0, 8.0) = 4.0;
uniform vec3 ambient_light : source_color = vec3(0.35, 0.30, 0.25);
uniform vec3 diffuse_light_color : source_color = vec3(1.0, 0.88, 0.70);
uniform vec2 light_dir = vec2(-0.6, -0.8);
uniform float diffuse_strength : hint_range(0.0, 2.0) = 1.2;
uniform vec3 rim_light_color : source_color = vec3(0.4, 0.55, 0.9);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.6;
uniform int crater_count : hint_range(1, 8) = 5;

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(dot(hash2(i + vec2(0,0)), f - vec2(0,0)),
                   dot(hash2(i + vec2(1,0)), f - vec2(1,0)), u.x),
               mix(dot(hash2(i + vec2(0,1)), f - vec2(0,1)),
                   dot(hash2(i + vec2(1,1)), f - vec2(1,1)), u.x), u.y);
}

float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

float cracks(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float min_dist = 1.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = hash2(i + neighbor) * 0.5 + 0.5;
            float d = length(neighbor + point - f);
            min_dist = min(min_dist, d);
        }
    }
    return min_dist;
}

vec2 crater(vec2 uv, vec2 center, float radius, vec2 light) {
    vec2 delta = uv - center;
    float d = length(delta) / radius;
    float rim = smoothstep(1.0, 0.85, d) * smoothstep(0.6, 0.85, d) * 0.5;
    float floor_dip = smoothstep(0.8, 0.4, d) * 0.35;
    float height = rim - floor_dip;
    vec2 dir = normalize(delta + vec2(0.001));
    float shadow = dot(dir, normalize(light)) * 0.5 + 0.5;
    float inner_shadow = (1.0 - smoothstep(0.0, 0.75, d)) * (1.0 - shadow) * 0.7;
    return vec2(height, inner_shadow);
}

void fragment() {

    vec2 uv = floor(UV * pixel_size) / pixel_size;

    vec2 centered = uv - 0.5;
    float dist = length(centered);


    float edge_noise = fbm(centered * roughness + time_offset * 0.05, 3) * 0.12;
    float circle_mask = smoothstep(0.5, 0.42 + edge_noise, dist);

    // Textura rocosa base
    float rocky_base   = fbm(uv * roughness + time_offset * 0.02, 4) * 0.5 + 0.5;
    float rocky_detail = fbm(uv * roughness * 2.5 + 3.7, 3) * 0.5 + 0.5;


    float crack = cracks(uv * 3.5 + time_offset * 0.01);
    float crack_mask = smoothstep(0.15, 0.35, crack) * crack_intensity;
	
    vec2 crater_centers[8];
    crater_centers[0] = vec2(0.30, 0.35);
    crater_centers[1] = vec2(0.65, 0.55);
    crater_centers[2] = vec2(0.50, 0.70);
    crater_centers[3] = vec2(0.38, 0.62);
    crater_centers[4] = vec2(0.60, 0.30);
    crater_centers[5] = vec2(0.45, 0.44);
    crater_centers[6] = vec2(0.70, 0.65);
    crater_centers[7] = vec2(0.28, 0.50);

    float crater_radii[8];
    crater_radii[0] = 0.13;
    crater_radii[1] = 0.10;
    crater_radii[2] = 0.08;
    crater_radii[3] = 0.06;
    crater_radii[4] = 0.09;
    crater_radii[5] = 0.04;
    crater_radii[6] = 0.05;
    crater_radii[7] = 0.07;

    vec2 ldir = normalize(light_dir);
    float crater_height = 0.0;
    float crater_shadow = 0.0;
    for (int i = 0; i < 8; i++) {
        if (i >= crater_count) break;
        float r = crater_radii[i];
        if (length(uv - crater_centers[i]) < r * 1.5) {
            vec2 c = crater(uv, crater_centers[i], r, ldir);
            crater_height += c.x;
            crater_shadow += c.y;
        }
    }
    crater_shadow = clamp(crater_shadow, 0.0, 1.0);

    float eps = 0.005;
    float hL = fbm((uv - vec2(eps, 0.0)) * roughness, 3) + crater_height;
    float hR = fbm((uv + vec2(eps, 0.0)) * roughness, 3) + crater_height;
    float hD = fbm((uv - vec2(0.0, eps)) * roughness, 3) + crater_height;
    float hU = fbm((uv + vec2(0.0, eps)) * roughness, 3) + crater_height;
    vec3 normal = normalize(vec3(hL - hR, hD - hU, 0.04));

    vec3 light3 = normalize(vec3(ldir, 0.5));
    float NdotL = max(dot(normal, light3), 0.0);
    vec3 diffuse = diffuse_light_color * NdotL * diffuse_strength;

    float rim_factor = pow(1.0 - max(dot(normal, vec3(0.0, 0.0, 1.0)), 0.0), 2.5);
    float rim_angle  = dot(normalize(centered + vec2(0.001)), -ldir) * 0.5 + 0.5;
    vec3 rim = rim_light_color * rim_factor * rim_angle * rim_strength;

    vec3 total_light = ambient_light + diffuse + rim;

    vec4 rock_color = mix(dark_color, base_color, rocky_base);
    rock_color = mix(rock_color, highlight_color, rocky_detail * 0.35 * (NdotL + 0.3));
    rock_color.rgb = mix(rock_color.rgb * 0.4, rock_color.rgb, crack_mask);
    rock_color.rgb *= (1.0 - crater_shadow * 0.65);
    rock_color.rgb += crater_height * diffuse_light_color * 0.5;
    rock_color.rgb *= total_light;

    vec3 hot_tint = vec3(1.0, 0.75, 0.55);
    rock_color.rgb = mix(rock_color.rgb, rock_color.rgb * hot_tint, 0.3);
    rock_color.rgb = clamp(rock_color.rgb, 0.0, 1.0);

    COLOR = vec4(rock_color.rgb, circle_mask);
}