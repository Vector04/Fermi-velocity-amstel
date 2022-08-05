#pragma TextEncoding	= "UTF-8"
#pragma rtGlobals 		= 3
#pragma IgorVersion		= 6.36
#pragma ModuleName		= SpectraGraphTools
#pragma version			= 1.70
#pragma DefaultTab		= {3,20,4}		// set default tab width in Igor Pro 9 and later

static Constant kVersion = 1.70
static StrConstant kVersionDate = "04/2022"

// --------------------- Project Updater header ----------------------
// If you're using Igor Pro 8 or later and have Project Updater
// installed, this package can check periodically for new releases.
// https://www.wavemetrics.com/project/Updater
static Constant kProjectID = 21562																// the project node on IgorExchange
static StrConstant ksShortTitle = "Spectra Graph Tools"											// the project short title on IgorExchange

//________________________________________________________________________________________________
//	Written by Stephan Thuermer - https://www.wavemetrics.com/user/chozo
//	Original code & idea for the right-click graph menus by Tony Withers - https://www.wavemetrics.com/user/tony
//
//	This is a collection of functions for modifying traces and graphs.
//	Contents:
//		- Basic Graph Style and Label Macros
//		- Quick Normalization :		Normalize to unit area or height / scale the traces in a graph
//		- SpectraWaterfall :		Generates a waterfall plot out of 2D data or a folder
//		- BuildTraceOffsetPanel :	A small panel to offset and color traces
//		- BuildGraphSizePanel :		A small panel to set the graph size and margins
//
// 2021-03-01 - ver. 1.00:	Initial public release.
// 2021-03-07 - ver. 1.10:	Quick normalization did not work properly when the data included NaNs.
//							Graph Size panel: Axes margins did not copy correctly from one graph to the other.
//							The Graph Size panel threw an error on Mac because of a wrong ModifyControl command.
//							Trace Offset panel: Added keyboard shortcuts for selecting and moving the cursor.
//							Trace Offset panel: It is now possible to move and scale selected traces with the cursor keys.
// 2021-03-11 - ver. 1.11:	A cursor set on an image triggered an error message for the TraceOffset panel.
// 2021-03-16 - ver. 1.20:	Added global constant for the multiplier step and made keyboard control more precise.
//							Added Offset Traces functionality to the graph and traces right-click menus.
// 2021-03-17 - ver. 1.21:	Now it is possible to choose whether offsets are set or added.
//							Fixed bug: Closing a graph did not properly update active window.
//							Now the total shift is also displayed for single traces.
// 2021-03-28 - ver. 1.30:	Graph Size panel: The last selected size unit setting is now saved in the current experiment.
//							Trace offset panel: Fixed a few error messages triggered by very old versions of the panel.
//							Trace offset panel: Trace scaling increment steps now get smaller and bigger depending on the
//							order of magnitude of the current scaling (helps to work with very big or small scaling factors).
//							Trace offset panel: Added a button to quickly set a new cursor onto the graph.
//							The currently selected trace name is now displayed in the panel title.
// 2021-05-14 - ver. 1.40:	Slightly adjusted the axis-label graph macros.
//							Graph size panel: Now switching the axes keeps the axis label visible.
//							Offset menu: Works now for 1-column 2D waves as well.
//							Graph Size panel: Hold shift while changing the font size to change the global axes font instead.
//							Graph Size panel: Added print checkbox to enable print-to-history function for most controls.
// 2021-08-14 - ver. 1.50:	Fixed bug: Commands got printed anyway when an old panel without the print checkbox was used.
//							Graph Size panel: Overhaul of the panel controls.
//							Graph Size panel: Added tick label margin controls.
//							Trace offset panel: Moved controls into tabs for better organization.
//							Trace offset panel: The Prev and Next cursor placement controls honor trace offsets now.
//							Trace offset panel: New cursors get set in the center of the current bottom-axis range.
// 2021-12-01 - ver. 1.60:	Added support for sub-graphs (also in layouts and panels) in all tools.
//							Trace offset panel: Fixed bug - cursors on shared image plots were not caught properly and led to errors.
//							Graph Size panel: Doubled the increment for size changes for faster adjustments.
//							Graph Size panel: Added controls for label margin.
//							Graph Size panel: Tick and label margins will be copied & pasted between graphs as well.
// 2022-03-23 - ver. 1.65:	Normalize to cursor now honors x-offsets of traces.
//							Added support for keyboard-shortcut (and other future) settings via external text file.
//							Added quick-scale tool to modify data directly from a graph.
//							Trace tool now shows color of currently selected trace.
// 2022-04-05 - ver. 1.70:	New right-click shortcut to add legend with live trace offset information.
//							Moved all graph related menu entries into Offset Spectra sub-menu.
//							Fixed bug: Quick-Scale panel did not react when trace together with cursor was removed.
//							Made the Quick-Scale panel x-wave aware.
//________________________________________________________________________________________________

static Constant kOffsetIncrStep = 0.005															// fraction of the total range to increase / decrease values each step
static Constant kMultiIncrStep  = 0.1															// by how much the multiplier is incremented (keyboard presses are 1/5 of this value)
static StrConstant ksTraceIgnoreList	= "w_base;MQP_*;"										// list of traces to ignore, wildcards okay
static StrConstant ksGraphSizeUnitSave	= "V_SizePanelUnit"										// global variable name which saves the current unit setting of the Graph Size Panel
static StrConstant kSettingsFileName	= "Spectra Tools settings.dat"							// just for keyboard shortcuts for now.

//-------------------------------- functions for user code ---------------------------------------
static Function TraceTool_FetchXShift(input, unit)												// extract predetermined X offset shift values from data
	Wave input
	String &unit																				// optional unit string
	Variable xShift = NaN																		// the shift value which will be preset in the panel
	// ++++++++++++++++++++++ get the photon energy as shift value +++++++++++++++++++++++++++++++
	Variable neg = 1
	String notes = note(input)
	String energy = StringByKey("Xray energy", notes, "=","\r")									// find the photon energy
	if (!strlen(energy))
		energy = StringByKey("photon energy ", notes, "=","\r")									// try a different key
	endif
	if (!strlen(energy))
		energy = StringByKey("Excitation Energy", notes, "=","\r")								// try yet a different key
		neg = -1																				// this data requires flipping
	endif
	unit = "eV"
	xShift = str2num(energy)*neg
	if (xShift == 0)
		xShift = NaN
	endif
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	return xShift 																				// return NaN for no change and return negative values for flipping the trace
End

static Function TraceTool_FetchYShift(input,unit)												// extract predetermined Y offset shift values
	Wave input
	String &unit
	return NaN	 																				// return NaN for no change and return negative values for flipping the trace
End
//------------------------------------------------------------------------------------------------

Menu "Spectra Tools"
	"-"
	SpectraGraphTools#MenuEntry("norm_to1"),	/Q, ScaleTo1()
	SpectraGraphTools#MenuEntry("norm_toCur"),	/Q, ScaleTo1AtCsr("A")
	SpectraGraphTools#MenuEntry("norm_toArea"),	/Q, ScaleTo1(toarea=1)
	"-"
	SpectraGraphTools#MenuEntry("waterfall"),	/Q, CreateBrowser; SpectraWaterfall()
	SpectraGraphTools#MenuEntry("quick_color"),	/Q, QuickColorAllTraces()
	SpectraGraphTools#MenuEntry("graph_GUI"),	/Q, BuildGraphSizePanel()
	SpectraGraphTools#MenuEntry("trace_GUI"),	/Q, BuildTraceOffsetPanel()
	SpectraGraphTools#MenuEntry("quick_scale"),	/Q, AttachQuickScalePanel()
End

Menu "GraphPopup"
	"-"
	"Add Annotation with Live Offset ...", /Q, SpectraGraphTools#QuickOffsetLegendWrapper()
	Submenu "Offset Spectra"
		"Spread Traces Across y Range",	/Q, SpectraGraphTools#SpreadToFillRange()
		"Spread Traces: Equal Offset", 	/Q, SpectraGraphTools#SpreadSpectra(0)
		"Spread Traces: Equal Gap", 	/Q, SpectraGraphTools#SpreadSpectra(1)
		"-"
		"Left Axis: Autoscale Only Visible", /Q, SetAxis/A=2/E=0 left
		"Left Axis: Autoscale From Zero",	 /Q, SetAxis/A=2/E=1 left
		"Traces: Undo All Scaling",		/Q, ModifyGraph muloffset={0,0}
		"Traces: Undo All Offsets",		/Q, ModifyGraph offset={0,0}
	End
End

Menu "TracePopup", dynamic
	"-"
	"Add Annotation with Live Offset ...", /Q, SpectraGraphTools#QuickOffsetLegendWrapper()
	Submenu "Offset Spectra"
		SpectraGraphTools#SaveMenuPosition("y-Offset: Align Traces Here"),/Q, SpectraGraphTools#AlignTracesAtXPos(0)// holding ctrl / command aligns to zero
		SpectraGraphTools#SaveMenuPosition("y-Scale: Match Traces Here"),/Q, SpectraGraphTools#AlignTracesAtXPos(1)	// holding ctrl / command scales to one
		SpectraGraphTools#SaveMenuPosition("y-Order Traces Here"),/Q, SpectraGraphTools#OrderTracesAtXPos()			// holding ctrl / command sorts in descending order
		"-"
		"Spread Traces Across y Range", /Q, SpectraGraphTools#SpreadToFillRange()
		"Spread Traces: Equal Offset", 	/Q, SpectraGraphTools#SpreadSpectra(0)
		"Spread Traces: Equal Gap", 	/Q, SpectraGraphTools#SpreadSpectra(1)
		"-"
		"Left Axis: Autoscale Only Visible", /Q, SetAxis/A=2/E=0 left
		"Left Axis: Autoscale From Zero",	 /Q, SetAxis/A=2/E=1 left
		"Traces: Undo All Scaling",		/Q, ModifyGraph muloffset={0,0}
		"Traces: Undo All Offsets",		/Q, ModifyGraph offset={0,0}
	End
End

//################################################################################################

static Function/S MenuEntry(which)
	String which
	Variable fileID

	String read = "", menuStr = "", searchStr = ""
	StrSwitch (which)
		case "norm_to1":
			menuStr = "Normalize Traces to 1"
			searchStr = "normalize traces to one"
		break
		case "norm_toCur":
			menuStr = "Normalize Traces to 1 at Cursor A"
			searchStr = "normalize traces to cursor"
		break
		case "norm_toArea":
			menuStr = "Normalize Traces to Area"
			searchStr = "normalize traces to area"
		break
		case "waterfall":
			menuStr = "Waterfall Plot of 2D Data or Folder"
			searchStr = "create waterfall plot"
		break
		case "quick_color":
			menuStr = "Quick Colorize Traces"
			searchStr = "quick colorize traces"
		break
		case "graph_GUI":
			menuStr = "Graph Size Panel ..."
			searchStr = "start graph size panel"
		break
		case "trace_GUI":
			menuStr = "Trace Offset Panel ..."
			searchStr = "start trace offset panel"
		break
		case "quick_scale":
			menuStr = "Attach Quick-Scale Panel ..."
			searchStr = "start quick-scale panel"
		break
		default:
			return ""
	EndSwitch
	
	Open/Z/R fileID as ParseFilePath(1, FunctionPath(""), ":", 1, 0)+kSettingsFileName
	if (!V_flag)
		do
			FReadLine fileID, read
		while (strlen(read) > 0 && !StringMatch(read, searchStr+"*"))
		read = ReplaceString("\t", ReplaceString(" ", read, ""), "")
		read = StringByKey(ReplaceString(" ", searchStr, ""),read,"=","\r")
		Close fileID
	endif
	return menuStr+SelectString(strlen(read),"","/"+read)
End

//________________________________________________________________________________________________
//
//										Standard Graph Macros
//________________________________________________________________________________________________

Proc BoxStyle() : GraphStyle
	PauseUpdate; Silent 1
	GetAxis/Q right
	if (V_flag == 1)
		ModifyGraph/Z mirror(left)=2
	endif
	GetAxis/Q top
	if (V_flag == 1)
		ModifyGraph/Z mirror(bottom)=2
	endif
	ModifyGraph noLabel=0
	ModifyGraph standoff=0
	ModifyGraph ZisZ=1
	ModifyGraph tick=0
	ModifyGraph notation(left)=1
	ModifyGraph axisOnTop=1
	ModifyGraph minor=1
	if ((GetKeyState(0) & 2^0) != 0)															// ctrl / command = paper style (no left axis notation)
		ModifyGraph tick(left)=3
		ModifyGraph noLabel(left)=1
	endif
	ResumeUpdate
EndMacro

Proc XAS_Label() : GraphStyle
	Label/Z left "\u#2Intensity [arb. u.] \\E"
	Label/Z bottom "Photon energy [\U]"
EndMacro

Proc XES_Label() : GraphStyle
	Label/Z left "\u#2Intensity [arb. u.] \\E"
	Label/Z bottom "Emission energy [\U]"
EndMacro

Proc TOF_Label() : GraphStyle
	Label/Z left "\u#2Intensity [arb. u.] \\E"
	Label/Z bottom "Flight time [\U]"
EndMacro

Proc PKE_Label() : GraphStyle
	Label/Z left "\u#2Intensity [arb. u.] \\E"
	Label/Z bottom "\u#2"+SelectString((GetKeyState(0) & 2^0) != 0, "Kinetic", "Binding")+" energy [eV]"	// BE label with ctrl / command
EndMacro

//________________________________________________________________________________________________
//	Change the Color of up to 13 Traces with Preset Colors - Sorted to give good contrast for even a few traces
//________________________________________________________________________________________________

Function QuickColorAllTraces()																	// colors traces with 12 different colors (hard-coded)
	String traces, gName = getTopGraph()
	Variable trNum = FetchTraces(gName,traces,1)
	if (trNum == 0)
		return 0
	endif
	Make/FREE colors = {{65280,0,0}, {65280,43520,0}, {0,65280,0}, {0,52224,0}, {0,26214,1329}, {0,65280,65280}, {0,43520,65280}, {0,15872,65280}, {44253,29492,58982}, {65535,16385,55749}, {26411,1,52428}, {26112,26112,26112}, {0,0,0}}
	Variable trI, cI, cCount = DimSize(colors,1)
	Variable leap = trNum < cCount/2 ? trunc((cCount-1)/(trNum-1)) : 1							// introduce a leap value to choose more distant colors for only a few traces
	for (trI = 0, cI = 0; trI < trNum; trI += 1, cI += leap)
		cI = cI == cCount ? 0 : cI																// loop colors around
		ModifyGraph/W=$gName rgb($StringFromList(trI,traces))=(colors[0][cI],colors[1][cI],colors[2][cI])	// set new color offset
	endfor
End

//________________________________________________________________________________________________
//
//						Add Legend with Trace Offset and Scaling Infos
//________________________________________________________________________________________________

static Function InsertIntoMainProc(newCode)
	String newCode
	String currScrap = GetScrapText()															// copy current scrap text
	GetWindow Procedure hide
	Variable wasHidden = V_Value != 0 
	DisplayProcedure/W=Procedure
	DoIgorMenu "Edit" "Select All"
	DoIgorMenu "Edit" "Copy"
	PutScrapText GetScrapText()+newCode															// modify procedure code
	DoIgorMenu "Edit" "Paste"
	PutScrapText currScrap			 															// put previous scrap text back
	Execute/P/Q/Z "COMPILEPROCEDURES "															// recompile all
	if (wasHidden)
		HideProcedures																			// hide all procedure windows
	endif
End
//------------------------------------------------------------------------------------------------
static Function/S OffsetFuncCode()																// inserts function for a live display of trace offset
	String newCode = "\r\rFunction/S GT_liveOff(gName, trace, which)\r"
	newCode += "\tString gName, trace;\tVariable which\r"
	newCode += "\tif (which < 0 || which > 3)\t\t// which modes: [0] = x offset, [1] = y offset, [2] = x multiplier, [3] = y multiplier\r"
	newCode += "\t\treturn \"\"\r\tendif\r\tNVAR/Z digits = root:GT_liveOffRoundValues\r\tVariable mode = which > 1, xval, yval, roundTo = NVAR_Exists(digits) ? digits : 5\r"
	newCode += "\tsscanf StringByKey(SelectString(mode,\"offset(x)\",\"muloffset(x)\"), TraceInfo(gName,trace,0), \"=\"), \"{%f,%f}\", xval, yval\r"
	newCode += "\tString result;\tsprintf result, \"%.*g\", roundTo, (which-2*mode ? yval+(yval==0) : xval)\r\treturn result\rEnd"
	return newCode
End

//################################################################################################

Function QuickOffsetLegendWrapper()
	Variable mode = 1, add = 1, pos = 1, rnd = 6
	String hlpStr = "This tool adds a function GT_liveOff(graphName, traceName, mode) to the current experiment to display live offset information of traces."
	Prompt mode,"1st Information:",popup,"x Offsets;y Offsets;x Multiplier;y Multiplier;"
	Prompt add,"2nd Information:",popup,"None;x Offsets;y Offsets;x Multiplier;y Multiplier;"
	Prompt pos,"Legend Position:",popup,"Default;LB: left bottom;MB: mid bottom;RB: right bottom;LC: left center;MC: mid center;RC: right center;LT: left top;MT: mid top;RT: right top;"
	Prompt rnd,"No. of Significant Digits (Rounding):",popup,"0;1;2;3;4;5;6;7;8;9;10;"
	DoPrompt/HELP=hlpStr "Which information should be displayed in the legend of "+getTopMainGraph()+"?",mode, add, rnd, pos
	if (!V_Flag)
		QuickOffsetLegend(mode-1, addinfo = add-2, anchor = pos-1, digits = rnd-1)	
	endif
	return 0
End
//------------------------------------------------------------------------------------------------
Function QuickOffsetLegend(which, [addinfo, anchor, digits])									// which modes: [0] = x offset, [1] = y offset, [2] = x multiplier, [3] = y multiplier
	Variable which, addinfo, anchor, digits
	String gName = getTopMainGraph()
	if (!strlen(gName))
		return -1
	endif
	
	Variable anchorCode	= ParamIsDefault(anchor) || anchor < 0 || anchor > 9 ? 7 : anchor		// default is LT anchor
	Variable addWhich	= ParamIsDefault(addinfo) || addinfo < -1 || addinfo > 3 ? -1 : addinfo	// default is no info
	Variable roundTo	= ParamIsDefault(digits) || digits < 0 || digits > 16 ? 5 : digits		// default is 5 significant digits
	
	if (!strlen(FunctionInfo("GT_liveOff","Procedure")))										// first inject offset macro into experiment
		InsertIntoMainProc(OffsetFuncCode())
	endif
	
	Variable/G root:GT_liveOffRoundValues = roundTo
	String traces = TraceNameList(gName,";",1), legendText = ""
	String modeList = SelectString(IgorVersion()<7,"Δx = ;Δy = ;x *;y *;", "dx = ;dy = ;x *;y *;")
	String anchorID = StringFromList(anchorCode, "none;LB;MB;RB;LC;MC;RC;LT;MT;RT;")
	
	Variable i
	for (i = 0; i < ItemsInList(traces); i += 1)
		String currTrace = StringFromList(i, traces)
		String cleanName = ReplaceString("'", currTrace, "")
		cleanName = ReplaceString("_prH", cleanName, "")										// cleanup endings from image profiles
		cleanName = ReplaceString("_prV", cleanName, "")
		cleanName = ReplaceString("_prL", cleanName, "")
		legendText += "\\s(" + currTrace + ") " + cleanName + " ("+StringFromList(which, modelist)+"\\{GT_liveOff(\""+gName+"\",\""+currTrace+"\", "+num2str(which)+")}"
		if (addWhich > -1)
			legendText += ", " + StringFromList(addWhich, modelist)+"\\{GT_liveOff(\""+gName+"\",\""+currTrace+"\", "+num2str(addWhich)+")}"
		endif
		legendText += ")\r"
	endfor
	
	if (CmpStr (anchorID, "none") == 0)
		Legend/W=$gName/C/N=TraceOffsets/J/F=0/B=1 legendText
	else
		Legend/W=$gName/A=$anchorID/C/N=TraceOffsets/J/F=0/B=1 legendText
	endif
	return 0
