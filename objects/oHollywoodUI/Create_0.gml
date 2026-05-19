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
window_set_size(1280, 960);
surface_resize(application_surface, 1280, 960);
display_set_gui_size(1280, 960);
room_width = 1280;
room_height = 960;

// --- 2. UI & LAYOUT CONSTANTS ---
scene_win_x = 50; scene_win_y = 60; scene_win_w = 800; scene_win_h = 450; // Scene window (16:9)
box_x = 50; box_y = 570; box_w = 1180; box_h = 370; // Main text box
btn_play_w = 100; btn_play_h = 35; // Play Button
btn_play_x = (box_x + box_w / 2) - (btn_play_w / 2); btn_play_y = 520; 

dropdown_open = false;
dropdown_scroll_y = 0;
dropdown_w = 350;
dropdown_h = 35;
btn_edit_w        = 130;
btn_edit_h        = 35;
btn_edit_x        = box_x + box_w - btn_edit_w;
btn_edit_y        = 520;
dropdown_x        = btn_edit_x - 15 - dropdown_w;
dropdown_y        = 520;

char_sel_x = 880; char_sel_y = 60; char_sel_w = 350; char_sel_h = 450;
char_sel_scroll_y = 0;
btn_theater_x = 880; btn_theater_y = 15; btn_theater_w = 140; btn_theater_h = 35;
theater_mode = false;
theater_paused = false;
theater_subtitles = "";
theater_active_char = -1;

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
active_request_id = -1;      // What the Step event is waiting for
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
        _b.height = max(60, string_height_ext(_b.text, 28, _wrap_w) + 30) + 55;
    }
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

// --- 5. TTS ENGINE & CHARACTERS ---
all_voices = tts_refresh_voices(); 

characters = [
    { name: "NARRATOR", voice_id: all_voices[0].voice_id, pitch: 50, speed: 50, mode: 0, style: 0, tweaked: false, sprite: -1 },
    { name: "GUS", voice_id: all_voices[18].voice_id, pitch: 50, speed: 50, mode: 0, style: 0, tweaked: false, sprite: -1 },
    { name: "LILLY", voice_id: all_voices[1].voice_id, pitch: 60, speed: 45, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "MATT", voice_id: all_voices[4].voice_id, pitch: 40, speed: 55, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "JENNY", voice_id: all_voices[2].voice_id, pitch: 70, speed: 60, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "SUSAN", voice_id: all_voices[7].voice_id, pitch: 45, speed: 40, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "GARY", voice_id: all_voices[5].voice_id, pitch: 30, speed: 35, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "RUTH", voice_id: all_voices[13].voice_id, pitch: 20, speed: 30, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "GLENN", voice_id: all_voices[15].voice_id, pitch: 55, speed: 50, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "BABY", voice_id: all_voices[3].voice_id, pitch: 90, speed: 40, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "STELLA", voice_id: all_voices[1].voice_id, pitch: 55, speed: 30, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "ANNA", voice_id: all_voices[2].voice_id, pitch: 45, speed: 65, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "ED", voice_id: all_voices[16].voice_id, pitch: 65, speed: 70, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "LARRY", voice_id: all_voices[0].voice_id, pitch: 40, speed: 30, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "SID", voice_id: all_voices[17].voice_id, pitch: 75, speed: 50, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "TIFFANIE", voice_id: all_voices[6].voice_id, pitch: 60, speed: 55, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "ARTIE", voice_id: all_voices[11].voice_id, pitch: 30, speed: 45, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "CHARLOTTE", voice_id: all_voices[1].voice_id, pitch: 80, speed: 40, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "CHUCK", voice_id: all_voices[14].voice_id, pitch: 70, speed: 60, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "BILLIE", voice_id: all_voices[3].voice_id, pitch: 85, speed: 70, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "JJ", voice_id: all_voices[12].voice_id, pitch: 50, speed: 75, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "BEV", voice_id: all_voices[7].voice_id, pitch: 35, speed: 65, mode: 0, style: 0, tweaked: true, sprite: -1 },
    { name: "LUCILLE", voice_id: all_voices[13].voice_id, pitch: 50, speed: 25, mode: 0, style: 0, tweaked: true, sprite: -1 }
];

// Character sprites
char_sprites = ds_map_create();
get_character_sprite = function(_char_index) {
    if (_char_index < 0 || _char_index >= array_length(characters)) return -1;
    var _c = characters[_char_index];
    if (ds_map_exists(char_sprites, _c.name)) return char_sprites[? _c.name];
    var _path = working_directory + "images/characters/" + string_lower(_c.name) + ".png";
    if (file_exists(_path)) {
        var _spr = sprite_add(_path, 1, true, false, 0, 0);
        ds_map_add(char_sprites, _c.name, _spr);
        return _spr;
    }
    return -1;
}

