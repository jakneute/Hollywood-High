/// @description Professional Editor UI Renderer (With Hover Effects)
var _mx = mouse_x; var _my = mouse_y;

draw_clear(make_color_rgb(45, 45, 55)); 

//// --- 3. THEATER MODE RENDERER ---
if (theater_mode) {
    draw_set_color(c_black);
    draw_rectangle(0, 0, 1280, 960, false);
    
    // Background & Clipping Setup (Fit-to-Screen with Subtitle Safety)
    var _max_theater_h = 810; // Threshold to avoid subtitles/controls
    var _stage_w = 1280;
    var _stage_h = _max_theater_h;
    var _stage_x = 0;
    var _stage_y = 0;
    
    if (current_scene_sprite != -1) {
        var _bw = sprite_get_width(current_scene_sprite);
        var _sh = sprite_get_height(current_scene_sprite);
        
        // Calculate scale to fit within 1280 x 810
        var _sc_w = 1280 / _bw;
        var _sc_h = _max_theater_h / _sh;
        var _bg_sc = min(_sc_w, _sc_h); 
        
        _stage_w = _bw * _bg_sc;
        _stage_h = _sh * _bg_sc;
        
        // Centering within the 1280x810 area
        _stage_x = (1280 - _stage_w) / 2;
        _stage_y = (_max_theater_h - _stage_h) / 2;
        
        draw_sprite_ext(current_scene_sprite, 0, _stage_x, _stage_y, _bg_sc, _bg_sc, 0, c_white, 1);
    }
    
    // Actor Clipping (Clips exactly to the background area, clear of subtitles)
    gpu_set_scissor(_stage_x, _stage_y, _stage_w, _stage_h);
    
    // Actors
    for (var i = 0; i < array_length(preview_actors); i++) {
        var _act = preview_actors[i];
        var _spr = get_character_sprite(_act.char_index);
        if (_spr != -1) {
            var _csh = sprite_get_height(_spr);
            var _csw = sprite_get_width(_spr);
            // Matching Standard Scale (75% of theater stage height / 450px reference)
            var _asc = (_stage_h * 0.75) / 450; 
            
            // Accurate Mapping (Mapped to Centered Stage Area)
            var _ax = _stage_x + (_act.x / scene_win_w) * _stage_w;
            var _ay = _stage_y + (_act.y / scene_win_h) * _stage_h; 
            
            var _face = variable_struct_exists(_act, "facing") ? _act.facing : 1;
            
            // CENTER-MATH DRAWING
            var _draw_x = _ax - (_csw * _asc * _face / 2);
            var _draw_y = _ay - (_csh * _asc); 
            
            // Talking Glow (Theater Mode - Halo Pass)
            if (talking_glow_enabled && real(theater_active_char) == real(_act.char_index)) {
                var _pulse = (is_speaking) ? (0.4 + sin(current_time * 0.01) * 0.2) : 0;
                if (_pulse > 0) {
                    gpu_set_blendmode(bm_add);
                    draw_sprite_ext(_spr, 0, _draw_x - (_csw*_asc*0.04), _draw_y - (_csh*_asc*0.08), _asc * _face * 1.08, _asc * 1.08, 0, c_yellow, _pulse * 0.6);
                    gpu_set_blendmode(bm_normal);
                }
            }
            
            draw_sprite_ext(_spr, 0, _draw_x, _draw_y, _asc * _face, _asc, 0, c_white, 1);
            
            // Talking Glow (Theater Mode - Rim Light Pass)
            if (talking_glow_enabled && real(theater_active_char) == real(_act.char_index)) {
                var _pulse = (is_speaking) ? (0.4 + sin(current_time * 0.01) * 0.2) : 0;
                if (_pulse > 0) {
                    gpu_set_blendmode(bm_add);
                    draw_sprite_ext(_spr, 0, _draw_x, _draw_y, _asc * _face, _asc, 0, c_yellow, _pulse);
                    gpu_set_blendmode(bm_normal);
                }
            }
        }
    }
    gpu_set_scissor(0, 0, 1280, 960); // Reset clipping
    
    // Subtitles (Narrower to avoid Play/Exit buttons)
    if (theater_subtitles != "") {
        draw_set_alpha(0.7); draw_set_color(c_black);
        draw_rectangle(180, 820, 1100, 940, false); 
        draw_set_alpha(1.0);
        
        draw_set_color(c_yellow);
        var _name = (theater_active_char != -1) ? string_upper(characters[theater_active_char].name) : "";
        draw_text(200, 830, _name + ":");
        
        draw_set_color(c_white);
        draw_text_ext(200, 860, theater_subtitles, 32, 880);
    }
    
    // Controls
    // EXIT Button (Bottom Right)
    var _ex = 1280 - 200; var _ey = 860; var _ew = 180; var _eh = 50;
    var _ehov = (mouse_x > _ex && mouse_x < _ex + _ew && mouse_y > _ey && mouse_y < _ey + _eh);
    draw_set_color(_ehov ? make_color_rgb(200, 50, 50) : make_color_rgb(150, 40, 40));
    draw_rectangle(_ex, _ey, _ex + _ew, _ey + _eh, false);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_ex + 90, _ey + 15, "EXIT THEATER");
    draw_set_halign(fa_left);
    
    // PLAY/PAUSE Button (Bottom Left)
    var _px = 30; var _py = 860; var _pw = 120; var _ph = 50;
    var _phov = (mouse_x > _px && mouse_x < _px + _pw && mouse_y > _py && mouse_y < _py + _ph);
    draw_set_color(_phov ? make_color_rgb(100, 100, 200) : make_color_rgb(60, 60, 150));
    draw_rectangle(_px, _py, _px + _pw, _py + _ph, false);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_px + 60, _py + 15, theater_paused ? "PLAY" : "PAUSE");
    draw_set_halign(fa_left);
    
    return; // Stop here if in theater mode
}


