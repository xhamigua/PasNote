(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * frame input interface
 * Created by CodeCoolie@CNSW 2009/09/07 -> $Date:: 2013-09-17 #$
 *)

unit FrameInput;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
  {$ENDIF}
  System.SysUtils,
  System.Classes,
  {$IFDEF FFFMX}
    {$IFDEF VCL_XE5_OR_ABOVE}
      FMX.Graphics,
    {$ELSE}
      FMX.Types,
    {$ENDIF}
  {$ELSE}
    Vcl.Graphics,
  {$ENDIF}
{$ELSE}
  Windows,
  SysUtils,
  Classes,
  Graphics,
{$ENDIF}

{$IFDEF FPC}
  IntfGraphics, // TLazIntfImage
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

  FFBaseComponent,
  FFUtils,
  MyUtils;

type
  PInputFrameInfo = ^TInputFrameInfo;
  TInputFrameInfo = record
    TimeStamp: Int64;
    LastTimeStamp: Int64;
    FrameNumber: Integer;
    Width: Integer;
    Height: Integer;
    BitsPerPixel: Integer;        // for RGB only
    BytesPerLine: Integer;        // for RGB only
    BytesPerFrame: Integer;
    PixelFormat: TAVPixelFormat;
  end;

  TReadFrameCanvasEvent = function(Sender: TObject; ACanvas: TCanvas;
    AFrameInfo: PInputFrameInfo): Integer of object;
  TReadFrameDataEvent = function(Sender: TObject; AData: Pointer;
    AFrameInfo: PInputFrameInfo): Integer of object;
{$IFDEF MSWINDOWS}
  TReadFrameDCEvent = function(Sender: TObject; ADC: HDC;
    AFrameInfo: PInputFrameInfo): Integer of object;
{$ENDIF}

  TFrameInputAdapter = class(TFFBaseComponent)
  private
    FData: Pointer;
    FResult: Integer;
    FTriggerEventInMainThread: Boolean;
    FFrameInfo: PInputFrameInfo;
    Fframe_input: Pointer;
    FOnReadHeader: TNotifyEvent;
    FOnReadClose: TNotifyEvent;
    FOnReadFrameCanvas: TReadFrameCanvasEvent;
    FOnReadFrameBMP: TReadFrameDataEvent;
{$IFDEF MSWINDOWS}
    FOnReadFrameDC: TReadFrameDCEvent;
{$ENDIF}
    FOnReadFrameYUV: TReadFrameDataEvent;
  protected
    procedure CallReadHeader;
    procedure ReadHeader;
    procedure CallReadClose;
    procedure ReadClose;
    procedure CallReadFrameCanvas;
    function ReadFrameCanvas: Integer;
    procedure CallReadFrameBMP;
    function ReadFrameBMP: Integer;
{$IFDEF MSWINDOWS}
    procedure CallReadFrameDC;
    function ReadFrameDC: Integer;
{$ENDIF}
    procedure CallReadFrameYUV;
    function ReadFrameYUV: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property FrameInfo: PInputFrameInfo read FFrameInfo;
    property UserData: Pointer read FData write FData;
  published
    property TriggerEventInMainThread: Boolean read FTriggerEventInMainThread write FTriggerEventInMainThread default True;
    property OnReadHeader: TNotifyEvent read FOnReadHeader write FOnReadHeader;
    property OnReadClose: TNotifyEvent read FOnReadClose write FOnReadClose;
    property OnReadFrameCanvas: TReadFrameCanvasEvent read FOnReadFrameCanvas write FOnReadFrameCanvas;
    property OnReadFrameBMP: TReadFrameDataEvent read FOnReadFrameBMP write FOnReadFrameBMP;
{$IFDEF MSWINDOWS}
    property OnReadFrameDC: TReadFrameDCEvent read FOnReadFrameDC write FOnReadFrameDC;
{$ENDIF}
    property OnReadFrameYUV: TReadFrameDataEvent read FOnReadFrameYUV write FOnReadFrameYUV;
  end;

procedure register_frameinput;

implementation

type
  TInputType = (
    itYUV,        // YUV data
    itBMP,        // Bitmap data
    itCanvas      // Bitmap canvas
{$IFDEF MSWINDOWS}
    , itHDC       // Bitmap HDC
{$ENDIF}
  );

  Pframe_input = ^Tframe_input;
  Tframe_input = record
    class_: PAVClass;
    pts: Int64;             // timestamp
    last_pts: Int64;        // last timestamp
    frame_number: Integer;  // current frame number
    width: Integer;         // width of the frame
    height: Integer;        // height of the frame
    bpp: Integer;           // bits per pixel of the frame, for RGB only
    bpl: Integer;           // bytes per line of the frame, for RGB only
    size: Integer;          // size in bytes of the frame
    pix_fmt: TAVPixelFormat;

    input_type: TInputType;

