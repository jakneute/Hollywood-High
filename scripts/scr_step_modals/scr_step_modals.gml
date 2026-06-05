/// @description Step handlers for all editor modals (dictionary, movement, pose, expression, action).

// ── Animation Editor ─────────────────────────────────────────────────────────

function step_modal_anim_editor() {
    var _mx = mouse_x; var _my = mouse_y;
    var _m_w = 1060; var _m_h = 620;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;

    // Derive layout constants (must match Draw_0)
    var _preview_x = _m_x + 235;
    var _preview_y = _m_y + 55;
    var _preview_w = _m_w - 245;
    var _info_x    = _preview_x + floor(_preview_w * 0.40);
    var _strip_y   = _m_y + _m_h - 145;

    var _data = canned_anim_get_data(anim_editor_char_idx);
    if (_data == undefined) { anim_editor_open = false; return; }

    var _has_anims = (array_length(_data) > 0);
    var _anim   = _has_anims ? _data[clamp(anim_editor_anim_idx, 0, array_length(_data) - 1)] : undefined;
    var _frames = (_anim != undefined) ? _anim.frames : [];

    // Playback tick — sound frames fire immediately, hold only counts on sprite frames
    if (anim_editor_playing) {
        while (anim_editor_frame_idx < array_length(_frames) && _frames[anim_editor_frame_idx].type == "sound") {
            canned_anim_fire_sound(anim_editor_char_idx, _frames[anim_editor_frame_idx]);
            anim_editor_frame_idx++;
            anim_editor_tick = 0;
        }
        if (anim_editor_frame_idx >= array_length(_frames)) anim_editor_frame_idx = 0;
        var _pcf  = (anim_editor_frame_idx < array_length(_frames)) ? _frames[anim_editor_frame_idx] : undefined;
        var _hold = (_pcf != undefined && _pcf.type == "sprite" && variable_struct_exists(_pcf, "hold")) ? _pcf.hold : 1;
        anim_editor_tick++;
        if (anim_editor_tick >= _hold) {
            anim_editor_tick = 0;
            anim_editor_frame_idx++;
            while (anim_editor_frame_idx < array_length(_frames) && _frames[anim_editor_frame_idx].type == "sound") {
                canned_anim_fire_sound(anim_editor_char_idx, _frames[anim_editor_frame_idx]);
                anim_editor_frame_idx++;
            }
            if (anim_editor_frame_idx >= array_length(_frames)) anim_editor_frame_idx = 0;
        }
    }

    // ── SFX picker ────────────────────────────────────────────────────────────
    if (anim_editor_sfx_picker) {
        var _lx = _m_x + 10; var _ly_base = _m_y + 60; var _lh = 28; var _lw = _m_w - 32;
        var _has_back = (anim_editor_sfx_path != "");
        var _total_rows = (_has_back ? 1 : 0) + array_length(anim_editor_sfx_folders) + array_length(anim_editor_sfx_files);
        var _visible_rows = floor((_m_h - 114) / (_lh + 4)); // 60 header + 54 button bar
        var _max_scroll = max(0, _total_rows - _visible_rows);
        anim_editor_sfx_scroll = clamp(anim_editor_sfx_scroll, 0, _max_scroll);
        var _scr = anim_editor_sfx_scroll;

        // Scrollbar geometry (must match Draw_0)
        var _sbx_fx = _m_x + _m_w - 16; var _sby_fx = _m_y + 60;
        var _sbh_fx = _m_h - 110;
        var _thumb_h_fx = (_total_rows > 0) ? max(20, _sbh_fx * _visible_rows / _total_rows) : _sbh_fx;
        var _thumb_y_fx = _sby_fx + (_max_scroll > 0 ? (anim_editor_sfx_scroll / _max_scroll) * (_sbh_fx - _thumb_h_fx) : 0);

        // Scrollbar drag (runs every frame while held)
        if (mouse_check_button(mb_left) && anim_editor_sfx_sb_drag) {
            if (_max_scroll > 0 && _sbh_fx - _thumb_h_fx > 0) {
                var _raw_fx = clamp(_my - anim_editor_sfx_sb_drag_off - _sby_fx, 0, _sbh_fx - _thumb_h_fx);
                anim_editor_sfx_scroll = clamp(round(_raw_fx / (_sbh_fx - _thumb_h_fx) * _max_scroll), 0, _max_scroll);
            }
            return;
        }
        if (!mouse_check_button(mb_left)) anim_editor_sfx_sb_drag = false;

        // Bottom bar: OK and Cancel buttons
        var _btn_y = _m_y + _m_h - 44; var _btn_h = 32;
        var _ok_x  = _m_x + _m_w - 220; var _ok_w  = 90;
        var _cx    = _m_x + _m_w - 120; var _cw    = 90;

        if (mouse_check_button_pressed(mb_left)) {
            // Start scrollbar drag
            if (_max_scroll > 0 && _mx > _sbx_fx && _mx < _sbx_fx + 10 && _my > _thumb_y_fx && _my < _thumb_y_fx + _thumb_h_fx) {
                anim_editor_sfx_sb_drag = true;
                anim_editor_sfx_sb_drag_off = _my - _thumb_y_fx;
                return;
            }
            // OK — confirm pending selection
            if (anim_editor_sfx_pending != "" && _mx > _ok_x && _mx < _ok_x + _ok_w && _my > _btn_y && _my < _btn_y + _btn_h) {
                if (anim_editor_sfx_insert_mode) {
                    var _ins_idx = clamp(anim_editor_selected_frame + (anim_editor_sfx_insert_after ? 1 : 0), 0, array_length(_frames));
                    var _new_sfx = { type: "sound", file: anim_editor_sfx_pending, "_sound_id": 0 };
                    array_insert(_frames, _ins_idx, _new_sfx);
                    anim_editor_selected_frame = _ins_idx;
                    anim_editor_dirty = true;
                } else {
                    if (anim_editor_selected_frame >= 0 && anim_editor_selected_frame < array_length(_frames)) {
                        _frames[anim_editor_selected_frame].file = anim_editor_sfx_pending;
                        anim_editor_dirty = true;
                    }
                }
                anim_editor_sfx_insert_mode = false;
                anim_editor_sfx_pending = ""; anim_editor_sfx_picker = false; return;
            }
            // Cancel
            if (_mx > _cx && _mx < _cx + _cw && _my > _btn_y && _my < _btn_y + _btn_h) {
                anim_editor_sfx_insert_mode = false;
                anim_editor_sfx_pending = ""; anim_editor_sfx_picker = false; return;
            }

            var _r = 0;
            // Back button
            if (_has_back) {
                var _sy = _ly_base + (_r - _scr) * (_lh + 4);
                if (_sy >= _ly_base && _sy + _lh <= _m_y + _m_h - 54) {
                    if (_mx > _lx && _mx < _lx + _lw && _my > _sy && _my < _sy + _lh) {
                        var _sep = string_last_pos("/", anim_editor_sfx_path);
                        anim_editor_sfx_path = (_sep > 0) ? string_copy(anim_editor_sfx_path, 1, _sep - 1) : "";
                        anim_editor_sfx_pending = "";
                        _anim_sfx_refresh(); return;
                    }
                }
                _r++;
            }
            // Folders
            for (var _fi = 0; _fi < array_length(anim_editor_sfx_folders); _fi++) {
                var _sy = _ly_base + (_r - _scr) * (_lh + 4);
                if (_sy >= _ly_base && _sy + _lh <= _m_y + _m_h - 54) {
                    if (_mx > _lx && _mx < _lx + _lw && _my > _sy && _my < _sy + _lh) {
                        anim_editor_sfx_path = (anim_editor_sfx_path == "") ? anim_editor_sfx_folders[_fi] : (anim_editor_sfx_path + "/" + anim_editor_sfx_folders[_fi]);
                        anim_editor_sfx_pending = "";
                        _anim_sfx_refresh(); return;
                    }
                }
                _r++;
            }
            // WAV files — click plays and sets pending
            for (var _wfi = 0; _wfi < array_length(anim_editor_sfx_files); _wfi++) {
                var _sy = _ly_base + (_r - _scr) * (_lh + 4);
                if (_sy >= _ly_base && _sy + _lh <= _m_y + _m_h - 54) {
                    if (_mx > _lx && _mx < _lx + _lw && _my > _sy && _my < _sy + _lh) {
                        var _rel = (anim_editor_sfx_path == "") ? anim_editor_sfx_files[_wfi] : (anim_editor_sfx_path + "/" + anim_editor_sfx_files[_wfi]);
                        play_sfx_preview(anim_editor_sfx_path, anim_editor_sfx_files[_wfi]);
                        anim_editor_sfx_pending = _rel;
                        return;
                    }
                }
                _r++;
            }
            // Click outside list (but not buttons) closes picker
            if (_my < _btn_y) { anim_editor_sfx_pending = ""; anim_editor_sfx_picker = false; }
        }
        if (mouse_wheel_up())   anim_editor_sfx_scroll = max(0, anim_editor_sfx_scroll - 1);
        if (mouse_wheel_down()) anim_editor_sfx_scroll = min(_max_scroll, anim_editor_sfx_scroll + 1);
        return;
    }

    // ── Sprite picker ─────────────────────────────────────────────────────────
    if (anim_editor_sprite_picker) {
        var _cols = 4; var _th = 160;
        var _gy = _m_y + 60;
        var _vis_rows = floor((_m_h - 114) / _th); // 60px header + 54px button bar, matches draw
        var _total_spr_rows = ceil(array_length(anim_editor_sprite_list) / _cols);
        var _max_spr = max(0, _total_spr_rows - _vis_rows);
        var _sbx_s = _m_x + _m_w - 16; var _sby_s = _gy;
        var _sbh_s = _vis_rows * _th;
        var _thumb_h_s = (_total_spr_rows > 0) ? max(20, _sbh_s * _vis_rows / _total_spr_rows) : _sbh_s;
        var _thumb_y_s = _sby_s + (_max_spr > 0 ? (anim_editor_sprite_scroll / _max_spr) * (_sbh_s - _thumb_h_s) : 0);

        // Scrollbar drag (runs every frame while held)
        if (mouse_check_button(mb_left) && anim_editor_sprite_sb_drag) {
            if (_max_spr > 0 && _sbh_s - _thumb_h_s > 0) {
                var _raw = clamp(_my - anim_editor_sprite_sb_drag_off - _sby_s, 0, _sbh_s - _thumb_h_s);
                anim_editor_sprite_scroll = round(_raw / (_sbh_s - _thumb_h_s) * _max_spr);
            }
            anim_editor_sprite_scroll = clamp(anim_editor_sprite_scroll, 0, _max_spr);
            return;
        }
        if (!mouse_check_button(mb_left)) anim_editor_sprite_sb_drag = false;

        var _sp_btn_y = _m_y + _m_h - 44; var _sp_btn_h = 32;
        var _sp_ok_x  = _m_x + _m_w - 220; var _sp_ok_w  = 90;
        var _sp_cx    = _m_x + _m_w - 120; var _sp_cw    = 90;

        if (mouse_check_button_pressed(mb_left)) {
            // OK — confirm pending sprite
            if (anim_editor_sprite_pending != "" && _mx > _sp_ok_x && _mx < _sp_ok_x + _sp_ok_w && _my > _sp_btn_y && _my < _sp_btn_y + _sp_btn_h) {
                if (anim_editor_sprite_picker_mode == 1) {
                    // Animation-level feet sprite (normal or flipped)
                    var _fk = anim_editor_flipped_mode ? "feet_sprite_flipped" : "feet_sprite";
                    _anim[$ _fk] = anim_editor_sprite_pending;
                    anim_editor_dirty = true;
                    anim_editor_sprite_pending = ""; anim_editor_sprite_picker = false;
                    anim_editor_sprite_picker_mode = 0; return;
                }
                if (anim_editor_selected_frame >= 0 && anim_editor_selected_frame < array_length(_frames)) {
                    if (anim_editor_flipped_mode) {
                        _frames[anim_editor_selected_frame].sprite_flipped = anim_editor_sprite_pending;
                    } else {
                        _frames[anim_editor_selected_frame].sprite = anim_editor_sprite_pending;
                        var _c2  = characters[anim_editor_char_idx];
                        var _nm2 = variable_struct_exists(_c2, "sprite_name") ? _c2.sprite_name : _c2.name;
                        ds_map_delete(char_sprites, "CANNED_" + _nm2 + "_" + anim_editor_sprite_pending);
                    }
                    anim_editor_dirty = true;
                }
                anim_editor_sprite_pending = ""; anim_editor_sprite_picker = false;
                anim_editor_sprite_picker_mode = 0; return;
            }
            // Cancel
            if (_mx > _sp_cx && _mx < _sp_cx + _sp_cw && _my > _sp_btn_y && _my < _sp_btn_y + _sp_btn_h) {
                anim_editor_sprite_pending = ""; anim_editor_sprite_picker = false; anim_editor_sprite_picker_mode = 0; return;
            }
            // Start scrollbar drag
            if (_max_spr > 0 && _mx > _sbx_s && _mx < _sbx_s + 10 && _my > _thumb_y_s && _my < _thumb_y_s + _thumb_h_s) {
                anim_editor_sprite_sb_drag = true;
                anim_editor_sprite_sb_drag_off = _my - _thumb_y_s;
                return;
            }
            var _gx = _m_x + 10;
            var _start = anim_editor_sprite_scroll * _cols;
            for (var _pi = 0; _pi < array_length(anim_editor_sprite_list); _pi++) {
                var _pidx = _pi - _start;
                if (_pidx < 0 || _pidx >= _cols * _vis_rows) continue;
                var _pr = floor(_pidx / _cols); var _pc = _pidx mod _cols;
                var _px = _gx + _pc * 200; var _py = _gy + _pr * _th;
                if (_mx > _px && _mx < _px + 196 && _my > _py && _my < _py + _th - 4) {
                    anim_editor_sprite_pending = anim_editor_sprite_list[_pi]; return;
                }
            }
            if (_my < _sp_btn_y) { anim_editor_sprite_pending = ""; anim_editor_sprite_picker = false; anim_editor_sprite_picker_mode = 0; }
        }

        if (mouse_wheel_up())   anim_editor_sprite_scroll = max(0, anim_editor_sprite_scroll - 1);
        if (mouse_wheel_down()) anim_editor_sprite_scroll = min(_max_spr, anim_editor_sprite_scroll + 1);

        // PgUp/PgDn hold-to-repeat; Home/End instant
        var _pgd = keyboard_check(vk_pagedown); var _pgu = keyboard_check(vk_pageup);
        var _pgdir = _pgd ? 1 : (_pgu ? -1 : 0);
        if (_pgdir != 0) {
            if (_pgdir != anim_editor_pgud_dir) { anim_editor_pgud_dir = _pgdir; anim_editor_pgud_timer = 0; }
            anim_editor_pgud_timer++;
            if (anim_editor_pgud_timer == 1 || (anim_editor_pgud_timer > 20 && (anim_editor_pgud_timer - 20) mod 6 == 0))
                anim_editor_sprite_scroll = clamp(anim_editor_sprite_scroll + _pgdir * _vis_rows, 0, _max_spr);
        } else {
            anim_editor_pgud_dir = 0; anim_editor_pgud_timer = 0;
        }
        if (keyboard_check_pressed(vk_home)) anim_editor_sprite_scroll = 0;
        if (keyboard_check_pressed(vk_end))  anim_editor_sprite_scroll = _max_spr;
        anim_editor_sprite_scroll = clamp(anim_editor_sprite_scroll, 0, _max_spr);
        return;
    }

    // ── Main editor clicks ────────────────────────────────────────────────────
    if (mouse_check_button_pressed(mb_left)) {
        // Close — discard unsaved changes, evict cache so next open reloads from disk
        if (_mx > _m_x + _m_w - 50 && _mx < _m_x + _m_w - 10 && _my > _m_y + 10 && _my < _m_y + 40) {
            if (anim_editor_dirty) {
                var _cc = characters[anim_editor_char_idx];
                var _cn = variable_struct_exists(_cc, "sprite_name") ? _cc.sprite_name : _cc.name;
                ds_map_delete(char_anim_cache, _cn);
            }
            anim_editor_open = false; anim_editor_playing = false; anim_editor_dirty = false; return;
        }
        // Save button — save without closing
        if (_mx > _m_x + 460 && _mx < _m_x + 560 && _my > _m_y + 20 && _my < _m_y + 48) {
            canned_anim_save(anim_editor_char_idx); anim_editor_dirty = false; return;
        }
        // Flip mode toggle
        if (_mx > _m_x + 572 && _mx < _m_x + 642 && _my > _m_y + 20 && _my < _m_y + 48) {
            anim_editor_flipped_mode = !anim_editor_flipped_mode; return;
        }
        // Copy to flipped — next to FLIP button, normal mode only
        if (!anim_editor_flipped_mode && _mx > _m_x + 650 && _mx < _m_x + 790 && _my > _m_y + 20 && _my < _m_y + 48) {
            for (var _cfi4 = 0; _cfi4 < array_length(_frames); _cfi4++) {
                if (_frames[_cfi4].type == "sprite") {
                    _frames[_cfi4].sprite_flipped = canned_anim_flipped_name(_frames[_cfi4].sprite);
                }
            }
            anim_editor_dirty = true; return;
        }
        // Animation list
        for (var i = 0; i < array_length(_data); i++) {
            var _lyl = _m_y + 60 + i * 30;
            if (_mx > _m_x + 10 && _mx < _m_x + 220 && _my > _lyl && _my < _lyl + 28) {
                anim_editor_anim_idx = i; anim_editor_frame_idx = 0;
                anim_editor_selected_frame = -1; anim_editor_tick = 0; anim_editor_playing = false;
                return;
            }
        }
        // +ANIM button
        var _add_anim_y = _m_y + 60 + array_length(_data) * 30;
        if (_mx > _m_x + 10 && _mx < _m_x + 220 && _my > _add_anim_y && _my < _add_anim_y + 26) {
            var _new_anim = { name: "new animation", triggers: [], frames: [] };
            array_push(_data, _new_anim);
            anim_editor_anim_idx = array_length(_data) - 1;
            anim_editor_frame_idx = 0; anim_editor_selected_frame = -1;
            anim_editor_playing = false; anim_editor_dirty = true; return;
        }
        // Play / Pause
        if (array_length(_frames) > 0 && _mx > _m_x + 230 && _mx < _m_x + 330 && _my > _m_y + 20 && _my < _m_y + 48) {
            anim_editor_playing = !anim_editor_playing; anim_editor_tick = 0; return;
        }
        // Prev frame
        if (_mx > _m_x + 340 && _mx < _m_x + 390 && _my > _m_y + 20 && _my < _m_y + 48) {
            anim_editor_playing = false;
            do { anim_editor_frame_idx = (anim_editor_frame_idx - 1 + array_length(_frames)) mod array_length(_frames); }
            until (_frames[anim_editor_frame_idx].type == "sprite" || anim_editor_frame_idx == 0);
            return;
        }
        // Next frame
        if (array_length(_frames) > 0 && _mx > _m_x + 400 && _mx < _m_x + 450 && _my > _m_y + 20 && _my < _m_y + 48) {
            anim_editor_playing = false;
            do { anim_editor_frame_idx = (anim_editor_frame_idx + 1) mod array_length(_frames); }
            until (_frames[anim_editor_frame_idx].type == "sprite" || anim_editor_frame_idx == 0);
            return;
        }

        // Frame strip — scroll arrows and frame selection
        var _strip_fw = 54; var _arr_w = 28;
        var _sx_base = _preview_x + 4 + _arr_w;
        var _strip_inner_w = _preview_w - _arr_w * 2 - 8;
        var _vis_s = floor(_strip_inner_w / _strip_fw);
        var _max_ss = max(0, array_length(_frames) - _vis_s);
        anim_editor_strip_scroll = clamp(anim_editor_strip_scroll, 0, _max_ss);
        var _s_start = anim_editor_strip_scroll;
        // Left arrow
        if (_mx > _preview_x + 4 && _mx < _preview_x + 4 + _arr_w && _my > _strip_y + 2 && _my < _strip_y + 66) {
            anim_editor_strip_scroll = max(0, anim_editor_strip_scroll - 1); return;
        }
        // Right arrow
        var _rarr_x = _sx_base + _vis_s * _strip_fw + 4;
        if (_mx > _rarr_x && _mx < _rarr_x + _arr_w && _my > _strip_y + 2 && _my < _strip_y + 66) {
            anim_editor_strip_scroll = min(_max_ss, anim_editor_strip_scroll + 1); return;
        }
        for (var _si = _s_start; _si < min(array_length(_frames), _s_start + _vis_s); _si++) {
            var _ssx = _sx_base + (_si - _s_start) * _strip_fw;
            if (_mx > _ssx && _mx < _ssx + _strip_fw - 2 && _my > _strip_y + 2 && _my < _strip_y + 66) {
                anim_editor_playing = false; anim_editor_frame_idx = _si; anim_editor_selected_frame = _si; return;
            }
        }

        // ── Animation-level FEET buttons ──
        if (_anim != undefined)
        {
            var _feet_key = anim_editor_flipped_mode ? "feet_sprite_flipped" : "feet_sprite";
            var _anim_fs2 = variable_struct_exists(_anim, _feet_key) ? _anim[$ _feet_key] : "";
            // SET
            if (_mx > _info_x && _mx < _info_x + 54 && _my > _preview_y + 50 && _my < _preview_y + 68) {
                anim_editor_sprite_picker_mode = 1;
                anim_editor_sprite_list = canned_anim_sprite_list(anim_editor_char_idx);
                anim_editor_sprite_scroll = 0;
                var _fp_found = false;
                if (_anim_fs2 != "") {
                    for (var _fli = 0; _fli < array_length(anim_editor_sprite_list); _fli++) {
                        if (anim_editor_sprite_list[_fli] == _anim_fs2) {
                            var _cols_fp = 4; var _vis_fp = floor((_m_h - 80) / 160);
                            anim_editor_sprite_scroll = max(0, floor(_fli / _cols_fp) - floor(_vis_fp / 2));
                            _fp_found = true; break;
                        }
                    }
                }
                if (!_fp_found) {
                    var _fp_cb = anim_editor_pose_clipboard;
                    if (_fp_cb != "") {
                        for (var _fli = 0; _fli < array_length(anim_editor_sprite_list); _fli++) {
                            if (anim_editor_sprite_list[_fli] == _fp_cb) {
                                var _cols_fp = 4; var _vis_fp = floor((_m_h - 80) / 160);
                                anim_editor_sprite_scroll = max(0, floor(_fli / _cols_fp) - floor(_vis_fp / 2));
                                _fp_found = true; break;
                            }
                        }
                    }
                    if (!_fp_found) {
                        for (var _fli = 0; _fli < array_length(anim_editor_sprite_list); _fli++) {
                            var _fp_name = anim_editor_sprite_list[_fli];
                            var _fp_upos = string_pos("_", _fp_name);
                            var _fp_num = real(string_copy(_fp_name, _fp_upos + 1, string_length(_fp_name) - _fp_upos - 4));
                            if ((_fp_num mod 1000) >= 500) {
                                var _cols_fp = 4;
                                anim_editor_sprite_scroll = floor(_fli / _cols_fp);
                                break;
                            }
                        }
                    }
                }
                anim_editor_sprite_picker = true; return;
            }
            // CLR
            if (_mx > _info_x + 60 && _mx < _info_x + 114 && _my > _preview_y + 50 && _my < _preview_y + 68) {
                _anim[$ _feet_key] = ""; anim_editor_dirty = true; return;
            }
            // Body Y offset stepper (normal mode only — same row, right of CLR)
            if (!anim_editor_flipped_mode) {
                var _cur_bdy = variable_struct_exists(_anim, "body_dy") ? _anim.body_dy : 0;
                if (_mx > _info_x + 152 && _mx < _info_x + 174 && _my > _preview_y + 50 && _my < _preview_y + 68) {
                    _anim.body_dy = _cur_bdy - 1; anim_editor_dirty = true; return;
                }
                if (_mx > _info_x + 178 && _mx < _info_x + 200 && _my > _preview_y + 50 && _my < _preview_y + 68) {
                    _anim.body_dy = _cur_bdy + 1; anim_editor_dirty = true; return;
                }
            }
        }

        // Edit controls — use selected_frame if set, otherwise fall back to current viewing frame
        var _edit_idx = (anim_editor_selected_frame >= 0 && anim_editor_selected_frame < array_length(_frames))
                        ? anim_editor_selected_frame : anim_editor_frame_idx;
        if (_edit_idx >= 0 && _edit_idx < array_length(_frames)) {
            var _sf2 = _frames[_edit_idx];

            if (_sf2.type == "sprite") {
                // Hold -
                if (_mx > _info_x + 100 && _mx < _info_x + 126 && _my > _preview_y + 98 && _my < _preview_y + 116) {
                    _sf2.hold = max(1, _sf2.hold - 1); anim_editor_dirty = true; return;
                }
                // Hold +
                if (_mx > _info_x + 132 && _mx < _info_x + 158 && _my > _preview_y + 98 && _my < _preview_y + 116) {
                    _sf2.hold++; anim_editor_dirty = true; return;
                }
                // Apply hold to all sprite frames
                if (_mx > _info_x + 164 && _mx < _info_x + 232 && _my > _preview_y + 98 && _my < _preview_y + 116) {
                    for (var _afi = 0; _afi < array_length(_frames); _afi++) {
                        if (_frames[_afi].type == "sprite") _frames[_afi].hold = _sf2.hold;
                    }
                    anim_editor_dirty = true; return;
                }
                // Copy pose to clipboard
                if (_mx > _info_x + 168 && _mx < _info_x + 248 && _my > _preview_y + 168 && _my < _preview_y + 190) {
                    anim_editor_pose_clipboard = _sf2.sprite; return;
                }
                // Change sprite / change flipped sprite
                if (_mx > _info_x && _mx < _info_x + 160 && _my > _preview_y + 168 && _my < _preview_y + 190) {
                    anim_editor_selected_frame = _edit_idx;
                    anim_editor_sprite_picker_mode = 0;
                    anim_editor_sprite_list = canned_anim_sprite_list(anim_editor_char_idx);
                    anim_editor_sprite_scroll = 0;
                    var _cur_spr = anim_editor_flipped_mode
                        ? (variable_struct_exists(_sf2, "sprite_flipped") ? _sf2.sprite_flipped : "")
                        : (variable_struct_exists(_sf2, "sprite") ? _sf2.sprite : "");
                    var _sp_found = false;
                    if (_cur_spr != "") {
                        for (var _sli = 0; _sli < array_length(anim_editor_sprite_list); _sli++) {
                            if (anim_editor_sprite_list[_sli] == _cur_spr) {
                                var _cols_sp = 4; var _vis_sp = floor((_m_h - 80) / 160);
                                var _row_sp  = floor(_sli / _cols_sp);
                                anim_editor_sprite_scroll = max(0, _row_sp - floor(_vis_sp / 2));
                                _sp_found = true; break;
                            }
                        }
                    }
                    if (!_sp_found) {
                        var _sp_cb = anim_editor_pose_clipboard;
                        if (_sp_cb != "") {
                            for (var _sli = 0; _sli < array_length(anim_editor_sprite_list); _sli++) {
                                if (anim_editor_sprite_list[_sli] == _sp_cb) {
                                    var _cols_sp = 4; var _vis_sp = floor((_m_h - 80) / 160);
                                    anim_editor_sprite_scroll = max(0, floor(_sli / _cols_sp) - floor(_vis_sp / 2));
                                    _sp_found = true; break;
                                }
                            }
                        }
                        if (!_sp_found) {
                            for (var _sli = 0; _sli < array_length(anim_editor_sprite_list); _sli++) {
                                var _sp_name = anim_editor_sprite_list[_sli];
                                var _sp_upos = string_pos("_", _sp_name);
                                var _sp_num = real(string_copy(_sp_name, _sp_upos + 1, string_length(_sp_name) - _sp_upos - 4));
                                if ((_sp_num mod 1000) >= 500) {
                                    var _cols_sp = 4;
                                    anim_editor_sprite_scroll = floor(_sli / _cols_sp);
                                    break;
                                }
                            }
                        }
                    }
                    anim_editor_sprite_picker = true; return;
                }
            }

            if (_sf2.type == "sprite") {
                // Per-frame offset steppers (when any feet sprite assigned and composite_legs)
                var _has_feet_sf2 = (_anim != undefined && (
                    (variable_struct_exists(_anim, "feet_sprite") && _anim.feet_sprite != "") ||
                    (variable_struct_exists(_anim, "feet_sprite_flipped") && _anim.feet_sprite_flipped != "")
                ));
                var _is_comp_sf2  = variable_struct_exists(_sf2, "composite_legs") && _sf2.composite_legs;
                if (_has_feet_sf2 && _is_comp_sf2) {
                    var _fdy_key2 = anim_editor_flipped_mode ? "frame_dy_flipped" : "frame_dy";
                    var _fdx_key2 = anim_editor_flipped_mode ? "frame_dx_flipped" : "frame_dx";
                    // CLR flipped override (label row: _preview_y+116 to _preview_y+130)
                    if (anim_editor_flipped_mode && _mx > _info_x + 138 && _mx < _info_x + 168 && _my > _preview_y + 116 && _my < _preview_y + 130) {
                        variable_struct_remove(_sf2, "frame_dy_flipped");
                        variable_struct_remove(_sf2, "frame_dx_flipped");
                        anim_editor_dirty = true; return;
                    }
                    // Y - (row1: _preview_y+122 to _preview_y+140)
                    if (_mx > _info_x + 74 && _mx < _info_x + 100 && _my > _preview_y + 122 && _my < _preview_y + 140) {
                        _sf2[$ _fdy_key2] = (variable_struct_exists(_sf2, _fdy_key2) ? _sf2[$ _fdy_key2] : 0) - 1;
                        anim_editor_dirty = true; return;
                    }
                    // Y +
                    if (_mx > _info_x + 104 && _mx < _info_x + 130 && _my > _preview_y + 122 && _my < _preview_y + 140) {
                        _sf2[$ _fdy_key2] = (variable_struct_exists(_sf2, _fdy_key2) ? _sf2[$ _fdy_key2] : 0) + 1;
                        anim_editor_dirty = true; return;
                    }
                    // X - (row2: _preview_y+142 to _preview_y+160)
                    if (_mx > _info_x + 74 && _mx < _info_x + 100 && _my > _preview_y + 142 && _my < _preview_y + 160) {
                        _sf2[$ _fdx_key2] = (variable_struct_exists(_sf2, _fdx_key2) ? _sf2[$ _fdx_key2] : 0) - 1;
                        anim_editor_dirty = true; return;
                    }
                    // X +
                    if (_mx > _info_x + 104 && _mx < _info_x + 130 && _my > _preview_y + 142 && _my < _preview_y + 160) {
                        _sf2[$ _fdx_key2] = (variable_struct_exists(_sf2, _fdx_key2) ? _sf2[$ _fdx_key2] : 0) + 1;
                        anim_editor_dirty = true; return;
                    }
                }
            }

            if (_sf2.type == "sound") {
                // Change SFX button
                if (_mx > _info_x && _mx < _info_x + 160 && _my > _preview_y + 168 && _my < _preview_y + 190) {
                    anim_editor_selected_frame = _edit_idx;
                    var _sc  = characters[anim_editor_char_idx];
                    var _snm = variable_struct_exists(_sc, "sprite_name") ? _sc.sprite_name : _sc.name;
                    anim_editor_sfx_root   = "";
                    anim_editor_sfx_path   = "Actors - " + _snm;
                    anim_editor_sfx_scroll = 0;
                    anim_editor_sfx_insert_mode = false;
                    _anim_sfx_refresh();
                    anim_editor_sfx_picker = true; return;
                }
                // DEL button — remove this sound frame
                if (_mx > _info_x + 168 && _mx < _info_x + 228 && _my > _preview_y + 168 && _my < _preview_y + 190) {
                    array_delete(_frames, _edit_idx, 1);
                    anim_editor_selected_frame = -1;
                    anim_editor_dirty = true; return;
                }
            }
        }

        // ── Unified bottom row: +SFX, +SPRITE, DEL — always active when anim selected ──
        if (_has_anims && _anim != undefined) {
            var _btn_y = _preview_y + 200;
            var _edit_idx2 = (anim_editor_selected_frame >= 0 && anim_editor_selected_frame < array_length(_frames))
                             ? anim_editor_selected_frame : anim_editor_frame_idx;
            var _has_sel = (_edit_idx2 >= 0 && _edit_idx2 < array_length(_frames));
            var _sf3 = _has_sel ? _frames[_edit_idx2] : undefined;

            // +SFX — insert after selection (or append if empty)
            if (_mx > _info_x && _mx < _info_x + 80 && _my > _btn_y && _my < _btn_y + 22) {
                var _sc5 = characters[anim_editor_char_idx];
                var _snm5 = variable_struct_exists(_sc5, "sprite_name") ? _sc5.sprite_name : _sc5.name;
                anim_editor_sfx_root   = "";
                anim_editor_sfx_path   = "Actors - " + _snm5;
                anim_editor_sfx_scroll = 0;
                anim_editor_sfx_insert_mode  = true;
                anim_editor_sfx_insert_after = true;
                anim_editor_selected_frame   = _has_sel ? _edit_idx2 : -1;
                _anim_sfx_refresh();
                anim_editor_sfx_picker = true; return;
            }
            // +SPRITE — duplicate selection and insert after, or append blank if empty
            if (_mx > _info_x + 88 && _mx < _info_x + 168 && _my > _btn_y && _my < _btn_y + 22) {
                var _new_sp2 = { type: "sprite", sprite: (_sf3 != undefined && _sf3.type == "sprite") ? _sf3.sprite : "", composite_legs: true, hold: (_sf3 != undefined && _sf3.type == "sprite") ? _sf3.hold : 10 };
                var _ins2 = _has_sel ? _edit_idx2 + 1 : array_length(_frames);
                array_insert(_frames, _ins2, _new_sp2);
                anim_editor_selected_frame = _ins2;
                anim_editor_dirty = true; return;
            }
            // DEL — remove selected frame (sprite or sound)
            if (_has_sel && _mx > _info_x + 176 && _mx < _info_x + 236 && _my > _btn_y && _my < _btn_y + 22) {
                array_delete(_frames, _edit_idx2, 1);
                anim_editor_selected_frame = -1;
                anim_editor_dirty = true; return;
            }
        }
    }

    // Click-and-hold repeat for hold +/- and per-frame offset +/-
    if (mouse_check_button(mb_left) && !anim_editor_sprite_picker && !anim_editor_sfx_picker) {
        var _ei2 = (anim_editor_selected_frame >= 0 && anim_editor_selected_frame < array_length(_frames))
                   ? anim_editor_selected_frame : anim_editor_frame_idx;
        if (_ei2 >= 0 && _ei2 < array_length(_frames) && _frames[_ei2].type == "sprite") {
            var _hi = _info_x; var _py2 = _preview_y;
            var _on_minus   = (_mx > _hi + 100 && _mx < _hi + 126 && _my > _py2 + 98  && _my < _py2 + 116);
            var _on_plus    = (_mx > _hi + 132 && _mx < _hi + 158 && _my > _py2 + 98  && _my < _py2 + 116);
            var _on_fdy_min = (_mx > _hi + 74  && _mx < _hi + 100 && _my > _py2 + 122 && _my < _py2 + 140);
            var _on_fdy_pls = (_mx > _hi + 104 && _mx < _hi + 130 && _my > _py2 + 122 && _my < _py2 + 140);
            var _on_fdx_min = (_mx > _hi + 74  && _mx < _hi + 100 && _my > _py2 + 142 && _my < _py2 + 160);
            var _on_fdx_pls = (_mx > _hi + 104 && _mx < _hi + 130 && _my > _py2 + 142 && _my < _py2 + 160);
            if (_on_minus || _on_plus || _on_fdy_min || _on_fdy_pls || _on_fdx_min || _on_fdx_pls) {
                if (_on_minus)        anim_editor_hold_btn = 1;
                else if (_on_plus)    anim_editor_hold_btn = 2;
                else if (_on_fdy_min) anim_editor_hold_btn = 3;
                else if (_on_fdy_pls) anim_editor_hold_btn = 4;
                else if (_on_fdx_min) anim_editor_hold_btn = 5;
                else                  anim_editor_hold_btn = 6;
                anim_editor_hold_repeat++;
                // Wait 30 frames before repeating, then fire every 4 frames
                var _hr_fdy_k = anim_editor_flipped_mode ? "frame_dy_flipped" : "frame_dy";
                var _hr_fdx_k = anim_editor_flipped_mode ? "frame_dx_flipped" : "frame_dx";
                if (anim_editor_hold_repeat >= 30 && anim_editor_hold_repeat mod 4 == 0) {
                    if (anim_editor_hold_btn == 1) { _frames[_ei2].hold = max(1, _frames[_ei2].hold - 1); anim_editor_dirty = true; }
                    if (anim_editor_hold_btn == 2) { _frames[_ei2].hold++;                                anim_editor_dirty = true; }
                    if (anim_editor_hold_btn == 3) { _frames[_ei2][$ _hr_fdy_k] = (variable_struct_exists(_frames[_ei2], _hr_fdy_k) ? _frames[_ei2][$ _hr_fdy_k] : 0) - 1; anim_editor_dirty = true; }
                    if (anim_editor_hold_btn == 4) { _frames[_ei2][$ _hr_fdy_k] = (variable_struct_exists(_frames[_ei2], _hr_fdy_k) ? _frames[_ei2][$ _hr_fdy_k] : 0) + 1; anim_editor_dirty = true; }
                    if (anim_editor_hold_btn == 5) { _frames[_ei2][$ _hr_fdx_k] = (variable_struct_exists(_frames[_ei2], _hr_fdx_k) ? _frames[_ei2][$ _hr_fdx_k] : 0) - 1; anim_editor_dirty = true; }
                    if (anim_editor_hold_btn == 6) { _frames[_ei2][$ _hr_fdx_k] = (variable_struct_exists(_frames[_ei2], _hr_fdx_k) ? _frames[_ei2][$ _hr_fdx_k] : 0) + 1; anim_editor_dirty = true; }
                }
            } else {
                anim_editor_hold_btn = 0; anim_editor_hold_repeat = 0;
            }
        }
    } else {
        anim_editor_hold_btn = 0; anim_editor_hold_repeat = 0;
    }

    if (mouse_wheel_up()   && !anim_editor_sprite_picker && !anim_editor_sfx_picker) anim_editor_sprite_scroll = max(0, anim_editor_sprite_scroll - 1);
    if (mouse_wheel_down() && !anim_editor_sprite_picker && !anim_editor_sfx_picker) anim_editor_sprite_scroll++;

    // Arrow keys scroll the strip (and move selection) when a frame is selected
    if (!anim_editor_sprite_picker && !anim_editor_sfx_picker && anim_editor_selected_frame >= 0) {
        var _nf = array_length(_frames);
        if (keyboard_check_pressed(vk_left) && anim_editor_selected_frame > 0) {
            anim_editor_selected_frame--;
            anim_editor_frame_idx = anim_editor_selected_frame;
            // Scroll view to keep selection visible
            var _arr_w2 = 28; var _strip_inner_w2 = _preview_w - _arr_w2 * 2 - 8; var _vis_s2 = floor(_strip_inner_w2 / 54);
            if (anim_editor_selected_frame < anim_editor_strip_scroll)
                anim_editor_strip_scroll = anim_editor_selected_frame;
        }
        if (keyboard_check_pressed(vk_right) && anim_editor_selected_frame < _nf - 1) {
            anim_editor_selected_frame++;
            anim_editor_frame_idx = anim_editor_selected_frame;
            var _arr_w2 = 28; var _strip_inner_w2 = _preview_w - _arr_w2 * 2 - 8; var _vis_s2 = floor(_strip_inner_w2 / 54);
            if (anim_editor_selected_frame >= anim_editor_strip_scroll + _vis_s2)
                anim_editor_strip_scroll = anim_editor_selected_frame - _vis_s2 + 1;
        }
    }
}

