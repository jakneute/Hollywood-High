function draw_modals() {
    var _mx = mouse_x; var _my = mouse_y;
// --- 6. MODALS ---
// Nearest-neighbour rendering for all modal UI — prevents fuzzy text on bright headers.
// draw_composite_character_ext saves/restores its own filter state, so this is safe.
gpu_set_texfilter(false);
if (dictionary_open) {
    draw_set_color(c_black); draw_set_alpha(0.8); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _m_w = 700; var _m_h = 500; var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    draw_set_color(make_color_rgb(14, 48, 20)); draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 14, 14, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + 52, 14, 14, false);
    draw_rectangle(_m_x, _m_y + 32, _m_x + _m_w, _m_y + 52, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 14, 14, true);
    draw_set_color(c_black); draw_text(_m_x + 20, _m_y + 18, "PRONUNCIATION DICTIONARY");
    draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_m_x + 20, _m_y + 58, "Written Word"); draw_text(_m_x + 280, _m_y + 58, "Pronunciation");

    gpu_set_scissor(_m_x + 10, _m_y + 80, _m_w - 20, 320);
    for (var i = 0; i < array_length(dictionary_list); i++) {
        var _ey = _m_y + 80 + (i * 45) + dictionary_scroll_y;
        var _entry = dictionary_list[i];
        
        // Column 1: Written
        draw_set_color((dict_focused_entry == i && dict_focused_field == 0) ? c_white : make_color_rgb(225, 240, 228));
        draw_roundrect_ext(_m_x + 20, _ey, _m_x + 260, _ey + 35, 5, 5, false);
        draw_set_color(c_black); draw_text(_m_x + 25, _ey + 8, _entry.written);
        if (dict_focused_entry == i && dict_focused_field == 0 && cursor_visible) {
            var _cx = string_width(string_copy(_entry.written, 1, dict_caret_pos));
            draw_set_color(c_blue);
            draw_line_width(_m_x + 25 + _cx, _ey + 5, _m_x + 25 + _cx, _ey + 30, 2);
        }

        // Column 2: Pronunciation
        draw_set_color((dict_focused_entry == i && dict_focused_field == 1) ? c_white : make_color_rgb(225, 240, 228));
        draw_roundrect_ext(_m_x + 280, _ey, _m_x + 520, _ey + 35, 5, 5, false);
        draw_set_color(c_black); draw_text(_m_x + 285, _ey + 8, _entry.pronunciation);
        if (dict_focused_entry == i && dict_focused_field == 1 && cursor_visible) {
            var _cx = string_width(string_copy(_entry.pronunciation, 1, dict_caret_pos));
            draw_set_color(c_blue);
            draw_line_width(_m_x + 285 + _cx, _ey + 5, _m_x + 285 + _cx, _ey + 30, 2);
        }
        
        // Test Button
        var _test_hov = (_mx > _m_x + 540 && _mx < _m_x + 610 && _my > _ey && _my < _ey + 35);
        draw_set_color(_test_hov ? make_color_rgb(20, 105, 32) : make_color_rgb(14, 70, 22));
        draw_roundrect_ext(_m_x + 540, _ey, _m_x + 610, _ey + 35, 5, 5, false);
        draw_set_color(_test_hov ? c_white : make_color_rgb(196, 213, 20));
        draw_roundrect_ext(_m_x + 540, _ey, _m_x + 610, _ey + 35, 5, 5, true);
        draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_m_x + 575, _ey + 8, "TEST"); draw_set_halign(fa_left);

        // Remove Button
        var _rhov = (_mx > _m_x + 630 && _mx < _m_x + 670 && _my > _ey && _my < _ey + 35);
        draw_set_color(_rhov ? make_color_rgb(210, 50, 50) : make_color_rgb(155, 28, 28));
        draw_roundrect_ext(_m_x + 630, _ey, _m_x + 670, _ey + 35, 5, 5, false);
        draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_m_x + 650, _ey + 8, "X"); draw_set_halign(fa_left);
    }
    gpu_set_scissor(0, 0, 1280, 960);

    // Dictionary Scrollbar
    var _dict_total_h = array_length(dictionary_list) * 45;
    var _dict_view_h = 320;
    if (_dict_total_h > _dict_view_h) {
        _sb_w = 8; _sb_x = _m_x + _m_w - 22;
        var _sb_y = _m_y + 80; var _sb_h = _dict_view_h;
        draw_set_color(make_color_rgb(8, 30, 12));
        draw_rectangle(_sb_x, _sb_y, _sb_x + _sb_w, _sb_y + _sb_h, false); // Track
        var _bar_h = (_dict_view_h / _dict_total_h) * _sb_h;
        var _bar_y = _sb_y + (-dictionary_scroll_y / _dict_total_h) * _sb_h;
        draw_set_color(make_color_rgb(155, 170, 38));
        draw_rectangle(_sb_x, _bar_y, _sb_x + _sb_w, _bar_y + _bar_h, false); // Handle
    }
    
    // Add Button
    var _ahov = (_mx > _m_x + 20 && _mx < _m_x + 150 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20);
    draw_set_color(_ahov ? make_color_rgb(22, 105, 32) : make_color_rgb(14, 70, 22));
    draw_roundrect_ext(_m_x + 20, _m_y + _m_h - 60, _m_x + 150, _m_y + _m_h - 20, 7, 7, false);
    draw_set_color(_ahov ? c_white : make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_m_x + 20, _m_y + _m_h - 60, _m_x + 150, _m_y + _m_h - 20, 7, 7, true);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_m_x + 85, _m_y + _m_h - 50, "ADD ENTRY"); draw_set_halign(fa_left);

    // Close Button
    var _chov = (_mx > _m_x + _m_w - 140 && _mx < _m_x + _m_w - 20 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20);
    draw_set_color(_chov ? make_color_rgb(190, 40, 40) : make_color_rgb(140, 22, 22));
    draw_roundrect_ext(_m_x + _m_w - 140, _m_y + _m_h - 60, _m_x + _m_w - 20, _m_y + _m_h - 20, 7, 7, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_m_x + _m_w - 80, _m_y + _m_h - 50, "CLOSE"); draw_set_halign(fa_left);
}

if (edit_mode) {
    draw_set_color(c_black); draw_set_alpha(0.85); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _mw = 800; var _mh = 700; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    draw_set_color(make_color_rgb(14, 48, 20)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 14, 14, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+56, 14, 14, false);
    draw_rectangle(_mxo, _myo+36, _mxo+_mw, _myo+56, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 14, 14, true);
    draw_set_color(c_black); draw_text(_mxo+28, _myo+19, modal_is_local_edit ? "ALTER VOICE — THIS BLOCK ONLY" : "VOICE STUDIO");
    
    var _cols = 4; var _bw = 170; var _bh = 45; var _gx = (_mw - (_cols * (_bw + 15))) / 2;
    for (var i = 0; i < array_length(all_voices); i++) {
        var _bx = _mxo + _gx + ((i % _cols) * (_bw + 15));
        var _by = _myo + 70 + (floor(i / _cols) * (_bh + 8));
        var _is_sel = (all_voices[i].voice_id == modal_voice_id);
        var _v_hov = (_mx > _bx && _mx < _bx + _bw && _my > _by && _my < _by + _bh);
        draw_set_color(_is_sel ? make_color_rgb(16, 58, 155) : (_v_hov ? make_color_rgb(20, 78, 30) : make_color_rgb(10, 42, 16)));
        draw_roundrect_ext(_bx, _by, _bx + _bw, _by + _bh, 8, 8, false);
        if (_is_sel) { draw_set_color(make_color_rgb(196, 213, 20)); draw_roundrect_ext(_bx, _by, _bx + _bw, _by + _bh, 8, 8, true); }
        draw_set_color(c_white); var _ns = all_voices[i].name; if (string_length(_ns) > 22) _ns = string_copy(_ns, 1, 20) + "..";
        draw_text(_bx + 10, _by + 13, _ns);
    }
    // --- Volume Slider (vertical, lower-right) ---
    var _vsl_cx = _mxo + 680;
    var _vsl_top = _myo + 370; var _vsl_bot = _myo + 570; var _vsl_h = _vsl_bot - _vsl_top;
    var _vsl_thumb_y = _vsl_top + (1 - modal_volume / 100.0) * _vsl_h;
    var _vsl_hov = (_mx > _vsl_cx-18 && _mx < _vsl_cx+18 && _my > _vsl_top-10 && _my < _vsl_bot+10);
    draw_set_halign(fa_center);
    draw_set_color(make_color_rgb(160, 160, 160)); draw_text(_vsl_cx, _myo+352, "VOL");
    draw_set_color(make_color_rgb(40, 55, 42)); draw_rectangle(_vsl_cx-5, _vsl_top, _vsl_cx+5, _vsl_bot, false);
    draw_set_color(slider_drag==4 ? make_color_rgb(100, 220, 120) : make_color_rgb(60, 160, 80));
    draw_rectangle(_vsl_cx-5, _vsl_thumb_y, _vsl_cx+5, _vsl_bot, false);
    draw_set_color(c_white); draw_circle(_vsl_cx, _vsl_thumb_y, 10, false);
    draw_set_color(slider_drag==4 ? make_color_rgb(100, 220, 120) : (_vsl_hov ? make_color_rgb(120, 200, 130) : make_color_rgb(60, 160, 80)));
    draw_circle(_vsl_cx, _vsl_thumb_y, 7, false);
    var _vol_db = round((modal_volume / 50.0 - 1.0) * 20);
    draw_set_color(make_color_rgb(160, 160, 160));
    draw_text(_vsl_cx, _vsl_bot+8,  string(round(modal_volume)));
    draw_text(_vsl_cx, _vsl_bot+22, (_vol_db >= 0 ? "+" : "") + string(_vol_db) + "dB");
    draw_set_halign(fa_left);

    // --- Tweak Toggle ---
    var _toggle_y = _myo + 610;
    var _twk_hov = (_mx > _mxo+50 && _mx < _mxo+350 && _my > _toggle_y && _my < _toggle_y+25);
    draw_set_color(_twk_hov ? c_white : c_ltgray);
    draw_rectangle(_mxo+50, _toggle_y, _mxo+70, _toggle_y+20, true); // checkbox outline
    if (tweak_enabled) { draw_set_color(c_lime); draw_rectangle(_mxo+54, _toggle_y+4, _mxo+66, _toggle_y+16, false); }
    draw_set_color(c_white); draw_text(_mxo+80, _toggle_y+2, "Advanced Voice Tweaks");

    // --- Tweak Controls (only when enabled) ---
    if (tweak_enabled) {
        var _ctrl_y = _myo + 360;
        
        // Pitch
        var _p_x = _mxo+180 + (modal_pitch/100)*300;
        _p_hov = (_mx > _mxo+180 && _mx < _mxo+480 && _my > _ctrl_y-5 && _my < _ctrl_y+25);
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+2, "Pitch:");
        draw_set_color(_p_hov || slider_drag==1 ? make_color_rgb(80,80,110) : make_color_rgb(60,60,80));
        draw_rectangle(_mxo+180, _ctrl_y+2, _mxo+480, _ctrl_y+18, false);
        draw_set_color(slider_drag==1 ? make_color_rgb(130,130,255) : make_color_rgb(100,100,255));
        draw_rectangle(_mxo+180, _ctrl_y+2, _p_x, _ctrl_y+18, false);
        draw_set_color(c_white); draw_circle(_p_x, _ctrl_y+10, 9, false);
        draw_set_color(slider_drag==1 ? make_color_rgb(130,130,255) : make_color_rgb(80,80,220)); draw_circle(_p_x, _ctrl_y+10, 6, false);
        draw_set_color(c_white); draw_text(_mxo+155, _ctrl_y+2, "<"); draw_text(_mxo+485, _ctrl_y+2, ">");
        draw_text(_mxo+520, _ctrl_y+2, string(round(modal_pitch)));

        // Speed
        var _s_x = _mxo+180 + (modal_speed/100)*300;
        var _s_hov = (_mx > _mxo+180 && _mx < _mxo+480 && _my > _ctrl_y+45 && _my < _ctrl_y+75);
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+52, "Speed:");
        draw_set_color(_s_hov || slider_drag==2 ? make_color_rgb(50,90,50) : make_color_rgb(40,65,40));
        draw_rectangle(_mxo+180, _ctrl_y+52, _mxo+480, _ctrl_y+68, false);
        draw_set_color(slider_drag==2 ? make_color_rgb(130,255,130) : make_color_rgb(100,255,100));
        draw_rectangle(_mxo+180, _ctrl_y+52, _s_x, _ctrl_y+68, false);
        draw_set_color(c_white); draw_circle(_s_x, _ctrl_y+60, 9, false);
        draw_set_color(slider_drag==2 ? make_color_rgb(130,255,130) : make_color_rgb(60,200,60)); draw_circle(_s_x, _ctrl_y+60, 6, false);
        draw_set_color(c_white); draw_text(_mxo+155, _ctrl_y+52, "<"); draw_text(_mxo+485, _ctrl_y+52, ">");
        draw_text(_mxo+520, _ctrl_y+52, string(round(modal_speed)));

        // Quality radio buttons
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+93, "Quality:");
        var _q_labels = ["Normal", "Monotone", "Sung"]; var _q_vals = [0, 2, 4];
        for (var e = 0; e < 3; e++) {
            var _ex = _mxo+195+(e*105);
            var _q_sel = (modal_quality == _q_vals[e]);
            var _q_hov = (point_distance(_mx, _my, _ex, _ctrl_y+108) < 16);
            draw_set_color(_q_sel ? c_lime : (_q_hov ? make_color_rgb(180, 220, 180) : make_color_rgb(90, 90, 90)));
            draw_circle(_ex, _ctrl_y+108, 10, true);
            if (_q_sel) { draw_set_color(make_color_rgb(30, 80, 30)); draw_circle(_ex, _ctrl_y+108, 6, false); }
            draw_set_halign(fa_center);
            draw_set_color(_q_sel ? c_white : (_q_hov ? c_white : make_color_rgb(180, 180, 180)));
            draw_text(_ex, _ctrl_y+121, _q_labels[e]);
            draw_set_halign(fa_left);
        }

        // Effort radio buttons
        draw_set_color(c_white); draw_text(_mxo+50, _ctrl_y+143, "Effort:");
        var _s_labels = ["Normal", "Breathy", "Whispered"];
        _s_hov = false;
        for (var s = 0; s < 3; s++) {
            var _sx = _mxo+195+(s*105);
            var _s_sel = (modal_effort == s);
            _s_hov = (point_distance(_mx, _my, _sx, _ctrl_y+158) < 16);
            draw_set_color(_s_sel ? c_lime : (_s_hov ? make_color_rgb(180, 220, 180) : make_color_rgb(90, 90, 90)));
            draw_circle(_sx, _ctrl_y+158, 10, true);
            if (_s_sel) { draw_set_color(make_color_rgb(30, 80, 30)); draw_circle(_sx, _ctrl_y+158, 6, false); }
            draw_set_halign(fa_center);
            draw_set_color(_s_sel ? c_white : (_s_hov ? c_white : make_color_rgb(180, 180, 180)));
            draw_text(_sx, _ctrl_y+171, _s_labels[s]);
            draw_set_halign(fa_left);
        }

        // Glottal source slider (-1 to 5)
        var _g_y = _ctrl_y + 193;
        var _g_val = clamp(modal_glottal, -1, 5);
        var _g_x = _mxo+180 + ((_g_val + 1) / 6.0) * 300;
        var _g_hov = (_mx > _mxo+180 && _mx < _mxo+480 && _my > _g_y-5 && _my < _g_y+25);
        draw_set_color(c_white); draw_text(_mxo+50, _g_y+2, "Timbre:");
        draw_set_color(make_color_rgb(130, 130, 130)); draw_text(_mxo+50, _g_y+16, "(5 recommended)");
        draw_set_color(_g_hov || slider_drag==3 ? make_color_rgb(90,55,10) : make_color_rgb(60,38,8));
        draw_rectangle(_mxo+180, _g_y+2, _mxo+480, _g_y+18, false);
        if (_g_val >= 0) {
            draw_set_color(slider_drag==3 ? make_color_rgb(255,175,70) : make_color_rgb(210,135,40));
            draw_rectangle(_mxo+180, _g_y+2, _g_x, _g_y+18, false);
        }
        draw_set_color(c_white); draw_circle(_g_x, _g_y+10, 9, false);
        draw_set_color(slider_drag==3 ? make_color_rgb(255,175,70) : make_color_rgb(210,135,40));
        draw_circle(_g_x, _g_y+10, 6, false);
        draw_set_color(c_white);
        draw_text(_mxo+155, _g_y+2, "<"); draw_text(_mxo+485, _g_y+2, ">");
        draw_text(_mxo+520, _g_y+2, (_g_val == -1) ? "off" : string(_g_val));
    }

    // --- Bottom Buttons ---
    var _btn_y = _myo + _mh - 60;

    // Revert (Only for local block edits)
    if (modal_is_local_edit) {
        var _rv_hov = (_mx > _mxo + 30 && _mx < _mxo + 150 && _my > _btn_y && _my < _btn_y + 40);
        draw_set_color(_rv_hov ? make_color_rgb(185, 130, 18) : make_color_rgb(140, 95, 10));
        draw_roundrect_ext(_mxo + 30, _btn_y, _mxo + 150, _btn_y + 40, 7, 7, false);
        draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_mxo + 90, _btn_y + 10, "REVERT"); draw_set_halign(fa_left);
    }

    // Test
    var _tx = modal_is_local_edit ? _mxo + 165 : _mxo + 30;
    var _t_hov = (_mx > _tx && _mx < _tx + 120 && _my > _btn_y && _my < _btn_y + 40);
    draw_set_color(_t_hov ? make_color_rgb(18, 72, 162) : make_color_rgb(12, 50, 140));
    draw_roundrect_ext(_tx, _btn_y, _tx + 120, _btn_y + 40, 7, 7, false);
    draw_set_color(_t_hov ? c_white : make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_tx, _btn_y, _tx + 120, _btn_y + 40, 7, 7, true);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_tx + 60, _btn_y + 10, "TEST"); draw_set_halign(fa_left);

    // Export Config (debug)
    if (SHOW_VOICE_CFG && !modal_is_local_edit) {
        var _ex_hov = (_mx > _mxo+_mw-430 && _mx < _mxo+_mw-295 && _my > _btn_y && _my < _btn_y+40);
        draw_set_color(_ex_hov ? make_color_rgb(100, 40, 160) : make_color_rgb(72, 25, 120));
        draw_roundrect_ext(_mxo+_mw-430, _btn_y, _mxo+_mw-295, _btn_y+40, 7, 7, false);
        draw_set_color(c_white);
        draw_set_halign(fa_center); draw_text(_mxo+_mw-362, _btn_y+10, "SAVE CONFIG"); draw_set_halign(fa_left);
    }

    // Save
    var _s_hov = (_mx > _mxo+_mw-280 && _mx < _mxo+_mw-150 && _my > _btn_y && _my < _btn_y+40);
    draw_set_color(_s_hov ? make_color_rgb(22, 110, 32) : make_color_rgb(14, 75, 22));
    draw_roundrect_ext(_mxo+_mw-280, _btn_y, _mxo+_mw-150, _btn_y+40, 7, 7, false);
    draw_set_color(_s_hov ? c_white : make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_mxo+_mw-280, _btn_y, _mxo+_mw-150, _btn_y+40, 7, 7, true);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_mxo+_mw-215, _btn_y+10, "SAVE"); draw_set_halign(fa_left);
    // Cancel
    var _c_hov = (_mx > _mxo+_mw-140 && _mx < _mxo+_mw-30 && _my > _btn_y && _my < _btn_y+40);
    draw_set_color(_c_hov ? make_color_rgb(200,40,40) : make_color_rgb(148,22,22));
    draw_roundrect_ext(_mxo+_mw-140, _btn_y, _mxo+_mw-30, _btn_y+40, 7, 7, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_mxo+_mw-85, _btn_y+10, "CANCEL"); draw_set_halign(fa_left);

}

if (scene_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _mw = 700; var _mh = 490; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    draw_set_color(make_color_rgb(14, 48, 20)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 12, 12, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+52, 12, 12, false);
    draw_rectangle(_mxo, _myo+32, _mxo+_mw, _myo+52, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 12, 12, true);
    draw_set_color(c_black); draw_text(_mxo+20, _myo+18, "SELECT SCENE");

    // Search box
    var _srx = _mxo+20; var _sry = _myo+58; var _srw = 300; var _srh = 28;
    draw_set_color(scene_modal_search_focused ? make_color_rgb(14,55,20) : make_color_rgb(8,30,12));
    draw_roundrect_ext(_srx, _sry, _srx+_srw, _sry+_srh, 4, 4, false);
    draw_set_color(scene_modal_search_focused ? make_color_rgb(148,200,30) : make_color_rgb(60,100,25));
    draw_roundrect_ext(_srx, _sry, _srx+_srw, _sry+_srh, 4, 4, true);
    var _sq_d = scene_modal_search;
    var _show_caret = scene_modal_search_focused && ((scene_modal_caret_timer div 30) % 2 == 0);
    if (_sq_d == "" && !scene_modal_search_focused) {
        draw_set_color(make_color_rgb(80,110,50));
        draw_text(_srx+7, _sry+6, "Search scenes...");
    } else {
        draw_set_color(c_white);
        draw_text(_srx+7, _sry+6, string_upper(_sq_d) + (_show_caret ? "|" : ""));
    }
    if (_sq_d != "") {
        var _cx_hov = (_mx > _srx+_srw-22 && _mx < _srx+_srw && _my > _sry && _my < _sry+_srh);
        draw_set_color(_cx_hov ? c_white : make_color_rgb(180,80,80));
        draw_text(_srx+_srw-16, _sry+6, "X");
    }

    if (array_length(all_scenes) == 0) {
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        draw_text_ext(_mxo + _mw/2, _myo + _mh/2 - 40, "No background scenes found!\n\nIf you just packed the scenes, please reload this project in GameMaker IDE (File -> Recent Projects -> Hollywood High) so the IDE registers the new 'scenes.pack' included file.", 22, 600);
        draw_set_halign(fa_left);
    }

    var _max_h = 315; var _list_h = array_length(scene_modal_filtered) * 40; var _lw = 300;
    var _hov_idx = -1;
    gpu_set_scissor(_mxo+20, _myo+95, _lw, _max_h);
    for (var i = 0; i < array_length(scene_modal_filtered); i++) {
        var _by = _myo + 95 + (i * 40) + scene_modal_scroll_y;
        if (_by + 35 < _myo+95 || _by > _myo+95+_max_h) continue;
        var _hov = (_mx > _mxo+20 && _mx < _mxo+20+_lw && _my > _by && _my < _by+35);
        if (_hov) _hov_idx = i;
        draw_set_color(_hov ? make_color_rgb(18, 65, 25) : make_color_rgb(10, 40, 15));
        draw_roundrect_ext(_mxo+20, _by, _mxo+20+_lw, _by+35, 5, 5, false);
        draw_set_color(c_white); draw_text(_mxo+30, _by+8, scene_modal_filtered[i].name);
    }
    gpu_set_scissor(0,0,1280,960);

    // Scrollbar for Scene Modal
    if (_list_h > _max_h) {
        var _bar_h = max(20, (_max_h / _list_h) * _max_h);
        var _sb_max_top = (_myo+95) + _max_h - _bar_h;
        var _bar_y = clamp((_myo+95) + (-scene_modal_scroll_y / _list_h) * _max_h, _myo+95, _sb_max_top);
        var _bar_hov = (_mx >= _mxo+20+_lw+3 && _mx <= _mxo+20+_lw+17 && _my >= _bar_y && _my <= _bar_y + _bar_h);
        draw_set_color(make_color_rgb(8, 30, 12));
        draw_rectangle(_mxo+20+_lw+5, _myo+95, _mxo+20+_lw+15, _myo+95+_max_h, false); // Track
        draw_set_color(scene_sb_dragging ? make_color_rgb(215, 232, 85) : (_bar_hov ? make_color_rgb(185, 205, 60) : make_color_rgb(148, 162, 35)));
        draw_rectangle(_mxo+20+_lw+5, _bar_y, _mxo+20+_lw+15, _bar_y + _bar_h, false); // Bar
    }

    var _pre_x = _mxo + 350; var _pre_y = _myo + 95; var _pre_w = 320; var _pre_h = 315;
    draw_set_color(c_black); draw_rectangle(_pre_x, _pre_y, _pre_x+_pre_w, _pre_y+_pre_h, false);
    if (_hov_idx != -1) {
        var _iname = scene_modal_filtered[_hov_idx].internal_name;
        var _spr = get_scene_sprite(_iname);
        var _mask_spr = get_scene_sprite(_iname + "_mask");
        if (_spr != -1) {
            var _sc = min(_pre_w/sprite_get_width(_spr), _pre_h/sprite_get_height(_spr)) * 0.9;
            var _dx = _pre_x + (_pre_w - sprite_get_width(_spr)*_sc)/2;
            var _dy = _pre_y + (_pre_h - sprite_get_height(_spr)*_sc)/2;
            draw_sprite_ext(_spr, 0, _dx, _dy, _sc, _sc, 0, c_white, 1);
            if (_mask_spr != -1) draw_sprite_ext(_mask_spr, 0, _dx, _dy, _sc, _sc, 0, c_white, 1);
        }
    }
	var _c_y = _myo + _mh - 50;
	var _can_hov = (_mx > _mxo+20 && _mx < _mxo+_mw-20 && _my > _c_y && _my < _c_y+35);
	draw_set_color(_can_hov ? make_color_rgb(200,40,40) : make_color_rgb(148,22,22));
	draw_roundrect_ext(_mxo+20, _c_y, _mxo+_mw-20, _c_y+35, 7, 7, false);
	draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_mxo+_mw/2, _c_y+8, "CANCEL"); draw_set_halign(fa_left);
}

