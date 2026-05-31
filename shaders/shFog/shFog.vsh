//
// Fog vertex shader — computes normalized UV from world position.
// Requires u_rect uniform (x, y, w, h) matching the drawn rectangle.
//
attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec4 u_rect; // x, y, w, h of the stage rectangle in screen pixels

void main() {
    vec4 object_space_pos = vec4(in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    // Compute 0-1 UV from vertex world position within the rect
    v_vTexcoord = vec2(
        (in_Position.x - u_rect.x) / u_rect.z,
        (in_Position.y - u_rect.y) / u_rect.w
    );
    v_vColour = in_Colour;
}
