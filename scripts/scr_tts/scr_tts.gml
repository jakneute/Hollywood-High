/// @description Professional TTS Wrapper (Cartoon Mode)
/*
 * Stable TTS execution with support for Pitch and Speed.
 */

function tts_speak(_text, _voice_id, _pitch, _speed, _mode, _style) {
    if (_text == "") return;

    global.tts_request_id++;
    var _req = global.tts_request_id;

    // --- 1. PREPARE UNIQUE RAW TEXT FILE ---
    var _path = game_save_id + "talkit_text_" + string(_req) + ".txt";
    var _f = file_text_open_write(_path);
    if (_f != -1) { file_text_write_string(_f, _text); file_text_close(_f); }

    // --- 2. GET EXECUTABLE / VOICE ---
    var _v = _voice_id;

    if (string_pos("talkit_", _v) == 1) {
        // --- RETRO TALK IT MODE ---
        var _idx = real(string_replace(_v, "talkit_", ""));
        var _script = working_directory + "talkit\\talkit_speak.ps1";
        var _ps_exe = "C:\\Windows\\SysWOW64\\WindowsPowerShell\\v1.0\\powershell.exe";
        
        // Map UI 0-100 to TalkIt 50-300 range
        var _t_pitch = floor(50 + (_pitch * 1.5)); 
        var _t_speed = floor(50 + (_speed * 2.5)); 
        var _done_file = working_directory + "talkit\\talkit_done_" + string(_req) + ".tmp";
        if (file_exists(_done_file)) file_delete(_done_file);

        var _cmd = _ps_exe + " -ExecutionPolicy Bypass -File \"" + _script + "\" -Path \"" + _path + "\" -Voice " + string(_idx) + " -Rate " + string(_t_speed) + " -Pitch " + string(_t_pitch) + " -Mode " + string(_mode) + " -Style " + string(_style) + " -Req " + string(_req);
        
        if (variable_global_exists("win_exec_id")) {
            external_call(global.win_exec_id, _cmd, 0); 
        }
        return _req;
    } else {
        // --- STANDARD BALCON MODE ---
        var _exe_path = working_directory + "balcon\\balcon.exe";
        if (!file_exists(_exe_path)) _exe_path = working_directory + "balcon.exe";
        var _exe = "\"" + _exe_path + "\"";

        var _b_pitch = floor((_pitch - 50) / 5); 
        var _b_speed = floor((_speed - 50) / 5); 

        var _cmd = _exe + " -k -v " + string(100) + " -n \"" + _v + "\" -p " + string(_b_pitch) + " -s " + string(_b_speed) + " -f \"" + _path + "\"";
        
        if (variable_global_exists("win_exec_id")) {
            external_call(global.win_exec_id, _cmd, 0); 
        }
        return _req;
    }
}

function tts_stop() {
    var _exe_path = working_directory + "balcon\\balcon.exe";
    if (!file_exists(_exe_path)) _exe_path = working_directory + "balcon.exe";
    if (variable_global_exists("win_exec_id")) {
        // Stop Balcon
        external_call(global.win_exec_id, "\"" + _exe_path + "\" -k", 0);
        // Stop TalkIt (Force kill processes and the parent powershell script)
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
