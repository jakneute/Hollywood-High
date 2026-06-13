/// @description Free studio sprite cache (released when leaving the room)
if (variable_instance_exists(id, "studio_sprite_cache") && ds_exists(studio_sprite_cache, ds_type_map)) {
    var _k = ds_map_find_first(studio_sprite_cache);
    while (!is_undefined(_k)) {
        var _spr = studio_sprite_cache[? _k];
        if (_spr != -1 && sprite_exists(_spr)) sprite_delete(_spr);
        _k = ds_map_find_next(studio_sprite_cache, _k);
    }
    ds_map_destroy(studio_sprite_cache);
}
