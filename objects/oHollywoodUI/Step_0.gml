/// @description Advanced Block Editor Logic (Fixed & Restored)
check_timer++; // Throttle timer: rate-limits disk file_exists() polls to ~10 Hz to eliminate OS spinning cursor
var _mx = mouse_x; var _my = mouse_y;
var _overlay_active = false;
var _scene = -1;

// --- Particle update (runs every step regardless of mode) ---
for (var _ppi = array_length(active_particles) - 1; _ppi >= 0; _ppi--) {
    var _pp = active_particles[_ppi];
    _pp.x  += _pp.vx;
    _pp.y  += _pp.vy;
    _pp.vy += variable_struct_exists(_pp, "gravity") ? _pp.gravity : 0.18;
    _pp.life--;
    if (_pp.life <= 0) array_delete(active_particles, _ppi, 1);
}

// --- Emitter update (continuous particle streams) ---
for (var _ei = array_length(active_emitters) - 1; _ei >= 0; _ei--) {
    var _em = active_emitters[_ei];
    var _expired = false;
    if (variable_struct_exists(_em, "chain_start_index") && _em.chain_start_index != -1) {
        if (playing_block_index != _em.chain_start_index || !is_driving_event_active()) {
            _expired = true;
        }
    } else {
        _em.frames_remaining--;
        if (_em.frames_remaining < 0) {
            _expired = true;
        }
    }
    if (_expired) {
        array_delete(active_emitters, _ei, 1);
    } else if ((variable_struct_exists(_em, "chain_start_index") && _em.chain_start_index != -1) || (_em.frames_remaining mod 2 == 0)) {
        var _esx0 = scene_win_x + _em.x;
        var _esy0 = scene_win_y + _em.y;
        var _eang = degtorad(_em.angle);
        var _esprd = degtorad(variable_struct_exists(_em, "spread") ? _em.spread : 65);
        var _espd_mul = variable_struct_exists(_em, "speed") ? _em.speed : 1.0;
        var _ecolor = variable_struct_exists(_em, "color")   ? _em.color   : "red";
        var _ecr    = variable_struct_exists(_em, "color_r") ? _em.color_r : 200;
        var _ecg    = variable_struct_exists(_em, "color_g") ? _em.color_g : 0;
        var _ecb    = variable_struct_exists(_em, "color_b") ? _em.color_b : 0;
        var _eaw    = variable_struct_exists(_em, "area_w")  ? _em.area_w  : 0;
        var _eah    = variable_struct_exists(_em, "area_h")  ? _em.area_h  : 0;
        repeat (max(1, _em.density)) {
            var _ea = (irandom(6) == 0) ? random_range(0, 2*pi) : (_eang + random_range(-_esprd, _esprd));
            var _ergb = get_particle_rgb_ex(_ecolor, _ecr, _ecg, _ecb);
            var _epx = _esx0 + random_range(-_eaw/2, _eaw/2);
            var _epy = _esy0 + random_range(-_eah/2, _eah/2);
            spawn_emitter_particle(_em.effect, _epx, _epy, _ea, _em.size, _espd_mul, _ergb);
        }
    }
}

// --- Beam update ---
for (var _bmi = array_length(active_beams) - 1; _bmi >= 0; _bmi--) {
    var _bm = active_beams[_bmi];
    var _expired = false;
    if (variable_struct_exists(_bm, "chain_start_index") && _bm.chain_start_index != -1) {
        if (playing_block_index != _bm.chain_start_index || !is_driving_event_active()) {
            _expired = true;
        }
    } else {
        _bm.frames_remaining--;
        if (_bm.frames_remaining <= 0) {
            _expired = true;
        }
    }
    if (_expired) {
        array_delete(active_beams, _bmi, 1);
    }
}

