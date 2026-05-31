//
// Infrared false-colour: shadows → deep blue, midtones → red/magenta,
// highlights → bright yellow-white. Branchless for GPU compatibility.
// Uniform: u_time (seconds, unused but kept for consistency)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;
    vec4 scene = texture2D(gm_BaseTexture, uv);

    float lum = dot(scene.rgb, vec3(0.299, 0.587, 0.114));

    // Three-stop false-colour ramp — branchless
    vec3 cold = vec3(0.04, 0.04, 0.42);   // deep blue  — shadows / cool areas
    vec3 mid  = vec3(0.88, 0.08, 0.32);   // red-magenta — midtones
    vec3 hot  = vec3(1.00, 0.96, 0.72);   // warm white  — hot highlights

    float t1 = clamp(lum * 2.0,         0.0, 1.0); // 0→1 across [0, 0.5]
    float t2 = clamp((lum - 0.5) * 2.0, 0.0, 1.0); // 0→1 across [0.5, 1.0]
    vec3 col = mix(mix(cold, mid, t1), hot, t2);

    // Blend a small amount of original colour back so cartoon outlines stay readable
    col = mix(col, scene.rgb, 0.10);

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), scene.a) * v_vColour;
}
