#pragma rtGlobals=1		// Use modern global access method.
Macro EDM_manipulations()
	//Prompt hor_twoDwave0,"3D wave", popup WaveList("*", ";", "DIMS:3")
	//String hor_twoDwave0
	manip()
end

Function manip()
	if(DataFolderExists("root:manip")==0)
		KillDatafolder/Z root:manip
	endif
	
	if(DataFolderExists("root:Fitresults")==0)	
		NewDataFolder/O root:Fitresults
	endif
	if(DataFolderExists("root:EDCs")==0)	
		NewDataFolder/O root:EDCs
	endif
	if(DataFolderExists("root:EDMs")==0)	
		NewDataFolder/O root:EDMS
	endif
	NewDataFolder/S/O root:manip
	
	Variable/G Ef = 23.942
	Variable/G lattice = 3.1415926
	
	Variable/G s_tilt = 0
	Variable/G s_polar = 0 
	Variable/G pol_shift = 0
	Variable/G s_phi = 0
	Variable/G slit = 0									// slit horizontal=0 or vertical=1
	Variable/G slit_width = 30								// beginning and end of slit
	Variable/G EDC_slice = 0
	Variable/G MDC_slice = 0
	Variable/G Avk = 0
	Variable/G Ave = 0
	Variable/G pointcount = 0
	Variable/G smothk = 7
	Variable/G smothe = 7
	Variable/G edmoff = 0
	Variable/G edmdel = 0
	Variable/G edcmdc = 0
	Variable/G polynom = 0
	Variable/G Temp = 10
	Variable/G Res = 3
	Variable/G fitedc_cnt = 1
	Variable/G fitmdc_cnt = 1
	Variable/G opt = 0
	Variable/G sm_fac = 5
	Variable/G norm_flag = 0
	Variable/G revertcolorvar,reversecolorvar, contrast, brightness, topoaverage, topodev,imselect
	String/G  file_name, fname, f_name, folderlist, colorscheme
	String/G name1, name3
	Make/O/N=(1,1) EDM,EDMshow, dk2EDM
	Make/O/N=1 EDCcut, MDCcut, EDClinex, EDCliney, MDClinex, MDCliney, Init__fit
	Make/O/N=1 osc_shape
	DoWindow/K manipEDM
	Display/N=manipEDM/K=1/W=(300,40,1440,600)
	
	NewPanel/K=1/Host=manipEDM/N=buttons/W=(0.8,0,1,1)
	Showinfo
	//SetDataFolder root:
	//-----Select data
	Variable n, nmax
	nmax = CountObjects("root:",4)
	String/G waveslist
	folderlist = "\""+"root"+";"
	for (n=0;n<nmax-1;n+=1)
		folderlist = folderlist + GetIndexedObjName("root:", 4, n) + ";"
	endfor
	folderlist = folderlist + GetIndexedObjName("root:", 4, nmax-1)+"\""
	
	PopupMenu chfol,pos={12,10},size={76,20},proc=get_folder_name,title="Fol:",mode=1,popvalue="choose",value= #folderlist
	PopupMenu ddd,pos={110,10},size={76,20},proc=get_EDM_name,title="Wave:",mode=1,popvalue="choose",value= # "root:manip:waveslist"
	Button lodat,pos={110,30},size={110,20},proc=load_HDF5data,title="load HDF5"
//	Button set_k,pos={110,50},size={110,20},proc=Au_correction,title="to k-space"
	Button set_k,pos={110,50},size={110,20},proc=load_elettra,title="load Elettra"
		
	DrawText 7,45,"Slit Orientation:"
	PopupMenu popbut,pos={12,45},size={100,20},proc=slit_manips
	PopupMenu popbut,mode=1,popvalue="horizontal",value= #"\"vertical; horizontal\""
	SetVariable ps,pos={180,70},size={100,15},proc=polshift,title="Pol shift:"
	SetVariable ps,limits={-90,90,0.1},value= root:manip:pol_shift
	SetVariable SetEf,pos={12,70},size={80,15},proc=update_var, title=" hnu:",limits={0,1000,0.1},value= root:manip:Ef
	SetVariable Setlat,pos={95,70},size={80,15},proc=update_var, title=" lat.:",limits={0,10,0.1},value= root:manip:lattice
	SetVariable edmo,pos={12,85},size={100,15},proc=EDM_scale, title=" edm of:",limits={-100,100,0.01},value= root:manip:edmoff
	SetVariable edmd,pos={105,85},size={100,15},proc=EDM_scale, title=" edmdel:",limits={-1,1,0.0001},value= root:manip:edmdel
	
	//-------k-space stuff
	
	DrawText 7,120,"Angle Corrections:"
	SetVariable e,pos={12,120},size={100,15},proc=update_var,title="Polar:"
	SetVariable e,limits={-90,90,0.1},value= root:manip:s_polar
	SetVariable ee,pos={115,120},size={100,15},proc=update_var,title="Azi:"
	SetVariable ee,limits={-360,360,0.25},value= root:manip:s_phi
	SetVariable eee,pos={12,140},size={100,15},proc=update_var,title="Tilt:"
	SetVariable eee,limits={-90,90,0.1},value= root:manip:s_tilt
	SetVariable eeee,pos={115,140},size={100,15},proc=update_var,title="slit width:"
	SetVariable eeee,limits={-90,90,0.1},value= root:manip:slit_width
	
	
	DrawText 7,175,"Averaging:"
	SetVariable avk,pos={12,180},size={100,15},proc=ave_ek,title="Av. k:"
	SetVariable avk,limits={-90,90,1},value= root:manip:Avk
	SetVariable ave,pos={115,180},size={100,15},proc=ave_ek,title="Av. e (meV):"
	SetVariable ave,limits={-90,90,1},value= root:manip:Ave
	
	DrawText 7,210,"Derivate:"
	SetVariable smok,pos={12,210},size={100,15},proc =der_EDM, title="d(Img)/dk:"
	SetVariable smok,limits={7,32001,2}, value= root:manip:smothk
	SetVariable smoe,pos={120,210},size={100,15} ,title="d(Img)/dE:"
	SetVariable smoe,limits={7,32001,2},proc =der_EDM, value= root:manip:smothe
	
	Display/K=1/Host=manipEDM/N=image/W=(0,0,0.4,0.6); AppendImage EDMshow; AppendToGraph EDCliney vs EDClinex; AppendToGraph MDCliney vs MDClinex
	ModifyImage EDMshow ctab= {*,*,BlueHot,1}
	Cursor/I/A=1/C=(64000,0,64000)/W=manipEDM#image A EDMshow 20,270
	Cursor/I/A=1/C=(64000,0,64000)/W=manipEDM#image B EDMshow 150,250
	Display/K=1/Host=manipEDM/N=image2/W=(0,0.6,0.4,1); AppendImage dk2EDM;
	
	SetVariable EDCslice_but,pos={12,230},size={120,20},proc=make_EDCs,title="EDC slice",limits={DimOffset(EDM,0),DimOffset(EDM,0)+(DimSize(EDM,0)-1)*DimDelta(EDM,0),DimDelta(EDM,0)},value= root:manip:EDC_slice
	SetVariable MDCslice_but,pos={12,255},size={120,20},proc=make_MDCs,title="MDC slice",limits={DimOffset(EDM,1),DimOffset(EDM,1)+(DimSize(EDM,1)-1)*DimDelta(EDM,1),DimDelta(EDM,1)},value= root:manip:MDC_slice
	Button cro, proc=crop, title="Crop",pos={136,230},size={60,20}
	Button ucro, proc=uncrop, title="Uncrop",pos={136,255},size={60,20}
	
	
	Display/K=1/Host=manipEDM/N=EDC/W=(0.4,0.5,0.8,1); AppendToGraph EDCcut;
	Display/K=1/Host=manipEDM/N=MDC/W=(0.4,0,0.8,0.5); AppendToGraph MDCcut;//AppendToGraph/C=(1,4,52428) Init__fit

	Variable/G start, stop, p_amount, bg_offset, bg_slope, bg_shift, bg_sq, bg_cub, bg_qu, p_num, l_pos, l_int, l_width, l_mix, high, max_lor
	Variable/G offs, slop, shif, sqr, cube, quar
	shif = 1
	sqr = 1
	cube = 1
	quar = 1
	p_amount=1
	bg_offset = 0.05 
	bg_slope=0.01
	bg_shift = 0
	bg_sq = 0
	bg_cub = 0
	bg_qu = 0 
	p_num=1 
	l_pos=0 
	l_int=0
	l_width=0
	l_mix = 0
	max_lor=1
	Make/O/N=(6 + 3*p_amount) Fit_para	
	Variable/G BG_type //17nov06
	BG_type=2
	
	Button al, proc=low_val, title="Start MDC:",pos={12,280},size={80,20}
	Button bl, proc=high_val, title="End MDC:",pos={12,305},size={80,20}
	Button al2, proc=val_go, title="Go:", pos={100,280}, size={40,20}
	Button bl2, proc=val_go, title="Go:", pos={100,305}, size={40,20}
		
	PopupMenu kl2, pos={150,280},size={150,18}, proc=EDC_MDC, title="FIT:", value="MDC;EDC"
	
	SetVariable cl proc=num_lor, title="Nr. of Osc.:",pos={12,330},size={100,20}, limits={0,10,0},value= p_amount;DelayUpdate
	SetVariable gl ,title="Osc. nr.:", proc=show_input, pos={120,330},size={120,18}, limits={1,max_lor,1},value= p_num;DelayUpdate
    SetVariable hl ,title="Osc. position:", proc=updat_fit,pos={12,353},size={120,18}, limits={-2000,2000,0},value= l_pos;DelayUpdate
	SetVariable il,title="Osc. height:", proc=updat_fit,pos={12,376},size={120,18}, limits={0,10000000000000,0},value= l_int;DelayUpdate
	SetVariable jl ,title="Osc. width:", proc=updat_fit,pos={12,399},size={120,18}, limits={0,10000000000000,0},value= l_width;DelayUpdate
	SetVariable jl2 ,title="mix/asymm.:", proc=updat_fit,pos={140,399},size={120,18}, limits={-100,100,0},value= l_mix;DelayUpdate
	
	PopupMenu kl, pos={135,353},size={150,18}, proc=updat_shape, title="Shape:", value="Lorentz;Voigt;DS;poly;Gauss"
	SetVariable dl proc=updat_fit,title="BG offset:",pos={12,422},size={100,18}, limits={-1000000000000,10000000000000,0},value= bg_offset;DelayUpdate
	checkbox gc, noproc, title = " ", pos = {115,422}, size={20,20}, variable = offs
	SetVariable el proc=updat_fit,title="BG slope:",pos={12,445},size={100,18}, limits={-100000000000000,10000000000000,0},value= bg_slope;DelayUpdate
	checkbox hc, noproc, title = " ", pos = {115,445}, size={20,20}, variable = slop
	SetVariable dl3 proc=updat_fit,title="BG shift:",pos={12,468},size={100,18}, limits={-10000000000000,10000000000000,0},value= bg_shift;DelayUpdate
	checkbox ic, noproc, title = " ",  pos = {115,468}, size={20,20}, variable = shif
	SetVariable dl2 proc=updat_fit,title="sq.:",pos={135,422},size={100,18}, limits={-10000000000000,100000000000000,0},value= bg_sq;DelayUpdate
	checkbox jc, noproc, title = " ",  pos = {238,422}, size={20,20}, variable = sqr
	SetVariable el2 proc=updat_fit,title="cube:",pos={135,445},size={100,18}, limits={-10000000000000,1000000000000000,0},value= bg_cub;DelayUpdate
	checkbox gc2, noproc, title = " ", pos = {238,445}, size={20,20},variable= cube
	SetVariable el3 proc=updat_fit,title="quar:",pos={135,468},size={100,18}, limits={-1000000000000000,10000000000000000,0},value= bg_qu;DelayUpdate
	checkbox hc2, noproc, title = " ", pos = {238,468}, size={20,20}, variable = quar
	
	
	//PopupMenu xl, pos={12,468},size={150,18}, proc=BG_proc_edm, title="Background", value="smooth ; free; smooth + 0 slope" //17nov06
	
	Button fl1 proc=fit_one, pos={12,491},size={60,18}, title="fit one!"; DelayUpdate
	Button fla proc=fit_all, pos={75,491},size={60,18}, title="fit all!"; DelayUpdate
	Button nwft proc=new_disp, pos={138,491},size={80,18}, title="new disp"; DelayUpdate
	
	Button im2Da ,proc=rcal_input_edm,pos={12,514},size={120,18},title="Recall input"
	Button im2Db ,proc=bg_sub_edm,pos={140,514},size={120,18},title="Substract BG"
	
	//This function allows you to add a point to an E(k) curve, from cursor values
	Button ek,proc=add_point,pos={12,537},size={100,25},title="Add to E(K)"
	Button ekb,proc=back_point,pos={115,537},size={60,25},title="Back"
	Button derim,proc=do_der_im,pos={180,537},size={60,25},title="Der. Im."
	Button ekn,proc=add_new,pos={12,567},size={100,25},title="New E(K)"
	Button mkim,proc=do_image,pos={115,567},size={100,25},title="Make image"
	Button sedm,pos={12,597},size={100,28},proc=save_EDM2,title="Save EDM"
	Button sedc,pos={115,597},size={100,28},proc=save_EDC2,title="Save EDC/MDC"
	
	
	SetVariable ft,pos={12,630},size={100,15},proc=div_fe, limits={0,1000,0.5},title="FE(T(K)):", value = Temp
	SetVariable rt,pos={115,630},size={100,15},proc=div_fe, limits={0,10000,0.1},title="Res (meV):", value = res
	
	PopupMenu reno,pos={12,660},size={150,28},proc=renormalize,title="Renormalize EDM",value= #"\"Subt. Integr.; Div. Integr.; Subt. Ind.;\""
	SetVariable smfa,pos={12,700},size={100,15}, limits={5,10000,2},title="Smooth:", value = sm_fac
	
//	
//	PopupMenu colorselect,pos={13,660},size={180,21}, proc=colortopowave3, mode=1,popvalue="",value= #"\"*COLORTABLEPOPNONAMES*\""
//	CheckBox reversecolorbox, pos={12,685}, size={64,15},proc=reversecolor3,title="Reverse",variable= reversecolorvar
//	CheckBox orcolore, pos={78,685}, size={64,15},proc=revertcolor3,title="Revert",variable= revertcolorvar
//	CheckBox imsel, pos={142,685}, size={64,15},proc=selectimg3,title="dE/dk",variable= imselect
//	
//	Slider contrastslider, fsize=0, side=2,vert = 0, limits={0.01,10,0.01},pos={12,700},size={204,40}, variable=contrast, proc=contrasttopowave3
//	Slider brightnessslider, fsize=0, side=1,vert = 0, limits={0.01,5,0.01},pos={12,745},size={204,40}, variable=brightness, proc=contrasttopowave3
//	Button reno,pos={12,790},size={150,28},proc=renormalize,title="Renormalize EDM"
//	

End

Function new_disp(ctrlName ):buttonControl	//does the actual fitting
		String ctrlName
	
		NVAR edcmdc, fitedc_cnt, fitmdc_cnt
		SVAR name1, name3
		name1 = ""
		name3 = ""
		if (edcmdc == 0)
			Wave MDC_result_wav, MDC_error_wav
			KillWaves MDC_result_wav, MDC_error_wav
			fitmdc_cnt += 1
		else
			Wave EDC_result_wav, EDC_error_wav
			KillWaves EDC_result_wav, EDC_error_wav
			fitedc_cnt += 1
		endif