// --- 1. GLOBAL BUTTONS (Shuffled Midsection) ---
btn_add_x = box_x; btn_add_y = dropdown_y;
btn_add_action_x = btn_add_x + 135; btn_add_action_y = dropdown_y;
btn_add_scene_x = btn_add_action_x + 135; btn_add_scene_y = dropdown_y;

btn_play_x = (box_x + box_w / 2) - (btn_play_w / 2);
btn_edit_x = box_x + box_w - btn_edit_w;
dropdown_x = btn_edit_x - 15 - dropdown_w;
dropdown_w = 350;

btn_add_w = 125; btn_add_h = 35;
btn_add_scene_w = 125; btn_add_scene_h = 35;
btn_add_action_w = 125; btn_add_action_h = 35;

var _add_hov = (_mx > btn_add_x && _mx < btn_add_x + btn_add_w && _my > btn_add_y && _my < btn_add_y + btn_add_h);
draw_set_color(_add_hov ? make_color_rgb(0, 220, 120) : make_color_rgb(0, 180, 100));
draw_rectangle(btn_add_x, btn_add_y, btn_add_x + btn_add_w, btn_add_y + btn_add_h, false);
draw_set_color(c_white); draw_text(btn_add_x + 12, btn_add_y + 5, "+ VOICE");

// --- 1.2 SCENE EDIT MODE INDICATOR ---
if (scene_edit_mode && active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
    var _scene = script_blocks[active_scene_block_idx];
    draw_set_color(make_color_rgb(255, 150, 0));
    draw_rectangle(scene_win_x, scene_win_y - 30, scene_win_x + 180, scene_win_y, false);
    draw_set_color(c_black); draw_text(scene_win_x + 10, scene_win_y - 25, "STAGING");
}

if (insertion_idx != -1 && !scene_edit_mode) {
    draw_set_color(make_color_rgb(0, 150, 255));
    draw_rectangle(scene_win_x, scene_win_y - 30, scene_win_x + 180, scene_win_y, false);
    draw_set_color(c_white); draw_text(scene_win_x + 10, scene_win_y - 25, "SPLICE MODE");
}
var _is_narrator = (selected_character_index == 0);
var _act_hov = (_mx > btn_add_action_x && _mx < btn_add_action_x + btn_add_action_w && _my > btn_add_action_y && _my < btn_add_action_y + btn_add_action_h);
var _act_col = _is_narrator ? make_color_rgb(50, 50, 60) : make_color_rgb(180, 50, 255);
var _act_hov_col = _is_narrator ? make_color_rgb(50, 50, 60) : make_color_rgb(220, 100, 255);
draw_set_color(_act_hov ? _act_hov_col : _act_col);
draw_rectangle(btn_add_action_x, btn_add_action_y, btn_add_action_x + btn_add_action_w, btn_add_action_y + btn_add_action_h, false);
draw_set_color(_is_narrator ? c_gray : c_white);
draw_text(btn_add_action_x + 12, btn_add_action_y + 5, "+ ACTION");

var _scn_hov = (_mx > btn_add_scene_x && _mx < btn_add_scene_x + btn_add_scene_w && _my > btn_add_scene_y && _my < btn_add_scene_y + btn_add_scene_h);
draw_set_color(_scn_hov ? make_color_rgb(0, 120, 220) : make_color_rgb(0, 100, 180));
draw_rectangle(btn_add_scene_x, btn_add_scene_y, btn_add_scene_x + btn_add_scene_w, btn_add_scene_y + btn_add_scene_h, false);
draw_set_color(c_white); draw_text(btn_add_scene_x + 12, btn_add_scene_y + 5, "+ SCENE");

// --- 1b. SCENE WINDOW ---
draw_set_color(c_black);
draw_rectangle(scene_win_x - 2, scene_win_y - 2, scene_win_x + scene_win_w + 2, scene_win_y + scene_win_h + 2, false);
if (current_scene_sprite != -1) {
    var _sw = sprite_get_width(current_scene_sprite);
    var _sh = sprite_get_height(current_scene_sprite);
    draw_sprite_ext(current_scene_sprite, 0, scene_win_x, scene_win_y, scene_win_w / _sw, scene_win_h / _sh, 0, c_white, 1);
}

