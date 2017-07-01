(*
 * DeCSS - As It. No Warrant. No Support.

 * CCAVC - CodeCoolie Audio Video Components
 * http://www.CCAVC.com
 * FFVCL - Delphi FFmpeg VCL Components
 * http://www.DelphiFFmpeg.com
 *
 * Original file: DeCSS.c
 * ported by CodeCoolie@CNSW 2008/06/28 -> $Date:: 2010-09-24 #$
 *)

unit DeCSS;

interface

{$I CompilerDefines.inc}

type
  PDVD40BitKey = ^TDVD40BitKey;
  TDVD40BitKey = array[0..4] of Byte;

//procedure CSSdescramble(key: PDVD40BitKey);
procedure CSSdescrambleSector(key: PDVD40BitKey; sec: PByte);
//procedure CSStitlekey1(key, im: PDVD40BitKey);
//procedure CSStitlekey2(key, im: PDVD40BitKey);
//procedure CSSdecrypttitlekey(tkey, dkey: PDVD40BitKey);
//function CSScracker(StartVal: Integer; pStream: PByte; pkey: PDVD40BitKey): Integer;
function CSScrackerDVD(StartVal: Integer; pCrypted, pDecrypted: PByte; StreamKey, pkey: PDVD40BitKey): Integer;

implementation

