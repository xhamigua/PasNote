(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Unicode filename I/O protocol
 * Using Unicode filename for input/output
 * Created by CodeCoolie@CNSW 2009/07/19 -> $Date:: 2013-06-06 #$
 *)
(*
 * filename format: "unicode:utf8:<filename encoded in utf8 string>"
 *)

unit UnicodeProtocol;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  System.SysUtils,
  {$IFDEF VCL_XE4_OR_ABOVE}
    System.AnsiStrings, // StrLen
  {$ENDIF}
{$ELSE}
  Windows,
  SysUtils,
{$ENDIF}

  MyUtils;

procedure register_unicode_protocol;
function ffmpeg_filename(const AFileName: TPathFileName): PAnsiChar;
function delphi_filename(const AFileName: PAnsiChar): TPathFileName;

implementation

uses
{$IFDEF MSWINDOWS}
  libavcodec,
  AVFormatStubs,
  AVUtilStubs,
  MyUtilStubs,
{$ENDIF}
  libavformat_avio,
  libavformat_url,
  FFUtils;

{ routines }

{$IFDEF MSWINDOWS}
(****** TODO: check from libavformat/img2.c **************)
function my_ff_guess_image2_codec(const str: PAnsiChar): TAVCodecID;
type
  PIdStrMap = ^TIdStrMap;
  TIdStrMap = record
    id: TAVCodecID;
    str: PAnsiChar;
  end;
const
  img_tags: array[0..48] of TIdStrMap = (
    (id: AV_CODEC_ID_MJPEG;       str: 'jpeg'     ),
    (id: AV_CODEC_ID_MJPEG;       str: 'jpg'      ),
    (id: AV_CODEC_ID_MJPEG;       str: 'jps'      ),
    (id: AV_CODEC_ID_LJPEG;       str: 'ljpg'     ),
    (id: AV_CODEC_ID_JPEGLS;      str: 'jls'      ),
    (id: AV_CODEC_ID_PNG;         str: 'png'      ),
    (id: AV_CODEC_ID_PNG;         str: 'pns'      ),
    (id: AV_CODEC_ID_PNG;         str: 'mng'      ),
    (id: AV_CODEC_ID_PPM;         str: 'ppm'      ),
    (id: AV_CODEC_ID_PPM;         str: 'pnm'      ),
    (id: AV_CODEC_ID_PGM;         str: 'pgm'      ),
    (id: AV_CODEC_ID_PGMYUV;      str: 'pgmyuv'   ),
    (id: AV_CODEC_ID_PBM;         str: 'pbm'      ),
    (id: AV_CODEC_ID_PAM;         str: 'pam'      ),
    (id: AV_CODEC_ID_MPEG1VIDEO;  str: 'mpg1-img' ),
    (id: AV_CODEC_ID_MPEG2VIDEO;  str: 'mpg2-img' ),
    (id: AV_CODEC_ID_MPEG4;       str: 'mpg4-img' ),
    (id: AV_CODEC_ID_FFV1;        str: 'ffv1-img' ),
    (id: AV_CODEC_ID_RAWVIDEO;    str: 'y'        ),
    (id: AV_CODEC_ID_RAWVIDEO;    str: 'raw'      ),
    (id: AV_CODEC_ID_BMP;         str: 'bmp'      ),
    (id: AV_CODEC_ID_GIF;         str: 'gif'      ),
    (id: AV_CODEC_ID_TARGA;       str: 'tga'      ),
    (id: AV_CODEC_ID_TIFF;        str: 'tiff'     ),
    (id: AV_CODEC_ID_TIFF;        str: 'tif'      ),
    (id: AV_CODEC_ID_SGI;         str: 'sgi'      ),
    (id: AV_CODEC_ID_PTX;         str: 'ptx'      ),
    (id: AV_CODEC_ID_PCX;         str: 'pcx'      ),
    (id: AV_CODEC_ID_BRENDER_PIX; str: 'pix'      ),
    (id: AV_CODEC_ID_SUNRAST;     str: 'sun'      ),
    (id: AV_CODEC_ID_SUNRAST;     str: 'ras'      ),
    (id: AV_CODEC_ID_SUNRAST;     str: 'rs'       ),
    (id: AV_CODEC_ID_SUNRAST;     str: 'im1'      ),
    (id: AV_CODEC_ID_SUNRAST;     str: 'im8'      ),
    (id: AV_CODEC_ID_SUNRAST;     str: 'im24'     ),
    (id: AV_CODEC_ID_SUNRAST;     str: 'im32'     ),
    (id: AV_CODEC_ID_SUNRAST;     str: 'sunras'   ),
    (id: AV_CODEC_ID_JPEG2000;    str: 'j2c'      ),
    (id: AV_CODEC_ID_JPEG2000;    str: 'j2k'      ),
    (id: AV_CODEC_ID_JPEG2000;    str: 'jp2'      ),
    (id: AV_CODEC_ID_JPEG2000;    str: 'jpc'      ),
    (id: AV_CODEC_ID_DPX;         str: 'dpx'      ),
    (id: AV_CODEC_ID_EXR;         str: 'exr'      ),
    (id: AV_CODEC_ID_PICTOR;      str: 'pic'      ),
    (id: AV_CODEC_ID_V210X;       str: 'yuv10'    ),
    (id: AV_CODEC_ID_XBM;         str: 'xbm'      ),
    (id: AV_CODEC_ID_XFACE;       str: 'xface'    ),
    (id: AV_CODEC_ID_XWD;         str: 'xwd'      ),
    (id: AV_CODEC_ID_NONE;        str: nil        )
  );
