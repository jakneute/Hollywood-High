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
if (dictionary_open)       { step_modal_dictionary();  return; }

if (expr_cfg_open)         { step_modal_expr_cfg();    return; }

if (move_modal_open)       { step_modal_movement();    return; }

if (pose_expr_modal_open)  { step_modal_pose_expr();   return; }

if (action_modal_open)     { step_modal_action();      return; }

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
        
        // Export Config (debug)
        if (SHOW_VOICE_CFG && !modal_is_local_edit && _mx > _m_x+_m_w-430 && _mx < _m_x+_m_w-295 && _my > _btn_y && _my < _btn_y+40) {
            var _json = "{";
            for (var _ci = 0; _ci < array_length(characters); _ci++) {
                var _cc = characters[_ci];
                if (_ci > 0) _json += ",";
                _json += "\n  \"" + _cc.name + "\": {";
                _json += "\"voice_id\": \"" + string(_cc.voice_id) + "\", ";
                _json += "\"pitch\": " + string(_cc.pitch) + ", ";
                _json += "\"speed\": " + string(_cc.speed) + ", ";
                _json += "\"mode\": " + string(_cc.mode) + ", ";
                _json += "\"style\": " + string(_cc.style) + ", ";
                _json += "\"tweaked\": " + (_cc.tweaked ? "true" : "false") + "}";
            }
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
        var _fm_x = 10; var _fm_y = 45; var _fm_w = 165; var _fm_h = 105;
        var _clicked_option = false;

        // ── SAVE SCRIPT ──
        if (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y && _my < _fm_y + 35) {
            var _file = get_save_filename("Hollywood High Script|*.hhi", "screenplay.hhi");
            if (_file != "") {
                // Version 2: chars array now carries sprite_name for renamed characters
                var _save_data = { version: 2, script: script_blocks, chars: characters, dict: dictionary_list };
                var _json = json_stringify(_save_data);
                var _buf = buffer_create(string_byte_length(_json) + 1, buffer_fixed, 1);
                buffer_write(_buf, buffer_string, _json);
                buffer_seek(_buf, buffer_seek_start, 0);
                var _cbuf = buffer_compress(_buf, 0, buffer_get_size(_buf));
                buffer_save(_cbuf, _file);
                buffer_delete(_buf); buffer_delete(_cbuf);
            }
            _clicked_option = true;

        // ── LOAD SCRIPT ──
        } else if (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y + 35 && _my < _fm_y + 70) {
            var _file = get_open_filename("Hollywood High Script|*.hhi", "");
            if (_file != "" && file_exists(_file)) {
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
            }
            _clicked_option = true;

        // ── SAVE SCREENPLAY (export-only text file) ──
        } else if (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y + 70 && _my < _fm_y + 105) {
            var _file = get_save_filename("Screenplay Text|*.txt|Fountain Format|*.fountain", "screenplay.txt");
            if (_file != "") {
                var _sf = file_text_open_write(_file);
                if (_sf != -1) {
                    file_text_write_string(_sf, "FADE IN:\n\n\n");
                    for (var _bi = 0; _bi < array_length(script_blocks); _bi++) {
                        var _bl = script_blocks[_bi];
                        var _btype = variable_struct_exists(_bl, "type") ? _bl.type : "voice";

                        if (_btype == "scene") {
                            file_text_write_string(_sf, "INT. " + string_upper(_bl.name) + " - DAY\n\n");

                        } else if (_btype == "action") {
                            var _aname = _bl.action_name;
                            var _aname_u = string_upper(_aname);
                            var _cn = (_bl.char_index >= 0 && _bl.char_index < array_length(characters))
                                      ? characters[_bl.char_index].name : "";
                            if (string_pos("WAIT", _aname_u) > 0) {
                                // Silent pause — omit from screenplay prose
                            } else if (string_pos("PLAY SFX", _aname_u) > 0) {
                                var _sfx = variable_struct_exists(_bl, "sfx_path") ? _bl.sfx_path : "";
                                file_text_write_string(_sf, "(SOUND EFFECT: " + _sfx + ")\n\n");
                            } else if (string_pos("DISPLAY TITLE", _aname_u) > 0) {
                                var _ttl = variable_struct_exists(_bl, "title_text") ? _bl.title_text : "";
                                if (_ttl != "") file_text_write_string(_sf, "                    TITLE CARD: \"" + _ttl + "\"\n\n");
                            } else {
                                // Character action — build a readable sentence
                                var _sent = _cn + " " + _aname;
                                _sent = string_upper(string_char_at(_sent, 1)) + string_copy(_sent, 2, string_length(_sent) - 1);
                                var _lc = string_char_at(_sent, string_length(_sent));
                                if (_lc != "." && _lc != "!" && _lc != "?") _sent += ".";
                                file_text_write_string(_sf, _sent + "\n\n");
                            }

                        } else {
                            // Voice / dialogue block
                            var _cn = (_bl.char_index >= 0 && _bl.char_index < array_length(characters))
                                      ? characters[_bl.char_index].name : "UNKNOWN";
                            var _txt = _bl.text;
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
        }

        file_menu_open = false;
        if (_clicked_option) return;
    }
}

// --- 2d. CHARACTER SELECTOR CLICKS & DRAGS ---
if (mouse_check_button_pressed(mb_left)) {
    // Block interaction if any modal is open
    _overlay_active = (file_menu_open || edit_mode || scene_modal_open || action_modal_open || theater_mode || move_modal_open || pose_modal_open || expression_modal_open || pose_expr_modal_open);

    if (!_overlay_active && playing_block_index == -1 && _mx > char_sel_x && _mx < char_sel_x + char_sel_w && _my > char_sel_y && _my < char_sel_y + char_sel_h) {
        if (!scene_edit_mode) focused_block = -1;
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
                var _tl = get_composite_character_sprite(_act.char_index, variable_struct_exists(_act, "pose") ? _act.pose : 1, variable_struct_exists(_act, "expression") ? _act.expression : 21, variable_struct_exists(_act, "facing") ? _act.facing : undefined);
                var _spr = _tl[0].spr;
                if (_spr != -1) {
                    var _sw = sprite_get_width(_spr);
                    var _sh = sprite_get_height(_spr);
                    var _scale = (scene_win_h * 1.5) / 450;
                    var _ax = scene_win_x + _act.x;
                    var _ay = scene_win_y + _act.y;
                    var _face = variable_struct_exists(_act, "facing") ? _act.facing : 1;
                    var _hit_top = _ay - (_sh + max(0, -_tl[1].dy)) * _scale;
                    if (_mx > _ax - (_sw*_scale)/2 && _mx < _ax + (_sw*_scale)/2 && _my > _hit_top && _my < _ay) {
                        dragging_actor_idx = a;
                        scene_edit_selected_actor_idx = a; // Select on click
                        selected_character_index = _act.char_index; // Sync global selection
                        
                        // Auto-scroll character pane
                        var _row = floor(selected_character_index / 2);
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
            if (_spr == -1) { var _tl = get_composite_character_sprite(_act.char_index, variable_struct_exists(_act, "pose") ? _act.pose : 1, variable_struct_exists(_act, "expression") ? _act.expression : 21, variable_struct_exists(_act, "facing") ? _act.facing : undefined); _spr = _tl[0].spr; }
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
                var _tl = get_composite_character_sprite(_act.char_index, variable_struct_exists(_act, "pose") ? _act.pose : 1, variable_struct_exists(_act, "expression") ? _act.expression : 21, variable_struct_exists(_act, "facing") ? _act.facing : undefined);
                var _spr = _tl[0].spr;
                if (_spr != -1) {
                    var _sw = sprite_get_width(_spr);
                    var _sh = sprite_get_height(_spr);
                    var _scale = (scene_win_h * 1.5) / 450;
                    var _ax = scene_win_x + _act.x;
                    var _ay = scene_win_y + _act.y;
                    var _hit_top = _ay - (_sh + max(0, -_tl[1].dy)) * _scale;
                    if (_mx > _ax - (_sw*_scale)/2 && _mx < _ax + (_sw*_scale)/2 && _my > _hit_top && _my < _ay) {
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
                        var _row = floor(selected_character_index / 2);
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
                if (_spr == -1) { var _tl = get_composite_character_sprite(_act.char_index, variable_struct_exists(_act, "pose") ? _act.pose : 1, variable_struct_exists(_act, "expression") ? _act.expression : 21, variable_struct_exists(_act, "facing") ? _act.facing : undefined); _spr = _tl[0].spr; }
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
    if (SHOW_EXPR_CFG && !theater_mode && playing_block_index == -1 && _mx > char_sel_x + 195 && _mx < char_sel_x + char_sel_w - 6 && _my > char_sel_y + 2 && _my < char_sel_y + 28) {
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

        // POSE / EXPR Combined Button Click (disabled for Narrator)
        var _is_narrator = (characters[selected_character_index].name == "NARRATOR");
        if (_mx > btn_pose_x && _mx < btn_expression_x + btn_expression_w && _my > btn_pose_y && _my < btn_pose_y + btn_pose_h) {
            if (_is_narrator) return;
            var _active_pose = selected_pose;
            var _active_expr = selected_expression;
            for (var pa = 0; pa < array_length(preview_actors); pa++) {
                if (preview_actors[pa].char_index == selected_character_index) {
                    _active_pose = variable_struct_exists(preview_actors[pa], "pose") ? preview_actors[pa].pose : _active_pose;
                    _active_expr = variable_struct_exists(preview_actors[pa], "expression") ? preview_actors[pa].expression : _active_expr;
                    break;
                }
            }
            pose_modal_locked_pose       = _active_pose;  pose_modal_temp_pose       = _active_pose;
            expression_modal_locked_expr = _active_expr;  expression_modal_temp_expr = _active_expr;
            pose_expr_pose_touched = false;
            pose_expr_expr_touched = false;
            pose_expr_modal_open = true;
            return;
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
    _overlay_active = (scene_modal_open || action_modal_open || theater_mode || move_modal_open || pose_modal_open || expression_modal_open || pose_expr_modal_open);
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
    _overlay_active = (file_menu_open || edit_mode || scene_modal_open || action_modal_open || theater_mode || move_modal_open || pose_modal_open || expression_modal_open || pose_expr_modal_open);

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
                    var _aname_u  = string_upper(_block.action_name);
                    var _aname_lo = string_lower(_block.action_name);
                    var _is_move      = (string_pos("MOVE", _aname_u) > 0 || string_pos("ENTER", _aname_u) > 0 || string_pos("EXIT", _aname_u) > 0);
                    var _has_looks    = (string_pos("looks ", _aname_lo) > 0);
                    var _has_and_pose = (_has_looks && string_pos("and pose ", _aname_lo) > 0);
                    var _is_expr_only = (string_pos("expression:", _aname_lo) > 0) || (_has_looks && !_has_and_pose);
                    var _is_pose      = (!_is_expr_only) && (string_pos("poses ", _aname_lo) > 0 || _has_and_pose
                                        || (string_pos("pose ", _aname_lo) > 0 && string_pos("poses ", _aname_lo) == 0 && !_has_looks));

                    if (_is_move) {
                        move_modal_open = true;
                        move_modal_target_index = i;
                        move_modal_edit_mode = true;
                        var _blk_spd = variable_struct_exists(_block, "speed") ? _block.speed : 1.9;
                        move_modal_temp_moonwalk = variable_struct_exists(_block, "moonwalk") ? _block.moonwalk : false;
                        move_modal_temp_speed_index = 2;
                        for (var j = 0; j < array_length(move_speeds); j++) {
                            if (abs(move_speeds[j] - _blk_spd) < 0.01) { move_modal_temp_speed_index = j; break; }
                        }
                    } else if (_is_pose) {
                        selected_character_index = _block.char_index;
                        // Parse pose number from any supported format
                        var _e_idx = 21;
                        var _p_num = 1;
                        if (string_pos("poses ", _aname_lo) > 0) {
                            var _p_start = string_pos("poses ", _aname_lo) + 6;
                            var _p_end = string_pos(" ", string_copy(_aname_lo, _p_start, 999));
                            _p_num = (_p_end > 0) ? real(string_digits(string_copy(_aname_lo, _p_start, _p_end))) : 1;
                            // Parse expression from "(MOODNAME)"
                            var _open_p = string_pos("(", _aname_lo); var _close_p = string_pos(")", _aname_lo);
                            if (_open_p > 0 && _close_p > _open_p) {
                                var _ms = string_upper(string_trim(string_copy(_block.action_name, _open_p + 1, _close_p - _open_p - 1)));
                                for (var _mi = 0; _mi < array_length(mood_names); _mi++) { if (mood_names[_mi] == _ms) { _e_idx = _mi + 1; break; } }
                            }
                        } else if (_has_and_pose) {
                            var _ap = string_pos("and pose ", _aname_lo) + 9;
                            _p_num = real(string_copy(_aname_lo, _ap, 1));
                            var _lp = string_pos("looks ", _aname_lo) + 6;
                            var _ms = string_upper(string_trim(string_copy(_aname_lo, _lp, _ap - 10 - _lp)));
                            for (var _mi = 0; _mi < array_length(mood_names); _mi++) { if (mood_names[_mi] == _ms) { _e_idx = _mi + 1; break; } }
                        } else {
                            // "pose N" format
                            var _pp = string_pos("pose ", _aname_lo) + 5;
                            _p_num = real(string_copy(_aname_lo, _pp, 1));
                        }
                        if (_p_num < 1 || _p_num > 4) _p_num = 1;
                        pose_modal_locked_pose = _p_num; pose_modal_temp_pose = _p_num;
                        expression_modal_locked_expr = _e_idx; expression_modal_temp_expr = _e_idx;
                        // touched flags: both for combined blocks, only pose for pose-only
                        pose_expr_pose_touched = true;
                        pose_expr_expr_touched = (_has_and_pose || string_pos("poses ", _aname_lo) > 0);
                        pose_modal_edit_mode = true; pose_modal_target_index = i;
                        pose_expr_modal_open = true;
                    } else if (_is_expr_only) {
                        selected_character_index = _block.char_index;
                        var _e_idx = 21;
                        if (string_pos("expression:", _aname_lo) > 0) {
                            var _colon = string_pos(":", _aname_lo);
                            var _ms = string_upper(string_trim(string_copy(_block.action_name, _colon + 1, 999)));
                            for (var _mi = 0; _mi < array_length(mood_names); _mi++) { if (mood_names[_mi] == _ms) { _e_idx = _mi + 1; break; } }
                        } else if (_has_looks) {
                            var _lp = string_pos("looks ", _aname_lo) + 6;
                            var _ms = string_upper(string_trim(string_copy(_aname_lo, _lp, 999)));
                            for (var _mi = 0; _mi < array_length(mood_names); _mi++) { if (mood_names[_mi] == _ms) { _e_idx = _mi + 1; break; } }
                        }
                        expression_modal_locked_expr = _e_idx; expression_modal_temp_expr = _e_idx;
                        var _cur_pose = selected_pose;
                        for (var pa = 0; pa < array_length(preview_actors); pa++) {
                            if (preview_actors[pa].char_index == _block.char_index) { _cur_pose = variable_struct_exists(preview_actors[pa], "pose") ? preview_actors[pa].pose : _cur_pose; break; }
                        }
                        pose_modal_locked_pose = _cur_pose; pose_modal_temp_pose = _cur_pose;
                        pose_expr_pose_touched = false;
                        pose_expr_expr_touched = true;
                        expression_modal_edit_mode = true; expression_modal_target_index = i;
                        pose_expr_modal_open = true;
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
                        var _row = floor(selected_character_index / 2);
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
                    var _row = floor(selected_character_index / 2);
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
        var _cols = 2; var _item_h = 135;
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
                    drag_off_y = -(_csh * _scale) / 2;
                    
                    // Auto-scroll logic
                    var _row = floor(selected_character_index / 2);
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
