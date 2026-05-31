//
// Spotlight — a single pool of warm light gently drifting center-stage,
// deep shadow outside with a cool blue cast, soft penumbra edge.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;
    vec4 col = texture2D(gm_BaseTexture, uv);

    // Spotlight center drifts slowly — subtle theatrical sway
    float cx = 0.50 + sin(u_time * 0.28) * 0.04;
    float cy = 0.44 + cos(u_time * 0.21) * 0.025;

    // Aspect-corrected distance so the spot is circular (2:1 scene)
    vec2 d = uv - vec2(cx, cy);
    float dist = length(vec2(d.x * 2.0, d.y));

    float inner = 0.22; // hard centre radius
    float outer = 0.34; // penumbra edge radius
    float in_spot = 1.0 - smoothstep(inner, outer, dist);

    // Darken and cool the shadows
    float shadow = (1.0 - in_spot);
    col.rgb *= 1.0 - shadow * 0.78;
    col.rgb = mix(col.rgb, col.rgb * vec3(0.72, 0.80, 1.10), shadow * 0.45);

    // Warm and very slightly brighten the lit area
    col.rgb = mix(col.rgb, col.rgb * vec3(1.14, 1.06, 0.88), in_spot * 0.40);

    gl_FragColor = col * v_vColour;
}
