#NoTrayIcon
#SingleInstance force

#include stdout2var.ahk
#Include Gdip.ahk

OnExit("ExitFunc")

title1=Waifu2x-CPP GUI By Maz-1 (maz_1@foxmail.com)
StringCaseSense, Off
SetFormat, Float, 0.2
WPath = %A_ScriptDir%
Waifu2x_Exe = waifu2x-converter-cpp.exe
I18nFile:=A_ScriptDir . "\i18n.ini"
SettingsFile:=A_ScriptDir . "\settings.ini"

SetWorkingDir %WPath%

HideCMD:="Hide"
FTypeInit:="png,jpg,jpeg,jfif,tif,tiff,bmp,tga"
GDIPToken := Gdip_Startup()

ConverterPID:=0
SelProcNum:=0
ManualProc:=0
CurrentProc:=""

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

ProcessorsArr:=[]
ProcessorsCmdOut:=StdOutStream(Waifu2x_Exe " --list-processor")
Loop, Parse, ProcessorsCmdOut,`r,`n
{
  RegExMatch(A_LoopField, "O)^\s{3}(\d):\s+(.*?)\s+\((\S+)\s*\):\snum_core=(\d+)$" , OutVar)
  If (OutVar.Value(1) <> "")
    ProcessorsArr.Push(OutVar.Value(1) . "|" . OutVar.Value(3) . "|" . OutVar.Value(4) . "|" . OutVar.Value(2))
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
L_OutExt := "Output extension"
L_Model := "Model"
L_BlkSize := "Block size"
L_ProcOpt := "Processor options"
L_DisableGPU := "Disable GPU"
L_ForceOpenCL := "Force OpenCL"
L_Threads := "Threads"
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
L_Type:="Type"
L_Name:="Name"
L_Cores:="Cores"
L_SelProc:="Select processor"
L_ManualProc:="Manually specify processor"
L_SelProc:="Select processor"
L_SelProcInfo:="Click to manually specify processor"
L_NoItemSelected:="No item selected"
L_AutoProc:="Select processor automatically"
L_CancelTip:="Press Ctrl+K to cancel"
L_Font:="Tahoma"

FileEncoding ,UTF-8
FileRead, I18N, %I18nFile%

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
  Msgbox, 262192, %L_Error%, %Waifu2x_Exe% %L_NotFound%
  exitapp
}