if (action_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _mw = 900; var _mh = 660; var _mxo = (1280-_mw)/2; var _myo = (800-_mh)/2;
    draw_set_color(make_color_rgb(14, 48, 20)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 12, 12, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+52, 12, 12, false);
    draw_rectangle(_mxo, _myo+32, _mxo+_mw, _myo+52, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_mxo, _myo, _mxo+_mw, _myo+_mh, 12, 12, true);
    draw_set_color(c_black); draw_text(_mxo+20, _myo+18, "ADD ACTION");
    draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_mxo + 20, _myo + 58, "GENERAL ACTIONS");
    draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_mxo + 20, _myo + 78, _mxo + 250, _myo + 78);

    var _char_header_drawn = false;
    for (var i = 0; i < array_length(all_actions); i++) {
        var _is_gen = (all_actions[i].category == "general");
        var _ng = 0; var _nc = 0;
        for (var _k = 0; _k < i; _k++) { if (all_actions[_k].category == "general") _ng++; else _nc++; }
        var _by = _myo + 85 + (_ng * 45) + (!_is_gen ? 50 : 0) + (_nc * 45);

        if (!_is_gen && !_char_header_drawn) {
            _char_header_drawn = true;
            draw_set_color(make_color_rgb(196, 213, 20));
            draw_text(_mxo + 20, _by - 38, "CHARACTER ACTIONS");
            draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_mxo + 20, _by - 14, _mxo + 250, _by - 14);
        }

        var _disabled = false;
        if (action_modal_edit_mode) {
            if (action_modal_selected_idx != i) _disabled = true;
        } else if (!_is_gen) {
            var _aname_i = all_actions[i].name;
            if (selected_character_index == 0) _disabled = true;
            else if (_aname_i == "stand up") {
                if (!action_modal_char_is_knocked_down) _disabled = true;
            } else if (_aname_i == "reform") {
                if (!action_modal_char_is_decapitated) _disabled = true;
            } else if (!action_modal_char_onstage) _disabled = true;
            else if (_aname_i == "special animation" && action_modal_char_is_injured) _disabled = true;
        }

        var _hov = (!_disabled && _mx > _mxo+20 && _mx < _mxo+250 && _my > _by && _my < _by+40);
        var _col = make_color_rgb(10, 40, 15);
        if (_disabled) _col = make_color_rgb(8, 28, 10);
        else if (action_modal_selected_idx == i) _col = make_color_rgb(16, 55, 148);
        else if (_hov) _col = make_color_rgb(18, 68, 24);

        draw_set_color(_col);
        draw_roundrect_ext(_mxo+20, _by, _mxo+250, _by+40, 5, 5, false);
        if (action_modal_selected_idx == i) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_mxo+20, _by, _mxo+250, _by+40, 5, 5, true); }
        draw_set_color(_disabled ? make_color_rgb(70,90,72) : c_white); draw_text(_mxo+30, _by+10, string_upper(all_actions[i].name));
    }

    // OK / Cancel Buttons
    var _can_proceed = true;
    if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "play sfx") {
        if ((action_modal_sfx_folder_idx == -1 || action_modal_sfx_file_idx == -1) && action_modal_sfx_search_sel == -1) _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "display title") {
        if (action_modal_title_text == "") _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "quake") {
        // always valid — general action
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "jitter") {
        if (selected_character_index == 0 || !action_modal_char_onstage) _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "disappear") {
        if (selected_character_index == 0 || !action_modal_char_onstage) _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "injure") {
        if (selected_character_index == 0) _can_proceed = false;
        else if (!action_modal_edit_mode && action_modal_injure_style == "knock_down" && action_modal_char_is_knocked_down) _can_proceed = false;
        else if (!action_modal_edit_mode && action_modal_injure_style == "decapitate" && action_modal_char_is_decapitated) _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "stand up") {
        if (selected_character_index == 0 || !action_modal_char_is_knocked_down) _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "reform") {
        if (selected_character_index == 0 || !action_modal_char_is_decapitated) _can_proceed = false;
    } else if (action_modal_selected_idx != -1 && all_actions[action_modal_selected_idx].name == "special animation") {
        _can_proceed = (action_modal_selected_anim_idx >= 0 && action_modal_char_onstage && !action_modal_char_is_injured && selected_character_index > 0);
    } else if (action_modal_selected_idx == -1) {
        _can_proceed = false;
    }

    var _ok_locked = (action_modal_locked && _can_proceed);
    var _ok_hov = (_ok_locked && _mx > _mxo+_mw-280 && _mx < _mxo+_mw-150 && _my > _myo+_mh-50 && _my < _myo+_mh-15);
    draw_set_color(_ok_locked ? (_ok_hov ? make_color_rgb(22,110,32) : make_color_rgb(14,75,22)) : make_color_rgb(28,45,30));
    draw_roundrect_ext(_mxo+_mw-280, _myo+_mh-50, _mxo+_mw-150, _myo+_mh-15, 7, 7, false);
    draw_set_color(_ok_locked ? make_color_rgb(196,213,20) : make_color_rgb(55,78,57));
    draw_roundrect_ext(_mxo+_mw-280, _myo+_mh-50, _mxo+_mw-150, _myo+_mh-15, 7, 7, true);
    draw_set_color(_ok_locked ? c_white : make_color_rgb(80,100,82));
    draw_set_halign(fa_center); draw_text(_mxo+_mw-215, _myo+_mh-42, "OK"); draw_set_halign(fa_left);

    var _can_hov = (_mx > _mxo+_mw-130 && _mx < _mxo+_mw-20 && _my > _myo+_mh-50 && _my < _myo+_mh-15);
    draw_set_color(_can_hov ? make_color_rgb(200,40,40) : make_color_rgb(148,22,22));
    draw_roundrect_ext(_mxo+_mw-130, _myo+_mh-50, _mxo+_mw-20, _myo+_mh-15, 7, 7, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_mxo+_mw-75, _myo+_mh-42, "CANCEL"); draw_set_halign(fa_left);

    // Description Box
    draw_set_color(make_color_rgb(10, 38, 14));
    draw_roundrect_ext(_mxo+280, _myo+60, _mxo+880, _myo+510, 8, 8, false);
    if (action_modal_selected_idx != -1) {
        draw_set_color(c_white);
        draw_text_ext(_mxo+290, _myo+70, all_actions[action_modal_selected_idx].desc, 25, 580);
        
        if (all_actions[action_modal_selected_idx].name == "wait") {
            var _wx = _mxo + 320; var _wy = _myo + 170;
            var _sw = 400;
            
            draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_wx, _wy, "PARAMETERS");
            draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_wx, _wy + 25, _wx + _sw + 80, _wy + 25);
            draw_set_color(c_white);
            draw_text(_wx, _wy + 40, "Wait Duration:");
            
            var _ty = _wy + 80;

            // Arrows
            var _l_hov = (_mx > _wx - 5 && _mx < _wx + 25 && _my > _ty - 10 && _my < _ty + 35);
            draw_set_color(_l_hov ? c_aqua : c_gray);
            draw_text(_wx, _ty, "<");

            var _r_hov = (_mx > _wx + _sw + 35 && _mx < _wx + _sw + 75 && _my > _ty - 10 && _my < _ty + 35);
            draw_set_color(_r_hov ? c_aqua : c_gray);
            draw_text(_wx + _sw + 50, _ty, ">");

            // Slider Track
            draw_set_color(make_color_rgb(15, 55, 20));
            draw_rectangle(_wx + 30, _ty + 8, _wx + 30 + _sw, _ty + 13, false);

            // Slider Handle
            var _perc = (action_modal_wait_duration - 0.1) / 9.9;
            var _hx = _wx + 30 + (_perc * _sw);
            draw_set_color(make_color_rgb(196, 213, 20)); draw_rectangle(_wx + 30, _ty + 8, _hx, _ty + 13, false);
            draw_set_color(make_color_rgb(196, 213, 20));
            draw_circle(_hx, _ty + 10, 8, false);
            
            draw_set_color(c_white);
            draw_text(_wx + 20, _wy + 115, string(action_modal_wait_duration) + " seconds");
        } else if (all_actions[action_modal_selected_idx].name == "play sfx") {
            var _wx = _mxo + 300; var _wy = _myo + 130;

            draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_wx, _wy, "PARAMETERS");
            draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_wx, _wy + 25, _wx + 560, _wy + 25);

            var _fx = _mxo + 280;
            var _lx = _mxo + 550;

            // SEARCH BOX — sits between separator and the category/file columns
            var _srx = _fx + 10; var _sry = _wy + 30; var _srw = 560; var _srh = 24;
            var _sr_focused = action_modal_sfx_search_focused;
            draw_set_color(_sr_focused ? make_color_rgb(40, 40, 70) : make_color_rgb(20, 20, 30));
            draw_rectangle(_srx, _sry, _srx + _srw, _sry + _srh, false);
            draw_set_color(_sr_focused ? c_yellow : c_ltgray);
            draw_rectangle(_srx, _sry, _srx + _srw, _sry + _srh, true);
            var _sq = action_modal_sfx_search;
            var _sfx_show_caret = _sr_focused && ((action_modal_sfx_caret_timer div 30) % 2 == 0);
            if (_sq == "" && !_sr_focused) {
                draw_set_color(make_color_rgb(80, 80, 100));
                draw_text(_srx + 6, _sry + 4, "Search...");
            } else {
                draw_set_color(c_white);
                draw_text(_srx + 6, _sry + 4, string_upper(_sq) + (_sfx_show_caret ? "|" : ""));
            }
            if (_sq != "") {
                var _cx_hov = (_mx > _srx + _srw - 22 && _mx < _srx + _srw && _my > _sry && _my < _sry + _srh);
                draw_set_color(_cx_hov ? c_white : make_color_rgb(180, 80, 80));
                draw_text(_srx + _srw - 18, _sry + 4, "X");
            }

            // ACTOR FOLDERS CHECKBOX
            var _chk_x = _fx + 10; var _chk_y = _wy + 60;
            var _chk_hov = (_mx > _chk_x && _mx < _chk_x + 200 && _my > _chk_y && _my < _chk_y + 18);
            draw_set_color(_chk_hov ? make_color_rgb(38, 55, 22) : make_color_rgb(18, 30, 10));
            draw_rectangle(_chk_x, _chk_y + 2, _chk_x + 13, _chk_y + 15, false);
            draw_set_color(action_modal_sfx_show_actors ? make_color_rgb(148, 162, 35) : make_color_rgb(70, 85, 30));
            draw_rectangle(_chk_x, _chk_y + 2, _chk_x + 13, _chk_y + 15, true);
            if (action_modal_sfx_show_actors) {
                draw_set_color(c_yellow);
                draw_set_halign(fa_center);
                draw_text(_chk_x + 7, _chk_y + 2, "X");
                draw_set_halign(fa_left);
            }
            draw_set_color(_chk_hov ? c_white : make_color_rgb(160, 175, 100));
            draw_text(_chk_x + 18, _chk_y + 1, "SHOW ACTOR FOLDERS");

            var _boxy = _wy + 100; var _boxh = 185;
            var _boxy2 = _boxy + _boxh;

            if (action_modal_sfx_search != "") {
                // SEARCH RESULTS — full-width single list
                var _rc = array_length(action_modal_sfx_search_results);
                draw_set_color(c_white); draw_text(_fx + 10, _boxy - 20, "Results (" + string(_rc) + "):");
                draw_set_color(make_color_rgb(10, 38, 14)); draw_roundrect_ext(_fx + 10, _boxy, _fx + 580, _boxy2, 5, 5, false);
                gpu_set_scissor(_fx + 10, _boxy, 570, _boxh);
                for (var f = 0; f < _rc; f++) {
                    var _res = action_modal_sfx_search_results[f];
                    var _rby = _boxy + (f * 28) - action_modal_sfx_search_scroll_y;
                    if (_rby + 28 > _boxy2 || _rby < _boxy) continue;
                    var _is_sel = (action_modal_sfx_search_sel == f);
                    var _r_hov = (_mx > _fx + 10 && _mx < _fx + 578 && _my > _rby && _my < _rby + 28 && _my > _boxy && _my < _boxy2);
                    draw_set_color(_is_sel ? make_color_rgb(16, 55, 148) : (_r_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 38, 14)));
                    draw_rectangle(_fx + 10, _rby, _fx + 580, _rby + 28, false);
                    draw_set_color(make_color_rgb(120, 120, 160)); draw_text(_fx + 15, _rby + 6, string_upper(_res.folder) + " /");
                    draw_set_color(_is_sel ? c_white : c_ltgray);
                    draw_text(_fx + 15 + string_width(string_upper(_res.folder) + " /") + 6, _rby + 6, string_replace(string_upper(_res.file), ".WAV", ""));
                }
                gpu_set_scissor(0, 0, 1280, 960);
                // Scrollbar
                var _rtot = _rc * 28;
                if (_rtot > _boxh) {
                    _sb_x = _fx + 572;
                    draw_set_color(make_color_rgb(8, 28, 12)); draw_rectangle(_sb_x, _boxy, _sb_x + 8, _boxy2, false);
                    var _bar_h = (_boxh / _rtot) * _boxh;
                    var _bar_y = _boxy + (action_modal_sfx_search_scroll_y / _rtot) * _boxh;
                    draw_set_color(make_color_rgb(148, 162, 35)); draw_rectangle(_sb_x, _bar_y, _sb_x + 8, _bar_y + _bar_h, false);
                }
            } else {
                // FOLDERS
                draw_set_color(c_white); draw_text(_fx + 10, _boxy - 20, "Category:");
                draw_set_color(make_color_rgb(10, 38, 14)); draw_roundrect_ext(_fx + 10, _boxy, _fx + 240, _boxy2, 5, 5, false);
                gpu_set_scissor(_fx + 10, _boxy, 230, _boxh);
                for (var f = 0; f < array_length(action_modal_sfx_folders); f++) {
                    var _fby = _boxy + (f * 30) - action_modal_sfx_scroll_y;
                    if (_fby + 30 > _boxy2 || _fby < _boxy) continue;
                    var _is_sel = (action_modal_sfx_folder_idx == f);
                    var _f_hov = (!action_modal_sfx_dragging_folder && _mx > _fx + 10 && _mx < _fx + 230 && _my > _fby && _my < _fby + 30 && _my > _boxy && _my < _boxy2);
                    draw_set_color(_is_sel ? make_color_rgb(16, 55, 148) : (_f_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 38, 14)));
                    draw_rectangle(_fx + 10, _fby, _fx + 240, _fby + 30, false);
                    draw_set_color(_is_sel ? c_white : c_ltgray); draw_text(_fx + 15, _fby + 5, string_upper(action_modal_sfx_folders[f]));
                }
                gpu_set_scissor(0, 0, 1280, 960);

                // FILES
                draw_set_color(c_white); draw_text(_lx - 10, _boxy - 20, "Sound Effect:");
                draw_set_color(make_color_rgb(10, 38, 14)); draw_roundrect_ext(_lx - 10, _boxy, _lx + 310, _boxy2, 5, 5, false);
                gpu_set_scissor(_lx - 10, _boxy, 320, _boxh);
                if (action_modal_sfx_folder_idx != -1) {
                    for (var f = 0; f < array_length(action_modal_sfx_files); f++) {
                        var _fby = _boxy + (f * 30) - action_modal_sfx_files_scroll_y;
                        if (_fby + 30 > _boxy2 || _fby < _boxy) continue;
                        var _is_sel = (action_modal_sfx_file_idx == f);
                        var _f_hov = (!action_modal_sfx_dragging_file && _mx > _lx - 10 && _mx < _lx + 300 && _my > _fby && _my < _fby + 30 && _my > _boxy && _my < _boxy2);
                        draw_set_color(_is_sel ? make_color_rgb(16, 55, 148) : (_f_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 38, 14)));
                        draw_rectangle(_lx - 10, _fby, _lx + 310, _fby + 30, false);
                        draw_set_color(_is_sel ? c_white : c_ltgray); draw_text(_lx - 5, _fby + 5, string_replace(string_upper(action_modal_sfx_files[f]), ".WAV", ""));
                    }
                }
                gpu_set_scissor(0, 0, 1280, 960);

                // FOLDER SCROLLBAR
                var _ftot = array_length(action_modal_sfx_folders) * 30;
                if (_ftot > _boxh) {
                    _sb_x = _fx + 240 - 8;
                    draw_set_color(make_color_rgb(8, 28, 12)); draw_rectangle(_sb_x, _boxy, _sb_x + 8, _boxy2, false);
                    var _bar_h = (_boxh / _ftot) * _boxh;
                    var _bar_y = _boxy + (action_modal_sfx_scroll_y / _ftot) * _boxh;
                    draw_set_color(make_color_rgb(148, 162, 35)); draw_rectangle(_sb_x, _bar_y, _sb_x + 8, _bar_y + _bar_h, false);
                }

                // FILE SCROLLBAR
                var _ltot = array_length(action_modal_sfx_files) * 30;
                if (_ltot > _boxh) {
                    _sb_x = _lx + 310 - 8;
                    draw_set_color(make_color_rgb(8, 28, 12)); draw_rectangle(_sb_x, _boxy, _sb_x + 8, _boxy2, false);
                    var _bar_h = (_boxh / _ltot) * _boxh;
                    var _bar_y = _boxy + (action_modal_sfx_files_scroll_y / _ltot) * _boxh;
                    draw_set_color(make_color_rgb(148, 162, 35)); draw_rectangle(_sb_x, _bar_y, _sb_x + 8, _bar_y + _bar_h, false);
                }
            }

            // TEST / STOP BUTTON
            var _tx = _mxo + _mw - 150; var _ty = _myo + _mh - 120;
            var _sfx_playing = (test_sfx_sound != -1 && audio_is_playing(test_sfx_sound));
            var _can_test = (action_modal_sfx_folder_idx != -1 && action_modal_sfx_file_idx != -1) || _sfx_playing;
            var _t_hov = (_can_test && _mx > _tx && _mx < _tx + 120 && _my > _ty && _my < _ty + 35);
            draw_set_color(_sfx_playing ? (_t_hov ? make_color_rgb(220, 80, 80) : make_color_rgb(160, 50, 50))
                                        : (_can_test ? (_t_hov ? make_color_rgb(100, 100, 200) : make_color_rgb(60, 60, 150)) : make_color_rgb(40, 40, 50)));
            draw_rectangle(_tx, _ty, _tx + 120, _ty + 35, false);
            draw_set_color(_can_test ? c_white : c_gray);
            draw_text(_tx + (_sfx_playing ? 30 : 35), _ty + 8, _sfx_playing ? "STOP" : "TEST");
        } else if (all_actions[action_modal_selected_idx].name == "display title") {
            var _wx = _mxo + 300; var _wy = _myo + 100;
            
            draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_wx, _wy, "PARAMETERS");
            draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_wx, _wy + 25, _wx + 560, _wy + 25);
            
            draw_set_color(c_white); draw_text(_wx, _wy + 40, "Title Text (Max 100 chars, Auto-wraps):");
            draw_set_color(make_color_rgb(228, 242, 232)); draw_roundrect_ext(_wx, _wy + 65, _wx + 560, _wy + 150, 5, 5, false);
            gpu_set_scissor(_wx, _wy + 65, 561, 86);
            var _ttx = _wx + 10; var _tty = _wy + 75;
            if (action_modal_title_sel_start != action_modal_title_sel_end) {
                var _tss = min(action_modal_title_sel_start, action_modal_title_sel_end);
                var _tse = max(action_modal_title_sel_start, action_modal_title_sel_end);
                var _tsp = get_text_pos(action_modal_title_text, _tss, 540, 25);
                var _tep = get_text_pos(action_modal_title_text, _tse, 540, 25);
                draw_set_color(make_color_rgb(100, 160, 220)); draw_set_alpha(0.45);
                if (_tsp.y == _tep.y) {
                    draw_rectangle(_ttx + _tsp.x, _tty + _tsp.y, _ttx + _tep.x, _tty + _tsp.y + 22, false);
                } else {
                    draw_rectangle(_ttx + _tsp.x, _tty + _tsp.y, _ttx + 540, _tty + _tsp.y + 22, false);
                    if (_tep.y > _tsp.y + 25) draw_rectangle(_ttx, _tty + _tsp.y + 25, _ttx + 540, _tty + _tep.y, false);
                    draw_rectangle(_ttx, _tty + _tep.y, _ttx + _tep.x, _tty + _tep.y + 22, false);
                }
                draw_set_alpha(1.0);
            }
            draw_set_color(c_black); draw_text_ext(_ttx, _tty, action_modal_title_text, 25, 540);
            if (cursor_visible) {
                var _tcp = get_text_pos(action_modal_title_text, action_modal_title_caret, 540, 25);
                draw_set_color(c_black);
                draw_line(_ttx + _tcp.x, _tty + _tcp.y, _ttx + _tcp.x, _tty + _tcp.y + 22);
            }
            gpu_set_scissor(0, 0, 1280, 960);
            
            draw_set_color(c_white); draw_text(_wx, _wy + 170, "Duration:");
            var _sw = 300; var _sx = _wx + 100; var _sy = _wy + 170;
            
            var _l_hov = (_mx > _sx - 35 && _mx < _sx - 5 && _my > _sy - 10 && _my < _sy + 35);
            draw_set_color(_l_hov ? c_aqua : c_gray); draw_text(_sx - 35, _sy, "<");
            var _r_hov = (_mx > _sx + _sw + 5 && _mx < _sx + _sw + 45 && _my > _sy - 10 && _my < _sy + 35);
            draw_set_color(_r_hov ? c_aqua : c_gray); draw_text(_sx + _sw + 20, _sy, ">");

            draw_set_color(make_color_rgb(15, 55, 20)); draw_rectangle(_sx, _sy + 8, _sx + _sw, _sy + 13, false);
            var _perc = (action_modal_wait_duration - 0.1) / 9.9;
            draw_set_color(make_color_rgb(196, 213, 20)); draw_rectangle(_sx, _sy + 8, _sx + (_perc * _sw), _sy + 13, false);
            draw_set_color(make_color_rgb(196, 213, 20)); draw_circle(_sx + (_perc * _sw), _sy + 10, 8, false);
            draw_set_color(c_white); draw_text(_sx + _sw + 50, _sy, string(action_modal_wait_duration) + "s");

            var draw_dropdown = function(dx, dy, label, val_idx, opts_array, is_open) {
                draw_set_color(c_white); draw_text(dx, dy, label);
                var _bx = dx + 60; var _bw = 200;
                draw_set_color(is_open ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 42, 16));
                draw_roundrect_ext(_bx, dy, _bx + _bw, dy + 25, 4, 4, false);
                draw_set_color(make_color_rgb(196, 213, 20)); draw_roundrect_ext(_bx, dy, _bx + _bw, dy + 25, 4, 4, true);
                draw_set_color(c_white); draw_text(_bx + 10, dy + 3, opts_array[val_idx]);
                draw_text(_bx + _bw - 20, dy + 3, "v");
                
                if (is_open) {
                    draw_set_color(make_color_rgb(10, 40, 15)); draw_rectangle(_bx, dy + 25, _bx + _bw, dy + 25 + (array_length(opts_array) * 30), false);
                    draw_set_color(make_color_rgb(196, 213, 20)); draw_rectangle(_bx, dy + 25, _bx + _bw, dy + 25 + (array_length(opts_array) * 30), true);
                    for (var d = 0; d < array_length(opts_array); d++) {
                        var _dhov = (mouse_x > _bx && mouse_x < _bx + _bw && mouse_y > dy + 25 + (d * 30) && mouse_y < dy + 25 + ((d+1) * 30));
                        if (_dhov) { draw_set_color(make_color_rgb(20, 72, 28)); draw_rectangle(_bx, dy + 25 + (d * 30), _bx + _bw, dy + 25 + ((d+1) * 30), false); }
                        draw_set_color(d == val_idx ? make_color_rgb(220, 238, 88) : c_white);
                        draw_text(_bx + 10, dy + 30 + (d * 30), opts_array[d]);
                    }
                }
            };
            
            if (action_modal_dropdown_open != "align") draw_dropdown(_wx, _wy + 230, "Align:", action_modal_title_align, action_modal_title_align_opts, false);
            if (action_modal_dropdown_open != "size") draw_dropdown(_wx + 290, _wy + 230, "Size:", action_modal_title_size, action_modal_title_size_opts, false);
            if (action_modal_dropdown_open != "font") draw_dropdown(_wx, _wy + 280, "Font:", action_modal_title_font, action_modal_title_font_opts, false);
            if (action_modal_dropdown_open != "color") draw_dropdown(_wx + 290, _wy + 280, "Color:", action_modal_title_color, action_modal_title_color_opts, false);
            
            if (action_modal_dropdown_open == "align") draw_dropdown(_wx, _wy + 230, "Align:", action_modal_title_align, action_modal_title_align_opts, true);
            if (action_modal_dropdown_open == "size") draw_dropdown(_wx + 290, _wy + 230, "Size:", action_modal_title_size, action_modal_title_size_opts, true);
            if (action_modal_dropdown_open == "font") draw_dropdown(_wx, _wy + 280, "Font:", action_modal_title_font, action_modal_title_font_opts, true);
            if (action_modal_dropdown_open == "color") draw_dropdown(_wx + 290, _wy + 280, "Color:", action_modal_title_color, action_modal_title_color_opts, true);
        } else if (all_actions[action_modal_selected_idx].name == "jitter") {
            var _jx = _mxo+290; var _jsw = 360;
            // Direction
            draw_set_color(make_color_rgb(196,213,20)); draw_text(_jx, _myo+120, "DIRECTION");
            draw_set_color(make_color_rgb(100,120,40)); draw_line(_jx, _myo+138, _jx+_jsw, _myo+138);
            var _jdirs = ["horizontal","vertical","omni"]; var _jdlbls = ["HORIZONTAL","VERTICAL","OMNI"];
            for (var _jdi = 0; _jdi < 3; _jdi++) {
                var _jdx = _jx + _jdi * 124; var _jdsel = (action_modal_jitter_direction == _jdirs[_jdi]);
                var _jdhov = (_mx > _jdx && _mx < _jdx+118 && _my > _myo+146 && _my < _myo+184);
                draw_set_color(_jdsel ? make_color_rgb(16,55,148) : (_jdhov ? make_color_rgb(18,65,24) : make_color_rgb(10,40,15)));
                draw_roundrect_ext(_jdx, _myo+146, _jdx+118, _myo+184, 5,5,false);
                if (_jdsel) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_jdx, _myo+146, _jdx+118, _myo+184, 5,5,true); }
                draw_set_color(_jdsel ? c_white : make_color_rgb(178,210,182));
                draw_set_halign(fa_center); draw_text(_jdx+59, _myo+157, _jdlbls[_jdi]); draw_set_halign(fa_left);
            }
            // Intensity slider
            draw_set_color(make_color_rgb(196,213,20)); draw_text(_jx, _myo+202, "INTENSITY");
            draw_set_color(make_color_rgb(100,120,40)); draw_line(_jx, _myo+220, _jx+_jsw, _myo+220);
            draw_set_color(c_white); draw_text(_jx, _myo+234, "SUBTLE"); draw_text(_jx+_jsw-40, _myo+234, "VIOLENT");
            var _jity = _myo+260;
            draw_set_color(make_color_rgb(15,55,20)); draw_rectangle(_jx, _jity+4, _jx+_jsw, _jity+9, false);
            var _jipct = (action_modal_jitter_intensity-1)/6.0;
            var _jihx = _jx + _jipct*_jsw;
            draw_set_color(make_color_rgb(196,213,20)); draw_rectangle(_jx, _jity+4, _jihx, _jity+9, false);
            draw_circle(_jihx, _jity+6, 8, false);
            draw_set_color(c_white); draw_text(_jx, _myo+278, "Intensity: " + string(action_modal_jitter_intensity));
            // Duration slider
            draw_set_color(make_color_rgb(196,213,20)); draw_text(_jx, _myo+305, "DURATION");
            draw_set_color(make_color_rgb(100,120,40)); draw_line(_jx, _myo+323, _jx+_jsw, _myo+323);
            draw_set_color(c_white); draw_text(_jx, _myo+337, "0.2s"); draw_text(_jx+_jsw-16, _myo+337, "5s");
            var _jdry = _myo+363;
            draw_set_color(make_color_rgb(15,55,20)); draw_rectangle(_jx, _jdry+4, _jx+_jsw, _jdry+9, false);
            var _jdrpct = (action_modal_jitter_duration-0.2)/4.8;
            var _jdrhx = _jx + _jdrpct*_jsw;
            draw_set_color(make_color_rgb(196,213,20)); draw_rectangle(_jx, _jdry+4, _jdrhx, _jdry+9, false);
            draw_circle(_jdrhx, _jdry+6, 8, false);
            draw_set_color(c_white); draw_text(_jx, _myo+381, "Duration: " + string(round(action_modal_jitter_duration*10)/10) + " seconds");
            // Notices
            if (selected_character_index == 0) {
                draw_set_color(make_color_rgb(255,120,120)); draw_text(_jx, _myo+415, "Narrator cannot use character actions.");
            } else if (!action_modal_char_onstage) {
                draw_set_color(make_color_rgb(255,200,80)); draw_text(_jx, _myo+415, "Character is not currently on stage.");
            }
        } else if (all_actions[action_modal_selected_idx].name == "quake") {
            var _qx2 = _mxo+290; var _qsw = 360;
            // Direction
            draw_set_color(make_color_rgb(196,213,20)); draw_text(_qx2, _myo+120, "DIRECTION");
            draw_set_color(make_color_rgb(100,120,40)); draw_line(_qx2, _myo+138, _qx2+_qsw, _myo+138);
            var _qdirs = ["horizontal","vertical","omni"]; var _qdlbls = ["HORIZONTAL","VERTICAL","OMNI"];
            for (var _qdi = 0; _qdi < 3; _qdi++) {
                var _qdx = _qx2 + _qdi * 124; var _qdsel = (action_modal_quake_direction == _qdirs[_qdi]);
                var _qdhov = (_mx > _qdx && _mx < _qdx+118 && _my > _myo+146 && _my < _myo+184);
                draw_set_color(_qdsel ? make_color_rgb(16,55,148) : (_qdhov ? make_color_rgb(18,65,24) : make_color_rgb(10,40,15)));
                draw_roundrect_ext(_qdx, _myo+146, _qdx+118, _myo+184, 5,5,false);
                if (_qdsel) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_qdx, _myo+146, _qdx+118, _myo+184, 5,5,true); }
                draw_set_color(_qdsel ? c_white : make_color_rgb(178,210,182));
                draw_set_halign(fa_center); draw_text(_qdx+59, _myo+157, _qdlbls[_qdi]); draw_set_halign(fa_left);
            }
            // Intensity slider
            draw_set_color(make_color_rgb(196,213,20)); draw_text(_qx2, _myo+202, "INTENSITY");
            draw_set_color(make_color_rgb(100,120,40)); draw_line(_qx2, _myo+220, _qx2+_qsw, _myo+220);
            draw_set_color(c_white); draw_text(_qx2, _myo+234, "SUBTLE"); draw_text(_qx2+_qsw-40, _myo+234, "VIOLENT");
            var _qity = _myo+260;
            draw_set_color(make_color_rgb(15,55,20)); draw_rectangle(_qx2, _qity+4, _qx2+_qsw, _qity+9, false);
            var _qipct = (action_modal_quake_intensity-1)/6.0;
            var _qihx = _qx2 + _qipct*_qsw;
            draw_set_color(make_color_rgb(196,213,20)); draw_rectangle(_qx2, _qity+4, _qihx, _qity+9, false);
            draw_circle(_qihx, _qity+6, 8, false);
            draw_set_color(c_white); draw_text(_qx2, _myo+278, "Intensity: " + string(action_modal_quake_intensity));
            // Duration slider
            draw_set_color(make_color_rgb(196,213,20)); draw_text(_qx2, _myo+305, "DURATION");
            draw_set_color(make_color_rgb(100,120,40)); draw_line(_qx2, _myo+323, _qx2+_qsw, _myo+323);
            draw_set_color(c_white); draw_text(_qx2, _myo+337, "0.2s"); draw_text(_qx2+_qsw-16, _myo+337, "5s");
            var _qdry2 = _myo+363;
            draw_set_color(make_color_rgb(15,55,20)); draw_rectangle(_qx2, _qdry2+4, _qx2+_qsw, _qdry2+9, false);
            var _qdrpct = (action_modal_quake_duration-0.2)/4.8;
            var _qdrhx = _qx2 + _qdrpct*_qsw;
            draw_set_color(make_color_rgb(196,213,20)); draw_rectangle(_qx2, _qdry2+4, _qdrhx, _qdry2+9, false);
            draw_circle(_qdrhx, _qdry2+6, 8, false);
            draw_set_color(c_white); draw_text(_qx2, _myo+381, "Duration: " + string(round(action_modal_quake_duration*10)/10) + " seconds");
        } else if (all_actions[action_modal_selected_idx].name == "disappear") {
            var _disp_styles = ["pop", "eat dirt", "home planet", "disintegrate", "melt"];
            var _disp_labels = ["POP", "EAT DIRT", "HOME PLANET", "DISINTEGRATE", "MELT"];
            var _has_speed = (action_modal_disappear_style != "pop");

            // Style column
            draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_mxo+290, _myo+120, "STYLE");
            draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_mxo+290, _myo+138, _mxo+460, _myo+138);
            for (var _dsi = 0; _dsi < 5; _dsi++) {
                var _dsy = _myo + 148 + _dsi * 44;
                var _dssel = (action_modal_disappear_style == _disp_styles[_dsi]);
                var _dshov = (_mx > _mxo+290 && _mx < _mxo+460 && _my > _dsy && _my < _dsy+38);
                draw_set_color(_dssel ? make_color_rgb(16,55,148) : (_dshov ? make_color_rgb(18,65,24) : make_color_rgb(10,40,15)));
                draw_roundrect_ext(_mxo+290, _dsy, _mxo+460, _dsy+38, 5, 5, false);
                if (_dssel) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_mxo+290, _dsy, _mxo+460, _dsy+38, 5, 5, true); }
                draw_set_color(_dssel ? c_white : make_color_rgb(178,210,182));
                draw_set_halign(fa_center); draw_text(_mxo+375, _dsy+10, _disp_labels[_dsi]); draw_set_halign(fa_left);
            }

            // Speed column
            draw_set_color(_has_speed ? make_color_rgb(196, 213, 20) : make_color_rgb(70, 88, 30)); draw_text(_mxo+475, _myo+120, "SPEED");
            draw_set_color(_has_speed ? make_color_rgb(100, 120, 40) : make_color_rgb(35, 50, 15)); draw_line(_mxo+475, _myo+138, _mxo+660, _myo+138);
            for (var _spi = 0; _spi < 5; _spi++) {
                var _spy = _myo + 148 + _spi * 44;
                var _spsel = (_has_speed && action_modal_disappear_speed == _spi);
                var _sphov = (_has_speed && _mx > _mxo+475 && _mx < _mxo+660 && _my > _spy && _my < _spy+38);
                draw_set_color(_spsel ? make_color_rgb(16,55,148) : (_sphov ? make_color_rgb(18,65,24) : (_has_speed ? make_color_rgb(10,40,15) : make_color_rgb(8,25,10))));
                draw_roundrect_ext(_mxo+475, _spy, _mxo+660, _spy+38, 5, 5, false);
                if (_spsel) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_mxo+475, _spy, _mxo+660, _spy+38, 5, 5, true); }
                draw_set_color(_spsel ? c_white : (_has_speed ? make_color_rgb(178,210,182) : make_color_rgb(50,65,52)));
                draw_set_halign(fa_center); draw_text(_mxo+567, _spy+10, disappear_speed_labels[_spi]); draw_set_halign(fa_left);
            }

            // Disabled notices
            if (selected_character_index == 0) {
                draw_set_color(make_color_rgb(255,120,120)); draw_text(_mxo+290, _myo+415, "Narrator cannot use character actions.");
            } else if (!action_modal_char_onstage) {
                draw_set_color(make_color_rgb(255,200,80)); draw_text(_mxo+290, _myo+415, "Character is not currently on stage.");
            }
        } else if (all_actions[action_modal_selected_idx].name == "injure") {
            var _inj_styles = ["knock_down", "decapitate"];
            var _inj_labels = ["KNOCK DOWN", "DECAPITATE"];
            draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_mxo+290, _myo+158, "INJURY TYPE");
            draw_set_color(make_color_rgb(180, 100, 30)); draw_line(_mxo+290, _myo+176, _mxo+540, _myo+176);
            for (var _isi = 0; _isi < 2; _isi++) {
                var _isy = _myo + 184 + _isi * 46;
                var _issel = (action_modal_injure_style == _inj_styles[_isi]);
                var _ishov = (_mx > _mxo+290 && _mx < _mxo+540 && _my > _isy && _my < _isy+40);
                draw_set_color(_issel ? make_color_rgb(100, 55, 10) : (_ishov ? make_color_rgb(65, 38, 10) : make_color_rgb(38, 22, 8)));
                draw_roundrect_ext(_mxo+290, _isy, _mxo+540, _isy+40, 5, 5, false);
                if (_issel) { draw_set_color(make_color_rgb(200, 110, 30)); draw_roundrect_ext(_mxo+290, _isy, _mxo+540, _isy+40, 5, 5, true); }
                draw_set_color(_issel ? c_white : make_color_rgb(200, 160, 100));
                draw_set_halign(fa_center); draw_text(_mxo+415, _isy+11, _inj_labels[_isi]); draw_set_halign(fa_left);
            }
            if (action_modal_injure_style == "knock_down") {
                var _kd_labels = ["FALL FORWARDS", "FALL BACKWARDS"];
                var _kd_dirs   = ["forwards", "backwards"];
                draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_mxo+555, _myo+158, "DIRECTION");
                draw_set_color(make_color_rgb(180, 100, 30)); draw_line(_mxo+555, _myo+176, _mxo+745, _myo+176);
                for (var _kdi2 = 0; _kdi2 < 2; _kdi2++) {
                    var _kdy2 = _myo + 184 + _kdi2 * 46;
                    var _kdsel = (action_modal_knock_direction == _kd_dirs[_kdi2]);
                    var _kdhov = (_mx > _mxo+555 && _mx < _mxo+745 && _my > _kdy2 && _my < _kdy2+40);
                    draw_set_color(_kdsel ? make_color_rgb(100, 55, 10) : (_kdhov ? make_color_rgb(65, 38, 10) : make_color_rgb(38, 22, 8)));
                    draw_roundrect_ext(_mxo+555, _kdy2, _mxo+745, _kdy2+40, 5, 5, false);
                    if (_kdsel) { draw_set_color(make_color_rgb(200, 110, 30)); draw_roundrect_ext(_mxo+555, _kdy2, _mxo+745, _kdy2+40, 5, 5, true); }
                    draw_set_color(_kdsel ? c_white : make_color_rgb(200, 160, 100));
                    draw_set_halign(fa_center); draw_text(_mxo+650, _kdy2+11, _kd_labels[_kdi2]); draw_set_halign(fa_left);
                }
                var _ispd_labels = ["VERY SLOW", "SLOW", "NORMAL", "FAST", "VERY FAST"];
                draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_mxo+555, _myo+286, "FALL SPEED");
                draw_set_color(make_color_rgb(180, 100, 30)); draw_line(_mxo+555, _myo+304, _mxo+745, _myo+304);
                for (var _ispi = 0; _ispi < 5; _ispi++) {
                    var _ispy = _myo + 310 + _ispi * 36;
                    var _ispsel = (action_modal_injure_speed == _ispi);
                    var _isphov = (_mx > _mxo+555 && _mx < _mxo+745 && _my > _ispy && _my < _ispy+30);
                    draw_set_color(_ispsel ? make_color_rgb(100, 55, 10) : (_isphov ? make_color_rgb(65, 38, 10) : make_color_rgb(38, 22, 8)));
                    draw_roundrect_ext(_mxo+555, _ispy, _mxo+745, _ispy+30, 4, 4, false);
                    if (_ispsel) { draw_set_color(make_color_rgb(200, 110, 30)); draw_roundrect_ext(_mxo+555, _ispy, _mxo+745, _ispy+30, 4, 4, true); }
                    draw_set_color(_ispsel ? c_white : make_color_rgb(200, 160, 100));
                    draw_set_halign(fa_center); draw_text(_mxo+650, _ispy+7, _ispd_labels[_ispi]); draw_set_halign(fa_left);
                }
            } else if (action_modal_injure_style == "decapitate") {
                var _dm_labels = ["REMOVE HEAD", "REMOVE BODY"];
                var _dm_modes  = ["remove_head", "remove_body"];
                draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_mxo+555, _myo+158, "DECAP MODE");
                draw_set_color(make_color_rgb(180, 100, 30)); draw_line(_mxo+555, _myo+176, _mxo+745, _myo+176);
                for (var _dmi2 = 0; _dmi2 < 2; _dmi2++) {
                    var _dmy2 = _myo + 184 + _dmi2 * 46;
                    var _dmsel = (action_modal_decap_mode == _dm_modes[_dmi2]);
                    var _dmhov = (_mx > _mxo+555 && _mx < _mxo+745 && _my > _dmy2 && _my < _dmy2+40);
                    draw_set_color(_dmsel ? make_color_rgb(100, 55, 10) : (_dmhov ? make_color_rgb(65, 38, 10) : make_color_rgb(38, 22, 8)));
                    draw_roundrect_ext(_mxo+555, _dmy2, _mxo+745, _dmy2+40, 5, 5, false);
                    if (_dmsel) { draw_set_color(make_color_rgb(200, 110, 30)); draw_roundrect_ext(_mxo+555, _dmy2, _mxo+745, _dmy2+40, 5, 5, true); }
                    draw_set_color(_dmsel ? c_white : make_color_rgb(200, 160, 100));
                    draw_set_halign(fa_center); draw_text(_mxo+650, _dmy2+11, _dm_labels[_dmi2]); draw_set_halign(fa_left);
                }
            }
            if (selected_character_index == 0) {
                draw_set_color(make_color_rgb(255,120,120)); draw_text(_mxo+290, _myo+518, "Narrator cannot use character actions.");
            } else if (!action_modal_char_onstage) {
                draw_set_color(make_color_rgb(255,200,80)); draw_text(_mxo+290, _myo+518, "Character is not currently on stage.");
            } else if (!action_modal_edit_mode && action_modal_injure_style == "knock_down" && action_modal_char_is_knocked_down) {
                draw_set_color(make_color_rgb(255,200,80)); draw_text(_mxo+290, _myo+518, "Character is already knocked down.");
            } else if (!action_modal_edit_mode && action_modal_injure_style == "decapitate" && action_modal_char_is_decapitated) {
                draw_set_color(make_color_rgb(255,200,80)); draw_text(_mxo+290, _myo+518, "Character is already decapitated.");
            }
        } else if (all_actions[action_modal_selected_idx].name == "stand up") {
            draw_set_color(make_color_rgb(150, 210, 120));
            draw_text_ext(_mxo+290, _myo+160, "The character gets back on their feet.\nDecapitation state is not cleared.", 28, 560);
            if (action_modal_char_is_knocked_down) {
                var _su_spd_labels = ["VERY SLOW", "SLOW", "NORMAL", "FAST", "VERY FAST"];
                draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_mxo+290, _myo+236, "RISE SPEED");
                draw_set_color(make_color_rgb(150, 210, 120)); draw_line(_mxo+290, _myo+254, _mxo+540, _myo+254);
                for (var _susi = 0; _susi < 5; _susi++) {
                    var _susy = _myo + 260 + _susi * 36;
                    var _susel = (action_modal_standup_speed == _susi);
                    var _suhov = (_mx > _mxo+290 && _mx < _mxo+540 && _my > _susy && _my < _susy+30);
                    draw_set_color(_susel ? make_color_rgb(60, 120, 40) : (_suhov ? make_color_rgb(30, 80, 20) : make_color_rgb(18, 48, 12)));
                    draw_roundrect_ext(_mxo+290, _susy, _mxo+540, _susy+30, 4, 4, false);
                    if (_susel) { draw_set_color(make_color_rgb(150, 210, 120)); draw_roundrect_ext(_mxo+290, _susy, _mxo+540, _susy+30, 4, 4, true); }
                    draw_set_color(_susel ? c_black : make_color_rgb(130, 185, 100));
                    draw_set_halign(fa_center); draw_text(_mxo+415, _susy+8, _su_spd_labels[_susi]); draw_set_halign(fa_left);
                }
            }
            if (!action_modal_char_is_knocked_down) {
                draw_set_color(make_color_rgb(255,200,80)); draw_text(_mxo+290, _myo+450, "Character is not knocked down.");
            }
        } else if (all_actions[action_modal_selected_idx].name == "reform") {
            draw_set_color(make_color_rgb(150, 210, 120));
            draw_text_ext(_mxo+290, _myo+160, "The character's head (or body) rematerializes.\nKnocked-down state is not cleared.", 28, 560);
            if (!action_modal_char_is_decapitated) {
                draw_set_color(make_color_rgb(255,200,80)); draw_text(_mxo+290, _myo+450, "Character is not decapitated.");
            }
        } else if (all_actions[action_modal_selected_idx].name == "special animation") {
            var _sa_dr = canned_anim_get_data(selected_character_index);
            var _sa_on = (action_modal_char_onstage && !action_modal_char_is_injured && selected_character_index > 0);
            var _sa_rx = _mxo+290; var _sa_ry = _myo+115; var _sa_rh = 36; var _sa_rw = _mw-324;
            var _sa_lh = _mh - 185; var _sa_stp = _sa_rh + 6;
            var _sa_vis = floor(_sa_lh / _sa_stp);
            if (_sa_dr != undefined && array_length(_sa_dr) > 0) {
                var _sa_total = array_length(_sa_dr);
                var _sa_max = max(0, _sa_total - _sa_vis);
                var _sa_scr = clamp(action_modal_sa_scroll, 0, _sa_max);
                for (var _sai2 = 0; _sai2 < _sa_total; _sai2++) {
                    var _sby2 = _sa_ry + (_sai2 - _sa_scr) * _sa_stp;
                    if (_sby2 < _sa_ry || _sby2 + _sa_rh > _sa_ry + _sa_lh) continue;
                    var _sa_sel2 = (action_modal_selected_anim_idx == _sai2);
                    var _sa_hov2 = (_sa_on && _mx > _sa_rx && _mx < _sa_rx + _sa_rw && _my > _sby2 && _my < _sby2 + _sa_rh);
                    draw_set_color(_sa_sel2 ? make_color_rgb(16, 100, 55) : (_sa_hov2 ? make_color_rgb(14, 70, 35) : make_color_rgb(10, 40, 18)));
                    draw_roundrect_ext(_sa_rx, _sby2, _sa_rx + _sa_rw, _sby2 + _sa_rh, 5, 5, false);
                    if (_sa_sel2) { draw_set_color(make_color_rgb(80, 220, 130)); draw_roundrect_ext(_sa_rx, _sby2, _sa_rx + _sa_rw, _sby2 + _sa_rh, 5, 5, true); }
                    draw_set_color(_sa_on ? (_sa_sel2 ? c_white : make_color_rgb(150, 220, 170)) : make_color_rgb(60, 80, 62));
                    draw_text(_sa_rx + 12, _sby2 + 9, string_upper(_sa_dr[_sai2].name));
                }
                // Scrollbar
                if (_sa_max > 0) {
                    var _sbx_sa = _sa_rx + _sa_rw + 4;
                    draw_set_color(make_color_rgb(10, 35, 14));
                    draw_rectangle(_sbx_sa, _sa_ry, _sbx_sa + 10, _sa_ry + _sa_lh, false);
                    var _th_sa = max(20, _sa_lh * _sa_vis / _sa_total);
                    var _ty_sa = _sa_ry + (_sa_scr / _sa_max) * (_sa_lh - _th_sa);
                    draw_set_color(make_color_rgb(80, 180, 100));
                    draw_rectangle(_sbx_sa, _ty_sa, _sbx_sa + 10, _ty_sa + _th_sa, false);
                }
            } else {
                draw_set_color(make_color_rgb(180, 140, 60));
                draw_text(_sa_rx, _sa_ry, "No animations found for this character.");
            }
            if (!_sa_on) {
                draw_set_color(make_color_rgb(200, 160, 60));
                draw_text(_sa_rx, _myo + 460, action_modal_char_is_injured ? "Character is injured." : "Character is not on stage.");
            }
        }
    }
}


