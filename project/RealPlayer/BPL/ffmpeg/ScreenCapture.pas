(*
 * Win32 video grab interface
 *
 * This file is part of FFmpeg.
 *
 * Copyright (C) 2007 Christophe Gisquet <christophe.gisquet <at> free.fr>
 *
 * FFmpeg is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with FFmpeg; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *)

(**
 * @file win32grab.c
 * Win32 frame device demuxer by Christophe Gisquet
 * <christophe.gisquet <at> free.fr>
 *)

(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Original file: win32grab.c
 * Ported by CodeCoolie@CNSW 2009/08/31 -> $Date:: 2013-02-10 #$
 *)

unit ScreenCapture;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms;
{$ELSE}
  Windows,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms;
{$ENDIF}

procedure register_screencapture;

implementation

uses
{$IFDEF FPC}
  LCLType,  // TCreateParams
{$ENDIF}
  libavcodec,
  AVCodecStubs,
  libavformat,
  AVFormatStubs,
  libavutil,
  libavutil_error,
  libavutil_log,
  libavutil_opt,
  libavutil_pixfmt,
  libavutil_rational,
  AVUtilStubs,
  MyUtilStubs,

  UnicodeProtocol,
  FFUtils,
  MyUtils;

const
  CFrameBorder = 2;
  CFrameColors: array[0..1] of TColor = (clRed, clBlue);
  FLAG_SHOW_FRAME       = 1;
  FLAG_CAPTURE_CLIENT   = 2;
  FLAG_CAPTURE_CURSOR   = 4;

type
  TFrameForm = class;
  Pwin32_grab = ^Twin32_grab;
  Twin32_grab = record
    class_: PAVClass;
    window_handle: HWND;    (* handle of the window for the grab *)
    source_hdc: HDC;        (* Source device context *)
    window_hdc: HDC;        (* Destination, source-compatible device context *)
    hbmp: HBITMAP;          (* Information on the bitmap captured *)

    time_base: TAVRational; (* Time base *)
    time_frame: Int64;      (* Current time *)
    time_start: Int64;
    Started: Integer;

    x_off: Integer;         (* Horizontal top-left corner coordinate *)
    y_off: Integer;         (* Vertical top-left corner coordinate *)
    cursor: Integer;        (* Also capture cursor *)

    size: Integer;          (* Size in bytes of the grab frame *)
    width: Integer;         (* Width of the grab frame *)
    height: Integer;        (* Height of the grab frame *)
    bpp: Integer;           (* Bits per pixel of the grab frame *)

    client: Integer;        // only capture client of window

    input_type_str: PAnsiChar;    // set by a private option
    capture_flags: Integer;       // set by a private option
    capture_offset: PAnsiChar;    // set by a private option
    video_size: PAnsiChar;        (**< A string describing video size, set by a private option. *)
    framerate: PAnsiChar;         (**< Set by a private option. *)

    show_frame: Integer;    // show flashing frame
    frame: TFrameForm;      // frame form
  end;

  TFlashThread = class(TThread)
  private
    FOwner: TFrameForm;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TFrameForm);
  end;

  TFrameForm = class(TCustomForm)
  private
    Fwin32_grab: Pwin32_grab;
    FBorder: Integer;
    FThread: TFlashThread;
    FLock: Integer;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(Awin32_grab: Pwin32_grab); reintroduce;
    destructor Destroy; override;
    procedure AdjustPosition;
    procedure Flash;
  end;

function GetTopLeft(const Awin32_grab: Pwin32_grab; const ABorder: Integer): TPoint;
var
  R: TRect;