// Actor Clipping (Clips exactly to the background area)
gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
if (active_scene_block_idx != -1 && active_scene_block_idx < array_length(script_blocks)) {
    var _scene = script_blocks[active_scene_block_idx];
    if (variable_struct_exists(_scene, "actors")) {
    for (var a = 0; a < array_length(preview_actors); a++) {
        var _act = preview_actors[a];
        
        var _is_being_dragged = false;
        if (dragging_actor_idx != -1 && dragging_actor_idx < array_length(_scene.actors) && _scene.actors[dragging_actor_idx].char_index == _act.char_index) {
            _is_being_dragged = true;
        }
        if (dragging_preview_idx != -1 && dragging_preview_idx < array_length(preview_actors) && preview_actors[dragging_preview_idx].char_index == _act.char_index) {
            _is_being_dragged = true;
        }
        if (_is_being_dragged) continue;
        
        var _spr = get_character_sprite(_act.char_index);
        if (_spr != -1) {
            var _csw = sprite_get_width(_spr);
            var _csh = sprite_get_height(_spr);
            var _scale = (scene_win_h * 0.75) / 450;
            var _is_speaking = false;
            if (playing_block_index != -1 && playing_block_index < array_length(script_blocks)) {
                var _pb = script_blocks[playing_block_index];
                if (!variable_struct_exists(_pb, "type") && real(_pb.char_index) == real(_act.char_index)) _is_speaking = true;
            }
            var _face = variable_struct_exists(_act, "facing") ? _act.facing : 1;
            var _sc = _scale;
            var _draw_x = scene_win_x + _act.x - (_csw * _sc * _face)/2;
            var _draw_y = scene_win_y + _act.y - (_csh * _sc);
            
            var _alpha = (dragging_preview_idx != -1 && dragging_preview_idx < array_length(preview_actors) && preview_actors[dragging_preview_idx].char_index == _act.char_index) ? 0.5 : 1.0;
            
            // Speaking Highlight (Editor Mode - Halo Pass)
            if (talking_glow_enabled && real(theater_active_char) == real(_act.char_index)) {
                var _pulse = (is_speaking) ? (0.4 + sin(current_time * 0.01) * 0.2) : 0;
                if (_pulse > 0) {
                    gpu_set_blendmode(bm_add);
                    draw_sprite_ext(_spr, 0, _draw_x - (_csw*_sc*0.04), _draw_y - (_csh*_sc*0.08), _sc * _face * 1.08, _sc * 1.08, 0, c_yellow, _pulse * 0.6);
                    gpu_set_blendmode(bm_normal);
                }
            }

            // Main Sprite
            draw_sprite_ext(_spr, 0, _draw_x, _draw_y, _sc * _face, _sc, 0, c_white, _alpha);
            
            // Speaking Highlight (Editor Mode - Rim Light Pass)
            if (talking_glow_enabled && real(theater_active_char) == real(_act.char_index)) {
                var _pulse = (is_speaking) ? (0.4 + sin(current_time * 0.01) * 0.2) : 0;
                if (_pulse > 0) {
                    gpu_set_blendmode(bm_add);
                    draw_sprite_ext(_spr, 0, _draw_x, _draw_y, _sc * _face, _sc, 0, c_yellow, _pulse);
                    gpu_set_blendmode(bm_normal);
                }
            }
            
            // Selection Highlight (Scene Edit Mode)
            if (scene_edit_mode && scene_edit_selected_actor_idx == a) {
                draw_set_color(c_yellow);
                draw_rectangle(_draw_x, _draw_y, _draw_x + (_csw * _sc * _face), _draw_y + (_csh * _sc), true);
            }
        }
    }
    
    }
}
gpu_set_scissor(0, 0, 1280, 960);

// --- 3d. STATIC FLIP BUTTON (Scene Edit Mode) ---
if (scene_edit_mode && scene_edit_selected_actor_idx != -1) {
    var _fx = scene_win_x + 200; var _fy = scene_win_y - 30;
    var _fhov = (_mx > _fx && _mx < _fx + 100 && _my > _fy && _my < _fy + 30);
    draw_set_color(_fhov ? c_white : make_color_rgb(100, 100, 255));
    draw_rectangle(_fx, _fy, _fx + 100, _fy + 30, false);
    draw_set_color(_fhov ? make_color_rgb(100, 100, 255) : c_white);
    draw_text(_fx + 25, _fy + 5, "FLIP");
}

// --- 1c. CHARACTER SELECTOR WINDOW ---
draw_set_color(make_color_rgb(35, 35, 45));
draw_rectangle(char_sel_x, char_sel_y, char_sel_x + char_sel_w, char_sel_y + char_sel_h, false);
draw_set_color(c_aqua); draw_rectangle(char_sel_x, char_sel_y, char_sel_x + char_sel_w, char_sel_y + char_sel_h, true);
draw_set_color(c_white); draw_text(char_sel_x + 10, char_sel_y + 5, "CHARACTER SELECTOR");

