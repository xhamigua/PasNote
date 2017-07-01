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
 * Original file: libavcodec/avfft.h
 * Ported by CodeCoolie@CNSW 2010/03/14 -> $Date:: 2012-12-01 #$
 *)

unit libavcodec_avfft;

interface

{$I CompilerDefines.inc}

{$I libversion.inc}

(**
 * @file
 * @ingroup lavc_fft
 * FFT functions
 *)

(**
 * @defgroup lavc_fft FFT functions
 * @ingroup lavc_misc
 *
 * @{
 *)

type
  PFFTSample = ^TFFTSample;
  TFFTSample = Single;

  PFFTComplex = ^TFFTComplex;
  TFFTComplex = record
    re, im: TFFTSample;
  end;

  PFFTContext = ^TFFTContext;
  TFFTContext = record
    // need {$ALIGN 8}
{
    nbits: Integer;
    inverse: Integer;
    revtab: PWord;
    exptab: PFFTComplex;
    exptab1: PFFTComplex; (* only used by SSE code *)
    tmp_buf: PFFTComplex;
    mdct_size: Integer; (* size of MDCT (i.e. number of input data * 2) *)
    mdct_bits: Integer; (* n = 2^nbits *)
    (* pre/post rotation tables *)
    tcos: PFFTSample;
    tsin: PFFTSample;
    fft_permute: Pointer; //void (*fft_permute)(struct FFTContext *s, FFTComplex *z);
    fft_calc: Pointer; //void (*fft_calc)(struct FFTContext *s, FFTComplex *z);
    imdct_calc: Pointer; //void (*imdct_calc)(struct FFTContext *s, FFTSample *output, const FFTSample *input);
    imdct_half: Pointer; //void (*imdct_half)(struct FFTContext *s, FFTSample *output, const FFTSample *input);
    mdct_calc: Pointer; //void (*mdct_calc)(struct FFTContext *s, FFTSample *output, const FFTSample *input);
    split_radix: Integer;
    permutation: Integer;
//#define FF_MDCT_PERM_NONE       0
//#define FF_MDCT_PERM_INTERLEAVE 1
}
  end;

(**
 * Set up a complex FFT.
 * @param nbits           log2 of the length of the input array
 * @param inverse         if 0 perform the forward transform, if 1 perform the inverse
 *)
  Tav_fft_initProc = function(nbits, inverse: Integer): PFFTContext; cdecl;

(**
 * Do the permutation needed BEFORE calling ff_fft_calc().
 *)
  Tav_fft_permuteProc = procedure(s: PFFTContext; z: PFFTComplex); cdecl;

(**
 * Do a complex FFT with the parameters defined in av_fft_init(). The
 * input data must be permuted before. No 1.0/sqrt(n) normalization is done.
 *)
  Tav_fft_calcProc = procedure(s: PFFTContext; z: PFFTComplex); cdecl;

  Tav_fft_endProc = procedure(s: PFFTContext); cdecl;

  Tav_mdct_initProc = function(nbits, inverse: Integer; scale: Double): PFFTContext; cdecl;
  Tav_imdct_calcProc = procedure(s: PFFTContext; output: PFFTSample; const input: PFFTSample); cdecl;
  Tav_imdct_halfProc = procedure(s: PFFTContext; output: PFFTSample; const input: PFFTSample); cdecl;
  Tav_mdct_calcProc = procedure(s: PFFTContext; output: PFFTSample; const input: PFFTSample); cdecl;
  Tav_mdct_endProc = procedure(s: PFFTContext); cdecl;

(* Real Discrete Fourier Transform *)

  TRDFTransformType = (
      DFT_R2C,
      IDFT_C2R,
      IDFT_R2C,
      DFT_C2R
    );

  PRDFTContext = ^TRDFTContext;
  TRDFTContext = record
    // need {$ALIGN 8}
{
    nbits: Integer;
    inverse: Integer;
    sign_convention: Integer;

    (* pre/post rotation tables *)
    tcos: PFFTSample;
    tsin: PFFTSample;
    fft: TFFTContext;
}
  end;

(**
 * Set up a real FFT.
 * @param nbits           log2 of the length of the input array
 * @param trans           the type of transform
 *)
  Tav_rdft_initProc = function(nbits: Integer; trans: TRDFTransformType): PRDFTContext; cdecl;
  Tav_rdft_calcProc = procedure(s: PRDFTContext; data: PFFTSample); cdecl;
  Tav_rdft_endProc = procedure(s: PRDFTContext); cdecl;

(* Discrete Cosine Transform *)

  PDCTContext = ^TDCTContext;
  TDCTContext = record
    // need {$ALIGN 8}
  end;

  TDCTTransformType = (
    DCT_II = 0,
    DCT_III,
    DCT_I,
    DST_I
  );

(**
 * Set up DCT.
 * @param nbits           size of the input array:
 *                        (1 << nbits)     for DCT-II, DCT-III and DST-I
 *                        (1 << nbits) + 1 for DCT-I
 *
 * @note the first element of the input of DST-I is ignored
 *)
  Tav_dct_initProc = function(nbits: Integer; ttype: TDCTTransformType): PDCTContext; cdecl;
  Tav_dct_calcProc = procedure(s: PDCTContext; data: PFFTSample); cdecl;
  Tav_dct_endProc = procedure(s: PDCTContext); cdecl;

(**
 * @}
 *)

implementation

end.
