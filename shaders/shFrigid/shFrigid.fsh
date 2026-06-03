//
// Frigid — frozen-over scene: cold color grade, dendritic frost crystals
// creeping from the edges, brief ice sparkles, and slow breath mist rising
// from below. Reads from a scene snapshot surface.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

float hash(vec2 v) {
    return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

// Dendritic frost crystal — ridged absolute-sine noise creates branching lines
float frost_crystal(vec2 uv) {
    float f = 0.0;
    vec2 p = uv;
    f += 1.0 - abs(sin((p.x + sin(p.y * 1.6) * 0.85) * 6.0));
    p.x *= 1.3; p.y *= 0.8;
    f += (1.0 - abs(sin((p.y * 0.9 + sin(p.x * 2.1) * 0.7) * 5.5))) * 0.55;
    p *= 2.0;
    f += (1.0 - abs(sin((p.x * 1.1 + sin(p.y * 1.8) * 0.65) * 5.0))) * 0.30;
    return pow(clamp(f / 1.85, 0.0, 1.0), 2.8);
}

void main() {
    vec2 uv = v_vTexcoord;
    float t  = u_time;

    // --- Sample scene snapshot ---
    vec4 col = texture2D(gm_BaseTexture, uv);

    // --- Cold color grade ---
    // Desaturate toward grey
    float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    col.rgb = mix(col.rgb, vec3(lum), 0.32);
    // Blue-cold tint: pull reds, lift blues
    col.r = col.r * 0.80;
    col.g = min(1.0, col.g * 0.92 + 0.02);
    col.b = min(1.0, col.b * 1.20 + 0.07);
    // Slight contrast crisp (ice is hard-edged)
    col.rgb = (col.rgb - 0.5) * 1.06 + 0.5;
    col.rgb = clamp(col.rgb, 0.0, 1.0);

    // --- Edge frost mask (strongest at corners, fades to nothing in centre) ---
    vec2 fromEdge = abs(uv - vec2(0.5)) * 2.0; // 0=centre, 1=edge
    float edge = max(fromEdge.x, fromEdge.y);
    // Slow breath: frost expands and contracts subtly
    float frost_expand = 0.82 + 0.18 * sin(t * 0.38);
    float frost_mask = smoothstep(0.28, 0.95, edge * frost_expand);

    // --- Frost crystal overlay ---
    float crystal = frost_crystal(uv * vec2(1.0, 1.6));
    crystal = pow(crystal, 1.6) * frost_mask;
    vec3 frost_tint = mix(vec3(0.76, 0.89, 1.0), vec3(0.95, 0.98, 1.0), crystal * 0.7);
    col.rgb = mix(col.rgb, frost_tint, clamp(crystal * 1.5, 0.0, 0.70));

    // --- Ice sparkles: 4-pointed star glints at frost-covered spots ---
    float sparkles = 0.0;
    for (int i = 0; i < 20; i++) {
        float fi = float(i);
        float sx     = hash(vec2(fi * 3.71, 1.0));
        float sy     = hash(vec2(fi * 3.71, 2.0));
        float sphase = hash(vec2(fi * 3.71, 3.0));
        float sspeed = 0.4 + hash(vec2(fi * 3.71, 4.0)) * 1.2;

        // Weight toward edges where frost lives
        float sedge = max(abs(sx - 0.5), abs(sy - 0.5)) * 2.0;
        float sedge_w = smoothstep(0.22, 0.7, sedge);

        // Brief sharp flash
        float slife  = fract(sphase + t * sspeed * 0.13);
        float sflash = smoothstep(0.90, 0.95, slife) * (1.0 - smoothstep(0.95, 1.0, slife));

        vec2 sdiff = uv - vec2(sx, sy);
        vec2 saspect = sdiff * vec2(2.0, 1.0); // ~2:1 scene aspect correction

        // Core dot
        float sdot = (1.0 - smoothstep(0.0, 0.010, length(saspect)));
        // Horizontal arm
        float arm_h = (1.0 - smoothstep(0.0, 0.004, abs(sdiff.y)))
                    * (1.0 - smoothstep(0.0, 0.032, abs(sdiff.x * 2.0)));
        // Vertical arm
        float arm_v = (1.0 - smoothstep(0.0, 0.032, abs(sdiff.y)))
                    * (1.0 - smoothstep(0.0, 0.004, abs(sdiff.x * 2.0)));

        sparkles += clamp((sdot + max(arm_h, arm_v) * 0.75) * sflash * sedge_w, 0.0, 1.0);
    }
    sparkles = clamp(sparkles, 0.0, 1.0);
    col.rgb = mix(col.rgb, vec3(1.0), sparkles * 0.95);

    // --- Breath mist: periodic white haze rising from the bottom ---
    // Each cycle: appear at the bottom, drift upward, fade out
    float breath_cycle = fract(t * 0.09);   // ~11s per breath
    float breath_top   = mix(0.98, 0.55, breath_cycle); // start near bottom, rise
    float breath_band  = 1.0 - smoothstep(0.0, 0.20, abs(uv.y - breath_top));
    float breath_noise = 0.5 + 0.5 * sin(uv.x * 11.0 + t * 1.1)
                               * sin(uv.x *  4.5 - t * 0.7);
    float breath_env   = smoothstep(0.0, 0.28, breath_cycle)
                       * (1.0 - smoothstep(0.36, 0.72, breath_cycle));
    float breath = breath_band * breath_noise * breath_env * 0.18;
    col.rgb = mix(col.rgb, vec3(0.88, 0.94, 1.0), clamp(breath, 0.0, 1.0));

    // --- Icy vignette: cool dark edges + blue-white frost bloom ---
    float vig = dot(uv - vec2(0.5), uv - vec2(0.5)) * 2.0;
    col.rgb *= 1.0 - clamp(vig * 0.38, 0.0, 0.38);
    col.rgb  = mix(col.rgb, vec3(0.60, 0.78, 1.0), clamp(frost_mask * 0.30, 0.0, 0.24));

    gl_FragColor = col * v_vColour;
}
