; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)

;SignTool=signtool
#define AppVersion GetFileVersion("{#SourcePath}\..\..\bin\win32\local-link-messaging-host\local-link-messaging-host.exe")
#define AppName "Local file links Native Messaging API Host"

AppId={{318A38DD-A431-42F0-BBAB-58C330AC545F}
AppName={#AppName} v{#AppVersion}
AppVerName={#AppName} {#AppVersion}
VersionInfoVersion={#AppVersion}
AppVersion={#AppVersion}
;AppVerName=Local file links Native Messaging API Host
AppPublisher=feinstaub/webextension_local_filesystem_links
AppPublisherURL=https://github.com/feinstaub/webextension_local_filesystem_links
AppSupportURL=https://github.com/feinstaub/webextension_local_filesystem_links
AppUpdatesURL=https://github.com/feinstaub/webextension_local_filesystem_links
DefaultDirName={%USERPROFILE}\{#AppName}
DisableDirPage=yes
DefaultGroupName=Local file links Native Messaging API Host
DisableProgramGroupPage=yes
OutputDir={#SourcePath}\..\..\bin\win32
OutputBaseFilename=native-app-setup
Compression=lzma
UninstallDisplayIcon={#SourcePath}\..\..\src\addon_icon_48.ico
SetupIconFile={#SourcePath}\..\..\src\addon_icon_48.ico
SolidCompression=yes
PrivilegesRequired=lowest

[Tasks]
Name: Visualc; Description: Install Visual C++ re-distributable (required for the app - install if not already available); Flags: unchecked

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "{#SourcePath}\..\..\bin\win32\local-link-messaging-host\*"; DestDir: "{app}"; Flags: recursesubdirs
Source: "{#SourcePath}\..\..\src\webextension_local_filesystem_links_win.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\..\..\build\windows\vcredist_x86.exe"; DestDir: "{app}"; AfterInstall: RunOtherInstaller; Tasks: Visualc; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
; Name: "{group}\Local file links Native Messaging API Host"; Filename: "{app}\local-link-messaging-host.exe"

[Registry]
Root: HKLM; Subkey: "Software\Mozilla\NativeMessagingHosts\webextension_local_filesystem_links"; ValueType: string; ValueName: ""; ValueData: "{app}\webextension_local_filesystem_links_win.json"; Flags: uninsdeletekey; Check: not IsWin64 and isElevated
Root: HKLM64; Subkey: "Software\Mozilla\NativeMessagingHosts\webextension_local_filesystem_links"; ValueType: string; ValueName: ""; ValueData: "{app}\webextension_local_filesystem_links_win.json"; Flags: uninsdeletekey; Check: IsWin64 and IsElevated
Root: HKCU; Subkey: "Software\Mozilla\NativeMessagingHosts\webextension_local_filesystem_links"; ValueType: string; ValueName: ""; ValueData: "{app}\webextension_local_filesystem_links_win.json"; Flags: uninsdeletekey; Check: not IsElevated; 

[Code]
var
  Page: TInputOptionWizardPage;
  InstallationOnlyMe: Boolean;

procedure InitializeWizard;
begin
  // Create the page
  Page := CreateInputOptionPage(wpWelcome,
    'Installation type', 'Install for all users or only current user?',
    'By selecting "All users" it will install the native app to program folder which requires elevated rights.',
    True, False);

  // Add items
  Page.Add('Only current user');
  Page.Add('All users');
  

  // Set initial values (default to current unser)
  Page.Values[0] := True;
end;

// check if elevated
function IsElevated: Boolean;
begin
  Result := IsAdminLoggedOn or IsPowerUserLoggedOn;
end;

procedure ExitProcess(uExitCode: UINT);
  external 'ExitProcess@kernel32.dll stdcall';
function ShellExecute(hwnd: HWND; lpOperation: string; lpFile: string;
  lpParameters: string; lpDirectory: string; nShowCmd: Integer): THandle;
  external 'ShellExecuteW@shell32.dll stdcall';

// elevate installer
// code from here https://stackoverflow.com/questions/21556853/make-inno-setup-installer-request-privileges-elevation-only-when-needed        
// --> slightly modified
// NOT working and not used - at the moment just an info that admin rights are required to install for all users.
function Elevate: Boolean;
var
  I: Integer;
  RetVal: Integer;
  Params: string;
  S: string;
begin
  { Collect current instance parameters }
  for I := 1 to ParamCount do
  begin
    S := ParamStr(I);
    { Unique log file name for the elevated instance }
    if CompareText(Copy(S, 1, 5), '/LOG=') = 0 then
    begin
      S := S + '-elevated';
    end;
    { Do not pass our /SL5 switch }
    if CompareText(Copy(S, 1, 5), '/SL5=') <> 0 then
    begin
      Params := Params + AddQuotes(S) + ' ';
    end;
  end;

  { ... and add selected language }
  // Params := Params + '/LANG=' + ActiveLanguage;

  //Log(Format('Elevating setup with parameters [%s]', [Params]));
  Log(ExpandConstant('{srcexe}'));
  //RetVal := ShellExecute(0, 'runas', ExpandConstant('{srcexe}'), Params, '', SW_SHOW);
  RetVal := ShellExecute(WizardForm.handle, 'runas', ExpandConstant('{srcexe}'), '', '', SW_SHOW);
  Log(Format('Running elevated setup returned [%d]', [RetVal]));
  Result := (RetVal > 32);
  { if elevated executing of this setup succeeded, then... }
  if Result then
  begin
    Log('Elevation succeeded');
    { exit this non-elevated setup instance }
    ExitProcess(0);
  end
    else
  begin
    Log(Format('Elevation failed [%s]', [SysErrorMessage(RetVal)]));
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var dest: String;
var res: Boolean;
begin
  
  res := True
  Log('NextButtonClick(' + IntToStr(CurPageID) + ') called');
  if (CurPageID = 100) then 
    begin
      // Read values into variables
      InstallationOnlyMe := Page.Values[0];
      if InstallationOnlyMe then
        dest := ExpandConstant('{%USERPROFILE}\{#AppName}');
      
      if not InstallationOnlyMe or (isElevated and WizardSilent) then
        // selected all user or running silently with elevated right
        dest := ExpandConstant('{pf}\{#AppName}');
        //if IsElevated = False then
        //  elevate
        //end;
        //WriteRegKey

      //test := IsElevated
      // todo --> request elevated rights for pf
      WizardForm.DirEdit.Text := dest;
      if IsElevated or InstallationOnlyMe then
        res := True
      else
        begin
          MsgBox('Administrator privileges required to install for all users. Please restart setup with the correct rights or install for current user.',mbError, MB_OK)
          res := False
        end;
    end;
  Result := res
end;

// check HKCU for onlyMe or HKLM for allUsers
function CheckKeyLocation() : Boolean;
//var
//  Version: TWindowsVersion;
begin
  Result := InstallationOnlyMe;
end;

procedure RunOtherInstaller;

var
  ResultCode: Integer;

begin
  if not ShellExec('runas', ExpandConstant('{app}\vcredist_x86.exe'), '', '', SW_SHOW,
          ewWaitUntilTerminated, ResultCode)
  then
    MsgBox('Other installer failed to run!' + #13#10 +
      SysErrorMessage(ResultCode), mbError, MB_OK);
end;

