/// @description Professional Editor UI Renderer (With Hover Effects)
var _mx = mouse_x; var _my = mouse_y;

var _overlay_active = (file_menu_open || dictionary_open || edit_mode || scene_modal_open || action_modal_open || move_modal_open || theater_mode || pose_modal_open || expression_modal_open || pose_expr_modal_open || expr_cfg_open || import_modal_open || anim_editor_open);

draw_clear(make_color_rgb(10, 42, 16));

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
        
        if (_pb != -1 && (!variable_struct_exists(_pb, "title_frames") || _pb.title_frames > 0)) {
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
        
        var _q_th_x = quake_x * (_stage_w / scene_win_w); var _q_th_y = quake_y * (_stage_h / scene_win_h);
        draw_sprite_ext(current_scene_sprite, 0, _stage_x + _q_th_x, _stage_y + _q_th_y, _bg_sc, _bg_sc, 0, c_white, 1);
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

			// Canned animation override — build layers before using _layers for size calc
			if (variable_struct_exists(_act, "canned_spr") && _act.canned_spr != -1) {
			    var _canned_ay = variable_struct_exists(_act, "canned_anchor_y") ? _act.canned_anchor_y : 0;
			    var _feet_spr  = (variable_struct_exists(_act, "canned_composite") && _act.canned_composite
			                      && variable_struct_exists(_act, "canned_feet_spr") && _act.canned_feet_spr != -1)
			                     ? _act.canned_feet_spr : -1;
			    if (_feet_spr != -1) {
			        var _canned_h  = sprite_get_height(_act.canned_spr);
			        var _body_dy   = variable_struct_exists(_act, "canned_body_dy") ? _act.canned_body_dy : 0;
			        var _body_dx   = variable_struct_exists(_act, "canned_body_dx") ? _act.canned_body_dx : 0;
			        var _composite_legs = !variable_struct_exists(_act, "canned_composite_legs") || _act.canned_composite_legs;
			        var _dy_val = -_canned_h + _canned_ay + _body_dy;
			        if (!_composite_legs) {
			            var _feet_h = sprite_get_height(_feet_spr);
			            _dy_val = _feet_h - _canned_h + _canned_ay + _body_dy;
			        }
			        _layers = [{ spr: _feet_spr,       dx: 0,        dy: 0 },
			                   { spr: _act.canned_spr, dx: _body_dx, dy: _dy_val },
			                   { spr: -1, dx: 0, dy: 0 }, { spr: -1, dx: 0, dy: 0 }];
			    } else {
			        var _body_dy   = variable_struct_exists(_act, "canned_body_dy") ? _act.canned_body_dy : 0;
			        var _body_dx   = variable_struct_exists(_act, "canned_body_dx") ? _act.canned_body_dx : 0;
			        _layers = [{ spr: _act.canned_spr, dx: _body_dx, dy: _canned_ay + _body_dy },
			                   { spr: -1, dx: 0, dy: 0 }, { spr: -1, dx: 0, dy: 0 }, { spr: -1, dx: 0, dy: 0 }];
			    }
			} else {
			    _layers = get_composite_character_sprite(_act.char_index, _pose, _expr, _aface);
			}
			var _spr    = _layers[0].spr;

			if (_spr != -1) {
				var _csh = sprite_get_height(_spr);
				var _csw = sprite_get_width(_spr);
				var _asc = (_stg_h * 1.5) / 450;

				var _ax = (_act.x / scene_win_w) * _stg_w;
				var _ay = (_act.y / scene_win_h) * _stg_h;

				var _y_off  = variable_struct_exists(_act, "y_offset") ? (_act.y_offset / scene_win_h) * _stg_h : 0;
				var _jit_x  = variable_struct_exists(_act, "jitter_x") ? _act.jitter_x * (_stg_w / scene_win_w) : 0;
				var _jit_y  = variable_struct_exists(_act, "jitter_y") ? _act.jitter_y * (_stg_h / scene_win_h) : 0;

				var _qx_th = quake_x * (_stg_w / scene_win_w); var _qy_th = quake_y * (_stg_h / scene_win_h);
				var _draw_x = (target_surface == -1) ? (_stg_x + _ax - (_csw * _asc / 2) + _jit_x + _qx_th) : (_ax - (_csw * _asc / 2) + _jit_x);
				var _draw_y = (target_surface == -1) ? (_stg_y + _ay - (_csh * _asc) + _y_off + _jit_y + _qy_th) : (_ay - (_csh * _asc) + _y_off + _jit_y);

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
						var _adj_dur = 0;
						if (current_viseme_total_ms > 0 && speak_start_time_ms >= 0) {
							var _t_speed_val = max(1, 50 + _spk_speed * 2.5);
							_adj_dur = current_viseme_total_ms * (175.0 / _t_speed_val);
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
							var _vi = 0;
							for (_vi = 0; _vi < array_length(current_viseme_data); _vi++) {
								if (current_viseme_data[_vi].t <= _prog) _cur_v = current_viseme_data[_vi].v; else break;
							}
							// Hold the last open shape so the mouth doesn't snap closed between phonemes.
							if (_cur_v != 0) {
								mouth_last_vis_time_ms = current_time; mouth_last_vis_value = _cur_v;
							} else if (mouth_last_vis_time_ms >= 0 && current_time - mouth_last_vis_time_ms < 500) {
								_cur_v = mouth_last_vis_value;
							} else if (current_viseme_total_ms > 0 && mouth_last_vis_value != 0) {
								for (var _vla = _vi; _vla < array_length(current_viseme_data); _vla++) {
									if (current_viseme_data[_vla].v != 0) {
										if ((current_viseme_data[_vla].t - _prog) * _adj_dur < 400) _cur_v = mouth_last_vis_value;
										break;
									}
								}
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
				var _is_dead_dr   = variable_struct_exists(_act, "dead") && _act.dead;
				var _dstyle_dr    = _is_dead_dr ? (variable_struct_exists(_act, "death_style") ? _act.death_style : "sudden") : "";
				var _dangle_dr    = _is_dead_dr ? (variable_struct_exists(_act, "death_angle") ? _act.death_angle : 0) : 0;
				for (var _li = 0; _li < array_length(_layers); _li++) {
					var _l       = _layers[_li];
					// For decapitate: skip head layers (face=1, mouth=2, eyes=3)
					if (_is_dead_dr && _dstyle_dr == "decapitate" && _li > 0) {
						array_push(_final_layers, { spr: -1, dx: _l.dx, dy: _l.dy });
						continue;
					}
					var _is_anim = variable_struct_exists(_l, "is_mouth") && _has_manim && _mouth_open && !_is_dead_dr;
					var _ae      = _is_anim ? _mouth_anim[_manim_fi] : undefined;
					var _lspr    = _is_anim ? _ae.spr : _l.spr;
					if (_li == 0 && (variable_struct_exists(_act, "canned_composite_legs") && !_act.canned_composite_legs)) {
						_lspr = -1;
					}
					var _ldx     = _l.dx + (_is_anim ? _ae.dx : 0);
					var _ldy     = _l.dy + (_is_anim ? _ae.dy : 0);
					array_push(_final_layers, { spr: _lspr, dx: _ldx, dy: _ldy });
				}
				var _clip = (target_surface == -1) ? [_stg_x, _stg_y, _stg_w, _stg_h] : undefined;
				var _dp_th   = variable_struct_exists(_act, "dissolve_progress") ? _act.dissolve_progress : 0;
				var _melt_th = variable_struct_exists(_act, "melt_progress")     ? _act.melt_progress     : 0;
				var _ang_th  = variable_struct_exists(_act, "image_angle")       ? _act.image_angle       : 0;
				if (_is_dead_dr && (_dstyle_dr == "fall_forwards" || _dstyle_dr == "fall_backwards") && _dangle_dr != 0) {
					// Fall: rotate all layers around foot pivot
					var _rpx_dr = (target_surface == -1) ? (_stg_x + _ax) : _ax;
					var _rpy_dr = (target_surface == -1) ? (_stg_y + _ay + _y_off) : (_ay + _y_off);
					var _cos_dr = dcos(_dangle_dr); var _sin_dr = dsin(_dangle_dr);
					for (var _rli = 0; _rli < array_length(_final_layers); _rli++) {
						var _rl = _final_layers[_rli];
						if (_rl.spr == -1) continue;
						var _vx_dr = (_draw_x + _rl.dx * _asc) - _rpx_dr;
						var _vy_dr = (_draw_y + _rl.dy * _asc) - _rpy_dr;
						draw_sprite_ext(_rl.spr, 0,
							_rpx_dr + _vx_dr * _cos_dr + _vy_dr * _sin_dr,
							_rpy_dr - _vx_dr * _sin_dr + _vy_dr * _cos_dr,
							_asc, _asc, _dangle_dr, c_white, 1);
					}
				} else if (_dp_th > 0) {
					var _dta = max(0, (1.0 - _dp_th) * (1.0 - _dp_th * 0.5));
					var _dtc = make_color_rgb(max(80, 255 - round(_dp_th * 175)), min(255, 180 + round(_dp_th * 75)), 255);
					draw_composite_character_ext(_final_layers, _draw_x, _draw_y, _asc, _dta, _dtc, false, 0, c_white, _clip);
					if (_dp_th > 0.12) {
						var _tfa = min(0.30, (_dp_th - 0.12) * 0.5 * (1.0 - _dp_th * 0.85));
						var _tsp = _dp_th * _dp_th * 18;
						for (var _tfi = 0; _tfi < 4; _tfi++) {
							var _tfang = _tfi * (pi * 0.5) + _dp_th * 3.1;
							draw_composite_character_ext(_final_layers,
								_draw_x + cos(_tfang) * _tsp,
								_draw_y + sin(_tfang) * _tsp * 0.35,
								_asc * (1.0 - _dp_th * 0.35), _tfa, _dtc, false, 0, c_white, _clip);
						}
					}
				} else if (_melt_th > 0) {
					var _mxsc_th   = _asc * (1.0 + _melt_th * 0.8);
					var _mysc_th   = _asc * max(0.04, 1.0 - _melt_th * 0.96);
					var _malpha_th = max(0.0, 1.0 - max(0.0, _melt_th - 0.55) / 0.45);
					var _sink_th   = _melt_th * _csh * _asc * 0.5;
					var _char_cx_th = _draw_x + _csw * _asc * 0.5;
					var _feet_y_th  = _draw_y + _csh * _asc;
					for (var _mli_th = 0; _mli_th < array_length(_final_layers); _mli_th++) {
						var _ml_th = _final_layers[_mli_th];
						if (_ml_th.spr == -1) continue;
						var _mlw_th = sprite_get_width(_ml_th.spr);
						var _mlh_th = sprite_get_height(_ml_th.spr);
						var _orig_cx_th = _draw_x + (_ml_th.dx + _mlw_th * 0.5) * _asc;
						var _ml_x_th = _char_cx_th + (_orig_cx_th - _char_cx_th) * (_mxsc_th / _asc) - _mlw_th * _mxsc_th * 0.5;
						var _dist_th = (_draw_y + (_ml_th.dy + _mlh_th) * _asc) - _feet_y_th;
						var _ml_y_th = (_feet_y_th + _sink_th) + _dist_th * (_mysc_th / _asc) - _mlh_th * _mysc_th;
						draw_sprite_ext(_ml_th.spr, 0, _ml_x_th, _ml_y_th, _mxsc_th, _mysc_th, 0, c_white, _malpha_th);
					}
				} else if (_ang_th != 0) {
					var _rpx_th = (target_surface == -1) ? (_stg_x + _ax) : _ax;
					var _rpy_th = (target_surface == -1) ? (_stg_y + _ay - _csh * _asc * 0.82 + _y_off) : (_ay - _csh * _asc * 0.82 + _y_off);
					var _cos_th = dcos(_ang_th); var _sin_th = dsin(_ang_th);
					for (var _rli_th = 0; _rli_th < array_length(_final_layers); _rli_th++) {
						var _rl_th = _final_layers[_rli_th];
						if (_rl_th.spr == -1) continue;
						var _vx_th = (_draw_x + _rl_th.dx * _asc) - _rpx_th;
						var _vy_th = (_draw_y + _rl_th.dy * _asc) - _rpy_th;
						draw_sprite_ext(_rl_th.spr, 0, _rpx_th + _vx_th * _cos_th + _vy_th * _sin_th, _rpy_th - _vx_th * _sin_th + _vy_th * _cos_th, _asc, _asc, _ang_th, c_white, 1);
					}
				} else {
					var _dead_sel = _is_dead_dr && (target_surface == -1) && (_act.char_index == selected_character_index) && playing_block_index == -1;
					draw_composite_character_ext(_final_layers, _draw_x, _draw_y, _asc, 1, c_white, _dead_sel, 3, make_color_rgb(200, 30, 30), _clip);
				}
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

		var _qs_th_x = quake_x * (_stage_w / scene_win_w); var _qs_th_y = quake_y * (_stage_h / scene_win_h);
		draw_surface(o_char_surface, _stage_x + _qs_th_x, _stage_y + _qs_th_y);
		// Foreground mask drawn after particles — see below

	} else {
		// --- Unmasked Drawing ---
		draw_theater_actors(_stage_w, _stage_h, _stage_x, _stage_y);
	}
    
    gpu_set_scissor(0, 0, 1280, 960); // Reset clipping

    // --- Theater Beams ---
    if (array_length(active_beams) > 0) {
        gpu_set_scissor(_stage_x, _stage_y, _stage_w, _stage_h);
        var _b_sx = _stage_w / scene_win_w; var _b_sy = _stage_h / scene_win_h;
        for (var _tbmi = 0; _tbmi < array_length(active_beams); _tbmi++) {
            var _tbm = active_beams[_tbmi];
            if (_tbm.frames_total <= 0) continue;
            var _tbt = 1.0 - (_tbm.frames_remaining / _tbm.frames_total);
            var _thfrac = clamp(_tbt / 0.22, 0, 1.0);
            var _ttfrac = clamp((_tbt - 0.52) / 0.48, 0, 1.0);
            if (_ttfrac >= 1.0) continue;
            var _tbdx = cos(_tbm.angle); var _tbdy = sin(_tbm.angle);
            var _tblen;
            if (variable_struct_exists(_tbm, "beam_len")) {
                _tblen = _tbm.beam_len;
            } else {
                _tblen = 9999;
                if (abs(_tbdx) > 0.001) _tblen = min(_tblen, _tbdx>0 ? (scene_win_w-_tbm.x)/_tbdx : -_tbm.x/_tbdx);
                if (abs(_tbdy) > 0.001) _tblen = min(_tblen, _tbdy>0 ? (scene_win_h-_tbm.y)/_tbdy : -_tbm.y/_tbdy);
                _tblen = max(0, _tblen);
            }
            var _tbox = _stage_x + _tbm.x*_b_sx; var _tboy = _stage_y + _tbm.y*_b_sy;
            var _tbhx = _stage_x + (_tbm.x+_tbdx*_tblen*_thfrac)*_b_sx;
            var _tbhy = _stage_y + (_tbm.y+_tbdy*_tblen*_thfrac)*_b_sy;
            var _tbtx = _stage_x + (_tbm.x+_tbdx*_tblen*_ttfrac)*_b_sx;
            var _tbty = _stage_y + (_tbm.y+_tbdy*_tblen*_ttfrac)*_b_sy;
            var _tbrgb = get_beam_rgb(_tbm.color, _tbm.color_r, _tbm.color_g, _tbm.color_b);
            var _tbw = max(1, 2.5 * _tbm.size * _b_sy);
            draw_set_color(make_color_rgb(_tbrgb.r, _tbrgb.g, _tbrgb.b));
            draw_set_alpha(0.12); draw_line_width(_tbtx, _tbty, _tbhx, _tbhy, _tbw*10);
            draw_set_alpha(0.32); draw_line_width(_tbtx, _tbty, _tbhx, _tbhy, _tbw*5);
            draw_set_alpha(0.72); draw_line_width(_tbtx, _tbty, _tbhx, _tbhy, _tbw*2);
            var _tbcr = min(255,_tbrgb.r+115); var _tbcg = min(255,_tbrgb.g+115); var _tbcb = min(255,_tbrgb.b+115);
            draw_set_color(make_color_rgb(_tbcr, _tbcg, _tbcb));
            draw_set_alpha(0.95); draw_line_width(_tbtx, _tbty, _tbhx, _tbhy, max(0.5, _tbw*0.6));
            if (_ttfrac < 0.08) {
                draw_set_color(make_color_rgb(_tbcr, _tbcg, _tbcb));
                draw_set_alpha(0.65 * (1 - _ttfrac/0.08)); draw_circle(_tbox, _tboy, _tbw*5, false);
            }
            draw_set_alpha(1.0);
        }
        gpu_set_scissor(0, 0, 1280, 960);
    }

    // --- Theater Particles (before FX capture so distortion shaders include them) ---
    if (array_length(active_particles) > 0) {
        gpu_set_scissor(_stage_x, _stage_y, _stage_w, _stage_h);
        var _p_sx = _stage_w / scene_win_w;
        var _p_sy = _stage_h / scene_win_h;
        for (var _tpi = 0; _tpi < array_length(active_particles); _tpi++) {
            var _pp = active_particles[_tpi];
            var _t = _pp.life / _pp.max_life;
            draw_set_color(make_color_rgb(_pp.r, _pp.g, _pp.b));
            draw_set_alpha(_t * _t);
            var _tx = _stage_x + (_pp.x - scene_win_x) * _p_sx;
            var _ty = _stage_y + (_pp.y - scene_win_y) * _p_sy;
            if (variable_struct_exists(_pp, "shape") && _pp.shape == "line") {
                var _tx2 = _stage_x + ((_pp.x - _pp.vx * 2) - scene_win_x) * _p_sx;
                var _ty2 = _stage_y + ((_pp.y - _pp.vy * 2) - scene_win_y) * _p_sy;
                draw_line_width(_tx, _ty, _tx2, _ty2, max(1, _pp.size * _t * 0.5 * _p_sy));
            } else if (variable_struct_exists(_pp, "shape") && _pp.shape == "chunk") {
                var _crot_t = _pp.rot + (_pp.max_life - _pp.life) * _pp.spin;
                var _hw_t = max(0.5, _pp.cw * _pp.size * _t * _p_sy);
                var _hh_t = max(0.5, _pp.ch * _pp.size * _t * _p_sy);
                var _cc_t = cos(_crot_t); var _cs_t = sin(_crot_t);
                var _tx1 = _tx + (-_hw_t)*_cc_t - (-_hh_t)*_cs_t; var _ty1 = _ty + (-_hw_t)*_cs_t + (-_hh_t)*_cc_t;
                var _tx2 = _tx + ( _hw_t)*_cc_t - (-_hh_t)*_cs_t; var _ty2 = _ty + ( _hw_t)*_cs_t + (-_hh_t)*_cc_t;
                var _tx3 = _tx + ( _hw_t)*_cc_t - ( _hh_t)*_cs_t; var _ty3 = _ty + ( _hw_t)*_cs_t + ( _hh_t)*_cc_t;
                var _tx4 = _tx + (-_hw_t)*_cc_t - ( _hh_t)*_cs_t; var _ty4 = _ty + (-_hw_t)*_cs_t + ( _hh_t)*_cc_t;
                draw_triangle(_tx1, _ty1, _tx2, _ty2, _tx3, _ty3, false);
                draw_triangle(_tx1, _ty1, _tx3, _ty3, _tx4, _ty4, false);
            } else if (variable_struct_exists(_pp, "shape") && _pp.shape == "shard") {
                var _sang = arctan2(_pp.vy, _pp.vx);
                var _ssz  = max(0.5, _pp.size * _t * _p_sy);
                var _slen = _ssz * 2.2; var _swid = max(0.5, _ssz * 0.45);
                var _sperp = _sang + pi/2;
                draw_triangle(_tx + cos(_sang)*_slen,  _ty + sin(_sang)*_slen,
                              _tx + cos(_sperp)*_swid, _ty + sin(_sperp)*_swid,
                              _tx - cos(_sperp)*_swid, _ty - sin(_sperp)*_swid, false);
            } else {
                draw_circle(_tx, _ty, max(0.5, _pp.size * _t * _p_sy), false);
            }
        }
        draw_set_alpha(1.0);
        gpu_set_scissor(0, 0, 1280, 960);
    }

    // --- Theater Explosions ---
    if (array_length(active_explosions) > 0) {
        gpu_set_scissor(_stage_x, _stage_y, _stage_w, _stage_h);
        var _p_sx2 = _stage_w / scene_win_w; var _p_sy2 = _stage_h / scene_win_h;
        draw_active_explosions(_stage_x, _stage_y, _p_sx2, _p_sy2);
        gpu_set_scissor(0, 0, 1280, 960);
    }

    // --- Theater Decap Heads ---
    if (array_length(active_decap_heads) > 0) {
        gpu_set_scissor(_stage_x, _stage_y, _stage_w, _stage_h);
        var _th_psx = _stage_w / scene_win_w;
        var _th_psy = _stage_h / scene_win_h;
        var _th_asc = (scene_win_h * 1.5) / 450 * _th_psy;
        for (var _tdhi = 0; _tdhi < array_length(active_decap_heads); _tdhi++) {
            var _tdh = active_decap_heads[_tdhi];
            var _tdlys = get_composite_character_sprite(_tdh.char_index, _tdh.pose, _tdh.expression, _tdh.facing);
            var _tdbwpx = (_tdlys[0].spr != -1) ? sprite_get_width(_tdlys[0].spr) : 80;
            var _tdbhpx = (_tdlys[0].spr != -1) ? sprite_get_height(_tdlys[0].spr) : 200;
            var _td_neck_bx = _tdbwpx * 0.5;
            var _td_neck_by = _tdbhpx * 0.75;
            var _tdx = _stage_x + (_tdh.x - scene_win_x) * _th_psx;
            var _tdy = _stage_y + (_tdh.y - scene_win_y) * _th_psy;
            var _td_face = _tdlys[1];
            var _td_piv_x = _tdx + ((_td_face.spr != -1 ? _td_face.dx + sprite_get_width(_td_face.spr) * 0.5 : _td_neck_bx) - _td_neck_bx) * _th_asc;
            var _td_piv_y = _tdy + ((_td_face.spr != -1 ? _td_face.dy + sprite_get_height(_td_face.spr) * 0.5 : _td_neck_by) - _td_neck_by) * _th_asc;
            var _td_hcos = dcos(_tdh.angle); var _td_hsin = dsin(_tdh.angle);
            draw_set_alpha(_tdh.alpha);
            for (var _thli = 1; _thli < 4; _thli++) {
                var _thl = _tdlys[_thli];
                if (_thl.spr == -1) continue;
                var _tulx = _tdx + (_thl.dx - _td_neck_bx) * _th_asc;
                var _tuly = _tdy + (_thl.dy - _td_neck_by) * _th_asc;
                var _tox = _tulx - _td_piv_x; var _toy = _tuly - _td_piv_y;
                var _tsx_h = _td_piv_x + _tox * _td_hcos + _toy * _td_hsin;
                var _tsy_h = _td_piv_y - _tox * _td_hsin + _toy * _td_hcos;
                draw_sprite_ext(_thl.spr, 0, _tsx_h, _tsy_h, _th_asc, _th_asc, _tdh.angle, c_white, _tdh.alpha);
            }
            draw_set_alpha(1.0);
        }
        gpu_set_scissor(0, 0, 1280, 960);
    }

    // --- Theater Shots ---
    if (array_length(active_shots) > 0) {
        gpu_set_scissor(_stage_x, _stage_y, _stage_w, _stage_h);
        var _sth_sx = _stage_w / scene_win_w; var _sth_sy = _stage_h / scene_win_h;
        gpu_set_blendmode(bm_add);
        for (var _sthi = 0; _sthi < array_length(active_shots); _sthi++) {
            var _st = active_shots[_sthi];
            var _stx = _stage_x + _st.x * _sth_sx; var _sty = _stage_y + _st.y * _sth_sy;
            var _stco = cos(degtorad(_st.angle)); var _stsi = sin(degtorad(_st.angle));
            var _sthw = _st.w * _sth_sx * 0.5; var _sthh = _st.h * _sth_sy * 0.5;
            var _stx1 = _stx - _stco * _sthw; var _sty1 = _sty - _stsi * _sthw;
            var _stx2 = _stx + _stco * _sthw; var _sty2 = _sty + _stsi * _sthw;
            draw_set_color(make_color_rgb(_st.r, _st.g, _st.b));
            draw_set_alpha(_st.alpha * 0.12); draw_line_width(_stx1, _sty1, _stx2, _sty2, max(2, _sthh * 2 * 5));
            draw_set_alpha(_st.alpha * 0.35); draw_line_width(_stx1, _sty1, _stx2, _sty2, max(1.5, _sthh * 2 * 2.5));
            draw_set_alpha(_st.alpha * 0.80); draw_line_width(_stx1, _sty1, _stx2, _sty2, max(1, _sthh * 2));
            draw_set_color(make_color_rgb(min(255, _st.r + 110), min(255, _st.g + 110), min(255, _st.b + 110)));
            draw_set_alpha(_st.alpha); draw_line_width(_stx1, _sty1, _stx2, _sty2, max(0.5, _sthh * 0.7));
        }
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1.0);
        gpu_set_scissor(0, 0, 1280, 960);
    }

    // Draw foreground mask AFTER beams and particles so they appear behind the foreground layer
    if (_mask_sprite != -1) {
        gpu_set_scissor(_stage_x, _stage_y, _stage_w, _stage_h);
        var _mq_x = quake_x * (_stage_w / scene_win_w); var _mq_y = quake_y * (_stage_h / scene_win_h);
        draw_sprite_ext(_mask_sprite, 0, _stage_x + _mq_x, _stage_y + _mq_y, _bg_sc, _bg_sc, 0, c_white, 1);
        gpu_set_scissor(0, 0, 1280, 960);
    }

    // --- FX OVERLAY ---
    var _active_fx = (_scene_block != -1 && variable_struct_exists(_scene_block, "fx")) ? _scene_block.fx : "none";
    if (_active_fx == "fog" && shader_is_compiled(shFog)) {
        shader_set(shFog);
        shader_set_uniform_f(shader_get_uniform(shFog, "u_time"), current_time * 0.001);
        shader_set_uniform_f(shader_get_uniform(shFog, "u_rect"), _stage_x, _stage_y, _stage_w, _stage_h);
        gpu_set_blendmode(bm_normal);
        draw_set_color(c_white); draw_set_alpha(1.0);
        draw_rectangle(_stage_x, _stage_y, _stage_x + _stage_w, _stage_y + _stage_h, false);
        shader_reset();
        gpu_set_blendmode(bm_normal);
    } else if (_active_fx == "rain" && shader_is_compiled(shRain)) {
        shader_set(shRain);
        shader_set_uniform_f(shader_get_uniform(shRain, "u_time"), current_time * 0.001);
        shader_set_uniform_f(shader_get_uniform(shRain, "u_rect"), _stage_x, _stage_y, _stage_w, _stage_h);
        gpu_set_blendmode(bm_normal);
        draw_set_color(c_white); draw_set_alpha(1.0);
        draw_rectangle(_stage_x, _stage_y, _stage_x + _stage_w, _stage_y + _stage_h, false);
        shader_reset();
        gpu_set_blendmode(bm_normal);
    } else if (_active_fx == "snow" && shader_is_compiled(shSnow)) {
        shader_set(shSnow);
        shader_set_uniform_f(shader_get_uniform(shSnow, "u_time"), current_time * 0.001);
        shader_set_uniform_f(shader_get_uniform(shSnow, "u_rect"), _stage_x, _stage_y, _stage_w, _stage_h);
        gpu_set_blendmode(bm_normal);
        draw_set_color(c_white); draw_set_alpha(1.0);
        draw_rectangle(_stage_x, _stage_y, _stage_x + _stage_w, _stage_y + _stage_h, false);
        shader_reset();
        gpu_set_blendmode(bm_normal);
    } else if (_active_fx == "embers" && shader_is_compiled(shEmbers)) {
        shader_set(shEmbers);
        shader_set_uniform_f(shader_get_uniform(shEmbers, "u_time"), current_time * 0.001);
        shader_set_uniform_f(shader_get_uniform(shEmbers, "u_rect"), _stage_x, _stage_y, _stage_w, _stage_h);
        gpu_set_blendmode(bm_add);
        draw_set_color(c_white); draw_set_alpha(1.0);
        draw_rectangle(_stage_x, _stage_y, _stage_x + _stage_w, _stage_y + _stage_h, false);
        shader_reset();
        gpu_set_blendmode(bm_normal);
    } else if (_active_fx == "static" && shader_is_compiled(shStatic)) {
        shader_set(shStatic);
        shader_set_uniform_f(shader_get_uniform(shStatic, "u_time"), current_time * 0.001);
        shader_set_uniform_f(shader_get_uniform(shStatic, "u_rect"), _stage_x, _stage_y, _stage_w, _stage_h);
        gpu_set_blendmode(bm_normal);
        draw_set_color(c_white); draw_set_alpha(1.0);
        draw_rectangle(_stage_x, _stage_y, _stage_x + _stage_w, _stage_y + _stage_h, false);
        shader_reset();
        gpu_set_blendmode(bm_normal);
    } else if (_active_fx == "heat" && shader_is_compiled(shHeat)) {
        var _hsw = ceil(_stage_w); var _hsh = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _hsw || surface_get_height(heat_surface) != _hsh) {
            if (surface_exists(heat_surface)) surface_free(heat_surface);
            heat_surface = surface_create(_hsw, _hsh);
        }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _hsw, _hsh);
        shader_set(shHeat);
        shader_set_uniform_f(shader_get_uniform(shHeat, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0);
        draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h);
        shader_reset();
    } else if (_active_fx == "moonlight" && shader_is_compiled(shMoonlight)) {
        var _sw = ceil(_stage_w); var _sh2 = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _sw || surface_get_height(heat_surface) != _sh2) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_sw, _sh2); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _sw, _sh2);
        shader_set(shMoonlight); shader_set_uniform_f(shader_get_uniform(shMoonlight, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "sunlight" && shader_is_compiled(shSunlight)) {
        var _sw = ceil(_stage_w); var _sh2 = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _sw || surface_get_height(heat_surface) != _sh2) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_sw, _sh2); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _sw, _sh2);
        shader_set(shSunlight); shader_set_uniform_f(shader_get_uniform(shSunlight, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "filth" && shader_is_compiled(shFilth)) {
        var _sw = ceil(_stage_w); var _sh2 = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _sw || surface_get_height(heat_surface) != _sh2) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_sw, _sh2); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _sw, _sh2);
        shader_set(shFilth); shader_set_uniform_f(shader_get_uniform(shFilth, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "candlelight" && shader_is_compiled(shCandlelight)) {
        var _sw = ceil(_stage_w); var _sh2 = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _sw || surface_get_height(heat_surface) != _sh2) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_sw, _sh2); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _sw, _sh2);
        shader_set(shCandlelight); shader_set_uniform_f(shader_get_uniform(shCandlelight, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "crt" && shader_is_compiled(shCRT)) {
        var _sw = ceil(_stage_w); var _sh2 = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _sw || surface_get_height(heat_surface) != _sh2) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_sw, _sh2); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _sw, _sh2);
        shader_set(shCRT); shader_set_uniform_f(shader_get_uniform(shCRT, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "frigid" && shader_is_compiled(shFrigid)) {
        var _sw = ceil(_stage_w); var _sh2 = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _sw || surface_get_height(heat_surface) != _sh2) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_sw, _sh2); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _sw, _sh2);
        shader_set(shFrigid); shader_set_uniform_f(shader_get_uniform(shFrigid, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "goldenhour" && shader_is_compiled(shGoldenHour)) {
        var _sw = ceil(_stage_w); var _sh2 = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _sw || surface_get_height(heat_surface) != _sh2) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_sw, _sh2); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _sw, _sh2);
        shader_set(shGoldenHour); shader_set_uniform_f(shader_get_uniform(shGoldenHour, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "darken" && shader_is_compiled(shDarken)) {
        var _sw = ceil(_stage_w); var _sh2 = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _sw || surface_get_height(heat_surface) != _sh2) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_sw, _sh2); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _sw, _sh2);
        shader_set(shDarken); shader_set_uniform_f(shader_get_uniform(shDarken, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "blackwhite" && shader_is_compiled(shBlackWhite)) {
        var _sw = ceil(_stage_w); var _sh2 = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _sw || surface_get_height(heat_surface) != _sh2) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_sw, _sh2); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _sw, _sh2);
        shader_set(shBlackWhite); shader_set_uniform_f(shader_get_uniform(shBlackWhite, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "brighten" && shader_is_compiled(shBrighten)) {
        var _sw = ceil(_stage_w); var _sh2 = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _sw || surface_get_height(heat_surface) != _sh2) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_sw, _sh2); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _sw, _sh2);
        shader_set(shBrighten); shader_set_uniform_f(shader_get_uniform(shBrighten, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "dream" && shader_is_compiled(shDream)) {
        var _sw = ceil(_stage_w); var _sh2 = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _sw || surface_get_height(heat_surface) != _sh2) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_sw, _sh2); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _sw, _sh2);
        shader_set(shDream); shader_set_uniform_f(shader_get_uniform(shDream, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "drunk" && shader_is_compiled(shDrunk)) {
        var _dsw = ceil(_stage_w); var _dsh = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _dsw || surface_get_height(heat_surface) != _dsh) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_dsw, _dsh); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _dsw, _dsh);
        shader_set(shDrunk); shader_set_uniform_f(shader_get_uniform(shDrunk, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "stoned" && shader_is_compiled(shStoned)) {
        var _sw = ceil(_stage_w); var _sh2 = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _sw || surface_get_height(heat_surface) != _sh2) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_sw, _sh2); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _sw, _sh2);
        shader_set(shStoned); shader_set_uniform_f(shader_get_uniform(shStoned, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "underwater" && shader_is_compiled(shUnderwater)) {
        var _usw = ceil(_stage_w); var _ush = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _usw || surface_get_height(heat_surface) != _ush) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_usw, _ush); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _usw, _ush);
        shader_set(shUnderwater); shader_set_uniform_f(shader_get_uniform(shUnderwater, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "nightvision" && shader_is_compiled(shNightVision)) {
        var _nsw = ceil(_stage_w); var _nsh = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _nsw || surface_get_height(heat_surface) != _nsh) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_nsw, _nsh); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _nsw, _nsh);
        shader_set(shNightVision); shader_set_uniform_f(shader_get_uniform(shNightVision, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "infrared" && shader_is_compiled(shInfrared)) {
        var _isw = ceil(_stage_w); var _ish = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _isw || surface_get_height(heat_surface) != _ish) { if (surface_exists(heat_surface)) surface_free(heat_surface); heat_surface = surface_create(_isw, _ish); }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _isw, _ish);
        shader_set(shInfrared); shader_set_uniform_f(shader_get_uniform(shInfrared, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0); draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h); shader_reset();
    } else if (_active_fx == "sepia" && shader_is_compiled(shSepia)) {
        var _ssw = ceil(_stage_w); var _ssh = ceil(_stage_h);
        if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _ssw || surface_get_height(heat_surface) != _ssh) {
            if (surface_exists(heat_surface)) surface_free(heat_surface);
            heat_surface = surface_create(_ssw, _ssh);
        }
        surface_copy_part(heat_surface, 0, 0, application_surface, round(_stage_x), round(_stage_y), _ssw, _ssh);
        shader_set(shSepia);
        shader_set_uniform_f(shader_get_uniform(shSepia, "u_time"), current_time * 0.001);
        draw_set_color(c_white); draw_set_alpha(1.0);
        draw_surface_stretched(heat_surface, _stage_x, _stage_y, _stage_w, _stage_h);
        shader_reset();
    }

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
            var _is_alt = _is_v && (variable_struct_exists(_pb, "is_altered") ? _pb.is_altered : (_pb.voice_id != _c_ref.voice_id || _pb.pitch != _c_ref.pitch || _pb.speed != _c_ref.speed || _pb.mode != _c_ref.mode || _pb.style != _c_ref.style || (_pb[$ "glottal"] ?? -1) != (_c_ref[$ "glottal"] ?? -1) || _pb.tweaked != _c_ref.tweaked));
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
    
    // Controls (auto-hide when playing and mouse idle)
    var _theater_ui_vis = (theater_ui_timer > 0 || theater_paused);
    if (_theater_ui_vis) {
        // EXIT Button (Bottom Right)
        var _ex = 1280 - 200; var _ey = 860; var _ew = 180; var _eh = 50;
        var _ehov = (mouse_x > _ex && mouse_x < _ex + _ew && mouse_y > _ey && mouse_y < _ey + _eh);
        draw_set_color(_ehov ? make_color_rgb(200,60,60) : make_color_rgb(155,38,38));
        draw_roundrect_ext(_ex, _ey, _ex+_ew, _ey+_eh, 7, 7, false);
        draw_set_color(_ehov ? c_white : make_color_rgb(235,100,100));
        draw_roundrect_ext(_ex, _ey, _ex+_ew, _ey+_eh, 7, 7, true);
        draw_set_color(c_white); draw_set_halign(fa_center);
        draw_text(_ex + 90, _ey + 17, "EXIT THEATER");
        draw_set_halign(fa_left);

        // PLAY/PAUSE Button (Bottom Left)
        var _px = 30; var _py = 860; var _pw = 120; var _ph = 50;
        var _phov = (mouse_x > _px && mouse_x < _px + _pw && mouse_y > _py && mouse_y < _py + _ph);
        var _paused = theater_paused;
        draw_set_color(_paused ? (_phov ? make_color_rgb(45,175,70) : make_color_rgb(25,140,50)) : (_phov ? make_color_rgb(95,68,178) : make_color_rgb(70,45,140)));
        draw_roundrect_ext(_px, _py, _px+_pw, _py+_ph, 7, 7, false);
        draw_set_color(_paused ? (_phov ? c_white : make_color_rgb(75,215,105)) : (_phov ? c_white : make_color_rgb(150,120,250)));
        draw_roundrect_ext(_px, _py, _px+_pw, _py+_ph, 7, 7, true);
        draw_set_color(c_white); draw_set_halign(fa_center);
        draw_text(_px + 60, _py + 17, theater_paused ? "PLAY" : "PAUSE");
        draw_set_halign(fa_left);
    }
    
    _render_live_titles();
    
    return; // Stop here if in theater mode
}

