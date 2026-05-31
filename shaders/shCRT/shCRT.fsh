//
// CRT monitor — barrel distortion (inverse mapping, no black border),
// scanlines, edge chromatic fringing, corner vignette.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;

    // Barrel distortion via inverse mapping.
    // For each output pixel we find the source UV by dividing delta by the
    // barrel factor — the result always stays within [0,1], no black border.
    vec2 delta = uv - vec2(0.5);
    float r2 = dot(delta, delta) * 4.0; // 0 at center, ~2 at corner
    vec2 warped = delta / (1.0 + r2 * 0.14) + vec2(0.5);
    vec2 sw = clamp(warped, 0.001, 0.999);

    // Chromatic fringe — red bleeds outward, blue inward
    float fringe = r2 * 0.010;
    vec2 dir = normalize(delta + vec2(0.0001));
    float r = texture2D(gm_BaseTexture, clamp(sw + dir * fringe,       0.001, 0.999)).r;
    float g = texture2D(gm_BaseTexture, sw).g;
    float b = texture2D(gm_BaseTexture, clamp(sw - dir * fringe * 0.6, 0.001, 0.999)).b;
    vec4 col = vec4(r, g, b, 1.0);

    // Scanlines — roll slowly downward
    float scan = 0.78 + 0.22 * step(0.5, fract(warped.y * 120.0 - u_time * 4.0));
    col.rgb *= scan;

    // Corner vignette
    col.rgb *= 1.0 - clamp(r2 * 0.62, 0.0, 1.0);

    gl_FragColor = col * v_vColour;
}