// Refreshes the folder/file lists for the SFX picker at the current path.
function _anim_sfx_refresh() {
    anim_editor_sfx_folders = [];
    anim_editor_sfx_files = [];
    
    var _path = anim_editor_sfx_path;
    if (_path != "" && string_char_at(_path, string_length(_path)) != "/") {
        _path += "/";
    }
    var _path_len = string_length(_path);

    if (global.sounds_pack_header != undefined) {
        var _keys = struct_get_names(global.sounds_pack_header);
        for (var i = 0; i < array_length(_keys); i++) {
            var _k = _keys[i];
            if (_path == "" || string_lower(string_copy(_k, 1, _path_len)) == string_lower(_path)) {
                var _rem = string_delete(_k, 1, _path_len);
                var _slash = string_pos("/", _rem);
                if (_slash > 0) {
                    var _fld = string_copy(_rem, 1, _slash - 1);
                    var _found = false;
                    for (var f = 0; f < array_length(anim_editor_sfx_folders); f++) {
                        if (string_lower(anim_editor_sfx_folders[f]) == string_lower(_fld)) { _found = true; break; }
                    }
                    if (!_found) array_push(anim_editor_sfx_folders, _fld);
                } else {
                    var _found = false;
                    for (var f = 0; f < array_length(anim_editor_sfx_files); f++) {
                        if (string_lower(anim_editor_sfx_files[f]) == string_lower(_rem)) { _found = true; break; }
                    }
                    if (!_found) array_push(anim_editor_sfx_files, _rem);
                }
            }
        }
    }

    array_sort(anim_editor_sfx_folders, function(a, b) {
        var _la = string_lower(a); var _lb = string_lower(b);
        if (_la < _lb) return -1; if (_la > _lb) return 1; return 0;
    });
    array_sort(anim_editor_sfx_files, function(a, b) {
        var _la = string_lower(a); var _lb = string_lower(b);
        if (_la < _lb) return -1; if (_la > _lb) return 1; return 0;
    });

    anim_editor_sfx_scroll = 0;
}

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
        if (keyboard_check_pressed(vk_tab) && dict_focused_field == 0) {
            dict_focused_field = 1;
            dict_caret_pos = string_length(_entry.pronunciation);
            keyboard_string = "";
            cursor_timer = 0; cursor_visible = true;
        }
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
    var _m_w = 400; var _m_h = 660;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;

    if (mouse_check_button_pressed(mb_left)) {
        for (var i = 0; i < array_length(move_speed_labels); i++) {
            var _by = _m_y + 80 + (i * 45);
            if (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _by && _my < _by + 40) move_modal_temp_speed_index = i;
        }
        if (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _m_y + 314 && _my < _m_y + 340) {
            move_modal_temp_moonwalk = !move_modal_temp_moonwalk;
        }
        // Trick buttons
        var _trick_vals = ["jump", "front flip", "back flip"];
        for (var _ti = 0; _ti < 3; _ti++) {
            var _ty = _m_y + 380 + _ti * 44;
            if (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _ty && _my < _ty + 38) {
                move_modal_temp_trick = (move_modal_temp_trick == _trick_vals[_ti]) ? "none" : _trick_vals[_ti];
                if (move_modal_temp_trick == "none") move_modal_temp_trick_count = 1;
            }
        }
        // Count buttons (1–5)
        if (move_modal_temp_trick != "none") {
            var _cbw2 = 52; var _cbg2 = 8;
            for (var _ci2 = 0; _ci2 < 5; _ci2++) {
                var _cx2 = _m_x + 50 + _ci2 * (_cbw2 + _cbg2);
                var _cy2 = _m_y + 540;
                if (_mx > _cx2 && _mx < _cx2 + _cbw2 && _my > _cy2 && _my < _cy2 + 34) {
                    move_modal_temp_trick_count = _ci2 + 1;
                }
            }
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
                _b.trick       = move_modal_temp_trick;
                _b.trick_count = (move_modal_temp_trick != "none") ? move_modal_temp_trick_count : 1;
                var _bn = _b.action_name;
                var _pos = string_pos(" (", _bn); if (_pos > 0) _bn = string_copy(_bn, 1, _pos - 1);
                _pos = string_pos(" [MOONWALK]", _bn); if (_pos > 0) _bn = string_copy(_bn, 1, _pos - 1);
                // Strip trick labels — match prefix so "x2" variants are also removed
                _pos = string_pos(" [JUMP", string_upper(_bn));       if (_pos > 0) _bn = string_copy(_bn, 1, _pos - 1);
                _pos = string_pos(" [FRONT FLIP", string_upper(_bn)); if (_pos > 0) _bn = string_copy(_bn, 1, _pos - 1);
                _pos = string_pos(" [BACK FLIP", string_upper(_bn));  if (_pos > 0) _bn = string_copy(_bn, 1, _pos - 1);
                var _lbl = move_speed_labels[move_modal_temp_speed_index];
                if (_lbl != "WALK") _bn += " (" + _lbl + ")";
                if (_b.moonwalk) _bn += " [MOONWALK]";
                if (_b.trick != "none") {
                    _bn += " [" + string_upper(_b.trick);
                    if (_b.trick_count > 1) _bn += " x" + string(_b.trick_count);
                    _bn += "]";
                }
                _b.action_name = _bn;
                move_modal_edit_mode = false;
            } else {
                move_speed_index = move_modal_temp_speed_index;
                moonwalk_enabled = move_modal_temp_moonwalk;
                move_trick = move_modal_temp_trick;
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
                    var _insert_idx = (insertion_idx != -1) ? insertion_idx + 1 : ((focused_block != -1) ? focused_block + 1 : array_length(script_blocks));
                    var _spliced = (insertion_idx != -1);
                    array_insert(script_blocks, _insert_idx, _new_a);
                    update_block_height(_insert_idx);
                    focused_block = _insert_idx;
                    if (_spliced) {
                        insertion_idx = -1;
                        var _block_y = 0;
                        for (var k = 0; k < _insert_idx; k++) _block_y += script_blocks[k].height + 20;
                        block_scroll_y = min(0, -(_block_y - box_h / 3));
                        update_preview_actors_for_block(_insert_idx, true);
                    }
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
                var _insert_idx = (insertion_idx != -1) ? insertion_idx + 1 : ((focused_block != -1) ? focused_block + 1 : array_length(script_blocks));
                var _spliced = (insertion_idx != -1);
                array_insert(script_blocks, _insert_idx, _new_a);
                update_block_height(_insert_idx);
                focused_block = _insert_idx;
                if (_spliced) {
                    insertion_idx = -1;
                    var _block_y = 0;
                    for (var k = 0; k < _insert_idx; k++) _block_y += script_blocks[k].height + 20;
                    block_scroll_y = min(0, -(_block_y - box_h / 3));
                    update_preview_actors_for_block(_insert_idx, true);
                }
            }
            expression_modal_open = false; expression_modal_edit_mode = false;
        }
        if (_mx > _m_x + 525 && _mx < _m_x + 675 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20) {
            expression_modal_open = false; expression_modal_edit_mode = false;
        }
    }
}

