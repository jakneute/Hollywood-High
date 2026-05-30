/// @description Professional Editor UI Renderer (With Hover Effects)
var _mx = mouse_x; var _my = mouse_y;

var _overlay_active = (file_menu_open || dictionary_open || edit_mode || scene_modal_open || action_modal_open || move_modal_open || theater_mode || pose_modal_open || expression_modal_open || pose_expr_modal_open || expr_cfg_open);

draw_clear(make_color_rgb(45, 45, 55)); 

// --- LIVE TITLE RENDERING FUNCTION ---
var _render_live_titles = function() {
    if (playing_block_index != -1 && playing_block_index < array_length(script_blocks)) {
        var _pb = -1;
        var _end_idx = max(playing_block_index, playing_linked_index);
        for (var _i = playing_block_index; _i <= _end_idx; _i++) {
            if (_i < array_length(script_blocks)) {
                var _cb = script_blocks[_i];
                if (variable_struct_exists(_cb, "type") && _cb.type == "action" && string_pos("DISPLAY TITLE", string_upper(_cb.action_name)) > 0) {
                    _pb = _cb; break;
                }
            }
        }
        
        if (_pb != -1) {
            var _txt = variable_struct_exists(_pb, "title_text") ? _pb.title_text : "";
            if (_txt != "") {
                var _align = variable_struct_exists(_pb, "title_align") ? _pb.title_align : 1;
                var _font_idx = variable_struct_exists(_pb, "title_font") ? _pb.title_font : 0;
                var _size = variable_struct_exists(_pb, "title_size") ? _pb.title_size : 1;
                var _color_idx = variable_struct_exists(_pb, "title_color") ? _pb.title_color : 0;
                
                var _c = c_white;
                if (_color_idx == 1) _c = c_black; else if (_color_idx == 2) _c = c_red;
                else if (_color_idx == 3) _c = c_yellow; else if (_color_idx == 4) _c = c_blue;
                else if (_color_idx == 5) _c = c_green; else if (_color_idx == 6) _c = c_orange;
                else if (_color_idx == 7) _c = c_purple; else if (_color_idx == 8) _c = c_aqua;
                else if (_color_idx == 9) _c = c_fuchsia;

                var _scl = 2.0;
                if (_size == 0) _scl = 2.0; else if (_size == 1) _scl = 2.5; else if (_size == 2) _scl = 3.0;
                
                var _tx = 0; var _ty = 0;
                if (theater_mode) {
                    _scl *= 1.6;
                    _tx = 1280 / 2;
                    if (_align == 0) _ty = 80; else if (_align == 1) _ty = 405; else if (_align == 2) _ty = 730;
                } else {
                    _tx = scene_win_x + scene_win_w / 2;
                    if (_align == 0) _ty = scene_win_y + 40; else if (_align == 1) _ty = scene_win_y + scene_win_h / 2; else if (_align == 2) _ty = scene_win_y + scene_win_h - 40;
                }
                
                var _sel_font = -1;
                if (_font_idx >= 0 && _font_idx < array_length(action_modal_title_fonts)) _sel_font = action_modal_title_fonts[_font_idx];

                draw_set_halign(fa_center); 
                if (_align == 0) draw_set_valign(fa_top); else if (_align == 1) draw_set_valign(fa_middle); else if (_align == 2) draw_set_valign(fa_bottom);
                
                if (_sel_font != -1) draw_set_font(_sel_font);
                var _wrap_w = theater_mode ? (1100 / _scl) : ((scene_win_w - 60) / _scl);
                
                gpu_set_texfilter(false); draw_set_color(c_black); draw_set_alpha(0.5); draw_text_ext_transformed(_tx + 2*_scl, _ty + 2*_scl, _txt, -1, _wrap_w, _scl, _scl, 0);
                draw_set_alpha(1.0); draw_set_color(_c); draw_text_ext_transformed(_tx, _ty, _txt, -1, _wrap_w, _scl, _scl, 0); gpu_set_texfilter(false);
                draw_set_halign(fa_left); draw_set_valign(fa_top); if (_sel_font != -1) draw_set_font(-1);
            }
        }
    }
};

//// --- 3. THEATER MODE RENDERER ---
if (theater_mode) {
    draw_set_color(c_black);
    draw_rectangle(0, 0, 1280, 960, false);
    var _bg_sc = 1;
    var _mask_name = "";
    
    // Background & Clipping Setup (Fit-to-Screen with Subtitle Safety)
    var _max_theater_h = 810; // Threshold to avoid subtitles/controls
    var _stage_w = 1280;
    var _stage_h = _max_theater_h;
    var _stage_x = 0;
    var _stage_y = 0;
    
    if (current_scene_sprite != -1) {
        var _bw = sprite_get_width(current_scene_sprite);
        var _sh = sprite_get_height(current_scene_sprite);
        
        // Calculate scale to fit within 1280 x 810
        var _sc_w = 1280 / _bw;
        var _sc_h = _max_theater_h / _sh;
        _bg_sc = min(_sc_w, _sc_h); 
        
        _stage_w = _bw * _bg_sc;
        _stage_h = _sh * _bg_sc;
        
        // Centering within the 1280x810 area
        _stage_x = (1280 - _stage_w) / 2;
        _stage_y = (_max_theater_h - _stage_h) / 2;
        
        draw_sprite_ext(current_scene_sprite, 0, _stage_x, _stage_y, _bg_sc, _bg_sc, 0, c_white, 1);
    }
    
    // Actor Clipping (Clips exactly to the background area, clear of subtitles)
    gpu_set_scissor(_stage_x, _stage_y, _stage_w, _stage_h);
    
	var _scene_block = (active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) ? script_blocks[active_scene_block_idx] : -1;
	var _mask_sprite = -1;
	if (_scene_block != -1 && variable_struct_exists(_scene_block, "internal_name")) {
		_mask_name = _scene_block.internal_name + "_mask";
		_mask_sprite = get_scene_sprite(_mask_name);
	}

	var draw_theater_actors = function(_stg_w, _stg_h, _stg_x, _stg_y, target_surface = -1) {
		gpu_set_texfilter(false);
		for (var i = 0; i < array_length(preview_actors); i++) {
			var _act = preview_actors[i];
			var _pose  = variable_struct_exists(_act, "pose")       ? _act.pose       : 1;
			var _expr  = variable_struct_exists(_act, "expression") ? _act.expression : 21;
			var _aface = variable_struct_exists(_act, "facing")     ? _act.facing     : undefined;

			var _layers = get_composite_character_sprite(_act.char_index, _pose, _expr, _aface);
			var _spr    = _layers[0].spr;

			if (_spr != -1) {
				var _csh = sprite_get_height(_spr);
				var _csw = sprite_get_width(_spr);
				var _asc = (_stg_h * 1.5) / 450;

				var _ax = (_act.x / scene_win_w) * _stg_w;
				var _ay = (_act.y / scene_win_h) * _stg_h;

				var _y_off = variable_struct_exists(_act, "y_offset") ? (_act.y_offset / scene_win_h) * _stg_h : 0;

				var _draw_x = (target_surface == -1) ? (_stg_x + _ax - (_csw * _asc / 2)) : (_ax - (_csw * _asc / 2));
				var _draw_y = (target_surface == -1) ? (_stg_y + _ay - (_csh * _asc) + _y_off) : (_ay - (_csh * _asc) + _y_off);

				var _char_is_speaking = false;
				if (playing_block_index != -1 && is_speaking) {
                    var _end_idx = max(playing_block_index, playing_linked_index);
                    for (var _pi = playing_block_index; _pi <= _end_idx; _pi++) {
                        if (_pi < array_length(script_blocks)) {
                            var _cb = script_blocks[_pi];
                            if ((!variable_struct_exists(_cb, "type") || _cb.type == "voice") && real(_cb.char_index) == real(_act.char_index)) {
                                var _creq = variable_struct_exists(_cb, "tts_req") ? _cb.tts_req : -1;
                                for (var _ri = 0; _ri < array_length(active_requests); _ri++) {
                                    if (active_requests[_ri] == _creq) { _char_is_speaking = true; break; }
                                }
                                break;
                            }
                        }
                    }
				}

				var _mouth_anim = _char_is_speaking ? get_mouth_anim_sprites(_act.char_index, _pose, _expr, _aface) : [];
				var _has_manim  = array_length(_mouth_anim) > 0;
				var _manim_fi   = 0;
				var _mouth_open = false;
				if (_has_manim && playing_block_index >= 0 && playing_block_index < array_length(script_blocks)) {
					var _spk_b     = script_blocks[playing_block_index];
					var _spk_speed = variable_struct_exists(_spk_b, "speed") ? _spk_b.speed : 50;
					var _mouth_ms  = max(100, 300 - _spk_speed * 2);
					if (array_length(current_viseme_data) > 0) {
						// Time-based progress: elapsed ms vs SAPI5 total scaled for TalkIt speed.
						// Falls back to CPS character position if duration file not yet received.
						var _prog;
						if (current_viseme_total_ms > 0 && speak_start_time_ms >= 0) {
							var _t_speed_val = max(1, 50 + _spk_speed * 2.5);
							var _adj_dur = current_viseme_total_ms * (175.0 / _t_speed_val);
							_prog = clamp((current_time - speak_start_time_ms) / max(1, _adj_dur), 0, 2);
						} else {
							var _txt_len = variable_struct_exists(_spk_b, "text") ? max(1, string_length(_spk_b.text)) : 1;
							_prog = speaking_index / _txt_len;
						}
						if (_prog >= 0.95) {
							_mouth_open = true;
							_manim_fi = floor(current_time / _mouth_ms) mod array_length(_mouth_anim);
						} else {
							var _cur_v = 0;
							for (var _vi = 0; _vi < array_length(current_viseme_data); _vi++) {
								if (current_viseme_data[_vi].t <= _prog) _cur_v = current_viseme_data[_vi].v; else break;
							}
							// Coast through SAPI5 inter-sentence silences — hold the last open
							// shape for up to 300 ms so the mouth doesn't snap closed between sentences.
							if (_cur_v != 0) {
								mouth_last_vis_time_ms = current_time; mouth_last_vis_value = _cur_v;
							} else if (mouth_last_vis_time_ms >= 0 && current_time - mouth_last_vis_time_ms < 300) {
								_cur_v = mouth_last_vis_value;
							}
							_mouth_open = (_cur_v != 0);
							if (_mouth_open) {
								// Map SAPI5 viseme (0-21) to jaw openness: 0=closed,1=small,2=open,3=wide
								var _vg = [0,2,3,2,1,1,1,1,1,2,1,2,1,1,0,0,1,0,0,0,1,0];
								_manim_fi = clamp(_vg[clamp(_cur_v, 0, 21)], 0, array_length(_mouth_anim) - 1);
							}
						}
					} else if (speaking_has_progress) {
						_mouth_open = true;
						_manim_fi = floor(current_time / _mouth_ms) mod array_length(_mouth_anim);
					}
				}
				var _final_layers = [];
				for (var _li = 0; _li < array_length(_layers); _li++) {
					var _l       = _layers[_li];
					var _is_anim = variable_struct_exists(_l, "is_mouth") && _has_manim && _mouth_open;
					var _ae      = _is_anim ? _mouth_anim[_manim_fi] : undefined;
					var _lspr    = _is_anim ? _ae.spr : _l.spr;
					var _ldx     = _l.dx + (_is_anim ? _ae.dx : 0);
					var _ldy     = _l.dy + (_is_anim ? _ae.dy : 0);
					array_push(_final_layers, { spr: _lspr, dx: _ldx, dy: _ldy });
				}
				var _clip = (target_surface == -1) ? [_stg_x, _stg_y, _stg_w, _stg_h] : undefined;
				draw_composite_character_ext(_final_layers, _draw_x, _draw_y, _asc, 1, c_white, false, 3, c_yellow, _clip);
				// Restore scissor clip for subsequent actors (since surface target switches clear it in GameMaker)
				if (target_surface == -1) {
					gpu_set_scissor(_stg_x, _stg_y, _stg_w, _stg_h);
				}

			}
		}
		gpu_set_texfilter(false);
	}

	if (_mask_sprite != -1) {
		// --- Masked Drawing using Surfaces ---
		if (!surface_exists(o_char_surface) || surface_get_width(o_char_surface) != _stage_w || surface_get_height(o_char_surface) != _stage_h) {
			if (surface_exists(o_char_surface)) surface_free(o_char_surface);
			o_char_surface = surface_create(_stage_w, _stage_h);
		}
		surface_set_target(o_char_surface);
		draw_clear_alpha(c_black, 0);
		draw_theater_actors(_stage_w, _stage_h, _stage_x, _stage_y, o_char_surface);
		surface_reset_target();

		if (!surface_exists(o_mask_surface) || surface_get_width(o_mask_surface) != _stage_w || surface_get_height(o_mask_surface) != _stage_h) {
			if (surface_exists(o_mask_surface)) surface_free(o_mask_surface);
			o_mask_surface = surface_create(_stage_w, _stage_h);
		}
		surface_set_target(o_mask_surface);
		draw_clear_alpha(c_black, 0);
		
		draw_sprite_ext(_mask_sprite, 0, 0, 0, _bg_sc, _bg_sc, 0, c_white, 1);
		
		surface_reset_target();

		surface_set_target(o_char_surface);
		gpu_set_blendmode_ext(bm_zero, bm_inv_src_alpha);
		draw_surface(o_mask_surface, 0, 0);
		gpu_set_blendmode(bm_normal);
		surface_reset_target();

		draw_surface(o_char_surface, _stage_x, _stage_y);
		
		// Draw the visual mask (unshifted)
		draw_sprite_ext(_mask_sprite, 0, _stage_x, _stage_y, _bg_sc, _bg_sc, 0, c_white, 1);

	} else {
		// --- Unmasked Drawing ---
		draw_theater_actors(_stage_w, _stage_h, _stage_x, _stage_y);
	}
    
    gpu_set_scissor(0, 0, 1280, 960); // Reset clipping
    
    // Subtitles (Narrower to avoid Play/Exit buttons)
    if (theater_subtitles != "") {
        draw_set_alpha(0.7); draw_set_color(c_black);
        // Expanded to 960 (bottom of screen) to ensure 3 full lines (32px * 3 = 96px) fit
        draw_rectangle(180, 820, 1100, 960, false); 
        draw_set_alpha(1.0);
        
        draw_set_color(c_yellow);
        var _name = (theater_active_char != -1) ? string_upper(characters[theater_active_char].name) : "";
        if (theater_active_char != -1 && playing_block_index != -1) {
            var _pb = -1;
            var _end_idx = max(playing_block_index, playing_linked_index);
            for (var _i = playing_block_index; _i <= _end_idx; _i++) {
                if (_i < array_length(script_blocks)) {
                    var _cb = script_blocks[_i];
                    if ((!variable_struct_exists(_cb, "type") || _cb.type == "voice") && real(_cb.char_index) == real(theater_active_char)) {
                        _pb = _cb; break;
                    }
                }
            }
            if (_pb != -1) {
            var _c_ref = characters[theater_active_char];
            var _is_v = !variable_struct_exists(_pb, "type") || _pb.type == "voice";
            var _is_alt = _is_v && (variable_struct_exists(_pb, "is_altered") ? _pb.is_altered : (_pb.voice_id != _c_ref.voice_id || _pb.pitch != _c_ref.pitch || _pb.speed != _c_ref.speed || _pb.mode != _c_ref.mode || _pb.style != _c_ref.style || _pb.tweaked != _c_ref.tweaked));
            if (_pb.char_index != 0 && _is_alt) {
                _name += " (altered voice)";
            }
            }
        }
        draw_text(200, 830, _name + ":");
        
        draw_set_color(c_white);
        // Clip to 3 lines (32px * 3 = 96px) starting from the subtitle Y (860)
        gpu_set_scissor(200, 860, 880, 96);
        draw_text_ext(200, 860 + theater_subtitle_scroll_y, theater_subtitles, 32, 880);
        gpu_set_scissor(0, 0, 1280, 960);
    }
    
    // Controls
    // EXIT Button (Bottom Right)
    var _ex = 1280 - 200; var _ey = 860; var _ew = 180; var _eh = 50;
    var _ehov = (mouse_x > _ex && mouse_x < _ex + _ew && mouse_y > _ey && mouse_y < _ey + _eh);
    draw_set_color(_ehov ? make_color_rgb(200, 50, 50) : make_color_rgb(150, 40, 40));
    draw_rectangle(_ex, _ey, _ex + _ew, _ey + _eh, false);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_ex + 90, _ey + 15, "EXIT THEATER");
    draw_set_halign(fa_left);
    
    // PLAY/PAUSE Button (Bottom Left)
    var _px = 30; var _py = 860; var _pw = 120; var _ph = 50;
    var _phov = (mouse_x > _px && mouse_x < _px + _pw && mouse_y > _py && mouse_y < _py + _ph);
    draw_set_color(_phov ? make_color_rgb(100, 100, 200) : make_color_rgb(60, 60, 150));
    draw_rectangle(_px, _py, _px + _pw, _py + _ph, false);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_px + 60, _py + 15, theater_paused ? "PLAY" : "PAUSE");
    draw_set_halign(fa_left);
    
    _render_live_titles();
    
    return; // Stop here if in theater mode
}


// --- 1. GLOBAL BUTTONS (Shuffled Midsection) ---
btn_add_x = box_x + 10; btn_add_y = btn_play_y;
btn_add_action_x = btn_add_x + 135; btn_add_action_y = btn_play_y;
btn_add_scene_x = btn_add_action_x + 135; btn_add_scene_y = btn_play_y;

btn_play_x = (box_x + box_w / 2) - (btn_play_w / 2);

// Repositioned Elements per Request
dropdown_x = char_sel_x;
dropdown_w = char_sel_w;
dropdown_y = char_sel_y - dropdown_h - 10;

btn_theater_w = 170;
btn_theater_h = 35;
btn_theater_x = scene_win_x + (scene_win_w / 2) - (btn_theater_w / 2);
btn_theater_y = scene_win_y - 45;

btn_dictionary_x = scene_win_x + scene_win_w - btn_dictionary_w;
btn_dictionary_y = btn_theater_y;
var _d_hov = (!_overlay_active && playing_block_index == -1 && _mx > btn_dictionary_x && _mx < btn_dictionary_x + btn_dictionary_w && _my > btn_dictionary_y && _my < btn_dictionary_y + btn_dictionary_h);
draw_set_color(playing_block_index != -1 ? make_color_rgb(60, 60, 60) : (_d_hov ? make_color_rgb(100, 200, 255) : make_color_rgb(60, 120, 180)));
draw_rectangle(btn_dictionary_x, btn_dictionary_y, btn_dictionary_x + btn_dictionary_w, btn_dictionary_y + btn_dictionary_h, false);
draw_set_color(c_white); draw_set_halign(fa_center); draw_text(btn_dictionary_x + (btn_dictionary_w/2), btn_dictionary_y + 8, "DICTIONARY"); draw_set_halign(fa_left);

var _btn_gap = 6;
var _col_w = (char_sel_w - _btn_gap * 2) / 3;

btn_pose_x = char_sel_x;
btn_pose_w = _col_w;
btn_pose_y = char_sel_y + char_sel_h + 10;
btn_pose_h = 35;

btn_expression_x = char_sel_x + _col_w + _btn_gap;
btn_expression_w = _col_w;
btn_expression_y = btn_pose_y;
btn_expression_h = 35;

btn_edit_x = char_sel_x + (_col_w + _btn_gap) * 2;
btn_edit_w = _col_w;
btn_edit_y = btn_pose_y;
btn_edit_h = 35;

btn_add_w = 125; btn_add_h = 35;
btn_add_scene_w = 125; btn_add_scene_h = 35;
btn_add_action_w = 125; btn_add_action_h = 35;

// --- FILE MENU BUTTON ---
var _fm_btn_x = 10; var _fm_btn_y = 10; var _fm_btn_w = 80; var _fm_btn_h = 35;
var _fm_hov = (!_overlay_active && playing_block_index == -1 && _mx > _fm_btn_x && _mx < _fm_btn_x + _fm_btn_w && _my > _fm_btn_y && _my < _fm_btn_y + _fm_btn_h);
draw_set_color(playing_block_index != -1 ? make_color_rgb(60, 60, 60) : ((_fm_hov || file_menu_open) ? make_color_rgb(100, 100, 120) : make_color_rgb(60, 60, 80)));
draw_rectangle(_fm_btn_x, _fm_btn_y, _fm_btn_x + _fm_btn_w, _fm_btn_y + _fm_btn_h, false);
draw_set_color(c_white); draw_set_halign(fa_center);
draw_text(_fm_btn_x + (_fm_btn_w / 2), _fm_btn_y + 8, "FILE");
draw_set_halign(fa_left);

// --- 1b. SCENE WINDOW ---
draw_set_color(c_black);
draw_rectangle(scene_win_x - 2, scene_win_y - 2, scene_win_x + scene_win_w + 2, scene_win_y + scene_win_h + 2, false);
if (current_scene_sprite != -1) {
    var _sw = sprite_get_width(current_scene_sprite);
    var _sh = sprite_get_height(current_scene_sprite);
    draw_sprite_ext(current_scene_sprite, 0, scene_win_x, scene_win_y, scene_win_w / _sw, scene_win_h / _sh, 0, c_white, 1);
}

