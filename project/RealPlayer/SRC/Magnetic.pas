unit Magnetic;
interface
uses
  Windows, Messages;

  function SubFormWindowProc(Wnd: HWND; Msg, wParam, lParam: Integer): Integer; stdcall;
  //创建磁性类
  function CreateMag:Boolean;stdcall;
  //销毁类
  function DestMag:Boolean;stdcall;

Type
  PWND_INFO = ^TWND_INFO;
  TWND_INFO = record
    h_wnd      : HWND;
    hWndParent : HWND;
    Glue       : Boolean;
  end;

  TSubClass_Proc = function(lng_hWnd: HWND; uMsg: Integer;
                            var Msg: TMessage; var bHandled: Boolean) : boolean;

  TMagnetic = class
    constructor Create;
    Destructor Destroy; Override;

   private
    FSnapWidth    : integer;
    m_uWndInfo    : array of TWND_INFO;
    m_rcWnd       : array of TRECT;
    m_lWndCount   : Integer;
    m_ptAnchor    : TPOINT;
    m_ptOffset    : TPOINT;
    m_ptCurr      : TPOINT;
    m_ptLast      : TPOINT;

    function  GetSnapWidth: Integer;
    procedure SetSnapWidth(const Value: Integer);
    procedure pvSizeRect(Handle: HWND; var rcWnd: TRECT; lfEdge: Integer);
    procedure pvMoveRect(Handle: HWND; var rcWnd: TRECT);
    procedure pvCheckGlueing;
    function  pvWndsConnected(rcWnd1: TRECT; rcWnd2: TRECT): Boolean;
    function  pvWndGetInfoIndex(Handle: HWND): Integer;
    function  pvWndParentGetInfoIndex(hWndParent: HWND): Integer;
    procedure zSubclass_Proc(lng_hWnd: HWND;
                             uMsg, wParam, lParam: Integer;
                             var lReturn: LRESULT;//Integer;
                             var bHandled: Boolean);

   public
    function  AddWindow(Handle: HWND; hWndParent: HWND; var FuncPointer : TSubClass_Proc): Boolean;
    function  RemoveWindow(Handle: HWND): Boolean;
    procedure CheckGlueing;
    property  SnapWidth: Integer read GetSnapWidth write SetSnapWidth;
  end;

Const
  LB_RECT = 16;

Var
  MagneticWnd: TMagnetic;
  MagneticWndProc : TSubClass_Proc;


implementation

// procedure to subclass ChildForms window procedure for magnetic effect.
//以下是注册一个窗体为磁性窗口

function SubFormWindowProc(Wnd: HWND; Msg, wParam, lParam: Integer): Integer; stdcall;
var
  Handled: boolean;
  Message_: TMessage;
  OrgWndProc: Integer;
  dummyHandled : boolean;     //这个要放到外面
begin
  Result := 0;
  if not Assigned(MagneticWndProc) then
  begin
    Result := CallWindowProc(Pointer(OrgWndProc), Wnd, Msg, wParam, lParam);
    exit;
  end;

  OrgWndProc := GetWindowLong(Wnd, GWL_USERDATA);
  if (OrgWndProc = 0) then  exit;

  Message_.WParam := wParam;
  Message_.LParam := lParam;
  Message_.Result := 0;

  if (Msg = WM_SYSCOMMAND) or (Msg = WM_ENTERSIZEMOVE) or (Msg = WM_EXITSIZEMOVE) or
  (Msg = WM_WINDOWPOSCHANGED) or (Msg = WM_COMMAND)then
  begin
    Result := CallWindowProc(Pointer(OrgWndProc), Wnd, Msg, wParam, lParam);
    MagneticWndProc(Wnd, Msg, Message_, dummyHandled);
  end else if (Msg = WM_MOVING) or (Msg = WM_SIZING) then
  begin
    MagneticWndProc(Wnd, Msg, Message_, Handled);
    if Handled then
    begin
      Result := Message_.Result;
      exit;
    end else
      Result := CallWindowProc(Pointer(OrgWndProc), Wnd, Msg, wParam, lParam);
  end else if (Msg = WM_DESTROY) then
  begin
    if Assigned(MagneticWnd) then
    MagneticWnd.RemoveWindow(Wnd);
    Result := CallWindowProc(Pointer(OrgWndProc), Wnd, Msg, wParam, lParam);
  end else
    Result := CallWindowProc(Pointer(OrgWndProc), Wnd, Msg, wParam, lParam);
