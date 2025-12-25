!include MUI2.nsh
!include LogicLib.nsh
!include nsDialogs.nsh
!include "WinVer.nsh"
!include "x64.nsh"

; Macro to check if a requirement is installed
!macro CheckRequirement REQUIREMENT_NAME COMMAND VAR_RESULT
  nsExec::ExecToStack '${COMMAND}'
  Pop $0
  Pop $1
  
  ${If} $0 != 0
    StrCpy ${VAR_RESULT} "0" ; Not installed
  ${Else}
    StrCpy ${VAR_RESULT} "1" ; Installed
  ${EndIf}
!macroend

; Variables for requirement status
Var Dialog
Var ReqListBox
Var NodeStatus
Var StatusLabel
Var NodeInstallAttempted

; Variables for System Requirements (Hardware/OS)
Var SysReqDialog
Var SysReqLabel
Var OSResult
Var ArchResult

; Function to install Node.js silently
Function InstallNodeJS
  DetailPrint "Installing Node.js..."
  
  ; Execute Node.js installer silently from temp location
  ; /quiet = silent install, /norestart = don't restart after install
  ExecWait '"$TEMP\node-v24.12.0-x64.msi" /quiet /norestart' $0
  
  ${If} $0 == 0
    DetailPrint "Node.js installation completed successfully"
    
    ; Refresh environment variables
    ; This is needed so node command is available in PATH
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
    
    ; Manually refresh PATH for current process
    ReadRegStr $1 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
    System::Call 'Kernel32::SetEnvironmentVariable(t "PATH", t "$1")i.r2'
    
    ; Wait a moment for installation to finalize
    Sleep 3000
    
    ; Re-check if Node.js is now available
    !insertmacro CheckRequirement "Node.js" "node --version" $NodeStatus
    
    ${If} $NodeStatus == "1"
      DetailPrint "Node.js verified successfully"
    ${Else}
      DetailPrint "Warning: Node.js installed but not immediately available. May require system restart."
    ${EndIf}
  ${Else}
    DetailPrint "Node.js installation failed with error code: $0"
  ${EndIf}
FunctionEnd

; Function to check requirements and show custom page
Function CheckRequirementsPage
  nsDialogs::Create 1018
  Pop $Dialog
  
  ${If} $Dialog == error
    Abort
  ${EndIf}
  
  ; Title
  ${NSD_CreateLabel} 0 0 100% 12u "System Requirements Check"
  Pop $0
  
  ; Create ListBox for results
  ${NSD_CreateListBox} 0 20u 100% 70u ""
  Pop $ReqListBox

  ; Check Node.js only
  !insertmacro CheckRequirement "Node.js" "node --version" $NodeStatus
  ${If} $NodeStatus == "1"
    SendMessage $ReqListBox ${LB_ADDSTRING} 0 "STR:Node.js: Installed"
  ${Else}
    SendMessage $ReqListBox ${LB_ADDSTRING} 0 "STR:Node.js: Missing (will be installed automatically)"
  ${EndIf}

  ; Status message
  ${If} $NodeStatus == "1"
    ${NSD_CreateLabel} 0 95u 100% 24u "Node.js is installed. You can proceed with the installation."
    Pop $StatusLabel
  ${Else}
    ${NSD_CreateLabel} 0 95u 100% 40u "Node.js is not installed.$\nThe installer will automatically install Node.js for you."
    Pop $StatusLabel
  ${EndIf}
  
  nsDialogs::Show
FunctionEnd