selected_character_index = 0;
edit_mode = false; 
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
action_modal_char_onstage = false;

action_animating = false;
action_anim_char_index = -1;
action_anim_target_x = 0;
action_anim_target_y = 0;
action_anim_speed = 2.5;
action_anim_type = ""; 

all_actions = [
    { name: "enters left", desc: "Character walks in from the left side of the screen." },
    { name: "enters right", desc: "Character walks in from the right side of the screen." },
    { name: "turns around", desc: "Character flips their horizontal facing direction." }
];

char_facings = array_create(array_length(characters), 1);

array_sort(all_scenes, function(a, b) {
    if (a.internal_name < b.internal_name) return -1;
    if (a.internal_name > b.internal_name) return 1;
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
    return -1;
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
scene_modal_scroll_y = 0;
scene_modal_target_index = -1; // -1 means add to end

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
scene_edit_menu_actor_idx = -1; // -1 if placing new, >=0 if moving existing
scene_edit_menu_pending_x = 0;
scene_edit_menu_pending_y = 0;
scene_edit_menu_pending_face = 1;
scene_edit_menu_orig_x = 0; // For cancel
scene_edit_menu_orig_y = 0;
scene_edit_menu_orig_face = 1;

// --- 3c. INSERTION CONTEXT MENU ---
insert_menu_open = false;
insert_menu_x = 0;
insert_menu_y = 0;
insert_menu_target_idx = -1;
insert_menu_above = true;

is_speaking      = false;  
check_timer      = 0;      
speaking_timer   = 0;      
speaking_pause_timer = 0;  

// --- 4. VISUAL HIGHLIGHTING ---
speaking_word_start = -1;  // Starting index of the word currently being spoken
speaking_word_len   = 0;   // Length of the active word highlight
speaking_index      = 0;   // Floating point index for smooth word tracking

// --- 5. UI & LAYOUT ---
scene_win_x = 50; scene_win_y = 60; scene_win_w = 800; scene_win_h = 450; // Scene window (16:9)
box_x = 50; box_y = 570; box_w = 1180; box_h = 370; // Main text box (Stretched down for 4:3 ratio)
btn_play_x = (box_x + box_w / 2) - (btn_play_w / 2); btn_play_y = 520; 

// --- 6. CHARACTER SELECTION DROPDOWN ---
dropdown_open = false;
dropdown_scroll_y = 0;
dropdown_w = 350;
dropdown_h = 35;
btn_edit_w        = 130;
btn_edit_h        = 35;
btn_edit_x        = box_x + box_w - btn_edit_w;
btn_edit_y        = 520;
dropdown_x        = btn_edit_x - 15 - dropdown_w;
dropdown_y        = 520;

// --- 7. TEXT SCROLLING & RENDERING ---
text_scroll_y      = 0;
text_surface       = -1; // Surface used for clipping the text area
is_scrolling_text  = false;
click_count        = 0;  // For double-click detection
click_timer        = 0;
repeat_timer       = 0;  // Keyboard repeat speed
repeat_key         = vk_nokey;

// --- 8. CHARACTER SELECTOR & CONTROLLER LAYOUT ---
char_sel_x = 880; char_sel_y = 60; char_sel_w = 350; char_sel_h = 450;
char_sel_scroll_y = 0;

ctrl_x = 880; ctrl_y = char_sel_y + char_sel_h + 20; ctrl_w = 350; ctrl_h = 150;
slider_x = ctrl_x + 30; 
slider_w = 25; slider_h = 100; // Scaled down sliders to fit
pitch_y = ctrl_y + 40;
speed_y = ctrl_y + 160;

radio_x = ctrl_x + 100;
effort_y = ctrl_y + 40;
quality_y = ctrl_y + 140;

// --- 8. CORE ENGINE METHODS ---

/**
 * Recalculates the height for a specific block.
 * Standardizes calculation to avoid redundancy in Step event.
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
        _b.height = max(60, string_height_ext(_b.text, 28, _wrap_w)) + 25;
    }
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
 * Starts playback from a specific block, calculating proper scene state.
 */
play_from_index = function(_idx) {
    if (_idx < 0 || _idx >= array_length(script_blocks)) return;
    
    // Disable splicing and staging modes before playback starts
    scene_edit_mode = false;
    insertion_idx = -1;
    
    // 1. Find the last scene heading
    active_scene_block_idx = -1;
    for (var j = _idx; j >= 0; j--) {
        if (variable_struct_exists(script_blocks[j], "type") && script_blocks[j].type == "scene") {
            active_scene_block_idx = j;
            break;
        }
    }
    
    // 2. Initialize actors from that scene
    preview_actors = [];
    if (active_scene_block_idx != -1) {
        var _scene = script_blocks[active_scene_block_idx];
        if (variable_struct_exists(_scene, "actors")) {
            for (var a = 0; a < array_length(_scene.actors); a++) {
                var _sa = _scene.actors[a];
                var _face = variable_struct_exists(_sa, "facing") ? _sa.facing : 1;
                array_push(preview_actors, { char_index: _sa.char_index, x: _sa.x, y: _sa.y, is_base: true, facing: _face });
            }
        }
        
        // 3. Fast-forward through actions up to the target index
        for (var j = active_scene_block_idx + 1; j < _idx; j++) {
            var _b = script_blocks[j];
            if (variable_struct_exists(_b, "type") && _b.type == "action") {
                var _aname = string_lower(_b.action_name);
                var _is_enter = (string_pos("enter", _aname) > 0);
                var _is_exit = (string_pos("exit", _aname) > 0);
                var _is_left = (string_pos("left", _aname) > 0);
                
                var _act_idx = -1;
                for (var k = 0; k < array_length(preview_actors); k++) {
                    if (preview_actors[k].char_index == _b.char_index) { _act_idx = k; break; }
                }
                
                if (_is_enter) {
                    if (_act_idx == -1) {
                        var _spr = get_character_sprite(_b.char_index);
                        var _w = (_spr != -1) ? sprite_get_width(_spr) * ((scene_win_h * 0.75) / sprite_get_height(_spr)) : 100;
                        var _start_x = _is_left ? (_w/2) + 20 : scene_win_w - (_w/2) - 20; 
                        
                        var _final_x = variable_struct_exists(_b, "target_x") ? _b.target_x : _start_x;
                        var _final_y = variable_struct_exists(_b, "target_y") ? _b.target_y : (scene_win_h * 0.8);
                        
                        var _face = _is_left ? -1 : 1;
                        char_facings[_b.char_index] = _face;
                        array_push(preview_actors, { char_index: _b.char_index, x: _final_x, y: _final_y, is_base: false, facing: _face });
                    } else {
                        // If already onstage, update position and handle auto-facing
                        if (variable_struct_exists(_b, "target_x")) {
                            if (_b.target_x > preview_actors[_act_idx].x) preview_actors[_act_idx].facing = -1;
                            else if (_b.target_x < preview_actors[_act_idx].x) preview_actors[_act_idx].facing = 1;
                            preview_actors[_act_idx].x = _b.target_x;
                            preview_actors[_act_idx].y = _b.target_y;
                        }
                        // Explicit side mention overrides auto-facing
                        if (string_pos("left", _aname) > 0) preview_actors[_act_idx].facing = -1;
                        else if (string_pos("right", _aname) > 0) preview_actors[_act_idx].facing = 1;
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
                            // Auto-face movement direction
                            if (_b.target_x > preview_actors[_act_idx].x) preview_actors[_act_idx].facing = -1;
                            else if (_b.target_x < preview_actors[_act_idx].x) preview_actors[_act_idx].facing = 1;
                            preview_actors[_act_idx].x = _b.target_x;
                            preview_actors[_act_idx].y = _b.target_y;
                            char_facings[_b.char_index] = preview_actors[_act_idx].facing;
                        }
                    }
                }
            }
        }
    }
    
    // 4. Start playback
    playing_block_index = _idx;
    is_speaking = false;
    speaking_pause_timer = -1; // Special flag to start current index immediately
    action_animating = false;
    audio_stop_all();
    tts_stop();
};


/**
 * Safely deletes a portion of a string, preventing out-of-bounds errors.
 */
safe_delete = function(_str, _start, _count) {
    if (string_length(_str) == 0) return "";
    var _s = clamp(_start, 1, string_length(_str));
    var _c = min(_count, string_length(_str) - _s + 1);
    if (_c <= 0) return _str;
    return string_delete(_str, _s, _c);
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

// --- 7. WARM UP TTS ENGINE ---
// Speak a silent space to initialize the engine process and prevent first-play lag
if (array_length(all_voices) > 0) {
    tts_speak(" ", all_voices[0].voice_id, 50, 50, 0, 0);
    tts_stop();
}
