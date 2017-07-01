(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of avformat library api stubs.
 * Created by CodeCoolie@CNSW 2008/03/20 -> $Date:: 2013-11-18 #$
 *)

unit AVFormatStubs;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.SysUtils,
{$ELSE}
  SysUtils,
{$ENDIF}
  MyUtils,
  AVUtilStubs,  // for av_reduce()
  libavcodec,
  libavformat,
  libavformat_avio,
  libavformat_url,
  libavutil_frame,
  libavutil_rational;

var
  av_codec_get_id             : Tav_codec_get_idProc            = nil;
  av_codec_get_tag2           : Tav_codec_get_tag2Proc          = nil;
  av_dump_format              : Tav_dump_formatProc             = nil;
  av_filename_number_test     : Tav_filename_number_testProc    = nil;
  av_find_best_stream         : Tav_find_best_streamProc        = nil;
  av_find_input_format        : Tav_find_input_formatProc       = nil;
  av_find_program_from_stream : Tav_find_program_from_streamProc= nil;
  av_format_set_audio_codec   : Tav_format_set_audio_codecProc  = nil;
  av_format_set_subtitle_codec: Tav_format_set_subtitle_codecProc= nil;
  av_format_set_video_codec   : Tav_format_set_video_codecProc  = nil;
  av_guess_codec              : Tav_guess_codecProc             = nil;
  av_guess_format             : Tav_guess_formatProc            = nil;
  av_iformat_next             : Tav_iformat_nextProc            = nil;
  av_interleaved_write_frame  : Tav_interleaved_write_frameProc = nil;
  av_oformat_next             : Tav_oformat_nextProc            = nil;
  av_pkt_dump_log2            : Tav_pkt_dump_log2Proc           = nil;
  av_read_frame               : Tav_read_frameProc              = nil;
  av_read_pause               : Tav_read_pauseProc              = nil;
  av_read_play                : Tav_read_playProc               = nil;
  av_register_all             : Tav_register_allProc            = nil;
  av_register_input_format    : Tav_register_input_formatProc   = nil;
  av_register_output_format   : Tav_register_output_formatProc  = nil;
  av_sdp_create               : Tav_sdp_createProc              = nil;
  av_seek_frame               : Tav_seek_frameProc              = nil;
  av_set_pts_info             : Tav_set_pts_infoProc            = nil;
  av_write_trailer            : Tav_write_trailerProc           = nil;
  avformat_alloc_context      : Tavformat_alloc_contextProc     = nil;
  avformat_alloc_output_context2: Tavformat_alloc_output_context2Proc = nil;
  avformat_close_input        : Tavformat_close_inputProc       = nil;
  avformat_find_stream_info   : Tavformat_find_stream_infoProc  = nil;
  avformat_free_context       : Tavformat_free_contextProc      = nil;
  avformat_get_class          : Tavformat_get_classProc         = nil;
  avformat_match_stream_specifier: Tavformat_match_stream_specifierProc = nil;
  avformat_network_deinit     : Tavformat_network_deinitProc    = nil;
  avformat_network_init       : Tavformat_network_initProc      = nil;
  avformat_new_stream         : Tavformat_new_streamProc        = nil;
  avformat_open_input         : Tavformat_open_inputProc        = nil;
  avformat_query_codec        : Tavformat_query_codecProc       = nil;
  avformat_seek_file          : Tavformat_seek_fileProc         = nil;
  avformat_write_header       : Tavformat_write_headerProc      = nil;
  avio_check                  : Tavio_checkProc                 = nil;
  avio_close                  : Tavio_closeProc                 = nil;
  avio_close_dyn_buf          : Tavio_close_dyn_bufProc         = nil;
  avio_closep                 : Tavio_closepProc                = nil;
  avio_flush                  : Tavio_flushProc                 = nil;
  avio_open                   : Tavio_openProc                  = nil;
  avio_open2                  : Tavio_open2Proc                 = nil;
  avio_open_dyn_buf           : Tavio_open_dyn_bufProc          = nil;
  avio_printf                 : Tavio_printfProc                = nil;
  avio_read                   : Tavio_readProc                  = nil;
  avio_seek                   : Tavio_seekProc                  = nil;
  avio_size                   : Tavio_sizeProc                  = nil;
  avio_w8                     : Tavio_w8Proc                    = nil;
  avio_write                  : Tavio_writeProc                 = nil;
  url_feof                    : Turl_feofProc                   = nil;
  // private api of ffmpeg libraries
  ff_guess_image2_codec       : Tff_guess_image2_codecProc      = nil;
  ffurl_protocol_next         : Tffurl_protocol_nextProc        = nil;
  ffurl_register_protocol     : Tffurl_register_protocolProc    = nil;

