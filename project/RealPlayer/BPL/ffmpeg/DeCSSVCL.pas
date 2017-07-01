(*
 * DeCSSVCL - As It. No Warrant. No Support.

 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Original file: DeCSSplus.c
 * ported by CodeCoolie@CNSW 2008/06/28 -> $Date:: 2011-10-28 #$
 *)

unit DeCSSVCL;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
{$ELSE}
  Windows,
  SysUtils,
  Classes,
{$ENDIF}

  DeCSS;

// DeCSSplus v1.0 - Decrypt without knowing the key - (c) 2000 Ethan Hawke
// Please make sure the DVD VOB file is _readable_. Use a DVD-player to remove the sector protection.
// AScanAll: Scan entier file. Default is to stop after having found 20 times the same key.

const
  CMaxKeys = 1000;

type
  TKeyOcc = packed record
    occ: Integer;
    key: TDVD40BitKey;
  end;

  TPositionEvent = procedure(Sender: TObject; const APosition, AFileSize: Integer) of object;

  TDeCSSVCL = class(TComponent)
  private
    FPosKey: array[0..CMaxKeys-1] of TKeyOcc;
    FLastErrMsg: string;
    FEncrypted: Boolean;
    FKeysCount: Integer;
    FFileName: string;
    FFileSize: Integer;
    FInDVDROM: Boolean;
    FPosPercent: Boolean;
    FOnPosition: TPositionEvent;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function OpenVOB(const AFileName: string; const AScanAll: Boolean = False): Integer;
    function SaveAs(const AFileName: string; const AKeyIdx: Integer = 0): Integer;

    property InDVDROM: Boolean read FInDVDROM;
    property KeysCount: Integer read FKeysCount;
    property LastErrMsg: string read FLastErrMsg;
  published
    property PosPercent: Boolean read FPosPercent write FPosPercent default True;
    property OnPosition: TPositionEvent read FOnPosition write FOnPosition;
  end;

implementation

const
  CBufSize = $800; // do not change!!! fixed $800

{ TDeCSSVCL }

constructor TDeCSSVCL.Create(AOwner: TComponent);
begin
  inherited;
  FPosPercent := True;
end;

destructor TDeCSSVCL.Destroy;
begin

  inherited;
end;

function TDeCSSVCL.OpenVOB(const AFileName: string; const AScanAll: Boolean): Integer;
var
  HIn: Integer;
  LBytesRead: Integer;
  LBuffer: array[0..CBufSize-1] of Byte;
  LBestPLen: Integer;
  LBestP: Integer;
  I: Integer;
  J: Integer;
  LKey: TDVD40BitKey;
  LDuplicate: Boolean;
  LRegisteredKeys: Integer;
  LStopScanning: Boolean;
  Locc: Integer;