End

//________________________________________________________________________________________________
//
//							Scaling Normalization of Graph Traces
//________________________________________________________________________________________________

Function ScaleTo1AtCsr(csrName)																	// wrapper to scale at cursors
	String csrName
	String gName = getTopGraph()
	String info = CsrInfo($csrName,gName)
	if (!strlen(info))
		Abort "Cursor "+csrName+" is not set."
	endif
	
	String trace = StringByKey("TNAME",info)
	Variable xOff = 0, yOff = 0, xScale = 0, yScale = 0
	getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)
	Variable xCsrPos = hcsr($csrName, gName)*xScale + xOff										// add trace offset to the cursor position

	ScaleTo1(xpos=xCsrPos)
	return 0
End
//------------------------------------------------------------------------------------------------
Function ScaleTo1([smth,xpos,toarea])
	Variable smth, xpos, toarea
	String gName = getTopGraph()
	String traces  = TraceNameList(gName,";",1)
	Variable items = ItemsInList(Traces)
	if (items == 0)
		return 0
	endif

	Variable xOff = 0, yOff = 0, xScale = 0, yScale = 0
	Variable i, shiftBaseline = !(GetKeyState(0) == 4)											// don't shift background if shift is pressed
	for (i = 0; i < items; i += 1)
		String currTr = StringFromList(i,traces)
		Wave inwave	= TraceNameToWaveRef(gName, currTr)
		if (DimSize(inwave,1) < 2 && WaveDims(inwave) < 3)										// 1D or pseudo-1D data
			Duplicate/FREE inwave work
		elseif (WaveDims(inwave) == 2)															// traces of 2D data
			String range = StringByKey("YRANGE", TraceInfo(gName,currTr,0))						// find the displayed column from TraceInfo
			Variable col = strsearch(range,"[",Inf,1)
			range = range[col+1,inf]
			col = str2num(RemoveEnding(range,"]"))
			if (numtype(col) == 0)
				Duplicate/R=[][col]/FREE inwave work
			else
				continue
			endif
		else
			return -1
		endif
		MatrixOP/O work = replaceNaNs(work,0)
		
		if( !ParamIsDefault(smth) && smth > 0)													// optional smoothing before scaling
			Smooth smth, work
		endif
		
		Variable minval	= wavemin(work)*shiftBaseline
		Variable maxval	= wavemax(work)
		if (!ParamIsDefault(xpos) && numtype(xpos) == 0)
			getAllTraceOffsets(gName, currTr, xOff, yOff, xScale, yScale)						// adjust for each trace's offsets
			Variable pntpos = x2pnt(work, (xpos - xOff)/xScale)
			if (pntpos > 0 && pntpos < DimSize(work,0)-1)										// make sure to stay within range
				maxval = work[pntpos]
			endif
		endif
		Variable scale = maxval-minval
		if (!ParamIsDefault(toarea) && toarea == 1)												// scale to area instead
			scale  = area(work)
			minval = 0
		endif
		scale = scale == 0 ? 1 : scale
		ModifyGraph/W=$gName offset($currTr)={,-minval/scale},muloffset($currTr)={,1/scale}
	endfor
	return 0
End

//________________________________________________________________________________________________
//
//					Creates Waterfall Plot from a 2D Wave or a Folder of Waves
//________________________________________________________________________________________________

Function SpectraWaterfall()
	Wave/Z inwave = $GetBrowserSelection(0)														// get the first selected wave
	if (!WaveExists(inwave))
		Print "Nothing selected"
		return -1
	endif
	DFREF saveDFR = GetDataFolderDFR()
	
	String list	= ""
	Variable OneD = WaveDims(inwave) == 1														// first check, if the incoming wave is 1D or 2D
	if (OneD)
		SetDataFolder GetWavesDataFolderDFR(inwave)
		list = WaveList("!Int_*", ";", "DIMS:1")
		list = SortList(list, ";", 16)
	endif
	
	String wTitle = SelectString(OneD,NameOfWave(inwave),GetWavesDataFolder(inwave,0))			// name of 2D wave or folder
	Display/W=(230,50,650,450)/K=1/N=$UniqueName("WaterfallGraph", 6, 0) as "Waterfall of "+wTitle
	Variable i, items = OneD ? ItemsInList(list) : DimSize(inwave,1)
	for (i = items-1; i > -1; i -=1)															// go backwards (in reverse order, so that the later traces are BEHIND the earlier ones)
		if (OneD)
			AppendToGraph/Q $Stringfromlist(i,list)
		else
			AppendToGraph/Q inwave[][i]
		endif
	endfor
	SetDataFolder saveDFR
	
	Execute/Q "BoxStyle()"
	ColorSpectrumFromTable(0, "Rainbow")
	
	list = TraceNameList("",";",1)
	Variable initOffset	= WaveMax(inwave) * 0.05												// the initial distance will be set in percent from the maximal value of the selected wave
	for (i = 1; i < items; i += 1)
		ModifyGraph offset($StringFromList(items-1 - i,list))={,i*initOffset}
	endfor
	return 0
End

//________________________________________________________________________________________________
//
//							Right-Click Offset Menus for Graph Traces
//				Adapted from the StackTraces procedures v1.20 by Tony Withers
//________________________________________________________________________________________________

static Function/S SaveMenuPosition(s_menu)														// use to create a menu item in a popup when you need to know where the user clicks to invoke the popup
	String s_menu
	if (WinType("") != 1)																		// don't create variables if Igor is just rebuilding the menu
		return ""
	endif
	GetMouse/W=kwTopWin
	if (V_left<0 || V_top<0)
		return ""
	endif
	if(IgorVersion() < 8.00)																	// compatibility with earlier Igor versions: save mouse position as global variable
		Variable/G V_menuX = V_left, V_menuY = V_top
	endif
	return s_menu
End

//################################################################################################

static Function getYfromWave(gName, trace, xPos, yVal, yMin)
	String gName, trace
	Variable xPos, &yVal, &yMin
	
	Wave w = TraceNameToWaveRef(gName, trace)
	Wave/Z w_x = XWaveRefFromTrace(gName, trace)
	
	String range
	Variable col2D = 0
	if (WaveDims(w) == 2 && DimSize(w,1) > 1)													// handle 2D waterfall plots => extract column
		range = StringByKey("YRANGE", TraceInfo(gName,trace,0))									// extract the last number out of something like "[*][15]" or "[3,50][15]"
		col2D = strsearch(range,"[",Inf,1)
		range = range[col2D+1,inf]
		col2D = str2num(RemoveEnding(range,"]"))
		if (numtype(col2D) == 0)
			Duplicate/R=[][col2D]/FREE w work
			Wave w = work
		else
			return -1
		endif
	endif
	
	yMin = WaveMin(w)
	yVal = NaN
	if(WaveExists(w_x))
		FindLevel/P/Q w_x, xPos
		if (!v_flag && v_levelX > 0 && v_levelX < DimSize(w,0)-1)								// make sure to stay within range
			yVal = w[round(v_levelX)]
		else
			return -1
		endif
	else
		if (x2pnt(w, xPos) > 0 && x2pnt(w, xPos) < DimSize(w,0)-1)
			yVal = w(xPos)
		else
			return -1
		endif
	endif
	return 0
End

//################################################################################################

static Function getMinMaxfromWave(gName, trace, yMin, yMax)										// figure out plotted x-range for trace and finds wave's max and min values in this range
	String gName, trace
	Variable &yMin, &yMax 
	
	wave w = TraceNameToWaveRef(gName, trace)
	wave/Z w_x = XWaveRefFromTrace(gName, trace)
	
	String range
	Variable col2D = 0
	if (WaveDims(w) == 2 && DimSize(w,1) > 1)
		range = StringByKey("YRANGE", TraceInfo(gName,trace,0))
		col2D = strsearch(range,"[",Inf,1)
		range = range[col2D+1,inf]
		col2D = str2num(RemoveEnding(range,"]"))
		if (numtype(col2D) == 0)
			Duplicate/R=[][col2D]/FREE w work
			Wave w = work
		else
			return -1
		endif
	endif
	
	Variable xOff = 0, yOff = 0, xScale = 0, yScale = 0											// x-offset and y-scale aware
	getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)
	if (WhichListItem("bottom",AxisList(gName)) > -1)
		GetAxis/W=$gName/Q bottom
	elseif (WhichListItem("top",AxisList(gName)) > -1)
		GetAxis/W=$gName/Q top
	else
		return -1
	endif
	
	if(WaveExists(w_x))
		FindLevel /Q w_x, v_min																	// no /P flag here - assumes same x-scaling for w and w_x
		v_min = v_flag ? 0 : V_LevelX
		FindLevel /Q w_x, v_max
		v_max = v_flag ? numpnts(w) : V_LevelX
	endif
	Variable fr = (v_min - xOff)/xScale
	Variable to = (v_max - xOff)/xScale
	yMax = WaveMax(w, fr, to)*yScale
	yMin = WaveMin(w, fr, to)*yScale
	return 0
End

//################################################################################################

static Function AlignTracesAtXPos(which)														// use trace popup to y-align traces at clicked x position by setting offsets (which = 0) or multipliers (which = 1)
	Variable which
	
	GetLastUserMenuInfo																			// figure out graph and trace names
#if(IgorVersion() < 8.00)																		// compatibility with earlier Igor versions
	NVAR V_mouseX = v_menuX
	NVAR V_mouseY = v_menuY
#endif

	String gName = S_graphName, trace = S_traceName
	String s_info = TraceInfo(gName, trace, 0), traces = ""
	Variable trNum = FetchTraces(gName,traces,1)
	Variable xClick = AxisValFromPixel(gName, StringByKey("XAXIS",s_info) , V_mouseX)
	Variable yClick = AxisValFromPixel(gName, StringByKey("YAXIS",s_info) , V_mouseY)
	
	Variable normVal = (GetKeyState(0) & 2^0)													// holding ctrl / command aligns to zero or scales to one
	yClick = normVal && which == 0 ? 0 : yClick													// shift to zero?
	
	Variable i, err, modVal
	for(i = 0; i < trNum; i += 1)
		trace = StringFromList(i,traces)
		Variable xOff = 0, yOff = 0, xScale = 0, yScale = 0, ywVal, ywMin
		getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)
		err = getYfromWave(gName, trace, (xClick-xOff)/xScale, ywVal, ywMin)					// extract wave min and Y value at X position
		if (err)
			continue
		endif
		if (which)
			modVal = normVal ? 1/(ywVal-ywMin) : (yClick-yOff/yScale-ywMin)/(ywVal-ywMin)		// scale to one?
			ModifyGraph/W=$gName muloffset($trace)={,modVal}									// scale to match position
			if (normVal && which)																// if normalized scale offsets down as well (because the scale difference can be huge)
				ModifyGraph/W=$gName offset($trace)={,-ywMin*modVal}
			endif
		else
			modVal = yClick-ywVal*yScale
			ModifyGraph/W=$gName offset($trace)={,modVal}										// shift to align position
		endif
	endfor
	return 0
End

//################################################################################################

static Function OrderTracesAtXPos()																// reorder traces based on (possibly offset) value at x=xpos
	GetLastUserMenuInfo																			// figure out graph and trace names
#if(IgorVersion() < 8.00)																		// compatibility with earlier Igor versions
	NVAR V_mouseX = v_menuX
#endif

	String gName = S_graphName, trace = S_traceName
	String s_info = TraceInfo(gName, trace, 0), traces = ""
	Variable trNum = FetchTraces(gName, traces, 1)
	Variable xClick = AxisValFromPixel(gName, StringByKey("XAXIS",s_info) , V_mouseX)
	
	Make/Free/T/N=(trNum) w_traces
	Make/Free/N=(trNum) w_order
	
	Variable i, err
	for(i = 0 ; i < trNum; i += 1)
		trace = StringFromList(i,traces)
		Variable xOff = 0, yOff = 0, xScale = 0, yScale = 0, ywVal, ywMin
		getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)
		err = getYfromWave(gName, trace, (xClick-xOff)/xScale, ywVal, ywMin)					// extract wave min and Y value at X position
		w_traces[i] = trace
		w_order[i] = err ? yOff : yOff+ywVal*yScale
	endfor
	
	if (GetKeyState(0) & 2^0)																	// holding ctrl / command triggers descending order sorting
		Sort/R w_order, w_order, w_traces
	else
		Sort w_order, w_order, w_traces
	endif
	
	for(i = 0; i < numpnts(w_traces); i += 1)
	#if(IgorVersion() > 7.00)
		ReorderTraces/W=$gName _front_, {$w_traces[i]}
	#endif
	endfor
	return 0
End

//################################################################################################

static Function SpreadToFillRange()																// spread (equally offset) spectra over Y axis range; traces are stacked in the order of plotting
	String traces = "", gName = getTopGraph()
	Variable trNum = FetchTraces(gName,traces,1)
	Make/Free/N=(trNum)/T w_traces = StringFromList(p,traces)
	Make/Free/N=(trNum) w_offsets = getTraceOffset(gName, w_traces[p], 1)

	Variable yMin, yMax, low, high
	getMinMaxfromWave(gName, w_traces[0], yMin, yMax);		 low  = yMin + w_offsets[0]			// find low from first trace
	getMinMaxfromWave(gName, w_traces[trNum-1], yMin, yMax); high = yMax + w_offsets[trNum-1]	// find high from last trace
	
	if (WhichListItem("left",AxisList(gName)) > -1)
		GetAxis/W=$gName/Q left
	elseif (WhichListItem("right",AxisList(gName)) > -1)
		GetAxis/W=$gName/Q right
	else
		return -1
	endif
	
	Variable bottomGap = low-v_Min, topGap = v_Max-high
	Variable i, dOffset = (topGap+bottomGap)/(trNum-1)
	for (i = 0; i < trNum; i += 1)																// apply offsets
		ModifyGraph/W=$gName offset($w_traces[i])={,w_offsets[i]- bottomGap + dOffset*i}
	endfor
	return 0
End

//################################################################################################

static Function SpreadSpectra(which)
	Variable which																				// which: 0 = equal offset increment, 1 = equal spacing
	
	String traces = "", gName = getTopGraph()
	Variable trNum = FetchTraces(gName,traces,1)
	Make/Free/N=(trNum)/T w_traces = StringFromList(p,traces)
	Make/Free/N=(trNum)/Wave w_waves = TraceNameToWaveRef(gName,w_traces)
	Make/Free/N=(trNum) w_low, w_high, w_range	
	
	Variable i, yMin, yMax
	for (i = 0; i < trNum; i += 1)
		getMinMaxfromWave(gName, w_traces[i], yMin, yMax);  w_low[i] = yMin;  w_high[i] = yMax;
	endfor
	w_range = w_high-w_low
	
	if (WhichListItem("left",AxisList(gName)) > -1)
		GetAxis/W=$gName/Q left
	elseif (WhichListItem("right",AxisList(gName)) > -1)
		GetAxis/W=$gName/Q right
	else
		return -1
	endif
	
	Variable yAxMin = v_min, yAxRange = (v_max-v_min), dRange = sum(w_range)
	Variable gap = which ? (yAxRange-dRange)/(trNum-1) : (yAxRange-w_range[trNum-1])/(trNum-1)	// gap or offset between each trace (defined as distance between highest value of spectrum n and lowest value of spectrum n+1)
	Variable newOff
	for (i = 0; i < trNum; i += 1)
		if (i == 0)
			newOff = yAxMin - w_low[0]															// add this to bring first trace down to bottom
		else
			newOff = which ? w_high[i-1] - w_low[i] + gap : w_low[i-1] - w_low[i] + gap
		endif
		ModifyGraph/W=$gName offset($w_traces[i])={,newOff}
		w_high[i] += newOff
		w_low[i]  += newOff
	endfor
	return 0
End

//################################################################################################

static Function/S getTopMainGraph()
	return StringFromList(0,WinList("*", ";", "WIN:1"))
End

static Function/S getTopGraph()
	String windows = WinList("*", ";", "")
	String topwindow = StringFromList(0, windows)
	Variable i = 1
	do																							// try finding a valid graph, even if it is not the top one
		Variable wtype = WinType(topwindow)
		if (wtype == 1 || wtype == 3 || wtype == 7)												// top window is graph or a type that can contain a graph
			GetWindow $topwindow, activeSW														// for the active sub window (this can also be the top-level, if there are not children, or no child is active)
			if (strlen(S_value) > 0 && WinType(S_value) == 1)
				return S_value																	// this isn't necessarily an immediate child of top window
			elseif (wtype == 1)
				return topwindow
			endif
		endif
		topwindow = StringFromList(i, windows)
		i += 1
	while (strlen(topWindow) > 0)
	return ""																					// no graph found
End

//________________________________________________________________________________________________
//
//										TRACE OFFSET PANEL
//________________________________________________________________________________________________

Function BuildTraceOffsetPanel()
	if (WinType("TraceOffsetPanel"))
		DoWindow/F TraceOffsetPanel
		return 0
	endif
	NewPanel/K=1/W=(450,60,675,505)/N=TraceOffsetPanel as "Modify Traces"
	ModifyPanel/W=TraceOffsetPanel ,fixedSize=1
	SetWindow TraceOffsetPanel hook(UpdateHook)=OffsetPanelUpdateFunc
	SetWindow TraceOffsetPanel userdata(procVersion)=num2str(kVersion)							// save procedure version

	TabControl offsetTabs ,pos={5,5} ,size={216,408} ,tabLabel(0)="All Traces" ,tabLabel(1)="Individual Trace" ,proc=TraceTool_TabControl
#if IgorVersion() >= 7.00
	TabControl offsetTabs focusring=0
#endif
	
	DefineGuide TabL={FL,5}
	DefineGuide TabR={FR,-5}
	DefineGuide TabT={FT,30}
	DefineGuide TabB={FB,-5}
	// +++++++++++++++++++++++++++++++++++ multi traces tab ++++++++++++++++++++++++++++++++++++++
	String pMulti = "TraceOffsetPanel#MultiTab"
	NewPanel/FG=(TabL, TabT, TabR, TabB)/HOST=#/N=MultiTab
	ModifyPanel frameStyle=0, frameInset=0
#if IgorVersion() >= 7.00
	ModifyPanel cbRGB=(60000,60000,60000,0)
