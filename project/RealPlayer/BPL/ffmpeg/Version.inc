{$I _LicenseDefines.inc}
const
  SVersion = '5.4a';
  SComponents = 'Delphi FFmpeg VCL Components'
{$IF Defined(FFVCL) Or Defined(FFFMX)}
                + ' Professional'
{$ELSE}
                + ' Standard'
{$IFEND}
                {$IFDEF NEED_TRIAL} + ' (Trial Edition)'{$ENDIF};
  SWebSiteC   = 'http://www.CCAVC.com';
  SWebSiteE   = 'http://www.DelphiFFmpeg.com';
  SCopyRightC = 'Copyright(C) 2008-2013 CodeCoolie@CNSW';
  SCopyRightE = 'Copyright(C) 2008-2013 DelphiFFmpeg.com';