End



Function load_HDF5data(ctrlName ):buttonControl	//does the actual fitting
		String ctrlName
		
		Variable/G file_ID
		String/G filename,fname
	
		HDF5OpenFile/I/R file_ID as ""
		filename = S_filename
		fname=replacestring("-",filename,"_")
		fname=replacestring(".nxs",fname,"")
		NewDataFolder/S/O $fname
		HDF5LoadGroup/IMAG=1 :, file_ID, "entry1/analyser"
		HDF5CloseFile file_ID
		
		Wave data, angles,energies
		Make/O/N=(dimsize(data,1),dimsize(data,2)) rdata
		Setscale/P x,angles[0],angles[1]-angles[0],"" rdata
		Setscale/P y,energies[0],energies[1]-energies[0],"" rdata
		
		rdata[][]=data[0][p][q]
		filename="root:EDMS:"+fname
		Duplicate/O rdata,$filename 
		SetDatafolder "root:manip:"
		 
		KillDatafolder $fname
		String/G datafolder
		datafolder="EDMS"
		get_EDM_name("bla",0,fname)
		
End

Function load_Elettra(ctrlName ):buttonControl	//does the actual fitting
	String ctrlName
	loadwave/Q/O
	String/G filename,fname,fname2, fname3, fname4
	fname=StringfromList(0,S_fileName)
	fname3=StringfromList(0,S_waveNames)
	fname2=replacestring(".ibw",fname,"")
	duplicate/O $fname3, $fname2
	filename="root:EDMS:"+fname2
	Variable n,cnt
	if(dimsize($fname2,2)==0)
		Matrixtranspose $fname2
		Setscale/P x, dimoffset($fname2,0),dimdelta($fname2,0),"" $fname2
		Setscale/P y, dimoffset($fname2,1),dimdelta($fname2,1),"" $fname2 
		Duplicate/O $fname2,$filename
		Killwaves $fname2
		SetDatafolder "root:manip:"
		String/G datafolder
		datafolder="EDMS"
		get_EDM_name("bla",0,fname2) 
	else
		fname3=fname2+"_sum"
		Duplicate/O/RMD=[][][0] $fname2, $fname3
		Wave v=$fname2
		Redimension/N=(-1,-1,0) $fname3
		Wave w = $fname3
		w=0
		cnt=0
		for(n=0;n<dimsize($fname2,2);n+=1)
			w[][]+=v[p][q][n]
			cnt+=1
			fname4=fname2+"_"+num2str(n)
			Duplicate/O/RMD=[][][n] $fname2, $fname4
			Redimension/N=(-1,-1,0) $fname4
			Matrixtranspose $fname4
			filename="root:EDMS:"+fname4
			Duplicate/O $fname4,$filename
			Killwaves $fname4
		endfor
		w=w/cnt
		Redimension/N=(-1,-1,0) w
		Matrixtranspose w
		filename="root:EDMS:"+fname3
		Duplicate/O $fname3,$filename
		Killwaves $fname3
		SetDatafolder "root:manip:"
		String/G datafolder
		datafolder="EDMS"
		get_EDM_name("bla",0,fname4)
	endif
End

Function Au_correction(ctrlName ):buttonControl	//does the actual fitting
		String ctrlName
		
		
		Wave mEDM
		Variable index
		Variable n,m
		String auwav="root:EDMS:Auwave"
		if(exists(auwav)==1)
			if(exists("slit_wav")!=1)
				Wave Auwave=$auwav
				Make/O/N=(dimsize(mEDM,0)) slitfunction, intensity, BGwav
				Make/O/N=(dimsize(mEDM,1)) EDC2fit
				Setscale/P x,dimoffset(Auwave,1),dimdelta(Auwave,1),"" EDC2fit
				Make/O/N=(5) W_coef
				
				W_coef[0] = 23.6
					W_coef[1] = 1400   	//put the initial guess to fit
					W_coef[2] = 300 						// Background starting value
					W_coef[3] = 0.05 	
					W_coef[4] = 0.01
				For(n=0;n<dimsize(mEDM,0);n+=1)
					EDc2fit[]=Auwave[n][p]
					Wavestats/Q EDC2fit
					intensity[n]=V_sum/dimsize(EDC2fit,0)
					Wavestats/Q/R=[dimsize(EDC2fit,0)-50,dimsize(EDC2fit,0)] EDC2fit
					BGwav[n]=V_avg
					FuncFit/Q/N FermiEDM W_coef EDC2fit /D
					slitfunction[n]=W_coef[0]	
					
				endfor
			 endif
			 Wavestats/Q slitfunction
			 NVAR Ef
			// Ef=V_avg	
//			Smooth 100, slitfunction
//		// ------------------ GOLD CORRECTION						// SdJ 7nov 06, swapped corr and norm; doing norm first gives 
//														// clear view on the uncorrected slit. Also placed 'Gold correction'
//														// inside if-loop that excludes it if gold fit is done earlier
//		Matrixtranspose Auwave
//		Make/O/N=(DimSize(Auwave,0),DimSize(Auwave,1))  norm_Auwave = Auwave[p][0]
//		WaveStats/Q slitfunction
//		SetScale/P x,(DimOffset(Auwave,0) - V_min),DimDelta(Auwave,0),"" norm_Auwave
//		SetScale/P y,DimOffset(Auwave,1),DimDelta(Auwave,1),"deg" norm_Auwave
//
//		Make/O/N=(DimSize(Auwave,0)) slice_norm, slice_corr
//		
//		index = 0										//
//		do												//
//			slice_norm=Auwave[p][index]/  intensity[index]	// Normalization
//			norm_Auwave[][index]= slice_norm[p]			//
//			index+=1									//
//		while(index<DimSize(Auwave,1))					//
//	
//		String gold_name= "Auwave_norm"
//	
//		Duplicate/O norm_Auwave $gold_name
//		
//		Duplicate/O slitfunction step_shift					//
//		step_shift-=V_min								// Calculate the number of steps to shift each gold EDC
//		step_shift/=Dimdelta(Auwave,0)					//
//		
//		Duplicate/O norm_Auwave corr_norm_Au
//		
//		index = 0	
//		Variable step
//		do
//			//if(shift_type==2)								// SdJ: gives user the chiose between a 'ridged' and 'soft' shift
//				step=floor(step_shift[index]+0.5)			// For FDD off-sets: 0< <0.5 ; no shift,
//			//else											//				   0.5< <1.5 1 stepsize shift,
//			//	step=step_shift[index]						//				   1.5< <2.5 2 stepsize shift, etc.
//			//endif
//			step_shift[index]=step
//			slice_norm=norm_Auwave[p][index]
//			Duplicate/O slice_norm slice_corr
//			slice_corr=slice_norm[p+(step_shift[index])]
//			corr_norm_Au[][index]=slice_corr[p]
//			index+=1
//		while(index<DimSize(step_shift,0))
//		
//		gold_name= "Auwave_NC"
//		Duplicate/O corr_norm_Au, $gold_name
//		Matrixtranspose $gold_name
//		Matrixtranspose Auwave

// ------------------ WAVE2BNORMALIZED NORMALIZATION			// SdJ 7nov 06, swapped corr and norm
	Duplicate/O mEDM, wave2bcorrnorm
	Matrixtranspose wave2bcorrnorm
	Make/O/N=(DimSize(wave2bcorrnorm,0),DimSize(wave2bcorrnorm,1))  wave2bnorm = wave2bcorrnorm[p][0]
	WaveStats/Q slitfunction
	Duplicate/O wave2bcorrnorm,wave2bnorm
	SetScale/P x,(DimOffset(wave2bcorrnorm,0) - Ef),DimDelta(wave2bcorrnorm,0),"" wave2bnorm
	SetScale/P y,DimOffset(wave2bcorrnorm,1),DimDelta(wave2bcorrnorm,1),"" wave2bnorm
	
	Make/O/N=(DimSize(wave2bcorrnorm,0)) slice_norm, slice_corr
	
	index = 0
	Variable intens, BGval
		
	Duplicate/O wave2bnorm, dup_wave
	Make/O/N=(Dimsize(dup_wave,0)) oneDnorm, BGwav	
	oneDnorm[]=0
	Variable num
	for(m=0; m<Dimsize(dup_wave,0); m+=1)
		num =0
		for(n=0; n<Dimsize(dup_wave,1)-1; n+=1)
			oneDnorm[m]+=dup_wave[m][n]
			num+=1
		endfor
		oneDnorm[m] = oneDnorm[m]/num 
		num =0
		for(n=Dimsize(dup_wave,1)-50; n<Dimsize(dup_wave,1)-1; n+=1)
			BGwav[m]+=dup_wave[m][n]
			num+=1
		endfor
		BGwav[m] = BGwav[m]/num 
	endfor
	
	for(m=0; m<Dimsize(dup_wave,0); m+=1)
		for(n=0; n<Dimsize(dup_wave,1); n+=1)
			dup_wave[m][n]= (dup_wave[m][n]-BGwav[m])/oneDnorm[m]
		endfor
	endfor
	Duplicate/O dup_wave wave2bnorm											//	
	
	String wav_name= "mEDM_norm"
	
	Duplicate/O wave2bnorm $wav_name
	

//// ------------------ WAVE2BNORMALIZED CORRECTION
//		
//	Duplicate/O slitfunction step_shift
//													//
//	step_shift-=V_min								// Calculate the number of steps to shift each gold EDC
//	step_shift/=Dimdelta(wave2bcorrnorm,0)				//
//		
//	Duplicate/O wave2bnorm corr_norm_wav
//
//	index = 0	
//	do
//			step=floor(step_shift[index]+0.5)
//			//step=step_shift[index]						//				   1.5< <2.5 2 stepsize shift, etc.
//			step_shift[index]=step
//			slice_norm= wave2bnorm[p][index]
//			Duplicate/O slice_norm slice_corr
//			slice_corr=slice_norm[p+(step_shift[index])]
//			corr_norm_wav[][index]=slice_corr[p]
//			index+=1
//	while(index<DimSize(step_shift,0))
//		
//	wav_name= "mEDM_NC"
//	Duplicate/O corr_norm_wav, $wav_name
	wav_name= "wave2bnorm"
	MatrixTranspose $wav_name
	endif
	Duplicate/O $wav_name, mEDM, EDMshow
	update_var("bla",0,"bla","bla")
End

Function FermiEDM(coeff, x) : FitFunc 										// Fitting function: Fermi Dirac distribution
		Wave coeff														// coeff[0] = position, coeff[1] = intensity 
		Variable x														// coeff[2] = background, coeff[3] = width, coeff[4]- Bg slope 
		return (coeff[1]*(1+coeff[4]*(x-coeff[0])) / (1 + exp((x - coeff[0]) / (0.000865 * coeff[3] ) ) ) ) + coeff[2] 
End

threadsafe Function FermiEDM2(coeff, x) : FitFunc 										// Fitting function: Fermi Dirac distribution
		Wave coeff														// coeff[0] = position, coeff[1] = intensity 
		Variable x														// coeff[2] = background, coeff[3] = width 
		return ( coeff[1] / (1 + exp((x - coeff[0]) / (0.0000865 * coeff[3] ) ) ) ) + coeff[2] 
End

Function change_k_EDM(ctrlName ):buttonControl	//does the actual fitting
		String ctrlName
		Wave EDMshow
		
//		Duplicate/O EDMshow root:manip:EDM
//		Duplicate/O EDMshow root:manip:mEDM
//		Duplicate/O root:manip:EDM root:manip:EDMshow
//		Duplicate/O root:manip:EDM root:manip:kEDM
//	
//		Matrixtranspose mEDM
		put_k_EDM()
End

