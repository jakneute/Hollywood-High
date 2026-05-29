/// @description Initialize Screenplay Editor Engine
/*
 * HOLLYWOOD HIGH - PROFESSIONAL SCREENPLAY EDITOR
 * This script initializes the core text engine, TTS integration, and UI state.
 */

//// --- 1. EXTERNAL LIBRARIES ---
if (!variable_global_exists("win_exec_id")) {
    global.win_exec_id = external_define("kernel32.dll", "WinExec", dll_stdcall, ty_real, 2, ty_string, ty_real);
}

// --- 1b. WINDOW SCALING ---
window_set_min_width(640);
window_set_min_height(480);
window_set_max_width(display_get_width());
window_set_max_height(display_get_height());
window_set_size(1280, 960);
surface_resize(application_surface, 1280, 960);
display_set_gui_size(1280, 960);
room_width = 1280;
room_height = 960;

// Enable views to enforce 1280x960 internal resolution while allowing window resize stretching
view_enabled = true;
view_visible[0] = true;
view_xport[0] = 0;
view_yport[0] = 0;
view_wport[0] = 1280;
view_hport[0] = 960;
view_camera[0] = camera_create_view(0, 0, 1280, 960, 0, -1, -1, -1, 0, 0);

// --- 2. UI & LAYOUT CONSTANTS ---
scene_win_x = 50; scene_win_y = 60; scene_win_w = 800; scene_win_h = 450; // Scene window (16:9)
box_x = 50; box_y = 570; box_w = 1180; box_h = 370; // Main text box
btn_play_w = 100; btn_play_h = 35; // Play Button
btn_play_x = (box_x + box_w / 2) - (btn_play_w / 2); btn_play_y = 535; 

dropdown_open = false;
dropdown_scroll_y = 0;
dropdown_w = 350;
dropdown_h = 35;
btn_edit_w        = 130;
btn_edit_h        = 35;
btn_edit_x        = box_x + box_w - btn_edit_w;
btn_edit_y        = 535;
dropdown_x        = btn_edit_x - 15 - dropdown_w;
dropdown_y        = 535;

char_sel_x = 880; char_sel_y = 60; char_sel_w = 350; char_sel_h = 450;
char_sel_scroll_y = 0;
btn_theater_x = 880; btn_theater_y = 15; btn_theater_w = 140; btn_theater_h = 35;

// --- 2c. DICTIONARY STATE ---
dictionary_open = false;
dictionary_list = []; // Array of {written: "", pronunciation: ""}
dictionary_scroll_y = 0;
dict_focused_entry = -1; 
dict_focused_field = 0; // 0: Written, 1: Pronunciation
dict_caret_pos = 0;
btn_dictionary_w = 140; btn_dictionary_h = 35;
btn_dictionary_x = scene_win_x + scene_win_w - btn_dictionary_w;
btn_dictionary_y = scene_win_y - 45;

// --- 2b. POSE & EXPRESSION PARAMETERS STATE ---
pose_modal_open = false;
pose_modal_temp_pose = 1;
pose_modal_locked_pose = 1;
pose_modal_edit_mode = false;
pose_modal_target_index = -1;
expression_modal_open = false;
expression_modal_temp_expr = 21;
expression_modal_locked_expr = 21;
selected_pose = 1;
selected_expression = 21; // Default NEUTRAL
mood_names = [
    "HAPPY", "SAD", "ANGRY", "COOL", "FLIRTATIOUS",
    "SHY", "EMBARRASSED", "SURPRISED", "FRIGHTENED", "MISCHIEVOUS",
    "GUILTY", "PARANOID", "CONFUSED", "BORED", "SILLY",
    "PANICKED", "POMPOUS", "CONTENT", "REFLECTIVE", "WISTFUL",
    "NEUTRAL"
];
pose_names = ["POSE 1", "POSE 2", "POSE 3", "POSE 4"];

// --- 2c. MOVEMENT PARAMETERS STATE ---
move_modal_open = false;
move_speed_index = 2; // Default: WALK
move_speeds = [0.6, 1.25, 1.9, 3.1, 5.6];
move_speed_labels = ["CRAWL", "SLOW", "WALK", "JOG", "RUN"];
moonwalk_enabled = false;
move_modal_temp_speed_index = 2;
move_modal_temp_moonwalk = false;
move_modal_edit_mode = false;
move_modal_target_index = -1;

theater_mode = false;
theater_paused = false;
theater_subtitles = "";
theater_subtitle_scroll_y = 0;
theater_active_char = -1;
speaking_phonetic_ratio = 1.0; // Ratio of visual text length to phonetic length

ctrl_x = 880; ctrl_y = char_sel_y + char_sel_h + 20; ctrl_w = 350; ctrl_h = 150;
slider_x = ctrl_x + 30; 
slider_w = 25; slider_h = 100; // Scaled down sliders to fit
pitch_y = ctrl_y + 40;
speed_y = ctrl_y + 160;

radio_x = ctrl_x + 100;
effort_y = ctrl_y + 40;
quality_y = ctrl_y + 140;

// --- 3. EDITOR CORE STATE ---
script_text      = "";      // The full body of the screenplay
script_blocks = [];

focused_block = -1;           // Index of the block currently being typed in
playing_block_index = -1;    // Index of the block currently being spoken
playing_linked_index = -1;   // Index of secondary linked block being spoken
block_scroll_y = 0;          // Global scroll position for the list
preview_actors = [];         // Dynamically calculated actors for the current block

btn_add_x = box_x; btn_add_y = dropdown_y;
btn_add_scene_x = 0; btn_add_scene_y = 0;
btn_add_action_x = 0; btn_add_action_y = 0;

last_played_block_index = -1;

global.tts_request_id = 0;  // Unique ID per speech call
dragging_preview_idx = -1;
drag_preview_x = 0;
drag_preview_y = 0;
drag_preview_char = -1;
active_requests = [];        // Array of all active TTS request IDs
keyboard_string  = "";      // GameMaker built-in for text capture
caret_pos        = 0;      // Current cursor index in the string
key_repeat_timer = 0;        // Timer for repeating keys
key_repeat_delay = 0;        // Delay before first repeat
last_key_pressed = -1;       // Tracking the key currently held
selection_start  = 0;      // Start of the highlight block
selection_end    = 0;      // End of the highlight block
is_selecting     = false;  // Whether the user is dragging the mouse
cursor_timer     = 0;      // Used for caret blinking
cursor_visible   = true;   // Blinking visibility toggle

// --- 4. CORE ENGINE METHODS ---

/**
 * Recalculates the height for a specific block.
 */
