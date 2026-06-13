/// @description TTS sequential playback engine: progress polling, viseme sync,
///              subtitle scroll, action animation, completion checks, sequence advance.

function step_tts_playback() {
    // --- SCENE TRANSITION UPDATE ---
    if (scene_transition_active && playing_block_index != -1 && !theater_paused) {
        scene_transition_frames++;
        scene_transition_progress = min(1.0, scene_transition_frames / max(1, scene_transition_duration));
        if (scene_transition_progress >= 1.0) {
            scene_transition_active = false;
            if (scene_transition_dir == "in") scene_transition_progress = 0.0;
            // "out": keep progress=1.0 (full black) until new scene loads and clears it
        }
    }

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
    if (action_animating && !theater_paused) {
        for (var _ai = array_length(active_animations) - 1; _ai >= 0; _ai--) {
            var _anim = active_animations[_ai];
            var _act_idx = -1;
            for (var a = 0; a < array_length(preview_actors); a++) {
                if (preview_actors[a].char_index == _anim.char_index) { _act_idx = a; break; }
            }
            if (_act_idx != -1) {
                var _act = preview_actors[_act_idx];

                if (_anim.type == "jitter") {
                    _anim.frames_remaining--;
                    var _ji = _anim.intensity; var _jd = _anim.direction;
                    var _should_stop = (_anim.frames_remaining <= 0);
                    if (variable_struct_exists(_anim, "chain_start_index") && _anim.chain_start_index != -1) {
                        _should_stop = (playing_block_index != _anim.chain_start_index || !is_driving_event_active());
                    } else if (variable_struct_exists(_anim, "tied_to_move") && _anim.tied_to_move) {
                        var _move_still_on = false;
                        for (var _mi2 = 0; _mi2 < array_length(active_animations); _mi2++) {
                            if (_mi2 == _ai) continue;
                            var _ma = active_animations[_mi2];
                            if (real(_ma.char_index) == real(_anim.char_index) && (_ma.type == "move" || _ma.type == "enter" || _ma.type == "exit")) { _move_still_on = true; break; }
                        }
                        _should_stop = !_move_still_on;
                    }
                    if (!_should_stop) {
                        _act.jitter_x = (_jd != "vertical")   ? random_range(-_ji, _ji) : 0;
                        _act.jitter_y = (_jd != "horizontal") ? random_range(-_ji, _ji) : 0;
                    } else {
                        _act.jitter_x = 0; _act.jitter_y = 0;
                        array_delete(active_animations, _ai, 1);
                    }
                } else if (_anim.type == "melt") {
                    _anim.progress = min(1.0, _anim.progress + 1.0 / max(1, _anim.duration));
                    _act.melt_progress = _anim.progress;
                    // Emit occasional green drip particles
                    if (irandom(3) == 0) {
                        var _msc = (scene_win_h * 1.5) / 450;
                        var _mspr = get_character_sprite(_act.char_index);
                        var _mhw = (_mspr != -1) ? sprite_get_width(_mspr) * _msc * 0.4 : 40;
                        array_push(active_particles, {
                            x: scene_win_x + _act.x + random_range(-_mhw, _mhw),
                            y: scene_win_y + _act.y,
                            vx: random_range(-0.3, 0.3),
                            vy: random_range(0.5, 2.0),
                            life: irandom_range(12, 22), max_life: 20,
                            size: random_range(2, 5),
                            r: irandom_range(20, 80), g: irandom_range(140, 200), b: irandom_range(20, 60),
                            gravity: 0.08,
                        });
                    }
                    if (_anim.progress >= 1.0) {
                        var _is_inj = (variable_struct_exists(preview_actors[_act_idx], "is_knocked_down") && preview_actors[_act_idx].is_knocked_down)
                                   || (variable_struct_exists(preview_actors[_act_idx], "is_decapitated") && preview_actors[_act_idx].is_decapitated);
                        if (_is_inj) {
                            preview_actors[_act_idx].hidden = true;
                        } else {
                            array_delete(preview_actors, _act_idx, 1);
                        }
                        array_delete(active_animations, _ai, 1);
                    }
                } else if (_anim.type == "injure_fall") {
                    _anim.progress = min(1.0, _anim.progress + 1.0 / max(1, _anim.duration));
                    _act.knock_angle = _anim.direction * 90.0 * _anim.progress * _anim.progress;
                    if (_anim.progress >= 1.0) {
                        _act.knock_angle = _anim.direction * 90.0;
                        array_delete(active_animations, _ai, 1);
                    }
                } else if (_anim.type == "stand_up") {
                    _anim.progress = min(1.0, _anim.progress + 1.0 / max(1, _anim.duration));
                    var _t = 1.0 - _anim.progress;
                    _act.knock_angle = _anim.start_angle * (_t * _t);
                    if (_anim.progress >= 1.0) {
                        _act.knock_angle      = 0;
                        _act.is_knocked_down  = false;
                        _act.knock_direction  = "forwards";
                        var _still_inj = variable_struct_exists(_act, "is_decapitated") && _act.is_decapitated;
                        _act.injured = _still_inj;
                        array_delete(active_animations, _ai, 1);
                        // Snap y to valid vertical range now that character is upright
                        var _su_spr = get_character_sprite(_act.char_index);
                        if (_su_spr != -1) {
                            var _su_sc = (scene_win_h * 1.5) / 450;
                            var _su_sh = sprite_get_height(_su_spr) * _su_sc;
                            _act.y = clamp(_act.y, _su_sh * 0.20, scene_win_h + _su_sh * 0.80);
                        }
                    }
                } else if (_anim.type == "disintegrate") {
                    // Time-based: advance progress, emit electric particles, then remove
                    _anim.progress = min(1.0, _anim.progress + 1.0 / max(1, _anim.duration));
                    _act.dissolve_progress = _anim.progress;

                    var _ds = (scene_win_h * 1.5) / 450;
                    var _dspr3 = get_character_sprite(_act.char_index);
                    var _dhw = (_dspr3 != -1) ? sprite_get_width(_dspr3)  * _ds * 0.36 : 50;
                    var _dht = (_dspr3 != -1) ? sprite_get_height(_dspr3) * _ds * 0.80 : 180;
                    repeat (max(1, round(_anim.progress * _anim.progress * 12))) {
                        var _dpx  = _act.x + random_range(-_dhw, _dhw);
                        var _dpy  = _act.y - random_range(0, _dht);
                        var _dspd = random_range(0.4, 2.8) * (0.6 + _anim.progress * 3.0);
                        var _dang = random_range(0, 2 * pi);
                        var _dlf  = irandom_range(10, 26);
                        var _dclr = irandom(2);
                        array_push(active_particles, {
                            x:        scene_win_x + _dpx,
                            y:        scene_win_y + _dpy,
                            vx:       cos(_dang) * _dspd,
                            vy:       sin(_dang) * _dspd - random_range(0, 1.2),
                            life:     _dlf, max_life: _dlf,
                            size:     random_range(0.8, 3.0),
                            r:        (_dclr == 0) ? irandom_range(160, 255) : irandom_range(20, 80),
                            g:        irandom_range(200, 255),
                            b:        255,
                            gravity:  -0.04,
                        });
                    }
                    if (_anim.progress >= 1.0) {
                        var _is_inj = (variable_struct_exists(preview_actors[_act_idx], "is_knocked_down") && preview_actors[_act_idx].is_knocked_down)
                                   || (variable_struct_exists(preview_actors[_act_idx], "is_decapitated") && preview_actors[_act_idx].is_decapitated);
                        if (_is_inj) {
                            preview_actors[_act_idx].hidden = true;
                        } else {
                            array_delete(preview_actors, _act_idx, 1);
                        }
                        array_delete(active_animations, _ai, 1);
                    }
                } else if (_anim.type == "canned") {
                    cleanup_sfx_instances();
                    var _frames = _anim.anim_data.frames;
                    var _total  = array_length(_frames);
                    while (_anim.frame_idx < _total && _frames[_anim.frame_idx].type == "sound") {
                        canned_anim_fire_sound(_anim.char_index, _frames[_anim.frame_idx]);
                        _anim.frame_idx++;
                        _anim.tick = 0;
                    }
                    if (_anim.frame_idx >= _total) {
                        _act.canned_spr      = -1;
                        _act.canned_feet_spr = -1;
                        array_delete(active_animations, _ai, 1);
                    } else {
                        var _cur_frame = _frames[_anim.frame_idx];
                        var _hold = (_cur_frame.type == "sprite" && variable_struct_exists(_cur_frame, "hold")) ? _cur_frame.hold : 1;
                        var _facing_ca = variable_struct_exists(_act, "facing") ? _act.facing : 1;
                        var _def_ca = variable_struct_exists(characters[_anim.char_index], "default_facing") ? characters[_anim.char_index].default_facing : 1;
                        var _spr_ca = (_facing_ca != _def_ca && variable_struct_exists(_cur_frame, "sprite_flipped") && _cur_frame.sprite_flipped != "")
                                      ? _cur_frame.sprite_flipped
                                      : canned_anim_facing_sprite(_cur_frame.sprite, _anim.char_index, _facing_ca);
                        _act.canned_spr = canned_anim_load_sprite(_anim.char_index, _spr_ca);
                        // If flipped variant is missing, fall back to original so we don't drop through to composite-legs rendering
                        if (_act.canned_spr == -1 && _spr_ca != _cur_frame.sprite) {
                            _act.canned_spr = canned_anim_load_sprite(_anim.char_index, _cur_frame.sprite);
                        }
                        _act.canned_anchor_y = variable_struct_exists(_cur_frame, "anchor_y") ? _cur_frame.anchor_y : 0;
                        // Feet sprite is set per-animation, not per-frame
                        var _anim_feet_ca = "";
                        if (_facing_ca != _def_ca) {
                            var _ffca = variable_struct_exists(_anim.anim_data, "feet_sprite_flipped") ? _anim.anim_data.feet_sprite_flipped : "";
                            if (_ffca != "") { _anim_feet_ca = _ffca; }
                            else { var _nf = variable_struct_exists(_anim.anim_data, "feet_sprite") ? _anim.anim_data.feet_sprite : ""; if (_nf != "") _anim_feet_ca = canned_anim_flipped_name(_nf); }
                        } else {
                            _anim_feet_ca = variable_struct_exists(_anim.anim_data, "feet_sprite") ? _anim.anim_data.feet_sprite : "";
                        }
                        _act.canned_composite = (_anim_feet_ca != "");
                        _act.canned_feet_spr  = (_anim_feet_ca != "") ? canned_anim_load_sprite(_anim.char_index, _anim_feet_ca) : -1;
                        var _is_flipped_ca = (_facing_ca != _def_ca);
                        _act.canned_composite_legs = true;
                        if (_is_flipped_ca && variable_struct_exists(_cur_frame, "composite_legs_flipped")) {
                            _act.canned_composite_legs = _cur_frame.composite_legs_flipped;
                        } else if (variable_struct_exists(_cur_frame, "composite_legs") && !_cur_frame.composite_legs) {
                            _act.canned_composite_legs = false;
                        }
                        var _fdy_ca = (_is_flipped_ca && variable_struct_exists(_cur_frame, "frame_dy_flipped")) ? _cur_frame.frame_dy_flipped
                                    : (variable_struct_exists(_cur_frame, "frame_dy") ? _cur_frame.frame_dy : 0);
                        var _fdx_ca = (_is_flipped_ca && variable_struct_exists(_cur_frame, "frame_dx_flipped")) ? _cur_frame.frame_dx_flipped
                                    : (variable_struct_exists(_cur_frame, "frame_dx") ? _cur_frame.frame_dx : 0);
                        var _bdy_key_ca = _is_flipped_ca ? "body_dy_flipped" : "body_dy";
                        _act.canned_body_dy   = (variable_struct_exists(_anim.anim_data, _bdy_key_ca) ? _anim.anim_data[$ _bdy_key_ca] : 0) + _fdy_ca;
                        // Horizontal alignment via offsets.json (same coordinate system as get_composite_character_sprite)
                        var _c_ca  = characters[_anim.char_index];
                        var _nm_ca = variable_struct_exists(_c_ca, "sprite_name") ? _c_ca.sprite_name : _c_ca.name;
                        if (!ds_map_exists(char_offsets_cache, _nm_ca)) {
                            ds_map_add(char_offsets_cache, _nm_ca, load_config_json(_nm_ca, "offsets.json"));
                        }
                        var _od_ca = char_offsets_cache[? _nm_ca];
                        var _body_ok_ca = string_replace(_spr_ca, ".png", "");
                        if (!_is_flipped_ca && _od_ca != undefined && !variable_struct_exists(_od_ca, _body_ok_ca))
                            _body_ok_ca = string_replace(_cur_frame.sprite, ".png", "");
                        var _feet_ok_ca = string_replace(_anim_feet_ca, ".png", "");
                        var _has_bx_ca = (_od_ca != undefined && variable_struct_exists(_od_ca, _body_ok_ca));
                        var _has_fx_ca = (_od_ca != undefined && _anim_feet_ca != "" && variable_struct_exists(_od_ca, _feet_ok_ca));
                        var _bdx_key_ca = _is_flipped_ca ? "body_dx_flipped" : "body_dx";
                        _act.canned_body_dx = ((_has_bx_ca && _has_fx_ca) ? (_od_ca[$ _body_ok_ca][0] - _od_ca[$ _feet_ok_ca][0]) : 0) + _fdx_ca + (variable_struct_exists(_anim.anim_data, _bdx_key_ca) ? _anim.anim_data[$ _bdx_key_ca] : 0);
                        _anim.tick++;
                        if (_anim.tick >= _hold) {
                            _anim.tick = 0;
                            _anim.frame_idx++;
                            while (_anim.frame_idx < _total && _frames[_anim.frame_idx].type == "sound") {
                                canned_anim_fire_sound(_anim.char_index, _frames[_anim.frame_idx]);
                                _anim.frame_idx++;
                            }
                        }
                    }
                } else {

                var _dist = point_distance(_act.x, _act.y, _anim.target_x, _anim.target_y);
                if (!variable_struct_exists(_act, "bounce_timer")) _act.bounce_timer = 0;
                if (!variable_struct_exists(_act, "y_offset"))     _act.y_offset = 0;
                if (!variable_struct_exists(_anim, "cur_speed"))   _anim.cur_speed = 0;
                var _trick = variable_struct_exists(_anim, "trick") ? _anim.trick : "none";
                var _trick_count = variable_struct_exists(_anim, "trick_count") ? max(1, _anim.trick_count) : 1;
                // Initialize trick_start_dist on first frame
                if (_trick != "none" && _anim.trick_start_dist < 0) _anim.trick_start_dist = max(1, _dist);
                var _is_tweening  = variable_struct_exists(_anim, "start_scale") && (_anim.start_scale != _anim.target_scale);
                var _spd_scl      = _is_tweening ? 1.0 : (_act[$ "scale"] ?? 1.0);
                var _base_spd     = _anim.speed * _spd_scl;
                var _target_speed = _base_spd;
                var _decel_dist   = _base_spd * 12;
                if (_dist < _decel_dist) _target_speed = max(0.1, _base_spd * (_dist / _decel_dist));
                _anim.cur_speed += (_target_speed - _anim.cur_speed) * 0.2;
                if (_dist > _anim.cur_speed) {
                    var _dir = point_direction(_act.x, _act.y, _anim.target_x, _anim.target_y);
                    var _dx = lengthdir_x(_anim.cur_speed, _dir); var _dy = lengthdir_y(_anim.cur_speed, _dir);
                    _act.x += _dx; _act.y += _dy;
                    if (variable_struct_exists(_anim, "start_scale") && _anim.start_scale != _anim.target_scale) {
                        var _td = point_distance(_anim.start_x, _anim.start_y, _anim.target_x, _anim.target_y);
                        var _rd = point_distance(_act.x, _act.y, _anim.target_x, _anim.target_y);
                        _act.scale = lerp(_anim.start_scale, _anim.target_scale, clamp(1.0 - _rd / max(1, _td), 0, 1));
                    }
                    var _act_is_kd_anim = variable_struct_exists(_act, "is_knocked_down") && _act.is_knocked_down;
                    if (_act_is_kd_anim) {
                        // Knocked down: no bounce, no image_angle — knock_angle handles all rotation
                        _act.y_offset = 0; _act.bounce_timer = 0; _act.image_angle = 0;
                    } else if (_trick != "none") {
                        var _prog = clamp(1.0 - (_dist / _anim.trick_start_dist), 0, 1);
                        _act.bounce_timer = 0;
                        if (_trick != "jump") {
                            // Flips: single arc so character stays airborne through all rotations
                            _act.y_offset = -sin(_prog * pi) * (scene_win_h * 0.18);
                            var _moving_right = (_anim.target_x > _act.x);
                            var _flip_dir = (_trick == "front flip") ? (_moving_right ? -1 : 1) : (_moving_right ? 1 : -1);
                            if (variable_struct_exists(_anim, "moonwalk") && _anim.moonwalk) _flip_dir *= -1;
                            _act.image_angle = _prog * 360 * _trick_count * _flip_dir;
                        } else {
                            // Jumps: multiple hops, each touching down
                            _act.y_offset = -abs(sin(_prog * _trick_count * pi)) * (scene_win_h * 0.18);
                            _act.image_angle = 0;
                        }
                    } else {
                        _act.image_angle = 0;
                        var _spd = _anim.cur_speed;
                        if (_spd > 0.2) {
                            var _is_scaling = variable_struct_exists(_anim, "start_scale") && (_anim.start_scale != _anim.target_scale);
                            var _act_scl = _act[$ "scale"] ?? 1.0;
                            _act.bounce_timer += _spd * (_is_scaling ? 0.035 : 0.07);
                            _act.y_offset = -round(abs(sin(_act.bounce_timer)) * clamp(_spd * 0.8, 0, 4) * _act_scl);
                        } else { _act.y_offset = 0; _act.bounce_timer = 0; }
                    }
                } else {
                    _act.x = _anim.target_x; _act.y = _anim.target_y;
                    if (variable_struct_exists(_anim, "target_scale")) _act.scale = _anim.target_scale;
                    _act.y_offset = 0; _act.bounce_timer = 0; _act.image_angle = 0;
                    speaking_pause_timer = max(speaking_pause_timer, 5);
                    if (_anim.type == "exit") {
                        var _is_inj = (variable_struct_exists(preview_actors[_act_idx], "is_knocked_down") && preview_actors[_act_idx].is_knocked_down)
                                   || (variable_struct_exists(preview_actors[_act_idx], "is_decapitated") && preview_actors[_act_idx].is_decapitated);
                        if (_is_inj) {
                            preview_actors[_act_idx].hidden = true;
                        } else {
                            array_delete(preview_actors, _act_idx, 1);
                        }
                    }
                    array_delete(active_animations, _ai, 1);
                }
                } // end else (non-disintegrate)

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
                tts_cleanup_req(_req);
                array_delete(active_requests, _r, 1);
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
                    focused_block = array_length(script_blocks) - 1;
                } else { stop_playback(); }
            }
        }
    }

    // --- WARMUP CLEANUP ---
    if (variable_instance_exists(id, "warmup_requests") && check_timer mod 6 == 0) {
        for (var _r = array_length(warmup_requests) - 1; _r >= 0; _r--) {
            var _req = warmup_requests[_r];
            var _done_file = working_directory + "talkit\\talkit_done_" + string(_req) + ".tmp";
            if (file_exists(_done_file)) {
                tts_cleanup_req(_req);
                array_delete(warmup_requests, _r, 1);
            }
        }
    }

    // --- PAUSE TIMER ---
    if (playing_block_index != -1 && !theater_paused && speaking_pause_timer > 0) speaking_pause_timer--;

    // --- AUTO-STOP (last block is scene/action) ---
    if (!is_speaking && !action_animating && playing_block_index != -1 && playing_block_index < array_length(script_blocks)) {
        if (speaking_pause_timer <= 0 && speaking_pause_timer != -1 && !scene_transition_active) {
            var _lb_idx = (playing_linked_index != -1) ? playing_linked_index : playing_block_index;
            var _lb = script_blocks[_lb_idx];
            var _lb_is_scene    = (variable_struct_exists(_lb, "type") && _lb.type == "scene");
            var _lb_is_action   = (variable_struct_exists(_lb, "type") && _lb.type == "action");
            var _lb_is_particle = (variable_struct_exists(_lb, "type") && _lb.type == "particle");
            if ((_lb_is_scene || _lb_is_action || _lb_is_particle) && _lb_idx >= array_length(script_blocks) - 1) {
                var _lb_tout = _lb_is_scene && variable_struct_exists(_lb, "transition_out") ? _lb.transition_out : "none";
                if (_lb_tout == "none") {
                    if (theater_mode) {
                        theater_subtitles = ""; theater_active_char = -1;
                        theater_paused = true; play_from_index(0); playing_block_index = -1;
                        focused_block = array_length(script_blocks) - 1;
                    } else { stop_playback(); }
                }
            }
        }
    }

    // --- SEQUENCE ADVANCE ---
    if (!is_speaking && !action_animating && playing_block_index != -1 && !theater_paused) {
        if (speaking_pause_timer <= 0 || speaking_pause_timer == -1) {

            // Out-transition: intercept before advancing to a new scene block (or at end of script)
            if (speaking_pause_timer <= 0 && speaking_pause_timer != -1 && !scene_out_transitioning && active_scene_block_idx != -1 && !(scene_transition_active && scene_transition_dir == "in")) {
                var _look_next = (playing_linked_index != -1) ? playing_linked_index + 1 : playing_block_index + 1;
                var _outb = script_blocks[active_scene_block_idx];
                var _tout = variable_struct_exists(_outb, "transition_out") ? _outb.transition_out : "none";
                if (_tout != "none") {
                    var _fire_out = (_look_next >= array_length(script_blocks));
                    if (!_fire_out) {
                        var _look_b = script_blocks[_look_next];
                        if (variable_struct_exists(_look_b, "type") && _look_b.type == "scene") _fire_out = true;
                    }
                    if (_fire_out) {
                        var _tdur_out = variable_struct_exists(_outb, "transition_out_speed") ? _outb.transition_out_speed : 60;
                        scene_transition_active   = true;
                        scene_transition_type     = _tout;
                        scene_transition_dir      = "out";
                        scene_transition_frames   = 0;
                        scene_transition_progress = 0.0;
                        scene_transition_duration = _tdur_out;
                        scene_out_transitioning   = true;
                        speaking_pause_timer      = _tdur_out + 2;
                        return;
                    }
                }
            }
            scene_out_transitioning = false;

            if (speaking_pause_timer <= 0 && speaking_pause_timer != -1) {
                var _next_idx = (playing_linked_index != -1) ? playing_linked_index + 1 : playing_block_index + 1;
                if (_next_idx < array_length(script_blocks)) {
                    playing_block_index = _next_idx; playing_linked_index = -1; speaking_pause_timer = 0;
                } else {
                    if (theater_mode) {
                        theater_subtitles = ""; theater_active_char = -1;
                        theater_paused = true; play_from_index(0); playing_block_index = -1; playing_linked_index = -1;
                        focused_block = array_length(script_blocks) - 1;
                    } else { stop_playback(); theater_paused = false; }
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
                var _is_scene    = (variable_struct_exists(_b, "type") && _b.type == "scene");
                var _is_action   = (variable_struct_exists(_b, "type") && _b.type == "action");
                var _is_particle = (variable_struct_exists(_b, "type") && _b.type == "particle");

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
                            var _pa = { char_index: _act.char_index, x: _act.x, y: _act.y, is_base: true, facing: _face, pose: _pose, expression: _expr, scale: _act[$ "scale"] ?? 1.0 };
                            if (variable_struct_exists(_act, "is_knocked_down") && _act.is_knocked_down) {
                                _pa.is_knocked_down = true;
                                var _kd_dir = variable_struct_exists(_act, "knock_direction") ? _act.knock_direction : "forwards";
                                _pa.knock_direction = _kd_dir;
                                var _kd_ang = variable_struct_exists(_act, "knock_angle") ? _act.knock_angle : 0;
                                _pa.knock_angle = (_kd_ang != 0) ? _kd_ang : ((_kd_dir == "forwards") ? (_face * 90) : (-_face * 90));
                                _pa.injured = true;
                            }
                            if (variable_struct_exists(_act, "is_decapitated") && _act.is_decapitated) {
                                _pa.is_decapitated = true;
                                _pa.decap_mode = variable_struct_exists(_act, "decap_mode") ? _act.decap_mode : "remove_head";
                                _pa.injured = true;
                            }
                            if (variable_struct_exists(_act, "is_foreground") && _act.is_foreground) {
                                _pa.is_foreground = true;
                            }
                            array_push(preview_actors, _pa);
                            char_facings[_act.char_index] = _face;
                        }
                    }
                    // Start in-transition (clear any leftover out-overlay first)
                    var _tin = variable_struct_exists(_b, "transition_in") ? _b.transition_in : "none";
                    if (_tin != "none") {
                        var _tin_dur = variable_struct_exists(_b, "transition_in_speed") ? _b.transition_in_speed : 60;
                        scene_transition_active   = true;
                        scene_transition_type     = _tin;
                        scene_transition_dir      = "in";
                        scene_transition_frames   = 0;
                        scene_transition_progress = 0.0;
                        scene_transition_duration = _tin_dur;
                    } else if (scene_transition_progress > 0) {
                        // No configured transition_in but came from an out-transition — auto-mirror it
                        // scene_transition_type + scene_transition_duration still hold the out values
                        scene_transition_active   = true;
                        scene_transition_dir      = "in";
                        scene_transition_frames   = 0;
                        scene_transition_progress = 0.0;
                    } else {
                        scene_transition_active   = false;
                        scene_transition_progress = 0.0;
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
                    // For knocked-down actors (full body), horizontal extent = sprite height (rotated 90°)
                    // remove_body (head only) keeps the original _w — head pivots around the foot/neck point
                    if (_act_idx != -1) {
                        var _pa_ex = preview_actors[_act_idx];
                        var _ex_is_kd = variable_struct_exists(_pa_ex, "is_knocked_down") && _pa_ex.is_knocked_down;
                        var _ex_is_rb = _ex_is_kd && variable_struct_exists(_pa_ex, "is_decapitated") && _pa_ex.is_decapitated
                                        && (variable_struct_exists(_pa_ex, "decap_mode") ? _pa_ex.decap_mode : "") == "remove_body";
                        if (_ex_is_kd && !_ex_is_rb && _spr != -1) {
                            _w = sprite_get_height(_spr) * ((scene_win_h * 1.5) / 450);
                        }
                    }

                    if (_is_enter) {
                        var _act_is_hidden = (_act_idx != -1 && variable_struct_exists(preview_actors[_act_idx], "hidden") && preview_actors[_act_idx].hidden);
                        var _act_is_inj_en = (_act_idx != -1 && !_act_is_hidden
                            && ((variable_struct_exists(preview_actors[_act_idx], "is_knocked_down") && preview_actors[_act_idx].is_knocked_down)
                             || (variable_struct_exists(preview_actors[_act_idx], "is_decapitated")  && preview_actors[_act_idx].is_decapitated)));
                        if ((_act_idx != -1 && !_act_is_hidden) || _act_is_inj_en) { speaking_pause_timer = max(speaking_pause_timer, 5); }
                        else {
                            var _start_x  = _is_left ? -(_w/2) : scene_win_w + (_w/2);
                            var _base_face = _is_left ? -1 : 1;
                            char_facings[_b.char_index] = _moon ? -_base_face : _base_face;
                            var _target_y = variable_struct_exists(_b, "target_y") ? _b.target_y : (scene_win_h * 0.8);
                            var _c = characters[_b.char_index];
                            var _pose = variable_struct_exists(_b, "enter_pose")       ? _b.enter_pose       : (variable_struct_exists(_c, "pose")       ? _c.pose       : 1);
                            var _expr = variable_struct_exists(_b, "enter_expression") ? _b.enter_expression : (variable_struct_exists(_c, "expression") ? _c.expression : 21);
                            if (_act_is_hidden) {
                                // Re-entering after exit: clear any injury state, enter fresh
                                var _ha = preview_actors[_act_idx];
                                _ha.hidden         = false;
                                _ha.x              = _start_x;
                                _ha.y              = _target_y;
                                _ha.facing         = char_facings[_b.char_index];
                                _ha.pose           = _pose;
                                _ha.expression     = _expr;
                                _ha.is_knocked_down = false;
                                _ha.knock_angle     = 0;
                                _ha.knock_direction = "forwards";
                                _ha.is_decapitated  = false;
                                _ha.injured         = false;
                            } else {
                                var _pb_enter_scale = char_entry_scales[_b.char_index];
                                var _pb_scene_blk = (active_scene_block_idx != -1) ? script_blocks[active_scene_block_idx] : undefined;
                                if (_pb_scene_blk != undefined && variable_struct_exists(_pb_scene_blk, "actors")) {
                                    for (var _pbesi = 0; _pbesi < array_length(_pb_scene_blk.actors); _pbesi++) {
                                        if (_pb_scene_blk.actors[_pbesi].char_index == _b.char_index) { _pb_enter_scale = _pb_scene_blk.actors[_pbesi][$ "scale"] ?? 1.0; break; }
                                    }
                                }
                                array_push(preview_actors, { char_index: _b.char_index, x: _start_x, y: _target_y, is_base: false, facing: char_facings[_b.char_index], pose: _pose, expression: _expr, scale: _pb_enter_scale });
                            }
                            action_animating = true;
                            array_push(active_animations, {
                                char_index: _b.char_index, type: "enter", speed: _spd,
                                target_x: variable_struct_exists(_b, "target_x") ? _b.target_x : (_is_left ? (_w/2)+20 : scene_win_w-(_w/2)-20),
                                target_y: variable_struct_exists(_b, "target_y") ? _b.target_y : scene_win_h,
                                trick: variable_struct_exists(_b, "trick") ? _b.trick : "none",
                                trick_count: variable_struct_exists(_b, "trick_count") ? _b.trick_count : 1,
                                trick_start_dist: -1, moonwalk: _moon
                            });
                        }
                    } else if (_is_exit) {
                        if (_act_idx == -1) { speaking_pause_timer = max(speaking_pause_timer, 5); }
                        else {
                            var _act_is_inj_ex = (variable_struct_exists(preview_actors[_act_idx], "is_knocked_down") && preview_actors[_act_idx].is_knocked_down)
                                              || (variable_struct_exists(preview_actors[_act_idx], "is_decapitated")  && preview_actors[_act_idx].is_decapitated);
                            if (_act_is_inj_ex) { speaking_pause_timer = max(speaking_pause_timer, 5); }
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
                                target_y: preview_actors[_act_idx].y,
                                trick: variable_struct_exists(_b, "trick") ? _b.trick : "none",
                                trick_count: variable_struct_exists(_b, "trick_count") ? _b.trick_count : 1,
                                trick_start_dist: -1, moonwalk: _moon
                            });
                            }
                        }
                    } else if (string_pos("turn", _aname) > 0) {
                        if (_act_idx != -1) { preview_actors[_act_idx].facing *= -1; char_facings[_b.char_index] = preview_actors[_act_idx].facing; }
                        speaking_pause_timer = max(speaking_pause_timer, 5);
                    } else if (string_pos("wait", _aname) > 0) {
                        var _dur = variable_struct_exists(_b, "duration") ? _b.duration : 1.0;
                        speaking_pause_timer = max(speaking_pause_timer, max(1, _dur * 60));
                    } else if (string_pos("display title", _aname) > 0) {
                        var _dur = variable_struct_exists(_b, "duration") ? _b.duration : 2.0;
                        var _tied = has_driving_event_in_chain(_blocks_to_start);
                        _b.title_tied_to_chain = _tied;
                        if (_tied) {
                            _b.title_frames = 999999;
                        } else {
                            _b.title_frames = max(1, _dur * 60);
                            var _is_linked_to_src = false;
                            for (var _check = 0; _check < array_length(_blocks_to_start); _check++) {
                                var _ctype = get_link_type(_blocks_to_start[_check]);
                                if (_ctype == "sfx" || _ctype == "voice") { _is_linked_to_src = true; break; }
                            }
                            if (!_is_linked_to_src) {
                                speaking_pause_timer = max(speaking_pause_timer, _b.title_frames);
                            }
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
                                var _wav = parse_wav_header(_b.last_buffer);
                                var _fmt = (_wav.bits == 16) ? buffer_s16 : buffer_u8;
                                var _cfmt = (_wav.chan == 2) ? audio_stereo : audio_mono;
                                _b.last_sound = audio_create_buffer_sound(_b.last_buffer, _fmt, _wav.rate, _wav.data_offset, _wav.data_size, _cfmt);
                                if (_b.last_sound != -1) {
                                    audio_play_sound(_b.last_sound, 1, false);
                                    speaking_pause_timer = max(speaking_pause_timer, ceil(audio_sound_length(_b.last_sound) * 60));
                                } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                            } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                        } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                    } else if (string_pos("moves", _aname) > 0) {
                        if (_act_idx != -1) {
                            var _act_is_inj_mv = (variable_struct_exists(preview_actors[_act_idx], "is_knocked_down") && preview_actors[_act_idx].is_knocked_down)
                                              || (variable_struct_exists(preview_actors[_act_idx], "is_decapitated")  && preview_actors[_act_idx].is_decapitated);
                            if (_act_is_inj_mv) { speaking_pause_timer = max(speaking_pause_timer, 5); }
                            else {
                            action_animating = true;
                            var _base_face = (_b.target_x > preview_actors[_act_idx].x) ? -1 : 1;
                            char_facings[_b.char_index] = _moon ? -_base_face : _base_face;
                            preview_actors[_act_idx].facing = char_facings[_b.char_index];
                            array_push(active_animations, { char_index: _b.char_index, type: "move", speed: _spd, target_x: _b.target_x, target_y: _b.target_y, trick: variable_struct_exists(_b, "trick") ? _b.trick : "none", trick_count: variable_struct_exists(_b, "trick_count") ? _b.trick_count : 1, trick_start_dist: -1, moonwalk: _moon, start_x: preview_actors[_act_idx].x, start_y: preview_actors[_act_idx].y, start_scale: preview_actors[_act_idx][$ "scale"] ?? 1.0, target_scale: variable_struct_exists(_b, "target_scale") ? _b.target_scale : (preview_actors[_act_idx][$ "scale"] ?? 1.0) });
                            }
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
                    } else if (variable_struct_exists(_b, "quake_intensity")) {
                        var _qi2   = variable_struct_exists(_b, "quake_intensity") ? _b.quake_intensity : 3;
                        var _qdir2 = variable_struct_exists(_b, "quake_direction") ? _b.quake_direction : "omni";
                        var _qfr2  = max(1, round((variable_struct_exists(_b, "quake_duration") ? _b.quake_duration : 1.0) * 60));
                        var _chain_start = has_driving_event_in_chain(_blocks_to_start) ? playing_block_index : -1;
                        quake_intensity      = _qi2;
                        quake_direction      = _qdir2;
                        quake_frames         = (_chain_start != -1) ? 999999 : _qfr2;
                        quake_tied_to_chain  = (_chain_start != -1);
                        quake_chain_start    = _chain_start;
                        if (_chain_start == -1) {
                            speaking_pause_timer = max(speaking_pause_timer, _qfr2);
                        }
                    } else if (_aname == "jitters") {
                        if (_act_idx != -1) {
                            var _ji  = variable_struct_exists(_b, "jitter_intensity") ? _b.jitter_intensity : 3;
                            var _jd  = variable_struct_exists(_b, "jitter_direction") ? _b.jitter_direction : "omni";
                            var _jfr = max(1, round((variable_struct_exists(_b, "jitter_duration") ? _b.jitter_duration : 1.0) * 60));
                            // If linked with same-char move, jitter lasts until move finishes
                            var _tied_to_move = false;
                            for (var _ti = 0; _ti < array_length(_blocks_to_start); _ti++) {
                                var _tb = _blocks_to_start[_ti];
                                if (variable_struct_exists(_tb, "char_index") && real(_tb.char_index) == real(_b.char_index) && get_link_type(_tb) == "move") { _tied_to_move = true; break; }
                            }
                            var _chain_start = has_driving_event_in_chain(_blocks_to_start) ? playing_block_index : -1;
                            action_animating = true;
                            array_push(active_animations, {
                                char_index:       _b.char_index,
                                type:             "jitter",
                                intensity:        _ji,
                                direction:        _jd,
                                frames_remaining: (_chain_start != -1 || _tied_to_move) ? 999999 : _jfr,
                                tied_to_move:     _tied_to_move,
                                tied_to_chain:    (_chain_start != -1),
                                chain_start_index: _chain_start
                            });
                        }
                        if (!has_driving_event_in_chain(_blocks_to_start)) {
                            speaking_pause_timer = max(speaking_pause_timer, 5);
                        }
                    } else if (string_pos("disappears", _aname) > 0) {
                        var _dstyle = variable_struct_exists(_b, "disappear_style") ? _b.disappear_style : "pop";
                        var _dspeed_idx = variable_struct_exists(_b, "disappear_speed") ? _b.disappear_speed : 2;
                        var _dspd = move_speeds[clamp(_dspeed_idx, 0, array_length(move_speeds)-1)];
                        if (_act_idx != -1) {
                            if (_dstyle == "eat dirt") {
                                var _dspr = get_character_sprite(_b.char_index);
                                var _dscale = (scene_win_h * 1.5) / 450;
                                var _dch = (_dspr != -1) ? sprite_get_height(_dspr) * _dscale : 300;
                                action_animating = true;
                                array_push(active_animations, {
                                    char_index: _b.char_index, type: "exit", speed: _dspd,
                                    target_x: preview_actors[_act_idx].x,
                                    target_y: scene_win_h + _dch + 20,
                                });
                            } else if (_dstyle == "home planet") {
                                action_animating = true;
                                array_push(active_animations, {
                                    char_index: _b.char_index, type: "exit", speed: _dspd,
                                    target_x: preview_actors[_act_idx].x,
                                    target_y: -20,
                                });
                            } else if (_dstyle == "disintegrate") {
                                action_animating = true;
                                var _d_dur = max(20, round(240.0 / max(0.5, _dspd)));
                                array_push(active_animations, {
                                    char_index: _b.char_index,
                                    type:       "disintegrate",
                                    speed:      _dspd,
                                    duration:   _d_dur,
                                    progress:   0.0,
                                });
                            } else if (_dstyle == "melt") {
                                action_animating = true;
                                var _m_dur = max(20, round(200.0 / max(0.5, _dspd)));
                                array_push(active_animations, {
                                    char_index: _b.char_index,
                                    type:       "melt",
                                    speed:      _dspd,
                                    duration:   _m_dur,
                                    progress:   0.0,
                                });
                            } else {
                                // pop: instant removal
                                var _is_inj = (variable_struct_exists(preview_actors[_act_idx], "is_knocked_down") && preview_actors[_act_idx].is_knocked_down)
                                           || (variable_struct_exists(preview_actors[_act_idx], "is_decapitated") && preview_actors[_act_idx].is_decapitated);
                                if (_is_inj) {
                                    preview_actors[_act_idx].hidden = true;
                                } else {
                                    array_delete(preview_actors, _act_idx, 1);
                                }
                                speaking_pause_timer = max(speaking_pause_timer, 4);
                            }
                        } else { speaking_pause_timer = max(speaking_pause_timer, 4); }
                    } else if (variable_struct_exists(_b, "injure_style")) {
                        var _istyle = _b.injure_style;
                        var _ia_offscreen = (variable_struct_exists(_b, "offscreen_pre") && _b.offscreen_pre);
                        if (_act_idx != -1) {
                            var _ia = preview_actors[_act_idx];
                            if (variable_struct_exists(_ia, "hidden") && _ia.hidden) _ia_offscreen = true;
                            if (_ia_offscreen) { speaking_pause_timer = max(speaking_pause_timer, 5); }
                            else {
                            _ia.injured = true;
                            // Cancel any active canned animation for this character
                            for (var _cai = array_length(active_animations) - 1; _cai >= 0; _cai--) {
                                if (active_animations[_cai].char_index == _b.char_index && active_animations[_cai].type == "canned") {
                                    array_delete(active_animations, _cai, 1);
                                }
                            }
                            if (_istyle == "knock_down") {
                                var _kdir_b = variable_struct_exists(_b, "knock_direction") ? _b.knock_direction : "forwards";
                                var _ifacing = variable_struct_exists(_ia, "facing") ? _ia.facing : 1;
                                _ia.is_knocked_down = true;
                                _ia.knock_direction = _kdir_b;
                                if (_ia_offscreen) {
                                    // Offscreen: set state instantly at full fall angle, no animation
                                    _ia.knock_angle = (_kdir_b == "forwards") ? (_ifacing * 90) : (-_ifacing * 90);
                                } else {
                                    var _ispd_idx = variable_struct_exists(_b, "injure_speed") ? clamp(_b.injure_speed, 0, 4) : 2;
                                    var _idurations = [130, 90, 65, 38, 22];
                                    var _idir = (_kdir_b == "forwards") ? _ifacing : -_ifacing;
                                    _ia.knock_angle = 0;
                                    action_animating = true;
                                    array_push(active_animations, {
                                        char_index: _b.char_index,
                                        type:       "injure_fall",
                                        direction:  _idir,
                                        progress:   0,
                                        duration:   _idurations[_ispd_idx],
                                    });
                                }
                            } else if (_istyle == "decapitate") {
                                var _decap_mode = variable_struct_exists(_b, "decap_mode") ? _b.decap_mode : "remove_head";
                                _ia.is_decapitated = true;
                                _ia.decap_mode     = _decap_mode;
                                if (!_ia_offscreen) {
                                    var _ksc = (scene_win_h * 1.5) / 450;
                                    var _kly = get_composite_character_sprite(_ia.char_index, _ia.pose, _ia.expression, _ia.facing);
                                    var _kbh = (_kly[0].spr != -1) ? sprite_get_height(_kly[0].spr) * _ksc : 200;
                                    var _kbw = (_kly[0].spr != -1) ? sprite_get_width(_kly[0].spr)  * _ksc : 80;
                                    var _kface = variable_struct_exists(_ia, "facing") ? _ia.facing : 1;
                                    // Flying head draw reference: 0.25 from foot matches _td_neck_by = 0.75 from top in the draw code
                                    var _neck_ux = 0;
                                    var _neck_uy = -_kbh * 0.25;
                                    // Neckhole center: midpoint of face sprite (X) at its bottom edge (Y)
                                    var _face_l    = _kly[1];
                                    var _face_w_px = (_face_l.spr != -1) ? sprite_get_width(_face_l.spr)  : 0;
                                    var _face_h_px = (_face_l.spr != -1) ? sprite_get_height(_face_l.spr) : 0;
                                    var _body_w_px = (_kly[0].spr != -1) ? sprite_get_width(_kly[0].spr)  : 80;
                                    var _body_h_px = (_kly[0].spr != -1) ? sprite_get_height(_kly[0].spr) : 200;
                                    var _splatter_ux = (_face_l.dx + _face_w_px * 0.5 - _body_w_px * 0.5) * _ksc;
                                    var _splatter_uy = -max(1, _body_h_px - _face_l.dy - _face_h_px) * _ksc;
                                    var _kangle = (variable_struct_exists(_ia, "is_knocked_down") && _ia.is_knocked_down) ? (variable_struct_exists(_ia, "knock_angle") ? _ia.knock_angle : 0) : 0;
                                    var _knx, _kny, _snx, _sny;
                                    if (abs(_kangle) > 1) {
                                        var _krac = dcos(_kangle); var _kras = dsin(_kangle);
                                        _knx = _ia.x + _neck_ux * _krac + _neck_uy * _kras;
                                        _kny = _ia.y - _neck_ux * _kras + _neck_uy * _krac;
                                        _snx = _ia.x + _splatter_ux * _krac + _splatter_uy * _kras;
                                        _sny = _ia.y - _splatter_ux * _kras + _splatter_uy * _krac;
                                    } else {
                                        _knx = _ia.x + _neck_ux;
                                        _kny = _ia.y + _neck_uy;
                                        _snx = _ia.x + _splatter_ux;
                                        _sny = _ia.y + _splatter_uy;
                                    }
                                    // Fly direction: away from neck along the rotated "up" axis
                                    var _fly_angle = 270 - _kangle;
                                    start_particle_emitter("splatter", _snx, _sny, _fly_angle, 1.5, 0.55, 7, 1.8, 100, "darkred", 0,0,0, 18, 8);
                                    // Base fly velocity is straight up; rotate by knock_angle so it fires away from the neck regardless of orientation
                                    var _base_spd = random_range(4.5, 5.5);
                                    var _fly_krac = dcos(_kangle); var _fly_kras = dsin(_kangle);
                                    var _hvx = _base_spd * _fly_kras + random_range(-1.0, 1.0);
                                    var _hvy = -_base_spd * _fly_krac + random_range(-1.0, 1.0);
                                    var _hspin = random_range(5, 9) * ((_hvx >= 0) ? 1 : -1);
                                    array_push(active_decap_heads, {
                                        char_index:  _ia.char_index,
                                        pose:        _ia.pose,
                                        expression:  _ia.expression,
                                        facing:      _kface,
                                        decap_mode:  _decap_mode,
                                        body_w:      _kbw,
                                        body_h:      _kbh,
                                        x:           scene_win_x + _snx,
                                        y:           scene_win_y + _sny,
                                        vx:          _hvx,
                                        vy:          _hvy,
                                        angle:       0,
                                        spin:        _hspin,
                                        alpha:       1.0,
                                        life:        0,
                                        max_life:    150,
                                    });
                                }
                            }
                        }
                        if (_istyle == "decapitate") speaking_pause_timer = max(speaking_pause_timer, 300);
                        else speaking_pause_timer = max(speaking_pause_timer, 5);
                        } // end !_ia_offscreen
                    } else if (string_pos("stands up", _aname) > 0) {
                        if (_act_idx != -1) {
                            var _sua = preview_actors[_act_idx];
                            var _sua_is_kd = variable_struct_exists(_sua, "is_knocked_down") && _sua.is_knocked_down;
                            if (_sua_is_kd) {
                                var _cur_kangle = variable_struct_exists(_sua, "knock_angle") ? _sua.knock_angle : 0;
                                if (_cur_kangle == 0) {
                                    var _sua_face = variable_struct_exists(_sua, "facing") ? _sua.facing : 1;
                                    var _sua_kdir = variable_struct_exists(_sua, "knock_direction") ? _sua.knock_direction : "forwards";
                                    _cur_kangle = (_sua_kdir == "forwards") ? (_sua_face * 90) : (-_sua_face * 90);
                                    _sua.knock_angle = _cur_kangle;
                                }
                                var _sdurations = [130, 90, 65, 38, 22];
                                var _sspd = variable_struct_exists(_b, "standup_speed") ? clamp(_b.standup_speed, 0, 4) : 2;
                                action_animating = true;
                                array_push(active_animations, {
                                    char_index:  _b.char_index,
                                    type:        "stand_up",
                                    start_angle: _cur_kangle,
                                    progress:    0,
                                    duration:    _sdurations[_sspd],
                                });
                            } else {
                                _sua.knock_angle     = 0;
                                _sua.is_knocked_down = false;
                                _sua.knock_direction = "forwards";
                                var _still_inj3 = variable_struct_exists(_sua, "is_decapitated") && _sua.is_decapitated;
                                _sua.injured = _still_inj3;
                            }
                        }
                        speaking_pause_timer = max(speaking_pause_timer, 22);
                    } else if (string_pos("reforms", _aname) > 0) {
                        if (_act_idx != -1) {
                            var _rha = preview_actors[_act_idx];
                            var _rha_is_decap = variable_struct_exists(_rha, "is_decapitated") && _rha.is_decapitated;
                            if (!_rha_is_decap) {
                                _rha.is_decapitated = false;
                                var _still_inj_nd = variable_struct_exists(_rha, "is_knocked_down") && _rha.is_knocked_down;
                                _rha.injured = _still_inj_nd;
                                speaking_pause_timer = max(speaking_pause_timer, 10);
                            } else {
                            var _rha_offscreen = variable_struct_exists(_rha, "is_offscreen") && _rha.is_offscreen;
                            if (!_rha_offscreen) {
                                var _rsc = (scene_win_h * 1.5) / 450;
                                var _rly = get_composite_character_sprite(_rha.char_index, _rha.pose, _rha.expression, variable_struct_exists(_rha, "facing") ? _rha.facing : 1);
                                var _rbh = (_rly[0].spr != -1) ? sprite_get_height(_rly[0].spr) * _rsc : 200;
                                var _rbw = (_rly[0].spr != -1) ? sprite_get_width(_rly[0].spr)  * _rsc : 80;
                                var _rface = variable_struct_exists(_rha, "facing") ? _rha.facing : 1;
                                var _rdm = variable_struct_exists(_rha, "decap_mode") ? _rha.decap_mode : "remove_head";
                                var _r_face_l    = _rly[1];
                                var _r_face_w_px = (_r_face_l.spr != -1) ? sprite_get_width(_r_face_l.spr)  : 0;
                                var _r_face_h_px = (_r_face_l.spr != -1) ? sprite_get_height(_r_face_l.spr) : 0;
                                var _r_body_w_px = (_rly[0].spr != -1) ? sprite_get_width(_rly[0].spr)  : 80;
                                var _r_body_h_px = (_rly[0].spr != -1) ? sprite_get_height(_rly[0].spr) : 200;
                                var _r_neck_ux = (_r_face_l.dx + _r_face_w_px * 0.5 - _r_body_w_px * 0.5) * _rsc;
                                var _r_neck_uy = -max(1, _r_body_h_px - _r_face_l.dy - _r_face_h_px) * _rsc;
                                var _rkangle = (variable_struct_exists(_rha, "is_knocked_down") && _rha.is_knocked_down) ? (variable_struct_exists(_rha, "knock_angle") ? _rha.knock_angle : 0) : 0;
                                var _rnx, _rny;
                                if (abs(_rkangle) > 1) {
                                    var _r_krac = dcos(_rkangle); var _r_kras = dsin(_rkangle);
                                    _rnx = _rha.x + _r_neck_ux * _r_krac + _r_neck_uy * _r_kras;
                                    _rny = _rha.y - _r_neck_ux * _r_kras + _r_neck_uy * _r_krac;
                                } else {
                                    _rnx = _rha.x + _r_neck_ux;
                                    _rny = _rha.y + _r_neck_uy;
                                }
                                var _reform_dur = 55;
                                var _r_start_x = scene_win_x + _rnx + dsin(_rkangle) * scene_win_h * 0.85;
                                var _r_start_y = scene_win_y + _rny - dcos(_rkangle) * scene_win_h * 0.85;
                                var _r_end_x = scene_win_x + _rnx;
                                var _r_end_y = scene_win_y + _rny;
                                array_push(active_decap_heads, {
                                    char_index:  _rha.char_index,
                                    pose:        _rha.pose,
                                    expression:  variable_struct_exists(_rha, "expression") ? _rha.expression : 21,
                                    facing:      _rface,
                                    decap_mode:  _rdm,
                                    body_w:      _rbw,
                                    body_h:      _rbh,
                                    x:           _r_start_x,
                                    y:           _r_start_y,
                                    vx:          0,
                                    vy:          0,
                                    angle:       random_range(-180, 180),
                                    spin:        random_range(-9, 9),
                                    alpha:       1.0,
                                    life:        0,
                                    max_life:    _reform_dur,
                                    returning:   true,
                                    target_x:    _r_end_x,
                                    target_y:    _r_end_y,
                                    char_ref:    _rha,
                                });
                                speaking_pause_timer = max(speaking_pause_timer, _reform_dur + 10);
                            } else {
                                _rha.is_decapitated = false;
                                var _still_inj4b = variable_struct_exists(_rha, "is_knocked_down") && _rha.is_knocked_down;
                                _rha.injured = _still_inj4b;
                                speaking_pause_timer = max(speaking_pause_timer, 10);
                            }
                            } // end _rha_is_decap
                        } else {
                            speaking_pause_timer = max(speaking_pause_timer, 10);
                        }
                    } else if (string_pos("rolls over", _aname) > 0) {
                        if (_act_idx != -1) {
                            var _roa = preview_actors[_act_idx];
                            if (variable_struct_exists(_roa, "knock_direction")) {
                                var _cur_kd = _roa.knock_direction;
                                var _new_kd = (_cur_kd == "forwards") ? "backwards" : "forwards";
                                _roa.knock_direction = _new_kd;
                                _roa.facing *= -1;
                                char_facings[_b.char_index] = _roa.facing;
                                _roa.knock_angle = (_new_kd == "forwards") ? (_roa.facing * 90) : (-_roa.facing * 90);
                            }
                        }
                        speaking_pause_timer = max(speaking_pause_timer, 5);
                    } else if (canned_anim_find(_b.char_index, _b.action_name) != undefined) {
                        var _canim = canned_anim_find(_b.char_index, _b.action_name);
                        var _ca_aidx = -1;
                        for (var _ca_a = 0; _ca_a < array_length(preview_actors); _ca_a++) {
                            if (preview_actors[_ca_a].char_index == _b.char_index) { _ca_aidx = _ca_a; break; }
                        }
                        if (_ca_aidx != -1) {
                            var _ca_state = {
                                type:       "canned",
                                char_index: _b.char_index,
                                anim_data:  _canim,
                                frame_idx:  0,
                                tick:       0,
                            };
                            canned_anim_seek_next_sprite(_ca_state);
                            if (_ca_state.frame_idx < array_length(_canim.frames)) {
                                var _cf0 = _canim.frames[_ca_state.frame_idx];
                                if (_cf0.type == "sprite") {
                                    var _facing0 = variable_struct_exists(preview_actors[_ca_aidx], "facing") ? preview_actors[_ca_aidx].facing : 1;
                                    var _def0 = variable_struct_exists(characters[_b.char_index], "default_facing") ? characters[_b.char_index].default_facing : 1;
                                    var _spr0 = (_facing0 != _def0 && variable_struct_exists(_cf0, "sprite_flipped") && _cf0.sprite_flipped != "")
                                                ? _cf0.sprite_flipped
                                                : canned_anim_facing_sprite(_cf0.sprite, _b.char_index, _facing0);
                                    preview_actors[_ca_aidx].canned_spr = canned_anim_load_sprite(_b.char_index, _spr0);
                                    if (preview_actors[_ca_aidx].canned_spr == -1 && _spr0 != _cf0.sprite) {
                                        preview_actors[_ca_aidx].canned_spr = canned_anim_load_sprite(_b.char_index, _cf0.sprite);
                                    }
                                    preview_actors[_ca_aidx].canned_anchor_y  = variable_struct_exists(_cf0, "anchor_y") ? _cf0.anchor_y : 0;
                                    var _anim_feet0 = "";
                                    if (_facing0 != _def0) {
                                        var _ff0 = variable_struct_exists(_canim, "feet_sprite_flipped") ? _canim.feet_sprite_flipped : "";
                                        if (_ff0 != "") { _anim_feet0 = _ff0; }
                                        else { var _nf0 = variable_struct_exists(_canim, "feet_sprite") ? _canim.feet_sprite : ""; if (_nf0 != "") _anim_feet0 = canned_anim_flipped_name(_nf0); }
                                    } else {
                                        _anim_feet0 = variable_struct_exists(_canim, "feet_sprite") ? _canim.feet_sprite : "";
                                    }
                                    preview_actors[_ca_aidx].canned_composite = (_anim_feet0 != "");
                                    preview_actors[_ca_aidx].canned_feet_spr  = (_anim_feet0 != "") ? canned_anim_load_sprite(_b.char_index, _anim_feet0) : -1;
                                    var _is_flipped0 = (_facing0 != _def0);
                                    preview_actors[_ca_aidx].canned_composite_legs = true;
                                    if (_is_flipped0 && variable_struct_exists(_cf0, "composite_legs_flipped")) {
                                        preview_actors[_ca_aidx].canned_composite_legs = _cf0.composite_legs_flipped;
                                    } else if (variable_struct_exists(_cf0, "composite_legs") && !_cf0.composite_legs) {
                                        preview_actors[_ca_aidx].canned_composite_legs = false;
                                    }
                                    var _fdy0 = (_is_flipped0 && variable_struct_exists(_cf0, "frame_dy_flipped")) ? _cf0.frame_dy_flipped
                                              : (variable_struct_exists(_cf0, "frame_dy") ? _cf0.frame_dy : 0);
                                    var _fdx0 = (_is_flipped0 && variable_struct_exists(_cf0, "frame_dx_flipped")) ? _cf0.frame_dx_flipped
                                              : (variable_struct_exists(_cf0, "frame_dx") ? _cf0.frame_dx : 0);
                                    var _bdy_key0 = _is_flipped0 ? "body_dy_flipped" : "body_dy";
                                    preview_actors[_ca_aidx].canned_body_dy   = (variable_struct_exists(_canim, _bdy_key0) ? _canim[$ _bdy_key0] : 0) + _fdy0;
                                    var _c0  = characters[_b.char_index];
                                    var _nm0 = variable_struct_exists(_c0, "sprite_name") ? _c0.sprite_name : _c0.name;
                                    if (!ds_map_exists(char_offsets_cache, _nm0)) {
                                        ds_map_add(char_offsets_cache, _nm0, load_config_json(_nm0, "offsets.json"));
                                    }
                                    var _od0 = char_offsets_cache[? _nm0];
                                    var _body_ok0 = string_replace(_spr0, ".png", "");
                                    if (!_is_flipped0 && _od0 != undefined && !variable_struct_exists(_od0, _body_ok0))
                                        _body_ok0 = string_replace(_cf0.sprite, ".png", "");
                                    var _feet_ok0 = string_replace(_anim_feet0, ".png", "");
                                    var _has_bx0 = (_od0 != undefined && variable_struct_exists(_od0, _body_ok0));
                                    var _has_fx0 = (_od0 != undefined && _anim_feet0 != "" && variable_struct_exists(_od0, _feet_ok0));
                                    var _bdx_key0 = _is_flipped0 ? "body_dx_flipped" : "body_dx";
                                    preview_actors[_ca_aidx].canned_body_dx = ((_has_bx0 && _has_fx0) ? (_od0[$ _body_ok0][0] - _od0[$ _feet_ok0][0]) : 0) + _fdx0 + (variable_struct_exists(_canim, _bdx_key0) ? _canim[$ _bdx_key0] : 0);
                                }
                            }
                            action_animating = true;
                            array_push(active_animations, _ca_state);
                        } else {
                            speaking_pause_timer = max(speaking_pause_timer, 4);
                        }
                    } else { speaking_pause_timer = max(speaking_pause_timer, 5); }
                } else if (_is_particle) {
                    var _psize  = variable_struct_exists(_b, "size")     ? _b.size     : 1.0;
                    var _pdur   = variable_struct_exists(_b, "duration") ? _b.duration : 1.0;
                    var _pden   = variable_struct_exists(_b, "density")  ? _b.density  : 2;
                    var _pspd   = variable_struct_exists(_b, "speed")    ? _b.speed    : 1.0;
                    var _pspr   = variable_struct_exists(_b, "spread")   ? _b.spread   : 65;
                    var _pcol   = variable_struct_exists(_b, "color")   ? _b.color   : "red";
                    var _pcr    = variable_struct_exists(_b, "color_r") ? _b.color_r : 200;
                    var _pcg    = variable_struct_exists(_b, "color_g") ? _b.color_g : 0;
                    var _pcb    = variable_struct_exists(_b, "color_b") ? _b.color_b : 0;
                    var _paw    = variable_struct_exists(_b, "area_w")  ? _b.area_w  : 0;
                    var _pah    = variable_struct_exists(_b, "area_h")  ? _b.area_h  : 0;
                    var _chain_start = has_driving_event_in_chain(_blocks_to_start) ? playing_block_index : -1;
                    start_particle_emitter(_b.effect, _b.x, _b.y, _b.angle, _psize, _pdur, _pden, _pspd, _pspr, _pcol, _pcr, _pcg, _pcb, _paw, _pah, _chain_start);
                    if (_b.effect == "shot") {
                        speaking_pause_timer = max(speaking_pause_timer, 4);
                        waiting_for_shots    = true;
                    } else {
                        if (_chain_start == -1) {
                            speaking_pause_timer = max(speaking_pause_timer, round(_pdur * 60));
                        }
                    }
                } else {
                    var _is_empty = true;
                    for (var _e_idx = 1; _e_idx <= string_length(_b.text); _e_idx++) {
                        if (string_char_at(_b.text, _e_idx) != " " && string_char_at(_b.text, _e_idx) != "\n" && string_char_at(_b.text, _e_idx) != "\r") { _is_empty = false; break; }
                    }
                    var _phonetic_text = apply_dictionary(_b.text);
                    if (_is_empty) {
                        _b.tts_req = -1;
                    } else {
                        var _cc = characters[_b.char_index];
                        var _req = tts_speak(_phonetic_text, _b.voice_id, _b.pitch, _b.speed, _b.mode, _b.style,
                            _b[$ "glottal"]   ?? _cc[$ "glottal"]   ?? -1,
                            _b[$ "f0perturb"] ?? _cc[$ "f0perturb"] ?? -1,
                            _b[$ "f0range"]   ?? _cc[$ "f0range"]   ?? -1,
                            _b[$ "speaking"]  ?? _cc[$ "speaking"]  ?? -1,
                            _b[$ "vowel"]     ?? _cc[$ "vowel"]     ?? -1,
                            _b[$ "volume"]    ?? _cc[$ "volume"]    ?? 50);
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

                if (!(_is_scene || _is_action || _is_particle) && _b.tts_req != -1) {
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
