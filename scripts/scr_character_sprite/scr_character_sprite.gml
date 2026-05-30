/// @description Character sprite loading and compositing functions.

function get_character_sprite(_char_index) {
    if (_char_index < 0 || _char_index >= array_length(characters)) return -1;
    var _c = characters[_char_index];
    var _spr_nm = variable_struct_exists(_c, "sprite_name") ? _c.sprite_name : _c[$ "name"];
    if (ds_map_exists(char_sprites, _spr_nm)) return char_sprites[? _spr_nm];
    var _path = datafiles_path + "actors/" + string_lower(_spr_nm) + ".png";
    if (file_exists(_path)) {
        var _spr = sprite_add(_path, 1, false, false, 0, 0);
        ds_map_add(char_sprites, _spr_nm, _spr);
        return _spr;
    }
    return -1;
}

// Tiled character compositing.
// Layers: [0] lower body, [1] blank face (05), [2] mouth (31+mood), [3] eyes (11+expr)
// NEUTRAL / expressions 13-17: single full-body composite, other layers empty.
// Facing: ALL characters store their natural direction at LOW suffixes.
//   _use_high = (_facing_override * default_facing == -1) — correctly handles both
//   left-natural (default_facing=1, e.g. Anna) and right-natural (default_facing=-1, e.g. Sid).
// dx/dy deltas come from offsets.json (run extract_offsets.js to generate).
function get_composite_character_sprite(_char_index, _pose, _expression, _facing_override = undefined) {
    var _null_layer = { spr: -1, dx: 0, dy: 0 };

    if (_char_index < 0 || _char_index >= array_length(characters)) {
        return [_null_layer, _null_layer, _null_layer, _null_layer];
    }
    var _c = characters[_char_index];
    var _spr_nm = variable_struct_exists(_c, "sprite_name") ? _c.sprite_name : _c[$ "name"];
    if (_spr_nm == "NARRATOR") {
        return [_null_layer, _null_layer, _null_layer, _null_layer];
    }

    var _act_idx  = variable_struct_exists(_c, "act_index")     ? _c.act_index     : 1;
    var _def_face = variable_struct_exists(_c, "default_facing") ? _c.default_facing : 1;
    var _dir_name = string_lower(_spr_nm);

    var _use_high = (_facing_override != undefined) && (_facing_override * _def_face == -1);
    var _sfx_off  = _use_high ? 50 : 0;

    var _folder_path = datafiles_path + "actors/" + _spr_nm + "/";
    if (!directory_exists(_folder_path)) {
        _folder_path = datafiles_path + "actors/" + _dir_name + "/";
    }

    if (!directory_exists(_folder_path)) {
        var _bp = datafiles_path + "actors/" + _dir_name + ".png";
        if (!file_exists(_bp)) _bp = datafiles_path + "actors/" + _spr_nm + ".png";
        if (file_exists(_bp)) {
            var _fs;
            if (ds_map_exists(char_sprites, _spr_nm)) {
                _fs = char_sprites[? _spr_nm];
            } else {
                _fs = sprite_add(_bp, 1, false, false, 0, 0);
                ds_map_add(char_sprites, _spr_nm, _fs);
            }
            return [{ spr: _fs, dx: 0, dy: 0 }, _null_layer, _null_layer, _null_layer];
        }
        return [_null_layer, _null_layer, _null_layer, _null_layer];
    }

    if (!ds_map_exists(char_offsets_cache, _spr_nm)) {
        var _off_path = _folder_path + "offsets.json";
        if (file_exists(_off_path)) {
            var _off_str = "";
            var _off_f = file_text_open_read(_off_path);
            while (!file_text_eof(_off_f)) { _off_str += file_text_readln(_off_f); }
            file_text_close(_off_f);
            ds_map_add(char_offsets_cache, _spr_nm, json_parse(_off_str));
        } else {
            ds_map_add(char_offsets_cache, _spr_nm, undefined);
        }
    }
    var _off_data = char_offsets_cache[? _spr_nm];

    var _prefix = string(_act_idx) + string(_pose);

    if (!ds_map_exists(char_expr_cache, _spr_nm)) {
        var _ecfg_path = _folder_path + "expressions_config.json";
        if (file_exists(_ecfg_path)) {
            var _ecfg_str = "";
            var _ecfg_f = file_text_open_read(_ecfg_path);
            while (!file_text_eof(_ecfg_f)) { _ecfg_str += file_text_readln(_ecfg_f); }
            file_text_close(_ecfg_f);
            ds_map_add(char_expr_cache, _spr_nm, json_parse(_ecfg_str));
        } else {
            ds_map_add(char_expr_cache, _spr_nm, undefined);
        }
    }
    var _ecfg_data = char_expr_cache[? _spr_nm];
    var _ecfg_dir  = _use_high ? "high" : "low";
    var _ecfg_key  = "pose_" + string(_pose) + "_" + _ecfg_dir;
    var _ecfg_pc   = (_ecfg_data != undefined && variable_struct_exists(_ecfg_data, _ecfg_key)) ? _ecfg_data[$ _ecfg_key] : undefined;

    // --- Layer 0: Lower body ---
    var _lower_spr  = -1;
    var _lower_file = "";
    var _lo_ox = 0; var _lo_oy = 0;

    if (_ecfg_pc != undefined && variable_struct_exists(_ecfg_pc, "body_file") && _ecfg_pc.body_file != "") {
        _lower_file = _ecfg_pc.body_file;
        var _lk_cfg = _spr_nm + "_" + _lower_file;
        if (ds_map_exists(char_sprites, _lk_cfg)) {
            _lower_spr = char_sprites[? _lk_cfg];
        } else if (file_exists(_folder_path + _lower_file)) {
            _lower_spr = sprite_add(_folder_path + _lower_file, 1, false, false, 0, 0);
            ds_map_add(char_sprites, _lk_cfg, _lower_spr);
        }
        if (_lower_spr != -1 && _off_data != undefined) {
            var _bk2_cfg = string_copy(_lower_file, 1, string_length(_lower_file) - 4);
            if (variable_struct_exists(_off_data, _bk2_cfg)) { var _bv = _off_data[$ _bk2_cfg]; _lo_ox = _bv[0]; _lo_oy = _bv[1]; }
        }
    }

    if (_lower_spr == -1 || _expression < 1 || _expression > 20) {
        var _lo_start = (_expression < 1 || _expression > 20) ? (1 + _sfx_off) : (6 + _sfx_off);
        var _lo_end   = 10 + _sfx_off;
        var _lower_sz = 0;

        for (var _n = _lo_start; _n <= _lo_end; _n++) {
            var _ns = (_n < 10 ? "0" : "") + string(_n);
            var _cf = "pose_" + _prefix + _ns + ".png";
            if (file_exists(_folder_path + _cf)) {
                var _fb = file_bin_open(_folder_path + _cf, 0);
                var _sz = (_fb != -1) ? file_bin_size(_fb) : 0;
                if (_fb != -1) file_bin_close(_fb);
                if (_sz > _lower_sz) { _lower_sz = _sz; _lower_file = _cf; }
            }
        }
        if (_lower_sz >= 2000) {
            var _lk = _spr_nm + "_" + _lower_file;
            if (ds_map_exists(char_sprites, _lk)) {
                _lower_spr = char_sprites[? _lk];
            } else {
                _lower_spr = sprite_add(_folder_path + _lower_file, 1, false, false, 0, 0);
                ds_map_add(char_sprites, _lk, _lower_spr);
            }
        }
        if (_lower_spr == -1) {
            var _fb3 = datafiles_path + "actors/" + _dir_name + ".png";
            if (!file_exists(_fb3)) _fb3 = datafiles_path + "actors/" + _spr_nm + ".png";
            if (file_exists(_fb3)) {
                if (ds_map_exists(char_sprites, _spr_nm)) _lower_spr = char_sprites[? _spr_nm];
                else { _lower_spr = sprite_add(_fb3, 1, false, false, 0, 0); ds_map_add(char_sprites, _spr_nm, _lower_spr); }
            }
        }
        if (_lower_file != "" && _off_data != undefined) {
            var _lo_key = string_copy(_lower_file, 1, string_length(_lower_file) - 4);
            if (variable_struct_exists(_off_data, _lo_key)) {
                var _loo = _off_data[$ _lo_key]; _lo_ox = _loo[0]; _lo_oy = _loo[1];
            }
        }
    }

    if (_expression < 1 || _expression > 20) {
        return [{ spr: _lower_spr, dx: 0, dy: 0 }, _null_layer, _null_layer, _null_layer];
    }

    // happy sad angry cool flrt shy emb sur fri msc gui par con bor sil pan pom cnt ref wis
    var _mood_map = [0, 2, 3, 1, 0, 1, 1, 1, 1, 0, 2, 1, 1, 1, 0, 3, 1, 0, 1, 2];
    var _mouth_idx = _mood_map[clamp(_expression - 1, 0, 19)];

    var _face_n   = 5  + _sfx_off;
    var _mouth_n  = 31 + _mouth_idx + _sfx_off;
    var _eyes_n   = 10 + _expression + _sfx_off;

    var _face_sfx  = (_face_n  < 10 ? "0" : "") + string(_face_n);
    var _mouth_sfx = (_mouth_n < 10 ? "0" : "") + string(_mouth_n);
    var _eyes_sfx  = (_eyes_n  < 10 ? "0" : "") + string(_eyes_n);

    // --- Layer 1: blank face ---
    var _face_file = "pose_" + _prefix + _face_sfx + ".png";
    if (_ecfg_pc != undefined && variable_struct_exists(_ecfg_pc, "face_file") && _ecfg_pc.face_file != "") _face_file = _ecfg_pc.face_file;
    var _face_spr = -1;
    if (file_exists(_folder_path + _face_file)) {
        var _fk = _spr_nm + "_" + _face_file;
        if (ds_map_exists(char_sprites, _fk)) {
            _face_spr = char_sprites[? _fk];
        } else {
            _face_spr = sprite_add(_folder_path + _face_file, 1, false, false, 0, 0);
            ds_map_add(char_sprites, _fk, _face_spr);
        }
    }
    var _face_dx = 0; var _face_dy = 0;
    var _face_ok = string_replace(_face_file, ".png", "");
    if (_off_data != undefined && variable_struct_exists(_off_data, _face_ok)) {
        var _fov = _off_data[$ _face_ok]; _face_dx = _fov[0] - _lo_ox; _face_dy = _fov[1] - _lo_oy;
    }
    if (_ecfg_pc != undefined) {
        if (variable_struct_exists(_ecfg_pc, "face_dx_offsets") && variable_struct_exists(_ecfg_pc.face_dx_offsets, _face_file)) {
            _face_dx += _ecfg_pc.face_dx_offsets[$ _face_file];
        } else if (variable_struct_exists(_ecfg_pc, "face_dx")) {
            _face_dx = _ecfg_pc.face_dx;
        }
        if (variable_struct_exists(_ecfg_pc, "face_dy_offsets") && variable_struct_exists(_ecfg_pc.face_dy_offsets, _face_file)) {
            _face_dy += _ecfg_pc.face_dy_offsets[$ _face_file];
        } else if (variable_struct_exists(_ecfg_pc, "face_dy")) {
            _face_dy = _ecfg_pc.face_dy;
        }
    }

    // --- Layer 2: mouth ---
    var _mouth_file = "pose_" + _prefix + _mouth_sfx + ".png";
    if (_ecfg_pc != undefined && variable_struct_exists(_ecfg_pc, "mouth_files")) {
        var _mf_map = _ecfg_pc.mouth_files;
        var _expr_key = string(_expression);
        var _mood_key = string(_mouth_idx);
        if (variable_struct_exists(_mf_map, _expr_key) && _mf_map[$ _expr_key] != "") {
            _mouth_file = _mf_map[$ _expr_key];
        } else if (variable_struct_exists(_mf_map, _mood_key) && _mf_map[$ _mood_key] != "") {
            _mouth_file = _mf_map[$ _mood_key];
        }
    }
    var _mouth_spr = -1;
    if (file_exists(_folder_path + _mouth_file)) {
        var _mk = _spr_nm + "_" + _mouth_file;
        if (ds_map_exists(char_sprites, _mk)) {
            _mouth_spr = char_sprites[? _mk];
        } else {
            _mouth_spr = sprite_add(_folder_path + _mouth_file, 1, false, false, 0, 0);
            ds_map_add(char_sprites, _mk, _mouth_spr);
        }
    }
    var _mouth_dx = 0; var _mouth_dy = 0;
    var _mouth_ok = string_replace(_mouth_file, ".png", "");
    if (_off_data != undefined && variable_struct_exists(_off_data, _mouth_ok)) {
        var _mov = _off_data[$ _mouth_ok]; _mouth_dx = _mov[0] - _lo_ox; _mouth_dy = _mov[1] - _lo_oy;
    }
    if (_ecfg_pc != undefined) {
        var _expr_key = string(_expression);
        if (variable_struct_exists(_ecfg_pc, "mouth_dx_expr_offsets") && variable_struct_exists(_ecfg_pc.mouth_dx_expr_offsets, _expr_key)) {
            _mouth_dx += _ecfg_pc.mouth_dx_expr_offsets[$ _expr_key];
        } else if (variable_struct_exists(_ecfg_pc, "mouth_dx_offsets") && variable_struct_exists(_ecfg_pc.mouth_dx_offsets, _mouth_file)) {
            _mouth_dx += _ecfg_pc.mouth_dx_offsets[$ _mouth_file];
        } else if (variable_struct_exists(_ecfg_pc, "mouth_dx")) {
            _mouth_dx = _ecfg_pc.mouth_dx;
        }
        if (variable_struct_exists(_ecfg_pc, "mouth_dy_expr_offsets") && variable_struct_exists(_ecfg_pc.mouth_dy_expr_offsets, _expr_key)) {
            _mouth_dy += _ecfg_pc.mouth_dy_expr_offsets[$ _expr_key];
        } else if (variable_struct_exists(_ecfg_pc, "mouth_dy_offsets") && variable_struct_exists(_ecfg_pc.mouth_dy_offsets, _mouth_file)) {
            _mouth_dy += _ecfg_pc.mouth_dy_offsets[$ _mouth_file];
        } else if (variable_struct_exists(_ecfg_pc, "mouth_dy")) {
            _mouth_dy = _ecfg_pc.mouth_dy;
        }
    }

    // --- Layer 3: eyes ---
    var _eyes_file = "pose_" + _prefix + _eyes_sfx + ".png";
    if (_ecfg_pc != undefined && variable_struct_exists(_ecfg_pc, "eyes_files")) {
        var _ef_map = _ecfg_pc.eyes_files;
        var _ef_key = string(_expression);
        if (variable_struct_exists(_ef_map, _ef_key) && _ef_map[$ _ef_key] != "") _eyes_file = _ef_map[$ _ef_key];
    }
    var _eyes_spr = -1;
    if (file_exists(_folder_path + _eyes_file)) {
        var _ek = _spr_nm + "_" + _eyes_file;
        if (ds_map_exists(char_sprites, _ek)) {
            _eyes_spr = char_sprites[? _ek];
        } else {
            _eyes_spr = sprite_add(_folder_path + _eyes_file, 1, false, false, 0, 0);
            ds_map_add(char_sprites, _ek, _eyes_spr);
        }
    }
    var _eyes_dx = 0; var _eyes_dy = 0;
    var _eyes_ok = string_replace(_eyes_file, ".png", "");
    if (_off_data != undefined && variable_struct_exists(_off_data, _eyes_ok)) {
        var _eov = _off_data[$ _eyes_ok]; _eyes_dx = _eov[0] - _lo_ox; _eyes_dy = _eov[1] - _lo_oy;
    }
    if (_ecfg_pc != undefined) {
        var _expr_key = string(_expression);
        if (variable_struct_exists(_ecfg_pc, "eyes_dx_expr_offsets") && variable_struct_exists(_ecfg_pc.eyes_dx_expr_offsets, _expr_key)) {
            _eyes_dx += _ecfg_pc.eyes_dx_expr_offsets[$ _expr_key];
        } else if (variable_struct_exists(_ecfg_pc, "eyes_dx_offsets") && variable_struct_exists(_ecfg_pc.eyes_dx_offsets, _eyes_file)) {
            _eyes_dx += _ecfg_pc.eyes_dx_offsets[$ _eyes_file];
        } else if (variable_struct_exists(_ecfg_pc, "eyes_dx")) {
            _eyes_dx = _ecfg_pc.eyes_dx;
        }
        if (variable_struct_exists(_ecfg_pc, "eyes_dy_expr_offsets") && variable_struct_exists(_ecfg_pc.eyes_dy_expr_offsets, _expr_key)) {
            _eyes_dy += _ecfg_pc.eyes_dy_expr_offsets[$ _expr_key];
        } else if (variable_struct_exists(_ecfg_pc, "eyes_dy_offsets") && variable_struct_exists(_ecfg_pc.eyes_dy_offsets, _eyes_file)) {
            _eyes_dy += _ecfg_pc.eyes_dy_offsets[$ _eyes_file];
        } else if (variable_struct_exists(_ecfg_pc, "eyes_dy")) {
            _eyes_dy = _ecfg_pc.eyes_dy;
        }
    }

    var _bdx_c = 0; var _bdy_c = 0;
    var _body_ok = string_replace(_lower_file, ".png", "");
    if (_off_data != undefined && variable_struct_exists(_off_data, _body_ok)) {
        var _bv = _off_data[$ _body_ok]; _bdx_c = _bv[0] - _lo_ox; _bdy_c = _bv[1] - _lo_oy;
    }
    if (_ecfg_pc != undefined) {
        if (variable_struct_exists(_ecfg_pc, "body_dx_offsets") && variable_struct_exists(_ecfg_pc.body_dx_offsets, _lower_file)) {
            _bdx_c += _ecfg_pc.body_dx_offsets[$ _lower_file];
        } else if (variable_struct_exists(_ecfg_pc, "body_dx")) {
            _bdx_c = _ecfg_pc.body_dx;
        }
        if (variable_struct_exists(_ecfg_pc, "body_dy_offsets") && variable_struct_exists(_ecfg_pc.body_dy_offsets, _lower_file)) {
            _bdy_c += _ecfg_pc.body_dy_offsets[$ _lower_file];
        } else if (variable_struct_exists(_ecfg_pc, "body_dy")) {
            _bdy_c = _ecfg_pc.body_dy;
        }
    }

    var _layer_body  = { spr: _lower_spr, dx: _bdx_c,              dy: _bdy_c              };
    var _layer_face  = { spr: _face_spr,  dx: _face_dx  + _bdx_c,  dy: _face_dy  + _bdy_c  };
    var _layer_mouth = { spr: _mouth_spr, dx: _mouth_dx + _bdx_c,  dy: _mouth_dy + _bdy_c,  is_mouth: true };
    var _layer_eyes  = { spr: _eyes_spr,  dx: _eyes_dx  + _bdx_c,  dy: _eyes_dy  + _bdy_c  };

    // face_over_mouth: draw face after mouth so long noses always overlay mouth frames
    if (_ecfg_pc != undefined && variable_struct_exists(_ecfg_pc, "face_over_mouth") && _ecfg_pc.face_over_mouth) {
        return [_layer_body, _layer_mouth, _layer_face, _layer_eyes];
    }
    return [_layer_body, _layer_face, _layer_mouth, _layer_eyes];
}