gpu_set_scissor(char_sel_x + 2, char_sel_y + 30, char_sel_w - 4, char_sel_h - 35);
var _grid_x = char_sel_x + 10; var _grid_y = char_sel_y + 35;
var _item_w = 80; var _item_h = 100; var _cols = 4;
for (var i = 0; i < array_length(characters); i++) {
    var _ix = _grid_x + (i % _cols) * _item_w;
    var _iy = _grid_y + floor(i / _cols) * _item_h + char_sel_scroll_y;
    if (_iy + _item_h < char_sel_y + 30 || _iy > char_sel_y + char_sel_h) continue;
    var _is_sel = (i == selected_character_index);
    var _hov = (_mx > _ix && _mx < _ix + _item_w && _my > _iy && _my < _iy + _item_h && _my > char_sel_y + 30 && _my < char_sel_y + char_sel_h);
    if (_hov || dragging_char_index == i) { draw_set_color(make_color_rgb(60, 60, 80)); draw_rectangle(_ix, _iy, _ix + _item_w - 5, _iy + _item_h - 5, false); }
    if (_is_sel) { draw_set_color(c_yellow); draw_rectangle(_ix, _iy, _ix + _item_w - 5, _iy + _item_h - 5, true); }
    var _spr = get_character_sprite(i);
    if (_spr != -1) {
        var _sc = (_item_h - 30) / sprite_get_height(_spr);
        draw_sprite_ext(_spr, 0, _ix + (_item_w - 5) / 2 - (sprite_get_width(_spr) * _sc) / 2, _iy + 5, _sc, _sc, 0, c_white, (dragging_char_index == i) ? 0.3 : 1.0);
    }
    draw_set_color(_is_sel ? c_yellow : c_white);
    var _disp_name = characters[i].name; if (string_length(_disp_name) > 8) _disp_name = string_copy(_disp_name, 1, 7) + ".";
    draw_text_transformed(_ix + 5, _iy + _item_h - 20, _disp_name, 0.8, 0.8, 0);
}
gpu_set_scissor(0, 0, 1280, 960);
if (dragging_char_index != -1 || dragging_actor_idx != -1 || dragging_preview_idx != -1) {
    var _char_id = -1;
    var _face = 1;
    if (dragging_char_index != -1) _char_id = dragging_char_index;
    else if (dragging_actor_idx != -1) {
        _char_id = script_blocks[active_scene_block_idx].actors[dragging_actor_idx].char_index;
        _face = script_blocks[active_scene_block_idx].actors[dragging_actor_idx].facing;
    }
    else if (dragging_preview_idx != -1) {
        _char_id = preview_actors[dragging_preview_idx].char_index;
        _face = preview_actors[dragging_preview_idx].facing;
    }
    
    var _spr = get_character_sprite(_char_id);
    if (_spr != -1) {
        var _csh = sprite_get_height(_spr);
        var _csw = sprite_get_width(_spr);
        var _scale = (scene_win_h * 0.75) / 450; 
        
        _mx = (window_mouse_get_x() / window_get_width()) * 1280;
        _my = (window_mouse_get_y() / window_get_height()) * 960;
        
        if (dragging_char_index != -1) {
            var _is_left = (_mx < scene_win_x + (scene_win_w/2));
            _face = _is_left ? -1 : 1;
        }

        var _cw = _csw * _scale;
        var _ch = _csh * _scale;
        
        // Proposed Position (with offsets, removed clamps)
        var _px = _mx - scene_win_x - drag_off_x;
        var _py = _my - scene_win_y - drag_off_y;

        // Vertical intersection
        var _ay_abs = scene_win_y + _py;
        var _v_top = _ay_abs - _ch;
        var _v_bottom = _ay_abs;
        var _v_visible = max(0, min(_v_bottom, scene_win_y + scene_win_h) - max(_v_top, scene_win_y));
        
        // Horizontal intersection (using Proposed Position)
        var _ax_abs = scene_win_x + _px;
        var _h_left = _ax_abs - (_cw * _face)/2;
        var _h_right = _ax_abs + (_cw * _face)/2;
        if (_face == -1) { var _tmp = _h_left; _h_left = _h_right; _h_right = _tmp; }
        
        var _h_intersect_l = max(_h_left, scene_win_x);
        var _h_intersect_r = min(_h_right, scene_win_x + scene_win_w);
        var _h_visible = max(0, _h_intersect_r - _h_intersect_l);
        
        var _in_live = (current_scene_sprite != -1) && (_v_visible >= _ch * 0.25) && (_h_visible >= _cw * 0.51);
        var _color = _in_live ? c_white : c_red;
        var _alpha = _in_live ? 0.6 : 0.4;
        
        gpu_set_scissor(scene_win_x, scene_win_y, scene_win_w, scene_win_h);
        var _gx = scene_win_x + _px - (_csw * _scale * _face)/2;
        var _gy = scene_win_y + _py - (_csh * _scale);
        draw_sprite_ext(_spr, 0, _gx, _gy, _scale * _face, _scale, 0, _color, _alpha);
        gpu_set_scissor(0, 0, 1280, 960);
    }
}

// --- 2. SCRIPT BLOCKS RENDERING ---
draw_set_color(make_color_rgb(250, 250, 250));
draw_rectangle(box_x + 10, box_y + 5, box_x + box_w - 10, box_y + box_h - 5, false);
gpu_set_scissor(box_x - 50, box_y + 5, box_w + 40, box_h - 10);
var _cur_y = box_y + 5 + block_scroll_y;
var _wrap_w = box_w - 120;
var _onstage = [];
var _scene_encountered = false;

