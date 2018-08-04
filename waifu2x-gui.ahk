#NoTrayIcon
#SingleInstance force

#include stdout2var.ahk
#Include Gdip.ahk
#Include Class_CtlColors.ahk

title1=Waifu2x-CPP GUI By Maz-1 (maz_1@foxmail.com)
StringCaseSense, Off
SetFormat, Float, 0.2
WPath = %A_ScriptDir%
Waifu2x_Exe = waifu2x-converter-cpp.exe
I18nFile:=A_ScriptDir . "\i18n.ini"
SettingsFile:=A_ScriptDir . "\settings.ini"

SetWorkingDir %WPath%

FTypeInit:="png,jpg,jpeg,jfif,tif,tiff,bmp,tga"
ErrorColor:="FFC0C0"
GDIPToken := Gdip_Startup()

ConverterPID:=0
SelProcNum:=0
ManualProc:=0
CurrentProc:=""
LoopState:=False
Alert:=False

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
L_Quality := "Quality"
L_Model := "Model"
L_BlkSize := "Block size"
L_ProcOpt := "Processor options"
L_DisableGPU := "Disable GPU"
L_ForceOpenCL := "Force OpenCL"
L_Threads := "Threads"
L_ScaleRatio := "Scale ratio"
L_ProcTheseTypes := "Process these filetypes"
L_Go := "Go"
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
L_Stop:="Stop"
L_SBarPrefix:="Converting "
L_Font:="Tahoma"
L_ShowLog:="Show command line output"

If !FileExist(I18nFile)
FileInstall, i18n.ini, %I18nFile%

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

