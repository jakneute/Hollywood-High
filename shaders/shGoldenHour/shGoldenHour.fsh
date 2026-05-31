//
// Golden hour — warm orange-amber grade strongest at the bottom,
// subtle light-ray shimmer, slight haze toward the horizon.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;
    vec4 col = texture2D(gm_BaseTexture, uv);

    // Warmth ramps up toward the bottom (ground level, near the sun)
    float warmth = clamp((1.0 - uv.y) * 0.85 + 0.08, 0.0, 1.0);

    col.r = min(1.0, col.r + warmth * 0.28);
    col.g = min(1.0, col.g + warmth * 0.10);
    col.b = max(0.0, col.b - warmth * 0.32);

    // Subtle sun-ray shimmer — fine diagonal bands of light
    float ray = sin(uv.x * 28.0 - uv.y * 14.0 + u_time * 0.6) * 0.5 + 0.5;
    ray = pow(ray, 8.0) * 0.07 * warmth;
    col.rgb += ray * vec3(1.0, 0.75, 0.30);

    // Very gentle haze/bloom near the bottom
    float haze = clamp((1.0 - uv.y - 0.4) * 1.5, 0.0, 1.0);
    col.rgb = mix(col.rgb, vec3(1.0, 0.72, 0.35), haze * 0.12);

    gl_FragColor = col * v_vColour;
}
