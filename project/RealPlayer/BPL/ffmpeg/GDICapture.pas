(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * GDI(Screen/Wave) capture interface
 * Created by CodeCoolie@CNSW 2012/12/03 -> $Date:: 2013-11-18 #$
 *)

unit GDICapture;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Winapi.MMSystem;
{$ELSE}
  Windows,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms,
  MMSystem;
{$ENDIF}

procedure register_gdicapture;

implementation

uses
{$IFDEF VER140} // Delphi 6
  MultiMon,
{$ENDIF}
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
  libavutil_samplefmt,
  AVUtilStubs,
  MyUtilStubs,

  FFUtils,
  MyUtils;

const
  // *** screen capture ***
  CFrameBorder = 2;
  CFrameColors: array[0..1] of TColor = (clRed, clBlue);
  FLAG_SHOW_FRAME       = 1;
  FLAG_CAPTURE_CLIENT   = 2;
  FLAG_CAPTURE_CURSOR   = 4;
  // *** wave capture ***
  MAX_BUFFER_COUNT = 4;
  WAVE_BUFFER_SIZE = $10000; // 64 KB
//  AUDIO_BLOCK_SIZE = 4096;

type
  Pgdi_capture = ^Tgdi_capture;
  Tgdi_capture = record
    class_: PAVClass;
    Started: Integer;
    time_start: Int64;
    Stoped: Integer;
    error: Integer;
    Paused: PInteger;
    mutex: THANDLE;
    event: THANDLE;

    // *** screen capture ***
    screen: Integer;        // enable screen capture
    screen_st_idx: Integer;
    window_handle: HWND;    (* handle of the window for the grab *)
    source_hdc: HDC;        (* Source device context *)
    window_hdc: HDC;        (* Destination, source-compatible device context *)
    hbmp: HBITMAP;          (* Information on the bitmap captured *)

    requested_framerate: TAVRational;
    time_frame: Int64;      (* Current time *)

    x_off: Integer;         (* Horizontal top-left corner coordinate *)
    y_off: Integer;         (* Vertical top-left corner coordinate *)
    cursor: Integer;        (* Also capture cursor *)

    bmp_size: Integer;      (* Size in bytes of the grab frame *)
    width: Integer;         (* Width of the grab frame *)
    height: Integer;        (* Height of the grab frame *)
    bpp: Integer;           (* Bits per pixel of the grab frame *)

    client: Integer;        // only capture client of window

    capture_flags: Integer;       // set by a private option
    capture_offset: PAnsiChar;    // set by a private option
    video_size: PAnsiChar;        (**< A string describing video size, set by a private option. *)
    requested_width: Integer;
    requested_height: Integer;
    framerate_str: PAnsiChar;         (**< Set by a private option. *)
    pix_fmt: TAVPixelFormat;

    show_frame: Integer;    // show flashing frame
    FrameForm: TCustomForm; // frame form
    ScreenThread: TObject;
    curbufsize: Int64;
    video_frame_num: Cardinal;


    // *** wave capture ***
    wave: Integer;                      // enable screen capture
    wave_st_idx: Integer;
    device: LongWord;                   // index of sound card
    sample_rate: Integer;               // sample rate, set by a private option
    channels: Integer;                  // channels, set by a private option
    sample_format: Integer;             // sample format
    sample_fmt: TAVSampleFormat;
    wave_codec_id: TAVCodecID;
    wave_bufsize: Integer;              // waveIn buffer size
//    frame_size: Integer;

    // for waveIn functions
    WaveFormat: TWaveFormatEx;          // wave format
    WaveHandle: HWAVEIN;                // wave input handle
    _WaveHdr: array[0..MAX_BUFFER_COUNT - 1] of TWaveHdr;  // wave Header buffer
    WaveHdr: array[0..MAX_BUFFER_COUNT - 1] of PWaveHdr;   // wave Header pointer
    WaveBuf: array[0..MAX_BUFFER_COUNT - 1] of PAnsiChar;  // wave buffer
    WaveBufIdx: Integer;                // wave buffer index

    sample_fmt_str: PAnsiChar;    // set by a private option

    pktl: PAVPacketList;
    s: PAVFormatContext;
  end;

  TFlashThread = class(TThread)
  private
    FOwner: TCustomForm;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TCustomForm);
  end;

  TFrameForm = class(TCustomForm)
  private
    Fgdi_capture: Pgdi_capture;
    FBorder: Integer;
    FThread: TFlashThread;
    FLock: Integer;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor Create(Agdi_capture: Pgdi_capture); reintroduce;
    destructor Destroy; override;
    procedure AdjustPosition;
    procedure Flash;
  end;

  TScreenThread = class(TThread)
  private
    ctx: Pgdi_capture;
    procedure DoDrawIcon;
  protected
    procedure Execute; override;
  public
    constructor Create(s: PAVFormatContext);
  end;

function GetTopLeft(const Agdi_capture: Pgdi_capture; const ABorder: Integer): TPoint;
var
  R: TRect;
begin
  if Agdi_capture.window_handle <> 0 then
  begin
    if Agdi_capture.client <> 0 then
    begin
{$IFDEF VCL_XE2_OR_ABOVE}
      Winapi.Windows.GetClientRect(Agdi_capture.window_handle, R);
      Winapi.Windows.ClientToScreen(Agdi_capture.window_handle, R.TopLeft);
{$ELSE}
      Windows.GetClientRect(Agdi_capture.window_handle, R);
      Windows.ClientToScreen(Agdi_capture.window_handle, R.TopLeft);
{$ENDIF}
    end
    else
      GetWindowRect(Agdi_capture.window_handle, R);
    Result.X := R.Left + Agdi_capture.x_off - ABorder;
    Result.Y := R.Top + Agdi_capture.y_off - ABorder;
  end
  else
  begin
    Result.X := Agdi_capture.x_off - ABorder;
    Result.Y := Agdi_capture.y_off - ABorder;
  end;
