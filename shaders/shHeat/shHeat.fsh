//
// Heat distortion — warps a scene snapshot to simulate hot rising air.
// Distortion is strongest at the bottom (ground level) and fades to nothing
// at the top. Draws over the scene via draw_surface_stretched.
// v_vTexcoord: natural surface UVs (0,0)=top-left, (1,1)=bottom-right.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;

    // Distortion magnitude: quadratic ramp so ground is hottest
    float strength = uv.y * uv.y * 0.014;

    // Two overlapping wave frequencies for organic shimmer
    float dx = (sin(uv.y * 18.0 + u_time * 3.2) * 0.6 +
                sin(uv.y *  7.0 + u_time * 1.8 + 1.5) * 0.4) * strength;
    float dy =  cos(uv.x * 13.0 + u_time * 2.5) * strength * 0.35;

    vec2 warped = clamp(uv + vec2(dx, dy), 0.001, 0.999);

    vec4 col = texture2D(gm_BaseTexture, warped);

    // Subtle warm tint at the bottom to sell the heat
    col.rgb = mix(col.rgb, vec3(1.0, 0.72, 0.28), uv.y * 0.07);

    gl_FragColor = col * v_vColour;
}
