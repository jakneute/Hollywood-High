/// @description Text, block, and string utility functions.

function safe_delete(_str, _start, _count) {
    if (string_length(_str) == 0) return "";
    var _s = clamp(_start, 1, string_length(_str));
    var _c = min(_count, string_length(_str) - _s + 1);
    if (_c <= 0) return _str;
    return string_delete(_str, _s, _c);
}

function update_block_height(_idx) {
    if (_idx < 0 || _idx >= array_length(script_blocks)) return;
    var _b = script_blocks[_idx];
    var _wrap_w = box_w - 120;
    var _is_scene    = (variable_struct_exists(_b, "type") && _b.type == "scene");
    var _is_action   = (variable_struct_exists(_b, "type") && _b.type == "action");
    var _is_particle = (variable_struct_exists(_b, "type") && _b.type == "particle");
    if (_is_scene || _is_action || _is_particle) {
        _b.height = 85;
    } else {
        var _txt_h = string_height_ext(_b.text, 28, _wrap_w);
        _b.height = 25 + max(70, _txt_h + 16);
    }
}

function update_all_block_heights() {
    for (var i = 0; i < array_length(script_blocks); i++) {
        update_block_height(i);
    }
}

// Case-insensitive whole-word substitution for TTS pronunciation overrides.
function apply_dictionary(_text) {
    var _out = _text;
    var _delims = " .,!?;:()[]<>\"'/\n\r\t";
    for (var i = 0; i < array_length(dictionary_list); i++) {
        var _entry = dictionary_list[i];
        var _find = string_lower(_entry.written);
        var _repl = _entry.pronunciation;
        if (_find == "" || _repl == "") continue;
        var _pos = 1;
        while (true) {
            var _out_l = string_lower(_out);
            _pos = string_pos_ext(_find, _out_l, _pos);
            if (_pos == 0) break;
            var _is_start = (_pos == 1 || string_pos(string_char_at(_out, _pos - 1), _delims) > 0);
            var _is_end   = (_pos + string_length(_find) > string_length(_out) || string_pos(string_char_at(_out, _pos + string_length(_find)), _delims) > 0);
            if (_is_start && _is_end) {
                _out = string_delete(_out, _pos, string_length(_find));
                _out = string_insert(_repl, _out, _pos);
                _pos += string_length(_repl);
            } else {
                _pos += string_length(_find);
            }
        }
    }
    return _out;
}

// Returns the pixel {x, y} of a caret position inside word-wrapped text.
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

function get_link_type(_block) {
    if (variable_struct_exists(_block, "type") && _block.type == "action") {
        var _aname = string_lower(_block.action_name);
        if (string_pos("play sfx",     _aname) > 0) return "sfx";
        if (string_pos("display title",_aname) > 0) return "title";
        if (string_pos("disappears",   _aname) > 0) return "charaction";
        if (string_pos("enter", _aname) > 0 || string_pos("exit", _aname) > 0 || string_pos("move", _aname) > 0) return "move";
    } else if (variable_struct_exists(_block, "type") && _block.type == "particle") {
        return "particle";
    } else if (!variable_struct_exists(_block, "type") || _block.type == "voice") {
        return "voice";
    }
    return "other";
}

// Maps a mouse position to a character index inside the script text area.
function get_index(_mx, _my) {
    var _rel_x = _mx - (box_x + 10);
    var _rel_y = _my - (box_y + 10 + text_scroll_y);
    var _max_w = box_w - 50;
    var _line_h = 24;
    if (script_text == "") return 0;
    var _target_row = clamp(floor(_rel_y / _line_h), 0, 1000);
    var _cur_x = 0; var _cur_y = 0; var _cur_row = 0;
    var _best_idx = 0; var _found_on_row = false;
    var _last_idx_on_row = 0;
    for (var i = 1; i <= string_length(script_text); i++) {
        var _char = string_char_at(script_text, i);
        if (i == 1 || string_char_at(script_text, i-1) == " " || string_char_at(script_text, i-1) == "\n") {
            var _next_space = string_pos_ext(" ", script_text, i);
            var _next_nl = string_pos_ext("\n", script_text, i);
            var _end = string_length(script_text);
            if (_next_space > 0) _end = min(_end, _next_space - 1);
            if (_next_nl > 0) _end = min(_end, _next_nl - 1);
            var _word_w = string_width(string_copy(script_text, i, _end - i + 1));
            if (_cur_x + _word_w > _max_w && _cur_x > 0) { _cur_x = 0; _cur_y += _line_h; _cur_row++; }
        }
        if (_cur_row == _target_row) {
            _found_on_row = true;
            if (abs(_rel_x - _cur_x) < 20) { _best_idx = i - 1; break; }
            _best_idx = i;
            _last_idx_on_row = i;
        }
        if (_char == "\n") { _cur_x = 0; _cur_y += _line_h; _cur_row++; }
        else _cur_x += string_width(_char);
    }
    if (!_found_on_row && _rel_y > _cur_y) return string_length(script_text);
    if (_found_on_row && _rel_x > _cur_x) return _last_idx_on_row;
    return _best_idx;
}

