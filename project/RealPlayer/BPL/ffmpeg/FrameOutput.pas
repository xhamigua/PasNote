(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * frame output interface
 * Created by CodeCoolie@CNSW 2009/09/07 -> $Date:: 2012-12-01 #$
 *)

unit FrameOutput;

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

  libavcodec,
  libavformat,
  libavutil_error,
  libavutil_log,
  libavutil_pixfmt,
  AVUtilStubs,

  FFBaseComponent,
  FFUtils,
  MyUtils;

type
  POutputFrameInfo = ^TOutputFrameInfo;
  TOutputFrameInfo = record
    FormatContext: PAVFormatContext;
    PixelFormat: TAVPixelFormat;
    Width: Integer;
    Height: Integer;
    FrameNumber: Integer;
    Packet: PAVPacket;
  end;

  TWriteFrameEvent = procedure(Sender: TObject; AFrameInfo: POutputFrameInfo) of object;

  TFrameOutputAdapter = class(TFFBaseComponent)
  private
    FData: Pointer;
    FFrameInfo: POutputFrameInfo;
    FOnWriteHeader: TNotifyEvent;
    FOnWriteFrame: TWriteFrameEvent;
    FOnWriteClose: TNotifyEvent;
  protected
    procedure WriteHeader;
    procedure WriteFrame(AFrameInfo: POutputFrameInfo);
    procedure WriteClose;
  public
    destructor Destroy; override;
    property FrameInfo: POutputFrameInfo read FFrameInfo;
    property UserData: Pointer read FData write FData;
  published
    property OnWriteHeader: TNotifyEvent read FOnWriteHeader write FOnWriteHeader;
    property OnWriteFrame: TWriteFrameEvent read FOnWriteFrame write FOnWriteFrame;
    property OnWriteClose: TNotifyEvent read FOnWriteClose write FOnWriteClose;
  end;

procedure register_frameoutput;

implementation

{ TFrameOutputAdapter }

destructor TFrameOutputAdapter.Destroy;
begin
  FOnWriteHeader := nil;
  FOnWriteFrame := nil;
  FOnWriteClose := nil;
  inherited Destroy;
end;

procedure TFrameOutputAdapter.WriteHeader;
begin
  if Assigned(FOnWriteHeader) then
    FOnWriteHeader(Self);
end;

procedure TFrameOutputAdapter.WriteFrame(AFrameInfo: POutputFrameInfo);
begin
  if Assigned(FOnWriteFrame) then
    FOnWriteFrame(Self, AFrameInfo);
end;

procedure TFrameOutputAdapter.WriteClose;
begin
  if Assigned(FOnWriteClose) then
    FOnWriteClose(Self);
end;

type
  Pframe_output = ^Tframe_output;
  Tframe_output = record
    s: PAVFormatContext;
    pix_fmt: TAVPixelFormat;
    width: Integer;
    height: Integer;
    frame_number: Integer;
    pkt: PAVPacket;

    adapter: TFrameOutputAdapter;  // frame output adapter
  end;