(****** TODO: check from libavformat/avformat.h **************)
(**
 * Guess the sample aspect ratio of a frame, based on both the stream and the
 * frame aspect ratio.
 *
 * Since the frame aspect ratio is set by the codec but the stream aspect ratio
 * is set by the demuxer, these two may not be equal. This function tries to
 * return the value that you should use if you would like to display the frame.
 *
 * Basic logic is to use the stream aspect ratio if it is set to something sane
 * otherwise use the frame aspect ratio. This way a container setting, which is
 * usually easy to modify can override the coded value in the frames.
 *
 * @param format the format context which the stream is part of
 * @param stream the stream which the frame is part of
 * @param frame the frame with the aspect ratio to be determined
 * @return the guessed (valid) sample_aspect_ratio, 0/1 if no idea
 *)
function av_guess_sample_aspect_ratio(format: PAVFormatContext; stream: PAVStream; frame: PAVFrame): TAVRational;

(****** TODO: check from libavformat/avformat.h **************)
(**
 * Guess the frame rate, based on both the container and codec information.
 *
 * @param ctx the format context which the stream is part of
 * @param stream the stream which the frame is part of
 * @param frame the frame for which the frame rate should be determined, may be NULL
 * @return the guessed (valid) frame rate, 0/1 if no idea
 *)
function av_guess_frame_rate(format: PAVFormatContext; st: PAVStream; frame: PAVFrame): TAVRational;

(****** TODO: check from libavformat/avio.h **************)
(**
 * ftell() equivalent for AVIOContext.
 * @return position or AVERROR.
 *)
function avio_tell(s: PAVIOContext): Int64;

procedure AVFormatFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
procedure AVFormatUnfixStubs;

implementation

(****** TODO: check from libavformat/utils.c **************)
function av_guess_sample_aspect_ratio(format: PAVFormatContext; stream: PAVStream; frame: PAVFrame): TAVRational;
var
  undef: TAVRational;
  stream_sample_aspect_ratio: TAVRational;
  codec_sample_aspect_ratio: TAVRational;
  frame_sample_aspect_ratio: TAVRational;
begin
  undef.num := 0;
  undef.den := 1;
  if Assigned(stream) then
  begin
    stream_sample_aspect_ratio := stream.sample_aspect_ratio;
    if Assigned(stream.codec) then
      codec_sample_aspect_ratio := stream.codec.sample_aspect_ratio
    else
      codec_sample_aspect_ratio := undef;
  end
  else
  begin
    stream_sample_aspect_ratio := undef;
    codec_sample_aspect_ratio := undef;
  end;
  if Assigned(frame) then
    frame_sample_aspect_ratio := frame.sample_aspect_ratio
  else
    frame_sample_aspect_ratio := codec_sample_aspect_ratio;

  av_reduce(@stream_sample_aspect_ratio.num, @stream_sample_aspect_ratio.den,
             stream_sample_aspect_ratio.num,  stream_sample_aspect_ratio.den, MaxInt);
  if (stream_sample_aspect_ratio.num <= 0) or (stream_sample_aspect_ratio.den <= 0) then
    stream_sample_aspect_ratio := undef;

  av_reduce(@frame_sample_aspect_ratio.num, @frame_sample_aspect_ratio.den,
             frame_sample_aspect_ratio.num,  frame_sample_aspect_ratio.den, MaxInt);
  if (frame_sample_aspect_ratio.num <= 0) or (frame_sample_aspect_ratio.den <= 0) then
    frame_sample_aspect_ratio := undef;

  if stream_sample_aspect_ratio.num <> 0 then
    Result := stream_sample_aspect_ratio
  else
    Result := frame_sample_aspect_ratio;
end;

(****** TODO: check from libavformat/utils.c **************)
function av_guess_frame_rate(format: PAVFormatContext; st: PAVStream; frame: PAVFrame): TAVRational;
var
  fr: TAVRational;
  codec_fr: TAVRational;
  avg_fr: TAVRational;