update_block_height = function(_idx) {
    if (_idx < 0 || _idx >= array_length(script_blocks)) return;
    var _b = script_blocks[_idx];
    var _wrap_w = box_w - 120;
    
    var _is_scene = (variable_struct_exists(_b, "type") && _b.type == "scene");
    var _is_action = (variable_struct_exists(_b, "type") && _b.type == "action");
    
    if (_is_scene || _is_action) {
        _b.height = 85; 
    } else {
        // Default box height is 70px, providing breathing room for text.
        // We add 16px of vertical padding and then 25px for the header/name area.
        var _txt_h = string_height_ext(_b.text, 28, _wrap_w);
        _b.height = 25 + max(70, _txt_h + 16);
    }
};

/**
 * Processes text through the dictionary before sending it to the TTS engine.
 * Performs case-insensitive, whole-word replacement to ensure script integrity while fixing audio.
 */
apply_dictionary = function(_text) {
    var _out = _text;
    var _delims = " .,!?;:()[]<>\"'/\n\r\t"; // Characters that define word boundaries
    
    for (var i = 0; i < array_length(dictionary_list); i++) {
        var _entry = dictionary_list[i];
        var _find = string_lower(_entry.written); // Search using lowercase
        var _repl = _entry.pronunciation;
        if (_find == "" || _repl == "") continue;
        
        var _pos = 1;
        while (true) {
            var _out_l = string_lower(_out); // Check against lowercase version of text
            _pos = string_pos_ext(_find, _out_l, _pos);
            if (_pos == 0) break;
            
            var _is_start = (_pos == 1 || string_pos(string_char_at(_out, _pos - 1), _delims) > 0);
            var _is_end   = (_pos + string_length(_find) > string_length(_out) || string_pos(string_char_at(_out, _pos + string_length(_find)), _delims) > 0);
            
            if (_is_start && _is_end) {
                _out = string_delete(_out, _pos, string_length(_find)); // Delete original casing
                _out = string_insert(_repl, _out, _pos); // Insert phonetic version
                _pos += string_length(_repl);
            } else {
                _pos += string_length(_find); // Skip this partial match
            }
        }
    }
    return _out;
};

/**
 * Iterates through all blocks to ensure heights are correct.
 */
update_all_block_heights = function() {
    for (var i = 0; i < array_length(script_blocks); i++) {
        update_block_height(i);
    }
};

/**
 * Safely deletes a portion of a string.
 */
safe_delete = function(_str, _start, _count) {
    if (string_length(_str) == 0) return "";
    var _s = clamp(_start, 1, string_length(_str));
    var _c = min(_count, string_length(_str) - _s + 1);
    if (_c <= 0) return _str;
    return string_delete(_str, _s, _c);
};

/**
 * Calculates the X and Y offset for a caret position within wrapped text.
 */
get_text_pos = function(_txt, _target_pos, _wrap_w, _line_h) {
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
};

get_link_type = function(_block) {
    if (variable_struct_exists(_block, "type") && _block.type == "action") {
        var _aname = string_lower(_block.action_name);
        if (string_pos("play sfx", _aname) > 0) return "sfx";
        if (string_pos("display title", _aname) > 0) return "title";
        if (string_pos("enter", _aname) > 0 || string_pos("exit", _aname) > 0 || string_pos("move", _aname) > 0) return "move";
    } else if (!variable_struct_exists(_block, "type") || _block.type == "voice") {
        return "voice";
    }
    return "other";
};

// --- 5. TTS ENGINE & CHARACTERS ---
all_voices = tts_refresh_voices(); 

// default_facing: 1 = low suffixes (03/05/06/11-22), -1 = high suffixes (53/55/56/61-72)
characters = [
    { name: "NARRATOR",  voice_id: all_voices[0].voice_id,  pitch: 50, speed: 50, mode: 0, style: 0, tweaked: false, sprite: -1, act_index: 0,  pose: 1, expression: 21, default_facing:  1 },
    { name: "GUS",       voice_id: all_voices[18].voice_id, pitch: 50, speed: 50, mode: 0, style: 0, tweaked: false, sprite: -1, act_index: 11, pose: 1, expression: 10, default_facing:  1 }, // mischievous
    { name: "LILLY",     voice_id: all_voices[1].voice_id,  pitch: 60, speed: 45, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 12, pose: 1, expression:  1, default_facing: -1 }, // happy
    { name: "MATT",      voice_id: all_voices[4].voice_id,  pitch: 40, speed: 55, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 13, pose: 1, expression:  6, default_facing:  1 }, // shy
    { name: "JENNY",     voice_id: all_voices[2].voice_id,  pitch: 70, speed: 60, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 14, pose: 1, expression:  4, default_facing: -1 }, // cool
    { name: "SUSAN",     voice_id: all_voices[7].voice_id,  pitch: 45, speed: 40, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 15, pose: 1, expression:  9, default_facing: -1 }, // frightened
    { name: "GARY",      voice_id: all_voices[5].voice_id,  pitch: 30, speed: 35, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 16, pose: 1, expression:  8, default_facing:  1 }, // surprised
    { name: "RUTH",      voice_id: all_voices[13].voice_id, pitch: 20, speed: 30, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 17, pose: 1, expression:  1, default_facing:  1 }, // happy
    { name: "GLENN",     voice_id: all_voices[15].voice_id, pitch: 55, speed: 50, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 18, pose: 1, expression:  4, default_facing: -1 }, // cool
    { name: "BABY",      voice_id: all_voices[3].voice_id,  pitch: 90, speed: 40, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 19, pose: 1, expression:  1, default_facing:  1 }, // happy
    { name: "STELLA",    voice_id: all_voices[1].voice_id,  pitch: 55, speed: 30, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 20, pose: 1, expression:  1, default_facing:  1 }, // happy
    { name: "ANNA",      voice_id: all_voices[2].voice_id,  pitch: 45, speed: 65, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 21, pose: 1, expression:  1, default_facing:  1 }, // happy
    { name: "ED",        voice_id: all_voices[16].voice_id, pitch: 65, speed: 70, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 22, pose: 1, expression:  1, default_facing:  1 }, // happy
    { name: "LARRY",     voice_id: all_voices[0].voice_id,  pitch: 40, speed: 30, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 1,  pose: 1, expression: 13, default_facing: -1 }, // confused
    { name: "SID",       voice_id: all_voices[17].voice_id, pitch: 75, speed: 50, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 2,  pose: 1, expression:  4, default_facing: -1 }, // cool
    { name: "TIFFANIE",  voice_id: all_voices[6].voice_id,  pitch: 60, speed: 55, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 3,  pose: 1, expression: 21, default_facing:  1 }, // pompous
    { name: "ARTIE",     voice_id: all_voices[11].voice_id, pitch: 30, speed: 45, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 4,  pose: 1, expression:  7, default_facing:  1 }, // embarrassed
    { name: "CHARLOTTE", voice_id: all_voices[1].voice_id,  pitch: 80, speed: 40, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 5,  pose: 1, expression: 15, default_facing: -1 }, // silly
    { name: "CHUCK",     voice_id: all_voices[14].voice_id, pitch: 70, speed: 60, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 6,  pose: 1, expression:  6, default_facing:  1 }, // shy
    { name: "BILLIE",    voice_id: all_voices[3].voice_id,  pitch: 85, speed: 70, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 7,  pose: 1, expression:  8, default_facing: -1 }, // surprised
    { name: "JJ",        voice_id: all_voices[12].voice_id, pitch: 50, speed: 75, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 8,  pose: 1, expression:  5, default_facing:  1 }, // flirtatious
    { name: "BEV",       voice_id: all_voices[7].voice_id,  pitch: 35, speed: 65, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 9,  pose: 1, expression: 11, default_facing:  1 }, // guilty
    { name: "LUCILLE",   voice_id: all_voices[13].voice_id, pitch: 50, speed: 25, mode: 0, style: 0, tweaked: true,  sprite: -1, act_index: 10, pose: 1, expression:  2, default_facing: -1 }  // sad
];