function get_particle_rgb(_color_name) {
    if (_color_name == "darkred")   return { r: irandom_range(90,  150), g: irandom_range(0,  12), b: irandom_range(0,  8)  };
    if (_color_name == "crimson")   return { r: irandom_range(150, 200), g: irandom_range(0,  18), b: irandom_range(20, 55) };
    if (_color_name == "maroon")    return { r: irandom_range(70,  110), g: irandom_range(0,  8),  b: irandom_range(0,  6)  };
    if (_color_name == "brown")     return { r: irandom_range(90,  130), g: irandom_range(48, 80), b: irandom_range(15, 38) };
    if (_color_name == "darkbrown") return { r: irandom_range(45,  75),  g: irandom_range(20, 40), b: irandom_range(5,  18) };
    if (_color_name == "orange")    return { r: irandom_range(175, 215), g: irandom_range(45, 80), b: irandom_range(0,  12) };
    if (_color_name == "black")     return { r: irandom_range(8,   35),  g: irandom_range(5,  18), b: irandom_range(5,  15) };
    if (_color_name == "glass")     return { r: irandom_range(175, 225), g: irandom_range(210, 240), b: irandom_range(228, 255) };
    if (_color_name == "wood") {
        var _wt = irandom(3);
        if (_wt == 0) return { r: irandom_range(120, 168), g: irandom_range(78, 108), b: irandom_range(28, 52)  }; // mid plank
        if (_wt == 1) return { r: irandom_range(178, 215), g: irandom_range(145, 172), b: irandom_range(88, 112) }; // raw cut
        if (_wt == 2) return { r: irandom_range(48,  82),  g: irandom_range(24,  46),  b: irandom_range(6,  22)  }; // dark grain
                      return { r: irandom_range(222, 242), g: irandom_range(212, 228), b: irandom_range(185, 208) }; // paint chip
    }
    if (_color_name == "electric")  {
        if (irandom(1) == 0) return { r: irandom_range(210, 255), g: irandom_range(210, 255), b: irandom_range(80,  160) };
        else                 return { r: irandom_range(60,  160), g: irandom_range(180, 240), b: irandom_range(230, 255) };
    }
    if (_color_name == "yellow")    return { r: irandom_range(195, 232), g: irandom_range(185, 212), b: irandom_range(5,   30)  }; // piss
    if (_color_name == "white")     return { r: irandom_range(225, 255), g: irandom_range(218, 248), b: irandom_range(205, 235) }; // jizz
    return { r: irandom_range(120, 210), g: irandom_range(0, 25), b: irandom_range(0, 18) }; // red (default)
}

function ray_aabb(_ox, _oy, _dx, _dy, _x1, _y1, _x2, _y2) {
    var _tmin = 0; var _tmax = 99999;
    if (abs(_dx) > 0.0001) {
        var _tx1 = (_x1 - _ox) / _dx; var _tx2 = (_x2 - _ox) / _dx;
        if (_tx1 > _tx2) { var _tmp = _tx1; _tx1 = _tx2; _tx2 = _tmp; }
        _tmin = max(_tmin, _tx1); _tmax = min(_tmax, _tx2);
    } else if (_ox < _x1 || _ox > _x2) return -1;
    if (abs(_dy) > 0.0001) {
        var _ty1 = (_y1 - _oy) / _dy; var _ty2 = (_y2 - _oy) / _dy;
        if (_ty1 > _ty2) { var _tmp2 = _ty1; _ty1 = _ty2; _ty2 = _tmp2; }
        _tmin = max(_tmin, _ty1); _tmax = min(_tmax, _ty2);
    } else if (_oy < _y1 || _oy > _y2) return -1;
    if (_tmax < _tmin || _tmax < 0) return -1;
    return _tmin > 0 ? _tmin : _tmax;
}

