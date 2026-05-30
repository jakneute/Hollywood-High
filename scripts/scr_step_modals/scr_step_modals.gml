/// @description Step handlers for all editor modals (dictionary, movement, pose, expression, action).

function step_modal_dictionary() {
    var _mx = mouse_x; var _my = mouse_y;
    var _m_w = 700; var _m_h = 500;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;

    if (mouse_check_button_pressed(mb_left)) {
        dict_focused_entry = -1;
        if (_mx > _m_x + 20 && _mx < _m_x + 150 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            array_push(dictionary_list, { written: "", pronunciation: "" });
            dict_focused_entry = array_length(dictionary_list) - 1;
            dict_focused_field = 0; keyboard_string = ""; dict_caret_pos = 0;
        }
        if (_mx > _m_x + _m_w - 140 && _mx < _m_x + _m_w - 20 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            dictionary_open = false;
        }
        for (var i = 0; i < array_length(dictionary_list); i++) {
            var _ey = _m_y + 80 + (i * 45) + dictionary_scroll_y;
            if (_ey < _m_y + 70 || _ey > _m_y + 400) continue;
            if (_mx > _m_x + 20 && _mx < _m_x + 260 && _my > _ey && _my < _ey + 35) {
                dict_focused_entry = i; dict_focused_field = 0; keyboard_string = "";
                var _rx = _mx - (_m_x + 25); var _best_p = 0; var _min_d = 999999;
                for (var c = 0; c <= string_length(dictionary_list[i].written); c++) {
                    var _d = abs(_rx - string_width(string_copy(dictionary_list[i].written, 1, c)));
                    if (_d < _min_d) { _min_d = _d; _best_p = c; }
                }
                dict_caret_pos = _best_p;
            }
            if (_mx > _m_x + 280 && _mx < _m_x + 520 && _my > _ey && _my < _ey + 35) {
                dict_focused_entry = i; dict_focused_field = 1; keyboard_string = "";
                var _rx = _mx - (_m_x + 285); var _best_p = 0; var _min_d = 999999;
                for (var c = 0; c <= string_length(dictionary_list[i].pronunciation); c++) {
                    var _d = abs(_rx - string_width(string_copy(dictionary_list[i].pronunciation, 1, c)));
                    if (_d < _min_d) { _min_d = _d; _best_p = c; }
                }
                dict_caret_pos = _best_p;
            }
            if (_mx > _m_x + 540 && _mx < _m_x + 610 && _my > _ey && _my < _ey + 35) {
                var _txt = (dictionary_list[i].pronunciation != "") ? dictionary_list[i].pronunciation : "Nothing to test";
                tts_stop(); tts_speak(_txt, all_voices[0].voice_id, 50, 50, 0, 0);
            }
            if (_mx > _m_x + 630 && _mx < _m_x + 670 && _my > _ey && _my < _ey + 35) {
                array_delete(dictionary_list, i, 1); break;
            }
        }
    }

    if (dict_focused_entry != -1) {
        var _entry = dictionary_list[dict_focused_entry];
        var _txt = (dict_focused_field == 0) ? _entry.written : _entry.pronunciation;
        if (keyboard_string != "") {
            _txt = string_insert(keyboard_string, _txt, dict_caret_pos + 1);
            dict_caret_pos += string_length(keyboard_string);
            keyboard_string = "";
            while (string_width(_txt) > 230) {
                _txt = string_delete(_txt, string_length(_txt), 1);
                dict_caret_pos = min(dict_caret_pos, string_length(_txt));
            }
        }
        if (keyboard_check_pressed(vk_left))  { dict_caret_pos = max(0, dict_caret_pos - 1); cursor_timer = 0; cursor_visible = true; }
        if (keyboard_check_pressed(vk_right)) { dict_caret_pos = min(string_length(_txt), dict_caret_pos + 1); cursor_timer = 0; cursor_visible = true; }
        if (keyboard_check_pressed(vk_backspace) && dict_caret_pos > 0) { _txt = string_delete(_txt, dict_caret_pos, 1); dict_caret_pos--; cursor_timer = 0; cursor_visible = true; }
        if (keyboard_check_pressed(vk_delete) && dict_caret_pos < string_length(_txt)) { _txt = string_delete(_txt, dict_caret_pos + 1, 1); cursor_timer = 0; cursor_visible = true; }
        if (dict_focused_field == 0) _entry.written = _txt; else _entry.pronunciation = _txt;
        if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape)) dict_focused_entry = -1;
    }

    if (mouse_wheel_up())   dictionary_scroll_y += 45;
    if (mouse_wheel_down()) dictionary_scroll_y -= 45;
    dictionary_scroll_y = clamp(dictionary_scroll_y, -max(0, (array_length(dictionary_list) * 45) - 320), 0);
    cursor_timer++; if (cursor_timer >= 60) cursor_timer = 0; cursor_visible = (cursor_timer < 30);
}

