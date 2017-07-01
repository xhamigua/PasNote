(*
 * copyright (c) 2001 Fabrice Bellard
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
 * Original file: libavformat/avformat.h
 * Ported by CodeCoolie@CNSW 2008/03/19 -> $Date:: 2013-11-18 #$
 *)

unit libavformat;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF BCB}
  BCBTypes,
{$ENDIF}
  libavcodec,
  libavformat_avio,
  libavutil,
  libavutil_dict,
  libavutil_frame,
  libavutil_log,
  libavutil_pixfmt,
  libavutil_rational;

{$I libversion.inc}

(**
 * @file
 * @ingroup libavf
 * Main libavformat public API header
 *)

(**
 * @defgroup libavf I/O and Muxing/Demuxing Library
 * @{
 *
 * Libavformat (lavf) is a library for dealing with various media container
 * formats. Its main two purposes are demuxing - i.e. splitting a media file
 * into component streams, and the reverse process of muxing - writing supplied
 * data in a specified container format. It also has an @ref lavf_io
 * "I/O module" which supports a number of protocols for accessing the data (e.g.
 * file, tcp, http and others). Before using lavf, you need to call
 * av_register_all() to register all compiled muxers, demuxers and protocols.
 * Unless you are absolutely sure you won't use libavformat's network
 * capabilities, you should also call avformat_network_init().
 *
 * A supported input format is described by an AVInputFormat struct, conversely
 * an output format is described by AVOutputFormat. You can iterate over all
 * registered input/output formats using the av_iformat_next() /
 * av_oformat_next() functions. The protocols layer is not part of the public
 * API, so you can only get the names of supported protocols with the
 * avio_enum_protocols() function.
 *
 * Main lavf structure used for both muxing and demuxing is AVFormatContext,
 * which exports all information about the file being read or written. As with
 * most Libavformat structures, its size is not part of public ABI, so it cannot be
 * allocated on stack or directly with av_malloc(). To create an
 * AVFormatContext, use avformat_alloc_context() (some functions, like
 * avformat_open_input() might do that for you).
 *
 * Most importantly an AVFormatContext contains:
 * @li the @ref AVFormatContext.iformat "input" or @ref AVFormatContext.oformat
 * "output" format. It is either autodetected or set by user for input;
 * always set by user for output.
 * @li an @ref AVFormatContext.streams "array" of AVStreams, which describe all
 * elementary streams stored in the file. AVStreams are typically referred to
 * using their index in this array.
 * @li an @ref AVFormatContext.pb "I/O context". It is either opened by lavf or
 * set by user for input, always set by user for output (unless you are dealing
 * with an AVFMT_NOFILE format).
 *
 * @section lavf_options Passing options to (de)muxers
 * Lavf allows to configure muxers and demuxers using the @ref avoptions
 * mechanism. Generic (format-independent) libavformat options are provided by
 * AVFormatContext, they can be examined from a user program by calling
 * av_opt_next() / av_opt_find() on an allocated AVFormatContext (or its AVClass
 * from avformat_get_class()). Private (format-specific) options are provided by
 * AVFormatContext.priv_data if and only if AVInputFormat.priv_class /
 * AVOutputFormat.priv_class of the corresponding format struct is non-NULL.
 * Further options may be provided by the @ref AVFormatContext.pb "I/O context",
 * if its AVClass is non-NULL, and the protocols layer. See the discussion on
 * nesting in @ref avoptions documentation to learn how to access those.
 *
 * @defgroup lavf_decoding Demuxing
 * @{
 * Demuxers read a media file and split it into chunks of data (@em packets). A
 * @ref AVPacket "packet" contains one or more encoded frames which belongs to a
 * single elementary stream. In the lavf API this process is represented by the
 * avformat_open_input() function for opening a file, av_read_frame() for
 * reading a single packet and finally avformat_close_input(), which does the
 * cleanup.
 *
 * @section lavf_decoding_open Opening a media file
 * The minimum information required to open a file is its URL or filename, which
 * is passed to avformat_open_input(), as in the following code:
 * @code
 * const char    *url = "in.mp3";
 * AVFormatContext *s = NULL;
 * int ret = avformat_open_input(&s, url, NULL, NULL);
 * if (ret < 0)
 *     abort();
 * @endcode
 * The above code attempts to allocate an AVFormatContext, open the
 * specified file (autodetecting the format) and read the header, exporting the
 * information stored there into s. Some formats do not have a header or do not
 * store enough information there, so it is recommended that you call the
 * avformat_find_stream_info() function which tries to read and decode a few
 * frames to find missing information.
 *
 * In some cases you might want to preallocate an AVFormatContext yourself with
 * avformat_alloc_context() and do some tweaking on it before passing it to
 * avformat_open_input(). One such case is when you want to use custom functions
 * for reading input data instead of lavf internal I/O layer.
 * To do that, create your own AVIOContext with avio_alloc_context(), passing
 * your reading callbacks to it. Then set the @em pb field of your
 * AVFormatContext to newly created AVIOContext.
 *
 * Since the format of the opened file is in general not known until after
 * avformat_open_input() has returned, it is not possible to set demuxer private
 * options on a preallocated context. Instead, the options should be passed to
 * avformat_open_input() wrapped in an AVDictionary:
 * @code
 * AVDictionary *options = NULL;
 * av_dict_set(&options, "video_size", "640x480", 0);
 * av_dict_set(&options, "pixel_format", "rgb24", 0);
 *
 * if (avformat_open_input(&s, url, NULL, &options) < 0)
 *     abort();
 * av_dict_free(&options);
 * @endcode
 * This code passes the private options 'video_size' and 'pixel_format' to the
 * demuxer. They would be necessary for e.g. the rawvideo demuxer, since it
 * cannot know how to interpret raw video data otherwise. If the format turns
 * out to be something different than raw video, those options will not be
 * recognized by the demuxer and therefore will not be applied. Such unrecognized
 * options are then returned in the options dictionary (recognized options are
 * consumed). The calling program can handle such unrecognized options as it
 * wishes, e.g.
 * @code
 * AVDictionaryEntry *e;
 * if (e = av_dict_get(options, "", NULL, AV_DICT_IGNORE_SUFFIX)) {
 *     fprintf(stderr, "Option %s not recognized by the demuxer.\n", e->key);
 *     abort();
 * }
 * @endcode
 *
 * After you have finished reading the file, you must close it with
 * avformat_close_input(). It will free everything associated with the file.
 *
 * @section lavf_decoding_read Reading from an opened file
 * Reading data from an opened AVFormatContext is done by repeatedly calling
 * av_read_frame() on it. Each call, if successful, will return an AVPacket
 * containing encoded data for one AVStream, identified by
 * AVPacket.stream_index. This packet may be passed straight into the libavcodec
 * decoding functions avcodec_decode_video2(), avcodec_decode_audio4() or
 * avcodec_decode_subtitle2() if the caller wishes to decode the data.
 *
 * AVPacket.pts, AVPacket.dts and AVPacket.duration timing information will be
 * set if known. They may also be unset (i.e. AV_NOPTS_VALUE for
 * pts/dts, 0 for duration) if the stream does not provide them. The timing
 * information will be in AVStream.time_base units, i.e. it has to be
 * multiplied by the timebase to convert them to seconds.
 *
 * If AVPacket.buf is set on the returned packet, then the packet is
 * allocated dynamically and the user may keep it indefinitely.
 * Otherwise, if AVPacket.buf is NULL, the packet data is backed by a
 * static storage somewhere inside the demuxer and the packet is only valid
 * until the next av_read_frame() call or closing the file. If the caller
 * requires a longer lifetime, av_dup_packet() will make an av_malloc()ed copy
 * of it.
 * In both cases, the packet must be freed with av_free_packet() when it is no
 * longer needed.
 *
 * @section lavf_decoding_seek Seeking
 * @}
 *
 * @defgroup lavf_encoding Muxing
 * @{
 * @}
 *
 * @defgroup lavf_io I/O Read/Write
 * @{
 * @}
 *
 * @defgroup lavf_codec Demuxers
 * @{
 * @defgroup lavf_codec_native Native Demuxers
 * @{
 * @}
 * @defgroup lavf_codec_wrappers External library wrappers
 * @{
 * @}
 * @}
 * @defgroup lavf_protos I/O Protocols
 * @{
 * @}
 * @defgroup lavf_internal Internal
 * @{
 * @}
 * @}
 *
 *)

const
/// Demuxer will use avio_open, no opened file should be provided by the caller.
  AVFMT_NOFILE        = $0001;
  AVFMT_NEEDNUMBER    = $0002; (**< Needs '%d' in filename. *)
  AVFMT_SHOW_IDS      = $0008; (**< Show format stream IDs numbers. *)
  AVFMT_RAWPICTURE    = $0020; (**< Format wants AVPicture structure for
                                      raw picture data. *)
  AVFMT_GLOBALHEADER  = $0040; (**< Format wants global header. *)
  AVFMT_NOTIMESTAMPS  = $0080; (**< Format does not need / have any timestamps. *)
  AVFMT_GENERIC_INDEX = $0100; (**< Use generic index building code. *)
  AVFMT_TS_DISCONT    = $0200; (**< Format allows timestamp discontinuities. Note, muxers always require valid (monotone) timestamps *)
  AVFMT_VARIABLE_FPS  = $0400; (**< Format allows variable fps. *)
  AVFMT_NODIMENSIONS  = $0800; (**< Format does not need width/height *)
  AVFMT_NOSTREAMS     = $1000; (**< Format does not require any streams *)
  AVFMT_NOBINSEARCH   = $2000; (**< Format does not allow to fall back on binary search via read_timestamp *)
  AVFMT_NOGENSEARCH   = $4000; (**< Format does not allow to fall back on generic search *)
  AVFMT_NO_BYTE_SEEK  = $8000; (**< Format does not allow seeking by bytes *)
  AVFMT_ALLOW_FLUSH   = $10000; (**< Format allows flushing. If not set, the muxer will not receive a NULL packet in the write_packet function. *)
{$IF LIBAVFORMAT_VERSION_MAJOR <= 54}
  AVFMT_TS_NONSTRICT  = $8020000; //we try to be compatible to the ABIs of ffmpeg and major forks
{$ELSE}
  AVFMT_TS_NONSTRICT  = $20000;
{$IFEND}
                                  (**< Format does not require strictly
                                        increasing timestamps, but they must
                                        still be monotonic *)
  AVFMT_TS_NEGATIVE   = $40000; (**< Format allows muxing negative
                                        timestamps. If not set the timestamp
                                        will be shifted in av_write_frame and
                                        av_interleaved_write_frame so they
                                        start from 0.
                                        The user or muxer can override this through
                                        AVFormatContext.avoid_negative_ts
                                        *)

  AVFMT_SEEK_TO_PTS   = $4000000; (**< Seeking is based on PTS *)

  AVPROBE_SCORE_RETRY     = 25;   // (AVPROBE_SCORE_MAX/4);
  AVPROBE_SCORE_EXTENSION = 50;   ///< score for file extension
  AVPROBE_SCORE_MAX       = 100;  ///< maximum score

  AVPROBE_PADDING_SIZE = 32;      ///< extra allocated bytes at the end of the probe buffer

  AVINDEX_KEYFRAME     = $0001;

  AV_DISPOSITION_DEFAULT   = $0001;
  AV_DISPOSITION_DUB       = $0002;
  AV_DISPOSITION_ORIGINAL  = $0004;
  AV_DISPOSITION_COMMENT   = $0008;
  AV_DISPOSITION_LYRICS    = $0010;
  AV_DISPOSITION_KARAOKE   = $0020;