// --- Explosion update ---
for (var _exi = array_length(active_explosions) - 1; _exi >= 0; _exi--) {
    var _ex = active_explosions[_exi];
    _ex.frames_elapsed++;

    // Spawn sparks at the flash peak (~t=0.22)
    if (!_ex.sparks_done) {
        var _spark_t = _ex.frames_elapsed / max(1, _ex.frames_total);
        if (_spark_t >= 0.22) {
            _ex.sparks_done = true;
            var _scx  = scene_win_x + _ex.x;
            var _scy  = scene_win_y + _ex.y;
            var _ssz  = _ex.size;
            var _scr  = variable_struct_exists(_ex, "color_r") ? _ex.color_r : 165;
            var _scg  = variable_struct_exists(_ex, "color_g") ? _ex.color_g : 12;
            var _scb  = variable_struct_exists(_ex, "color_b") ? _ex.color_b : 8;
            var _sden = variable_struct_exists(_ex, "density") ? _ex.density : 2;
            for (var _si = 0; _si < max(4, round(8 * _sden)); _si++) {
                var _sa = random_range(0, 2 * pi);
                var _sp = random_range(3.5, 9.0) * _ssz;
                var _sl = irandom_range(14, 26);
                var _sw = (irandom(2) == 0);
                array_push(active_particles, {
                    x: _scx, y: _scy,
                    vx: cos(_sa) * _sp, vy: sin(_sa) * _sp,
                    life: _sl, max_life: _sl,
                    size: random_range(1.5, 3.5) * _ssz,
                    r:  _sw ? 255 : min(255, _scr + 65),
                    g:  _sw ? 255 : min(255, _scg + 50),
                    b:  _sw ? 220 : min(255, _scb + 25),
                    r2: _sw ? 60  : floor(_scr * 0.25),
                    g2: _sw ? 50  : floor(_scg * 0.20),
                    b2: _sw ? 0   : floor(_scb * 0.30),
                    gravity: 0.10, shape: "line", additive: true,
                });
            }
        }
    }

    var _expired = false;
    if (variable_struct_exists(_ex, "chain_start_index") && _ex.chain_start_index != -1) {
        if (playing_block_index != _ex.chain_start_index || !is_driving_event_active()) {
            _expired = true;
        }
    } else {
        if (_ex.frames_elapsed >= _ex.frames_total) {
            _expired = true;
        }
    }
    if (_expired) {
        array_delete(active_explosions, _exi, 1);
    }
}

// --- Title frames update ---
if (playing_block_index != -1) {
    var _end_idx = max(playing_block_index, playing_linked_index);
    var _driving_active = is_driving_event_active();
    for (var _i = playing_block_index; _i <= _end_idx; _i++) {
        if (_i < array_length(script_blocks)) {
            var _cb = script_blocks[_i];
            if (variable_struct_exists(_cb, "title_frames")) {
                if (variable_struct_exists(_cb, "title_tied_to_chain") && _cb.title_tied_to_chain) {
                    if (!_driving_active) {
                        _cb.title_frames = 0;
                    }
                } else {
                    if (!theater_paused && _cb.title_frames > 0) {
                        _cb.title_frames--;
                    }
                }
            }
        }
    }
}

// --- Quake ---
if (quake_frames > 0) {
    if (quake_chain_start != -1) {
        if (playing_block_index != quake_chain_start || !is_driving_event_active()) {
            quake_frames = 0;
            quake_tied_to_chain = false;
            quake_chain_start = -1;
        }
    } else { quake_frames--; }
    if (quake_frames > 0) {
        quake_x = (quake_direction != "vertical")   ? random_range(-quake_intensity, quake_intensity) : 0;
        quake_y = (quake_direction != "horizontal") ? random_range(-quake_intensity, quake_intensity) : 0;
    } else { quake_x = 0; quake_y = 0; }
} else { quake_x = 0; quake_y = 0; }

