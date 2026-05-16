/// @description Advanced Block Editor Logic (Fixed & Restored)
var _mx = mouse_x; var _my = mouse_y;

// --- Helper Layout Function ---
function get_text_pos(_txt, _target_pos, _wrap_w, _line_h) {
    var _tx = 0; var _ty = 0;
    for (var i = 1; i <= _target_pos; i++) {
        var _c = string_char_at(_txt, i);
        var _cw = string_width(_c);
        if (_c == " " || _c == "\n") {
            _tx += _cw; if (_c == "\n") { _tx = 0; _ty += _line_h; }
        } else {
            var _next_space = string_pos_ext(" ", _txt, i);
            var _next_nl = string_pos_ext("\n", _txt, i);
            var _end = string_length(_txt);
            if (_next_space > 0) _end = min(_end, _next_space - 1);
            if (_next_nl > 0) _end = min(_end, _next_nl - 1);
            var _word = string_copy(_txt, i, _end - i + 1);
            if (_tx + string_width(_word) > _wrap_w && _tx > 0) { _tx = 0; _ty += _line_h; }
            _tx += _cw;
        }
    }
    return { x: _tx, y: _ty };
}

// --- 0. SCRIPT HEIGHT CALCULATION ---
// (Now handled on-demand via update_block_height and update_all_block_heights)

// --- 1. TTS SEQUENTIAL PLAYBACK & AUTO-SCROLL ---
if (playing_block_index != -1) {
    var _b = script_blocks[playing_block_index];
    var _target_y = 0;
    for (var i = 0; i < playing_block_index; i++) _target_y += script_blocks[i].height + 20;
    
    var _is_scene = (variable_struct_exists(_b, "type") && _b.type == "scene");
    var _header_offset = _is_scene ? 0 : 30; // Center on the name label/scene header
    var _char_progress_y = 0;
    
    if (is_speaking && string_length(_b.text) > 0) {
        var _cur_char = floor(speaking_index);
        var _sub = string_copy(_b.text, 1, _cur_char);
        _char_progress_y = string_height_ext(_sub, 28, box_w - 120);
    }
    
    var _dest_scroll = -(_target_y + _header_offset + _char_progress_y) + (box_h / 2); 
    block_scroll_y += (_dest_scroll - block_scroll_y) * 0.15; // Faster interpolation
    block_scroll_y = min(0, block_scroll_y);
}

// --- 1.1 ACTION ANIMATOR ---
if (action_animating) {
    var _act_idx = -1;
    for (var a = 0; a < array_length(preview_actors); a++) {
        if (preview_actors[a].char_index == action_anim_char_index) { _act_idx = a; break; }
    }
    
    if (_act_idx != -1) {
        var _act = preview_actors[_act_idx];
        var _dist = point_distance(_act.x, _act.y, action_anim_target_x, action_anim_target_y);
        
        if (_dist > action_anim_speed) {
            var _dir = point_direction(_act.x, _act.y, action_anim_target_x, action_anim_target_y);
            _act.x += lengthdir_x(action_anim_speed, _dir);
            _act.y += lengthdir_y(action_anim_speed, _dir);
        } else {
            _act.x = action_anim_target_x;
            _act.y = action_anim_target_y;
            action_animating = false;
            speaking_pause_timer = 5;
            if (action_anim_type == "exit") array_delete(preview_actors, _act_idx, 1);
        }
    } else { action_animating = false; }
}

