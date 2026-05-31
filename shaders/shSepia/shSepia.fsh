//
// Old film effect: sepia tone, vignette, grain, brightness flicker,
// occasional vertical scratch, and occasional dust/hair spot.
// Branchless throughout for GPU compatibility.
// Samples the scene via gm_BaseTexture (surface_copy_part pipeline).
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

    // Sample scene
    vec4 scene = texture2D(gm_BaseTexture, uv);

    // 1. Sepia tone — desaturate and tint warm brown
    float gray = dot(scene.rgb, vec3(0.299, 0.587, 0.114));
    vec3 col = vec3(
        min(1.0, gray * 1.18 + 0.04),
        min(1.0, gray * 1.02),
        min(1.0, gray * 0.70)
    );

    // 2. Vignette — darken corners for that old projector look
    vec2 center = uv - vec2(0.5, 0.5);
    float vignette = 1.0 - clamp(dot(center, center) * 2.4, 0.0, 1.0);
    col *= vignette;

    // 3. Subtle film grain — advances at ~24fps
    float gf = floor(u_time * 24.0);
    float grain = hash(vec2(uv.x * 380.0 + gf * 4.7, uv.y * 380.0 + gf * 2.9));
    col += (grain - 0.5) * 0.09;

    // 4. Brightness flicker — slow, gentle
    float ff = floor(u_time * 8.0);
    col *= 0.91 + 0.09 * hash(vec2(ff, 0.5));

    // 5. Vertical scratch — rare, branchless
    float st = floor(u_time * 2.0);
    float scratch_active = step(0.82, hash(vec2(st, 9.1)));
    float scratch_x = hash(vec2(st, 1.3));
    float in_scratch = (1.0 - smoothstep(0.0, 0.004, abs(uv.x - scratch_x))) * scratch_active;
    float scratch_bright = hash(vec2(uv.y * 5.0 + st, 2.7));
    col += in_scratch * scratch_bright * 0.85;

    // 6. Dust / hair spot — slow moving, rare
    float dt = floor(u_time * 3.0);
    float dust_active = step(0.78, hash(vec2(dt, 7.3)));
    float dust_x = hash(vec2(dt, 5.1));
    float dust_y = hash(vec2(dt, 6.2));
    float dust_r = 0.007 + hash(vec2(dt, 8.4)) * 0.014;
    float dust = (1.0 - smoothstep(0.0, dust_r, length(uv - vec2(dust_x, dust_y)))) * dust_active;
    col -= dust * 0.80;

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), scene.a) * v_vColour;
}