// --- Active shots ---
for (var _shi = array_length(active_shots) - 1; _shi >= 0; _shi--) {
    var _sh = active_shots[_shi];
    var _prev_x = _sh.x; var _prev_y = _sh.y;
    _sh.x   += _sh.vx;
    _sh.y   += _sh.vy;
    _sh.life++;
    var _sh_fade = _sh.max_life * 0.7;
    if (_sh.life > _sh_fade) _sh.alpha = max(0, 1.0 - (_sh.life - _sh_fade) / max(1, _sh.max_life * 0.3));
    // Segment-vs-character hit test (same composite bbox as laser, same ray_aabb function)
    var _sh_hit = false;
    var _sh_speed = point_distance(0, 0, _sh.vx, _sh.vy);
    if (_sh_speed > 0.001) {
        var _sh_dx = _sh.vx / _sh_speed; var _sh_dy = _sh.vy / _sh_speed;
        var _sc_sh = (scene_win_h * 1.5) / 450;
        for (var _chi = 0; _chi < array_length(preview_actors) && !_sh_hit; _chi++) {
            var _ca = preview_actors[_chi];
            var _cl = get_composite_character_sprite(_ca.char_index,
                variable_struct_exists(_ca, "pose")       ? _ca.pose       : 1,
                variable_struct_exists(_ca, "expression") ? _ca.expression : 21,
                variable_struct_exists(_ca, "facing")     ? _ca.facing     : 1);
            if (array_length(_cl) == 0 || _cl[0].spr == -1) continue;
            var _bspr = _cl[0].spr;
            var _bw = sprite_get_width(_bspr); var _bh = sprite_get_height(_bspr);
            // Y: composite top for head coverage; X: body sprite pixel bbox to avoid empty canvas edges
            var _bb_y1 = 0;
            for (var _li = 1; _li < array_length(_cl); _li++) {
                var _ll = _cl[_li]; if (_ll.spr == -1) continue;
                _bb_y1 = min(_bb_y1, _ll.dy);
            }
            var _cdx0 = _ca.x - _bw * _sc_sh * 0.5; var _cdy0 = _ca.y - _bh * _sc_sh;
            var _sc_x1 = _cdx0 + sprite_get_bbox_left(_bspr)  * _sc_sh;
            var _sc_x2 = _cdx0 + sprite_get_bbox_right(_bspr) * _sc_sh;
            var _sc_y1 = max(_cdy0 + _bb_y1 * _sc_sh, -scene_win_h * 0.1); var _sc_y2 = _ca.y + 5;
            // Cast from the leading edge so the shot disappears when its tip — not center — reaches the character
            var _lead_x = _prev_x + _sh_dx * (_sh.w * 0.5);
            var _lead_y = _prev_y + _sh_dy * (_sh.w * 0.5);
            if (_lead_x >= _sc_x1 - 4 && _lead_x <= _sc_x2 + 4 && _lead_y >= _sc_y1 && _lead_y <= _sc_y2) continue;
            var _lt = ray_aabb(_lead_x, _lead_y, _sh_dx, _sh_dy, _sc_x1, _sc_y1, _sc_x2, _sc_y2);
            if (_lt > 0 && _lt <= _sh_speed + 4) _sh_hit = true;
        }
    }
    var _sh_exited = (_sh.x < -50 || _sh.x > scene_win_w + 50 || _sh.y < -50 || _sh.y > scene_win_h + 50);
    if (_sh_hit || _sh_exited || _sh.life >= _sh.max_life || _sh.alpha <= 0) array_delete(active_shots, _shi, 1);
}
// While shots are in flight keep the pause timer alive; release it the moment the last shot is gone
if (waiting_for_shots) {
    if (array_length(active_shots) > 0) {
        speaking_pause_timer = max(speaking_pause_timer, 2);
    } else {
        waiting_for_shots    = false;
        speaking_pause_timer = min(speaking_pause_timer, 1);
    }
}