begin
  if Awin32_grab.window_handle <> 0 then
  begin
    if Awin32_grab.client <> 0 then
    begin
{$IFDEF VCL_XE2_OR_ABOVE}
      Winapi.Windows.GetClientRect(Awin32_grab.window_handle, R);
      Winapi.Windows.ClientToScreen(Awin32_grab.window_handle, R.TopLeft);
{$ELSE}
      Windows.GetClientRect(Awin32_grab.window_handle, R);
      Windows.ClientToScreen(Awin32_grab.window_handle, R.TopLeft);
{$ENDIF}
    end
    else
      GetWindowRect(Awin32_grab.window_handle, R);
    Result.X := R.Left + Awin32_grab.x_off - ABorder;
    Result.Y := R.Top + Awin32_grab.y_off - ABorder;
  end
  else
  begin
    Result.X := Awin32_grab.x_off - ABorder;
    Result.Y := Awin32_grab.y_off - ABorder;
  end;
end;

{ TFlashThread }

constructor TFlashThread.Create(AOwner: TFrameForm);
begin
  inherited Create(False);
  FOwner := AOwner;
end;

procedure TFlashThread.Execute;
var
  LCounter: Integer;
begin
  LCounter := 0;
  while not Terminated do
  begin
    Inc(LCounter);
    if LCounter = 50 then
    begin
      FOwner.Flash;
      LCounter := 0;
    end;
    FOwner.AdjustPosition;
    Sleep(10);
  end;
end;

{ TFrameForm }

constructor TFrameForm.Create(Awin32_grab: Pwin32_grab);
  procedure SetupForm;
  var
    P: TPoint;
    rgn, rgn1, rgn2: HRGN;
  begin
    // frame outlook
    BorderStyle := bsNone;
    FormStyle := fsStayOnTop;
    BorderIcons := [];
    Position := poDesigned;
    Color := CFrameColors[0];

    // frame bounds
    P := GetTopLeft(Awin32_grab, FBorder);
    SetBounds(P.X, P.Y, Fwin32_grab.width + 2 * FBorder, Fwin32_grab.height + 2 * FBorder);

    // frame region
    rgn :=  CreateRectRgn(0, 0, Fwin32_grab.width + 2 * FBorder, Fwin32_grab.height + 2 * FBorder);
    rgn1 := CreateRectRgn(0, 0, Fwin32_grab.width + 2 * FBorder, Fwin32_grab.height + 2 * FBorder);
    rgn2 := CreateRectRgn(FBorder, FBorder, Fwin32_grab.width + FBorder, Fwin32_grab.height + FBorder);
    CombineRgn(rgn, rgn1, rgn2, RGN_DIFF);
    SetWindowRgn(Handle, rgn, True);
    DeleteObject(rgn);
    DeleteObject(rgn1);
    DeleteObject(rgn2);

    // do not show in taskbar
    SetWindowLong(Handle, GWL_EXSTYLE,
      GetWindowLong(Handle, GWL_EXSTYLE) or
      WS_EX_TOOLWINDOW and not WS_EX_APPWINDOW);

    // show frame
    Visible := True;
  end;
begin
  inherited CreateNew(nil);
  FBorder := CFrameBorder;
  Fwin32_grab := Awin32_grab;
  SetupForm;
  FLock := 0;
  FThread := TFlashThread.Create(Self);
end;

procedure TFrameForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WndParent := GetDesktopWindow;
end;

destructor TFrameForm.Destroy;
begin
  FThread.Free;
  inherited Destroy;
end;

procedure TFrameForm.AdjustPosition;
var
  P: TPoint;
begin
  if FLock <> 0 then
    Exit;
  FLock := 1;
  try
    P := GetTopLeft(Fwin32_grab, FBorder);
    if (Left <> P.X) or (Top <> P.Y) then
      SetWindowPos(Handle, HWND_TOPMOST, P.X, P.Y, Width, Height,
        SWP_NOSIZE or SWP_NOACTIVATE)
    else
      SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0,
        SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);
  finally
    FLock := 0;
  end;
end;

procedure TFrameForm.Flash;
const
{$J+}
  ColorIdx: Boolean = True;
{$J-}
begin
  if Fwin32_grab.Started = 1 then
  begin
    Self.Color := CFrameColors[Ord(ColorIdx)];
    ColorIdx := not ColorIdx;
  end;
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);
end;

