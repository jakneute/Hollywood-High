/// @description Professional TTS Wrapper (Cartoon Mode)
/*
 * Stable TTS execution with support for Pitch and Speed.
 */

function tts_speak(_text, _voice_id, _pitch, _speed, _mode, _style, _glottal = -1, _f0perturb = -1, _f0range = -1, _speaking = -1, _vowel = -1, _volume = 50) {
    if (_text == "") return;

    global.tts_request_id++;
    var _req = global.tts_request_id;

    var _path = game_save_id + "talkit_text_" + string(_req) + ".txt";
    var _f = file_text_open_write(_path);
    if (_f != -1) { file_text_write_string(_f, _text); file_text_close(_f); }

    var _idx = real(string_replace(_voice_id, "talkit_", ""));
    var _script = working_directory + "talkit\\talkit_speak.ps1";
    var _ps_exe = "C:\\Windows\\SysWOW64\\WindowsPowerShell\\v1.0\\powershell.exe";

    var _t_pitch = floor(50 + (_pitch * 1.5));
    var _t_speed = floor(50 + (_speed * 2.5));
    var _done_file = working_directory + "talkit\\talkit_done_" + string(_req) + ".tmp";
    if (file_exists(_done_file)) file_delete(_done_file);

    var _cmd = _ps_exe + " -ExecutionPolicy Bypass -File \"" + _script + "\""
        + " -Path \""     + _path            + "\""
        + " -Voice "      + string(_idx)
        + " -Rate "       + string(_t_speed)
        + " -Pitch "      + string(_t_pitch)
        + " -Mode "       + string(_mode)
        + " -Style "      + string(_style)
        + " -Req "        + string(_req);

    if (_glottal   >= 0) _cmd += " -GlottalSource " + string(_glottal);
    if (_f0perturb >= 0) _cmd += " -F0Perturb "     + string(_f0perturb);
    if (_f0range   >= 0) _cmd += " -F0Range "       + string(_f0range);
    if (_speaking  >= 0) _cmd += " -SpeakingMode "  + string(_speaking);
    if (_vowel     >= 0) _cmd += " -VowelFactor "   + string(_vowel);
    if (_volume != 50)   _cmd += " -Volume "         + string(clamp(round(_volume), 0, 100));

    if (variable_global_exists("win_exec_id")) {
        external_call(global.win_exec_id, _cmd, 0);
    }
    return _req;
}

function tts_cleanup_req(_req) {
    var _done_file = working_directory + "talkit\\talkit_done_" + string(_req) + ".tmp";
    var _txt_file  = game_save_id       + "talkit_text_"        + string(_req) + ".txt";
    var _prog_file = working_directory + "talkit\\talkit_prog_" + string(_req) + ".tmp";
    var _dur_file  = working_directory + "talkit\\talkit_dur_"  + string(_req) + ".tmp";
    if (file_exists(_done_file)) file_delete(_done_file);
    if (file_exists(_txt_file))  file_delete(_txt_file);
    if (file_exists(_prog_file)) file_delete(_prog_file);
    if (file_exists(_dur_file))  file_delete(_dur_file);
}

function tts_stop() {
    if (variable_global_exists("win_exec_id")) {
        var _tk = "C:\\Windows\\System32\\taskkill.exe /F /T /IM ";
        external_call(global.win_exec_id, _tk + "talkit_bridge.exe", 0);
        external_call(global.win_exec_id, _tk + "TiSpeech.Host.exe", 0);
        external_call(global.win_exec_id, _tk + "tihost.exe", 0);
        external_call(global.win_exec_id, "C:\\Windows\\System32\\Wbem\\wmic.exe process where \"CommandLine like '%talkit_speak.ps1%'\" call terminate", 0);
        external_call(global.win_exec_id, "C:\\Windows\\System32\\Wbem\\wmic.exe process where \"Name like 'TiSpeech%'\" call terminate", 0);
    }
}

/**
 * UPGRADED: Uses PowerShell to find ALL registered SAPI 5 voices.
 */
function tts_refresh_voices() {
    var _retro = [
        "Man", "Woman", "Hyper Female", "Child", "Strong Man", 
        "Mellow", "Singing Girl", "Strong Woman", "The Fly", "Little Robot",
        "Martian", "Big Robot", "Hyper Male", "Old Woman", "Little Man",
        "Imaginary Man", "Nerd", "Whiner", "Wobbly", "Singing Boy"
    ];
    var _v = [];
    for (var i = 0; i < array_length(_retro); i++) {
        array_push(_v, { name: _retro[i], voice_id: "talkit_" + string(i) });
    }
    return _v;
}
