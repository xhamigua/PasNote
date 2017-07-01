program WinBoot;

{$R '..\res\R4.res' '..\res\R4.rc'}

uses
  Forms,
  UMain in '..\SRC\UMain.pas' {FormWinboot};

{$R *.res}

begin
  Application.Initialize;
//  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormWinboot, FormWinboot);
  Application.Run;
end.
