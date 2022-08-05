#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma IndependentModule = ALP
#pragma version 1.3

//           ALP
// Alternate Line Profile

// The Igor 7 image line profile has lost functionality compared to Igor 6.
// It is also now more difficult to manually process the results of the function.

// ALP attempts to fulfill typical needs, and make it easy to use the results.

// v1.0 24.12.2016 initial release
// v1.1 3.1.2017 
//		handles X and Y axis waves
//		update does not reset profile graph settings
// 		saved wave names more systematic
// v1.2 29.1.2017
//		plot profile vs scaled x or y instead of pixels
//		profile width increment adapted to wave scaling/axis wave
// v1.3 9.1.2018
//		better switching between image windows, ALP parameters are stored in graph user data
//		ALP lines can be hidden or retained on image when ALP is not the active top window,
//		  see constant HideLinesDefault below to control default behavior
//		Initial profile adapts to displayed ranges, if whole image not visible.  


// Menu "ALP" or "Image"
//	ALPsetup()
//	ALPmakePanel()
// ALPWindowHook(s) 
//	ALPupdate()
//	ALPdraw()
//	ALPresetParms()
//	ALPgetGraphInfo() // get info about 2D waves in top graph
//	ALPhCheckProc(cba) : CheckBoxControl
//	ALPvCheckProc(cba) : CheckBoxControl
//	ALPOneGraphCheckProc(cba) : CheckBoxControl
//	ALPMultiGraphCheckProc(cba) : CheckBoxControl
// ALPhidelinesCheckProc(cba) : CheckBoxControl
//	ALPSetPixelsProc(sva) : SetVariableControl
//	ALPSetValsProc(sva) : SetVariableControl
// ALPpxToVal()
// ALPvalToPx()
// ALPsaveGraphButtonProc(ba) : ButtonControl // does the save and graph work
// ALPstackTracesButtonProc(ba) : ButtonControl
// ALPstackTraces()
// ALPnormTracesButtonProc(ba) : ButtonControl
// ALPnormTraces()
// ALPtagsOnOffButtonProc(ba) : ButtonControl
// ALPtoggleTags(onoff)  
// ALPhelpButtonProc(ba) : ButtonControl
// ALPshowHelp()
// ALPgetAxisLabel()

// Copyright (c) 2016,2017 Richard Knochenmuss
// All rights reserved.
//
// I am happy if you use and modify Chem3D, but please do not sell my work.

// License: 
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0  International License
// http://creativecommons.org/licenses/by-nc-sa/4.0/

// use this to change default behavior:
constant HideLinesDefault=1

//--------------------------------//
//Menu "ALP"
Menu "Image"
	"Alternate Line Profile...",/Q, ALPsetup()
End

//--------------------------------//
Function ALPsetup()
	string SaveDataFolder,graphlist, topgraph, ALPdata
	
	SaveDataFolder=GetDataFolder(1)
	
	if (!Datafolderexists("root:Packages"))
		NewDataFolder root:Packages
	endif
	if (!Datafolderexists("root:Packages:ALP"))
		NewDataFolder/S root:Packages:ALP
		
		variable/G ALPtype=0 // 0=H, 1=V, 2=diag
		variable/G ALPctrPx, ALPctrVal
		variable/G ALPwidthPx, ALPwidthVal
		variable/G ALPgraphing=1 // 0=separate, 1=single
		variable/G ALPhidelines=HideLinesDefault // delete or keep when ALP deactivated 
		string/G ALPmessage
		string/G ALPsourceWindow
		string/G ALPsourceWave 
		string/G ALPxWave 
		string/G ALPyWave 
		make/N=(2) ALPprofile, ALPx, ALPy, ALPprofileX
	endif
	
	ALPgetGraphInfo() // get info about 2D waves in top graph

	DoWindow ALP
	if (!v_flag)
		ALPmakePanel() 
		DoUpdate
	endif
	
	// ALP maybe closed before and is now reopened for prev used image- get ALP parms
	// see also ALPwindowHook
	graphlist=winlist("*",";","WIN:1")
	topgraph=stringfromlist(0, graphlist)
	ALPdata=getuserdata(topgraph,"","ALP") // v1.3
	if (strlen(ALPdata)!=0)
		svar ALPsourceWindow
		nvar ALPtype, ALPctrPx, ALPctrVal,ALPwidthPx, ALPwidthVal, ALPgraphing
		ALPtype=str2num(stringfromlist(0,ALPdata))
		ALPctrPx=str2num(stringfromlist(1,ALPdata))
		ALPctrVal=str2num(stringfromlist(2,ALPdata))
		ALPwidthPx=str2num(stringfromlist(3,ALPdata))
		ALPwidthVal=str2num(stringfromlist(4,ALPdata))
		ALPgraphing=str2num(stringfromlist(5,ALPdata))
		ALPsourceWindow=topgraph
		//print ALPdata
		//print ALPtype, ALPctrPx, ALPctrVal,ALPwidthPx, ALPwidthVal, ALPgraphing
		if (ALPtype==0) // 0=H, 1=V
			CheckBox TypeVertical, win=ALP,value=0	
			CheckBox TypeHorizontal, win=ALP,value=1
			SetVariable CenterVal, win=ALP, title="Center Y "
			SetVariable WidthVal, win=ALP, title="Width Y "
		else
			CheckBox TypeVertical, win=ALP,value=1	
			CheckBox TypeHorizontal, win=ALP,value=0
			SetVariable CenterVal, win=ALP, title="Center X "
			SetVariable WidthVal, win=ALP, title="Width X "
		endif
	else
		ALPresetParms()  // no old ALP data, reset parms
	endif
	ALPupdate()
		
	SetDataFolder SaveDataFolder
end