function step_modal_pose_expr() {
    var _mx = mouse_x; var _my = mouse_y;
    var _m_w = 1060; var _m_h = 520;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;

    // Hover detection for pose
    var _hov_pose = -1;
    for (var i = 1; i <= 4; i++) {
        var _by = _m_y + 38 + (i - 1) * 58;
        if (_mx > _m_x + 12 && _mx < _m_x + 208 && _my > _by && _my < _by + 50) { _hov_pose = i; break; }
    }

    // Hover detection for expression
    var _cols_ep = 4; var _col_w_ep = 118; var _row_h_ep = 44;
    var _gx_ep = _m_x + 228; var _gy_ep = _m_y + 38;
    var _hov_expr = -1;
    for (var e = 1; e <= 20; e++) {
        var _col = (e - 1) % _cols_ep; var _row = floor((e - 1) / _cols_ep);
        var _ex = _gx_ep + _col * _col_w_ep; var _ey = _gy_ep + _row * _row_h_ep;
        if (_mx > _ex + 2 && _mx < _ex + _col_w_ep - 2 && _my > _ey + 2 && _my < _ey + _row_h_ep - 2) { _hov_expr = e; break; }
    }

    // Update temp (hover preview)
    pose_modal_temp_pose        = (_hov_pose != -1) ? _hov_pose : pose_modal_locked_pose;
    expression_modal_temp_expr  = (_hov_expr != -1) ? _hov_expr : expression_modal_locked_expr;

    if (mouse_check_button_pressed(mb_left)) {
        if (_hov_pose != -1) { pose_modal_locked_pose = _hov_pose; pose_modal_temp_pose = _hov_pose; pose_expr_pose_touched = true; }
        if (_hov_expr != -1) { expression_modal_locked_expr = _hov_expr; expression_modal_temp_expr = _hov_expr; pose_expr_expr_touched = true; }

        // APPLY
        var _can_apply = (pose_modal_locked_pose != -1 && expression_modal_locked_expr != -1);
        var _ap_x = _m_x + 228; var _btn_y_pe = _m_y + _m_h - 52; var _btn_w_pe = 210; var _btn_h_pe = 40;
        if (_can_apply && _mx > _ap_x && _mx < _ap_x + _btn_w_pe && _my > _btn_y_pe && _my < _btn_y_pe + _btn_h_pe) {
            selected_pose       = pose_modal_locked_pose;
            selected_expression = expression_modal_locked_expr;
            var _char = characters[selected_character_index];
            _char.pose       = selected_pose;
            _char.expression = selected_expression;

            // Apply to staging actors
            if (scene_edit_mode && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                var _sb = script_blocks[active_scene_block_idx];
                if (variable_struct_exists(_sb, "actors")) {
                    for (var a = 0; a < array_length(_sb.actors); a++) {
                        if (_sb.actors[a].char_index == selected_character_index) {
                            _sb.actors[a].pose = selected_pose;
                            _sb.actors[a].expression = selected_expression;
                        }
                    }
                }
            }
            // Apply to preview actors
            var _is_onstage = false;
            for (var pa = 0; pa < array_length(preview_actors); pa++) {
                if (preview_actors[pa].char_index == selected_character_index) {
                    preview_actors[pa].pose = selected_pose;
                    preview_actors[pa].expression = selected_expression;
                    _is_onstage = true;
                }
            }

            // Insert/update action block
            if ((_is_onstage || pose_modal_edit_mode || expression_modal_edit_mode) && !scene_edit_mode) {
                var _expr_name = string_lower(mood_names[selected_expression - 1]);
                var _action_text;
                if (pose_expr_pose_touched && pose_expr_expr_touched) {
                    _action_text = "looks " + _expr_name + " and pose " + string(selected_pose);
                } else if (pose_expr_pose_touched) {
                    _action_text = "pose " + string(selected_pose);
                } else {
                    _action_text = "looks " + _expr_name;
                }
                if (pose_modal_edit_mode && pose_modal_target_index != -1) {
                    script_blocks[pose_modal_target_index].action_name = _action_text;
                } else if (expression_modal_edit_mode && expression_modal_target_index != -1) {
                    script_blocks[expression_modal_target_index].action_name = _action_text;
                } else {
                    var _new_a = { type: "action", char_index: selected_character_index, action_name: _action_text, height: 85 };
                    var _insert_idx = (insertion_idx != -1) ? insertion_idx + 1 : ((focused_block != -1) ? focused_block + 1 : array_length(script_blocks));
                    var _spliced = (insertion_idx != -1);
                    array_insert(script_blocks, _insert_idx, _new_a);
                    update_block_height(_insert_idx);
                    focused_block = _insert_idx;
                    if (_spliced) {
                        insertion_idx = -1;
                        var _block_y = 0;
                        for (var k = 0; k < _insert_idx; k++) _block_y += script_blocks[k].height + 20;
                        block_scroll_y = min(0, -(_block_y - box_h / 3));
                        update_preview_actors_for_block(_insert_idx, true);
                    }
                }
            }

            pose_expr_modal_open = false;
            pose_modal_edit_mode = false; pose_modal_target_index = -1;
            expression_modal_edit_mode = false; expression_modal_target_index = -1;
            return;
        }

        // CANCEL
        var _cx_pe = _ap_x + _btn_w_pe + 14;
        if (_mx > _cx_pe && _mx < _cx_pe + _btn_w_pe && _my > _btn_y_pe && _my < _btn_y_pe + _btn_h_pe) {
            pose_expr_modal_open = false;
            pose_modal_edit_mode = false; expression_modal_edit_mode = false;
            return;
        }
    }
}