// Dynamic datafiles directory resolver (checks absolute project path for live development reads/writes)
datafiles_path = "d:/Projects/Game Maker/Hollywood High/datafiles/";
if (!directory_exists(datafiles_path)) {
    datafiles_path = working_directory;
}

// Character sprites and per-sprite canvas offsets (loaded lazily from offsets.json)
char_sprites      = ds_map_create();
char_offsets_cache = ds_map_create(); // char_name → struct parsed from offsets.json, or undefined
char_expr_cache    = ds_map_create(); // char_name → struct parsed from expressions_config.json, or undefined
char_sel_layer_cache = array_create(array_length(characters), undefined); // Per-character composite layer cache for the selector UI (avoids file_exists every frame)
get_character_sprite = function(_char_index) {
    if (_char_index < 0 || _char_index >= array_length(characters)) return -1;
    var _c = characters[_char_index];
    if (ds_map_exists(char_sprites, _c.name)) return char_sprites[? _c.name];
    var _path = datafiles_path + "images/characters/" + string_lower(_c.name) + ".png";
    if (file_exists(_path)) {
        var _spr = sprite_add(_path, 1, false, false, 0, 0);
        ds_map_add(char_sprites, _c.name, _spr);
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
get_composite_character_sprite = function(_char_index, _pose, _expression, _facing_override = undefined) {
    var _null_layer = { spr: -1, dx: 0, dy: 0 };

    if (_char_index < 0 || _char_index >= array_length(characters)) {
        return [_null_layer, _null_layer, _null_layer, _null_layer];
    }
    var _c = characters[_char_index];
    if (_c.name == "NARRATOR") {
        return [_null_layer, _null_layer, _null_layer, _null_layer];
    }

    var _act_idx  = variable_struct_exists(_c, "act_index")     ? _c.act_index     : 1;
    var _def_face = variable_struct_exists(_c, "default_facing") ? _c.default_facing : 1;
    var _dir_name = string_lower(_c.name);

    // _use_high: add +50 to every suffix (flipped direction).
    // True when the desired facing and the character's natural facing are OPPOSITE.
    var _use_high = (_facing_override != undefined) && (_facing_override * _def_face == -1);
    var _sfx_off  = _use_high ? 50 : 0;

    var _folder_path = datafiles_path + "images/characters/" + _c.name + "/";
    if (!directory_exists(_folder_path)) {
        _folder_path = datafiles_path + "images/characters/" + _dir_name + "/";
    }

    // No pose folder — fallback to single root PNG
    if (!directory_exists(_folder_path)) {
        var _bp = datafiles_path + "images/characters/" + _dir_name + ".png";
        if (!file_exists(_bp)) _bp = datafiles_path + "images/characters/" + _c.name + ".png";
        if (file_exists(_bp)) {
            var _fs;
            if (ds_map_exists(char_sprites, _c.name)) {
                _fs = char_sprites[? _c.name];
            } else {
                _fs = sprite_add(_bp, 1, false, false, 0, 0);
                ds_map_add(char_sprites, _c.name, _fs);
            }
            return [{ spr: _fs, dx: 0, dy: 0 }, _null_layer, _null_layer, _null_layer];
        }
        return [_null_layer, _null_layer, _null_layer, _null_layer];
    }

    // Lazy-load offsets.json
    if (!ds_map_exists(char_offsets_cache, _c.name)) {
        var _off_path = _folder_path + "offsets.json";
        if (file_exists(_off_path)) {
            var _off_str = "";
            var _off_f = file_text_open_read(_off_path);
            while (!file_text_eof(_off_f)) { _off_str += file_text_readln(_off_f); }
            file_text_close(_off_f);
            ds_map_add(char_offsets_cache, _c.name, json_parse(_off_str));
        } else {
            ds_map_add(char_offsets_cache, _c.name, undefined);
        }
    }
    var _off_data = char_offsets_cache[? _c.name];

    var _prefix = string(_act_idx) + string(_pose); // e.g., "111" for Gus, Pose 1

    // ── Check expressions_config.json for user-configured offsets ──
    if (!ds_map_exists(char_expr_cache, _c.name)) {
        var _ecfg_path = _folder_path + "expressions_config.json";
        if (file_exists(_ecfg_path)) {
            var _ecfg_str = "";
            var _ecfg_f = file_text_open_read(_ecfg_path);
            while (!file_text_eof(_ecfg_f)) { _ecfg_str += file_text_readln(_ecfg_f); }
            file_text_close(_ecfg_f);
            ds_map_add(char_expr_cache, _c.name, json_parse(_ecfg_str));
        } else {
            ds_map_add(char_expr_cache, _c.name, undefined);
        }
    }
    var _ecfg_data = char_expr_cache[? _c.name];
    // Key encodes pose + direction so left/right can differ
    var _ecfg_dir  = _use_high ? "high" : "low";
    var _ecfg_key  = "pose_" + string(_pose) + "_" + _ecfg_dir;
    var _ecfg_pc   = (_ecfg_data != undefined && variable_struct_exists(_ecfg_data, _ecfg_key)) ? _ecfg_data[$ _ecfg_key] : undefined;

    // --- Layer 0: Lower body ---
    var _lower_spr  = -1;
    var _lower_file = "";
    var _lo_ox = 0; var _lo_oy = 0; // Canvas origin for delta calculation (anchored to lower body)

    // 1. Prioritize user-defined body_file from expressions_config.json
    if (_ecfg_pc != undefined && variable_struct_exists(_ecfg_pc, "body_file") && _ecfg_pc.body_file != "") {
        _lower_file = _ecfg_pc.body_file;
        var _lk_cfg = _c.name + "_" + _lower_file;
        if (ds_map_exists(char_sprites, _lk_cfg)) {
            _lower_spr = char_sprites[? _lk_cfg];
        } else if (file_exists(_folder_path + _lower_file)) {
            _lower_spr = sprite_add(_folder_path + _lower_file, 1, false, false, 0, 0);
            ds_map_add(char_sprites, _lk_cfg, _lower_spr);
        }
        // Calculate _lo_ox and _lo_oy based on this custom file
        if (_lower_spr != -1 && _off_data != undefined) {
            var _bk2_cfg = string_copy(_lower_file, 1, string_length(_lower_file) - 4);
            if (variable_struct_exists(_off_data, _bk2_cfg)) { var _bv = _off_data[$ _bk2_cfg]; _lo_ox = _bv[0]; _lo_oy = _bv[1]; }
        }
    }

    // 2. If no custom body_file, or if expression is NEUTRAL (21+), use default logic
    if (_lower_spr == -1 || _expression < 1 || _expression > 20) {
        var _lo_start = (_expression < 1 || _expression > 20) ? (1 + _sfx_off) : (6 + _sfx_off); // Neutral uses 01-10 range
        var _lo_end   = (_expression < 1 || _expression > 20) ? (10 + _sfx_off) : (10 + _sfx_off);
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
            var _lk = _c.name + "_" + _lower_file;
            if (ds_map_exists(char_sprites, _lk)) {
                _lower_spr = char_sprites[? _lk];
            } else {
                _lower_spr = sprite_add(_folder_path + _lower_file, 1, false, false, 0, 0);
                ds_map_add(char_sprites, _lk, _lower_spr);
            }
        }
        // Fallback to main character PNG if no specific body part found
        if (_lower_spr == -1) {
            var _fb3 = datafiles_path + "images/characters/" + _dir_name + ".png";
            if (!file_exists(_fb3)) _fb3 = datafiles_path + "images/characters/" + _c.name + ".png";
            if (file_exists(_fb3)) {
                if (ds_map_exists(char_sprites, _c.name)) _lower_spr = char_sprites[? _c.name];
                else { _lower_spr = sprite_add(_fb3, 1, false, false, 0, 0); ds_map_add(char_sprites, _c.name, _lower_spr); }
            }
        }
        // Calculate _lo_ox and _lo_oy based on this default file
        if (_lower_file != "" && _off_data != undefined) {
            var _lo_key = string_copy(_lower_file, 1, string_length(_lower_file) - 4);
            if (variable_struct_exists(_off_data, _lo_key)) {
                var _loo = _off_data[$ _lo_key]; _lo_ox = _loo[0]; _lo_oy = _loo[1];
            }
        }
    }

    // If expression is NEUTRAL (21+), we only need the body layer.
    if (_expression < 1 || _expression > 20) {
        return [{ spr: _lower_spr, dx: 0, dy: 0 }, _null_layer, _null_layer, _null_layer];
    }

    // ── Expressions 1-20: tiled composition (only if not neutral) ──
    // Fallback mouth mood (0=happy 1=neutral 2=sad 3=angry) when no expressions_config.json override.
    // happy sad angry cool flrt shy emb sur fri msc gui par con bor sil pan pom cnt ref wis
    var _mood_map = [0, 2, 3, 1, 0, 1, 1, 1, 1, 0, 2, 1, 1, 1, 0, 3, 1, 0, 1, 2];
    var _mouth_idx = _mood_map[clamp(_expression - 1, 0, 19)];

    // Suffix numbers (before 2-digit format)
    var _lo_start = 6  + _sfx_off; // lower body scan range start
    var _lo_end   = 10 + _sfx_off; // lower body scan range end
    var _face_n   = 5  + _sfx_off; // blank face
    var _mouth_n  = 31 + _mouth_idx + _sfx_off; // mouth expression
    var _eyes_n   = 10 + _expression + _sfx_off; // eye expression

    var _face_sfx  = (_face_n  < 10 ? "0" : "") + string(_face_n);
    var _mouth_sfx = (_mouth_n < 10 ? "0" : "") + string(_mouth_n);
    var _eyes_sfx  = (_eyes_n  < 10 ? "0" : "") + string(_eyes_n);

    // ── Layer 1: blank face ──
    var _face_file = "pose_" + _prefix + _face_sfx + ".png";
    if (_ecfg_pc != undefined && variable_struct_exists(_ecfg_pc, "face_file") && _ecfg_pc.face_file != "") _face_file = _ecfg_pc.face_file;
    var _face_spr = -1;
    if (file_exists(_folder_path + _face_file)) {
        var _fk = _c.name + "_" + _face_file;
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

    // ── Layer 2: mouth ──
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
        var _mk = _c.name + "_" + _mouth_file;
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

    // ── Layer 3: eyes ──
    var _eyes_file = "pose_" + _prefix + _eyes_sfx + ".png";
    if (_ecfg_pc != undefined && variable_struct_exists(_ecfg_pc, "eyes_files")) {
        var _ef_map = _ecfg_pc.eyes_files;
        var _ef_key = string(_expression);
        if (variable_struct_exists(_ef_map, _ef_key) && _ef_map[$ _ef_key] != "") _eyes_file = _ef_map[$ _ef_key];
    }
    var _eyes_spr = -1;
    if (file_exists(_folder_path + _eyes_file)) {
        var _ek = _c.name + "_" + _eyes_file;
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

    // body_dx/dy shifts the whole composite (anchor correction)
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

    return [
        { spr: _lower_spr, dx: _bdx_c,              dy: _bdy_c              },
        { spr: _face_spr,  dx: _face_dx  + _bdx_c,  dy: _face_dy  + _bdy_c  },
        { spr: _mouth_spr, dx: _mouth_dx + _bdx_c,  dy: _mouth_dy + _bdy_c  },
        { spr: _eyes_spr,  dx: _eyes_dx  + _bdx_c,  dy: _eyes_dy  + _bdy_c  }
    ];
}

selected_character_index = 0;
edit_mode = false; 
modal_is_local_edit = false; // Tracks if we are editing a block or a character global
modal_target_block_idx = -1;  // The specific block being edited locally
modal_voice_id = ""; 
tweak_enabled = false;
modal_pitch = 50;
modal_speed = 50;
modal_quality = 0; 
modal_effort = 0;
active_input = 0;
arrow_repeat_timer = 0;
slider_drag = 0; 

// --- 6. SCENE ASSETS ---
all_scenes = [];
var _exts = ["*.png", "*.jpg", "*.jpeg"];
for (var e = 0; e < array_length(_exts); e++) {
    var _fname = file_find_first(working_directory + "images/backgrounds/" + _exts[e], 0);
    while (_fname != "") {
        var _name = _fname;
        _name = string_replace(_name, ".png", "");
        _name = string_replace(_name, ".jpg", "");
        _name = string_replace(_name, ".jpeg", "");
        
        // Filter out mask files from the selectable list
        if (string_pos("_mask", _name) > 0) {
            _fname = file_find_next();
            continue;
        }
        
        var _disp_name = string_upper(string_char_at(_name, 1)) + string_copy(_name, 2, string_length(_name)-1);
        array_push(all_scenes, { name: _disp_name, internal_name: _name, sprite: -1, path: "backgrounds/" + _fname });
        _fname = file_find_next();
    }
    file_find_close();
}

action_modal_open = false;
action_modal_target_index = -1;
action_modal_selected_idx = -1;
action_modal_locked = false;
action_modal_edit_mode = false;
action_modal_char_onstage = false;

action_animating = false;
action_anim_char_index = -1;
action_anim_target_x = 0;
action_anim_target_y = 0;
action_anim_speed = 1.9;
action_anim_type = ""; 
active_animations = [];
action_modal_slider_dragging = false;
action_modal_wait_duration = 1.0;

action_modal_title_text = "";
action_modal_title_align = 1;
action_modal_title_font = 0;
action_modal_title_size = 1;
action_modal_title_color = 0;
action_modal_title_align_opts = ["Top", "Center", "Bottom"];

// Dynamically scan the project for any font assets
action_modal_title_font_opts = ["Default"];
action_modal_title_fonts = [-1]; // -1 maps to the default UI font
for (var _f_idx = 0; _f_idx < 200; _f_idx++) { // 200 is far more than enough; GML assigns font IDs sequentially from 0
    if (font_exists(_f_idx)) {
        var _fname = font_get_name(_f_idx);
        if (_fname != "" && _fname != "<undefined>") {
            var _disp_name = _fname;
            if (string_pos("fnt_", _disp_name) == 1) _disp_name = string_copy(_disp_name, 5, string_length(_disp_name) - 4);
            else if (string_pos("font_", _disp_name) == 1) _disp_name = string_copy(_disp_name, 6, string_length(_disp_name) - 5);
            
            array_push(action_modal_title_font_opts, _disp_name);
            array_push(action_modal_title_fonts, _f_idx);
        }
    }
}

action_modal_title_size_opts = ["Small", "Medium", "Large"];
action_modal_title_color_opts = ["White", "Black", "Red", "Yellow", "Blue", "Green", "Orange", "Purple", "Cyan", "Pink"];
action_modal_dropdown_open = "";

// --- SFX Browser State ---
action_modal_sfx_folders = [];
action_modal_sfx_files = [];
action_modal_sfx_folder_idx = -1;
action_modal_sfx_file_idx = -1;
action_modal_sfx_scroll_y = 0;
action_modal_sfx_files_scroll_y = 0;
action_modal_sfx_dragging_folder = false;
action_modal_sfx_dragging_file = false;
test_sfx_sound = -1;
test_sfx_buffer = -1;
sfx_base_path = working_directory + "sounds/sfx/";

refresh_sfx_folders = function() {
    action_modal_sfx_folders = [];
    var _file = file_find_first(sfx_base_path + "*", fa_directory);
    while (_file != "") {
        if (_file != "." && _file != ".." && directory_exists(sfx_base_path + _file)) array_push(action_modal_sfx_folders, _file);
        _file = file_find_next();
    }
    file_find_close();
    array_sort(action_modal_sfx_folders, function(a, b) {
        var _la = string_lower(a); var _lb = string_lower(b);
        if (_la < _lb) return -1;
        if (_la > _lb) return 1;
        return 0;
    });
}

refresh_sfx_files = function(_folder) {
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
        if (_la < _lb) return -1;
        if (_la > _lb) return 1;
        return 0;
    });
}

all_actions = [
    { name: "turns around", desc: "Character flips their horizontal facing direction.", category: "character" },
    { name: "wait", desc: "Pauses the script for a set duration of time.", category: "general" },
    { name: "play sfx", desc: "Plays a sound effect from the library.", category: "general" },
    { name: "display title", desc: "Displays a text title on screen for a set duration.", category: "general" }
];

char_facings = array_create(array_length(characters), 1);

array_sort(all_scenes, function(a, b) {
    var _la = string_lower(a.internal_name);
    var _lb = string_lower(b.internal_name);
    if (_la < _lb) return -1;
    if (_la > _lb) return 1;
    return 0;
});


scene_sprites = ds_map_create();
get_scene_sprite = function(_internal_name) {
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
    
    // Fallback for files not in the list (e.g., masks)
    var _exts_check = [".png", ".jpg", ".jpeg"];
    for (var e = 0; e < array_length(_exts_check); e++) {
        var _path = working_directory + "images/backgrounds/" + _internal_name + _exts_check[e];
        if (file_exists(_path)) {
            var _spr = sprite_add(_path, 1, false, false, 0, 0);
            
            ds_map_add(scene_sprites, _internal_name, _spr);
            return _spr;
        }
    }
    
    return -1; // Truly not found
}


scene_live_top = 0;
scene_live_bottom = 0;

detect_scene_live_area = function(_spr) {
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
        if (surface_getpixel(_surf, 0, i) == _chroma) _top = i + 1;
        else break;
    }
    
    var _bottom = 0;
    for (var i = _sh - 1; i > max(_sh/2, _sh - 101); i--) {
        if (surface_getpixel(_surf, 0, i) == _chroma) _bottom = (_sh - 1) - i + 1;
        else break;
    }
    
    surface_free(_surf);
    scene_live_top = _top / _sh;
    scene_live_bottom = _bottom / _sh;
};

