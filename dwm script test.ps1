# Script made by crusty & OpenAI's GPT-3
# Configuration
$LogPath = "$PSScriptRoot\dwm_script_log.txt"
$PsSuspendPath = "$PSScriptRoot\Tools\PSSuspend\PsSuspend.exe"
$PsSuspendDownloadURL = "https://live.sysinternals.com/pssuspend.exe"

# Function to log messages to a file
function Log-Message {
    param([string]$Message)
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Message = "$TimeStamp - $Message"
    Add-content -Path $LogPath -Value $Message
}

# Function to display a MessageBox
function Show-MessageBox {
    param(
        [string]$Message,
        [string]$Title,
        [string]$Icon,
        [string[]]$Buttons
    )
    Add-Type -AssemblyName System.Windows.Forms
    $buttonEnum = [System.Windows.Forms.MessageBoxButtons]::OK
    switch ($Buttons) {
        "YesNo" { $buttonEnum = [System.Windows.Forms.MessageBoxButtons]::YesNo }
        "OK" { $buttonEnum = [System.Windows.Forms.MessageBoxButtons]::OK }
        "OKCancel" { $buttonEnum = [System.Windows.Forms.MessageBoxButtons]::OKCancel }
        "AbortRetryIgnore" { $buttonEnum = [System.Windows.Forms.MessageBoxButtons]::AbortRetryIgnore }
        "RetryCancel" { $buttonEnum = [System.Windows.Forms.MessageBoxButtons]::RetryCancel }
        "YesNoCancel" { $buttonEnum = [System.Windows.Forms.MessageBoxButtons]::YesNoCancel }
        default { $buttonEnum = [System.Windows.Forms.MessageBoxButtons]::OK }
    }
    $result = [System.Windows.Forms.MessageBox]::Show($Message, $Title, $buttonEnum, $Icon)
    return $result
}

# Log start of the script
Log-Message "Starting the script"

# Function to check if DWM is enabled
function Is-DWMEnabled {
    return (Get-Process -Name "dwm" -ErrorAction SilentlyContinue) -ne $null
}

# Log whether DWM is enabled
Log-Message "Is DWM enabled? $(Is-DWMEnabled)"

# Function to disable DWM
function Disable-DWM {
    try {
        Start-Process -FilePath "$PsSuspendPath" -ArgumentList "winlogon.exe" -NoNewWindow -Wait -ErrorAction Stop
        Log-Message "Winlogon suspended successfully"
        
        $processesToStop = @("wallpaper32", "explorer", "dwm", "SearchApp", "TextInputHost", "StartMenuExperienceHost", "ShellExperienceHost")
        foreach ($processName in $processesToStop) {
            Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
        }
        
        Log-Message "DWM disabled successfully"
        return $true
    }
    catch {
        Log-Message "Failed to disable DWM: $_"
        return $false
    }
}

# Function to enable DWM
function Enable-DWM {
    try {
        Start-Process -FilePath "$PsSuspendPath" -ArgumentList "-r winlogon.exe" -NoNewWindow -Wait -ErrorAction Stop
        
        if (-not (Get-Process -Name "explorer" -ErrorAction SilentlyContinue)) {
            Start-Process -FilePath "explorer.exe" -ErrorAction Stop
            Log-Message "Explorer started"
        }
        
        Log-Message "DWM enabled successfully"
        return $true
    }
    catch {
        Log-Message "Failed to enable DWM: $_"
        return $false
    }
}

# Function to open Task Manager
function Open-TaskManager {
    try {
        Start-Process -FilePath "taskmgr.exe"
        Log-Message "Task Manager opened"
        return $true
    }
    catch {
        Log-Message "Failed to open Task Manager: $_"
        return $false
    }
}

# Function to open GitHub link
function Open-GitHubLink {
    try {
        Start-Process -FilePath "https://github.com/crustySenpai/DWM-Script"
        Log-Message "GitHub link opened"
        return $true
    }
    catch {
        Log-Message "Failed to open GitHub link: $_"
        return $false
    }
}

# Function to update DWM status label
function Update-DWMStatusLabel {
    if (Is-DWMEnabled) {
        $dwmStatusLabel.Text = "DWM Status: Enabled"
    } else {
        $dwmStatusLabel.Text = "DWM Status: Disabled"
    }
}

# Function to download PsSuspend
function Download-PsSuspend {
    try {
        Log-Message "Downloading PsSuspend..."
        $null = New-Item -Path (Split-Path -Path $PsSuspendPath) -ItemType Directory -Force
        Invoke-WebRequest -Uri $PsSuspendDownloadURL -OutFile $PsSuspendPath -ErrorAction Stop
        Log-Message "PsSuspend downloaded successfully"
        return $true
    }
    catch {
        Log-Message "Failed to download PsSuspend: $_"
        return $false
    }
}

# Function to check if PsSuspend is already downloaded
function Is-PsSuspendDownloaded {
    return Test-Path -Path $PsSuspendPath
}

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-WindowStyle Hidden -File `"$scriptPath`""
    exit
}

# Function to get Windows version and build number
function Get-WindowsVersionAndBuild {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $majorVersion = $os.Version.Split('.')[0]
    $minorVersion = $os.Version.Split('.')[1]
    $buildNumber = $os.BuildNumber
    return $majorVersion, $minorVersion, $buildNumber
}

# Check if OS is supported
$majorVersion, $minorVersion, $buildNumber = Get-WindowsVersionAndBuild

