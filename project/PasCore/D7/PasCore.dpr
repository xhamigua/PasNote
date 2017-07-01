//{$INCLUDE '..\TypeDef.INC'}
//{$IFDEF Pdll}
//library PasCore;
//{$ELSE}
program PasCore;
//{$ENDIF}

uses
  SysUtils,
  Classes,
  Forms,
  Uimain in '..\FRM\Uimain.pas' {Form1},
  UFile in '..\SRC\UFile.pas',
  UCommon in '..\SRC\UCommon.pas';

//{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