end;

{ TFlashThread }

constructor TFlashThread.Create(AOwner: TCustomForm);
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
      (FOwner as TFrameForm).Flash;
      LCounter := 0;
    end;
    (FOwner as TFrameForm).AdjustPosition;
    Sleep(10);
  end;
end;

{ TFrameForm }

constructor TFrameForm.Create(Agdi_capture: Pgdi_capture);
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
    P := GetTopLeft(Agdi_capture, FBorder);
    SetBounds(P.X, P.Y, Fgdi_capture.width + 2 * FBorder, Fgdi_capture.height + 2 * FBorder);

    // frame region
    rgn :=  CreateRectRgn(0, 0, Fgdi_capture.width + 2 * FBorder, Fgdi_capture.height + 2 * FBorder);
    rgn1 := CreateRectRgn(0, 0, Fgdi_capture.width + 2 * FBorder, Fgdi_capture.height + 2 * FBorder);
    rgn2 := CreateRectRgn(FBorder, FBorder, Fgdi_capture.width + FBorder, Fgdi_capture.height + FBorder);
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
  Fgdi_capture := Agdi_capture;
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
    P := GetTopLeft(Fgdi_capture, FBorder);
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
  if Fgdi_capture.Started <> 0 then
  begin
    Self.Color := CFrameColors[Ord(ColorIdx)];
    ColorIdx := not ColorIdx;
  end;
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);
end;

{ TScreenThread }

constructor TScreenThread.Create(s: PAVFormatContext);
begin
  //FreeOnTerminate := True;
  ctx := s.priv_data;
  inherited Create(False);
end;