#endif
	
	SetDrawLayer UserBack
	DrawLine 12,280,205,280
	DrawLine 12,345,205,345
	
	TitleBox MultiTargetTitle	,pos={10,3}		,size={195,18}	,title=""	,fixedSize=1		,frame=0
	
	CheckBox cHiddenTraces		,pos={13,25}	,size={60,22}	,title="Include Hidden Traces"	,value = 1		,help={"Include hidden traces when scaling."}
	SetVariable vaSetYOffset	,pos={13,70}	,size={90,16}	,title="y:"
	SetVariable vaScaleYOffset	,pos={13,110}	,size={90,16}	,title="y:"
	SetVariable vaShiftYOffset	,pos={13,150}	,size={90,16}	,title="y:"
	SetVariable vaSetXOffset	,pos={113,70}	,size={90,16}	,title="x:"
	SetVariable vaScaleXOffset	,pos={113,110}	,size={90,16}	,title="x:"
	SetVariable vaShiftXOffset	,pos={113,150}	,size={90,16}	,title="x:"
	
	CheckBox ChooseSet			,pos={13,50}	,size={60,22}	,title="Set or "				,value=1		,help={"Sets and overrides offsets of traces."}
	CheckBox ChooseAdd			,pos={67,50}	,size={60,22}	,title="Add"					,value=0		,help={"Adds to the current trace offsets."}
	TitleBox SetTitle			,pos={110,50}	,size={160,13}	,title="Offset per Trace"
	TitleBox ScaleTitle			,pos={13,93}	,size={160,13}	,title="Scale Offset per Trace"
	TitleBox ShiftTitle			,pos={13,133}	,size={160,13}	,title="Shift Offset of All Traces"
	Button ResetYButton			,pos={13,175}	,size={90,22}	,title="Y Reset"								,help={"Resets all Y offsets to 0."}
	Button ResetXButton			,pos={113,175}	,size={90,22}	,title="X Reset"								,help={"Resets all X offsets to 0."}
	Button ReverseButton		,pos={13,205}	,size={190,22}	,title="Reverse Sorting"						,help={"Reverses the order in which the traces are sorted in the graph."}
	SetVariable vTraceFilter	,pos={13,235}	,size={190,16}	,title="Filter:"								,help={"Apply offsets only to traces with matching name. You can use wildcard characters."}
	CheckBox cOmitFilter		,pos={47,257}	,size={90,22}	,title="Filter Excludes Traces"	,value = 0		,help={"The filter keyword is used to omit traces instead of including them."}

	PopupMenu ColorSelect		,pos={13,290}	,size={190,22}									,bodyWidth=190
	Button ColorButton			,pos={13,315}	,size={110,22}	,title="Colorize"								,help={"Colorize traces with currently selected color spectrum. To reverse spectrum hold 'ctrl'/'command'."}
	CheckBox cReverseColor		,pos={133,318}	,size={60,22}	,title="in Reverse"				,value = 0		,help={"Applies the color in reverse (also works directly by holding 'ctrl'/'command' while pressing the button.)"}
	PopUpMenu ProfileSelect		,pos={13,353}	,size={190,20}	,title="Profile"				,bodywidth=152
	
	Button vaApplyAllButton		,pos={5,387}	,size={205,22}	,title="Apply All to Data (overwrite!)"			,help={"Applies all offsets and scales to 1D data. Will overwrite the original waves, so use this with care!"}
	// ++++++++++++++++++++++++++++++++++++++++ settings +++++++++++++++++++++++++++++++++++++++++
	SetVariable vaSetYOffset	,value=_NUM:0	,limits={0,inf,1}					,userdata="0"
	SetVariable vaScaleYOffset	,value=_NUM:1	,limits={0,inf,kMultiIncrStep}		,userdata="1"
	SetVariable vaShiftYOffset	,value=_NUM:0	,limits={-inf,inf,1}
	SetVariable vaSetXOffset	,value=_NUM:0	,limits={-inf,inf,0.1}				,userdata="0"
	SetVariable vaScaleXOffset	,value=_NUM:1	,limits={0,inf,kMultiIncrStep}		,userdata="1"
	SetVariable vaShiftXOffset	,value=_NUM:0	,limits={-inf,inf,1}
	SetVariable vTraceFilter	,value=_STR:""
	
	PopupMenu ColorSelect		,mode=2	,value="*COLORTABLEPOPNONAMES*"							// must be mode first
	PopupMenu ProfileSelect		,mode=1	,value=TraceTool_ProfileWaveList()	,proc=TraceTool_ProfileSelect
	
	Button ReverseButton		,disable=2*(IgorVersion()<7.00)									// resorting does not work in Igor 6
	
	ModifyControlList ControlNameList(pMulti,";","Choose*")	,win=$pMulti	,proc=TraceTool_SwitchOffsetMode,mode = 1
	ModifyControlList ControlNameList(pMulti,";","*Button")	,win=$pMulti	,proc=TraceTool_ButtonFunctions
	ModifyControlList ControlNameList(pMulti,";","vaS*") 	,win=$pMulti	,proc=TraceTool_MultiTraceVars	,format="%g"
	ModifyControlList ControlNameList(pMulti,";","*Title")	,win=$pMulti	,frame=0

#if IgorVersion() >= 7.00
	ModifyControlList ControlNameList(pMulti,";","vaS*")+"ColorSelect;ProfileSelect;" ,win=$pMulti ,focusRing=0
#endif
	if (CmpStr(IgorInfo(2), "Macintosh") == 0)
		ModifyControlList ControlNameList(pMulti,";","*")	,win=$pMulti	,fsize=10
	endif
	SetActiveSubwindow ##
	
	// ++++++++++++++++++++++++++++++++++++ single trace tab +++++++++++++++++++++++++++++++++++++
	String pSingle = "TraceOffsetPanel#SingleTab"
	NewPanel/FG=(TabL, TabT, TabR, TabB)/HOST=#/N=SingleTab
	ModifyPanel frameStyle=0, frameInset=0
#if IgorVersion() >= 7.00
	ModifyPanel cbRGB=(60000,60000,60000,0)
#endif

	SetDrawLayer UserBack
	DrawLine 12,235,205,235
	DrawLine 12,317,205,317

	TitleBox SingleTargetTitle	,pos={10,3}		,size={195,18}	,title=""			,frame=0	,fixedSize=1

	Button CsrActButton			,pos={10,25}	,size={60,22}	,title="Cursor:"	,fstyle=1					,help={"Sets a new cursor on the graph."}
	CheckBox traceCsrA			,pos={78,28}	,size={60,22}	,title="A"										,help={"Selects cursor A (a key)."}
	CheckBox traceCsrB			,pos={111,28}	,size={60,22}	,title="B"										,help={"Selects cursor B (b key)."}
	CheckBox traceCsrC			,pos={144,28}	,size={60,22}	,title="C"										,help={"Selects cursor C (c key)."}
	CheckBox traceCsrD			,pos={177,28}	,size={60,22}	,title="D"										,help={"Selects cursor D (d key)."}
	
	TitleBox trSetTitle			,pos={13,53}	,size={170,13}	,title="Set Trace Offset"
	TitleBox trScaleTitle		,pos={13,93}	,size={170,13}	,title="Set Trace Multiplier"
	TitleBox trShiftTitle		,pos={13,133}	,size={170,13}	,title="Reposition at Cursor"
	SetVariable trSetYOffset	,pos={13,70}	,size={90,16}	,title="y:"
	SetVariable trScaleYOffset	,pos={13,110}	,size={90,16}	,title="y:"
	SetVariable trShiftYOffset	,pos={13,150}	,size={90,16}	,title="y:"
	SetVariable trSetXOffset	,pos={113,70}	,size={90,16}	,title="x:"
	SetVariable trScaleXOffset	,pos={113,110}	,size={90,16}	,title="x:"
	SetVariable trShiftXOffset	,pos={113,150}	,size={90,16}	,title="x:"
	SetVariable trScaleNorm		,pos={13,178}	,size={140,16}	,title="Normalize:"				,bodyWidth=80	,help={"Adjusts the multiplier to normalize the trace height to this value at the current cursor's position (excluding the Y offset)."}
	Button trNormTo1Button		,pos={163,177}	,size={40,20}	,title="to 1"									,help={"Normalizes trace height to 1 at current cursor position (excluding the Y offset)."}
	Button trResetYButton		,pos={13,205}	,size={90,22}	,title="Y Reset"								,help={"Resets Y offset and multiplier to 0."}
	Button trResetXButton		,pos={113,205}	,size={90,22}	,title="X Reset"								,help={"Resets X offset and multiplier to 0."}
	
	TitleBox trCsrControlTitle	,pos={13,240}	,size={190,13}	,title="Control Cursor Position"
	Button trPrevTraceButton	,pos={13,258}	,size={90,22}	,title="< Prev Trace"							,help={"Moves the cursor to onto the previous trace in the list of traces (page down key)."}
	Button trNextTraceButton	,pos={113,258}	,size={90,22}	,title="Next Trace >"							,help={"Moves the cursor to onto the next trace in the list of traces (page up key)."}
	Button trGoToMaxButton		,pos={13,288}	,size={90,22}	,title="Go to Max"								,help={"Sets the cursor to trace's maximum (h key)."}
	Button trGoToMinButton		,pos={113,288}	,size={90,22}	,title="Go to Min"								,help={"Sets the cursor to trace's minimum (l key)."}
	
	SetVariable trOffxDelta		,pos={58,325}	,size={100,16}	,title="dx:"					,bodyWidth=80	,help={"Negative values will flip trace in X direction."}
	SetVariable trOffyDelta		,pos={58,353}	,size={100,16}	,title="dy:"					,bodyWidth=80	,help={"Negative values will flip trace in Y direction."}
	Button trAddXButton			,pos={168,323}	,size={35,20}	,title="+"			,fstyle=1	,fsize=14		,help={"Add X delta value."}
	Button trRemXButton			,pos={13,323}	,size={35,20}	,title="-"			,fstyle=1	,fsize=14		,help={"Subtract X delta value."}
	Button trAddYButton			,pos={168,351}	,size={35,20}	,title="+"			,fstyle=1	,fsize=14		,help={"Add Y delta value."}
	Button trRemYButton			,pos={13,351}	,size={35,20}	,title="-"			,fstyle=1	,fsize=14		,help={"Subtract Y delta value."}

	Button trApplyCurButton		,pos={5,387}	,size={205,22}	,title="Apply to Current Data (overwrite!)"		,help={"Applies offsets and scales to the currently selected 1D data. Will overwrite the original waves, so use this with care!"}
	// ++++++++++++++++++++++++++++++++++++++++ settings +++++++++++++++++++++++++++++++++++++++++
	SetVariable trSetYOffset	,value=_NUM:0	,limits={-inf,inf,1}
	SetVariable trScaleYOffset	,value=_NUM:1	,limits={-inf,inf,kMultiIncrStep}
	SetVariable trShiftYOffset	,value=_NUM:0	,limits={-inf,inf,0}
	SetVariable trSetXOffset	,value=_NUM:0	,limits={-inf,inf,0.1}
	SetVariable trScaleXOffset	,value=_NUM:1	,limits={-inf,inf,kMultiIncrStep}
	SetVariable trShiftXOffset	,value=_NUM:0	,limits={-inf,inf,0}
	SetVariable trScaleNorm		,value=_NUM:0	,limits={-inf,inf,1}
	
	SetVariable trOffxDelta		,value=_NUM:0	,limits={-inf,inf,0}
	SetVariable trOffyDelta		,value=_NUM:0	,limits={-inf,inf,0}
	
	ModifyControlList ControlNameList(pSingle,";","tr*")		,win=$pSingle	,disable=2		// disable all cursor related controls for now
	ModifyControlList ControlNameList(pSingle,";","traceCsr*")	,win=$pSingle	,proc=TraceTool_CursorSelector	,mode = 1
	ModifyControlList ControlNameList(pSingle,";","*Button")	,win=$pSingle	,proc=TraceTool_ButtonFunctions
	ModifyControlList ControlNameList(pSingle,";","trS*") 		,win=$pSingle	,proc=TraceTool_SingleTraceVars	,format="%g"
	ModifyControlList ControlNameList(pSingle,";","*Title")		,win=$pSingle	,frame=0
#if IgorVersion() >= 7.00
	ModifyControlList ControlNameList(pSingle,";","trS*")		,win=$pSingle	,focusRing=0
#endif
	if (CmpStr(IgorInfo(2), "Macintosh") == 0)
		ModifyControlList ControlNameList(pSingle,";","*")		,win=$pSingle	,fsize=10
	endif
	SetActiveSubwindow ##
	
	Variable csrSet = 0
	String gName = getTopGraph()
	if (strlen(gName))																			// check whether one of the cursors is set
		csrSet = strlen(CsrInfo(A,gName)+CsrInfo(B,gName)+CsrInfo(C,gName)+CsrInfo(D,gName)) > 0
	endif
	TabControl offsetTabs value=csrSet															// if a cursor is set, display the single trace tab
	TraceTool_ToggleTabs(csrSet)
	
	FetchLatestTraceValues()																	// set variable values from top window
	return 0
End
//+++++++++++++++++++++++++++++++++++++ popup help functions +++++++++++++++++++++++++++++++++++++
Function/S TraceTool_ProfileWaveList()
	return "none;"+WaveList("*",";", "DIMS:1")
End

//################################################################################################

static Function getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)
	String gName, trace
	Variable &xOff, &yOff, &xScale, &yScale
	String info = TraceInfo(gName,trace,0)
	sscanf StringByKey("offset(x)", info, "="), "{%f,%f}", xOff, yOff
	sscanf StringByKey("muloffset(x)", info, "="), "{%f,%f}", xScale, yScale
	yScale = yScale == 0? 1 : yScale
	xScale = xScale == 0? 1 : xScale
	return 0
End

//################################################################################################

static Function getTraceOffset(gName, trace, axis)
	String gName, trace
	Variable axis
	Variable xOff = 0, yOff = 0
	sscanf StringByKey("offset(x)", TraceInfo(gName,trace,0), "="), "{%f,%f}", xOff, yOff
	return axis ? yOff : xOff
End

//################################ panel update helper function ##################################

Function OffsetPanelUpdateFunc(s)
	STRUCT WMWinHookStruct &s
	Variable HookTakeover = 0
	Switch (s.EventCode)
		case 0:		// activate
			HookTakeover = 1
			if (CmpStr(s.winName,"OffsetPanel") == 0)											// in case an older panel is open -> rebuild
				KillWindow OffsetPanel
				BuildTraceOffsetPanel()
			endif
			FetchLatestTraceValues()
		break
		case 11:	// keys
			String gName = getTopGraph()
			if (!strlen(gName))
				return 0
			endif
			HookTakeover = 1
			String Key = ""
			Switch(s.keycode)
				case 11:	// page up
					Key = "trNextTraceButton"
				break
				case 12:	// page down
					Key = "trPrevTraceButton"
				break
				case 104:	// h
					Key = "trGoToMaxButton"
				break
				case 108:	// l
					Key = "trGoToMinButton"
				break
			EndSwitch
			TraceTool_ExecuteButtonAction(Key)
			
			if (s.keycode > 96 && s.keycode < 101)	// a-d keys
				Key = StringFromList(s.keycode-97, "A;B;C;D;")
				if (strlen(CsrInfo($Key,gName)))
					TraceTool_SwitchCurrentCursor("traceCsr"+Key)
				endif
			endif
			
			if (s.keycode > 27 && s.keycode < 32)	// left, right, up, down
				HookTakeover = TraceTool_KeypadShiftandScale(s.keycode)
			endif
		break
	EndSwitch
	return HookTakeover
End

//################################################################################################

Function TraceTool_ToggleTabs(whichTab)
	Variable whichTab
	SetWindow TraceOffsetPanel#MultiTab  hide=whichTab==1
	SetWindow TraceOffsetPanel#SingleTab hide=whichTab==0
end

Function TraceTool_TabControl(s) : TabControl
	STRUCT WMTabControlAction &s
	if (s.eventCode == 2)
		TraceTool_ToggleTabs(s.tab)
	endif
End

//################################################################################################

Function TraceTool_KeypadShiftandScale(key)
	Variable key
	
	String gName = getTopGraph()
	if (!strlen(gName))
		return 0
	endif
	
	String trace = GetUserData("TraceOffsetPanel", "", "trace")									// get current trace name and cursor from panel user data
	String csr   = GetUserData("TraceOffsetPanel", "", "cursor")
	if (strlen(trace) == 0 || strlen(csr) == 0)
		return 0
	endif
	Variable xOff = 0, yOff = 0, xScale = 0, yScale = 0
	getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)
	Variable yScaleMult = kMultiIncrStep*10^GetValuesOrderOfMagnitude(yScale) 
	Variable xScaleMult = kMultiIncrStep*10^GetValuesOrderOfMagnitude(xScale) 
	
	Wave work  = TraceNameToWaveRef(gName, trace)
	Wave/Z w_x = XWaveRefFromTrace(gName, trace)
	Variable xDelta = DimDelta(work,0)															// delta shift values for cursor control
	Variable yDelta = WaveMax(work)*yScale*10*kOffsetIncrStep
	if (WaveExists(w_x))
		xDelta = abs(leftx(w_x)-rightx(w_x))/(numpnts(w_x))
	endif
	
	Variable neg = 1, mulDelta
	Switch(key)
		case 28:	// left
			neg = -1
		case 29:	// right
			if(GetKeyState(0) & 2^0)
				mulDelta = xScale*neg == -xScaleMult/5 ? xScaleMult*2/5 : xScaleMult/5			// don't scale to exactly zero (which will flip back to 1)
				ModifyGraph/W=$gName muloffset($trace)={xScale+neg*mulDelta,}
			else
				ModifyGraph/W=$gName offset($trace)={xOff+neg*xDelta,}
			endif
		break
		case 31:	// down
			neg = -1
		case 30:	// up
			if(GetKeyState(0) & 2^0)
				mulDelta = yScale*neg == -yScaleMult/5 ? yScaleMult*2/5 : yScaleMult/5
				ModifyGraph/W=$gName muloffset($trace)={,yScale+neg*mulDelta}
			else
				ModifyGraph/W=$gName offset($trace)={,yOff+neg*yDelta}
			endif
		break
	EndSwitch
	FetchLatestCursorValues(csr)
	AdjustProfileAxisScaling()
	return 1
End

//################################################################################################

Function TraceTool_SwitchOffsetMode(s) : CheckBoxControl
	STRUCT WMCheckboxAction &s
	if(s.eventCode == 2)
		CheckBox $StringFromList(0,RemoveFromList(s.ctrlName, ControlNameList("TraceOffsetPanel#MultiTab",";","Choose*"))) ,win=TraceOffsetPanel#MultiTab ,value=0		
	endif
	return 0
End

//################################################################################################

Function TraceTool_CursorSelector(s) : CheckBoxControl
	STRUCT WMCheckboxAction &s
	if(s.eventCode == 2)
		TraceTool_SwitchCurrentCursor(s.ctrlName)
	endif
	return 0
End

//################################################################################################

Function TraceTool_SwitchCurrentCursor(which)
	String which
	Variable i
	String ctrl = RemoveFromList(which, ControlNameList("TraceOffsetPanel#SingleTab",";","traceCsr*"))
	for (i = 0; i < ItemsInList(ctrl); i += 1)
		CheckBox $StringFromList(i,ctrl) ,win=TraceOffsetPanel#SingleTab ,value=0
	endfor
	CheckBox $which ,win=TraceOffsetPanel#SingleTab ,value=1
	FetchLatestCursorValues(ReplaceString("traceCsr", which, ""))
	return 0
End

//################################################################################################