end;

function CreateMag:Boolean;stdcall;
begin
  if Assigned(MagneticWnd) then
  begin  //如果创建就退出
    Result:=False;
    Exit;
  end  else  begin
    MagneticWnd := TMagnetic.Create;
    Result:=True;
  end;
end;

function DestMag:Boolean;stdcall;
begin
  if Assigned(MagneticWnd) then
  MagneticWnd.Free;
end;




function Subclass_Proc(lng_hWnd: HWND;
                       uMsg: Integer;
                       var Msg: TMessage;
                       var bHandled: Boolean) : boolean;
begin
   if Assigned(MagneticWnd) then
   begin
      MagneticWnd.zSubclass_Proc(lng_hWnd, uMsg,
                                 Msg.wParam, Msg.lParam, Msg.Result, bHandled);
      result := true;
   end else
      result := false;
end;

constructor TMagnetic.create;
begin
  SnapWidth := 10;    // Default snap width
  m_lWndCount := 0;   // Initialize registered number of window
end;


Destructor TMagnetic.Destroy;
begin
   MagneticWnd := nil;
   
   SetLength(m_uWndInfo, 0);  // not sure this is needed
   SetLength(m_rcWnd, 0);     // not sure this is needed

   inherited;
end;


function TMagnetic.GetSnapWidth: Integer;
begin
  Result := FSnapWidth;
end; 

procedure TMagnetic.SetSnapWidth(const Value: Integer);
begin
  FSnapWidth := Value; 
end;

procedure TMagnetic.zSubclass_Proc(lng_hWnd: HWND;
                                   uMsg, wParam, lParam: Integer;
                                   var lReturn: LRESULT;//Integer;
                                   var bHandled: Boolean);
{
Parameters:
   lng_hWnd - The window handle
   uMsg     - The message number
   wParam   - Message related data
   lParam   - Message related data
   lReturn  - Set this variable as per your intentions and requirements, see the MSDN
              documentation or each individual message value.
   bHandled - Set this variable to True in a 'before' callback to prevent the message being
              subsequently processed by the default handler... and if set, an 'after' callback
}

{
Notes:
   If you really know what you're doing, it's possible to change the values of the
   lng_hWnd, uMsg, wParam and lParam parameters in a 'before' callback so that different
   values get passed to the default handler.. and optionaly, the 'after' callback
}
Var
  rcWnd : TRECT;
  lC    : Integer;
  pWINDOWPOS : ^TWINDOWPOS;
begin
    bHandled := false;

    Case uMsg of
        // Size/Move starting
        WM_ENTERSIZEMOVE:
        begin
            // Get Desktop area (as first rectangle)
            SystemParametersInfo(SPI_GETWORKAREA, 0, @m_rcWnd[0], 0);

            // Get rectangles of all handled windows
            For lC := 1 To m_lWndCount do
             begin
                // Window maximized ?
                If (IsZoomed(m_uWndInfo[lC].h_wnd)) Then
                  begin
                    // Take work are rectangle
                    CopyMemory(@m_rcWnd[lC], @m_rcWnd[0], LB_RECT);
                  end Else
                    // Get window rectangle
                    GetWindowRect((m_uWndInfo[lC].h_wnd), m_rcWnd[lC]);

                // Is it our current window ?
                If (m_uWndInfo[lC].h_wnd = lng_hWnd) Then
                  begin
                    // Get anchor-offset
                    GetCursorPos(m_ptAnchor);
                    GetCursorPos(m_ptLast);
                    m_ptOffset.x := m_rcWnd[lC].Left - m_ptLast.x;
                    m_ptOffset.y := m_rcWnd[lC].Top - m_ptLast.y;
                  end;
            end;
         end;
        // Sizing
        WM_SIZING:
         begin
            CopyMemory(@rcWnd, pointer(lParam), LB_RECT);
            pvSizeRect(lng_hWnd, rcWnd, wParam);
            CopyMemory(pointer(lParam), @rcWnd, LB_RECT);

            bHandled := True;
            lReturn := 1;
         end;
        // Moving
        WM_MOVING:
          begin
            CopyMemory(@rcWnd, pointer(lParam), LB_RECT);
            pvMoveRect(lng_hWnd, rcWnd);
            CopyMemory(pointer(lParam), @rcWnd, LB_RECT);

            bHandled := True;
            lReturn := 1;
          end;
        // Size/Move finishing
        WM_EXITSIZEMOVE:
          begin
            pvCheckGlueing;
          end;
        // at after Shown or Hidden window
        WM_WINDOWPOSCHANGED:  // ************** Added
          begin
            pWINDOWPOS := pointer(lParam);
            if ((pWINDOWPOS^.flags and SWP_SHOWWINDOW) = SWP_SHOWWINDOW) or
               ((pWINDOWPOS^.flags and SWP_HIDEWINDOW) = SWP_HIDEWINDOW) then
               pvCheckGlueing;
          end;
        // Special case: *menu* call
        WM_SYSCOMMAND:
          begin
            If (wParam = SC_MINIMIZE) Or (wParam = SC_RESTORE) Then
                pvCheckGlueing;

          end;
        // Special case: *control* call
        WM_COMMAND:
          begin
            pvCheckGlueing;
          end;
    End;
