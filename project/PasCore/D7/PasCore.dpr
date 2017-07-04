{$INCLUDE '..\TypeDef.INC'}
{$IFNDEF Pdll}
program PasCore;
{$ELSE}
library PasCore;
{$ENDIF}

uses
  SysUtils,
  Classes,
  Forms,
  Graphics,
  Uimain in '..\FRM\Uimain.pas' {FormPas},
  UFile in '..\SRC\UFile.pas',
  UCommon in '..\SRC\UCommon.pas',
  UKeyboard in '..\SRC\UKeyboard.pas',
  UMd5Code in '..\SRC\UMd5Code.pas';

//{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormPas, FormPas);
  Application.Run;
end.
