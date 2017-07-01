(*
 * filter layer
 * Copyright (c) 2007 Bobby Bingham
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *)

(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Original file: libavfilter/avfilter.h
 * Ported by CodeCoolie@CNSW 2008/03/19 -> $Date:: 2013-11-18 #$
 *)

unit libavfilter;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF BCB}
  BCBTypes,
{$ENDIF}
  libavutil,
  libavutil_dict,
  libavutil_frame,
  libavutil_log,
  libavutil_pixfmt,
  libavutil_rational,
  libavutil_samplefmt;

{$I libversion.inc}

(**
 * @file
 * @ingroup lavfi
 * Main libavfilter public API header
 *)

(**
 * @defgroup lavfi Libavfilter - graph-based frame editing library
 * @{
 *)

const
  // const for TAVFilterBufferRef.perms
  AV_PERM_READ     = $01;   ///< can read from the buffer
  AV_PERM_WRITE    = $02;   ///< can write to the buffer
  AV_PERM_PRESERVE = $04;   ///< nobody else can overwrite the buffer
  AV_PERM_REUSE    = $08;   ///< can output the buffer multiple times, with the same contents each time
  AV_PERM_REUSE2   = $10;   ///< can output the buffer multiple times, modified each time
  AV_PERM_NEG_LINESIZES = $20;  ///< the buffer requested can have negative linesizes
  AV_PERM_ALIGN    = $40;   ///< the buffer must be aligned

  AVFILTER_ALIGN = 16; //not part of ABI

  AVFILTER_FLAG_DYNAMIC_INPUTS            = (1 shl  0);
  AVFILTER_FLAG_DYNAMIC_OUTPUTS           = (1 shl  1);
  AVFILTER_FLAG_SLICE_THREADS             = (1 shl  2);
  AVFILTER_FLAG_SUPPORT_TIMELINE_GENERIC  = (1 shl 16);
  AVFILTER_FLAG_SUPPORT_TIMELINE_INTERNAL = (1 shl 17);
  AVFILTER_FLAG_SUPPORT_TIMELINE          = (AVFILTER_FLAG_SUPPORT_TIMELINE_GENERIC or AVFILTER_FLAG_SUPPORT_TIMELINE_INTERNAL);

  AVFILTER_THREAD_SLICE  = (1 shl 0);

  AVFILTER_CMD_FLAG_ONE  = 1; ///< Stop once a filter understood the command (for target=all for example), fast filters are favored automatically
  AVFILTER_CMD_FLAG_FAST = 2; ///< Only execute command when its fast (like a video out that supports contrast adjustment in hw)

(****** TODO: check from libavfilter/buffersink.h **************)
  AV_BUFFERSINK_FLAG_PEEK = 1;
  AV_BUFFERSINK_FLAG_NO_REQUEST = 2;

(****** TODO: check from libavfilter/buffersrc.h **************)
  AV_BUFFERSRC_FLAG_NO_CHECK_FORMAT = 1;
{$IFDEF FF_API_AVFILTERBUFFER}
  AV_BUFFERSRC_FLAG_NO_COPY = 2;
{$ENDIF}
  AV_BUFFERSRC_FLAG_PUSH = 4;
  AV_BUFFERSRC_FLAG_KEEP_REF = 8;

type
(**
 * Return the LIBAVFILTER_VERSION_INT constant.
 *)
  Tavfilter_versionProc = function: Cardinal; cdecl;

(**
 * Return the libavfilter build-time configuration.
 *)
  Tavfilter_configurationProc = function: PAnsiChar; cdecl;

(**
 * Return the libavfilter license.
 *)
  Tavfilter_licenseProc = function: PAnsiChar; cdecl;

  PPAVFilterContext = ^PAVFilterContext;
  PAVFilterContext = ^TAVFilterContext;

  PPPAVFilterLink = ^PPAVFilterLink;
  PPAVFilterLink = ^PAVFilterLink;
  PAVFilterLink = ^TAVFilterLink;
  //typedef struct AVFilterPad     AVFilterPad;
  //typedef struct AVFilterFormats AVFilterFormats;
  PPPAVFilterFormats = ^PPAVFilterFormats;
  PPAVFilterFormats = ^PAVFilterFormats;
  PAVFilterFormats = ^TAVFilterFormats;

{$IFDEF FF_API_AVFILTERBUFFER}
(**
 * A reference-counted buffer data type used by the filter system. Filters
 * should not store pointers to this structure directly, but instead use the
 * AVFilterBufferRef structure below.
 *)
  PAVFilterBuffer = ^TAVFilterBuffer;
  TAVFilterBuffer = record
    data: array[0..7] of PByte;           ///< buffer data for each plane/channel

    (**
     * pointers to the data planes/channels.
     *
     * For video, this should simply point to data[].
     *
     * For planar audio, each channel has a separate data pointer, and
     * linesize[0] contains the size of each channel buffer.
     * For packed audio, there is just one data pointer, and linesize[0]
     * contains the total size of the buffer for all channels.
     *
     * Note: Both data and extended_data will always be set, but for planar
     * audio with more channels that can fit in data, extended_data must be used
     * in order to access all channels.
     *)
    extended_data: PPByte;
    linesize: array[0..7] of Integer;     ///< number of bytes per line

    (** private data to be used by a custom free function *)
    priv: Pointer;
    (**
     * A pointer to the function to deallocate this buffer if the default
     * function is not sufficient. This could, for example, add the memory
     * back into a memory pool to be reused later without the overhead of
     * reallocating it from scratch.
     *)
    free: procedure(buf: PAVFilterBuffer); cdecl;

    format: Integer;                 ///< media format
    w, h: Integer;                   ///< width and height of the allocated buffer
    refcount: Cardinal;        ///< number of references to this buffer
  end;

(**
 * Audio specific properties in a reference to an AVFilterBuffer. Since
 * AVFilterBufferRef is common to different media formats, audio specific
 * per reference properties must be separated out.
 *)
  PAVFilterBufferRefAudioProps = ^TAVFilterBufferRefAudioProps;
  TAVFilterBufferRefAudioProps = record
    channel_layout: Int64;     ///< channel layout of audio buffer
    nb_samples: Integer;       ///< number of audio samples per channel
    sample_rate: Integer;      ///< audio buffer sample rate
    channels: Integer;         ///< number of channels (do not access directly)
  end;

(**
 * Video specific properties in a reference to an AVFilterBuffer. Since
 * AVFilterBufferRef is common to different media formats, video specific
 * per reference properties must be separated out.
 *)
  PAVFilterBufferRefVideoProps = ^TAVFilterBufferRefVideoProps;
  TAVFilterBufferRefVideoProps = record
    w: Integer;                   ///< image width
    h: Integer;                   ///< image height
    sample_aspect_ratio: TAVRational; ///< sample aspect ratio
    interlaced: Integer;          ///< is frame interlaced
    top_field_first: Integer;     ///< field order
    pict_type: TAVPictureType;    ///< picture type of the frame
    key_frame: Integer;           ///< 1 -> keyframe, 0-> not
    qp_table_linesize: Integer;   ///< qp_table stride
    qp_table_size: Integer;       ///< qp_table size
    qp_table: PByte;              ///< array of Quantization Parameters
  end;

(**
 * A reference to an AVFilterBuffer. Since filters can manipulate the origin of
 * a buffer to, for example, crop image without any memcpy, the buffer origin
 * and dimensions are per-reference properties. Linesize is also useful for
 * image flipping, frame to field filters, etc, and so is also per-reference.
 *
 * TODO: add anything necessary for frame reordering
 *)
  PPAVFilterBufferRef = ^PAVFilterBufferRef;
  PAVFilterBufferRef = ^TAVFilterBufferRef;
  TAVFilterBufferRef = record
    buf: PAVFilterBuffer;             ///< the buffer that this is a reference to
    data: array[0..7] of PByte;       ///< picture/audio data for each plane
    (**
     * pointers to the data planes/channels.
     *
     * For video, this should simply point to data[].
     *
     * For planar audio, each channel has a separate data pointer, and
     * linesize[0] contains the size of each channel buffer.
     * For packed audio, there is just one data pointer, and linesize[0]
     * contains the total size of the buffer for all channels.
     *
     * Note: Both data and extended_data will always be set, but for planar
     * audio with more channels that can fit in data, extended_data must be used
     * in order to access all channels.
     *)
    extended_data: PPByte;
    linesize: array[0..7] of Integer; ///< number of bytes per line

    video: PAVFilterBufferRefVideoProps;  ///< video buffer specific properties
    audio: PAVFilterBufferRefAudioProps;  ///< audio buffer specific properties

    (**
     * presentation timestamp. The time unit may change during
     * filtering, as it is specified in the link and the filter code
     * may need to rescale the PTS accordingly.
     *)
    pts: Int64;
    pos: Int64;                       ///< byte position in stream, -1 if unknown

    format: Integer;                  ///< media format

    perms: Integer;                   ///< permissions, see the AV_PERM_* flags

    type_: TAVMediaType;              ///< media type of buffer data

    metadata: PAVDictionary;          ///< dictionary containing metadata key=value tags
  end;

(**
 * Copy properties of src to dst, without copying the actual data
 *)
  Tavfilter_copy_buffer_ref_propsProc = procedure(dst, src: PAVFilterBufferRef); cdecl;

(**
 * Add a new reference to a buffer.
 *
 * @param ref   an existing reference to the buffer
 * @param pmask a bitmask containing the allowable permissions in the new
 *              reference
 * @return      a new reference to the buffer with the same properties as the
 *              old, excluding any permissions denied by pmask
 *)
  Tavfilter_ref_bufferProc = function(ref: PAVFilterBufferRef; pmask: Integer): PAVFilterBufferRef; cdecl;

(**
 * Remove a reference to a buffer. If this is the last reference to the
 * buffer, the buffer itself is also automatically freed.
 *
 * @param ref reference to the buffer, may be NULL
 *
 * @note it is recommended to use avfilter_unref_bufferp() instead of this
 * function
 *)
  Tavfilter_unref_bufferProc = procedure(ref: PAVFilterBufferRef); cdecl;

(**
 * Remove a reference to a buffer and set the pointer to NULL.
 * If this is the last reference to the buffer, the buffer itself
 * is also automatically freed.
 *
 * @param ref pointer to the buffer reference
 *)
  Tavfilter_unref_bufferpProc = procedure(ref: PPAVFilterBufferRef); cdecl;
{$ENDIF}

(**
 * Get the number of channels of a buffer reference.
 *)
  Tavfilter_ref_get_channelsProc = function(ref: PAVFilterBufferRef): Integer; cdecl;

{$IFDEF FF_API_AVFILTERPAD_PUBLIC}
(**
 * A filter pad used for either input or output.
 *
 * See doc/filter_design.txt for details on how to implement the methods.
 *
 * @warning this struct might be removed from public API.
 * users should call avfilter_pad_get_name() and avfilter_pad_get_type()
 * to access the name and type fields; there should be no need to access
 * any other fields from outside of libavfilter.
 *)
  PPAVFilterPad = ^PAVFilterPad;
  PAVFilterPad = ^TAVFilterPad;
  TAVFilterPad = record
    (**
     * Pad name. The name is unique among inputs and among outputs, but an
     * input may have the same name as an output. This may be NULL if this
     * pad has no need to ever be referenced by name.
     *)
    name: PAnsiChar;

    (**
     * AVFilterPad type.
     *)
    ttype: TAVMediaType;

    (**
     * Input pads:
     * Minimum required permissions on incoming buffers. Any buffer with
     * insufficient permissions will be automatically copied by the filter
     * system to a new buffer which provides the needed access permissions.
     *
     * Output pads:
     * Guaranteed permissions on outgoing buffers. Any buffer pushed on the
     * link must have at least these permissions; this fact is checked by
     * asserts. It can be used to optimize buffer allocation.
     *)
    min_perms: Integer;

    (**
     * Input pads:
     * Permissions which are not accepted on incoming buffers. Any buffer
     * which has any of these permissions set will be automatically copied
     * by the filter system to a new buffer which does not have those
     * permissions. This can be used to easily disallow buffers with
     * AV_PERM_REUSE.
     *
     * Output pads:
     * Permissions which are automatically removed on outgoing buffers. It
     * can be used to optimize buffer allocation.
     *)
    rej_perms: Integer;

    (**
     * @deprecated unused
     *)
    start_frame: function(link: PAVFilterLink; picref: PAVFilterBufferRef): Integer; cdecl;

    (**
     * Callback function to get a video buffer. If NULL, the filter system will
     * use ff_default_get_video_buffer().
     *
     * Input video pads only.
     *)
    get_video_buffer: function(link: PAVFilterLink; w, h: Integer): PAVFrame; cdecl;

    (**
     * Callback function to get an audio buffer. If NULL, the filter system will
     * use ff_default_get_audio_buffer().
     *
     * Input audio pads only.
     *)
     get_audio_buffer: function(link: PAVFilterLink; nb_samples: Integer): PAVFrame; cdecl;

    (**
     * @deprecated unused
     *)
    end_frame: function(link: PAVFilterLink): Integer; cdecl;

    (**
     * @deprecated unused
     *)
    draw_slice: function(link: PAVFilterLink; y, height, slice_dir: Integer): Integer; cdecl;

    (**
     * Filtering callback. This is where a filter receives a frame with
     * audio/video data and should do its processing.
     *
     * Input pads only.
     *
     * @return >= 0 on success, a negative AVERROR on error. This function
     * must ensure that frame is properly unreferenced on error if it
     * hasn't been passed on to another filter.
     *)
    filter_frame: function(link: PAVFilterLink; frame: PAVFrame): Integer; cdecl;

    (**
     * Frame poll callback. This returns the number of immediately available
     * samples. It should return a positive value if the next request_frame()
     * is guaranteed to return one frame (with no delay).
     *
     * Defaults to just calling the source poll_frame() method.
     *
     * Output pads only.
     *)
    poll_frame: function(link: PAVFilterLink): Integer; cdecl;

    (**
     * Frame request callback. A call to this should result in at least one
     * frame being output over the given link. This should return zero on
     * success, and another value on error.
     * See ff_request_frame() for the error codes with a specific
     * meaning.
     *
     * Output pads only.
     *)
    request_frame: function(link: PAVFilterLink): Integer; cdecl;

    (**
     * Link configuration callback.
     *
     * For output pads, this should set the following link properties:
     * video: width, height, sample_aspect_ratio, time_base
     * audio: sample_rate.
     *
     * This should NOT set properties such as format, channel_layout, etc which
     * are negotiated between filters by the filter system using the
     * query_formats() callback before this function is called.
     *
     * For input pads, this should check the properties of the link, and update
     * the filter's internal state as necessary.
     *
     * For both input and output pads, this should return zero on success,
     * and another value on error.
     *)
    config_props: function(link: PAVFilterLink): Integer; cdecl;

    (**
     * The filter expects a fifo to be inserted on its input link,
     * typically because it has a delay.
     *
     * input pads only.
     *)
    needs_fifo: Integer;

    needs_writable: Integer;
  end;
{$ENDIF}

(**
 * Get the number of elements in a NULL-terminated array of AVFilterPads (e.g.
 * AVFilter.inputs/outputs).
 *)
  Tavfilter_pad_countProc = function(const pads: PAVFilterPad): Integer; cdecl;

(**
 * Get the name of an AVFilterPad.
 *
 * @param pads an array of AVFilterPads
 * @param pad_idx index of the pad in the array it; is the caller's
 *                responsibility to ensure the index is valid
 *
 * @return name of the pad_idx'th pad in pads
 *)
  Tavfilter_pad_get_nameProc = function(const pads: PAVFilterPad; pad_idx: Integer): PAnsiChar; cdecl;

(**
 * Get the type of an AVFilterPad.
 *
 * @param pads an array of AVFilterPads
 * @param pad_idx index of the pad in the array; it is the caller's
 *                responsibility to ensure the index is valid
 *
 * @return type of the pad_idx'th pad in pads
 *)
  Tavfilter_pad_get_typeProc = function(const pads: PAVFilterPad; pad_idx: Integer): TAVMediaType; cdecl;

(*
/**
 * The number of the filter inputs is not determined just by AVFilter.inputs.
 * The filter might add additional inputs during initialization depending on the
 * options supplied to it.
 */
#define AVFILTER_FLAG_DYNAMIC_INPUTS        (1 << 0)
/**
 * The number of the filter outputs is not determined just by AVFilter.outputs.
 * The filter might add additional outputs during initialization depending on
 * the options supplied to it.
 */
#define AVFILTER_FLAG_DYNAMIC_OUTPUTS       (1 << 1)
/**
 * The filter supports multithreading by splitting frames into multiple parts
 * and processing them concurrently.
 */
#define AVFILTER_FLAG_SLICE_THREADS         (1 << 2)
/**
 * Some filters support a generic "enable" expression option that can be used
 * to enable or disable a filter in the timeline. Filters supporting this
 * option have this flag set. When the enable expression is false, the default
 * no-op filter_frame() function is called in place of the filter_frame()
 * callback defined on each input pad, thus the frame is passed unchanged to
 * the next filters.
 */
#define AVFILTER_FLAG_SUPPORT_TIMELINE_GENERIC  (1 << 16)
/**
 * Same as AVFILTER_FLAG_SUPPORT_TIMELINE_GENERIC, except that the filter will
 * have its filter_frame() callback(s) called as usual even when the enable
 * expression is false. The filter will disable filtering within the
 * filter_frame() callback(s) itself, for example executing code depending on
 * the AVFilterContext->is_disabled value.
 */
#define AVFILTER_FLAG_SUPPORT_TIMELINE_INTERNAL (1 << 17)
/**
 * Handy mask to test whether the filter supports or no the timeline feature
 * (internally or generically).
 */
#define AVFILTER_FLAG_SUPPORT_TIMELINE (AVFILTER_FLAG_SUPPORT_TIMELINE_GENERIC | AVFILTER_FLAG_SUPPORT_TIMELINE_INTERNAL)
*)

(**
 * Filter definition. This defines the pads a filter contains, and all the
 * callback functions used to interact with the filter.
 *)
  PPAVFilter = ^PAVFilter;
  PAVFilter = ^TAVFilter;
  TAVFilter = record
    (**
     * Filter name. Must be non-NULL and unique among filters.
     *)
    name: PAnsiChar;         ///< filter name

    (**
     * A description of the filter. May be NULL.
     *
     * You should use the NULL_IF_CONFIG_SMALL() macro to define it.
     *)
    description: PAnsiChar;

    (**
     * List of inputs, terminated by a zeroed element.
     *
     * NULL if there are no (static) inputs. Instances of filters with
     * AVFILTER_FLAG_DYNAMIC_INPUTS set may have more inputs than present in
     * this list.
     *)
    inputs: PAVFilterPad;  ///< NULL terminated list of inputs. NULL if none
    (**
     * List of outputs, terminated by a zeroed element.
     *
     * NULL if there are no (static) outputs. Instances of filters with
     * AVFILTER_FLAG_DYNAMIC_OUTPUTS set may have more outputs than present in
     * this list.
     *)
    outputs: PAVFilterPad; ///< NULL terminated list of outputs. NULL if none

    (**
     * A class for the private data, used to declare filter private AVOptions.
     * This field is NULL for filters that do not declare any options.
     *
     * If this field is non-NULL, the first member of the filter private data
     * must be a pointer to AVClass, which will be set by libavfilter generic
     * code to this class.
     *)
    priv_class: PAVClass;

    (**
     * A combination of AVFILTER_FLAG_*
     *)
    flags: Integer;

    (*****************************************************************
     * All fields below this line are not part of the public API. They
     * may not be used outside of libavfilter and can be changed and
     * removed at will.
     * New public fields should be added right above.
     *****************************************************************
     *)

    (**
     * Filter initialization function.
     *
     * This callback will be called only once during the filter lifetime, after
     * all the options have been set, but before links between filters are
     * established and format negotiation is done.
     *
     * Basic filter initialization should be done here. Filters with dynamic
     * inputs and/or outputs should create those inputs/outputs here based on
     * provided options. No more changes to this filter's inputs/outputs can be
     * done after this callback.
     *
     * This callback must not assume that the filter links exist or frame
     * parameters are known.
     *
     * @ref AVFilter.uninit "uninit" is guaranteed to be called even if
     * initialization fails, so this callback does not have to clean up on
     * failure.
     *
     * @return 0 on success, a negative AVERROR on failure
     *)
    init: function(ctx: PAVFilterContext): Integer; cdecl;

    (**
     * Should be set instead of @ref AVFilter.init "init" by the filters that
     * want to pass a dictionary of AVOptions to nested contexts that are
     * allocated during init.
     *
     * On return, the options dict should be freed and replaced with one that
     * contains all the options which could not be processed by this filter (or
     * with NULL if all the options were processed).
     *
     * Otherwise the semantics is the same as for @ref AVFilter.init "init".
     *)
    init_dict: function(ctx: PAVFilterContext; options: PPAVDictionary): Integer; cdecl;

    (**
     * Filter uninitialization function.
     *
     * Called only once right before the filter is freed. Should deallocate any
     * memory held by the filter, release any buffer references, etc. It does
     * not need to deallocate the AVFilterContext.priv memory itself.
     *
     * This callback may be called even if @ref AVFilter.init "init" was not
     * called or failed, so it must be prepared to handle such a situation.
     *)
    uninit: procedure(ctx: PAVFilterContext); cdecl;

    (**
     * Query formats supported by the filter on its inputs and outputs.
     *
     * This callback is called after the filter is initialized (so the inputs
     * and outputs are fixed), shortly before the format negotiation. This
     * callback may be called more than once.
     *
     * This callback must set AVFilterLink.out_formats on every input link and
     * AVFilterLink.in_formats on every output link to a list of pixel/sample
     * formats that the filter supports on that link. For audio links, this
     * filter must also set @ref AVFilterLink.in_samplerates "in_samplerates" /
     * @ref AVFilterLink.out_samplerates "out_samplerates" and
     * @ref AVFilterLink.in_channel_layouts "in_channel_layouts" /
     * @ref AVFilterLink.out_channel_layouts "out_channel_layouts" analogously.
     *
     * This callback may be NULL for filters with one input, in which case
     * libavfilter assumes that it supports all input formats and preserves
     * them on output.
     *
     * @return zero on success, a negative value corresponding to an
     * AVERROR code otherwise
     *)
    query_formats: function(ctx: PAVFilterContext): Integer; cdecl;

    priv_size: Integer;  ///< size of private data to allocate for the filter

    (**
     * Used by the filter registration system. Must not be touched by any other
     * code.
     *)
    next: PAVFilter;

    (**
     * Make the filter instance process a command.
     *
     * @param cmd    the command to process, for handling simplicity all commands must be alphanumeric only
     * @param arg    the argument for the command
     * @param res    a buffer with size res_size where the filter(s) can return a response. This must not change when the command is not supported.
     * @param flags  if AVFILTER_CMD_FLAG_FAST is set and the command would be
     *               time consuming then a filter should treat it like an unsupported command
     *
     * @returns >=0 on success otherwise an error code.
     *          AVERROR(ENOSYS) on unsupported commands
     *)
    process_command: function(ctx: PAVFilterContext; const cmd, arg: PAnsiChar; res: PAnsiChar; res_len, flags: Integer): Integer; cdecl;

    (**
     * Filter initialization function, alternative to the init()
     * callback. Args contains the user-supplied parameters, opaque is
     * used for providing binary data.
     *)
    init_opaque: function(ctx: PAVFilterContext; opaque: Pointer): Integer; cdecl;
  end;

(*
/**
 * Process multiple parts of the frame concurrently.
 */
#define AVFILTER_THREAD_SLICE (1 << 0)
*)

  PAVFilterInternal = ^TAVFilterInternal;
  TAVFilterInternal = record
    // need {$ALIGN 8}
  end;

(** An instance of a filter *)
  PPAVFilterGraph = ^PAVFilterGraph;
  PAVFilterGraph = ^TAVFilterGraph;
  TAVFilterContext = record
    av_class: PAVClass;         ///< needed for av_log() and filters common options

    filter: PAVFilter;          ///< the AVFilter of which this is an instance

    name: PAnsiChar;            ///< name of this filter instance

    input_pads: PAVFilterPad;   ///< array of input pads
    inputs: PPAVFilterLink;     ///< array of pointers to input links
{$IFDEF FF_API_FOO_COUNT}
    input_count: Cardinal;      ///< @deprecated use nb_inputs
{$ENDIF}
    nb_inputs: Cardinal;        ///< number of input pads

    output_pads: PAVFilterPad;  ///< array of output pads
    outputs: PPAVFilterLink;    ///< array of pointers to output links
{$IFDEF FF_API_FOO_COUNT}
    output_count: Cardinal;     ///< @deprecated use nb_outputs
{$ENDIF}
    nb_outputs: Cardinal;       ///< number of output pads

    priv: Pointer;              ///< private data for use by the filter

    graph: PAVFilterGraph;      ///< filtergraph this filter belongs to

    (**
     * Type of multithreading being allowed/used. A combination of
     * AVFILTER_THREAD_* flags.
     *
     * May be set by the caller before initializing the filter to forbid some
     * or all kinds of multithreading for this filter. The default is allowing
     * everything.
     *
     * When the filter is initialized, this field is combined using bit AND with
     * AVFilterGraph.thread_type to get the final mask used for determining
     * allowed threading types. I.e. a threading type needs to be set in both
     * to be allowed.
     *
     * After the filter is initialzed, libavfilter sets this field to the
     * threading type that is actually used (0 for no multithreading).
     *)
    thread_type: Integer;

    (**
     * An opaque struct for libavfilter internal use.
     *)
    internal: PAVFilterInternal;

    command_queue: Pointer; //PAVFilterCommand;

    enable_str: PAnsiChar;      ///< enable expression string
    enable: Pointer;            ///< parsed expression (AVExpr*)
    var_values: PDouble;        ///< variable values for the enable expression
    is_disabled: Integer;       ///< the enabled state from the last expression evaluation
  end;

  Tinit_state = (
    AVLINK_UNINIT = 0,      ///< not started
    AVLINK_STARTINIT,       ///< started, but incomplete
    AVLINK_INIT             ///< complete
  );

  PPPAVFilterChannelLayouts = ^PPAVFilterChannelLayouts;
  PPAVFilterChannelLayouts = ^PAVFilterChannelLayouts;
  PAVFilterChannelLayouts = ^TAVFilterChannelLayouts;

(**
 * A link between two filters. This contains pointers to the source and
 * destination filters between which this link exists, and the indexes of
 * the pads involved. In addition, this link also contains the parameters
 * which have been negotiated and agreed upon between the filter, such as
 * image dimensions, format, etc.
 *)
  TAVFilterLink = record
    src: PAVFilterContext;    ///< source filter
    srcpad: PAVFilterPad;     ///< output pad on the source filter

    dst: PAVFilterContext;    ///< dest filter
    dstpad: PAVFilterPad;     ///< input pad on the dest filter

    type_: TAVMediaType;      ///< filter media type

    (* These parameters apply only to video *)
    w: Integer;               ///< agreed upon image width
    h: Integer;               ///< agreed upon image height
    sample_aspect_ratio: TAVRational; ///< agreed upon sample aspect ratio
    (* These parameters apply only to audio *)
    channel_layout: Int64;    ///< channel layout of current buffer (see libavutil/channel_layout.h)
    sample_rate: Integer;     ///< samples per second

    format: Integer;          ///< agreed upon media format

    (**
     * Define the time base used by the PTS of the frames/samples
     * which will pass through this link.
     * During the configuration stage, each filter is supposed to
     * change only the output timebase, while the timebase of the
     * input link is assumed to be an unchangeable property.
     *)
    time_base: TAVRational;

    (*****************************************************************
     * All fields below this line are not part of the public API. They
     * may not be used outside of libavfilter and can be changed and
     * removed at will.
     * New public fields should be added right above.
     *****************************************************************
     *)
    (**
     * Lists of formats and channel layouts supported by the input and output
     * filters respectively. These lists are used for negotiating the format
     * to actually be used, which will be loaded into the format and
     * channel_layout members, above, when chosen.
     *
     *)
    in_formats: PAVFilterFormats;
    out_formats: PAVFilterFormats;

    (**
     * Lists of channel layouts and sample rates used for automatic
     * negotiation.
     *)
    in_samplerates: PAVFilterFormats;
    out_samplerates: PAVFilterFormats;
    in_channel_layouts: PAVFilterChannelLayouts;
    out_channel_layouts: PAVFilterChannelLayouts;

    (**
     * Audio only, the destination filter sets this to a non-zero value to
     * request that buffers with the given number of samples should be sent to
     * it. AVFilterPad.needs_fifo must also be set on the corresponding input
     * pad.
     * Last buffer before EOF will be padded with silence.
     *)
    request_samples: Integer;

    (** stage of the initialization of the link properties (dimensions, etc) *)
    init_state: Tinit_state;

    pool: Pointer; // TODO: PAVFilterPool;
(*
// libavfilter/internal.h
#define POOL_SIZE 32
typedef struct AVFilterPool {
    AVFilterBufferRef *pic[POOL_SIZE];
    int count;
    int refcount;
    int draining;
} AVFilterPool;
*)
    (**
     * Graph the filter belongs to.
     *)
    graph: PAVFilterGraph;

    (**
     * Current timestamp of the link, as defined by the most recent
     * frame(s), in AV_TIME_BASE units.
     *)
    current_pts: Int64;

    (**
     * Index in the age array.
     *)
    age_index: Integer;

    (**
     * Frame rate of the stream on the link, or 1/0 if unknown;
     * if left to 0/0, will be automatically be copied from the first input
     * of the source filter if it exists.
     *
     * Sources should set it to the best estimation of the real frame rate.
     * Filters should update it if necessary depending on their function.
     * Sinks can use it to set a default output frame rate.
     * It is similar to the r_frame_rate field in AVStream.
     *)
    frame_rate: TAVRational;

    (**
     * Buffer partially filled with samples to achieve a fixed/minimum size.
     *)
    partial_buf: PAVFrame;

    (**
     * Size of the partial buffer to allocate.
     * Must be between min_samples and max_samples.
     *)
    partial_buf_size: Integer;

    (**
     * Minimum number of samples to filter at once. If filter_frame() is
     * called with fewer samples, it will accumulate them in partial_buf.
     * This field and the related ones must not be changed after filtering
     * has started.
     * If 0, all related fields are ignored.
     *)
    min_samples: Integer;

    (**
     * Maximum number of samples to filter at once. If filter_frame() is
     * called with more samples, it will split them.
     *)
    max_samples: Integer;

    (**
     * The buffer reference currently being received across the link by the
     * destination filter. This is used internally by the filter system to
     * allow automatic copying of buffers which do not have sufficient
     * permissions for the destination. This should not be accessed directly
     * by the filters.
     *)
    cur_buf_copy: PAVFilterBufferRef;

    (**
     * True if the link is closed.
     * If set, all attemps of start_frame, filter_frame or request_frame
     * will fail with AVERROR_EOF, and if necessary the reference will be
     * destroyed.
     * If request_frame returns AVERROR_EOF, this flag is set on the
     * corresponding link.
     * It can be set also be set by either the source or the destination
     * filter.
     *)
    closed: Integer;

    (**
     * Number of channels.
     *)
    channels: Integer;

    (**
     * True if a frame is being requested on the link.
     * Used internally by the framework.
     *)
    frame_requested: Cardinal;

    (**
     * Link processing flags.
     *)
    flags: Cardinal;

    (**
     * Number of past frames sent through the link.
     *)
    frame_count: Int64;
  end;

(**
 * Link two filters together.
 *
 * @param src    the source filter
 * @param srcpad index of the output pad on the source filter
 * @param dst    the destination filter
 * @param dstpad index of the input pad on the destination filter
 * @return       zero on success
 *)
  Tavfilter_linkProc = function(src: PAVFilterContext; srcpad: Cardinal;
                  dst: PAVFilterContext; dstpad: Cardinal): Integer; cdecl;

(**
 * Free the link in *link, and set its pointer to NULL.
 *)
  Tavfilter_link_freeProc = procedure(link: PPAVFilterLink); cdecl;

(**
 * Get the number of channels of a link.
 *)
  Tavfilter_link_get_channelsProc = function(link: PAVFilterLink): Integer; cdecl;

(**
 * Set the closed field of a link.
 *)
  Tavfilter_link_set_closedProc = procedure(link: PAVFilterLink; closed: Integer); cdecl;

(**
 * Negotiate the media format, dimensions, etc of all inputs to a filter.
 *
 * @param filter the filter to negotiate the properties for its inputs
 * @return       zero on successful negotiation
 *)
  Tavfilter_config_linksProc = function(filter: PAVFilterContext): Integer; cdecl;

{$IFDEF FF_API_AVFILTERBUFFER}
(**
 * Create a buffer reference wrapped around an already allocated image
 * buffer.
 *
 * @param data pointers to the planes of the image to reference
 * @param linesize linesizes for the planes of the image to reference
 * @param perms the required access permissions
 * @param w the width of the image specified by the data and linesize arrays
 * @param h the height of the image specified by the data and linesize arrays
 * @param format the pixel format of the image specified by the data and linesize arrays
 *)
  Tavfilter_get_video_buffer_ref_from_arraysProc = function(data: PPByte{array[0..3] of PByte}; linesize: PInteger{array[0..3] of Integer}; perms: Integer;
                                          w, h: Integer; format: TAVPixelFormat): PAVFilterBufferRef; cdecl;

(**
 * Create an audio buffer reference wrapped around an already
 * allocated samples buffer.
 *
 * See avfilter_get_audio_buffer_ref_from_arrays_channels() for a version
 * that can handle unknown channel layouts.
 *
 * @param data           pointers to the samples plane buffers
 * @param linesize       linesize for the samples plane buffers
 * @param perms          the required access permissions
 * @param nb_samples     number of samples per channel
 * @param sample_fmt     the format of each sample in the buffer to allocate
 * @param channel_layout the channel layout of the buffer
 *)
  Tavfilter_get_audio_buffer_ref_from_arraysProc = function(data: PPByte;
                                          linesize, perms, nb_samples: Integer; sample_fmt: TAVSampleFormat;
                                          channel_layout: Int64): PAVFilterBufferRef; cdecl;
(**
 * Create an audio buffer reference wrapped around an already
 * allocated samples buffer.
 *
 * @param data           pointers to the samples plane buffers
 * @param linesize       linesize for the samples plane buffers
 * @param perms          the required access permissions
 * @param nb_samples     number of samples per channel
 * @param sample_fmt     the format of each sample in the buffer to allocate
 * @param channels       the number of channels of the buffer
 * @param channel_layout the channel layout of the buffer,
 *                       must be either 0 or consistent with channels
 *)
  Tavfilter_get_audio_buffer_ref_from_arrays_channelsProc = function(data: PPByte;
                                          linesize, perms, nb_samples: Integer; sample_fmt: TAVSampleFormat;
                                          channels: Integer; channel_layout: Int64): PAVFilterBufferRef; cdecl;
{$ENDIF}


//#define AVFILTER_CMD_FLAG_ONE   1 ///< Stop once a filter understood the command (for target=all for example), fast filters are favored automatically
//#define AVFILTER_CMD_FLAG_FAST  2 ///< Only execute command when its fast (like a video out that supports contrast adjustment in hw)

(**
 * Make the filter instance process a command.
 * It is recommended to use avfilter_graph_send_command().
 *)
  Tavfilter_process_commandProc = function(filter: PAVFilterContext; const cmd, arg: PAnsiChar; res: PAnsiChar; res_len, flags: Integer): Integer; cdecl;

(** Initialize the filter system. Register all builtin filters. *)
  Tavfilter_register_allProc = procedure; cdecl;

{$IFDEF FF_API_OLD_FILTER_REGISTER}
(** Uninitialize the filter system. Unregister all filters. *)
  Tavfilter_uninitProc = procedure; cdecl;
{$ENDIF}

(**
 * Register a filter. This is only needed if you plan to use
 * avfilter_get_by_name later to lookup the AVFilter structure by name. A
 * filter can still by instantiated with avfilter_graph_alloc_filter even if it
 * is not registered.
 *
 * @param filter the filter to register
 * @return 0 if the registration was successful, a negative value
 * otherwise
 *)
  Tavfilter_registerProc = function(filter: PAVFilter): Integer; cdecl;

(**
 * Get a filter definition matching the given name.
 *
 * @param name the filter name to find
 * @return     the filter definition, if any matching one is registered.
 *             NULL if none found.
 *)
  Tavfilter_get_by_nameProc = function(const name: PAnsiChar): PAVFilter; cdecl;

(**
 * Iterate over all registered filters.
 * @return If prev is non-NULL, next registered filter after prev or NULL if
 * prev is the last filter. If prev is NULL, return the first registered filter.
 *)
  Tavfilter_nextProc = function(const prev: PAVFilter): PAVFilter; cdecl;

{$IFDEF FF_API_OLD_FILTER_REGISTER}
(**
 * If filter is NULL, returns a pointer to the first registered filter pointer,
 * if filter is non-NULL, returns the next pointer after filter.
 * If the returned pointer points to NULL, the last registered filter
 * was already reached.
 * @deprecated use avfilter_next()
 *)
  Tav_filter_nextProc = function(filter: PPAVFilter): PPAVFilter; cdecl;
{$ENDIF}

{$IFDEF FF_API_AVFILTER_OPEN}
(**
 * Create a filter instance.
 *
 * @param filter_ctx put here a pointer to the created filter context
 * on success, NULL on failure
 * @param filter    the filter to create an instance of
 * @param inst_name Name to give to the new instance. Can be NULL for none.
 * @return >= 0 in case of success, a negative error code otherwise
 * @deprecated use avfilter_graph_alloc_filter() instead
 *)
  Tavfilter_openProc = function(filter_ctx: PPAVFilterContext; filter: PAVFilter; const inst_name: PAnsiChar): Integer; cdecl;
{$ENDIF}


{$IFDEF FF_API_AVFILTER_INIT_FILTER}
(**
 * Initialize a filter.
 *
 * @param filter the filter to initialize
 * @param args   A string of parameters to use when initializing the filter.
 *               The format and meaning of this string varies by filter.
 * @param opaque Any extra non-string data needed by the filter. The meaning
 *               of this parameter varies by filter.
 * @return       zero on success
 *)
  Tavfilter_init_filterProc = function(filter: PAVFilterContext; const args: PAnsiChar; opaque: Pointer): Integer; cdecl;
{$ENDIF}

(**
 * Initialize a filter with the supplied parameters.
 *
 * @param ctx  uninitialized filter context to initialize
 * @param args Options to initialize the filter with. This must be a
 *             ':'-separated list of options in the 'key=value' form.
 *             May be NULL if the options have been set directly using the
 *             AVOptions API or there are no options that need to be set.
 * @return 0 on success, a negative AVERROR on failure
 *)
  Tavfilter_init_strProc = function(ctx: PAVFilterContext; const args: PAnsiChar): Integer; cdecl;

(**
 * Initialize a filter with the supplied dictionary of options.
 *
 * @param ctx     uninitialized filter context to initialize
 * @param options An AVDictionary filled with options for this filter. On
 *                return this parameter will be destroyed and replaced with
 *                a dict containing options that were not found. This dictionary
 *                must be freed by the caller.
 *                May be NULL, then this function is equivalent to
 *                avfilter_init_str() with the second parameter set to NULL.
 * @return 0 on success, a negative AVERROR on failure
 *
 * @note This function and avfilter_init_str() do essentially the same thing,
 * the difference is in manner in which the options are passed. It is up to the
 * calling code to choose whichever is more preferable. The two functions also
 * behave differently when some of the provided options are not declared as
 * supported by the filter. In such a case, avfilter_init_str() will fail, but
 * this function will leave those extra options in the options AVDictionary and
 * continue as usual.
 *)
  Tavfilter_init_dictProc = function(ctx: PAVFilterContext; options: PPAVDictionary): Integer; cdecl;

(**
 * Free a filter context. This will also remove the filter from its
 * filtergraph's list of filters.
 *
 * @param filter the filter to free
 *)
  Tavfilter_freeProc = procedure(filter: PAVFilterContext); cdecl;

(**
 * Insert a filter in the middle of an existing link.
 *
 * @param link the link into which the filter should be inserted
 * @param filt the filter to be inserted
 * @param filt_srcpad_idx the input pad on the filter to connect
 * @param filt_dstpad_idx the output pad on the filter to connect
 * @return     zero on success
 *)
  Tavfilter_insert_filterProc = function(link: PAVFilterLink; filt: PAVFilterContext;
                           filt_srcpad_idx, filt_dstpad_idx: Cardinal): Integer; cdecl;

{$IFDEF FF_API_AVFILTERBUFFER}
(**
 * Copy the frame properties of src to dst, without copying the actual
 * image data.
 *
 * @return 0 on success, a negative number on error.
 *)
  Tavfilter_copy_frame_propsProc = function(dst: PAVFilterBufferRef; const src: PAVFrame): Integer; cdecl;

(**
 * Copy the frame properties and data pointers of src to dst, without copying
 * the actual data.
 *
 * @return 0 on success, a negative number on error.
 *)
  Tavfilter_copy_buf_propsProc = function(dst: PAVFrame; const src: PAVFilterBufferRef): Integer; cdecl;
{$ENDIF}

(**
 * @return AVClass for AVFilterContext.
 *
 * @see av_opt_find().
 *)
  Tavfilter_get_classProc = function: PAVClass; cdecl;

  PAVFilterGraphInternal = ^TAVFilterGraphInternal;
  TAVFilterGraphInternal = record
    // need {$ALIGN 8}
  end;

(**
 * A function pointer passed to the @ref AVFilterGraph.execute callback to be
 * executed multiple times, possibly in parallel.
 *
 * @param ctx the filter context the job belongs to
 * @param arg an opaque parameter passed through from @ref
 *            AVFilterGraph.execute
 * @param jobnr the index of the job being executed
 * @param nb_jobs the total number of jobs
 *
 * @return 0 on success, a negative AVERROR on error
 *)
  Tavfilter_action_func = function(ctx: PAVFilterContext; arg: Pointer; jobnr, nb_jobs: Integer): Integer; cdecl;

(**
 * A function executing multiple jobs, possibly in parallel.
 *
 * @param ctx the filter context to which the jobs belong
 * @param func the function to be called multiple times
 * @param arg the argument to be passed to func
 * @param ret a nb_jobs-sized array to be filled with return values from each
 *            invocation of func
 * @param nb_jobs the number of jobs to execute
 *
 * @return 0 on success, a negative AVERROR on error
 *)
  Tavfilter_execute_func = function(ctx: PAVFilterContext; func: Tavfilter_action_func;
                                    arg: Pointer; ret: PInteger; nb_jobs: Integer): Integer; cdecl;

  TAVFilterGraph = record
    av_class: PAVClass;
{$IFDEF FF_API_FOO_COUNT}
    filter_count_unused: Cardinal;
{$ENDIF}
    filters: PPAVFilterContext;
{$IFNDEF FF_API_FOO_COUNT}
    nb_filters: Cardinal;
{$ENDIF}

    scale_sws_opts: PAnsiChar; ///< sws options to use for the auto-inserted scale filters
    resample_lavr_opts: PAnsiChar; ///< libavresample options to use for the auto-inserted resample filters
{$IFDEF FF_API_FOO_COUNT}
    nb_filters: Cardinal;
{$ENDIF}

    (**
     * Type of multithreading allowed for filters in this graph. A combination
     * of AVFILTER_THREAD_* flags.
     *
     * May be set by the caller at any point, the setting will apply to all
     * filters initialized after that. The default is allowing everything.
     *
     * When a filter in this graph is initialized, this field is combined using
     * bit AND with AVFilterContext.thread_type to get the final mask used for
     * determining allowed threading types. I.e. a threading type needs to be
     * set in both to be allowed.
     *)
    thread_type: Integer;

    (**
     * Maximum number of threads used by filters in this graph. May be set by
     * the caller before adding any filters to the filtergraph. Zero (the
     * default) means that the number of threads is determined automatically.
     *)
    nb_threads: Integer;

    (**
     * Opaque object for libavfilter internal use.
     *)
    internal: PAVFilterGraphInternal;

    (**
     * Opaque user data. May be set by the caller to an arbitrary value, e.g. to
     * be used from callbacks like @ref AVFilterGraph.execute.
     * Libavfilter will not touch this field in any way.
     *)
    opaque: Pointer;

    (**
     * This callback may be set by the caller immediately after allocating the
     * graph and before adding any filters to it, to provide a custom
     * multithreading implementation.
     *
     * If set, filters with slice threading capability will call this callback
     * to execute multiple jobs in parallel.
     *
     * If this field is left unset, libavfilter will use its internal
     * implementation, which may or may not be multithreaded depending on the
     * platform and build options.
     *)
    execute: Tavfilter_execute_func;

    aresample_swr_opts: PAnsiChar; ///< swr options to use for the auto-inserted aresample filters, Access ONLY through AVOptions

    (**
     * Private fields
     *
     * The following fields are for internal use only.
     * Their type, offset, number and semantic can change without notice.
     *)

    sink_links: PPAVFilterLink;
    sink_links_count: Integer;

    disable_auto_convert: Cardinal;
  end;

(**
 * Allocate a filter graph.
 *)
  Tavfilter_graph_allocProc = function: PAVFilterGraph; cdecl;

(**
 * Create a new filter instance in a filter graph.
 *
 * @param graph graph in which the new filter will be used
 * @param filter the filter to create an instance of
 * @param name Name to give to the new instance (will be copied to
 *             AVFilterContext.name). This may be used by the caller to identify
 *             different filters, libavfilter itself assigns no semantics to
 *             this parameter. May be NULL.
 *
 * @return the context of the newly created filter instance (note that it is
 *         also retrievable directly through AVFilterGraph.filters or with
 *         avfilter_graph_get_filter()) on success or NULL or failure.
 *)
  Tavfilter_graph_alloc_filterProc = function(graph: PAVFilterGraph;
                                              const filter: PAVFilter;
                                              const name: PAnsiChar): PAVFilterContext; cdecl;

(**
 * Get a filter instance with name name from graph.
 *
 * @return the pointer to the found filter instance or NULL if it
 * cannot be found.
 *)
  Tavfilter_graph_get_filterProc = function(graph: PAVFilterGraph; name: PAnsiChar): PAVFilterContext; cdecl;

{$IFDEF FF_API_AVFILTER_OPEN}
(**
 * Add an existing filter instance to a filter graph.
 *
 * @param graphctx  the filter graph
 * @param filter The filter to be added
 *
 * @deprecated use avfilter_graph_alloc_filter() to allocate a filter in a
 * filter graph
 *)
  Tavfilter_graph_add_filterProc = function(graphctx: PAVFilterGraph; filter: PAVFilterContext): Integer; cdecl;
{$ENDIF}

(**
 * Create and add a filter instance into an existing graph.
 * The filter instance is created from the filter filt and inited
 * with the parameters args and opaque.
 *
 * In case of success put in *filt_ctx the pointer to the created
 * filter instance, otherwise set *filt_ctx to NULL.
 *
 * @param name the instance name to give to the created filter instance
 * @param graph_ctx the filter graph
 * @return a negative AVERROR error code in case of failure, a non
 * negative value otherwise
 *)
  Tavfilter_graph_create_filterProc = function(filt_ctx: PPAVFilterContext; const filt: PAVFilter;
                                 const name: PAnsiChar; const args: PAnsiChar; opaque: Pointer;
                                 graph_ctx: PAVFilterGraph): Integer; cdecl;

(**
 * Enable or disable automatic format conversion inside the graph.
 *
 * Note that format conversion can still happen inside explicitly inserted
 * scale and aresample filters.
 *
 * @param flags  any of the AVFILTER_AUTO_CONVERT_* constants
 *)
  Tavfilter_graph_set_auto_convertProc = procedure(graph: PAVFilterGraph; flags: Integer); cdecl;

  TAVFilterConverter = (
    AVFILTER_AUTO_CONVERT_NONE = -1, (**< all automatic conversions disabled *)
    AVFILTER_AUTO_CONVERT_ALL  =  0  (**< all automatic conversions enabled *)
  );

(**
 * Check validity and configure all the links and formats in the graph.
 *
 * @param graphctx the filter graph
 * @param log_ctx context used for logging
 * @return >= 0 in case of success, a negative AVERROR code otherwise
 *)
  Tavfilter_graph_configProc = function(graphctx: PAVFilterGraph; log_ctx: Pointer): Integer; cdecl;

(**
 * Free a graph, destroy its links, and set *graph to NULL.
 * If *graph is NULL, do nothing.
 *)
  Tavfilter_graph_freeProc = procedure(graph: PPAVFilterGraph); cdecl;

(**
 * A linked-list of the inputs/outputs of the filter chain.
 *
 * This is mainly useful for avfilter_graph_parse() / avfilter_graph_parse2(),
 * where it is used to communicate open (unlinked) inputs and outputs from and
 * to the caller.
 * This struct specifies, per each not connected pad contained in the graph, the
 * filter context and the pad index required for establishing a link.
 *)
  PPAVFilterInOut = ^PAVFilterInOut;
  PAVFilterInOut = ^TAVFilterInOut;
  TAVFilterInOut = record
    (** unique name for this input/output in the list *)
    name: PAnsiChar;

    (** filter context associated to this input/output *)
    filter_ctx: PAVFilterContext;

    (** index of the filt_ctx pad to use for linking *)
    pad_idx: Integer;

    (** next input/input in the list, NULL if this is the last *)
    next: PAVFilterInOut;
  end;

(**
 * Allocate a single AVFilterInOut entry.
 * Must be freed with avfilter_inout_free().
 * @return allocated AVFilterInOut on success, NULL on failure.
 *)
  Tavfilter_inout_allocProc = function: PAVFilterInOut; cdecl;

(**
 * Free the supplied list of AVFilterInOut and set *inout to NULL.
 * If *inout is NULL, do nothing.
 *)
  Tavfilter_inout_freeProc = procedure(inout: PPAVFilterInOut); cdecl;

{$IF Defined(AV_HAVE_INCOMPATIBLE_LIBAV_ABI) Or Not Defined(FF_API_OLD_GRAPH_PARSE)}
(**
 * Add a graph described by a string to a graph.
 *
 * @note The caller must provide the lists of inputs and outputs,
 * which therefore must be known before calling the function.
 *
 * @note The inputs parameter describes inputs of the already existing
 * part of the graph; i.e. from the point of view of the newly created
 * part, they are outputs. Similarly the outputs parameter describes
 * outputs of the already existing filters, which are provided as
 * inputs to the parsed filters.
 *
 * @param graph   the filter graph where to link the parsed grap context
 * @param filters string to be parsed
 * @param inputs  linked list to the inputs of the graph
 * @param outputs linked list to the outputs of the graph
 * @return zero on success, a negative AVERROR code on error
 *)
  Tavfilter_graph_parseProc = function(graph: PAVFilterGraph; const filters: PAnsiChar;
                          inputs, outputs: PAVFilterInOut; log_ctx: Pointer): Integer; cdecl;
{$ELSE}
(**
 * Add a graph described by a string to a graph.
 *
 * @param graph   the filter graph where to link the parsed graph context
 * @param filters string to be parsed
 * @param inputs  pointer to a linked list to the inputs of the graph, may be NULL.
 *                If non-NULL, *inputs is updated to contain the list of open inputs
 *                after the parsing, should be freed with avfilter_inout_free().
 * @param outputs pointer to a linked list to the outputs of the graph, may be NULL.
 *                If non-NULL, *outputs is updated to contain the list of open outputs
 *                after the parsing, should be freed with avfilter_inout_free().
 * @return non negative on success, a negative AVERROR code on error
 * @deprecated Use avfilter_graph_parse_ptr() instead.
 *)
  Tavfilter_graph_parseProc = function(graph: PAVFilterGraph; const filters: PAnsiChar;
                         inputs: PPAVFilterInOut; outputs: PPAVFilterInOut;
                         log_ctx: Pointer): Integer; cdecl;
{$IFEND}

(**
 * Add a graph described by a string to a graph.
 *
 * @param graph   the filter graph where to link the parsed graph context
 * @param filters string to be parsed
 * @param inputs  pointer to a linked list to the inputs of the graph, may be NULL.
 *                If non-NULL, *inputs is updated to contain the list of open inputs
 *                after the parsing, should be freed with avfilter_inout_free().
 * @param outputs pointer to a linked list to the outputs of the graph, may be NULL.
 *                If non-NULL, *outputs is updated to contain the list of open outputs
 *                after the parsing, should be freed with avfilter_inout_free().
 * @return non negative on success, a negative AVERROR code on error
 *)
  Tavfilter_graph_parse_ptrProc = function(graph: PAVFilterGraph; const filters: PAnsiChar;
                              inputs, outputs: PPAVFilterInOut; log_ctx: Pointer): Integer; cdecl;

(**
 * Add a graph described by a string to a graph.
 *
 * @param[in]  graph   the filter graph where to link the parsed graph context
 * @param[in]  filters string to be parsed
 * @param[out] inputs  a linked list of all free (unlinked) inputs of the
 *                     parsed graph will be returned here. It is to be freed
 *                     by the caller using avfilter_inout_free().
 * @param[out] outputs a linked list of all free (unlinked) outputs of the
 *                     parsed graph will be returned here. It is to be freed by the
 *                     caller using avfilter_inout_free().
 * @return zero on success, a negative AVERROR code on error
 *
 * @note This function returns the inputs and outputs that are left
 * unlinked after parsing the graph and the caller then deals with
 * them.
 * @note This function makes no reference whatsoever to already
 * existing parts of the graph and the inputs parameter will on return
 * contain inputs of the newly parsed part of the graph.  Analogously
 * the outputs parameter will contain outputs of the newly created
 * filters.
 *)
  Tavfilter_graph_parse2Proc = function(graph: PAVFilterGraph; const filters: PAnsiChar;
                          inputs, outputs: PPAVFilterInOut): Integer; cdecl;

(**
 * Send a command to one or more filter instances.
 *
 * @param graph  the filter graph
 * @param target the filter(s) to which the command should be sent
 *               "all" sends to all filters
 *               otherwise it can be a filter or filter instance name
 *               which will send the command to all matching filters.
 * @param cmd    the command to send, for handling simplicity all commands must be alphanumeric only
 * @param arg    the argument for the command
 * @param res    a buffer with size res_size where the filter(s) can return a response.
 *
 * @returns >=0 on success otherwise an error code.
 *              AVERROR(ENOSYS) on unsupported commands
 *)
  Tavfilter_graph_send_commandProc = function(graph: PAVFilterGraph; const target, cmd, arg: PAnsiChar; res: PAnsiChar; res_len, flags: Integer): Integer; cdecl;

(**
 * Queue a command for one or more filter instances.
 *
 * @param graph  the filter graph
 * @param target the filter(s) to which the command should be sent
 *               "all" sends to all filters
 *               otherwise it can be a filter or filter instance name
 *               which will send the command to all matching filters.
 * @param cmd    the command to sent, for handling simplicity all commands must be alphanummeric only
 * @param arg    the argument for the command
 * @param ts     time at which the command should be sent to the filter
 *
 * @note As this executes commands after this function returns, no return code
 *       from the filter is provided, also AVFILTER_CMD_FLAG_ONE is not supported.
 *)
  Tavfilter_graph_queue_commandProc = function(graph: PAVFilterGraph; const target, cmd, arg: PAnsiChar; flags: Integer; ts: Double): Integer; cdecl;

(**
 * Dump a graph into a human-readable string representation.
 *
 * @param graph    the graph to dump
 * @param options  formatting options; currently ignored
 * @return  a string, or NULL in case of memory allocation failure;
 *          the string must be freed using av_free
 *)
  Tavfilter_graph_dumpProc = function(graph: PAVFilterGraph; const options: PAnsiChar): PAnsiChar; cdecl;

(**
 * Request a frame on the oldest sink link.
 *
 * If the request returns AVERROR_EOF, try the next.
 *
 * Note that this function is not meant to be the sole scheduling mechanism
 * of a filtergraph, only a convenience function to help drain a filtergraph
 * in a balanced way under normal circumstances.
 *
 * Also note that AVERROR_EOF does not mean that frames did not arrive on
 * some of the sinks during the process.
 * When there are multiple sink links, in case the requested link
 * returns an EOF, this may cause a filter to flush pending frames
 * which are sent to another sink link, although unrequested.
 *
 * @return  the return value of ff_request_frame(),
 *          or AVERROR_EOF if all links returned AVERROR_EOF
 *)
  Tavfilter_graph_request_oldestProc = function(graph: PAVFilterGraph): Integer; cdecl;

(**
 * @}
 *)