//--------------------------------//
Function ALPdraw() // redraw lines showing region
	string SaveDataFolder, wrec
	variable nxpts, nypts, ii, jj, kk, fract, X0, Y0, dx, dy, UL, LL, topax
	
	SaveDataFolder=GetDataFolder(1)
	
	SetDataFolder root:Packages:ALP
	nvar ALPtype, ALPctrPx, ALPctrVal,ALPwidthPx, ALPwidthVal, ALPgraphing
	svar ALPsourceWindow, ALPsourceWave, ALPmessage, ALPxwave, ALPywave
	wave wv2d=ImageNameToWaveRef(ALPsourceWindow, ALPsourceWave)
	nxpts=dimsize(wv2d,0)
	nypts=dimsize(wv2d,1)
	x0=dimoffset(wv2d,0)
	y0=dimoffset(wv2d,1)
	dx=dimdelta(wv2d,0)
	dy=dimdelta(wv2d,1)
	
	// show info about data being processed:
	ALPmessage="Graph: "+ALPsourceWindow+",  2D wave: "+ALPsourceWave
	if (strlen(ALPxWave)>0)
		ALPmessage=ALPmessage+", X: "+ALPxWave
	endif
	if (strlen(ALPyWave)>0)
		ALPmessage=ALPmessage+", Y: "+ALPyWave
	endif
	
	// save current ALP parms in window user data
	Setwindow $ALPsourceWindow, UserData(ALP)=num2str(ALPtype)+";"+num2str(ALPctrPx)+";"
	Setwindow $ALPsourceWindow, UserData(ALP)+=num2str(ALPctrVal)+";"+num2str(ALPwidthPx)+";"
	Setwindow $ALPsourceWindow, UserData(ALP)+=num2str(ALPwidthVal)+";"+num2str(ALPgraphing)+";"
	
	// is image plotted vs top or bottom H axis (NewImage or AppendImage)?
	wrec=winrecreation(ALPsourceWindow,0)
	ii=strsearch(wrec,"AppendImage/T",0)
	if (ii>=0)
		topax=1
	else
		topax=0
	endif
	
	DrawAction/W=$ALPsourceWindow  getgroup=ALP, delete // delete existing lines
	SetDrawEnv/W=$ALPsourceWindow gstart, gname= ALP // start drawing new
	LL=ALPctrVal - ALPwidthVal/2
	UL=ALPctrVal + ALPwidthVal/2

	if (ALPtype==0) // H
		if (strlen(ALPyWave)>0)  // v1.1 axis wave
			wave ywv=$ALPyWave
			ii=min(ALPctrPx+ALPwidthPx/2+0.5, numpnts(ywv)-1)
			UL=ywv[ii]
			ii=max(ALPctrPx-ALPwidthPx/2+0.5, 0)
			LL=ywv[ii]
		else
			LL=max(y0-0.5*dy,LL)
			UL=min(y0+(nypts-0.5)*dy, UL)
		endif
		// lower limit
		SetDrawEnv/W=$ALPsourceWindow ycoord= left // black on white dash
		SetDrawEnv/W=$ALPsourceWindow linethick=1
		SetDrawEnv/W=$ALPsourceWindow linefgc=(65535,65535,65535)
		DrawLine/W=$ALPsourceWindow 0,LL,1, LL
		
		SetDrawEnv/W=$ALPsourceWindow ycoord= left
		SetDrawEnv/W=$ALPsourceWindow dash=7
		DrawLine/W=$ALPsourceWindow 0,LL,1, LL
		// upper limit
		SetDrawEnv/W=$ALPsourceWindow ycoord= left
		SetDrawEnv/W=$ALPsourceWindow linethick=1
		SetDrawEnv/W=$ALPsourceWindow linefgc=(65535,65535,65535)
		DrawLine/W=$ALPsourceWindow 0,UL,1, UL
		
		SetDrawEnv/W=$ALPsourceWindow ycoord= left
		SetDrawEnv/W=$ALPsourceWindow dash=7
		DrawLine/W=$ALPsourceWindow 0,UL,1, UL
		// center line
		SetDrawEnv/W=$ALPsourceWindow ycoord= left
		SetDrawEnv/W=$ALPsourceWindow linethick=1
		SetDrawEnv/W=$ALPsourceWindow linefgc=(65535,65535,65535)
		DrawLine/W=$ALPsourceWindow 0,ALPctrVal,1, ALPctrVal
		
		SetDrawEnv/W=$ALPsourceWindow ycoord= left
		SetDrawEnv/W=$ALPsourceWindow dash=1
		DrawLine/W=$ALPsourceWindow 0,ALPctrVal,1, ALPctrVal
		
	elseif(ALPtype==1) // V
		if (strlen(ALPxWave)>0)  // v1.1 axis wave
			wave xwv=$ALPxWave
			ii=min(ALPctrPx+ALPwidthPx/2+0.5, numpnts(xwv)-1)
			UL=xwv[ii]
			ii=max(ALPctrPx-ALPwidthPx/2+0.5, 0)
			LL=xwv[ii]
		else
			LL=max(x0-0.5*dx,LL)
			UL=min(x0+(nxpts-0.5)*dx, UL)
		endif
		// lower limit
		if (topax)
			SetDrawEnv/W=$ALPsourceWindow xcoord= top
		else
			SetDrawEnv/W=$ALPsourceWindow xcoord= bottom
		endif
		SetDrawEnv/W=$ALPsourceWindow linethick=1
		SetDrawEnv/W=$ALPsourceWindow linefgc=(65535,65535,65535)
		DrawLine/W=$ALPsourceWindow LL, 0, LL, 1
		
		if (topax)
			SetDrawEnv/W=$ALPsourceWindow xcoord= top
		else
			SetDrawEnv/W=$ALPsourceWindow xcoord= bottom
		endif
		SetDrawEnv/W=$ALPsourceWindow dash=7
		DrawLine/W=$ALPsourceWindow LL, 0, LL, 1
		// upper limit
		if (topax)
			SetDrawEnv/W=$ALPsourceWindow xcoord= top
		else
			SetDrawEnv/W=$ALPsourceWindow xcoord= bottom
		endif
		SetDrawEnv/W=$ALPsourceWindow linethick=1
		SetDrawEnv/W=$ALPsourceWindow linefgc=(65535,65535,65535)
		DrawLine/W=$ALPsourceWindow UL, 0, UL, 1
		
		if (topax)
			SetDrawEnv/W=$ALPsourceWindow xcoord= top
		else
			SetDrawEnv/W=$ALPsourceWindow xcoord= bottom
		endif
		SetDrawEnv/W=$ALPsourceWindow dash=7
		DrawLine/W=$ALPsourceWindow UL, 0, UL, 1
		// center line
		if (topax)
			SetDrawEnv/W=$ALPsourceWindow xcoord= top
		else
			SetDrawEnv/W=$ALPsourceWindow xcoord= bottom
		endif
		SetDrawEnv/W=$ALPsourceWindow linethick=1
		SetDrawEnv/W=$ALPsourceWindow linefgc=(65535,65535,65535)
		DrawLine/W=$ALPsourceWindow ALPctrVal, 0, ALPctrVal, 1
		
		if (topax)
			SetDrawEnv/W=$ALPsourceWindow xcoord= top
		else
			SetDrawEnv/W=$ALPsourceWindow xcoord= bottom
		endif
		SetDrawEnv/W=$ALPsourceWindow dash=1
		DrawLine/W=$ALPsourceWindow ALPctrVal, 0, ALPctrVal, 1
	endif
	SetDrawEnv/W=$ALPsourceWindow gstop

	SetDataFolder SaveDataFolder
end

