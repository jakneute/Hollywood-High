param(
    [string]$Text = "",
    [string]$Path = "",
    [int]$Voice = 0,
    [int]$Rate = 150,
    [int]$Pitch = 100,
    [int]$Mode = 0,
    [int]$Style = 0,
    [int]$Req = 0
)

if ($Path -and (Test-Path $Path)) { $Text = Get-Content $Path -Raw }
if (!$Text) { $Text = "Hello" }

$HostPath = Join-Path $PSScriptRoot "TiSpeech.Host.exe"
$DllDir = $PSScriptRoot

# --- SAPI5 Viseme Pre-Analysis ---
# Silently synthesizes the text using a Windows SAPI5 voice to capture phoneme
# timing. Each VisemeReached event gives us a mouth-shape code (0-21) at a
# millisecond offset. We normalize the offsets to 0.0-1.0 and write them to a
# temp file that GML reads to drive mouth-open/closed animation instead of cycling.
$script:_vis = [System.Collections.Generic.List[string]]::new()
try {
    Add-Type -AssemblyName System.Speech -ErrorAction Stop
    $sapi = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $sapi.SetOutputToNull()
    $sapi.add_VisemeReached({
        param($s, $e)
        $script:_vis.Add("$($e.AudioPosition.TotalMilliseconds):$([int]$e.Viseme)")
    })
    $sapi.Speak($Text)
    $sapi.Dispose()
    if ($script:_vis.Count -gt 0) {
        $lastMs = [double]($script:_vis[$script:_vis.Count - 1] -split ':')[0]
        if ($lastMs -gt 0) {
            $out = ($script:_vis | ForEach-Object {
                $p = $_ -split ':'; "$([Math]::Round([double]$p[0] / $lastMs, 3)):$($p[1])"
            }) -join ','
            $out | Set-Content -Path "$DllDir\talkit_vis_$Req.tmp" -NoNewline -Encoding UTF8
        }
    }
} catch { }  # No SAPI5 voices or unavailable — mouth will cycle normally

# Get parent process (the game) to monitor its life
$Parent = $null
try {
    $ParentProcessId = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $PID").ParentProcessId
    if ($ParentProcessId) { $Parent = Get-Process -Id $ParentProcessId -ErrorAction SilentlyContinue }
} catch {
    try {
        $ParentProcessId = (Get-WmiObject Win32_Process -Filter "ProcessId = $PID").ParentProcessId
        if ($ParentProcessId) { $Parent = Get-Process -Id $ParentProcessId -ErrorAction SilentlyContinue }
    } catch {}
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
        ($charsProcessed / $totalPhoneticLength).ToString("F2") | Set-Content -Path "$DllDir\talkit_prog_$Req.tmp" -NoNewline

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
"1.00" | Set-Content -Path "$DllDir\talkit_prog_$Req.tmp" -NoNewline

# Create signal file IMMEDIATELY so the game can start the next block
New-Item -Path "$DllDir\talkit_done_$Req.tmp" -ItemType File -Force

Send @{"Cmd"="Close"}
if (!$p.WaitForExit(1000)) { $p.Kill() }