function step_modal_movement() {
    var _mx = mouse_x; var _my = mouse_y;
    var _m_w = 400; var _m_h = 420;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;

    if (mouse_check_button_pressed(mb_left)) {
        for (var i = 0; i < array_length(move_speed_labels); i++) {
            var _by = _m_y + 80 + (i * 45);
            if (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _by && _my < _by + 40) move_modal_temp_speed_index = i;
        }
        if (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _m_y + 310 && _my < _m_y + 330) {
            move_modal_temp_moonwalk = !move_modal_temp_moonwalk;
        }
        if (_mx > _m_x + 40 && _mx < _m_x + 180 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            if (move_modal_edit_mode && move_modal_target_index != -1) {
                var _b = script_blocks[move_modal_target_index];
                _b.speed = move_speeds[move_modal_temp_speed_index];
                var _old_moonwalk = (variable_struct_exists(_b, "moonwalk") && _b.moonwalk) || (string_pos("[moonwalk]", string_lower(_b.action_name)) > 0);
                if (_old_moonwalk != move_modal_temp_moonwalk) {
                    if (variable_struct_exists(_b, "facing")) _b.facing *= -1;
                    _b.moonwalk = move_modal_temp_moonwalk;
                }
                var _bn = _b.action_name;
                var _pos = string_pos(" (", _bn); if (_pos > 0) _bn = string_copy(_bn, 1, _pos - 1);
                _pos = string_pos(" [MOONWALK]", _bn); if (_pos > 0) _bn = string_copy(_bn, 1, _pos - 1);
                var _lbl = move_speed_labels[move_modal_temp_speed_index];
                if (_lbl != "WALK") _bn += " (" + _lbl + ")";
                if (_b.moonwalk) _bn += " [MOONWALK]";
                _b.action_name = _bn;
                move_modal_edit_mode = false;
            } else {
                move_speed_index = move_modal_temp_speed_index;
                moonwalk_enabled = move_modal_temp_moonwalk;
            }
            move_modal_open = false;
        }
        if (_mx > _m_x + 220 && _mx < _m_x + 360 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            move_modal_edit_mode = false; move_modal_open = false;
        }
    }
}