// --- Decap head ---
for (var _dhi = array_length(active_decap_heads) - 1; _dhi >= 0; _dhi--) {
    var _dh = active_decap_heads[_dhi];
    _dh.life++;
    if (variable_struct_exists(_dh, "returning") && _dh.returning) {
        // Ease toward target (reform animation)
        var _rt = clamp(_dh.life / _dh.max_life, 0, 1);
        var _rt_ease = 1 - (1 - _rt) * (1 - _rt);
        _dh.x = lerp(_dh.x, _dh.target_x, 0.09 + _rt * 0.12);
        _dh.y = lerp(_dh.y, _dh.target_y, 0.09 + _rt * 0.12);
        _dh.spin = lerp(_dh.spin, 0, 0.18);
        _dh.angle += _dh.spin;
        if (_dh.life >= _dh.max_life || (abs(_dh.x - _dh.target_x) < 2 && abs(_dh.y - _dh.target_y) < 2)) {
            // Arrived — clear decapitated flag on the actor
            var _cr = _dh.char_ref;
            _cr.is_decapitated = false;
            var _still_inj_ret = variable_struct_exists(_cr, "is_knocked_down") && _cr.is_knocked_down;
            _cr.injured = _still_inj_ret;
            array_delete(active_decap_heads, _dhi, 1);
        }
    } else {
        _dh.x     += _dh.vx;
        _dh.y     += _dh.vy;
        _dh.angle += _dh.spin;
        if (_dh.life > _dh.max_life * 0.6) _dh.alpha = max(0, 1.0 - (_dh.life - _dh.max_life * 0.6) / (_dh.max_life * 0.4));
        var _dh_exited = (_dh.x < scene_win_x || _dh.x > scene_win_x + scene_win_w
                       || _dh.y < scene_win_y || _dh.y > scene_win_y + scene_win_h);
        if (_dh_exited || _dh.life >= _dh.max_life) {
            if (array_length(active_decap_heads) == 1) speaking_pause_timer = 1;
            array_delete(active_decap_heads, _dhi, 1);
        }
    }
}

// --- Idle blood spurt (decapitate) ---
if (playing_block_index != -1) {
    var _asc_bl = (scene_win_h * 1.5) / 450;
    for (var _bli = 0; _bli < array_length(preview_actors); _bli++) {
        var _bla = preview_actors[_bli];
        if (!variable_struct_exists(_bla, "is_decapitated") || !_bla.is_decapitated) continue;
        if (variable_struct_exists(_bla, "is_knocked_down") && _bla.is_knocked_down) continue;
        if (!variable_struct_exists(_bla, "blood_timer")) _bla.blood_timer = 0;
        _bla.blood_timer++;
        var _btrig = 70 + irandom(60);
        if (_bla.blood_timer >= _btrig) {
            _bla.blood_timer = 0;
            var _blly = get_composite_character_sprite(_bla.char_index, _bla.pose, _bla.expression, _bla.facing);
            var _blbh = (_blly[0].spr != -1) ? sprite_get_height(_blly[0].spr) * _asc_bl : 200;
            var _bnx = _bla.x + random_range(-6, 6);
            var _bny = _bla.y - _blbh * 0.92;
            repeat (irandom_range(2, 4)) {
                var _bba = degtorad(random_range(240, 300));
                var _bsp = random_range(1.2, 3.5);
                array_push(active_particles, {
                    x: scene_win_x + _bnx, y: scene_win_y + _bny,
                    vx: cos(_bba) * _bsp, vy: sin(_bba) * _bsp,
                    life: irandom_range(12, 22), max_life: 20,
                    size: random_range(2, 4.5),
                    r: irandom_range(120, 180), g: irandom_range(0, 10), b: irandom_range(0, 8),
                    r2: 30, g2: 0, b2: 0,
                    gravity: 0.18,
                });
            }
        }
    }
}

// --- Particle panel drag: track mouse position and detect drop ---
if (dragging_particle_effect != "") {
    drag_particle_x = _mx;
    drag_particle_y = _my;
    if (!mouse_check_button(mb_left)) {
        if (_mx > scene_win_x && _mx < scene_win_x + scene_win_w
                && _my > scene_win_y && _my < scene_win_y + scene_win_h) {
            var _pblk_x = _mx - scene_win_x;
            var _pblk_y = _my - scene_win_y;
            var _pblk_i = (focused_block != -1) ? focused_block + 1 : array_length(script_blocks);
            var _is_shot_drop = (dragging_particle_effect == "shot");
            array_insert(script_blocks, _pblk_i, {
                type: "particle", effect: dragging_particle_effect,
                x: _pblk_x, y: _pblk_y,
                angle:    (_is_shot_drop ? 0 : (dragging_particle_effect == "flame" ? 270 : 315)),
                size:     1.0,
                duration: (_is_shot_drop ? 2.0 : (dragging_particle_effect == "explosion" ? 1.5 : 1.0)),
                density:  2, speed: (_is_shot_drop ? 8.0 : 1.0), spread: 65,
                color:    (_is_shot_drop ? "white" : (dragging_particle_effect == "shatter" ? "glass" : (dragging_particle_effect == "electrify" ? "electric" : (dragging_particle_effect == "debris" ? "wood" : (dragging_particle_effect == "flame" || dragging_particle_effect == "explosion" ? "orange" : "red"))))),
                color_r: 200, color_g: 0, color_b: 0,
                area_w: (_is_shot_drop ? 30 : 0), area_h: (_is_shot_drop ? 4 : 0),
                height: 85,
            });
            update_all_block_heights();
            focused_block           = _pblk_i;
            particle_edit_mode      = true;
            particle_edit_block_idx = _pblk_i;
        }
        dragging_particle_effect = "";
    }
}

