#pragma rtGlobals=1		// Use modern global access method.
function/wave kxyztoimage(kwavex, kwavey, kwaveint,sizex,sizey) //LB & SS added 2019
	wave kwavex, kwavey, kwaveint
	variable sizex// = sqrt(numpnts(kwavex))//*2
	variable sizey// = sqrt(numpnts(kwavey))//*2	
	variable xmin = wavemin(kwavex)
	variable xmax = wavemax(kwavex)
	variable ymin = wavemin(kwavey)
	variable ymax = wavemax(kwavey)

	string oldname = nameofwave(kwaveint)
	string mapname = oldname[0,strlen(oldname)-5]
	if(waveexists($mapname))
		//killwaves/z $mapname, $(mapname + "_bins")
		wave kxkymap = $mapname
		kxkymap = 0
		wave kxkybins = $(mapname+"_bins")
		kxkybins = 0
	else
		make/o/n=(sizex,sizey) $mapname, $(mapname+"_bins")
		wave kxkymap = $mapname
		wave kxkybins = $(mapname+"_bins")
		setscale/i x, xmin, xmax, kxkymap, kxkybins
		setscale/i y, ymin, ymax, kxkymap, kxkybins	
	endif
	
	imagefromXYZ {kwavex, kwavey, kwaveint}, kxkymap, kxkybins
	kxkymap /= kxkybins
	matrixfilter/p=2 NaNZapMedian, kxkymap
	return kxkymap
end


Macro TB_slicerD()
	//Prompt hor_twoDwave0,"3D wave", popup WaveList("*", ";", "DIMS:3")
	//String hor_twoDwave0
	SetDataFolder root:
	if(!(exists("mapcnt") ==2))
		Variable/G mapcnt = 1
		String/G maplist="\"\""
		print mapcnt
		if (Datafolderexists("root:EDMS") == 0)
			NewDataFolder root:EDMS
			Make/T/N=(0,2) root:EDMS:photonenergies
		endif
		NewDataFolder/O root:kMAPS
		
	endif
	Cut3DfuncD()
end

Function Cut3DfuncD()
	
	SetDataFolder root:
	NVAR mapcnt
	SVAR maplist
	
 
  if(!(exists("newdf") ==2))
	String/G newdf = "root:FSMAP" + num2str(mapcnt)
	Variable n, nmax
	nmax = CountObjects("root:",4)
	 
	maplist = "\""+";"
	for (n=1;n<nmax;n+=1)
		maplist = maplist + GetIndexedObjName("root:", 4, n) + ";"
	endfor
	maplist = maplist + "FSMAP" + num2str(mapcnt)+"\""
	mapcnt += 1
	
	NewDataFolder/S/O $newdf
	
	SVAR crdf = root:newdf
	String/G crntdf = crdf
	SVAR maps = root:maplist
   	String/G namewave="Int3D"
   	String/G namewave2="Int3D"
   
    	Variable/G normal
    	Variable/G Ef = 16.89
	Variable/G lattice1 = 3.1415
	Variable/G lattice2 = 3.1415
//	Variable/G lattice = 4.51
	Variable/G intensity = 5000
	Variable/G int_around = 0
	Variable/G int_range = 1
	Variable/G sliceenergy = 0
	Variable/G EDC_slice = 0
	Variable/G MDC_slice = 0
	Variable/G num_interp =0
	Variable/G points = 0
	Variable/G tt1=-1
	Variable/G tt2=1.3
	Variable/G tt3=-0.85
	Variable/G tt4=-0.85
	Variable/G tta1=-0.6
	Variable/G tta2=0.3
	Variable/G tta3=0.24
	Variable/G ttb1=-0.4
	Variable/G ttb2=0.2
	Variable/G ttb3=0.24
	Variable/G ttc1=1.7
	Variable/G ttc2=1.14
	Variable/G ttc3=0.74
	Variable/G ttd1=1.7
	Variable/G ttd2=1.14
	Variable/G ttd3=-0.64
	Variable/G tmu =1.45
	Variable/G tscale = 1
	Variable/G pol_0 = 0
	Variable/G tilt_0 = 0
	Variable/G slsize = 1
	Variable/G ftype = 1
	Variable/G s_polar = 0
	Variable/G s_tilt = 0
	Variable/G s_azi = 0
	Variable/G slit = 0
	Variable/G AC_min = 0
	Variable/G low_trip = 0
	Variable/G csrangle = 0
	String/G gold_name, file_name, strip_name, fname, f_name, Au_path
	
	Variable/G kx_b,ky_b,kpar_b,kx_e,ky_e,kpar_e,k_inc
	Variable/G kx_b2,ky_b2,kpar_b2,kx_e2,ky_e2,kpar_e2,k_inc2
	
	String/G tbswitch = "tb off"
  	Make/O/N=(1,1) TwoDwave ,ThreeDcut,ThreeDcut2, kEDM, kEDM2

	Make/O/N=1 linex, liney, EDCcut, MDCcut, EDClinex, EDCliney, MDClinex, MDCliney
	Make/O/N=(DimSize(ThreeDcut,0)) Ep,Em, Eps,Ems, Emsa,Epf,Emf, Epsf,Emsf, Emsaf, Ep2, Em2, Eps2, Ems2, Ems2a
	
  endif
  	SetDataFolder root:
  	SVAR newdf
	SetDataFolder $newdf
   	SVAR crntdf
	SVAR maps = root:maplist
   	SVAR namewave,namewave2
      NVAR normal,Ef, intensity, int_around,int_range, sliceenergy,EDC_slice,MDC_slice,AC_min,num_interp, points, low_trip
	NVAR lattice1, lattice2
//	NVAR lattice
	NVAR csrangle
	NVAR s_tilt,pol_0,tilt_0,s_polar,s_azi, slsize, ftype
	NVAR slit
	SVAR gold_name, file_name, strip_name, fname, f_name, Au_path
	NVAR kx_b,ky_b,kpar_b,kx_e,ky_e,kpar_e,k_inc
	NVAR kx_b2,ky_b2,kpar_b2,kx_e2,ky_e2,kpar_e2,k_inc2
	
  	Wave TwoDwave ,ThreeDcut,ThreeDcut2
	Wave linex, liney, EDCcut, MDCcut, EDClinex, EDCliney, MDClinex, MDCliney
	
	DoWindow/K Cut3D
	Display/N=Cut3D/K=1/W=(20,20,1100,750)
	
	NewPanel/K=1/Host=Cut3D/N=buttons/W=(0.8,0,1,1)
	
	//-----Select data
	SetDrawEnv textrgb= (0,0,65280),fstyle= 1,fsize= 14;DrawText 7,21,"Input data"	
	
	PopupMenu ft1,pos={140,40},size={76,20},proc = filetypehnuD, title="file type:",mode=0,value="itx file;nxs (diamond) file;h5 (SLS) file;krx (AMSTEL)"
	SetVariable Setau,pos={8,23},size={120,15},title="Au wave:",value= gold_name
	Button Popup_Auwave,pos={9,40},size={120,25},proc=PopupAuwave_3DD,title="Select"
	SetVariable e,pos={130,23},size={110,15},title="Pol offset:", limits={-90,90,0.1},value= pol_0
//	SetVariable t,pos={130,40},size={110,15},title="Tilt offset:", limits={-90,90,0.1},value= tilt_0
	PopupMenu sl2,pos={140,60},size={76,20},proc = slitsizeD, title="slit size:",mode=0,value="30 degrees;14 degrees"
	SetVariable SetEf,pos={13,69},size={120,15},proc=update_var2D,title=" Ef (in eV):",limits={0,1000,0.1},value= Ef
	SetVariable SetIntensity,pos={13,88},size={120,15},title="Au Intensity:",limits={0,1000000,100},value= Intensity
	SetVariable Setlat1,pos={13,106},size={100,15},proc=update_var2D,title=" a_x (in A):",limits={0,10,0.1},value= lattice1
	SetVariable Setlat2,pos={113,106},size={100,15},proc=update_var2D,title=" c_y (in A):",limits={0,10,0.1},value= lattice2
//	SetVariable Setlat1,pos={13,106},size={100,15},proc=update_var2D,title=" c_x (in A):",limits={0,10,0.1},value= lattice
	Button load_data,pos={10,124},size={100,25},proc=load_3DD,title="Load data"
	Button new_map,pos={140,80},size={90,20},proc=make_newD,title="New Map"
	
	PopupMenu nm,pos={120,124},size={76,20},proc=reloadD,title="MAP:",mode=1,popvalue="Choose",value= #maps
	
	//---Select normalization
	SetDrawEnv textrgb= (0,0,65280),fstyle= 1,fsize= 14;DrawText 7,170,"Norm. & Int."
	PopupMenu ddd,pos={12,177},size={76,20},proc=int_type_3DD,title="norm.:",mode=1,popvalue="non",value= "non;HBE;EDC;MDC;Interpol3D;EDM"
	SetVariable interpol,pos={100,177},size={100,20},proc=interp_3dD,title="Interpolate",limits={0,10000,1},value= num_interp
	
	SetVariable slice,pos={12,200},size={138,15},proc=setenergyD, title="slice energy", value = sliceenergy
	SetVariable dd,pos={12,220},size={80,20},proc=do_m_intMDCD,title="+/- :",limits={0,1000,1},value= int_range
	Button mk_map,pos={110,220},size={100,25},proc=make_kmapD,title="FS  k map"
	Button app_fit,pos={110,250},size={100,25},proc=append_FsfitD,title="add FS fit"
	Button reno1,fsize=13,pos={10,620},size={80,23},proc=EDC_normalization,title="EDC_norm"
	Button reno2,fsize=13,pos={10,645},size={125,23},proc=EDM_normalization,title="EDM_normalization"
	Button reno3,fsize=13,pos={90,620},size={80,23},proc=MDC_normalization,title="MDC_norm"
	
	//----Select Energy slice
	SetDrawEnv textrgb= (0,0,65280),fstyle= 1,fsize= 14;DrawText 7,260,"Utilities:"; 
	
	SetVariable e1,pos={12,270},size={100,15},proc=update_var2D,title="Polar:"
	SetVariable e1,limits={-90,90,0.1},value= s_polar
	SetVariable ee1,pos={12,290},size={100,15},proc=update_var2D,title="Azi:"
	SetVariable ee1,limits={-360,360,0.1},value= s_azi
	SetVariable eee1,pos={12,310},size={100,15},proc=update_var2D,title="Tilt:"
	SetVariable eee1,limits={-90,90,0.1},value= s_tilt
	PopupMenu sl,pos={120,290},size={76,20},proc=slit_selectD,title="Slit:",mode=1,popvalue="Choose",value= "hor.;vert;no corr"
	
	
	Button Go,pos={10,330},size={70,28},proc=CutD,title="Cut 1"
	Button Go1,pos={85,330},size={70,28},proc=Cut2D,title="Cut 2"
	
    	Button sedm,pos={10,370},size={75,28},proc=save_EDMD,title="Save EDM"
	Button sedc,pos={95,370},size={100,28},proc=save_EDCD,title="Save EDC/MDC"
	Button AC_F,pos={120,403},size={100,28},proc=AC_FSD,title="AutoCorrelate"
	Button Mov,pos={120,435},size={100,28},proc=Make_FS_movie2D,title="Make Movie"
	
	SetVariable EDCslice_but,pos={12,400},size={100,20},proc=make_EDCD,title="EDC slice",limits={DimOffset(ThreeDcut,0),DimOffset(ThreeDcut,0)+(DimSize(ThreeDcut,0)-1)*DimDelta(ThreeDcut,0),DimDelta(ThreeDcut,0)},value= EDC_slice
	SetVariable MDCslice_but,pos={12,420},size={100,20},proc=make_MDCD,title="MDC slice",limits={DimOffset(ThreeDcut,1),DimOffset(ThreeDcut,1)+(DimSize(ThreeDcut,1)-1)*DimDelta(ThreeDcut,1),DimDelta(ThreeDcut,1)},value= MDC_slice
	
     SetVariable maxcut,pos={12,440},size={100,20},title="Int. trip",limits={-10,10,0.001},value= AC_min

	PopupMenu addtb,pos={13,460},size={120,20},proc=add_tbD,title="",mode=1,popvalue="tb off",value= "tb off;Raghu;Zhang;Khorshunov;Parabola;Graser"
	
	SetVariable setazi,pos={130,560},size={100,28},title=" angle:",limits={-180,180,0.01},value= csrangle
	Button setazi1,pos={130,580},size={100,28},proc=rot_csrD,title="Rotate Csr"
	Button setazi2,pos={12,580},size={100,28},proc=set_csrD,title="Set Csr"
	
	
	
	Button sym,pos={60,700},size={120,28},proc=sym_3D_blockD,title="Symmetrize data"
	SetVariable ltr,pos={60,730},size={70,15},title="low trip:",limits={0,1,0.01},value= low_trip
	
	Display/K=1/Host=Cut3D/N=image/W=(0,0,0.4,0.5); AppendImage TwoDwave; AppendToGraph liney vs linex; 
	ModifyImage TwoDwave ctab= {*,*,BlueHot,1}
	Display/K=1/Host=Cut3D/N=image2/W=(0.4,0,0.8,0.65); AppendImage ThreeDcut; AppendToGraph EDCliney vs EDClinex; AppendToGraph MDCliney vs MDClinex; 
	ModifyImage ThreeDcut ctab= {*,*,BlueHot,1}
	Display/K=1/Host=Cut3D/N=image3/W=(0,0.45,0.4,1); AppendImage ThreeDcut2;  
	ModifyImage ThreeDcut2 ctab= {*,*,BlueHot,1}
	Display/K=1/Host=Cut3D/N=EDC/W=(0.4,0.65,0.8,0.82); AppendToGraph EDCcut;
	Display/K=1/Host=Cut3D/N=MDC/W=(0.4,0.82,0.8,1); AppendToGraph MDCcut;

	Cursor/I/A=1/C=(0,0,64000)/W=Cut3D#image A TwoDwave DimOffset(TwoDwave,0)+5*DimDelta(TwoDwave,0),DimOffset(TwoDwave,1)+5*DimDelta(TwoDwave,1)
	Cursor/I/A=1/C=(0,0,64000)/W=Cut3D#image B TwoDwave DimOffset(TwoDwave,0)+20*DimDelta(TwoDwave,0),DimOffset(TwoDwave,1)+20*DimDelta(TwoDwave,1)
	ShowInfo/W=Cut3D
	
End

