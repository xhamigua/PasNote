{$INCLUDE '..\IVersion.INC'}
{$IFNDEF Pdll}
program RealPlayer;
{$ELSE}
library RealPlayer;
{$ENDIF}

{$IFDEF PResdll}
  {$R '..\res\resdll.res' '..\res\resdll.rc'}
{$ENDIF}

{$R '..\res\PlayRES.res' '..\res\PlayRES.rc'}
{$R '..\BPL\VolRes.res' '..\BPL\VolRes.rc'}


uses
  Forms,
  SysUtils,
  RealBar in '..\BPL\RealBar.pas',
  Magnetic in '..\src\Magnetic.pas',
  UCommon in '..\src\UCommon.pas',
  UFrmConfig in '..\src\UFrmConfig.pas' {FConfig},
  UPlayer in '..\src\UPlayer.pas' {FPlay},
  UVolumeCtrlBar in '..\BPL\UVolumeCtrlBar.pas';

//{$R *.res}
{$IFNDEF Pdll}
var
  ICMD:Integer;
{$ENDIF}
begin
  {$IFDEF PResdll}
  if not FileExists(CLibAVPath+'avcodec-55.dll') then
  begin
    ForceDirectories(CLibAVPath);
    ExtractRes('avcodec',CLibAVPath,'avcodec-55.dll');
    ExtractRes('avformat',CLibAVPath,'avformat-55.dll');
    ExtractRes('avfilter',CLibAVPath,'avfilter-3.dll');
    ExtractRes('swscale',CLibAVPath,'swscale-2.dll');
    ExtractRes('SDL',CLibAVPath,'SDL.dll');
    ExtractRes('avutil',CLibAVPath,'avutil-52.dll');
    ExtractRes('avdevice',CLibAVPath,'avdevice-55.dll');
    ExtractRes('swresample',CLibAVPath,'swresample-0.dll');
  end;
  {$ENDIF}
{$IFDEF Pdll}
{$ELSE}
  Application.Initialize;
  {$IFDEF DELPHI_2010}
  Application.MainFormOnTaskbar := True;
  {$ENDIF}
  Application.Title := '';
  Application.CreateForm(TFPlay, FPlay);
  for ICMD := 1 to ParamCount do
  begin
    FPlay.LoadPlayFile(LowerCase(ParamStr(ICMD)));
    Break;
  end;
  Application.Run;
{$ENDIF}
end.
