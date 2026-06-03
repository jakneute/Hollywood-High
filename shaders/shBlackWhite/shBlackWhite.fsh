//
// B&W Film — luminance conversion, two-scale film grain at 24fps,
// heavy period vignette, and slow projector flicker.
// Reads from a scene snapshot surface.
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
    float t  = u_time;

    vec4 col = texture2D(gm_BaseTexture, uv);

    // --- Luminance conversion ---
    float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    // Slight contrast lift (old orthochromatic film was high-contrast)
    lum = clamp((lum - 0.45) * 1.20 + 0.45, 0.0, 1.0);
    col.rgb = vec3(lum);

    // --- Film grain (two-scale, updates at 24 fps) ---
    float frame = floor(t * 24.0);
    // Coarse blobs — lower frequency, more visible in midtones
    float g_coarse = hash(uv * vec2(95.0, 65.0) + vec2(frame * 13.7, frame * 9.3));
    // Fine noise — high frequency pixel scatter
    float g_fine   = hash(uv * vec2(310.0, 210.0) + vec2(frame * 27.1, frame * 19.9));
    // Blend: midtones get more grain than deep shadows/bright highlights
    float midtone  = 1.0 - abs(lum - 0.5) * 2.0;
    float grain    = (g_coarse * 0.60 + g_fine * 0.40 - 0.5) * (0.09 + midtone * 0.06);
    col.rgb        = clamp(col.rgb + vec3(grain), 0.0, 1.0);

    // --- Heavy vignette (period lens falloff) ---
    float vig = dot(uv - vec2(0.5), uv - vec2(0.5)) * 3.2;
    col.rgb *= 1.0 - clamp(vig * 0.75, 0.0, 0.82);

    // --- Projector flicker (slow, irregular brightness pulse) ---
    float flicker = 0.93 + 0.07 * sin(t * 11.3) * sin(t * 7.1)
                         * (0.5 + 0.5 * hash(vec2(frame * 0.3, 1.0)));
    col.rgb = clamp(col.rgb * flicker, 0.0, 1.0);

    gl_FragColor = col * v_vColour;
}
