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
  UCommon in '..\SRC\UCommon.pas';

//{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormPas, FormPas);
  Application.Run;
end.
