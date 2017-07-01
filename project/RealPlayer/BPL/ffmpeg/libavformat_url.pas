(*
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
 * Original file: libavformat/url.h
 * Ported by CodeCoolie@CNSW 2012/10/30 -> $Date:: 2012-12-01 #$
 *)

unit libavformat_url;

interface

{$I CompilerDefines.inc}

uses
  libavformat_avio,
  libavutil_dict,
  libavutil_log;

{$I libversion.inc}

(**
 * @file
 * unbuffered private I/O API
 *)

const
  URL_PROTOCOL_FLAG_NESTED_SCHEME = 1; (*< The protocol name can be the first part of a nested protocol scheme *)
  URL_PROTOCOL_FLAG_NETWORK       = 2; (*< The protocol uses network *)

// TODO: check update url.h which is internal header

//extern int (*url_interrupt_cb)(void);

//extern const AVClass ffurl_context_class;

type
  PPURLProtocol = ^PURLProtocol;
  PURLProtocol = ^TURLProtocol;
  PPURLContext = ^PURLContext;
  PURLContext = ^TURLContext;
  TURLContext = record
    av_class: PAVClass;         (**< information for av_log(). Set by url_open(). *)
    prot: PURLProtocol;
    priv_data: Pointer;
    filename: PAnsiChar;        (**< specified URL *)
    flags: Integer;
    max_packet_size: Integer;   (**< if non zero, the stream is packetized with this max packet size *)
    is_streamed: Integer;       (**< true if streamed (no seek possible), default = false *)
    is_connected: Integer;
    interrupt_callback: TAVIOInterruptCB;
    rw_timeout: Int64;          (**< maximum time to wait for (network) read/write operation completion, in mcs *)
  end;

  PPInteger = ^PInteger;
  TURLProtocol = record
    name: PAnsiChar;
    url_open: function(h: PURLContext; const url: PAnsiChar; flags: Integer): Integer; cdecl;
    (**
     * This callback is to be used by protocols which open further nested
     * protocols. options are then to be passed to ffurl_open()/ffurl_connect()
     * for those nested protocols.
     *)
    url_open2: function(h: PURLContext; const url: PAnsiChar; flags: Integer; options: PPAVDictionary): Integer; cdecl;

    (**
     * Read data from the protocol.
     * If data is immediately available (even less than size), EOF is
     * reached or an error occurs (including EINTR), return immediately.
     * Otherwise:
     * In non-blocking mode, return AVERROR(EAGAIN) immediately.
     * In blocking mode, wait for data/EOF/error with a short timeout (0.1s),
     * and return AVERROR(EAGAIN) on timeout.
     * Checking interrupt_callback, looping on EINTR and EAGAIN and until
     * enough data has been read is left to the calling function; see
     * retry_transfer_wrapper in avio.c.
     *)
    url_read: function(h: PURLContext; buf: PAnsiChar; size: Integer): Integer; cdecl;
    url_write: function(h: PURLContext; const buf: PAnsiChar; size: Integer): Integer; cdecl;
    url_seek: function(h: PURLContext; pos: Int64; whence: Integer): Int64; cdecl;
    url_close: function(h: PURLContext): Integer; cdecl;
    next: PURLProtocol;
    url_read_pause: function(h: PURLContext; pause: Integer): Integer; cdecl;
    url_read_seek: function(h: PURLContext; stream_index: Integer;
                             timestamp: Int64; flags: Integer): Int64; cdecl;
    url_get_file_handle: function(h: PURLContext): Integer; cdecl;
    url_get_multi_file_handle: function(h: PURLContext; handles: PPInteger;
                                     numhandles: PInteger): Integer; cdecl;
    url_shutdown: function(h: PURLContext; flags: Integer): Integer; cdecl;
    priv_data_size: Integer;
    priv_data_class: PAVClass;
    flags: Integer;
    url_check: function(h: PURLContext; mask: Integer): Integer; cdecl;
  end;

(**
 * Create a URLContext for accessing to the resource indicated by
 * url, but do not initiate the connection yet.
 *
 * @param puc pointer to the location where, in case of success, the
 * function puts the pointer to the created URLContext
 * @param flags flags which control how the resource indicated by url
 * is to be opened
 * @param int_cb interrupt callback to use for the URLContext, may be
 * NULL
 * @return 0 in case of success, a negative value corresponding to an
 * AVERROR code in case of failure
 *)
  Tffurl_allocProc = function(puc: PPURLContext; const filename: PAnsiChar; flags: Integer;
                const int_cb: PAVIOInterruptCB): Integer; cdecl;

(**
 * Connect an URLContext that has been allocated by ffurl_alloc
 *
 * @param options  A dictionary filled with options for nested protocols,
 * i.e. it will be passed to url_open2() for protocols implementing it.
 * This parameter will be destroyed and replaced with a dict containing options
 * that were not found. May be NULL.
 *)
  Tffurl_connectProc = function(uc: PURLContext; options: PPAVDictionary): Integer; cdecl;

