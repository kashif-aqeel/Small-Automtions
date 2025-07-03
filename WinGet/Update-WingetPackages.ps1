# Define global variables for paths
#$logDirectory = "D:\wip\winget"
$logDirectory = "C:\Tools\WinGet"
$permanentLog = Join-Path $logDirectory "winget.log"
$tempLog = Join-Path $logDirectory "temp_log.txt"

$infoEnabled = 1
$debugEnabled = 1
$traceEnabled = 0

$testMode = 0
$testInput = Join-Path $logDirectory "test-input.txt"
$testOutput = Join-Path $logDirectory "test-output.txt"

function Initialize {

    Debug "Initializing environment..."
    # Ensure the log directory exists
    if (-not (Test-Path $logDirectory)) {
        New-Item -Path $logDirectory -ItemType Directory -Force
    }

    # Remove previous temp log if it exists
    if (Test-Path $tempLog) {
        Remove-Item -Path $tempLog -Force
    }

    # Add timestamp to permanent log
    Add-Content -Path $permanentLog -Value "`r`n============================== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==============================`r`n"
    Debug "Initialization complete."
}
function Cleanup {
    # Optionally delete the temp log
    if (Test-Path $tempLog) {
        Remove-Item -Path $tempLog -Force
    }

    Debug "Cleaned up"
}
function Trace{
    param (
        [string]$message
    )

    if($traceEnabled -eq 1){
        Write-Host $message
    }
}
function Debug{
    param (
        [string]$message
    )

    if($debugEnabled -eq 1){
        Write-Host $message
    }
}
function Info{
    param (
        [string]$message
    )

    if($infoEnabled -eq 1){
        Write-Host $message
    }
}
function TraceCleanStep{
    param (
        [int]$number,
        [string]$message
    )
    Trace "------------------------------ Clean Step $($number) ------------------------------"
    Trace $message
}

function Clean-Winget-Log {
    param (
        [string]$LogText
    )

    Debug "Cleaning up winget log..."
    $result = $LogText
    
    # Filter out unwanted spinner characters
    $result = $result -replace "\s*[\|\\\/\-]\s*\r\n", "`r`n"
    TraceCleanStep -number 1 -message $result

    # Filter out unwanted progress bar characters
    $result = $result -replace "[█▒]", ""
    TraceCleanStep -number 2 -message $result

    # Filter out other unwanted junk characters
    $result = $result -replace "[�]", ""
    TraceCleanStep -number 3 -message $result

    # Filter out progress percentages.
    $result = $result -replace "\d+%", ""
    TraceCleanStep -number 4 -message $result

    # Filter out progress download file sizes.
    $result = $result -replace "(\b\d+\.*\d*\b [KM]B)+(\s*/\s*\b\d+\.*\d*\b [KM]B)*", ""
    TraceCleanStep -number 5 -message $result

    # Replace 2 or more consecutive empty lines with just one empty line
    $result = $result -replace "(\s*\r\n){3}", "`r`n`r`n"
    $result = $result -replace "(\s*\r\n){3}", "`r`n`r`n"
    $result = $result -replace "(\s*\r\n){3}", "`r`n`r`n"
    TraceCleanStep -number 6 -message $result

    Debug "Cleanup complete."
    return $result
}

function Update-AllPackages{
    # Run winget and redirect output (stdout + stderr) to temporary file
    Start-Process -FilePath "winget" `
                -ArgumentList "upgrade --all --silent --accept-source-agreements --accept-package-agreements" `
                -NoNewWindow `
                -RedirectStandardOutput $tempLog `
                -Wait

                #-RedirectStandardError $tempLog `

    $logTextArray = Get-Content -Path $tempLog
    #Write-Host $wingetLog
    #Add-Content -Path $permanentLog -Value $wingetLog

    # Join lines into a single string with newlines
    $logText = $logTextArray -join "`r`n"

    return $logText
}

function Get-TestInput{
    $logTextArray = Get-Content -Path $testInput

    # Join lines into a single string with newlines
    $logText = $logTextArray -join "`r`n"

    return $logText
}

function Main {

    Clear-Host

    Info "Starting up..."
    Initialize

    if($testMode -eq 0){
        Info "Running WinGet..."
        $wingetLog = Update-AllPackages
    }
    else {
        $wingetLog = Get-TestInput
    }

    Trace "============================== Original =============================="
    Trace $wingetLog

    $cleanedText = Clean-Winget-Log -LogText $wingetLog

    Trace "============================== Cleaned =============================="
    Trace $cleanedText

    # Append cleaned and processed content to permanent log
    Debug "Writing log..."
    if($testMode -eq 0){
        Add-Content -Path $permanentLog -Value $cleanedText
    }
    else {
        Add-Content -Path $testOutput -Value $cleanedText
    }

    Cleanup
    Info "All done."
}

Main
