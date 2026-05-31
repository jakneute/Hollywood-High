//
// Night time — plunges the scene into darkness with a cool blue-grey moonlight grade,
// heavy desaturation, and soft edge shadow.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;
    vec4 col = texture2D(gm_BaseTexture, uv);

    // Desaturate — night strips colour
    float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    col.rgb = mix(col.rgb, vec3(lum), 0.60);

    // Heavy darkening
    col.rgb *= 0.32;

    // Cool blue-indigo moonlight cast
    col.r *= 0.75;
    col.g *= 0.85;
    col.b = min(1.0, col.b * 1.15 + 0.03);

    // Soft moonbeam from top — fades downward
    float moon = clamp(1.0 - uv.y * 1.4, 0.0, 1.0);
    float pulse = 1.0 + 0.04 * sin(u_time * 0.22);
    col.rgb += moon * vec3(0.03, 0.05, 0.10) * pulse;

    // Deepen the edges into shadow
    vec2 c = uv - vec2(0.5);
    float edge = clamp(dot(c, c) * 2.8, 0.0, 1.0);
    col.rgb *= 1.0 - edge * 0.50;

    gl_FragColor = col * v_vColour;
}
