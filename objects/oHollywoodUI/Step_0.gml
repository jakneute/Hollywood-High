/// @description Advanced Block Editor Logic (Fixed & Restored)
check_timer++; // Throttle timer: rate-limits disk file_exists() polls to ~10 Hz to eliminate OS spinning cursor
var _mx = mouse_x; var _my = mouse_y;
var _overlay_active = false;
var _scene = -1;

// Flush pending JSON save from save_expr_config() — file_text_write must run here,
// not inside a method, to avoid GML's built-in scope resolution bug.
if (expr_cfg_pending_save_path != "") {
    var _sf = file_text_open_write(expr_cfg_pending_save_path);
    file_text_write_string(_sf, expr_cfg_pending_save_data);
    file_text_close(_sf);
    expr_cfg_pending_save_path = "";
    expr_cfg_pending_save_data = "";
}

// --- 0. MODAL OVERLAY BLOCKING ---
// Ensure modals capture all input and prevent background logic from running
if (dictionary_open) {
    var _m_w = 700; var _m_h = 500;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    
    if (mouse_check_button_pressed(mb_left)) {
        dict_focused_entry = -1;
        // Add New Entry
        if (_mx > _m_x + 20 && _mx < _m_x + 150 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            array_push(dictionary_list, { written: "", pronunciation: "" });
            dict_focused_entry = array_length(dictionary_list) - 1;
            dict_focused_field = 0; keyboard_string = "";
            dict_caret_pos = 0;
        }
        // Close Button
        if (_mx > _m_x + _m_w - 140 && _mx < _m_x + _m_w - 20 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            dictionary_open = false;
        }
        
        // Entry Interactions
        for (var i = 0; i < array_length(dictionary_list); i++) {
            var _ey = _m_y + 80 + (i * 45) + dictionary_scroll_y;
            if (_ey < _m_y + 70 || _ey > _m_y + 400) continue;
            
            // Written Column Focus
            if (_mx > _m_x + 20 && _mx < _m_x + 260 && _my > _ey && _my < _ey + 35) {
                dict_focused_entry = i; dict_focused_field = 0; 
                keyboard_string = "";
                var _rx = _mx - (_m_x + 25);
                var _best_p = 0; var _min_d = 999999;
                for (var c = 0; c <= string_length(dictionary_list[i].written); c++) {
                    var _d = abs(_rx - string_width(string_copy(dictionary_list[i].written, 1, c)));
                    if (_d < _min_d) { _min_d = _d; _best_p = c; }
                }
                dict_caret_pos = _best_p;
            }
            // Pronunciation Column Focus
            if (_mx > _m_x + 280 && _mx < _m_x + 520 && _my > _ey && _my < _ey + 35) {
                dict_focused_entry = i; dict_focused_field = 1; 
                keyboard_string = "";
                var _rx = _mx - (_m_x + 285);
                var _best_p = 0; var _min_d = 999999;
                for (var c = 0; c <= string_length(dictionary_list[i].pronunciation); c++) {
                    var _d = abs(_rx - string_width(string_copy(dictionary_list[i].pronunciation, 1, c)));
                    if (_d < _min_d) { _min_d = _d; _best_p = c; }
                }
                dict_caret_pos = _best_p;
            }
            // Test Button
            if (_mx > _m_x + 540 && _mx < _m_x + 610 && _my > _ey && _my < _ey + 35) {
                var _txt = (dictionary_list[i].pronunciation != "") ? dictionary_list[i].pronunciation : "Nothing to test";
                tts_stop(); tts_speak(_txt, all_voices[0].voice_id, 50, 50, 0, 0);
            }
            // Remove (X) Button
            if (_mx > _m_x + 630 && _mx < _m_x + 670 && _my > _ey && _my < _ey + 35) {
                array_delete(dictionary_list, i, 1); break;
            }
        }
    }
    
    // Keyboard Input for Dictionary Fields
    if (dict_focused_entry != -1) {
        var _entry = dictionary_list[dict_focused_entry];
        var _txt = (dict_focused_field == 0) ? _entry.written : _entry.pronunciation;
        
        if (keyboard_string != "") {
            _txt = string_insert(keyboard_string, _txt, dict_caret_pos + 1);
            dict_caret_pos += string_length(keyboard_string);
            keyboard_string = "";
            
            // Enforce visual width limit
            while (string_width(_txt) > 230) {
                _txt = string_delete(_txt, string_length(_txt), 1);
                dict_caret_pos = min(dict_caret_pos, string_length(_txt));
            }
        }

        if (keyboard_check_pressed(vk_left)) { dict_caret_pos = max(0, dict_caret_pos - 1); cursor_timer = 0; cursor_visible = true; }
        if (keyboard_check_pressed(vk_right)) { dict_caret_pos = min(string_length(_txt), dict_caret_pos + 1); cursor_timer = 0; cursor_visible = true; }
        if (keyboard_check_pressed(vk_backspace) && dict_caret_pos > 0) {
            _txt = string_delete(_txt, dict_caret_pos, 1);
            dict_caret_pos--;
            cursor_timer = 0; cursor_visible = true;
        }
        if (keyboard_check_pressed(vk_delete) && dict_caret_pos < string_length(_txt)) {
            _txt = string_delete(_txt, dict_caret_pos + 1, 1);
            cursor_timer = 0; cursor_visible = true;
        }

        if (dict_focused_field == 0) _entry.written = _txt;
        else _entry.pronunciation = _txt;

        if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape)) {
            dict_focused_entry = -1;
        }
    }

    if (mouse_wheel_up()) dictionary_scroll_y += 45;
    if (mouse_wheel_down()) dictionary_scroll_y -= 45;
    dictionary_scroll_y = clamp(dictionary_scroll_y, -max(0, (array_length(dictionary_list) * 45) - 320), 0);

    cursor_timer++; if (cursor_timer >= 60) cursor_timer = 0; cursor_visible = (cursor_timer < 30);
    return;
}

if (expr_cfg_open) {
    _overlay_active = true;
    var _m_x = 85; var _m_y = 55; var _m_w = 1110; var _m_h = 770;
    var _lx = _m_x + 12; var _ly = _m_y + 12;
    var _c_s = characters[expr_cfg_char_idx];
    var _nav_y_s = _ly + 28;
    var _pose_ys = _nav_y_s + 36;
    var _dir_ys = _pose_ys + 36;
    var _layer_y0_s = _dir_ys + 38;
    var _nudge_ys = _layer_y0_s + 4 * 52 + 6;
    var _esel_ys = _nudge_ys + 110;

    // Get body spr + scale for drag calculations
    var _pc_s = expr_cfg_get_pc();
    
    // Resolve currently active file for selected layer (defined early for nudges/dragging)
    var get_active_layer_file = function() {
        var _c_s = characters[expr_cfg_char_idx];
        var _pc_s = expr_cfg_get_pc();
        var _cur_file_s = "";
        var _layer_key_s = "";
        switch (expr_cfg_selected_layer) {
            case 0:
                _cur_file_s = _pc_s.body_file;
                _layer_key_s = "body";
                break;
            case 1:
                _cur_file_s = _pc_s.face_file;
                _layer_key_s = "face";
                break;
            case 2:
                var _eyes_file_s = "";
                if (_pc_s != undefined && variable_struct_exists(_pc_s, "eyes_files")) {
                    var _ef_s = _pc_s.eyes_files;
                    var _ef_ek = string(expr_cfg_preview_expr);
                    if (variable_struct_exists(_ef_s, _ef_ek) && _ef_s[$ _ef_ek] != "") _eyes_file_s = _ef_s[$ _ef_ek];
                }
                if (_eyes_file_s == "") {
                    var _ai_s = variable_struct_exists(_c_s, "act_index") ? _c_s.act_index : 1;
                    var _sfx_off_s = expr_cfg_high ? 50 : 0;
                    var _pfx_s = string(_ai_s) + string(expr_cfg_pose);
                    var _eyes_n_s = 10 + expr_cfg_preview_expr + _sfx_off_s;
                    _eyes_file_s = "pose_" + _pfx_s + ((_eyes_n_s < 10 ? "0" : "") + string(_eyes_n_s)) + ".png";
                }
                _cur_file_s = _eyes_file_s;
                _layer_key_s = "eyes";
                break;
            case 3:
                var _s_mood_map = [0, 2, 3, 1, 0, 1, 1, 1, 1, 0, 2, 1, 1, 1, 0, 3, 1, 0, 1, 2];
                var _derived_mood_s = _s_mood_map[clamp(expr_cfg_preview_expr - 1, 0, 19)];
                var _mouth_file_s = "";
                if (_pc_s != undefined && variable_struct_exists(_pc_s, "mouth_files")) {
                    var _mf_s = _pc_s.mouth_files;
                    var _expr_key = string(expr_cfg_preview_expr);
                    var _mood_key = string(_derived_mood_s);
                    if (variable_struct_exists(_mf_s, _expr_key) && _mf_s[$ _expr_key] != "") {
                        _mouth_file_s = _mf_s[$ _expr_key];
                    } else if (variable_struct_exists(_mf_s, _mood_key) && _mf_s[$ _mood_key] != "") {
                        _mouth_file_s = _mf_s[$ _mood_key];
                    }
                }
                if (_mouth_file_s == "") {
                    var _ai_s = variable_struct_exists(_c_s, "act_index") ? _c_s.act_index : 1;
                    var _sfx_off_s = expr_cfg_high ? 50 : 0;
                    var _pfx_s = string(_ai_s) + string(expr_cfg_pose);
                    var _mouth_n_s = 31 + _derived_mood_s + _sfx_off_s;
                    _mouth_file_s = "pose_" + _pfx_s + ((_mouth_n_s < 10 ? "0" : "") + string(_mouth_n_s)) + ".png";
                }
                _cur_file_s = _mouth_file_s;
                _layer_key_s = "mouth";
                break;
        }
        return { file: _cur_file_s, key: _layer_key_s };
    };

    var _body_spr_s = -1;
    if (_pc_s != undefined && _pc_s.body_file != "") {
        var _bks = _c_s.name + "_" + _pc_s.body_file;
        if (ds_map_exists(char_sprites, _bks)) _body_spr_s = char_sprites[? _bks];
    }
    var _ph_s = _m_h - 20;
    var _char_preview_h_s = floor(_ph_s * 0.58);
    var _base_sc_s = 2.0;
    if (_body_spr_s != -1) _base_sc_s = min((_ph_s - 60) / sprite_get_height(_body_spr_s), 4.0);
    var _cfg_sc_s = _base_sc_s * expr_cfg_zoom;
    var _px_s = _m_x + 298; var _py_s = _m_y + 10; var _pw_s = _m_w - 308;
    var _bdw_s = (_body_spr_s != -1) ? sprite_get_width(_body_spr_s)  : 80;
    var _bdh_s = (_body_spr_s != -1) ? sprite_get_height(_body_spr_s) : 100;
    var _anch_xs = _px_s + _pw_s / 2;
    var _anch_ys = _py_s + _ph_s - 25;
    var _drawx_s = _anch_xs - _bdw_s * _cfg_sc_s / 2;
    var _drawy_s = _anch_ys - _bdh_s * _cfg_sc_s;

    if (mouse_check_button_pressed(mb_left)) {
        // Character nav
        if (_mx > _lx && _mx < _lx + 28 && _my > _nav_y_s && _my < _nav_y_s + 28) {
            expr_cfg_char_idx = (expr_cfg_char_idx - 1 + array_length(characters)) mod array_length(characters);
            open_expr_configurator(expr_cfg_char_idx);
        }
        if (_mx > _lx + 253 && _mx < _lx + 281 && _my > _nav_y_s && _my < _nav_y_s + 28) {
            expr_cfg_char_idx = (expr_cfg_char_idx + 1) mod array_length(characters);
            open_expr_configurator(expr_cfg_char_idx);
        }

        // Pose buttons
        for (var _pi = 1; _pi <= 4; _pi++) {
            var _pbxs = _lx + 45 + (_pi - 1) * 58;
            if (_mx > _pbxs && _mx < _pbxs + 48 && _my > _pose_ys && _my < _pose_ys + 28) {
                expr_cfg_pose = _pi;
            }
        }

        // Direction toggle
        if (_mx > _lx && _mx < _lx + 132 && _my > _dir_ys && _my < _dir_ys + 28) expr_cfg_high = false;
        if (_mx > _lx + 142 && _mx < _lx + 274 && _my > _dir_ys && _my < _dir_ys + 28) expr_cfg_high = true;

        // Layer selection (body = 0 is now selectable)
        for (var _li = 0; _li <= 3; _li++) {
            var _lbys = _layer_y0_s + _li * 52;
            if (_mx > _lx && _mx < _lx + 280 && _my > _lbys && _my < _lbys + 46)
                expr_cfg_selected_layer = _li;
        }

        // Preview expression selector (left panel)
        var _ecols_s = 5; var _eboxw_s = 52; var _eboxh_s = 36; var _egap_s = 4;
        for (var _ei = 1; _ei <= 20; _ei++) {
            var _ex3 = _lx + ((_ei - 1) % _ecols_s) * (_eboxw_s + _egap_s);
            var _ey3 = _esel_ys + 18 + floor((_ei - 1) / _ecols_s) * (_eboxh_s + _egap_s);
            if (_mx > _ex3 && _mx < _ex3 + _eboxw_s && _my > _ey3 && _my < _ey3 + _eboxh_s) expr_cfg_preview_expr = _ei;
        }

        // ── File browser: item click → assign file to layer/slot ──
        var _fb_y_s = _py_s + _char_preview_h_s + 4 + 28; // just past the header bar
        var _fb_cols_s = 3;
        var _fb_item_w_s = floor((_m_w - 308) / _fb_cols_s);
        var _fb_item_h_s = 22;
        if (_mx > _px_s && _mx < _px_s + (_m_w - 308) && _my > _fb_y_s && _pc_s != undefined) {
            var _frow_click = floor((_my - _fb_y_s) / _fb_item_h_s);
            var _fcol_click = floor((_mx - _px_s) / _fb_item_w_s);
            var _fi_click = (expr_cfg_file_scroll + _frow_click) * _fb_cols_s + _fcol_click;
            if (_fi_click >= 0 && _fi_click < array_length(expr_cfg_file_list)) {
                var _chosen = expr_cfg_file_list[_fi_click];
                switch (expr_cfg_selected_layer) {
                    case 0: _pc_s.body_file = _chosen; break;
                    case 1: _pc_s.face_file = _chosen; break;
                    case 2:
                        if (!variable_struct_exists(_pc_s, "eyes_files")) _pc_s.eyes_files = {};
                        _pc_s.eyes_files[$ string(expr_cfg_preview_expr)] = _chosen;
                        break;
                    case 3:
                        if (!variable_struct_exists(_pc_s, "mouth_files")) _pc_s.mouth_files = {};
                        _pc_s.mouth_files[$ string(expr_cfg_preview_expr)] = _chosen;
                        break;
                }
                // Invalidate the runtime cache for this character so results show right away
                if (ds_map_exists(char_expr_cache, _c_s.name)) {
                    ds_map_delete(char_expr_cache, _c_s.name);
                }
            }
        }

        // Preview area click → drag currently selected layer (selected via left panel icons)
        if (_mx > _px_s && _mx < _px_s + _pw_s && _my > _py_s && _my < _py_s + _ph_s && _pc_s != undefined) {
            expr_cfg_drag  = true;
            expr_cfg_drag_mx0 = _mx; expr_cfg_drag_my0 = _my;
            
            var _info = get_active_layer_file();
            var _cur_file_s = _info.file;
            var _layer_key_s = _info.key;
            
            var _dx_struct_key = _layer_key_s + "_dx_offsets";
            var _dy_struct_key = _layer_key_s + "_dy_offsets";
            var _offset_key = _cur_file_s;
            if (_layer_key_s == "eyes" || _layer_key_s == "mouth") {
                _dx_struct_key = _layer_key_s + "_dx_expr_offsets";
                _dy_struct_key = _layer_key_s + "_dy_expr_offsets";
                _offset_key = string(expr_cfg_preview_expr);
            }
            
            if (!variable_struct_exists(_pc_s, _dx_struct_key)) _pc_s[$ _dx_struct_key] = {};
            if (!variable_struct_exists(_pc_s, _dy_struct_key)) _pc_s[$ _dy_struct_key] = {};
            var _dx_map = _pc_s[$ _dx_struct_key];
            var _dy_map = _pc_s[$ _dy_struct_key];
            if (!variable_struct_exists(_dx_map, _offset_key)) _dx_map[$ _offset_key] = 0;
            if (!variable_struct_exists(_dy_map, _offset_key)) _dy_map[$ _offset_key] = 0;
            
            expr_cfg_drag_dx0 = _dx_map[$ _offset_key];
            expr_cfg_drag_dy0 = _dy_map[$ _offset_key];
        }

        // Bottom buttons: SAVE, CLOSE
        var _btn_ys = _m_y + _m_h - 52;
        var _btn_w  = 50; var _btn_gap = 8;
        if (_mx > _lx && _mx < _lx + _btn_w && _my > _btn_ys && _my < _btn_ys + 40) {
            save_expr_config();
        }
        var _cls_x_new = _lx + _btn_w + _btn_gap;
        if (_mx > _cls_x_new && _mx < _cls_x_new + _btn_w && _my > _btn_ys && _my < _btn_ys + 40) {
            expr_cfg_open = false; expr_cfg_drag = false;
        }
    }

    // Drag release
    if (!mouse_check_button(mb_left)) expr_cfg_drag = false;

    // Active drag: update dx/dy in real time
    if (expr_cfg_drag && mouse_check_button(mb_left) && _pc_s != undefined) {
        var _ddx = round((_mx - expr_cfg_drag_mx0) / _cfg_sc_s);
        var _ddy = round((_my - expr_cfg_drag_my0) / _cfg_sc_s);
        
        var _info = get_active_layer_file();
        var _cur_file_s = _info.file;
        var _layer_key_s = _info.key;
        
        var _dx_struct_key = _layer_key_s + "_dx_offsets";
        var _dy_struct_key = _layer_key_s + "_dy_offsets";
        var _offset_key = _cur_file_s;
        if (_layer_key_s == "eyes" || _layer_key_s == "mouth") {
            _dx_struct_key = _layer_key_s + "_dx_expr_offsets";
            _dy_struct_key = _layer_key_s + "_dy_expr_offsets";
            _offset_key = string(expr_cfg_preview_expr);
        }
        
        var _dx_map = _pc_s[$ _dx_struct_key];
        var _dy_map = _pc_s[$ _dy_struct_key];
        
        _dx_map[$ _offset_key] = expr_cfg_drag_dx0 + _ddx;
        _dy_map[$ _offset_key] = expr_cfg_drag_dy0 + _ddy;
        
        if (ds_map_exists(char_expr_cache, _c_s.name)) ds_map_delete(char_expr_cache, _c_s.name);
    }

    // Middle click to reset zoom
    if (mouse_check_button_pressed(mb_middle)) expr_cfg_zoom = 1.0;

    // File browser mouse wheel scroll
    if (_mx > _px_s && _mx < _px_s + (_m_w - 308)) {
        if (_my < _py_s + _char_preview_h_s) {
            // Zoom logic for preview pane
            if (mouse_wheel_up())   expr_cfg_zoom = min(expr_cfg_zoom + 0.1, 8.0);
            if (mouse_wheel_down()) expr_cfg_zoom = max(expr_cfg_zoom - 0.1, 0.2);
        } else {
            // File browser scroll logic
            var _fb_cols_scroll = 3;
            var _fb_total_rows = ceil(array_length(expr_cfg_file_list) / _fb_cols_scroll);
            var _fb_vis_rows_s = floor(floor((_m_h - 20) * 0.42 - 56) / 22);
            if (mouse_wheel_up())   expr_cfg_file_scroll = max(0, expr_cfg_file_scroll - 1);
            if (mouse_wheel_down()) expr_cfg_file_scroll = min(max(0, _fb_total_rows - _fb_vis_rows_s), expr_cfg_file_scroll + 1);
        }
    }

    // Handle dx/dy nudge button repetition
    if (mouse_check_button(mb_left) && _pc_s != undefined && !expr_cfg_drag) {
        var _clicked_axis = -1; var _clicked_dir = 0;
        for (var _ai2 = 0; _ai2 <= 1; _ai2++) {
            var _ny2 = _nudge_ys + _ai2 * 34;
            if (_mx > _lx + 30 && _mx < _lx + 57 && _my > _ny2 && _my < _ny2 + 27) { _clicked_axis = _ai2; _clicked_dir = -1; break; }
            if (_mx > _lx + 110 && _mx < _lx + 137 && _my > _ny2 && _my < _ny2 + 27) { _clicked_axis = _ai2; _clicked_dir = 1; break; }
        }
        if (_clicked_axis != -1) {
            var _do_nudge = false;
            if (mouse_check_button_pressed(mb_left)) { _do_nudge = true; arrow_repeat_timer = 20; }
            else { arrow_repeat_timer--; if (arrow_repeat_timer <= 0) { _do_nudge = true; arrow_repeat_timer = 2; } }
            if (_do_nudge) {
                var _info = get_active_layer_file();
                var _cur_file_s = _info.file;
                var _layer_key_s = _info.key;
                
                var _dx_struct_key = _layer_key_s + "_dx_offsets";
                var _dy_struct_key = _layer_key_s + "_dy_offsets";
                if (!variable_struct_exists(_pc_s, _dx_struct_key)) _pc_s[$ _dx_struct_key] = {};
                if (!variable_struct_exists(_pc_s, _dy_struct_key)) _pc_s[$ _dy_struct_key] = {};
                var _dx_map = _pc_s[$ _dx_struct_key];
                var _dy_map = _pc_s[$ _dy_struct_key];
                if (!variable_struct_exists(_dx_map, _cur_file_s)) _dx_map[$ _cur_file_s] = 0;
                if (!variable_struct_exists(_dy_map, _cur_file_s)) _dy_map[$ _cur_file_s] = 0;
                
                if (_clicked_axis == 0) _dx_map[$ _cur_file_s] += _clicked_dir;
                else _dy_map[$ _cur_file_s] += _clicked_dir;
                
                if (ds_map_exists(char_expr_cache, _c_s.name)) ds_map_delete(char_expr_cache, _c_s.name);
            }
        }
    }

    // Arrow key nudge (1 px)
    if (_pc_s != undefined) {
        var _rk = -1;
        if (keyboard_check(vk_left)) _rk = vk_left;
        else if (keyboard_check(vk_right)) _rk = vk_right;
        else if (keyboard_check(vk_up)) _rk = vk_up;
        else if (keyboard_check(vk_down)) _rk = vk_down;

        if (_rk != -1) {
            var _do_knudge = false;
            if (keyboard_check_pressed(_rk)) { _do_knudge = true; key_repeat_timer = 20; }
            else { key_repeat_timer--; if (key_repeat_timer <= 0) { _do_knudge = true; key_repeat_timer = 2; } }

            if (_do_knudge) {
                var _kdx = 0; var _kdy = 0;
                if (_rk == vk_left) _kdx = -1; if (_rk == vk_right) _kdx = 1;
                if (_rk == vk_up) _kdy = -1;   if (_rk == vk_down)  _kdy = 1;
        var _info = get_active_layer_file();
        var _cur_file_s = _info.file;
        var _layer_key_s = _info.key;
        
        var _dx_struct_key = _layer_key_s + "_dx_offsets";
        var _dy_struct_key = _layer_key_s + "_dy_offsets";
        if (!variable_struct_exists(_pc_s, _dx_struct_key)) _pc_s[$ _dx_struct_key] = {};
        if (!variable_struct_exists(_pc_s, _dy_struct_key)) _pc_s[$ _dy_struct_key] = {};
        var _dx_map = _pc_s[$ _dx_struct_key];
        var _dy_map = _pc_s[$ _dy_struct_key];
        if (!variable_struct_exists(_dx_map, _cur_file_s)) _dx_map[$ _cur_file_s] = 0;
        if (!variable_struct_exists(_dy_map, _cur_file_s)) _dy_map[$ _cur_file_s] = 0;
        
        _dx_map[$ _cur_file_s] += _kdx;
        _dy_map[$ _cur_file_s] += _kdy;
        
        if (ds_map_exists(char_expr_cache, _c_s.name)) ds_map_delete(char_expr_cache, _c_s.name);
    }
        }
    }
    return;
}

