#NoTrayIcon
#SingleInstance force

#include stdout2var.ahk
#Include Gdip.ahk

title1=Waifu2x-CPP GUI By Maz-1 (maz_1@foxmail.com)
StringCaseSense, Off
SetFormat, Float, 0.2
WPath = %A_ScriptDir%
Waifu2x_Exe = waifu2x-converter-cpp.exe
Magick_Exe = magick.exe

SetWorkingDir %WPath%

HideCMD = Hide

FTypeInit = png,jpg,jpeg,tif,tiff,bmp,tga

GDIPToken := Gdip_Startup()

fName = %1%
DirInit =
If FileExist(fName)
{
  SplitPath, fName, , DirInit
}
else
{
  fName = 
}


;Default Texts
L_InPath := "Input Path"
L_InPathTip := "You can drag a file/folder here"
L_InPathBtnTip := "Right click to choose a folder"
L_OutPath := "Output Path"
L_OutPathTip := "You can drag a folder here"
L_ConvMode := "Conversion Mode"
L_Denoise := "Denoise"
L_Scale := "Scale"
L_Denoise_Scale := "Denoise and scale"
L_Denoise_Level := "JPEG denoise level"
L_Level := "Level"
L_OutExt := "Output extension"
L_Model := "Model"
L_BlkSize := "Block size"
L_ProcOpt := "Processor options"
L_DisableGPU := "Disable GPU"
L_ForceOpenCL := "Force OpenCL"
L_Threads := "Threads"
L_ProcInfoTip := "View processors"
L_ScaleRatio := "Scale ratio"
L_ProcTheseTypes := "Process these filetypes"
L_Go := "Go"
L_GoTip := "Right click to run and show cmd window"
L_Ready := "Ready"
L_Error := "Error"
L_EmptyPath := "Input path or output path not specified"
L_CantHandle := "Cannot handle"
L_OnePathAllowed := "Only one path allowed"
L_WrongType := "Wrong file type"
L_PicDirOnly := "Only picture file or directory"
L_ProcInfoDiag := "Processors Info"
L_ChooseInPath := "Choose Input Path"
L_ChooseOutPath := "Choose Output Path"
L_ScaleGenTip := "Calculate a ratio for wallpaper"
L_CalcTitle := "Calculate"
L_Resolution := "Resolution"
L_CalcRatio := "Suggested Ratio"
L_FileCorrupt := "Not a correct image file"
L_OK := "OK"
L_Cancel := "Cancel"
L_NotFound := "not found"
L_NotValidDir := "Not a valid directory"
L_Font="Tahoma"

FileEncoding ,UTF-8
FileRead, I18N, %A_ScriptDir%\i18n.ini

InTargetSection := false
Loop, Parse, I18N,`r,`n
{
	  If (InTargetSection = true)
	  {
	    RegExMatch(A_LoopField, "^(L_[A-Za-z0-9_]+)=""(.*)""$",Key)
	    If (Key1 <> "")
	      %Key1% := Key2
	    Else
	    {
	      RegExMatch(A_LoopField, "^\[(.*)]$",Section)
	      If (Section1 <> "")
	        Break
	    }
	  }
	  Else
	  {
	  RegExMatch(A_LoopField, "^\[(.*)]$",Section)
	  If (Section1 = A_Language)
	    InTargetSection := true
	  }
}

