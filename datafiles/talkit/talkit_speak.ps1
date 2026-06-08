param(
    [string]$Text = "",
    [string]$Path = "",
    [int]$Voice = 0,
    [int]$Rate = 150,
    [int]$Pitch = 100,
    [int]$Mode = 0,
    [int]$Style = 0,
    [int]$Req = 0,
    [int]$GlottalSource = -1,
    [int]$F0Perturb = -1,
    [int]$F0Range = -1,
    [int]$SpeakingMode = -1,
    [int]$VowelFactor = -1,
    [int]$Volume = 50,
    [int]$GamePID = 0
)

if ($Path -and (Test-Path $Path)) { $Text = Get-Content $Path -Raw }
if (!$Text) { $Text = "Hello" }

$HostPath = Join-Path $PSScriptRoot "TiSpeech.Host.exe"
$DllDir = $PSScriptRoot

# --- SAPI5 Viseme Pre-Analysis ---
try {
    [System.Reflection.Assembly]::LoadFrom((Join-Path $PSScriptRoot "talkit_sapi.dll")) | Out-Null
    [SapiAnalyzer]::AnalyzeAsync($Text, $DllDir, $Req)
} catch {}

# Get parent process (the game) to monitor its life
$Parent = $null
if ($GamePID -gt 0) {
    $Parent = Get-Process -Id $GamePID -ErrorAction SilentlyContinue
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $HostPath
$psi.WorkingDirectory = $DllDir
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$p = [System.Diagnostics.Process]::Start($psi)
$stdin = $p.StandardInput
$stdout = $p.StandardOutput

function Send($cmdObj) {
    $json = $cmdObj | ConvertTo-Json -Compress
    $stdin.WriteLine($json)
}

Send @{"Cmd"="Open"; "S"=$DllDir; "U"=[uint32]1}
Send @{"Cmd"="SetPersonality"; "I"=$Voice}
Send @{"Cmd"="SetRate"; "I"=$Rate}
Send @{"Cmd"="SetPitch"; "I"=$Pitch}

# New settings (if supported by Host)
Send @{"Cmd"="SetVoicingMode"; "I"=$Mode}
Send @{"Cmd"="SetF0Style"; "I"=$Style}
if ($GlottalSource -ge 0) { Send @{"Cmd"="SetGlottalSource"; "I"=$GlottalSource} }
if ($F0Perturb     -ge 0) { Send @{"Cmd"="SetF0Perturb";     "I"=$F0Perturb}     }
if ($F0Range       -ge 0) { Send @{"Cmd"="SetF0Range";       "I"=$F0Range}       }
if ($SpeakingMode  -ge 0) { Send @{"Cmd"="SetSpeakingMode";  "I"=$SpeakingMode}  }
if ($VowelFactor   -ge 0) { Send @{"Cmd"="SetVowelFactor";   "I"=$VowelFactor}   }

# Volume 50 = neutral (0 dB); 0..49 = -20..0 dB quieter; 51..100 = 0..+20 dB louder
if ($Volume -ne 50) {
    $avBias = [int][Math]::Round(($Volume / 50.0 - 1.0) * 20)
    Send @{"Cmd"="SetAVBias"; "I"=$avBias}
}

$totalPhoneticLength = $Text.Length
$charsProcessed = 0

# Split text into chunks to avoid engine limits (max ~400 chars per speak command)
# We split by sentence boundaries or by length if no boundaries exist
$chunks = $Text -split "(?<=[.!?])\s+"

foreach ($chunk in $chunks) {
    if ($chunk.Length -gt 400) {
        # Fallback for very long sentences
        $subchunks = [regex]::Matches($chunk, ".{1,400}") | ForEach-Object { $_.Value }
    } else {
        $subchunks = @($chunk)
    }

    foreach ($sub in $subchunks) {
        if ($sub.Trim().Length -eq 0) { continue }
        
        # Check if parent (the game) is still alive before speaking
        if ($Parent -and $Parent.HasExited) { 
            $p.Kill(); Send @{"Cmd"="Close"}; exit 
        }

        # Update Progress Pulse (Report progress of what has already finished)
        [System.IO.File]::WriteAllText("$DllDir\talkit_prog_$Req.tmp", ($charsProcessed / $totalPhoneticLength).ToString("F2"))

        Send @{"Cmd"="Speak"; "S"=$sub; "B"=$true}

        while ($line = $stdout.ReadLine()) {
            # Continuous check while waiting for speech to finish
            if ($Parent -and $Parent.HasExited) { $p.Kill(); exit }
            
            if ($line -like '*SpeakCompleted*') { break }
            if ($line -like '*Error*') { break }
        }
        $charsProcessed += $sub.Length
    }
}

# Final 100% pulse
[System.IO.File]::WriteAllText("$DllDir\talkit_prog_$Req.tmp", "1.00")

# Create signal file IMMEDIATELY so the game can start the next block
[System.IO.File]::WriteAllText("$DllDir\talkit_done_$Req.tmp", "")

Send @{"Cmd"="Close"}
if (!$p.WaitForExit(1000)) { $p.Kill() }