(****** TODO: check from libavfilter/avcodec.h **************)
{$IFDEF FF_API_AVFILTERBUFFER}
(**
 * Create and return a picref reference from the data and properties
 * contained in frame.
 *
 * @param perms permissions to assign to the new buffer reference
 * @deprecated avfilter APIs work natively with AVFrame instead.
 *)
  Tavfilter_get_video_buffer_ref_from_frameProc = function(const frame: PAVFrame; perms: Integer): PAVFilterBufferRef; cdecl;


(**
 * Create and return a picref reference from the data and properties
 * contained in frame.
 *
 * @param perms permissions to assign to the new buffer reference
 * @deprecated avfilter APIs work natively with AVFrame instead.
 *)
  Tavfilter_get_audio_buffer_ref_from_frameProc = function(const frame: PAVFrame;
                                                           perms: Integer): PAVFilterBufferRef; cdecl;

(**
 * Create and return a buffer reference from the data and properties
 * contained in frame.
 *
 * @param perms permissions to assign to the new buffer reference
 * @deprecated avfilter APIs work natively with AVFrame instead.
 *)
  Tavfilter_get_buffer_ref_from_frameProc = function(ttype: TAVMediaType;
                                                     const frame: PAVFrame;
                                                     perms: Integer): PAVFilterBufferRef; cdecl;
{$ENDIF}

