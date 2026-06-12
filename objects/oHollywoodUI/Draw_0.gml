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
                
                var _clut = [c_white, c_black, c_red, c_yellow, c_blue, c_green, c_orange, c_purple, c_aqua, c_fuchsia];
                var _c = (_color_idx >= 0 && _color_idx < array_length(_clut)) ? _clut[_color_idx] : c_white;
                var _scl = [2.0, 2.5, 3.0][clamp(_size, 0, 2)];
                
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

// --- SCENE TRANSITION OVERLAY FUNCTION ---
var _draw_scene_transition = function(_x1, _y1, _x2, _y2) {
    if (!scene_transition_active && scene_transition_progress <= 0.0) return;
    var _tp = (scene_transition_dir == "out") ? scene_transition_progress : (1.0 - scene_transition_progress);
    _tp = clamp(_tp, 0.0, 1.0);
    _tp = _tp * _tp * (3.0 - 2.0 * _tp); // smoothstep easing
    if (_tp <= 0) return;
    var _cx = (_x1 + _x2) * 0.5;
    var _cy = (_y1 + _y2) * 0.5;
    draw_set_color(c_black);
    if (scene_transition_type == "fade") {
        draw_set_alpha(_tp);
        draw_rectangle(_x1, _y1, _x2, _y2, false);
        draw_set_alpha(1.0);
    } else if (scene_transition_type == "iris") {
        var _max_r = point_distance(_cx, _cy, _x2, _y2) + 10;
        var _r = _max_r * (1.0 - _tp);
        draw_set_alpha(1.0);
        if (_r < 1) {
            draw_rectangle(_x1, _y1, _x2, _y2, false);
        } else {
            var _segs = 64;
            draw_primitive_begin(pr_trianglelist);
            for (var _tsi = 0; _tsi < _segs; _tsi++) {
                var _a1t = (_tsi       / _segs) * (2 * pi);
                var _a2t = ((_tsi + 1) / _segs) * (2 * pi);
                var _ix1t = _cx + cos(_a1t) * _r;            var _iy1t = _cy + sin(_a1t) * _r;
                var _ix2t = _cx + cos(_a2t) * _r;            var _iy2t = _cy + sin(_a2t) * _r;
                var _ox1t = _cx + cos(_a1t) * (_max_r + 20); var _oy1t = _cy + sin(_a1t) * (_max_r + 20);
                var _ox2t = _cx + cos(_a2t) * (_max_r + 20); var _oy2t = _cy + sin(_a2t) * (_max_r + 20);
                draw_vertex(_ix1t, _iy1t); draw_vertex(_ox1t, _oy1t); draw_vertex(_ox2t, _oy2t);
                draw_vertex(_ix1t, _iy1t); draw_vertex(_ox2t, _oy2t); draw_vertex(_ix2t, _iy2t);
            }
            draw_primitive_end();
        }
    } else if (scene_transition_type == "wipe_left") {
        draw_set_alpha(1.0);
        draw_rectangle(_x1, _y1, _x1 + (_x2 - _x1) * _tp, _y2, false);
    } else if (scene_transition_type == "wipe_right") {
        draw_set_alpha(1.0);
        draw_rectangle(_x2 - (_x2 - _x1) * _tp, _y1, _x2, _y2, false);
    } else if (scene_transition_type == "wipe_top") {
        draw_set_alpha(1.0);
        draw_rectangle(_x1, _y1, _x2, _y1 + (_y2 - _y1) * _tp, false);
    } else if (scene_transition_type == "wipe_bottom") {
        draw_set_alpha(1.0);
        draw_rectangle(_x1, _y2 - (_y2 - _y1) * _tp, _x2, _y2, false);
    } else if (scene_transition_type == "barn_door") {
        draw_set_alpha(1.0);
        var _hw_tr = (_x2 - _x1) * 0.5;
        draw_rectangle(_x1, _y1, _x1 + _hw_tr * _tp, _y2, false);
        draw_rectangle(_x2 - _hw_tr * _tp, _y1, _x2, _y2, false);
    }
    draw_set_alpha(1.0);
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
				var _idle_layers = get_composite_character_sprite(_act.char_index, _pose, _expr, _aface);
				var _csw = (_idle_layers[0].spr != -1) ? sprite_get_width(_idle_layers[0].spr) : sprite_get_width(_spr);
				var _csh = sprite_get_height(_spr);
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
				var _is_decap_dr  = variable_struct_exists(_act, "is_decapitated") && _act.is_decapitated;
				var _decap_mode_dr = _is_decap_dr ? (variable_struct_exists(_act, "decap_mode") ? _act.decap_mode : "remove_head") : "";
				var _is_kd_dr     = variable_struct_exists(_act, "is_knocked_down") && _act.is_knocked_down;
				var _dangle_dr    = _is_kd_dr ? (variable_struct_exists(_act, "knock_angle") ? _act.knock_angle : 0) : 0;
				var _is_injured_dr = false;
				for (var _li = 0; _li < array_length(_layers); _li++) {
					var _l       = _layers[_li];
					// remove_head: skip head layers (face=1, mouth=2, eyes=3); remove_body: skip body layer (index 0)
					if (_is_decap_dr && _decap_mode_dr == "remove_head" && _li > 0) {
						array_push(_final_layers, { spr: -1, dx: _l.dx, dy: _l.dy });
						continue;
					}
					if (_is_decap_dr && _decap_mode_dr == "remove_body" && _li == 0) {
						array_push(_final_layers, { spr: -1, dx: _l.dx, dy: _l.dy });
						continue;
					}
					_is_injured_dr = _is_decap_dr || _is_kd_dr;
					var _mouth_blocked_dr = (_is_decap_dr && _decap_mode_dr != "remove_body");
					var _is_anim = variable_struct_exists(_l, "is_mouth") && _has_manim && _mouth_open && !_mouth_blocked_dr;
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
				if (_is_kd_dr && _dangle_dr != 0) {
					var _rpx_dr; var _rpy_dr;
					_rpx_dr = (target_surface == -1) ? (_stg_x + _ax) : _ax;
					_rpy_dr = (target_surface == -1) ? (_stg_y + _ay + _y_off) : (_ay + _y_off);
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
					var _inj_sel = _is_injured_dr && (target_surface == -1) && (_act.char_index == selected_character_index) && playing_block_index == -1;
					draw_composite_character_ext(_final_layers, _draw_x, _draw_y, _asc, 1, c_white, _inj_sel, 3, make_color_rgb(200, 100, 30), _clip);
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
            var _td_is_rb = variable_struct_exists(_tdh, "decap_mode") && _tdh.decap_mode == "remove_body";
            var _tdlys = get_composite_character_sprite(_tdh.char_index, _tdh.pose, _tdh.expression, _tdh.facing);
            var _tdbwpx = (_tdlys[0].spr != -1) ? sprite_get_width(_tdlys[0].spr) : 80;
            var _tdbhpx = (_tdlys[0].spr != -1) ? sprite_get_height(_tdlys[0].spr) : 200;
            var _td_neck_bx = _tdbwpx * 0.5;
            var _td_neck_by = _tdbhpx * 0.75;
            var _tdx = _stage_x + (_tdh.x - scene_win_x) * _th_psx;
            var _tdy = _stage_y + (_tdh.y - scene_win_y) * _th_psy;
            var _td_hcos = dcos(_tdh.angle); var _td_hsin = dsin(_tdh.angle);
            draw_set_alpha(_tdh.alpha);
            if (_td_is_rb) {
                // remove_body: fly the body layer (index 0), pivot at its centre
                var _tb0 = _tdlys[0];
                if (_tb0.spr != -1) {
                    var _tb0w = sprite_get_width(_tb0.spr); var _tb0h = sprite_get_height(_tb0.spr);
                    var _tb0x = _tdx + (_tb0.dx - _td_neck_bx) * _th_asc;
                    var _tb0y = _tdy + (_tb0.dy - _td_neck_by) * _th_asc;
                    var _tb_piv_x = _tb0x + _tb0w * _th_asc * 0.5;
                    var _tb_piv_y = _tb0y + _tb0h * _th_asc * 0.5;
                    var _tox = _tb0x - _tb_piv_x; var _toy = _tb0y - _tb_piv_y;
                    var _tsx_b = _tb_piv_x + _tox * _td_hcos + _toy * _td_hsin;
                    var _tsy_b = _tb_piv_y - _tox * _td_hsin + _toy * _td_hcos;
                    draw_sprite_ext(_tb0.spr, 0, _tsx_b, _tsy_b, _th_asc, _th_asc, _tdh.angle, c_white, _tdh.alpha);
                }
            } else {
                // remove_head: fly head layers (face=1, mouth=2, eyes=3), pivot at face centre
                var _td_face = _tdlys[1];
                var _td_piv_x = _tdx + ((_td_face.spr != -1 ? _td_face.dx + sprite_get_width(_td_face.spr) * 0.5 : _td_neck_bx) - _td_neck_bx) * _th_asc;
                var _td_piv_y = _tdy + ((_td_face.spr != -1 ? _td_face.dy + sprite_get_height(_td_face.spr) * 0.5 : _td_neck_by) - _td_neck_by) * _th_asc;
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
    if      (_active_fx == "fog")         draw_fx_overlay(shFog,         _stage_x, _stage_y, _stage_w, _stage_h, bm_normal);
    else if (_active_fx == "rain")        draw_fx_overlay(shRain,        _stage_x, _stage_y, _stage_w, _stage_h, bm_normal);
    else if (_active_fx == "snow")        draw_fx_overlay(shSnow,        _stage_x, _stage_y, _stage_w, _stage_h, bm_normal);
    else if (_active_fx == "embers")      draw_fx_overlay(shEmbers,      _stage_x, _stage_y, _stage_w, _stage_h, bm_add);
    else if (_active_fx == "static")      draw_fx_overlay(shStatic,      _stage_x, _stage_y, _stage_w, _stage_h, bm_normal);
    else if (_active_fx == "heat")        draw_fx_distort(shHeat,        _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "moonlight")   draw_fx_distort(shMoonlight,   _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "sunlight")    draw_fx_distort(shSunlight,    _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "filth")       draw_fx_distort(shFilth,       _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "candlelight") draw_fx_distort(shCandlelight, _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "crt")         draw_fx_distort(shCRT,         _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "frigid")      draw_fx_distort(shFrigid,      _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "goldenhour")  draw_fx_distort(shGoldenHour,  _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "darken")      draw_fx_distort(shDarken,      _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "blackwhite")  draw_fx_distort(shBlackWhite,  _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "brighten")    draw_fx_distort(shBrighten,    _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "dream")       draw_fx_distort(shDream,       _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "drunk")       draw_fx_distort(shDrunk,       _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "stoned")      draw_fx_distort(shStoned,      _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "underwater")  draw_fx_distort(shUnderwater,  _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "nightvision") draw_fx_distort(shNightVision, _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "infrared")    draw_fx_distort(shInfrared,    _stage_x, _stage_y, _stage_w, _stage_h);
    else if (_active_fx == "sepia")       draw_fx_distort(shSepia,       _stage_x, _stage_y, _stage_w, _stage_h);

    // --- Scene Transition Overlay (theater) ---
    if (scene_transition_active || scene_transition_progress > 0) {
        var _ov_x1 = floor(_stage_x); var _ov_y1 = floor(_stage_y);
        var _ov_x2 = ceil(_stage_x + _stage_w); var _ov_y2 = ceil(_stage_y + _stage_h);
        gpu_set_scissor(_ov_x1, _ov_y1, _ov_x2 - _ov_x1, _ov_y2 - _ov_y1);
        _draw_scene_transition(_ov_x1, _ov_y1, _ov_x2, _ov_y2);
        gpu_set_scissor(0, 0, 1280, 960);
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

if (script_expanded || scene_edit_mode) {
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
					var _idle_layers = get_composite_character_sprite(_act.char_index, _pose, _expr, _aface);
					var _csw = (_idle_layers[0].spr != -1) ? sprite_get_width(_idle_layers[0].spr) : sprite_get_width(_spr);
					var _csh = sprite_get_height(_spr);
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

					var _is_decap_ed   = variable_struct_exists(_act, "is_decapitated") && _act.is_decapitated;
					var _decap_mode_ed = _is_decap_ed ? (variable_struct_exists(_act, "decap_mode") ? _act.decap_mode : "remove_head") : "";
					var _is_kd_ed      = variable_struct_exists(_act, "is_knocked_down") && _act.is_knocked_down;
					var _dangle_ed     = _is_kd_ed ? (variable_struct_exists(_act, "knock_angle") ? _act.knock_angle : 0) : 0;
					var _is_injured_ed = _is_decap_ed || _is_kd_ed;
					var _final_layers = [];
					for (var _li = 0; _li < array_length(_layers); _li++) {
						var _l       = _layers[_li];
						if (_is_decap_ed && _decap_mode_ed == "remove_head" && _li > 0) {
							array_push(_final_layers, { spr: -1, dx: _l.dx, dy: _l.dy });
							continue;
						}
						if (_is_decap_ed && _decap_mode_ed == "remove_body" && _li == 0) {
							array_push(_final_layers, { spr: -1, dx: _l.dx, dy: _l.dy });
							continue;
						}
						var _mouth_blocked_ed = (_is_decap_ed && _decap_mode_ed != "remove_body");
						var _is_anim = variable_struct_exists(_l, "is_mouth") && _has_manim && _mouth_open && !_mouth_blocked_ed;
						var _ae      = _is_anim ? _mouth_anim[_manim_fi] : undefined;
						var _lspr    = _is_anim ? _ae.spr : _l.spr;
						if (_li == 0 && (variable_struct_exists(_act, "canned_composite_legs") && !_act.canned_composite_legs)) {
							_lspr = -1;
						}
						var _ldx     = _l.dx + (_is_anim ? _ae.dx : 0);
						var _ldy     = _l.dy + (_is_anim ? _ae.dy : 0);
						array_push(_final_layers, { spr: _lspr, dx: _ldx, dy: _ldy });
					}

					// Outline: yellow for normal+selected, orange for injured+selected
					if (_draw_outline && playing_block_index == -1 && selected_character_index == _act.char_index) {
						var _outline_col = _is_injured_ed ? make_color_rgb(220, 120, 30) : c_yellow;
						var _os = _sc * 1.18;
						var _ol_rpx_ed; var _ol_rpy_ed;
						_ol_rpx_ed = (target_surface == -1) ? (scene_win_x + _act.x) : _act.x;
						_ol_rpy_ed = (target_surface == -1) ? (scene_win_y + _act.y + _y_off) : (_act.y + _y_off);
						var _ol_cos_ed = dcos(_dangle_ed); var _ol_sin_ed = dsin(_dangle_ed);
						for (var _oli = 0; _oli < array_length(_final_layers); _oli++) {
							var _ol = _final_layers[_oli];
							if (_ol.spr != -1) {
								var _lw = sprite_get_width(_ol.spr);
								var _lh = sprite_get_height(_ol.spr);
								var _olx = _draw_x + _ol.dx * _sc - _lw * (_os - _sc) * 0.5;
								var _oly = _draw_y + _ol.dy * _sc - _lh * (_os - _sc) * 0.5;
								if (_dangle_ed != 0) {
									var _ovx = _olx - _ol_rpx_ed; var _ovy = _oly - _ol_rpy_ed;
									_olx = _ol_rpx_ed + _ovx * _ol_cos_ed + _ovy * _ol_sin_ed;
									_oly = _ol_rpy_ed - _ovx * _ol_sin_ed + _ovy * _ol_cos_ed;
								}
								draw_sprite_ext(_ol.spr, 0, _olx, _oly, _os, _os, _dangle_ed, _outline_col, _alpha);
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
						} else if (_is_kd_ed && _dangle_ed != 0) {
							var _rpx_ed; var _rpy_ed;
							_rpx_ed = (target_surface == -1) ? (scene_win_x + _act.x) : _act.x;
							_rpy_ed = (target_surface == -1) ? (scene_win_y + _act.y + _y_off) : (_act.y + _y_off);
							var _cos_ed = dcos(_dangle_ed); var _sin_ed = dsin(_dangle_ed);
							for (var _rli_ed = 0; _rli_ed < array_length(_final_layers); _rli_ed++) {
								var _rl_ed = _final_layers[_rli_ed];
								if (_rl_ed.spr == -1) continue;
								var _vx_ed = (_draw_x + _rl_ed.dx * _sc) - _rpx_ed;
								var _vy_ed = (_draw_y + _rl_ed.dy * _sc) - _rpy_ed;
								var _rx_ed = _rpx_ed + _vx_ed * _cos_ed + _vy_ed * _sin_ed;
								var _ry_ed = _rpy_ed - _vx_ed * _sin_ed + _vy_ed * _cos_ed;
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
								var _inj_sel_ed = _is_injured_ed && (target_surface == -1) && (_act.char_index == selected_character_index) && playing_block_index == -1;
								draw_composite_character_ext(_final_layers, _draw_x, _draw_y, _sc, _alpha, c_white, _inj_sel_ed, 3, make_color_rgb(200, 100, 30), _clip);
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
			var _dh_is_rb = variable_struct_exists(_dh, "decap_mode") && _dh.decap_mode == "remove_body";
			var _dlys = get_composite_character_sprite(_dh.char_index, _dh.pose, _dh.expression, _dh.facing);
			var _dbwpx = (_dlys[0].spr != -1) ? sprite_get_width(_dlys[0].spr) : 80;
			var _dbhpx = (_dlys[0].spr != -1) ? sprite_get_height(_dlys[0].spr) : 200;
			var _neck_bx = _dbwpx * 0.5;
			var _neck_by = _dbhpx * 0.75;
			var _hcos = dcos(_dh.angle); var _hsin = dsin(_dh.angle);
			draw_set_alpha(_dh.alpha);
			if (_dh_is_rb) {
				// remove_body: fly the body layer (index 0), pivot at its centre
				var _db0 = _dlys[0];
				if (_db0.spr != -1) {
					var _db0w = sprite_get_width(_db0.spr); var _db0h = sprite_get_height(_db0.spr);
					var _db0x = _dh.x + (_db0.dx - _neck_bx) * _dasc;
					var _db0y = _dh.y + (_db0.dy - _neck_by) * _dasc;
					var _db_piv_x = _db0x + _db0w * _dasc * 0.5;
					var _db_piv_y = _db0y + _db0h * _dasc * 0.5;
					var _dox = _db0x - _db_piv_x; var _doy = _db0y - _db_piv_y;
					var _dsx_b = _db_piv_x + _dox * _hcos + _doy * _hsin;
					var _dsy_b = _db_piv_y - _dox * _hsin + _doy * _hcos;
					draw_sprite_ext(_db0.spr, 0, _dsx_b + scene_win_x, _dsy_b + scene_win_y, _dasc, _dasc, _dh.angle, c_white, _dh.alpha);
				}
			} else {
				// remove_head: fly head layers (face=1, mouth=2, eyes=3), pivot at face centre
				var _face_lyr = _dlys[1];
				var _piv_x = _dh.x + ((_face_lyr.spr != -1 ? _face_lyr.dx + sprite_get_width(_face_lyr.spr) * 0.5 : _neck_bx) - _neck_bx) * _dasc;
				var _piv_y = _dh.y + ((_face_lyr.spr != -1 ? _face_lyr.dy + sprite_get_height(_face_lyr.spr) * 0.5 : _neck_by) - _neck_by) * _dasc;
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
			if (variable_struct_exists(_oact, "hidden") && _oact.hidden) continue;
			if (real(_oact.char_index) != real(selected_character_index)) continue;
			if (dragging_preview_idx != -1 && dragging_preview_idx < array_length(preview_actors) && preview_actors[dragging_preview_idx].char_index == _oact.char_index) continue;

			var _opose  = variable_struct_exists(_oact, "pose")       ? _oact.pose       : 1;
			var _oexpr  = variable_struct_exists(_oact, "expression") ? _oact.expression : 21;
			var _oface  = variable_struct_exists(_oact, "facing")     ? _oact.facing     : undefined;
			var _oy_off = variable_struct_exists(_oact, "y_offset")   ? _oact.y_offset   : 0;
			var _idle_layers = get_composite_character_sprite(_oact.char_index, _opose, _oexpr, _oface);
			if (_idle_layers[0].spr == -1) break;

			// Injury state for shape/orientation matching
			var _o_is_decap = variable_struct_exists(_oact, "is_decapitated") && _oact.is_decapitated;
			var _o_decap_mode = _o_is_decap ? (variable_struct_exists(_oact, "decap_mode") ? _oact.decap_mode : "remove_head") : "";
			var _o_is_kd     = variable_struct_exists(_oact, "is_knocked_down") && _oact.is_knocked_down;
			var _o_kangle    = _o_is_kd ? (variable_struct_exists(_oact, "knock_angle") ? _oact.knock_angle : 0) : 0;


			var _olayers = [];
			var _is_canned = variable_struct_exists(_oact, "canned_spr") && _oact.canned_spr != -1;
			if (_is_canned) {
			    var _canned_ay_o = variable_struct_exists(_oact, "canned_anchor_y") ? _oact.canned_anchor_y : 0;
			    var _feet_spr_o  = (variable_struct_exists(_oact, "canned_composite") && _oact.canned_composite && variable_struct_exists(_oact, "canned_feet_spr") && _oact.canned_feet_spr != -1) ? _oact.canned_feet_spr : -1;
			    if (_feet_spr_o != -1) {
			        var _canned_h_o  = sprite_get_height(_oact.canned_spr);
			        var _body_dy_o   = variable_struct_exists(_oact, "canned_body_dy") ? _oact.canned_body_dy : 0;
			        var _body_dx_o   = variable_struct_exists(_oact, "canned_body_dx") ? _oact.canned_body_dx : 0;
			        var _composite_legs_o = !variable_struct_exists(_oact, "canned_composite_legs") || _oact.canned_composite_legs;
			        var _dy_val_o = -_canned_h_o + _canned_ay_o + _body_dy_o;
			        if (!_composite_legs_o) {
			            var _feet_h_o = sprite_get_height(_feet_spr_o);
			            _dy_val_o = _feet_h_o - _canned_h_o + _canned_ay_o + _body_dy_o;
			        }
			        _olayers = [{ spr: _feet_spr_o, dx: 0, dy: 0 }, { spr: _oact.canned_spr, dx: _body_dx_o, dy: _dy_val_o }, { spr: -1, dx: 0, dy: 0 }, { spr: -1, dx: 0, dy: 0 }];
			    } else {
			        var _body_dy_o   = variable_struct_exists(_oact, "canned_body_dy") ? _oact.canned_body_dy : 0;
			        var _body_dx_o   = variable_struct_exists(_oact, "canned_body_dx") ? _oact.canned_body_dx : 0;
			        _olayers = [{ spr: _oact.canned_spr, dx: _body_dx_o, dy: _canned_ay_o + _body_dy_o }, { spr: -1, dx: 0, dy: 0 }, { spr: -1, dx: 0, dy: 0 }, { spr: -1, dx: 0, dy: 0 }];
			    }
			} else {
			    // Apply decap layer filtering to match rendered shape
			    for (var _oli_f = 0; _oli_f < array_length(_idle_layers); _oli_f++) {
			        var _ol_f = _idle_layers[_oli_f];
			        if (_o_is_decap && _o_decap_mode == "remove_head" && _oli_f > 0) {
			            array_push(_olayers, { spr: -1, dx: _ol_f.dx, dy: _ol_f.dy });
			        } else if (_o_is_decap && _o_decap_mode == "remove_body" && _oli_f == 0) {
			            array_push(_olayers, { spr: -1, dx: _ol_f.dx, dy: _ol_f.dy });
			        } else {
			            array_push(_olayers, _ol_f);
			        }
			    }
			}

			var _ocsw = sprite_get_width(_idle_layers[0].spr);
			var _ocsh = sprite_get_height(_idle_layers[0].spr);
			var _osc  = (scene_win_h * 1.5) / 450;
			// Local surface coords (no scene_win offset — applied when drawing the surface)
			var _sdx = _oact.x - (_ocsw * _osc) / 2;
			var _sdy = _oact.y - (_ocsh * _osc) + _oy_off;

			if (_is_canned) {
			    if (variable_struct_exists(_oact, "canned_composite_legs") && !_oact.canned_composite_legs) {
			        _olayers[0].spr = -1;
			    }
			}

			// Compute rotation pivot for knocked-down state (surface-local coords)
			var _o_do_rotate = (_o_is_kd && _o_kangle != 0);
			var _o_rpx = _oact.x; var _o_rpy = _oact.y + _oy_off;
			var _o_cos = dcos(_o_kangle); var _o_sin = dsin(_o_kangle);

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
					    var _lx_o = _sdx + _ol.dx * _osc + _ooffs[_oi][0];
					    var _ly_o = _sdy + _ol.dy * _osc + _ooffs[_oi][1];
					    if (_o_do_rotate) {
					        var _ovx_o = _lx_o - _o_rpx; var _ovy_o = _ly_o - _o_rpy;
					        _lx_o = _o_rpx + _ovx_o * _o_cos + _ovy_o * _o_sin;
					        _ly_o = _o_rpy - _ovx_o * _o_sin + _ovy_o * _o_cos;
					    }
						draw_sprite_ext(_ol.spr, 0, _lx_o, _ly_o, _osc, _osc, _o_kangle, c_white, 1.0);
					}
				}
			}

			// Flatten all stamped pixels to yellow (normal) or orange (injured), preserving the alpha mask
			gpu_set_colorwriteenable(true, true, true, false);
			draw_set_color((_o_is_kd || _o_is_decap) ? make_color_rgb(220, 120, 30) : c_yellow);
			draw_rectangle(0, 0, scene_win_w, scene_win_h, false);
			gpu_set_colorwriteenable(true, true, true, true);

			// Punch a hole where the character actually is
			gpu_set_blendmode_ext(bm_zero, bm_inv_src_alpha);
			for (var _li2 = 0; _li2 < array_length(_olayers); _li2++) {
				var _ol2 = _olayers[_li2];
				if (_ol2.spr != -1) {
				    var _lx_o2 = _sdx + _ol2.dx * _osc;
				    var _ly_o2 = _sdy + _ol2.dy * _osc;
				    if (_o_do_rotate) {
				        var _ovx_o2 = _lx_o2 - _o_rpx; var _ovy_o2 = _ly_o2 - _o_rpy;
				        _lx_o2 = _o_rpx + _ovx_o2 * _o_cos + _ovy_o2 * _o_sin;
				        _ly_o2 = _o_rpy - _ovx_o2 * _o_sin + _ovy_o2 * _o_cos;
				    }
					draw_sprite_ext(_ol2.spr, 0, _lx_o2, _ly_o2, _osc, _osc, _o_kangle, c_white, 1.0);
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

    // --- Scene Transition Overlay (editor preview) ---
    if (active_scene_block_idx != -1 && (scene_transition_active || scene_transition_progress > 0) && playing_block_index != -1) {
        gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
        _draw_scene_transition(scene_win_x, scene_win_y, scene_win_x + scene_win_w, scene_win_y + scene_win_h);
        gpu_set_scissor(0, 0, 1280, 960);
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

    // --- IN / OUT Transition Buttons ---
    var _tr_names_d  = ["none","fade","iris","wipe_left","wipe_right","wipe_top","wipe_bottom","barn_door"];
    var _tr_labels_d = ["NONE","FADE","IRIS *","WIPE >","< WIPE","v WIPE","WIPE ^","BARN DR"];
    var _tin_id_d    = variable_struct_exists(_sfx_scene, "transition_in")  ? _sfx_scene.transition_in  : "none";
    var _tout_id_d   = variable_struct_exists(_sfx_scene, "transition_out") ? _sfx_scene.transition_out : "none";
    var _in_btn_xd   = _fx_btn_x + _fx_btn_w + 10; var _in_btn_wd  = 88;
    var _out_btn_xd  = _in_btn_xd + _in_btn_wd + 5; var _out_btn_wd = 90;
    var _in_on_d  = (_tin_id_d  != "none");
    var _out_on_d = (_tout_id_d != "none");
    var _in_hov_d  = (!_overlay_active && !trans_in_picker_open && !trans_out_picker_open && !fx_picker_open
                     && _mx > _in_btn_xd  && _mx < _in_btn_xd  + _in_btn_wd  && _my > scene_win_y - 45 && _my < scene_win_y - 10);
    var _out_hov_d = (!_overlay_active && !trans_in_picker_open && !trans_out_picker_open && !fx_picker_open
                     && _mx > _out_btn_xd && _mx < _out_btn_xd + _out_btn_wd && _my > scene_win_y - 45 && _my < scene_win_y - 10);
    // IN button
    draw_set_color(trans_in_picker_open ? make_color_rgb(35,70,35) : (_in_on_d ? make_color_rgb(18,90,40) : (_in_hov_d ? make_color_rgb(28,55,28) : make_color_rgb(18,32,18))));
    draw_roundrect_ext(_in_btn_xd, scene_win_y-45, _in_btn_xd+_in_btn_wd, scene_win_y-10, 5,5, false);
    draw_set_color(trans_in_picker_open ? make_color_rgb(70,150,70) : (_in_on_d ? make_color_rgb(50,185,90) : (_in_hov_d ? c_white : make_color_rgb(45,95,45))));
    draw_roundrect_ext(_in_btn_xd, scene_win_y-45, _in_btn_xd+_in_btn_wd, scene_win_y-10, 5,5, true);
    var _in_cur_lbl_d = "NONE";
    for (var _trid = 0; _trid < array_length(_tr_names_d); _trid++) { if (_tr_names_d[_trid] == _tin_id_d) { _in_cur_lbl_d = _tr_labels_d[_trid]; break; } }
    draw_set_color(_in_on_d ? make_color_rgb(90,230,120) : c_white);
    var _in_str_d = "IN: " + _in_cur_lbl_d + " v";
    var _in_lbl_sc_d = min(1.0, (_in_btn_wd - 10) / max(1, string_width(_in_str_d)));
    draw_set_halign(fa_center); draw_text_transformed(_in_btn_xd + _in_btn_wd/2, scene_win_y-37, _in_str_d, _in_lbl_sc_d, 1.0, 0); draw_set_halign(fa_left);
    // OUT button
    draw_set_color(trans_out_picker_open ? make_color_rgb(70,35,35) : (_out_on_d ? make_color_rgb(100,40,18) : (_out_hov_d ? make_color_rgb(60,28,28) : make_color_rgb(32,18,18))));
    draw_roundrect_ext(_out_btn_xd, scene_win_y-45, _out_btn_xd+_out_btn_wd, scene_win_y-10, 5,5, false);
    draw_set_color(trans_out_picker_open ? make_color_rgb(160,70,70) : (_out_on_d ? make_color_rgb(200,95,55) : (_out_hov_d ? c_white : make_color_rgb(100,50,50))));
    draw_roundrect_ext(_out_btn_xd, scene_win_y-45, _out_btn_xd+_out_btn_wd, scene_win_y-10, 5,5, true);
    var _out_cur_lbl_d = "NONE";
    for (var _trid2 = 0; _trid2 < array_length(_tr_names_d); _trid2++) { if (_tr_names_d[_trid2] == _tout_id_d) { _out_cur_lbl_d = _tr_labels_d[_trid2]; break; } }
    draw_set_color(_out_on_d ? make_color_rgb(230,120,90) : c_white);
    var _out_str_d = "OUT: " + _out_cur_lbl_d + " v";
    var _out_lbl_sc_d = min(1.0, (_out_btn_wd - 10) / max(1, string_width(_out_str_d)));
    draw_set_halign(fa_center); draw_text_transformed(_out_btn_xd + _out_btn_wd/2, scene_win_y-37, _out_str_d, _out_lbl_sc_d, 1.0, 0); draw_set_halign(fa_left);
    // Picker dropdowns drawn at end of event so they render above script blocks
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
        var _is_kd_flip = false;
        for (var _fci2 = 0; _fci2 < array_length(preview_actors); _fci2++) {
            if (preview_actors[_fci2].char_index == selected_character_index) {
                _is_kd_flip = variable_struct_exists(preview_actors[_fci2], "is_knocked_down") && preview_actors[_fci2].is_knocked_down;
                break;
            }
        }
        draw_set_color(_fhov ? c_white : make_color_rgb(160, 160, 255));
        draw_set_halign(fa_center);
        draw_text(_fx + (_fw / 2), _fy + 5, _is_kd_flip ? "ROLL OVER" : "TURN AROUND");
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
        // Find injury state for this character from preview_actors
        var _ch_pa_kd    = false;
        var _ch_pa_kdir  = "forwards";
        var _ch_pa_decap = false;
        var _ch_pa_dmode = "remove_head";
        var _ch_pa_facing = 1;
        for (var _dpa = 0; _dpa < array_length(preview_actors); _dpa++) {
            var _dpa_act = preview_actors[_dpa];
            if (_dpa_act.char_index == i) {
                _ch_pa_kd     = variable_struct_exists(_dpa_act, "is_knocked_down") && _dpa_act.is_knocked_down;
                _ch_pa_kdir   = _ch_pa_kd ? (variable_struct_exists(_dpa_act, "knock_direction") ? _dpa_act.knock_direction : "forwards") : "forwards";
                _ch_pa_facing = variable_struct_exists(_dpa_act, "facing") ? _dpa_act.facing : 1;
                _ch_pa_decap  = variable_struct_exists(_dpa_act, "is_decapitated") && _dpa_act.is_decapitated;
                _ch_pa_dmode  = _ch_pa_decap ? (variable_struct_exists(_dpa_act, "decap_mode") ? _dpa_act.decap_mode : "remove_head") : "remove_head";
                break;
            }
        }
        // Draw with actual injury state — filtered layers for decap, rotated for knocked-down
        var _ch_clip = [char_sel_x + 2, char_sel_y + 30, char_sel_w - 4, char_sel_h - 35];
        if (_ch_pa_kd) {
            var _kangle_ch = (_ch_pa_kdir == "forwards") ? (_ch_pa_facing * 90) : (-_ch_pa_facing * 90);
            var _dcos_ch = dcos(_kangle_ch); var _dsin_ch = dsin(_kangle_ch);
            // Pivot: face-centre for lone head (remove_body), otherwise center of tile
            // After 90° rotation the character lies flat — center pivot in tile so they appear centered
            var _rpx_ch, _rpy_ch;
            var _tile_cx = _ix + (_item_w - 5) / 2;
            var _tile_cy = _iy + 30 + (_item_h - 52) / 2; // center of drawable area above name label
            if (_ch_pa_decap && _ch_pa_dmode == "remove_body" && _ch_layers[1].spr != -1) {
                // Lone head: pivot at face-centre in upright position, then center that in the tile
                _rpx_ch = _sx + (_ch_layers[1].dx + sprite_get_width(_ch_layers[1].spr) * 0.5) * _sc;
                _rpy_ch = _sy + (_ch_layers[1].dy + sprite_get_height(_ch_layers[1].spr) * 0.5) * _sc;
            } else {
                // Full body or headless: pivot at horizontal center, vertical center of tile
                // so the rotated body fills the tile symmetrically
                _rpx_ch = _tile_cx;
                _rpy_ch = _tile_cy;
            }
            gpu_set_scissor(_ch_clip[0], _ch_clip[1], _ch_clip[2], _ch_clip[3]);
            for (var _cli = 0; _cli < array_length(_ch_layers); _cli++) {
                var _cll = _ch_layers[_cli];
                if (_cll.spr == -1) continue;
                if (_ch_pa_decap && _ch_pa_dmode == "remove_head" && _cli > 0) continue;
                if (_ch_pa_decap && _ch_pa_dmode == "remove_body" && _cli == 0) continue;
                var _lx_ch = _sx + _cll.dx * _sc;
                var _ly_ch = _sy + _cll.dy * _sc;
                var _vx_ch = _lx_ch - _rpx_ch; var _vy_ch = _ly_ch - _rpy_ch;
                var _rx_ch = _rpx_ch + _vx_ch * _dcos_ch + _vy_ch * _dsin_ch;
                var _ry_ch = _rpy_ch - _vx_ch * _dsin_ch + _vy_ch * _dcos_ch;
                draw_sprite_ext(_cll.spr, 0, _rx_ch, _ry_ch, _sc, _sc, _kangle_ch, c_white, _alpha);
            }
            gpu_set_scissor(char_sel_x + 2, char_sel_y + 30, char_sel_w - 4, char_sel_h - 35);
        } else if (_ch_pa_decap) {
            // Decapitated: draw only visible layers
            gpu_set_scissor(_ch_clip[0], _ch_clip[1], _ch_clip[2], _ch_clip[3]);
            for (var _cli2 = 0; _cli2 < array_length(_ch_layers); _cli2++) {
                var _cll2 = _ch_layers[_cli2];
                if (_cll2.spr == -1) continue;
                if (_ch_pa_dmode == "remove_head" && _cli2 > 0) continue;
                if (_ch_pa_dmode == "remove_body" && _cli2 == 0) continue;
                draw_sprite_ext(_cll2.spr, 0, _sx + _cll2.dx * _sc, _sy + _cll2.dy * _sc, _sc, _sc, 0, c_white, _alpha);
            }
            gpu_set_scissor(char_sel_x + 2, char_sel_y + 30, char_sel_w - 4, char_sel_h - 35);
        } else {
            draw_composite_character_ext(_ch_layers, _sx, _sy, _sc, _alpha, c_white, false, 3, c_yellow, _ch_clip);
            gpu_set_scissor(char_sel_x + 2, char_sel_y + 30, char_sel_w - 4, char_sel_h - 35);
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
        // If knocked down, keep existing facing — head orientation must not flip during drag
        var _drag_is_kd_face = false;
        for (var _dfi = 0; _dfi < array_length(preview_actors); _dfi++) {
            if (preview_actors[_dfi].char_index == dragging_char_index) {
                _drag_is_kd_face = variable_struct_exists(preview_actors[_dfi], "is_knocked_down") && preview_actors[_dfi].is_knocked_down;
                if (_drag_is_kd_face) _drag_face = variable_struct_exists(preview_actors[_dfi], "facing") ? preview_actors[_dfi].facing : 1;
                break;
            }
        }
        if (!_drag_is_kd_face) {
            var _ghost_is_left = (_mx < scene_win_x + scene_win_w / 2);
            _drag_face = _ghost_is_left ? -1 : 1;
        }
    } else if (dragging_actor_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
        // Prefer preview_actors facing (live state); fall back to scene block actor
        var _da = script_blocks[active_scene_block_idx].actors[dragging_actor_idx];
        var _da_face_src = undefined;
        for (var _dfi2 = 0; _dfi2 < array_length(preview_actors); _dfi2++) {
            if (preview_actors[_dfi2].char_index == _da.char_index) { _da_face_src = preview_actors[_dfi2]; break; }
        }
        if (_da_face_src != undefined) {
            _drag_face = variable_struct_exists(_da_face_src, "facing") ? _da_face_src.facing : undefined;
        } else {
            _drag_face = variable_struct_exists(_da, "facing") ? _da.facing : undefined;
        }
    } else if (dragging_preview_idx != -1) {
        var _dp = preview_actors[dragging_preview_idx];
        _drag_face = variable_struct_exists(_dp, "facing") ? _dp.facing : undefined;
    }

    // Read knock-down state for the dragged actor
    var _drag_is_kd = false; var _drag_kangle = 0;
    var _drag_is_decap = false; var _drag_decap_mode = "remove_head";
    var _drag_inj_src = undefined;
    if (dragging_preview_idx != -1) {
        _drag_inj_src = preview_actors[dragging_preview_idx];
    } else if (dragging_actor_idx != -1 && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
        var _dsa = script_blocks[active_scene_block_idx].actors[dragging_actor_idx];
        // Prefer preview_actors entry (has live knock_angle); fall back to scene actor
        for (var _dpi = 0; _dpi < array_length(preview_actors); _dpi++) {
            if (preview_actors[_dpi].char_index == _dsa.char_index) { _drag_inj_src = preview_actors[_dpi]; break; }
        }
        _drag_inj_src ??= _dsa;
    } else if (dragging_char_index != -1) {
        // Look up this character's injury state from preview_actors
        for (var _dpi2 = 0; _dpi2 < array_length(preview_actors); _dpi2++) {
            if (preview_actors[_dpi2].char_index == dragging_char_index) { _drag_inj_src = preview_actors[_dpi2]; break; }
        }
    }
    if (_drag_inj_src != undefined) {
        _drag_is_kd      = variable_struct_exists(_drag_inj_src, "is_knocked_down") && _drag_inj_src.is_knocked_down;
        _drag_kangle     = _drag_is_kd ? (variable_struct_exists(_drag_inj_src, "knock_angle") ? _drag_inj_src.knock_angle : 0) : 0;
        _drag_is_decap   = variable_struct_exists(_drag_inj_src, "is_decapitated") && _drag_inj_src.is_decapitated;
        _drag_decap_mode = _drag_is_decap ? (variable_struct_exists(_drag_inj_src, "decap_mode") ? _drag_inj_src.decap_mode : "remove_head") : "remove_head";
    }

    var _layers = get_composite_character_sprite(_char_id, _pose, _expr, _drag_face);
    var _spr    = _layers[0].spr;

    if (_spr != -1) {
        var _csh = sprite_get_height(_spr);
        var _csw = sprite_get_width(_spr);
        var _scale = (scene_win_h * 1.5) / 450;

        var _px = _mx - scene_win_x - drag_off_x;
        var _py = _my - scene_win_y - drag_off_y;

        var _ax_abs = scene_win_x + _px;
        var _ay_abs = scene_win_y + _py;
        var _drag_act_state = (_drag_inj_src != undefined) ? _drag_inj_src : {};
        var _bbox_dg = get_actor_bbox(_layers, _scale, _ax_abs, _ay_abs, _drag_act_state);
        var _bb_dg_w = _bbox_dg.bb_right - _bbox_dg.bb_left;
        var _bb_dg_h = _bbox_dg.bb_bottom - _bbox_dg.bb_top;
        var _h_visible = max(0, min(_bbox_dg.bb_right, scene_win_x + scene_win_w) - max(_bbox_dg.bb_left, scene_win_x));
        var _v_visible = max(0, min(_bbox_dg.bb_bottom, scene_win_y + scene_win_h) - max(_bbox_dg.bb_top, scene_win_y));

        var _in_live = (current_scene_sprite != -1) && (_h_visible >= _bb_dg_w * 0.20) && (_v_visible >= _bb_dg_h * 0.20);
        var _color = _in_live ? c_white : c_red;
        var _alpha = _in_live ? 0.6 : 0.4;

        gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
        var _gx = scene_win_x + _px - (_csw * _scale)/2;
        var _gy = scene_win_y + _py - (_csh * _scale);

        if (_drag_is_kd && _drag_kangle != 0) {
            var _rpx_dg = scene_win_x + _px;
            var _rpy_dg = scene_win_y + _py;
            var _dcos = dcos(_drag_kangle); var _dsin = dsin(_drag_kangle);
            for (var _dgi = 0; _dgi < array_length(_layers); _dgi++) {
                var _dgl = _layers[_dgi];
                if (_dgl.spr == -1) continue;
                if (_drag_is_decap && _drag_decap_mode == "remove_head" && _dgi > 0) continue;
                if (_drag_is_decap && _drag_decap_mode == "remove_body" && _dgi == 0) continue;
                // Top-left of this layer in screen space (matches editor outline pattern)
                var _dlx = _gx + _dgl.dx * _scale;
                var _dly = _gy + _dgl.dy * _scale;
                var _dvx = _dlx - _rpx_dg; var _dvy = _dly - _rpy_dg;
                var _dlxr = _rpx_dg + _dvx * _dcos + _dvy * _dsin;
                var _dlyr = _rpy_dg - _dvx * _dsin + _dvy * _dcos;
                draw_sprite_ext(_dgl.spr, 0, _dlxr, _dlyr, _scale, _scale, _drag_kangle, _color, _alpha);
            }
        } else if (_drag_is_decap) {
            // Upright but decapitated — filter layers manually
            var _dcos_up = dcos(0); var _dsin_up = dsin(0);
            for (var _dgi2 = 0; _dgi2 < array_length(_layers); _dgi2++) {
                var _dgl2 = _layers[_dgi2];
                if (_dgl2.spr == -1) continue;
                if (_drag_decap_mode == "remove_head" && _dgi2 > 0) continue;
                if (_drag_decap_mode == "remove_body" && _dgi2 == 0) continue;
                draw_sprite_ext(_dgl2.spr, 0, _gx + _dgl2.dx * _scale, _gy + _dgl2.dy * _scale, _scale, _scale, 0, _color, _alpha);
            }
        } else {
            draw_composite_character_ext(_layers, _gx, _gy, _scale, _alpha, _color, false, 3, c_yellow, [scene_win_x, scene_win_y, scene_win_w, scene_win_h]);
        }
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
        var _is_jitter = variable_struct_exists(_block, "jitter_intensity") || (_aname_u == "JITTERS");
        var _is_injure    = variable_struct_exists(_block, "injure_style");
        var _is_stand_up  = (string_pos("STANDS UP", _aname_u) > 0);
        var _is_turn_around = (string_pos("TURNS AROUND", _aname_u) > 0);
        var _is_rolls_over  = (string_pos("ROLLS OVER",  _aname_u) > 0);
        var _is_reform      = (string_pos("REFORMS",     _aname_u) > 0);

        var _is_canned = (variable_struct_exists(_block, "char_index") && _block.char_index > 0 && canned_anim_find(_block.char_index, _block.action_name) != undefined);

        var _is_move = (string_pos("MOVE", _aname_u) > 0 || string_pos("ENTER", _aname_u) > 0 || string_pos("EXIT", _aname_u) > 0);
        var _has_looks = (string_pos("looks ", _aname_lo) > 0);
        var _has_and_pose = (_has_looks && string_pos("and pose ", _aname_lo) > 0);
        var _is_expr_only = (string_pos("expression:", _aname_lo) > 0) || (_has_looks && !_has_and_pose);
        var _is_pose = (!_is_expr_only) && (string_pos("poses ", _aname_lo) > 0 || _has_and_pose
                            || (string_pos("pose ", _aname_lo) > 0 && string_pos("poses ", _aname_lo) == 0 && !_has_looks));

        if (_is_turn_around || _is_rolls_over || _is_reform) {
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
            } else if (_is_injure) {
                _edit_lbl = "EDIT INJURY";
                _edit_w = 120;
            } else if (_is_stand_up) {
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

draw_modals();

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

// --- IN / OUT TRANSITION PICKER DROPDOWNS (drawn last so they're always on top) ---
if ((trans_in_picker_open || trans_out_picker_open) && scene_edit_mode && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
    var _trpick_block  = script_blocks[active_scene_block_idx];
    var _trpick_names  = ["none","fade","iris","wipe_left","wipe_right","wipe_top","wipe_bottom","barn_door"];
    var _trpick_labels = ["NONE","FADE","IRIS *","WIPE >","< WIPE","v WIPE","WIPE ^","BARN DR"];
    var _trpick_count  = array_length(_trpick_names);
    var _trpick_item_h = 22;
    var _trpick_sep    = 5;
    var _trpick_spd_h  = 28;
    var _trpick_w      = 140;
    var _trpick_h      = _trpick_count * _trpick_item_h + _trpick_sep + _trpick_spd_h;

    // Recompute button X positions (same math as toolbar section)
    var _ind_xtr      = max(scene_win_x, 110);
    var _fx_btn_x_tr  = _ind_xtr + 120; var _fx_btn_w_tr = 130;
    var _in_btn_x_tr  = _fx_btn_x_tr + _fx_btn_w_tr + 10;
    var _out_btn_x_tr = _in_btn_x_tr + 88 + 5;

    var _open_in   = trans_in_picker_open;
    var _tpick_bx  = _open_in ? _in_btn_x_tr : _out_btn_x_tr;
    var _tpick_by  = scene_win_y - 10;
    var _tpick_key = _open_in ? "transition_in"       : "transition_out";
    var _tpick_spk = _open_in ? "transition_in_speed"  : "transition_out_speed";
    var _tpick_cur = variable_struct_exists(_trpick_block, _tpick_key)  ? variable_struct_get(_trpick_block, _tpick_key)  : "none";
    var _tpick_spd = variable_struct_exists(_trpick_block, _tpick_spk)  ? variable_struct_get(_trpick_block, _tpick_spk)  : 30;
    var _tpick_acc = _open_in ? make_color_rgb(50,185,90) : make_color_rgb(200,95,55);
    var _tpick_bdr = _open_in ? make_color_rgb(70,150,70) : make_color_rgb(160,70,70);
    var _tpick_bg  = _open_in ? make_color_rgb(18,32,18)  : make_color_rgb(32,18,18);

    // Background + border
    draw_set_color(_tpick_bg);
    draw_rectangle(_tpick_bx, _tpick_by, _tpick_bx + _trpick_w, _tpick_by + _trpick_h, false);
    draw_set_color(_tpick_bdr);
    draw_rectangle(_tpick_bx, _tpick_by, _tpick_bx + _trpick_w, _tpick_by + _trpick_h, true);

    // Effect rows
    for (var _tri = 0; _tri < _trpick_count; _tri++) {
        var _try    = _tpick_by + _tri * _trpick_item_h;
        var _trcur  = (_trpick_names[_tri] == _tpick_cur);
        var _trhov  = (_mx > _tpick_bx && _mx < _tpick_bx + _trpick_w && _my > _try && _my < _try + _trpick_item_h);
        if (_trcur)      { draw_set_color(_tpick_acc); draw_rectangle(_tpick_bx+1, _try+1, _tpick_bx+_trpick_w-1, _try+_trpick_item_h-1, false); }
        else if (_trhov) { draw_set_color(make_color_rgb(40,50,40)); draw_rectangle(_tpick_bx+1, _try+1, _tpick_bx+_trpick_w-1, _try+_trpick_item_h-1, false); }
        draw_set_color(_trcur ? c_black : c_white);
        draw_text(_tpick_bx + 8, _try + 4, _trpick_labels[_tri]);
        if (_tri < _trpick_count - 1) {
            draw_set_color(make_color_rgb(40,55,40));
            draw_line(_tpick_bx+2, _try+_trpick_item_h, _tpick_bx+_trpick_w-2, _try+_trpick_item_h);
        }
    }

    // Separator
    var _tspd_y = _tpick_by + _trpick_count * _trpick_item_h + _trpick_sep;
    draw_set_color(make_color_rgb(55,70,55));
    draw_line(_tpick_bx + 4, _tspd_y - _trpick_sep/2, _tpick_bx + _trpick_w - 4, _tspd_y - _trpick_sep/2);

    // Speed buttons [FST][MED][SLO]
    var _spd_vals  = [30,   60,   90  ];
    var _spd_strs  = ["FST","MED","SLO"];
    var _spd_bw    = floor((_trpick_w - 10) / 3);
    for (var _si = 0; _si < 3; _si++) {
        var _sbx     = _tpick_bx + 5 + _si * (_spd_bw + 0);
        var _sby     = _tspd_y;
        var _s_on    = (_tpick_spd == _spd_vals[_si]);
        var _s_hov   = (_mx > _sbx && _mx < _sbx + _spd_bw && _my > _sby && _my < _sby + _trpick_spd_h - 4);
        draw_set_color(_s_on ? _tpick_acc : (_s_hov ? make_color_rgb(50,60,50) : make_color_rgb(30,40,30)));
        draw_roundrect_ext(_sbx, _sby, _sbx+_spd_bw-1, _sby+_trpick_spd_h-4, 3,3, false);
        draw_set_color(_s_on ? c_black : c_white);
        draw_set_halign(fa_center);
        draw_text(_sbx + _spd_bw/2, _sby + 6, _spd_strs[_si]);
        draw_set_halign(fa_left);
    }

    draw_set_halign(fa_left);
}