if (move_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _m_w = 400; var _m_h = 660;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    draw_set_color(make_color_rgb(14, 48, 20)); draw_roundrect_ext(_m_x, _m_y, _m_x+_m_w, _m_y+_m_h, 14, 14, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_m_x, _m_y, _m_x+_m_w, _m_y+52, 14, 14, false);
    draw_rectangle(_m_x, _m_y+32, _m_x+_m_w, _m_y+52, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_m_x, _m_y, _m_x+_m_w, _m_y+_m_h, 14, 14, true);
    draw_set_color(c_black); draw_text_transformed(_m_x + 20, _m_y + 13, "MOVEMENT PARAMETERS", 1.1, 1.1, 0);

    // Speed list
    for (var i = 0; i < array_length(move_speed_labels); i++) {
        var _by = _m_y + 80 + (i * 45);
        var _is_sel = (move_modal_temp_speed_index == i);
        var _hov = (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _by && _my < _by + 40);

        draw_set_color(_is_sel ? make_color_rgb(16, 55, 148) : (_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 40, 15)));
        draw_roundrect_ext(_m_x + 50, _by, _m_x + 350, _by + 40, 6, 6, false);
        if (_is_sel) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_m_x + 50, _by, _m_x + 350, _by + 40, 6, 6, true); }
        draw_set_color(_is_sel ? c_white : make_color_rgb(200, 220, 200));
        draw_set_halign(fa_center); draw_text(_m_x + 200, _by + 10, move_speed_labels[i]); draw_set_halign(fa_left);
    }

    // Moonwalk Toggle
    var _m_hov = (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _m_y + 316 && _my < _m_y + 340);
    draw_set_color(_m_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 40, 15));
    draw_roundrect_ext(_m_x + 50, _m_y + 314, _m_x + 350, _m_y + 340, 5, 5, false);
    draw_set_color(c_white); draw_circle(_m_x + 65, _m_y + 327, 9, true);
    if (move_modal_temp_moonwalk) { draw_set_color(make_color_rgb(196, 213, 20)); draw_circle(_m_x + 65, _m_y + 327, 6, false); }
    draw_set_color(c_white); draw_text(_m_x + 82, _m_y + 319, "ENABLE MOONWALK");

    // Trick section
    draw_set_color(make_color_rgb(196, 213, 20)); draw_text(_m_x + 50, _m_y + 356, "TRICK");
    draw_set_color(make_color_rgb(100, 120, 40)); draw_line(_m_x + 50, _m_y + 374, _m_x + 350, _m_y + 374);
    var _trick_labels = ["JUMP", "FRONT FLIP", "BACK FLIP"];
    var _trick_vals   = ["jump", "front flip", "back flip"];
    for (var _ti = 0; _ti < 3; _ti++) {
        var _ty = _m_y + 380 + _ti * 44;
        var _t_sel = (move_modal_temp_trick == _trick_vals[_ti]);
        var _t_hov = (_mx > _m_x + 50 && _mx < _m_x + 350 && _my > _ty && _my < _ty + 38);
        draw_set_color(_t_sel ? make_color_rgb(16, 55, 148) : (_t_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 40, 15)));
        draw_roundrect_ext(_m_x + 50, _ty, _m_x + 350, _ty + 38, 6, 6, false);
        if (_t_sel) { draw_set_color(make_color_rgb(196,213,20)); draw_roundrect_ext(_m_x + 50, _ty, _m_x + 350, _ty + 38, 6, 6, true); }
        draw_set_color(_t_sel ? c_white : make_color_rgb(200, 220, 200));
        draw_set_halign(fa_center); draw_text(_m_x + 200, _ty + 10, _trick_labels[_ti]); draw_set_halign(fa_left);
    }

    // Count section (1–5 repeats, only meaningful when a trick is selected)
    var _cnt_active = (move_modal_temp_trick != "none");
    draw_set_color(_cnt_active ? make_color_rgb(196, 213, 20) : make_color_rgb(80, 95, 30));
    draw_text(_m_x + 50, _m_y + 514, "COUNT");
    draw_set_color(_cnt_active ? make_color_rgb(100, 120, 40) : make_color_rgb(50, 65, 20));
    draw_line(_m_x + 50, _m_y + 532, _m_x + 350, _m_y + 532);
    var _cbw = 52; var _cbg = 8;
    for (var _ci = 0; _ci < 5; _ci++) {
        var _cx = _m_x + 50 + _ci * (_cbw + _cbg);
        var _cy = _m_y + 540;
        var _c_sel = (_cnt_active && move_modal_temp_trick_count == _ci + 1);
        var _c_hov = (_cnt_active && !_c_sel && _mx > _cx && _mx < _cx + _cbw && _my > _cy && _my < _cy + 34);
        draw_set_color(_c_sel ? make_color_rgb(16, 55, 148) : (_c_hov ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 30, 10)));
        draw_roundrect_ext(_cx, _cy, _cx + _cbw, _cy + 34, 5, 5, false);
        if (_c_sel) { draw_set_color(make_color_rgb(196, 213, 20)); draw_roundrect_ext(_cx, _cy, _cx + _cbw, _cy + 34, 5, 5, true); }
        draw_set_color(_c_sel ? c_white : (_cnt_active ? make_color_rgb(200, 220, 200) : make_color_rgb(80, 95, 60)));
        draw_set_halign(fa_center); draw_text(_cx + _cbw/2, _cy + 9, string(_ci + 1)); draw_set_halign(fa_left);
    }

    // OK Button
    var _ok_hov = (_mx > _m_x + 40 && _mx < _m_x + 180 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20);
    draw_set_color(_ok_hov ? make_color_rgb(22, 110, 32) : make_color_rgb(14, 75, 22));
    draw_roundrect_ext(_m_x + 40, _m_y + _m_h - 60, _m_x + 180, _m_y + _m_h - 20, 7, 7, false);
    draw_set_color(_ok_hov ? c_white : make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_m_x + 40, _m_y + _m_h - 60, _m_x + 180, _m_y + _m_h - 20, 7, 7, true);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_m_x + 110, _m_y + _m_h - 50, "OK"); draw_set_halign(fa_left);

    // Cancel Button
    var _can_hov = (_mx > _m_x + 220 && _mx < _m_x + 360 && _my > _m_y + _m_h - 60 && _my < _m_y + _m_h - 20);
    draw_set_color(_can_hov ? make_color_rgb(200, 40, 40) : make_color_rgb(148, 22, 22));
    draw_roundrect_ext(_m_x + 220, _m_y + _m_h - 60, _m_x + 360, _m_y + _m_h - 20, 7, 7, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_m_x + 290, _m_y + _m_h - 50, "CANCEL"); draw_set_halign(fa_left);
}

