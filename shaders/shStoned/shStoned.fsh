//
// Stoned — gentle psychedelic drift: soft distortion, mild chromatic fringe,
// slow hue tilt, and light pulsing saturation.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;
    float t = u_time;

    // Gentle swirl — much smaller twist, slower pulse
    vec2 d = uv - vec2(0.5);
    float dist = length(d);
    float ang = atan(d.y, d.x);
    float twist = sin(t * 0.22) * 0.7 * exp(-dist * 3.5);
    float rd = dist + sin(t * 0.32 + dist * 7.0) * 0.008;
    vec2 sw = vec2(0.5) + rd * vec2(cos(ang + twist), sin(ang + twist));

    // Soft wave wash
    sw.x += sin(t * 0.50 + uv.y * 4.0) * 0.010
          + sin(uv.x * 5.0 + t * 0.70) * 0.005;
    sw.y += cos(t * 0.40 + uv.x * 3.5) * 0.009
          + cos(uv.y * 4.5 + t * 0.55) * 0.004;
    sw = clamp(sw, 0.001, 0.999);

    // Narrow chromatic fringe
    float spread = 0.007 + 0.003 * sin(t * 0.45);
    vec2 dir = normalize(d + vec2(0.001));
    float r = texture2D(gm_BaseTexture, clamp(sw + dir * spread,        0.001, 0.999)).r;
    float g = texture2D(gm_BaseTexture, sw).g;
    float b = texture2D(gm_BaseTexture, clamp(sw - dir * spread * 0.75, 0.001, 0.999)).b;
    vec4 col = vec4(r, g, b, texture2D(gm_BaseTexture, sw).a);

    // Slow, subtle hue drift
    float hue = t * 0.07;
    float cs = cos(hue), sn = sin(hue);
    const vec3 k = vec3(0.57735);
    col.rgb = col.rgb * cs + cross(k, col.rgb) * sn + k * dot(k, col.rgb) * (1.0 - cs);

    // Mild saturation pulse — stays close to natural
    float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    float sat = 1.18 + 0.12 * sin(t * 0.35);
    col.rgb = mix(vec3(lum), col.rgb, sat);

    // Very faint brightness throb
    col.rgb *= 0.97 + 0.04 * sin(t * 0.70 + dist * 3.5);

    col.rgb = clamp(col.rgb, 0.0, 1.0);
    gl_FragColor = col * v_vColour;
}