{$IFDEF FF_API_FILL_FRAME}
(**
 * Fill an AVFrame with the information stored in samplesref.
 *
 * @param frame an already allocated AVFrame
 * @param samplesref an audio buffer reference
 * @return >= 0 in case of success, a negative AVERROR code in case of
 * failure
 * @deprecated Use avfilter_copy_buf_props() instead.
 *)
  Tavfilter_fill_frame_from_audio_buffer_refProc = function(frame: PAVFrame;
                                              const samplesref: PAVFilterBufferRef): Integer; cdecl;

(**
 * Fill an AVFrame with the information stored in picref.
 *
 * @param frame an already allocated AVFrame
 * @param picref a video buffer reference
 * @return >= 0 in case of success, a negative AVERROR code in case of
 * failure
 * @deprecated Use avfilter_copy_buf_props() instead.
 *)
  Tavfilter_fill_frame_from_video_buffer_refProc = function(frame: PAVFrame;
                                              const picref: PAVFilterBufferRef): Integer; cdecl;

(**
 * Fill an AVFrame with information stored in ref.
 *
 * @param frame an already allocated AVFrame
 * @param ref a video or audio buffer reference
 * @return >= 0 in case of success, a negative AVERROR code in case of
 * failure
 * @deprecated Use avfilter_copy_buf_props() instead.
 *)
  Tavfilter_fill_frame_from_buffer_refProc = function(frame: PAVFrame;
                                        const ref: PAVFilterBufferRef): Integer; cdecl;
{$ENDIF}