function get_beam_rgb(_color, _cr, _cg, _cb) {
    if (_color == "custom")    return { r: _cr,  g: _cg,  b: _cb  };
    if (_color == "darkred")   return { r: 130,  g: 8,    b: 8    };
    if (_color == "crimson")   return { r: 175,  g: 0,    b: 38   };
    if (_color == "maroon")    return { r: 95,   g: 5,    b: 5    };
    if (_color == "brown")     return { r: 115,  g: 62,   b: 28   };
    if (_color == "darkbrown") return { r: 65,   g: 30,   b: 10   };
    if (_color == "orange")    return { r: 200,  g: 70,   b: 5    };
    if (_color == "yellow")    return { r: 215,  g: 198,  b: 12   };
    if (_color == "glass")     return { r: 185,  g: 220,  b: 248  };
    if (_color == "wood")      return { r: 145,  g: 95,   b: 42   };
    if (_color == "white")     return { r: 242,  g: 238,  b: 228  };
    if (_color == "electric")  return { r: 70,   g: 195,  b: 255  };
    if (_color == "black")     return { r: 22,   g: 14,   b: 14   };
    return { r: 220, g: 22, b: 22 }; // red default
}

function get_particle_rgb_ex(_color, _cr, _cg, _cb) {
    if (_color == "custom") {
        return { r: clamp(_cr + irandom_range(-12, 12), 0, 255),
                 g: clamp(_cg + irandom_range(-12, 12), 0, 255),
                 b: clamp(_cb + irandom_range(-12, 12), 0, 255) };
    }
    return get_particle_rgb(_color);
}

// Scans a WAV buffer for the fmt and data chunks, returning format info and the
// actual data chunk offset/size. Handles WAVs with extended headers or extra chunks.
function parse_wav_header(_buf) {
    var _sz = buffer_get_size(_buf);
    var _result = { chan: 1, rate: 44100, bits: 16, data_offset: 44, data_size: max(0, _sz - 44) };
    if (_sz < 12) return _result;
    var _pos = 12; // skip "RIFF xxxx WAVE"
    while (_pos + 8 <= _sz) {
        buffer_seek(_buf, buffer_seek_start, _pos);
        var _id = "";
        for (var _j = 0; _j < 4; _j++) _id += chr(buffer_read(_buf, buffer_u8));
        var _csz = buffer_read(_buf, buffer_u32);
        if (_id == "fmt ") {
            buffer_seek(_buf, buffer_seek_start, _pos + 10);
            _result.chan = buffer_read(_buf, buffer_u16);
            _result.rate = buffer_read(_buf, buffer_u32);
            buffer_seek(_buf, buffer_seek_start, _pos + 22);
            _result.bits = buffer_read(_buf, buffer_u16);
        } else if (_id == "data") {
            _result.data_offset = _pos + 8;
            _result.data_size   = _csz;
            return _result;
        }
        _pos += 8 + _csz + (_csz & 1); // advance past chunk, pad to even boundary
    }
    return _result;
}