function step_modal_pose() {
    var _mx = mouse_x; var _my = mouse_y;
    var _m_w = 800; var _m_h = 420;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;

    var _hovered_pose = -1;
    for (var i = 1; i <= 4; i++) {
        var _by = _m_y + 80 + ((i-1) * 60);
        if (_mx > _m_x + 50 && _mx < _m_x + 380 && _my > _by && _my < _by + 50) { _hovered_pose = i; break; }
    }
    pose_modal_temp_pose = (_hovered_pose != -1) ? _hovered_pose : pose_modal_locked_pose;

    if (mouse_check_button_pressed(mb_left)) {
        if (_hovered_pose != -1) { pose_modal_locked_pose = _hovered_pose; pose_modal_temp_pose = _hovered_pose; }

        if (_mx > _m_x + 210 && _mx < _m_x + 360 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            if (pose_modal_locked_pose != -1) selected_pose = pose_modal_locked_pose;
            else selected_pose = pose_modal_temp_pose;
            var _char = characters[selected_character_index];
            _char.pose = selected_pose;
            var _applied_to_staging = false;
            if (scene_edit_mode && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                var _scene_block = script_blocks[active_scene_block_idx];
                if (variable_struct_exists(_scene_block, "actors")) {
                    for (var a = 0; a < array_length(_scene_block.actors); a++) {
                        var _act = _scene_block.actors[a];
                        if (_act.char_index == selected_character_index) { _act.pose = selected_pose; _applied_to_staging = true; }
                    }
                }
            }
            var _is_onstage = false;
            for (var pa = 0; pa < array_length(preview_actors); pa++) {
                var _act = preview_actors[pa];
                if (_act.char_index == selected_character_index) { _act.pose = selected_pose; _is_onstage = true; }
            }
            if ((_is_onstage || pose_modal_edit_mode) && !scene_edit_mode) {
                var _pose_lbl = string(selected_pose);
                var _current_expr = 21;
                for (var pa = 0; pa < array_length(preview_actors); pa++) {
                    if (preview_actors[pa].char_index == selected_character_index) {
                        _current_expr = variable_struct_exists(preview_actors[pa], "expression") ? preview_actors[pa].expression : 21; break;
                    }
                }
                var _expr_lbl = mood_names[_current_expr - 1];
                if (pose_modal_edit_mode && pose_modal_target_index != -1) {
                    var _old_action = script_blocks[pose_modal_target_index].action_name;
                    var _open_p = string_pos("(", _old_action); var _close_p = string_pos(")", _old_action);
                    if (_open_p > 0 && _close_p > _open_p) _expr_lbl = string_copy(_old_action, _open_p + 1, _close_p - _open_p - 1);
                }
                var _action_text = "poses " + _pose_lbl + " (" + _expr_lbl + ")";
                if (pose_modal_edit_mode && pose_modal_target_index != -1) {
                    script_blocks[pose_modal_target_index].action_name = _action_text;
                    pose_modal_edit_mode = false;
                } else {
                    var _new_a = { type: "action", char_index: selected_character_index, action_name: _action_text, height: 85 };
                    var _insert_idx = (focused_block != -1) ? focused_block + 1 : array_length(script_blocks);
                    array_insert(script_blocks, _insert_idx, _new_a);
                    update_block_height(_insert_idx);
                    focused_block = _insert_idx;
                }
            }
            pose_modal_open = false; pose_modal_edit_mode = false;
        }
        if (_mx > _m_x + 440 && _mx < _m_x + 590 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            pose_modal_open = false; pose_modal_edit_mode = false;
        }
    }
}