(****** TODO: check from libavfilter/buffersink.h **************)
(**
 * @file
 * memory buffer sink API for audio and video
 *)

{$IFDEF FF_API_AVFILTERBUFFER}
(**
 * Get an audio/video buffer data from buffer_sink and put it in bufref.
 *
 * This function works with both audio and video buffer sinks.
 *
 * @param buffer_sink pointer to a buffersink or abuffersink context
 * @param flags a combination of AV_BUFFERSINK_FLAG_* flags
 * @return >= 0 in case of success, a negative AVERROR code in case of
 * failure
 *)
  Tav_buffersink_get_buffer_refProc = function(buffer_sink: PAVFilterContext;
                                  bufref: PPAVFilterBufferRef; flags: Integer): Integer; cdecl;

(**
 * Get the number of immediately available frames.
 *)
  Tav_buffersink_poll_frameProc = function(ctx: PAVFilterContext): Integer; cdecl;

(**
 * Get a buffer with filtered data from sink and put it in buf.
 *
 * @param ctx pointer to a context of a buffersink or abuffersink AVFilter.
 * @param buf pointer to the buffer will be written here if buf is non-NULL. buf
 *            must be freed by the caller using avfilter_unref_buffer().
 *            Buf may also be NULL to query whether a buffer is ready to be
 *            output.
 *
 * @return >= 0 in case of success, a negative AVERROR code in case of
 *         failure.
 *)
  Tav_buffersink_readProc = function(ctx: PAVFilterContext; buf: PPAVFilterBufferRef): Integer; cdecl;