// Layout override for expanded script mode (recalculated every frame)
if (script_expanded) {
    box_x = 5; box_w = 1270;
    box_y = 90; box_h = 855;
    btn_play_y = 52;
} else {
    box_x = 50; box_w = 1180;
    box_y = 570; box_h = 370;
    btn_play_y = 535;
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

if (script_expanded) {
    // Push off-screen so they don't draw or intercept clicks
    btn_theater_x = -1000; btn_theater_y = -1000;
    btn_dictionary_x = -1000; btn_dictionary_y = -1000;
}
var _d_hov = (!_overlay_active && playing_block_index == -1 && _mx > btn_dictionary_x && _mx < btn_dictionary_x + btn_dictionary_w && _my > btn_dictionary_y && _my < btn_dictionary_y + btn_dictionary_h);
var _d_dis = (playing_block_index != -1);
draw_set_color(_d_dis ? make_color_rgb(50,50,60) : (_d_hov ? make_color_rgb(35,130,145) : make_color_rgb(25,95,105)));
draw_roundrect_ext(btn_dictionary_x, btn_dictionary_y, btn_dictionary_x+btn_dictionary_w, btn_dictionary_y+btn_dictionary_h, 5, 5, false);
draw_set_color(_d_dis ? make_color_rgb(75,75,85) : (_d_hov ? c_white : make_color_rgb(65,185,200)));
draw_roundrect_ext(btn_dictionary_x, btn_dictionary_y, btn_dictionary_x+btn_dictionary_w, btn_dictionary_y+btn_dictionary_h, 5, 5, true);
draw_set_color(c_white); draw_set_halign(fa_center); draw_text(btn_dictionary_x+(btn_dictionary_w/2), btn_dictionary_y+10, "DICTIONARY"); draw_set_halign(fa_left);

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
var _fm_open = (_fm_hov || file_menu_open);
draw_set_color(playing_block_index != -1 ? make_color_rgb(30, 50, 32) : (_fm_open ? make_color_rgb(22, 90, 30) : make_color_rgb(14, 62, 20)));
draw_roundrect_ext(_fm_btn_x, _fm_btn_y, _fm_btn_x + _fm_btn_w, _fm_btn_y + _fm_btn_h, 5, 5, false);
draw_set_color(playing_block_index != -1 ? make_color_rgb(60, 80, 62) : (_fm_open ? c_white : make_color_rgb(196, 213, 20)));
draw_roundrect_ext(_fm_btn_x, _fm_btn_y, _fm_btn_x + _fm_btn_w, _fm_btn_y + _fm_btn_h, 5, 5, true);
draw_set_color(c_white); draw_set_halign(fa_center);
draw_text(_fm_btn_x + (_fm_btn_w / 2), _fm_btn_y + 10, "FILE");
draw_set_halign(fa_left);


// --- 1b. SCENE WINDOW ---
draw_set_color(c_black);
draw_rectangle(scene_win_x - 2, scene_win_y - 2, scene_win_x + scene_win_w + 2, scene_win_y + scene_win_h + 2, false);
if (scene_edit_mode) {
    draw_set_color(make_color_rgb(255, 150, 0));
    draw_rectangle(scene_win_x - 4, scene_win_y - 4, scene_win_x + scene_win_w + 4, scene_win_y + scene_win_h + 4, true);
    draw_rectangle(scene_win_x - 5, scene_win_y - 5, scene_win_x + scene_win_w + 5, scene_win_y + scene_win_h + 5, true);
} else if (focused_block != -1 && focused_block < array_length(script_blocks) - 1) {
    draw_set_color(make_color_rgb(0, 150, 255));
    draw_rectangle(scene_win_x - 4, scene_win_y - 4, scene_win_x + scene_win_w + 4, scene_win_y + scene_win_h + 4, true);
    draw_rectangle(scene_win_x - 5, scene_win_y - 5, scene_win_x + scene_win_w + 5, scene_win_y + scene_win_h + 5, true);
}
if (current_scene_sprite != -1) {
    var _sw = sprite_get_width(current_scene_sprite);
    var _sh = sprite_get_height(current_scene_sprite);
    draw_sprite_ext(current_scene_sprite, 0, scene_win_x + quake_x, scene_win_y + quake_y, scene_win_w / _sw, scene_win_h / _sh, 0, c_white, 1);
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
				if (variable_struct_exists(_act, "hidden") && _act.hidden) continue;

				var _pose  = variable_struct_exists(_act, "pose")       ? _act.pose       : 1;
				var _expr  = variable_struct_exists(_act, "expression") ? _act.expression : 21;
				var _aface = variable_struct_exists(_act, "facing")     ? _act.facing     : undefined;

				// Canned animation override
				if (variable_struct_exists(_act, "canned_spr") && _act.canned_spr != -1) {
				    var _canned_ay2 = variable_struct_exists(_act, "canned_anchor_y") ? _act.canned_anchor_y : 0;
				    var _feet_spr2  = (variable_struct_exists(_act, "canned_composite") && _act.canned_composite
				                       && variable_struct_exists(_act, "canned_feet_spr") && _act.canned_feet_spr != -1)
				                      ? _act.canned_feet_spr : -1;
				    if (_feet_spr2 != -1) {
				        var _canned_h2  = sprite_get_height(_act.canned_spr);
				        var _body_dy2   = variable_struct_exists(_act, "canned_body_dy") ? _act.canned_body_dy : 0;
				        var _body_dx2   = variable_struct_exists(_act, "canned_body_dx") ? _act.canned_body_dx : 0;
				        var _composite_legs2 = !variable_struct_exists(_act, "canned_composite_legs") || _act.canned_composite_legs;
				        var _dy_val2 = -_canned_h2 + _canned_ay2 + _body_dy2;
				        if (!_composite_legs2) {
				            var _feet_h2 = sprite_get_height(_feet_spr2);
				            _dy_val2 = _feet_h2 - _canned_h2 + _canned_ay2 + _body_dy2;
				        }
				        _layers = [{ spr: _feet_spr2,      dx: 0,         dy: 0 },
				                   { spr: _act.canned_spr, dx: _body_dx2, dy: _dy_val2 },
				                   { spr: -1, dx: 0, dy: 0 }, { spr: -1, dx: 0, dy: 0 }];
				    } else {
				        var _body_dy2   = variable_struct_exists(_act, "canned_body_dy") ? _act.canned_body_dy : 0;
				        var _body_dx2   = variable_struct_exists(_act, "canned_body_dx") ? _act.canned_body_dx : 0;
				        _layers = [{ spr: _act.canned_spr, dx: _body_dx2, dy: _canned_ay2 + _body_dy2 },
				                   { spr: -1, dx: 0, dy: 0 }, { spr: -1, dx: 0, dy: 0 }, { spr: -1, dx: 0, dy: 0 }];
				    }
				} else {
				    _layers = get_composite_character_sprite(_act.char_index, _pose, _expr, _aface);
				}
				var _spr    = _layers[0].spr;

				if (_spr != -1) {
					var _csw = sprite_get_width(_spr), _csh = sprite_get_height(_spr);
					var _sc = (scene_win_h * 1.5) / 450;
					var _y_off  = variable_struct_exists(_act, "y_offset")  ? _act.y_offset  : 0;
					var _jit_x  = variable_struct_exists(_act, "jitter_x")  ? _act.jitter_x  : 0;
					var _jit_y  = variable_struct_exists(_act, "jitter_y")  ? _act.jitter_y  : 0;
					var _draw_x = (target_surface == -1) ? (scene_win_x + _act.x - (_csw * _sc)/2 + _jit_x + quake_x) : (_act.x - (_csw * _sc)/2 + _jit_x);
					var _draw_y = (target_surface == -1) ? (scene_win_y + _act.y - (_csh * _sc) + _y_off + _jit_y + quake_y) : (_act.y - (_csh * _sc) + _y_off + _jit_y);

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
							var _adj_dur = 0;
							if (current_viseme_total_ms > 0 && speak_start_time_ms >= 0) {
								var _t_speed_val = max(1, 50 + _spk_speed * 2.5);
								_adj_dur = current_viseme_total_ms * (175.0 / _t_speed_val);
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
								var _vi = 0;
								for (_vi = 0; _vi < array_length(current_viseme_data); _vi++) {
									if (current_viseme_data[_vi].t <= _prog) _cur_v = current_viseme_data[_vi].v; else break;
								}
								// Hold the last open shape so the mouth doesn't snap closed between phonemes.
								if (_cur_v != 0) {
									mouth_last_vis_time_ms = current_time; mouth_last_vis_value = _cur_v;
								} else if (mouth_last_vis_time_ms >= 0 && current_time - mouth_last_vis_time_ms < 500) {
									_cur_v = mouth_last_vis_value;
								} else if (current_viseme_total_ms > 0 && mouth_last_vis_value != 0) {
									for (var _vla = _vi; _vla < array_length(current_viseme_data); _vla++) {
										if (current_viseme_data[_vla].v != 0) {
											if ((current_viseme_data[_vla].t - _prog) * _adj_dur < 400) _cur_v = mouth_last_vis_value;
											break;
										}
									}
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

					var _is_dead_ed  = variable_struct_exists(_act, "dead") && _act.dead;
					var _dstyle_ed   = _is_dead_ed ? (variable_struct_exists(_act, "death_style") ? _act.death_style : "sudden") : "";
					var _dangle_ed   = _is_dead_ed ? (variable_struct_exists(_act, "death_angle") ? _act.death_angle : 0) : 0;
					var _final_layers = [];
					for (var _li = 0; _li < array_length(_layers); _li++) {
						var _l       = _layers[_li];
						if (_is_dead_ed && _dstyle_ed == "decapitate" && _li > 0) {
							array_push(_final_layers, { spr: -1, dx: _l.dx, dy: _l.dy });
							continue;
						}
						var _is_anim = variable_struct_exists(_l, "is_mouth") && _has_manim && _mouth_open && !_is_dead_ed;
						var _ae      = _is_anim ? _mouth_anim[_manim_fi] : undefined;
						var _lspr    = _is_anim ? _ae.spr : _l.spr;
						if (_li == 0 && (variable_struct_exists(_act, "canned_composite_legs") && !_act.canned_composite_legs)) {
							_lspr = -1;
						}
						var _ldx     = _l.dx + (_is_anim ? _ae.dx : 0);
						var _ldy     = _l.dy + (_is_anim ? _ae.dy : 0);
						array_push(_final_layers, { spr: _lspr, dx: _ldx, dy: _ldy });
					}

					// Outline: yellow for alive+selected, red for dead+selected
					if (_draw_outline && playing_block_index == -1 && selected_character_index == _act.char_index) {
						var _outline_col = _is_dead_ed ? make_color_rgb(220, 30, 30) : c_yellow;
						var _os = _sc * 1.18;
						for (var _oli = 0; _oli < array_length(_final_layers); _oli++) {
							var _ol = _final_layers[_oli];
							if (_ol.spr != -1) {
								var _lw = sprite_get_width(_ol.spr);
								var _lh = sprite_get_height(_ol.spr);
								var _olx = _draw_x + _ol.dx * _sc - _lw * (_os - _sc) * 0.5;
								var _oly = _draw_y + _ol.dy * _sc - _lh * (_os - _sc) * 0.5;
								draw_sprite_ext(_ol.spr, 0, _olx, _oly, _os, _os, 0, _outline_col, _alpha);
							}
						}
					}

					if (_draw_sprite) {
						var _clip = (target_surface == -1) ? [scene_win_x, scene_win_y, scene_win_w, scene_win_h] : undefined;
						var _dp   = variable_struct_exists(_act, "dissolve_progress") ? _act.dissolve_progress : 0;
						var _melt = variable_struct_exists(_act, "melt_progress")     ? _act.melt_progress     : 0;
						if (_dp > 0) {
							// Electric disintegration visual
							var _d_main_a = max(0, (1.0 - _dp) * (1.0 - _dp * 0.5));
							var _d_tint   = make_color_rgb(max(80, 255 - round(_dp * 175)), min(255, 180 + round(_dp * 75)), 255);
							draw_composite_character_ext(_final_layers, _draw_x, _draw_y, _sc, _d_main_a, _d_tint, false, 0, c_white, _clip);
							if (_dp > 0.12) {
								var _fa = min(0.30, (_dp - 0.12) * 0.5 * (1.0 - _dp * 0.85));
								var _spread = _dp * _dp * 18;
								for (var _fi2 = 0; _fi2 < 4; _fi2++) {
									var _fang2 = _fi2 * (pi * 0.5) + _dp * 3.1;
									draw_composite_character_ext(_final_layers,
										_draw_x + cos(_fang2) * _spread,
										_draw_y + sin(_fang2) * _spread * 0.35,
										_sc * (1.0 - _dp * 0.35), _fa, _d_tint, false, 0, c_white, _clip);
								}
							}
						} else if (_melt > 0) {
							// Melt: squish wide + flatten + drip down, bottom-anchored
							var _mxsc   = _sc * (1.0 + _melt * 0.8);
							var _mysc   = _sc * max(0.04, 1.0 - _melt * 0.96);
							var _malpha = max(0.0, 1.0 - max(0.0, _melt - 0.55) / 0.45);
							var _sink   = _melt * _csh * _sc * 0.5;
							var _char_cx = _draw_x + _csw * _sc * 0.5;
							var _feet_y  = _draw_y + _csh * _sc;
							for (var _mli = 0; _mli < array_length(_final_layers); _mli++) {
								var _ml = _final_layers[_mli];
								if (_ml.spr == -1) continue;
								var _mlw = sprite_get_width(_ml.spr);
								var _mlh = sprite_get_height(_ml.spr);
								var _orig_cx = _draw_x + (_ml.dx + _mlw * 0.5) * _sc;
								var _ml_x = _char_cx + (_orig_cx - _char_cx) * (_mxsc / _sc) - _mlw * _mxsc * 0.5;
								var _dist_from_feet = (_draw_y + (_ml.dy + _mlh) * _sc) - _feet_y;
								var _ml_y = (_feet_y + _sink) + _dist_from_feet * (_mysc / _sc) - _mlh * _mysc;
								draw_sprite_ext(_ml.spr, 0, _ml_x, _ml_y, _mxsc, _mysc, 0, c_white, _malpha);
							}
						} else if (_is_dead_ed && (_dstyle_ed == "fall_forwards" || _dstyle_ed == "fall_backwards") && _dangle_ed != 0) {
							// Fall: rotate all layers around foot pivot
							var _rpx_ed = (target_surface == -1) ? (scene_win_x + _act.x) : _act.x;
							var _rpy_ed = (target_surface == -1) ? (scene_win_y + _act.y + _y_off) : (_act.y + _y_off);
							var _cos_ed = dcos(_dangle_ed); var _sin_ed = dsin(_dangle_ed);
							var _dead_sel_fall = (target_surface == -1) && (_act.char_index == selected_character_index) && playing_block_index == -1;
							for (var _rli_ed = 0; _rli_ed < array_length(_final_layers); _rli_ed++) {
								var _rl_ed = _final_layers[_rli_ed];
								if (_rl_ed.spr == -1) continue;
								var _vx_ed = (_draw_x + _rl_ed.dx * _sc) - _rpx_ed;
								var _vy_ed = (_draw_y + _rl_ed.dy * _sc) - _rpy_ed;
								var _rx_ed = _rpx_ed + _vx_ed * _cos_ed + _vy_ed * _sin_ed;
								var _ry_ed = _rpy_ed - _vx_ed * _sin_ed + _vy_ed * _cos_ed;
								if (_dead_sel_fall) {
									var _lw_e = sprite_get_width(_rl_ed.spr); var _lh_e = sprite_get_height(_rl_ed.spr);
									var _os_e = _sc * 1.18;
									var _olx_e = _rx_ed - _lw_e * (_os_e - _sc) * 0.5; var _oly_e = _ry_ed - _lh_e * (_os_e - _sc) * 0.5;
									draw_sprite_ext(_rl_ed.spr, 0, _olx_e, _oly_e, _os_e, _os_e, _dangle_ed, make_color_rgb(220, 30, 30), _alpha);
								}
								draw_sprite_ext(_rl_ed.spr, 0, _rx_ed, _ry_ed, _sc, _sc, _dangle_ed, c_white, _alpha);
							}
						} else {
							var _img_angle = variable_struct_exists(_act, "image_angle") ? _act.image_angle : 0;
							if (_img_angle != 0) {
								// Silly flip: pivot at face/head level (~18% from top of sprite)
								var _rpx = (target_surface == -1) ? (scene_win_x + _act.x) : _act.x;
								var _rpy = (target_surface == -1) ? (scene_win_y + _act.y - _csh * _sc * 0.82 + _y_off) : (_act.y - _csh * _sc * 0.82 + _y_off);
								var _cos_a = dcos(_img_angle);
								var _sin_a = dsin(_img_angle);
								for (var _rli = 0; _rli < array_length(_final_layers); _rli++) {
									var _rl = _final_layers[_rli];
									if (_rl.spr == -1) continue;
									var _vx = (_draw_x + _rl.dx * _sc) - _rpx;
									var _vy = (_draw_y + _rl.dy * _sc) - _rpy;
									draw_sprite_ext(_rl.spr, 0, _rpx + _vx * _cos_a + _vy * _sin_a, _rpy - _vx * _sin_a + _vy * _cos_a, _sc, _sc, _img_angle, c_white, _alpha);
								}
							} else {
								var _dead_sel_ed = _is_dead_ed && (target_surface == -1) && (_act.char_index == selected_character_index) && playing_block_index == -1;
								draw_composite_character_ext(_final_layers, _draw_x, _draw_y, _sc, _alpha, c_white, _dead_sel_ed, 3, make_color_rgb(200, 30, 30), _clip);
							}
						}
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

		draw_surface(o_char_surface, scene_win_x + quake_x, scene_win_y + quake_y);
		// Foreground mask drawn after particles — see below

	} else {
		// --- Unmasked Drawing ---
		draw_editor_actors(_scene, -1, false, true);
	};



	// --- Active Beams ---
	if (array_length(active_beams) > 0) {
		gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
		for (var _bmi = 0; _bmi < array_length(active_beams); _bmi++) {
			var _bm = active_beams[_bmi];
			if (_bm.frames_total <= 0) continue;
			var _bt = 1.0 - (_bm.frames_remaining / _bm.frames_total);
			var _hfrac = clamp(_bt / 0.22, 0, 1.0);
			var _tfrac = clamp((_bt - 0.52) / 0.48, 0, 1.0);
			if (_tfrac >= 1.0) continue;
			var _box = scene_win_x + _bm.x; var _boy = scene_win_y + _bm.y;
			var _bdx = cos(_bm.angle); var _bdy = sin(_bm.angle);
			var _blen;
			if (variable_struct_exists(_bm, "beam_len")) {
			    _blen = _bm.beam_len;
			} else {
			    _blen = 9999;
			    if (abs(_bdx) > 0.001) _blen = min(_blen, _bdx>0 ? (scene_win_x+scene_win_w-_box)/_bdx : (scene_win_x-_box)/_bdx);
			    if (abs(_bdy) > 0.001) _blen = min(_blen, _bdy>0 ? (scene_win_y+scene_win_h-_boy)/_bdy : (scene_win_y-_boy)/_bdy);
			    _blen = max(0, _blen);
			}
			var _bhx = _box + _bdx*_blen*_hfrac; var _bhy = _boy + _bdy*_blen*_hfrac;
			var _btx = _box + _bdx*_blen*_tfrac; var _bty = _boy + _bdy*_blen*_tfrac;
			var _brgb = get_beam_rgb(_bm.color, _bm.color_r, _bm.color_g, _bm.color_b);
			var _bw = max(1, 2.5 * _bm.size);
			draw_set_color(make_color_rgb(_brgb.r, _brgb.g, _brgb.b));
			draw_set_alpha(0.12); draw_line_width(_btx, _bty, _bhx, _bhy, _bw*10);
			draw_set_alpha(0.32); draw_line_width(_btx, _bty, _bhx, _bhy, _bw*5);
			draw_set_alpha(0.72); draw_line_width(_btx, _bty, _bhx, _bhy, _bw*2);
			var _bcr = min(255,_brgb.r+115); var _bcg = min(255,_brgb.g+115); var _bcb = min(255,_brgb.b+115);
			draw_set_color(make_color_rgb(_bcr, _bcg, _bcb));
			draw_set_alpha(0.95); draw_line_width(_btx, _bty, _bhx, _bhy, max(0.5, _bw*0.6));
			if (_tfrac < 0.08) {
				draw_set_color(make_color_rgb(_bcr, _bcg, _bcb));
				draw_set_alpha(0.65 * (1 - _tfrac/0.08)); draw_circle(_box, _boy, _bw*5, false);
			}
			draw_set_alpha(1.0);
		}
		gpu_set_scissor(0, 0, 1280, 960);
	}

	// --- Active Particles ---
	if (array_length(active_particles) > 0) {
		gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
		var _pp_add = false; // track current blend mode
		for (var _ppi = 0; _ppi < array_length(active_particles); _ppi++) {
			var _pp = active_particles[_ppi];
			var _t  = _pp.life / _pp.max_life;
			// switch blend mode only when needed
			var _is_add = variable_struct_exists(_pp, "additive") && _pp.additive;
			if (_is_add != _pp_add) {
				gpu_set_blendmode(_is_add ? bm_add : bm_normal);
				_pp_add = _is_add;
			}
			// color over lifetime: lerp from r2/g2/b2 (dying) to r/g/b (fresh)
			var _cr = variable_struct_exists(_pp, "r2") ? floor(lerp(_pp.r2, _pp.r, _t)) : _pp.r;
			var _cg = variable_struct_exists(_pp, "g2") ? floor(lerp(_pp.g2, _pp.g, _t)) : _pp.g;
			var _cb = variable_struct_exists(_pp, "b2") ? floor(lerp(_pp.b2, _pp.b, _t)) : _pp.b;
			draw_set_color(make_color_rgb(_cr, _cg, _cb));
			// additive particles use linear fade; normal use quadratic (stays bright longer then drops)
			draw_set_alpha(_is_add ? _t : _t * _t);
			var _pshape = variable_struct_exists(_pp, "shape") ? _pp.shape : "";
			if (_pshape == "line") {
				draw_line_width(_pp.x, _pp.y, _pp.x - _pp.vx * 2, _pp.y - _pp.vy * 2, max(1, _pp.size * _t * 0.5));
			} else if (_pshape == "shard") {
				var _sang = arctan2(_pp.vy, _pp.vx);
				var _ssz  = max(0.5, _pp.size * _t);
				var _slen = _ssz * 2.2; var _swid = max(0.5, _ssz * 0.45);
				var _sperp = _sang + pi/2;
				draw_triangle(_pp.x + cos(_sang)*_slen,  _pp.y + sin(_sang)*_slen,
				              _pp.x + cos(_sperp)*_swid, _pp.y + sin(_sperp)*_swid,
				              _pp.x - cos(_sperp)*_swid, _pp.y - sin(_sperp)*_swid, false);
			} else if (_pshape == "chunk") {
				var _crot = _pp.rot + (_pp.max_life - _pp.life) * _pp.spin;
				var _hw = max(0.5, _pp.cw * _pp.size * _t);
				var _hh = max(0.5, _pp.ch * _pp.size * _t);
				var _cc = cos(_crot); var _cs = sin(_crot);
				var _qx1 = _pp.x + (-_hw)*_cc - (-_hh)*_cs;  var _qy1 = _pp.y + (-_hw)*_cs + (-_hh)*_cc;
				var _qx2 = _pp.x + ( _hw)*_cc - (-_hh)*_cs;  var _qy2 = _pp.y + ( _hw)*_cs + (-_hh)*_cc;
				var _qx3 = _pp.x + ( _hw)*_cc - ( _hh)*_cs;  var _qy3 = _pp.y + ( _hw)*_cs + ( _hh)*_cc;
				var _qx4 = _pp.x + (-_hw)*_cc - ( _hh)*_cs;  var _qy4 = _pp.y + (-_hw)*_cs + ( _hh)*_cc;
				draw_triangle(_qx1, _qy1, _qx2, _qy2, _qx3, _qy3, false);
				draw_triangle(_qx1, _qy1, _qx3, _qy3, _qx4, _qy4, false);
			} else if (_pshape == "lick") {
				var _lang = arctan2(_pp.vy, _pp.vx);
				var _lsz  = max(0.5, _pp.size * _t);
				var _lperp = _lang + pi/2;
				draw_triangle(
				    _pp.x + cos(_lang)  * _lsz * 2.2,  _pp.y + sin(_lang)  * _lsz * 2.2,
				    _pp.x + cos(_lperp) * _lsz * 0.85, _pp.y + sin(_lperp) * _lsz * 0.85,
				    _pp.x - cos(_lperp) * _lsz * 0.85, _pp.y - sin(_lperp) * _lsz * 0.85,
				    false);
			} else {
				draw_circle(_pp.x, _pp.y, max(0.5, _pp.size * _t), false);
			}
		}
		if (_pp_add) gpu_set_blendmode(bm_normal);
		draw_set_alpha(1.0);
		gpu_set_scissor(0, 0, 1280, 960);
	}

	// --- Active Explosions (editor) ---
	if (array_length(active_explosions) > 0) {
		gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
		draw_active_explosions(scene_win_x, scene_win_y, 1.0, 1.0);
		gpu_set_scissor(0, 0, 1280, 960);
	}

	// --- Flying decap heads (editor) ---
	if (array_length(active_decap_heads) > 0) {
		var _dasc = (scene_win_h * 1.5) / 450;
		gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
		for (var _dhi = 0; _dhi < array_length(active_decap_heads); _dhi++) {
			var _dh = active_decap_heads[_dhi];
			// Only draw if inside scene bounds
			if (_dh.x < scene_win_x - 50 || _dh.x > scene_win_x + scene_win_w + 50) continue;
			if (_dh.y > scene_win_y + scene_win_h + 50) continue;
			var _dlys = get_composite_character_sprite(_dh.char_index, _dh.pose, _dh.expression, _dh.facing);
			var _dbwpx = (_dlys[0].spr != -1) ? sprite_get_width(_dlys[0].spr) : 80;
			var _dbhpx = (_dlys[0].spr != -1) ? sprite_get_height(_dlys[0].spr) : 200;
			// Neck pivot in body-space (sprite pixels)
			var _neck_bx = _dbwpx * 0.5;
			var _neck_by = _dbhpx * 0.75;
			// Common pivot: centre of face sprite, so all layers spin as a rigid unit
			var _face_lyr = _dlys[1];
			var _piv_x = _dh.x + ((_face_lyr.spr != -1 ? _face_lyr.dx + sprite_get_width(_face_lyr.spr) * 0.5 : _neck_bx) - _neck_bx) * _dasc;
			var _piv_y = _dh.y + ((_face_lyr.spr != -1 ? _face_lyr.dy + sprite_get_height(_face_lyr.spr) * 0.5 : _neck_by) - _neck_by) * _dasc;
			var _hcos = dcos(_dh.angle); var _hsin = dsin(_dh.angle);
			draw_set_alpha(_dh.alpha);
			for (var _hli = 1; _hli < 4; _hli++) { // face, mouth, eyes
				var _hl = _dlys[_hli];
				if (_hl.spr == -1) continue;
				var _ulx = _dh.x + (_hl.dx - _neck_bx) * _dasc;
				var _uly = _dh.y + (_hl.dy - _neck_by) * _dasc;
				var _ox = _ulx - _piv_x; var _oy = _uly - _piv_y;
				var _sx_h = _piv_x + _ox * _hcos + _oy * _hsin;
				var _sy_h = _piv_y - _ox * _hsin + _oy * _hcos;
				draw_sprite_ext(_hl.spr, 0, _sx_h, _sy_h, _dasc, _dasc, _dh.angle, c_white, _dh.alpha);
			}
			draw_set_alpha(1.0);
		}
		gpu_set_scissor(0, 0, 1280, 960);
	}

	// --- Active shots (editor) ---
	if (array_length(active_shots) > 0) {
		gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
		gpu_set_blendmode(bm_add);
		for (var _stei = 0; _stei < array_length(active_shots); _stei++) {
			var _ste = active_shots[_stei];
			var _stex = scene_win_x + _ste.x; var _stey = scene_win_y + _ste.y;
			var _steco = cos(degtorad(_ste.angle)); var _stesi = sin(degtorad(_ste.angle));
			var _stewh = _ste.w * 0.5; var _stehh = _ste.h * 0.5;
			var _stex1 = _stex - _steco * _stewh; var _stey1 = _stey - _stesi * _stewh;
			var _stex2 = _stex + _steco * _stewh; var _stey2 = _stey + _stesi * _stewh;
			draw_set_color(make_color_rgb(_ste.r, _ste.g, _ste.b));
			draw_set_alpha(_ste.alpha * 0.12); draw_line_width(_stex1, _stey1, _stex2, _stey2, max(2, _stehh * 2 * 5));
			draw_set_alpha(_ste.alpha * 0.35); draw_line_width(_stex1, _stey1, _stex2, _stey2, max(1.5, _stehh * 2 * 2.5));
			draw_set_alpha(_ste.alpha * 0.80); draw_line_width(_stex1, _stey1, _stex2, _stey2, max(1, _stehh * 2));
			draw_set_color(make_color_rgb(min(255, _ste.r + 110), min(255, _ste.g + 110), min(255, _ste.b + 110)));
			draw_set_alpha(_ste.alpha); draw_line_width(_stex1, _stey1, _stex2, _stey2, max(0.5, _stehh * 0.7));
		}
		gpu_set_blendmode(bm_normal);
		draw_set_alpha(1.0);
		gpu_set_scissor(0, 0, 1280, 960);
	}

	// Draw foreground mask AFTER beams and particles so they appear behind the foreground layer
	if (_mask_sprite != -1) {
		gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
		var _fg_scale_x = scene_win_w / sprite_get_width(_mask_sprite);
		var _fg_scale_y = scene_win_h / sprite_get_height(_mask_sprite);
		draw_sprite_ext(_mask_sprite, 0, scene_win_x + quake_x, scene_win_y + quake_y, _fg_scale_x, _fg_scale_y, 0, c_white, 1);
		gpu_set_scissor(0, 0, 1280, 960);
	}

	// --- Selection outline: hollow yellow ring drawn on top of foreground ---
	// Drawn before FX capture so distortion shaders (e.g. CRT) warp it in sync with characters.
	if (playing_block_index == -1 && !particle_edit_mode) {
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
			var _ooffs = [[-_ow,0],[_ow,0],[0,-_ow],[0,-_ow],[-_ow,-_ow],[_ow,-_ow],[-_ow,_ow],[_ow,_ow]];
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

			// Draw the hollow ring on top of the scene
			gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
			draw_surface(o_mask_surface, scene_win_x, scene_win_y);
			break;
		}
	}

	// --- FX OVERLAY (editor preview) ---
	var _edit_fx = variable_struct_exists(_scene, "fx") ? _scene.fx : "none";
	if (_edit_fx != "none") {
		gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
		var _is_capture_fx = (_edit_fx == "blackwhite" || _edit_fx == "brighten" || _edit_fx == "candlelight" || _edit_fx == "crt" || _edit_fx == "darken" || _edit_fx == "dream" || _edit_fx == "drunk" || _edit_fx == "filth" || _edit_fx == "frigid" || _edit_fx == "goldenhour" || _edit_fx == "heat" || _edit_fx == "infrared" || _edit_fx == "moonlight" || _edit_fx == "nightvision" || _edit_fx == "sepia" || _edit_fx == "stoned" || _edit_fx == "sunlight" || _edit_fx == "underwater");
		var _cap_sh_for_fx = shHeat;
		if      (_edit_fx == "blackwhite")  _cap_sh_for_fx = shBlackWhite;
		else if (_edit_fx == "brighten")    _cap_sh_for_fx = shBrighten;
		else if (_edit_fx == "candlelight") _cap_sh_for_fx = shCandlelight;
		else if (_edit_fx == "crt")         _cap_sh_for_fx = shCRT;
		else if (_edit_fx == "darken")      _cap_sh_for_fx = shDarken;
		else if (_edit_fx == "dream")       _cap_sh_for_fx = shDream;
		else if (_edit_fx == "drunk")       _cap_sh_for_fx = shDrunk;
		else if (_edit_fx == "filth")       _cap_sh_for_fx = shFilth;
		else if (_edit_fx == "frigid")      _cap_sh_for_fx = shFrigid;
		else if (_edit_fx == "moonlight")   _cap_sh_for_fx = shMoonlight;
		else if (_edit_fx == "sunlight")    _cap_sh_for_fx = shSunlight;
		else if (_edit_fx == "goldenhour")  _cap_sh_for_fx = shGoldenHour;
		else if (_edit_fx == "infrared")    _cap_sh_for_fx = shInfrared;
		else if (_edit_fx == "nightvision") _cap_sh_for_fx = shNightVision;
		else if (_edit_fx == "sepia")       _cap_sh_for_fx = shSepia;
		else if (_edit_fx == "stoned")      _cap_sh_for_fx = shStoned;
		else if (_edit_fx == "underwater")  _cap_sh_for_fx = shUnderwater;
		if (_is_capture_fx && shader_is_compiled(_cap_sh_for_fx)) {
			var _cap_sh = _cap_sh_for_fx;
			var _ehsw = ceil(scene_win_w); var _ehsh = ceil(scene_win_h);
			if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _ehsw || surface_get_height(heat_surface) != _ehsh) {
				if (surface_exists(heat_surface)) surface_free(heat_surface);
				heat_surface = surface_create(_ehsw, _ehsh);
			}
			surface_copy_part(heat_surface, 0, 0, application_surface, round(scene_win_x), round(scene_win_y), _ehsw, _ehsh);
			shader_set(_cap_sh);
			shader_set_uniform_f(shader_get_uniform(_cap_sh, "u_time"), current_time * 0.001);
			draw_set_color(c_white); draw_set_alpha(1.0);
			draw_surface_stretched(heat_surface, scene_win_x, scene_win_y, scene_win_w, scene_win_h);
			shader_reset();
		} else {
			var _efx_sh = shFog;
			if (_edit_fx == "rain")   _efx_sh = shRain;
			else if (_edit_fx == "snow")   _efx_sh = shSnow;
			else if (_edit_fx == "embers") _efx_sh = shEmbers;
			else if (_edit_fx == "static") _efx_sh = shStatic;
			if (shader_is_compiled(_efx_sh)) {
				shader_set(_efx_sh);
				shader_set_uniform_f(shader_get_uniform(_efx_sh, "u_time"), current_time * 0.001);
				shader_set_uniform_f(shader_get_uniform(_efx_sh, "u_rect"), scene_win_x, scene_win_y, scene_win_w, scene_win_h);
				gpu_set_blendmode(_edit_fx == "embers" ? bm_add : bm_normal);
				draw_set_color(c_white); draw_set_alpha(1.0);
				draw_rectangle(scene_win_x, scene_win_y, scene_win_x + scene_win_w, scene_win_y + scene_win_h, false);
				shader_reset();
				gpu_set_blendmode(bm_normal);
			}
		}
	}
}


gpu_set_scissor(0, 0, 1280, 960);

// --- PARTICLE EDIT MODE OVERLAY ---
if (particle_edit_mode && particle_edit_block_idx != -1 && particle_edit_block_idx < array_length(script_blocks)
        && variable_struct_exists(script_blocks[particle_edit_block_idx], "type")
        && script_blocks[particle_edit_block_idx].type == "particle") {
    var _pb = script_blocks[particle_edit_block_idx];

    // Crimson border around scene window (like staging mode's orange border)
    draw_set_color(make_color_rgb(200, 30, 30)); draw_set_alpha(1.0);
    draw_rectangle(scene_win_x - 3, scene_win_y - 3, scene_win_x + scene_win_w + 3, scene_win_y + scene_win_h + 3, true);
    draw_rectangle(scene_win_x - 2, scene_win_y - 2, scene_win_x + scene_win_w + 2, scene_win_y + scene_win_h + 2, true);

    var _dot_sx = scene_win_x + _pb.x;
    var _dot_sy = scene_win_y + _pb.y;
    var _ang_r  = degtorad(_pb.angle);
    var _arr_len = 65;
    var _tip_sx = _dot_sx + cos(_ang_r) * _arr_len;
    var _tip_sy = _dot_sy + sin(_ang_r) * _arr_len;

    gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
    // Direction arrow
    draw_set_color(c_yellow);
    draw_line_width(_dot_sx, _dot_sy, _tip_sx, _tip_sy, 2);
    // Arrow tip handle
    var _tip_hov = (point_distance(_mx, _my, _tip_sx, _tip_sy) < 12);
    draw_set_color(particle_drag_dir || _tip_hov ? make_color_rgb(255, 240, 60) : c_yellow);
    draw_circle(_tip_sx, _tip_sy, 7, false);
    draw_set_color(c_black); draw_circle(_tip_sx, _tip_sy, 7, true);
    // Position dot
    var _dot_hov = (point_distance(_mx, _my, _dot_sx, _dot_sy) < 14);
    draw_set_color(particle_drag_pos || _dot_hov ? make_color_rgb(255, 100, 100) : make_color_rgb(200, 30, 30));
    draw_circle(_dot_sx, _dot_sy, 9, false);
    draw_set_color(c_white); draw_circle(_dot_sx, _dot_sy, 9, true);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_dot_sx, _dot_sy - 5, "+"); draw_set_halign(fa_left);

    // Area ellipse (not shown for laser or explosion — not applicable to those effects)
    var _paw = (_pb.effect != "laser" && _pb.effect != "explosion" && variable_struct_exists(_pb, "area_w")) ? _pb.area_w : 0;
    var _pah = (_pb.effect != "laser" && _pb.effect != "explosion" && variable_struct_exists(_pb, "area_h")) ? _pb.area_h : 0;
    if (_paw > 0 || _pah > 0) {
        draw_set_color(make_color_rgb(200, 60, 60)); draw_set_alpha(0.15);
        draw_ellipse(_dot_sx - _paw/2, _dot_sy - _pah/2, _dot_sx + _paw/2, _dot_sy + _pah/2, false);
        draw_set_alpha(0.65);
        draw_ellipse(_dot_sx - _paw/2, _dot_sy - _pah/2, _dot_sx + _paw/2, _dot_sy + _pah/2, true);
        draw_set_alpha(1.0);
    }
    // Width handle (orange, right)
    var _aw_hx = _dot_sx + max(18, _paw/2); var _aw_hy = _dot_sy;
    var _aw_hov = (point_distance(_mx, _my, _aw_hx, _aw_hy) < 10);
    draw_set_color(particle_drag_area_w || _aw_hov ? make_color_rgb(255,165,40) : make_color_rgb(200,115,18));
    draw_circle(_aw_hx, _aw_hy, 6, false);
    draw_set_color(c_black); draw_circle(_aw_hx, _aw_hy, 6, true);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_aw_hx, _aw_hy - 5, "W"); draw_set_halign(fa_left);
    // Height handle (cyan, above)
    var _ah_hx = _dot_sx; var _ah_hy = _dot_sy - max(18, _pah/2);
    var _ah_hov = (point_distance(_mx, _my, _ah_hx, _ah_hy) < 10);
    draw_set_color(particle_drag_area_h || _ah_hov ? make_color_rgb(50,235,235) : make_color_rgb(18,175,175));
    draw_circle(_ah_hx, _ah_hy, 6, false);
    draw_set_color(c_black); draw_circle(_ah_hx, _ah_hy, 6, true);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_ah_hx, _ah_hy - 5, "H"); draw_set_halign(fa_left);
    // Dimension labels + RESET button when area is set
    if (_paw > 0 || _pah > 0) {
        draw_set_color(c_white); draw_set_alpha(0.85);
        draw_text(_aw_hx + 9, _aw_hy - 7, "W: " + string(round(_paw)));
        draw_text(_ah_hx + 9, _ah_hy - 7, "H: " + string(round(_pah)));
        draw_set_alpha(1.0);
        var _rst_x = _dot_sx - 20; var _rst_y = _dot_sy + 14;
        var _rst_hov = (_mx > _rst_x && _mx < _rst_x+40 && _my > _rst_y && _my < _rst_y+18);
        draw_set_color(_rst_hov ? make_color_rgb(225,75,75) : make_color_rgb(140,38,38));
        draw_roundrect_ext(_rst_x, _rst_y, _rst_x+40, _rst_y+18, 3, 3, false);
        draw_set_color(c_white); draw_set_halign(fa_center);
        draw_text(_rst_x+20, _rst_y+3, "RESET");
        draw_set_halign(fa_left);
    }
    gpu_set_scissor(0, 0, 1280, 960);

    // "PARTICLE EDIT" label — clamped right so it never overlaps the FILE button (~x=90)
    var _pe_lx = max(scene_win_x, 98);
    draw_set_color(make_color_rgb(180, 28, 28));
    draw_roundrect_ext(_pe_lx, scene_win_y - 44, _pe_lx + 140, scene_win_y - 10, 5, 5, false);
    draw_set_color(make_color_rgb(255, 90, 90));
    draw_roundrect_ext(_pe_lx, scene_win_y - 44, _pe_lx + 140, scene_win_y - 10, 5, 5, true);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_pe_lx + 70, scene_win_y - 36, "PARTICLE EDIT");
    draw_set_halign(fa_left);

    // Panel side: flip to right when emitter is in the left 35% of the scene
    var _on_right = (_pb.x < scene_win_w * 0.35);
    var _pbase_x  = _on_right ? (scene_win_x + scene_win_w - 210) : (scene_win_x + 5);

    // DONE button
    var _ped_x = _on_right ? (scene_win_x + 10) : (scene_win_x + scene_win_w - 90);
    var _ped_y = scene_win_y + 8;
    var _ped_hov = (_mx > _ped_x && _mx < _ped_x + 80 && _my > _ped_y && _my < _ped_y + 26);
    draw_set_color(_ped_hov ? make_color_rgb(50, 190, 50) : make_color_rgb(28, 135, 28));
    draw_roundrect_ext(_ped_x, _ped_y, _ped_x + 80, _ped_y + 26, 4, 4, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_ped_x + 40, _ped_y + 6, "DONE"); draw_set_halign(fa_left);
    // PREVIEW button
    var _pep_x = _on_right ? (scene_win_x + 100) : (scene_win_x + scene_win_w - 185);
    var _pep_y = scene_win_y + 8;
    var _pep_hov = (_mx > _pep_x && _mx < _pep_x + 86 && _my > _pep_y && _my < _pep_y + 26);
    draw_set_color(_pep_hov ? make_color_rgb(80, 130, 220) : make_color_rgb(48, 82, 165));
    draw_roundrect_ext(_pep_x, _pep_y, _pep_x + 86, _pep_y + 26, 4, 4, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_pep_x + 43, _pep_y + 6, "PREVIEW"); draw_set_halign(fa_left);

    // Particle controls (5-row layout: Size, Duration, Density, Speed, Spread)
    var _is_laser = (_pb.effect == "laser"); var _is_shot = (_pb.effect == "shot");
    var _psz  = variable_struct_exists(_pb, "size")     ? _pb.size     : 1.0;
    var _pdur = variable_struct_exists(_pb, "duration") ? _pb.duration : 1.0;
    var _pden = variable_struct_exists(_pb, "density")  ? _pb.density  : 2;
    var _pspd = variable_struct_exists(_pb, "speed")    ? _pb.speed    : 1.0;
    var _pspr = variable_struct_exists(_pb, "spread")   ? _pb.spread   : 65;
    var _pctrl_y = scene_win_y + 10; var _pbsz = 24;
    var _is_custom_color = (variable_struct_exists(_pb, "color") && _pb.color == "custom");
    var _panel_h = _is_custom_color ? 372 : 284;
    draw_set_color(make_color_rgb(28, 28, 40));
    draw_rectangle(_pbase_x, _pctrl_y, _pbase_x + 200, _pctrl_y + _panel_h, false);
    draw_set_color(make_color_rgb(90, 30, 30));
    draw_rectangle(_pbase_x, _pctrl_y, _pbase_x + 200, _pctrl_y + _panel_h, true);

    var _ctrl_lx = _pbase_x + 70; var _ctrl_rx = _pbase_x + 143; var _ctrl_vc = _pbase_x + 119;

    // SIZE row
    var _r1y = _pctrl_y + 4;
    if (!_is_shot) {
        var _sm_hov = (_mx >= _ctrl_lx && _mx <= _ctrl_lx+_pbsz && _my >= _r1y && _my <= _r1y+_pbsz);
        var _sp_hov = (_mx >= _ctrl_rx && _mx <= _ctrl_rx+_pbsz && _my >= _r1y && _my <= _r1y+_pbsz);
        draw_set_color(make_color_rgb(200, 200, 200)); draw_text(_pbase_x + 7, _r1y + 5, "SIZE");
        draw_set_color(_sm_hov ? c_white : make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_lx, _r1y, _ctrl_lx+_pbsz, _r1y+_pbsz, 3,3, false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_lx+12, _r1y+5, "-"); draw_set_halign(fa_left);
        draw_set_color(_sp_hov ? c_white : make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_rx, _r1y, _ctrl_rx+_pbsz, _r1y+_pbsz, 3,3, false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_rx+12, _r1y+5, "+"); draw_set_halign(fa_left);
        draw_set_color(c_yellow); draw_set_halign(fa_center); draw_text_transformed(_ctrl_vc, _r1y+5, string(_psz), 1.1, 1.1, 0); draw_set_halign(fa_left);
    } else {
        draw_set_alpha(0.28); draw_set_color(make_color_rgb(120,120,120));
        draw_text(_pbase_x + 7, _r1y + 5, "SIZE"); draw_set_halign(fa_center);
        draw_text(_ctrl_vc, _r1y + 5, "—"); draw_set_halign(fa_left); draw_set_alpha(1.0);
    }

    // DUR row
    var _r2y = _pctrl_y + 32;
    if (!_is_shot) {
        var _dm_hov = (_mx >= _ctrl_lx && _mx <= _ctrl_lx+_pbsz && _my >= _r2y && _my <= _r2y+_pbsz);
        var _dp_hov = (_mx >= _ctrl_rx && _mx <= _ctrl_rx+_pbsz && _my >= _r2y && _my <= _r2y+_pbsz);
        draw_set_color(make_color_rgb(200, 200, 200)); draw_text(_pbase_x + 7, _r2y + 5, "DUR (s)");
        draw_set_color(_dm_hov ? c_white : make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_lx, _r2y, _ctrl_lx+_pbsz, _r2y+_pbsz, 3,3, false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_lx+12, _r2y+5, "-"); draw_set_halign(fa_left);
        draw_set_color(_dp_hov ? c_white : make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_rx, _r2y, _ctrl_rx+_pbsz, _r2y+_pbsz, 3,3, false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_rx+12, _r2y+5, "+"); draw_set_halign(fa_left);
        draw_set_color(c_yellow); draw_set_halign(fa_center); draw_text_transformed(_ctrl_vc, _r2y+5, string(_pdur) + "s", 1.1, 1.1, 0); draw_set_halign(fa_left);
    } else {
        draw_set_alpha(0.28); draw_set_color(make_color_rgb(120,120,120));
        draw_text(_pbase_x + 7, _r2y + 5, "DUR (s)"); draw_set_halign(fa_center);
        draw_text(_ctrl_vc, _r2y + 5, "AUTO"); draw_set_halign(fa_left); draw_set_alpha(1.0);
    }

    // DENSITY row
    var _r3y = _pctrl_y + 60;
    if (!_is_laser && !_is_shot) {
        var _dem_hov = (_mx >= _ctrl_lx && _mx <= _ctrl_lx+_pbsz && _my >= _r3y && _my <= _r3y+_pbsz);
        var _dep_hov = (_mx >= _ctrl_rx && _mx <= _ctrl_rx+_pbsz && _my >= _r3y && _my <= _r3y+_pbsz);
        draw_set_color(make_color_rgb(200, 200, 200)); draw_text(_pbase_x + 7, _r3y + 5, "DENSITY");
        draw_set_color(_dem_hov ? c_white : make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_lx, _r3y, _ctrl_lx+_pbsz, _r3y+_pbsz, 3,3, false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_lx+12, _r3y+5, "-"); draw_set_halign(fa_left);
        draw_set_color(_dep_hov ? c_white : make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_rx, _r3y, _ctrl_rx+_pbsz, _r3y+_pbsz, 3,3, false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_rx+12, _r3y+5, "+"); draw_set_halign(fa_left);
        draw_set_color(c_yellow); draw_set_halign(fa_center); draw_text_transformed(_ctrl_vc, _r3y+5, string(_pden), 1.1, 1.1, 0); draw_set_halign(fa_left);
    } else {
        draw_set_alpha(0.28); draw_set_color(make_color_rgb(120,120,120));
        draw_text(_pbase_x + 7, _r3y + 5, "DENSITY"); draw_set_halign(fa_center);
        draw_text(_ctrl_vc, _r3y + 5, "—"); draw_set_halign(fa_left); draw_set_alpha(1.0);
    }

    // SPEED row
    var _r4y = _pctrl_y + 88;
    if (!_is_laser) {
        var _spm_hov = (_mx >= _ctrl_lx && _mx <= _ctrl_lx+_pbsz && _my >= _r4y && _my <= _r4y+_pbsz);
        var _spp_hov = (_mx >= _ctrl_rx && _mx <= _ctrl_rx+_pbsz && _my >= _r4y && _my <= _r4y+_pbsz);
        draw_set_color(make_color_rgb(200, 200, 200)); draw_text(_pbase_x + 7, _r4y + 5, "SPEED");
        draw_set_color(_spm_hov ? c_white : make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_lx, _r4y, _ctrl_lx+_pbsz, _r4y+_pbsz, 3,3, false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_lx+12, _r4y+5, "-"); draw_set_halign(fa_left);
        draw_set_color(_spp_hov ? c_white : make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_rx, _r4y, _ctrl_rx+_pbsz, _r4y+_pbsz, 3,3, false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_rx+12, _r4y+5, "+"); draw_set_halign(fa_left);
        draw_set_color(c_yellow); draw_set_halign(fa_center); draw_text_transformed(_ctrl_vc, _r4y+5, (_is_shot ? string(round(_pspd / 4)) : string(_pspd)) + "x", 1.1, 1.1, 0); draw_set_halign(fa_left);
    } else {
        draw_set_alpha(0.28); draw_set_color(make_color_rgb(120,120,120));
        draw_text(_pbase_x + 7, _r4y + 5, "SPEED"); draw_set_halign(fa_center);
        draw_text(_ctrl_vc, _r4y + 5, "—"); draw_set_halign(fa_left); draw_set_alpha(1.0);
    }

    // SPREAD row
    var _r5y = _pctrl_y + 116;
    if (!_is_laser && !_is_shot) {
        var _sprm_hov = (_mx >= _ctrl_lx && _mx <= _ctrl_lx+_pbsz && _my >= _r5y && _my <= _r5y+_pbsz);
        var _sprp_hov = (_mx >= _ctrl_rx && _mx <= _ctrl_rx+_pbsz && _my >= _r5y && _my <= _r5y+_pbsz);
        draw_set_color(make_color_rgb(200, 200, 200)); draw_text(_pbase_x + 7, _r5y + 5, "SPREAD");
        draw_set_color(_sprm_hov ? c_white : make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_lx, _r5y, _ctrl_lx+_pbsz, _r5y+_pbsz, 3,3, false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_lx+12, _r5y+5, "-"); draw_set_halign(fa_left);
        draw_set_color(_sprp_hov ? c_white : make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_rx, _r5y, _ctrl_rx+_pbsz, _r5y+_pbsz, 3,3, false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_rx+12, _r5y+5, "+"); draw_set_halign(fa_left);
        draw_set_color(c_yellow); draw_set_halign(fa_center); draw_text_transformed(_ctrl_vc, _r5y+5, string(_pspr) + chr(176), 1.1, 1.1, 0); draw_set_halign(fa_left);
    } else {
        draw_set_alpha(0.28); draw_set_color(make_color_rgb(120,120,120));
        draw_text(_pbase_x + 7, _r5y + 5, "SPREAD"); draw_set_halign(fa_center);
        draw_text(_ctrl_vc, _r5y + 5, "—"); draw_set_halign(fa_left); draw_set_alpha(1.0);
    }

    // COLOR section — 3 rows of 4 presets (24px, 4px gap) + [CUSTOM RGB] button + conditional sliders
    var _r6y = _pctrl_y + 148;
    var _cur_pcolor = variable_struct_exists(_pb, "color") ? _pb.color : "red";
    draw_set_color(make_color_rgb(200, 200, 200)); draw_text(_pbase_x + 7, _r6y + 2, "COLOR");
    var _pcolors  = ["red",        "darkred",   "crimson",   "maroon",
                     "orange",     "yellow",    "brown",     "darkbrown",
                     "glass",      "white",     "electric",  "black"];
    var _pcol_rgb = [[220,20,20],  [140,10,10], [180,0,40],  [100,5,5],
                     [190,60,10],  [210,195,15],[120,64,32], [60,30,10],
                     [195,225,245],[240,235,225],[200,220,60],[30,20,20]];
    var _csxo = _pbase_x + 46;
    for (var _ci = 0; _ci < array_length(_pcolors); _ci++) {
        var _csx = _csxo + (_ci mod 4) * 28;
        var _csy = _r6y + 22 + floor(_ci / 4) * 28;
        var _crgb = _pcol_rgb[_ci];
        draw_set_color(make_color_rgb(_crgb[0], _crgb[1], _crgb[2]));
        draw_rectangle(_csx, _csy, _csx + 24, _csy + 24, false);
        if (_cur_pcolor == _pcolors[_ci]) {
            draw_set_color(c_white); draw_rectangle(_csx - 1, _csy - 1, _csx + 25, _csy + 25, true);
        }
    }
    // [CUSTOM RGB] button
    var _cust_x = _csxo; var _cust_y = _r6y + 110;
    var _cust_sel = (_cur_pcolor == "custom");
    draw_set_color(_cust_sel ? make_color_rgb(80,80,110) : make_color_rgb(38,38,55));
    draw_rectangle(_cust_x, _cust_y, _cust_x + 108, _cust_y + 22, false);
    draw_set_color(_cust_sel ? c_white : make_color_rgb(110,110,145));
    draw_rectangle(_cust_x, _cust_y, _cust_x + 108, _cust_y + 22, true);
    if (_cust_sel) {
        // preview swatch of current custom color
        var _pcrv = variable_struct_exists(_pb, "color_r") ? _pb.color_r : 200;
        var _pcgv = variable_struct_exists(_pb, "color_g") ? _pb.color_g : 0;
        var _pcbv = variable_struct_exists(_pb, "color_b") ? _pb.color_b : 0;
        draw_set_color(make_color_rgb(_pcrv, _pcgv, _pcbv));
        draw_rectangle(_cust_x + 84, _cust_y + 3, _cust_x + 106, _cust_y + 19, false);
    }
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_cust_x + 54, _cust_y + 5, "CUSTOM RGB");
    draw_set_halign(fa_left);
    // RGB sliders (only when custom selected)
    if (_cust_sel) {
        var _pcr = variable_struct_exists(_pb, "color_r") ? _pb.color_r : 200;
        var _pcg = variable_struct_exists(_pb, "color_g") ? _pb.color_g : 0;
        var _pcb = variable_struct_exists(_pb, "color_b") ? _pb.color_b : 0;
        var _r7y = _r6y + 140; var _r8y = _r6y + 168; var _r9y = _r6y + 196;
        // R
        var _rm_hov = (_mx>=_ctrl_lx&&_mx<=_ctrl_lx+_pbsz&&_my>=_r7y&&_my<=_r7y+_pbsz);
        var _rp_hov = (_mx>=_ctrl_rx&&_mx<=_ctrl_rx+_pbsz&&_my>=_r7y&&_my<=_r7y+_pbsz);
        draw_set_color(make_color_rgb(210,70,70)); draw_text(_pbase_x + 7, _r7y + 5, "R");
        draw_set_color(_rm_hov?c_white:make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_lx,_r7y,_ctrl_lx+_pbsz,_r7y+_pbsz,3,3,false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_lx+12,_r7y+5,"-"); draw_set_halign(fa_left);
        draw_set_color(_rp_hov?c_white:make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_rx,_r7y,_ctrl_rx+_pbsz,_r7y+_pbsz,3,3,false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_rx+12,_r7y+5,"+"); draw_set_halign(fa_left);
        var _rgb_cursor = (check_timer mod 30 < 15);
        // R value — editable
        if (rgb_edit_channel == 0) {
            draw_set_color(make_color_rgb(60,20,20)); draw_rectangle(_ctrl_lx+_pbsz, _r7y, _ctrl_rx, _r7y+_pbsz, false);
            draw_set_color(make_color_rgb(255,160,160)); draw_set_halign(fa_center);
            draw_text_transformed(_ctrl_vc, _r7y+5, rgb_edit_str + (_rgb_cursor ? "|" : ""), 1.1, 1.1, 0);
        } else {
            draw_set_color(make_color_rgb(220,100,100)); draw_set_halign(fa_center);
            draw_text_transformed(_ctrl_vc, _r7y+5, string(_pcr), 1.1, 1.1, 0);
        }
        draw_set_halign(fa_left);
        // G
        var _gm_hov = (_mx>=_ctrl_lx&&_mx<=_ctrl_lx+_pbsz&&_my>=_r8y&&_my<=_r8y+_pbsz);
        var _gp_hov = (_mx>=_ctrl_rx&&_mx<=_ctrl_rx+_pbsz&&_my>=_r8y&&_my<=_r8y+_pbsz);
        draw_set_color(make_color_rgb(70,210,70)); draw_text(_pbase_x + 7, _r8y + 5, "G");
        draw_set_color(_gm_hov?c_white:make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_lx,_r8y,_ctrl_lx+_pbsz,_r8y+_pbsz,3,3,false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_lx+12,_r8y+5,"-"); draw_set_halign(fa_left);
        draw_set_color(_gp_hov?c_white:make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_rx,_r8y,_ctrl_rx+_pbsz,_r8y+_pbsz,3,3,false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_rx+12,_r8y+5,"+"); draw_set_halign(fa_left);
        // G value — editable
        if (rgb_edit_channel == 1) {
            draw_set_color(make_color_rgb(20,60,20)); draw_rectangle(_ctrl_lx+_pbsz, _r8y, _ctrl_rx, _r8y+_pbsz, false);
            draw_set_color(make_color_rgb(160,255,160)); draw_set_halign(fa_center);
            draw_text_transformed(_ctrl_vc, _r8y+5, rgb_edit_str + (_rgb_cursor ? "|" : ""), 1.1, 1.1, 0);
        } else {
            draw_set_color(make_color_rgb(100,220,100)); draw_set_halign(fa_center);
            draw_text_transformed(_ctrl_vc, _r8y+5, string(_pcg), 1.1, 1.1, 0);
        }
        draw_set_halign(fa_left);
        // B
        var _bm_hov = (_mx>=_ctrl_lx&&_mx<=_ctrl_lx+_pbsz&&_my>=_r9y&&_my<=_r9y+_pbsz);
        var _bp_hov = (_mx>=_ctrl_rx&&_mx<=_ctrl_rx+_pbsz&&_my>=_r9y&&_my<=_r9y+_pbsz);
        draw_set_color(make_color_rgb(70,70,210)); draw_text(_pbase_x + 7, _r9y + 5, "B");
        draw_set_color(_bm_hov?c_white:make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_lx,_r9y,_ctrl_lx+_pbsz,_r9y+_pbsz,3,3,false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_lx+12,_r9y+5,"-"); draw_set_halign(fa_left);
        draw_set_color(_bp_hov?c_white:make_color_rgb(120,120,140)); draw_roundrect_ext(_ctrl_rx,_r9y,_ctrl_rx+_pbsz,_r9y+_pbsz,3,3,false);
        draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ctrl_rx+12,_r9y+5,"+"); draw_set_halign(fa_left);
        // B value — editable
        if (rgb_edit_channel == 2) {
            draw_set_color(make_color_rgb(20,20,60)); draw_rectangle(_ctrl_lx+_pbsz, _r9y, _ctrl_rx, _r9y+_pbsz, false);
            draw_set_color(make_color_rgb(160,160,255)); draw_set_halign(fa_center);
            draw_text_transformed(_ctrl_vc, _r9y+5, rgb_edit_str + (_rgb_cursor ? "|" : ""), 1.1, 1.1, 0);
        } else {
            draw_set_color(make_color_rgb(100,100,220)); draw_set_halign(fa_center);
            draw_text_transformed(_ctrl_vc, _r9y+5, string(_pcb), 1.1, 1.1, 0);
        }
        draw_set_halign(fa_left);
    }
}