// --- Particle edit mode: continuous drag updates ---
if (particle_edit_mode && particle_edit_block_idx != -1 && particle_edit_block_idx < array_length(script_blocks)
        && variable_struct_exists(script_blocks[particle_edit_block_idx], "type")
        && script_blocks[particle_edit_block_idx].type == "particle") {
    var _peb = script_blocks[particle_edit_block_idx];
    if (!mouse_check_button(mb_left)) {
        particle_drag_pos = false; particle_drag_dir = false;
        particle_drag_area_w = false; particle_drag_area_h = false;
    }
    if (particle_drag_pos) {
        _peb.x = clamp(_mx - scene_win_x, 0, scene_win_w);
        _peb.y = clamp(_my - scene_win_y, 0, scene_win_h);
    }
    if (particle_drag_area_w) {
        _peb.area_w = clamp((_mx - (scene_win_x + _peb.x)) * 2, 0, 255);
    }
    if (particle_drag_area_h) {
        _peb.area_h = clamp(((scene_win_y + _peb.y) - _my) * 2, 0, 255);
    }
    if (particle_drag_dir) {
        var _ddx = _mx - (scene_win_x + _peb.x);
        var _ddy = _my - (scene_win_y + _peb.y);
        if (point_distance(0, 0, _ddx, _ddy) > 5) {
            _peb.angle = radtodeg(arctan2(_ddy, _ddx));
            // Emit a trickle of preview particles each frame so direction is visually live
            var _esx0 = scene_win_x + _peb.x; var _esy0 = scene_win_y + _peb.y;
            var _eang = degtorad(_peb.angle);
            var _esprd = degtorad(variable_struct_exists(_peb, "spread") ? _peb.spread : 65);
            var _esz    = variable_struct_exists(_peb, "size")    ? _peb.size    : 1.0;
            var _espd_m = variable_struct_exists(_peb, "speed")   ? _peb.speed   : 1.0;
            var _eden   = variable_struct_exists(_peb, "density") ? _peb.density : 2;
            var _ecolor = variable_struct_exists(_peb, "color")   ? _peb.color   : "red";
            var _ecr    = variable_struct_exists(_peb, "color_r") ? _peb.color_r : 200;
            var _ecg    = variable_struct_exists(_peb, "color_g") ? _peb.color_g : 0;
            var _ecb    = variable_struct_exists(_peb, "color_b") ? _peb.color_b : 0;
            var _eaw    = variable_struct_exists(_peb, "area_w")  ? _peb.area_w  : 0;
            var _eah    = variable_struct_exists(_peb, "area_h")  ? _peb.area_h  : 0;
            if (_peb.effect == "laser" || _peb.effect == "explosion" || _peb.effect == "shot") {} else
            repeat (max(1, _eden)) {
                var _ea = _eang + random_range(-_esprd, _esprd);
                var _ergb = get_particle_rgb_ex(_ecolor, _ecr, _ecg, _ecb);
                var _epx = _esx0 + random_range(-_eaw/2, _eaw/2);
                var _epy = _esy0 + random_range(-_eah/2, _eah/2);
                spawn_emitter_particle(_peb.effect, _epx, _epy, _ea, _esz, _espd_m, _ergb);
            }
        }
    }
} else if (particle_edit_mode) {
    particle_edit_mode = false; particle_drag_pos = false; particle_drag_dir = false; particle_drag_area_w = false; particle_drag_area_h = false;
}