Function CheckRequirementsPageLeave
  ; If Node.js is not installed, install it now
  ${If} $NodeStatus != "1"
    StrCpy $NodeInstallAttempted "1"
    
    MessageBox MB_ICONINFORMATION|MB_OK "Node.js will now be installed automatically.$\nThis may take a few minutes."
    
    ; Extract Node.js installer to temp location
    SetOutPath "$TEMP"
    File "prerequisites\node-v24.12.0-x64.msi"
    
    Call InstallNodeJS
    
    ; Clean up temp file
    Delete "$TEMP\node-v24.12.0-x64.msi"
    
    ; Check final status
    ${If} $NodeStatus != "1"
      MessageBox MB_ICONEXCLAMATION|MB_OKCANCEL "Node.js installation completed, but the node command is not immediately available.$\n$\nThis usually means a system restart is required for the changes to take effect.$\n$\nClick OK to continue anyway (you may need to restart later)$\nor Cancel to abort the installation." IDOK continue
      Abort
      continue:
      DetailPrint "User chose to continue despite Node.js not being immediately available"
    ${EndIf}
  ${EndIf}
FunctionEnd

Function CheckSysReqPage
  nsDialogs::Create 1018
  Pop $SysReqDialog

  ${If} $SysReqDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 12u "System Compatibility Check"
  Pop $0

  ; Check OS
  ${If} ${AtLeastWin10}
    StrCpy $OSResult "Windows 10 or later: Detected (Pass)"
  ${Else}
    StrCpy $OSResult "Windows 10 or later: Not Detected (Fail)"
  ${EndIf}
  ${NSD_CreateLabel} 0 20u 100% 12u $OSResult
  Pop $0

  ; Check Architecture
  ${If} ${RunningX64}
    StrCpy $ArchResult "64-bit Architecture: Detected (Pass)"
  ${Else}
    StrCpy $ArchResult "64-bit Architecture: Not Detected (Fail)"
  ${EndIf}
  ${NSD_CreateLabel} 0 35u 100% 12u $ArchResult
  Pop $0

  ; Summary
  ${If} ${AtLeastWin10}
  ${AndIf} ${RunningX64}
    ${NSD_CreateLabel} 0 60u 100% 24u "System compatibility check passed."
  ${Else}
    ${NSD_CreateLabel} 0 60u 100% 48u "System compatibility check failed.$\nPlease ensure you are running Windows 10 (or later) 64-bit."
  ${EndIf}

  nsDialogs::Show
FunctionEnd

Function CheckSysReqPageLeave
  ${If} ${AtLeastWin10}
  ${AndIf} ${RunningX64}
    ; Proceed
  ${Else}
    MessageBox MB_ICONSTOP|MB_OK "System requirements not met.$\nInstallation cannot continue."
    Abort
  ${EndIf}
FunctionEnd

Name "GigBim Labs"
OutFile "GigBimLabs-Setup.exe"
; Use dynamic default under current user's AppData\Roaming
InstallDir "$APPDATA\Autodesk\Revit\Addins\2024"
RequestExecutionLevel admin

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.txt"
; System requirements check
Page custom CheckSysReqPage CheckSysReqPageLeave
; Software requirements check (Node.js)
Page custom CheckRequirementsPage CheckRequirementsPageLeave
; Allow user to change install directory
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages
!insertmacro MUI_LANGUAGE "English"

; Initialize variables
Function .onInit
  StrCpy $NodeInstallAttempted "0"
FunctionEnd

Section "Install"
  SetOutPath "$INSTDIR"
  ; Copy all files from the app folder
  File /r "app\*.*"

  WriteUninstaller "$INSTDIR\revit_ai_plugin\Uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GigBimLabs" "DisplayName" "GigBim Labs Add-in"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GigBimLabs" "UninstallString" "$INSTDIR\revit_ai_plugin\Uninstall.exe"
SectionEnd

Section "Uninstall"
  ; Remove the specific .addin manifest file from the main directory
  Delete "$INSTDIR\revit-ai-plugin.addin"

  ; Remove the plugin specific directory (contains the DLLs and the uninstaller itself)
  ; The uninstaller will delete itself which is standard behavior
  RMDir /r "$INSTDIR\revit_ai_plugin"

  ; Remove uninstall registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GigBimLabs"
SectionEnd