const
  CSStab0: array[0..10] of Cardinal = (5, 0, 1, 2, 3, 4, 0, 1, 2, 3, 4);

  CSStab1: array[0..255] of Byte = (
    $33, $73, $3b, $26, $63, $23, $6b, $76, $3e, $7e, $36, $2b, $6e, $2e, $66, $7b,
    $d3, $93, $db, $06, $43, $03, $4b, $96, $de, $9e, $d6, $0b, $4e, $0e, $46, $9b,
    $57, $17, $5f, $82, $c7, $87, $cf, $12, $5a, $1a, $52, $8f, $ca, $8a, $c2, $1f,
    $d9, $99, $d1, $00, $49, $09, $41, $90, $d8, $98, $d0, $01, $48, $08, $40, $91,

    $3d, $7d, $35, $24, $6d, $2d, $65, $74, $3c, $7c, $34, $25, $6c, $2c, $64, $75,
    $dd, $9d, $d5, $04, $4d, $0d, $45, $94, $dc, $9c, $d4, $05, $4c, $0c, $44, $95,
    $59, $19, $51, $80, $c9, $89, $c1, $10, $58, $18, $50, $81, $c8, $88, $c0, $11,
    $d7, $97, $df, $02, $47, $07, $4f, $92, $da, $9a, $d2, $0f, $4a, $0a, $42, $9f,

    $53, $13, $5b, $86, $c3, $83, $cb, $16, $5e, $1e, $56, $8b, $ce, $8e, $c6, $1b,
    $b3, $f3, $bb, $a6, $e3, $a3, $eb, $f6, $be, $fe, $b6, $ab, $ee, $ae, $e6, $fb,
    $37, $77, $3f, $22, $67, $27, $6f, $72, $3a, $7a, $32, $2f, $6a, $2a, $62, $7f,
    $b9, $f9, $b1, $a0, $e9, $a9, $e1, $f0, $b8, $f8, $b0, $a1, $e8, $a8, $e0, $f1,

    $5d, $1d, $55, $84, $cd, $8d, $c5, $14, $5c, $1c, $54, $85, $cc, $8c, $c4, $15,
    $bd, $fd, $b5, $a4, $ed, $ad, $e5, $f4, $bc, $fc, $b4, $a5, $ec, $ac, $e4, $f5,
    $39, $79, $31, $20, $69, $29, $61, $70, $38, $78, $30, $21, $68, $28, $60, $71,
    $b7, $f7, $bf, $a2, $e7, $a7, $ef, $f2, $ba, $fa, $b2, $af, $ea, $aa, $e2, $ff
    );

  CSStab2: array[0..255] of Byte = (
    $00, $01, $02, $03, $04, $05, $06, $07, $09, $08, $0b, $0a, $0d, $0c, $0f, $0e,
    $12, $13, $10, $11, $16, $17, $14, $15, $1b, $1a, $19, $18, $1f, $1e, $1d, $1c,
    $24, $25, $26, $27, $20, $21, $22, $23, $2d, $2c, $2f, $2e, $29, $28, $2b, $2a,
    $36, $37, $34, $35, $32, $33, $30, $31, $3f, $3e, $3d, $3c, $3b, $3a, $39, $38,
    $49, $48, $4b, $4a, $4d, $4c, $4f, $4e, $40, $41, $42, $43, $44, $45, $46, $47,
    $5b, $5a, $59, $58, $5f, $5e, $5d, $5c, $52, $53, $50, $51, $56, $57, $54, $55,
    $6d, $6c, $6f, $6e, $69, $68, $6b, $6a, $64, $65, $66, $67, $60, $61, $62, $63,
    $7f, $7e, $7d, $7c, $7b, $7a, $79, $78, $76, $77, $74, $75, $72, $73, $70, $71,
    $92, $93, $90, $91, $96, $97, $94, $95, $9b, $9a, $99, $98, $9f, $9e, $9d, $9c,
    $80, $81, $82, $83, $84, $85, $86, $87, $89, $88, $8b, $8a, $8d, $8c, $8f, $8e,
    $b6, $b7, $b4, $b5, $b2, $b3, $b0, $b1, $bf, $be, $bd, $bc, $bb, $ba, $b9, $b8,
    $a4, $a5, $a6, $a7, $a0, $a1, $a2, $a3, $ad, $ac, $af, $ae, $a9, $a8, $ab, $aa,
    $db, $da, $d9, $d8, $df, $de, $dd, $dc, $d2, $d3, $d0, $d1, $d6, $d7, $d4, $d5,
    $c9, $c8, $cb, $ca, $cd, $cc, $cf, $ce, $c0, $c1, $c2, $c3, $c4, $c5, $c6, $c7,
    $ff, $fe, $fd, $fc, $fb, $fa, $f9, $f8, $f6, $f7, $f4, $f5, $f2, $f3, $f0, $f1,
    $ed, $ec, $ef, $ee, $e9, $e8, $eb, $ea, $e4, $e5, $e6, $e7, $e0, $e1, $e2, $e3
    );

  CSStab3: array[0..511] of Byte = (
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff,
    $00, $24, $49, $6d, $92, $b6, $db, $ff, $00, $24, $49, $6d, $92, $b6, $db, $ff
    );

  CSStab4: array[0..255] of Byte = (
    $00, $80, $40, $c0, $20, $a0, $60, $e0, $10, $90, $50, $d0, $30, $b0, $70, $f0,
    $08, $88, $48, $c8, $28, $a8, $68, $e8, $18, $98, $58, $d8, $38, $b8, $78, $f8,
    $04, $84, $44, $c4, $24, $a4, $64, $e4, $14, $94, $54, $d4, $34, $b4, $74, $f4,
    $0c, $8c, $4c, $cc, $2c, $ac, $6c, $ec, $1c, $9c, $5c, $dc, $3c, $bc, $7c, $fc,
    $02, $82, $42, $c2, $22, $a2, $62, $e2, $12, $92, $52, $d2, $32, $b2, $72, $f2,
    $0a, $8a, $4a, $ca, $2a, $aa, $6a, $ea, $1a, $9a, $5a, $da, $3a, $ba, $7a, $fa,
    $06, $86, $46, $c6, $26, $a6, $66, $e6, $16, $96, $56, $d6, $36, $b6, $76, $f6,
    $0e, $8e, $4e, $ce, $2e, $ae, $6e, $ee, $1e, $9e, $5e, $de, $3e, $be, $7e, $fe,
    $01, $81, $41, $c1, $21, $a1, $61, $e1, $11, $91, $51, $d1, $31, $b1, $71, $f1,
    $09, $89, $49, $c9, $29, $a9, $69, $e9, $19, $99, $59, $d9, $39, $b9, $79, $f9,
    $05, $85, $45, $c5, $25, $a5, $65, $e5, $15, $95, $55, $d5, $35, $b5, $75, $f5,
    $0d, $8d, $4d, $cd, $2d, $ad, $6d, $ed, $1d, $9d, $5d, $dd, $3d, $bd, $7d, $fd,
    $03, $83, $43, $c3, $23, $a3, $63, $e3, $13, $93, $53, $d3, $33, $b3, $73, $f3,
    $0b, $8b, $4b, $cb, $2b, $ab, $6b, $eb, $1b, $9b, $5b, $db, $3b, $bb, $7b, $fb,
    $07, $87, $47, $c7, $27, $a7, $67, $e7, $17, $97, $57, $d7, $37, $b7, $77, $f7,
    $0f, $8f, $4f, $cf, $2f, $af, $6f, $ef, $1f, $9f, $5f, $df, $3f, $bf, $7f, $ff
    );

  CSStab5: array[0..255] of Byte = (
    $ff, $7f, $bf, $3f, $df, $5f, $9f, $1f, $ef, $6f, $af, $2f, $cf, $4f, $8f, $0f,
    $f7, $77, $b7, $37, $d7, $57, $97, $17, $e7, $67, $a7, $27, $c7, $47, $87, $07,
    $fb, $7b, $bb, $3b, $db, $5b, $9b, $1b, $eb, $6b, $ab, $2b, $cb, $4b, $8b, $0b,
    $f3, $73, $b3, $33, $d3, $53, $93, $13, $e3, $63, $a3, $23, $c3, $43, $83, $03,
    $fd, $7d, $bd, $3d, $dd, $5d, $9d, $1d, $ed, $6d, $ad, $2d, $cd, $4d, $8d, $0d,
    $f5, $75, $b5, $35, $d5, $55, $95, $15, $e5, $65, $a5, $25, $c5, $45, $85, $05,
    $f9, $79, $b9, $39, $d9, $59, $99, $19, $e9, $69, $a9, $29, $c9, $49, $89, $09,
    $f1, $71, $b1, $31, $d1, $51, $91, $11, $e1, $61, $a1, $21, $c1, $41, $81, $01,
    $fe, $7e, $be, $3e, $de, $5e, $9e, $1e, $ee, $6e, $ae, $2e, $ce, $4e, $8e, $0e,
    $f6, $76, $b6, $36, $d6, $56, $96, $16, $e6, $66, $a6, $26, $c6, $46, $86, $06,
    $fa, $7a, $ba, $3a, $da, $5a, $9a, $1a, $ea, $6a, $aa, $2a, $ca, $4a, $8a, $0a,
    $f2, $72, $b2, $32, $d2, $52, $92, $12, $e2, $62, $a2, $22, $c2, $42, $82, $02,
    $fc, $7c, $bc, $3c, $dc, $5c, $9c, $1c, $ec, $6c, $ac, $2c, $cc, $4c, $8c, $0c,
    $f4, $74, $b4, $34, $d4, $54, $94, $14, $e4, $64, $a4, $24, $c4, $44, $84, $04,
    $f8, $78, $b8, $38, $d8, $58, $98, $18, $e8, $68, $a8, $28, $c8, $48, $88, $08,
    $f0, $70, $b0, $30, $d0, $50, $90, $10, $e0, $60, $a0, $20, $c0, $40, $80, $00
    );