var
  p: PAnsiChar;
  tags: PIdStrMap;
begin
  if Assigned(ff_guess_image2_codec) then
  begin
    Result := ff_guess_image2_codec(str);
    Exit;
  end;

  Result := AV_CODEC_ID_NONE;
  p := my_strrchr(str, '.');
  if not Assigned(p) then
    Exit;
  Inc(p);

  tags := @img_tags[0];
  while tags.id <> AV_CODEC_ID_NONE do
  begin
    if av_strcasecmp(p, tags.str) = 0 then
    begin
      Result := tags.id;
      Break;
    end;
    Inc(tags);
  end;
end;

const
  SUTF8Flag = AnsiString('unicode:utf8:');
  SProtocols = AnsiString(':unicode:stream:gopher:http:pipe:rtp:tcp:udp:');
var
  unicode_protocol_enabled: Boolean = False;

function need_utf8_encode(const AFileName: WideString): Boolean;
var
  s: WideString;
begin
  if Pos(':', AFileName) > 0 then
  begin
    s := Copy(AFileName, 1, Pos(':', AFileName) - 1);
    if Pos(':' + s + ':', SProtocols) > 0 then
    begin
      Result := False;
      Exit;
    end;
  end;
  Result := WideString(AnsiString(AFileName)) <> AFileName;
end;

function is_utf8_filename(const AFileName: PAnsiChar): Boolean;
begin
  if Integer(MyStrLen(AFileName)) > Length(SUTF8Flag) then
    Result := CompareMem(AFileName, PAnsiChar(SUTF8Flag), Length(SUTF8Flag))
  else
    Result := False;
end;

function embed_utf8_filename(const AFileName: WideString): UTF8String;
begin
  Result := Utf8Encode(SUTF8Flag + AFileName);
end;

function extract_utf8_filename(const AFileName: PAnsiChar): WideString;
var
  S: WideString;
begin
  // filename format: "unicode:utf8:<filename encoded in utf8 string>"
  // extract <utf8 string>
{$IFDEF UNICODE}
  S := Utf8ToWideString(AFileName);
{$ELSE}
  s := Utf8Decode(AFileName);
{$ENDIF}
  S := Copy(S, Pos(':', S) + 1, MaxInt);  // remove 'unicode:'
  S := Copy(S, Pos(':', S) + 1, MaxInt);  // remove 'utf8:'
  Result := S;
end;
{$ENDIF}

function ffmpeg_filename(const AFileName: TPathFileName): PAnsiChar;
const
  B: array[0..2047] of AnsiChar = '';
var
  S: AnsiString;
  P: PAnsiChar;
{$IFDEF MSWINDOWS}
  LFileName: WideString;
{$ENDIF}
begin
{$IFDEF FPC}
  S := AnsiString(AFileName);
{$ELSE}
  S := AnsiString(Utf8Encode(AFileName));
{$ENDIF}

{$IFDEF MSWINDOWS}
  // in libavformat, image2 format has a bug on processing utf8 filename
  if my_ff_guess_image2_codec(PAnsiChar(S)) <> AV_CODEC_ID_NONE then
  begin
  {$IFDEF FPC}
    LFileName := UTF8Decode(AFileName);
  {$ELSE}
    LFileName := AFileName;
  {$ENDIF}
    if unicode_protocol_enabled and need_utf8_encode(LFileName) then
      S := AnsiString(embed_utf8_filename(LFileName))
    else
      S := AnsiString(LFileName);
  end;
{$ENDIF}

  P := B;
  FillChar(P^, SizeOf(B), 0);
  if S <> '' then
    Move(S[1], P^, Length(S));
  Result := B;
end;

