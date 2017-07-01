(*
 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * This file is a unit of some effects on frame.
 * Created by CodeCoolie@CNSW 2013/11/15 -> $Date:: 2013-11-18 #$
 *)

unit FrameEffects;

interface

{$I CompilerDefines.inc}

// brightness range -> -100 - 100
// contrast range -> -100 - 100

// AVCodecContext -> width, height
// AVFrame/AVPicture -> data, linesize

// adjust full frame -> (0, 0) - (width, height)
// adjust_eq(data[0],
//           linesize[0],
//           width,
//           height,
//           brightness,
//           contrast);

// adjust rect frame -> (x1, y1) - (x2, y2)
// adjust_eq(PByte(Integer(data[0]) + linesize[0] * y1  + x1),
//           linesize[0],
//           x2 - x1,
//           y2 - y1,
//           brightness,
//           contrast);

procedure adjust_eq(y_line: PByte; stride, w, h, brightness, contrast: Integer); overload;
procedure adjust_eq(y_dst: PByte; linesize_dst: Integer;
  y_src: PByte; linesize_src: Integer; w, h, brightness, contrast: Integer); overload;

// hue range -> -100 - 100
// saturation range -> -100 - 100

// AVCodecContext -> pix_fmt, width, height
// AVFrame/AVPicture -> data, linesize

// avcodec_get_chroma_sub_sample(pix_fmt, @hsub, @vsub);
// PIX_FMT_YUV420P -> hsub=1, vsub=1

// adjust full frame -> (0, 0) - (width, height)
// adjust_hue(data[1],
//            data[2],
//            linesize[1],
//            width shr hsub,
//            height shr vsub,
//            hue,
//            saturation);

// adjust rect frame -> (x1, y1) - (x2, y2)
// adjust_hue(PByte(Integer(data[1]) + linesize[1] * (y1 shr vsub) + (x1 shr vsub)),
//            PByte(Integer(data[2]) + linesize[2] * (y1 shr vsub) + (x1 shr vsub)),
//            linesize[1],
//            (x2 - x1) shr hsub,
//            (y2 - y1) shr vsub,
//            hue,
//            saturation);

procedure adjust_hue(u_line, v_line: PByte; stride, w, h, hue, saturation: Integer); overload;
procedure adjust_hue(u_dst, v_dst: PByte; linesize_dst: Integer;
  u_src, v_src: PByte; linesize_src: Integer; w, h, hue, saturation: Integer); overload;

implementation

uses
{$IFDEF VCL_XE2_OR_ABOVE}
  System.Math,
{$ELSE}
  Math,
{$ENDIF}

  libavutil_mathematics,

  MyUtils;

procedure adjust_eq(y_dst: PByte; linesize_dst: Integer;
  y_src: PByte; linesize_src: Integer; w, h, brightness, contrast: Integer); overload;
var
  i: Integer;
  pel: Integer;
  step_dst: Integer;
  step_src: Integer;
begin
  step_dst := linesize_dst - w;
  step_src := linesize_src - w;

  contrast := ((contrast + 100) * $10000) div 100;
  brightness := ((brightness + 100) * $1FF) div 200 - $80 - (contrast shr 9);

  while h > 0 do
  begin
    i := w;
    while i > 0 do
    begin
      pel := ((y_src^ * contrast) shr 16) + brightness;
      if pel < 0 then
        y_dst^ := 0
      else if pel > $FF then
        y_dst^ := $FF
      else
        y_dst^ := pel;
      Inc(y_src);
      Inc(y_dst);
      Dec(i);
    end;
    Inc(y_src, step_src);
    Inc(y_dst, step_dst);
    Dec(h);
  end;
end;

procedure adjust_eq(y_line: PByte; stride, w, h, brightness, contrast: Integer);
begin
  adjust_eq(y_line, stride, y_line, stride, w, h, brightness, contrast);
end;

function PtrIdx(P: PByte; I: Integer): PByte; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

procedure adjust_hue(u_dst, v_dst: PByte; linesize_dst: Integer;
  u_src, v_src: PByte; linesize_src: Integer; w, h, hue, saturation: Integer);
var
  s: Integer;
  c: Integer;
  i: Integer;
  u, v, new_u, new_v: Integer;
begin
  s := Floor(Sin(hue * M_PI / 100) * $10000 * (saturation + 100) / 100 + 0.5);
  c := Floor(Cos(hue * M_PI / 100) * $10000 * (saturation + 100) / 100 + 0.5);

  while h > 0 do
  begin
    for i := 0 to w - 1 do
    begin
      u := PtrIdx(u_src, i)^ - 128;
      v := PtrIdx(v_src, i)^ - 128;
      new_u := MySAR(c * u - s * v + $808000, 16);
      new_v := MySAR(s * u + c * v + $808000, 16);
      if (new_u and $300) <> 0 then
      begin
        if new_u > 0 then
          new_u := $FF
        else
          new_u := 0;
      end;
      if (new_v and $300) <> 0 then
      begin
        if new_v > 0 then
          new_v := $FF
        else
          new_v := 0;
      end;
      PtrIdx(u_dst, i)^ := new_u;
      PtrIdx(v_dst, i)^ := new_v;
    end;
    Inc(u_src, linesize_src);
    Inc(v_src, linesize_src);
    Inc(u_dst, linesize_dst);
    Inc(v_dst, linesize_dst);
    Dec(h);
  end;
end;

procedure adjust_hue(u_line, v_line: PByte; stride, w, h, hue, saturation: Integer);
begin
  adjust_hue(u_line, v_line, stride, u_line, v_line, stride, w, h, hue, saturation);
end;

end.
