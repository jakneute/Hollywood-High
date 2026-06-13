/// @description Actor Studio — render UI and live composite
var _mx = mouse_x; var _my = mouse_y;

var _c_bg     = make_color_rgb(8, 24, 12);
var _c_panel  = make_color_rgb(10, 42, 15);
var _c_accent = make_color_rgb(196, 213, 20);
var _c_hi     = make_color_rgb(18, 72, 26);
var _c_dim    = make_color_rgb(120, 150, 120);

draw_set_font(-1);
draw_set_halign(fa_left); draw_set_valign(fa_top);

// --- BACKGROUND ---
draw_set_color(_c_bg);
draw_rectangle(0, 0, 1280, 960, false);

// --- TITLE BAR ---
draw_set_color(_c_accent);
draw_set_halign(fa_left);
draw_text(24, 22, "ACTOR STUDIO");
draw_set_color(_c_dim);
draw_text(24, 50, "Build custom photo-actors from loose PNGs + actor.json");

// --- BACK BUTTON ---
var _back_hov = (_mx > back_btn_x && _mx < back_btn_x + back_btn_w && _my > back_btn_y && _my < back_btn_y + back_btn_h);
draw_set_color(_back_hov ? _c_hi : _c_panel);
draw_rectangle(back_btn_x, back_btn_y, back_btn_x + back_btn_w, back_btn_y + back_btn_h, false);
draw_set_color(_c_accent);
draw_rectangle(back_btn_x, back_btn_y, back_btn_x + back_btn_w, back_btn_y + back_btn_h, true);
draw_set_color(c_white);
draw_set_halign(fa_center); draw_set_valign(fa_middle);
draw_text(back_btn_x + back_btn_w / 2, back_btn_y + back_btn_h / 2, "< BACK TO EDITOR");
draw_set_halign(fa_left); draw_set_valign(fa_top);

// ============================================================
// LEFT PANEL — ACTOR LIST
// ============================================================
draw_set_color(_c_panel);
draw_rectangle(ui_list_x, ui_list_y, ui_list_x + ui_list_w, ui_list_y + ui_list_h, false);
draw_set_color(_c_accent);
draw_rectangle(ui_list_x, ui_list_y, ui_list_x + ui_list_w, ui_list_y + ui_list_h, true);
draw_text(ui_list_x + 12, ui_list_y + 12, "CUSTOM ACTORS");

if (array_length(studio_actors) == 0) {
    draw_set_color(_c_dim);
    var _msg = "No custom actors found.\n\nCreate a folder:\nactors/(Name)/\n\nwith body/ face/ eyes/\nmouth/ and actor.json\n\nSee custom_actor_plan\nfor the full spec.";
    draw_text_ext(ui_list_x + 14, ui_list_y + 56, _msg, 22, ui_list_w - 28);
} else {
    var _row_h = 40;
    for (var _i = 0; _i < array_length(studio_actors); _i++) {
        var _ry = ui_list_y + 50 + _i * _row_h;
        var _sel = (_i == selected_actor);
        var _hov = (_mx > ui_list_x + 8 && _mx < ui_list_x + ui_list_w - 8 && _my > _ry && _my < _ry + _row_h - 4);
        if (_sel || _hov) {
            draw_set_color(_sel ? _c_hi : make_color_rgb(14, 56, 20));
            draw_rectangle(ui_list_x + 8, _ry, ui_list_x + ui_list_w - 8, _ry + _row_h - 4, false);
        }
        draw_set_color(_sel ? _c_accent : c_white);
        var _a = studio_actors[_i];
        var _label = _a.name + (_a.data == undefined ? "  (no actor.json)" : "");
        draw_text(ui_list_x + 18, _ry + 8, _label);
    }
}

// ============================================================
// CENTER CANVAS — COMPOSITE PREVIEW
// ============================================================
draw_set_color(make_color_rgb(30, 34, 40));
draw_rectangle(ui_canvas_x, ui_canvas_y, ui_canvas_x + ui_canvas_w, ui_canvas_y + ui_canvas_h, false);
draw_set_color(_c_accent);
draw_rectangle(ui_canvas_x, ui_canvas_y, ui_canvas_x + ui_canvas_w, ui_canvas_y + ui_canvas_h, true);

var _has_actor = (selected_actor >= 0 && selected_actor < array_length(studio_actors));
var _data = _has_actor ? studio_actors[selected_actor].data : undefined;