Log-Message "Detected OS Version: $majorVersion.$minorVersion (Build: $buildNumber)"

if ($majorVersion -eq 10 -and $buildNumber -lt 22000) {
    Log-Message "Supported OS detected: Windows 10"
} elseif ($majorVersion -eq 10 -and $buildNumber -ge 22000) {
    Log-Message "Unsupported OS detected: Windows 11"
    Show-MessageBox "OS not Supported!" "Error" "Error" @("OK")
    exit
} else {
    Log-Message "Unsupported OS detected: $majorVersion.$minorVersion (Build: $buildNumber)"
    Show-MessageBox "OS not Supported!" "Error" "Error" @("OK")
    exit
}

# Check if PsSuspend is already downloaded
if (-not (Is-PsSuspendDownloaded)) {
    Log-Message "PsSuspend is required to run this script. Prompting to download."
    # Prompt to download PsSuspend
    $downloadChoice = Show-MessageBox "PsSuspend is required to run this script. Do you want to download it now?" "Download PsSuspend" "Warning" @("YesNo")

    if ($downloadChoice -eq "Yes") {
        if (-not (Download-PsSuspend)) {
            Log-Message "Failed to download PsSuspend. Exiting script."
            Show-MessageBox "Failed to download PsSuspend. Exiting script." "Error" "Error" @("OK")
            exit
        }
    } else {
        Log-Message "PsSuspend is required to run this script. Exiting."
        Show-MessageBox "PsSuspend is required to run this script. Exiting." "Error" "Error" @("OK")
        exit
    }
}

# Main script
try {
    # Display GUI
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "DWM Script"
    $form.Size = New-Object System.Drawing.Size(300,160)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = 'FixedDialog'
    $form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#00245c")  # Set background color

    # GitHub button
    $githubButton = New-Object System.Windows.Forms.Button
    $githubButton.Location = New-Object System.Drawing.Point(150,80)
    $githubButton.Size = New-Object System.Drawing.Size(100,30)
    $githubButton.Text = "Github Page"
    $githubButton.BackColor = [System.Drawing.Color]::White
    $githubButton.Add_Click({ 
        Open-GitHubLink
    })
    $form.Controls.Add($githubButton)

    # Label to display DWM status
    $dwmStatusLabel = New-Object System.Windows.Forms.Label
    $dwmStatusLabel.Location = New-Object System.Drawing.Point(150,10)  # Adjusted position
    $dwmStatusLabel.Size = New-Object System.Drawing.Size(260,20)
    $dwmStatusLabel.ForeColor = [System.Drawing.Color]::White
    $form.Controls.Add($dwmStatusLabel)

    # Welcome message
    $welcomeLabel = New-Object System.Windows.Forms.Label
    $welcomeLabel.Location = New-Object System.Drawing.Point(30,10)
    $welcomeLabel.Size = New-Object System.Drawing.Size(260,20)
    $welcomeLabel.Text = "Welcome, $($env:USERNAME)!"
    $welcomeLabel.ForeColor = [System.Drawing.Color]::White
    $form.Controls.Add($welcomeLabel)

    # Update DWM status label when form loads
    $form.Add_Load({
        Update-DWMStatusLabel
    })

    # Disable DWM button
    $disableButton = New-Object System.Windows.Forms.Button
    $disableButton.Location = New-Object System.Drawing.Point(30,35)  # Adjusted position
    $disableButton.Size = New-Object System.Drawing.Size(100,30)
    $disableButton.Text = "Disable DWM"
    $disableButton.BackColor = [System.Drawing.Color]::White
    $disableButton.Add_Click({ 
        if (Disable-DWM) {
            Show-MessageBox "DWM disabled successfully" "Success" "Information" @("OK")
            Update-DWMStatusLabel  # Update label text
        } else {
            Show-MessageBox "Failed to disable DWM" "Error" "Error" @("OK")
        }
    })
    $form.Controls.Add($disableButton)

    # Enable DWM button
    $enableButton = New-Object System.Windows.Forms.Button
    $enableButton.Location = New-Object System.Drawing.Point(150,35)  # Adjusted position
    $enableButton.Size = New-Object System.Drawing.Size(100,30)
    $enableButton.Text = "Enable DWM"
    $enableButton.BackColor = [System.Drawing.Color]::White
    $enableButton.Add_Click({ 
        if (Enable-DWM) {
            Show-MessageBox "DWM enabled successfully" "Success" "Information" @("OK")
            Update-DWMStatusLabel  # Update label text
        } else {
            Show-MessageBox "Failed to enable DWM" "Error" "Error" @("OK")
        }
    })
    $form.Controls.Add($enableButton)

    # Open Task Manager button
    $taskManagerButton = New-Object System.Windows.Forms.Button
    $taskManagerButton.Location = New-Object System.Drawing.Point(30,80)  # Adjusted position
    $taskManagerButton.Size = New-Object System.Drawing.Size(100,30)
    $taskManagerButton.Text = "Task Manager"
    $taskManagerButton.BackColor = [System.Drawing.Color]::White
    $taskManagerButton.Add_Click({ 
        Open-TaskManager
    })

    $form.Controls.Add($taskManagerButton)

    $form.ShowDialog() | Out-Null
}
catch {
    Log-Message "An error occurred: $_"
    Show-MessageBox "An error occurred. Please check the log for details." "Error" "Error" @("OK")
}
finally {
    $form.Dispose()
}
