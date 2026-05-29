/// @description Scene sprite loading, dimension detection, actor preview, and SFX browser.

function get_scene_sprite(_internal_name) {
    if (_internal_name == "") return -1;
    if (ds_map_exists(scene_sprites, _internal_name)) return scene_sprites[? _internal_name];
    for (var i = 0; i < array_length(all_scenes); i++) {
        if (all_scenes[i].internal_name == _internal_name) {
            var _path = working_directory + "images/" + all_scenes[i].path;
            if (file_exists(_path)) {
                var _spr = sprite_add(_path, 1, false, false, 0, 0);
                ds_map_add(scene_sprites, _internal_name, _spr);
                return _spr;
            }
            break;
        }
    }
    var _exts_check = [".png", ".jpg", ".jpeg"];
    for (var e = 0; e < array_length(_exts_check); e++) {
        var _path = working_directory + "images/backgrounds/" + _internal_name + _exts_check[e];
        if (file_exists(_path)) {
            var _spr = sprite_add(_path, 1, false, false, 0, 0);
            ds_map_add(scene_sprites, _internal_name, _spr);
            return _spr;
        }
    }
    return -1;
}

// Scans the top/bottom chroma rows to find where the live content area starts.
function detect_scene_live_area(_spr) {
    if (_spr == -1) { scene_live_top = 0; scene_live_bottom = 0; return; }
    var _sw = sprite_get_width(_spr);
    var _sh = sprite_get_height(_spr);
    var _surf = surface_create(_sw, _sh);
    surface_set_target(_surf);
    draw_clear_alpha(c_black, 0);
    draw_sprite(_spr, 0, 0, 0);
    surface_reset_target();
    var _chroma = surface_getpixel(_surf, 0, 0);
    var _top = 0;
    for (var i = 0; i < min(_sh/2, 100); i++) {
        if (surface_getpixel(_surf, 0, i) == _chroma) _top = i + 1; else break;
    }
    var _bottom = 0;
    for (var i = _sh - 1; i > max(_sh/2, _sh - 101); i--) {
        if (surface_getpixel(_surf, 0, i) == _chroma) _bottom = (_sh - 1) - i + 1; else break;
    }
    surface_free(_surf);
    scene_live_top    = _top    / _sh;
    scene_live_bottom = _bottom / _sh;
}

function set_scene_dimensions(_spr) {
    if (_spr == -1) {
        scene_win_w = 800; scene_win_h = 450;
        scene_win_x = 50;  scene_win_y = 60;
        scene_live_top = 0; scene_live_bottom = 0;
        return;
    }
    var _sw = sprite_get_width(_spr);
    var _sh = sprite_get_height(_spr);
    var _ratio = _sw / _sh;
    var _max_w = 800; var _max_h = 450;
    scene_win_w = _max_w; scene_win_h = _max_w / _ratio;
    if (scene_win_h > _max_h) { scene_win_h = _max_h; scene_win_w = _max_h * _ratio; }
    scene_win_x = 50 + (800 - scene_win_w) / 2;
    scene_win_y = 60  + (450 - scene_win_h) / 2;
    detect_scene_live_area(_spr);
}

function refresh_sfx_folders() {
    action_modal_sfx_folders = [];
    var _file = file_find_first(sfx_base_path + "*", fa_directory);
    while (_file != "") {
        if (_file != "." && _file != ".." && directory_exists(sfx_base_path + _file)) array_push(action_modal_sfx_folders, _file);
        _file = file_find_next();
    }
    file_find_close();
    array_sort(action_modal_sfx_folders, function(a, b) {
        var _la = string_lower(a); var _lb = string_lower(b);
        if (_la < _lb) return -1; if (_la > _lb) return 1; return 0;
    });
}

function refresh_sfx_files(_folder) {
    action_modal_sfx_files = [];
    var _path = sfx_base_path + _folder + "/";
    var _file = file_find_first(_path + "*.wav", 0);
    while (_file != "") {
        array_push(action_modal_sfx_files, _file);
        _file = file_find_next();
    }
    file_find_close();
    array_sort(action_modal_sfx_files, function(a, b) {
        var _la = string_lower(a); var _lb = string_lower(b);
        if (_la < _lb) return -1; if (_la > _lb) return 1; return 0;
    });
}

