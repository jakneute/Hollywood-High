/// @description Advanced Block Editor Logic (Fixed & Restored)
check_timer++; // Throttle timer: rate-limits disk file_exists() polls to ~10 Hz to eliminate OS spinning cursor
var _mx = mouse_x; var _my = mouse_y;
var _overlay_active = false;
var _scene = -1;
var _wrap_w = box_w - 120;

step_effects_update();

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
// Export polling — check each step until PowerShell writes the zip
if (export_state == 1 && file_exists(export_dest_path)) {
    export_state = 0;
    export_status_msg = "Exported!";
    export_status_timer = 180;
    if (file_exists(export_ps1_path)) file_delete(export_ps1_path);
}
if (export_status_timer > 0) export_status_timer--;
if (quick_save_timer > 0) quick_save_timer--;

// Ensure modals capture all input and prevent background logic from running
if (dictionary_open)       { step_modal_dictionary();  return; }

if (anim_editor_open)      { step_modal_anim_editor(); return; }

if (expr_cfg_open)         { step_modal_expr_cfg();    return; }

if (move_modal_open)       { step_modal_movement();    return; }

if (pose_expr_modal_open)  { step_modal_pose_expr();   return; }

if (action_modal_open)     { step_modal_action();      return; }
if (import_modal_open)     { step_modal_import();      return; }

// --- CHARACTER RENAME ---
if (char_rename_active) {
    if (string_length(keyboard_string) > 0) {
        char_rename_text = string_copy(char_rename_text + string_upper(keyboard_string), 1, 20);
        keyboard_string = "";
    }
    if (keyboard_check_pressed(vk_backspace) && string_length(char_rename_text) > 0)
        char_rename_text = string_delete(char_rename_text, string_length(char_rename_text), 1);

    var _rnm_ok  = keyboard_check_pressed(vk_return);
    var _rnm_off = keyboard_check_pressed(vk_escape);
    if (!_rnm_ok && !_rnm_off && mouse_check_button_pressed(mb_left)) {
        if (_mx < char_sel_x || _mx > char_sel_x + char_sel_w || _my < char_sel_y || _my > char_sel_y + char_sel_h)
            _rnm_ok = true;   // click outside pane → confirm
        else
            _rnm_off = true;  // click inside pane → cancel, let pane handle the click
    }
    if (_rnm_ok || _rnm_off) {
        if (_rnm_ok && string_length(char_rename_text) > 0) {
            var _old_nm = characters[char_rename_target].name;
            var _new_nm = string_upper(char_rename_text);
            if (_old_nm != _new_nm) {
                if (!variable_struct_exists(characters[char_rename_target], "sprite_name"))
                    characters[char_rename_target].sprite_name = _old_nm;
                characters[char_rename_target].name = _new_nm;
                for (var _ri = 0; _ri < array_length(script_blocks); _ri++) {
                    var _rb = script_blocks[_ri];
                    if (variable_struct_exists(_rb, "text") && string_pos(_old_nm, _rb.text) > 0) {
                        _rb.text = string_replace_all(_rb.text, _old_nm, _new_nm);
                        update_block_height(_ri);
                    }
                }
            }
        }
        char_rename_active = false; char_rename_target = -1;
        char_rename_text = ""; keyboard_string = "";
        if (_rnm_ok) return;
    }
}

// --- 0. SCRIPT HEIGHT CALCULATION ---
// (Now handled on-demand via update_block_height and update_all_block_heights)

