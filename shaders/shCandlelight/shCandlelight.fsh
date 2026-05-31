//
// Candlelight — warm orange grade, organic multi-frequency flicker,
// and darkening edges that glow amber like firelit walls.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;
    vec4 col = texture2D(gm_BaseTexture, uv);

    // Organic flicker — three unsynchronised sine waves
    float flicker = 1.0
        + sin(u_time * 3.80)           * 0.065
        + sin(u_time * 7.30 + 1.20)    * 0.035
        + sin(u_time * 13.70 + 2.60)   * 0.020
        + sin(u_time * 19.10 + 0.75)   * 0.010;

    // Warm candle colour grade
    col.r = min(1.0, col.r * 1.18 + 0.06);
    col.g = min(1.0, col.g * 0.92 + 0.02);
    col.b = max(0.0, col.b * 0.62);

    col.rgb *= flicker;

    // Edge darkness — light doesn't reach the corners
    vec2 c = uv - vec2(0.5);
    float edge = clamp(dot(c, c) * 3.0, 0.0, 1.0);
    col.rgb *= 1.0 - edge * 0.60;

    // Amber glow bleeds into the dark edges
    col.rgb = mix(col.rgb, vec3(0.55, 0.18, 0.02) * flicker, edge * 0.28);

    gl_FragColor = col * v_vColour;
}