begin
  if not FileExists(AFileName) then
  begin
    FLastErrMsg := 'Cannot find the input file!';
    Result := -1;
    Exit;
  end;

  HIn := FileOpen(AFileName, fmOpenRead or fmShareDenyWrite);
  if HIn < 0 then
  begin
    FLastErrMsg := 'FILE ERROR: File could not be opened. [Check if file is readable]';
    Result := -2;
    Exit;
  end;

  FInDVDROM := DRIVE_CDROM = GetDriveType(PChar(ExtractFileDrive(AFileName)));

  FEncrypted := False;
  FKeysCount := 0;
  FFileName := AFileName;
  FFileSize := FileSeek(HIn, 0, FILE_END);
  FileSeek(HIn, 0, FILE_BEGIN);

  LRegisteredKeys := 0;
  LStopScanning := False;
  FillChar(FPosKey, SizeOf(FPosKey), 0);

  repeat
    //if (paramVerbose>=1 && filsize>1024*1024) printf("%.2f of file read & found %i keys...\r",pos*100.0/filsize,TotalKeysFound);
    LBytesRead := FileRead(HIn, LBuffer[0], CBufSize);
    if (LBuffer[$14] and $30) <> 0 then // PES_scrambling_control
    begin
      FEncrypted := True;
      LBestPLen := 0;
      LBestP := 0;
      for I := 2 to $30 - 1 do
      begin
        J := I;
        while (J < $80) and (LBuffer[$7F - (J mod I)] = LBuffer[$7F - J]) do
          Inc(J);
        if (J > LBestPLen) and (J > I) then
        begin
          LBestPLen := J;
          LBestP := I;
        end;
      end;
      if (LBestPLen > 20) and (LBestPLen div LBestP >= 2) then
      begin
        I := CSScrackerDVD(0, @LBuffer[$80], @LBuffer[$80 - (LBestPLen div LBestP) * LBestP], @LBuffer[$54],@LKey);
        while I >= 0 do
        begin
          LDuplicate := False;
          for J := 0 to LRegisteredKeys - 1 do
          begin
            if CompareMem(@(FPosKey[J].key), @LKey, SizeOf(TDVD40BitKey)) then
            begin
              Inc(FPosKey[J].occ);
              LDuplicate := True;
            end;
          end;
          if not LDuplicate then
          begin
            Move(LKey, FPosKey[LRegisteredKeys].key, SizeOf(TDVD40BitKey));
            FPosKey[LRegisteredKeys].occ := 1;
            Inc(LRegisteredKeys);
          end;
          //if (paramVerbose>=2) printf("\nOfs:%08X - Key: %02X %02X %02X %02X %02X\n",pos,MyKey[0],MyKey[1],MyKey[2],MyKey[3],MyKey[4]);
          I := CSScrackerDVD(I, @LBuffer[$80], @LBuffer[$80 - (LBestPLen div LBestP) * LBestP], @LBuffer[$54], @LKey);
        end;
        if not AScanALL and (LRegisteredKeys = 1) and (FPosKey[0].occ >= 20) or (LRegisteredKeys = CMaxKeys) then
          LStopScanning := True;
      end;
    end;
  until (LBytesRead <> CBufSize) or LStopScanning;

  FileClose(HIn);

  //if (paramVerbose>=1 && StopScanning) printf("Found enough occurancies of the same key. Scan stopped.");

  if not FEncrypted then
  begin
    FLastErrMsg := 'This file was _NOT_ encrypted!';
    Result := -3;
    Exit;
  end;

  if LRegisteredKeys = 0 then
  begin
    FLastErrMsg := 'Sorry... No keys found to this encrypted file.';
    Result := 0;
    Exit;
  end;

  for I := 0 to LRegisteredKeys - 2 do
    for J := I + 1 to LRegisteredKeys - 1 do
      if FPosKey[J].occ > FPosKey[I].occ then
      begin
        Move(FPosKey[J].key, LKey, SizeOf(TDVD40BitKey));
        Locc := FPosKey[J].occ;
        Move(FPosKey[I].key, FPosKey[J].key, SizeOf(TDVD40BitKey));
        FPosKey[J].occ := FPosKey[I].occ;
        Move(LKey, FPosKey[I].key, SizeOf(TDVD40BitKey));
        FPosKey[I].occ := Locc;
      end;

(*
  if (paramVerbose>=1)
  {
    printf(" Key(s) & key probability\n--------------------------\n");
    for(i=0;i<RegisteredKeys;i++)
      printf(" %02X %02X %02X %02X %02X - %3.2f%%\n",PosKey[i].key[0],PosKey[i].key[1],PosKey[i].key[2],PosKey[i].key[3],PosKey[i].key[4],PosKey[i].occ*100.0/TotalKeysFound);
    printf("\n");
  }
*)

  FKeysCount := LRegisteredKeys;
  Result := LRegisteredKeys;
end;

function TDeCSSVCL.SaveAs(const AFileName: string; const AKeyIdx: Integer = 0): Integer;
var
  LKey: TDVD40BitKey;
  HIn: Integer;
  HOut: Integer;
  LBytesRead: Integer;
  LBytesWritten: Integer;
  LPos: Integer;
  LBuffer: array[0..CBufSize-1] of Byte;
  LPosPercent: Integer;