step_tts_playback();

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
    var _vsl_cx = _m_x + 680; var _vsl_top = _m_y + 370; var _vsl_h = 200;
    if (mouse_check_button(mb_left) && slider_drag != 0) {
        if (slider_drag == 1) modal_pitch   = clamp(((_mx - (_m_x + 180)) / 300) * 100, 0, 100);
        if (slider_drag == 2) modal_speed   = clamp(((_mx - (_m_x + 180)) / 300) * 100, 0, 100);
        if (slider_drag == 3) modal_glottal = clamp(round(((_mx - (_m_x + 180)) / 300.0) * 6) - 1, -1, 5);
        if (slider_drag == 4) modal_volume  = clamp(round((1 - (_my - _vsl_top) / _vsl_h) * 100), 0, 100);
    }
    if (mouse_check_button_released(mb_left)) slider_drag = 0;
    if (mouse_check_button_pressed(mb_left)) {
        // Voice Selection (Compact Coordinates)
        var _cols = 4; var _bw = 170; var _bh = 45; var _gx = (_m_w - (_cols * (_bw + 15))) / 2;
        for (var i = 0; i < array_length(all_voices); i++) {
            var _bx = _m_x + _gx + ((i % _cols) * (_bw + 15));
            var _by = _m_y + 70 + (floor(i / _cols) * (_bh + 8));
            if (_mx > _bx && _mx < _bx + _bw && _my > _by && _my < _by + _bh) {
                modal_voice_id = all_voices[i].voice_id;
                tts_stop(); tts_speak("Testing voice", modal_voice_id, modal_pitch, modal_speed, modal_effort, modal_quality, modal_glottal, -1, -1, -1, -1, modal_volume);
            }
        }
        
        // Tweak Controls (Shifted Up)
        var _ctrl_y = _m_y + 360;
        if (tweak_enabled) {
            // Pitch Fine-Tuning Arrows
            if (_my > _ctrl_y - 5 && _my < _ctrl_y + 25) {
                if (_mx > _m_x + 150 && _mx < _m_x + 175) modal_pitch = max(0, modal_pitch - 5);
                if (_mx > _m_x + 485 && _mx < _m_x + 510) modal_pitch = min(100, modal_pitch + 5);
                if (_mx > _m_x + 180 && _mx < _m_x + 480) { modal_pitch = clamp(((_mx - (_m_x + 180)) / 300) * 100, 0, 100); slider_drag = 1; }
            }

            // Speed Fine-Tuning Arrows
            if (_my > _ctrl_y + 45 && _my < _ctrl_y + 75) {
                if (_mx > _m_x + 150 && _mx < _m_x + 175) modal_speed = max(0, modal_speed - 5);
                if (_mx > _m_x + 485 && _mx < _m_x + 510) modal_speed = min(100, modal_speed + 5);
                if (_mx > _m_x + 180 && _mx < _m_x + 480) { modal_speed = clamp(((_mx - (_m_x + 180)) / 300) * 100, 0, 100); slider_drag = 2; }
            }
            
            // Radio Buttons: Quality (Controls F0Style)
            if (_my > _ctrl_y + 90 && _my < _ctrl_y + 130) {
                for (var e = 0; e < 3; e++) {
                    var _ex = _m_x + 195 + (e * 105);
                    if (point_distance(_mx, _my, _ex, _ctrl_y + 108) < 16) {
                        if (e == 0) modal_quality = 0;
                        if (e == 1) modal_quality = 2;
                        if (e == 2) modal_quality = 4;
                    }
                }
            }

            // Radio Buttons: Effort (Controls VoicingMode)
            if (_my > _ctrl_y + 140 && _my < _ctrl_y + 178) {
                for (var s = 0; s < 3; s++) {
                    var _sx = _m_x + 195 + (s * 105);
                    if (point_distance(_mx, _my, _sx, _ctrl_y + 158) < 16) modal_effort = s;
                }
            }

            // Glottal slider
            if (_my > _ctrl_y + 188 && _my < _ctrl_y + 218) {
                if (_mx > _m_x + 150 && _mx < _m_x + 175) modal_glottal = max(-1, modal_glottal - 1);
                if (_mx > _m_x + 485 && _mx < _m_x + 510) modal_glottal = min(5, modal_glottal + 1);
                if (_mx > _m_x + 180 && _mx < _m_x + 480) { modal_glottal = clamp(round(((_mx - (_m_x + 180)) / 300.0) * 6) - 1, -1, 5); slider_drag = 3; }
            }
        }

        // Volume slider (always visible — outside tweak block)
        if (_mx > _vsl_cx - 18 && _mx < _vsl_cx + 18 && _my > _vsl_top - 10 && _my < _vsl_top + _vsl_h + 10) {
            modal_volume = clamp(round((1 - (_my - _vsl_top) / _vsl_h) * 100), 0, 100);
            slider_drag = 4;
        }
        
        // Advanced Tweak Toggle (Moved Lower)
        var _toggle_y = _m_y + 610;
        if (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _toggle_y && _my < _toggle_y + 25) tweak_enabled = !tweak_enabled;

        // Bottom Buttons Layout
        var _btn_y = _m_y + _m_h - 60;

        // Revert (Local Edit only) - Discard block tweaks and return to Character Globals
        if (modal_is_local_edit && _mx > _m_x + 30 && _mx < _m_x + 150 && _my > _btn_y && _my < _btn_y + 40) {
            var _b = script_blocks[modal_target_block_idx];
            var _c = characters[_b.char_index];
            modal_voice_id = _c.voice_id; modal_pitch = _c.pitch; modal_speed = _c.speed;
            modal_effort = _c.mode; modal_quality = _c.style; modal_glottal = _c[$ "glottal"] ?? -1; modal_volume = _c[$ "volume"] ?? 50; tweak_enabled = _c.tweaked;
            tts_stop();
            return;
        }

        // Test Button (X position shifts if Revert is present)
        var _tx = modal_is_local_edit ? _m_x + 165 : _m_x + 30;
        if (_mx > _tx && _mx < _tx + 120 && _my > _btn_y && _my < _btn_y + 40) { tts_stop(); tts_speak("Testing settings", modal_voice_id, modal_pitch, modal_speed, modal_effort, modal_quality, modal_glottal, -1, -1, -1, -1, modal_volume); }
        
        // Export Config (debug) — saves only the currently selected character
        if (SHOW_VOICE_CFG && !modal_is_local_edit && _mx > _m_x+_m_w-430 && _mx < _m_x+_m_w-295 && _my > _btn_y && _my < _btn_y+40) {
            var _cc = characters[selected_character_index];
            var _json = "{\n  \"" + _cc.name + "\": {";
            _json += "\"voice_id\": \"" + string(_cc.voice_id) + "\", ";
            _json += "\"pitch\": " + string(_cc.pitch) + ", ";
            _json += "\"speed\": " + string(_cc.speed) + ", ";
            _json += "\"mode\": " + string(_cc.mode) + ", ";
            _json += "\"style\": " + string(_cc.style) + ", ";
            _json += "\"tweaked\": " + (_cc.tweaked ? "true" : "false") + "}";
            _json += "\n}";
            var _f = file_text_open_write(datafiles_path + "voice_config.json");
            file_text_write_string(_f, _json);
            file_text_close(_f);
        }

        if (_mx > _m_x + _m_w - 280 && _mx < _m_x + _m_w - 150 && _my > _btn_y && _my < _btn_y + 40) {
            var _c = characters[selected_character_index];
            if (modal_is_local_edit) {
                var _b = script_blocks[modal_target_block_idx];
                _b.voice_id = modal_voice_id; _b.pitch = modal_pitch; _b.speed = modal_speed;
                _b.mode = modal_effort; _b.style = modal_quality; _b.glottal = modal_glottal; _b.volume = modal_volume; _b.tweaked = tweak_enabled;
                script_dirty = true;
                // Only mark as altered if it actually differs from character's current global
                _b.is_altered = (_b.voice_id != _c.voice_id || _b.pitch != _c.pitch || _b.speed != _c.speed || _b.mode != _c.mode || _b.style != _c.style || (_b[$ "glottal"] ?? -1) != (_c[$ "glottal"] ?? -1) || (_b[$ "volume"] ?? 50) != (_c[$ "volume"] ?? 50) || _b.tweaked != _c.tweaked);
            } else {
                _c.voice_id = modal_voice_id; _c.pitch = modal_pitch; _c.speed = modal_speed;
                _c.mode = modal_effort; _c.style = modal_quality; _c.glottal = modal_glottal; _c.volume = modal_volume; _c.tweaked = tweak_enabled;
                script_dirty = true;
                
                // Propagate the new "Global" settings to all blocks that are currently using the character default
                for (var i = 0; i < array_length(script_blocks); i++) {
                    var _block = script_blocks[i];
                    var _is_v = !variable_struct_exists(_block, "type") || _block.type == "voice";
                    if (_is_v && _block.char_index == selected_character_index) {
                        if (!variable_struct_exists(_block, "is_altered") || !_block.is_altered) {
                            _block.voice_id = _c.voice_id; _block.pitch = _c.pitch; _block.speed = _c.speed;
                            _block.mode = _c.mode; _block.style = _c.style; _block.glottal = _c[$ "glottal"] ?? -1; _block.volume = _c[$ "volume"] ?? 50; _block.tweaked = _c.tweaked;
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
    var _m_w = 700; var _m_h = 490;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    var _max_visible_h = 315;
    var _list_w = 300;
    var _list_h = array_length(scene_modal_filtered) * 40;

    // Scrollbar geometry
    var _sb_x = _m_x + 20 + _list_w + 5;
    var _sb_w = 10;
    var _sb_track_y = _m_y + 95;
    var _sb_bar_h = (_list_h > 0) ? max(20, (_max_visible_h / _list_h) * _max_visible_h) : _max_visible_h;
    var _sb_max_top = _sb_track_y + _max_visible_h - _sb_bar_h;
    var _sb_bar_y = (_list_h > 0) ? clamp(_sb_track_y + (-scene_modal_scroll_y / _list_h) * _max_visible_h, _sb_track_y, _sb_max_top) : _sb_track_y;
    var _sb_visible = (_list_h > _max_visible_h);

    if (mouse_check_button_pressed(mb_left)) {
        var _sb_clicked = false;

        // Search box: focus or clear
        var _srx2 = _m_x + 20; var _sry2 = _m_y + 58; var _srw2 = 300; var _srh2 = 28;
        if (_mx > _srx2 && _mx < _srx2 + _srw2 && _my > _sry2 && _my < _sry2 + _srh2) {
            if (_mx > _srx2 + _srw2 - 22 && scene_modal_search != "") {
                scene_modal_search = "";
                scene_modal_scroll_y = 0;
                scene_modal_filtered = [];
                for (var _fi = 0; _fi < array_length(all_scenes); _fi++) array_push(scene_modal_filtered, all_scenes[_fi]);
            }
            scene_modal_search_focused = true;
            scene_modal_caret_timer = 0;
            keyboard_string = "";
            return;
        }
        scene_modal_search_focused = false;

        // Scrollbar interaction
        if (_sb_visible && _mx >= _sb_x - 2 && _mx <= _sb_x + _sb_w + 2 && _my >= _sb_track_y && _my <= _sb_track_y + _max_visible_h) {
            _sb_clicked = true;
            if (_my >= _sb_bar_y && _my <= _sb_bar_y + _sb_bar_h) {
                scene_sb_dragging = true;
                scene_sb_drag_offset = _my - _sb_bar_y;
            } else {
                var _clicked_frac = (_my - _sb_track_y) / _max_visible_h;
                scene_modal_scroll_y = clamp(-(_clicked_frac * _list_h - _sb_bar_h / 2), -(_list_h - _max_visible_h), 0);
            }
        }

        if (!_sb_clicked) {
            // Option selection
            if (_mx > _m_x + 20 && _mx < _m_x + 20 + _list_w && _my > _m_y + 95 && _my < _m_y + 95 + _max_visible_h) {
                for (var i = 0; i < array_length(scene_modal_filtered); i++) {
                    var _by = _m_y + 95 + (i * 40) + scene_modal_scroll_y;
                    if (_my > _by && _my < _by + 35) {
                        var _data = scene_modal_filtered[i];
                        var _target_idx = scene_modal_target_index;

                        if (scene_modal_edit_mode) {
                            var _b = script_blocks[_target_idx];
                            _b.name = _data.name;
                            _b.internal_name = _data.internal_name;
                            scene_modal_edit_mode = false;
                        } else {
                            var _new_scene = { type: "scene", name: _data.name, internal_name: _data.internal_name, actors: [], height: 80, fx: "none" };
                            if (_target_idx == -1) {
                                array_push(script_blocks, _new_scene);
                                _target_idx = array_length(script_blocks) - 1;
                            } else {
                                array_insert(script_blocks, _target_idx, _new_scene);
                            }
                            script_dirty = true;
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
                scene_sb_dragging = false;
                scene_modal_open = false; insertion_idx = -1; return;
            }
        }
    }

    // Scrollbar drag
    if (scene_sb_dragging) {
        if (mouse_check_button(mb_left) && _sb_visible) {
            var _new_bar_y = clamp(_my - scene_sb_drag_offset, _sb_track_y, _sb_max_top);
            var _new_frac = (_new_bar_y - _sb_track_y) / _max_visible_h;
            scene_modal_scroll_y = clamp(-_new_frac * _list_h, -(_list_h - _max_visible_h), 0);
        } else {
            scene_sb_dragging = false;
        }
    }

    // Mouse wheel scrolling
    if (mouse_wheel_up()) scene_modal_scroll_y = min(0, scene_modal_scroll_y + 40);
    if (mouse_wheel_down()) {
        if (_list_h > _max_visible_h) scene_modal_scroll_y = max(-(_list_h - _max_visible_h), scene_modal_scroll_y - 40);
    }

    // Keyboard navigation (suppressed when search is focused)
    if (!scene_modal_search_focused) {
        var _page_size = floor(_max_visible_h / 40) * 40;
        if (keyboard_check_pressed(vk_pageup)) scene_modal_scroll_y = min(0, scene_modal_scroll_y + _page_size);
        if (keyboard_check_pressed(vk_pagedown)) {
            if (_list_h > _max_visible_h) scene_modal_scroll_y = max(-(_list_h - _max_visible_h), scene_modal_scroll_y - _page_size);
        }
        if (keyboard_check_pressed(vk_home)) scene_modal_scroll_y = 0;
        if (keyboard_check_pressed(vk_end)) {
            if (_list_h > _max_visible_h) scene_modal_scroll_y = -(_list_h - _max_visible_h);
        }
    }

    // Search keyboard input
    if (scene_modal_search_focused) {
        scene_modal_caret_timer++;
        var _search_changed = false;
        if (string_length(keyboard_string) > 0) {
            scene_modal_search += keyboard_string;
            keyboard_string = "";
            _search_changed = true;
        }
        if (keyboard_check_pressed(vk_backspace) && string_length(scene_modal_search) > 0) {
            scene_modal_search = string_copy(scene_modal_search, 1, string_length(scene_modal_search) - 1);
            _search_changed = true;
        }
        if (keyboard_check(vk_backspace)) {
            scene_modal_bksp_held++;
            if (scene_modal_bksp_held >= 45 && scene_modal_search != "") {
                scene_modal_search = "";
                scene_modal_bksp_held = 0;
                _search_changed = true;
            }
        } else { scene_modal_bksp_held = 0; }
        if (_search_changed) {
            scene_modal_scroll_y = 0;
            scene_modal_filtered = [];
            var _sq_up = string_upper(scene_modal_search);
            for (var _fi = 0; _fi < array_length(all_scenes); _fi++) {
                if (_sq_up == "" || string_pos(_sq_up, string_upper(all_scenes[_fi].name)) > 0)
                    array_push(scene_modal_filtered, all_scenes[_fi]);
            }
        }
    }

    return;
}

// --- EXIT INTERCEPT ---
if (keyboard_check_pressed(vk_f4) && keyboard_check(vk_alt)) {
    if (!script_dirty || show_question("You have unsaved changes. Exit anyway?")) game_end();
    return;
}

// --- QUICK SAVE (Ctrl+S) ---
if (keyboard_check(vk_control) && keyboard_check_pressed(ord("S")) && current_script_path != "") {
    var _save_data = { version: 2, script: script_blocks, chars: characters, dict: dictionary_list };
    var _json = json_stringify(_save_data);
    var _buf = buffer_create(string_byte_length(_json) + 1, buffer_fixed, 1);
    buffer_write(_buf, buffer_string, _json);
    buffer_seek(_buf, buffer_seek_start, 0);
    var _cbuf = buffer_compress(_buf, 0, buffer_get_size(_buf));
    buffer_save(_cbuf, current_script_path);
    buffer_delete(_buf); buffer_delete(_cbuf);
    script_dirty = false;
    quick_save_timer = 180; // 3 seconds — reset on hammer, no stacking
}

// --- 2c2. FILE MENU ---
if (file_menu_open) {
    if (mouse_check_button_pressed(mb_left)) {
        var _fm_x = 10; var _fm_y = 45; var _fm_w = 165; var _fm_h = 210;
        var _clicked_option = false;

        // ── NEW SCRIPT ──
        if (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y && _my < _fm_y + 35) {
            var _proceed = true;
            if (script_dirty) _proceed = show_question("You have unsaved changes. Start a new script anyway?");
            if (_proceed) {
                tts_stop(); script_blocks = []; current_script_path = "";
                focused_block = -1; playing_block_index = -1; playing_linked_index = -1;
                scene_edit_mode = false; insertion_idx = -1; block_scroll_y = 0;
                is_speaking = false; audio_stop_all();
                preview_actors = []; current_scene_sprite = -1; set_scene_dimensions(-1);
                script_dirty = false;
            }
            _clicked_option = true;

        // ── SAVE SCRIPT ──
        } else if (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y + 35 && _my < _fm_y + 70) {
            var _default = (current_script_path != "") ? current_script_path : working_directory + "screenplay.hhi";
            var _file = get_save_filename("Hollywood High Script|*.hhi", _default);
            if (_file != "") {
                current_script_path = _file;
                var _save_data = { version: 2, script: script_blocks, chars: characters, dict: dictionary_list };
                var _json = json_stringify(_save_data);
                var _buf = buffer_create(string_byte_length(_json) + 1, buffer_fixed, 1);
                buffer_write(_buf, buffer_string, _json);
                buffer_seek(_buf, buffer_seek_start, 0);
                var _cbuf = buffer_compress(_buf, 0, buffer_get_size(_buf));
                buffer_save(_cbuf, _file);
                buffer_delete(_buf); buffer_delete(_cbuf);
                script_dirty = false;
            }
            _clicked_option = true;

        // ── LOAD SCRIPT ──
        } else if (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y + 70 && _my < _fm_y + 105) {
            var _load_proceed = !script_dirty || show_question("You have unsaved changes. Load a different script anyway?");
            var _file = _load_proceed ? get_open_filename("Hollywood High Script|*.hhi", current_script_path) : "";
            if (_file != "" && file_exists(_file)) {
                current_script_path = _file;
                try {
                    var _buf = buffer_load(_file);
                    var _dbuf = buffer_decompress(_buf);
                    var _json = buffer_read(_dbuf, buffer_string);
                    buffer_delete(_buf); buffer_delete(_dbuf);
                    var _loaded = json_parse(_json);
                    if (is_array(_loaded)) script_blocks = _loaded;
                    else if (is_struct(_loaded)) {
                        if (variable_struct_exists(_loaded, "script")) script_blocks   = _loaded.script;
                        if (variable_struct_exists(_loaded, "chars"))  characters      = _loaded.chars;
                        if (variable_struct_exists(_loaded, "dict"))   dictionary_list = _loaded.dict;
                    }
                    // Re-initialise runtime arrays so sizes match the loaded character list
                    char_facings         = array_create(array_length(characters), 1);
                    char_sel_layer_cache = array_create(array_length(characters), undefined);
                    // Clear sprite caches — forces reload under each character's correct name/sprite_name
                    ds_map_clear(char_sprites);
                    ds_map_clear(char_offsets_cache);
                    ds_map_clear(char_expr_cache);
                    ds_map_clear(mouth_anim_cache);
                    update_all_block_heights();
                    focused_block = -1; playing_block_index = -1; playing_linked_index = -1;
                    scene_edit_mode = false; insertion_idx = -1;
                    selection_start = 0; selection_end = 0; is_selecting = false;
                    is_speaking = false; audio_stop_all(); tts_stop(); block_scroll_y = 0;
                    if (array_length(script_blocks) > 0) { play_from_index(0); playing_block_index = -1; }
                    else { preview_actors = []; current_scene_sprite = -1; set_scene_dimensions(-1); }
                } catch(_e) { show_message("Error loading script file! Invalid format."); }
                script_dirty = false;
            }
            _clicked_option = true;

        // ── SAVE SCREENPLAY (export-only text file) ──
        } else if (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y + 105 && _my < _fm_y + 140) {
            var _file = get_save_filename("Screenplay Text|*.txt|Fountain Format|*.fountain", working_directory + "screenplay.txt");
            if (_file != "") {
                var _sf = file_text_open_write(_file);
                if (_sf != -1) {
                    file_text_write_string(_sf, "FADE IN:\n\n\n");
                    for (var _bi = 0; _bi < array_length(script_blocks); _bi++) {
                        var _bl = script_blocks[_bi];
                        var _btype = variable_struct_exists(_bl, "type") ? _bl.type : "voice";

                        if (_btype == "scene") {
                            file_text_write_string(_sf, "SCENE: " + string_upper(_bl.name) + "\n\n");

                        } else if (_btype == "action") {
                            if (variable_struct_exists(_bl, "offscreen_pre") && _bl.offscreen_pre) continue;
                            var _aname = _bl.action_name;
                            var _aname_u = string_upper(_aname);
                            var _cn = (variable_struct_exists(_bl, "char_index") && _bl.char_index >= 0 && _bl.char_index < array_length(characters))
                                      ? characters[_bl.char_index].name : "";
                            if (string_pos("WAIT", _aname_u) > 0) {
                                // Silent pause — omit from screenplay prose
                            } else if (string_pos("PLAY SFX", _aname_u) > 0) {
                                var _sfx = variable_struct_exists(_bl, "sfx_path") ? _bl.sfx_path : "";
                                file_text_write_string(_sf, "(SOUND EFFECT: " + _sfx + ")\n\n");
                            } else if (string_pos("DISPLAY TITLE", _aname_u) > 0) {
                                var _ttl = variable_struct_exists(_bl, "title_text") ? _bl.title_text : "";
                                if (_ttl != "") file_text_write_string(_sf, "                    TITLE CARD: \"" + _ttl + "\"\n\n");
                            } else if (string_pos("RESURRECTS", _aname_u) > 0) {
                                // Resurrection — omit from screenplay prose
                            } else {
                                // Character action — build a readable sentence
                                var _aname_lo = string_lower(_aname);
                                var _display_aname = _aname;
                                if (string_pos("looks ", _aname_lo) > 0 && string_pos(" and pose ", _aname_lo) > 0) {
                                    var _ap2 = string_pos(" and pose ", _aname_lo);
                                    var _pn2 = real(string_copy(_aname_lo, _ap2 + 10, 1));
                                    _display_aname = string_copy(_aname, 1, _ap2 - 1) + ", " + get_pose_label(_bl.char_index, _pn2);
                                } else if (string_pos("pose ", _aname_lo) > 0 && string_pos("poses ", _aname_lo) == 0) {
                                    var _pn2 = real(string_copy(_aname_lo, string_pos("pose ", _aname_lo) + 5, 1));
                                    _display_aname = get_pose_label(_bl.char_index, _pn2);
                                }
                                if (string_pos("FELL FORWARDS", _aname_u) > 0)  _display_aname = "falls forwards";
                                else if (string_pos("FELL BACKWARDS", _aname_u) > 0) _display_aname = "falls backwards";
                                var _sent = _cn + " " + _display_aname;
                                _sent = string_upper(string_char_at(_sent, 1)) + string_copy(_sent, 2, string_length(_sent) - 1);
                                var _lc = string_char_at(_sent, string_length(_sent));
                                if (_lc != "." && _lc != "!" && _lc != "?") _sent += ".";
                                file_text_write_string(_sf, _sent + "\n\n");
                            }

                        } else if (_btype == "voice") {
                            // Voice / dialogue block
                            var _cn = (variable_struct_exists(_bl, "char_index") && _bl.char_index >= 0 && _bl.char_index < array_length(characters))
                                      ? characters[_bl.char_index].name : "UNKNOWN";
                            var _txt = variable_struct_exists(_bl, "text") ? _bl.text : "";
                            if (string_length(_txt) > 0) {
                                if (_cn == "NARRATOR") {
                                    // Narration reads as plain action prose
                                    file_text_write_string(_sf, _txt + "\n\n");
                                } else {
                                    // Character name, then indented dialogue (indent each line)
                                    file_text_write_string(_sf, "                      " + _cn + "\n");
                                    var _dlines = string_split(_txt, "\n");
                                    for (var _dli = 0; _dli < array_length(_dlines); _dli++) {
                                        file_text_write_string(_sf, "            " + _dlines[_dli] + "\n");
                                    }
                                    file_text_write_string(_sf, "\n");
                                }
                            }
                        }
                    }
                    file_text_write_string(_sf, "\n\nFADE OUT.\n\nTHE END\n");
                    file_text_close(_sf);
                }
            }
            _clicked_option = true;

        // ── IMPORT ASSETS ──
        } else if (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y + 140 && _my < _fm_y + 175) {
            import_modal_open = true;
            import_modal_mode = 0;
            import_modal_bg_path = ""; import_modal_mask_path = ""; import_modal_snd_path = "";
            import_modal_status = ""; keyboard_string = "";
            _clicked_option = true;

        // ── EXPORT SCRIPT ──
        } else if (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y + 175 && _my < _fm_y + 210) {
            do_export_script();
            _clicked_option = true;
        }

        file_menu_open = false;
        if (_clicked_option) return;
    }
}

// Theater auto-hide timer — must run every step, not inside a click check
if (theater_mode) {
    if (_mx != theater_ui_last_mx || _my != theater_ui_last_my || theater_paused) {
        theater_ui_timer = 120;
    } else if (theater_ui_timer > 0) {
        theater_ui_timer--;
    }
    theater_ui_last_mx = _mx; theater_ui_last_my = _my;

    // Spacebar: play/pause shortcut
    if (keyboard_check_pressed(vk_space)) {
        if (playing_block_index == -1) {
            play_from_index(0);
            theater_paused = false;
            theater_ui_timer = 0;
        } else {
            theater_paused = !theater_paused;
            if (theater_paused) {
                theater_was_mid_speech = is_speaking;
                audio_stop_all(); tts_stop(); is_speaking = false;
            } else {
                speaking_pause_timer = theater_was_mid_speech ? -1 : 0;
                theater_ui_timer = 0;
            }
        }
    }
}

// --- 2c. SCRIPT EDITOR KEYBOARD NAVIGATION (PgUp/PgDown/Home/End) ---
{
    var _no_modal   = !file_menu_open && !edit_mode && !scene_modal_open && !theater_mode;
    var _not_typing = (focused_block == -1 || focused_block >= array_length(script_blocks)
                       || !variable_struct_exists(script_blocks[focused_block], "type")
                       || script_blocks[focused_block].type != "voice");
    if (_no_modal && playing_block_index == -1 && array_length(script_blocks) > 0) {
        var _total_h = 0;
        for (var _ni = 0; _ni < array_length(script_blocks); _ni++) _total_h += script_blocks[_ni].height + 20;
        var _max_scroll = min(0, box_h - 40 - _total_h);

        // Home/End — single press only
        if (_not_typing) {
            if (keyboard_check_pressed(vk_home)) { block_scroll_y = 0;           focused_block = 0; }
            else if (keyboard_check_pressed(vk_end))  { block_scroll_y = _max_scroll; focused_block = array_length(script_blocks) - 1; }
        }

        // Nav button geometry
        var _nb_x   = box_x + box_w + 5; var _nb_w   = 38;
        var _nb_h   = 26;                 var _nb_gap = 5;
        var _nb_y0  = box_y + (box_h - (4 * _nb_h + 3 * _nb_gap)) / 2;
        var _nav_full_h     = _total_h;
        var _nav_can_scroll = (_nav_full_h > box_h - 20);
        var _nav_max_scroll = _nav_can_scroll ? (-(_nav_full_h + box_h / 2 - (box_h - 20))) : 0;
        var _at_top    = !_nav_can_scroll || block_scroll_y >= 0;
        var _at_bottom = !_nav_can_scroll || block_scroll_y <= _nav_max_scroll;

        // PgUp/PgDown: keyboard OR nav buttons 1/2 — both support hold-to-repeat
        var _pgup_y  = _nb_y0 + (_nb_h + _nb_gap);
        var _pgdn_y  = _nb_y0 + 2 * (_nb_h + _nb_gap);
        var _mb_held = mouse_check_button(mb_left) && !_overlay_active && _mx >= _nb_x && _mx <= _nb_x + _nb_w;
        var _pgup_btn = _mb_held && _my >= _pgup_y && _my <= _pgup_y + _nb_h;
        var _pgdn_btn = _mb_held && _my >= _pgdn_y && _my <= _pgdn_y + _nb_h;
        var _pgup_key = _not_typing && keyboard_check(vk_pageup);
        var _pgdn_key = _not_typing && keyboard_check(vk_pagedown);
        if (!variable_instance_exists(id, "nav_hold_timer")) nav_hold_timer = 0;
        if (_pgup_btn || _pgdn_btn || _pgup_key || _pgdn_key) {
            nav_hold_timer++;
            var _first = keyboard_check_pressed(vk_pageup) || keyboard_check_pressed(vk_pagedown)
                      || (mouse_check_button_pressed(mb_left) && (_pgup_btn || _pgdn_btn));
            if (_first || (nav_hold_timer > 22 && nav_hold_timer mod 10 == 0)) {
                if ((_pgup_btn || _pgup_key) && !_at_top)    block_scroll_y = min(0, block_scroll_y + box_h);
                if ((_pgdn_btn || _pgdn_key) && !_at_bottom) block_scroll_y = max(_nav_max_scroll, block_scroll_y - box_h);
            }
        } else { nav_hold_timer = 0; }

        // Nav buttons 0 and 3 (jump to top/bottom) — single press only
        if (mouse_check_button_pressed(mb_left) && !_overlay_active && _mx >= _nb_x && _mx <= _nb_x + _nb_w) {
            var _top_y = _nb_y0;
            var _end_y = _nb_y0 + 3 * (_nb_h + _nb_gap);
            if (_my >= _top_y && _my <= _top_y + _nb_h && !_at_top)    { block_scroll_y = 0;             focused_block = 0; }
            if (_my >= _end_y && _my <= _end_y + _nb_h && !_at_bottom) { block_scroll_y = _nav_max_scroll; focused_block = array_length(script_blocks) - 1; }
        }
    }
}

// --- EXPAND/COLLAPSE TOGGLE ---
if (mouse_check_button_pressed(mb_left)) {
    if (script_expanded) {
        if (_mx > box_x+box_w-98 && _mx < box_x+box_w-6 && _my > 30 && _my < 60) {
            script_expanded = false; block_scroll_y = 0; return;
        }
    } else {
        var _exp_x = btn_play_x + btn_play_w + 12;
        if (_mx > _exp_x && _mx < _exp_x + 92 && _my > btn_play_y && _my < btn_play_y + btn_play_h) {
            script_expanded = true; block_scroll_y = 0;
            dragging_char_index = -1; dragging_actor_idx = -1;
            scene_edit_mode = false;
            insertion_idx = -1;
            particle_edit_mode = false;
            particle_drag_pos = false; particle_drag_dir = false;
            particle_drag_area_w = false; particle_drag_area_h = false;
            dragging_particle_effect = "";
            return;
        }
    }
}

// --- 2d. CHARACTER SELECTOR CLICKS & DRAGS ---
if (!script_expanded && mouse_check_button_pressed(mb_left)) {
    // Block interaction if any modal is open
    _overlay_active = (file_menu_open || edit_mode || scene_modal_open || action_modal_open || theater_mode || move_modal_open || pose_modal_open || expression_modal_open || pose_expr_modal_open);

    if (!_overlay_active && !particle_panel_mode && playing_block_index == -1 && _mx > char_sel_x && _mx < char_sel_x + char_sel_w && _my > char_sel_y && _my < char_sel_y + char_sel_h) {

        selection_start = 0; selection_end = 0;
        var _grid_x = char_sel_x + 10;
        var _grid_y = char_sel_y + 35;
        var _item_w = 165;
        var _item_h = 135;
        var _cols = 2;
        for (var i = 0; i < array_length(characters); i++) {
            var _ix = _grid_x + (i % _cols) * _item_w;
            var _iy = _grid_y + floor(i / _cols) * _item_h + char_sel_scroll_y;
            if (_my > char_sel_y + 30 && _mx > _ix && _mx < _ix + _item_w && _my > _iy && _my < _iy + _item_h) {
                var _was_sel = (i == selected_character_index);
                selected_character_index = i;
                dropdown_open = false;
                if (_was_sel && characters[i].name != "NARRATOR" && playing_block_index == -1 &&
                    _mx > _ix + _item_w - 18 && _my > _iy + _item_h - 22 && _my < _iy + _item_h - 6) {
                    char_rename_active = true; char_rename_target = i;
                    char_rename_text = characters[i].name; keyboard_string = "";
                    return;
                }
                if (!particle_edit_mode) {
                    dragging_char_index = i; // Unified drag start — not available in particle edit mode

                    // Sync staging selection: focus character if they are in the scene, otherwise clear focus
                    if (scene_edit_mode && active_scene_block_idx != -1) {
                        _scene = script_blocks[active_scene_block_idx];
                        var _found = -1;
                        for (var a = 0; a < array_length(_scene.actors); a++) {
                            if (_scene.actors[a].char_index == i) { _found = a; break; }
                        }
                        scene_edit_selected_actor_idx = _found;
                    }
                }
                return;
            }
        }
    }
}

// Reset staging injury defaults when scene changes — injuries don't carry between scenes
if (active_scene_block_idx != prev_active_scene_block_idx) {
    char_entry_knock_state      = array_create(22, 0);
    char_entry_decap_state      = array_create(22, 0);
    char_entry_foreground       = array_create(22, false);
    prev_active_scene_block_idx = active_scene_block_idx;
}
// --- SCALE PANEL INTERACTION (staging + off-stage entry scale, mutually exclusive with particle edit) ---
if (particle_edit_mode || current_scene_sprite == -1
    || (selected_character_index != -1 && characters[selected_character_index].name == "NARRATOR")) staging_scale_drag = false;
var _sp2_sel_visible = false;
if (selected_character_index != -1) {
    for (var _svi2 = 0; _svi2 < array_length(preview_actors); _svi2++) {
        if (preview_actors[_svi2].char_index == selected_character_index
            && !(variable_struct_exists(preview_actors[_svi2], "hidden") && preview_actors[_svi2].hidden)) {
            _sp2_sel_visible = true; break;
        }
    }
}
if (selected_character_index != -1 && !particle_edit_mode && !theater_mode && playing_block_index == -1
    && current_scene_sprite != -1 && characters[selected_character_index].name != "NARRATOR"
    && (scene_edit_mode || !_sp2_sel_visible)) {
    var _sp2_act_idx = -1;
    for (var _spi2 = 0; _spi2 < array_length(preview_actors); _spi2++) {
        if (preview_actors[_spi2].char_index == selected_character_index) { _sp2_act_idx = _spi2; break; }
    }
    var _sp2_on_right = (_sp2_act_idx == -1) || (preview_actors[_sp2_act_idx].x < scene_win_w * 0.5);
    var _sp2_pw = 48; var _sp2_ph = 220;
    var _sp2_px = _sp2_on_right ? (scene_win_x + scene_win_w - _sp2_pw - 4) : (scene_win_x + 4);
    var _sp2_py = scene_win_y + (scene_win_h - _sp2_ph) / 2;
    var _sp2_cx = _sp2_px + _sp2_pw / 2;
    var _sp2_track_top = _sp2_py + 30;
    var _sp2_track_bot = _sp2_py + _sp2_ph - 46;
    var _sp2_track_h   = _sp2_track_bot - _sp2_track_top;
    var _sp2_rst_y = _sp2_py + _sp2_ph - 36;
    // Start drag on press in track area
    if (mouse_check_button_pressed(mb_left)) {
        if (_mx > _sp2_px && _mx < _sp2_px + _sp2_pw && _my > _sp2_track_top - 12 && _my < _sp2_track_bot + 12) {
            staging_scale_drag = true;
        }
        // RST button
        if (_mx > _sp2_px + 4 && _mx < _sp2_px + _sp2_pw - 4 && _my > _sp2_rst_y && _my < _sp2_rst_y + 22) {
            char_entry_scales[selected_character_index] = 1.0;
            if (scene_edit_mode && _sp2_act_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                var _sp2_sb = script_blocks[active_scene_block_idx];
                if (variable_struct_exists(_sp2_sb, "actors")) {
                    for (var _sp2_ai = 0; _sp2_ai < array_length(_sp2_sb.actors); _sp2_ai++) {
                        if (_sp2_sb.actors[_sp2_ai].char_index == selected_character_index) { _sp2_sb.actors[_sp2_ai].scale = 1.0; break; }
                    }
                }
            }
        }
    }
    // Active drag
    if (staging_scale_drag) {
        if (mouse_check_button(mb_left)) {
            var _sp2_t = clamp((_sp2_track_bot - _my) / _sp2_track_h, 0, 1);
            var _sp2_new = round(lerp(0.10, 5.0, _sp2_t) * 100) / 100;
            char_entry_scales[selected_character_index] = _sp2_new;
            if (scene_edit_mode && _sp2_act_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                var _sp2_sb = script_blocks[active_scene_block_idx];
                if (variable_struct_exists(_sp2_sb, "actors")) {
                    for (var _sp2_ai = 0; _sp2_ai < array_length(_sp2_sb.actors); _sp2_ai++) {
                        if (_sp2_sb.actors[_sp2_ai].char_index == selected_character_index) { _sp2_sb.actors[_sp2_ai].scale = _sp2_new; break; }
                    }
                }
            }
        } else {
            staging_scale_drag = false;
        }
    }
    // Arrow key fine adjust when slider is hovered or being dragged
    var _sp2_hover = (_mx > _sp2_px && _mx < _sp2_px + _sp2_pw && _my > _sp2_track_top - 12 && _my < _sp2_track_bot + 12);
    if (staging_scale_drag || _sp2_hover || scene_edit_mode) {
        var _sp2_kup = keyboard_check(vk_up);
        var _sp2_kdn = keyboard_check(vk_down);
        if (_sp2_kup || _sp2_kdn) {
            scale_key_repeat_timer++;
            if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(vk_down) || scale_key_repeat_timer >= 20) {
                if (scale_key_repeat_timer >= 20) scale_key_repeat_timer = 17;
                var _sp2_kval = clamp(round((char_entry_scales[selected_character_index] + (_sp2_kup ? 0.01 : -0.01)) * 100) / 100, 0.10, 5.0);
                char_entry_scales[selected_character_index] = _sp2_kval;
                if (scene_edit_mode && _sp2_act_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                    var _sp2_ksb = script_blocks[active_scene_block_idx];
                    if (variable_struct_exists(_sp2_ksb, "actors")) {
                        for (var _sp2_kai = 0; _sp2_kai < array_length(_sp2_ksb.actors); _sp2_kai++) {
                            if (_sp2_ksb.actors[_sp2_kai].char_index == selected_character_index) { _sp2_ksb.actors[_sp2_kai].scale = _sp2_kval; break; }
                        }
                    }
                }
            }
        } else {
            scale_key_repeat_timer = 0;
        }
    }
    // Injury state panel click (staging mode only)
    if (scene_edit_mode && mouse_check_button_pressed(mb_left)) {
        var _inj_pw2 = 72; var _inj_ph2 = 252;
        var _inj_px2 = _sp2_on_right ? (_sp2_px - _inj_pw2 - 4) : (_sp2_px + _sp2_pw + 4);
        var _inj_py2 = scene_win_y + (scene_win_h - _inj_ph2) / 2;
        var _inj_ci2 = selected_character_index;
        for (var _fi2 = 0; _fi2 < 3; _fi2++) {
            var _fy2 = _inj_py2 + 42 + _fi2 * 24;
            if (_mx > _inj_px2 + 2 && _mx < _inj_px2 + _inj_pw2 - 2 && _my > _fy2 && _my < _fy2 + 18) {
                char_entry_knock_state[_inj_ci2] = _fi2;
                if (scene_edit_mode && _sp2_act_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                    var _inj_sb = script_blocks[active_scene_block_idx];
                    if (variable_struct_exists(_inj_sb, "actors")) {
                        for (var _inj_ai = 0; _inj_ai < array_length(_inj_sb.actors); _inj_ai++) {
                            if (_inj_sb.actors[_inj_ai].char_index == _inj_ci2) {
                                var _inj_sa = _inj_sb.actors[_inj_ai];
                                if (_fi2 == 0) {
                                    _inj_sa.is_knocked_down = false;
                                } else {
                                    _inj_sa.is_knocked_down = true;
                                    _inj_sa.knock_direction = (_fi2 == 1) ? "forwards" : "backwards";
                                    var _inj_kface = variable_struct_exists(preview_actors[_sp2_act_idx], "facing") ? preview_actors[_sp2_act_idx].facing : 1;
                                    _inj_sa.knock_angle = (_inj_sa.knock_direction == "forwards") ? (_inj_kface * 90) : (-_inj_kface * 90);
                                }
                                break;
                            }
                        }
                    }
                }
            }
        }
        for (var _di2 = 0; _di2 < 3; _di2++) {
            var _dy2 = _inj_py2 + 136 + _di2 * 24;
            if (_mx > _inj_px2 + 2 && _mx < _inj_px2 + _inj_pw2 - 2 && _my > _dy2 && _my < _dy2 + 18) {
                char_entry_decap_state[_inj_ci2] = _di2;
                if (scene_edit_mode && _sp2_act_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                    var _inj_sb2 = script_blocks[active_scene_block_idx];
                    if (variable_struct_exists(_inj_sb2, "actors")) {
                        for (var _inj_ai2 = 0; _inj_ai2 < array_length(_inj_sb2.actors); _inj_ai2++) {
                            if (_inj_sb2.actors[_inj_ai2].char_index == _inj_ci2) {
                                var _inj_sa2 = _inj_sb2.actors[_inj_ai2];
                                if (_di2 == 0) {
                                    _inj_sa2.is_decapitated = false;
                                } else {
                                    _inj_sa2.is_decapitated = true;
                                    _inj_sa2.decap_mode = (_di2 == 1) ? "remove_head" : "remove_body";
                                }
                                break;
                            }
                        }
                    }
                }
            }
        }
        // FG toggle
        var _fgy2 = _inj_py2 + 224;
        if (_mx > _inj_px2 + 2 && _mx < _inj_px2 + _inj_pw2 - 2 && _my > _fgy2 && _my < _fgy2 + 18) {
            char_entry_foreground[_inj_ci2] = !char_entry_foreground[_inj_ci2];
            if (_sp2_act_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                var _fg_sb = script_blocks[active_scene_block_idx];
                if (variable_struct_exists(_fg_sb, "actors")) {
                    for (var _fg_ai = 0; _fg_ai < array_length(_fg_sb.actors); _fg_ai++) {
                        if (_fg_sb.actors[_fg_ai].char_index == _inj_ci2) {
                            _fg_sb.actors[_fg_ai].is_foreground = char_entry_foreground[_inj_ci2];
                            break;
                        }
                    }
                }
            }
        }
    }
}

// --- 2e. IN-SCENE DRAGGING & DROPPING ---
if (playing_block_index == -1 && scene_edit_mode && !fx_picker_open && !trans_in_picker_open && !trans_out_picker_open && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
    _scene = script_blocks[active_scene_block_idx];

    // Start dragging actor already in scene / or just Click to open menu
    if (mouse_check_button_pressed(mb_left)) {
        if (_mx > scene_win_x && _mx < scene_win_x + scene_win_w && _my > scene_win_y && _my < scene_win_y + scene_win_h) {
            for (var a = array_length(_scene.actors) - 1; a >= 0; a--) {
                var _act = _scene.actors[a];
                var _tl = get_composite_character_sprite(_act.char_index, variable_struct_exists(_act, "pose") ? _act.pose : 1, variable_struct_exists(_act, "expression") ? _act.expression : 21, variable_struct_exists(_act, "facing") ? _act.facing : undefined);
                var _spr = _tl[0].spr;
                if (_spr != -1) {
                    var _ax = scene_win_x + _act.x;
                    var _ay = scene_win_y + _act.y;
                    // Use get_actor_bbox so knocked-down rotation is accounted for
                    var _pa_inj2 = _act;
                    for (var _paj2 = 0; _paj2 < array_length(preview_actors); _paj2++) {
                        if (preview_actors[_paj2].char_index == _act.char_index) { _pa_inj2 = preview_actors[_paj2]; break; }
                    }
                    var _scale = (scene_win_h * 1.5) / 450 * (_pa_inj2[$ "scale"] ?? 1.0);
                    var _hbox = get_actor_bbox(_tl, _scale, _ax, _ay, _pa_inj2);
                    if (_mx > _hbox.bb_left && _mx < _hbox.bb_right && _my > _hbox.bb_top && _my < _hbox.bb_bottom) {
                        // Select on click regardless of injury
                        scene_edit_selected_actor_idx = a;
                        selected_character_index = _act.char_index;
                        if (particle_panel_mode) particle_panel_mode = false;

                        // Auto-scroll character pane
                        var _row = floor(selected_character_index / 2);
                        var _iy = _row * 135;
                        if (_iy + char_sel_scroll_y < 0) char_sel_scroll_y = -_iy;
                        else if (_iy + 135 + char_sel_scroll_y > char_sel_h - 35) char_sel_scroll_y = -( _iy - (char_sel_h - 170) );

                        // Injured actors cannot be dragged
                        var _inj_pa = _pa_inj2;
                        var _is_inj_drag = (variable_struct_exists(_inj_pa, "is_knocked_down") && _inj_pa.is_knocked_down)
                                        || (variable_struct_exists(_inj_pa, "is_decapitated")  && _inj_pa.is_decapitated);
                        if (!_is_inj_drag) {
                            dragging_actor_idx = a;
                            drag_start_x = _act.x;
                            drag_start_y = _act.y;
                            drag_off_x = _mx - _ax;
                            drag_off_y = _my - _ay;
                        }
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

            // Only update if mouse is inside the scene window; toolbar clicks can't drag actors off-screen
            if (_my >= scene_win_y) {
                _act.x = _mx - scene_win_x - drag_off_x;
                _act.y = _my - scene_win_y - drag_off_y;
            }

            // Removed clamps: Characters can turn red and be removed if out of bounds
        } else {
            var _act = _scene.actors[dragging_actor_idx];
            var _pose = variable_struct_exists(_act, "pose") ? _act.pose : 1;
            var _expr = variable_struct_exists(_act, "expression") ? _act.expression : 21;
            var _face = variable_struct_exists(_act, "facing") ? _act.facing : 1;
            var _layers = get_composite_character_sprite(_act.char_index, _pose, _expr, _face);
            if (_layers[0].spr != -1) {
                var _ax_abs = scene_win_x + _act.x;
                var _ay_abs = scene_win_y + _act.y;
                // Find live preview_actors entry for injury state
                var _pa_inj = {};
                for (var _paj = 0; _paj < array_length(preview_actors); _paj++) {
                    if (preview_actors[_paj].char_index == _act.char_index) { _pa_inj = preview_actors[_paj]; break; }
                }
                var _sc = (scene_win_h * 1.5) / 450 * (_pa_inj[$ "scale"] ?? (_act[$ "scale"] ?? 1.0));
                var _bbox = get_actor_bbox(_layers, _sc, _ax_abs, _ay_abs, _pa_inj);
                var _bb_w = _bbox.bb_right - _bbox.bb_left;
                var _bb_h = _bbox.bb_bottom - _bbox.bb_top;
                var _h_visible = max(0, min(_bbox.bb_right, scene_win_x + scene_win_w) - max(_bbox.bb_left, scene_win_x));
                var _v_visible = max(0, min(_bbox.bb_bottom, scene_win_y + scene_win_h) - max(_bbox.bb_top, scene_win_y));
                // Cap at 80px so large-scale actors (200%+) whose bbox extends outside scene don't get deleted
                var _in_live = (current_scene_sprite != -1) && (_h_visible >= min(_bb_w * 0.20, 80)) && (_v_visible >= min(_bb_h * 0.20, 80));

                if (!_in_live) {
                    array_delete(_scene.actors, dragging_actor_idx, 1);
                } else {
                    scene_edit_selected_actor_idx = dragging_actor_idx;
                }
            }
            dragging_actor_idx = -1;
        }
    }
}

// --- 3d. FLIP FACING BUTTON ---
if (!script_expanded && playing_block_index == -1 && current_scene_sprite != -1 && mouse_check_button_pressed(mb_left)) {
    var _flip_act_idx = -1;
    for (var _fci = 0; _fci < array_length(preview_actors); _fci++) {
        if (preview_actors[_fci].char_index == selected_character_index) { _flip_act_idx = _fci; break; }
    }
    if (_flip_act_idx != -1) {
        var _btn_w = 128; var _btn_h = 24;
        var _btn_x = scene_win_x + (scene_win_w / 2) - (_btn_w / 2);
        var _btn_y = scene_win_y + scene_win_h + 5;
        var _flip_blocked = (file_menu_open || edit_mode || scene_modal_open || action_modal_open || theater_mode || move_modal_open || pose_modal_open || expression_modal_open || pose_expr_modal_open || fx_picker_open);
        if (!_flip_blocked && _mx > _btn_x && _mx < _btn_x + _btn_w && _my > _btn_y && _my < _btn_y + _btn_h) {
            if (scene_edit_mode && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
                // Staging: flip actor facing in scene block data
                var _s = script_blocks[active_scene_block_idx];
                for (var _ai = 0; _ai < array_length(_s.actors); _ai++) {
                    if (_s.actors[_ai].char_index == selected_character_index) {
                        if (!variable_struct_exists(_s.actors[_ai], "facing")) _s.actors[_ai].facing = 1;
                        _s.actors[_ai].facing *= -1;
                        var _pa = preview_actors[_flip_act_idx];
                        _pa.facing = _s.actors[_ai].facing;
                        // For knocked-down actors, also flip knock_direction to keep head in same spot
                        if (variable_struct_exists(_pa, "is_knocked_down") && _pa.is_knocked_down) {
                            var _cur_kdir_stg = variable_struct_exists(_s.actors[_ai], "knock_direction") ? _s.actors[_ai].knock_direction : "forwards";
                            var _new_kdir_stg = (_cur_kdir_stg == "forwards") ? "backwards" : "forwards";
                            _s.actors[_ai].knock_direction = _new_kdir_stg;
                            _pa.knock_direction = _new_kdir_stg;
                            _pa.knock_angle = (_new_kdir_stg == "forwards") ? (_pa.facing * 90) : (-_pa.facing * 90);
                        }
                        break;
                    }
                }
            } else {
                // Script mode: insert "rolls over" if knocked down, otherwise "turns around"
                var _ins = (focused_block != -1) ? focused_block + 1 : array_length(script_blocks);
                var _spliced = (focused_block != -1 && focused_block < array_length(script_blocks) - 1);
                var _is_kd_ta = false;
                for (var _ta_pa = 0; _ta_pa < array_length(preview_actors); _ta_pa++) {
                    if (preview_actors[_ta_pa].char_index == selected_character_index) {
                        _is_kd_ta = variable_struct_exists(preview_actors[_ta_pa], "is_knocked_down") && preview_actors[_ta_pa].is_knocked_down;
                        break;
                    }
                }
                var _ta_name = _is_kd_ta ? "rolls over" : "turns around";
                array_insert(script_blocks, _ins, { type: "action", char_index: selected_character_index, action_name: _ta_name, height: 85 });
                update_all_block_heights();
                focused_block = _ins;
                if (_spliced) {
                    var _block_y = 0;
                    for (var k = 0; k < _ins; k++) _block_y += script_blocks[k].height + 20;
                    block_scroll_y = min(0, -(_block_y - box_h / 3));
                    update_preview_actors_for_block(_ins, true);
                }
            }
            return;
        }
    }
}

// --- 2f. LIVE MOVE DRAGGING (When NOT in edit mode) ---
if (!script_expanded && !scene_edit_mode && !particle_edit_mode && !fx_picker_open && !trans_in_picker_open && !trans_out_picker_open && !is_speaking && playing_block_index == -1 && active_scene_block_idx != -1) {
    if (mouse_check_button_pressed(mb_left)) {
        if (_mx > scene_win_x && _mx < scene_win_x + scene_win_w && _my > scene_win_y && _my < scene_win_y + scene_win_h) {
            for (var a = array_length(preview_actors) - 1; a >= 0; a--) {
                var _act = preview_actors[a];
                var _tl = get_composite_character_sprite(_act.char_index, variable_struct_exists(_act, "pose") ? _act.pose : 1, variable_struct_exists(_act, "expression") ? _act.expression : 21, variable_struct_exists(_act, "facing") ? _act.facing : undefined);
                var _spr = _tl[0].spr;
                if (_spr != -1) {
                    var _sw = sprite_get_width(_spr);
                    var _sh = sprite_get_height(_spr);
                    var _scale = (scene_win_h * 1.5) / 450;
                    var _ax = scene_win_x + _act.x;
                    var _ay = scene_win_y + _act.y;
                    var _is_injured_nd  = variable_struct_exists(_act, "is_knocked_down") && _act.is_knocked_down;
                    var _kangle_nd      = _is_injured_nd ? (variable_struct_exists(_act, "knock_angle") ? _act.knock_angle : 0) : 0;
                    var _is_decap_nd    = variable_struct_exists(_act, "is_decapitated") && _act.is_decapitated;
                    var _decap_mode_nd  = _is_decap_nd ? (variable_struct_exists(_act, "decap_mode") ? _act.decap_mode : "remove_head") : "";
                    // For hit testing: inverse-rotate mouse around foot pivot
                    var _test_mx = _mx; var _test_my = _my;
                    if (_kangle_nd != 0) {
                        var _piv_x_nd = _ax; var _piv_y_nd = _ay;
                        var _inv_cos = dcos(-_kangle_nd); var _inv_sin = dsin(-_kangle_nd);
                        var _dvx = _mx - _piv_x_nd; var _dvy = _my - _piv_y_nd;
                        _test_mx = _piv_x_nd + _dvx * _inv_cos + _dvy * _inv_sin;
                        _test_my = _piv_y_nd - _dvx * _inv_sin + _dvy * _inv_cos;
                    }
                    // For remove_body, hit test against head layers only
                    var _hit_left_nd; var _hit_right_nd; var _hit_top_nd; var _hit_bot_nd;
                    if (_is_decap_nd && _decap_mode_nd == "remove_body" && _tl[1].spr != -1) {
                        var _fl = _tl[1];
                        _hit_left_nd  = _ax + (_fl.dx - _sw * 0.5) * _scale;
                        _hit_right_nd = _ax + (_fl.dx + sprite_get_width(_fl.spr) - _sw * 0.5) * _scale;
                        _hit_top_nd   = _ay - (_sh - _fl.dy) * _scale;
                        _hit_bot_nd   = _ay - (_sh - _fl.dy - sprite_get_height(_fl.spr)) * _scale;
                    } else {
                        _hit_left_nd  = _ax - (_sw * _scale) / 2;
                        _hit_right_nd = _ax + (_sw * _scale) / 2;
                        _hit_top_nd   = _ay - (_sh + max(0, -_tl[1].dy)) * _scale;
                        _hit_bot_nd   = _ay;
                    }
                    if (_test_mx > _hit_left_nd && _test_mx < _hit_right_nd && _test_my > _hit_top_nd && _test_my < _hit_bot_nd) {
                        selected_character_index = _act.char_index;
                        if (particle_panel_mode) particle_panel_mode = false;
                        var _row = floor(selected_character_index / 2);
                        var _iy = _row * 135;
                        if (_iy + char_sel_scroll_y < 0) char_sel_scroll_y = -_iy;
                        else if (_iy + 135 + char_sel_scroll_y > char_sel_h - 35) char_sel_scroll_y = -( _iy - (char_sel_h - 170) );
                        // Injured actors cannot be dragged to create move blocks
                        var _is_inj_prev = _is_injured_nd || _is_decap_nd;
                        if (!_is_inj_prev) {
                            dragging_preview_idx = a;
                            drag_preview_char = _act.char_index;
                            drag_preview_x = _act.x;
                            drag_preview_y = _act.y;
                            drag_start_x = _act.x;
                            drag_start_y = _act.y;
                            drag_off_x = _mx - _ax;
                            drag_off_y = _my - _ay;
                        }
                        break;
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
                var _insert_idx = (focused_block != -1) ? focused_block + 1 : array_length(script_blocks);

                var _pose = variable_struct_exists(_act, "pose") ? _act.pose : 1;
                var _expr = variable_struct_exists(_act, "expression") ? _act.expression : 21;
                var _face = variable_struct_exists(_act, "facing") ? _act.facing : 1;
                var _layers = get_composite_character_sprite(_act.char_index, _pose, _expr, _face);
                var _sc = (scene_win_h * 1.5) / 450 * (_act[$ "scale"] ?? 1.0);
                var _ax_abs = scene_win_x + _act.x;
                var _ay_abs = scene_win_y + _act.y;
                var _bbox = get_actor_bbox(_layers, _sc, _ax_abs, _ay_abs, _act);
                var _bb_w = _bbox.bb_right - _bbox.bb_left;
                var _bb_h = _bbox.bb_bottom - _bbox.bb_top;
                var _h_visible = max(0, min(_bbox.bb_right, scene_win_x + scene_win_w) - max(_bbox.bb_left, scene_win_x));
                var _v_visible = max(0, min(_bbox.bb_bottom, scene_win_y + scene_win_h) - max(_bbox.bb_top, scene_win_y));
                // Cap at 80px so large-scale actors don't snap/exit when mostly above scene
                var _in_live = (current_scene_sprite != -1) && (_h_visible >= min(_bb_w * 0.20, 80)) && (_v_visible >= min(_bb_h * 0.20, 80));
                var _v_snap_thresh = min(_bb_h * 0.20, 80);

                if (_v_visible < _v_snap_thresh) {
                    // Vertically out of bounds — snap pivot to edge
                    if (_bbox.bb_top < scene_win_y) {
                        _act.y = _act.y + (scene_win_y - _bbox.bb_top);
                    } else {
                        _act.y = _act.y - (_bbox.bb_bottom - (scene_win_y + scene_win_h));
                    }
                    _act.x = drag_start_x;
                } else {
                    var _aname = "moves";
                    if (!_in_live) {
                        _aname = (_ax_abs < scene_win_x + scene_win_w * 0.5) ? "exits left" : "exits right";
                    }

                    var _lbl = move_speed_labels[move_speed_index];
                    if (_lbl != "WALK") _aname += " (" + _lbl + ")";
                    if (moonwalk_enabled) _aname += " [MOONWALK]";
                    if (move_trick != "none") _aname += " [" + string_upper(move_trick) + "]";

                    array_insert(script_blocks, _insert_idx, {
                        type: "action",
                        action_name: _aname,
                        char_index: _act.char_index,
                        target_x: _act.x,
                        target_y: _act.y,
                        facing: _act.facing,
                        height: 85,
                        speed: move_speeds[move_speed_index],
                        moonwalk: moonwalk_enabled,
                        trick: move_trick
                    });
                    focused_block = _insert_idx;
                }
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
if (focused_block != -1 && focused_block < array_length(script_blocks) - 1 && !scene_edit_mode && !particle_edit_mode && mouse_check_button_pressed(mb_left)) {
    if (_mx > _ind_x && _mx < _ind_x + 150 && _my > scene_win_y - 45 && _my < scene_win_y - 10) {
        focused_block = -1;
        return;
    }
}
if (scene_edit_mode && mouse_check_button_pressed(mb_left)) {
    // Keep sorted alphabetically by label (OFF always first). Add future effects in order.
    var _fx_ids    = ["none","blackwhite","brighten","candlelight","crt","darken","dream","drunk","embers","filth","fog","frigid","goldenhour","heat","infrared","moonlight","nightvision","rain","sepia","snow","static","stoned","sunlight","underwater"];
    var _fx_btn_x  = _ind_x + 120; var _fx_btn_w = 130;
    var _pick_item_h = 22; var _pick_count = array_length(_fx_ids);

    // --- FX picker item click (must be checked before anything else) ---
    if (fx_picker_open) {
        var _pick_y   = scene_win_y - 10;
        var _fp_max   = min(13, _pick_count);
        var _pick_vis_h = _fp_max * _pick_item_h;
        var _fp_sb_x2   = _fx_btn_x + _fx_btn_w - 8; // scrollbar x — matches Draw geometry
        var _on_sb      = (_mx >= _fp_sb_x2 && _mx <= _fx_btn_x + _fx_btn_w);
        var _in_picker  = (!_on_sb && _mx > _fx_btn_x && _mx < _fp_sb_x2
                        && _my > _pick_y && _my < _pick_y + _pick_vis_h);
        if (!_on_sb && fx_picker_sb_dragging) { fx_picker_sb_dragging = false; }
        if (_in_picker && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
            var _picked = fx_picker_scroll + floor((_my - _pick_y) / _pick_item_h);
            if (_picked >= 0 && _picked < _pick_count)
                script_blocks[active_scene_block_idx].fx = _fx_ids[_picked];
        }
        fx_picker_open = false;
        return;
    }

    // --- IN / OUT transition picker item click ---
    if (trans_in_picker_open || trans_out_picker_open) {
        var _tr_names_s  = ["none","fade","iris","wipe_left","wipe_right","wipe_top","wipe_bottom","barn_door"];
        var _tr_count_s  = array_length(_tr_names_s);
        var _tr_item_h_s = 22;
        var _tr_sep_s    = 5;
        var _tr_spd_h_s  = 28;
        var _tr_w_s      = 140;
        var _tr_h_s      = _tr_count_s * _tr_item_h_s + _tr_sep_s + _tr_spd_h_s;
        var _in_btn_x_s  = _fx_btn_x + _fx_btn_w + 10;
        var _out_btn_x_s = _in_btn_x_s + 88 + 5;
        var _open_in_s   = trans_in_picker_open;
        var _tr_bx_s     = _open_in_s ? _in_btn_x_s : _out_btn_x_s;
        var _tr_by_s     = scene_win_y - 10;
        var _tkey_s      = _open_in_s ? "transition_in"       : "transition_out";
        var _tspk_s      = _open_in_s ? "transition_in_speed"  : "transition_out_speed";
        if (active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
            var _trb_s = script_blocks[active_scene_block_idx];
            // Effect rows
            if (_mx > _tr_bx_s && _mx < _tr_bx_s + _tr_w_s && _my > _tr_by_s && _my < _tr_by_s + _tr_count_s * _tr_item_h_s) {
                var _picked_tr = floor((_my - _tr_by_s) / _tr_item_h_s);
                if (_picked_tr >= 0 && _picked_tr < _tr_count_s)
                    variable_struct_set(_trb_s, _tkey_s, _tr_names_s[_picked_tr]);
            }
            // Speed buttons
            var _tspd_by_s = _tr_by_s + _tr_count_s * _tr_item_h_s + _tr_sep_s;
            var _spd_bw_s  = floor((_tr_w_s - 10) / 3);
            var _spd_vals_s = [30, 60, 90];
            for (var _spi = 0; _spi < 3; _spi++) {
                var _sbx_s = _tr_bx_s + 5 + _spi * _spd_bw_s;
                if (_mx > _sbx_s && _mx < _sbx_s + _spd_bw_s - 1 && _my > _tspd_by_s && _my < _tspd_by_s + _tr_spd_h_s - 4)
                    variable_struct_set(_trb_s, _tspk_s, _spd_vals_s[_spi]);
            }
        }
        // Only close if click was outside picker bounds
        var _in_picker_s = (_mx > _tr_bx_s && _mx < _tr_bx_s + _tr_w_s && _my > _tr_by_s && _my < _tr_by_s + _tr_h_s);
        if (!_in_picker_s) {
            trans_in_picker_open  = false;
            trans_out_picker_open = false;
        }
        return;
    }

    // --- STAGING label click → exit staging ---
    if (_mx > _ind_x && _mx < _ind_x + 110 && _my > scene_win_y - 45 && _my < scene_win_y - 10) {
        scene_edit_mode = false;
        return;
    }

    // --- FX button click → open picker ---
    if (active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
        if (_mx > _fx_btn_x && _mx < _fx_btn_x + _fx_btn_w && _my > scene_win_y - 45 && _my < scene_win_y - 10) {
            fx_picker_open   = true;
            fx_picker_scroll = 0;
            return;
        }
    }

    // --- IN / OUT button clicks → open pickers ---
    if (active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
        var _in_btn_x_op  = _fx_btn_x + _fx_btn_w + 10;
        var _out_btn_x_op = _in_btn_x_op + 88 + 5;
        if (_mx > _in_btn_x_op && _mx < _in_btn_x_op + 88 && _my > scene_win_y - 45 && _my < scene_win_y - 10) {
            dragging_actor_idx = -1; dragging_char_index = -1;
            trans_in_picker_open  = true;
            trans_out_picker_open = false;
            return;
        }
        if (_mx > _out_btn_x_op && _mx < _out_btn_x_op + 90 && _my > scene_win_y - 45 && _my < scene_win_y - 10) {
            dragging_actor_idx = -1; dragging_char_index = -1;
            trans_out_picker_open = true;
            trans_in_picker_open  = false;
            return;
        }
    }
}
if (!scene_edit_mode) { fx_picker_open = false; fx_picker_scroll = 0; trans_in_picker_open = false; trans_out_picker_open = false; }

// --- FX picker scroll wheel + scrollbar drag (runs every step) ---
if (fx_picker_open) {
    var _fp_total  = 24; // must match picker list length
    var _fp_max_sb = 13;
    if (mouse_wheel_up())   fx_picker_scroll = max(0, fx_picker_scroll - 1);
    if (mouse_wheel_down()) fx_picker_scroll = min(_fp_total - _fp_max_sb, fx_picker_scroll + 1);

    // Scrollbar geometry (mirrors Draw)
    var _ind_x_sb  = max(scene_win_x, 110);
    var _fp_btn_x_sb = _ind_x_sb + 120; var _fp_btn_w_sb = 130;
    var _fp_pick_y_sb = scene_win_y - 10;
    var _fp_h_sb   = _fp_max_sb * 22;
    var _fp_sb_w   = 6;
    var _fp_sb_x   = _fp_btn_x_sb + _fp_btn_w_sb - _fp_sb_w - 2;
    var _fp_bar_h  = max(16, (_fp_max_sb / _fp_total) * _fp_h_sb);
    var _fp_sb_max = _fp_pick_y_sb + _fp_h_sb - _fp_bar_h;
    var _fp_bar_y  = _fp_pick_y_sb + (fx_picker_scroll / max(1, _fp_total - _fp_max_sb)) * (_fp_h_sb - _fp_bar_h);

    if (mouse_check_button_pressed(mb_left)
        && _mx >= _fp_sb_x && _mx <= _fp_sb_x + _fp_sb_w
        && _my >= _fp_pick_y_sb && _my <= _fp_pick_y_sb + _fp_h_sb) {
        if (_my >= _fp_bar_y && _my <= _fp_bar_y + _fp_bar_h) {
            fx_picker_sb_dragging    = true;
            fx_picker_sb_drag_offset = _my - _fp_bar_y;
        } else {
            // Click on track — jump
            var _frac = clamp((_my - _fp_pick_y_sb) / _fp_h_sb, 0.0, 1.0);
            fx_picker_scroll = round(_frac * (_fp_total - _fp_max_sb));
        }
    }

    if (fx_picker_sb_dragging) {
        if (mouse_check_button(mb_left)) {
            var _new_bar_y   = clamp(_my - fx_picker_sb_drag_offset, _fp_pick_y_sb, _fp_sb_max);
            var _new_frac    = (_new_bar_y - _fp_pick_y_sb) / max(1, _fp_h_sb - _fp_bar_h);
            fx_picker_scroll = round(clamp(_new_frac * (_fp_total - _fp_max_sb), 0, _fp_total - _fp_max_sb));
        } else {
            fx_picker_sb_dragging = false;
        }
    }
}

step_ui_clicks(_mx, _my);

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

// --- SCRIPT SCROLLBAR DRAG ---
if (!theater_mode) {
    var _sb_full_h = 0;
    for (var i = 0; i < array_length(script_blocks); i++) _sb_full_h += script_blocks[i].height + 20;
    _sb_full_h += box_h / 2;

    if (_sb_full_h > box_h - 10) {
        var _sb_view_h  = box_h - 10;
        var _sb_bar_h   = max(20, (_sb_view_h / _sb_full_h) * _sb_view_h);
        var _sb_max_top = (box_y + 5) + _sb_view_h - _sb_bar_h;
        var _sb_bar_y   = clamp((box_y + 5) + (-block_scroll_y / _sb_full_h) * _sb_view_h, box_y + 5, _sb_max_top);
        var _sb_x = box_x + box_w - 12;
        var _sb_w = 10;

        if (mouse_check_button_pressed(mb_left) && _mx >= _sb_x && _mx <= _sb_x + _sb_w
            && _my >= box_y + 5 && _my <= box_y + box_h - 5) {
            if (_my >= _sb_bar_y && _my <= _sb_bar_y + _sb_bar_h) {
                script_scrollbar_dragging = true;
                script_scrollbar_drag_offset = _my - _sb_bar_y;
            } else {
                // Click on track — center bar at click position
                var _clicked_frac = (_my - (box_y + 5)) / _sb_view_h;
                block_scroll_y = clamp(-(_clicked_frac * _sb_full_h - _sb_bar_h / 2), -(_sb_full_h - _sb_view_h), 0);
            }
        }

        if (script_scrollbar_dragging) {
            if (mouse_check_button(mb_left)) {
                var _new_bar_y = clamp(_my - script_scrollbar_drag_offset, box_y + 5, _sb_max_top);
                var _new_frac  = (_new_bar_y - (box_y + 5)) / _sb_view_h;
                block_scroll_y = clamp(-_new_frac * _sb_full_h, -(_sb_full_h - _sb_view_h), 0);
            } else {
                script_scrollbar_dragging = false;
            }
        }
    } else {
        script_scrollbar_dragging = false;
    }
}

if (!_overlay_active) {
    var _over_pane = (_mx > char_sel_x && _mx < char_sel_x + char_sel_w && _my > char_sel_y && _my < char_sel_y + char_sel_h);

    // --- CHAR SELECTOR SCROLLBAR DRAG ---
    var _c_total_h2 = ceil(array_length(characters) / 2) * 135;
    var _c_view_h2 = char_sel_h - 35;
    var _char_sb_clicked = false;
    if (_c_total_h2 > _c_view_h2) {
        var _csb_w = 8; var _csb_x = char_sel_x + char_sel_w - _csb_w - 4;
        var _csb_y = char_sel_y + 35; var _csb_h = char_sel_h - 40;
        var _csb_bar_h = max(20, (_c_view_h2 / _c_total_h2) * _csb_h);
        var _csb_max_top = _csb_y + _csb_h - _csb_bar_h;
        var _csb_bar_y = clamp(_csb_y + (-char_sel_scroll_y / _c_total_h2) * _csb_h, _csb_y, _csb_max_top);
        if (mouse_check_button_pressed(mb_left) && _mx >= _csb_x - 4 && _mx <= _csb_x + _csb_w + 4
                && _my >= _csb_y && _my <= _csb_y + _csb_h) {
            _char_sb_clicked = true;
            if (_my >= _csb_bar_y && _my <= _csb_bar_y + _csb_bar_h) {
                char_sb_dragging = true;
                char_sb_drag_offset = _my - _csb_bar_y;
            } else {
                var _clicked_frac = (_my - _csb_y) / _csb_h;
                char_sel_scroll_y = clamp(-(_clicked_frac * _c_total_h2 - _csb_bar_h / 2), -(_c_total_h2 - _c_view_h2), 0);
            }
        }
        if (char_sb_dragging) {
            if (mouse_check_button(mb_left)) {
                var _new_bar_y = clamp(_my - char_sb_drag_offset, _csb_y, _csb_max_top);
                var _new_frac = (_new_bar_y - _csb_y) / _csb_h;
                char_sel_scroll_y = clamp(-_new_frac * _c_total_h2, -(_c_total_h2 - _c_view_h2), 0);
            } else {
                char_sb_dragging = false;
            }
        }
    } else {
        char_sb_dragging = false;
    }

    if (_over_pane) {
        // Scroll the character selector
        var _cols = 2; var _item_h = 135;
        var _total_h = ceil(array_length(characters) / _cols) * _item_h;
        var _max_visible_h = char_sel_h - 35;
        if (mouse_wheel_up()) char_sel_scroll_y = min(0, char_sel_scroll_y + _item_h);
        if (mouse_wheel_down()) {
            if (_total_h > _max_visible_h) char_sel_scroll_y = max(-(_total_h - _max_visible_h), char_sel_scroll_y - _item_h);
        }
        
        // --- CHARACTER SELECTION & DRAG START ---
        if (!_char_sb_clicked && !particle_edit_mode && playing_block_index == -1 && mouse_check_button_pressed(mb_left)) {
        if (particle_panel_mode) {
            // Particle tile drag start — positions must match Draw exactly
            var _tile_w3 = 155; var _tile_h3 = 82;
            var _pe_ids = ["splatter", "shatter", "electrify", "laser", "debris", "flame", "explosion", "shot"];
            for (var _pei3 = 0; _pei3 < array_length(_pe_ids); _pei3++) {
                var _tx3 = char_sel_x + 10 + (_pei3 % 2) * 168;
                var _ty3 = char_sel_y + 40 + floor(_pei3 / 2) * 95;
                if (_mx > _tx3 && _mx < _tx3 + _tile_w3 && _my > _ty3 && _my < _ty3 + _tile_h3
                        && _my > char_sel_y + 30 && _my < char_sel_y + char_sel_h
                        && current_scene_sprite != -1) {
                    dragging_particle_effect = _pe_ids[_pei3];
                    drag_particle_x = _mx; drag_particle_y = _my; break;
                }
            }
        } else {
            var _grid_x = char_sel_x + 10; var _grid_y = char_sel_y + 35;
            for (var i = 0; i < array_length(characters); i++) {
                var _iw2 = 165;
                var _ix = _grid_x + (i % _cols) * _iw2;
                var _iy = _grid_y + floor(i / _cols) * _item_h + char_sel_scroll_y;
                if (_mx > _ix && _mx < _ix + _iw2 && _my > _iy && _my < _iy + _item_h && _my > char_sel_y + 30 && _my < char_sel_y + char_sel_h) {
                    var _was_sel2 = (i == selected_character_index);
                    var _spr = get_character_sprite(i);
                    var _csh = (_spr != -1) ? sprite_get_height(_spr) : 100;
                    var _scale = (scene_win_h * 1.5) / 450;

                    selected_character_index = i;
                    if (_was_sel2 && characters[i].name != "NARRATOR" &&
                        _mx > _ix + _iw2 - 18 && _my > _iy + _item_h - 22 && _my < _iy + _item_h - 6) {
                        char_rename_active = true; char_rename_target = i;
                        char_rename_text = characters[i].name; keyboard_string = "";
                        break;
                    }
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
                    // Grab by the head/face instead of the feet so they can drag it lower
                    drag_off_y = -(_csh * _scale);
                    
                    // Auto-scroll logic
                    var _row = floor(selected_character_index / 2);
                    var _iy_scroll = _row * 135;
                    if (_iy_scroll + char_sel_scroll_y < 0) char_sel_scroll_y = -_iy_scroll;
                    else if (_iy_scroll + 135 + char_sel_scroll_y > char_sel_h - 35) char_sel_scroll_y = -( _iy_scroll - (char_sel_h - 170) );
                    break;
                }
            }
        } // end particle_panel_mode else
        } // end !_char_sb_clicked block
    } else {
        // Normal script scrolling — suppressed when FX picker is open
        if (!fx_picker_open && mouse_wheel_up()) block_scroll_y += 80;
        if (!fx_picker_open && mouse_wheel_down()) block_scroll_y -= 80;
    }
}

// --- UNIFIED DRAGGING FROM PANE LOGIC ---
_overlay_active = (file_menu_open || edit_mode || scene_modal_open || action_modal_open || theater_mode || move_modal_open);

if (!script_expanded && !_overlay_active && playing_block_index == -1 && dragging_char_index != -1) {
    if (!mouse_check_button(mb_left)) {
        var _c = characters[dragging_char_index];
        var _pose = variable_struct_exists(_c, "pose") ? _c.pose : 1;
        var _expr = variable_struct_exists(_c, "expression") ? _c.expression : 21;
        var _face = (_mx < scene_win_x + (scene_win_w / 2)) ? -1 : 1;
        var _layers = get_composite_character_sprite(dragging_char_index, _pose, _expr, _face);
        var _spr = _layers[0].spr;
        
        var _sc = (scene_win_h * 1.5) / 450;
        var _sw = (_spr != -1) ? sprite_get_width(_spr) : 100;
        var _sh = (_spr != -1) ? sprite_get_height(_spr) : 100;
        var _cw = _sw * _sc;
        var _ch = _sh * _sc;

        var _min_x = 0; var _max_x = _sw;
        var _min_y = 0; var _max_y = _sh;
        if (_spr != -1) {
            for (var _li = 0; _li < array_length(_layers); _li++) {
                var _l = _layers[_li];
                if (_l.spr != -1) {
                    var _lw = sprite_get_width(_l.spr);
                    var _lh = sprite_get_height(_l.spr);
                    _min_x = min(_min_x, _l.dx);
                    _max_x = max(_max_x, _l.dx + _lw);
                    _min_y = min(_min_y, _l.dy);
                    _max_y = max(_max_y, _l.dy + _lh);
                }
            }
        }
        var _true_w = (_max_x - _min_x) * _sc;
        var _true_h = (_max_y - _min_y) * _sc;

        var _px = _mx - scene_win_x - drag_off_x;
        var _py = _my - scene_win_y - drag_off_y;

        var _ay_abs = scene_win_y + _py;
        var _v_top = _ay_abs - _ch + _min_y * _sc;
        var _v_bottom = _ay_abs - _ch + _max_y * _sc;
        var _v_visible = max(0, min(_v_bottom, scene_win_y + scene_win_h) - max(_v_top, scene_win_y));
        
        var _ax_abs = scene_win_x + _px;
        var _h_left  = _ax_abs - _cw / 2 + _min_x * _sc;
        var _h_right = _ax_abs - _cw / 2 + _max_x * _sc;
        
        var _h_intersect_l = max(_h_left, scene_win_x);
        var _h_intersect_r = min(_h_right, scene_win_x + scene_win_w);
        var _h_visible = max(0, _h_intersect_r - _h_intersect_l);
        
        var _in_live = (current_scene_sprite != -1) && (_h_visible >= _true_w * 0.20) && (_v_visible >= _true_h * 0.20);
        
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
                        // Injured characters can still be placed in scenes; no blocking needed
                        if (true) {
                        // Auto-flip for entrance — but keep existing facing if knocked down
                        var _is_left = (_mx < scene_win_x + (scene_win_w / 2));
                        var _drop_is_kd = false;
                        for (var _dki = 0; _dki < array_length(preview_actors); _dki++) {
                            if (preview_actors[_dki].char_index == dragging_char_index) {
                                _drop_is_kd = variable_struct_exists(preview_actors[_dki], "is_knocked_down") && preview_actors[_dki].is_knocked_down;
                                if (_drop_is_kd) _face = variable_struct_exists(preview_actors[_dki], "facing") ? preview_actors[_dki].facing : _face;
                                break;
                            }
                        }
                        if (!_drop_is_kd) _face = _is_left ? -1 : 1;

                        // Precise coordinates within background
                        var _nx = _px;
                        var _ny = _py;

                        _c = characters[dragging_char_index];
                        _pose = variable_struct_exists(_c, "pose") ? _c.pose : 1;
                        _expr = variable_struct_exists(_c, "expression") ? _c.expression : 21;

                        // Carry injury state from any hidden pre-injured preview actor
                        var _sa_new = { char_index: dragging_char_index, x: _nx, y: _ny, facing: _face, pose: _pose, expression: _expr, scale: char_entry_scales[dragging_char_index] };
                        for (var _hpi = 0; _hpi < array_length(preview_actors); _hpi++) {
                            var _hpa = preview_actors[_hpi];
                            if (_hpa.char_index == dragging_char_index && variable_struct_exists(_hpa, "hidden") && _hpa.hidden) {
                                if (variable_struct_exists(_hpa, "is_knocked_down") && _hpa.is_knocked_down) {
                                    _sa_new.is_knocked_down  = true;
                                    _sa_new.knock_direction  = variable_struct_exists(_hpa, "knock_direction") ? _hpa.knock_direction : "forwards";
                                    var _hpa_angle = variable_struct_exists(_hpa, "knock_angle") ? _hpa.knock_angle : 0;
                                    _sa_new.knock_angle = (_hpa_angle != 0) ? _hpa_angle : ((_sa_new.knock_direction == "forwards") ? (_face * 90) : (-_face * 90));
                                }
                                if (variable_struct_exists(_hpa, "is_decapitated") && _hpa.is_decapitated) {
                                    _sa_new.is_decapitated = true;
                                    _sa_new.decap_mode     = variable_struct_exists(_hpa, "decap_mode") ? _hpa.decap_mode : "remove_head";
                                }
                                // Unhide and place the preview actor — keep facing unchanged for knocked-down
                                _hpa.hidden  = false;
                                _hpa.x       = _nx;
                                _hpa.y       = _ny;
                                if (!_drop_is_kd) _hpa.facing = _face;
                                if (variable_struct_exists(_hpa, "is_knocked_down") && _hpa.is_knocked_down && _hpa.knock_angle == 0) {
                                    var _hpa_kdir = variable_struct_exists(_hpa, "knock_direction") ? _hpa.knock_direction : "forwards";
                                    var _hpa_face = variable_struct_exists(_hpa, "facing") ? _hpa.facing : 1;
                                    _hpa.knock_angle = (_hpa_kdir == "forwards") ? (_hpa_face * 90) : (-_hpa_face * 90);
                                }
                                break;
                            }
                        }
                        // Apply char_entry staging injury if no hidden actor provided it
                        if (!variable_struct_exists(_sa_new, "is_knocked_down") && !variable_struct_exists(_sa_new, "is_decapitated")) {
                            var _drop_ks = char_entry_knock_state[dragging_char_index];
                            var _drop_ds = char_entry_decap_state[dragging_char_index];
                            if (_drop_ks > 0) {
                                _sa_new.is_knocked_down = true;
                                _sa_new.knock_direction = (_drop_ks == 1) ? "forwards" : "backwards";
                                _sa_new.knock_angle = (_sa_new.knock_direction == "forwards") ? (_face * 90) : (-_face * 90);
                            }
                            if (_drop_ds > 0) {
                                _sa_new.is_decapitated = true;
                                _sa_new.decap_mode = (_drop_ds == 1) ? "remove_head" : "remove_body";
                            }
                        }
                        if (char_entry_foreground[dragging_char_index]) {
                            _sa_new.is_foreground = true;
                        }
                        array_push(_scene.actors, _sa_new);
                        scene_edit_selected_actor_idx = array_length(_scene.actors) - 1;
                        }
                    } else {
                        // Reposition existing actor to drop point (handles offscreen/oversized characters)
                        _scene.actors[_dup_idx].x = _px;
                        _scene.actors[_dup_idx].y = _py;
                        scene_edit_selected_actor_idx = _dup_idx;
                    }
                }
            } else {
                // LIVE DROP: Create Script Command
                var _onstage = false;
                if (active_scene_block_idx != -1) {
                    for (var pa = 0; pa < array_length(preview_actors); pa++) {
                        if (preview_actors[pa].char_index == dragging_char_index
                            && !(variable_struct_exists(preview_actors[pa], "hidden") && preview_actors[pa].hidden)) {
                            _onstage = true; break;
                        }
                    }
                }
                
                if (!_onstage) {
                    var _is_left = (_mx < scene_win_x + (scene_win_w / 2));
                    var _aname = _is_left ? "enters from left" : "enters from right";

                    var _lbl = move_speed_labels[move_speed_index];
                    if (_lbl != "WALK") _aname += " (" + _lbl + ")";
                    if (moonwalk_enabled) _aname += " [MOONWALK]";
                    if (move_trick != "none") _aname += " [" + string_upper(move_trick) + "]";

                    var _insert_idx = (focused_block != -1) ? focused_block + 1 : array_length(script_blocks);
                    var _ec = characters[dragging_char_index];
                    array_insert(script_blocks, _insert_idx, {
                        type: "action",
                        action_name: _aname,
                        char_index: dragging_char_index,
                        target_x: _px,
                        target_y: _py,
                        facing: _is_left ? 1 : -1,
                        height: 85,
                        speed: move_speeds[move_speed_index],
                        moonwalk: moonwalk_enabled,
                        trick: move_trick,
                        enter_expression: variable_struct_exists(_ec, "expression") ? _ec.expression : 21,
                        enter_pose:       variable_struct_exists(_ec, "pose")       ? _ec.pose       : 1
                    });
                    focused_block = _insert_idx;
                    update_all_block_heights();

                    var _th = 0; for (var k = 0; k < _insert_idx; k++) _th += script_blocks[k].height + 20;
                    block_scroll_y = -_th + 50;
                } else {
                    // Already on stage but may be offscreen — create a moves block to reposition
                    var _onstg_x     = scene_win_w / 2;
                    var _onstg_scale = 1.0;
                    for (var _pao = 0; _pao < array_length(preview_actors); _pao++) {
                        if (preview_actors[_pao].char_index == dragging_char_index) {
                            _onstg_x     = preview_actors[_pao].x;
                            _onstg_scale = preview_actors[_pao][$ "scale"] ?? 1.0;
                            break;
                        }
                    }
                    var _lbl2  = move_speed_labels[move_speed_index];
                    var _aname2 = "moves";
                    if (_lbl2 != "WALK") _aname2 += " (" + _lbl2 + ")";
                    if (moonwalk_enabled) _aname2 += " [MOONWALK]";
                    if (move_trick != "none") _aname2 += " [" + string_upper(move_trick) + "]";
                    var _mv_bface = (_px > _onstg_x) ? -1 : 1;
                    var _mv_face  = moonwalk_enabled ? -_mv_bface : _mv_bface;
                    var _insert_idx2 = (focused_block != -1) ? focused_block + 1 : array_length(script_blocks);
                    array_insert(script_blocks, _insert_idx2, {
                        type: "action",
                        action_name: _aname2,
                        char_index: dragging_char_index,
                        target_x: _px,
                        target_y: _py,
                        facing: _mv_face,
                        height: 85,
                        speed: move_speeds[move_speed_index],
                        moonwalk: moonwalk_enabled,
                        trick: move_trick,
                        target_scale: _onstg_scale
                    });
                    focused_block = _insert_idx2;
                    update_all_block_heights();
                    var _th2 = 0; for (var k = 0; k < _insert_idx2; k++) _th2 += script_blocks[k].height + 20;
                    block_scroll_y = -_th2 + 50;
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

        if (_ctrl && keyboard_check_pressed(ord("C"))) {
            var _copy_txt = (selection_start != selection_end)
                ? string_copy(_b.text, min(selection_start, selection_end) + 1, abs(selection_end - selection_start))
                : _b.text;
            clipboard_set_text(_copy_txt);
            keyboard_string = "";
        }

        if (_ctrl && keyboard_check_pressed(ord("V"))) {
            var _paste = clipboard_get_text();
            if (string_length(_paste) > 0) {
                if (selection_start != selection_end) {
                    var _s = min(selection_start, selection_end);
                    var _e = max(selection_start, selection_end);
                    _b.text = string_delete(_b.text, _s + 1, _e - _s);
                    _b.caret_pos = _s;
                    selection_start = _s; selection_end = _s;
                }
                _b.text = string_insert(_paste, _b.text, _b.caret_pos + 1);
                _b.caret_pos += string_length(_paste);
                update_block_height(focused_block);
            }
            keyboard_string = "";
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
            script_dirty = true;
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
        if (keyboard_check_pressed(vk_home)) { _b.caret_pos = 0; selection_start = 0; selection_end = 0; }
        if (keyboard_check_pressed(vk_end))  { _b.caret_pos = string_length(_b.text); selection_start = _b.caret_pos; selection_end = _b.caret_pos; }
        if (_ctrl && keyboard_check_pressed(ord("A"))) { selection_start = 0; selection_end = string_length(_b.text); _b.caret_pos = selection_end; keyboard_string = ""; }
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

var _ref_idx;
if (playing_block_index != -1) {
    _ref_idx = playing_block_index;
} else if (focused_block != -1) {
    _ref_idx = focused_block;
} else if (_len > 0) {
    // Nothing selected — show the scene context for whatever's visible in the center of the viewport
    var _center_target = -block_scroll_y + box_h * 0.4;
    var _acc = 0;
    _ref_idx = _len - 1;
    for (var _ri = 0; _ri < _len; _ri++) {
        _acc += script_blocks[_ri].height + 20;
        if (_acc >= _center_target) { _ref_idx = _ri; break; }
    }
} else {
    _ref_idx = -1;
}
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
    // Live preview while move modal is open: apply temp scale + recompute facing from live moonwalk toggle
    if (move_modal_open && move_modal_target_index != -1 && move_modal_target_index < array_length(script_blocks)) {
        var _mm_blk  = script_blocks[move_modal_target_index];
        var _mm_char = _mm_blk.char_index;
        for (var _mmi = 0; _mmi < array_length(preview_actors); _mmi++) {
            if (preview_actors[_mmi].char_index == _mm_char) {
                var _pa_mm = preview_actors[_mmi];
                _pa_mm.scale = move_modal_temp_target_scale;
                var _mm_saved_moon = (variable_struct_exists(_mm_blk, "moonwalk") && _mm_blk.moonwalk)
                                  || (string_pos("[moonwalk]", string_lower(_mm_blk.action_name)) > 0);
                if (move_modal_temp_moonwalk != _mm_saved_moon) _pa_mm.facing *= -1;
                break;
            }
        }
    }
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

// End of Step Event