//--------------------------------//
Function ALPupdate()
	string SaveDataFolder
	variable nxpts, nypts, ii, jj, kk, fract, X0, Y0, dx, dy
	variable UL, LL, ULint, LLint
	string str, csrA, csrB
	
	SaveDataFolder=GetDataFolder(1)
	
	SetDataFolder root:Packages:ALP
	nvar ALPtype, ALPctrPx, ALPctrVal,ALPwidthPx, ALPwidthVal, ALPgraphing
	svar ALPsourceWindow, ALPsourceWave, ALPmessage, ALPxWave, ALPyWave
	wave ALPprofile, ALPprofileX, ALPx, ALPy
	
	if (strlen(ALPsourceWindow)>0) // was image found in top graph?
		
		ALPdraw() // redraw lines showing region
	
		wave wv2d=ImageNameToWaveRef(ALPsourceWindow, ALPsourceWave)
		nxpts=dimsize(wv2d,0)
		nypts=dimsize(wv2d,1)
		x0=dimoffset(wv2d,0)
		y0=dimoffset(wv2d,1)
		dx=dimdelta(wv2d,0)
		dy=dimdelta(wv2d,1)
		
		// the nominal FP limits
		UL=ALPctrPx+ALPwidthPx/2
		LL=ALPctrPx-ALPwidthPx/2
		
		// array index limits, pixel boundaries are half-integer
		ULint= (UL-floor(UL))>0.5 ? floor(UL)+1 : floor(UL)
		LLint= (LL-floor(LL))>=0.5 ? floor(LL)+1 : floor(LL)
		
		
		if (ALPtype==0) // HORIZONTAL ----------------------
			make/O/N=(nxpts) ALPprofile, ALPx, ALPy
			if (strlen(ALPxWave)>0)  // v1.1 axis wave
				wave xwv=$ALPxWave
				ALPx=xwv[p]+(xwv[p+1]-xwv[p])/2
			else
				ALPx=x0 + p*dx
			endif
			ALPy=ALPctrVal
			
			// boundary checking
			UL=min(nypts-0.5, UL)
			ULint=min(nypts-1, ULint)
		
			LL=max(-0.5, LL)
			LLint=max(0, LLint)
			
			ALPprofile=0
			
			if (LLint==ULint) // within 1 pixel
				if (ALPwidthPx==0) // special case width=0 => get full pixel
					fract=1
				else
					fract=UL-LL
				endif
				ALPprofile = WV2D[p][LLint]*fract
			else // spans more than one pixel
				// add all full width contributions
				if (ULint-LLint > 1) 
					for (kk=(LLint+1); kk<=(ULint-1); kk+=1) 
						ALPprofile=ALPprofile + WV2D[p][kk]
					endfor
				endif
			
				// lower partial pixel
				fract=LL-(LLint-0.5)
				fract=1-fract
				ALPprofile=ALPprofile + WV2D[p][LLint]*fract
			
				// upper partial pixel
				fract=UL-(ULint-0.5)
				ALPprofile=ALPprofile + WV2D[p][ULint]*fract
			endif
			
			duplicate/O ALPx, ALPprofileX
			str=ALPgetAxisLabel()
			if (strlen(str)==0)
				str="X Value"
			endif
			label/w=ALP#G0 bottom str
			
		elseif(ALPtype==1) // VERTICAL ----------------------
			make/O/N=(nypts) ALPprofile, ALPx, ALPy
			if (strlen(ALPyWave)>0)  // v1.1 axis wave
				wave ywv=$ALPyWave
				ALPy=ywv[p]+(ywv[p+1]-ywv[p])/2
			else
				ALPy=y0 + p*dy
			endif
			ALPx=ALPctrVal
			
			// boundary checking
			UL=min(nxpts-0.5, UL)
			ULint=min(nxpts-1, ULint)
		
			LL=max(-0.5, LL)
			LLint=max(0, LLint)
			
			ALPprofile=0
			
			if (LLint==ULint) // within 1 pixel
				if (ALPwidthPx==0) // special case width=0 => get full pixel
					fract=1
				else
					fract=UL-LL
				endif
				ALPprofile = WV2D[LLint][p]*fract
			else // spans more than one pixel
				// add all full width contributions
				if (ULint-LLint > 1) 
					for (kk=(LLint+1); kk<=(ULint-1); kk+=1) 
						ALPprofile=ALPprofile + WV2D[kk][p]
					endfor
				endif
			
				// lower partial pixel
				fract=LL-(LLint-0.5)
				fract=1-fract
				ALPprofile=ALPprofile + WV2D[LLint][p]*fract
			
				// upper partial pixel
				fract=UL-(ULint-0.5)
				ALPprofile=ALPprofile + WV2D[ULint][p]*fract
			endif
			
			duplicate/O ALPy, ALPprofileX
			str=ALPgetAxisLabel()
			if (strlen(str)==0)
				str="Y Value"
			endif
			label/w=ALP#G0 bottom str
			
		endif // V or H
	endif
	
	SetDataFolder SaveDataFolder
end

//--------------------------------//
Function ALPresetParms()
	string SaveDataFolder
	variable nxpts, nypts, X0, Y0, dx, dy, ii, LL, UL
	string str
	
	SaveDataFolder=GetDataFolder(1)
	SetDataFolder root:Packages:ALP
	nvar ALPtype, ALPctrPx, ALPctrVal,ALPwidthPx, ALPwidthVal, ALPgraphing
	svar ALPsourceWindow, ALPsourceWave, ALPmessage,ALPxWave, ALPyWave
	wave ALPprofile, ALPx, ALPy
	wave wv2d=ImageNameToWaveRef(ALPsourceWindow, ALPsourceWave)
	nxpts=dimsize(wv2d,0)
	nypts=dimsize(wv2d,1)
	x0=dimoffset(wv2d,0)
	y0=dimoffset(wv2d,1)
	dx=dimdelta(wv2d,0)
	dy=dimdelta(wv2d,1)
	
	if (ALPtype==0) // Horizontal
		getaxis/Q/W=$ALPsourceWindow left  // ensure profile is within displayed range v1.3
		ALPctrVal=(v_max-v_min)/2 + v_min
		if (strlen(ALPyWave)>0)  // have axis wave
			wave ywv=$ALPyWave
			ALPctrPx=binarysearch(ywv,ALPctrVal)
			if (ALPctrPx==-1)
				ALPctrPx=1
			elseif (ALPctrPx==-2)
				ALPctrPx=nypts-2
			endif
			ALPctrVal=ywv[ALPctrPx+0.5] // axis wave=px edges
			ii=min(ALPctrPx+ALPwidthPx/2+0.5, numpnts(ywv)-1)
			UL=ywv[ii]
			ii=max(ALPctrPx-ALPwidthPx/2+0.5, 0)
			LL=ywv[ii]
			ALPwidthVal=UL-LL
		else		// no axis wave, use wave scaling
			ALPctrPx=round((ALPctrVal-y0)/dy)
			if (ALPctrPx<1)
				ALPctrPx=1
			elseif(ALPctrPx>=nypts-1)
				ALPctrPx=nypts-2
			endif
			ALPctrVal=y0 + dy*ALPctrPx
			ALPwidthVal=dy
		endif
		
	elseif(ALPtype==1) // Vertical
		getaxis/Q/W=$ALPsourceWindow bottom  // ensure profile is within displayed range v1.3
		ALPctrVal=(v_max-v_min)/2 + v_min
		if (strlen(ALPxWave)>0)  // have axis wave
			wave xwv=$ALPxWave
			ALPctrPx=binarysearch(xwv,ALPctrVal)
			if (ALPctrPx==-1)
				ALPctrPx=1
			elseif (ALPctrPx==-2)
				ALPctrPx=nxpts-2
			endif
			ALPctrVal=xwv[ALPctrPx+0.5] // axis wave=px edges
			ii=min(ALPctrPx+ALPwidthPx/2+0.5, numpnts(xwv)-1)
			UL=xwv[ii]
			ii=max(ALPctrPx-ALPwidthPx/2+0.5, 0)
			LL=xwv[ii]
			ALPwidthVal=UL-LL
		else		// no axis wave, use wave scaling
			ALPctrPx=round((ALPctrVal-x0)/dx)
			if (ALPctrPx<1)
				ALPctrPx=1
			elseif(ALPctrPx>=nxpts-1)
				ALPctrPx=nxpts-2
			endif
			ALPctrVal=x0 + dx*ALPctrPx
			ALPwidthVal=dx
		endif
	endif
	str="SetVariable WidthVal,win=ALP, limits={0,inf,root:packages:ALP:ALPwidthVal}"
	execute/P/Q str
	str="SetVariable CenterVal,win=ALP, limits={-inf,inf,root:packages:ALP:ALPwidthVal}"
	execute/P/Q str
	
	SetDataFolder SaveDataFolder
end