// Actor Clipping (Clips exactly to the background area)
gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
if (active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
	var _scene = script_blocks[active_scene_block_idx];
	var _mask_sprite = -1;
	var _mask_name = "";
	if (variable_struct_exists(_scene, "internal_name")) {
		_mask_name = _scene.internal_name + "_mask";
		_mask_sprite = get_scene_sprite(_mask_name);
	}

	// --- Actor Drawing Logic ---
	var draw_editor_actors = function(_s, target_surface = -1, _draw_outline = true, _draw_sprite = true) {
		if (variable_struct_exists(_s, "actors")) {
			gpu_set_texfilter(false);
			for (var a = 0; a < array_length(preview_actors); a++) {
				var _act = preview_actors[a];
				
				var _is_being_dragged = false;
				if (dragging_actor_idx != -1 && dragging_actor_idx < array_length(_s.actors) && _s.actors[dragging_actor_idx].char_index == _act.char_index) _is_being_dragged = true;
				if (dragging_preview_idx != -1 && dragging_preview_idx < array_length(preview_actors) && preview_actors[dragging_preview_idx].char_index == _act.char_index) _is_being_dragged = true;
				if (_is_being_dragged) continue;
				
				var _pose  = variable_struct_exists(_act, "pose")       ? _act.pose       : 1;
				var _expr  = variable_struct_exists(_act, "expression") ? _act.expression : 21;
				var _aface = variable_struct_exists(_act, "facing")     ? _act.facing     : undefined;

				var _layers = get_composite_character_sprite(_act.char_index, _pose, _expr, _aface);
				var _spr    = _layers[0].spr;

				if (_spr != -1) {
					var _csw = sprite_get_width(_spr), _csh = sprite_get_height(_spr);
					var _sc = (scene_win_h * 1.5) / 450;
					var _y_off = variable_struct_exists(_act, "y_offset") ? _act.y_offset : 0;
					var _draw_x = (target_surface == -1) ? (scene_win_x + _act.x - (_csw * _sc)/2) : (_act.x - (_csw * _sc)/2);
					var _draw_y = (target_surface == -1) ? (scene_win_y + _act.y - (_csh * _sc) + _y_off) : (_act.y - (_csh * _sc) + _y_off);

					var _char_is_speaking = false;
					if (playing_block_index != -1 && is_speaking) {
                        var _end_idx = max(playing_block_index, playing_linked_index);
                        for (var _pi = playing_block_index; _pi <= _end_idx; _pi++) {
                            if (_pi < array_length(script_blocks)) {
                                var _cb = script_blocks[_pi];
                                if ((!variable_struct_exists(_cb, "type") || _cb.type == "voice") && real(_cb.char_index) == real(_act.char_index)) {
                                    var _creq = variable_struct_exists(_cb, "tts_req") ? _cb.tts_req : -1;
                                    for (var _ri = 0; _ri < array_length(active_requests); _ri++) {
                                        if (active_requests[_ri] == _creq) { _char_is_speaking = true; break; }
                                    }
                                    break;
                                }
                            }
                        }
					}
					var _alpha = (dragging_preview_idx != -1 && dragging_preview_idx < array_length(preview_actors) && preview_actors[dragging_preview_idx].char_index == _act.char_index) ? 0.5 : 1.0;
					var _mouth_anim = _char_is_speaking ? get_mouth_anim_sprites(_act.char_index, _pose, _expr, _aface) : [];
					var _has_manim  = array_length(_mouth_anim) > 0;
					var _manim_fi   = 0;
					var _mouth_open = false;
					if (_has_manim && playing_block_index >= 0 && playing_block_index < array_length(script_blocks)) {
						var _spk_b     = script_blocks[playing_block_index];
						var _spk_speed = variable_struct_exists(_spk_b, "speed") ? _spk_b.speed : 50;
						var _mouth_ms  = max(100, 300 - _spk_speed * 2);
						if (array_length(current_viseme_data) > 0) {
							var _prog;
							if (current_viseme_total_ms > 0 && speak_start_time_ms >= 0) {
								var _t_speed_val = max(1, 50 + _spk_speed * 2.5);
								var _adj_dur = current_viseme_total_ms * (175.0 / _t_speed_val);
								_prog = clamp((current_time - speak_start_time_ms) / max(1, _adj_dur), 0, 2);
							} else {
								var _txt_len = variable_struct_exists(_spk_b, "text") ? max(1, string_length(_spk_b.text)) : 1;
								_prog = speaking_index / _txt_len;
							}
							if (_prog >= 0.95) {
								_mouth_open = true;
								_manim_fi = floor(current_time / _mouth_ms) mod array_length(_mouth_anim);
							} else {
								var _cur_v = 0;
								for (var _vi = 0; _vi < array_length(current_viseme_data); _vi++) {
									if (current_viseme_data[_vi].t <= _prog) _cur_v = current_viseme_data[_vi].v; else break;
								}
								// Coast through SAPI5 inter-sentence silences — hold the last open
								// shape for up to 300 ms so the mouth doesn't snap closed between sentences.
								if (_cur_v != 0) {
									mouth_last_vis_time_ms = current_time; mouth_last_vis_value = _cur_v;
								} else if (mouth_last_vis_time_ms >= 0 && current_time - mouth_last_vis_time_ms < 300) {
									_cur_v = mouth_last_vis_value;
								}
								_mouth_open = (_cur_v != 0);
								if (_mouth_open) {
									// Map SAPI5 viseme (0-21) to jaw openness: 0=closed,1=small,2=open,3=wide
									var _vg = [0,2,3,2,1,1,1,1,1,2,1,2,1,1,0,0,1,0,0,0,1,0];
									_manim_fi = clamp(_vg[clamp(_cur_v, 0, 21)], 0, array_length(_mouth_anim) - 1);
								}
							}
						} else {
							_mouth_open = true;
							_manim_fi = floor(current_time / _mouth_ms) mod array_length(_mouth_anim);
						}
					}

					var _final_layers = [];
					for (var _li = 0; _li < array_length(_layers); _li++) {
						var _l       = _layers[_li];
						var _is_anim = variable_struct_exists(_l, "is_mouth") && _has_manim && _mouth_open;
						var _ae      = _is_anim ? _mouth_anim[_manim_fi] : undefined;
						var _lspr    = _is_anim ? _ae.spr : _l.spr;
						var _ldx     = _l.dx + (_is_anim ? _ae.dx : 0);
						var _ldy     = _l.dy + (_is_anim ? _ae.dy : 0);
						array_push(_final_layers, { spr: _lspr, dx: _ldx, dy: _ldy });
					}

					// Outline: drawn independently of sprite — needed for the mask surface pass
					if (_draw_outline && playing_block_index == -1 && selected_character_index == _act.char_index) {
						var _os = _sc * 1.18;
						for (var _oli = 0; _oli < array_length(_final_layers); _oli++) {
							var _ol = _final_layers[_oli];
							if (_ol.spr != -1) {
								var _lw = sprite_get_width(_ol.spr);
								var _lh = sprite_get_height(_ol.spr);
								var _olx = _draw_x + _ol.dx * _sc - _lw * (_os - _sc) * 0.5;
								var _oly = _draw_y + _ol.dy * _sc - _lh * (_os - _sc) * 0.5;
								draw_sprite_ext(_ol.spr, 0, _olx, _oly, _os, _os, 0, c_yellow, _alpha);
							}
						}
					}

					if (_draw_sprite) {
						var _clip = (target_surface == -1) ? [scene_win_x, scene_win_y, scene_win_w, scene_win_h] : undefined;
						draw_composite_character_ext(_final_layers, _draw_x, _draw_y, _sc, _alpha, c_white, false, 8, c_yellow, _clip);
						// Restore scissor clip for subsequent actors (since surface target switches clear it in GameMaker)
						if (target_surface == -1) {
							gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
						}
					}

				}
			}
			gpu_set_texfilter(false);
		}
	};

	if (_mask_sprite != -1) {
		// --- Masked Drawing using Surfaces ---
		if (!surface_exists(o_char_surface) || surface_get_width(o_char_surface) != scene_win_w || surface_get_height(o_char_surface) != scene_win_h) {
			if (surface_exists(o_char_surface)) surface_free(o_char_surface);
			o_char_surface = surface_create(scene_win_w, scene_win_h);
		}
		surface_set_target(o_char_surface);
		draw_clear_alpha(c_black, 0);
		draw_editor_actors(_scene, o_char_surface, false, true);
		surface_reset_target();

		if (!surface_exists(o_mask_surface) || surface_get_width(o_mask_surface) != scene_win_w || surface_get_height(o_mask_surface) != scene_win_h) {
			if (surface_exists(o_mask_surface)) surface_free(o_mask_surface);
			o_mask_surface = surface_create(scene_win_w, scene_win_h);
		}
		surface_set_target(o_mask_surface);
		draw_clear_alpha(c_black, 0);
		var _mask_w = sprite_get_width(_mask_sprite), _mask_h = sprite_get_height(_mask_sprite);
		var _mask_scale_x = scene_win_w / _mask_w;
		var _mask_scale_y = scene_win_h / _mask_h;
		
		draw_sprite_ext(_mask_sprite, 0, 0, 0, _mask_scale_x, _mask_scale_y, 0, c_white, 1);

		surface_reset_target();

		surface_set_target(o_char_surface);
		gpu_set_blendmode_ext(bm_zero, bm_inv_src_alpha);
		draw_surface(o_mask_surface, 0, 0);
		gpu_set_blendmode(bm_normal);
		surface_reset_target();

		draw_surface(o_char_surface, scene_win_x, scene_win_y);
		
		// Draw the visual mask (unshifted)
		draw_sprite_ext(_mask_sprite, 0, scene_win_x, scene_win_y, _mask_scale_x, _mask_scale_y, 0, c_white, 1);


	} else {
		// --- Unmasked Drawing ---
		draw_editor_actors(_scene, -1, false, true);
	};

	// --- Selection outline: hollow yellow ring drawn on top of foreground ---
	if (playing_block_index == -1) {
		for (var _oa = 0; _oa < array_length(preview_actors); _oa++) {
			var _oact = preview_actors[_oa];
			if (real(_oact.char_index) != real(selected_character_index)) continue;
			if (dragging_preview_idx != -1 && dragging_preview_idx < array_length(preview_actors) && preview_actors[dragging_preview_idx].char_index == _oact.char_index) continue;

			var _opose  = variable_struct_exists(_oact, "pose")       ? _oact.pose       : 1;
			var _oexpr  = variable_struct_exists(_oact, "expression") ? _oact.expression : 21;
			var _oface  = variable_struct_exists(_oact, "facing")     ? _oact.facing     : undefined;
			var _oy_off = variable_struct_exists(_oact, "y_offset")   ? _oact.y_offset   : 0;
			var _olayers = get_composite_character_sprite(_oact.char_index, _opose, _oexpr, _oface);
			if (_olayers[0].spr == -1) break;

			var _ocsw = sprite_get_width(_olayers[0].spr);
			var _ocsh = sprite_get_height(_olayers[0].spr);
			var _osc  = (scene_win_h * 1.5) / 450;
			// Local surface coords (no scene_win offset — applied when drawing the surface)
			var _sdx = _oact.x - (_ocsw * _osc) / 2;
			var _sdy = _oact.y - (_ocsh * _osc) + _oy_off;

			if (!surface_exists(o_mask_surface) || surface_get_width(o_mask_surface) != scene_win_w || surface_get_height(o_mask_surface) != scene_win_h) {
				if (surface_exists(o_mask_surface)) surface_free(o_mask_surface);
				o_mask_surface = surface_create(scene_win_w, scene_win_h);
			}
			surface_set_target(o_mask_surface);
			draw_clear_alpha(c_black, 0);
			gpu_set_texfilter(false);

			// Stamp 8-offset alpha footprint in white (color will be overwritten)
			var _ow = 3;
			var _ooffs = [[-_ow,0],[_ow,0],[0,-_ow],[0,_ow],[-_ow,-_ow],[_ow,-_ow],[-_ow,_ow],[_ow,_ow]];
			for (var _oi = 0; _oi < 8; _oi++) {
				for (var _li = 0; _li < array_length(_olayers); _li++) {
					var _ol = _olayers[_li];
					if (_ol.spr != -1) {
						draw_sprite_ext(_ol.spr, 0, _sdx + _ol.dx * _osc + _ooffs[_oi][0], _sdy + _ol.dy * _osc + _ooffs[_oi][1], _osc, _osc, 0, c_white, 1.0);
					}
				}
			}

			// Flatten all stamped pixels to pure yellow, preserving the alpha mask
			gpu_set_colorwriteenable(true, true, true, false);
			draw_set_color(c_yellow);
			draw_rectangle(0, 0, scene_win_w, scene_win_h, false);
			gpu_set_colorwriteenable(true, true, true, true);

			// Punch a hole where the character actually is
			gpu_set_blendmode_ext(bm_zero, bm_inv_src_alpha);
			for (var _li2 = 0; _li2 < array_length(_olayers); _li2++) {
				var _ol2 = _olayers[_li2];
				if (_ol2.spr != -1) {
					draw_sprite_ext(_ol2.spr, 0, _sdx + _ol2.dx * _osc, _sdy + _ol2.dy * _osc, _osc, _osc, 0, c_white, 1.0);
				}
			}
			gpu_set_blendmode(bm_normal);
			gpu_set_texfilter(false);
			surface_reset_target();

			// Draw the hollow ring on top of the scene (through foreground)
			gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
			draw_surface(o_mask_surface, scene_win_x, scene_win_y);
			break;
		}
	}
}


gpu_set_scissor(0, 0, 1280, 960);

// --- 1. GLOBAL BUTTONS (Drawn on top of Scene Window to prevent any overlap) ---
var _add_hov = (!_overlay_active && playing_block_index == -1 && _mx > btn_add_x && _mx < btn_add_x + btn_add_w && _my > btn_add_y && _my < btn_add_y + btn_add_h);
draw_set_color(playing_block_index != -1 ? make_color_rgb(100, 100, 100) : (_add_hov ? make_color_rgb(0, 220, 120) : make_color_rgb(0, 180, 100)));
draw_rectangle(btn_add_x, btn_add_y, btn_add_x + btn_add_w, btn_add_y + btn_add_h, false);
draw_set_color(c_white); draw_text(btn_add_x + 12, btn_add_y + 5, "+ VOICE");

var _act_hov = (!_overlay_active && playing_block_index == -1 && _mx > btn_add_action_x && _mx < btn_add_action_x + btn_add_action_w && _my > btn_add_action_y && _my < btn_add_action_y + btn_add_action_h);
var _act_col = make_color_rgb(180, 50, 255);
var _act_hov_col = make_color_rgb(220, 100, 255);
draw_set_color(playing_block_index != -1 ? make_color_rgb(100, 100, 100) : (_act_hov ? _act_hov_col : _act_col));
draw_rectangle(btn_add_action_x, btn_add_action_y, btn_add_action_x + btn_add_action_w, btn_add_action_y + btn_add_action_h, false);
draw_set_color(c_white);
draw_text(btn_add_action_x + 12, btn_add_action_y + 5, "+ ACTION");

var _scn_hov = (!_overlay_active && playing_block_index == -1 && _mx > btn_add_scene_x && _mx < btn_add_scene_x + btn_add_scene_w && _my > btn_add_scene_y && _my < btn_add_scene_y + btn_add_scene_h);
draw_set_color(playing_block_index != -1 ? make_color_rgb(100, 100, 100) : (_scn_hov ? make_color_rgb(0, 120, 220) : make_color_rgb(0, 100, 180)));
draw_rectangle(btn_add_scene_x, btn_add_scene_y, btn_add_scene_x + btn_add_scene_w, btn_add_scene_y + btn_add_scene_h, false);
draw_set_color(c_white); draw_text(btn_add_scene_x + 12, btn_add_scene_y + 5, "+ SCENE");

// --- 1.2 SCENE EDIT MODE INDICATORS (Drawn on top of Scene Window) ---
var _ind_x = max(scene_win_x, 110);
if (scene_edit_mode && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
    draw_set_color(make_color_rgb(255, 150, 0));
    draw_rectangle(_ind_x, scene_win_y - 45, _ind_x + 110, scene_win_y - 10, false);
    draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ind_x + 55, scene_win_y - 37, "STAGING"); draw_set_halign(fa_left);
}

if (insertion_idx != -1 && !scene_edit_mode) {
    draw_set_color(make_color_rgb(0, 150, 255));
    draw_rectangle(_ind_x, scene_win_y - 45, _ind_x + 150, scene_win_y - 10, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_ind_x + 75, scene_win_y - 37, "SPLICE MODE"); draw_set_halign(fa_left);
}

// --- 3d. STATIC FLIP BUTTON (Scene Edit Mode) ---
if (playing_block_index == -1 && scene_edit_mode && scene_edit_selected_actor_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
    var _scene = script_blocks[active_scene_block_idx];
    if (scene_edit_selected_actor_idx < array_length(_scene.actors)) {
        var _act = _scene.actors[scene_edit_selected_actor_idx];
        var _spr = get_character_sprite(_act.char_index);
        var _is_visible = true;
        if (_spr != -1) {
            var _csw = sprite_get_width(_spr), _csh = sprite_get_height(_spr);
            var _sc = (scene_win_h * 1.5) / 450;
            var _cw = _csw * _sc; var _ch = _csh * _sc;
            var _ax = scene_win_x + _act.x; var _ay = scene_win_y + _act.y;

            var _v_top = max(_ay - _ch, scene_win_y);
            var _v_bottom = min(_ay, scene_win_y + scene_win_h);
            var _v_visible = max(0, _v_bottom - _v_top);

            var _h_left  = _ax - _cw / 2;
            var _h_right = _ax + _cw / 2;
            var _h_intersect_l = max(_h_left, scene_win_x);
            var _h_intersect_r = min(_h_right, scene_win_x + scene_win_w);
            var _h_visible = max(0, _h_intersect_r - _h_intersect_l);
            
            _is_visible = (current_scene_sprite != -1) && (_v_visible >= _ch * 0.25) && (_h_visible >= _cw * 0.51);
        }

        if (_is_visible) {
            var _fw = 120; var _fh = 20;
            var _fx = scene_win_x + (scene_win_w / 2) - (_fw / 2); var _fy = scene_win_y + scene_win_h + 4;
            var _fhov = (!_overlay_active && _mx > _fx && _mx < _fx + _fw && _my > _fy && _my < _fy + _fh);
            draw_set_color(_fhov ? c_white : make_color_rgb(100, 100, 255));
            draw_rectangle(_fx, _fy, _fx + _fw, _fy + _fh, false);
            draw_set_color(_fhov ? make_color_rgb(100, 100, 255) : c_white);
            draw_set_halign(fa_center); draw_text(_fx + (_fw / 2), _fy + 3, "FLIP FACING"); draw_set_halign(fa_left);
        }
    }
}

if (file_menu_open) {
    var _fm_x = 10; var _fm_y = 45; var _fm_w = 165; var _fm_h = 105;
    draw_set_color(make_color_rgb(30, 30, 40)); draw_rectangle(_fm_x, _fm_y, _fm_x + _fm_w, _fm_y + _fm_h, false);
    draw_set_color(c_aqua); draw_rectangle(_fm_x, _fm_y, _fm_x + _fm_w, _fm_y + _fm_h, true);
    var _opts = ["SAVE SCRIPT", "LOAD SCRIPT", "SAVE SCREENPLAY"];
    for (var i = 0; i < 3; i++) {
        var _hov = (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y + (i * 35) && _my < _fm_y + ((i + 1) * 35));
        if (_hov) { draw_set_color(make_color_rgb(60, 60, 100)); draw_rectangle(_fm_x + 1, _fm_y + (i * 35) + 1, _fm_x + _fm_w - 1, _fm_y + ((i + 1) * 35) - 1, false); }
        draw_set_color(i == 2 ? make_color_rgb(180, 220, 255) : c_white);
        draw_text(_fm_x + 15, _fm_y + (i * 35) + 8, _opts[i]);
    }
}

// --- 1c. CHARACTER SELECTOR WINDOW ---
draw_set_color(make_color_rgb(35, 35, 45));
draw_rectangle(char_sel_x, char_sel_y, char_sel_x + char_sel_w, char_sel_y + char_sel_h, false);
draw_set_color(c_aqua); draw_rectangle(char_sel_x, char_sel_y, char_sel_x + char_sel_w, char_sel_y + char_sel_h, true);
draw_set_color(c_white); draw_text(char_sel_x + 10, char_sel_y + 5, "CHARACTER SELECTOR");
var _is_narrator_sel = (characters[selected_character_index].name == "NARRATOR");
if (SHOW_EXPR_CFG) {
    var _ecfg_btn_hov = (!_overlay_active && !_is_narrator_sel && _mx > char_sel_x + 195 && _mx < char_sel_x + char_sel_w - 6 && _my > char_sel_y + 2 && _my < char_sel_y + 28);
    draw_set_color(_is_narrator_sel ? make_color_rgb(28, 28, 38) : (_ecfg_btn_hov ? make_color_rgb(100, 150, 255) : make_color_rgb(40, 60, 110)));
    draw_roundrect_ext(char_sel_x + 195, char_sel_y + 2, char_sel_x + char_sel_w - 6, char_sel_y + 28, 4, 4, false);
    draw_set_color(_is_narrator_sel ? make_color_rgb(55, 55, 65) : c_white); draw_set_halign(fa_center);
    draw_text((char_sel_x + 195 + char_sel_x + char_sel_w - 6) / 2, char_sel_y + 7, "EXPR CFG");
    draw_set_halign(fa_left);
}