End;


function TMagnetic.AddWindow(Handle: HWND; hWndParent: HWND; var FuncPointer : TSubClass_Proc): Boolean;
Var
  lC : Integer;

begin
    Result := false;  // assume failure
    FuncPointer := nil;
    
    // Already in collection ?
    For lC := 1 To m_lWndCount do
      begin
        If (Handle = m_uWndInfo[lC].h_wnd) Then
          Exit;
      end;

    // Validate windows
    If IsWindow(Handle) And (IsWindow(hWndParent) Or (hWndParent = 0)) Then  //********* Changed
    begin
        // Increase count
        inc(m_lWndCount);

        // Resize arrays
        SetLength(m_uWndInfo, m_lWndCount+1);
        SetLength(m_rcWnd, m_lWndCount+1);

        // Add info
        m_uWndInfo[m_lWndCount].h_wnd := Handle;
        if hWndParent = Handle then      // Parent window is Self window ?       //******** Added
           m_uWndInfo[m_lWndCount].hWndParent := 0  // Then same to "no parent"  //******** Added
        else
           m_uWndInfo[m_lWndCount].hWndParent := hWndParent;

        // Check glueing for first time
        pvCheckGlueing;

        FuncPointer := Subclass_Proc;

        // Success
        Result := True;
    End;
End;


function TMagnetic.RemoveWindow(Handle: HWND): Boolean;
Var
  lc1 : Integer;
  lc2 : Integer;

begin
    Result := false;  // assume failure

    For lc1 := 1 To m_lWndCount do
    begin
        If (Handle = m_uWndInfo[lc1].h_wnd) Then
        begin
            // Move down
            For lc2 := lc1 To (m_lWndCount - 1) do
            begin
                m_uWndInfo[lc2] := m_uWndInfo[lc2 + 1];
            end;

            // Resize arrays
              dec(m_lWndCount);
              SetLength(m_uWndInfo, m_lWndCount+1);
              SetLength(m_rcWnd, m_lWndCount+1);

            // Remove parent relationships
            For lc2 := 1 To m_lWndCount do
            begin
                If (m_uWndInfo[lc2].hWndParent = Handle) Then
                    m_uWndInfo[lc2].hWndParent := 0;
            end;

            // verify connections
            pvCheckGlueing;

            // Success
            Result := True;
            Break;
        End;
    end;
End;

procedure TMagnetic.CheckGlueing;
begin
    // Check ALL windows for possible new *connections*.
    pvCheckGlueing;
End;


procedure TMagnetic.pvSizeRect(Handle: HWND; var rcWnd: TRECT; lfEdge: integer);
var
  rcTmp: TRECT;
  lC:    integer;