static Function FetchLatestTraceValues()														// update both left and right side values (if cursors are set)
	String gName = getTopGraph()
	String pSingle = "TraceOffsetPanel#SingleTab"
	String pMulti  = "TraceOffsetPanel#MultiTab"
	
	ModifyControlList/Z ControlNameList(pSingle,";","tr*")+"trApplyCurButton;",win=$pSingle ,disable=2	// disable cursor related controls for now
	if (!strlen(gName))
		TitleBox MultiTargetTitle  ,win=$pMulti  ,title="No Graph Available!"	,fColor=(65535,0,0)
		TitleBox SingleTargetTitle ,win=$pSingle ,title="No Graph Available!" ,fColor=(65535,0,0)
		return 0
	endif
	Variable xRange, yRange
	String xUnit = "", yUnit = ""
	Variable error = GetAxisRange(xRange, yRange, xUnit, yUnit, gName)
	if (error)
		return -1
	endif
	xUnit = SelectString(strlen(xUnit),""," "+xUnit)
	yUnit = SelectString(strlen(yUnit),""," "+yUnit)
	
	String traces = ""
	Variable i, items = FetchTraces(gName,traces,0)
	Variable xOff = 0, yOff = 0, xShift = 0,  yShift = 0
	sscanf StringByKey("offset(x)", TraceInfo(gName,StringFromList(items-1,traces),0), "="), "{%f,%f}", xShift, yShift
	if (items > 1)																				// calculate shift and offset from first two traces
		sscanf StringByKey("offset(x)", TraceInfo(gName,StringFromList(items-2,traces),0), "="), "{%f,%f}", xOff, yOff
	else
		xOff = xShift; yOff = yShift
	endif
	
	TitleBox MultiTargetTitle 	,win=$pMulti	,title="\f01Modify:\f00 "+gName ,fColor=(0,0,0)
	SetVariable vaSetYOffset	,win=$pMulti	,value=_NUM:yOff-yShift	,format="%g"+yUnit	,limits={-inf,inf,yRange*kOffsetIncrStep}	,userdata=num2str(yOff-yShift)
	SetVariable vaShiftYOffset	,win=$pMulti	,value=_NUM:yShift		,format="%g"+yUnit	,limits={-inf,inf,yRange*kOffsetIncrStep}
	SetVariable vaSetXOffset	,win=$pMulti	,value=_NUM:xOff-xShift	,format="%g"+xUnit	,limits={-inf,inf,xRange*kOffsetIncrStep}	,userdata=num2str(xOff-xShift)
	SetVariable vaShiftXOffset	,win=$pMulti	,value=_NUM:xShift		,format="%g"+xUnit	,limits={-inf,inf,xRange*kOffsetIncrStep*10}
	PopupMenu ProfileSelect 	,win=$pMulti 	,mode=1											// update the selected profile or select none
	if (FindListItem("Profileleft", AxisList(gName)) >= 0)
		Wave profile = TraceNameToWaveRef(gName, "AddTraceProfile")
		PopupMenu ProfileSelect	,win=$pMulti	,popmatch=nameofwave(profile)
	endif
	
	Wave data = TraceNameToWaveRef(gName, StringFromList(0,traces))
	if (!WaveExists(data))																		// probably image data => not useful here
		return 0
	endif
	Button vaApplyAllButton 	,win=$pMulti 	,disable=2*(WaveDims(data) != 1)				// this button only works for 1D traces
	//------------------------------------- cursor controls --------------------------------------
	String csr = "A;B;C;D;", currCsr															// fetch available cursor list
	Variable selCsr = -1,  setCsr = -1, csrActive = 0
	for (i = 0; i < ItemsInList(csr); i += 1)													// find currently selected cursor
		currCsr = "traceCsr"+StringFromList(i,csr)
		ControlInfo/W=$pSingle $currCsr
		if (V_Value)
			CheckBox $currCsr ,win=$pSingle ,value=0											// deselect for now
			selCsr = i
			break
		endif
	endfor

	for (i = 0; i < ItemsInList(csr); i += 1)
		currCsr = StringFromList(i,csr)
		if (strlen(CsrInfo($currCsr,gName)))
			if (numtype(zcsr($currCsr,gName)) != 2)												// check for cursors on image plots
				continue
			endif
			if (csrActive == 0 && selCsr == i)													// the currently selected cursor is active and can stay
				csrActive = 1
				setCsr = i
			endif
			if (setCsr == -1)																	// find the first free cursor from left
				setCsr = i
			endif
			CheckBox $("traceCsr"+currCsr) ,win=$pSingle ,disable=0
		endif
	endfor
	
	if (setCsr == -1)
		SetWindow TraceOffsetPanel	,userdata(cursor)=""										// clear cursor user data
		if (selCsr != -1)
			CheckBox $("traceCsr"+StringFromList(selCsr,csr)) ,win=$pSingle ,value=1			// set previous cursor (disabled but keeps cursor selected)
		endif
		TitleBox SingleTargetTitle	,win=$pSingle ,title="No Trace Selected!" ,fColor=(65535,0,0)
		return 0
	endif
	//---------------------------------- if cursor was found -------------------------------------
	currCsr = StringFromList(setCsr,csr)
	CheckBox $("traceCsr"+currCsr) ,win=$pSingle ,value=1
	String ctrlList = RemoveFromList("traceCsrA;traceCsrB;traceCsrC;traceCsrD;",ControlNameList(pSingle,";","tr*"))+"trApplyCurButton;"
	ModifyControlList ctrlList	,win=$pSingle	,disable=0
	FetchLatestCursorValues(currCsr)															// now get cursor specific values (right side)
	return 0
End

//################################################################################################

static Function FetchLatestCursorValues(csr)
	String csr
	String gName = getTopGraph()
	String pSingle = "TraceOffsetPanel#SingleTab"
	if (!strlen(gName))
		return 0
	endif
	
	Variable xRange, yRange, shift
	String xUnit = "", yUnit = "", unit = ""
	Variable error = GetAxisRange(xRange, yRange, xUnit, yUnit, gName)
	if (error)
		return -1
	endif
	
	String trace = StringByKey("TNAME",CsrInfo($csr,gName))
	Variable xOff = 0, yOff = 0, xScale = 0, yScale = 0
	getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)
	xUnit = SelectString(strlen(xUnit),""," "+xUnit)
	yUnit = SelectString(strlen(yUnit),""," "+yUnit)
	
	Variable csrShiftx = (hcsr($csr, gName)*xScale+xOff)										// round to prevent floating point errors
	Variable csrShifty = (vcsr($csr, gName)*yScale+yOff)
	csrShiftx = round(csrShiftx*10^6)/10^6
	csrShifty = round(csrShifty*10^6)/10^6
	
	Variable yScOrder = GetValuesOrderOfMagnitude(yScale)
	Variable xScOrder = GetValuesOrderOfMagnitude(xScale) 

	String color = StringByKey("rgb(x)", TraceInfo(gName,trace,0), "=")							// show the color of the selected trace
	Wave data = TraceNameToWaveRef(gName, trace)
	TitleBox SingleTargetTitle	,win=$pSingle ,title="\f01Trace: \K"+color+ReplaceString("'",trace,"")+"\K(0,0,0)\f00",fColor=(0, 0, 0)
	Button trApplyCurButton 	,win=$pSingle ,disable=2*(WaveDims(data)!=1)					// this button only works for 1D traces
	SetVariable trSetYOffset	,win=$pSingle	,value=_NUM:yOff						,format="%g"+yUnit	,limits={-inf,inf,yRange*kOffsetIncrStep}
	SetVariable trShiftYOffset	,win=$pSingle	,value=_NUM:csrShifty					,format="%g"+yUnit	,limits={-inf,inf,yRange*kOffsetIncrStep*10}
	SetVariable trScaleYOffset	,win=$pSingle	,value=_NUM:yScale						,format="%g"		,limits={-inf,inf,kMultiIncrStep*10^yScOrder}
	SetVariable trSetXOffset	,win=$pSingle	,value=_NUM:xOff						,format="%g"+xUnit	,limits={-inf,inf,xRange*kOffsetIncrStep}
	SetVariable trShiftXOffset	,win=$pSingle	,value=_NUM:csrShiftx					,format="%g"+xUnit	,limits={-inf,inf,xRange*kOffsetIncrStep*10}
	SetVariable trScaleXOffset	,win=$pSingle	,value=_NUM:xScale						,format="%g"		,limits={-inf,inf,kMultiIncrStep*10^xScOrder}
	SetVariable trScaleNorm		,win=$pSingle	,value=_NUM:vcsr($csr, gName)*yScale	,format="%g"+yUnit
	
	SetVariable trOffxDelta		,win=$pSingle	,format="%g"									// first reset unit
	SetVariable trOffyDelta		,win=$pSingle	,format="%g"
	shift = TraceTool_FetchXShift(TraceNameToWaveRef(gName, trace),unit)
	if (numtype(shift) == 0)
		SetVariable trOffxDelta	,win=$pSingle	,value=_NUM:shift	,format="%g"+SelectString(strlen(unit),""," "+unit)
	endif
	unit = ""
	shift = TraceTool_FetchYShift(TraceNameToWaveRef(gName, trace),unit)
	if (numtype(shift) == 0)
		SetVariable trOffyDelta	,win=$pSingle	,value=_NUM:shift	,format="%g"+SelectString(strlen(unit),""," "+unit)
	endif
	
	SetWindow TraceOffsetPanel, userdata(trace)=trace											// save into panel's user data
	SetWindow TraceOffsetPanel, userdata(cursor)=csr
	return 0
End

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

static Function GetAxisRange(xRange, yRange, xUnit, yUnit, gName)
	Variable &xRange, &yRange
	String &xUnit, &yUnit, gName
	String Axes = AxisList(gName), str
	if (WhichListItem("left",Axes) > -1)
		GetAxis/W=$gName/Q left
		yRange = abs(V_max - V_min)
		yUnit  = StringByKey("UNITS", AxisInfo(gName,"left"))
	elseif (WhichListItem("right",Axes) > -1)
		GetAxis/W=$gName/Q right
		yRange = abs(V_max - V_min)
		yUnit  = StringByKey("UNITS", AxisInfo(gName,"right"))
	else
		return -1
	endif
	if (WhichListItem("bottom",Axes) > -1)
		GetAxis/W=$gName/Q bottom
		xRange = abs(V_max - V_min)
		xUnit  = StringByKey("UNITS", AxisInfo(gName,"bottom"))
	elseif (WhichListItem("top",Axes) > -1)
		GetAxis/W=$gName/Q top
		xRange = abs(V_max - V_min)
		xUnit  = StringByKey("UNITS", AxisInfo(gName,"top"))
	else
		return -1
	endif
	sprintf str, "%.*g\r", 1, yRange;	yRange = str2num(str)									// rounding
	sprintf str, "%.*g\r", 1, xRange;	xRange = str2num(str)
	return 0
End

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

static Function GetValuesOrderOfMagnitude(val)
	Variable val
	String NumChar = "", EChar = ""
	SPrintf NumChar, "%.1E", val
	SplitString/E=("[0-9]+.[0-9]([eE][-+]?[0-9]+)?") NumChar, EChar
	Variable OrderOfMagnitude = str2num(EChar[1,strlen(EChar)])
	OrderOfMagnitude = numtype(OrderOfMagnitude) != 0 ? 0 : OrderOfMagnitude
	return OrderOfMagnitude
End

//################################## variable helper function ####################################

Function TraceTool_SingleTraceVars(SV) : SetVariableControl
	STRUCT WMSetVariableAction &SV
	if (SV.eventCode == 1 || SV.eventCode == 2)
		SV.blockReentry=1
		String gName = getTopGraph()
		if (!strlen(gName))
			return 0
		endif
		
		String trace = GetUserData("TraceOffsetPanel", "", "trace")								// get current trace name and cursor from panel user data
		String csr   = GetUserData("TraceOffsetPanel", "", "cursor")
		if (strlen(trace) == 0 || strlen(csr) == 0)
			return 0
		endif
		
		Variable xOff = 0, yOff = 0, xScale = 0, yScale = 0
		getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)
		if (StringMatch(SV.ctrlName,"trScale*"))
			SV.dval = abs(SV.dval) < 10e-8 ? sign(SV.dval)*10e-8 : SV.dval						// prevent input from getting very small
		endif
		
		StrSwitch(SV.ctrlName)
			case "trSetYOffset":
				ModifyGraph/W=$gName offset($trace)={,SV.dval}
			break
			case "trSetXOffset":
				ModifyGraph/W=$gName offset($trace)={SV.dval,}
			break
			case "trShiftYOffset":
				ModifyGraph/W=$gName offset($trace)={,(SV.dval-vcsr($csr, gName)*yScale)}
			break
			case "trShiftXOffset":
				ModifyGraph/W=$gName offset($trace)={(SV.dval-hcsr($csr, gName)*xScale),}
			break
			case "trScaleYOffset":
				ModifyGraph/W=$gName muloffset($trace)={,SV.dval}
			break
			case "trScaleXOffset":
				ModifyGraph/W=$gName muloffset($trace)={SV.dval,}
			break
			case "trScaleNorm":
				if (vcsr($csr, gName) != 0)
					ModifyGraph/W=$gName muloffset($trace)={,SV.dval/vcsr($csr, gName)}
				endif
			break
		EndSwitch	
		FetchLatestCursorValues(csr)
		AdjustProfileAxisScaling()
	endif
	return 0
End

//################################################################################################

Function TraceTool_MultiTraceVars(SV) : SetVariableControl
	STRUCT WMSetVariableAction &SV
	if (SV.eventCode == 1 || SV.eventCode == 2)
		SV.blockReentry=1
		String gName = getTopGraph()
		if (!strlen(gName))
			return 0
		endif
		String traces = ""
		Variable items = FetchTraces(gName,traces,0)
		if (items == 0)
			return 0
		endif
		
		Variable PrevVal, curXOff = 0, curYOff = 0, xOff = 0, yOff = 0, YnotX = 0, i
		sscanf StringByKey("offset(x)", TraceInfo(gName,StringFromList(items-1,traces),0), "="), "{%f,%f}", xOff, yOff
		StrSwitch(SV.ctrlName)
			case "vaSetYOffset":
				YnotX = 1
			case "vaSetXOffset":
				ControlInfo/W=TraceOffsetPanel#MultiTab ChooseAdd
				Variable addMode = v_Value
				
				PrevVal = str2num(SV.Userdata);	SV.Userdata = num2str(SV.dval)					// get previous offset from and write current value to control user data
				for (i = 0; i < items; i += 1)
					if (addMode)
						sscanf StringByKey("offset(x)", TraceInfo(gName,StringFromList(items-1 - i,traces),0), "="), "{%f,%f}", curXOff, curYOff
						if (YnotX)
							ModifyGraph/W=$gName offset($StringFromList(items-1 - i,traces))={,i*(SV.dval-PrevVal)+curYOff}
						else
							ModifyGraph/W=$gName offset($StringFromList(items-1 - i,traces))={i*(SV.dval-PrevVal)+curXOff,}
						endif
					else
						if (YnotX)
							ModifyGraph/W=$gName offset($StringFromList(items-1 - i,traces))={,i*SV.dval+yOff}
						else
							ModifyGraph/W=$gName offset($StringFromList(items-1 - i,traces))={i*SV.dval+xOff,}
						endif
					endif
				endfor
			break
			case "vaScaleYOffset":
				YnotX = 1
			case "vaScaleXOffset":
				PrevVal = str2num(SV.Userdata);	SV.Userdata = num2str(SV.dval)					// get previous multiplier from and write current value to control user data
				PrevVal = PrevVal != 0 ? PrevVal : 1											// make sure multiplier is not zero
				for (i = 0; i < items; i += 1)
					sscanf StringByKey("offset(x)", TraceInfo(gName,StringFromList(items-1 - i,traces),0), "="), "{%f,%f}", curXOff, curYOff
					if (YnotX)
						ModifyGraph/W=$gName offset($StringFromList(items-1 - i,traces))={,(curYOff-yOff)*SV.dval/PrevVal+yOff}
					else
						ModifyGraph/W=$gName offset($StringFromList(items-1 - i,traces))={(curXOff-xOff)*SV.dval/PrevVal+xOff,}
					endif
				endfor
			break
			case "vaShiftYOffset":
				YnotX = 1
			case "vaShiftXOffset":
				for (i = 0; i < items; i += 1)
					sscanf StringByKey("offset(x)", TraceInfo(gName,StringFromList(items-1 - i,traces),0), "="), "{%f,%f}", curXOff, curYOff
					if (YnotX)
						ModifyGraph/W=$gName offset($StringFromList(items-1 - i,traces))={,(curYOff-yOff)+SV.dval}
					else
						ModifyGraph/W=$gName offset($StringFromList(items-1 - i,traces))={(curXOff-xOff)+SV.dval,}
					endif
				endfor
			break
		EndSwitch
		String csr = GetUserData("TraceOffsetPanel", "", "cursor")
		if (strlen(csr))
			FetchLatestCursorValues(csr)
		endif
		AdjustProfileAxisScaling()
	endif
	return 0
End

//++++++++++++++++++++++++++++++ help function to get a trace list ++++++++++++++++++++++++++++++

static Function FetchTraces(win,traces,getAll)
	String win, &traces
	Variable getAll
	
	Variable noHidden = 0, omit = 0
	String filter = ""
	if (WinType("TraceOffsetPanel") && !getAll)													// read settings from panel if open
		ControlInfo/W=TraceOffsetPanel#MultiTab cHiddenTraces
		if (V_flag)
			noHidden = !V_Value
		endif
		ControlInfo/W=TraceOffsetPanel#MultiTab vTraceFilter
		if (V_flag)
			filter = S_Value
		endif
		ControlInfo/W=TraceOffsetPanel#MultiTab cOmitFilter
		if (V_flag)
			omit = V_Value
		endif
	endif
	
	traces = TraceNameList(win,";",1+4*noHidden)
	if (strlen(filter))
		if (omit)
			traces = RemoveFromList(ListMatch(traces,filter),traces)
		else
			traces = ListMatch(traces,filter)
		endif
	endif
	
	Variable i, items = ItemsInList(traces)
	String xAxis, remItem = ""
	for (i = 0; i < items; i += 1)																// remove possible vertical traces
		xAxis = StringByKey("XAXIS",  TraceInfo(win,StringFromList(items-1 - i,traces),0))
		if (!(StringMatch(xAxis,"bottom") || StringMatch(xAxis,"top")))
			remItem += StringFromList(items-1 - i,traces)+";"
		endif
	endfor
	traces = RemoveFromList(remItem,traces)
	traces = RemoveFromListWC(traces, ksTraceIgnoreList)
	return 	ItemsInList(traces)
End

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

static Function/S RemoveFromListWC(listStr, zapListStr)											// returns listStr, purged of any items that match an item in ZapListStr.
	String listStr, zapListStr
	String removeStr=""
	Variable i
	for(i = 0; i < ItemsInList(zapListStr); i += 1)
		removeStr += ListMatch(listStr, StringFromList(i, zapListStr))							// Wildcards okay! Case insensitive.
	endfor
	return RemoveFromList(removeStr, listStr, ";", 0)
End

//+++++++++++++++++++++++++++++++ help function for Profile Axis +++++++++++++++++++++++++++++++++

static Function AdjustProfileAxisScaling()
	String gName = getTopGraph()
	if (!strlen(gName) || WhichListItem("Profileleft", AxisList(gName)) < 0)
		return 0
	endif

	String traces = ""
	Variable items = FetchTraces(gName,traces,1)												// get all traces
	if (items == 0)
		return 0
	endif
	Variable currMax = 0, dataMin = 0, i, scale = 0
	for (i = 0; i < items; i += 1)
		Variable yOff = getTraceOffset(gName, StringFromList(i,traces), 1)
		if (yOff > currMax)
			currMax = yOff
			Wave work = TraceNameToWaveRef(gName,StringFromList(i,traces))
			dataMin = WaveMin(work)
		endif
	endfor
	dataMin = numtype(dataMin) != 0 ? 0 : dataMin

	DoUpdate; GetAxis/W=$gName/Q left
	scale = (currMax+dataMin-V_min)/(V_Max-V_min)												// calculate the ratio between highest offset and axis height
	scale = Limit(scale, 0.1, 1)																// prevent scaling to useless values
	ModifyGraph/W=$gName axisEnab(Profileleft)={0,scale}
	return 0
End

//################################### button helper function #####################################

Function TraceTool_ButtonFunctions(s) : ButtonControl
	STRUCT WMButtonAction &s
	if (s.eventCode == 2)
		s.blockReentry=1
		TraceTool_ExecuteButtonAction(s.ctrlName)
	endif
	return 0
End

//################################################################################################

