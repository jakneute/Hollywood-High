//
// Fire embers — sparks rise from the bottom and scatter across the scene.
// Uses a grid of cells, each containing one ember with random phase, speed,
// and horizontal wobble. Designed for bm_add blend mode so sparks glow.
// v_vTexcoord: (0,0)=top-left, (1,1)=bottom-right of the stage rect.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;

float hash(vec2 v) {
    return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

// One layer of embers on a cols x rows grid.
// Each cell has a single ember rising bottom-to-top with wobble.
// size: ember radius in cell UV space.
float ember_layer(vec2 uv, float t, float cols, float rows, float size) {
    vec2 cell_id  = floor(uv * vec2(cols, rows));
    vec2 cell_uv  = fract(uv * vec2(cols, rows));

    float r1 = hash(cell_id);
    float r2 = hash(cell_id + vec2(17.0, 31.0));
    float r3 = hash(cell_id + vec2(53.0,  7.0));

    // life: 0 = just born at bottom, 1 = reached top and dies
    float life = fract(r2 + t * (0.28 + r3 * 0.50));

    // Rise from cell bottom (y=1) to cell top (y=0)
    float pos_y = 1.0 - life;
    // Drift and wobble horizontally
    float pos_x = r1 + sin(life * 10.0 + r2 * 6.28) * 0.14
                     + cos(life *  6.0 + r3 * 4.00) * 0.07;
    pos_x = fract(pos_x);

    float dist = length(cell_uv - vec2(pos_x, pos_y));

    // Circular ember, slightly tapered at end of life (shrinks as it dies)
    float cur_size = size * (0.4 + 0.6 * (1.0 - life));
    float circle = 1.0 - smoothstep(0.0, cur_size, dist);

    // Brightness: fade in quickly, linger, fade out
    float fade = pow(sin(life * 3.14159), 0.6);

    return circle * fade;
}

void main() {
    float px = v_vTexcoord.x;
    float py = v_vTexcoord.y;  // 0=top, 1=bottom
    float t  = u_time;

    // Three layers: medium embers, tiny sparks, large slow cinders
    float l1 = ember_layer(vec2(px, py), t,        14.0, 11.0, 0.13);
    float l2 = ember_layer(vec2(px, py), t * 1.5,  22.0, 17.0, 0.08);
    float l3 = ember_layer(vec2(px, py), t * 0.65,  8.0,  6.0, 0.20);

    float embers = clamp(l1 * 0.90 + l2 * 0.65 + l3 * 0.75, 0.0, 1.0);

    // Bottom-heavy: denser and brighter near fire source
    embers *= 0.30 + py * 0.70;

    // Colour: deep orange at bottom, bright yellow higher up
    vec3 col = mix(vec3(1.0, 0.85, 0.15), vec3(1.0, 0.30, 0.0), py);

    // Output for additive blending — alpha drives how much colour is added
    gl_FragColor = vec4(col * embers, embers) * v_vColour;
}