// --- 1. GLOBAL BUTTONS (Drawn on top of Scene Window to prevent any overlap) ---
var _dis = (playing_block_index != -1);

var _add_hov = (!_overlay_active && !_dis && _mx > btn_add_x && _mx < btn_add_x+btn_add_w && _my > btn_add_y && _my < btn_add_y+btn_add_h);
draw_set_color(_dis ? make_color_rgb(30,50,32) : (_add_hov ? make_color_rgb(22,105,32) : make_color_rgb(14,75,22)));
draw_roundrect_ext(btn_add_x, btn_add_y, btn_add_x+btn_add_w, btn_add_y+btn_add_h, 5, 5, false);
draw_set_color(_dis ? make_color_rgb(55,75,57) : (_add_hov ? c_white : make_color_rgb(196,213,20)));
draw_roundrect_ext(btn_add_x, btn_add_y, btn_add_x+btn_add_w, btn_add_y+btn_add_h, 5, 5, true);
draw_set_color(c_white); draw_set_halign(fa_center); draw_text(btn_add_x+btn_add_w/2, btn_add_y+10, "+ VOICE"); draw_set_halign(fa_left);

var _act_hov = (!_overlay_active && !_dis && _mx > btn_add_action_x && _mx < btn_add_action_x+btn_add_action_w && _my > btn_add_action_y && _my < btn_add_action_y+btn_add_action_h);
draw_set_color(_dis ? make_color_rgb(30,40,62) : (_act_hov ? make_color_rgb(28,80,195) : make_color_rgb(18,55,158)));
draw_roundrect_ext(btn_add_action_x, btn_add_action_y, btn_add_action_x+btn_add_action_w, btn_add_action_y+btn_add_action_h, 5, 5, false);
draw_set_color(_dis ? make_color_rgb(55,65,95) : (_act_hov ? c_white : make_color_rgb(100,145,235)));
draw_roundrect_ext(btn_add_action_x, btn_add_action_y, btn_add_action_x+btn_add_action_w, btn_add_action_y+btn_add_action_h, 5, 5, true);
draw_set_color(c_white); draw_set_halign(fa_center); draw_text(btn_add_action_x+btn_add_action_w/2, btn_add_action_y+10, "+ ACTION"); draw_set_halign(fa_left);

var _scn_hov = (!_overlay_active && !_dis && _mx > btn_add_scene_x && _mx < btn_add_scene_x+btn_add_scene_w && _my > btn_add_scene_y && _my < btn_add_scene_y+btn_add_scene_h);
draw_set_color(_dis ? make_color_rgb(28,45,30) : (_scn_hov ? make_color_rgb(8,88,18) : make_color_rgb(4,58,12)));
draw_roundrect_ext(btn_add_scene_x, btn_add_scene_y, btn_add_scene_x+btn_add_scene_w, btn_add_scene_y+btn_add_scene_h, 5, 5, false);
draw_set_color(_dis ? make_color_rgb(52,70,54) : (_scn_hov ? c_white : make_color_rgb(196,213,20)));
draw_roundrect_ext(btn_add_scene_x, btn_add_scene_y, btn_add_scene_x+btn_add_scene_w, btn_add_scene_y+btn_add_scene_h, 5, 5, true);
draw_set_color(c_white); draw_set_halign(fa_center); draw_text(btn_add_scene_x+btn_add_scene_w/2, btn_add_scene_y+10, "+ SCENE"); draw_set_halign(fa_left);

// --- 1.2 SCENE EDIT MODE INDICATORS (Drawn on top of Scene Window) ---
var _ind_x = max(scene_win_x, 110);
if (scene_edit_mode && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
    var _stg_hov = (!_overlay_active && _mx > _ind_x && _mx < _ind_x + 110 && _my > scene_win_y - 45 && _my < scene_win_y - 10);
    draw_set_color(_stg_hov ? make_color_rgb(255,170,30) : make_color_rgb(220,130,0));
    draw_roundrect_ext(_ind_x, scene_win_y - 45, _ind_x + 110, scene_win_y - 10, 5, 5, false);
    draw_set_color(_stg_hov ? c_white : make_color_rgb(255,200,80));
    draw_roundrect_ext(_ind_x, scene_win_y - 45, _ind_x + 110, scene_win_y - 10, 5, 5, true);
    draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_ind_x + 55, scene_win_y - 37, "STAGING"); draw_set_halign(fa_left);
    // FX dropdown button + picker
    var _sfx_scene = script_blocks[active_scene_block_idx];
    var _cur_fx = variable_struct_exists(_sfx_scene, "fx") ? _sfx_scene.fx : "none";
    // Keep sorted alphabetically by label (OFF always first). Add future effects in order.
    var _fx_ids    = ["none", "blackwhite", "brighten", "candlelight", "crt",   "darken", "dream",  "drunk", "embers", "filth",  "fog", "frigid",  "goldenhour",  "heat",      "infrared", "moonlight",  "nightvision",  "rain", "sepia", "snow", "static",    "stoned", "sunlight",   "underwater"];
    var _fx_labels = ["OFF",  "B&W FILM",  "BRIGHTEN", "CANDLELIGHT", "CRT",   "DARKEN", "DREAM",  "DRUNK", "EMBERS", "FILTH",  "FOG", "FRIGID",  "GOLDEN HOUR", "HEAT HAZE", "INFRARED", "MOONLIGHT",  "NIGHT VISION", "RAIN", "SEPIA", "SNOW", "TV STATIC", "STONED", "SUNLIGHT",   "UNDERWATER"];
    var _fx_btn_x = _ind_x + 120; var _fx_btn_w = 130;
    var _fx_hov = (!_overlay_active && !fx_picker_open && _mx > _fx_btn_x && _mx < _fx_btn_x + _fx_btn_w && _my > scene_win_y - 45 && _my < scene_win_y - 10);
    var _fx_on  = (_cur_fx != "none");
    var _cur_label = "OFF";
    for (var _fi = 0; _fi < array_length(_fx_ids); _fi++) { if (_fx_ids[_fi] == _cur_fx) { _cur_label = _fx_labels[_fi]; break; } }
    draw_set_color(fx_picker_open ? make_color_rgb(55,55,85) : (_fx_on ? make_color_rgb(22,110,105) : (_fx_hov ? make_color_rgb(42,42,68) : make_color_rgb(28,28,48))));
    draw_roundrect_ext(_fx_btn_x, scene_win_y - 45, _fx_btn_x + _fx_btn_w, scene_win_y - 10, 5, 5, false);
    draw_set_color(fx_picker_open ? make_color_rgb(110,110,160) : (_fx_on ? make_color_rgb(60,200,190) : (_fx_hov ? c_white : make_color_rgb(75,75,110))));
    draw_roundrect_ext(_fx_btn_x, scene_win_y - 45, _fx_btn_x + _fx_btn_w, scene_win_y - 10, 5, 5, true);
    draw_set_color(_fx_on ? make_color_rgb(120,240,230) : c_white);
    var _fx_lbl_str = "FX: " + _cur_label + " v";
    var _fx_lbl_sc = min(1.0, (_fx_btn_w - 16) / max(1, string_width(_fx_lbl_str)));
    draw_set_halign(fa_center);
    draw_text_transformed(_fx_btn_x + _fx_btn_w / 2, scene_win_y - 37, _fx_lbl_str, _fx_lbl_sc, 1.0, 0);
    draw_set_halign(fa_left);
    // Picker dropdown drawn at end of event so it renders above script blocks
}

if (focused_block != -1 && focused_block < array_length(script_blocks) - 1 && !scene_edit_mode && !particle_edit_mode) {
    draw_set_color(make_color_rgb(0, 150, 255));
    draw_rectangle(_ind_x, scene_win_y - 45, _ind_x + 150, scene_win_y - 10, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_ind_x + 75, scene_win_y - 37, "SPLICE MODE"); draw_set_halign(fa_left);
}

// --- 3d. FLIP FACING BUTTON ---
// Visible whenever the selected character is present in the current scene.
// In staging mode: flips their facing in the scene data.
// In script mode: inserts a "turns around" action block.
if (playing_block_index == -1 && current_scene_sprite != -1) {
    var _flip_on_scene = false;
    for (var _fci = 0; _fci < array_length(preview_actors); _fci++) {
        if (preview_actors[_fci].char_index == selected_character_index) { _flip_on_scene = true; break; }
    }
    if (_flip_on_scene) {
        var _fw = 128; var _fh = 24;
        var _fx = scene_win_x + (scene_win_w / 2) - (_fw / 2); var _fy = scene_win_y + scene_win_h + 5;
        var _fhov = (!_overlay_active && _mx > _fx && _mx < _fx + _fw && _my > _fy && _my < _fy + _fh);
        // Dark fill
        draw_set_color(make_color_rgb(22, 22, 38));
        draw_roundrect_ext(_fx, _fy, _fx + _fw, _fy + _fh, 5, 5, false);
        // Border / filled highlight
        draw_set_color(_fhov ? make_color_rgb(100, 100, 230) : make_color_rgb(70, 70, 160));
        draw_roundrect_ext(_fx, _fy, _fx + _fw, _fy + _fh, 5, 5, true);
        if (_fhov) { draw_set_alpha(0.18); draw_set_color(make_color_rgb(100, 100, 255)); draw_roundrect_ext(_fx+1, _fy+1, _fx+_fw-1, _fy+_fh-1, 4, 4, false); draw_set_alpha(1.0); }
        draw_set_color(_fhov ? c_white : make_color_rgb(160, 160, 255));
        draw_set_halign(fa_center);
        draw_text(_fx + (_fw / 2), _fy + 5, "TURN AROUND");
        draw_set_halign(fa_left);
    }
}

if (file_menu_open) {
    var _fm_x = 10; var _fm_y = 45; var _fm_w = 165; var _fm_h = 210;
    draw_set_color(make_color_rgb(10, 42, 15)); draw_rectangle(_fm_x, _fm_y, _fm_x + _fm_w, _fm_y + _fm_h, false);
    draw_set_color(make_color_rgb(196, 213, 20)); draw_rectangle(_fm_x, _fm_y, _fm_x + _fm_w, _fm_y + _fm_h, true);
    var _opts = ["NEW SCRIPT", "SAVE SCRIPT", "LOAD SCRIPT", "SAVE SCREENPLAY", "IMPORT ASSETS", "EXPORT SCRIPT"];
    for (var i = 0; i < 6; i++) {
        var _hov = (_mx > _fm_x && _mx < _fm_x + _fm_w && _my > _fm_y + (i * 35) && _my < _fm_y + ((i + 1) * 35));
        if (_hov) { draw_set_color(make_color_rgb(18, 72, 26)); draw_rectangle(_fm_x + 1, _fm_y + (i * 35) + 1, _fm_x + _fm_w - 1, _fm_y + ((i + 1) * 35) - 1, false); }
        draw_set_color(i == 3 ? make_color_rgb(180, 220, 255) : (i == 4 ? make_color_rgb(190, 160, 240) : (i == 5 ? make_color_rgb(130, 210, 155) : c_white)));
        var _lbl = _opts[i];
        if (i == 0 && script_dirty) _lbl = "NEW SCRIPT";
        draw_text(_fm_x + 15, _fm_y + (i * 35) + 8, _lbl);
        if (i == 1 && script_dirty) { draw_set_color(make_color_rgb(255, 200, 60)); draw_text(_fm_x + _fm_w - 18, _fm_y + (i * 35) + 8, "*"); }
    }
}

// Export status (shows while zipping or briefly on completion)
if (export_status_timer > 0 || export_state == 1) {
    var _ealpha = (export_state == 1) ? 1.0 : min(1.0, export_status_timer / 60.0);
    draw_set_alpha(_ealpha);
    draw_set_color(export_state == 1 ? c_yellow : make_color_rgb(100, 220, 130));
    draw_text(200, 17, export_status_msg);
    draw_set_alpha(1.0);
}

// Quick save notification
if (quick_save_timer > 0) {
    var _fade_in  = min(1.0, (180 - quick_save_timer) / 15.0); // 0.25s fade in
    var _fade_out = min(1.0, quick_save_timer / 40.0);          // ~0.67s fade out
    var _alpha = min(_fade_in, _fade_out);
    var _slide = (1.0 - _fade_in) * 12;                         // slides down from above
    draw_set_alpha(_alpha);
    draw_set_halign(fa_center);
    draw_set_color(make_color_rgb(20, 20, 20));
    draw_roundrect_ext(540, 10 + _slide, 740, 38 + _slide, 6, 6, false);
    draw_set_color(make_color_rgb(80, 200, 100));
    draw_roundrect_ext(540, 10 + _slide, 740, 38 + _slide, 6, 6, true);
    draw_set_color(c_white);
    draw_text(640, 17 + _slide, "SAVED");
    draw_set_halign(fa_left);
    draw_set_alpha(1.0);
}