function do_export_script() {
    var _base = (current_script_path != "") ? filename_change_ext(filename_name(current_script_path), "") : "screenplay";
    var _dest = get_save_filename("Hollywood High Package|*.zip", working_directory + _base + ".zip");
    if (_dest == "") return;

    var _tmp = working_directory + "__hhexport__/";
    directory_create(_tmp + "scenes/");

    // Save .hhi into temp dir
    var _hhi_name = (current_script_path != "") ? filename_name(current_script_path) : "screenplay.hhi";
    var _save_data = { version: 2, script: script_blocks, chars: characters, dict: dictionary_list };
    var _json = json_stringify(_save_data);
    var _buf = buffer_create(string_byte_length(_json) + 1, buffer_fixed, 1);
    buffer_write(_buf, buffer_string, _json);
    buffer_seek(_buf, buffer_seek_start, 0);
    var _cbuf = buffer_compress(_buf, 0, buffer_get_size(_buf));
    buffer_save(_cbuf, _tmp + _hhi_name);
    buffer_delete(_buf); buffer_delete(_cbuf);

    // Collect custom scenes referenced in the script
    var _seen_scenes = ds_map_create();
    for (var _i = 0; _i < array_length(script_blocks); _i++) {
        var _bl = script_blocks[_i];
        if (!variable_struct_exists(_bl, "type") || _bl.type != "scene") continue;
        if (!variable_struct_exists(_bl, "internal_name") || _bl.internal_name == "") continue;
        var _iname_lo = string_lower(_bl.internal_name);
        if (ds_map_exists(_seen_scenes, _iname_lo)) continue;
        ds_map_add(_seen_scenes, _iname_lo, true);
        for (var _s = 0; _s < array_length(all_scenes); _s++) {
            if (string_lower(all_scenes[_s].internal_name) != _iname_lo) continue;
            if (!all_scenes[_s].is_custom) break; // in pack, no file to bundle
            var _bg_src = datafiles_path + all_scenes[_s].path;
            if (file_exists(_bg_src)) file_copy(_bg_src, _tmp + "scenes/" + filename_name(_bg_src));
            // Include mask if present
            var _mexts = [".png", ".jpg", ".jpeg"];
            for (var _e = 0; _e < array_length(_mexts); _e++) {
                var _msrc = datafiles_path + "scenes/" + _bl.internal_name + "_mask" + _mexts[_e];
                if (file_exists(_msrc)) { file_copy(_msrc, _tmp + "scenes/" + filename_name(_msrc)); break; }
            }
            break;
        }
    }
    ds_map_destroy(_seen_scenes);

    // Collect custom sounds referenced in the script (loose files only, not in pack)
    var _seen_snds = ds_map_create();
    for (var _i = 0; _i < array_length(script_blocks); _i++) {
        var _bl = script_blocks[_i];
        if (!variable_struct_exists(_bl, "type") || _bl.type != "action") continue;
        if (!variable_struct_exists(_bl, "sfx_path") || _bl.sfx_path == "") continue;
        var _rel = string_replace(_bl.sfx_path, "sounds/sfx/", "sounds/");
        if (string_copy(_rel, 1, 7) != "sounds/") continue;
        var _pack_key = string_delete(_rel, 1, 7); // "folder/file.wav"
        if (ds_map_exists(_seen_snds, _pack_key)) continue;
        ds_map_add(_seen_snds, _pack_key, true);
        // Skip sounds that live in the pack
        if (global.sounds_pack_header != undefined && variable_struct_exists(global.sounds_pack_header, _pack_key)) continue;
        var _src = sfx_base_path + _pack_key;
        if (!file_exists(_src)) continue;
        var _slash = string_pos("/", _pack_key);
        if (_slash > 0) directory_create(_tmp + "sounds/" + string_copy(_pack_key, 1, _slash - 1) + "/");
        file_copy(_src, _tmp + "sounds/" + _pack_key);
    }
    ds_map_destroy(_seen_snds);

    // Write a .ps1 and execute it — PowerShell Compress-Archive handles the zip
    var _ps1 = working_directory + "__hhexport__.ps1";
    var _tmp_w  = string_replace_all(_tmp,  "/", "\\");
    var _dest_w = string_replace_all(_dest, "/", "\\");
    if (file_exists(_dest)) file_delete(_dest);
    var _f = file_text_open_write(_ps1);
    file_text_write_string(_f, "Compress-Archive -Path '" + _tmp_w + "*' -DestinationPath '" + _dest_w + "' -Force");
    file_text_close(_f);
    var _ps1_w = string_replace_all(_ps1, "/", "\\");
    external_call(global.win_exec_id, "powershell -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"" + _ps1_w + "\"", 0);

    export_state      = 1;
    export_dest_path  = _dest;
    export_tmp_dir    = _tmp;
    export_ps1_path   = _ps1;
    export_status_msg = "Exporting...";
    export_status_timer = 9999;
}

