(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of avcodec library api stubs.
 * Created by CodeCoolie@CNSW 2008/03/19 -> $Date:: 2013-11-18 #$
 *)

unit AVCodecStubs;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.SysUtils,
{$ELSE}
  SysUtils,
{$ENDIF}
  MyUtils,
  libavcodec,
  libavcodec_avfft;

var
  av_bitstream_filter_close     : Tav_bitstream_filter_closeProc      = nil;
  av_bitstream_filter_filter    : Tav_bitstream_filter_filterProc     = nil;
  av_bitstream_filter_init      : Tav_bitstream_filter_initProc       = nil;
  av_codec_get_lowres           : Tav_codec_get_lowresProc            = nil;
  av_codec_get_max_lowres       : Tav_codec_get_max_lowresProc        = nil;
  av_codec_next                 : Tav_codec_nextProc                  = nil;
  av_codec_set_lowres           : Tav_codec_set_lowresProc            = nil;
  av_copy_packet                : Tav_copy_packetProc                 = nil;
  av_fast_malloc                : Tav_fast_mallocProc                 = nil;
  av_get_audio_frame_duration   : Tav_get_audio_frame_durationProc    = nil;
  av_get_bits_per_sample        : Tav_get_bits_per_sampleProc         = nil;
  av_get_exact_bits_per_sample  : Tav_get_exact_bits_per_sampleProc   = nil;
  av_lockmgr_register           : Tav_lockmgr_registerProc            = nil;
  av_parser_change              : Tav_parser_changeProc               = nil;
  av_picture_copy               : Tav_picture_copyProc                = nil;
  avcodec_alloc_frame           : Tavcodec_alloc_frameProc            = nil;
  avcodec_close                 : Tavcodec_closeProc                  = nil;
  avcodec_copy_context          : Tavcodec_copy_contextProc           = nil;
  avcodec_decode_audio4         : Tavcodec_decode_audio4Proc          = nil;
  avcodec_decode_subtitle2      : Tavcodec_decode_subtitle2Proc       = nil;
  avcodec_decode_video2         : Tavcodec_decode_video2Proc          = nil;
  avcodec_descriptor_get_by_name: Tavcodec_descriptor_get_by_nameProc = nil;
  avcodec_encode_audio2         : Tavcodec_encode_audio2Proc          = nil;
  avcodec_encode_subtitle       : Tavcodec_encode_subtitleProc        = nil;
  avcodec_encode_video2         : Tavcodec_encode_video2Proc          = nil;
  avcodec_find_best_pix_fmt_of_2: Tavcodec_find_best_pix_fmt_of_2Proc = nil;
  avcodec_find_decoder          : Tavcodec_find_decoderProc           = nil;
  avcodec_find_decoder_by_name  : Tavcodec_find_decoder_by_nameProc   = nil;
  avcodec_find_encoder          : Tavcodec_find_encoderProc           = nil;
  avcodec_find_encoder_by_name  : Tavcodec_find_encoder_by_nameProc   = nil;
  avcodec_flush_buffers         : Tavcodec_flush_buffersProc          = nil;
  avcodec_free_frame            : Tavcodec_free_frameProc             = nil;
  avcodec_get_chroma_sub_sample : Tavcodec_get_chroma_sub_sampleProc  = nil;
  avcodec_get_class             : Tavcodec_get_classProc              = nil;
  avcodec_get_context_defaults3 : Tavcodec_get_context_defaults3Proc  = nil;
  avcodec_get_frame_class       : Tavcodec_get_frame_classProc        = nil;
  avcodec_get_frame_defaults    : Tavcodec_get_frame_defaultsProc     = nil;
  avcodec_get_name              : Tavcodec_get_nameProc               = nil;
  avcodec_open2                 : Tavcodec_open2Proc                  = nil;
  avcodec_register_all          : Tavcodec_register_allProc           = nil;
  avcodec_string                : Tavcodec_stringProc                 = nil;
  avpicture_deinterlace         : Tavpicture_deinterlaceProc          = nil;
  avpicture_fill                : Tavpicture_fillProc                 = nil;
  avpicture_get_size            : Tavpicture_get_sizeProc             = nil;
  avsubtitle_free               : Tavsubtitle_freeProc                = nil;

  av_destruct_packet            : Tav_destruct_packetProc             = nil;
  av_dup_packet                 : Tav_dup_packetProc                  = nil;
  av_init_packet                : Tav_init_packetProc                 = nil;
  av_new_packet                 : Tav_new_packetProc                  = nil;
  av_free_packet                : Tav_free_packetProc                 = nil;

  av_rdft_init                  : Tav_rdft_initProc                   = nil;
  av_rdft_calc                  : Tav_rdft_calcProc                   = nil;
  av_rdft_end                   : Tav_rdft_endProc                    = nil;