// --- Character Pane Scrollbar ---
var _c_total_h = ceil(array_length(characters) / 2) * 135;
var _c_view_h = char_sel_h - 35;
if (_c_total_h > _c_view_h) {
    var _sb_w = 8; var _sb_x = char_sel_x + char_sel_w - _sb_w - 4;
    var _sb_y = char_sel_y + 35; var _sb_h = char_sel_h - 40;
    draw_set_color(make_color_rgb(50, 50, 60)); draw_rectangle(_sb_x, _sb_y, _sb_x + _sb_w, _sb_y + _sb_h, false);
    var _bar_h = (_c_view_h / _c_total_h) * _sb_h;
    var _bar_y = _sb_y + (-char_sel_scroll_y / _c_total_h) * _sb_h;
    draw_set_color(make_color_rgb(120, 120, 140)); draw_rectangle(_sb_x, _bar_y, _sb_x + _sb_w, _bar_y + _bar_h, false);
}

gpu_set_scissor(char_sel_x + 2, char_sel_y + 30, char_sel_w - 4, char_sel_h - 35);
var _grid_x = char_sel_x + 10; var _grid_y = char_sel_y + 35;
var _item_w = 165; var _item_h = 135; var _cols = 2;
for (var i = 0; i < array_length(characters); i++) {
    var _ix = _grid_x + (i % _cols) * _item_w;
    var _iy = _grid_y + floor(i / _cols) * _item_h + char_sel_scroll_y;
    if (_iy + _item_h < char_sel_y + 30 || _iy > char_sel_y + char_sel_h) continue;
    var _is_sel = (i == selected_character_index);
    var _hov = (!_overlay_active && playing_block_index == -1 && _mx > _ix && _mx < _ix + _item_w && _my > _iy && _my < _iy + _item_h && _my > char_sel_y + 30 && _my < char_sel_y + char_sel_h);
    if (_hov || dragging_char_index == i) { draw_set_color(make_color_rgb(60, 60, 80)); draw_rectangle(_ix, _iy, _ix + _item_w - 5, _iy + _item_h - 5, false); }
    if (_is_sel) { draw_set_color(c_yellow); draw_rectangle(_ix, _iy, _ix + _item_w - 5, _iy + _item_h - 5, true); }
    // Use composite sprite reflecting current pose/expression; facing 1 (right) is the default selector view
    var _c_ch = characters[i];
    var _sel_pose = variable_struct_exists(_c_ch, "pose") ? _c_ch.pose : 1;
    var _sel_expr = variable_struct_exists(_c_ch, "expression") ? _c_ch.expression : 21;
    for (var pa = 0; pa < array_length(preview_actors); pa++) {
        if (preview_actors[pa].char_index == i) {
            _sel_pose = variable_struct_exists(preview_actors[pa], "pose") ? preview_actors[pa].pose : _sel_pose;
            _sel_expr = variable_struct_exists(preview_actors[pa], "expression") ? preview_actors[pa].expression : _sel_expr;
            break;
        }
    }
    // Use cached layers if pose/expr haven't changed — avoids ~5 file_exists calls per character per frame
    var _cached = (i < array_length(char_sel_layer_cache)) ? char_sel_layer_cache[i] : undefined;
    var _ch_layers = undefined;
    if (_cached == undefined || _cached.pose != _sel_pose || _cached.expr != _sel_expr) {
        _ch_layers = get_composite_character_sprite(i, _sel_pose, _sel_expr);
        char_sel_layer_cache[i] = { layers: _ch_layers, pose: _sel_pose, expr: _sel_expr };
    } else {
        _ch_layers = _cached.layers;
    }
    var _spr = _ch_layers[0].spr; // Use the body sprite from the composite layers
    if (_spr != -1) {
        // Total composite height = lower body + amount face extends above it (face_dy is negative)
        var _body_h_ch = sprite_get_height(_spr);
        var _face_above = max(0, -_ch_layers[1].dy);  // 0 for neutral (full body, no tiled face)
        var _total_h_ch = _body_h_ch + _face_above;
        var _sc    = (_item_h - 30) / _total_h_ch;
        var _sx    = _ix + (_item_w - 5) / 2 - (sprite_get_width(_spr) * _sc) / 2;
        // Bottom-anchor: feet near the name label, face extends upward naturally
        var _sy    = _iy + _item_h - 22 - _body_h_ch * _sc;
        var _alpha = (dragging_char_index == i) ? 0.3 : 1.0;
        draw_composite_character_ext(_ch_layers, _sx, _sy, _sc, _alpha, c_white, false, 3, c_yellow, [char_sel_x + 2, char_sel_y + 30, char_sel_w - 4, char_sel_h - 35]);
        // Restore scissor clip for subsequent selector items (since surface target switches clear it in GameMaker)
        gpu_set_scissor(char_sel_x + 2, char_sel_y + 30, char_sel_w - 4, char_sel_h - 35);
    }
    if (_is_sel && char_rename_active && char_rename_target == i) {
        // Inline rename field
        draw_set_color(c_white);
        draw_rectangle(_ix + 2, _iy + _item_h - 23, _ix + _item_w - 7, _iy + _item_h - 4, false);
        draw_set_color(make_color_rgb(20, 20, 30));
        var _rt_disp = char_rename_text;
        while (string_length(_rt_disp) > 0 && string_width(_rt_disp) > _item_w - 16) {
            _rt_disp = string_copy(_rt_disp, 2, string_length(_rt_disp) - 1);
        }
        draw_text(_ix + 5, _iy + _item_h - 20, _rt_disp);
        if ((current_time div 400) mod 2 == 0) {
            var _cx = _ix + 5 + string_width(_rt_disp);
            draw_line_width(_cx, _iy + _item_h - 20, _cx, _iy + _item_h - 6, 1);
        }
    } else {
        var _has_pencil = (_is_sel && playing_block_index == -1 && characters[i].name != "NARRATOR");
        var _nm_max_w = _item_w - 9 - (_has_pencil ? 20 : 4);
        var _nm_full  = characters[i].name;
        var _nm_scl   = min(1, _nm_max_w / max(1, string_width(_nm_full)));
        draw_set_color(_is_sel ? c_yellow : c_white);
        draw_text_transformed(_ix + 4, _iy + _item_h - 20, _nm_full, _nm_scl, 1, 0);
        if (_has_pencil) {
            var _penc_x = _ix + _item_w - 18; var _penc_y = _iy + _item_h - 22;
            var _penc_hov = (!_overlay_active && _mx > _penc_x && _mx < _penc_x + 14 && _my > _penc_y && _my < _penc_y + 16 && _my > char_sel_y + 30 && _my < char_sel_y + char_sel_h);
            draw_set_color(_penc_hov ? make_color_rgb(160, 180, 255) : make_color_rgb(80, 100, 160));
            draw_rectangle(_penc_x, _penc_y, _penc_x + 14, _penc_y + 16, false);
            draw_set_color(c_white); draw_set_halign(fa_center);
            draw_text(_penc_x + 7, _penc_y + 2, "/");
            draw_set_halign(fa_left);
        }
    }
}
gpu_set_scissor(0, 0, 1280, 960);
if (dragging_char_index != -1 || dragging_actor_idx != -1 || dragging_preview_idx != -1) {
    var _char_id = -1;
    if (dragging_char_index != -1) _char_id = dragging_char_index;
    else if (dragging_actor_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
        _char_id = script_blocks[active_scene_block_idx].actors[dragging_actor_idx].char_index;
    }
    else if (dragging_preview_idx != -1) {
        _char_id = preview_actors[dragging_preview_idx].char_index;
    }
    var _pose = 1;
    var _expr = 21;
    if (dragging_char_index != -1) {
        var _c = characters[dragging_char_index];
        _pose = variable_struct_exists(_c, "pose") ? _c.pose : 1;
        _expr = variable_struct_exists(_c, "expression") ? _c.expression : 21;
    } else if (dragging_actor_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
        var _sa = script_blocks[active_scene_block_idx].actors[dragging_actor_idx];
        _pose = variable_struct_exists(_sa, "pose") ? _sa.pose : 1;
        _expr = variable_struct_exists(_sa, "expression") ? _sa.expression : 21;
    } else if (dragging_preview_idx != -1) {
        var _sa = preview_actors[dragging_preview_idx];
        _pose = variable_struct_exists(_sa, "pose") ? _sa.pose : 1;
        _expr = variable_struct_exists(_sa, "expression") ? _sa.expression : 21;
    }
    
    _mx = mouse_x;
    _my = mouse_y;

    // Facing: new placements flip dynamically with mouse position (matching drop logic);
    // existing in-scene or preview actors hold whatever facing they already have.
    var _drag_face = undefined;
    if (dragging_char_index != -1) {
        var _ghost_is_left = (_mx < scene_win_x + scene_win_w / 2);
        _drag_face = scene_edit_mode ? (_ghost_is_left ? -1 : 1) : (_ghost_is_left ? 1 : -1);
    } else if (dragging_actor_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
        var _da = script_blocks[active_scene_block_idx].actors[dragging_actor_idx];
        _drag_face = variable_struct_exists(_da, "facing") ? _da.facing : undefined;
    } else if (dragging_preview_idx != -1) {
        var _dp = preview_actors[dragging_preview_idx];
        _drag_face = variable_struct_exists(_dp, "facing") ? _dp.facing : undefined;
    }

    var _layers = get_composite_character_sprite(_char_id, _pose, _expr, _drag_face);
    var _spr    = _layers[0].spr;

    if (_spr != -1) {
        var _csh = sprite_get_height(_spr);
        var _csw = sprite_get_width(_spr);
        var _scale = (scene_win_h * 1.5) / 450;

        var _cw = _csw * _scale;
        var _ch = _csh * _scale;

        var _px = _mx - scene_win_x - drag_off_x;
        var _py = _my - scene_win_y - drag_off_y;

        var _ay_abs = scene_win_y + _py;
        var _v_top = _ay_abs - _ch;
        var _v_bottom = _ay_abs;
        var _v_visible = max(0, min(_v_bottom, scene_win_y + scene_win_h) - max(_v_top, scene_win_y));

        var _ax_abs = scene_win_x + _px;
        var _h_left  = _ax_abs - _cw / 2;
        var _h_right = _ax_abs + _cw / 2;

        var _h_intersect_l = max(_h_left, scene_win_x);
        var _h_intersect_r = min(_h_right, scene_win_x + scene_win_w);
        var _h_visible = max(0, _h_intersect_r - _h_intersect_l);

        var _in_live = (current_scene_sprite != -1) && (_v_visible >= _ch * 0.25) && (_h_visible >= _cw * 0.51);
        var _color = _in_live ? c_white : c_red;
        var _alpha = _in_live ? 0.6 : 0.4;

        gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
        var _gx = scene_win_x + _px - (_csw * _scale)/2;
        var _gy = scene_win_y + _py - (_csh * _scale);
        draw_composite_character_ext(_layers, _gx, _gy, _scale, _alpha, _color, false, 3, c_yellow, [scene_win_x, scene_win_y, scene_win_w, scene_win_h]);
        gpu_set_scissor(0, 0, 1280, 960);
    }
}

// --- 2. SCRIPT BLOCKS RENDERING ---
draw_set_color(make_color_rgb(250, 250, 250));
draw_rectangle(box_x + 10, box_y + 5, box_x + box_w - 10, box_y + box_h - 5, false);
gpu_set_scissor(box_x - 50, box_y + 5, box_w + 40, box_h - 10);
var _cur_y = box_y + 5 + block_scroll_y;
var _wrap_w = box_w - 120;
var _onstage = [];
var _scene_encountered = false;

for (var b = 0; b < array_length(script_blocks); b++) {
    var _block = script_blocks[b];
    var _is_scene = variable_struct_exists(_block, "type") && _block.type == "scene";
    var _is_action = variable_struct_exists(_block, "type") && _block.type == "action";

    if (_is_scene) {
    _onstage = [];
    _scene_encountered = true;
    if (variable_struct_exists(_block, "actors")) {
        for (var a = 0; a < array_length(_block.actors); a++) {
            array_push(_onstage, _block.actors[a].char_index);
        }
    }
    var _box_y = _cur_y + 5;
        var _is_playing = (playing_block_index != -1 && b >= playing_block_index && b <= max(playing_block_index, playing_linked_index));
        draw_set_color(_is_playing ? make_color_rgb(255, 255, 180) : make_color_rgb(200, 200, 220));
        draw_rectangle(box_x + 45, _box_y, box_x + box_w - 45, _box_y + 80, false);
        draw_set_color(c_black); draw_text(box_x + 55, _box_y + 30, "[SCENE: " + string_upper(_block.name) + "]");
    } else if (_is_action) {
        var _aname = string_lower(_block.action_name);
        if (string_pos("enter", _aname) > 0) {
            var _found = false; for(var o=0; o<array_length(_onstage); o++) if (_onstage[o] == _block.char_index) _found = true;
            if (!_found) array_push(_onstage, _block.char_index);
        } else if (string_pos("exit", _aname) > 0) {
            for(var o=0; o<array_length(_onstage); o++) {
                if (_onstage[o] == _block.char_index) { array_delete(_onstage, o, 1); break; }
            }
        }

        var _box_y = _cur_y + 5;
        var _is_playing = (playing_block_index != -1 && b >= playing_block_index && b <= max(playing_block_index, playing_linked_index));
        draw_set_color(_is_playing ? make_color_rgb(255, 255, 180) : make_color_rgb(210, 220, 210));
        draw_rectangle(box_x + 45, _box_y, box_x + box_w - 45, _box_y + 80, false);
        
        var _aname_up = string_upper(_block.action_name);
        var _is_wait      = (string_pos("WAIT",          _aname_up) > 0);
        var _is_sfx       = (string_pos("PLAY SFX",      _aname_up) > 0);
        var _is_title     = (string_pos("DISPLAY TITLE", _aname_up) > 0);
        var _is_expr_blk  = (string_pos("EXPRESSION:", _aname_up) > 0 || string_pos("LOOKS ", _aname_up) > 0 || (string_pos("POSE ", _aname_up) > 0 && string_pos("POSES ", _aname_up) == 0));
        if (_is_expr_blk && !_is_playing) {
            draw_set_color(make_color_rgb(210, 210, 228));
            draw_rectangle(box_x + 45, _box_y, box_x + box_w - 45, _box_y + 80, false);
        }
        var _act_str = "ACTION: ";
        if (_is_wait || _is_sfx || _is_title) {
            _act_str += _aname_up;
        } else {
            var _aname_lo_blk = string_lower(_block.action_name);
            var _display_act = _aname_up;
            // Substitute pose label for "pose N" and "looks X and pose N" formats
            if (string_pos("looks ", _aname_lo_blk) > 0 && string_pos(" and pose ", _aname_lo_blk) > 0) {
                var _ap2 = string_pos(" and pose ", _aname_lo_blk);
                var _pn2 = real(string_copy(_aname_lo_blk, _ap2 + 10, 1));
                var _plbl = string_upper(get_pose_label(_block.char_index, _pn2));
                _display_act = string_upper(string_copy(_block.action_name, 1, _ap2 - 1)) + ", " + _plbl;
            } else if (string_pos("pose ", _aname_lo_blk) > 0 && string_pos("poses ", _aname_lo_blk) == 0) {
                var _pn2 = real(string_copy(_aname_lo_blk, string_pos("pose ", _aname_lo_blk) + 5, 1));
                _display_act = string_upper(get_pose_label(_block.char_index, _pn2));
            }
            _act_str += characters[_block.char_index].name + " " + _display_act;
        }
        draw_set_color(c_black); draw_text(box_x + 55, _box_y + 30, _act_str);
    } else {
        var _is_focused = (focused_block == b);
        var _text_h = _block.height - 25; // Matching Create_0 logic
        
        var _is_onstage = false;
        for(var o=0; o<array_length(_onstage); o++) if (_onstage[o] == _block.char_index) _is_onstage = true;
        
        var _chain_start = b;
        while (_chain_start > 0 && variable_struct_exists(script_blocks[_chain_start-1], "linked") && script_blocks[_chain_start-1].linked) _chain_start--;
        var _chain_end = b;
        while (_chain_end < array_length(script_blocks) - 1 && variable_struct_exists(script_blocks[_chain_end], "linked") && script_blocks[_chain_end].linked) _chain_end++;
        
        if (_chain_start != _chain_end) {
            for (var _k = _chain_start; _k <= _chain_end; _k++) {
                var _cb = script_blocks[_k];
                if (variable_struct_exists(_cb, "type") && _cb.type == "action" && _cb.char_index == _block.char_index) {
                    var _caname = string_lower(_cb.action_name);
                    if (string_pos("enter", _caname) > 0 || string_pos("exit", _caname) > 0) {
                        _is_onstage = true;
                        break;
                    }
                }
            }
        }
        
        var _c_ref = characters[_block.char_index];
        var _is_v = !variable_struct_exists(_block, "type") || _block.type == "voice";
        var _is_alt = _is_v && (variable_struct_exists(_block, "is_altered") ? _block.is_altered : (_block.voice_id != _c_ref.voice_id || _block.pitch != _c_ref.pitch || _block.speed != _c_ref.speed || _block.mode != _c_ref.mode || _block.style != _c_ref.style || _block.tweaked != _c_ref.tweaked));
        
        var _char_name = string_upper(_c_ref.name);
        if (_is_alt) _char_name += " (altered voice)";
        if (!_is_onstage && _block.char_index != 0) _char_name += " (offstage)";
        
        draw_set_color(make_color_rgb(100, 100, 120)); draw_text(box_x + 50, _cur_y, _char_name + ":");
        var _is_playing = (playing_block_index != -1 && b >= playing_block_index && b <= max(playing_block_index, playing_linked_index));
        draw_set_color(_is_playing ? make_color_rgb(255, 255, 180) : (_is_focused ? make_color_rgb(245, 250, 255) : c_white));
        draw_rectangle(box_x + 45, _cur_y + 20, box_x + box_w - 45, _cur_y + 20 + _text_h, false);
        draw_set_color(_is_focused ? c_blue : c_black); draw_rectangle(box_x + 45, _cur_y + 20, box_x + box_w - 45, _cur_y + 20 + _text_h, true);

        // Text Selection Highlight
        var _sel_s = min(selection_start, selection_end);
        var _sel_e = max(selection_start, selection_end);
        if (_is_focused && _sel_s != _sel_e) {
            var _p_start = get_text_pos(_block.text, _sel_s, _wrap_w, 28);
            var _p_end   = get_text_pos(_block.text, _sel_e, _wrap_w, 28);
            draw_set_alpha(0.3); draw_set_color(c_blue);
            if (_p_start.y == _p_end.y) {
                draw_rectangle(box_x + 60 + _p_start.x, _cur_y + 32 + _p_start.y, box_x + 60 + _p_end.x, _cur_y + 32 + _p_start.y + 24, false);
            } else {
                // First line
                draw_rectangle(box_x + 60 + _p_start.x, _cur_y + 32 + _p_start.y, box_x + 60 + _wrap_w, _cur_y + 32 + _p_start.y + 24, false);
                // Middle lines
                var _mid_y = _p_start.y + 28;
                while (_mid_y < _p_end.y) {
                    draw_rectangle(box_x + 60, _cur_y + 32 + _mid_y, box_x + 60 + _wrap_w, _cur_y + 32 + _mid_y + 24, false);
                    _mid_y += 28;
                }
                // Last line
                draw_rectangle(box_x + 60, _cur_y + 32 + _p_end.y, box_x + 60 + _p_end.x, _cur_y + 32 + _p_end.y + 24, false);
            }
            draw_set_alpha(1.0);
        }

        draw_set_color(c_black); draw_text_ext(box_x + 60, _cur_y + 30, _block.text, 28, _wrap_w);

        // Caret (Cursor) Rendering
        if (_is_focused && cursor_visible) {
            var _cp = get_text_pos(_block.text, _block.caret_pos, _wrap_w, 28);
            draw_set_color(c_blue);
            draw_line_width(box_x + 60 + _cp.x, _cur_y + 32 + _cp.y, box_x + 60 + _cp.x, _cur_y + 32 + _cp.y + 24, 2);
        }
    }

    // Button Stacks
    var _lx = box_x + 10; var _rx = box_x + box_w - 35; var _bw = 28; var _bh = 22;
    
    // Left Hover Checks
    var _hov_up = (!_overlay_active && playing_block_index == -1 && _mx > _lx && _mx < _lx + _bw && _my > _cur_y + 5 && _my < _cur_y + 5 + _bh);
    var _hov_ed = (!_overlay_active && playing_block_index == -1 && _mx > _lx && _mx < _lx + _bw && _my > _cur_y + 35 && _my < _cur_y + 35 + _bh);
    var _hov_dn = (!_overlay_active && playing_block_index == -1 && _mx > _lx && _mx < _lx + _bw && _my > _cur_y + 65 && _my < _cur_y + 65 + _bh);
    
    // Right Hover Checks
    var _hov_del = (!_overlay_active && playing_block_index == -1 && _mx > _rx && _mx < _rx + _bw && _my > _cur_y + 5 && _my < _cur_y + 5 + _bh);

    // Render Left Stack
    draw_set_color((playing_block_index != -1) ? make_color_rgb(80, 80, 90) : (_hov_up ? make_color_rgb(140, 140, 170) : make_color_rgb(100, 100, 120)));
    draw_rectangle(_lx, _cur_y + 5, _lx + _bw, _cur_y + 5 + _bh, false); 
    draw_set_color((playing_block_index != -1) ? c_gray : c_white); draw_text(_lx+8, _cur_y + 5, "^");
    
    draw_set_color((playing_block_index != -1) ? make_color_rgb(150, 150, 150) : (_hov_ed ? make_color_rgb(255, 255, 150) : c_yellow));
    draw_rectangle(_lx, _cur_y+35, _lx + _bw, _cur_y + 35 + _bh, false); 
    draw_set_color(c_black); draw_text(_lx+8, _cur_y+35, "/");
    
    draw_set_color((playing_block_index != -1) ? make_color_rgb(80, 80, 90) : (_hov_dn ? make_color_rgb(140, 140, 170) : make_color_rgb(100, 100, 120)));
    draw_rectangle(_lx, _cur_y+65, _lx + _bw, _cur_y + 65 + _bh, false); 
    draw_set_color((playing_block_index != -1) ? c_gray : c_white); draw_text(_lx+8, _cur_y+65, "v");

    // Render Right Stack
    draw_set_color((playing_block_index != -1) ? make_color_rgb(120, 60, 60) : (_hov_del ? make_color_rgb(230, 80, 80) : make_color_rgb(180, 50, 50)));
    draw_rectangle(_rx, _cur_y + 5, _rx + _bw, _cur_y + 5 + _bh, false); 
    draw_set_color((playing_block_index != -1) ? c_gray : c_white); draw_text(_rx+6, _cur_y + 5, "X");

    // 4. Play From Here (Green Triangle) - Now in the GUTTER
    if (playing_block_index == -1) {
        var _px = box_x - 30; var _py = _cur_y + 5;
        var _phov = (!_overlay_active && _mx > _px && _mx < _px + 30 && _my > _py && _my < _py + 30);
        draw_set_color(_phov ? c_lime : c_green);
        draw_triangle(_px+5, _py+5, _px+5, _py+25, _px+25, _py+15, false);
    }

    var _gap_y = _cur_y + _block.height;
    if (insertion_idx == b && !action_animating && playing_block_index == -1) {
        draw_set_color(c_yellow);
        draw_set_alpha(0.3);
        draw_rectangle(box_x + 10, _gap_y + 2, box_x + box_w - 10, _gap_y + 23, false);
        draw_set_alpha(1.0);
        draw_set_color(c_yellow);
        draw_line_width(box_x + 10, _gap_y + 12, box_x + box_w - 10, _gap_y + 12, 2);
    }
    
    // 5. Draw "+" Splice Mode Button
    if (b < array_length(script_blocks) - 1 && playing_block_index == -1) {
        var _plus_center_x = box_x + (box_w / 2);
        var _plus_hov = (!_overlay_active && _mx > _plus_center_x - 20 && _mx < _plus_center_x + 20 && _my > _gap_y && _my < _gap_y + 20);
        
        // 6. Draw "LINK" Button
        var _b1 = script_blocks[b];
        var _is_linked = variable_struct_exists(_b1, "linked") && _b1.linked;
        
        if (!_is_linked) {
            draw_set_color(_plus_hov ? c_green : make_color_rgb(150, 150, 170));
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_text_transformed(_plus_center_x, _gap_y + 10, "+", 1.5, 1.5, 0);
            draw_text_transformed(_plus_center_x + 1, _gap_y + 10, "+", 1.5, 1.5, 0); // Faux bolding
            draw_text_transformed(_plus_center_x, _gap_y + 11, "+", 1.5, 1.5, 0);
            draw_text_transformed(_plus_center_x + 1, _gap_y + 11, "+", 1.5, 1.5, 0);
            draw_set_halign(fa_left); draw_set_valign(fa_top);
        }
        
        var _b2 = script_blocks[b+1];

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

        var _chain_valid = true;
        
        if (_base_valid && !_is_linked) {
            var _start_idx = b;
            while (_start_idx > 0 && variable_struct_exists(script_blocks[_start_idx-1], "linked") && script_blocks[_start_idx-1].linked) _start_idx--;
            var _end_idx = b + 1;
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
            var _link_hov = (!_overlay_active && _mx > _link_x - 15 && _mx < _link_x + 60 && _my > _gap_y && _my < _gap_y + 20);
            
            var _link_col = _is_linked ? (_link_hov ? c_green : c_lime) : (_link_hov ? c_yellow : make_color_rgb(150, 150, 170));
            draw_set_color(_link_col);
            var _lx1 = _link_x - 8; var _lx2 = _link_x + 8;
            draw_circle(_lx1, _gap_y + 10, 5, true); draw_circle(_lx1, _gap_y + 10, 4, true);
            draw_circle(_lx2, _gap_y + 10, 5, true); draw_circle(_lx2, _gap_y + 10, 4, true);
            draw_line_width(_lx1 + 3, _gap_y + 7, _lx2 - 3, _gap_y + 7, 2);
            draw_line_width(_lx1 + 3, _gap_y + 13, _lx2 - 3, _gap_y + 13, 2);
            
            draw_set_halign(fa_left); draw_set_valign(fa_middle);
            draw_text(_link_x + 18, _gap_y + 10, _is_linked ? "LINKED" : "LINK");
            draw_set_halign(fa_left); draw_set_valign(fa_top);
        }
    }

    _cur_y += _block.height + 20;
}
gpu_set_scissor(0, 0, 1280, 960);