function step_modal_action() {
    var _mx = mouse_x; var _my = mouse_y;
    var _mw = 900; var _mh = 550; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;

    if (mouse_check_button_pressed(mb_left)) {
        for (var i = 0; i < array_length(all_actions); i++) {
            var _is_gen = (all_actions[i].category == "general");
            var _ng = 0; var _nc = 0;
            for (var _k = 0; _k < i; _k++) { if (all_actions[_k].category == "general") _ng++; else _nc++; }
            var _by = _myo + 85 + (_ng * 45) + (!_is_gen ? 50 : 0) + (_nc * 45);
            var _disabled = false;
            if (action_modal_edit_mode) {
                if (action_modal_selected_idx != i) _disabled = true;
            } else if (!_is_gen) {
                if (selected_character_index == 0) _disabled = true;
                else if (all_actions[i].name == "resurrect") {
                    if (!action_modal_char_is_dead) _disabled = true;
                } else if (!action_modal_char_onstage) _disabled = true;
                else if (all_actions[i].name == "kill" && action_modal_char_is_dead) _disabled = true;
                else if (all_actions[i].name != "kill" && action_modal_char_is_dead) _disabled = true;
            }
            if (!_disabled && _mx > _mxo+20 && _mx < _mxo+250 && _my > _by && _my < _by+40) {
                action_modal_selected_idx = i; action_modal_locked = true; action_modal_selected_anim_idx = -1;
                if (all_actions[i].name == "play sfx") { refresh_sfx_folders(); action_modal_sfx_folder_idx = -1; action_modal_sfx_file_idx = -1; action_modal_sfx_search = ""; action_modal_sfx_search_results = []; action_modal_sfx_search_sel = -1; action_modal_sfx_search_focused = false; action_modal_sfx_search_scroll_y = 0; keyboard_string = ""; }
                else if (all_actions[i].name == "display title") { action_modal_title_text = ""; action_modal_title_caret = 0; action_modal_title_sel_start = 0; action_modal_title_sel_end = 0; action_modal_wait_duration = 2.0; action_modal_dropdown_open = ""; keyboard_string = ""; }
                else if (all_actions[i].name == "disappear") { action_modal_disappear_style = "pop"; action_modal_disappear_speed = 2; }
                else if (all_actions[i].name == "jitter")    { action_modal_jitter_intensity = 3; action_modal_jitter_duration = 1.0; action_modal_jitter_direction = "omni"; }
                else if (all_actions[i].name == "quake")     { action_modal_quake_intensity = 3; action_modal_quake_duration = 1.0; action_modal_quake_direction = "omni"; }
                else if (all_actions[i].name == "kill")            { action_modal_kill_style = "sudden"; }
                else if (all_actions[i].name == "special animation") { action_modal_sa_scroll = 0; }
                return;
            }
        }
        // Jitter sub-options
        if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "jitter") {
            var _jx = _mxo+290; var _jsw = 360;
            var _jdirs = ["horizontal","vertical","omni"];
            for (var _jdi = 0; _jdi < 3; _jdi++) {
                var _jdx = _jx + _jdi * 124;
                if (_mx > _jdx && _mx < _jdx+118 && _my > _myo+146 && _my < _myo+184) {
                    action_modal_jitter_direction = _jdirs[_jdi]; return;
                }
            }
            var _jity = _myo+260;
            if (_mx > _jx && _mx < _jx+_jsw && _my > _jity-12 && _my < _jity+20) {
                action_modal_jitter_drag = 1; return;
            }
            var _jdry = _myo+363;
            if (_mx > _jx && _mx < _jx+_jsw && _my > _jdry-12 && _my < _jdry+20) {
                action_modal_jitter_drag = 2; return;
            }
        }
        // Quake sub-options
        if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "quake") {
            var _qx2 = _mxo+290; var _qsw = 360;
            var _qdirs2 = ["horizontal","vertical","omni"];
            for (var _qdi2 = 0; _qdi2 < 3; _qdi2++) {
                var _qdx2 = _qx2 + _qdi2 * 124;
                if (_mx > _qdx2 && _mx < _qdx2+118 && _my > _myo+146 && _my < _myo+184) {
                    action_modal_quake_direction = _qdirs2[_qdi2]; return;
                }
            }
            var _qity2 = _myo+260;
            if (_mx > _qx2 && _mx < _qx2+_qsw && _my > _qity2-12 && _my < _qity2+20) {
                action_modal_quake_drag = 1; return;
            }
            var _qdry3 = _myo+363;
            if (_mx > _qx2 && _mx < _qx2+_qsw && _my > _qdry3-12 && _my < _qdry3+20) {
                action_modal_quake_drag = 2; return;
            }
        }
        // Disappear sub-options (style + speed)
        if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "disappear") {
            var _dstyles = ["pop", "eat dirt", "home planet", "disintegrate", "melt"];
            for (var _dsi = 0; _dsi < 5; _dsi++) {
                var _dsy = _myo + 148 + _dsi * 44;
                if (_mx > _mxo+290 && _mx < _mxo+460 && _my > _dsy && _my < _dsy+38) {
                    action_modal_disappear_style = _dstyles[_dsi];
                    if (action_modal_disappear_style == "pop") action_modal_disappear_speed = 2;
                    return;
                }
            }
            // Speed selector (vertical list)
            if (action_modal_disappear_style != "pop") {
                for (var _spi = 0; _spi < 5; _spi++) {
                    var _spy = _myo + 148 + _spi * 44;
                    if (_mx > _mxo+475 && _mx < _mxo+660 && _my > _spy && _my < _spy+38) {
                        action_modal_disappear_speed = _spi; return;
                    }
                }
            }
        }

        // Kill style + speed selector
        if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "kill") {
            var _kstyles = ["sudden", "fall_forwards", "fall_backwards", "decapitate"];
            for (var _ksi = 0; _ksi < 4; _ksi++) {
                var _ksy = _myo + 184 + _ksi * 46;
                if (_mx > _mxo+290 && _mx < _mxo+540 && _my > _ksy && _my < _ksy+40) {
                    action_modal_kill_style = _kstyles[_ksi]; return;
                }
            }
            var _kfall2 = (action_modal_kill_style == "fall_forwards" || action_modal_kill_style == "fall_backwards");
            if (_kfall2) {
                for (var _kspi2 = 0; _kspi2 < 5; _kspi2++) {
                    var _kspy2 = _myo + 184 + _kspi2 * 40;
                    if (_mx > _mxo+555 && _mx < _mxo+745 && _my > _kspy2 && _my < _kspy2+34) {
                        action_modal_kill_speed = _kspi2; return;
                    }
                }
            }
        }

        if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "resurrect") {
            var _rfell3 = (action_modal_char_death_style == "fall_forwards" || action_modal_char_death_style == "fall_backwards");
            if (_rfell3) {
                for (var _rspi = 0; _rspi < 5; _rspi++) {
                    var _rspy = _myo + 260 + _rspi * 36;
                    if (_mx > _mxo+290 && _mx < _mxo+540 && _my > _rspy && _my < _rspy+30) {
                        action_modal_resurrect_speed = _rspi; return;
                    }
                }
            }
        }

        // Special animation right-panel list
        if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "special animation") {
            var _sa_d3 = canned_anim_get_data(selected_character_index);
            if (_sa_d3 != undefined) {
                var _sa_rx = _mxo+290; var _sa_ry = _myo+115; var _sa_rh = 36; var _sa_rw = _mw-324;
                var _sa_lh = _mh - 185; var _sa_stp = _sa_rh + 6;
                var _sa_vis3 = floor(_sa_lh / _sa_stp);
                var _sa_max3 = max(0, array_length(_sa_d3) - _sa_vis3);
                action_modal_sa_scroll = clamp(action_modal_sa_scroll, 0, _sa_max3);
                var _sa_scr3 = action_modal_sa_scroll;
                // Scrollbar thumb press → start drag
                if (_sa_max3 > 0) {
                    var _sbx3 = _sa_rx + _sa_rw + 4; var _sby_t3 = _sa_ry; var _sbh3 = _sa_lh;
                    var _th3 = max(20, _sbh3 * _sa_vis3 / array_length(_sa_d3));
                    var _ty3 = _sby_t3 + (_sa_scr3 / _sa_max3) * (_sbh3 - _th3);
                    if (_mx > _sbx3 && _mx < _sbx3 + 10 && _my > _ty3 && _my < _ty3 + _th3) {
                        action_modal_sa_sb_drag = true; action_modal_sa_sb_drag_off = _my - _ty3; return;
                    }
                }
                // List item clicks (only selectable when char eligible)
                if (action_modal_char_onstage && !action_modal_char_is_dead && selected_character_index > 0) {
                    for (var _si3 = 0; _si3 < array_length(_sa_d3); _si3++) {
                        var _sby3 = _sa_ry + (_si3 - _sa_scr3) * _sa_stp;
                        if (_sby3 < _sa_ry || _sby3 + _sa_rh > _sa_ry + _sa_lh) continue;
                        if (_mx > _sa_rx && _mx < _sa_rx + _sa_rw && _my > _sby3 && _my < _sby3 + _sa_rh) {
                            action_modal_selected_anim_idx = _si3; action_modal_locked = true; return;
                        }
                    }
                }
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
            var _fx = _mxo + 280; var _fy = _wy + 100; var _fh = 185;
            var _lx = _mxo + 550; var _ly = _wy + 100; var _lh = 185;
            var _srx = _fx + 10; var _sry = _wy + 30; var _srw = 560; var _srh = 24;

            // Search box: clear button (×) or focus
            if (_mx > _srx && _mx < _srx + _srw && _my > _sry && _my < _sry + _srh) {
                if (_mx > _srx + _srw - 22 && action_modal_sfx_search != "") {
                    // × clear button
                    action_modal_sfx_search = "";
                    refresh_sfx_search("");
                    action_modal_sfx_bksp_held = 0;
                    action_modal_sfx_search_focused = true;
                    keyboard_string = "";
                } else {
                    action_modal_sfx_search_focused = true;
                    keyboard_string = "";
                }
            } else {
                action_modal_sfx_search_focused = false;

                // Actor folders checkbox
                var _chk_x2 = _fx + 10; var _chk_y2 = _wy + 58;
                if (_mx > _chk_x2 && _mx < _chk_x2 + 200 && _my > _chk_y2 && _my < _chk_y2 + 18) {
                    action_modal_sfx_show_actors = !action_modal_sfx_show_actors;
                    refresh_sfx_folders();
                    action_modal_sfx_folder_idx = -1;
                    action_modal_sfx_files = [];
                    action_modal_sfx_scroll_y = 0;
                    return;
                }

                if (action_modal_sfx_search != "") {
                    // Search results list click
                    var _rh = 195; var _ry = _wy + 90;
                    if (_mx > _fx + 10 && _mx < _fx + 570 && _my > _ry && _my < _ry + _rh) {
                        for (var f = 0; f < array_length(action_modal_sfx_search_results); f++) {
                            var _by = _ry + (f * 28) - action_modal_sfx_search_scroll_y;
                            if (_my > _by && _my < _by + 28) {
                                var _res = action_modal_sfx_search_results[f];
                                var _dbl = (action_modal_sfx_last_click_idx == f && current_time - action_modal_sfx_last_click_time < 400);
                                action_modal_sfx_search_sel = f;
                                for (var _fi = 0; _fi < array_length(action_modal_sfx_folders); _fi++) {
                                    if (action_modal_sfx_folders[_fi] == _res.folder) {
                                        action_modal_sfx_folder_idx = _fi;
                                        refresh_sfx_files(_res.folder);
                                        for (var _ki = 0; _ki < array_length(action_modal_sfx_files); _ki++) {
                                            if (action_modal_sfx_files[_ki] == _res.file) { action_modal_sfx_file_idx = _ki; break; }
                                        }
                                        break;
                                    }
                                }
                                if (_dbl) {
                                    play_sfx_preview(_res.folder, _res.file);
                                    action_modal_sfx_last_click_idx = -1;
                                } else {
                                    action_modal_sfx_last_click_idx = f;
                                    action_modal_sfx_last_click_time = current_time;
                                }
                                break;
                            }
                        }
                    }
                } else {
                    // Normal folder/file columns
                    if (_mx > _fx + 10 && _mx < _fx + 230 && _my > _fy && _my < _fy + _fh) {
                        for (var f = 0; f < array_length(action_modal_sfx_folders); f++) {
                            var _by = _fy + (f * 30) - action_modal_sfx_scroll_y;
                            if (_my > _by && _my < _by + 30) {
                                action_modal_sfx_folder_idx = f;
                                refresh_sfx_files(action_modal_sfx_folders[f]);
                                action_modal_sfx_file_idx = -1;
                                action_modal_sfx_files_scroll_y = 0;
                                action_modal_sfx_last_click_idx = -1;
                            }
                        }
                    }
                    if (_mx > _lx - 10 && _mx < _lx + 300 && _my > _ly && _my < _ly + _lh) {
                        for (var f = 0; f < array_length(action_modal_sfx_files); f++) {
                            var _by = _ly + (f * 30) - action_modal_sfx_files_scroll_y;
                            if (_my > _by && _my < _by + 30) {
                                var _dbl = (action_modal_sfx_last_click_idx == f && current_time - action_modal_sfx_last_click_time < 400);
                                action_modal_sfx_file_idx = f;
                                if (_dbl && action_modal_sfx_folder_idx != -1) {
                                    play_sfx_preview(action_modal_sfx_folders[action_modal_sfx_folder_idx], action_modal_sfx_files[f]);
                                    action_modal_sfx_last_click_idx = -1;
                                } else {
                                    action_modal_sfx_last_click_idx = f;
                                    action_modal_sfx_last_click_time = current_time;
                                }
                            }
                        }
                    }
                }
            }
            var _tx = _mxo + _mw - 150; var _ty = _myo + _mh - 120;
            if (_mx > _tx && _mx < _tx + 120 && _my > _ty && _my < _ty + 35) {
                if (test_sfx_sound != -1 && audio_is_playing(test_sfx_sound)) {
                    audio_stop_sound(test_sfx_sound);
                    audio_free_buffer_sound(test_sfx_sound); test_sfx_sound = -1;
                    if (test_sfx_buffer != -1) { buffer_delete(test_sfx_buffer); test_sfx_buffer = -1; }
                } else if (action_modal_sfx_folder_idx != -1 && action_modal_sfx_file_idx != -1) {
                    play_sfx_preview(action_modal_sfx_folders[action_modal_sfx_folder_idx], action_modal_sfx_files[action_modal_sfx_file_idx]);
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
            if (_mx > _wx && _mx < _wx + 560 && _my > _wy + 65 && _my < _wy + 150) {
                var _rel_x = _mx - (_wx + 10); var _rel_y = _my - (_wy + 75);
                var _best_p = 0; var _min_d = 999999;
                for (var _tc = 0; _tc <= string_length(action_modal_title_text); _tc++) {
                    var _tpos = get_text_pos(action_modal_title_text, _tc, 540, 25);
                    var _td = point_distance(_rel_x, _rel_y, _tpos.x, _tpos.y + 11);
                    if (_td < _min_d) { _min_d = _td; _best_p = _tc; }
                }
                action_modal_title_caret = _best_p;
                action_modal_title_sel_start = _best_p; action_modal_title_sel_end = _best_p;
                action_modal_title_dragging = true;
                keyboard_string = "";
            }
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
                if ((action_modal_sfx_folder_idx == -1 || action_modal_sfx_file_idx == -1) && action_modal_sfx_search_sel == -1) _can_proceed = false;
                else {
                    var _sfx_folder2 = ""; var _sfx_file = "";
                    if (action_modal_sfx_search_sel != -1 && action_modal_sfx_search_sel < array_length(action_modal_sfx_search_results)) {
                        var _sr = action_modal_sfx_search_results[action_modal_sfx_search_sel];
                        _sfx_folder2 = _sr.folder; _sfx_file = _sr.file;
                    } else {
                        _sfx_folder2 = action_modal_sfx_folders[action_modal_sfx_folder_idx];
                        _sfx_file    = action_modal_sfx_files[action_modal_sfx_file_idx];
                    }
                    _sfx_path = "sounds/" + _sfx_folder2 + "/" + _sfx_file;
                    _act_name = "Play SFX: " + string_replace(string_upper(_sfx_file), ".WAV", "");
                }
            } else if (_act_name == "quake") {
                _act_name = "quake";
            } else if (_act_name == "jitter") {
                if (selected_character_index == 0 || !action_modal_char_onstage) _can_proceed = false;
                else _act_name = "jitters";
            } else if (_act_name == "disappear") {
                if (selected_character_index == 0 || !action_modal_char_onstage) _can_proceed = false;
                else _act_name = "disappears (" + action_modal_disappear_style + ")";
            } else if (_act_name == "kill") {
                if (selected_character_index == 0 || !action_modal_char_onstage || action_modal_char_is_dead) _can_proceed = false;
                else {
                    var _dlbl = "sudden death";
                    if (action_modal_kill_style == "fall_forwards")  _dlbl = "fell forwards";
                    else if (action_modal_kill_style == "fall_backwards") _dlbl = "fell backwards";
                    else if (action_modal_kill_style == "decapitate")     _dlbl = "decapitated";
                    _act_name = "dies (" + _dlbl + ")";
                }
            } else if (_act_name == "resurrect") {
                if (selected_character_index == 0 || !action_modal_char_is_dead) _can_proceed = false;
                else _act_name = "resurrects";
            } else if (_act_name == "special animation") {
                if (action_modal_selected_anim_idx < 0 || !action_modal_char_onstage || action_modal_char_is_dead) { _can_proceed = false; }
                else {
                    var _sa_ok = canned_anim_get_data(selected_character_index);
                    if (_sa_ok == undefined || action_modal_selected_anim_idx >= array_length(_sa_ok)) { _can_proceed = false; }
                    else _act_name = _sa_ok[action_modal_selected_anim_idx].name;
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
                    } else if (all_actions[action_modal_selected_idx].name == "play sfx") { _b.sfx_path = _sfx_path; }
                    else if (all_actions[action_modal_selected_idx].name == "quake") {
                        _b.quake_intensity = action_modal_quake_intensity;
                        _b.quake_duration  = action_modal_quake_duration;
                        _b.quake_direction = action_modal_quake_direction;
                        _b.char_index      = 0;
                    } else if (all_actions[action_modal_selected_idx].name == "jitter") {
                        _b.jitter_intensity = action_modal_jitter_intensity;
                        _b.jitter_duration  = action_modal_jitter_duration;
                        _b.jitter_direction = action_modal_jitter_direction;
                    } else if (all_actions[action_modal_selected_idx].name == "disappear") {
                        _b.disappear_style = action_modal_disappear_style;
                        _b.disappear_speed = action_modal_disappear_speed;
                    } else if (all_actions[action_modal_selected_idx].name == "kill") {
                        _b.kill_style  = action_modal_kill_style;
                        _b.kill_speed  = action_modal_kill_speed;
                        var _dlbl2 = "sudden death";
                        if (action_modal_kill_style == "fall_forwards")  _dlbl2 = "fell forwards";
                        else if (action_modal_kill_style == "fall_backwards") _dlbl2 = "fell backwards";
                        else if (action_modal_kill_style == "decapitate")     _dlbl2 = "decapitated";
                        _b.action_name = "dies (" + _dlbl2 + ")";
                    } else if (all_actions[action_modal_selected_idx].name == "resurrect") {
                        _b.resurrect_speed            = action_modal_resurrect_speed;
                        _b.resurrect_prev_death_style = action_modal_char_death_style;
                    }
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
                    else if (all_actions[action_modal_selected_idx].name == "quake") {
                        _new_a.quake_intensity = action_modal_quake_intensity;
                        _new_a.quake_duration  = action_modal_quake_duration;
                        _new_a.quake_direction = action_modal_quake_direction;
                        _new_a.char_index      = 0;
                    } else if (all_actions[action_modal_selected_idx].name == "jitter") {
                        _new_a.jitter_intensity = action_modal_jitter_intensity;
                        _new_a.jitter_duration  = action_modal_jitter_duration;
                        _new_a.jitter_direction = action_modal_jitter_direction;
                    } else if (all_actions[action_modal_selected_idx].name == "disappear") {
                        _new_a.disappear_style = action_modal_disappear_style;
                        _new_a.disappear_speed = action_modal_disappear_speed;
                    } else if (all_actions[action_modal_selected_idx].name == "kill") {
                        _new_a.kill_style  = action_modal_kill_style;
                        _new_a.kill_speed  = action_modal_kill_speed;
                    } else if (all_actions[action_modal_selected_idx].name == "resurrect") {
                        _new_a.resurrect_speed            = action_modal_resurrect_speed;
                        _new_a.resurrect_prev_death_style = action_modal_char_death_style;
                    }
                    if (action_modal_target_index == -1) array_push(script_blocks, _new_a);
                    else array_insert(script_blocks, action_modal_target_index, _new_a);
                }
                update_all_block_heights();
                action_modal_open = false;
                insertion_idx = -1; // Reset splice mode!
                var _ins_idx = (action_modal_target_index != -1) ? action_modal_target_index : (array_length(script_blocks) - 1);
                var _block_y = 0;
                for (var k = 0; k < _ins_idx; k++) _block_y += script_blocks[k].height + 20;
                block_scroll_y = min(0, -(_block_y - box_h / 3));
                update_preview_actors_for_block(_ins_idx, true);
                return;
            }
        }
        if (_mx > _mxo+_mw-130 && _mx < _mxo+_mw-20 && _my > _myo+_mh-50 && _my < _myo+_mh-15) {
            action_modal_edit_mode = false; action_modal_open = false; return;
        }
    }

    if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "play sfx") {
        var _wx = _mxo + 300; var _wy = _myo + 130;
        var _fx = _mxo + 280; var _fy = _wy + 90; var _fh = 195;
        var _lx = _mxo + 550; var _ly = _wy + 90; var _lh = 195;

        // Keyboard input for search box
        if (action_modal_sfx_search_focused) {
            if (string_length(keyboard_string) > 0) {
                action_modal_sfx_search += keyboard_string;
                keyboard_string = "";
                refresh_sfx_search(action_modal_sfx_search);
            }
            if (keyboard_check(vk_backspace)) {
                action_modal_sfx_bksp_held++;
                if (action_modal_sfx_bksp_held >= 45 && string_length(action_modal_sfx_search) > 0) {
                    action_modal_sfx_search = "";
                    refresh_sfx_search("");
                    action_modal_sfx_bksp_held = 0;
                }
            } else {
                action_modal_sfx_bksp_held = 0;
            }
            if (keyboard_check_pressed(vk_backspace) && string_length(action_modal_sfx_search) > 0) {
                action_modal_sfx_search = string_copy(action_modal_sfx_search, 1, string_length(action_modal_sfx_search) - 1);
                refresh_sfx_search(action_modal_sfx_search);
            }
        } else {
            action_modal_sfx_bksp_held = 0;
        }

        if (action_modal_sfx_search != "") {
            // Scroll search results
            var _ry = _wy + 90; var _rh = 200;
            if (_mx > _fx + 10 && _mx < _fx + 580 && _my > _ry && _my < _ry + _rh) {
                if (mouse_wheel_up())   action_modal_sfx_search_scroll_y -= 56;
                if (mouse_wheel_down()) action_modal_sfx_search_scroll_y += 56;
            }
            var _max_r = max(0, array_length(action_modal_sfx_search_results) * 28 - _rh);
            action_modal_sfx_search_scroll_y = clamp(action_modal_sfx_search_scroll_y, 0, _max_r);
        } else {
            // Normal scroll
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

    if (action_modal_jitter_drag != 0) {
        if (mouse_check_button(mb_left)) {
            var _jsw = 360.0; var _jx = _mxo + 290.0;
            var _jp = clamp((_mx - _jx) / _jsw, 0.0, 1.0);
            if (action_modal_jitter_drag == 1) action_modal_jitter_intensity = round(clamp(1 + _jp * 6, 1, 7));
            else action_modal_jitter_duration = round(clamp(0.2 + _jp * 4.8, 0.2, 5.0) * 10) / 10;
        } else { action_modal_jitter_drag = 0; }
    }

    if (action_modal_quake_drag != 0) {
        if (mouse_check_button(mb_left)) {
            var _qsw2 = 360.0; var _qx3 = _mxo + 290.0;
            var _qp = clamp((_mx - _qx3) / _qsw2, 0.0, 1.0);
            if (action_modal_quake_drag == 1) action_modal_quake_intensity = round(clamp(1 + _qp * 6, 1, 7));
            else action_modal_quake_duration = round(clamp(0.2 + _qp * 4.8, 0.2, 5.0) * 10) / 10;
        } else { action_modal_quake_drag = 0; }
    }

    if (action_modal_title_dragging) {
        if (mouse_check_button(mb_left)) {
            var _title_tx = _mxo + 310; var _title_ty = _myo + 175;
            var _rel_x = _mx - _title_tx; var _rel_y = _my - _title_ty;
            var _best_p = 0; var _min_d = 999999;
            for (var _tc = 0; _tc <= string_length(action_modal_title_text); _tc++) {
                var _tpos = get_text_pos(action_modal_title_text, _tc, 540, 25);
                var _td = point_distance(_rel_x, _rel_y, _tpos.x, _tpos.y + 11);
                if (_td < _min_d) { _min_d = _td; _best_p = _tc; }
            }
            action_modal_title_caret = _best_p;
            action_modal_title_sel_end = _best_p;
        } else { action_modal_title_dragging = false; }
    }

    if (action_modal_open && action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "display title") {
        var _ctrl = keyboard_check(vk_control);

        if (_ctrl && keyboard_check_pressed(ord("A"))) {
            action_modal_title_sel_start = 0;
            action_modal_title_sel_end = string_length(action_modal_title_text);
            action_modal_title_caret = action_modal_title_sel_end;
            keyboard_string = "";
        }

        var _trk = -1;
        if      (keyboard_check(vk_backspace)) _trk = vk_backspace;
        else if (keyboard_check(vk_delete))    _trk = vk_delete;
        else if (keyboard_check(vk_left))      _trk = vk_left;
        else if (keyboard_check(vk_right))     _trk = vk_right;
        var _tdo = false;
        if (_trk != -1) {
            if (keyboard_check_pressed(_trk)) { _tdo = true; action_modal_title_repeat_timer = 25; }
            else { action_modal_title_repeat_timer--; if (action_modal_title_repeat_timer <= 0) { _tdo = true; action_modal_title_repeat_timer = 2; } }
        } else { action_modal_title_repeat_timer = 0; }

        if (!_ctrl && string_length(keyboard_string) > 0) {
            if (action_modal_title_sel_start != action_modal_title_sel_end) {
                var _s = min(action_modal_title_sel_start, action_modal_title_sel_end);
                var _e = max(action_modal_title_sel_start, action_modal_title_sel_end);
                action_modal_title_text = string_delete(action_modal_title_text, _s + 1, _e - _s);
                action_modal_title_caret = _s; action_modal_title_sel_start = _s; action_modal_title_sel_end = _s;
            }
            var _new_text = string_insert(keyboard_string, action_modal_title_text, action_modal_title_caret + 1);
            if (string_length(_new_text) <= 100) {
                action_modal_title_text = _new_text;
                action_modal_title_caret += string_length(keyboard_string);
                action_modal_title_sel_start = action_modal_title_caret; action_modal_title_sel_end = action_modal_title_caret;
            }
            keyboard_string = "";
        }

        if (_tdo) {
            if ((_trk == vk_backspace || _trk == vk_delete) && action_modal_title_sel_start != action_modal_title_sel_end) {
                var _s = min(action_modal_title_sel_start, action_modal_title_sel_end);
                var _e = max(action_modal_title_sel_start, action_modal_title_sel_end);
                action_modal_title_text = string_delete(action_modal_title_text, _s + 1, _e - _s);
                action_modal_title_caret = _s; action_modal_title_sel_start = _s; action_modal_title_sel_end = _s;
            } else {
                if (_trk == vk_left)  { action_modal_title_caret = max(0, action_modal_title_caret - 1); action_modal_title_sel_start = action_modal_title_caret; action_modal_title_sel_end = action_modal_title_caret; }
                if (_trk == vk_right) { action_modal_title_caret = min(string_length(action_modal_title_text), action_modal_title_caret + 1); action_modal_title_sel_start = action_modal_title_caret; action_modal_title_sel_end = action_modal_title_caret; }
                if (_trk == vk_backspace && action_modal_title_caret > 0) {
                    action_modal_title_text = string_delete(action_modal_title_text, action_modal_title_caret, 1);
                    action_modal_title_caret--; action_modal_title_sel_start = action_modal_title_caret; action_modal_title_sel_end = action_modal_title_caret;
                }
                if (_trk == vk_delete && action_modal_title_caret < string_length(action_modal_title_text)) {
                    action_modal_title_text = string_delete(action_modal_title_text, action_modal_title_caret + 1, 1);
                    action_modal_title_sel_start = action_modal_title_caret; action_modal_title_sel_end = action_modal_title_caret;
                }
            }
        }

        if (keyboard_check_pressed(vk_home)) { action_modal_title_caret = 0; action_modal_title_sel_start = 0; action_modal_title_sel_end = 0; }
        if (keyboard_check_pressed(vk_end))  { action_modal_title_caret = string_length(action_modal_title_text); action_modal_title_sel_start = action_modal_title_caret; action_modal_title_sel_end = action_modal_title_caret; }
        if (keyboard_check_pressed(vk_enter)) {
            var _lines = string_count("\n", action_modal_title_text);
            if (_lines < 2 && string_length(action_modal_title_text) < 100) {
                if (action_modal_title_sel_start != action_modal_title_sel_end) {
                    var _s = min(action_modal_title_sel_start, action_modal_title_sel_end);
                    var _e = max(action_modal_title_sel_start, action_modal_title_sel_end);
                    action_modal_title_text = string_delete(action_modal_title_text, _s + 1, _e - _s);
                    action_modal_title_caret = _s; action_modal_title_sel_start = _s; action_modal_title_sel_end = _s;
                }
                action_modal_title_text = string_insert("\n", action_modal_title_text, action_modal_title_caret + 1);
                action_modal_title_caret++; action_modal_title_sel_start = action_modal_title_caret; action_modal_title_sel_end = action_modal_title_caret;
            }
        }
    }

    // Special animation scrollbar drag + mouse wheel
    if (action_modal_open && action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "special animation") {
        var _sa_d4 = canned_anim_get_data(selected_character_index);
        if (_sa_d4 != undefined) {
            var _sa_rx4 = _mxo+290; var _sa_ry4 = _myo+115; var _sa_rw4 = _mw-324;
            var _sa_lh4 = _mh - 185; var _sa_stp4 = 42;
            var _sa_vis4 = floor(_sa_lh4 / _sa_stp4);
            var _sa_max4 = max(0, array_length(_sa_d4) - _sa_vis4);

            if (mouse_check_button(mb_left) && action_modal_sa_sb_drag) {
                if (_sa_max4 > 0 && _sa_lh4 > 0) {
                    var _th4 = max(20, _sa_lh4 * _sa_vis4 / array_length(_sa_d4));
                    var _raw4 = clamp(mouse_y - action_modal_sa_sb_drag_off - _sa_ry4, 0, _sa_lh4 - _th4);
                    action_modal_sa_scroll = clamp(round(_raw4 / (_sa_lh4 - _th4) * _sa_max4), 0, _sa_max4);
                }
            } else {
                if (!mouse_check_button(mb_left)) action_modal_sa_sb_drag = false;
                if (mouse_wheel_up())   action_modal_sa_scroll = max(0,        action_modal_sa_scroll - 1);
                if (mouse_wheel_down()) action_modal_sa_scroll = min(_sa_max4, action_modal_sa_scroll + 1);
            }
        }
    }
}

function step_modal_import() {
    var _mx = mouse_x; var _my = mouse_y;
    var _mw = 580; var _mh = 330;
    var _mxo = (1280 - _mw) / 2; var _myo = (800 - _mh) / 2;

    if (mouse_check_button_pressed(mb_left)) {
        // Close button
        if (_mx > _mxo + _mw - 34 && _mx < _mxo + _mw - 6 && _my > _myo + 6 && _my < _myo + 30) {
            import_modal_open = false; import_modal_status = ""; return;
        }
        // Mode tabs
        if (_my > _myo + 38 && _my < _myo + 63) {
            if (_mx > _mxo + 10 && _mx < _mxo + 100) { import_modal_mode = 0; import_modal_status = ""; keyboard_string = ""; }
            if (_mx > _mxo + 106 && _mx < _mxo + 196) { import_modal_mode = 1; import_modal_status = ""; keyboard_string = ""; }
        }

        if (import_modal_mode == 0) {
            // Browse background
            if (_mx > _mxo + _mw - 105 && _mx < _mxo + _mw - 10 && _my > _myo + 95 && _my < _myo + 120) {
                var _p = get_open_filename("Image Files|*.png;*.jpg;*.jpeg", "");
                if (_p != "") { import_modal_bg_path = _p; import_modal_status = ""; }
            }
            // Browse mask
            if (_mx > _mxo + _mw - 105 && _mx < _mxo + _mw - 10 && _my > _myo + 168 && _my < _myo + 193) {
                var _p = get_open_filename("Image Files|*.png;*.jpg;*.jpeg", "");
                if (_p != "") { import_modal_mask_path = _p; import_modal_status = ""; }
            }
            // Clear mask
            if (import_modal_mask_path != "" && _mx > _mxo + _mw - 105 && _mx < _mxo + _mw - 10 && _my > _myo + 198 && _my < _myo + 216) {
                import_modal_mask_path = ""; import_modal_status = "";
            }
            // Import button
            if (import_modal_bg_path != "" && _mx > _mxo + _mw - 105 && _mx < _mxo + _mw - 10 && _my > _myo + _mh - 55 && _my < _myo + _mh - 20) {
                var _dest_dir = datafiles_path + "scenes/";
                if (!directory_exists(_dest_dir)) directory_create(_dest_dir);
                var _bg_fname = filename_name(import_modal_bg_path);
                var _int_name = filename_change_ext(_bg_fname, "");
                file_copy(import_modal_bg_path, _dest_dir + _bg_fname);
                if (import_modal_mask_path != "") {
                    var _mask_ext = filename_ext(import_modal_mask_path);
                    file_copy(import_modal_mask_path, _dest_dir + _int_name + "_mask" + _mask_ext);
                }
                var _already = false;
                for (var s = 0; s < array_length(all_scenes); s++) {
                    if (string_lower(all_scenes[s].internal_name) == string_lower(_int_name)) { _already = true; break; }
                }
                if (!_already) {
                    var _disp = string_upper(string_char_at(_int_name, 1)) + string_copy(_int_name, 2, string_length(_int_name) - 1) + " (Custom)";
                    array_push(all_scenes, { name: _disp, internal_name: _int_name, sprite: -1, path: "scenes/" + _bg_fname, is_custom: true });
                    array_sort(all_scenes, function(a, b) { var _la = string_lower(a.name); var _lb = string_lower(b.name); return _la < _lb ? -1 : (_la > _lb ? 1 : 0); });
                }
                if (file_exists(_dest_dir + _bg_fname)) {
                    import_modal_status = "Imported!";
                    import_modal_status_ok = true;
                    import_modal_bg_path = ""; import_modal_mask_path = "";
                } else {
                    import_modal_status = "Copy failed — check file permissions.";
                    import_modal_status_ok = false;
                }
            }
        } else {
            // Browse sound
            if (_mx > _mxo + _mw - 105 && _mx < _mxo + _mw - 10 && _my > _myo + 168 && _my < _myo + 193) {
                var _p = get_open_filename("WAV Files|*.wav", "");
                if (_p != "") { import_modal_snd_path = _p; import_modal_status = ""; }
            }
            // Import button
            var _subcat = string_trim(import_modal_subcat);
            if (import_modal_snd_path != "" && string_length(_subcat) > 0
                && _mx > _mxo + _mw - 105 && _mx < _mxo + _mw - 10 && _my > _myo + _mh - 55 && _my < _myo + _mh - 20) {
                var _dest_dir = sfx_base_path + _subcat + "/";
                if (!directory_exists(_dest_dir)) directory_create(_dest_dir);
                var _snd_fname = filename_name(import_modal_snd_path);
                file_copy(import_modal_snd_path, _dest_dir + _snd_fname);
                refresh_sfx_folders();
                if (file_exists(_dest_dir + _snd_fname)) {
                    import_modal_status = "Imported!";
                    import_modal_status_ok = true;
                    import_modal_snd_path = "";
                } else {
                    import_modal_status = "Copy failed — check file permissions.";
                    import_modal_status_ok = false;
                }
            }
        }

        // Click outside to close
        if (_mx < _mxo || _mx > _mxo + _mw || _my < _myo || _my > _myo + _mh) {
            import_modal_open = false; import_modal_status = ""; return;
        }
    }

    // Subcategory text input (sound mode only) with key repeat
    if (import_modal_mode == 1) {
        var _trk = -1;
        if      (keyboard_check(vk_backspace)) _trk = vk_backspace;
        else if (keyboard_check(vk_delete))    _trk = vk_delete;
        else if (keyboard_check(vk_left))      _trk = vk_left;
        else if (keyboard_check(vk_right))     _trk = vk_right;
        var _tdo = false;
        if (_trk != -1) {
            if (keyboard_check_pressed(_trk)) { _tdo = true; import_modal_subcat_repeat_timer = 25; }
            else { import_modal_subcat_repeat_timer--; if (import_modal_subcat_repeat_timer <= 0) { _tdo = true; import_modal_subcat_repeat_timer = 2; } }
        } else { import_modal_subcat_repeat_timer = 0; }

        if (string_length(keyboard_string) > 0) {
            var _valid = "";
            for (var _ci = 1; _ci <= string_length(keyboard_string); _ci++) {
                var _ch = string_char_at(keyboard_string, _ci); var _co = ord(_ch);
                if ((_co >= 48 && _co <= 57) || (_co >= 65 && _co <= 90) || (_co >= 97 && _co <= 122) || _ch == "-" || _ch == "_") _valid += _ch;
            }
            if (string_length(_valid) > 0 && string_length(import_modal_subcat) < 40) {
                import_modal_subcat = string_insert(_valid, import_modal_subcat, import_modal_subcat_caret + 1);
                import_modal_subcat_caret += string_length(_valid);
            }
            keyboard_string = "";
        }
        if (_tdo) {
            if (_trk == vk_left)  import_modal_subcat_caret = max(0, import_modal_subcat_caret - 1);
            if (_trk == vk_right) import_modal_subcat_caret = min(string_length(import_modal_subcat), import_modal_subcat_caret + 1);
            if (_trk == vk_backspace && import_modal_subcat_caret > 0) { import_modal_subcat = string_delete(import_modal_subcat, import_modal_subcat_caret, 1); import_modal_subcat_caret--; }
            if (_trk == vk_delete && import_modal_subcat_caret < string_length(import_modal_subcat)) { import_modal_subcat = string_delete(import_modal_subcat, import_modal_subcat_caret + 1, 1); }
        }
    } else {
        import_modal_subcat_repeat_timer = 0;
    }
}