{$IFDEF MSWINDOWS}
    hbmp: HBITMAP;          // DIB
    dc: HDC;                // DC
{$ENDIF}
    pBits: Pointer;         // pointer to the location of the DIB bit values
    bmp: TBitmap;           // Bitmap
{$IFDEF FPC}
    IntfImg: TLazIntfImage;
{$ENDIF}
    canvas: TCanvas;        // Canvas
    pkt: PAVPacket;

    time_base: TAVRational; // time base
    time_frame: Int64;      // current time

    input_type_str: PAnsiChar;    // set by a private option
    pixel_format: PAnsiChar;      // set by a private option
    video_size: PAnsiChar;        (**< A string describing video size, set by a private option. *)
    framerate: PAnsiChar;         (**< Set by a private option. *)

    adapter: TFrameInputAdapter;  // frame input adapter
  end;

{ TFrameInputAdapter }

constructor TFrameInputAdapter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTriggerEventInMainThread := True;
end;

destructor TFrameInputAdapter.Destroy;
begin
  FOnReadHeader := nil;
  FOnReadClose := nil;
  FOnReadFrameCanvas := nil;
  FOnReadFrameBMP := nil;
{$IFDEF MSWINDOWS}
  FOnReadFrameDC := nil;
{$ENDIF}
  inherited Destroy;
end;

procedure TFrameInputAdapter.CallReadHeader;
begin
  FOnReadHeader(Self);
end;

procedure TFrameInputAdapter.ReadHeader;
begin
  if Assigned(FOnReadHeader) then
    if FTriggerEventInMainThread then
      MySynchronize(CallReadHeader)
    else
      CallReadHeader;
end;

procedure TFrameInputAdapter.CallReadClose;
begin
  FOnReadClose(Self);
end;

procedure TFrameInputAdapter.ReadClose;
begin
  if Assigned(FOnReadClose) then
    if FTriggerEventInMainThread then
      MySynchronize(CallReadClose)
    else
      CallReadClose;
end;

procedure TFrameInputAdapter.CallReadFrameCanvas;
begin
  FResult := FOnReadFrameCanvas(Self, Pframe_input(Fframe_input).canvas, FFrameInfo)
end;

function TFrameInputAdapter.ReadFrameCanvas: Integer;
begin
  if Assigned(FOnReadFrameCanvas) then
  begin
    if FTriggerEventInMainThread then
      MySynchronize(CallReadFrameCanvas)
    else
    begin
{$IFDEF FFFMX}
      Pframe_input(Fframe_input).canvas.BeginScene;
{$ELSE}
      Pframe_input(Fframe_input).canvas.Lock;
{$ENDIF}
      try
        CallReadFrameCanvas;
      finally
{$IFDEF FFFMX}
        Pframe_input(Fframe_input).canvas.EndScene;
{$ELSE}
        Pframe_input(Fframe_input).canvas.Unlock;
{$ENDIF}
      end;
    end;
    Result := FResult;
  end
  else
    Result := -1;
end;

procedure TFrameInputAdapter.CallReadFrameBMP;
begin
  FResult := FOnReadFrameBMP(Self, Pframe_input(Fframe_input).pBits, FFrameInfo)
end;

