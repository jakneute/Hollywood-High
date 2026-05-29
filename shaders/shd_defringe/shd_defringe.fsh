varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec2 u_texel_size;

void main() {
    vec4 col = texture2D(gm_BaseTexture, v_vTexcoord);

    // For semi-transparent edge pixels, replace the color with a weighted blend of
    // nearby fully-opaque pixels in the same sprite. This eliminates fringe contamination
    // (white or black halo) that occurs when sprites are anti-aliased against a
    // background color in the source image editor.
    if (col.a > 0.01 && col.a < 0.98) {
        vec3 sum_col = vec3(0.0);
        float sum_w  = 0.0;
        for (int dx = -2; dx <= 2; dx++) {
            for (int dy = -2; dy <= 2; dy++) {
                vec4 s  = texture2D(gm_BaseTexture, v_vTexcoord + vec2(float(dx), float(dy)) * u_texel_size);
                float w = s.a * s.a;
                sum_col += s.rgb * w;
                sum_w   += w;
            }
        }
        if (sum_w > 0.0) col.rgb = sum_col / sum_w;
    }

    gl_FragColor = col * v_vColour;
}