if (!_has_actor) {
    draw_set_color(_c_dim);
    draw_set_halign(fa_center);
    draw_text(ui_canvas_x + ui_canvas_w / 2, ui_canvas_y + ui_canvas_h / 2, "Select an actor");
    draw_set_halign(fa_left);
} else if (_data == undefined || !is_struct(_data)) {
    draw_set_color(make_color_rgb(220, 120, 120));
    draw_set_halign(fa_center);
    draw_text(ui_canvas_x + ui_canvas_w / 2, ui_canvas_y + ui_canvas_h / 2, "actor.json missing or invalid");
    draw_set_halign(fa_left);
} else {
    var _folder = studio_actors[selected_actor].folder;
    var _poses  = variable_struct_exists(_data, "poses")       ? _data.poses       : [];
    var _exprs  = variable_struct_exists(_data, "expressions") ? _data.expressions : [];
    var _eyes   = variable_struct_exists(_data, "eyes")        ? _data.eyes        : [];
    var _mouths = variable_struct_exists(_data, "mouths")      ? _data.mouths      : [];
    var _foff   = variable_struct_exists(_data, "face_offsets")? _data.face_offsets: undefined;

    if (array_length(_poses) == 0) {
        draw_set_color(_c_dim);
        draw_set_halign(fa_center);
        draw_text(ui_canvas_x + ui_canvas_w / 2, ui_canvas_y + ui_canvas_h / 2, "No poses defined in actor.json");
        draw_set_halign(fa_left);
    } else {
        var _pose = _poses[clamp(selected_pose, 0, array_length(_poses) - 1)];

        // Resolve sprites (facing right for the studio preview)
        var _body_spr = actor_studio_sprite(studio_sprite_cache, _folder + (variable_struct_exists(_pose, "file_right") ? _pose.file_right : ""));
        var _face_spr = actor_studio_sprite(studio_sprite_cache, _folder + (variable_struct_exists(_pose, "face_right") ? _pose.face_right : ""));

        // Resolve expression -> eye / mouth tile ids -> files
        var _eye_spr = -1; var _mouth_spr = -1;
        if (array_length(_exprs) > 0) {
            var _expr = _exprs[clamp(selected_expression, 0, array_length(_exprs) - 1)];
            var _eye_id   = variable_struct_exists(_expr, "eyes")  ? _expr.eyes  : "";
            var _mouth_id = variable_struct_exists(_expr, "mouth") ? _expr.mouth : "";
            for (var _e = 0; _e < array_length(_eyes); _e++) {
                if (variable_struct_exists(_eyes[_e], "id") && _eyes[_e].id == _eye_id) {
                    _eye_spr = actor_studio_sprite(studio_sprite_cache, _folder + (variable_struct_exists(_eyes[_e], "file_right") ? _eyes[_e].file_right : ""));
                    break;
                }
            }
            for (var _m = 0; _m < array_length(_mouths); _m++) {
                if (variable_struct_exists(_mouths[_m], "id") && _mouths[_m].id == _mouth_id) {
                    _mouth_spr = actor_studio_sprite(studio_sprite_cache, _folder + (variable_struct_exists(_mouths[_m], "file_right") ? _mouths[_m].file_right : ""));
                    break;
                }
            }
        }

        // Compute fit scale so the body fills ~75% of canvas height, times the height slider
        var _draw_scale = 1.0;
        if (_body_spr != -1) {
            var _bh = sprite_get_height(_body_spr);
            if (_bh > 0) _draw_scale = (ui_canvas_h * 0.75) / _bh;
        }
        _draw_scale *= height_scale;

        // Body anchored bottom-center
        var _baseline = ui_canvas_y + ui_canvas_h - 40;
        var _cx = ui_canvas_x + ui_canvas_w / 2;
        var _bw = (_body_spr != -1) ? sprite_get_width(_body_spr)  : 0;
        var _bh2 = (_body_spr != -1) ? sprite_get_height(_body_spr) : 0;
        var _body_x = _cx - (_bw * _draw_scale) / 2;
        var _body_y = _baseline - (_bh2 * _draw_scale);

        var _face_off  = actor_studio_offset(_pose, "face_offset");
        var _eye_off   = actor_studio_offset(_foff, "eye_offset");
        var _mouth_off = actor_studio_offset(_foff, "mouth_offset");

        // Layer 1: body
        if (_body_spr != -1) draw_sprite_ext(_body_spr, 0, _body_x, _body_y, _draw_scale, _draw_scale, 0, c_white, 1);
        // Layer 2: face at face_offset
        var _face_x = _body_x + _face_off[0] * _draw_scale;
        var _face_y = _body_y + _face_off[1] * _draw_scale;
        if (_face_spr != -1) draw_sprite_ext(_face_spr, 0, _face_x, _face_y, _draw_scale, _draw_scale, 0, c_white, 1);
        // Layer 3: eyes at face_offset + eye_offset
        if (_eye_spr != -1) draw_sprite_ext(_eye_spr, 0, _face_x + _eye_off[0] * _draw_scale, _face_y + _eye_off[1] * _draw_scale, _draw_scale, _draw_scale, 0, c_white, 1);
        // Layer 4: mouth at face_offset + mouth_offset
        if (_mouth_spr != -1) draw_sprite_ext(_mouth_spr, 0, _face_x + _mouth_off[0] * _draw_scale, _face_y + _mouth_off[1] * _draw_scale, _draw_scale, _draw_scale, 0, c_white, 1);

        // Missing-layer warnings
        if (_body_spr == -1) {
            draw_set_color(make_color_rgb(220, 120, 120));
            draw_text(ui_canvas_x + 14, ui_canvas_y + 14, "body PNG missing for this pose");
        }
    }
}

