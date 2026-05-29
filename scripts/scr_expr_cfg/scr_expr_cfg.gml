/// @description Expression tile configurator — Create-side helpers and Step-side modal handler.

function expr_cfg_get_pc() {
    return expr_cfg_configs[expr_cfg_pose][expr_cfg_high ? 1 : 0];
}

function expr_cfg_set_pc(_v) {
    expr_cfg_configs[expr_cfg_pose][expr_cfg_high ? 1 : 0] = _v;
}

function expr_cfg_auto_fill(_pose_num, _is_high) {
    var _c_af = characters[expr_cfg_char_idx];
    var _ai_af = variable_struct_exists(_c_af, "act_index") ? _c_af.act_index : 1;
    var _sfx_off_af = _is_high ? 50 : 0;
    var _pfx_af = string(_ai_af) + string(_pose_num);
    var _folder_af = datafiles_path + "images/characters/" + _c_af.name + "/";

    var _off_af = undefined;
    if (file_exists(_folder_af + "offsets.json")) {
        var _s = ""; var _f = file_text_open_read(_folder_af + "offsets.json");
        while (!file_text_eof(_f)) { _s += file_text_readln(_f); }
        file_text_close(_f); _off_af = json_parse(_s);
    }

    var _lo_s = 6 + _sfx_off_af; var _lo_e = 10 + _sfx_off_af;
    var _body_file_af = ""; var _body_sz_af = 0;
    var _box = 0; var _boy = 0;
    for (var _n = _lo_s; _n <= _lo_e; _n++) {
        var _ns = (_n < 10 ? "0" : "") + string(_n);
        var _cf = "pose_" + _pfx_af + _ns + ".png";
        if (file_exists(_folder_af + _cf)) {
            var _fb = file_bin_open(_folder_af + _cf, 0);
            var _sz = (_fb != -1) ? file_bin_size(_fb) : 0;
            if (_fb != -1) file_bin_close(_fb);
            if (_sz > _body_sz_af) { _body_sz_af = _sz; _body_file_af = _cf; }
        }
    }
    if (_off_af != undefined && _body_file_af != "") {
        var _bk2 = string_copy(_body_file_af, 1, string_length(_body_file_af) - 4);
        if (variable_struct_exists(_off_af, _bk2)) { var _bv = _off_af[$ _bk2]; _box = _bv[0]; _boy = _bv[1]; }
    }

    var _face_n_af = 5 + _sfx_off_af;
    var _face_sfx_af = (_face_n_af < 10 ? "0" : "") + string(_face_n_af);
    var _face_file_af = "pose_" + _pfx_af + _face_sfx_af + ".png";
    if (!file_exists(_folder_af + _face_file_af)) _face_file_af = "";
    var _fdx = 0; var _fdy = 0;
    if (_off_af != undefined) {
        var _fok = "pose_" + _pfx_af + _face_sfx_af;
        if (variable_struct_exists(_off_af, _fok)) { var _fv = _off_af[$ _fok]; _fdx = _fv[0] - _box; _fdy = _fv[1] - _boy; }
    }

    var _eyes_n_af = 10 + 1 + _sfx_off_af;
    var _eyes_sfx_af = (_eyes_n_af < 10 ? "0" : "") + string(_eyes_n_af);
    var _edx = 0; var _edy = 0;
    if (_off_af != undefined) {
        var _eok = "pose_" + _pfx_af + _eyes_sfx_af;
        if (variable_struct_exists(_off_af, _eok)) { var _ev = _off_af[$ _eok]; _edx = _ev[0] - _box; _edy = _ev[1] - _boy; }
    }

    var _mouth_n_af = 31 + _sfx_off_af;
    var _mouth_sfx_af = (_mouth_n_af < 10 ? "0" : "") + string(_mouth_n_af);
    var _mdx = 0; var _mdy = 0;
    if (_off_af != undefined) {
        var _mok = "pose_" + _pfx_af + _mouth_sfx_af;
        if (variable_struct_exists(_off_af, _mok)) { var _mv = _off_af[$ _mok]; _mdx = _mv[0] - _box; _mdy = _mv[1] - _boy; }
    }

    return {
        body_file: _body_file_af, face_file: _face_file_af,
        body_dx: 0, body_dy: 0,
        face_dx: _fdx, face_dy: _fdy,
        eyes_dx: _edx, eyes_dy: _edy,
        mouth_dx: _mdx, mouth_dy: _mdy,
        eyes_files: {}, mouth_files: {}
    };
}

