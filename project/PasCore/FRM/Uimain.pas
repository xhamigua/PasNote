unit Uimain;
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFile, UCommon,
  Dialogs, StdCtrls;

type
  TFormPas = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormPas: TFormPas;

implementation

{$R *.dfm}

procedure TFormPas.Button1Click(Sender: TObject);
begin
  ShowBox('test');
  LogFun('asdasd');
  //ShowBox(ReadFileToHex('C:\1.pas'));
  //ShowBox(ReadFileToTen('C:\1.pas'));

end;

end.
