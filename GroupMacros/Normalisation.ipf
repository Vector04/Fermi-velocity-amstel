#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.



Function put_k_EDM_SS(W)
	wave W
	Variable lattice, slit
	lattice=pi
	
	Variable Ef = 1.8728 // 1.8728 // 16.94 //Ef=1.8825//16.918 PE10 //889 = EP10, 885 = EP20
	Variable kx_b,ky_b,kpar_b,kx_e,ky_e,kpar_e,k_inc
	Variable pol_inc = Dimsize(W,0) //number of chanels along the slit 
	Variable K1, K2, K3
	Variable pol //dummy vars 
	
	Duplicate/O W, $(nameofwave(w)+"_k")
	wave kEDM = $(nameofwave(w)+"_k")
	//Polar and phi
	K1=-30//Along slit
	K2=0//
	K3=0

	
			pol = K1+Dimoffset(w,0)
			kx_b=0.5123*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*cos((K2)*pi/180)*cos((K3)*pi/180)-sin((K2)*pi/180)*sin((K3)*pi/180))
			ky_b=0.5123*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*sin((K2)*pi/180)*cos((K3)*pi/180)+cos((K2)*pi/180)*sin((K3)*pi/180))
			
			pol = K1+Dimoffset(w,0)+(DimSize(w,0)-1)*DimDelta(w,0)
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
				print "1"
			elseif ((kx_b >= 0)&&(ky_b >= 0))
				kpar_b=-sqrt(kx_b*kx_b+ky_b*ky_b)                   // watch out for the signs here (SB)
				k_inc=sqrt((kx_e-kx_b)^2+(ky_e-ky_b)^2)/pol_inc     // watch out for the signs here (SB)
				print "2"
			elseif	((kx_b >= 0)&&(ky_b <= 0))
				kpar_b=-sqrt(kx_b*kx_b+ky_b*ky_b)
				k_inc=+sqrt((kx_e-kx_b)^2+(ky_e-ky_b)^2)/pol_inc
				print "3"
			elseif	((kx_b <= 0)&&(ky_b >= 0))
				kpar_b=-sqrt(kx_b*kx_b+ky_b*ky_b)
				k_inc=+sqrt((kx_e-kx_b)^2+(ky_e-ky_b)^2)/pol_inc
				print "4"
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
				
//		pol = K1+Dimoffset(W,0)
//			kx_b=0.5123*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*cos((K2)*pi/180)*cos((K3)*pi/180)-sin((K2)*pi/180)*sin((K3)*pi/180))
//			ky_b=0.5123*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*sin((K2)*pi/180)*cos((K3)*pi/180)+cos((K2)*pi/180)*sin((K3)*pi/180))
//			kpar_b=-sqrt(kx_b*kx_b+ky_b*ky_b)	
//			
//			pol = K1+Dimoffset(W,0)+(DimSize(W,0)-1)*DimDelta(W,0)
//			kx_e=0.5123*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*cos((K2)*pi/180)*cos((K3)*pi/180)-sin((K2)*pi/180)*sin((K3)*pi/180))
//			ky_e=0.5123*sqrt(Ef)*lattice/pi *(sin((pol)*pi/180)*sin((K2)*pi/180)*cos((K3)*pi/180)+cos((K2)*pi/180)*sin((K3)*pi/180))
//			kpar_e=sqrt(kx_e*kx_e+ky_e*ky_e)	
//			
//				k_inc=abs(kpar_e-kpar_b)/pol_inc
//			
//			SetScale	/P x, kpar_b,k_inc,"", kEDM
//			variable a = dimoffset(kedm,1)
//			Setscale/P y, a-Ef,dimdelta(kedm,1),kedm
			
End



Function MakeEdgesWave(centers, edgesWave) 
	Wave centers // Input
	Wave edgesWave // Receives output
   	Variable N=numpnts(centers)
  	Redimension/N=(N+1) edgesWave
	edgesWave[0]=centers[0]-0.5*(centers[1]-centers[0])
	edgesWave[N]=centers[N-1]+0.5*(centers[N-1]-centers[N-2]) 
	edgesWave[1,N-1]=centers[p]-0.5*(centers[p]-centers[p-1])
End

Function DemoPlotXYZAsImage()
   wave FWHM_all_50K, Allangles,Alldopings
   
   Make/O edgesX; MakeEdgesWave(AllAngles,edgesX)
   Make/O edgesY; MakeEdgesWave(Alldopings,edgesY)
   Display; AppendImage FWHM_all_50K vs {edgesX,edgesY}

end                                         

