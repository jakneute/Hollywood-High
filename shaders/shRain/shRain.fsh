//
// Cartoon rain overlay.
// v_vTexcoord: (0,0)=top-left, (1,1)=bottom-right of the stage rect.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;

// Returns streak coverage for one rain layer.
// spacing  - column width in UV space
// speed    - fall speed (UV units per second)
// thick    - streak width as a fraction of spacing (0-1)
// len      - streak length as a fraction of the row period (0-1)
// offset   - horizontal shift to interleave layers
float rain_layer(float px, float py, float speed, float spacing, float thick, float len, float offset) {
    // Diagonal lean (wind tilt, left-to-right)
    float rx = px - py * 0.20 + offset;
    float ry = py - u_time * speed;

    // Position within each column cell
    float cx = fract(rx / spacing);

    // Stagger each column's drop timing using golden-ratio offset
    float col = floor(rx / spacing);
    float period = spacing * 3.0;
    float stagger = fract(col * 0.618) * period;
    float cy = fract((ry + stagger) / period);

    // Streak: thin vertical bar centered in the column, occupying [0, len] of the period
    float in_x = step((1.0 - thick) * 0.5, cx) * (1.0 - step((1.0 + thick) * 0.5, cx));
    float in_y = 1.0 - step(len, cy);

    return in_x * in_y;
}

void main() {
    float px = v_vTexcoord.x;
    float py = v_vTexcoord.y;

    // Foreground layer: fast drops
    float fg = rain_layer(px, py, 2.6, 0.09, 0.035, 0.55, 0.0);
    // Background layer: slower drops, offset so columns don't overlap
    float bg = rain_layer(px, py, 1.7, 0.065, 0.03, 0.45, 0.19);

    float rain = clamp(fg * 0.95 + bg * 0.55, 0.0, 1.0);

    // Bold cartoon blue-white — no transparency on the streaks themselves
    gl_FragColor = vec4(0.55, 0.80, 1.0, rain) * v_vColour;
}