if (move_modal_open) {
    var _m_w = 400; var _m_h = 420;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    
    if (mouse_check_button_pressed(mb_left)) {
        // Speed selection
        for (var i = 0; i < array_length(move_speed_labels); i++) {
            var _by = _m_y + 80 + (i * 45);
            if (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _by && _my < _by + 40) {
                move_modal_temp_speed_index = i;
            }
        }
        
        // Moonwalk Toggle
        if (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _m_y + 310 && _my < _m_y + 330) {
            move_modal_temp_moonwalk = !move_modal_temp_moonwalk;
        }
        
        // OK Button - Apply changes
        if (_mx > _m_x + 40 && _mx < _m_x + 180 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            if (move_modal_edit_mode && move_modal_target_index != -1) {
                var _b = script_blocks[move_modal_target_index];
                
                // Update block data
                _b.speed = move_speeds[move_modal_temp_speed_index];
                var _old_moonwalk = (variable_struct_exists(_b, "moonwalk") && _b.moonwalk) || (string_pos("[moonwalk]", string_lower(_b.action_name)) > 0);
                if (_old_moonwalk != move_modal_temp_moonwalk) {
                    if (variable_struct_exists(_b, "facing")) _b.facing *= -1;
                    _b.moonwalk = move_modal_temp_moonwalk;
                }

                // Update visual label in script
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
        
        // Cancel Button - Discard changes
        if (_mx > _m_x + 220 && _mx < _m_x + 360 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            move_modal_edit_mode = false;
            move_modal_open = false;
        }
    }
    return; // Block entire frame logic while modal is open
}

if (pose_modal_open) {
    var _m_w = 800; var _m_h = 420;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    
    // Hovering Logic
    var _hovered_pose = -1;
    for (var i = 1; i <= 4; i++) {
        var _by = _m_y + 80 + ((i-1) * 60);
        if (_mx > _m_x + 50 && _mx < _m_x + 380 && _my > _by && _my < _by + 50) {
            _hovered_pose = i;
            break;
        }
    }
    
    if (_hovered_pose != -1) {
        pose_modal_temp_pose = _hovered_pose; // Always preview hovered
    } else {
        pose_modal_temp_pose = pose_modal_locked_pose; // Revert to locked
    }
    
    if (mouse_check_button_pressed(mb_left)) {
        if (_hovered_pose != -1) {
            pose_modal_locked_pose = _hovered_pose;
            pose_modal_temp_pose = _hovered_pose;
        }
        
        // APPLY Button (Left)
        if (_mx > _m_x + 210 && _mx < _m_x + 360 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            if (pose_modal_locked_pose != -1) selected_pose = pose_modal_locked_pose;
            else selected_pose = pose_modal_temp_pose;
            
            var _char = characters[selected_character_index];
            _char.pose = selected_pose;
            
            // Sync changes to onstage staging actors
            var _applied_to_staging = false;
            if (scene_edit_mode && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                var _scene_block = script_blocks[active_scene_block_idx];
                if (variable_struct_exists(_scene_block, "actors")) {
                    for (var a = 0; a < array_length(_scene_block.actors); a++) {
                        var _act = _scene_block.actors[a];
                        if (_act.char_index == selected_character_index) {
                            _act.pose = selected_pose;
                            _applied_to_staging = true;
                        }
                    }
                }
            }
            
            // Always update live preview actors immediately so the scene reflects the change
            var _is_onstage = false;
            for (var pa = 0; pa < array_length(preview_actors); pa++) {
                var _act = preview_actors[pa];
                if (_act.char_index == selected_character_index) {
                    _act.pose = selected_pose;
                    _is_onstage = true;
                }
            }
            
            // Apply block to screenplay script only when NOT in staging/scene_edit mode
            if ((_is_onstage || pose_modal_edit_mode) && !scene_edit_mode) {
                var _pose_lbl = string(selected_pose);
                
                var _current_expr = 21;
                for (var pa = 0; pa < array_length(preview_actors); pa++) {
                    if (preview_actors[pa].char_index == selected_character_index) {
                        _current_expr = variable_struct_exists(preview_actors[pa], "expression") ? preview_actors[pa].expression : 21;
                        break;
                    }
                }
                var _expr_lbl = mood_names[_current_expr - 1];
                
                if (pose_modal_edit_mode && pose_modal_target_index != -1) {
                    var _old_action = script_blocks[pose_modal_target_index].action_name;
                    var _open_p = string_pos("(", _old_action);
                    var _close_p = string_pos(")", _old_action);
                    if (_open_p > 0 && _close_p > _open_p) {
                        _expr_lbl = string_copy(_old_action, _open_p + 1, _close_p - _open_p - 1);
                    }
                }
                
                var _action_text = "poses " + _pose_lbl + " (" + _expr_lbl + ")";
                
                if (pose_modal_edit_mode && pose_modal_target_index != -1) {
                    script_blocks[pose_modal_target_index].action_name = _action_text;
                    pose_modal_edit_mode = false;
                } else {
                    var _new_a = { 
                        type: "action", 
                        char_index: selected_character_index, 
                        action_name: _action_text, 
                        height: 85 
                    };
                    
                    var _insert_idx = (focused_block != -1) ? focused_block + 1 : array_length(script_blocks);
                    array_insert(script_blocks, _insert_idx, _new_a);
                    update_block_height(_insert_idx);
                    focused_block = _insert_idx;
                }
            }
            
            pose_modal_open = false;
            pose_modal_edit_mode = false;
            return;
        }
        
        // CANCEL Button (Right)
        if (_mx > _m_x + 440 && _mx < _m_x + 590 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            pose_modal_open = false;
            pose_modal_edit_mode = false;
            return;
        }
    }
    return; // Block entire frame logic while modal is open
}

if (expression_modal_open) {
    var _m_w = 950; var _m_h = 460;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;

    var _cols_em = 4;
    var _col_w = 660 / _cols_em;
    var _row_h = 52;
    var _gx = _m_x + 20;
    var _gy = _m_y + 55;

    // Hovering Logic
    var _hovered_expr = -1;
    for (var e = 1; e <= 20; e++) {
        var _col = (e - 1) % _cols_em;
        var _row = floor((e - 1) / _cols_em);
        var _ex = _gx + _col * _col_w;
        var _ey = _gy + _row * _row_h;
        if (_mx > _ex && _mx < _ex + _col_w && _my > _ey && _my < _ey + _row_h) {
            _hovered_expr = e;
            break;
        }
    }
    
    if (_hovered_expr != -1) {
        expression_modal_temp_expr = _hovered_expr; // Always preview hovered
    } else {
        expression_modal_temp_expr = expression_modal_locked_expr; // Revert to locked
    }

    if (mouse_check_button_pressed(mb_left)) {
        if (_hovered_expr != -1) {
            expression_modal_locked_expr = _hovered_expr;
            expression_modal_temp_expr = _hovered_expr;
        }

        // APPLY Button (Left)
        if (_mx > _m_x + 275 && _mx < _m_x + 425 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            selected_expression = expression_modal_locked_expr;
            var _char = characters[selected_character_index];
            _char.expression = selected_expression;
            
            // Sync changes to onstage staging actors
            var _applied_to_staging = false;
            if (scene_edit_mode && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                var _scene_block = script_blocks[active_scene_block_idx];
                if (variable_struct_exists(_scene_block, "actors")) {
                    for (var a = 0; a < array_length(_scene_block.actors); a++) {
                        var _act = _scene_block.actors[a];
                        if (_act.char_index == selected_character_index) {
                            _act.expression = selected_expression;
                            _applied_to_staging = true;
                        }
                    }
                }
            }
            
            // Always update live preview actors immediately so the scene reflects the change
            var _is_onstage = false;
            for (var pa = 0; pa < array_length(preview_actors); pa++) {
                var _act = preview_actors[pa];
                if (_act.char_index == selected_character_index) {
                    _act.expression = selected_expression;
                    _is_onstage = true;
                }
            }
            
            // Apply block to screenplay script only when NOT in staging/scene_edit mode
            if (_is_onstage && !scene_edit_mode) {
                var _current_pose = 1;
                for (var pa = 0; pa < array_length(preview_actors); pa++) {
                    if (preview_actors[pa].char_index == selected_character_index) {
                        _current_pose = variable_struct_exists(preview_actors[pa], "pose") ? preview_actors[pa].pose : 1;
                        break;
                    }
                }
                var _pose_lbl = string(_current_pose);
                var _expr_lbl = mood_names[selected_expression - 1];
                var _action_text = "poses " + _pose_lbl + " (" + _expr_lbl + ")";
                
                var _new_a = { 
                    type: "action", 
                    char_index: selected_character_index, 
                    action_name: _action_text, 
                    height: 85 
                };
                
                var _insert_idx = (focused_block != -1) ? focused_block + 1 : array_length(script_blocks);
                array_insert(script_blocks, _insert_idx, _new_a);
                update_block_height(_insert_idx);
                focused_block = _insert_idx;
            }
            
            expression_modal_open = false;
            return;
        }
        
        // CANCEL Button (Right)
        if (_mx > _m_x + 525 && _mx < _m_x + 675 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            expression_modal_open = false;
            return;
        }
    }
    return; // Block entire frame logic while modal is open
}

if (action_modal_open) {
    var _mw = 900; var _mh = 550; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    
    if (mouse_check_button_pressed(mb_left)) {
        
        // Action selection handling
        for (var i = 0; i < array_length(all_actions); i++) {
            var _is_gen = (all_actions[i].category == "general");
            var _by = _myo + 60 + (i * 45) + (_is_gen ? 25 : 0);
            var _aname = string_lower(all_actions[i].name);
            var _disabled = false;
            
            // Enforce single-action focus during edit mode
            if (action_modal_edit_mode) {
                if (action_modal_selected_idx != i) _disabled = true;
            } else {
                if (selected_character_index == 0 && !_is_gen) _disabled = true;
                else if (!_is_gen) {
                    if (action_modal_char_onstage && string_pos("enter", _aname) > 0) _disabled = true;
                    if (!action_modal_char_onstage && string_pos("exit", _aname) > 0) _disabled = true;
                    if (!action_modal_char_onstage && string_pos("turn", _aname) > 0) _disabled = true;
                }
            }
            
            if (!_disabled && _mx > _mxo+20 && _mx < _mxo+250 && _my > _by && _my < _by+40) {
                action_modal_selected_idx = i; action_modal_locked = true; 
                if (all_actions[i].name == "play sfx") {
                    refresh_sfx_folders();
                    action_modal_sfx_folder_idx = -1; action_modal_sfx_file_idx = -1;
                } else if (all_actions[i].name == "display title") {
                    action_modal_title_text = "";
                    action_modal_wait_duration = 2.0;
                    action_modal_dropdown_open = "";
                    keyboard_string = "";
                }
                return;
            }
        }
        
        // Wait Duration Controls
        if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "wait") {
            var _sw = 400; 
            var _wx = _mxo + 320; // Base X for parameters area
            var _wy = _myo + 250; // Base Y for the slider/arrows row

            var _perc = (action_modal_wait_duration - 0.1) / 9.9;
            var _hx = _wx + 30 + (_perc * _sw);
            
            var _chk_left = (_mx > _wx - 5 && _mx < _wx + 25 && _my > _wy - 10 && _my < _wy + 35);
            var _chk_right = (_mx > _wx + _sw + 35 && _mx < _wx + _sw + 75 && _my > _wy - 10 && _my < _wy + 35);

            // Slider Handle (Start Dragging) - Give arrows priority over the handle
            if (!_chk_left && !_chk_right && _mx > _hx - 15 && _mx < _hx + 15 && _my > _wy - 10 && _my < _wy + 35) {
                action_modal_slider_dragging = true;
            }
        }

        // SFX Browser Controls
        if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "play sfx") {
            var _wx = _mxo + 300; var _wy = _myo + 130;
            var _fx = _mxo + 280; var _fy = _wy + 65; var _fw = 230; var _fh = 215;
            var _lx = _mxo + 550; var _ly = _wy + 65; var _lw = 320; var _lh = 215;

            // Click Folder
            if (_mx > _fx + 10 && _mx < _fx + 230 && _my > _fy && _my < _fy + _fh) {
                for (var f = 0; f < array_length(action_modal_sfx_folders); f++) {
                    var _by = _fy + (f * 30) - action_modal_sfx_scroll_y;
                    if (_my > _by && _my < _by + 30) {
                        action_modal_sfx_folder_idx = f; refresh_sfx_files(action_modal_sfx_folders[f]); action_modal_sfx_file_idx = -1; action_modal_sfx_files_scroll_y = 0;
                    }
                }
            }
            
            // Click File
            if (_mx > _lx - 10 && _mx < _lx + 300 && _my > _ly && _my < _ly + _lh) {
                for (var f = 0; f < array_length(action_modal_sfx_files); f++) {
                    var _by = _ly + (f * 30) - action_modal_sfx_files_scroll_y;
                    if (_my > _by && _my < _by + 30) {
                        action_modal_sfx_file_idx = f;
                    }
                }
            }

            // Test SFX Button
            var _tx = _mxo + _mw - 150; var _ty = _myo + _mh - 120;
            if (_mx > _tx && _mx < _tx + 120 && _my > _ty && _my < _ty + 35) {
                if (action_modal_sfx_folder_idx != -1 && action_modal_sfx_file_idx != -1) {
                    var _folder = action_modal_sfx_folders[action_modal_sfx_folder_idx];
                    var _file = action_modal_sfx_files[action_modal_sfx_file_idx];
                    var _snd_path = sfx_base_path + _folder + "/" + _file;
                    if (file_exists(_snd_path)) {
                        if (test_sfx_sound != -1) { audio_free_buffer_sound(test_sfx_sound); test_sfx_sound = -1; }
                        if (test_sfx_buffer != -1) { buffer_delete(test_sfx_buffer); test_sfx_buffer = -1; }
                        var _tmp_buf = buffer_load(_snd_path);
                        if (_tmp_buf != -1) {
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
        }

        // Display Title Controls
        if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "display title") {
            var _wx = _mxo + 300; var _wy = _myo + 100;
            
            var _clicked_dropdown = false;
            if (action_modal_dropdown_open != "") {
                var _opts = []; var _dx = 0; var _dy = 0;
                if (action_modal_dropdown_open == "align") { _opts = action_modal_title_align_opts; _dx = _wx + 60; _dy = _wy + 230; }
                else if (action_modal_dropdown_open == "size") { _opts = action_modal_title_size_opts; _dx = _wx + 350; _dy = _wy + 230; }
                else if (action_modal_dropdown_open == "font") { _opts = action_modal_title_font_opts; _dx = _wx + 60; _dy = _wy + 280; }
                else if (action_modal_dropdown_open == "color") { _opts = action_modal_title_color_opts; _dx = _wx + 350; _dy = _wy + 280; }
                
                if (array_length(_opts) > 0) {
                    for (var d = 0; d < array_length(_opts); d++) {
                        if (_mx > _dx && _mx < _dx + 200 && _my > _dy + 25 + (d * 30) && _my < _dy + 25 + ((d+1) * 30)) {
                            if (action_modal_dropdown_open == "align") action_modal_title_align = d;
                            else if (action_modal_dropdown_open == "size") action_modal_title_size = d;
                            else if (action_modal_dropdown_open == "font") action_modal_title_font = d;
                            else if (action_modal_dropdown_open == "color") action_modal_title_color = d;
                            action_modal_dropdown_open = "";
                            _clicked_dropdown = true;
                            break;
                        }
                    }
                    if (!_clicked_dropdown) action_modal_dropdown_open = ""; // click outside
                }
            }

            if (!_clicked_dropdown && action_modal_dropdown_open == "") {
                if (_mx > _wx + 60 && _mx < _wx + 260 && _my > _wy + 230 && _my < _wy + 255) { action_modal_dropdown_open = "align"; _clicked_dropdown = true; }
                else if (_mx > _wx + 350 && _mx < _wx + 550 && _my > _wy + 230 && _my < _wy + 255) { action_modal_dropdown_open = "size"; _clicked_dropdown = true; }
                else if (_mx > _wx + 60 && _mx < _wx + 260 && _my > _wy + 280 && _my < _wy + 305) { action_modal_dropdown_open = "font"; _clicked_dropdown = true; }
                else if (_mx > _wx + 350 && _mx < _wx + 550 && _my > _wy + 280 && _my < _wy + 305) { action_modal_dropdown_open = "color"; _clicked_dropdown = true; }
            }
            
            if (_clicked_dropdown) return; // consume click

            var _sw = 300; var _sx = _wx + 100; var _sy = _wy + 170;
            var _perc = (action_modal_wait_duration - 0.1) / 9.9;
            var _hx = _sx + (_perc * _sw);
            var _chk_left = (_mx > _sx - 35 && _mx < _sx - 5 && _my > _sy - 10 && _my < _sy + 35);
            var _chk_right = (_mx > _sx + _sw + 5 && _mx < _sx + _sw + 45 && _my > _sy - 10 && _my < _sy + 35);
            if (!_chk_left && !_chk_right && _mx > _hx - 15 && _mx < _hx + 15 && _my > _sy - 10 && _my < _sy + 35) {
                action_modal_slider_dragging = true;
            }
        }

        // OK Button
        if (action_modal_locked && _mx > _mxo+_mw-280 && _mx < _mxo+_mw-150 && _my > _myo+_mh-50 && _my < _myo+_mh-15) {
            var _act_name = all_actions[action_modal_selected_idx].name;
            var _can_proceed = true;
            var _sfx_path = "";
            
            if (_act_name == "wait") {
                _act_name = "WAIT " + string(action_modal_wait_duration) + " SECONDS";
            } else if (_act_name == "display title") {
                if (action_modal_title_text == "") _can_proceed = false;
                else {
                    var _clean = string_replace_all(action_modal_title_text, "\n", " ");
                    _act_name = "DISPLAY TITLE \"" + _clean + "\"";
                }
            } else if (_act_name == "play sfx") {
                if (action_modal_sfx_folder_idx == -1 || action_modal_sfx_file_idx == -1) _can_proceed = false;
                else {
                    var _folder = action_modal_sfx_folders[action_modal_sfx_folder_idx];
                    var _sfx_file = action_modal_sfx_files[action_modal_sfx_file_idx];
                    _sfx_path = "sounds/sfx/" + _folder + "/" + _sfx_file;
                    _act_name = "Play SFX: " + string_replace(string_upper(_sfx_file), ".WAV", "");
                }
            }
            
            if (_can_proceed) {
                if (action_modal_edit_mode) {
                var _b = script_blocks[action_modal_target_index];
                _b.action_name = _act_name;
                if (all_actions[action_modal_selected_idx].name == "wait") _b.duration = action_modal_wait_duration;
                else if (all_actions[action_modal_selected_idx].name == "display title") {
                    _b.duration = action_modal_wait_duration;
                    _b.title_text = action_modal_title_text;
                    _b.title_align = action_modal_title_align;
                    _b.title_font = action_modal_title_font;
                    _b.title_size = action_modal_title_size;
                    _b.title_color = action_modal_title_color;
                }
                else if (all_actions[action_modal_selected_idx].name == "play sfx") _b.sfx_path = _sfx_path;
                action_modal_edit_mode = false;
            } else {
                var _new_a = { type: "action", char_index: selected_character_index, action_name: _act_name, height: 85 };
                
                if (all_actions[action_modal_selected_idx].name == "wait") {
                    _new_a.duration = action_modal_wait_duration;
                    _new_a.char_index = 0; // Force Narrator/System context for wait
                } else if (all_actions[action_modal_selected_idx].name == "display title") {
                    _new_a.duration = action_modal_wait_duration;
                    _new_a.title_text = action_modal_title_text;
                    _new_a.title_align = action_modal_title_align;
                    _new_a.title_font = action_modal_title_font;
                    _new_a.title_size = action_modal_title_size;
                    _new_a.title_color = action_modal_title_color;
                    _new_a.char_index = 0; // General action
                } else if (all_actions[action_modal_selected_idx].name == "play sfx") {
                    _new_a.sfx_path = _sfx_path;
                    _new_a.char_index = 0; // General action
                }
                
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
        // Cancel
        if (_mx > _mxo+_mw-130 && _mx < _mxo+_mw-20 && _my > _myo+_mh-50 && _my < _myo+_mh-15) { action_modal_edit_mode = false; action_modal_open = false; return; }
    }
    
    if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "play sfx") {
        var _wx = _mxo + 300; var _wy = _myo + 130;
        var _fx = _mxo + 280; var _fy = _wy + 65; var _fw = 230; var _fh = 215;
        var _lx = _mxo + 550; var _ly = _wy + 65; var _lw = 320; var _lh = 215;
        
        // Mouse Wheel Logic (Precise Hitboxes)
        if (_mx > _fx + 10 && _mx < _fx + 240 && _my > _fy && _my < _fy + _fh) {
            if (mouse_wheel_up()) action_modal_sfx_scroll_y -= 60;
            if (mouse_wheel_down()) action_modal_sfx_scroll_y += 60;
        }
        if (_mx > _lx - 10 && _mx < _lx + 310 && _my > _ly && _my < _ly + _lh) {
            if (mouse_wheel_up()) action_modal_sfx_files_scroll_y -= 60;
            if (mouse_wheel_down()) action_modal_sfx_files_scroll_y += 60;
        }
        
        var _max_s = max(0, (array_length(action_modal_sfx_folders) * 30) - _fh);
        action_modal_sfx_scroll_y = clamp(action_modal_sfx_scroll_y, 0, _max_s);
        
        var _max_f = max(0, (array_length(action_modal_sfx_files) * 30) - _lh);
        action_modal_sfx_files_scroll_y = clamp(action_modal_sfx_files_scroll_y, 0, _max_f);
        
        // Interactive Scrollbar Dragging
        if (mouse_check_button_pressed(mb_left)) {
            // Folder scrollbar track: _fx + 232 to _fx + 240
            if (_max_s > 0 && _mx > _fx + 232 && _mx < _fx + 240 && _my > _fy && _my < _fy + _fh) {
                action_modal_sfx_dragging_folder = true;
            }
            // File scrollbar track: _lx + 302 to _lx + 310
            if (_max_f > 0 && _mx > _lx + 302 && _mx < _lx + 310 && _my > _ly && _my < _ly + _lh) {
                action_modal_sfx_dragging_file = true;
            }
        }
        
        if (action_modal_sfx_dragging_folder) {
            if (mouse_check_button(mb_left)) {
                var _perc = clamp((_my - _fy) / _fh, 0, 1);
                action_modal_sfx_scroll_y = _perc * _max_s;
            } else action_modal_sfx_dragging_folder = false;
        }
        
        if (action_modal_sfx_dragging_file) {
            if (mouse_check_button(mb_left)) {
                var _perc = clamp((_my - _ly) / _lh, 0, 1);
                action_modal_sfx_files_scroll_y = _perc * _max_f;
            } else action_modal_sfx_dragging_file = false;
        }
    }
    
    // Continuous Wait Duration Arrow Adjustments
    if (action_modal_selected_idx != -1 && (all_actions[action_modal_selected_idx].name == "wait" || all_actions[action_modal_selected_idx].name == "display title")) {
        var _is_title = (all_actions[action_modal_selected_idx].name == "display title");
        var _sw = _is_title ? 300 : 400; 
        var _wx = _mxo + (_is_title ? 300 : 320);
        var _wy = _myo + (_is_title ? 100 : 250);
        var _sx = _is_title ? _wx + 100 : _wx + 30;
        var _sy = _is_title ? _wy + 170 : _wy;
        
        var _on_left = (_mx > _sx - 35 && _mx < _sx - 5 && _my > _sy - 10 && _my < _sy + 35);
        var _on_right = (_mx > _sx + _sw + 5 && _mx < _sx + _sw + 45 && _my > _sy - 10 && _my < _sy + 35);
        
        // Only trigger arrows if NOT dragging slider
        if (!action_modal_slider_dragging && mouse_check_button(mb_left)) {
            if (_on_left || _on_right) {
                var _do_tick = false;
                if (mouse_check_button_pressed(mb_left)) {
                    _do_tick = true; arrow_repeat_timer = 20;
                } else {
                    arrow_repeat_timer--;
                    if (arrow_repeat_timer <= 0) { _do_tick = true; arrow_repeat_timer = 4; }
                }
                
                if (_do_tick) {
                    if (_on_left) action_modal_wait_duration = max(0.1, action_modal_wait_duration - 0.1);
                    if (_on_right) action_modal_wait_duration = min(10.0, action_modal_wait_duration + 0.1);
                    action_modal_wait_duration = round(action_modal_wait_duration * 10.0) / 10.0;
                }
            }
        } else if (!mouse_check_button(mb_left)) {
            arrow_repeat_timer = 0;
        }
    }
    
    // Continuous Slider Dragging Logic (Outside Pressed check, inside Modal check)
    if (action_modal_slider_dragging) {
        if (mouse_check_button(mb_left)) {
            var _is_title = (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "display title");
            var _sw = _is_title ? 300.0 : 400.0;
            var _track_start = _is_title ? (_mxo + 400.0) : (_mxo + 350.0); 
            var _perc = clamp((_mx - _track_start) / _sw, 0.0, 1.0);
            action_modal_wait_duration = clamp(0.1 + (_perc * 9.9), 0.1, 10.0);
            action_modal_wait_duration = round(action_modal_wait_duration * 10.0) / 10.0;
        } else {
            action_modal_slider_dragging = false;
        }
    }
    
    if (action_modal_open && action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "display title") {
        if (keyboard_string != "") {
            var _new_text = action_modal_title_text + keyboard_string;
            if (string_length(_new_text) <= 100) {
                action_modal_title_text = _new_text;
            }
            keyboard_string = "";
        }
        if (keyboard_check_pressed(vk_backspace) && string_length(action_modal_title_text) > 0) {
            action_modal_title_text = string_copy(action_modal_title_text, 1, string_length(action_modal_title_text) - 1);
            cursor_timer = 0; cursor_visible = true;
        }
        if (keyboard_check_pressed(vk_enter)) {
            var _lines = string_count("\n", action_modal_title_text);
            if (_lines < 2 && string_length(action_modal_title_text) < 100) {
                action_modal_title_text += "\n";
            }
        }
    }

    return; // Block all other UI interactions
}

// --- 0. SCRIPT HEIGHT CALCULATION ---
// (Now handled on-demand via update_block_height and update_all_block_heights)

// --- 1. TTS SEQUENTIAL PLAYBACK & AUTO-SCROLL ---
if (playing_block_index != -1 && playing_block_index < array_length(script_blocks)) {
    var _scroll_idx = playing_block_index;
    var _b = script_blocks[_scroll_idx];
    
    if (!variable_struct_exists(_b, "text") && playing_linked_index != -1) {
        for (var _i = playing_block_index; _i <= playing_linked_index; _i++) {
            if (_i < array_length(script_blocks) && variable_struct_exists(script_blocks[_i], "text")) {
                _scroll_idx = _i;
                _b = script_blocks[_scroll_idx];
                break;
            }
        }
    }
    
    var _target_y = 0;
    for (var i = 0; i < _scroll_idx; i++) _target_y += script_blocks[i].height + 20;
    
    var _is_scene = (variable_struct_exists(_b, "type") && _b.type == "scene");
    var _header_offset = _is_scene ? 0 : 30; // Center on the name label/scene header
    var _char_progress_y = 0;
    
    if (is_speaking && variable_struct_exists(_b, "text") && string_length(_b.text) > 0) {
        // 1. Check for Accurate Progress Pulse from TTS Bridge (throttled: runs every 6 frames to avoid per-frame disk I/O)
        if (check_timer mod 6 == 0) {
            var _req_to_check = variable_struct_exists(_b, "tts_req") ? _b.tts_req : -1;
            if (_req_to_check != -1) {
                var _prog_file = working_directory + "talkit\\talkit_prog_" + string(_req_to_check) + ".tmp";
                if (file_exists(_prog_file)) {
                    var _f = file_text_open_read(_prog_file);
                    if (_f != -1) {
                        var _perc = file_text_read_real(_f);
                        file_text_close(_f);
                        // Re-sync visual index: allow estimation to move past pulse, but use pulse as a floor
                        if (_perc > 0) speaking_index = max(speaking_index, _perc * string_length(_b.text));
                    }
                }
                // Read viseme timeline once per request (PS1 writes this before TalkIt speaks)
                if (_req_to_check != current_viseme_req) {
                    var _vis_file = working_directory + "talkit\\talkit_vis_" + string(_req_to_check) + ".tmp";
                    if (file_exists(_vis_file)) {
                        current_viseme_req  = _req_to_check;
                        current_viseme_data = [];
                        var _vf = file_text_open_read(_vis_file);
                        if (_vf != -1) {
                            var _vs = ""; while (!file_text_eof(_vf)) { _vs += file_text_readln(_vf); } file_text_close(_vf);
                            var _pairs = string_split(_vs, ",");
                            for (var _vi = 0; _vi < array_length(_pairs); _vi++) {
                                var _vp = string_split(_pairs[_vi], ":");
                                if (array_length(_vp) >= 2) array_push(current_viseme_data, { t: real(_vp[0]), v: real(_vp[1]) });
                            }
                        }
                        file_delete(_vis_file);
                    }
                }
            }
        }

        // 2. Advance estimation (Aggressive 20 CPS base to prevent lagging)
        var _base_cps = 20; 
        var _ui_speed = variable_struct_exists(_b, "speed") ? _b.speed : 50;
        var _spd_factor = (50 + (_ui_speed * 2.5)) / 175;
        speaking_index += (_base_cps / 60) * _spd_factor * speaking_phonetic_ratio;
        speaking_index = min(speaking_index, string_length(_b.text));

        var _cur_char = floor(speaking_index);
        var _sub = string_copy(_b.text, 1, _cur_char);
        _char_progress_y = string_height_ext(_sub, 28, box_w - 120);
    }
    
    var _dest_scroll = -(_target_y + _header_offset + _char_progress_y) + (box_h / 2); 
    block_scroll_y += (_dest_scroll - block_scroll_y) * 0.15; // Faster interpolation
    block_scroll_y = min(0, block_scroll_y);
    // --- Theater Subtitle Auto-Scroll ---
    if (theater_mode && is_speaking && !theater_paused) {
        // Subtitles use 32px line height and 880px wrap width (from Draw_0.gml)
        if (variable_struct_exists(_b, "text")) {
            var _p = get_text_pos(_b.text, floor(speaking_index), 880, 32);
            var _target_sub_scroll = 0;
            // If the current line is the 4th or lower (y >= 96), scroll up
            if (_p.y >= 96) {
                _target_sub_scroll = -(_p.y - 64); // Keeps the current line as the 3rd visible line
            }
            theater_subtitle_scroll_y += (_target_sub_scroll - theater_subtitle_scroll_y) * 0.1;
        }
    }
} else {
    theater_subtitle_scroll_y = 0;
}

// --- 1.1 ACTION ANIMATOR ---
if (action_animating) {
    for (var _ai = array_length(active_animations) - 1; _ai >= 0; _ai--) {
        var _anim = active_animations[_ai];
        var _act_idx = -1;
        for (var a = 0; a < array_length(preview_actors); a++) {
            if (preview_actors[a].char_index == _anim.char_index) { _act_idx = a; break; }
        }
        
        if (_act_idx != -1) {
            var _act = preview_actors[_act_idx];
            var _dist = point_distance(_act.x, _act.y, _anim.target_x, _anim.target_y);
            
            if (!variable_struct_exists(_act, "bounce_timer")) _act.bounce_timer = 0;
            if (!variable_struct_exists(_act, "y_offset")) _act.y_offset = 0;
            if (!variable_struct_exists(_anim, "cur_speed")) _anim.cur_speed = 0;
            
            var _target_speed = _anim.speed;
            var _decel_dist = _anim.speed * 12; // Start slowing down when close
            if (_dist < _decel_dist) {
                _target_speed = max(0.2, _anim.speed * (_dist / _decel_dist));
            }
            
            _anim.cur_speed += (_target_speed - _anim.cur_speed) * 0.2; // Inertia ease
            
            if (_dist > _anim.cur_speed) {
                var _dir = point_direction(_act.x, _act.y, _anim.target_x, _anim.target_y);
                var _dx = lengthdir_x(_anim.cur_speed, _dir);
                var _dy = lengthdir_y(_anim.cur_speed, _dir);
                _act.x += _dx;
                _act.y += _dy;
                
                var _h_speed = abs(_dx);
                if (_h_speed > 0.2) {
                    _act.bounce_timer += _h_speed * 0.07; 
                    var _bob_amp = clamp(_h_speed * 0.8, 0, 4);
                    _act.y_offset = -round(abs(sin(_act.bounce_timer)) * _bob_amp);
                } else {
                    _act.y_offset = 0;
                    _act.bounce_timer = 0;
                }
            } else {
                _act.x = _anim.target_x;
                _act.y = _anim.target_y;
                _act.y_offset = 0;
                _act.bounce_timer = 0;
                speaking_pause_timer = max(speaking_pause_timer, 5);
                if (_anim.type == "exit") array_delete(preview_actors, _act_idx, 1);
                array_delete(active_animations, _ai, 1);
            }
        } else { array_delete(active_animations, _ai, 1); }
    }
    if (array_length(active_animations) == 0) action_animating = false;
}

if (is_speaking) {
    if (check_timer mod 6 == 0) { // Throttled: only poll done-files ~10 times/sec instead of 60
    var _all_done = true;
    for (var _r = array_length(active_requests) - 1; _r >= 0; _r--) {
        var _req = active_requests[_r];
        var _done_file = working_directory + "talkit\\talkit_done_" + string(_req) + ".tmp";
        if (file_exists(_done_file)) {
            file_delete(_done_file);
            array_delete(active_requests, _r, 1);
            
            var _txt_file = game_save_id + "talkit_text_" + string(_req) + ".txt";
            if (file_exists(_txt_file)) file_delete(_txt_file);
            
            var _prog_file = working_directory + "talkit\\talkit_prog_" + string(_req) + ".tmp";
            if (file_exists(_prog_file)) file_delete(_prog_file);
        } else {
            _all_done = false;
        }
    }

    if (_all_done) {
        if (playing_block_index != -1 && playing_block_index < array_length(script_blocks) - 1) {
            is_speaking = false; speaking_pause_timer = max(speaking_pause_timer, 15); 
        } else {
            is_speaking = false; last_played_block_index = playing_block_index; 
            tts_stop();
            
            if (theater_mode) {
                theater_subtitles = ""; theater_active_char = -1;
                theater_paused = true;
                play_from_index(0); // Rewind
                playing_block_index = -1; // Stay stopped
            } else {
                playing_block_index = -1;
            }
        }
    }
    } // end check_timer throttle
}

// --- CLEANUP WARMUP REQUESTS ---
if (variable_instance_exists(id, "warmup_requests") && check_timer mod 6 == 0) {
    for (var _r = array_length(warmup_requests) - 1; _r >= 0; _r--) {
        var _req = warmup_requests[_r];
        var _done_file = working_directory + "talkit\\talkit_done_" + string(_req) + ".tmp";
        if (file_exists(_done_file)) {
            file_delete(_done_file);
            array_delete(warmup_requests, _r, 1);
            
            var _txt_file = game_save_id + "talkit_text_" + string(_req) + ".txt";
            if (file_exists(_txt_file)) file_delete(_txt_file);
            
            var _prog_file = working_directory + "talkit\\talkit_prog_" + string(_req) + ".tmp";
            if (file_exists(_prog_file)) file_delete(_prog_file);
        }
    }
}

// Global Parallel Timer Decrement
if (playing_block_index != -1 && !theater_paused && speaking_pause_timer > 0) {
    speaking_pause_timer--;
}

// Auto-stop if current block is scene/action and it's the last block
if (!is_speaking && !action_animating && playing_block_index != -1 && playing_block_index < array_length(script_blocks)) {
    if (speaking_pause_timer <= 0 && speaking_pause_timer != -1) {
    var _lb_idx = (playing_linked_index != -1) ? playing_linked_index : playing_block_index;
    var _lb = script_blocks[_lb_idx];
    var _lb_is_scene = (variable_struct_exists(_lb, "type") && _lb.type == "scene");
    var _lb_is_action = (variable_struct_exists(_lb, "type") && _lb.type == "action");
    if ((_lb_is_scene || _lb_is_action) && _lb_idx >= array_length(script_blocks) - 1) {
        if (theater_mode) {
            theater_subtitles = ""; theater_active_char = -1;
            theater_paused = true;
            play_from_index(0); // Rewind
            playing_block_index = -1;
        } else {
            playing_block_index = -1;
        }
    }
    }
}

// Sequence Advance
if (!is_speaking && !action_animating && playing_block_index != -1 && !theater_paused) {
    if (speaking_pause_timer <= 0 || speaking_pause_timer == -1) {
        // If speaking_pause_timer <= 0, we need to advance. 
        // If speaking_pause_timer == -1, we stay on current index (first play).
        if (speaking_pause_timer <= 0 && speaking_pause_timer != -1) {
            var _next_idx = (playing_linked_index != -1) ? playing_linked_index + 1 : playing_block_index + 1;
            if (_next_idx < array_length(script_blocks)) {
                playing_block_index = _next_idx;
                playing_linked_index = -1;
                speaking_pause_timer = 0; // Reset safely
            } else {
                if (theater_mode) {
                    theater_subtitles = ""; theater_active_char = -1;
                    theater_paused = true;
                    play_from_index(0); // Rewind
                    playing_block_index = -1;
                    playing_linked_index = -1;
                } else {
                    playing_block_index = -1;
                    playing_linked_index = -1;
                    theater_paused = false; 
                }
                return;
            }
        }
        if (speaking_pause_timer == -1) speaking_pause_timer = 0;

        var _blocks_to_start = [script_blocks[playing_block_index]];
        var _curr_link_idx = playing_block_index;
        while (_curr_link_idx < array_length(script_blocks) - 1 && variable_struct_exists(script_blocks[_curr_link_idx], "linked") && script_blocks[_curr_link_idx].linked) {
            _curr_link_idx++;
            array_push(_blocks_to_start, script_blocks[_curr_link_idx]);
        }
        playing_linked_index = (_curr_link_idx > playing_block_index) ? _curr_link_idx : -1;
            
        theater_active_char = -1; 
        if (theater_mode) theater_subtitles = ""; 
        
        active_requests = [];

        for (var _idx_b = 0; _idx_b < array_length(_blocks_to_start); _idx_b++) {
            var _b = _blocks_to_start[_idx_b];
            var _is_scene = (variable_struct_exists(_b, "type") && _b.type == "scene");
            var _is_action = (variable_struct_exists(_b, "type") && _b.type == "action");
            
            if (_is_scene) {
                current_scene_sprite = get_scene_sprite(_b.internal_name);
                set_scene_dimensions(current_scene_sprite);
                speaking_pause_timer = max(speaking_pause_timer, 60); // Give scene 1 second to breathe
                
                active_scene_block_idx = playing_block_index;
                preview_actors = [];
                if (variable_struct_exists(_b, "actors")) {
                    for(var a=0; a<array_length(_b.actors); a++) {
                        var _act = _b.actors[a];
                        var _def_face = (_act.char_index >= 0 && _act.char_index < array_length(characters) && variable_struct_exists(characters[_act.char_index], "default_facing")) ? characters[_act.char_index].default_facing : 1;
                        var _face = variable_struct_exists(_act, "facing") ? _act.facing : _def_face;
                        var _pose = variable_struct_exists(_act, "pose") ? _act.pose : 1;
                        var _expr = variable_struct_exists(_act, "expression") ? _act.expression : 21;
                        array_push(preview_actors, { char_index: _act.char_index, x: _act.x, y: _act.y, is_base: true, facing: _face, pose: _pose, expression: _expr });
                        char_facings[_act.char_index] = _face;
                    }
                }
            } else if (_is_action) {
                var _aname = string_lower(_b.action_name);
                var _is_enter = (string_pos("enter", _aname) > 0);
                var _is_exit = (string_pos("exit", _aname) > 0);
                var _is_left = (string_pos("left", _aname) > 0);
                var _spd = variable_struct_exists(_b, "speed") ? _b.speed : 1.9;
                var _moon = (variable_struct_exists(_b, "moonwalk") && _b.moonwalk) || (string_pos("[moonwalk]", _aname) > 0);
                
                var _act_idx = -1;
                for (var a = 0; a < array_length(preview_actors); a++) {
                    if (preview_actors[a].char_index == _b.char_index) { _act_idx = a; break; }
                }
                
                var _spr = get_character_sprite(_b.char_index);
                var _w = (_spr != -1) ? sprite_get_width(_spr) * ((scene_win_h * 1.5) / 450) : 100;
                
                if (_is_enter) {
                    if (_act_idx != -1) { speaking_pause_timer = max(speaking_pause_timer, 5); } // Conflict
                    else {
                        var _start_x = _is_left ? -(_w/2) : scene_win_w + (_w/2);
                        var _base_face = _is_left ? -1 : 1;
                        char_facings[_b.char_index] = _moon ? -_base_face : _base_face;

                        var _target_y = variable_struct_exists(_b, "target_y") ? _b.target_y : (scene_win_h * 0.8);
                        var _c = characters[_b.char_index];
                        var _pose = variable_struct_exists(_c, "pose") ? _c.pose : 1;
                        var _expr = variable_struct_exists(_c, "expression") ? _c.expression : 21;
                        array_push(preview_actors, { char_index: _b.char_index, x: _start_x, y: _target_y, is_base: false, facing: char_facings[_b.char_index], pose: _pose, expression: _expr });
                        action_animating = true;
                        array_push(active_animations, {
                            char_index: _b.char_index,
                            type: "enter",
                            speed: _spd,
                            target_x: variable_struct_exists(_b, "target_x") ? _b.target_x : (_is_left ? (_w/2) + 20 : scene_win_w - (_w/2) - 20),
                            target_y: variable_struct_exists(_b, "target_y") ? _b.target_y : scene_win_h
                        });
                    }
                } else if (_is_exit) {
                    if (_act_idx == -1) { speaking_pause_timer = max(speaking_pause_timer, 5); } // Conflict
                    else {
                        action_animating = true;
                        
                        // Intelligently choose exit side if not specified
                        var _current_x = preview_actors[_act_idx].x;
                        var _exit_left = (string_pos("left", _aname) > 0);
                        var _exit_right = (string_pos("right", _aname) > 0);
                        if (!_exit_left && !_exit_right) {
                            // Default to nearest side
                            _exit_left = (_current_x < scene_win_w / 2);
                        }
                        
                        var _base_face = _exit_left ? 1 : -1;
                        char_facings[_b.char_index] = _moon ? -_base_face : _base_face;
                        preview_actors[_act_idx].facing = char_facings[_b.char_index];
                        
                        array_push(active_animations, {
                            char_index: _b.char_index,
                            type: "exit",
                            speed: _spd,
                            target_x: _exit_left ? -(_w/2) - 50 : scene_win_w + (_w/2) + 50,
                            target_y: preview_actors[_act_idx].y
                        });
                    }
                } else if (string_pos("turn", _aname) > 0) {
                    if (_act_idx != -1) {
                        preview_actors[_act_idx].facing *= -1;
                        char_facings[_b.char_index] = preview_actors[_act_idx].facing;
                    }
                    speaking_pause_timer = max(speaking_pause_timer, 5);
                } else if (string_pos("wait", _aname) > 0) {
                    var _dur = variable_struct_exists(_b, "duration") ? _b.duration : 1.0;
                    speaking_pause_timer = max(speaking_pause_timer, max(1, _dur * 60));
                } else if (string_pos("display title", _aname) > 0) {
                    var _is_linked_to_duration_source = false;
                    for (var _check = 0; _check < array_length(_blocks_to_start); _check++) {
                        var _ctype = get_link_type(_blocks_to_start[_check]);
                        if (_ctype == "sfx" || _ctype == "voice") {
                            _is_linked_to_duration_source = true; break;
                        }
                    }
                    if (!_is_linked_to_duration_source) {
                        var _dur = variable_struct_exists(_b, "duration") ? _b.duration : 2.0;
                        speaking_pause_timer = max(speaking_pause_timer, max(1, _dur * 60));
                    }
                } else if (string_pos("play sfx", _aname) > 0) {
                    if (variable_struct_exists(_b, "sfx_path")) {
                        var _path = working_directory + _b.sfx_path;
                        if (file_exists(_path)) {
                            if (variable_struct_exists(_b, "last_sound") && _b.last_sound != -1) { audio_free_buffer_sound(_b.last_sound); _b.last_sound = -1; }
                            if (variable_struct_exists(_b, "last_buffer") && _b.last_buffer != -1) { buffer_delete(_b.last_buffer); _b.last_buffer = -1; }
                            var _tmp_buf = buffer_load(_path);
                            if (_tmp_buf != -1) {
                                var _sz = buffer_get_size(_tmp_buf);
                                _b.last_buffer = buffer_create(_sz, buffer_fixed, 1);
                                buffer_copy(_tmp_buf, 0, _sz, _b.last_buffer, 0);
                                buffer_delete(_tmp_buf);
                                
                                buffer_seek(_b.last_buffer, buffer_seek_start, 22); var _chan = buffer_read(_b.last_buffer, buffer_u16);
                                buffer_seek(_b.last_buffer, buffer_seek_start, 24); var _rate = buffer_read(_b.last_buffer, buffer_u32);
                                buffer_seek(_b.last_buffer, buffer_seek_start, 34); var _bits = buffer_read(_b.last_buffer, buffer_u16);
                                var _fmt = (_bits == 16) ? buffer_s16 : buffer_u8;
                                var _cfmt = (_chan == 2) ? audio_stereo : audio_mono;
                                
                                _b.last_sound = audio_create_buffer_sound(_b.last_buffer, _fmt, _rate, 44, _sz - 44, _cfmt);
                                if (_b.last_sound != -1) {
                                    audio_play_sound(_b.last_sound, 1, false);
                                    speaking_pause_timer = max(speaking_pause_timer, ceil(audio_sound_length(_b.last_sound) * 60));
                                } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                            } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                        } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                    } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                } else if (string_pos("moves", _aname) > 0) {
                    if (_act_idx != -1) {
                        action_animating = true;
                        var _base_face = (_b.target_x > preview_actors[_act_idx].x) ? -1 : 1;
                        char_facings[_b.char_index] = _moon ? -_base_face : _base_face;
                        preview_actors[_act_idx].facing = char_facings[_b.char_index];
                        array_push(active_animations, {
                            char_index: _b.char_index,
                            type: "move",
                            speed: _spd,
                            target_x: _b.target_x,
                            target_y: _b.target_y
                        });
                    } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                } else if (string_pos("poses", _aname) > 0) {
                    if (_act_idx != -1) {
                        var _p_pos = string_pos("poses ", _aname);
                        if (_p_pos > 0) {
                            var _p_str = string_copy(_aname, _p_pos + 6, 1);
                            var _p_num = real(_p_str);
                            if (_p_num >= 1 && _p_num <= 4) {
                                preview_actors[_act_idx].pose = _p_num;
                            }
                        }
                        
                        var _m_start = string_pos("(", _aname);
                        var _m_end = string_pos(")", _aname);
                        if (_m_start > 0 && _m_end > _m_start) {
                            var _mood_str = string_copy(_aname, _m_start + 1, _m_end - _m_start - 1);
                            _mood_str = string_upper(_mood_str);
                            for (var m = 0; m < array_length(mood_names); m++) {
                                if (mood_names[m] == _mood_str) {
                                    preview_actors[_act_idx].expression = m + 1;
                                    break;
                                }
                            }
                        }
                        
                        speaking_pause_timer = max(speaking_pause_timer, 6);
                    } else {
                        speaking_pause_timer = max(speaking_pause_timer, 5);
                    }
                } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
            } else {
                var _is_empty = true;
                for (var _e_idx = 1; _e_idx <= string_length(_b.text); _e_idx++) {
                    if (string_char_at(_b.text, _e_idx) != " " && string_char_at(_b.text, _e_idx) != "\n" && string_char_at(_b.text, _e_idx) != "\r") {
                        _is_empty = false; break;
                    }
                }
                
                var _c = characters[_b.char_index];
                var _phonetic_text = apply_dictionary(_b.text);
                
                if (_is_empty) {
                    _b.tts_req = -1;
                } else {
                    var _req = tts_speak(_phonetic_text, _b.voice_id, _b.pitch, _b.speed, _b.mode, _b.style);
                    _b.tts_req = _req;
                    array_push(active_requests, _req);
                    if (!is_speaking) {
                        is_speaking         = true;
                        current_viseme_data = []; // will be filled lazily from vis file
                        speaking_index      = 0; // Reset progress for the primary line
                        var _v_len = max(1, string_length(_b.text));
                        var _p_len = max(1, string_length(_phonetic_text));
                        speaking_phonetic_ratio = _v_len / _p_len;
                    }
                }
            }
            
            if (!(_is_scene || _is_action) && _b.tts_req != -1) { 
                if (theater_active_char == -1) {
                    theater_active_char = _b.char_index; 
                    if (theater_mode) theater_subtitles = _b.text; 
                } else {
                    if (theater_mode) theater_subtitles += "\n" + string_upper(characters[_b.char_index].name) + ": " + _b.text; 
                }
            }
        }
    }
}

// --- 1b. SCENE CONTEXT TRACKING

// --- 1. MODAL BLOCKING & CONTEXT MENUS ---
if (scene_edit_menu_open) {
    if (mouse_check_button_pressed(mb_left)) {
        var _mw = 100; var _mh = 35;
        var _bx = scene_edit_menu_x; var _by = scene_edit_menu_y;
        if (active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
            _scene = script_blocks[active_scene_block_idx];
            
            // FLIP Button
            if (_mx > _bx && _mx < _bx + _mw && _my > _by && _my < _by + _mh) {
                if (scene_edit_menu_actor_idx != -1 && scene_edit_menu_actor_idx < array_length(_scene.actors)) {
                    var _act = _scene.actors[scene_edit_menu_actor_idx];
                    _act.facing = (variable_struct_exists(_act, "facing") ? _act.facing : 1) * -1;
                }
                return;
            }
        }
        
        // Close menu on click anywhere else (and allow the click to pass through)
        scene_edit_menu_open = false;
    }
}


if (edit_mode) {
    var _m_w = 800; var _m_h = 700;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    if (mouse_check_button_pressed(mb_left)) {
        // Voice Selection (Compact Coordinates)
        var _cols = 4; var _bw = 170; var _bh = 45; var _gx = (_m_w - (_cols * (_bw + 15))) / 2;
        for (var i = 0; i < array_length(all_voices); i++) {
            var _bx = _m_x + _gx + ((i % _cols) * (_bw + 15));
            var _by = _m_y + 70 + (floor(i / _cols) * (_bh + 8));
            if (_mx > _bx && _mx < _bx + _bw && _my > _by && _my < _by + _bh) {
                modal_voice_id = all_voices[i].voice_id;
                tts_stop(); tts_speak("Testing voice", modal_voice_id, modal_pitch, modal_speed, modal_effort, modal_quality);
            }
        }
        
        // Tweak Controls (Shifted Up)
        var _ctrl_y = _m_y + 360;
        if (tweak_enabled) {
            // Pitch Fine-Tuning Arrows
            if (_my > _ctrl_y - 5 && _my < _ctrl_y + 25) {
                if (_mx > _m_x + 150 && _mx < _m_x + 175) modal_pitch = max(0, modal_pitch - 5);
                if (_mx > _m_x + 485 && _mx < _m_x + 510) modal_pitch = min(180, modal_pitch + 5);
                if (_mx > _m_x + 180 && _mx < _m_x + 480) modal_pitch = ((_mx - (_m_x + 180)) / 300) * 180;
            }
            
            // Speed Fine-Tuning Arrows
            if (_my > _ctrl_y + 45 && _my < _ctrl_y + 75) {
                if (_mx > _m_x + 150 && _mx < _m_x + 175) modal_speed = max(0, modal_speed - 5);
                if (_mx > _m_x + 485 && _mx < _m_x + 510) modal_speed = min(100, modal_speed + 5);
                if (_mx > _m_x + 180 && _mx < _m_x + 480) modal_speed = ((_mx - (_m_x + 180)) / 300) * 100;
            }
            
            // Radio Buttons: Quality (Controls F0Style)
            if (_my > _ctrl_y + 90 && _my < _ctrl_y + 125) {
                for (var e = 0; e < 3; e++) {
                    var _ex = _m_x + 180 + (e * 105);
                    if (point_distance(_mx, _my, _ex, _ctrl_y + 108) < 25) {
                        if (e == 0) modal_quality = 0;
                        if (e == 1) modal_quality = 2;
                        if (e == 2) modal_quality = 4;
                    }
                }
            }
            
            // Radio Buttons: Effort (Controls VoicingMode)
            if (_my > _ctrl_y + 130 && _my < _ctrl_y + 165) {
                for (var s = 0; s < 3; s++) {
                    var _sx = _m_x + 180 + (s * 105);
                    if (point_distance(_mx, _my, _sx, _ctrl_y + 148) < 25) modal_effort = s;
                }
            }
        }
        
        // Advanced Tweak Toggle (Moved Lower)
        var _toggle_y = _m_y + 580;
        if (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _toggle_y && _my < _toggle_y + 25) tweak_enabled = !tweak_enabled;

        // Bottom Buttons Layout
        var _btn_y = _m_y + _m_h - 60;

        // Revert (Local Edit only) - Discard block tweaks and return to Character Globals
        if (modal_is_local_edit && _mx > _m_x + 30 && _mx < _m_x + 150 && _my > _btn_y && _my < _btn_y + 40) {
            var _b = script_blocks[modal_target_block_idx];
            var _c = characters[_b.char_index];
            modal_voice_id = _c.voice_id; modal_pitch = _c.pitch; modal_speed = _c.speed;
            modal_effort = _c.mode; modal_quality = _c.style; tweak_enabled = _c.tweaked;
            tts_stop();
            return;
        }

        // Test Button (X position shifts if Revert is present)
        var _tx = modal_is_local_edit ? _m_x + 165 : _m_x + 30;
        if (_mx > _tx && _mx < _tx + 120 && _my > _btn_y && _my < _btn_y + 40) { tts_stop(); tts_speak("Testing settings", modal_voice_id, modal_pitch, modal_speed, modal_effort, modal_quality); }
        
        if (_mx > _m_x + _m_w - 280 && _mx < _m_x + _m_w - 150 && _my > _btn_y && _my < _btn_y + 40) {
            var _c = characters[selected_character_index];
            if (modal_is_local_edit) {
                var _b = script_blocks[modal_target_block_idx];
                _b.voice_id = modal_voice_id; _b.pitch = modal_pitch; _b.speed = modal_speed;
                _b.mode = modal_effort; _b.style = modal_quality; _b.tweaked = tweak_enabled;
                // Only mark as altered if it actually differs from character's current global
                _b.is_altered = (_b.voice_id != _c.voice_id || _b.pitch != _c.pitch || _b.speed != _c.speed || _b.mode != _c.mode || _b.style != _c.style || _b.tweaked != _c.tweaked);
            } else {
                _c.voice_id = modal_voice_id; _c.pitch = modal_pitch; _c.speed = modal_speed;
                _c.mode = modal_effort; _c.style = modal_quality; _c.tweaked = tweak_enabled;
                
                // Propagate the new "Global" settings to all blocks that are currently using the character default
                for (var i = 0; i < array_length(script_blocks); i++) {
                    var _block = script_blocks[i];
                    var _is_v = !variable_struct_exists(_block, "type") || _block.type == "voice";
                    if (_is_v && _block.char_index == selected_character_index) {
                        if (!variable_struct_exists(_block, "is_altered") || !_block.is_altered) {
                            _block.voice_id = _c.voice_id; _block.pitch = _c.pitch; _block.speed = _c.speed;
                            _block.mode = _c.mode; _block.style = _c.style; _block.tweaked = _c.tweaked;
                            _block.is_altered = false;
                        }
                    }
                }
            }
            edit_mode = false; tts_stop();
        }
        if (_mx > _m_x + _m_w - 140 && _mx < _m_x + _m_w - 30 && _my > _btn_y && _my < _btn_y + 40) { edit_mode = false; tts_stop(); }
    }
    return;
}

//// --- 2b. SCENE SELECTION MODAL ---
if (scene_modal_open) {
    var _m_w = 700; var _m_h = 450;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    var _max_visible_h = 320;
    var _list_w = 300;
    
    if (mouse_check_button_pressed(mb_left)) {
        // Option selection
        if (_mx > _m_x + 20 && _mx < _m_x + 20 + _list_w && _my > _m_y + 60 && _my < _m_y + 60 + _max_visible_h) {
            for (var i = 0; i < array_length(all_scenes); i++) {
                var _by = _m_y + 60 + (i * 40) + scene_modal_scroll_y;
                if (_my > _by && _my < _by + 35) {
                    var _data = all_scenes[i];
                    var _target_idx = scene_modal_target_index;
                    
                    if (scene_modal_edit_mode) {
                        var _b = script_blocks[_target_idx];
                        _b.name = _data.name;
                        _b.internal_name = _data.internal_name;
                        scene_modal_edit_mode = false;
                    } else {
                        var _new_scene = { type: "scene", name: _data.name, internal_name: _data.internal_name, actors: [], height: 80 };
                        if (_target_idx == -1) {
                            array_push(script_blocks, _new_scene);
                            _target_idx = array_length(script_blocks) - 1;
                        } else {
                            array_insert(script_blocks, _target_idx, _new_scene);
                        }
                    }

                    update_all_block_heights();
                    scene_modal_open = false; 
                            
                            // Auto-enable Staging Mode for the new/edited scene
                            focused_block = _target_idx;
                            scene_edit_mode = true;
                            insertion_idx = -1;
                            active_scene_block_idx = _target_idx;
                            current_scene_sprite = get_scene_sprite(_data.internal_name);
                            set_scene_dimensions(current_scene_sprite);
                            
                            var _th = 0; for (var k = 0; k <= _target_idx; k++) _th += script_blocks[k].height + 20;
                            block_scroll_y = min(0, (box_h - 100) - _th);
                            return;
                }
            }
        }
        
        // Cancel Button
        var _c_y = _m_y + _m_h - 50;
        if (_mx > _m_x + 20 && _mx < _m_x + _m_w - 20 && _my > _c_y && _my < _c_y + 35) {
            scene_modal_edit_mode = false;
            scene_modal_open = false; return;
        }
    }
    
    // Modal scrolling
    if (mouse_wheel_up()) scene_modal_scroll_y = min(0, scene_modal_scroll_y + 40);
    if (mouse_wheel_down()) {
        var _list_h = array_length(all_scenes) * 40;
        if (_list_h > _max_visible_h) scene_modal_scroll_y = max(-(_list_h - _max_visible_h), scene_modal_scroll_y - 40);
    }
    return;
}

// --- 2c2. FILE MENU ---
if (file_menu_open) {
    if (mouse_check_button_pressed(mb_left)) {
        var _fm_x = 10; var _fm_y = 45; var _fm_w = 150; var _fm_h = 70;
        var _clicked_option = false;
        
        if (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y && _my < _fm_y + 35) {
            var _file = get_save_filename("Hollywood High Script|*.hhi", "screenplay.hhi");
            if (_file != "") {
                var _save_data = { version: 1, script: script_blocks, chars: characters, dict: dictionary_list };
                var _json = json_stringify(_save_data);
                
                // Create a buffer from the JSON string
                var _buffer = buffer_create(string_byte_length(_json) + 1, buffer_fixed, 1);
                buffer_write(_buffer, buffer_string, _json);
                buffer_seek(_buffer, buffer_seek_start, 0); // Rewind buffer before compression
                
                // Compress the buffer
                var _compressed_buffer = buffer_compress(_buffer, 0, buffer_get_size(_buffer));
                
                // Save the compressed buffer to a binary file
                buffer_save(_compressed_buffer, _file);
                
                // Clean up memory
                buffer_delete(_buffer);
                buffer_delete(_compressed_buffer);
            }
            _clicked_option = true;
        } else if (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y + 35 && _my < _fm_y + 70) {
            var _file = get_open_filename("Hollywood High Script|*.hhi", "");
            if (_file != "" && file_exists(_file)) {
                try {
                    // Load the binary file into a buffer, decompress it, and read the JSON string
                    var _buffer = buffer_load(_file);
                    var _decompressed_buffer = buffer_decompress(_buffer);
                    var _json = buffer_read(_decompressed_buffer, buffer_string);
                    buffer_delete(_buffer);
                    buffer_delete(_decompressed_buffer);

                    var _loaded = json_parse(_json);
                    if (is_array(_loaded)) script_blocks = _loaded;
                    else if (is_struct(_loaded)) {
                        if (variable_struct_exists(_loaded, "script")) script_blocks = _loaded.script;
                        if (variable_struct_exists(_loaded, "chars")) characters = _loaded.chars;
                        if (variable_struct_exists(_loaded, "dict")) dictionary_list = _loaded.dict;
                    }
                    update_all_block_heights();
                    focused_block = -1; playing_block_index = -1; playing_linked_index = -1;
                    scene_edit_mode = false; insertion_idx = -1;
                    selection_start = 0; selection_end = 0; is_selecting = false;
                    is_speaking = false; audio_stop_all(); tts_stop(); block_scroll_y = 0;
                    if (array_length(script_blocks) > 0) { play_from_index(0); playing_block_index = -1; } else { preview_actors = []; current_scene_sprite = -1; set_scene_dimensions(-1); }
                } catch(e) { show_message("Error loading script file! Invalid format."); }
            }
            _clicked_option = true;
        }
        file_menu_open = false;
        if (_clicked_option) return;
    }
}

// --- 2d. CHARACTER SELECTOR CLICKS & DRAGS ---
if (mouse_check_button_pressed(mb_left)) {
    // Block interaction if any modal is open
    _overlay_active = (file_menu_open || edit_mode || scene_modal_open || action_modal_open || theater_mode || move_modal_open || pose_modal_open || expression_modal_open);
    
    if (!_overlay_active && playing_block_index == -1 && _mx > char_sel_x && _mx < char_sel_x + char_sel_w && _my > char_sel_y && _my < char_sel_y + char_sel_h) {
        if (!scene_edit_mode) focused_block = -1;
        selection_start = 0; selection_end = 0;
        var _grid_x = char_sel_x + 10;
        var _grid_y = char_sel_y + 35;
        var _item_w = 105;
        var _item_h = 135;
        var _cols = 3;
        for (var i = 0; i < array_length(characters); i++) {
            var _ix = _grid_x + (i % _cols) * _item_w;
            var _iy = _grid_y + floor(i / _cols) * _item_h + char_sel_scroll_y;
            if (_my > char_sel_y + 30 && _mx > _ix && _mx < _ix + _item_w && _my > _iy && _my < _iy + _item_h) {
                selected_character_index = i;
                dropdown_open = false;
                dragging_char_index = i; // Unified drag start

                // Sync staging selection: focus character if they are in the scene, otherwise clear focus
                if (scene_edit_mode && active_scene_block_idx != -1) {
                    _scene = script_blocks[active_scene_block_idx];
                    var _found = -1;
                    for (var a = 0; a < array_length(_scene.actors); a++) {
                        if (_scene.actors[a].char_index == i) { _found = a; break; }
                    }
                    scene_edit_selected_actor_idx = _found;
                }
                return;
            }
        }
    }
}

// --- 2e. IN-SCENE DRAGGING & DROPPING ---
if (playing_block_index == -1 && scene_edit_mode && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
    _scene = script_blocks[active_scene_block_idx];
    
    // Start dragging actor already in scene / or just Click to open menu
    if (mouse_check_button_pressed(mb_left)) {
        if (_mx > scene_win_x && _mx < scene_win_x + scene_win_w && _my > scene_win_y && _my < scene_win_y + scene_win_h) {
            for (var a = array_length(_scene.actors) - 1; a >= 0; a--) {
                var _act = _scene.actors[a];
                var _spr = get_character_sprite(_act.char_index);
                if (_spr != -1) {
                    var _sw = sprite_get_width(_spr);
                    var _sh = sprite_get_height(_spr);
                    var _scale = (scene_win_h * 1.5) / 450; 
                    var _ax = scene_win_x + _act.x;
                    var _ay = scene_win_y + _act.y;
                    var _face = variable_struct_exists(_act, "facing") ? _act.facing : 1;
                    if (_mx > _ax - (_sw*_scale)/2 && _mx < _ax + (_sw*_scale)/2 && _my > _ay - (_sh*_scale) && _my < _ay) {
                        dragging_actor_idx = a;
                        scene_edit_selected_actor_idx = a; // Select on click
                        selected_character_index = _act.char_index; // Sync global selection
                        
                        // Auto-scroll character pane
                        var _row = floor(selected_character_index / 3);
                        var _iy = _row * 135;
                        if (_iy + char_sel_scroll_y < 0) char_sel_scroll_y = -_iy;
                        else if (_iy + 135 + char_sel_scroll_y > char_sel_h - 35) char_sel_scroll_y = -( _iy - (char_sel_h - 170) );
                        
                        drag_off_x = _mx - _ax;
                        drag_off_y = _my - _ay;
                        return;
                    }
                }
            }
        }
    }
    
    // Update actor position while dragging
    if (dragging_actor_idx != -1) {
        if (mouse_check_button(mb_left)) {
            var _act = _scene.actors[dragging_actor_idx];
            var _spr = get_character_sprite(_act.char_index);
            var _csh = (_spr != -1) ? sprite_get_height(_spr) : 100;
            var _scale = (scene_win_h * 1.5) / 450; 
            
            _act.x = _mx - scene_win_x - drag_off_x;
            _act.y = _my - scene_win_y - drag_off_y;
            
            // Removed clamps: Characters can turn red and be removed if out of bounds
        } else {
            // Check if off-stage for removal (Standardized 25% V / 51% H)
            var _act = _scene.actors[dragging_actor_idx];
            var _spr = get_character_sprite(_act.char_index);
            if (_spr != -1) {
                var _sw = sprite_get_width(_spr);
                var _sh = sprite_get_height(_spr);
                var _sc = (scene_win_h * 1.5) / 450; 
                var _cw = _sw * _sc;
                var _ch = _sh * _sc;
                
                var _face = variable_struct_exists(_act, "facing") ? _act.facing : 1;
                
                // Vertical intersection
                var _ay = scene_win_y + _act.y;
                var _v_top = max(_ay - _ch, scene_win_y);
                var _v_bottom = min(_ay, scene_win_y + scene_win_h);
                var _v_visible = max(0, _v_bottom - _v_top);
                
                // Horizontal intersection
                var _ax = scene_win_x + _act.x;
                var _h_left = _ax - (_cw * _face)/2;
                var _h_right = _ax + (_cw * _face)/2;
                if (_face == -1) { var _tmp = _h_left; _h_left = _h_right; _h_right = _tmp; }
                
                var _h_intersect_l = max(_h_left, scene_win_x);
                var _h_intersect_r = min(_h_right, scene_win_x + scene_win_w);
                var _h_visible = max(0, _h_intersect_r - _h_intersect_l);
                
                var _in_live = (current_scene_sprite != -1) && (_v_visible >= _ch * 0.25) && (_h_visible >= _cw * 0.51);

                if (!_in_live) {
                    array_delete(_scene.actors, dragging_actor_idx, 1);
                } else {
                    // Update selection to current actor
                    scene_edit_selected_actor_idx = dragging_actor_idx;
                }
            }
            dragging_actor_idx = -1;
        }
    }
}

// --- 3d. STATIC FLIP BUTTON (Scene Edit Mode) ---
if (scene_edit_mode && scene_edit_selected_actor_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks) && mouse_check_button_pressed(mb_left)) {
    _scene = script_blocks[active_scene_block_idx];
    var _btn_w = 120; var _btn_h = 20;
    var _btn_x = scene_win_x + (scene_win_w / 2) - (_btn_w / 2);
    var _btn_y = scene_win_y + scene_win_h + 4;
    var _is_visible = true;
    if (scene_edit_selected_actor_idx < array_length(_scene.actors)) {
        var _act = _scene.actors[scene_edit_selected_actor_idx];
        var _spr = get_character_sprite(_act.char_index);
        if (_spr != -1) {
            var _csw = sprite_get_width(_spr), _csh = sprite_get_height(_spr);
            var _sc = (scene_win_h * 1.5) / 450;
            var _cw = _csw * _sc; var _ch = _csh * _sc;
            var _face = variable_struct_exists(_act, "facing") ? _act.facing : 1;
            var _ax = scene_win_x + _act.x; var _ay = scene_win_y + _act.y;
            var _v_top = max(_ay - _ch, scene_win_y);
            var _v_bottom = min(_ay, scene_win_y + scene_win_h);
            var _v_visible = max(0, _v_bottom - _v_top);
            var _h_left = _ax - (_cw * _face)/2;
            var _h_right = _ax + (_cw * _face)/2;
            if (_face == -1) { var _tmp = _h_left; _h_left = _h_right; _h_right = _tmp; }
            var _h_intersect_l = max(_h_left, scene_win_x);
            var _h_intersect_r = min(_h_right, scene_win_x + scene_win_w);
            var _h_visible = max(0, _h_intersect_r - _h_intersect_l);
            _is_visible = (current_scene_sprite != -1) && (_v_visible >= _ch * 0.25) && (_h_visible >= _cw * 0.51);
        }
    }
    if (_is_visible && _mx > _btn_x && _mx < _btn_x + _btn_w && _my > _btn_y && _my < _btn_y + _btn_h) {
            if (scene_edit_selected_actor_idx < array_length(_scene.actors)) {
                var _act = _scene.actors[scene_edit_selected_actor_idx];
                if (!variable_struct_exists(_act, "facing")) _act.facing = 1;
                _act.facing *= -1;
                return;
            }
        }
}

// --- 2f. LIVE MOVE DRAGGING (When NOT in edit mode) ---
if (!scene_edit_mode && !is_speaking && playing_block_index == -1 && active_scene_block_idx != -1) {
    if (mouse_check_button_pressed(mb_left)) {
        if (_mx > scene_win_x && _mx < scene_win_x + scene_win_w && _my > scene_win_y && _my < scene_win_y + scene_win_h) {
            for (var a = array_length(preview_actors) - 1; a >= 0; a--) {
                var _act = preview_actors[a];
                var _spr = get_character_sprite(_act.char_index);
                if (_spr != -1) {
                    var _sw = sprite_get_width(_spr);
                    var _sh = sprite_get_height(_spr);
                    var _scale = (scene_win_h * 1.5) / 450; 
                    var _ax = scene_win_x + _act.x;
                    var _ay = scene_win_y + _act.y;
                    if (_mx > _ax - (_sw*_scale)/2 && _mx < _ax + (_sw*_scale)/2 && _my > _ay - (_sh*_scale) && _my < _ay) {
                        dragging_preview_idx = a;
                        drag_preview_char = _act.char_index;
                        drag_preview_x = _act.x;
                        drag_preview_y = _act.y;
                        drag_start_x = _act.x;
                        drag_start_y = _act.y;
                        
                        // Reference point is the shoes (ay), but we calculate offset
                        drag_off_x = _mx - _ax;
                        drag_off_y = _my - _ay;
                        
                        selected_character_index = _act.char_index; // Sync global selection
                        
                        // Auto-scroll character pane
                        var _row = floor(selected_character_index / 3);
                        var _iy = _row * 135;
                        if (_iy + char_sel_scroll_y < 0) char_sel_scroll_y = -_iy;
                        else if (_iy + 135 + char_sel_scroll_y > char_sel_h - 35) char_sel_scroll_y = -( _iy - (char_sel_h - 170) );
                        
                        break; // Stop loop so we only select the topmost clicked character
                    }
                }
            }
        }
    }
    
    if (dragging_preview_idx != -1) {
        if (mouse_check_button(mb_left)) {
            var _act = preview_actors[dragging_preview_idx];
            var _spr = get_character_sprite(_act.char_index);
            var _csh = (_spr != -1) ? sprite_get_height(_spr) : 100;
            var _scale = (scene_win_h * 1.5) / 450; 

            _act.x = _mx - scene_win_x - drag_off_x;
            _act.y = _my - scene_win_y - drag_off_y;
            drag_preview_x = _act.x;
            drag_preview_y = _act.y;

            // Removed clamps: Characters can turn red and trigger exit if out of bounds
        } else {
            // RELEASE: Create the "moves" or "exit" action ONLY if moved
            var _act = preview_actors[dragging_preview_idx];
            if (point_distance(_act.x, _act.y, drag_start_x, drag_start_y) > 5) {
                var _insert_idx = (insertion_idx != -1) ? insertion_idx + 1 : array_length(script_blocks);
                
                // Check if off-stage for exit (Standardized 25% V / 51% H)
                var _spr = get_character_sprite(_act.char_index);
                var _sw = sprite_get_width(_spr);
                var _sh = sprite_get_height(_spr);
                var _sc = (scene_win_h * 1.5) / 450; 
                var _cw = _sw * _sc;
                var _ch = _sh * _sc;
                
                var _face = variable_struct_exists(_act, "facing") ? _act.facing : 1;
                
                // Vertical intersection
                var _ay = scene_win_y + _act.y;
                var _v_top = max(_ay - _ch, scene_win_y);
                var _v_bottom = min(_ay, scene_win_y + scene_win_h);
                var _v_visible = max(0, _v_bottom - _v_top);
                
                // Horizontal intersection
                var _ax = scene_win_x + _act.x;
                var _h_left = _ax - (_cw * _face)/2;
                var _h_right = _ax + (_cw * _face)/2;
                if (_face == -1) { var _tmp = _h_left; _h_left = _h_right; _h_right = _tmp; }
                
                var _h_intersect_l = max(_h_left, scene_win_x);
                var _h_intersect_r = min(_h_right, scene_win_x + scene_win_w);
                var _h_visible = max(0, _h_intersect_r - _h_intersect_l);
                
                var _in_live = (current_scene_sprite != -1) && (_v_visible >= _ch * 0.25) && (_h_visible >= _cw * 0.51);

                var _aname = "moves";
                if (!_in_live) {
                    _aname = (_ax < scene_win_x + scene_win_w/2) ? "exits left" : "exits right";
                }
                
                var _lbl = move_speed_labels[move_speed_index];
                if (_lbl != "WALK") _aname += " (" + _lbl + ")";
                if (moonwalk_enabled) _aname += " [MOONWALK]";
                
                array_insert(script_blocks, _insert_idx, { 
                    type: "action", 
                    action_name: _aname, 
                    char_index: _act.char_index, 
                    target_x: _act.x, 
                    target_y: _act.y,
                    facing: _act.facing,
                    height: 85,
                    speed: move_speeds[move_speed_index],
                    moonwalk: moonwalk_enabled
                });
                focused_block = _insert_idx;
                insertion_idx = -1; // Reset after commit
            } else {
                // Revert position cleanly if clicked without dragging to select
                _act.x = drag_start_x;
                _act.y = drag_start_y;
            }
            dragging_preview_idx = -1;
        }
    }
}

// --- 2g. MODE DISMISSAL (Label Click) ---
var _ind_x = max(scene_win_x, 110);
if (insertion_idx != -1 && mouse_check_button_pressed(mb_left)) {
    if (_mx > _ind_x && _mx < _ind_x + 150 && _my > scene_win_y - 45 && _my < scene_win_y - 10) {
        insertion_idx = -1;
        return;
    }
}
if (scene_edit_mode && mouse_check_button_pressed(mb_left)) {
    if (_mx > _ind_x && _mx < _ind_x + 110 && _my > scene_win_y - 45 && _my < scene_win_y - 10) {
        scene_edit_mode = false;
        return;
    }
}

if (mouse_check_button_pressed(mb_left)) {
    // PLAY Button
    
    // FILE MENU TOGGLE
    if (!file_menu_open && playing_block_index == -1 && _mx > 10 && _mx < 90 && _my > 10 && _my < 45) {
        file_menu_open = true;
        return;
    }
    
    if (_mx > btn_play_x && _mx < btn_play_x + btn_play_w && _my > btn_play_y && _my < btn_play_y + btn_play_h) {
        focused_block = -1;
        selection_start = 0; selection_end = 0;
        if (playing_block_index != -1) {
            playing_block_index = -1; is_speaking = false; audio_stop_all(); tts_stop();
            theater_mode = false; theater_paused = false; theater_subtitles = "";
        } else if (array_length(script_blocks) > 0) {
            play_from_index(0);
        }
        return;
    }

    // DICTIONARY Button
    // Force coordinate update to match visual placement exactly
    btn_dictionary_x = scene_win_x + scene_win_w - btn_dictionary_w;
    btn_dictionary_y = scene_win_y - 45;

    if (!theater_mode && !is_speaking && playing_block_index == -1 && _mx > btn_dictionary_x && _mx < btn_dictionary_x + btn_dictionary_w && _my > btn_dictionary_y && _my < btn_dictionary_y + btn_dictionary_h) {
        dictionary_open = true;
        dictionary_scroll_y = 0;
        focused_block = -1; // Clear any text focus when opening modal
        return;
    }

    // EXPR CFG button in character panel header (Narrator has no sprite — skip)
    if (!theater_mode && playing_block_index == -1 && _mx > char_sel_x + 195 && _mx < char_sel_x + char_sel_w - 6 && _my > char_sel_y + 2 && _my < char_sel_y + 28) {
        if (characters[selected_character_index].name != "NARRATOR") open_expr_configurator(selected_character_index);
        return;
    }

    // GLOBAL HEADER BUTTONS (Theater & Move Params)
    if (!theater_mode && !is_speaking && playing_block_index == -1 && !action_modal_open && !scene_modal_open && !move_modal_open) {
        if (_mx > btn_theater_x && _mx < btn_theater_x + btn_theater_w && _my > btn_theater_y && _my < btn_theater_y + btn_theater_h) {
            theater_mode = true;
            theater_paused = true; // Start PAUSED on entry
            theater_subtitles = "";
            scene_edit_mode = false;
            insertion_idx = -1;
            play_from_index(0); 
            return;
        }

        // POSE Button Click (disabled for Narrator)
        var _is_narrator = (characters[selected_character_index].name == "NARRATOR");
        if (!_is_narrator && _mx > btn_pose_x && _mx < btn_pose_x + btn_pose_w && _my > btn_pose_y && _my < btn_pose_y + btn_pose_h) {
            var _active_pose = selected_pose;
            for (var pa = 0; pa < array_length(preview_actors); pa++) {
                if (preview_actors[pa].char_index == selected_character_index) {
                    _active_pose = variable_struct_exists(preview_actors[pa], "pose") ? preview_actors[pa].pose : selected_pose;
                    break;
                }
            }
            pose_modal_temp_pose = _active_pose;
            pose_modal_locked_pose = _active_pose;
            pose_modal_open = true;
            return;
        }
        if (_is_narrator && _mx > btn_pose_x && _mx < btn_pose_x + btn_pose_w && _my > btn_pose_y && _my < btn_pose_y + btn_pose_h) {
            return; // Silently block
        }

        // EXPRESSION Button Click (disabled for Narrator)
        if (!_is_narrator && _mx > btn_expression_x && _mx < btn_expression_x + btn_expression_w && _my > btn_expression_y && _my < btn_expression_y + btn_expression_h) {
            var _active_expr = selected_expression;
            for (var pa = 0; pa < array_length(preview_actors); pa++) {
                if (preview_actors[pa].char_index == selected_character_index) {
                    _active_expr = variable_struct_exists(preview_actors[pa], "expression") ? preview_actors[pa].expression : selected_expression;
                    break;
                }
            }
            expression_modal_temp_expr = _active_expr;
            expression_modal_locked_expr = _active_expr;
            expression_modal_open = true;
            return;
        }
        if (_is_narrator && _mx > btn_expression_x && _mx < btn_expression_x + btn_expression_w && _my > btn_expression_y && _my < btn_expression_y + btn_expression_h) {
            return; // Silently block
        }
    }

    if (theater_mode) {
        // Theater Mode Controls
        if (mouse_check_button_pressed(mb_left)) {
            focused_block = -1;
            selection_start = 0; selection_end = 0;
            // EXIT Button (Bottom Right)
            if (_mx > 1280 - 200 && _mx < 1280 - 20 && _my > 860 && _my < 910) {
                theater_mode = false;
                theater_paused = false;
                playing_block_index = -1; // Clear playback on exit
                is_speaking = false; audio_stop_all(); tts_stop();
                return;
            }
            // PLAY/PAUSE Button (Bottom Left)
            if (_mx > 30 && _mx < 150 && _my > 860 && _my < 910) {
                if (playing_block_index == -1) {
                    play_from_index(0);
                    theater_paused = false;
                } else {
                    theater_paused = !theater_paused;
                    if (theater_paused) {
                        // Pause: Stop current audio
                        audio_stop_all(); tts_stop(); is_speaking = false;
                    } else {
                        // Resume: Trigger the sequencer
                        speaking_pause_timer = -1; 
                    }
                }
                return;
            }
        }
        
        // Blocking all other editor clicks
        if (mouse_check_button_pressed(mb_left)) return;
    }
    
    // ADD VOICE Button
    if (!is_speaking && playing_block_index == -1 && _mx > btn_add_x && _mx < btn_add_x + btn_add_w && _my > btn_add_y && _my < btn_add_y + btn_add_h) {
        selection_start = 0; selection_end = 0;
        var _c = characters[selected_character_index];
        var _idx = (insertion_idx != -1) ? insertion_idx + 1 : array_length(script_blocks);
        array_insert(script_blocks, _idx, { 
            type: "voice", char_index: selected_character_index, text: "", height: 115, caret_pos: 0, selection_anchor: 0, selection_active: false,
            voice_id: _c.voice_id, pitch: _c.pitch, speed: _c.speed, mode: _c.mode, style: _c.style, tweaked: _c.tweaked, is_altered: false
        });
        update_block_height(_idx);
        focused_block = _idx; insertion_idx = -1; keyboard_string = ""; 
        scene_edit_mode = false; 
        
        // Auto-scroll to show the new line
        var _th = 0; for (var k = 0; k < array_length(script_blocks); k++) _th += script_blocks[k].height + 20;
        block_scroll_y = min(0, (box_h - 40) - _th);
        return;
    }

    // ADD ACTION Button (Now also inserts at focused point)
    if (!is_speaking && playing_block_index == -1 && _mx > btn_add_action_x && _mx < btn_add_action_x + btn_add_action_w && _my > btn_add_action_y && _my < btn_add_action_y + btn_add_action_h) {
        focused_block = -1;
        selection_start = 0; selection_end = 0;
        {
            action_modal_open = true;
            action_modal_target_index = (insertion_idx != -1) ? insertion_idx + 1 : -1;
            action_modal_selected_idx = -1;
            action_modal_locked = false;
            
            // Calculate onstage context for the selected character
            var _is_onstage = false;
            var _limit = (action_modal_target_index == -1) ? array_length(script_blocks) : action_modal_target_index;
            for (var k = 0; k < _limit; k++) {
                var _b = script_blocks[k];
                if (variable_struct_exists(_b, "type")) {
                    if (_b.type == "scene") {
                        _is_onstage = false;
                        if (variable_struct_exists(_b, "actors")) {
                            for (var a = 0; a < array_length(_b.actors); a++) {
                                if (_b.actors[a].char_index == selected_character_index) {
                                    _is_onstage = true; break;
                                }
                            }
                        }
                    } else if (_b.type == "action" && _b.char_index == selected_character_index) {
                        var _aname = string_lower(_b.action_name);
                        if (string_pos("enter", _aname) > 0) _is_onstage = true;
                        else if (string_pos("exit", _aname) > 0) _is_onstage = false;
                    }
                }
            }
            action_modal_char_onstage = _is_onstage;
            
            scene_edit_mode = false;
        }
        return;
    }

    // ADD SCENE Button (Now also inserts at focused point)
    if (!is_speaking && playing_block_index == -1 && _mx > btn_add_scene_x && _mx < btn_add_scene_x + btn_add_scene_w && _my > btn_add_scene_y && _my < btn_add_scene_y + btn_add_scene_h) {
        focused_block = -1;
        selection_start = 0; selection_end = 0;
        scene_modal_open = true;
        scene_modal_target_index = (insertion_idx != -1) ? insertion_idx + 1 : -1;
        scene_edit_mode = false;
        return;
    }

    // EDIT VOICE Button
    _overlay_active = (scene_modal_open || action_modal_open || theater_mode || move_modal_open || pose_modal_open || expression_modal_open);
    if (!_overlay_active && !is_speaking && playing_block_index == -1 && _mx > btn_edit_x && _mx < btn_edit_x + btn_edit_w && _my > btn_edit_y && _my < btn_edit_y + btn_edit_h) {
        focused_block = -1;
        selection_start = 0; selection_end = 0;
        edit_mode = true;
        modal_is_local_edit = false;
        scene_edit_mode = false; // Exit edit mode on edit voice
        var _c = characters[selected_character_index];
        modal_voice_id = _c.voice_id; modal_pitch = _c.pitch; modal_speed = _c.speed;
        modal_effort = _c.mode; modal_quality = _c.style; tweak_enabled = _c.tweaked;
        return;
    }
}

// DROPDOWN Button Removed (Using Character Pane instead)

    // --- 4. SCRIPT AREA CLICKS (Block Focus & Caret) ---
    var _clip_x = box_x + 10; var _clip_y = box_y + 5; 
    var _text_margin = 15;
    var _wrap_w = box_w - 120; // Standardized wrap width
    
    var _found_block = focused_block;
    _overlay_active = (file_menu_open || edit_mode || scene_modal_open || action_modal_open || theater_mode || move_modal_open || pose_modal_open || expression_modal_open);
    
    if (!_overlay_active && mouse_check_button_pressed(mb_left) && _mx > box_x - 50 && _mx < box_x + box_w && _my > box_y && _my < box_y + box_h) {
        var _cy = _clip_y + block_scroll_y;
        for (var i = 0; i < array_length(script_blocks); i++) {
            var _block = script_blocks[i];
            var _bh = _block.height;
            var _is_scene = (variable_struct_exists(_block, "type") && _block.type == "scene");
            var _is_action = (variable_struct_exists(_block, "type") && _block.type == "action");
            var _is_voice = !_is_scene && !_is_action;
            var _box_y = (_is_scene || _is_action) ? _cy + 5 : _cy + 20;
            
            // --- 4b. INLINE BUTTONS (RIGHT STACK - Management) ---
            var _bx = box_x + box_w - 35;
            var _bw = 28; var _btn_h = 22;
            
            // If in Gap Editing Mode, these buttons just clear it
            if (insertion_idx != -1) {
                if (_mx > _bx && _mx < _bx + _bw && _my > _cy && _my < _cy + 90) { // Hovering any right button
                    insertion_idx = -1; return;
                }
                var _lx = box_x + 15;
                if (_mx > _lx && _mx < _lx + _bw && _my > _cy && _my < _cy + 90) { // Hovering any left button
                    insertion_idx = -1; return;
                }
            }

            // 1. Delete (X) - Anchored to _cy + 5
            if (playing_block_index == -1 && _mx > _bx && _mx < _bx + _bw && _my > _cy + 5 && _my < _cy + 5 + _btn_h) {
                if (i > 0 && variable_struct_exists(script_blocks[i-1], "linked")) script_blocks[i-1].linked = false;
                array_delete(script_blocks, i, 1);
                update_all_block_heights();
                if (focused_block >= array_length(script_blocks)) focused_block = array_length(script_blocks) - 1;
                return;
            }

            // --- 4c. RESEQUENCE BUTTONS (LEFT STACK) ---
            var _lx = box_x + 15;
            // UP
            if (playing_block_index == -1 && _mx > _lx && _mx < _lx + _bw && _my > _cy + 5 && _my < _cy + 5 + _btn_h) {
                if (i > 0) {
                    if (variable_struct_exists(script_blocks[i], "linked")) script_blocks[i].linked = false;
                    if (variable_struct_exists(script_blocks[i-1], "linked")) script_blocks[i-1].linked = false;
                    if (i > 1 && variable_struct_exists(script_blocks[i-2], "linked")) script_blocks[i-2].linked = false;

                    var _h = script_blocks[i-1].height + 25;
                    var _temp = script_blocks[i]; script_blocks[i] = script_blocks[i-1]; script_blocks[i-1] = _temp;
                    block_scroll_y += _h; // Shift scroll to keep block under mouse
                    if (focused_block == i) focused_block = i-1; else if (focused_block == i-1) focused_block = i;
                }
                return;
            }
            // PENCIL (EDIT)
            else if (playing_block_index == -1 && _mx > _lx && _mx < _lx + _bw && _my > _cy + 35 && _my < _cy + 35 + _btn_h) {
                if (_is_scene) {
                    scene_modal_open = true;
                    scene_modal_target_index = i;
                    scene_modal_edit_mode = true;
                }
                else if (_is_action && (string_pos("WAIT", string_upper(_block.action_name)) > 0 || string_pos("PLAY SFX", string_upper(_block.action_name)) > 0 || string_pos("DISPLAY TITLE", string_upper(_block.action_name)) > 0)) {
                    action_modal_open = true;
                    action_modal_target_index = i;
                    action_modal_edit_mode = true;
                    
                    var _is_wait = string_pos("WAIT", string_upper(_block.action_name)) > 0;
                    var _is_title = string_pos("DISPLAY TITLE", string_upper(_block.action_name)) > 0;
                    if (_is_wait || _is_title) action_modal_wait_duration = variable_struct_exists(_block, "duration") ? _block.duration : 1.0;
                    
                    if (_is_title) {
                        action_modal_title_text = variable_struct_exists(_block, "title_text") ? _block.title_text : "";
                        action_modal_title_align = variable_struct_exists(_block, "title_align") ? _block.title_align : 1;
                        action_modal_title_font = variable_struct_exists(_block, "title_font") ? _block.title_font : 0;
                        action_modal_title_size = variable_struct_exists(_block, "title_size") ? _block.title_size : 1;
                        action_modal_title_color = variable_struct_exists(_block, "title_color") ? _block.title_color : 0;
                        action_modal_dropdown_open = "";
                        keyboard_string = "";
                    }
                    
                    // Automatically find and select the action in the modal list
                    for (var j = 0; j < array_length(all_actions); j++) {
                        if ((_is_wait && all_actions[j].name == "wait") || (_is_title && all_actions[j].name == "display title") || (!_is_wait && !_is_title && all_actions[j].name == "play sfx")) {
                            action_modal_selected_idx = j;
                            action_modal_locked = true;
                            break;
                        }
                    }

                    if (!_is_wait && !_is_title) {
                        refresh_sfx_folders();
                        action_modal_sfx_folder_idx = -1; action_modal_sfx_file_idx = -1;
                        action_modal_sfx_scroll_y = 0; action_modal_sfx_files_scroll_y = 0;
                        if (variable_struct_exists(_block, "sfx_path") && _block.sfx_path != "") {
                            var _sub = string_replace(_block.sfx_path, "sounds/sfx/", "");
                            var _slash = string_pos("/", _sub);
                            if (_slash > 0) {
                                var _fld = string_copy(_sub, 1, _slash - 1);
                                var _fil = string_copy(_sub, _slash + 1, string_length(_sub) - _slash);
                                for (var f = 0; f < array_length(action_modal_sfx_folders); f++) {
                                    if (action_modal_sfx_folders[f] == _fld) {
                                        action_modal_sfx_folder_idx = f;
                                        refresh_sfx_files(_fld);
                                        for (var k = 0; k < array_length(action_modal_sfx_files); k++) {
                                            if (action_modal_sfx_files[k] == _fil) { action_modal_sfx_file_idx = k; break; }
                                        }
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
                else if (_is_action) {
                    var _aname_u = string_upper(_block.action_name);
                    var _is_move = (string_pos("MOVE", _aname_u) > 0 || string_pos("ENTER", _aname_u) > 0 || string_pos("EXIT", _aname_u) > 0);
                    var _is_pose = (string_pos("POSES", _aname_u) > 0);
                    
                    if (_is_move) {
                        move_modal_open = true;
                        move_modal_target_index = i;
                        move_modal_edit_mode = true;
                        
                        // Load current block values into temp modal state
                        var _blk_spd = variable_struct_exists(_block, "speed") ? _block.speed : 1.9;
                        move_modal_temp_moonwalk = variable_struct_exists(_block, "moonwalk") ? _block.moonwalk : false;
                        
                        // Match the speed value to the nearest index
                        move_modal_temp_speed_index = 2; // Default Walk
                        for (var j = 0; j < array_length(move_speeds); j++) {
                            if (abs(move_speeds[j] - _blk_spd) < 0.01) {
                                move_modal_temp_speed_index = j;
                                break;
                            }
                        }
                    } else if (_is_pose) {
                        pose_modal_open = true;
                        pose_modal_target_index = i;
                        pose_modal_edit_mode = true;
                        selected_character_index = _block.char_index;
                        
                        var _p_start = string_pos("poses ", string_lower(_block.action_name)) + 6;
                        var _p_end = string_pos(" ", string_copy(_block.action_name, _p_start, 999));
                        if (_p_end > 0) {
                            var _str_dig = string_digits(string_copy(_block.action_name, _p_start, _p_end));
                            pose_modal_locked_pose = (_str_dig != "") ? real(_str_dig) : 1;
                        } else {
                            pose_modal_locked_pose = 1;
                        }
                        pose_modal_temp_pose = pose_modal_locked_pose;
                    }
                }
                else if (_is_voice) {
                    edit_mode = true;
                    modal_is_local_edit = true;
                    modal_target_block_idx = i;
                    modal_voice_id = _block.voice_id;
                    modal_pitch = _block.pitch;
                    modal_speed = _block.speed;
                    modal_effort = _block.mode;
                    modal_quality = _block.style;
                    tweak_enabled = _block.tweaked;
                }
                return;
            }
            // DOWN
            else if (playing_block_index == -1 && _mx > _lx && _mx < _lx + _bw && _my > _cy + 65 && _my < _cy + 65 + _btn_h) {
                if (i < array_length(script_blocks) - 1) {
                    if (variable_struct_exists(script_blocks[i], "linked")) script_blocks[i].linked = false;
                    if (variable_struct_exists(script_blocks[i+1], "linked")) script_blocks[i+1].linked = false;
                    if (i > 0 && variable_struct_exists(script_blocks[i-1], "linked")) script_blocks[i-1].linked = false;

                    var _h = script_blocks[i+1].height + 25;
                    var _temp = script_blocks[i]; script_blocks[i] = script_blocks[i+1]; script_blocks[i+1] = _temp;
                    block_scroll_y -= _h; // Shift scroll to keep block under mouse
                    if (focused_block == i) focused_block = i+1; else if (focused_block == i+1) focused_block = i;
                }
                return;
            }
            
            // 4. PLAY FROM HERE (Green Triangle) - Now in the GUTTER
            var _px = box_x - 30; var _py = _cy + 5;
            if (playing_block_index == -1 && _mx > _px && _mx < _px + 30 && _my > _py && _my < _py + 30) {
                play_from_index(i);
                return;
            }

            if (_is_scene) {
                // Scene Box Click (Enable Staging)
                if (playing_block_index == -1 && _mx > box_x + 55 && _mx < box_x + 55 + _wrap_w + 20 && _my > _box_y && _my < _box_y + 80) {
                    focused_block = i;
                    scene_edit_mode = !scene_edit_mode; // Toggle
                    insertion_idx = -1; // Turn off Splice Mode
                    if (scene_edit_mode) {
                        update_preview_actors_for_block(i, true);
                        if (active_scene_block_idx != -1) {
                            current_scene_sprite = get_scene_sprite(script_blocks[active_scene_block_idx].internal_name);
                            set_scene_dimensions(current_scene_sprite);
                        }
                    }
                    return;
                }
            } else if (_is_action || _is_voice) {
                // Other Blocks (Dialogue/Action) - Disable Staging
                if (playing_block_index == -1 && _mx > box_x + 55 && _mx < box_x + 55 + _wrap_w + 20 && _my > _box_y && _my < _box_y + (_bh - 55)) {
                    focused_block = i;
                    
                    update_preview_actors_for_block(i, true);
                    if (active_scene_block_idx != -1) {
                        current_scene_sprite = get_scene_sprite(script_blocks[active_scene_block_idx].internal_name);
                        set_scene_dimensions(current_scene_sprite);
                    }
                    
                    if (variable_struct_exists(_block, "char_index")) {
                        selected_character_index = _block.char_index;
                        var _row = floor(selected_character_index / 3);
                        var _iy_scroll = _row * 135;
                        if (_iy_scroll + char_sel_scroll_y < 0) char_sel_scroll_y = -_iy_scroll;
                        else if (_iy_scroll + 135 + char_sel_scroll_y > char_sel_h - 35) char_sel_scroll_y = -( _iy_scroll - (char_sel_h - 170) );
                    }
                    
                    scene_edit_mode = false; // Always OFF
                    insertion_idx = -1;
                    
                    if (_is_voice) {
                        keyboard_string = "";
                        var _rx = _mx - (box_x + 60); var _ry = _my - (_cy + 32);
                        var _best_p = 0; var _min_d = 999999;
                        for (var c = 0; c <= string_length(_block.text); c++) {
                            var _pos = get_text_pos(_block.text, c, _wrap_w, 28);
                            var _d = point_distance(_rx, _ry, _pos.x, _pos.y);
                            if (_d < _min_d) { _min_d = _d; _best_p = c; }
                        }
                        _block.caret_pos = _best_p;
                        selection_start = _best_p;
                        selection_end = _best_p;
                        is_selecting = true;
                    }
                    return;
                }
            }
            
            // Main Block Focus Click
            if (playing_block_index == -1 && _mx > box_x + 50 && _mx < box_x + box_w - 50 && _my > _cy && _my < _cy + _bh) {
                focused_block = i;
                
                if (variable_struct_exists(_block, "char_index")) {
                    selected_character_index = _block.char_index;
                    var _row = floor(selected_character_index / 3);
                    var _iy_scroll = _row * 135;
                    if (_iy_scroll + char_sel_scroll_y < 0) char_sel_scroll_y = -_iy_scroll;
                    else if (_iy_scroll + 135 + char_sel_scroll_y > char_sel_h - 35) char_sel_scroll_y = -( _iy_scroll - (char_sel_h - 170) );
                }
                
                insertion_idx = -1;
                selection_start = 0; selection_end = 0; // Clear on general focus
                if (!_is_scene && !_is_action) {
                    keyboard_string = ""; 
                    _block.caret_pos = string_length(_block.text);
                }
                return;
            }
            
            // --- 4d. GAP CLICK (Between blocks) ---
            if (playing_block_index == -1 && i < array_length(script_blocks) - 1) {
                var _gap_y = _cy + _bh;
                var _plus_center_x = box_x + (box_w / 2);
                
                // Link Check
                var _b1 = script_blocks[i];
                var _b2 = script_blocks[i+1];

                var _b1_type = get_link_type(_b1);
                var _b2_type = get_link_type(_b2);

                var _diff_char = (variable_struct_exists(_b1, "char_index") && variable_struct_exists(_b2, "char_index") && real(_b1.char_index) != real(_b2.char_index));

                var _base_valid = false;
                if ((_b1_type == "move" && _b2_type == "voice") || (_b1_type == "voice" && _b2_type == "move")) _base_valid = true;
                else if ((_b1_type == "move" && _b2_type == "sfx") || (_b1_type == "sfx" && _b2_type == "move")) _base_valid = true;
                else if ((_b1_type == "voice" && _b2_type == "sfx") || (_b1_type == "sfx" && _b2_type == "voice")) _base_valid = true;
                else if ((_b1_type == "title" && _b2_type == "sfx") || (_b1_type == "sfx" && _b2_type == "title")) _base_valid = true;
                else if ((_b1_type == "title" && _b2_type == "voice") || (_b1_type == "voice" && _b2_type == "title")) _base_valid = true;
                else if (_b1_type == "move" && _b2_type == "move" && _diff_char) _base_valid = true;
                else if (_b1_type == "voice" && _b2_type == "voice" && _diff_char) _base_valid = true;

                var _is_linked = variable_struct_exists(_b1, "linked") && _b1.linked;
                var _chain_valid = true;
                
                if (_base_valid && !_is_linked) {
                    var _start_idx = i;
                    while (_start_idx > 0 && variable_struct_exists(script_blocks[_start_idx-1], "linked") && script_blocks[_start_idx-1].linked) _start_idx--;
                    var _end_idx = i + 1;
                    while (_end_idx < array_length(script_blocks) - 1 && variable_struct_exists(script_blocks[_end_idx], "linked") && script_blocks[_end_idx].linked) _end_idx++;
                    
                    var _sfx_in_chain = 0;
                    var _title_in_chain = 0;
                    var _move_in_chain = false;
                    for (var k = _start_idx; k <= _end_idx; k++) {
                        var _bk = script_blocks[k];
                        var _c_idx = real(variable_struct_exists(_bk, "char_index") ? _bk.char_index : 0);
                        var _bk_type = get_link_type(_bk);
                        if (_bk_type == "sfx") _sfx_in_chain++;
                        if (_bk_type == "title") _title_in_chain++;
                        if (_bk_type == "move") _move_in_chain = true;
                        
                        if (_bk_type == "voice" || _bk_type == "move") {
                            for (var j = k + 1; j <= _end_idx; j++) {
                                var _bj = script_blocks[j];
                                if (real(variable_struct_exists(_bj, "char_index") ? _bj.char_index : 0) == _c_idx) {
                                    var _bj_type = get_link_type(_bj);
                                    if (_bk_type == "voice" && _bj_type == "voice") { _chain_valid = false; break; }
                                    if (_bk_type == "move" && _bj_type == "move") { _chain_valid = false; break; }
                                }
                            }
                        }
                        if (!_chain_valid) break;
                    }
                    if (_title_in_chain > 0) {
                        if (_title_in_chain > 1 || _move_in_chain || (_end_idx - _start_idx > 1)) _chain_valid = false;
                    } else {
                        if (_sfx_in_chain > 1) _chain_valid = false;
                    }
                }
                
                if ((_base_valid && _chain_valid) || _is_linked) {
                    var _link_x = box_x + 90;
                    if (_my > _gap_y && _my < _gap_y + 20 && _mx > _link_x - 15 && _mx < _link_x + 60) {
                        if (variable_struct_exists(_b1, "linked")) _b1.linked = !_b1.linked;
                        else _b1.linked = true;
                        
                        if (_b1.linked && insertion_idx == i) insertion_idx = -1;
                        return;
                    }
                }

                if (!_is_linked && _my > _gap_y && _my < _gap_y + 20 && _mx > _plus_center_x - 20 && _mx < _plus_center_x + 20) {
                    if (insertion_idx == i) insertion_idx = -1; // Toggle Off
                    else {
                        insertion_idx = i; // Toggle On
                        scene_edit_mode = false; // Turn off Staging
                    }
                    return;
                }
            }
            
            _cy += _bh + 20;
        }
        // Clicked script area but not a block or gap
        insertion_idx = -1;
        focused_block = -1;
        scene_edit_mode = false; // Exit Staging on empty area click
        selection_start = 0; selection_end = 0;
    }

// --- 4e. TEXT SELECTION DRAGGING ---
if (playing_block_index == -1 && is_selecting && focused_block != -1) {
    if (mouse_check_button(mb_left)) {
        var _b = script_blocks[focused_block];
        // Calculate current y of focused block for coordinate mapping
        var _calc_y = box_y + 5 + block_scroll_y;
        for (var i = 0; i < focused_block; i++) _calc_y += script_blocks[i].height + 20;
        
        var _rx = _mx - (box_x + 60); var _ry = _my - (_calc_y + 32);
        var _best_p = 0; var _min_d = 999999;
        for (var c = 0; c <= string_length(_b.text); c++) {
            var _pos = get_text_pos(_b.text, c, _wrap_w, 28);
            var _d = point_distance(_rx, _ry, _pos.x, _pos.y);
            if (_d < _min_d) { _min_d = _d; _best_p = c; }
        }
        selection_end = _best_p;
        _b.caret_pos = _best_p;
        cursor_timer = 0; cursor_visible = true; // Keep caret solid while dragging
    } else {
        is_selecting = false;
    }
}

// Scroll Wheel
_overlay_active = (file_menu_open || edit_mode || scene_modal_open || action_modal_open || theater_mode || move_modal_open);

if (!_overlay_active) {
    var _over_pane = (_mx > char_sel_x && _mx < char_sel_x + char_sel_w && _my > char_sel_y && _my < char_sel_y + char_sel_h);
    
    if (_over_pane) {
        // Scroll the character selector
        var _cols = 3; var _item_h = 135;
        var _total_h = ceil(array_length(characters) / _cols) * _item_h;
        var _max_visible_h = char_sel_h - 35;
        if (mouse_wheel_up()) char_sel_scroll_y = min(0, char_sel_scroll_y + _item_h);
        if (mouse_wheel_down()) {
            if (_total_h > _max_visible_h) char_sel_scroll_y = max(-(_total_h - _max_visible_h), char_sel_scroll_y - _item_h);
        }
        
        // --- CHARACTER SELECTION & DRAG START ---
        if (playing_block_index == -1 && mouse_check_button_pressed(mb_left)) {
            var _grid_x = char_sel_x + 10; var _grid_y = char_sel_y + 35;
            for (var i = 0; i < array_length(characters); i++) {
                var _ix = _grid_x + (i % _cols) * 105;
                var _iy = _grid_y + floor(i / _cols) * _item_h + char_sel_scroll_y;
                if (_mx > _ix && _mx < _ix + 105 && _my > _iy && _my < _iy + _item_h && _my > char_sel_y + 30 && _my < char_sel_y + char_sel_h) {
                    var _spr = get_character_sprite(i);
                    var _csh = (_spr != -1) ? sprite_get_height(_spr) : 100;
                    var _scale = (scene_win_h * 1.5) / 450; 
                    
                    selected_character_index = i;
                    var _c = characters[selected_character_index];
                    selected_pose = variable_struct_exists(_c, "pose") ? _c.pose : 1;
                    selected_expression = variable_struct_exists(_c, "expression") ? _c.expression : 21;

                    for (var pa = 0; pa < array_length(preview_actors); pa++) {
                        if (preview_actors[pa].char_index == i) {
                            selected_pose = variable_struct_exists(preview_actors[pa], "pose") ? preview_actors[pa].pose : selected_pose;
                            selected_expression = variable_struct_exists(preview_actors[pa], "expression") ? preview_actors[pa].expression : selected_expression;
                            break;
                        }
                    }

                    // Sync staging selection
                    if (scene_edit_mode && active_scene_block_idx != -1) {
                        _scene = script_blocks[active_scene_block_idx];
                        var _found = -1;
                        for (var a = 0; a < array_length(_scene.actors); a++) {
                            if (_scene.actors[a].char_index == i) { _found = a; break; }
                        }
                        scene_edit_selected_actor_idx = _found;
                    }

                    dragging_char_index = i; // START DRAGGING (Unified)
                    drag_off_x = 0;
                    drag_off_y = -(_csh * _scale) / 2;
                    
                    // Auto-scroll logic
                    var _row = floor(selected_character_index / 3);
                    var _iy_scroll = _row * 135;
                    if (_iy_scroll + char_sel_scroll_y < 0) char_sel_scroll_y = -_iy_scroll;
                    else if (_iy_scroll + 135 + char_sel_scroll_y > char_sel_h - 35) char_sel_scroll_y = -( _iy_scroll - (char_sel_h - 170) );
                    break;
                }
            }
        }
    } else {
        // Normal script scrolling
        if (mouse_wheel_up()) block_scroll_y += 80;
        if (mouse_wheel_down()) block_scroll_y -= 80;
    }
}

// --- UNIFIED DRAGGING FROM PANE LOGIC ---
_overlay_active = (file_menu_open || edit_mode || scene_modal_open || action_modal_open || theater_mode || move_modal_open);

if (!_overlay_active && playing_block_index == -1 && dragging_char_index != -1) {
    if (!mouse_check_button(mb_left)) {
        var _spr_ghost = get_character_sprite(dragging_char_index);
        var _char_h = (_spr_ghost != -1) ? sprite_get_height(_spr_ghost) * ((scene_win_h * 1.5) / 450) : 100;
        var _char_w = (_spr_ghost != -1) ? sprite_get_width(_spr_ghost) * ((scene_win_h * 1.5) / 450) : 100;

        // Proposed Position (relative to window, with offsets and clamps)
        var _px = _mx - scene_win_x - drag_off_x;
        var _py = _my - scene_win_y - drag_off_y;
        if (_py > scene_win_h) _py = scene_win_h;
        if (_py < scene_win_h * 0.25) _py = scene_win_h * 0.25;

        // Vertical intersection (using Proposed Position)
        var _ay_abs = scene_win_y + _py;
        var _ch = _char_h;
        var _cw = _char_w;
        var _v_top = max(_ay_abs - _ch, scene_win_y);
        var _v_bottom = min(_ay_abs, scene_win_y + scene_win_h);
        var _v_visible = max(0, _v_bottom - _v_top);
        
        // Horizontal intersection (using Proposed Position)
        var _ax_abs = scene_win_x + _px;
        var _face = (_mx < scene_win_x + (scene_win_w / 2)) ? 1 : -1;
        var _h_left = _ax_abs - (_cw * _face)/2;
        var _h_right = _ax_abs + (_cw * _face)/2;
        if (_face == -1) { var _tmp = _h_left; _h_left = _h_right; _h_right = _tmp; }
        
        var _h_intersect_l = max(_h_left, scene_win_x);
        var _h_intersect_r = min(_h_right, scene_win_x + scene_win_w);
        var _h_visible = max(0, _h_intersect_r - _h_intersect_l);
        
        var _in_live = (current_scene_sprite != -1) && (_v_visible >= _ch * 0.25) && (_h_visible >= _cw * 0.51);
        
        if (_in_live) {
            if (scene_edit_mode) {
                // STAGING DROP: Add to scene block permanently
                if (active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                    _scene = script_blocks[active_scene_block_idx];
                    var _dup_idx = -1;
                    for (var a = 0; a < array_length(_scene.actors); a++) {
                        if (_scene.actors[a].char_index == dragging_char_index) { _dup_idx = a; break; }
                    }
                    if (_dup_idx == -1) {
                        // Auto-flip for entrance
                        var _is_left = (_mx < scene_win_x + (scene_win_w / 2));
                        _face = _is_left ? -1 : 1;
                        
                        // Precise coordinates within background
                        var _nx = _px;
                        var _ny = _py;
                        
                        var _c = characters[dragging_char_index];
                        var _pose = variable_struct_exists(_c, "pose") ? _c.pose : 1;
                        var _expr = variable_struct_exists(_c, "expression") ? _c.expression : 21;
                        
                        array_push(_scene.actors, { char_index: dragging_char_index, x: _nx, y: _ny, facing: _face, pose: _pose, expression: _expr });
                        scene_edit_selected_actor_idx = array_length(_scene.actors) - 1;
                    } else {
                        // If character already onstage, update selection to them immediately
                        scene_edit_selected_actor_idx = _dup_idx;
                    }
                }
            } else {
                // LIVE DROP: Create Script Command
                var _onstage = false;
                if (active_scene_block_idx != -1) {
                    for (var pa = 0; pa < array_length(preview_actors); pa++) {
                        if (preview_actors[pa].char_index == dragging_char_index) { _onstage = true; break; }
                    }
                }
                
                if (!_onstage) {
                    var _is_left = (_mx < scene_win_x + (scene_win_w / 2));
                    var _aname = _is_left ? "enters from left" : "enters from right";
                    
                    var _lbl = move_speed_labels[move_speed_index];
                    if (_lbl != "WALK") _aname += " (" + _lbl + ")";
                    if (moonwalk_enabled) _aname += " [MOONWALK]";
                    
                    var _insert_idx = (insertion_idx != -1) ? insertion_idx + 1 : array_length(script_blocks);
                    array_insert(script_blocks, _insert_idx, { 
                        type: "action", 
                        action_name: _aname, 
                        char_index: dragging_char_index, 
                        target_x: _px, 
                        target_y: _py,
                        facing: _is_left ? 1 : -1,
                        height: 85,
                        speed: move_speeds[move_speed_index],
                        moonwalk: moonwalk_enabled
                    });
                    focused_block = _insert_idx;
                    insertion_idx = -1;
                    update_all_block_heights();
                    
                    var _th = 0; for (var k = 0; k < _insert_idx; k++) _th += script_blocks[k].height + 20;
                    block_scroll_y = -_th + 50; 
                }
            }
        }
        dragging_char_index = -1;
    }
}

// Global Scroll Clamp
var _full_script_h = 0; 
for (var i = 0; i < array_length(script_blocks); i++) {
    _full_script_h += script_blocks[i].height + 20;
}

var _scroll_buffer = box_h / 2; // Normal breathing room at bottom
if (_full_script_h < box_h - 20) block_scroll_y = 0;
else block_scroll_y = clamp(block_scroll_y, -( (_full_script_h + _scroll_buffer) - (box_h - 20)), 0);


// --- 5. KEYBOARD INTERACTION ---
if (playing_block_index == -1 && !is_speaking && focused_block >= 0) {
    var _b = script_blocks[focused_block];
    if (variable_struct_exists(_b, "caret_pos")) {
        var _ctrl = keyboard_check(vk_control);
        var _repeat_key = -1;
        if (keyboard_check(vk_left)) _repeat_key = vk_left;
        else if (keyboard_check(vk_right)) _repeat_key = vk_right;
        else if (keyboard_check(vk_up)) _repeat_key = vk_up;
        else if (keyboard_check(vk_down)) _repeat_key = vk_down;
        else if (keyboard_check(vk_backspace)) _repeat_key = vk_backspace;
        else if (keyboard_check(vk_delete)) _repeat_key = vk_delete;
        
        var _do_action = false;
        if (_repeat_key != -1) {
            if (keyboard_check_pressed(_repeat_key)) { _do_action = true; key_repeat_timer = 25; }
            else { key_repeat_timer--; if (key_repeat_timer <= 0) { _do_action = true; key_repeat_timer = 2; } }
        }

        if (string_length(keyboard_string) > 0) {
            if (selection_start != selection_end) {
                var _s = min(selection_start, selection_end);
                var _e = max(selection_start, selection_end);
                _b.text = string_delete(_b.text, _s + 1, _e - _s);
                _b.caret_pos = _s;
                selection_start = _s; selection_end = _s;
            }
            _b.text = string_insert(keyboard_string, _b.text, _b.caret_pos + 1);
            _b.caret_pos += string_length(keyboard_string);
            update_block_height(focused_block);
            keyboard_string = "";
        }
        
        if (_do_action) {
            if ((_repeat_key == vk_backspace || _repeat_key == vk_delete) && selection_start != selection_end) {
                var _s = min(selection_start, selection_end);
                var _e = max(selection_start, selection_end);
                _b.text = string_delete(_b.text, _s + 1, _e - _s);
                _b.caret_pos = _s;
                selection_start = _s; selection_end = _s;
                update_block_height(focused_block);
                _do_action = false; // Consume the keypress
            }
            
            // _wrap_w is already defined as box_w - 120 for consistency with Draw event
            if (_repeat_key == vk_left) _b.caret_pos = max(0, _b.caret_pos - 1);
            if (_repeat_key == vk_right) _b.caret_pos = min(string_length(_b.text), _b.caret_pos + 1);
            if (_repeat_key == vk_up || _repeat_key == vk_down) {
                var _cur_p = get_text_pos(_b.text, _b.caret_pos, _wrap_w, 28);
                var _target_y = _cur_p.y + (_repeat_key == vk_up ? -28 : 28);
                
                // Calculate the last character's position to define vertical bounds
                var _last_p = get_text_pos(_b.text, string_length(_b.text), _wrap_w, 28);
                
                if (_target_y < 0) {
                    _b.caret_pos = 0;
                } else if (_target_y > _last_p.y) {
                    _b.caret_pos = string_length(_b.text);
                } else {
                    var _best_p = _b.caret_pos; var _min_dx = 999999;
                    var _found_on_line = false;
                    for (var c = 0; c <= string_length(_b.text); c++) {
                        var _pos = get_text_pos(_b.text, c, _wrap_w, 28);
                        if (_pos.y == _target_y) {
                            var _dx = abs(_cur_p.x - _pos.x);
                            if (_dx < _min_dx) { _min_dx = _dx; _best_p = c; _found_on_line = true; }
                        }
                    }
                    if (_found_on_line) _b.caret_pos = _best_p;
                }
            }
            if (_repeat_key == vk_backspace && _b.caret_pos > 0) { _b.text = string_delete(_b.text, _b.caret_pos, 1); _b.caret_pos--; update_block_height(focused_block); }
            if (_repeat_key == vk_delete && _b.caret_pos < string_length(_b.text)) { _b.text = string_delete(_b.text, _b.caret_pos + 1, 1); update_block_height(focused_block); }
        }
        if (keyboard_check_pressed(vk_home)) _b.caret_pos = 0;
        if (keyboard_check_pressed(vk_end)) _b.caret_pos = string_length(_b.text);
        if (keyboard_check_pressed(vk_enter)) { _b.text = string_insert("\n", _b.text, _b.caret_pos + 1); _b.caret_pos++; update_block_height(focused_block); }
    }
}

cursor_timer++; if (cursor_timer >= 60) cursor_timer = 0; cursor_visible = (cursor_timer < 30);

// --- 1b. SCENE CONTEXT TRACKING (Moved to end of step) ---
// Find the last scene block before the currently focused or playing block
// Ensure indices are within bounds after potential deletions
var _len = array_length(script_blocks);
focused_block = clamp(focused_block, -1, _len - 1);
playing_block_index = clamp(playing_block_index, -1, _len - 1);
last_played_block_index = clamp(last_played_block_index, -1, _len - 1);

var _ref_idx = (playing_block_index != -1) ? playing_block_index : (insertion_idx != -1 ? insertion_idx : (focused_block != -1 ? focused_block : _len - 1));
_ref_idx = clamp(_ref_idx, -1, _len - 1);

active_scene_block_idx = -1;
var _found_scene = false;
if (_ref_idx != -1) {
    for (var i = _ref_idx; i >= 0; i--) {
        var _b = script_blocks[i];
        if (variable_struct_exists(_b, "type") && _b.type == "scene") {
            active_scene_block_idx = i;
            var _new_spr = get_scene_sprite(_b.internal_name);
            if (current_scene_sprite != _new_spr) {
                current_scene_sprite = _new_spr;
                set_scene_dimensions(current_scene_sprite);
            }
            _found_scene = true;
            break;
        }
    }
}

if (!_found_scene) {
    if (current_scene_sprite != -1) {
        current_scene_sprite = -1;
        set_scene_dimensions(-1);
    }
}

// STAGING ENFORCEMENT: Only allow staging if focused on a scene heading
if (scene_edit_mode && focused_block != active_scene_block_idx) {
    scene_edit_mode = false;
    scene_edit_selected_actor_idx = -1;
}

// Compute preview_actors
if (playing_block_index == -1) {
    update_preview_actors_for_block(_ref_idx, true);
}

// 3. Re-apply drag state AFTER recomputing
if (dragging_preview_idx != -1) {
    for(var pa=0; pa<array_length(preview_actors); pa++) {
        if (preview_actors[pa].char_index == drag_preview_char) {
            preview_actors[pa].x = drag_preview_x;
            preview_actors[pa].y = drag_preview_y;
            dragging_preview_idx = pa; 
            break;
        }
    }
}

// 4. Staging and Splicing Mutual Exclusion Safety Check
if (scene_edit_mode && insertion_idx != -1) {
    insertion_idx = -1;
}