for (var b = 0; b < array_length(script_blocks); b++) {
    var _block = script_blocks[b];
    var _is_scene = variable_struct_exists(_block, "type") && _block.type == "scene";
    var _is_action = variable_struct_exists(_block, "type") && _block.type == "action";

    if (_is_scene) {
    _onstage = [];
    _scene_encountered = true;
    if (variable_struct_exists(_block, "actors")) {
        for (var a = 0; a < array_length(_block.actors); a++) {
            array_push(_onstage, _block.actors[a].char_index);
        }
    }
    var _box_y = _cur_y + 5;
        draw_set_color((playing_block_index == b) ? make_color_rgb(255, 255, 180) : make_color_rgb(200, 200, 220));
        draw_rectangle(box_x + 45, _box_y, box_x + box_w - 45, _box_y + 80, false);
        draw_set_color(c_black); draw_text(box_x + 55, _box_y + 30, "[SCENE: " + string_upper(_block.name) + "]");
    } else if (_is_action) {
        var _aname = string_lower(_block.action_name);
        if (string_pos("enter", _aname) > 0) {
            var _found = false; for(var o=0; o<array_length(_onstage); o++) if (_onstage[o] == _block.char_index) _found = true;
            if (!_found) array_push(_onstage, _block.char_index);
        } else if (string_pos("exit", _aname) > 0) {
            for(var o=0; o<array_length(_onstage); o++) {
                if (_onstage[o] == _block.char_index) { array_delete(_onstage, o, 1); break; }
            }
        }

        var _box_y = _cur_y + 5;
        draw_set_color(make_color_rgb(210, 220, 210));
        draw_rectangle(box_x + 45, _box_y, box_x + box_w - 45, _box_y + 80, false);
        draw_set_color(c_black); draw_text(box_x + 55, _box_y + 30, "ACTION: " + characters[_block.char_index].name + " " + _block.action_name);
    } else {
        var _is_focused = (focused_block == b);
        var _text_h = _block.height - 25; // Matching Create_0 logic
        
        var _is_onstage = false;
        for(var o=0; o<array_length(_onstage); o++) if (_onstage[o] == _block.char_index) _is_onstage = true;
        
        var _char_name = string_upper(characters[_block.char_index].name);
        if (!_is_onstage && _block.char_index != 0) _char_name += " (offstage)";
        
        draw_set_color(make_color_rgb(100, 100, 120)); draw_text(box_x + 50, _cur_y, _char_name + ":");
        draw_set_color((playing_block_index == b) ? make_color_rgb(255, 255, 180) : (_is_focused ? make_color_rgb(245, 250, 255) : c_white));
        draw_rectangle(box_x + 45, _cur_y + 20, box_x + box_w - 45, _cur_y + 20 + _text_h, false);
        draw_set_color(_is_focused ? c_blue : c_black); draw_rectangle(box_x + 45, _cur_y + 20, box_x + box_w - 45, _cur_y + 20 + _text_h, true);
        draw_set_color(c_black); draw_text_ext(box_x + 60, _cur_y + 30, _block.text, 28, _wrap_w);
    }

    // Button Stacks
    var _lx = box_x + 10; var _rx = box_x + box_w - 35; var _bw = 28; var _bh = 22;
    
    // Left Hover Checks
    var _hov_up = (_mx > _lx && _mx < _lx + _bw && _my > _cur_y && _my < _cur_y + _bh);
    var _hov_ed = (_mx > _lx && _mx < _lx + _bw && _my > _cur_y+30 && _my < _cur_y + 30 + _bh);
    var _hov_dn = (_mx > _lx && _mx < _lx + _bw && _my > _cur_y+60 && _my < _cur_y + 60 + _bh);
    
    // Right Hover Checks
    var _hov_del = (_mx > _rx && _mx < _rx + _bw && _my > _cur_y && _my < _cur_y + _bh);
    var _hov_au  = (_mx > _rx && _mx < _rx + _bw && _my > _cur_y+30 && _my < _cur_y + 30 + _bh);
    var _hov_ad  = (_mx > _rx && _mx < _rx + _bw && _my > _cur_y+60 && _my < _cur_y + 60 + _bh);

    // Render Left Stack
    draw_set_color(_hov_up ? make_color_rgb(140, 140, 170) : make_color_rgb(100, 100, 120));
    draw_rectangle(_lx, _cur_y, _lx + _bw, _cur_y + _bh, false); 
    draw_set_color(c_white); draw_text(_lx+8, _cur_y, "^");
    
    draw_set_color(_hov_ed ? make_color_rgb(255, 255, 150) : c_yellow);
    draw_rectangle(_lx, _cur_y+30, _lx + _bw, _cur_y + 30 + _bh, false); 
    draw_set_color(c_black); draw_text(_lx+8, _cur_y+30, "/");
    
    draw_set_color(_hov_dn ? make_color_rgb(140, 140, 170) : make_color_rgb(100, 100, 120));
    draw_rectangle(_lx, _cur_y+60, _lx + _bw, _cur_y + 60 + _bh, false); 
    draw_set_color(c_white); draw_text(_lx+8, _cur_y+60, "v");

    // Render Right Stack
    draw_set_color(_hov_del ? make_color_rgb(230, 80, 80) : make_color_rgb(180, 50, 50));
    draw_rectangle(_rx, _cur_y, _rx + _bw, _cur_y + _bh, false); 
    draw_set_color(c_white); draw_text(_rx+6, _cur_y, "X");
    
    draw_set_color(_hov_au ? make_color_rgb(80, 200, 80) : make_color_rgb(50, 150, 50));
    draw_rectangle(_rx, _cur_y+30, _rx + _bw, _cur_y + 30 + _bh, false); 
    draw_set_color(c_white); draw_text(_rx+4, _cur_y+30, "^+");
    
    draw_set_color(_hov_ad ? make_color_rgb(80, 200, 80) : make_color_rgb(50, 150, 50));
    draw_rectangle(_rx, _cur_y+60, _rx + _bw, _cur_y + 60 + _bh, false); 
    draw_set_color(c_white); draw_text(_rx+4, _cur_y+60, "v+");

    // 4. Play From Here (Green Triangle) - Now in the GUTTER
    var _px = box_x - 30; var _py = _cur_y + 5;
    var _phov = (_mx > _px && _mx < _px + 30 && _my > _py && _my < _py + 30);
    draw_set_color(_phov ? c_lime : c_green);
    draw_triangle(_px+5, _py+5, _px+5, _py+25, _px+25, _py+15, false);

    var _gap_y = _cur_y + _block.height;
    if (insertion_idx == b && !action_animating && playing_block_index == -1) {
        draw_set_color(c_yellow);
        draw_set_alpha(0.3);
        draw_rectangle(box_x + 10, _gap_y + 2, box_x + box_w - 10, _gap_y + 23, false);
        draw_set_alpha(1.0);
        draw_set_color(c_yellow);
        draw_line_width(box_x + 10, _gap_y + 12, box_x + box_w - 10, _gap_y + 12, 2);
    }
    _cur_y += _block.height + 20;
}
gpu_set_scissor(0, 0, 1280, 960);

// --- 5. SCRIPT SCROLLBAR ---
var _full_h = 0; 
for (var i = 0; i < array_length(script_blocks); i++) {
    _full_h += script_blocks[i].height + 20;
}
_full_h += box_h / 2; // Match the Step event's normalized buffer

