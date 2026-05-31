//
// Night vision — green phosphor, scanlines, grain, vignette, gentle flicker.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

float hash(vec2 v) {
    return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    vec2 uv = v_vTexcoord;
    vec4 scene = texture2D(gm_BaseTexture, uv);

    // Luminance — lift shadows so dark areas still read
    float lum = dot(scene.rgb, vec3(0.299, 0.587, 0.114));
    lum = pow(lum, 0.65) * 1.25;
    lum = clamp(lum, 0.0, 1.0);

    // Green phosphor tint
    vec3 col = vec3(lum * 0.12, min(1.0, lum * 1.05), lum * 0.18);

    // Scanlines
    col *= 0.78 + 0.22 * step(0.5, fract(uv.y * 130.0));

    // Grain advancing at ~20fps
    float gf = floor(u_time * 20.0);
    float grain = hash(vec2(uv.x * 320.0 + gf * 4.9, uv.y * 320.0 + gf * 2.5));
    col += (grain - 0.5) * 0.07;

    // Vignette
    vec2 c = uv - vec2(0.5, 0.5);
    col *= 1.0 - clamp(dot(c, c) * 2.8, 0.0, 1.0);

    // Subtle brightness flicker
    col *= 0.92 + 0.08 * hash(vec2(floor(u_time * 10.0), 0.4));

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), scene.a) * v_vColour;
}