(**
 * Same as av_buffersink_read, but with the ability to specify the number of
 * samples read. This function is less efficient than av_buffersink_read(),
 * because it copies the data around.
 *
 * @param ctx pointer to a context of the abuffersink AVFilter.
 * @param buf pointer to the buffer will be written here if buf is non-NULL. buf
 *            must be freed by the caller using avfilter_unref_buffer(). buf
 *            will contain exactly nb_samples audio samples, except at the end
 *            of stream, when it can contain less than nb_samples.
 *            Buf may also be NULL to query whether a buffer is ready to be
 *            output.
 *
 * @warning do not mix this function with av_buffersink_read(). Use only one or
 * the other with a single sink, not both.
 *)
  Tav_buffersink_read_samplesProc = function(ctx: PAVFilterContext; buf: PPAVFilterBufferRef;
                               nb_samples: Integer): Integer; cdecl;
{$ENDIF}

(**
 * Get a frame with filtered data from sink and put it in frame.
 *
 * @param ctx    pointer to a buffersink or abuffersink filter context.
 * @param frame  pointer to an allocated frame that will be filled with data.
 *               The data must be freed using av_frame_unref() / av_frame_free()
 * @param flags  a combination of AV_BUFFERSINK_FLAG_* flags
 *
 * @return  >= 0 in for success, a negative AVERROR code for failure.
 *)
  Tav_buffersink_get_frame_flagsProc = function(ctx: PAVFilterContext; frame: PAVFrame; flags: Integer): Integer; cdecl;