procedure AVCodecFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
procedure AVCodecUnfixStubs;

implementation

procedure AVCodecFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
begin
  FixupStub(ALibFile, AHandle, 'av_bitstream_filter_close',     @av_bitstream_filter_close);
  FixupStub(ALibFile, AHandle, 'av_bitstream_filter_filter',    @av_bitstream_filter_filter);
  FixupStub(ALibFile, AHandle, 'av_bitstream_filter_init',      @av_bitstream_filter_init);
  FixupStub(ALibFile, AHandle, 'av_codec_get_lowres',           @av_codec_get_lowres);
  FixupStub(ALibFile, AHandle, 'av_codec_get_max_lowres',       @av_codec_get_max_lowres);
  FixupStub(ALibFile, AHandle, 'av_codec_next',                 @av_codec_next);
  FixupStub(ALibFile, AHandle, 'av_codec_set_lowres',           @av_codec_set_lowres);
  FixupStub(ALibFile, AHandle, 'av_copy_packet',                @av_copy_packet);
  FixupStub(ALibFile, AHandle, 'av_fast_malloc',                @av_fast_malloc);
  FixupStub(ALibFile, AHandle, 'av_get_audio_frame_duration',   @av_get_audio_frame_duration);
  FixupStub(ALibFile, AHandle, 'av_get_bits_per_sample',        @av_get_bits_per_sample);
  FixupStub(ALibFile, AHandle, 'av_get_exact_bits_per_sample',  @av_get_exact_bits_per_sample);
  FixupStub(ALibFile, AHandle, 'av_lockmgr_register',           @av_lockmgr_register);
  FixupStub(ALibFile, AHandle, 'av_parser_change',              @av_parser_change);
  FixupStub(ALibFile, AHandle, 'av_picture_copy',               @av_picture_copy);
  FixupStub(ALibFile, AHandle, 'avcodec_alloc_frame',           @avcodec_alloc_frame);
  FixupStub(ALibFile, AHandle, 'avcodec_close',                 @avcodec_close);
  FixupStub(ALibFile, AHandle, 'avcodec_copy_context',          @avcodec_copy_context);
  FixupStub(ALibFile, AHandle, 'avcodec_decode_audio4',         @avcodec_decode_audio4);
  FixupStub(ALibFile, AHandle, 'avcodec_decode_subtitle2',      @avcodec_decode_subtitle2);
  FixupStub(ALibFile, AHandle, 'avcodec_decode_video2',         @avcodec_decode_video2);
  FixupStub(ALibFile, AHandle, 'avcodec_descriptor_get_by_name',@avcodec_descriptor_get_by_name);
  FixupStub(ALibFile, AHandle, 'avcodec_encode_audio2',         @avcodec_encode_audio2);
  FixupStub(ALibFile, AHandle, 'avcodec_encode_subtitle',       @avcodec_encode_subtitle);
  FixupStub(ALibFile, AHandle, 'avcodec_encode_video2',         @avcodec_encode_video2);
  FixupStub(ALibFile, AHandle, 'avcodec_find_best_pix_fmt_of_2',@avcodec_find_best_pix_fmt_of_2);
  FixupStub(ALibFile, AHandle, 'avcodec_find_decoder',          @avcodec_find_decoder);
  FixupStub(ALibFile, AHandle, 'avcodec_find_decoder_by_name',  @avcodec_find_decoder_by_name);
  FixupStub(ALibFile, AHandle, 'avcodec_find_encoder',          @avcodec_find_encoder);
  FixupStub(ALibFile, AHandle, 'avcodec_find_encoder_by_name',  @avcodec_find_encoder_by_name);
  FixupStub(ALibFile, AHandle, 'avcodec_flush_buffers',         @avcodec_flush_buffers);
  FixupStub(ALibFile, AHandle, 'avcodec_free_frame',            @avcodec_free_frame);
  FixupStub(ALibFile, AHandle, 'avcodec_get_chroma_sub_sample', @avcodec_get_chroma_sub_sample);
  FixupStub(ALibFile, AHandle, 'avcodec_get_class',             @avcodec_get_class);
  FixupStub(ALibFile, AHandle, 'avcodec_get_context_defaults3', @avcodec_get_context_defaults3);
  FixupStub(ALibFile, AHandle, 'avcodec_get_frame_class',       @avcodec_get_frame_class);
  FixupStub(ALibFile, AHandle, 'avcodec_get_frame_defaults',    @avcodec_get_frame_defaults);
  FixupStub(ALibFile, AHandle, 'avcodec_get_name',              @avcodec_get_name);
  FixupStub(ALibFile, AHandle, 'avcodec_open2',                 @avcodec_open2);
  FixupStub(ALibFile, AHandle, 'avcodec_register_all',          @avcodec_register_all);
  FixupStub(ALibFile, AHandle, 'avcodec_string',                @avcodec_string);
  FixupStub(ALibFile, AHandle, 'avpicture_deinterlace',         @avpicture_deinterlace);
  FixupStub(ALibFile, AHandle, 'avpicture_fill',                @avpicture_fill);
  FixupStub(ALibFile, AHandle, 'avpicture_get_size',            @avpicture_get_size);
  FixupStub(ALibFile, AHandle, 'avsubtitle_free',               @avsubtitle_free);

  FixupStub(ALibFile, AHandle, 'av_destruct_packet',            @av_destruct_packet);
  FixupStub(ALibFile, AHandle, 'av_dup_packet',                 @av_dup_packet);
  FixupStub(ALibFile, AHandle, 'av_init_packet',                @av_init_packet);
  FixupStub(ALibFile, AHandle, 'av_new_packet',                 @av_new_packet);
  FixupStub(ALibFile, AHandle, 'av_free_packet',                @av_free_packet);

  FixupStub(ALibFile, AHandle, 'av_rdft_init',                  @av_rdft_init);
  FixupStub(ALibFile, AHandle, 'av_rdft_calc',                  @av_rdft_calc);
  FixupStub(ALibFile, AHandle, 'av_rdft_end',                   @av_rdft_end);

  avcodec_register_all;