//--------------------------------//
Function ALPgetGraphInfo() // get info about 2D waves in top graph
	string SaveDataFolder,graphlist, topgraph, imagelist, winrec, str, str2
	variable nxpts, nypts, X0, Y0, dx, dy, ii, jj, kk
	
	SaveDataFolder=GetDataFolder(1)
	SetDataFolder root:Packages:ALP
	nvar ALPtype, ALPctrPx, ALPctrVal,ALPwidthPx, ALPwidthVal, ALPgraphing
	svar ALPsourceWindow, ALPsourceWave, ALPmessage, ALPxWave, ALPyWave
	wave ALPprofile, ALPx, ALPy
	
	graphlist=winlist("*",";","WIN:1")
	topgraph=stringfromlist(0, graphlist)
	imagelist=ImageNameList(topgraph, ";")

	if (strlen(imagelist)>0) // yes, there is an image in top graph
		ALPsourceWindow=topgraph
		ALPsourceWave=stringfromlist(0, imagelist)
		ALPmessage="Image: "+ALPsourceWave
		winrec=winrecreation(ALPsourceWindow, 0)
		ii=strsearch(winrec, "appendimage", 0, 2)
		jj=strsearch(winrec, "\r", ii, 2)  // end of line with "appendimage"
		kk=strsearch(winrec, "vs {", ii, 2) // v 1.1 displayed vs X or Y axis waves?
		if ((kk<jj) && (kk>ii))
			str=winrec[kk+4,jj-1]
			jj=strsearch(str, ",", 0, 2) 
			str2=str[0,jj-1]
			ii=strsearch(str2, "*", 0,2)
			if (ii>=0)
				ALPxWave=""
			else
				ALPxWave="root:"+str2
				ALPxWave=ReplaceString("::",ALPxWave,":")
				
			endif
			
			kk=strsearch(str, "}", jj, 2) 
			str2=str[jj+1,kk-1]
			ii=strsearch(str2, "*", 0,2)
			if (ii>=0)
				ALPyWave=""
			else
				ALPyWave="root:"+str2
				ALPyWave=ReplaceString("::",ALPyWave,":")
			endif
		else
			ALPxWave=""
			ALPyWave=""
		endif
		//ALPresetParms()  // must be called separately if needed v1.3
		return 0
	endif
	
	// If user is returning to ALP window, but last topwin had no image,
	// presumably wants to return to last window which did have an image.
	// This typically happens when a Save&Graph is performed.
	
	// check if last image window exists, go there
	DoWindow $ALPsourceWindow
	if (v_flag) // yes, dont reset
		return 0
	else
		ALPsourceWindow=""
		ALPsourceWave=""
		ALPmessage="No image in top graph"
		ALPprofile=0
		ALPx=NaN
		ALPy=NaN
		ALPctrPx=0
		ALPctrVal=0
		ALPwidthPx=0
		ALPwidthVal=0
	endif
	
	SetDataFolder SaveDataFolder
end

//--------------------------------//
Function ALPmakePanel() 
	string SaveDataFolder
	
	SaveDataFolder=GetDataFolder(1)
	SetDataFolder root:Packages:ALP
	nvar ALPtype, ALPctrPx, ALPctrVal,ALPwidthPx, ALPwidthVal, ALPgraphing, ALPhidelines
	
	NewPanel /K=1/W=(44,76,514,460) as "Alternate Image Line Profile v1.3"
	DoWindow/C ALP
	SetDrawLayer UserBack
	CheckBox TypeVertical,pos={15.00,8.00},size={84.00,19.00},proc=ALPvCheckProc,title="Vertical      "
	CheckBox TypeVertical,fSize=14,value= 0,side= 1
	CheckBox TypeVertical,value= (ALPtype==1) // 0=H, 1=V, 2=diag
	
	CheckBox TypeHorizontal,pos={15.00,29.00},size={82.00,19.00},proc=ALPhCheckProc,title="Horizontal "
	CheckBox TypeHorizontal,fSize=14,side= 1
	CheckBox TypeHorizontal,value= (ALPtype==0) // 0=H, 1=V, 2=diag
	
	SetVariable CenterPx,pos={126.00,8.00},size={149.00,22.00},title="Center Pixel "
	SetVariable CenterPx,fSize=14, value=ALPctrPx, limits={0,inf,1}, proc=ALPSetPixelsProc
	
	SetVariable CenterVal,pos={126.00,31.00},size={149.00,22.00}
	SetVariable CenterVal,fSize=14, value=ALPctrVal, proc=ALPSetValsProc
	if (ALPtype==0) // 0=H, 1=V, 2=diag
		SetVariable CenterVal,title="Center Y "
	elseif (ALPtype==1)
		SetVariable CenterVal,title="Center X "
	endif
	
	SetVariable WidthPx,pos={302.00,9.00},size={149.00,22.00},title="Width Pixel "
	SetVariable WidthPx,fSize=14, value=ALPwidthPx, limits={0,inf,1}, proc=ALPSetPixelsProc
	
	SetVariable WidthVal,pos={301.00,33.00},size={149.00,22.00}, proc=ALPSetValsProc
	SetVariable WidthVal,fSize=14, limits={0,inf,1}, value=ALPwidthVal
	if (ALPtype==0) // 0=H, 1=V, 2=diag
		SetVariable WidthVal,title="Width Y "
	elseif (ALPtype==1)
		SetVariable WidthVal,title="Width X "
	endif
	
	Button SaveButton,pos={6.00,60.00},size={50.00,25.00},title="Save",fSize=14
	Button SaveButton, proc=ALPsaveGraphButtonProc
	
	Button SaveGraphButton,pos={62.00,60.00},size={100.00,25.00},title="Save & Graph"
	Button SaveGraphButton, fSize=14, proc=ALPsaveGraphButtonProc
	
	CheckBox OneGraph,pos={168.00,63.0},size={91.00,19.00},proc=ALPOneGraphCheckProc
	CheckBox OneGraph,fSize=14,side= 1,title="One Graph "
	if (ALPgraphing)
		CheckBox OneGraph, value=1 // 0=separate, 1=single 
	else
		CheckBox OneGraph, value=0
	endif
	
	CheckBox MultiGraphs,pos={274.00,63.0},size={124.00,19.00},proc=ALPmultiGraphCheckProc
	CheckBox MultiGraphs,fSize=14,value= 0,side= 1,title="Separate Graphs "
	if (ALPgraphing)
		CheckBox MultiGraphs, value=0 // 0=separate, 1=single
	else
		CheckBox MultiGraphs, value=1
	endif
	
	Button HelpButton,pos={406.00,60.00},size={50.00,25.00},title="Help",fSize=14
	Button HelpButton,proc=ALPhelpButtonProc
	
	CheckBox checkhidelines,pos={117.00,90.00},size={249.00,17.00},proc=ALPhidelinesCheckProc
	CheckBox checkhidelines, title="Hide profile lines when ALP not active "
	CheckBox checkhidelines,fSize=13,side= 1
	if (ALPhidelines)
		CheckBox checkhidelines,value= 1
	else
		CheckBox checkhidelines,value= 0
	endif
	
	wave ALPprofile=root:packages:ALP:ALPprofile
	wave ALPprofileX=root:packages:ALP:ALPprofileX
	Display/W=(193,110,581,352)/FG=(FL,$"",$"",$"")/HOST=#  ALPprofile vs ALPprofileX
	ModifyGraph mirror=2
	RenameWindow #,G0
	SetActiveSubwindow ##
	
	TitleBox title0,pos={6.00,360.00},size={57.00,17.00},fSize=13,frame=0
	TitleBox title0,variable= ALPmessage
	
	Setwindow kwtopwin hook(ALPhook)=ALPWindowHook
	
	SetDataFolder SaveDataFolder
	DoUpdate