// --- 5. SCRIPT SCROLLBAR ---
var _full_h = 0; 
for (var i = 0; i < array_length(script_blocks); i++) {
    _full_h += script_blocks[i].height + 20;
}
_full_h += box_h / 2; // Match the Step event's normalized buffer

if (_full_h > box_h - 10) {
    var _view_h = box_h - 10;
    var _bar_h = (_view_h / _full_h) * _view_h;
    var _bar_y = (box_y + 5) + (-block_scroll_y / _full_h) * _view_h;
    
    // Draw Track
    draw_set_color(make_color_rgb(70, 70, 80));
    draw_rectangle(box_x + box_w - 10, box_y + 5, box_x + box_w - 2, box_y + box_h - 5, false); 
    
    // Draw Bar
    draw_set_color(make_color_rgb(120, 120, 140));
    draw_rectangle(box_x + box_w - 10, _bar_y, box_x + box_w - 2, _bar_y + _bar_h, false); 
}

// --- 5b. BOTTOM CONTROLS ---
var _p_hov = (!_overlay_active && _mx > btn_play_x && _mx < btn_play_x + btn_play_w && _my > btn_play_y && _my < btn_play_y + btn_play_h);
var _p_col = (playing_block_index != -1) ? make_color_rgb(200, 50, 50) : make_color_rgb(50, 180, 50);
var _p_hov_col = (playing_block_index != -1) ? make_color_rgb(255, 80, 80) : make_color_rgb(80, 220, 80);
draw_set_color(_p_hov ? _p_hov_col : _p_col);
draw_rectangle(btn_play_x, btn_play_y, btn_play_x + btn_play_w, btn_play_y + btn_play_h, false);
draw_set_color(c_white); draw_text(btn_play_x + 25, btn_play_y + 8, (playing_block_index != -1) ? "STOP" : "PLAY");

// ENTER THEATER Button
var _thov = (!_overlay_active && playing_block_index == -1 && _mx > btn_theater_x && _mx < btn_theater_x + btn_theater_w && _my > btn_theater_y && _my < btn_theater_y + btn_theater_h);
draw_set_color(playing_block_index != -1 ? make_color_rgb(60, 60, 60) : (_thov ? make_color_rgb(100, 100, 200) : make_color_rgb(60, 60, 150)));
draw_rectangle(btn_theater_x, btn_theater_y, btn_theater_x + btn_theater_w, btn_theater_y + btn_theater_h, false);
draw_set_color(c_white); draw_set_halign(fa_center); draw_text(btn_theater_x + (btn_theater_w / 2), btn_theater_y + 8, "ENTER THEATER"); draw_set_halign(fa_left);

// --- POSE, EXPRESSION & VOICE CONTROLS ---
var _is_narrator = (characters[selected_character_index].name == "NARRATOR");
var _pe_btn_w = btn_expression_x + btn_expression_w - btn_pose_x;
var _phov = (!_is_narrator && !_overlay_active && playing_block_index == -1 && _mx > btn_pose_x && _mx < btn_pose_x + _pe_btn_w && _my > btn_pose_y && _my < btn_pose_y + btn_pose_h);
var _evhov = (!_overlay_active && playing_block_index == -1 && _mx > btn_edit_x && _mx < btn_edit_x + btn_edit_w && _my > btn_edit_y && _my < btn_edit_y + btn_edit_h);

// RENDER POSE / EXPR COMBINED BUTTON
draw_set_color(_is_narrator || playing_block_index != -1 ? make_color_rgb(55, 55, 55) : (_phov ? make_color_rgb(100, 150, 255) : make_color_rgb(40, 80, 150)));
draw_rectangle(btn_pose_x, btn_pose_y, btn_pose_x + _pe_btn_w, btn_pose_y + btn_pose_h, false);
draw_set_color(_is_narrator ? make_color_rgb(110, 110, 110) : c_white); draw_set_halign(fa_center);
draw_text(btn_pose_x + _pe_btn_w / 2, btn_pose_y + 8, "POSE / EXPR");
draw_set_halign(fa_left);

// RENDER VOICE BUTTON
draw_set_color(playing_block_index != -1 ? make_color_rgb(80, 80, 80) : (_evhov ? make_color_rgb(160, 160, 160) : make_color_rgb(100, 100, 100)));
draw_rectangle(btn_edit_x, btn_edit_y, btn_edit_x + btn_edit_w, btn_edit_y + btn_edit_h, false);
draw_set_color(c_white); draw_set_halign(fa_center);
draw_text(btn_edit_x + btn_edit_w/2, btn_edit_y + 8, "VOICE");
draw_set_halign(fa_left);

draw_set_color(make_color_rgb(50, 50, 60)); draw_rectangle(dropdown_x, dropdown_y, dropdown_x + dropdown_w, dropdown_y + dropdown_h, false);
draw_set_color(c_aqua); draw_rectangle(dropdown_x, dropdown_y, dropdown_x + dropdown_w, dropdown_y + dropdown_h, true);
draw_set_color(c_white); draw_text(dropdown_x + 10, dropdown_y + 5, characters[selected_character_index].name);

// --- 6. MODALS ---
if (dictionary_open) {
    draw_set_color(c_black); draw_set_alpha(0.8); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _m_w = 700; var _m_h = 500; var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    draw_set_color(make_color_rgb(40, 40, 50)); draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 20, 20, false);
    draw_set_color(c_aqua); draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 20, 20, true);
    
    draw_set_color(c_white); draw_text(_m_x + 20, _m_y + 20, "PRONUNCIATION DICTIONARY");
    draw_text(_m_x + 20, _m_y + 55, "Written Word"); draw_text(_m_x + 280, _m_y + 55, "Pronunciation");

    gpu_set_scissor(_m_x + 10, _m_y + 80, _m_w - 20, 320);
    for (var i = 0; i < array_length(dictionary_list); i++) {
        var _ey = _m_y + 80 + (i * 45) + dictionary_scroll_y;
        var _entry = dictionary_list[i];
        
        // Column 1: Written
        draw_set_color((dict_focused_entry == i && dict_focused_field == 0) ? c_white : make_color_rgb(60, 60, 70));
        draw_rectangle(_m_x + 20, _ey, _m_x + 260, _ey + 35, false);
        draw_set_color(c_black); draw_text(_m_x + 25, _ey + 8, _entry.written);
        if (dict_focused_entry == i && dict_focused_field == 0 && cursor_visible) {
            var _cx = string_width(string_copy(_entry.written, 1, dict_caret_pos));
            draw_set_color(c_blue);
            draw_line_width(_m_x + 25 + _cx, _ey + 5, _m_x + 25 + _cx, _ey + 30, 2);
        }

        // Column 2: Pronunciation
        draw_set_color((dict_focused_entry == i && dict_focused_field == 1) ? c_white : make_color_rgb(60, 60, 70));
        draw_rectangle(_m_x + 280, _ey, _m_x + 520, _ey + 35, false);
        draw_set_color(c_black); draw_text(_m_x + 285, _ey + 8, _entry.pronunciation);
        if (dict_focused_entry == i && dict_focused_field == 1 && cursor_visible) {
            var _cx = string_width(string_copy(_entry.pronunciation, 1, dict_caret_pos));
            draw_set_color(c_blue);
            draw_line_width(_m_x + 285 + _cx, _ey + 5, _m_x + 285 + _cx, _ey + 30, 2);
        }
        
        // Test Button
        var _test_hov = (_mx > _m_x + 540 && _mx < _m_x + 610 && _my > _ey && _my < _ey + 35);
        draw_set_color(_test_hov ? c_lime : make_color_rgb(50, 150, 50));
        draw_rectangle(_m_x + 540, _ey, _m_x + 610, _ey + 35, false);
        draw_set_color(c_white); draw_text(_m_x + 550, _ey + 8, "TEST");
        
        // Remove Button
        var _rhov = (_mx > _m_x + 630 && _mx < _m_x + 670 && _my > _ey && _my < _ey + 35);
        draw_set_color(_rhov ? c_red : make_color_rgb(150, 50, 50));
        draw_rectangle(_m_x + 630, _ey, _m_x + 670, _ey + 35, false);
        draw_set_color(c_white); draw_text(_m_x + 643, _ey + 8, "X");
    }
    gpu_set_scissor(0, 0, 1280, 960);

    // Dictionary Scrollbar
    var _dict_total_h = array_length(dictionary_list) * 45;
    var _dict_view_h = 320;
    if (_dict_total_h > _dict_view_h) {
        var _sb_w = 8; var _sb_x = _m_x + _m_w - 22;
        var _sb_y = _m_y + 80; var _sb_h = _dict_view_h;
        draw_set_color(make_color_rgb(60, 60, 70));
        draw_rectangle(_sb_x, _sb_y, _sb_x + _sb_w, _sb_y + _sb_h, false); // Track
        var _bar_h = (_dict_view_h / _dict_total_h) * _sb_h;
        var _bar_y = _sb_y + (-dictionary_scroll_y / _dict_total_h) * _sb_h;
        draw_set_color(make_color_rgb(120, 120, 140));
        draw_rectangle(_sb_x, _bar_y, _sb_x + _sb_w, _bar_y + _bar_h, false); // Handle
    }
    
    // Add Button
    var _ahov = (_mx > _m_x + 20 && _mx < _m_x + 150 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20);
    draw_set_color(_ahov ? c_white : c_ltgray);
    draw_rectangle(_m_x + 20, _m_y + _m_h - 60, _m_x + 150, _m_y + _m_h - 20, false);
    draw_set_color(c_black); draw_text(_m_x + 40, _m_y + _m_h - 50, "ADD ENTRY");
    
    // Close Button
    var _chov = (_mx > _m_x + _m_w - 140 && _mx < _m_x + _m_w - 20 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20);
    draw_set_color(_chov ? c_white : c_ltgray);
    draw_rectangle(_m_x + _m_w - 140, _m_y + _m_h - 60, _m_x + _m_w - 20, _m_y + _m_h - 20, false);
    draw_set_color(c_black); draw_text(_m_x + _m_w - 105, _m_y + _m_h - 50, "CLOSE");
}

if (edit_mode) {
    draw_set_color(c_black); draw_set_alpha(0.85); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _mw = 800; var _mh = 700; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    draw_set_color(make_color_rgb(30, 30, 40)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 20, 20, false);
    draw_set_color(make_color_rgb(100, 100, 255)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 20, 20, true);
    draw_set_color(c_white); draw_text_transformed(_mxo+30, _myo+25, "VOICE STUDIO", 1.2, 1.2, 0);
    
    _cols = 4; var _bw = 170; var _bh = 45; var _gx = (_mw - (_cols * (_bw + 15))) / 2;
    for (var i = 0; i < array_length(all_voices); i++) {
        var _bx = _mxo + _gx + ((i % _cols) * (_bw + 15));
        var _by = _myo + 70 + (floor(i / _cols) * (_bh + 8));
        var _is_sel = (all_voices[i].voice_id == modal_voice_id);
        var _v_hov = (_mx > _bx && _mx < _bx + _bw && _my > _by && _my < _by + _bh);
        draw_set_color(_is_sel ? make_color_rgb(0, 120, 255) : (_v_hov ? make_color_rgb(80, 80, 100) : make_color_rgb(50, 50, 70)));
        draw_roundrect_ext(_bx, _by, _bx + _bw, _by + _bh, 10, 10, false);
        draw_set_color(c_white); var _ns = all_voices[i].name; if (string_length(_ns) > 22) _ns = string_copy(_ns, 1, 20) + "..";
        draw_text(_bx + 10, _by + 13, _ns);
    }
	  // --- Tweak Toggle ---
    var _toggle_y = _myo + 580;
    var _twk_hov = (_mx > _mxo+50 && _mx < _mxo+350 && _my > _toggle_y && _my < _toggle_y+25);
    draw_set_color(_twk_hov ? c_white : c_ltgray);
    draw_rectangle(_mxo+50, _toggle_y, _mxo+70, _toggle_y+20, true); // checkbox outline
    if (tweak_enabled) { draw_set_color(c_lime); draw_rectangle(_mxo+54, _toggle_y+4, _mxo+66, _toggle_y+16, false); }
    draw_set_color(c_white); draw_text(_mxo+80, _toggle_y+2, "Advanced Voice Tweaks");

    // --- Tweak Controls (only when enabled) ---
    if (tweak_enabled) {
        var _ctrl_y = _myo + 360;
        
        // Pitch
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y, "Pitch:");
        draw_set_color(make_color_rgb(60,60,80)); draw_rectangle(_mxo+180, _ctrl_y, _mxo+480, _ctrl_y+20, false);
        draw_set_color(make_color_rgb(100,100,255)); draw_rectangle(_mxo+180, _ctrl_y, _mxo+180+(modal_pitch/180)*300, _ctrl_y+20, false);
        draw_set_color(c_white); draw_text(_mxo+165, _ctrl_y, "<"); draw_text(_mxo+485, _ctrl_y, ">");
        draw_text(_mxo+520, _ctrl_y, string(modal_pitch));

        // Speed
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+50, "Speed:");
        draw_set_color(make_color_rgb(60,60,80)); draw_rectangle(_mxo+180, _ctrl_y+50, _mxo+480, _ctrl_y+70, false);
        draw_set_color(make_color_rgb(100,255,100)); draw_rectangle(_mxo+180, _ctrl_y+50, _mxo+180+(modal_speed/100)*300, _ctrl_y+70, false);
        draw_set_color(c_white); draw_text(_mxo+165, _ctrl_y+50, "<"); draw_text(_mxo+485, _ctrl_y+50, ">");
        draw_text(_mxo+520, _ctrl_y+50, string(modal_speed));

        // Quality radio buttons
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+93, "Quality:");
        var _q_labels = ["Normal", "Monotone", "Sung"]; var _q_vals = [0, 2, 4];
        for (var e = 0; e < 3; e++) {
            var _ex = _mxo+180+(e*105);
            draw_set_color((modal_quality == _q_vals[e]) ? c_lime : c_gray);
            draw_circle(_ex, _ctrl_y+108, 10, true);
            if (modal_quality == _q_vals[e]) draw_circle(_ex, _ctrl_y+108, 6, false);
            draw_set_color(c_white); draw_text(_ex-12, _ctrl_y+120, _q_labels[e]);
        }

        // Effort radio buttons
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+133, "Effort:");
        var _s_labels = ["Normal", "Breathy", "Whispered"];
        for (var s = 0; s < 3; s++) {
            var _sx = _mxo+180+(s*105);
            draw_set_color((modal_effort == s) ? c_lime : c_gray);
            draw_circle(_sx, _ctrl_y+148, 10, true);
            if (modal_effort == s) draw_circle(_sx, _ctrl_y+148, 6, false);
            draw_set_color(c_white); draw_text(_sx-12, _ctrl_y+160, _s_labels[s]);
        }
    }

    // --- Bottom Buttons ---
    var _btn_y = _myo + _mh - 60;

    // Revert (Only for local block edits)
    if (modal_is_local_edit) {
        var _rv_hov = (_mx > _mxo + 30 && _mx < _mxo + 150 && _my > _btn_y && _my < _btn_y + 40);
        draw_set_color(_rv_hov ? c_white : make_color_rgb(200, 150, 50));
        draw_rectangle(_mxo + 30, _btn_y, _mxo + 150, _btn_y + 40, false);
        draw_set_color(_rv_hov ? make_color_rgb(200, 150, 50) : c_white); draw_text(_mxo + 50, _btn_y + 10, "REVERT");
    }

    // Test
    var _tx = modal_is_local_edit ? _mxo + 165 : _mxo + 30;
    var _t_hov = (_mx > _tx && _mx < _tx + 120 && _my > _btn_y && _my < _btn_y + 40);
    draw_set_color(_t_hov ? c_white : make_color_rgb(50, 150, 200));
    draw_rectangle(_tx, _btn_y, _tx + 120, _btn_y + 40, false);
    draw_set_color(_t_hov ? make_color_rgb(50, 150, 200) : c_white); draw_text(_tx + 35, _btn_y + 10, "TEST");

    // Export Config (debug)
    if (SHOW_VOICE_CFG && !modal_is_local_edit) {
        var _ex_hov = (_mx > _mxo+_mw-430 && _mx < _mxo+_mw-295 && _my > _btn_y && _my < _btn_y+40);
        draw_set_color(_ex_hov ? c_white : make_color_rgb(140, 60, 200));
        draw_rectangle(_mxo+_mw-430, _btn_y, _mxo+_mw-295, _btn_y+40, false);
        draw_set_color(_ex_hov ? make_color_rgb(140,60,200) : c_white);
        draw_set_halign(fa_center); draw_text(_mxo+_mw-362, _btn_y+10, "SAVE CONFIG"); draw_set_halign(fa_left);
    }

    // Save
    var _s_hov = (_mx > _mxo+_mw-280 && _mx < _mxo+_mw-150 && _my > _btn_y && _my < _btn_y+40);
    draw_set_color(_s_hov ? c_white : make_color_rgb(50,200,50));
    draw_rectangle(_mxo+_mw-280, _btn_y, _mxo+_mw-150, _btn_y+40, false);
    draw_set_color(_s_hov ? make_color_rgb(50,200,50) : c_white); draw_text(_mxo+_mw-240, _btn_y+10, "SAVE");
    // Cancel
    var _c_hov = (_mx > _mxo+_mw-140 && _mx < _mxo+_mw-30 && _my > _btn_y && _my < _btn_y+40);
    draw_set_color(_c_hov ? c_white : make_color_rgb(200,50,50));
    draw_rectangle(_mxo+_mw-140, _btn_y, _mxo+_mw-30, _btn_y+40, false);
    draw_set_color(_c_hov ? make_color_rgb(200,50,50) : c_white); draw_text(_mxo+_mw-105, _btn_y+10, "CANCEL");

}