// Returns animation-frame sprites for the speaking mouth cycle.
// Frame count is derived from the gap between same-range base mouth files so
// trailing files (e.g. eye sprites packed after the last mouth group) are not
// accidentally included. Results are cached per base-mouth file.
function get_mouth_anim_sprites(_char_index, _pose, _expression, _facing_override = undefined) {
    if (_char_index < 0 || _char_index >= array_length(characters)) return [];
    var _c = characters[_char_index];
    var _spr_nm = variable_struct_exists(_c, "sprite_name") ? _c.sprite_name : _c[$ "name"];
    if (_spr_nm == "NARRATOR") return [];
    if (_expression < 1 || _expression > 20) return [];

    var _def_face = variable_struct_exists(_c, "default_facing") ? _c.default_facing : 1;
    var _use_high = (_facing_override != undefined) && (_facing_override * _def_face == -1);
    var _sfx_off  = _use_high ? 50 : 0;

    var _dir_name    = string_lower(_spr_nm);
    var _folder_path = datafiles_path + "actors/" + _spr_nm + "/";
    if (!directory_exists(_folder_path)) _folder_path = datafiles_path + "actors/" + _dir_name + "/";
    if (!directory_exists(_folder_path)) return [];

    var _act_idx = variable_struct_exists(_c, "act_index") ? _c.act_index : 1;
    var _prefix  = string(_act_idx) + string(_pose);

    var _ecfg_data = ds_map_exists(char_expr_cache, _spr_nm) ? char_expr_cache[? _spr_nm] : undefined;
    var _ecfg_dir  = _use_high ? "high" : "low";
    var _ecfg_key  = "pose_" + string(_pose) + "_" + _ecfg_dir;
    var _ecfg_pc   = (_ecfg_data != undefined && variable_struct_exists(_ecfg_data, _ecfg_key)) ? _ecfg_data[$ _ecfg_key] : undefined;

    var _mood_map   = [0, 2, 3, 1, 0, 1, 1, 1, 1, 0, 2, 1, 1, 1, 0, 3, 1, 0, 1, 2];
    var _mouth_idx  = _mood_map[clamp(_expression - 1, 0, 19)];
    var _mouth_n    = 31 + _mouth_idx + _sfx_off;
    var _mouth_sfx  = (_mouth_n < 10 ? "0" : "") + string(_mouth_n);
    var _mouth_file = "pose_" + _prefix + _mouth_sfx + ".png";
    if (_ecfg_pc != undefined && variable_struct_exists(_ecfg_pc, "mouth_files")) {
        var _mf_map  = _ecfg_pc.mouth_files;
        var _expr_key = string(_expression);
        var _mood_key = string(_mouth_idx);
        if (variable_struct_exists(_mf_map, _expr_key) && _mf_map[$ _expr_key] != "") {
            _mouth_file = _mf_map[$ _expr_key];
        } else if (variable_struct_exists(_mf_map, _mood_key) && _mf_map[$ _mood_key] != "") {
            _mouth_file = _mf_map[$ _mood_key];
        }
    }

    var _cache_key = _spr_nm + "_manim_" + _mouth_file;
    if (ds_map_exists(mouth_anim_cache, _cache_key)) return mouth_anim_cache[? _cache_key];

    var _stem     = string_delete(_mouth_file, 1, 5);
    _stem         = string_delete(_stem, string_length(_stem) - 3, 4);
    var _base_num = real(_stem);

    // "Local range": 50-file band for same pose + same direction to prevent cross-direction bleed
    var _hundred  = floor(_base_num / 100) * 100;
    var _half_off = ((_base_num - _hundred) >= 50) ? 50 : 0;
    var _range_lo = _hundred + _half_off;
    var _range_hi = _range_lo + 49;

    var _all_bases = ds_map_create();
    var _peers     = [];
    if (_ecfg_data != undefined) {
        var _pose_keys = variable_struct_get_names(_ecfg_data);
        var _seen = ds_map_create();
        for (var _pk = 0; _pk < array_length(_pose_keys); _pk++) {
            var _pc = _ecfg_data[$ _pose_keys[_pk]];
            if (variable_struct_exists(_pc, "mouth_files")) {
                var _mf       = _pc.mouth_files;
                var _mk_names = variable_struct_get_names(_mf);
                for (var _mk = 0; _mk < array_length(_mk_names); _mk++) {
                    var _mfn = _mf[$ _mk_names[_mk]];
                    if (_mfn != "" && !ds_map_exists(_seen, _mfn)) {
                        ds_map_add(_seen, _mfn, 1);
                        var _ns = string_delete(_mfn, 1, 5);
                        _ns    = string_delete(_ns, string_length(_ns) - 3, 4);
                        var _n = real(_ns);
                        ds_map_add(_all_bases, _mfn, 1);
                        if (_n >= _range_lo && _n <= _range_hi) array_push(_peers, _n);
                    }
                }
            }
        }
        ds_map_destroy(_seen);
    }
    array_sort(_peers, true);

    // Derive max frame count from gap between sorted same-range peers.
    // For the last peer, mirror the previous gap to avoid over-scanning.
    var _max_frames = 4;
    var _peer_pos   = -1;
    for (var _pi = 0; _pi < array_length(_peers); _pi++) {
        if (_peers[_pi] == _base_num) { _peer_pos = _pi; break; }
    }
    if (_peer_pos >= 0) {
        if (_peer_pos < array_length(_peers) - 1) {
            _max_frames = _peers[_peer_pos + 1] - _base_num - 1;
        } else if (_peer_pos > 0) {
            _max_frames = _base_num - _peers[_peer_pos - 1] - 2; // last group has 1 fewer valid frame than interior groups
        }
    }
    _max_frames = clamp(_max_frames, 1, 6);

    // Per-frame position correction from offsets.json.
    // mouth_anim_anchor: 0 = base (closed) mouth is reference, 1 = first open frame is reference.
    var _off_ma = ds_map_exists(char_offsets_cache, _spr_nm) ? char_offsets_cache[? _spr_nm] : undefined;
    var _anch   = (_ecfg_pc != undefined && variable_struct_exists(_ecfg_pc, "mouth_anim_anchor")) ? _ecfg_pc.mouth_anim_anchor : 0;
    var _bstem  = "pose_" + string(_base_num);
    var _base_ax = 0; var _base_ay = 0;
    if (_off_ma != undefined && variable_struct_exists(_off_ma, _bstem)) {
        var _bv_ma = _off_ma[$ _bstem]; _base_ax = _bv_ma[0]; _base_ay = _bv_ma[1];
    }

    var _anim_frames = [];
    for (var _f = 1; _f <= _max_frames; _f++) {
        var _ff = "pose_" + string(_base_num + _f) + ".png";
        if (ds_map_exists(_all_bases, _ff)) break;
        if (!file_exists(_folder_path + _ff)) break;
        var _fk = _spr_nm + "_" + _ff;
        var _fspr;
        if (ds_map_exists(char_sprites, _fk)) {
            _fspr = char_sprites[? _fk];
        } else {
            _fspr = sprite_add(_folder_path + _ff, 1, false, false, 0, 0);
            ds_map_add(char_sprites, _fk, _fspr);
        }
        var _ff_stem = "pose_" + string(_base_num + _f);
        var _fax = _base_ax; var _fay = _base_ay;
        if (_off_ma != undefined && variable_struct_exists(_off_ma, _ff_stem)) {
            var _fov_ma = _off_ma[$ _ff_stem]; _fax = _fov_ma[0]; _fay = _fov_ma[1];
        }
        array_push(_anim_frames, { spr: _fspr, dx: _fax, dy: _fay });
    }

    // Convert absolute offsets to deltas relative to the anchor frame
    var _ref_ax = _base_ax; var _ref_ay = _base_ay;
    if (_anch >= 1 && _anch <= array_length(_anim_frames)) {
        _ref_ax = _anim_frames[_anch - 1].dx; _ref_ay = _anim_frames[_anch - 1].dy;
    }
    for (var _f2 = 0; _f2 < array_length(_anim_frames); _f2++) {
        _anim_frames[_f2].dx -= _ref_ax; _anim_frames[_f2].dy -= _ref_ay;
    }

    ds_map_destroy(_all_bases);
    ds_map_add(mouth_anim_cache, _cache_key, _anim_frames);
    return _anim_frames;
}

