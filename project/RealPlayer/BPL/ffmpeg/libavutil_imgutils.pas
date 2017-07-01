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
 * Original file: libavcore/imgutils.h
 * Ported by CodeCoolie@CNSW 2010/09/17 -> 2011-01-21
 * Original file: libavutil/imgutils.h
 * Ported by CodeCoolie@CNSW 2011/07/02 -> $Date:: 2013-02-05 #$
 *)

unit libavutil_imgutils;

interface

{$I CompilerDefines.inc}

uses
{$IFDEF BCB}
  BCBTypes,
{$ENDIF}
  libavutil,
  libavutil_pixdesc,
  libavutil_pixfmt;

{$I libversion.inc}

(**
 * @file
 * misc image utilities
 *
 * @addtogroup lavu_picture
 * @{
 *)

type
(**
 * Compute the max pixel step for each plane of an image with a
 * format described by pixdesc.
 *
 * The pixel step is the distance in bytes between the first byte of
 * the group of bytes which describe a pixel component and the first
 * byte of the successive group in the same plane for the same
 * component.
 *
 * @param max_pixsteps an array which is filled with the max pixel step
 * for each plane. Since a plane may contain different pixel
 * components, the computed max_pixsteps[plane] is relative to the
 * component in the plane with the max pixel step.
 * @param max_pixstep_comps an array which is filled with the component
 * for each plane which has the max pixel step. May be NULL.
 *)
  Tav_image_fill_max_pixstepsProc = procedure(max_pixsteps, max_pixstep_comps: PInteger{array[0..3] of Integer};
                                              const pixdesc: PAVPixFmtDescriptor);

(**
 * Compute the size of an image line with format pix_fmt and width
 * width for the plane plane.
 *
 * @return the computed size in bytes
 *)
  Tav_image_get_linesizeProc = function(pix_fmt: TAVPixelFormat; width, plane: Integer): Integer; cdecl;

(**
 * Fill plane linesizes for an image with pixel format pix_fmt and
 * width width.
 *
 * @param linesizes array to be filled with the linesize for each plane
 * @return >= 0 in case of success, a negative error code otherwise
 *)
  Tav_image_fill_linesizesProc = function(linesizes: PInteger{array[0..3] of Integer}; pix_fmt: TAVPixelFormat; width: Integer): Integer; cdecl;

(**
 * Fill plane data pointers for an image with pixel format pix_fmt and
 * height height.
 *
 * @param data pointers array to be filled with the pointer for each image plane
 * @param ptr the pointer to a buffer which will contain the image
 * @param linesizes the array containing the linesize for each
 * plane, should be filled by av_image_fill_linesizes()
 * @return the size in bytes required for the image buffer, a negative
 * error code in case of failure
 *)
  Tav_image_fill_pointersProc = function(data: PPByte{array[0..3] of PByte}; pix_fmt: TAVPixelFormat; height: Integer;
                                         ptr: PByte; linesizes: PInteger{array[0..3] of Integer}): Integer; cdecl;

(**
 * Allocate an image with size w and h and pixel format pix_fmt, and
 * fill pointers and linesizes accordingly.
 * The allocated image buffer has to be freed by using
 * av_freep(&pointers[0]).
 *
 * @param align the value to use for buffer size alignment
 * @return the size in bytes required for the image buffer, a negative
 * error code in case of failure
 *)
  Tav_image_allocProc = function(pointers: PPByte{array[0..3] of PByte}; linesizes: PInteger{array[0..3] of Integer};
                   w, h: Integer; pix_fmt: TAVPixelFormat; align: Integer): Integer; cdecl;

(**
 * Copy image plane from src to dst.
 * That is, copy "height" number of lines of "bytewidth" bytes each.
 * The first byte of each successive line is separated by *_linesize
 * bytes.
 *
 * bytewidth must be contained by both absolute values of dst_linesize
 * and src_linesize, otherwise the function behavior is undefined.
 *
 * @param dst_linesize linesize for the image plane in dst
 * @param src_linesize linesize for the image plane in src
 *)
  Tav_image_copy_planeProc = procedure(dst: PByte; dst_linesize: Integer;
                                       const src: PByte; src_linesize: Integer;
                                       bytewidth, height: Integer); cdecl;

(**
 * Copy image in src_data to dst_data.
 *
 * @param dst_linesizes linesizes for the image in dst_data
 * @param src_linesizes linesizes for the image in src_data
 *)
  Tav_image_copyProc = procedure(dst_data: PPByte{array[0..3] of PByte}; dst_linesizes: PInteger{array[0..3] of Integer};
                                 src_data: PPByte{array[0..3] of PByte}; src_linesizes: PInteger{array[0..3] of Integer};
                                 pix_fmt: TAVPixelFormat; width, height: Integer); cdecl;

(**
 * Setup the data pointers and linesizes based on the specified image
 * parameters and the provided array.
 *
 * The fields of the given image are filled in by using the src
 * address which points to the image data buffer. Depending on the
 * specified pixel format, one or multiple image data pointers and
 * line sizes will be set.  If a planar format is specified, several
 * pointers will be set pointing to the different picture planes and
 * the line sizes of the different planes will be stored in the
 * lines_sizes array. Call with src == NULL to get the required
 * size for the src buffer.
 *
 * To allocate the buffer and fill in the dst_data and dst_linesize in
 * one call, use av_image_alloc().
 *
 * @param dst_data      data pointers to be filled in
 * @param dst_linesizes linesizes for the image in dst_data to be filled in
 * @param src           buffer which will contain or contains the actual image data, can be NULL
 * @param pix_fmt       the pixel format of the image
 * @param width         the width of the image in pixels
 * @param height        the height of the image in pixels
 * @param align         the value used in src for linesize alignment
 * @return the size in bytes required for src, a negative error code
 * in case of failure
 *)
  Tav_image_fill_arraysProc = function(dst_data: PPByte{array[0..3] of PByte}; dst_linesize: PInteger{array[0..3] of Integer};
                                        const src: PByte; pix_fmt: TAVPixelFormat;
                                        width, height, align: Integer): Integer; cdecl;

(**
 * Return the size in bytes of the amount of data required to store an
 * image with the given parameters.
 *
 * @param[in] align the assumed linesize alignment
 *)
  Tav_image_get_buffer_sizeProc = function(pix_fmt: TAVPixelFormat; width, height, align: Integer): Integer; cdecl;

(**
 * Copy image data from an image into a buffer.
 *
 * av_image_get_buffer_size() can be used to compute the required size
 * for the buffer to fill.
 *
 * @param dst           a buffer into which picture data will be copied
 * @param dst_size      the size in bytes of dst
 * @param src_data      pointers containing the source image data
 * @param src_linesizes linesizes for the image in src_data
 * @param pix_fmt       the pixel format of the source image
 * @param width         the width of the source image in pixels
 * @param height        the height of the source image in pixels
 * @param align         the assumed linesize alignment for dst
 * @return the number of bytes written to dst, or a negative value
 * (error code) on error
 *)
  Tav_image_copy_to_bufferProc = function(dst: PByte; dst_size: Integer;
                            const src_data: PPByte{array[0..3] of PByte}; const src_linesize: PInteger{array[0..3] of Integer};
                            pix_fmt: TAVPixelFormat; width, height, align: Integer): Integer; cdecl;

(**
 * Check if the given dimension of an image is valid, meaning that all
 * bytes of the image can be addressed with a signed int.
 *
 * @param w the width of the picture
 * @param h the height of the picture
 * @param log_offset the offset to sum to the log level for logging with log_ctx
 * @param log_ctx the parent logging context, it may be NULL
 * @return >= 0 if valid, a negative error code otherwise
 *)
  Tav_image_check_sizeProc = function(w, h: Cardinal; log_offset: Integer; log_ctx: Pointer): Integer; cdecl;

  Tavpriv_set_systematic_pal2Proc = function(pal: PCardinal; pix_fmt: TAVPixelFormat): Integer; cdecl;

(**
 * @}
 *)

implementation

end.

