//
// Dream — soft bloom diffusion, slow wave undulation, subtle chromatic
// fringe, lifted shadows, lavender-white pastel grade, and a bright hazy
// vignette that fogs the edges rather than darkening them.
// Reads from a scene snapshot surface.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

void main() {
    vec2  uv = v_vTexcoord;
    float t  = u_time;

    // --- Slow dream-wave distortion ---
    float dx = sin(uv.y * 3.8 + t * 0.55) * 0.005
             + sin(uv.y * 1.6 + t * 0.32) * 0.003;
    float dy = cos(uv.x * 3.2 + t * 0.48) * 0.004
             + cos(uv.x * 1.4 + t * 0.28) * 0.002;
    vec2 w = clamp(uv + vec2(dx, dy), 0.001, 0.999);

    // --- Subtle chromatic fringe ---
    vec2  dir    = normalize(w - vec2(0.5));
    float spread = 0.007;
    float r = texture2D(gm_BaseTexture, clamp(w + dir * spread,       0.001, 0.999)).r;
    float g = texture2D(gm_BaseTexture, w).g;
    float b = texture2D(gm_BaseTexture, clamp(w - dir * spread * 0.6, 0.001, 0.999)).b;
    vec4 col = vec4(r, g, b, texture2D(gm_BaseTexture, w).a);

    // --- Soft bloom: 8-sample radial blur blended back ---
    float br   = 0.016;
    float br7  = br * 0.7;
    vec4 bloom = col * 3.0;
    bloom += texture2D(gm_BaseTexture, clamp(w + vec2( br,   0.0 ), 0.001, 0.999));
    bloom += texture2D(gm_BaseTexture, clamp(w + vec2(-br,   0.0 ), 0.001, 0.999));
    bloom += texture2D(gm_BaseTexture, clamp(w + vec2( 0.0,  br  ), 0.001, 0.999));
    bloom += texture2D(gm_BaseTexture, clamp(w + vec2( 0.0, -br  ), 0.001, 0.999));
    bloom += texture2D(gm_BaseTexture, clamp(w + vec2( br7,  br7 ), 0.001, 0.999));
    bloom += texture2D(gm_BaseTexture, clamp(w + vec2(-br7,  br7 ), 0.001, 0.999));
    bloom += texture2D(gm_BaseTexture, clamp(w + vec2( br7, -br7 ), 0.001, 0.999));
    bloom += texture2D(gm_BaseTexture, clamp(w + vec2(-br7, -br7 ), 0.001, 0.999));
    bloom /= 11.0;
    col = mix(col, bloom, 0.52);

    // --- Pastel grade ---
    col.rgb  = col.rgb * 0.82 + 0.12;                       // lift blacks, compress whites
    col.rgb  = mix(col.rgb, vec3(0.95, 0.90, 1.00), 0.14);  // lavender-white tint
    float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    col.rgb  = mix(col.rgb, vec3(lum), 0.18);               // mild desaturation

    // --- Bright hazy vignette (edges fog to light, not dark) ---
    float vig = dot(uv - vec2(0.5), uv - vec2(0.5)) * 2.0;
    col.rgb = mix(col.rgb, vec3(0.90, 0.86, 1.00), clamp(vig * 0.38, 0.0, 0.32));

    col.rgb = clamp(col.rgb, 0.0, 1.0);
    gl_FragColor = col * v_vColour;
}
