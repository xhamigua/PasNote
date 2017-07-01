(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * packet input interface
 * Created by CodeCoolie@CNSW 2010/09/09 -> $Date:: 2013-11-18 #$
 *)

unit PacketInput;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.SysUtils,
  System.Classes,
{$ELSE}
  SysUtils,
  Classes,
{$ENDIF}

  FFBaseComponent,
  FFUtils,
  MyUtils;

type
  TReadPacketEvent = function(Sender: TObject; var Buffer; Count: Longint): Longint of object;

  TPacketInputAdapter = class(TFFBaseComponent)
  private
    FData: Pointer;
    FOnReadHeader: TNotifyEvent;
    FOnReadClose: TNotifyEvent;
    FOnReadPacket: TReadPacketEvent;
  protected
    procedure ReadHeader;
    procedure ReadClose;
    function ReadPacket(var Buffer; Count: Longint): Longint;
  public
    destructor Destroy; override;
    property UserData: Pointer read FData write FData;
  published
    property OnReadHeader: TNotifyEvent read FOnReadHeader write FOnReadHeader;
    property OnReadClose: TNotifyEvent read FOnReadClose write FOnReadClose;
    property OnReadPacket: TReadPacketEvent read FOnReadPacket write FOnReadPacket;
  end;

procedure register_packetinput;

implementation

uses
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
  AVUtilStubs;

type
  TInputType = (
    itH264,         // H.264 video
    itH263,         // H.263 video
    itMJPEG,        // MJPEG video
    itM4V,          // MPEG-4 video
    itMPEGVIDEO,    // MPEG video
    itVC1           // VC-1 video
  );

  Ppacket_input = ^Tpacket_input;
  Tpacket_input = record
    class_: PAVClass;
    width: Integer;         // width of the frame
    height: Integer;        // height of the frame
    time_base: TAVRational; // time base
    pix_fmt: TAVPixelFormat;

    input_type: TInputType;
    codec_id: TAVCodecID;

    buffer: PByte;
    size: Integer;
    pos: Int64;

    input_type_str: PAnsiChar;    // set by a private option
    pixel_format: PAnsiChar;      // set by a private option
    video_size: PAnsiChar;        (**< A string describing video size, set by a private option. *)
    framerate: PAnsiChar;         (**< Set by a private option. *)

    adapter: TPacketInputAdapter;  // packet input adapter
  end;

{ TPacketInputAdapter }

destructor TPacketInputAdapter.Destroy;
begin
  FOnReadHeader := nil;
  FOnReadClose := nil;
  FOnReadPacket := nil;
  inherited Destroy;
end;

procedure TPacketInputAdapter.ReadHeader;
begin
  if Assigned(FOnReadHeader) then
    FOnReadHeader(Self);
end;

procedure TPacketInputAdapter.ReadClose;
begin
  if Assigned(FOnReadClose) then
    FOnReadClose(Self);
end;

function TPacketInputAdapter.ReadPacket(var Buffer; Count: Longint): Longint;
begin
  if Assigned(FOnReadPacket) then
    Result := FOnReadPacket(Self, Buffer, Count)
  else
    Result := -1;
end;

// release resource
procedure release_resource(ctx: Ppacket_input);
begin
  av_freep(@ctx.buffer);
end;

function packetinput_read_header(s: PAVFormatContext): Integer; cdecl;
const
  CCodecIDs: array[TInputType] of TAVCodecID = (
              AV_CODEC_ID_H264, AV_CODEC_ID_H263,
              AV_CODEC_ID_MJPEG, AV_CODEC_ID_MPEG4,
              AV_CODEC_ID_MPEG1VIDEO, AV_CODEC_ID_VC1);
var
  ctx: Ppacket_input;
  ret: Integer;
  framerate_q: TAVRational;
  st: PAVStream;
