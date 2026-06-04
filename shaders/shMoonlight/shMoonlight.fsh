//
// Moonlight — soft directional silver light from a specific moon position.
// Distinct from Darken: lighter overall, strong silver directional quality,
// bloom on bright surfaces, and slow animated shimmer through moving clouds.
// Evokes being caught in a shaft of cold moonlight rather than general night.
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;

void main() {
    vec2 uv = v_vTexcoord;
    float t  = u_time;

    vec4 col  = texture2D(gm_BaseTexture, uv);
    float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));

    // Heavy desaturation — moonlight drains almost all colour
    col.rgb = mix(col.rgb, vec3(luma), 0.75);

    // Moderate darkening — lighter than Darken (0.32), feels like deep shadow not pitch black
    col.rgb *= 0.48;

    // Cold blue-silver cast
    col.rgb = mix(col.rgb, vec3(0.58, 0.68, 0.90), 0.16);

    // Directional moonbeam from upper-left — a specific moon position, not diffuse overhead
    vec2 moon = vec2(0.22, 0.0);
    float md   = length(uv - moon);
    col.rgb   += exp(-md * md * 2.0) * vec3(0.12, 0.16, 0.28);

    // Silver bloom on bright surfaces — highlights catch the moonlight and glint
    float hi = max(0.0, luma - 0.50);
    col.rgb  += hi * hi * vec3(0.60, 0.72, 1.00) * 2.2;

    // Animated shimmer — moonlight filtered through slow drifting clouds
    float s1 = sin(uv.x * 5.0 + t * 0.14) * sin(uv.y * 3.5 + t * 0.09);
    float s2 = cos(uv.x * 8.0 - t * 0.10 + 1.4) * cos(uv.y * 6.0 + t * 0.07);
    float shim = (s1 + s2 * 0.6) * 0.045 * luma;
    col.rgb += shim * vec3(0.45, 0.55, 0.85);

    // Light vignette — softer than Darken's heavy edge crush
    vec2 c  = uv - vec2(0.5);
    float v = dot(c, c) * 1.5;
    col.rgb *= max(0.72, 1.0 - v * 0.48);

    gl_FragColor = col * v_vColour;
}
