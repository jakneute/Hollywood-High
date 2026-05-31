//
// TV static overlay — flickering noise, horizontal scanlines, and
// occasional glitch bars. Designed for bm_normal blend.
// v_vTexcoord: (0,0)=top-left, (1,1)=bottom-right.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;

float hash(vec2 v) {
    return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    float px = v_vTexcoord.x;
    float py = v_vTexcoord.y;

    // Advance at ~8fps for a calmer, less frantic flicker
    float frame = floor(u_time * 8.0);

    // Per-pixel random noise
    float noise = hash(vec2(px * 260.0 + frame * 7.3, py * 260.0 + frame * 3.1));

    // Horizontal scanlines — every other line is slightly dimmer
    float scanline = 0.55 + 0.45 * step(0.5, fract(py * 90.0));

    // Rarer glitch bars
    float glitch_row = floor(py * 32.0 + frame * 2.7);
    float glitch = step(0.97, hash(vec2(glitch_row, frame * 0.3))) * 0.85;

    float val = clamp(noise * scanline + glitch, 0.0, 1.0);

    // Bright pixels are opaque, dark pixels let the scene show through
    gl_FragColor = vec4(val, val, val, val * 0.80) * v_vColour;
}