function raw_write_header(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pframe_output;
begin
  ctx := s.priv_data;

  // FrameOutputAdapter
  try
    ctx.adapter := TFrameOutputAdapter(StrToInt(string(s.filename)));
  except on E: Exception do
    begin
      av_log(s, AV_LOG_ERROR, 'Could not parse FrameOutputAdapter: "%s", ' +
        'it should be address of FrameOutputAdapter'#10, s.filename);
      Result := AVERROR_EINVAL;
      Exit;
    end;
  end;
  if not Assigned(ctx.adapter) then
  begin
    av_log(s, AV_LOG_ERROR, 'Invalid FrameOutputAdapter'#10);
    Result := AVERROR_EINVAL;
    Exit;
  end;

  ctx.s := s;
  ctx.pix_fmt := PPtrIdx(s.streams, 0)^.codec.pix_fmt;
  ctx.width := PPtrIdx(s.streams, 0)^.codec.width;
  ctx.height := PPtrIdx(s.streams, 0)^.codec.height;

  // notify write header
  ctx.adapter.FFrameInfo := POutputFrameInfo(ctx);
  ctx.adapter.WriteHeader;

  Result := 0;
end;

function raw_write_packet(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;
var
  ctx: Pframe_output;
begin
  ctx := s.priv_data;
  Inc(ctx.frame_number);
  ctx.pkt := pkt;
  ctx.adapter.WriteFrame(POutputFrameInfo(ctx));
  // here we get the packet! in raw format case, one packet contains one frame
{
  if pkt.flags and AV_PKT_FLAG_KEY <> 0 then
  begin
    // this is a packet of key-frame
  end;
  put_buffer(s.pb, PAnsiChar(pkt.data), pkt.size);
  put_flush_packet(s.pb);
}
  Result := 0;
end;

function raw_write_trailer(s: PAVFormatContext): Integer; cdecl;
var
  ctx: Pframe_output;
begin
  ctx := s.priv_data;
  ctx.adapter.WriteClose;
  Result := 0;
end;

var
  raw_h263_muxer: TAVOutputFormat = (
    name: 'rawh263';
    long_name: 'raw H.263 video format';
    mime_type: nil;
    extensions: 'h263';
    audio_codec: AV_CODEC_ID_NONE;
    video_codec: AV_CODEC_ID_H263;
    flags: AVFMT_NOFILE or AVFMT_NOTIMESTAMPS;
    priv_data_size: SizeOf(Tframe_output);
    write_header: raw_write_header;
    write_packet: raw_write_packet;
    write_trailer: raw_write_trailer;
  );

procedure register_raw_h263;
begin
  RegisterOutputFormat(@raw_h263_muxer);
end;

var
  raw_h264_muxer: TAVOutputFormat = (
    name: 'rawh264';
    long_name: 'raw H.264 video format';
    mime_type: nil;
    extensions: 'h264';
    audio_codec: AV_CODEC_ID_NONE;
    video_codec: AV_CODEC_ID_H264;
    flags: AVFMT_NOFILE or AVFMT_NOTIMESTAMPS;
    priv_data_size: SizeOf(Tframe_output);
    write_header: raw_write_header;
    write_packet: raw_write_packet;
    write_trailer: raw_write_trailer;
  );

procedure register_raw_h264;
begin
  RegisterOutputFormat(@raw_h264_muxer);
end;

var
  raw_mjpeg_muxer: TAVOutputFormat = (
    name: 'rawmjpeg';
    long_name: 'raw MJPEG video';
    mime_type: 'video/x-mjpeg';
    extensions: 'mjpg,mjpeg';
    audio_codec: AV_CODEC_ID_NONE;
    video_codec: AV_CODEC_ID_MJPEG;
    flags: AVFMT_NOFILE or AVFMT_NOTIMESTAMPS;
    priv_data_size: SizeOf(Tframe_output);
    write_header: raw_write_header;
    write_packet: raw_write_packet;
    write_trailer: raw_write_trailer;
  );

procedure register_raw_mjpeg;
begin
  RegisterOutputFormat(@raw_mjpeg_muxer);
end;

var
  raw_yuv_muxer: TAVOutputFormat = (
    name: 'rawyuv';
    long_name: 'raw YUV video format';
    mime_type: nil;
    extensions: 'yuv';
    audio_codec: AV_CODEC_ID_NONE;
    video_codec: AV_CODEC_ID_RAWVIDEO;
    flags: AVFMT_NOFILE or AVFMT_NOTIMESTAMPS;
    priv_data_size: SizeOf(Tframe_output);
    write_header: raw_write_header;
    write_packet: raw_write_packet;
    write_trailer: raw_write_trailer;
  );

procedure register_raw_yuv;
begin
  RegisterOutputFormat(@raw_yuv_muxer);
end;

var
  raw_rgb_muxer: TAVOutputFormat = (
    name: 'rawrgb';
    long_name: 'raw RGB video format';
    mime_type: nil;
    extensions: 'rgb';
    audio_codec: AV_CODEC_ID_NONE;
    video_codec: AV_CODEC_ID_RAWVIDEO;
    flags: AVFMT_NOFILE or AVFMT_NOTIMESTAMPS;
    priv_data_size: SizeOf(Tframe_output);
    write_header: raw_write_header;
    write_packet: raw_write_packet;
    write_trailer: raw_write_trailer;
  );

procedure register_raw_rgb;
begin
  RegisterOutputFormat(@raw_rgb_muxer);
end;

procedure register_frameoutput;
begin
  register_raw_h263;
  register_raw_h264;
  register_raw_mjpeg;
  register_raw_yuv;
  register_raw_rgb;
end;

end.
