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
        // Stop early if beam hits a character
        var _char_scale = (scene_win_h * 1.5) / 450;
        var _char_hw = 55 * _char_scale;
        var _char_ht = 360 * _char_scale;
        for (var _lai = 0; _lai < array_length(preview_actors); _lai++) {
            var _la = preview_actors[_lai];
            // Skip the character whose body contains the emitter (laser-eyes source)
            if (_ox >= _la.x - _char_hw && _ox <= _la.x + _char_hw && _oy >= _la.y - _char_ht && _oy <= _la.y + 5) continue;
            var _lt = ray_aabb(_ox, _oy, _dx, _dy, _la.x - _char_hw, _la.y - _char_ht, _la.x + _char_hw, _la.y + 5);
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