if (pose_expr_modal_open) {
    draw_set_color(c_black); draw_set_alpha(0.7); draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
    var _m_w = 1060; var _m_h = 520;
    var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;
    draw_set_color(make_color_rgb(14, 48, 20));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 14, 14, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + 30, 14, 14, false);
    draw_rectangle(_m_x, _m_y + 14, _m_x + _m_w, _m_y + 30, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 14, 14, true);
    draw_set_color(c_black); draw_text(_m_x + 18, _m_y + 8, "POSE / EXPRESSION");

    // ── POSE LIST ──
    for (var i = 1; i <= 4; i++) {
        var _by = _m_y + 38 + (i - 1) * 58;
        var _hov_p = (_mx > _m_x + 12 && _mx < _m_x + 208 && _my > _by && _my < _by + 50);
        var _locked_p = (pose_modal_locked_pose == i);
        draw_set_color(_locked_p ? make_color_rgb(16, 55, 148) : (_hov_p ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 40, 15)));
        draw_roundrect_ext(_m_x + 12, _by, _m_x + 208, _by + 50, 5, 5, false);
        if (_locked_p) { draw_set_color(make_color_rgb(196, 213, 20)); draw_roundrect_ext(_m_x + 12, _by, _m_x + 208, _by + 50, 5, 5, true); }
        draw_set_color(_locked_p ? c_white : c_ltgray);
        var _plbl = get_pose_label(selected_character_index, i);
        var _plbl_max_w = 178;
        var _plbl_sc = min(1.0, _plbl_max_w / max(1, string_width(_plbl)));
        gpu_set_texfilter(true);
        draw_text_transformed(_m_x + 22, _by + 16, _plbl, _plbl_sc, 1, 0);
        gpu_set_texfilter(false);
    }

    // ── EXPRESSION GRID (4 cols × 5 rows) ──
    var _cols_ep = 4; var _col_w_ep = 118; var _row_h_ep = 44;
    var _gx_ep = _m_x + 228; var _gy_ep = _m_y + 38;
    for (var e = 1; e <= 20; e++) {
        var _col = (e - 1) % _cols_ep; var _row = floor((e - 1) / _cols_ep);
        var _ex = _gx_ep + _col * _col_w_ep; var _ey = _gy_ep + _row * _row_h_ep;
        var _hov_e = (_mx > _ex + 2 && _mx < _ex + _col_w_ep - 2 && _my > _ey + 2 && _my < _ey + _row_h_ep - 2);
        var _locked_e = (expression_modal_locked_expr == e);
        draw_set_color(_locked_e ? make_color_rgb(16, 55, 148) : (_hov_e ? make_color_rgb(18, 65, 24) : make_color_rgb(10, 40, 15)));
        draw_roundrect_ext(_ex + 2, _ey + 2, _ex + _col_w_ep - 2, _ey + _row_h_ep - 2, 4, 4, false);
        if (_locked_e) { draw_set_color(make_color_rgb(196, 213, 20)); draw_roundrect_ext(_ex + 2, _ey + 2, _ex + _col_w_ep - 2, _ey + _row_h_ep - 2, 4, 4, true); }
        draw_set_color(_locked_e ? c_white : c_ltgray);
        draw_set_halign(fa_center); draw_text(_ex + _col_w_ep / 2, _ey + _row_h_ep / 2 - 8, mood_names[e - 1]); draw_set_halign(fa_left);
    }

    // ── PREVIEW (full body) ──
    var _pre_x = _m_x + 706; var _pre_y = _m_y + 14;
    var _pre_w = 340; var _pre_h = 460;
    draw_set_color(make_color_rgb(8, 30, 12));
    draw_roundrect_ext(_pre_x, _pre_y, _pre_x + _pre_w, _pre_y + _pre_h, 8, 8, false);
    draw_set_color(make_color_rgb(100, 120, 40));
    draw_roundrect_ext(_pre_x, _pre_y, _pre_x + _pre_w, _pre_y + _pre_h, 8, 8, true);
    if (selected_character_index != -1) {
        var _prev_pose = (pose_modal_temp_pose != -1) ? pose_modal_temp_pose : 1;
        var _prev_expr = (expression_modal_temp_expr != -1) ? expression_modal_temp_expr : 1;
        var _aface = char_facings[selected_character_index];
        for (var pa = 0; pa < array_length(preview_actors); pa++) {
            if (preview_actors[pa].char_index == selected_character_index) {
                _aface = variable_struct_exists(preview_actors[pa], "facing") ? preview_actors[pa].facing : _aface; break;
            }
        }
        var _layers = get_composite_character_sprite(selected_character_index, _prev_pose, _prev_expr, _aface);
        if (_layers[0].spr != -1) {
            var _csw = sprite_get_width(_layers[0].spr); var _csh = sprite_get_height(_layers[0].spr);
            var _min_dy = 0; var _max_dy_end = _csh;
            for (var _pli = 1; _pli < 4; _pli++) {
                if (_layers[_pli].spr != -1) { _min_dy = min(_min_dy, _layers[_pli].dy); _max_dy_end = max(_max_dy_end, _layers[_pli].dy + sprite_get_height(_layers[_pli].spr)); }
            }
            var _total_h_pm = _max_dy_end - _min_dy;
            var _sc = min((_pre_h - 20) / max(1, _total_h_pm), (_pre_w - 20) / max(1, _csw), 3.5);
            var _draw_x = _pre_x + (_pre_w - _csw * _sc) / 2;
            var _draw_y = _pre_y + 10 - _min_dy * _sc;
            draw_composite_character_ext(_layers, _draw_x, _draw_y, _sc, 1, c_white, false);
        }
    }

    // ── APPLY / CANCEL ──
    var _can_apply = (pose_modal_locked_pose != -1 && expression_modal_locked_expr != -1);
    var _ap_x = _m_x + 228; var _btn_y_pe = _m_y + _m_h - 52; var _btn_w_pe = 210; var _btn_h_pe = 40;
    var _ap_hov = (_can_apply && _mx > _ap_x && _mx < _ap_x + _btn_w_pe && _my > _btn_y_pe && _my < _btn_y_pe + _btn_h_pe);
    draw_set_color(_can_apply ? (_ap_hov ? make_color_rgb(22, 110, 32) : make_color_rgb(14, 75, 22)) : make_color_rgb(28, 45, 30));
    draw_roundrect_ext(_ap_x, _btn_y_pe, _ap_x + _btn_w_pe, _btn_y_pe + _btn_h_pe, 7, 7, false);
    draw_set_color(_can_apply ? make_color_rgb(196, 213, 20) : make_color_rgb(55, 78, 57));
    draw_roundrect_ext(_ap_x, _btn_y_pe, _ap_x + _btn_w_pe, _btn_y_pe + _btn_h_pe, 7, 7, true);
    draw_set_color(_can_apply ? c_white : make_color_rgb(80, 100, 82));
    draw_set_halign(fa_center); draw_text(_ap_x + _btn_w_pe / 2, _btn_y_pe + 11, "APPLY"); draw_set_halign(fa_left);
    var _cx_pe = _ap_x + _btn_w_pe + 14;
    var _can_hov = (_mx > _cx_pe && _mx < _cx_pe + _btn_w_pe && _my > _btn_y_pe && _my < _btn_y_pe + _btn_h_pe);
    draw_set_color(_can_hov ? make_color_rgb(200, 40, 40) : make_color_rgb(148, 22, 22));
    draw_roundrect_ext(_cx_pe, _btn_y_pe, _cx_pe + _btn_w_pe, _btn_y_pe + _btn_h_pe, 7, 7, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_cx_pe + _btn_w_pe / 2, _btn_y_pe + 11, "CANCEL"); draw_set_halign(fa_left);
}

