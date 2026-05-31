/// @description TTS sequential playback engine: progress polling, viseme sync,
///              subtitle scroll, action animation, completion checks, sequence advance.

function step_tts_playback() {
    // --- TTS SCROLL & PROGRESS ---
    if (playing_block_index != -1 && playing_block_index < array_length(script_blocks)) {
        var _scroll_idx = playing_block_index;
        var _b = script_blocks[_scroll_idx];

        if (!variable_struct_exists(_b, "text") && playing_linked_index != -1) {
            for (var _i = playing_block_index; _i <= playing_linked_index; _i++) {
                if (_i < array_length(script_blocks) && variable_struct_exists(script_blocks[_i], "text")) {
                    _scroll_idx = _i; _b = script_blocks[_scroll_idx]; break;
                }
            }
        }

        var _target_y = 0;
        for (var i = 0; i < _scroll_idx; i++) _target_y += script_blocks[i].height + 20;

        var _is_scene = (variable_struct_exists(_b, "type") && _b.type == "scene");
        var _header_offset = _is_scene ? 0 : 30;
        var _char_progress_y = 0;

        if (is_speaking && variable_struct_exists(_b, "text") && string_length(_b.text) > 0) {
            if (check_timer mod 6 == 0) {
                var _req_to_check = variable_struct_exists(_b, "tts_req") ? _b.tts_req : -1;
                if (_req_to_check != -1) {
                    var _prog_file = working_directory + "talkit\\talkit_prog_" + string(_req_to_check) + ".tmp";
                    if (file_exists(_prog_file)) {
                        speaking_has_progress = true;
                        var _f = file_text_open_read(_prog_file);
                        if (_f != -1) {
                            var _perc = file_text_read_real(_f);
                            file_text_close(_f);
                            if (_perc > 0) {
                                speaking_index = max(speaking_index, _perc * string_length(_b.text));
                                // Snap time-based progress forward to the sentence boundary so the
                                // viseme lookup catches up immediately instead of lagging behind.
                                // Only advances speak_start_time_ms, never moves it backward.
                                if (current_viseme_total_ms > 0 && speak_start_time_ms >= 0) {
                                    var _spd2 = variable_struct_exists(_b, "speed") ? _b.speed : 50;
                                    var _adj2 = current_viseme_total_ms * (175.0 / max(1, 50 + _spd2 * 2.5));
                                    var _target_elapsed = _perc * _adj2;
                                    if (_target_elapsed > (current_time - speak_start_time_ms)) {
                                        speak_start_time_ms = current_time - _target_elapsed;
                                    }
                                }
                            }
                        }
                    }
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
                            var _dur_file = working_directory + "talkit\\talkit_dur_" + string(_req_to_check) + ".tmp";
                            if (file_exists(_dur_file)) {
                                var _dff = file_text_open_read(_dur_file);
                                if (_dff != -1) { current_viseme_total_ms = file_text_read_real(_dff); file_text_close(_dff); }
                                file_delete(_dur_file);
                            }
                        }
                    }
                }
            }

            var _base_cps = 20;
            var _ui_speed = variable_struct_exists(_b, "speed") ? _b.speed : 50;
            var _spd_factor = (50 + (_ui_speed * 2.5)) / 175;
            if (speaking_has_progress) {
                speaking_index += (_base_cps / 60) * _spd_factor * speaking_phonetic_ratio;
                speaking_index = min(speaking_index, string_length(_b.text));
            }

            var _sub = string_copy(_b.text, 1, floor(speaking_index));
            _char_progress_y = string_height_ext(_sub, 28, box_w - 120);
        }

        var _dest_scroll = -(_target_y + _header_offset + _char_progress_y) + (box_h / 2);
        block_scroll_y += (_dest_scroll - block_scroll_y) * 0.15;
        block_scroll_y = min(0, block_scroll_y);

        if (theater_mode && is_speaking && !theater_paused && variable_struct_exists(_b, "text")) {
            var _p = get_text_pos(_b.text, floor(speaking_index), 880, 32);
            var _target_sub_scroll = 0;
            if (_p.y >= 96) _target_sub_scroll = -(_p.y - 64);
            theater_subtitle_scroll_y += (_target_sub_scroll - theater_subtitle_scroll_y) * 0.1;
        }
    } else {
        theater_subtitle_scroll_y = 0;
    }

    // --- ACTION ANIMATOR ---
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
                if (!variable_struct_exists(_act, "y_offset"))     _act.y_offset = 0;
                if (!variable_struct_exists(_anim, "cur_speed"))   _anim.cur_speed = 0;
                var _target_speed = _anim.speed;
                var _decel_dist = _anim.speed * 12;
                if (_dist < _decel_dist) _target_speed = max(0.2, _anim.speed * (_dist / _decel_dist));
                _anim.cur_speed += (_target_speed - _anim.cur_speed) * 0.2;
                if (_dist > _anim.cur_speed) {
                    var _dir = point_direction(_act.x, _act.y, _anim.target_x, _anim.target_y);
                    var _dx = lengthdir_x(_anim.cur_speed, _dir); var _dy = lengthdir_y(_anim.cur_speed, _dir);
                    _act.x += _dx; _act.y += _dy;
                    var _h_speed = abs(_dx);
                    if (_h_speed > 0.2) {
                        _act.bounce_timer += _h_speed * 0.07;
                        _act.y_offset = -round(abs(sin(_act.bounce_timer)) * clamp(_h_speed * 0.8, 0, 4));
                    } else { _act.y_offset = 0; _act.bounce_timer = 0; }
                } else {
                    _act.x = _anim.target_x; _act.y = _anim.target_y; _act.y_offset = 0; _act.bounce_timer = 0;
                    speaking_pause_timer = max(speaking_pause_timer, 5);
                    if (_anim.type == "exit") array_delete(preview_actors, _act_idx, 1);
                    array_delete(active_animations, _ai, 1);
                }
            } else { array_delete(active_animations, _ai, 1); }
        }
        if (array_length(active_animations) == 0) action_animating = false;
    }

    // --- TTS DONE-FILE POLLING ---
    if (is_speaking && check_timer mod 6 == 0) {
        var _all_done = true;
        for (var _r = array_length(active_requests) - 1; _r >= 0; _r--) {
            var _req = active_requests[_r];
            var _done_file = working_directory + "talkit\\talkit_done_" + string(_req) + ".tmp";
            if (file_exists(_done_file)) {
                file_delete(_done_file);
                array_delete(active_requests, _r, 1);
                var _txt_file  = game_save_id + "talkit_text_" + string(_req) + ".tmp";
                var _prog_file = working_directory + "talkit\\talkit_prog_" + string(_req) + ".tmp";
                var _dur_file  = working_directory + "talkit\\talkit_dur_"  + string(_req) + ".tmp";
                if (file_exists(_txt_file))  file_delete(_txt_file);
                if (file_exists(_prog_file)) file_delete(_prog_file);
                if (file_exists(_dur_file))  file_delete(_dur_file);
            } else { _all_done = false; }
        }
        if (_all_done) {
            if (playing_block_index != -1 && playing_block_index < array_length(script_blocks) - 1) {
                is_speaking = false; speaking_pause_timer = max(speaking_pause_timer, 15);
            } else {
                is_speaking = false; last_played_block_index = playing_block_index;
                tts_stop();
                if (theater_mode) {
                    theater_subtitles = ""; theater_active_char = -1;
                    theater_paused = true; play_from_index(0); playing_block_index = -1;
                } else { playing_block_index = -1; }
            }
        }
    }

    // --- WARMUP CLEANUP ---
    if (variable_instance_exists(id, "warmup_requests") && check_timer mod 6 == 0) {
        for (var _r = array_length(warmup_requests) - 1; _r >= 0; _r--) {
            var _req = warmup_requests[_r];
            var _done_file = working_directory + "talkit\\talkit_done_" + string(_req) + ".tmp";
            if (file_exists(_done_file)) {
                file_delete(_done_file);
                array_delete(warmup_requests, _r, 1);
                var _txt_file  = game_save_id + "talkit_text_" + string(_req) + ".tmp";
                var _prog_file = working_directory + "talkit\\talkit_prog_" + string(_req) + ".tmp";
                var _dur_file  = working_directory + "talkit\\talkit_dur_"  + string(_req) + ".tmp";
                if (file_exists(_txt_file))  file_delete(_txt_file);
                if (file_exists(_prog_file)) file_delete(_prog_file);
                if (file_exists(_dur_file))  file_delete(_dur_file);
            }
        }
    }

    // --- PAUSE TIMER ---
    if (playing_block_index != -1 && !theater_paused && speaking_pause_timer > 0) speaking_pause_timer--;

    // --- AUTO-STOP (last block is scene/action) ---
    if (!is_speaking && !action_animating && playing_block_index != -1 && playing_block_index < array_length(script_blocks)) {
        if (speaking_pause_timer <= 0 && speaking_pause_timer != -1) {
            var _lb_idx = (playing_linked_index != -1) ? playing_linked_index : playing_block_index;
            var _lb = script_blocks[_lb_idx];
            var _lb_is_scene  = (variable_struct_exists(_lb, "type") && _lb.type == "scene");
            var _lb_is_action = (variable_struct_exists(_lb, "type") && _lb.type == "action");
            if ((_lb_is_scene || _lb_is_action) && _lb_idx >= array_length(script_blocks) - 1) {
                if (theater_mode) {
                    theater_subtitles = ""; theater_active_char = -1;
                    theater_paused = true; play_from_index(0); playing_block_index = -1;
                } else { playing_block_index = -1; }
            }
        }
    }

    // --- SEQUENCE ADVANCE ---
    if (!is_speaking && !action_animating && playing_block_index != -1 && !theater_paused) {
        if (speaking_pause_timer <= 0 || speaking_pause_timer == -1) {
            if (speaking_pause_timer <= 0 && speaking_pause_timer != -1) {
                var _next_idx = (playing_linked_index != -1) ? playing_linked_index + 1 : playing_block_index + 1;
                if (_next_idx < array_length(script_blocks)) {
                    playing_block_index = _next_idx; playing_linked_index = -1; speaking_pause_timer = 0;
                } else {
                    if (theater_mode) {
                        theater_subtitles = ""; theater_active_char = -1;
                        theater_paused = true; play_from_index(0); playing_block_index = -1; playing_linked_index = -1;
                    } else { playing_block_index = -1; playing_linked_index = -1; theater_paused = false; }
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
                var _is_scene  = (variable_struct_exists(_b, "type") && _b.type == "scene");
                var _is_action = (variable_struct_exists(_b, "type") && _b.type == "action");

                if (_is_scene) {
                    current_scene_sprite = get_scene_sprite(_b.internal_name);
                    set_scene_dimensions(current_scene_sprite);
                    active_scene_block_idx = playing_block_index;
                    preview_actors = [];
                    if (variable_struct_exists(_b, "actors")) {
                        for (var a = 0; a < array_length(_b.actors); a++) {
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
                    var _aname    = string_lower(_b.action_name);
                    var _is_enter = (string_pos("enter", _aname) > 0);
                    var _is_exit  = (string_pos("exit",  _aname) > 0);
                    var _is_left  = (string_pos("left",  _aname) > 0);
                    var _spd  = variable_struct_exists(_b, "speed") ? _b.speed : 1.9;
                    var _moon = (variable_struct_exists(_b, "moonwalk") && _b.moonwalk) || (string_pos("[moonwalk]", _aname) > 0);
                    var _act_idx = -1;
                    for (var a = 0; a < array_length(preview_actors); a++) {
                        if (preview_actors[a].char_index == _b.char_index) { _act_idx = a; break; }
                    }
                    var _spr = get_character_sprite(_b.char_index);
                    var _w = (_spr != -1) ? sprite_get_width(_spr) * ((scene_win_h * 1.5) / 450) : 100;

                    if (_is_enter) {
                        if (_act_idx != -1) { speaking_pause_timer = max(speaking_pause_timer, 5); }
                        else {
                            var _start_x  = _is_left ? -(_w/2) : scene_win_w + (_w/2);
                            var _base_face = _is_left ? -1 : 1;
                            char_facings[_b.char_index] = _moon ? -_base_face : _base_face;
                            var _target_y = variable_struct_exists(_b, "target_y") ? _b.target_y : (scene_win_h * 0.8);
                            var _c = characters[_b.char_index];
                            var _pose = variable_struct_exists(_b, "enter_pose")       ? _b.enter_pose       : (variable_struct_exists(_c, "pose")       ? _c.pose       : 1);
                            var _expr = variable_struct_exists(_b, "enter_expression") ? _b.enter_expression : (variable_struct_exists(_c, "expression") ? _c.expression : 21);
                            array_push(preview_actors, { char_index: _b.char_index, x: _start_x, y: _target_y, is_base: false, facing: char_facings[_b.char_index], pose: _pose, expression: _expr });
                            action_animating = true;
                            array_push(active_animations, {
                                char_index: _b.char_index, type: "enter", speed: _spd,
                                target_x: variable_struct_exists(_b, "target_x") ? _b.target_x : (_is_left ? (_w/2)+20 : scene_win_w-(_w/2)-20),
                                target_y: variable_struct_exists(_b, "target_y") ? _b.target_y : scene_win_h
                            });
                        }
                    } else if (_is_exit) {
                        if (_act_idx == -1) { speaking_pause_timer = max(speaking_pause_timer, 5); }
                        else {
                            action_animating = true;
                            var _current_x = preview_actors[_act_idx].x;
                            var _exit_left  = (string_pos("left",  _aname) > 0);
                            var _exit_right = (string_pos("right", _aname) > 0);
                            if (!_exit_left && !_exit_right) _exit_left = (_current_x < scene_win_w / 2);
                            var _base_face = _exit_left ? 1 : -1;
                            char_facings[_b.char_index] = _moon ? -_base_face : _base_face;
                            preview_actors[_act_idx].facing = char_facings[_b.char_index];
                            array_push(active_animations, {
                                char_index: _b.char_index, type: "exit", speed: _spd,
                                target_x: _exit_left ? -(_w/2)-50 : scene_win_w+(_w/2)+50,
                                target_y: preview_actors[_act_idx].y
                            });
                        }
                    } else if (string_pos("turn", _aname) > 0) {
                        if (_act_idx != -1) { preview_actors[_act_idx].facing *= -1; char_facings[_b.char_index] = preview_actors[_act_idx].facing; }
                        speaking_pause_timer = max(speaking_pause_timer, 5);
                    } else if (string_pos("wait", _aname) > 0) {
                        var _dur = variable_struct_exists(_b, "duration") ? _b.duration : 1.0;
                        speaking_pause_timer = max(speaking_pause_timer, max(1, _dur * 60));
                    } else if (string_pos("display title", _aname) > 0) {
                        var _is_linked_to_src = false;
                        for (var _check = 0; _check < array_length(_blocks_to_start); _check++) {
                            var _ctype = get_link_type(_blocks_to_start[_check]);
                            if (_ctype == "sfx" || _ctype == "voice") { _is_linked_to_src = true; break; }
                        }
                        if (!_is_linked_to_src) {
                            var _dur = variable_struct_exists(_b, "duration") ? _b.duration : 2.0;
                            speaking_pause_timer = max(speaking_pause_timer, max(1, _dur * 60));
                        }
                    } else if (string_pos("play sfx", _aname) > 0) {
                        if (variable_struct_exists(_b, "sfx_path")) {
                            var _tmp_buf = load_sfx_buffer_by_path(_b.sfx_path);
                            if (_tmp_buf != -1) {
                                if (variable_struct_exists(_b, "last_sound") && _b.last_sound != -1) { audio_free_buffer_sound(_b.last_sound); _b.last_sound = -1; }
                                if (variable_struct_exists(_b, "last_buffer") && _b.last_buffer != -1) { buffer_delete(_b.last_buffer); _b.last_buffer = -1; }
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
                    } else if (string_pos("moves", _aname) > 0) {
                        if (_act_idx != -1) {
                            action_animating = true;
                            var _base_face = (_b.target_x > preview_actors[_act_idx].x) ? -1 : 1;
                            char_facings[_b.char_index] = _moon ? -_base_face : _base_face;
                            preview_actors[_act_idx].facing = char_facings[_b.char_index];
                            array_push(active_animations, { char_index: _b.char_index, type: "move", speed: _spd, target_x: _b.target_x, target_y: _b.target_y });
                        } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                    } else if (string_pos("expression:", _aname) > 0) {
                        if (_act_idx != -1) {
                            var _colon_p = string_pos(":", _aname);
                            var _mood_str = string_upper(string_trim(string_copy(_aname, _colon_p + 1, 999)));
                            for (var m = 0; m < array_length(mood_names); m++) {
                                if (mood_names[m] == _mood_str) { preview_actors[_act_idx].expression = m + 1; break; }
                            }
                            speaking_pause_timer = max(speaking_pause_timer, 6);
                        } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                    } else if (string_pos("poses", _aname) > 0) {
                        if (_act_idx != -1) {
                            var _p_pos = string_pos("poses ", _aname);
                            if (_p_pos > 0) {
                                var _p_num = real(string_copy(_aname, _p_pos + 6, 1));
                                if (_p_num >= 1 && _p_num <= 4) preview_actors[_act_idx].pose = _p_num;
                            }
                            var _m_start = string_pos("(", _aname); var _m_end = string_pos(")", _aname);
                            if (_m_start > 0 && _m_end > _m_start) {
                                var _mood_str = string_upper(string_copy(_aname, _m_start + 1, _m_end - _m_start - 1));
                                for (var m = 0; m < array_length(mood_names); m++) {
                                    if (mood_names[m] == _mood_str) { preview_actors[_act_idx].expression = m + 1; break; }
                                }
                            }
                            speaking_pause_timer = max(speaking_pause_timer, 6);
                        } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                    } else if (string_pos("looks ", _aname) > 0) {
                        if (_act_idx != -1) {
                            var _lp = string_pos("looks ", _aname) + 6;
                            var _ap = string_pos(" and pose ", _aname);
                            var _mood_str = string_upper(string_trim(string_copy(_aname, _lp, (_ap > 0) ? _ap - _lp : 999)));
                            for (var m = 0; m < array_length(mood_names); m++) {
                                if (mood_names[m] == _mood_str) { preview_actors[_act_idx].expression = m + 1; break; }
                            }
                            if (_ap > 0) {
                                var _pn = real(string_copy(_aname, _ap + 10, 1));
                                if (_pn >= 1 && _pn <= 4) preview_actors[_act_idx].pose = _pn;
                            }
                            speaking_pause_timer = max(speaking_pause_timer, 6);
                        } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                    } else if (string_pos("pose ", _aname) > 0) {
                        if (_act_idx != -1) {
                            var _pn = real(string_copy(_aname, string_pos("pose ", _aname) + 5, 1));
                            if (_pn >= 1 && _pn <= 4) preview_actors[_act_idx].pose = _pn;
                            speaking_pause_timer = max(speaking_pause_timer, 6);
                        } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                    } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                } else {
                    var _is_empty = true;
                    for (var _e_idx = 1; _e_idx <= string_length(_b.text); _e_idx++) {
                        if (string_char_at(_b.text, _e_idx) != " " && string_char_at(_b.text, _e_idx) != "\n" && string_char_at(_b.text, _e_idx) != "\r") { _is_empty = false; break; }
                    }
                    var _phonetic_text = apply_dictionary(_b.text);
                    if (_is_empty) {
                        _b.tts_req = -1;
                    } else {
                        var _req = tts_speak(_phonetic_text, _b.voice_id, _b.pitch, _b.speed, _b.mode, _b.style);
                        _b.tts_req = _req;
                        array_push(active_requests, _req);
                        if (!is_speaking) {
                            is_speaking             = true;
                            speaking_has_progress   = false;
                            current_viseme_data     = [];
                            speaking_index          = 0;
                            current_viseme_total_ms = -1;
                            speak_start_time_ms     = current_time;
                            mouth_last_vis_time_ms  = -1;
                            mouth_last_vis_value    = 0;
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
}