If !FileExist(WPath "\" Waifu2x_Exe)
{
  Msgbox, ,%L_Error%, %Waifu2x_Exe% %L_NotFound%
  exitapp
}
If !FileExist(WPath "\" Magick_Exe)
{
  Msgbox, ,%L_Error%, %Magick_Exe% %L_NotFound%
  exitapp
}

w_width  = 600
w_height = 220
w_x := (A_ScreenWidth - w_width)/5
w_y := (A_ScreenHeight - w_height)/2
Gui,2: Font, s8, %L_Font%
;Gui,2:+ToolWindow
Gui,2:+HwndMyGuiHwnd
;-=-=-=-=-=-=-=-=-=
WM_DROPFILES := 0x0233
WS_EX_ACCEPTFILES := 0x10
;-=-=-=-=-=-=-=-=-=
Gui,2:Add, Tab2, x0 y0 w0 h0 -Wrap vVTab, OneTab
Gui,2:Tab, OneTab
Gui,2:Add, Text, x5 y12 w60 h30 Center, %L_InPath%
Gui,2:Add, Edit, % "HwndHInPath r1 vInPath x70 y10 h30 w" w_width-120 " +E" WS_EX_ACCEPTFILES, %fName%
Gui,2:add,Button, % "vInPathBtn gSelectInPath y9 w30 h23 x" w_width - 40 , ...
InPath_TT = %L_InPathTip%
InPathBtn_TT = %L_InPathBtnTip%
;-=-=-=-=-=-=-=-=-=
Gui,2:Add, Text, x5 y47 w60 h15 Center, %L_OutPath%
Gui,2:Add, Edit, % "HwndHOutPath r1 vOutPath x70 y45 h30 w" w_width-120 " +E" WS_EX_ACCEPTFILES, %DirInit%
Gui,2:add,Button, % "gSelectOutPath y44 w30 h23 x" w_width - 40 , ...
OutPath_TT = %L_OutPathTip%
;-=-=-=-=-=-=-=-=-=
BusyCur:=DllCall("LoadCursor","UInt",NULL,"Int",32514,"UInt") ;IDC_WAIT
NormalCur:=DllCall("LoadCursor","UInt",NULL,"Int",32512,"UInt") ;IDC_ARROW
InputIsDir := false
OnMessage(WM_DROPFILES, "On_WM_DROPFILES")
OnMessage(0x200, "WM_MOUSEMOVE")
;-=-=-=-=-=-=-=-=-=
Gui,2:Add, GroupBox, x5 y80 w180 h75, %L_ConvMode%
;Gui,2:Add, GroupBox, x5 y80 w180 h75, %L_ConvMode%
Gui,2:Add, Radio, x10 y96 w160 h14 vConvMode, %L_Denoise%
Gui,2:Add, Radio, x10 y114 w160 h14, %L_Scale%
Gui,2:Add, Radio, x10 y132 w160 h14 Checked, %L_Denoise_Scale%
;Gui,2:Add, Radio, x10 y154 w160 h14 vConvMode4, Denoise(autodetect) and scale
Gui,2:Add, GroupBox, x5 y155 w180 h40, %L_Model%
Model_List:=""
Model_Default:=1
Loop, Files, models/* ,D
{
    If (Model_List = "")
      Model_List=%A_LoopFileName%
    Else
      Model_List=%Model_List%|%A_LoopFileName%
    
    If (A_LoopFileName = "models")
      Model_Default:=A_Index
}
Gui,2:Add, Combobox, x10 y170 w170 vOutModel Choose%Model_Default%, %Model_List%
;-=-=-=-=-=-=-=-=-=
Gui,2:Add, GroupBox, x190 y80 w125 h35, %L_Denoise_Level%
;Gui,2:Add, GroupBox, x190 y80 w125 h75, %L_Denoise_Level%
Gui,2:Add, Radio, x195 y97 w58 h14 vDenoiseLevel Checked, %L_Level% 1
Gui,2:Add, Radio, x255 y97 w58 h14, %L_Level% 2
;Gui,2:Add, Radio, x195 y116 w58 h14, %L_Level% 2
;-=-=-=-=-=-=-=-=-=
Gui,2:Add, GroupBox, x190 y155 w125 h40, %L_OutExt%
Gui,2:Add, Combobox, x195 y170 w115 vOutExt Choose1, png|jpg|bmp|tiff|webp
;-=-=-=-=-=-=-=-=-=
Gui,2:Add, GroupBox, x190 y115 w125 h40, %L_BlkSize%
Gui,2:Add, Edit, x195 y130 w115 h18 vBLKSize
;-=-=-=-=-=-=-=-=-=
Gui,2:Add, GroupBox, x320 y80 w115 h115, %L_ProcOpt%
Gui,2:Add, Checkbox, x325 y97 w100 h20 vDisableGPU, %L_DisableGPU%
Gui,2:Add, Checkbox, x325 y116 w105 h20 vForceOpenCL, %L_ForceOpenCL%
Gui,2:Add, Text, x325 y150 w105 h20, %L_Threads%
EnvGet, ProcessorCount, NUMBER_OF_PROCESSORS
Gui,2:Add, Edit, x325 y171 w80 h18 vThreads, % ProcessorCount
Gui,2:Add, UpDown, % "range1-" ProcessorCount, % ProcessorCount
Gui,2:Add, Button, x410 y170 w20 h20 gViewProcInfo vViewProcInfoV, i
ViewProcInfoV_TT = %L_ProcInfoTip%
;-=-=-=-=-=-=-=-=-=
Gui,2:Add, GroupBox, x440 y80 w150 h37, %L_ScaleRatio%
Gui,2:Add, Edit, x445 y95 w110 h18 vScaleRatio, 2
Gui,2:Add, UpDown, range1-50, 2
Gui,2:Add, Button, x560 y94 w25 h20 vScaleGenBtn gScaleGen, ...
ScaleGenBtn_TT = %L_ScaleGenTip%
;-=-=-=-=-=-=-=-=-=
Gui,2:Add, GroupBox, x440 y117 w150 h40, %L_ProcTheseTypes%
Gui,2:Add, Edit, x445 y133 w140 h20 vFTypeList, % FTypeInit
;-=-=-=-=-=-=-=-=-=
Gui,2:Add, Button, x439 y160 w152 h35 gProcess vProcessV, %L_Go%
ProcessV_TT = %L_GoTip%
;-=-=-=-=-=-=-=-=-=
Gui,2:Add, StatusBar,, %L_Ready%
;-=-=-=-=-=-=-=-=-=
Gui,2:Show, x%w_x% y%w_y% w%w_width% h%w_height%, %title1%

RatioCalc =
restool_w  = 200
restool_h = 120
restool_x := (A_ScreenWidth - restool_w)/3
restool_y := (A_ScreenHeight - restool_h)/2
ResAvailable = 800x600|1024x768|1280x720|1280x800|1360x768|1366x768|1440x900|1680x1050|1920x1080|1920x1200|1920x1440|2048x1536|2560x1440|3200x1800|4096x2160
Gui,3: Font, s8, Tahoma
Gui,3:+ToolWindow
Gui,3:+Owner2
;-=-=-=-=-=-=-=-=-=
Gui,3:Add, Text, x5 y12 w60 h30 Center, %L_Resolution%
Gui,3:Add, Combobox, % "vResForCalc gResCalc x70 y10 w" restool_w-80, %ResAvailable%
Sysget, MonResX, 0
Sysget, MonResY, 1
GuiControl, 3:Text, ResForCalc, % MonResX "x" MonResY
Gui,3:Add, GroupBox, % "x10 y35 h37 w" restool_w-20 , %L_CalcRatio%
Gui,3:Add, Text, % "vRatioCalcTxt x15 y50 h20 w" restool_w-30 , 0
Gui,3:Add, Button, x9 y80 w85 h30 gSetRatio, %L_OK%
Gui,3:Add, Button, % "gCancelRatio y80 w85 h30 x" restool_w-95, %L_Cancel%
Return

CancelRatio:
Gui,2:-Disabled
Gui,3:Hide
Return

SetRatio:
Gui,2:-Disabled
Gui,3:Submit
GuiControl, 2:Text, ScaleRatio, % RatioCalc
Return

ScaleGen:
Gui,2:submit,nohide
IfExist, %InPath%
{
  pBM := Gdip_CreateBitmapFromFile(InPath)
  If (pBM = 0)
  {
    Msgbox, %L_FileCorrupt%
    Gdip_DisposeImage(pBM)
  }
  Else
  {
    BMWidth:= Gdip_GetImageWidth(pBM)
    BMHeight:= Gdip_GetImageHeight(pBM)
    Gui,3:Show, x%restool_x% y%restool_y% w%restool_w% h%restool_h%, %L_CalcTitle%
    Gui,2:+Disabled
    Gdip_DisposeImage(pBM)
    Goto ResCalc
  }
}
Return

ResCalc:
Gui,3:submit,nohide
RegExMatch(ResForCalc, "^(\d+)x(\d+)$",ResMatch)
RatioCalc := Calculate_Ratio(BMWidth, BMHeight, ResMatch1, ResMatch2)
GuiControl, 3:Text, RatioCalcTxt, % RatioCalc
Return

3Guiclose:
Gui,2:-Disabled
Gui,3:Hide
Return

Process:
Gui,2:submit,nohide
If (InPath = "" or OutPath = "")
{
  Msgbox, 262192, %L_Error%, %L_EmptyPath%
  Return
}
;-=-=-=-=-=-=-=-=-=
;GuiControl, 2:Disable, ProcessV
GuiControl, 2:Disable, VTab
;Gui,2:+Disabled
;-=-=-=-=-=-=-=-=-=
Waifu2x_Path = "%WPath%\%Waifu2x_Exe%"
Magick_Path = "%WPath%\%Magick_Exe%"
Params =
Loop 1 {
   Goto Case-ConvMode-%ConvMode%
Case-ConvMode-1:
   Params := Params " -m noise"
   Break
Case-ConvMode-2:
   Params := Params " -m scale"
   Break
Case-ConvMode-3:
   Params := Params " -m noise_scale"
   Break
}
;-=-=-=-=-=-=-=-=-=
Loop 1 {
   Goto Case-DenoiseLevel-%DenoiseLevel%
Case-DenoiseLevel-1:
   Params := Params " --noise_level 1"
   Break
Case-DenoiseLevel-2:
   Params := Params " --noise_level 2"
   Break
}
;-=-=-=-=-=-=-=-=-=
Params := Params " --model_dir """ A_ScriptDir "\models\" OutModel """"
;-=-=-=-=-=-=-=-=-=
Params := Params " -j " Threads
;-=-=-=-=-=-=-=-=-=
If (DisableGPU = 1)
  Params := Params " --disable-gpu"
If (ForceOpenCL = 1)
  Params := Params " --force-OpenCL"
Params := Params " --scale_ratio " ScaleRatio
If (BLKSize <> "")
If BLKSize is integer
  Params := Params " --block_size " BLKSize
;-=-=-=-=-=-=-=-=-=
OutPath:=RegExReplace(OutPath, " *$", "\")
OutPath:=RegExReplace(OutPath, "\\+", "\")
If( InStr( FileExist(OutPath), "D") = 0 )
   FileCreateDir, %OutPath%
If (InputIsDir=0)
{
  SplitPath, InPath, , InPathDir, Ext, Name_no_ext
  InPathDir=%InPathDir%\
  If (InPathDir=OutPath)
    FilePrefix := "mai_"
  Outfile=%OutPath%%FilePrefix%%Name_no_ext%.%OutExt%
  Convert_File(InPath, Outfile, Params, HideCMD)
}
Else
{
  InPath:=RegExReplace(InPath, " *$", "\")
  InPath:=RegExReplace(InPath, "\\+", "\")
  If (InPath=OutPath)
    FilePrefix := "mai_"
  Loop %InPath%*
  {
    SplitPath, A_LoopFileName, , , Ext, Name_no_ext
    If Ext in %FTypeList%
    {
      InFile=%InPath%\%A_LoopFileName%
      Outfile=%OutPath%%FilePrefix%%Name_no_ext%.%OutExt%
      Convert_File(InFile, Outfile, Params, HideCMD)
    }
  }
}
;Msgbox % Params
;Msgbox %Waifu2x_Path% %Params%
;Gui,2:-Disabled
;GuiControl, 2:Enable, ProcessV
GuiControl, 2:Enable, VTab
DllCall("SetCursor","UInt",NormalCur)
HideCMD = Hide
SB_SetText(L_Ready)
Return

ViewProcInfo:
Msgbox,,%L_ProcInfoDiag%, % StdOutStream(Waifu2x_Exe " --list-processor")
Return

2Guiclose:
DllCall("DestroyCursor","Uint",BusyCur)
DllCall("DestroyCursor","Uint",NormalCur)
exitapp

SelectInPath:
StringReplace, FTypeFilter, FTypeInit, `, , `; *.,,All
FTypeFilter = *.%FTypeFilter%
FileSelectFile, InPathFromDiag, , , %L_ChooseInPath%, %FTypeFilter%
if ! ErrorLevel
Set_Edit_Content(InPathFromDiag)
Return

SelectOutPath:
FileSelectFolder, OutPathFromDiag , , , %L_ChooseOutPath%
if ! ErrorLevel
GuiControl, , % HOutPath, % OutPathFromDiag
Return

2GuiContextMenu:
if A_GuiControl = InPathBtn
{
  FileSelectFolder, InPathFromDiag , , , %L_ChooseInPath%
  if ! ErrorLevel
    Set_Edit_Content(InPathFromDiag)
}
if A_GuiControl = ProcessV
{
  HideCMD = 
  Goto Process
}
Return

WM_MOUSEMOVE(){
  Global BusyCur
  ;GuiControlGet, Enabled, 2:Enabled, ProcessV
  GuiControlGet, Enabled, 2:Enabled, VTab
  If (Enabled = false)
  {
	  DllCall("SetCursor","UInt",BusyCur)
	  Return
	}
	
	static CurrControl, PrevControl, _TT
	CurrControl := A_GuiControl
	If (CurrControl <> PrevControl){
			SetTimer, DisplayToolTip, -300
			PrevControl := CurrControl
	}
	return
	
	DisplayToolTip:
	try
			ToolTip % %CurrControl%_TT
	catch
			ToolTip
	SetTimer, RemoveToolTip, -2000
	return
	
	RemoveToolTip:
	ToolTip
	return
}

On_WM_DROPFILES(WParam, LParam, Msg, HWND) {
   Global HOutPath
   Global L_Error
   Global L_NotValidDir
   Static DragQueryFile := "Shell32.dll\DragQueryFile" . (A_IsUnicode ? "W" : "A")
   Dropped := ""
   Files := DllCall(DragQueryFile, "Ptr", WParam, "UInt", -1, "Ptr", 0, "UInt", 0, "UInt")
   Loop, % Files {
      Length := DllCall(DragQueryFile, "Ptr", WParam, "UInt", A_Index - 1, "Ptr", 0, "UInt", 0, "UInt") + 1
      VarSetCapacity(File, Length * (A_IsUnicode ? 2 : 1), 0)
      DllCall(DragQueryFile, "Ptr", WParam, "UInt", A_Index - 1, "Str", File, "UInt", Length, "UInt")
      Dropped .= File . "`r`n"
   }
   DllCall("Shell32.dll\DragFinish", "Ptr", WParam)
   DroppedPath := RTrim(Dropped, "`r`n")
   If (A_GuiControl = "InPath")
     Set_Edit_Content(DroppedPath)
   Else
   {
     If InStr( FileExist(DroppedPath), "D" )
       GuiControl, , % HOutPath, % DroppedPath
     Else
       Msgbox, 262192, %L_Error%, %L_NotValidDir%
   }
   Return 0
}

Set_Edit_Content(DroppedPath) {
   Global HInPath
   Global HOutPath
   Global InputIsDir
   Global OutExt
   Global FTypeInit
;-=-=-=-=-=-=-=-=-=
   Global L_CantHandle
   Global L_OnePathAllowed
   Global L_WrongType
   Global L_PicDirOnly
;-=-=-=-=-=-=-=-=-=
   ;Msgbox, % A_GuiControl
   IfInString, DroppedPath, `r`n
   {
     Msgbox, 262192, %L_CantHandle%, %L_OnePathAllowed%
     Return 1
   }
   If InStr( FileExist(DroppedPath), "D" )
   {
     InputIsDir := true
     GuiControl, , % HOutPath, % DroppedPath "\waifu2x_output"
   }
   Else
   {
     InputIsDir := false
     ;SplitPath, DroppedPath, Name, Dir, Ext, Name_no_ext
     SplitPath, DroppedPath, , Dir, Ext
     If Ext Not In % FTypeInit
     {
       Msgbox, 262192, %L_WrongType%,%L_PicDirOnly%
       Return 1
     }
     GuiControl, , % HOutPath, % Dir
   }
   GuiControl, , % HInPath, % DroppedPath
}

Calculate_Ratio(InWidth, InHeight, OutWidth, OutHeight) {
  RatioW := Ceil((OutWidth / InWidth)*100)/100
  RatioH := Ceil((OutHeight / InHeight)*100)/100
  If (RatioW < 1 and RatioH <1)
    Return 1
  IfGreater, RatioW, %RatioH%
    Return RatioW
  Else
    Return RatioH
}

Convert_File(InFile, Outfile, Params, HideCMD){
  Global Waifu2x_Path
  Global WPath
  Global Magick_Path
  Params = %Params% -i "%InFile%" -o "%Outfile%"
  SB_SetText("Converting " . InFile)
  RunWait, %Waifu2x_Path% %Params% , %WPath%, %HideCMD%
  RunWait, %Magick_Path% "%Outfile%.png" "%Outfile%" , %WPath%, %HideCMD%
  FileDelete, %Outfile%.png
}

;$Esc::
;exitapp