function PtrIdx(P: PByte; I: Integer): PByte; overload; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  Result := P;
  Inc(Result, I);
end;

function shr_1(N: Cardinal): Cardinal; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  if Integer(N) < 0 then
    Result := N shr 1 or $80000000
  else
    Result := N shr 1;
end;

function shr_3(N: Cardinal): Cardinal; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  if Integer(N) < 0 then
    Result := N shr 3 or $E0000000
  else
    Result := N shr 3;
end;

function shr_5(N: Cardinal): Cardinal; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  if Integer(N) < 0 then
    Result := N shr 5 or $F8000000
  else
    Result := N shr 5;
end;

function shr_8(N: Cardinal): Cardinal; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  if Integer(N) < 0 then
    Result := N shr 8 or $FF000000
  else
    Result := N shr 8;
end;

function shr_16(N: Cardinal): Cardinal; {$IFDEF USE_INLINE}inline;{$ENDIF}
begin
  if Integer(N) < 0 then
    Result := N shr 16 or $FFFF0000
  else
    Result := N shr 16;
end;

(***********************************************
 *
 * The basic CSS cipher code
 *
 *
 * With reduced mangling in the key setup
 *
 *
 ***********************************************)

{$IFDEF aaa}
void CSSdescramble( DVD40bitKey *key )
{
  unsigned int t1,t2,t3,t4,t5,t6;
  unsigned int i;

  t1= (*key)[0] ^ 0x100;
  t2= (*key)[1];
  t3= ((*key)[2]) | ((*key)[3]<<8) | ((*key)[4]<<16);
  t4=t3&7;
  t3=t3*2+8-t4;
  t5=0;

  printf( "Keystate at start: %03x %02x %08x\n", t1, t2, t3 );
  printf( "output: " );
  for( i=0 ; i < 10 ; i++ )
  {
    t4=CSStab2[t2]^CSStab3[t1];
    t2=t1>>1;
    t1=((t1&1)<<8)^t4;
    t4=CSStab5[t4];
    t6=(((((((t3>>3)^t3)>>1)^t3)>>8)^t3)>>5)&0xff;
    t3=(t3<<8)|t6;
    t6=CSStab4[t6];
    t5+=t6+t4;
    printf( "%02x ",t5&0xff);
    t5>>=8;
  }
  printf( "\n" );
}
{$ENDIF}