// ── ANIMATION EDITOR MODAL ──
if (anim_editor_open) {
    var _data = canned_anim_get_data(anim_editor_char_idx);
    if (_data != undefined) {
        var _m_w = 1060; var _m_h = 620;
        var _m_x = (1280 - _m_w) / 2; var _m_y = (800 - _m_h) / 2;

        draw_set_color(c_black); draw_set_alpha(0.78);
        draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
        draw_set_color(make_color_rgb(10, 36, 16));
        draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 8, 8, false);
        draw_set_color(make_color_rgb(40, 140, 70));
        draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 8, 8, true);

        // Title + close
        draw_set_color(anim_editor_dirty ? make_color_rgb(255, 200, 60) : c_white); draw_set_halign(fa_left);
        var _cname = characters[anim_editor_char_idx].name;
        draw_text(_m_x + 14, _m_y + 14, "ANIMATIONS — " + _cname + (anim_editor_dirty ? "  *" : ""));
        draw_set_color(make_color_rgb(200, 80, 80));
        draw_roundrect_ext(_m_x + _m_w - 50, _m_y + 10, _m_x + _m_w - 10, _m_y + 40, 4, 4, false);
        draw_set_color(c_white); draw_set_halign(fa_center);
        draw_text(_m_x + _m_w - 30, _m_y + 17, "X"); draw_set_halign(fa_left);

        // Controls
        var _playing_label = anim_editor_playing ? "PAUSE" : "PLAY";
        draw_set_color(anim_editor_playing ? make_color_rgb(200, 120, 20) : make_color_rgb(20, 140, 60));
        draw_roundrect_ext(_m_x + 230, _m_y + 20, _m_x + 330, _m_y + 48, 4, 4, false);
        draw_set_color(c_white); draw_set_halign(fa_center);
        draw_text((_m_x + 230 + _m_x + 330) / 2, _m_y + 27, _playing_label);
        draw_set_color(make_color_rgb(40, 90, 130));
        draw_roundrect_ext(_m_x + 340, _m_y + 20, _m_x + 390, _m_y + 48, 4, 4, false);
        draw_roundrect_ext(_m_x + 400, _m_y + 20, _m_x + 450, _m_y + 48, 4, 4, false);
        draw_set_color(c_white);
        draw_text((_m_x + 340 + _m_x + 390) / 2, _m_y + 27, "<");
        draw_text((_m_x + 400 + _m_x + 450) / 2, _m_y + 27, ">");
        // Save button
        var _save_hov = (_mx > _m_x + 460 && _mx < _m_x + 560 && _my > _m_y + 20 && _my < _m_y + 48);
        draw_set_color(anim_editor_dirty ? ((_save_hov) ? make_color_rgb(180, 140, 20) : make_color_rgb(130, 100, 14)) : make_color_rgb(30, 55, 32));
        draw_roundrect_ext(_m_x + 460, _m_y + 20, _m_x + 560, _m_y + 48, 4, 4, false);
        draw_set_color(anim_editor_dirty ? c_white : make_color_rgb(60, 90, 62));
        draw_text((_m_x + 460 + _m_x + 560) / 2, _m_y + 27, "SAVE");
        // Flip mode toggle
        var _flip_hov = (_mx > _m_x + 572 && _mx < _m_x + 642 && _my > _m_y + 20 && _my < _m_y + 48);
        draw_set_color(anim_editor_flipped_mode ? make_color_rgb(40, 110, 190) : (_flip_hov ? make_color_rgb(30, 60, 90) : make_color_rgb(18, 38, 58)));
        draw_roundrect_ext(_m_x + 572, _m_y + 20, _m_x + 642, _m_y + 48, 4, 4, false);
        if (anim_editor_flipped_mode) { draw_set_color(make_color_rgb(120, 190, 255)); draw_roundrect_ext(_m_x + 572, _m_y + 20, _m_x + 642, _m_y + 48, 4, 4, true); }
        draw_set_color(anim_editor_flipped_mode ? c_white : make_color_rgb(80, 120, 160));
        draw_text((_m_x + 572 + _m_x + 642) / 2, _m_y + 27, "FLIP");
        draw_set_halign(fa_left);

        // Fit mode toggle
        var _fit_hov = (_mx > _m_x + 652 && _mx < _m_x + 722 && _my > _m_y + 20 && _my < _m_y + 48);
        draw_set_color(anim_editor_fit_mode ? make_color_rgb(110, 40, 190) : (_fit_hov ? make_color_rgb(60, 30, 90) : make_color_rgb(38, 18, 58)));
        draw_roundrect_ext(_m_x + 652, _m_y + 20, _m_x + 722, _m_y + 48, 4, 4, false);
        if (anim_editor_fit_mode) { draw_set_color(make_color_rgb(190, 120, 255)); draw_roundrect_ext(_m_x + 652, _m_y + 20, _m_x + 722, _m_y + 48, 4, 4, true); }
        draw_set_color(anim_editor_fit_mode ? c_white : make_color_rgb(120, 80, 160));
        draw_set_halign(fa_center);
        draw_text((_m_x + 652 + _m_x + 722) / 2, _m_y + 27, "FIT");
        draw_set_halign(fa_left);

        // Grid snap toggle
        var _grid_hov = (_mx > _m_x + 732 && _mx < _m_x + 802 && _my > _m_y + 20 && _my < _m_y + 48);
        draw_set_color(anim_editor_grid_snap ? make_color_rgb(40, 110, 190) : (_grid_hov ? make_color_rgb(30, 60, 90) : make_color_rgb(18, 38, 58)));
        draw_roundrect_ext(_m_x + 732, _m_y + 20, _m_x + 802, _m_y + 48, 4, 4, false);
        if (anim_editor_grid_snap) { draw_set_color(make_color_rgb(120, 190, 255)); draw_roundrect_ext(_m_x + 732, _m_y + 20, _m_x + 802, _m_y + 48, 4, 4, true); }
        draw_set_color(anim_editor_grid_snap ? c_white : make_color_rgb(80, 120, 160));
        draw_set_halign(fa_center);
        draw_text((_m_x + 732 + _m_x + 802) / 2, _m_y + 27, "GRID");
        draw_set_halign(fa_left);


        // Animation list (left panel)
        draw_set_color(make_color_rgb(8, 28, 12));
        draw_roundrect_ext(_m_x + 10, _m_y + 55, _m_x + 225, _m_y + _m_h - 10, 4, 4, false);
        for (var _ai = 0; _ai < array_length(_data); _ai++) {
            var _anim_entry = _data[_ai];
            var _ly = _m_y + 60 + _ai * 30;
            var _is_sel = (_ai == anim_editor_anim_idx);
            draw_set_color(_is_sel ? make_color_rgb(20, 120, 55) : make_color_rgb(14, 50, 22));
            draw_roundrect_ext(_m_x + 12, _ly, _m_x + 222, _ly + 26, 3, 3, false);
            draw_set_color(_is_sel ? c_white : c_ltgray);
            draw_text(_m_x + 18, _ly + 5, _anim_entry.name);
        }
        // +ANIM button
        var _add_anim_y = _m_y + 60 + array_length(_data) * 30;
        _add_hov = (_mx > _m_x + 12 && _mx < _m_x + 222 && _my > _add_anim_y && _my < _add_anim_y + 26);
        draw_set_color(_add_hov ? make_color_rgb(20, 80, 40) : make_color_rgb(12, 44, 20));
        draw_roundrect_ext(_m_x + 12, _add_anim_y, _m_x + 222, _add_anim_y + 26, 3, 3, false);
        draw_set_color(make_color_rgb(60, 140, 80)); draw_set_halign(fa_center);
        draw_text((_m_x + 12 + _m_x + 222) / 2, _add_anim_y + 5, "+ NEW ANIM");
        draw_set_halign(fa_left);

        // Frame preview (right panel)
        var _cur_anim = (array_length(_data) > 0) ? _data[clamp(anim_editor_anim_idx, 0, array_length(_data) - 1)] : undefined;
        var _frames   = (_cur_anim != undefined) ? _cur_anim.frames : [];
        var _preview_x = _m_x + 235; var _preview_y = _m_y + 55;
        var _preview_w = _m_w - 245; var _preview_h = _m_h - 100;

        // Preview column: left 40% of the panel; info column: right 60% starting at _info_x
        var _info_x     = _preview_x + floor(_preview_w * 0.40);
        _col_w      = _preview_x + _preview_w - _info_x - 8; // usable width for info buttons
        var _prev_col_w = _info_x - _preview_x - 4;              // usable pixel width for the character

        // Current frame sprite — composite with feet if assigned
        var _cf = (_frames != undefined && anim_editor_frame_idx < array_length(_frames)) ? _frames[anim_editor_frame_idx] : undefined;
        if (_cf != undefined && _cf.type == "sprite") {
            var _fspr_name = _cf.sprite;
            if (anim_editor_flipped_mode) {
                _fspr_name = (variable_struct_exists(_cf, "sprite_flipped") && _cf.sprite_flipped != "")
                             ? _cf.sprite_flipped : canned_anim_flipped_name(_cf.sprite);
            }
            var _fspr = canned_anim_load_sprite(anim_editor_char_idx, _fspr_name);

            // Resolve feet sprite (animation-level, respects flip mode)
            var _feet_key_prev = anim_editor_flipped_mode ? "feet_sprite_flipped" : "feet_sprite";
            var _feet_name_prev = (_cur_anim != undefined && variable_struct_exists(_cur_anim, _feet_key_prev)) ? _cur_anim[$ _feet_key_prev] : "";
            if (_feet_name_prev == "" && anim_editor_flipped_mode && _cur_anim != undefined) {
                var _fn0 = variable_struct_exists(_cur_anim, "feet_sprite") ? _cur_anim.feet_sprite : "";
                if (_fn0 != "") _feet_name_prev = canned_anim_flipped_name(_fn0);
            }
            var _feet_spr_prev = (_feet_name_prev != "") ? canned_anim_load_sprite(anim_editor_char_idx, _feet_name_prev) : -1;
            var _draw_feet_prev = (_feet_spr_prev != -1);
            var _cl_off_prev = anim_editor_flipped_mode
                ? (variable_struct_exists(_cf, "composite_legs_flipped") ? !_cf.composite_legs_flipped
                   : (variable_struct_exists(_cf, "composite_legs") && !_cf.composite_legs))
                : (variable_struct_exists(_cf, "composite_legs") && !_cf.composite_legs);
            if (_cl_off_prev) { _draw_feet_prev = false; }

            if (_fspr != -1) {
                var _fw = sprite_get_width(_fspr); var _fh = sprite_get_height(_fspr);
                // Available draw area: _prev_col_w wide, (_preview_h - 10) tall, with a small margin
                var _avail_w = _prev_col_w - 8;
                var _avail_h = _preview_h - 20;
                var _center_x = _preview_x + _prev_col_w * 0.5;
                var _floor_y  = _preview_y + _avail_h + 6;

                if (_feet_spr_prev != -1) {
                    // Composite: feet on bottom, body on top — use same math as theater runtime
                    var _fsw2 = sprite_get_width(_feet_spr_prev); var _fsh2 = sprite_get_height(_feet_spr_prev);
                    var _bdy_key = anim_editor_flipped_mode ? "body_dy_flipped" : "body_dy";
                    var _bdx_key = anim_editor_flipped_mode ? "body_dx_flipped" : "body_dx";
                    var _anim_bdy  = (_cur_anim != undefined && variable_struct_exists(_cur_anim, _bdy_key)) ? _cur_anim[$ _bdy_key] : 0;
                    var _anim_bdx  = (_cur_anim != undefined && variable_struct_exists(_cur_anim, _bdx_key)) ? _cur_anim[$ _bdx_key] : 0;
                    var _frame_fdy = (anim_editor_flipped_mode && variable_struct_exists(_cf, "frame_dy_flipped")) ? _cf.frame_dy_flipped
                                   : (variable_struct_exists(_cf, "frame_dy") ? _cf.frame_dy : 0);
                    var _frame_fdx = (anim_editor_flipped_mode && variable_struct_exists(_cf, "frame_dx_flipped")) ? _cf.frame_dx_flipped
                                   : (variable_struct_exists(_cf, "frame_dx") ? _cf.frame_dx : 0);

                    // Offset from offsets.json (same as runtime)
                    var _c_prev = characters[anim_editor_char_idx];
                    var _nm_prev = variable_struct_exists(_c_prev, "sprite_name") ? _c_prev.sprite_name : _c_prev.name;
                    var _od_prev = ds_map_exists(char_offsets_cache, _nm_prev) ? char_offsets_cache[? _nm_prev] : undefined;
                    var _body_ok_prev = string_replace(_fspr_name, ".png", "");
                    var _feet_ok_prev = string_replace(_feet_name_prev, ".png", "");
                    var _off_bdx = 0;
                    var _off_bdy = 0;
                    if (_od_prev != undefined && variable_struct_exists(_od_prev, _body_ok_prev) && variable_struct_exists(_od_prev, _feet_ok_prev)) {
                        _off_bdx = _od_prev[$ _body_ok_prev][0] - _od_prev[$ _feet_ok_prev][0];
                        _off_bdy = _od_prev[$ _body_ok_prev][1] - _od_prev[$ _feet_ok_prev][1];
                    }

                    // Body sits at (-body_h) relative to feet top, plus offsets
                    // Virtual total height = feet_h + any body above the feet top
                    var _body_dy_px = -_fh + _frame_fdy + _anim_bdy; // dy of body relative to feet top (negative = body starts above)
                    var _virtual_top = min(0, _body_dy_px);           // topmost pixel relative to feet top
                    var _total_h = _fsh2 - _virtual_top;              // feet_h + overhang above feet top
                    var _max_w   = max(_fw, _fsw2);
                    var _fsc2 = min(_avail_h / _total_h, _avail_w / _max_w);
                    if (anim_editor_fit_mode) _fsc2 = 1.5;

                    var _feet_draw_x = _center_x - (_fsw2 * _fsc2 * 0.5);
                    var _feet_draw_y = _floor_y  - _fsh2 * _fsc2;
                    var _body_draw_x = _feet_draw_x + (_off_bdx + _frame_fdx + _anim_bdx) * _fsc2;
                    var _body_draw_y = _feet_draw_y + _body_dy_px * _fsc2;
                    var _cl_off_body = anim_editor_flipped_mode
                        ? (variable_struct_exists(_cf, "composite_legs_flipped") ? !_cf.composite_legs_flipped
                           : (variable_struct_exists(_cf, "composite_legs") && !_cf.composite_legs))
                        : (variable_struct_exists(_cf, "composite_legs") && !_cf.composite_legs);
                    if (_cl_off_body) {
                        _body_draw_x = _feet_draw_x + (_off_bdx + _frame_fdx + _anim_bdx) * _fsc2;
                        _body_dy_px = _fsh2 - _fh + _frame_fdy + _anim_bdy;
                        _body_draw_y = _feet_draw_y + _body_dy_px * _fsc2;
                    }
                    var _zsc2 = _fsc2 * anim_editor_zoom;
                    var _zpx2 = (_feet_draw_x - _center_x) * anim_editor_zoom + _center_x + anim_editor_pan_x;
                    var _zpy2 = (_feet_draw_y - _floor_y)  * anim_editor_zoom + _floor_y  + anim_editor_pan_y;
                    var _zbpx = (_body_draw_x - _center_x) * anim_editor_zoom + _center_x + anim_editor_pan_x;
                    var _zbpy = (_body_draw_y - _floor_y)  * anim_editor_zoom + _floor_y  + anim_editor_pan_y;

                    // Draw grid if enabled
                    if (anim_editor_grid_snap) {
                        draw_set_color(make_color_rgb(60, 100, 60)); draw_set_alpha(0.15);
                        for (var _gx = _preview_x; _gx < _preview_x + _prev_col_w; _gx += 16) {
                            draw_line(_gx, _preview_y, _gx, _preview_y + _preview_h);
                        }
                        for (var _gy = _preview_y; _gy < _preview_y + _preview_h; _gy += 16) {
                            draw_line(_preview_x, _gy, _preview_x + _prev_col_w, _gy);
                        }
                        draw_set_alpha(1.0);
                    }
                    if (_draw_feet_prev) {
                        draw_sprite_ext(_feet_spr_prev, 0, _zpx2, _zpy2, _zsc2, _zsc2, 0, c_white, 1);
                    }
                    draw_sprite_ext(_fspr,          0, _zbpx, _zbpy, _zsc2, _zsc2, 0, c_white, 1);
                    // Faint seam line at feet top
                    if (_draw_feet_prev) {
                        draw_set_color(make_color_rgb(50, 130, 50)); draw_set_alpha(0.3);
                        draw_line(_zpx2, _zpy2, _zpx2 + _fsw2 * _zsc2, _zpy2);
                        draw_set_alpha(1.0);
                    }
                } else {
                    var _fsc = min(_avail_h / _fh, _avail_w / _fw);
                    if (anim_editor_fit_mode) _fsc = 1.5;
                    var _fdx = _center_x - (_fw * _fsc * 0.5);
                    var _fdy = _floor_y  - _fh * _fsc;
                    var _zsc  = _fsc * anim_editor_zoom;
                    var _zfdx = (_fdx - _center_x) * anim_editor_zoom + _center_x + anim_editor_pan_x;
                    var _zfdy = (_fdy - _floor_y)  * anim_editor_zoom + _floor_y  + anim_editor_pan_y;

                    // Draw grid if enabled
                    if (anim_editor_grid_snap) {
                        draw_set_color(make_color_rgb(60, 100, 60)); draw_set_alpha(0.15);
                        for (var _gx = _preview_x; _gx < _preview_x + _prev_col_w; _gx += 16) {
                            draw_line(_gx, _preview_y, _gx, _preview_y + _preview_h);
                        }
                        for (var _gy = _preview_y; _gy < _preview_y + _preview_h; _gy += 16) {
                            draw_line(_preview_x, _gy, _preview_x + _prev_col_w, _gy);
                        }
                        draw_set_alpha(1.0);
                    }

                    draw_sprite_ext(_fspr, 0, _zfdx, _zfdy, _zsc, _zsc, 0, c_white, 1);
                }
            }
        }

        // Frame info + edit controls
        var _sprite_count = 0;
        for (var _fi2 = 0; _fi2 < array_length(_frames); _fi2++) {
            if (_frames[_fi2].type == "sprite") _sprite_count++;
        }
        var _edit_frame = (anim_editor_selected_frame >= 0 && anim_editor_selected_frame < array_length(_frames)) ? _frames[anim_editor_selected_frame] : _cf;
        // Compact header: frame position + sprite count on one line
        draw_set_color(c_ltgray);
        draw_text(_info_x, _preview_y + 10, "Frame " + string(anim_editor_frame_idx + 1) + " / " + string(array_length(_frames)) + "  (" + string(_sprite_count) + " spr)");
        if (_edit_frame != undefined && _cur_anim != undefined) {
            // ── Per-animation FEET row (shown regardless of frame type) ──
            var _anim_fs = variable_struct_exists(_cur_anim, "feet_sprite") ? _cur_anim.feet_sprite : "";
            if (!anim_editor_flipped_mode) {
                var _fs_disp = (_anim_fs == "") ? "none" : _anim_fs;
                if (string_length(_fs_disp) > 20) _fs_disp = ".." + string_copy(_fs_disp, string_length(_fs_disp) - 17, 18);
                draw_set_color(_anim_fs != "" ? make_color_rgb(100, 160, 100) : make_color_rgb(100, 100, 100));
                draw_text(_info_x, _preview_y + 26, "FEET  " + _fs_disp);
                draw_set_color(make_color_rgb(32, 76, 140));
                draw_roundrect_ext(_info_x, _preview_y + 44, _info_x + 54, _preview_y + 62, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 27, _preview_y + 48, "SET");
                draw_set_halign(fa_left);
                draw_set_color(_anim_fs != "" ? make_color_rgb(112, 40, 40) : make_color_rgb(36, 27, 27));
                draw_roundrect_ext(_info_x + 60, _preview_y + 44, _info_x + 114, _preview_y + 62, 3, 3, false);
                draw_set_color(_anim_fs != "" ? c_white : make_color_rgb(65, 50, 50)); draw_set_halign(fa_center);
                draw_text(_info_x + 87, _preview_y + 48, "CLR");
                draw_set_halign(fa_left);
                // Body Y offset stepper (same row, right of CLR)
                var _bdy_val = variable_struct_exists(_cur_anim, "body_dy") ? _cur_anim.body_dy : 0;
                draw_set_color(make_color_rgb(80, 110, 80));
                draw_text(_info_x + 122, _preview_y + 48, "Y " + string(_bdy_val));
                draw_set_color(make_color_rgb(32, 70, 90));
                draw_roundrect_ext(_info_x + 172, _preview_y + 44, _info_x + 194, _preview_y + 62, 3, 3, false);
                draw_roundrect_ext(_info_x + 198, _preview_y + 44, _info_x + 220, _preview_y + 62, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 183, _preview_y + 48, "-");
                draw_text(_info_x + 209, _preview_y + 48, "+");
                draw_set_halign(fa_left);
                // Body X offset stepper (same row, right of Y)
                var _bdx_val = variable_struct_exists(_cur_anim, "body_dx") ? _cur_anim.body_dx : 0;
                draw_set_color(make_color_rgb(80, 110, 80));
                draw_text(_info_x + 232, _preview_y + 48, "X " + string(_bdx_val));
                draw_set_color(make_color_rgb(32, 70, 90));
                draw_roundrect_ext(_info_x + 282, _preview_y + 44, _info_x + 304, _preview_y + 62, 3, 3, false);
                draw_roundrect_ext(_info_x + 308, _preview_y + 44, _info_x + 330, _preview_y + 62, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 293, _preview_y + 48, "-");
                draw_text(_info_x + 319, _preview_y + 48, "+");
                draw_set_halign(fa_left);
            } else {
                var _anim_fsf = variable_struct_exists(_cur_anim, "feet_sprite_flipped") ? _cur_anim.feet_sprite_flipped : "";
                var _fsf_disp = (_anim_fsf == "") ? "none" : _anim_fsf;
                if (string_length(_fsf_disp) > 20) _fsf_disp = ".." + string_copy(_fsf_disp, string_length(_fsf_disp) - 17, 18);
                draw_set_color(_anim_fsf != "" ? make_color_rgb(80, 140, 200) : make_color_rgb(80, 100, 120));
                draw_text(_info_x, _preview_y + 26, "FEET  " + _fsf_disp);
                draw_set_color(make_color_rgb(32, 76, 140));
                draw_roundrect_ext(_info_x, _preview_y + 44, _info_x + 54, _preview_y + 62, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 27, _preview_y + 48, "SET");
                draw_set_halign(fa_left);
                draw_set_color(_anim_fsf != "" ? make_color_rgb(112, 40, 40) : make_color_rgb(36, 27, 27));
                draw_roundrect_ext(_info_x + 60, _preview_y + 44, _info_x + 114, _preview_y + 62, 3, 3, false);
                draw_set_color(_anim_fsf != "" ? c_white : make_color_rgb(65, 50, 50)); draw_set_halign(fa_center);
                draw_text(_info_x + 87, _preview_y + 48, "CLR");
                draw_set_halign(fa_left);
                // Body Y offset stepper
                var _bdy_val_f = variable_struct_exists(_cur_anim, "body_dy_flipped") ? _cur_anim.body_dy_flipped : 0;
                draw_set_color(make_color_rgb(80, 110, 80));
                draw_text(_info_x + 122, _preview_y + 48, "Y " + string(_bdy_val_f));
                draw_set_color(make_color_rgb(32, 70, 90));
                draw_roundrect_ext(_info_x + 172, _preview_y + 44, _info_x + 194, _preview_y + 62, 3, 3, false);
                draw_roundrect_ext(_info_x + 198, _preview_y + 44, _info_x + 220, _preview_y + 62, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 183, _preview_y + 48, "-");
                draw_text(_info_x + 209, _preview_y + 48, "+");
                draw_set_halign(fa_left);
                // Body X offset stepper
                var _bdx_val_f = variable_struct_exists(_cur_anim, "body_dx_flipped") ? _cur_anim.body_dx_flipped : 0;
                draw_set_color(make_color_rgb(80, 110, 80));
                draw_text(_info_x + 232, _preview_y + 48, "X " + string(_bdx_val_f));
                draw_set_color(make_color_rgb(32, 70, 90));
                draw_roundrect_ext(_info_x + 282, _preview_y + 44, _info_x + 304, _preview_y + 62, 3, 3, false);
                draw_roundrect_ext(_info_x + 308, _preview_y + 44, _info_x + 330, _preview_y + 62, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 293, _preview_y + 48, "-");
                draw_text(_info_x + 319, _preview_y + 48, "+");
                draw_set_halign(fa_left);
            }
            if (_edit_frame.type == "sprite") {
                // Frame filename
                var _fn_short = _edit_frame.sprite;
                if (string_length(_fn_short) > 20) _fn_short = ".." + string_copy(_fn_short, string_length(_fn_short) - 17, 18);
                draw_set_color(make_color_rgb(140, 160, 140));
                draw_text(_info_x, _preview_y + 76, _fn_short);
                // ── HOLD row ──
                draw_set_color(make_color_rgb(130, 145, 130));
                draw_text(_info_x, _preview_y + 96, "HOLD  " + string(_edit_frame.hold));
                draw_set_color(make_color_rgb(32, 88, 140));
                draw_roundrect_ext(_info_x + 100, _preview_y + 92, _info_x + 126, _preview_y + 110, 3, 3, false);
                draw_roundrect_ext(_info_x + 132, _preview_y + 92, _info_x + 158, _preview_y + 110, 3, 3, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 113, _preview_y + 95, "-");
                draw_text(_info_x + 145, _preview_y + 95, "+");
                draw_set_halign(fa_left);

                // ── Per-frame offset (frame_dy / frame_dx) — when any feet sprite is assigned ──
                var _has_feet_ef = (_cur_anim != undefined && (
                        (variable_struct_exists(_cur_anim, "feet_sprite") && _cur_anim.feet_sprite != "") ||
                        (variable_struct_exists(_cur_anim, "feet_sprite_flipped") && _cur_anim.feet_sprite_flipped != "")
                    ));
                {
                    if (_has_feet_ef) {
                        var _fdy_key = anim_editor_flipped_mode ? "frame_dy_flipped" : "frame_dy";
                        var _fdx_key = anim_editor_flipped_mode ? "frame_dx_flipped" : "frame_dx";
                        var _fdy_val = variable_struct_exists(_edit_frame, _fdy_key) ? _edit_frame[$ _fdy_key] : 0;
                        var _fdx_val = variable_struct_exists(_edit_frame, _fdx_key) ? _edit_frame[$ _fdx_key] : 0;
                        var _has_override = anim_editor_flipped_mode && (variable_struct_exists(_edit_frame, "frame_dy_flipped") || variable_struct_exists(_edit_frame, "frame_dx_flipped"));
                        var _off_row1 = _preview_y + 144; // Y row
                        var _off_row2 = _preview_y + 164; // X row
                        // Section label
                        draw_set_color(_has_override ? make_color_rgb(80, 140, 200) : make_color_rgb(70, 100, 70));
                        draw_text(_info_x, _off_row1 - 16, anim_editor_flipped_mode ? "FRAME OFFSET (FLIP)" : "FRAME OFFSET");
                        // CLR button in flip mode (removes flipped override, falls back to standard)
                        if (anim_editor_flipped_mode && _has_override) {
                            draw_set_color(make_color_rgb(90, 32, 32));
                            draw_roundrect_ext(_info_x + 138, _off_row1 - 18, _info_x + 168, _off_row1 - 4, 3, 3, false);
                            draw_set_color(c_white); draw_set_halign(fa_center);
                            draw_text(_info_x + 153, _off_row1 - 15, "CLR");
                            draw_set_halign(fa_left);
                        }
                        // COPY / PASTE offset clipboard (normal and flipped tracked separately)
                        {
                            var _cb_base = (anim_editor_flipped_mode && _has_override) ? _info_x + 172 : _info_x + 138;
                            var _active_cb = anim_editor_flipped_mode ? anim_editor_offset_clipboard_flipped : anim_editor_offset_clipboard;
                            var _has_cb = (_active_cb != undefined);
                            var _cpy_hov = (_mx > _cb_base && _mx < _cb_base + 26 && _my > _off_row1 - 18 && _my < _off_row1 - 4);
                            draw_set_color(_cpy_hov ? make_color_rgb(60, 100, 60) : make_color_rgb(38, 65, 38));
                            draw_roundrect_ext(_cb_base, _off_row1 - 18, _cb_base + 26, _off_row1 - 4, 3, 3, false);
                            draw_set_color(c_white); draw_set_halign(fa_center);
                            draw_text(_cb_base + 13, _off_row1 - 15, "CPY");
                            draw_set_halign(fa_left);
                            var _pst_hov = _has_cb && (_mx > _cb_base + 30 && _mx < _cb_base + 80 && _my > _off_row1 - 18 && _my < _off_row1 - 4);
                            draw_set_color(_has_cb ? (_pst_hov ? make_color_rgb(40, 80, 120) : make_color_rgb(26, 52, 90)) : make_color_rgb(35, 40, 38));
                            draw_roundrect_ext(_cb_base + 30, _off_row1 - 18, _cb_base + 80, _off_row1 - 4, 3, 3, false);
                            draw_set_color(_has_cb ? c_white : make_color_rgb(70, 75, 70)); draw_set_halign(fa_center);
                            draw_text(_cb_base + 55, _off_row1 - 15, "PASTE");
                            draw_set_halign(fa_left);
                            // AUTO Y: calculate frame offsets relative to frame 1 height and apply to all frames
                            var _ay_hov = (_mx > _cb_base + 84 && _mx < _cb_base + 152 && _my > _off_row1 - 18 && _my < _off_row1 - 4);
                            draw_set_color(_ay_hov ? make_color_rgb(100, 100, 40) : make_color_rgb(68, 68, 26));
                            draw_roundrect_ext(_cb_base + 84, _off_row1 - 18, _cb_base + 152, _off_row1 - 4, 3, 3, false);
                            draw_set_color(c_white); draw_set_halign(fa_center);
                            draw_text(_cb_base + 118, _off_row1 - 15, "AUTO Y");
                            draw_set_halign(fa_left);
                        }
                        // Y row
                        draw_set_color(make_color_rgb(90, 140, 90));
                        draw_text(_info_x, _off_row1 + 4, "Y");
                        draw_set_color(make_color_rgb(200, 220, 200));
                        draw_set_halign(fa_right);
                        draw_text(_info_x + 68, _off_row1 + 4, string(_fdy_val));
                        draw_set_halign(fa_left);
                        draw_set_color(make_color_rgb(32, 70, 90));
                        draw_roundrect_ext(_info_x + 74,  _off_row1, _info_x + 100, _off_row1 + 18, 3, 3, false);
                        draw_roundrect_ext(_info_x + 104, _off_row1, _info_x + 130, _off_row1 + 18, 3, 3, false);
                        draw_set_color(c_white); draw_set_halign(fa_center);
                        draw_text(_info_x + 87,  _off_row1 + 4, "-");
                        draw_text(_info_x + 117, _off_row1 + 4, "+");
                        draw_set_halign(fa_left);
                        // X row
                        draw_set_color(make_color_rgb(90, 140, 90));
                        draw_text(_info_x, _off_row2 + 4, "X");
                        draw_set_color(make_color_rgb(200, 220, 200));
                        draw_set_halign(fa_right);
                        draw_text(_info_x + 68, _off_row2 + 4, string(_fdx_val));
                        draw_set_halign(fa_left);
                        draw_set_color(make_color_rgb(32, 70, 90));
                        draw_roundrect_ext(_info_x + 74,  _off_row2, _info_x + 100, _off_row2 + 18, 3, 3, false);
                        draw_roundrect_ext(_info_x + 104, _off_row2, _info_x + 130, _off_row2 + 18, 3, 3, false);
                        draw_set_color(c_white); draw_set_halign(fa_center);
                        draw_text(_info_x + 87,  _off_row2 + 4, "-");
                        draw_text(_info_x + 117, _off_row2 + 4, "+");
                        draw_set_halign(fa_left);
                    }
                }
                // ── CHANGE SPRITE ──
                draw_set_color(anim_editor_flipped_mode ? make_color_rgb(26, 60, 128) : make_color_rgb(32, 80, 144));
                draw_roundrect_ext(_info_x, _preview_y + 190, _info_x + 160, _preview_y + 212, 4, 4, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 80, _preview_y + 195, anim_editor_flipped_mode ? "CHANGE FLIPPED" : "CHANGE SPRITE");
                draw_set_halign(fa_left);
                // flipped status indicator (read-only, in flip mode)
                if (anim_editor_flipped_mode) {
                    var _has_flip = variable_struct_exists(_edit_frame, "sprite_flipped") && _edit_frame.sprite_flipped != "";
                    draw_set_color(make_color_rgb(26, 52, 98));
                    draw_roundrect_ext(_info_x, _preview_y + 190, _info_x + 220, _preview_y + 212, 4, 4, false);
                    draw_set_color(_has_flip ? make_color_rgb(105, 185, 105) : make_color_rgb(185, 125, 50)); draw_set_halign(fa_center);
                    draw_text(_info_x + 110, _preview_y + 195, _has_flip ? "OVERRIDE SET" : "USING +250 AUTO");
                    draw_set_halign(fa_left);
                }
                // ── FEET toggle (only when animation has feet sprite) ──
                if (_has_feet_ef) {
                    var _feet_on = anim_editor_flipped_mode
                        ? (variable_struct_exists(_edit_frame, "composite_legs_flipped") ? _edit_frame.composite_legs_flipped
                           : !(variable_struct_exists(_edit_frame, "composite_legs") && !_edit_frame.composite_legs))
                        : !(variable_struct_exists(_edit_frame, "composite_legs") && !_edit_frame.composite_legs);
                    var _ft_hov  = (_mx > _info_x && _mx < _info_x + 160 && _my > _preview_y + 216 && _my < _preview_y + 236);
                    draw_set_color(_feet_on ? (_ft_hov ? make_color_rgb(20, 100, 40) : make_color_rgb(14, 65, 28))
                                           : (_ft_hov ? make_color_rgb(200, 100, 20) : make_color_rgb(130, 60, 10)));
                    draw_roundrect_ext(_info_x, _preview_y + 216, _info_x + 160, _preview_y + 236, 4, 4, false);
                    draw_set_color(c_white); draw_set_halign(fa_center);
                    draw_text(_info_x + 80, _preview_y + 220, _feet_on ? "FEET ON" : "FEET OFF");
                    draw_set_halign(fa_left);
                }
            } else if (_edit_frame.type == "sound") {
                var _sfile = variable_struct_exists(_edit_frame, "file") && _edit_frame.file != undefined ? string(_edit_frame.file) : "unset";
                if (string_length(_sfile) > 26) _sfile = ".." + string_copy(_sfile, string_length(_sfile) - 23, 24);
                draw_set_color(make_color_rgb(160, 180, 160));
                draw_text(_info_x, _preview_y + 76, _sfile);
                draw_set_color(make_color_rgb(130, 145, 130));
                draw_text(_info_x, _preview_y + 96, "ID: " + string(_edit_frame[$ "_sound_id"]));
                // CHANGE SFX
                var _chov_sfx = (_mx > _info_x && _mx < _info_x + 160 && _my > _preview_y + 190 && _my < _preview_y + 212);
                draw_set_color(_chov_sfx ? make_color_rgb(160, 94, 28) : make_color_rgb(120, 74, 18));
                draw_roundrect_ext(_info_x, _preview_y + 190, _info_x + 160, _preview_y + 212, 4, 4, false);
                draw_set_color(c_white); draw_set_halign(fa_center);
                draw_text(_info_x + 80, _preview_y + 195, "CHANGE SFX");
                draw_set_halign(fa_left);
            }
        }

        // ── Unified bottom row: always visible when an animation is selected ──
        if (_cur_anim != undefined) {
            var _btn_y = _preview_y + 248;
            var _has_sel = (_edit_frame != undefined);
            // +SFX
            var _sfx_hov = (_mx > _info_x && _mx < _info_x + 80 && _my > _btn_y && _my < _btn_y + 22);
            draw_set_color(_sfx_hov ? make_color_rgb(60, 120, 60) : make_color_rgb(30, 80, 30));
            draw_roundrect_ext(_info_x, _btn_y, _info_x + 80, _btn_y + 22, 4, 4, false);
            draw_set_color(c_white); draw_set_halign(fa_center);
            draw_text(_info_x + 40, _btn_y + 4, "+SFX");
            draw_set_halign(fa_left);
            // +SPRITE
            var _spr_hov = (_mx > _info_x + 88 && _mx < _info_x + 168 && _my > _btn_y && _my < _btn_y + 22);
            draw_set_color(_spr_hov ? make_color_rgb(40, 80, 160) : make_color_rgb(20, 50, 110));
            draw_roundrect_ext(_info_x + 88, _btn_y, _info_x + 168, _btn_y + 22, 4, 4, false);
            draw_set_color(c_white); draw_set_halign(fa_center);
            draw_text(_info_x + 128, _btn_y + 4, "+SPRITE");
            draw_set_halign(fa_left);
            // DEL — dimmed when nothing selected
            var _dsp_hov = _has_sel && (_mx > _info_x + 176 && _mx < _info_x + 236 && _my > _btn_y && _my < _btn_y + 22);
            draw_set_color(_has_sel ? (_dsp_hov ? make_color_rgb(160, 40, 30) : make_color_rgb(100, 28, 20)) : make_color_rgb(50, 20, 18));
            draw_roundrect_ext(_info_x + 176, _btn_y, _info_x + 236, _btn_y + 22, 4, 4, false);
            draw_set_color(_has_sel ? c_white : make_color_rgb(80, 50, 50)); draw_set_halign(fa_center);
            draw_text(_info_x + 206, _btn_y + 4, "DEL");
            draw_set_halign(fa_left);
        }

        // Frame strip (two rows tall to accommodate selection highlight)
        var _strip_y = _m_y + _m_h - 130;
        draw_set_color(make_color_rgb(8, 28, 12));
        draw_rectangle(_preview_x, _strip_y, _m_x + _m_w - 10, _strip_y + 68, false);
        var _strip_frame_w = 54; var _arr_w = 28;
        var _sx = _preview_x + 4 + _arr_w;
        var _strip_inner_w = _preview_w - _arr_w * 2 - 8;
        var _visible = floor(_strip_inner_w / _strip_frame_w);
        var _max_strip_scroll = max(0, array_length(_frames) - _visible);
        // Auto-scroll to keep current/selected frame in view
        var _focus_idx = (anim_editor_selected_frame >= 0) ? anim_editor_selected_frame : (anim_editor_playing ? anim_editor_frame_idx : -1);
        if (_focus_idx >= 0) {
            if (_focus_idx < anim_editor_strip_scroll)
                anim_editor_strip_scroll = _focus_idx;
            else if (_focus_idx >= anim_editor_strip_scroll + _visible)
                anim_editor_strip_scroll = _focus_idx - _visible + 1;
        }
        anim_editor_strip_scroll = clamp(anim_editor_strip_scroll, 0, _max_strip_scroll);
        var _strip_start = anim_editor_strip_scroll;
        // Left arrow
        var _larr_hov = (_mx > _preview_x + 4 && _mx < _preview_x + 4 + _arr_w && _my > _strip_y + 2 && _my < _strip_y + 66);
        draw_set_color(_larr_hov ? make_color_rgb(60, 80, 60) : make_color_rgb(20, 45, 22));
        draw_roundrect_ext(_preview_x + 4, _strip_y + 20, _preview_x + 4 + _arr_w, _strip_y + 48, 3, 3, false);
        draw_set_color(anim_editor_strip_scroll > 0 ? c_white : make_color_rgb(60, 70, 60));
        draw_set_halign(fa_center); draw_text(_preview_x + 4 + _arr_w / 2, _strip_y + 26, "<"); draw_set_halign(fa_left);
        // Right arrow
        var _rarr_x = _sx + _visible * _strip_frame_w + 4;
        var _rarr_hov = (_mx > _rarr_x && _mx < _rarr_x + _arr_w && _my > _strip_y + 2 && _my < _strip_y + 66);
        draw_set_color(_rarr_hov ? make_color_rgb(60, 80, 60) : make_color_rgb(20, 45, 22));
        draw_roundrect_ext(_rarr_x, _strip_y + 20, _rarr_x + _arr_w, _strip_y + 48, 3, 3, false);
        draw_set_color(anim_editor_strip_scroll < _max_strip_scroll ? c_white : make_color_rgb(60, 70, 60));
        draw_set_halign(fa_center); draw_text(_rarr_x + _arr_w / 2, _strip_y + 26, ">"); draw_set_halign(fa_left);
        for (var _si = _strip_start; _si < min(array_length(_frames), _strip_start + _visible); _si++) {
            var _sf = _frames[_si]; var _sx2 = _sx + (_si - _strip_start) * _strip_frame_w;
            var _is_cur  = (_si == anim_editor_frame_idx);
            var _is_sel  = (_si == anim_editor_selected_frame);
            draw_set_color(_is_sel ? make_color_rgb(20, 80, 180) : (_is_cur ? make_color_rgb(20, 160, 70) : make_color_rgb(20, 50, 28)));
            draw_roundrect_ext(_sx2, _strip_y + 2, _sx2 + _strip_frame_w - 2, _strip_y + 66, 3, 3, false);
            if (_is_sel) { draw_set_color(make_color_rgb(80, 140, 255)); draw_roundrect_ext(_sx2, _strip_y + 2, _sx2 + _strip_frame_w - 2, _strip_y + 66, 3, 3, true); }
            if (_sf.type == "sprite") {
                var _strip_sname = _sf.sprite;
                if (anim_editor_flipped_mode) {
                    _strip_sname = (variable_struct_exists(_sf, "sprite_flipped") && _sf.sprite_flipped != "")
                                   ? _sf.sprite_flipped : canned_anim_flipped_name(_sf.sprite);
                }
                var _tspr = canned_anim_load_sprite(anim_editor_char_idx, _strip_sname);
                if (_tspr != -1) {
                    var _tw = sprite_get_width(_tspr); var _th = sprite_get_height(_tspr);
                    if (_tw > 5 && _th > 5) {  // skip garbage 10x10 frames
                        var _tsc = min(58.0 / _th, 48.0 / _tw);
                        draw_sprite_ext(_tspr, 0, _sx2 + (_strip_frame_w - _tw * _tsc) / 2, _strip_y + 4, _tsc, _tsc, 0, c_white, 1);
                    } else {
                        draw_set_color(make_color_rgb(180, 60, 60)); draw_set_halign(fa_center);
                        draw_text(_sx2 + _strip_frame_w / 2, _strip_y + 24, "?"); draw_set_halign(fa_left);
                    }
                }
            } else if (_sf.type == "sound") {
                draw_set_color(make_color_rgb(200, 180, 40)); draw_set_halign(fa_center);
                draw_text(_sx2 + _strip_frame_w / 2, _strip_y + 24, "SFX"); draw_set_halign(fa_left);
            }
        }

        // SFX picker overlay
        if (anim_editor_sfx_picker) {
            draw_set_color(c_black); draw_set_alpha(0.85);
            draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
            draw_set_color(make_color_rgb(36, 20, 8));
            draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 8, 8, false);
            draw_set_color(make_color_rgb(200, 140, 40));
            draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 8, 8, true);
            var _spath = (anim_editor_sfx_path == "") ? "actors\\" : "actors\\" + anim_editor_sfx_path;
            draw_set_color(c_white); draw_text(_m_x + 14, _m_y + 14, "SELECT SOUND — " + _spath);
            var _lx2 = _m_x + 10; var _ly2 = _m_y + 60; var _lh2 = 28; var _lw2 = _m_w - 32;
            var _btn_y2 = _m_y + _m_h - 44; var _btn_h2 = 32;
            var _clip_bot2 = _btn_y2 - 6;
            var _list_h2 = _clip_bot2 - _ly2;
            var _has_back2 = (anim_editor_sfx_path != "");
            var _total_rows2 = (_has_back2 ? 1 : 0) + array_length(anim_editor_sfx_folders) + array_length(anim_editor_sfx_files);
            var _vis_rows2 = floor(_list_h2 / (_lh2 + 4));
            var _max_scroll2 = max(0, _total_rows2 - _vis_rows2);
            var _scr2 = clamp(anim_editor_sfx_scroll, 0, _max_scroll2);
            var _r2 = 0;
            // Back button
            if (_has_back2) {
                var _rsy = _ly2 + (_r2 - _scr2) * (_lh2 + 4);
                if (_rsy >= _ly2 && _rsy + _lh2 <= _clip_bot2) {
                    var _bhov = (_mx > _lx2 && _mx < _lx2 + _lw2 && _my > _rsy && _my < _rsy + _lh2);
                    draw_set_color(_bhov ? make_color_rgb(80, 50, 20) : make_color_rgb(50, 32, 10));
                    draw_roundrect_ext(_lx2, _rsy, _lx2 + _lw2, _rsy + _lh2, 3, 3, false);
                    draw_set_color(make_color_rgb(255, 200, 80)); draw_text(_lx2 + 10, _rsy + 6, "< BACK");
                }
                _r2++;
            }
            for (var _fdi = 0; _fdi < array_length(anim_editor_sfx_folders); _fdi++) {
                var _rsy = _ly2 + (_r2 - _scr2) * (_lh2 + 4);
                if (_rsy >= _ly2 && _rsy + _lh2 <= _clip_bot2) {
                    var _fdhov = (_mx > _lx2 && _mx < _lx2 + _lw2 && _my > _rsy && _my < _rsy + _lh2);
                    draw_set_color(_fdhov ? make_color_rgb(60, 40, 15) : make_color_rgb(38, 25, 8));
                    draw_roundrect_ext(_lx2, _rsy, _lx2 + _lw2, _rsy + _lh2, 3, 3, false);
                    draw_set_color(make_color_rgb(220, 180, 60)); draw_text(_lx2 + 10, _rsy + 6, "[folder]  " + anim_editor_sfx_folders[_fdi]);
                }
                _r2++;
            }
            for (var _wfi2 = 0; _wfi2 < array_length(anim_editor_sfx_files); _wfi2++) {
                var _rsy = _ly2 + (_r2 - _scr2) * (_lh2 + 4);
                if (_rsy >= _ly2 && _rsy + _lh2 <= _clip_bot2) {
                    var _rel2 = (anim_editor_sfx_path == "") ? anim_editor_sfx_files[_wfi2] : (anim_editor_sfx_path + "\\" + anim_editor_sfx_files[_wfi2]);
                    var _is_pending = (_rel2 == anim_editor_sfx_pending);
                    var _wfhov = (_mx > _lx2 && _mx < _lx2 + _lw2 && _my > _rsy && _my < _rsy + _lh2);
                    draw_set_color(_is_pending ? make_color_rgb(80, 55, 10) : (_wfhov ? make_color_rgb(60, 35, 10) : make_color_rgb(28, 18, 6)));
                    draw_roundrect_ext(_lx2, _rsy, _lx2 + _lw2, _rsy + _lh2, 3, 3, false);
                    if (_is_pending) { draw_set_color(make_color_rgb(255, 210, 80)); draw_roundrect_ext(_lx2, _rsy, _lx2 + _lw2, _rsy + _lh2, 3, 3, true); }
                    var _fname2 = anim_editor_sfx_files[_wfi2];
                    var _dot2 = string_last_pos(".", _fname2);
                    if (_dot2 > 0) _fname2 = string_copy(_fname2, 1, _dot2 - 1);
                    draw_set_color(_is_pending ? make_color_rgb(255, 220, 100) : c_white);
                    draw_text(_lx2 + 10, _rsy + 6, _fname2);
                }
                _r2++;
            }
            // Scrollbar
            if (_max_scroll2 > 0) {
                var _sbx = _m_x + _m_w - 16; var _sby2 = _ly2; var _sbh2 = _list_h2;
                draw_set_color(make_color_rgb(30, 20, 8));
                draw_rectangle(_sbx, _sby2, _sbx + 10, _sby2 + _sbh2, false);
                var _thumb_h2 = max(20, _sbh2 * _vis_rows2 / _total_rows2);
                var _thumb_y2 = _sby2 + (_scr2 / _max_scroll2) * (_sbh2 - _thumb_h2);
                draw_set_color(make_color_rgb(180, 120, 40));
                draw_rectangle(_sbx, _thumb_y2, _sbx + 10, _thumb_y2 + _thumb_h2, false);
            }
            // OK / Cancel buttons
            var _ok_x2  = _m_x + _m_w - 220; var _ok_w2 = 90;
            var _cx2    = _m_x + _m_w - 120; var _cw2   = 90;
            
            // Draw pending selected SFX name
            if (anim_editor_sfx_pending != "") {
                draw_set_color(make_color_rgb(255, 200, 80));
                var _disp_pending = anim_editor_sfx_pending;
                var _dot_pos = string_last_pos(".", _disp_pending);
                if (_dot_pos > 0) _disp_pending = string_copy(_disp_pending, 1, _dot_pos - 1);
                draw_text(_m_x + 14, _btn_y2 + 8, "Selected: " + _disp_pending);
            }
            
            var _ok_active = (anim_editor_sfx_pending != "");
            draw_set_color(_ok_active ? ((_mx > _ok_x2 && _mx < _ok_x2 + _ok_w2 && _my > _btn_y2 && _my < _btn_y2 + _btn_h2) ? make_color_rgb(80, 160, 80) : make_color_rgb(40, 100, 40)) : make_color_rgb(30, 50, 30));
            draw_roundrect_ext(_ok_x2, _btn_y2, _ok_x2 + _ok_w2, _btn_y2 + _btn_h2, 4, 4, false);
            draw_set_color(_ok_active ? c_white : make_color_rgb(80, 100, 80));
            draw_text(_ok_x2 + 22, _btn_y2 + 8, "OK");
            var _chov2 = (_mx > _cx2 && _mx < _cx2 + _cw2 && _my > _btn_y2 && _my < _btn_y2 + _btn_h2);
            draw_set_color(_chov2 ? make_color_rgb(100, 40, 30) : make_color_rgb(60, 28, 20));
            draw_roundrect_ext(_cx2, _btn_y2, _cx2 + _cw2, _btn_y2 + _btn_h2, 4, 4, false);
            draw_set_color(c_white); draw_text(_cx2 + 14, _btn_y2 + 8, "CANCEL");
        }

        // Sprite picker overlay
        if (anim_editor_sprite_picker) {
            draw_set_color(c_black); draw_set_alpha(0.85);
            draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);
            draw_set_color(make_color_rgb(8, 28, 14));
            draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 8, 8, false);
            draw_set_color(make_color_rgb(80, 140, 255));
            draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 8, 8, true);
            draw_set_color(c_white); draw_text(_m_x + 14, _m_y + 14, anim_editor_sprite_picker_mode == 1 ? "SELECT FEET SPRITE" : "SELECT SPRITE");
            var _sp_btn_y2 = _m_y + _m_h - 44; var _sp_btn_h2 = 32;
            var _grid_x = _m_x + 10; var _grid_y = _m_y + 60;
            var _cols = 4; var _tw2 = 200; var _th2 = 160;
            var _visible_rows = floor((_sp_btn_y2 - 10 - _grid_y) / _th2);
            var _start = anim_editor_sprite_scroll * _cols;
            for (var _pi = _start; _pi < min(array_length(anim_editor_sprite_list), _start + _cols * _visible_rows); _pi++) {
                var _pidx = _pi - _start;
                var _pr = floor(_pidx / _cols); var _pc = _pidx mod _cols;
                var _px = _grid_x + _pc * _tw2; var _py = _grid_y + _pr * _th2;
                var _is_pend = (anim_editor_sprite_list[_pi] == anim_editor_sprite_pending);
                var _phov = (_mx > _px && _mx < _px + _tw2 - 4 && _my > _py && _my < _py + _th2 - 4);
                draw_set_color(_is_pend ? make_color_rgb(20, 70, 120) : (_phov ? make_color_rgb(20, 80, 140) : make_color_rgb(14, 44, 20)));
                draw_roundrect_ext(_px, _py, _px + _tw2 - 4, _py + _th2 - 4, 3, 3, false);
                if (_is_pend) { draw_set_color(make_color_rgb(80, 180, 255)); draw_roundrect_ext(_px, _py, _px + _tw2 - 4, _py + _th2 - 4, 3, 3, true); }
                var _pspr = canned_anim_load_sprite(anim_editor_char_idx, anim_editor_sprite_list[_pi]);
                if (_pspr != -1) {
                    var _pw = sprite_get_width(_pspr); var _ph = sprite_get_height(_pspr);
                    if (_pw > 5 && _ph > 5) {
                        var _psc = min(140.0 / _ph, 180.0 / _pw);
                        gpu_set_texfilter(true);
                        draw_sprite_ext(_pspr, 0, _px + (_tw2 - 4 - _pw * _psc) / 2, _py + (_th2 - 4 - _ph * _psc) / 2, _psc, _psc, 0, c_white, 1);
                        gpu_set_texfilter(false);
                    }
                }
                draw_set_color(_is_pend ? make_color_rgb(140, 210, 255) : make_color_rgb(100, 130, 100)); draw_set_halign(fa_center);
                var _lbl = anim_editor_sprite_list[_pi];
                if (string_length(_lbl) > 10) _lbl = string_copy(_lbl, string_pos("_", _lbl) + 1, 8);
                draw_text(_px + _tw2 / 2, _py + _th2 - 18, _lbl);
                draw_set_halign(fa_left);
            }
            // Scrollbar
            var _total_spr_rows = ceil(array_length(anim_editor_sprite_list) / _cols);
            var _max_spr_scroll = max(0, _total_spr_rows - _visible_rows);
            if (_max_spr_scroll > 0) {
                var _sbx2 = _m_x + _m_w - 16; var _sby3 = _grid_y; var _sbh3 = _visible_rows * _th2;
                draw_set_color(make_color_rgb(10, 30, 15));
                draw_rectangle(_sbx2, _sby3, _sbx2 + 10, _sby3 + _sbh3, false);
                var _thumb_h3 = max(20, _sbh3 * _visible_rows / _total_spr_rows);
                var _thumb_y3 = _sby3 + (anim_editor_sprite_scroll / _max_spr_scroll) * (_sbh3 - _thumb_h3);
                draw_set_color(make_color_rgb(80, 140, 255));
                draw_rectangle(_sbx2, _thumb_y3, _sbx2 + 10, _thumb_y3 + _thumb_h3, false);
            }
            // OK / Cancel buttons
            var _sp_ok_x2 = _m_x + _m_w - 220; var _sp_ok_w2 = 90;
            var _sp_cx2   = _m_x + _m_w - 120; var _sp_cw2   = 90;
            var _sp_ok_active = (anim_editor_sprite_pending != "");
            draw_set_color(_sp_ok_active ? ((_mx > _sp_ok_x2 && _mx < _sp_ok_x2 + _sp_ok_w2 && _my > _sp_btn_y2 && _my < _sp_btn_y2 + _sp_btn_h2) ? make_color_rgb(80, 160, 80) : make_color_rgb(40, 100, 40)) : make_color_rgb(30, 50, 30));
            draw_roundrect_ext(_sp_ok_x2, _sp_btn_y2, _sp_ok_x2 + _sp_ok_w2, _sp_btn_y2 + _sp_btn_h2, 4, 4, false);
            draw_set_color(_sp_ok_active ? c_white : make_color_rgb(80, 100, 80));
            draw_text(_sp_ok_x2 + 22, _sp_btn_y2 + 8, "OK");
            var _sp_chov = (_mx > _sp_cx2 && _mx < _sp_cx2 + _sp_cw2 && _my > _sp_btn_y2 && _my < _sp_btn_y2 + _sp_btn_h2);
            draw_set_color(_sp_chov ? make_color_rgb(100, 40, 30) : make_color_rgb(60, 28, 20));
            draw_roundrect_ext(_sp_cx2, _sp_btn_y2, _sp_cx2 + _sp_cw2, _sp_btn_y2 + _sp_btn_h2, 4, 4, false);
            draw_set_color(c_white); draw_text(_sp_cx2 + 14, _sp_btn_y2 + 8, "CANCEL");
        }
    }
}