if (is_speaking && active_request_id != -1) {
    var _done_file = working_directory + "talkit\\talkit_done_" + string(active_request_id) + ".tmp";
    if (file_exists(_done_file)) {
        if (playing_block_index != -1 && playing_block_index < array_length(script_blocks) - 1) {
            is_speaking = false; speaking_pause_timer = 15; file_delete(_done_file);
        } else {
            is_speaking = false; last_played_block_index = playing_block_index; 
            file_delete(_done_file); tts_stop();
            
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
}

// Auto-stop if current block is scene/action and it's the last block
if (!is_speaking && !action_animating && playing_block_index != -1) {
    var _lb = script_blocks[playing_block_index];
    var _lb_is_scene = (variable_struct_exists(_lb, "type") && _lb.type == "scene");
    var _lb_is_action = (variable_struct_exists(_lb, "type") && _lb.type == "action");
    if ((_lb_is_scene || _lb_is_action) && playing_block_index >= array_length(script_blocks) - 1) {
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

// Sequence Advance
if (!is_speaking && !action_animating && playing_block_index != -1 && !theater_paused) {
    if (speaking_pause_timer > 0) {
        speaking_pause_timer--;
    } else {
        // If speaking_pause_timer == 0, we need to advance. 
        // If speaking_pause_timer == -1, we stay on current index (first play).
        if (speaking_pause_timer == 0) {
            if (playing_block_index < array_length(script_blocks) - 1) {
                playing_block_index++;
            } else {
                if (theater_mode) {
                    theater_subtitles = ""; theater_active_char = -1;
                    theater_paused = true;
                    play_from_index(0); // Rewind
                    playing_block_index = -1;
                } else {
                    playing_block_index = -1;
                    theater_paused = false; 
                }
                return;
            }
        }
        if (speaking_pause_timer == -1) speaking_pause_timer = 0;

        var _b = script_blocks[playing_block_index];
        var _is_scene = (variable_struct_exists(_b, "type") && _b.type == "scene");
        var _is_action = (variable_struct_exists(_b, "type") && _b.type == "action");
            
            if (_is_scene) {
                current_scene_sprite = get_scene_sprite(_b.internal_name);
                set_scene_dimensions(current_scene_sprite);
                speaking_pause_timer = 60; // Give scene 1 second to breathe
                
                active_scene_block_idx = playing_block_index;
                preview_actors = [];
                if (variable_struct_exists(_b, "actors")) {
                    for(var a=0; a<array_length(_b.actors); a++) {
                        var _act = _b.actors[a];
                        var _face = variable_struct_exists(_act, "facing") ? _act.facing : char_facings[_act.char_index];
                        array_push(preview_actors, { char_index: _act.char_index, x: _act.x, y: _act.y, is_base: true, facing: _face });
                    }
                }
            } else if (_is_action) {
                var _aname = string_lower(_b.action_name);
                var _is_enter = (string_pos("enter", _aname) > 0);
                var _is_exit = (string_pos("exit", _aname) > 0);
                var _is_left = (string_pos("left", _aname) > 0);
                
                var _act_idx = -1;
                for (var a = 0; a < array_length(preview_actors); a++) {
                    if (preview_actors[a].char_index == _b.char_index) { _act_idx = a; break; }
                }
                
                var _spr = get_character_sprite(_b.char_index);
                var _w = (_spr != -1) ? sprite_get_width(_spr) * ((scene_win_h * 0.75) / sprite_get_height(_spr)) : 100;
                
                if (_is_enter) {
                    if (_act_idx != -1) { speaking_pause_timer = 5; } // Conflict
                    else {
                        var _start_x = _is_left ? -(_w/2) : scene_win_w + (_w/2);
                        char_facings[_b.char_index] = _is_left ? -1 : 1;
                        var _target_y = variable_struct_exists(_b, "target_y") ? _b.target_y : (scene_win_h * 0.8);
                        array_push(preview_actors, { char_index: _b.char_index, x: _start_x, y: _target_y, is_base: false, facing: char_facings[_b.char_index] });
                        action_animating = true;
                        action_anim_char_index = _b.char_index;
                        action_anim_type = "enter";
                        action_anim_target_x = variable_struct_exists(_b, "target_x") ? _b.target_x : (_is_left ? (_w/2) + 20 : scene_win_w - (_w/2) - 20);
                        action_anim_target_y = variable_struct_exists(_b, "target_y") ? _b.target_y : scene_win_h;
                    }
                } else if (_is_exit) {
                    if (_act_idx == -1) { speaking_pause_timer = 5; } // Conflict
                    else {
                        action_animating = true;
                        action_anim_char_index = _b.char_index;
                        action_anim_type = "exit";
                        
                        // Intelligently choose exit side if not specified
                        var _current_x = preview_actors[_act_idx].x;
                        var _exit_left = (string_pos("left", _aname) > 0);
                        var _exit_right = (string_pos("right", _aname) > 0);
                        if (!_exit_left && !_exit_right) {
                            // Default to nearest side
                            _exit_left = (_current_x < scene_win_w / 2);
                        }
                        
                        char_facings[_b.char_index] = _exit_left ? 1 : -1;
                        preview_actors[_act_idx].facing = char_facings[_b.char_index];
                        
                        action_anim_target_x = _exit_left ? -(_w/2) - 50 : scene_win_w + (_w/2) + 50;
                        action_anim_target_y = preview_actors[_act_idx].y;
                    }
                } else if (string_pos("turn", _aname) > 0) {
                    char_facings[_b.char_index] *= -1;
                    if (_act_idx != -1) preview_actors[_act_idx].facing = char_facings[_b.char_index];
                    speaking_pause_timer = 5;
                } else if (string_pos("moves", _aname) > 0) {
                    if (_act_idx != -1) {
                        action_animating = true;
                        action_anim_char_index = _b.char_index;
                        action_anim_type = "move";
                        action_anim_target_x = _b.target_x;
                        action_anim_target_y = _b.target_y;
                        // Face target: Right is -1, Left is 1 (based on previous swap)
                        if (action_anim_target_x > preview_actors[_act_idx].x) char_facings[_b.char_index] = -1;
                        else if (action_anim_target_x < preview_actors[_act_idx].x) char_facings[_b.char_index] = 1;
                        preview_actors[_act_idx].facing = char_facings[_b.char_index];
                    } else { speaking_pause_timer = 5; }
                } else { speaking_pause_timer = 5; }
            } else {
                var _c = characters[_b.char_index];
                active_request_id = tts_speak(_b.text, _c.voice_id, _c.pitch, _c.speed, _c.mode, _c.style);
                is_speaking = true;
            }
            
            // Update Talking State
            if (_is_scene || _is_action) { 
                theater_active_char = -1; 
                if (theater_mode) theater_subtitles = ""; 
            } else { 
                theater_active_char = _b.char_index; 
                if (theater_mode) theater_subtitles = _b.text; 
            }
        }
    }

    // --- 4. ANIMATION ENGINE ---
    if (action_animating) {
        var _spd = action_anim_speed;
        var _done = true;
        for (var i = 0; i < array_length(preview_actors); i++) {
            if (preview_actors[i].char_index == action_anim_char_index) {
                _done = false;
                var _dx = action_anim_target_x - preview_actors[i].x;
                var _dy = action_anim_target_y - preview_actors[i].y;
                var _dist = point_distance(preview_actors[i].x, preview_actors[i].y, action_anim_target_x, action_anim_target_y);
                
                if (_dist < _spd) {
                    preview_actors[i].x = action_anim_target_x;
                    preview_actors[i].y = action_anim_target_y;
                    _done = true;
                } else {
                    var _dir = point_direction(preview_actors[i].x, preview_actors[i].y, action_anim_target_x, action_anim_target_y);
                    preview_actors[i].x += lengthdir_x(_spd, _dir);
                    preview_actors[i].y += lengthdir_y(_spd, _dir);
                }
                break;
            }
        }
        
        if (_done) {
            action_animating = false;
            if (action_anim_type == "exit") {
                for (var i = 0; i < array_length(preview_actors); i++) {
                    if (preview_actors[i].char_index == action_anim_char_index) { array_delete(preview_actors, i, 1); break; }
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
        var _scene = script_blocks[active_scene_block_idx];
        
        // FLIP Button
        if (_mx > _bx && _mx < _bx + _mw && _my > _by && _my < _by + _mh) {
            if (scene_edit_menu_actor_idx != -1 && scene_edit_menu_actor_idx < array_length(_scene.actors)) {
                var _act = _scene.actors[scene_edit_menu_actor_idx];
                _act.facing = (variable_struct_exists(_act, "facing") ? _act.facing : 1) * -1;
            }
            return;
        }
        
        // Close menu on click anywhere else (and allow the click to pass through)
        scene_edit_menu_open = false;
    }
}

// --- 2. MODAL LOGIC (Edit Mode) ---
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
                if (_mx > _m_x + 485 && _mx < _m_x + 510) modal_speed = min(180, modal_speed + 5);
                if (_mx > _m_x + 180 && _mx < _m_x + 480) modal_speed = ((_mx - (_m_x + 180)) / 300) * 180;
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

        // Bottom Buttons
        var _btn_y = _m_y + _m_h - 60;
        if (_mx > _m_x + 30 && _mx < _m_x + 150 && _my > _btn_y && _my < _btn_y + 40) { tts_stop(); tts_speak("Testing settings", modal_voice_id, modal_pitch, modal_speed, modal_effort, modal_quality); }
        if (_mx > _m_x + _m_w - 280 && _mx < _m_x + _m_w - 150 && _my > _btn_y && _my < _btn_y + 40) {
            var _c = characters[selected_character_index];
            _c.voice_id = modal_voice_id; _c.pitch = modal_pitch; _c.speed = modal_speed;
            _c.mode = modal_effort; _c.style = modal_quality; _c.tweaked = tweak_enabled;
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
                    var _new_scene = { type: "scene", name: _data.name, internal_name: _data.internal_name, actors: [], height: 80 };
                    if (scene_modal_target_index == -1) array_push(script_blocks, _new_scene);
                    else array_insert(script_blocks, scene_modal_target_index, _new_scene);
                    update_all_block_heights();
                    scene_modal_open = false; return;
                }
            }
        }
        
        // Cancel Button
        var _c_y = _m_y + _m_h - 50;
        if (_mx > _m_x + 20 && _mx < _m_x + _m_w - 20 && _my > _c_y && _my < _c_y + 35) {
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

// --- 2c. INSERTION CONTEXT MENU ---
if (insert_menu_open) {
    var _m_w = 120; var _m_h = 70;
    if (mouse_check_button_pressed(mb_left)) {
        var _clicked_option = false;
        // Voice option
        if (_mx > insert_menu_x && _mx < insert_menu_x + _m_w && _my > insert_menu_y && _my < insert_menu_y + 35) {
            var _idx = insert_menu_above ? insert_menu_target_idx : insert_menu_target_idx + 1;
            array_insert(script_blocks, _idx, { char_index: selected_character_index, text: "", height: 60, caret_pos: 0, selection_anchor: 0, selection_active: false });
            update_all_block_heights();
            focused_block = _idx; keyboard_string = ""; _clicked_option = true;
        }
        // Scene option
        else if (_mx > insert_menu_x && _mx < insert_menu_x + _m_w && _my > insert_menu_y + 35 && _my < insert_menu_y + 70) {
            scene_modal_target_index = insert_menu_above ? insert_menu_target_idx : insert_menu_target_idx + 1;
            scene_modal_open = true; _clicked_option = true;
        }
        // Action option
        else if (selected_character_index != 0 && _mx > insert_menu_x && _mx < insert_menu_x + _m_w && _my > insert_menu_y + 70 && _my < insert_menu_y + 105) {
            action_modal_target_index = insert_menu_above ? insert_menu_target_idx : insert_menu_target_idx + 1;
            
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
		        }
        else if (_b.type == "action" && _b.char_index == selected_character_index) {
            var _aname = string_lower(_b.action_name);
            if (string_pos("enter", _aname) > 0) _is_onstage = true;
            else if (string_pos("exit", _aname) > 0) _is_onstage = false;
        }
    }
}
            action_modal_char_onstage = _is_onstage;
            
            action_modal_open = true; 
            action_modal_selected_idx = -1;
            action_modal_locked = false;
            _clicked_option = true;
        }
        
        insert_menu_open = false;
        if (_clicked_option) return;
    }
}

// --- 2c. ACTION MODAL INTERACTION ---
if (action_modal_open) {
    var _m_w = 600; var _m_h = 400;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    var _list_x = _m_x + 20; var _list_y = _m_y + 60;
    var _list_w = 250; var _item_h = 40;

    if (mouse_check_button_pressed(mb_left)) {
        // Selection
        for (var i = 0; i < array_length(all_actions); i++) {
            var _iy = _list_y + (i * (_item_h + 5));
            if (_mx > _list_x && _mx < _list_x + _list_w && _my > _iy && _my < _iy + _item_h) {
                action_modal_selected_idx = i;
                action_modal_locked = true;
                return;
            }
        }

        var _btn_y = _m_y + _m_h - 50;
        // OK Button
        if (action_modal_locked && _mx > _m_x + 20 && _mx < _m_x + _m_w/2 - 10 && _my > _btn_y && _my < _btn_y + 35) {
            var _act = all_actions[action_modal_selected_idx];
            var _new_block = { type: "action", char_index: selected_character_index, action_name: _act.name, height: 80 };
            if (action_modal_target_index == -1) array_push(script_blocks, _new_block);
            else array_insert(script_blocks, action_modal_target_index, _new_block);
            update_all_block_heights();
            action_modal_open = false; return;
        }

        // Cancel Button
        if (_mx > _m_x + _m_w/2 + 10 && _mx < _m_x + _m_w - 20 && _my > _btn_y && _my < _btn_y + 35) {
            action_modal_open = false; return;
        }
    }
    return;
}

// --- 2d. CHARACTER SELECTOR CLICKS & DRAGS ---
if (mouse_check_button_pressed(mb_left)) {
    if (_mx > char_sel_x && _mx < char_sel_x + char_sel_w && _my > char_sel_y && _my < char_sel_y + char_sel_h) {
        var _grid_x = char_sel_x + 10;
        var _grid_y = char_sel_y + 35;
        var _item_w = 80;
        var _item_h = 100;
        var _cols = 4;
        for (var i = 0; i < array_length(characters); i++) {
            var _ix = _grid_x + (i % _cols) * _item_w;
            var _iy = _grid_y + floor(i / _cols) * _item_h + char_sel_scroll_y;
            if (_my > char_sel_y + 30 && _mx > _ix && _mx < _ix + _item_w && _my > _iy && _my < _iy + _item_h) {
                selected_character_index = i;
                dropdown_open = false;
                dragging_char_index = i; // Unified drag start
                return;
            }
        }
    }
}

// --- 2e. IN-SCENE DRAGGING & DROPPING ---
if (scene_edit_mode && active_scene_block_idx != -1) {
    var _scene = script_blocks[active_scene_block_idx];
    
    // Start dragging actor already in scene / or just Click to open menu
    if (mouse_check_button_pressed(mb_left)) {
        if (_mx > scene_win_x && _mx < scene_win_x + scene_win_w && _my > scene_win_y && _my < scene_win_y + scene_win_h) {
            for (var a = array_length(_scene.actors) - 1; a >= 0; a--) {
                var _act = _scene.actors[a];
                var _spr = get_character_sprite(_act.char_index);
                if (_spr != -1) {
                    var _sw = sprite_get_width(_spr);
                    var _sh = sprite_get_height(_spr);
                    var _scale = (scene_win_h * 0.75) / 450; 
                    var _ax = scene_win_x + _act.x;
                    var _ay = scene_win_y + _act.y;
                    var _face = variable_struct_exists(_act, "facing") ? _act.facing : 1;
                    if (_mx > _ax - (_sw*_scale)/2 && _mx < _ax + (_sw*_scale)/2 && _my > _ay - (_sh*_scale) && _my < _ay) {
                        dragging_actor_idx = a;
                        scene_edit_selected_actor_idx = a; // Select on click
                        selected_character_index = _act.char_index; // Sync global selection
                        
                        // Auto-scroll character pane
                        var _row = floor(selected_character_index / 4);
                        var _iy = _row * 100;
                        if (_iy + char_sel_scroll_y < 0) char_sel_scroll_y = -_iy;
                        else if (_iy + 100 + char_sel_scroll_y > char_sel_h - 35) char_sel_scroll_y = -( _iy - (char_sel_h - 135) );
                        
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
            var _scale = (scene_win_h * 0.75) / 450; 
            
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
                var _sc = (scene_win_h * 0.75) / 450; 
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
if (scene_edit_mode && scene_edit_selected_actor_idx != -1 && mouse_check_button_pressed(mb_left)) {
    var _btn_x = scene_win_x + 200; var _btn_y = scene_win_y - 30;
    if (_mx > _btn_x && _mx < _btn_x + 100 && _my > _btn_y && _my < _btn_y + 30) {
        var _scene = script_blocks[active_scene_block_idx];
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
                    var _scale = (scene_win_h * 0.75) / 450; 
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
                        var _row = floor(selected_character_index / 4);
                        var _iy = _row * 100;
                        if (_iy + char_sel_scroll_y < 0) char_sel_scroll_y = -_iy;
                        else if (_iy + 100 + char_sel_scroll_y > char_sel_h - 35) char_sel_scroll_y = -( _iy - (char_sel_h - 135) );
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
            var _scale = (scene_win_h * 0.75) / 450; 

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
                var _sc = (scene_win_h * 0.75) / 450; 
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
                
                array_insert(script_blocks, _insert_idx, { 
                    type: "action", 
                    action_name: _aname, 
                    char_index: _act.char_index, 
                    target_x: _act.x, 
                    target_y: _act.y,
                    facing: _act.facing,
                    height: 85 
                });
                focused_block = _insert_idx;
                insertion_idx = -1; // Reset after commit
                dragging_preview_idx = -1;
            }
        }
    }
}

// --- 2g. MODE DISMISSAL (Label Click) ---
if (insertion_idx != -1 && mouse_check_button_pressed(mb_left)) {
    if (_mx > scene_win_x && _mx < scene_win_x + 180 && _my > scene_win_y - 30 && _my < scene_win_y) {
        insertion_idx = -1;
        return;
    }
}
if (scene_edit_mode && mouse_check_button_pressed(mb_left)) {
    if (_mx > scene_win_x && _mx < scene_win_x + 180 && _my > scene_win_y - 30 && _my < scene_win_y) {
        scene_edit_mode = false;
        return;
    }
}

if (mouse_check_button_pressed(mb_left)) {
    // PLAY Button
    if (_mx > btn_play_x && _mx < btn_play_x + btn_play_w && _my > btn_play_y && _my < btn_play_y + btn_play_h) {
        if (playing_block_index != -1) {
            playing_block_index = -1; is_speaking = false; audio_stop_all(); tts_stop();
            theater_mode = false; theater_paused = false; theater_subtitles = "";
        } else if (array_length(script_blocks) > 0) {
            play_from_index(0);
        }
        return;
    }

    // ENTER THEATER Button
    if (!theater_mode && !is_speaking && playing_block_index == -1 && insertion_idx == -1 && !scene_edit_mode && !action_modal_open && !scene_modal_open) {
        if (_mx > btn_theater_x && _mx < btn_theater_x + btn_theater_w && _my > btn_theater_y && _my < btn_theater_y + btn_theater_h) {
            theater_mode = true;
            theater_paused = true; // Start PAUSED on entry
            theater_subtitles = "";
            play_from_index(0); 
            return;
        }
    }

    if (theater_mode) {
        // Theater Mode Controls
        if (mouse_check_button_pressed(mb_left)) {
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
    if (!is_speaking && _mx > btn_add_x && _mx < btn_add_x + btn_add_w && _my > btn_add_y && _my < btn_add_y + btn_add_h) {
        var _idx = (insertion_idx != -1) ? insertion_idx + 1 : array_length(script_blocks);
        array_insert(script_blocks, _idx, { type: "voice", char_index: selected_character_index, text: "", height: 115, caret_pos: 0, selection_anchor: 0, selection_active: false });
        update_block_height(_idx);
        focused_block = _idx; insertion_idx = -1; keyboard_string = ""; 
        scene_edit_mode = false; 
        
        // Auto-scroll to show the new line
        var _th = 0; for (var k = 0; k < array_length(script_blocks); k++) _th += script_blocks[k].height + 20;
        block_scroll_y = min(0, (box_h - 40) - _th);
        return;
    }

    // ADD ACTION Button (Now also inserts at focused point)
    if (!is_speaking && _mx > btn_add_action_x && _mx < btn_add_action_x + btn_add_action_w && _my > btn_add_action_y && _my < btn_add_action_y + btn_add_action_h) {
        if (selected_character_index != 0) {
            action_modal_open = true;
            action_modal_target_index = (insertion_idx != -1) ? insertion_idx + 1 : -1;
            action_modal_selected_idx = -1;
            action_modal_locked = false;
            // Check if char is onstage
            action_modal_char_onstage = false;
            if (active_scene_block_idx != -1) {
                for (var pa = 0; pa < array_length(preview_actors); pa++) {
                }
            }
            scene_edit_mode = false;
        }
        return;
    }

    // ADD SCENE Button (Now also inserts at focused point)
    if (!is_speaking && _mx > btn_add_scene_x && _mx < btn_add_scene_x + btn_add_scene_w && _my > btn_add_scene_y && _my < btn_add_scene_y + btn_add_scene_h) {
        scene_modal_open = true;
        scene_modal_target_index = (insertion_idx != -1) ? insertion_idx + 1 : -1;
        scene_edit_mode = false;
        return;
    }

    // --- 4b. MODAL INTERACTION (Scene/Action Selection) ---
    if (scene_modal_open) {
        var _mw = 700; var _mh = 450; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
        var _lw = 300; var _max_h = 320;
        var _list_h = array_length(all_scenes) * 40;
        
        // Modal Scroll Wheel
        if (mouse_wheel_up()) scene_modal_scroll_y = min(0, scene_modal_scroll_y + 40);
        if (mouse_wheel_down()) {
            if (_list_h > _max_h) scene_modal_scroll_y = max(-(_list_h - _max_h), scene_modal_scroll_y - 40);
        }

        if (mouse_check_button_pressed(mb_left)) {
            for (var i = 0; i < array_length(all_scenes); i++) {
                var _by = _myo + 60 + (i * 40) + scene_modal_scroll_y;
                if (_by + 35 < _myo+60 || _by > _myo+60+_max_h) continue;
                if (_mx > _mxo+20 && _mx < _mxo+20+_lw && _my > _by && _my < _by+35) {
                    var _new_s = { type: "scene", name: all_scenes[i].name, internal_name: all_scenes[i].internal_name, height: 85, actors: [] };
                    var _new_idx = -1;
                    if (scene_modal_target_index == -1) {
                        array_push(script_blocks, _new_s);
                        _new_idx = array_length(script_blocks) - 1;
                    } else {
                        array_insert(script_blocks, scene_modal_target_index, _new_s);
                        _new_idx = scene_modal_target_index;
                    }
                    update_all_block_heights();
                    scene_modal_open = false;
                    
                    // Auto-enable Staging Mode for the new scene
                    focused_block = _new_idx;
                    scene_edit_mode = true;
                    insertion_idx = -1;
                    active_scene_block_idx = _new_idx;
                    current_scene_sprite = get_scene_sprite(_new_s.internal_name);
                    set_scene_dimensions(current_scene_sprite);
                    
                    var _th = 0; for (var k = 0; k < array_length(script_blocks); k++) _th += script_blocks[k].height + 20;
                    block_scroll_y = min(0, (box_h - 40) - _th);
                    return;
                }
            }
            // Cancel check
            if (_mx > _mxo+20 && _mx < _mxo+290 && _my > _myo+400 && _my < _myo+435) { scene_modal_open = false; return; }
        }
        return; // Block all other UI interactions
    }

    if (action_modal_open) {
        if (mouse_check_button_pressed(mb_left)) {
            var _mw = 600; var _mh = 400; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
            for (var i = 0; i < array_length(all_actions); i++) {
                var _by = _myo + 60 + (i * 45);
                var _aname = string_lower(all_actions[i].name);
                var _disabled = false;
                if (action_modal_char_onstage && string_pos("enter", _aname) > 0) _disabled = true;
                if (!action_modal_char_onstage && string_pos("exit", _aname) > 0) _disabled = true;
                if (!_disabled && _mx > _mxo+20 && _mx < _mxo+270 && _my > _by && _my < _by+40) {
                    action_modal_selected_idx = i; action_modal_locked = true; return;
                }
            }
            // OK Button
            if (action_modal_locked && _mx > _mxo+20 && _mx < _mxo+290 && _my > _myo+350 && _my < _myo+385) {
                var _new_a = { type: "action", char_index: selected_character_index, action_name: all_actions[action_modal_selected_idx].name, height: 85 };
                if (action_modal_target_index == -1) array_push(script_blocks, _new_a);
                else array_insert(script_blocks, action_modal_target_index, _new_a);
                update_all_block_heights();
                action_modal_open = false;
                
                var _th = 0; for (var k = 0; k < array_length(script_blocks); k++) _th += script_blocks[k].height + 20;
                block_scroll_y = min(0, (box_h - 40) - _th);
                return;
            }
            // Cancel
            if (_mx > _mxo+310 && _mx < _mxo+580 && _my > _myo+350 && _my < _myo+385) { action_modal_open = false; return; }
        }
        return; // Block all other UI interactions
    }

    // EDIT VOICE Button
    if (!is_speaking && _mx > btn_edit_x && _mx < btn_edit_x + btn_edit_w && _my > btn_edit_y && _my < btn_edit_y + btn_edit_h) {
        edit_mode = true;
        scene_edit_mode = false; // Exit edit mode on edit voice
        var _c = characters[selected_character_index];
        modal_voice_id = _c.voice_id; modal_pitch = _c.pitch; modal_speed = _c.speed;
        modal_mode = _c.mode; modal_style = _c.style; tweak_enabled = _c.tweaked;
        return;
    }
}

// DROPDOWN Button Removed (Using Character Pane instead)

    // --- 4. SCRIPT AREA CLICKS (Block Focus & Caret) ---
    var _clip_x = box_x + 10; var _clip_y = box_y + 5; 
    var _text_margin = 15;
    var _wrap_w = box_w - 120; // Standardized wrap width
    
    var _found_block = focused_block;
    if (mouse_check_button_pressed(mb_left) && _mx > box_x - 50 && _mx < box_x + box_w && _my > box_y && _my < box_y + box_h) {
        var _cy = _clip_y + block_scroll_y;
        for (var i = 0; i < array_length(script_blocks); i++) {
            var _block = script_blocks[i];
            var _bh = _block.height;
            var _is_scene = (variable_struct_exists(_block, "type") && _block.type == "scene");
            var _is_action = (variable_struct_exists(_block, "type") && _block.type == "action");
            var _is_voice = (variable_struct_exists(_block, "type") && _block.type == "voice");
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

            // 1. Delete (X) - Anchored to _cy
            if (_mx > _bx && _mx < _bx + _bw && _my > _cy && _my < _cy + _btn_h) {
                array_delete(script_blocks, i, 1);
                update_all_block_heights();
                if (focused_block >= array_length(script_blocks)) focused_block = array_length(script_blocks) - 1;
                return;
            }
            // 2. Insert Up (^+) - Anchored to _cy + 30
            else if (_mx > _bx && _mx < _bx + _bw && _my > _cy + 30 && _my < _cy + 30 + _btn_h) {
                insert_menu_open = true; 
                insert_menu_x = min(_mx, 1280 - 130); 
                insert_menu_y = min(_my, 800 - 80);
                insert_menu_target_idx = i; insert_menu_above = true; return;
            }
            // 3. Insert Down (v+) - Anchored to _cy + 60
            else if (_mx > _bx && _mx < _bx + _bw && _my > _cy + 60 && _my < _cy + 60 + _btn_h) {
                insert_menu_open = true; 
                insert_menu_x = min(_mx, 1280 - 130); 
                insert_menu_y = min(_my, 800 - 80);
                insert_menu_target_idx = i; insert_menu_above = false; return;
            }

            // --- 4c. RESEQUENCE BUTTONS (LEFT STACK) ---
            var _lx = box_x + 15;
            // UP
            if (_mx > _lx && _mx < _lx + _bw && _my > _cy && _my < _cy + _btn_h) {
                if (i > 0) {
                    var _h = script_blocks[i-1].height + 25;
                    var _temp = script_blocks[i]; script_blocks[i] = script_blocks[i-1]; script_blocks[i-1] = _temp;
                    block_scroll_y += _h; // Shift scroll to keep block under mouse
                    if (focused_block == i) focused_block = i-1; else if (focused_block == i-1) focused_block = i;
                }
                return;
            }
            // PENCIL (EDIT)
            else if (_mx > _lx && _mx < _lx + _bw && _my > _cy + 30 && _my < _cy + 30 + _btn_h) {
                // Placeholder for editing logic
                return;
            }
            // DOWN
            else if (_mx > _lx && _mx < _lx + _bw && _my > _cy + 60 && _my < _cy + 60 + _btn_h) {
                if (i < array_length(script_blocks) - 1) {
                    var _h = script_blocks[i+1].height + 25;
                    var _temp = script_blocks[i]; script_blocks[i] = script_blocks[i+1]; script_blocks[i+1] = _temp;
                    block_scroll_y -= _h; // Shift scroll to keep block under mouse
                    if (focused_block == i) focused_block = i+1; else if (focused_block == i+1) focused_block = i;
                }
                return;
            }
            
            // 4. PLAY FROM HERE (Green Triangle) - Now in the GUTTER
            var _px = box_x - 30; var _py = _cy + 5;
            if (_mx > _px && _mx < _px + 30 && _my > _py && _my < _py + 30) {
                play_from_index(i);
                return;
            }

            if (_is_scene) {
                // Scene Box Click (Enable Staging)
                if (_mx > box_x + 55 && _mx < box_x + 55 + _wrap_w + 20 && _my > _box_y && _my < _box_y + 80) {
                    focused_block = i;
                    scene_edit_mode = !scene_edit_mode; // Toggle
                    insertion_idx = -1; // Turn off Splice Mode
                    if (scene_edit_mode) {
                        active_scene_block_idx = i;
                    // Refresh preview actors to match THIS scene specifically
                    preview_actors = [];
                    if (variable_struct_exists(_block, "actors")) {
                        for(var a=0; a<array_length(_block.actors); a++) {
                            var _act = _block.actors[a];
                            var _face = variable_struct_exists(_act, "facing") ? _act.facing : 1;
                            array_push(preview_actors, { char_index: _act.char_index, x: _act.x, y: _act.y, is_base: true, facing: _face });
                        }
                    }
                    current_scene_sprite = get_scene_sprite(_block.internal_name);
                        set_scene_dimensions(current_scene_sprite);
                    }
                    return;
                }
            } else if (_is_action || _is_voice) {
                // Other Blocks (Dialogue/Action) - Disable Staging
                if (_mx > box_x + 55 && _mx < box_x + 55 + _wrap_w + 20 && _my > _box_y && _my < _box_y + (_bh - 55)) {
                    focused_block = i;
                    scene_edit_mode = false; // Always OFF
                    insertion_idx = -1;
                    
                    if (_is_voice) {
                        keyboard_string = "";
                        var _rx = _mx - (box_x + 55 + _text_margin); var _ry = _my - (_box_y + 10);
                        var _best_p = 0; var _min_d = 999999;
                        for (var c = 0; c <= string_length(_block.text); c++) {
                            var _pos = get_text_pos(_block.text, c, _wrap_w, 28);
                            var _d = point_distance(_rx, _ry, _pos.x, _pos.y);
                            if (_d < _min_d) { _min_d = _d; _best_p = c; }
                        }
                        _block.caret_pos = _best_p;
                    }
                    return;
                }
            }
            
            // Main Block Focus Click
            if (_mx > box_x + 50 && _mx < box_x + box_w - 50 && _my > _cy && _my < _cy + _bh) {
                focused_block = i;
                insertion_idx = -1;
                if (!_is_scene && !_is_action) {
                    keyboard_string = ""; 
                    _block.caret_pos = string_length(_block.text);
                }
                return;
            }
            
            // --- 4d. GAP CLICK (Between blocks) ---
            if (i < array_length(script_blocks) - 1) {
                var _gap_y = _cy + _bh;
                if (_my > _gap_y && _my < _gap_y + 20 && _mx > box_x && _mx < box_x + box_w) {
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
        scene_edit_mode = false; // Exit Staging on empty area click
    }

// Scroll Wheel
if (!is_speaking && !edit_mode && !theater_mode) {
    var _over_pane = (_mx > char_sel_x && _mx < char_sel_x + char_sel_w && _my > char_sel_y && _my < char_sel_y + char_sel_h);
    
    if (_over_pane) {
        // Scroll the character selector
        var _cols = 4; var _item_h = 100;
        var _total_h = ceil(array_length(characters) / _cols) * _item_h;
        var _max_visible_h = char_sel_h - 35;
        if (mouse_wheel_up()) char_sel_scroll_y = min(0, char_sel_scroll_y + _item_h);
        if (mouse_wheel_down()) {
            if (_total_h > _max_visible_h) char_sel_scroll_y = max(-(_total_h - _max_visible_h), char_sel_scroll_y - _item_h);
        }
        
        // --- CHARACTER SELECTION & DRAG START ---
        if (mouse_check_button_pressed(mb_left)) {
            var _grid_x = char_sel_x + 10; var _grid_y = char_sel_y + 35;
            for (var i = 0; i < array_length(characters); i++) {
                var _ix = _grid_x + (i % _cols) * 80;
                var _iy = _grid_y + floor(i / _cols) * _item_h + char_sel_scroll_y;
                if (_mx > _ix && _mx < _ix + 80 && _my > _iy && _my < _iy + _item_h && _my > char_sel_y + 30 && _my < char_sel_y + char_sel_h) {
                    var _spr = get_character_sprite(i);
                    var _csh = (_spr != -1) ? sprite_get_height(_spr) : 100;
                    var _scale = (scene_win_h * 0.75) / 450; 
                    
                    selected_character_index = i;
                    dragging_char_index = i; // START DRAGGING (Unified)
                    drag_off_x = 0;
                    drag_off_y = -(_csh * _scale) / 2;
                    
                    // Auto-scroll logic
                    var _row = floor(selected_character_index / 4);
                    var _iy_scroll = _row * 100;
                    if (_iy_scroll + char_sel_scroll_y < 0) char_sel_scroll_y = -_iy_scroll;
                    else if (_iy_scroll + 100 + char_sel_scroll_y > char_sel_h - 35) char_sel_scroll_y = -( _iy_scroll - (char_sel_h - 135) );
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
if (dragging_char_index != -1) {
    if (!mouse_check_button(mb_left)) {
        var _spr_ghost = get_character_sprite(dragging_char_index);
        var _char_h = (_spr_ghost != -1) ? sprite_get_height(_spr_ghost) * ((scene_win_h * 0.75) / 450) : 100;
        var _char_w = (_spr_ghost != -1) ? sprite_get_width(_spr_ghost) * ((scene_win_h * 0.75) / 450) : 100;

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
                if (active_scene_block_idx != -1) {
                    var _scene = script_blocks[active_scene_block_idx];
                    var _dup = false;
                    for (var a = 0; a < array_length(_scene.actors); a++) {
                        if (_scene.actors[a].char_index == dragging_char_index) { _dup = true; break; }
                    }
                    if (!_dup) {
                        // Auto-flip for entrance
                        var _is_left = (_mx < scene_win_x + (scene_win_w / 2));
                        _face = _is_left ? -1 : 1;
                        
                        // Precise coordinates within background
                        var _nx = _px;
                        var _ny = _py;
                        
                        array_push(_scene.actors, { char_index: dragging_char_index, x: _nx, y: _ny, facing: _face });
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
                    var _aname = _is_left ? "enters left and moves" : "enters right and moves";
                    
                    var _insert_idx = (insertion_idx != -1) ? insertion_idx + 1 : array_length(script_blocks);
                    array_insert(script_blocks, _insert_idx, { 
                        type: "action", 
                        action_name: _aname, 
                        char_index: dragging_char_index, 
                        target_x: _px, 
                        target_y: _py,
                        facing: _is_left ? 1 : -1, // Face inwards on entry
                        height: 85 
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
if (!is_speaking && focused_block >= 0) {
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
        _b.text = string_insert(keyboard_string, _b.text, _b.caret_pos + 1);
        _b.caret_pos += string_length(keyboard_string);
        update_block_height(focused_block);
        keyboard_string = "";
    }
    
    if (_do_action) {
        // _wrap_w is already defined as box_w - 120 for consistency with Draw event
        if (_repeat_key == vk_left) _b.caret_pos = max(0, _b.caret_pos - 1);
        if (_repeat_key == vk_right) _b.caret_pos = min(string_length(_b.text), _b.caret_pos + 1);
        if (_repeat_key == vk_up || _repeat_key == vk_down) {
            var _cur_p = get_text_pos(_b.text, _b.caret_pos, _wrap_w, 28);
            var _target_y = _cur_p.y + (_repeat_key == vk_up ? -28 : 28);
            if (_target_y >= 0 && _target_y < string_height_ext(_b.text, 28, _wrap_w)) {
                var _best_p = _b.caret_pos; var _min_d = 999999;
                for (var c = 0; c <= string_length(_b.text); c++) {
                    var _pos = get_text_pos(_b.text, c, _wrap_w, 28);
                    var _d = point_distance(_cur_p.x, _target_y, _pos.x, _pos.y);
                    if (_d < _min_d) { _min_d = _d; _best_p = c; }
                }
                _b.caret_pos = _best_p;
            } else if (_repeat_key == vk_up) _b.caret_pos = 0;
            else _b.caret_pos = string_length(_b.text);
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

current_scene_sprite = -1; // Default to Blank (Black) if no scene found above
active_scene_block_idx = -1;
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
            break;
        }
    }
} else {
    if (current_scene_sprite != -1) {
        current_scene_sprite = -1;
        set_scene_dimensions(-1);
    }
}

// STAGING ENFORCEMENT: Only allow staging if focused on a scene heading
if (scene_edit_mode && focused_block != active_scene_block_idx) {
    scene_edit_mode = false;
}

// Compute preview_actors
if (playing_block_index == -1) {
    preview_actors = [];
    if (active_scene_block_idx != -1) {
        var _scene = script_blocks[active_scene_block_idx];
        if (variable_struct_exists(_scene, "actors")) {
            for(var a=0; a<array_length(_scene.actors); a++) {
                var _act = _scene.actors[a];
                var _face = variable_struct_exists(_act, "facing") ? _act.facing : 1;
                array_push(preview_actors, { char_index: _act.char_index, x: _act.x, y: _act.y, facing: _face });
            }
        }
        
        if (_ref_idx != -1) {
            for (var i = active_scene_block_idx + 1; i <= _ref_idx; i++) {
                var _b = script_blocks[i];
                var _is_action = (variable_struct_exists(_b, "type") && _b.type == "action");
                if (_is_action) {
                    var _aname = string_lower(_b.action_name);
                    var _is_enter = (string_pos("enter", _aname) > 0);
                    var _is_exit = (string_pos("exit", _aname) > 0);
                    var _is_left = (string_pos("left", _aname) > 0);
                    
                    if (_is_enter) {
                        var _spr = get_character_sprite(_b.char_index);
                        var _w = (_spr != -1) ? sprite_get_width(_spr) * ((scene_win_h * 0.75) / sprite_get_height(_spr)) : 100;
                        var _x = _is_left ? (_w/2) + 20 : scene_win_w - (_w/2) - 20;
                        var _found = false;
                        var _pa_idx = -1;
                        for(var pa=0; pa<array_length(preview_actors); pa++) {
                            if (preview_actors[pa].char_index == _b.char_index) { _found = true; _pa_idx = pa; break; }
                        }
                        if (!_found) {
                            var _final_x = variable_struct_exists(_b, "target_x") ? _b.target_x : _x;
                            var _final_y = variable_struct_exists(_b, "target_y") ? _b.target_y : scene_win_h;
                            var _face = _is_left ? -1 : 1;
                            array_push(preview_actors, { char_index: _b.char_index, x: _final_x, y: _final_y, facing: _face });
                        } else {
                            // If already onstage, update position and handle auto-facing
                            if (variable_struct_exists(_b, "target_x")) {
                                if (_b.target_x > preview_actors[_pa_idx].x) preview_actors[_pa_idx].facing = -1;
                                else if (_b.target_x < preview_actors[_pa_idx].x) preview_actors[_pa_idx].facing = 1;
                                preview_actors[_pa_idx].x = _b.target_x;
                                preview_actors[_pa_idx].y = _b.target_y;
                            }
                            // Explicit side mention overrides auto-facing
                            if (string_pos("left", _aname) > 0) preview_actors[_pa_idx].facing = -1;
                            else if (string_pos("right", _aname) > 0) preview_actors[_pa_idx].facing = 1;
                        }
                    } else if (_is_exit) {
                        for(var pa=0; pa<array_length(preview_actors); pa++) {
                            if (preview_actors[pa].char_index == _b.char_index) { array_delete(preview_actors, pa, 1); break; }
                        }
                    } else if (string_pos("turn", _aname) > 0) {
                        for(var pa=0; pa<array_length(preview_actors); pa++) {
                            if (preview_actors[pa].char_index == _b.char_index) { 
                                if (!variable_struct_exists(preview_actors[pa], "facing")) preview_actors[pa].facing = 1;
                                preview_actors[pa].facing *= -1; 
                                break; 
                            }
                        }
                    } else if (string_pos("moves", _aname) > 0) {
                        for(var pa=0; pa<array_length(preview_actors); pa++) {
                            if (preview_actors[pa].char_index == _b.char_index) { 
                                if (variable_struct_exists(_b, "target_x")) {
                                    // Auto-face movement direction
                                    if (_b.target_x > preview_actors[pa].x) preview_actors[pa].facing = -1;
                                    else if (_b.target_x < preview_actors[pa].x) preview_actors[pa].facing = 1;
                                    preview_actors[pa].x = _b.target_x;
                                    preview_actors[pa].y = _b.target_y;
                                }
                                break; 
                            }
                        }
                    }
                }
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