h_withlog:=353
h_withoutlog:=243
Gui,Main: Font, s8, %L_Font%
Gui,Main:+HwndMainGuiHwnd
;-=-=-=-=-=-=-=-=-=
WM_DROPFILES := 0x0233
WM_MOUSEMOVE := 0x200
WM_LBUTTONUP := 0x202
WS_EX_ACCEPTFILES := 0x10
;-=-=-=-=-=-=-=-=-=
Gui,Main:Add, Tab2, x0 y0 w0 h0 -Wrap vVTab, OneTab
Gui,Main:Tab, OneTab
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Main:Add, Text, x5 y12 w60 Center, %L_InPath%
Gui,Main:Add, Edit, HwndHInPath r1 vInPath x70 y10 h30 w530 gRevertInPathColor +E%WS_EX_ACCEPTFILES%, %fName%
CtlColors.Attach(HInPath, "", "")
Gui,Main:add,Button, vInPathBtn gSelectInPath y9 w30 h23 x610 , ...
InPath_TT = %L_InPathTip%
InPathBtn_TT = %L_InPathBtnTip%
;-=-=-=-=-=-=-=-=-=
Gui,Main:Add, Text, x5 y47 w60 Center, %L_OutPath%
Gui,Main:Add, Edit, HwndHOutPath r1 vOutPath x70 y45 h30 w530 gRevertOutPathColor +E%WS_EX_ACCEPTFILES%, %DirInit%
CtlColors.Attach(HOutPath, "", "")
Gui,Main:add,Button, gSelectOutPath y44 w30 h23 x610 , ...
OutPath_TT = %L_OutPathTip%
;-=-=-=-=-=-=-=-=-=
;BusyCur:=DllCall("LoadCursor","UInt",NULL,"Int",32514,"UInt") ;IDC_WAIT
;NormalCur:=DllCall("LoadCursor","UInt",NULL,"Int",32512,"UInt") ;IDC_ARROW
OnMessage(WM_DROPFILES, "On_WM_DROPFILES")
OnMessage(WM_MOUSEMOVE, "On_WM_MOUSEMOVE")
OnMessage(WM_LBUTTONUP, "On_WM_LBUTTONUP")
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x5 y80 w150 h75, %L_ConvMode%
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
Gui,Main:Add, DropDownList, x10 y170 w140 vOutModel Choose%Model_Default%, %Model_List% ;gSetDenoiseLevelRange
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x160 y80 w145 h35, %L_Denoise_Level%
Gui,Main:Add, Slider, hwndhdenoise x165 y95 w120 h18 vDenoiseLevel AltSubmit gSetSliderLabel Range1-3, 1
Gui,Main:Add, Text, x285 y95 w10 h18 vCurDenoiseLevel Center, 1
;-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x160 y155 w145 h44, %L_OutExt%
Gui,Main:Add, DropDownList, x165 y170 w45 vOutExt gExtChanged hwndhExt Choose1, png|jpg|bmp|tiff
;|webp
Gui,Main:Add, Text, x210 y172 w45 h20 Right, %L_Quality%
Gui,Main:Add, Combobox, vOutQuality x260 y170 w40 Choose2, 100|75
;-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x160 y115 w145 h40, %L_BlkSize%
Gui,Main:Add, Edit, x165 y130 w135 h18 Number vBLKSize
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x310 y80 w155 h119, %L_ProcOpt%
Gui,Main:Add, Checkbox, hwndhnogpu x315 y97 w140 h20 vDisableGPU, %L_DisableGPU%
Gui,Main:Add, Checkbox, hwndhforceocl x315 y116 w145 h20 vForceOpenCL, %L_ForceOpenCL%
Gui,Main:Add, Button, x314 y136 w147 h35 vSelProcInfoV hwndhBtnProcWin gProcInit, %L_AutoProc%
SelProcInfoV_TT:=L_SelProcInfo
EnvGet, ProcessorCount, NUMBER_OF_PROCESSORS
Gui,Main:Add, Text, x315 y177 w145 h20, %L_Threads%
Gui,Main:Add, Edit, x390 y175 w70 h18 Number vThreads gThreadsCheck hwndHThreads, % ProcessorCount
CtlColors.Attach(HThreads, "", "")
Gui,Main:Add, UpDown, % "range1-" ProcessorCount, % ProcessorCount
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x470 y80 w170 h37, %L_ScaleRatio%
Gui,Main:Add, Edit, x475 y95 w130 h18 vScaleRatio gScaleRatioCheck hwndHScaleRatio, 2
Gui,Main:Add, UpDown, range1-50, 2
Gui,Main:Add, Button, x610 y94 w25 h20 vScaleGenBtn gScaleGen, ...
ScaleGenBtn_TT = %L_ScaleGenTip%
;-=-=-=-=-=-=-=-=-=
Gui,Main:Add, GroupBox, x470 y117 w170 h40, %L_ProcTheseTypes%
Gui,Main:Add, Edit, x475 y133 w160 h20 vFTypeList gFTypeListCheck hwndhFTypeList, % FTypeInit
CtlColors.Attach(hFTypeList, "", "")
;-=-=-=-=-=-=-=-=-=
;Hotkey, IfWinActive, ahk_id %MainGuiHwnd%
;Hotkey, ^k, KillConverter
Gui,Main:Add, Checkbox, x5 y205 h15 vShowLog gToggleLog, %L_ShowLog%
Gui,Main:Tab
Gui,Main:Add, Button, x469 y160 w172 h39 hwndhBtnGo gProcess vProcessV, %L_Go%
Gui,Main:Add, StatusBar,, %L_Ready%
Gui,Main:Font, s7, Lucida Console
Gui,Main:Add, Edit, x5 y225 w635 r10 vVerboseLog hwndhVLog ReadOnly
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
;-=-=-=-=-=-=-=-=-=
if FileExist(SettingsFile)
{
  IniRead, ConvMode, %SettingsFile%, Main, convmode, 3
    hConv:=hConv%ConvMode%
    GuiControl, , %hConv%, 1
  IniRead, OutModel, %SettingsFile%, Main, model
    if FileExist(A_ScriptDir . "\models\" . OutModel)
      GuiControl, Main:ChooseString, OutModel, % OutModel
      ;SetDenoiseLevelRange(OutModel)
  IniRead, DenoiseLevel, %SettingsFile%, Main, denoise, 1
    GuiControl, , %hdenoise%, %DenoiseLevel%
    GuiControl, Main:Text, CurDenoiseLevel, %DenoiseLevel%
  IniRead, BLKSize, %SettingsFile%, Main, blocksize, %A_Space%
    GuiControl, Main:Text, BLKSize, % BLKSize
  IniRead, OutExt, %SettingsFile%, Main, extension, png
    GuiControl, Main:ChooseString, OutExt, % OutExt
    If (OutExt <> "jpg")
      GuiControl, Main:Disable, OutQuality
  IniRead, OutQuality, %SettingsFile%, Main, quality, 75
    GuiControl, Main:Text, OutQuality, % OutQuality
  IniRead, DisableGPU, %SettingsFile%, Main, nogpu, 0
    GuiControl, , %hnogpu%, %DisableGPU%
  IniRead, ForceOpenCL, %SettingsFile%, Main, forceocl, 0
    GuiControl, , %hforceocl%, %ForceOpenCL%
  IniRead, CurrentProc, %SettingsFile%, Main, defaultproc
    If (HasVal(ProcessorsArr, CurrentProc)<>0)
    {
      ArrayTmp:=StrSplit(CurrentProc , "|")
      SelProcNum:=ArrayTmp[1]
      ManualProc:=1
      ProcsSetText(ArrayTmp[2], ArrayTmp[4])
    }
  IniRead, Threads, %SettingsFile%, Main, threads, %ProcessorCount%
    If (Threads <= ProcessorCount and Threads > 0)
      GuiControl, Main:Text, Threads, % Threads
  IniRead, ScaleRatio, %SettingsFile%, Main, ratio
    ScaleRatioFormat(ScaleRatio)
    GuiControl, Main:Text, ScaleRatio, % ScaleRatio
  IniRead, FTypeList, %SettingsFile%, Main, filetypes, %A_Space%
    If (CheckFTypeList(FTypeList)<>0)
      GuiControl, Main:Text, FTypeList, % FTypeList
  IniRead, ShowLog, %SettingsFile%, Main, showlog, 1
    GuiControl,Main:, ShowLog, %ShowLog%
    If (ShowLog=0)
    {
      GuiControl, Main:Hide, VerboseLog
      Gui,Main:Show, h%h_withoutlog%, %title1%
    }
    Else
      Gui,Main:Show, h%h_withlog%, %title1%
}
Else
  Gui,Main:Show, h%h_withlog%, %title1%
hQualityEdit := ComboBoxGetHEDIT(hQuality)
WinSet, Style, +0x2000, ahk_id %hQualityEdit%
;-=-=-=-=-=-=-=-=-=

RatioCalc =
ResAvailable = 800x600|1024x768|1280x720|1280x800|1360x768|1366x768|1440x900|1680x1050|1920x1080|1920x1200|1920x1440|2048x1536|2560x1440|3200x1800|4096x2160
Gui,Res: Font, s8, %L_Font%
;Gui,Res:+ToolWindow
Gui,Res:+OwnerMain
;-=-=-=-=-=-=-=-=-=
Gui,Res:Add, Text, x5 y12 w60 h30 Center, %L_Resolution%
Gui,Res:Add, Combobox, vResForCalc gResCalc x70 y10 w120, %ResAvailable%
Sysget, MonResX, 0
Sysget, MonResY, 1
GuiControl, Res:Text, ResForCalc, % MonResX . "x" . MonResY
Gui,Res:Add, GroupBox, x10 y35 h37 w180 , %L_CalcRatio%
Gui,Res:Add, Text, vRatioCalcTxt x15 y50 h20 w170 , 0
Gui,Res:Add, Button, x9 y80 w85 h30 gSetRatio, %L_OK%
Gui,Res:Add, Button, gCancelRatio y80 w85 h30 x105, %L_Cancel%
;-=-=-=-=-=-=-=-=-=-=-=-=
Gui,Proc: Font, s8, %L_Font%
;Gui,Proc:+ToolWindow
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
    CurrentProc:=ProcNum . "|" . ProcType . "|" . ProcCores . "|" . ProcName
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
    Gui,Res:Show, , %L_CalcTitle%
    Gui,Main:+Disabled
    Gdip_DisposeImage(pBM)
    Goto ResCalc
  }
}
Return