// ============================================================
// RIGHT PANEL — CONTROLS
// ============================================================
draw_set_color(_c_panel);
draw_rectangle(ui_panel_x, ui_panel_y, ui_panel_x + ui_panel_w, ui_panel_y + ui_panel_h, false);
draw_set_color(_c_accent);
draw_rectangle(ui_panel_x, ui_panel_y, ui_panel_x + ui_panel_w, ui_panel_y + ui_panel_h, true);
draw_text(ui_panel_x + 12, ui_panel_y + 12, "PREVIEW CONTROLS");

if (_has_actor && _data != undefined && is_struct(_data)) {
    var _poses2 = variable_struct_exists(_data, "poses")       ? _data.poses       : [];
    var _exprs2 = variable_struct_exists(_data, "expressions") ? _data.expressions : [];

    // ---- POSE CYCLER ----
    draw_set_color(c_white);
    draw_text(ui_panel_x + 20, ui_panel_y + 80, "POSE");
    var _py = ui_panel_y + 110;
    actor_studio_arrow(ui_panel_x + 20, _py, "<", _mx, _my, _c_hi, _c_panel, _c_accent);
    actor_studio_arrow(ui_panel_x + ui_panel_w - 64, _py, ">", _mx, _my, _c_hi, _c_panel, _c_accent);
    draw_set_color(c_white);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    var _pose_label = "-";
    if (array_length(_poses2) > 0) {
        var _pp = _poses2[clamp(selected_pose, 0, array_length(_poses2) - 1)];
        _pose_label = variable_struct_exists(_pp, "id") ? string(_pp.id) : ("pose " + string(selected_pose + 1));
        _pose_label += "  (" + string(selected_pose + 1) + "/" + string(array_length(_poses2)) + ")";
    }
    draw_text(ui_panel_x + ui_panel_w / 2, _py + 22, _pose_label);
    draw_set_halign(fa_left); draw_set_valign(fa_top);

    // ---- EXPRESSION CYCLER ----
    draw_set_color(c_white);
    draw_text(ui_panel_x + 20, ui_panel_y + 220, "EXPRESSION");
    var _ey = ui_panel_y + 250;
    actor_studio_arrow(ui_panel_x + 20, _ey, "<", _mx, _my, _c_hi, _c_panel, _c_accent);
    actor_studio_arrow(ui_panel_x + ui_panel_w - 64, _ey, ">", _mx, _my, _c_hi, _c_panel, _c_accent);
    draw_set_color(c_white);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    var _expr_label = "-";
    if (array_length(_exprs2) > 0) {
        var _ee = _exprs2[clamp(selected_expression, 0, array_length(_exprs2) - 1)];
        _expr_label = variable_struct_exists(_ee, "id") ? string(_ee.id) : ("expr " + string(selected_expression + 1));
        _expr_label += "  (" + string(selected_expression + 1) + "/" + string(array_length(_exprs2)) + ")";
    }
    draw_text(ui_panel_x + ui_panel_w / 2, _ey + 22, _expr_label);
    draw_set_halign(fa_left); draw_set_valign(fa_top);

    // ---- HEIGHT SLIDER ----
    draw_set_color(c_white);
    draw_text(ui_panel_x + 20, ui_panel_y + 380, "HEIGHT  " + string_format(height_scale, 1, 2) + "x");
    var _track_x = ui_panel_x + 30; var _track_w = ui_panel_w - 60;
    var _track_y = ui_panel_y + 410;
    draw_set_color(make_color_rgb(40, 60, 44));
    draw_rectangle(_track_x, _track_y - 3, _track_x + _track_w, _track_y + 3, false);
    var _knob_x = _track_x + ((height_scale - 0.5) / 1.0) * _track_w;
    draw_set_color(_c_accent);
    draw_rectangle(_knob_x - 6, _track_y - 10, _knob_x + 6, _track_y + 10, false);

    // ---- STATUS / TODO NOTE ----
    draw_set_color(_c_dim);
    draw_text_ext(ui_panel_x + 20, ui_panel_y + 470, "Skeleton: preview only.\nDrag-to-offset editing,\nGus reference guide, and\nsaving back to actor.json\nare not wired up yet.", 22, ui_panel_w - 40);
}

draw_set_halign(fa_left); draw_set_valign(fa_top);
draw_set_color(c_white);
