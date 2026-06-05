/// @description Canned animation data loading, sprite caching, and trigger matching.

// Lazy-loads animations.json for a character. Returns the parsed array or undefined.
function canned_anim_get_data(_char_index) {
    if (_char_index < 0 || _char_index >= array_length(characters)) return undefined;
    var _c    = characters[_char_index];
    var _name = variable_struct_exists(_c, "sprite_name") ? _c.sprite_name : _c.name;

    if (ds_map_exists(char_anim_cache, _name)) return char_anim_cache[? _name];

    var _path = datafiles_path + "config/" + _name + "/animations.json";
    if (!file_exists(_path)) {
        ds_map_add(char_anim_cache, _name, undefined);
        return undefined;
    }

    var _str = ""; var _f = file_text_open_read(_path);
    while (!file_text_eof(_f)) { _str += file_text_readln(_f); }
    file_text_close(_f);
    var _data = json_parse(_str);
    ds_map_add(char_anim_cache, _name, _data);
    return _data;
}

// Returns the +250 flipped variant of a sprite filename.
function canned_anim_flipped_name(_filename) {
    var _dot = string_last_pos(".", _filename);
    if (_dot <= 1) return _filename;
    var _us = string_last_pos("_", string_copy(_filename, 1, _dot - 1));
    if (_us <= 0) return _filename;
    var _num = real(string_copy(_filename, _us + 1, _dot - _us - 1));
    return string_copy(_filename, 1, _us) + string(_num + 250) + string_copy(_filename, _dot, string_length(_filename) - _dot + 1);
}

// Returns the sprite filename adjusted for the actor's facing direction.
// Adds 250 to the number in the filename when actor faces opposite of character's default_facing.
// Sound files are unaffected — only call this for sprite frames.
function canned_anim_facing_sprite(_filename, _char_index, _actor_facing) {
    var _char = characters[_char_index];
    var _def = variable_struct_exists(_char, "default_facing") ? _char.default_facing : 1;
    if (_actor_facing == _def) return _filename;
    var _dot = string_last_pos(".", _filename);
    if (_dot <= 1) return _filename;
    var _us = string_last_pos("_", string_copy(_filename, 1, _dot - 1));
    if (_us <= 0) return _filename;
    var _num = real(string_copy(_filename, _us + 1, _dot - _us - 1));
    return string_copy(_filename, 1, _us) + string(_num + 250) + string_copy(_filename, _dot, string_length(_filename) - _dot + 1);
}

// Returns the animation struct whose triggers array contains _action_name, or undefined.
function canned_anim_find(_char_index, _action_name) {
    var _data = canned_anim_get_data(_char_index);
    if (_data == undefined) return undefined;
    var _needle = string_lower(_action_name);
    // Strip "CHARNAME (" prefix and ")" suffix from blocks inserted via the action modal
    var _open = string_pos("(", _needle);
    if (_open > 0) {
        var _close = string_last_pos(")", _needle);
        if (_close > _open) _needle = string_copy(_needle, _open + 1, _close - _open - 1);
    }
    for (var i = 0; i < array_length(_data); i++) {
        var _anim = _data[i];
        if (string_lower(_anim.name) == _needle) return _anim;
        var _trigs = _anim.triggers;
        for (var t = 0; t < array_length(_trigs); t++) {
            if (string_lower(_trigs[t]) == _needle) return _anim;
        }
    }
    return undefined;
}

// Loads (and caches) a canned animation sprite frame. Returns a GML sprite index or -1.
function canned_anim_load_sprite(_char_index, _filename) {
    if (_char_index < 0 || _char_index >= array_length(characters)) return -1;
    var _c    = characters[_char_index];
    var _name = variable_struct_exists(_c, "sprite_name") ? _c.sprite_name : _c.name;
    var _key  = "CANNED_" + _name + "_" + _filename;

    if (ds_map_exists(char_sprites, _key)) return char_sprites[? _key];

    var _dir     = string_lower(_name);
    var _folder  = datafiles_path + "actors/" + _name + "/";
    if (!directory_exists(_folder)) _folder = datafiles_path + "actors/" + _dir + "/";

    var _full = _folder + _filename;
    var _spr  = -1;

    // Check loose file first, then actors.pack
    if (file_exists(_full)) {
        _spr = sprite_add(_full, 1, false, false, 0, 0);
    } else if (global.actors_pack_header != undefined) {
        var _pfx = string_lower(_name);
        var _pk  = _pfx + "/" + _filename;
        if (!variable_struct_exists(global.actors_pack_header, _pk)) {
            _pk = _name + "/" + _filename;
        }
        if (variable_struct_exists(global.actors_pack_header, _pk)) {
            var _entry = global.actors_pack_header[$ _pk];
            var _buf   = buffer_create(_entry.size, buffer_fixed, 1);
            buffer_seek(global.actors_pack_buffer, buffer_seek_start, _entry.offset);
            buffer_copy(global.actors_pack_buffer, _entry.offset, _entry.size, _buf, 0);
            _spr = sprite_add_from_buffer(_buf, _entry.size);
            buffer_delete(_buf);
        }
    }

    ds_map_add(char_sprites, _key, _spr);
    return _spr;
}

