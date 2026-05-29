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
display_reset(0, true); // vsync — eliminates screen tearing
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
// Defined in: scr_utils (update_block_height, update_all_block_heights, apply_dictionary,
//             safe_delete, get_text_pos, get_link_type, get_index)

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
mouth_anim_cache   = ds_map_create(); // "charName_manim_pose_NNNNN.png" → array of animation frame sprites
char_sel_layer_cache = array_create(array_length(characters), undefined); // Per-character composite layer cache for the selector UI (avoids file_exists every frame)
// Defined in: scr_character_sprite (get_character_sprite, get_composite_character_sprite, get_mouth_anim_sprites)

// get_composite_character_sprite — defined in scr_character_sprite

// Returns array of animation-frame sprites for the speaking mouth cycle.
// get_mouth_anim_sprites — defined in scr_character_sprite

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

// refresh_sfx_folders = function() — defined in scr_scene/scr_utils/scr_expr_cfg

// refresh_sfx_files = function(_folder) — defined in scr_scene/scr_utils/scr_expr_cfg

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
// get_scene_sprite = function(_internal_name) — defined in scr_scene/scr_utils/scr_expr_cfg


scene_live_top = 0;
scene_live_bottom = 0;

// detect_scene_live_area = function(_spr) — defined in scr_scene/scr_utils/scr_expr_cfg

// set_scene_dimensions = function(_spr) — defined in scr_scene/scr_utils/scr_expr_cfg

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

is_speaking          = false;
speaking_has_progress = false; // true once the progress file appears, gating mouth animation
check_timer          = 0;
speaking_timer       = 0;
current_viseme_data  = [];   // [{t:0-1, v:0-21}] from SAPI5 pre-analysis; empty = fall back to cycling
current_viseme_req   = -1;   // request ID for which current_viseme_data was loaded
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

// update_preview_actors_for_block = function(_idx, _inclusive) — defined in scr_scene/scr_utils/scr_expr_cfg

/**
 * Starts playback from a specific block, calculating proper scene state.
 */
// play_from_index = function(_idx) — defined in scr_scene/scr_utils/scr_expr_cfg

/**
 * Calculates the character index based on mouse X/Y coordinates.
 * Prioritizes the vertical line (row) to prevent 'jumping' between empty lines.
 */
// get_index = function(_mx, _my) — defined in scr_scene/scr_utils/scr_expr_cfg

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
// expr_cfg_get_pc = function() — defined in scr_scene/scr_utils/scr_expr_cfg
// expr_cfg_set_pc = function(_v) — defined in scr_scene/scr_utils/scr_expr_cfg

// Auto-fill one config from offsets.json
// expr_cfg_auto_fill = function(_pose_num, _is_high) — defined in scr_scene/scr_utils/scr_expr_cfg

// Open the configurator for a character (Narrator has no sprite and is skipped)
// open_expr_configurator = function(_char_idx) — defined in scr_scene/scr_utils/scr_expr_cfg

// Save all configs for the current character.
// file_text_write is unreachable inside GML instance methods on this runtime,
// so we just stage the data and let the Step event do the actual write.
expr_cfg_pending_save_path = "";
expr_cfg_pending_save_data = "";

// Defringe shader uniform — eliminates anti-aliasing fringe on mouth sprites
defringe_u_texel = shader_is_compiled(shd_defringe) ? shader_get_uniform(shd_defringe, "u_texel_size") : -1;

expr_cfg_pan_x    = 0;        // preview pan offset in screen pixels
expr_cfg_pan_y    = 0;
expr_cfg_pan_drag = false;    // true while middle mouse is held
expr_cfg_pan_mx0  = 0;        // mouse position at drag start
expr_cfg_pan_my0  = 0;
expr_cfg_pan_ox   = 0;        // pan offset at drag start
expr_cfg_pan_oy   = 0;

// save_expr_config = function() — defined in scr_scene/scr_utils/scr_expr_cfg