if (scene_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _mw = 700; var _mh = 450; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    draw_set_color(make_color_rgb(40, 40, 50)); draw_rectangle(_mxo, _myo, _mxo+_mw, _myo+_mh, false);
    draw_set_color(c_aqua); draw_rectangle(_mxo, _myo, _mxo+_mw, _myo+_mh, true);
    
    if (array_length(all_scenes) == 0) {
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        draw_text_ext(_mxo + _mw/2, _myo + _mh/2 - 40, "No background scenes found!\n\nIf you just packed the scenes, please reload this project in GameMaker IDE (File -> Recent Projects -> Hollywood High) so the IDE registers the new 'scenes.pack' included file.", 22, 600);
        draw_set_halign(fa_left);
    }
    
    var _max_h = 320; var _list_h = array_length(all_scenes) * 40; var _lw = 300;
    var _hov_idx = -1;
    gpu_set_scissor(_mxo+20, _myo+60, _lw, _max_h);
    for (var i = 0; i < array_length(all_scenes); i++) {
        var _by = _myo + 60 + (i * 40) + scene_modal_scroll_y;
        if (_by + 35 < _myo+60 || _by > _myo+60+_max_h) continue;
        var _hov = (_mx > _mxo+20 && _mx < _mxo+20+_lw && _my > _by && _my < _by+35);
        if (_hov) _hov_idx = i;
        draw_set_color(_hov ? make_color_rgb(60,60,100) : make_color_rgb(30,30,40));
        draw_rectangle(_mxo+20, _by, _mxo+20+_lw, _by+35, false);
        draw_set_color(c_white); draw_text(_mxo+30, _by+8, all_scenes[i].name);
    }
    gpu_set_scissor(0,0,1280,960);
    
    // Scrollbar for Scene Modal
    if (_list_h > _max_h) {
        var _bar_h = (_max_h / _list_h) * _max_h;
        var _bar_y = (_myo+60) + (-scene_modal_scroll_y / _list_h) * _max_h;
        draw_set_color(make_color_rgb(50, 50, 60));
        draw_rectangle(_mxo+20+_lw+5, _myo+60, _mxo+20+_lw+15, _myo+60+_max_h, false); // Track
        draw_set_color(make_color_rgb(120, 120, 140));
        draw_rectangle(_mxo+20+_lw+5, _bar_y, _mxo+20+_lw+15, _bar_y + _bar_h, false); // Bar
    }
    
    var _pre_x = _mxo + 350; var _pre_y = _myo + 60; var _pre_w = 320; var _pre_h = 320;
    draw_set_color(c_black); draw_rectangle(_pre_x, _pre_y, _pre_x+_pre_w, _pre_y+_pre_h, false);
    if (_hov_idx != -1) {
        var _iname = all_scenes[_hov_idx].internal_name;
        var _spr = get_scene_sprite(_iname);
        var _mask_spr = get_scene_sprite(_iname + "_mask");
        if (_spr != -1) {
            var _sc = min(_pre_w/sprite_get_width(_spr), _pre_h/sprite_get_height(_spr)) * 0.9;
            var _dx = _pre_x + (_pre_w - sprite_get_width(_spr)*_sc)/2;
            var _dy = _pre_y + (_pre_h - sprite_get_height(_spr)*_sc)/2;
            draw_sprite_ext(_spr, 0, _dx, _dy, _sc, _sc, 0, c_white, 1);
            if (_mask_spr != -1) draw_sprite_ext(_mask_spr, 0, _dx, _dy, _sc, _sc, 0, c_white, 1);
        }
    }
	var _c_y = _myo + _mh - 50;
	var _can_hov = (_mx > _mxo+20 && _mx < _mxo+_mw-20 && _my > _c_y && _my < _c_y+35);
	draw_set_color(_can_hov ? make_color_rgb(200,50,50) : make_color_rgb(150,30,30));
	draw_rectangle(_mxo+20, _c_y, _mxo+_mw-20, _c_y+35, false);
	draw_set_color(c_white); draw_text(_mxo+(_mw/2)-20, _c_y+8, "CANCEL");
}

if (action_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _mw = 900; var _mh = 550; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    draw_set_color(make_color_rgb(40, 40, 50)); draw_rectangle(_mxo, _myo, _mxo+_mw, _myo+_mh, false);
    draw_set_color(c_aqua); draw_rectangle(_mxo, _myo, _mxo+_mw, _myo+_mh, true);
    
    draw_set_color(c_aqua); draw_text(_mxo + 20, _myo + 20, "CHARACTER ACTIONS");
    draw_line(_mxo + 20, _myo + 45, _mxo + 250, _myo + 45);

    for (var i = 0; i < array_length(all_actions); i++) {
        var _is_gen = (all_actions[i].category == "general");
        
        if (_is_gen && i > 0 && all_actions[i-1].category != "general") {
            draw_set_color(c_aqua); draw_text(_mxo + 20, _myo + 60 + (i * 45), "GENERAL ACTIONS");
            draw_line(_mxo + 20, _myo + 85 + (i * 45), _mxo + 250, _myo + 85 + (i * 45));
        }

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
        
        var _hov = (!_disabled && _mx > _mxo+20 && _mx < _mxo+250 && _my > _by && _my < _by+40);
        var _col = make_color_rgb(30,30,40);
        if (_disabled) _col = make_color_rgb(20,20,25);
        else if (action_modal_selected_idx == i) _col = make_color_rgb(80,80,150);
        else if (_hov) _col = make_color_rgb(60,60,80);
        
        draw_set_color(_col);
        draw_rectangle(_mxo+20, _by, _mxo+250, _by+40, false);
        draw_set_color(_disabled ? c_gray : c_white); draw_text(_mxo+30, _by+10, string_upper(all_actions[i].name));
    }
    
    // OK / Cancel Buttons
    var _can_proceed = true;
    if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "play sfx") {
        if (action_modal_sfx_folder_idx == -1 || action_modal_sfx_file_idx == -1) _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "display title") {
        if (action_modal_title_text == "") _can_proceed = false;
    }
    
    var _ok_locked = (action_modal_locked && _can_proceed);
    var _ok_hov = (_ok_locked && _mx > _mxo+_mw-280 && _mx < _mxo+_mw-150 && _my > _myo+_mh-50 && _my < _myo+_mh-15);
    draw_set_color(_ok_locked ? (_ok_hov ? make_color_rgb(50,200,50) : make_color_rgb(30,150,30)) : make_color_rgb(50,50,60));
    draw_rectangle(_mxo+_mw-280, _myo+_mh-50, _mxo+_mw-150, _myo+_mh-15, false);
    draw_set_color(_ok_locked ? c_white : c_gray); draw_text(_mxo+_mw-230, _myo+_mh-42, "OK");
    
    var _can_hov = (_mx > _mxo+_mw-130 && _mx < _mxo+_mw-20 && _my > _myo+_mh-50 && _my < _myo+_mh-15);
    draw_set_color(_can_hov ? make_color_rgb(200,50,50) : make_color_rgb(150,30,30));
    draw_rectangle(_mxo+_mw-130, _myo+_mh-50, _mxo+_mw-20, _myo+_mh-15, false);
    draw_set_color(c_white); draw_text(_mxo+_mw-110, _myo+_mh-42, "CANCEL");

    // Description Box
    draw_set_color(make_color_rgb(30,30,40));
    draw_rectangle(_mxo+280, _myo+60, _mxo+880, _myo+480, false);
    if (action_modal_selected_idx != -1) {
        draw_set_color(c_white);
        draw_text_ext(_mxo+290, _myo+70, all_actions[action_modal_selected_idx].desc, 25, 580);
        
        if (all_actions[action_modal_selected_idx].name == "wait") {
            var _wx = _mxo + 320; var _wy = _myo + 170;
            var _sw = 400;
            
            draw_set_color(c_aqua); draw_text(_wx, _wy, "PARAMETERS");
            draw_line(_wx, _wy + 25, _wx + _sw + 80, _wy + 25);
            
            draw_set_color(c_white);
            draw_text(_wx, _wy + 40, "Wait Duration:");
            
            var _ty = _wy + 80;

            // Arrows
            var _l_hov = (_mx > _wx - 5 && _mx < _wx + 25 && _my > _ty - 10 && _my < _ty + 35);
            draw_set_color(_l_hov ? c_aqua : c_gray);
            draw_text(_wx, _ty, "<");

            var _r_hov = (_mx > _wx + _sw + 35 && _mx < _wx + _sw + 75 && _my > _ty - 10 && _my < _ty + 35);
            draw_set_color(_r_hov ? c_aqua : c_gray);
            draw_text(_wx + _sw + 50, _ty, ">");

            // Slider Track
            draw_set_color(make_color_rgb(60, 60, 80));
            draw_rectangle(_wx + 30, _ty + 8, _wx + 30 + _sw, _ty + 13, false);
            
            // Slider Handle
            var _perc = (action_modal_wait_duration - 0.1) / 9.9;
            var _hx = _wx + 30 + (_perc * _sw);
            draw_set_color(c_aqua);
            draw_circle(_hx, _ty + 10, 8, false);
            
            draw_set_color(c_white);
            draw_text(_wx + 20, _wy + 115, string(action_modal_wait_duration) + " seconds");
        } else if (all_actions[action_modal_selected_idx].name == "play sfx") {
            var _wx = _mxo + 300; var _wy = _myo + 130;
            
            draw_set_color(c_aqua); draw_text(_wx, _wy, "PARAMETERS");
            draw_line(_wx, _wy + 25, _wx + 560, _wy + 25);
            
            var _fx = _mxo + 280; var _fy = _myo + 80; var _fw = 250; var _fh = 350;
            var _lx = _mxo + 550; var _ly = _myo + 80; var _lw = 320; var _lh = 350;

            // FOLDERS
            draw_set_color(c_white); draw_text(_fx + 10, _wy + 40, "Category:");
            draw_set_color(make_color_rgb(20, 20, 25)); draw_rectangle(_fx + 10, _wy + 65, _fx + 240, _wy + 280, false);
            
            gpu_set_scissor(_fx + 10, _wy + 65, 230, 215);
            for (var f = 0; f < array_length(action_modal_sfx_folders); f++) {
                var _fby = _wy + 65 + (f * 30) - action_modal_sfx_scroll_y;
                var _is_sel = (action_modal_sfx_folder_idx == f);
                var _f_hov = (!action_modal_sfx_dragging_folder && _mx > _fx + 10 && _mx < _fx + 230 && _my > _fby && _my < _fby + 30 && _my > _wy + 65 && _my < _wy + 280);
                draw_set_color(_is_sel ? make_color_rgb(80, 80, 150) : (_f_hov ? make_color_rgb(50, 50, 70) : make_color_rgb(30, 30, 40)));
                draw_rectangle(_fx + 10, _fby, _fx + 240, _fby + 30, false);
                draw_set_color(_is_sel ? c_white : c_ltgray); draw_text(_fx + 15, _fby + 5, string_upper(action_modal_sfx_folders[f]));
            }
            gpu_set_scissor(0, 0, 1280, 960);
            
            // FILES
            draw_set_color(c_white); draw_text(_lx - 10, _wy + 40, "Sound Effect:");
            draw_set_color(make_color_rgb(20, 20, 25)); draw_rectangle(_lx - 10, _wy + 65, _lx + 310, _wy + 280, false);
            
            gpu_set_scissor(_lx - 10, _wy + 65, 320, 215);
            if (action_modal_sfx_folder_idx != -1) {
                for (var f = 0; f < array_length(action_modal_sfx_files); f++) {
                    var _fby = _wy + 65 + (f * 30) - action_modal_sfx_files_scroll_y;
                    var _is_sel = (action_modal_sfx_file_idx == f);
                    var _f_hov = (!action_modal_sfx_dragging_file && _mx > _lx - 10 && _mx < _lx + 300 && _my > _fby && _my < _fby + 30 && _my > _wy + 65 && _my < _wy + 280);
                    draw_set_color(_is_sel ? make_color_rgb(80, 80, 150) : (_f_hov ? make_color_rgb(50, 50, 70) : make_color_rgb(30, 30, 40)));
                    draw_rectangle(_lx - 10, _fby, _lx + 310, _fby + 30, false);
                    draw_set_color(_is_sel ? c_white : c_ltgray); draw_text(_lx - 5, _fby + 5, string_replace(string_upper(action_modal_sfx_files[f]), ".WAV", ""));
                }
            }
            gpu_set_scissor(0, 0, 1280, 960);
            
            // FOLDER SCROLLBAR
            _fh = 215; var _ftot = array_length(action_modal_sfx_folders) * 30;
            if (_ftot > _fh) {
                var _sb_x = _fx + 240 - 8;
                draw_set_color(make_color_rgb(40, 40, 50)); draw_rectangle(_sb_x, _wy + 65, _sb_x + 8, _wy + 280, false);
                var _bar_h = (_fh / _ftot) * _fh;
                var _bar_y = (_wy + 65) + (action_modal_sfx_scroll_y / _ftot) * _fh;
                draw_set_color(make_color_rgb(100, 100, 120)); draw_rectangle(_sb_x, _bar_y, _sb_x + 8, _bar_y + _bar_h, false);
            }
            
            // FILE SCROLLBAR
            _lh = 215; var _ltot = array_length(action_modal_sfx_files) * 30;
            if (_ltot > _lh) {
                var _sb_x = _lx + 310 - 8;
                draw_set_color(make_color_rgb(40, 40, 50)); draw_rectangle(_sb_x, _wy + 65, _sb_x + 8, _wy + 280, false);
                var _bar_h = (_lh / _ltot) * _lh;
                var _bar_y = (_wy + 65) + (action_modal_sfx_files_scroll_y / _ltot) * _lh;
                draw_set_color(make_color_rgb(100, 100, 120)); draw_rectangle(_sb_x, _bar_y, _sb_x + 8, _bar_y + _bar_h, false);
            }

            // TEST BUTTON
            var _tx = _mxo + _mw - 150; var _ty = _myo + _mh - 120;
            var _can_test = (action_modal_sfx_folder_idx != -1 && action_modal_sfx_file_idx != -1);
            var _t_hov = (_can_test && _mx > _tx && _mx < _tx + 120 && _my > _ty && _my < _ty + 35);
            draw_set_color(_can_test ? (_t_hov ? make_color_rgb(100, 100, 200) : make_color_rgb(60, 60, 150)) : make_color_rgb(40, 40, 50));
            draw_rectangle(_tx, _ty, _tx + 120, _ty + 35, false);
            draw_set_color(_can_test ? c_white : c_gray); draw_text(_tx + 35, _ty + 8, "TEST");
        } else if (all_actions[action_modal_selected_idx].name == "display title") {
            var _wx = _mxo + 300; var _wy = _myo + 100;
            
            draw_set_color(c_aqua); draw_text(_wx, _wy, "PARAMETERS");
            draw_line(_wx, _wy + 25, _wx + 560, _wy + 25);
            
            draw_set_color(c_white); draw_text(_wx, _wy + 40, "Title Text (Max 100 chars, Auto-wraps):");
            draw_set_color(make_color_rgb(20, 20, 25)); draw_rectangle(_wx, _wy + 65, _wx + 560, _wy + 150, false);
            draw_set_color(c_white); draw_text_ext(_wx + 10, _wy + 75, action_modal_title_text + (cursor_visible ? "|" : ""), 25, 540);
            
            draw_set_color(c_white); draw_text(_wx, _wy + 170, "Duration:");
            var _sw = 300; var _sx = _wx + 100; var _sy = _wy + 170;
            
            var _l_hov = (_mx > _sx - 35 && _mx < _sx - 5 && _my > _sy - 10 && _my < _sy + 35);
            draw_set_color(_l_hov ? c_aqua : c_gray); draw_text(_sx - 35, _sy, "<");
            var _r_hov = (_mx > _sx + _sw + 5 && _mx < _sx + _sw + 45 && _my > _sy - 10 && _my < _sy + 35);
            draw_set_color(_r_hov ? c_aqua : c_gray); draw_text(_sx + _sw + 20, _sy, ">");

            draw_set_color(make_color_rgb(60, 60, 80)); draw_rectangle(_sx, _sy + 8, _sx + _sw, _sy + 13, false);
            var _perc = (action_modal_wait_duration - 0.1) / 9.9;
            draw_set_color(c_aqua); draw_circle(_sx + (_perc * _sw), _sy + 10, 8, false);
            draw_set_color(c_white); draw_text(_sx + _sw + 50, _sy, string(action_modal_wait_duration) + "s");

            var draw_dropdown = function(dx, dy, label, val_idx, opts_array, is_open) {
                draw_set_color(c_white); draw_text(dx, dy, label);
                var _bx = dx + 60; var _bw = 200;
                draw_set_color(is_open ? make_color_rgb(60,60,80) : make_color_rgb(40,40,50));
                draw_rectangle(_bx, dy, _bx + _bw, dy + 25, false);
                draw_set_color(c_aqua); draw_rectangle(_bx, dy, _bx + _bw, dy + 25, true);
                draw_set_color(c_white); draw_text(_bx + 10, dy + 3, opts_array[val_idx]);
                draw_text(_bx + _bw - 20, dy + 3, "v");
                
                if (is_open) {
                    draw_set_color(make_color_rgb(30,30,40)); draw_rectangle(_bx, dy + 25, _bx + _bw, dy + 25 + (array_length(opts_array) * 30), false);
                    draw_set_color(c_aqua); draw_rectangle(_bx, dy + 25, _bx + _bw, dy + 25 + (array_length(opts_array) * 30), true);
                    for (var d = 0; d < array_length(opts_array); d++) {
                        var _dhov = (mouse_x > _bx && mouse_x < _bx + _bw && mouse_y > dy + 25 + (d * 30) && mouse_y < dy + 25 + ((d+1) * 30));
                        if (_dhov) { draw_set_color(make_color_rgb(80,80,120)); draw_rectangle(_bx, dy + 25 + (d * 30), _bx + _bw, dy + 25 + ((d+1) * 30), false); }
                        draw_set_color(d == val_idx ? c_yellow : c_white);
                        draw_text(_bx + 10, dy + 30 + (d * 30), opts_array[d]);
                    }
                }
            };
            
            if (action_modal_dropdown_open != "align") draw_dropdown(_wx, _wy + 230, "Align:", action_modal_title_align, action_modal_title_align_opts, false);
            if (action_modal_dropdown_open != "size") draw_dropdown(_wx + 290, _wy + 230, "Size:", action_modal_title_size, action_modal_title_size_opts, false);
            if (action_modal_dropdown_open != "font") draw_dropdown(_wx, _wy + 280, "Font:", action_modal_title_font, action_modal_title_font_opts, false);
            if (action_modal_dropdown_open != "color") draw_dropdown(_wx + 290, _wy + 280, "Color:", action_modal_title_color, action_modal_title_color_opts, false);
            
            if (action_modal_dropdown_open == "align") draw_dropdown(_wx, _wy + 230, "Align:", action_modal_title_align, action_modal_title_align_opts, true);
            if (action_modal_dropdown_open == "size") draw_dropdown(_wx + 290, _wy + 230, "Size:", action_modal_title_size, action_modal_title_size_opts, true);
            if (action_modal_dropdown_open == "font") draw_dropdown(_wx, _wy + 280, "Font:", action_modal_title_font, action_modal_title_font_opts, true);
            if (action_modal_dropdown_open == "color") draw_dropdown(_wx + 290, _wy + 280, "Color:", action_modal_title_color, action_modal_title_color_opts, true);
        }
    }
}

