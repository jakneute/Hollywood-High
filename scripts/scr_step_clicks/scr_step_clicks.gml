function step_ui_clicks(_mx, _my) {
    var _overlay_active = false;
if (mouse_check_button_pressed(mb_left)) {
    // PLAY Button
    
    // FILE MENU TOGGLE
    if (!file_menu_open && playing_block_index == -1 && _mx > 10 && _mx < 90 && _my > 10 && _my < 45) {
        file_menu_open = true;
        return;
    }

    if (!script_expanded && _mx > btn_play_x && _mx < btn_play_x + btn_play_w && _my > btn_play_y && _my < btn_play_y + btn_play_h) {
        focused_block = -1; block_last_click_idx = -1;
        selection_start = 0; selection_end = 0;
        if (playing_block_index != -1) {
            stop_playback();
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

    // Panel tab toggle (CHARS / FX)
    if (!theater_mode && playing_block_index == -1 && _my > char_sel_y + 4 && _my < char_sel_y + 26) {
        if (_mx > char_sel_x + 5 && _mx < char_sel_x + 70) {
            particle_panel_mode = false; dragging_particle_effect = ""; return;
        }
        if (_mx > char_sel_x + 73 && _mx < char_sel_x + 118) {
            particle_panel_mode = true; return;
        }
    }

    // Particle edit mode — DONE / PREVIEW / start handle drag
    if (particle_edit_mode && particle_edit_block_idx != -1 && particle_edit_block_idx < array_length(script_blocks)) {
        var _peb2 = script_blocks[particle_edit_block_idx];
        // "PARTICLE EDIT" label click → exit
        var _pe_lx = max(scene_win_x, 98);
        if (_mx >= _pe_lx && _mx <= _pe_lx + 140 && _my >= scene_win_y - 44 && _my <= scene_win_y - 10) {
            particle_edit_mode = false; focused_block = -1; particle_drag_pos = false; particle_drag_dir = false; particle_drag_area_w = false; particle_drag_area_h = false; return;
        }
        var _on_right2 = (_peb2.x < scene_win_w * 0.35);
        var _pbase_x2  = _on_right2 ? (scene_win_x + scene_win_w - 210) : (scene_win_x + 5);
        var _ped_x = _on_right2 ? (scene_win_x + 10) : (scene_win_x + scene_win_w - 90); var _ped_y = scene_win_y + 8;
        if (_mx > _ped_x && _mx < _ped_x + 80 && _my > _ped_y && _my < _ped_y + 26) {
            particle_edit_mode = false; focused_block = -1; particle_drag_pos = false; particle_drag_dir = false; particle_drag_area_w = false; particle_drag_area_h = false; return;
        }
        var _pep_x = _on_right2 ? (scene_win_x + 100) : (scene_win_x + scene_win_w - 185); var _pep_y = scene_win_y + 8;
        if (_mx > _pep_x && _mx < _pep_x + 86 && _my > _pep_y && _my < _pep_y + 26) {
            var _psize2 = variable_struct_exists(_peb2, "size")     ? _peb2.size     : 1.0;
            var _pdur2  = variable_struct_exists(_peb2, "duration") ? _peb2.duration : 1.0;
            var _pden2  = variable_struct_exists(_peb2, "density")  ? _peb2.density  : 2;
            var _pspd2  = variable_struct_exists(_peb2, "speed")    ? _peb2.speed    : 1.0;
            var _pspr2  = variable_struct_exists(_peb2, "spread")   ? _peb2.spread   : 65;
            var _pcol2  = variable_struct_exists(_peb2, "color")   ? _peb2.color   : "red";
            var _pcr2   = variable_struct_exists(_peb2, "color_r") ? _peb2.color_r : 200;
            var _pcg2   = variable_struct_exists(_peb2, "color_g") ? _peb2.color_g : 0;
            var _pcb2   = variable_struct_exists(_peb2, "color_b") ? _peb2.color_b : 0;
            var _paw2   = variable_struct_exists(_peb2, "area_w")  ? _peb2.area_w  : 0;
            var _pah2   = variable_struct_exists(_peb2, "area_h")  ? _peb2.area_h  : 0;
            active_particles = []; active_emitters = []; active_beams = []; active_explosions = []; active_shots = []; waiting_for_shots = false;
            start_particle_emitter(_peb2.effect, _peb2.x, _peb2.y, _peb2.angle, _psize2, _pdur2, _pden2, _pspd2, _pspr2, _pcol2, _pcr2, _pcg2, _pcb2, _paw2, _pah2); return;
        }
        var _ped_dot_sx = scene_win_x + _peb2.x;
        var _ped_dot_sy = scene_win_y + _peb2.y;
        var _ped_tip_x  = _ped_dot_sx + cos(degtorad(_peb2.angle)) * 65;
        var _ped_tip_y  = _ped_dot_sy + sin(degtorad(_peb2.angle)) * 65;
        if (point_distance(_mx, _my, _ped_tip_x, _ped_tip_y) < 14) { particle_drag_dir = true; return; }
        // Area handles (disabled for laser and explosion)
        var _paw_h = (_peb2.effect != "laser" && _peb2.effect != "explosion" && variable_struct_exists(_peb2, "area_w")) ? _peb2.area_w : 0;
        var _pah_h = (_peb2.effect != "laser" && _peb2.effect != "explosion" && variable_struct_exists(_peb2, "area_h")) ? _peb2.area_h : 0;
        var _aw_hx2 = _ped_dot_sx + max(18, _paw_h/2);
        var _ah_hy2 = _ped_dot_sy - max(18, _pah_h/2);
        if (point_distance(_mx, _my, _aw_hx2, _ped_dot_sy) < 10) { particle_drag_area_w = true; return; }
        if (point_distance(_mx, _my, _ped_dot_sx, _ah_hy2)  < 10) { particle_drag_area_h = true; return; }
        if ((_paw_h > 0 || _pah_h > 0) && _mx > _ped_dot_sx-20 && _mx < _ped_dot_sx+20
                && _my > _ped_dot_sy+14 && _my < _ped_dot_sy+32) {
            _peb2.area_w = 0; _peb2.area_h = 0; return;
        }
        if (point_distance(_mx, _my, _ped_dot_sx, _ped_dot_sy) < 16) { particle_drag_pos = true; return; }
        // Size / Duration / Density / Speed / Spread controls — positions must match Draw exactly
        var _psz  = variable_struct_exists(_peb2, "size")     ? _peb2.size     : 1.0;
        var _pdur = variable_struct_exists(_peb2, "duration") ? _peb2.duration : 1.0;
        var _pden = variable_struct_exists(_peb2, "density")  ? _peb2.density  : 2;
        var _pspd = variable_struct_exists(_peb2, "speed")    ? _peb2.speed    : 1.0;
        var _pspr = variable_struct_exists(_peb2, "spread")   ? _peb2.spread   : 65;
        var _r1y2 = scene_win_y + 14; var _r2y2 = scene_win_y + 42;
        var _r3y2 = scene_win_y + 70;  var _r4y2 = scene_win_y + 98;  var _r5y2 = scene_win_y + 126;
        var _pbsz2 = 24; var _clx2 = _pbase_x2 + 70; var _crx2 = _pbase_x2 + 143;
        // SIZE [-] [+]
        if (_peb2.effect != "shot") {
            if (_mx >= _clx2 && _mx <= _clx2+_pbsz2 && _my >= _r1y2 && _my <= _r1y2+_pbsz2) { _peb2.size     = max(0.25, _psz  - 0.25); return; }
            if (_mx >= _crx2 && _mx <= _crx2+_pbsz2 && _my >= _r1y2 && _my <= _r1y2+_pbsz2) { _peb2.size     = min(5.0,  _psz  + 0.25); return; }
        }
        // DUR [-] [+]
        if (_peb2.effect != "shot") {
            if (_mx >= _clx2 && _mx <= _clx2+_pbsz2 && _my >= _r2y2 && _my <= _r2y2+_pbsz2) { _peb2.duration = max(0.25, _pdur - 0.25); return; }
            if (_mx >= _crx2 && _mx <= _crx2+_pbsz2 && _my >= _r2y2 && _my <= _r2y2+_pbsz2) { _peb2.duration = min(5.0,  _pdur + 0.25); return; }
        }
        // DENSITY [-] [+]
        if (_peb2.effect != "laser") {
            if (_mx >= _clx2 && _mx <= _clx2+_pbsz2 && _my >= _r3y2 && _my <= _r3y2+_pbsz2) { _peb2.density  = max(1,    _pden - 1);    return; }
            if (_mx >= _crx2 && _mx <= _crx2+_pbsz2 && _my >= _r3y2 && _my <= _r3y2+_pbsz2) { _peb2.density  = min(10,   _pden + 1);    return; }
        }
        // SPEED [-] [+]
        if (_peb2.effect == "shot") {
            if (_mx >= _clx2 && _mx <= _clx2+_pbsz2 && _my >= _r4y2 && _my <= _r4y2+_pbsz2) { _peb2.speed = max(4.0,  _pspd - 4.0);  return; }
            if (_mx >= _crx2 && _mx <= _crx2+_pbsz2 && _my >= _r4y2 && _my <= _r4y2+_pbsz2) { _peb2.speed = min(20.0, _pspd + 4.0);  return; }
        } else if (_peb2.effect != "laser") {
            if (_mx >= _clx2 && _mx <= _clx2+_pbsz2 && _my >= _r4y2 && _my <= _r4y2+_pbsz2) { _peb2.speed    = max(0.25, _pspd - 0.25); return; }
            if (_mx >= _crx2 && _mx <= _crx2+_pbsz2 && _my >= _r4y2 && _my <= _r4y2+_pbsz2) { _peb2.speed    = min(5.0,  _pspd + 0.25); return; }
        }
        // SPREAD [-] [+]
        if (_peb2.effect != "laser") {
            if (_mx >= _clx2 && _mx <= _clx2+_pbsz2 && _my >= _r5y2 && _my <= _r5y2+_pbsz2) { _peb2.spread   = max(0,    _pspr - 5);    return; }
            if (_mx >= _crx2 && _mx <= _crx2+_pbsz2 && _my >= _r5y2 && _my <= _r5y2+_pbsz2) { _peb2.spread   = min(180,  _pspr + 5);    return; }
        }
        // COLOR swatches — 3 rows of 4 (24px each, 4px gap), positions must match Draw exactly
        var _pcolors2 = ["red",     "darkred",   "crimson",   "maroon",
                         "orange",  "yellow",    "brown",     "darkbrown",
                         "glass",   "white",     "electric",  "black"];
        var _csxo2 = _pbase_x2 + 46; var _cr_ys2 = [scene_win_y + 180, scene_win_y + 208, scene_win_y + 236];
        for (var _ci2 = 0; _ci2 < array_length(_pcolors2); _ci2++) {
            var _csx2 = _csxo2 + (_ci2 mod 4) * 28;
            var _csy2 = _cr_ys2[floor(_ci2 / 4)];
            if (_mx >= _csx2 && _mx <= _csx2+24 && _my >= _csy2 && _my <= _csy2+24) {
                _peb2.color = _pcolors2[_ci2]; return;
            }
        }
        // [CUSTOM RGB] button
        if (_mx >= _csxo2 && _mx <= _csxo2+108 && _my >= scene_win_y + 268 && _my <= scene_win_y + 290) {
            _peb2.color = "custom"; return;
        }
        // Custom RGB sliders (only when custom selected)
        if (variable_struct_exists(_peb2, "color") && _peb2.color == "custom") {
            var _pcr3 = variable_struct_exists(_peb2, "color_r") ? _peb2.color_r : 200;
            var _pcg3 = variable_struct_exists(_peb2, "color_g") ? _peb2.color_g : 0;
            var _pcb3 = variable_struct_exists(_peb2, "color_b") ? _peb2.color_b : 0;
            var _r7y2 = scene_win_y + 298; var _r8y2 = scene_win_y + 326; var _r9y2 = scene_win_y + 354;
            // Commit any in-progress typed value before handling this click
            if (rgb_edit_channel != -1) {
                var _cv = clamp(string_length(rgb_edit_str) > 0 ? real(rgb_edit_str) : 0, 0, 255);
                if      (rgb_edit_channel == 0) _peb2.color_r = _cv;
                else if (rgb_edit_channel == 1) _peb2.color_g = _cv;
                else                            _peb2.color_b = _cv;
                rgb_edit_channel = -1; rgb_edit_str = "";
                _pcr3 = _peb2.color_r; _pcg3 = _peb2.color_g; _pcb3 = _peb2.color_b;
            }
            // [-] [+] buttons — fire once on press, hold-repeat handled in step
            if (_mx>=_clx2&&_mx<=_clx2+_pbsz2&&_my>=_r7y2&&_my<=_r7y2+_pbsz2) { _peb2.color_r=max(0,  _pcr3-5); rgb_hold_btn="r-"; rgb_hold_timer=0; return; }
            if (_mx>=_crx2&&_mx<=_crx2+_pbsz2&&_my>=_r7y2&&_my<=_r7y2+_pbsz2) { _peb2.color_r=min(255,_pcr3+5); rgb_hold_btn="r+"; rgb_hold_timer=0; return; }
            if (_mx>=_clx2&&_mx<=_clx2+_pbsz2&&_my>=_r8y2&&_my<=_r8y2+_pbsz2) { _peb2.color_g=max(0,  _pcg3-5); rgb_hold_btn="g-"; rgb_hold_timer=0; return; }
            if (_mx>=_crx2&&_mx<=_crx2+_pbsz2&&_my>=_r8y2&&_my<=_r8y2+_pbsz2) { _peb2.color_g=min(255,_pcg3+5); rgb_hold_btn="g+"; rgb_hold_timer=0; return; }
            if (_mx>=_clx2&&_mx<=_clx2+_pbsz2&&_my>=_r9y2&&_my<=_r9y2+_pbsz2) { _peb2.color_b=max(0,  _pcb3-5); rgb_hold_btn="b-"; rgb_hold_timer=0; return; }
            if (_mx>=_crx2&&_mx<=_crx2+_pbsz2&&_my>=_r9y2&&_my<=_r9y2+_pbsz2) { _peb2.color_b=min(255,_pcb3+5); rgb_hold_btn="b+"; rgb_hold_timer=0; return; }
            // Click on value display → enter type mode for that channel
            var _val_x1 = _clx2 + _pbsz2; var _val_x2 = _crx2;
            if (_mx>=_val_x1&&_mx<=_val_x2&&_my>=_r7y2&&_my<=_r7y2+_pbsz2) { rgb_edit_channel=0; rgb_edit_str=string(_pcr3); keyboard_string=""; return; }
            if (_mx>=_val_x1&&_mx<=_val_x2&&_my>=_r8y2&&_my<=_r8y2+_pbsz2) { rgb_edit_channel=1; rgb_edit_str=string(_pcg3); keyboard_string=""; return; }
            if (_mx>=_val_x1&&_mx<=_val_x2&&_my>=_r9y2&&_my<=_r9y2+_pbsz2) { rgb_edit_channel=2; rgb_edit_str=string(_pcb3); keyboard_string=""; return; }
        }
        // Guard: don't teleport if click is in the control strip area
        var _is_cust2 = variable_struct_exists(_peb2, "color") && _peb2.color == "custom";
        if (_my >= scene_win_y + 10 && _my <= (_is_cust2 ? scene_win_y + 382 : scene_win_y + 294)) return;

        // click elsewhere on scene to teleport emitter (skip if clicking on a character)
        if (_mx > scene_win_x && _mx < scene_win_x + scene_win_w && _my > scene_win_y && _my < scene_win_y + scene_win_h) {
            var _on_char = false;
            var _pscale = (scene_win_h * 1.5) / 450;
            for (var _pci = array_length(preview_actors) - 1; _pci >= 0; _pci--) {
                var _pca = preview_actors[_pci];
                var _tl = get_composite_character_sprite(_pca.char_index, variable_struct_exists(_pca, "pose") ? _pca.pose : 1, variable_struct_exists(_pca, "expression") ? _pca.expression : 21, variable_struct_exists(_pca, "facing") ? _pca.facing : undefined);
                _pspr = _tl[0].spr;
                if (_pspr != -1) {
                    var _psw = sprite_get_width(_pspr) * _pscale;
                    var _psh = (sprite_get_height(_pspr) + max(0, -_tl[1].dy)) * _pscale;
                    var _pax = scene_win_x + _pca.x;
                    var _pay = scene_win_y + _pca.y;
                    if (_mx > _pax - _psw/2 && _mx < _pax + _psw/2 && _my > _pay - _psh && _my < _pay) {
                        _on_char = true; break;
                    }
                }
            }
            if (!_on_char) { _peb2.x = _mx - scene_win_x; _peb2.y = _my - scene_win_y; }
            return;
        }
    }

    // EXPR CFG / ANIM EDITOR buttons — side by side in the header row
    if (!particle_panel_mode && !theater_mode && playing_block_index == -1) {
        var _has_anims_b = SHOW_ANIM_EDITOR;
        var _btn_l2  = char_sel_x + 195;
        var _btn_r2  = char_sel_x + char_sel_w - 6;
        var _btn_mid2 = floor((_btn_l2 + _btn_r2) / 2) - 1;
        var _ex_r2   = (SHOW_EXPR_CFG && _has_anims_b) ? _btn_mid2 : _btn_r2;
        var _an_l2   = (SHOW_EXPR_CFG && _has_anims_b) ? _btn_mid2 + 2 : _btn_l2;
        if (SHOW_EXPR_CFG && _mx > _btn_l2 && _mx < _ex_r2 && _my > char_sel_y + 2 && _my < char_sel_y + 26) {
            if (characters[selected_character_index].name != "NARRATOR") open_expr_configurator(selected_character_index);
            return;
        }
        if (_has_anims_b && characters[selected_character_index].name != "NARRATOR" && _mx > _an_l2 && _mx < _btn_r2 && _my > char_sel_y + 2 && _my < char_sel_y + 26) {
            anim_editor_open          = true;
            anim_editor_char_idx      = selected_character_index;
            anim_editor_anim_idx      = 0;
            anim_editor_frame_idx     = 0;
            anim_editor_selected_frame = -1;
            anim_editor_playing       = false;
            anim_editor_tick          = 0;
            anim_editor_sprite_list   = [];
            anim_editor_flipped_mode  = false;
            anim_editor_pan_x = 0; anim_editor_pan_y = 0; anim_editor_pan_drag = false; anim_editor_zoom = 1.0;
            return;
        }
    }

    // GLOBAL HEADER BUTTONS (Theater & Move Params)
    if (!theater_mode && !is_speaking && playing_block_index == -1 && !action_modal_open && !scene_modal_open && !move_modal_open) {
        if (_mx > btn_theater_x && _mx < btn_theater_x + btn_theater_w && _my > btn_theater_y && _my < btn_theater_y + btn_theater_h) {
            theater_mode = true;
            theater_paused = true;
            theater_subtitles = "";
            theater_ui_timer = 120;
            theater_was_mid_speech = false;
            scene_edit_mode = false;
            insertion_idx = -1;
            play_from_index(0); 
            return;
        }

        // POSE / EXPR Combined Button Click (disabled for Narrator and particle blocks)
        var _is_narrator = (characters[selected_character_index].name == "NARRATOR");
        var _foc_is_particle = particle_edit_mode || (insertion_idx == -1 && focused_block != -1 && focused_block < array_length(script_blocks) && variable_struct_exists(script_blocks[focused_block], "type") && script_blocks[focused_block].type == "particle");
        if (_mx > btn_pose_x && _mx < btn_expression_x + btn_expression_w && _my > btn_pose_y && _my < btn_pose_y + btn_pose_h) {
            if (_is_narrator || _foc_is_particle) return;
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
        var _theater_ui_vis = (theater_ui_timer > 0 || theater_paused);

        // Theater Mode Controls
        if (mouse_check_button_pressed(mb_left)) {
            focused_block = -1;
            selection_start = 0; selection_end = 0;
            // EXIT Button (Bottom Right) — only when visible
            if (_theater_ui_vis && _mx > 1280 - 200 && _mx < 1280 - 20 && _my > 860 && _my < 910) {
                stop_playback();
                theater_mode = false;
                theater_paused = false;
                return;
            }
            // PLAY/PAUSE Button (Bottom Left) — only when visible
            if (_theater_ui_vis && _mx > 30 && _mx < 150 && _my > 860 && _my < 910) {
                if (playing_block_index == -1) {
                    play_from_index(0);
                    theater_paused = false;
                    theater_ui_timer = 0; // hide controls immediately
                } else {
                    theater_paused = !theater_paused;
                    if (theater_paused) {
                        theater_was_mid_speech = is_speaking;
                        audio_stop_all(); tts_stop(); is_speaking = false;
                    } else {
                        // Resume: replay if we were mid-speech, otherwise advance immediately
                        speaking_pause_timer = theater_was_mid_speech ? -1 : 0;
                        theater_ui_timer = 0; // hide controls immediately
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
        var _idx = (focused_block != -1) ? focused_block + 1 : array_length(script_blocks);
        array_insert(script_blocks, _idx, {
            type: "voice", char_index: selected_character_index, text: "", height: 115, caret_pos: 0, selection_anchor: 0, selection_active: false,
            voice_id: _c.voice_id, pitch: _c.pitch, speed: _c.speed, mode: _c.mode, style: _c.style, glottal: _c[$ "glottal"] ?? -1, tweaked: _c.tweaked, is_altered: false
        });
        script_dirty = true;
        update_block_height(_idx);
        focused_block = _idx; keyboard_string = "";
        scene_edit_mode = false;

        // Scroll to show the spliced block — place it ~1/3 down from the top of the viewport
        var _block_y = 0;
        for (var k = 0; k < _idx; k++) _block_y += script_blocks[k].height + 20;
        block_scroll_y = min(0, -(_block_y - box_h / 3));
        update_preview_actors_for_block(_idx, true);
        return;
    }

    // ADD ACTION Button (Now also inserts at focused point)
    if (!is_speaking && playing_block_index == -1 && _mx > btn_add_action_x && _mx < btn_add_action_x + btn_add_action_w && _my > btn_add_action_y && _my < btn_add_action_y + btn_add_action_h) {
        selection_start = 0; selection_end = 0;
        {
            action_modal_open = true;
            action_modal_target_index = (focused_block != -1) ? focused_block + 1 : -1;
            action_modal_selected_idx = -1;
            action_modal_locked = false;
            
            // Calculate onstage/injured context for the selected character
            var _is_onstage       = false;
            var _is_knocked_down  = false;
            var _is_decapitated   = false;
            var _limit = (action_modal_target_index == -1) ? array_length(script_blocks) : action_modal_target_index;
            for (var k = 0; k < _limit; k++) {
                var _b = script_blocks[k];
                if (variable_struct_exists(_b, "type")) {
                    if (_b.type == "scene") {
                        _is_onstage      = false;
                        _is_knocked_down = false;
                        _is_decapitated  = false;
                        if (variable_struct_exists(_b, "actors")) {
                            for (var a = 0; a < array_length(_b.actors); a++) {
                                if (_b.actors[a].char_index == selected_character_index) {
                                    _is_onstage = true;
                                    _is_knocked_down = variable_struct_exists(_b.actors[a], "is_knocked_down") && _b.actors[a].is_knocked_down;
                                    _is_decapitated  = variable_struct_exists(_b.actors[a], "is_decapitated")  && _b.actors[a].is_decapitated;
                                    break;
                                }
                            }
                        }
                    } else if (_b.type == "action" && _b.char_index == selected_character_index) {
                        var _aname = string_lower(_b.action_name);
                        if (string_pos("enter", _aname) > 0)            { _is_onstage = true; }
                        else if (string_pos("exit", _aname) > 0)        { _is_onstage = false; }
                        else if (string_pos("disappears", _aname) > 0)  { _is_onstage = false; }
                        else if (variable_struct_exists(_b, "injure_style")) {
                            if (_b.injure_style == "knock_down")  _is_knocked_down = true;
                            else if (_b.injure_style == "decapitate") _is_decapitated = true;
                        }
                        else if (string_pos("stands up", _aname) > 0)   { _is_knocked_down = false; }
                        else if (string_pos("reforms", _aname) > 0)  { _is_decapitated = false; }
                    }
                }
            }
            action_modal_char_onstage        = _is_onstage;
            action_modal_char_is_knocked_down = _is_knocked_down;
            action_modal_char_is_decapitated  = _is_decapitated;
            action_modal_char_is_injured      = _is_knocked_down || _is_decapitated;
            
            scene_edit_mode = false;
        }
        return;
    }

    // ADD SCENE Button (Now also inserts at focused point)
    if (!is_speaking && playing_block_index == -1 && _mx > btn_add_scene_x && _mx < btn_add_scene_x + btn_add_scene_w && _my > btn_add_scene_y && _my < btn_add_scene_y + btn_add_scene_h) {
        selection_start = 0; selection_end = 0;
        scene_modal_open = true;
        scene_modal_search = ""; scene_modal_search_focused = false; scene_modal_scroll_y = 0; scene_modal_bksp_held = 0;
        scene_modal_filtered = []; for (var _sfi = 0; _sfi < array_length(all_scenes); _sfi++) array_push(scene_modal_filtered, all_scenes[_sfi]);
        scene_modal_target_index = (focused_block != -1) ? focused_block + 1 : -1;
        scene_edit_mode = false;
        return;
    }

    // EDIT VOICE Button
    _overlay_active = (scene_modal_open || action_modal_open || theater_mode || move_modal_open || pose_modal_open || expression_modal_open || pose_expr_modal_open);
    var _voice_foc_particle = particle_edit_mode || (insertion_idx == -1 && focused_block != -1 && focused_block < array_length(script_blocks) && variable_struct_exists(script_blocks[focused_block], "type") && script_blocks[focused_block].type == "particle");
    if (!script_expanded && !_overlay_active && !is_speaking && !_voice_foc_particle && playing_block_index == -1 && _mx > btn_edit_x && _mx < btn_edit_x + btn_edit_w && _my > btn_edit_y && _my < btn_edit_y + btn_edit_h) {
        focused_block = -1;
        selection_start = 0; selection_end = 0;
        edit_mode = true;
        modal_is_local_edit = false;
        scene_edit_mode = false; // Exit edit mode on edit voice
        var _c = characters[selected_character_index];
        modal_voice_id = _c.voice_id; modal_pitch = _c.pitch; modal_speed = _c.speed;
        modal_effort = _c.mode; modal_quality = _c.style; modal_glottal = _c[$ "glottal"] ?? -1; modal_volume = _c[$ "volume"] ?? 50; tweak_enabled = _c.tweaked;
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
            var _is_scene    = (variable_struct_exists(_block, "type") && _block.type == "scene");
            var _is_action   = (variable_struct_exists(_block, "type") && _block.type == "action");
            var _is_particle = (variable_struct_exists(_block, "type") && _block.type == "particle");
            var _is_voice    = !_is_scene && !_is_action && !_is_particle;
            var _box_y = (_is_scene || _is_action || _is_particle) ? _cy + 5 : _cy + 20;

            var _edit_lbl = "";
            var _edit_w = 0;
            var _show_edit_btn = false;

            if (_is_scene) {
                _edit_lbl = "CHANGE SCENE";
                _edit_w = 110;
                _show_edit_btn = true;
            } else if (_is_particle) {
                _show_edit_btn = false;
            } else if (_is_voice) {
                _edit_lbl = "ALTER VOICE";
                _edit_w = 105;
                _show_edit_btn = true;
            } else if (_is_action) {
                var _aname_u = string_upper(_block.action_name);
                var _aname_lo = string_lower(_block.action_name);
                
                var _is_sfx = (string_pos("PLAY SFX", _aname_u) > 0);
                var _is_title = (string_pos("DISPLAY TITLE", _aname_u) > 0);
                var _is_wait = (string_pos("WAIT", _aname_u) > 0);
                var _is_quake = variable_struct_exists(_block, "quake_intensity") || (string_pos("QUAKE", _aname_u) > 0);
                var _is_disappear = (string_pos("DISAPPEARS", _aname_u) > 0);
                var _is_jitter = (_aname_u == "JITTERS");
                var _is_injure2    = variable_struct_exists(_block, "injure_style");
                var _is_stand_up2  = (string_pos("STANDS UP", _aname_u) > 0);
                var _is_turn_around = (string_pos("TURNS AROUND", _aname_u) > 0);
                
                var _is_canned = (variable_struct_exists(_block, "char_index") && _block.char_index > 0 && canned_anim_find(_block.char_index, _block.action_name) != undefined);
                
                var _is_move = (string_pos("MOVE", _aname_u) > 0 || string_pos("ENTER", _aname_u) > 0 || string_pos("EXIT", _aname_u) > 0);
                var _has_looks = (string_pos("looks ", _aname_lo) > 0);
                var _has_and_pose = (_has_looks && string_pos("and pose ", _aname_lo) > 0);
                var _is_expr_only = (string_pos("expression:", _aname_lo) > 0) || (_has_looks && !_has_and_pose);
                var _is_pose = (!_is_expr_only) && (string_pos("poses ", _aname_lo) > 0 || _has_and_pose
                                    || (string_pos("pose ", _aname_lo) > 0 && string_pos("poses ", _aname_lo) == 0 && !_has_looks));
                
                if (_is_turn_around) {
                    _show_edit_btn = false;
                } else {
                    _show_edit_btn = true;
                    if (_is_sfx) {
                        _edit_lbl = "CHANGE SOUND";
                        _edit_w = 110;
                    } else if (_is_title) {
                        _edit_lbl = "CHANGE TITLE";
                        _edit_w = 110;
                    } else if (_is_wait) {
                        _edit_lbl = "EDIT TIMER";
                        _edit_w = 95;
                    } else if (_is_quake) {
                        _edit_lbl = "EDIT QUAKE";
                        _edit_w = 95;
                    } else if (_is_disappear) {
                        _edit_lbl = "EDIT DISAPPEAR METHOD";
                        _edit_w = 195;
                    } else if (_is_jitter) {
                        _edit_lbl = "EDIT JITTER";
                        _edit_w = 105;
                    } else if (_is_injure2) {
                        _edit_lbl = "EDIT INJURY";
                        _edit_w = 120;
                    } else if (_is_stand_up2) {
                        _edit_lbl = "EDIT STAND UP";
                        _edit_w = 120;
                    } else if (_is_canned) {
                        _edit_lbl = "EDIT SPECIAL ANIMATION";
                        _edit_w = 205;
                    } else if (_is_move) {
                        _edit_lbl = "EDIT MOVEMENT";
                        _edit_w = 125;
                    } else if (_is_pose || _is_expr_only) {
                        _edit_lbl = "EDIT POSE/EXPR";
                        _edit_w = 125;
                    } else {
                        _edit_lbl = "EDIT ACTION";
                        _edit_w = 105;
                    }
                }
            }
            var _edit_btn_h = 22;
            var _edit_btn_x = box_x + box_w - 45 - _edit_w;
            var _edit_btn_y = (_is_voice) ? _cy - 4 : _box_y;
            
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
                if (particle_edit_mode && particle_edit_block_idx == i) {
                    particle_edit_mode = false; particle_drag_pos = false; particle_drag_dir = false;
                    particle_drag_area_w = false; particle_drag_area_h = false;
                }
                array_delete(script_blocks, i, 1);
                script_dirty = true;
                if (particle_edit_mode && particle_edit_block_idx > i) particle_edit_block_idx--;
                update_all_block_heights();
                if (focused_block >= array_length(script_blocks)) focused_block = array_length(script_blocks) - 1;
                return;
            }

            // --- 4c. RESEQUENCE BUTTONS (LEFT STACK) ---
            var _lx = box_x + 10;
            // UP
            if (playing_block_index == -1 && _mx > _lx && _mx < _lx + _bw && _my > _box_y + 8 && _my < _box_y + 8 + _btn_h) {
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
            // TOP-RIGHT EDIT BUTTON CLICK
            else if (_show_edit_btn && playing_block_index == -1 && _mx > _edit_btn_x && _mx < _edit_btn_x + _edit_w && _my > _edit_btn_y && _my < _edit_btn_y + _edit_btn_h) {
                if (variable_struct_exists(_block, "type") && _block.type == "particle") {
                    if (script_expanded) script_expanded = false;
                    particle_edit_mode = true; particle_edit_block_idx = i; return;
                }
                else if (_is_scene) {
                    scene_modal_open = true;
                    scene_modal_search = ""; scene_modal_search_focused = false; scene_modal_scroll_y = 0; scene_modal_bksp_held = 0;
                    scene_modal_filtered = []; for (var _sfi = 0; _sfi < array_length(all_scenes); _sfi++) array_push(scene_modal_filtered, all_scenes[_sfi]);
                    scene_modal_target_index = i;
                    scene_modal_edit_mode = true;
                }
                else if (_is_action && (string_pos("WAIT", string_upper(_block.action_name)) > 0 || string_pos("PLAY SFX", string_upper(_block.action_name)) > 0 || string_pos("DISPLAY TITLE", string_upper(_block.action_name)) > 0 || string_pos("DISAPPEARS", string_upper(_block.action_name)) > 0 || variable_struct_exists(_block, "injure_style") || variable_struct_exists(_block, "jitter_intensity") || variable_struct_exists(_block, "quake_intensity") || string_pos("STANDS UP", string_upper(_block.action_name)) > 0)) {
                    action_modal_open = true;
                    action_modal_target_index = i;
                    action_modal_edit_mode = true;
                    if (variable_struct_exists(_block, "char_index") && _block.char_index > 0) {
                        selected_character_index = _block.char_index;
                    }

                    var _is_wait       = string_pos("WAIT",          string_upper(_block.action_name)) > 0;
                    var _is_title      = string_pos("DISPLAY TITLE", string_upper(_block.action_name)) > 0;
                    var _is_disappear  = string_pos("DISAPPEARS",    string_upper(_block.action_name)) > 0;
                    var _is_jitter     = variable_struct_exists(_block, "jitter_intensity");
                    var _is_quake      = variable_struct_exists(_block, "quake_intensity");
                    var _is_injure     = variable_struct_exists(_block, "injure_style");
                    var _is_stand_up   = string_pos("STANDS UP",     string_upper(_block.action_name)) > 0;
                    if (_is_wait || _is_title) action_modal_wait_duration = variable_struct_exists(_block, "duration") ? _block.duration : 1.0;

                    if (_is_title) {
                        action_modal_title_text = variable_struct_exists(_block, "title_text") ? _block.title_text : "";
                        action_modal_title_caret = string_length(action_modal_title_text);
                        action_modal_title_sel_start = 0; action_modal_title_sel_end = 0;
                        action_modal_title_align = variable_struct_exists(_block, "title_align") ? _block.title_align : 1;
                        action_modal_title_font = variable_struct_exists(_block, "title_font") ? _block.title_font : 0;
                        action_modal_title_size = variable_struct_exists(_block, "title_size") ? _block.title_size : 1;
                        action_modal_title_color = variable_struct_exists(_block, "title_color") ? _block.title_color : 0;
                        action_modal_dropdown_open = "";
                        keyboard_string = "";
                    }

                    // Automatically find and select the action in the modal list
                    for (var j = 0; j < array_length(all_actions); j++) {
                        if ((_is_wait && all_actions[j].name == "wait")
                         || (_is_title && all_actions[j].name == "display title")
                         || (_is_disappear && all_actions[j].name == "disappear")
                         || (_is_jitter && all_actions[j].name == "jitter")
                         || (_is_quake && all_actions[j].name == "quake")
                         || (_is_injure && all_actions[j].name == "injure")
                         || (_is_stand_up && all_actions[j].name == "stand up")
                         || (!_is_wait && !_is_title && !_is_disappear && !_is_jitter && !_is_quake && !_is_injure && !_is_stand_up && all_actions[j].name == "play sfx")) {
                            action_modal_selected_idx = j;
                            action_modal_locked = true;
                            break;
                        }
                    }
                    if (_is_quake) {
                        action_modal_quake_intensity = variable_struct_exists(_block, "quake_intensity") ? _block.quake_intensity : 3;
                        action_modal_quake_duration  = variable_struct_exists(_block, "quake_duration")  ? _block.quake_duration  : 1.0;
                        action_modal_quake_direction = variable_struct_exists(_block, "quake_direction") ? _block.quake_direction : "omni";
                    }
                    if (_is_jitter) {
                        action_modal_jitter_intensity = variable_struct_exists(_block, "jitter_intensity") ? _block.jitter_intensity : 3;
                        action_modal_jitter_duration  = variable_struct_exists(_block, "jitter_duration")  ? _block.jitter_duration  : 1.0;
                        action_modal_jitter_direction = variable_struct_exists(_block, "jitter_direction") ? _block.jitter_direction : "omni";
                        action_modal_char_onstage = true;
                    }
                    if (_is_disappear) {
                        action_modal_disappear_style = variable_struct_exists(_block, "disappear_style") ? _block.disappear_style : "pop";
                        action_modal_disappear_speed = variable_struct_exists(_block, "disappear_speed") ? _block.disappear_speed : 2;
                        action_modal_char_onstage = true;
                    }
                    if (_is_injure) {
                        action_modal_injure_style    = variable_struct_exists(_block, "injure_style")    ? _block.injure_style    : "knock_down";
                        action_modal_knock_direction = variable_struct_exists(_block, "knock_direction") ? _block.knock_direction : "forwards";
                        action_modal_decap_mode      = variable_struct_exists(_block, "decap_mode")      ? _block.decap_mode      : "remove_head";
                        action_modal_injure_speed    = variable_struct_exists(_block, "injure_speed")    ? _block.injure_speed    : 2;
                        action_modal_char_onstage    = true;
                        action_modal_char_is_injured = false;
                    }
                    if (_is_stand_up) {
                        action_modal_standup_speed        = variable_struct_exists(_block, "standup_speed") ? _block.standup_speed : 2;
                        action_modal_char_onstage         = true;
                        action_modal_char_is_knocked_down = true;
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
                        move_modal_temp_moonwalk    = (variable_struct_exists(_block, "moonwalk") && _block.moonwalk) || (string_pos("[moonwalk]", string_lower(_block.action_name)) > 0);
                        move_modal_temp_trick       = variable_struct_exists(_block, "trick")       ? _block.trick       : "none";
                        move_modal_temp_trick_count = variable_struct_exists(_block, "trick_count") ? _block.trick_count : 1;
                        // Capture start position (before this block) for drag facing updates
                        update_preview_actors_for_block(i, false);
                        move_modal_start_x = 0;
                        for (var _paj_sx = 0; _paj_sx < array_length(preview_actors); _paj_sx++) {
                            if (preview_actors[_paj_sx].char_index == _block.char_index) { move_modal_start_x = preview_actors[_paj_sx].x; break; }
                        }
                        var _blk_cur_scale = 1.0;
                        if (variable_struct_exists(_block, "target_scale")) {
                            update_preview_actors_for_block(i, false);
                            for (var _paj = 0; _paj < array_length(preview_actors); _paj++) {
                                if (preview_actors[_paj].char_index == _block.char_index) { _blk_cur_scale = preview_actors[_paj][$ "scale"] ?? 1.0; break; }
                            }
                            update_preview_actors_for_block(i, true);
                        } else {
                            for (var _paj = 0; _paj < array_length(preview_actors); _paj++) {
                                if (preview_actors[_paj].char_index == _block.char_index) { _blk_cur_scale = preview_actors[_paj][$ "scale"] ?? 1.0; break; }
                            }
                        }
                        move_modal_start_scale       = _blk_cur_scale;
                        move_modal_temp_target_scale = variable_struct_exists(_block, "target_scale") ? _block.target_scale : _blk_cur_scale;
                        move_modal_temp_target_x     = variable_struct_exists(_block, "target_x") ? _block.target_x : 0;
                        move_modal_temp_target_y     = variable_struct_exists(_block, "target_y") ? _block.target_y : (scene_win_h * 0.8);
                        move_modal_dragging          = false;
                        move_modal_temp_speed_index  = 2;
                        var _blk_spd_arr = (abs(move_modal_temp_target_scale - _blk_cur_scale) > 0.01) ? move_speeds_scaled : move_speeds;
                        for (var j = 0; j < array_length(_blk_spd_arr); j++) {
                            if (abs(_blk_spd_arr[j] - _blk_spd) < 0.01) { move_modal_temp_speed_index = j; break; }
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
                    } else if (variable_struct_exists(_block, "char_index") && _block.char_index > 0
                            && canned_anim_find(_block.char_index, _block.action_name) != undefined) {
                        action_modal_open = true; action_modal_target_index = i; action_modal_edit_mode = true;
                        action_modal_char_onstage = true; action_modal_char_is_injured = false;
                        action_modal_selected_anim_idx = -1; action_modal_sa_scroll = 0;
                        for (var _cj2 = 0; _cj2 < array_length(all_actions); _cj2++) {
                            if (all_actions[_cj2].name == "special animation") { action_modal_selected_idx = _cj2; action_modal_locked = true; break; }
                        }
                        var _cad2 = canned_anim_get_data(_block.char_index);
                        if (_cad2 != undefined) {
                            var _cn2 = string_lower(_block.action_name);
                            for (var _ci2 = 0; _ci2 < array_length(_cad2); _ci2++) {
                                if (string_lower(_cad2[_ci2].name) == _cn2) { action_modal_selected_anim_idx = _ci2; action_modal_sa_scroll = max(0, _ci2 - 3); break; }
                            }
                        }
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
                    modal_glottal = _block[$ "glottal"] ?? -1;
                    modal_volume = _block[$ "volume"] ?? 50;
                    tweak_enabled = _block.tweaked;
                }
                return;
            }
            // DOWN
            else if (playing_block_index == -1 && _mx > _lx && _mx < _lx + _bw && _my > _box_y + 38 && _my < _box_y + 38 + _btn_h) {
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

            if (_is_particle) {
                // Particle block click → toggle edit mode; splice point is AFTER the particle block
                if (playing_block_index == -1 && _mx > box_x + 45 && _mx < box_x + box_w - 45 && _my > _box_y && _my < _box_y + 80) {
                    if (focused_block == i && particle_edit_mode) {
                        focused_block = -1;
                        particle_edit_mode = false;
                        particle_drag_pos  = false;
                        particle_drag_dir  = false;
                    } else {
                        focused_block = i;
                        if (script_expanded) script_expanded = false;
                        particle_edit_mode      = true;
                        particle_edit_block_idx = i;
                        scene_edit_mode         = false;
                    }
                    return;
                }
            } else if (_is_scene) {
                // Scene Box Click — toggles staging; splice point is AFTER the scene block
                if (playing_block_index == -1 && _mx > box_x + 45 && _mx < box_x + box_w - 45 && _my > _box_y && _my < _box_y + 80) {
                    if (focused_block == i && scene_edit_mode) {
                        scene_edit_mode = false;
                    } else {
                        focused_block = i;
                        particle_edit_mode = false;
                        scene_edit_mode = true;
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
                if (playing_block_index == -1 && _mx > box_x + 45 && _mx < box_x + box_w - 45 && _my > _box_y && _my < _cy + _bh) {
                    var _is_dbl = (block_last_click_idx == i && current_time - block_last_click_time < 380);
                    block_last_click_idx  = i;
                    block_last_click_time = current_time;

                    if (_is_dbl && playing_block_index == -1) {
                        // Double-click: mirror the pencil button — open the appropriate edit UI for this block
                        if (_is_action) {
                            var _dbl_aname_u  = string_upper(_block.action_name);
                            var _dbl_aname_lo = string_lower(_block.action_name);
                            var _dbl_is_move  = (string_pos("MOVE", _dbl_aname_u) > 0 || string_pos("ENTER", _dbl_aname_u) > 0 || string_pos("EXIT", _dbl_aname_u) > 0);
                            var _dbl_has_looks    = (string_pos("looks ", _dbl_aname_lo) > 0);
                            var _dbl_has_and_pose = (_dbl_has_looks && string_pos("and pose ", _dbl_aname_lo) > 0);
                            var _dbl_is_expr_only = (string_pos("expression:", _dbl_aname_lo) > 0) || (_dbl_has_looks && !_dbl_has_and_pose);
                            var _dbl_is_pose      = (!_dbl_is_expr_only) && (string_pos("poses ", _dbl_aname_lo) > 0 || _dbl_has_and_pose
                                                    || (string_pos("pose ", _dbl_aname_lo) > 0 && string_pos("poses ", _dbl_aname_lo) == 0 && !_dbl_has_looks));
                            var _dbl_is_injure    = variable_struct_exists(_block, "injure_style");
                            var _dbl_is_stand_up  = (string_pos("STANDS UP", _dbl_aname_u) > 0);
                            var _dbl_is_jitter    = (_dbl_aname_u == "JITTERS");
                            var _dbl_is_quake     = variable_struct_exists(_block, "quake_intensity");
                            var _dbl_is_gen = (string_pos("WAIT", _dbl_aname_u) > 0 || string_pos("PLAY SFX", _dbl_aname_u) > 0
                                           || string_pos("DISPLAY TITLE", _dbl_aname_u) > 0 || string_pos("DISAPPEARS", _dbl_aname_u) > 0
                                           || _dbl_is_injure || _dbl_is_stand_up || _dbl_is_jitter || _dbl_is_quake);

                            if (_dbl_is_move) {
                                move_modal_open = true; move_modal_target_index = i; move_modal_edit_mode = true;
                                var _dbl_spd = variable_struct_exists(_block, "speed") ? _block.speed : 1.9;
                                move_modal_temp_moonwalk    = (variable_struct_exists(_block, "moonwalk") && _block.moonwalk) || (string_pos("[moonwalk]", string_lower(_block.action_name)) > 0);
                                move_modal_temp_trick       = variable_struct_exists(_block, "trick") ? _block.trick : "none";
                                move_modal_temp_trick_count = variable_struct_exists(_block, "trick_count") ? _block.trick_count : 1;
                                var _dbl_cur_scale = 1.0;
                                if (variable_struct_exists(_block, "target_scale")) {
                                    update_preview_actors_for_block(i, false);
                                    for (var _paj2 = 0; _paj2 < array_length(preview_actors); _paj2++) {
                                        if (preview_actors[_paj2].char_index == _block.char_index) { _dbl_cur_scale = preview_actors[_paj2][$ "scale"] ?? 1.0; break; }
                                    }
                                    update_preview_actors_for_block(i, true);
                                } else {
                                    for (var _paj2 = 0; _paj2 < array_length(preview_actors); _paj2++) {
                                        if (preview_actors[_paj2].char_index == _block.char_index) { _dbl_cur_scale = preview_actors[_paj2][$ "scale"] ?? 1.0; break; }
                                    }
                                }
                                move_modal_start_scale       = _dbl_cur_scale;
                                move_modal_temp_target_scale = variable_struct_exists(_block, "target_scale") ? _block.target_scale : _dbl_cur_scale;
                                move_modal_temp_speed_index  = 2;
                                var _dbl_spd_arr = (abs(move_modal_temp_target_scale - _dbl_cur_scale) > 0.01) ? move_speeds_scaled : move_speeds;
                                for (var _dj2 = 0; _dj2 < array_length(_dbl_spd_arr); _dj2++) {
                                    if (abs(_dbl_spd_arr[_dj2] - _dbl_spd) < 0.01) { move_modal_temp_speed_index = _dj2; break; }
                                }
                            } else if (_dbl_is_gen) {
                                action_modal_open = true; action_modal_target_index = i; action_modal_edit_mode = true;
                                var _aw2 = string_pos("WAIT", _dbl_aname_u) > 0;
                                var _at2 = string_pos("DISPLAY TITLE", _dbl_aname_u) > 0;
                                var _ad2 = string_pos("DISAPPEARS", _dbl_aname_u) > 0;
                                if (_aw2 || _at2) action_modal_wait_duration = variable_struct_exists(_block, "duration") ? _block.duration : 1.0;
                                if (_at2) {
                                    action_modal_title_text  = variable_struct_exists(_block, "title_text")  ? _block.title_text  : "";
                                    action_modal_title_caret = string_length(action_modal_title_text);
                                    action_modal_title_sel_start = 0; action_modal_title_sel_end = 0;
                                    action_modal_title_align = variable_struct_exists(_block, "title_align") ? _block.title_align : 1;
                                    action_modal_title_font  = variable_struct_exists(_block, "title_font")  ? _block.title_font  : 0;
                                    action_modal_title_size  = variable_struct_exists(_block, "title_size")  ? _block.title_size  : 1;
                                    action_modal_title_color = variable_struct_exists(_block, "title_color") ? _block.title_color : 0;
                                    action_modal_dropdown_open = ""; keyboard_string = "";
                                } else if (_dbl_is_quake) {
                                    action_modal_quake_intensity = variable_struct_exists(_block, "quake_intensity") ? _block.quake_intensity : 3;
                                    action_modal_quake_duration  = variable_struct_exists(_block, "quake_duration")  ? _block.quake_duration  : 1.0;
                                    action_modal_quake_direction = variable_struct_exists(_block, "quake_direction") ? _block.quake_direction : "omni";
                                } else if (_dbl_is_jitter) {
                                    action_modal_jitter_intensity = variable_struct_exists(_block, "jitter_intensity") ? _block.jitter_intensity : 3;
                                    action_modal_jitter_duration  = variable_struct_exists(_block, "jitter_duration")  ? _block.jitter_duration  : 1.0;
                                    action_modal_jitter_direction = variable_struct_exists(_block, "jitter_direction") ? _block.jitter_direction : "omni";
                                    action_modal_char_onstage = true;
                                } else if (_ad2) {
                                    action_modal_disappear_style = variable_struct_exists(_block, "disappear_style") ? _block.disappear_style : "pop";
                                    action_modal_disappear_speed = variable_struct_exists(_block, "disappear_speed") ? _block.disappear_speed : 2;
                                    action_modal_char_onstage = true;
                                } else if (_dbl_is_injure) {
                                    action_modal_injure_style    = variable_struct_exists(_block, "injure_style")    ? _block.injure_style    : "knock_down";
                                    action_modal_knock_direction = variable_struct_exists(_block, "knock_direction") ? _block.knock_direction : "forwards";
                                    action_modal_decap_mode      = variable_struct_exists(_block, "decap_mode")      ? _block.decap_mode      : "remove_head";
                                    action_modal_injure_speed    = variable_struct_exists(_block, "injure_speed")    ? _block.injure_speed    : 2;
                                    action_modal_char_onstage    = true; action_modal_char_is_injured = false;
                                } else if (_dbl_is_stand_up) {
                                    action_modal_standup_speed        = variable_struct_exists(_block, "standup_speed") ? _block.standup_speed : 2;
                                    action_modal_char_onstage         = true; action_modal_char_is_knocked_down = true;
                                }
                                for (var _dj = 0; _dj < array_length(all_actions); _dj++) {
                                    if ((_aw2 && all_actions[_dj].name == "wait") || (_at2 && all_actions[_dj].name == "display title")
                                     || (_ad2 && all_actions[_dj].name == "disappear")
                                     || (_dbl_is_jitter && all_actions[_dj].name == "jitter")
                                     || (_dbl_is_quake && all_actions[_dj].name == "quake")
                                     || (_dbl_is_injure && all_actions[_dj].name == "injure")
                                     || (_dbl_is_stand_up && all_actions[_dj].name == "stand up")
                                     || (!_aw2 && !_at2 && !_ad2 && !_dbl_is_jitter && !_dbl_is_quake && !_dbl_is_injure && !_dbl_is_stand_up && all_actions[_dj].name == "play sfx")) {
                                        action_modal_selected_idx = _dj; action_modal_locked = true; break;
                                    }
                                }
                                if (!_aw2 && !_at2 && !_ad2 && !_dbl_is_injure && !_dbl_is_stand_up) { refresh_sfx_folders(); action_modal_sfx_folder_idx = -1; action_modal_sfx_file_idx = -1; }
                            } else if (_dbl_is_pose || _dbl_is_expr_only) {
                                selected_character_index = _block.char_index;
                                pose_expr_modal_open = true;
                                expression_modal_edit_mode = true; expression_modal_target_index = i;
                                pose_expr_pose_touched = _dbl_is_pose; pose_expr_expr_touched = _dbl_is_expr_only;
                                var _dbl_e = 21; var _dbl_p = 1;
                                for (var _pa = 0; _pa < array_length(preview_actors); _pa++) {
                                    if (preview_actors[_pa].char_index == _block.char_index) {
                                        _dbl_e = variable_struct_exists(preview_actors[_pa], "expression") ? preview_actors[_pa].expression : 21;
                                        _dbl_p = variable_struct_exists(preview_actors[_pa], "pose")       ? preview_actors[_pa].pose       : 1;
                                        break;
                                    }
                                }
                                expression_modal_locked_expr = _dbl_e; expression_modal_temp_expr = _dbl_e;
                                pose_modal_locked_pose = _dbl_p; pose_modal_temp_pose = _dbl_p;
                            } else if (variable_struct_exists(_block, "char_index") && _block.char_index > 0
                                    && canned_anim_find(_block.char_index, _block.action_name) != undefined) {
                                action_modal_open = true; action_modal_target_index = i; action_modal_edit_mode = true;
                                action_modal_char_onstage = true; action_modal_char_is_injured = false;
                                action_modal_selected_anim_idx = -1; action_modal_sa_scroll = 0;
                                for (var _cj3 = 0; _cj3 < array_length(all_actions); _cj3++) {
                                    if (all_actions[_cj3].name == "special animation") { action_modal_selected_idx = _cj3; action_modal_locked = true; break; }
                                }
                                var _cad3 = canned_anim_get_data(_block.char_index);
                                if (_cad3 != undefined) {
                                    var _cn3 = string_lower(_block.action_name);
                                    for (var _ci3 = 0; _ci3 < array_length(_cad3); _ci3++) {
                                        if (string_lower(_cad3[_ci3].name) == _cn3) { action_modal_selected_anim_idx = _ci3; action_modal_sa_scroll = max(0, _ci3 - 3); break; }
                                    }
                                }
                            }
                        }
                        return;
                    }

                    if (_is_voice) {
                        // Voice block: clicking only handles text editing — does NOT change splice position
                        // (splice position for voice blocks set by clicking the gap below them)
                        if (focused_block == i) {
                            focused_block = -1;
                            scene_edit_mode = false;
                            is_selecting = false;
                        } else {
                            focused_block = i;
                            particle_edit_mode = false;

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

                            scene_edit_mode = false;

                            keyboard_string = "";
                            var _rx = _mx - (box_x + 60); var _ry = _my - (_cy + 32);
                            var _best_p = get_caret_at_pos(_block.text, _rx, _ry, _wrap_w, 28);
                            _block.caret_pos = _best_p;
                            selection_start = _best_p;
                            selection_end = _best_p;
                            is_selecting = true;
                        }
                    } else {
                        // Action block: clicking sets splice point AFTER block i
                        if (focused_block == i) {
                            focused_block = -1;
                            scene_edit_mode = false;
                        } else {
                            focused_block = i;
                            particle_edit_mode = false;

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

                            scene_edit_mode = false;
                        }
                    }
                    return;
                }
            }
            
            // Main Block Focus Click (fallback — most blocks handled above)
            if (playing_block_index == -1 && _mx > box_x + 45 && _mx < box_x + box_w - 45 && _my > _cy && _my < _cy + _bh) {
                var _splice_idx = i;
                if (focused_block == _splice_idx) {
                    focused_block = -1;
                    scene_edit_mode = false;
                    particle_edit_mode = false;
                } else {
                    focused_block = _splice_idx;
                    if (!_is_particle) particle_edit_mode = false;

                    if (variable_struct_exists(_block, "char_index")) {
                        selected_character_index = _block.char_index;
                        var _row = floor(selected_character_index / 2);
                        var _iy_scroll = _row * 135;
                        if (_iy_scroll + char_sel_scroll_y < 0) char_sel_scroll_y = -_iy_scroll;
                        else if (_iy_scroll + 135 + char_sel_scroll_y > char_sel_h - 35) char_sel_scroll_y = -( _iy_scroll - (char_sel_h - 170) );
                    }

                    selection_start = 0; selection_end = 0;
                    if (!_is_scene && !_is_action && !_is_particle) {
                        keyboard_string = "";
                        _block.caret_pos = string_length(_block.text);
                    }
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
                if (_b1_type == "other" || _b2_type == "other") { /* scene/unknown blocks never link */ }
                else if ((_b1_type == "move" && _b2_type == "voice") || (_b1_type == "voice" && _b2_type == "move")) _base_valid = true;
                else if ((_b1_type == "move" && (_b2_type == "sfx" || _b2_type == "quake")) || ((_b1_type == "sfx" || _b1_type == "quake") && _b2_type == "move")) _base_valid = true;
                else if ((_b1_type == "voice" && (_b2_type == "sfx" || _b2_type == "quake")) || ((_b1_type == "sfx" || _b1_type == "quake") && _b2_type == "voice")) _base_valid = true;
                else if ((_b1_type == "title" && (_b2_type == "sfx" || _b2_type == "quake")) || ((_b1_type == "sfx" || _b1_type == "quake") && _b2_type == "title")) _base_valid = true;
                else if ((_b1_type == "title" && _b2_type == "voice") || (_b1_type == "voice" && _b2_type == "title")) _base_valid = true;
                else if (_b1_type == "move" && _b2_type == "move" && _diff_char) _base_valid = true;
                else if (_b1_type == "voice" && _b2_type == "voice" && _diff_char) _base_valid = true;
                else if ((_b1_type == "sfx" && _b2_type == "quake") || (_b1_type == "quake" && _b2_type == "sfx")) _base_valid = true;
                else if ((_b1_type == "particle" || _b2_type == "particle") && _b1_type != "other" && _b2_type != "other") _base_valid = true;
                else if (_b1_type == "charaction" || _b2_type == "charaction") {
                    var _other_t = (_b1_type == "charaction") ? _b2_type : _b1_type;
                    if (_other_t == "voice" || _other_t == "sfx" || _other_t == "quake" || _other_t == "particle" || _other_t == "title") _base_valid = true;
                    else if ((_other_t == "move" || _other_t == "charaction") && _diff_char) _base_valid = true;
                }
                else if (_b1_type == "kill" || _b2_type == "kill") {
                    var _other_kt = (_b1_type == "kill") ? _b2_type : _b1_type;
                    if (_other_kt == "sfx" || _other_kt == "quake" || _other_kt == "particle") _base_valid = true;
                    else if (_diff_char) _base_valid = true;
                }
                else if (_b1_type == "jitter" || _b2_type == "jitter") {
                    var _other_jt = (_b1_type == "jitter") ? _b2_type : _b1_type;
                    if (_other_jt == "sfx" || _other_jt == "particle" || _other_jt == "title") _base_valid = true;
                    else if (_other_jt == "voice" || _other_jt == "move") _base_valid = true;
                    else if (_other_jt != "quake" && _diff_char) _base_valid = true;
                }
                else if (_b1_type == "canned" || _b2_type == "canned") {
                    var _other_ca = (_b1_type == "canned") ? _b2_type : _b1_type;
                    // Same-char: only movement is allowed alongside a special animation
                    if (_other_ca == "move" && !_diff_char) _base_valid = true;
                    // General actions are always fine
                    else if (_other_ca == "sfx" || _other_ca == "quake" || _other_ca == "particle" || _other_ca == "title") _base_valid = true;
                    // Different-character blocks are fine
                    else if (_diff_char && (_other_ca == "voice" || _other_ca == "move" || _other_ca == "charaction" || _other_ca == "canned")) _base_valid = true;
                }
                else if (_b1_type == "injure" || _b2_type == "injure") {
                    var _other_inj = (_b1_type == "injure") ? _b2_type : _b1_type;
                    if (_other_inj == "sfx" || _other_inj == "voice" || _other_inj == "quake" || _other_inj == "particle") _base_valid = true;
                    else if (_diff_char) _base_valid = true;
                }

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
                    var _particle_in_chain = 0;
                    var _quake_in_chain = 0;
                    for (var k = _start_idx; k <= _end_idx; k++) {
                        var _bk = script_blocks[k];
                        var _c_idx = real(variable_struct_exists(_bk, "char_index") ? _bk.char_index : 0);
                        var _bk_type = get_link_type(_bk);
                        if (_bk_type == "sfx")      _sfx_in_chain++;
                        if (_bk_type == "title")    _title_in_chain++;
                        if (_bk_type == "move")     _move_in_chain = true;
                        if (_bk_type == "particle") _particle_in_chain++;
                        if (_bk_type == "quake")    _quake_in_chain++;

                        if (_bk_type == "kill" || _bk_type == "jitter" || _bk_type == "voice" || _bk_type == "move" || _bk_type == "charaction" || _bk_type == "canned" || _bk_type == "injure") {
                            for (var j = k + 1; j <= _end_idx; j++) {
                                var _bj = script_blocks[j];
                                if (real(variable_struct_exists(_bj, "char_index") ? _bj.char_index : 0) == _c_idx) {
                                    var _bj_type = get_link_type(_bj);
                                    if (_bk_type == "kill"   && _bj_type != "sfx" && _bj_type != "particle" && _bj_type != "other") { _chain_valid = false; break; }
                                    if (_bj_type == "kill"   && _bk_type != "sfx" && _bk_type != "particle" && _bk_type != "other") { _chain_valid = false; break; }
                                    if (_bk_type == "jitter" && _bj_type == "jitter")    { _chain_valid = false; break; }
                                    if (_bk_type == "jitter" && _bj_type == "charaction") { _chain_valid = false; break; }
                                    if (_bk_type == "charaction" && _bj_type == "jitter") { _chain_valid = false; break; }
                                    if (_bk_type == "voice"  && _bj_type == "voice")     { _chain_valid = false; break; }
                                    if (_bk_type == "move"   && _bj_type == "move")      { _chain_valid = false; break; }
                                    if (_bk_type == "charaction" && (_bj_type == "charaction" || _bj_type == "move")) { _chain_valid = false; break; }
                                    if (_bk_type == "move"   && _bj_type == "charaction") { _chain_valid = false; break; }
                                    // Canned animation: same character cannot also talk, do other char-actions, or run another canned anim
                                    if (_bk_type == "canned" && (_bj_type == "voice" || _bj_type == "charaction" || _bj_type == "canned")) { _chain_valid = false; break; }
                                    if (_bj_type == "canned" && (_bk_type == "voice" || _bk_type == "charaction")) { _chain_valid = false; break; }
                                    // Injure: same character cannot also move, disappear, get another injury, or do a canned anim
                                    if (_bk_type == "injure" && (_bj_type == "injure" || _bj_type == "move" || _bj_type == "charaction" || _bj_type == "canned")) { _chain_valid = false; break; }
                                    if (_bj_type == "injure" && (_bk_type == "move" || _bk_type == "charaction" || _bk_type == "canned")) { _chain_valid = false; break; }
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
                    if (_particle_in_chain > 10) _chain_valid = false;
                    if (_quake_in_chain > 1) _chain_valid = false;
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
                        particle_edit_mode = false; particle_drag_pos = false; particle_drag_dir = false; particle_drag_area_w = false; particle_drag_area_h = false;
                    }
                    return;
                }

                // Gap click (outside the + button) sets the splice point after block i for all block types
                // This is the primary way to set splice position for voice blocks
                if (_my > _gap_y && _my < _gap_y + 20) {
                    focused_block = i;
                    scene_edit_mode = false;
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
}