End

//--------------------------------//
Function ALPhidelinesCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			nvar ALPhidelines=root:Packages:ALP:ALPhidelines
			if (checked)
				ALPhidelines=1
			else
				ALPhidelines=0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//--------------------------------//
Function ALPWindowHook(s)
	STRUCT WMWinHookStruct &s

	Variable hookResult = 0
	string SaveDataFolder,graphlist, topgraph, imagelist, ALPdata
	
	SaveDataFolder=GetDataFolder(1)
	setDataFolder root:Packages:ALP
	svar ALPsourceWindow
	nvar ALPtype, ALPctrPx, ALPctrVal,ALPwidthPx, ALPwidthVal, ALPgraphing,ALPhidelines

	switch(s.eventCode)
		case 0:				// Activate
			graphlist=winlist("*",";","WIN:1")
			topgraph=stringfromlist(0, graphlist)
			ALPdata=getuserdata(topgraph,"","ALP") // v1.3
			if (strlen(ALPdata)!=0)
				ALPtype=str2num(stringfromlist(0,ALPdata))   // see also ALPsetup
				ALPctrPx=str2num(stringfromlist(1,ALPdata))
				ALPctrVal=str2num(stringfromlist(2,ALPdata))
				ALPwidthPx=str2num(stringfromlist(3,ALPdata))
				ALPwidthVal=str2num(stringfromlist(4,ALPdata))
				ALPgraphing=str2num(stringfromlist(5,ALPdata))
				ALPsourceWindow=topgraph
				//print ALPdata
				//print ALPtype, ALPctrPx, ALPctrVal,ALPwidthPx, ALPwidthVal, ALPgraphing
				if (ALPtype==0) // 0=H, 1=V
					CheckBox TypeVertical, value=0	
					CheckBox TypeHorizontal, value=1
					SetVariable CenterVal, win=ALP, title="Center Y "
					SetVariable WidthVal, win=ALP, title="Width Y "
				else
					CheckBox TypeVertical, value=1	
					CheckBox TypeHorizontal, value=0
					SetVariable CenterVal, win=ALP, title="Center X "
					SetVariable WidthVal, win=ALP, title="Width X "
				endif
				ALPgetGraphInfo() // does not include ALPresetParms, v1.3
				ALPupdate()
			else
				ALPgetGraphInfo() 
				ALPresetParms()
				if (strlen(ALPsourceWindow)!=0)
					ALPupdate()
				endif
			endif
			break

		case 1:				// Deactivate
			if (ALPhidelines)
				DrawAction/W=$ALPsourceWindow  getgroup=ALP, delete // delete existing lines
			endif
			break
			
		case 17:				// Kill vote
			DrawAction/W=$ALPsourceWindow  getgroup=ALP, delete // delete existing lines
			break
	endswitch
	
	setdatafolder SaveDataFolder
	return hookResult		// 0 if nothing done, else 1
End


//--------------------------------//
Function ALPhCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			nvar ALPtype=root:packages:ALP:ALPtype
			if (checked)
				CheckBox TypeVertical, value=0	
				ALPtype=0
				SetVariable CenterVal, win=ALP, title="Center Y "
				SetVariable WidthVal, win=ALP, title="Width Y "
			else
				CheckBox TypeVertical, value=1	
				ALPtype=1
				SetVariable CenterVal, win=ALP, title="Center X "
				SetVariable WidthVal, win=ALP, title="Width X "
			endif
			ALPresetParms()
			ALPupdate()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//--------------------------------//
Function ALPvCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			nvar ALPtype=root:packages:ALP:ALPtype
			if (checked)
				CheckBox TypeHorizontal, value=0	
				ALPtype=1
				SetVariable CenterVal, win=ALP, title="Center X "
				SetVariable WidthVal, win=ALP, title="Width X "
			else
				CheckBox TypeHorizontal, value=1	
				ALPtype=0
				SetVariable CenterVal, win=ALP, title="Center Y "
				SetVariable WidthVal, win=ALP, title="Width Y "
			endif
			ALPresetParms()
			ALPupdate()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
//--------------------------------//
Function ALPOneGraphCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			nvar ALPgraphing=root:packages:ALP:ALPgraphing
			if (checked)
				CheckBox MultiGraphs, value=0
				ALPgraphing=1 // 0=separate, 1=single
			else
				CheckBox MultiGraphs, value=1
				ALPgraphing=0 // 0=separate, 1=single
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
//--------------------------------//
Function ALPmultiGraphCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			nvar ALPgraphing=root:packages:ALP:ALPgraphing
			if (checked)
				CheckBox OneGraph, value=0
				ALPgraphing=0 // 0=separate, 1=single
			else
				CheckBox OneGraph, value=1
				ALPgraphing=1 // 0=separate, 1=single
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//--------------------------------//
Function ALPSetPixelsProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			ALPpxToVal()
			ALPupdate()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//--------------------------------//
Function ALPSetValsProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			ALPvalToPx()
			ALPupdate()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//--------------------------------//
Function ALPpxToVal()
	String SaveDataFolder
	variable nxpts, nypts, X0, Y0, dx, dy, UL, LL, ii
	
	SaveDataFolder=GetDataFolder(1)
	SetDataFolder root:Packages:ALP
	nvar ALPtype, ALPctrPx, ALPctrVal, ALPwidthPx, ALPwidthVal
	svar ALPsourceWindow, ALPsourceWave, ALPxWave, ALPywave
	
	wave wv2d=ImageNameToWaveRef(ALPsourceWindow, ALPsourceWave)
	nxpts=dimsize(wv2d,0)
	nypts=dimsize(wv2d,1)
	x0=dimoffset(wv2d,0)
	y0=dimoffset(wv2d,1)
	dx=dimdelta(wv2d,0)
	dy=dimdelta(wv2d,1)
	
	// bounds checking
	ALPctrPx=max(0, ALPctrPx)
	ALPwidthPx=max(0, ALPwidthPx)
	if (ALPtype==0) // 0=H, 1=V, 2=diag
		// bounds checking
		ALPctrPx=min(nypts-1, ALPctrPx)
		ALPwidthPx=min(2*nypts, ALPwidthPx)
		// conversion
		if (strlen(ALPyWave)>0)  // v1.1 axis wave
			wave ywv=$ALPyWave
			ALPctrVal=ywv[ALPctrPx+0.5] // axis wave=px edges
			ii=min(ALPctrPx+ALPwidthPx/2+0.5, numpnts(ywv)-1)
			UL=ywv[ii]
			ii=max(ALPctrPx-ALPwidthPx/2+0.5, 0)
			LL=ywv[ii]
			ALPwidthVal=UL-LL
		else
			ALPctrVal=y0 + ALPctrPx*dy
			ALPwidthVal=ALPwidthPx*dy
		endif
	elseif (ALPtype==1) // 0=H, 1=V, 2=diag
		// bounds checking
		ALPctrPx=min(nxpts-1, ALPctrPx)
		ALPwidthPx=min(2*nxpts, ALPwidthPx)
		// conversion
		if (strlen(ALPxWave)>0)  // v1.1 axis wave
			wave xwv=$ALPxWave
			ALPctrVal=xwv[ALPctrPx+0.5] // axis wave=px edges
			ii=min(ALPctrPx+ALPwidthPx/2+0.5, numpnts(xwv)-1)
			UL=xwv[ii]
			ii=max(ALPctrPx-ALPwidthPx/2+0.5, 0)
			LL=xwv[ii]
			ALPwidthVal=UL-LL
		else
			ALPctrVal=x0 + ALPctrPx*dx
			ALPwidthVal=ALPwidthPx*dx
		endif
	endif
	
	setdatafolder SaveDataFolder