// Rewinds actor state to what it was at (or just before) a given block index.
function update_preview_actors_for_block(_idx, _inclusive) {
    preview_actors = [];
    if (_idx < 0 || _idx >= array_length(script_blocks)) return;

    active_scene_block_idx = -1;
    for (var j = _idx; j >= 0; j--) {
        if (variable_struct_exists(script_blocks[j], "type") && script_blocks[j].type == "scene") {
            active_scene_block_idx = j; break;
        }
    }

    if (active_scene_block_idx != -1) {
        var _scene = script_blocks[active_scene_block_idx];
        if (variable_struct_exists(_scene, "actors")) {
            for (var a = 0; a < array_length(_scene.actors); a++) {
                var _sa = _scene.actors[a];
                var _face = variable_struct_exists(_sa, "facing")     ? _sa.facing     : 1;
                var _pose = variable_struct_exists(_sa, "pose")       ? _sa.pose       : 1;
                var _expr = variable_struct_exists(_sa, "expression") ? _sa.expression : 21;
                array_push(preview_actors, { char_index: _sa.char_index, x: _sa.x, y: _sa.y, is_base: true, facing: _face, pose: _pose, expression: _expr });
                char_facings[_sa.char_index] = _face;
            }
        }

        var _limit = _inclusive ? _idx : (_idx - 1);
        for (var j = active_scene_block_idx + 1; j <= _limit; j++) {
            var _b = script_blocks[j];
            if (variable_struct_exists(_b, "type") && _b.type == "action") {
                var _aname   = string_lower(_b.action_name);
                var _is_enter = (string_pos("enter", _aname) > 0);
                var _is_exit  = (string_pos("exit",  _aname) > 0);
                var _is_left  = (string_pos("left",  _aname) > 0);
                var _spd  = variable_struct_exists(_b, "speed")     ? _b.speed     : 1.5;
                var _moon = (variable_struct_exists(_b, "moonwalk") && _b.moonwalk) || (string_pos("[moonwalk]", _aname) > 0);

                var _act_idx = -1;
                for (var k = 0; k < array_length(preview_actors); k++) {
                    if (preview_actors[k].char_index == _b.char_index) { _act_idx = k; break; }
                }

                if (_is_enter) {
                    if (_act_idx == -1) {
                        var _spr = get_character_sprite(_b.char_index);
                        var _w = (_spr != -1) ? sprite_get_width(_spr) * ((scene_win_h * 1.5) / 450) : 100;
                        var _start_x  = _is_left ? (_w/2) + 20 : scene_win_w - (_w/2) - 20;
                        var _base_face = _is_left ? -1 : 1;
                        var _final_x = variable_struct_exists(_b, "target_x") ? _b.target_x : _start_x;
                        var _final_y = variable_struct_exists(_b, "target_y") ? _b.target_y : (scene_win_h * 0.8);
                        var _c = characters[_b.char_index];
                        var _pose = variable_struct_exists(_c, "pose")       ? _c.pose       : 1;
                        var _expr = variable_struct_exists(_c, "expression") ? _c.expression : 21;
                        char_facings[_b.char_index] = _moon ? -_base_face : _base_face;
                        array_push(preview_actors, { char_index: _b.char_index, x: _final_x, y: _final_y, is_base: false, facing: char_facings[_b.char_index], pose: _pose, expression: _expr });
                    } else {
                        if (variable_struct_exists(_b, "target_x")) {
                            var _base_f = (_b.target_x > preview_actors[_act_idx].x) ? -1 : 1;
                            preview_actors[_act_idx].facing = _moon ? -_base_f : _base_f;
                            preview_actors[_act_idx].x = _b.target_x;
                            preview_actors[_act_idx].y = _b.target_y;
                        }
                        if (string_pos("left", _aname) > 0) {
                            var _base_f = -1; preview_actors[_act_idx].facing = _moon ? -_base_f : _base_f;
                        } else if (string_pos("right", _aname) > 0) {
                            var _base_f = 1; preview_actors[_act_idx].facing = _moon ? -_base_f : _base_f;
                        }
                        char_facings[_b.char_index] = preview_actors[_act_idx].facing;
                    }
                } else if (_is_exit) {
                    if (_act_idx != -1) array_delete(preview_actors, _act_idx, 1);
                } else if (string_pos("turn", _aname) > 0) {
                    if (_act_idx != -1) { preview_actors[_act_idx].facing *= -1; char_facings[_b.char_index] = preview_actors[_act_idx].facing; }
                } else if (string_pos("moves", _aname) > 0) {
                    if (_act_idx != -1 && variable_struct_exists(_b, "target_x")) {
                        var _base_f = (_b.target_x > preview_actors[_act_idx].x) ? -1 : 1;
                        preview_actors[_act_idx].facing = _moon ? -_base_f : _base_f;
                        preview_actors[_act_idx].x = _b.target_x;
                        preview_actors[_act_idx].y = _b.target_y;
                        char_facings[_b.char_index] = preview_actors[_act_idx].facing;
                    }
                } else if (string_pos("poses", _aname) > 0) {
                    if (_act_idx != -1) {
                        var _p_pos = string_pos("poses ", _aname);
                        if (_p_pos > 0) {
                            var _p_num = real(string_copy(_aname, _p_pos + 6, 1));
                            if (_p_num >= 1 && _p_num <= 4) preview_actors[_act_idx].pose = _p_num;
                        }
                        var _m_start = string_pos("(", _aname); var _m_end = string_pos(")", _aname);
                        if (_m_start > 0 && _m_end > _m_start) {
                            var _mood_str = string_upper(string_copy(_aname, _m_start + 1, _m_end - _m_start - 1));
                            for (var m = 0; m < array_length(mood_names); m++) {
                                if (mood_names[m] == _mood_str) { preview_actors[_act_idx].expression = m + 1; break; }
                            }
                        }
                    }
                }
            }
        }
    }
}

function play_from_index(_idx) {
    if (_idx < 0 || _idx >= array_length(script_blocks)) return;
    scene_edit_mode = false;
    insertion_idx   = -1;
    update_preview_actors_for_block(_idx, false);
    playing_block_index  = _idx;
    playing_linked_index = -1;
    is_speaking          = false;
    speaking_pause_timer = -1;
    active_requests      = [];
    action_animating     = false;
    active_animations    = [];
    audio_stop_all();
    tts_stop();
}