if (_full_h > box_h - 10) {
    var _view_h = box_h - 10;
    var _bar_h = (_view_h / _full_h) * _view_h;
    var _bar_y = (box_y + 5) + (-block_scroll_y / _full_h) * _view_h;
    
    // Draw Track
    draw_set_color(make_color_rgb(70, 70, 80));
    draw_rectangle(box_x + box_w - 10, box_y + 5, box_x + box_w - 2, box_y + box_h - 5, false); 
    
    // Draw Bar
    draw_set_color(make_color_rgb(120, 120, 140));
    draw_rectangle(box_x + box_w - 10, _bar_y, box_x + box_w - 2, _bar_y + _bar_h, false); 
}

// --- 5b. BOTTOM CONTROLS ---
var _p_hov = (_mx > btn_play_x && _mx < btn_play_x + btn_play_w && _my > btn_play_y && _my < btn_play_y + btn_play_h);
var _p_col = (playing_block_index != -1) ? make_color_rgb(200, 50, 50) : make_color_rgb(50, 180, 50);
var _p_hov_col = (playing_block_index != -1) ? make_color_rgb(255, 80, 80) : make_color_rgb(80, 220, 80);
draw_set_color(_p_hov ? _p_hov_col : _p_col);
draw_rectangle(btn_play_x, btn_play_y, btn_play_x + btn_play_w, btn_play_y + btn_play_h, false);
draw_set_color(c_white); draw_text(btn_play_x + 25, btn_play_y + 8, (playing_block_index != -1) ? "STOP" : "PLAY");

// ENTER THEATER Button
var _thov = (!theater_mode && !is_speaking && playing_block_index == -1 && insertion_idx == -1 && !scene_edit_mode && _mx > btn_theater_x && _mx < btn_theater_x + btn_theater_w && _my > btn_theater_y && _my < btn_theater_y + btn_theater_h);
draw_set_color(_thov ? make_color_rgb(100, 100, 200) : make_color_rgb(60, 60, 150));
draw_rectangle(btn_theater_x, btn_theater_y, btn_theater_x + btn_theater_w, btn_theater_y + btn_theater_h, false);
draw_set_color(c_white); draw_text(btn_theater_x + 10, btn_theater_y + 8, "ENTER THEATER");

draw_set_color(make_color_rgb(50, 50, 60)); draw_rectangle(dropdown_x, dropdown_y, dropdown_x + dropdown_w, dropdown_y + dropdown_h, false);
draw_set_color(c_aqua); draw_rectangle(dropdown_x, dropdown_y, dropdown_x + dropdown_w, dropdown_y + dropdown_h, true);
draw_set_color(c_white); draw_text(dropdown_x + 10, dropdown_y + 5, characters[selected_character_index].name);

var _ev_hov = (_mx > btn_edit_x && _mx < btn_edit_x + btn_edit_w && _my > btn_edit_y && _my < btn_edit_y + btn_edit_h);
draw_set_color(_ev_hov ? c_white : c_gray); draw_rectangle(btn_edit_x, btn_edit_y, btn_edit_x + btn_edit_w, btn_edit_y + btn_edit_h, false);
draw_set_color(c_white); draw_text(btn_edit_x + 10, btn_edit_y + 5, "EDIT VOICE");

// --- 6. MODALS ---
// Dropdown modal removed