(**
 * Tell av_buffersink_get_buffer_ref() to read video/samples buffer
 * reference, but not remove it from the buffer. This is useful if you
 * need only to read a video/samples buffer, without to fetch it.
 *)
//const
//  AV_BUFFERSINK_FLAG_PEEK = 1;

(**
 * Tell av_buffersink_get_buffer_ref() not to request a frame from its input.
 * If a frame is already buffered, it is read (and removed from the buffer),
 * but if no frame is present, return AVERROR(EAGAIN).
 *)
//  AV_BUFFERSINK_FLAG_NO_REQUEST = 2;

(**
 * Struct to use for initializing a buffersink context.
 *)
  PAVBufferSinkParams = ^TAVBufferSinkParams;
  TAVBufferSinkParams = record
    pixel_fmts: PAVPixelFormat; ///< list of allowed pixel formats, terminated by AV_PIX_FMT_NONE
  end;

(**
 * Create an AVBufferSinkParams structure.
 *
 * Must be freed with av_free().
 *)
  Tav_buffersink_params_allocProc = function: PAVBufferSinkParams; cdecl;

(**
 * Struct to use for initializing an abuffersink context.
 *)
  PAVABufferSinkParams = ^TAVABufferSinkParams;
  TAVABufferSinkParams = record
    sample_fmts: PAVSampleFormat; ///< list of allowed sample formats, terminated by AV_SAMPLE_FMT_NONE
    channel_layouts: PInt64;      ///< list of allowed channel layouts, terminated by -1
    channel_counts: PInteger;     ///< list of allowed channel counts, terminated by -1
    all_channel_counts: Integer;  ///< if not 0, accept any channel count or layout
    sample_rates: PInteger;       ///< list of allowed sample rates, terminated by -1
  end;