begin
  // Get a copy
  CopyMemory(@rcTmp, @rcWnd, LB_RECT);

  // Check all windows
  for lC := 0 to m_lWndCount do
  begin
    with m_rcWnd[lC] do
    begin
      // Avoid hidden window
      if lC <> 0 then  // m_rcWnd[0] has the window rect of Desktop area
        if not IsWindowVisible(m_uWndInfo[lc].h_wnd) then   // **************** Added
           continue;

      // Avoid current window
      if (m_uWndInfo[lC].h_wnd <> Handle) then
      begin
        // X magnetism
        if (rcWnd.Top < Bottom + SnapWidth) and (rcWnd.Bottom > Top - SnapWidth) then
        begin
          case lfEdge of

            WMSZ_LEFT, WMSZ_TOPLEFT, WMSZ_BOTTOMLEFT:
            begin
              //Case True of
              case Abs(rcTmp.Left - Left) < SnapWidth of
                True:
                  rcWnd.Left := Left;
              end;
              case Abs(rcTmp.Left - Right) < SnapWidth of
                True:
                  rcWnd.Left := Right;
              end;
            end;
            WMSZ_RIGHT, WMSZ_TOPRIGHT, WMSZ_BOTTOMRIGHT:
            begin
              case Abs(rcTmp.Right - Left) < SnapWidth of
                True:
                  rcWnd.Right := Left;
              end;
              case Abs(rcTmp.Right - Right) < SnapWidth of
                True:
                  rcWnd.Right := Right;
              end;
            end;
          end;
        end;

        // Y magnetism
        if (rcWnd.Left < Right + SnapWidth) and (rcWnd.Right > Left - SnapWidth) then
        begin
          case lfEdge of

            WMSZ_TOP, WMSZ_TOPLEFT, WMSZ_TOPRIGHT:
            begin
              case Abs(rcTmp.Top - Top) < SnapWidth of
                True:
                  rcWnd.Top := Top;
              end;
              case Abs(rcTmp.Top - Bottom) < SnapWidth of
                True:
                  rcWnd.Top := Bottom;
              end;
            end;

            WMSZ_BOTTOM, WMSZ_BOTTOMLEFT, WMSZ_BOTTOMRIGHT:
            begin
              case Abs(rcTmp.Bottom - Top) < SnapWidth of
                True:
                  rcWnd.Bottom := Top;
              end;
              case Abs(rcTmp.Bottom - Bottom) < SnapWidth of
                True:
                  rcWnd.Bottom := Bottom;
              end;
            end;
          end;
        end;
      end;
    end; // end of "with m_rcWnd[lC] do"
  end; // end of "for lC := 0 to m_lWndCount do"
end;

procedure TMagnetic.pvMoveRect(Handle: HWND; var rcWnd: TRECT);
var
  lc1:   integer;
  lc2:   integer;
  lWId:  integer;
  rcTmp: TRECT;
  lOffx: integer;
  lOffy: integer;
  hDWP:  integer;