// ── EXPRESSION TILE CONFIGURATOR MODAL ──
if (expr_cfg_open) {
    draw_set_color(c_black); draw_set_alpha(0.78);
    draw_rectangle(0, 0, 1280, 960, false); draw_set_alpha(1.0);

    var _m_x = 85; var _m_y = 55; var _m_w = 1110; var _m_h = 770;
    draw_set_color(make_color_rgb(14, 48, 20));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 12, 12, false);
    draw_set_color(make_color_rgb(196, 213, 20));
    draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + 48, 12, 12, false);
    draw_rectangle(_m_x, _m_y + 28, _m_x + _m_w, _m_y + 48, false);
    draw_set_color(make_color_rgb(148, 162, 14)); draw_roundrect_ext(_m_x, _m_y, _m_x + _m_w, _m_y + _m_h, 12, 12, true);

    var _lx = _m_x + 12; var _ly = _m_y + 12;
    var _c_ec = characters[expr_cfg_char_idx];

    // Load offsets.json for left panel total offset displays
    var _folder_ec2 = datafiles_path + "actors/" + _c_ec.name + "/";
    var _off_data = load_config_json(_c_ec.name, "offsets.json");

    // Title
    draw_set_color(c_black);
    draw_text_transformed(_lx, _m_y + 12, "EXPRESSION TILE CONFIGURATOR  [DEBUG]", 1.05, 1.05, 0);

    // Character navigation
    var _nav_y = _ly + 28;
    var _c_prev_hov = (!theater_mode && _mx > _lx && _mx < _lx + 28 && _my > _nav_y && _my < _nav_y + 28);
    var _c_next_hov = (!theater_mode && _mx > _lx + 252 && _mx < _lx + 280 && _my > _nav_y && _my < _nav_y + 28);
    draw_set_color(_c_prev_hov ? c_yellow : c_ltgray);
    draw_rectangle(_lx, _nav_y, _lx + 27, _nav_y + 27, false);
    draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_lx + 13, _nav_y + 5, "<");
    draw_set_color(_c_next_hov ? c_yellow : c_ltgray);
    draw_rectangle(_lx + 253, _nav_y, _lx + 280, _nav_y + 27, false);
    draw_set_color(c_black); draw_text(_lx + 266, _nav_y + 5, ">"); draw_set_halign(fa_left);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_lx + 140, _nav_y + 5, _c_ec.name); draw_set_halign(fa_left);

    // Pose buttons
    var _pose_y = _nav_y + 36;
    draw_set_color(c_ltgray); draw_text(_lx, _pose_y + 3, "POSE");
    for (var _pi = 1; _pi <= 4; _pi++) {
        var _pbx = _lx + 45 + (_pi - 1) * 58;
        var _pi_hov = (!theater_mode && _mx > _pbx && _mx < _pbx + 48 && _my > _pose_y && _my < _pose_y + 28);
        var _p_sel = (expr_cfg_pose == _pi);
        draw_set_color(_p_sel ? make_color_rgb(70, 110, 200) : (_pi_hov ? make_color_rgb(45, 55, 80) : make_color_rgb(28, 32, 48)));
        draw_roundrect_ext(_pbx, _pose_y, _pbx + 48, _pose_y + 28, 4, 4, false);
        draw_set_color(_p_sel ? c_white : c_ltgray);
        draw_set_halign(fa_center); draw_text(_pbx + 24, _pose_y + 5, string(_pi)); draw_set_halign(fa_left);
    }

    // Direction toggle
    var _dir_y = _pose_y + 36;
    var _dir_labels = ["NATURAL", "FLIPPED"];
    for (var _di = 0; _di <= 1; _di++) {
        var _dbx = _lx + _di * 142;
        var _d_sel = (expr_cfg_high == (_di == 1));
        var _di_hov = (!theater_mode && _mx > _dbx && _mx < _dbx + 132 && _my > _dir_y && _my < _dir_y + 28);
        draw_set_color(_d_sel ? make_color_rgb(50, 100, 60) : (_di_hov ? make_color_rgb(35, 50, 40) : make_color_rgb(25, 30, 28)));
        draw_roundrect_ext(_dbx, _dir_y, _dbx + 132, _dir_y + 28, 4, 4, false);
        draw_set_color(_d_sel ? c_lime : c_ltgray);
        draw_set_halign(fa_center); draw_text(_dbx + 66, _dir_y + 5, _dir_labels[_di]); draw_set_halign(fa_left);
    }

    // Layer rows
    var _pc_ec = expr_cfg_get_pc();
    var _layer_y0 = _dir_y + 38;
    var _layer_names_ec = ["BODY", "FACE", "EYES", "MOUTH"];
    var _layer_cols = [make_color_rgb(160,120,60), make_color_rgb(100,160,255), make_color_rgb(80,200,80), make_color_rgb(255,160,60)];
    
    var _ai_ec = variable_struct_exists(_c_ec, "act_index") ? _c_ec.act_index : 1;
    var _sfx_off_ec = expr_cfg_high ? 50 : 0;
    var _pfx_ec = string(_ai_ec) + string(expr_cfg_pose);
    var _ec_mood_map = [0, 2, 3, 1, 0, 1, 1, 1, 1, 0, 2, 1, 1, 1, 0, 3, 1, 0, 1, 2];
    var _derived_mood_ec = _ec_mood_map[clamp(expr_cfg_preview_expr - 1, 0, 19)];

    for (var _li = 0; _li <= 3; _li++) {
        var _lby = _layer_y0 + _li * 52;
        var _l_sel = (expr_cfg_selected_layer == _li);
        var _l_hov = (!theater_mode && _mx > _lx && _mx < _lx + 280 && _my > _lby && _my < _lby + 46);
        draw_set_color(_l_sel ? make_color_rgb(28, 40, 68) : (_l_hov ? make_color_rgb(22, 26, 40) : make_color_rgb(18, 20, 30)));
        draw_roundrect_ext(_lx, _lby, _lx + 280, _lby + 46, 5, 5, false);
        draw_set_color(_layer_cols[_li]);
        draw_roundrect_ext(_lx, _lby, _lx + 280, _lby + 46, 5, 5, true);
        draw_set_color(c_white); draw_text(_lx + 8, _lby + 4, _layer_names_ec[_li]);
        if (_pc_ec != undefined) {
            var _ldx = 0; var _ldy = 0;
            
            // Resolve currently active file for this layer
            var _cur_file_li = "";
            var _layer_key_li = "";
            switch (_li) {
                case 0:
                    _cur_file_li = _pc_ec.body_file;
                    _layer_key_li = "body";
                    break;
                case 1:
                    _cur_file_li = _pc_ec.face_file;
                    _layer_key_li = "face";
                    break;
                case 2:
                    var _eyes_file_li = "";
                    if (_pc_ec != undefined && variable_struct_exists(_pc_ec, "eyes_files")) {
                        var _ef_li = _pc_ec.eyes_files;
                        var _ef_ek = string(expr_cfg_preview_expr);
                        if (variable_struct_exists(_ef_li, _ef_ek) && _ef_li[$ _ef_ek] != "") _eyes_file_li = _ef_li[$ _ef_ek];
                    }
                    if (_eyes_file_li == "") {
                        var _eyes_n_li = 10 + expr_cfg_preview_expr + _sfx_off_ec;
                        _eyes_file_li = "pose_" + _pfx_ec + ((_eyes_n_li < 10 ? "0" : "") + string(_eyes_n_li)) + ".png";
                    }
                    _cur_file_li = _eyes_file_li;
                    _layer_key_li = "eyes";
                    break;
                case 3:
                    var _mouth_file_li = "";
                    if (_pc_ec != undefined && variable_struct_exists(_pc_ec, "mouth_files")) {
                        var _mf_li = _pc_ec.mouth_files;
                        var _expr_key = string(expr_cfg_preview_expr);
                        var _mood_key = string(_derived_mood_ec);
                        if (variable_struct_exists(_mf_li, _expr_key) && _mf_li[$ _expr_key] != "") {
                            _mouth_file_li = _mf_li[$ _expr_key];
                        } else if (variable_struct_exists(_mf_li, _mood_key) && _mf_li[$ _mood_key] != "") {
                            _mouth_file_li = _mf_li[$ _mood_key];
                        }
                    }
                    if (_mouth_file_li == "") {
                        var _mouth_n_li = 31 + _derived_mood_ec + _sfx_off_ec;
                        _mouth_file_li = "pose_" + _pfx_ec + ((_mouth_n_li < 10 ? "0" : "") + string(_mouth_n_li)) + ".png";
                    }
                    _cur_file_li = _mouth_file_li;
                    _layer_key_li = "mouth";
                    break;
            }
            
            // Base offset from offsets.json
            var _lo_ox_li = 0; var _lo_oy_li = 0;
            if (_off_data != undefined && _pc_ec.body_file != "") {
                var _bk_li = string_replace(_pc_ec.body_file, ".png", "");
                if (variable_struct_exists(_off_data, _bk_li)) { var _bv_li = _off_data[$ _bk_li]; _lo_ox_li = _bv_li[0]; _lo_oy_li = _bv_li[1]; }
            }
            
            var _file_ok_li = string_replace(_cur_file_li, ".png", "");
            if (_off_data != undefined && variable_struct_exists(_off_data, _file_ok_li)) {
                var _fov_li = _off_data[$ _file_ok_li]; _ldx = _fov_li[0] - _lo_ox_li; _ldy = _fov_li[1] - _lo_oy_li;
            }
            
            // Add custom nudge delta offset
            var _expr_key_li = string(expr_cfg_preview_expr);
            if ((_layer_key_li == "eyes" || _layer_key_li == "mouth") && variable_struct_exists(_pc_ec, _layer_key_li + "_dx_expr_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_li + "_dx_expr_offsets"], _expr_key_li)) {
                _ldx += _pc_ec[$ _layer_key_li + "_dx_expr_offsets"][$ _expr_key_li];
            } else if (variable_struct_exists(_pc_ec, _layer_key_li + "_dx_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_li + "_dx_offsets"], _cur_file_li)) {
                _ldx += _pc_ec[$ _layer_key_li + "_dx_offsets"][$ _cur_file_li];
            } else if (variable_struct_exists(_pc_ec, _layer_key_li + "_dx")) {
                _ldx = _pc_ec[$ _layer_key_li + "_dx"];
            }
            if ((_layer_key_li == "eyes" || _layer_key_li == "mouth") && variable_struct_exists(_pc_ec, _layer_key_li + "_dy_expr_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_li + "_dy_expr_offsets"], _expr_key_li)) {
                _ldy += _pc_ec[$ _layer_key_li + "_dy_expr_offsets"][$ _expr_key_li];
            } else if (variable_struct_exists(_pc_ec, _layer_key_li + "_dy_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_li + "_dy_offsets"], _cur_file_li)) {
                _ldy += _pc_ec[$ _layer_key_li + "_dy_offsets"][$ _cur_file_li];
            } else if (variable_struct_exists(_pc_ec, _layer_key_li + "_dy")) {
                _ldy = _pc_ec[$ _layer_key_li + "_dy"];
            }
            
            draw_set_color(c_ltgray); draw_text(_lx + 8, _lby + 24, "dx:" + string(_ldx) + "  dy:" + string(_ldy));

        }
    }

    // dx/dy nudge controls for selected layer
    var _nudge_y = _layer_y0 + 4 * 52 + 6;
    if (_pc_ec != undefined) {
        var _n_ldx = 0; var _n_ldy = 0;
        
        // Resolve currently active file for selected layer
        var _cur_file_sel = "";
        var _layer_key_sel = "";
        switch (expr_cfg_selected_layer) {
            case 0:
                _cur_file_sel = _pc_ec.body_file;
                _layer_key_sel = "body";
                break;
            case 1:
                _cur_file_sel = _pc_ec.face_file;
                _layer_key_sel = "face";
                break;
            case 2:
                var _eyes_file_sel = "";
                if (_pc_ec != undefined && variable_struct_exists(_pc_ec, "eyes_files")) {
                    var _ef_sel = _pc_ec.eyes_files;
                    var _ef_ek = string(expr_cfg_preview_expr);
                    if (variable_struct_exists(_ef_sel, _ef_ek) && _ef_sel[$ _ef_ek] != "") _eyes_file_sel = _ef_sel[$ _ef_ek];
                }
                if (_eyes_file_sel == "") {
                    var _eyes_n_sel = 10 + expr_cfg_preview_expr + _sfx_off_ec;
                    _eyes_file_sel = "pose_" + _pfx_ec + ((_eyes_n_sel < 10 ? "0" : "") + string(_eyes_n_sel)) + ".png";
                }
                _cur_file_sel = _eyes_file_sel;
                _layer_key_sel = "eyes";
                break;
            case 3:
                var _mouth_file_sel = "";
                if (_pc_ec != undefined && variable_struct_exists(_pc_ec, "mouth_files")) {
                    var _mf_sel = _pc_ec.mouth_files;
                    var _expr_key = string(expr_cfg_preview_expr);
                    var _mood_key = string(_derived_mood_ec);
                    if (variable_struct_exists(_mf_sel, _expr_key) && _mf_sel[$ _expr_key] != "") {
                        _mouth_file_sel = _mf_sel[$ _expr_key];
                    } else if (variable_struct_exists(_mf_sel, _mood_key) && _mf_sel[$ _mood_key] != "") {
                        _mouth_file_sel = _mf_sel[$ _mood_key];
                    }
                }
                if (_mouth_file_sel == "") {
                    var _mouth_n_sel = 31 + _derived_mood_ec + _sfx_off_ec;
                    _mouth_file_sel = "pose_" + _pfx_ec + ((_mouth_n_sel < 10 ? "0" : "") + string(_mouth_n_sel)) + ".png";
                }
                _cur_file_sel = _mouth_file_sel;
                _layer_key_sel = "mouth";
                break;
        }
        
        var _lo_ox_sel = 0; var _lo_oy_sel = 0;
        if (_off_data != undefined && _pc_ec.body_file != "") {
            var _bk_sel = string_replace(_pc_ec.body_file, ".png", "");
            if (variable_struct_exists(_off_data, _bk_sel)) { var _bv_sel = _off_data[$ _bk_sel]; _lo_ox_sel = _bv_sel[0]; _lo_oy_sel = _bv_sel[1]; }
        }
        
        var _file_ok_sel = string_replace(_cur_file_sel, ".png", "");
        if (_off_data != undefined && variable_struct_exists(_off_data, _file_ok_sel)) {
            var _fov_sel = _off_data[$ _file_ok_sel]; _n_ldx = _fov_sel[0] - _lo_ox_sel; _n_ldy = _fov_sel[1] - _lo_oy_sel;
        }
        
        var _expr_key_sel = string(expr_cfg_preview_expr);
        if ((_layer_key_sel == "eyes" || _layer_key_sel == "mouth") && variable_struct_exists(_pc_ec, _layer_key_sel + "_dx_expr_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_sel + "_dx_expr_offsets"], _expr_key_sel)) {
            _n_ldx += _pc_ec[$ _layer_key_sel + "_dx_expr_offsets"][$ _expr_key_sel];
        } else if (variable_struct_exists(_pc_ec, _layer_key_sel + "_dx_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_sel + "_dx_offsets"], _cur_file_sel)) {
            _n_ldx += _pc_ec[$ _layer_key_sel + "_dx_offsets"][$ _cur_file_sel];
        } else if (variable_struct_exists(_pc_ec, _layer_key_sel + "_dx")) {
            _n_ldx = _pc_ec[$ _layer_key_sel + "_dx"];
        }
        if ((_layer_key_sel == "eyes" || _layer_key_sel == "mouth") && variable_struct_exists(_pc_ec, _layer_key_sel + "_dy_expr_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_sel + "_dy_expr_offsets"], _expr_key_sel)) {
            _n_ldy += _pc_ec[$ _layer_key_sel + "_dy_expr_offsets"][$ _expr_key_sel];
        } else if (variable_struct_exists(_pc_ec, _layer_key_sel + "_dy_offsets") && variable_struct_exists(_pc_ec[$ _layer_key_sel + "_dy_offsets"], _cur_file_sel)) {
            _n_ldy += _pc_ec[$ _layer_key_sel + "_dy_offsets"][$ _cur_file_sel];
        } else if (variable_struct_exists(_pc_ec, _layer_key_sel + "_dy")) {
            _n_ldy = _pc_ec[$ _layer_key_sel + "_dy"];
        }
        
        var _axes = ["dx", "dy"]; var _vals = [_n_ldx, _n_ldy];
        for (var _ai2 = 0; _ai2 <= 1; _ai2++) {
            var _ny2 = _nudge_y + _ai2 * 34;
            draw_set_color(c_ltgray); draw_text(_lx, _ny2 + 4, _axes[_ai2] + ":");
            var _nm_hov = (!theater_mode && _mx > _lx + 30 && _mx < _lx + 58 && _my > _ny2 && _my < _ny2 + 28);
            var _np_hov = (!theater_mode && _mx > _lx + 110 && _mx < _lx + 138 && _my > _ny2 && _my < _ny2 + 28);
            draw_set_color(_nm_hov ? c_yellow : c_ltgray); draw_rectangle(_lx + 30, _ny2, _lx + 57, _ny2 + 27, false);
            draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_lx + 43, _ny2 + 4, "-"); draw_set_halign(fa_left);
            draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_lx + 84, _ny2 + 4, string(_vals[_ai2])); draw_set_halign(fa_left);
            draw_set_color(_np_hov ? c_yellow : c_ltgray); draw_rectangle(_lx + 110, _ny2, _lx + 137, _ny2 + 27, false);
            draw_set_color(c_black); draw_set_halign(fa_center); draw_text(_lx + 123, _ny2 + 4, "+"); draw_set_halign(fa_left);
        }
        draw_set_color(make_color_rgb(60, 60, 80));
        draw_text(_lx, _nudge_y + 72, "Arrow keys: nudge 1px");
        draw_text(_lx, _nudge_y + 86, "Drag tiles in preview");
    }

    // Expression selector — drives both eyes and mouth (via mood_map)
    // 20 expressions in a 5-col × 4-row grid
    var _esel_y = _nudge_y + 110;
    draw_set_color(c_ltgray); draw_text(_lx, _esel_y, "EXPRESSION (eyes + mouth):");
    var _expr_names_short = ["HAP","SAD","ANG","COL","FLR","SHY","EMB","SUR","FRI","MSC","GUI","PAR","CON","BOR","SIL","PAN","POM","CNT","REF","WIS"];
    var _esel_mood_map    = [0, 2, 3, 1, 0, 1, 1, 1, 1, 0, 2, 1, 1, 1, 0, 3, 1, 0, 1, 2];
    var _mood_col = [make_color_rgb(255,200,60), make_color_rgb(160,160,180), make_color_rgb(255,100,80), make_color_rgb(160,220,100)];
    var _ecols = 5; var _eboxw = 52; var _eboxh = 36; var _egap = 4;
    for (var _ei = 1; _ei <= 20; _ei++) {
        var _ecol = (_ei - 1) % _ecols;
        var _erow = floor((_ei - 1) / _ecols);
        var _ex2 = _lx + _ecol * (_eboxw + _egap);
        var _ey2 = _esel_y + 18 + _erow * (_eboxh + _egap);
        var _e_sel2 = (expr_cfg_preview_expr == _ei);
        var _e_hov2 = (!theater_mode && _mx > _ex2 && _mx < _ex2 + _eboxw && _my > _ey2 && _my < _ey2 + _eboxh);
        draw_set_color(_e_sel2 ? make_color_rgb(55, 90, 170) : (_e_hov2 ? make_color_rgb(38, 46, 68) : make_color_rgb(22, 26, 38)));
        draw_rectangle(_ex2, _ey2, _ex2 + _eboxw, _ey2 + _eboxh, false);
        // Expression name
        draw_set_color(c_white); draw_set_halign(fa_center);
        draw_text(_ex2 + _eboxw/2, _ey2 + 3, _expr_names_short[_ei - 1]);
        // Mouth-mood colour stripe
        var _em = _esel_mood_map[_ei - 1];
        var _has_mouth = (_pc_ec != undefined && variable_struct_exists(_pc_ec, "mouth_files") && ((variable_struct_exists(_pc_ec.mouth_files, string(_ei)) && _pc_ec.mouth_files[$ string(_ei)] != "") || (variable_struct_exists(_pc_ec.mouth_files, string(_em)) && _pc_ec.mouth_files[$ string(_em)] != "")));
        var _has_eyes  = (_pc_ec != undefined && variable_struct_exists(_pc_ec, "eyes_files")  && variable_struct_exists(_pc_ec.eyes_files,  string(_ei)) && _pc_ec.eyes_files[$  string(_ei)] != "");
        draw_set_color(_has_mouth ? _mood_col[_em] : make_color_rgb(40, 42, 55));
        draw_rectangle(_ex2 + 2, _ey2 + 26, _ex2 + _eboxw - 2, _ey2 + 33, false);
        if (_has_eyes) { draw_set_color(c_aqua); draw_circle(_ex2 + _eboxw - 6, _ey2 + 6, 3, false); }
        draw_set_halign(fa_left);
    }

    // Quick-fill: enter baseline eye/mouth suffix → auto-populate all 8 configs
    var _btn_y2 = _m_y + _m_h - 52;
    var _qf_y = _btn_y2 - 36;
    draw_set_color(make_color_rgb(85, 85, 110)); draw_text(_lx, _qf_y + 3, "EYES");
    var _qf_ex = _lx + 38;
    var _qf_ea = (expr_cfg_qfill_active == 0);
    draw_set_color(_qf_ea ? make_color_rgb(35, 50, 90) : make_color_rgb(22, 26, 38));
    draw_rectangle(_qf_ex, _qf_y, _qf_ex + 30, _qf_y + 22, false);
    draw_set_color(_qf_ea ? c_yellow : c_white);
    draw_set_halign(fa_center);
    draw_text(_qf_ex + 15, _qf_y + 3, expr_cfg_qfill_eyes + (_qf_ea && (current_time mod 600 < 300) ? "|" : ""));
    draw_set_halign(fa_left);
    draw_set_color(make_color_rgb(85, 85, 110)); draw_text(_qf_ex + 36, _qf_y + 3, "MOUTH");
    var _qf_mx = _qf_ex + 82;
    var _qf_ma = (expr_cfg_qfill_active == 1);
    draw_set_color(_qf_ma ? make_color_rgb(35, 50, 90) : make_color_rgb(22, 26, 38));
    draw_rectangle(_qf_mx, _qf_y, _qf_mx + 30, _qf_y + 22, false);
    draw_set_color(_qf_ma ? c_yellow : c_white);
    draw_set_halign(fa_center);
    draw_text(_qf_mx + 15, _qf_y + 3, expr_cfg_qfill_mouth + (_qf_ma && (current_time mod 600 < 300) ? "|" : ""));
    draw_set_halign(fa_left);
    var _qf_get_x = _qf_mx + 38;
    var _qf_get_hov = (!theater_mode && _mx > _qf_get_x && _mx < _qf_get_x + 40 && _my > _qf_y && _my < _qf_y + 22);
    draw_set_color(_qf_get_hov ? make_color_rgb(30, 130, 130) : make_color_rgb(15, 75, 75));
    draw_rectangle(_qf_get_x, _qf_y, _qf_get_x + 40, _qf_y + 22, false);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_qf_get_x + 20, _qf_y + 3, "GET"); draw_set_halign(fa_left);
    var _qf_apply_x = _qf_get_x + 46;
    var _qf_apply_hov = (!theater_mode && _mx > _qf_apply_x && _mx < _qf_apply_x + 55 && _my > _qf_y && _my < _qf_y + 22);
    draw_set_color(_qf_apply_hov ? make_color_rgb(200, 120, 20) : make_color_rgb(120, 70, 10));
    draw_rectangle(_qf_apply_x, _qf_y, _qf_apply_x + 55, _qf_y + 22, false);
    draw_set_color(c_white); draw_set_halign(fa_center);
    draw_text(_qf_apply_x + 27, _qf_y + 3, "APPLY"); draw_set_halign(fa_left);

    // Bottom buttons: SAVE, CLOSE
    var _btn_w = 50; var _btn_gap_ec = 8;

    // SAVE
    var _save_x = _lx;
    var _save_hov = (!theater_mode && _mx > _save_x && _mx < _save_x + _btn_w && _my > _btn_y2 && _my < _btn_y2 + 40);
    draw_set_color(_save_hov ? c_lime : make_color_rgb(50, 110, 50)); draw_rectangle(_save_x, _btn_y2, _save_x + _btn_w, _btn_y2 + 40, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_save_x + _btn_w/2, _btn_y2 + 11, "SAVE"); draw_set_halign(fa_left);

    // CLOSE
    var _cls_x = _save_x + _btn_w + _btn_gap_ec;
    var _cls_hov2 = (!theater_mode && _mx > _cls_x && _mx < _cls_x + _btn_w && _my > _btn_y2 && _my < _btn_y2 + 40);
    draw_set_color(_cls_hov2 ? c_red : make_color_rgb(80, 25, 25)); draw_rectangle(_cls_x, _btn_y2, _cls_x + _btn_w, _btn_y2 + 40, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_cls_x + _btn_w/2, _btn_y2 + 11, "CLOSE"); draw_set_halign(fa_left);

    // ── Right panel: preview ──
    var _px2 = _m_x + 298; var _py2 = _m_y + 10;
    var _pw2 = _m_w - 308; var _ph2 = _m_h - 20;
    draw_set_color(make_color_rgb(10, 12, 18));
    draw_roundrect_ext(_px2, _py2, _px2 + _pw2, _py2 + _ph2, 8, 8, false);
    draw_set_color(make_color_rgb(35, 45, 75));
    draw_roundrect_ext(_px2, _py2, _px2 + _pw2, _py2 + _ph2, 8, 8, true);

    // Layout and dimensions for character composite + file browser (declared early for hover logic)
    var _char_preview_h = floor(_ph2 * 0.58);
    var _file_browser_y = _py2 + _char_preview_h + 4;
    var _file_browser_h = _ph2 - _char_preview_h - 8;
    var _fb_list_y = _file_browser_y + 28;
    var _fb_cols = 3;
    var _fb_item_w = floor(_pw2 / _fb_cols);
    var _fb_item_h = 22;
    var _fb_vis_rows = floor((_file_browser_h - (_fb_list_y - _file_browser_y) - 2) / _fb_item_h);
    var _fb_start = expr_cfg_file_scroll * _fb_cols;
    var _fb_end = min(_fb_start + _fb_vis_rows * _fb_cols, array_length(expr_cfg_file_list));

    // Determine if any file is hovered in the browser, to show it in the composite preview
    var _hov_fname = "";
    for (var _fi2 = _fb_start; _fi2 < _fb_end; _fi2++) {
        var _fcol2  = (_fi2 - _fb_start) mod _fb_cols;
        var _frow2  = floor((_fi2 - _fb_start) / _fb_cols);
        var _fix2   = _px2 + 1 + _fcol2 * _fb_item_w;
        var _fiy2   = _fb_list_y + _frow2 * _fb_item_h;
        if (_mx > _fix2 && _mx < _fix2 + _fb_item_w && _my > _fiy2 && _my < _fiy2 + _fb_item_h) {
            _hov_fname = expr_cfg_file_list[_fi2]; break;
        }
    }

    var _hov_spr = -1;
    if (_hov_fname != "") {
        var _hk = _c_ec.name + "_" + _hov_fname;
        if (ds_map_exists(char_sprites, _hk)) {
            _hov_spr = char_sprites[? _hk];
        } else {
            var _hpath = datafiles_path + "actors/" + _c_ec.name + "/" + _hov_fname;
            if (file_exists(_hpath)) {
                _hov_spr = sprite_add(_hpath, 1, false, false, 0, 0);
                ds_map_add(char_sprites, _hk, _hov_spr);
            }
        }
    }

    // Get preview sprites
    var _body_spr_ec = -1;
    var _face_spr_ec = -1;
    var _eyes_spr_ec = -1;
    var _mouth_spr_ec = -1;
    _folder_ec2 = datafiles_path + "actors/" + _c_ec.name + "/";
    var _dir_nm_ec = string_lower(_c_ec.name);
    _ai_ec = variable_struct_exists(_c_ec, "act_index") ? _c_ec.act_index : 1;
    _sfx_off_ec = expr_cfg_high ? 50 : 0;
    _pfx_ec = string(_ai_ec) + string(expr_cfg_pose);

    // ── Load body / face sprites (with sprite_add fallback) ──
    if (_pc_ec != undefined) {
        if (_pc_ec.body_file != "") {
            var _bk3 = _c_ec.name + "_" + _pc_ec.body_file;
            if (ds_map_exists(char_sprites, _bk3)) {
                _body_spr_ec = char_sprites[? _bk3];
            } else if (_actor_file_exists(_dir_nm_ec, _folder_ec2, _pc_ec.body_file)) {
                _body_spr_ec = _actor_sprite_add(_dir_nm_ec, _folder_ec2, _pc_ec.body_file);
                ds_map_add(char_sprites, _bk3, _body_spr_ec);
            }
        }
        if (_pc_ec.face_file != "") {
            var _fk3 = _c_ec.name + "_" + _pc_ec.face_file;
            if (ds_map_exists(char_sprites, _fk3)) {
                _face_spr_ec = char_sprites[? _fk3];
            } else if (_actor_file_exists(_dir_nm_ec, _folder_ec2, _pc_ec.face_file)) {
                _face_spr_ec = _actor_sprite_add(_dir_nm_ec, _folder_ec2, _pc_ec.face_file);
                ds_map_add(char_sprites, _fk3, _face_spr_ec);
            }
        }
    }

    // Eyes: use per-expression override if set, else suffix auto
    var _eyes_file_ec = "";
    if (_pc_ec != undefined && variable_struct_exists(_pc_ec, "eyes_files")) {
        var _ef_ec = _pc_ec.eyes_files;
        var _ef_ek = string(expr_cfg_preview_expr);
        if (variable_struct_exists(_ef_ec, _ef_ek) && _ef_ec[$ _ef_ek] != "") _eyes_file_ec = _ef_ec[$ _ef_ek];
    }
    if (_eyes_file_ec == "") {
        var _eyes_n_ec = 10 + expr_cfg_preview_expr + _sfx_off_ec;
        _eyes_file_ec = "pose_" + _pfx_ec + ((_eyes_n_ec < 10 ? "0" : "") + string(_eyes_n_ec)) + ".png";
    }
    var _ek3 = _c_ec.name + "_" + _eyes_file_ec;
    if (ds_map_exists(char_sprites, _ek3)) {
        _eyes_spr_ec = char_sprites[? _ek3];
    } else if (_actor_file_exists(_dir_nm_ec, _folder_ec2, _eyes_file_ec)) {
        _eyes_spr_ec = _actor_sprite_add(_dir_nm_ec, _folder_ec2, _eyes_file_ec);
        ds_map_add(char_sprites, _ek3, _eyes_spr_ec);
    }

    // Mouth: derive mood from the selected expression (same mapping as get_composite_character_sprite)
    _ec_mood_map = [0, 2, 3, 1, 0, 1, 1, 1, 1, 0, 2, 1, 1, 1, 0, 3, 1, 0, 1, 2];
    _derived_mood_ec = _ec_mood_map[clamp(expr_cfg_preview_expr - 1, 0, 19)];
    var _mouth_file_ec = "";
    if (_pc_ec != undefined && variable_struct_exists(_pc_ec, "mouth_files")) {
        var _mf_ec = _pc_ec.mouth_files;
        var _expr_key = string(expr_cfg_preview_expr);
        var _mood_key = string(_derived_mood_ec);
        if (variable_struct_exists(_mf_ec, _expr_key) && _mf_ec[$ _expr_key] != "") {
            _mouth_file_ec = _mf_ec[$ _expr_key];
        } else if (variable_struct_exists(_mf_ec, _mood_key) && _mf_ec[$ _mood_key] != "") {
            _mouth_file_ec = _mf_ec[$ _mood_key];
        }
    }
    if (_mouth_file_ec == "") {
        var _mouth_n_ec = 31 + _derived_mood_ec + _sfx_off_ec;
        _mouth_file_ec = "pose_" + _pfx_ec + ((_mouth_n_ec < 10 ? "0" : "") + string(_mouth_n_ec)) + ".png";
    }
    var _mk3 = _c_ec.name + "_" + _mouth_file_ec;
    if (ds_map_exists(char_sprites, _mk3)) {
        _mouth_spr_ec = char_sprites[? _mk3];
    } else if (_actor_file_exists(_dir_nm_ec, _folder_ec2, _mouth_file_ec)) {
        _mouth_spr_ec = _actor_sprite_add(_dir_nm_ec, _folder_ec2, _mouth_file_ec);
        ds_map_add(char_sprites, _mk3, _mouth_spr_ec);
    }

    // If hovering a file list item, temporarily override the active layer with the hovered sprite
    if (_hov_spr != -1) {
        if (expr_cfg_selected_layer == 0) _body_spr_ec = _hov_spr;
        else if (expr_cfg_selected_layer == 1) _face_spr_ec = _hov_spr;
        else if (expr_cfg_selected_layer == 2) _eyes_spr_ec = _hov_spr;
        else if (expr_cfg_selected_layer == 3) _mouth_spr_ec = _hov_spr;
    }

    // ── Split preview panel: top 58% = composite, bottom 42% = file browser ──
    // (Layout variables _char_preview_h, _file_browser_y, and _file_browser_h are declared early)

    // ── Character composite preview ──
    var _bdw2 = (_body_spr_ec != -1) ? sprite_get_width(_body_spr_ec) : 80;
    var _bdh2 = (_body_spr_ec != -1) ? sprite_get_height(_body_spr_ec) : 100;
    // Total composite height = body bottom → face top (face_dy is negative when above body)
    var _total_char_h = _bdh2;
    if (_pc_ec != undefined && _pc_ec.face_dy < 0) _total_char_h = _bdh2 - _pc_ec.face_dy;
    var _base_sc = (_body_spr_ec != -1) ? min((_char_preview_h - 20) / _total_char_h, 4.0) : 2.0;
    var _cfg_sc = _base_sc * expr_cfg_zoom;

    var _anch_x2 = _px2 + _pw2 / 2;
    var _anch_y2 = _py2 + _char_preview_h - 10;
    var _drawx2 = _anch_x2 - _bdw2 * _cfg_sc / 2 + expr_cfg_pan_x;
    var _drawy2 = _anch_y2 - _bdh2 * _cfg_sc    + expr_cfg_pan_y;

    gpu_set_scissor(_px2 + 2, _py2 + 2, _pw2 - 4, _char_preview_h - 4);
    gpu_set_texfilter(false);
    var _prev_sprs = [_body_spr_ec, _face_spr_ec, _eyes_spr_ec, _mouth_spr_ec];
    
    // Compute total offset dx/dy for each layer in the preview panel (including base + custom delta nudges)
    var _bdx_prev = 0; var _bdy_prev = 0;
    var _fdx_prev = 0; var _fdy_prev = 0;
    var _edx_prev = 0; var _edy_prev = 0;
    var _mdx_prev = 0; var _mdy_prev = 0;
    
    var _lo_ox_p = 0; var _lo_oy_p = 0;
    if (_off_data != undefined && _pc_ec.body_file != "") {
        var _bk_p = string_replace(_pc_ec.body_file, ".png", "");
        if (variable_struct_exists(_off_data, _bk_p)) { var _bv_p = _off_data[$ _bk_p]; _lo_ox_p = _bv_p[0]; _lo_oy_p = _bv_p[1]; }
    }
    
    if (_pc_ec != undefined) {
        // BODY
        var _body_file_prev = _pc_ec.body_file;
        var _body_ok_p = string_replace(_body_file_prev, ".png", "");
        if (_off_data != undefined && variable_struct_exists(_off_data, _body_ok_p)) {
            var _bv_p = _off_data[$ _body_ok_p]; _bdx_prev = _bv_p[0] - _lo_ox_p; _bdy_prev = _bv_p[1] - _lo_oy_p;
        }
        if (variable_struct_exists(_pc_ec, "body_dx_offsets") && variable_struct_exists(_pc_ec.body_dx_offsets, _body_file_prev)) {
            _bdx_prev += _pc_ec.body_dx_offsets[$ _body_file_prev];
        } else if (variable_struct_exists(_pc_ec, "body_dx")) {
            _bdx_prev = _pc_ec.body_dx;
        }
        if (variable_struct_exists(_pc_ec, "body_dy_offsets") && variable_struct_exists(_pc_ec.body_dy_offsets, _body_file_prev)) {
            _bdy_prev += _pc_ec.body_dy_offsets[$ _body_file_prev];
        } else if (variable_struct_exists(_pc_ec, "body_dy")) {
            _bdy_prev = _pc_ec.body_dy;
        }
        
        // FACE
        var _face_file_prev = _pc_ec.face_file;
        var _face_ok_p = string_replace(_face_file_prev, ".png", "");
        if (_off_data != undefined && variable_struct_exists(_off_data, _face_ok_p)) {
            var _fov_p = _off_data[$ _face_ok_p]; _fdx_prev = _fov_p[0] - _lo_ox_p; _fdy_prev = _fov_p[1] - _lo_oy_p;
        }
        if (variable_struct_exists(_pc_ec, "face_dx_offsets") && variable_struct_exists(_pc_ec.face_dx_offsets, _face_file_prev)) {
            _fdx_prev += _pc_ec.face_dx_offsets[$ _face_file_prev];
        } else if (variable_struct_exists(_pc_ec, "face_dx")) {
            _fdx_prev = _pc_ec.face_dx;
        }
        if (variable_struct_exists(_pc_ec, "face_dy_offsets") && variable_struct_exists(_pc_ec.face_dy_offsets, _face_file_prev)) {
            _fdy_prev += _pc_ec.face_dy_offsets[$ _face_file_prev];
        } else if (variable_struct_exists(_pc_ec, "face_dy")) {
            _fdy_prev = _pc_ec.face_dy;
        }
        
        // EYES
        var _eyes_file_prev = "";
        if (variable_struct_exists(_pc_ec, "eyes_files")) {
            var _ef_prev = _pc_ec.eyes_files;
            var _ef_ek_prev = string(expr_cfg_preview_expr);
            if (variable_struct_exists(_ef_prev, _ef_ek_prev) && _ef_prev[$ _ef_ek_prev] != "") _eyes_file_prev = _ef_prev[$ _ef_ek_prev];
        }
        if (_eyes_file_prev == "") {
            var _eyes_n_prev = 10 + expr_cfg_preview_expr + _sfx_off_ec;
            _eyes_file_prev = "pose_" + _pfx_ec + ((_eyes_n_prev < 10 ? "0" : "") + string(_eyes_n_prev)) + ".png";
        }
        var _eyes_ok_p = string_replace(_eyes_file_prev, ".png", "");
        if (_off_data != undefined && variable_struct_exists(_off_data, _eyes_ok_p)) {
            var _eov_p = _off_data[$ _eyes_ok_p]; _edx_prev = _eov_p[0] - _lo_ox_p; _edy_prev = _eov_p[1] - _lo_oy_p;
        }
        var _expr_key_prev = string(expr_cfg_preview_expr);
        if (variable_struct_exists(_pc_ec, "eyes_dx_expr_offsets") && variable_struct_exists(_pc_ec.eyes_dx_expr_offsets, _expr_key_prev)) {
            _edx_prev += _pc_ec.eyes_dx_expr_offsets[$ _expr_key_prev];
        } else if (variable_struct_exists(_pc_ec, "eyes_dx_offsets") && variable_struct_exists(_pc_ec.eyes_dx_offsets, _eyes_file_prev)) {
            _edx_prev += _pc_ec.eyes_dx_offsets[$ _eyes_file_prev];
        } else if (variable_struct_exists(_pc_ec, "eyes_dx")) {
            _edx_prev = _pc_ec.eyes_dx;
        }
        if (variable_struct_exists(_pc_ec, "eyes_dy_expr_offsets") && variable_struct_exists(_pc_ec.eyes_dy_expr_offsets, _expr_key_prev)) {
            _edy_prev += _pc_ec.eyes_dy_expr_offsets[$ _expr_key_prev];
        } else if (variable_struct_exists(_pc_ec, "eyes_dy_offsets") && variable_struct_exists(_pc_ec.eyes_dy_offsets, _eyes_file_prev)) {
            _edy_prev += _pc_ec.eyes_dy_offsets[$ _eyes_file_prev];
        } else if (variable_struct_exists(_pc_ec, "eyes_dy")) {
            _edy_prev = _pc_ec.eyes_dy;
        }
        
        // MOUTH
        var _mouth_file_prev = "";
        if (variable_struct_exists(_pc_ec, "mouth_files")) {
            var _mf_prev = _pc_ec.mouth_files;
            var _expr_key = string(expr_cfg_preview_expr);
            var _mood_key = string(_derived_mood_ec);
            if (variable_struct_exists(_mf_prev, _expr_key) && _mf_prev[$ _expr_key] != "") {
                _mouth_file_prev = _mf_prev[$ _expr_key];
            } else if (variable_struct_exists(_mf_prev, _mood_key) && _mf_prev[$ _mood_key] != "") {
                _mouth_file_prev = _mf_prev[$ _mood_key];
            }
        }
        if (_mouth_file_prev == "") {
            var _mouth_n_prev = 31 + _derived_mood_ec + _sfx_off_ec;
            _mouth_file_prev = "pose_" + _pfx_ec + ((_mouth_n_prev < 10 ? "0" : "") + string(_mouth_n_prev)) + ".png";
        }
        var _mouth_ok_p = string_replace(_mouth_file_prev, ".png", "");
        if (_off_data != undefined && variable_struct_exists(_off_data, _mouth_ok_p)) {
            var _mov_p = _off_data[$ _mouth_ok_p]; _mdx_prev = _mov_p[0] - _lo_ox_p; _mdy_prev = _mov_p[1] - _lo_oy_p;
        }
        _expr_key_prev = string(expr_cfg_preview_expr);
        if (variable_struct_exists(_pc_ec, "mouth_dx_expr_offsets") && variable_struct_exists(_pc_ec.mouth_dx_expr_offsets, _expr_key_prev)) {
            _mdx_prev += _pc_ec.mouth_dx_expr_offsets[$ _expr_key_prev];
        } else if (variable_struct_exists(_pc_ec, "mouth_dx_offsets") && variable_struct_exists(_pc_ec.mouth_dx_offsets, _mouth_file_prev)) {
            _mdx_prev += _pc_ec.mouth_dx_offsets[$ _mouth_file_prev];
        } else if (variable_struct_exists(_pc_ec, "mouth_dx")) {
            _mdx_prev = _pc_ec.mouth_dx;
        }
        if (variable_struct_exists(_pc_ec, "mouth_dy_expr_offsets") && variable_struct_exists(_pc_ec.mouth_dy_expr_offsets, _expr_key_prev)) {
            _mdy_prev += _pc_ec.mouth_dy_expr_offsets[$ _expr_key_prev];
        } else if (variable_struct_exists(_pc_ec, "mouth_dy_offsets") && variable_struct_exists(_pc_ec.mouth_dy_offsets, _mouth_file_prev)) {
            _mdy_prev += _pc_ec.mouth_dy_offsets[$ _mouth_file_prev];
        } else if (variable_struct_exists(_pc_ec, "mouth_dy")) {
            _mdy_prev = _pc_ec.mouth_dy;
        }
    }
    
    var _prev_dx = [_bdx_prev, _fdx_prev + _bdx_prev, _edx_prev + _bdx_prev, _mdx_prev + _bdx_prev];
    var _prev_dy = [_bdy_prev, _fdy_prev + _bdy_prev, _edy_prev + _bdy_prev, _mdy_prev + _bdy_prev];
    for (var _li2 = 0; _li2 <= 3; _li2++) {
        var _ls2 = _prev_sprs[_li2];
        var _lsx = _drawx2 + _prev_dx[_li2] * _cfg_sc;
        var _lsy = _drawy2 + _prev_dy[_li2] * _cfg_sc;
        var _is_sel_l = (expr_cfg_selected_layer == _li2);
        if (_ls2 == -1) {
            // Placeholder: lets user see and click the layer even without a sprite loaded
            draw_set_color(_is_sel_l ? c_yellow : make_color_rgb(35, 40, 60));
            draw_rectangle(_lsx, _lsy, _lsx + 64, _lsy + 28, _is_sel_l);
            continue;
        }
        if (_is_sel_l) {
            gpu_set_blendmode(bm_add);
            draw_sprite_ext(_ls2, 0, _lsx, _lsy, _cfg_sc, _cfg_sc, 0, _layer_cols[_li2], 0.35);
            gpu_set_blendmode(bm_normal);
        }
        draw_sprite_ext(_ls2, 0, _lsx, _lsy, _cfg_sc, _cfg_sc, 0, _is_sel_l ? c_yellow : c_white, 1.0);
    }

    // Zoom Indicator
    draw_set_halign(fa_right); draw_set_color(c_ltgray);
    draw_text(_px2 + _pw2 - 10, _py2 + 10, "Zoom: " + string(round(expr_cfg_zoom * 100)) + "%");
    draw_set_halign(fa_left);

    gpu_set_texfilter(false);
    gpu_set_scissor(0, 0, 1280, 960);

    // Divider
    draw_set_color(make_color_rgb(40, 50, 80));
    draw_rectangle(_px2, _py2 + _char_preview_h, _px2 + _pw2, _py2 + _char_preview_h + 4, false);

    // ── File browser ──
    draw_set_color(make_color_rgb(12, 14, 22));
    draw_rectangle(_px2 + 1, _file_browser_y, _px2 + _pw2 - 1, _file_browser_y + _file_browser_h, false);

    // Header bar: shows layer name + slot selector for EYES/MOUTH
    draw_set_color(make_color_rgb(28, 35, 55));
    draw_rectangle(_px2 + 1, _file_browser_y, _px2 + _pw2 - 1, _file_browser_y + 26, false);
    draw_set_color(c_white);
    var _fb_layer_name = _layer_names_ec[expr_cfg_selected_layer];
    var _hdr_text = "SELECT FILE  ·  " + _fb_layer_name;
    if (_hov_fname != "") {
        draw_set_color(c_lime);
        _hdr_text += "  [PREVIEWING: " + _hov_fname + "]";
    }
    draw_text(_px2 + 6, _file_browser_y + 5, _hdr_text);
    draw_set_color(c_white);

    // File list grid (3 columns) - (Local layout variables are declared early)

    // Determine currently assigned file for all 4 layers
    var _active_body_file = "";
    var _active_face_file = "";
    var _active_eyes_file = "";
    var _active_mouth_file = "";
    
    if (_pc_ec != undefined) {
        _active_body_file = _pc_ec.body_file;
        _active_face_file = _pc_ec.face_file;
        
        if (variable_struct_exists(_pc_ec, "eyes_files")) {
            var _ef2 = _pc_ec.eyes_files; var _ek4 = string(expr_cfg_preview_expr);
            if (variable_struct_exists(_ef2, _ek4) && _ef2[$ _ek4] != "") _active_eyes_file = _ef2[$ _ek4];
        }
        if (_active_eyes_file == "") {
            var _eyes_n_ec = 10 + expr_cfg_preview_expr + _sfx_off_ec;
            _active_eyes_file = "pose_" + _pfx_ec + ((_eyes_n_ec < 10 ? "0" : "") + string(_eyes_n_ec)) + ".png";
        }
        
        if (variable_struct_exists(_pc_ec, "mouth_files")) {
            var _mf2 = _pc_ec.mouth_files;
            var _expr_key = string(expr_cfg_preview_expr);
            var _mood_key = string(_derived_mood_ec);
            if (variable_struct_exists(_mf2, _expr_key) && _mf2[$ _expr_key] != "") {
                _active_mouth_file = _mf2[$ _expr_key];
            } else if (variable_struct_exists(_mf2, _mood_key) && _mf2[$ _mood_key] != "") {
                _active_mouth_file = _mf2[$ _mood_key];
            }
        }
        if (_active_mouth_file == "") {
            var _mouth_n_ec = 31 + _derived_mood_ec + _sfx_off_ec;
            _active_mouth_file = "pose_" + _pfx_ec + ((_mouth_n_ec < 10 ? "0" : "") + string(_mouth_n_ec)) + ".png";
        }
    }

    gpu_set_scissor(_px2 + 1, _fb_list_y, _pw2 - 2, _file_browser_h - (_fb_list_y - _file_browser_y));
    for (var _fi = _fb_start; _fi < _fb_end; _fi++) {
        var _fname = expr_cfg_file_list[_fi];
        var _fcol  = (_fi - _fb_start) mod _fb_cols;
        var _frow  = floor((_fi - _fb_start) / _fb_cols);
        var _fitem_x = _px2 + 1 + _fcol * _fb_item_w;
        var _fitem_y = _fb_list_y + _frow * _fb_item_h;
        var _fhov = (!theater_mode && _mx > _fitem_x && _mx < _fitem_x + _fb_item_w && _my > _fitem_y && _my < _fitem_y + _fb_item_h);
        
        var _is_body  = (_fname == _active_body_file);
        var _is_face  = (_fname == _active_face_file);
        var _is_eyes  = (_fname == _active_eyes_file);
        var _is_mouth = (_fname == _active_mouth_file);
        
        // Check if this file is the active file for the currently selected layer
        var _is_sel_layer_file = false;
        if (expr_cfg_selected_layer == 0 && _is_body) _is_sel_layer_file = true;
        else if (expr_cfg_selected_layer == 1 && _is_face) _is_sel_layer_file = true;
        else if (expr_cfg_selected_layer == 2 && _is_eyes) _is_sel_layer_file = true;
        else if (expr_cfg_selected_layer == 3 && _is_mouth) _is_sel_layer_file = true;
        
        // Define colors
        var _col_body  = make_color_rgb(255, 180, 100);
        var _col_head  = make_color_rgb(100, 180, 255);
        var _col_eyes  = make_color_rgb(120, 255, 120);
        var _col_mouth = make_color_rgb(255, 120, 120);
        
        var _bg_body  = make_color_rgb(45, 38, 25);
        var _bg_head  = make_color_rgb(25, 38, 48);
        var _bg_eyes  = make_color_rgb(22, 45, 28);
        var _bg_mouth = make_color_rgb(48, 38, 25);
        
        // Collect tags
        var _tags = [];
        if (_is_body)  array_push(_tags, { text: "BODY",  col: _col_body,  bg: make_color_rgb(80, 50, 20) });
        if (_is_face)  array_push(_tags, { text: "HEAD",  col: _col_head,  bg: make_color_rgb(20, 50, 80) });
        if (_is_eyes)  array_push(_tags, { text: "EYES",  col: _col_eyes,  bg: make_color_rgb(20, 70, 30) });
        if (_is_mouth) array_push(_tags, { text: "MOUTH", col: _col_mouth, bg: make_color_rgb(80, 30, 30) });
        
        var _bg_col = make_color_rgb(16, 18, 26);
        var _text_col = make_color_rgb(130, 140, 160);
        
        // Background color logic
        if (_is_sel_layer_file) {
            _bg_col = make_color_rgb(30, 50, 90); // Slate blue selected background
            _text_col = c_white;
        } else if (array_length(_tags) > 0) {
            // Harmonic background tint based on role
            if (_is_body)       _bg_col = _bg_body;
            else if (_is_face)  _bg_col = _bg_head;
            else if (_is_eyes)  _bg_col = _bg_eyes;
            else if (_is_mouth) _bg_col = _bg_mouth;
            _text_col = c_ltgray;
        }
        
        // Hover state
        if (_fhov) {
            if (_is_sel_layer_file) {
                _bg_col = make_color_rgb(45, 75, 130);
            } else if (array_length(_tags) > 0) {
                _bg_col = make_color_rgb(color_get_red(_bg_col) + 12, color_get_green(_bg_col) + 12, color_get_blue(_bg_col) + 12);
            } else {
                _bg_col = make_color_rgb(30, 38, 58);
            }
            _text_col = c_white;
        }
        
        // Draw background
        draw_set_color(_bg_col);
        draw_rectangle(_fitem_x, _fitem_y, _fitem_x + _fb_item_w - 2, _fitem_y + _fb_item_h - 1, false);
        
        // Draw borders for selected/hovered files
        if (_is_sel_layer_file) {
            draw_set_color(make_color_rgb(100, 180, 255));
            draw_rectangle(_fitem_x, _fitem_y, _fitem_x + _fb_item_w - 2, _fitem_y + _fb_item_h - 1, true);
        } else if (_fhov) {
            draw_set_color(make_color_rgb(80, 90, 110));
            draw_rectangle(_fitem_x, _fitem_y, _fitem_x + _fb_item_w - 2, _fitem_y + _fb_item_h - 1, true);
        }
        
        // Draw tag badges starting from right to left
        var _bx = _fitem_x + _fb_item_w - 6;
        for (var _ti = array_length(_tags) - 1; _ti >= 0; _ti--) {
            var _t = _tags[_ti];
            var _badge_w = string_width(_t.text) + 8;
            var _badge_h = 14;
            var _by = _fitem_y + (_fb_item_h - _badge_h) / 2;
            
            // Draw badge background
            draw_set_color(_t.bg);
            draw_roundrect_ext(_bx - _badge_w, _by, _bx, _by + _badge_h, 3, 3, false);
            
            // Draw badge border
            draw_set_color(_t.col);
            draw_roundrect_ext(_bx - _badge_w, _by, _bx, _by + _badge_h, 3, 3, true);
            
            // Draw badge text
            draw_set_color(_t.col);
            draw_set_halign(fa_center);
            draw_text_transformed(_bx - _badge_w / 2, _by + 1, _t.text, 0.7, 0.7, 0);
            draw_set_halign(fa_left);
            
            _bx -= _badge_w + 4;
        }
        
        // Strip .png and dynamically truncate filename to fit left panel remaining space
        var _disp_name = string_replace(_fname, ".png", "");
        var _max_w = _bx - 4 - (_fitem_x + 6);
        if (string_width(_disp_name) > _max_w) {
            while (string_length(_disp_name) > 0 && string_width(_disp_name + "..") > _max_w) {
                _disp_name = string_copy(_disp_name, 1, string_length(_disp_name) - 1);
            }
            _disp_name += "..";
        }
        
        // Draw filename
        draw_set_color(_text_col);
        draw_text(_fitem_x + 6, _fitem_y + 3, _disp_name);
    }
    gpu_set_scissor(0, 0, 1280, 960);

    // ── File hover preview (handled in-context in preview pane) ──

    // Scrollbar for file browser
    var _total_rows = ceil(array_length(expr_cfg_file_list) / _fb_cols);
    if (_total_rows > _fb_vis_rows) {
        var _sb2_x = _px2 + _pw2 - 10;
        var _sb2_y = _fb_list_y; var _sb2_h = _fb_vis_rows * _fb_item_h;
        draw_set_color(make_color_rgb(28,32,48)); draw_rectangle(_sb2_x, _sb2_y, _sb2_x + 8, _sb2_y + _sb2_h, false);
        var _bar2_h = max(20, (_fb_vis_rows / _total_rows) * _sb2_h);
        var _bar2_y = _sb2_y + (expr_cfg_file_scroll / max(1, _total_rows - _fb_vis_rows)) * (_sb2_h - _bar2_h);
        draw_set_color(make_color_rgb(80,100,160)); draw_rectangle(_sb2_x, _bar2_y, _sb2_x + 8, _bar2_y + _bar2_h, false);
    }
}

// --- IMPORT MODAL ---
if (import_modal_open) {
    var _imw = 580; var _imh = 330;
    var _imx = (1280 - _imw) / 2; var _imy = (800 - _imh) / 2;

    // Background
    draw_set_color(make_color_rgb(12, 8, 22)); draw_roundrect_ext(_imx, _imy, _imx + _imw, _imy + _imh, 8, 8, false);
    draw_set_color(make_color_rgb(175, 130, 230)); draw_roundrect_ext(_imx, _imy, _imx + _imw, _imy + _imh, 8, 8, true);

    // Header
    draw_set_color(make_color_rgb(175, 130, 230)); draw_text(_imx + 14, _imy + 10, "IMPORT ASSETS");
    draw_set_color(make_color_rgb(80, 55, 110)); draw_line(_imx + 1, _imy + 33, _imx + _imw - 1, _imy + 33);

    // Close button
    var _ic_hov = (_mx > _imx + _imw - 34 && _mx < _imx + _imw - 6 && _my > _imy + 6 && _my < _imy + 30);
    draw_set_color(_ic_hov ? c_red : make_color_rgb(100, 30, 30)); draw_roundrect_ext(_imx + _imw - 34, _imy + 6, _imx + _imw - 6, _imy + 30, 4, 4, false);
    draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_imx + _imw - 20, _imy + 10, "X"); draw_set_halign(fa_left);

    // Mode tabs
    var _it0 = (import_modal_mode == 0); var _it1 = (import_modal_mode == 1);
    draw_set_color(_it0 ? make_color_rgb(80, 40, 130) : make_color_rgb(30, 20, 50));
    draw_roundrect_ext(_imx + 10, _imy + 38, _imx + 100, _imy + 63, 5, 5, false);
    draw_set_color(_it0 ? make_color_rgb(175, 130, 230) : make_color_rgb(90, 70, 120));
    draw_roundrect_ext(_imx + 10, _imy + 38, _imx + 100, _imy + 63, 5, 5, true);
    draw_set_color(_it0 ? c_white : make_color_rgb(150, 120, 180)); draw_set_halign(fa_center); draw_text(_imx + 55, _imy + 43, "IMAGE"); draw_set_halign(fa_left);

    draw_set_color(_it1 ? make_color_rgb(80, 40, 130) : make_color_rgb(30, 20, 50));
    draw_roundrect_ext(_imx + 106, _imy + 38, _imx + 196, _imy + 63, 5, 5, false);
    draw_set_color(_it1 ? make_color_rgb(175, 130, 230) : make_color_rgb(90, 70, 120));
    draw_roundrect_ext(_imx + 106, _imy + 38, _imx + 196, _imy + 63, 5, 5, true);
    draw_set_color(_it1 ? c_white : make_color_rgb(150, 120, 180)); draw_set_halign(fa_center); draw_text(_imx + 151, _imy + 43, "SOUND"); draw_set_halign(fa_left);

    var _browse_w = 92;
    var _browse_x = _imx + _imw - 10 - _browse_w;

    if (import_modal_mode == 0) {
        // Background image row
        draw_set_color(make_color_rgb(175, 130, 230)); draw_text(_imx + 14, _imy + 75, "Background Image:");
        var _bg_disp = (import_modal_bg_path != "") ? filename_name(import_modal_bg_path) : "no file selected";
        draw_set_color(make_color_rgb(200, 200, 210)); draw_roundrect_ext(_imx + 14, _imy + 92, _browse_x - 8, _imy + 120, 4, 4, false);
        gpu_set_scissor(_imx + 14, _imy + 92, _browse_x - 24, 28);
        draw_set_color(import_modal_bg_path != "" ? c_white : make_color_rgb(120, 110, 140)); draw_text(_imx + 20, _imy + 100, _bg_disp);
        gpu_set_scissor(0, 0, 1280, 960);
        var _bb_hov = (_mx > _browse_x && _mx < _browse_x + _browse_w && _my > _imy + 92 && _my < _imy + 120);
        draw_set_color(_bb_hov ? make_color_rgb(110, 60, 175) : make_color_rgb(70, 35, 120)); draw_roundrect_ext(_browse_x, _imy + 92, _browse_x + _browse_w, _imy + 120, 4, 4, false);
        draw_set_color(_bb_hov ? c_white : make_color_rgb(175, 130, 230)); draw_roundrect_ext(_browse_x, _imy + 92, _browse_x + _browse_w, _imy + 120, 4, 4, true);
        draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_browse_x + _browse_w / 2, _imy + 100, "BROWSE"); draw_set_halign(fa_left);

        // Mask image row
        draw_set_color(make_color_rgb(175, 130, 230)); draw_text(_imx + 14, _imy + 148, "Mask Image (optional):");
        var _mk_disp = (import_modal_mask_path != "") ? filename_name(import_modal_mask_path) : "none";
        draw_set_color(make_color_rgb(200, 200, 210)); draw_roundrect_ext(_imx + 14, _imy + 165, _browse_x - 8, _imy + 193, 4, 4, false);
        gpu_set_scissor(_imx + 14, _imy + 165, _browse_x - 24, 28);
        draw_set_color(import_modal_mask_path != "" ? c_white : make_color_rgb(120, 110, 140)); draw_text(_imx + 20, _imy + 173, _mk_disp);
        gpu_set_scissor(0, 0, 1280, 960);
        var _mb_hov = (_mx > _browse_x && _mx < _browse_x + _browse_w && _my > _imy + 165 && _my < _imy + 193);
        draw_set_color(_mb_hov ? make_color_rgb(110, 60, 175) : make_color_rgb(70, 35, 120)); draw_roundrect_ext(_browse_x, _imy + 165, _browse_x + _browse_w, _imy + 193, 4, 4, false);
        draw_set_color(_mb_hov ? c_white : make_color_rgb(175, 130, 230)); draw_roundrect_ext(_browse_x, _imy + 165, _browse_x + _browse_w, _imy + 193, 4, 4, true);
        draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_browse_x + _browse_w / 2, _imy + 173, "BROWSE"); draw_set_halign(fa_left);
        if (import_modal_mask_path != "") {
            var _clr_hov = (_mx > _browse_x && _mx < _browse_x + _browse_w && _my > _imy + 198 && _my < _imy + 216);
            draw_set_color(_clr_hov ? make_color_rgb(140, 40, 40) : make_color_rgb(80, 25, 25)); draw_roundrect_ext(_browse_x, _imy + 198, _browse_x + _browse_w, _imy + 216, 3, 3, false);
            draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_browse_x + _browse_w / 2, _imy + 202, "CLEAR"); draw_set_halign(fa_left);
        }
        // Mask rename note
        if (import_modal_mask_path != "" && import_modal_bg_path != "") {
            var _note = "Will be saved as: " + filename_change_ext(filename_name(import_modal_bg_path), "") + "_mask" + filename_ext(import_modal_mask_path);
            draw_set_color(make_color_rgb(140, 120, 170)); draw_text(_imx + 14, _imy + 220, _note);
        }
    } else {
        // Subcategory row
        draw_set_color(make_color_rgb(175, 130, 230)); draw_text(_imx + 14, _imy + 75, "Subcategory (folder name):");
        draw_set_color(make_color_rgb(200, 200, 210)); draw_roundrect_ext(_imx + 14, _imy + 92, _imx + _imw - 14, _imy + 120, 4, 4, false);
        var _sc_txt = import_modal_subcat + (cursor_visible ? "|" : "");
        draw_set_color(string_length(import_modal_subcat) > 0 ? make_color_rgb(20, 15, 35) : make_color_rgb(155, 140, 175));
        draw_text(_imx + 20, _imy + 100, string_length(import_modal_subcat) > 0 ? import_modal_subcat : "e.g.  humans");
        if (cursor_visible) {
            var _cp = get_text_pos(import_modal_subcat, import_modal_subcat_caret, _imw - 34, 20);
            draw_set_color(make_color_rgb(20, 15, 35));
            draw_line(_imx + 20 + _cp.x, _imy + 100, _imx + 20 + _cp.x, _imy + 116);
        }

        // Sound file row
        draw_set_color(make_color_rgb(175, 130, 230)); draw_text(_imx + 14, _imy + 148, "Sound File (.wav):");
        var _snd_disp = (import_modal_snd_path != "") ? filename_name(import_modal_snd_path) : "no file selected";
        draw_set_color(make_color_rgb(200, 200, 210)); draw_roundrect_ext(_imx + 14, _imy + 165, _browse_x - 8, _imy + 193, 4, 4, false);
        gpu_set_scissor(_imx + 14, _imy + 165, _browse_x - 24, 28);
        draw_set_color(import_modal_snd_path != "" ? c_white : make_color_rgb(120, 110, 140)); draw_text(_imx + 20, _imy + 173, _snd_disp);
        gpu_set_scissor(0, 0, 1280, 960);
        var _sb_hov = (_mx > _browse_x && _mx < _browse_x + _browse_w && _my > _imy + 165 && _my < _imy + 193);
        draw_set_color(_sb_hov ? make_color_rgb(110, 60, 175) : make_color_rgb(70, 35, 120)); draw_roundrect_ext(_browse_x, _imy + 165, _browse_x + _browse_w, _imy + 193, 4, 4, false);
        draw_set_color(_sb_hov ? c_white : make_color_rgb(175, 130, 230)); draw_roundrect_ext(_browse_x, _imy + 165, _browse_x + _browse_w, _imy + 193, 4, 4, true);
        draw_set_color(c_white); draw_set_halign(fa_center); draw_text(_browse_x + _browse_w / 2, _imy + 173, "BROWSE"); draw_set_halign(fa_left);
    }

    // Divider above bottom bar
    draw_set_color(make_color_rgb(60, 40, 90)); draw_line(_imx + 1, _imy + _imh - 65, _imx + _imw - 1, _imy + _imh - 65);

    // Status message
    if (import_modal_status != "") {
        draw_set_color(import_modal_status_ok ? make_color_rgb(100, 220, 120) : make_color_rgb(220, 100, 100));
        draw_text(_imx + 14, _imy + _imh - 55, import_modal_status);
    }

    // Import button
    var _can_import = (import_modal_mode == 0) ? (import_modal_bg_path != "") : (import_modal_snd_path != "" && string_length(string_trim(import_modal_subcat)) > 0);
    var _imp_hov = (_can_import && _mx > _browse_x && _mx < _browse_x + _browse_w && _my > _imy + _imh - 55 && _my < _imy + _imh - 20);
    draw_set_color(_can_import ? (_imp_hov ? make_color_rgb(80, 160, 80) : make_color_rgb(40, 110, 40)) : make_color_rgb(30, 40, 30));
    draw_roundrect_ext(_browse_x, _imy + _imh - 55, _browse_x + _browse_w, _imy + _imh - 20, 5, 5, false);
    draw_set_color(_can_import ? (_imp_hov ? c_white : make_color_rgb(130, 210, 130)) : make_color_rgb(60, 70, 60));
    draw_roundrect_ext(_browse_x, _imy + _imh - 55, _browse_x + _browse_w, _imy + _imh - 20, 5, 5, true);
    draw_set_color(_can_import ? c_white : make_color_rgb(80, 90, 80)); draw_set_halign(fa_center);
    draw_text(_browse_x + _browse_w / 2, _imy + _imh - 44, "IMPORT"); draw_set_halign(fa_left);
}