end

//--------------------------------//
Function ALPvalToPx()
	String SaveDataFolder
	variable nxpts, nypts, X0, Y0, dx, dy, UL, LL, ii, jj
	
	SaveDataFolder=GetDataFolder(1)
	SetDataFolder root:Packages:ALP
	nvar ALPtype, ALPctrPx, ALPctrVal, ALPwidthPx, ALPwidthVal
	svar ALPsourceWindow, ALPsourceWave, ALPxWave, ALPyWave
	
	wave wv2d=ImageNameToWaveRef(ALPsourceWindow, ALPsourceWave)
	nxpts=dimsize(wv2d,0)
	nypts=dimsize(wv2d,1)
	x0=dimoffset(wv2d,0)
	y0=dimoffset(wv2d,1)
	dx=dimdelta(wv2d,0)
	dy=dimdelta(wv2d,1)
	
	ALPwidthVal=max(0, ALPwidthVal)
	if (ALPtype==0) // 0=H, 1=V, 2=diag
		if (strlen(ALPyWave)>0)  // v1.1, axis wave  
			wave ywv=$ALPyWave
			ALPctrVal=max(ALPctrVal, ywv[0])
			ALPctrVal=min(ALPctrVal, ywv[inf])
			ALPctrPx=binarysearchinterp(ywv,ALPctrVal)-0.5
			ALPctrPx=max(ALPctrPx, 0)
			
			ii=ALPctrVal+ALPwidthVal/2
			ii=binarysearchinterp(ywv,ii)-0.5
			if (numtype(ii)!=0) // out of range
				UL=nypts-0.5
			else
				UL=ii
			endif
			
			jj=ALPctrVal-ALPwidthVal/2
			jj=binarysearchinterp(ywv,jj)-0.5
			if (numtype(jj)!=0) // out of range
				LL=-0.5
			else
				LL=jj
			endif
			// handle edge cases:
			if ((numtype(ii)!=0) && (numtype(jj)==0)) // UL is out
				ALPwidthPx=2*(ALPctrPx-LL)
			elseif ((numtype(ii)==0) && (numtype(jj)!=0)) // LL is out
				ALPwidthPx=2*(UL-ALPctrPx)
			else // both or none out
				ALPwidthPx=UL-LL
			endif 
		else
			// bounds checking
			ALPctrVal=max(ALPctrVal, y0)
			ALPctrVal=min(ALPctrVal, y0+(nypts-1)*dy)
			ALPwidthVal=min(ALPwidthVal,y0+2*(nypts)*dy) 
			// conversion
			ALPctrPx=(ALPctrVal-y0)/dy
			ALPwidthPx=ALPwidthVal/dy
		endif 
		
	elseif (ALPtype==1) // 0=H, 1=V, 2=diag
		if (strlen(ALPxWave)>0)  // v1.1, axis wave
			wave xwv=$ALPxWave
			ALPctrVal=max(ALPctrVal, xwv[0])
			ALPctrVal=min(ALPctrVal, xwv[inf])
			ALPctrPx=binarysearchinterp(xwv,ALPctrVal)-0.5
			ALPctrPx=max(ALPctrPx, 0)
			
			ii=ALPctrVal+ALPwidthVal/2
			ii=binarysearchinterp(xwv,ii)-0.5
			if (numtype(ii)!=0) // out of range
				UL=nxpts-0.5
			else
				UL=ii
			endif
			
			jj=ALPctrVal-ALPwidthVal/2
			jj=binarysearchinterp(xwv,jj)-0.5
			if (numtype(jj)!=0) // out of range
				LL=-0.5
			else
				LL=jj
			endif
			// handle edge cases:
			if ((numtype(ii)!=0) && (numtype(jj)==0)) // UL is out
				ALPwidthPx=2*(ALPctrPx-LL)
			elseif ((numtype(ii)==0) && (numtype(jj)!=0)) // LL is out
				ALPwidthPx=2*(UL-ALPctrPx)
			else // both or none out
				ALPwidthPx=UL-LL
			endif 

		else
			// bounds checking
			ALPctrVal=max(ALPctrVal, x0)
			ALPctrVal=min(ALPctrVal, x0+(nxpts-1)*dx)
			ALPctrVal=min(ALPctrVal, x0+2*(nxpts-1)*dx)
			// conversion
			ALPctrPx=(ALPctrVal-x0)/dx
			ALPwidthPx=ALPwidthVal/dx
		endif 
	endif
	
	setdatafolder SaveDataFolder
end

//------------------------------------------------------------------//
Function ALPstackTracesButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ALPstackTraces()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//------------------------------------------------------------------//
Function ALPstackTraces()
	string  trname, previoustrace, ECLtrname, str
	variable ctr, ii, jj, yoff, ymin, ymax, prevoffset
	variable spacing
	
	spacing=1.05
	ctr=0
	prevoffset=0
	yoff=0
	do
		trname=stringfromlist(ctr,tracenamelist("",";",5))  // top window trace list
		if (strlen(trname)==0)
			break
		endif
		wave/z YY=TraceNameToWaveRef("",trname)
		ymin=wavemin(YY)
		ymax=wavemax(YY)
		
		if (prevoffset!=0)
			yoff = prevoffset -ymin
			ModifyGraph offset($trname)={0,yoff}
			prevoffset=yoff + (ymax-ymin)*spacing 
		else
			ModifyGraph offset($trname)={0,0}  // first one is shifted to zero
			prevoffset=ymax*spacing  
		endif	
		ctr+=1
	while (1)
end

//------------------------------------------------------------------//
Function ALPnormTracesButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			ALPnormTraces()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//------------------------------------------------------------------//
Function ALPnormTraces()
	string  trname, previoustrace, ECLtrname, str
	variable ctr, ii, jj, yoff, ymin, ymax, prevoffset
	variable spacing
	
	spacing=1.05
	ctr=0
	prevoffset=0
	yoff=0

	do
		trname=stringfromlist(ctr,tracenamelist("",";",5))  // top window trace list
		if (strlen(trname)==0)
			break
		endif
		
		wave/z YY=TraceNameToWaveRef("",trname)
		ymin=0 
		ymax=wavemax(YY)

		YY=YY-ymin
		YY=YY/(ymax-ymin)
		ctr+=1
	while (1)
end

//------------------------------------------------------------------//
Function ALPtagsOnOffButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	string ctrlname, str
	variable ii
	
	switch( ba.eventCode )
		case 2: // mouse up
			ctrlname=ba.ctrlName
			str=GetUserData("",ctrlname,"")
			ii=strsearch(str, "on",0)
			if (ii>=0)
				ALPtoggleTags(0)
				Button $ctrlname userdata="off"
			else
				ALPtoggleTags(1)
				Button $ctrlname userdata="on"
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End	

//------------------------------------------------------------------//
// Tags are assumed to have names like: TracenameTag
// where Tracename is the name of the trace on the graph.
//
// Tag content is saved the wave note, can be changed by user.

