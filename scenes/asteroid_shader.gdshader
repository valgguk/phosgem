shader_type canvas_item;

uniform float time_offset : hint_range(0.0, 100.0) = 0.0;
uniform vec4 base_color : source_color = vec4(0.35, 0.30, 0.25, 1.0);
uniform vec4 dark_color : source_color = vec4(0.15, 0.12, 0.10, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.55, 0.50, 0.45, 1.0);
uniform float crack_intensity : hint_range(0.0, 1.0) = 0.6;
uniform float roughness : hint_range(1.0, 8.0) = 4.0;

// Hash para pseudoaleatoriedad
vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// Noise de Perlin suavizado
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(dot(hash2(i + vec2(0,0)), f - vec2(0,0)),
                   dot(hash2(i + vec2(1,0)), f - vec2(1,0)), u.x),
               mix(dot(hash2(i + vec2(0,1)), f - vec2(0,1)),
                   dot(hash2(i + vec2(1,1)), f - vec2(1,1)), u.x), u.y);
}

// FBM (Fractal Brownian Motion) para textura compleja
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

// Simula grietas usando distancia a líneas de Voronoi
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

void fragment() {
    vec2 uv = UV;
    
    // Forma circular con borde irregular usando FBM
    vec2 centered = uv - 0.5;
    float dist = length(centered);
    float edge_noise = fbm(centered * roughness + time_offset * 0.05, 3) * 0.12;
    float circle_mask = smoothstep(0.5, 0.42 + edge_noise, dist);
    
    // Capas de textura rocosa
    float rocky_base = fbm(uv * roughness + time_offset * 0.02, 4);
    float rocky_detail = fbm(uv * roughness * 2.5 + 3.7, 3);
    
    // Grietas
    float crack = cracks(uv * 3.5 + time_offset * 0.01);
    float crack_mask = smoothstep(0.15, 0.35, crack) * crack_intensity;
    
    // Iluminación falsa: luz desde arriba-izquierda
    float light = dot(normalize(centered), normalize(vec2(-0.6, -0.8))) * 0.5 + 0.5;
    float shading = mix(0.4, 1.0, light);
    
    // Componer color final
    vec4 rock_color = mix(dark_color, base_color, rocky_base);
    rock_color = mix(rock_color, highlight_color, rocky_detail * 0.4 * shading);
    rock_color = mix(rock_color * 0.3, rock_color, crack_mask); // grietas oscuras
    rock_color.rgb *= shading;
    
    float rim = smoothstep(0.38, 0.50, dist) * (1.0 - edge_noise * 2.0);
    rock_color = mix(rock_color, dark_color * 0.5, rim * 0.7);
    
    COLOR = vec4(rock_color.rgb, circle_mask);
}