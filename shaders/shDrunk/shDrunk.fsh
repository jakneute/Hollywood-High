//
// Drunk/dizzy — slow swaying full-frame distortion with chromatic fringing.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;
    float t = u_time;

    // Multi-layer sway — horizontal and vertical, different frequencies
    float sx = sin(t * 0.75 + uv.y * 3.2) * 0.020
             + sin(t * 0.45 + uv.y * 1.4 + 1.3) * 0.012;
    float sy = cos(t * 0.60 + uv.x * 2.6) * 0.014
             + cos(t * 0.85 + uv.x * 1.1 + 0.9) * 0.008;

    // Additional low-frequency rolling to sell the drunk camera
    sx += sin(uv.x * 2.5 + t * 0.35) * 0.007;
    sy += cos(uv.y * 2.0 + t * 0.50) * 0.006;

    vec2 warped = clamp(uv + vec2(sx, sy), 0.001, 0.999);
    vec4 col = texture2D(gm_BaseTexture, warped);

    // Chromatic fringing — red and blue channels drift slightly apart
    float r = texture2D(gm_BaseTexture, clamp(warped + vec2( 0.005, 0.0), 0.001, 0.999)).r;
    float b = texture2D(gm_BaseTexture, clamp(warped + vec2(-0.005, 0.0), 0.001, 0.999)).b;
    col.r = r; col.b = b;

    gl_FragColor = col * v_vColour;
}