begin
  ctx := s.priv_data;

  // PacketInputAdapter
  try
    ctx.adapter := TPacketInputAdapter(StrToInt(string(s.filename)));
  except on E: Exception do
    begin
      av_log(s, AV_LOG_ERROR, 'Could not parse PacketInputAdapter: "%s", ' +
        'it should be address of PacketInputAdapter'#10, s.filename);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end;
  if not Assigned(ctx.adapter) then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid PacketInputAdapter'#10);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  // packet input type, one of {h264, h263, mjpeg, m4v, mpegvideo, vc1}, default h264
  if Assigned(ctx.input_type_str) and (ctx.input_type_str <> '') then
  begin
    if ctx.input_type_str = 'h264' then
      ctx.input_type := itH264      // H.264 video
    else if ctx.input_type_str = 'h263' then
      ctx.input_type := itH263      // H.263 video
    else if ctx.input_type_str = 'mjpeg' then
      ctx.input_type := itMJPEG     // MJPEG video
    else if ctx.input_type_str = 'm4v' then
      ctx.input_type := itM4V       // MPEG-4 video
    else if ctx.input_type_str = 'mpegvideo' then
      ctx.input_type := itMPEGVIDEO // MPEG video
    else if ctx.input_type_str = 'vc1' then
      ctx.input_type := itVC1       // VC-1 video
    else
    begin
      av_log(s, AV_LOG_ERROR, 'Invalid packet input type: "%s", ' +
        'it should be one of h264, h263, mjpeg, m4v, mpegvideo, vc1'#10, ctx.input_type_str);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end
  else
    ctx.input_type := itH264;
  ctx.codec_id := CCodecIDs[ctx.input_type];

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

  // max packet size
  if ctx.size <= 0 then
    ctx.size := $10000;

  // malloc buffer
  ctx.buffer := av_malloc(ctx.size);
  if not Assigned(ctx.buffer) then
  begin
    av_log(s, AV_LOG_ERROR, 'Out of memory');
    Result := AVERROR_ENOMEM;
    Exit;
  end;

  // create stream
  st := avformat_new_stream(s, nil);
  if st = nil then
  begin
    release_resource(ctx);
    Result := AVERROR_ENOMEM;
    Exit;
  end;

  av_set_pts_info(st, 64, 1, 1000000);
  //av_set_pts_info(st, 64, 1, 1200000);

  with st.codec^ do
  begin
    codec_type := AVMEDIA_TYPE_VIDEO;
    codec_id   := ctx.codec_id;
    width      := ctx.width;
    height     := ctx.height;
    time_base  := ctx.time_base;
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

  // notify read header
  ctx.adapter.ReadHeader;

  Result := 0;
end;

function packetinput_read_partial_packet(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;
var
  ctx: Ppacket_input;
  ret: Integer;
begin
  ctx := s.priv_data;

  ret := ctx.adapter.ReadPacket(ctx.buffer^, ctx.size);

  if ret <= 0 then
  begin
    Result := ret;
    Exit;
  end;

  Assert(ret <= ctx.size);

  // malloc packet
  if av_new_packet(pkt, ret) < 0 then
  begin
    Result := AVERROR_ENOMEM;
    Exit;
  end;

  if ctx.input_type = itMJPEG then
    pkt.flags := pkt.flags or AV_PKT_FLAG_KEY;

  pkt.pos := ctx.pos;
  pkt.stream_index := 0;

  Move(ctx.buffer^, pkt.data^, ret);
  pkt.size := ret;

  Inc(ctx.pos, ret);

  Result := ret;
end;

function packetinput_read_close(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Ppacket_input;
begin
  ctx := s.priv_data;

  // release resource
  release_resource(ctx);

  // notify read close
  ctx.adapter.ReadClose;

  Result := 0;
end;

var
  options: array[0..5] of TAVOption = (
    (name       : 'input_type';
     help       : 'one of {h264, h263, mjpeg, m4v, mpegvideo, vc1}, default h264';
     offset     : -1;
     ttype      : AV_OPT_TYPE_STRING;
     default_val: (str: 'h264');
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
     help       : '';
     offset     : -1;
     ttype      : AV_OPT_TYPE_STRING;
     default_val: (str: 'yuv420p');
     min        : 0;
     max        : 0;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : 'max_packet_size';
     help       : 'default 65536(64KB)';
     offset     : -1;
     ttype      : AV_OPT_TYPE_INT;
     default_val: (i64: 65536);
     min        : 0;
     max        : MaxInt;
     flags      : AV_OPT_FLAG_DECODING_PARAM),
    (name       : nil;)
  );

  packetinput_class: TAVClass = (
    class_name: 'PacketInputFormat';
    //item_name : av_default_item_name;
    option    : @options[0];
    version   : LIBAVUTIL_VERSION_INT;
  );

  packetinput_demuxer: TAVInputFormat = (
    name: 'packetinput';
    long_name: 'Packet input';
    flags: AVFMT_NOFILE;
    priv_class: @packetinput_class;
    priv_data_size: SizeOf(Tpacket_input);
    read_header: packetinput_read_header;
    read_packet: packetinput_read_partial_packet;
    read_close: packetinput_read_close;
  );

procedure register_packetinput;
var
  ctx: Tpacket_input;
begin
  Assert(Assigned(av_default_item_name));
  packetinput_class.item_name := av_default_item_name;
  options[0].offset := Integer(@ctx.input_type_str) - Integer(@ctx);
  options[1].offset := Integer(@ctx.video_size) - Integer(@ctx);
  options[2].offset := Integer(@ctx.framerate) - Integer(@ctx);
  options[3].offset := Integer(@ctx.pixel_format) - Integer(@ctx);
  options[4].offset := Integer(@ctx.size) - Integer(@ctx);
  RegisterInputFormat(@packetinput_demuxer);
end;

end.
