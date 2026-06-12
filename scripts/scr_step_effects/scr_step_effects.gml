function step_effects_update() {
    var _mx = mouse_x; var _my = mouse_y;
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
}