function step_modal_expression() {
    var _mx = mouse_x; var _my = mouse_y;
    var _m_w = 950; var _m_h = 460;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    var _cols_em = 4; var _col_w = 660 / _cols_em; var _row_h = 52;
    var _gx = _m_x + 20; var _gy = _m_y + 55;

    var _hovered_expr = -1;
    for (var e = 1; e <= 20; e++) {
        var _col = (e - 1) % _cols_em; var _row = floor((e - 1) / _cols_em);
        var _ex = _gx + _col * _col_w; var _ey = _gy + _row * _row_h;
        if (_mx > _ex && _mx < _ex + _col_w && _my > _ey && _my < _ey + _row_h) { _hovered_expr = e; break; }
    }
    expression_modal_temp_expr = (_hovered_expr != -1) ? _hovered_expr : expression_modal_locked_expr;

    if (mouse_check_button_pressed(mb_left)) {
        if (_hovered_expr != -1) { expression_modal_locked_expr = _hovered_expr; expression_modal_temp_expr = _hovered_expr; }

        if (_mx > _m_x + 275 && _mx < _m_x + 425 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            selected_expression = expression_modal_locked_expr;
            var _char = characters[selected_character_index];
            _char.expression = selected_expression;
            if (scene_edit_mode && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                var _scene_block = script_blocks[active_scene_block_idx];
                if (variable_struct_exists(_scene_block, "actors")) {
                    for (var a = 0; a < array_length(_scene_block.actors); a++) {
                        var _act = _scene_block.actors[a];
                        if (_act.char_index == selected_character_index) _act.expression = selected_expression;
                    }
                }
            }
            var _is_onstage = false;
            for (var pa = 0; pa < array_length(preview_actors); pa++) {
                var _act = preview_actors[pa];
                if (_act.char_index == selected_character_index) { _act.expression = selected_expression; _is_onstage = true; }
            }
            var _action_text = "expression: " + mood_names[selected_expression - 1];
            if (expression_modal_edit_mode && expression_modal_target_index != -1) {
                script_blocks[expression_modal_target_index].action_name = _action_text;
                expression_modal_edit_mode = false;
            } else if (_is_onstage && !scene_edit_mode) {
                var _new_a = { type: "action", char_index: selected_character_index, action_name: _action_text, height: 85 };
                var _insert_idx = (focused_block != -1) ? focused_block + 1 : array_length(script_blocks);
                array_insert(script_blocks, _insert_idx, _new_a);
                update_block_height(_insert_idx);
                focused_block = _insert_idx;
            }
            expression_modal_open = false; expression_modal_edit_mode = false;
        }
        if (_mx > _m_x + 525 && _mx < _m_x + 675 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            expression_modal_open = false; expression_modal_edit_mode = false;
        }
    }
}