begin
  // Get current cursor position
  GetCursorPos(m_ptCurr);

  // Check magnetism for current window
  // 'Move' current window
  OffsetRect(rcWnd, (m_ptCurr.x - rcWnd.Left) + m_ptOffset.x, 0);
  OffsetRect(rcWnd, 0, (m_ptCurr.y - rcWnd.Top) + m_ptOffset.y);

  lOffx := 0;
  lOffy := 0;

  // Check all windows
  for lc1 := 0 to m_lWndCount do
  begin
    // Avoid hidden window
    if lC1 <> 0 then  // m_rcWnd[0] has the window rect of Desktop area
      if not IsWindowVisible(m_uWndInfo[lc1].h_wnd) then   // **************** Added
         continue;

    // Avoid current window
    if (m_uWndInfo[lc1].h_wnd <> Handle) then
    begin
      // Avoid child windows
      if (m_uWndInfo[lc1].Glue = False) or
        (m_uWndInfo[lc1].hWndParent <> Handle) then
      begin
        with m_rcWnd[lc1] do
        begin
          // X magnetism
          if (rcWnd.Top < Bottom + SnapWidth) and (rcWnd.Bottom > Top - SnapWidth) then
          begin
            case Abs(rcWnd.Left - Left) < SnapWidth of
              True:
                lOffx := Left - rcWnd.Left;
            end;
            case Abs(rcWnd.Left - Right) < SnapWidth of
              True:
                lOffx := Right - rcWnd.Left;
            end;
            case Abs(rcWnd.Right - Left) < SnapWidth of
              True:
                lOffx := Left - rcWnd.Right;
            end;
            case Abs(rcWnd.Right - Right) < SnapWidth of
              True:
                lOffx := Right - rcWnd.Right;
            end;
          end;

          // Y magnetism
          if (rcWnd.Left < Right + SnapWidth) and (rcWnd.Right > Left - SnapWidth) then
          begin
            case Abs(rcWnd.Top - Top) < SnapWidth of
              True:
                lOffy := Top - rcWnd.Top;
            end;
            case Abs(rcWnd.Top - Bottom) < SnapWidth of
              True:
                lOffy := Bottom - rcWnd.Top;
            end;
            case Abs(rcWnd.Bottom - Top) < SnapWidth of
              True:
                lOffy := Top - rcWnd.Bottom;
            end;
            case Abs(rcWnd.Bottom - Bottom) < SnapWidth of
              True:
                lOffy := Bottom - rcWnd.Bottom;
            end;
          end;
        end;
      end;
    end;
  end;

  // Check magnetism for child windows
  for lc1 := 1 to m_lWndCount do
  begin
    // Avoid hidden window
    if not IsWindowVisible(m_uWndInfo[lc1].h_wnd) then   // **************** Added
       continue;

    // Child and connected window ?
    if (m_uWndInfo[lc1].Glue) and (m_uWndInfo[lc1].hWndParent = Handle) then
    begin
      // 'Move' child window
      CopyMemory(@rcTmp, @m_rcWnd[lc1], LB_RECT);
      OffsetRect(rcTmp, m_ptCurr.x - m_ptAnchor.x, 0);
      OffsetRect(rcTmp, 0, m_ptCurr.y - m_ptAnchor.y);

      for lc2 := 0 to m_lWndCount do
      begin
        if (lc1 <> lc2) then
        begin
          // Avoid hidden window
          if not IsWindowVisible(m_uWndInfo[lc2].h_wnd) then   // **************** Added
             continue;

          // Avoid child windows
          if (m_uWndInfo[lc2].Glue = False) and
            (m_uWndInfo[lc2].h_wnd <> Handle) then
          begin
            with m_rcWnd[lc2] do
            begin
              // X magnetism
              if (rcTmp.Top < Bottom + SnapWidth) and
                (rcTmp.Bottom > Top - SnapWidth) then
              begin
                case Abs(rcTmp.Left - Left) < SnapWidth of
                  True:
                    lOffx := Left - rcTmp.Left;
                end;
                case Abs(rcTmp.Left - Right) < SnapWidth of
                  True:
                    lOffx := Right - rcTmp.Left;
                end;
                case Abs(rcTmp.Right - Left) < SnapWidth of
                  True:
                    lOffx := Left - rcTmp.Right;
                end;
                case Abs(rcTmp.Right - Right) < SnapWidth of
                  True:
                    lOffx := Right - rcTmp.Right;
                end;
              end;

              // Y magnetism
              if (rcTmp.Left < Right + SnapWidth) and
                (rcTmp.Right > Left - SnapWidth) then
              begin
                case Abs(rcTmp.Top - Top) < SnapWidth of
                  True:
                    lOffy := Top - rcTmp.Top;
                end;
                case Abs(rcTmp.Top - Bottom) < SnapWidth of
                  True:
                    lOffy := Bottom - rcTmp.Top;
                end;
                case Abs(rcTmp.Bottom - Top) < SnapWidth of
                  True:
                    lOffy := Top - rcTmp.Bottom;
                end;
                case Abs(rcTmp.Bottom - Bottom) < SnapWidth of
                  True:
                    lOffy := Bottom - rcTmp.Bottom;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;

  // Apply offsets
  OffsetRect(rcWnd, lOffx, lOffy);

  // Glueing (move child windows, if any)
  hDWP := BeginDeferWindowPos(1);

  for lc1 := 1 to m_lWndCount do
  begin
    // Avoid hidden window
    if not IsWindowVisible(m_uWndInfo[lc1].h_wnd) then   // **************** Added
       continue;

    with m_uWndInfo[lc1] do
      // Is parent our current window ?
      if (hWndParent = Handle) and (Glue) then
      begin
        // Move 'child' window
        lWId := pvWndGetInfoIndex(Handle);
        with m_rcWnd[lc1] do
          DeferWindowPos(hDWP, m_uWndInfo[lc1].h_wnd, 0,
                         Left - (m_rcWnd[lWId].Left - rcWnd.Left),
                         Top - (m_rcWnd[lWId].Top - rcWnd.Top),
                         0{width}, 0{height},  // No size change
                         SWP_NOACTIVATE or SWP_NOSIZE or SWP_NOZORDER);
      end;
  end;


  EndDeferWindowPos(hDWP);
  // Store last cursor position
  m_ptLast := m_ptCurr;
