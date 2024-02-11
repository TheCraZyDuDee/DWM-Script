#Silly Script made by crusty & OpenAI's GPT-3
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

# Function to check if PsSuspend is already downloaded
function Is-PsSuspendDownloaded {
    return Test-Path -Path $PsSuspendPath
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

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-WindowStyle Hidden -File `"$scriptPath`""
    exit
}

# Check if PsSuspend is already downloaded
if (-not (Is-PsSuspendDownloaded)) {
    # Prompt to download PsSuspend
    $downloadChoice = [System.Windows.Forms.MessageBox]::Show("PsSuspend is required to run this script. Do you want to download it now?", "Download PsSuspend", "YesNo", "Warning")

    if ($downloadChoice -eq "Yes") {
        if (-not (Download-PsSuspend)) {
            Log-Message "Failed to download PsSuspend. Exiting script."
            [System.Windows.Forms.MessageBox]::Show("Failed to download PsSuspend. Exiting script.", "Error", "OK", "Error")
            exit
        }
    } else {
        Log-Message "PsSuspend is required to run this script. Exiting."
        [System.Windows.Forms.MessageBox]::Show("PsSuspend is required to run this script. Exiting.", "Error", "OK", "Error")
        exit
    }
}

# Function to check if DWM is enabled
function Is-DWMEnabled {
    return (Get-Process -Name "dwm" -ErrorAction SilentlyContinue) -ne $null
}

# Function to suspend winlogon
function Suspend-Winlogon {
    try {
        Start-Process -FilePath "$PsSuspendPath" -ArgumentList "winlogon.exe" -NoNewWindow -Wait -ErrorAction Stop
        Log-Message "Winlogon suspended successfully"
        return $true
    }
    catch {
        Log-Message "Failed to suspend Winlogon: $_"
        return $false
    }
}

# Function to resume winlogon
function Resume-Winlogon {
    try {
        Start-Process -FilePath "$PsSuspendPath" -ArgumentList "-r winlogon.exe" -NoNewWindow -Wait -ErrorAction Stop
        Log-Message "Winlogon resumed successfully"
        return $true
    }
    catch {
        Log-Message "Failed to resume Winlogon: $_"
        return $false
    }
}

# Function to disable DWM
function Disable-DWM {
    try {
        if (-not (Suspend-Winlogon)) {
            throw "Failed to suspend Winlogon"
        }
        
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
        if (-not (Resume-Winlogon)) {
            throw "Failed to resume Winlogon"
        }
        
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

# Main script
try {
    # Display GUI
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "DWM Script"
    $form.Size = New-Object System.Drawing.Size(300,200)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = 'FixedDialog'
    $form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#00245c")  # Set background color

    # Welcome message
    $welcomeLabel = New-Object System.Windows.Forms.Label
    $welcomeLabel.Location = New-Object System.Drawing.Point(20,20)
    $welcomeLabel.Size = New-Object System.Drawing.Size(260,20)
    $welcomeLabel.Text = "Welcome, $($env:USERNAME)!"
    $welcomeLabel.ForeColor = [System.Drawing.Color]::White
    $form.Controls.Add($welcomeLabel)

    # Disable DWM button
    $disableButton = New-Object System.Windows.Forms.Button
    $disableButton.Location = New-Object System.Drawing.Point(30,60)
    $disableButton.Size = New-Object System.Drawing.Size(100,30)
    $disableButton.Text = "Disable DWM"
    $disableButton.BackColor = [System.Drawing.Color]::White
    $disableButton.Add_Click({ 
        if (Disable-DWM) {
            [System.Windows.Forms.MessageBox]::Show("DWM disabled successfully", "Success", "OK", "Information")
        } else {
            [System.Windows.Forms.MessageBox]::Show("Failed to disable DWM", "Error", "OK", "Error")
        }
    })
    $form.Controls.Add($disableButton)

    # Enable DWM button
    $enableButton = New-Object System.Windows.Forms.Button
    $enableButton.Location = New-Object System.Drawing.Point(150,60)
    $enableButton.Size = New-Object System.Drawing.Size(100,30)
    $enableButton.Text = "Enable DWM"
    $enableButton.BackColor = [System.Drawing.Color]::White
    $enableButton.Add_Click({ 
        if (Enable-DWM) {
            [System.Windows.Forms.MessageBox]::Show("DWM enabled successfully", "Success", "OK", "Information")
        } else {
            [System.Windows.Forms.MessageBox]::Show("Failed to enable DWM", "Error", "OK", "Error")
        }
    })
    $form.Controls.Add($enableButton)

    # Open Task Manager button
    $taskManagerButton = New-Object System.Windows.Forms.Button
    $taskManagerButton.Location = New-Object System.Drawing.Point(90,110)
    $taskManagerButton.Size = New-Object System.Drawing.Size(120,30)
    $taskManagerButton.Text = "Open Task Manager"
    $taskManagerButton.BackColor = [System.Drawing.Color]::White
    $taskManagerButton.Add_Click({ 
        if (Open-TaskManager) {
            [System.Windows.Forms.MessageBox]::Show("Task Manager opened successfully", "Success", "OK", "Information")
        } else {
            [System.Windows.Forms.MessageBox]::Show("Failed to open Task Manager", "Error", "OK", "Error")
        }
    })
    $form.Controls.Add($taskManagerButton)

    $form.ShowDialog() | Out-Null
}
catch {
    Log-Message "An error occurred: $_"
    [System.Windows.Forms.MessageBox]::Show("An error occurred. Please check the log for details.", "Error", "OK", "Error")
}
finally {
    $form.Dispose()
}