if (edit_mode) {
    draw_set_color(c_black); draw_set_alpha(0.85); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _mw = 800; var _mh = 700; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    draw_set_color(make_color_rgb(30, 30, 40)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 20, 20, false);
    draw_set_color(make_color_rgb(100, 100, 255)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 20, 20, true);
    draw_set_color(c_white); draw_text_transformed(_mxo+30, _myo+25, "VOICE STUDIO", 1.2, 1.2, 0);
    
    _cols = 4; var _bw = 170; var _bh = 45; var _gx = (_mw - (_cols * (_bw + 15))) / 2;
    for (var i = 0; i < array_length(all_voices); i++) {
        var _bx = _mxo + _gx + ((i % _cols) * (_bw + 15));
        var _by = _myo + 70 + (floor(i / _cols) * (_bh + 8));
        var _is_sel = (all_voices[i].voice_id == modal_voice_id);
        var _v_hov = (_mx > _bx && _mx < _bx + _bw && _my > _by && _my < _by + _bh);
        draw_set_color(_is_sel ? make_color_rgb(0, 120, 255) : (_v_hov ? make_color_rgb(80, 80, 100) : make_color_rgb(50, 50, 70)));
        draw_roundrect_ext(_bx, _by, _bx + _bw, _by + _bh, 10, 10, false);
        draw_set_color(c_white); var _ns = all_voices[i].name; if (string_length(_ns) > 22) _ns = string_copy(_ns, 1, 20) + "..";
        draw_text(_bx + 10, _by + 13, _ns);
    }
	  // --- Tweak Toggle ---
    var _toggle_y = _myo + 580;
    var _twk_hov = (_mx > _mxo+50 && _mx < _mxo+350 && _my > _toggle_y && _my < _toggle_y+25);
    draw_set_color(_twk_hov ? c_white : c_ltgray);
    draw_rectangle(_mxo+50, _toggle_y, _mxo+70, _toggle_y+20, true); // checkbox outline
    if (tweak_enabled) { draw_set_color(c_lime); draw_rectangle(_mxo+54, _toggle_y+4, _mxo+66, _toggle_y+16, false); }
    draw_set_color(c_white); draw_text(_mxo+80, _toggle_y+2, "Advanced Voice Tweaks");

    // --- Tweak Controls (only when enabled) ---
    if (tweak_enabled) {
        var _ctrl_y = _myo + 360;
        
        // Pitch
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y, "Pitch:");
        draw_set_color(make_color_rgb(60,60,80)); draw_rectangle(_mxo+180, _ctrl_y, _mxo+480, _ctrl_y+20, false);
        draw_set_color(make_color_rgb(100,100,255)); draw_rectangle(_mxo+180, _ctrl_y, _mxo+180+(modal_pitch/180)*300, _ctrl_y+20, false);
        draw_set_color(c_white); draw_text(_mxo+165, _ctrl_y, "<"); draw_text(_mxo+485, _ctrl_y, ">");
        draw_text(_mxo+520, _ctrl_y, string(modal_pitch));

        // Speed
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+50, "Speed:");
        draw_set_color(make_color_rgb(60,60,80)); draw_rectangle(_mxo+180, _ctrl_y+50, _mxo+480, _ctrl_y+70, false);
        draw_set_color(make_color_rgb(100,255,100)); draw_rectangle(_mxo+180, _ctrl_y+50, _mxo+180+(modal_speed/180)*300, _ctrl_y+70, false);
        draw_set_color(c_white); draw_text(_mxo+165, _ctrl_y+50, "<"); draw_text(_mxo+485, _ctrl_y+50, ">");
        draw_text(_mxo+520, _ctrl_y+50, string(modal_speed));

        // Quality radio buttons
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+93, "Quality:");
        var _q_labels = ["Normal", "Monotone", "Sung"]; var _q_vals = [0, 2, 4];
        for (var e = 0; e < 3; e++) {
            var _ex = _mxo+180+(e*105);
            draw_set_color((modal_quality == _q_vals[e]) ? c_lime : c_gray);
            draw_circle(_ex, _ctrl_y+108, 10, true);
            if (modal_quality == _q_vals[e]) draw_circle(_ex, _ctrl_y+108, 6, false);
            draw_set_color(c_white); draw_text(_ex-12, _ctrl_y+120, _q_labels[e]);
        }

        // Effort radio buttons
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+133, "Effort:");
        var _s_labels = ["Normal", "Breathy", "Whispered"];
        for (var s = 0; s < 3; s++) {
            var _sx = _mxo+180+(s*105);
            draw_set_color((modal_effort == s) ? c_lime : c_gray);
            draw_circle(_sx, _ctrl_y+148, 10, true);
            if (modal_effort == s) draw_circle(_sx, _ctrl_y+148, 6, false);
            draw_set_color(c_white); draw_text(_sx-12, _ctrl_y+160, _s_labels[s]);
        }
    }

    // --- Bottom Buttons ---
    var _btn_y = _myo + _mh - 60;
    // Test
    var _t_hov = (_mx > _mxo+30 && _mx < _mxo+150 && _my > _btn_y && _my < _btn_y+40);
    draw_set_color(_t_hov ? c_white : make_color_rgb(50,150,200));
    draw_rectangle(_mxo+30, _btn_y, _mxo+150, _btn_y+40, false);
    draw_set_color(_t_hov ? make_color_rgb(50,150,200) : c_white); draw_text(_mxo+55, _btn_y+10, "TEST");
    // Save
    var _s_hov = (_mx > _mxo+_mw-280 && _mx < _mxo+_mw-150 && _my > _btn_y && _my < _btn_y+40);
    draw_set_color(_s_hov ? c_white : make_color_rgb(50,200,50));
    draw_rectangle(_mxo+_mw-280, _btn_y, _mxo+_mw-150, _btn_y+40, false);
    draw_set_color(_s_hov ? make_color_rgb(50,200,50) : c_white); draw_text(_mxo+_mw-240, _btn_y+10, "SAVE");
    // Cancel
    var _c_hov = (_mx > _mxo+_mw-140 && _mx < _mxo+_mw-30 && _my > _btn_y && _my < _btn_y+40);
    draw_set_color(_c_hov ? c_white : make_color_rgb(200,50,50));
    draw_rectangle(_mxo+_mw-140, _btn_y, _mxo+_mw-30, _btn_y+40, false);
    draw_set_color(_c_hov ? make_color_rgb(200,50,50) : c_white); draw_text(_mxo+_mw-105, _btn_y+10, "CANCEL");

}

if (scene_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _mw = 700; var _mh = 450; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    draw_set_color(make_color_rgb(40, 40, 50)); draw_rectangle(_mxo, _myo, _mxo+_mw, _myo+_mh, false);
    draw_set_color(c_aqua); draw_rectangle(_mxo, _myo, _mxo+_mw, _myo+_mh, true);
    
    var _max_h = 320; var _list_h = array_length(all_scenes) * 40; var _lw = 300;
    var _hov_idx = -1;
    gpu_set_scissor(_mxo+20, _myo+60, _lw, _max_h);
    for (var i = 0; i < array_length(all_scenes); i++) {
        var _by = _myo + 60 + (i * 40) + scene_modal_scroll_y;
        if (_by + 35 < _myo+60 || _by > _myo+60+_max_h) continue;
        var _hov = (_mx > _mxo+20 && _mx < _mxo+20+_lw && _my > _by && _my < _by+35);
        if (_hov) _hov_idx = i;
        draw_set_color(_hov ? make_color_rgb(60,60,100) : make_color_rgb(30,30,40));
        draw_rectangle(_mxo+20, _by, _mxo+20+_lw, _by+35, false);
        draw_set_color(c_white); draw_text(_mxo+30, _by+8, all_scenes[i].name);
    }
    gpu_set_scissor(0,0,1280,960);
    
    // Scrollbar for Scene Modal
    if (_list_h > _max_h) {
        var _bar_h = (_max_h / _list_h) * _max_h;
        var _bar_y = (_myo+60) + (-scene_modal_scroll_y / _list_h) * _max_h;
        draw_set_color(make_color_rgb(50, 50, 60));
        draw_rectangle(_mxo+20+_lw+5, _myo+60, _mxo+20+_lw+15, _myo+60+_max_h, false); // Track
        draw_set_color(make_color_rgb(120, 120, 140));
        draw_rectangle(_mxo+20+_lw+5, _bar_y, _mxo+20+_lw+15, _bar_y + _bar_h, false); // Bar
    }
    
    var _pre_x = _mxo + 350; var _pre_y = _myo + 60; var _pre_w = 320; var _pre_h = 320;
    draw_set_color(c_black); draw_rectangle(_pre_x, _pre_y, _pre_x+_pre_w, _pre_y+_pre_h, false);
    if (_hov_idx != -1) {
        var _spr = get_scene_sprite(all_scenes[_hov_idx].internal_name);
        if (_spr != -1) {
            var _sc = min(_pre_w/sprite_get_width(_spr), _pre_h/sprite_get_height(_spr)) * 0.9;
            draw_sprite_ext(_spr, 0, _pre_x + (_pre_w - sprite_get_width(_spr)*_sc)/2, _pre_y + (_pre_h - sprite_get_height(_spr)*_sc)/2, _sc, _sc, 0, c_white, 1);
        }
    }
	var _c_y = _myo + _mh - 50;
	var _can_hov = (_mx > _mxo+20 && _mx < _mxo+_mw-20 && _my > _c_y && _my < _c_y+35);
	draw_set_color(_can_hov ? make_color_rgb(200,50,50) : make_color_rgb(150,30,30));
	draw_rectangle(_mxo+20, _c_y, _mxo+_mw-20, _c_y+35, false);
	draw_set_color(c_white); draw_text(_mxo+(_mw/2)-20, _c_y+8, "CANCEL");
}