function start_particle_emitter(_effect, _ox, _oy, _angle_deg, _size, _duration_sec, _density = 2, _speed = 1.0, _spread = 65, _color = "red", _color_r = 200, _color_g = 0, _color_b = 0, _area_w = 0, _area_h = 0) {
    if (_effect == "laser") {
        var _frames = max(2, round(_duration_sec * 60));
        var _ang = degtorad(_angle_deg);
        var _dx = cos(_ang); var _dy = sin(_ang);
        // Compute beam length: stop at scene edge
        var _blen = 9999;
        if (abs(_dx) > 0.001) _blen = min(_blen, _dx>0 ? (scene_win_w-_ox)/_dx : -_ox/_dx);
        if (abs(_dy) > 0.001) _blen = min(_blen, _dy>0 ? (scene_win_h-_oy)/_dy : -_oy/_dy);
        _blen = max(0, _blen);
        // Stop early if beam hits a character — uses actual composite bounds per facing/pose
        var _char_scale = (scene_win_h * 1.5) / 450;
        for (var _lai = 0; _lai < array_length(preview_actors); _lai++) {
            var _la    = preview_actors[_lai];
            var _lface = variable_struct_exists(_la, "facing")     ? _la.facing     : 1;
            var _lpose = variable_struct_exists(_la, "pose")       ? _la.pose       : 1;
            var _lexpr = variable_struct_exists(_la, "expression") ? _la.expression : 21;

            var _layers = get_composite_character_sprite(_la.char_index, _lpose, _lexpr, _lface);
            if (array_length(_layers) == 0 || _layers[0].spr == -1) continue;

            var _body_spr = _layers[0].spr;
            var _body_w   = sprite_get_width(_body_spr);
            var _body_h   = sprite_get_height(_body_spr);

            // Compute composite bounding box in sprite-canvas units (same logic as draw_composite_character_ext)
            var _bb_x1 = 0; var _bb_x2 = _body_w;
            var _bb_y1 = 0;
            for (var _li2 = 1; _li2 < array_length(_layers); _li2++) {
                var _ll = _layers[_li2];
                if (_ll.spr == -1) continue;
                _bb_x1 = min(_bb_x1, _ll.dx);
                _bb_x2 = max(_bb_x2, _ll.dx + sprite_get_width(_ll.spr));
                _bb_y1 = min(_bb_y1, _ll.dy);
            }

            // Convert to scene coordinates (draw_x = act.x - body_w * scale / 2)
            var _draw_x0 = _la.x - _body_w * _char_scale * 0.5;
            var _draw_y0 = _la.y - _body_h * _char_scale;
            var _sc_x1 = _draw_x0 + _bb_x1 * _char_scale;
            var _sc_x2 = _draw_x0 + _bb_x2 * _char_scale;
            var _sc_y1 = max(_draw_y0 + _bb_y1 * _char_scale, -scene_win_h * 0.1);
            var _sc_y2 = _la.y + 5;

            // Skip source character (emitter inside box, with generous horizontal margin for eyes)
            if (_ox >= _sc_x1 - 8 && _ox <= _sc_x2 + 8 && _oy >= _sc_y1 && _oy <= _sc_y2) continue;

            var _lt = ray_aabb(_ox, _oy, _dx, _dy, _sc_x1, _sc_y1, _sc_x2, _sc_y2);
            if (_lt > 8 && _lt < _blen) _blen = _lt;
        }
        array_push(active_beams, {
            x: _ox, y: _oy,
            angle:            _ang,
            size:             _size,
            color:            _color,
            color_r:          _color_r,
            color_g:          _color_g,
            color_b:          _color_b,
            beam_len:         _blen,
            frames_total:     _frames,
            frames_remaining: _frames,
        });
        return;
    }
    if (_effect == "explosion") {
        var _frames = max(2, round(_duration_sec * 60));
        var _eang_base = 2.0 * pi / 7.0;
        var _eoffsets  = [0.0, 0.18, -0.12, 0.22, -0.08, 0.15, -0.20];
        var _angles = array_create(7);
        var _ang_offset = degtorad(_angle_deg);
        for (var _ai = 0; _ai < 7; _ai++) _angles[_ai] = _ai * _eang_base + _eoffsets[_ai] + _ang_offset;
        var _ergb = get_particle_rgb_ex(_color, _color_r, _color_g, _color_b);
        array_push(active_explosions, {
            x: _ox, y: _oy,
            size: _size,
            speed: _speed,
            spread: _spread,
            density: _density,
            color_r: _ergb.r, color_g: _ergb.g, color_b: _ergb.b,
            frames_total: _frames,
            frames_elapsed: 0,
            angles: _angles,
            sparks_done: false,
        });
        return;
    }
    array_push(active_emitters, {
        effect:           _effect,
        x:                _ox,
        y:                _oy,
        angle:            _angle_deg,
        size:             _size,
        density:          _density,
        speed:            _speed,
        spread:           _spread,
        color:            _color,
        color_r:          _color_r,
        color_g:          _color_g,
        color_b:          _color_b,
        area_w:           _area_w,
        area_h:           _area_h,
        frames_remaining: max(2, round(_duration_sec * 60)),
    });
}