(**
 * Track should be used during playback by default.
 * Useful for subtitle track that should be displayed
 * even when user did not explicitly ask for subtitles.
 *)
  AV_DISPOSITION_FORCED    = $0040;
  AV_DISPOSITION_HEARING_IMPAIRED = $0080;  (**< stream for hearing impaired audiences *)
  AV_DISPOSITION_VISUAL_IMPAIRED  = $0100;  (**< stream for visual impaired audiences *)
  AV_DISPOSITION_CLEAN_EFFECTS    = $0200;  (**< stream without voice *)
(**
 * The stream is stored in the file as an attached picture/"cover art" (e.g.
 * APIC frame in ID3v2). The single packet associated with it will be returned
 * among the first few packets read from the file unless seeking takes place.
 * It can also be accessed at any time in AVStream.attached_pic.
 *)
  AV_DISPOSITION_ATTACHED_PIC     = $0400;

(**
 * To specify text track kind (different from subtitles default).
 *)
  AV_DISPOSITION_CAPTIONS     = $10000;
  AV_DISPOSITION_DESCRIPTIONS = $20000;
  AV_DISPOSITION_METADATA     = $40000;

(**
 * Options for behavior on timestamp wrap detection.
 *)
  AV_PTS_WRAP_IGNORE      = 0;   ///< ignore the wrap
  AV_PTS_WRAP_ADD_OFFSET  = 1;   ///< add the format specific offset on wrap detection
  AV_PTS_WRAP_SUB_OFFSET  = -1;  ///< subtract the format specific offset on wrap detection

  MAX_REORDER_DELAY  = 16;
  MAX_PROBE_PACKETS  = 2500;
  AV_PROGRAM_RUNNING = 1;
  AVFMTCTX_NOHEADER  = $0001; (**< signal that no header is present
                                   (streams are added dynamically) *)

// const for TAVFormatContext.flags;
  AVFMT_FLAG_GENPTS       = $0001; ///< Generate missing pts even if it requires parsing future frames.
  AVFMT_FLAG_IGNIDX       = $0002; ///< Ignore index.
  AVFMT_FLAG_NONBLOCK     = $0004; ///< Do not block when reading packets from input.
  AVFMT_FLAG_IGNDTS       = $0008; ///< Ignore DTS on frames that contain both DTS & PTS
  AVFMT_FLAG_NOFILLIN     = $0010; ///< Do not infer any values from other values, just return what is stored in the container
  AVFMT_FLAG_NOPARSE      = $0020; ///< Do not use AVParsers, you also must set AVFMT_FLAG_NOFILLIN as the fillin code works on frames and no parsing -> no frames. Also seeking to frames can not work if parsing to find frame boundaries has been disabled
  AVFMT_FLAG_NOBUFFER     = $0040; ///< Do not buffer frames when possible
  AVFMT_FLAG_CUSTOM_IO    = $0080; ///< The caller has supplied a custom AVIOContext, don't avio_close() it.
  AVFMT_FLAG_DISCARD_CORRUPT = $0100; ///< Discard frames marked corrupted
  AVFMT_FLAG_FLUSH_PACKETS   = $0200; ///< Flush the AVIOContext every packet.
  AVFMT_FLAG_MP4A_LATM    = $8000; ///< Enable RTP MP4A-LATM payload
  AVFMT_FLAG_SORT_DTS     = $10000; ///< try to interleave outputted packets by dts (using this flag can slow demuxing down)
  AVFMT_FLAG_PRIV_OPT     = $20000; ///< Enable use of private options by delaying codec open (this could be made default once all code is converted)
  AVFMT_FLAG_KEEP_SIDE_DATA = $40000; ///< Dont merge side data but keep it seperate.

  FF_FDEBUG_TS            = $0001;
  RAW_PACKET_BUFFER_SIZE  = 2500000;

  AVSEEK_FLAG_BACKWARD = 1; ///< seek backward
  AVSEEK_FLAG_BYTE     = 2; ///< seeking based on position in bytes
  AVSEEK_FLAG_ANY      = 4; ///< seek to any frame, even non key-frames
  AVSEEK_FLAG_FRAME    = 8; ///< seeking based on frame number

(**
 * @defgroup metadata_api Public Metadata API
 * @{
 * @ingroup libavf
 * The metadata API allows libavformat to export metadata tags to a client
 * application when demuxing. Conversely it allows a client application to
 * set metadata when muxing.
 *
 * Metadata is exported or set as pairs of key/value strings in the 'metadata'
 * fields of the AVFormatContext, AVStream, AVChapter and AVProgram structs
 * using the @ref lavu_dict "AVDictionary" API. Like all strings in FFmpeg,
 * metadata is assumed to be UTF-8 encoded Unicode. Note that metadata
 * exported by demuxers isn't checked to be valid UTF-8 in most cases.
 *
 * Important concepts to keep in mind:
 * -  Keys are unique; there can never be 2 tags with the same key. This is
 *    also meant semantically, i.e., a demuxer should not knowingly produce
 *    several keys that are literally different but semantically identical.
 *    E.g., key=Author5, key=Author6. In this example, all authors must be
 *    placed in the same tag.
 * -  Metadata is flat, not hierarchical; there are no subtags. If you
 *    want to store, e.g., the email address of the child of producer Alice
 *    and actor Bob, that could have key=alice_and_bobs_childs_email_address.
 * -  Several modifiers can be applied to the tag name. This is done by
 *    appending a dash character ('-') and the modifier name in the order
 *    they appear in the list below -- e.g. foo-eng-sort, not foo-sort-eng.
 *    -  language -- a tag whose value is localized for a particular language
 *       is appended with the ISO 639-2/B 3-letter language code.
 *       For example: Author-ger=Michael, Author-eng=Mike
 *       The original/default language is in the unqualified "Author" tag.
 *       A demuxer should set a default if it sets any translated tag.
 *    -  sorting  -- a modified version of a tag that should be used for
 *       sorting will have '-sort' appended. E.g. artist="The Beatles",
 *       artist-sort="Beatles, The".
 *
 * -  Demuxers attempt to export metadata in a generic format, however tags
 *    with no generic equivalents are left as they are stored in the container.
 *    Follows a list of generic tag names:
 *
 @verbatim
 album        -- name of the set this work belongs to
 album_artist -- main creator of the set/album, if different from artist.
                 e.g. "Various Artists" for compilation albums.
 artist       -- main creator of the work
 comment      -- any additional description of the file.
 composer     -- who composed the work, if different from artist.
 copyright    -- name of copyright holder.
 creation_time-- date when the file was created, preferably in ISO 8601.
 date         -- date when the work was created, preferably in ISO 8601.
 disc         -- number of a subset, e.g. disc in a multi-disc collection.
 encoder      -- name/settings of the software/hardware that produced the file.
 encoded_by   -- person/group who created the file.
 filename     -- original name of the file.
 genre        -- <self-evident>.
 language     -- main language in which the work is performed, preferably
                 in ISO 639-2 format. Multiple languages can be specified by
                 separating them with commas.
 performer    -- artist who performed the work, if different from artist.
                 E.g for "Also sprach Zarathustra", artist would be "Richard
                 Strauss" and performer "London Philharmonic Orchestra".
 publisher    -- name of the label/publisher.
 service_name     -- name of the service in broadcasting (channel name).
 service_provider -- name of the service provider in broadcasting.
 title        -- name of the work.
 track        -- number of this work in the set, can be in form current/total.
 variant_bitrate -- the total bitrate of the bitrate variant that the current stream is part of
 @endverbatim
 *
 * Look in the examples section for an application example how to use the Metadata API.
 *
 * @}
 *)

type
  PPAVFormatContext = ^PAVFormatContext;
  PAVFormatContext = ^TAVFormatContext;

(* packet functions *)

(**
 * Allocate and read the payload of a packet and initialize its
 * fields with default values.
 *
 * @param pkt packet
 * @param size desired payload size
 * @return >0 (read size) if OK, AVERROR_xxx otherwise
 *)
  Tav_get_packetProc = function(s: PAVIOContext; pkt: PAVPacket; size: Integer): Integer; cdecl;

(**
 * Read data and append it to the current content of the AVPacket.
 * If pkt->size is 0 this is identical to av_get_packet.
 * Note that this uses av_grow_packet and thus involves a realloc
 * which is inefficient. Thus this function should only be used
 * when there is no reasonable way to know (an upper bound of)
 * the final size.
 *
 * @param pkt packet
 * @param size amount of data to read
 * @return >0 (read size) if OK, AVERROR_xxx otherwise, previous data
 *         will not be lost even if an error occurs.
 *)
  Tav_append_packetProc = function(s: PAVIOContext; pkt: PAVPacket; size: Integer): Integer; cdecl;

(*************************************************)
(* fractional numbers for exact pts handling *)

(**
 * The exact value of the fractional number is: 'val + num / den'.
 * num is assumed to be 0 <= num < den.
*)
  PAVFrac = ^TAVFrac;
  TAVFrac = record
    val, num, den: Int64;
  end;

(*************************************************)
(* input/output formats *)

  PPAVCodecTag = ^PAVCodecTag;
  PAVCodecTag = ^TAVCodecTag;
  TAVCodecTag = record
    // need {$ALIGN 8}
    // TODO: check from libavformat/internal.h
    id: TAVCodecID;
    tag: Integer;
  end;

(**
 * This structure contains the data a format has to probe a file.
 *)
  PAVProbeData = ^TAVProbeData;
  TAVProbeData = record
    filename: PAnsiChar;
    buf: PAnsiChar;      (**< Buffer must have AVPROBE_PADDING_SIZE of extra allocated bytes filled with zero. *)
    buf_size: Integer;   (**< Size of buf except extra allocated bytes *)
  end;

//#define AVPROBE_SCORE_RETRY (AVPROBE_SCORE_MAX/4)
//#define AVPROBE_SCORE_EXTENSION  50 ///< score for file extension
//#define AVPROBE_SCORE_MAX       100 ///< maximum score

//#define AVPROBE_PADDING_SIZE 32             ///< extra allocated bytes at the end of the probe buffer

/// Demuxer will use avio_open, no opened file should be provided by the caller.
{
#define AVFMT_NOFILE        0x0001
#define AVFMT_NEEDNUMBER    0x0002 (**< Needs '%d' in filename. *)
#define AVFMT_SHOW_IDS      0x0008 (**< Show format stream IDs numbers. *)
#define AVFMT_RAWPICTURE    0x0020 (**< Format wants AVPicture structure for
                                      raw picture data. *)
#define AVFMT_GLOBALHEADER  0x0040 (**< Format wants global header. *)
#define AVFMT_NOTIMESTAMPS  0x0080 (**< Format does not need / have any timestamps. *)
#define AVFMT_GENERIC_INDEX 0x0100 (**< Use generic index building code. *)
#define AVFMT_TS_DISCONT    0x0200 /**< Format allows timestamp discontinuities. Note, muxers always require valid (monotone) timestamps */
#define AVFMT_VARIABLE_FPS  0x0400 /**< Format allows variable fps. */
#define AVFMT_NODIMENSIONS  0x0800 /**< Format does not need width/height */
#define AVFMT_NOSTREAMS     0x1000 /**< Format does not require any streams */
#define AVFMT_NOBINSEARCH   0x2000 /**< Format does not allow to fall back on binary search via read_timestamp */
#define AVFMT_NOGENSEARCH   0x4000 /**< Format does not allow to fall back on generic search */
#define AVFMT_NO_BYTE_SEEK  0x8000 /**< Format does not allow seeking by bytes */
#define AVFMT_ALLOW_FLUSH  0x10000 /**< Format allows flushing. If not set, the muxer will not receive a NULL packet in the write_packet function. */
#if LIBAVFORMAT_VERSION_MAJOR <= 54
#define AVFMT_TS_NONSTRICT 0x8020000 //we try to be compatible to the ABIs of ffmpeg and major forks
#else
#define AVFMT_TS_NONSTRICT 0x20000
#endif
                                   /**< Format does not require strictly
                                        increasing timestamps, but they must
                                        still be monotonic */