if (action_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _mw = 600; var _mh = 400; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    draw_set_color(make_color_rgb(40, 40, 50)); draw_rectangle(_mxo, _myo, _mxo+_mw, _myo+_mh, false);
    draw_set_color(c_aqua); draw_rectangle(_mxo, _myo, _mxo+_mw, _myo+_mh, true);
    for (var i = 0; i < array_length(all_actions); i++) {
        var _by = _myo + 60 + (i * 45);
        var _aname = string_lower(all_actions[i].name);
        var _disabled = false;
        if (action_modal_char_onstage && string_pos("enter", _aname) > 0) _disabled = true;
        if (!action_modal_char_onstage && string_pos("exit", _aname) > 0) _disabled = true;
        
        var _hov = (!_disabled && _mx > _mxo+20 && _mx < _mxo+270 && _my > _by && _my < _by+40);
        var _col = make_color_rgb(30,30,40);
        if (_disabled) _col = make_color_rgb(20,20,25);
        else if (action_modal_selected_idx == i) _col = make_color_rgb(80,80,150);
        else if (_hov) _col = make_color_rgb(60,60,80);
        
        draw_set_color(_col);
        draw_rectangle(_mxo+20, _by, _mxo+270, _by+40, false);
        draw_set_color(_disabled ? c_gray : c_white); draw_text(_mxo+30, _by+10, string_upper(all_actions[i].name));
    }
    
    // Description Box
    draw_set_color(make_color_rgb(30,30,40));
    draw_rectangle(_mxo+300, _myo+60, _mxo+580, _myo+330, false);
    if (action_modal_selected_idx != -1) {
        draw_set_color(c_white);
        draw_text_ext(_mxo+310, _myo+70, all_actions[action_modal_selected_idx].desc, 25, 260);
    }
    
    // OK / Cancel Buttons
    var _ok_hov = (action_modal_locked && _mx > _mxo+20 && _mx < _mxo+290 && _my > _myo+350 && _my < _myo+385);
    draw_set_color(action_modal_locked ? (_ok_hov ? make_color_rgb(50,200,50) : make_color_rgb(30,150,30)) : make_color_rgb(50,50,60));
    draw_rectangle(_mxo+20, _myo+350, _mxo+290, _myo+385, false);
    draw_set_color(action_modal_locked ? c_white : c_gray); draw_text(_mxo+130, _myo+355, "OK");
    
    var _can_hov = (_mx > _mxo+310 && _mx < _mxo+580 && _my > _myo+350 && _my < _myo+385);
    draw_set_color(_can_hov ? make_color_rgb(200,50,50) : make_color_rgb(150,30,30));
    draw_rectangle(_mxo+310, _myo+350, _mxo+580, _myo+385, false);
    draw_set_color(c_white); draw_text(_mxo+420, _myo+355, "CANCEL");
}

if (insert_menu_open) {
    var _mw = 120; var _mh = 105;
    draw_set_color(make_color_rgb(30, 30, 40)); draw_rectangle(insert_menu_x, insert_menu_y, insert_menu_x+_mw, insert_menu_y+_mh, false);
    draw_set_color(c_aqua); draw_rectangle(insert_menu_x, insert_menu_y, insert_menu_x+_mw, insert_menu_y+_mh, true);
    var _opts = ["VOICE", "SCENE", "ACTION"];
    for (var i=0; i<3; i++) {
        var _is_action = (i == 2);
        var _disabled = (_is_action && selected_character_index == 0);
        var _hov = (!_disabled && _mx > insert_menu_x && _mx < insert_menu_x+_mw && _my > insert_menu_y+(i*35) && _my < insert_menu_y+((i+1)*35));
        if (_hov) { draw_set_color(make_color_rgb(60, 60, 100)); draw_rectangle(insert_menu_x+1, insert_menu_y+(i*35)+1, insert_menu_x+_mw-1, insert_menu_y+((i+1)*35)-1, false); }
        draw_set_color(_disabled ? c_gray : c_white); draw_text(insert_menu_x + 10, insert_menu_y + (i*35) + 8, _opts[i]);
    }
}