function spawn_emitter_particle(_effect, _epx, _epy, _ea, _esz, _espd_mul, _ergb) {
    var _ep;
    if (_effect == "electrify") {
        // fresh: boosted toward white (bright spark); dying: dim, slightly desaturated
        var _espd = random_range(3.5, 11.0) * _esz * _espd_mul;
        var _elife = irandom_range(6, 16);
        _ep = { x: _epx, y: _epy, vx: cos(_ea)*_espd, vy: sin(_ea)*_espd,
                life: _elife, max_life: _elife, size: random_range(1.5, 3.5)*_esz,
                r:  min(255, _ergb.r + 80),  g:  min(255, _ergb.g + 80),  b:  min(255, _ergb.b + 80),
                r2: floor(_ergb.r * 0.2),    g2: floor(_ergb.g * 0.2),    b2: floor(_ergb.b * 0.3),
                gravity: 0, shape: "line", additive: true };
    } else if (_effect == "shatter") {
        // fresh: catch of light (slightly brighter); dying: darker, heavier
        var _espd = random_range(2.0, 9.0) * _esz * _espd_mul;
        var _elife = irandom_range(22, 38);
        _ep = { x: _epx, y: _epy, vx: cos(_ea)*_espd, vy: sin(_ea)*_espd,
                life: _elife, max_life: _elife, size: random_range(2.0, 5.5)*_esz,
                r:  min(255, floor(_ergb.r * 1.2 + 18)), g:  min(255, floor(_ergb.g * 1.2 + 18)), b:  min(255, floor(_ergb.b * 1.1 + 18)),
                r2: floor(_ergb.r * 0.3),                g2: floor(_ergb.g * 0.4),                b2: floor(_ergb.b * 0.55),
                shape: "shard" };
    } else if (_effect == "debris") {
        var _dtype = irandom(5);
        if (_dtype <= 1) {
            var _espd = random_range(1.2, 5.5) * _esz * _espd_mul;
            var _elife = irandom_range(30, 50);
            _ep = { x: _epx, y: _epy, vx: cos(_ea)*_espd, vy: sin(_ea)*_espd,
                    life: _elife, max_life: _elife, size: random_range(5, 11)*_esz,
                    r: _ergb.r, g: _ergb.g, b: _ergb.b,
                    r2: floor(_ergb.r * 0.3), g2: floor(_ergb.g * 0.3), b2: floor(_ergb.b * 0.3),
                    shape: "chunk", cw: random_range(0.45, 1.7), ch: random_range(0.2, 0.75),
                    rot: random_range(0, 2*pi), spin: random_range(-0.28, 0.28), gravity: random_range(0.25, 0.45) };
        } else if (_dtype <= 3) {
            var _espd = random_range(4.0, 13.0) * _esz * _espd_mul;
            var _elife = irandom_range(16, 30);
            _ep = { x: _epx, y: _epy, vx: cos(_ea)*_espd, vy: sin(_ea)*_espd,
                    life: _elife, max_life: _elife, size: random_range(6, 15)*_esz,
                    r: _ergb.r, g: _ergb.g, b: _ergb.b,
                    r2: floor(_ergb.r * 0.25), g2: floor(_ergb.g * 0.25), b2: floor(_ergb.b * 0.25),
                    shape: "shard", gravity: 0.18 };
        } else {
            var _dust_a = random_range(0, 2*pi);
            var _espd = random_range(0.6, 3.5) * _esz * _espd_mul;
            var _elife = irandom_range(22, 38);
            _ep = { x: _epx, y: _epy, vx: cos(_dust_a)*_espd, vy: sin(_dust_a)*_espd,
                    life: _elife, max_life: _elife, size: random_range(1.2, 3.2)*_esz,
                    r: _ergb.r, g: _ergb.g, b: _ergb.b,
                    r2: floor(_ergb.r * 0.2), g2: floor(_ergb.g * 0.2), b2: floor(_ergb.b * 0.2),
                    gravity: 0.08 };
        }
    } else if (_effect == "flame") {
        // fresh: yellow-hot shift of the chosen color; dying: dark ember
        var _espd = random_range(1.5, 4.0) * _esz * _espd_mul;
        var _elife = irandom_range(18, 32);
        _ep = { x: _epx, y: _epy,
                vx: cos(_ea)*_espd + random_range(-0.5, 0.5)*_esz,
                vy: sin(_ea)*_espd,
                life: _elife, max_life: _elife, size: random_range(3.0, 7.5)*_esz,
                r:  min(255, _ergb.r + 55),  g:  min(255, _ergb.g + 90),  b:  min(60, _ergb.b + 15),
                r2: floor(_ergb.r * 0.25),   g2: floor(_ergb.g * 0.08),   b2: 0,
                gravity: -0.06, additive: true };
    } else {
        // splatter / generic: bright on impact, darkens as it settles
        var _espd = random_range(1.5, 7.0) * _esz * _espd_mul;
        var _elife = irandom_range(26, 42);
        _ep = { x: _epx, y: _epy, vx: cos(_ea)*_espd, vy: sin(_ea)*_espd,
                life: _elife, max_life: _elife, size: random_range(2.5, 6.5)*_esz,
                r:  min(255, floor(_ergb.r * 1.25)), g:  min(255, floor(_ergb.g * 1.1)), b:  min(255, floor(_ergb.b * 1.1)),
                r2: floor(_ergb.r * 0.3),            g2: floor(_ergb.g * 0.2),           b2: floor(_ergb.b * 0.2) };
    }
    array_push(active_particles, _ep);
}

