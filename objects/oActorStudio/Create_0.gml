/// @description Actor Studio — initialize state, scan custom actors
/*
 * Dedicated room for building custom photo-actors. Opens from the main editor's
 * file menu and returns there via the BACK button. The main editor (oHollywoodUI)
 * is persistent, so the loaded screenplay survives the round trip.
 */

// --- VIEW / CAMERA (match the 1280x960 design space of the main editor) ---
if (!variable_global_exists("studio_cam")) {
    global.studio_cam = camera_create_view(0, 0, 1280, 960, 0, -1, -1, -1, 0, 0);
}
view_enabled = true;
view_visible[0] = true;
view_xport[0] = 0; view_yport[0] = 0;
view_wport[0] = 1280; view_hport[0] = 960;
view_camera[0] = global.studio_cam;

// --- DATAFILES PATH (same resolver as oHollywoodUI) ---
datafiles_path = "d:/Projects/Game Maker/Hollywood High/datafiles/";
if (!directory_exists(datafiles_path)) datafiles_path = working_directory;
actors_base = datafiles_path + "actors/";

// --- ACTOR DATA ---
studio_sprite_cache = ds_map_create();
studio_actors = actor_studio_scan(actors_base);
selected_actor      = (array_length(studio_actors) > 0) ? 0 : -1;
selected_pose       = 0;
selected_expression = 0;
height_scale        = 1.0; // composite scale multiplier (height slider — stub for now)

// --- LAYOUT CONSTANTS ---
ui_list_x   = 20;  ui_list_y   = 90;  ui_list_w   = 280; ui_list_h   = 820;
ui_canvas_x = 320; ui_canvas_y = 90;  ui_canvas_w = 620; ui_canvas_h = 820;
ui_panel_x  = 960; ui_panel_y  = 90;  ui_panel_w  = 300; ui_panel_h  = 820;

back_btn_x = 1080; back_btn_y = 20; back_btn_w = 180; back_btn_h = 44;

// Fonts may be unset on first frame; guard draws against -1
studio_font = -1;