begin
  fr := st.r_frame_rate;

  if st.codec.ticks_per_frame > 1 then
  begin
    codec_fr := av_inv_q(st.codec.time_base);
    avg_fr := st.avg_frame_rate;
    codec_fr.den := codec_fr.den * st.codec.ticks_per_frame;
    if (codec_fr.num > 0) and (codec_fr.den > 0) and (av_q2d(codec_fr) < av_q2d(fr) * 0.7) and
       (Abs(1.0 - av_q2d(av_div_q(avg_fr, fr))) > 0.1) then
      fr := codec_fr;
  end;

  Result := fr;
end;

(****** TODO: check from libavformat/avio.h **************)
function avio_tell(s: PAVIOContext): Int64;
begin
  Result := avio_seek(s, 0, {SEEK_CUR}1);
end;

procedure AVFormatFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
begin
  FixupStub(ALibFile, AHandle, 'av_codec_get_id',             @av_codec_get_id);
  FixupStub(ALibFile, AHandle, 'av_codec_get_tag2',           @av_codec_get_tag2);
  FixupStub(ALibFile, AHandle, 'av_dump_format',              @av_dump_format);
  FixupStub(ALibFile, AHandle, 'av_filename_number_test',     @av_filename_number_test);
  FixupStub(ALibFile, AHandle, 'av_find_best_stream',         @av_find_best_stream);
  FixupStub(ALibFile, AHandle, 'av_find_input_format',        @av_find_input_format);
  FixupStub(ALibFile, AHandle, 'av_find_program_from_stream', @av_find_program_from_stream);
  FixupStub(ALibFile, AHandle, 'av_format_set_audio_codec',   @av_format_set_audio_codec);
  FixupStub(ALibFile, AHandle, 'av_format_set_subtitle_codec',@av_format_set_subtitle_codec);
  FixupStub(ALibFile, AHandle, 'av_format_set_video_codec',   @av_format_set_video_codec);
  FixupStub(ALibFile, AHandle, 'av_guess_codec',              @av_guess_codec);
  FixupStub(ALibFile, AHandle, 'av_guess_format',             @av_guess_format);
  FixupStub(ALibFile, AHandle, 'av_iformat_next',             @av_iformat_next);
  FixupStub(ALibFile, AHandle, 'av_interleaved_write_frame',  @av_interleaved_write_frame);
  FixupStub(ALibFile, AHandle, 'av_oformat_next',             @av_oformat_next);
  FixupStub(ALibFile, AHandle, 'av_pkt_dump_log2',            @av_pkt_dump_log2);
  FixupStub(ALibFile, AHandle, 'av_read_frame',               @av_read_frame);
  FixupStub(ALibFile, AHandle, 'av_read_pause',               @av_read_pause);
  FixupStub(ALibFile, AHandle, 'av_read_play',                @av_read_play);
  FixupStub(ALibFile, AHandle, 'av_register_all',             @av_register_all);
  FixupStub(ALibFile, AHandle, 'av_register_input_format',    @av_register_input_format);
  FixupStub(ALibFile, AHandle, 'av_register_output_format',   @av_register_output_format);
  FixupStub(ALibFile, AHandle, 'av_sdp_create',               @av_sdp_create);
  FixupStub(ALibFile, AHandle, 'av_seek_frame',               @av_seek_frame);
  FixupStub(ALibFile, AHandle, 'av_set_pts_info',             @av_set_pts_info);
  FixupStub(ALibFile, AHandle, 'av_write_trailer',            @av_write_trailer);
  FixupStub(ALibFile, AHandle, 'avformat_alloc_context',      @avformat_alloc_context);
  FixupStub(ALibFile, AHandle, 'avformat_alloc_output_context2', @avformat_alloc_output_context2);
  FixupStub(ALibFile, AHandle, 'avformat_close_input',        @avformat_close_input);
  FixupStub(ALibFile, AHandle, 'avformat_find_stream_info',   @avformat_find_stream_info);
  FixupStub(ALibFile, AHandle, 'avformat_free_context',       @avformat_free_context);
  FixupStub(ALibFile, AHandle, 'avformat_get_class',          @avformat_get_class);
  FixupStub(ALibFile, AHandle, 'avformat_match_stream_specifier', @avformat_match_stream_specifier);
  FixupStub(ALibFile, AHandle, 'avformat_network_deinit',     @avformat_network_deinit);
  FixupStub(ALibFile, AHandle, 'avformat_network_init',       @avformat_network_init);
  FixupStub(ALibFile, AHandle, 'avformat_new_stream',         @avformat_new_stream);
  FixupStub(ALibFile, AHandle, 'avformat_open_input',         @avformat_open_input);
  FixupStub(ALibFile, AHandle, 'avformat_query_codec',        @avformat_query_codec);
  FixupStub(ALibFile, AHandle, 'avformat_seek_file',          @avformat_seek_file);
  FixupStub(ALibFile, AHandle, 'avformat_write_header',       @avformat_write_header);
  FixupStub(ALibFile, AHandle, 'avio_check',                  @avio_check);
  FixupStub(ALibFile, AHandle, 'avio_close',                  @avio_close);
  FixupStub(ALibFile, AHandle, 'avio_close_dyn_buf',          @avio_close_dyn_buf);
  FixupStub(ALibFile, AHandle, 'avio_closep',                 @avio_closep);
  FixupStub(ALibFile, AHandle, 'avio_flush',                  @avio_flush);
  FixupStub(ALibFile, AHandle, 'avio_open',                   @avio_open);
  FixupStub(ALibFile, AHandle, 'avio_open2',                  @avio_open2);
  FixupStub(ALibFile, AHandle, 'avio_open_dyn_buf',           @avio_open_dyn_buf);
  FixupStub(ALibFile, AHandle, 'avio_printf',                 @avio_printf);
  FixupStub(ALibFile, AHandle, 'avio_read',                   @avio_read);
  FixupStub(ALibFile, AHandle, 'avio_seek',                   @avio_seek);
  FixupStub(ALibFile, AHandle, 'avio_size',                   @avio_size);
  FixupStub(ALibFile, AHandle, 'avio_w8',                     @avio_w8);
  FixupStub(ALibFile, AHandle, 'avio_write',                  @avio_write);
  FixupStub(ALibFile, AHandle, 'url_feof',                    @url_feof);
  // private api of ffmpeg libraries
  FixupStub(ALibFile, AHandle, 'ff_guess_image2_codec',       @ff_guess_image2_codec,   True);
  FixupStub(ALibFile, AHandle, 'ffurl_protocol_next',         @ffurl_protocol_next,     True);
  FixupStub(ALibFile, AHandle, 'ffurl_register_protocol',     @ffurl_register_protocol, True);

  av_register_all;
  avformat_network_init;
