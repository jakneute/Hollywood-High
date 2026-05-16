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

# Get parent process (the game) to monitor its life
$ParentProcess = Get-Process -Id ([System.Diagnostics.Process]::GetCurrentProcess().Id) | Select-Object -ExpandProperty ParentId
try { $Parent = Get-Process -Id $ParentProcess } catch { $Parent = $null }

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

        Send @{"Cmd"="Speak"; "S"=$sub; "B"=$true}
        while ($line = $stdout.ReadLine()) {
            # Continuous check while waiting for speech to finish
            if ($Parent -and $Parent.HasExited) { $p.Kill(); exit }
            
            if ($line -like '*SpeakCompleted*') { break }
            if ($line -like '*Error*') { break }
        }
    }
}

# Create signal file IMMEDIATELY so the game can start the next block
New-Item -Path "$DllDir\talkit_done_$Req.tmp" -ItemType File -Force

Send @{"Cmd"="Close"}
if (!$p.WaitForExit(1000)) { $p.Kill() }