// Draw all active explosions. Called from both theater and editor sections.
// _bx/_by: screen-space base (scene_win_x/y or _stage_x/y)
// _sx/_sy: scale factors (1.0/1.0 for editor, _p_sx/_p_sy for theater)
function draw_active_explosions(_bx, _by, _sx, _sy) {
    if (array_length(active_explosions) == 0) return;
    for (var _exi = 0; _exi < array_length(active_explosions); _exi++) {
        var _ex = active_explosions[_exi];
        var _t  = clamp(_ex.frames_elapsed / max(1, _ex.frames_total), 0.0, 1.0);
        var _cx = _bx + _ex.x * _sx;
        var _cy = _by + _ex.y * _sy;
        var _sz  = _ex.size * _sy;
        var _mr  = 65.0 * _sz;
        var _ecr  = variable_struct_exists(_ex, "color_r") ? _ex.color_r : 165;
        var _ecg  = variable_struct_exists(_ex, "color_g") ? _ex.color_g : 12;
        var _ecb  = variable_struct_exists(_ex, "color_b") ? _ex.color_b : 8;
        var _espd = variable_struct_exists(_ex, "speed")   ? clamp(_ex.speed, 0.25, 3.0) : 1.0;
        var _espr = variable_struct_exists(_ex, "spread")  ? clamp(_ex.spread / 65.0, 0.15, 2.5) : 1.0;

        if (_t < 0.12) {
            // ---- WIND-UP: tiny compressed spark ----
            var _wp = _t / 0.12;
            var _wr = _sz * 7.0 * _wp * _wp;
            draw_set_alpha(0.95 * _wp);
            draw_set_color(make_color_rgb(12, 8, 8));
            draw_circle(_cx, _cy, _wr + _sz * 2.0, false);
            draw_set_color(make_color_rgb(
                min(255, floor(_ecr * 0.6 + 130)),
                min(255, floor(_ecg * 0.5 + 130)),
                min(255, floor(_ecb * 0.35 + 50))
            ));
            draw_circle(_cx, _cy, _wr, false);
            draw_set_color(c_white);
            draw_circle(_cx, _cy, _wr * 0.45, false);

        } else if (_t < 0.26) {
            // ---- FLASH: blinding white burst ----
            var _fp = (_t - 0.12) / 0.14;
            var _fr = _sz * lerp(9.0, _mr * 1.18, _fp * _fp);
            draw_set_alpha(1.0 - _fp * 0.32);
            draw_set_color(c_white);
            draw_circle(_cx, _cy, _fr, false);
            draw_set_alpha((1.0 - _fp * 0.32) * 0.80);
            draw_set_color(make_color_rgb(255, 252, 140));
            draw_circle(_cx, _cy, _fr * 0.68, false);

        } else {
            // ---- FIRE CLOUD + SMOKE ----
            var _ft = (_t - 0.26) / 0.74;

            // Radius: exponential ease-out growth, then smoke ring expands further
            var _grow = min(1.0, _ft / 0.40);
            var _r    = _mr * (1.0 - exp(-_grow * (3.8 * _espd)));
            var _sp   = max(0.0, (_ft - 0.55) / 0.45); // smoke phase 0→1
            var _fa   = 1.0 - _sp;                      // fire alive  1→0
            var _sr   = _r * (1.0 + _sp * 0.52);        // smoke ring expands past fire

            var _n   = 7;
            var _pad = max(2.0, _sz * 2.8);
            var _pd  = min(_sr * 1.5, _sr * 0.67 * _espr);
            var _pr  = _sr * min(0.65, 0.35 + 0.15 * _espr);

            // -- Black cartoon outline --
            draw_set_alpha(min(1.0, _fa * 0.94 + _sp * 0.52));
            draw_set_color(make_color_rgb(12, 8, 8));
            draw_circle(_cx, _cy, _sr + _pad, false);
            for (var _pi = 0; _pi < _n; _pi++) {
                var _pa = _ex.angles[_pi];
                draw_circle(_cx + cos(_pa)*_pd, _cy + sin(_pa)*_pd, _pr + _pad, false);
            }

            // -- Body (fire color → dark smoke grey) --
            draw_set_alpha(_fa * 0.92 + _sp * 0.50);
            draw_set_color(make_color_rgb(
                floor(lerp(50, _ecr, _fa)),
                floor(lerp(38, _ecg, _fa)),
                floor(lerp(32, _ecb, _fa))
            ));
            draw_circle(_cx, _cy, _sr, false);
            for (var _pi = 0; _pi < _n; _pi++) {
                var _pa = _ex.angles[_pi];
                draw_circle(_cx + cos(_pa)*_pd, _cy + sin(_pa)*_pd, _pr, false);
            }

            if (_fa > 0.04) {
                // -- Bright mid layer (brighter tint of fire color) --
                draw_set_alpha(_fa * 0.90);
                draw_set_color(make_color_rgb(
                    min(255, floor(_ecr * 1.22 + 40)),
                    min(255, floor(_ecg * 1.15 + 50)),
                    min(255, floor(_ecb + 8))
                ));
                draw_circle(_cx, _cy, _sr * 0.78, false);

                // -- Yellow-hot inner --
                draw_set_alpha(_fa * max(0.0, 1.0 - _sp * 1.4) * 0.92);
                draw_set_color(make_color_rgb(255, 232, 38));
                draw_circle(_cx, _cy, _sr * 0.52, false);

                // -- White core (fades earliest) --
                var _ca = _fa * max(0.0, 1.0 - _ft * 1.6) * 0.95;
                if (_ca > 0.02) {
                    draw_set_alpha(_ca);
                    draw_set_color(c_white);
                    draw_circle(_cx, _cy, _sr * 0.25, false);
                }
            }
        }
        draw_set_alpha(1.0);
    }
}

