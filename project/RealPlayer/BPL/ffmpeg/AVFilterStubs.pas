(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of avfilter library api stubs.
 * Created by CodeCoolie@CNSW 2008/03/19 -> $Date:: 2013-12-16 #$
 *)

unit AVFilterStubs;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.SysUtils,
{$ELSE}
  SysUtils,
{$ENDIF}
  MyUtils,
  libavfilter,
  libavutil,
  libavutil_rational;

var
  av_buffersink_get_frame_flags : Tav_buffersink_get_frame_flagsProc  = nil;
  av_buffersink_set_frame_size  : Tav_buffersink_set_frame_sizeProc   = nil;
  av_buffersrc_add_frame        : Tav_buffersrc_add_frameProc         = nil;
  av_buffersrc_add_frame_flags  : Tav_buffersrc_add_frame_flagsProc   = nil;
  av_buffersrc_add_ref          : Tav_buffersrc_add_refProc           = nil;
  av_buffersrc_get_nb_failed_requests: Tav_buffersrc_get_nb_failed_requestsProc = nil;
  av_filter_next                : Tav_filter_nextProc                 = nil;
  avfilter_get_by_name          : Tavfilter_get_by_nameProc           = nil;
  avfilter_graph_alloc          : Tavfilter_graph_allocProc           = nil;
  avfilter_graph_alloc_filter   : Tavfilter_graph_alloc_filterProc    = nil;
  avfilter_graph_config         : Tavfilter_graph_configProc          = nil;
  avfilter_graph_create_filter  : Tavfilter_graph_create_filterProc   = nil;
  avfilter_graph_free           : Tavfilter_graph_freeProc            = nil;
  avfilter_graph_parse2         : Tavfilter_graph_parse2Proc          = nil;
  avfilter_graph_parse_ptr      : Tavfilter_graph_parse_ptrProc       = nil;
  avfilter_graph_queue_command  : Tavfilter_graph_queue_commandProc   = nil;
  avfilter_graph_request_oldest : Tavfilter_graph_request_oldestProc  = nil;
  avfilter_graph_send_command   : Tavfilter_graph_send_commandProc    = nil;
  avfilter_graph_set_auto_convert: Tavfilter_graph_set_auto_convertProc = nil;
  avfilter_init_str             : Tavfilter_init_strProc              = nil;
  avfilter_inout_alloc          : Tavfilter_inout_allocProc           = nil;
  avfilter_inout_free           : Tavfilter_inout_freeProc            = nil;
  avfilter_link                 : Tavfilter_linkProc                  = nil;
  avfilter_link_get_channels    : Tavfilter_link_get_channelsProc     = nil;
  avfilter_pad_get_name         : Tavfilter_pad_get_nameProc          = nil;
  avfilter_pad_get_type         : Tavfilter_pad_get_typeProc          = nil;
//  avfilter_register             : Tavfilter_registerProc              = nil;
  avfilter_register_all         : Tavfilter_register_allProc          = nil;
{
  // private api of ffmpeg libraries
  ff_get_video_buffer           : Tff_get_video_bufferProc            = nil;
  ff_filter_frame               : Tff_filter_frameProc                = nil;
  ff_make_format_list           : Tff_make_format_listProc            = nil;
  ff_set_common_formats         : Tff_set_common_formatsProc          = nil;
}

(****** TODO: check from libavfilter/buffersink.h **************)
(**
 * Get the frame rate of the input.
 *)
function av_buffersink_get_frame_rate(ctx: PAVFilterContext): TAVRational;

procedure AVFilterFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
procedure AVFilterUnfixStubs;

implementation

(****** TODO: check from libavfilter/buffersink.c **************)
function av_buffersink_get_frame_rate(ctx: PAVFilterContext): TAVRational;
begin
  Assert((ctx.filter.name = 'buffersink') or (ctx.filter.name = 'ffbuffersink'));
  Result := ctx.inputs^^.frame_rate;
end;

