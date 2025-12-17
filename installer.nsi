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

; Variables for System Requirements (Hardware/OS)
Var SysReqDialog
Var SysReqLabel
Var OSResult
Var ArchResult

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
    SendMessage $ReqListBox ${LB_ADDSTRING} 0 "STR:Node.js: Missing"
  ${EndIf}

  ; Status message
  ${If} $NodeStatus == "1"
    ${NSD_CreateLabel} 0 95u 100% 24u "Node.js is installed. You can proceed with the installation."
    Pop $StatusLabel
  ${Else}
    ${NSD_CreateLabel} 0 95u 100% 40u "Node.js is missing!$\nPlease install Node.js and run the installer again."
    Pop $StatusLabel
  ${EndIf}
  
  nsDialogs::Show
FunctionEnd

Function CheckRequirementsPageLeave
  ; Check if Node.js is installed before proceeding
  ${If} $NodeStatus != "1"
    MessageBox MB_ICONSTOP|MB_OK "Node.js is required to proceed.$\n$\nPlease install Node.js and run the installer again."
    Abort
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
; Allow user to change install directory
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages
!insertmacro MUI_LANGUAGE "English"

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