procedure CSSdescrambleSector(key: PDVD40BitKey; sec: PByte);
var
  t1, t2, t3, t4, t5, t6: Cardinal;
  secend: PByte;
begin
  secend := PByte(Cardinal(sec) + $800);

  t1 := key[0] xor PtrIdx(sec, $54)^ or $100;
  t2 := key[1] xor PtrIdx(sec, $55)^;
  t3 := (key[2] or (key[3] shl 8) or (key[4] shl 16)) xor (PtrIdx(sec, $56)^ or (PtrIdx(sec, $57)^ shl 8) or (PtrIdx(sec, $58)^ shl 16));
  t4 := t3 and 7;
  t3 := t3 * 2 + 8 - t4;
  t5 := 0;
  Inc(sec, $80);
  while sec <> secend do
  begin
    t4 := CSStab2[t2] xor CSStab3[t1];
    t2 := shr_1(t1);
    t1 := ((t1 and 1) shl 8) xor t4;
    t4 := CSStab5[t4];
    t6 := shr_5(shr_8(shr_1(shr_3(t3) xor t3) xor t3) xor t3) and $ff;
    t3 := (t3 shl 8) or t6;
    t6 := CSStab4[t6];
    Inc(t5, t6 + t4);
    sec^ := CSStab1[sec^] xor (t5 and $ff);
    Inc(sec);
    t5 := shr_8(t5);
  end;