Function TraceTool_ExecuteButtonAction(which)
	String which
	String gName = getTopGraph()
	if (!strlen(gName))
		return 0
	endif
	String pSingle = "TraceOffsetPanel#SingleTab"
	String pMulti  = "TraceOffsetPanel#MultiTab"
	
	String trace = GetUserData("TraceOffsetPanel", "", "trace")									// get current selected trace name and cursor from panel user data
	String csr   = GetUserData("TraceOffsetPanel", "", "cursor")
	Variable xOff = 0, yOff = 0, xScale = 0, yScale = 0, setX, setY
	if (strlen(trace) && strlen(csr))
		getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)
	endif
	
	String traces = "",  list = ""
	Variable GoUp = 0, items, i
	StrSwitch(which)
		case "CsrActButton":
			items = FetchTraces(gName,traces,1)													// get all traces
			if (items == 0)
				break
			endif
			
			for (i = 0; i < 4; i += 1)
				String currCsr = StringFromList(i,"A;B;C;D;")
				if (!strlen(CsrInfo($currCsr,gName)))
					trace = StringFromList(0,traces)
					Wave work = TraceNameToWaveRef(gName,trace)
					GetAxis/W=$gName/Q bottom
					if (!V_flag)
						getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)
						Variable cursorLoc = (V_min+(V_max-V_min)/2 - xOff)/xScale				// center of the current axis corrected for scaling and offset of the current trace
						Cursor/W=$gName/P $currCsr, $trace, x2pnt(work,cursorLoc)				// set a new cursor in the center of the current axis scale if possible
					else
						Cursor/W=$gName/P $currCsr, $trace, DimSize(work,0)/2					// set a new cursor on the center of the first trace
					endif
					if (strlen(csr))															// if a cursor was already active, then switch over to the newly placed one
						CheckBox $("traceCsr"+csr)		,win=$pSingle ,value=0
						CheckBox $("traceCsr"+currCsr)	,win=$pSingle ,value=1
					endif
					FetchLatestTraceValues()
					break																		// cursor set => quit
				endif
			endfor
		break
		case "ColorButton":
			ControlInfo/W=$pMulti ColorSelect
			String Table = S_value
			ControlInfo/W=$pMulti cReverseColor
			ColorSpectrumFromTable((V_Value || GetKeyState(0) & 1), table)
		break
		case "ReverseButton":
			items = FetchTraces(gName,traces,1)													// get all traces
			if (items == 0)
				break
			endif
			for (i = 0; i < items; i += 1)														// reverse trace list
				list += StringFromList(items-1 - i,traces) + ";"
			endfor
			ControlInfo/W=$pMulti vaSetYOffset;	setY = V_Value
			ControlInfo/W=$pMulti vaSetXOffset;	setX = V_Value
			Make/Free/N=(items)/T w_traces = StringFromList(p,traces)
			Make/Free/N=(items) xOffsets = getTraceOffset(gName, w_traces[p], 0)-setX*(items-1-2*p)
			Make/Free/N=(items) yOffsets = getTraceOffset(gName, w_traces[p], 1)-setY*(items-1-2*p)
			String sortTraces = RemoveEnding(ReplaceString(";", list, ","), ",")
			Execute/Z "ReorderTraces/W="+gName+" _back_,{"+sortTraces+"}"						// execute reverse operation
			if (V_Flag)
				Print "Cannot reverse sorting: Too many traces."
				break
			else
				for (i = 0; i < items; i += 1)													// reapply offsets (in reverse)
					ModifyGraph/W=$gName offset($w_traces[i])={xOffsets[i],yOffsets[i]}
				endfor
				//FetchLatestTraceValues()
			endif
		break
		case "ResetYButton":																	// no break here... reverse button also resets trace offsets
			ModifyGraph/W=$gName offset={,0}//,muloffset={,0}
			SetVariable vaSetYOffset	,win=$pMulti	,value=_NUM:0	,userdata="0"
			SetVariable vaScaleYOffset	,win=$pMulti	,value=_NUM:1	,userdata="1"
			SetVariable vaShiftYOffset	,win=$pMulti	,value=_NUM:0
			AdjustProfileAxisScaling()															// resizes the profile axis
		break
		case "ResetXButton":
			ModifyGraph/W=$gName offset={0,}//,muloffset={0,}
			SetVariable vaSetXOffset	,win=$pMulti	,value=_NUM:0	,userdata="0"
			SetVariable vaScaleXOffset	,win=$pMulti	,value=_NUM:1	,userdata="1"
			SetVariable vaShiftXOffset	,win=$pMulti	,value=_NUM:0
			AdjustProfileAxisScaling()
		break
		case "trResetYButton":
			if (strlen(trace) && strlen(csr))
				ModifyGraph/W=$gName offset($trace)={,0} ,muloffset($trace)={,0}
				SetVariable trSetYOffset	,win=$pSingle	,value=_NUM:0
				SetVariable trScaleYOffset	,win=$pSingle	,value=_NUM:1
				SetVariable trShiftYOffset	,win=$pSingle	,value=_NUM:vcsr($csr, gName)
				SetVariable trScaleNorm		,win=$pSingle	,value=_NUM:vcsr($csr, gName)
				AdjustProfileAxisScaling()
			endif
		break
		case "trResetXButton":
			if (strlen(trace) && strlen(csr))
				ModifyGraph/W=$gName offset($trace)={0,} ,muloffset($trace)={0,}
				SetVariable trSetXOffset	,win=$pSingle	,value=_NUM:0
				SetVariable trScaleXOffset	,win=$pSingle	,value=_NUM:1
				SetVariable trShiftXOffset	,win=$pSingle	,value=_NUM:hcsr($csr, gName)
				AdjustProfileAxisScaling()
			endif
		break
		case "trGoToMaxButton":
			GoUp = 1
		case "trGoToMinButton":
			if (strlen(trace) && strlen(csr))
				Wave work = CsrWaveRef($csr,gName)
				WaveStats/Q work
				if (GoUp)
					setX = WaveDims(work) == 2 ? V_maxRowLoc : V_maxLoc
					setY = V_maxColLoc
				else
					setX = WaveDims(work) == 2 ? V_minRowLoc : V_minLoc
					setY = V_minColLoc
				endif
				if (strlen(ImageInfo(gName,trace,0)))
					Cursor/W=$gName/I $csr, $trace, setX, setY									// move cursor to image position
				else
					Cursor/W=$gName	 $csr, $trace, setX											// move cursor to trace position
				endif
				FetchLatestCursorValues(csr)
			endif
		break
		case "trNextTraceButton":
			GoUp = 1
		case "trPrevTraceButton":
			if (strlen(trace) && strlen(csr))
				items = FetchTraces(gName,traces,0)
				setX  = hcsr($csr, gName)
				Variable position = WhichListItem(trace, traces)
				String nextTrace = ""
				if (GoUp)
					if (position < items-1)
						 nextTrace = StringFromList(position+1,traces)
					endif
				else
					if (position > 0)
						 nextTrace = StringFromList(position-1,traces)
					endif
				endif
				setX = setX*xScale + xOff														// correct for current trace's offsets
				if (!strlen(ImageInfo(gName,trace,0)) && strlen(nextTrace))
					getAllTraceOffsets(gName, nextTrace, xOff, yOff, xScale, yScale)
					setX = (setX - xOff)/xScale													// correct for next trace's offsets
					Cursor/W=$gName $csr, $nextTrace, setX										// move cursor to next trace
				endif
				FetchLatestCursorValues(csr)
			endif
		break
		case "trAddXButton":
			GoUp = 1
		case "trRemXButton":
			if (strlen(trace) && strlen(csr))
				GoUp = GoUp == 0 ? -1 : GoUp
				ControlInfo/W=$pSingle trOffxDelta
				setX = V_Value
				if (setX < 0)
					ModifyGraph/W=$gName muloffset($trace)={-GoUp*abs(xScale),}
				else
					xScale = xScale == -1 ? 0 : xScale
					ModifyGraph/W=$gName muloffset($trace)={abs(xScale),}
				endif
				ModifyGraph/W=$gName offset($trace)={(GoUp*abs(setX)+xOff),}
				FetchLatestCursorValues(csr)
			endif
		break
		case "trAddYButton":
			GoUp = 1
		case "trRemYButton":
			if (strlen(trace) && strlen(csr))
				GoUp = GoUp == 0 ? -1 : GoUp
				ControlInfo/W=$pSingle trOffyDelta
				setY = V_Value
				if (setY < 0)
					ModifyGraph/W=$gName muloffset($trace)={,-GoUp*abs(yScale)}
				else
					yScale = yScale == -1 ? 0 : yScale
					ModifyGraph/W=$gName muloffset($trace)={,abs(yScale)}
				endif
				ModifyGraph/W=$gName offset($trace)={,(GoUp*abs(setY)+yOff)}
				AdjustProfileAxisScaling()
				FetchLatestCursorValues(csr)
			endif
		break
		case "trNormTo1Button":
			if (strlen(trace) && strlen(csr))
				if (vcsr($csr, gName) != 0)
					ModifyGraph/W=$gName muloffset($trace)={,1/vcsr($csr, gName)}
					FetchLatestCursorValues(csr)
				endif
			endif
		break
		case "trApplyCurButton":
			if (strlen(trace))																	// falls through with only the current trace selected
				traces = trace
				items  = 1
			endif
		case "vaApplyAllButton":
			if (!strlen(traces))
				items = FetchTraces(gName,traces,0)
			endif
			for (i = 0; i < items; i += 1)
				trace = StringFromList(i,traces)
				getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)
				
				Wave work  = TraceNameToWaveRef(gName, trace)									// apply all scales and offsets to 1D data
				Wave/Z w_x = XWaveRefFromTrace(gName, trace)
				if (WaveDims(work) != 1)														// just in case there is 2D data mixed in
					continue
				endif
				work *= yScale
				work += yOff
				if(WaveExists(w_x))
					w_x *= xScale
					w_x += xOff
				else
					SetScale/P x, DimOffset(work,0) * xScale + xOff, DimDelta(work,0) * xScale, WaveUnits(work,0), work
				endif
				ModifyGraph/W=$gName offset($trace)={0,0} ,muloffset($trace)={0,0}
				
				String lognote = ""																// write a simple log
				lognote += SelectString((xScale!=1),"","\rx-scale="+num2str(xScale))
				lognote += SelectString((xOff!=0),"","\rx-offset="+num2str(xOff))
				lognote += SelectString((yScale!=1),"","\ry-scale="+num2str(yScale))
				lognote += SelectString((yOff!=0),"","\ry-offset="+num2str(yOff))
				if (strlen(lognote))
					lognote[0] = "\rscaling and offsets applied:"
					Note work, lognote
				endif
			endfor
			FetchLatestTraceValues()
		break
	EndSwitch
	return 0
End

//#################################### popup helper function #####################################

Function TraceTool_ProfileSelect(s) : PopupMenuControl
	STRUCT WMPopupAction &s
	if (s.eventCode != 2)
		return 0
	endif
	String gName = getTopGraph()
	if (!strlen(gName))
		return 0
	endif
	SetActiveSubwindow $gName																	// make sure to do stuff in the graph window
	String axes = AxisList(gName)
	if (FindListItem("Profileleft", axes) != -1)												// see if the additional Profile axis is attached
		RemoveFromGraph/W=$gName $("AddTraceProfile")											// remove the old trace (if present)
		if (WhichListItem("bottom",axes) > -1)													// reset the axes and remove the drawn line from previous selections
			ModifyGraph/W=$gName axisEnab(bottom)={0,1}
		endif
		if (WhichListItem("top",axes) > -1)
			ModifyGraph/W=$gName axisEnab(top)={0,1}
		endif
	endif

	StrSwitch(s.popStr)
		case "none":																			// do nothing
			break
		default:
			Wave inwave = $s.popStr
			if (WhichListItem("bottom",axes) > -1)												// make the bottom axis shorter
				ModifyGraph/W=$gName axisEnab(bottom)={0,0.72}
			endif
			if (WhichListItem("top",axes) > -1)
				ModifyGraph/W=$gName axisEnab(top)={0,0.72}
			endif
			AppendToGraph/W=$gName/C=(0,15872,65280)/B=Profilebottom/L=Profileleft/VERT inwave/TN=AddTraceProfile	// append the Profile trace
			ModifyGraph/W=$gName mirror(Profilebottom)=2
			ModifyGraph/W=$gName axisEnab(Profilebottom)={0.76,1}	
			ModifyGraph/W=$gName freePos(Profilebottom)=0 ,freePos(Profileleft)={0.76,kwFraction}					// move the new axes to the right position
			ModifyGraph/W=$gName tkLblRot(Profileleft)=90										// rotate the tick labels
			ModifyGraph/W=$gName minor(Profileleft)=1, tick(Profileleft)=2						// minor ticks
			ModifyGraph/W=$gName standoff=0														// axes are aligned, having no 1 pixel standoff
			ModifyGraph/W=$gName ZisZ(Profilebottom)=1,	ZisZ(Profileleft)=1						// zero is 0 (not 0.00)
			ModifyGraph/W=$gName notation(Profilebottom)=1										// scientific notation (10^4 instead of 10*10^3)
			ModifyGraph/W=$gName tlOffset(Profileleft)=-2										// move the labels in a bit
			AdjustProfileAxisScaling()															// resizes the profile axis
		break
	EndSwitch
	return 0
End

//################################################################################################

Function ColorSpectrumFromTable(rev, table)
	Variable rev
	String table
	
	String traces = "", gName = getTopGraph()
	Variable i, items = FetchTraces(gName,traces,0)
	if (items == 0)																				// may be an image
		traces = StringFromList(0,ImageNameList(gName,";"))
		if (strlen(traces) == 0)
			return 0
		endif
		ModifyImage/W=$gName $traces ctab={,,$table,rev}
		return 0
	endif
	
	ColorTab2Wave $table
	Wave M_colors
	for (i = 0; i < items; i += 1)
		Variable row = (i/(items-1))*(DimSize(M_Colors, 0)-1)
		Variable red = M_Colors[row][0], green = M_Colors[row][1], blue = M_Colors[row][2]
		Variable idx = rev == 0 ? i : (items-1)-i
		ModifyGraph/W=$gName/Z rgb($StringFromList(idx,traces)) = (red, green, blue)
	endfor
	KillWaves/Z M_colors
	return 0
End

//________________________________________________________________________________________________
//
//										GRAPH SIZE PANEL
//________________________________________________________________________________________________

Function BuildGraphSizePanel()
	String pName = "GraphSizePanel"
	if (WinType(pName))
		DoWindow/F $pName
		return 0
	endif
	
	NewPanel/K=1/W=(500,60,820,538)/N=$pName as "Set Graph Size"
	ModifyPanel /W=$pName ,fixedSize=1 //,noEdit=1
	SetWindow $pName hook(UpdateHook)=SizePanelUpdateFunc
	SetWindow $pName userdata(procVersion)=num2str(kVersion)									// save procedure version
	
	SetDrawLayer UserBack
	SetDrawEnv linethick= 2,fillpat= 0															// full rectangle
	DrawRect 17,10,305,198
	SetDrawEnv linethick= 2,dash= 3,fillpat= 0													// dashed rectangle
	DrawRect 55,40,265,168
	
	SetDrawEnv linethick= 2,linefgc=(16380,28400,65535),arrow=3,arrowfat=0.80					// blue arrows
	DrawLine 58,73,257,73
	SetDrawEnv linethick= 2,linefgc=(16380,28400,65535),arrow=3,arrowfat=0.80
	DrawLine 210,43,210,166
	
	SetDrawEnv linethick= 2,linefgc=(8000,39320,19940),arrow=3,arrowfat=0.80					// green arrows
	DrawLine 21,153,300,153
	SetDrawEnv linethick= 2,linefgc=(8000,39320,19940),arrow=3,arrowfat=0.80
	DrawLine 110,13,110,196
	
	SetDrawEnv linethick= 2,linefgc=(36870,14755,58980),arrow=3,arrowfat=0.80					// purple arrows
	DrawLine 123,171,123,196
	SetDrawEnv linethick= 2,linefgc=(36870,14755,58980),arrow=3,arrowfat=0.80					// vert top
	DrawLine 123,13,123,38
	SetDrawEnv linethick= 2,linefgc=(36870,14755,58980),arrow=3,arrowfat=0.80					// hor left
	DrawLine 21,95,51,95
	SetDrawEnv linethick= 2,linefgc=(36870,14755,58980),arrow=3,arrowfat=0.80					// hor right
	DrawLine 270,95,300,95
	
	TitleBox TplotW		,pos={140,45}	,size={48,16}	,title=" plot W: "	,anchor=MT ,labelBack=(16380,28400,65535)
	TitleBox TplotH		,pos={188,85}	,size={45,16}	,title=" plot H: "	,anchor=MT ,labelBack=(16380,28400,65535)
	TitleBox TgraphW	,pos={82,85}	,size={55,16}	,title=" graph H: "	,anchor=MT ,labelBack=(8000,39320,19940)
	TitleBox TgraphH	,pos={135,125}	,size={58,16}	,title=" graph W: "	,anchor=MT ,labelBack=(8000,39320,19940)
	ModifyControlList ControlNameList(pName,";","T*")	,fixedSize=1	,frame=0	,fStyle=1	,fColor=(65535,65535,65535)
	
	SetVariable VLeftMargin		,pos={10,103}	,value=_NUM:0
	SetVariable VBottomMargin	,pos={133,175}	,value=_NUM:0
	SetVariable VRightMargin	,pos={250,103}	,value=_NUM:0
	SetVariable VTopMargin		,pos={133,16}	,value=_NUM:0
	SetVariable VGraphHeight	,pos={80,103}	,value=_NUM:0
	SetVariable VPlotWidth		,pos={133,63}	,value=_NUM:0
	SetVariable VGraphWidth		,pos={133,143}	,value=_NUM:0
	SetVariable VPlotHeight		,pos={180,103}	,value=_NUM:0
	SetVariable VMagnification	,pos={235,175}	,value=_NUM:0
	SetVariable VGraphFont		,pos={35,175}	,value=_NUM:0
	
	ModifyControlList ControlNameList(pName,";","V*")	,limits={0,2000,1}		,size={60,18} ,bodyWidth=60 ,proc=Gsize_VarControl
	SetVariable VMagnification	,title="magn.:"	,limits={0,8,0} 	,bodyWidth=40	,format="%g x"
	SetVariable VGraphFont		,title="font:"	,limits={0,100,0}	,bodyWidth=40						,help={"Sets the global graph font. If shift+enter is pressed instead the global axes font is changed. Insert 0 to reset to 'auto'"}

	CheckBox cPrint				,pos={25,17}	,size={23,23}	,title="print cmd"			,value=0	,help={"Prints modify commands into history."}
	TitleBox SwapTitle			,pos={147,85}	,size={60,23}	,title="\JCswap:"						,frame=0
	PopupMenu SizeUnit			,pos={210,16}	,size={70,23}	,title="unit: "				,mode=1		,proc=Gsize_PresetPopup		,popvalue="points"	,value= #"\"points;inches;cm\""
	CheckBox SwapAxes			,pos={154,105}	,size={23,23}	,title=""					,value=0	,proc=Gsize_SwapGraph
	
	GroupBox GrAxisToggle		,pos={8,208}	,size={304,92}	,title="Toggle Axis Ticks & Labels (Set Margins):"	,fStyle=1	,frame=0	,fColor=(36870,14755,58980)
	CheckBox cAxis_left			,pos={49,228}	,size={23,23}	,title="Left"				,value=0
	CheckBox cAxis_bottom		,pos={116,228}	,size={23,23}	,title="Bottom"				,value=0
	CheckBox cAxis_right		,pos={183,228}	,size={23,23}	,title="Right"				,value=0
	CheckBox cAxis_top			,pos={250,228}	,size={23,23}	,title="Top"				,value=0
	
	SetVariable tlAxis_left		,pos={49,250}	,value=_NUM:0	,title="Tick:"
	SetVariable tlAxis_bottom	,pos={116,250}	,value=_NUM:0
	SetVariable tlAxis_right	,pos={183,250}	,value=_NUM:0
	SetVariable tlAxis_top		,pos={250,250}	,value=_NUM:0
	ModifyControlList ControlNameList(pName,";","tlAxis_*")	,limits={-50,50,1}	,size={52,18} ,bodyWidth=52 ,proc=Gsize_VarControl
	
	SetVariable alAxis_left		,pos={49,274}	,value=_NUM:0	,title="Axis:"
	SetVariable alAxis_bottom	,pos={116,274}	,value=_NUM:0
	SetVariable alAxis_right	,pos={183,274}	,value=_NUM:0
	SetVariable alAxis_top		,pos={250,274}	,value=_NUM:0
	ModifyControlList ControlNameList(pName,";","alAxis_*")	,limits={-50,50,1}	,size={52,18} ,bodyWidth=52 ,proc=Gsize_VarControl

	GroupBox GrSizeSetting		,pos={8,308}	,size={304,75}	,title="Set & Copy Graph Sizes:"	,fStyle=1	,frame=0	,fColor=(8000,39320,19940)
	CheckBox KeepAutoMode		,pos={15,358}	,size={23,23}	,title="Keep Auto Mode"		,value=1	,help={"Automatically resets the mode to Auto after changing the size."}
	PopupMenu AspectSelect		,pos={17,328}	,size={130,22}	,title="Aspect Ratio:"		,bodyWidth=60	,proc=Gsize_PresetPopup
	PopupMenu FormatSelect		,pos={130,328}	,size={175,22}	,title="Format:"			,bodyWidth=100	,proc=Gsize_PresetPopup
	Button CopyAllButton		,pos={130,354}	,size={80,22}	,title="Copy Sizes"
	Button PasteAllButton		,pos={220,354}	,size={85,22}	,title="Paste to Top"
	
	GroupBox GrStyleSetting		,pos={8,390}	,size={304,78}	,title="Set & Copy Graph Styles:"	,fStyle=1	,frame=0
	Button CopyStyleButton		,pos={18,410}	,size={85,22}	,title="Copy Style"						,help={"Copies the style of the top graph."}
	CheckBox CopyAxes			,pos={115,412}	,size={60,22}	,title="incl. Axis Range"	,value=1	,help={"Copies the axis scaling as well."}
	PopupMenu GrStyle			,pos={15,440}	,size={205,22}	,title="Style:"				,bodyWidth=170
	Button RevertButton			,pos={230,410}	,size={75,22}	,title="Revert"							,help={"Reverts to last style before Apply was pressed."}
	Button ApplyButton			,pos={230,438}	,size={75,22}	,title="\f01Apply"						,help={"Applies selected style to the top graph."}
	
	PopupMenu GrStyle			,mode=1	,value= Gsize_FetchGraphMacroList()
	PopupMenu AspectSelect		,mode=1	,value= "Free;1:1;-;4:3;3:2;16:9;-;2:3;3:4;4:5"
	PopupMenu FormatSelect		,mode=1	,value= "Free Size;Paper Half;Paper Full;PPT 16:9 Half;PPT 16:9 Full;PPT 4:3 Half;PPT 4:3 Full;"
	
	ModifyControlList ControlNameList(pName,";","*Button")	,proc=Gsize_CopyPaste
	ModifyControlList ControlNameList(pName,";","cAxis_*")	,proc=Gsize_ToggleAxis
	
	if (CmpStr(IgorInfo(2), "Macintosh") == 0)
		ModifyControlList ControlNameList(pName,";","*") ,fsize=10
	endif
	
	NVAR/Z unit = root:$ksGraphSizeUnitSave														// load saved settings
	if (NVAR_Exists(unit))
		PopupMenu SizeUnit ,mode=unit
		String CtrlList = RemoveFromList("VMagnification;VGraphFont;",ControlNameList(pName,";","V*"))
		Variable div  = unit == 1 ? 1 : (unit == 2 ? 72 : 72/2.54)								// in points, inches or cm
		Variable step = unit == 1 ? 1 : (unit == 2 ? 0.014 : 0.036)
		ModifyControlList CtrlList ,limits={0,8000/div,step}									// official max size is 8000 points
	endif

	FetchLatestGraphSizeValues()
	return 0