;SetDenoiseLevelRange:
;GuiControlGet, OutModel, , OutModel
;SetDenoiseLevelRange(OutModel)
;Return

ExtChanged:
ControlGetText, CurrentExt,, ahk_id %hExt%
If (CurrentExt = "jpg")
  GuiControl, Main:Enable, OutQuality
Else
  GuiControl, Main:Disable, OutQuality
Return

ScaleRatioCheck:
GuiControlGet, InVar, , ScaleRatio
EnsureNum(InVar, HScaleRatio)
Return

ThreadsCheck:
If (Alert:=True)
{
  CtlColors.Change(HThreads, "", "")
  Alert:=False
}
GuiControlGet, InVar, , Threads
EnsureIntRange(InVar, ProcessorCount, HThreads, ProcessorCount)
Return

FTypeListCheck:
If (Alert:=True)
{
  Alert:=False
  CtlColors.Change(hFTypeList, "", "")
}
GuiControlGet, InVar, , FTypeList
EnsureFTypeList(InVar, hFTypeList)
Return

RevertInPathColor:
If (Alert:=True)
{
  Alert:=False
  CtlColors.Change(HInPath, "", "")
}
Return

RevertOutPathColor:
If (Alert:=True)
{
  Alert:=False
  CtlColors.Change(HOutPath, "", "")
}
Return

