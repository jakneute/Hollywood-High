/// @description Actor Studio — input handling
var _mx = mouse_x; var _my = mouse_y;

if (mouse_check_button_pressed(mb_left)) {

    // --- BACK TO EDITOR ---
    if (_mx > back_btn_x && _mx < back_btn_x + back_btn_w && _my > back_btn_y && _my < back_btn_y + back_btn_h) {
        room_goto(MainWindow);
        exit;
    }

    // --- ACTOR LIST SELECTION ---
    var _row_h = 40;
    for (var _i = 0; _i < array_length(studio_actors); _i++) {
        var _ry = ui_list_y + 50 + _i * _row_h;
        if (_mx > ui_list_x + 8 && _mx < ui_list_x + ui_list_w - 8 && _my > _ry && _my < _ry + _row_h - 4) {
            if (selected_actor != _i) {
                selected_actor = _i;
                selected_pose = 0;
                selected_expression = 0;
            }
        }
    }

    // --- POSE / EXPRESSION CYCLERS (only when an actor with data is selected) ---
    if (selected_actor >= 0) {
        var _act = studio_actors[selected_actor];
        if (_act.data != undefined && is_struct(_act.data)) {
            var _poses = variable_struct_exists(_act.data, "poses") ? _act.data.poses : [];
            var _exprs = variable_struct_exists(_act.data, "expressions") ? _act.data.expressions : [];

            // Pose < >
            var _py = ui_panel_y + 110;
            if (array_length(_poses) > 0) {
                if (_mx > ui_panel_x + 20 && _mx < ui_panel_x + 64 && _my > _py && _my < _py + 44) {
                    selected_pose = (selected_pose - 1 + array_length(_poses)) mod array_length(_poses);
                }
                if (_mx > ui_panel_x + ui_panel_w - 64 && _mx < ui_panel_x + ui_panel_w - 20 && _my > _py && _my < _py + 44) {
                    selected_pose = (selected_pose + 1) mod array_length(_poses);
                }
            }

            // Expression < >
            var _ey = ui_panel_y + 250;
            if (array_length(_exprs) > 0) {
                if (_mx > ui_panel_x + 20 && _mx < ui_panel_x + 64 && _my > _ey && _my < _ey + 44) {
                    selected_expression = (selected_expression - 1 + array_length(_exprs)) mod array_length(_exprs);
                }
                if (_mx > ui_panel_x + ui_panel_w - 64 && _mx < ui_panel_x + ui_panel_w - 20 && _my > _ey && _my < _ey + 44) {
                    selected_expression = (selected_expression + 1) mod array_length(_exprs);
                }
            }
        }
    }
}

// --- HEIGHT SLIDER (continuous drag) ---
if (mouse_check_button(mb_left) && selected_actor >= 0) {
    var _track_x = ui_panel_x + 30; var _track_w = ui_panel_w - 60;
    var _track_y = ui_panel_y + 410;
    if (_mx >= _track_x - 8 && _mx <= _track_x + _track_w + 8 && _my > _track_y - 12 && _my < _track_y + 16) {
        height_scale = 0.5 + clamp((_mx - _track_x) / _track_w, 0, 1) * 1.0; // 0.5x .. 1.5x
    }
}

// --- KEYBOARD: ESC returns to editor ---
if (keyboard_check_pressed(vk_escape)) {
    room_goto(MainWindow);
    exit;
}