w_width  = 650
w_height = 224
w_x := (A_ScreenWidth - w_width)/5
w_y := (A_ScreenHeight - w_height)/2
Gui,Main: Font, s8, %L_Font%
;Gui,Main:+ToolWindow
Gui,Main:+HwndMainGuiHwnd
;-=-=-=-=-=-=-=-=-=
WM_DROPFILES := 0x0233
WS_EX_ACCEPTFILES := 0x10
WM_MOUSEMOVE := 0x200
;-=-=-=-=-=-=-=-=-=
Gui,Main:Add, Tab2, x0 y0 w0 h0 -Wrap vVTab, OneTab
Gui,Main:Tab, OneTab
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Main:Add, Text, x5 y12 w60 h30 Center, %L_InPath%
Gui,Main:Add, Edit, % "HwndHInPath r1 vInPath x70 y10 h30 w" w_width-120 " +E" WS_EX_ACCEPTFILES, %fName%
Gui,Main:add,Button, % "vInPathBtn gSelectInPath y9 w30 h23 x" w_width - 40 , ...
InPath_TT = %L_InPathTip%
InPathBtn_TT = %L_InPathBtnTip%
;-=-=-=-=-=-=-=-=-=
Gui,Main:Add, Text, x5 y47 w60 h15 Center, %L_OutPath%
Gui,Main:Add, Edit, % "HwndHOutPath r1 vOutPath x70 y45 h30 w" w_width-120 " +E" WS_EX_ACCEPTFILES, %DirInit%
Gui,Main:add,Button, % "gSelectOutPath y44 w30 h23 x" w_width - 40 , ...
OutPath_TT = %L_OutPathTip%
;-=-=-=-=-=-=-=-=-=
BusyCur:=DllCall("LoadCursor","UInt",NULL,"Int",32514,"UInt") ;IDC_WAIT
NormalCur:=DllCall("LoadCursor","UInt",NULL,"Int",32512,"UInt") ;IDC_ARROW
InputIsDir := false
OnMessage(WM_DROPFILES, "On_WM_DROPFILES")
OnMessage(WM_MOUSEMOVE, "On_WM_MOUSEMOVE")
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x5 y80 w150 h75, %L_ConvMode%
;Gui,Main:Add, GroupBox, x5 y80 w150 h75, %L_ConvMode%
Gui,Main:Add, Radio, hwndhConv1 x10 y96 w130 h14 vConvMode, %L_Denoise%
Gui,Main:Add, Radio, hwndhConv2 x10 y114 w130 h14, %L_Scale%
Gui,Main:Add, Radio, hwndhConv3 x10 y132 w130 h14 Checked, %L_Denoise_Scale%
Gui,Main:Add, GroupBox, x5 y155 w150 h44, %L_Model%
Model_List:=""
Model_Default:=1
Loop, Files, models\* ,D
{
    If (Model_List = "")
      Model_List=%A_LoopFileName%
    Else
      Model_List=%Model_List%|%A_LoopFileName%
    
    If (A_LoopFileName = "models")
      Model_Default:=A_Index
}
Gui,Main:Add, Combobox, x10 y170 w140 vOutModel Choose%Model_Default%, %Model_List%
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x160 y80 w145 h35, %L_Denoise_Level%
;Gui,Main:Add, GroupBox, x160 y80 w135 h75, %L_Denoise_Level%
Gui,Main:Add, Radio, hwndhdenoise1 x165 y97 w45 h14 vDenoiseLevel Checked, 1
Gui,Main:Add, Radio, hwndhdenoise2 x210 y97 w45 h14, 2
Gui,Main:Add, Radio, hwndhdenoise3 x255 y97 w45 h14, 3
;-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x160 y155 w145 h44, %L_OutExt%
Gui,Main:Add, Combobox, x165 y170 w135 vOutExt Choose1, png|jpg|bmp|tiff
;|webp
;-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x160 y115 w145 h40, %L_BlkSize%
Gui,Main:Add, Edit, x165 y130 w135 h18 vBLKSize
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x310 y80 w155 h119, %L_ProcOpt%
Gui,Main:Add, Checkbox, hwndhnogpu x315 y97 w140 h20 vDisableGPU, %L_DisableGPU%
Gui,Main:Add, Checkbox, hwndhforceocl x315 y116 w145 h20 vForceOpenCL, %L_ForceOpenCL%
Gui,Main:Add, Button, x314 y136 w147 h35 vSelProcInfoV hwndhBtnProcWin gProcInit, %L_AutoProc%
SelProcInfoV_TT:=L_SelProcInfo
EnvGet, ProcessorCount, NUMBER_OF_PROCESSORS
Gui,Main:Add, Text, x315 y177 w145 h20, %L_Threads%
Gui,Main:Add, Edit, x390 y175 w70 h18 vThreads, % ProcessorCount
Gui,Main:Add, UpDown, % "range1-" ProcessorCount, % ProcessorCount
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x470 y80 w170 h37, %L_ScaleRatio%
Gui,Main:Add, Edit, x475 y95 w130 h18 vScaleRatio, 2
Gui,Main:Add, UpDown, range1-50, 2
Gui,Main:Add, Button, x610 y94 w25 h20 vScaleGenBtn gScaleGen, ...
ScaleGenBtn_TT = %L_ScaleGenTip%
;-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x470 y117 w170 h40, %L_ProcTheseTypes%
Gui,Main:Add, Edit, x475 y133 w160 h20 vFTypeList, % FTypeInit
;-=-=-=-=-=-=-=-=-=
;Gui,Main:Tab
Gui,Main:Add, Button, x469 y160 w172 h39 hwndhBtnGo gProcess vProcessV, %L_Go%
ProcessV_TT = %L_GoTip%
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Main:Add, StatusBar,, %L_Ready%
;-=-=-=-=-=-=-=-=-=
;tobedone
if FileExist(SettingsFile)
{
  IniRead, StoredConvMode, %SettingsFile%, Main, convmode
    hConv:=hConv%StoredConvMode%
    GuiControl, , %hConv%, 1
  IniRead, StoredModel, %SettingsFile%, Main, model
    if FileExist(A_ScriptDir . "\models\" . StoredModel)
      GuiControl, Main:Text, OutModel, % StoredModel
  IniRead, StoredDenoiseLevel, %SettingsFile%, Main, denoise
    hdenoise:=hdenoise%StoredDenoiseLevel%
    GuiControl, , %hdenoise%, 1
  IniRead, StoredBlockSize, %SettingsFile%, Main, blocksize
    GuiControl, Main:Text, BLKSize, % StoredBlockSize
  IniRead, StoredExtension, %SettingsFile%, Main, extension
    GuiControl, Main:Text, OutExt, % StoredExtension
  IniRead, StoredNGPU, %SettingsFile%, Main, nogpu
    StoredNGPU:=(StoredNGPU)?1:0
    GuiControl, , %hnogpu%, %StoredNGPU%
  IniRead, StoredFOCL, %SettingsFile%, Main, forceocl
    StoredFOCL:=(StoredFOCL)?1:0
    GuiControl, , %hforceocl%, %StoredFOCL%
  IniRead, StoredDPROC, %SettingsFile%, Main, defaultproc
    If (HasVal(ProcessorsArr, StoredDPROC)<>0)
    {
      ArrayTmp:=StrSplit(StoredDPROC , "|")
      SelProcNum:=ArrayTmp[1]
      CurrentProc:=StoredDPROC
      ManualProc:=1
      ProcsSetText(ArrayTmp[2], ArrayTmp[4])
    }
  IniRead, StoredThreads, %SettingsFile%, Main, threads
    If (StoredThreads <= ProcessorCount)
      GuiControl, Main:Text, Threads, % StoredThreads
  IniRead, StoredRatio, %SettingsFile%, Main, ratio
    GuiControl, Main:Text, ScaleRatio, % StoredRatio
  IniRead, StoredFtypes, %SettingsFile%, Main, filetypes
    GuiControl, Main:Text, FTypeList, % StoredFtypes
}
;-=-=-=-=-=-=-=-=-=
Gui,Main:Show, x%w_x% y%w_y% w%w_width% h%w_height%, %title1%
;-=-=-=-=-=-=-=-=-=



RatioCalc =
restool_w  = 200
restool_h = 120
restool_x := (A_ScreenWidth - restool_w)/3
restool_y := (A_ScreenHeight - restool_h)/2
ResAvailable = 800x600|1024x768|1280x720|1280x800|1360x768|1366x768|1440x900|1680x1050|1920x1080|1920x1200|1920x1440|2048x1536|2560x1440|3200x1800|4096x2160
Gui,Res: Font, s8, %L_Font%
Gui,Res:+ToolWindow
Gui,Res:+OwnerMain
;-=-=-=-=-=-=-=-=-=
Gui,Res:Add, Text, x5 y12 w60 h30 Center, %L_Resolution%
Gui,Res:Add, Combobox, % "vResForCalc gResCalc x70 y10 w" restool_w-80, %ResAvailable%
Sysget, MonResX, 0
Sysget, MonResY, 1
GuiControl, Res:Text, ResForCalc, % MonResX . "x" . MonResY
Gui,Res:Add, GroupBox, % "x10 y35 h37 w" restool_w-20 , %L_CalcRatio%
Gui,Res:Add, Text, % "vRatioCalcTxt x15 y50 h20 w" restool_w-30 , 0
Gui,Res:Add, Button, x9 y80 w85 h30 gSetRatio, %L_OK%
Gui,Res:Add, Button, % "gCancelRatio y80 w85 h30 x" restool_w-95, %L_Cancel%
;-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Proc: Font, s8, %L_Font%
Gui,Proc:+ToolWindow
Gui,Proc:+OwnerMain
Gui,Proc: Add, CheckBox, x5 y5 h14 vManualProcChecked hwndhManualProc -Checked, %L_ManualProc%
Gui,Proc: Add, ListView, x5 y25 w400 h200 vProcListLV gLVSelect AltSubmit NoSortHdr -Multi -LV0x10, No.|%L_Type%|%L_Cores%|%L_Name%
Gui,Proc: Default
LV_ModifyCol(1, 30)
LV_ModifyCol(2, 50)
LV_ModifyCol(3, 50)
LV_ModifyCol(4, 265)
Gui,Proc: Add, Button, x5 y230 w195 h30 gProcOk, %L_OK%
Gui,Proc: Add, Button, x210 y230 w195 h30 gProcCancel, %L_Cancel%
Control, uncheck,,, ahk_id %hManualProc%
Return

ProcInit:
Gui,Proc: Default
LV_Delete()
for index, element in ProcessorsArr
{
  ArrayTmp:=StrSplit(element , "|")
  LV_Add( ,ArrayTmp[1], ArrayTmp[2], ArrayTmp[3], ArrayTmp[4])
}
Gui,Main: Default
Gui,Main:+Disabled
Gui,Proc: Show, ,%L_SelProc%
Return

LVSelect:
Gui,Proc: Submit, nohide
If (LV_GetNext(0)<>0)
{
  If (A_GuiControlEvent="Normal")
    Control, check,,, ahk_id %hManualProc%
  Else If (A_GuiControlEvent="DoubleClick")
    GoSub ProcOk
}
Return

ProcOk:
Gui,Proc: Submit, nohide
Gui,Proc: Default
RowNum:=LV_GetNext(0)
LV_GetText(ProcNum, RowNum, 1)
LV_GetText(ProcType, RowNum, 2)
LV_GetText(ProcCores, RowNum, 3)
LV_GetText(ProcName, RowNum, 4)
ManualProc:=ManualProcChecked
If (ManualProc=1)
{
  If (RowNum<>0)
  {
    SelProcNum:=ProcNum
    ProcsSetText(ProcType, ProcName)
    CurrentProc:=ProcNum . "|" ProcType . "|" ProcCores . "|" . ProcName
  }
  Else
  {
    Msgbox, 262192, %L_Error%, %L_NoItemSelected%
    Return
  }
}
Else
{
   ControlSetText, , %L_AutoProc%, ahk_id %hBtnProcWin%
   CurrentProc:=""
}
Gui,Main:-Disabled
Gui,Proc: Hide
Return

ProcCancel:
Gui,Main:-Disabled
Gui,Proc: Hide
Return

ProcGuiclose:
GoSub ProcCancel
Return

CancelRatio:
Gui,Main:-Disabled
Gui,Res:Hide
Return

SetRatio:
Gui,Main:-Disabled
Gui,Res:Submit
GuiControl, Main:Text, ScaleRatio, % RatioCalc
Return

ScaleGen:
Gui,Main:submit,nohide
IfExist, %InPath%
{
  pBM := Gdip_CreateBitmapFromFile(InPath)
  If (pBM = 0)
  {
    Msgbox, 262192, %L_Error%, %L_FileCorrupt%
    Gdip_DisposeImage(pBM)
  }
  Else
  {
    BMWidth:= Gdip_GetImageWidth(pBM)
    BMHeight:= Gdip_GetImageHeight(pBM)
    Gui,Res:Show, x%restool_x% y%restool_y% w%restool_w% h%restool_h%, %L_CalcTitle%
    Gui,Main:+Disabled
    Gdip_DisposeImage(pBM)
    Goto ResCalc
  }
}
Return

ResCalc:
Gui,Res:submit,nohide
RegExMatch(ResForCalc, "^(\d+)x(\d+)$",ResMatch)
RatioCalc := Calculate_Ratio(BMWidth, BMHeight, ResMatch1, ResMatch2)
GuiControl, Res:Text, RatioCalcTxt, % RatioCalc
Return

ResGuiclose:
GoSub CancelRatio
Return

Process:
GuiControlGet, Enabled, Main:Enabled, VTab
If (Enabled=False)
  Return
Gui,Main:submit,nohide
If (InPath = "" or OutPath = "")
{
  Msgbox, 262192, %L_Error%, %L_EmptyPath%
  Return
}
ControlSetText, , %L_CancelTip%, ahk_id %hBtnGo%
;-=-=-=-=-=-=-=-=-=
GuiControl, Main:Disable, VTab
;-=-=-=-=-=-=-=-=-=
Waifu2x_Path = "%WPath%\%Waifu2x_Exe%"
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
Params := Params " --noise_level " . DenoiseLevel
;-=-=-=-=-=-=-=-=-=
Params := Params " --model_dir """ A_ScriptDir "\models\" OutModel """"
;-=-=-=-=-=-=-=-=-=
Params := Params " -j " Threads
;-=-=-=-=-=-=-=-=-=
If (DisableGPU = 1)
  Params := Params " --disable-gpu"
If (ForceOpenCL = 1)
  Params := Params " --force-OpenCL"
If (ManualProc=1)
{
  Params := Params " --processor " SelProcNum
}
Params := Params " --scale_ratio " ScaleRatio
If (BLKSize <> "")
If BLKSize is integer
  Params := Params " --block_size " BLKSize
;-=-=-=-=-=-=-=-=-=
;Msgbox % Params
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
  Loop, Files, %InPath%*, F
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
GuiControl, Main:Enable, VTab
ConverterPID:=0
ControlSetText, , %L_OK%, ahk_id %hBtnGo%
DllCall("SetCursor","UInt",NormalCur)
HideCMD = Hide
SB_SetText(L_Ready)
Return

MainGuiclose:
DllCall("DestroyCursor","Uint",BusyCur)
DllCall("DestroyCursor","Uint",NormalCur)
exitapp

SelectInPath:
Gui,Main:+OwnDialogs
StringReplace, FTypeFilter, FTypeInit, `, , `; *.,,All
FTypeFilter = *.%FTypeFilter%
FileSelectFile, InPathFromDiag, , , %L_ChooseInPath%, %FTypeFilter%
if ! ErrorLevel
Set_Edit_Content(InPathFromDiag)
Return

SelectOutPath:
Gui,Main:+OwnDialogs
FileSelectFolder, OutPathFromDiag , , , %L_ChooseOutPath%
if ! ErrorLevel
GuiControl, , % HOutPath, % OutPathFromDiag
Return

MainGuiContextMenu:
if A_GuiControl = InPathBtn
{
  Gui,Main:+OwnDialogs
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

On_WM_MOUSEMOVE(){
  Global BusyCur
  Global ConverterPID
  If (ConverterPID<>0)
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
  Global ConverterPID
  Params = %Params% -i "%InFile%" -o "%Outfile%"
  SplitPath, InFile, InFileName
  SB_SetText("Converting " . InFileName)
  RunWait, %Waifu2x_Path% %Params% , %WPath%, %HideCMD%, ConverterPID
  Convert_Format(Outfile . ".png", OutFile)
  FileDelete, %Outfile%.png
}

Convert_Format(InFile, OutFile)
{
  Result:=False
  If (SubStr(InFile, -2)<>SubStr(OutFile, -2))
  {
    pBitmap := Gdip_CreateBitmapFromFile(InFile)
    If (pBitmap<>0)
    {
      Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)
      pBitmapNew := Gdip_CreateBitmap(Width, Height)
      GNew := Gdip_GraphicsFromImage(pBitmapNew),	Gdip_SetInterpolationMode(GNew, 7)
      Gdip_DrawImage(GNew, pBitmap, 0, 0, Width, Height, 0, 0, Width, Height)
      Gdip_SaveBitmapToFile(pBitmapNew, OutFile)
      If FileExist(OutFile)
        Result:=True
      Gdip_DisposeImage(pBitmap),	Gdip_DeleteGraphics(GNew), Gdip_DisposeImage(pBitmapNew)
    }
  }
  Else
    FileMove, InFile, OutFile
	Return Result
}

ProcsSetText(ProcType, ProcName)
{
  Global hBtnProcWin
  
  If (StrLen(ProcName) < 20)
    ControlSetText, , %ProcName%`r`n(%ProcType%), ahk_id %hBtnProcWin%
  Else If (StrLen(ProcName)+StrLen(ProcType) > 38)
    ControlSetText, , % SubStr(ProcName, 1, 35) . "... (" . ProcType . ")", ahk_id %hBtnProcWin%
  Else
    ControlSetText, , %ProcName% (%ProcType%), ahk_id %hBtnProcWin%
}

HasVal(haystack, needle) {
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}

ExitFunc() 
{
  Global GDIPToken
  Global SettingsFile
  Global ConvMode, OutModel, DenoiseLevel, OutExt, BLKSize, DisableGPU
  Global ForceOpenCL, CurrentProc, Threads, ScaleRatio, FTypeList
  Gui,Main:submit
  IniWrite, %ConvMode%, %SettingsFile%, Main, convmode
  IniWrite, %OutModel%, %SettingsFile%, Main, model
  IniWrite, %DenoiseLevel%, %SettingsFile%, Main, denoise
  IniWrite, %OutExt%, %SettingsFile%, Main, extension
  IniWrite, %BLKSize%, %SettingsFile%, Main, blocksize
  IniWrite, %DisableGPU%, %SettingsFile%, Main, nogpu
  IniWrite, %ForceOpenCL%, %SettingsFile%, Main, forceocl
  IniWrite, %CurrentProc%, %SettingsFile%, Main, defaultproc
  IniWrite, %Threads%, %SettingsFile%, Main, threads
  IniWrite, %ScaleRatio%, %SettingsFile%, Main, ratio
  IniWrite, %FTypeList%, %SettingsFile%, Main, filetypes
  Gdip_Shutdown(GDIPToken)
}

^K::
WinGet, active_id, ID, A
GuiControlGet, Enabled, Main:Enabled, VTab
If (active_id=MainGuiHwnd and Enabled=False)
  Process, Close, %ConverterPID%
ConverterPID:=0
Return

$Esc::
WinGet, active_id, ID, A
GuiControlGet, Enabled, Main:Enabled, VTab
If (active_id=MainGuiHwnd and Enabled=True)
  exitapp
Return