procedure TScreenThread.DoDrawIcon;
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
    ctx.cursor := 0; // do not capture cursor any more
    av_log(ctx.s, AV_LOG_ERROR, 'Couldn not get cursor info: GetCursorInfo() error %li'#10, GetLastError);
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

      if ctx.window_handle <> 0 then
      begin
        if ((ctx.client <> 0) and GetClientRect(ctx.window_handle, rect)) or
          ((ctx.client = 0) and GetWindowRect(ctx.window_handle, rect)) then
        begin
          if ctx.client <> 0 then
          begin
            ClientToScreen(ctx.window_handle, rect.TopLeft);
            ClientToScreen(ctx.window_handle, rect.BottomRight);
          end;
          //av_log(s1, AV_LOG_DEBUG, 'Pos(%li,%li) . (%li,%li)'#10, x, y, x - rect.left, y - rect.top);
          Dec(x, rect.left);
          Dec(y, rect.top);
        end
        else
        begin
          ctx.cursor := 0; // do not capture cursor any more
          if ctx.Stoped = 0 then
            av_log(ctx.s, AV_LOG_ERROR, 'Could not draw icon: GetClientRect() or GetWindowRect() error %li'#10, GetLastError);
        end;
      end;

      Dec(x, ctx.x_off);
      Dec(y, ctx.y_off);
      if not DrawIcon(ctx.window_hdc, x, y, icon) then
      begin
        ctx.cursor := 0; // do not capture cursor any more
        if ctx.Stoped = 0 then
          av_log(ctx.s, AV_LOG_ERROR, 'Could not draw icon: DrawIcon() error %li'#10, GetLastError);
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
      ctx.cursor := 0; // do not capture cursor any more
      if ctx.Stoped = 0 then
        av_log(ctx.s, AV_LOG_ERROR, 'Could not get icon info: GetIconInfo() error %li'#10, GetLastError);
    end
    else
    begin
      ctx.cursor := 0; // do not capture cursor any more
      if ctx.Stoped = 0 then
        av_log(ctx.s, AV_LOG_ERROR, 'Could not copy icon: CopyIcon() error %li'#10, GetLastError);
    end;
  finally
    if icon <> 0 then
      DestroyIcon(icon);
  end;
end;

function shall_we_drop(s: PAVFormatContext): Boolean;
const
  ndropscores = 4;
  dropscore: array[0..ndropscores-1] of Byte = (62, 75, 87, 100);
var
  ctx: Pgdi_capture;
  buffer_fullness: Cardinal;
begin
  ctx := s.priv_data;
  buffer_fullness := (ctx.curbufsize * 100) div s.max_picture_buffer;

  Inc(ctx.video_frame_num);
  if dropscore[ctx.video_frame_num mod ndropscores] <= buffer_fullness then
  begin
    av_log(s, AV_LOG_ERROR, 'real-time buffer %d%% full! frame dropped!'#10, buffer_fullness);
    Result := True;
  end
  else
    Result := False;
end;

type
  PPAVPacketList = ^PAVPacketList;

procedure TScreenThread.Execute;
var
  interval: Double;
  delay: Int64;
  lost: Integer;
  pts: Int64;
  ppktl: PPAVPacketList;
  pktl_next: PAVPacketList;
  LastError: Integer;
begin
  interval := ctx.requested_framerate.den / ctx.requested_framerate.num;

  // wait while not started
  while not Terminated and (ctx.Started = 0) do
    Sleep(10);

  while not Terminated and (ctx.Stoped = 0) do
  begin
    // skip when paused
    if Assigned(ctx.Paused) and (ctx.Paused^ <> 0) then
    begin
      Sleep(10);
      Continue;
    end;

    (* wait based on the frame rate *)
    while ctx.time_start <> 0 do
    begin
      delay := Round(ctx.time_frame * interval - av_gettime);
      if delay <= 0 then
      begin
        //if delay < Int64(-1000000) * interval then
        //  Inc(ctx.time_frame, AV_TIME_BASE{1000000});
        lost := (-1 * delay) div Round(interval * 1000000);
        if lost > 0 then
        begin
          Inc(ctx.time_frame, AV_TIME_BASE{1000000} * lost);
          av_log(ctx.s, AV_LOG_INFO, 'We lost %d frames. ' +
                 'It might be caused by paused or bad performance or frame rate is too high.'#10, lost);
        end;
        (* Calculate the time of the next frame *)
        Inc(ctx.time_frame, AV_TIME_BASE{1000000});
        Break;
      end;
      Sleep(delay div 1000);
    end;

    (* Blit screen grab *)
    if not BitBlt(ctx.window_hdc, 0, 0, ctx.width, ctx.height,
                  ctx.source_hdc, ctx.x_off, ctx.y_off, SRCCOPY) then
    begin
      if ctx.Stoped = 0 then
      begin
        ctx.Stoped := 1;
        ctx.error := AVERROR_EIO;
        av_log(ctx.s, AV_LOG_ERROR, 'Failed to capture image: BitBlt() error %li'#10, GetLastError);
      end;
      Break;
    end;

    if ctx.time_start <> 0 then
      pts := av_gettime - ctx.time_start
    else
    begin
      ctx.time_start := av_gettime;
      ctx.time_frame := Round(ctx.time_start * av_q2d(ctx.requested_framerate));
      pts := 0;
    end;

    if ctx.cursor <> 0 then
      DoDrawIcon; // MySynchronize(DoDrawIcon);

    // obtain mutex for writing
    WaitForSingleObject(ctx.mutex, INFINITE);
    try
      if shall_we_drop(ctx.s) then
        Continue;

      // create packet list
      pktl_next := av_mallocz(SizeOf(TAVPacketList));
      if not Assigned(pktl_next) then
      begin
        ctx.Stoped := 1;
        ctx.error := AVERROR_ENOMEM;
        av_log(ctx.s, AV_LOG_ERROR, 'av_mallocz() error'#10);
        Break;
      end;

      // create packet
      if av_new_packet(@pktl_next.pkt, ctx.bmp_size) < 0 then
      begin
        av_free(pktl_next);
        ctx.Stoped := 1;
        ctx.error := AVERROR_ENOMEM;
        av_log(ctx.s, AV_LOG_ERROR, 'av_new_packet() error'#10);
        Break;
      end;

      // write screen data
      pktl_next.pkt.stream_index := ctx.screen_st_idx;
      pktl_next.pkt.pts := pts;
      (* Get bits *)
      if GetBitmapBits(ctx.hbmp, ctx.bmp_size, pktl_next.pkt.data) = 0 then
      begin
        LastError := GetLastError;
        av_destruct_packet(@pktl_next.pkt);
        av_free(pktl_next);
        if ctx.Stoped = 0 then
        begin
          ctx.Stoped := 1;
          ctx.error := AVERROR_EIO;
          av_log(ctx.s, AV_LOG_ERROR, 'GetBitmapBits() error %li'#10, LastError);
        end;
        Break;
      end;

      // add packet to list
      ppktl := @ctx.pktl;
      while Assigned(ppktl^) do
        ppktl := @ppktl^.next;
      ppktl^ := pktl_next;
      Inc(ctx.curbufsize, ctx.bmp_size);

      SetEvent(ctx.event);
    finally
      ReleaseMutex(ctx.mutex);
    end;
  end;
end;

// get waveIn function error message
function waveInGetError(mmrError: MMRESULT): string;
var
  LBuf: array[0..255] of Char;
begin
  FillChar(LBuf[0], SizeOf(LBuf), 0);
  waveInGetErrorText(mmrError, LBuf, SizeOf(LBuf));
  Result := LBuf;
end;

// release resource
procedure ReleaseResource(s: PAVFormatContext);
var
  ctx: Pgdi_capture;
  I: Integer;
  pktl, next: PAVPacketList;
begin
  ctx := s.priv_data;
  ctx.Stoped := 1;

  if ctx.source_hdc <> 0 then
  begin
    ReleaseDC(ctx.window_handle, ctx.source_hdc); // GetDC/GetWindowDC -> ReleaseDC
    ctx.source_hdc := 0;
  end;
  if ctx.window_hdc <> 0 then
  begin
    DeleteDC(ctx.window_hdc); // CreateDC/CreateCompatibleDC -> DeleteDC
    ctx.window_hdc := 0;
  end;
  if ctx.hbmp <> 0 then
  begin
    DeleteObject(ctx.hbmp);
    ctx.hbmp := 0;
  end;
  if ctx.FrameForm <> nil then
  begin
    ctx.FrameForm.Release;
    ctx.FrameForm := nil;
  end;
  if ctx.ScreenThread <> nil then
  begin
    with TThread(ctx.ScreenThread) do
    begin
      Terminate;
      WaitFor;
      Free;
    end;
    ctx.ScreenThread := nil;
  end;

  // close wave device
  if ctx.WaveHandle <> 0 then
  begin
    waveInReset(ctx.WaveHandle);
    waveInClose(ctx.WaveHandle);
    ctx.WaveHandle := 0;
  end;

  // close mutex and event
  if ctx.mutex <> 0 then
  begin
    CloseHandle(ctx.mutex);
    ctx.mutex := 0;
  end;
  if ctx.event <> 0 then
  begin
    CloseHandle(ctx.event);
    ctx.event := 0;
  end;

  // free wave buffer
  for I := Low(ctx.WaveBuf) to High(ctx.WaveBuf) do
  begin
    if Assigned(ctx.WaveBuf[I]) then
    begin
      FreeMem(ctx.WaveBuf[I]);
      ctx.WaveBuf[I] := nil;
    end;
  end;

  // free pktl
  pktl := ctx.pktl;
  while Assigned(pktl) do
  begin
    next := pktl.next;
    av_destruct_packet(@pktl.pkt);
    av_free(pktl);
    pktl := next;
  end;

  ctx.s := nil;
end;

// queue next wave buffer
function PushNextBuffer(ctx: Pgdi_capture): Boolean;
var
  LRet: MMRESULT;
begin
  if ctx.WaveHandle = 0 then
  begin
    av_log(ctx.s, AV_LOG_DEBUG, 'WaveHandle is invalid.'#10);
    Result := False;
    Exit;
  end;

  // add wave buffer
  LRet := waveInAddBuffer(ctx.WaveHandle, ctx.WaveHdr[ctx.WaveBufIdx], SizeOf(TWaveHdr));
  if LRet <> MMSYSERR_NOERROR then
  begin
    ctx.Stoped := 1;
    ctx.error := AVERROR_EIO;
    av_log(ctx.s, AV_LOG_ERROR, PAnsiChar(AnsiString(waveInGetError(LRet)) + #10));
    Result := False;
    Exit;
  end;

  // toggle for next buffer index
  ctx.WaveBufIdx := (ctx.WaveBufIdx + 1) mod MAX_BUFFER_COUNT;
  Result := True;
end;

// waveIn callback
procedure waveInCallback(hwi: HWAVEIN; uMsg: UINT;
  dwInstance, dwParam1, dwParam2: DWORD{_PTR}); stdcall;
var
  ctx: Pgdi_capture;
  LBytes: DWORD;
  ppktl: PPAVPacketList;
  pktl_next: PAVPacketList;
  pts: Int64;
begin
  ctx := Pgdi_capture(dwInstance);

  if ctx.Stoped <> 0 then
    Exit;

  case uMsg of
    WIM_DATA: // wave data recorded
      begin
        pts := av_gettime - ctx.time_start;

        // bytes recorded
        LBytes := PWaveHdr(dwParam1).dwBytesRecorded;
        if LBytes = 0 then
        begin
          PushNextBuffer(ctx);
          Exit;
        end;

        // skip when not started
        if ctx.Started = 0 then
        begin
          PushNextBuffer(ctx);
          av_log(ctx.s, AV_LOG_DEBUG, 'not started, skip wave data %d bytes'#10, LBytes);
          Exit;
        end;

        // skip when paused
        if Assigned(ctx.Paused) and (ctx.Paused^ <> 0) then
        begin
          PushNextBuffer(ctx);
//          av_log(ctx.s, AV_LOG_DEBUG, 'paused, skip wave data %d bytes'#10, LBytes);
          Exit;
        end;

        // skip when screen frame not start
        if ctx.time_start = 0 then
        begin
          if ctx.screen <> 0 then
          begin
            PushNextBuffer(ctx);
//            av_log(ctx.s, AV_LOG_DEBUG, 'wait for screen frame, skipwave data %d bytes'#10, LBytes);
            Exit;
          end
          else
          begin
            ctx.time_start := av_gettime;
            //ctx.time_frame := Round(ctx.time_start * av_q2d(ctx.requested_framerate));
            pts := 0;
          end;
        end;

        // obtain mutex for writing
        WaitForSingleObject(ctx.mutex, INFINITE);
        try
          // create packet list
          pktl_next := av_mallocz(SizeOf(TAVPacketList));
          if not Assigned(pktl_next) then
          begin
            ctx.Stoped := 1;
            ctx.error := AVERROR_ENOMEM;
            av_log(ctx.s, AV_LOG_ERROR, 'av_mallocz() error'#10);
            Exit;
          end;

          // create packet
          if av_new_packet(@pktl_next.pkt, LBytes) < 0 then
          begin
            av_free(pktl_next);
            ctx.Stoped := 1;
            ctx.error := AVERROR_ENOMEM;
            av_log(ctx.s, AV_LOG_ERROR, 'av_new_packet() error'#10);
            Exit;
          end;

          // write wave data
          pktl_next.pkt.stream_index := ctx.wave_st_idx;
          pktl_next.pkt.pts := pts;
          Move(ctx.WaveBuf[ctx.WaveBufIdx]^, pktl_next.pkt.data^, LBytes);
          //av_log(ctx.s, AV_LOG_DEBUG, 'Wave data %d bytes'#10, LBytes);

          // add packet to list
          ppktl := @ctx.pktl;
          while Assigned(ppktl^) do
            ppktl := @ppktl^.next;
          ppktl^ := pktl_next;
          Inc(ctx.curbufsize, LBytes);

          SetEvent(ctx.event);
        finally
          ReleaseMutex(ctx.mutex);
        end;

        PushNextBuffer(ctx);
      end;
    WIM_OPEN: // <- waveInOpen()
      begin
        av_log(ctx.s, AV_LOG_INFO, 'waveIn device opened.'#10);
      end;
    WIM_CLOSE: // <- waveInClose()
      begin
        ctx.WaveHandle := 0;
        ctx.Stoped := 1;
        av_log(ctx.s, AV_LOG_INFO, 'waveIn device closed.'#10);
      end;
  end;
end;

// init wave device
function InitWaveDevice(ctx: Pgdi_capture): Boolean;
var
  I: Integer;
  LBufSize: DWORD;
  LRet: MMRESULT;
begin
  Result := False;

  // find a device compatible with the available wave characteristics
  // TODO: check device index
  if waveInGetNumDevs < 1 then
  begin
    av_log(ctx.s, AV_LOG_ERROR, 'No wave audio recording devices found.'#10);
    Exit;
  end;

// TODO: if waveInGetDevCaps(0, @m_WaveInDevCaps,sizeof(WAVEINCAPS));

  // init wave format structure
  FillChar(ctx.WaveFormat, SizeOf(TWaveFormatEx), 0);
  with ctx.WaveFormat do
  begin
    wFormatTag := WAVE_FORMAT_PCM;
    cbSize := 0;

    nSamplesPerSec := ctx.sample_rate;
    wBitsPerSample := ctx.sample_format;
    nChannels := ctx.channels;

    nBlockAlign := wBitsPerSample * nChannels div 8;
    if nBlockAlign = 0 then
      nBlockAlign := 1;
    nAvgBytesPerSec := nSamplesPerSec * nBlockAlign;
  end;

  // init wave header
  for I := Low(ctx.WaveHdr) to High(ctx.WaveHdr) do
  begin
    ctx.WaveHdr[I] := @ctx._WaveHdr[I];
    FillChar(ctx.WaveHdr[I]^, SizeOf(TWaveHdr), 0);
  end;

  // make the wave buffer size a multiple of the block align
  LBufSize := ctx.wave_bufsize - (ctx.wave_bufsize mod ctx.WaveFormat.nBlockAlign);
  // allocate the wave data buffer memory
  for I := Low(ctx.WaveBuf) to High(ctx.WaveBuf) do
  begin
    GetMem(ctx.WaveBuf[I], LBufSize);
    if ctx.WaveBuf[I] = nil then
    begin
      av_log(ctx.s, AV_LOG_ERROR, 'Error allocating wave buffer memory.'#10);
      Exit;
    end;
    FillChar(ctx.WaveBuf[I]^, LBufSize, 0);
    // assign wave buffer with wave header
    ctx.WaveHdr[I].dwBufferLength := LBufSize;
    ctx.WaveHdr[I].lpData := ctx.WaveBuf[I];
  end;

  // query the device for recording format
  LRet := waveInOpen(nil, ctx.device, @ctx.WaveFormat, 0, 0, WAVE_FORMAT_QUERY);
  if LRet <> MMSYSERR_NOERROR then
  begin
    av_log(ctx.s, AV_LOG_ERROR, PAnsiChar(AnsiString(waveInGetError(LRet)) + #10));
    Exit;
  end;

  // open the device
  LRet := waveInOpen(@ctx.WaveHandle, ctx.device, @ctx.WaveFormat,
                     DWORD(@waveInCallback), DWORD(ctx), CALLBACK_FUNCTION or {WAVE_FORMAT_DIRECT}8);
  if LRet <> MMSYSERR_NOERROR then
  begin
    av_log(ctx.s, AV_LOG_ERROR, PAnsiChar(AnsiString(waveInGetError(LRet)) + #10));
    Exit;
  end;

  // prepare wave header
  for I := Low(ctx.WaveHdr) to High(ctx.WaveHdr) do
    if waveInPrepareHeader(ctx.WaveHandle, ctx.WaveHdr[I], SizeOf(TWaveHdr)) <> MMSYSERR_NOERROR then
    begin
      av_log(ctx.s, AV_LOG_ERROR, PAnsiChar(AnsiString(waveInGetError(LRet)) + #10));
      Exit;
    end;

  // first wave buffer index
  ctx.WaveBufIdx := 0;

  // queue the wave buffers
  for I := 1 to MAX_BUFFER_COUNT do
    if not PushNextBuffer(ctx)  then
      Exit;

  // start recording to first buffer
  LRet := waveInStart(ctx.WaveHandle);
  if LRet <> MMSYSERR_NOERROR then
  begin
    av_log(ctx.s, AV_LOG_ERROR, PAnsiChar(AnsiString(waveInGetError(LRet)) + #10));
    Exit;
  end;

  Result := True;
end;

function parse_input(s: PAVFormatContext): Integer;
var
  ctx: Pgdi_capture;
  T, V, A: string;
label
  error;
begin
  Result := 0;
  ctx := s.priv_data;
  // filename format: video=hwnd:audio=device_id
  //  hwnd for screen capture: special window handle; 0 indicate desktop
  //  device_id for wave capture: device identifier, such as -1 for WAVE_MAPPER
  T := string(s.filename);
  if Pos('video=', T) = 1 then
  begin
    if Pos(':audio=', T) > 1 then
    begin
      A := Copy(T, Pos(':audio=', T) + Length(':audio='), MaxInt);
      if A = '' then
        A := '-1';  // default
      V := Copy(T, Length('video=') + 1, Pos(':audio=', T) - Length('video=') - 1);
      if V = '' then
        V := '0'; // default
    end
    else
    begin
      A := '';
      V := Copy(T, Length('video=') + 1, MaxInt);
      if V = '' then
        V := '0'; // default
    end;
  end
  else if Pos('audio=', T) = 1 then
  begin
    if Pos(':video=', T) > 1 then
    begin
      V := Copy(T, Pos(':video=', T) + Length(':video='), MaxInt);
      if V = '' then
        V := '0';  // default
      A := Copy(T, Length('audio=') + 1, Pos(':video=', T) - Length('audio=') - 1);
      if A = '' then
        A := '-1'; // default
    end
    else
    begin
      V := '';
      A := Copy(T, Length('audio=') + 1, MaxInt);
      if A = '' then
        A := '-1'; // default
    end;
  end
  else
  begin
    A := '';
    V := '';
    Result := AVERROR_EINVAL;
  end;

  // screen capture
  if (Result = 0) and (V <> '') then
  begin
    try
      // special window handle
      ctx.window_handle := StrToInt(V);
      ctx.screen := 1;
    except on E: Exception do
      begin
        av_log(s, AV_LOG_ERROR, 'Failed to parse "%s": %s'#10, s.filename, PAnsiChar(AnsiString(E.Message)));
        Result := AVERROR_EINVAL;
      end;
    end;
  end;

  // wave capture
  if (Result = 0) and (A <> '') then
  begin
    try
      ctx.device := StrToInt(A);
      ctx.wave := 1;
    except on E: Exception do
      begin
        av_log(s, AV_LOG_ERROR, 'Failed to parse "%s": %s'#10, s.filename, PAnsiChar(AnsiString(E.Message)));
        Result := AVERROR_EINVAL;
      end;
    end;
  end;

  if Result < 0 then
    av_log(s, AV_LOG_ERROR, 'Invalid parameters, it should be "video=hwnd:audio=device_id"'#10);
end;

function parse_screen(s: PAVFormatContext): Integer;
var
  ctx: Pgdi_capture;
  p: PAnsiChar;
begin
  ctx := s.priv_data;

  // video frame rate
  if av_parse_video_rate(@ctx.requested_framerate, ctx.framerate_str) < 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Could not parse framerate "%s".'#10, ctx.framerate_str);
    Result := AVERROR_EINVAL;
    Exit;
  end;
  if (ctx.requested_framerate.num = 0) or (ctx.requested_framerate.den = 0) then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid frame rate "%s".'#10, ctx.framerate_str);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  // video frame size
  if Assigned(ctx.video_size) and (ctx.video_size <> '') then
  begin
    if av_parse_video_size(@ctx.requested_width, @ctx.requested_height, ctx.video_size) < 0 then
    begin
      av_log(s, AV_LOG_ERROR, 'Could not parse video size "%s".'#10, ctx.video_size);
      Result := AVERROR_EINVAL;
      Exit;
    end;
    if (ctx.requested_width <= 0) or (ctx.requested_height <= 0) then
    begin
      av_log(s, AV_LOG_ERROR, 'Invalid frame size "%s".'#10, ctx.video_size);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end;

  // capture offset %d,%d: offset on x and y against the final source window
  if Assigned(ctx.capture_offset) and (ctx.capture_offset <> '') then
  begin
    ctx.x_off := my_strtol(ctx.capture_offset, @p, 10);
    if not Assigned(p) or (p^ <> ',') then
    begin
      av_log(s, AV_LOG_ERROR, 'Could not parse capture-offset "%s".'#10, ctx.capture_offset);
      Result := AVERROR_EINVAL;
      Exit;
    end;
    Inc(p);
    ctx.y_off := my_strtol(p, @p, 10);
    if Assigned(p) and (p^ <> #0) then
    begin
      av_log(s, AV_LOG_ERROR, 'Could not parse capture-offset "%s".'#10, ctx.capture_offset);
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

  Result := 0;
end;

function parse_wave(s: PAVFormatContext): Integer;
var
  ctx: Pgdi_capture;
begin
  ctx := s.priv_data;

  // sample format, u8 or s16
  if Assigned(ctx.sample_fmt_str) and (ctx.sample_fmt_str <> '') then
  begin
    ctx.sample_fmt := av_get_sample_fmt(ctx.sample_fmt_str);
    if ctx.sample_fmt = AV_SAMPLE_FMT_U8 then
    begin
      ctx.sample_format := 8;
      ctx.wave_codec_id := AV_CODEC_ID_PCM_U8;
    end
    else if ctx.sample_fmt = AV_SAMPLE_FMT_S16 then
    begin
      ctx.sample_format := 16;
      ctx.wave_codec_id := AV_CODEC_ID_PCM_S16LE;
    end
{
    else if ctx.sample_fmt = AV_SAMPLE_FMT_S32 then
    begin
      ctx.sample_format := 32;
      ctx.wave_codec_id := AV_CODEC_ID_PCM_S32LE;
    end
}
    else
    begin
      av_log(s, AV_LOG_ERROR, 'Invalid sample format: "%s", it should be u8 or s16'#10, ctx.sample_fmt_str);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end
  else
  begin
    ctx.sample_fmt := AV_SAMPLE_FMT_S16;
    ctx.sample_format := 16;
    ctx.wave_codec_id := AV_CODEC_ID_PCM_S16LE;
  end;

  // check buffer size
  if ctx.wave_bufsize <= 0 then
    ctx.wave_bufsize := WAVE_BUFFER_SIZE;

  // check sample rate
  if ctx.sample_rate <= 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid sample rate %d'#10, ctx.sample_rate);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  // check channels
  if ctx.channels <= 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid channels %d'#10, ctx.channels);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  Result := 0;
end;

function open_screen(s: PAVFormatContext): Integer;
var
  ctx: Pgdi_capture;
  screenwidth: Longint;
  screenheight: Longint;
  bmp: BITMAP;
  dim: TRect;
  errcode: Integer;
  errmsg: string;
begin
  ctx := s.priv_data;

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

  screenwidth := GetSystemMetrics(SM_CXVIRTUALSCREEN);
  screenheight := GetSystemMetrics(SM_CYVIRTUALSCREEN);
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
  if ctx.requested_width > 0 then
    ctx.width := ctx.requested_width;
  if ctx.requested_height > 0 then
    ctx.height := ctx.requested_height;

  if ctx.x_off + ctx.width > screenwidth then
    ctx.width := screenwidth - ctx.x_off;
  if ctx.y_off + ctx.height > screenheight then
    ctx.height := screenheight - ctx.y_off;

  if (ctx.width <= 0) or (ctx.height <= 0) then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid offset %s or size %s, aborting.'#10,
                             ctx.capture_offset, ctx.video_size);
    Result := AVERROR_EIO;
    Exit;
  end;

  ctx.bpp := GetDeviceCaps(ctx.source_hdc, BITSPIXEL);

  if ctx.bpp mod 8 <> 0 then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid properties, aborting.'#10);
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
    8:  ctx.pix_fmt := AV_PIX_FMT_PAL8;  // AV_PIX_FMT_RGB8 ?
    16: ctx.pix_fmt := AV_PIX_FMT_RGB555;
    24: ctx.pix_fmt := AV_PIX_FMT_BGR24;
    32: ctx.pix_fmt := AV_PIX_FMT_RGB32;
  else
    av_log(s, AV_LOG_ERROR, 'image depth %i not supported ... aborting'#10, ctx.bpp);
    Result := AVERROR_EIO;
    Exit;
  end;
  ctx.bmp_size := bmp.bmWidthBytes * bmp.bmHeight * bmp.bmPlanes;

  ctx.ScreenThread := TScreenThread.Create(s);

  Result := 0;
end;

function open_wave(s: PAVFormatContext): Integer;
var
  ctx: Pgdi_capture;
begin
  ctx := s.priv_data;

  // init wave device
  if InitWaveDevice(ctx) then
    Result := 0
  else
    Result := AVERROR_EIO;
end;

function add_screen(s: PAVFormatContext): Integer;
//const
//  BottomUp: AnsiString = 'BottomUp';
var
  ctx: Pgdi_capture;
  st: PAVStream;
begin
  ctx := s.priv_data;

  // new stream
  st := avformat_new_stream(s, nil);
  if st = nil then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;
  st.id := 0;
  ctx.screen_st_idx := st.index;

  st.codec.codec_type := AVMEDIA_TYPE_VIDEO;
  st.codec.codec_id   := AV_CODEC_ID_RAWVIDEO;
  st.codec.width      := ctx.width;
  st.codec.height     := ctx.height;
  st.codec.pix_fmt    := ctx.pix_fmt;
//  st.codec.time_base.num := ctx.requested_framerate.den * AV_TIME_BASE{1000000} div ctx.requested_framerate.num;
//  st.codec.time_base.den := AV_TIME_BASE;
  st.codec.time_base.num := ctx.requested_framerate.den;
  st.codec.time_base.den := ctx.requested_framerate.num;
  st.codec.bit_rate   := Round(ctx.bmp_size * av_q2d(ctx.requested_framerate) * 8);
  Inc(s.bit_rate, st.codec.bit_rate);
//  st.codec.bits_per_coded_sample := ctx.bpp;
{
  st.codec.extradata := av_mallocz(9 + FF_INPUT_BUFFER_PADDING_SIZE);
  if Assigned(st.codec.extradata) then
  begin
    st.codec.extradata_size := 9;
    Move(BottomUp[1], st.codec.extradata^, 9);
  end;
}
  st.codec.thread_count := 1; // avoid multithreading issue of log callback

  // !!! to avoid av_find_stream_info() to read packets
  // condition 1
  st.r_frame_rate := ctx.requested_framerate;
  st.avg_frame_rate := ctx.requested_framerate;
  // condition 2
  s.flags := s.flags or AVFMT_FLAG_NOPARSE;
  // condition 3
  st.first_dts := 0;
  // condition ALL
  s.probesize := 0; // 32
  //s.fps_probe_size := 0;

  av_set_pts_info(st, 64, 1, AV_TIME_BASE_I{1000000}); (* 64 bits pts in us *)

  if ctx.show_frame <> 0 then
    ctx.FrameForm := TFrameForm.Create(ctx);

  av_log(s, AV_LOG_INFO, 'ready for screen capturing %ix%ix%i at (%i,%i)'#10,
         ctx.width, ctx.height, ctx.bpp, ctx.x_off, ctx.y_off);

  Result := 0;
end;

function add_wave(s: PAVFormatContext): Integer;
var
  ctx: Pgdi_capture;
  st: PAVStream;
begin
  ctx := s.priv_data;

  // new stream
  st := avformat_new_stream(s, nil);
  if st = nil then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;
  st.id := 1;
  ctx.wave_st_idx := st.index;

  st.codec.codec_type   := AVMEDIA_TYPE_AUDIO;
  st.codec.codec_id     := ctx.wave_codec_id;
  st.codec.channels     := ctx.channels;
  st.codec.sample_rate  := ctx.sample_rate;
  st.codec.block_align  := ctx.WaveFormat.nBlockAlign;
  st.codec.sample_fmt   := ctx.sample_fmt;
  st.codec.bit_rate     := ctx.sample_rate * ctx.channels * ctx.sample_format;
  Inc(s.bit_rate, st.codec.bit_rate);
//  st.codec.frame_size   := ctx.frame_size;
//  st.codec.bits_per_coded_sample := ctx.sample_format;
  st.codec.thread_count := 1; // avoid multithreading issue of log callback

  // !!! to avoid av_find_stream_info() to read packets
  // condition 1
//  st.r_frame_rate := ctx.requested_framerate;
//  st.avg_frame_rate := ctx.requested_framerate;
  // condition 2
  s.flags := s.flags or AVFMT_FLAG_NOPARSE;
  // condition 3
  st.first_dts := 0;
  // condition ALL
  s.probesize := 0; // 32
  //s.fps_probe_size := 0;

//  av_set_pts_info(st, 64, 1, ctx.sample_rate);
  av_set_pts_info(st, 64, 1, AV_TIME_BASE_I{1000000}); (* 64 bits pts in us *)

  av_log(s, AV_LOG_INFO, 'ready for wave recording...'#10);

  Result := 0;
end;

function gdi_capture_read_header(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pgdi_capture;
  ret: Integer;
begin
  ctx := s.priv_data;
  ctx.s := s;
//  ctx.frame_size := AUDIO_BLOCK_SIZE;
  s.max_picture_buffer := s.max_picture_buffer * 10; // -rtbufsize 3041280 * 10

  // parse input
  ret := parse_input(s);

  // create mutex
  if ret = 0 then
  begin
    ctx.mutex := CreateMutex(nil, False, nil);
    if ctx.mutex = 0 then
    begin
      av_log(s, AV_LOG_ERROR, 'Could not create Mutex.'#10);
      ret := AVERROR_EIO;
    end;
  end;

  // create event
  if ret = 0 then
  begin
    ctx.event := CreateEvent(nil, True, False, nil);
    if ctx.event = 0 then
    begin
      av_log(s, AV_LOG_ERROR, 'Could not create Event.'#10);
      ret := AVERROR_EIO;
    end;
  end;

  // init screen capture
  if (ret = 0) and (ctx.screen <> 0) then
    ret := parse_screen(s);
  if (ret = 0) and (ctx.screen <> 0) then
    ret := open_screen(s);
  if (ret = 0) and (ctx.screen <> 0) then
    ret := add_screen(s);

  // init wave capture
  if (ret = 0) and (ctx.wave <> 0) then
    ret := parse_wave(s);
  if (ret = 0) and (ctx.wave <> 0) then
    ret := open_wave(s);
  if (ret = 0) and (ctx.wave <> 0) then
    ret := add_wave(s);

  if ret < 0 then
    ReleaseResource(s);

  Result := ret;
end;

function gdi_capture_read_packet(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;
var
  ctx: Pgdi_capture;
  pktl: PAVPacketList;
begin
  ctx := s.priv_data;

  if ctx.Started = 0 then
  begin
    ctx.Started := 1;
{$IFNDEF FPC}
    av_log(s, AV_LOG_DEBUG, 'Count of GDI objects: %d, Count of USER objects: %d'#10,
           GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS), GetGuiResources(GetCurrentProcess, GR_USEROBJECTS));
{$ENDIF}
  end;

  if ctx.Stoped <> 0 then
  begin
    if ctx.error < 0 then
      Result := ctx.error
    else
      Result := AVERROR_EOF;
    Exit;
  end;

  pktl := nil;
  while not Assigned(pktl) do
  begin
    // obtain mutex for reading
    WaitForSingleObject(ctx.mutex, INFINITE);
    pktl := ctx.pktl;
    if Assigned(pktl) then
    begin
      pkt^ := pktl.pkt;
      ctx.pktl := pktl.next;
      av_free(pktl);
      Dec(ctx.curbufsize, pkt.size);
    end;
    ResetEvent(ctx.event);
    ReleaseMutex(ctx.mutex);

    // wait for packet incoming
    if not Assigned(pktl) then
    begin
      if (s.flags and AVFMT_FLAG_NONBLOCK) <> 0 then
      begin
        av_log(ctx.s, AV_LOG_DEBUG, 'non-block, need read again'#10);
        Result := AVERROR_EAGAIN;
        Exit;
      end
      else
      begin
        //WaitForSingleObject(ctx.event, INFINITE);
        if WaitForSingleObject(ctx.event, 1000) <> WAIT_OBJECT_0 then
        begin
          av_log(ctx.s, AV_LOG_DEBUG, 'wait timeout, need read again'#10);
          Result := AVERROR_EAGAIN;
          Exit;
        end;

        if ctx.Stoped <> 0 then
        begin
          if ctx.error < 0 then
            Result := ctx.error
          else
            Result := AVERROR_EOF;
          Exit;
        end;
      end;
    end;
  end;
  Result := pkt.size;
end;

function gdi_capture_read_close(s: PAVFormatContext): Integer; cdecl;
begin
{$IFNDEF FPC}
  av_log(s, AV_LOG_DEBUG, 'Count of GDI objects: %d, Count of USER objects: %d'#10,
         GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS), GetGuiResources(GetCurrentProcess, GR_USEROBJECTS));
{$ENDIF}
  ReleaseResource(s);
  Result := 0;
end;

var
  options: array[0..12] of TAVOption = (
    // *** screen capture ***
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
    // *** wave capture ***
    (name       : 'sample_rate';
     help       : 'set audio sampling rate (in Hz)';
     offset     : -1;
     ttype      : AV_OPT_TYPE_INT;
     default_val: (i64: 44100);
     min        : 0;
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'channels';
     help       : 'set number of audio channels';
     offset     : -1;
     ttype      : AV_OPT_TYPE_INT;
     default_val: (i64: 2);
     min        : 0;
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'sample_fmt';
     help       : 'set sample format';
     offset     : -1;
     ttype      : AV_OPT_TYPE_STRING;
     default_val: (str: 's16');
     min        : 0;
     max        : 0;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'wavebufsize';
     help       : 'waveIn buffer size';
     offset     : -1;
     ttype      : AV_OPT_TYPE_INT;
     default_val: (i64: WAVE_BUFFER_SIZE);
     min        : 0;
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'pause_pointer';
     help       : 'integer value of pause flag pointer';
     offset     : -1;
     ttype      : AV_OPT_TYPE_INT;
     default_val: (i64: 0);
     min        : Low(Integer);
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : nil;)
  );

  gdi_capture_class: TAVClass = (
    class_name: 'ScreenCaptureFormat';
    //item_name : av_default_item_name;
    option    : @options[0];
    version   : LIBAVUTIL_VERSION_INT;
  );

  gdi_capture_demuxer: TAVInputFormat = (
    name: 'gdicapture';
    long_name: 'GDI(Screen/Wave) capture';
    flags: AVFMT_NOFILE;
    priv_class: @gdi_capture_class;
    priv_data_size: SizeOf(Tgdi_capture);
    read_header: gdi_capture_read_header;
    read_packet: gdi_capture_read_packet;
    read_close: gdi_capture_read_close;
  );

procedure register_gdicapture;
var
  ctx: Tgdi_capture;
begin
  Assert(Assigned(av_default_item_name));
  gdi_capture_class.item_name := av_default_item_name;
  // *** screen capture ***
  options[0].offset := Integer(@ctx.video_size) - Integer(@ctx);
  options[1].offset := Integer(@ctx.framerate_str) - Integer(@ctx);
  options[2].offset := Integer(@ctx.capture_offset) - Integer(@ctx);
  options[3].offset := Integer(@ctx.capture_flags) - Integer(@ctx);
  // *** wave capture ***
  options[07].offset := Integer(@ctx.sample_rate) - Integer(@ctx);
  options[08].offset := Integer(@ctx.channels) - Integer(@ctx);
  options[09].offset := Integer(@ctx.sample_fmt_str) - Integer(@ctx);
  options[10].offset := Integer(@ctx.wave_bufsize) - Integer(@ctx);
  options[11].offset := Integer(@ctx.Paused) - Integer(@ctx);
  RegisterInputFormat(@gdi_capture_demuxer);
end;

end.
