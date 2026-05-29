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
    var _is_scene  = (variable_struct_exists(_b, "type") && _b.type == "scene");
    var _is_action = (variable_struct_exists(_b, "type") && _b.type == "action");
    if (_is_scene || _is_action) {
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
        if (string_pos("play sfx", _aname) > 0) return "sfx";
        if (string_pos("display title", _aname) > 0) return "title";
        if (string_pos("enter", _aname) > 0 || string_pos("exit", _aname) > 0 || string_pos("move", _aname) > 0) return "move";
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