begin
  if FKeysCount = 0 then
  begin
    FLastErrMsg := 'Sorry... No keys found to this encrypted file.';
    Result := -1;
    Exit;
  end;

  if (AKeyIdx < 0) or (AKeyIdx > FKeysCount - 1) then
  begin
    FLastErrMsg := 'invalid key index.';
    Result := -2;
    Exit;
  end;

  Move(FPosKey[AKeyIdx].key, LKey, SizeOf(TDVD40BitKey));
  // if (paramVerbose>=2) printf("Using key %02X %02X %02X %02X %02X\n",MyKey[0],MyKey[1],MyKey[2],MyKey[3],MyKey[4]);

  if SameText(FFileName, AFileName) then
  begin
    HIn := FileOpen(FFileName, fmOpenReadWrite or fmShareExclusive);
    if HIn < 0 then
    begin
      FLastErrMsg := 'File could not be opened for Read/Write';
      Result := -3;
      Exit;
    end;

    FFileSize := FileSeek(HIn, 0, FILE_END);
    FileSeek(HIn, 0, FILE_BEGIN);

    LPos := 0;
    LPosPercent := -1;
    repeat
      // if (paramVerbose>=1 && filsize>1024*1024) printf("%.2f of file read/written...\r",pos*100.0/filsize);
      if Assigned(FOnPosition) then
      begin
        if not FPosPercent then
          FOnPosition(Self, LPos, FFileSize)
        else if MulDiv(LPos, 100, FFileSize) > LPosPercent then
        begin
          FOnPosition(Self, LPos, FFileSize);
          LPosPercent := MulDiv(LPos, 100, FFileSize);
        end;
      end;
      //FileSeek(HIn, LPos, FILE_BEGIN);
      LBytesRead := FileRead(HIn, LBuffer[0], CBufSize);
      if (LBuffer[$14] and $30) <> 0 then // PES_scrambling_control
      begin
        CSSdescrambleSector(@LKey, @LBuffer[0]);
        LBuffer[$14] := LBuffer[$14] and $8F;
      end;
      FileSeek(HIn, LPos, FILE_BEGIN);
      LBytesWritten := FileWrite(HIn, LBuffer[0], LBytesRead);
      if LBytesWritten <> LBytesRead then
      begin
        FLastErrMsg := 'Could not write to output file.';
        Result := -4;
        FileClose(HIn);
        Exit;
      end;
      Inc(LPos, LBytesRead);
    until (LBytesRead <> CBufSize);
    FileClose(HIn);
    if Assigned(FOnPosition) then
      FOnPosition(Self, LPos, FFileSize);
  end
  else
  begin
    HIn := FileOpen(FFileName, fmOpenRead or fmShareDenyWrite);
    if HIn < 0 then
    begin
      FLastErrMsg := 'File could not be opened for Read';
      Result := -5;
      Exit;
    end;

    HOut := FileCreate(AFileName);
    if HOut < 0 then
    begin
      FLastErrMsg := 'File could not be opened for Write';
      Result := -6;
      FileClose(HIn);
      Exit;
    end;

    FFileSize := FileSeek(HIn, 0, FILE_END);
    FileSeek(HIn, 0, FILE_BEGIN);

    LPos := 0;
    LPosPercent := -1;
    repeat
      // if (paramVerbose>=1 && filsize>1024*1024) printf("%.2f of file read/written...\r",pos*100.0/filsize);
      if Assigned(FOnPosition) then
      begin
        if not FPosPercent then
          FOnPosition(Self, LPos, FFileSize)
        else if MulDiv(LPos, 100, FFileSize) > LPosPercent then
        begin
          FOnPosition(Self, LPos, FFileSize);
          LPosPercent := MulDiv(LPos, 100, FFileSize);
        end;
      end;
      LBytesRead := FileRead(HIn, LBuffer[0], CBufSize);
      if (LBuffer[$14] and $30) <> 0 then // PES_scrambling_control
      begin
        CSSdescrambleSector(@LKey, @LBuffer[0]);
        LBuffer[$14] := LBuffer[$14] and $8F;
      end;
      LBytesWritten := FileWrite(HOut, LBuffer[0], LBytesRead);
      if LBytesWritten <> LBytesRead then
      begin
        FLastErrMsg := 'Could not write to output file.';
        Result := -7;
        FileClose(HIn);
        FileClose(HOut);
        Exit;
      end;
      Inc(LPos, LBytesRead);
    until (LBytesRead <> CBufSize);
    FileClose(HIn);
    FileClose(HOut);
    if Assigned(FOnPosition) then
      FOnPosition(Self, LPos, FFileSize);
  end;

  Result := 0;
end;

end.
