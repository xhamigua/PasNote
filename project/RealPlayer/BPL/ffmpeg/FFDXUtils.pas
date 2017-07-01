(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of some utils on DirectX.
 * Created by CodeCoolie@CNSW 2011/07/19 -> $Date:: 2012-05-29 #$
 *)

unit FFDXUtils;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  Winapi.Windows, System.Classes, Winapi.ActiveX;
{$ELSE}
  Windows, Classes, ActiveX;
{$ENDIF}

type
  TDeviceType = (dtVideo, dtAudio);
function EnumDirectShowInputDevices(ADevices: TStrings; AType: TDeviceType; APrefix: Boolean): Boolean; overload;
function EnumDirectShowInputDevices(ADevices: TStrings): Boolean; overload;

implementation

{$IFDEF FPC}
uses
  varutils;
{$ENDIF}

type
  ICreateDevEnum = interface(IUnknown)
    ['{29840822-5B84-11D0-BD3B-00A0C911CE86}']
    function CreateClassEnumerator(const clsidDeviceClass: TGUID;
        out ppEnumMoniker: IEnumMoniker; dwFlags: DWORD): HResult; stdcall;
  end;

function EnumDirectShowInputDevices(ADevices: TStrings; AType: TDeviceType; APrefix: Boolean): Boolean;
const
  // WDM Streaming Capture Devices
  //AM_KSCATEGORY_CAPTURE: TGUID = (D1:$65E8773D;D2:$8F56;D3:$11D0;D4:($A3,$B9,$00,$A0,$C9,$22,$31,$96));
  // Video Capture Sources
//  CLSID_VideoInputDeviceCategory: TGUID = (D1:$860BB310;D2:$5D01;D3:$11D0;D4:($BD,$3B,$00,$A0,$C9,$11,$CE,$86));
  // Audio Capture Sources
//  CLSID_AudioInputDeviceCategory: TGUID = (D1:$33D9A762;D2:$90C8;D3:$11D0;D4:($BD,$43,$00,$A0,$C9,$11,$CE,$86));
  IID_IPropertyBag: TGUID = '{55272A00-42CB-11CE-8135-00AA004BB851}';
  IID_ICreateDevEnum: TGUID = '{29840822-5B84-11D0-BD3B-00A0C911CE86}';
  CLSID_SystemDeviceEnum: TGUID = (D1:$62BE5D10;D2:$60EB;D3:$11D0;D4:($BD,$3B,$00,$A0,$C9,$11,$CE,$86));
  CDeviceCategories: array[TDeviceType] of TGUID = (
    (D1:$860BB310;D2:$5D01;D3:$11D0;D4:($BD,$3B,$00,$A0,$C9,$11,$CE,$86)),
    (D1:$33D9A762;D2:$90C8;D3:$11D0;D4:($BD,$43,$00,$A0,$C9,$11,$CE,$86)));
  CPrefixs: array[TDeviceType] of string = ('video', 'audio');
var
  CreateDevEnum: ICreateDevEnum;
  EnumMoniker: IEnumMoniker;
  Moniker: IMoniker;
  PropertyBag: IPropertyBag;
  varName: {$IFDEF FPC}Variant{$ELSE}OleVariant{$ENDIF};
  HR: HRESULT;
{$IFDEF FPC}
  pceltFetched: LongWord;
  S: UTF8String;
{$ENDIF}
begin
  if CoCreateInstance(CLSID_SystemDeviceEnum, nil, CLSCTX_INPROC_SERVER,
     IID_ICreateDevEnum, CreateDevEnum) <> S_OK then
  begin
    Result := False;
    Exit;
  end;

  if CreateDevEnum.CreateClassEnumerator(CDeviceCategories[AType], EnumMoniker, 0) <> S_OK then
  begin
    Result := False;
    Exit;
  end;

  EnumMoniker.Reset;
{$IFDEF FPC}
  pceltFetched := 0;
{$ENDIF}
  while EnumMoniker.Next(1, Moniker, {$IFDEF FPC}pceltFetched{$ELSE}nil{$ENDIF}) = S_OK do
  begin
    HR := Moniker.BindToStorage(nil, nil, IID_IPropertyBag, PropertyBag);
    if Failed(HR) then
      Continue;
{$IFNDEF FPC}
    VariantInit(varName);
{$ENDIF}
    HR := PropertyBag.Read('FriendlyName', varName, nil);
    if Succeeded(HR) then
    begin
{$IFDEF FPC}
      S := varName;
      if APrefix then
        ADevices.Add(CPrefixs[AType] + '=' + S)
      else
        ADevices.Add(S);
{$ELSE}
      if APrefix then
        ADevices.Add(CPrefixs[AType] + '=' + varName)
      else
        ADevices.Add(varName);
      VariantClear(varName);
{$ENDIF}
    end;
  end;
  Result := True;
end;

function EnumDirectShowInputDevices(ADevices: TStrings): Boolean;
begin
  Result := EnumDirectShowInputDevices(ADevices, dtVideo, True);
  Result := EnumDirectShowInputDevices(ADevices, dtAudio, True) or Result;
end;

var
  NeedToUninitialize: Boolean = False;
initialization
  NeedToUninitialize := Succeeded(CoInitialize(nil));

finalization
  if NeedToUninitialize then
    CoUninitialize;

end.
