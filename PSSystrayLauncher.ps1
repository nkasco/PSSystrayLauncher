#Load necessary assemblies
Add-Type -AssemblyName 'System.Windows.Forms'
​
Add-Type -Name Window -Namespace Console -MemberDefinition '
   [DllImport("Kernel32.dll")]
   public static extern IntPtr GetConsoleWindow();

   [DllImport("user32.dll")]
   public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

function Start-ShowConsole {
   $PSConsole = [Console.Window]::GetConsoleWindow()
   [Console.Window]::ShowWindow($PSConsole, 5)
}

function Start-HideConsole {
   $PSConsole = [Console.Window]::GetConsoleWindow()
   [Console.Window]::ShowWindow($PSConsole, 0)
}
​
function New-MenuItem{
   param(
       [string]
       $Text = "Placeholder Text",
​
       $MyScriptPath,
       
       [switch]
       $ExitOnly = $false
   )
​
   #Initialization
   $MenuItem = New-Object System.Windows.Forms.MenuItem
​
   #Apply desired text
   if($Text){
       $MenuItem.Text = $Text
   }
​
   #Apply click event logic
   if($MyScriptPath -and !$ExitOnly){
       $MenuItem | Add-Member -Name MyScriptPath -Value $MyScriptPath -MemberType NoteProperty
       $MenuItem.Add_Click({
           try{
               $MyScriptPath = $This.MyScriptPath #Used to find proper path during click event
               
               if(Test-Path $MyScriptPath){
                   Start-Process -FilePath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-NoProfile -NoLogo -ExecutionPolicy Bypass -File `"$MyScriptPath`"" -ErrorAction Stop
               } else {
                   throw "Could not find at path: $MyScriptPath"
               }
           } catch {
               $Text = $This.Text
               [System.Windows.Forms.MessageBox]::Show("Failed to launch $Text`n`n$_") > $null
           }
       })
   }
​
   #Provide a way to exit the launcher
   if($ExitOnly -and !$MyScriptPath){
       $MenuItem.Add_Click({
           $Form.Close()
​
           #Handle any hung processes
           Stop-Process $PID
       })
   }
​
   #Return our new MenuItem
   $MenuItem
}
​
#Create Form to serve as a container for our components
$Form = New-Object System.Windows.Forms.Form
​
#Configure our form to be hidden
$Form.BackColor = "Magenta" #Pick a color you won't use again and match it to the TransparencyKey property
$Form.TransparencyKey = "Magenta"
$Form.ShowInTaskbar = $false
$Form.FormBorderStyle = "None"
​
#Initialize/configure necessary components
$SystrayLauncher = New-Object System.Windows.Forms.NotifyIcon
$SystrayIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe")
$SystrayLauncher.Icon = $SystrayIcon
$SystrayLauncher.Text = "PowerShell Launcher"
$SystrayLauncher.Visible = $true
​
$ContextMenu = New-Object System.Windows.Forms.ContextMenu
​
$LoggedOnUser = New-MenuItem -Text "Get Logged On User" -MyScriptPath "C:\scripts\GetLoggedOn.ps1"
$RestartRemoteComputer = New-MenuItem -Text "Restart Remote PC" -MyScriptPath "C:\scripts\restartpc.ps1"
$ExitLauncher = New-MenuItem -Text "Exit" -ExitOnly
​
#Add menu items to context menu
$ContextMenu.MenuItems.AddRange($LoggedOnUser)
$ContextMenu.MenuItems.AddRange($RestartRemoteComputer)
$ContextMenu.MenuItems.AddRange($ExitLauncher)
​
#Add components to our form
$SystrayLauncher.ContextMenu = $ContextMenu
​
#Launch
Start-HideConsole
$Form.ShowDialog() > $null
Start-ShowConsole