Function EDC_MDC (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr 
	
	Variable/G old_osc1,old_osc2
	NVAR bg_offset, bg_slope, bg_sq, bg_cub, bg_shift, bg_qu, edcmdc, polynom, p_num
	SVAR image_name
	String fol,fole,folm
	fol = "root:Fitresults:"+ image_name
	fole =  "root:Fitresults:"+ image_name +":EDC"
	folm =  "root:Fitresults:"+ image_name +":MDC"
	if(DataFolderExists(fol)==0)
		NewDataFolder/O $fol
		NewDataFolder/O $fole
		NewDataFolder/O $folm
	endif
	if (popNum == 1)
		edcmdc= 0
		
		Duplicate/O MDCcut dupwav
		Make/O/N=(DimSize(dupwav,0)) MDC
		SetScale/P x DimOffset(dupwav,0),DimDelta(dupwav,0),"", 'MDC'
		MDC []=dupwav[p][0]										//first MDC to be displayed..is a copy of MDCcut
	
		Make/O/N=(DimSize(dupwav,0)) Init__fit						//Wave for initial fitting input
		SetScale/P x DimOffset(dupwav,0),DimDelta(dupwav,0),"", 'Init__fit'
		Removefromgraph/Z/W=manipEDM#MDC Init__fit, Osc_MDC_1,Osc_MDC_2,Osc_MDC_3,Osc_MDC_4,Osc_MDC_5,Osc_MDC_6,Osc_MDC_7,Osc_MDC_8,Osc_MDC_9,Osc_MDC_10, line_mdc
		Removefromgraph/Z/W=manipEDM#EDC Init__fit, Osc_EDC_1,Osc_EDC_2,Osc_EDC_3,Osc_EDC_4,Osc_EDC_5,Osc_EDC_6,Osc_EDC_7,Osc_EDC_8,Osc_EDC_9,Osc_EDC_10, line_edc
		Appendtograph/C=(1,4,52428)/W=manipEDM#MDC Init__fit
	else
		edcmdc = 1
		
		Duplicate/O EDCcut dupwav
		Make/O/N=(DimSize(dupwav,0)) EDC
		SetScale/P x DimOffset(dupwav,0),DimDelta(dupwav,0),"", 'EDC'
		EDC []=dupwav[p][0]										//first MDC to be displayed..is a copy of MDCcut
	
		Make/O/N=(DimSize(dupwav,0)) Init__fit						//Wave for initial fitting input
		SetScale/P x DimOffset(dupwav,0),DimDelta(dupwav,0),"", 'Init__fit'
		
		Removefromgraph/Z/W=manipEDM#MDC Init__fit, Osc_MDC_1,Osc_MDC_2,Osc_MDC_3,Osc_MDC_4,Osc_MDC_5,Osc_MDC_6,Osc_MDC_7,Osc_MDC_8,Osc_MDC_9,Osc_MDC_10, line_mdc
		Removefromgraph/Z/W=manipEDM#EDC Init__fit, Osc_EDC_1,Osc_EDC_2,Osc_EDC_3,Osc_EDC_4,Osc_EDC_5,Osc_EDC_6,Osc_EDC_7,Osc_EDC_8,Osc_EDC_9,Osc_EDC_10, line_edc
		Appendtograph/C=(1,4,52428)/W=manipEDM#EDC Init__fit
	endif 	
	
	num_lor("bla",p_num,"bla","bla")
	updat_shape("bla",1,"bla")
	if (edcmdc==0)
			Cursor/A=1/C=(0,0,0)/W=manipEDM#MDC A MDCcut -3.285//Dimoffset(MDCcut,0)+20*Dimdelta(MDCcut,0)
			Cursor/A=1/C=(0,0,0)/W=manipEDM#MDC B MDCcut 1.6459//Dimoffset(MDCcut,0)+50*Dimdelta(MDCcut,0)
	else
			Cursor/A=1/C=(0,0,0)/W=manipEDM#EDC A EDCcut Dimoffset(EDCcut,0)+8*Dimdelta(EDCcut,0)
			Cursor/A=1/C=(0,0,0)/W=manipEDM#EDC B EDCcut Dimoffset(EDCcut,0)+68*Dimdelta(EDCcut,0)
	endif
End


Function updat_shape (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum // which item is currently selected (1-based)
	String popStr // contents of current popup item as string77
	NVAR p_num, p_amount, polynom, bg_offset, bg_slope, bg_shift, bg_sq, bg_cub, bg_qu, edcmdc
	Wave osc_shape, Fit_para, EDCcut, MDCcut
	Variable cnt,a
	
	if (popNum == 1)
		if ((osc_shape[p_num-1] != 0)&&(osc_shape[p_num-1] != 3)&&(osc_shape[p_num-1] != 4))
			cnt=5
			for (a=0;a<p_num;a+=1)
				if ((osc_shape[a] != 0)&&(osc_shape[a] != 4))
					cnt+=4
				else
					cnt+=3	
				endif
			endfor 	
			Deletepoints cnt,1,Fit_para
		endif
		
		if (osc_shape[p_num-1] == 3)
			polynom = 0
		endif
		osc_shape[p_num-1]= 0
	elseif(popNum == 2)
		if ((osc_shape[p_num-1] != 1)&&(osc_shape[p_num-1] != 2)&&(osc_shape[p_num-1] != 5))
			cnt=6
			for (a=0;a<=(p_num-1);a+=1)
				if ((osc_shape[a] != 0)&&(osc_shape[a] != 4))
					cnt+=4
				else
					cnt+=3	
				endif
			endfor 
			Insertpoints cnt,1,Fit_para
		endif
		if (osc_shape[p_num-1] == 3)
			polynom = 0
		endif
		osc_shape[p_num-1] = 1
	elseif(popNum == 3)
		if ((osc_shape[p_num-1] != 1)&&(osc_shape[p_num-1] != 2)&&(osc_shape[p_num-1] != 5))
			cnt=6
			for (a=0;a<=p_num-1;a+=1)
				if ((osc_shape[a] != 0)&&(osc_shape[a] != 4))
					cnt+=4
				else
					cnt+=3	
				endif
			endfor 
			Insertpoints cnt,1,Fit_para
		endif
		if (osc_shape[p_num-1] == 3)
			polynom = 0
		endif
		osc_shape[p_num-1] = 2
	elseif(popNum ==4)
		if ((osc_shape[p_num-1] != 0)&&(osc_shape[p_num-1] != 3)&&(osc_shape[p_num-1] != 4))
			cnt=5
			for (a=0;a<p_num;a+=1)
				if ((osc_shape[a] != 0)&&(osc_shape[a] != 4))
					cnt+=4
				else
					cnt+=3	
				endif
			endfor 
			
			Deletepoints cnt,1,Fit_para
		endif
		
		osc_shape[p_num-1] = 3
		Fit_para = 0
		Fit_para[0]=bg_offset
		Fit_para[1]=bg_slope
		Fit_para[2]=bg_shift
		Fit_para[3]=bg_sq
		Fit_para[4]=bg_cub
		Fit_para[5]=bg_qu
		polynom = 1
	else
		if ((osc_shape[p_num-1] != 0)&&(osc_shape[p_num-1] != 3)&&(osc_shape[p_num-1] != 4))
			cnt=5
			for (a=0;a<p_num;a+=1)
				if ((osc_shape[a] != 0)&&(osc_shape[a] != 4))
					cnt+=4
				else
					cnt+=3	
				endif
			endfor 	
			Deletepoints cnt,1,Fit_para
		endif
		
		if (osc_shape[p_num-1] == 3)
			polynom = 0
		endif
		osc_shape[p_num-1]= 4	
	endif
	
End

Function colortopowave3 (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum // which item is currently selected (1-based)
	String popStr // contents of current popup item as string
	SVAR colorscheme
	NVAR imselect, contrast, brightness
	contrast = 0
	brightness = 0
	colorscheme = popStr
	string tempwavename	
	if (imselect ==0)
		tempwavename = "EDMshow"
		ModifyImage/W=manipEDM#image  $tempwavename ctab= {*,*,$colorscheme,0}
	else 	
		tempwavename = "dk2EDM"
		ModifyImage/W=manipEDM#image2  $tempwavename ctab= {*,*,$colorscheme,0}
	endif
End

Function reversecolor3 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked // 1 if selected, 0 if not
	NVAR contrast, brightness,imselect
	SVAR colorscheme
	string tempwavename
   if (checked == 1) 	
	if (imselect ==0)
		tempwavename = "EDMshow"
		if ((contrast==0)&&(brightness == 0))
		ModifyImage/W=manipEDM#image  $tempwavename ctab= {*,*,$colorscheme,1}
		else
			fixcolorofimage3()
		endif
	else 	
		tempwavename = "dk2EDM"
		if ((contrast==0)&&(brightness == 0))
			ModifyImage/W=manipEDM#image2  $tempwavename ctab= {*,*,$colorscheme,1}
		else
			fixcolorofimage3()
		endif
	endif
   else
   	if (imselect ==0)
		tempwavename = "EDMshow"
		if ((contrast==0)&&(brightness == 0))
		ModifyImage/W=manipEDM#image  $tempwavename ctab= {*,*,$colorscheme,0}
		else
			fixcolorofimage3()
		endif
	else 	
		tempwavename = "dk2EDM"
		if ((contrast==0)&&(brightness == 0))
			ModifyImage/W=manipEDM#image2  $tempwavename ctab= {*,*,$colorscheme,0}
		else
			fixcolorofimage3()
		endif
	endif
	endif	
End

Function selectimg3(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked // 1 if selected, 0 if not
	fixcolorofimage3()
End

Function revertcolor3 (ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked // 1 if selected, 0 if not
	fixcolorofimage3()
End

Function fixcolorofimage3()
	NVAR reversecolorvar,revertcolorvar, imselect //de variabele die reverse color regelt
	SVAR colorscheme //de string die de colortable beschrijft
	SVAR image_name
	NVAR contrast, brightness, topoaverage, topodev
	string tempwavename	
	if (imselect ==0)
		tempwavename = "EDMshow"
		//SetDataFolder root:
		WaveStats/Q/Z $tempwavename
		topoaverage = V_avg; topodev = (V_max + V_min)/2
		if (revertcolorvar == 0)
			ModifyImage/W=manipEDM#image  $tempwavename ctab= {(topodev*brightness-topodev*contrast), (topoaverage*brightness+topodev*contrast),$colorscheme,reversecolorvar}
		else
			ModifyImage/W=manipEDM#image  $tempwavename ctab= {*,*,$colorscheme,0}
		endif
	else 	
		tempwavename = "dk2EDM"
		//SetDataFolder root:
		WaveStats/Q/Z $tempwavename
		topoaverage = V_avg; topodev = (V_max - V_min)/2
		if (revertcolorvar == 0)
			ModifyImage/W=manipEDM#image2  $tempwavename ctab= {(topodev*brightness-topodev*contrast), (topoaverage*brightness+topodev*contrast),$colorscheme,reversecolorvar}
		else
			ModifyImage/W=manipEDM#image2  $tempwavename ctab= {*,*,$colorscheme,0}
		endif
	endif	
End

Function save_EDM2(ctrlName): ButtonControl
	String ctrlName
	SVAR image_name
	String EDMname = image_name
	
	
//	Prompt EDMname,"Name:"
//	DoPrompt "EDM name:", EDMname
	Duplicate/O EDMshow root:EDMs:$EDMname
	
end

Function div_fe(ctrlName,varNum,varStr,varName) : SetVariableControl  
		String ctrlName
		Variable varNum
		String varStr
		String varName
	
	NVAR Temp, res
	Wave EDM
	
	Variable te = Temp/11604 //convert to eV
	Variable Int, re, he, a, b
	re =res/1000 //convert to eV
	Duplicate/O EDM EDMdiv
	
	Make/O/N=(Dimsize(EDM,1)) fe
	Setscale/P x,Dimoffset(EDM,1),Dimdelta(EDM,1),"" fe
	
	Make/O/N=60000 gaus, fet
	Setscale/I x,-1.5,1.5,"" gaus, fet
	fet=1/(exp(x/te)+1)
	gaus = exp(-(x^2/(2*re^2)))
	
	convolve/A fet, gaus
	he = gaus[2000]
	fet[]= gaus[p]/he
	
	Interpolate2/I=3/Y=fe fet 
	Wavestats/Q EDM
	
	For (a=0; a<Dimsize(EDMdiv,0);a+=1)
		for (b=0; b< Dimsize(EDMdiv,1); b+=1)
			Int = EDM[a][b]/fe[b]
			if ((Int < V_max)&&(Int > 0))
				EDMdiv[a][b] = Int
			else 
				EDMdiv[a][b] = 0
			endif	
		endfor
	endfor
	Duplicate/O EDMdiv EDMshow
end

Function save_EDC2(ctrlName): ButtonControl
	String ctrlName
	String EDMname
	
	Prompt EDMname,"Name:"
	DoPrompt "EDC/MDC name:", EDMname
	String xname,yname
	xname="root:EDCs:"+EDMname+"_EDC"
	yname="root:EDCs:"+EDMname+"_MDC"
	
	Duplicate/O EDCcut $xname
	Duplicate/O MDCcut $yname
end

function crop(ctrlName) : ButtonControl
	String ctrlName
	Variable/G crsax,crsay,crsbx,crsby
	crsax = pcsr(A, "manipEDM#image")
	crsbx = pcsr(B, "manipEDM#image")
	crsay = qcsr(A, "manipEDM#image")
	crsby = qcsr(B, "manipEDM#image")
	
	Duplicate/O/R=[crsax,crsbx][crsay,crsby] EDMshow temp_EDM
	Duplicate/O temp_EDM EDMshow   
	SetVariable EDCslice_but,limits={0,Dimsize(EDMshow,0),1},value= root:manip:EDC_slice
	SetVariable MDCslice_but,limits={0,DimSize(EDMshow,1),1},value= root:manip:MDC_slice
	SetAxis /W=manipEDM#image bottom, Dimoffset(EDMshow,0),DimOffset(EDMshow,0)+(DimSize(EDMshow,0)-1)*DimDelta(EDMshow,0)
	SetAxis /W=manipEDM#image left, Dimoffset(EDMshow,1),DimOffset(EDMshow,1)+(DimSize(EDMshow,1)-1)*DimDelta(EDMshow,1)
end

function uncrop(ctrlName) : ButtonControl
	String ctrlName
	
	Duplicate/O kEDM EDMshow
	//Duplicate/O EDMshow kEDM  
	SetVariable EDCslice_but,limits={0,Dimsize(EDMshow,0),1},value= root:manip:EDC_slice
	SetVariable MDCslice_but,limits={0,DimSize(EDMshow,1),1},value= root:manip:MDC_slice
	SetAxis /W=manipEDM#image bottom, Dimoffset(EDMshow,0),DimOffset(EDMshow,0)+(DimSize(EDMshow,0)-1)*DimDelta(EDMshow,0)
	SetAxis /W=manipEDM#image left, Dimoffset(EDMshow,1),DimOffset(EDMshow,1)+(DimSize(EDMshow,1)-1)*DimDelta(EDMshow,1)
end

Function polshift(ctrlName,varNum,varStr,varName) : SetVariableControl  
		String ctrlName
		Variable varNum
		String varStr
		String varName
		
		NVAR row
		NVAR pol_shift
		Duplicate/O EDM mEDM
		SetScale/P x, Dimoffset(EDM,0)-pol_shift,Dimdelta(EDM,0),"", mEDM
		Duplicate/O mEDM EDMshow
		SetVariable EDCslice_but,limits={0,Dimsize(EDMshow,0),1},value= root:manip:EDC_slice
		SetVariable MDCslice_but,limits={0,DimSize(EDMshow,1),1},value= root:manip:MDC_slice
		SetAxis /W=manipEDM#image bottom, Dimoffset(EDMshow,0),DimOffset(EDMshow,0)+(DimSize(EDMshow,0)-1)*DimDelta(EDMshow,0)
		SetAxis /W=manipEDM#image left, Dimoffset(EDMshow,1),DimOffset(EDMshow,1)+(DimSize(EDMshow,1)-1)*DimDelta(EDMshow,1)
		Make_MDCs("bla",row,"bla","bla")
end

function der_EDM(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVAR opt
	NVAR smothk, smothe
	Variable n,m
	
	Duplicate/O EDMshow sk_EDM
	
	if (cmpstr("smok",ctrlName)==0)
		opt=0
		smooth/DIM=0/S=4 smothk, sk_EDM
	
		Make/O/N=(Dimsize(sk_EDM,0)-2,Dimsize(sk_EDM,1)) dkEDM
	
		For (n =0; n<Dimsize(dkEDM,0);n+=1)
			For (m=0; m<Dimsize(dkEDM,1);m+=1)
			
				dkEDM[n][m] = (sk_EDM[n+1][m]-sk_EDM[n][m])/DimDelta(sk_EDM,0)
	
			endfor
		endfor 
		
		smooth/DIM=0/S=4 smothk, dkEDM
	
		Make/O/N=(Dimsize(dkEDM,0)-2,Dimsize(dkEDM,1)) dk2EDM
	
		For (n =0; n<Dimsize(dk2EDM,0);n+=1)
			For (m=0; m<Dimsize(dk2EDM,1);m+=1)
			
				dk2EDM[n][m] = (dkEDM[n+1][m]-dkEDM[n][m])/DimDelta(dkEDM,0)
	
			endfor
		endfor 
		
		
		
		Setscale/P x, Dimoffset(sk_EDM,0)+2*Dimdelta(sk_EDM,0),Dimdelta(sk_EDM,0),"" dk2EDM
		Setscale/P y, Dimoffset(sk_EDM,1),Dimdelta(sk_EDM,1),"" dk2EDM
	else
		opt=1
		smooth/DIM=1/S=4 smothe, sk_EDM
		
		Make/O/N=(Dimsize(sk_EDM,0),Dimsize(sk_EDM,1)-2) dkEDM
	
		
	
		For (n =0; n<Dimsize(dkEDM,0);n+=1)
			For (m=0; m<Dimsize(dkEDM,1);m+=1)
			
				dkEDM[n][m] = (sk_EDM[n][m+1]-sk_EDM[n][m])/DimDelta(sk_EDM,1)
	
			endfor
		endfor 
		
		smooth/DIM=1/S=4 smothe, dkEDM
		
		Make/O/N=(Dimsize(dkEDM,0),Dimsize(dkEDM,1)-2) dk2EDM
	
		
	
		For (n =0; n<Dimsize(dk2EDM,0);n+=1)
			For (m=0; m<Dimsize(dk2EDM,1);m+=1)
			
				dk2EDM[n][m] = (dkEDM[n][m+1]-dkEDM[n][m])/DimDelta(dkEDM,1)
	
			endfor
		endfor
		
		Setscale/P x, Dimoffset(sk_EDM,0),Dimdelta(sk_EDM,0),"" dk2EDM
		Setscale/P y, Dimoffset(sk_EDM,1)+2*Dimdelta(sk_EDM,1),Dimdelta(sk_EDM,1),"" dk2EDM
	endif
	
	SetAxis /W=manipEDM#image2 bottom, Dimoffset(dk2EDM,0),DimOffset(dk2EDM,0)+(DimSize(dk2EDM,0)-1)*DimDelta(dk2EDM,0)
	SetAxis /W=manipEDM#image2 left, Dimoffset(dk2EDM,1),DimOffset(dk2EDM,1)+(DimSize(dk2EDM,1)-1)*DimDelta(dk2EDM,1)
end


Function updat_fit(ctrlName,varNum,varStr,varName) : SetVariableControl  //adapts fit to newly defined lorentzian position
		String ctrlName
		Variable varNum
		String varStr
		String varName
		NVAR l_pos,l_int,l_width, l_mix, p_num, bg_offset, bg_slope,bg_sq, bg_cub, bg_shift, bg_qu, edcmdc
		Wave f_Fit_para = Fit_para 
		//Duplicate/O f_Fit_para recal_Init__fit
		Wave osc_shape
		
		if (stringmatch(ctrlName,"dl"))
			bg_offset=varNum
			f_Fit_para [0]=bg_offset
		endif
		
		if (stringmatch(ctrlName,"el"))
			bg_slope=varNum
			f_Fit_para [1]=bg_slope
		endif
		
		if (stringmatch(ctrlName,"dl3"))
			bg_shift=varNum
			f_Fit_para [2]=bg_shift
		endif
		
		if (stringmatch(ctrlName,"dl2"))
			bg_sq=varNum
			f_Fit_para [3]=bg_sq
		endif
		
		if (stringmatch(ctrlName,"el2"))
			bg_cub=varNum
			f_Fit_para [4]=bg_cub
		endif
		
		if (stringmatch(ctrlName,"el3"))
			bg_qu=varNum
			f_Fit_para [5]=bg_qu
		endif
		
		Variable a 
		Variable cnt = 6
		for (a=0;a<(p_num-1);a+=1)
			if ((osc_shape[a] == 0)||(osc_shape[a] == 4))
				cnt += 3
			else
				cnt += 4
			endif
		endfor
		
		if (stringmatch(ctrlName,"hl"))
			l_pos=varNum
			f_Fit_para [cnt]=l_pos
		endif
		
		if(stringmatch(ctrlName,"il"))
			l_int=varNum
			f_Fit_para [cnt+1]=l_int
		endif
		
		if(stringmatch(ctrlName,"jl"))
			l_width=varNum
			f_Fit_para [cnt+2]=l_width
		endif		
		
	
		if(stringmatch(ctrlName,"jl2")&&((osc_shape[p_num-1] ==1)||(osc_shape[p_num-1] ==2)))
			
			l_mix=varNum
			f_Fit_para [cnt+3]=l_mix
		endif		
		
		Duplicate/O f_Fit_para recal_Init__fit //Store the original parameters
		
		Make_fit_display_EDM()	//calls function making the displayed fit wave	
			
End
	
Function Make_fit_display_EDM()	// function making the displayed fit wave
		Wave f_Fit_para = Fit_para
		Wave f_Init__fit = Init__fit
		Wave EDCcut,MDCcut
		NVAR p_amount,edcmdc, polynom
				
		Variable x, a, b,i
		Wave osc_shape
		b=0
		x=0
		if (polynom ==0)		
			do														//making the total fit (ie sum of lors)
				x=Dimoffset(f_Init__fit,0)+Dimdelta(f_Init__fit,0)*b
				Variable xprime = x - f_Fit_para[2] 
				f_Init__fit[b]=f_Fit_para[0]+xprime*f_Fit_para[1]+f_Fit_para[3]*xprime^2+f_Fit_para[4]*xprime^3+f_Fit_para[5]*xprime^4
				a=6
				for (i=0; i < p_amount; i+=1)
					if (osc_shape[i] == 0)
						f_Init__fit[b]+= (f_Fit_para[a+1]*0.25*f_Fit_para[a+2]*f_Fit_para[a+2])/(( x-f_Fit_para[a])^2+0.5*f_Fit_para[a+2]*0.5*f_Fit_para[a+2])
						a+=3
					elseif(osc_shape[i] == 1)
						f_Init__fit[b] += f_Fit_para[a+1]*VoigtV2(f_Fit_para[a+2]*(x-f_Fit_para[a]),f_Fit_para[a+3])
						a+=4
					elseif(osc_shape[i] == 2)
						f_Init__fit[b] += f_Fit_para[a+1]*cos(pi*f_Fit_para[a+3]/2+(1-f_Fit_para[a+3])*atan((x-f_Fit_para[a])/f_Fit_para[a+2]))/((x-f_Fit_para[a])^2+f_Fit_para[a+2]*f_Fit_para[a+2])^(0.5-0.5*f_Fit_para[a+3])
						a+=4
					elseif(osc_shape[i]== 4)
						f_Init__fit[b]+= f_Fit_para[a+1]*exp( -(x-f_Fit_para[a])^2/(2*f_Fit_para[a+2]*f_Fit_para[a+2]))
						a+=3
					endif
				endfor
				b+=1
			while (b<Dimsize(f_Init__fit,0))
		else
			
			do														//making the total fit (ie sum of lors)
				x=Dimoffset(f_Init__fit,0)+Dimdelta(f_Init__fit,0)*b
				xprime = x - f_Fit_para[2] 
				f_Init__fit[b]=f_Fit_para[0]+xprime*f_Fit_para[1]+f_Fit_para[3]*xprime^2+f_Fit_para[4]*xprime^3+f_Fit_para[5]*xprime^4
				b+=1
			while (b<Dimsize(f_Init__fit,0))
		endif	
		
		Make/O/N=(DimSize(f_Init__fit,0)) lor, line_add
		SetScale/P x DimOffset(f_Init__fit,0),DimDelta(f_Init__fit,0),"", 'lor', 'line_add'
		x=0
		String name
		if (polynom==0)
			a=6
			for (i=0; i < p_amount; i+=1)
				b=0
				lor=0
				do
					x=Dimoffset(lor,0)+Dimdelta(lor,0)*b
					xprime = x - f_Fit_para[2]
					line_add[b] = f_Fit_para[0]+xprime*f_Fit_para[1]+f_Fit_para[3]*xprime^2+f_Fit_para[4]*xprime^3+f_Fit_para[5]*xprime^4
					if (osc_shape[i] == 0)
						lor[b]+= (f_Fit_para[a+1]*0.25*f_Fit_para[a+2]*f_Fit_para[a+2])/(( x-f_Fit_para[a])^2+0.5*f_Fit_para[a+2]*0.5*f_Fit_para[a+2])
					elseif(osc_shape[i] == 1)
						lor[b] += f_Fit_para[a+1]*VoigtV2(f_Fit_para[a+2]*(x-f_Fit_para[a]),f_Fit_para[a+3])
					elseif(osc_shape[i] == 2)
						lor[b] += f_Fit_para[a+1]*cos(pi*f_Fit_para[a+3]/2+(1-f_Fit_para[a+3])*atan((x-f_Fit_para[a])/f_Fit_para[a+2]))/((x-f_Fit_para[a])^2+f_Fit_para[a+2]*f_Fit_para[a+2])^(0.5-0.5*f_Fit_para[a+3])
					else
						lor[b] += f_Fit_para[a+1]*exp( -(x-f_Fit_para[a])^2/(2*f_Fit_para[a+2]*f_Fit_para[a+2]))
					endif
					b+=1
				while (b<Dimsize(lor,0))

				if (edcmdc==0)
					name="Osc_MDC_"+Num2Str(i+1)
					Duplicate/O lor $name
					Removefromgraph/Z/W=manipEDM#MDC $name
					Appendtograph/W=manipEDM#MDC $name
					ModifyGraph/W=manipEDM#MDC lstyle($name)=3,rgb($name)=(0+65000/p_amount*i,65000-65000/p_amount*i,0)
				else
					name="Osc_EDC_"+Num2Str(i+1)
					Duplicate/O lor $name
					Removefromgraph/Z/W=manipEDM#EDC $name
					Appendtograph/W=manipEDM#EDC $name
					ModifyGraph/W=manipEDM#EDC lstyle($name)=3,rgb($name)=(0+65000/p_amount*i,65000-65000/p_amount*i,0)
				endif
			
				DoUpdate
			
				if (osc_shape[i] == 0)
					a+=3
				elseif(osc_shape[i] == 1)
					a+=4
				elseif(osc_shape[i] == 2)
					a+=4
				else
					a+=3
				endif
			endfor
		else
			b=0
			do
				x=Dimoffset(line_add,0)+Dimdelta(line_add,0)*b
				xprime = x - f_Fit_para[2]
				line_add[b] = f_Fit_para[0]+xprime*f_Fit_para[1]+f_Fit_para[3]*xprime^2+f_Fit_para[4]*xprime^3+f_Fit_para[5]*xprime^4
				b+=1
				
			while (b<Dimsize(line_add,0))
		endif
		
		if (edcmdc==0)
			Duplicate/O line_add line_mdc
			Removefromgraph/W=manipEDM#MDC/Z line_mdc
			Removefromgraph/W=manipEDM#EDC/Z line_edc
			Appendtograph/W=manipEDM#MDC  line_mdc
			ModifyGraph/W=manipEDM#MDC lstyle(line_mdc)=3,rgb(line_mdc)=(0,0,0)
			Wavestats/Q MDCcut
			SetAxis/W=manipEDM#MDC left,0,V_max+(0.1*v_max)
		else
			Duplicate/O line_add line_edc
			Removefromgraph/W=manipEDM#MDC/Z line_mdc
			Removefromgraph/W=manipEDM#EDC/Z line_edc
			Appendtograph/W=manipEDM#EDC  line_edc
			ModifyGraph/W=manipEDM#EDC lstyle(line_edc)=3,rgb(line_edc)=(0,0,0)
			Wavestats/Q EDCcut
			SetAxis/W=manipEDM#EDC left,0,V_max+(0.1*v_max)
		endif
End
		

Function show_input(ctrlName,varNum,varStr,varName) : SetVariableControl  //returns correct input value if user switches 'active peak'
		String ctrlName
		Variable varNum
		String varStr
		String varName
		NVAR l_width, l_int, l_pos, l_mix, p_num, bg_offset, bg_shift, bg_slope, bg_sq, bg_cub, bg_qu
		Wave f_Fit_para =Fit_para
		Wave osc_shape
		
		bg_offset = f_Fit_para[0]
		bg_slope = f_Fit_para[1]
		bg_shift = f_Fit_para[2]
		bg_sq = f_Fit_para[3]
		bg_cub = f_Fit_para[4]
		bg_qu = f_Fit_para[5]
		
		p_num=varNum
		Variable a 
		Variable cnt = 6
		for (a=1;a<p_num;a+=1)
			if ((osc_shape[a-1] == 0)||(osc_shape[a-1] == 4))
				cnt += 3
			else
				cnt += 4
			endif
		endfor
		
		
		if (osc_shape[p_num-1] == 0)
			PopupMenu kl, mode = 1
			l_pos=f_Fit_para[cnt]
			l_int=f_Fit_para[cnt+1]
			l_width=f_Fit_para[cnt+2]
			l_mix = 0
		elseif (osc_shape[p_num-1] == 1)
			PopupMenu kl, mode = 2
			l_pos=f_Fit_para[cnt]
			l_int=f_Fit_para[cnt+1]
			l_width=f_Fit_para[cnt+2]
			l_mix = f_Fit_para[cnt+3]
		elseif (osc_shape[p_num-1] == 2)
			PopupMenu kl, mode = 3
			l_pos=f_Fit_para[cnt]
			l_int=f_Fit_para[cnt+1]
			l_width=f_Fit_para[cnt+2]
			l_mix = f_Fit_para[cnt+3]
		elseif(osc_shape[p_num-1] == 4)
			PopupMenu kl, mode = 5
			l_pos=f_Fit_para[cnt]
			l_int=f_Fit_para[cnt+1]
			l_width=f_Fit_para[cnt+2]
			l_mix = 0
		else
			PopupMenu kl, mode = 4
		endif
End
	
Function num_lor(ctrlName,varNum,varStr,varName) : SetVariableControl //gives the amount of lorentzians, creates the wave containing fit para's, etc.
		String ctrlName
		Variable varNum
		String varStr
		String varName
		
		NVAR p_amount, max_lor, p_num, edcmdc, fitedc_cnt, fitmdc_cnt
		Wave osc_shape
		
		Variable cnt,a
		Redimension/N=(p_amount) osc_shape
		cnt=0
		for (a=0;a<p_amount;a+=1)
			if ((osc_shape[a] != 0)&&(osc_shape[a] != 3)&&(osc_shape[a] != 4))
				cnt+=1
			endif
		endfor
		String name
		Make/O/N=(6+3*(p_amount-cnt)+4*cnt) Fit_para	
								//makes wave containing correct number of peak parameters		
		for (a=0; a<max_lor;a+=1)
			if (edcmdc == 0)
				name="Osc_MDC_"+Num2Str(a+1)
				Removefromgraph/Z/W=manipEDM#MDC $name
			else
				name="Osc_EDC_"+Num2Str(a+1)
				Removefromgraph/Z/W=manipEDM#EDC $name
			endif
		endfor	
		max_lor = varNum
		SetVariable gl, limits={1,max_lor,1}, value= p_num;DelayUpdate
		If (p_num>max_lor)
			p_num=max_lor
		endif
		
		for (a=0;a<max_lor;a+=1)
			if (edcmdc == 0)
				name="Osc_MDC_"+Num2Str(a+1)
				if (exists(name))
					Appendtograph/W=manipEDM#MDC $name
					ModifyGraph/W=manipEDM#MDC lstyle($name)=3,rgb($name)=(0+65000/p_amount*a,65000-65000/p_amount*a,0)
				endif
			else
				name="Osc_EDC_"+Num2Str(a+1)
				if (exists(name))
					
					Appendtograph/W=manipEDM#EDC $name
					ModifyGraph/W=manipEDM#EDC lstyle($name)=3,rgb($name)=(0+65000/p_amount*a,65000-65000/p_amount*a,0)
				endif
			endif
		endfor
		if (edcmdc == 0)
			if (Dimsize(MDC_result_wav,1) >= 3)
				 fitmdc_cnt+=1
			endif
		else
			if (Dimsize(EDC_result_wav,1) >= 3)
				 fitedc_cnt+=1
			endif
		endif
		SVAR name1, name3
		name1 = ""
		name3 = ""
		Killwaves/Z MDC_result_wav,MDC_error_wav,EDC_result_wav,EDC_error_wav  
		
End


Function get_folder_name(ctrlName,popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SetDatafolder root:manip
	String/G datafolder = popStr
	SVAR waveslist
	
	if (!stringmatch(datafolder,"root"))
		SetDatafolder root:$datafolder
		waveslist = WaveList("*", ";", "DIMS:2")
	else
		SetDataFolder root:
	endif
end

Function low_val(ctrlName) : ButtonControl
	String ctrlName
	SetDataFolder root:manip
	NVAR start,row
	start=row
end

Function val_go(ctrlName) : ButtonControl
	String ctrlName
	SetDataFolder root:manip
	NVAR start, stop, high, bg_offset, bg_slope, bg_sq, bg_cub, bg_shift, bg_qu, MDC_slice
	Wave EDMshow
	
	//row = round((varNum - DimOffset(EDM,1))/DimDelta(EDM,1))
	
    Make/O/N=(DimSize(EDMshow,0)) MDCcut, MDClinex, MDCliney
	SetScale/P x, DimOffset(EDMshow,0), DimDelta(EDMshow,0), MDCcut
	
	if (stringmatch(ctrlname,"al2"))
		MDCcut[] = EDMshow[p][start]
		MDCliney[] = DimOffset(EDMshow,1)+start*DimDelta(EDMshow,1)
		MDC_slice = start
		DoUpdate
	endif
	
	if(stringmatch(ctrlname,"bl2"))
		MDCcut[] = EDMshow[p][stop]
		MDCliney[] = DimOffset(EDMshow,1)+stop*DimDelta(EDMshow,1)
		MDC_slice = stop
	endif
	
	MDClinex[] = DimOffset(EDMshow,0) + DimDelta(EDMshow,0)*x
	
	Duplicate/O MDCcut dupwav
	Make/O/N=(DimSize(dupwav,0)) MDC
	SetScale/P x DimOffset(dupwav,0),DimDelta(dupwav,0),"", 'MDC'
	MDC []=dupwav[p][0]										//first MDC to be displayed..is a copy of MDCcut
	
	Make/O/N=(DimSize(dupwav,0)) Init__fit						//Wave for initial fitting input
	SetScale/P x DimOffset(dupwav,0),DimDelta(dupwav,0),"", 'Init__fit'
	
	//Make/O/N=(8) Fit_para										//Making wave containing initial fitparameters
	//Wavestats/Z/Q MDC										//to obtain the minimum x-value of first MDC; intial guess for BG
	//high=DimSize(dupwav,1)-1

	//bg_offset=V_min
	
	//Init__fit[]=bg_offset
	//Fit_para[0]=bg_offset
	//Fit_para[1]=bg_slope
	//Fit_para[2]=bg_shift
	//Fit_para[3]=bg_sq
	//Fit_para[4]=bg_cub
	//Fit_para[5]=bg_qu
End

Function update_MDC(val)
	Variable val
	NVAR start, stop, high, bg_offset, bg_slope, bg_sq, bg_cub, bg_shift, bg_qu, MDC_slice
	Wave EDMshow, EDM
	
	//row = round((varNum - DimOffset(EDM,1))/DimDelta(EDM,1))
	
    Make/O/N=(DimSize(EDMshow,0)) MDCcut, MDClinex, MDCliney
	SetScale/P x, DimOffset(EDMshow,0), DimDelta(EDMshow,0), MDCcut
	
	MDCcut[] = EDMshow[p][val]
	MDCliney[] = DimOffset(EDMshow,1)+val*DimDelta(EDMshow,1)
	MDC_slice = val	
	MDClinex[] = DimOffset(EDMshow,0) + DimDelta(EDMshow,0)*x
	Duplicate/O MDCcut dupwav
	Make/O/N=(DimSize(dupwav,0)) MDC
	SetScale/P x DimOffset(dupwav,0),DimDelta(dupwav,0),"", 'MDC'
	MDC []=dupwav[p][0]										//first MDC to be displayed..is a copy of MDCcut
	
	Make/O/N=(DimSize(dupwav,0)) Init__fit						//Wave for initial fitting input
	SetScale/P x DimOffset(dupwav,0),DimDelta(dupwav,0),"", 'Init__fit'
	
	//Make/O/N=(10) Fit_para										//Making wave containing initial fitparameters
	//Wavestats/Z/Q MDC										//to obtain the minimum x-value of first MDC; intial guess for BG
	//high=DimSize(dupwav,1)-1

	//bg_offset=V_min
	
	//Init__fit[]=bg_offset
	//Fit_para[0]=bg_offset
	//Fit_para[1]=bg_slope
	//Fit_para[2]=bg_shift
	//Fit_para[3]=bg_sq
	//Fit_para[4]=bg_cub
	//Fit_para[5]=bg_qu
end

Function high_val(ctrlName) : ButtonControl
	String ctrlName
	SetDataFolder root:manip
	NVAR stop,row
	stop=row
end

Function get_EDM_name(ctrlName,popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	String/G root:manip:image_name  = popStr
	SVAR datafolder = root:manip:datafolder
	String newname = "root:"+datafolder+":"+popStr
	
	Duplicate/O $newname root:manip:EDM
	Duplicate/O $newname root:manip:mEDM
	Duplicate/O root:manip:EDM root:manip:EDMshow
	Duplicate/O root:manip:EDM root:manip:kEDM
//	if (exists("photonenergies")==1)
//	   Duplicate/O/T photonenergies, root:manip:photonenergies
//	endif
	SetDataFolder root:manip
	Variable m, number
	NVAR Ef, pol_shift
	NVAR norm_flag
	norm_flag=0
//	Wave/T photonenergies
//	for (m=0;m<Dimsize(photonenergies,0);m+=1)
//		if (!cmpstr(popstr,photonenergies[m][0]))
//			Ef = str2num(photonenergies[m][1])
//		endif	
//	
//	endfor
//	

////////////////////////////////////////////////////////////////////////////
//This is a temporary bit used in the analysis of BTS221 data from may 2011
////////////////////////////////////////////////////////////////////////////
//	Ef = str2num(photonenergies[popNum-2][0])
//	pol_shift = str2num(photonenergies[popNum-2][1])

	NVAR Avk, Ave
	Avk = abs(DimDelta(EDMshow,0))
	Ave = abs(DimDelta(EDMshow,1)*1000) //in meV
	NVAR edmoff, edmdel
	edmoff = DimOffset(EDMshow,0)
	
	edmdel = DimDelta(EDMshow,0)
	SetVariable avk,limits={Avk,DimSize(EDMshow,0),Avk},value= root:manip:Avk
	SetVariable ave,limits={Ave,DimSize(EDMshow,1),Ave},value= root:manip:Ave
		
	SetVariable EDCslice_but,limits={0,DimSize(EDMshow,0),1},value= root:manip:EDC_slice
	SetVariable MDCslice_but,limits={0,DimSize(EDMshow,1),1},value= root:manip:MDC_slice
	SetVariable edmo,limits={-100,100,DimDelta(EDMshow,0)},value= root:manip:edmoff
	SetAxis /W=manipEDM#image bottom, Dimoffset(EDMshow,0),DimOffset(EDMshow,0)+(DimSize(EDMshow,0)-1)*DimDelta(EDMshow,0)
	SetAxis /W=manipEDM#image left, Dimoffset(EDMshow,1),DimOffset(EDMshow,1)+(DimSize(EDMshow,1)-1)*DimDelta(EDMshow,1)
	RemoveFromGraph
	Make_EDCs("bla",0,"bla","bla")
	Make_MDCs("bla",0,"bla","bla")
	NVAR fitmdc_cnt,fitedc_cnt
	fitmdc_cnt = 1
	fitedc_cnt = 1
	KillWaves/Z MDC_result_wav, MDC_error_wav	,EDC_result_wav, EDC_error_wav
	
//////////////////////////////////////////////////////////////////////////////
////This is a temporary bit used in the analysis of BTS221 data from Feb 2012
//////////////////////////////////////////////////////////////////////////////	
//Make_EDCs("bla",306,"bla","bla")
//EDC_MDC ("bla",2,"bla")
EDM_scale("bla",306,"bla","bla")
Make_MDCs("bla",750,"bla","bla")
end

Function EDM_scale(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	NVAR edmoff,edmdel
	
	SetScale/P x,edmoff,edmdel,"" EDMshow
	SetVariable EDCslice_but,limits={0,DimSize(EDMshow,0),1},value= root:manip:EDC_slice
	SetVariable MDCslice_but,limits={0,DimSize(EDMshow,1),1},value= root:manip:MDC_slice
	
	SetAxis /W=manipEDM#image bottom, Dimoffset(EDMshow,0),DimOffset(EDMshow,0)+(DimSize(EDMshow,0)-1)*DimDelta(EDMshow,0)
	SetAxis /W=manipEDM#image left, Dimoffset(EDMshow,1),DimOffset(EDMshow,1)+(DimSize(EDMshow,1)-1)*DimDelta(EDMshow,1)
	NVAR row
	Make_MDCs("bla",row,"bla","bla")
	
	
	//////////////////////////////////////////////////////////////////////////////
	////This is a temporary bit used in the analysis of SrMnSb2 data from Feb 2012
	//////////////////////////////////////////////////////////////////////////////	

	save_EDM2("bla")
End

Function Make_EDCs(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	SetDataFolder root:manip
	
	Wave EDMshow
	
	Variable column = varNum//round((varNum - DimOffset(EDMshow,0))/DimDelta(EDMshow,0))
	Make/O/N=(DimSize(EDMshow,1)) EDCcut, EDClinex, EDCliney
	SetScale/P x, DimOffset(EDMshow,1), DimDelta(EDMshow,1), EDCcut
	EDCcut[] = EDMshow[column][p]
	EDClinex[] = Dimoffset(EDMshow,0)+varNum*Dimdelta(EDMshow,0)
	EDCliney[] = DimOffset(EDMshow,1) + DimDelta(EDMshow,1)*x
	
	Wavestats/Q EDCcut
//	SetAxis/W=manipEDM#EDC left,0,V_max+0.1
End

Function Make_MDCs(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	SetDataFolder root:manip
	
	Wave EDMshow
	Variable/G row = varNum//round((varNum - DimOffset(EDM,1))/DimDelta(EDM,1))
	Make/O/N=(DimSize(EDMshow,0)) MDCcut, MDClinex, MDCliney
	SetScale/P x, DimOffset(EDMshow,0), DimDelta(EDMshow,0), MDCcut
	MDCcut[] = EDMshow[p][row]
	MDClinex[] = DimOffset(EDMshow,0) + DimDelta(EDMshow,0)*x
	MDCliney[] = DimOffset(EDMshow,1)+row*DimDelta(EDMshow,1)//varNum
	Wavestats/Q MDCcut
	SetAxis/W=manipEDM#MDC left,0,V_max+(0.1*V_max)
End


Function update_var(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	//NVAR slit_width
	SetDataFolder root:manip
	NVAR row
	
	//if (Dimoffset(EDM,0)+DimDelta(EDM,0)*Dimsize(EDM,0)>slit_width/4)
		put_k_EDM()
	//endif
		Make_MDCs("bla",row,"bla","bla")
end

Function slit_manips(ctrlName,popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	SetDataFolder root:manip
	
	NVAR slit	
	slit=popNum
	put_k_EDM()	
end

Function put_k_EDM()
	
	SetDataFolder root:manip
	
	NVAR Ef, lattice, slit, s_tilt, s_phi, s_polar, slit_width, Ave, Avk
	Wave EDMshow, mEDM, kEDM
	Variable/G kx_b,ky_b,kpar_b,kx_e,ky_e,kpar_e,k_inc
	Variable pol_inc = Dimsize(mEDM,0) //number of chanels along the slit 
	Variable K1, K2, K3
	Variable/G pol //dummy vars 
	
	Duplicate/O mEDM kEDM
	//Polar and phi
	K1=s_polar
	K2=s_phi		
	K3=s_tilt
	
		if(slit==1)			// vertical slit
			
			pol = K1+Dimoffset(mEDM,0)
			kx_b=0.5123*lattice/pi*sqrt(Ef)*((sin(K1*pi/180)*cos(pol*pi/180)-sin(pol*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(pol*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(pol*pi/180))*sin(K2*pi/180))
			ky_b=0.5123*sqrt(Ef)*lattice/pi *((sin(K1*pi/180)*cos(pol*pi/180)-sin(pol*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(pol*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(pol*pi/180))*cos(K2*pi/180))
			kpar_b=sqrt(kx_b*kx_b+ky_b*ky_b)	
			
			pol = K1+Dimoffset(mEDM,0)+DimSize(mEDM,0)*DimDelta(mEDM,0)
			kx_e=0.5123*lattice/pi*sqrt(Ef)*((sin(K1*pi/180)*cos(pol*pi/180)-sin(pol*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(pol*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(pol*pi/180))*sin(K2*pi/180))
			ky_e=0.5123*sqrt(Ef)*lattice/pi *((sin(K1*pi/180)*cos(pol*pi/180)-sin(pol*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(pol*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(pol*pi/180))*cos(K2*pi/180))
			kpar_e=sqrt(kx_e*kx_e+ky_e*ky_e)	
			
			k_inc=abs(kpar_e-kpar_b)/pol_inc
			
			SetScale	/P x, kpar_b,k_inc,"", kEDM
	
		else					// horizontal slit
			
			pol = K1+Dimoffset(mEDM,0)
			kx_b=0.5123*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*cos((K2)*pi/180)*cos((K3)*pi/180)-sin((K2)*pi/180)*sin((K3)*pi/180))
			ky_b=0.5123*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*sin((K2)*pi/180)*cos((K3)*pi/180)+cos((K2)*pi/180)*sin((K3)*pi/180))
			
			pol = K1+Dimoffset(mEDM,0)+(DimSize(mEDM,0)-1)*DimDelta(mEDM,0)
			kx_e=0.5123*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*cos((K2)*pi/180)*cos((K3)*pi/180)-sin((K2)*pi/180)*sin((K3)*pi/180))
			ky_e=0.5123*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*sin((K2)*pi/180)*cos((K3)*pi/180)+cos((K2)*pi/180)*sin((K3)*pi/180))
			
			
			Variable/G kxb=kx_b
			Variable/G kyb=ky_b
			Variable/G kxe = kx_e
			Variable/G kye = ky_e
			Variable/G angle =  -atan2((ky_b+ky_e),(kx_b+kx_e))
		
			if ((kx_b <=0)&&(ky_b <=0)&&(kx_e <=0)&&(ky_e <=0))
				kx_b = kxb*cos(angle)-kyb*sin(angle)
				ky_b = kxb*sin(angle)+kyb*cos(angle)
				kx_e = kxe*cos(angle)-kye*sin(angle)
				ky_e = kxe*sin(angle)+kye*cos(angle)
			endif
			
			if ((kx_b >=0)&&(ky_b >=0)&&(kx_e >=0)&&(ky_e >=0))
				kx_b = kxb*cos(angle)-kyb*sin(angle)
				ky_b = kxb*sin(angle)+kyb*cos(angle)
				kx_e = kxe*cos(angle)-kye*sin(angle)
				ky_e = kxe*sin(angle)+kye*cos(angle)
			endif
			
			if ((kx_b >= 0)&&(ky_b <= 0)&&(kx_e >= 0)&&(ky_e <= 0))
				kx_b = kxb*cos(angle)-kyb*sin(angle)
				ky_b = kxb*sin(angle)+kyb*cos(angle)
				kx_e = kxe*cos(angle)-kye*sin(angle)
				ky_e = kxe*sin(angle)+kye*cos(angle)
			endif
			
			if ((kx_b <= 0)&&(ky_b >= 0)&&(kx_e <= 0)&&(ky_e >= 0))
				kx_b = kxb*cos(angle)-kyb*sin(angle)
				ky_b = kxb*sin(angle)+kyb*cos(angle)
				kx_e = kxe*cos(angle)-kye*sin(angle)
				ky_e = kxe*sin(angle)+kye*cos(angle)
			endif

			if ((kx_b <=0)&&(ky_b <=0))
				kpar_b=-sqrt(kx_b*kx_b+ky_b*ky_b)
				k_inc=+sqrt((kx_e-kx_b)^2+(ky_e-ky_b)^2)/pol_inc
			elseif ((kx_b >= 0)&&(ky_b >= 0))
				kpar_b=sqrt(kx_b*kx_b+ky_b*ky_b)
				k_inc=-sqrt((kx_e-kx_b)^2+(ky_e-ky_b)^2)/pol_inc
			elseif	((kx_b >= 0)&&(ky_b <= 0))
				kpar_b=-sqrt(kx_b*kx_b+ky_b*ky_b)
				k_inc=+sqrt((kx_e-kx_b)^2+(ky_e-ky_b)^2)/pol_inc
			elseif	((kx_b <= 0)&&(ky_b >= 0))
				kpar_b=-sqrt(kx_b*kx_b+ky_b*ky_b)
				k_inc=+sqrt((kx_e-kx_b)^2+(ky_e-ky_b)^2)/pol_inc
			endif
			
			if (kpar_b > 2)
				kpar_b = kpar_b - 2
			endif
			
			if (kpar_b < -2)
				kpar_b = kpar_b + 2
			endif
				
			//if (kpar_b > 1)
			//	kpar_b = kpar_b - 1
			//endif
			
			//if (kpar_b < -1)
			//	kpar_b = kpar_b +1
			//endif
			
			SetScale	/P x, kpar_b,k_inc,"", kEDM
			SetScale	/P y, Dimoffset(kEDM,1)-Ef,dimdelta(kEDM,1),"", kEDM
			
			
		endif
		
		Duplicate/O kEDM EDMshow		
		Avk = DimDelta(EDMshow,0)
		Ave = DimDelta(EDMshow,1)*1000 //in meV
		SetVariable avk,limits={Avk,DimSize(EDMshow,0),Avk},value= root:manip:Avk
		SetVariable ave,limits={Ave,DimSize(EDMshow,1),Ave},value= root:manip:Ave
		
		SetVariable EDCslice_but,limits={0,DimSize(EDMshow,0),1},value= root:manip:EDC_slice
		SetVariable MDCslice_but,limits={0,DimSize(EDMshow,1),1},value= root:manip:MDC_slice
		SetAxis /W=manipEDM#image bottom, Dimoffset(EDMshow,0),DimOffset(EDMshow,0)+(DimSize(EDMshow,0)-1)*DimDelta(EDMshow,0)
		SetAxis /W=manipEDM#image left, Dimoffset(EDMshow,1),DimOffset(EDMshow,1)+(DimSize(EDMshow,1)-1)*DimDelta(EDMshow,1)
		
End

Function BG_proc_edm(ctrlname,popNum,popStr1) : popupMenuControl //17nov to choose the background type
		String ctrlName
		Variable popNum
		String popStr1
		NVAR BG_type
	
		BG_type = popNum
	
end

Function rcal_input_edm(ctrlName ):buttonControl	//recalls the original input for all peaks
		String ctrlName
		Wave recal_Init__fit
		Wave Fit_para
		
		Fit_para = recal_Init__fit
		show_input("bla",1,"bla","bla")
		Make_fit_display_EDM()
end

Function bg_sub_edm(ctrlName ):buttonControl	//creates a wave with the fitted background substracted
		String ctrlName
		Wave recal_Init__fit
		Wave dupwav, Background, Background_slope, Background_smth, Background_slope_smth
		NVAR BG_type, start, stop
		
		if(BG_type==2)
			Duplicate/O Background BG_dup
			Duplicate/O Background_slope BG_slp_dup
		else
			Duplicate/O Background_smth BG_dup
			Duplicate/O Background_slope_smth BG_slp_dup
		endif
		
	Make/O/N=(Dimsize(dupwav, 0), (stop-start+1)) wav_red, BG_wave, 'Data-BG'
	SetScale/P x Dimoffset(dupwav, 0),Dimdelta(dupwav, 0),"", wav_red
	SetScale/P y (Dimoffset(dupwav, 1)+start*Dimdelta(dupwav, 1)),Dimdelta(dupwav, 1),"", wav_red
	SetScale/P x Dimoffset(dupwav, 0),Dimdelta(dupwav, 0),"", 'Data-BG'
	SetScale/P y (Dimoffset(dupwav, 1)+start*Dimdelta(dupwav, 1)),Dimdelta(dupwav, 1),"", 'Data-BG'
	
	Variable x, y, k
	for(x=start; x<stop+1; x+=1)
		wav_red[][x-start]=dupwav[p][x]
		
		for(y=0; y<Dimsize(dupwav,0); y+=1)
			k=Dimoffset(dupwav,0)+y*Dimdelta(dupwav,0)
			BG_wave[y][x-start]=BG_dup[x-start]+k*BG_slp_dup[x-start]
		endfor
		
	endfor
	
	'Data-BG'= wav_red-BG_wave
	
end

Function fit_all(ctrlName ):buttonControl	//does the actual fitting
		String ctrlName
		SetDataFolder root:manip
		NVAR p_amount, start, stop, BG_type, bg_slope, bg_offset
		Wave f_Fit_para = Fit_para
		Wave f_dupwav=dupwav
		Wave f_MDC=MDC
		Variable a,b
		String position, height, width
		Variable start_f,stop_f
			start_f=start
			stop_f=stop
		
		a=start_f
		NVAR MDC_slice
		if (start_f < stop_f)
			do
				//Make_MDCs("bla",a,"bla","bla");DoUpdate
				//fit_one("bla"); DoUpdate
				Make_MDCs("bla",a,"bla","bla");
				fit_one("bla"); 
				a+=1
				MDC_slice = a
			while (a<stop_f+1)
		else
			do
				//Make_MDCs("bla",a,"bla","bla");DoUpdate
				//fit_one("bla"); DoUpdate
				Make_MDCs("bla",a,"bla","bla");
				fit_one("bla"); 
				a=a-1
				MDC_slice = a
			while (a>stop_f-1)
		endif
			
End

Function fit_one(ctrlName ):buttonControl	//does the actual fitting
		String ctrlName
		NVAR p_amount, p_num, MDC_slice, EDC_slice, BG_type, bg_slope, bg_offset, bg_sq, bg_cub, bg_shift, bg_qu, edcmdc, polynom
		Wave f_Fit_para = Fit_para
		Wave line_add
		Wave recal_Init__fit 
		Wave osc_shape
		Variable a,b
		Variable/G fit_dim_m,fit_dim_e
		//String position, height, width
		Variable V_FitQuitReason
		NVAR offs, slop, shif, sqr, cube, quar
		if (edcmdc ==0)
			Wave f_MDC = MDCcut
		else
			Wave f_EDC = EDCcut
		endif
		
		//PauseUpdate
		
		Variable cnt,cnt2, num
		cnt=0
		cnt2 = 0
		for (a=0;a<p_amount;a+=1)
			if (osc_shape[a] == 1)
				cnt+=1
			elseif(osc_shape[a] == 2)
				cnt2+=1
			endif
		endfor
		
		Make/O/N=(7+3*(p_amount-(cnt+cnt2))+4*(cnt+cnt2)) oneD_fit_wav 	//1D wave containing all fitted parameters
		
		if (edcmdc == 0)
			if (!(exists("MDC_result_wav")==1))
				Make/O/N=((7+3*(p_amount-(cnt+cnt2))+4*(cnt+cnt2))) MDC_result_wav 	//wave containing all fitted parameters
				Make/O/N=((7+3*(p_amount-(cnt+cnt2))+4*(cnt+cnt2))) MDC_error_wav 	//wave containing all fitted parameters
				MDC_result_wav[Dimsize(MDC_result_wav,0)-1][0] = -1
				fit_dim_m =0
			else
				Redimension/N=(-1,fit_dim_m+1) MDC_result_wav
				Redimension/N=(-1,fit_dim_m+1) MDC_error_wav
				MDC_result_wav[Dimsize(MDC_result_wav,0)-1][fit_dim_m] = -1
			endif
		else
			if (!(exists("EDC_result_wav")==1))
				Make/O/N=((7+3*(p_amount-(cnt+cnt2))+4*(cnt+cnt2))) EDC_result_wav 	//wave containing all fitted parameters
				Make/O/N=((7+3*(p_amount-(cnt+cnt2))+4*(cnt+cnt2))) EDC_error_wav 	//wave containing all fitted parameters
				EDC_result_wav[Dimsize(EDC_result_wav,0)-1][0] = -1
				fit_dim_e =0
			else
				Redimension/N=(-1,fit_dim_e+1) EDC_result_wav
				Redimension/N=(-1,fit_dim_e+1) EDC_error_wav
				EDC_result_wav[Dimsize(EDC_result_wav,0)-1][fit_dim_e] = -1
			endif
		endif	
		Make/O/T/N=(2*(p_amount-cnt2)+4*cnt2) T_Constraints
		
		cnt=6
		num =0
		For (a=0; a < p_amount; a+=1)
			if ((osc_shape[a]==0)||(osc_shape[a]==4))
				T_Constraints[num] = "K"+num2str(cnt+1) +"> 0"  
				T_Constraints[num+1] = "K"+num2str(cnt+2) +"> 0"
				cnt += 3  
				num += 2 
			elseif (osc_shape[a]==1)
				T_Constraints[num] = "K"+num2str(cnt+1) +"> 0"  
				T_Constraints[num+1] = "K"+num2str(cnt+2) +"> 0"
				T_Constraints[num+2] = "K"+num2str(cnt+3) +"> 0.001"
				cnt+=4
				num += 2 
			else	
				T_Constraints[num] = "K"+num2str(cnt+1) +"> 0"  
				T_Constraints[num+1] = "K"+num2str(cnt+2) +"> 0"
				T_Constraints[num+2] = "K"+num2str(cnt+3) +"> 0"
				T_Constraints[num+3] = "K"+num2str(cnt+3) +"< 1"
				
				cnt+=4
				num += 4 
			endif
			
		endfor
		
		if (polynom == 0)
			
			String/G holdstr 
			
			holdstr = num2str(offs) + num2str(slop)+ num2str(shif)+ num2str(sqr)+ num2str(cube)+ num2str(quar)
//			for (a=6;a<DimSize(f_Fit_para,0);a+=1)
//				holdstr += "0"
//			endfor
			
			if (edcmdc == 0)
				FuncFit/W=2/N/Q/H=holdstr Multi_lor_edm, f_Fit_para, f_MDC[pcsr(A),pcsr(B)] /C=T_Constraints //Here we make the first fit
			else
				print "fitfit"
				FuncFit/W=2/N/Q/H=holdstr Multi_lor_edm, f_Fit_para, f_EDC[pcsr(A),pcsr(B)] /C=T_Constraints //Here we make the first fit
			endif
		else
			
			f_Fit_para[6,Dimsize(f_Fit_para,0)] = 0
			//f_Fit_para[0] = bg_offset
			//f_Fit_para[1] = bg_slope
			//f_Fit_para[2] = bg_shift
			//f_Fit_para[3]=bg_sq
			//f_Fit_para[4]=bg_cub
			//f_Fit_para[5]=bg_qu
			
			String/G holdstr 
			
			holdstr = num2str(offs) + num2str(slop)+ num2str(shif)+ num2str(sqr)+ num2str(cube)+ num2str(quar)
			for (a=6;a<DimSize(f_Fit_para,0);a+=1)
				holdstr += "1"
			endfor
			
			
			if (edcmdc == 0)	
				FuncFit/W=0/N/Q/H=holdstr Multi_lor_edm, f_Fit_para, f_MDC[pcsr(A),pcsr(B)]
			else
				FuncFit/W=0/N/Q/H=holdstr Multi_lor_edm, f_Fit_para, f_EDC[pcsr(A),pcsr(B)]
			endif
		endif
		
		Make_fit_display_EDM()//And update the graphs //Maarten
		show_input("bla",p_num,"bla","bla")
		//DoUpdate
		oneD_fit_wav[]=f_Fit_para[p]//Store the optimized parameters in oneD_fit_wav
		
		if (V_FitQuitReason==0)
			recal_Init__fit[] = oneD_fit_wav[p]
		endif
		
		Wave W_sigma
		bg_offset = oneD_fit_wav[0]
		bg_slope = oneD_fit_wav[1]
		bg_shift = oneD_fit_wav[2]
		bg_sq = oneD_fit_wav[3]
		bg_cub = oneD_fit_wav[4]
		bg_qu = oneD_fit_wav[5]
		
		If (polynom == 1)
			Make/O/N=(8000) curvef
			Setscale/I x,xcsr(A), xcsr(B),"", curvef
			curvef =f_Fit_para[0]+ (x - f_Fit_para[2]) *f_Fit_para[1]+f_Fit_para[3]*(x - f_Fit_para[2]) ^2+f_Fit_para[4]*(x - f_Fit_para[2]) ^3+f_Fit_para[5]*(x - f_Fit_para[2]) ^4
		endif	
			
		if (edcmdc == 0)
			Variable m_exists =0
			for (a=0;a<Dimsize(MDC_result_wav,1);a+=1)
				if (MDC_result_wav[Dimsize(MDC_result_wav,0)-1][a] == MDC_slice)
					MDC_result_wav[][a]=oneD_fit_wav[p]
					MDC_error_wav[][a]=W_sigma[p]	
					MDC_result_wav[Dimsize(MDC_result_wav,0)-1][a]=MDC_slice
					MDC_error_wav[Dimsize(MDC_error_wav,0)-1][a]=MDC_slice
					
					if (polynom == 1)
						FindPeak/B=3/Q curvef
						MDC_result_wav[6][a]= V_PeakLoc
						MDC_result_wav[7][a]= V_PeakVal
						MDC_result_wav[8][a]= V_peakwidth
						if ((V_flag !=0)||(V_peakLoc<= leftx(curvef) + 10*Dimdelta(curvef,0))||(V_peakLoc>= rightx(curvef) - 10*Dimdelta(curvef,0)))
							Differentiate curvef/D=W_DIF
							FindPeak/Q/B=3 W_DIF
							MDC_result_wav[6][a]= V_PeakLoc
							MDC_result_wav[7][a]= V_PeakVal
							MDC_result_wav[8][a]= V_peakwidth
						endif
					endif		
					m_exists =1
				endif
			endfor 
		
			if (m_exists == 0)
				MDC_result_wav[][fit_dim_m]=oneD_fit_wav[p]
				MDC_error_wav[][fit_dim_m]=W_sigma[p]	
				MDC_result_wav[Dimsize(MDC_result_wav,0)-1][fit_dim_m]=MDC_slice
				MDC_error_wav[Dimsize(MDC_error_wav,0)-1][fit_dim_m]=MDC_slice
				
				if (polynom == 1)
						FindPeak/B=3/Q curvef
						MDC_result_wav[6][fit_dim_m]= V_PeakLoc
						MDC_result_wav[7][fit_dim_m]= V_PeakVal
						MDC_result_wav[8][fit_dim_m]= V_peakwidth
						if ((V_flag !=0)||(V_peakLoc<= leftx(curvef) + 10*Dimdelta(curvef,0))||(V_peakLoc>= rightx(curvef) - 10*Dimdelta(curvef,0)))
							Differentiate curvef/D=W_DIF
							FindPeak/Q/B=3 W_DIF
							MDC_result_wav[6][a]= V_PeakLoc
							MDC_result_wav[7][a]= V_PeakVal
							MDC_result_wav[8][a]= V_peakwidth
						endif
				endif	
				fit_dim_m+=1	
			endif
		else
			Variable e_exists =0
			for (a=0;a<Dimsize(EDC_result_wav,1);a+=1)
				if (EDC_result_wav[Dimsize(EDC_result_wav,0)-1][a] == EDC_slice)
					EDC_result_wav[][a]=oneD_fit_wav[p]
					EDC_error_wav[][a]=W_sigma[p]	
					EDC_result_wav[Dimsize(EDC_result_wav,0)-1][a]=EDC_slice
					EDC_error_wav[Dimsize(EDC_error_wav,0)-1][a]=EDC_slice
					if (polynom == 1)
						
						FindPeak/Q/B=3 curvef
						EDC_result_wav[6][a]= V_PeakLoc
						EDC_result_wav[7][a]= V_PeakVal
						EDC_result_wav[8][a]= V_peakwidth
						if ((V_flag !=0)||(V_peakLoc<= leftx(curvef) + 10*Dimdelta(curvef,0))||(V_peakLoc>= rightx(curvef) - 10*Dimdelta(curvef,0)))
							Differentiate curvef/D=W_DIF
							Smooth/S=2 251, W_DIF
							Differentiate W_DIF/D=W_DIF_DIF
							FindPeak/N/B=3 W_DIF
							EDC_result_wav[6][a]= V_PeakLoc
							EDC_result_wav[7][a]= V_PeakVal
							EDC_result_wav[8][a]= V_peakwidth
						endif
					endif		
					e_exists =1
				endif
			endfor 
		
			if (e_exists == 0)
				EDC_result_wav[][fit_dim_e]=oneD_fit_wav[p]
				EDC_error_wav[][fit_dim_e]=W_sigma[p]	
				EDC_result_wav[Dimsize(EDC_result_wav,0)-1][fit_dim_e]=EDC_slice
				EDC_error_wav[Dimsize(EDC_error_wav,0)-1][fit_dim_e]=EDC_slice
				
				if (polynom == 1)
						FindPeak/B=3/Q curvef
						EDC_result_wav[6][fit_dim_e]= V_PeakLoc
						EDC_result_wav[7][fit_dim_e]= V_PeakVal
						EDC_result_wav[8][fit_dim_e]= V_peakwidth
						if ((V_flag !=0)||(V_peakLoc<= leftx(curvef) + 10*Dimdelta(curvef,0))||(V_peakLoc>= rightx(curvef) - 10*Dimdelta(curvef,0)))
							Differentiate curvef/D=W_DIF
							Smooth/S=2 251, W_DIF
							Differentiate W_DIF/D=W_DIF_DIF
							FindPeak/N/B=3 W_DIF
							EDC_result_wav[6][a]= V_PeakLoc
							EDC_result_wav[7][a]= V_PeakVal
							EDC_result_wav[8][a]= V_peakwidth
							
						endif
					endif		
				fit_dim_e+=1	
			endif
		endif
		Reorder_traces()
		Append_traces()
		
		//These two lines for setting EDMs to zero polar angle 23/12/11
		NVAR pol_shift, l_pos
		pol_shift = l_pos
		//KillWaves/Z curvef, W_sigma, T_Constraints, oneD_fit_wav
End

Function Reorder_traces()
	NVAR edcmdc
	Wave EDMshow
	if (edcmdc==0)
		Wave res_wav = MDC_result_wav
		Wave err_wav = MDC_error_wav
	else
		Wave res_wav = EDC_result_wav
		Wave err_wav = EDC_error_wav
	endif
	
	Duplicate/O/R=[Dimsize(res_wav,0)-1][] res_wav sort_wav, xwave
	Duplicate/O res_wav tempw, tempe
	Sort sort_wav,sort_wav
	Variable a,b
	
	For (b = 0; b< Dimsize(sort_wav,1); b+=1)
		For (a = 0; a< Dimsize(res_wav,1);a+=1)
			if (res_wav[Dimsize(res_wav,0)-1][a] == sort_wav[0][b])	
				tempw[][b] = res_wav[p][a]
				tempe[][b] = err_wav[p][a]
			endif
		endfor 
	endfor
	
	if (tempw[Dimsize(tempw,0)-1][0] == -1)
		Deletepoints/M=1 0,1,tempw,tempe
		Redimension/N=(-1,Dimsize(tempw,1)+1) tempw, tempe
		tempw[Dimsize(tempw,0)-1][Dimsize(tempw,1)-1] = -1
		Redimension/N=(-1,Dimsize(xwave,1)-1)  xwave
	endif
	
	Duplicate/O tempw, res_wav
	Duplicate/O tempe, err_wav
	
	if(Dimsize(xwave,1)==0)
		REdimension/N=(-1,1) xwave
	endif
	
	For (a=0;a<Dimsize(xwave,1);a+=1)
		if (edcmdc == 0)
			xwave[a] = Dimoffset(EDMshow,1)+res_wav[Dimsize(res_wav,0)-1][a]*Dimdelta(EDMshow,1)
		else
			xwave[a] = Dimoffset(EDMshow,0)+res_wav[Dimsize(res_wav,0)-1][a]*Dimdelta(EDMshow,0)
		endif
	endfor
	
	//KillWaves tempw,tempe,sort_wav
end

Function Append_traces()
	Wave osc_shape, EDMshow, xwave
	NVAR edcmdc, fitedc_cnt, fitmdc_cnt
	SVAR image_name
	NVAR old_osc1,old_osc2
	Variable i,j,k,num,lnum
	String name2, name4, name5, name, namerr, nameE
	SVAR name1, name3
	
	j=6
	for (i = 0; i < Dimsize(osc_shape,0);i+=1)
		if (edcmdc ==0)
			Wave reslist = MDC_result_wav
			Wave errlist = MDC_error_wav
			if (reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-1] != -1)	
				name1 = "root:Fitresults:" + image_name + ":MDC:osc_"+ num2str(fitmdc_cnt) +"_" + num2str(i+1) + "_" + num2str(reslist[Dimsize(reslist,0)-1][0]) + "_" + num2str(reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-1])
				name2 = "root:Fitresults:" + image_name + ":MDC:osc_"+ num2str(fitmdc_cnt) +"_" + num2str(i+1) + "_" + num2str(old_osc1) + "_" + num2str(old_osc2)
				name3 = "root:Fitresults:" + image_name + ":MDC:error_"+ num2str(fitmdc_cnt) +"_" + num2str(i+1) + "_" + num2str(reslist[Dimsize(reslist,0)-1][0]) + "_" + num2str(reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-1])
				name4 = "root:Fitresults:" + image_name + ":MDC:error_"+ num2str(fitmdc_cnt) +"_" + num2str(i+1) + "_" + num2str(old_osc1) + "_" + num2str(old_osc2)
				if (i == (Dimsize(osc_shape,0)-1))
					old_osc1 = reslist[Dimsize(reslist,0)-1][0] 
					old_osc2 = reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-1]
				endif
				lnum=0
			else
				
				name1 = "root:Fitresults:" + image_name + ":MDC:osc_"+ num2str(fitmdc_cnt) +"_" + num2str(i+1) + "_" + num2str(reslist[Dimsize(reslist,0)-1][0]) + "_" + num2str(reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-2])
				name2 = "root:Fitresults:" + image_name + ":MDC:osc_"+ num2str(fitmdc_cnt) +"_" + num2str(i+1) + "_" + num2str(old_osc1) + "_" + num2str(old_osc2)
				name3 = "root:Fitresults:" + image_name + ":MDC:error_"+ num2str(fitmdc_cnt) +"_" + num2str(i+1) + "_" + num2str(reslist[Dimsize(reslist,0)-1][0]) + "_" + num2str(reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-2])
				name4 = "root:Fitresults:" + image_name + ":MDC:error_"+ num2str(fitmdc_cnt) +"_" + num2str(i+1) + "_" + num2str(old_osc1) + "_" + num2str(old_osc2)
				if (i == (Dimsize(osc_shape,0)-1))
					old_osc1 = reslist[Dimsize(reslist,0)-1][0] 
					old_osc2 = reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-2]
				endif
				lnum=1
			endif
			name5 =  "root:Fitresults:" + image_name + ":MDC:E_"+ num2str(fitmdc_cnt) +"_" +num2str(i+1)
		else
			Wave reslist = EDC_result_wav
			Wave errlist = EDC_error_wav
			if (reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-1] != -1)	
				
				name1 = "root:Fitresults:" + image_name + ":EDC:osc_"+ num2str(fitedc_cnt) +"_" + num2str(i+1) + "_" + num2str(reslist[Dimsize(reslist,0)-1][0]) + "_" + num2str(reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-1])
				name2 = "root:Fitresults:" + image_name + ":EDC:osc_"+ num2str(fitedc_cnt) +"_" + num2str(i+1) + "_" + num2str(old_osc1) + "_" + num2str(old_osc2)
				name3 = "root:Fitresults:" + image_name + ":EDC:error_"+ num2str(fitedc_cnt) +"_" + num2str(i+1) + "_" + num2str(reslist[Dimsize(reslist,0)-1][0]) + "_" + num2str(reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-1])
				name4 = "root:Fitresults:" + image_name + ":EDC:error_"+ num2str(fitedc_cnt) +"_" + num2str(i+1) + "_" + num2str(old_osc1) + "_" + num2str(old_osc2)
				if (i == (Dimsize(osc_shape,0)-1))
					old_osc1 = reslist[Dimsize(reslist,0)-1][0] 
					old_osc2 = reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-1]
				endif
				lnum=0
			else
				
				name1 = "root:Fitresults:" + image_name + ":EDC:osc_"+ num2str(fitedc_cnt) +"_" + num2str(i+1) + "_" + num2str(reslist[Dimsize(reslist,0)-1][0]) + "_" + num2str(reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-2])
				name2 = "root:Fitresults:" + image_name + ":EDC:osc_"+ num2str(fitedc_cnt) +"_" + num2str(i+1) + "_" + num2str(old_osc1) + "_" + num2str(old_osc2)
				name3 = "root:Fitresults:" + image_name + ":EDC:error_"+ num2str(fitedc_cnt) +"_" + num2str(i+1) + "_" + num2str(reslist[Dimsize(reslist,0)-1][0]) + "_" + num2str(reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-2])
				name4 = "root:Fitresults:" + image_name + ":EDC:error_"+ num2str(fitedc_cnt) +"_" + num2str(i+1) + "_" + num2str(old_osc1) + "_" + num2str(old_osc2)
				if (i == (Dimsize(osc_shape,0)-1))
					old_osc1 = reslist[Dimsize(reslist,0)-1][0] 
					old_osc2 = reslist[Dimsize(reslist,0)-1][Dimsize(reslist,1)-2]
				endif
				lnum=1
			endif
			name5 =  "root:Fitresults:" + image_name + ":EDC:E_"+ num2str(fitedc_cnt) +"_" +num2str(i+1)
		endif

		if (lnum == 0)
			if (osc_shape[i] == 0)
				Duplicate/O/R=[j,j+2][] reslist osc
				Duplicate/O/R=[j,j+2][] errlist err
				j+=3
			elseif (osc_shape[i] == 1)
				Duplicate/O/R=[j,j+3][] reslist osc
				Duplicate/O/R=[j,j+3][] errlist err
				j+=4
			elseif (osc_shape[i] == 2)
				Duplicate/O/R=[j,j+3][] reslist osc
				Duplicate/O/R=[j,j+3][] errlist err
				j+=4
			else
				Duplicate/O/R=[j,j+2][] reslist osc
				Duplicate/O/R=[j,j+2][] errlist err
				j+=3
			endif
		else
			if (osc_shape[i] == 0)
				Duplicate/O/R=[j,j+2][0,DimSize(reslist,1)-2] reslist osc
				Duplicate/O/R=[j,j+2][0,DimSize(reslist,1)-2] errlist err
				j+=3
			elseif (osc_shape[i] == 1)
				Duplicate/O/R=[j,j+3][0,DimSize(reslist,1)-2] reslist osc
				Duplicate/O/R=[j,j+3][0,DimSize(reslist,1)-2] errlist err
				j+=4
			elseif (osc_shape[i] == 2)
				Duplicate/O/R=[j,j+3][0,DimSize(reslist,1)-2] reslist osc
				Duplicate/O/R=[j,j+3][0,DimSize(reslist,1)-2] errlist err
				j+=4
			else
				Duplicate/O/R=[j,j+2][0,DimSize(reslist,1)-2] reslist osc
				Duplicate/O/R=[j,j+2][0,DimSize(reslist,1)-2] errlist err
				j+=3
			endif
		endif				
		
		Redimension/N=(Dimsize(osc,0)+1,-1) osc
		osc[Dimsize(osc,0)-1][] = reslist[Dimsize(reslist,0)-1][q]	
		
		name = "osc_"+num2str(fitedc_cnt+fitmdc_cnt)+"_"+num2str(i+1)
		namerr = "err_"+num2str(fitedc_cnt+fitmdc_cnt)+"_"+num2str(i+1)
		nameE = "E_"+num2str(fitedc_cnt+fitmdc_cnt)+"_"+num2str(i+1)	
		Duplicate/O xwave, $name5, $nameE
		//matrixtranspose osc
		//matrixtranspose err

		Duplicate/O/R=[0][] osc $name
		Duplicate/O/R=[0][] err $namerr
//		Duplicate/O/R=[0][] reslist $name
//		Duplicate/O/R=[0][] errlist $namerr

		
		RemoveFromgraph/Z/W=manipEDM#image $name
		KillWaves/Z $name2, $name4
		
//		Duplicate/O osc $name1
//		Duplicate/O err $name3
		Duplicate/O reslist $name1
		Duplicate/O errlist $name3
		if (edcmdc ==0)
			Appendtograph/VERT/W=manipEDM#image $name vs $nameE
		else
			Appendtograph/W=manipEDM#image $name vs $nameE
		endif
		ErrorBars/W=manipEDM#image $name Y, wave=($namerr,$namerr)
		ModifyGraph/W=manipEDM#image mode($name)=3
		ModifyGraph/W=manipEDM#image rgb($name)=(4369,4369,4369)
		num+=1
	endfor	
End



Function do_image(ctrlName) : ButtonControl				
	String ctrlName
	Wave EDMshow
	SVAR image_name
	NVAR edcmdc, norm_flag
	
	if (!datafolderexists("root:images"))
		NewDataFolder root:images
	endif
	
	if (norm_flag!=1)
		Duplicate/O EDMshow root:images:$image_name
		SetScale/P x, Dimoffset(EDMshow,0),DimDelta(EDMshow,0),"",root:images:$image_name
		SetScale/P y, Dimoffset(EDMshow,1),DimDelta(EDMshow,1),"",root:images:$image_name
		Display/K=1/W=(100,100,500,600)
		DoWindow/C $image_name
		AppendImage root:images:$image_name	
		ModifyImage $image_name ctab= {*,*,BlueHot,1}
		ModifyGraph fSize=20;DelayUpdate
		Label left "E-E\\BF\\M (eV)";DelayUpdate
		Label bottom "Momentum (\\F'symbol'p\\F'geneva'/a)"
		ModifyGraph standoff=0
		SetDrawEnv fstyle= 1
		ResumeUpdate
	else
		string imnam=image_name+"_ren"
		Duplicate/O EDMshow root:images:$imnam
		SetScale/P x, Dimoffset(EDMshow,0),DimDelta(EDMshow,0),"",root:images:$imnam
		SetScale/P y, Dimoffset(EDMshow,1),DimDelta(EDMshow,1),"",root:images:$imnam
		Display/K=1/W=(100,100,500,600)
		DoWindow/C $imnam
		AppendImage root:images:$imnam
		ModifyImage $imnam ctab= {*,*,BlueHot,1}
		ModifyGraph fSize=20;DelayUpdate
		Label left "E-E\\BF\\M (eV)";DelayUpdate
		Label bottom "Momentum (\\F'symbol'p\\F'geneva'/a)"
		ModifyGraph standoff=0
		SetDrawEnv fstyle= 1
		ResumeUpdate
	endif
end

Function do_der_im(ctrlName) : ButtonControl				
	String ctrlName
	Wave dk2EDM
	SVAR image_name
	NVAR edcmdc,opt
	
	string plotname
	if (opt==0)
		plotname= image_name+"d2k"
	else
		plotname= image_name+"d2E"
	endif
		
	if (!datafolderexists("root:images"))
		NewDataFolder root:images
	endif
	Duplicate/O dk2EDM root:images:$plotname
	SetScale/P x, Dimoffset(EDMshow,0),DimDelta(EDMshow,0),"",root:images:$plotname
	SetScale/P y, Dimoffset(EDMshow,1),DimDelta(EDMshow,1),"",root:images:$plotname
	Display/K=1/W=(100,100,600,500)
	DoWindow/C $plotname
	AppendImage root:images:$plotname	
	ModifyImage $plotname ctab= {*,0,ColdWarm,1}
	ModifyGraph fSize=15;DelayUpdate
	Label left "\\Z18BE (eV)";DelayUpdate
	Label bottom "\\Z18 Momentum (\\F'symbol'p\\F'geneva'/a)"
	ModifyGraph standoff=0
	SetDrawEnv fstyle= 1

	ResumeUpdate
end

Function ave_ek(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Variable/G De, Dk, rk, re
	Variable k,n,m,a
	Variable/G dime,dimk,dstk,dste
	NVAR Ave, Avk
	Wave kEDM
	Duplicate/O kEDM dummy
	
	//original dimension of EDM
	De = abs(DimDelta(kEDM,1)*1000)//in meV
	Dk = abs(DimDelta(kEDM,0))
	//Number of lines that are going to be averaged
	rk = round(Avk/Dk)
	re = round(Ave/De)
	
	Redimension/N=(rk*floor(Dimsize(kEDM,0)/rk),re*floor(Dimsize(kEDM,1)/re)) dummy
	//The new dimensions of the averaged wave are
	dimk=(Dimsize(dummy,0)/rk)
	dime=(Dimsize(dummy,1)/re)
	Make/O/N=(dimk,Dimsize(dummy,1)) EDMa
	Make/O/N=(dimk,dime) EDMav
	
	//Now we can do the average over k
	Make/O/N=(Dimsize(dummy,1)) sumk
	a=0
	for (k=0; k < Dimsize(dummy,0); k+=rk)
		sumk[]=0
		m=0
		for (n=0; n < rk; n+=1) 	
			sumk[]=sumk[p]+dummy[k+n][x]
			m=m+1
		endfor
		
		sumk=sumk/m
		
		for(n=0;n<DimSize(sumk,0);n+=1) 
			EDMa[a][n]=sumk[n]
		endfor
		a=a+1
	endfor
	
	//and average the new wave over energy
	Make/O/N=(Dimsize(EDMa,0)) sume
	a=0
	for (k=0; k < Dimsize(EDMa,1); k+=re)
		sume[]=0
		m=0
		for (n=0; n < re; n+=1) 	
			sume[]=sume[p]+EDMa[x][k+n]
			m=m+1
		endfor
		sume=sume/m
		for(n=0;n<DimSize(sume,0);n+=1) 
			EDMav[n][a]=sume[n]
		endfor
		a=a+1
	endfor
	
	//Set the scales of the new EDM. Calculate the average of the k/E-values of the first rows.
	dstk=Dimoffset(kEDM,0)+(rk-1)*DimDelta(kEDM,0)/rk
	//for (n=1;n<rk-1;n+=1)
	//	dstk=dstk+Dimoffset(kEDM,0)+n*DimDelta(kEDM,0)
	//endfor
	//dstk=dstk/rk
	
	dste=Dimoffset(kEDM,1)+(re-1)*DimDelta(kEDM,1)/re
	//for (n=0; n<re-1; n+=1)
	//	dste=dste+Dimoffset(kEDM,1)+n*DimDelta(kEDM,1)
		
	//endfor
	//dste=dste/re
	
	
	SetScale	/P x, dstk,DimDelta(kEDM,0)*rk,"", EDMav 
	SetScale	/P y, dste,DimDelta(kEDM,1)*re,"", EDMav 
	
	Duplicate/O EDMav EDMshow		
	SetVariable EDCslice_but,limits={0,DimSize(EDMshow,0),1},value= root:manip:EDC_slice
	SetVariable MDCslice_but,limits={0,DimSize(EDMshow,1),1},value= root:manip:MDC_slice
	SetAxis /W=manipEDM#image bottom, Dimoffset(EDMshow,0),DimOffset(EDMshow,0)+(DimSize(EDMshow,0)-1)*DimDelta(EDMshow,0)
	SetAxis /W=manipEDM#image left, Dimoffset(EDMshow,1),DimOffset(EDMshow,1)+(DimSize(EDMshow,1)-1)*DimDelta(EDMshow,1)

	
	
end

Function add_point(ctrlName) : ButtonControl
	String ctrlName
	
	NVAR pointcount
	//Check to see if EkDisp has been created
	if(!exists("Energy"))
		Make/O/N=(1,1) Energy
		Make/O/N=(1,1) kvalues
		
		
	endif
	//We will get the k-value of the datapoint from this wave
	Wave MDCcut, EDMshow
	//We need this one to get the energy
	NVAR MDC_slice
	if (pointcount>0)
		RemoveFromGraph/W=manipEDM#image Energy
	endif
	Redimension/N=(pointcount+1,1) Energy, kvalues
	Energy[pointcount] = Dimoffset(EDMshow,1)+MDC_slice*DimDelta(EDMshow,1)
	kvalues[pointcount] = Dimoffset(EDMshow,0)+pcsr(A, "manipEDM#MDC")*DimDelta(EDMshow,0)
	AppendTograph/W=manipEDM#image  Energy vs kvalues
	pointcount = pointcount+1
	
end

Function add_new(ctrlName) : ButtonControl
	String ctrlName
	NVAR pointcount
	RemoveFromGraph/W=manipEDM#image Energy
	KillWaves Energy, kvalues
	pointcount=0
end

Function back_point(ctrlName) : ButtonControl
	String ctrlName
	NVAR pointcount
	
	pointcount=pointcount-1
end

Function renormalize(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr 
	
	NVAR norm_flag
	
	Variable y,num,z,x
	print popnum
	if (norm_flag==1)
		Duplicate/O EDM_prenorm, EDMshow
	endif
	
	Duplicate/O EDMshow dup_wave,EDM_prenorm
	If (popNum==1)
		SrMnSb_norm_subst()
		ModifyImage/W=manipEDM#image EDMshow ctab= {0,*,BlueHot,1}
		norm_flag=1	
	endif
	
	If (popNum==2)
		SrMnSb_norm_div()
		ModifyImage/W=manipEDM#image EDMshow ctab= {1,*,BlueHot,1}
		norm_flag=1		
	endif
	
	If (popNum==3)
		SrMnSb_norm_subst_ind()
		ModifyImage/W=manipEDM#image EDMshow ctab= {0,*,BlueHot,1}
		norm_flag=1		
	endif
	
	
	
//	Make/O/N=(Dimsize(dup_wave,0)) oneDnorm
//	for(y=0; y<Dimsize(dup_wave,0); y+=1)
//		num =0
//		for(x=0; x<Dimsize(dup_wave,1)-1; x+=1)
//			oneDnorm[y]+=dup_wave[y][x]
//			num+=1
//		endfor
//		oneDnorm[y] = oneDnorm[y]/num 
//	endfor
//	
//	for(y=0; y<Dimsize(dup_wave,0); y+=1)
//		for(z=0; z<Dimsize(dup_wave,1); z+=1)
//			dup_wave[y][z]/= oneDnorm[y]
//		endfor
//	endfor
//	
//	Variable/G point1,point2, point
//	point1=qcsr(A,"manipEDM#image")
//	point2=qcsr(B,"manipEDM#image")
//	if (point1>point2)
//		point = point1
//		point1=point2
//		point2=point
//	endif
//	Make/O/N=(Dimsize(dup_wave,0)) background
//	num=0
//	for (y=point1;y<point2;y+=1)
//		background[]=background+dup_wave[p][y]
//		num=num+1
//	endfor
//	background[]=background[p]/num
//	smooth/E=3/S=2 31,background
//	
//	for(y=0; y<Dimsize(dup_wave,0); y+=1)
//		for(z=0; z<Dimsize(dup_wave,1); z+=1)
//			dup_wave[y][z]/= background[y]
//		endfor
//	endfor
	Duplicate/O dup_wave, EDMshow
end

Function SrMnSb_norm_subst()
	Wave w=dup_wave
	NVAR sm_fac
	Make/O/N=(dimsize(w,1)) sum_col
	
	Variable m,n,cnt
	sum_col=0
	For(m=0;m<dimsize(w,0);m+=1)
	
		sum_col[]+=w[m][p]
		
		cnt+=1	
	endfor
	sum_col/=cnt
	Smooth/S=2 sm_fac,sum_col
	For(m=0;m<dimsize(w,0);m+=1)
		w[m][]-=sum_col[q]
		cnt+=1	
	endfor
End

Function SrMnSb_norm_div()
	Wave w=dup_wave
	
	Make/O/N=(dimsize(w,1)) sum_col
	
	Variable m,n,cnt
	sum_col=0
	For(m=0;m<dimsize(w,0);m+=1)
		sum_col[]+=w[m][p]
		
		cnt+=1	
	endfor
	sum_col/=cnt
	
	For(m=0;m<dimsize(w,0);m+=1)
		w[m][]/=sum_col[q]
		cnt+=1	
	endfor
End

Function SrMnSb_norm_subst_ind()
	Wave w=dup_wave
	NVAR sm_fac
	Make/O/N=(dimsize(w,1)) sum_col
	
	Variable m,n,cnt
	sum_col=0
	For(m=0;m<dimsize(w,0);m+=1)
		sum_col[]=w[m][p]
		Smooth/S=2 sm_fac,sum_col
		w[m][]-=sum_col[q]
		cnt+=1	
	endfor
	
End
//--------------------------------------------------
// Fitting functions
//----------------------------------------------------

//---------------------------------------------------
Function multi_lor_edm(w,x) : FitFunc						//the function with which the MDC's/EDC's are fitted
		Wave w
		Variable x
		NVAR p_amount,edcmdc
		Wave osc_shape
		
		Variable func,a,i,xprime
		xprime = x-w[2]
		func=w[0]+xprime*w[1] +w[3]*xprime^2+w[4]*xprime^3+w[5]*xprime^4
		a=6
		for (i=0; i < p_amount; i+=1)
			if (osc_shape[i] == 0)
				func+= (w[a+1]*0.25*w[a+2]*w[a+2])/(( x-w[a])^2+0.5*w[a+2]*0.5*w[a+2])
				a+=3
			elseif(osc_shape[i] == 1)
				func += w[a+1]*VoigtV2(w[a+2]*(x-w[a]),w[a+3])
				a+=4
			elseif(osc_shape[i] == 2)
				func += w[a+1]*cos(pi*w[a+3]/2+(1-w[a+3])*atan((x-w[a])/w[a+2]))/((x-w[a])^2+w[a+2]*w[a+2])^(0.5-0.5*w[a+3])
				a+=4
			else
				func+= w[a+1]*exp(-( x-w[a])^2/(2*w[a+2]*w[a+2]))
				a+=3
			endif
		endfor
		
		return func
End

//------------------------------------------------------------------------------------------------------------------
// A fitting function utilizing the Voigt profile (a convolution between a
// Gaussian and a Lorentzian). Can handle a number of peaks depending on the
// number of points in the coefficient wave w. If w contains 5 points then one
// peak will be generated as follows: 
// w[0]+w[1]*Voigt(w[2]*(x-w[3]),w[4])
// Parameter w[0] sets the DC offset, w[1] sets the amplitude, w[2]  affects the
// width, w[3] sets the location of the peak and w[4] adjusts the shape (but also
// affects the amplitude). 
// After the fit, you can use the returned coefficients to calculate the area (a)
// along with the half width at half max for the Gaussian (wg), Lorentzian (wl)
// and the Voigt (wv). Assuming the coefficient wave is named coef: 
// 	a= coef[1]*sqrt(pi)/coef[2]
// 	wg= sqrt(ln(2))/coef[2]
// 	wl= coef[4]/coef[2] 
// 	wv= wl/2 + sqrt( wl^2/4 + wg^2)
// See Tech Note TN026 for more information about the Voigt.

Function VoigtV2(X,Y)
	variable X,Y
	
	Y= abs(Y)
	X= abs(X)

	variable/C W,U,T= cmplx(Y,-X)
	variable S= X+Y

	if( S >= 15 )								//        Region I
		W= T*0.5641896/(0.5+T*T)
	else
		if( S >= 5.5 ) 							//        Region II
			U= T*T
			W= T*(1.410474+U*0.5641896)/(0.75+U*(3+U))
		else
			if( Y >= (0.195*X-0.176) ) 	//        Region III
				W= (16.4955+T*(20.20933+T*(11.96482+T*(3.778987+T*0.5642236))))
				W /= (16.4955+T*(38.82363+T*(39.27121+T*(21.69274+T*(6.699398+T)))))
			else									//        Region IV
				U= T*T
				W= T*(36183.31-U*(3321.9905-U*(1540.787-U*(219.0313-U*(35.76683-U*(1.320522-U*0.56419))))))
				W /= (32066.6-U*(24322.84-U*(9022.228-U*(2186.181-U*(364.2191-U*(61.57037-U*(1.841439-U)))))))
				W= cmplx(exp(real(U))*cos(imag(U)),0)-W
			endif
		endif
	endif
	return real(W)
end


Function PanelScrollHook(info)
    Struct WMWinHookStruct &info
 
    strswitch( info.eventName )
        case "mouseWheel":
            // If the mouse wheel is above a subwindow, info.name won't be the top level window
            // This test allows the scroll wheel to work normally when over a table subwindow.
            Variable mouseIsOverSubWindow= ItemsInList(info.WinName,"#") > 1
            if( !mouseIsOverSubWindow )
                String controls = ControlNameList(info.winName)
                Variable shiftKeyIsDown = info.eventMod & 0x2
                if( shiftKeyIsDown )
                    Variable dx
                    #ifdef MACINTOSH
                        dx= info.wheelDx
                    #else
                        dx= info.wheelDy
                    #endif
                    ModifyControlList controls, win=$info.winName, pos+={dx,0}  // left/right
                else
                    ModifyControlList controls, win=$info.winName, pos+={0,info.wheelDy}    // up/down
                endif
            endif
            break
    endswitch
    return 0    // process all events normally
End
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------