if (!script_expanded) { // --- 1c. CHARACTER SELECTOR WINDOW ---
draw_set_color(make_color_rgb(12, 48, 18));
draw_rectangle(char_sel_x, char_sel_y, char_sel_x + char_sel_w, char_sel_y + char_sel_h, false);
draw_set_color(make_color_rgb(196, 213, 20)); draw_rectangle(char_sel_x, char_sel_y, char_sel_x + char_sel_w, char_sel_y + char_sel_h, true);
// CHARS / FX tab buttons
var _tab_y = char_sel_y + 4; var _tab_h = 22;
var _tab_c1 = char_sel_x + 5;  var _tab_c2 = char_sel_x + 70;
var _tab_p1 = char_sel_x + 73; var _tab_p2 = char_sel_x + 118;
draw_set_color(!particle_panel_mode ? make_color_rgb(196,213,20) : (_mx>_tab_c1&&_mx<_tab_c2&&_my>_tab_y&&_my<_tab_y+_tab_h ? make_color_rgb(20,72,28) : make_color_rgb(14,52,20)));
draw_roundrect_ext(_tab_c1, _tab_y, _tab_c2, _tab_y+_tab_h, 3, 3, false);
draw_set_color(!particle_panel_mode ? c_black : c_white); draw_set_halign(fa_center); draw_text((_tab_c1+_tab_c2)/2, _tab_y+4, "CHARS"); draw_set_halign(fa_left);
draw_set_color(particle_panel_mode ? make_color_rgb(160,28,28) : (_mx>_tab_p1&&_mx<_tab_p2&&_my>_tab_y&&_my<_tab_y+_tab_h ? make_color_rgb(70,18,18) : make_color_rgb(38,15,15)));
draw_roundrect_ext(_tab_p1, _tab_y, _tab_p2, _tab_y+_tab_h, 3, 3, false);
draw_set_color(particle_panel_mode ? c_white : make_color_rgb(200,80,80)); draw_set_halign(fa_center); draw_text((_tab_p1+_tab_p2)/2, _tab_y+4, "FX"); draw_set_halign(fa_left);

var _is_narrator_sel = (characters[selected_character_index].name == "NARRATOR");
var _has_anims_btn   = (!particle_panel_mode && SHOW_ANIM_EDITOR && canned_anim_get_data(selected_character_index) != undefined);
var _btn_l  = char_sel_x + 195;
var _btn_r  = char_sel_x + char_sel_w - 6;
var _btn_y1 = char_sel_y + 2;
var _btn_y2 = char_sel_y + 26;
var _btn_mid = floor((_btn_l + _btn_r) / 2) - 1;

if (!particle_panel_mode && SHOW_EXPR_CFG) {
    var _ex_r = (SHOW_EXPR_CFG && _has_anims_btn) ? _btn_mid : _btn_r;
    var _ecfg_btn_hov = (!_overlay_active && !_is_narrator_sel && _mx > _btn_l && _mx < _ex_r && _my > _btn_y1 && _my < _btn_y2);
    draw_set_color(_is_narrator_sel ? make_color_rgb(10, 38, 14) : (_ecfg_btn_hov ? make_color_rgb(28, 90, 195) : make_color_rgb(16, 58, 148)));
    draw_roundrect_ext(_btn_l, _btn_y1, _ex_r, _btn_y2, 4, 4, false);
    draw_set_color(_is_narrator_sel ? make_color_rgb(55, 80, 58) : c_white); draw_set_halign(fa_center);
    draw_text((_btn_l + _ex_r) / 2, _btn_y1 + 5, "EXPR CFG");
    draw_set_halign(fa_left);
}
if (_has_anims_btn) {
    var _an_l = (SHOW_EXPR_CFG && _has_anims_btn) ? _btn_mid + 2 : _btn_l;
    var _abtn_hov = (!_overlay_active && !_is_narrator_sel && _mx > _an_l && _mx < _btn_r && _my > _btn_y1 && _my < _btn_y2);
    draw_set_color(_is_narrator_sel ? make_color_rgb(10, 38, 14) : (_abtn_hov ? make_color_rgb(28, 148, 90) : make_color_rgb(16, 90, 58)));
    draw_roundrect_ext(_an_l, _btn_y1, _btn_r, _btn_y2, 4, 4, false);
    draw_set_color(_is_narrator_sel ? make_color_rgb(55, 80, 58) : c_white); draw_set_halign(fa_center);
    draw_text((_an_l + _btn_r) / 2, _btn_y1 + 5, "ANIMS");
    draw_set_halign(fa_left);
}

if (!particle_panel_mode) {
// --- Character Pane Scrollbar ---
var _c_total_h = ceil(array_length(characters) / 2) * 135;
var _c_view_h = char_sel_h - 35;
if (_c_total_h > _c_view_h) {
    var _sb_w = 8; var _sb_x = char_sel_x + char_sel_w - _sb_w - 4;
    var _sb_y = char_sel_y + 35; var _sb_h = char_sel_h - 40;
    draw_set_color(make_color_rgb(8, 32, 12)); draw_rectangle(_sb_x, _sb_y, _sb_x + _sb_w, _sb_y + _sb_h, false);
    var _bar_h = max(20, (_c_view_h / _c_total_h) * _sb_h);
    var _bar_y = clamp(_sb_y + (-char_sel_scroll_y / _c_total_h) * _sb_h, _sb_y, _sb_y + _sb_h - _bar_h);
    var _bar_hov = (!_overlay_active && _mx >= _sb_x - 4 && _mx <= _sb_x + _sb_w + 4 && _my >= _bar_y && _my <= _bar_y + _bar_h);
    draw_set_color(char_sb_dragging ? make_color_rgb(215, 232, 85) : (_bar_hov ? make_color_rgb(185, 205, 60) : make_color_rgb(140, 162, 35)));
    draw_rectangle(_sb_x, _bar_y, _sb_x + _sb_w, _bar_y + _bar_h, false);
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
    if (_hov || dragging_char_index == i) { draw_set_color(make_color_rgb(18, 68, 24)); draw_rectangle(_ix, _iy, _ix + _item_w - 5, _iy + _item_h - 5, false); }
    if (_is_sel && !particle_edit_mode) { draw_set_color(make_color_rgb(196, 213, 20)); draw_rectangle(_ix, _iy, _ix + _item_w - 5, _iy + _item_h - 5, true); }
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
        // Check if this character is dead at the current script position
        var _char_is_dead_sel = false;
        for (var _dpa = 0; _dpa < array_length(preview_actors); _dpa++) {
            if (preview_actors[_dpa].char_index == i && variable_struct_exists(preview_actors[_dpa], "dead") && preview_actors[_dpa].dead) {
                _char_is_dead_sel = true; break;
            }
        }
        var _draw_alpha = _char_is_dead_sel ? 0.35 : _alpha;
        draw_composite_character_ext(_ch_layers, _sx, _sy, _sc, _draw_alpha, _char_is_dead_sel ? make_color_rgb(160, 100, 100) : c_white, false, 3, c_yellow, [char_sel_x + 2, char_sel_y + 30, char_sel_w - 4, char_sel_h - 35]);
        // Restore scissor clip for subsequent selector items (since surface target switches clear it in GameMaker)
        gpu_set_scissor(char_sel_x + 2, char_sel_y + 30, char_sel_w - 4, char_sel_h - 35);
        if (_char_is_dead_sel) {
            draw_set_color(make_color_rgb(200, 30, 30)); draw_set_alpha(0.65);
            draw_line_width(_ix + 8, _iy + 8, _ix + _item_w - 13, _iy + _item_h - 28, 3);
            draw_line_width(_ix + _item_w - 13, _iy + 8, _ix + 8, _iy + _item_h - 28, 3);
            draw_set_alpha(1.0);
        }
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
        draw_set_color(_is_sel ? make_color_rgb(220, 238, 88) : c_white);
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
} else {
    // --- Particle Effects Panel ---
    gpu_set_scissor(char_sel_x + 2, char_sel_y + 30, char_sel_w - 4, char_sel_h - 35);
    // [id, label, bg_normal, bg_hover, bg_drag, border, icon_rgb]
    var _pe_list = [
        ["splatter",  "SPLATTER",  [65,12,12],  [95,18,18],  [40,8,8],    [165,28,28],  [200,22,22]],
        ["shatter",   "SHATTER",   [10,28,58],  [16,52,98],  [6,18,42],   [22,90,175],  [155,210,245]],
        ["electrify", "ELECTRIFY", [22,18,58],  [42,35,98],  [15,12,44],  [82,62,175],  [230,220,55]],
        ["laser",     "LASER",     [35,10,5],   [62,20,8],   [22,6,3],    [195,75,18],  [255,155,38]],
        ["debris",    "DEBRIS",    [38,28,12],  [58,42,16],  [24,18,7],   [105,72,30],  [175,140,68]],
        ["flame",     "FLAME",     [55,18,5],   [85,28,8],   [35,10,3],   [200,70,12],  [255,140,20]],
        ["explosion", "EXPLOSION", [62,20,5],   [95,32,8],   [38,12,3],   [215,85,18],  [255,175,25]],
        ["shot",      "SHOT",      [12,38,55],  [18,62,92],  [8,24,42],   [28,110,185], [200,230,255]],
    ];
    var _tile_w = 155; var _tile_h = 82;
    for (var _pei = 0; _pei < array_length(_pe_list); _pei++) {
        var _pe = _pe_list[_pei];
        var _tx = char_sel_x + 10 + (_pei % 2) * 168;
        var _ty = char_sel_y + 40 + floor(_pei / 2) * 95;
        var _is_dragging_this = (dragging_particle_effect == _pe[0]);
        var _tile_hov = (!_overlay_active && !_is_dragging_this && _mx > _tx && _mx < _tx + _tile_w && _my > _ty && _my < _ty + _tile_h && _my > char_sel_y + 30 && _my < char_sel_y + char_sel_h);
        var _bg = _is_dragging_this ? _pe[4] : (_tile_hov ? _pe[3] : _pe[2]);
        draw_set_color(make_color_rgb(_bg[0], _bg[1], _bg[2]));
        draw_rectangle(_tx, _ty, _tx+_tile_w, _ty+_tile_h, false);
        draw_set_color(make_color_rgb(_pe[5][0], _pe[5][1], _pe[5][2]));
        draw_rectangle(_tx, _ty, _tx+_tile_w, _ty+_tile_h, true);
        // effect icon
        draw_set_color(make_color_rgb(_pe[6][0], _pe[6][1], _pe[6][2])); draw_set_alpha(0.85);
        if (_pe[0] == "shatter") {
            draw_circle(_tx + _tile_w/2, _ty + 28, 11, true);
            draw_line(_tx+_tile_w/2, _ty+17, _tx+_tile_w/2-7, _ty+31);
            draw_line(_tx+_tile_w/2-7, _ty+31, _tx+_tile_w/2+2, _ty+39);
            draw_line(_tx+_tile_w/2, _ty+17, _tx+_tile_w/2+6, _ty+32);
            draw_line(_tx+_tile_w/2+6, _ty+32, _tx+_tile_w/2-3, _ty+39);
        } else if (_pe[0] == "electrify") {
            draw_line_width(_tx+_tile_w/2+6, _ty+14, _tx+_tile_w/2-3, _ty+27, 2);
            draw_line_width(_tx+_tile_w/2-3, _ty+27, _tx+_tile_w/2+5, _ty+27, 2);
            draw_line_width(_tx+_tile_w/2+5, _ty+27, _tx+_tile_w/2-6, _ty+42, 2);
        } else if (_pe[0] == "laser") {
            draw_circle(_tx + 20, _ty + 28, 4, false);
            draw_set_alpha(0.18); draw_line_width(_tx+20, _ty+28, _tx+_tile_w-12, _ty+28, 12);
            draw_set_alpha(0.50); draw_line_width(_tx+20, _ty+28, _tx+_tile_w-12, _ty+28, 5);
            draw_set_alpha(1.0);  draw_line_width(_tx+20, _ty+28, _tx+_tile_w-12, _ty+28, 1.5);
        } else if (_pe[0] == "debris") {
            var _dcx = _tx + _tile_w/2;
            // Irregular chunks + splinters flying outward
            draw_triangle(_dcx-12, _ty+22, _dcx-2,  _ty+18, _dcx-8,  _ty+33, false); // big chunk
            draw_triangle(_dcx+4,  _ty+22, _dcx+14, _ty+25, _dcx+9,  _ty+38, false); // smaller chunk
            draw_line_width(_dcx-6, _ty+38, _dcx+16, _ty+20, 2);                      // splinter
            draw_line_width(_dcx-14, _ty+28, _dcx+2,  _ty+15, 1.5);                  // thin splinter
        } else if (_pe[0] == "flame") {
            var _fcx = _tx + _tile_w/2;
            // Outer flame body
            draw_triangle(_fcx - 10, _ty+42, _fcx + 10, _ty+42, _fcx, _ty+14, false);
            // Inner bright core
            draw_set_color(make_color_rgb(255, 230, 100)); draw_set_alpha(0.9);
            draw_triangle(_fcx - 5, _ty+40, _fcx + 5, _ty+40, _fcx, _ty+24, false);
            // Side wisps
            draw_set_color(make_color_rgb(_pe[6][0], _pe[6][1], _pe[6][2])); draw_set_alpha(0.6);
            draw_triangle(_fcx - 13, _ty+38, _fcx - 4, _ty+38, _fcx - 8, _ty+22, false);
            draw_triangle(_fcx + 4,  _ty+38, _fcx + 13, _ty+38, _fcx + 8, _ty+22, false);
        } else if (_pe[0] == "explosion") {
            var _ecx = _tx + _tile_w/2; var _ecy = _ty + 28;
            // Starburst: 8 alternating long/short spikes + center circle
            for (var _ri = 0; _ri < 8; _ri++) {
                var _rang = _ri * (pi / 4.0) + 0.22;
                var _rlen = (_ri mod 2 == 0) ? 17 : 10;
                draw_line_width(_ecx, _ecy, _ecx + cos(_rang)*_rlen, _ecy + sin(_rang)*_rlen, 2.2);
            }
            draw_circle(_ecx, _ecy, 5, false);
        } else if (_pe[0] == "shot") {
            var _scx = _tx + _tile_w/2;
            draw_set_alpha(0.18); draw_line_width(_scx - 22, _ty+28, _scx + 22, _ty+28, 12);
            draw_set_alpha(0.50); draw_line_width(_scx - 22, _ty+28, _scx + 22, _ty+28, 5);
            draw_set_alpha(1.0);  draw_line_width(_scx - 22, _ty+28, _scx + 22, _ty+28, 2);
            draw_set_color(make_color_rgb(255,255,255)); draw_set_alpha(0.95);
            draw_line_width(_scx - 22, _ty+28, _scx + 22, _ty+28, 0.8);
            draw_set_color(make_color_rgb(_pe[6][0], _pe[6][1], _pe[6][2]));
        } else {
            draw_circle(_tx + _tile_w/2, _ty + 28, 12, false);
        }
        draw_set_alpha(1.0);
        draw_set_color(c_white); draw_set_halign(fa_center);
        draw_text(_tx + _tile_w/2, _ty + 56, _pe[1]);
        draw_set_halign(fa_left);
    }
    gpu_set_scissor(0, 0, 1280, 960);
}
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

    // Facing: mirrors drop logic exactly — left of centre gets -1, right gets 1 — consistent
    // in all modes so the ghost never flips as the cursor enters the scene area.
    var _drag_face = undefined;
    if (dragging_char_index != -1) {
        var _ghost_is_left = (_mx < scene_win_x + scene_win_w / 2);
        _drag_face = _ghost_is_left ? -1 : 1;
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

        var _min_x = 0; var _max_x = _csw;
        var _min_y = 0; var _max_y = _csh;
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
        var _true_w = (_max_x - _min_x) * _scale;
        var _true_h = (_max_y - _min_y) * _scale;

        var _ay_abs = scene_win_y + _py;
        var _v_top = _ay_abs - _ch + _min_y * _scale;
        var _v_bottom = _ay_abs - _ch + _max_y * _scale;
        var _v_visible = max(0, min(_v_bottom, scene_win_y + scene_win_h) - max(_v_top, scene_win_y));

        var _ax_abs = scene_win_x + _px;
        var _h_left  = _ax_abs - _cw / 2 + _min_x * _scale;
        var _h_right = _ax_abs - _cw / 2 + _max_x * _scale;

        var _h_intersect_l = max(_h_left, scene_win_x);
        var _h_intersect_r = min(_h_right, scene_win_x + scene_win_w);
        var _h_visible = max(0, _h_intersect_r - _h_intersect_l);

        var _in_live = (current_scene_sprite != -1) && (_h_visible >= _true_w * 0.20) && (_v_visible >= _true_h * 0.20);
        var _color = _in_live ? c_white : c_red;
        var _alpha = _in_live ? 0.6 : 0.4;

        gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
        var _gx = scene_win_x + _px - (_csw * _scale)/2;
        var _gy = scene_win_y + _py - (_csh * _scale);
        draw_composite_character_ext(_layers, _gx, _gy, _scale, _alpha, _color, false, 3, c_yellow, [scene_win_x, scene_win_y, scene_win_w, scene_win_h]);
        gpu_set_scissor(0, 0, 1280, 960);
    }
}
} // end !script_expanded char selector

// Particle drag ghost
if (dragging_particle_effect != "") {
    var _dpe_r = 185; var _dpe_g = 18; var _dpe_b = 18;
    if (dragging_particle_effect == "shatter")   { _dpe_r = 22;  _dpe_g = 90;  _dpe_b = 175; }
    if (dragging_particle_effect == "electrify") { _dpe_r = 82;  _dpe_g = 62;  _dpe_b = 175; }
    if (dragging_particle_effect == "flame")      { _dpe_r = 220; _dpe_g = 80;  _dpe_b = 10;  }
    if (dragging_particle_effect == "explosion")  { _dpe_r = 255; _dpe_g = 160; _dpe_b = 20;  }
    if (dragging_particle_effect == "shot")       { _dpe_r = 100; _dpe_g = 190; _dpe_b = 255; }
    var _dpx = drag_particle_x; var _dpy = drag_particle_y;
    var _in_scene_dp = (_dpx > scene_win_x && _dpx < scene_win_x + scene_win_w
                     && _dpy > scene_win_y && _dpy < scene_win_y + scene_win_h);
    // Full-width/height crosshair lines across the scene when hovering over it
    if (_in_scene_dp) {
        gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
        draw_set_color(make_color_rgb(_dpe_r, _dpe_g, _dpe_b)); draw_set_alpha(0.22);
        draw_line(scene_win_x, _dpy, scene_win_x + scene_win_w, _dpy);
        draw_line(_dpx, scene_win_y, _dpx, scene_win_y + scene_win_h);
        draw_set_alpha(1.0);
        gpu_set_scissor(0, 0, 1280, 960);
    }
    // Outer glow
    draw_set_color(make_color_rgb(_dpe_r, _dpe_g, _dpe_b)); draw_set_alpha(0.18);
    draw_circle(_dpx, _dpy, 30, false);
    // Main circle
    draw_set_alpha(0.78); draw_circle(_dpx, _dpy, 20, false);
    // Border
    draw_set_color(make_color_rgb(min(255,_dpe_r+80), min(255,_dpe_g+80), min(255,_dpe_b+80))); draw_set_alpha(1.0);
    draw_circle(_dpx, _dpy, 20, true);
    // Mini effect icon inside circle
    draw_set_color(make_color_rgb(min(255,_dpe_r+110), min(255,_dpe_g+110), min(255,_dpe_b+110)));
    if (dragging_particle_effect == "laser" || dragging_particle_effect == "shot") {
        draw_set_alpha(0.18); draw_line_width(_dpx-14, _dpy, _dpx+14, _dpy, 8);
        draw_set_alpha(0.55); draw_line_width(_dpx-14, _dpy, _dpx+14, _dpy, 3.5);
        draw_set_alpha(1.0);  draw_line_width(_dpx-14, _dpy, _dpx+14, _dpy, 1.2);
    } else if (dragging_particle_effect == "explosion") {
        draw_set_alpha(0.9);
        for (var _dri = 0; _dri < 6; _dri++) {
            var _dra = _dri * (pi / 3.0) + 0.3;
            draw_line_width(_dpx, _dpy, _dpx + cos(_dra)*13, _dpy + sin(_dra)*13, 1.8);
        }
        draw_circle(_dpx, _dpy, 4, false);
    } else if (dragging_particle_effect == "electrify") {
        draw_set_alpha(0.9);
        draw_line_width(_dpx+5, _dpy-10, _dpx-2, _dpy, 2);
        draw_line_width(_dpx-2, _dpy, _dpx+5, _dpy+1, 2);
        draw_line_width(_dpx+5, _dpy+1, _dpx-5, _dpy+10, 2);
    } else if (dragging_particle_effect == "flame") {
        draw_set_alpha(0.9);
        draw_triangle(_dpx-7, _dpy+10, _dpx+7, _dpy+10, _dpx, _dpy-9, false);
        draw_set_color(make_color_rgb(255,230,80)); draw_set_alpha(0.8);
        draw_triangle(_dpx-3, _dpy+8, _dpx+3, _dpy+8, _dpx, _dpy-3, false);
    } else {
        draw_set_alpha(0.9); draw_circle(_dpx, _dpy, 5, false);
        draw_set_alpha(0.45); draw_circle(_dpx, _dpy, 11, true);
    }
    draw_set_alpha(1.0);
    // Label badge
    draw_set_color(make_color_rgb(_dpe_r, _dpe_g, _dpe_b));
    var _dlbl = string_upper(dragging_particle_effect);
    var _dlw = string_width(_dlbl) + 16;
    draw_set_color(make_color_rgb(16, 16, 26)); draw_set_alpha(0.90);
    draw_roundrect_ext(_dpx - _dlw/2, _dpy - 46, _dpx + _dlw/2, _dpy - 30, 4, 4, false);
    draw_set_color(make_color_rgb(_dpe_r, _dpe_g, _dpe_b)); draw_set_alpha(1.0);
    draw_roundrect_ext(_dpx - _dlw/2, _dpy - 46, _dpx + _dlw/2, _dpy - 30, 4, 4, true);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_dpx, _dpy - 45, _dlbl);
    draw_set_halign(fa_left);
}

// --- EXPAND / COLLAPSE TOGGLE ---
if (script_expanded) {
    gpu_set_scissor(0, 0, 1280, 960); // Full-screen scissor so header+collapse draw unclipped
    // Header strip
    draw_set_color(make_color_rgb(14, 52, 20));
    draw_rectangle(box_x - 4, 0, box_x + box_w + 4, box_y, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_line(box_x - 4, box_y, box_x + box_w + 4, box_y);
    // Collapse button (top-right of header)
    var _tog_x = box_x + box_w - 98; var _tog_y = 30;
    var _tog_hov = (_mx > _tog_x && _mx < _tog_x + 92 && _my > _tog_y && _my < _tog_y + 30);
    draw_set_color(_tog_hov ? make_color_rgb(130, 50, 18) : make_color_rgb(90, 32, 10));
    draw_roundrect_ext(_tog_x, _tog_y, _tog_x+92, _tog_y+30, 5, 5, false);
    draw_set_color(make_color_rgb(220, 160, 80));
    draw_roundrect_ext(_tog_x, _tog_y, _tog_x+92, _tog_y+30, 5, 5, true);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_tog_x+46, _tog_y+7, "v COLLAPSE"); draw_set_halign(fa_left);
} else {
    // Expand button — sits right of the PLAY button, same row
    var _tog_x = btn_play_x + btn_play_w + 12; var _tog_y = btn_play_y;
    var _tog_hov = (_mx > _tog_x && _mx < _tog_x + 92 && _my > _tog_y && _my < _tog_y + btn_play_h);
    draw_set_color(_tog_hov ? make_color_rgb(28, 90, 35) : make_color_rgb(14, 55, 20));
    draw_roundrect_ext(_tog_x, _tog_y, _tog_x+92, _tog_y+btn_play_h, 5, 5, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_tog_x, _tog_y, _tog_x+92, _tog_y+btn_play_h, 5, 5, true);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_tog_x+46, _tog_y+10, "^ EXPAND"); draw_set_halign(fa_left);
}

// --- 2. SCRIPT BLOCKS RENDERING ---
draw_set_color(make_color_rgb(250, 250, 250));
draw_rectangle(box_x + 10, box_y + 5, box_x + box_w - 10, box_y + box_h - 5, false);
gpu_set_scissor(box_x - 50, box_y + 5, box_w + 40, box_h - 10);
var _cur_y = box_y + 5 + block_scroll_y;
var _wrap_w = box_w - 120;
var _onstage = [];
var _scene_encountered = false;

// --- Chain group borders (pre-pass: drawn under block content) ---
{
    var _cby = box_y + 5 + block_scroll_y;
    var _chain_in = false; var _chain_top = 0;
    for (var _bi = 0; _bi < array_length(script_blocks); _bi++) {
        var _bb = script_blocks[_bi];
        var _lnk = (variable_struct_exists(_bb, "linked") && _bb.linked);
        if (!_chain_in && _lnk) {
            _chain_in = true; _chain_top = _cby;
        }
        if (_chain_in && !_lnk) {
            var _chain_bot = _cby + _bb.height + 16;
            draw_set_color(make_color_rgb(90, 170, 225));
            draw_set_alpha(0.06); draw_roundrect_ext(box_x+38, _chain_top+1, box_x+box_w-38, _chain_bot, 6,6, false);
            draw_set_alpha(0.65); draw_roundrect_ext(box_x+38, _chain_top+1, box_x+box_w-38, _chain_bot, 6,6, true);
            draw_set_alpha(1.0);
            _chain_in = false;
        }
        _cby += _bb.height + 20;
    }
    // Safety: close any open chain at end of list
    if (_chain_in && array_length(script_blocks) > 0) {
        var _last = script_blocks[array_length(script_blocks)-1];
        draw_set_color(make_color_rgb(90, 170, 225));
        draw_set_alpha(0.06); draw_roundrect_ext(box_x+38, _chain_top+1, box_x+box_w-38, _cby-20+_last.height+16, 6,6, false);
        draw_set_alpha(0.65); draw_roundrect_ext(box_x+38, _chain_top+1, box_x+box_w-38, _cby-20+_last.height+16, 6,6, true);
        draw_set_alpha(1.0);
    }
}