function fire_particle_effect(_effect, _ox, _oy, _angle_deg, _size = 1.0, _duration = 1.0, _density = 2, _color = "red", _color_r = 200, _color_g = 0, _color_b = 0, _area_w = 0, _area_h = 0) {
    var _sx0    = scene_win_x + _ox;
    var _sy0    = scene_win_y + _oy;
    var _angle  = degtorad(_angle_deg);
    var _spread = degtorad(65);
    var _count  = round(13 * _density);
    for (var _i = 0; _i < _count; _i++) {
        var _a;
        if (_i < round(_count * 0.77)) {
            _a = _angle + random_range(-_spread, _spread);
        } else {
            _a = random_range(0, 2 * pi);
        }
        var _spd = random_range(1.5, 7.0) * _size;
        var _life = irandom_range(26, 42);
        var _rgb = get_particle_rgb_ex(_color, _color_r, _color_g, _color_b);
        var _sx = _sx0 + random_range(-_area_w/2, _area_w/2);
        var _sy = _sy0 + random_range(-_area_h/2, _area_h/2);
        var _p = {
            x:        _sx,
            y:        _sy,
            vx:       cos(_a) * _spd,
            vy:       sin(_a) * _spd,
            life:     round(_life * _duration),
            max_life: round(_life * _duration),
            size:     random_range(2.5, 6.5) * _size,
            r:        _rgb.r,
            g:        _rgb.g,
            b:        _rgb.b,
        };
        array_push(active_particles, _p);
    }
}