end;

procedure AVFormatUnfixStubs;
begin
  if Assigned(avformat_network_deinit) then
    avformat_network_deinit;
  @av_codec_get_id              := nil;
  @av_codec_get_tag2            := nil;
  @av_dump_format               := nil;
  @av_filename_number_test      := nil;
  @av_find_best_stream          := nil;
  @av_find_input_format         := nil;
  @av_find_program_from_stream  := nil;
  @av_format_set_audio_codec    := nil;
  @av_format_set_subtitle_codec := nil;
  @av_format_set_video_codec    := nil;
  @av_guess_codec               := nil;
  @av_guess_format              := nil;
  @av_iformat_next              := nil;
  @av_interleaved_write_frame   := nil;
  @av_oformat_next              := nil;
  @av_pkt_dump_log2             := nil;
  @av_read_frame                := nil;
  @av_read_pause                := nil;
  @av_read_play                 := nil;
  @av_register_all              := nil;
  @av_register_input_format     := nil;
  @av_register_output_format    := nil;
  @av_sdp_create                := nil;
  @av_seek_frame                := nil;
  @av_set_pts_info              := nil;
  @av_write_trailer             := nil;
  @avformat_alloc_context       := nil;
  @avformat_alloc_output_context2 := nil;
  @avformat_close_input         := nil;
  @avformat_find_stream_info    := nil;
  @avformat_free_context        := nil;
  @avformat_get_class           := nil;
  @avformat_match_stream_specifier := nil;
  @avformat_network_deinit      := nil;
  @avformat_network_init        := nil;
  @avformat_new_stream          := nil;
  @avformat_open_input          := nil;
  @avformat_query_codec         := nil;
  @avformat_seek_file           := nil;
  @avformat_write_header        := nil;
  @avio_check                   := nil;
  @avio_close                   := nil;
  @avio_close_dyn_buf           := nil;
  @avio_closep                  := nil;
  @avio_flush                   := nil;
  @avio_open                    := nil;
  @avio_open2                   := nil;
  @avio_open_dyn_buf            := nil;
  @avio_printf                  := nil;
  @avio_read                    := nil;
  @avio_seek                    := nil;
  @avio_size                    := nil;
  @avio_w8                      := nil;
  @avio_write                   := nil;
  @ff_guess_image2_codec        := nil;
  @ffurl_protocol_next          := nil;
  @ffurl_register_protocol      := nil;
  @url_feof                     := nil;
end;

end.