function open_expr_configurator(_char_idx) {
    if (characters[_char_idx].name == "NARRATOR") return;
    expr_cfg_char_idx      = _char_idx;
    expr_cfg_pose          = 1;
    expr_cfg_high          = false;
    expr_cfg_preview_expr  = 1;
    expr_cfg_selected_layer = 1;
    expr_cfg_drag          = false;
    expr_cfg_zoom          = 1.0;
    expr_cfg_configs       = array_create(5);
    for (var _i2 = 1; _i2 <= 4; _i2++) expr_cfg_configs[_i2] = [undefined, undefined];

    var _c_oc = characters[_char_idx];
    var _folder_oc = datafiles_path + "images/characters/" + _c_oc.name + "/";
    var _existing = {};
    if (file_exists(_folder_oc + "expressions_config.json")) {
        var _s2 = ""; var _f2 = file_text_open_read(_folder_oc + "expressions_config.json");
        while (!file_text_eof(_f2)) { _s2 += file_text_readln(_f2); }
        file_text_close(_f2); _existing = json_parse(_s2);
    }
    for (var _p2 = 1; _p2 <= 4; _p2++) {
        for (var _d2 = 0; _d2 <= 1; _d2++) {
            var _k2 = "pose_" + string(_p2) + "_" + (_d2 == 1 ? "high" : "low");
            expr_cfg_configs[_p2][_d2] = variable_struct_exists(_existing, _k2)
                ? _existing[$ _k2]
                : expr_cfg_auto_fill(_p2, (_d2 == 1));
        }
    }

    expr_cfg_pan_x = 0; expr_cfg_pan_y = 0; expr_cfg_pan_drag = false;
    expr_cfg_file_list   = [];
    expr_cfg_file_scroll = 0;
    expr_cfg_preview_mood = 0;
    var _scan_folder = datafiles_path + "images/characters/" + characters[_char_idx].name + "/";
    var _scan_f = file_find_first(_scan_folder + "*.png", 0);
    while (_scan_f != "") { array_push(expr_cfg_file_list, _scan_f); _scan_f = file_find_next(); }
    file_find_close();
    array_sort(expr_cfg_file_list, function(a, b) { return (a < b) ? -1 : (a > b ? 1 : 0); });
    expr_cfg_open = true;
}

// Stages config for disk write; actual write happens in Step (file_text_write scope restriction).
function save_expr_config() {
    var _c_sv = characters[expr_cfg_char_idx];
    var _folder_sv = datafiles_path + "images/characters/" + _c_sv.name + "/";
    var _out = {};
    for (var _p3 = 1; _p3 <= 4; _p3++) {
        for (var _d3 = 0; _d3 <= 1; _d3++) {
            var _cfg3 = expr_cfg_configs[_p3][_d3];
            if (_cfg3 != undefined) _out[$ "pose_" + string(_p3) + "_" + (_d3 == 1 ? "high" : "low")] = _cfg3;
        }
    }
    expr_cfg_pending_save_path = _folder_sv + "expressions_config.json";
    expr_cfg_pending_save_data = json_stringify(_out);
    if (ds_map_exists(char_expr_cache, _c_sv.name)) ds_map_delete(char_expr_cache, _c_sv.name);
}