function delphi_filename(const AFileName: PAnsiChar): TPathFileName;
{$IFDEF MSWINDOWS}
var
  W: WideString;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  // in libavformat, image2 format has a bug on processing utf8 filename
  if my_ff_guess_image2_codec(AFileName) <> AV_CODEC_ID_NONE then
  begin
    if unicode_protocol_enabled and is_utf8_filename(AFileName) then
      W := extract_utf8_filename(AFileName)
    else
      W := WideString(AnsiString(AFileName));
  {$IFDEF FPC}
    Result := UTF8Encode(W);
  {$ELSE}
    Result := W;
  {$ENDIF}
    Exit;
  end;
{$ENDIF}

{$IFDEF FPC}
  Result := AFileName
{$ELSE}
  {$IFDEF UNICODE}
  Result := Utf8ToWideString(AFileName);
  {$ELSE}
  Result := UTF8Decode(AFileName);
  {$ENDIF}
{$ENDIF};
end;

{$IFDEF MSWINDOWS}
function FileOpenW(const FileName: WideString; flags: Integer): Integer;
var
  Access: Cardinal;
  Create: Cardinal;
begin
  if (flags and AVIO_FLAG_READ_WRITE) <> 0 then
  begin
    Access := GENERIC_READ or GENERIC_WRITE;
    Create := CREATE_ALWAYS;
  end
  else if (flags and AVIO_FLAG_WRITE) <> 0 then
  begin
    Access := GENERIC_WRITE;
    Create := CREATE_ALWAYS;
  end
  else
  begin
    Access := GENERIC_READ;
    Create := OPEN_EXISTING;
  end;
  Result := Integer(CreateFileW(PWideChar(FileName),
    Access,
    FILE_SHARE_READ, nil,
    Create,
    FILE_ATTRIBUTE_NORMAL, 0));
end;

{ unicode protocol }

function unicode_open(h: PURLContext; const filename: PAnsiChar; flags: Integer): Integer; cdecl;
var
  fd: THandle;
begin
  // filename format: "unicode:utf8:<filename encoded in utf8 string>"
  fd := FileOpenW(extract_utf8_filename(filename), flags);
  if fd <> INVALID_HANDLE_VALUE then
  begin
    Result := 0;
    h.priv_data := Pointer(fd);
  end
  else
    Result := {AVERROR_ENOENT}-2;
end;

function unicode_read(h: PURLContext; buf: PAnsiChar; size: Integer): Integer; cdecl;
begin
  if not ReadFile(THandle(h.priv_data), buf^, size, LongWord(Result), nil) then
    Result := -1;
end;

function unicode_write(h: PURLContext; const buf: PAnsiChar; size: Integer): Integer; cdecl;
begin
  if not WriteFile(THandle(h.priv_data), buf^, size, LongWord(Result), nil) then
    Result := -1;
end;

function unicode_seek(h: PURLContext; pos: Int64; whence: Integer): Int64; cdecl;
begin
  if whence <> {AVSEEK_SIZE}$10000 then
  begin
    Result := pos;
    Int64Rec(Result).Lo := SetFilePointer(THandle(h.priv_data), Int64Rec(Result).Lo,
      @Int64Rec(Result).Hi, whence);
    if (Int64Rec(Result).Lo = $FFFFFFFF) and (GetLastError <> 0) then
      Int64Rec(Result).Hi := $FFFFFFFF;
  end
  else
  begin
    Result := -1;
{$IFDEF VCL_XE2_OR_ABOVE}
    Int64Rec(Result).Lo := Winapi.Windows.GetFileSize(THandle(h.priv_data), @Int64Rec(Result).Hi);
{$ELSE}
    Int64Rec(Result).Lo := Windows.GetFileSize(THandle(h.priv_data), @Int64Rec(Result).Hi);
{$ENDIF}
    if (Int64Rec(Result).Lo = $FFFFFFFF) and (GetLastError <> 0) then
      Int64Rec(Result).Hi := $FFFFFFFF;
  end;
end;

function unicode_close(h: PURLContext): Integer; cdecl;
begin
  Result := Ord(CloseHandle(THandle(h.priv_data)));
end;

var
  unicode_protocol: TURLProtocol = (
    name: 'unicode';
    url_open: unicode_open;
    url_read: unicode_read;
    url_write: unicode_write;
    url_seek: unicode_seek;
    url_close: unicode_close;
    next: nil;
    url_read_pause: nil;
    url_read_seek: nil;
  );
{$ENDIF}

procedure register_unicode_protocol;
begin
{$IFDEF MSWINDOWS}
  unicode_protocol_enabled := RegisterProtocol(@unicode_protocol);
{$ENDIF}
end;

end.