end;

procedure AVCodecUnfixStubs;
begin
  @av_bitstream_filter_close      := nil;
  @av_bitstream_filter_filter     := nil;
  @av_bitstream_filter_init       := nil;
  @av_codec_get_lowres            := nil;
  @av_codec_get_max_lowres        := nil;
  @av_codec_next                  := nil;
  @av_codec_set_lowres            := nil;
  @av_copy_packet                 := nil;
  @av_fast_malloc                 := nil;
  @av_get_audio_frame_duration    := nil;
  @av_get_bits_per_sample         := nil;
  @av_get_exact_bits_per_sample   := nil;
  @av_lockmgr_register            := nil;
  @av_parser_change               := nil;
  @av_picture_copy                := nil;
  @avcodec_alloc_frame            := nil;
  @avcodec_close                  := nil;
  @avcodec_copy_context           := nil;
  @avcodec_decode_audio4          := nil;
  @avcodec_decode_subtitle2       := nil;
  @avcodec_decode_video2          := nil;
  @avcodec_descriptor_get_by_name := nil;
  @avcodec_encode_audio2          := nil;
  @avcodec_encode_subtitle        := nil;
  @avcodec_encode_video2          := nil;
  @avcodec_find_best_pix_fmt_of_2 := nil;
  @avcodec_find_decoder           := nil;
  @avcodec_find_decoder_by_name   := nil;
  @avcodec_find_encoder           := nil;
  @avcodec_find_encoder_by_name   := nil;
  @avcodec_flush_buffers          := nil;
  @avcodec_free_frame             := nil;
  @avcodec_get_chroma_sub_sample  := nil;
  @avcodec_get_class              := nil;
  @avcodec_get_context_defaults3  := nil;
  @avcodec_get_frame_class        := nil;
  @avcodec_get_frame_defaults     := nil;
  @avcodec_get_name               := nil;
  @avcodec_open2                  := nil;
  @avcodec_register_all           := nil;
  @avcodec_string                 := nil;
  @avpicture_deinterlace          := nil;
  @avpicture_fill                 := nil;
  @avpicture_get_size             := nil;
  @avsubtitle_free                := nil;

  @av_destruct_packet             := nil;
  @av_dup_packet                  := nil;
  @av_init_packet                 := nil;
  @av_new_packet                  := nil;
  @av_free_packet                 := nil;

  @av_rdft_init                   := nil;
  @av_rdft_calc                   := nil;
  @av_rdft_end                    := nil;
end;

end.