End
//++++++++++++++++++++++++++++++++ panel update helper function ++++++++++++++++++++++++++++++++++
Function SizePanelUpdateFunc(s)
	STRUCT WMWinHookStruct &s
	If (s.eventCode == 0)
		FetchLatestGraphSizeValues()
		return 1
	endif
	return 0
End

//################################################################################################

Function/S Gsize_FetchGraphMacroList()
	String list = MacroList("*",";","KIND:1,SUBTYPE:GraphStyle")
	String copy = GetUserData("GraphSizePanel", "", "CopyStyle")
	if (strlen(copy))
		list[0] = "Copied Style;"
	endif
	return list
End

//################################################################################################

Function Gsize_SwapGraph(s) : CheckBoxControl
	STRUCT WMCheckboxAction& s
	
	String gName = getTopGraph()
	if (s.eventCode == 2 && strlen(gName) > 0)
		ControlInfo/W=$(s.win) AspectSelect
		String currAspect = S_Value
		ChangeAspectRatio("Free")																// release the aspect mode and set again later (otherwise swap will switch this too)
		ModifyGraph/W=$gName/Z swapXY=s.checked
		ControlInfo/W=$(s.win) cPrint
		if (V_Value && V_flag == 2)
			print "•ModifyGraph swapXY="+num2str(s.checked)
		endif
		ChangeAspectRatio(currAspect)
		FetchLatestGraphSizeValues()
	endif
	return 0
End

//################################################################################################

Function Gsize_ToggleAxis(s) : CheckBoxControl
	STRUCT WMCheckboxAction& s
	String gName = getTopGraph()
	if (s.eventCode == 2 && strlen(gName) > 0)
		SetAxisLabelsAndTicks(ReplaceString("cAxis_",s.ctrlName,""), gName, !s.checked)
		FetchLatestGraphSizeValues()
	endif
	return 0
End
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
static Function SetAxisLabelsAndTicks(axName, gName, off)
	String axName, gName
	Variable off
	if (FindListItem(axName,AxisList(gName)) > -1)
		ModifyGraph/W=$gName tick($axName)=3*off
		ModifyGraph/W=$gName noLabel($axName)=1*off
		ModifyGraph/W=$gName margin($axName)=25*off
		ControlInfo/W=GraphSizePanel cPrint
		if (V_Value)
			print "•ModifyGraph tick("+axName+")="+num2str(3*off)+", noLabel("+axName+")="+num2str(1*off)+", margin("+axName+")="+num2str(25*off)
		endif
	endif
	return 0
End

//################################################################################################

Function Gsize_CopyPaste(s) : ButtonControl
	STRUCT WMButtonAction &s
	if (s.eventCode != 2)
		return 0
	endif
	String gName = getTopGraph()
	if (!strlen(gName))
		return 0
	endif
	String topLevelgName = StringFromList(0, gName, "#")

	String cName = "", CtrlList = "", ValList = "", Others = "", AxisSet = "", Style = ""
	Variable i
	StrSwitch(s.ctrlName)
		case "CopyAllButton":
			CtrlList = ControlNameList(s.win, ";", "*Axis_*")
			for (i = 0; i < ItemsInList(CtrlList); i += 1)
				ControlInfo/W=$(s.win) $StringFromList(i,CtrlList)
				AxisSet += StringFromList(i,CtrlList) + ":" + num2str(V_Value) + ";"
			endfor

			CtrlList = ControlNameList(s.win, ";", "V*")
			CtrlList = RemoveFromList("VGraphWidth;VGraphHeight;",CtrlList)
			for (i = 0; i < ItemsInList(CtrlList); i += 1)
				ControlInfo/W=$(s.win) $StringFromList(i,CtrlList)
				ValList += num2str(V_Value) + ";"
			endfor
			ControlInfo/W=$(s.win) SwapAxes;		Others +=  "SwapAxes:" + num2str(V_Value) + ";"
			ControlInfo/W=$(s.win) SizeUnit;		Others +=  "SizeUnit:" + S_Value + ";"
			ControlInfo/W=$(s.win) AspectSelect;	Others +=  "Aspect:" + S_Value + ";"
			ControlInfo/W=$(s.win) FormatSelect;	Others +=  "Format:" + S_Value + ";"
		
			SetWindow $(s.win) ,userdata(CtrlSet)=CtrlList										// saved in the panel's user data
			SetWindow $(s.win) ,userdata(ValSet)=ValList
			SetWindow $(s.win) ,userdata(OtherSet)=Others
			SetWindow $(s.win) ,userdata(AxesSet)=AxisSet
		break
		case "PasteAllButton":
			Others   = GetUserData(s.win, "", "OtherSet")
			AxisSet	 = GetUserData(s.win, "", "AxesSet")
			if (strlen(Others) == 0)
				break
			endif
			Variable swap = str2num(StringByKey("SwapAxes", Others))
			CheckBox SwapAxes  		,win=$(s.win)	,value=swap
			PopupMenu SizeUnit 		,win=$(s.win)	,popMatch=StringByKey("SizeUnit", Others)
			PopupMenu FormatSelect	,win=$(s.win)	,popMatch=StringByKey("Format", Others)
			PopupMenu AspectSelect	,win=$(s.win)	,popMatch=StringByKey("Aspect", Others)
			
			Variable cValue
			CtrlList = ControlNameList(s.win, ";", "cAxis_*")
			for (i = 0; i < ItemsInList(CtrlList); i += 1)
				cName	= StringFromList(i,CtrlList)
				cValue	= str2num(StringByKey(cName, AxisSet)) == 0
				SetAxisLabelsAndTicks(ReplaceString("cAxis_",cName,""), gName, cValue)
			endfor
			
			CtrlList = ControlNameList(s.win, ";", "tlAxis_*")+ControlNameList(s.win, ";", "alAxis_*")
			for (i = 0; i < ItemsInList(CtrlList); i += 1)
				cName	= StringFromList(i,CtrlList)
				cValue	= str2num(StringByKey(cName, AxisSet))
				SetVariable $cName	,win=$(s.win) ,value=_NUM:cValue
				ControlInfo/W=$(s.win) $cName
				if (V_disable == 0)
					ExecuteVarChange(cName, cValue)
				endif
			endfor
			
			CtrlList = GetUserData(s.win, "", "CtrlSet")
			ValList	 = GetUserData(s.win, "", "ValSet")
			for (i = 0; i < ItemsInList(CtrlList); i += 1)
				cName  = StringFromList(i,CtrlList)
				cValue = str2num(StringFromList(i,ValList))
				SetVariable $cName	,win=$(s.win) ,value=_NUM:cValue
				ExecuteVarChange(cName, cValue)
			endfor
			
			ModifyGraph/W=$gName/Z swapXY=swap
			String aspect = StringByKey("Aspect", Others)
			if (!StringMatch(aspect,"Free"))													// actually apply aspect ratio setting as well (should come after swapXY)
				ChangeAspectRatio(aspect)
			endif
		break
		case "ApplyButton":																		// applies selected graph style
			ControlInfo/W=$(s.win) GrStyle
			Style = S_value
			String Last = WinRecreation(topLevelgName,0)
			Variable noRevert = (StringMatch(Last,"*TransformMirror*") || StringMatch(Last,"*AxisTransform*"))	// graphs with a transformed axis cannot be recreated
			if (noRevert)
				DoAlert 1, "Reverting the graph will not be possible. Apply anyway?"
				if (V_flag != 1)
					break
				endif
			endif
			
			DoWindow/F $topLevelgName															// make sure the window is in front for the macro to work on
			if (StringMatch(Style,"Copied Style"))
				Style = GetUserData(s.win, "", "CopyStyle") 
				for (i = 0; i < ItemsInList(Style); i += 1)
					Execute/Q StringFromList(i,Style)
				endfor
			elseif (strlen(Style))
				Execute/Q Style+"()"
				ControlInfo/W=$(s.win) cPrint
				if (V_Value && V_flag == 2)
					print "•"+Style+"()"
				endif
			endif
			DoWindow/F $(s.win)
			
			if (!noRevert)
				SetWindow $(s.win), userdata(LastgName)=topLevelgName							// save into panel's user data
				SetWindow $(s.win), userdata(LastStyle)=Last
			endif
		break
		case "RevertButton":																	// copies top-graph's style
			Style = GetUserData(s.win, "", "LastStyle")											// check for existence of backup style
			if (strlen(Style) > 0)
				KillWindow $topLevelgName
				String/G ExeCmd = Style
				Execute/P/Q "Execute ExeCmd"
				Execute/P/Q "KillStrings/Z ExeCmd"
			endif
		break
		case "CopyStyleButton":																	// copies style of selected graph
			Style = WinRecreation(gName,1)
			String childList = ChildWindowList(gName), childStyle = ""							// need to clean the style macro of any subwindow styles (won't work anyway)
			for (i = 0; i < ItemsInList(childList); i += 1)
				childStyle = WinRecreation(gName+"#"+StringFromList(i,childList),1)
				childStyle = RemoveListItem(0,childStyle, "\r")									// remove "proc" line
				childStyle = RemoveListItem(0,childStyle, "\r")									// remove "pauseupdate" line
				childStyle = RemoveListItem(ItemsInList(childStyle,"\r") - 1,childStyle, "\r")	// remove "endmacro" line
				Style = ReplaceString(childStyle,Style,"")										// remove child window style
			endfor
			Style = GrepList(Style, "^\t(DefineGuide|ControlBar|SetWindow|Cursor|ListBox|CheckBox|PopupMenu|ValDisplay|SetVariable|Button|NewPanel|ModifyPanel|RenameWindow|SetActiveSubwindow|ShowTools)", 1, "\r") // remove control items
			Style = GrepList(Style, "^\t(ModifyGraph/Z rgb|ModifyGraph/Z muloffset|ModifyGraph/Z offset|ShowInfo)", 1, "\r")
			ControlInfo/W=$(s.win) CopyAxes														// include axes if checkbox is active
			if (!V_Value)
				Style = GrepList(Style, "^\t(SetAxis)", 1, "\r")
			endif
			Style = RemoveListItem(0,Style, "\r")												// remove "proc" line
			Style = RemoveListItem(0,Style, "\r")												// remove "pauseupdate" line
			Style = RemoveListItem(ItemsInList(Style,"\r") - 1,Style, "\r")						// remove "endmacro" line
			Style = ReplaceString("\t", Style, "")
			Style = ReplaceString("\r", Style, ";")
			SetWindow $(s.win), userdata(CopyStyle)=Style										// save into panel's user data
			PopupMenu GrStyle ,win=$(s.win) ,mode= 1
		break
	EndSwitch
	FetchLatestGraphSizeValues()
	return 0
End

//################################################################################################

Function Gsize_VarControl(s) : SetVariableControl
	struct WMSetVariableAction &s
	if (s.eventCode == 1 || s.eventCode == 2)
		ExecuteVarChange(s.ctrlName, s.dval)
	endif
	return 0
End
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
static Function ExecuteVarChange(ctrlName, val)
	String ctrlName
	Variable val
	String gName = getTopGraph()
	String pName = "GraphSizePanel"
	if (!strlen(gName))
		return 0
	endif

	ControlInfo/W=$pName SizeUnit
	Variable modifier = V_Value == 1 ? 1 : (V_Value == 2 ? 72 : 72/2.54)						// in points, inches or cm
	ControlInfo/W=$pName KeepAutoMode
	Variable Auto = V_Value																		// reset to Auto scale mode after size change
	ControlInfo/W=$pName cPrint
	Variable printcmd = V_flag == 2 ? V_Value :0
	
	String cmd = ""
	StrSwitch(ctrlName)
		case "VLeftMargin":
			ModifyGraph/W=$gName margin(left) = val*modifier
			cmd = "margin(left)="+num2str(val*modifier)
		break
		case "VBottomMargin":
			ModifyGraph/W=$gName margin(bottom) = val*modifier
			cmd = "margin(bottom)="+num2str(val*modifier)
		break
		case "VRightMargin":
			ModifyGraph/W=$gName margin(right) = val*modifier
			cmd = "margin(right)="+num2str(val*modifier)
		break
		case "VTopMargin":
			ModifyGraph/W=$gName margin(top) = val*modifier
			cmd = "margin(top)="+num2str(val*modifier)
		break
		case "VGraphHeight":
			ControlInfo/W=$pName VTopMargin
			Variable mTop = V_Value
			ControlInfo/W=$pName VBottomMargin
			Variable mBot = V_Value
			Variable pHeight = val-mTop-mBot
			if (val == 0)
				ModifyGraph/W=$gName margin(top) = 0, margin(bottom) = 0,  height = 0
				cmd = "margin(top)=0, margin(bottom)=0,  height=0"
			elseif (pHeight > 0)
				ModifyGraph/W=$gName height = pHeight*modifier
				cmd = "height="+num2str(pHeight*modifier)
			endif
		break
		case "VGraphWidth":
			ControlInfo/W=$pName VLeftMargin
			Variable mLeft = V_Value
			ControlInfo/W=$pName VRightMargin
			Variable mRight = V_Value
			Variable pWidth = val-mLeft-mRight
			if (val == 0)
				ModifyGraph/W=$gName margin(left) = 0, margin(right) = 0,  width = 0
				cmd = "margin(left)=0, margin(right)=0,  width=0"
			elseif (pWidth > 0)
				ModifyGraph/W=$gName width = pWidth*modifier
				cmd = "width="+num2str(pWidth*modifier)
			endif
		break
		case "VPlotHeight":
			ModifyGraph/W=$gName height = val*modifier
			cmd = "height="+num2str(val*modifier)
		break
		case "VPlotWidth":
			ModifyGraph/W=$gName width = val*modifier
			cmd = "width="+num2str(val*modifier)
		break
		case "VMagnification":
			Variable Mag = val == 1 ? 0 : val	// reset to none
			ModifyGraph/W=$gName expand = Mag
			cmd = "expand="+num2str(Mag)
		break
		case "VGraphFont":
			if ((GetKeyState(0) & 2^2) != 0)	// shift pressed
				ModifyGraph/W=$gName fSize = val
				cmd = "fSize="+num2str(val)
			else
				ModifyGraph/W=$gName gfSize = val
				cmd = "gfSize="+num2str(val)
			endif
		break
		case "tlAxis_left":
			ModifyGraph/W=$gName tlOffset(left) = val
			cmd = "tlOffset(left)="+num2str(val)
		break
		case "tlAxis_bottom":
			ModifyGraph/W=$gName tlOffset(bottom) = val
			cmd = "tlOffset(bottom)="+num2str(val)
		break
		case "tlAxis_right":
			ModifyGraph/W=$gName tlOffset(right) = val
			cmd = "tlOffset(right)="+num2str(val)
		break
		case "tlAxis_top":
			ModifyGraph/W=$gName tlOffset(top) = val
			cmd = "tlOffset(top)="+num2str(val)
		break
		case "alAxis_left":
			ModifyGraph/W=$gName lblMargin(left) = val
			cmd = "lblMargin(left)="+num2str(val)
		break
		case "alAxis_bottom":
			ModifyGraph/W=$gName lblMargin(bottom) = val
			cmd = "lblMargin(bottom)="+num2str(val)
		break
		case "alAxis_right":
			ModifyGraph/W=$gName lblMargin(right) = val
			cmd = "lblMargin(right)="+num2str(val)
		break
		case "alAxis_top":
			ModifyGraph/W=$gName lblMargin(top) = val
			cmd = "lblMargin(top)="+num2str(val)
		break
	EndSwitch
	
	if (printcmd)
		print "•ModifyGraph "+cmd
	endif
	
	if (Auto)
		DoUpdate/W=$gName
		if (StringMatch(ctrlName,"*Height"))
			ModifyGraph/W=$gName height = 0
		elseif (StringMatch(ctrlName,"*Width"))
			ModifyGraph/W=$gName width = 0
		endif
	endif
	FetchLatestGraphSizeValues()
	return 0