(**
 * Create an AVABufferSinkParams structure.
 *
 * Must be freed with av_free().
 *)
  Tav_abuffersink_params_allocProc = function: PAVABufferSinkParams; cdecl;

(**
 * Set the frame size for an audio buffer sink.
 *
 * All calls to av_buffersink_get_buffer_ref will return a buffer with
 * exactly the specified number of samples, or AVERROR(EAGAIN) if there is
 * not enough. The last buffer at EOF will be padded with 0.
 *)
  Tav_buffersink_set_frame_sizeProc = procedure(ctx: PAVFilterContext; frame_size: Cardinal); cdecl;

(**
 * Get the frame rate of the input.
 *)
//TODO: API returen record  Tav_buffersink_get_frame_rateProc = function(ctx: PAVFilterContext): TAVRational; cdecl;

(**
 * Get a frame with filtered data from sink and put it in frame.
 *
 * @param ctx pointer to a context of a buffersink or abuffersink AVFilter.
 * @param frame pointer to an allocated frame that will be filled with data.
 *              The data must be freed using av_frame_unref() / av_frame_free()
 *
 * @return >= 0 in case of success, a negative AVERROR code in case of
 *         failure.
 *)
  Tav_buffersink_get_frameProc = function(ctx: PAVFilterContext; frame: PAVFrame): Integer; cdecl;

(**
 * Same as av_buffersink_get_frame(), but with the ability to specify the number
 * of samples read. This function is less efficient than
 * av_buffersink_get_frame(), because it copies the data around.
 *
 * @param ctx pointer to a context of the abuffersink AVFilter.
 * @param frame pointer to an allocated frame that will be filled with data.
 *              The data must be freed using av_frame_unref() / av_frame_free()
 *              frame will contain exactly nb_samples audio samples, except at
 *              the end of stream, when it can contain less than nb_samples.
 *
 * @warning do not mix this function with av_buffersink_get_frame(). Use only one or
 * the other with a single sink, not both.
 *)
  Tav_buffersink_get_samplesProc = function(ctx: PAVFilterContext; frame: PAVFrame; nb_samples: Integer): Integer; cdecl;


(****** TODO: check from libavfilter/buffersrc.h **************)
(*
    /**
     * Do not check for format changes.
     */
    AV_BUFFERSRC_FLAG_NO_CHECK_FORMAT = 1,

#if FF_API_AVFILTERBUFFER
    /**
     * Ignored
     */
    AV_BUFFERSRC_FLAG_NO_COPY = 2,
#endif

    /**
     * Immediately push the frame to the output.
     */
    AV_BUFFERSRC_FLAG_PUSH = 4,

    /**
     * Keep a reference to the frame.
     * If the frame if reference-counted, create a new reference; otherwise
     * copy the frame data.
     */
    AV_BUFFERSRC_FLAG_KEEP_REF = 8,
*)

(**
 * Add buffer data in picref to buffer_src.
 *
 * @param buffer_src  pointer to a buffer source context
 * @param picref      a buffer reference, or NULL to mark EOF
 * @param flags       a combination of AV_BUFFERSRC_FLAG_*
 * @return            >= 0 in case of success, a negative AVERROR code
 *                    in case of failure
 *)
  Tav_buffersrc_add_refProc = function(buffer_src: PAVFilterContext;
                         picref: PAVFilterBufferRef; flags: Integer): Integer; cdecl;

(**
 * Get the number of failed requests.
 *
 * A failed request is when the request_frame method is called while no
 * frame is present in the buffer.
 * The number is reset when a frame is added.
 *)
  Tav_buffersrc_get_nb_failed_requestsProc = function(buffer_src: PAVFilterContext): Cardinal; cdecl;

{$IFDEF FF_API_AVFILTERBUFFER}
(**
 * Add a buffer to the filtergraph s.
 *
 * @param buf buffer containing frame data to be passed down the filtergraph.
 * This function will take ownership of buf, the user must not free it.
 * A NULL buf signals EOF -- i.e. no more frames will be sent to this filter.
 *
 * @deprecated use av_buffersrc_write_frame() or av_buffersrc_add_frame()
 *)
  Tav_buffersrc_bufferProc = function(s: PAVFilterContext; buf: PAVFilterBufferRef): Integer; cdecl;
{$ENDIF}

(**
 * Add a frame to the buffer source.
 *
 * @param s an instance of the buffersrc filter.
 * @param frame frame to be added. If the frame is reference counted, this
 * function will make a new reference to it. Otherwise the frame data will be
 * copied.
 *
 * @return 0 on success, a negative AVERROR on error
 *
 * This function is equivalent to av_buffersrc_add_frame_flags() with the
 * AV_BUFFERSRC_FLAG_KEEP_REF flag.
 *)
  Tav_buffersrc_write_frameProc = function(s: PAVFilterContext; const frame: PAVFrame): Integer; cdecl;

(**
 * Add a frame to the buffer source.
 *
 * @param s an instance of the buffersrc filter.
 * @param frame frame to be added. If the frame is reference counted, this
 * function will take ownership of the reference(s) and reset the frame.
 * Otherwise the frame data will be copied. If this function returns an error,
 * the input frame is not touched.
 *
 * @return 0 on success, a negative AVERROR on error.
 *
 * @note the difference between this function and av_buffersrc_write_frame() is
 * that av_buffersrc_write_frame() creates a new reference to the input frame,
 * while this function takes ownership of the reference passed to it.
 *
 * This function is equivalent to av_buffersrc_add_frame_flags() without the
 * AV_BUFFERSRC_FLAG_KEEP_REF flag.
 *)
  Tav_buffersrc_add_frameProc = function(ctx: PAVFilterContext; frame: PAVFrame): Integer; cdecl;