Function HighT_sub(w,wht)
	wave w, wht
	Duplicate/o w, $(nameofwave(w)+"_HT")
	wave diffht = $(nameofwave(w)+"_HT")
	
	diffht = w - wht
end

Function UD_OD(w)
	wave w
	string help = nameofwave(w)
	string nieuw = replacestring("FIX00003", help, "BST_AlO")
	
	rename w, $(nieuw)
//	Note w "Symmetrized around k=0"
end


Function normalize_EDC(w)
	wave w
	variable bck1,bck2,norm1,norm2
	
	bck1 = 0.1//range for background subtraction above EF
	bck2 = 0.15
	
	norm1 = -0.5 //range for normalisation at high BE
	norm2 = -0.4
	
	variable bck = sum(w,bck1,bck2)/(abs(x2pnt(w,bck1)-x2pnt(w,bck2)))
		w -= bck
		
	variable norm_cst = sum(w,norm1,norm2)/(abs(x2pnt(w,norm1)-x2pnt(w,norm2)))
		w /= norm_cst	
end	
////Setscale/P x, $(nameofwave(%s)+"Y")[0], $(nameofwave(%s)+"Y")[1]-$(nameofwave(%s)+"Y")[0], $(nameofwave(%s))

function/wave Norm_EDM_EDC(w)
	wave w
	Duplicate/O w, $(nameofwave(w)+"_Nrm")
	wave wnorm = $(nameofwave(w)+"_Nrm")
	wnorm =0
	
	
	variable bck1,bck2,norm1,norm2
	
	bck1 = 0.1//range for background subtraction above EF
	bck2 = 0.15
	
	norm1 = -0.6 //range for normalisation at high BE
	norm2 = -0.5
	variable ii
	for(ii=0;ii<dimsize(w,0);ii+=1)
		duplicate/o/R=[ii][] w, edc2norm
		matrixtranspose edc2norm
		Redimension/N=-1 edc2norm
		
		variable bck = sum(edc2norm,bck1,bck2)/(abs(x2pnt(edc2norm,bck1)-x2pnt(edc2norm,bck2)))
		edc2norm -= bck
		
		variable norm_cst = sum(edc2norm,norm1,norm2)/(abs(x2pnt(edc2norm,norm1)-x2pnt(edc2norm,norm2)))
		
		edc2norm /= norm_cst
		
		wnorm[ii][] = edc2norm[q]
	
	endfor
	
	return wnorm
	
end

Function/wave mirror_EDC(w)
	wave w
	variable numpts = abs((dimoffset(w,0) * 2)/dimdelta(w,0) )
	
	duplicate/o w, w_flip
	setscale/P x, -dimoffset(w,0), -dimdelta(w,0), w_flip
	make/O/n=(numpts) $(nameofwave(w)+"_m")
	wave w_m = $(nameofwave(w)+"_m")
	w_m = 0
	setscale/P x, dimoffset(w,0), dimdelta(w,0), w_m
	variable begin = dimsize(w,0)-1
	variable b2 = dimsize(w_m,0)-dimsize(w_flip,0)
	variable ending = dimsize(w_m,0)
	w_m[0,begin] = w(x)
	w_m[b2,ending] += w_flip(x)
	
	
	variable tester = 0
	return w_m
end

function Flip_edm(w) //for edms!
	wave w
	variable numpts = abs((dimoffset(w,1) * 2)/dimdelta(w,1) )
	
	duplicate/o w, w_flip
	setscale/P y, -dimoffset(w,1), -dimdelta(w,1), w_flip
	make/O/n=(dimsize(w,0),numpts) $(nameofwave(w)+"_m")
	wave w_m = $(nameofwave(w)+"_m")
	w_m = 0
	setscale/P x, dimoffset(w,0), dimdelta(w,0), w_m
	setscale/P y, dimoffset(w,1), dimdelta(w,1), w_m
	
	variable begin = dimsize(w,1) - 1
	variable b2 = dimsize(w_m,1)-dimsize(w_flip,1) + 2
	variable ending = dimsize(w_m,1)  -1
	w_m[][0,begin] = w(x)(y)
	w_m[][b2,ending] += w_flip(x)(y)
	
	variable test = 0

end



Function/wave sub_norm_EDM(w1,w2)
	wave w1,w2
	
	Duplicate/o w1, $(nameofwave(w1)+"_diff")
	
	wave diff = $(nameofwave(w1)+"_diff")
	
	wave w1_n = Norm_EDM_EDC(w1)
	wave w2_n = Norm_EDM_EDC(w2)
	
	
	diff = w1_n - w2_n
end