set_scene_dimensions = function(_spr) {
    if (_spr == -1) { 
        scene_win_w = 800; scene_win_h = 450; 
        scene_win_x = 50; scene_win_y = 60;
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
    scene_win_y = 60 + (450 - scene_win_h) / 2;
    
    detect_scene_live_area(_spr);
};

// --- 7. INITIAL SETUP ---
var _suburbs_internal = "suburbs";
current_scene_sprite = get_scene_sprite(_suburbs_internal);
set_scene_dimensions(current_scene_sprite);

update_all_block_heights();

scene_modal_open = false;
scene_modal_scroll_y = 0;
scene_modal_target_index = -1;
scene_modal_edit_mode = false;

// --- 3bb. SCENE EDITING STATE ---
scene_edit_mode = false;
talking_glow_enabled = true; // New: Global toggle for character highlight while talking
dragging_char_index = -1; // Index in 'characters' array
dragging_actor_idx = -1;  // Index in the active scene's 'actors' array (Edit Mode)
dragging_preview_idx = -1; // Index in preview_actors (Live Move Mode)
drag_start_x = 0;
drag_start_y = 0;
drag_off_x = 0;
drag_off_y = 0;
active_scene_block_idx = 0; // The index of the scene block currently being viewed
insertion_idx = -1; // -1 means add to end, >=0 means insert AFTER this index

// --- 3bc. SCENE EDIT CONTEXT MENU ---
scene_edit_menu_open = false;
scene_edit_menu_x = 0;
scene_edit_menu_y = 0;
scene_edit_menu_char_idx = -1;
scene_edit_menu_actor_idx = -1;
scene_edit_selected_actor_idx = -1; // New: Persistent selection for static buttons
scene_edit_menu_pending_x = 0;
scene_edit_menu_pending_y = 0;
scene_edit_menu_pending_face = 1;
scene_edit_menu_orig_x = 0; // For cancel
scene_edit_menu_orig_y = 0;
scene_edit_menu_orig_face = 1;

file_menu_open = false;

o_char_surface = -1;
o_mask_surface = -1;

is_speaking      = false;  
check_timer      = 0;      
speaking_timer   = 0;      
speaking_pause_timer = 0;  

// --- 4. VISUAL HIGHLIGHTING ---
speaking_word_start = -1;  // Starting index of the word currently being spoken
speaking_word_len   = 0;   // Length of the active word highlight
speaking_index      = 0;   // Floating point index for smooth word tracking

// --- 7. TEXT SCROLLING & RENDERING ---
text_scroll_y      = 0;
text_surface       = -1; // Surface used for clipping the text area
is_scrolling_text  = false;
click_count        = 0;  // For double-click detection
click_timer        = 0;
repeat_timer       = 0;  // Keyboard repeat speed
repeat_key         = vk_nokey;

// --- 8. WARM UP TTS ENGINE ---
// PowerShell and the .NET host have a noticeable delay on their first run.
// We trigger a silent dummy request here (".") so the OS caches the executable
// and JIT-compiles the libraries, preventing a pause on the first actual playback.
warmup_requests = [];
if (array_length(all_voices) > 0) {
    array_push(warmup_requests, tts_speak(".", all_voices[0].voice_id, 50, 50, 0, 0));
}

update_preview_actors_for_block = function(_idx, _inclusive) {
    preview_actors = [];
    if (_idx < 0 || _idx >= array_length(script_blocks)) return;
    
    // 1. Find the last scene heading
    active_scene_block_idx = -1;
    for (var j = _idx; j >= 0; j--) {
        if (variable_struct_exists(script_blocks[j], "type") && script_blocks[j].type == "scene") {
            active_scene_block_idx = j;
            break;
        }
    }
    
    // 2. Initialize actors from that scene
    if (active_scene_block_idx != -1) {
        var _scene = script_blocks[active_scene_block_idx];
        if (variable_struct_exists(_scene, "actors")) {
            for (var a = 0; a < array_length(_scene.actors); a++) {
                var _sa = _scene.actors[a];
                var _face = variable_struct_exists(_sa, "facing") ? _sa.facing : 1;
                var _pose = variable_struct_exists(_sa, "pose") ? _sa.pose : 1;
                var _expr = variable_struct_exists(_sa, "expression") ? _sa.expression : 21;
                array_push(preview_actors, { char_index: _sa.char_index, x: _sa.x, y: _sa.y, is_base: true, facing: _face, pose: _pose, expression: _expr });
                char_facings[_sa.char_index] = _face;
            }
        }
        
        // 3. Fast-forward through actions up to the target index
        var _limit = _inclusive ? _idx : (_idx - 1);
        for (var j = active_scene_block_idx + 1; j <= _limit; j++) {
            var _b = script_blocks[j];
            if (variable_struct_exists(_b, "type") && _b.type == "action") {
                var _aname = string_lower(_b.action_name);
                var _is_enter = (string_pos("enter", _aname) > 0);
                var _is_exit = (string_pos("exit", _aname) > 0);
                var _is_left = (string_pos("left", _aname) > 0);
                var _spd = variable_struct_exists(_b, "speed") ? _b.speed : 1.5;
                var _moon = (variable_struct_exists(_b, "moonwalk") && _b.moonwalk) || (string_pos("[moonwalk]", _aname) > 0);
                
                var _act_idx = -1;
                for (var k = 0; k < array_length(preview_actors); k++) {
                    if (preview_actors[k].char_index == _b.char_index) { _act_idx = k; break; }
                }
                
                if (_is_enter) {
                    if (_act_idx == -1) {
                        var _spr = get_character_sprite(_b.char_index);
                        var _w = (_spr != -1) ? sprite_get_width(_spr) * ((scene_win_h * 1.5) / 450) : 100;
                        var _start_x = _is_left ? (_w/2) + 20 : scene_win_w - (_w/2) - 20; 
                        var _base_face = _is_left ? -1 : 1;

                        var _final_x = variable_struct_exists(_b, "target_x") ? _b.target_x : _start_x;
                        var _final_y = variable_struct_exists(_b, "target_y") ? _b.target_y : (scene_win_h * 0.8);
                        
                        var _c = characters[_b.char_index];
                        var _pose = variable_struct_exists(_c, "pose") ? _c.pose : 1;
                        var _expr = variable_struct_exists(_c, "expression") ? _c.expression : 21;
                        char_facings[_b.char_index] = _moon ? -_base_face : _base_face;
                        array_push(preview_actors, { char_index: _b.char_index, x: _final_x, y: _final_y, is_base: false, facing: char_facings[_b.char_index], pose: _pose, expression: _expr });
                    } else {
                        // If already onstage, update position and handle auto-facing
                        if (variable_struct_exists(_b, "target_x")) {
                            var _base_f = (_b.target_x > preview_actors[_act_idx].x) ? -1 : 1;
                            preview_actors[_act_idx].facing = _moon ? -_base_f : _base_f;
                            preview_actors[_act_idx].x = _b.target_x;
                            preview_actors[_act_idx].y = _b.target_y;
                        }
                        // Explicit side mention overrides auto-facing
                        if (string_pos("left", _aname) > 0) {
                            var _base_f = -1;
                            preview_actors[_act_idx].facing = _moon ? -_base_f : _base_f;
                        } else if (string_pos("right", _aname) > 0) {
                            var _base_f = 1;
                            preview_actors[_act_idx].facing = _moon ? -_base_f : _base_f;
                        }
                        char_facings[_b.char_index] = preview_actors[_act_idx].facing;
                    }
                } else if (_is_exit) {
                    if (_act_idx != -1) array_delete(preview_actors, _act_idx, 1);
                } else if (string_pos("turn", _aname) > 0) {
                    if (_act_idx != -1) {
                        preview_actors[_act_idx].facing *= -1;
                        char_facings[_b.char_index] = preview_actors[_act_idx].facing;
                    }
                } else if (string_pos("moves", _aname) > 0) {
                    if (_act_idx != -1) {
                        if (variable_struct_exists(_b, "target_x")) {
                            var _base_f = (_b.target_x > preview_actors[_act_idx].x) ? -1 : 1;
                            preview_actors[_act_idx].facing = _moon ? -_base_f : _base_f;
                            preview_actors[_act_idx].x = _b.target_x;
                            preview_actors[_act_idx].y = _b.target_y;
                            char_facings[_b.char_index] = preview_actors[_act_idx].facing;
                        }
                    }
                } else if (string_pos("poses", _aname) > 0) {
                    if (_act_idx != -1) {
                        var _p_pos = string_pos("poses ", _aname);
                        if (_p_pos > 0) {
                            var _p_str = string_copy(_aname, _p_pos + 6, 1);
                            var _p_num = real(_p_str);
                            if (_p_num >= 1 && _p_num <= 4) {
                                preview_actors[_act_idx].pose = _p_num;
                            }
                        }
                        
                        var _m_start = string_pos("(", _aname);
                        var _m_end = string_pos(")", _aname);
                        if (_m_start > 0 && _m_end > _m_start) {
                            var _mood_str = string_copy(_aname, _m_start + 1, _m_end - _m_start - 1);
                            _mood_str = string_upper(_mood_str);
                            for (var m = 0; m < array_length(mood_names); m++) {
                                if (mood_names[m] == _mood_str) {
                                    preview_actors[_act_idx].expression = m + 1;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
};

/**
 * Starts playback from a specific block, calculating proper scene state.
 */
play_from_index = function(_idx) {
    if (_idx < 0 || _idx >= array_length(script_blocks)) return;
    
    // Disable splicing and staging modes before playback starts
    scene_edit_mode = false;
    insertion_idx = -1;
    
    update_preview_actors_for_block(_idx, false);
    
    // 4. Start playback
    playing_block_index = _idx;
    playing_linked_index = -1;
    is_speaking = false;
    speaking_pause_timer = -1; // Special flag to start current index immediately
    active_requests = [];
    action_animating = false;
    active_animations = [];
    audio_stop_all();
    tts_stop();
};

/**
 * Calculates the character index based on mouse X/Y coordinates.
 * Prioritizes the vertical line (row) to prevent 'jumping' between empty lines.
 */
get_index = function(_mx, _my) {
    var _rel_x = _mx - (box_x + 10); 
    var _rel_y = _my - (box_y + 10 + text_scroll_y);
    var _max_w = box_w - 50; 
    var _line_h = 24;
    
    if (script_text == "") return 0;
    
    // Determine target row
    var _target_row = clamp(floor(_rel_y / _line_h), 0, 1000);
    
    var _cur_x = 0; var _cur_y = 0; var _cur_row = 0; 
    var _best_idx = 0; var _found_on_row = false;
    var _last_idx_on_row = 0;

    for (var i = 1; i <= string_length(script_text); i++) {
        var _char = string_char_at(script_text, i);
        
        // Multi-line wrap detection (must match Draw_0 exactly)
        if (i == 1 || string_char_at(script_text, i-1) == " " || string_char_at(script_text, i-1) == "\n") {
            var _next_space = string_pos_ext(" ", script_text, i);
            var _next_nl = string_pos_ext("\n", script_text, i);
            var _end = string_length(script_text);
            if (_next_space > 0) _end = min(_end, _next_space - 1);
            if (_next_nl > 0) _end = min(_end, _next_nl - 1);
            var _word_w = string_width(string_copy(script_text, i, _end - i + 1));
            if (_cur_x + _word_w > _max_w && _cur_x > 0) { 
                _cur_x = 0; _cur_y += _line_h; _cur_row++; 
            }
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
};

// ─────────────────────────────────────────────────────────────────
// EXPRESSION TILE CONFIGURATOR (debug tool — remove for final build)
// ─────────────────────────────────────────────────────────────────
// 4 poses × 2 directions (low = natural, high = flipped) = 8 configs per character.
// Data saved to datafiles/images/characters/<Name>/expressions_config.json.

expr_cfg_open           = false;
expr_cfg_char_idx       = 0;
expr_cfg_pose           = 1;     // 1-4
expr_cfg_high           = false; // false = natural direction, true = flipped
expr_cfg_preview_expr   = 1;     // 1-12  (eyes slot currently previewed)
expr_cfg_preview_mood   = 0;     // 0-3   (mouth slot currently previewed)
expr_cfg_selected_layer = 1;     // 0=body(locked), 1=face, 2=eyes, 3=mouth
expr_cfg_drag           = false;
expr_cfg_zoom           = 1.0;
expr_cfg_drag_mx0       = 0; expr_cfg_drag_my0 = 0;
expr_cfg_drag_dx0       = 0; expr_cfg_drag_dy0 = 0;
expr_cfg_file_list      = [];    // array of PNG filenames in the current char folder
expr_cfg_file_scroll    = 0;     // scroll offset for file browser (rows, not pixels)
// expr_cfg_configs[pose 1-4][0=low, 1=high] → struct or undefined
expr_cfg_configs = array_create(5);
for (var _i = 1; _i <= 4; _i++) expr_cfg_configs[_i] = [undefined, undefined];

// Helper: get/set the active config struct for current pose+direction
expr_cfg_get_pc = function() {
    return expr_cfg_configs[expr_cfg_pose][expr_cfg_high ? 1 : 0];
};
expr_cfg_set_pc = function(_v) {
    expr_cfg_configs[expr_cfg_pose][expr_cfg_high ? 1 : 0] = _v;
};

// Auto-fill one config from offsets.json
expr_cfg_auto_fill = function(_pose_num, _is_high) {
    var _c_af = characters[expr_cfg_char_idx];
    var _ai_af = variable_struct_exists(_c_af, "act_index") ? _c_af.act_index : 1;
    var _sfx_off_af = _is_high ? 50 : 0;
    var _pfx_af = string(_ai_af) + string(_pose_num);
    var _folder_af = datafiles_path + "images/characters/" + _c_af.name + "/";

    // Load offsets.json
    var _off_af = undefined;
    if (file_exists(_folder_af + "offsets.json")) {
        var _s = ""; var _f = file_text_open_read(_folder_af + "offsets.json");
        while (!file_text_eof(_f)) { _s += file_text_readln(_f); }
        file_text_close(_f); _off_af = json_parse(_s);
    }

    // Largest body file in lo_start..lo_end
    var _lo_s = 6 + _sfx_off_af; var _lo_e = 10 + _sfx_off_af;
    var _body_file_af = ""; var _body_sz_af = 0;
    var _box = 0; var _boy = 0;
    for (var _n = _lo_s; _n <= _lo_e; _n++) {
        var _ns = (_n < 10 ? "0" : "") + string(_n);
        var _cf = "pose_" + _pfx_af + _ns + ".png";
        if (file_exists(_folder_af + _cf)) {
            var _fb = file_bin_open(_folder_af + _cf, 0);
            var _sz = (_fb != -1) ? file_bin_size(_fb) : 0;
            if (_fb != -1) file_bin_close(_fb);
            if (_sz > _body_sz_af) { _body_sz_af = _sz; _body_file_af = _cf; }
        }
    }
    if (_off_af != undefined && _body_file_af != "") {
        var _bk2 = string_copy(_body_file_af, 1, string_length(_body_file_af) - 4);
        if (variable_struct_exists(_off_af, _bk2)) { var _bv = _off_af[$ _bk2]; _box = _bv[0]; _boy = _bv[1]; }
    }

    // Face file (suffix 05 or 55)
    var _face_n_af = 5 + _sfx_off_af;
    var _face_sfx_af = (_face_n_af < 10 ? "0" : "") + string(_face_n_af);
    var _face_file_af = "pose_" + _pfx_af + _face_sfx_af + ".png";
    if (!file_exists(_folder_af + _face_file_af)) _face_file_af = "";
    var _fdx = 0; var _fdy = 0;
    if (_off_af != undefined) {
        var _fok = "pose_" + _pfx_af + _face_sfx_af;
        if (variable_struct_exists(_off_af, _fok)) { var _fv = _off_af[$ _fok]; _fdx = _fv[0] - _box; _fdy = _fv[1] - _boy; }
    }

    // Eyes dx/dy (expression 1, suffix 11 or 61)
    var _eyes_n_af = 10 + 1 + _sfx_off_af;
    var _eyes_sfx_af = (_eyes_n_af < 10 ? "0" : "") + string(_eyes_n_af);
    var _edx = 0; var _edy = 0;
    if (_off_af != undefined) {
        var _eok = "pose_" + _pfx_af + _eyes_sfx_af;
        if (variable_struct_exists(_off_af, _eok)) { var _ev = _off_af[$ _eok]; _edx = _ev[0] - _box; _edy = _ev[1] - _boy; }
    }

    // Mouth dx/dy (mood 0, suffix 31 or 81)
    var _mouth_n_af = 31 + _sfx_off_af;
    var _mouth_sfx_af = (_mouth_n_af < 10 ? "0" : "") + string(_mouth_n_af);
    var _mdx = 0; var _mdy = 0;
    if (_off_af != undefined) {
        var _mok = "pose_" + _pfx_af + _mouth_sfx_af;
        if (variable_struct_exists(_off_af, _mok)) { var _mv = _off_af[$ _mok]; _mdx = _mv[0] - _box; _mdy = _mv[1] - _boy; }
    }

    return {
        body_file:   _body_file_af, face_file:  _face_file_af,
        body_dx: 0,  body_dy: 0,
        face_dx:  _fdx, face_dy:  _fdy,
        eyes_dx:  _edx, eyes_dy:  _edy,
        mouth_dx: _mdx, mouth_dy: _mdy,
        eyes_files:  {},   // struct: expr_number(str) → filename; empty = use suffix auto
        mouth_files: {}    // struct: mood_index(str) → filename; empty = use suffix auto
    };
};

// Open the configurator for a character (Narrator has no sprite and is skipped)
open_expr_configurator = function(_char_idx) {
    if (characters[_char_idx].name == "NARRATOR") return;
    expr_cfg_char_idx     = _char_idx;
    expr_cfg_pose         = 1;
    expr_cfg_high         = false;
    expr_cfg_preview_expr = 1;
    expr_cfg_selected_layer = 1;
    expr_cfg_drag         = false;
    expr_cfg_zoom         = 1.0;
    expr_cfg_configs      = array_create(5);
    for (var _i2 = 1; _i2 <= 4; _i2++) expr_cfg_configs[_i2] = [undefined, undefined];

    // Load existing config
    var _c_oc = characters[_char_idx];
    var _folder_oc = datafiles_path + "images/characters/" + _c_oc.name + "/";
    var _path_oc = _folder_oc + "expressions_config.json";
    var _existing = {};
    if (file_exists(_path_oc)) {
        var _s2 = ""; var _f2 = file_text_open_read(_path_oc);
        while (!file_text_eof(_f2)) { _s2 += file_text_readln(_f2); }
        file_text_close(_f2); _existing = json_parse(_s2);
    }
    for (var _p2 = 1; _p2 <= 4; _p2++) {
        for (var _d2 = 0; _d2 <= 1; _d2++) {
            var _k2 = "pose_" + string(_p2) + "_" + (_d2 == 1 ? "high" : "low");
            if (variable_struct_exists(_existing, _k2)) {
                expr_cfg_configs[_p2][_d2] = _existing[$ _k2];
            } else {
                expr_cfg_configs[_p2][_d2] = expr_cfg_auto_fill(_p2, (_d2 == 1));
            }
        }
    }
    // Scan PNG files in character folder
    expr_cfg_file_list   = [];
    expr_cfg_file_scroll = 0;
    expr_cfg_preview_mood = 0;
    var _scan_folder = datafiles_path + "images/characters/" + characters[_char_idx].name + "/";
    var _scan_f = file_find_first(_scan_folder + "*.png", 0);
    while (_scan_f != "") {
        array_push(expr_cfg_file_list, _scan_f);
        _scan_f = file_find_next();
    }
    file_find_close();
    array_sort(expr_cfg_file_list, function(a, b) { return (a < b) ? -1 : (a > b ? 1 : 0); });

    expr_cfg_open = true;
};

// Save all configs for the current character.
// file_text_write is unreachable inside GML instance methods on this runtime,
// so we just stage the data and let the Step event do the actual write.
expr_cfg_pending_save_path = "";
expr_cfg_pending_save_data = "";

save_expr_config = function() {
    var _c_sv = characters[expr_cfg_char_idx];
    var _folder_sv = datafiles_path + "images/characters/" + _c_sv.name + "/";
    var _out = {};
    for (var _p3 = 1; _p3 <= 4; _p3++) {
        for (var _d3 = 0; _d3 <= 1; _d3++) {
            var _cfg3 = expr_cfg_configs[_p3][_d3];
            if (_cfg3 != undefined) {
                _out[$ "pose_" + string(_p3) + "_" + (_d3 == 1 ? "high" : "low")] = _cfg3;
            }
        }
    }
    expr_cfg_pending_save_path = _folder_sv + "expressions_config.json";
    expr_cfg_pending_save_data = json_stringify(_out);
    // Invalidate runtime cache immediately so the preview uses the new data
    if (ds_map_exists(char_expr_cache, _c_sv.name)) ds_map_delete(char_expr_cache, _c_sv.name);
};
