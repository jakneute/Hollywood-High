/// @description Draw Character Placeholder
draw_set_color(c_white);
draw_rectangle(x - width/2, y - height, x + width/2, y, false);
draw_set_color(c_black);
draw_rectangle(x - width/2, y - height, x + width/2, y, true);

// Name Label
draw_set_halign(fa_center);
draw_text(x, y + 10, name);
draw_set_halign(fa_left);

// Highlight if active
with (oHollywoodUI) {
    if (active_speaker == other.id) {
        draw_set_color(c_yellow);
        draw_rectangle(other.x - other.width/2 - 4, other.y - other.height - 4, other.x + other.width/2 + 4, other.y + 4, true);
    }
}
