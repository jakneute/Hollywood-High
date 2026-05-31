//
// Stoned — full psychedelic meltdown: swirling distortion, wide chromatic blowout,
// slow hue cycling, and pulsing oversaturation.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;
    float t = u_time;

    // Swirl — angular twist from centre that pulses and breathes
    vec2 d = uv - vec2(0.5);
    float dist = length(d);
    float ang = atan(d.y, d.x);
    float twist = sin(t * 0.38) * 2.8 * exp(-dist * 3.2);
    float rd = dist + sin(t * 0.55 + dist * 9.0) * 0.028;
    vec2 sw = vec2(0.5) + rd * vec2(cos(ang + twist), sin(ang + twist));

    // Layered wave wash on top of the swirl
    sw.x += sin(t * 0.82 + uv.y * 5.5) * 0.032
          + sin(uv.x * 7.2 + t * 1.15)  * 0.013;
    sw.y += cos(t * 0.67 + uv.x * 4.8) * 0.027
          + cos(uv.y * 6.1 + t * 0.92)  * 0.011;
    sw = clamp(sw, 0.001, 0.999);

    // Wide chromatic aberration — RGB pulled to very different positions
    float spread = 0.024 + 0.011 * sin(t * 0.72);
    vec2 dir = normalize(d + vec2(0.001));
    float r = texture2D(gm_BaseTexture, clamp(sw + dir * spread,        0.001, 0.999)).r;
    float g = texture2D(gm_BaseTexture, sw).g;
    float b = texture2D(gm_BaseTexture, clamp(sw - dir * spread * 0.75, 0.001, 0.999)).b;
    vec4 col = vec4(r, g, b, texture2D(gm_BaseTexture, sw).a);

    // Hue cycling — rotate around the grey axis (Rodrigues, k = (1,1,1)/sqrt(3))
    float hue = t * 0.20;
    float cs = cos(hue), sn = sin(hue);
    const vec3 k = vec3(0.57735);
    col.rgb = col.rgb * cs + cross(k, col.rgb) * sn + k * dot(k, col.rgb) * (1.0 - cs);

    // Pulsing saturation — heavily oversaturated and heaving
    float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
    float sat = 1.65 + 0.55 * sin(t * 0.50);
    col.rgb = mix(vec3(lum), col.rgb, sat);

    // Per-distance brightness pulse — things throb outward from centre
    col.rgb *= 0.90 + 0.14 * sin(t * 1.05 + dist * 5.0);

    col.rgb = clamp(col.rgb, 0.0, 1.0);
    gl_FragColor = col * v_vColour;
}