end;
{
procedure CSStitlekey1(key, im: PDVD40BitKey);
var
  t1, t2, t3, t4, t5, t6: Cardinal;
  k: array[0..4] of Byte;
  i: Integer;
begin
  t1 := im[0] or $100;
  t2 := im[1];
  t3 := im[2] or (im[3] shl 8) or (im[4] shl 16);
  t4 := t3 and 7;
  t3 := t3 * 2 + 8 - t4;
  t5 := 0;
  for i :=0 to 4 do
  begin
    t4 := CSStab2[t2] xor CSStab3[t1];
    t2 := shr_1(t1);
    t1 := ((t1 and 1) shl 8) xor t4;
    t4 := CSStab4[t4];
    t6 := shr_5(shr_8(shr_1(shr_3(t3) xor t3) xor t3) xor t3) and $ff;
    t3 := (t3 shl 8) or t6;
    t6 := CSStab4[t6];
    Inc(t5, t6 + t4);
    k[i] := t5 and $ff;
    t5 := shr_8(t5);
  end;
  for i := 9 downto 0 do
    key[CSStab0[i + 1]] := k[CSStab0[i + 1]] xor CSStab1[key[CSStab0[i + 1]]] xor key[CSStab0[i]];
end;

procedure CSStitlekey2(key, im: PDVD40BitKey);
var
  t1, t2, t3, t4, t5, t6: Cardinal;
  k: array[0..4] of Byte;
  i: Integer;
begin
  t1 := im[0] or $100;
  t2 := im[1];
  t3 := im[2] or (im[3] shl 8) or (im[4] shl 16);
  t4 := t3 and 7;
  t3 := t3 * 2 + 8 - t4;
  t5 := 0;
  for i :=0 to 4 do
  begin
    t4 := CSStab2[t2] xor CSStab3[t1];
    t2 := shr_1(t1);
    t1 := ((t1 and 1) shl 8) xor t4;
    t4 := CSStab4[t4];
    t6 := shr_5(shr_8(shr_1(shr_3(t3) xor t3) xor t3) xor t3) and $ff;
    t3 := (t3 shl 8) or t6;
    t6 := CSStab5[t6];
    Inc(t5, t6 + t4);
    k[i] := t5 and $ff;
    t5 := shr_8(t5);
  end;
  for i := 9 downto 0 do
    key[CSStab0[i + 1]] := k[CSStab0[i + 1]] xor CSStab1[key[CSStab0[i + 1]]] xor key[CSStab0[i]];
end;

procedure CSSdecrypttitlekey(tkey, dkey: PDVD40BitKey);
var
  i: Integer;
  im1, im2: TDVD40BitKey;
begin
  im2[0] := $51;
  im2[1] := $67;
  im2[2] := $67;
  im2[3] := $c5;
  im2[4] := $e0;

  for i := 0 to 5 do
    im1[i] := dkey[i];

  CSStitlekey1(@im1, @im2);
  CSStitlekey2(tkey, @im1);
end;
}

(********************************************************
 *
 *  The Divide and conquer attack
 *
 *  Deviced and written by Frank A. Stevenson 26 Oct 1999
 *
 *  ( frank@funcom.com )
 *  Released under the GPL license
 *
 ********************************************************)

const
  KEYSTREAMBYTES = 10;

var
  GLastErrMsg: string;

function CSScracker(StartVal: Integer; pStream: PByte; pkey: PDVD40BitKey): Integer;
var
  invtab4: array[0..255] of Byte;
  t1, t2, t3, t4, t5, t6: Cardinal;
  nTry: Cardinal;
  vCandidate: Cardinal;
  i: Integer;
  j: Cardinal;
  ii: Integer;
