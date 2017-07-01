unit UCommon;
interface
uses
  Dialogs, Classes;

function OpenDlg(strdefault:string):string;stdcall;
function ExtractRes(ResName,ResPath, ResNewName: string): string;

implementation

function OpenDlg(strdefault:string):string;stdcall;
var
  open:TOpenDialog;
begin
  open:=TOpenDialog.Create(nil);
  if strdefault='' then open.InitialDir:='c:\'
  else
  open.InitialDir:= strdefault; //��ʼ·��
  if open.Execute() then
  begin
    if Length(open.FileName)<1 then Result:=''
    else
    Result:= open.FileName
  end;
  open.Free;
end;

function ExtractRes(ResName,ResPath, ResNewName: string): string;
//function ExtractRes(ResType, ResName,ResPath, ResNewName: string): boolean;
var
  Res: TResourceStream;
begin
  try
    Res := TResourceStream.Create(Hinstance, Resname, 'exefile');
    try
      Res.SavetoFile(pchar(ResPath+ResNewName));
      Result := '��ȡ: '+ResPath+ResNewName;
    finally
      Res.Free;
    end;
  except
    Result := '��ȡʧ��!';
  end;
//  ExtractRes('KeyDll','c:\','MyDll.dll');
  //  ExtractRes('exefile','KeyDll','MyDll.dll');
end;

end.