// Step handler for the expression configurator modal.
function step_modal_expr_cfg() {
    var _mx = mouse_x; var _my = mouse_y;
    var _m_x = 85; var _m_y = 55; var _m_w = 1110; var _m_h = 770;
    var _lx = _m_x + 12; var _ly = _m_y + 12;
    var _c_s = characters[expr_cfg_char_idx];
    var _nav_y_s   = _ly + 28;
    var _pose_ys   = _nav_y_s + 36;
    var _dir_ys    = _pose_ys + 36;
    var _layer_y0_s = _dir_ys + 38;
    var _nudge_ys  = _layer_y0_s + 4 * 52 + 6;
    var _esel_ys   = _nudge_ys + 110;

    var _pc_s = expr_cfg_get_pc();

    var get_active_layer_file = function() {
        var _c_s = characters[expr_cfg_char_idx];
        var _pc_s = expr_cfg_get_pc();
        var _cur_file_s = ""; var _layer_key_s = "";
        switch (expr_cfg_selected_layer) {
            case 0: _cur_file_s = _pc_s.body_file; _layer_key_s = "body"; break;
            case 1: _cur_file_s = _pc_s.face_file; _layer_key_s = "face"; break;
            case 2:
                var _eyes_file_s = "";
                if (_pc_s != undefined && variable_struct_exists(_pc_s, "eyes_files")) {
                    var _ef_s = _pc_s.eyes_files; var _ef_ek = string(expr_cfg_preview_expr);
                    if (variable_struct_exists(_ef_s, _ef_ek) && _ef_s[$ _ef_ek] != "") _eyes_file_s = _ef_s[$ _ef_ek];
                }
                if (_eyes_file_s == "") {
                    var _ai_s = variable_struct_exists(_c_s, "act_index") ? _c_s.act_index : 1;
                    var _sfx_off_s = expr_cfg_high ? 50 : 0;
                    var _pfx_s = string(_ai_s) + string(expr_cfg_pose);
                    var _eyes_n_s = 10 + expr_cfg_preview_expr + _sfx_off_s;
                    _eyes_file_s = "pose_" + _pfx_s + ((_eyes_n_s < 10 ? "0" : "") + string(_eyes_n_s)) + ".png";
                }
                _cur_file_s = _eyes_file_s; _layer_key_s = "eyes"; break;
            case 3:
                var _s_mood_map = [0, 2, 3, 1, 0, 1, 1, 1, 1, 0, 2, 1, 1, 1, 0, 3, 1, 0, 1, 2];
                var _derived_mood_s = _s_mood_map[clamp(expr_cfg_preview_expr - 1, 0, 19)];
                var _mouth_file_s = "";
                if (_pc_s != undefined && variable_struct_exists(_pc_s, "mouth_files")) {
                    var _mf_s = _pc_s.mouth_files;
                    var _expr_key = string(expr_cfg_preview_expr); var _mood_key = string(_derived_mood_s);
                    if (variable_struct_exists(_mf_s, _expr_key) && _mf_s[$ _expr_key] != "") _mouth_file_s = _mf_s[$ _expr_key];
                    else if (variable_struct_exists(_mf_s, _mood_key) && _mf_s[$ _mood_key] != "") _mouth_file_s = _mf_s[$ _mood_key];
                }
                if (_mouth_file_s == "") {
                    var _ai_s = variable_struct_exists(_c_s, "act_index") ? _c_s.act_index : 1;
                    var _sfx_off_s = expr_cfg_high ? 50 : 0;
                    var _pfx_s = string(_ai_s) + string(expr_cfg_pose);
                    var _mouth_n_s = 31 + _derived_mood_s + _sfx_off_s;
                    _mouth_file_s = "pose_" + _pfx_s + ((_mouth_n_s < 10 ? "0" : "") + string(_mouth_n_s)) + ".png";
                }
                _cur_file_s = _mouth_file_s; _layer_key_s = "mouth"; break;
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
    var _drawx_s = _anch_xs - _bdw_s * _cfg_sc_s / 2 + expr_cfg_pan_x;
    var _drawy_s = _anch_ys - _bdh_s * _cfg_sc_s    + expr_cfg_pan_y;

    if (mouse_check_button_pressed(mb_left)) {
        if (_mx > _lx && _mx < _lx + 28 && _my > _nav_y_s && _my < _nav_y_s + 28) {
            expr_cfg_char_idx = (expr_cfg_char_idx - 1 + array_length(characters)) mod array_length(characters);
            open_expr_configurator(expr_cfg_char_idx);
        }
        if (_mx > _lx + 253 && _mx < _lx + 281 && _my > _nav_y_s && _my < _nav_y_s + 28) {
            expr_cfg_char_idx = (expr_cfg_char_idx + 1) mod array_length(characters);
            open_expr_configurator(expr_cfg_char_idx);
        }
        for (var _pi = 1; _pi <= 4; _pi++) {
            var _pbxs = _lx + 45 + (_pi - 1) * 58;
            if (_mx > _pbxs && _mx < _pbxs + 48 && _my > _pose_ys && _my < _pose_ys + 28) expr_cfg_pose = _pi;
        }
        if (_mx > _lx && _mx < _lx + 132 && _my > _dir_ys && _my < _dir_ys + 28) expr_cfg_high = false;
        if (_mx > _lx + 142 && _mx < _lx + 274 && _my > _dir_ys && _my < _dir_ys + 28) expr_cfg_high = true;
        for (var _li = 0; _li <= 3; _li++) {
            var _lbys = _layer_y0_s + _li * 52;
            if (_li == 3 && _mx > _lx + 148 && _mx < _lx + 278 && _my > _lbys + 25 && _my < _lbys + 44 && _pc_s != undefined) {
                var _cur_anch = variable_struct_exists(_pc_s, "mouth_anim_anchor") ? _pc_s.mouth_anim_anchor : 0;
                _pc_s.mouth_anim_anchor = (_cur_anch >= 1) ? 0 : 1;
                ds_map_clear(mouth_anim_cache);
            }
            if (_mx > _lx && _mx < _lx + 280 && _my > _lbys && _my < _lbys + 46) expr_cfg_selected_layer = _li;
        }
        var _ecols_s = 5; var _eboxw_s = 52; var _eboxh_s = 36; var _egap_s = 4;
        for (var _ei = 1; _ei <= 20; _ei++) {
            var _ex3 = _lx + ((_ei - 1) % _ecols_s) * (_eboxw_s + _egap_s);
            var _ey3 = _esel_ys + 18 + floor((_ei - 1) / _ecols_s) * (_eboxh_s + _egap_s);
            if (_mx > _ex3 && _mx < _ex3 + _eboxw_s && _my > _ey3 && _my < _ey3 + _eboxh_s) expr_cfg_preview_expr = _ei;
        }
        var _fb_y_s = _py_s + _char_preview_h_s + 4 + 28;
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
                        _pc_s.eyes_files[$ string(expr_cfg_preview_expr)] = _chosen; break;
                    case 3:
                        if (!variable_struct_exists(_pc_s, "mouth_files")) _pc_s.mouth_files = {};
                        _pc_s.mouth_files[$ string(expr_cfg_preview_expr)] = _chosen; break;
                }
                if (ds_map_exists(char_expr_cache, _c_s.name)) ds_map_delete(char_expr_cache, _c_s.name);
                if (ds_map_exists(mouth_anim_cache, _c_s.name + "_manim_" + _chosen)) ds_map_delete(mouth_anim_cache, _c_s.name + "_manim_" + _chosen);
            }
        }
        if (_mx > _px_s && _mx < _px_s + _pw_s && _my > _py_s && _my < _py_s + _ph_s && _pc_s != undefined) {
            expr_cfg_drag = true;
            expr_cfg_drag_mx0 = _mx; expr_cfg_drag_my0 = _my;
            var _info = get_active_layer_file();
            var _cur_file_s = _info.file; var _layer_key_s = _info.key;
            var _dx_struct_key = _layer_key_s + "_dx_offsets"; var _dy_struct_key = _layer_key_s + "_dy_offsets";
            var _offset_key = _cur_file_s;
            if (_layer_key_s == "eyes" || _layer_key_s == "mouth") {
                _dx_struct_key = _layer_key_s + "_dx_expr_offsets"; _dy_struct_key = _layer_key_s + "_dy_expr_offsets";
                _offset_key = string(expr_cfg_preview_expr);
            }
            if (!variable_struct_exists(_pc_s, _dx_struct_key)) _pc_s[$ _dx_struct_key] = {};
            if (!variable_struct_exists(_pc_s, _dy_struct_key)) _pc_s[$ _dy_struct_key] = {};
            var _dx_map = _pc_s[$ _dx_struct_key]; var _dy_map = _pc_s[$ _dy_struct_key];
            if (!variable_struct_exists(_dx_map, _offset_key)) _dx_map[$ _offset_key] = 0;
            if (!variable_struct_exists(_dy_map, _offset_key)) _dy_map[$ _offset_key] = 0;
            expr_cfg_drag_dx0 = _dx_map[$ _offset_key];
            expr_cfg_drag_dy0 = _dy_map[$ _offset_key];
        }
        var _nom_ys = _esel_ys + 180;
        if (_mx > _lx && _mx < _lx + 280 && _my > _nom_ys && _my < _nom_ys + 28 && _pc_s != undefined) {
            _pc_s.face_over_mouth = !(variable_struct_exists(_pc_s, "face_over_mouth") && _pc_s.face_over_mouth);
            if (ds_map_exists(char_expr_cache, _c_s.name)) ds_map_delete(char_expr_cache, _c_s.name);
        }

        var _btn_ys = _m_y + _m_h - 52; var _btn_w = 50; var _btn_gap = 8;
        if (_mx > _lx && _mx < _lx + _btn_w && _my > _btn_ys && _my < _btn_ys + 40) save_expr_config();
        var _cls_x_new = _lx + _btn_w + _btn_gap;
        if (_mx > _cls_x_new && _mx < _cls_x_new + _btn_w && _my > _btn_ys && _my < _btn_ys + 40) {
            expr_cfg_open = false; expr_cfg_drag = false;
        }
    }

    if (!mouse_check_button(mb_left)) expr_cfg_drag = false;

    if (expr_cfg_drag && mouse_check_button(mb_left) && _pc_s != undefined) {
        var _ddx = round((_mx - expr_cfg_drag_mx0) / _cfg_sc_s);
        var _ddy = round((_my - expr_cfg_drag_my0) / _cfg_sc_s);
        var _info = get_active_layer_file();
        var _cur_file_s = _info.file; var _layer_key_s = _info.key;
        var _dx_struct_key = _layer_key_s + "_dx_offsets"; var _dy_struct_key = _layer_key_s + "_dy_offsets";
        var _offset_key = _cur_file_s;
        if (_layer_key_s == "eyes" || _layer_key_s == "mouth") {
            _dx_struct_key = _layer_key_s + "_dx_expr_offsets"; _dy_struct_key = _layer_key_s + "_dy_expr_offsets";
            _offset_key = string(expr_cfg_preview_expr);
        }
        var _dx_map = _pc_s[$ _dx_struct_key]; var _dy_map = _pc_s[$ _dy_struct_key];
        _dx_map[$ _offset_key] = expr_cfg_drag_dx0 + _ddx;
        _dy_map[$ _offset_key] = expr_cfg_drag_dy0 + _ddy;
        if (ds_map_exists(char_expr_cache, _c_s.name)) ds_map_delete(char_expr_cache, _c_s.name);
    }

    // Middle mouse: drag to pan; click (no movement) to reset zoom + pan
    if (mouse_check_button_pressed(mb_middle)) {
        expr_cfg_pan_drag = true;
        expr_cfg_pan_mx0 = _mx; expr_cfg_pan_my0 = _my;
        expr_cfg_pan_ox  = expr_cfg_pan_x; expr_cfg_pan_oy = expr_cfg_pan_y;
    }
    if (expr_cfg_pan_drag) {
        if (mouse_check_button(mb_middle)) {
            expr_cfg_pan_x = expr_cfg_pan_ox + (_mx - expr_cfg_pan_mx0);
            expr_cfg_pan_y = expr_cfg_pan_oy + (_my - expr_cfg_pan_my0);
        } else {
            if (abs(_mx - expr_cfg_pan_mx0) < 4 && abs(_my - expr_cfg_pan_my0) < 4) {
                expr_cfg_zoom = 1.0; expr_cfg_pan_x = 0; expr_cfg_pan_y = 0;
            }
            expr_cfg_pan_drag = false;
        }
    }

    if (_mx > _px_s && _mx < _px_s + (_m_w - 308)) {
        if (_my < _py_s + _char_preview_h_s) {
            if (mouse_wheel_up())   expr_cfg_zoom = min(expr_cfg_zoom + 0.1, 8.0);
            if (mouse_wheel_down()) expr_cfg_zoom = max(expr_cfg_zoom - 0.1, 0.2);
        } else {
            var _fb_cols_scroll = 3;
            var _fb_total_rows = ceil(array_length(expr_cfg_file_list) / _fb_cols_scroll);
            var _fb_vis_rows_s = floor(floor((_m_h - 20) * 0.42 - 56) / 22);
            if (mouse_wheel_up())   expr_cfg_file_scroll = max(0, expr_cfg_file_scroll - 1);
            if (mouse_wheel_down()) expr_cfg_file_scroll = min(max(0, _fb_total_rows - _fb_vis_rows_s), expr_cfg_file_scroll + 1);
        }
    }

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
                var _cur_file_s = _info.file; var _layer_key_s = _info.key;
                var _dx_struct_key = _layer_key_s + "_dx_offsets"; var _dy_struct_key = _layer_key_s + "_dy_offsets";
                var _offset_key_s = _cur_file_s;
                if (_layer_key_s == "eyes" || _layer_key_s == "mouth") {
                    _dx_struct_key = _layer_key_s + "_dx_expr_offsets"; _dy_struct_key = _layer_key_s + "_dy_expr_offsets";
                    _offset_key_s = string(expr_cfg_preview_expr);
                }
                if (!variable_struct_exists(_pc_s, _dx_struct_key)) _pc_s[$ _dx_struct_key] = {};
                if (!variable_struct_exists(_pc_s, _dy_struct_key)) _pc_s[$ _dy_struct_key] = {};
                var _dx_map = _pc_s[$ _dx_struct_key]; var _dy_map = _pc_s[$ _dy_struct_key];
                if (!variable_struct_exists(_dx_map, _offset_key_s)) _dx_map[$ _offset_key_s] = 0;
                if (!variable_struct_exists(_dy_map, _offset_key_s)) _dy_map[$ _offset_key_s] = 0;
                if (_clicked_axis == 0) _dx_map[$ _offset_key_s] += _clicked_dir;
                else _dy_map[$ _offset_key_s] += _clicked_dir;
                if (ds_map_exists(char_expr_cache, _c_s.name)) ds_map_delete(char_expr_cache, _c_s.name);
            }
        }
    }

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
                if (_rk == vk_up)   _kdy = -1; if (_rk == vk_down)  _kdy = 1;
                var _info = get_active_layer_file();
                var _cur_file_s = _info.file; var _layer_key_s = _info.key;
                var _dx_struct_key = _layer_key_s + "_dx_offsets"; var _dy_struct_key = _layer_key_s + "_dy_offsets";
                var _offset_key_s = _cur_file_s;
                if (_layer_key_s == "eyes" || _layer_key_s == "mouth") {
                    _dx_struct_key = _layer_key_s + "_dx_expr_offsets"; _dy_struct_key = _layer_key_s + "_dy_expr_offsets";
                    _offset_key_s = string(expr_cfg_preview_expr);
                }
                if (!variable_struct_exists(_pc_s, _dx_struct_key)) _pc_s[$ _dx_struct_key] = {};
                if (!variable_struct_exists(_pc_s, _dy_struct_key)) _pc_s[$ _dy_struct_key] = {};
                var _dx_map = _pc_s[$ _dx_struct_key]; var _dy_map = _pc_s[$ _dy_struct_key];
                if (!variable_struct_exists(_dx_map, _offset_key_s)) _dx_map[$ _offset_key_s] = 0;
                if (!variable_struct_exists(_dy_map, _offset_key_s)) _dy_map[$ _offset_key_s] = 0;
                _dx_map[$ _offset_key_s] += _kdx;
                _dy_map[$ _offset_key_s] += _kdy;
                if (ds_map_exists(char_expr_cache, _c_s.name)) ds_map_delete(char_expr_cache, _c_s.name);
            }
        }
    }
}