procedure DoDrawIcon(s: Pwin32_grab; s1: PAVFormatContext);
{$IFDEF FPC}
const
  CURSOR_SHOWING = $00000001;
{$ENDIF}
var
  ci: TCURSORINFO;
  icon: HICON;
  info: ICONINFO;
  x, y: Longint;
  rect: TRect;
begin
  (*
  http://www.codeproject.com/csharp/DesktopCaptureWithMouse.asp?df=100&forumid=261533&exp=0&select=1442638
  *)
  ci.cbSize := SizeOf(ci);

  if not GetCursorInfo(ci) then
  begin
    av_log(s1, AV_LOG_ERROR, 'Couldn not get cursor info: GetCursorInfo() error %li'#10, GetLastError);
    s.cursor := 0; // do not capture cursor any more
    Exit;
  end;

  if ci.flags <> CURSOR_SHOWING then
    Exit;

  icon := CopyIcon(ci.hCursor);
  try
    if (icon <> 0) and GetIconInfo(icon, info) then
    begin
      x := ci.ptScreenPos.x - Longint(info.xHotspot);
      y := ci.ptScreenPos.y - Longint(info.yHotspot);

      if s.window_handle <> 0 then
      begin
        if ((s.client <> 0) and GetClientRect(s.window_handle, rect)) or
          ((s.client = 0) and GetWindowRect(s.window_handle, rect)) then
        begin
          if s.client <> 0 then
          begin
            ClientToScreen(s.window_handle, rect.TopLeft);
            ClientToScreen(s.window_handle, rect.BottomRight);
          end;
          //av_log(s1, AV_LOG_DEBUG, 'Pos(%li,%li) . (%li,%li)'#10, x, y, x - rect.left, y - rect.top);
          Dec(x, rect.left);
          Dec(y, rect.top);
        end
        else
        begin
          av_log(s1, AV_LOG_ERROR, 'Could not draw icon: GetClientRect() or GetWindowRect() error %li'#10, GetLastError);
          s.cursor := 0; // do not capture cursor any more
        end;
      end;

      Dec(x, s.x_off);
      Dec(y, s.y_off);
      if not DrawIcon(s.window_hdc, x, y, icon) then
      begin
        av_log(s1, AV_LOG_ERROR, 'Could not draw icon: DrawIcon() error %li'#10, GetLastError);
        s.cursor := 0; // do not capture cursor any more
      end;

      // GetIconInfo creates bitmaps for the hbmMask and hbmColor members of ICONINFO.
      // The calling application must manage these bitmaps and delete them when they are no longer necessary.
      if info.hbmMask <> 0 then
        DeleteObject(info.hbmMask);
      if info.hbmColor <> 0 then
        DeleteObject(info.hbmColor);
    end
    else if icon <> 0 then
    begin
      av_log(s1, AV_LOG_ERROR, 'Could not get icon info: GetIconInfo() error %li'#10, GetLastError);
      s.cursor := 0; // do not capture cursor any more
    end
    else
    begin
      av_log(s1, AV_LOG_ERROR, 'Could not copy icon: CopyIcon() error %li'#10, GetLastError);
      s.cursor := 0; // do not capture cursor any more
    end;
  finally
    if icon <> 0 then
      DestroyIcon(icon);
  end;
end;

function win32grab_read_header(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pwin32_grab;
  show_title: Boolean;
  title: TPathFileName;
  ret: Integer;
  framerate_q: TAVRational;
  width: Integer;
  height: Integer;
  p: PAnsiChar;
  screenwidth: Longint;
  screenheight: Longint;
  bmp: BITMAP;
  input_pixfmt: TAVPixelFormat;
  errcode: Integer;
  errmsg: string;
  dim: TRect;
  st: PAVStream;
begin
  ctx := s.priv_data;
  show_title := False;
  title := 'N/A';

  // screen input type, one of {hwnd, title, desktop}, default desktop
  if Assigned(ctx.input_type_str) and (ctx.input_type_str <> '') then
  begin
    if ctx.input_type_str = 'hwnd' then
    begin
      try
        // special window handle
        ctx.window_handle := StrToInt(string(s.filename));
      except
        av_log(s, AV_LOG_ERROR, 'Invalid capture parameter: "%s", ' +
          'it should be a window handle'#10, s.filename);
        Result := AVERROR_EINVAL;
        Exit;
      end;
    end
    else if ctx.input_type_str = 'title' then
    begin
      // find window handle by title
      title := delphi_filename(s.filename);
      ctx.window_handle := FindWindowW(nil, PWideChar(title));
      if ctx.window_handle = 0 then
      begin
        av_log(s, AV_LOG_ERROR, 'Could not find window: "%s"'#10, s.filename);
        Result := AVERROR_EINVAL;
        Exit;
      end;
      show_title := True;
    end
    else if ctx.input_type_str <> 'desktop' then
    begin
      av_log(s, AV_LOG_ERROR, 'Invalid capture input type: "%s", ' +
        'it should be hwnd, title or desktop'#10, ctx.input_type_str);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end;

  // video frame rate
  ret := av_parse_video_rate(@framerate_q, ctx.framerate);
  if ret < 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Could not parse framerate "%s".'#10, ctx.framerate);
    Result := AVERROR_EINVAL;
    Exit;
  end;
  ctx.time_base.num := framerate_q.den;
  ctx.time_base.den := framerate_q.num;
  if (ctx.time_base.num = 0) or (ctx.time_base.den = 0) then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid frame rate'#10);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  // video frame size
  if Assigned(ctx.video_size) and (ctx.video_size <> '') then
  begin
    ret := av_parse_video_size(@width, @height, ctx.video_size);
    if ret < 0 then
    begin
      av_log(s, AV_LOG_ERROR, 'Couldn''t parse video size.'#10);
      Result := AVERROR_EINVAL;
      Exit;
    end;
    if (width <= 0) or (height <= 0) then
    begin
      av_log(s, AV_LOG_ERROR, 'Invalid frame size'#10);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end
  else
  begin
    width := 0;
    height := 0;
  end;

  // capture offset %d,%d: offset on x and y against the final source window
  if Assigned(ctx.capture_offset) and (ctx.capture_offset <> '') then
  begin
    ctx.x_off := my_strtol(ctx.capture_offset, @p, 10);
    if not Assigned(p) or (p^ <> ',') then
    begin
      av_log(s, AV_LOG_ERROR, 'Couldn''t parse capture-offset.'#10);
      Result := AVERROR_EINVAL;
      Exit;
    end;
    Inc(p);
    ctx.y_off := my_strtol(p, @p, 10);
    if Assigned(p) and (p^ <> #0) then
    begin
      av_log(s, AV_LOG_ERROR, 'Couldn''t parse capture-offset.'#10);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end;

  // capture flags
  if (ctx.capture_flags and FLAG_SHOW_FRAME) <> 0 then
    ctx.show_frame := 1;
  if (ctx.capture_flags and FLAG_CAPTURE_CLIENT) <> 0 then
    ctx.client := 1;
  if (ctx.capture_flags and FLAG_CAPTURE_CURSOR) <> 0 then
    ctx.cursor := 1;

  if ctx.client <> 0 then
    ctx.source_hdc := GetDC(ctx.window_handle)
  else
    ctx.source_hdc := GetWindowDC(ctx.window_handle);
  if ctx.source_hdc = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Could not get window DC: GetDC() or GetWindowDC() error %li.'#10, GetLastError);
    Result := AVERROR_EIO;
    Exit;
  end;

  screenwidth := GetDeviceCaps(ctx.source_hdc, HORZRES);
  screenheight := GetDeviceCaps(ctx.source_hdc, VERTRES);
  if ctx.window_handle <> 0 then
  begin
    if ctx.client <> 0 then
      GetClientRect(ctx.window_handle, dim)
    else
      GetWindowRect(ctx.window_handle, dim);
    ctx.width := dim.right - dim.left;
    ctx.height := dim.bottom - dim.top;
  end
  else
  begin
    ctx.width := screenwidth;
    ctx.height := screenheight;
  end;
  if (width > 0) and (width <> ctx.width) then
    ctx.width := width;
  if (height > 0) and (height <> ctx.height) then
    ctx.height := height;

  if ctx.x_off + ctx.width > screenwidth then
    ctx.width := screenwidth - ctx.x_off;
  if ctx.y_off + ctx.height > screenheight then
    ctx.height := screenheight - ctx.y_off;

  ctx.bpp := GetDeviceCaps(ctx.source_hdc, BITSPIXEL);

  if (ctx.width < 0) or (ctx.height < 0) or (ctx.bpp mod 8 <> 0) then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid properties, aborting'#10);
    Result := AVERROR_EIO;
    Exit;
  end;

  ctx.window_hdc := CreateCompatibleDC(ctx.source_hdc);
  if ctx.window_hdc = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'CreateCompatibleDC() error %li'#10, GetLastError);
    Result := AVERROR_EIO;
    Exit;
  end;
  ctx.hbmp := CreateCompatibleBitmap(ctx.source_hdc, ctx.width, ctx.height);
  if ctx.hbmp = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'CreateCompatibleBitmap() error %li'#10, GetLastError);
    Result := AVERROR_EIO;
    Exit;
  end;

  (* Get info from the bitmap *)
  FillChar(bmp, sizeof(BITMAP), 0);
  if GetObject(ctx.hbmp, sizeof(BITMAP), @bmp) = 0 then
  begin
    errcode := GetLastError;
    if errcode <> 0 then
    begin
      errmsg := SysErrorMessage(errcode);
      av_log(s, AV_LOG_ERROR, 'GetObject() error %li: %s'#10, errcode, PAnsiChar(AnsiString(errmsg)));
      Result := AVERROR_EIO;
      Exit;
    end
    else
    begin
      bmp.bmType := 0;
      bmp.bmWidth := ctx.width;
      bmp.bmHeight := ctx.height;
      bmp.bmWidthBytes := ctx.width * ctx.bpp div 8;
      bmp.bmPlanes := 1;
      bmp.bmBitsPixel := ctx.bpp;
      bmp.bmBits := nil;
      av_log(s, AV_LOG_WARNING,
             'GetObject failed. Force Bitmap type %li, size %lix%lix%i, ' +
             '%i planes of width %li bytes'#10,
             bmp.bmType, bmp.bmWidth, bmp.bmHeight, bmp.bmBitsPixel,
             bmp.bmPlanes, bmp.bmWidthBytes);
    end;
  end
  else
    av_log(s, AV_LOG_DEBUG,
           'Using Bitmap type %li, size %lix%lix%i, ' +
           '%i planes of width %li bytes'#10,
           bmp.bmType, bmp.bmWidth, bmp.bmHeight, bmp.bmBitsPixel,
           bmp.bmPlanes, bmp.bmWidthBytes);
  if SelectObject(ctx.window_hdc, ctx.hbmp) = 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'SelectObject() error %li'#10, GetLastError);
    Result := AVERROR_EIO;
    Exit;
  end;

  case ctx.bpp of
    8:  input_pixfmt := AV_PIX_FMT_PAL8;
    16: input_pixfmt := AV_PIX_FMT_RGB555;
    24: input_pixfmt := AV_PIX_FMT_BGR24;
    32: input_pixfmt := AV_PIX_FMT_RGB32;
  else
    av_log(s, AV_LOG_ERROR, 'image depth %i not supported ... aborting'#10, ctx.bpp);
    Result := -1;
    Exit;
  end;
  ctx.size := bmp.bmWidthBytes * bmp.bmHeight * bmp.bmPlanes;

  st := avformat_new_stream(s, nil);
  if st = nil then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;
  av_set_pts_info(st, 64, 1, 1000000); (* 64 bits pts in us *)

//  if (s.show_frame <> 0) and (s.window_handle = 0) then
  if ctx.show_frame <> 0 then
    ctx.frame := TFrameForm.Create(ctx);

  st.codec.codec_type := AVMEDIA_TYPE_VIDEO;
  st.codec.codec_id   := AV_CODEC_ID_RAWVIDEO;
  st.codec.width      := ctx.width;
  st.codec.height     := ctx.height;
  st.codec.pix_fmt    := input_pixfmt;
  st.codec.time_base  := ctx.time_base;
  st.codec.bit_rate   := Round(ctx.size * 1 / av_q2d(ctx.time_base) * 8);
  st.codec.thread_count := 1; // avoid multithreading issue of log callback
  Inc(s.bit_rate, st.codec.bit_rate);

  // !!! to avoid av_find_stream_info() to read packets
  // condition 1
  st.r_frame_rate.num := ctx.time_base.den;
  st.r_frame_rate.den := ctx.time_base.num;
  st.avg_frame_rate.num := ctx.time_base.den;
  st.avg_frame_rate.den := ctx.time_base.num;
  // condition 2
  s.flags := s.flags or AVFMT_FLAG_NOPARSE;
  // condition 3
  st.first_dts := 0;
  // condition ALL
  s.probesize := 0;

  ctx.time_frame := Round(av_gettime / av_q2d(ctx.time_base));

  if show_title then
    av_log(s, AV_LOG_INFO, 'Found window %s, ', s.filename);
  av_log(s, AV_LOG_INFO, 'ready for capturing %ix%ix%i at (%i,%i)'#10,
         ctx.width, ctx.height, ctx.bpp, ctx.x_off, ctx.y_off);

  Result := 0;
end;

function win32grab_read_packet(s1: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;
var
  s: Pwin32_grab;
  curtime: Int64;
  delay: Int64;
begin
  s := s1.priv_data;

  if s.Started = 0 then
  begin
{$IFNDEF FPC}
    av_log(s, AV_LOG_DEBUG, 'Count of GDI objects: %d, Count of USER objects: %d'#10,
           GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS), GetGuiResources(GetCurrentProcess, GR_USEROBJECTS));
{$ENDIF}
    s.time_frame := Round(av_gettime / av_q2d(s.time_base));
    s.time_start := av_gettime;
    s.Started := 1;
  end;

  curtime := 0; {stop compiler warning}
  (* wait based on the frame rate *)
  while True do
  begin
    curtime := av_gettime;
    delay := Round(s.time_frame * av_q2d(s.time_base)) - curtime;
    if delay <= 0 then
    begin
      if delay < Int64(-1000000) * av_q2d(s.time_base) then
        Inc(s.time_frame, Int64(1000000));
      Break;
    end;
    Sleep(delay div 1000);
  end;

  (* Calculate the time of the next frame *)
  Inc(s.time_frame, Int64(1000000));

  if av_new_packet(pkt, s.size) < 0 then
  begin
    Result := AVERROR_EIO;
    Exit;
  end;

  pkt.pts := curtime - s.time_start;

  (* Blit screen grab *)
  if not BitBlt(s.window_hdc, 0, 0, s.width, s.height,
                s.source_hdc, s.x_off, s.y_off, SRCCOPY) then
  begin
    av_log(s1, AV_LOG_ERROR, 'Failed to capture image: BitBlt() error %li'#10, GetLastError);
    Result := -1;
    Exit;
  end;

  if s.cursor <> 0 then
    DoDrawIcon(s, s1);

  (* Get bits *)
  if GetBitmapBits(s.hbmp, s.size, pkt.data) = 0 then
  begin
    av_log(s1, AV_LOG_ERROR, 'GetBitmapBits() error %li'#10, GetLastError);
    Result := -1;
    Exit;
  end;

  Result := s.size;
end;

function win32grab_read_close(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pwin32_grab;
begin
{$IFNDEF FPC}
  av_log(s, AV_LOG_DEBUG, 'Count of GDI objects: %d, Count of USER objects: %d'#10,
         GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS), GetGuiResources(GetCurrentProcess, GR_USEROBJECTS));
{$ENDIF}
  ctx := s.priv_data;

  // release resource
  if ctx.source_hdc <> 0 then
    ReleaseDC(ctx.window_handle, ctx.source_hdc);
  if ctx.window_hdc <> 0 then
    DeleteDC(ctx.window_hdc);
  if ctx.hbmp <> 0 then
    DeleteObject(ctx.hbmp);
  if ctx.source_hdc <> 0 then
    DeleteDC(ctx.source_hdc);
  if ctx.frame <> nil then
    ctx.frame.Release;

  Result := 0;
end;

var
  options: array[0..8] of TAVOption = (
    (name       : 'input_type';
     help       : 'one of {hwnd, title, desktop}, default desktop';
     offset     : -1;
     ttype      : AV_OPT_TYPE_STRING;
     default_val: (str: 'desktop');
     min        : 0;
     max        : 0;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'video_size';
     help       : 'A string describing frame size, such as 640x480 or hd720.';
     offset     : -1;
     ttype      : AV_OPT_TYPE_STRING;
     default_val: (str: nil);
     min        : 0;
     max        : 0;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'framerate';
     help       : '';
     offset     : -1;
     ttype      : AV_OPT_TYPE_STRING;
     default_val: (str: 'ntsc');
     min        : 0;
     max        : 0;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'capture_offset';
     help       : '%d,%d: offset on x and y against the final source window';
     offset     : -1;
     ttype      : AV_OPT_TYPE_STRING;
     default_val: (str: nil);
     min        : 0;
     max        : 0;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'capture_flags';
     help       : '';
     offset     : -1;
     ttype      : AV_OPT_TYPE_FLAGS;
     default_val: (i64: FLAG_SHOW_FRAME or FLAG_CAPTURE_CLIENT or FLAG_CAPTURE_CURSOR);
     min        : Low(Integer);
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM;
     uunit      : 'capture_flags'),
    (name       : 'showframe';
     help       : 'show frame';
     offset     : 0;
     ttype      : AV_OPT_TYPE_CONST;
     default_val: (i64: FLAG_SHOW_FRAME);
     min        : Low(Integer);
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM;
     uunit      : 'capture_flags'),
    (name       : 'client';
     help       : 'capture client dc instead of window dc';
     offset     : 0;
     ttype      : AV_OPT_TYPE_CONST;
     default_val: (i64: FLAG_CAPTURE_CLIENT);
     min        : Low(Integer);
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM;
     uunit      : 'capture_flags'),
    (name       : 'cursor';
     help       : 'capture cursor';
     offset     : 0;
     ttype      : AV_OPT_TYPE_CONST;
     default_val: (i64: FLAG_CAPTURE_CURSOR);
     min        : Low(Integer);
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM;
     uunit      : 'capture_flags'),
    (name       : nil;)
  );

  win32_grab_class: TAVClass = (
    class_name: 'ScreenCaptureFormat';
    //item_name : av_default_item_name;
    option    : @options[0];
    version   : LIBAVUTIL_VERSION_INT;
  );

  win32_grab_device_demuxer: TAVInputFormat = (
    name: 'screencapture';
    long_name: 'Screen capture using GDI';
    flags: AVFMT_NOFILE;
    priv_class: @win32_grab_class;
    priv_data_size: SizeOf(Twin32_grab);
    read_header: win32grab_read_header;
    read_packet: win32grab_read_packet;
    read_close: win32grab_read_close;
  );

procedure register_screencapture;
var
  ctx: Twin32_grab;
begin
  Assert(Assigned(av_default_item_name));
  win32_grab_class.item_name := av_default_item_name;
  options[0].offset := Integer(@ctx.input_type_str) - Integer(@ctx);
  options[1].offset := Integer(@ctx.video_size) - Integer(@ctx);
  options[2].offset := Integer(@ctx.framerate) - Integer(@ctx);
  options[3].offset := Integer(@ctx.capture_offset) - Integer(@ctx);
  options[4].offset := Integer(@ctx.capture_flags) - Integer(@ctx);
  RegisterInputFormat(@win32_grab_device_demuxer);
end;

end.