begin
  (* Test that CSStab4 is a permutation *)
  FillChar(invtab4[0], 256, 0);
  for i := 0 to 255 do
    invtab4[CSStab4[i]] := 1;
  for i := 0 to 255 do
    if invtab4[i] <> 1 then
    begin
      //printf( "Permutation error\n" );
      GLastErrMsg := 'Permutation error';
      Result := -1;
      Exit;
    end;

  (* initialize the inverse of table4 *)
  for i := 0 to 255 do
    invtab4[CSStab4[i]] := i;

  for nTry := StartVal to 65535 do
  begin
    t1 := shr_8(nTry) or $100;
    t2 := nTry and $ff;
    t3 := 0;   (* not needed *)
    t5 := 0;

    (* iterate cipher 4 times to reconstruct LFSR2 *)
    for i := 0 to 3 do
    begin
      (* advance LFSR1 normaly *)
      t4 := CSStab2[t2] xor CSStab3[t1];
      t2 := shr_1(t1);
      t1 := ((t1 and 1) shl 8) xor t4;
      t4 := CSStab5[t4];
      (* deduce t6 & t5 *)
      t6 := PtrIdx(pStream, i)^;
      if t5 <> 0 then
        t6 := (t6 + $ff ) and $ff;
      if t6 < t4 then
        Inc(t6, $100);
      Dec(t6, t4);
      Inc(t5, t6 + t4);
      t6 := invtab4[t6];
      (* printf( "%02x/%02x ", t4, t6 ); *)
      (* feed / advance t3 / t5 *)
      t3 := (t3 shl 8) or t6;
      t5 := shr_8(t5);
    end;

    vCandidate := t3;

    (* iterate 6 more times to validate candidate key *)
    ii := KEYSTREAMBYTES;
    for i := 4 to KEYSTREAMBYTES - 1 do
    begin
      t4 := CSStab2[t2] xor CSStab3[t1];
      t2 := shr_1(t1);
      t1 := ((t1 and 1) shl 8) xor t4;
      t4 := CSStab5[t4];
      t6 := shr_5(shr_8(shr_1(shr_3(t3) xor t3) xor t3) xor t3) and $ff;
      t3 := (t3 shl 8) or t6;
      t6 := CSStab4[t6];
      Inc(t5, t6 + t4);
      if (t5 and $ff) <> PtrIdx(pStream, i)^ then
      begin
        ii := i;
        Break;
      end;
      t5 := shr_8(t5);
    end;

    if ii = KEYSTREAMBYTES then
    begin
      (* Do 4 backwards steps of iterating t3 to deduce initial state *)
      t3 := vCandidate;
      for i := 0 to 3 do
      begin
        t1 := t3 and $ff;
        t3 := shr_8(t3);
        (* easy to code, and fast enough bruteforce search for byte shifted in *)
        for j := 0 to 255 do
        begin
          t3 := (t3 and $1ffff) or (j shl 17);
          t6 := shr_5(shr_8(shr_1(shr_3(t3) xor t3) xor t3) xor t3) and $ff;
          if t6 = t1 then
            Break;
        end;
      end;
//      printf( "Candidate: t1=%03x t2=%02x t3=%08x\n", 0x100|(nTry>>8),nTry&0x0ff, t3 );
      t4 := shr_1(t3) - 4;
      for t5 := 0 to 7 do
      begin
        if ((t4 + t5) * 2 + 8 - ((t4 + t5) and 7)) = t3 then
        begin
          pkey[0] := shr_8(nTry);
          pkey[1] := nTry and $FF;
          pkey[2] := (t4 + t5) and $FF;
          pkey[3] := shr_8(t4 + t5) and $FF;
          pkey[4] := shr_16(t4 + t5) and $FF;
          Result := nTry + 1;
          Exit;
        end;
      end;
    end;
  end;

  GLastErrMsg := 'not found';
  Result := -1;
end;

function CSScrackerDVD(StartVal: Integer; pCrypted, pDecrypted: PByte; StreamKey, pkey: PDVD40BitKey): Integer;
var
  i: Integer;
  MyBuf: array[0..9] of Byte;
begin
  for i := 0 to 9 do
    MyBuf[i] := CSStab1[PtrIdx(pCrypted, i)^] xor PtrIdx(pDecrypted, i)^;

  i := CSScracker(StartVal, @MyBuf[0], pkey);
  if i >= 0 then
  begin
    pkey[0] := pkey[0] xor StreamKey[0];
    pkey[1] := pkey[1] xor StreamKey[1];
    pkey[2] := pkey[2] xor StreamKey[2];
    pkey[3] := pkey[3] xor StreamKey[3];
    pkey[4] := pkey[4] xor StreamKey[4];
  end;
  Result := i;
end;

end.
