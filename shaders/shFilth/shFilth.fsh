//
// Filth — noxious fume effect. Irregular blobby warping, sickly green-yellow tint,
// rising gas wisps, and a queasy desaturation. Distinct from Heat: organic rather
// than smooth, green rather than amber, present throughout not just the bottom.
// Stronger near the bottom (fume source) but present everywhere.
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;
    float t  = u_time;

    // Organic blobby distortion — four overlapping irregular frequencies
    float nx = sin(uv.x *  8.0 + t * 1.1) * cos(uv.y * 12.0 - t * 0.9)
             + sin(uv.x * 19.0 - t * 2.1 + 1.7) * 0.35;
    float ny = cos(uv.x *  6.0 + t * 0.8 + 2.5) * sin(uv.y *  9.0 + t * 1.3)
             + cos(uv.y * 16.0 - t * 1.6) * 0.30;

    // Stronger near the bottom (fume source) but present throughout
    float str = (0.35 + uv.y * 0.65) * 0.013;

    vec2 warped = clamp(uv + vec2(nx, ny) * str, 0.001, 0.999);
    vec4 col    = texture2D(gm_BaseTexture, warped);

    // Partial desaturation — filth leeches color vibrancy
    float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    col.rgb     = mix(col.rgb, vec3(luma), 0.22);

    // Pervasive sickly green-yellow base tint
    col.rgb = mix(col.rgb, vec3(0.52, 0.64, 0.04), 0.09);

    // Pooling tint deepens at the bottom where the stench originates
    col.rgb = mix(col.rgb, vec3(0.38, 0.52, 0.0), uv.y * 0.11);

    // Rising gas wisps — smooth blobs drifting upward, horizontally varied
    float gas_phase = fract(uv.y * 0.7 + t * 0.16 + sin(uv.x * 4.5) * 0.12);
    float gas_blob  = sin(gas_phase * 6.28318);
    float gas_horz  = sin(uv.x * 6.0 + t * 0.55) * 0.5 + 0.5;
    float gas       = max(0.0, gas_blob) * gas_blob * gas_horz * uv.y * 0.20;
    col.rgb = mix(col.rgb, vec3(0.28, 0.60, 0.02), gas);

    // Queasy pulsing darkening — spatially varied nausea flicker
    float nausea = 0.035 * sin(t * 1.9) * sin(uv.x * 3.2 + t * 0.7) * (0.4 + uv.y * 0.6);
    col.rgb     *= 1.0 + nausea;

    gl_FragColor = col * v_vColour;
}