for (var b = 0; b < array_length(script_blocks); b++) {
    var _block = script_blocks[b];
    var _is_scene    = variable_struct_exists(_block, "type") && _block.type == "scene";
    var _is_action   = variable_struct_exists(_block, "type") && _block.type == "action";
    var _is_particle = variable_struct_exists(_block, "type") && _block.type == "particle";
    var _is_voice    = !_is_scene && !_is_action && !_is_particle;

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
        var _is_kill = variable_struct_exists(_block, "kill_style") || (string_pos("KILL", _aname_u) > 0);
        var _is_resurrect = (string_pos("RESURRECTS", _aname_u) > 0);
        var _is_turn_around = (string_pos("TURNS AROUND", _aname_u) > 0);
        
        var _is_canned = (variable_struct_exists(_block, "char_index") && _block.char_index > 0 && canned_anim_find(_block.char_index, _block.action_name) != undefined);
        
        var _is_move = (string_pos("MOVE", _aname_u) > 0 || string_pos("ENTER", _aname_u) > 0 || string_pos("EXIT", _aname_u) > 0);
        var _has_looks = (string_pos("looks ", _aname_lo) > 0);
        var _has_and_pose = (_has_looks && string_pos("and pose ", _aname_lo) > 0);
        var _is_expr_only = (string_pos("expression:", _aname_lo) > 0) || (_has_looks && !_has_and_pose);
        var _is_pose = (!_is_expr_only) && (string_pos("poses ", _aname_lo) > 0 || _has_and_pose
                            || (string_pos("pose ", _aname_lo) > 0 && string_pos("poses ", _aname_lo) == 0 && !_has_looks));
        
        if (_is_resurrect || _is_turn_around) {
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
            } else if (_is_kill) {
                _edit_lbl = "EDIT KILL METHOD";
                _edit_w = 150;
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
    var _edit_btn_y = (_is_voice) ? _cur_y - 4 : _cur_y + 5;

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
        var _is_focused = (focused_block == b);
        var _bg_col;
        if (_is_playing) {
            _bg_col = make_color_rgb(255, 255, 180);
        } else if (_is_focused) {
            _bg_col = make_color_rgb(242, 250, 160);
        } else {
            _bg_col = make_color_rgb(226, 240, 95);
        }
        draw_set_color(_bg_col);
        draw_rectangle(box_x + 45, _box_y, box_x + box_w - 45, _box_y + 80, false);
        
        draw_set_color(_is_focused ? make_color_rgb(25, 80, 185) : c_black);
        draw_rectangle(box_x + 45, _box_y, box_x + box_w - 45, _box_y + 80, true);
        if (_is_focused) {
            draw_rectangle(box_x + 44, _box_y - 1, box_x + box_w - 44, _box_y + 81, true);
        }
        
        draw_set_color(c_black); draw_text(box_x + 55, _box_y + 30, "[SCENE: " + string_upper(_block.name) + "]");
    } else if (_is_action) {
        var _aname = string_lower(_block.action_name);
        if (string_pos("enter", _aname) > 0) {
            var _found = false; for(var o=0; o<array_length(_onstage); o++) if (_onstage[o] == _block.char_index) _found = true;
            if (!_found) array_push(_onstage, _block.char_index);
        } else if (string_pos("exit", _aname) > 0 || string_pos("disappears", _aname) > 0) {
            for(var o=0; o<array_length(_onstage); o++) {
                if (_onstage[o] == _block.char_index) { array_delete(_onstage, o, 1); break; }
            }
        }

        var _box_y = _cur_y + 5;
        var _is_playing = (playing_block_index != -1 && b >= playing_block_index && b <= max(playing_block_index, playing_linked_index));
        var _is_focused = (focused_block == b);
        var _is_disappear = (string_pos("DISAPPEARS", string_upper(_block.action_name)) > 0);
        var _bg_col;
        if (_is_playing) {
            _bg_col = make_color_rgb(255, 255, 180);
        } else if (_is_focused) {
            _bg_col = _is_disappear ? make_color_rgb(230, 220, 255) : make_color_rgb(230, 240, 255);
        } else {
            _bg_col = _is_disappear ? make_color_rgb(210, 200, 240) : make_color_rgb(210, 225, 255);
        }
        draw_set_color(_bg_col);
        draw_rectangle(box_x + 45, _box_y, box_x + box_w - 45, _box_y + 80, false);

        var _aname_up = string_upper(_block.action_name);
        var _is_wait      = (string_pos("WAIT",          _aname_up) > 0);
        var _is_sfx       = (string_pos("PLAY SFX",      _aname_up) > 0);
        var _is_title     = (string_pos("DISPLAY TITLE", _aname_up) > 0);
        var _is_expr_blk  = (string_pos("EXPRESSION:", _aname_up) > 0 || string_pos("LOOKS ", _aname_up) > 0 || (string_pos("POSE ", _aname_up) > 0 && string_pos("POSES ", _aname_up) == 0));
        if (_is_expr_blk && !_is_playing) {
            draw_set_color(_is_focused ? make_color_rgb(235, 242, 255) : make_color_rgb(215, 228, 255));
            draw_rectangle(box_x + 45, _box_y, box_x + box_w - 45, _box_y + 80, false);
        }
        
        draw_set_color(_is_focused ? make_color_rgb(25, 80, 185) : c_black);
        draw_rectangle(box_x + 45, _box_y, box_x + box_w - 45, _box_y + 80, true);
        if (_is_focused) {
            draw_rectangle(box_x + 44, _box_y - 1, box_x + box_w - 44, _box_y + 81, true);
        }
        
        var _act_str = "ACTION: ";
        var _is_quake_blk = variable_struct_exists(_block, "quake_intensity");
        if (_is_wait || _is_sfx || _is_title || _is_quake_blk) {
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
    } else if (_is_particle) {
        var _box_y = _cur_y + 5;
        var _is_playing = (playing_block_index != -1 && b >= playing_block_index && b <= max(playing_block_index, playing_linked_index));
        var _is_focused = (focused_block == b);
        var _is_editing_this = (particle_edit_mode && particle_edit_block_idx == b);
        var _bg_col;
        if (_is_playing) {
            _bg_col = make_color_rgb(255, 220, 220);
        } else if (_is_editing_this) {
            _bg_col = make_color_rgb(120, 45, 10);
        } else if (_is_focused) {
            _bg_col = make_color_rgb(90, 30, 30);
        } else {
            _bg_col = make_color_rgb(55, 10, 10);
        }
        draw_set_color(_bg_col);
        draw_rectangle(box_x + 45, _box_y, box_x + box_w - 45, _box_y + 80, false);

        draw_set_color(_is_editing_this ? make_color_rgb(220, 120, 20) : (_is_focused ? make_color_rgb(25, 80, 185) : make_color_rgb(175, 28, 28)));
        draw_rectangle(box_x + 45, _box_y, box_x + box_w - 45, _box_y + 80, true);
        if (_is_editing_this || _is_focused) {
            draw_rectangle(box_x + 44, _box_y - 1, box_x + box_w - 44, _box_y + 81, true);
        }

        draw_set_color(_is_playing ? c_black : (_is_editing_this ? c_yellow : c_white));
        var _eff_lbl = string_upper(_block.effect);
        draw_text(box_x + 55, _box_y + 28, "[FX: " + _eff_lbl + "]");
        draw_set_color(make_color_rgb(140, 140, 140));
        draw_text(box_x + 55, _box_y + 50, "pos (" + string(round(_block.x)) + ", " + string(round(_block.y)) + ")  angle " + string(round(_block.angle)) + chr(176));
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
        var _is_alt = _is_v && (variable_struct_exists(_block, "is_altered") ? _block.is_altered : (_block.voice_id != _c_ref.voice_id || _block.pitch != _c_ref.pitch || _block.speed != _c_ref.speed || _block.mode != _c_ref.mode || _block.style != _c_ref.style || (_block[$ "glottal"] ?? -1) != (_c_ref[$ "glottal"] ?? -1) || _block.tweaked != _c_ref.tweaked));
        
        var _char_name = string_upper(_c_ref.name);
        if (_is_alt) _char_name += " (altered voice)";
        if (!_is_onstage && _block.char_index != 0) _char_name += " (offstage)";
        
        draw_set_color(make_color_rgb(55, 105, 62)); draw_text(box_x + 50, _cur_y, _char_name + ":");
        var _is_playing = (playing_block_index != -1 && b >= playing_block_index && b <= max(playing_block_index, playing_linked_index));
        draw_set_color(_is_playing ? make_color_rgb(255, 255, 180) : (_is_focused ? make_color_rgb(230, 245, 255) : c_white));
        draw_rectangle(box_x + 45, _cur_y + 20, box_x + box_w - 45, _cur_y + 20 + _text_h, false);
        draw_set_color(_is_focused ? make_color_rgb(25, 80, 185) : c_black); draw_rectangle(box_x + 45, _cur_y + 20, box_x + box_w - 45, _cur_y + 20 + _text_h, true);
        if (_is_focused) {
            draw_rectangle(box_x + 44, _cur_y + 19, box_x + box_w - 44, _cur_y + 20 + _text_h + 1, true);
        }

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
    var _btn_base_y = (_is_scene || _is_action || _is_particle) ? _cur_y + 5 : _cur_y + 20;
    
    // Left Hover Checks
    var _hov_up = (!_overlay_active && playing_block_index == -1 && _mx > _lx && _mx < _lx + _bw && _my > _btn_base_y + 8 && _my < _btn_base_y + 8 + _bh);
    var _hov_dn = (!_overlay_active && playing_block_index == -1 && _mx > _lx && _mx < _lx + _bw && _my > _btn_base_y + 38 && _my < _btn_base_y + 38 + _bh);
    
    // Right Hover Checks
    var _hov_del = (!_overlay_active && playing_block_index == -1 && _mx > _rx && _mx < _rx + _bw && _my > _cur_y + 5 && _my < _cur_y + 5 + _bh);

    // Render Left Stack
    draw_set_color((playing_block_index != -1) ? make_color_rgb(80, 80, 90) : (_hov_up ? make_color_rgb(140, 140, 170) : make_color_rgb(100, 100, 120)));
    draw_rectangle(_lx, _btn_base_y + 8, _lx + _bw, _btn_base_y + 8 + _bh, false); 
    draw_set_color((playing_block_index != -1) ? c_gray : c_white); draw_text(_lx+8, _btn_base_y + 8, "^");
    
    draw_set_color((playing_block_index != -1) ? make_color_rgb(80, 80, 90) : (_hov_dn ? make_color_rgb(140, 140, 170) : make_color_rgb(100, 100, 120)));
    draw_rectangle(_lx, _btn_base_y + 38, _lx + _bw, _btn_base_y + 38 + _bh, false); 
    draw_set_color((playing_block_index != -1) ? c_gray : c_white); draw_text(_lx+8, _btn_base_y + 38, "v");

    // Render Right Stack
    draw_set_color((playing_block_index != -1) ? make_color_rgb(120, 60, 60) : (_hov_del ? make_color_rgb(230, 80, 80) : make_color_rgb(180, 50, 50)));
    draw_rectangle(_rx, _cur_y + 5, _rx + _bw, _cur_y + 5 + _bh, false); 
    draw_set_color((playing_block_index != -1) ? c_gray : c_white); draw_text(_rx+6, _cur_y + 5, "X");

    // Render Top-Right Edit Button
    if (_show_edit_btn) {
        var _edit_hov = (!_overlay_active && playing_block_index == -1 && _mx > _edit_btn_x && _mx < _edit_btn_x + _edit_w && _my > _edit_btn_y && _my < _edit_btn_y + _edit_btn_h);
        gpu_set_texfilter(true);
        draw_set_color((playing_block_index != -1) ? make_color_rgb(45,35,20) : (_edit_hov ? make_color_rgb(145,75,10) : make_color_rgb(100,52,8)));
        draw_roundrect_ext(_edit_btn_x, _edit_btn_y, _edit_btn_x + _edit_w, _edit_btn_y + _edit_btn_h, 5, 5, false);
        draw_set_color((playing_block_index != -1) ? make_color_rgb(80,68,50) : (_edit_hov ? c_white : make_color_rgb(220,150,55)));
        draw_roundrect_ext(_edit_btn_x, _edit_btn_y, _edit_btn_x + _edit_w, _edit_btn_y + _edit_btn_h, 5, 5, true);
        draw_set_color((playing_block_index != -1) ? make_color_rgb(120,110,90) : c_white);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        var _lbl_y_off = _is_voice ? -2 : -1;
        draw_text_transformed(_edit_btn_x + _edit_w/2, _edit_btn_y + _edit_btn_h/2 + _lbl_y_off, _edit_lbl, 0.75, 0.75, 0);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        gpu_set_texfilter(false);
    }

    // 4. Play From Here (Green Triangle) - Now in the GUTTER
    if (playing_block_index == -1) {
        var _px = box_x - 30; var _py = _cur_y + 5;
        var _phov = (!_overlay_active && _mx > _px && _mx < _px + 30 && _my > _py && _my < _py + 30);
        draw_set_color(_phov ? c_lime : c_green);
        draw_triangle(_px+5, _py+5, _px+5, _py+25, _px+25, _py+15, false);
    }

    var _gap_y = _cur_y + _block.height;
    if (focused_block == b && b < array_length(script_blocks) - 1 && !action_animating && playing_block_index == -1) {
        draw_set_color(c_yellow);
        draw_set_alpha(0.3);
        draw_rectangle(box_x + 10, _gap_y + 2, box_x + box_w - 10, _gap_y + 23, false);
        draw_set_alpha(1.0);
        draw_set_color(c_yellow);
        draw_line_width(box_x + 10, _gap_y + 12, box_x + box_w - 10, _gap_y + 12, 2);
    }
    
    // 5. Draw Splice Mode / Link Button Context
    if (b < array_length(script_blocks) - 1 && playing_block_index == -1) {
        // 6. Draw "LINK" Button
        var _b1 = script_blocks[b];
        var _is_linked = variable_struct_exists(_b1, "linked") && _b1.linked;
        
        var _b2 = script_blocks[b+1];

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
            var _other_ct = (_b1_type == "canned") ? _b2_type : _b1_type;
            // Same-char: only movement is allowed alongside a special animation
            if (_other_ct == "move" && !_diff_char) _base_valid = true;
            // General actions are always fine
            else if (_other_ct == "sfx" || _other_ct == "quake" || _other_ct == "particle" || _other_ct == "title") _base_valid = true;
            // Different-character blocks are fine
            else if (_diff_char && (_other_ct == "voice" || _other_ct == "move" || _other_ct == "charaction" || _other_ct == "canned")) _base_valid = true;
        }

        var _chain_valid = true;

        if (_base_valid && !_is_linked) {
            var _start_idx = b;
            while (_start_idx > 0 && variable_struct_exists(script_blocks[_start_idx-1], "linked") && script_blocks[_start_idx-1].linked) _start_idx--;
            var _end_idx = b + 1;
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

                if (_bk_type == "kill" || _bk_type == "jitter" || _bk_type == "voice" || _bk_type == "move" || _bk_type == "charaction" || _bk_type == "canned") {
                    for (var j = k + 1; j <= _end_idx; j++) {
                        var _bj = script_blocks[j];
                        if (real(variable_struct_exists(_bj, "char_index") ? _bj.char_index : 0) == _c_idx) {
                            var _bj_type = get_link_type(_bj);
                            if (_bk_type == "kill"   && _bj_type != "sfx" && _bj_type != "particle" && _bj_type != "other") { _chain_valid = false; break; }
                            if (_bj_type == "kill"   && _bk_type != "sfx" && _bk_type != "particle" && _bk_type != "other") { _chain_valid = false; break; }
                            if (_bk_type == "jitter" && _bj_type == "jitter")     { _chain_valid = false; break; }
                            if (_bk_type == "jitter" && _bj_type == "charaction") { _chain_valid = false; break; }
                            if (_bk_type == "charaction" && _bj_type == "jitter") { _chain_valid = false; break; }
                            if (_bk_type == "voice"  && _bj_type == "voice")      { _chain_valid = false; break; }
                            if (_bk_type == "move"   && _bj_type == "move")       { _chain_valid = false; break; }
                            if (_bk_type == "charaction" && (_bj_type == "charaction" || _bj_type == "move")) { _chain_valid = false; break; }
                            if (_bk_type == "move"   && _bj_type == "charaction") { _chain_valid = false; break; }
                            // Canned animation: same character cannot also talk, do other char-actions, or run another canned anim
                            if (_bk_type == "canned" && (_bj_type == "voice" || _bj_type == "charaction" || _bj_type == "canned")) { _chain_valid = false; break; }
                            if (_bj_type == "canned" && (_bk_type == "voice" || _bk_type == "charaction")) { _chain_valid = false; break; }
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

var _sb_x = box_x + box_w - 12;
var _sb_w = 10;
if (_full_h > box_h - 10) {
    var _view_h = box_h - 10;
    var _bar_h = max(20, (_view_h / _full_h) * _view_h);
    var _max_bar_top = (box_y + 5) + _view_h - _bar_h;
    var _bar_y = clamp((box_y + 5) + (-block_scroll_y / _full_h) * _view_h, box_y + 5, _max_bar_top);
    var _sb_hov = (_mx >= _sb_x && _mx <= _sb_x + _sb_w && _my >= box_y + 5 && _my <= box_y + box_h - 5);
    var _bar_hov = (_mx >= _sb_x && _mx <= _sb_x + _sb_w && _my >= _bar_y && _my <= _bar_y + _bar_h);

    // Track
    draw_set_color(make_color_rgb(60, 60, 72));
    draw_rectangle(_sb_x, box_y + 5, _sb_x + _sb_w, box_y + box_h - 5, false);
    // Bar
    draw_set_color(script_scrollbar_dragging ? make_color_rgb(170, 170, 200) : (_bar_hov ? make_color_rgb(150, 150, 175) : make_color_rgb(110, 110, 130)));
    draw_rectangle(_sb_x, _bar_y, _sb_x + _sb_w, _bar_y + _bar_h, false);
}

// --- 5b. SCRIPT NAV BUTTONS ---
{
    var _nb_x   = box_x + box_w + 5;
    var _nb_w   = 38;
    var _nb_h   = 26;
    var _nb_gap = 5;
    var _nb_y   = box_y + (box_h - (4 * _nb_h + 3 * _nb_gap)) / 2;

    // Compute scroll bounds for disabled states
    var _nav_full_h = 0;
    for (var _ni = 0; _ni < array_length(script_blocks); _ni++) _nav_full_h += script_blocks[_ni].height + 20;
    var _nav_can_scroll = (_nav_full_h > box_h - 20);
    var _nav_max_scroll = _nav_can_scroll ? (-(_nav_full_h + box_h / 2 - (box_h - 20))) : 0;
    var _at_top    = !_nav_can_scroll || block_scroll_y >= 0;
    var _at_bottom = !_nav_can_scroll || block_scroll_y <= _nav_max_scroll;
    var _is_playing = (playing_block_index != -1 || theater_mode);

    for (var _bi = 0; _bi < 4; _bi++) {
        var _by = _nb_y + _bi * (_nb_h + _nb_gap);
        var _disabled = _is_playing || ((_bi < 2) ? _at_top : _at_bottom);
        var _hov = (!_disabled && !_overlay_active && _mx >= _nb_x && _mx <= _nb_x + _nb_w && _my >= _by && _my <= _by + _nb_h);
        var _col_bg = _disabled ? make_color_rgb(42, 44, 52) : (_hov ? make_color_rgb(72, 88, 128) : make_color_rgb(55, 58, 75));
        var _col_bd = _disabled ? make_color_rgb(62, 65, 76) : (_hov ? make_color_rgb(130, 158, 210) : make_color_rgb(88, 95, 118));
        var _col_ar = _disabled ? make_color_rgb(78, 82, 92) : c_white;
        draw_set_color(_col_bg);
        draw_roundrect_ext(_nb_x, _by, _nb_x + _nb_w, _by + _nb_h, 4, 4, false);
        draw_set_color(_col_bd);
        draw_roundrect_ext(_nb_x, _by, _nb_x + _nb_w, _by + _nb_h, 4, 4, true);
        var _cx = _nb_x + _nb_w / 2;
        var _cy = _by + _nb_h / 2;
        draw_set_color(_col_ar);
        if (_bi == 0) {
            // Home: two upward triangles
            draw_triangle(_cx, _cy-7, _cx-5, _cy-1, _cx+5, _cy-1, false);
            draw_triangle(_cx, _cy+1, _cx-5, _cy+7, _cx+5, _cy+7, false);
        } else if (_bi == 1) {
            // Page up: one upward triangle
            draw_triangle(_cx, _cy-5, _cx-6, _cy+4, _cx+6, _cy+4, false);
        } else if (_bi == 2) {
            // Page down: one downward triangle
            draw_triangle(_cx, _cy+5, _cx-6, _cy-4, _cx+6, _cy-4, false);
        } else {
            // End: two downward triangles
            draw_triangle(_cx, _cy-1, _cx-5, _cy-7, _cx+5, _cy-7, false);
            draw_triangle(_cx, _cy+7, _cx-5, _cy+1, _cx+5, _cy+1, false);
        }
    }
}

// --- 5b. BOTTOM CONTROLS ---
var _p_dis = script_expanded;
var _p_hov = (!_p_dis && !_overlay_active && _mx > btn_play_x && _mx < btn_play_x+btn_play_w && _my > btn_play_y && _my < btn_play_y+btn_play_h);
var _is_playing = (playing_block_index != -1);
draw_set_color(_p_dis ? make_color_rgb(30,50,32) : (_is_playing ? (_p_hov ? make_color_rgb(200,60,60) : make_color_rgb(160,38,38)) : (_p_hov ? make_color_rgb(45,175,70) : make_color_rgb(25,140,50))));
draw_roundrect_ext(btn_play_x, btn_play_y, btn_play_x+btn_play_w, btn_play_y+btn_play_h, 5, 5, false);
draw_set_color(_p_dis ? make_color_rgb(55,70,56) : (_is_playing ? (_p_hov ? c_white : make_color_rgb(235,100,100)) : (_p_hov ? c_white : make_color_rgb(75,215,105))));
draw_roundrect_ext(btn_play_x, btn_play_y, btn_play_x+btn_play_w, btn_play_y+btn_play_h, 5, 5, true);
draw_set_color(_p_dis ? make_color_rgb(70,85,70) : c_white); draw_set_halign(fa_center); draw_text(btn_play_x+btn_play_w/2, btn_play_y+10, _is_playing ? "STOP" : "PLAY"); draw_set_halign(fa_left);

// ENTER THEATER Button
var _thov = (!_overlay_active && playing_block_index == -1 && _mx > btn_theater_x && _mx < btn_theater_x+btn_theater_w && _my > btn_theater_y && _my < btn_theater_y+btn_theater_h);
var _t_dis = (playing_block_index != -1);
draw_set_color(_t_dis ? make_color_rgb(28,40,62) : (_thov ? make_color_rgb(25,78,192) : make_color_rgb(16,55,158)));
draw_roundrect_ext(btn_theater_x, btn_theater_y, btn_theater_x+btn_theater_w, btn_theater_y+btn_theater_h, 5, 5, false);
draw_set_color(_t_dis ? make_color_rgb(52,65,95) : (_thov ? c_white : make_color_rgb(196,213,20)));
draw_roundrect_ext(btn_theater_x, btn_theater_y, btn_theater_x+btn_theater_w, btn_theater_y+btn_theater_h, 5, 5, true);
draw_set_color(c_white); draw_set_halign(fa_center); draw_text(btn_theater_x+(btn_theater_w/2), btn_theater_y+10, "ENTER THEATER"); draw_set_halign(fa_left);

// --- POSE, EXPRESSION & VOICE CONTROLS ---
if (!script_expanded) {
// Footer panel that visually connects to the character selector above
var _fp_y = char_sel_y + char_sel_h;
var _fp_h = (btn_pose_y + btn_pose_h) - _fp_y;
draw_set_color(make_color_rgb(10, 40, 15));
draw_rectangle(char_sel_x, _fp_y, char_sel_x + char_sel_w, _fp_y + _fp_h, false);
draw_set_color(make_color_rgb(196, 213, 20));
draw_line(char_sel_x,               _fp_y, char_sel_x,               _fp_y + _fp_h);
draw_line(char_sel_x + char_sel_w,  _fp_y, char_sel_x + char_sel_w,  _fp_y + _fp_h);
draw_line(char_sel_x, _fp_y + _fp_h, char_sel_x + char_sel_w, _fp_y + _fp_h);

var _is_narrator = (characters[selected_character_index].name == "NARRATOR");
var _foc_particle = particle_edit_mode || (focused_block != -1 && focused_block < array_length(script_blocks) && variable_struct_exists(script_blocks[focused_block], "type") && script_blocks[focused_block].type == "particle");
var _pe_btn_w = btn_expression_x + btn_expression_w - btn_pose_x;
var _phov = (!_is_narrator && !_foc_particle && !_overlay_active && playing_block_index == -1 && _mx > btn_pose_x && _mx < btn_pose_x + _pe_btn_w && _my > btn_pose_y && _my < btn_pose_y + btn_pose_h);
var _evhov = (!_foc_particle && !_overlay_active && playing_block_index == -1 && _mx > btn_edit_x && _mx < btn_edit_x + btn_edit_w && _my > btn_edit_y && _my < btn_edit_y + btn_edit_h);

// RENDER POSE / EXPRESSION COMBINED BUTTON
var _pe_dis = (_is_narrator || playing_block_index != -1 || _foc_particle);
draw_set_color(_pe_dis ? make_color_rgb(28,42,30) : (_phov ? make_color_rgb(20,72,168) : make_color_rgb(14,52,145)));
draw_roundrect_ext(btn_pose_x, btn_pose_y, btn_pose_x+_pe_btn_w, btn_pose_y+btn_pose_h, 5, 5, false);
draw_set_color(_pe_dis ? make_color_rgb(52,65,54) : (_phov ? c_white : make_color_rgb(196,213,20)));
draw_roundrect_ext(btn_pose_x, btn_pose_y, btn_pose_x+_pe_btn_w, btn_pose_y+btn_pose_h, 5, 5, true);
draw_set_color(_pe_dis ? make_color_rgb(110,110,120) : c_white); draw_set_halign(fa_center);
draw_text(btn_pose_x+_pe_btn_w/2, btn_pose_y+10, "POSE / EXPRESSION");
draw_set_halign(fa_left);

// RENDER VOICE BUTTON (amber — distinct from the green +VOICE add button)
var _ev_dis = (playing_block_index != -1 || _foc_particle);
draw_set_color(_ev_dis ? make_color_rgb(45,35,20) : (_evhov ? make_color_rgb(145,75,10) : make_color_rgb(100,52,8)));
draw_roundrect_ext(btn_edit_x, btn_edit_y, btn_edit_x+btn_edit_w, btn_edit_y+btn_edit_h, 5, 5, false);
draw_set_color(_ev_dis ? make_color_rgb(80,68,50) : (_evhov ? c_white : make_color_rgb(220,150,55)));
draw_roundrect_ext(btn_edit_x, btn_edit_y, btn_edit_x+btn_edit_w, btn_edit_y+btn_edit_h, 5, 5, true);
draw_set_color(_ev_dis ? make_color_rgb(120,110,90) : c_white); draw_set_halign(fa_center);
draw_text(btn_edit_x+btn_edit_w/2, btn_edit_y+10, "VOICE");
draw_set_halign(fa_left);

draw_set_color(make_color_rgb(8, 32, 12)); draw_rectangle(dropdown_x, dropdown_y, dropdown_x + dropdown_w, dropdown_y + dropdown_h, false);
draw_set_color(make_color_rgb(196, 213, 20)); draw_rectangle(dropdown_x, dropdown_y, dropdown_x + dropdown_w, dropdown_y + dropdown_h, true);
draw_set_color(c_white); draw_text(dropdown_x + 10, dropdown_y + 5, characters[selected_character_index].name);
} // end if (!script_expanded) — side panels

// --- 6. MODALS ---
// Nearest-neighbour rendering for all modal UI — prevents fuzzy text on bright headers.
// draw_composite_character_ext saves/restores its own filter state, so this is safe.
gpu_set_texfilter(false);
if (dictionary_open) {
    draw_set_color(c_black); draw_set_alpha(0.8); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _m_w = 700; var _m_h = 500; var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    draw_set_color(make_color_rgb(14, 48, 20)); draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 14, 14, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + 52, 14, 14, false);
    draw_rectangle(_m_x, _m_y + 32, _m_x + _m_w, _m_y + 52, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 14, 14, true);
    draw_set_color(c_black); draw_text(_m_x + 20, _m_y + 18, "PRONUNCIATION DICTIONARY");
    draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_m_x + 20, _m_y + 58, "Written Word"); draw_text(_m_x + 280, _m_y + 58, "Pronunciation");

    gpu_set_scissor(_m_x + 10, _m_y + 80, _m_w - 20, 320);
    for (var i = 0; i < array_length(dictionary_list); i++) {
        var _ey = _m_y + 80 + (i * 45) + dictionary_scroll_y;
        var _entry = dictionary_list[i];
        
        // Column 1: Written
        draw_set_color((dict_focused_entry == i && dict_focused_field == 0) ? c_white : make_color_rgb(225, 240, 228));
        draw_roundrect_ext(_m_x + 20, _ey, _m_x + 260, _ey + 35, 5, 5, false);
        draw_set_color(c_black); draw_text(_m_x + 25, _ey + 8, _entry.written);
        if (dict_focused_entry == i && dict_focused_field == 0 && cursor_visible) {
            var _cx = string_width(string_copy(_entry.written, 1, dict_caret_pos));
            draw_set_color(c_blue);
            draw_line_width(_m_x + 25 + _cx, _ey + 5, _m_x + 25 + _cx, _ey + 30, 2);
        }

        // Column 2: Pronunciation
        draw_set_color((dict_focused_entry == i && dict_focused_field == 1) ? c_white : make_color_rgb(225, 240, 228));
        draw_roundrect_ext(_m_x + 280, _ey, _m_x + 520, _ey + 35, 5, 5, false);
        draw_set_color(c_black); draw_text(_m_x + 285, _ey + 8, _entry.pronunciation);
        if (dict_focused_entry == i && dict_focused_field == 1 && cursor_visible) {
            var _cx = string_width(string_copy(_entry.pronunciation, 1, dict_caret_pos));
            draw_set_color(c_blue);
            draw_line_width(_m_x + 285 + _cx, _ey + 5, _m_x + 285 + _cx, _ey + 30, 2);
        }
        
        // Test Button
        var _test_hov = (_mx > _m_x + 540 && _mx < _m_x + 610 && _my > _ey && _my < _ey + 35);
        draw_set_color(_test_hov ? make_color_rgb(20, 105, 32) : make_color_rgb(14, 70, 22));
        draw_roundrect_ext(_m_x + 540, _ey, _m_x + 610, _ey + 35, 5, 5, false);
        draw_set_color(_test_hov ? c_white : make_color_rgb(196, 213, 20));
        draw_roundrect_ext(_m_x + 540, _ey, _m_x + 610, _ey + 35, 5, 5, true);
        draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_m_x + 575, _ey + 8, "TEST"); draw_set_halign(fa_left);

        // Remove Button
        var _rhov = (_mx > _m_x + 630 && _mx < _m_x + 670 && _my > _ey && _my < _ey + 35);
        draw_set_color(_rhov ? make_color_rgb(210, 50, 50) : make_color_rgb(155, 28, 28));
        draw_roundrect_ext(_m_x + 630, _ey, _m_x + 670, _ey + 35, 5, 5, false);
        draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_m_x + 650, _ey + 8, "X"); draw_set_halign(fa_left);
    }
    gpu_set_scissor(0, 0, 1280, 960);

    // Dictionary Scrollbar
    var _dict_total_h = array_length(dictionary_list) * 45;
    var _dict_view_h = 320;
    if (_dict_total_h > _dict_view_h) {
        _sb_w = 8; _sb_x = _m_x + _m_w - 22;
        var _sb_y = _m_y + 80; var _sb_h = _dict_view_h;
        draw_set_color(make_color_rgb(8, 30, 12));
        draw_rectangle(_sb_x, _sb_y, _sb_x + _sb_w, _sb_y + _sb_h, false); // Track
        var _bar_h = (_dict_view_h / _dict_total_h) * _sb_h;
        var _bar_y = _sb_y + (-dictionary_scroll_y / _dict_total_h) * _sb_h;
        draw_set_color(make_color_rgb(155, 170, 38));
        draw_rectangle(_sb_x, _bar_y, _sb_x + _sb_w, _bar_y + _bar_h, false); // Handle
    }
    
    // Add Button
    var _ahov = (_mx > _m_x + 20 && _mx < _m_x + 150 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20);
    draw_set_color(_ahov ? make_color_rgb(22, 105, 32) : make_color_rgb(14, 70, 22));
    draw_roundrect_ext(_m_x + 20, _m_y + _m_h - 60, _m_x + 150, _m_y + _m_h - 20, 7, 7, false);
    draw_set_color(_ahov ? c_white : make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_m_x + 20, _m_y + _m_h - 60, _m_x + 150, _m_y + _m_h - 20, 7, 7, true);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_m_x + 85, _m_y + _m_h - 50, "ADD ENTRY"); draw_set_halign(fa_left);

    // Close Button
    var _chov = (_mx > _m_x + _m_w - 140 && _mx < _m_x + _m_w - 20 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20);
    draw_set_color(_chov ? make_color_rgb(190, 40, 40) : make_color_rgb(140, 22, 22));
    draw_roundrect_ext(_m_x + _m_w - 140, _m_y + _m_h - 60, _m_x + _m_w - 20, _m_y + _m_h - 20, 7, 7, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_m_x + _m_w - 80, _m_y + _m_h - 50, "CLOSE"); draw_set_halign(fa_left);
}

if (edit_mode) {
    draw_set_color(c_black); draw_set_alpha(0.85); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _mw = 800; var _mh = 700; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    draw_set_color(make_color_rgb(14, 48, 20)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 14, 14, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+56, 14, 14, false);
    draw_rectangle(_mxo, _myo+36, _mxo+_mw, _myo+56, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 14, 14, true);
    draw_set_color(c_black); draw_text(_mxo+28, _myo+19, modal_is_local_edit ? "ALTER VOICE — THIS BLOCK ONLY" : "VOICE STUDIO");
    
    var _cols = 4; var _bw = 170; var _bh = 45; var _gx = (_mw - (_cols * (_bw + 15))) / 2;
    for (var i = 0; i < array_length(all_voices); i++) {
        var _bx = _mxo + _gx + ((i % _cols) * (_bw + 15));
        var _by = _myo + 70 + (floor(i / _cols) * (_bh + 8));
        var _is_sel = (all_voices[i].voice_id == modal_voice_id);
        var _v_hov = (_mx > _bx && _mx < _bx + _bw && _my > _by && _my < _by + _bh);
        draw_set_color(_is_sel ? make_color_rgb(16, 58, 155) : (_v_hov ? make_color_rgb(20, 78, 30) : make_color_rgb(10, 42, 16)));
        draw_roundrect_ext(_bx, _by, _bx + _bw, _by + _bh, 8, 8, false);
        if (_is_sel) { draw_set_color(make_color_rgb(196, 213, 20)); draw_roundrect_ext(_bx, _by, _bx + _bw, _by + _bh, 8, 8, true); }
        draw_set_color(c_white); var _ns = all_voices[i].name; if (string_length(_ns) > 22) _ns = string_copy(_ns, 1, 20) + "..";
        draw_text(_bx + 10, _by + 13, _ns);
    }
    // --- Volume Slider (vertical, lower-right) ---
    var _vsl_cx = _mxo + 680;
    var _vsl_top = _myo + 370; var _vsl_bot = _myo + 570; var _vsl_h = _vsl_bot - _vsl_top;
    var _vsl_thumb_y = _vsl_top + (1 - modal_volume / 100.0) * _vsl_h;
    var _vsl_hov = (_mx > _vsl_cx-18 && _mx < _vsl_cx+18 && _my > _vsl_top-10 && _my < _vsl_bot+10);
    draw_set_halign(fa_center);
    draw_set_color(make_color_rgb(160, 160, 160)); draw_text(_vsl_cx, _myo+352, "VOL");
    draw_set_color(make_color_rgb(40, 55, 42)); draw_rectangle(_vsl_cx-5, _vsl_top, _vsl_cx+5, _vsl_bot, false);
    draw_set_color(slider_drag==4 ? make_color_rgb(100, 220, 120) : make_color_rgb(60, 160, 80));
    draw_rectangle(_vsl_cx-5, _vsl_thumb_y, _vsl_cx+5, _vsl_bot, false);
    draw_set_color(c_white); draw_circle(_vsl_cx, _vsl_thumb_y, 10, false);
    draw_set_color(slider_drag==4 ? make_color_rgb(100, 220, 120) : (_vsl_hov ? make_color_rgb(120, 200, 130) : make_color_rgb(60, 160, 80)));
    draw_circle(_vsl_cx, _vsl_thumb_y, 7, false);
    var _vol_db = round((modal_volume / 50.0 - 1.0) * 20);
    draw_set_color(make_color_rgb(160, 160, 160));
    draw_text(_vsl_cx, _vsl_bot+8,  string(round(modal_volume)));
    draw_text(_vsl_cx, _vsl_bot+22, (_vol_db >= 0 ? "+" : "") + string(_vol_db) + "dB");
    draw_set_halign(fa_left);

    // --- Tweak Toggle ---
    var _toggle_y = _myo + 610;
    var _twk_hov = (_mx > _mxo+50 && _mx < _mxo+350 && _my > _toggle_y && _my < _toggle_y+25);
    draw_set_color(_twk_hov ? c_white : c_ltgray);
    draw_rectangle(_mxo+50, _toggle_y, _mxo+70, _toggle_y+20, true); // checkbox outline
    if (tweak_enabled) { draw_set_color(c_lime); draw_rectangle(_mxo+54, _toggle_y+4, _mxo+66, _toggle_y+16, false); }
    draw_set_color(c_white); draw_text(_mxo+80, _toggle_y+2, "Advanced Voice Tweaks");

    // --- Tweak Controls (only when enabled) ---
    if (tweak_enabled) {
        var _ctrl_y = _myo + 360;
        
        // Pitch
        var _p_x = _mxo+180 + (modal_pitch/100)*300;
        _p_hov = (_mx > _mxo+180 && _mx < _mxo+480 && _my > _ctrl_y-5 && _my < _ctrl_y+25);
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+2, "Pitch:");
        draw_set_color(_p_hov || slider_drag==1 ? make_color_rgb(80,80,110) : make_color_rgb(60,60,80));
        draw_rectangle(_mxo+180, _ctrl_y+2, _mxo+480, _ctrl_y+18, false);
        draw_set_color(slider_drag==1 ? make_color_rgb(130,130,255) : make_color_rgb(100,100,255));
        draw_rectangle(_mxo+180, _ctrl_y+2, _p_x, _ctrl_y+18, false);
        draw_set_color(c_white); draw_circle(_p_x, _ctrl_y+10, 9, false);
        draw_set_color(slider_drag==1 ? make_color_rgb(130,130,255) : make_color_rgb(80,80,220)); draw_circle(_p_x, _ctrl_y+10, 6, false);
        draw_set_color(c_white); draw_text(_mxo+155, _ctrl_y+2, "<"); draw_text(_mxo+485, _ctrl_y+2, ">");
        draw_text(_mxo+520, _ctrl_y+2, string(round(modal_pitch)));

        // Speed
        var _s_x = _mxo+180 + (modal_speed/100)*300;
        var _s_hov = (_mx > _mxo+180 && _mx < _mxo+480 && _my > _ctrl_y+45 && _my < _ctrl_y+75);
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+52, "Speed:");
        draw_set_color(_s_hov || slider_drag==2 ? make_color_rgb(50,90,50) : make_color_rgb(40,65,40));
        draw_rectangle(_mxo+180, _ctrl_y+52, _mxo+480, _ctrl_y+68, false);
        draw_set_color(slider_drag==2 ? make_color_rgb(130,255,130) : make_color_rgb(100,255,100));
        draw_rectangle(_mxo+180, _ctrl_y+52, _s_x, _ctrl_y+68, false);
        draw_set_color(c_white); draw_circle(_s_x, _ctrl_y+60, 9, false);
        draw_set_color(slider_drag==2 ? make_color_rgb(130,255,130) : make_color_rgb(60,200,60)); draw_circle(_s_x, _ctrl_y+60, 6, false);
        draw_set_color(c_white); draw_text(_mxo+155, _ctrl_y+52, "<"); draw_text(_mxo+485, _ctrl_y+52, ">");
        draw_text(_mxo+520, _ctrl_y+52, string(round(modal_speed)));

        // Quality radio buttons
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+93, "Quality:");
        var _q_labels = ["Normal", "Monotone", "Sung"]; var _q_vals = [0, 2, 4];
        for (var e = 0; e < 3; e++) {
            var _ex = _mxo+195+(e*105);
            var _q_sel = (modal_quality == _q_vals[e]);
            var _q_hov = (point_distance(_mx, _my, _ex, _ctrl_y+108) < 16);
            draw_set_color(_q_sel ? c_lime : (_q_hov ? make_color_rgb(180, 220, 180) : make_color_rgb(90, 90, 90)));
            draw_circle(_ex, _ctrl_y+108, 10, true);
            if (_q_sel) { draw_set_color(make_color_rgb(30, 80, 30)); draw_circle(_ex, _ctrl_y+108, 6, false); }
            draw_set_halign(fa_center);
            draw_set_color(_q_sel ? c_white : (_q_hov ? c_white : make_color_rgb(180, 180, 180)));
            draw_text(_ex, _ctrl_y+121, _q_labels[e]);
            draw_set_halign(fa_left);
        }

        // Effort radio buttons
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+143, "Effort:");
        var _s_labels = ["Normal", "Breathy", "Whispered"];
        var _s_hov = false;
        for (var s = 0; s < 3; s++) {
            var _sx = _mxo+195+(s*105);
            var _s_sel = (modal_effort == s);
            _s_hov = (point_distance(_mx, _my, _sx, _ctrl_y+158) < 16);
            draw_set_color(_s_sel ? c_lime : (_s_hov ? make_color_rgb(180, 220, 180) : make_color_rgb(90, 90, 90)));
            draw_circle(_sx, _ctrl_y+158, 10, true);
            if (_s_sel) { draw_set_color(make_color_rgb(30, 80, 30)); draw_circle(_sx, _ctrl_y+158, 6, false); }
            draw_set_halign(fa_center);
            draw_set_color(_s_sel ? c_white : (_s_hov ? c_white : make_color_rgb(180, 180, 180)));
            draw_text(_sx, _ctrl_y+171, _s_labels[s]);
            draw_set_halign(fa_left);
        }

        // Glottal source slider (-1 to 5)
        var _g_y = _ctrl_y + 193;
        var _g_val = clamp(modal_glottal, -1, 5);
        var _g_x = _mxo+180 + ((_g_val + 1) / 6.0) * 300;
        var _g_hov = (_mx > _mxo+180 && _mx < _mxo+480 && _my > _g_y-5 && _my < _g_y+25);
        draw_set_color(c_white); draw_text(_mxo+50, _g_y+2, "Timbre:");
        draw_set_color(make_color_rgb(130, 130, 130)); draw_text(_mxo+50, _g_y+16, "(5 recommended)");
        draw_set_color(_g_hov || slider_drag==3 ? make_color_rgb(90,55,10) : make_color_rgb(60,38,8));
        draw_rectangle(_mxo+180, _g_y+2, _mxo+480, _g_y+18, false);
        if (_g_val >= 0) {
            draw_set_color(slider_drag==3 ? make_color_rgb(255,175,70) : make_color_rgb(210,135,40));
            draw_rectangle(_mxo+180, _g_y+2, _g_x, _g_y+18, false);
        }
        draw_set_color(c_white); draw_circle(_g_x, _g_y+10, 9, false);
        draw_set_color(slider_drag==3 ? make_color_rgb(255,175,70) : make_color_rgb(210,135,40));
        draw_circle(_g_x, _g_y+10, 6, false);
        draw_set_color(c_white);
        draw_text(_mxo+155, _g_y+2, "<"); draw_text(_mxo+485, _g_y+2, ">");
        draw_text(_mxo+520, _g_y+2, (_g_val == -1) ? "off" : string(_g_val));
    }

    // --- Bottom Buttons ---
    var _btn_y = _myo + _mh - 60;

    // Revert (Only for local block edits)
    if (modal_is_local_edit) {
        var _rv_hov = (_mx > _mxo + 30 && _mx < _mxo + 150 && _my > _btn_y && _my < _btn_y + 40);
        draw_set_color(_rv_hov ? make_color_rgb(185, 130, 18) : make_color_rgb(140, 95, 10));
        draw_roundrect_ext(_mxo + 30, _btn_y, _mxo + 150, _btn_y + 40, 7, 7, false);
        draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_mxo + 90, _btn_y + 10, "REVERT"); draw_set_halign(fa_left);
    }

    // Test
    var _tx = modal_is_local_edit ? _mxo + 165 : _mxo + 30;
    var _t_hov = (_mx > _tx && _mx < _tx + 120 && _my > _btn_y && _my < _btn_y + 40);
    draw_set_color(_t_hov ? make_color_rgb(18, 72, 162) : make_color_rgb(12, 50, 140));
    draw_roundrect_ext(_tx, _btn_y, _tx + 120, _btn_y + 40, 7, 7, false);
    draw_set_color(_t_hov ? c_white : make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_tx, _btn_y, _tx + 120, _btn_y + 40, 7, 7, true);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_tx + 60, _btn_y + 10, "TEST"); draw_set_halign(fa_left);

    // Export Config (debug)
    if (SHOW_VOICE_CFG && !modal_is_local_edit) {
        var _ex_hov = (_mx > _mxo+_mw-430 && _mx < _mxo+_mw-295 && _my > _btn_y && _my < _btn_y+40);
        draw_set_color(_ex_hov ? make_color_rgb(100, 40, 160) : make_color_rgb(72, 25, 120));
        draw_roundrect_ext(_mxo+_mw-430, _btn_y, _mxo+_mw-295, _btn_y+40, 7, 7, false);
        draw_set_color(c_white);
        draw_set_halign(fa_center); draw_text(_mxo+_mw-362, _btn_y+10, "SAVE CONFIG"); draw_set_halign(fa_left);
    }

    // Save
    var _s_hov = (_mx > _mxo+_mw-280 && _mx < _mxo+_mw-150 && _my > _btn_y && _my < _btn_y+40);
    draw_set_color(_s_hov ? make_color_rgb(22, 110, 32) : make_color_rgb(14, 75, 22));
    draw_roundrect_ext(_mxo+_mw-280, _btn_y, _mxo+_mw-150, _btn_y+40, 7, 7, false);
    draw_set_color(_s_hov ? c_white : make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_mxo+_mw-280, _btn_y, _mxo+_mw-150, _btn_y+40, 7, 7, true);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_mxo+_mw-215, _btn_y+10, "SAVE"); draw_set_halign(fa_left);
    // Cancel
    var _c_hov = (_mx > _mxo+_mw-140 && _mx < _mxo+_mw-30 && _my > _btn_y && _my < _btn_y+40);
    draw_set_color(_c_hov ? make_color_rgb(200,40,40) : make_color_rgb(148,22,22));
    draw_roundrect_ext(_mxo+_mw-140, _btn_y, _mxo+_mw-30, _btn_y+40, 7, 7, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_mxo+_mw-85, _btn_y+10, "CANCEL"); draw_set_halign(fa_left);

}

if (scene_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _mw = 700; var _mh = 450; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    draw_set_color(make_color_rgb(14, 48, 20)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 12, 12, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+52, 12, 12, false);
    draw_rectangle(_mxo, _myo+32, _mxo+_mw, _myo+52, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 12, 12, true);
    draw_set_color(c_black); draw_text(_mxo+20, _myo+18, "SELECT SCENE");
    
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
        draw_set_color(_hov ? make_color_rgb(18, 65, 25) : make_color_rgb(10, 40, 15));
        draw_roundrect_ext(_mxo+20, _by, _mxo+20+_lw, _by+35, 5, 5, false);
        draw_set_color(c_white); draw_text(_mxo+30, _by+8, all_scenes[i].name);
    }
    gpu_set_scissor(0,0,1280,960);
    
    // Scrollbar for Scene Modal
    if (_list_h > _max_h) {
        var _bar_h = max(20, (_max_h / _list_h) * _max_h);
        var _sb_max_top = (_myo+60) + _max_h - _bar_h;
        var _bar_y = clamp((_myo+60) + (-scene_modal_scroll_y / _list_h) * _max_h, _myo+60, _sb_max_top);
        var _bar_hov = (_mx >= _mxo+20+_lw+3 && _mx <= _mxo+20+_lw+17 && _my >= _bar_y && _my <= _bar_y + _bar_h);
        draw_set_color(make_color_rgb(8, 30, 12));
        draw_rectangle(_mxo+20+_lw+5, _myo+60, _mxo+20+_lw+15, _myo+60+_max_h, false); // Track
        draw_set_color(scene_sb_dragging ? make_color_rgb(215, 232, 85) : (_bar_hov ? make_color_rgb(185, 205, 60) : make_color_rgb(148, 162, 35)));
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
	draw_set_color(_can_hov ? make_color_rgb(200,40,40) : make_color_rgb(148,22,22));
	draw_roundrect_ext(_mxo+20, _c_y, _mxo+_mw-20, _c_y+35, 7, 7, false);
	draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_mxo+_mw/2, _c_y+8, "CANCEL"); draw_set_halign(fa_left);
}

