/// @description Dragging Logic
var _mx = mouse_x;
var _my = mouse_y;

if (mouse_check_button_pressed(mb_left)) {
    if (_mx > x - width/2 && _mx < x + width/2 && _my > y - height && _my < y) {
        is_dragging = true;
        drag_offset_x = x - _mx;
        drag_offset_y = y - _my;
        
        // Select as active speaker
        with (oHollywoodUI) {
            active_speaker = other.id;
        }
    }
}

if (is_dragging) {
    x = _mx + drag_offset_x;
    y = _my + drag_offset_y;
    
    if (mouse_check_button_released(mb_left)) {
        is_dragging = false;
    }
}
