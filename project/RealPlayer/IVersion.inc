{$DEFINE PResdll}     //����ɰ�
//{$DEFINE Pdll}        //�����dll
//{$DEFINE CDlE}        //code
{$DEFINE DCdecl}      //��C����Լ��
//{$DEFINE BPL}         //�������

//Delphi 7
{$IFDEF VER150}
  {$DEFINE DCC}
  {$DEFINE VCL_70}
  {$DEFINE DELPHI_7} // there was no C++ Builder 7
{$ENDIF}

//Delphi & C++Builder 2010 (Weaver)
{$IFDEF VER210}
  {$DEFINE DCC}
  {$DEFINE VCL_2010}
  {$IFDEF CBUILDER}
    {$DEFINE CBUILDER_2010}
  {$ELSE}
    {$DEFINE DELPHI_2010}
  {$ENDIF}
{$ENDIF}

{ Delphi XE5 / C++Builder XE5 (Win32/Win64) }
{$IFDEF VER260}
  {$DEFINE DCC}
  {$DEFINE VCL_XE5}
  {$IFDEF CBUILDER}
    {$DEFINE CBUILDER_XE5}
  {$ELSE}
    {$DEFINE DELPHI_XE5}
  {$ENDIF}
{$ENDIF}

//{$IF Defined(VER140) OR Defined(VER150)} {$IFEND}