// --- RGB custom color: keyboard typing + hold-repeat (runs every step) ---
if (particle_edit_mode && particle_edit_block_idx != -1 && particle_edit_block_idx < array_length(script_blocks)) {
    var _peb_c = script_blocks[particle_edit_block_idx];
    var _is_cust_c = variable_struct_exists(_peb_c, "color") && _peb_c.color == "custom";

    if (rgb_edit_channel != -1 && _is_cust_c) {
        // Accept digit characters
        if (string_length(keyboard_string) > 0) {
            for (var _ki = 1; _ki <= string_length(keyboard_string); _ki++) {
                var _kc = string_char_at(keyboard_string, _ki);
                if (_kc >= "0" && _kc <= "9" && string_length(rgb_edit_str) < 3)
                    rgb_edit_str += _kc;
            }
            keyboard_string = "";
        }
        if (keyboard_check_pressed(vk_backspace) && string_length(rgb_edit_str) > 0)
            rgb_edit_str = string_delete(rgb_edit_str, string_length(rgb_edit_str), 1);
        // Commit on Enter
        if (keyboard_check_pressed(vk_return)) {
            var _typed_val = clamp(string_length(rgb_edit_str) > 0 ? real(rgb_edit_str) : 0, 0, 255);
            if      (rgb_edit_channel == 0) _peb_c.color_r = _typed_val;
            else if (rgb_edit_channel == 1) _peb_c.color_g = _typed_val;
            else                            _peb_c.color_b = _typed_val;
            rgb_edit_channel = -1; rgb_edit_str = "";
        }
        if (keyboard_check_pressed(vk_escape)) { rgb_edit_channel = -1; rgb_edit_str = ""; }
    }

    // Hold-repeat for [-]/[+] buttons
    if (rgb_hold_btn != "") {
        if (!mouse_check_button(mb_left)) {
            rgb_hold_btn = ""; rgb_hold_timer = 0;
        } else if (_is_cust_c) {
            rgb_hold_timer++;
            // start slow after 20 frames, speed up after 50
            if (rgb_hold_timer > 50 && rgb_hold_timer mod 2 == 0
             || rgb_hold_timer > 20 && rgb_hold_timer mod 4 == 0) {
                if (rgb_hold_btn == "r-") _peb_c.color_r = max(0,   _peb_c.color_r - 5);
                if (rgb_hold_btn == "r+") _peb_c.color_r = min(255, _peb_c.color_r + 5);
                if (rgb_hold_btn == "g-") _peb_c.color_g = max(0,   _peb_c.color_g - 5);
                if (rgb_hold_btn == "g+") _peb_c.color_g = min(255, _peb_c.color_g + 5);
                if (rgb_hold_btn == "b-") _peb_c.color_b = max(0,   _peb_c.color_b - 5);
                if (rgb_hold_btn == "b+") _peb_c.color_b = min(255, _peb_c.color_b + 5);
            }
        }
    }
}

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
                scene_modal_open = false; return;
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
    var _tmx = mouse_x; var _tmy = mouse_y;
    if (_tmx != theater_ui_last_mx || _tmy != theater_ui_last_my || theater_paused) {
        theater_ui_timer = 120;
    } else if (theater_ui_timer > 0) {
        theater_ui_timer--;
    }
    theater_ui_last_mx = _tmx; theater_ui_last_my = _tmy;

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
                    var _scale = (scene_win_h * 1.5) / 450;
                    var _ax = scene_win_x + _act.x;
                    var _ay = scene_win_y + _act.y;
                    // Use get_actor_bbox so knocked-down rotation is accounted for
                    var _pa_inj2 = _act;
                    for (var _paj2 = 0; _paj2 < array_length(preview_actors); _paj2++) {
                        if (preview_actors[_paj2].char_index == _act.char_index) { _pa_inj2 = preview_actors[_paj2]; break; }
                    }
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
                var _sc = (scene_win_h * 1.5) / 450;
                var _ax_abs = scene_win_x + _act.x;
                var _ay_abs = scene_win_y + _act.y;
                // Find live preview_actors entry for injury state
                var _pa_inj = {};
                for (var _paj = 0; _paj < array_length(preview_actors); _paj++) {
                    if (preview_actors[_paj].char_index == _act.char_index) { _pa_inj = preview_actors[_paj]; break; }
                }
                var _bbox = get_actor_bbox(_layers, _sc, _ax_abs, _ay_abs, _pa_inj);
                var _bb_w = _bbox.bb_right - _bbox.bb_left;
                var _bb_h = _bbox.bb_bottom - _bbox.bb_top;
                var _h_visible = max(0, min(_bbox.bb_right, scene_win_x + scene_win_w) - max(_bbox.bb_left, scene_win_x));
                var _v_visible = max(0, min(_bbox.bb_bottom, scene_win_y + scene_win_h) - max(_bbox.bb_top, scene_win_y));
                var _in_live = (current_scene_sprite != -1) && (_h_visible >= _bb_w * 0.20) && (_v_visible >= _bb_h * 0.20);

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
                var _sc = (scene_win_h * 1.5) / 450;
                var _ax_abs = scene_win_x + _act.x;
                var _ay_abs = scene_win_y + _act.y;
                var _bbox = get_actor_bbox(_layers, _sc, _ax_abs, _ay_abs, _act);
                var _bb_w = _bbox.bb_right - _bbox.bb_left;
                var _bb_h = _bbox.bb_bottom - _bbox.bb_top;
                var _h_visible = max(0, min(_bbox.bb_right, scene_win_x + scene_win_w) - max(_bbox.bb_left, scene_win_x));
                var _v_visible = max(0, min(_bbox.bb_bottom, scene_win_y + scene_win_h) - max(_bbox.bb_top, scene_win_y));
                var _in_live = (current_scene_sprite != -1) && (_h_visible >= _bb_w * 0.20) && (_v_visible >= _bb_h * 0.20);

                if (_v_visible < _bb_h * 0.20) {
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
        // Injured characters can still talk; only block if offstage/disappeared
        var _vblocked = false;
        var _vcheck_limit = (focused_block != -1) ? focused_block + 1 : array_length(script_blocks);
        for (var _vk = 0; _vk < _vcheck_limit; _vk++) {
            var _vb = script_blocks[_vk];
            if (!variable_struct_exists(_vb, "type")) continue;
            if (_vb.type == "action" && _vb.char_index == selected_character_index) {
                var _vaname = string_lower(_vb.action_name);
                if (string_pos("exit", _vaname) > 0 || string_pos("disappears", _vaname) > 0) _vblocked = true;
                else if (string_pos("enter", _vaname) > 0) _vblocked = false;
            } else if (_vb.type == "scene" && variable_struct_exists(_vb, "actors")) {
                for (var _va = 0; _va < array_length(_vb.actors); _va++) {
                    if (_vb.actors[_va].char_index == selected_character_index) { _vblocked = false; break; }
                }
            }
        }
        if (_vblocked) return;
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
                        move_modal_temp_moonwalk    = variable_struct_exists(_block, "moonwalk")     ? _block.moonwalk     : false;
                        move_modal_temp_trick       = variable_struct_exists(_block, "trick")       ? _block.trick       : "none";
                        move_modal_temp_trick_count = variable_struct_exists(_block, "trick_count") ? _block.trick_count : 1;
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
                                move_modal_temp_moonwalk = variable_struct_exists(_block, "moonwalk") ? _block.moonwalk : false;
                                move_modal_temp_trick = variable_struct_exists(_block, "trick") ? _block.trick : "none";
                                move_modal_temp_speed_index = 2;
                                for (var _dj2 = 0; _dj2 < array_length(move_speeds); _dj2++) {
                                    if (abs(move_speeds[_dj2] - _dbl_spd) < 0.01) { move_modal_temp_speed_index = _dj2; break; }
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

                        if (_bk_type == "kill" || _bk_type == "jitter" || _bk_type == "voice" || _bk_type == "move" || _bk_type == "charaction" || _bk_type == "canned") {
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
                        var _sa_new = { char_index: dragging_char_index, x: _nx, y: _ny, facing: _face, pose: _pose, expression: _expr };
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
                        array_push(_scene.actors, _sa_new);
                        scene_edit_selected_actor_idx = array_length(_scene.actors) - 1;
                        }
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