Function filetypehnuD(ctrlName,popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR ftype
	ftype= popNum
	
End


Function slitsizeD(ctrlName,popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR slsize 
	slsize= popNum
	
End

Function update_var2D(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	//NVAR slit_width
	SVAR crntdf
	SetDataFolder $crntdf
	
	put_k_EDM2D()
	//put_k_EDM22()
	
end

Function make_kmapD(ctrlName): ButtonControl
	String ctrlName
	
	Make/O/N=(1,1) k_wave_y, k_wave_x, plot_wave
	Variable K1, K2, K3
	Variable pol,n,m,k,x //dummy vars 
	NVAR Ef, s_tilt, s_azi, s_polar, pol_0, slit
	NVAR lattice1, lattice2
//	NVAR lattice
	Wave TwoDwave
	
	Make/O/N=(DimSize(TwoDwave,0)*DimSize(TwoDwave,1)) k_wave_x, k_wave_y,plot_wave
	
	Variable tstart, tdelta, tend, tilt_s, tilt_e, tilt
	tstart=Dimoffset(TwoDwave,0)
	tend=Dimoffset(TwoDwave,0)+ DimDelta(TwoDwave,0)*Dimsize(TwoDwave,0)
	tdelta=DimDelta(TwoDwave,0)
	tilt_s=Dimoffset(TwoDwave,1)
	tilt_e = Dimoffset(TwoDwave,1)+ DimDelta(TwoDwave,1)*Dimsize(TwoDwave,1)
	Duplicate/O TwoDwave, temp_wav
	if (Dimdelta(TwoDwave,1)<0)
		For (k=0;k<Dimsize(temp_wav,1);k+=1)
			TwoDwave[][k]=temp_wav[p][Dimsize(temp_wav,1)-k-1]
		endfor
		Setscale/P y,tilt_e,-Dimdelta(temp_wav,1),"" TwoDwave
		tilt_s=Dimoffset(TwoDwave,1)
		tilt_e = Dimoffset(TwoDwave,1)+ DimDelta(TwoDwave,1)*Dimsize(TwoDwave,1)
	endif
		
	
	if (slit ==0)
		//Polar and phi
		K1=s_polar
		K2=s_azi
	
		n=0
		m=0
		for (tilt=tilt_s; tilt <= tilt_e;tilt+=Dimdelta(TwoDwave,1))
			K3=tilt-s_tilt
	 		// horizontal slit
				k=0
				for (pol = tstart-K1; pol <= tend-K1; pol += tdelta) 
					//original 032021
//					k_wave_x[n]=0.512*sqrt(Ef)*(lattice1/pi)*(sin((pol)*pi/180)*cos((K2)*pi/180)*cos((K3)*pi/180)-sin((K2)*pi/180)*sin((K3)*pi/180))
//					k_wave_y[n]=0.512*sqrt(Ef)*(lattice1/pi)*(sin((pol)*pi/180)*sin((K2)*pi/180)*cos((K3)*pi/180)+cos((K2)*pi/180)*sin((K3)*pi/180))
					
					//Added by SS 032021, convention from ref REVIEW OF SCIENTIFIC INSTRUMENTS 89, 043903 (2018)
					variable al,phi,del,th
					al = (pol+K1) * pi/180
					phi = K1 *pi/180
					del = K2 *pi/180
					th =  K3 *pi/180
					
					
					
					k_wave_x[n]=0.512*sqrt(Ef)*(lattice1/pi)*(-sin(al)*(cos(phi)*cos(del)) + cos(al)*(sin(th)*sin(del) + cos(th)*sin(phi)*cos(del)))
					k_wave_y[n]=0.512*sqrt(Ef)*(lattice1/pi)*(-sin(al)*(cos(phi)*sin(del)) + cos(al)*(cos(th)*sin(phi)*sin(del) - sin(th)*cos(del)))

					
//					variable/C Blue_mom = BlueZoneAngleToMomentum(Ef,K1,tilt,K2,pol+K1,2)
//					
//					k_wave_x[n] = Real(blue_mom)
//					k_wave_y[n] = Imag(blue_mom)
//					
//					variable k_x_E =0.512*sqrt(Ef)*(lattice1/pi)*(sin((pol)*pi/180)*cos((K2)*pi/180)*cos((K3)*pi/180)-sin((K2)*pi/180)*sin((K3)*pi/180))
//					variable k_y_E =0.512*sqrt(Ef)*(lattice1/pi)*(sin((pol)*pi/180)*sin((K2)*pi/180)*cos((K3)*pi/180)+cos((K2)*pi/180)*sin((K3)*pi/180))
					
					
//					k_wave_x[n]=0.512*sqrt(Ef)*(lattice/pi)*(sin((pol)*pi/180)*cos((K2)*pi/180)*cos((K3)*pi/180)-sin((K2)*pi/180)*sin((K3)*pi/180))
//					k_wave_y[n]=0.512*sqrt(Ef)*(lattice/pi)*(sin((pol)*pi/180)*sin((K2)*pi/180)*cos((K3)*pi/180)+cos((K2)*pi/180)*sin((K3)*pi/180))
					plot_wave[n]=TwoDwave[k][m]
					n=n+1
					k=k+1
				endfor
			m+=1
		endfor
	elseif(slit ==1)
		K1=s_polar
		K2=s_azi
	
		n=0
		m=0
		for (tilt=tilt_s; tilt <= tilt_e;tilt+=Dimdelta(TwoDwave,1))
			K3=tilt-s_tilt
	 		// horizontal slit
				k=0
				for (pol = tstart; pol <= tend; pol += tdelta) 
		
					x= pol
					k_wave_x[n]=0.5123*sqrt(Ef)*(lattice1/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*sin(K2*pi/180))
					k_wave_y[n]=0.5123*sqrt(Ef)*(lattice2/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*cos(K2*pi/180))
	
//					k_wave_x[n]=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*sin(K2*pi/180))
//					k_wave_y[n]=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*cos(K2*pi/180))
					plot_wave[n]=TwoDwave[k][m]
					n=n+1
					k=k+1
				endfor
			m+=1
		endfor
	elseif(slit == 2)
		
		Variable p,a,t
		a= -s_azi
		n=0
		m=0
		for (tilt=tilt_s; tilt <= tilt_e;tilt+=Dimdelta(TwoDwave,1))
			t=tilt-s_tilt
	 		// horizontal slit
				k=0
				for (pol = tstart; pol <= tend; pol += tdelta) 
					p = pol-s_polar
				
					K1=p*cos(a*pi/180)+t*sin(a*pi/180)
					K2=-p*sin(a*pi/180)+t*cos(a*pi/180)
					k_wave_x[n] = 0.5123*sqrt(Ef)*(lattice1/Pi)*sin(K1*pi/180)
					k_wave_y[n] = 0.5123*sqrt(Ef)*(lattice2/Pi)*sin(K2*pi/180)

//					k_wave_x[n] = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K1*pi/180)
//					k_wave_y[n] = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K2*pi/180)
					plot_wave[n]=TwoDwave[k][m]
					n=n+1
					k=k+1
				endfor
			m+=1
		endfor
	endif
	
	SVAR crntdf
	NVAR sliceenergy
	String/G fsname = Replacestring("root:",crntdf,"")+"_"+num2str(abs(sliceenergy))+"eV"
	fsname = replacestring(".",fsname,"p")
	String kwave_x = "root:kMAPS:"+fsname + "_x"
	String kwave_y = "root:kMAPS:"+fsname + "_y"
	String kwav = fsname + "_y"
	
	String kwave = "root:kMAPS:"+fsname + "_int"
	Duplicate/O k_wave_x, $kwave_x
	Duplicate/O k_wave_y, $kwave_y
	Duplicate/O plot_wave, $kwave
	
//	Erik Display method
//	Display/K=1/W=(100,100,600,600);
////	AppendImage $kwave vs {$kwave_x, $kwave_y};
////	ModifyImage $kwave ctab= {*,*,RedWhiteBlue,1}
////	ModifyGraph fSize=20;DelayUpdate
//	
//	AppendToGraph $kwave_y vs $kwave_x;
//	ModifyGraph zColor($kwav)={$kwave,*,*,Grays,1}
//	ModifyGraph mode($kwav)=3,marker($kwav)=19,msize($kwav)=4
//		
//	ModifyGraph fSize=22;DelayUpdate
//	Label left "\\Z24k\\By\\M \\Z24(\\F'symbol'p\\F'geneva'/a)";DelayUpdate
//	Label bottom "\\Z24k\\Bx\\M \\Z24(\\F'symbol'p\\F'geneva'/a)"
//	ModifyGraph nticks(left)=3,minor=1
//	if (DimDelta(temp_wave,1)<0)
//		Duplicate/O temp_wav, TwoDwave
//	endif
//	Killwaves temp_wav
////	
	
	///Lewis  Display method
	Display/K=1/W=(100,100,600,600);
	
	wave kxkymap = kxyztoimage($kwave_x, $kwave_y, $kwave,dimsize(twoDwave,0),dimsize(twoDwave,1))
	string kxkyname = nameofwave(kxkymap)
	appendimage kxkymap		
	ModifyGraph fSize=22;DelayUpdate
	Label left "k\By\M (Å\S-1\M)";DelayUpdate
	Label bottom "k\Bx\M (Å\S-1\M)"
	ModifyGraph minor=1, width={plan, 1, bottom, left}, zero=1,standoff=1,axthick=2, mirror=2
	ModifyImage $kxkyname ctab= {,,BlueHot,1}
	
	Killwaves temp_wav
//	///
	
end

Function app_FS_fitD(ctrlName): ButtonControl
	String ctrlName
	
	Make/O/N=(1,1) k_fit_y, k_fit_x, plot_fit
	Variable K1, K2, K3
	Variable tilt,pol,n,m,k,x //dummy vars 
	NVAR Ef, s_tilt, s_azi, s_polar, pol_0, tilt_0, slit
	NVAR lattice1, lattice2
//	NVAR lattice
	String fitname
	SetDatafolder root:FSfits
	Variable foln
	String namelist = WaveList("*", ";", "DIMS:1")
	Prompt foln "Which fit?", popup namelist
	DoPrompt "Select", foln
	if (V_flag == 1)
		return 1
	endif

	fitname = StringFromList(foln-1,namelist)
	SetDatafolder root:
	String newdf
	Setdatafolder $newdf
	Wave fit_wave = root:FSfits:$fitname
	Make/O/N=(DimSize(fit_wave,0)) k_fit_x, k_fit_y,plot_fit
	
	if (slit ==0)
		//Polar and phi
		K1=s_polar
		K2=s_azi

		for (n=0; n <Dimsize(fit_wave,0);n+=1)
			tilt = fit_wave[n][1]
			pol = fit_wave[n][0]
			K3=tilt-s_tilt
	 		// horizontal slit
			k_fit_x[n]=0.512*sqrt(Ef)*lattice1/pi *(sin((pol)*pi/180)*cos((K2)*pi/180)*cos((K3)*pi/180)-sin((K2)*pi/180)*sin((K3)*pi/180))
			k_fit_y[n]=0.512*sqrt(Ef)*lattice2/pi *(sin((pol)*pi/180)*sin((K2)*pi/180)*cos((K3)*pi/180)+cos((K2)*pi/180)*sin((K3)*pi/180))
//			k_fit_x[n]=0.512*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*cos((K2)*pi/180)*cos((K3)*pi/180)-sin((K2)*pi/180)*sin((K3)*pi/180))
//			k_fit_y[n]=0.512*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*sin((K2)*pi/180)*cos((K3)*pi/180)+cos((K2)*pi/180)*sin((K3)*pi/180))
			plot_fit[n]=5
		endfor
	elseif(slit ==1)
		K1=s_polar
		K2=s_azi
	
		for(n=0; n <Dimsize(fit_wave,0);n+=1)
			tilt = fit_wave[n][1]
			pol = fit_wave[n][0]
			K3=tilt-s_tilt
	 		// horizontal slit
			
			x= pol
			k_fit_x[n]=0.5123*sqrt(Ef)*(lattice1/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*sin(K2*pi/180))
			k_fit_y[n]=0.5123*sqrt(Ef)*(lattice2/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*cos(K2*pi/180))
//			k_fit_x[n]=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*sin(K2*pi/180))
//			k_fit_y[n]=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*cos(K2*pi/180))
			plot_fit[n]=5				
		endfor
	elseif(slit == 2)
		
		Variable p,a,t
		a= s_azi
		n=0
		m=0
		for (n=0; n <Dimsize(fit_wave,0);n+=1)
			tilt = fit_wave[n][1]
			pol = fit_wave[n][0]
			t=tilt-s_tilt
	 		p = pol-s_polar
				
			K1=p*cos(a*pi/180)+t*sin(a*pi/180)
			K2=-p*sin(a*pi/180)+t*cos(a*pi/180)
			k_fit_x[n] = 0.5123*sqrt(Ef)*(lattice1/Pi)*sin(K1*pi/180)
			k_fit_y[n] = 0.5123*sqrt(Ef)*(lattice2/Pi)*sin(K2*pi/180)
//			k_fit_x[n] = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K1*pi/180)
//			k_fit_y[n] = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K2*pi/180)
			plot_fit[n]=5
		endfor
	endif
	AppendToGraph/W=FSmap k_fit_y vs k_fit_x;
	ModifyGraph/W=FSmap mode(k_fit_y)=3,marker(k_fit_y)=19,msize(k_fit_y)=4
	ModifyGraph/W=FSmap zColor(k_fit_y)={plot_fit,*,*,BlueHot,1}	
	Killwaves temp_wav

end

Function make_newD(ctrlName): ButtonControl
	String ctrlName
	SetDataFolder root:
	NVAR mapcnt
	SVAR maplist
	String/G newdf = "root:FSMAP" + num2str(mapcnt)
	Variable n, nmax
	nmax = CountObjects("root:",4)
	 
	maplist = "\""+";"
	for (n=1;n<nmax;n+=1)
		maplist = maplist + GetIndexedObjName("root:", 4, n) + ";"
	endfor
	maplist = maplist + "FSMAP" + num2str(mapcnt)+"\""
	mapcnt += 1
	
	NewDataFolder/S/O $newdf
	
	SVAR crdf = root:newdf
	String/G crntdf = crdf
	SVAR maps = root:maplist
   	String/G namewave="Int3D"
   	String/G namewave2="Int3D"
   
    	Variable/G normal
    	Variable/G Ef = 16.89
	Variable/G lattice1 = 3.1415
	Variable/G lattice2 = 3.1415
//	Variable/G lattice = 4.51
	Variable/G intensity = 5000
	Variable/G int_around = 0
	Variable/G int_range = 1
	Variable/G sliceenergy = 0
	Variable/G EDC_slice = 0
	Variable/G MDC_slice = 0
	Variable/G num_interp =0
	Variable/G points = 0
	Variable/G tt1=-1
	Variable/G tt2=1.3
	Variable/G tt3=-0.85
	Variable/G tt4=-0.85
	Variable/G tta1=-0.6
	Variable/G tta2=0.3
	Variable/G tta3=0.24
	Variable/G ttb1=-0.4
	Variable/G ttb2=0.2
	Variable/G ttb3=0.24
	Variable/G ttc1=1.7
	Variable/G ttc2=1.14
	Variable/G ttc3=0.74
	Variable/G ttd1=1.7
	Variable/G ttd2=1.14
	Variable/G ttd3=-0.64
	
	Variable/G tmu =1.45
	Variable/G tscale = 1
	Variable/G pol_0 = 0
	Variable/G tilt_0 = 0
	Variable/G s_tilt = 0
	Variable/G s_polar = 0
	Variable/G s_azi = 0
	Variable/G slit=0
	Variable/G slsize=1
	Variable/G ftype = 1
	Variable/G AC_min = 0
	Variable/G low_trip = 0
	Variable/G csrangle =0
	String/G gold_name, file_name, strip_name, fname, f_name, Au_path
	
	Variable/G kx_b,ky_b,kpar_b,kx_e,ky_e,kpar_e,k_inc
	Variable/G kx_b2,ky_b2,kpar_b2,kx_e2,ky_e2,kpar_e2,k_inc2
	
	String/G tbswitch = "tb off"
  	Make/O/N=(1,1) TwoDwave ,ThreeDcut,ThreeDcut2, kEDM

	Make/O/N=1 linex, liney, EDCcut, MDCcut, EDClinex, EDCliney, MDClinex, MDCliney
	Make/O/N=(DimSize(ThreeDcut,0)) Ep,Em, Eps,Ems,Emsa, Epf,Emf, Epsf,Emsf, Emsaf,Ep2, Em2, Eps2, Ems2, Ems2a
	
	Cut3DFuncD()
End


Function do_m_intMDCD(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	Wave Int3D
	
	SVAR namewave
	
	if(exists("Int3D")==1)
		plot_3DD(namewave)
	endif
end

Function slit_selectD(ctrlName,popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR slit
	if (popNum ==1)
		slit=0
	elseif(popNum == 2) 
		slit =1
	elseif(popNum == 3)
		slit = 2	
	endif
	print popNum,slit
	put_k_EDM2D()
end

Function reloadD(ctrlName,popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	String chdf
	chdf = "root:" + popStr
	
	RemoveImage/W=Cut3D#image TwoDwave
	RemoveImage/W=Cut3D#image2 ThreeDcut
	RemoveImage/W=Cut3D#image3 ThreeDcut2
	RemoveFromGraph/W=Cut3D#image liney
	RemoveFromGraph/W=Cut3D#image2 EDCliney, MDCliney
	RemoveFromGraph/W=Cut3D#EDC EDCcut
	RemoveFromGraph/W=Cut3D#MDC MDCcut
	
	SetDataFolder $chdf
	
	SVAR crntdf
	SVAR maps = root:maplist
   	SVAR namewave,namewave2
   	NVAR normal,Ef,intensity, int_around,int_range, sliceenergy,EDC_slice,MDC_slice,num_interp, points
 	NVAR lattice1, lattice2
//	NVAR lattice
	NVAR tta1,tta2,tta3,ttb1,ttb2,ttb3,ttc1,ttc2,ttc3,ttd1,ttd2,ttd3
	NVAR tt1,tt2,tt3,tt4,tmu, tscale
	NVAR s_tilt,s_polar,s_azi 
	NVAR slit, csrangle
	SVAR gold_name, file_name, strip_name, fname, f_name, Au_path
	SVAR tbswitch
	
	//-----Select data
	
	SetVariable Setau,value= gold_name
	SetVariable SetEf,value= Ef
	SetVariable SetIntensity,value= Intensity
	SetVariable Setlat1,value= lattice1
//	SetVariable Setlat1,value= lattice
		
	//---Select normalization	
	SetVariable slice,value = sliceenergy
	SetVariable dd,value= int_range
	
	
	//----Select Energy slice
    Wave TwoDwave ,ThreeDcut,ThreeDcut2

	Wave linex, liney, EDCcut, MDCcut, EDClinex, EDCliney, MDClinex, MDCliney
	Wave Ep,Em, Eps,Ems, Emsa, Epf,Emf, Epsf,Emsf, Emsaf,Ep2, Em2, Eps2, Ems2, Ems2a
	
	SetVariable EDCslice_but,value= EDC_slice
	SetVariable MDCslice_but,value= MDC_slice
	SetVariable interpol,value= num_interp
	
	SetVariable Setlt1,value= tt1
	SetVariable Setlsc,value= tscale
	SetVariable Sett2,value= tt2
	SetVariable Sett3,value= tt3
	SetVariable Sett4,value= tt4
	SetVariable Setmu,value= tmu
	
	SetVariable e1,value= s_polar
	SetVariable ee1,value= s_azi
	SetVariable eee1,value= s_tilt
	
	SetVariable Setta1,value= tta1
	SetVariable Setta2,value= tta2
	SetVariable Setta3,value= tta3
	
	SetVariable Settb1,value= ttb1
	SetVariable Settb2,value= ttb2
	SetVariable Settb3,value= ttb3
	
	SetVariable Settc1,value= ttc1
	SetVariable Settc2,value= ttc2
	SetVariable Settc3,value= ttc3
	
	SetVariable Settd1,value= ttd1
	SetVariable Settd2,value= ttd2
	SetVariable Settd3,value= ttd3
	SetVariable setazi,value = csrangle
	
	AppendImage/W=Cut3D#image TwoDwave;
	ModifyImage/W=Cut3D#image TwoDwave ctab= {*,*,Bluehot,1} 
	AppendToGraph/W=Cut3D#image liney vs linex
	AppendImage/W=Cut3D#image2 ThreeDcut;
	ModifyImage/W=Cut3D#image2 ThreeDcut ctab= {*,*,Bluehot,1} 
	AppendToGraph/W=Cut3D#image2 EDCliney vs EDClinex; 
	AppendToGraph/W=Cut3D#image2 MDCliney vs MDClinex; 
	AppendImage/W=Cut3D#image3 ThreeDcut2;  
	ModifyImage/W=Cut3D#image3 ThreeDcut2 ctab= {*,*,Bluehot,1}
	
	AppendToGraph/W=Cut3D#EDC EDCcut;
	AppendToGraph/W=Cut3D#MDC MDCcut;

	//Cursor/I/A=1/C=(64000,64000,64000)/W=Cut3D#image A TwoDwave DimOffset(TwoDwave,0)+5*DimDelta(TwoDwave,0),DimOffset(TwoDwave,1)+5*DimDelta(TwoDwave,1)
	//Cursor/I/A=1/C=(64000,64000,64000)/W=Cut3D#image B TwoDwave DimOffset(TwoDwave,0)+20*DimDelta(TwoDwave,0),DimOffset(TwoDwave,1)+20*DimDelta(TwoDwave,1)

	if(exists("Int3D")==1)
		plot_3DD(namewave)
		CutD("bla")
	endif
End

Function int_type_3DD(ctrlName,popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	SVAR namewave
	SVAR namewave2 //for the interpolation routine
	SVAR crntdf
	
	SetDataFolder $crntdf
	NVAR normal
	normal=popNum
	
	if(exists("Int3D")==1)
		if(normal==1)
			namewave="Int3D"
			namewave2="Int3D"
			plot_3DD(namewave)
		elseif(normal==2)
			namewave="Int3D_HBE"
			namewave2="Int3D_HBE"
			plot_3DD(namewave)
//		elseif(normal==3)
//			namewave="Int3D_Ef"
//			namewave2="Int3D_HBE"
//			plot_3DD(namewave)
		elseif(normal==3)
			namewave="Int3D_EDC"
			namewave2="Int3D_EDC"
			plot_3DD(namewave)
		elseif(normal==4)
			namewave="Int3D_MDC"
			namewave2="Int3D_MDC"
			plot_3DD(namewave)
		elseif(normal==5)
			namewave="Interpol3D"
			namewave2="Interpol3D"
			plot_3DD(namewave)
//		elseif(normal==5)
//			namewave="Int3D_1c"
//			namewave2="Int3D_1c"
//			plot_3DD(namewave)
//		elseif (normal==4)
//			namewave="Int3D_sym"
//			namewave2="Int3D_sym"
//			plot_3DD(namewave)
		else
			namewave="Int3D_EDM"
			namewave2="Int3D_EDM"
			plot_3DD(namewave)
		endif
	endif
	
end

Function Cut3DblockD(ThreeDwave)
	String ThreeDwave

	NVAR sliceenergy, int_range
	Wave w = $ThreeDwave
	Variable counter = 0, zdup, z, x, intrange
	z = (sliceenergy-DimOffset(w,1))/DimDelta(w,1)
	zdup = z

	Duplicate/O w, TwoDwave
	Redimension/N=(-1,DimSize(w,2),0) TwoDwave;// DoUpdate
	SetScale/P y, DimOffset(w,2), DimDelta(w,2), TwoDwave
	
	intrange = int_range/(DimDelta(w,1)*1000)
	
	Make/O/N=(DimSize(w,0),DimSize(w,2)) MDM
	MDM=0
	if (z<intrange)
		for (x=0; x <z+intrange; x+=1)
			MDM[][] += w[p][x][q]
		endfor
	elseif (z > (DimSize(w,1)-intrange))
		for (x=z-intrange; x <DimSize(w,1); x+=1)
			MDM[][] += w[p][x][q]
		endfor
	else
		for (x=z-intrange; x <z+intrange; x+=1)
			MDM[][] += w[p][x][q]
		endfor
	endif
	
	TwoDwave[][] = MDM[p][q]

	Variable xa, xb, ya, yb

	String csrapresent, csrbpresent
	csrapresent = CsrInfo(A, "Cut3D#image")
	csrbpresent = CsrInfo(B, "Cut3D#image")
	if(Strlen(csrapresent)==0)
		Cursor/I/A=1/W=Cut3D#image A TwoDwave DimOffset(TwoDwave,0)+5*DimDelta(TwoDwave,0),DimOffset(TwoDwave,1)+5*DimDelta(TwoDwave,1)
	endif
	if(Strlen(csrbpresent)==0)
		Cursor/I/A=1/W=Cut3D#image B TwoDwave DimOffset(TwoDwave,0)+20*DimDelta(TwoDwave,0),DimOffset(TwoDwave,1)+20*DimDelta(TwoDwave,1)	
	endif
		
	xa = pcsr(A, "Cut3D#image")
	ya = qcsr(A, "Cut3D#image")
	xb = pcsr(B, "Cut3D#image")
	yb = qcsr(B, "Cut3D#image")
	Make/O/N=2 xTrace, yTrace
	xTrace[0] = xa*DimDelta(w,0)+DimOffset(w,0); xTrace[1] = xb*DimDelta(w,0)+DimOffset(w,0);
	yTrace[0] = ya*DimDelta(w,2)+DimOffset(w,2); yTrace[1] = yb*DimDelta(w,2)+DimOffset(w,2);

	for(z=0;z<DimSize(w,1);z+=1)
		TwoDwave[][] = w[p][z][q]// ;DoUpdate
		ImageLineProfile/SC srcWave=TwoDwave, xWave=xTrace, yWave=yTrace
		Wave W_ImageLineProfile
		SetScale/P x, DimOffset(w,0), DimDelta(w,0), W_ImageLineProfile
		if(counter==0)
			counter=1
			Duplicate/O W_ImageLineProfile, ThreeDcut
			Redimension/N=(-1,DimSize(w,1)) ThreeDcut
			SetScale/P y, DimOffset(w,1), DimDelta(w,1), ThreeDcut
		endif
		ThreeDcut[][z] = W_ImageLineProfile[p]
	endfor
	TwoDwave[][] = MDM[p][q]
	
	Variable slope=(yb-ya)*DimDelta(w,2)/((xb-xa)*DimDelta(w,2))
	Make/O/N=(Round(Sqrt((abs(xb-xa))^2+(abs(yb-ya))^2))+1) linex, liney

	if(xb==xa&&yb>ya)
		for(x=0;x<Dimsize(linex,0);x+=1)
			liney[x] = ya*DimDelta(w,2)+DimOffset(w,2) + x*abs(yb-ya)/(DimSize(linex,0)-1)*DimDelta(w,2)
			linex[x] = xa*DimDelta(w,0)+DimOffset(w,0)
		endfor
	elseif(xb==xa&&ya>yb)
		for(x=0;x<Dimsize(linex,0);x+=1)
			linex[x] = ya*DimDelta(w,2)+DimOffset(w,2) - x*abs(yb-ya)/(DimSize(linex,0)-1)*DimDelta(w,2)
			liney[x] = xa*DimDelta(w,0)+DimOffset(w,0)
		endfor
	elseif(xb>xa)
		for(x=0;x<Dimsize(linex,0);x+=1)
			liney[x] = ya*DimDelta(w,2)+DimOffset(w,2) + slope*x*abs(xb-xa)*DimDelta(w,2)/(DimSize(linex,0)-1)
			linex[x] = xa*DimDelta(w,0)+DimOffset(w,0) + x*abs(xb-xa)*DimDelta(w,0)/(DimSize(linex,0)-1)
		endfor
	else
		for(x=0;x<Dimsize(linex,0);x+=1)
			liney[x] = ya*DimDelta(w,2)+DimOffset(w,2) - slope*x*abs(xb-xa)*DimDelta(w,2)/(DimSize(linex,0)-1)
			linex[x] = xa*DimDelta(w,0)+DimOffset(w,0) - x*abs(xb-xa)*DimDelta(w,0)/(DimSize(linex,0)-1)
		endfor
	endif
	NVAR EDC_slice, MDC_slice
	Duplicate/O ThreeDcut ThreeDcutN1
	
	put_k_EDM2D()

End

Function Cut3Dblock2D(ThreeDwave)
	String ThreeDwave

	NVAR sliceenergy, int_range
	Wave w = $ThreeDwave
	Variable counter = 0, zdup, z, x, intrange
	z = (sliceenergy-DimOffset(w,1))/DimDelta(w,1)
	zdup = z

	Duplicate/O w, TwoDwave
	Redimension/N=(-1,DimSize(w,2),0) TwoDwave;// DoUpdate
	SetScale/P y, DimOffset(w,2), DimDelta(w,2), TwoDwave
	
	intrange = int_range/(DimDelta(w,1)*1000)
	
	Make/O/N=(DimSize(w,0),DimSize(w,2)) MDM
	MDM=0
	if (z<intrange)
		for (x=0; x <z+intrange; x+=1)
			MDM[][] += w[p][x][q]
		endfor
	elseif (z > (DimSize(w,1)-intrange))
		for (x=z-intrange; x <DimSize(w,1); x+=1)
			MDM[][] += w[p][x][q]
		endfor
	else
		for (x=z-intrange; x <z+intrange; x+=1)
			MDM[][] += w[p][x][q]
		endfor
	endif
	
	TwoDwave[][] = MDM[p][q]

	Variable xa, xb, ya, yb

	String csrapresent, csrbpresent
	csrapresent = CsrInfo(A, "Cut3D#image")
	csrbpresent = CsrInfo(B, "Cut3D#image")
	if(Strlen(csrapresent)==0)
		Cursor/I/A=1/W=Cut3D#image A TwoDwave DimOffset(TwoDwave,0)+5*DimDelta(TwoDwave,0),DimOffset(TwoDwave,1)+5*DimDelta(TwoDwave,1)
	endif
	if(Strlen(csrbpresent)==0)
		Cursor/I/A=1/W=Cut3D#image B TwoDwave DimOffset(TwoDwave,0)+20*DimDelta(TwoDwave,0),DimOffset(TwoDwave,1)+20*DimDelta(TwoDwave,1)	
	endif
		
	xa = pcsr(A, "Cut3D#image")
	ya = qcsr(A, "Cut3D#image")
	xb = pcsr(B, "Cut3D#image")
	yb = qcsr(B, "Cut3D#image")
	Make/O/N=2 xTrace, yTrace
	xTrace[0] = xa*DimDelta(w,0)+DimOffset(w,0); xTrace[1] = xb*DimDelta(w,0)+DimOffset(w,0);
	yTrace[0] = ya*DimDelta(w,2)+DimOffset(w,2); yTrace[1] = yb*DimDelta(w,2)+DimOffset(w,2);

	for(z=0;z<DimSize(w,1);z+=1)
		TwoDwave[][] = w[p][z][q]// ;DoUpdate
		ImageLineProfile/SC srcWave=TwoDwave, xWave=xTrace, yWave=yTrace
		Wave W_ImageLineProfile
		SetScale/P x, DimOffset(w,0), DimDelta(w,0), W_ImageLineProfile
		if(counter==0)
			counter=1
			Duplicate/O W_ImageLineProfile, ThreeDcut2
			Redimension/N=(-1,DimSize(w,1)) ThreeDcut2
			SetScale/P y, DimOffset(w,1), DimDelta(w,1), ThreeDcut2
		endif
		ThreeDcut2[][z] = W_ImageLineProfile[p]
	endfor
	TwoDwave[][] = MDM[p][q]
	
	Duplicate/O ThreeDcut2 ThreeDcutN2
	put_k_EDM22D()

End

Function put_k_EDM2D()
	
	NVAR Ef, lattice1, lattice2
//	NVAR Ef, lattice
	NVAR slit
	Wave  ThreeDcutN1, kEDM, TwoDwave
	Variable xa,ya,xb,yb,pol_a,pol_b,tilt_a,tilt_b, pola, polb, tilta, tiltb, alpha
	NVAR kx_b,ky_b,kpar_b,kx_e,ky_e,kpar_e,k_inc
	Variable pol_inc = Dimsize(ThreeDcutN1,0) //number of chanels along the slit 
	Variable K1, K2, K3, x, norm_vec
	NVAR s_polar, s_tilt, s_azi//, pol_0, tilt_0, azi_0
	SVAR tbswitch
	Duplicate/O ThreeDcutN1 kEDM
	
	//Polar and phi of two csr points
	pola = xcsr(A, "Cut3D#image")
	tilta = vcsr(A, "Cut3D#image")
	polb = xcsr(B, "Cut3D#image")
	tiltb = vcsr(B, "Cut3D#image")
	
	if (slit == 0)
		K1=pola-s_polar
		K2 = s_azi
		K3 = tilta - s_tilt
		
		kx_b=0.5123*sqrt(Ef)*(lattice1/Pi)*(sin((K1)*pi/180)*cos(K2*pi/180)-cos((K1)*pi/180)*sin(K3*pi/180)*sin(K2*pi/180))
		ky_b=0.5123*sqrt(Ef)*(lattice2/Pi)*(sin((K1)*pi/180)*sin(K2*pi/180)+cos((K1)*pi/180)*sin(K3*pi/180)*cos(K2*pi/180))
//		kx_b=0.5123*sqrt(Ef)*(lattice/Pi)*(sin((K1)*pi/180)*cos(K2*pi/180)-cos((K1)*pi/180)*sin(K3*pi/180)*sin(K2*pi/180))
//		ky_b=0.5123*sqrt(Ef)*(lattice/Pi)*(sin((K1)*pi/180)*sin(K2*pi/180)+cos((K1)*pi/180)*sin(K3*pi/180)*cos(K2*pi/180))

	elseif(slit == 1)
		K1 = s_polar
		K2 = s_azi
		K3 = tilta-s_tilt
		x= pola
		kx_b=0.5123*sqrt(Ef)*(lattice1/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*sin(K2*pi/180))
		ky_b=0.5123*sqrt(Ef)*(lattice2/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*cos(K2*pi/180))

//		kx_b=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*sin(K2*pi/180))
//		ky_b=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*cos(K2*pi/180))


	elseif(slit ==2)
			Variable p = pola-s_polar
			Variable a = s_azi
			Variable t = tilta - s_tilt
			K1=p*cos(a*pi/180)+t*sin(a*pi/180)
			K2=-p*sin(a*pi/180)+t*cos(a*pi/180)
			kx_b = 0.5123*sqrt(Ef)*(lattice1/Pi)*sin(K1*pi/180)
			ky_b = 0.5123*sqrt(Ef)*(lattice2/Pi)*sin(K2*pi/180)

//			kx_b = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K1*pi/180)
//			ky_b = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K2*pi/180)



	endif
	
	if (slit == 0)
		
		K1= polb-s_polar
		K3 = -s_tilt +tiltb
		 	
		kx_e=0.5123*sqrt(Ef)*(lattice1/Pi)*(sin((K1)*pi/180)*cos(K2*pi/180)-cos((K1)*pi/180)*sin(K3*pi/180)*sin(K2*pi/180))
		ky_e=0.5123*sqrt(Ef)*(lattice2/Pi)*(sin((K1)*pi/180)*sin(K2*pi/180)+cos((K1)*pi/180)*sin(K3*pi/180)*cos(K2*pi/180))

//		kx_e=0.5123*sqrt(Ef)*(lattice/Pi)*(sin((K1)*pi/180)*cos(K2*pi/180)-cos((K1)*pi/180)*sin(K3*pi/180)*sin(K2*pi/180))
//		ky_e=0.5123*sqrt(Ef)*(lattice/Pi)*(sin((K1)*pi/180)*sin(K2*pi/180)+cos((K1)*pi/180)*sin(K3*pi/180)*cos(K2*pi/180))


	elseif(slit == 1)
		K1 = s_polar
		K2 = s_azi
		K3 = tiltb-s_tilt
		x= polb
		
		kx_e=0.5123*sqrt(Ef)*(lattice1/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*sin(K2*pi/180))
		ky_e=0.5123*sqrt(Ef)*(lattice2/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*cos(K2*pi/180))

//		kx_e=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*sin(K2*pi/180))
//		ky_e=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*cos(K2*pi/180))

	elseif(slit ==2)
			Variable pe = polb-s_polar
			Variable ae = s_azi
			Variable te = tiltb - s_tilt
			K1=pe*cos(ae*pi/180)+te*sin(ae*pi/180)
			K2=-pe*sin(ae*pi/180)+te*cos(ae*pi/180)
			kx_e = 0.5123*sqrt(Ef)*(lattice1/Pi)*sin(K1*pi/180)
			ky_e = 0.5123*sqrt(Ef)*(lattice2/Pi)*sin(K2*pi/180)
			
//			kx_e = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K1*pi/180)
//			ky_e = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K2*pi/180)		
		
	endif
	
		
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
			
			if ((kx_b >=0)&&(ky_b <= 0)&&(kx_e >= 0)&&(ky_e <= 0))
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
				
			if (kpar_b > 1)
				kpar_b = kpar_b - 1
			endif
			
			if (kpar_b < -1)
				kpar_b = kpar_b +1
			endif
			
				
			SetScale	/P x, kpar_b,k_inc,"", kEDM
//			SetScale	/P y, Dimoffset(kEDM,1)-Ef,dimdelta(kEDM,1),"", kEDM //Steef added 06-06-2019
		
		
		Duplicate/O kEDM ThreeDcut		
		
		NVAR EDC_slice, MDC_slice
		//EDC_slice = 0; MDC_slice = 0
		SetVariable EDCslice_but,limits={Dimoffset(ThreeDcut,0),Dimoffset(ThreeDcut,0)+(DimSize(ThreeDcut,0)-1)*DimDelta(ThreeDcut,0),DimDelta(ThreeDcut,0)},value= EDC_slice
		SetVariable MDCslice_but,limits={Dimoffset(ThreeDcut,1),Dimoffset(ThreeDcut,1)+(DimSize(ThreeDcut,1)-1)*DimDelta(ThreeDcut,1),DimDelta(ThreeDcut,1)},value= MDC_slice
		
		Make_EDCD("bla",EDC_slice,"bla","bla")
		Make_MDCD("bla",MDC_slice,"bla","bla")
		
		SetAxis /W=Cut3D#image2 bottom, Dimoffset(ThreeDcut,0),DimOffset(ThreeDcut,0)+(DimSize(ThreeDcut,0)-1)*DimDelta(ThreeDcut,0)
		SetAxis /W=cut3D#image2 left, Dimoffset(ThreeDcut,1),DimOffset(ThreeDcut,1)+(DimSize(ThreeDcut,1)-1)*DimDelta(ThreeDcut,1)
		
		if (stringmatch(tbswitch,"Raghu")||stringmatch(tbswitch,"Zhang")||stringmatch(tbswitch,"Graser")||stringmatch(tbswitch,"Parabola"))
			calc_EkD()
		endif
End

Function put_k_EDM22D()
	NVAR Ef, lattice1, lattice2
//	NVAR Ef, lattice
	NVAR slit
	Wave  ThreeDcutN2, kEDM2, TwoDwave
	Variable xa,ya,xb,yb,pol_a,pol_b,tilt_a,tilt_b, pola, polb, tilta, tiltb, alpha
	NVAR kx_b2,ky_b2,kpar_b2,kx_e2,ky_e2,kpar_e2,k_inc2
	Variable pol_inc = Dimsize(ThreeDcutN2,0) //number of chanels along the slit 
	Variable K1, K2, K3, x, norm_vec
	NVAR s_polar, s_tilt, s_azi//, pol_0, tilt_0, azi_0
	SVAR tbswitch
	Duplicate/O ThreeDcutN2 kEDM2
	
	//Polar and phi of two csr points
	pola = xcsr(A, "Cut3D#image")
	tilta = vcsr(A, "Cut3D#image")
	polb = xcsr(B, "Cut3D#image")
	tiltb = vcsr(B, "Cut3D#image")
	
	
	
	if (slit == 0)
		K1=pola-s_polar
		K2 = s_azi
		K3 = tilta - s_tilt
		
		kx_b2=0.5123*sqrt(Ef)*(lattice1/Pi)*(sin((K1)*pi/180)*cos(K2*pi/180)-cos((K1)*pi/180)*sin(K3*pi/180)*sin(K2*pi/180))
		ky_b2=0.5123*sqrt(Ef)*(lattice2/Pi)*(sin((K1)*pi/180)*sin(K2*pi/180)+cos((K1)*pi/180)*sin(K3*pi/180)*cos(K2*pi/180))

//		kx_b2=0.5123*sqrt(Ef)*(lattice/Pi)*(sin((K1)*pi/180)*cos(K2*pi/180)-cos((K1)*pi/180)*sin(K3*pi/180)*sin(K2*pi/180))
//		ky_b2=0.5123*sqrt(Ef)*(lattice/Pi)*(sin((K1)*pi/180)*sin(K2*pi/180)+cos((K1)*pi/180)*sin(K3*pi/180)*cos(K2*pi/180))
	elseif(slit == 1)
		K1 = s_polar
		K2 = s_azi
		K3 = tilta-s_tilt
		x= pola
		kx_b2=0.5123*sqrt(Ef)*(lattice1/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*sin(K2*pi/180))
		ky_b2=0.5123*sqrt(Ef)*(lattice2/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*cos(K2*pi/180))

//		kx_b2=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*sin(K2*pi/180))
//		ky_b2=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*cos(K2*pi/180))
	elseif(slit ==2)
			Variable p = pola-s_polar
			Variable a = s_azi
			Variable t = tilta - s_tilt
			K1=p*cos(a*pi/180)+t*sin(a*pi/180)
			K2=-p*sin(a*pi/180)+t*cos(a*pi/180)
			kx_b2 = 0.5123*sqrt(Ef)*(lattice1/Pi)*sin(K1*pi/180)
			ky_b2 = 0.5123*sqrt(Ef)*(lattice2/Pi)*sin(K2*pi/180)

//			kx_b2 = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K1*pi/180)
//			ky_b2 = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K2*pi/180)
	endif
	
	if (slit == 0)
		
		K1= polb-s_polar
		K3 = -s_tilt +tiltb
		 	
		kx_e2=0.5123*sqrt(Ef)*(lattice1/Pi)*(sin((K1)*pi/180)*cos(K2*pi/180)-cos((K1)*pi/180)*sin(K3*pi/180)*sin(K2*pi/180))
		ky_e2=0.5123*sqrt(Ef)*(lattice2/Pi)*(sin((K1)*pi/180)*sin(K2*pi/180)+cos((K1)*pi/180)*sin(K3*pi/180)*cos(K2*pi/180))

//		kx_e2=0.5123*sqrt(Ef)*(lattice/Pi)*(sin((K1)*pi/180)*cos(K2*pi/180)-cos((K1)*pi/180)*sin(K3*pi/180)*sin(K2*pi/180))
//		ky_e2=0.5123*sqrt(Ef)*(lattice/Pi)*(sin((K1)*pi/180)*sin(K2*pi/180)+cos((K1)*pi/180)*sin(K3*pi/180)*cos(K2*pi/180))
	elseif(slit == 1)
		K1 = s_polar
		K2 = s_azi
		K3 = tiltb-s_tilt
		x= polb
		
		kx_e2=0.5123*sqrt(Ef)*(lattice1/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*sin(K2*pi/180))
		ky_e2=0.5123*sqrt(Ef)*(lattice2/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*cos(K2*pi/180))

//		kx_e2=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*sin(K2*pi/180))
//		ky_e2=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(x*pi/180)-sin(x*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(x*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(x*pi/180))*cos(K2*pi/180))
	elseif(slit ==2)
			Variable pe = polb-s_polar
			Variable ae = s_azi
			Variable te = tiltb - s_tilt
			K1=pe*cos(ae*pi/180)+te*sin(ae*pi/180)
			K2=-pe*sin(ae*pi/180)+te*cos(ae*pi/180)
			kx_e2 = 0.5123*sqrt(Ef)*(lattice1/Pi)*sin(K1*pi/180)
			ky_e2 = 0.5123*sqrt(Ef)*(lattice2/Pi)*sin(K2*pi/180)

//			kx_e2 = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K1*pi/180)
//			ky_e2 = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K2*pi/180)
	endif
			
			Variable/G kxb=kx_b2
			Variable kyb=ky_b2
			Variable kxe = kx_e2
			Variable kye = ky_e2
			Variable angle =  -atan2((ky_b2+ky_e2),(kx_b2+kx_e2))
		
			if ((kx_b2 <=0)&&(ky_b2 <=0)&&(kx_e2 <=0)&&(ky_e2 <=0))
				kx_b2 = kxb*cos(angle)-kyb*sin(angle)
				ky_b2 = kxb*sin(angle)+kyb*cos(angle)
				kx_e2 = kxe*cos(angle)-kye*sin(angle)
				ky_e2 = kxe*sin(angle)+kye*cos(angle)
			endif
			
			if ((kx_b2 >=0)&&(ky_b2 >=0)&&(kx_e2 >=0)&&(ky_e2 >=0))
				kx_b2 = kxb*cos(angle)-kyb*sin(angle)
				ky_b2 = kxb*sin(angle)+kyb*cos(angle)
				kx_e2 = kxe*cos(angle)-kye*sin(angle)
				ky_e2 = kxe*sin(angle)+kye*cos(angle)
			endif
			
			if ((kx_b2 >=0)&&(ky_b2 <= 0)&&(kx_e2 >= 0)&&(ky_e2 <= 0))
				kx_b2 = kxb*cos(angle)-kyb*sin(angle)
				ky_b2 = kxb*sin(angle)+kyb*cos(angle)
				kx_e2 = kxe*cos(angle)-kye*sin(angle)
				ky_e2 = kxe*sin(angle)+kye*cos(angle)
			endif
			
			if ((kx_b2 <= 0)&&(ky_b2 >= 0)&&(kx_e2 <= 0)&&(ky_e2 >= 0))
				kx_b2 = kxb*cos(angle)-kyb*sin(angle)
				ky_b2 = kxb*sin(angle)+kyb*cos(angle)
				kx_e2 = kxe*cos(angle)-kye*sin(angle)
				ky_e2 = kxe*sin(angle)+kye*cos(angle)
			endif

			if ((kx_b2 <=0)&&(ky_b2 <=0))
				kpar_b2=-sqrt(kx_b2*kx_b2+ky_b2*ky_b2)
				k_inc2=+sqrt((kx_e2-kx_b2)^2+(ky_e2-ky_b2)^2)/pol_inc
			elseif ((kx_b2 >= 0)&&(ky_b2 >= 0))
				kpar_b2=sqrt(kx_b2*kx_b2+ky_b2*ky_b2)
				k_inc2=-sqrt((kx_e2-kx_b2)^2+(ky_e2-ky_b2)^2)/pol_inc
			elseif	((kx_b2 >= 0)&&(ky_b2 <= 0))
				kpar_b2=-sqrt(kx_b2*kx_b2+ky_b2*ky_b2)
				k_inc2=+sqrt((kx_e2-kx_b2)^2+(ky_e2-ky_b2)^2)/pol_inc
			elseif	((kx_b2 <= 0)&&(ky_b2 >= 0))
				kpar_b2=-sqrt(kx_b2*kx_b2+ky_b2*ky_b2)
				k_inc2=+sqrt((kx_e2-kx_b2)^2+(ky_e2-ky_b2)^2)/pol_inc
			endif
			
			if (kpar_b2 > 2)
				kpar_b2 = kpar_b2 - 2
			endif
			
			if (kpar_b2 < -2)
				kpar_b2 = kpar_b2 + 2
			endif
				
			if (kpar_b2 > 1)
				kpar_b2 = kpar_b2 - 1
			endif
			
			if (kpar_b2 < -1)
				kpar_b2 = kpar_b2 +1
			endif
			
				
			SetScale	/P x, kpar_b2,k_inc2,"", kEDM2
		
		Duplicate/O kEDM2 ThreeDcut2		
		
		SetAxis /W=Cut3D#image3 bottom, Dimoffset(ThreeDcut2,0),DimOffset(ThreeDcut2,0)+(DimSize(ThreeDcut2,0)-1)*DimDelta(ThreeDcut2,0)
		SetAxis /W=cut3D#image3 left, Dimoffset(ThreeDcut2,1),DimOffset(ThreeDcut2,1)+(DimSize(ThreeDcut2,1)-1)*DimDelta(ThreeDcut2,1)

		if (stringmatch(tbswitch,"Raghu")||stringmatch(tbswitch,"Zhang")||stringmatch(tbswitch,"Parabola")||stringmatch(tbswitch,"Graser"))
			calc_ek2D()
		endif
End

Function CutD(ctrlName): ButtonControl
	String ctrlName
	SVAR namewave
	if(exists("Int3D")==1)
		Cut3DblockD(namewave)
	endif
End

Function Cut2D(ctrlName): ButtonControl
	String ctrlName
	SVAR namewave
	if(exists("Int3D")==1)
		Cut3Dblock2D(namewave)
	endif
End

Function AC_FSD(ctrlName): ButtonControl
	String ctrlName
	if(exists("Int3D")==1)
		FS_autocorrelationD()	
	endif
End

Function setenergyD(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	if(exists("Int3D")==1)
		NVAR sliceenergy,int_range
		SVAR namewave
		Wave w = $namewave
		Wave TwoDwave
		Variable z = (sliceenergy-DimOffset(w,1))/DimDelta(w,1)
		variable x
		variable intrange = int_range/(DimDelta(w,1)*1000)
	
		Make/O/N=(DimSize(w,0),DimSize(w,2)) MDM
		MDM=0
		if (z<intrange)
			for (x=0; x <z+intrange; x+=1)
				MDM[][] += w[p][x][q]
			endfor
		elseif (z > (DimSize(w,1)-intrange))
			for (x=z-intrange; x <DimSize(w,1); x+=1)
				MDM[][] += w[p][x][q]
			endfor
		else
			for (x=z-intrange; x <z+intrange; x+=1)
				MDM[][] += w[p][x][q]
			endfor
		endif
	
		TwoDwave[][] = MDM[p][q]
		
	endif
End

Function/S Diamond_HDF5_Auload()
	Variable/G file_ID
	String/G filename,filename2,fname, fname2
	
	HDF5OpenFile/I/R file_ID as ""
	if(V_flag!=0)
		return ""
	else
		filename = S_filename
		fname=replacestring("-",filename,"_")
		fname2=replacestring(".nxs",fname,"")
		fname="root:"+fname2
		NewDataFolder/O $fname
		HDF5LoadGroup $fname, file_ID, "entry1/analyser"
		HDF5CloseFile file_ID
		filename = fname+":angles"
		filename2 = fname+":energies"
		Wave w=$filename
		Wave v=$filename2
		Make/O/N=(dimsize(w,0),dimsize(v,0)) $fname2
		Variable dimx,dimy
		dimx=w[1]-w[0]
		dimy=v[1]-v[0]
		Setscale/P x,w[0],dimx,"" $fname2
		Setscale/P y,v[0],dimy,"" $fname2
		filename = fname+":data"
		Wave w=$filename
		Wave v=$fname2
		v[][]=w[0][p][q]
		KillDataFolder $fname
		Duplicate/O $fname2, dupwave
//		Duplicate/O/R=[155,853][] dupwave, $fname2
		Duplicate/O/R=[50][954] dupwave, $fname2
		Killwaves dupwave
		return fname2
	endif
End

Function PopupAuwave_3DD(ctrlName)
	String ctrlname
	
	SVAR gold_name
	NVAR Ef
	SVAR crntdf
	
	KillWaves/Z $gold_name
	gold_name = Diamond_HDF5_Auload()												// Loads the goldwave from the HDD as a file in 'root:CEM'
	Matrixtranspose $gold_name
	//estimates Ef, so you will not have to insert it by hand:
	Duplicate/O $gold_name dummy
	Make/O/N=(Dimsize(dummy,0)) gold_sect
	SetScale/P x Dimoffset(dummy,0),dimdelta(dummy,0),"", gold_sect
	Variable x
	for(x=0; x<Dimsize(dummy,1); x+=1)
		gold_sect+=dummy[p][x]
	endfor
	Smooth 50, gold_sect
	Differentiate gold_sect/D=gold_sect
	WaveStats/Q gold_sect
	Variable Ef_dummy=V_minloc

	KillWaves  dummy, gold_sect
	
	Ef = Ef_dummy
		
End

Function load_3DD(ctrlName)
	String ctrlname
	
	continue_loadD()
	
End

Function load_h5_SLSmap()
	Variable/G file_ID
	String/G filename,filename2, filename3,fname, fname2, dataname
	SVAR crntdf, gold_name
	
	fname2 = LoadSIStemHDF5_Easy("", targetFolder=getdatafolder(2))
End

Function continue_loading_noAuSLS()
	SVAR  fname2, namewave
	
	Duplicate/O $fname2, Int3D
	Killwaves/Z $fname2
	
	// transpose it correctly (slit angle, energy, perp angle)
	string wnote = note(Int3D)
	imagetransform/g=5 transposeVol Int3D
	wave M_VolumeTranspose
	duplicate/o M_VolumeTranspose Int3D
	killwaves/z M_VolumeTranspose
	Note Int3D, wnote
	
	// convert to KE for correct scaling
	variable WF,hnu
	variable WFstart = strsearch(wnote, "Work Function", 0)
	variable WFend = strsearch(wnote, "\r", WFstart)
	variable hnustart = strsearch(wnote, "Excitation Energy", 0)
	variable hnuend = strsearch(wnote, "\r", hnustart)
	sscanf wnote[WFstart,WFend], "Work Function (eV)=%g", WF
	sscanf wnote[hnustart,hnuend], "Excitation Energy (eV)=%g", hnu
//	setscale/p y, dimoffset(Int3D,1)+hnu-WF, dimdelta(Int3D,1), Int3D
	
	plot_3DD("Int3D")
	CutD("bla")
	Killwaves/Z phi, theta, tilt, manip_X_mm,manip_Y_mm, manip_Z_mm, Spectrum
	Killwaves/Z hv_eV, Ep_eV, KEf_eV, dt_ms, elapsed_time_secs, sweeps
End

Function continue_loadD()
	Variable/G file_ID
	String/G filename,filename2, filename3,fname, fname2, dataname
	SVAR crntdf, gold_name
	NVAR ftype
	
	if(ftype==1)
		LoadWave/O/T/Q
	elseif(ftype==2)
		load_hdf5fsmap()
	elseif(ftype==3)
		load_h5_slsmap()
		continue_loading_noAuSLS()
		return 0
	elseif(ftype==4)	
		// you need the load_krx_AMSTEL.ipf file for the following functions
		Wave loadedWave = load_krx_deflector_map64(1)
		PutInCorrectFormatForSlicer(loadedWave, 0)
		return 0
	endif
	
	if(stringmatch(gold_name,"")==1)	
		continue_loading_noAuD()
	else
		continue_loadingD()
	endif

End	
	
Function load_hdf5fsmap()
	Variable/G file_ID
	String/G filename,filename2, filename3,fname, fname2, dataname
	SVAR crntdf, gold_name
	
	HDF5OpenFile/I/R file_ID as ""
	filename = S_filename
	fname=replacestring("-",filename,"_")
	fname2=replacestring(".nxs",fname,"")
	fname="root:"+fname2
	NewDataFolder/O $fname
	HDF5LoadGroup $fname, file_ID, "entry1/analyser"
	HDF5CloseFile file_ID
	filename = fname+":angles"
	filename2 = fname+":energies"
	filename3 = fname+":sapolar"
	Duplicate/O $filename3, tilt
	wave u=$filename
	Wave w=$filename2
	Wave v=$filename3
	Variable dimx,dimy,dimz
	dimx=u[1]-u[0]//angles
	dimy=w[1]-w[0]//energies
	dimz=v[1]-v[0]//polar
	dataname = fname+":data"
	Wave spec=$dataname
	MatrixOp/O$fname2=transposeVol(spec,4) 
	NVAR pol_0, tilt_0
	Setscale/P x,u[0]-pol_0,dimx,"" $fname2
	Setscale/P y,w[0],dimy,"" $fname2
	Setscale/P z,v[0]-tilt_0,dimz,"" $fname2
	Duplicate/O $fname2,dupwave
//	Duplicate/O/R=[][][] dupwave, Spectrum
	Duplicate/O/R=[155,853][][] dupwave, Spectrum
//	Duplicate/O/R=[50,954][][] dupwave, $fname2
//	Duplicate/O/R=[125,895][][] dupwave, $fname2
	Killwaves dupwave, $fname2
	KillDataFolder $fname
	
End

Function continue_loadingD()
	SVAR namewave, gold_name, fname2
	NVAR pol_0, tilt_0, slsize, ftype
	Wave tilt
	Variable tstart, tdelta, tend, c
	
	Wave Spectrum = $fname2
	
	//---Now we have to normalize Spectrum to the gold ref.
	Variable n,nmax,x,y,z	
	
	Make/O/N=(DimSize(Spectrum,0),DimSize(Spectrum,1)) EDM
	Make/O/N=(DimSize(Spectrum,0),DimSize(Spectrum,1),DimSize(Spectrum,2)) Int3D
	
	nmax=DimSize(Spectrum,2)
	for (n=0;n<nmax;n+=1)
		EDM[][] = Spectrum[p][q][n]
		SetScale/P x,dimoffset($fname2,0),dimdelta($fname2,0), EDM
		SetScale/P y,dimoffset($fname2,1),dimdelta($fname2,1), EDM
		
		MatrixTranspose EDM
		CorrNorm_FM_3DD()
		
	// The EDM is now added to a 3D wave in order to allow for on-line integration, also the waves containg the angles are made
		
		
		Int3D[][][n]=EDM[p][q]
		SetScale/P x,DimOffset(EDM,0),DimDelta(EDM,0), Int3D 
		SetScale/P y,DimOffset(EDM,1),DimDelta(EDM,1), Int3D 
		if (tilt[1]-tilt[0]>0)
			SetScale/P z,tilt[0],(tilt[1]-tilt[0]),  Int3D
		else
			SetScale/P z,tilt[rightx(tilt)],-(tilt[1]-tilt[0]), Int3D
		endif
		
		
	endfor
	
	//killwaves/Z Int3D_EDM, Int3D_HBE, Int3D_Ef
	plot_3DD(namewave)
	CutD("bla")
	Killwaves/Z $fname2
	Killwaves/Z phi, theta, tilt, manip_X_mm,manip_Y_mm, manip_Z_mm, Spectrum
	Killwaves/Z hv_eV, Ep_eV, KEf_eV, dt_ms, elapsed_time_secs, sweeps
End

Function continue_loading_noAuD()
	SVAR  fname2, namewave
	Wave tilt
	NVAR ftype
//	Duplicate/O $fname2, Int3D

	wave/z KEi_eV, dE_eV
	
	Duplicate/O Spectrum, Int3D
	Killwaves/Z Spectrum
//	Killwaves/Z $fname2
	
	
	
	if (tilt[1]-tilt[0]>0)
		SetScale/P z,tilt[0],(tilt[1]-tilt[0]),  Int3D
		if(ftype==1)
			setscale/P y, kEi_eV[0], dE_eV[0], Int3d	//SS Added 06-06-2019
		endif
	else
		SetScale/P z,tilt[rightx(tilt)],-(tilt[1]-tilt[0]), Int3D
		if(ftype==1)
			Setscale/P y, kEi_eV[0], dE_eV[0], Int3d //SS added 06-06-2019
		endif
	endif
	Variable m,n,y,z,sume
//		
//	For(m=0;m<Dimsize(Int3D,2);m+=1)
//		Duplicate/O/R=[][][m] Int3D, dup_wave
//		Make/O/N=(Dimsize(dup_wave,0)) oneDnorm
//		for(y=0; y<Dimsize(dup_wave,0); y+=1)
//			sume=0
//			for(n=0; n<Dimsize(dup_wave,1)-1; n+=1)
//				oneDnorm[y]+=dup_wave[y][n]
//				sume+=1
//			endfor
//			oneDnorm[y]=oneDnorm[y]/sume
//		endfor
//	
//		for(y=0; y<Dimsize(dup_wave,0); y+=1)
//			for(z=0; z<Dimsize(dup_wave,1); z+=1)
//				dup_wave[y][z]/= oneDnorm[y]
//			endfor
//		endfor
//		Duplicate/O dup_wave EDC_norm
//		Int3D[][][m]=EDC_norm
//	endfor
	plot_3DD(namewave)
	CutD("bla")
	Killwaves/Z phi, theta, tilt, manip_X_mm,manip_Y_mm, manip_Z_mm, Spectrum
	Killwaves/Z hv_eV, Ep_eV, KEf_eV, dt_ms, elapsed_time_secs, sweeps
End

Function Normalization_3Ddiamond()


End


//Function EDC_normalization(ctrlName) : ButtonControl			//Shyama_1March2016
//	String ctrlName
//	Variable m, y, n, z, sume
//	SVAR namewave
//	
//	Duplicate/O Int3D Int3d_EDC
//	
//		For(m=0;m<Dimsize(Int3D,2);m+=1)
//			Duplicate/O/R=[][][m] Int3D, dup_wave
//			Make/O/N=(Dimsize(dup_wave,0)) oneDnorm
//			for(y=0; y<Dimsize(dup_wave,0); y+=1)
//				sume=0
//				for(n=0; n<Dimsize(dup_wave,1)-1; n+=1)
//					oneDnorm[y]+=dup_wave[y][n]
//					sume+=1
//				endfor
//				oneDnorm[y]=oneDnorm[y]/sume
//			endfor
//		
//			for(y=0; y<Dimsize(dup_wave,0); y+=1)
//				for(z=0; z<Dimsize(dup_wave,1); z+=1)
//					dup_wave[y][z]/= oneDnorm[y]
//				endfor
//			endfor
//			Duplicate/O dup_wave EDC_norm
//			Int3D_EDC[][][m]=EDC_norm[p][q]
//		endfor
//		
//		Killwaves/Z dup_wave
//		SetScale/P x,DimOffset(Int3D,0),DimDelta(Int3D,0), Int3D_EDC
//		SetScale/P y,DimOffset(Int3D,1),DimDelta(Int3D,1), Int3D_EDC
//		SetScale/P z,DimOffset(Int3D,2),DimDelta(Int3D,2), Int3D_EDC
//		
//		namewave="Int3D_EDC"
//		plot_3DD(namewave)
//		CutD("bla")
//
//End


Function EDC_normalization(ctrlName)	//Shyama_1March2016
	
	String ctrlName
	Variable nlayer, y, n, z, sume
	SVAR namewave

	If(exists("Int3D")==1)
		Duplicate/O Int3D Int3D_EDC
	endif
	
		For(nlayer=0;nlayer<DimSize(Int3D,2);nlayer+=1)
			Duplicate/O/R=[0,Dimsize(Int3D,0)-1][0,Dimsize(Int3D,1)-1][nlayer] Int3D, dup_wave
			Make/O/N=(Dimsize(Int3D,0)) oneDnorm
			
			for(y=0; y<Dimsize(Int3D,0); y+=1)
				sume=0
				for(n=0; n<Dimsize(Int3D,1)-1; n+=1)
					oneDnorm[y]+=dup_wave[y][n]
					sume+=1
				endfor
				oneDnorm[y]=oneDnorm[y]/sume
			endfor
		
			for(y=0; y<Dimsize(Int3D,0); y+=1)
				for(z=0; z<Dimsize(Int3D,1); z+=1)
					dup_wave[y][z]/= oneDnorm[y]
				endfor
			endfor
			
			Duplicate/O dup_wave, EDC_norm
			Int3D_EDC[][][nlayer]=EDC_norm[p][q]
		endfor
		
		namewave="Int3D_EDC"
		plot_3DD(namewave)
		CutD("bla")

End

Function MDC_normalization(ctrlName)	//Shyama_1March2016
	
	String ctrlName
	Variable nlayer, y, n, z, sume
	SVAR namewave

	If(exists("Int3D")==1)
		Duplicate/O Int3D Int3D_MDC
	endif
	
		For(nlayer=0;nlayer<DimSize(Int3D,2);nlayer+=1)
//			Duplicate/O/R=[0,Dimsize(Int3D,0)-1][0,Dimsize(Int3D,1)-1][nlayer] Int3D, dup_wave
			Duplicate/O/R=[][][nlayer] Int3D, dup_wave
			Make/O/N=(Dimsize(Int3D,1)) oneDnorm
			
			for(y=0; y<Dimsize(Int3D,1); y+=1)
				sume=0
				for(n=0; n<Dimsize(Int3D,0)-1; n+=1)
					oneDnorm[y]+=dup_wave[n][y]
					sume+=1
				endfor
				oneDnorm[y]=oneDnorm[y]/sume
			endfor
		
			for(z=0; z<Dimsize(Int3D,1); z+=1)
				for(y=0; y<Dimsize(Int3D,0); y+=1)
					dup_wave[y][z]/= oneDnorm[z]
				endfor
			endfor
			
			Duplicate/O dup_wave, MDC_norm
			Int3D_MDC[][][nlayer]=MDC_norm[p][q]
		endfor
		
		namewave="Int3D_MDC"
		plot_3DD(namewave)
		CutD("bla")

End

Function EDM_normalization(ctrlName)	//Shyama_1March2016
	
	String ctrlName
	Variable x, y, n, sume, EDM_sum
	SVAR namewave
	Wave Int3D	
	
	If(exists("Int3D")==1)
		Duplicate/O Int3D Int3D_EDM
	endif	
	
	Make /O/N=(DimSize(Int3D,0),DimSize(Int3D,1)) EDM
	
	for (n=0;n<Dimsize(Int3D,2);n+=1)
		EDM[][] = Int3D[p][q][n]
		SetScale/P x,DimOffset(Int3D,0),DimDelta(Int3D,0), EDM
		SetScale/P y,DimOffset(Int3D,1),DimDelta(Int3D,1), EDM

		EDM_sum = 0
		sume=0
		for (y=0;y<dimsize(EDM,0);y+=1)
			for (x=0;x<dimsize(EDM,1);x+=1)
					EDM_sum+= EDM[y][x]
					sume+=1
			endfor
		endfor
		EDM_sum/=sume
		Int3D_EDM[][][n]=EDM[p][q]/EDM_sum
	endfor
	
	Killwaves/Z EDM_sum

	namewave="Int3D_EDM"
	plot_3DD(namewave)
	CutD("bla")
	
	
End



Function plot_3DD(namewave)
 	String namewave
	
	Wave w = $namewave
	NVAR sliceenergy,int_range
	Variable z = (sliceenergy-DimOffset(w,1))/DimDelta(w,1)
	Variable offset = DimOffset(w,1), delta = DimDelta(w,1), size = DimSize(w,1)
	Variable/G intrange 
	Variable x
	if(exists("ThreeDcut")==0)
		Make/N=(2,2) ThreeDcut
	endif
	if(exists("linex")==0)
		Make/N=2 linex, liney
	endif
	Duplicate/O w, TwoDwave
	Redimension/N=(-1,DimSize(w,2),0) TwoDwave; DoUpdate
	SetScale/P y, DimOffset(w,2), DimDelta(w,2), TwoDwave
	intrange = int_range/(DimDelta(w,1)*1000)
	
	Make/O/N=(DimSize(w,0),DimSize(w,2)) MDM
	MDM=0
	if (z<intrange)
		for (x=0; x <z+intrange; x+=1)
			MDM[][] += w[p][x][q]
		endfor
	elseif (z > (DimSize(w,1)-intrange))
		for (x=z-intrange; x <DimSize(w,1); x+=1)
			MDM[][] += w[p][x][q]
		endfor
	else
		for (x=z-intrange; x <z+intrange; x+=1)
			MDM[][] += w[p][x][q]
		endfor
	endif
	
	TwoDwave[][] = MDM[p][q]

//	SetDrawEnv textrgb= (0,0,65280),fstyle= 1,fsize= 14; DrawText 7,530,"Energy slice"
	
	
	if(DimDelta(w,1)<0)
		SetVariable slice,limits={offset+delta*size,offset,delta},value= sliceenergy
	else
		SetVariable slice,limits={offset,offset+delta*size,delta},value= sliceenergy
	endif
	CutD("bla")
End

Function CorrNorm_FM_3DD()

	SVAR crntdf
	SetDataFolder $crntdf

	NVAR Ef, lattice1, intensity
//	NVAR Ef, lattice, intensity
	SVAR gold_name, file_name					//
	Wave EDM									//
												//
	String Auwave0 = gold_name					//
	String wave2bcorrnorm0 = "EDM"			//
												// Some renaming to make the C&N procedure compatible with CEM
	Variable Intensity_start = intensity					//
	Variable Ef_start = Ef 							//
	Variable fit_type  = 1							// 
	Variable shift_type = 2							//

	Variable low0,high0, index,rindex

	Duplicate/O EDM wave2bcorrnorm
	Duplicate/O $Auwave0, Auwave

	Variable s											//Check if the goldcorrection for this file has already been done
	s = Exists(Auwave0 + "_fit_gslitfunction")+Exists(Auwave0 + "_intensity")+Exists(Auwave0 + "_background")
	
	if(s<3)
		Make/O/N=(DimSize(Auwave,0)) slicce
		
		slicce = Auwave[p][0]
		
//		slicce=0											// Adaptation made on 2april 2007; sums up the entire goldwave in 'k' and fits the background slope from this 'low noise EDC'
//		for(index=0; index<DimSize(slicce,0); index+=1)
//			slicce[]+= Auwave[p][index]
//		endfor

		low0=DimOffSet(Auwave,0)
		high0=DimOffSet(Auwave,0)+(DimSize(Auwave,0))*DimDelta(Auwave,0)
		SetScale/I x,low0,high0,"" slicce
		
		Make/D/N=5/O W_coef
		W_coef[4] = 0 
		
		W_coef[0] = Ef_start
		W_coef[1] = Intensity_start  							//put the initial guess to fit
		W_coef[2] = 0 									// Background starting value
		W_coef[3] = 10 									// Width starting value
		index = 0
		
		do
			FuncFit/Q FermiDirac2_3DD W_coef slicce /D
			index += 1
		while(index < 10)									// Fit the first slice 10 times, to iterate to the right starting values for the actual fit
		
		Display/K=1 slicce, fit_slicce
		DoWindow/C FermiDiracFitWindow
		ModifyGraph rgb(fit_slicce)=(0,0,65280) 				// Show the fit result in blue
		Make/D/N=(DimSize(Auwave,1))/O slitfunction, intensity_wav, background, width
		Make/O/D/N=(DimSize(Auwave,1))/O BG_slope
		
		index=0
		Variable V_FitOptions = 4
		
		do												// Loop to fit each gold EDC
			slicce = Auwave[p] [index]
			FuncFit/N=1/Q FermiDirac2_3DD W_coef slicce /D	// Adaptation made on 2april 2007; the background slope is estimated from 'summed EDC'; loop fitting abundant. This will make gold fitting faster by factor >2
			slitfunction[index] = W_coef[0]
			intensity_wav[index] = W_coef[1]
			background[index] = W_coef[2]
			width[index] = W_coef[3]
			BG_slope[index] = W_coef[4]
			index+=1
		while(index<DimSize(Auwave,1))

		String slitfunction_wave=Auwave0+"_slitfunction"	
		String fitslit = Auwave0+"_fit_gslitfunction"
		String intensity_wave = Auwave0 + "_intensity"			
		String background_wave = Auwave0 + "_background"	
		
		Duplicate/O slitfunction $slitfunction_wave
		Smooth 200, slitfunction							// SdJ, 7nov06: Increased smoothing level from 50 to 200 to get rid 
														// of noise
		
		Duplicate/O slitfunction $fitslit					
		Duplicate/O intensity_wav $intensity_wave
		
		Intensity_wave = Auwave0 + "_fit_gintensity"			//
														//
		//Smooth 50, intensity_wav								// SdJ 7 nov 06; norm with smoothed intensity profile. 14feb 07; disabled smooth; it wil lead to faulty
		Duplicate/O intensity_wav $intensity_wave				// correction
		Duplicate/O background $background_wave			
		
		Variable/G average_BGS
		
		String BGslope_wave=Auwave0+"_BG_slope"
		Duplicate/O BG_slope $BGslope_wave
			
		Wavestats/Q BG_slope						// Redo fit with BG slope constraint, 
		average_BGS=V_avg							// in order to get better instensity estimate. Note: this does not help much; smooting later on anyway
//		average_BGS=W_coef[4]
														//
		Make/O/T T_Constraints= {"K4>"+Num2str(average_BGS), "K4<"+Num2str(average_BGS)}
														//
		W_coef[0] = Ef_start							//
		W_coef[1] = Intensity_start  					// put the initial guess to fit
		W_coef[2] = 0 								// Background starting value
		W_coef[3] = 10 								// Width starting value
		W_coef[4] = average_BGS 							//	
														//
		//ModifyGraph rgb(fit_slicce)=(0,65280,0) 			//									
			
		index = 0									//
														//
		do											// Loop to fit each gold EDC
			slicce = Auwave[p] [index]					//
			FuncFit/Q/N=1 FermiDirac2_3DD W_coef slicce /D/C=T_Constraints
			slitfunction[index] = W_coef[0]				//
			intensity_wav[index] = W_coef[1]				//
			background[index] = W_coef[2]				//
			width[index] = W_coef[3]					//
			BG_slope[index] = W_coef[4]				//
			index+=1								//
		while(index<DimSize(Auwave,1))				//
														//
		intensity_wave = Auwave0 + "_intensity"			//
														//
		Duplicate/O BG_slope $BGslope_wave			//
		Duplicate/O slitfunction $slitfunction_wave			// SdJ, 7nov06: Increased smoothing level from 50 to 200 to get rid 
		Smooth 200, slitfunction						// of noise
		Duplicate/O slitfunction $fitslit					//	
		Duplicate/O intensity_wav $intensity_wave			//
			
		intensity_wave = Auwave0 + "_fit_gintensity"		//
			
		//Smooth 50, intensity_wav							//
		Duplicate/O intensity_wav $intensity_wave			// Use a smoothed version of the intensity profile to normalize.13 feb 2007; this
		Duplicate/O background $background_wave		// will result in a wrong normalization of the int profile is already smooth!
		
		DoWindow/K FermiDiracFitWindow
// ------------------ GOLD CORRECTION						// SdJ 7nov 06, swapped corr and norm; doing norm first gives 
														// clear view on the uncorrected slit. Also placed 'Gold correction'
													// inside if-loop that excludes it if gold fit is done earlier
		Make/O/N=(DimSize(Auwave,0),DimSize(Auwave,1))  norm_Auwave = Auwave[p][0]
		WaveStats/Q slitfunction
		SetScale/P x,(DimOffset(Auwave,0) - V_min),DimDelta(Auwave,0),"eV" norm_Auwave
		SetScale/P y,DimOffset(Auwave,1),DimDelta(Auwave,1),"deg" norm_Auwave

		Make/O/N=(DimSize(Auwave,0)) slice_norm, slice_corr
	
		index = 0										//
		do												//
			slice_norm=Auwave[p][index]/  intensity_wav[index]	// Normalization
			norm_Auwave[][index]= slice_norm[p]			//
			index+=1									//
		while(index<DimSize(Auwave,1))					//
	
		String gold_name1= Auwave0 + "_norm"
	
		//Duplicate/O norm_Auwave $gold_name1
		
		Duplicate/O slitfunction step_shift					//
		step_shift-=V_min								// Calculate the number of steps to shift each gold EDC
		step_shift/=Dimdelta(Auwave,0)					//
		
		Duplicate/O norm_Auwave corr_norm_Au
		
		index = 0	
		Variable step
		do										//				   0.5< <1.5 1 stepsize shift,
			step=step_shift[index]						//				   1.5< <2.5 2 stepsize shift, etc.
			step_shift[index]=step
			slice_norm=norm_Auwave[p][index]
			Duplicate/O slice_norm slice_corr
			slice_corr=slice_norm[p+(step_shift[index])]
			corr_norm_Au[][index]=slice_corr[p]
			index+=1
		while(index<DimSize(step_shift,0))
		
		gold_name1= Auwave0 + "_N&C"
		//Duplicate/O corr_norm_Au, $gold_name1
		//Matrixtranspose $gold_name1
	
	else
		String slitf = Auwave0 + "_fit_gslitfunction"			// Load waves from previous normalization
		String int = Auwave0 + "_fit_gintensity"			
		duplicate/O $int intensity1	
		duplicate/O $slitf slitfunction1
	endif

// ------------------ WAVE2BNORMALIZED NORMALIZATION			// SdJ 7nov 06, swapped corr and norm

	Make/O/N=(DimSize(wave2bcorrnorm,0),DimSize(wave2bcorrnorm,1))  wave2bnorm = wave2bcorrnorm[p][0]
	if(s==3)
		WaveStats/Q slitfunction1
	else
		WaveStats/Q slitfunction
	endif		
	SetScale/P x,(DimOffset(wave2bcorrnorm,0) - V_min),DimDelta(wave2bcorrnorm,0),"eV" wave2bnorm
	SetScale/P y,DimOffset(wave2bcorrnorm,1),DimDelta(wave2bcorrnorm,1),"deg" wave2bnorm
	
	Make/O/N=(DimSize(wave2bcorrnorm,0)) slice_norm, slice_corr
	
	index = 0										//
	do												//	
		if(s==3)										//
			slice_norm=wave2bcorrnorm[p][index]/  intensity1[index]
		else											//
			slice_norm=wave2bcorrnorm[p][index]/  intensity_wav[index]	// Normalization
		endif										//
		wave2bnorm[][index]= slice_norm[p]			//
		index+=1									//
	while(index<DimSize(wave2bcorrnorm,1))			//
	
	String wav_name= wave2bcorrnorm0 + "_norm"
	
	//Duplicate/O wave2bnorm $wav_name
	

// ------------------ WAVE2BNORMALIZED CORRECTION
		
	if(s==3)
		Duplicate/O slitfunction1 step_shift
	else
		Duplicate/O slitfunction step_shift
	endif	
													//
	step_shift-=V_min								// Calculate the number of steps to shift each gold EDC
	step_shift/=Dimdelta(wave2bcorrnorm,0)				//
		
	Duplicate/O wave2bnorm corr_norm_wav

	index = 0	
	do										//				   0.5< <1.5 1 stepsize shift,
			step=step_shift[index]						//				   1.5< <2.5 2 stepsize shift, etc.
			step_shift[index]=step
			slice_norm= wave2bnorm[p][index]
			Duplicate/O slice_norm slice_corr
			slice_corr=slice_norm[p+(step_shift[index])]
			corr_norm_wav[][index]=slice_corr[p]
			index+=1
		while(index<DimSize(step_shift,0))
		
	//wav_name= wave2bcorrnorm0 + "_N&C"
	Duplicate/O corr_norm_wav, EDM

	MatrixTranspose EDM
///Some additional normalizations.


  
	KillWaves/Z wave2bcorrnorm, slicce, fit_slicce, slitfunction, corr_Auwave, wave2bnorm, norm_wave
	KillWaves/Z intensity_wav, background, width, BG_slope		// These wave might me useful for debugging puposes: parameters of the FermiDirac fitting	
	KillWaves/Z Auwave, fit_gslitfunction, slice_corr, T_Constraints, norm_Auwave, slice_norm, step_shift, corr_norm_Au, corr_norm_wav
	KillWaves/Z W_ParamConfidenceInterval, W_sigma, W_coef, intensity1, slitfunction1
	KillVariables/Z average_BGS
	
	//Continue_addition()
	
End

Function FermiDirac2_3DD(coeff, x) : FitFunc 										// Fitting function: Fermi Dirac distribution
		Wave coeff														// coeff[0] = position, coeff[1] = intensity 
		Variable x														// coeff[2] = background, coeff[3] = width, coeff[4]- Bg slope 
		return (coeff[1]*(1+coeff[4]*(x-coeff[0])) / (1 + exp((x - coeff[0]) / (0.000865 * coeff[3] ) ) ) ) + coeff[2] 
End

Function Make_EDCD(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	Wave ThreeDcut
	Variable column = round((varNum - DimOffset(ThreeDcut,0))/DimDelta(ThreeDcut,0))
	Make/O/N=(DimSize(ThreeDcut,1)) EDCcut, EDClinex, EDCliney
	SetScale/P x, DimOffset(ThreeDcut,1), DimDelta(ThreeDcut,1), EDCcut
	EDCcut[] = ThreeDcut[column][p]
	EDClinex[] = varNum
	EDCliney[] = DimOffset(ThreeDcut,1) + DimDelta(ThreeDcut,1)*x
End

Function Make_MDCD(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	Wave ThreeDcut
	Variable row = round((varNum - DimOffset(ThreeDcut,1))/DimDelta(ThreeDcut,1))
	Make/O/N=(DimSize(ThreeDcut,0)) MDCcut, MDClinex, MDCliney
	SetScale/P x, DimOffset(ThreeDcut,0), DimDelta(ThreeDcut,0), MDCcut
	MDCcut[] = ThreeDcut[p][row]
	MDClinex[] = DimOffset(ThreeDcut,0) + DimDelta(ThreeDcut,0)*x
	MDCliney[] = varNum
End

Function interp_3dD(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	SVAR namewave, namewave2
	String wave2inter = namewave2
	NVAR num_interp
	NVAR points = num_interp

	//namewave is changed to the last chosen normalisation method. 
	namewave=namewave2
	
		//make a new_wave with the same dimensions as the original. wavetointer is a dummy
		Duplicate/O $namewave new_wave wavetointer
		//create the new 3D wave
		Variable dim, dimnew, delta, deltanew, dimoffs,tilts,m
		//This offset is the tilt angle at which the wave begins
		dimoffs=DimOffset($wave2inter,2)
		//It has dim slices
		dim=Dimsize($wave2inter,2)
		//The interpolated wave has dimnew slices
		dimnew=dim+((dim-1)*points)
		//The original wave has a scaling delta
		delta=Dimdelta($wave2inter,2)
		//and the new wave scaling delta divided by points
		deltanew=delta/(points+1)
		//make a new wave with the same k,E dimensions but new angle dimensions
		Redimension/N=(-1,-1,dimnew) new_wave
		//Set the new scaling
		SetScale/P z dimoffs,deltanew,"", new_wave
		
		//Now do the interpolation
		variable a,b, dimx, dimy, c, d
		a=0

		do
		
			new_wave [] [] [a*(points+1)]  = wavetointer [p] [q] [a] 
			b=0
	
			do
	
				dimx= Dimsize($wave2inter,0)
				dimy= Dimsize($wave2inter,1)
				Make/O/N=(dimx,dimy) inter
				c=(points-b)/(points+1)
				d=(b+1)/(points+1)
				inter [] [] = c* wavetointer [p] [q] [a] + d* wavetointer [p] [q] [a+1]
				new_wave [] [] [(a*(points+1))+b+1] = inter [p] [q]
		
				b+=1
				Killwaves inter
		
			while(b<points)
	
		a+=1

		while(a<dim)
	
		//Set the new dimension of the interpolated wave
		SetScale/P z dimoffs,deltanew,"", new_wave
		
		if(exists("Interpol3D")==1)
			KillWaves Interpol3D
		endif
	
		Duplicate/O new_wave Interpol3D

		KillWaves/Z wavetointer, new_wave
		//We change namewave to the new 3D wave for plotting purposes
		namewave = "Interpol3D"
		plot_3DD(namewave)

end

Function save_EDMD(ctrlName): ButtonControl
	String ctrlName
	String EDMname
	Prompt EDMname,"Name:"
	DoPrompt "EDM name:", EDMname
	String xname,yname
	xname=EDMname+"_x"
	yname=EDMname+"_y"
	
	NVAR Ef
	Duplicate/T/O root:EDMS:photonenergies, photonenergies
	Duplicate/O ThreeDcut root:EDMs:$EDMname
	Redimension/N=(Dimsize(photonenergies,0)+1,-1) photonenergies
	photonenergies[dimsize(photonenergies,0)-1][0] = EDMname
	photonenergies[dimsize(photonenergies,0)-1][1] =num2str(Ef)
	Duplicate/O photonenergies root:EDMS:photonenergies
end

Function save_EDCD(ctrlName): ButtonControl
	String ctrlName
	String EDMname
	
	Prompt EDMname,"Name:"
	DoPrompt "EDC/MDC name:", EDMname
	String xname,yname
	xname="root:EDMs:"+EDMname+"_EDC"
	yname="root:EDMs:"+EDMname+"_MDC"
	
	Duplicate/O EDCcut $xname
	Duplicate/O MDCcut $yname
end

Function add_tbD(ctrlName,popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR tt1,tt2,tt3,tt4,tmu,tscale
	SVAR tbswitch
	if (stringmatch(popStr,"tb off"))
		tbswitch = "tb off"
		RemoveFromGraph/Z/W=cut3D#image2 Ep 
		RemoveFromGraph/Z/W=cut3D#image2 Em
		RemoveFromGraph/Z/W=cut3D#image2 Eps
		RemoveFromGraph/Z/W=cut3D#image2 Ems
		RemoveFromGraph/Z/W=cut3D#image2 Emsa
		RemoveFromGraph/Z/W=cut3D#image2 Epf 
		RemoveFromGraph/Z/W=cut3D#image2 Emf
		RemoveFromGraph/Z/W=cut3D#image2 Epsf
		RemoveFromGraph/Z/W=cut3D#image2 Emsf
		RemoveFromGraph/Z/W=cut3D#image2 Emsaf
		
		RemoveFromGraph/Z/W=cut3D#image3 Ep2
		RemoveFromGraph/Z/W=cut3D#image3 Em2
		RemoveFromGraph/Z/W=cut3D#image3 Eps2
		RemoveFromGraph/Z/W=cut3D#image3 Ems2
		RemoveFromGraph/Z/W=cut3D#image3 Ems2a
	endif
	
	if (stringmatch(popStr,"Raghu"))
		
		tt1=-1
		tt2=1.3
		tt3=-0.85
		tt4=-0.85
		tscale = 1
		tmu=1.45
		SetVariable Setlt1,pos={13,480},size={120,15},proc=update_Ek,title=" t1:",limits={-10,10,0.01},value= tt1
		SetVariable Setlsc,pos={140,480},size={80,15},proc=update_Ek,title=" scale:",limits={-100,100,0.01},value= tscale
		SetVariable Sett2,pos={13,500},size={120,15},proc=update_Ek,title=" t2:",limits={-10,10,0.01},value= tt2
		SetVariable Sett3,pos={13,520},size={120,15},proc=update_Ek,title=" t3:",limits={-10,10,0.01},value= tt3
		SetVariable Sett4,pos={13,540},size={120,15},proc=update_Ek,title=" t4:",limits={-10,10,0.01},value= tt4
		SetVariable Setmu,pos={13,560},size={120,15},proc=update_Ek,title=" mu:",limits={-10,10,0.01},value= tmu

		tbswitch = "Raghu"
		RemoveFromGraph/Z/W=cut3D#image2 Ep 
		RemoveFromGraph/Z/W=cut3D#image2 Em
		RemoveFromGraph/Z/W=cut3D#image2 Eps
		RemoveFromGraph/Z/W=cut3D#image2 Ems
		RemoveFromGraph/Z/W=cut3D#image2 Emsa
		RemoveFromGraph/Z/W=cut3D#image2 Epf 
		RemoveFromGraph/Z/W=cut3D#image2 Emf
		RemoveFromGraph/Z/W=cut3D#image2 Epsf
		RemoveFromGraph/Z/W=cut3D#image2 Emsf
		RemoveFromGraph/Z/W=cut3D#image2 Emsaf
		
		RemoveFromGraph/Z/W=cut3D#image3 Ep2
		RemoveFromGraph/Z/W=cut3D#image3 Em2
		RemoveFromGraph/Z/W=cut3D#image3 Eps2
		RemoveFromGraph/Z/W=cut3D#image3 Ems2
		RemoveFromGraph/Z/W=cut3D#image3 Ems2a
		calc_EkD()
		calc_Ek2D()
		AppendToGraph/W=cut3D#image2 Ep 
		AppendToGraph/W=cut3D#image2 Em
		AppendToGraph/W=cut3D#image2 Eps 
		AppendToGraph/W=cut3D#image2 Ems
		AppendToGraph/W=cut3D#image3 Ep2 
		AppendToGraph/W=cut3D#image3 Em2
		AppendToGraph/W=cut3D#image3 Eps2
		AppendToGraph/W=cut3D#image3 Ems2
	endif
	
	if (stringmatch(popStr,"Zhang"))
		
		tt1= 0.58
		tt2= 0.03
		tt3= -1
		tt4= 0.035
		tscale = 3
		tmu=-0.55
		SetVariable Setlt1,pos={13,480},size={120,15},proc=update_Ek,title=" t1:",limits={-10,10,0.01},value= tt1
		SetVariable Setlsc,pos={140,480},size={80,15},proc=update_Ek,title=" scale:",limits={-100,100,0.01},value= tscale
		SetVariable Sett2,pos={13,500},size={120,15},proc=update_Ek,title=" t2:",limits={-10,10,0.01},value= tt2
		SetVariable Sett3,pos={13,520},size={120,15},proc=update_Ek,title=" t3:",limits={-10,10,0.01},value= tt3
		SetVariable Sett4,pos={13,540},size={120,15},proc=update_Ek,title=" t4:",limits={-10,10,0.01},value= tt4
		SetVariable Setmu,pos={13,560},size={120,15},proc=update_Ek,title=" mu:",limits={-10,10,0.01},value= tmu

		tbswitch = "Zhang"
		RemoveFromGraph/Z/W=cut3D#image2 Ep 
		RemoveFromGraph/Z/W=cut3D#image2 Em
		RemoveFromGraph/Z/W=cut3D#image2 Eps
		RemoveFromGraph/Z/W=cut3D#image2 Ems
		RemoveFromGraph/Z/W=cut3D#image2 Emsa
		RemoveFromGraph/Z/W=cut3D#image2 Epf 
		RemoveFromGraph/Z/W=cut3D#image2 Emf
		RemoveFromGraph/Z/W=cut3D#image2 Epsf
		RemoveFromGraph/Z/W=cut3D#image2 Emsf
		RemoveFromGraph/Z/W=cut3D#image2 Emsaf
		
		RemoveFromGraph/Z/W=cut3D#image3 Ep2
		RemoveFromGraph/Z/W=cut3D#image3 Em2
		RemoveFromGraph/Z/W=cut3D#image3 Eps2
		RemoveFromGraph/Z/W=cut3D#image3 Ems2
		RemoveFromGraph/Z/W=cut3D#image3 Ems2a
		calc_EkD()
		calc_Ek2D()
		AppendToGraph/W=cut3D#image2 Ep 
		AppendToGraph/W=cut3D#image2 Em
		AppendToGraph/W=cut3D#image2 Eps 
		AppendToGraph/W=cut3D#image2 Ems
		AppendToGraph/W=cut3D#image3 Ep2 
		AppendToGraph/W=cut3D#image3 Em2
		AppendToGraph/W=cut3D#image3 Eps2
		AppendToGraph/W=cut3D#image3 Ems2
	endif
	if (stringmatch(popStr,"Khorshunov"))
		
		tt1= 0.58
		tt2= 0.03
		tt3= -1
		tt4= 0.035
		tscale = 3
		tmu=-0.55
		SetVariable Setlt1,pos={13,480},size={120,15},proc=update_Ek,title=" t1:",limits={-10,10,0.01},value= tt1
		SetVariable Setlsc,pos={140,480},size={80,15},proc=update_Ek,title=" scale:",limits={-100,100,0.01},value= tscale
		SetVariable Sett2,pos={13,500},size={120,15},proc=update_Ek,title=" t2:",limits={-10,10,0.01},value= tt2
		SetVariable Sett3,pos={13,520},size={120,15},proc=update_Ek,title=" t3:",limits={-10,10,0.01},value= tt3
		SetVariable Sett4,pos={13,540},size={120,15},proc=update_Ek,title=" t4:",limits={-10,10,0.01},value= tt4
		SetVariable Setmu,pos={13,560},size={120,15},proc=update_Ek,title=" mu:",limits={-10,10,0.01},value= tmu

		tbswitch = "Khorshunov"
		RemoveFromGraph/Z/W=cut3D#image2 Ep 
		RemoveFromGraph/Z/W=cut3D#image2 Em
		RemoveFromGraph/Z/W=cut3D#image2 Eps
		RemoveFromGraph/Z/W=cut3D#image2 Ems
		RemoveFromGraph/Z/W=cut3D#image2 Emsa
		RemoveFromGraph/Z/W=cut3D#image2 Epf 
		RemoveFromGraph/Z/W=cut3D#image2 Emf
		RemoveFromGraph/Z/W=cut3D#image2 Epsf
		RemoveFromGraph/Z/W=cut3D#image2 Emsf
		RemoveFromGraph/Z/W=cut3D#image2 Emsaf
		
		RemoveFromGraph/Z/W=cut3D#image3 Ep2
		RemoveFromGraph/Z/W=cut3D#image3 Em2
		RemoveFromGraph/Z/W=cut3D#image3 Eps2
		RemoveFromGraph/Z/W=cut3D#image3 Ems2
		RemoveFromGraph/Z/W=cut3D#image3 Ems2a
		calc_EkD()
		calc_Ek2D()
		AppendToGraph/W=cut3D#image2 Ep 
		AppendToGraph/W=cut3D#image2 Em
		AppendToGraph/W=cut3D#image2 Eps 
		AppendToGraph/W=cut3D#image2 Ems
		AppendToGraph/W=cut3D#image3 Ep2 
		AppendToGraph/W=cut3D#image3 Em2
		AppendToGraph/W=cut3D#image3 Eps2
		AppendToGraph/W=cut3D#image3 Ems2
	endif
	
	if (stringmatch(popStr,"Parabola"))
		
		tt1= 0.58
		tt2= 0.03
		tt3= 0
		tt4= 0
		tscale = 1
		tmu= 0
		SetVariable Setlt1,pos={13,480},size={120,15},proc=update_Ek,title=" t1:",limits={-10,10,0.01},value= tt1
		SetVariable Setlsc,pos={140,480},size={80,15},proc=update_Ek,title=" scale:",limits={-100,100,0.01},value= tscale
		SetVariable Sett2,pos={13,500},size={120,15},proc=update_Ek,title=" t2:",limits={-10,10,0.01},value= tt2
		SetVariable Sett3,pos={13,520},size={120,15},proc=update_Ek,title=" t3:",limits={-10,10,0.01},value= tt3
		SetVariable Sett4,pos={13,540},size={120,15},proc=update_Ek,title=" t4:",limits={-10,10,0.01},value= tt4
		SetVariable Setmu,pos={13,560},size={120,15},proc=update_Ek,title=" mu:",limits={-10,10,0.01},value= tmu

		tbswitch = "Parabola"
		RemoveFromGraph/Z/W=cut3D#image2 Ep 
		RemoveFromGraph/Z/W=cut3D#image2 Em
		RemoveFromGraph/Z/W=cut3D#image2 Eps
		RemoveFromGraph/Z/W=cut3D#image2 Ems
		RemoveFromGraph/Z/W=cut3D#image2 Emsa
		RemoveFromGraph/Z/W=cut3D#image2 Epf 
		RemoveFromGraph/Z/W=cut3D#image2 Emf
		RemoveFromGraph/Z/W=cut3D#image2 Epsf
		RemoveFromGraph/Z/W=cut3D#image2 Emsf
		RemoveFromGraph/Z/W=cut3D#image2 Emsaf
		
		RemoveFromGraph/Z/W=cut3D#image3 Ep2
		RemoveFromGraph/Z/W=cut3D#image3 Em2
		RemoveFromGraph/Z/W=cut3D#image3 Eps2
		RemoveFromGraph/Z/W=cut3D#image3 Ems2
		RemoveFromGraph/Z/W=cut3D#image3 Ems2a
		calc_EkD()
		calc_Ek2D()
		AppendToGraph/W=cut3D#image2 Ep
		ModifyGraph lsize(Ep)=2,rgb(Ep)=(0,0,0) 
		AppendToGraph/W=cut3D#image2 Em
		ModifyGraph lsize(Em)=2,rgb(Em)=(0,0,0)
		AppendToGraph/W=cut3D#image2 Eps 
		ModifyGraph lsize(Eps)=2,rgb(Eps)=(0,0,0)
		AppendToGraph/W=cut3D#image2 Ems
		ModifyGraph lsize(Ems)=2,rgb(Ems)=(0,0,0)
		AppendToGraph/W=cut3D#image3 Ep2
		ModifyGraph lsize(Ep2)=2,rgb(Ep2)=(0,0,0) 
		AppendToGraph/W=cut3D#image3 Em2
		ModifyGraph lsize(Em2)=2,rgb(Em2)=(0,0,0)
		AppendToGraph/W=cut3D#image3 Eps2
		ModifyGraph lsize(Eps2)=2,rgb(Eps2)=(0,0,0)
		AppendToGraph/W=cut3D#image3 Ems2
		ModifyGraph lsize(Ems2)=2,rgb(Ems2)=(0,0,0)
	endif
	
	if (stringmatch(popStr,"Graser"))
		
		tt1= 0.58
		tt2= 0.03
		tt3= 13.01
		tt4= 0
		tscale = 1
		tmu= 0
		SetVariable Setlt1,pos={13,480},size={120,15},proc=update_Ek,title="V0:",limits={0,30,0.1},value= tt1
		SetVariable Setlsc,pos={140,480},size={80,15},proc=update_Ek,title=" scale:",limits={-100,100,0.01},value= tscale
		SetVariable Sett2,pos={13,500},size={120,15},proc=update_Ek,title="mu:",limits={-10,10,0.01},value= tmu
		SetVariable Sett3,pos={13,520},size={120,15},proc=update_Ek,title="c-axis",limits={0,30,0.01},value= tt3
		SetVariable Sett4,pos={13,540},size={120,15},proc=update_Ek,title="",limits={-10,10,0.01},value= tt4
		SetVariable Setmu,pos={13,560},size={120,15},proc=update_Ek,title="",limits={-30,30,0.01},value= tt2

		tbswitch = "Graser"
		RemoveFromGraph/Z/W=cut3D#image2 Ep 
		RemoveFromGraph/Z/W=cut3D#image2 Em
		RemoveFromGraph/Z/W=cut3D#image2 Eps
		RemoveFromGraph/Z/W=cut3D#image2 Ems
		RemoveFromGraph/Z/W=cut3D#image2 Emsa
		RemoveFromGraph/Z/W=cut3D#image2 Epf 
		RemoveFromGraph/Z/W=cut3D#image2 Emf
		RemoveFromGraph/Z/W=cut3D#image2 Epsf
		RemoveFromGraph/Z/W=cut3D#image2 Emsf
		RemoveFromGraph/Z/W=cut3D#image2 Emsaf
		
		RemoveFromGraph/Z/W=cut3D#image3 Ep2
		RemoveFromGraph/Z/W=cut3D#image3 Em2
		RemoveFromGraph/Z/W=cut3D#image3 Eps2
		RemoveFromGraph/Z/W=cut3D#image3 Ems2
		RemoveFromGraph/Z/W=cut3D#image3 Ems2a
		calc_EkD()
		calc_Ek2D()
		AppendToGraph/W=cut3D#image2 Ep
		ModifyGraph/W=cut3D#image2 lsize(Ep)=2,rgb(Ep)=(0,0,0) 
		AppendToGraph/W=cut3D#image2 Em
		ModifyGraph/W=cut3D#image2 lsize(Em)=2,rgb(Em)=(0,0,0)
		AppendToGraph/W=cut3D#image2 Eps 
		ModifyGraph/W=cut3D#image2 lsize(Eps)=2,rgb(Eps)=(0,0,0)
		AppendToGraph/W=cut3D#image2 Ems
		ModifyGraph/W=cut3D#image2 lsize(Ems)=2,rgb(Ems)=(0,0,0)
		AppendToGraph/W=cut3D#image2 Emsa
		ModifyGraph/W=cut3D#image2 lsize(Emsa)=2,rgb(Emsa)=(0,0,0)
		AppendToGraph/W=cut3D#image2 Epf
		ModifyGraph/W=cut3D#image2 lsize(Epf)=2,rgb(Epf)=(0,0,0) 
		AppendToGraph/W=cut3D#image2 Emf
		ModifyGraph/W=cut3D#image2 lsize(Emf)=2,rgb(Emf)=(0,0,0)
		AppendToGraph/W=cut3D#image2 Epsf 
		ModifyGraph/W=cut3D#image2 lsize(Epsf)=2,rgb(Epsf)=(0,0,0)
		AppendToGraph/W=cut3D#image2 Emsf
		ModifyGraph/W=cut3D#image2 lsize(Emsf)=2,rgb(Emsf)=(0,0,0)
		AppendToGraph/W=cut3D#image2 Emsaf
		ModifyGraph/W=cut3D#image2 lsize(Emsaf)=2,rgb(Emsaf)=(0,0,0)
		
		AppendToGraph/W=cut3D#image3 Ep2
		ModifyGraph/W=cut3D#image3 lsize(Ep2)=2,rgb(Ep2)=(0,0,0) 
		AppendToGraph/W=cut3D#image3 Em2
		ModifyGraph/W=cut3D#image3 lsize(Em2)=2,rgb(Em2)=(0,0,0)
		AppendToGraph/W=cut3D#image3 Eps2
		ModifyGraph/W=cut3D#image3 lsize(Eps2)=2,rgb(Eps2)=(0,0,0)
		AppendToGraph/W=cut3D#image3 Ems2
		ModifyGraph/W=cut3D#image3 lsize(Ems2)=2,rgb(Ems2)=(0,0,0)
		AppendToGraph/W=cut3D#image3 Ems2a
		ModifyGraph/W=cut3D#image3 lsize(Ems2a)=2,rgb(Ems2a)=(0,0,0)
		
	endif
	
end

Function update_EkD(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	calc_EkD()
	calc_Ek2D()
	
	
end

Function calc_EkD()
 	

 	variable kx,ky
 	Wave ThreeDcut
 	
 	
	NVAR tt1,tt2,tt3,tt4,tmu, tscale	
	NVAR tta1,tta2,tta3,ttb1,ttb2,ttb3,ttc1,ttc2,ttc3,ttd1,ttd2,ttd3
 	Variable t1,t2,t3,t4,mu
 	SVAR tbswitch
 	t1=tt1/tscale
 	t2=tt2/tscale
 	t3=tt3/tscale
 	t4=tt4/tscale
 	
 	
 	
 	mu=tmu/tscale
 	
 	
 	Wave Ep,Em, Eps,Ems, Emsa,Epf,Emf, Epsf,Emsf, Emsaf
 	Redimension/N=(Dimsize(ThreeDcut,0)) Ep, Em, Eps, Ems, Emsa,Epf, Emf, Epsf, Emsf, Emsaf
 	
 	Variable npoints = Dimsize(ThreeDcut,0)
 	NVAR kx_b,ky_b,kx_e,ky_e, kpar_b,k_inc
 	Variable kx_inc, ky_inc
 	kx_inc=(kx_e-kx_b)/npoints
 	ky_inc=(ky_e-ky_b)/npoints
 	
 	Variable m, kxa,kya
 	kxa=kx_b
 	kya=ky_b
 	
 	
 	for (m=0;m<=Dimsize(ThreeDcut,0); m+=1)
 	
 		if (stringmatch(tbswitch,"Graser"))
 		
 		
			Variable tx11, tx33, tx44, tx55, ty11, txx11, txx33, txx44, txx55, txy11, txy33, txy44,	txxy11, txxy44, txxy55
			Variable txyy11, txxyy11, txxyy44, txxyy55, tz44 = 0.1001, tz55, txz11, txz44, txz55, txxz11, txyz44
			NVAR Ef
 			Variable  V0 = tt1
 			Variable caxis= tt3 
 			Variable scale = tscale; 
 			Wave W_eigenvalues
 			Variable/C i 
 			Variable ksqr,kz
			Variable E1, E2, E3, E4, E5
			Variable tx13, txxyy12, tz45, tx14, txxyy45, tx15, tx35, txy12, txxy12, txz14, txy13, txxy13, txz24
			Variable txy14, txxy14, txz45, txy15, txxy34, txy45, txxy35,	txyz12, txxyz14, txyz14, txxyz24, txyz15
			Variable/C E11, E22, E33, E44, E55, E12, E21, E13, E31, E41, E14, E15, E51
			Variable/C E23, E32, E42, E24, E25, E52, E34, E43, E35, E53, E54, E45  
			VAriable ba, kx1,ky1,kz1
			
			kx1=pi*(kxa*cos(45*Pi/180)+kya*sin(45*Pi/180))/Sqrt(2)
 			ky1=pi*(-kxa*sin(45*Pi/180)+kya*cos(45*Pi/180))/Sqrt(2)
 			//print kxa,kya
 			//print kx,ky
 			mu = tmu;
 			i =cmplx(0,1);
			
			ksqr = sqrt(kx*kx+ky*ky)
			kz1=0.512*sqrt(Ef+V0-ksqr)*caxis
			
			for (ba = 1; ba<=2; ba+=1)
				if (ba == 1)
					kx = kx1
					ky=ky1
					kz=kz1
				elseif (ba==2)
					kx = kx1-pi
					ky=ky1-pi
					kz=kz-pi					
				endif
				E1 = 0.0987- mu;
				E2 = 0.0987- mu;
				E3 =-0.3595- mu;
				E4 = 0.2078- mu;
				E5 =-0.7516- mu;
				//define hopping parameters Table 1 of PRB 81, 214503
				tx11 = -0.0604;   tx33 = 0.3378;    tx44 = 0.1965;    tx55 = -0.0656;
				ty11 = -0.3005;   
				txx11 = 0.0253;   txx33 = 0.0011;   txx44=-0.0528;    txx55 = 0.0001;
				txy11 = 0.2388;   txy33 =-0.0947;   txy44= 0.1259;    
				txxy11 = -0.0414; txxy44 = -0.032;  txxy55 = 0.01;
				txyy11 = -0.0237; 
				txxyy11 = 0.0158; txxyy44 = 0.0045; txxyy55 = 0.0047;
				tz44 = 0.1001;    tz55 = 0.0563;
				txz11 = -0.0101;  txz44 = 0.0662;   txz55 = -0.0036;
				txxz11 = 0.0126;  
				txyz44 = 0.0421;

			
				//define hopping parameters: Table 2 ibid.
				tx13 =-0.4224;          txxyy12 = 0.0158;     tz45 = -0.019;
				tx14 = 0.1549;          txxyy45 = 0.0004;     
				tx15 =-0.0526;
				tx35 =-0.2845;

				txy12 = 0.1934;         txxy12 =-0.0325;      txz14 = 0.0524;
				txy13 = 0.0589;         txxy13 = 0.0005;      txz24 = 0.0566;
				txy14 =-0.007;          txxy14 =-0.0055;      txz45 =-0.0023;
				txy15 =-0.0862;         txxy34 =-0.0108;
				txy45 =-0.0475;         txxy35 = 0.0046;      

				txyz12 =-0.0168;        txxyz14 = 0.0018;
				txyz14 = 0.0349;        txxyz24 = 0.0283;
				txyz15 =-0.0203;
			
				// define diagonal elements of epsilon(k)
				E11 = 2*tx11*cos(kx) + 2*ty11*cos(ky) + 4*txy11*cos(kx)*cos(ky)
				E11+= 2*txx11*(cos(2*kx)-cos(2*ky))
    				E11+= 4*txxy11*cos(2*kx)*cos(ky) + 4*txyy11*cos(kx)*cos(2*ky)
    				E11+= 4*txxyy11*cos(2*kx)*cos(2*ky)
  				E11+= 4*txz11*(cos(kx) + cos(ky))*cos(kz)
    				E11+= 4*txxz11*(cos(2*kx)-cos(2*ky))*cos(kz)

				E22 = 2*ty11*cos(kx) + 2*tx11*cos(ky) + 4*txy11*cos(kx)*cos(ky)
    				E22 -= 2*txx11*(cos(2*kx)-cos(2*ky))
    				E22 += 4*txyy11*cos(2*kx)*cos(ky) + 4*txxy11*cos(kx)*cos(2*ky)
    				E22 += 4*txxyy11*cos(2*kx)*cos(2*ky)
    				E22 += 4*txz11*(cos(kx) + cos(ky))*cos(kz)
    				E22 -= 4*txxz11*(cos(2*kx)-cos(2*ky))*cos(kz)

				E33 = 2*tx33*(cos(kx)+cos(ky)) + 4*txy33*cos(kx)*cos(ky)
    				E33 += 2*txx33*(cos(2*kx)+cos(2*ky))

				E44 = 2*tx44*(cos(kx)+cos(ky)) + 4*txy44*cos(kx)*cos(ky)
    				E44 += 2*txx44*(cos(2*kx)+cos(2*ky))
    				E44 += 4*txxy44*(cos(2*kx)*cos(ky) + cos(kx)*cos(2*ky))
    				E44 += 4*txxyy44*cos(2*kx)*cos(2*ky)
    				E44 += 2*tz44*cos(kz) + 4*txz44*(cos(kx)+cos(ky))*cos(kz)
    				E44 += 8*txyz44*cos(kx)*cos(ky)*cos(kz)

				E55 = 2*tx55*(cos(kx)+cos(ky)) + 2*txx55*(cos(2*kx)+cos(2*ky))
    				E55 += 4*txxy55*(cos(2*kx)*cos(ky) + cos(kx)*cos(2*ky))
    				E55 += 4*txxyy55*cos(2*kx)*cos(2*ky)
    				E55 += 2*tz55*cos(kz) + 4*txz55*(cos(kx)+cos(ky))*cos(kz)
  
 
				E12 = 4*txy12*sin(kx)*sin(ky)
    				E12 += 4*txxy12*(sin(2*kx)*sin(ky) + sin(2*ky)*sin(kx))
    				E12 += 4*txxyy12*sin(2*kx)*sin(2*ky) + 8*txyz12*sin(kx)*sin(ky)*cos(kz)
				E21 = conj(E12);

				E13 = 2*i*tx13*sin(ky) + 4*i*txy13*sin(ky)*cos(kx)
    				E13  -= 4*i*txxy13*(sin(2*ky)*cos(kx) - cos(2*kx)*sin(ky))
				E31 = conj(E13);

				E23 = 2*i*tx13*sin(kx) + 4*i*txy13*sin(kx)*cos(ky)
    				E23 -= 4*i*txxy13*(sin(2*kx)*cos(ky) - cos(2*ky)*sin(kx))
				E32 = conj(E23);

				E14 = 2*i*tx14*sin(kx) + 4*i*txy14*cos(ky)*sin(kx)
    				E14 += 4*i*txxy14*sin(2*kx)*cos(ky) + 4*i*txz14*sin(kx)*cos(kz)
    				E14 -= 4*txz24*sin(kx)*sin(kz) + 8*i*txyz14*cos(ky)*sin(kx)*cos(kz)
    				E14 += 8*i*txxyz14*sin(2*kx)*cos(ky)*cos(kz) - 8*txxyz24*sin(2*kx)*cos(ky)*sin(kz)
				E41 = conj(E14);

				E24 = -2*i*tx14*sin(ky) - 4*i*txy14*cos(kx)*sin(ky)
    				E24 -= 4*i*txxy14*sin(2*ky)*cos(kx) - 4*i*txz14*sin(ky)*cos(kz)
    				E24 -= 4*txz24*sin(ky)*sin(kz) - 8*i*txyz14*cos(kx)*sin(ky)*cos(kz)
    				E24 -= 8*i*txxyz14*sin(2*ky)*cos(kx)*cos(kz) - 8*txxyz24*sin(2*ky)*cos(kx)*sin(kz);
				E42 = conj(E24);

				E15 = +2*i*tx15*sin(ky) - 4*i*txy15*sin(ky)*cos(kx)
    				E15 -= 8*i*txyz15*sin(ky)*cos(kx)*cos(kz);
				E51 = conj(E15);

				E25 = -2*i*tx15*sin(kx) + 4*i*txy15*sin(kx)*cos(ky)
    				E25+= 8*i*txyz15*sin(kx)*cos(ky)*cos(kz);
				E52 = conj(E25);

				E34 = 4*txxy34*(sin(2*ky)*sin(kx)-sin(2*kx)*sin(ky));
				E43 = conj(E34);

				E35 = 2*tx35*(cos(kx)-cos(ky)) + 4*txxy35*(cos(2*kx)*cos(ky) - cos(2*ky)*cos(kx));
				E53 = conj(E35);

				E45 = 4*txy45*sin(kx)*sin(ky) + 4*txxyy45*sin(2*kx)*sin(2*ky)
    				E45 += 2*i*tz45*sin(kz) + 4*i*txz45*(cos(kx)+cos(ky))*sin(kz);
				E54 = conj(E45);
			
				Make/O/C/N=(5,5) H 
				H[0][0] = E1+ E11; H[0][1] = E12; H[0][2] = E13; H[0][3] = E14; H[0][4] = E15;
				H[1][0] = E21; H[1][1] = E2 + E22; H[1][2] = E23; H[1][3] = E24; H[1][4] = E25;
				H[2][0] = E31; H[2][1] = E32; H[2][2] = E3+ E33; H[2][3] = E34; H[2][4] = E35;
				H[3][0] = E41; H[3][1] = E42; H[3][2] = E43; H[3][3] = E4 + E44; H[3][4] = E45;
				H[4][0] = E51; H[4][1] = E52; H[4][2] = E53; H[4][3] = E54; H[4][4] = E5 + E55;
			
				MatrixEigenV/S=1 H
				Make/O/N=5 eigenvalues
				eigenvalues[] = real(W_eigenvalues[p])
				Sort eigenvalues, eigenvalues
				if (ba==1)
 					Ep[m] = eigenvalues[0]/scale
 					Em[m] = eigenvalues[1]/scale
 					Eps[m] = eigenvalues[2]/scale
 					Ems[m] = eigenvalues[3]/scale
 					Emsa[m] = eigenvalues[4]/scale
 				elseif(ba==2)
 					Epf[m] = eigenvalues[0]/scale
 					Emf[m] = eigenvalues[1]/scale
 					Epsf[m] = eigenvalues[2]/scale
 					Emsf[m] = eigenvalues[3]/scale
 					Emsaf[m] = eigenvalues[4]/scale
 				endif	
 			endfor
 		endif
 		if (stringmatch(tbswitch,"Raghu"))
 		
 			Variable epl,emi,exy,ex,ey,epls,emis,exys,exs,eys
 			//Our BZ is rotated with respect to the one in Raghu et al
 			kx=(kxa*cos(45*Pi/180)+kya*sin(45*Pi/180))/Sqrt(2)
 			ky=(-kxa*sin(45*Pi/180)+kya*cos(45*Pi/180))/Sqrt(2)
 			
 			ex=-2*t1*cos(Pi*kx)-2*t2*cos(Pi*ky)-4*t3*cos(Pi*kx)*cos(Pi*ky)
 			ey=-2*t2*cos(Pi*kx)-2*t1*cos(Pi*ky)-4*t3*cos(Pi*kx)*cos(Pi*ky)
 	
 			epl=(ex+ey)/2
 			emi=(ex-ey)/2
 	
 			exy = -4*t4*sin(Pi*kx)*sin(Pi*ky)
 	
 			Ep[m]=epl+sqrt(emi*emi+exy*exy)-mu
 			Em[m]=epl-sqrt(emi*emi+exy*exy)-mu
	
			exs=-2*t1*cos(Pi*kx+Pi)-2*t2*cos(Pi*ky+Pi)-4*t3*cos(Pi*kx+Pi)*cos(Pi*ky+Pi)
 			eys=-2*t2*cos(Pi*kx+Pi)-2*t1*cos(Pi*ky+Pi)-4*t3*cos(Pi*kx+Pi)*cos(Pi*ky+Pi)
 	
 			epls=(exs+eys)/2
 			emis=(exs-eys)/2
 	
 			exys = -4*t4*sin(Pi*kx+Pi)*sin(Pi*ky+Pi)
 	
 			Eps[m]=epls+sqrt(emis*emis+exys*exys)-mu
 			Ems[m]=epls-sqrt(emis*emis+exys*exys)-mu
 		endif
 		
 		if (stringmatch(tbswitch,"Zhang"))
 			Variable ea,eb
 			Variable/C et,etc
 			kx=kxa
 			ky=kya
 			ea=-2*(t2*cos(Pi*kx)+t3*cos(Pi*ky))
 			eb=-2*(t3*cos(Pi*kx)+t2*cos(Pi*ky))
 	
 			exy = -2*t4*(cos(Pi*kx)+cos(Pi*ky))
 			
 			et = -t1*(1+(cos(kx*Pi)+cmplx(0,1)*sin(kx*Pi))+(cos(ky*Pi)+cmplx(0,1)*sin(ky*Pi))+(cos((kx+ky)*Pi)+cmplx(0,1)*sin((kx+ky)*Pi)))
 			
 			etc =  -t1*(1+(cos(kx*Pi)-cmplx(0,1)*sin(kx*Pi))+(cos(ky*Pi)-cmplx(0,1)*sin(ky*Pi))+(cos((kx+ky)*Pi)-cmplx(0,1)*sin((kx+ky)*Pi)))
 			
 			//the 00 combination in Zhang
 			Ep[m]=0.5*(ea+eb)+exy+sqrt(0.25*(ea-eb)*(ea-eb)+real(et*etc))-mu
 			//the 01combination in Zhang
 			Em[m]=0.5*(ea+eb)+exy-sqrt(0.25*(ea-eb)*(ea-eb)+real(et*etc))-mu
			//the 10 combination in Zhang
 			Eps[m]=0.5*(ea+eb)-exy+sqrt(0.25*(ea-eb)*(ea-eb)+real(et*etc))-mu
 			//the 11 combination in Zhang
 			Ems[m]=0.5*(ea+eb)-exy-sqrt(0.25*(ea-eb)*(ea-eb)+real(et*etc))-mu
 		
 		endif
 		
 		if (stringmatch(tbswitch,"Khorshunov"))
 			Variable ea1,eb2, ec3, ed4
 			
 			kx=kxa
 			ky=kya
 			
 			ea1 = tta1+tta2*(cos(kx*Pi)+cos(ky*Pi))+tta3*cos(kx*Pi)*cos(ky*Pi)
 			
 			eb2 = ttb1+ttb2*(cos(kx*Pi)+cos(ky*Pi))+ttb3*cos(kx*Pi)*cos(ky*Pi)
 			
 			ec3 =  ttc1+ttc2*(cos(kx*Pi)+cos(ky*Pi))+ttc3*cos(kx*Pi/2)*cos(ky*Pi/2)
 			
 			ed4 = ttd1+ttd2*(cos(kx*Pi)+cos(ky*Pi))+ttd3*cos(kx*Pi/2)*cos(ky*Pi/2)
 			
 			Ep[m]=ea1
 			//the 01combination in Zhang
 			Em[m]=eb2
			//the 10 combination in Zhang
 			Eps[m]=ec3
 			//the 11 combination in Zhang
 			Ems[m]=ed4
 		
 		endif
 		if (stringmatch(tbswitch,"Parabola"))
 			Variable p1,p2,p3,p4,ksq
 			
 			kx=kxa
 			ky=kya
 			
 			ksq=sqrt(kx*kx+ky*ky)
 			
 			
 			p1 = tta1+tta2*(ksq-tta3)^2
 			
 			p2 = ttb1+ttb2*(ksq-ttb3)^2
 			
 			p3 =  ttc1+ttc2*(ksq-ttc3)^2
 			
 			p4 = ttd1+ttd2*(ksq-ttd3)^2
 			
 			Ep[m]=p1
 			Em[m]=p2
			Eps[m]=p3
 			Ems[m]=p4
 		
 		endif
 		kxa=kxa+kx_inc
 		kya=kya+ky_inc
	endfor
	
	Setscale/P x,kpar_b,k_inc,Ep
	Setscale/P x,kpar_b,k_inc,Em
	Setscale/P x,kpar_b,k_inc,Eps
	Setscale/P x,kpar_b,k_inc,Ems
	Setscale/P x,kpar_b,k_inc,Emsa
	Setscale/P x,kpar_b,k_inc,Epf
	Setscale/P x,kpar_b,k_inc,Emf
	Setscale/P x,kpar_b,k_inc,Epsf
	Setscale/P x,kpar_b,k_inc,Emsf
	Setscale/P x,kpar_b,k_inc,Emsaf
	
end

Function calc_Ek2D()
 	
 	variable kx,ky
 	Wave ThreeDcut2
 	
 	NVAR tta1,tta2,tta3,ttb1,ttb2,ttb3,ttc1,ttc2,ttc3,ttd1,ttd2,ttd3
	NVAR tt1,tt2,tt3,tt4,tmu, tscale	
 	Variable t1,t2,t3,t4,mu
 	SVAR tbswitch
 	t1=tt1/tscale
 	t2=tt2/tscale
 	t3=tt3/tscale
 	t4=tt4/tscale
 	mu=tmu/tscale
 	
 	
 	Wave Ep2, Em2, Eps2, Ems2, Ems2a
 	Redimension/N=(Dimsize(ThreeDcut2,0)) Ep2,Em2,Eps2,Ems2,Ems2a 
 	
 	Variable npoints = Dimsize(ThreeDcut2,0)
 	NVAR kx_b2,ky_b2,kx_e2,ky_e2, kpar_b2,k_inc2
 	Variable kx_inc, ky_inc
 	kx_inc=(kx_e2-kx_b2)/npoints
 	ky_inc=(ky_e2-ky_b2)/npoints
 	
 	Variable m, kxa,kya
 	kxa=kx_b2
 	kya=ky_b2
 	
 	
 	for (m=0;m<=Dimsize(ThreeDcut2,0); m+=1)
 	
 		if (stringmatch(tbswitch,"Graser"))
 			kx=pi*(kxa*cos(45*Pi/180)+kya*sin(45*Pi/180))/Sqrt(2)
 			ky=pi*(-kxa*sin(45*Pi/180)+kya*cos(45*Pi/180))/Sqrt(2)
 			
 			NVAR Ef
 			Variable  V0 = tt1 
 			Variable scale = tscale; 
 			Variable caxis
 			mu = tmu;
 			Wave W_eigenvalues
 			Variable/C i 
 			i =cmplx(0,1);
			
			Variable ksqr,kz
			ksqr = sqrt(kx*kx+ky*ky)
			kz=0.512*sqrt(Ef+V0-ksqr)*caxis 
			Variable E1, E2, E3, E4, E5
			
			E1 = 0.0987- mu;
			E2 = 0.0987- mu;
			E3 =-0.3595- mu;
			E4 = 0.2078- mu;
			E5 =-0.7516- mu;
			
			Variable tx11, tx33, tx44, tx55, ty11, txx11, txx33, txx44, txx55, txy11, txy33, txy44,	txxy11, txxy44, txxy55
			Variable txyy11, txxyy11, txxyy44, txxyy55, tz44 = 0.1001, tz55, txz11, txz44, txz55, txxz11, txyz44
			//define hopping parameters Table 1 of PRB 81, 214503
			tx11 = -0.0604;   tx33 = 0.3378;    tx44 = 0.1965;    tx55 = -0.0656;
			ty11 = -0.3005;   
			txx11 = 0.0253;   txx33 = 0.0011;   txx44=-0.0528;    txx55 = 0.0001;
			txy11 = 0.2388;   txy33 =-0.0947;   txy44= 0.1259;    
			txxy11 = -0.0414; txxy44 = -0.032;  txxy55 = 0.01;
			txyy11 = -0.0237; 
			txxyy11 = 0.0158; txxyy44 = 0.0045; txxyy55 = 0.0047;
			tz44 = 0.1001;    tz55 = 0.0563;
			txz11 = -0.0101;  txz44 = 0.0662;   txz55 = -0.0036;
			txxz11 = 0.0126;  
			txyz44 = 0.0421;

			Variable tx13, txxyy12, tz45, tx14, txxyy45, tx15, tx35, txy12, txxy12, txz14, txy13, txxy13, txz24
			Variable txy14, txxy14, txz45, txy15, txxy34, txy45, txxy35,	txyz12, txxyz14, txyz14, txxyz24, txyz15

			//define hopping parameters: Table 2 ibid.
			tx13 =-0.4224;          txxyy12 = 0.0158;     tz45 = -0.019;
			tx14 = 0.1549;          txxyy45 = 0.0004;     
			tx15 =-0.0526;
			tx35 =-0.2845;

			txy12 = 0.1934;         txxy12 =-0.0325;      txz14 = 0.0524;
			txy13 = 0.0589;         txxy13 = 0.0005;      txz24 = 0.0566;
			txy14 =-0.007;          txxy14 =-0.0055;      txz45 =-0.0023;
			txy15 =-0.0862;         txxy34 =-0.0108;
			txy45 =-0.0475;         txxy35 = 0.0046;      

			txyz12 =-0.0168;        txxyz14 = 0.0018;
			txyz14 = 0.0349;        txxyz24 = 0.0283;
			txyz15 =-0.0203;
			
			Variable/C E11, E22, E33, E44, E55, E12, E21, E13, E31, E41, E14, E15, E51
			Variable/C E23, E32, E42, E24, E25, E52, E34, E43, E35, E53, E54, E45  
			// define diagonal elements of epsilon(k)
			E11 = 2*tx11*cos(kx) + 2*ty11*cos(ky) + 4*txy11*cos(kx)*cos(ky)
			E11+= 2*txx11*(cos(2*kx)-cos(2*ky))
    			E11+= 4*txxy11*cos(2*kx)*cos(ky) + 4*txyy11*cos(kx)*cos(2*ky)
    			E11+= 4*txxyy11*cos(2*kx)*cos(2*ky)
  			E11+= 4*txz11*(cos(kx) + cos(ky))*cos(kz)
    			E11+= 4*txxz11*(cos(2*kx)-cos(2*ky))*cos(kz)

			E22 = 2*ty11*cos(kx) + 2*tx11*cos(ky) + 4*txy11*cos(kx)*cos(ky)
    			E22 -= 2*txx11*(cos(2*kx)-cos(2*ky))
    			E22 += 4*txyy11*cos(2*kx)*cos(ky) + 4*txxy11*cos(kx)*cos(2*ky)
    			E22 += 4*txxyy11*cos(2*kx)*cos(2*ky)
    			E22 += 4*txz11*(cos(kx) + cos(ky))*cos(kz)
    			E22 -= 4*txxz11*(cos(2*kx)-cos(2*ky))*cos(kz)

			E33 = 2*tx33*(cos(kx)+cos(ky)) + 4*txy33*cos(kx)*cos(ky)
    			E33 += 2*txx33*(cos(2*kx)+cos(2*ky))

			E44 = 2*tx44*(cos(kx)+cos(ky)) + 4*txy44*cos(kx)*cos(ky)
    			E44 += 2*txx44*(cos(2*kx)+cos(2*ky))
    			E44 += 4*txxy44*(cos(2*kx)*cos(ky) + cos(kx)*cos(2*ky))
    			E44 += 4*txxyy44*cos(2*kx)*cos(2*ky)
    			E44 += 2*tz44*cos(kz) + 4*txz44*(cos(kx)+cos(ky))*cos(kz)
    			E44 += 8*txyz44*cos(kx)*cos(ky)*cos(kz)

			E55 = 2*tx55*(cos(kx)+cos(ky)) + 2*txx55*(cos(2*kx)+cos(2*ky))
    			E55 += 4*txxy55*(cos(2*kx)*cos(ky) + cos(kx)*cos(2*ky))
    			E55 += 4*txxyy55*cos(2*kx)*cos(2*ky)
    			E55 += 2*tz55*cos(kz) + 4*txz55*(cos(kx)+cos(ky))*cos(kz)
  
 
			E12 = 4*txy12*sin(kx)*sin(ky)
    			E12 += 4*txxy12*(sin(2*kx)*sin(ky) + sin(2*ky)*sin(kx))
    			E12 += 4*txxyy12*sin(2*kx)*sin(2*ky) + 8*txyz12*sin(kx)*sin(ky)*cos(kz)
			E21 = conj(E12);

			E13 = 2*i*tx13*sin(ky) + 4*i*txy13*sin(ky)*cos(kx)
    			E13  -= 4*i*txxy13*(sin(2*ky)*cos(kx) - cos(2*kx)*sin(ky))
			E31 = conj(E13);

			E23 = 2*i*tx13*sin(kx) + 4*i*txy13*sin(kx)*cos(ky)
    			E23 -= 4*i*txxy13*(sin(2*kx)*cos(ky) - cos(2*ky)*sin(kx))
			E32 = conj(E23);

			E14 = 2*i*tx14*sin(kx) + 4*i*txy14*cos(ky)*sin(kx)
    			E14 += 4*i*txxy14*sin(2*kx)*cos(ky) + 4*i*txz14*sin(kx)*cos(kz)
    			E14 -= 4*txz24*sin(kx)*sin(kz) + 8*i*txyz14*cos(ky)*sin(kx)*cos(kz)
    			E14 += 8*i*txxyz14*sin(2*kx)*cos(ky)*cos(kz) - 8*txxyz24*sin(2*kx)*cos(ky)*sin(kz)
			E41 = conj(E14);

			E24 = -2*i*tx14*sin(ky) - 4*i*txy14*cos(kx)*sin(ky)
    			E24 -= 4*i*txxy14*sin(2*ky)*cos(kx) - 4*i*txz14*sin(ky)*cos(kz)
    			E24 -= 4*txz24*sin(ky)*sin(kz) - 8*i*txyz14*cos(kx)*sin(ky)*cos(kz)
    			E24 -= 8*i*txxyz14*sin(2*ky)*cos(kx)*cos(kz) - 8*txxyz24*sin(2*ky)*cos(kx)*sin(kz);
			E42 = conj(E24);

			E15 = +2*i*tx15*sin(ky) - 4*i*txy15*sin(ky)*cos(kx)
    			E15 -= 8*i*txyz15*sin(ky)*cos(kx)*cos(kz);
			E51 = conj(E15);

			E25 = -2*i*tx15*sin(kx) + 4*i*txy15*sin(kx)*cos(ky)
    			E25+= 8*i*txyz15*sin(kx)*cos(ky)*cos(kz);
			E52 = conj(E25);

			E34 = 4*txxy34*(sin(2*ky)*sin(kx)-sin(2*kx)*sin(ky));
			E43 = conj(E34);

			E35 = 2*tx35*(cos(kx)-cos(ky)) + 4*txxy35*(cos(2*kx)*cos(ky) - cos(2*ky)*cos(kx));
			E53 = conj(E35);

			E45 = 4*txy45*sin(kx)*sin(ky) + 4*txxyy45*sin(2*kx)*sin(2*ky)
    			E45 += 2*i*tz45*sin(kz) + 4*i*txz45*(cos(kx)+cos(ky))*sin(kz);
			E54 = conj(E45);
			
			Make/O/C/N=(5,5) H 
			H[0][0] = E1+ E11; H[0][1] = E12; H[0][2] = E13; H[0][3] = E14; H[0][4] = E15;
			H[1][0] = E21; H[1][1] = E2 + E22; H[1][2] = E23; H[1][3] = E24; H[1][4] = E25;
			H[2][0] = E31; H[2][1] = E32; H[2][2] = E3+ E33; H[2][3] = E34; H[2][4] = E35;
			H[3][0] = E41; H[3][1] = E42; H[3][2] = E43; H[3][3] = E4 + E44; H[3][4] = E45;
			H[4][0] = E51; H[4][1] = E52; H[4][2] = E53; H[4][3] = E54; H[4][4] = E5 + E55;
			
			MatrixEigenV/S=1 H
			Make/O/N=5 eigenvalues
			eigenvalues[] = real(W_eigenvalues[p])
			Sort eigenvalues, eigenvalues
			
 			Ep2[m] = eigenvalues[0]/scale
 			Em2[m] = eigenvalues[1]/scale
 			Eps2[m] = eigenvalues[2]/scale
 			Ems2[m] = eigenvalues[3]/scale
 			Ems2a[m] = eigenvalues[4]/scale
 			
 			
 		endif
 		
 		if (stringmatch(tbswitch,"Raghu"))
 		
 			Variable epl,emi,exy,ex,ey,epls,emis,exys,exs,eys
 			//Our BZ is rotated with respect to the one in Raghu et al
 			kx=(kxa*cos(45*Pi/180)+kya*sin(45*Pi/180))/Sqrt(2)
 			ky=(-kxa*sin(45*Pi/180)+kya*cos(45*Pi/180))/Sqrt(2)
 			
 			ex=-2*t1*cos(Pi*kx)-2*t2*cos(Pi*ky)-4*t3*cos(Pi*kx)*cos(Pi*ky)
 			ey=-2*t2*cos(Pi*kx)-2*t1*cos(Pi*ky)-4*t3*cos(Pi*kx)*cos(Pi*ky)
 	
 			epl=(ex+ey)/2
 			emi=(ex-ey)/2
 	
 			exy = -4*t4*sin(Pi*kx)*sin(Pi*ky)
 	
 			Ep2[m]=epl+sqrt(emi*emi+exy*exy)-mu
 			Em2[m]=epl-sqrt(emi*emi+exy*exy)-mu
	
			exs=-2*t1*cos(Pi*kx+Pi)-2*t2*cos(Pi*ky+Pi)-4*t3*cos(Pi*kx+Pi)*cos(Pi*ky+Pi)
 			eys=-2*t2*cos(Pi*kx+Pi)-2*t1*cos(Pi*ky+Pi)-4*t3*cos(Pi*kx+Pi)*cos(Pi*ky+Pi)
 	
 			epls=(exs+eys)/2
 			emis=(exs-eys)/2
 	
 			exys = -4*t4*sin(Pi*kx+Pi)*sin(Pi*ky+Pi)
 	
 			Eps2[m]=epls+sqrt(emis*emis+exys*exys)-mu
 			Ems2[m]=epls-sqrt(emis*emis+exys*exys)-mu
 		endif
 		
 		if (stringmatch(tbswitch,"Zhang"))
 			Variable ea,eb
 			Variable/C et,etc
 			kx=kxa
 			ky=kya
 			ea=-2*(t2*cos(Pi*kx)+t3*cos(Pi*ky))
 			eb=-2*(t3*cos(Pi*kx)+t2*cos(Pi*ky))
 	
 			exy = -2*t4*(cos(Pi*kx)+cos(Pi*ky))
 			
 			et = -t1*(1+(cos(kx*Pi)+cmplx(0,1)*sin(kx*Pi))+(cos(ky*Pi)+cmplx(0,1)*sin(ky*Pi))+(cos((kx+ky)*Pi)+cmplx(0,1)*sin((kx+ky)*Pi)))
 			
 			etc =  -t1*(1+(cos(kx*Pi)-cmplx(0,1)*sin(kx*Pi))+(cos(ky*Pi)-cmplx(0,1)*sin(ky*Pi))+(cos((kx+ky)*Pi)-cmplx(0,1)*sin((kx+ky)*Pi)))
 			
 			//the 00 combination in Zhang
 			Ep2[m]=0.5*(ea+eb)+exy+sqrt(0.25*(ea-eb)*(ea-eb)+real(et*etc))-mu
 			//the 01combination in Zhang
 			Em2[m]=0.5*(ea+eb)+exy-sqrt(0.25*(ea-eb)*(ea-eb)+real(et*etc))-mu
			//the 10 combination in Zhang
 			Eps2[m]=0.5*(ea+eb)-exy+sqrt(0.25*(ea-eb)*(ea-eb)+real(et*etc))-mu
 			//the 11 combination in Zhang
 			Ems2[m]=0.5*(ea+eb)-exy-sqrt(0.25*(ea-eb)*(ea-eb)+real(et*etc))-mu
 		
 		endif
 		if (stringmatch(tbswitch,"Khorshunov"))
 			Variable ea1,eb2, ec3, ed4
 			
 			kx=kxa
 			ky=kya
 			
 			ea1 = tta1+tta2*(cos(kx*Pi)+cos(ky*Pi))+tta3*cos(kx*Pi)*cos(ky*Pi)
 			
 			eb2 = ttb1+ttb2*(cos(kx*Pi)+cos(ky*Pi))+ttb3*cos(kx*Pi)*cos(ky*Pi)
 			
 			ec3 =  ttc1+ttc2*(cos(kx*Pi)+cos(ky*Pi))+ttc3*cos(kx*Pi/2)*cos(ky*Pi/2)
 			
 			ed4 = ttd1+ttd2*(cos(kx*Pi)+cos(ky*Pi))+ttd3*cos(kx*Pi/2)*cos(ky*Pi/2)
 			
 			Ep2[m]=ea1
 			//the 01combination in Zhang
 			Em2[m]=eb2
			//the 10 combination in Zhang
 			Eps2[m]=ec3
 			//the 11 combination in Zhang
 			Ems2[m]=ed4
 		
 		endif
 		kxa=kxa+kx_inc
 		kya=kya+ky_inc
	endfor
	
	Setscale/P x,kpar_b2,k_inc2,Ep2
	Setscale/P x,kpar_b2,k_inc2,Em2
	Setscale/P x,kpar_b2,k_inc2,Eps2
	Setscale/P x,kpar_b2,k_inc2,Ems2
	
end

Function Add_Norm_1cubes_sucksD()
	Wave dup_wave1
	Variable start, stop, x, y, z
	
	
	Wave Int3D_1c
	if(Dimsize(dup_wave1,2)>1)
		Make/O/N=(Dimsize(dup_wave1,1), Dimsize(dup_wave1,0), Dimsize(dup_wave1,2)) Norm_3D
		Setscale/P x,Dimoffset(dup_wave1,1), Dimdelta(dup_wave1,1), Norm_3D
		Setscale/P y,Dimoffset(dup_wave1,0), Dimdelta(dup_wave1,0), Norm_3D
		Setscale/P z,Dimoffset(dup_wave1,2), Dimdelta(dup_wave1,2), Norm_3D
	endif
	
for(z=0; z<Dimsize(dup_wave1,2)+1; z+=1)
	
	if(Dimsize(dup_wave1,2)>1)
		Make/O/N=(Dimsize(dup_wave1,0), Dimsize(dup_wave1,1)) dup_wave
		Setscale/P x,Dimoffset(dup_wave1,0), Dimdelta(dup_wave1,0), dup_wave
		Setscale/P y,Dimoffset(dup_wave1,1), Dimdelta(dup_wave1,1), dup_wave
		dup_wave[][]= dup_wave1[p][q][z]
		//Matrixtranspose dup_wave
	else 
		Duplicate/O dup_wave1, dup_wave
	endif


		Stop= Dimsize(dup_wave, 1)
		Start=0
	
	Make/O/N=(Dimsize(dup_wave,0)) OneD
	OneD=0
	for(x= start; x<stop; x+=1)
		OneD[]+=dup_wave[p][x]
	endfor
	
	for(x= 0; x<Dimsize(dup_wave,0); x+=1)
		for(y= 0; y<Dimsize(dup_wave,1); y+=1)
			dup_wave[x][y]/=OneD[x]
		endfor
	endfor
	
	Stop= Dimsize(dup_wave, 1)
//	Start= round((-1*Dimoffset(dup_wave, 1)+0.045)/Dimdelta(dup_wave,1))
	Start= Dimsize(dup_wave, 1)-25
	
	OneD=0
	
	for(x= start; x<stop; x+=1)
		OneD[]+=dup_wave[p][x]
	endfor
	
	Smooth 50, OneD
	
	for(x= 0; x<Dimsize(dup_wave,0); x+=1)
		for(y= 0; y<Dimsize(dup_wave,1); y+=1)
			dup_wave[x][y]/=OneD[x]
		endfor
	endfor
	
	if(Dimsize(dup_wave1,2)>1)
		Int3D_1c [][][z]=dup_wave[p][q] 
	endif
	
	
endfor
	
	
	Killwaves/Z dup_wave1, dup_wave, OneD
//	repeat_add_norm()
end

Function repeat_add_normD()
	SVAR name
	String hor_twoDwave0
	Variable number = CountObjects("", 1 )-1
	Variable W
	Variable start, stop, x, y, z
	
	for(W=1; W<number; W+=1)
		hor_twoDwave0= GetIndexedObjName("", 1, W)
		name = hor_twoDwave0
		Duplicate/O $hor_twoDwave0 dup_wave1
	
		if(Dimsize(dup_wave1,2)>1)
			Make/O/N=(Dimsize(dup_wave1,1), Dimsize(dup_wave1,0), Dimsize(dup_wave1,2)) Norm_3D
			Setscale/P x,Dimoffset(dup_wave1,1), Dimdelta(dup_wave1,1), Norm_3D
			Setscale/P y,Dimoffset(dup_wave1,0), Dimdelta(dup_wave1,0), Norm_3D
			Setscale/P z,Dimoffset(dup_wave1,2), Dimdelta(dup_wave1,2), Norm_3D
		endif
	
		for(z=0; z<Dimsize(dup_wave1,2)+1; z+=1)
	
			if(Dimsize(dup_wave1,2)>1)
				Make/O/N=(Dimsize(dup_wave1,0), Dimsize(dup_wave1,1)) dup_wave
				Setscale/P x,Dimoffset(dup_wave1,0), Dimdelta(dup_wave1,0), dup_wave
				Setscale/P y,Dimoffset(dup_wave1,1), Dimdelta(dup_wave1,1), dup_wave
				dup_wave[][]= dup_wave1[p][q][z]
				Matrixtranspose dup_wave
			else 
				Duplicate/O dup_wave1, dup_wave
			endif


			Stop= Dimsize(dup_wave, 1)
			Start=0
	
			Make/O/N=(Dimsize(dup_wave,0)) OneD
			OneD=0
			for(x= start; x<stop; x+=1)
				OneD[]+=dup_wave[p][x]
			endfor
	
			for(x= 0; x<Dimsize(dup_wave,0); x+=1)
				for(y= 0; y<Dimsize(dup_wave,1); y+=1)
					dup_wave[x][y]/=OneD[x]
				endfor
			endfor
	
			Stop= Dimsize(dup_wave, 1)
			Start= Dimsize(dup_wave, 1)-25
	
			OneD=0
	
			for(x= start; x<stop; x+=1)
				OneD[]+=dup_wave[p][x]
			endfor
	
			Smooth 50, OneD
	
			for(x= 0; x<Dimsize(dup_wave,0); x+=1)
				for(y= 0; y<Dimsize(dup_wave,1); y+=1)
					dup_wave[x][y]/=OneD[x]
				endfor
			endfor
	
			if(Dimsize(dup_wave1,2)>1)
				Norm_3D [][][z]=dup_wave[p][q] 
			endif
	
	
		endfor
		name+="_AN"
		Duplicate dup_wave $name
		Killwaves/Z dup_wave1, dup_wave, OneD
	
	endfor

end


Function FS_AutocorrelationD()
		Wave TwoDwave, ThreeDcut2
		NVAR sliceenergy, AC_min
		Variable n,m
		String autocorrname = "AC_E_"+ num2str(round(sliceenergy*1000))
		Duplicate/O TwoDwave, temp_wav
		For (n=0;n<Dimsize(temp_wav,0);n+=1)
			For (m=0;m<Dimsize(temp_wav,1);m+=1)
				if (TwoDwave[n][m] <= AC_min)
					temp_wav[n][m] = 0
				else
					temp_wav[n][m] = 1
				endif
			endfor
		endfor
		TwoDwave[][]=temp_wav[p][q]	
		MatrixOp/O $autocorrname = correlate(TwoDwave,TwoDwave,4)
		SetScale/P x, DimOffset(TwoDwave,0), DimDelta(TwoDwave,0), $autocorrname
		SetScale/P y, DimOffset(TwoDwave,1), DimDelta(TwoDwave,1), $autocorrname
		Duplicate/O $autocorrname, ThreeDcut2
		SetAxis /W=Cut3D#image3 bottom, Dimoffset(ThreeDcut2,0),DimOffset(ThreeDcut2,0)+(DimSize(ThreeDcut2,0)-1)*DimDelta(ThreeDcut2,0)
		SetAxis /W=cut3D#image3 left, Dimoffset(ThreeDcut2,1),DimOffset(ThreeDcut2,1)+(DimSize(ThreeDcut2,1)-1)*DimDelta(ThreeDcut2,1)
End


//Function Make_AC_FS_MovieD(ctrlName): ButtonControl				//Commentized by Shyama on 2March2016 because of memory issue while loading IO5-Diamond data
//	String ctrlName
//	
//	SVAR namewave
//	Wave w = $namewave
//	NVAR sliceenergy,int_range, AC_min
//	Variable offset = DimOffset(w,1), delta = DimDelta(w,1), size = DimSize(w,1)
//	Variable intrange2 
//	Variable x,i,n,m
//	Variable/G width,height
//	String tbname
//	
//	NewMovie/F=10/I/L/O
//	Make/O/N=(Dimsize($namewave,0),Dimsize($namewave,2)) Ecut
//	DoWindow/K Movie
//	width = Dimdelta(w,0)*Dimsize(w,0)
//	height = Dimdelta(w,2)*Dimsize(w,2)
//	Display/N=Movie/K=1/W=(100,100,120*width,60*height)
//	Display/K=1/Host=Movie/N=im1/W=(0,0,0.5,1)
//	Display/K=1/Host=Movie/N=im2/W=(0.5,0,1,1)
//	Duplicate/O ThreeDcut, AC
//	AppendImage/W=Movie#im1 Ecut
//	AppendImage/W=Movie#im2 AC
//	ModifyImage AC ctab= {*,*,Bluehot,1}
//	TextBox/W=Movie/C/N=text0/X=30.00/Y=-5.00 ""
//	
//	for(i=0;i<113;i+=1)
//		if (Dimoffset(w,1)+i*Dimdelta(w,1)<=-0.000283)
//			Duplicate/O w, Ecut
//			Redimension/N=(-1,DimSize(w,2),0) Ecut; DoUpdate
//			SetScale/P y, DimOffset(w,2), DimDelta(w,2), Ecut
//			intrange2 = int_range/(DimDelta(w,1)*1000)
//	
//			Make/O/N=(DimSize(w,0),DimSize(w,2)) MDM
//			MDM=0
//			if (i<intrange2)
//				for (x=0; x <i+intrange2; x+=1)
//					MDM[][] += w[p][x][q]
//				endfor
//			elseif (i > (DimSize(w,1)-intrange2))
//				for (x=i-intrange2; x <DimSize(w,1); x+=1)
//					MDM[][] += w[p][x][q]
//				endfor
//			else
//				for (x=i-intrange2; x <i+intrange2; x+=1)
//					MDM[][] += w[p][x][q]
//				endfor
//			endif
//	
//			Ecut[][] = MDM[p][q]
//		
//			Duplicate/O Ecut, temp_wav
//			For (n=0;n<Dimsize(temp_wav,0);n+=1)
//				For (m=0;m<Dimsize(temp_wav,1);m+=1)
//					if (Ecut[n][m] <= AC_min)
//						temp_wav[n][m] = 0
//					else
//						temp_wav[n][m] = Ecut[n][m]
//					endif
//				endfor
//			endfor
//			Ecut[][]=temp_wav[p][q]	
//			//MatrixOp/O AC = correlate(Ecut,Ecut,4)					//keep it Commentized to run this function - Shyama 2March2016
//			//AC[][] = Ecut[p][q]
//			//SetScale/P x, DimOffset(w,0), DimDelta(w,0), AC
//			//SetScale/P y, DimOffset(w,2), DimDelta(w,2), AC		//until here
//			tbname= "Energy = " + num2str(Dimoffset(w,1)+i*Dimdelta(w,1))+" (meV)"
//			TextBox/C/N=text0 tbname
//			DoUpdate/W=Movie
//			AddMovieFrame
//		endif
//	endfor
//	CloseMovie
//end

Function Make_FS_Movie2D(ctrlName): ButtonControl
	String ctrlName
	
	SVAR namewave
	Wave w = $namewave
	NVAR sliceenergy,int_range, AC_min
	Variable offset = DimOffset(w,1), delta = DimDelta(w,1), size = DimSize(w,1)
	Variable intrange2 
	Variable i,n,m,ang
	Variable/G width,height
	String tbname
	
	DoWindow/K Movie0
	Display/N=Movie0/K=1/W=(100,100,1100,600)
	Display/K=1/Host=Movie0/N=im1/W=(0,0,500,1000)
	Display/K=1/Host=Movie0/N=im2/W=(550,0,1000,1000)
	NewMovie/F=10/I/L/O
	Make/O/N=(Dimsize($namewave,0),Dimsize($namewave,2)) Ecut
	

	
	Duplicate/O ThreeDcut, AC
	Setscale/P x,-Dimoffset(ThreeDcut,0),-DimDelta(ThreeDcut,0),"", AC
	Make/O/N=(1,1) k_wave_y, k_wave_x, plot_wave
	Make/O/N=(DimSize(AC,0)) Elinex, Eliney
	
	
	//TextBox/W=Movie#im1/C/N=text0/X=30.00/Y=-5.00 ""
	Wave TwoDwave
	Variable tstart, tdelta, tend, tilt_s, tilt_e, tilt
	Variable K1, K2, K3
	Variable pol,k //dummy vars 
	NVAR Ef, lattice1, lattice2, s_tilt, s_azi, s_polar, pol_0, tilt_0, slit
//	NVAR Ef, lattice, s_tilt, s_azi, s_polar, pol_0, slit
	Wave TwoDwave
	
for(i=0;i<45;i+=1)
	sliceenergy=Dimoffset(w,1)+i*Dimdelta(w,1)
	
	setenergyD("bla",1,"bla","bla")
		
	
	Elinex[] = DimOffset(AC,0) + DimDelta(AC,0)*x
	Eliney[] =  sliceenergy
	
	Make/O/N=(DimSize(TwoDwave,0)*DimSize(TwoDwave,1)) k_wave_x, k_wave_y,plot_wave
	
	
	tstart=Dimoffset(TwoDwave,0)
	tend=Dimoffset(TwoDwave,0)+ DimDelta(TwoDwave,0)*Dimsize(TwoDwave,0)
	tdelta=DimDelta(TwoDwave,0)
	tilt_s=Dimoffset(TwoDwave,1)
	tilt_e = Dimoffset(TwoDwave,1)+ DimDelta(TwoDwave,1)*Dimsize(TwoDwave,1)
	Duplicate/O TwoDwave, temp_wav
	if (Dimdelta(TwoDwave,1)<0)
		For (k=0;k<Dimsize(temp_wav,1);k+=1)
			TwoDwave[][k]=temp_wav[p][Dimsize(temp_wav,1)-k-1]
		endfor
		Setscale/P y,tilt_e,-Dimdelta(temp_wav,1),"" TwoDwave
		tilt_s=Dimoffset(TwoDwave,1)
		tilt_e = Dimoffset(TwoDwave,1)+ DimDelta(TwoDwave,1)*Dimsize(TwoDwave,1)
	endif
		
	
	if (slit ==0)
		//Polar and phi
		K1=s_polar
		K2=s_azi
	
		n=0
		m=0
		for (tilt=tilt_s; tilt <= tilt_e;tilt+=Dimdelta(TwoDwave,1))
			K3=tilt-s_tilt
	 		// horizontal slit
				k=0
				for (pol = tstart-K1; pol <= tend-K1; pol += tdelta) 
					k_wave_x[n]=0.512*sqrt(Ef)*lattice1/pi *(sin((pol)*pi/180)*cos((K2)*pi/180)*cos((K3)*pi/180)-sin((K2)*pi/180)*sin((K3)*pi/180))
					k_wave_y[n]=0.512*sqrt(Ef)*lattice2/pi *(sin((pol)*pi/180)*sin((K2)*pi/180)*cos((K3)*pi/180)+cos((K2)*pi/180)*sin((K3)*pi/180))
//					k_wave_x[n]=0.512*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*cos((K2)*pi/180)*cos((K3)*pi/180)-sin((K2)*pi/180)*sin((K3)*pi/180))
//					k_wave_y[n]=0.512*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*sin((K2)*pi/180)*cos((K3)*pi/180)+cos((K2)*pi/180)*sin((K3)*pi/180))
					plot_wave[n]=TwoDwave[k][m]
					n=n+1
					k=k+1
				endfor
			m+=1
		endfor
	elseif(slit ==1)
		K1=s_polar
		K2=s_azi
	
		n=0
		m=0
		for (tilt=tilt_s; tilt <= tilt_e;tilt+=Dimdelta(TwoDwave,1))
			K3=tilt-s_tilt
	 		// horizontal slit
				k=0
				for (pol = tstart; pol <= tend; pol += tdelta) 
		
					ang= pol
					k_wave_x[n]=0.5123*sqrt(Ef)*(lattice1/Pi)*((sin(K1*pi/180)*cos(ang*pi/180)-sin(ang*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(ang*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(ang*pi/180))*sin(K2*pi/180))
					k_wave_y[n]=0.5123*sqrt(Ef)*(lattice2/Pi)*((sin(K1*pi/180)*cos(ang*pi/180)-sin(ang*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(ang*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(ang*pi/180))*cos(K2*pi/180))
//					k_wave_x[n]=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(ang*pi/180)-sin(ang*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*cos(K2*pi/180)-(cos(K1*pi/180)*sin(K3*pi/180)*cos(ang*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(ang*pi/180))*sin(K2*pi/180))
//					k_wave_y[n]=0.5123*sqrt(Ef)*(lattice/Pi)*((sin(K1*pi/180)*cos(ang*pi/180)-sin(ang*pi/180)*sin(K1*pi/180)*cos(K1*pi/180)*sin(K3*pi/180)/sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2))*sin(K2*pi/180)+(cos(K1*pi/180)*sin(K3*pi/180)*cos(ang*pi/180)+sqrt(1-(cos(K1*pi/180)*sin(K3*pi/180))^2)*sin(ang*pi/180))*cos(K2*pi/180))
					plot_wave[n]=TwoDwave[k][m]
					n=n+1
					k=k+1
				endfor
			m+=1
		endfor
	elseif(slit == 2)
		
		Variable p,a,t
		a= s_azi
		n=0
		m=0
		for (tilt=tilt_s; tilt <= tilt_e;tilt+=Dimdelta(TwoDwave,1))
			t=tilt-s_tilt
	 		// horizontal slit
				k=0
				for (pol = tstart; pol <= tend; pol += tdelta) 
					p = pol-s_polar
				
					K1=p*cos(a*pi/180)+t*sin(a*pi/180)
					K2=-p*sin(a*pi/180)+t*cos(a*pi/180)
					k_wave_x[n] = 0.5123*sqrt(Ef)*(lattice1/Pi)*sin(K1*pi/180)
					k_wave_y[n] = 0.5123*sqrt(Ef)*(lattice2/Pi)*sin(K2*pi/180)
//					k_wave_x[n] = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K1*pi/180)
//					k_wave_y[n] = 0.5123*sqrt(Ef)*(lattice/Pi)*sin(K2*pi/180)
					plot_wave[n]=TwoDwave[k][m]
					n=n+1
					k=k+1
				endfor
			m+=1
		endfor
	endif
	DoWindow/K Movie0
	Display/N=Movie0/K=1/W=(100,100,1100,600)
	Display/K=1/Host=Movie0/N=im1/W=(0,0,500,1000)
	Display/K=1/Host=Movie0/N=im2/W=(550,0,1000,1000)

	AppendToGraph/W=Movie0#im1 k_wave_y vs k_wave_x;
	SetAxis/W=Movie0#im1 left -0.19,0.19;DelayUpdate
	SetAxis/W=Movie0#im1 bottom -0.19,0.19
	ModifyGraph margin(left)=85
	ModifyGraph/W=Movie0#im1 width=400,height=399
	ModifyGraph/W=Movie0#im1 zColor(k_wave_y)={plot_wave,*,*,BlueHot,1}
	ModifyGraph/W=Movie0#im1 mode(k_wave_y)=3,marker(k_wave_y)=16,msize(k_wave_y)=5
	ModifyGraph/W=Movie0#im1 fSize=20;DelayUpdate
	Label/W=Movie0#im1 left "\\Z20k\\By\\M \\Z20(\\F'symbol'p\\F'geneva'/a)";DelayUpdate
	Label/W=Movie0#im1 bottom "\\Z20k\\Bx\\M \\Z20(\\F'symbol'p\\F'geneva'/a)"
	ModifyGraph/W=Movie0#im1 nticks=3,minor=1
	ModifyGraph/W=Movie0#im1 gbRGB=(0,0,0),wbRGB=(0,0,0)
	ModifyGraph/W=Movie0#im1 axRGB=(65535,65535,65535),tlblRGB=(65535,65535,65535)
	ModifyGraph/W=Movie0#im1 alblRGB=(65535,65535,65535)	
	
	AppendImage/W=Movie0#im2 AC
	SetAxis/W=Movie0#im2 left -0.45,0.05;DelayUpdate
	SetAxis/W=Movie0#im2 bottom -0.19,0.19
	ModifyImage AC ctab= {*,*,Bluehot,1}
	AppendToGraph/W=Movie0#im2 Eliney vs Elinex
	ModifyGraph/W=Movie0#im2 lsize=2
	ModifyGraph/W=Movie0#im2 fSize=20;DelayUpdate
	Label/W=Movie0#im2 left "\\Z20E-E\BF\M (eV)";DelayUpdate
	Label/W=Movie0#im2 bottom "\\Z20k\\Bx\\M \\Z20(\\F'symbol'p\\F'geneva'/a)"
	ModifyGraph/W=Movie0#im2 width=350,height=402
	ModifyGraph/W=Movie0#im2 margin(top)=28,margin(right)=28,margin(left)=85	
	ModifyGraph/W=Movie0#im2 gbRGB=(0,0,0),wbRGB=(0,0,0)
	ModifyGraph/W=Movie0#im2 axRGB=(65535,65535,65535),tlblRGB=(65535,65535,65535)
	ModifyGraph/W=Movie0#im2 alblRGB=(65535,65535,65535)	
	tbname= "Energy = " + num2str(Dimoffset(w,1)+i*Dimdelta(w,1))+" (meV)"
	//TextBox/W=Movie#im1/C/N=text0 tbname
	DoUpdate/W=Movie0
	AddMovieFrame
		
	endfor
	CloseMovie
end

//Function sym_3D_block(ctrlName): ButtonControl
//	String ctrlName
//	
//	SVAR namewave
//	NVAR low_trip
//	Duplicate/O $namewave Int3D_sym
//	
//	//first make the 3D block square along the theta, tilt direction
//	Variable x_cent = pcsr(A)
//	Variable y_cent = qcsr(A)
//	Variable k,m,n
//	Wave temp_wave_hex
//	Redimension/N = (2*x_cent,-1,2*y_cent)  Int3D_sym
//	Insertpoints/M=2 Dimsize(Int3D_sym,2),(x_cent-y_cent),Int3D_sym
//	Insertpoints/M=2 0,(x_cent-y_cent),Int3D_sym
//	Setscale/P z,Dimoffset(Int3D_sym,2)-(x_cent-y_cent)*Dimdelta(Int3D_sym,2),Dimdelta(Int3D_sym,2),Int3D_sym
//	
//	Make/O/N=(Dimsize(int3D_sym,0),Dimsize(int3D_sym,2)) temp_wave
//	//now zero out all intensity below low_trip * max int for each theta,tilt plane and symmetrize
//	for (m=0;m<Dimsize(Int3D_sym,1);m+=1)
//		Make/O/N=(Dimsize(int3D_sym,0),Dimsize(int3D_sym,2)) temp_wave
//	
//		for (k=0;k<Dimsize(int3D_sym,0);k+=1)
//			for (n=0;n<Dimsize(Int3D_sym,2);n+=1)
//					temp_wave[k][n] =Int3D_sym[k][m][n]
//			endfor 	
//		endfor
//		
//		Wavestats/Q  temp_wave
//		for (k=0;k<Dimsize(temp_wave,0);k+=1)
//			for (n=0;n<Dimsize(temp_wave,1);n+=1)
//				if (temp_wave[k][n]<=(low_trip*V_max))
//					temp_wave[k][n] =0
//				endif
//			endfor 	
//		endfor
//		HexagonallySymmetriseWave("many_win","temp_wave")
//		Int3D_sym[][m][] = temp_wave[p][q]
//		print m
//	endfor
//	
//	
//
//End


Function set_csrD(ctrlName): ButtonControl
	String ctrlName

	variable/G centx,centy,cntr,ctrl
	cntr=0
	ctrl=0
	centx = xcsr(A)
	centy = vcsr(A)

end

Function rot_csrD(ctrlName): ButtonControl
	String ctrlName
	
	Variable  oldxA,oldxB,oldyA,oldyB
	NVAR csrangle, centx, centy
	Variable angle = csrangle*pi/180
	
	oldxA = xcsr(A)
	oldyA = vcsr(A)
	oldxB = xcsr(B)
	oldyB =vcsr(B)
	Variable distA, distB
	VAriable xA,xB,yA,yB
	xA = oldxA-centx
	xB = oldxB-centx
	yA = oldyA-centy
	yB = oldyB-centy
	
	
	Variable nxA,nxB,nyA,nyB
	nxA = (xA*cos(angle)-yA*sin(angle))
	nyA = (xA*sin(angle)+yA*cos(angle))
	
	nxB = (xB*cos(angle)-yB*sin(angle))
	nyB = (xB*sin(angle)+yB*cos(angle))
	
	Variable newxA,newxB,newyA,newyB
	newxA =nxA +centx
	newxB = nxB +centx
	newyA = nyA +centy
	newyB = nyB +centy
	
//	Cursor/I/A=1/C=(64000,64000,64000)/W=Cut3D#image A TwoDwave newxA,newyA
	Cursor/I/A=1/W=Cut3D#image A TwoDwave newxA,newyA
	Cursor/I/A=1/W=Cut3D#image B TwoDwave newxB,newyB
end

// ****************************
// LoadSIStemHDF5_Easy - Loads an .h5 file generated by the SIStem													* 
// 							program used at SIS beamline.															*
//																													*
// 08.07.14 : 		Finished first coding.																			*
// 23.10.14 :		New default data loading mode (mode=1) based on single-image-sized hyperslabs. Hope that this	*
//					will overcome crashes when Igor running on Windows loads large HDF5 files. Also appears that it	*
//					could be slightly faster for large datasets. At the very least, testing shows it is not substantively	*
//					slower.																							*
// ****************************

Function/s LoadSIStemHDF5_Easy(pathStr, [targetFolder, mode, showTime])
	String pathStr
	String targetFolder 		// optional full path to target folder where the data will be loaded (default = root)
	Variable mode			// optional (for debugging; see below)
	Variable showTime		// optional (for debugging)

	if(ParamIsDefault(targetFolder))
		targetFolder = "root:"
	endif
	targetFolder = ParseFilePath(2, targetFolder, ":", 0, 0)	// make sure path is ending with ":"
	
	if(ParamIsDefault(mode))
		mode = 1	// 1: New style, based on loading by single-image hyperslabs. An attempt to overcome crashes when Igor is running on Windows.
					// 0: Old style, straightforward use of HDF5LoadData.
	endif
	if(ParamIsDefault(showTime))
		showTime = 0
	endif
	
	DFREF initialFolder = GetDataFolderDFR()
	DFREF tempFolder = NewFreeDataFolder()
	
	Variable refnum
	HDF5OpenFile/R refnum as pathStr	// read-only
	if(V_flag)
		abort	// cancelled or failed
	endif
	
	Variable timer
	if(showTime)
		timer = startMSTimer
	endif
	
	String baseName = ParseFilePath(3, S_path+S_filename, ":", 0, 0)

	// Get the ARPES data...
	SetDataFolder tempFolder

	if(mode == 0)
		HDF5LoadData/N=W_temp/O/Q refnum, "/Electron Analyzer/Image Data"
		WAVE W_temp
	elseif(mode == 1)
		STRUCT HDF5DataInfo di
		Variable i, j
		
		InitHDF5DataInfo(di)
		HDF5DatasetInfo(refnum, "/Electron Analyzer/Image Data", 0, di)
		Variable rank = di.ndims
		
		Make/O/N=(rank) W_slab = {di.dims[0], di.dims[1], 1}
		HDF5MakeHyperslabWave("W_slab", rank)
		WAVE W_slab
		W_slab[][%Stride] = 1
		W_slab[][%Count] = 1
		W_slab[][%Block] = 1
		W_slab[0][%Block] = di.dims[0]
		W_slab[1][%Block] = di.dims[1]
		W_slab[0][%Start] = 0
		W_slab[1][%Start] = 0
		
		if(rank > 4)
			print "Igor cannot load higher than 4D waves."
			return ""
		elseif(rank < 2)
			print "Something is wrong. This doesn't look like ARPES data."
			return ""
		elseif(rank == 2)
			HDF5LoadData/N=W_temp/O/Q refnum, "/Electron Analyzer/Image Data"
			WAVE W_temp
		elseif(rank == 3)
			Make/O/N=(di.dims[0], di.dims[1], di.dims[2]) W_temp
				for(i = 0; i < di.dims[2]; i += 1)
					W_slab[2][%Start] = i
					HDF5LoadData/N=W_tempImage/O/Q/SLAB=W_slab refnum, "/Electron Analyzer/Image Data"
					WAVE W_tempImage
					W_temp[][][i] = W_tempImage[p][q][0]
				endfor
		elseif(rank == 4)
			Make/O/N=(di.dims[0], di.dims[1], di.dims[2], di.dims[3]) W_temp
			for(i = 0; i < di.dims[2]; i += 1)
				for(j = 0; j < di.dims[3]; j += 1)
					W_slab[2][%Start] = i
					W_slab[3][%Start] = j
					HDF5LoadData/N=W_tempImage/O/Q/SLAB=W_slab refnum, "/Electron Analyzer/Image Data"
					WAVE W_tempImage
					W_temp[][][i][j] = W_tempImage[p][q][0][0]
				endfor
			endfor
		endif
	endif
	
	
	// Handle attributes...
	String att
	
	for(i = 0; i < WaveDims(W_temp); i += 1)
		att = "Axis"+num2str(i)+".Scale"
		HDF5LoadData/A=att/N=W_temp_scale/O/Q refnum, "/Electron Analyzer/Image Data"
		WAVE W_temp_scale
		att = "Axis"+num2str(i)+".Units"
		HDF5LoadData/A=att/N=W_temp_units/O/Q refnum, "/Electron Analyzer/Image Data"
		WAVE/T W_temp_units
		att = "Axis"+num2str(i)+".Description"
		HDF5LoadData/A=att/N=W_temp_description/O/Q refnum, "/Electron Analyzer/Image Data"
		WAVE/T W_temp_description
		
		if(i == 0)
			SetScale/P x, W_temp_scale[0], W_temp_scale[1], W_temp_units[0], W_temp
		elseif(i == 1)
			SetScale/P y, W_temp_scale[0], W_temp_scale[1], W_temp_units[0], W_temp
		elseif(i == 2)
			SetScale/P z, W_temp_scale[0], W_temp_scale[1], W_temp_units[0], W_temp
		elseif(i == 3)
			SetScale/P t, W_temp_scale[0], W_temp_scale[1], W_temp_units[0], W_temp
		endif
		SetDimLabel i, -1, $(W_temp_description[0]), W_temp
	endfor
	att = "Intensity Units"
	HDF5LoadData/A=att/N=W_temp_intensityUnits/O/Q refnum, "/Electron Analyzer/Image Data"
	WAVE/T W_temp_intensityUnits
	SetScale d, 0, 1, W_temp_intensityUnits[0], W_temp
	
	// stuff as much data from the attributes into the wave note as practical...
	HDF5ListAttributes refnum, "/Electron Analyzer/Image Data"
	for(i = 0; i < ItemsInList(S_HDF5ListAttributes); i += 1)
		att = StringFromList(i, S_HDF5ListAttributes)
		
		InitHDF5DataInfo(di)
		HDF5AttributeInfo(refnum, "/Electron Analyzer/Image Data", 2, att, 0, di)
		rank = di.ndims 
		strswitch(di.datatype_class_str)
			case "H5T_INTEGER":
			case "H5T_FLOAT":
			case "H5T_ENUM":
			case "H5T_OPAQUE":
			case "H5T_BITFIELD":
				HDF5LoadData/A=att/N=W_attTemp/O/Q refnum, "/Electron Analyzer/Image Data"
				WAVE W_attTemp
				if(rank == 0 || (rank == 1 && di.dims[0] == 1))	// currently ignores any array attributes
					Note W_temp, att+"="+num2str(W_attTemp[0])
				endif
				break
			
			case "H5T_STRING":
				HDF5LoadData/A=att/N=W_strAttTemp/O/Q refnum, "/Electron Analyzer/Image Data"
				WAVE/T W_strAttTemp
				if(rank == 0 || (rank == 1 && di.dims[0] == 1))	// currently ignores any array attributes
					Note W_temp, att+"="+W_strAttTemp[0]
				endif
				break
		endswitch
	endfor
	
	HDF5CloseFile refnum
	
	Variable timer2
	if(showTime)
		timer2 = startMSTimer
	endif

	// Overwrite any existing wave with the same name in the target directory
	String destination = targetFolder + PossiblyQuoteName(baseName)
	KillWaves/Z $destination
	if(!WaveExists($destination))
		MoveWave W_temp, $destination	// try to conserve memory...
	else
		Duplicate/O W_temp, $destination	// ... but use brute force if necessary
	endif
	SetDataFolder initialFolder
	
	if(showTime)
		print "Execution time: "+num2str(stopMSTimer(timer)/1000)+" ms. "+num2str(stopMSTimer(timer2)/1000)+" ms were spent copying the finished data to the final location."
	endif
	return destination
End