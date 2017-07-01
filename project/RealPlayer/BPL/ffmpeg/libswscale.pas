(*
 * Copyright (C) 2001-2011 Michael Niedermayer <michaelni@gmx.at>
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
 * Original file: libswscale/swscale.h
 * Ported by CodeCoolie@CNSW 2008/03/20 -> $Date:: 2013-11-18 #$
 *)

unit libswscale;

interface

{$I CompilerDefines.inc}

uses
  libavutil,
  libavutil_log,
  libavutil_pixfmt;

{$I libversion.inc}

(**
 * @file
 * @ingroup lsws
 * external API header
 *)

(**
 * @defgroup lsws Libswscale
 * @{
 *)

type
(**
 * Return the LIBSWSCALE_VERSION_INT constant.
 *)
  Tswscale_versionProc = function: Cardinal; cdecl;

(**
 * Return the libswscale build-time configuration.
 *)
  Tswscale_configurationProc = function: PAnsiChar; cdecl;

(**
 * Return the libswscale license.
 *)
  Tswscale_licenseProc = function: PAnsiChar; cdecl;

const
(* values for the flags, the stuff on the command line is different *)
  SWS_FAST_BILINEAR = $0001;
  SWS_BILINEAR      = $0002;
  SWS_BICUBIC       = $0004;
  SWS_X             = $0008;
  SWS_POINT         = $0010;
  SWS_AREA          = $0020;
  SWS_BICUBLIN      = $0040;
  SWS_GAUSS         = $0080;
  SWS_SINC          = $0100;
  SWS_LANCZOS       = $0200;
  SWS_SPLINE        = $0400;

  SWS_SRC_V_CHR_DROP_MASK  = $30000;
  SWS_SRC_V_CHR_DROP_SHIFT = 16;

  SWS_PARAM_DEFAULT        = 123456;

  SWS_PRINT_INFO           = $1000;

//the following 3 flags are not completely implemented
//internal chrominace subsampling info
  SWS_FULL_CHR_H_INT    = $2000;
//input subsampling info
  SWS_FULL_CHR_H_INP    = $4000;
  SWS_DIRECT_BGR        = $8000;
  SWS_ACCURATE_RND      = $40000;
  SWS_BITEXACT          = $80000;
  SWS_ERROR_DIFFUSION   = $800000;

{$IFDEF FF_API_SWS_CPU_CAPS}
(**
 * CPU caps are autodetected now, those flags
 * are only provided for API compatibility.
 *)
  SWS_CPU_CAPS_MMX      = $80000000;
  SWS_CPU_CAPS_MMXEXT   = $20000000;
  SWS_CPU_CAPS_MMX2     = $20000000;
  SWS_CPU_CAPS_3DNOW    = $40000000;
  SWS_CPU_CAPS_ALTIVEC  = $10000000;
  SWS_CPU_CAPS_BFIN     = $01000000;
  SWS_CPU_CAPS_SSE2     = $02000000;
{$ENDIF}

  SWS_MAX_REDUCE_CUTOFF = 0.002;

  SWS_CS_ITU709         = 1;
  SWS_CS_FCC            = 4;
  SWS_CS_ITU601         = 5;
  SWS_CS_ITU624         = 5;
  SWS_CS_SMPTE170M      = 5;
  SWS_CS_SMPTE240M      = 7;
  SWS_CS_DEFAULT        = 5;

type
(**
 * Return a pointer to yuv<->rgb coefficients for the given colorspace
 * suitable for sws_setColorspaceDetails().
 *
 * @param colorspace One of the SWS_CS_* macros. If invalid,
 * SWS_CS_DEFAULT is used.
 *)
  Tsws_getCoefficientsProc = function(colorspace: Integer): Integer; cdecl;

// when used for filters they must have an odd number of elements
// coeffs cannot be shared between vectors
  PSwsVector = ^TSwsVector;
  TSwsVector = record
    coeff: PDouble;             ///< pointer to the list of coefficients
    length: Integer;            ///< number of coefficients in the vector
  end;

// vectors can be shared
  PSwsFilter = ^TSwsFilter;
  TSwsFilter = record
    lumH: PSwsVector;
    lumV: PSwsVector;
    chrH: PSwsVector;
    chrV: PSwsVector;
  end;

  PSwsContext = ^TSwsContext;
  TSwsContext = record
{$IFDEF XXX}
    (**
     * info on struct for av_log
     *)
    av_class: Pointer; // PAVClass;

    (**
     * Note that src, dst, srcStride, dstStride will be copied in the
     * sws_scale() wrapper so they can be freely modified here.
     *)
    swScale: Pointer; // SwsFunc;
    srcW, srcH, dstH: Integer;
    chrSrcW, chrSrcH, chrDstW, chrDstH: Integer;
    lumXInc, chrXInc: Integer;
    lumYInc, chrYInc: Integer;
    dstFormat, srcFormat: Integer;               ///< format 4:2:0 type is always YV12
    origDstFormat, origSrcFormat: Integer;       ///< format
    chrSrcHSubSample, chrSrcVSubSample: Integer;
    chrIntHSubSample, chrIntVSubSample: Integer;
    chrDstHSubSample, chrDstVSubSample: Integer;
    vChrDrop: Integer;
    sliceDir: Integer;

    // more ...
{$ENDIF}
  end;

(**
 * Return a positive value if pix_fmt is a supported input format, 0
 * otherwise.
 *)
  Tsws_isSupportedInputProc = function(pix_fmt: TAVPixelFormat): Integer; cdecl;

(**
 * Return a positive value if pix_fmt is a supported output format, 0
 * otherwise.
 *)
  Tsws_isSupportedOutputProc = function(pix_fmt: TAVPixelFormat): Integer; cdecl;

(**
 * @param[in]  pix_fmt the pixel format
 * @return a positive value if an endianness conversion for pix_fmt is
 * supported, 0 otherwise.
 *)
  Tsws_isSupportedEndiannessConversionProc = function(pix_fmt: TAVPixelFormat): Integer; cdecl;

(**
 * Allocate an empty SwsContext. This must be filled and passed to
 * sws_init_context(). For filling see AVOptions, options.c and
 * sws_setColorspaceDetails().
 *)
  Tsws_alloc_contextProc = function: PSwsContext; cdecl;

(**
 * Initialize the swscaler context sws_context.
 *
 * @return zero or positive value on success, a negative value on
 * error
 *)
  Tsws_init_contextProc = function(sws_context: PSwsContext; srcFilter, dstFilter: PSwsFilter): Integer; cdecl;

(**
 * Free the swscaler context swsContext.
 * If swsContext is NULL, then does nothing.
 *)
  Tsws_freeContextProc = procedure(swsContext: PSwsContext); cdecl;

{$IFDEF FF_API_SWS_GETCONTEXT}
(**
 * Allocate and return a SwsContext. You need it to perform
 * scaling/conversion operations using sws_scale().
 *
 * @param srcW the width of the source image
 * @param srcH the height of the source image
 * @param srcFormat the source image format
 * @param dstW the width of the destination image
 * @param dstH the height of the destination image
 * @param dstFormat the destination image format
 * @param flags specify which algorithm and options to use for rescaling
 * @return a pointer to an allocated context, or NULL in case of error
 * @note this function is to be removed after a saner alternative is
 *       written
 * @deprecated Use sws_getCachedContext() instead.
 *)
  Tsws_getContextProc = function(srcW, srcH: Integer; srcFormat: TAVPixelFormat;
                                  dstW, dstH: Integer; dstFormat: TAVPixelFormat;
                                  flags: Integer; srcFilter, dstFilter: PSwsFilter;
                                  param: PDouble): PSwsContext; cdecl;
{$ENDIF}

(**
 * Scale the image slice in srcSlice and put the resulting scaled
 * slice in the image in dst. A slice is a sequence of consecutive
 * rows in an image.
 *
 * Slices have to be provided in sequential order, either in
 * top-bottom or bottom-top order. If slices are provided in
 * non-sequential order the behavior of the function is undefined.
 *
 * @param c         the scaling context previously created with
 *                  sws_getContext()
 * @param srcSlice  the array containing the pointers to the planes of
 *                  the source slice
 * @param srcStride the array containing the strides for each plane of
 *                  the source image
 * @param srcSliceY the position in the source image of the slice to
 *                  process, that is the number (counted starting from
 *                  zero) in the image of the first row of the slice
 * @param srcSliceH the height of the source slice, that is the number
 *                  of rows in the slice
 * @param dst       the array containing the pointers to the planes of
 *                  the destination image
 * @param dstStride the array containing the strides for each plane of
 *                  the destination image
 * @return          the height of the output slice
 *)
  Tsws_scaleProc = function(c: PSwsContext; const srcSlice: PPByte;
                    const srcStride: PInteger; srcSliceY, srcSliceH: Integer;
                    const dst: PPByte; const dstStride: PInteger): Integer; cdecl;

(**
 * @param dstRange flag indicating the while-black range of the output (1=jpeg / 0=mpeg)
 * @param srcRange flag indicating the while-black range of the input (1=jpeg / 0=mpeg)
 * @param table the yuv2rgb coefficients describing the output yuv space, normally ff_yuv2rgb_coeffs[x]
 * @param inv_table the yuv2rgb coefficients describing the input yuv space, normally ff_yuv2rgb_coeffs[x]
 * @param brightness 16.16 fixed point brightness correction
 * @param contrast 16.16 fixed point contrast correction
 * @param saturation 16.16 fixed point saturation correction
 * @return -1 if not supported
 *)
  Tsws_setColorspaceDetailsProc = function(c: PSwsContext; inv_table: array{[0..3]} of Integer;
                             srcRange: Integer; table: array{[0..3]} of Integer; dstRange: Integer;
                             brightness, contrast, saturation: Integer): Integer; cdecl;
  PPInteger = ^PInteger;
(**
 * @return -1 if not supported
 *)
  Tsws_getColorspaceDetailsProc = function(c: PSwsContext; inv_table: PPInteger; srcRange: PInteger; table: PPInteger; dstRange, brightness, contrast, saturation: PInteger): Integer; cdecl;

(**
 * Allocate and return an uninitialized vector with length coefficients.
 *)
  Tsws_allocVecProc = function(length: Integer): PSwsVector; cdecl;

(**
 * Return a normalized Gaussian curve used to filter stuff
 * quality = 3 is high quality, lower is lower quality.
 *)
  Tsws_getGaussianVecProc = function(variance, quality: Double): PSwsVector; cdecl;

(**
 * Allocate and return a vector with length coefficients, all
 * with the same value c.
 *)
  Tsws_getConstVecProc = function(c: Double; length: Integer): PSwsVector; cdecl;

(**
 * Allocate and return a vector with just one coefficient, with
 * value 1.0.
 *)
  Tsws_getIdentityVecProc = function: PSwsVector; cdecl;

(**
 * Scale all the coefficients of a by the scalar value.
 *)
  Tsws_scaleVecProc = procedure(a: PSwsVector; scalar: Double); cdecl;

(**
 * Scale all the coefficients of a so that their sum equals height.
 *)
  Tsws_normalizeVecProc = procedure(a: PSwsVector; height: Double); cdecl;
  Tsws_convVecProc = procedure(a, b: PSwsVector); cdecl;
  Tsws_addVecProc = procedure(a, b: PSwsVector); cdecl;
  Tsws_subVecProc = procedure(a, b: PSwsVector); cdecl;
  Tsws_shiftVecProc = procedure(a: PSwsVector; shift: Integer); cdecl;

(**
 * Allocate and return a clone of the vector a, that is a vector
 * with the same coefficients as a.
 *)
  Tsws_cloneVecProc = function(a: PSwsVector): PSwsVector; cdecl;

(**
 * Print with av_log() a textual representation of the vector a
 * if log_level <= av_log_level.
 *)
  Tsws_printVec2Proc = procedure(a: PSwsVector; log_ctx: Pointer{PAVClass}; log_level: Integer); cdecl;

  Tsws_freeVecProc = procedure(a: PSwsVector); cdecl;

  Tsws_getDefaultFilterProc = function(lumaGBlur, chromaGBlur,
                                lumaSharpen, chromaSharpen,
                                chromaHShift, chromaVShift: Single;
                                verbose: Integer): PSwsFilter; cdecl;
  Tsws_freeFilterProc = procedure(filter: PSwsFilter); cdecl;

(**
 * Check if context can be reused, otherwise reallocate a new one.
 *
 * If context is NULL, just calls sws_getContext() to get a new
 * context. Otherwise, checks if the parameters are the ones already
 * saved in context. If that is the case, returns the current
 * context. Otherwise, frees context and gets a new context with
 * the new parameters.
 *
 * Be warned that srcFilter and dstFilter are not checked, they
 * are assumed to remain the same.
 *)
  Tsws_getCachedContextProc = function(context: PSwsContext;
                                        srcW, srcH, srcFormat,
                                        dstW, dstH, dstFormat, flags: Integer;
                                        srcFilter, dstFilter: PSwsFilter; const param: PDouble): PSwsContext; cdecl;

(**
 * Convert an 8-bit paletted frame into a frame with a color depth of 32 bits.
 *
 * The output frame will have the same packed format as the palette.
 *
 * @param src        source frame buffer
 * @param dst        destination frame buffer
 * @param num_pixels number of pixels to convert
 * @param palette    array with [256] entries, which must match color arrangement (RGB or BGR) of src
 *)
  Tsws_convertPalette8ToPacked32Proc = procedure(src, dst: PByte; num_pixels: Integer; palette: PByte); cdecl;

(**
 * Convert an 8-bit paletted frame into a frame with a color depth of 24 bits.
 *
 * With the palette format "ABCD", the destination frame ends up with the format "ABC".
 *
 * @param src        source frame buffer
 * @param dst        destination frame buffer
 * @param num_pixels number of pixels to convert
 * @param palette    array with [256] entries, which must match color arrangement (RGB or BGR) of src
 *)
  Tsws_convertPalette8ToPacked24Proc = procedure(src, dst: PByte; num_pixels: Integer; palette: PByte); cdecl;

(**
 * Get the AVClass for swsContext. It can be used in combination with
 * AV_OPT_SEARCH_FAKE_OBJ for examining options.
 *
 * @see av_opt_find().
 *)
  Tsws_get_classProc = function: PAVClass; cdecl;

(**
 * @}
 *)

implementation

end.
