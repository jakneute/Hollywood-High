//
// Snowfall — soft round flakes drifting gently straight down.
// Three layers give depth: large slow foreground flakes, medium mid-ground,
// tiny fast background specks.
// v_vTexcoord: (0,0)=top-left, (1,1)=bottom-right of the stage rect.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;

float hash(vec2 v) {
    return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

float snow_layer(vec2 uv, float t, float cols, float rows, float size) {
    vec2 cell_id = floor(uv * vec2(cols, rows));
    vec2 cell_uv = fract(uv * vec2(cols, rows));

    float r1 = hash(cell_id);
    float r2 = hash(cell_id + vec2(17.0, 31.0));
    float r3 = hash(cell_id + vec2(53.0,  7.0));

    // life: 0=top of cell, 1=bottom — flake falls downward
    float life = fract(r2 + t * (0.22 + r3 * 0.28));

    float pos_y = life;
    // Very gentle horizontal sway — no diagonal lean
    float pos_x = r1 + sin(life * 3.5 + r2 * 6.28) * 0.06;
    pos_x = fract(pos_x);

    float dist = length(cell_uv - vec2(pos_x, pos_y));

    // Soft edges — wide smoothstep range gives fluffy look
    float flake = 1.0 - smoothstep(size * 0.2, size, dist);

    // Fade in at top, fade out at bottom
    float fade = sin(life * 3.14159);

    return flake * fade;
}

void main() {
    float px = v_vTexcoord.x;
    float py = v_vTexcoord.y;
    float t  = u_time;

    // Large slow flakes up front, medium mid, tiny background specks
    float l1 = snow_layer(vec2(px, py), t,        10.0, 12.0, 0.16);
    float l2 = snow_layer(vec2(px, py), t * 1.6,  18.0, 22.0, 0.11);
    float l3 = snow_layer(vec2(px, py), t * 2.4,  28.0, 34.0, 0.07);

    float snow = clamp(l1 * 0.95 + l2 * 0.75 + l3 * 0.55, 0.0, 1.0);

    // Pure soft white
    gl_FragColor = vec4(1.0, 1.0, 1.0, snow) * v_vColour;
}