if (move_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _m_w = 400; var _m_h = 420;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    draw_set_color(make_color_rgb(30, 30, 40)); draw_roundrect_ext(_m_x, _m_y, _m_x+_m_w, _m_y+_m_h, 20, 20, false);
    draw_set_color(c_aqua); draw_roundrect_ext(_m_x, _m_y, _m_x+_m_w, _m_y+_m_h, 20, 20, true);
    draw_set_color(c_white); draw_text(_m_x + 20, _m_y + 20, "MOVEMENT PARAMETERS");
    
    for (var i = 0; i < array_length(move_speed_labels); i++) {
        var _by = _m_y + 80 + (i * 45);
        var _is_sel = (move_modal_temp_speed_index == i);
        var _hov = (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _by && _my < _by + 40);
        
        draw_set_color(_is_sel ? c_aqua : (_hov ? make_color_rgb(60,60,80) : make_color_rgb(45,45,55)));
        draw_rectangle(_m_x + 50, _by, _m_x + 350, _by + 40, false);
        draw_set_color(_is_sel ? c_black : c_white);
        draw_text(_m_x + 60, _by + 10, move_speed_labels[i]);
    }
    
    // Moonwalk Toggle
    var _m_hov = (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _m_y + 310 && _my < _m_y + 345);
    draw_set_color(_m_hov ? c_white : c_ltgray);
    draw_rectangle(_m_x + 50, _m_y + 310, _m_x + 70, _m_y + 330, true);
    if (move_modal_temp_moonwalk) { draw_set_color(c_orange); draw_rectangle(_m_x + 54, _m_y + 314, _m_x + 66, _m_y + 326, false); }
    draw_set_color(c_white); draw_text(_m_x + 80, _m_y + 312, "ENABLE MOONWALK");
    
    // OK Button
    var _ok_hov = (_mx > _m_x + 40 && _mx < _m_x + 180 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20);
    draw_set_color(_ok_hov ? c_white : c_ltgray);
    draw_rectangle(_m_x + 40, _m_y + _m_h - 60, _m_x + 180, _m_y + _m_h - 20, false);
    draw_set_color(c_black); draw_text(_m_x + 95, _m_y + _m_h - 50, "OK");
    
    // Cancel Button
    var _can_hov = (_mx > _m_x + 220 && _mx < _m_x + 360 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20);
    draw_set_color(_can_hov ? c_white : c_ltgray);
    draw_rectangle(_m_x + 220, _m_y + _m_h - 60, _m_x + 360, _m_y + _m_h - 20, false);
    draw_set_color(c_black); draw_text(_m_x + 255, _m_y + _m_h - 50, "CANCEL");
}

if (pose_expr_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _m_w = 1060; var _m_h = 520;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    draw_set_color(make_color_rgb(20, 22, 35));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 16, 16, false);
    draw_set_color(make_color_rgb(70, 95, 200));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 16, 16, true);

    // Section labels
    draw_set_color(c_ltgray);
    draw_text(_m_x + 18, _m_y + 14, "POSE");
    draw_text(_m_x + 232, _m_y + 14, "EXPRESSION");

    // ── POSE LIST ──
    for (var i = 1; i <= 4; i++) {
        var _by = _m_y + 38 + (i - 1) * 58;
        var _hov_p = (_mx > _m_x + 12 && _mx < _m_x + 208 && _my > _by && _my < _by + 50);
        var _locked_p = (pose_modal_locked_pose == i);
        draw_set_color(_locked_p ? make_color_rgb(40, 60, 130) : (_hov_p ? make_color_rgb(48, 52, 78) : make_color_rgb(28, 30, 48)));
        draw_roundrect_ext(_m_x + 12, _by, _m_x + 208, _by + 50, 5, 5, false);
        if (_locked_p) { draw_set_color(make_color_rgb(80, 120, 255)); draw_roundrect_ext(_m_x + 12, _by, _m_x + 208, _by + 50, 5, 5, true); }
        draw_set_color(_locked_p ? c_white : c_ltgray);
        var _plbl = get_pose_label(selected_character_index, i);
        var _plbl_max_w = 178;
        var _plbl_sc = min(1.0, _plbl_max_w / max(1, string_width(_plbl)));
        gpu_set_texfilter(true);
        draw_text_transformed(_m_x + 22, _by + 16, _plbl, _plbl_sc, 1, 0);
        gpu_set_texfilter(false);
    }

    // ── EXPRESSION GRID (4 cols × 5 rows) ──
    var _cols_ep = 4; var _col_w_ep = 118; var _row_h_ep = 44;
    var _gx_ep = _m_x + 228; var _gy_ep = _m_y + 38;
    for (var e = 1; e <= 20; e++) {
        var _col = (e - 1) % _cols_ep; var _row = floor((e - 1) / _cols_ep);
        var _ex = _gx_ep + _col * _col_w_ep; var _ey = _gy_ep + _row * _row_h_ep;
        var _hov_e = (_mx > _ex + 2 && _mx < _ex + _col_w_ep - 2 && _my > _ey + 2 && _my < _ey + _row_h_ep - 2);
        var _locked_e = (expression_modal_locked_expr == e);
        draw_set_color(_locked_e ? make_color_rgb(35, 85, 48) : (_hov_e ? make_color_rgb(40, 65, 48) : make_color_rgb(22, 32, 26)));
        draw_rectangle(_ex + 2, _ey + 2, _ex + _col_w_ep - 2, _ey + _row_h_ep - 2, false);
        if (_locked_e) { draw_set_color(c_lime); draw_rectangle(_ex + 2, _ey + 2, _ex + _col_w_ep - 2, _ey + _row_h_ep - 2, true); draw_rectangle(_ex + 3, _ey + 3, _ex + _col_w_ep - 3, _ey + _row_h_ep - 3, true); }
        draw_set_color(_locked_e ? c_white : c_ltgray);
        draw_set_halign(fa_center); draw_text(_ex + _col_w_ep / 2, _ey + _row_h_ep / 2 - 8, mood_names[e - 1]); draw_set_halign(fa_left);
    }

    // ── PREVIEW (full body) ──
    var _pre_x = _m_x + 706; var _pre_y = _m_y + 14;
    var _pre_w = 340; var _pre_h = 460;
    draw_set_color(make_color_rgb(12, 14, 22));
    draw_roundrect_ext(_pre_x, _pre_y, _pre_x + _pre_w, _pre_y + _pre_h, 8, 8, false);
    draw_set_color(make_color_rgb(40, 50, 90));
    draw_roundrect_ext(_pre_x, _pre_y, _pre_x + _pre_w, _pre_y + _pre_h, 8, 8, true);
    if (selected_character_index != -1) {
        var _prev_pose = (pose_modal_temp_pose != -1) ? pose_modal_temp_pose : 1;
        var _prev_expr = (expression_modal_temp_expr != -1) ? expression_modal_temp_expr : 1;
        var _aface = char_facings[selected_character_index];
        for (var pa = 0; pa < array_length(preview_actors); pa++) {
            if (preview_actors[pa].char_index == selected_character_index) {
                _aface = variable_struct_exists(preview_actors[pa], "facing") ? preview_actors[pa].facing : _aface; break;
            }
        }
        var _layers = get_composite_character_sprite(selected_character_index, _prev_pose, _prev_expr, _aface);
        if (_layers[0].spr != -1) {
            var _csw = sprite_get_width(_layers[0].spr); var _csh = sprite_get_height(_layers[0].spr);
            var _min_dy = 0; var _max_dy_end = _csh;
            for (var _pli = 1; _pli < 4; _pli++) {
                if (_layers[_pli].spr != -1) { _min_dy = min(_min_dy, _layers[_pli].dy); _max_dy_end = max(_max_dy_end, _layers[_pli].dy + sprite_get_height(_layers[_pli].spr)); }
            }
            var _total_h_pm = _max_dy_end - _min_dy;
            var _sc = min((_pre_h - 20) / max(1, _total_h_pm), (_pre_w - 20) / max(1, _csw), 3.5);
            var _draw_x = _pre_x + (_pre_w - _csw * _sc) / 2;
            var _draw_y = _pre_y + 10 - _min_dy * _sc;
            draw_composite_character_ext(_layers, _draw_x, _draw_y, _sc, 1, c_white, false);
        }
    }

    // ── APPLY / CANCEL ──
    var _can_apply = (pose_modal_locked_pose != -1 && expression_modal_locked_expr != -1);
    var _ap_x = _m_x + 228; var _btn_y_pe = _m_y + _m_h - 52; var _btn_w_pe = 210; var _btn_h_pe = 40;
    var _ap_hov = (_can_apply && _mx > _ap_x && _mx < _ap_x + _btn_w_pe && _my > _btn_y_pe && _my < _btn_y_pe + _btn_h_pe);
    draw_set_color(_can_apply ? (_ap_hov ? c_white : make_color_rgb(140, 200, 140)) : make_color_rgb(55, 55, 55));
    draw_rectangle(_ap_x, _btn_y_pe, _ap_x + _btn_w_pe, _btn_y_pe + _btn_h_pe, false);
    draw_set_color(_can_apply ? c_black : make_color_rgb(80, 80, 80));
    draw_set_halign(fa_center); draw_text(_ap_x + _btn_w_pe / 2, _btn_y_pe + 11, "APPLY"); draw_set_halign(fa_left);
    var _cx_pe = _ap_x + _btn_w_pe + 14;
    var _can_hov = (_mx > _cx_pe && _mx < _cx_pe + _btn_w_pe && _my > _btn_y_pe && _my < _btn_y_pe + _btn_h_pe);
    draw_set_color(_can_hov ? c_white : c_ltgray);
    draw_rectangle(_cx_pe, _btn_y_pe, _cx_pe + _btn_w_pe, _btn_y_pe + _btn_h_pe, false);
    draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_cx_pe + _btn_w_pe / 2, _btn_y_pe + 11, "CANCEL"); draw_set_halign(fa_left);
}

