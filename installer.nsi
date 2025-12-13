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
Var DockerStatus
Var GoStatus
Var JavaStatus
Var PythonStatus
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
  
  ; Check Docker
  !insertmacro CheckRequirement "Docker" "docker --version" $DockerStatus
  ${If} $DockerStatus == "1"
    SendMessage $ReqListBox ${LB_ADDSTRING} 0 "STR:Docker: Installed"
  ${Else}
    SendMessage $ReqListBox ${LB_ADDSTRING} 0 "STR:Docker: Missing"
  ${EndIf}
  
  ; Check Go
  !insertmacro CheckRequirement "Go" "go version" $GoStatus
  ${If} $GoStatus == "1"
    SendMessage $ReqListBox ${LB_ADDSTRING} 0 "STR:Go (Golang): Installed"
  ${Else}
    SendMessage $ReqListBox ${LB_ADDSTRING} 0 "STR:Go (Golang): Missing"
  ${EndIf}
  
  ; Check Java
  !insertmacro CheckRequirement "Java" "java -version" $JavaStatus
  ${If} $JavaStatus == "1"
    SendMessage $ReqListBox ${LB_ADDSTRING} 0 "STR:Java: Installed"
  ${Else}
    SendMessage $ReqListBox ${LB_ADDSTRING} 0 "STR:Java: Missing"
  ${EndIf}
  
  ; Check Python
  !insertmacro CheckRequirement "Python" "python --version" $PythonStatus
  ${If} $PythonStatus == "1"
    SendMessage $ReqListBox ${LB_ADDSTRING} 0 "STR:Python: Installed"
  ${Else}
    SendMessage $ReqListBox ${LB_ADDSTRING} 0 "STR:Python: Missing"
  ${EndIf}
  
  ; Status message
  ${If} $DockerStatus == "1"
  ${AndIf} $GoStatus == "1"
  ${AndIf} $JavaStatus == "1"
  ${AndIf} $PythonStatus == "1"
    ${NSD_CreateLabel} 0 95u 100% 24u "All requirements are satisfied!$\nYou can proceed with the installation."
    Pop $StatusLabel
  ${Else}
    ${NSD_CreateLabel} 0 95u 100% 40u "Some requirements are missing!$\nPlease install the missing components above."
    Pop $StatusLabel
  ${EndIf}
  
  nsDialogs::Show
FunctionEnd

Function CheckRequirementsPageLeave
  ; Check if all requirements are met before proceeding
  ${If} $DockerStatus != "1"
  ${OrIf} $GoStatus != "1"
  ${OrIf} $JavaStatus != "1"
  ${OrIf} $PythonStatus != "1"
    MessageBox MB_ICONSTOP|MB_OK "Cannot proceed with installation.$\n$\nPlease install all missing requirements and run the installer again."
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
InstallDir "$PROGRAMFILES\GigBimLabs"
RequestExecutionLevel admin

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.txt"
Page custom CheckSysReqPage CheckSysReqPageLeave
Page custom CheckRequirementsPage CheckRequirementsPageLeave
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages
!insertmacro MUI_LANGUAGE "English"

Section "Install"
  SetOutPath "$INSTDIR"
  ; Copy all files from the app folder (place your files in installer\app)
  File /nonfatal /r "app\*.*"

  ; Create Start Menu shortcut
  CreateDirectory "$SMPROGRAMS\GigBimLabs"
  CreateShortCut "$SMPROGRAMS\GigBimLabs\GigBimLabs.lnk" "$INSTDIR\GigBimLabs.exe" "" "$INSTDIR\GigBimLabs.exe" 0

  ; Write uninstall
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Register uninstall info (for Add/Remove Programs)
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GigBimLabs" "DisplayName" "GigBim Labs"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GigBimLabs" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GigBimLabs" "DisplayIcon" "$INSTDIR\GigBimLabs.exe"
SectionEnd

Section "Uninstall"
  ; Remove Start Menu shortcut and folder
  Delete "$SMPROGRAMS\GigBimLabs\GigBimLabs.lnk"
  RMDir "$SMPROGRAMS\GigBimLabs"

  ; Remove installed files
  Delete "$INSTDIR\GigBimLabs.exe"
  ; Delete other files (wildcard)
  Delete "$INSTDIR\*.*"
  RMDir /r "$INSTDIR"

  ; Remove uninstall registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GigBimLabs"
SectionEnd