function TFrameInputAdapter.ReadFrameBMP: Integer;
{$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE)}
var
  D: TBitmapData;
{$IFEND}
begin
  if Assigned(FOnReadFrameBMP) then
  begin
{$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE)}
    if Pframe_input(Fframe_input).bmp.Map(TMapAccess.maWrite, D) then
    begin
      try
        Pframe_input(Fframe_input).pBits := PAnsiChar(D.Data);
{$IFEND}
    if FTriggerEventInMainThread then
      MySynchronize(CallReadFrameBMP)
    else
      CallReadFrameBMP;
    Result := FResult;
{$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE)}
      finally
        Pframe_input(Fframe_input).bmp.Unmap(D);
      end;
    end
    else
    begin
      av_log(nil, AV_LOG_ERROR, 'Could not map Bitmap.'#10);
      Result := -1;
    end;
{$IFEND}
  end
  else
    Result := -1;
end;

{$IFDEF MSWINDOWS}
procedure TFrameInputAdapter.CallReadFrameDC;
begin
  FResult := FOnReadFrameDC(Self, Pframe_input(Fframe_input).dc, FFrameInfo)
end;

function TFrameInputAdapter.ReadFrameDC: Integer;
begin
  if Assigned(FOnReadFrameDC) then
  begin
    if FTriggerEventInMainThread then
      MySynchronize(CallReadFrameDC)
    else
      CallReadFrameDC;
    Result := FResult;
  end
  else
    Result := -1;
end;
{$ENDIF}

procedure TFrameInputAdapter.CallReadFrameYUV;
begin
  FResult := FOnReadFrameYUV(Self, Pframe_input(Fframe_input).pkt.data, FFrameInfo)
end;

function TFrameInputAdapter.ReadFrameYUV: Integer;
begin
  if Assigned(FOnReadFrameYUV) then
  begin
    if FTriggerEventInMainThread then
      MySynchronize(CallReadFrameYUV)
    else
      CallReadFrameYUV;
    Result := FResult;
  end
  else
    Result := -1;
end;

// release resource
procedure release_resource(ctx: Pframe_input);
begin
{$IFDEF MSWINDOWS}
  if ctx.dc <> 0 then
  begin
    DeleteDC(ctx.dc);
    ctx.dc := 0;
  end;
  if ctx.hbmp <> 0 then
  begin
    DeleteObject(ctx.hbmp);
    ctx.hbmp := 0;
  end;
{$ENDIF}
  if ctx.bmp <> nil then
  begin
    ctx.bmp.Free;
    ctx.bmp := nil;
  end;
{$IFDEF FPC}
  if ctx.IntfImg <> nil then
  begin
    ctx.IntfImg.Free;
    ctx.IntfImg := nil;
  end;
{$ENDIF}
end;

function frameinput_read_header(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pframe_input;
  ret: Integer;
  framerate_q: TAVRational;
{$IFNDEF FFFMX}
  LPixelFormat: TPixelFormat;
{$ENDIF}
{$IFDEF MSWINDOWS}
  bi: BITMAPINFO;
  bmp: BITMAP;
{$ENDIF}
  st: PAVStream;
begin
  ctx := s.priv_data;
{$IFNDEF FFFMX}
  LPixelFormat := pf24bit; {stop compiler warning}
{$ENDIF}

  // FrameInputAdapter
  try
    ctx.adapter := TFrameInputAdapter(StrToInt(string(s.filename)));
  except on E: Exception do
    begin
      av_log(s, AV_LOG_ERROR, 'Could not parse FrameInputAdapter: "%s", ' +
        'it should be address of FrameInputAdapter'#10, s.filename);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end;
  if not Assigned(ctx.adapter) then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid FrameInputAdapter'#10);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  // frame input type, one of {canvas, bmp, dc, yuv}, default yuv
  if Assigned(ctx.input_type_str) and (ctx.input_type_str <> '') then
  begin
    if ctx.input_type_str = 'canvas' then
      ctx.input_type := itCanvas  // Bitmap canvas
    else if ctx.input_type_str = 'bmp' then
      ctx.input_type := itBMP     // Bitmap data
    else if ctx.input_type_str = 'yuv' then
      ctx.input_type := itYUV     // YUV data
{$IFDEF MSWINDOWS}
    else if ctx.input_type_str = 'dc' then
      ctx.input_type := itHDC     // Bitmap HDC
{$ENDIF}
    else
    begin
      av_log(s, AV_LOG_ERROR, 'Invalid frame input type: "%s", ' +
        'it should be one of canvas/bmp/dc/yuv'#10, ctx.input_type_str);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end
  else
    ctx.input_type := itYUV;

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
    ret := av_parse_video_size(@ctx.width, @ctx.height, ctx.video_size);
    if ret < 0 then
    begin
      av_log(s, AV_LOG_ERROR, 'Couldn''t parse video size.'#10);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end;
  if (ctx.width <= 0) or (ctx.height <= 0) then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid frame size'#10);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  // video frame pixel format
  if Assigned(ctx.pixel_format) and (ctx.pixel_format <> '') then
  begin
    ctx.pix_fmt := av_get_pix_fmt(ctx.pixel_format);
    if ctx.pix_fmt = AV_PIX_FMT_NONE then
    begin
      av_log(s, AV_LOG_ERROR, 'Unknown pixel format requested'#10);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end
  else
    ctx.pix_fmt := AV_PIX_FMT_YUV420P;

  // check pixel format for canvas/bmp/dc
{$IFDEF MSWINDOWS}
  if ctx.input_type in [itCanvas, itBMP, itHDC] then
{$ELSE}
  if ctx.input_type in [itCanvas, itBMP] then
{$ENDIF}
  begin
    // pal8/rgb555le/bgr24/bgra for canvas/bmp/dc
    case ctx.pix_fmt of
{$IFNDEF FPC}
      AV_PIX_FMT_PAL8:
        begin
          ctx.bpp := 8;
{$IFNDEF FFFMX}
          LPixelFormat := pf8bit;
{$ENDIF}
        end;
      AV_PIX_FMT_RGB555:
        begin
          ctx.bpp := 16;
{$IFNDEF FFFMX}
          LPixelFormat := pf16bit;
{$ENDIF}
        end;
{$ENDIF}
      AV_PIX_FMT_BGR24:
        begin
          ctx.bpp := 24;
{$IFNDEF FFFMX}
          LPixelFormat := pf24bit;
{$ENDIF}
        end;
      AV_PIX_FMT_RGB32:
        begin
          ctx.bpp := 32;
{$IFNDEF FFFMX}
          LPixelFormat := pf32bit;
{$ENDIF}
        end;
    else
      av_log(s, AV_LOG_ERROR, 'Invalid pixel format for canvas/bmp/dc input, should be one of pal8/rgb555le/bgr24/bgra'#10);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end;

{$IFDEF MSWINDOWS}
  if ctx.input_type = itHDC then
  begin // for HDC
    // create DIB
    with bi.bmiHeader do
    begin
      biSize := SizeOf(BITMAPINFOHEADER);
      biWidth := ctx.width;
      biHeight := ctx.height;
      biPlanes := 1;
      biBitCount := ctx.bpp;
      biCompression := BI_RGB;
      biSizeImage := ctx.width * ctx.height * ctx.bpp div 8;
    end;
    ctx.hbmp := CreateDIBSection(0, bi, DIB_RGB_COLORS, ctx.pBits, 0, 0);
    if ctx.hbmp = 0 then
    begin
      av_log(s, AV_LOG_ERROR, 'CreateDIBSection error #%li'#10, GetLastError);
      Result := AVERROR_EIO;
      Exit;
    end;

    // create DC
    ctx.dc := CreateCompatibleDC(0);
{$IFDEF VCL_XE2_OR_ABOVE}
    if SelectObject(ctx.dc, ctx.hbmp) = Winapi.Windows.ERROR then
{$ELSE}
    if SelectObject(ctx.dc, ctx.hbmp) = Windows.ERROR then
{$ENDIF}
    begin
      av_log(s, AV_LOG_ERROR, 'SelectObject error #%li'#10, GetLastError);
      release_resource(ctx);
      Result := AVERROR_EIO;
      Exit;
    end;

    // calculate the data size in bytes per frame
    GetObject(ctx.hbmp, SizeOf(BITMAP), @bmp);
    ctx.size := bmp.bmWidthBytes * bmp.bmHeight * bmp.bmPlanes;
  end
  else
{$ENDIF}
  if ctx.input_type in [itCanvas, itBMP] then
  begin // for Bitmap canvas or Bitmap data
    // create TBitmap
{$IFDEF FFFMX}
    ctx.bmp := TBitmap.Create(ctx.width, ctx.height);
{$ELSE}
    ctx.bmp := TBitmap.Create;
{$IFDEF VCL_10_OR_ABOVE}
    ctx.bmp.SetSize(ctx.width, ctx.height);
{$ELSE}
    ctx.bmp.Width := ctx.width;
    ctx.bmp.Height := ctx.height;
{$ENDIF}
    ctx.bmp.PixelFormat := LPixelFormat;
{$ENDIF}
    ctx.canvas := ctx.bmp.Canvas;
{$IFDEF FPC}
    ctx.IntfImg := TLazIntfImage.Create(0, 0);
    if ctx.bmp.PixelFormat = pf24bit then
      ctx.IntfImg.DataDescription.Init_BPP24_B8G8R8_BIO_TTB(ctx.width, ctx.height)
    else
    begin
      Assert(ctx.bmp.PixelFormat = pf32bit);
      ctx.IntfImg.DataDescription.Init_BPP32_B8G8R8A8_BIO_TTB(ctx.width, ctx.height);
    end;
    ctx.IntfImg.SetSize(ctx.width, ctx.height);
    ctx.pBits := ctx.IntfImg.PixelData;
{$ELSE}
  {$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE)}
    ctx.pBits := nil;
  {$ELSE}
    ctx.pBits := ctx.bmp.ScanLine[ctx.height - 1]; // for writing
  {$IFEND}
{$ENDIF}
    ctx.size := BytesPerScanline(ctx.width, ctx.bpp, 32) * ctx.height;
  end
  else // if ctx.input_type = itYUV then
  begin
    // for YUV data
    ctx.size := avpicture_get_size(ctx.pix_fmt, ctx.width, ctx.height);
    if ctx.size < 0 then
    begin
      av_log(s, AV_LOG_ERROR, 'avpicture_get_size() failed'#10);
      Result := AVERROR_EIO;
      Exit;
    end;
  end;

  ctx.bpl := BytesPerScanline(ctx.width, ctx.bpp, 32);

  // create stream
  st := avformat_new_stream(s, nil);
  if st = nil then
  begin
    release_resource(ctx);
    Result := AVERROR_ENOMEM;
    Exit;
  end;

  av_set_pts_info(st, 64, 1, 1000000);

  with st.codec^ do
  begin
    codec_type := AVMEDIA_TYPE_VIDEO;
    codec_id   := AV_CODEC_ID_RAWVIDEO;
    width      := ctx.width;
    height     := ctx.height;
    time_base  := ctx.time_base;
    bit_rate   := Round(ctx.size / av_q2d(ctx.time_base) * 8);
    pix_fmt    := ctx.pix_fmt;
    thread_count := 1; // avoid multithreading issue of log callback
  end;

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

  ctx.last_pts := AV_NOPTS_VALUE;
  ctx.frame_number := 1;

  // notify read header
  ctx.adapter.FFrameInfo := PInputFrameInfo(@ctx.pts);
  ctx.adapter.Fframe_input := ctx;
  ctx.adapter.ReadHeader;

  Result := 0;
end;

(* Read one packet and put it in 'pkt'. pts and flags are also
   set. 'av_new_stream' can be called only if the flag
   AVFMTCTX_NOHEADER is used. *)
function frameinput_read_packet(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;
var
  ctx: Pframe_input;
  ret: Integer;
  b, p: PByte;
  I: Integer;
{$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE)}
  BS: TBitmapData;
{$IFEND}
begin
  ctx := s.priv_data;

  // malloc packet
  if av_new_packet(pkt, ctx.size) < 0 then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;

  ctx.pkt := pkt;

  // calculate pts
  ctx.pts := Round(ctx.time_frame * av_q2d(ctx.time_base));
  pkt.pts := ctx.pts;
  pkt.dts := ctx.pts;

  // read frame
  case ctx.input_type of
{$IFDEF MSWINDOWS}
    itHDC: // Bitmap HDC
      begin
        ret := ctx.adapter.ReadFrameDC;
        if ret < 0 then
        begin
          av_log(s, AV_LOG_INFO, 'reading frame (DC) return %d'#10, ret);
          av_free_packet(pkt);
          Result := ret;
          Exit;
        end;
        // get bitmap bits
        if GetBitmapBits(ctx.hbmp, ctx.size, pkt.data) = 0 then
        begin
          av_log(s, AV_LOG_ERROR, 'GetBitmapBits failed error #%li'#10, GetLastError);
          av_free_packet(pkt);
          Result := -1;
          Exit;
        end;
        pkt.flags := AV_PKT_FLAG_KEY;
      end;
{$ENDIF}
    itBMP,    // Bitmap data
    itCanvas: // Bitmap canvas
      begin
        if ctx.input_type = itBMP then
        begin
          ret := ctx.adapter.ReadFrameBMP;
          if ret < 0 then
          begin
            av_log(s, AV_LOG_ERROR, 'reading frame (BMP) return %d'#10, ret);
            av_free_packet(pkt);
            Result := ret;
            Exit;
          end;
        end
        else // if ctx.input_type = itCanvas then
        begin
          ret := ctx.adapter.ReadFrameCanvas;
          if ret < 0 then
          begin
            av_log(s, AV_LOG_INFO, 'reading frame (Canvas) return %d'#10, ret);
            av_free_packet(pkt);
            Result := ret;
            Exit;
          end;
        end;
        //b := ctx.pBits;
        // bitmap for reading
{$IFDEF FPC}
        ctx.IntfImg.LoadFromBitmap(ctx.bmp.Handle, ctx.bmp.MaskHandle);
        b := ctx.IntfImg.PixelData;
{$ELSE}
  {$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE)}
        if ctx.bmp.Map(TMapAccess.maWrite, BS) then
        begin
          try
            b := PByte(BS.Data);
  {$ELSE}
        b := PByte(ctx.bmp.ScanLine[ctx.height - 1]);
        Inc(b, (ctx.height - 1) * ctx.bpl);
  {$IFEND}
{$ENDIF}
        p := pkt.data;
        for I := 0 to ctx.height - 1 do
        begin
          Move(b^, p^, ctx.bpl);
          Inc(p, ctx.bpl);
{$IF Defined(FPC) Or Defined(FFFMX)}
          Inc(b, ctx.bpl);
{$ELSE}
          Dec(b, ctx.bpl);
{$IFEND}
        end;
        pkt.flags := AV_PKT_FLAG_KEY;
{$IF Defined(FFFMX) And Defined(VCL_XE3_OR_ABOVE)}
          finally
            ctx.bmp.Unmap(BS);
          end;
        end
        else
        begin
          av_log(s, AV_LOG_ERROR, 'Could not map Bitmap.'#10);
          Result := -1;
          Exit;
        end;
{$IFEND}
      end;
    itYUV: // YUV data
      begin
        ret := ctx.adapter.ReadFrameYUV;
        if ret < 0 then
        begin
          av_log(s, AV_LOG_INFO, 'reading frame (YUV) return'#10, ret);
          av_free_packet(pkt);
          Result := ret;
          Exit;
        end;
      end;
  else
    // never occur
    av_free_packet(pkt);
    Result := -1;
    Exit;
  end;

  // update pts for variable frame rate
  if pkt.pts <> ctx.pts then
  begin
    if ctx.pts <= ctx.last_pts then
      av_log(s, AV_LOG_WARNING, 'invalid pts %I64d'#10, ctx.pts)
    else
    begin
      pkt.pts := ctx.pts;
      pkt.dts := ctx.pts;
      ctx.time_frame := Round(ctx.pts / av_q2d(ctx.time_base));
    end;
  end;

  // calculate the time of the next frame
  Inc(ctx.time_frame, Int64(1000000));

  // increase frame number
  Inc(ctx.frame_number);

  // save last pts
  ctx.last_pts := pkt.pts;

  Result := ctx.size;
end;

(* Close the stream. The AVFormatContext and AVStreams are not
   freed by this function *)
function frameinput_read_close(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pframe_input;
begin
  ctx := s.priv_data;

  // release resource
  release_resource(ctx);

  // notify read close
  ctx.adapter.ReadClose;

  Result := 0;
end;

var
  options: array[0..4] of TAVOption = (
    (name       : 'input_type';
     help       : 'one of {canvas, bmp, dc, yuv}, default yuv';
     offset     : -1;
     ttype      : AV_OPT_TYPE_STRING;
     default_val: (str: 'yuv');
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
    (name       : 'pixel_format';
     help       : 'pal8/rgb555le/bgr24/bgra for canvas/bmp/dc';
     offset     : -1;
     ttype      : AV_OPT_TYPE_STRING;
     default_val: (str: 'yuv420p');
     min        : 0;
     max        : 0;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : nil;)
  );

  frameinput_class: TAVClass = (
    class_name: 'FrameInputFormat';
    //item_name : av_default_item_name;
    option    : @options[0];
    version   : LIBAVUTIL_VERSION_INT;
  );

  frameinput_demuxer: TAVInputFormat = (
    name: 'frameinput';
    long_name: 'Frame input';
    flags: AVFMT_NOFILE;
    priv_class: @frameinput_class;
    priv_data_size: SizeOf(Tframe_input);
    read_header: frameinput_read_header;
    read_packet: frameinput_read_packet;
    read_close: frameinput_read_close;
  );

procedure register_frameinput;
var
  ctx: Tframe_input;
begin
  Assert(Assigned(av_default_item_name));
  frameinput_class.item_name := av_default_item_name;
  options[0].offset := Integer(@ctx.input_type_str) - Integer(@ctx);
  options[1].offset := Integer(@ctx.video_size) - Integer(@ctx);
  options[2].offset := Integer(@ctx.framerate) - Integer(@ctx);
  options[3].offset := Integer(@ctx.pixel_format) - Integer(@ctx);
  RegisterInputFormat(@frameinput_demuxer);
end;

end.