end;

procedure TMagnetic.pvCheckGlueing;
var
  lcMain: integer;
  lc1:    integer;
  lc2:    integer;
  lWId:   integer;
begin
  // Get all windows rectangles / Reset glueing
  for lc1 := 1 to m_lWndCount do
  begin
    GetWindowRect(m_uWndInfo[lc1].h_wnd, m_rcWnd[lc1]);
    m_uWndInfo[lc1].Glue := False;
  end;

  // Check direct connection
  for lc1 := 1 to m_lWndCount do
  begin
    if not IsWindowVisible(m_uWndInfo[lc1].h_wnd) then   // **************** Added
       continue;

    if (m_uWndInfo[lc1].hWndParent <> 0) then
    begin
      // Get parent window info index
      lWId := pvWndParentGetInfoIndex(m_uWndInfo[lc1].hWndParent);
      // Connected ?
      m_uWndInfo[lc1].Glue := pvWndsConnected(m_rcWnd[lWId], m_rcWnd[lc1]);
    end;
  end;

  // Check indirect connection
  for lcMain := 1 to m_lWndCount do  // to check the windows snapped far lower level
  begin                              //  in multi-layer snapped structure
    for lc1 := 1 to m_lWndCount do
    begin
      // Avoid hidden window
      if not IsWindowVisible(m_uWndInfo[lc1].h_wnd) then   // **************** Added
         continue;

      if (m_uWndInfo[lc1].Glue) then
      begin
        for lc2 := 1 to m_lWndCount do
        begin
          // Avoid hidden window
          if not IsWindowVisible(m_uWndInfo[lc2].h_wnd) then   // **************** Added
             continue;
          if (lc1 <> lc2) then
          begin
            if (m_uWndInfo[lc1].hWndParent = m_uWndInfo[lc2].hWndParent) then
            begin
              // Connected ?
              if (m_uWndInfo[lc2].Glue = False) then
                  m_uWndInfo[lc2].Glue := pvWndsConnected(m_rcWnd[lc1], m_rcWnd[lc2]);
            end;
          end;
        end;  // end of for lc2
      end;
    end;   // end of for lc1
  end;   // end of for lcMain

end;

function TMagnetic.pvWndsConnected(rcWnd1: TRECT; rcWnd2: TRECT): boolean;
var
  rcUnion: TRECT;
begin
  result := false;  // assume not connected

  // Calc. union rectangle of windows
  UnionRect(rcUnion, rcWnd1, rcWnd2);

  // Bounding glue-rectangle
  if ((rcUnion.Right - rcUnion.Left) <= (rcWnd1.Right - rcWnd1.Left) +
    (rcWnd2.Right - rcWnd2.Left)) and ((rcUnion.Bottom - rcUnion.Top) <=
    (rcWnd1.Bottom - rcWnd1.Top) + (rcWnd2.Bottom - rcWnd2.Top)) then
  begin
    // Edge coincidences ?
    if (rcWnd1.Left = rcWnd2.Left) or (rcWnd1.Left = rcWnd2.Right) or
      (rcWnd1.Right = rcWnd2.Left) or (rcWnd1.Right = rcWnd2.Right) or
      (rcWnd1.Top = rcWnd2.Top) or (rcWnd1.Top = rcWnd2.Bottom) or
      (rcWnd1.Bottom = rcWnd2.Top) or (rcWnd1.Bottom = rcWnd2.Bottom) then

      pvWndsConnected := True;
  end;
end;

function TMagnetic.pvWndGetInfoIndex(Handle: HWND): integer;
var
  lC: integer;

begin
  result := -1;   // assume no matched item

  for lC := 1 to m_lWndCount do
  begin
    if (m_uWndInfo[lC].h_wnd = Handle) then
    begin
      pvWndGetInfoIndex := lC;
      break;
    end;
  end;
end;

function TMagnetic.pvWndParentGetInfoIndex(hWndParent: HWND): integer;
var
  lC: integer;
begin
  result := -1;   // assume no matched item

  for lC := 1 to m_lWndCount do
  begin
    if (m_uWndInfo[lC].h_wnd = hWndParent) then
    begin
      pvWndParentGetInfoIndex := lC;
      Break;
    end;
  end;
end;


end.