end

//################################################################################################

Function Gsize_PresetPopup(s) : PopupMenuControl
	STRUCT WMPopupAction &s
	if (s.eventCode == 2)
		StrSwitch(s.ctrlName)
			case "AspectSelect":
				ChangeAspectRatio(s.popStr)
			break
			case "FormatSelect":
				ChangeGraphFormat(s.popStr)
			break
			case "SizeUnit":
				String CtrlList = RemoveFromList("VMagnification;VGraphFont;",ControlNameList(s.win,";","V*"))
				Variable div  = s.popNum == 1 ? 1 : (s.popNum == 2 ? 72 : 72/2.54)				// in points, inches or cm
				Variable step = s.popNum == 1 ? 1 : (s.popNum == 2 ? 0.014 : 0.036)
				ModifyControlList CtrlList ,win=$(s.win) ,limits={0,8000/div,step*2}			// official max size is 8000 points
				Variable/G root:$ksGraphSizeUnitSave = s.popNum									// save settings into global variable
				FetchLatestGraphSizeValues()
			break
		EndSwitch
	endif
	return 0
End
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
static Function ChangeAspectRatio(which)
	String which
	String gName = getTopGraph()
	if (!strlen(gName))
		return 0
	endif
	String HeightMode = ""
	StrSwitch (which)
		case "Free":
			HeightMode = "0"
		break
		case "1:1":
			HeightMode = "{Aspect,1}"
		break
		case "4:3":
			HeightMode = "{Aspect,3/4}"
		break
		case "3:2":
			HeightMode = "{Aspect,2/3}"
		break
		case "16:9":
			HeightMode = "{Aspect,9/16}"
		break
		case "2:3":
			HeightMode = "{Aspect,3/2}"
		break
		case "3:4":
			HeightMode = "{Aspect,4/3}"
		break
		case "4:5":
			HeightMode = "{Aspect,5/4}"
		break
	EndSwitch
	if (strlen(HeightMode) > 0)
		Execute/Q "ModifyGraph/Z/W="+gName+" height="+HeightMode+";FetchLatestGraphSizeValues();"
		ControlInfo/W=GraphSizePanel cPrint
		if (V_Value && V_flag == 2 && CmpStr(HeightMode,"0") != 0)
			print "•ModifyGraph height="+HeightMode
		endif
	endif

	return 0
End
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
static Function ChangeGraphFormat(which)
	String which
	String gName = getTopGraph()
	if (!strlen(gName))
		return 0
	endif
	PopupMenu AspectSelect	,win=GraphSizePanel	,popMatch="Free"								// reset aspect popup
	if (StringMatch(which,"Free Size"))
		ModifyGraph/W=$gName/Z width=0, height=0, margin=0
		ModifyGraph/W=$gName/Z gfSize=0, fSize=0, lsize=1
		ModifyGraph/W=$gName/Z expand=0
		FetchLatestGraphSizeValues()
		return 0
	endif
	
	ControlInfo/W=GraphSizePanel KeepAutoMode
	Variable Auto = V_Value
	GetAxis/W=$gName/Q bottom																	// check which axes are active (increases the margin here)
	Variable bottomOn = !V_Flag
	GetAxis/W=$gName/Q left
	Variable leftOn = !V_Flag
	GetAxis/W=$gName/Q right
	Variable rightOn = !V_Flag
	GetAxis/W=$gName/Q top
	Variable topOn = !V_Flag
	
	if (StringMatch(which, "Paper*")) 
		ModifyGraph/W=$gName/Z gfSize=8, fSize=8
		ModifyGraph/W=$gName/Z expand=1.25
		ModifyGraph/W=$gName/Z lsize=1.5
		
		ModifyGraph/W=$gName/Z margin(left)	= (11 + 22*leftOn + 10*(bottomOn || topOn && !leftOn))
		ModifyGraph/W=$gName/Z margin(bottom)= (11 + 22*bottomOn)
		ModifyGraph/W=$gName/Z margin(top)	= (11 + 22*topOn)
		ModifyGraph/W=$gName/Z margin(right)	= (11 + 22*rightOn + 10*(bottomOn || topOn && !rightOn))
		if (StringMatch(which, "*Half"))
			ModifyGraph/W=$gName/Z width=(180 - 12*(leftOn && rightOn))
			ModifyGraph/W=$gName/Z height=(172 - 22*(bottomOn && topOn))
		elseif (StringMatch(which, "*Full"))
			ModifyGraph/W=$gName/Z width=(450 - 12*(leftOn && rightOn))
			ModifyGraph/W=$gName/Z height=(208 - 22*(bottomOn && topOn))
		endif
	endif
	
	if (StringMatch(which, "PPT*")) 
		ModifyGraph/W=$gName/Z gfSize=16, fSize=12
		ModifyGraph/W=$gName/Z expand=0.75
		ModifyGraph/W=$gName/Z lsize=1.5

		ModifyGraph/W=$gName/Z margin(left)		= (18 + 37*leftOn + 12*(bottomOn || topOn && !leftOn))
		ModifyGraph/W=$gName/Z margin(bottom)	= (18 + 37*bottomOn)
		ModifyGraph/W=$gName/Z margin(top)		= (18 + 37*topOn)
		ModifyGraph/W=$gName/Z margin(right)	= (18 + 37*rightOn + 12*(bottomOn || topOn && !rightOn))
		if (StringMatch(which, "*16:9*"))
			ModifyGraph/W=$gName/Z height=(360 - 37*(bottomOn && topOn))
			if (StringMatch(which, "*Half"))
				ModifyGraph/W=$gName/Z width=(380 - 25*(leftOn && rightOn))
			elseif (StringMatch(which, "*Full"))
				ModifyGraph/W=$gName/Z width=(800 - 25*(leftOn && rightOn))
			endif
		elseif (StringMatch(which, "*4:3*"))
			ModifyGraph/W=$gName/Z height=(350 - 37*(bottomOn && topOn))
			if (StringMatch(which, "*Half"))
				ModifyGraph/W=$gName/Z width=(290 - 25*(leftOn && rightOn))
			elseif (StringMatch(which, "*Full"))
				ModifyGraph/W=$gName/Z width=(600 - 25*(leftOn && rightOn))
			endif
		endif
	endif

	DoUpdate
	if (Auto)
		ModifyGraph/W=$gName/Z height = 0
		ModifyGraph/W=$gName/Z width = 0
	endif
	FetchLatestGraphSizeValues()
	return 0
End

//################################################################################################

Function FetchLatestGraphSizeValues()
	String gName = getTopGraph(), gRec = ""
	String pName = "GraphSizePanel"
	if (!strlen(gName))
		DoWindow /T $pName, "Set Graph Size: No Graph"
		return 0
	endif
	
	DoUpdate/W=$gName
	GetWindow $gName gsize																		// values from GetWindow (sometimes off by a fraction?)
	//print V_left, V_right, V_top, V_bottom		// debug
  	Variable gLeft	= V_left
  	Variable gRight	= V_right
  	Variable gTop	= V_top
	Variable gBottom= V_bottom
  	Variable gWidth	= V_right-V_left	
  	Variable gHeight= V_bottom-V_top	
	GetWindow $gName psize
	//print V_left, V_right, V_top, V_bottom		// debug
	Variable mLeft	= round(V_left - gLeft)
	Variable mTop	= round(V_top - gTop)
	Variable mRight	= round(gRight - V_right)
	Variable mBottom= round(gBottom - V_bottom)
	Variable pWidth	= round(V_right - V_left)
	Variable pHeight= round(V_bottom - V_top)
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	gRec = GrepList(WinRecreation(gName, 0), "^\t(ModifyGraph)", 0 , "\r")						// if available, replace with values from recreation macro (these are exact)
	gRec = GrepList(gRec, "(?i)(height|width|margin|gfsize|swapXY)", 0 , "\r")					// extract only relevant keys
	gRec = ReplaceString("\tModifyGraph ",gRec,"")
	gRec = ReplaceString("\r",gRec,",")

	Variable gSwap = str2num(StringByKey("swapXY", gRec, "=", ","))								// swap axes parameter
	Variable gMagn = abs(str2num(StringByKey("expand", gRec, "=", ",")))						// magnification parameter
	gSwap = numtype(gSwap) == 0 ? gSwap : 0
	gMagn = numtype(gMagn) == 0 ? gMagn : 1
	Variable Rec_mLeft	 = gSwap ? str2num(StringByKey("margin(bottom)", gRec, "=", ",")): str2num(StringByKey("margin(left)", gRec, "=", ","))
	Variable Rec_mTop	 = gSwap ? str2num(StringByKey("margin(right)", gRec, "=", ",")) : str2num(StringByKey("margin(top)", gRec, "=", ","))
	Variable Rec_mRight	 = gSwap ? str2num(StringByKey("margin(top)", gRec, "=", ","))	 : str2num(StringByKey("margin(right)", gRec, "=", ","))
	Variable Rec_mBottom = gSwap ? str2num(StringByKey("margin(left)", gRec, "=", ","))	 : str2num(StringByKey("margin(bottom)", gRec, "=", ","))
	Variable Rec_pWidth	 = gSwap ? str2num(StringByKey("height", gRec, "=", ","))		 : str2num(StringByKey("width", gRec, "=", ","))
	Variable Rec_pHeight = gSwap ? str2num(StringByKey("width", gRec, "=", ","))		 : str2num(StringByKey("height", gRec, "=", ","))
	Variable Rec_gHeight = Rec_pHeight + Rec_mBottom + Rec_mTop
	Variable Rec_gWidth	 = Rec_pWidth  + Rec_mRight  + Rec_mLeft
	Variable Rec_gFont	 = str2num(StringByKey("gfSize", gRec, "=", ","))
	Variable gFont = numtype(Rec_gFont) == 0 ? Rec_gFont : 10
#if IgorVersion() >= 7.00
	GetWindow $gName expand																		// fetch magnification in newer Igor versions
	gMagn = V_Value == 0 ? 1 : V_Value
#endif
	// ++++++++++++++++++++++++++++++++ get aspect ratio info ++++++++++++++++++++++++++++++++++++
	gRec = StringFromList(1, ReplaceString("{", ReplaceString("}",StringByKey(SelectString(gSwap, "height", "width"), gRec, "="),""),""), ",")	// extract aspect ratio
	String PopList = "free;1:1;4:3;3:2;16:9;2:3;3:4;4:5"										// popup match list
	Variable sel = 0																			// extract aspect ratio
	sel += 1 * StringMatch(gRec,"1")
	sel += 2 * StringMatch(gRec,"0.75")
	sel += 3 * StringMatch(gRec,"0.666667")
	sel += 4 * StringMatch(gRec,"0.5625")
	sel += 5 * StringMatch(gRec,"1.5")
	sel += 6 * StringMatch(gRec,"1.33333")
	sel += 7 * StringMatch(gRec,"1.25")
	// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	mLeft	= numtype(Rec_mLeft) == 0 ? Rec_mLeft : mLeft										// if the recreation values are valid then use these
	mBottom	= numtype(Rec_mBottom) == 0 ? Rec_mBottom : mBottom
	mRight	= numtype(Rec_mRight) == 0 ? Rec_mRight : mRight
	mTop	= numtype(Rec_mTop) == 0 ? Rec_mTop : mTop
	pWidth	= numtype(Rec_pWidth) == 0 ? Rec_pWidth : pWidth
	pHeight	= numtype(Rec_pHeight) == 0 ? Rec_pHeight : pHeight
	gHeight	= numtype(Rec_gHeight) == 0 ? Rec_gHeight : pHeight + mTop + mBottom
	gWidth	= numtype(Rec_gWidth) == 0 ? Rec_gWidth : pWidth + mLeft + mRight
	
	ControlInfo/W=$pName SizeUnit
	Variable modifier = V_Value == 1 ? 1 : (V_Value == 2 ? 72 : 72/2.54)						// in points, inches or cm
	if (modifier != 1)
		mLeft	= round((mLeft	 /modifier)*1000)/1000
		mBottom	= round((mBottom /modifier)*1000)/1000
		mRight	= round((mRight	 /modifier)*1000)/1000
		mTop	= round((mTop	 /modifier)*1000)/1000
		gHeight	= round((gHeight /modifier)*1000)/1000
		pWidth	= round((pWidth	 /modifier)*1000)/1000
		gWidth	= round((gWidth	 /modifier)*1000)/1000
		pHeight	= round((pHeight /modifier)*1000)/1000
	endif
	// +++++++++++++++++++++++++++++++ apply info to panel controls ++++++++++++++++++++++++++++++
	String undoGName = GetUserData(pName, "", "LastgName")										// check for existence of a undo style for the current graph
	DoWindow /T $pName, "Set Graph Size: " + gName
	CheckBox SwapAxes			,win=$pName	,value=gSwap
	SetVariable VLeftMargin		,win=$pName	,value=_NUM:mLeft	,fstyle=(numtype(Rec_mLeft)==0)
	SetVariable VBottomMargin	,win=$pName	,value=_NUM:mBottom	,fstyle=(numtype(Rec_mBottom)==0)
	SetVariable VRightMargin	,win=$pName	,value=_NUM:mRight	,fstyle=(numtype(Rec_mRight)==0)
	SetVariable VTopMargin		,win=$pName	,value=_NUM:mTop	,fstyle=(numtype(Rec_mTop)==0)
	SetVariable VGraphHeight	,win=$pName	,value=_NUM:gHeight	,fstyle=(numtype(Rec_gHeight)==0)
	SetVariable VPlotWidth		,win=$pName	,value=_NUM:pWidth	,fstyle=(numtype(Rec_pWidth)==0)
	SetVariable VGraphWidth		,win=$pName	,value=_NUM:gWidth	,fstyle=(numtype(Rec_gWidth)==0)
	SetVariable VPlotHeight		,win=$pName	,value=_NUM:pHeight	,fstyle=(numtype(Rec_pHeight)==0)
	SetVariable VGraphFont		,win=$pName	,value=_NUM:gFont	,fstyle=(numtype(Rec_gFont)==0)
	SetVariable VMagnification	,win=$pName	,value=_NUM:gMagn
	PopupMenu AspectSelect		,win=$pName	,popMatch=StringFromList(sel,PopList)
	Button RevertButton			,win=$pName	,disable=2*(!StringMatch(gName,undoGName))			// disable button if undo backup does not match to current graph
	
	Variable i
	String axes = "left;bottom;right;top;"
	for (i = 0; i < ItemsInList(axes); i += 1)													// set axis checkboxes
		Variable isOn = 0, tickOffset = 0, lblOffset = 0
		String currAxis = StringFromList(i,axes)
		gRec = AxisInfo(gName,currAxis)
		if (strlen(gRec))
			isOn = (str2num(StringByKey("tick(x)",gRec,"=",";"))!=3 && str2num(StringByKey("noLabel(x)",gRec,"=",";"))!= 2)		// inactive if both tick(x)=3 and noLabel(x)=2
			tickOffset = str2num(StringByKey("tlOffset(x)",gRec,"=",";"))
			lblOffset  = str2num(StringByKey("lblMargin(x)",gRec,"=",";"))
		endif
		CheckBox $("cAxis_"+currAxis) ,win=$pName ,value=isOn ,disable=2*(strlen(gRec)==0)
		ControlInfo/W=$pName $("tlAxis_"+currAxis)
		if (abs(V_Flag) == 5)
			SetVariable $("tlAxis_"+currAxis) ,win=$pName ,value=_NUM:tickOffset ,disable=2*(strlen(gRec)==0)
		endif
		ControlInfo/W=$pName $("alAxis_"+currAxis)
		if (abs(V_Flag) == 5)
			SetVariable $("alAxis_"+currAxis) ,win=$pName ,value=_NUM:lblOffset ,disable=2*(strlen(gRec)==0)
		endif
	endfor
	return 0
End

//________________________________________________________________________________________________
//	attaches a quick-scaling menu to the top graph
//	version 4 -  2022/03
//________________________________________________________________________________________________

Function AttachQuickScalePanel()
	String win=getTopMainGraph()
	if (strlen(win) == 0)
		return 0
	endif
	GetWindow $win hook(MainWindow)
	if (StringMatch(S_Value, "QuickScale_GraphHook"))
		return 0
	endif
	SetWindow $win hook(MainWindow)=QuickScale_GraphHook, hookevents = 4
	ShowInfo
	
	//++++++++++++++++++++++++++++++ build the panel ++++++++++++++++++++++++++++++++	
	String pPath = win+"#QuickScalePanel"
	NewPanel/HOST=$win/N=QuickScalePanel/EXT=0/W=(0,0,108,452) as "Norm & Scale"
	TitleBox tCursor		,pos={10,10}	,size={90,23}	,title="No Cursor"			,frame=0 	,fstyle=1	,userdata="none"
	Button bAddCursor		,pos={78,8}		,size={20,20}	,title="+"					,help={"Adds a new cursor to the graph."}
	Button bTracePrev		,pos={8,33}		,size={40,20}	,title="Prev"				,help={"Set cursor to previous trace in list."}
	Button bTraceNext		,pos={58,33}	,size={40,20}	,title="Next"				,help={"Set cursor to next trace in list."}
	TitleBox tFindPos		,pos={10,60}	,size={90,23}	,title="Place Cursor at:"	,frame=0
	Button bFindMin			,pos={8,80}		,size={40,20}	,title="Min"				,help={"Find the minimum data value."}
	Button bFindMax			,pos={58,80}	,size={40,20}	,title="Max"				,help={"Find the maximum data value."}
	DrawLine 8, 110, 98 ,110
	TitleBox tNormalize		,pos={10,118}	,size={90,23}	,title="Normalize to:"		,frame=0
	SetVariable vNormalize	,pos={8,138}	,size={90,23}	,title=""					,help={"Normalizes the spectrum to this value at cursor position."}
	Button bNormBack		,pos={8,163}	,size={90,20}	,title="Revert Norm."		,help={"Undoes the previous normalization."}
	DrawLine 8, 192, 98 ,192
	CheckBox cImageYShift	,pos={52,200}	,size={35,23}	,title="do Y:"				,fColor=(0,0,65280)
	TitleBox tShift			,pos={10,200}	,size={90,23}	,title="X pos:"				,frame=0
	SetVariable vShift		,pos={8,220}	,size={90,23}	,title=""					,help={"Offsets the selected axis so that the cursor will be at this value."}
	TitleBox tRelShift		,pos={10,245}	,size={90,23}	,title="Relative X shift:"	,frame=0	
	SetVariable vRelShift	,pos={8,265}	,size={90,23}	,title=""					,help={"Offsets the selected axis by this relative value."}
	DrawLine 8, 294, 98 ,294
	TitleBox tPhoton		,pos={10,300}	,size={90,23}	,title="Photon Energy"		,frame=0
	SetVariable vPhoton		,pos={8,320}	,size={90,23}	,title=""					,help={"Set the photon energy."}
	Button bSwitch			,pos={8,345}	,size={90,20}	,title="KE <> BE"			,help={"Switch between kinetic and binding energy using the set photon energy."}
	DrawLine 8, 374, 98 ,374
	TitleBox tArithmetic	,pos={10,380}	,size={90,23}	,title="Arithmetic Op.:"	,frame=0
	SetVariable vArithmetic	,pos={8,400}	,size={90,23}	,title=""					,help={"Multiply, divide, add, subtract a value by/to/from the data by this command just like in the command line."}
	CheckBox cImageOneCol	,pos={9,423}	,size={90,23}	,title="One Column"			,help={"Applies arithmetic operation to the selected column only instead of the full image."}	,value=1
	//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	ModifyControlList ControlNameList(pPath,";","b*")		,proc=QuickRescale_ButtonExecute
	ModifyControlList ControlNameList(pPath,";","v*")		,proc=QuickRescale_VariableExecute
	SetVariable vShift		,value=_NUM:0	,limits={-inf,inf,1}	,format="%g"
	SetVariable vNormalize	,value=_NUM:0	,limits={-inf,inf,1}					,userdata(reset)="0"	,userdata(wavname)="none"
	SetVariable vRelShift	,value=_NUM:0	,limits={-inf,inf,1}	,format="%g"	,userdata(offset)="0"	,userdata(wavname)="none"
	SetVariable vPhoton		,value=_NUM:0	,limits={0,inf,0}		,format="%g"
	SetVariable vArithmetic	,value=_STR:""
	ModifyControlList ControlNameList(pPath,";","!bAddCursor") disable = 2						// disable everything for now (other than the add cursor button)
	CheckBox cImageYShift	,side=1			,disable=1		,proc=QuickRescale_CheckExecute	
	
	if (CmpStr(IgorInfo(2), "Macintosh") == 0)
		ModifyControlList ControlNameList(pPath,";","*")	,win=$pPath	,fsize=10
	endif
	
	SetWindow $(pPath) hook(SubWindow)=QuickScale_PanelHook										// set an additional hook to handle close events
	SetActiveSubwindow $win																		// restore focus to main window
	
	Variable i
	String csr = "", csrList = "A;B;C;D;E;F;G;H;I;J;"
	for (i = 0; i < ItemsInList(csrList); i += 1)												// see if a cursor is set already
		csr = StringFromList(i,csrList)
		if (strlen(CsrInfo($csr,win)))
			String trace = StringByKey("TNAME",CsrInfo($csr,win))
			if (strlen(ImageInfo(win,trace,0)))													// update the cursor (recalculates the control values)
				Cursor/I/P $csr, $trace, pcsr($csr,win), qcsr($csr,win)							// move cursor to image position
			else
				Cursor/P $csr, $trace, pcsr($csr,win)											// move cursor to trace position
			endif
			break
		endif
	endfor
	
	return 0
