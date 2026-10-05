; TurtleNeck Windows installer (Inno Setup 6)
; Built by build.ps1:  ISCC /DAppVersion=1.2.3 installer.iss
; Keep this file ASCII-only.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{6D1B6A52-3F3E-4C7B-9F0E-6C2B2E1E7A11}
AppName=TurtleNeck
AppVersion={#AppVersion}
AppVerName=TurtleNeck {#AppVersion}
AppPublisher=kpryu6
AppPublisherURL=https://kpryu6.github.io/turtleneck/
AppSupportURL=https://github.com/kpryu6/turtleneck/issues
VersionInfoVersion={#AppVersion}
; Per-user install without an admin prompt. Same folder and shortcuts as install.ps1,
; so installing both ways never leaves two copies.
PrivilegesRequired=lowest
DefaultDirName={localappdata}\TurtleNeck
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=yes
OutputDir=dist
OutputBaseFilename=TurtleNeck-Setup
SetupIconFile=build\turtleneck.ico
UninstallDisplayIcon={app}\TurtleNeck.exe
UninstallDisplayName=TurtleNeck
WizardStyle=modern
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=force
RestartApplications=no

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[InstallDelete]
; Start each upgrade from a clean bundle so files from older builds don't linger
Type: filesandordirs; Name: "{app}\_internal"

[Files]
Source: "dist\TurtleNeck\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{userprograms}\TurtleNeck"; Filename: "{app}\TurtleNeck.exe"; WorkingDir: "{app}"
Name: "{userdesktop}\TurtleNeck"; Filename: "{app}\TurtleNeck.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Registry]
; The app's "Launch at login" setting writes this value; remove it on uninstall
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "TurtleNeck"; Flags: dontcreatekey uninsdeletevalue

[Run]
Filename: "{app}\TurtleNeck.exe"; Description: "{cm:LaunchProgram,TurtleNeck}"; Flags: nowait postinstall skipifsilent

[Code]
// TurtleNeck lives in the tray and may not react to Restart Manager's close
// request, so make sure it's not running before files are replaced or removed.
procedure StopTurtleNeck();
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM TurtleNeck.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function InitializeSetup(): Boolean;
begin
  StopTurtleNeck();
  Result := True;
end;

function InitializeUninstall(): Boolean;
begin
  StopTurtleNeck();
  Result := True;
end;