SetSliderLabel:
GuiControlGet, CurDenoiseLevel, , DenoiseLevel
If (CurDenoiseLevel<>"")
   GuiControl, Main:Text, CurDenoiseLevel, %CurDenoiseLevel%
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

ToggleLog:
GuiControlGet, LogEnabled, , ShowLog
If (LogEnabled=False)
{
  GuiControl, Main:Hide, VerboseLog
  Gui,Main:Show, h%h_withoutlog%
}
Else
{
  GuiControl, Main:Show, VerboseLog
  Gui,Main:Show, h%h_withlog%
  
}
Return

Process:
GuiControlGet, Enabled, Main:Enabled, VTab
If (Enabled=False)
{
  On_WM_LBUTTONUP()
  Return
}
Gui,Main:submit,nohide
If (FileExist(InPath)="")
{
  CtlColors.Change(HInPath, ErrorColor, "")
  Alert:=True
  GuiControl,Main:Focus, InPath
  SoundPlay, *64
  Return
}
If (Threads = "")
{
  CtlColors.Change(HThreads, ErrorColor, "")
  Alert:=True
  GuiControl,Main:Focus, Threads
  SoundPlay, *64
  Return
}
If (OutPath = "")
{
  CtlColors.Change(HOutPath, ErrorColor, "")
  Alert:=True
  GuiControl,Main:Focus, OutPath
  SoundPlay, *64
  Return
}
If (CheckFTypeList(FTypeList)=0)
{
  CtlColors.Change(hFTypeList, ErrorColor, "")
  Alert:=True
  GuiControl,Main:Focus, FTypeList
  SoundPlay, *64
  Return
}
ScaleRatioFormat(ScaleRatio)
ControlSetText, , %L_Stop%, ahk_id %hBtnGo%
;GuiControl, Main:Text, VerboseLog
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
OutPath:=RegExReplace(OutPath, " *$", "\")
OutPath:=RegExReplace(OutPath, "\\+", "\")
If( InStr( FileExist(OutPath), "D") = 0 )
   FileCreateDir, %OutPath%
If InStr( FileExist(InPath), "D" )
{
  InPath:=RegExReplace(InPath, " *$", "\")
  InPath:=RegExReplace(InPath, "\\+", "\")
  If (InPath=OutPath)
    FilePrefix := "mai_"
  LoopState:=True
  IndexMin:=0
  Loop, Files, %InPath%*, F
  {
    If (LoopState=False)
      Break
    SplitPath, A_LoopFileName, , , Ext, Name_no_ext
    If Ext in %FTypeList%
    {
      If (IndexMin=0)
      {
        IndexMin:=A_Index
        GuiControl, Main:Text, VerboseLog, Parameters: %Params%`r`n
      }
      InFile=%InPath%\%A_LoopFileName%
      Outfile=%OutPath%%FilePrefix%%Name_no_ext%.%OutExt%
      Convert_File(InFile, Outfile, Params)
    }
  }
  LoopState:=False
}
Else
{
  SplitPath, InPath, , InPathDir, Ext, Name_no_ext
  InPathDir=%InPathDir%\
  If (InPathDir=OutPath)
    FilePrefix := "mai_"
  Outfile=%OutPath%%FilePrefix%%Name_no_ext%.%OutExt%
  GuiControl, Main:Text, VerboseLog, Parameters: %Params%`r`n
  Convert_File(InPath, Outfile, Params)
}
GuiControl, Main:Enable, VTab
ConverterPID:=0
ControlSetText, , %L_Go%, ahk_id %hBtnGo%
;DllCall("SetCursor","UInt",NormalCur)
SB_SetText(L_Ready)
Return

MainGuiclose:
MainGuiEscape:
;DllCall("DestroyCursor","Uint",BusyCur)
;DllCall("DestroyCursor","Uint",NormalCur)
Gui,Main:submit
IniWrite, %ConvMode%, %SettingsFile%, Main, convmode
IniWrite, %OutModel%, %SettingsFile%, Main, model
IniWrite, %DenoiseLevel%, %SettingsFile%, Main, denoise
IniWrite, %OutExt%, %SettingsFile%, Main, extension
IniWrite, %OutQuality%, %SettingsFile%, Main, quality
IniWrite, %BLKSize%, %SettingsFile%, Main, blocksize
IniWrite, %DisableGPU%, %SettingsFile%, Main, nogpu
IniWrite, %ForceOpenCL%, %SettingsFile%, Main, forceocl
IniWrite, %CurrentProc%, %SettingsFile%, Main, defaultproc
IniWrite, %Threads%, %SettingsFile%, Main, threads
ScaleRatioFormat(ScaleRatio)
IniWrite, %ScaleRatio%, %SettingsFile%, Main, ratio
IniWrite, %ShowLog%, %SettingsFile%, Main, showlog
If (CheckFTypeList(FTypeList)<>0)
  IniWrite, %FTypeList%, %SettingsFile%, Main, filetypes
Else If (FTypeList="")
  IniDelete, %SettingsFile%, Main , filetypes
Gdip_Shutdown(GDIPToken)
Gui,Main:Destroy
Gui,Res:Destroy
Gui,Proc:Destroy
CtlColors.Free()
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
Return

On_WM_LBUTTONUP(){
  Global LoopState
  Global ConverterPID
  GuiControlGet, Enabled, Main:Enabled, VTab
  If (Enabled=False and A_GuiControl="ProcessV")
  {
    LoopState:=False
    Process, Close, %ConverterPID%
  }
}

On_WM_MOUSEMOVE(){
  ;Global BusyCur
  ;Global ConverterPID
  ;If (ConverterPID<>0)
  ;{
	;  DllCall("SetCursor","UInt",BusyCur)
	;  Return
	;}
	
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
   Global OutExt
   Global FTypeInit
;-=-=-=-=-=-=-=-=-=
   Global L_CantHandle
   Global L_OnePathAllowed
   Global L_WrongType
   Global L_PicDirOnly
;-=-=-=-=-=-=-=-=-=
   IfInString, DroppedPath, `r`n
   {
     Msgbox, 262192, %L_CantHandle%, %L_OnePathAllowed%
     Return 1
   }
   If InStr( FileExist(DroppedPath), "D" )
   {
     GuiControl, , % HOutPath, % DroppedPath "\waifu2x_output"
   }
   Else
   {
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

Convert_File(InFile, Outfile, Params){
  Global Waifu2x_Path
  Global WPath
  Global ConverterPID
  Global L_SBarPrefix
  Global OutQuality
  Params = %Params% -i "%InFile%" -o "%Outfile%"
  SplitPath, InFile, InFileName
  SB_SetText(L_SBarPrefix . InFileName)
  GuiControlGet, LogEnabled, , ShowLog
  If (LogEnabled=True)
    StdOutStream( Waifu2x_Path . " " . Params, "DumpCmdOut", WPath, ConverterPID)
  Else
    RunWait, %Waifu2x_Path% %Params%, %WPath%, Hide, ConverterPID
  Convert_Format(Outfile . ".png", OutFile, OutQuality)
  FileDelete, %Outfile%.png
}

DumpCmdOut(TxtNew, TxtIndex)
{
  Global MainGuiHwnd
  Global hVLog
  ;GuiControlGet, TxtOrig, , VerboseLog
  ;GuiControl, Main:Text, VerboseLog, %TxtOrig%%TxtNew%
  AppendText(hVLog, &TxtNew)
  WinGet, active_id, ID, A
  If (active_id=MainGuiHwnd)
    ControlSend, , ^{End}, ahk_id %hVLog%
}

Convert_Format(InFile, OutFile, Quality)
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
      Gdip_SaveBitmapToFile(pBitmapNew, OutFile, Quality)
      If FileExist(OutFile)
        Result:=True
      Gdip_DisposeImage(pBitmap),	Gdip_DeleteGraphics(GNew), Gdip_DisposeImage(pBitmapNew)
    }
  }
  Else
  {
    FileMove, %InFile%, %OutFile%
    Result:=ErrorLevel
	}
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

EnsureFTypeList(Variable, ControlID)
{
  containsSpaces:=RegExMatch(Variable,"[\s]")
  RegExMatch(Variable, "\w+(,\w+)*,?", CorrectVar)
  ControlGet,inPos, CurrentCol,,, ahk_id %ControlID%
  if (Variable==CorrectVar && !containsSpaces)
    Return
  GuiControl,,%ControlID%,%CorrectVar%
  PostMessage,0x00B1,inPos-2,inPos-2,, ahk_id %ControlID%
}

EnsureIntRange(Variable, Max, ControlID, DefaultVal)
{
  ControlGet, inPos, CurrentCol,,, ahk_id %ControlID%
	if ((Variable<=Max and Variable>0) or Variable="" ) 
		return
	GuiControl,,%ControlID%,%DefaultVal%
	PostMessage,0x00B1,inPos-1,inPos-1,, ahk_id %ControlID%
}

EnsureNum(Variable, ControlID)
{
	containsSpaces:=RegExMatch(Variable,"[\s]")		; Check if contains spaces
	noNumVar:=RegExReplace(Variable,"[^0-9.]+")		; Remove all non numerics or .
	ControlGet,inPos, CurrentCol,,, ahk_id %ControlID%		; Get input position of the edit box.
	StringSplit,splitNum,noNumVar,.				; Allow only one ".", the leftmost is preserved.
	if (splitNum0>2)							; This can be higher than three if user pastes in something with more than one dot.
	{
		noNumVar:=splitNum1 . "."
		Loop, % splitNum0-1
		{
			ind:=A_Index+1
			noNumVar.=splitNum%ind%	 
		}	
	}
	if (Variable==noNumVar && !containsSpaces) 		; If nothing changed and no spaces present, return
		return
	GuiControl,,%ControlID%,%noNumVar%		; Set text
	PostMessage,0x00B1,inPos-2,inPos-2,,ahk_id %ControlID% 	; Move input caret to correct position, EM_SETSEL:=0x00B1
}

CheckFTypeList(String)
{
  If (String="")
    Return 0
  Else
  {
    OutVar:=RegExMatch(String, "i)^\w+(,\w+)*$")
    If (OutVar="")
      Return 0
    Else
      Return OutVar
  }
}

SetDenoiseLevelRange(OutModel){
    NoiseLevelMin:=""
    NoiseLevelMax:=""
    Loop, Files, %A_ScriptDir%\models\%OutModel%\noise?_model.*
    {
      RegExMatch(A_LoopFileName, "\d(?=_model\.)", NoiseLevelNum)
      If (NoiseLevelNum<>"")
      {
        If (NoiseLevelMin="" or NoiseLevelNum<NoiseLevelMin)
          NoiseLevelMin:=NoiseLevelNum
        If (NoiseLevelMax="" or NoiseLevelNum>NoiseLevelMax)
          NoiseLevelMax:=NoiseLevelNum
      }
    }
    GuiControl, Main:+Range%NoiseLevelMin%-%NoiseLevelMax%, DenoiseLevel
    GuiControlGet, CurDenoiseLevel, , DenoiseLevel
    If (CurDenoiseLevel<>"")
      GuiControl, Main:Text, CurDenoiseLevel, %CurDenoiseLevel%
}

ScaleRatioFormat(InVar)
{
  Global HScaleRatio
  Global ScaleRatio
  ;GuiControlGet, InVar,, %HScaleRatio%
  InVar:=InVar+0
  If (InVar<1)
    InVar:="2"
  GuiControl, Main:Text, ScaleRatio, %InVar%
  ScaleRatio:=InVar
}

AppendText(hEdit, ptrText) {
    SendMessage, 0x000E, 0, 0,, ahk_id %hEdit% ;WM_GETTEXTLENGTH
    SendMessage, 0x00B1, ErrorLevel, ErrorLevel,, ahk_id %hEdit% ;EM_SETSEL
    SendMessage, 0x00C2, False, ptrText,, ahk_id %hEdit% ;EM_REPLACESEL
}

ComboBoxGetHEDIT(HCBB) {
   ; http://msdn.microsoft.com/en-us/library/bb775939(v=vs.85).aspx
   Static SizeOfCBI := (4 * 10) + (A_PtrSize * 3)
   Static OffHEDIT := (4 * 10) + A_PtrSize
   VarSetCapacity(CBI, SizeOfCBI, 0)
   NumPut(SizeOfCBI, CBI, 0, "UInt")
   If DllCall("User32.dll\GetComboBoxInfo", "Ptr", HCBB, "Ptr", &CBI, "UInt")
      Return NumGet(CBI, OffHEDIT, "UPtr")
   Return False
}