(**
 * Create an URLContext for accessing to the resource indicated by
 * url, and open it.
 *
 * @param puc pointer to the location where, in case of success, the
 * function puts the pointer to the created URLContext
 * @param flags flags which control how the resource indicated by url
 * is to be opened
 * @param int_cb interrupt callback to use for the URLContext, may be
 * NULL
 * @param options  A dictionary filled with protocol-private options. On return
 * this parameter will be destroyed and replaced with a dict containing options
 * that were not found. May be NULL.
 * @return 0 in case of success, a negative value corresponding to an
 * AVERROR code in case of failure
 *)
  Tffurl_openProc = function(puc: PPURLContext; const filename: PAnsiChar; flags: Integer;
               const int_cb: PAVIOInterruptCB; options: PPAVDictionary): Integer; cdecl;

(**
 * Read up to size bytes from the resource accessed by h, and store
 * the read bytes in buf.
 *
 * @return The number of bytes actually read, or a negative value
 * corresponding to an AVERROR code in case of error. A value of zero
 * indicates that it is not possible to read more from the accessed
 * resource (except if the value of the size argument is also zero).
 *)
  Tffurl_readProc = function(h: PURLContext; buf: PByte; size: Integer): Integer; cdecl;

(**
 * Read as many bytes as possible (up to size), calling the
 * read function multiple times if necessary.
 * This makes special short-read handling in applications
 * unnecessary, if the return value is < size then it is
 * certain there was either an error or the end of file was reached.
 *)
  Tffurl_read_completeProc = function(h: PURLContext; buf: PByte; size: Integer): Integer; cdecl;

(**
 * Write size bytes from buf to the resource accessed by h.
 *
 * @return the number of bytes actually written, or a negative value
 * corresponding to an AVERROR code in case of failure
 *)
  Tffurl_writeProc = function(h: PURLContext; const buf: PByte; size: Integer): Integer; cdecl;

(**
 * Change the position that will be used by the next read/write
 * operation on the resource accessed by h.
 *
 * @param pos specifies the new position to set
 * @param whence specifies how pos should be interpreted, it must be
 * one of SEEK_SET (seek from the beginning), SEEK_CUR (seek from the
 * current position), SEEK_END (seek from the end), or AVSEEK_SIZE
 * (return the filesize of the requested resource, pos is ignored).
 * @return a negative value corresponding to an AVERROR code in case
 * of failure, or the resulting file position, measured in bytes from
 * the beginning of the file. You can use this feature together with
 * SEEK_CUR to read the current file position.
 *)
  Tffurl_seekProc = function(h: PURLContext; pos: Int64; whence: Integer): Int64; cdecl;

(**
 * Close the resource accessed by the URLContext h, and free the
 * memory used by it. Also set the URLContext pointer to NULL.
 *
 * @return a negative value if an error condition occurred, 0
 * otherwise
 *)
  Tffurl_closepProc = function(h: PPURLContext): Integer; cdecl;
  Tffurl_closeProc = function(h: PURLContext): Integer; cdecl;

(**
 * Return the filesize of the resource accessed by h, AVERROR(ENOSYS)
 * if the operation is not supported by h, or another negative value
 * corresponding to an AVERROR error code in case of failure.
 *)
  Tffurl_sizeProc = function(h: PURLContext): Int64; cdecl;

(**
 * Return the file descriptor associated with this URL. For RTP, this
 * will return only the RTP file descriptor, not the RTCP file descriptor.
 *
 * @return the file descriptor associated with this URL, or <0 on error.
 *)
  Tffurl_get_file_handleProc = function(h: PURLContext): Integer; cdecl;

(**
 * Return the file descriptors associated with this URL.
 *
 * @return 0 on success or <0 on error.
 *)
  Tffurl_get_multi_file_handleProc = function(h: PURLContext; handles: PPInteger; numhandles: Integer): Integer; cdecl;

(**
 * Signal the URLContext that we are done reading or writing the stream.
 *
 * @param h pointer to the resource
 * @param flags flags which control how the resource indicated by url
 * is to be shutdown
 *
 * @return a negative value if an error condition occurred, 0
 * otherwise
 *)
  Tffurl_shutdownProc = function(h: PURLContext; flags: Integer): Integer; cdecl;

(**
 * Register the URLProtocol protocol.
 *
 * @param size the size of the URLProtocol struct referenced
 *)
  Tffurl_register_protocolProc = function(protocol: PURLProtocol; size: Integer): Integer; cdecl;

(**
 * Check if the user has requested to interrup a blocking function
 * associated with cb.
 *)
  Tff_check_interruptProc = function(cb: PAVIOInterruptCB): Integer; cdecl;

(**
 * Iterate over all available protocols.
 *
 * @param prev result of the previous call to this functions or NULL.
 *)
  Tffurl_protocol_nextProc = function(prev: PURLProtocol): PURLProtocol; cdecl;

(* udp.c *)
  Tff_udp_set_remote_urlProc = function(h: PURLContext; const uri: PAnsiChar): Integer; cdecl;
  Tff_udp_get_local_portProc = function(h: PURLContext): Integer; cdecl;

implementation

end.
