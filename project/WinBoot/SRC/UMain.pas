unit UMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, jpeg;

type
  TFormWinboot = class(TForm)
    BtnBootWin7: TBitBtn;
    BtnAdd: TBitBtn;
    Image1: TImage;
    Label1: TLabel;
    BtnWin7: TBitBtn;
    procedure BtnBootWin7Click(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnWin7Click(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Label1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

const
  P4DOS:PAnsiChar='C:\BO.EXE /DEVICE=C: /mbr /install /type=grub4dos '+
  ' /mbr-disable-floppy  /mbr-disable-osbr /boot_file=HAMIGUA /auto';
  Pwin7:PAnsiChar='C:\BO.EXE /DEVICE=C: /mbr /install /type=nt60 /auto';

var
  FormWinboot: TFormWinboot;

implementation

{$R *.dfm}

function ExtractRes(ResType, ResName, ResNewName: string): boolean;
var
  Res: TResourceStream;
begin
  try
    Res := TResourceStream.Create(Hinstance, Resname, Pchar(ResType));
    try
      Res.SavetoFile(ResNewName);
      Result := true;
    finally
      Res.Free;
    end;
  except
    Result := false;
  end;
end;

procedure TFormWinboot.BtnBootWin7Click(Sender: TObject);
begin
  //删除c:\ 和D:\下的文件hamigua和bootice.exe
  DeleteFile('C:\hamigua');
  DeleteFile('D:\hamigua');
  //解压hamigua文件到D盘
  ExtractRes('exefile','dboot','C:\HAMIGUA');  //保稳
  ExtractRes('exefile','dboot','D:\HAMIGUA');
  //设置bootice.exe
  WinExec(P4DOS,SW_HIDE);
  ShowMessage('设置成功,将win7系统盘解压到非C:的盘符后重启.');
end;

procedure TFormWinboot.BtnWin7Click(Sender: TObject);
begin
  DeleteFile('c:\hamigua');
  WinExec(Pwin7,SW_HIDE);
  ShowMessage('清除成功!');
end;

procedure TFormWinboot.BtnAddClick(Sender: TObject);
begin
  //删除c:\hamigua
  DeleteFile('c:\hamigua');
  //解压hamigua文件到c盘
  ExtractRes('exefile','cboot','c:\HAMIGUA');
  //设置bootice.exe
  WinExec(P4DOS,SW_HIDE);
  ShowMessage('设置成功,重启后将有强大的boot菜单!');
end;

procedure TFormWinboot.FormCreate(Sender: TObject);
begin
  WinExec('cmd /c attrib -h -r -s c:\hamigua',SW_HIDE);
  WinExec('cmd /c attrib -h -r -s D:\hamigua',SW_HIDE);
  //解压bootice
  ExtractRes('exefile','BO','c:\BO.exe');
end;

procedure TFormWinboot.FormDestroy(Sender: TObject);
begin
  WinExec('cmd /c attrib +h +r +s c:\hamigua',SW_HIDE);
  WinExec('cmd /c attrib +h +r +s D:\hamigua',SW_HIDE);
  //删除bootice
  DeleteFile('C:\BO.EXE');
end;

procedure TFormWinboot.Image1Click(Sender: TObject);
begin
  WinExec('cmd /c attrib +h +r +s c:\hamigua',SW_HIDE);
  WinExec('cmd /c attrib +h +r +s D:\hamigua',SW_HIDE);
  //删除bootice
  DeleteFile('C:\BO.EXE');
  Close;
end;

procedure TFormWinboot.Label1Click(Sender: TObject);
begin
  WinExec('C:\Program Files\Internet Explorer\IEXPLORE.EXE http://blog.163.com/xhamigua',SW_MAXIMIZE);
end;

end.



