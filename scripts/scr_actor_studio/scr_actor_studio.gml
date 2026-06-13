/// @description Actor Studio — custom actor scanning, parsing, and composite loading.
/*
 * Custom actors live in datafiles/actors/(custom) <Name>/ as loose PNGs + actor.json.
 * The studio reads them directly (no packing) so users can drop a friend into the world.
 * See memory/custom_actor_plan.md for the full design.
 */

// Reads and parses a JSON file from disk. Returns the parsed struct/array, or undefined.
function actor_studio_read_json(_path) {
    if (!file_exists(_path)) return undefined;
    var _s = "";
    var _f = file_text_open_read(_path);
    while (!file_text_eof(_f)) { _s += file_text_readln(_f); }
    file_text_close(_f);
    try { return json_parse(_s); }
    catch (_e) { return undefined; }
}

// Scans the actors/ folder for parenthesized custom-actor folders — e.g. actors/(Mike)/ —
// and loads each actor.json. The parens mark a folder as a user-made custom actor, keeping it
// distinct from preset actor folders (which are unparenthesized / live in actors.pack).
// In the shipped build there is no datafiles/, so _actors_base resolves to working_directory/actors/.
// Returns an array of structs: { folder, name, data } — data is undefined if json missing/invalid.
function actor_studio_scan(_actors_base) {
    var _list = [];
    if (!directory_exists(_actors_base)) return _list;

    var _name = file_find_first(_actors_base + "(*)", fa_directory);
    while (_name != "") {
        var _folder = _actors_base + _name + "/";
        // Confirm it's a directory wrapped in parens (file_find_first can return loose files too)
        if (directory_exists(_folder)
            && string_char_at(_name, 1) == "("
            && string_char_at(_name, string_length(_name)) == ")") {
            var _json = actor_studio_read_json(_folder + "actor.json");
            // Display name: prefer json "name", else strip the surrounding parens from the folder
            var _disp = string_trim(string_copy(_name, 2, string_length(_name) - 2));
            if (_json != undefined && is_struct(_json) && variable_struct_exists(_json, "name")) {
                _disp = _json.name;
            }
            array_push(_list, { folder: _folder, name: _disp, data: _json });
        }
        _name = file_find_next();
    }
    file_find_close();
    return _list;
}

// Loads a sprite from a path with caching keyed on the absolute path.
// _cache is a ds_map of path -> sprite index. Returns -1 if the file is missing.
function actor_studio_sprite(_cache, _path) {
    if (_path == "" || _path == undefined) return -1;
    if (ds_map_exists(_cache, _path)) return _cache[? _path];
    var _spr = -1;
    if (file_exists(_path)) {
        _spr = sprite_add(_path, 1, false, false, 0, 0);
    }
    _cache[? _path] = _spr; // cache misses too, so we don't retry disk every frame
    return _spr;
}

// Resolves a [x, y] offset array from a struct field, defaulting to [0, 0].
function actor_studio_offset(_struct, _field) {
    if (_struct != undefined && is_struct(_struct) && variable_struct_exists(_struct, _field)) {
        var _o = _struct[$ _field];
        if (is_array(_o) && array_length(_o) >= 2) return _o;
    }
    return [0, 0];
}

// Draws a 44x44 arrow/label button and returns true if the mouse is hovering it.
function actor_studio_arrow(_x, _y, _ch, _mx, _my, _c_hi, _c_panel, _c_accent) {
    var _w = 44; var _h = 44;
    var _hov = (_mx > _x && _mx < _x + _w && _my > _y && _my < _y + _h);
    draw_set_color(_hov ? _c_hi : _c_panel);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_color(_c_accent);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    draw_set_color(c_white);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_text(_x + _w / 2, _y + _h / 2, _ch);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    return _hov;
}
