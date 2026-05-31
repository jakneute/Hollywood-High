//
// Underwater — wave distortion, blue-green grade, caustics, vignette,
// and independent rising bubble rings (no grid, no seams).
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
    float t = u_time;

    // Rippling wave distortion
    float dx = sin(uv.y * 9.0  + t * 1.3) * 0.013
             + sin(uv.y * 3.8  + t * 0.7 + 1.6) * 0.008;
    float dy = cos(uv.x * 5.5  + t * 0.9 + 0.8) * 0.005
             + sin(uv.x * 3.0  + t * 0.6) * 0.004;

    vec2 warped = clamp(uv + vec2(dx, dy), 0.001, 0.999);
    vec4 col = texture2D(gm_BaseTexture, warped);

    // Blue-green underwater grade + dim
    col.r  = col.r  * 0.42;
    col.g  = min(1.0, col.g * 0.80 + 0.04);
    col.b  = min(1.0, col.b * 1.30 + 0.12);
    col.rgb *= 0.82;

    // Caustic light patches
    float caustic = sin(uv.x * 14.0 + t * 2.2) * sin(uv.y * 11.0 + t * 1.6) * 0.5 + 0.5;
    caustic = pow(caustic, 5.0) * 0.16;
    col.rgb = min(vec3(1.0), col.rgb + caustic * vec3(0.45, 0.82, 1.0));

    // Edge vignette
    vec2 vc = uv - vec2(0.5, 0.5);
    col.rgb *= 1.0 - clamp(dot(vc, vc) * 1.6, 0.0, 0.55);

    // Independent bubble rings — each is a standalone particle, no grid seams
    float bubbles = 0.0;
    for (int i = 0; i < 14; i++) {
        float fi = float(i);
        float r1 = hash(vec2(fi * 4.13, 1.0)); // x start position
        float r2 = hash(vec2(fi * 4.13, 2.0)); // rise speed / phase
        float r3 = hash(vec2(fi * 4.13, 3.0)); // size + wobble seed

        float speed  = 0.07 + r2 * 0.09;
        float life   = fract(r2 * 7.3 + t * speed);
        float pos_x  = r1 + sin(life * 4.8 + r3 * 6.28) * 0.04;
        float pos_y  = 1.0 - life;

        float radius    = 0.014 + r3 * 0.018; // 0.014 – 0.032 in screen UV
        float thickness = radius * 0.07;

        vec2 bv = uv - vec2(pos_x, pos_y);
        float dist = length(vec2(bv.x * 2.0, bv.y)); // correct for 2:1 scene aspect ratio
        float ring = 1.0 - smoothstep(0.0, thickness, abs(dist - radius));
        float fade = sin(life * 3.14159);

        bubbles += ring * fade;
    }
    bubbles = clamp(bubbles, 0.0, 1.0);
    col.rgb = mix(col.rgb, vec3(0.72, 0.90, 1.0), bubbles * 0.85);

    gl_FragColor = col * v_vColour;
}