// ── EXPRESSION TILE CONFIGURATOR MODAL ──
if (expr_cfg_open) {
    draw_set_color(c_black); draw_set_alpha(0.78);
    draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);

    var _m_x = 85; var _m_y = 55; var _m_w = 1110; var _m_h = 770;
    draw_set_color(make_color_rgb(16, 20, 30));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 10, 10, false);
    draw_set_color(make_color_rgb(70, 110, 200));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 10, 10, true);

    var _lx = _m_x + 12; var _ly = _m_y + 12;
    var _c_ec = characters[expr_cfg_char_idx];

    // Load offsets.json for left panel total offset displays
    var _folder_ec2 = datafiles_path + "actors/" + _c_ec.name + "/";
    var _off_data = undefined;
    if (file_exists(_folder_ec2 + "offsets.json")) {
        var _s = ""; var _f = file_text_open_read(_folder_ec2 + "offsets.json");
        while (!file_text_eof(_f)) { _s += file_text_readln(_f); }
        file_text_close(_f); _off_data = json_parse(_s);
    }

    // Title
    draw_set_color(c_white);
    draw_text(_lx, _ly, "EXPRESSION TILE CONFIGURATOR  [DEBUG]");

    // Character navigation
    var _nav_y = _ly + 28;
    var _c_prev_hov = (!theater_mode && _mx > _lx && _mx < _lx + 28 && _my > _nav_y && _my < _nav_y + 28);
    var _c_next_hov = (!theater_mode && _mx > _lx + 252 && _mx < _lx + 280 && _my > _nav_y && _my < _nav_y + 28);
    draw_set_color(_c_prev_hov ? c_yellow : c_ltgray);
    draw_rectangle(_lx, _nav_y, _lx + 27, _nav_y + 27, false);
    draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_lx + 13, _nav_y + 5, "<");
    draw_set_color(_c_next_hov ? c_yellow : c_ltgray);
    draw_rectangle(_lx + 253, _nav_y, _lx + 280, _nav_y + 27, false);
    draw_set_color(c_black); draw_text(_lx + 266, _nav_y + 5, ">"); draw_set_halign(fa_left);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_lx + 140, _nav_y + 5, _c_ec.name); draw_set_halign(fa_left);

    // Pose buttons
    var _pose_y = _nav_y + 36;
    draw_set_color(c_ltgray); draw_text(_lx, _pose_y + 3, "POSE");
    for (var _pi = 1; _pi <= 4; _pi++) {
        var _pbx = _lx + 45 + (_pi - 1) * 58;
        var _pi_hov = (!theater_mode && _mx > _pbx && _mx < _pbx + 48 && _my > _pose_y && _my < _pose_y + 28);
        var _p_sel = (expr_cfg_pose == _pi);
        draw_set_color(_p_sel ? make_color_rgb(70, 110, 200) : (_pi_hov ? make_color_rgb(45, 55, 80) : make_color_rgb(28, 32, 48)));
        draw_roundrect_ext(_pbx, _pose_y, _pbx + 48, _pose_y + 28, 4, 4, false);
        draw_set_color(_p_sel ? c_white : c_ltgray);
        draw_set_halign(fa_center); draw_text(_pbx + 24, _pose_y + 5, string(_pi)); draw_set_halign(fa_left);
    }

    // Direction toggle
    var _dir_y = _pose_y + 36;
    var _dir_labels = ["NATURAL", "FLIPPED"];
    for (var _di = 0; _di <= 1; _di++) {
        var _dbx = _lx + _di * 142;
        var _d_sel = (expr_cfg_high == (_di == 1));
        var _di_hov = (!theater_mode && _mx > _dbx && _mx < _dbx + 132 && _my > _dir_y && _my < _dir_y + 28);
        draw_set_color(_d_sel ? make_color_rgb(50, 100, 60) : (_di_hov ? make_color_rgb(35, 50, 40) : make_color_rgb(25, 30, 28)));
        draw_roundrect_ext(_dbx, _dir_y, _dbx + 132, _dir_y + 28, 4, 4, false);
        draw_set_color(_d_sel ? c_lime : c_ltgray);
        draw_set_halign(fa_center); draw_text(_dbx + 66, _dir_y + 5, _dir_labels[_di]); draw_set_halign(fa_left);
    }

    // Layer rows
    var _pc_ec = expr_cfg_get_pc();
    var _layer_y0 = _dir_y + 38;
    var _layer_names_ec = ["BODY", "FACE", "EYES", "MOUTH"];
    var _layer_cols = [make_color_rgb(160,120,60), make_color_rgb(100,160,255), make_color_rgb(80,200,80), make_color_rgb(255,160,60)];
    
    var _ai_ec = variable_struct_exists(_c_ec, "act_index") ? _c_ec.act_index : 1;
    var _sfx_off_ec = expr_cfg_high ? 50 : 0;
    var _pfx_ec = string(_ai_ec) + string(expr_cfg_pose);
    var _ec_mood_map = [0, 2, 3, 1, 0, 1, 1, 1, 1, 0, 2, 1, 1, 1, 0, 3, 1, 0, 1, 2];
    var _derived_mood_ec = _ec_mood_map[clamp(expr_cfg_preview_expr - 1, 0, 19)];

    for (var _li = 0; _li <= 3; _li++) {
        var _lby = _layer_y0 + _li * 52;
        var _l_sel = (expr_cfg_selected_layer == _li);
        var _l_hov = (!theater_mode && _mx > _lx && _mx < _lx + 280 && _my > _lby && _my < _lby + 46);
        draw_set_color(_l_sel ? make_color_rgb(28, 40, 68) : (_l_hov ? make_color_rgb(22, 26, 40) : make_color_rgb(18, 20, 30)));
        draw_roundrect_ext(_lx, _lby, _lx + 280, _lby + 46, 5, 5, false);
        draw_set_color(_layer_cols[_li]);
        draw_roundrect_ext(_lx, _lby, _lx + 280, _lby + 46, 5, 5, true);
        draw_set_color(c_white); draw_text(_lx + 8, _lby + 4, _layer_names_ec[_li]);
        if (_pc_ec != undefined) {
            var _ldx = 0; var _ldy = 0;
            
            // Resolve currently active file for this layer
            var _cur_file_li = "";
            var _layer_key_li = "";
            switch (_li) {
                case 0:
                    _cur_file_li = _pc_ec.body_file;
                    _layer_key_li = "body";
                    break;
                case 1:
                    _cur_file_li = _pc_ec.face_file;
                    _layer_key_li = "face";
                    break;
                case 2:
                    var _eyes_file_li = "";
                    if (_pc_ec != undefined && variable_struct_exists(_pc_ec, "eyes_files")) {
                        var _ef_li = _pc_ec.eyes_files;
                        var _ef_ek = string(expr_cfg_preview_expr);
                        if (variable_struct_exists(_ef_li, _ef_ek) && _ef_li[$ _ef_ek] != "") _eyes_file_li = _ef_li[$ _ef_ek];
                    }
                    if (_eyes_file_li == "") {
                        var _eyes_n_li = 10 + expr_cfg_preview_expr + _sfx_off_ec;
                        _eyes_file_li = "pose_" + _pfx_ec + ((_eyes_n_li < 10 ? "0" : "") + string(_eyes_n_li)) + ".png";
                    }
                    _cur_file_li = _eyes_file_li;
                    _layer_key_li = "eyes";
                    break;
                case 3:
                    var _mouth_file_li = "";
                    if (_pc_ec != undefined && variable_struct_exists(_pc_ec, "mouth_files")) {
                        var _mf_li = _pc_ec.mouth_files;
                        var _expr_key = string(expr_cfg_preview_expr);
                        var _mood_key = string(_derived_mood_ec);
                        if (variable_struct_exists(_mf_li, _expr_key) && _mf_li[$ _expr_key] != "") {
                            _mouth_file_li = _mf_li[$ _expr_key];
                        } else if (variable_struct_exists(_mf_li, _mood_key) && _mf_li[$ _mood_key] != "") {
                            _mouth_file_li = _mf_li[$ _mood_key];
                        }
                    }
                    if (_mouth_file_li == "") {
                        var _mouth_n_li = 31 + _derived_mood_ec + _sfx_off_ec;
                        _mouth_file_li = "pose_" + _pfx_ec + ((_mouth_n_li < 10 ? "0" : "") + string(_mouth_n_li)) + ".png";
                    }
                    _cur_file_li = _mouth_file_li;
                    _layer_key_li = "mouth";
                    break;
            }
            
            // Base offset from offsets.json
            var _lo_ox_li = 0; var _lo_oy_li = 0;
            if (_off_data != undefined && _pc_ec.body_file != "") {
                var _bk_li = string_replace(_pc_ec.body_file, ".png", "");
                if (variable_struct_exists(_off_data, _bk_li)) { var _bv_li = _off_data[$ _bk_li]; _lo_ox_li = _bv_li[0]; _lo_oy_li = _bv_li[1]; }
            }
            
            var _file_ok_li = string_replace(_cur_file_li, ".png", "");
            if (_off_data != undefined && variable_struct_exists(_off_data, _file_ok_li)) {
                var _fov_li = _off_data[$ _file_ok_li]; _ldx = _fov_li[0] - _lo_ox_li; _ldy = _fov_li[1] - _lo_oy_li;
            }
            
            // Add custom nudge delta offset
            var _expr_key_li = string(expr_cfg_preview_expr);
            if ((_layer_key_li == "eyes" || _layer_key_li == "mouth") && variable_struct_exists(_pc_ec, _layer_key_li + "_dx_expr_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_li + "_dx_expr_offsets"], _expr_key_li)) {
                _ldx += _pc_ec[$ _layer_key_li + "_dx_expr_offsets"][$ _expr_key_li];
            } else if (variable_struct_exists(_pc_ec, _layer_key_li + "_dx_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_li + "_dx_offsets"], _cur_file_li)) {
                _ldx += _pc_ec[$ _layer_key_li + "_dx_offsets"][$ _cur_file_li];
            } else if (variable_struct_exists(_pc_ec, _layer_key_li + "_dx")) {
                _ldx = _pc_ec[$ _layer_key_li + "_dx"];
            }
            if ((_layer_key_li == "eyes" || _layer_key_li == "mouth") && variable_struct_exists(_pc_ec, _layer_key_li + "_dy_expr_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_li + "_dy_expr_offsets"], _expr_key_li)) {
                _ldy += _pc_ec[$ _layer_key_li + "_dy_expr_offsets"][$ _expr_key_li];
            } else if (variable_struct_exists(_pc_ec, _layer_key_li + "_dy_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_li + "_dy_offsets"], _cur_file_li)) {
                _ldy += _pc_ec[$ _layer_key_li + "_dy_offsets"][$ _cur_file_li];
            } else if (variable_struct_exists(_pc_ec, _layer_key_li + "_dy")) {
                _ldy = _pc_ec[$ _layer_key_li + "_dy"];
            }
            
            draw_set_color(c_ltgray); draw_text(_lx + 8, _lby + 24, "dx:" + string(_ldx) + "  dy:" + string(_ldy));

        }
    }

    // dx/dy nudge controls for selected layer
    var _nudge_y = _layer_y0 + 4 * 52 + 6;
    if (_pc_ec != undefined) {
        var _n_ldx = 0; var _n_ldy = 0;
        
        // Resolve currently active file for selected layer
        var _cur_file_sel = "";
        var _layer_key_sel = "";
        switch (expr_cfg_selected_layer) {
            case 0:
                _cur_file_sel = _pc_ec.body_file;
                _layer_key_sel = "body";
                break;
            case 1:
                _cur_file_sel = _pc_ec.face_file;
                _layer_key_sel = "face";
                break;
            case 2:
                var _eyes_file_sel = "";
                if (_pc_ec != undefined && variable_struct_exists(_pc_ec, "eyes_files")) {
                    var _ef_sel = _pc_ec.eyes_files;
                    var _ef_ek = string(expr_cfg_preview_expr);
                    if (variable_struct_exists(_ef_sel, _ef_ek) && _ef_sel[$ _ef_ek] != "") _eyes_file_sel = _ef_sel[$ _ef_ek];
                }
                if (_eyes_file_sel == "") {
                    var _eyes_n_sel = 10 + expr_cfg_preview_expr + _sfx_off_ec;
                    _eyes_file_sel = "pose_" + _pfx_ec + ((_eyes_n_sel < 10 ? "0" : "") + string(_eyes_n_sel)) + ".png";
                }
                _cur_file_sel = _eyes_file_sel;
                _layer_key_sel = "eyes";
                break;
            case 3:
                var _mouth_file_sel = "";
                if (_pc_ec != undefined && variable_struct_exists(_pc_ec, "mouth_files")) {
                    var _mf_sel = _pc_ec.mouth_files;
                    var _expr_key = string(expr_cfg_preview_expr);
                    var _mood_key = string(_derived_mood_ec);
                    if (variable_struct_exists(_mf_sel, _expr_key) && _mf_sel[$ _expr_key] != "") {
                        _mouth_file_sel = _mf_sel[$ _expr_key];
                    } else if (variable_struct_exists(_mf_sel, _mood_key) && _mf_sel[$ _mood_key] != "") {
                        _mouth_file_sel = _mf_sel[$ _mood_key];
                    }
                }
                if (_mouth_file_sel == "") {
                    var _mouth_n_sel = 31 + _derived_mood_ec + _sfx_off_ec;
                    _mouth_file_sel = "pose_" + _pfx_ec + ((_mouth_n_sel < 10 ? "0" : "") + string(_mouth_n_sel)) + ".png";
                }
                _cur_file_sel = _mouth_file_sel;
                _layer_key_sel = "mouth";
                break;
        }
        
        var _lo_ox_sel = 0; var _lo_oy_sel = 0;
        if (_off_data != undefined && _pc_ec.body_file != "") {
            var _bk_sel = string_replace(_pc_ec.body_file, ".png", "");
            if (variable_struct_exists(_off_data, _bk_sel)) { var _bv_sel = _off_data[$ _bk_sel]; _lo_ox_sel = _bv_sel[0]; _lo_oy_sel = _bv_sel[1]; }
        }
        
        var _file_ok_sel = string_replace(_cur_file_sel, ".png", "");
        if (_off_data != undefined && variable_struct_exists(_off_data, _file_ok_sel)) {
            var _fov_sel = _off_data[$ _file_ok_sel]; _n_ldx = _fov_sel[0] - _lo_ox_sel; _n_ldy = _fov_sel[1] - _lo_oy_sel;
        }
        
        var _expr_key_sel = string(expr_cfg_preview_expr);
        if ((_layer_key_sel == "eyes" || _layer_key_sel == "mouth") && variable_struct_exists(_pc_ec, _layer_key_sel + "_dx_expr_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_sel + "_dx_expr_offsets"], _expr_key_sel)) {
            _n_ldx += _pc_ec[$ _layer_key_sel + "_dx_expr_offsets"][$ _expr_key_sel];
        } else if (variable_struct_exists(_pc_ec, _layer_key_sel + "_dx_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_sel + "_dx_offsets"], _cur_file_sel)) {
            _n_ldx += _pc_ec[$ _layer_key_sel + "_dx_offsets"][$ _cur_file_sel];
        } else if (variable_struct_exists(_pc_ec, _layer_key_sel + "_dx")) {
            _n_ldx = _pc_ec[$ _layer_key_sel + "_dx"];
        }
        if ((_layer_key_sel == "eyes" || _layer_key_sel == "mouth") && variable_struct_exists(_pc_ec, _layer_key_sel + "_dy_expr_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_sel + "_dy_expr_offsets"], _expr_key_sel)) {
            _n_ldy += _pc_ec[$ _layer_key_sel + "_dy_expr_offsets"][$ _expr_key_sel];
        } else if (variable_struct_exists(_pc_ec, _layer_key_sel + "_dy_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_sel + "_dy_offsets"], _cur_file_sel)) {
            _n_ldy += _pc_ec[$ _layer_key_sel + "_dy_offsets"][$ _cur_file_sel];
        } else if (variable_struct_exists(_pc_ec, _layer_key_sel + "_dy")) {
            _n_ldy = _pc_ec[$ _layer_key_sel + "_dy"];
        }
        
        var _axes = ["dx", "dy"]; var _vals = [_n_ldx, _n_ldy];
        for (var _ai2 = 0; _ai2 <= 1; _ai2++) {
            var _ny2 = _nudge_y + _ai2 * 34;
            draw_set_color(c_ltgray); draw_text(_lx, _ny2 + 4, _axes[_ai2] + ":");
            var _nm_hov = (!theater_mode && _mx > _lx + 30 && _mx < _lx + 58 && _my > _ny2 && _my < _ny2 + 28);
            var _np_hov = (!theater_mode && _mx > _lx + 110 && _mx < _lx + 138 && _my > _ny2 && _my < _ny2 + 28);
            draw_set_color(_nm_hov ? c_yellow : c_ltgray); draw_rectangle(_lx + 30, _ny2, _lx + 57, _ny2 + 27, false);
            draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_lx + 43, _ny2 + 4, "-"); draw_set_halign(fa_left);
            draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_lx + 84, _ny2 + 4, string(_vals[_ai2])); draw_set_halign(fa_left);
            draw_set_color(_np_hov ? c_yellow : c_ltgray); draw_rectangle(_lx + 110, _ny2, _lx + 137, _ny2 + 27, false);
            draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_lx + 123, _ny2 + 4, "+"); draw_set_halign(fa_left);
        }
        draw_set_color(make_color_rgb(60, 60, 80));
        draw_text(_lx, _nudge_y + 72, "Arrow keys: nudge 1px");
        draw_text(_lx, _nudge_y + 86, "Drag tiles in preview");
    }

    // Expression selector — drives both eyes and mouth (via mood_map)
    // 20 expressions in a 5-col × 4-row grid
    var _esel_y = _nudge_y + 110;
    draw_set_color(c_ltgray); draw_text(_lx, _esel_y, "EXPRESSION (eyes + mouth):");
    var _expr_names_short = ["HAP","SAD","ANG","COL","FLR","SHY","EMB","SUR","FRI","MSC","GUI","PAR","CON","BOR","SIL","PAN","POM","CNT","REF","WIS"];
    var _esel_mood_map    = [0, 2, 3, 1, 0, 1, 1, 1, 1, 0, 2, 1, 1, 1, 0, 3, 1, 0, 1, 2];
    var _mood_col = [make_color_rgb(255,200,60), make_color_rgb(160,160,180), make_color_rgb(255,100,80), make_color_rgb(160,220,100)];
    var _ecols = 5; var _eboxw = 52; var _eboxh = 36; var _egap = 4;
    for (var _ei = 1; _ei <= 20; _ei++) {
        var _ecol = (_ei - 1) % _ecols;
        var _erow = floor((_ei - 1) / _ecols);
        var _ex2 = _lx + _ecol * (_eboxw + _egap);
        var _ey2 = _esel_y + 18 + _erow * (_eboxh + _egap);
        var _e_sel2 = (expr_cfg_preview_expr == _ei);
        var _e_hov2 = (!theater_mode && _mx > _ex2 && _mx < _ex2 + _eboxw && _my > _ey2 && _my < _ey2 + _eboxh);
        draw_set_color(_e_sel2 ? make_color_rgb(55, 90, 170) : (_e_hov2 ? make_color_rgb(38, 46, 68) : make_color_rgb(22, 26, 38)));
        draw_rectangle(_ex2, _ey2, _ex2 + _eboxw, _ey2 + _eboxh, false);
        // Expression name
        draw_set_color(c_white); draw_set_halign(fa_center);
        draw_text(_ex2 + _eboxw/2, _ey2 + 3, _expr_names_short[_ei - 1]);
        // Mouth-mood colour stripe
        var _em = _esel_mood_map[_ei - 1];
        var _has_mouth = (_pc_ec != undefined && variable_struct_exists(_pc_ec, "mouth_files") && ((variable_struct_exists(_pc_ec.mouth_files, string(_ei)) && _pc_ec.mouth_files[$ string(_ei)] != "") || (variable_struct_exists(_pc_ec.mouth_files, string(_em)) && _pc_ec.mouth_files[$ string(_em)] != "")));
        var _has_eyes  = (_pc_ec != undefined && variable_struct_exists(_pc_ec, "eyes_files")  && variable_struct_exists(_pc_ec.eyes_files,  string(_ei)) && _pc_ec.eyes_files[$  string(_ei)] != "");
        draw_set_color(_has_mouth ? _mood_col[_em] : make_color_rgb(40, 42, 55));
        draw_rectangle(_ex2 + 2, _ey2 + 26, _ex2 + _eboxw - 2, _ey2 + 33, false);
        if (_has_eyes) { draw_set_color(c_aqua); draw_circle(_ex2 + _eboxw - 6, _ey2 + 6, 3, false); }
        draw_set_halign(fa_left);
    }

    // Quick-fill: enter baseline eye/mouth suffix → auto-populate all 8 configs
    var _btn_y2 = _m_y + _m_h - 52;
    var _qf_y = _btn_y2 - 36;
    draw_set_color(make_color_rgb(85, 85, 110)); draw_text(_lx, _qf_y + 3, "EYES");
    var _qf_ex = _lx + 38;
    var _qf_ea = (expr_cfg_qfill_active == 0);
    draw_set_color(_qf_ea ? make_color_rgb(35, 50, 90) : make_color_rgb(22, 26, 38));
    draw_rectangle(_qf_ex, _qf_y, _qf_ex + 30, _qf_y + 22, false);
    draw_set_color(_qf_ea ? c_yellow : c_white);
    draw_set_halign(fa_center);
    draw_text(_qf_ex + 15, _qf_y + 3, expr_cfg_qfill_eyes + (_qf_ea && (current_time mod 600 < 300) ? "|" : ""));
    draw_set_halign(fa_left);
    draw_set_color(make_color_rgb(85, 85, 110)); draw_text(_qf_ex + 36, _qf_y + 3, "MOUTH");
    var _qf_mx = _qf_ex + 82;
    var _qf_ma = (expr_cfg_qfill_active == 1);
    draw_set_color(_qf_ma ? make_color_rgb(35, 50, 90) : make_color_rgb(22, 26, 38));
    draw_rectangle(_qf_mx, _qf_y, _qf_mx + 30, _qf_y + 22, false);
    draw_set_color(_qf_ma ? c_yellow : c_white);
    draw_set_halign(fa_center);
    draw_text(_qf_mx + 15, _qf_y + 3, expr_cfg_qfill_mouth + (_qf_ma && (current_time mod 600 < 300) ? "|" : ""));
    draw_set_halign(fa_left);
    var _qf_get_x = _qf_mx + 38;
    var _qf_get_hov = (!theater_mode && _mx > _qf_get_x && _mx < _qf_get_x + 40 && _my > _qf_y && _my < _qf_y + 22);
    draw_set_color(_qf_get_hov ? make_color_rgb(30, 130, 130) : make_color_rgb(15, 75, 75));
    draw_rectangle(_qf_get_x, _qf_y, _qf_get_x + 40, _qf_y + 22, false);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_qf_get_x + 20, _qf_y + 3, "GET"); draw_set_halign(fa_left);
    var _qf_apply_x = _qf_get_x + 46;
    var _qf_apply_hov = (!theater_mode && _mx > _qf_apply_x && _mx < _qf_apply_x + 55 && _my > _qf_y && _my < _qf_y + 22);
    draw_set_color(_qf_apply_hov ? make_color_rgb(200, 120, 20) : make_color_rgb(120, 70, 10));
    draw_rectangle(_qf_apply_x, _qf_y, _qf_apply_x + 55, _qf_y + 22, false);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_qf_apply_x + 27, _qf_y + 3, "APPLY"); draw_set_halign(fa_left);

    // Bottom buttons: SAVE, CLOSE
    var _btn_w = 50; var _btn_gap_ec = 8;

    // SAVE
    var _save_x = _lx;
    var _save_hov = (!theater_mode && _mx > _save_x && _mx < _save_x + _btn_w && _my > _btn_y2 && _my < _btn_y2 + 40);
    draw_set_color(_save_hov ? c_lime : make_color_rgb(50, 110, 50)); draw_rectangle(_save_x, _btn_y2, _save_x + _btn_w, _btn_y2 + 40, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_save_x + _btn_w/2, _btn_y2 + 11, "SAVE"); draw_set_halign(fa_left);

    // CLOSE
    var _cls_x = _save_x + _btn_w + _btn_gap_ec;
    var _cls_hov2 = (!theater_mode && _mx > _cls_x && _mx < _cls_x + _btn_w && _my > _btn_y2 && _my < _btn_y2 + 40);
    draw_set_color(_cls_hov2 ? c_red : make_color_rgb(80, 25, 25)); draw_rectangle(_cls_x, _btn_y2, _cls_x + _btn_w, _btn_y2 + 40, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_cls_x + _btn_w/2, _btn_y2 + 11, "CLOSE"); draw_set_halign(fa_left);

    // ── Right panel: preview ──
    var _px2 = _m_x + 298; var _py2 = _m_y + 10;
    var _pw2 = _m_w - 308; var _ph2 = _m_h - 20;
    draw_set_color(make_color_rgb(10, 12, 18));
    draw_roundrect_ext(_px2, _py2, _px2 + _pw2, _py2 + _ph2, 8, 8, false);
    draw_set_color(make_color_rgb(35, 45, 75));
    draw_roundrect_ext(_px2, _py2, _px2 + _pw2, _py2 + _ph2, 8, 8, true);

    // Layout and dimensions for character composite + file browser (declared early for hover logic)
    var _char_preview_h = floor(_ph2 * 0.58);
    var _file_browser_y = _py2 + _char_preview_h + 4;
    var _file_browser_h = _ph2 - _char_preview_h - 8;
    var _fb_list_y = _file_browser_y + 28;
    var _fb_cols = 3;
    var _fb_item_w = floor(_pw2 / _fb_cols);
    var _fb_item_h = 22;
    var _fb_vis_rows = floor((_file_browser_h - (_fb_list_y - _file_browser_y) - 2) / _fb_item_h);
    var _fb_start = expr_cfg_file_scroll * _fb_cols;
    var _fb_end = min(_fb_start + _fb_vis_rows * _fb_cols, array_length(expr_cfg_file_list));

    // Determine if any file is hovered in the browser, to show it in the composite preview
    var _hov_fname = "";
    for (var _fi2 = _fb_start; _fi2 < _fb_end; _fi2++) {
        var _fcol2  = (_fi2 - _fb_start) mod _fb_cols;
        var _frow2  = floor((_fi2 - _fb_start) / _fb_cols);
        var _fix2   = _px2 + 1 + _fcol2 * _fb_item_w;
        var _fiy2   = _fb_list_y + _frow2 * _fb_item_h;
        if (_mx > _fix2 && _mx < _fix2 + _fb_item_w && _my > _fiy2 && _my < _fiy2 + _fb_item_h) {
            _hov_fname = expr_cfg_file_list[_fi2]; break;
        }
    }

    var _hov_spr = -1;
    if (_hov_fname != "") {
        var _hk = _c_ec.name + "_" + _hov_fname;
        if (ds_map_exists(char_sprites, _hk)) {
            _hov_spr = char_sprites[? _hk];
        } else {
            var _hpath = datafiles_path + "actors/" + _c_ec.name + "/" + _hov_fname;
            if (file_exists(_hpath)) {
                _hov_spr = sprite_add(_hpath, 1, false, false, 0, 0);
                ds_map_add(char_sprites, _hk, _hov_spr);
            }
        }
    }

    // Get preview sprites
    var _body_spr_ec = -1;
    var _face_spr_ec = -1;
    var _eyes_spr_ec = -1;
    var _mouth_spr_ec = -1;
    _folder_ec2 = datafiles_path + "actors/" + _c_ec.name + "/";
    _ai_ec = variable_struct_exists(_c_ec, "act_index") ? _c_ec.act_index : 1;
    _sfx_off_ec = expr_cfg_high ? 50 : 0;
    _pfx_ec = string(_ai_ec) + string(expr_cfg_pose);

    // ── Load body / face sprites (with sprite_add fallback) ──
    if (_pc_ec != undefined) {
        if (_pc_ec.body_file != "") {
            var _bk3 = _c_ec.name + "_" + _pc_ec.body_file;
            if (ds_map_exists(char_sprites, _bk3)) {
                _body_spr_ec = char_sprites[? _bk3];
            } else if (file_exists(_folder_ec2 + _pc_ec.body_file)) {
                _body_spr_ec = sprite_add(_folder_ec2 + _pc_ec.body_file, 1, false, false, 0, 0);
                ds_map_add(char_sprites, _bk3, _body_spr_ec);
            }
        }
        if (_pc_ec.face_file != "") {
            var _fk3 = _c_ec.name + "_" + _pc_ec.face_file;
            if (ds_map_exists(char_sprites, _fk3)) {
                _face_spr_ec = char_sprites[? _fk3];
            } else if (file_exists(_folder_ec2 + _pc_ec.face_file)) {
                _face_spr_ec = sprite_add(_folder_ec2 + _pc_ec.face_file, 1, false, false, 0, 0);
                ds_map_add(char_sprites, _fk3, _face_spr_ec);
            }
        }
    }

    // Eyes: use per-expression override if set, else suffix auto
    var _eyes_file_ec = "";
    if (_pc_ec != undefined && variable_struct_exists(_pc_ec, "eyes_files")) {
        var _ef_ec = _pc_ec.eyes_files;
        var _ef_ek = string(expr_cfg_preview_expr);
        if (variable_struct_exists(_ef_ec, _ef_ek) && _ef_ec[$ _ef_ek] != "") _eyes_file_ec = _ef_ec[$ _ef_ek];
    }
    if (_eyes_file_ec == "") {
        var _eyes_n_ec = 10 + expr_cfg_preview_expr + _sfx_off_ec;
        _eyes_file_ec = "pose_" + _pfx_ec + ((_eyes_n_ec < 10 ? "0" : "") + string(_eyes_n_ec)) + ".png";
    }
    var _ek3 = _c_ec.name + "_" + _eyes_file_ec;
    if (ds_map_exists(char_sprites, _ek3)) {
        _eyes_spr_ec = char_sprites[? _ek3];
    } else if (file_exists(_folder_ec2 + _eyes_file_ec)) {
        _eyes_spr_ec = sprite_add(_folder_ec2 + _eyes_file_ec, 1, false, false, 0, 0);
        ds_map_add(char_sprites, _ek3, _eyes_spr_ec);
    }

    // Mouth: derive mood from the selected expression (same mapping as get_composite_character_sprite)
    _ec_mood_map = [0, 2, 3, 1, 0, 1, 1, 1, 1, 0, 2, 1, 1, 1, 0, 3, 1, 0, 1, 2];
    _derived_mood_ec = _ec_mood_map[clamp(expr_cfg_preview_expr - 1, 0, 19)];
    var _mouth_file_ec = "";
    if (_pc_ec != undefined && variable_struct_exists(_pc_ec, "mouth_files")) {
        var _mf_ec = _pc_ec.mouth_files;
        var _expr_key = string(expr_cfg_preview_expr);
        var _mood_key = string(_derived_mood_ec);
        if (variable_struct_exists(_mf_ec, _expr_key) && _mf_ec[$ _expr_key] != "") {
            _mouth_file_ec = _mf_ec[$ _expr_key];
        } else if (variable_struct_exists(_mf_ec, _mood_key) && _mf_ec[$ _mood_key] != "") {
            _mouth_file_ec = _mf_ec[$ _mood_key];
        }
    }
    if (_mouth_file_ec == "") {
        var _mouth_n_ec = 31 + _derived_mood_ec + _sfx_off_ec;
        _mouth_file_ec = "pose_" + _pfx_ec + ((_mouth_n_ec < 10 ? "0" : "") + string(_mouth_n_ec)) + ".png";
    }
    var _mk3 = _c_ec.name + "_" + _mouth_file_ec;
    if (ds_map_exists(char_sprites, _mk3)) {
        _mouth_spr_ec = char_sprites[? _mk3];
    } else if (file_exists(_folder_ec2 + _mouth_file_ec)) {
        _mouth_spr_ec = sprite_add(_folder_ec2 + _mouth_file_ec, 1, false, false, 0, 0);
        ds_map_add(char_sprites, _mk3, _mouth_spr_ec);
    }

    // If hovering a file list item, temporarily override the active layer with the hovered sprite
    if (_hov_spr != -1) {
        if (expr_cfg_selected_layer == 0) _body_spr_ec = _hov_spr;
        else if (expr_cfg_selected_layer == 1) _face_spr_ec = _hov_spr;
        else if (expr_cfg_selected_layer == 2) _eyes_spr_ec = _hov_spr;
        else if (expr_cfg_selected_layer == 3) _mouth_spr_ec = _hov_spr;
    }

    // ── Split preview panel: top 58% = composite, bottom 42% = file browser ──
    // (Layout variables _char_preview_h, _file_browser_y, and _file_browser_h are declared early)

    // ── Character composite preview ──
    var _bdw2 = (_body_spr_ec != -1) ? sprite_get_width(_body_spr_ec) : 80;
    var _bdh2 = (_body_spr_ec != -1) ? sprite_get_height(_body_spr_ec) : 100;
    // Total composite height = body bottom → face top (face_dy is negative when above body)
    var _total_char_h = _bdh2;
    if (_pc_ec != undefined && _pc_ec.face_dy < 0) _total_char_h = _bdh2 - _pc_ec.face_dy;
    var _base_sc = (_body_spr_ec != -1) ? min((_char_preview_h - 20) / _total_char_h, 4.0) : 2.0;
    var _cfg_sc = _base_sc * expr_cfg_zoom;

    var _anch_x2 = _px2 + _pw2 / 2;
    var _anch_y2 = _py2 + _char_preview_h - 10;
    var _drawx2 = _anch_x2 - _bdw2 * _cfg_sc / 2 + expr_cfg_pan_x;
    var _drawy2 = _anch_y2 - _bdh2 * _cfg_sc    + expr_cfg_pan_y;

    gpu_set_scissor(_px2 + 2, _py2 + 2, _pw2 - 4, _char_preview_h - 4);
    gpu_set_texfilter(false);
    var _prev_sprs = [_body_spr_ec, _face_spr_ec, _eyes_spr_ec, _mouth_spr_ec];
    
    // Compute total offset dx/dy for each layer in the preview panel (including base + custom delta nudges)
    var _bdx_prev = 0; var _bdy_prev = 0;
    var _fdx_prev = 0; var _fdy_prev = 0;
    var _edx_prev = 0; var _edy_prev = 0;
    var _mdx_prev = 0; var _mdy_prev = 0;
    
    var _lo_ox_p = 0; var _lo_oy_p = 0;
    if (_off_data != undefined && _pc_ec.body_file != "") {
        var _bk_p = string_replace(_pc_ec.body_file, ".png", "");
        if (variable_struct_exists(_off_data, _bk_p)) { var _bv_p = _off_data[$ _bk_p]; _lo_ox_p = _bv_p[0]; _lo_oy_p = _bv_p[1]; }
    }
    
    if (_pc_ec != undefined) {
        // BODY
        var _body_file_prev = _pc_ec.body_file;
        var _body_ok_p = string_replace(_body_file_prev, ".png", "");
        if (_off_data != undefined && variable_struct_exists(_off_data, _body_ok_p)) {
            var _bv_p = _off_data[$ _body_ok_p]; _bdx_prev = _bv_p[0] - _lo_ox_p; _bdy_prev = _bv_p[1] - _lo_oy_p;
        }
        if (variable_struct_exists(_pc_ec, "body_dx_offsets") && variable_struct_exists(_pc_ec.body_dx_offsets, _body_file_prev)) {
            _bdx_prev += _pc_ec.body_dx_offsets[$ _body_file_prev];
        } else if (variable_struct_exists(_pc_ec, "body_dx")) {
            _bdx_prev = _pc_ec.body_dx;
        }
        if (variable_struct_exists(_pc_ec, "body_dy_offsets") && variable_struct_exists(_pc_ec.body_dy_offsets, _body_file_prev)) {
            _bdy_prev += _pc_ec.body_dy_offsets[$ _body_file_prev];
        } else if (variable_struct_exists(_pc_ec, "body_dy")) {
            _bdy_prev = _pc_ec.body_dy;
        }
        
        // FACE
        var _face_file_prev = _pc_ec.face_file;
        var _face_ok_p = string_replace(_face_file_prev, ".png", "");
        if (_off_data != undefined && variable_struct_exists(_off_data, _face_ok_p)) {
            var _fov_p = _off_data[$ _face_ok_p]; _fdx_prev = _fov_p[0] - _lo_ox_p; _fdy_prev = _fov_p[1] - _lo_oy_p;
        }
        if (variable_struct_exists(_pc_ec, "face_dx_offsets") && variable_struct_exists(_pc_ec.face_dx_offsets, _face_file_prev)) {
            _fdx_prev += _pc_ec.face_dx_offsets[$ _face_file_prev];
        } else if (variable_struct_exists(_pc_ec, "face_dx")) {
            _fdx_prev = _pc_ec.face_dx;
        }
        if (variable_struct_exists(_pc_ec, "face_dy_offsets") && variable_struct_exists(_pc_ec.face_dy_offsets, _face_file_prev)) {
            _fdy_prev += _pc_ec.face_dy_offsets[$ _face_file_prev];
        } else if (variable_struct_exists(_pc_ec, "face_dy")) {
            _fdy_prev = _pc_ec.face_dy;
        }
        
        // EYES
        var _eyes_file_prev = "";
        if (variable_struct_exists(_pc_ec, "eyes_files")) {
            var _ef_prev = _pc_ec.eyes_files;
            var _ef_ek_prev = string(expr_cfg_preview_expr);
            if (variable_struct_exists(_ef_prev, _ef_ek_prev) && _ef_prev[$ _ef_ek_prev] != "") _eyes_file_prev = _ef_prev[$ _ef_ek_prev];
        }
        if (_eyes_file_prev == "") {
            var _eyes_n_prev = 10 + expr_cfg_preview_expr + _sfx_off_ec;
            _eyes_file_prev = "pose_" + _pfx_ec + ((_eyes_n_prev < 10 ? "0" : "") + string(_eyes_n_prev)) + ".png";
        }
        var _eyes_ok_p = string_replace(_eyes_file_prev, ".png", "");
        if (_off_data != undefined && variable_struct_exists(_off_data, _eyes_ok_p)) {
            var _eov_p = _off_data[$ _eyes_ok_p]; _edx_prev = _eov_p[0] - _lo_ox_p; _edy_prev = _eov_p[1] - _lo_oy_p;
        }
        var _expr_key_prev = string(expr_cfg_preview_expr);
        if (variable_struct_exists(_pc_ec, "eyes_dx_expr_offsets") && variable_struct_exists(_pc_ec.eyes_dx_expr_offsets, _expr_key_prev)) {
            _edx_prev += _pc_ec.eyes_dx_expr_offsets[$ _expr_key_prev];
        } else if (variable_struct_exists(_pc_ec, "eyes_dx_offsets") && variable_struct_exists(_pc_ec.eyes_dx_offsets, _eyes_file_prev)) {
            _edx_prev += _pc_ec.eyes_dx_offsets[$ _eyes_file_prev];
        } else if (variable_struct_exists(_pc_ec, "eyes_dx")) {
            _edx_prev = _pc_ec.eyes_dx;
        }
        if (variable_struct_exists(_pc_ec, "eyes_dy_expr_offsets") && variable_struct_exists(_pc_ec.eyes_dy_expr_offsets, _expr_key_prev)) {
            _edy_prev += _pc_ec.eyes_dy_expr_offsets[$ _expr_key_prev];
        } else if (variable_struct_exists(_pc_ec, "eyes_dy_offsets") && variable_struct_exists(_pc_ec.eyes_dy_offsets, _eyes_file_prev)) {
            _edy_prev += _pc_ec.eyes_dy_offsets[$ _eyes_file_prev];
        } else if (variable_struct_exists(_pc_ec, "eyes_dy")) {
            _edy_prev = _pc_ec.eyes_dy;
        }
        
        // MOUTH
        var _mouth_file_prev = "";
        if (variable_struct_exists(_pc_ec, "mouth_files")) {
            var _mf_prev = _pc_ec.mouth_files;
            var _expr_key = string(expr_cfg_preview_expr);
            var _mood_key = string(_derived_mood_ec);
            if (variable_struct_exists(_mf_prev, _expr_key) && _mf_prev[$ _expr_key] != "") {
                _mouth_file_prev = _mf_prev[$ _expr_key];
            } else if (variable_struct_exists(_mf_prev, _mood_key) && _mf_prev[$ _mood_key] != "") {
                _mouth_file_prev = _mf_prev[$ _mood_key];
            }
        }
        if (_mouth_file_prev == "") {
            var _mouth_n_prev = 31 + _derived_mood_ec + _sfx_off_ec;
            _mouth_file_prev = "pose_" + _pfx_ec + ((_mouth_n_prev < 10 ? "0" : "") + string(_mouth_n_prev)) + ".png";
        }
        var _mouth_ok_p = string_replace(_mouth_file_prev, ".png", "");
        if (_off_data != undefined && variable_struct_exists(_off_data, _mouth_ok_p)) {
            var _mov_p = _off_data[$ _mouth_ok_p]; _mdx_prev = _mov_p[0] - _lo_ox_p; _mdy_prev = _mov_p[1] - _lo_oy_p;
        }
        _expr_key_prev = string(expr_cfg_preview_expr);
        if (variable_struct_exists(_pc_ec, "mouth_dx_expr_offsets") && variable_struct_exists(_pc_ec.mouth_dx_expr_offsets, _expr_key_prev)) {
            _mdx_prev += _pc_ec.mouth_dx_expr_offsets[$ _expr_key_prev];
        } else if (variable_struct_exists(_pc_ec, "mouth_dx_offsets") && variable_struct_exists(_pc_ec.mouth_dx_offsets, _mouth_file_prev)) {
            _mdx_prev += _pc_ec.mouth_dx_offsets[$ _mouth_file_prev];
        } else if (variable_struct_exists(_pc_ec, "mouth_dx")) {
            _mdx_prev = _pc_ec.mouth_dx;
        }
        if (variable_struct_exists(_pc_ec, "mouth_dy_expr_offsets") && variable_struct_exists(_pc_ec.mouth_dy_expr_offsets, _expr_key_prev)) {
            _mdy_prev += _pc_ec.mouth_dy_expr_offsets[$ _expr_key_prev];
        } else if (variable_struct_exists(_pc_ec, "mouth_dy_offsets") && variable_struct_exists(_pc_ec.mouth_dy_offsets, _mouth_file_prev)) {
            _mdy_prev += _pc_ec.mouth_dy_offsets[$ _mouth_file_prev];
        } else if (variable_struct_exists(_pc_ec, "mouth_dy")) {
            _mdy_prev = _pc_ec.mouth_dy;
        }
    }
    
    var _prev_dx = [_bdx_prev, _fdx_prev + _bdx_prev, _edx_prev + _bdx_prev, _mdx_prev + _bdx_prev];
    var _prev_dy = [_bdy_prev, _fdy_prev + _bdy_prev, _edy_prev + _bdy_prev, _mdy_prev + _bdy_prev];
    for (var _li2 = 0; _li2 <= 3; _li2++) {
        var _ls2 = _prev_sprs[_li2];
        var _lsx = _drawx2 + _prev_dx[_li2] * _cfg_sc;
        var _lsy = _drawy2 + _prev_dy[_li2] * _cfg_sc;
        var _is_sel_l = (expr_cfg_selected_layer == _li2);
        if (_ls2 == -1) {
            // Placeholder: lets user see and click the layer even without a sprite loaded
            draw_set_color(_is_sel_l ? c_yellow : make_color_rgb(35, 40, 60));
            draw_rectangle(_lsx, _lsy, _lsx + 64, _lsy + 28, _is_sel_l);
            continue;
        }
        if (_is_sel_l) {
            gpu_set_blendmode(bm_add);
            draw_sprite_ext(_ls2, 0, _lsx, _lsy, _cfg_sc, _cfg_sc, 0, _layer_cols[_li2], 0.35);
            gpu_set_blendmode(bm_normal);
        }
        draw_sprite_ext(_ls2, 0, _lsx, _lsy, _cfg_sc, _cfg_sc, 0, _is_sel_l ? c_yellow : c_white, 1.0);
    }

    // Zoom Indicator
    draw_set_halign(fa_right); draw_set_color(c_ltgray);
    draw_text(_px2 + _pw2 - 10, _py2 + 10, "Zoom: " + string(round(expr_cfg_zoom * 100)) + "%");
    draw_set_halign(fa_left);

    gpu_set_texfilter(false);
    gpu_set_scissor(0, 0, 1280, 960);

    // Divider
    draw_set_color(make_color_rgb(40, 50, 80));
    draw_rectangle(_px2, _py2 + _char_preview_h, _px2 + _pw2, _py2 + _char_preview_h + 4, false);

    // ── File browser ──
    draw_set_color(make_color_rgb(12, 14, 22));
    draw_rectangle(_px2 + 1, _file_browser_y, _px2 + _pw2 - 1, _file_browser_y + _file_browser_h, false);

    // Header bar: shows layer name + slot selector for EYES/MOUTH
    draw_set_color(make_color_rgb(28, 35, 55));
    draw_rectangle(_px2 + 1, _file_browser_y, _px2 + _pw2 - 1, _file_browser_y + 26, false);
    draw_set_color(c_white);
    var _fb_layer_name = _layer_names_ec[expr_cfg_selected_layer];
    var _hdr_text = "SELECT FILE  ·  " + _fb_layer_name;
    if (_hov_fname != "") {
        draw_set_color(c_lime);
        _hdr_text += "  [PREVIEWING: " + _hov_fname + "]";
    }
    draw_text(_px2 + 6, _file_browser_y + 5, _hdr_text);
    draw_set_color(c_white);

    // File list grid (3 columns) - (Local layout variables are declared early)

    // Determine currently assigned file for all 4 layers
    var _active_body_file = "";
    var _active_face_file = "";
    var _active_eyes_file = "";
    var _active_mouth_file = "";
    
    if (_pc_ec != undefined) {
        _active_body_file = _pc_ec.body_file;
        _active_face_file = _pc_ec.face_file;
        
        if (variable_struct_exists(_pc_ec, "eyes_files")) {
            var _ef2 = _pc_ec.eyes_files; var _ek4 = string(expr_cfg_preview_expr);
            if (variable_struct_exists(_ef2, _ek4) && _ef2[$ _ek4] != "") _active_eyes_file = _ef2[$ _ek4];
        }
        if (_active_eyes_file == "") {
            var _eyes_n_ec = 10 + expr_cfg_preview_expr + _sfx_off_ec;
            _active_eyes_file = "pose_" + _pfx_ec + ((_eyes_n_ec < 10 ? "0" : "") + string(_eyes_n_ec)) + ".png";
        }
        
        if (variable_struct_exists(_pc_ec, "mouth_files")) {
            var _mf2 = _pc_ec.mouth_files;
            var _expr_key = string(expr_cfg_preview_expr);
            var _mood_key = string(_derived_mood_ec);
            if (variable_struct_exists(_mf2, _expr_key) && _mf2[$ _expr_key] != "") {
                _active_mouth_file = _mf2[$ _expr_key];
            } else if (variable_struct_exists(_mf2, _mood_key) && _mf2[$ _mood_key] != "") {
                _active_mouth_file = _mf2[$ _mood_key];
            }
        }
        if (_active_mouth_file == "") {
            var _mouth_n_ec = 31 + _derived_mood_ec + _sfx_off_ec;
            _active_mouth_file = "pose_" + _pfx_ec + ((_mouth_n_ec < 10 ? "0" : "") + string(_mouth_n_ec)) + ".png";
        }
    }

    gpu_set_scissor(_px2 + 1, _fb_list_y, _pw2 - 2, _file_browser_h - (_fb_list_y - _file_browser_y));
    for (var _fi = _fb_start; _fi < _fb_end; _fi++) {
        var _fname = expr_cfg_file_list[_fi];
        var _fcol  = (_fi - _fb_start) mod _fb_cols;
        var _frow  = floor((_fi - _fb_start) / _fb_cols);
        var _fitem_x = _px2 + 1 + _fcol * _fb_item_w;
        var _fitem_y = _fb_list_y + _frow * _fb_item_h;
        var _fhov = (!theater_mode && _mx > _fitem_x && _mx < _fitem_x + _fb_item_w && _my > _fitem_y && _my < _fitem_y + _fb_item_h);
        
        var _is_body  = (_fname == _active_body_file);
        var _is_face  = (_fname == _active_face_file);
        var _is_eyes  = (_fname == _active_eyes_file);
        var _is_mouth = (_fname == _active_mouth_file);
        
        // Check if this file is the active file for the currently selected layer
        var _is_sel_layer_file = false;
        if (expr_cfg_selected_layer == 0 && _is_body) _is_sel_layer_file = true;
        else if (expr_cfg_selected_layer == 1 && _is_face) _is_sel_layer_file = true;
        else if (expr_cfg_selected_layer == 2 && _is_eyes) _is_sel_layer_file = true;
        else if (expr_cfg_selected_layer == 3 && _is_mouth) _is_sel_layer_file = true;
        
        // Define colors
        var _col_body  = make_color_rgb(255, 180, 100);
        var _col_head  = make_color_rgb(100, 180, 255);
        var _col_eyes  = make_color_rgb(120, 255, 120);
        var _col_mouth = make_color_rgb(255, 120, 120);
        
        var _bg_body  = make_color_rgb(45, 38, 25);
        var _bg_head  = make_color_rgb(25, 38, 48);
        var _bg_eyes  = make_color_rgb(22, 45, 28);
        var _bg_mouth = make_color_rgb(48, 38, 25);
        
        // Collect tags
        var _tags = [];
        if (_is_body)  array_push(_tags, { text: "BODY",  col: _col_body,  bg: make_color_rgb(80, 50, 20) });
        if (_is_face)  array_push(_tags, { text: "HEAD",  col: _col_head,  bg: make_color_rgb(20, 50, 80) });
        if (_is_eyes)  array_push(_tags, { text: "EYES",  col: _col_eyes,  bg: make_color_rgb(20, 70, 30) });
        if (_is_mouth) array_push(_tags, { text: "MOUTH", col: _col_mouth, bg: make_color_rgb(80, 30, 30) });
        
        var _bg_col = make_color_rgb(16, 18, 26);
        var _text_col = make_color_rgb(130, 140, 160);
        
        // Background color logic
        if (_is_sel_layer_file) {
            _bg_col = make_color_rgb(30, 50, 90); // Slate blue selected background
            _text_col = c_white;
        } else if (array_length(_tags) > 0) {
            // Harmonic background tint based on role
            if (_is_body)       _bg_col = _bg_body;
            else if (_is_face)  _bg_col = _bg_head;
            else if (_is_eyes)  _bg_col = _bg_eyes;
            else if (_is_mouth) _bg_col = _bg_mouth;
            _text_col = c_ltgray;
        }
        
        // Hover state
        if (_fhov) {
            if (_is_sel_layer_file) {
                _bg_col = make_color_rgb(45, 75, 130);
            } else if (array_length(_tags) > 0) {
                _bg_col = make_color_rgb(color_get_red(_bg_col) + 12, color_get_green(_bg_col) + 12, color_get_blue(_bg_col) + 12);
            } else {
                _bg_col = make_color_rgb(30, 38, 58);
            }
            _text_col = c_white;
        }
        
        // Draw background
        draw_set_color(_bg_col);
        draw_rectangle(_fitem_x, _fitem_y, _fitem_x + _fb_item_w - 2, _fitem_y + _fb_item_h - 1, false);
        
        // Draw borders for selected/hovered files
        if (_is_sel_layer_file) {
            draw_set_color(make_color_rgb(100, 180, 255));
            draw_rectangle(_fitem_x, _fitem_y, _fitem_x + _fb_item_w - 2, _fitem_y + _fb_item_h - 1, true);
        } else if (_fhov) {
            draw_set_color(make_color_rgb(80, 90, 110));
            draw_rectangle(_fitem_x, _fitem_y, _fitem_x + _fb_item_w - 2, _fitem_y + _fb_item_h - 1, true);
        }
        
        // Draw tag badges starting from right to left
        var _bx = _fitem_x + _fb_item_w - 6;
        for (var _ti = array_length(_tags) - 1; _ti >= 0; _ti--) {
            var _t = _tags[_ti];
            var _badge_w = string_width(_t.text) + 8;
            var _badge_h = 14;
            var _by = _fitem_y + (_fb_item_h - _badge_h) / 2;
            
            // Draw badge background
            draw_set_color(_t.bg);
            draw_roundrect_ext(_bx - _badge_w, _by, _bx, _by + _badge_h, 3, 3, false);
            
            // Draw badge border
            draw_set_color(_t.col);
            draw_roundrect_ext(_bx - _badge_w, _by, _bx, _by + _badge_h, 3, 3, true);
            
            // Draw badge text
            draw_set_color(_t.col);
            draw_set_halign(fa_center);
            draw_text_transformed(_bx - _badge_w / 2, _by + 1, _t.text, 0.7, 0.7, 0);
            draw_set_halign(fa_left);
            
            _bx -= _badge_w + 4;
        }
        
        // Strip .png and dynamically truncate filename to fit left panel remaining space
        var _disp_name = string_replace(_fname, ".png", "");
        var _max_w = _bx - 4 - (_fitem_x + 6);
        if (string_width(_disp_name) > _max_w) {
            while (string_length(_disp_name) > 0 && string_width(_disp_name + "..") > _max_w) {
                _disp_name = string_copy(_disp_name, 1, string_length(_disp_name) - 1);
            }
            _disp_name += "..";
        }
        
        // Draw filename
        draw_set_color(_text_col);
        draw_text(_fitem_x + 6, _fitem_y + 3, _disp_name);
    }
    gpu_set_scissor(0, 0, 1280, 960);

    // ── File hover preview (handled in-context in preview pane) ──

    // Scrollbar for file browser
    var _total_rows = ceil(array_length(expr_cfg_file_list) / _fb_cols);
    if (_total_rows > _fb_vis_rows) {
        var _sb2_x = _px2 + _pw2 - 10;
        var _sb2_y = _fb_list_y; var _sb2_h = _fb_vis_rows * _fb_item_h;
        draw_set_color(make_color_rgb(28,32,48)); draw_rectangle(_sb2_x, _sb2_y, _sb2_x + 8, _sb2_y + _sb2_h, false);
        var _bar2_h = max(20, (_fb_vis_rows / _total_rows) * _sb2_h);
        var _bar2_y = _sb2_y + (expr_cfg_file_scroll / max(1, _total_rows - _fb_vis_rows)) * (_sb2_h - _bar2_h);
        draw_set_color(make_color_rgb(80,100,160)); draw_rectangle(_sb2_x, _bar2_y, _sb2_x + 8, _bar2_y + _bar2_h, false);
    }
}

// --- 5c. LIVE TITLE RENDERING ---
_render_live_titles();