Function ALPtoggleTags(onoff)  
	variable onoff
	string  trname, str, tagname, annolist
	variable ctr, ii, jj, xpnt

	if (onoff) // turn on
		ctr=0
		do
			trname=stringfromlist(ctr,tracenamelist("",";",5))  // top window trace list
			if (strlen(trname)==0)
				break  // end of trace list
			endif
			str=Note($("root:"+trname))
			tagname=trname+"Tag"
			Tag/N=$tagname/X=10/Y=10/I=1 $trname, 1, str
			ctr+=1
		while(1)
	else // turn off
		ctr=0
		do
			trname=stringfromlist(ctr,tracenamelist("",";",5))  // top window trace list
			if (strlen(trname)==0)
				break  // end of trace list
			endif
			tagname=trname+"Tag"
			Tag/K/N=$tagname
			ctr+=1
		while(1)
	endif
End

//------------------------------------------------------------------//
Function/S ALPgetAxisLabel()
	nvar ALPtype=root:packages:ALP:ALPtype // 0=H, 1=V, 2=diag
	svar ALPsourceWindow=root:packages:ALP:ALPsourceWindow
	string str, wrec
	variable ii, jj, kk	
	
	str=WinRecreation(ALPsourceWindow,1) // parent 2D window
	if (ALPtype==0) // 0=H, 1=V, 2=diag
		// is image plotted vs top or bottom x axis?
		wrec=winrecreation(ALPsourceWindow,0)
		kk=strsearch(wrec,"AppendImage/T",0)
		if (kk>=0)
			kk=strsearch(str, "Label/Z top",0)
		else
			kk=strsearch(str, "Label/Z bottom",0)
		endif
	elseif (ALPtype==1) // 0=H, 1=V, 2=diag
		kk=strsearch(str, "Label/Z left",0)
	endif
	if (kk>=0)
		kk=strsearch(str, "\"",kk)
		jj=strsearch(str, "\"",kk+1)
		str=str[kk+1, jj-1]
	else
		str=""
	endif

	return str
end

//------------------------------------------------------------------//
Function ALPsaveGraphButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	String ctrlName
	ctrlName=ba.ctrlName
	variable ii, jj, kk
	string wname, wnamex, winnam, str, str2, notetext, tagname, wrec, trname
	
	nvar ALPtype=root:packages:ALP:ALPtype // 0=H, 1=V, 2=diag
	nvar ALPctrPx=root:packages:ALP:ALPctrPx 
	nvar ALPctrVal=root:packages:ALP:ALPctrVal
	nvar ALPwidthPx=root:packages:ALP:ALPwidthPx 
	nvar ALPwidthVal=root:packages:ALP:ALPwidthVal
	nvar ALPgraphing=root:packages:ALP:ALPgraphing // 0=separate, 1=single
	svar ALPmessage=root:packages:ALP:ALPmessage
	svar ALPsourceWindow=root:packages:ALP:ALPsourceWindow
	svar ALPsourceWave=root:packages:ALP:ALPsourceWave 
	wave ALPprofile=root:packages:ALP:ALPprofile
	wave ALPx=root:packages:ALP:ALPx
	wave ALPy=root:packages:ALP:ALPy
	
	switch( ba.eventCode )
		case 2: // mouse up
		
			if ((strlen(ALPsourceWave)==0) || (numtype(strlen(ALPsourceWave))!=0))  // if no data, quit
				break
			endif

			ii=0
			do  // find an unused wave name
				str="root:"+ALPsourceWave+"_Hprofile"+num2str(ii)
				str2="root:"+ALPsourceWave+"_Vprofile"+num2str(ii)
				if ((!exists(str))&&(!exists(str2)))
					if (ALPtype==0) // 0=H, 1=V, 2=diag
						wname=str
					elseif (ALPtype==1)
						wname=str2
					else
						print "copy type not yet supported"
					endif
					trname=parsefilepath(3, wname, ":", 0, 0)
					break
				endif
				ii+=1
			while(ii<100)
			if (ii>=100)
				print "too many profiles"
				abort
			endif

			// copy the waves
			Duplicate/O ALPprofile, $wname
			wave profile=$wname
			if (ALPtype==0) // 0=H, 1=V, 2=diag
				wnamex="root:"+ALPsourceWave+"_Hprofile"+num2str(ii)+"X"
				Duplicate/O ALPx,  $wnamex
			elseif (ALPtype==1)
				wnamex="root:"+ALPsourceWave+"_Vprofile"+num2str(ii)+"Y"
				Duplicate/O ALPy,  $wnamex
			endif
			wave profilex=$wnamex
			
			// store profile info in wave note
			notetext="2D wave:"+ALPsourceWave+"\r"
			if (ALPtype==0) // 0=H, 1=V, 2=diag
				notetext+= " Y Px Center:"+num2str(ALPctrPx)+" Y Px Width:"+num2str(ALPwidthPx)+"\r"
				notetext+= " Y Center:"+num2str(ALPctrVal)+" Y Width:"+num2str(ALPwidthVal)
			elseif (ALPtype==1) // 0=H, 1=V, 2=diag
				notetext+= " X Px Center:"+num2str(ALPctrPx)+" X Px Width:"+num2str(ALPwidthPx)+"\r"
				notetext+= " X Center:"+num2str(ALPctrVal)+" X Width:"+num2str(ALPwidthVal)
			endif
			Note $wname, notetext 
			Note $wnamex, notetext 
			
			ALPmessage="Saved: "+wname
			
			if (cmpstr(ctrlName, "SaveButton")==0) // if only save, we are done here
				break
			endif
			
			// continue with graphing options
			
			if (ALPgraphing==0)    // 0=separate, 1=single graph
				winnam=ALPsourceWave+"_profile"+num2str(ii)
			else
				winnam="ALPprofiles"
			endif

			DoWindow $winnam
			if (!V_Flag)  // if window doesnt exist, make it
				Display/K=1/W=(150, 310, 150+475, 310+250) $wname vs $wnamex
				DoWindow/C $winnam
				modifygraph mirror=2
		
				// copy the 2D window axis label:
				str=ALPgetAxisLabel()
				Label bottom str

				ControlBar 24

				if (ALPgraphing==1)    // 0=separate, 1=single
					// single graph has some display control buttons:
					ctrlname= "StackButton"
					Button $ctrlname title="Stack",size={45,20},pos={275,2}, fSize=11, proc=ALPstackTracesButtonProc
					Button $ctrlname, font=Tahoma, fsize=12
					
					ctrlname= "NormButton"
					Button $ctrlname title="Norm",size={45,20},pos={335,2}, fSize=11, proc=ALPnormTracesButtonProc
					Button $ctrlname, font=Tahoma, fsize=12
					
					ctrlname= "TagsButton" 
					Button $ctrlname title="Tags 0/1",size={60,20},pos={200,2}, fSize=11, proc=ALPtagsOnOffButtonProc
					Button $ctrlname userdata="on"
					Button $ctrlname, font=Tahoma, fsize=12
					
				else // separate graphs	
					if (ALPtype==0) // 0=H, 1=V, 2=diag
						str=wname + "   Y Center:"+num2str(ALPctrVal)+"  Y Width:"+num2str(ALPwidthVal)
					elseif (ALPtype==1) // 0=H, 1=V, 2=diag
						str=wname + "   X Center:"+num2str(ALPctrVal)+"  X Width:"+num2str(ALPwidthVal)
					endif
					TitleBox title0 title=str, pos={5,5}, frame=0, font=Tahoma
				endif
			else // window exists, simply add new wave
				AppendtoGraph/W=$winnam $wname vs $wnamex
			endif
			
			if (ALPgraphing==1)    // 1=single, show data for each profile in a tag
				tagname=trname+"Tag"
				notetext = "\\F'Tahoma'"+notetext
				str=parsefilepath(3,wname,":",0,0) // only trace name, not full path
				Tag/W=$winnam/N=$tagname/X=10/Y=10/I=1 $str, 1, notetext
			endif

			break
	endswitch
	return 0