// Advances an animation state struct to its first drawable sprite frame,
// firing any leading sound records. Call once on construction.
function canned_anim_seek_next_sprite(_anim_state) {
    var _frames = _anim_state.anim_data.frames;
    while (_anim_state.frame_idx < array_length(_frames)) {
        var _f = _frames[_anim_state.frame_idx];
        if (_f.type == "sound") {
            canned_anim_fire_sound(_anim_state.char_index, _f);
            _anim_state.frame_idx++;
        } else if (_f.type == "sprite") {
            break;
        } else {
            _anim_state.frame_idx++;
        }
    }
}

// Plays a WAV at an absolute path through the shared test_sfx preview slots.
function canned_anim_play_abs(_abs_path) {
    if (!file_exists(_abs_path)) return;
    if (test_sfx_sound  != -1) { audio_free_buffer_sound(test_sfx_sound);  test_sfx_sound  = -1; }
    if (test_sfx_buffer != -1) { buffer_delete(test_sfx_buffer);           test_sfx_buffer = -1; }
    var _tmp = buffer_load(_abs_path);
    if (_tmp == -1) return;
    var _sz  = buffer_get_size(_tmp);
    test_sfx_buffer = buffer_create(_sz, buffer_fixed, 1);
    buffer_copy(_tmp, 0, _sz, test_sfx_buffer, 0);
    buffer_delete(_tmp);
    var _wav  = parse_wav_header(test_sfx_buffer);
    var _fmt  = (_wav.bits == 16) ? buffer_s16 : buffer_u8;
    var _cfmt = (_wav.chan == 2) ? audio_stereo : audio_mono;
    test_sfx_sound = audio_create_buffer_sound(test_sfx_buffer, _fmt, _wav.rate, _wav.data_offset, _wav.data_size, _cfmt);
    if (test_sfx_sound != -1) audio_play_sound(test_sfx_sound, 1, false);
}

// Plays a sound frame's file during animation preview/playback.
function canned_anim_fire_sound(_char_index, _sound_frame) {
    if (!variable_struct_exists(_sound_frame, "file") || _sound_frame.file == undefined || _sound_frame.file == "" || _sound_frame.file == "null") return;
    var _c   = characters[_char_index];
    var _nm  = variable_struct_exists(_c, "sprite_name") ? _c.sprite_name : _c.name;
    // file stored as e.g. "GUS\audio\burp.wav" relative to actors root
    var _abs = datafiles_path + "actors\\" + _sound_frame.file;
    canned_anim_play_abs(_abs);
}

// Saves the in-memory animation data back to animations.json for a character.
function canned_anim_save(_char_index) {
    var _data = canned_anim_get_data(_char_index);
    if (_data == undefined) return;
    var _c    = characters[_char_index];
    var _name = variable_struct_exists(_c, "sprite_name") ? _c.sprite_name : _c.name;
    var _path = datafiles_path + "config/" + _name + "/animations.json";
    var _f    = file_text_open_write(_path);
    file_text_write_string(_f, json_stringify(_data, true));
    file_text_close(_f);
}

// Returns a sorted array of pose_*.png filenames in the character's actor folder.
function canned_anim_sprite_list(_char_index) {
    if (_char_index < 0 || _char_index >= array_length(characters)) return [];
    var _c    = characters[_char_index];
    var _name = variable_struct_exists(_c, "sprite_name") ? _c.sprite_name : _c.name;
    var _dir  = string_lower(_name);
    var _folder = datafiles_path + "actors/" + _name + "/";
    if (!directory_exists(_folder)) _folder = datafiles_path + "actors/" + _dir + "/";
    var _list = [];
    var _ff = file_find_first(_folder + "pose_*.png", fa_none | fa_readonly | fa_hidden | fa_sysfile | fa_archive);
    while (_ff != "") {
        array_push(_list, _ff);
        _ff = file_find_next();
    }
    file_find_close();
    array_sort(_list, true);
    return _list;
}