// Renders composite character layers onto an offscreen 1:1 surface with nearest-neighbor,
// then draws the merged surface to the screen at the target scale with linear filtering.
// This completely eliminates seams and outlines between layers while providing beautiful, smooth scaling!
function draw_composite_character_ext(_layers, _draw_x, _draw_y, _scale, _alpha, _color = c_white, _outline = false, _outline_width = 3, _outline_color = c_yellow, _scissor_clip = undefined) {
    var _first_spr = -1;
    for (var _i = 0; _i < array_length(_layers); _i++) {
        if (_layers[_i].spr != -1) {
            _first_spr = _layers[_i].spr;
            break;
        }
    }
    if (_first_spr == -1) return;

    var _csw = sprite_get_width(_first_spr);
    var _csh = sprite_get_height(_first_spr);

    // Compute bounding box of all layers to fit the surface perfectly
    var _min_x = undefined;
    var _min_y = undefined;
    var _max_x = undefined;
    var _max_y = undefined;

    for (var _li = 0; _li < array_length(_layers); _li++) {
        var _l = _layers[_li];
        if (_l.spr != -1) {
            var _lw = sprite_get_width(_l.spr);
            var _lh = sprite_get_height(_l.spr);
            if (_min_x == undefined) {
                _min_x = _l.dx;
                _min_y = _l.dy;
                _max_x = _l.dx + _lw;
                _max_y = _l.dy + _lh;
            } else {
                _min_x = min(_min_x, _l.dx);
                _min_y = min(_min_y, _l.dy);
                _max_x = max(_max_x, _l.dx + _lw);
                _max_y = max(_max_y, _l.dy + _lh);
            }
        }
    }

    if (_min_x == undefined) return;

    var _surf_w = ceil(_max_x - _min_x);
    var _surf_h = ceil(_max_y - _min_y);

    if (_surf_w <= 0 || _surf_h <= 0) return;

    // Use a persistent global surface to avoid recreation overhead
    if (!variable_global_exists("composite_char_surface")) {
        global.composite_char_surface = -1;
    }

    if (!surface_exists(global.composite_char_surface)) {
        global.composite_char_surface = surface_create(_surf_w, _surf_h);
    } else {
        var _cur_w = surface_get_width(global.composite_char_surface);
        var _cur_h = surface_get_height(global.composite_char_surface);
        if (_cur_w < _surf_w || _cur_h < _surf_h) {
            surface_free(global.composite_char_surface);
            global.composite_char_surface = surface_create(max(_cur_w, _surf_w), max(_cur_h, _surf_h));
        }
    }

    surface_set_target(global.composite_char_surface);
    draw_clear_alpha(c_black, 0);

    // Disable texture filtering while drawing elements to the 1:1 surface
    var _old_filter = gpu_get_texfilter();
    gpu_set_texfilter(false);

    for (var _li = 0; _li < array_length(_layers); _li++) {
        var _l = _layers[_li];
        if (_l.spr != -1) {
            draw_sprite_ext(_l.spr, 0, _l.dx - _min_x, _l.dy - _min_y, 1, 1, 0, c_white, 1);
        }
    }

    surface_reset_target();

    // Restore the scissor clip on the application surface target before drawing,
    // so that the composed surface itself is drawn beautifully clipped to the window!
    if (_scissor_clip != undefined) {
        gpu_set_scissor(_scissor_clip[0], _scissor_clip[1], _scissor_clip[2], _scissor_clip[3]);
    }

    // Now draw the pre-composited surface to the screen with linear texture filtering
    gpu_set_texfilter(true);

    var _surf_draw_x = _draw_x + _min_x * _scale;
    var _surf_draw_y = _draw_y + _min_y * _scale;

    // Draw outline around the pre-composed surface if enabled
    if (_outline) {
        gpu_set_fog(true, _outline_color, 0, 1);
        for (var _ox = -_outline_width; _ox <= _outline_width; _ox += _outline_width) {
            for (var _oy = -_outline_width; _oy <= _outline_width; _oy += _outline_width) {
                if (_ox != 0 || _oy != 0) {
                    draw_surface_part_ext(global.composite_char_surface, 0, 0, _surf_w, _surf_h, _surf_draw_x + _ox, _surf_draw_y + _oy, _scale, _scale, c_white, _alpha);
                }
            }
        }
        gpu_set_fog(false, c_black, 0, 0);
    }

    // Draw the final seamless composite character
    draw_surface_part_ext(global.composite_char_surface, 0, 0, _surf_w, _surf_h, _surf_draw_x, _surf_draw_y, _scale, _scale, _color, _alpha);

    // Restore previous texture filter state
    gpu_set_texfilter(_old_filter);
}
