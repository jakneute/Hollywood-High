//
// Sunlight — harsh overhead midday sun.
// Distinct from Brighten (general lift) and Golden Hour (low amber sun):
// overhead source creates vertical god rays, bleached high-contrast look,
// cooler white-yellow (not orange), animated dust motes, deep shadows.
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;

void main() {
    vec2 uv  = v_vTexcoord;
    float t   = u_time;
    float luma = dot(texture2D(gm_BaseTexture, uv).rgb, vec3(0.299, 0.587, 0.114));

    vec4 col = texture2D(gm_BaseTexture, uv);

    // Crush shadows hard then blow out midtones — high contrast overhead look
    col.rgb  = pow(clamp(col.rgb, 0.0, 1.0), vec3(0.72));
    col.rgb  = clamp(col.rgb * 1.25 - 0.05, 0.0, 1.0);

    // Midday white-yellow grade — neutral, not amber like Golden Hour
    col.r    = min(1.0, col.r * 1.06 + 0.03);
    col.g    = min(1.0, col.g * 1.04 + 0.02);
    col.b    = max(0.0, col.b * 0.88);

    // Overhead god rays — radiate downward from top-centre
    vec2  sun_dir  = uv - vec2(0.5, 0.0);
    float ray_ang  = atan(sun_dir.x, max(0.001, sun_dir.y));
    float rays     = pow(max(0.0, sin(ray_ang * 10.0 + t * 0.35) * 0.5 + 0.5), 5.0);
    float ray_fall = exp(-length(sun_dir) * 2.2) * 0.22;
    col.rgb       += rays * ray_fall * vec3(1.0, 0.96, 0.78);

    // Bleached highlight bloom — very bright areas blow out to glowing white
    float bloom = max(0.0, luma - 0.60) * 2.8;
    col.rgb     += bloom * bloom * vec3(1.0, 0.97, 0.88) * 0.45;

    // Animated dust motes — sparse drifting specks in the air
    float m1 = sin(uv.x * 53.0 + t * 0.55) * sin(uv.y * 67.0 - t * 0.32);
    float m2 = sin(uv.x * 37.0 - t * 0.42 + 2.1) * sin(uv.y * 47.0 + t * 0.28);
    float motes = max(0.0, m1 * m2 - 0.82);
    col.rgb    += motes * vec3(1.0, 0.96, 0.80) * 0.35;

    // Subtle cool overhead light from directly above
    col.rgb += (1.0 - uv.y) * vec3(0.03, 0.03, 0.05) * 0.5;

    col.rgb = clamp(col.rgb, 0.0, 1.0);
    gl_FragColor = col * v_vColour;
}
