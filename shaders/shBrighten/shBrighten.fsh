//
// Day time — lifts dark scenes into bright natural daylight with a warm sun grade,
// aggressive shadow exposure, and subtle sun shimmer.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;
    vec4 col = texture2D(gm_BaseTexture, uv);

    // Aggressive shadow lift then gamma correction to open up midtones
    col.rgb = clamp(col.rgb + vec3(0.10), 0.0, 1.0);
    col.rgb = pow(col.rgb, vec3(0.60));

    // Warm daylight colour grade — boost warm tones, reduce blue cast
    col.r = min(1.0, col.r * 1.10 + 0.05);
    col.g = min(1.0, col.g * 1.04 + 0.02);
    col.b = max(0.0, col.b * 0.80);

    // Sky light from above — cool-white gradient near top
    float sky = clamp((1.0 - uv.y - 0.4) * 2.5, 0.0, 1.0);
    col.rgb += sky * vec3(0.04, 0.05, 0.08) * 0.5;

    // Warm ground bounce from below
    float ground = clamp((uv.y - 0.65) * 3.0, 0.0, 1.0);
    col.rgb += ground * vec3(0.06, 0.04, 0.0) * 0.4;

    // Very faint sun shimmer
    float ray = sin(uv.x * 22.0 - uv.y * 11.0 + u_time * 0.55) * 0.5 + 0.5;
    ray = pow(ray, 10.0) * 0.035;
    col.rgb += ray * vec3(1.0, 0.88, 0.60);

    col.rgb = clamp(col.rgb, 0.0, 1.0);
    gl_FragColor = col * v_vColour;
}