// Restore default texture filter after modals
gpu_set_texfilter(false);
}

function draw_fx_overlay(sh, sx, sy, sw, sh_h, blend) {
    if (!shader_is_compiled(sh)) return;
    shader_set(sh);
    shader_set_uniform_f(shader_get_uniform(sh, "u_time"), current_time * 0.001);
    shader_set_uniform_f(shader_get_uniform(sh, "u_rect"), sx, sy, sw, sh_h);
    gpu_set_blendmode(blend);
    draw_set_color(c_white); draw_set_alpha(1.0);
    draw_rectangle(sx, sy, sx + sw, sy + sh_h, false);
    shader_reset(); gpu_set_blendmode(bm_normal);
}

function draw_fx_distort(sh, sx, sy, sw, sh_h) {
    if (!shader_is_compiled(sh)) return;
    var _w = ceil(sw); var _h = ceil(sh_h);
    if (!surface_exists(heat_surface) || surface_get_width(heat_surface) != _w || surface_get_height(heat_surface) != _h) {
        if (surface_exists(heat_surface)) surface_free(heat_surface);
        heat_surface = surface_create(_w, _h);
    }
    surface_copy_part(heat_surface, 0, 0, application_surface, round(sx), round(sy), _w, _h);
    shader_set(sh);
    shader_set_uniform_f(shader_get_uniform(sh, "u_time"), current_time * 0.001);
    draw_set_color(c_white); draw_set_alpha(1.0);
    draw_surface_stretched(heat_surface, sx, sy, sw, sh_h);
    shader_reset();
}