End

//------------------------------------------------------------------//
Function ALPhelpButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	string ctrlname, str
	variable ii
	
	switch( ba.eventCode )
		case 2: // mouse up
			dowindow ALPhelp
			if (!v_flag)
				ALPshowhelp()
			else
				dowindow/F ALPhelp
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End	

//------------------------------------------------------------------//
Function ALPshowhelp()
	String nb = "ALPhelp"
	NewNotebook/N=$nb/F=1/V=1/K=1/ENCG={3,1}/W=(435.75,39.5,806.25,400.25)
	Notebook $nb defaultTab=36
	Notebook $nb showRuler=0, rulerUnits=2, updating={1, 1}
	Notebook $nb newRuler=Normal, justification=0, margins={0,0,468}, spacing={0,0,0}, tabs={}, rulerDefaults={"Arial",11,0,(0,0,0)}
	Notebook $nb ruler=Normal, text="\t\t", fStyle=1, text=" ALP: Alternate Line Profile v1.3\r"
	Notebook $nb fStyle=-1, text="\r"
	Notebook $nb fStyle=1, text="Why ALP?\r"
	Notebook $nb fStyle=-1, text="The Igor 7 image line profile has fewer features than in Igor 6: \r"
	Notebook $nb text="- The profile graph cannnot be modified, or the data explored, \r"
	Notebook $nb text="   for example with a cursor.\r"
	Notebook $nb text="- Does not take wave scaling into account.\r"
	Notebook $nb text="- No longer possible to graph a profile, it can only be saved.\r"
	Notebook $nb text="- The saved wave is now a triplet. This is not visible in the \r"
	Notebook $nb text="  default New Graph menu, inexperienced users can not easily graph\r"
	Notebook $nb text="  it themselves. Also, inexperienced users do not know how to graph\r"
	Notebook $nb text="  one column of a triplet vs another.\r"
	Notebook $nb text="- The lines defining the profile are hard to see on dark images.\r"
	Notebook $nb text="- If a profile limit goes outside the image, the profile is NaN, instead\r"
	Notebook $nb text="  of truncating at the edge of the image. \r"
	Notebook $nb text="\r"
	Notebook $nb text="ALP is an Alternate Line Profile package designed to meet typical needs.\r"
	Notebook $nb text="- The profile graph is fully accessible.\r"
	Notebook $nb text="- Image wave scaling is used.\r"
	Notebook $nb text="- X and/or Y axis waves are used, if present.\r"
	Notebook $nb text="- The profile can be specified in pixel or scaled units.\r"
	Notebook $nb text="- There are two graphing options, together in one graph or separate \r"
	Notebook $nb text="  graphs. The single graph option facilitates comparison of profiles\r"
	Notebook $nb text="  from different images.\r"
	Notebook $nb text="- The profile lines on the image are easily visible.\r"
	Notebook $nb text="- The profiles are saved as three one-D waves, for easy discovery and\r"
	Notebook $nb text="  use. These are the profile, and the corresponding X and Y coords. The\r"
	Notebook $nb text="  coordinates are in scaled wave units.\r"
	Notebook $nb text="\r"
	Notebook $nb fStyle=1, text="Version 1.1 changes:\r"
	Notebook $nb fStyle=-1, text="- X and/or Y axis waves can be used.\r"
	Notebook $nb text="- Bug fixed causing profile graph modifications to be lost at each update.\r"
	Notebook $nb text="- Saved wave names are more systematic and clear.\r"
	Notebook $nb text="- Fixed possible tag name conflict in unified save graph.\r"
	Notebook $nb fStyle=1, text="Version 1.2 changes:\r"
	Notebook $nb fStyle=-1,text="- plot profile vs scaled x or y instead of pixels.\r"
	Notebook $nb text="- profile width increment adapted to wave scaling/axis wave.\r"
	Notebook $nb fStyle=1, text="Version 1.3 changes:\r"
	Notebook $nb fStyle=-1,text="- better switching between image windows, ALP parameters\r"
	Notebook $nb text="  are stored in graph user data.\r"
	Notebook $nb text="- ALP lines can be hidden or retained on image when \r"
	Notebook $nb text="  the ALP panel is not the active top window.\r"
	Notebook $nb text="\r"
	//Notebook $nb fStyle=1, text="Planned features:\r"
	//Notebook $nb fStyle=-1, text="- Diagonal profiles (but not freeform).\r"
	Notebook $nb text="\r"
	Notebook $nb fStyle=1, text="Using ALP\r"
	Notebook $nb fStyle=-1, text="- Start it from the menu: Image/Alternate Line Profile\r"
	Notebook $nb text="- When you click on the ALP window, it checks if the top graph includes\r"
	Notebook $nb text="  an image. If so, it places profile lines on the image.\r"
	Notebook $nb text="- When you leave the ALP window, the profile lines may be removed from \r"
	Notebook $nb text="  the image, or can be retained. See the checkbox above the ALP graph.\r"
	Notebook $nb text="- ALP stores profile parameters for each image graph.\r"
	Notebook $nb text="  You can leave or modify the image, then go back to ALP without loosing\r"
	Notebook $nb text="  the profile settings.\r"
	Notebook $nb text="- The width is the FULL width, not half width.\r"
	Notebook $nb text="- The profile is the SUM of the data over the width, not the average.\r"
	Notebook $nb text="- Sub-pixel interpolation is used, so a profile of width 1.1 is different from\r"
	Notebook $nb text="  width 1. This is an estimate of the profile from a higher res image.\r"
	Notebook $nb text="- Special case: if width = 0, the profile is the current row or column. For\r"
	Notebook $nb text="  example if the center = 2.23, and width=0, the profile is as if center\r"
	Notebook $nb text="  is exactly 2.0 and the width is exactly 1 pixel. This makes it easy to\r"
	Notebook $nb text="  examine specific rows and columns. \r"
	Notebook $nb text="- There is a message area at the bottom of the panel, giving some\r"
	Notebook $nb text="  information about what is happening.\r"
	Notebook $nb text="- The profile details are in the wave notes of the saved waves.\r"
	Notebook $nb text="- Using X or Y axis waves:\r"
	Notebook $nb text="\tIf the 2D wave is plotted vs separate X or Y axis waves, and\r"
	Notebook $nb text="\tthese waves are nonlinear (intervals not constant), you may\r"
	Notebook $nb text="\tfind that the profile boundaries on the graph are not exactly at\r"
	Notebook $nb text="\tthe expected X/Y values. This is because they are converted to\r"
	Notebook $nb text="\tpixel values using the axis wave at the center of the profile.\r"
	Notebook $nb text="\tThe pixel values determine the profile, they take priority over \r"
	Notebook $nb text="\tthe axis wave values. "

	Notebook $nb selection={startOfFile,startOfFile}, findText={"",1}
	Notebook $nb  findText={"Using ALP",1}
end