function step_modal_action() {
    var _mx = mouse_x; var _my = mouse_y;
    var _mw = 900; var _mh = 550; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;

    if (mouse_check_button_pressed(mb_left)) {
        for (var i = 0; i < array_length(all_actions); i++) {
            var _is_gen = (all_actions[i].category == "general");
            var _by = _myo + 60 + (i * 45) + (_is_gen ? 25 : 0);
            var _aname = string_lower(all_actions[i].name);
            var _disabled = false;
            if (action_modal_edit_mode) {
                if (action_modal_selected_idx != i) _disabled = true;
            } else {
                if (selected_character_index == 0 && !_is_gen) _disabled = true;
                else if (!_is_gen) {
                    if (action_modal_char_onstage && string_pos("enter", _aname) > 0) _disabled = true;
                    if (!action_modal_char_onstage && string_pos("exit",  _aname) > 0) _disabled = true;
                    if (!action_modal_char_onstage && string_pos("turn",  _aname) > 0) _disabled = true;
                }
            }
            if (!_disabled && _mx > _mxo+20 && _mx < _mxo+250 && _my > _by && _my < _by+40) {
                action_modal_selected_idx = i; action_modal_locked = true;
                if (all_actions[i].name == "play sfx") { refresh_sfx_folders(); action_modal_sfx_folder_idx = -1; action_modal_sfx_file_idx = -1; }
                else if (all_actions[i].name == "display title") { action_modal_title_text = ""; action_modal_wait_duration = 2.0; action_modal_dropdown_open = ""; keyboard_string = ""; }
                return;
            }
        }

        if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "wait") {
            var _sw = 400; var _wx = _mxo + 320; var _wy = _myo + 250;
            var _perc = (action_modal_wait_duration - 0.1) / 9.9;
            var _hx = _wx + 30 + (_perc * _sw);
            var _chk_left = (_mx > _wx - 5 && _mx < _wx + 25 && _my > _wy - 10 && _my < _wy + 35);
            var _chk_right = (_mx > _wx + _sw + 35 && _mx < _wx + _sw + 75 && _my > _wy - 10 && _my < _wy + 35);
            if (!_chk_left && !_chk_right && _mx > _hx - 15 && _mx < _hx + 15 && _my > _wy - 10 && _my < _wy + 35) action_modal_slider_dragging = true;
        }

        if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "play sfx") {
            var _wx = _mxo + 300; var _wy = _myo + 130;
            var _fx = _mxo + 280; var _fy = _wy + 65; var _fh = 215;
            var _lx = _mxo + 550; var _ly = _wy + 65; var _lh = 215;
            if (_mx > _fx + 10 && _mx < _fx + 230 && _my > _fy && _my < _fy + _fh) {
                for (var f = 0; f < array_length(action_modal_sfx_folders); f++) {
                    var _by = _fy + (f * 30) - action_modal_sfx_scroll_y;
                    if (_my > _by && _my < _by + 30) { action_modal_sfx_folder_idx = f; refresh_sfx_files(action_modal_sfx_folders[f]); action_modal_sfx_file_idx = -1; action_modal_sfx_files_scroll_y = 0; }
                }
            }
            if (_mx > _lx - 10 && _mx < _lx + 300 && _my > _ly && _my < _ly + _lh) {
                for (var f = 0; f < array_length(action_modal_sfx_files); f++) {
                    var _by = _ly + (f * 30) - action_modal_sfx_files_scroll_y;
                    if (_my > _by && _my < _by + 30) action_modal_sfx_file_idx = f;
                }
            }
            var _tx = _mxo + _mw - 150; var _ty = _myo + _mh - 120;
            if (_mx > _tx && _mx < _tx + 120 && _my > _ty && _my < _ty + 35) {
                if (action_modal_sfx_folder_idx != -1 && action_modal_sfx_file_idx != -1) {
                    var _folder = action_modal_sfx_folders[action_modal_sfx_folder_idx];
                    var _file = action_modal_sfx_files[action_modal_sfx_file_idx];
                    var _tmp_buf = load_sfx_buffer(_folder, _file);
                    if (_tmp_buf != -1) {
                        if (test_sfx_sound != -1) { audio_free_buffer_sound(test_sfx_sound); test_sfx_sound = -1; }
                        if (test_sfx_buffer != -1) { buffer_delete(test_sfx_buffer); test_sfx_buffer = -1; }
                        var _sz = buffer_get_size(_tmp_buf);
                        test_sfx_buffer = buffer_create(_sz, buffer_fixed, 1);
                        buffer_copy(_tmp_buf, 0, _sz, test_sfx_buffer, 0);
                        buffer_delete(_tmp_buf);
                        buffer_seek(test_sfx_buffer, buffer_seek_start, 22); var _chan = buffer_read(test_sfx_buffer, buffer_u16);
                        buffer_seek(test_sfx_buffer, buffer_seek_start, 24); var _rate = buffer_read(test_sfx_buffer, buffer_u32);
                        buffer_seek(test_sfx_buffer, buffer_seek_start, 34); var _bits = buffer_read(test_sfx_buffer, buffer_u16);
                        var _fmt = (_bits == 16) ? buffer_s16 : buffer_u8;
                        var _cfmt = (_chan == 2) ? audio_stereo : audio_mono;
                        test_sfx_sound = audio_create_buffer_sound(test_sfx_buffer, _fmt, _rate, 44, _sz - 44, _cfmt);
                        if (test_sfx_sound != -1) audio_play_sound(test_sfx_sound, 1, false);
                    }
                }
            }
        }

        if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "display title") {
            var _wx = _mxo + 300; var _wy = _myo + 100;
            var _clicked_dropdown = false;
            if (action_modal_dropdown_open != "") {
                var _opts = []; var _dx = 0; var _dy = 0;
                if (action_modal_dropdown_open == "align")  { _opts = action_modal_title_align_opts;  _dx = _wx + 60;  _dy = _wy + 230; }
                else if (action_modal_dropdown_open == "size")  { _opts = action_modal_title_size_opts;  _dx = _wx + 350; _dy = _wy + 230; }
                else if (action_modal_dropdown_open == "font")  { _opts = action_modal_title_font_opts;  _dx = _wx + 60;  _dy = _wy + 280; }
                else if (action_modal_dropdown_open == "color") { _opts = action_modal_title_color_opts; _dx = _wx + 350; _dy = _wy + 280; }
                if (array_length(_opts) > 0) {
                    for (var d = 0; d < array_length(_opts); d++) {
                        if (_mx > _dx && _mx < _dx + 200 && _my > _dy + 25 + (d * 30) && _my < _dy + 25 + ((d+1) * 30)) {
                            if (action_modal_dropdown_open == "align")  action_modal_title_align = d;
                            else if (action_modal_dropdown_open == "size")  action_modal_title_size  = d;
                            else if (action_modal_dropdown_open == "font")  action_modal_title_font  = d;
                            else if (action_modal_dropdown_open == "color") action_modal_title_color = d;
                            action_modal_dropdown_open = ""; _clicked_dropdown = true; break;
                        }
                    }
                    if (!_clicked_dropdown) action_modal_dropdown_open = "";
                }
            }
            if (!_clicked_dropdown && action_modal_dropdown_open == "") {
                if      (_mx > _wx + 60  && _mx < _wx + 260 && _my > _wy + 230 && _my < _wy + 255) { action_modal_dropdown_open = "align";  _clicked_dropdown = true; }
                else if (_mx > _wx + 350 && _mx < _wx + 550 && _my > _wy + 230 && _my < _wy + 255) { action_modal_dropdown_open = "size";   _clicked_dropdown = true; }
                else if (_mx > _wx + 60  && _mx < _wx + 260 && _my > _wy + 280 && _my < _wy + 305) { action_modal_dropdown_open = "font";   _clicked_dropdown = true; }
                else if (_mx > _wx + 350 && _mx < _wx + 550 && _my > _wy + 280 && _my < _wy + 305) { action_modal_dropdown_open = "color";  _clicked_dropdown = true; }
            }
            if (_clicked_dropdown) return;
            var _sw = 300; var _sx = _wx + 100; var _sy = _wy + 170;
            var _perc = (action_modal_wait_duration - 0.1) / 9.9;
            var _hx = _sx + (_perc * _sw);
            var _chk_left  = (_mx > _sx - 35 && _mx < _sx - 5  && _my > _sy - 10 && _my < _sy + 35);
            var _chk_right = (_mx > _sx + _sw + 5 && _mx < _sx + _sw + 45 && _my > _sy - 10 && _my < _sy + 35);
            if (!_chk_left && !_chk_right && _mx > _hx - 15 && _mx < _hx + 15 && _my > _sy - 10 && _my < _sy + 35) action_modal_slider_dragging = true;
        }

        if (action_modal_locked && _mx > _mxo+_mw-280 && _mx < _mxo+_mw-150 && _my > _myo+_mh-50 && _my < _myo+_mh-15) {
            var _act_name = all_actions[action_modal_selected_idx].name;
            var _can_proceed = true; var _sfx_path = "";
            if (_act_name == "wait") {
                _act_name = "WAIT " + string(action_modal_wait_duration) + " SECONDS";
            } else if (_act_name == "display title") {
                if (action_modal_title_text == "") _can_proceed = false;
                else _act_name = "DISPLAY TITLE \"" + string_replace_all(action_modal_title_text, "\n", " ") + "\"";
            } else if (_act_name == "play sfx") {
                if (action_modal_sfx_folder_idx == -1 || action_modal_sfx_file_idx == -1) _can_proceed = false;
                else {
                    var _folder = action_modal_sfx_folders[action_modal_sfx_folder_idx];
                    var _sfx_file = action_modal_sfx_files[action_modal_sfx_file_idx];
                    _sfx_path = "sounds/" + _folder + "/" + _sfx_file;
                    _act_name = "Play SFX: " + string_replace(string_upper(_sfx_file), ".WAV", "");
                }
            }
            if (_can_proceed) {
                if (action_modal_edit_mode) {
                    var _b = script_blocks[action_modal_target_index];
                    _b.action_name = _act_name;
                    if (all_actions[action_modal_selected_idx].name == "wait") _b.duration = action_modal_wait_duration;
                    else if (all_actions[action_modal_selected_idx].name == "display title") {
                        _b.duration = action_modal_wait_duration; _b.title_text = action_modal_title_text;
                        _b.title_align = action_modal_title_align; _b.title_font = action_modal_title_font;
                        _b.title_size = action_modal_title_size; _b.title_color = action_modal_title_color;
                    } else if (all_actions[action_modal_selected_idx].name == "play sfx") _b.sfx_path = _sfx_path;
                    action_modal_edit_mode = false;
                } else {
                    var _new_a = { type: "action", char_index: selected_character_index, action_name: _act_name, height: 85 };
                    if (all_actions[action_modal_selected_idx].name == "wait") { _new_a.duration = action_modal_wait_duration; _new_a.char_index = 0; }
                    else if (all_actions[action_modal_selected_idx].name == "display title") {
                        _new_a.duration = action_modal_wait_duration; _new_a.title_text = action_modal_title_text;
                        _new_a.title_align = action_modal_title_align; _new_a.title_font = action_modal_title_font;
                        _new_a.title_size = action_modal_title_size; _new_a.title_color = action_modal_title_color;
                        _new_a.char_index = 0;
                    } else if (all_actions[action_modal_selected_idx].name == "play sfx") { _new_a.sfx_path = _sfx_path; _new_a.char_index = 0; }
                    if (action_modal_target_index == -1) array_push(script_blocks, _new_a);
                    else array_insert(script_blocks, action_modal_target_index, _new_a);
                }
                update_all_block_heights();
                action_modal_open = false;
                var _th = 0; for (var k = 0; k < array_length(script_blocks); k++) _th += script_blocks[k].height + 20;
                block_scroll_y = min(0, (box_h - 40) - _th);
                return;
            }
        }
        if (_mx > _mxo+_mw-130 && _mx < _mxo+_mw-20 && _my > _myo+_mh-50 && _my < _myo+_mh-15) {
            action_modal_edit_mode = false; action_modal_open = false; return;
        }
    }

    if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "play sfx") {
        var _wx = _mxo + 300; var _wy = _myo + 130;
        var _fx = _mxo + 280; var _fy = _wy + 65; var _fh = 215;
        var _lx = _mxo + 550; var _ly = _wy + 65; var _lh = 215;
        if (_mx > _fx + 10 && _mx < _fx + 240 && _my > _fy && _my < _fy + _fh) {
            if (mouse_wheel_up())   action_modal_sfx_scroll_y -= 60;
            if (mouse_wheel_down()) action_modal_sfx_scroll_y += 60;
        }
        if (_mx > _lx - 10 && _mx < _lx + 310 && _my > _ly && _my < _ly + _lh) {
            if (mouse_wheel_up())   action_modal_sfx_files_scroll_y -= 60;
            if (mouse_wheel_down()) action_modal_sfx_files_scroll_y += 60;
        }
        var _max_s = max(0, (array_length(action_modal_sfx_folders) * 30) - _fh);
        var _max_f = max(0, (array_length(action_modal_sfx_files)  * 30) - _lh);
        action_modal_sfx_scroll_y       = clamp(action_modal_sfx_scroll_y,       0, _max_s);
        action_modal_sfx_files_scroll_y = clamp(action_modal_sfx_files_scroll_y, 0, _max_f);
        if (mouse_check_button_pressed(mb_left)) {
            if (_max_s > 0 && _mx > _fx + 232 && _mx < _fx + 240 && _my > _fy && _my < _fy + _fh) action_modal_sfx_dragging_folder = true;
            if (_max_f > 0 && _mx > _lx + 302 && _mx < _lx + 310 && _my > _ly && _my < _ly + _lh) action_modal_sfx_dragging_file = true;
        }
        if (action_modal_sfx_dragging_folder) {
            if (mouse_check_button(mb_left)) action_modal_sfx_scroll_y = clamp((_my - _fy) / _fh, 0, 1) * _max_s;
            else action_modal_sfx_dragging_folder = false;
        }
        if (action_modal_sfx_dragging_file) {
            if (mouse_check_button(mb_left)) action_modal_sfx_files_scroll_y = clamp((_my - _ly) / _lh, 0, 1) * _max_f;
            else action_modal_sfx_dragging_file = false;
        }
    }

    if (action_modal_selected_idx != -1 && (all_actions[action_modal_selected_idx].name == "wait" || all_actions[action_modal_selected_idx].name == "display title")) {
        var _is_title = (all_actions[action_modal_selected_idx].name == "display title");
        var _sw = _is_title ? 300 : 400;
        var _wx = _mxo + (_is_title ? 300 : 320); var _wy = _myo + (_is_title ? 100 : 250);
        var _sx = _is_title ? _wx + 100 : _wx + 30; var _sy = _is_title ? _wy + 170 : _wy;
        var _on_left  = (_mx > _sx - 35 && _mx < _sx - 5 && _my > _sy - 10 && _my < _sy + 35);
        var _on_right = (_mx > _sx + _sw + 5 && _mx < _sx + _sw + 45 && _my > _sy - 10 && _my < _sy + 35);
        if (!action_modal_slider_dragging && mouse_check_button(mb_left) && (_on_left || _on_right)) {
            var _do_tick = false;
            if (mouse_check_button_pressed(mb_left)) { _do_tick = true; arrow_repeat_timer = 20; }
            else { arrow_repeat_timer--; if (arrow_repeat_timer <= 0) { _do_tick = true; arrow_repeat_timer = 4; } }
            if (_do_tick) {
                if (_on_left)  action_modal_wait_duration = max(0.1, action_modal_wait_duration - 0.1);
                if (_on_right) action_modal_wait_duration = min(10.0, action_modal_wait_duration + 0.1);
                action_modal_wait_duration = round(action_modal_wait_duration * 10.0) / 10.0;
            }
        } else if (!mouse_check_button(mb_left)) {
            arrow_repeat_timer = 0;
        }
    }

    if (action_modal_slider_dragging) {
        if (mouse_check_button(mb_left)) {
            var _is_title = (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "display title");
            var _sw = _is_title ? 300.0 : 400.0;
            var _track_start = _is_title ? (_mxo + 400.0) : (_mxo + 350.0);
            var _perc = clamp((_mx - _track_start) / _sw, 0.0, 1.0);
            action_modal_wait_duration = round(clamp(0.1 + (_perc * 9.9), 0.1, 10.0) * 10.0) / 10.0;
        } else { action_modal_slider_dragging = false; }
    }

    if (action_modal_open && action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "display title") {
        if (keyboard_string != "") {
            var _new_text = action_modal_title_text + keyboard_string;
            if (string_length(_new_text) <= 100) action_modal_title_text = _new_text;
            keyboard_string = "";
        }
        if (keyboard_check_pressed(vk_backspace) && string_length(action_modal_title_text) > 0) {
            action_modal_title_text = string_copy(action_modal_title_text, 1, string_length(action_modal_title_text) - 1);
            cursor_timer = 0; cursor_visible = true;
        }
        if (keyboard_check_pressed(vk_enter)) {
            var _lines = string_count("\n", action_modal_title_text);
            if (_lines < 2 && string_length(action_modal_title_text) < 100) action_modal_title_text += "\n";
        }
    }
}