#define AVFMT_TS_NEGATIVE  0x40000 /**< Format allows muxing negative
                                        timestamps. If not set the timestamp
                                        will be shifted in av_write_frame and
                                        av_interleaved_write_frame so they
                                        start from 0.
                                        The user or muxer can override this through
                                        AVFormatContext.avoid_negative_ts
                                        */

#define AVFMT_SEEK_TO_PTS   0x4000000 /**< Seeking is based on PTS */
}

(**
 * @addtogroup lavf_encoding
 * @{
 *)
  PAVOutputFormat = ^TAVOutputFormat;
  TAVOutputFormat = record
    name: PAnsiChar;
    (**
     * Descriptive name for the format, meant to be more human-readable
     * than name. You should use the NULL_IF_CONFIG_SMALL() macro
     * to define it.
     *)
    long_name: PAnsiChar;
    mime_type: PAnsiChar;
    extensions: PAnsiChar; (**< comma-separated filename extensions *)
    (* output support *)
    audio_codec: TAVCodecID;    (**< default audio codec *)
    video_codec: TAVCodecID;    (**< default video codec *)
    subtitle_codec: TAVCodecID; (**< default subtitle codec *)
    (**
     * can use flags: AVFMT_NOFILE, AVFMT_NEEDNUMBER, AVFMT_RAWPICTURE,
     * AVFMT_GLOBALHEADER, AVFMT_NOTIMESTAMPS, AVFMT_VARIABLE_FPS,
     * AVFMT_NODIMENSIONS, AVFMT_NOSTREAMS, AVFMT_ALLOW_FLUSH,
     * AVFMT_TS_NONSTRICT
     *)
    flags: Integer;

    (**
     * List of supported codec_id-codec_tag pairs, ordered by "better
     * choice first". The arrays are all terminated by AV_CODEC_ID_NONE.
     *)
    //const struct AVCodecTag * const *codec_tag;
    codec_tag: PPAVCodecTag;


    priv_class: PAVClass; ///< AVClass for the private context

    (*****************************************************************
     * No fields below this line are part of the public API. They
     * may not be used outside of libavformat and can be changed and
     * removed at will.
     * New public fields should be added right above.
     *****************************************************************
     *)
    next: PAVOutputFormat;
    (**
     * size of private data so that it can be allocated in the wrapper.
     *)
    priv_data_size: Integer;

    write_header: function(s: PAVFormatContext): Integer; cdecl;
    (**
     * Write a packet. If AVFMT_ALLOW_FLUSH is set in flags,
     * pkt can be NULL in order to flush data buffered in the muxer.
     * When flushing, return 0 if there still is more data to flush,
     * or 1 if everything was flushed and there is no more buffered
     * data.
     *)
    write_packet: function(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;
    write_trailer: function(s: PAVFormatContext): Integer; cdecl;
    (**
     * Currently only used to set pixel format if not YUV420P.
     *)
    interleave_packet: function(s: PAVFormatContext; pktout: PAVPacket;
                                pktin: PAVPacket; flush: Integer): Integer; cdecl;
    (**
     * Test if the given codec can be stored in this container.
     *
     * @return 1 if the codec is supported, 0 if it is not.
     *         A negative number if unknown.
     *         MKTAG('A', 'P', 'I', 'C') if the codec is only supported as AV_DISPOSITION_ATTACHED_PIC
     *)
    query_codec: function(id: TAVCodecID; std_compliance: Integer): Integer; cdecl;

    get_output_timestamp: procedure(s: PAVFormatContext; stream: Integer;
                                 dts, wall: PInt64); cdecl;
  end;
(**
 * @}
 *)

(**
 * @addtogroup lavf_decoding
 * @{
 *)
  PPAVInputFormat = ^PAVInputFormat;
  PAVInputFormat = ^TAVInputFormat;
  TAVInputFormat = record
    (**
     * A comma separated list of short names for the format. New names
     * may be appended with a minor bump.
     *)
    name: PAnsiChar;

    (**
     * Descriptive name for the format, meant to be more human-readable
     * than name. You should use the NULL_IF_CONFIG_SMALL() macro
     * to define it.
     *)
    long_name: PAnsiChar;

    (**
     * Can use flags: AVFMT_NOFILE, AVFMT_NEEDNUMBER, AVFMT_SHOW_IDS,
     * AVFMT_GENERIC_INDEX, AVFMT_TS_DISCONT, AVFMT_NOBINSEARCH,
     * AVFMT_NOGENSEARCH, AVFMT_NO_BYTE_SEEK, AVFMT_SEEK_TO_PTS.
     *)
    flags: Integer;

    (**
     * If extensions are defined, then no probe is done. You should
     * usually not use extension format guessing because it is not
     * reliable enough
     *)
    extensions: PAnsiChar;

    codec_tag: PPAVCodecTag;

    priv_class: PAVClass; ///< AVClass for the private context

    (*****************************************************************
     * No fields below this line are part of the public API. They
     * may not be used outside of libavformat and can be changed and
     * removed at will.
     * New public fields should be added right above.
     *****************************************************************
     *)
    next: PAVInputFormat;

    (**
     * Raw demuxers store their codec ID here.
     *)
    raw_codec_id: Integer;

    (**
     * Size of private data so that it can be allocated in the wrapper.
     *)
    priv_data_size: Integer;

    (**
     * Tell if a given file has a chance of being parsed as this format.
     * The buffer provided is guaranteed to be AVPROBE_PADDING_SIZE bytes
     * big so you do not have to check for that unless you need more.
     *)
    read_probe: function(p: PAVProbeData): Integer; cdecl;

    (**
     * Read the format header and initialize the AVFormatContext
     * structure. Return 0 if OK. Only used in raw format right
     * now. 'avformat_new_stream' should be called to create new streams.
     *)
    read_header: function(s: PAVFormatContext): Integer; cdecl;

    (**
     * Read one packet and put it in 'pkt'. pts and flags are also
     * set. 'avformat_new_stream' can be called only if the flag
     * AVFMTCTX_NOHEADER is used and only in the calling thread (not in a
     * background thread).
     * @return 0 on success, < 0 on error.
     *         When returning an error, pkt must not have been allocated
     *         or must be freed before returning
     *)
    read_packet: function(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;

    (**
     * Close the stream. The AVFormatContext and AVStreams are not
     * freed by this function
     *)
    read_close: function(s: PAVFormatContext): Integer; cdecl;

    (**
     * Seek to a given timestamp relative to the frames in
     * stream component stream_index.
     * @param stream_index Must not be -1.
     * @param flags Selects which direction should be preferred if no exact
     *              match is available.
     * @return >= 0 on success (but not necessarily the new offset)
     *)
    read_seek: function(s: PAVFormatContext;
                     stream_index: Integer; timestamp: Int64; flags: Integer): Integer; cdecl;
    (**
     * Get the next timestamp in stream[stream_index].time_base units.
     * @return the timestamp or AV_NOPTS_VALUE if an error occurred
     *)
    read_timestamp: function(s: PAVFormatContext; stream_index: Integer;
                              pos: PInt64; pos_limit: Int64): Int64; cdecl;

    (**
     * Start/resume playing - only meaningful if using a network-based format
     * (RTSP).
     *)
    read_play: function(s: PAVFormatContext): Integer; cdecl;

    (**
     * Pause playing - only meaningful if using a network-based format
     * (RTSP).
     *)
    read_pause: function(s: PAVFormatContext): Integer; cdecl;

    (**
     * Seek to timestamp ts.
     * Seeking will be done so that the point from which all active streams
     * can be presented successfully will be closest to ts and within min/max_ts.
     * Active streams are all streams that have AVStream.discard < AVDISCARD_ALL.
     *)
    read_seek2: function(s: PAVFormatContext; stream_index: Integer; min_ts, ts, max_ts: Int64; flags: Integer): Integer; cdecl;
  end;
(**
 * @}
 *)

  TAVStreamParseType = (
    AVSTREAM_PARSE_NONE,
    AVSTREAM_PARSE_FULL,       (**< full parsing and repack *)
    AVSTREAM_PARSE_HEADERS,    (**< Only parse headers, don't repack. *)
    AVSTREAM_PARSE_TIMESTAMPS, (**< full parsing and interpolation of timestamps for frames not starting on a packet boundary *)
    AVSTREAM_PARSE_FULL_ONCE,  (**< full parsing and repack of the first frame only, only implemented for H.264 currently *)
    (**< full parsing and repack with timestamp and position generation by parser for raw
      this assumes that each packet in the file contains no demuxer level headers and
      just codec level data, otherwise position generation would fail *)
    AVSTREAM_PARSE_FULL_RAW=(0 or (Ord('R') shl 8) or (Ord('A') shl 16) or (Ord('W') shl 24))
  );

  PAVIndexEntry = ^TAVIndexEntry;
  TAVIndexEntry = record
    pos: Int64;
    timestamp: Int64;         (**<
                               * Timestamp in AVStream.time_base units, preferably the time from which on correctly decoded frames are available
                               * when seeking to this entry. That means preferable PTS on keyframe based formats.
                               * But demuxers can choose to store a different timestamp, if it is more convenient for the implementation or nothing better
                               * is known
                               *)
//#define AVINDEX_KEYFRAME 0x0001
//    int flags:2;
//    int size:30; //Yeah, trying to keep the size of this small to reduce memory requirements (it is 24 vs. 32 bytes due to possible 8-byte alignment).
    flags_size: Integer;
    min_distance: Integer;         (**< Minimum distance between this and the previous keyframe, used to avoid unneeded searching. *)
  end;

{
#define AV_DISPOSITION_DEFAULT   0x0001
#define AV_DISPOSITION_DUB       0x0002
#define AV_DISPOSITION_ORIGINAL  0x0004
#define AV_DISPOSITION_COMMENT   0x0008
#define AV_DISPOSITION_LYRICS    0x0010
#define AV_DISPOSITION_KARAOKE   0x0020
/**
 * Track should be used during playback by default.
 * Useful for subtitle track that should be displayed
 * even when user did not explicitly ask for subtitles.
 */
#define AV_DISPOSITION_FORCED    0x0040
#define AV_DISPOSITION_HEARING_IMPAIRED  0x0080  /**< stream for hearing impaired audiences */
#define AV_DISPOSITION_VISUAL_IMPAIRED   0x0100  /**< stream for visual impaired audiences */
#define AV_DISPOSITION_CLEAN_EFFECTS     0x0200  /**< stream without voice */
/**
 * The stream is stored in the file as an attached picture/"cover art" (e.g.
 * APIC frame in ID3v2). The single packet associated with it will be returned
 * among the first few packets read from the file unless seeking takes place.
 * It can also be accessed at any time in AVStream.attached_pic.
 */
#define AV_DISPOSITION_ATTACHED_PIC      0x0400

/**
 * To specify text track kind (different from subtitles default).
 */
#define AV_DISPOSITION_CAPTIONS     0x10000
#define AV_DISPOSITION_DESCRIPTIONS 0x20000
#define AV_DISPOSITION_METADATA     0x40000

/**
 * Options for behavior on timestamp wrap detection.
 */
#define AV_PTS_WRAP_IGNORE      0   ///< ignore the wrap
#define AV_PTS_WRAP_ADD_OFFSET  1   ///< add the format specific offset on wrap detection
#define AV_PTS_WRAP_SUB_OFFSET  -1  ///< subtract the format specific offset on wrap detection
}

  (**
   * Stream information used internally by av_find_stream_info()
   *)
//#define MAX_STD_TIMEBASES (60*12+6)
  Pduration_error = ^Tduration_error;
  Tduration_error = array[0..1] of array[0..{MAX_STD_TIMEBASES}(60*12+6) - 1] of Double;
  PInterStreamInfo = ^TInterStreamInfo;
  TInterStreamInfo = record
    last_dts: Int64;
    duration_gcd: Int64;
    duration_count: Integer;
    //double (*duration_error)[2][MAX_STD_TIMEBASES]
    //duration_error: array of array[0..1] of array[0..{MAX_STD_TIMEBASES}(60*12+6) - 1] of Double;
    duration_error: Pduration_error;
    codec_info_duration: Int64;
    codec_info_duration_fields: Int64;
    found_decoder: Integer;

    last_duration: Int64;

    (**
     * Those are used for average framerate estimation.
     *)
    fps_first_dts: Int64;
    fps_first_dts_idx: Integer;
    fps_last_dts: Int64;
    fps_last_dts_idx: Integer;
  end;
  PAVPacketList = ^TAVPacketList;
(**
 * Stream structure.
 * New fields can be added to the end with minor version bumps.
 * Removal, reordering and changes to existing fields require a major
 * version bump.
 * sizeof(AVStream) must not be used outside libav*.
 *)
  PPAVStream = ^PAVStream;
  PAVStream = ^TAVStream;
  TAVStream = record
    index: Integer;    (**< stream index in AVFormatContext *)
    (**
     * Format-specific stream ID.
     * decoding: set by libavformat
     * encoding: set by the user, replaced by libavformat if left unset
     *)
    id: Integer;
    (**
     * Codec context associated with this stream. Allocated and freed by
     * libavformat.
     *
     * - decoding: The demuxer exports codec information stored in the headers
     *             here.
     * - encoding: The user sets codec information, the muxer writes it to the
     *             output. Mandatory fields as specified in AVCodecContext
     *             documentation must be set even if this AVCodecContext is
     *             not actually used for encoding.
     *)
    codec: PAVCodecContext; (**< codec context *)
    priv_data: Pointer;

    (**
     * encoding: pts generation when outputting stream
     *)
    pts: TAVFrac;

    (**
     * This is the fundamental unit of time (in seconds) in terms
     * of which frame timestamps are represented.
     *
     * decoding: set by libavformat
     * encoding: set by libavformat in avformat_write_header. The muxer may use the
     * user-provided value of @ref AVCodecContext.time_base "codec->time_base"
     * as a hint.
     *)
    time_base: TAVRational;

    (**
     * Decoding: pts of the first frame of the stream in presentation order, in stream time base.
     * Only set this if you are absolutely 100% sure that the value you set
     * it to really is the pts of the first frame.
     * This may be undefined (AV_NOPTS_VALUE).
     * @note The ASF header does NOT contain a correct start_time the ASF
     * demuxer must NOT set this.
     *)
    start_time: Int64;

    (**
     * Decoding: duration of the stream, in stream time base.
     * If a source file does not specify a duration, but does specify
     * a bitrate, this value will be estimated from bitrate and file size.
     *)
    duration: Int64;

    nb_frames: Int64;                 ///< number of frames in this stream if known or 0

    disposition: Integer; (**< AV_DISPOSITION_* bit field *)

    discard: TAVDiscard; ///< Selects which packets can be discarded at will and do not need to be demuxed.

    (**
     * sample aspect ratio (0 if unknown)
     * - encoding: Set by user.
     * - decoding: Set by libavformat.
     *)
    sample_aspect_ratio: TAVRational;

    metadata: PAVDictionary;

    (**
     * Average framerate
     *)
    avg_frame_rate: TAVRational;

    (**
     * For streams with AV_DISPOSITION_ATTACHED_PIC disposition, this packet
     * will contain the attached picture.
     *
     * decoding: set by libavformat, must not be modified by the caller.
     * encoding: unused
     *)
    attached_pic: TAVPacket;

    (*****************************************************************
     * All fields below this line are not part of the public API. They
     * may not be used outside of libavformat and can be changed and
     * removed at will.
     * New public fields should be added right above.
     *****************************************************************
     *)

    (**
     * Stream information used internally by av_find_stream_info()
     *)
(*
#define MAX_STD_TIMEBASES (60*12+6)
    struct {
        int64_t last_dts;
        int64_t duration_gcd;
        int duration_count;
        double (*duration_error)[2][MAX_STD_TIMEBASES];
        int64_t codec_info_duration;
        int64_t codec_info_duration_fields;
        int found_decoder;

        int64_t last_duration;

        /**
         * Those are used for average framerate estimation.
         */
        int64_t fps_first_dts;
        int     fps_first_dts_idx;
        int64_t fps_last_dts;
        int     fps_last_dts_idx;

    } *info;
*)
    info: PInterStreamInfo;

    pts_wrap_bits: Integer; (**< number of bits in pts (used for wrapping control) *)

    // Timestamp generation support:
    (**
     * Timestamp corresponding to the last dts sync point.
     *
     * Initialized when AVCodecParserContext.dts_sync_point >= 0 and
     * a DTS is received from the underlying container. Otherwise set to
     * AV_NOPTS_VALUE by default.
     *)
    reference_dts: Int64;
    first_dts: Int64;
    cur_dts: Int64;
    last_IP_pts: Int64;
    last_IP_duration: Integer;

    (**
     * Number of packets to buffer for codec probing
     *)
//#define MAX_PROBE_PACKETS 2500
    probe_packets: Integer;

    (**
     * Number of frames that have been demuxed during av_find_stream_info()
     *)
    codec_info_nb_frames: Integer;

    (* av_read_frame() support *)
    need_parsing: TAVStreamParseType;
    parser: PAVCodecParserContext;

    (**
     * last packet in packet_buffer for this stream when muxing.
     *)
    last_in_packet_buffer: PAVPacketList;
    probe_data: TAVProbeData;
//#define MAX_REORDER_DELAY 16
    pts_buffer: array[0..MAX_REORDER_DELAY] of Int64;

    index_entries: PAVIndexEntry; (**< Only used if the format does not
                                    support seeking natively. *)
    nb_index_entries: Integer;
    index_entries_allocated_size: Cardinal;

    (**
     * Real base framerate of the stream.
     * This is the lowest framerate with which all timestamps can be
     * represented accurately (it is the least common multiple of all
     * framerates in the stream). Note, this value is just a guess!
     * For example, if the time base is 1/90000 and all frames have either
     * approximately 3600 or 1800 timer ticks, then r_frame_rate will be 50/1.
     *
     * Code outside avformat should access this field using:
     * av_stream_get/set_r_frame_rate(stream)
     *)
    r_frame_rate: TAVRational;

    (**
     * Stream Identifier
     * This is the MPEG-TS stream identifier +1
     * 0 means unknown
     *)
    stream_identifier: Integer;

    interleaver_chunk_size: Int64;
    interleaver_chunk_duration: Int64;

    (**
     * stream probing state
     * -1   -> probing finished
     *  0   -> no probing requested
     * rest -> perform probing with request_probe being the minimum score to accept.
     * NOT PART OF PUBLIC API
     *)
    request_probe: Integer;
    (**
     * Indicates that everything up to the next keyframe
     * should be discarded.
     *)
    skip_to_keyframe: Integer;

    (**
     * Number of samples to skip at the start of the frame decoded from the next packet.
     *)
    skip_samples: Integer;

    (**
     * Number of internally decoded frames, used internally in libavformat, do not access
     * its lifetime differs from info which is why it is not in that structure.
     *)
    nb_decoded_frames: Integer;

    (**
     * Timestamp offset added to timestamps before muxing
     * NOT PART OF PUBLIC API
     *)
    mux_ts_offset: Int64;

    (**
     * Internal data to check for wrapping of the time stamp
     *)
    pts_wrap_reference: Int64;

    (**
     * Options for behavior, when a wrap is detected.
     *
     * Defined by AV_PTS_WRAP_ values.
     *
     * If correction is enabled, there are two possibilities:
     * If the first time stamp is near the wrap point, the wrap offset
     * will be subtracted, which will create negative time stamps.
     * Otherwise the offset will be added.
     *)
    pts_wrap_behavior: Integer;

  end;

//TODO: API returen record  Tav_stream_get_r_frame_rateProc = function(const s: PAVStream): TAVRational; cdecl;
  Tav_stream_set_r_frame_rateProc = procedure(s: PAVStream; r: TAVRational); cdecl;

//#define AV_PROGRAM_RUNNING 1

(**
 * New fields can be added to the end with minor version bumps.
 * Removal, reordering and changes to existing fields require a major
 * version bump.
 * sizeof(AVProgram) must not be used outside libav*.
 *)
  PPAVProgram = ^PAVProgram;
  PAVProgram = ^TAVProgram;
  TAVProgram = record
    id: Integer;
    flags: Integer;
    discard: TAVDiscard;  ///< selects which program to discard and which to feed to the caller
    stream_index: PCardinal;
    nb_stream_indexes: Cardinal;
    metadata: PAVDictionary;

    program_num: Integer;
    pmt_pid: Integer;
    pcr_pid: Integer;

    (*****************************************************************
     * All fields below this line are not part of the public API. They
     * may not be used outside of libavformat and can be changed and
     * removed at will.
     * New public fields should be added right above.
     *****************************************************************
     *)
    start_time: Int64;
    end_time: Int64;

    pts_wrap_reference: Int64;    ///< reference dts for wrap detection
    pts_wrap_behavior: Integer;   ///< behavior on wrap detection
  end;

  PPAVChapter = ^PAVChapter;
  PAVChapter = ^TAVChapter;
  TAVChapter = record
    id: Integer;            ///< unique ID to identify the chapter
    time_base: TAVRational; ///< time base in which the start/end timestamps are specified
    start, eend: Int64;     ///< chapter start/end time in time_base units
    metadata: PAVDictionary;
  end;


(**
 * The duration of a video can be estimated through various ways, and this enum can be used
 * to know how the duration was estimated.
 *)
  TAVDurationEstimationMethod = (
    AVFMT_DURATION_FROM_PTS,    ///< Duration accurately estimated from PTSes
    AVFMT_DURATION_FROM_STREAM, ///< Duration estimated from a stream with a known duration
    AVFMT_DURATION_FROM_BITRATE ///< Duration estimated from bitrate (less accurate)
  );

(**
 * Format I/O context.
 * New fields can be added to the end with minor version bumps.
 * Removal, reordering and changes to existing fields require a major
 * version bump.
 * sizeof(AVFormatContext) must not be used outside libav*, use
 * avformat_alloc_context() to create an AVFormatContext.
 *)
  TAVFormatContext = record
    (**
     * A class for logging and AVOptions. Set by avformat_alloc_context().
     * Exports (de)muxer private options if they exist.
     *)
    av_class: PAVClass;

    (**
     * Can only be iformat or oformat, not both at the same time.
     *
     * decoding: set by avformat_open_input().
     * encoding: set by the user.
     *)
    iformat: PAVInputFormat;
    oformat: PAVOutputFormat;

    (**
     * Format private data. This is an AVOptions-enabled struct
     * if and only if iformat/oformat.priv_class is not NULL.
     *)
    priv_data: Pointer;

    (**
     * I/O context.
     *
     * decoding: either set by the user before avformat_open_input() (then
     * the user must close it manually) or set by avformat_open_input().
     * encoding: set by the user.
     *
     * Do NOT set this field if AVFMT_NOFILE flag is set in
     * iformat/oformat.flags. In such a case, the (de)muxer will handle
     * I/O in some other way and this field will be NULL.
     *)
    pb: PAVIOContext;

    (* stream info *)
    ctx_flags: Integer; (**< Format-specific flags, see AVFMTCTX_xx *)

    (**
     * A list of all streams in the file. New streams are created with
     * avformat_new_stream().
     *
     * decoding: streams are created by libavformat in avformat_open_input().
     * If AVFMTCTX_NOHEADER is set in ctx_flags, then new streams may also
     * appear in av_read_frame().
     * encoding: streams are created by the user before avformat_write_header().
     *)
    nb_streams: Cardinal;
    streams: PPAVStream;

    filename: array[0..1024-1] of AnsiChar; (**< input or output filename *)

    (**
     * Decoding: position of the first frame of the component, in
     * AV_TIME_BASE fractional seconds. NEVER set this value directly:
     * It is deduced from the AVStream values.
     *)
    start_time: Int64;

    (**
     * Decoding: duration of the stream, in AV_TIME_BASE fractional
     * seconds. Only set this value if you know none of the individual stream
     * durations and also do not set any of them. This is deduced from the
     * AVStream values if not set.
     *)
    duration: Int64;

    (**
     * Decoding: total stream bitrate in bit/s, 0 if not
     * available. Never set it directly if the file_size and the
     * duration are known as FFmpeg can compute it automatically.
     *)
    bit_rate: Integer;

    packet_size: Cardinal;
    max_delay: Integer;

    flags: Integer;
{
#define AVFMT_FLAG_GENPTS       0x0001 ///< Generate missing pts even if it requires parsing future frames.
#define AVFMT_FLAG_IGNIDX       0x0002 ///< Ignore index.
#define AVFMT_FLAG_NONBLOCK     0x0004 ///< Do not block when reading packets from input.
#define AVFMT_FLAG_IGNDTS       0x0008 ///< Ignore DTS on frames that contain both DTS & PTS
#define AVFMT_FLAG_NOFILLIN     0x0010 ///< Do not infer any values from other values, just return what is stored in the container
#define AVFMT_FLAG_NOPARSE      0x0020 ///< Do not use AVParsers, you also must set AVFMT_FLAG_NOFILLIN as the fillin code works on frames and no parsing -> no frames. Also seeking to frames can not work if parsing to find frame boundaries has been disabled
#define AVFMT_FLAG_NOBUFFER     0x0040 ///< Do not buffer frames when possible
#define AVFMT_FLAG_CUSTOM_IO    0x0080 ///< The caller has supplied a custom AVIOContext, don't avio_close() it.
#define AVFMT_FLAG_DISCARD_CORRUPT  0x0100 ///< Discard frames marked corrupted
#define AVFMT_FLAG_FLUSH_PACKETS    0x0200 ///< Flush the AVIOContext every packet.
#define AVFMT_FLAG_MP4A_LATM    0x8000 ///< Enable RTP MP4A-LATM payload
#define AVFMT_FLAG_SORT_DTS    0x10000 ///< try to interleave outputted packets by dts (using this flag can slow demuxing down)
#define AVFMT_FLAG_PRIV_OPT    0x20000 ///< Enable use of private options by delaying codec open (this could be made default once all code is converted)
#define AVFMT_FLAG_KEEP_SIDE_DATA 0x40000 ///< Don't merge side data but keep it separate.
}

    (**
     * decoding: size of data to probe; encoding: unused.
     *)
    probesize: Cardinal;

    (**
     * decoding: maximum time (in AV_TIME_BASE units) during which the input should
     * be analyzed in avformat_find_stream_info().
     *)
    max_analyze_duration: Integer;

    key: PByte;
    keylen: Integer;

    nb_programs: Cardinal;
    programs: PPAVProgram;

    (**
     * Forced video codec_id.
     * Demuxing: set by user.
     *)
    video_codec_id: TAVCodecID;

    (**
     * Forced audio codec_id.
     * Demuxing: set by user.
     *)
    audio_codec_id: TAVCodecID;

    (**
     * Forced subtitle codec_id.
     * Demuxing: set by user.
     *)
    subtitle_codec_id: TAVCodecID;

    (**
     * Maximum amount of memory in bytes to use for the index of each stream.
     * If the index exceeds this size, entries will be discarded as
     * needed to maintain a smaller size. This can lead to slower or less
     * accurate seeking (depends on demuxer).
     * Demuxers for which a full in-memory index is mandatory will ignore
     * this.
     * muxing  : unused
     * demuxing: set by user
     *)
    max_index_size: Cardinal;

    (**
     * Maximum amount of memory in bytes to use for buffering frames
     * obtained from realtime capture devices.
     *)
    max_picture_buffer: Cardinal;

    (**
     * Number of chapters in AVChapter array.
     * When muxing, chapters are normally written in the file header,
     * so nb_chapters should normally be initialized before write_header
     * is called. Some muxers (e.g. mov and mkv) can also write chapters
     * in the trailer.  To write chapters in the trailer, nb_chapters
     * must be zero when write_header is called and non-zero when
     * write_trailer is called.
     * muxing  : set by user
     * demuxing: set by libavformat
     *)
    nb_chapters: Cardinal;
    chapters: PPAVChapter;

    metadata: PAVDictionary;

    (**
     * Start time of the stream in real world time, in microseconds
     * since the unix epoch (00:00 1st January 1970). That is, pts=0
     * in the stream was captured at this real world time.
     * - encoding: Set by user.
     * - decoding: Unused.
     *)
    start_time_realtime: Int64;


    (**
     * decoding: number of frames used to probe fps
     *)
    fps_probe_size: Integer;

    (**
     * Error recognition; higher values will detect more errors but may
     * misdetect some more or less valid parts as errors.
     * - encoding: unused
     * - decoding: Set by user.
     *)
    error_recognition: Integer;

    (**
     * Custom interrupt callbacks for the I/O layer.
     *
     * decoding: set by the user before avformat_open_input().
     * encoding: set by the user before avformat_write_header()
     * (mainly useful for AVFMT_NOFILE formats). The callback
     * should also be passed to avio_open2() if it's used to
     * open the file.
     *)
    interrupt_callback: TAVIOInterruptCB;

    (**
     * Flags to enable debugging.
     *)
    debug: Integer;
//#define FF_FDEBUG_TS        0x0001

    (**
     * Transport stream id.
     * This will be moved into demuxer private options. Thus no API/ABI compatibility
     *)
    ts_id: Integer;

    (**
     * Audio preload in microseconds.
     * Note, not all formats support this and unpredictable things may happen if it is used when not supported.
     * - encoding: Set by user via AVOptions (NO direct access)
     * - decoding: unused
     *)
    audio_preload: Integer;

    (**
     * Max chunk time in microseconds.
     * Note, not all formats support this and unpredictable things may happen if it is used when not supported.
     * - encoding: Set by user via AVOptions (NO direct access)
     * - decoding: unused
     *)
    max_chunk_duration: Integer;

    (**
     * Max chunk size in bytes
     * Note, not all formats support this and unpredictable things may happen if it is used when not supported.
     * - encoding: Set by user via AVOptions (NO direct access)
     * - decoding: unused
     *)
    max_chunk_size: Integer;

    (**
     * forces the use of wallclock timestamps as pts/dts of packets
     * This has undefined results in the presence of B frames.
     * - encoding: unused
     * - decoding: Set by user via AVOptions (NO direct access)
     *)
    use_wallclock_as_timestamps: Integer;

    (**
     * Avoid negative timestamps during muxing.
     *  0 -> allow negative timestamps
     *  1 -> avoid negative timestamps
     * -1 -> choose automatically (default)
     * Note, this only works when interleave_packet_per_dts is in use.
     * - encoding: Set by user via AVOptions (NO direct access)
     * - decoding: unused
     *)
    avoid_negative_ts: Integer;

    (**
     * avio flags, used to force AVIO_FLAG_DIRECT.
     * - encoding: unused
     * - decoding: Set by user via AVOptions (NO direct access)
     *)
    avio_flags: Integer;

    (**
     * The duration field can be estimated through various ways, and this field can be used
     * to know how the duration was estimated.
     * - encoding: unused
     * - decoding: Read by user via AVOptions (NO direct access)
     *)
    duration_estimation_method: TAVDurationEstimationMethod;

    (**
     * Skip initial bytes when opening stream
     * - encoding: unused
     * - decoding: Set by user via AVOptions (NO direct access)
     *)
    skip_initial_bytes: Cardinal;

    (**
     * Correct single timestamp overflows
     * - encoding: unused
     * - decoding: Set by user via AVOPtions (NO direct access)
     *)
    correct_ts_overflow: Cardinal;

    (**
     * Force seeking to any (also non key) frames.
     * - encoding: unused
     * - decoding: Set by user via AVOPtions (NO direct access)
     *)
    seek2any: Integer;

    (**
     * Flush the I/O context after each packet.
     * - encoding: Set by user via AVOptions (NO direct access)
     * - decoding: unused
     *)
    flush_packets: Integer;

    (**
     * format probing score.
     * The maximal score is AVPROBE_SCORE_MAX, its set when the demuxer probes
     * the format.
     * - encoding: unused
     * - decoding: set by avformat, read by user via av_format_get_probe_score() (NO direct access)
     *)
    probe_score: Integer;

    (*****************************************************************
     * All fields below this line are not part of the public API. They
     * may not be used outside of libavformat and can be changed and
     * removed at will.
     * New public fields should be added right above.
     *****************************************************************
     *)

    (**
     * This buffer is only needed when packets were already buffered but
     * not decoded, for example to get the codec parameters in MPEG
     * streams.
     *)
    packet_buffer: PAVPacketList;
    packet_buffer_end: PAVPacketList;

    (* av_seek_frame() support *)
    data_offset: Int64; (**< offset of the first packet *)

    (**
     * Raw packets from the demuxer, prior to parsing and decoding.
     * This buffer is used for buffering packets until the codec can
     * be identified, as parsing cannot be done without knowing the
     * codec.
     *)
    raw_packet_buffer: PAVPacketList;
    raw_packet_buffer_end: PAVPacketList;
    (**
     * Packets split by the parser get queued here.
     *)
    parse_queue: PAVPacketList;
    parse_queue_end: PAVPacketList;
    (**
     * Remaining size available for raw_packet_buffer, in bytes.
     *)
//#define RAW_PACKET_BUFFER_SIZE 2500000
    raw_packet_buffer_remaining_size: Integer;

    (**
     * Offset to remap timestamps to be non-negative.
     * Expressed in timebase units.
     * @see AVStream.mux_ts_offset
     *)
    offset: Int64;

    (**
     * Timebase for the timestamp offset.
     *)
    offset_timebase: TAVRational;

    (**
     * IO repositioned flag.
     * This is set by avformat when the underlaying IO context read pointer
     * is repositioned, for example when doing byte based seeking.
     * Demuxers can use the flag to detect such changes.
     *)
    io_repositioned: Integer;

    (**
     * Forced video codec.
     * This allows forcing a specific decoder, even when there are multiple with
     * the same codec_id.
     * Demuxing: Set by user via av_format_set_video_codec (NO direct access).
     *)
    video_codec: PAVCodec;

    (**
     * Forced audio codec.
     * This allows forcing a specific decoder, even when there are multiple with
     * the same codec_id.
     * Demuxing: Set by user via av_format_set_audio_codec (NO direct access).
     *)
    audio_codec: PAVCodec;

    (**
     * Forced subtitle codec.
     * This allows forcing a specific decoder, even when there are multiple with
     * the same codec_id.
     * Demuxing: Set by user via av_format_set_subtitle_codec (NO direct access).
     *)
    subtitle_codec: PAVCodec;
  end;

  Tav_format_get_probe_scoreProc = function(const s: PAVFormatContext): Integer; cdecl;
  Tav_format_get_video_codecProc = function(const s: PAVFormatContext): PAVCodec; cdecl;
  Tav_format_set_video_codecProc = procedure(s: PAVFormatContext; c: PAVCodec); cdecl;
  Tav_format_get_audio_codecProc = function(const s: PAVFormatContext): PAVCodec; cdecl;
  Tav_format_set_audio_codecProc = procedure(s: PAVFormatContext; c: PAVCodec); cdecl;
  Tav_format_get_subtitle_codecProc = function(const s: PAVFormatContext): PAVCodec; cdecl;
  Tav_format_set_subtitle_codecProc = procedure(s: PAVFormatContext; c: PAVCodec); cdecl;

(**
 * Returns the method used to set ctx->duration.
 *
 * @return AVFMT_DURATION_FROM_PTS, AVFMT_DURATION_FROM_STREAM, or AVFMT_DURATION_FROM_BITRATE.
 *)
  Tav_fmt_ctx_get_duration_estimation_methodProc = function(const ctx: PAVFormatContext): TAVDurationEstimationMethod; cdecl;

  TAVPacketList = record
    pkt: TAVPacket;
    next: PAVPacketList;
  end;


(**
 * @defgroup lavf_core Core functions
 * @ingroup libavf
 *
 * Functions for querying libavformat capabilities, allocating core structures,
 * etc.
 * @{
 *)

(**
 * Return the LIBAVFORMAT_VERSION_INT constant.
 *)
  Tavformat_versionProc = function: Cardinal; cdecl;

(**
 * Return the libavformat build-time configuration.
 *)
  Tavformat_configurationProc = function: PAnsiChar; cdecl;

(**
 * Return the libavformat license.
 *)
  Tavformat_licenseProc = function: PAnsiChar; cdecl;

(**
 * Initialize libavformat and register all the muxers, demuxers and
 * protocols. If you do not call this function, then you can select
 * exactly which formats you want to support.
 *
 * @see av_register_input_format()
 * @see av_register_output_format()
 *)
  Tav_register_allProc = procedure; cdecl;

  Tav_register_input_formatProc = procedure(format: PAVInputFormat); cdecl;
  Tav_register_output_formatProc = procedure(format: PAVOutputFormat); cdecl;

(**
 * Do global initialization of network components. This is optional,
 * but recommended, since it avoids the overhead of implicitly
 * doing the setup for each session.
 *
 * Calling this function will become mandatory if using network
 * protocols at some major version bump.
 *)
  Tavformat_network_initProc = function: Integer; cdecl;

(**
 * Undo the initialization done by avformat_network_init.
 *)
  Tavformat_network_deinitProc = function: Integer; cdecl;

(**
 * If f is NULL, returns the first registered input format,
 * if f is non-NULL, returns the next registered input format after f
 * or NULL if f is the last one.
 *)
  Tav_iformat_nextProc = function(f: PAVInputFormat): PAVInputFormat; cdecl;

(**
 * If f is NULL, returns the first registered output format,
 * if f is non-NULL, returns the next registered output format after f
 * or NULL if f is the last one.
 *)
  Tav_oformat_nextProc = function(f: PAVOutputFormat): PAVOutputFormat; cdecl;

(**
 * Allocate an AVFormatContext.
 * avformat_free_context() can be used to free the context and everything
 * allocated by the framework within it.
 *)
  Tavformat_alloc_contextProc = function(): PAVFormatContext; cdecl;

(**
 * Free an AVFormatContext and all its streams.
 * @param s context to free
 *)
  Tavformat_free_contextProc = procedure(s: PAVFormatContext); cdecl;

(**
 * Get the AVClass for AVFormatContext. It can be used in combination with
 * AV_OPT_SEARCH_FAKE_OBJ for examining options.
 *
 * @see av_opt_find().
 *)
  Tavformat_get_classProc = function: PAVClass; cdecl;

(**
 * Add a new stream to a media file.
 *
 * When demuxing, it is called by the demuxer in read_header(). If the
 * flag AVFMTCTX_NOHEADER is set in s.ctx_flags, then it may also
 * be called in read_packet().
 *
 * When muxing, should be called by the user before avformat_write_header().
 *
 * User is required to call avcodec_close() and avformat_free_context() to
 * clean up the allocation by avformat_new_stream().
 *
 * @param c If non-NULL, the AVCodecContext corresponding to the new stream
 * will be initialized to use this codec. This is needed for e.g. codec-specific
 * defaults to be set, so codec should be provided if it is known.
 *
 * @return newly created stream or NULL on error.
 *)
  Tavformat_new_streamProc = function(s: PAVFormatContext; const c: PAVCodec): PAVStream; cdecl;

  Tav_new_programProc = function(s: PAVFormatContext; id: Integer): PAVProgram; cdecl;

(**
 * @}
 *)


{$IFDEF FF_API_ALLOC_OUTPUT_CONTEXT}
(**
 * @deprecated deprecated in favor of avformat_alloc_output_context2()
 *)
  Tavformat_alloc_output_contextProc = function(const format: PAnsiChar;
                                                oformat: PAVOutputFormat;
                                               const filename: PAnsiChar): PAVFormatContext; cdecl;
{$ENDIF}

(**
 * Allocate an AVFormatContext for an output format.
 * avformat_free_context() can be used to free the context and
 * everything allocated by the framework within it.
 *
 * @param *ctx is set to the created format context, or to NULL in
 * case of failure
 * @param oformat format to use for allocating the context, if NULL
 * format_name and filename are used instead
 * @param format_name the name of output format to use for allocating the
 * context, if NULL filename is used instead
 * @param filename the name of the filename to use for allocating the
 * context, may be NULL
 * @return >= 0 in case of success, a negative AVERROR code in case of
 * failure
 *)
  Tavformat_alloc_output_context2Proc = function(ctx: PPAVFormatContext; oformat: PAVOutputFormat;
                                   const format_name, filename: PAnsiChar): Integer; cdecl;

(**
 * @addtogroup lavf_decoding
 * @{
 *)

(**
 * Find AVInputFormat based on the short name of the input format.
 *)
  Tav_find_input_formatProc = function(const short_name: PAnsiChar): PAVInputFormat; cdecl;

(**
 * Guess the file format.
 *
 * @param is_opened Whether the file is already opened; determines whether
 *                  demuxers with or without AVFMT_NOFILE are probed.
 *)
  Tav_probe_input_formatProc = function(pd: PAVProbeData; is_opened: Integer): PAVInputFormat; cdecl;

(**
 * Guess the file format.
 *
 * @param is_opened Whether the file is already opened; determines whether
 *                  demuxers with or without AVFMT_NOFILE are probed.
 * @param score_max A probe score larger that this is required to accept a
 *                  detection, the variable is set to the actual detection
 *                  score afterwards.
 *                  If the score is <= AVPROBE_SCORE_MAX / 4 it is recommended
 *                  to retry with a larger probe buffer.
 *)
  Tav_probe_input_format2Proc = function(pd: PAVProbeData; is_opened: Integer; score_max: PInteger): PAVInputFormat; cdecl;

(**
 * Guess the file format.
 *
 * @param is_opened Whether the file is already opened; determines whether
 *                  demuxers with or without AVFMT_NOFILE are probed.
 * @param score_ret The score of the best detection.
 *)
  Tav_probe_input_format3Proc = function(pd: PAVProbeData; is_opened: Integer; score_ret: PInteger): PAVInputFormat; cdecl;

(**
 * Probe a bytestream to determine the input format. Each time a probe returns
 * with a score that is too low, the probe buffer size is increased and another
 * attempt is made. When the maximum probe size is reached, the input format
 * with the highest score is returned.
 *
 * @param pb the bytestream to probe
 * @param fmt the input format is put here
 * @param filename the filename of the stream
 * @param logctx the log context
 * @param offset the offset within the bytestream to probe from
 * @param max_probe_size the maximum probe buffer size (zero for default)
 * @return the score in case of success, a negative value corresponding to an
 *         the maximal score is AVPROBE_SCORE_MAX
 * AVERROR code otherwise
 *)
  Tav_probe_input_buffer2Proc = function(pb: PAVIOContext; fmt: PPAVInputFormat;
                           const filename: PAnsiChar; logctx: Pointer;
                           offset, max_probe_size: Cardinal): Integer; cdecl;

(**
 * Like av_probe_input_buffer2() but returns 0 on success
 *)
  Tav_probe_input_bufferProc = function(pb: PAVIOContext; fmt: PPAVInputFormat;
                          const filename: PAnsiChar; logctx: Pointer;
                          offset, max_probe_size: Cardinal): Integer; cdecl;

(**
 * Open an input stream and read the header. The codecs are not opened.
 * The stream must be closed with avformat_close_input().
 *
 * @param ps Pointer to user-supplied AVFormatContext (allocated by avformat_alloc_context).
 *           May be a pointer to NULL, in which case an AVFormatContext is allocated by this
 *           function and written into ps.
 *           Note that a user-supplied AVFormatContext will be freed on failure.
 * @param filename Name of the stream to open.
 * @param fmt If non-NULL, this parameter forces a specific input format.
 *            Otherwise the format is autodetected.
 * @param options  A dictionary filled with AVFormatContext and demuxer-private options.
 *                 On return this parameter will be destroyed and replaced with a dict containing
 *                 options that were not found. May be NULL.
 *
 * @return 0 on success, a negative AVERROR on failure.
 *
 * @note If you want to use custom IO, preallocate the format context and set its pb field.
 *)
  Tavformat_open_inputProc = function(ps: PPAVFormatContext; const filename: PAnsiChar; fmt: PAVInputFormat; options: PPAVDictionary): Integer; cdecl;

  Tav_demuxer_openProc = function(ic: PAVFormatContext): Integer; cdecl;

{$IFDEF FF_API_FORMAT_PARAMETERS}
(**
 * Read packets of a media file to get stream information. This
 * is useful for file formats with no headers such as MPEG. This
 * function also computes the real framerate in case of MPEG-2 repeat
 * frame mode.
 * The logical file position is not changed by this function;
 * examined packets may be buffered for later processing.
 *
 * @param ic media file handle
 * @return >=0 if OK, AVERROR_xxx on error
 * @todo Let the user decide somehow what information is needed so that
 *       we do not waste time getting stuff the user does not need.
 *
 * @deprecated use avformat_find_stream_info.
 *)
  Tav_find_stream_infoProc = function(ic: PAVFormatContext): Integer; cdecl;
{$ENDIF}

(**
 * Read packets of a media file to get stream information. This
 * is useful for file formats with no headers such as MPEG. This
 * function also computes the real framerate in case of MPEG-2 repeat
 * frame mode.
 * The logical file position is not changed by this function;
 * examined packets may be buffered for later processing.
 *
 * @param ic media file handle
 * @param options  If non-NULL, an ic.nb_streams long array of pointers to
 *                 dictionaries, where i-th member contains options for
 *                 codec corresponding to i-th stream.
 *                 On return each dictionary will be filled with options that were not found.
 * @return >=0 if OK, AVERROR_xxx on error
 *
 * @note this function isn't guaranteed to open all the codecs, so
 *       options being non-empty at return is a perfectly normal behavior.
 *
 * @todo Let the user decide somehow what information is needed so that
 *       we do not waste time getting stuff the user does not need.
 *)
  Tavformat_find_stream_infoProc = function(ic: PAVFormatContext; options: PPAVDictionary): Integer; cdecl;

(**
 * Find the programs which belong to a given stream.
 *
 * @param ic    media file handle
 * @param last  the last found program, the search will start after this
 *              program, or from the beginning if it is NULL
 * @param s     stream index
 * @return the next program which belongs to s, NULL if no program is found or
 *         the last program is not among the programs of ic.
 *)
  Tav_find_program_from_streamProc = function(ic: PAVFormatContext; last: PAVProgram; s: Integer): PAVProgram; cdecl;

(**
 * Find the "best" stream in the file.
 * The best stream is determined according to various heuristics as the most
 * likely to be what the user expects.
 * If the decoder parameter is non-NULL, av_find_best_stream will find the
 * default decoder for the stream's codec; streams for which no decoder can
 * be found are ignored.
 *
 * @param ic                media file handle
 * @param type              stream type: video, audio, subtitles, etc.
 * @param wanted_stream_nb  user-requested stream number,
 *                          or -1 for automatic selection
 * @param related_stream    try to find a stream related (eg. in the same
 *                          program) to this one, or -1 if none
 * @param decoder_ret       if non-NULL, returns the decoder for the
 *                          selected stream
 * @param flags             flags; none are currently defined
 * @return  the non-negative stream number in case of success,
 *          AVERROR_STREAM_NOT_FOUND if no stream with the requested type
 *          could be found,
 *          AVERROR_DECODER_NOT_FOUND if streams were found but no decoder
 * @note  If av_find_best_stream returns successfully and decoder_ret is not
 *        NULL, then *decoder_ret is guaranteed to be set to a valid AVCodec.
 *)
  Tav_find_best_streamProc = function(ic: PAVFormatContext;
                        type_: TAVMediaType;
                        wanted_stream_nb,
                        related_stream: Integer;
                        decoder_ret: PPAVCodec;
                        flags: Integer): Integer; cdecl;

{$IFDEF FF_API_READ_PACKET}
(**
 * @deprecated use AVFMT_FLAG_NOFILLIN | AVFMT_FLAG_NOPARSE to read raw
 * unprocessed packets
 *
 * Read a transport packet from a media file.
 *
 * This function is obsolete and should never be used.
 * Use av_read_frame() instead.
 *
 * @param s media file handle
 * @param pkt is filled
 * @return 0 if OK, AVERROR_xxx on error.
 *)
  Tav_read_packetProc = function(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;
{$ENDIF}

(**
 * Return the next frame of a stream.
 * This function returns what is stored in the file, and does not validate
 * that what is there are valid frames for the decoder. It will split what is
 * stored in the file into frames and return one for each call. It will not
 * omit invalid data between valid frames so as to give the decoder the maximum
 * information possible for decoding.
 *
 * If pkt->buf is NULL, then the packet is valid until the next
 * av_read_frame() or until avformat_close_input(). Otherwise the packet
 * is valid indefinitely. In both cases the packet must be freed with
 * av_free_packet when it is no longer needed. For video, the packet contains
 * exactly one frame. For audio, it contains an integer number of frames if each
 * frame has a known fixed size (e.g. PCM or ADPCM data). If the audio frames
 * have a variable size (e.g. MPEG audio), then it contains one frame.
 *
 * pkt->pts, pkt->dts and pkt->duration are always set to correct
 * values in AVStream.time_base units (and guessed if the format cannot
 * provide them). pkt->pts can be AV_NOPTS_VALUE if the video format
 * has B-frames, so it is better to rely on pkt->dts if you do not
 * decompress the payload.
 *
 * @return 0 if OK, < 0 on error or end of file
 *)
  Tav_read_frameProc = function(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;

(**
 * Seek to the keyframe at timestamp.
 * 'timestamp' in 'stream_index'.
 * @param stream_index If stream_index is (-1), a default
 * stream is selected, and timestamp is automatically converted
 * from AV_TIME_BASE units to the stream specific time_base.
 * @param timestamp Timestamp in AVStream.time_base units
 *        or, if no stream is specified, in AV_TIME_BASE units.
 * @param flags flags which select direction and seeking mode
 * @return >= 0 on success
 *)
  Tav_seek_frameProc = function(s: PAVFormatContext; stream_index: Integer; timestamp: Int64;
                                flags: Integer): Integer; cdecl;

(**
 * Seek to timestamp ts.
 * Seeking will be done so that the point from which all active streams
 * can be presented successfully will be closest to ts and within min/max_ts.
 * Active streams are all streams that have AVStream.discard < AVDISCARD_ALL.
 *
 * If flags contain AVSEEK_FLAG_BYTE, then all timestamps are in bytes and
 * are the file position (this may not be supported by all demuxers).
 * If flags contain AVSEEK_FLAG_FRAME, then all timestamps are in frames
 * in the stream with stream_index (this may not be supported by all demuxers).
 * Otherwise all timestamps are in units of the stream selected by stream_index
 * or if stream_index is -1, in AV_TIME_BASE units.
 * If flags contain AVSEEK_FLAG_ANY, then non-keyframes are treated as
 * keyframes (this may not be supported by all demuxers).
 * If flags contain AVSEEK_FLAG_BACKWARD, it is ignored.
 *
 * @param stream_index index of the stream which is used as time base reference
 * @param min_ts smallest acceptable timestamp
 * @param ts target timestamp
 * @param max_ts largest acceptable timestamp
 * @param flags flags
 * @return >=0 on success, error code otherwise
 *
 * @note This is part of the new seek API which is still under construction.
 *       Thus do not use this yet. It may change at any time, do not expect
 *       ABI compatibility yet!
 *)
  Tavformat_seek_fileProc = function(s: PAVFormatContext; stream_index: Integer; min_ts, ts, max_ts: Int64; flags: Integer): Integer; cdecl;

(**
 * Start playing a network-based stream (e.g. RTSP stream) at the
 * current position.
 *)
  Tav_read_playProc = function(s: PAVFormatContext): Integer; cdecl;

(**
 * Pause a network-based stream (e.g. RTSP stream).
 *
 * Use av_read_play() to resume it.
 *)
  Tav_read_pauseProc = function(s: PAVFormatContext): Integer; cdecl;

{$IFDEF FF_API_CLOSE_INPUT_FILE}
(**
 * @deprecated use avformat_close_input()
 * Close a media file (but not its codecs).
 *
 * @param s media file handle
 *)
  Tav_close_input_fileProc = procedure(s: PAVFormatContext); cdecl;
{$ENDIF}

(**
 * Close an opened input AVFormatContext. Free it and all its contents
 * and set *s to NULL.
 *)
  Tavformat_close_inputProc = procedure(s: PPAVFormatContext); cdecl;
(**
 * @}
 *)

{$IFDEF FF_API_NEW_STREAM}
(**
 * Add a new stream to a media file.
 *
 * Can only be called in the read_header() function. If the flag
 * AVFMTCTX_NOHEADER is in the format context, then new streams
 * can be added in read_packet too.
 *
 * @param s media file handle
 * @param id file format dependent stream ID
 *)
  Tav_new_streamProc = function(s: PAVFormatContext; id: Integer): PAVStream; cdecl;
{$ENDIF}

{$IFDEF FF_API_SET_PTS_INFO}
(**
 * @deprecated this function is not supposed to be called outside of lavf
 *)
  Tav_set_pts_infoProc = procedure(s: PAVStream; pts_wrap_bits: Integer;
                     pts_num, pts_den: Cardinal); cdecl;
{$ENDIF}

(**
 * @addtogroup lavf_encoding
 * @{
 *)
(**
 * Allocate the stream private data and write the stream header to
 * an output media file.
 *
 * @param s Media file handle, must be allocated with avformat_alloc_context().
 *          Its oformat field must be set to the desired output format;
 *          Its pb field must be set to an already opened AVIOContext.
 * @param options  An AVDictionary filled with AVFormatContext and muxer-private options.
 *                 On return this parameter will be destroyed and replaced with a dict containing
 *                 options that were not found. May be NULL.
 *
 * @return 0 on success, negative AVERROR on failure.
 *
 * @see av_opt_find, av_dict_set, avio_open, av_oformat_next.
 *)
  Tavformat_write_headerProc = function(s: PAVFormatContext; options: PPAVDictionary): Integer; cdecl;

(**
 * Write a packet to an output media file.
 *
 * The packet shall contain one audio or video frame.
 * The packet must be correctly interleaved according to the container
 * specification, if not then av_interleaved_write_frame must be used.
 *
 * @param s media file handle
 * @param pkt The packet, which contains the stream_index, buf/buf_size,
 *            dts/pts, ...
 *            This can be NULL (at any time, not just at the end), in
 *            order to immediately flush data buffered within the muxer,
 *            for muxers that buffer up data internally before writing it
 *            to the output.
 * @return < 0 on error, = 0 if OK, 1 if flushed and there is no more data to flush
 *)
  Tav_write_frameProc = function(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;

(**
 * Write a packet to an output media file ensuring correct interleaving.
 *
 * The packet must contain one audio or video frame.
 * If the packets are already correctly interleaved, the application should
 * call av_write_frame() instead as it is slightly faster. It is also important
 * to keep in mind that completely non-interleaved input will need huge amounts
 * of memory to interleave with this, so it is preferable to interleave at the
 * demuxer level.
 *
 * @param s media file handle
 * @param pkt The packet containing the data to be written. pkt->buf must be set
 * to a valid AVBufferRef describing the packet data. Libavformat takes
 * ownership of this reference and will unref it when it sees fit. The caller
 * must not access the data through this reference after this function returns.
 * This can be NULL (at any time, not just at the end), to flush the
 * interleaving queues.
 * Packet's @ref AVPacket.stream_index "stream_index" field must be set to the
 * index of the corresponding stream in @ref AVFormatContext.streams
 * "s.streams".
 * It is very strongly recommended that timing information (@ref AVPacket.pts
 * "pts", @ref AVPacket.dts "dts" @ref AVPacket.duration "duration") is set to
 * correct values.
 *
 * @return 0 on success, a negative AVERROR on error.
 *)
  Tav_interleaved_write_frameProc = function(s: PAVFormatContext; pkt: PAVPacket): Integer; cdecl;

(**
 * Write the stream trailer to an output media file and free the
 * file private data.
 *
 * May only be called after a successful call to avformat_write_header.
 *
 * @param s media file handle
 * @return 0 if OK, AVERROR_xxx on error.
 *)
  Tav_write_trailerProc = function(s: PAVFormatContext): Integer; cdecl;

(**
 * Return the output format in the list of registered output formats
 * which best matches the provided parameters, or return NULL if
 * there is no match.
 *
 * @param short_name if non-NULL checks if short_name matches with the
 * names of the registered formats
 * @param filename if non-NULL checks if filename terminates with the
 * extensions of the registered formats
 * @param mime_type if non-NULL checks if mime_type matches with the
 * MIME type of the registered formats
 *)
  Tav_guess_formatProc = function(const short_name: PAnsiChar;
                                  const filename: PAnsiChar;
                                  const mime_type: PAnsiChar): PAVOutputFormat; cdecl;
(**
 * Guess the codec ID based upon muxer and filename.
 *)
  Tav_guess_codecProc = function(fmt: PAVOutputFormat; const short_name: PAnsiChar;
                                 const filename: PAnsiChar; const mime_type: PAnsiChar;
                                 ttype: TAVMediaType): TAVCodecID; cdecl;

(**
 * Get timing information for the data currently output.
 * The exact meaning of "currently output" depends on the format.
 * It is mostly relevant for devices that have an internal buffer and/or
 * work in real time.
 * @param s          media file handle
 * @param stream     stream in the media file
 * @param[out] dts   DTS of the last packet output for the stream, in stream
 *                   time_base units
 * @param[out] wall  absolute time when that packet whas output,
 *                   in microsecond
 * @return  0 if OK, AVERROR(ENOSYS) if the format does not support it
 * Note: some formats or devices may not allow to measure dts and wall
 * atomically.
 *)
  Tav_get_output_timestampProc = function(s: PAVFormatContext; stream: Integer;
                              dts, wall: Int64): Integer; cdecl;


(**
 * @}
 *)


(**
 * @defgroup lavf_misc Utility functions
 * @ingroup libavf
 * @{
 *
 * Miscellaneous utility functions related to both muxing and demuxing
 * (or neither).
 *)

(**
 * Send a nice hexadecimal dump of a buffer to the specified file stream.
 *
 * @param f The file stream pointer where the dump should be sent to.
 * @param buf buffer
 * @param size buffer size
 *
 * @see av_hex_dump_log, av_pkt_dump2, av_pkt_dump_log2
 *)
  Tav_hex_dumpProc = procedure(f: Pointer{FILE}; const buf: PByte; size: Integer); cdecl;

(**
 * Send a nice hexadecimal dump of a buffer to the log.
 *
 * @param avcl A pointer to an arbitrary struct of which the first field is a
 * pointer to an AVClass struct.
 * @param level The importance level of the message, lower values signifying
 * higher importance.
 * @param buf buffer
 * @param size buffer size
 *
 * @see av_hex_dump, av_pkt_dump2, av_pkt_dump_log2
 *)
  Tav_hex_dump_logProc = procedure(avcl: Pointer; level: Integer; const buf: PByte; size: Integer); cdecl;

(**
 * Send a nice dump of a packet to the specified file stream.
 *
 * @param f The file stream pointer where the dump should be sent to.
 * @param pkt packet to dump
 * @param dump_payload True if the payload must be displayed, too.
 * @param st AVStream that the packet belongs to
 *)
  Tav_pkt_dump2Proc = procedure(f: Pointer{FILE}; pkt: PAVPacket; dump_payload: Integer; st: PAVStream); cdecl;

(**
 * Send a nice dump of a packet to the log.
 *
 * @param avcl A pointer to an arbitrary struct of which the first field is a
 * pointer to an AVClass struct.
 * @param level The importance level of the message, lower values signifying
 * higher importance.
 * @param pkt packet to dump
 * @param dump_payload True if the payload must be displayed, too.
 * @param st AVStream that the packet belongs to
 *)
  Tav_pkt_dump_log2Proc = procedure(avcl: Pointer; level: Integer; pkt: PAVPacket; dump_payload: Integer; st: PAVStream); cdecl;

(**
 * Get the AVCodecID for the given codec tag tag.
 * If no codec id is found returns AV_CODEC_ID_NONE.
 *
 * @param tags list of supported codec_id-codec_tag pairs, as stored
 * in AVInputFormat.codec_tag and AVOutputFormat.codec_tag
 *)
  Tav_codec_get_idProc = function(const tags: PPAVCodecTag; tag: Cardinal): TAVCodecID; cdecl;

(**
 * Get the codec tag for the given codec id id.
 * If no codec tag is found returns 0.
 *
 * @param tags list of supported codec_id-codec_tag pairs, as stored
 * in AVInputFormat.codec_tag and AVOutputFormat.codec_tag
 *)
  Tav_codec_get_tagProc = function(const tags: PPAVCodecTag; id: TAVCodecID): Cardinal; cdecl;

(**
 * Get the codec tag for the given codec id.
 *
 * @param tags list of supported codec_id - codec_tag pairs, as stored
 * in AVInputFormat.codec_tag and AVOutputFormat.codec_tag
 * @param id codec id that should be searched for in the list
 * @param tag A pointer to the found tag
 * @return 0 if id was not found in tags, > 0 if it was found
 *)
  Tav_codec_get_tag2Proc = function(const tags: PPAVCodecTag; id: TAVCodecID;
                            tag: PCardinal): Integer; cdecl;

  Tav_find_default_stream_indexProc = function(s: PAVFormatContext): Integer; cdecl;

(**
 * Get the index for a specific timestamp.
 * @param flags if AVSEEK_FLAG_BACKWARD then the returned index will correspond
 *                 to the timestamp which is <= the requested one, if backward
 *                 is 0, then it will be >=
 *              if AVSEEK_FLAG_ANY seek to any frame, only keyframes otherwise
 * @return < 0 if no such timestamp could be found
 *)
  Tav_index_search_timestampProc = function(st: PAVStream; timestamp: Int64; flags: Integer): Integer; cdecl;

(**
 * Add an index entry into a sorted list. Update the entry if the list
 * already contains it.
 *
 * @param timestamp timestamp in the time base of the given stream
 *)
  Tav_add_index_entryProc = function(st: PAVStream; pos: Int64; timestamp: Int64;
                                     size, distance, flags: Integer): Integer; cdecl;


(**
 * Split a URL string into components.
 *
 * The pointers to buffers for storing individual components may be null,
 * in order to ignore that component. Buffers for components not found are
 * set to empty strings. If the port is not found, it is set to a negative
 * value.
 *
 * @param proto the buffer for the protocol
 * @param proto_size the size of the proto buffer
 * @param authorization the buffer for the authorization
 * @param authorization_size the size of the authorization buffer
 * @param hostname the buffer for the host name
 * @param hostname_size the size of the hostname buffer
 * @param port_ptr a pointer to store the port number in
 * @param path the buffer for the path
 * @param path_size the size of the path buffer
 * @param url the URL to split
 *)
  Tav_url_splitProc = procedure(proto: PAnsiChar; proto_size: Integer;
                  authorization: PAnsiChar; authorization_size: Integer;
                  hostname: PAnsiChar; hostname_size: Integer;
                  port_ptr: PInteger;
                  path: PAnsiChar; path_size: Integer;
                  const url: PAnsiChar); cdecl;

  Tav_dump_formatProc = procedure(ic: PAVFormatContext;
                    index: Integer;
                    const url: PAnsiChar;
                    is_output: Integer); cdecl;

(**
 * Return in 'buf' the path with '%d' replaced by a number.
 *
 * Also handles the '%0nd' format where 'n' is the total number
 * of digits and '%%'.
 *
 * @param buf destination buffer
 * @param buf_size destination buffer size
 * @param path numbered sequence string
 * @param number frame number
 * @return 0 if OK, -1 on format error.
 *)
  Tav_get_frame_filenameProc = function(buf: PAnsiChar; buf_size: Integer;
                          const path: PAnsiChar; number: Integer): Integer; cdecl;

(**
 * Check whether filename actually is a numbered sequence generator.
 *
 * @param filename possible numbered sequence string
 * @return 1 if a valid numbered sequence string, 0 otherwise
 *)
  Tav_filename_number_testProc = function(const filename: PAnsiChar): Integer; cdecl;

(**
 * Generate an SDP for an RTP session.
 *
 * Note, this overwrites the id values of AVStreams in the muxer contexts
 * for getting unique dynamic payload types.
 *
 * @param ac array of AVFormatContexts describing the RTP streams. If the
 *           array is composed by only one context, such context can contain
 *           multiple AVStreams (one AVStream per RTP stream). Otherwise,
 *           all the contexts in the array (an AVCodecContext per RTP stream)
 *           must contain only one AVStream.
 * @param n_files number of AVCodecContexts contained in ac
 * @param buf buffer where the SDP will be stored (must be allocated by
 *            the caller)
 * @param size the size of the buffer
 * @return 0 if OK, AVERROR_xxx on error.
 *)
  Tav_sdp_createProc = function(ac: PPAVFormatContext; n_files: Integer; buf: PAnsiChar; size: Integer): Integer; cdecl;

(**
 * Return a positive value if the given filename has one of the given
 * extensions, 0 otherwise.
 *
 * @param extensions a comma-separated list of filename extensions
 *)
  Tav_match_extProc = function(const filename, extensions: PAnsiChar): Integer; cdecl;

(**
 * Test if the given container can store a codec.
 *
 * @param std_compliance standards compliance level, one of FF_COMPLIANCE_*
 *
 * @return 1 if codec with ID codec_id can be stored in ofmt, 0 if it cannot.
 *         A negative number if this information is not available.
 *)
  Tavformat_query_codecProc = function(ofmt: PAVOutputFormat; codec_id: TAVCodecID; std_compliance: Integer): Integer; cdecl;

(**
 * @defgroup riff_fourcc RIFF FourCCs
 * @{
 * Get the tables mapping RIFF FourCCs to libavcodec AVCodecIDs. The tables are
 * meant to be passed to av_codec_get_id()/av_codec_get_tag() as in the
 * following code:
 * @code
 * uint32_t tag = MKTAG('H', '2', '6', '4');
 * const struct AVCodecTag *table[] = { avformat_get_riff_video_tags(), 0 };
 * enum AVCodecID id = av_codec_get_id(table, tag);
 * @endcode
 *)
(**
 * @return the table mapping RIFF FourCCs for video to libavcodec AVCodecID.
 *)
  Tavformat_get_riff_video_tagsProc = function: PAVCodecTag; cdecl;
(**
 * @return the table mapping RIFF FourCCs for audio to AVCodecID.
 *)
  Tavformat_get_riff_audio_tagsProc = function: PAVCodecTag; cdecl;

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
//TODO: API returen record  Tav_guess_sample_aspect_ratioProc = function(format: PAVFormatContext; stream: PAVStream; frame: PAVFrame): TAVRational; cdecl;

(**
 * Guess the frame rate, based on both the container and codec information.
 *
 * @param ctx the format context which the stream is part of
 * @param stream the stream which the frame is part of
 * @param frame the frame for which the frame rate should be determined, may be NULL
 * @return the guessed (valid) frame rate, 0/1 if no idea
 *)
//TODO: API returen record  Tav_guess_frame_rateProc = function(ctx: PAVFormatContext; stream: PAVStream; frame: PAVFrame): TAVRational; cdecl;

(**
 * Check if the stream st contained in s is matched by the stream specifier
 * spec.
 *
 * See the "stream specifiers" chapter in the documentation for the syntax
 * of spec.
 *
 * @return  >0 if st is matched by spec;
 *          0  if st is not matched by spec;
 *          AVERROR code if spec is invalid
 *
 * @note  A stream specifier can match several streams in the format.
 *)
  Tavformat_match_stream_specifierProc = function(s: PAVFormatContext; st: PAVStream;
                                    const spec: PAnsiChar): Integer; cdecl;

  Tavformat_queue_attached_picturesProc = function(s: PAVFormatContext): Integer; cdecl;


(**
 * @}
 *)

(**
 * @}
 *)

(****** TODO: check from libavformat/internal.h **************)
  Tff_guess_image2_codecProc = function(const filename: PAnsiChar): TAVCodecID; cdecl;

implementation

end.
