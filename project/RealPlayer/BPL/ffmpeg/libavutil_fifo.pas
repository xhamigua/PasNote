(*
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
 * Original file: libavutil/fifo.h
 * Ported by CodeCoolie@CNSW 2008/03/25 -> $Date:: 2013-02-05 #$
 *)

unit libavutil_fifo;

interface

{$I CompilerDefines.inc}

{$I libversion.inc}

(**
 * @file libavutil/fifo.h
 * a very simple circular buffer FIFO implementation
 *)

type
  PAVFifoBuffer = ^TAVFifoBuffer;
  TAVFifoBuffer = record
    buffer: PByte;
    rptr, wptr, eend: PByte;
    rndx, wndx: Cardinal;
  end;

(**
 * Initialize an AVFifoBuffer.
 * @param size of FIFO
 * @return AVFifoBuffer or NULL if mem allocation failure
 *)
  Tav_fifo_allocProc = function(size: Cardinal): PAVFifoBuffer; cdecl;

(**
 * Free an AVFifoBuffer.
 * @param f AVFifoBuffer to free
 *)
  Tav_fifo_freeProc = procedure(f: PAVFifoBuffer); cdecl;

(**
 * Reset the AVFifoBuffer to the state right after av_fifo_alloc, in particular it is emptied.
 * @param f AVFifoBuffer to reset
 *)
  Tav_fifo_resetProc = procedure(f: PAVFifoBuffer); cdecl;

(**
 * Return the amount of data in bytes in the AVFifoBuffer, that is the
 * amount of data you can read from it.
 * @param f AVFifoBuffer to read from
 * @return size
 *)
  Tav_fifo_sizeProc = function(f: PAVFifoBuffer): Integer; cdecl;

(**
 * Return the amount of space in bytes in the AVFifoBuffer, that is the
 * amount of data you can write into it.
 * @param f AVFifoBuffer to write into
 * @return size
 *)
  Tav_fifo_spaceProc = function(f: PAVFifoBuffer): Integer; cdecl;

(**
 * Feed data from an AVFifoBuffer to a user-supplied callback.
 * @param f AVFifoBuffer to read from
 * @param buf_size number of bytes to read
 * @param func generic read function
 * @param dest data destination
 *)
  TfifoCall = procedure(v1, v2: Pointer; i: Integer); cdecl;
  Tav_fifo_generic_readProc = function(f: PAVFifoBuffer; dest: Pointer; buf_size: Integer; func: TfifoCall): Integer; cdecl;

(**
 * Feed data from a user-supplied callback to an AVFifoBuffer.
 * @param f AVFifoBuffer to write to
 * @param src data source; non-const since it may be used as a
 * modifiable context by the function defined in func
 * @param size number of bytes to write
 * @param func generic write function; the first parameter is src,
 * the second is dest_buf, the third is dest_buf_size.
 * func must return the number of bytes written to dest_buf, or <= 0 to
 * indicate no more data available to write.
 * If func is NULL, src is interpreted as a simple byte array for source data.
 * @return the number of bytes written to the FIFO
 *)
  TwriteCall = function(p1, p2: Pointer; i: Integer): Integer; cdecl;
  Tav_fifo_generic_writeProc = function(f: PAVFifoBuffer; src: Pointer; size: Integer; func: TwriteCall): Integer; cdecl;

(**
 * Resize an AVFifoBuffer.
 * In case of reallocation failure, the old FIFO is kept unchanged.
 *
 * @param f AVFifoBuffer to resize
 * @param size new AVFifoBuffer size in bytes
 * @return <0 for failure, >=0 otherwise
 *)
  Tav_fifo_realloc2Proc = function(f: PAVFifoBuffer; size: Cardinal): Integer; cdecl;

(**
 * Enlarge an AVFifoBuffer.
 * In case of reallocation failure, the old FIFO is kept unchanged.
 * The new fifo size may be larger than the requested size.
 *
 * @param f AVFifoBuffer to resize
 * @param additional_space the amount of space in bytes to allocate in addition to av_fifo_size()
 * @return <0 for failure, >=0 otherwise
 *)
  Tav_fifo_growProc = function(f: PAVFifoBuffer; additional_space: Cardinal): Integer; cdecl;

(**
 * Read and discard the specified amount of data from an AVFifoBuffer.
 * @param f AVFifoBuffer to read from
 * @param size amount of data to read in bytes
 *)
  Tav_fifo_drainProc = procedure(f: PAVFifoBuffer; size: Integer); cdecl;

(**
 * Return a pointer to the data stored in a FIFO buffer at a certain offset.
 * The FIFO buffer is not modified.
 *
 * @param f    AVFifoBuffer to peek at, f must be non-NULL
 * @param offs an offset in bytes, its absolute value must be less
 *             than the used buffer size or the returned pointer will
 *             point outside to the buffer data.
 *             The used buffer size can be checked with av_fifo_size().
 *)
function av_fifo_peek2(const f: PAVFifoBuffer; offs: Integer): PByte; {$IFDEF USE_INLINE}inline;{$ENDIF}

implementation

function av_fifo_peek2(const f: PAVFifoBuffer; offs: Integer): PByte;
var
  ptr: PByte;
begin
  ptr := f^.rptr;
  Inc(ptr, offs);
  if Cardinal(ptr) >= Cardinal(f^.eend) then
    Dec(ptr, Cardinal(f^.eend) - Cardinal(f^.buffer))
  else if Cardinal(ptr) < Cardinal(f^.buffer) then
    Inc(ptr, Cardinal(f^.eend) - Cardinal(f^.buffer));
  Result := ptr;
end;

end.