if (action_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _mw = 900; var _mh = 550; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    draw_set_color(make_color_rgb(14, 48, 20)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 12, 12, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+52, 12, 12, false);
    draw_rectangle(_mxo, _myo+32, _mxo+_mw, _myo+52, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 12, 12, true);
    draw_set_color(c_black); draw_text(_mxo+20, _myo+18, "ADD ACTION");
    draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_mxo + 20, _myo + 58, "GENERAL ACTIONS");
    draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_mxo + 20, _myo + 78, _mxo + 250, _myo + 78);

    var _char_header_drawn = false;
    for (var i = 0; i < array_length(all_actions); i++) {
        var _is_gen = (all_actions[i].category == "general");
        var _ng = 0; var _nc = 0;
        for (var _k = 0; _k < i; _k++) { if (all_actions[_k].category == "general") _ng++; else _nc++; }
        var _by = _myo + 85 + (_ng * 45) + (!_is_gen ? 50 : 0) + (_nc * 45);

        if (!_is_gen && !_char_header_drawn) {
            _char_header_drawn = true;
            draw_set_color(make_color_rgb(196, 213, 20));
            draw_text(_mxo + 20, _by - 38, "CHARACTER ACTIONS");
            draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_mxo + 20, _by - 14, _mxo + 250, _by - 14);
        }

        var _disabled = false;
        if (action_modal_edit_mode) {
            if (action_modal_selected_idx != i) _disabled = true;
        } else if (!_is_gen) {
            var _aname_i = all_actions[i].name;
            if (selected_character_index == 0) _disabled = true;
            else if (_aname_i == "resurrect") {
                if (!action_modal_char_is_dead) _disabled = true;
            } else if (!action_modal_char_onstage) _disabled = true;
            else if (_aname_i == "kill" && action_modal_char_is_dead) _disabled = true;
            else if (_aname_i != "kill" && action_modal_char_is_dead) _disabled = true;
        }

        var _hov = (!_disabled && _mx > _mxo+20 && _mx < _mxo+250 && _my > _by && _my < _by+40);
        var _col = make_color_rgb(10, 40, 15);
        if (_disabled) _col = make_color_rgb(8, 28, 10);
        else if (action_modal_selected_idx == i) _col = make_color_rgb(16, 55, 148);
        else if (_hov) _col = make_color_rgb(18, 68, 24);

        draw_set_color(_col);
        draw_roundrect_ext(_mxo+20, _by, _mxo+250, _by+40, 5, 5, false);
        if (action_modal_selected_idx == i) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_mxo+20, _by, _mxo+250, _by+40, 5, 5, true); }
        draw_set_color(_disabled ? make_color_rgb(70,90,72) : c_white); draw_text(_mxo+30, _by+10, string_upper(all_actions[i].name));
    }

    // OK / Cancel Buttons
    var _can_proceed = true;
    if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "play sfx") {
        if ((action_modal_sfx_folder_idx == -1 || action_modal_sfx_file_idx == -1) && action_modal_sfx_search_sel == -1) _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "display title") {
        if (action_modal_title_text == "") _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "quake") {
        // always valid — general action
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "jitter") {
        if (selected_character_index == 0 || !action_modal_char_onstage) _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "disappear") {
        if (selected_character_index == 0 || !action_modal_char_onstage) _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "kill") {
        if (selected_character_index == 0 || !action_modal_char_onstage || action_modal_char_is_dead) _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "resurrect") {
        if (selected_character_index == 0 || !action_modal_char_is_dead) _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "special animation") {
        _can_proceed = (action_modal_selected_anim_idx >= 0 && action_modal_char_onstage && !action_modal_char_is_dead && selected_character_index > 0);
    } else if (action_modal_selected_idx == -1) {
        _can_proceed = false;
    }

    var _ok_locked = (action_modal_locked && _can_proceed);
    var _ok_hov = (_ok_locked && _mx > _mxo+_mw-280 && _mx < _mxo+_mw-150 && _my > _myo+_mh-50 && _my < _myo+_mh-15);
    draw_set_color(_ok_locked ? (_ok_hov ? make_color_rgb(22,110,32) : make_color_rgb(14,75,22)) : make_color_rgb(28,45,30));
    draw_roundrect_ext(_mxo+_mw-280, _myo+_mh-50, _mxo+_mw-150, _myo+_mh-15, 7, 7, false);
    draw_set_color(_ok_locked ? make_color_rgb(196,213,20) : make_color_rgb(55,78,57));
    draw_roundrect_ext(_mxo+_mw-280, _myo+_mh-50, _mxo+_mw-150, _myo+_mh-15, 7, 7, true);
    draw_set_color(_ok_locked ? c_white : make_color_rgb(80,100,82));
    draw_set_halign(fa_center); draw_text(_mxo+_mw-215, _myo+_mh-42, "OK"); draw_set_halign(fa_left);

    var _can_hov = (_mx > _mxo+_mw-130 && _mx < _mxo+_mw-20 && _my > _myo+_mh-50 && _my < _myo+_mh-15);
    draw_set_color(_can_hov ? make_color_rgb(200,40,40) : make_color_rgb(148,22,22));
    draw_roundrect_ext(_mxo+_mw-130, _myo+_mh-50, _mxo+_mw-20, _myo+_mh-15, 7, 7, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_mxo+_mw-75, _myo+_mh-42, "CANCEL"); draw_set_halign(fa_left);

    // Description Box
    draw_set_color(make_color_rgb(10, 38, 14));
    draw_roundrect_ext(_mxo+280, _myo+60, _mxo+880, _myo+480, 8, 8, false);
    if (action_modal_selected_idx != -1) {
        draw_set_color(c_white);
        draw_text_ext(_mxo+290, _myo+70, all_actions[action_modal_selected_idx].desc, 25, 580);
        
        if (all_actions[action_modal_selected_idx].name == "wait") {
            var _wx = _mxo + 320; var _wy = _myo + 170;
            var _sw = 400;
            
            draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_wx, _wy, "PARAMETERS");
            draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_wx, _wy + 25, _wx + _sw + 80, _wy + 25);
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
            draw_set_color(make_color_rgb(15, 55, 20));
            draw_rectangle(_wx + 30, _ty + 8, _wx + 30 + _sw, _ty + 13, false);

            // Slider Handle
            var _perc = (action_modal_wait_duration - 0.1) / 9.9;
            var _hx = _wx + 30 + (_perc * _sw);
            draw_set_color(make_color_rgb(196, 213, 20)); draw_rectangle(_wx + 30, _ty + 8, _hx, _ty + 13, false);
            draw_set_color(make_color_rgb(196, 213, 20));
            draw_circle(_hx, _ty + 10, 8, false);
            
            draw_set_color(c_white);
            draw_text(_wx + 20, _wy + 115, string(action_modal_wait_duration) + " seconds");
        } else if (all_actions[action_modal_selected_idx].name == "play sfx") {
            var _wx = _mxo + 300; var _wy = _myo + 130;

            draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_wx, _wy, "PARAMETERS");
            draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_wx, _wy + 25, _wx + 560, _wy + 25);

            var _fx = _mxo + 280;
            var _lx = _mxo + 550;

            // SEARCH BOX — sits between separator and the category/file columns
            var _srx = _fx + 10; var _sry = _wy + 30; var _srw = 560; var _srh = 24;
            var _sr_focused = action_modal_sfx_search_focused;
            draw_set_color(_sr_focused ? make_color_rgb(40, 40, 70) : make_color_rgb(20, 20, 30));
            draw_rectangle(_srx, _sry, _srx + _srw, _sry + _srh, false);
            draw_set_color(_sr_focused ? c_yellow : c_ltgray);
            draw_rectangle(_srx, _sry, _srx + _srw, _sry + _srh, true);
            var _sq = action_modal_sfx_search;
            var _sq_disp = (_sq == "") ? "Search..." : (string_upper(_sq) + (_sr_focused ? "|" : ""));
            draw_set_color((_sq == "") ? make_color_rgb(80, 80, 100) : c_white);
            draw_text(_srx + 6, _sry + 4, _sq_disp);
            if (_sq != "") {
                var _cx_hov = (_mx > _srx + _srw - 22 && _mx < _srx + _srw && _my > _sry && _my < _sry + _srh);
                draw_set_color(_cx_hov ? c_white : make_color_rgb(180, 80, 80));
                draw_text(_srx + _srw - 18, _sry + 4, "X");
            }

            // ACTOR FOLDERS CHECKBOX
            var _chk_x = _fx + 10; var _chk_y = _wy + 60;
            var _chk_hov = (_mx > _chk_x && _mx < _chk_x + 200 && _my > _chk_y && _my < _chk_y + 18);
            draw_set_color(_chk_hov ? make_color_rgb(38, 55, 22) : make_color_rgb(18, 30, 10));
            draw_rectangle(_chk_x, _chk_y + 2, _chk_x + 13, _chk_y + 15, false);
            draw_set_color(action_modal_sfx_show_actors ? make_color_rgb(148, 162, 35) : make_color_rgb(70, 85, 30));
            draw_rectangle(_chk_x, _chk_y + 2, _chk_x + 13, _chk_y + 15, true);
            if (action_modal_sfx_show_actors) {
                draw_set_color(c_yellow);
                draw_set_halign(fa_center);
                draw_text(_chk_x + 7, _chk_y + 2, "X");
                draw_set_halign(fa_left);
            }
            draw_set_color(_chk_hov ? c_white : make_color_rgb(160, 175, 100));
            draw_text(_chk_x + 18, _chk_y + 1, "SHOW ACTOR FOLDERS");

            var _boxy = _wy + 100; var _boxh = 185;
            var _boxy2 = _boxy + _boxh;

            if (action_modal_sfx_search != "") {
                // SEARCH RESULTS — full-width single list
                var _rc = array_length(action_modal_sfx_search_results);
                draw_set_color(c_white); draw_text(_fx + 10, _boxy - 20, "Results (" + string(_rc) + "):");
                draw_set_color(make_color_rgb(10, 38, 14)); draw_roundrect_ext(_fx + 10, _boxy, _fx + 580, _boxy2, 5, 5, false);
                gpu_set_scissor(_fx + 10, _boxy, 570, _boxh);
                for (var f = 0; f < _rc; f++) {
                    var _res = action_modal_sfx_search_results[f];
                    var _rby = _boxy + (f * 28) - action_modal_sfx_search_scroll_y;
                    if (_rby + 28 > _boxy2 || _rby < _boxy) continue;
                    var _is_sel = (action_modal_sfx_search_sel == f);
                    var _r_hov = (_mx > _fx + 10 && _mx < _fx + 578 && _my > _rby && _my < _rby + 28 && _my > _boxy && _my < _boxy2);
                    draw_set_color(_is_sel ? make_color_rgb(16, 55, 148) : (_r_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 38, 14)));
                    draw_rectangle(_fx + 10, _rby, _fx + 580, _rby + 28, false);
                    draw_set_color(make_color_rgb(120, 120, 160)); draw_text(_fx + 15, _rby + 6, string_upper(_res.folder) + " /");
                    draw_set_color(_is_sel ? c_white : c_ltgray);
                    draw_text(_fx + 15 + string_width(string_upper(_res.folder) + " /") + 6, _rby + 6, string_replace(string_upper(_res.file), ".WAV", ""));
                }
                gpu_set_scissor(0, 0, 1280, 960);
                // Scrollbar
                var _rtot = _rc * 28;
                if (_rtot > _boxh) {
                    _sb_x = _fx + 572;
                    draw_set_color(make_color_rgb(8, 28, 12)); draw_rectangle(_sb_x, _boxy, _sb_x + 8, _boxy2, false);
                    var _bar_h = (_boxh / _rtot) * _boxh;
                    var _bar_y = _boxy + (action_modal_sfx_search_scroll_y / _rtot) * _boxh;
                    draw_set_color(make_color_rgb(148, 162, 35)); draw_rectangle(_sb_x, _bar_y, _sb_x + 8, _bar_y + _bar_h, false);
                }
            } else {
                // FOLDERS
                draw_set_color(c_white); draw_text(_fx + 10, _boxy - 20, "Category:");
                draw_set_color(make_color_rgb(10, 38, 14)); draw_roundrect_ext(_fx + 10, _boxy, _fx + 240, _boxy2, 5, 5, false);
                gpu_set_scissor(_fx + 10, _boxy, 230, _boxh);
                for (var f = 0; f < array_length(action_modal_sfx_folders); f++) {
                    var _fby = _boxy + (f * 30) - action_modal_sfx_scroll_y;
                    if (_fby + 30 > _boxy2 || _fby < _boxy) continue;
                    var _is_sel = (action_modal_sfx_folder_idx == f);
                    var _f_hov = (!action_modal_sfx_dragging_folder && _mx > _fx + 10 && _mx < _fx + 230 && _my > _fby && _my < _fby + 30 && _my > _boxy && _my < _boxy2);
                    draw_set_color(_is_sel ? make_color_rgb(16, 55, 148) : (_f_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 38, 14)));
                    draw_rectangle(_fx + 10, _fby, _fx + 240, _fby + 30, false);
                    draw_set_color(_is_sel ? c_white : c_ltgray); draw_text(_fx + 15, _fby + 5, string_upper(action_modal_sfx_folders[f]));
                }
                gpu_set_scissor(0, 0, 1280, 960);

                // FILES
                draw_set_color(c_white); draw_text(_lx - 10, _boxy - 20, "Sound Effect:");
                draw_set_color(make_color_rgb(10, 38, 14)); draw_roundrect_ext(_lx - 10, _boxy, _lx + 310, _boxy2, 5, 5, false);
                gpu_set_scissor(_lx - 10, _boxy, 320, _boxh);
                if (action_modal_sfx_folder_idx != -1) {
                    for (var f = 0; f < array_length(action_modal_sfx_files); f++) {
                        var _fby = _boxy + (f * 30) - action_modal_sfx_files_scroll_y;
                        if (_fby + 30 > _boxy2 || _fby < _boxy) continue;
                        var _is_sel = (action_modal_sfx_file_idx == f);
                        var _f_hov = (!action_modal_sfx_dragging_file && _mx > _lx - 10 && _mx < _lx + 300 && _my > _fby && _my < _fby + 30 && _my > _boxy && _my < _boxy2);
                        draw_set_color(_is_sel ? make_color_rgb(16, 55, 148) : (_f_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 38, 14)));
                        draw_rectangle(_lx - 10, _fby, _lx + 310, _fby + 30, false);
                        draw_set_color(_is_sel ? c_white : c_ltgray); draw_text(_lx - 5, _fby + 5, string_replace(string_upper(action_modal_sfx_files[f]), ".WAV", ""));
                    }
                }
                gpu_set_scissor(0, 0, 1280, 960);

                // FOLDER SCROLLBAR
                var _ftot = array_length(action_modal_sfx_folders) * 30;
                if (_ftot > _boxh) {
                    _sb_x = _fx + 240 - 8;
                    draw_set_color(make_color_rgb(8, 28, 12)); draw_rectangle(_sb_x, _boxy, _sb_x + 8, _boxy2, false);
                    var _bar_h = (_boxh / _ftot) * _boxh;
                    var _bar_y = _boxy + (action_modal_sfx_scroll_y / _ftot) * _boxh;
                    draw_set_color(make_color_rgb(148, 162, 35)); draw_rectangle(_sb_x, _bar_y, _sb_x + 8, _bar_y + _bar_h, false);
                }

                // FILE SCROLLBAR
                var _ltot = array_length(action_modal_sfx_files) * 30;
                if (_ltot > _boxh) {
                    _sb_x = _lx + 310 - 8;
                    draw_set_color(make_color_rgb(8, 28, 12)); draw_rectangle(_sb_x, _boxy, _sb_x + 8, _boxy2, false);
                    var _bar_h = (_boxh / _ltot) * _boxh;
                    var _bar_y = _boxy + (action_modal_sfx_files_scroll_y / _ltot) * _boxh;
                    draw_set_color(make_color_rgb(148, 162, 35)); draw_rectangle(_sb_x, _bar_y, _sb_x + 8, _bar_y + _bar_h, false);
                }
            }

            // TEST / STOP BUTTON
            var _tx = _mxo + _mw - 150; var _ty = _myo + _mh - 120;
            var _sfx_playing = (test_sfx_sound != -1 && audio_is_playing(test_sfx_sound));
            var _can_test = (action_modal_sfx_folder_idx != -1 && action_modal_sfx_file_idx != -1) || _sfx_playing;
            var _t_hov = (_can_test && _mx > _tx && _mx < _tx + 120 && _my > _ty && _my < _ty + 35);
            draw_set_color(_sfx_playing ? (_t_hov ? make_color_rgb(220, 80, 80) : make_color_rgb(160, 50, 50))
                                        : (_can_test ? (_t_hov ? make_color_rgb(100, 100, 200) : make_color_rgb(60, 60, 150)) : make_color_rgb(40, 40, 50)));
            draw_rectangle(_tx, _ty, _tx + 120, _ty + 35, false);
            draw_set_color(_can_test ? c_white : c_gray);
            draw_text(_tx + (_sfx_playing ? 30 : 35), _ty + 8, _sfx_playing ? "STOP" : "TEST");
        } else if (all_actions[action_modal_selected_idx].name == "display title") {
            var _wx = _mxo + 300; var _wy = _myo + 100;
            
            draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_wx, _wy, "PARAMETERS");
            draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_wx, _wy + 25, _wx + 560, _wy + 25);
            
            draw_set_color(c_white); draw_text(_wx, _wy + 40, "Title Text (Max 100 chars, Auto-wraps):");
            draw_set_color(make_color_rgb(228, 242, 232)); draw_roundrect_ext(_wx, _wy + 65, _wx + 560, _wy + 150, 5, 5, false);
            gpu_set_scissor(_wx, _wy + 65, 561, 86);
            var _ttx = _wx + 10; var _tty = _wy + 75;
            if (action_modal_title_sel_start != action_modal_title_sel_end) {
                var _tss = min(action_modal_title_sel_start, action_modal_title_sel_end);
                var _tse = max(action_modal_title_sel_start, action_modal_title_sel_end);
                var _tsp = get_text_pos(action_modal_title_text, _tss, 540, 25);
                var _tep = get_text_pos(action_modal_title_text, _tse, 540, 25);
                draw_set_color(make_color_rgb(100, 160, 220)); draw_set_alpha(0.45);
                if (_tsp.y == _tep.y) {
                    draw_rectangle(_ttx + _tsp.x, _tty + _tsp.y, _ttx + _tep.x, _tty + _tsp.y + 22, false);
                } else {
                    draw_rectangle(_ttx + _tsp.x, _tty + _tsp.y, _ttx + 540, _tty + _tsp.y + 22, false);
                    if (_tep.y > _tsp.y + 25) draw_rectangle(_ttx, _tty + _tsp.y + 25, _ttx + 540, _tty + _tep.y, false);
                    draw_rectangle(_ttx, _tty + _tep.y, _ttx + _tep.x, _tty + _tep.y + 22, false);
                }
                draw_set_alpha(1.0);
            }
            draw_set_color(c_black); draw_text_ext(_ttx, _tty, action_modal_title_text, 25, 540);
            if (cursor_visible) {
                var _tcp = get_text_pos(action_modal_title_text, action_modal_title_caret, 540, 25);
                draw_set_color(c_black);
                draw_line(_ttx + _tcp.x, _tty + _tcp.y, _ttx + _tcp.x, _tty + _tcp.y + 22);
            }
            gpu_set_scissor(0, 0, 1280, 960);
            
            draw_set_color(c_white); draw_text(_wx, _wy + 170, "Duration:");
            var _sw = 300; var _sx = _wx + 100; var _sy = _wy + 170;
            
            var _l_hov = (_mx > _sx - 35 && _mx < _sx - 5 && _my > _sy - 10 && _my < _sy + 35);
            draw_set_color(_l_hov ? c_aqua : c_gray); draw_text(_sx - 35, _sy, "<");
            var _r_hov = (_mx > _sx + _sw + 5 && _mx < _sx + _sw + 45 && _my > _sy - 10 && _my < _sy + 35);
            draw_set_color(_r_hov ? c_aqua : c_gray); draw_text(_sx + _sw + 20, _sy, ">");

            draw_set_color(make_color_rgb(15, 55, 20)); draw_rectangle(_sx, _sy + 8, _sx + _sw, _sy + 13, false);
            var _perc = (action_modal_wait_duration - 0.1) / 9.9;
            draw_set_color(make_color_rgb(196, 213, 20)); draw_rectangle(_sx, _sy + 8, _sx + (_perc * _sw), _sy + 13, false);
            draw_set_color(make_color_rgb(196, 213, 20)); draw_circle(_sx + (_perc * _sw), _sy + 10, 8, false);
            draw_set_color(c_white); draw_text(_sx + _sw + 50, _sy, string(action_modal_wait_duration) + "s");

            var draw_dropdown = function(dx, dy, label, val_idx, opts_array, is_open) {
                draw_set_color(c_white); draw_text(dx, dy, label);
                var _bx = dx + 60; var _bw = 200;
                draw_set_color(is_open ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 42, 16));
                draw_roundrect_ext(_bx, dy, _bx + _bw, dy + 25, 4, 4, false);
                draw_set_color(make_color_rgb(196, 213, 20)); draw_roundrect_ext(_bx, dy, _bx + _bw, dy + 25, 4, 4, true);
                draw_set_color(c_white); draw_text(_bx + 10, dy + 3, opts_array[val_idx]);
                draw_text(_bx + _bw - 20, dy + 3, "v");
                
                if (is_open) {
                    draw_set_color(make_color_rgb(10, 40, 15)); draw_rectangle(_bx, dy + 25, _bx + _bw, dy + 25 + (array_length(opts_array) * 30), false);
                    draw_set_color(make_color_rgb(196, 213, 20)); draw_rectangle(_bx, dy + 25, _bx + _bw, dy + 25 + (array_length(opts_array) * 30), true);
                    for (var d = 0; d < array_length(opts_array); d++) {
                        var _dhov = (mouse_x > _bx && mouse_x < _bx + _bw && mouse_y > dy + 25 + (d * 30) && mouse_y < dy + 25 + ((d+1) * 30));
                        if (_dhov) { draw_set_color(make_color_rgb(20, 72, 28)); draw_rectangle(_bx, dy + 25 + (d * 30), _bx + _bw, dy + 25 + ((d+1) * 30), false); }
                        draw_set_color(d == val_idx ? make_color_rgb(220, 238, 88) : c_white);
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
        } else if (all_actions[action_modal_selected_idx].name == "jitter") {
            var _jx = _mxo+290; var _jsw = 360;
            // Direction
            draw_set_color(make_color_rgb(196,213,20)); draw_text(_jx, _myo+120, "DIRECTION");
            draw_set_color(make_color_rgb(100,120,40)); draw_line(_jx, _myo+138, _jx+_jsw, _myo+138);
            var _jdirs = ["horizontal","vertical","omni"]; var _jdlbls = ["HORIZONTAL","VERTICAL","OMNI"];
            for (var _jdi = 0; _jdi < 3; _jdi++) {
                var _jdx = _jx + _jdi * 124; var _jdsel = (action_modal_jitter_direction == _jdirs[_jdi]);
                var _jdhov = (_mx > _jdx && _mx < _jdx+118 && _my > _myo+146 && _my < _myo+184);
                draw_set_color(_jdsel ? make_color_rgb(16,55,148) : (_jdhov ? make_color_rgb(18,65,24) : make_color_rgb(10,40,15)));
                draw_roundrect_ext(_jdx, _myo+146, _jdx+118, _myo+184, 5,5,false);
                if (_jdsel) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_jdx, _myo+146, _jdx+118, _myo+184, 5,5,true); }
                draw_set_color(_jdsel ? c_white : make_color_rgb(178,210,182));
                draw_set_halign(fa_center); draw_text(_jdx+59, _myo+157, _jdlbls[_jdi]); draw_set_halign(fa_left);
            }
            // Intensity slider
            draw_set_color(make_color_rgb(196,213,20)); draw_text(_jx, _myo+202, "INTENSITY");
            draw_set_color(make_color_rgb(100,120,40)); draw_line(_jx, _myo+220, _jx+_jsw, _myo+220);
            draw_set_color(c_white); draw_text(_jx, _myo+234, "SUBTLE"); draw_text(_jx+_jsw-40, _myo+234, "VIOLENT");
            var _jity = _myo+260;
            draw_set_color(make_color_rgb(15,55,20)); draw_rectangle(_jx, _jity+4, _jx+_jsw, _jity+9, false);
            var _jipct = (action_modal_jitter_intensity-1)/6.0;
            var _jihx = _jx + _jipct*_jsw;
            draw_set_color(make_color_rgb(196,213,20)); draw_rectangle(_jx, _jity+4, _jihx, _jity+9, false);
            draw_circle(_jihx, _jity+6, 8, false);
            draw_set_color(c_white); draw_text(_jx, _myo+278, "Intensity: " + string(action_modal_jitter_intensity));
            // Duration slider
            draw_set_color(make_color_rgb(196,213,20)); draw_text(_jx, _myo+305, "DURATION");
            draw_set_color(make_color_rgb(100,120,40)); draw_line(_jx, _myo+323, _jx+_jsw, _myo+323);
            draw_set_color(c_white); draw_text(_jx, _myo+337, "0.2s"); draw_text(_jx+_jsw-16, _myo+337, "5s");
            var _jdry = _myo+363;
            draw_set_color(make_color_rgb(15,55,20)); draw_rectangle(_jx, _jdry+4, _jx+_jsw, _jdry+9, false);
            var _jdrpct = (action_modal_jitter_duration-0.2)/4.8;
            var _jdrhx = _jx + _jdrpct*_jsw;
            draw_set_color(make_color_rgb(196,213,20)); draw_rectangle(_jx, _jdry+4, _jdrhx, _jdry+9, false);
            draw_circle(_jdrhx, _jdry+6, 8, false);
            draw_set_color(c_white); draw_text(_jx, _myo+381, "Duration: " + string(round(action_modal_jitter_duration*10)/10) + " seconds");
            // Notices
            if (selected_character_index == 0) {
                draw_set_color(make_color_rgb(255,120,120)); draw_text(_jx, _myo+415, "Narrator cannot use character actions.");
            } else if (!action_modal_char_onstage) {
                draw_set_color(make_color_rgb(255,200,80)); draw_text(_jx, _myo+415, "Character is not currently on stage.");
            }
        } else if (all_actions[action_modal_selected_idx].name == "quake") {
            var _qx2 = _mxo+290; var _qsw = 360;
            // Direction
            draw_set_color(make_color_rgb(196,213,20)); draw_text(_qx2, _myo+120, "DIRECTION");
            draw_set_color(make_color_rgb(100,120,40)); draw_line(_qx2, _myo+138, _qx2+_qsw, _myo+138);
            var _qdirs = ["horizontal","vertical","omni"]; var _qdlbls = ["HORIZONTAL","VERTICAL","OMNI"];
            for (var _qdi = 0; _qdi < 3; _qdi++) {
                var _qdx = _qx2 + _qdi * 124; var _qdsel = (action_modal_quake_direction == _qdirs[_qdi]);
                var _qdhov = (_mx > _qdx && _mx < _qdx+118 && _my > _myo+146 && _my < _myo+184);
                draw_set_color(_qdsel ? make_color_rgb(16,55,148) : (_qdhov ? make_color_rgb(18,65,24) : make_color_rgb(10,40,15)));
                draw_roundrect_ext(_qdx, _myo+146, _qdx+118, _myo+184, 5,5,false);
                if (_qdsel) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_qdx, _myo+146, _qdx+118, _myo+184, 5,5,true); }
                draw_set_color(_qdsel ? c_white : make_color_rgb(178,210,182));
                draw_set_halign(fa_center); draw_text(_qdx+59, _myo+157, _qdlbls[_qdi]); draw_set_halign(fa_left);
            }
            // Intensity slider
            draw_set_color(make_color_rgb(196,213,20)); draw_text(_qx2, _myo+202, "INTENSITY");
            draw_set_color(make_color_rgb(100,120,40)); draw_line(_qx2, _myo+220, _qx2+_qsw, _myo+220);
            draw_set_color(c_white); draw_text(_qx2, _myo+234, "SUBTLE"); draw_text(_qx2+_qsw-40, _myo+234, "VIOLENT");
            var _qity = _myo+260;
            draw_set_color(make_color_rgb(15,55,20)); draw_rectangle(_qx2, _qity+4, _qx2+_qsw, _qity+9, false);
            var _qipct = (action_modal_quake_intensity-1)/6.0;
            var _qihx = _qx2 + _qipct*_qsw;
            draw_set_color(make_color_rgb(196,213,20)); draw_rectangle(_qx2, _qity+4, _qihx, _qity+9, false);
            draw_circle(_qihx, _qity+6, 8, false);
            draw_set_color(c_white); draw_text(_qx2, _myo+278, "Intensity: " + string(action_modal_quake_intensity));
            // Duration slider
            draw_set_color(make_color_rgb(196,213,20)); draw_text(_qx2, _myo+305, "DURATION");
            draw_set_color(make_color_rgb(100,120,40)); draw_line(_qx2, _myo+323, _qx2+_qsw, _myo+323);
            draw_set_color(c_white); draw_text(_qx2, _myo+337, "0.2s"); draw_text(_qx2+_qsw-16, _myo+337, "5s");
            var _qdry2 = _myo+363;
            draw_set_color(make_color_rgb(15,55,20)); draw_rectangle(_qx2, _qdry2+4, _qx2+_qsw, _qdry2+9, false);
            var _qdrpct = (action_modal_quake_duration-0.2)/4.8;
            var _qdrhx = _qx2 + _qdrpct*_qsw;
            draw_set_color(make_color_rgb(196,213,20)); draw_rectangle(_qx2, _qdry2+4, _qdrhx, _qdry2+9, false);
            draw_circle(_qdrhx, _qdry2+6, 8, false);
            draw_set_color(c_white); draw_text(_qx2, _myo+381, "Duration: " + string(round(action_modal_quake_duration*10)/10) + " seconds");
        } else if (all_actions[action_modal_selected_idx].name == "disappear") {
            var _disp_styles = ["pop", "eat dirt", "home planet", "disintegrate", "melt"];
            var _disp_labels = ["POP", "EAT DIRT", "HOME PLANET", "DISINTEGRATE", "MELT"];
            var _has_speed = (action_modal_disappear_style != "pop");

            // Style column
            draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_mxo+290, _myo+120, "STYLE");
            draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_mxo+290, _myo+138, _mxo+460, _myo+138);
            for (var _dsi = 0; _dsi < 5; _dsi++) {
                var _dsy = _myo + 148 + _dsi * 44;
                var _dssel = (action_modal_disappear_style == _disp_styles[_dsi]);
                var _dshov = (_mx > _mxo+290 && _mx < _mxo+460 && _my > _dsy && _my < _dsy+38);
                draw_set_color(_dssel ? make_color_rgb(16,55,148) : (_dshov ? make_color_rgb(18,65,24) : make_color_rgb(10,40,15)));
                draw_roundrect_ext(_mxo+290, _dsy, _mxo+460, _dsy+38, 5, 5, false);
                if (_dssel) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_mxo+290, _dsy, _mxo+460, _dsy+38, 5, 5, true); }
                draw_set_color(_dssel ? c_white : make_color_rgb(178,210,182));
                draw_set_halign(fa_center); draw_text(_mxo+375, _dsy+10, _disp_labels[_dsi]); draw_set_halign(fa_left);
            }

            // Speed column
            draw_set_color(_has_speed ? make_color_rgb(196, 213, 20) : make_color_rgb(70, 88, 30)); draw_text(_mxo+475, _myo+120, "SPEED");
            draw_set_color(_has_speed ? make_color_rgb(100, 120, 40) : make_color_rgb(35, 50, 15)); draw_line(_mxo+475, _myo+138, _mxo+660, _myo+138);
            for (var _spi = 0; _spi < 5; _spi++) {
                var _spy = _myo + 148 + _spi * 44;
                var _spsel = (_has_speed && action_modal_disappear_speed == _spi);
                var _sphov = (_has_speed && _mx > _mxo+475 && _mx < _mxo+660 && _my > _spy && _my < _spy+38);
                draw_set_color(_spsel ? make_color_rgb(16,55,148) : (_sphov ? make_color_rgb(18,65,24) : (_has_speed ? make_color_rgb(10,40,15) : make_color_rgb(8,25,10))));
                draw_roundrect_ext(_mxo+475, _spy, _mxo+660, _spy+38, 5, 5, false);
                if (_spsel) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_mxo+475, _spy, _mxo+660, _spy+38, 5, 5, true); }
                draw_set_color(_spsel ? c_white : (_has_speed ? make_color_rgb(178,210,182) : make_color_rgb(50,65,52)));
                draw_set_halign(fa_center); draw_text(_mxo+567, _spy+10, disappear_speed_labels[_spi]); draw_set_halign(fa_left);
            }

            // Disabled notices
            if (selected_character_index == 0) {
                draw_set_color(make_color_rgb(255,120,120)); draw_text(_mxo+290, _myo+415, "Narrator cannot use character actions.");
            } else if (!action_modal_char_onstage) {
                draw_set_color(make_color_rgb(255,200,80)); draw_text(_mxo+290, _myo+415, "Character is not currently on stage.");
            }
        } else if (all_actions[action_modal_selected_idx].name == "kill") {
            var _kill_styles  = ["sudden", "fall_forwards", "fall_backwards", "decapitate"];
            var _kill_labels  = ["SUDDEN DEATH", "FALL FORWARDS", "FALL BACKWARDS", "DECAPITATE"];
            draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_mxo+290, _myo+158, "DEATH STYLE");
            draw_set_color(make_color_rgb(180, 40, 40)); draw_line(_mxo+290, _myo+176, _mxo+540, _myo+176);
            for (var _ksi = 0; _ksi < 4; _ksi++) {
                var _ksy = _myo + 184 + _ksi * 46;
                var _kssel = (action_modal_kill_style == _kill_styles[_ksi]);
                var _kshov = (_mx > _mxo+290 && _mx < _mxo+540 && _my > _ksy && _my < _ksy+40);
                draw_set_color(_kssel ? make_color_rgb(120,16,16) : (_kshov ? make_color_rgb(65,15,15) : make_color_rgb(38,10,10)));
                draw_roundrect_ext(_mxo+290, _ksy, _mxo+540, _ksy+40, 5, 5, false);
                if (_kssel) { draw_set_color(make_color_rgb(200,40,40)); draw_roundrect_ext(_mxo+290, _ksy, _mxo+540, _ksy+40, 5, 5, true); }
                draw_set_color(_kssel ? c_white : make_color_rgb(200,130,130));
                draw_set_halign(fa_center); draw_text(_mxo+415, _ksy+11, _kill_labels[_ksi]); draw_set_halign(fa_left);
            }
            // Speed column — only active for fall styles
            var _kfall = (action_modal_kill_style == "fall_forwards" || action_modal_kill_style == "fall_backwards");
            var _kspd_labels = ["VERY SLOW", "SLOW", "NORMAL", "FAST", "VERY FAST"];
            draw_set_color(_kfall ? make_color_rgb(196, 213, 20) : make_color_rgb(70, 88, 30));
            draw_text(_mxo+555, _myo+158, "SPEED");
            draw_set_color(_kfall ? make_color_rgb(180, 40, 40) : make_color_rgb(60, 25, 25));
            draw_line(_mxo+555, _myo+176, _mxo+745, _myo+176);
            for (var _kspi = 0; _kspi < 5; _kspi++) {
                var _kspy = _myo + 184 + _kspi * 40;
                var _kspsel = (_kfall && action_modal_kill_speed == _kspi);
                var _ksphov = (_kfall && _mx > _mxo+555 && _mx < _mxo+745 && _my > _kspy && _my < _kspy+34);
                draw_set_color(_kspsel ? make_color_rgb(120,16,16) : (_ksphov ? make_color_rgb(65,15,15) : (_kfall ? make_color_rgb(38,10,10) : make_color_rgb(18,6,6))));
                draw_roundrect_ext(_mxo+555, _kspy, _mxo+745, _kspy+34, 5, 5, false);
                if (_kspsel) { draw_set_color(make_color_rgb(200,40,40)); draw_roundrect_ext(_mxo+555, _kspy, _mxo+745, _kspy+34, 5, 5, true); }
                draw_set_color(_kspsel ? c_white : (_kfall ? make_color_rgb(200,130,130) : make_color_rgb(70,35,35)));
                draw_set_halign(fa_center); draw_text(_mxo+650, _kspy+9, _kspd_labels[_kspi]); draw_set_halign(fa_left);
            }
            if (selected_character_index == 0) {
                draw_set_color(make_color_rgb(255,120,120)); draw_text(_mxo+290, _myo+415, "Narrator cannot use character actions.");
            } else if (!action_modal_char_onstage) {
                draw_set_color(make_color_rgb(255,200,80)); draw_text(_mxo+290, _myo+415, "Character is not currently on stage.");
            } else if (action_modal_char_is_dead) {
                draw_set_color(make_color_rgb(255,200,80)); draw_text(_mxo+290, _myo+415, "Character is already dead.");
            }
        } else if (all_actions[action_modal_selected_idx].name == "resurrect") {
            draw_set_color(make_color_rgb(80,200,100));
            draw_text_ext(_mxo+290, _myo+160, "The character returns to life and can be manipulated again.\nIf they are off-screen, drag them back in from the cast panel.", 28, 560);
            var _rfell_ui = (action_modal_char_death_style == "fall_forwards" || action_modal_char_death_style == "fall_backwards");
            if (_rfell_ui) {
                var _rspd_labels = ["VERY SLOW", "SLOW", "NORMAL", "FAST", "VERY FAST"];
                draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_mxo+290, _myo+236, "RISE SPEED");
                draw_set_color(make_color_rgb(80, 200, 100)); draw_line(_mxo+290, _myo+254, _mxo+540, _myo+254);
                for (var _rsi = 0; _rsi < 5; _rsi++) {
                    var _rsy = _myo + 260 + _rsi * 36;
                    var _rsel = (action_modal_resurrect_speed == _rsi);
                    draw_set_color(_rsel ? make_color_rgb(80, 200, 100) : make_color_rgb(30, 80, 40));
                    draw_roundrect_ext(_mxo+290, _rsy, _mxo+540, _rsy+30, 4, 4, false);
                    draw_set_color(_rsel ? c_black : make_color_rgb(140, 190, 110));
                    draw_set_halign(fa_center); draw_text(_mxo+415, _rsy+8, _rspd_labels[_rsi]); draw_set_halign(fa_left);
                }
            }
            if (!action_modal_char_is_dead) {
                draw_set_color(make_color_rgb(255,200,80)); draw_text(_mxo+290, _myo+450, "Character is not dead.");
            }
        } else if (all_actions[action_modal_selected_idx].name == "special animation") {
            var _sa_dr = canned_anim_get_data(selected_character_index);
            var _sa_on = (action_modal_char_onstage && !action_modal_char_is_dead && selected_character_index > 0);
            var _sa_rx = _mxo+290; var _sa_ry = _myo+115; var _sa_rh = 36; var _sa_rw = _mw-324;
            var _sa_lh = _mh - 185; var _sa_stp = _sa_rh + 6;
            var _sa_vis = floor(_sa_lh / _sa_stp);
            if (_sa_dr != undefined && array_length(_sa_dr) > 0) {
                var _sa_total = array_length(_sa_dr);
                var _sa_max = max(0, _sa_total - _sa_vis);
                var _sa_scr = clamp(action_modal_sa_scroll, 0, _sa_max);
                for (var _sai2 = 0; _sai2 < _sa_total; _sai2++) {
                    var _sby2 = _sa_ry + (_sai2 - _sa_scr) * _sa_stp;
                    if (_sby2 < _sa_ry || _sby2 + _sa_rh > _sa_ry + _sa_lh) continue;
                    var _sa_sel2 = (action_modal_selected_anim_idx == _sai2);
                    var _sa_hov2 = (_sa_on && _mx > _sa_rx && _mx < _sa_rx + _sa_rw && _my > _sby2 && _my < _sby2 + _sa_rh);
                    draw_set_color(_sa_sel2 ? make_color_rgb(16, 100, 55) : (_sa_hov2 ? make_color_rgb(14, 70, 35) : make_color_rgb(10, 40, 18)));
                    draw_roundrect_ext(_sa_rx, _sby2, _sa_rx + _sa_rw, _sby2 + _sa_rh, 5, 5, false);
                    if (_sa_sel2) { draw_set_color(make_color_rgb(80, 220, 130)); draw_roundrect_ext(_sa_rx, _sby2, _sa_rx + _sa_rw, _sby2 + _sa_rh, 5, 5, true); }
                    draw_set_color(_sa_on ? (_sa_sel2 ? c_white : make_color_rgb(150, 220, 170)) : make_color_rgb(60, 80, 62));
                    draw_text(_sa_rx + 12, _sby2 + 9, string_upper(_sa_dr[_sai2].name));
                }
                // Scrollbar
                if (_sa_max > 0) {
                    var _sbx_sa = _sa_rx + _sa_rw + 4;
                    draw_set_color(make_color_rgb(10, 35, 14));
                    draw_rectangle(_sbx_sa, _sa_ry, _sbx_sa + 10, _sa_ry + _sa_lh, false);
                    var _th_sa = max(20, _sa_lh * _sa_vis / _sa_total);
                    var _ty_sa = _sa_ry + (_sa_scr / _sa_max) * (_sa_lh - _th_sa);
                    draw_set_color(make_color_rgb(80, 180, 100));
                    draw_rectangle(_sbx_sa, _ty_sa, _sbx_sa + 10, _ty_sa + _th_sa, false);
                }
            } else {
                draw_set_color(make_color_rgb(180, 140, 60));
                draw_text(_sa_rx, _sa_ry, "No animations found for this character.");
            }
            if (!_sa_on) {
                draw_set_color(make_color_rgb(200, 160, 60));
                draw_text(_sa_rx, _myo + 460, action_modal_char_is_dead ? "Character is dead." : "Character is not on stage.");
            }
        }
    }
}


if (move_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _m_w = 400; var _m_h = 660;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    draw_set_color(make_color_rgb(14, 48, 20)); draw_roundrect_ext(_m_x, _m_y, _m_x+_m_w, _m_y+_m_h, 14, 14, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_m_x, _m_y, _m_x+_m_w, _m_y+52, 14, 14, false);
    draw_rectangle(_m_x, _m_y+32, _m_x+_m_w, _m_y+52, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_m_x, _m_y, _m_x+_m_w, _m_y+_m_h, 14, 14, true);
    draw_set_color(c_black); draw_text_transformed(_m_x + 20, _m_y + 13, "MOVEMENT PARAMETERS", 1.1, 1.1, 0);

    // Speed list
    for (var i = 0; i < array_length(move_speed_labels); i++) {
        var _by = _m_y + 80 + (i * 45);
        var _is_sel = (move_modal_temp_speed_index == i);
        var _hov = (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _by && _my < _by + 40);

        draw_set_color(_is_sel ? make_color_rgb(16, 55, 148) : (_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 40, 15)));
        draw_roundrect_ext(_m_x + 50, _by, _m_x + 350, _by + 40, 6, 6, false);
        if (_is_sel) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_m_x + 50, _by, _m_x + 350, _by + 40, 6, 6, true); }
        draw_set_color(_is_sel ? c_white : make_color_rgb(200, 220, 200));
        draw_set_halign(fa_center); draw_text(_m_x + 200, _by + 10, move_speed_labels[i]); draw_set_halign(fa_left);
    }

    // Moonwalk Toggle
    var _m_hov = (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _m_y + 316 && _my < _m_y + 340);
    draw_set_color(_m_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 40, 15));
    draw_roundrect_ext(_m_x + 50, _m_y + 314, _m_x + 350, _m_y + 340, 5, 5, false);
    draw_set_color(c_white); draw_circle(_m_x + 65, _m_y + 327, 9, true);
    if (move_modal_temp_moonwalk) { draw_set_color(make_color_rgb(196, 213, 20)); draw_circle(_m_x + 65, _m_y + 327, 6, false); }
    draw_set_color(c_white); draw_text(_m_x + 82, _m_y + 319, "ENABLE MOONWALK");

    // Trick section
    draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_m_x + 50, _m_y + 356, "TRICK");
    draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_m_x + 50, _m_y + 374, _m_x + 350, _m_y + 374);
    var _trick_labels = ["JUMP", "FRONT FLIP", "BACK FLIP"];
    var _trick_vals   = ["jump", "front flip", "back flip"];
    for (var _ti = 0; _ti < 3; _ti++) {
        var _ty = _m_y + 380 + _ti * 44;
        var _t_sel = (move_modal_temp_trick == _trick_vals[_ti]);
        var _t_hov = (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _ty && _my < _ty + 38);
        draw_set_color(_t_sel ? make_color_rgb(16, 55, 148) : (_t_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 40, 15)));
        draw_roundrect_ext(_m_x + 50, _ty, _m_x + 350, _ty + 38, 6, 6, false);
        if (_t_sel) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_m_x + 50, _ty, _m_x + 350, _ty + 38, 6, 6, true); }
        draw_set_color(_t_sel ? c_white : make_color_rgb(200, 220, 200));
        draw_set_halign(fa_center); draw_text(_m_x + 200, _ty + 10, _trick_labels[_ti]); draw_set_halign(fa_left);
    }

    // Count section (1–5 repeats, only meaningful when a trick is selected)
    var _cnt_active = (move_modal_temp_trick != "none");
    draw_set_color(_cnt_active ? make_color_rgb(196, 213, 20) : make_color_rgb(80, 95, 30));
    draw_text(_m_x + 50, _m_y + 514, "COUNT");
    draw_set_color(_cnt_active ? make_color_rgb(100, 120, 40) : make_color_rgb(50, 65, 20));
    draw_line(_m_x + 50, _m_y + 532, _m_x + 350, _m_y + 532);
    var _cbw = 52; var _cbg = 8;
    for (var _ci = 0; _ci < 5; _ci++) {
        var _cx = _m_x + 50 + _ci * (_cbw + _cbg);
        var _cy = _m_y + 540;
        var _c_sel = (_cnt_active && move_modal_temp_trick_count == _ci + 1);
        var _c_hov = (_cnt_active && !_c_sel && _mx > _cx && _mx < _cx + _cbw && _my > _cy && _my < _cy + 34);
        draw_set_color(_c_sel ? make_color_rgb(16, 55, 148) : (_c_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 30, 10)));
        draw_roundrect_ext(_cx, _cy, _cx + _cbw, _cy + 34, 5, 5, false);
        if (_c_sel) { draw_set_color(make_color_rgb(196, 213, 20)); draw_roundrect_ext(_cx, _cy, _cx + _cbw, _cy + 34, 5, 5, true); }
        draw_set_color(_c_sel ? c_white : (_cnt_active ? make_color_rgb(200, 220, 200) : make_color_rgb(80, 95, 60)));
        draw_set_halign(fa_center); draw_text(_cx + _cbw/2, _cy + 9, string(_ci + 1)); draw_set_halign(fa_left);
    }

    // OK Button
    var _ok_hov = (_mx > _m_x + 40 && _mx < _m_x + 180 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20);
    draw_set_color(_ok_hov ? make_color_rgb(22, 110, 32) : make_color_rgb(14, 75, 22));
    draw_roundrect_ext(_m_x + 40, _m_y + _m_h - 60, _m_x + 180, _m_y + _m_h - 20, 7, 7, false);
    draw_set_color(_ok_hov ? c_white : make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_m_x + 40, _m_y + _m_h - 60, _m_x + 180, _m_y + _m_h - 20, 7, 7, true);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_m_x + 110, _m_y + _m_h - 50, "OK"); draw_set_halign(fa_left);

    // Cancel Button
    var _can_hov = (_mx > _m_x + 220 && _mx < _m_x + 360 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20);
    draw_set_color(_can_hov ? make_color_rgb(200, 40, 40) : make_color_rgb(148, 22, 22));
    draw_roundrect_ext(_m_x + 220, _m_y + _m_h - 60, _m_x + 360, _m_y + _m_h - 20, 7, 7, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_m_x + 290, _m_y + _m_h - 50, "CANCEL"); draw_set_halign(fa_left);
}