procedure AVFilterFixupStubs(const ALibFile: TPathFileName; const AHandle: THandle);
begin
  FixupStub(ALibFile, AHandle, 'av_buffersink_get_frame_flags',  @av_buffersink_get_frame_flags);
  FixupStub(ALibFile, AHandle, 'av_buffersink_set_frame_size',  @av_buffersink_set_frame_size);
  FixupStub(ALibFile, AHandle, 'av_buffersrc_add_frame',        @av_buffersrc_add_frame);
  FixupStub(ALibFile, AHandle, 'av_buffersrc_add_frame_flags',  @av_buffersrc_add_frame_flags);
  FixupStub(ALibFile, AHandle, 'av_buffersrc_add_ref',          @av_buffersrc_add_ref);
  FixupStub(ALibFile, AHandle, 'av_buffersrc_get_nb_failed_requests', @av_buffersrc_get_nb_failed_requests);
  FixupStub(ALibFile, AHandle, 'av_filter_next',                @av_filter_next);
  FixupStub(ALibFile, AHandle, 'avfilter_get_by_name',          @avfilter_get_by_name);
  FixupStub(ALibFile, AHandle, 'avfilter_graph_alloc',          @avfilter_graph_alloc);
  FixupStub(ALibFile, AHandle, 'avfilter_graph_alloc_filter',   @avfilter_graph_alloc_filter);
  FixupStub(ALibFile, AHandle, 'avfilter_graph_config',         @avfilter_graph_config);
  FixupStub(ALibFile, AHandle, 'avfilter_graph_create_filter',  @avfilter_graph_create_filter);
  FixupStub(ALibFile, AHandle, 'avfilter_graph_free',           @avfilter_graph_free);
  FixupStub(ALibFile, AHandle, 'avfilter_graph_parse2',         @avfilter_graph_parse2);
  FixupStub(ALibFile, AHandle, 'avfilter_graph_parse_ptr',      @avfilter_graph_parse_ptr);
  FixupStub(ALibFile, AHandle, 'avfilter_graph_queue_command',  @avfilter_graph_queue_command);
  FixupStub(ALibFile, AHandle, 'avfilter_graph_request_oldest', @avfilter_graph_request_oldest);
  FixupStub(ALibFile, AHandle, 'avfilter_graph_send_command',   @avfilter_graph_send_command);
  FixupStub(ALibFile, AHandle, 'avfilter_graph_set_auto_convert', @avfilter_graph_set_auto_convert);
  FixupStub(ALibFile, AHandle, 'avfilter_init_str',             @avfilter_init_str);
  FixupStub(ALibFile, AHandle, 'avfilter_inout_alloc',          @avfilter_inout_alloc);
  FixupStub(ALibFile, AHandle, 'avfilter_inout_free',           @avfilter_inout_free);
  FixupStub(ALibFile, AHandle, 'avfilter_link',                 @avfilter_link);
  FixupStub(ALibFile, AHandle, 'avfilter_link_get_channels',    @avfilter_link_get_channels);
  FixupStub(ALibFile, AHandle, 'avfilter_pad_get_name',         @avfilter_pad_get_name);
  FixupStub(ALibFile, AHandle, 'avfilter_pad_get_type',         @avfilter_pad_get_type);
//  FixupStub(ALibFile, AHandle, 'avfilter_register',             @avfilter_register);
  FixupStub(ALibFile, AHandle, 'avfilter_register_all',         @avfilter_register_all);
{
  // private api of ffmpeg libraries
  FixupStub(ALibFile, AHandle, 'ff_get_video_buffer',           @ff_get_video_buffer,       True);
  FixupStub(ALibFile, AHandle, 'ff_filter_frame',               @ff_filter_frame,           True);
  FixupStub(ALibFile, AHandle, 'ff_make_format_list',           @ff_make_format_list,       True);
  FixupStub(ALibFile, AHandle, 'ff_set_common_formats',         @ff_set_common_formats,     True);
}
  avfilter_register_all;
end;

procedure AVFilterUnfixStubs;
begin
  @av_buffersink_get_frame_flags  := nil;
  @av_buffersink_set_frame_size   := nil;
  @av_buffersrc_add_frame         := nil;
  @av_buffersrc_add_frame_flags   := nil;
  @av_buffersrc_add_ref           := nil;
  @av_buffersrc_get_nb_failed_requests := nil;
  @av_filter_next                 := nil;
  @avfilter_get_by_name           := nil;
  @avfilter_graph_alloc           := nil;
  @avfilter_graph_alloc_filter    := nil;
  @avfilter_graph_config          := nil;
  @avfilter_graph_create_filter   := nil;
  @avfilter_graph_free            := nil;
  @avfilter_graph_parse2          := nil;
  @avfilter_graph_parse_ptr       := nil;
  @avfilter_graph_queue_command   := nil;
  @avfilter_graph_request_oldest  := nil;
  @avfilter_graph_send_command    := nil;
  @avfilter_graph_set_auto_convert := nil;
  @avfilter_init_str              := nil;
  @avfilter_inout_alloc           := nil;
  @avfilter_inout_free            := nil;
  @avfilter_link                  := nil;
  @avfilter_link_get_channels     := nil;
  @avfilter_pad_get_name          := nil;
  @avfilter_pad_get_type          := nil;
//  @avfilter_register              := nil;
  @avfilter_register_all          := nil;
{
  @ff_get_video_buffer            := nil;
  @ff_filter_frame                := nil;
  @ff_make_format_list            := nil;
  @ff_set_common_formats          := nil;
}
end;

end.
