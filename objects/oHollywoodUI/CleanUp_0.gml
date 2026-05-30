/// @description Stop speech on exit
tts_stop();
is_speaking = false;

// Release surfaces to prevent VRAM memory leaks
if (surface_exists(o_char_surface)) surface_free(o_char_surface);
if (surface_exists(o_mask_surface)) surface_free(o_mask_surface);
if (variable_global_exists("composite_char_surface") && surface_exists(global.composite_char_surface)) {
    surface_free(global.composite_char_surface);
}

if (variable_global_exists("scenes_pack_buffer") && global.scenes_pack_buffer != -1) {
    buffer_delete(global.scenes_pack_buffer);
    global.scenes_pack_buffer = -1;
}

if (variable_global_exists("sounds_pack_buffer") && global.sounds_pack_buffer != -1) {
    buffer_delete(global.sounds_pack_buffer);
    global.sounds_pack_buffer = -1;
}