if (pose_expr_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _m_w = 1060; var _m_h = 520;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    draw_set_color(make_color_rgb(14, 48, 20));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 14, 14, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + 30, 14, 14, false);
    draw_rectangle(_m_x, _m_y + 14, _m_x + _m_w, _m_y + 30, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 14, 14, true);
    draw_set_color(c_black); draw_text(_m_x + 18, _m_y + 8, "POSE / EXPRESSION");

    // ── POSE LIST ──
    for (var i = 1; i <= 4; i++) {
        var _by = _m_y + 38 + (i - 1) * 58;
        var _hov_p = (_mx > _m_x + 12 && _mx < _m_x + 208 && _my > _by && _my < _by + 50);
        var _locked_p = (pose_modal_locked_pose == i);
        draw_set_color(_locked_p ? make_color_rgb(16, 55, 148) : (_hov_p ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 40, 15)));
        draw_roundrect_ext(_m_x + 12, _by, _m_x + 208, _by + 50, 5, 5, false);
        if (_locked_p) { draw_set_color(make_color_rgb(196, 213, 20)); draw_roundrect_ext(_m_x + 12, _by, _m_x + 208, _by + 50, 5, 5, true); }
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
        draw_set_color(_locked_e ? make_color_rgb(16, 55, 148) : (_hov_e ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 40, 15)));
        draw_roundrect_ext(_ex + 2, _ey + 2, _ex + _col_w_ep - 2, _ey + _row_h_ep - 2, 4, 4, false);
        if (_locked_e) { draw_set_color(make_color_rgb(196, 213, 20)); draw_roundrect_ext(_ex + 2, _ey + 2, _ex + _col_w_ep - 2, _ey + _row_h_ep - 2, 4, 4, true); }
        draw_set_color(_locked_e ? c_white : c_ltgray);
        draw_set_halign(fa_center); draw_text(_ex + _col_w_ep / 2, _ey + _row_h_ep / 2 - 8, mood_names[e - 1]); draw_set_halign(fa_left);
    }

    // ── PREVIEW (full body) ──
    var _pre_x = _m_x + 706; var _pre_y = _m_y + 14;
    var _pre_w = 340; var _pre_h = 460;
    draw_set_color(make_color_rgb(8, 30, 12));
    draw_roundrect_ext(_pre_x, _pre_y, _pre_x + _pre_w, _pre_y + _pre_h, 8, 8, false);
    draw_set_color(make_color_rgb(100, 120, 40));
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
    draw_set_color(_can_apply ? (_ap_hov ? make_color_rgb(22, 110, 32) : make_color_rgb(14, 75, 22)) : make_color_rgb(28, 45, 30));
    draw_roundrect_ext(_ap_x, _btn_y_pe, _ap_x + _btn_w_pe, _btn_y_pe + _btn_h_pe, 7, 7, false);
    draw_set_color(_can_apply ? make_color_rgb(196, 213, 20) : make_color_rgb(55, 78, 57));
    draw_roundrect_ext(_ap_x, _btn_y_pe, _ap_x + _btn_w_pe, _btn_y_pe + _btn_h_pe, 7, 7, true);
    draw_set_color(_can_apply ? c_white : make_color_rgb(80, 100, 82));
    draw_set_halign(fa_center); draw_text(_ap_x + _btn_w_pe / 2, _btn_y_pe + 11, "APPLY"); draw_set_halign(fa_left);
    var _cx_pe = _ap_x + _btn_w_pe + 14;
    var _can_hov = (_mx > _cx_pe && _mx < _cx_pe + _btn_w_pe && _my > _btn_y_pe && _my < _btn_y_pe + _btn_h_pe);
    draw_set_color(_can_hov ? make_color_rgb(200, 40, 40) : make_color_rgb(148, 22, 22));
    draw_roundrect_ext(_cx_pe, _btn_y_pe, _cx_pe + _btn_w_pe, _btn_y_pe + _btn_h_pe, 7, 7, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_cx_pe + _btn_w_pe / 2, _btn_y_pe + 11, "CANCEL"); draw_set_halign(fa_left);
}

// ── ANIMATION EDITOR MODAL ──
if (anim_editor_open) {
    var _data = canned_anim_get_data(anim_editor_char_idx);
    if (_data != undefined) {
        var _m_w = 1060; var _m_h = 620;
        var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;

        draw_set_color(c_black); draw_set_alpha(0.78);
        draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
        draw_set_color(make_color_rgb(10, 36, 16));
        draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 8, 8, false);
        draw_set_color(make_color_rgb(40, 140, 70));
        draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 8, 8, true);

        // Title + close
        draw_set_color(anim_editor_dirty ? make_color_rgb(255, 200, 60) : c_white); draw_set_halign(fa_left);
        var _cname = characters[anim_editor_char_idx].name;
        draw_text(_m_x + 14, _m_y + 14, "ANIMATIONS — " + _cname + (anim_editor_dirty ? "  *" : ""));
        draw_set_color(make_color_rgb(200, 80, 80));
        draw_roundrect_ext(_m_x + _m_w - 50, _m_y + 10, _m_x + _m_w - 10, _m_y + 40, 4, 4, false);
        draw_set_color(c_white); draw_set_halign(fa_center);
        draw_text(_m_x + _m_w - 30, _m_y + 17, "X"); draw_set_halign(fa_left);

        // Controls
        var _playing_label = anim_editor_playing ? "PAUSE" : "PLAY";
        draw_set_color(anim_editor_playing ? make_color_rgb(200, 120, 20) : make_color_rgb(20, 140, 60));
        draw_roundrect_ext(_m_x + 230, _m_y + 20, _m_x + 330, _m_y + 48, 4, 4, false);
        draw_set_color(c_white); draw_set_halign(fa_center);
        draw_text((_m_x + 230 + _m_x + 330) / 2, _m_y + 27, _playing_label);
        draw_set_color(make_color_rgb(40, 90, 130));
        draw_roundrect_ext(_m_x + 340, _m_y + 20, _m_x + 390, _m_y + 48, 4, 4, false);
        draw_roundrect_ext(_m_x + 400, _m_y + 20, _m_x + 450, _m_y + 48, 4, 4, false);
        draw_set_color(c_white);
        draw_text((_m_x + 340 + _m_x + 390) / 2, _m_y + 27, "<");
        draw_text((_m_x + 400 + _m_x + 450) / 2, _m_y + 27, ">");
        // Save button
        var _save_hov = (_mx > _m_x + 460 && _mx < _m_x + 560 && _my > _m_y + 20 && _my < _m_y + 48);
        draw_set_color(anim_editor_dirty ? ((_save_hov) ? make_color_rgb(180, 140, 20) : make_color_rgb(130, 100, 14)) : make_color_rgb(30, 55, 32));
        draw_roundrect_ext(_m_x + 460, _m_y + 20, _m_x + 560, _m_y + 48, 4, 4, false);
        draw_set_color(anim_editor_dirty ? c_white : make_color_rgb(60, 90, 62));
        draw_text((_m_x + 460 + _m_x + 560) / 2, _m_y + 27, "SAVE");
        // Flip mode toggle
        var _flip_hov = (_mx > _m_x + 572 && _mx < _m_x + 642 && _my > _m_y + 20 && _my < _m_y + 48);
        draw_set_color(anim_editor_flipped_mode ? make_color_rgb(40, 110, 190) : (_flip_hov ? make_color_rgb(30, 60, 90) : make_color_rgb(18, 38, 58)));
        draw_roundrect_ext(_m_x + 572, _m_y + 20, _m_x + 642, _m_y + 48, 4, 4, false);
        if (anim_editor_flipped_mode) { draw_set_color(make_color_rgb(120, 190, 255)); draw_roundrect_ext(_m_x + 572, _m_y + 20, _m_x + 642, _m_y + 48, 4, 4, true); }
        draw_set_color(anim_editor_flipped_mode ? c_white : make_color_rgb(80, 120, 160));
        draw_text((_m_x + 572 + _m_x + 642) / 2, _m_y + 27, "FLIP");
        draw_set_halign(fa_left);

        // Fit mode toggle
        var _fit_hov = (_mx > _m_x + 652 && _mx < _m_x + 722 && _my > _m_y + 20 && _my < _m_y + 48);
        draw_set_color(anim_editor_fit_mode ? make_color_rgb(110, 40, 190) : (_fit_hov ? make_color_rgb(60, 30, 90) : make_color_rgb(38, 18, 58)));
        draw_roundrect_ext(_m_x + 652, _m_y + 20, _m_x + 722, _m_y + 48, 4, 4, false);
        if (anim_editor_fit_mode) { draw_set_color(make_color_rgb(190, 120, 255)); draw_roundrect_ext(_m_x + 652, _m_y + 20, _m_x + 722, _m_y + 48, 4, 4, true); }
        draw_set_color(anim_editor_fit_mode ? c_white : make_color_rgb(120, 80, 160));
        draw_set_halign(fa_center);
        draw_text((_m_x + 652 + _m_x + 722) / 2, _m_y + 27, "FIT");
        draw_set_halign(fa_left);

        // Grid snap toggle
        var _grid_hov = (_mx > _m_x + 732 && _mx < _m_x + 802 && _my > _m_y + 20 && _my < _m_y + 48);
        draw_set_color(anim_editor_grid_snap ? make_color_rgb(40, 110, 190) : (_grid_hov ? make_color_rgb(30, 60, 90) : make_color_rgb(18, 38, 58)));
        draw_roundrect_ext(_m_x + 732, _m_y + 20, _m_x + 802, _m_y + 48, 4, 4, false);
        if (anim_editor_grid_snap) { draw_set_color(make_color_rgb(120, 190, 255)); draw_roundrect_ext(_m_x + 732, _m_y + 20, _m_x + 802, _m_y + 48, 4, 4, true); }
        draw_set_color(anim_editor_grid_snap ? c_white : make_color_rgb(80, 120, 160));
        draw_set_halign(fa_center);
        draw_text((_m_x + 732 + _m_x + 802) / 2, _m_y + 27, "GRID");
        draw_set_halign(fa_left);


        // Animation list (left panel)
        draw_set_color(make_color_rgb(8, 28, 12));
        draw_roundrect_ext(_m_x + 10, _m_y + 55, _m_x + 225, _m_y + _m_h - 10, 4, 4, false);
        for (var _ai = 0; _ai < array_length(_data); _ai++) {
            var _anim_entry = _data[_ai];
            var _ly = _m_y + 60 + _ai * 30;
            var _is_sel = (_ai == anim_editor_anim_idx);
            draw_set_color(_is_sel ? make_color_rgb(20, 120, 55) : make_color_rgb(14, 50, 22));
            draw_roundrect_ext(_m_x + 12, _ly, _m_x + 222, _ly + 26, 3, 3, false);
            draw_set_color(_is_sel ? c_white : c_ltgray);
            draw_text(_m_x + 18, _ly + 5, _anim_entry.name);
        }
        // +ANIM button
        var _add_anim_y = _m_y + 60 + array_length(_data) * 30;
        var _add_hov = (_mx > _m_x + 12 && _mx < _m_x + 222 && _my > _add_anim_y && _my < _add_anim_y + 26);
        draw_set_color(_add_hov ? make_color_rgb(20, 80, 40) : make_color_rgb(12, 44, 20));
        draw_roundrect_ext(_m_x + 12, _add_anim_y, _m_x + 222, _add_anim_y + 26, 3, 3, false);
        draw_set_color(make_color_rgb(60, 140, 80)); draw_set_halign(fa_center);
        draw_text((_m_x + 12 + _m_x + 222) / 2, _add_anim_y + 5, "+ NEW ANIM");
        draw_set_halign(fa_left);

        // Frame preview (right panel)
        var _cur_anim = (array_length(_data) > 0) ? _data[clamp(anim_editor_anim_idx, 0, array_length(_data) - 1)] : undefined;
        var _frames   = (_cur_anim != undefined) ? _cur_anim.frames : [];
        var _preview_x = _m_x + 235; var _preview_y = _m_y + 55;
        var _preview_w = _m_w - 245; var _preview_h = _m_h - 100;

        // Preview column: left 40% of the panel; info column: right 60% starting at _info_x
        var _info_x     = _preview_x + floor(_preview_w * 0.40);
        var _col_w      = _preview_x + _preview_w - _info_x - 8; // usable width for info buttons
        var _prev_col_w = _info_x - _preview_x - 4;              // usable pixel width for the character

        // Current frame sprite — composite with feet if assigned
        var _cf = (_frames != undefined && anim_editor_frame_idx < array_length(_frames)) ? _frames[anim_editor_frame_idx] : undefined;
        if (_cf != undefined && _cf.type == "sprite") {
            var _fspr_name = _cf.sprite;
            if (anim_editor_flipped_mode) {
                _fspr_name = (variable_struct_exists(_cf, "sprite_flipped") && _cf.sprite_flipped != "")
                             ? _cf.sprite_flipped : canned_anim_flipped_name(_cf.sprite);
            }
            var _fspr = canned_anim_load_sprite(anim_editor_char_idx, _fspr_name);

            // Resolve feet sprite (animation-level, respects flip mode)
            var _feet_key_prev = anim_editor_flipped_mode ? "feet_sprite_flipped" : "feet_sprite";
            var _feet_name_prev = (_cur_anim != undefined && variable_struct_exists(_cur_anim, _feet_key_prev)) ? _cur_anim[$ _feet_key_prev] : "";
            if (_feet_name_prev == "" && anim_editor_flipped_mode && _cur_anim != undefined) {
                var _fn0 = variable_struct_exists(_cur_anim, "feet_sprite") ? _cur_anim.feet_sprite : "";
                if (_fn0 != "") _feet_name_prev = canned_anim_flipped_name(_fn0);
            }
            var _feet_spr_prev = (_feet_name_prev != "") ? canned_anim_load_sprite(anim_editor_char_idx, _feet_name_prev) : -1;
            var _draw_feet_prev = (_feet_spr_prev != -1);
            var _cl_off_prev = anim_editor_flipped_mode
                ? (variable_struct_exists(_cf, "composite_legs_flipped") ? !_cf.composite_legs_flipped
                   : (variable_struct_exists(_cf, "composite_legs") && !_cf.composite_legs))
                : (variable_struct_exists(_cf, "composite_legs") && !_cf.composite_legs);
            if (_cl_off_prev) { _draw_feet_prev = false; }

            if (_fspr != -1) {
                var _fw = sprite_get_width(_fspr); var _fh = sprite_get_height(_fspr);
                // Available draw area: _prev_col_w wide, (_preview_h - 10) tall, with a small margin
                var _avail_w = _prev_col_w - 8;
                var _avail_h = _preview_h - 20;
                var _center_x = _preview_x + _prev_col_w * 0.5;
                var _floor_y  = _preview_y + _avail_h + 6;

                if (_feet_spr_prev != -1) {
                    // Composite: feet on bottom, body on top — use same math as theater runtime
                    var _fsw2 = sprite_get_width(_feet_spr_prev); var _fsh2 = sprite_get_height(_feet_spr_prev);
                    var _bdy_key = anim_editor_flipped_mode ? "body_dy_flipped" : "body_dy";
                    var _bdx_key = anim_editor_flipped_mode ? "body_dx_flipped" : "body_dx";
                    var _anim_bdy  = (_cur_anim != undefined && variable_struct_exists(_cur_anim, _bdy_key)) ? _cur_anim[$ _bdy_key] : 0;
                    var _anim_bdx  = (_cur_anim != undefined && variable_struct_exists(_cur_anim, _bdx_key)) ? _cur_anim[$ _bdx_key] : 0;
                    var _frame_fdy = (anim_editor_flipped_mode && variable_struct_exists(_cf, "frame_dy_flipped")) ? _cf.frame_dy_flipped
                                   : (variable_struct_exists(_cf, "frame_dy") ? _cf.frame_dy : 0);
                    var _frame_fdx = (anim_editor_flipped_mode && variable_struct_exists(_cf, "frame_dx_flipped")) ? _cf.frame_dx_flipped
                                   : (variable_struct_exists(_cf, "frame_dx") ? _cf.frame_dx : 0);

                    // Offset from offsets.json (same as runtime)
                    var _c_prev = characters[anim_editor_char_idx];
                    var _nm_prev = variable_struct_exists(_c_prev, "sprite_name") ? _c_prev.sprite_name : _c_prev.name;
                    var _od_prev = ds_map_exists(char_offsets_cache, _nm_prev) ? char_offsets_cache[? _nm_prev] : undefined;
                    var _body_ok_prev = string_replace(_fspr_name, ".png", "");
                    var _feet_ok_prev = string_replace(_feet_name_prev, ".png", "");
                    var _off_bdx = 0;
                    var _off_bdy = 0;
                    if (_od_prev != undefined && variable_struct_exists(_od_prev, _body_ok_prev) && variable_struct_exists(_od_prev, _feet_ok_prev)) {
                        _off_bdx = _od_prev[$ _body_ok_prev][0] - _od_prev[$ _feet_ok_prev][0];
                        _off_bdy = _od_prev[$ _body_ok_prev][1] - _od_prev[$ _feet_ok_prev][1];
                    }

                    // Body sits at (-body_h) relative to feet top, plus offsets
                    // Virtual total height = feet_h + any body above the feet top
                    var _body_dy_px = -_fh + _frame_fdy + _anim_bdy; // dy of body relative to feet top (negative = body starts above)
                    var _virtual_top = min(0, _body_dy_px);           // topmost pixel relative to feet top
                    var _total_h = _fsh2 - _virtual_top;              // feet_h + overhang above feet top
                    var _max_w   = max(_fw, _fsw2);
                    var _fsc2 = min(_avail_h / _total_h, _avail_w / _max_w);
                    if (anim_editor_fit_mode) _fsc2 = 1.5;

                    var _feet_draw_x = _center_x - (_fsw2 * _fsc2 * 0.5);
                    var _feet_draw_y = _floor_y  - _fsh2 * _fsc2;
                    var _body_draw_x = _feet_draw_x + (_off_bdx + _frame_fdx + _anim_bdx) * _fsc2;
                    var _body_draw_y = _feet_draw_y + _body_dy_px * _fsc2;
                    var _cl_off_body = anim_editor_flipped_mode
                        ? (variable_struct_exists(_cf, "composite_legs_flipped") ? !_cf.composite_legs_flipped
                           : (variable_struct_exists(_cf, "composite_legs") && !_cf.composite_legs))
                        : (variable_struct_exists(_cf, "composite_legs") && !_cf.composite_legs);
                    if (_cl_off_body) {
                        _body_draw_x = _feet_draw_x + (_off_bdx + _frame_fdx + _anim_bdx) * _fsc2;
                        _body_dy_px = _fsh2 - _fh + _frame_fdy + _anim_bdy;
                        _body_draw_y = _feet_draw_y + _body_dy_px * _fsc2;
                    }
                    var _zsc2 = _fsc2 * anim_editor_zoom;
                    var _zpx2 = (_feet_draw_x - _center_x) * anim_editor_zoom + _center_x + anim_editor_pan_x;
                    var _zpy2 = (_feet_draw_y - _floor_y)  * anim_editor_zoom + _floor_y  + anim_editor_pan_y;
                    var _zbpx = (_body_draw_x - _center_x) * anim_editor_zoom + _center_x + anim_editor_pan_x;
                    var _zbpy = (_body_draw_y - _floor_y)  * anim_editor_zoom + _floor_y  + anim_editor_pan_y;

                    // Draw grid if enabled
                    if (anim_editor_grid_snap) {
                        draw_set_color(make_color_rgb(60, 100, 60)); draw_set_alpha(0.15);
                        for (var _gx = _preview_x; _gx < _preview_x + _prev_col_w; _gx += 16) {
                            draw_line(_gx, _preview_y, _gx, _preview_y + _preview_h);
                        }
                        for (var _gy = _preview_y; _gy < _preview_y + _preview_h; _gy += 16) {
                            draw_line(_preview_x, _gy, _preview_x + _prev_col_w, _gy);
                        }
                        draw_set_alpha(1.0);
                    }
                    if (_draw_feet_prev) {
                        draw_sprite_ext(_feet_spr_prev, 0, _zpx2, _zpy2, _zsc2, _zsc2, 0, c_white, 1);
                    }
                    draw_sprite_ext(_fspr,          0, _zbpx, _zbpy, _zsc2, _zsc2, 0, c_white, 1);
                    // Faint seam line at feet top
                    if (_draw_feet_prev) {
                        draw_set_color(make_color_rgb(50, 130, 50)); draw_set_alpha(0.3);
                        draw_line(_zpx2, _zpy2, _zpx2 + _fsw2 * _zsc2, _zpy2);
                        draw_set_alpha(1.0);
                    }
                } else {
                    var _fsc = min(_avail_h / _fh, _avail_w / _fw);
                    if (anim_editor_fit_mode) _fsc = 1.5;
                    var _fdx = _center_x - (_fw * _fsc * 0.5);
                    var _fdy = _floor_y  - _fh * _fsc;
                    var _zsc  = _fsc * anim_editor_zoom;
                    var _zfdx = (_fdx - _center_x) * anim_editor_zoom + _center_x + anim_editor_pan_x;
                    var _zfdy = (_fdy - _floor_y)  * anim_editor_zoom + _floor_y  + anim_editor_pan_y;

                    // Draw grid if enabled
                    if (anim_editor_grid_snap) {
                        draw_set_color(make_color_rgb(60, 100, 60)); draw_set_alpha(0.15);
                        for (var _gx = _preview_x; _gx < _preview_x + _prev_col_w; _gx += 16) {
                            draw_line(_gx, _preview_y, _gx, _preview_y + _preview_h);
                        }
                        for (var _gy = _preview_y; _gy < _preview_y + _preview_h; _gy += 16) {
                            draw_line(_preview_x, _gy, _preview_x + _prev_col_w, _gy);
                        }
                        draw_set_alpha(1.0);
                    }

                    draw_sprite_ext(_fspr, 0, _zfdx, _zfdy, _zsc, _zsc, 0, c_white, 1);
                }
            }
        }

        // Frame info + edit controls
        var _sprite_count = 0;
        for (var _fi2 = 0; _fi2 < array_length(_frames); _fi2++) {
            if (_frames[_fi2].type == "sprite") _sprite_count++;
        }
        var _edit_frame = (anim_editor_selected_frame >= 0 && anim_editor_selected_frame < array_length(_frames)) ? _frames[anim_editor_selected_frame] : _cf;
        // Compact header: frame position + sprite count on one line
        draw_set_color(c_ltgray);
        draw_text(_info_x, _preview_y + 10, "Frame " + string(anim_editor_frame_idx + 1) + " / " + string(array_length(_frames)) + "  (" + string(_sprite_count) + " spr)");
        if (_edit_frame != undefined && _cur_anim != undefined) {
            // ── Per-animation FEET row (shown regardless of frame type) ──
            var _anim_fs = variable_struct_exists(_cur_anim, "feet_sprite") ? _cur_anim.feet_sprite : "";
            if (!anim_editor_flipped_mode) {
                var _fs_disp = (_anim_fs == "") ? "none" : _anim_fs;
                if (string_length(_fs_disp) > 20) _fs_disp = ".." + string_copy(_fs_disp, string_length(_fs_disp) - 17, 18);
                draw_set_color(_anim_fs != "" ? make_color_rgb(100, 160, 100) : make_color_rgb(100, 100, 100));
                draw_text(_info_x, _preview_y + 26, "FEET  " + _fs_disp);
                draw_set_color(make_color_rgb(32, 76, 140));
                draw_roundrect_ext(_info_x, _preview_y + 44, _info_x + 54, _preview_y + 62, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 27, _preview_y + 48, "SET");
                draw_set_halign(fa_left);
                draw_set_color(_anim_fs != "" ? make_color_rgb(112, 40, 40) : make_color_rgb(36, 27, 27));
                draw_roundrect_ext(_info_x + 60, _preview_y + 44, _info_x + 114, _preview_y + 62, 3, 3, false);
                draw_set_color(_anim_fs != "" ? c_white : make_color_rgb(65, 50, 50)); draw_set_halign(fa_center);
                draw_text(_info_x + 87, _preview_y + 48, "CLR");
                draw_set_halign(fa_left);
                // Body Y offset stepper (same row, right of CLR)
                var _bdy_val = variable_struct_exists(_cur_anim, "body_dy") ? _cur_anim.body_dy : 0;
                draw_set_color(make_color_rgb(80, 110, 80));
                draw_text(_info_x + 122, _preview_y + 48, "Y " + string(_bdy_val));
                draw_set_color(make_color_rgb(32, 70, 90));
                draw_roundrect_ext(_info_x + 172, _preview_y + 44, _info_x + 194, _preview_y + 62, 3, 3, false);
                draw_roundrect_ext(_info_x + 198, _preview_y + 44, _info_x + 220, _preview_y + 62, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 183, _preview_y + 48, "-");
                draw_text(_info_x + 209, _preview_y + 48, "+");
                draw_set_halign(fa_left);
                // Body X offset stepper (same row, right of Y)
                var _bdx_val = variable_struct_exists(_cur_anim, "body_dx") ? _cur_anim.body_dx : 0;
                draw_set_color(make_color_rgb(80, 110, 80));
                draw_text(_info_x + 232, _preview_y + 48, "X " + string(_bdx_val));
                draw_set_color(make_color_rgb(32, 70, 90));
                draw_roundrect_ext(_info_x + 282, _preview_y + 44, _info_x + 304, _preview_y + 62, 3, 3, false);
                draw_roundrect_ext(_info_x + 308, _preview_y + 44, _info_x + 330, _preview_y + 62, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 293, _preview_y + 48, "-");
                draw_text(_info_x + 319, _preview_y + 48, "+");
                draw_set_halign(fa_left);
            } else {
                var _anim_fsf = variable_struct_exists(_cur_anim, "feet_sprite_flipped") ? _cur_anim.feet_sprite_flipped : "";
                var _fsf_disp = (_anim_fsf == "") ? "none" : _anim_fsf;
                if (string_length(_fsf_disp) > 20) _fsf_disp = ".." + string_copy(_fsf_disp, string_length(_fsf_disp) - 17, 18);
                draw_set_color(_anim_fsf != "" ? make_color_rgb(80, 140, 200) : make_color_rgb(80, 100, 120));
                draw_text(_info_x, _preview_y + 26, "FEET  " + _fsf_disp);
                draw_set_color(make_color_rgb(32, 76, 140));
                draw_roundrect_ext(_info_x, _preview_y + 44, _info_x + 54, _preview_y + 62, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 27, _preview_y + 48, "SET");
                draw_set_halign(fa_left);
                draw_set_color(_anim_fsf != "" ? make_color_rgb(112, 40, 40) : make_color_rgb(36, 27, 27));
                draw_roundrect_ext(_info_x + 60, _preview_y + 44, _info_x + 114, _preview_y + 62, 3, 3, false);
                draw_set_color(_anim_fsf != "" ? c_white : make_color_rgb(65, 50, 50)); draw_set_halign(fa_center);
                draw_text(_info_x + 87, _preview_y + 48, "CLR");
                draw_set_halign(fa_left);
                // Body Y offset stepper
                var _bdy_val_f = variable_struct_exists(_cur_anim, "body_dy_flipped") ? _cur_anim.body_dy_flipped : 0;
                draw_set_color(make_color_rgb(80, 110, 80));
                draw_text(_info_x + 122, _preview_y + 48, "Y " + string(_bdy_val_f));
                draw_set_color(make_color_rgb(32, 70, 90));
                draw_roundrect_ext(_info_x + 172, _preview_y + 44, _info_x + 194, _preview_y + 62, 3, 3, false);
                draw_roundrect_ext(_info_x + 198, _preview_y + 44, _info_x + 220, _preview_y + 62, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 183, _preview_y + 48, "-");
                draw_text(_info_x + 209, _preview_y + 48, "+");
                draw_set_halign(fa_left);
                // Body X offset stepper
                var _bdx_val_f = variable_struct_exists(_cur_anim, "body_dx_flipped") ? _cur_anim.body_dx_flipped : 0;
                draw_set_color(make_color_rgb(80, 110, 80));
                draw_text(_info_x + 232, _preview_y + 48, "X " + string(_bdx_val_f));
                draw_set_color(make_color_rgb(32, 70, 90));
                draw_roundrect_ext(_info_x + 282, _preview_y + 44, _info_x + 304, _preview_y + 62, 3, 3, false);
                draw_roundrect_ext(_info_x + 308, _preview_y + 44, _info_x + 330, _preview_y + 62, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 293, _preview_y + 48, "-");
                draw_text(_info_x + 319, _preview_y + 48, "+");
                draw_set_halign(fa_left);
            }
            if (_edit_frame.type == "sprite") {
                // Frame filename
                var _fn_short = _edit_frame.sprite;
                if (string_length(_fn_short) > 20) _fn_short = ".." + string_copy(_fn_short, string_length(_fn_short) - 17, 18);
                draw_set_color(make_color_rgb(140, 160, 140));
                draw_text(_info_x, _preview_y + 76, _fn_short);
                // ── HOLD row ──
                draw_set_color(make_color_rgb(130, 145, 130));
                draw_text(_info_x, _preview_y + 96, "HOLD  " + string(_edit_frame.hold));
                draw_set_color(make_color_rgb(32, 88, 140));
                draw_roundrect_ext(_info_x + 100, _preview_y + 92, _info_x + 126, _preview_y + 110, 3, 3, false);
                draw_roundrect_ext(_info_x + 132, _preview_y + 92, _info_x + 158, _preview_y + 110, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 113, _preview_y + 95, "-");
                draw_text(_info_x + 145, _preview_y + 95, "+");
                draw_set_halign(fa_left);

                // ── Per-frame offset (frame_dy / frame_dx) — when any feet sprite is assigned ──
                {
                    var _has_feet_ef = (_cur_anim != undefined && (
                        (variable_struct_exists(_cur_anim, "feet_sprite") && _cur_anim.feet_sprite != "") ||
                        (variable_struct_exists(_cur_anim, "feet_sprite_flipped") && _cur_anim.feet_sprite_flipped != "")
                    ));
                    if (_has_feet_ef) {
                        var _fdy_key = anim_editor_flipped_mode ? "frame_dy_flipped" : "frame_dy";
                        var _fdx_key = anim_editor_flipped_mode ? "frame_dx_flipped" : "frame_dx";
                        var _fdy_val = variable_struct_exists(_edit_frame, _fdy_key) ? _edit_frame[$ _fdy_key] : 0;
                        var _fdx_val = variable_struct_exists(_edit_frame, _fdx_key) ? _edit_frame[$ _fdx_key] : 0;
                        var _has_override = anim_editor_flipped_mode && (variable_struct_exists(_edit_frame, "frame_dy_flipped") || variable_struct_exists(_edit_frame, "frame_dx_flipped"));
                        var _off_row1 = _preview_y + 144; // Y row
                        var _off_row2 = _preview_y + 164; // X row
                        // Section label
                        draw_set_color(_has_override ? make_color_rgb(80, 140, 200) : make_color_rgb(70, 100, 70));
                        draw_text(_info_x, _off_row1 - 16, anim_editor_flipped_mode ? "FRAME OFFSET (FLIP)" : "FRAME OFFSET");
                        // CLR button in flip mode (removes flipped override, falls back to standard)
                        if (anim_editor_flipped_mode && _has_override) {
                            draw_set_color(make_color_rgb(90, 32, 32));
                            draw_roundrect_ext(_info_x + 138, _off_row1 - 18, _info_x + 168, _off_row1 - 4, 3, 3, false);
                            draw_set_color(c_white); draw_set_halign(fa_center);
                            draw_text(_info_x + 153, _off_row1 - 15, "CLR");
                            draw_set_halign(fa_left);
                        }
                        // COPY / PASTE offset clipboard (normal and flipped tracked separately)
                        {
                            var _cb_base = (anim_editor_flipped_mode && _has_override) ? _info_x + 172 : _info_x + 138;
                            var _active_cb = anim_editor_flipped_mode ? anim_editor_offset_clipboard_flipped : anim_editor_offset_clipboard;
                            var _has_cb = (_active_cb != undefined);
                            var _cpy_hov = (_mx > _cb_base && _mx < _cb_base + 26 && _my > _off_row1 - 18 && _my < _off_row1 - 4);
                            draw_set_color(_cpy_hov ? make_color_rgb(60, 100, 60) : make_color_rgb(38, 65, 38));
                            draw_roundrect_ext(_cb_base, _off_row1 - 18, _cb_base + 26, _off_row1 - 4, 3, 3, false);
                            draw_set_color(c_white); draw_set_halign(fa_center);
                            draw_text(_cb_base + 13, _off_row1 - 15, "CPY");
                            draw_set_halign(fa_left);
                            var _pst_hov = _has_cb && (_mx > _cb_base + 30 && _mx < _cb_base + 80 && _my > _off_row1 - 18 && _my < _off_row1 - 4);
                            draw_set_color(_has_cb ? (_pst_hov ? make_color_rgb(40, 80, 120) : make_color_rgb(26, 52, 90)) : make_color_rgb(35, 40, 38));
                            draw_roundrect_ext(_cb_base + 30, _off_row1 - 18, _cb_base + 80, _off_row1 - 4, 3, 3, false);
                            draw_set_color(_has_cb ? c_white : make_color_rgb(70, 75, 70)); draw_set_halign(fa_center);
                            draw_text(_cb_base + 55, _off_row1 - 15, "PASTE");
                            draw_set_halign(fa_left);
                            // AUTO Y: calculate frame offsets relative to frame 1 height and apply to all frames
                            var _ay_hov = (_mx > _cb_base + 84 && _mx < _cb_base + 152 && _my > _off_row1 - 18 && _my < _off_row1 - 4);
                            draw_set_color(_ay_hov ? make_color_rgb(100, 100, 40) : make_color_rgb(68, 68, 26));
                            draw_roundrect_ext(_cb_base + 84, _off_row1 - 18, _cb_base + 152, _off_row1 - 4, 3, 3, false);
                            draw_set_color(c_white); draw_set_halign(fa_center);
                            draw_text(_cb_base + 118, _off_row1 - 15, "AUTO Y");
                            draw_set_halign(fa_left);
                        }
                        // Y row
                        draw_set_color(make_color_rgb(90, 140, 90));
                        draw_text(_info_x, _off_row1 + 4, "Y");
                        draw_set_color(make_color_rgb(200, 220, 200));
                        draw_set_halign(fa_right);
                        draw_text(_info_x + 68, _off_row1 + 4, string(_fdy_val));
                        draw_set_halign(fa_left);
                        draw_set_color(make_color_rgb(32, 70, 90));
                        draw_roundrect_ext(_info_x + 74,  _off_row1, _info_x + 100, _off_row1 + 18, 3, 3, false);
                        draw_roundrect_ext(_info_x + 104, _off_row1, _info_x + 130, _off_row1 + 18, 3, 3, false);
                        draw_set_color(c_white); draw_set_halign(fa_center);
                        draw_text(_info_x + 87,  _off_row1 + 4, "-");
                        draw_text(_info_x + 117, _off_row1 + 4, "+");
                        draw_set_halign(fa_left);
                        // X row
                        draw_set_color(make_color_rgb(90, 140, 90));
                        draw_text(_info_x, _off_row2 + 4, "X");
                        draw_set_color(make_color_rgb(200, 220, 200));
                        draw_set_halign(fa_right);
                        draw_text(_info_x + 68, _off_row2 + 4, string(_fdx_val));
                        draw_set_halign(fa_left);
                        draw_set_color(make_color_rgb(32, 70, 90));
                        draw_roundrect_ext(_info_x + 74,  _off_row2, _info_x + 100, _off_row2 + 18, 3, 3, false);
                        draw_roundrect_ext(_info_x + 104, _off_row2, _info_x + 130, _off_row2 + 18, 3, 3, false);
                        draw_set_color(c_white); draw_set_halign(fa_center);
                        draw_text(_info_x + 87,  _off_row2 + 4, "-");
                        draw_text(_info_x + 117, _off_row2 + 4, "+");
                        draw_set_halign(fa_left);
                    }
                }
                // ── CHANGE SPRITE ──
                draw_set_color(anim_editor_flipped_mode ? make_color_rgb(26, 60, 128) : make_color_rgb(32, 80, 144));
                draw_roundrect_ext(_info_x, _preview_y + 190, _info_x + 160, _preview_y + 212, 4, 4, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 80, _preview_y + 195, anim_editor_flipped_mode ? "CHANGE FLIPPED" : "CHANGE SPRITE");
                draw_set_halign(fa_left);
                // flipped status indicator (read-only, in flip mode)
                if (anim_editor_flipped_mode) {
                    var _has_flip = variable_struct_exists(_edit_frame, "sprite_flipped") && _edit_frame.sprite_flipped != "";
                    draw_set_color(make_color_rgb(26, 52, 98));
                    draw_roundrect_ext(_info_x, _preview_y + 190, _info_x + 220, _preview_y + 212, 4, 4, false);
                    draw_set_color(_has_flip ? make_color_rgb(105, 185, 105) : make_color_rgb(185, 125, 50)); draw_set_halign(fa_center);
                    draw_text(_info_x + 110, _preview_y + 195, _has_flip ? "OVERRIDE SET" : "USING +250 AUTO");
                    draw_set_halign(fa_left);
                }
                // ── FEET toggle (only when animation has feet sprite) ──
                if (_has_feet_ef) {
                    var _feet_on = anim_editor_flipped_mode
                        ? (variable_struct_exists(_edit_frame, "composite_legs_flipped") ? _edit_frame.composite_legs_flipped
                           : !(variable_struct_exists(_edit_frame, "composite_legs") && !_edit_frame.composite_legs))
                        : !(variable_struct_exists(_edit_frame, "composite_legs") && !_edit_frame.composite_legs);
                    var _ft_hov  = (_mx > _info_x && _mx < _info_x + 160 && _my > _preview_y + 216 && _my < _preview_y + 236);
                    draw_set_color(_feet_on ? (_ft_hov ? make_color_rgb(20, 100, 40) : make_color_rgb(14, 65, 28))
                                           : (_ft_hov ? make_color_rgb(200, 100, 20) : make_color_rgb(130, 60, 10)));
                    draw_roundrect_ext(_info_x, _preview_y + 216, _info_x + 160, _preview_y + 236, 4, 4, false);
                    draw_set_color(c_white); draw_set_halign(fa_center);
                    draw_text(_info_x + 80, _preview_y + 220, _feet_on ? "FEET ON" : "FEET OFF");
                    draw_set_halign(fa_left);
                }
            } else if (_edit_frame.type == "sound") {
                var _sfile = variable_struct_exists(_edit_frame, "file") && _edit_frame.file != undefined ? string(_edit_frame.file) : "unset";
                if (string_length(_sfile) > 26) _sfile = ".." + string_copy(_sfile, string_length(_sfile) - 23, 24);
                draw_set_color(make_color_rgb(160, 180, 160));
                draw_text(_info_x, _preview_y + 76, _sfile);
                draw_set_color(make_color_rgb(130, 145, 130));
                draw_text(_info_x, _preview_y + 96, "ID: " + string(_edit_frame[$ "_sound_id"]));
                // CHANGE SFX
                var _chov_sfx = (_mx > _info_x && _mx < _info_x + 160 && _my > _preview_y + 190 && _my < _preview_y + 212);
                draw_set_color(_chov_sfx ? make_color_rgb(160, 94, 28) : make_color_rgb(120, 74, 18));
                draw_roundrect_ext(_info_x, _preview_y + 190, _info_x + 160, _preview_y + 212, 4, 4, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 80, _preview_y + 195, "CHANGE SFX");
                draw_set_halign(fa_left);
            }
        }

        // ── Unified bottom row: always visible when an animation is selected ──
        if (_cur_anim != undefined) {
            var _btn_y = _preview_y + 248;
            var _has_sel = (_edit_frame != undefined);
            // +SFX
            var _sfx_hov = (_mx > _info_x && _mx < _info_x + 80 && _my > _btn_y && _my < _btn_y + 22);
            draw_set_color(_sfx_hov ? make_color_rgb(60, 120, 60) : make_color_rgb(30, 80, 30));
            draw_roundrect_ext(_info_x, _btn_y, _info_x + 80, _btn_y + 22, 4, 4, false);
            draw_set_color(c_white); draw_set_halign(fa_center);
            draw_text(_info_x + 40, _btn_y + 4, "+SFX");
            draw_set_halign(fa_left);
            // +SPRITE
            var _spr_hov = (_mx > _info_x + 88 && _mx < _info_x + 168 && _my > _btn_y && _my < _btn_y + 22);
            draw_set_color(_spr_hov ? make_color_rgb(40, 80, 160) : make_color_rgb(20, 50, 110));
            draw_roundrect_ext(_info_x + 88, _btn_y, _info_x + 168, _btn_y + 22, 4, 4, false);
            draw_set_color(c_white); draw_set_halign(fa_center);
            draw_text(_info_x + 128, _btn_y + 4, "+SPRITE");
            draw_set_halign(fa_left);
            // DEL — dimmed when nothing selected
            var _dsp_hov = _has_sel && (_mx > _info_x + 176 && _mx < _info_x + 236 && _my > _btn_y && _my < _btn_y + 22);
            draw_set_color(_has_sel ? (_dsp_hov ? make_color_rgb(160, 40, 30) : make_color_rgb(100, 28, 20)) : make_color_rgb(50, 20, 18));
            draw_roundrect_ext(_info_x + 176, _btn_y, _info_x + 236, _btn_y + 22, 4, 4, false);
            draw_set_color(_has_sel ? c_white : make_color_rgb(80, 50, 50)); draw_set_halign(fa_center);
            draw_text(_info_x + 206, _btn_y + 4, "DEL");
            draw_set_halign(fa_left);
        }

        // Frame strip (two rows tall to accommodate selection highlight)
        var _strip_y = _m_y + _m_h - 130;
        draw_set_color(make_color_rgb(8, 28, 12));
        draw_rectangle(_preview_x, _strip_y, _m_x + _m_w - 10, _strip_y + 68, false);
        var _strip_frame_w = 54; var _arr_w = 28;
        var _sx = _preview_x + 4 + _arr_w;
        var _strip_inner_w = _preview_w - _arr_w * 2 - 8;
        var _visible = floor(_strip_inner_w / _strip_frame_w);
        var _max_strip_scroll = max(0, array_length(_frames) - _visible);
        // Auto-scroll to keep current/selected frame in view
        var _focus_idx = (anim_editor_selected_frame >= 0) ? anim_editor_selected_frame : (anim_editor_playing ? anim_editor_frame_idx : -1);
        if (_focus_idx >= 0) {
            if (_focus_idx < anim_editor_strip_scroll)
                anim_editor_strip_scroll = _focus_idx;
            else if (_focus_idx >= anim_editor_strip_scroll + _visible)
                anim_editor_strip_scroll = _focus_idx - _visible + 1;
        }
        anim_editor_strip_scroll = clamp(anim_editor_strip_scroll, 0, _max_strip_scroll);
        var _strip_start = anim_editor_strip_scroll;
        // Left arrow
        var _larr_hov = (_mx > _preview_x + 4 && _mx < _preview_x + 4 + _arr_w && _my > _strip_y + 2 && _my < _strip_y + 66);
        draw_set_color(_larr_hov ? make_color_rgb(60, 80, 60) : make_color_rgb(20, 45, 22));
        draw_roundrect_ext(_preview_x + 4, _strip_y + 20, _preview_x + 4 + _arr_w, _strip_y + 48, 3, 3, false);
        draw_set_color(anim_editor_strip_scroll > 0 ? c_white : make_color_rgb(60, 70, 60));
        draw_set_halign(fa_center); draw_text(_preview_x + 4 + _arr_w / 2, _strip_y + 26, "<"); draw_set_halign(fa_left);
        // Right arrow
        var _rarr_x = _sx + _visible * _strip_frame_w + 4;
        var _rarr_hov = (_mx > _rarr_x && _mx < _rarr_x + _arr_w && _my > _strip_y + 2 && _my < _strip_y + 66);
        draw_set_color(_rarr_hov ? make_color_rgb(60, 80, 60) : make_color_rgb(20, 45, 22));
        draw_roundrect_ext(_rarr_x, _strip_y + 20, _rarr_x + _arr_w, _strip_y + 48, 3, 3, false);
        draw_set_color(anim_editor_strip_scroll < _max_strip_scroll ? c_white : make_color_rgb(60, 70, 60));
        draw_set_halign(fa_center); draw_text(_rarr_x + _arr_w / 2, _strip_y + 26, ">"); draw_set_halign(fa_left);
        for (var _si = _strip_start; _si < min(array_length(_frames), _strip_start + _visible); _si++) {
            var _sf = _frames[_si]; var _sx2 = _sx + (_si - _strip_start) * _strip_frame_w;
            var _is_cur  = (_si == anim_editor_frame_idx);
            var _is_sel  = (_si == anim_editor_selected_frame);
            draw_set_color(_is_sel ? make_color_rgb(20, 80, 180) : (_is_cur ? make_color_rgb(20, 160, 70) : make_color_rgb(20, 50, 28)));
            draw_roundrect_ext(_sx2, _strip_y + 2, _sx2 + _strip_frame_w - 2, _strip_y + 66, 3, 3, false);
            if (_is_sel) { draw_set_color(make_color_rgb(80, 140, 255)); draw_roundrect_ext(_sx2, _strip_y + 2, _sx2 + _strip_frame_w - 2, _strip_y + 66, 3, 3, true); }
            if (_sf.type == "sprite") {
                var _strip_sname = _sf.sprite;
                if (anim_editor_flipped_mode) {
                    _strip_sname = (variable_struct_exists(_sf, "sprite_flipped") && _sf.sprite_flipped != "")
                                   ? _sf.sprite_flipped : canned_anim_flipped_name(_sf.sprite);
                }
                var _tspr = canned_anim_load_sprite(anim_editor_char_idx, _strip_sname);
                if (_tspr != -1) {
                    var _tw = sprite_get_width(_tspr); var _th = sprite_get_height(_tspr);
                    if (_tw > 5 && _th > 5) {  // skip garbage 10x10 frames
                        var _tsc = min(58.0 / _th, 48.0 / _tw);
                        draw_sprite_ext(_tspr, 0, _sx2 + (_strip_frame_w - _tw * _tsc) / 2, _strip_y + 4, _tsc, _tsc, 0, c_white, 1);
                    } else {
                        draw_set_color(make_color_rgb(180, 60, 60)); draw_set_halign(fa_center);
                        draw_text(_sx2 + _strip_frame_w / 2, _strip_y + 24, "?"); draw_set_halign(fa_left);
                    }
                }
            } else if (_sf.type == "sound") {
                draw_set_color(make_color_rgb(200, 180, 40)); draw_set_halign(fa_center);
                draw_text(_sx2 + _strip_frame_w / 2, _strip_y + 24, "SFX"); draw_set_halign(fa_left);
            }
        }

        // SFX picker overlay
        if (anim_editor_sfx_picker) {
            draw_set_color(c_black); draw_set_alpha(0.85);
            draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
            draw_set_color(make_color_rgb(36, 20, 8));
            draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 8, 8, false);
            draw_set_color(make_color_rgb(200, 140, 40));
            draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 8, 8, true);
            var _spath = (anim_editor_sfx_path == "") ? "actors\\" : "actors\\" + anim_editor_sfx_path;
            draw_set_color(c_white); draw_text(_m_x + 14, _m_y + 14, "SELECT SOUND — " + _spath);
            var _lx2 = _m_x + 10; var _ly2 = _m_y + 60; var _lh2 = 28; var _lw2 = _m_w - 32;
            var _btn_y2 = _m_y + _m_h - 44; var _btn_h2 = 32;
            var _clip_bot2 = _btn_y2 - 6;
            var _list_h2 = _clip_bot2 - _ly2;
            var _has_back2 = (anim_editor_sfx_path != "");
            var _total_rows2 = (_has_back2 ? 1 : 0) + array_length(anim_editor_sfx_folders) + array_length(anim_editor_sfx_files);
            var _vis_rows2 = floor(_list_h2 / (_lh2 + 4));
            var _max_scroll2 = max(0, _total_rows2 - _vis_rows2);
            var _scr2 = clamp(anim_editor_sfx_scroll, 0, _max_scroll2);
            var _r2 = 0;
            // Back button
            if (_has_back2) {
                var _rsy = _ly2 + (_r2 - _scr2) * (_lh2 + 4);
                if (_rsy >= _ly2 && _rsy + _lh2 <= _clip_bot2) {
                    var _bhov = (_mx > _lx2 && _mx < _lx2 + _lw2 && _my > _rsy && _my < _rsy + _lh2);
                    draw_set_color(_bhov ? make_color_rgb(80, 50, 20) : make_color_rgb(50, 32, 10));
                    draw_roundrect_ext(_lx2, _rsy, _lx2 + _lw2, _rsy + _lh2, 3, 3, false);
                    draw_set_color(make_color_rgb(255, 200, 80)); draw_text(_lx2 + 10, _rsy + 6, "< BACK");
                }
                _r2++;
            }
            for (var _fdi = 0; _fdi < array_length(anim_editor_sfx_folders); _fdi++) {
                var _rsy = _ly2 + (_r2 - _scr2) * (_lh2 + 4);
                if (_rsy >= _ly2 && _rsy + _lh2 <= _clip_bot2) {
                    var _fdhov = (_mx > _lx2 && _mx < _lx2 + _lw2 && _my > _rsy && _my < _rsy + _lh2);
                    draw_set_color(_fdhov ? make_color_rgb(60, 40, 15) : make_color_rgb(38, 25, 8));
                    draw_roundrect_ext(_lx2, _rsy, _lx2 + _lw2, _rsy + _lh2, 3, 3, false);
                    draw_set_color(make_color_rgb(220, 180, 60)); draw_text(_lx2 + 10, _rsy + 6, "[folder]  " + anim_editor_sfx_folders[_fdi]);
                }
                _r2++;
            }
            for (var _wfi2 = 0; _wfi2 < array_length(anim_editor_sfx_files); _wfi2++) {
                var _rsy = _ly2 + (_r2 - _scr2) * (_lh2 + 4);
                if (_rsy >= _ly2 && _rsy + _lh2 <= _clip_bot2) {
                    var _rel2 = (anim_editor_sfx_path == "") ? anim_editor_sfx_files[_wfi2] : (anim_editor_sfx_path + "\\" + anim_editor_sfx_files[_wfi2]);
                    var _is_pending = (_rel2 == anim_editor_sfx_pending);
                    var _wfhov = (_mx > _lx2 && _mx < _lx2 + _lw2 && _my > _rsy && _my < _rsy + _lh2);
                    draw_set_color(_is_pending ? make_color_rgb(80, 55, 10) : (_wfhov ? make_color_rgb(60, 35, 10) : make_color_rgb(28, 18, 6)));
                    draw_roundrect_ext(_lx2, _rsy, _lx2 + _lw2, _rsy + _lh2, 3, 3, false);
                    if (_is_pending) { draw_set_color(make_color_rgb(255, 210, 80)); draw_roundrect_ext(_lx2, _rsy, _lx2 + _lw2, _rsy + _lh2, 3, 3, true); }
                    var _fname2 = anim_editor_sfx_files[_wfi2];
                    var _dot2 = string_last_pos(".", _fname2);
                    if (_dot2 > 0) _fname2 = string_copy(_fname2, 1, _dot2 - 1);
                    draw_set_color(_is_pending ? make_color_rgb(255, 220, 100) : c_white);
                    draw_text(_lx2 + 10, _rsy + 6, _fname2);
                }
                _r2++;
            }
            // Scrollbar
            if (_max_scroll2 > 0) {
                var _sbx = _m_x + _m_w - 16; var _sby2 = _ly2; var _sbh2 = _list_h2;
                draw_set_color(make_color_rgb(30, 20, 8));
                draw_rectangle(_sbx, _sby2, _sbx + 10, _sby2 + _sbh2, false);
                var _thumb_h2 = max(20, _sbh2 * _vis_rows2 / _total_rows2);
                var _thumb_y2 = _sby2 + (_scr2 / _max_scroll2) * (_sbh2 - _thumb_h2);
                draw_set_color(make_color_rgb(180, 120, 40));
                draw_rectangle(_sbx, _thumb_y2, _sbx + 10, _thumb_y2 + _thumb_h2, false);
            }
            // OK / Cancel buttons
            var _ok_x2  = _m_x + _m_w - 220; var _ok_w2 = 90;
            var _cx2    = _m_x + _m_w - 120; var _cw2   = 90;
            
            // Draw pending selected SFX name
            if (anim_editor_sfx_pending != "") {
                draw_set_color(make_color_rgb(255, 200, 80));
                var _disp_pending = anim_editor_sfx_pending;
                var _dot_pos = string_last_pos(".", _disp_pending);
                if (_dot_pos > 0) _disp_pending = string_copy(_disp_pending, 1, _dot_pos - 1);
                draw_text(_m_x + 14, _btn_y2 + 8, "Selected: " + _disp_pending);
            }
            
            var _ok_active = (anim_editor_sfx_pending != "");
            draw_set_color(_ok_active ? ((_mx > _ok_x2 && _mx < _ok_x2 + _ok_w2 && _my > _btn_y2 && _my < _btn_y2 + _btn_h2) ? make_color_rgb(80, 160, 80) : make_color_rgb(40, 100, 40)) : make_color_rgb(30, 50, 30));
            draw_roundrect_ext(_ok_x2, _btn_y2, _ok_x2 + _ok_w2, _btn_y2 + _btn_h2, 4, 4, false);
            draw_set_color(_ok_active ? c_white : make_color_rgb(80, 100, 80));
            draw_text(_ok_x2 + 22, _btn_y2 + 8, "OK");
            var _chov2 = (_mx > _cx2 && _mx < _cx2 + _cw2 && _my > _btn_y2 && _my < _btn_y2 + _btn_h2);
            draw_set_color(_chov2 ? make_color_rgb(100, 40, 30) : make_color_rgb(60, 28, 20));
            draw_roundrect_ext(_cx2, _btn_y2, _cx2 + _cw2, _btn_y2 + _btn_h2, 4, 4, false);
            draw_set_color(c_white); draw_text(_cx2 + 14, _btn_y2 + 8, "CANCEL");
        }

        // Sprite picker overlay
        if (anim_editor_sprite_picker) {
            draw_set_color(c_black); draw_set_alpha(0.85);
            draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
            draw_set_color(make_color_rgb(8, 28, 14));
            draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 8, 8, false);
            draw_set_color(make_color_rgb(80, 140, 255));
            draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 8, 8, true);
            draw_set_color(c_white); draw_text(_m_x + 14, _m_y + 14, anim_editor_sprite_picker_mode == 1 ? "SELECT FEET SPRITE" : "SELECT SPRITE");
            var _sp_btn_y2 = _m_y + _m_h - 44; var _sp_btn_h2 = 32;
            var _grid_x = _m_x + 10; var _grid_y = _m_y + 60;
            var _cols = 4; var _tw2 = 200; var _th2 = 160;
            var _visible_rows = floor((_sp_btn_y2 - 10 - _grid_y) / _th2);
            var _start = anim_editor_sprite_scroll * _cols;
            for (var _pi = _start; _pi < min(array_length(anim_editor_sprite_list), _start + _cols * _visible_rows); _pi++) {
                var _pidx = _pi - _start;
                var _pr = floor(_pidx / _cols); var _pc = _pidx mod _cols;
                var _px = _grid_x + _pc * _tw2; var _py = _grid_y + _pr * _th2;
                var _is_pend = (anim_editor_sprite_list[_pi] == anim_editor_sprite_pending);
                var _phov = (_mx > _px && _mx < _px + _tw2 - 4 && _my > _py && _my < _py + _th2 - 4);
                draw_set_color(_is_pend ? make_color_rgb(20, 70, 120) : (_phov ? make_color_rgb(20, 80, 140) : make_color_rgb(14, 44, 20)));
                draw_roundrect_ext(_px, _py, _px + _tw2 - 4, _py + _th2 - 4, 3, 3, false);
                if (_is_pend) { draw_set_color(make_color_rgb(80, 180, 255)); draw_roundrect_ext(_px, _py, _px + _tw2 - 4, _py + _th2 - 4, 3, 3, true); }
                var _pspr = canned_anim_load_sprite(anim_editor_char_idx, anim_editor_sprite_list[_pi]);
                if (_pspr != -1) {
                    var _pw = sprite_get_width(_pspr); var _ph = sprite_get_height(_pspr);
                    if (_pw > 5 && _ph > 5) {
                        var _psc = min(140.0 / _ph, 180.0 / _pw);
                        gpu_set_texfilter(true);
                        draw_sprite_ext(_pspr, 0, _px + (_tw2 - 4 - _pw * _psc) / 2, _py + (_th2 - 4 - _ph * _psc) / 2, _psc, _psc, 0, c_white, 1);
                        gpu_set_texfilter(false);
                    }
                }
                draw_set_color(_is_pend ? make_color_rgb(140, 210, 255) : make_color_rgb(100, 130, 100)); draw_set_halign(fa_center);
                var _lbl = anim_editor_sprite_list[_pi];
                if (string_length(_lbl) > 10) _lbl = string_copy(_lbl, string_pos("_", _lbl) + 1, 8);
                draw_text(_px + _tw2 / 2, _py + _th2 - 18, _lbl);
                draw_set_halign(fa_left);
            }
            // Scrollbar
            var _total_spr_rows = ceil(array_length(anim_editor_sprite_list) / _cols);
            var _max_spr_scroll = max(0, _total_spr_rows - _visible_rows);
            if (_max_spr_scroll > 0) {
                var _sbx2 = _m_x + _m_w - 16; var _sby3 = _grid_y; var _sbh3 = _visible_rows * _th2;
                draw_set_color(make_color_rgb(10, 30, 15));
                draw_rectangle(_sbx2, _sby3, _sbx2 + 10, _sby3 + _sbh3, false);
                var _thumb_h3 = max(20, _sbh3 * _visible_rows / _total_spr_rows);
                var _thumb_y3 = _sby3 + (anim_editor_sprite_scroll / _max_spr_scroll) * (_sbh3 - _thumb_h3);
                draw_set_color(make_color_rgb(80, 140, 255));
                draw_rectangle(_sbx2, _thumb_y3, _sbx2 + 10, _thumb_y3 + _thumb_h3, false);
            }
            // OK / Cancel buttons
            var _sp_ok_x2 = _m_x + _m_w - 220; var _sp_ok_w2 = 90;
            var _sp_cx2   = _m_x + _m_w - 120; var _sp_cw2   = 90;
            var _sp_ok_active = (anim_editor_sprite_pending != "");
            draw_set_color(_sp_ok_active ? ((_mx > _sp_ok_x2 && _mx < _sp_ok_x2 + _sp_ok_w2 && _my > _sp_btn_y2 && _my < _sp_btn_y2 + _sp_btn_h2) ? make_color_rgb(80, 160, 80) : make_color_rgb(40, 100, 40)) : make_color_rgb(30, 50, 30));
            draw_roundrect_ext(_sp_ok_x2, _sp_btn_y2, _sp_ok_x2 + _sp_ok_w2, _sp_btn_y2 + _sp_btn_h2, 4, 4, false);
            draw_set_color(_sp_ok_active ? c_white : make_color_rgb(80, 100, 80));
            draw_text(_sp_ok_x2 + 22, _sp_btn_y2 + 8, "OK");
            var _sp_chov = (_mx > _sp_cx2 && _mx < _sp_cx2 + _sp_cw2 && _my > _sp_btn_y2 && _my < _sp_btn_y2 + _sp_btn_h2);
            draw_set_color(_sp_chov ? make_color_rgb(100, 40, 30) : make_color_rgb(60, 28, 20));
            draw_roundrect_ext(_sp_cx2, _sp_btn_y2, _sp_cx2 + _sp_cw2, _sp_btn_y2 + _sp_btn_h2, 4, 4, false);
            draw_set_color(c_white); draw_text(_sp_cx2 + 14, _sp_btn_y2 + 8, "CANCEL");
        }
    }
}