End

//################################################################################################

Function QuickScale_GraphHook(s)
	STRUCT WMWinHookStruct &s
	String pPath = s.WinName+"#QuickScalePanel"
	
	Variable i, HookTakeover = 0
	Switch(s.eventCode)
		case 8:		// modified => if trace gets added or removed
		case 7:		// cursor moved
			if (WinType(pPath) != 7)															// something went wrong, since there is no panel => remove hook
				SetWindow $s.WinName hook(MainWindow)=$""
				return 0
			endif
			String csr = s.CursorName, trace = s.TraceName, csrList = "A;B;C;D;E;F;G;H;I;J;"
			if (!strLen(trace))																	// if the trace is not assigned, look for other cursors
				for (i = 0; i < ItemsInList(csrList); i += 1)
					csr = StringFromList(i,csrList)
					if (strlen(CsrInfo($csr,s.WinName)))
						trace = StringByKey("TNAME",CsrInfo($csr,s.WinName))
						break
					endif
				endfor
			endif
			
			if (!strLen(trace))																	// still not trace? => abort
				TitleBox tCursor ,win=$pPath ,title="No Cursor" ,userdata="none"
				ModifyControlList ControlNameList(pPath,";","!bAddCursor") ,win=$pPath ,disable = 2		// disable everything other than the add cursor button
				CheckBox cImageYShift ,win=$pPath	,disable=1
				return 0
			endif
			HookTakeover = 1
			
			Wave inwave  = CsrWaveRef($csr,s.WinName)
			Wave/Z xwave = CsrXWaveRef($csr,s.WinName)
			
			String wName = NameOfWave(inwave)
			String imgInfo = ImageInfo(s.WinName,s.TraceName,0)
			Variable isImage = strlen(imgInfo)

			ModifyControlList ControlNameList(pPath,";","*")		,win=$pPath ,disable = 0			// re-enable everything
			ModifyControlList ControlNameList(pPath,";","bTrace*")	,win=$pPath ,disable = 2*isImage	// disable trace controls for an image
			
			String hUnit, wUnit = WaveUnits(inwave,0), wOffsets
			Variable hv = abs(TraceTool_FetchXShift(inwave, hUnit));	hv = numtype(hv) ? 0 : hv
			Variable xOff = DimOffset(inwave,0), yOff = DimOffset(inwave,1), xDelta = DimDelta(inwave,0), yDelta = DimDelta(inwave,1)
			if (isImage)
				Wave/Z imgXW = $(StringByKey("XWAVEDF",imgInfo)+StringByKey("XWAVE",imgInfo))
				Wave/Z imgYW = $(StringByKey("YWAVEDF",imgInfo)+StringByKey("YWAVE",imgInfo))
				if (WaveExists(imgXW))
					xOff = imgXW[0]
					xDelta = (imgXW[DimSize(imgXW,0)-1] - imgXW[0])/(DimSize(imgXW,0)-1)
				endif
				if (WaveExists(imgYW))
					yOff = imgYW[0]
					yDelta = (imgYW[DimSize(imgYW,0)-1] - imgYW[0])/(DimSize(imgYW,0)-1)
				endif
			elseif(WaveExists(xwave))
				xOff = xwave[0]
				xDelta = (xwave[DimSize(xwave,0)-1] - xwave[0])/(DimSize(xwave,0)-1)
			endif
			sprintf wOffsets, "%f;%f;", xOff, yOff
			
			ControlInfo/W=$pPath cImageYShift
			Variable useY = V_Value && isImage
			Variable curPos = useY ? vcsr($csr, s.WinName) : hcsr($csr, s.WinName)
			Variable height = isImage ? zcsr($csr, s.WinName) : vcsr($csr, s.WinName)
			
			String offsetWave = GetUserData(pPath, "vRelShift",  "wavname")
			String renormWave = GetUserData(pPath, "vNormalize", "wavname")
			Variable startOff = str2num(StringFromList(useY,GetUserData(pPath, "vRelShift", "offset")))
			
			TitleBox tShift			,win=$pPath	,title=SelectString(useY,"X pos:","Y pos:")
			TitleBox tRelShift		,win=$pPath	,title=SelectString(useY,"Relative X shift:","Relative Y shift:")
			CheckBox cImageYShift 	,win=$pPath	,disable=!isImage
			CheckBox cImageOneCol	,win=$pPath	,disable=!(WaveDims(inwave)==2)*2
			TitleBox tCursor		,win=$pPath	,title="Cursor "+csr	,userdata=csr									// the cursor position will be saved into the variable control
			SetVariable vShift		,win=$pPath	,value=_NUM:curPos		,limits={-inf,inf,(useY ? yDelta : xDelta)} ,format="%g "+wUnit
			SetVariable vNormalize	,win=$pPath	,value=_NUM:height		,limits={-inf,inf,height/10}
			if(!StringMatch(wName,renormWave))																			// check if the current and the last waves are the same
				SetVariable vNormalize	,win=$pPath	,userdata(reset)="0" ,userdata(wavname)=wName						// if not, switch over to the new wave
			endif
			if(StringMatch(wName,offsetWave))																			// check if the current and the last waves are the same
				SetVariable vRelShift	,win=$pPath	,value=_NUM:(round(((useY ? yOff : xOff)-startOff)*10000)/10000)	// set control to the updated value
			else
				SetVariable vRelShift	,win=$pPath	,value=_NUM:0 ,limits={-inf,inf,(useY ? yDelta : xDelta)} ,userdata(wavname)=wName ,userdata(offset)=wOffsets ,format="%g "+wUnit
			endif
			if (hv != 0)
				SetVariable vPhoton		,win=$pPath	,value=_NUM:hv ,format="%g "+hUnit
			endif
		break
	EndSwitch
	return HookTakeover
End
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Function QuickScale_PanelHook(s)
	STRUCT WMWinHookStruct &s
	if (s.eventCode == 17)	// kill
		String gName = StringFromList(0, s.WinName, "#")
		HideInfo/W=$gName
		SetWindow $gName hook(MainWindow)=$""													// remove hook from main window
	endif
	return 0
End

//################################################################################################

Function QuickRescale_ButtonExecute(s) : ButtonControl
	STRUCT WMButtonAction &s
	if (s.eventCode != 2)
		return 0
	endif
	
	String gName = StringFromList(0, s.win, "#")
	String csr = GetUserData(s.win, "tCursor", "")
	String traceList = "", trace = ""
	Variable Findx = 0, Findy = 0
	Variable items = FetchTraces(gName,traceList,0)
	
	if (CmpStr(csr,"none") != 0 && strlen(csr))
		Wave yw = CsrWaveRef($csr,gName)
		Wave/Z xw = CsrXWaveRef($csr,gName)
		trace = StringByKey("TNAME",CsrInfo($csr,gName))
		Findx = pcsr($csr,gName)
		Findy = qcsr($csr,gName)
	endif
	if (!strlen(trace) && CmpStr(s.ctrlName,"bAddCursor") != 0)
		s.ctrlName = ""
	endif
	
	Variable i, GoUp = 0, xOff = 0, yOff = 0, xScale = 0, yScale = 0
	StrSwitch(s.ctrlName)
		case "bFindMax":
			WaveStats/Q yw
			Findx = V_maxRowLoc
			Findy = V_maxColLoc
		break
		case "bFindMin":
			WaveStats/Q yw
			Findx = V_minRowLoc
			Findy = V_minColLoc
		break
		case "bSwitch":
			ControlInfo/W=$(s.win) vPhoton
			Variable start = DimOffset(yw,0)
			if (WaveExists(xw))
				start = xw[0]
			endif
			
			Variable hv = V_Value, skip = 0			
			if (numtype(hv) == 0 && hv > 0)
				#if (Exists("QuickRescale_UserFunc") == 6)										// uses user code for photon energy handling
					skip = QuickRescale_UserFunc(yw, xw, hv)
				#endif
				if (skip)
					break
				endif
				//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
				String notes = GetUserData(s.win, "vRelShift", "offset")						// get the initial x offset
				hv = start < 0 ? hv : -hv														// decide the direction
				if ((start+hv)*start <= 0)
					if (WaveExists(xw))
						xw += hv
					else
						SetScale/P x start+hv, DimDelta(yw,0), WaveUnits(yw,0), yw
					endif
					sprintf notes, "%f;%s;",str2num(StringFromList(0,notes))+hv, StringFromList(1,notes)	// write new offset
					SetVariable vRelShift ,win=$(s.win) ,userdata(offset)=notes					// set new offset
				else
					Print "Photon energy is too small."
				endif
			else
				Print "Photon energy needs to be a positive number."
			endif
		break
		case "bNormBack":
			Variable oldMax = str2num(GetUserData(s.win, "vNormalize", "reset")), newMax = Wavemax(yw)
			if (oldMax != 0 && numtype(oldMax) == 0)
				yw *= oldMax/newMax																// normalize the wave
				SetVariable vNormalize ,win=$(s.win) ,userdata(reset)="0"
			endif
		break
		case "bAddCursor":
			String csrList = "A;B;C;D;E;F;G;H;I;J;"
			for (i = 0; i < ItemsInList(csrList); i += 1)										// find first unused cursor
				csr = StringFromList(i,csrList)
				if (!strlen(CsrInfo($csr,gName)))
					break
				endif
			endfor
			
			if (!items)																			// if there are no traces, then this must be an image
				trace = StringFromList(0,ImageNameList(gName, ";"))
				Wave yw = ImageNameToWaveRef(gName,trace)
			else
				trace = StringFromList(0,traceList)
				Wave yw = TraceNameToWaveRef(gName,trace)
				Wave/Z xw = XWaveRefFromTrace(gName,trace)										// xw is only needed for traces
			endif
			
			Findx = DimSize(yw,0)/2																// set a new cursor on the center of the first trace or image
			if (!items)
				Findy = DimSize(yw,1)/2
			else
				GetAxis/W=$gName/Q bottom
				if (!V_flag)
					getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)				// center of the current axis corrected for scaling and offset of the current trace
					if (WaveExists(xw))
						FindLevel/P/Q xw, (V_min+(V_max-V_min)/2 - xOff)/xScale
						Findx = (!v_flag && v_levelX > 0 && v_levelX < DimSize(xw,0)-1) ? v_levelX : round(DimSize(xw,0)/2)		// make sure to stay within range
					else
						Findx = x2pnt(yw,(V_min+(V_max-V_min)/2 - xOff)/xScale)
					endif
				endif
			endif
		break
		case "bTraceNext":
			GoUp = 1
		case "bTracePrev":
			if (strlen(ImageInfo(gName,trace,0)))
				break
			endif
			getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)
			Findx = hcsr($csr, gName)*xScale + xOff												// correct for current trace's offsets	
			
			Variable curTrace = WhichListItem(trace, traceList)
			if (GoUp)
				if (curTrace < items-1)
					 trace = StringFromList(curTrace+1,traceList)
				endif
			else
				if (curTrace > 0)
					 trace = StringFromList(curTrace-1,traceList)
				endif
			endif
			Wave yw = TraceNameToWaveRef(gName, trace)
			Wave/Z xw = XWaveRefFromTrace(gName,trace)
			
			getAllTraceOffsets(gName, trace, xOff, yOff, xScale, yScale)						// correct for next trace's offsets
			if (WaveExists(xw))
				FindLevel/P/Q xw, (Findx - xOff)/xScale
				Findx = (!v_flag && v_levelX > 0 && v_levelX < DimSize(xw,0)-1) ? v_levelX : round(DimSize(xw,0)/2)			// make sure to stay within range
			else
				Findx = x2pnt(yw,(Findx - xOff)/xScale)
			endif
		break
	EndSwitch

	if (strlen(ImageInfo(gName,trace,0)))
		Cursor/P/I $csr, $trace, Findx, Findy													// move cursor to image position
	else
		Cursor/P $csr, $trace, Findx															// move cursor to trace position
	endif
	SetActiveSubwindow $gName																	// restore focus to main window
	return 0
End

//################################################################################################

Function QuickRescale_VariableExecute(s) : SetVariableControl
	STRUCT WMSetVariableAction &s
	if (!(s.eventCode == 1 || s.eventCode == 2))
		return 0
	endif
	
	String varStr = s.sval
	String gName = StringFromList(0, s.win, "#")
	String csr = GetUserData(s.win, "tCursor", "")
	if (CmpStr(csr,"none") == 0 || !strlen(csr))
		return 0
	endif
	Wave yw = CsrWaveRef($csr, gName)
	Wave/Z xw = CsrXWaveRef($csr,gName)
	String trace = StringByKey("TNAME",CsrInfo($csr,gName))
	String imgInfo = ImageInfo(gName,trace,0)
	
	ControlInfo/W=$(s.win) cImageYShift
	Variable useY = V_Value && !V_disable, modVal, iniVal
	if (strlen(imgInfo))																		// the xw is used for shifts
		if (useY)
			Wave/Z xw = $(StringByKey("YWAVEDF",imgInfo)+StringByKey("YWAVE",imgInfo))
		else
			Wave/Z xw = $(StringByKey("XWAVEDF",imgInfo)+StringByKey("XWAVE",imgInfo))
		endif
	endif
	
	StrSwitch(s.ctrlName)
		case "vNormalize":
			modVal = strlen(ImageInfo(gName,trace,0)) ? zcsr($csr,gName)/s.dval : vcsr($csr,gName)/s.dval	// get the 1D y-value or 2D z-value of the cursor
			iniVal = str2num(StringFromList(useY,GetUserData(s.win, "vNormalize", "reset")))
			if (modVal != 0 && numtype(modVal) == 0)
				if (iniVal == 0)
					SetVariable vNormalize ,win=$(s.win) ,userdata(reset)=num2str(Wavemax(yw))				// the original height will be saved into the variable control
				endif
				yw /= modVal
			endif
		break
		case "vShift":
			modVal = useY ? vcsr($csr,gName) : hcsr($csr,gName)
			if (WaveExists(xw))
				xw -= (modVal-s.dval)
				break
			endif
			if (useY)
				SetScale/P y, DimOffset(yw,1)-(modVal-s.dval), DimDelta(yw,1), WaveUnits(yw,1), yw			// scale relative to cursor position in y direction
			else
				SetScale/P x, DimOffset(yw,0)-(modVal-s.dval), DimDelta(yw,0), WaveUnits(yw,0), yw			// scale relative to cursor position in x direction
			endif
		break
		case "vRelShift":
			iniVal = str2num(StringFromList(useY,GetUserData(s.win, "vRelShift", "offset")))
			if (WaveExists(xw))
				modVal = s.dval - (xw[0] - iniVal)												// calculate the difference to the previous change
				xw += modVal
				break
			endif
			if (useY)
				SetScale/P y, iniVal+s.dval, DimDelta(yw,1), WaveUnits(yw,1), yw		
			else
				SetScale/P x, iniVal+s.dval, DimDelta(yw,0), WaveUnits(yw,0), yw
			endif
		break
		case "vArithmetic":
			ControlInfo/W=$(s.win) cImageOneCol;	Variable singleCol = V_Value && !V_disable
			DFREF saveDFR = GetDataFolderDFR()
			SetDataFolder GetWavesDataFolderDFR(yw)
			
			String MultiDim = ""
			if (WaveDims(yw)==2 && singleCol)													// working on 2D waves
				Variable col = qcsr($csr,gName)
				if (!strlen(ImageInfo(gName,trace,0)))											// waterfall plot
					String range = StringByKey("YRANGE", TraceInfo(gName,trace,0))				// find the displayed column from TraceInfo
					col = strsearch(range,"[",Inf,1)
					range = range[col+1,inf]
					col = str2num(RemoveEnding(range,"]"))
				endif
				if (numtype(col) == 0)
					MultiDim = "[]["+num2str(col)+"]"
				endif
			endif
			
			String Op = varStr[0]
			if ((CmpStr(Op, "+") == 0) || (CmpStr(Op, "-") == 0) || (CmpStr(Op, "*") == 0) || (CmpStr(Op, "/") == 0))
				String command = PossiblyQuoteName(NameOfWave(yw)) + MultiDim + Op + "=" + varStr[1,inf]			// construct a multiply command string
				Execute/Q/Z command
				if (V_flag)
					Print "There was an error with this command: " + GetErrMessage(V_Flag,2)
				endif
			else
				Print "You need to start your expression by a arithmetic operator +,-,* or /."
			endif
			SetDataFolder saveDFR
			break
	EndSwitch
	
	if (strlen(ImageInfo(gName,trace,0)))														// update the cursor (recalculates the control values)
		Cursor/I/P $csr, $trace, pcsr($csr,gName), pcsr($csr,gName)								// move cursor to image position
	else
		Cursor/P $csr, $trace, pcsr($csr,gName)													// move cursor to trace position
	endif
	SetActiveSubwindow $gName																	// restore focus to main window
	return 0
End

//################################################################################################

Function QuickRescale_CheckExecute(s) : CheckBoxControl
	STRUCT WMCheckboxAction &s
	if(s.eventCode == 2)
		String gName = StringFromList(0, s.win, "#")
		String csr = GetUserData(s.win, "tCursor", "")											// extract from sub window
		if (CmpStr(csr,"none") != 0 && strlen(csr))
			String image = CsrWave($csr, gName)													// wave reference from cursor
			if (strlen(ImageInfo(gName,image,0)))												// update the cursor (recalculates the control values)
				Cursor/I/P $csr, $image, pcsr($csr, gName), qcsr($csr, gName)
			endif
		endif
	endif
	return 0
End