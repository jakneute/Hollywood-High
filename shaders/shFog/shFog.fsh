//
// Cartoonish rolling fog overlay.
// v_vTexcoord: (0,0)=top-left, (1,1)=bottom-right of the stage rect.
// Uniform: u_time (seconds)
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;

void main() {
    float px = v_vTexcoord.x;
    float py = v_vTexcoord.y;

    // Larger, slower blobs for a chunky cartoon feel
    float l1 = sin(px * 2.8 + u_time * 0.45) * cos(py * 1.4 + u_time * 0.18);
    float l2 = sin(px * 5.2 - u_time * 0.70 + 1.0) * sin(py * 1.9 + u_time * 0.28);
    float l3 = cos(px * 1.8 + u_time * 0.22 + 2.5) * sin(py * 0.9 - u_time * 0.12);

    float combined = (l1 * 0.45 + l2 * 0.35 + l3 * 0.20) * 0.5 + 0.5;

    // smoothstep sharpens blob edges for a defined, cartoon-cloud look
    float fog = smoothstep(0.25, 0.72, combined);

    // Ground-hugging — heavy at the bottom, thins out toward the top
    fog *= 0.10 + py * 0.90;
    fog = clamp(fog, 0.0, 1.0) * 0.80;

    // Bright white for maximum cartoon contrast
    gl_FragColor = vec4(1.0, 1.0, 1.0, fog) * v_vColour;
}