// ── EXPRESSION TILE CONFIGURATOR MODAL ──
if (expr_cfg_open) {
    draw_set_color(c_black); draw_set_alpha(0.78);
    draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);

    var _m_x = 85; var _m_y = 55; var _m_w = 1110; var _m_h = 770;
    draw_set_color(make_color_rgb(14, 48, 20));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 12, 12, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + 48, 12, 12, false);
    draw_rectangle(_m_x, _m_y + 28, _m_x + _m_w, _m_y + 48, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 12, 12, true);

    var _lx = _m_x + 12; var _ly = _m_y + 12;
    var _c_ec = characters[expr_cfg_char_idx];

    // Load offsets.json for left panel total offset displays
    var _folder_ec2 = datafiles_path + "actors/" + _c_ec.name + "/";
    var _cfg_ec2 = datafiles_path + "config/" + _c_ec.name + "/";
    var _off_data = undefined;
    if (file_exists(_cfg_ec2 + "offsets.json")) {
        var _s = ""; var _f = file_text_open_read(_cfg_ec2 + "offsets.json");
        while (!file_text_eof(_f)) { _s += file_text_readln(_f); }
        file_text_close(_f); _off_data = json_parse(_s);
    }

    // Title
    draw_set_color(c_black);
    draw_text_transformed(_lx, _m_y + 12, "EXPRESSION TILE CONFIGURATOR  [DEBUG]", 1.05, 1.05, 0);

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
    var _dir_nm_ec = string_lower(_c_ec.name);
    _ai_ec = variable_struct_exists(_c_ec, "act_index") ? _c_ec.act_index : 1;
    _sfx_off_ec = expr_cfg_high ? 50 : 0;
    _pfx_ec = string(_ai_ec) + string(expr_cfg_pose);

    // ── Load body / face sprites (with sprite_add fallback) ──
    if (_pc_ec != undefined) {
        if (_pc_ec.body_file != "") {
            var _bk3 = _c_ec.name + "_" + _pc_ec.body_file;
            if (ds_map_exists(char_sprites, _bk3)) {
                _body_spr_ec = char_sprites[? _bk3];
            } else if (_actor_file_exists(_dir_nm_ec, _folder_ec2, _pc_ec.body_file)) {
                _body_spr_ec = _actor_sprite_add(_dir_nm_ec, _folder_ec2, _pc_ec.body_file);
                ds_map_add(char_sprites, _bk3, _body_spr_ec);
            }
        }
        if (_pc_ec.face_file != "") {
            var _fk3 = _c_ec.name + "_" + _pc_ec.face_file;
            if (ds_map_exists(char_sprites, _fk3)) {
                _face_spr_ec = char_sprites[? _fk3];
            } else if (_actor_file_exists(_dir_nm_ec, _folder_ec2, _pc_ec.face_file)) {
                _face_spr_ec = _actor_sprite_add(_dir_nm_ec, _folder_ec2, _pc_ec.face_file);
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
    } else if (_actor_file_exists(_dir_nm_ec, _folder_ec2, _eyes_file_ec)) {
        _eyes_spr_ec = _actor_sprite_add(_dir_nm_ec, _folder_ec2, _eyes_file_ec);
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
    } else if (_actor_file_exists(_dir_nm_ec, _folder_ec2, _mouth_file_ec)) {
        _mouth_spr_ec = _actor_sprite_add(_dir_nm_ec, _folder_ec2, _mouth_file_ec);
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

// --- IMPORT MODAL ---
if (import_modal_open) {
    var _imw = 580; var _imh = 330;
    var _imx = (1280 - _imw) / 2; var _imy = (800 - _imh) / 2;

    // Background
    draw_set_color(make_color_rgb(12, 8, 22)); draw_roundrect_ext(_imx, _imy, _imx + _imw, _imy + _imh, 8, 8, false);
    draw_set_color(make_color_rgb(175, 130, 230)); draw_roundrect_ext(_imx, _imy, _imx + _imw, _imy + _imh, 8, 8, true);

    // Header
    draw_set_color(make_color_rgb(175, 130, 230)); draw_text(_imx + 14, _imy + 10, "IMPORT ASSETS");
    draw_set_color(make_color_rgb(80, 55, 110)); draw_line(_imx + 1, _imy + 33, _imx + _imw - 1, _imy + 33);

    // Close button
    var _ic_hov = (_mx > _imx + _imw - 34 && _mx < _imx + _imw - 6 && _my > _imy + 6 && _my < _imy + 30);
    draw_set_color(_ic_hov ? c_red : make_color_rgb(100, 30, 30)); draw_roundrect_ext(_imx + _imw - 34, _imy + 6, _imx + _imw - 6, _imy + 30, 4, 4, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_imx + _imw - 20, _imy + 10, "X"); draw_set_halign(fa_left);

    // Mode tabs
    var _it0 = (import_modal_mode == 0); var _it1 = (import_modal_mode == 1);
    draw_set_color(_it0 ? make_color_rgb(80, 40, 130) : make_color_rgb(30, 20, 50));
    draw_roundrect_ext(_imx + 10, _imy + 38, _imx + 100, _imy + 63, 5, 5, false);
    draw_set_color(_it0 ? make_color_rgb(175, 130, 230) : make_color_rgb(90, 70, 120));
    draw_roundrect_ext(_imx + 10, _imy + 38, _imx + 100, _imy + 63, 5, 5, true);
    draw_set_color(_it0 ? c_white : make_color_rgb(150, 120, 180)); draw_set_halign(fa_center); draw_text(_imx + 55, _imy + 43, "IMAGE"); draw_set_halign(fa_left);

    draw_set_color(_it1 ? make_color_rgb(80, 40, 130) : make_color_rgb(30, 20, 50));
    draw_roundrect_ext(_imx + 106, _imy + 38, _imx + 196, _imy + 63, 5, 5, false);
    draw_set_color(_it1 ? make_color_rgb(175, 130, 230) : make_color_rgb(90, 70, 120));
    draw_roundrect_ext(_imx + 106, _imy + 38, _imx + 196, _imy + 63, 5, 5, true);
    draw_set_color(_it1 ? c_white : make_color_rgb(150, 120, 180)); draw_set_halign(fa_center); draw_text(_imx + 151, _imy + 43, "SOUND"); draw_set_halign(fa_left);

    var _browse_w = 92;
    var _browse_x = _imx + _imw - 10 - _browse_w;

    if (import_modal_mode == 0) {
        // Background image row
        draw_set_color(make_color_rgb(175, 130, 230)); draw_text(_imx + 14, _imy + 75, "Background Image:");
        var _bg_disp = (import_modal_bg_path != "") ? filename_name(import_modal_bg_path) : "no file selected";
        draw_set_color(make_color_rgb(200, 200, 210)); draw_roundrect_ext(_imx + 14, _imy + 92, _browse_x - 8, _imy + 120, 4, 4, false);
        gpu_set_scissor(_imx + 14, _imy + 92, _browse_x - 24, 28);
        draw_set_color(import_modal_bg_path != "" ? c_white : make_color_rgb(120, 110, 140)); draw_text(_imx + 20, _imy + 100, _bg_disp);
        gpu_set_scissor(0, 0, 1280, 960);
        var _bb_hov = (_mx > _browse_x && _mx < _browse_x + _browse_w && _my > _imy + 92 && _my < _imy + 120);
        draw_set_color(_bb_hov ? make_color_rgb(110, 60, 175) : make_color_rgb(70, 35, 120)); draw_roundrect_ext(_browse_x, _imy + 92, _browse_x + _browse_w, _imy + 120, 4, 4, false);
        draw_set_color(_bb_hov ? c_white : make_color_rgb(175, 130, 230)); draw_roundrect_ext(_browse_x, _imy + 92, _browse_x + _browse_w, _imy + 120, 4, 4, true);
        draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_browse_x + _browse_w / 2, _imy + 100, "BROWSE"); draw_set_halign(fa_left);

        // Mask image row
        draw_set_color(make_color_rgb(175, 130, 230)); draw_text(_imx + 14, _imy + 148, "Mask Image (optional):");
        var _mk_disp = (import_modal_mask_path != "") ? filename_name(import_modal_mask_path) : "none";
        draw_set_color(make_color_rgb(200, 200, 210)); draw_roundrect_ext(_imx + 14, _imy + 165, _browse_x - 8, _imy + 193, 4, 4, false);
        gpu_set_scissor(_imx + 14, _imy + 165, _browse_x - 24, 28);
        draw_set_color(import_modal_mask_path != "" ? c_white : make_color_rgb(120, 110, 140)); draw_text(_imx + 20, _imy + 173, _mk_disp);
        gpu_set_scissor(0, 0, 1280, 960);
        var _mb_hov = (_mx > _browse_x && _mx < _browse_x + _browse_w && _my > _imy + 165 && _my < _imy + 193);
        draw_set_color(_mb_hov ? make_color_rgb(110, 60, 175) : make_color_rgb(70, 35, 120)); draw_roundrect_ext(_browse_x, _imy + 165, _browse_x + _browse_w, _imy + 193, 4, 4, false);
        draw_set_color(_mb_hov ? c_white : make_color_rgb(175, 130, 230)); draw_roundrect_ext(_browse_x, _imy + 165, _browse_x + _browse_w, _imy + 193, 4, 4, true);
        draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_browse_x + _browse_w / 2, _imy + 173, "BROWSE"); draw_set_halign(fa_left);
        if (import_modal_mask_path != "") {
            var _clr_hov = (_mx > _browse_x && _mx < _browse_x + _browse_w && _my > _imy + 198 && _my < _imy + 216);
            draw_set_color(_clr_hov ? make_color_rgb(140, 40, 40) : make_color_rgb(80, 25, 25)); draw_roundrect_ext(_browse_x, _imy + 198, _browse_x + _browse_w, _imy + 216, 3, 3, false);
            draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_browse_x + _browse_w / 2, _imy + 202, "CLEAR"); draw_set_halign(fa_left);
        }
        // Mask rename note
        if (import_modal_mask_path != "" && import_modal_bg_path != "") {
            var _note = "Will be saved as: " + filename_change_ext(filename_name(import_modal_bg_path), "") + "_mask" + filename_ext(import_modal_mask_path);
            draw_set_color(make_color_rgb(140, 120, 170)); draw_text(_imx + 14, _imy + 220, _note);
        }
    } else {
        // Subcategory row
        draw_set_color(make_color_rgb(175, 130, 230)); draw_text(_imx + 14, _imy + 75, "Subcategory (folder name):");
        draw_set_color(make_color_rgb(200, 200, 210)); draw_roundrect_ext(_imx + 14, _imy + 92, _imx + _imw - 14, _imy + 120, 4, 4, false);
        var _sc_txt = import_modal_subcat + (cursor_visible ? "|" : "");
        draw_set_color(string_length(import_modal_subcat) > 0 ? make_color_rgb(20, 15, 35) : make_color_rgb(155, 140, 175));
        draw_text(_imx + 20, _imy + 100, string_length(import_modal_subcat) > 0 ? import_modal_subcat : "e.g.  humans");
        if (cursor_visible) {
            var _cp = get_text_pos(import_modal_subcat, import_modal_subcat_caret, _imw - 34, 20);
            draw_set_color(make_color_rgb(20, 15, 35));
            draw_line(_imx + 20 + _cp.x, _imy + 100, _imx + 20 + _cp.x, _imy + 116);
        }

        // Sound file row
        draw_set_color(make_color_rgb(175, 130, 230)); draw_text(_imx + 14, _imy + 148, "Sound File (.wav):");
        var _snd_disp = (import_modal_snd_path != "") ? filename_name(import_modal_snd_path) : "no file selected";
        draw_set_color(make_color_rgb(200, 200, 210)); draw_roundrect_ext(_imx + 14, _imy + 165, _browse_x - 8, _imy + 193, 4, 4, false);
        gpu_set_scissor(_imx + 14, _imy + 165, _browse_x - 24, 28);
        draw_set_color(import_modal_snd_path != "" ? c_white : make_color_rgb(120, 110, 140)); draw_text(_imx + 20, _imy + 173, _snd_disp);
        gpu_set_scissor(0, 0, 1280, 960);
        var _sb_hov = (_mx > _browse_x && _mx < _browse_x + _browse_w && _my > _imy + 165 && _my < _imy + 193);
        draw_set_color(_sb_hov ? make_color_rgb(110, 60, 175) : make_color_rgb(70, 35, 120)); draw_roundrect_ext(_browse_x, _imy + 165, _browse_x + _browse_w, _imy + 193, 4, 4, false);
        draw_set_color(_sb_hov ? c_white : make_color_rgb(175, 130, 230)); draw_roundrect_ext(_browse_x, _imy + 165, _browse_x + _browse_w, _imy + 193, 4, 4, true);
        draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_browse_x + _browse_w / 2, _imy + 173, "BROWSE"); draw_set_halign(fa_left);
    }

    // Divider above bottom bar
    draw_set_color(make_color_rgb(60, 40, 90)); draw_line(_imx + 1, _imy + _imh - 65, _imx + _imw - 1, _imy + _imh - 65);

    // Status message
    if (import_modal_status != "") {
        draw_set_color(import_modal_status_ok ? make_color_rgb(100, 220, 120) : make_color_rgb(220, 100, 100));
        draw_text(_imx + 14, _imy + _imh - 55, import_modal_status);
    }

    // Import button
    var _can_import = (import_modal_mode == 0) ? (import_modal_bg_path != "") : (import_modal_snd_path != "" && string_length(string_trim(import_modal_subcat)) > 0);
    var _imp_hov = (_can_import && _mx > _browse_x && _mx < _browse_x + _browse_w && _my > _imy + _imh - 55 && _my < _imy + _imh - 20);
    draw_set_color(_can_import ? (_imp_hov ? make_color_rgb(80, 160, 80) : make_color_rgb(40, 110, 40)) : make_color_rgb(30, 40, 30));
    draw_roundrect_ext(_browse_x, _imy + _imh - 55, _browse_x + _browse_w, _imy + _imh - 20, 5, 5, false);
    draw_set_color(_can_import ? (_imp_hov ? c_white : make_color_rgb(130, 210, 130)) : make_color_rgb(60, 70, 60));
    draw_roundrect_ext(_browse_x, _imy + _imh - 55, _browse_x + _browse_w, _imy + _imh - 20, 5, 5, true);
    draw_set_color(_can_import ? c_white : make_color_rgb(80, 90, 80)); draw_set_halign(fa_center);
    draw_text(_browse_x + _browse_w / 2, _imy + _imh - 44, "IMPORT"); draw_set_halign(fa_left);
}

// Restore default texture filter after modals
gpu_set_texfilter(false);

// --- 5c. LIVE TITLE RENDERING ---
_render_live_titles();

// --- FX PICKER DROPDOWN (drawn last so it's always on top) ---
if (fx_picker_open && scene_edit_mode && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
    var _sfx2      = script_blocks[active_scene_block_idx];
    var _cur_fx2   = variable_struct_exists(_sfx2, "fx") ? _sfx2.fx : "none";
    var _ind_x2    = max(scene_win_x, 110);
    var _fp_btn_x  = _ind_x2 + 120; var _fp_btn_w = 130;
    var _fp_ids    = ["none", "blackwhite", "brighten", "candlelight", "crt",   "darken", "dream",  "drunk", "embers", "filth",  "fog", "frigid",  "goldenhour",  "heat",      "infrared", "moonlight",  "nightvision",  "rain", "sepia", "snow", "static",    "stoned", "sunlight",   "underwater"];
    var _fp_labels = ["OFF",  "B&W FILM",  "BRIGHTEN", "CANDLELIGHT", "CRT",   "DARKEN", "DREAM",  "DRUNK", "EMBERS", "FILTH",  "FOG", "FRIGID",  "GOLDEN HOUR", "HEAT HAZE", "INFRARED", "MOONLIGHT",  "NIGHT VISION", "RAIN", "SEPIA", "SNOW", "TV STATIC", "STONED", "SUNLIGHT",   "UNDERWATER"];
    var _fp_count  = array_length(_fp_ids);
    var _fp_item_h = 22;
    var _fp_max    = 13; // max visible rows
    var _fp_vis    = min(_fp_max, _fp_count);
    var _fp_pick_y = scene_win_y - 10;
    var _fp_h      = _fp_vis * _fp_item_h;

    // Background + border
    draw_set_color(make_color_rgb(25, 25, 35));
    draw_rectangle(_fp_btn_x, _fp_pick_y, _fp_btn_x + _fp_btn_w, _fp_pick_y + _fp_h, false);
    draw_set_color(c_aqua);
    draw_rectangle(_fp_btn_x, _fp_pick_y, _fp_btn_x + _fp_btn_w, _fp_pick_y + _fp_h, true);

    // Scrollbar geometry (computed here for both draw and hover state)
    var _fp_sb_w  = 6;
    var _fp_sb_x  = _fp_btn_x + _fp_btn_w - _fp_sb_w - 2;
    var _fp_bar_h = max(16, (_fp_vis / _fp_count) * _fp_h);
    var _fp_bar_y = _fp_pick_y + (fx_picker_scroll / max(1, _fp_count - _fp_vis)) * (_fp_h - _fp_bar_h);
    var _fp_bar_hov = (_mx >= _fp_sb_x && _mx <= _fp_sb_x + _fp_sb_w && _my >= _fp_bar_y && _my <= _fp_bar_y + _fp_bar_h);

    // Rows (hover zone stops before scrollbar)
    for (var _fi = 0; _fi < _fp_vis; _fi++) {
        var _idx = fx_picker_scroll + _fi;
        if (_idx >= _fp_count) break;
        var _iy     = _fp_pick_y + _fi * _fp_item_h;
        var _is_cur = (_fp_ids[_idx] == _cur_fx2);
        var _is_hov = (_mx > _fp_btn_x && _mx < _fp_sb_x && _my > _iy && _my < _iy + _fp_item_h);
        if (_is_cur)      { draw_set_color(make_color_rgb(70, 210, 180)); draw_rectangle(_fp_btn_x+1, _iy+1, _fp_sb_x-1, _iy+_fp_item_h-1, false); }
        else if (_is_hov) { draw_set_color(make_color_rgb(50, 50, 75));   draw_rectangle(_fp_btn_x+1, _iy+1, _fp_sb_x-1, _iy+_fp_item_h-1, false); }
        draw_set_color(_is_cur ? c_black : c_white);
        draw_text(_fp_btn_x + 8, _iy + 4, _fp_labels[_idx]);
        // Divider line (stops before scrollbar)
        if (_fi < _fp_vis - 1) {
            draw_set_color(make_color_rgb(50, 50, 70));
            draw_line(_fp_btn_x + 2, _iy + _fp_item_h, _fp_sb_x - 2, _iy + _fp_item_h);
        }
    }

    // Scrollbar track + bar
    draw_set_color(make_color_rgb(15, 15, 25));
    draw_rectangle(_fp_sb_x, _fp_pick_y, _fp_sb_x + _fp_sb_w, _fp_pick_y + _fp_h, false);
    draw_set_color(fx_picker_sb_dragging ? make_color_rgb(130, 210, 230) : (_fp_bar_hov ? make_color_rgb(100, 175, 200) : make_color_rgb(65, 110, 140)));
    draw_rectangle(_fp_sb_x + 1, _fp_bar_y, _fp_sb_x + _fp_sb_w - 1, _fp_bar_y + _fp_bar_h, false);

    draw_set_halign(fa_left);
}