(**
 * Add a frame to the buffer source.
 *
 * By default, if the frame is reference-counted, this function will take
 * ownership of the reference(s) and reset the frame. This can be controled
 * using the flags.
 *
 * If this function returns an error, the input frame is not touched.
 *
 * @param buffer_src  pointer to a buffer source context
 * @param frame       a frame, or NULL to mark EOF
 * @param flags       a combination of AV_BUFFERSRC_FLAG_*
 * @return            >= 0 in case of success, a negative AVERROR code
 *                    in case of failure
 *)
  Tav_buffersrc_add_frame_flagsProc = function(buffer_src: PAVFilterContext;
                                  frame: PAVFrame; flags: Integer): Integer; cdecl;


(****** TODO: check from libavfilter/formats.h **************)

(**
 * A list of supported formats for one end of a filter link. This is used
 * during the format negotiation process to try to pick the best format to
 * use to minimize the number of necessary conversions. Each filter gives a
 * list of the formats supported by each input and output pad. The list
 * given for each pad need not be distinct - they may be references to the
 * same list of formats, as is often the case when a filter supports multiple
 * formats, but will always output the same format as it is given in input.
 *
 * In this way, a list of possible input formats and a list of possible
 * output formats are associated with each link. When a set of formats is
 * negotiated over a link, the input and output lists are merged to form a
 * new list containing only the common elements of each list. In the case
 * that there were no common elements, a format conversion is necessary.
 * Otherwise, the lists are merged, and all other links which reference
 * either of the format lists involved in the merge are also affected.
 *
 * For example, consider the filter chain:
 * filter (a) --> (b) filter (b) --> (c) filter
 *
 * where the letters in parenthesis indicate a list of formats supported on
 * the input or output of the link. Suppose the lists are as follows:
 * (a) = {A, B}
 * (b) = {A, B, C}
 * (c) = {B, C}
 *
 * First, the first link's lists are merged, yielding:
 * filter (a) --> (a) filter (a) --> (c) filter
 *
 * Notice that format list (b) now refers to the same list as filter list (a).
 * Next, the lists for the second link are merged, yielding:
 * filter (a) --> (a) filter (a) --> (a) filter
 *
 * where (a) = {B}.
 *
 * Unfortunately, when the format lists at the two ends of a link are merged,
 * we must ensure that all links which reference either pre-merge format list
 * get updated as well. Therefore, we have the format list structure store a
 * pointer to each of the pointers to itself.
 *)
  TAVFilterFormats = record
    nb_formats: Cardinal;         ///< number of formats
    formats: PInteger;            ///< list of media formats

    refcount: Cardinal;           ///< number of references to this list
    refs: PPPAVFilterFormats;     ///< references to this list
  end;

  TAVFilterChannelLayouts = record
    channel_layouts: PInt64;          ///< list of channel layouts
    nb_channel_layouts: Integer;      ///< number of channel layouts

    refcount: Cardinal;               ///< number of references to this list
    refs: PPPAVFilterChannelLayouts;  ///< references to this list
  end;

(**
 * Return a channel layouts/samplerates list which contains the intersection of
 * the layouts/samplerates of a and b. Also, all the references of a, all the
 * references of b, and a and b themselves will be deallocated.
 *
 * If a and b do not share any common elements, neither is modified, and NULL
 * is returned.
 *)
  Tff_merge_channel_layoutsProc = function(a, b: PAVFilterChannelLayouts): PAVFilterChannelLayouts; cdecl;
  Tff_merge_sampleratesProc = function(a, b: PAVFilterFormats): PAVFilterFormats; cdecl;

(**
 * Construct an empty AVFilterChannelLayouts/AVFilterFormats struct --
 * representing any channel layout/sample rate.
 *)
  Tff_all_channel_layoutsProc = function: PAVFilterChannelLayouts; cdecl;
  Tff_all_sampleratesProc = function: PAVFilterFormats; cdecl;

  Tavfilter_make_format64_listProc = function(const fmts: PInt64): PAVFilterChannelLayouts; cdecl;


(**
 * A helper for query_formats() which sets all links to the same list of channel
 * layouts/sample rates. If there are no links hooked to this filter, the list
 * is freed.
 *)
  Tff_set_common_channel_layoutsProc = procedure(ctx: PAVFilterContext;
                                   layouts: PAVFilterChannelLayouts); cdecl;
  Tff_set_common_sampleratesProc = procedure(ctx: PAVFilterContext;
                               samplerates: PAVFilterFormats); cdecl;

(**
 * A helper for query_formats() which sets all links to the same list of
 * formats. If there are no links hooked to this filter, the list of formats is
 * freed.
 *)
  Tff_set_common_formatsProc = procedure(ctx: PAVFilterContext; formats: PAVFilterFormats); cdecl;

  Tff_add_channel_layoutProc = function(l: PPAVFilterChannelLayouts; channel_layout: Int64): Integer; cdecl;

(**
 * Add *ref as a new reference to f.
 *)
  Tff_channel_layouts_refProc = procedure(f: PAVFilterChannelLayouts;
                            ref: PPAVFilterChannelLayouts); cdecl;

(**
 * Remove a reference to a channel layouts list.
 *)
  Tff_channel_layouts_unrefProc = procedure(ref: PPAVFilterChannelLayouts); cdecl;

  Tff_channel_layouts_changerefProc = procedure(oldref, newref: PPAVFilterChannelLayouts); cdecl;

  Tff_default_query_formatsProc = function(ctx: PAVFilterContext): Integer; cdecl;


(**
 * Create a list of supported formats. This is intended for use in
 * AVFilter->query_formats().
 *
 * @param fmts list of media formats, terminated by -1
 * @return the format list, with no existing references
 *)
  Tff_make_format_listProc = function(const fmts: PInteger): PAVFilterFormats; cdecl;

(**
 * Add fmt to the list of media formats contained in *avff.
 * If *avff is NULL the function allocates the filter formats struct
 * and puts its pointer in *avff.
 *
 * @return a non negative value in case of success, or a negative
 * value corresponding to an AVERROR code in case of error
 *)
  Tff_add_formatProc = function(avff: PPAVFilterFormats; fmt: Int64): Integer; cdecl;

(**
 * Return a list of all formats supported by FFmpeg for the given media type.
 *)
  Tff_all_formatsProc = function(ttype: TAVMediaType): PAVFilterFormats; cdecl;

(**
 * Construct a formats list containing all planar sample formats.
 *)
  Tff_planar_sample_fmtsProc = function: PAVFilterFormats; cdecl;

(**
 * Return a format list which contains the intersection of the formats of
 * a and b. Also, all the references of a, all the references of b, and
 * a and b themselves will be deallocated.
 *
 * If a and b do not share any common formats, neither is modified, and NULL
 * is returned.
 *)
  Tff_merge_formatsProc = function(a, b: PAVFilterFormats): PAVFilterFormats; cdecl;

(**
 * Add *ref as a new reference to formats.
 * That is the pointers will point like in the ascii art below:
 *   ________
 *  |formats |<--------.
 *  |  ____  |     ____|___________________
 *  | |refs| |    |  __|_
 *  | |* * | |    | |  | |  AVFilterLink
 *  | |* *--------->|*ref|
 *  | |____| |    | |____|
 *  |________|    |________________________
 *)
  Tff_formats_refProc = procedure(formats: PAVFilterFormats; ref: PPAVFilterFormats); cdecl;

(**
 * If *ref is non-NULL, remove *ref as a reference to the format list
 * it currently points to, deallocates that list if this was the last
 * reference, and sets *ref to NULL.
 *
 *         Before                                 After
 *   ________                               ________         NULL
 *  |formats |<--------.                   |formats |         ^
 *  |  ____  |     ____|________________   |  ____  |     ____|________________
 *  | |refs| |    |  __|_                  | |refs| |    |  __|_
 *  | |* * | |    | |  | |  AVFilterLink   | |* * | |    | |  | |  AVFilterLink
 *  | |* *--------->|*ref|                 | |*   | |    | |*ref|
 *  | |____| |    | |____|                 | |____| |    | |____|
 *  |________|    |_____________________   |________|    |_____________________
 *)
  Tff_formats_unrefProc = procedure(ref: PPAVFilterFormats); cdecl;

(**
 *
 *         Before                                 After
 *   ________                         ________
 *  |formats |<---------.            |formats |<---------.
 *  |  ____  |       ___|___         |  ____  |       ___|___
 *  | |refs| |      |   |   |        | |refs| |      |   |   |   NULL
 *  | |* *--------->|*oldref|        | |* *--------->|*newref|     ^
 *  | |* * | |      |_______|        | |* * | |      |_______|  ___|___
 *  | |____| |                       | |____| |                |   |   |
 *  |________|                       |________|                |*oldref|
 *                                                             |_______|
 *)
  Tff_formats_changerefProc = procedure(oldref, newref: PPAVFilterFormats); cdecl;

(****** TODO: check from libavfilter/video.h **************)

(**
 * Request a picture buffer with a specific set of permissions.
 *
 * @param link  the output link to the filter from which the buffer will
 *              be requested
 * @param w     the minimum width of the buffer to allocate
 * @param h     the minimum height of the buffer to allocate
 * @return      A reference to the buffer. This must be unreferenced with
 *              avfilter_unref_buffer when you are finished with it.
 *)
  Tff_get_video_bufferProc = function(link: PAVFilterLink; w, h: Integer): PAVFrame; cdecl;

(****** TODO: check from libavfilter/internal.h **************)

(**
 * Send a frame of data to the next filter.
 *
 * @param link   the output link over which the data is being sent
 * @param frame a reference to the buffer of data being sent. The
 *              receiving filter will free this reference when it no longer
 *              needs it or pass it on to the next filter.
 *
 * @return >= 0 on success, a negative AVERROR on error. The receiving filter
 * is responsible for unreferencing frame in case of error.
 *)
  Tff_filter_frameProc = function(link: PAVFilterLink; frame: PAVFrame): Integer; cdecl;

implementation

end.
