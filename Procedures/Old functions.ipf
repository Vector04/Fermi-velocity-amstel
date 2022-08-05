#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function compare_widths()
	Duplicate/O root:FitVictor:EDM_n1 EDM	
	
	make/O energies = {-0.035, -0.025, -0.015, -0.05}
	variable i;
//	for(i=0; i < 4; i++)
		
		
	variable eidx = -0.02 //scaletoIndex(EDM, energies[i], 1)
	variable a, b
	wave c
	print "Energy: ", energies[i], "Index: ", eidx
	make/O /D /N=5 coeffs={1e5, 1e6, 20, -0.05, 1}
	
	[a, b, c] = get_peakcenter_and_width_voigt(EDM, eidx, coeffs=coeffs)
	Duplicate/O/R=[](eidx) EDM, edmslice
	redimension/n=-1 edmslice
	
	duplicate/O edmslice mdcfit

	
	display/k=1 edmslice; ModifyGraph mode(edmslice)=3,marker(edmslice)=8
//	CurveFit/M=2/W=0/TBOX=(0x300) Voigt, kwCWave=coeffs, edmslice /D=mdcfit
	FuncFit/M=2/W=0/TBOX=(0x300) VoigtVictor, coeffs, edmslice  /D=mdcfit

	appendtograph mdcfit
		
	
		
//	endfor

end

function compare_widths2()
	Duplicate/O root:FitVictor:EDM_n1 EDM	
	
	make/O /D /N=5 coeffs={1e5, 1e6, 20, -0.05, 1}
	
	Duplicate/O/R=[](-0.020) EDM, edmslice

	Funcfit/M=2 VoigtVictor, kwCWave=coeffs, edmslice
	variable width_gaussian = sqrt(ln(2)) / coeffs[2]
	variable width_lorentz = coeffs[4] / (coeffs[2])
	variable eidx = scaletoindex(EDM, -0.020, 1)
	
	variable a, b; wave c
	[a,b,c] = get_peakcenter_and_width_voigt(EDM, eidx, coeffs=coeffs)
	
	
	
	
end



function display_horizontal_slice()
	Duplicate/O root:FitVictor:EDM_n1 EDM	
	variable kf = -0.0604375
	variable delta = dimdelta(EDM, 0)
	variable offset = dimoffset(EDM, 0) - kf
	setscale/P x, offset, delta, EDM
	
	Display/k=1;DelayUpdate
	AppendImage EDM
	ModifyImage EDM ctab= {*,*,BlueHot256,1}
	Label bottom "momentum"
	Label left "Energy (eV)"
	modifygraph fsize(left)=20, fsize(bottom)=20
	Label bottom "\\Z20\\F'Garamond' k - k\\BF\\M (\\Z16Å \\S-1 \\M\\Z20)\\u#2"
	Label left "\\Z20\\F'Garamond'E - E\\BF\\M (meV)\\u#2"
	variable kmin = dimoffset(EDM, 0), kmax = dimoffset(EDM, 0) + dimdelta(EDM, 0) * dimsize(EDM, 0)
	modifygraph font="garamond", fsize=20
	
	make/O /N=2 Ef = {0, 0}, Eslice={-0.02, -0.02}
	setscale/I x, kmin, kmax, Ef, Eslice
	appendtograph Ef, Eslice
		
//	variable slice_energy = -0.0045227 + 0.000504202
	variable slice_energy = -0.020
	
	Duplicate/O/R=()(slice_energy) EDM, edmslice
	redimension/n=-1 edmslice
	
	
	
	variable size = dimsize(edmslice, 0) 
	delta = dimdelta(edmslice, 0) 
	offset = dimoffset(edmslice, 0)
	
	make/O /N=(size) voigt_fit, lor_fit
	setscale /P x, offset, delta, voigt_fit, lor_fit
	
	
	display/k=1 edmslice
	make/O /N=5 /D final_coeffs_voigt
	make/O /N=4 /D final_coeffs_lor
	CurveFit/M=2/W=2 lor, kwCWave=final_coeffs_lor, edmslice /D=lor_fit
	CurveFit/M=2/W=2 Voigt, kwCWave=final_coeffs_voigt, edmslice /D=voigt_fit
	appendtograph lor_fit//, voigt_fit
	TextBox/C/N=text0/A=LT "\\Z20\\F'Calibri'E = " +  num2str(1000*slice_energy) + " meV \rNode 1"
//	TextBox/C/N=text2/A=RB "\\Z20\\F'Calibri'Node 1"
//	Legend/C/N=text1/A=RT
//	
	ModifyGraph mode(edmslice)=3,marker(edmslice)=8,useMrkStrokeRGB(edmslice)=1,mrkStrokeRGB(edmslice)=(65535,21845,0)
	Modifygraph lstyle(lor_fit)=0,rgb(lor_Fit)=(0, 65535, 0), lsize(lor_fit)=2		
//	Modifygraph lstyle(voigt_fit)=0,rgb(voigt_Fit)=(16385,28398,65535), lsize(voigt_fit)=2		
	modifygraph fsize(left)=20, fsize(bottom)=20
	Label bottom "\\Z20\\F'Calibri' Momentum (\\Z16Å \\S-\\F'Calibri'1 \\M\\Z20)\\u#2"
	Label left "\\Z20\\F'Calibri'Intensity\\F'Calibri'\\u#2"
end


function display_peakcenters_position()
	Duplicate /O root:EDMS:peakcenters peakcenters
	variable start, delta, size, i
	
	start = DimOffset(peakcenters, 0)
	delta = DimDelta(peakcenters, 0)
	size = DimSize(peakcenters, 0)
	print start
	print delta
	
	start = 1.835
	delta = 0.000504202
	
	make/O /N=(size) energies
	for (i = 0; i < size; i++)
		energies[i] = start + i * delta
	endfor
	

	Display peakcenters
	
	Display energies vs peakcenters 
end

function display_edm_and_disperion()
	Duplicate /O root:FitVictor:EDM_n3 EDM
	
	wave peakcenters = get_all_peakcenters(EDM)
	
	duplicate /O /R=(*, 0) peakcenters, peakcenters_trunc
	 	
	Display/k=1;DelayUpdate
	AppendImage EDM
	ModifyImage EDM ctab= {*,*,BlueHot256,1}
	
	appendtograph /VERT peakcenters_trunc
	modifygraph rgb(peakcenters_trunc)=(0,65535,0)
	
	
end



function make_FD_dist(inputwave, peakcenters, energies)
	wave inputwave, peakcenters, energies
	
	variable size, i
	size = DimSize(peakcenters, 0)
	make/O /N=(size) intensities
	for(i = 0; i < size; i++)
		intensities[i] = inputwave(peakcenters[i])(energies[i])
	endfor
	SetScale/P x 1.835,0.000504202,"eV", intensities
	
	display intensities
	
end

function two_line_fit_and_plot(peakcenters_trunc, energies_trunc)
	wave peakcenters_trunc, energies_trunc
	
	variable size = Dimsize(peakcenters_trunc, 0)
	
	make/O /N=(size) energies_trunc_upper 
	make/O /N=(size) energies_trunc_middle 
	make/O /N=(size) energies_trunc_lower
	
	make/O /D /N=2 coeffs_upper, coeffs_middle, coeffs_lower
	
	
	display/k=1 energies_trunc vs peakcenters_trunc
	
	ModifyGraph mode(energies_trunc)=3,marker(energies_trunc)=19,rgb(energies_trunc)=(0,65535,0)
	
	// Fit upper part
	CurveFit line kwCWave=coeffs_upper, energies_trunc[70, 82] /X=peakcenters_trunc /D=energies_trunc_upper 
	Appendtograph energies_trunc_upper[70, 82] vs peakcenters_trunc[70, 82]	
	ModifyGraph rgb(energies_trunc_upper)=(0,0,0)
	
	// Fit Middle part
	CurveFit line kwCWave=coeffs_middle, energies_trunc[35, 70] /X=peakcenters_trunc /D=energies_trunc_middle
	Appendtograph energies_trunc_middle[35, 70] vs peakcenters_trunc[35, 70]	
	ModifyGraph rgb(energies_trunc_middle)=(1,9611,39321)
	ModifyGraph grid(bottom)=1,gridStyle(bottom)=5,gridRGB(bottom)=(56797,56797,56797)
	SetAxis bottom -0.1,0
	ModifyGraph grid=1,gridStyle=5,gridRGB(left)=(52428,52428,52428)

end

function/wave fit_all_topranges_of_peakcenters(wave peakcenters_trunc, wave energies_trunc)
	
	variable Emin, chisq
	wave coeffs, coeffs_error
	variable start = DimOffset(peakcenters_trunc, 0)
	variable delta = DimDelta(peakcenters_trunc, 0)
	variable size = Dimsize(peakcenters_trunc, 0)
	
	make/O /N=(size, 2) /D all_coeffs_top
	make/O /N=(size-10) all_chisq_top
	SetScale/P x start + 5 * delta, delta,"eV", all_coeffs_top
	SetScale/P x start + 5 * delta, delta,"eV", all_chisq_top
	
	for (Emin = 5; Emin < size-5; Emin++)
		[coeffs,coeffs_error, chisq] = fit_range_of_peakcenters(peakcenters_trunc, energies_trunc, Emin, size)
		all_coeffs_top[Emin-5] = coeffs[0]
		all_chisq_top[Emin-5] = chisq
		
	endfor
	return all_chisq_top
	
end


function get_peakcenter(inputwave, eidx)
	wave inputwave
	variable eidx
	
	make/O /N=5 /D final_coeffs
	Duplicate/O/R=[][eidx] inputwave, edmslice
	redimension/n=-1 edmslice
	
	CurveFit/M=2 /Q Voigt, kwCWave=final_coeffs, edmslice/D
	return final_coeffs[2]

end


function/wave get_all_peakcenters(inputwave)
	wave inputwave
	variable start, delta, size, eidx
	
	start = DimOffset(inputwave, 1)
	delta = DimDelta(inputwave, 1)
	size = DimSize(inputwave, 1)

	make/O /N=(size) /D peakcenters
	SetScale/P x start, delta,"eV", peakcenters
	
	
	for (eidx=0; eidx < size; eidx+=1)
		peakcenters[eidx] = get_peakcenter(inputwave, eidx)
	endfor 
	return peakcenters
	
end

function piecewise_line_fit_and_plot(peakcenters_trunc, energies_trunc)
	wave peakcenters_trunc, energies_trunc
	
	display/k=1 energies_trunc vs peakcenters_trunc
	ModifyGraph mode(energies_trunc)=3,marker(energies_trunc)=8,rgb(energies_trunc)=(65535,0, 0)
	
	
	Make/D/N=4/O piecewise_line_coeffs
	// Intials for nr. 5, 6, 7 respectively
	piecewise_line_coeffs[0] = {0.010,-0.02,-1.5,-1.7}
//	piecewise_line_coeffs[0] = {-0.02, -0.02,-1.5,-2}
//	piecewise_line_coeffs[0] = {-0.02, -0.02, -1.5, -2}
	make /O /N=(DimSize(peakcenters_trunc, 0)) piecewise_line_result
	
	variable i
	for (i = 0; i < DimSize(peakcenters_trunc, 0); i++)
		piecewise_line_result[i] = Piecewise_Linear(piecewise_line_coeffs, peakcenters_trunc[i])
	endfor
	
	funcfit Piecewise_Linear piecewise_line_coeffs, energies_trunc /X=peakcenters_trunc /D=piecewise_line_result
	
	appendtograph piecewise_line_result vs peakcenters_trunc
	ModifyGraph rgb(piecewise_line_result)=(0, 0, 0)
	ModifyGraph grid(bottom)=1,gridStyle(bottom)=5,gridRGB(bottom)=(56797,56797,56797)
//	SetAxis bottom -0.07,-0.035
	ModifyGraph grid=1,gridStyle=5,gridRGB(left)=(52428,52428,52428)
	
	make/O /N=1 kink_k = {piecewise_line_coeffs[0]}, kink_E = {piecewise_line_coeffs[1]}
	appendtograph kink_E vs kink_k
	ModifyGraph mode(kink_E)=3,marker(kink_E)=8,rgb(kink_E)=(0,0,0), mrkThick(kink_E)=1.2
	TextBox/C/N=text0/A=RT /G=(65535, 0, 0) "Node 1\rKink energy at: " + num2str(1000 * kink_E[0]) + " meV"
	modifygraph fSize(bottom)=20, fSize(left)=20 
	modifygraph font="Garamond" 
	Label bottom "Momentum \\$WMTEX$ k - k_F \\$/WMTEX$ (m\\Z15Å \\S -1 \\M\\Z20)\\u#2"
	Label left "Energy (meV)\\u#2"

end

function piecewise_linear_widths(variable node)
	switch(node)
	 		case 1:
            Duplicate/O root:FitVictor:EDM_n1 EDM
				make /O /N=3 nodecolor = {65535, 0, 0} // red
            break;
        case 3:
            Duplicate/O root:FitVictor:EDM_n3 EDM
				make /O /N=3nodecolor = {0, 65535, 0} // green
            break;
        case 4:
            Duplicate/O root:FitVictor:EDM_n4 EDM
				make /O /N=3 nodecolor = {37779,5654,65535} // purple
            break;
   endswitch
	wave Es, ks, dks, gams, dgams
	[Es, ks, dks, gams, dgams] = get_all_lor2(EDM)
	
	duplicate/O /R=(*, 0) gams, gams2, gams2_fit
	duplicate/O /R=(*, 0) dgams, dgams2
	
	Make/D/N=4/O coeffs = {-0.01, 0.010,-0.5,-0.3}

//	FuncFit/TBOX=768 Piecewise_Linear_Double coeffs peakcenters_trunc /D 
	
	gams2_fit = Piecewise_Linear(coeffs, gams2[p])
	FuncFit/M=2 Piecewise_Linear, coeffs, gams2 /D=gams2_fit /I=1 /W=dgams2 /F={0.68, 4}

	// Display widths
	display/VERT /k=1 /W=(0,0,1080/3-20,400) gams2
	ModifyGraph mode(gams2)=3,marker(gams2)=8, rgb(gams2)=(nodecolor[0], nodecolor[1], nodecolor[2])
	// Display fit result
	appendtograph/VERT gams2_fit
	modifygraph rgb(gams2_fit)=(0,0,0)
	// Display kink location
	make/O /N=1 kink_k = {coeffs[1]}, kink_E = {coeffs[0]}
	appendtograph kink_E vs kink_k
	ModifyGraph mode(kink_E)=3,marker(kink_E)=8,rgb(kink_E)=(0,0,0), mrkThick(kink_E)=1.2

	TextBox/C/N=text0/G=(nodecolor[0], nodecolor[1], nodecolor[2])/A=RT "\\F'Garamond'\\Z20Node " + num2str(node)
	modifygraph fSize(bottom)=20, fSize(left)=20, lsize(gams2_fit)=1.3
	
	ModifyGraph grid(bottom)=1,nticks(bottom)=4,gridStyle(bottom)=4,gridRGB(bottom)=(43690,43690,43690)
	ModifyGraph grid(left)=1,nticks(left)=4,gridStyle(left)=4,gridRGB(left)=(43690,43690,43690)
	modifygraph  font="Garamond"
	Label bottom "Peakwidth Γ (m\\Z15Å \\S -1 \\M\\Z20)\\u#2"
	Label left "E - E\BF\M (meV)\\u#2"
	

end


function run_piecewise_linear()
	Duplicate/O root:FitVictor:EDM_n1 EDM
	
	wave peakcenters = get_all_peakcenters(EDM)
	wave energies = get_energies(EDM)
	
	// I would like to draw the peakcentersline only up to the ~fermi level
	Duplicate/O /R=(*, 0) peakcenters peakcenters_trunc
	peakcenters_trunc = peakcenters[p] - peakcenters(0)
	Duplicate/O /R=(*, 0) energies energies_trunc
	
	
//	Display/k=1; DelayUpdate
//	AppendImage EDM
//	ModifyImage EDM ctab= {*,*,BlueHot256,1}
//	Label bottom "k"
//	Label left "Energy"
//
//   AppendToGraph energies_trunc vs peakcenters_trunc
//   ModifyGraph rgb(energies_trunc)=(65535,0,0)
//   ModifyGraph marker(energies_trunc)=8

	
   piecewise_line_fit_and_plot(peakcenters_trunc, energies_trunc)
	
end

Function Piecewise_Linear_Double(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ // w = {w[0], w[1], w[2], w[3], w[4], w[5]} (w[5] = (w[3] - w[2]) / (w[1] - w[0])
	//CurveFitDialog/ variable result
	//CurveFitDialog/ if (x < x1)
	//CurveFitDialog/ 	result = y1 + (x - x1) * s1
	//CurveFitDialog/ elseif (x > x1 && x < x2) // eq of line is: y - w[2] = (x - w[0]) * w[5] = (x - w[0]) * (w[3] - w[2]) / (w[1] - w[0])
	//CurveFitDialog/ 	result = y1 + (x - x1) * (y2 - y1) / (x2 - x1)
	//CurveFitDialog/ elseif (x > x2)
	//CurveFitDialog/ 	result = y2 + (x - x2) * s3
	//CurveFitDialog/ endif
	//CurveFitDialog/ f(x) = result
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 6
	//CurveFitDialog/ w[0] = x1
	//CurveFitDialog/ w[1] = x2
	//CurveFitDialog/ w[2] = y1
	//CurveFitDialog/ w[3] = y2
	//CurveFitDialog/ w[4] = s1
	//CurveFitDialog/ w[5] = s3

	// w = {w[0], w[1], w[2], w[3], w[4], w[5]} (w[5] = (w[3] - w[2]) / (w[1] - w[0])
	variable result
	if (x < w[0])
		result = w[2] + (x - w[0]) * w[4]
	elseif (x > w[0] && x < w[1]) // eq of line is: y - w[2] = (x - w[0]) * w[5] = (x - w[0]) * (w[3] - w[2]) / (w[1] - w[0])
		result = w[2] + (x - w[0]) * (w[3] - w[2]) / (w[1] - w[0])
	elseif (x > w[1])
		result = w[3] + (x - w[1]) * w[5]
	endif
	return result
End

function calc_piecewise_linear_v2()

	Duplicate/O root:FitVictor:EDM_n1 EDM
	
	wave peakcenters, peakwidths
	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM)
	wave energies = get_energies(EDM)
	
	duplicate/O /R=(*, 0.005) energies, energies_trunc
	duplicate/O /R=(*, 0.005) peakcenters, peakcenters_trunc
	
	make/O /N=6 /D coeffs={-0.06, -0.04, 0, -1.5, -1.8, -2}
//	make/O /N=()

	make /O /N=(Dimsize(peakcenters_trunc, 0)) energies_test = Piecewise_Linear_double(coeffs, peakcenters_trunc[p])
	
	display/k=1 energies_trunc vs peakcenters_trunc
	appendtograph energies_test vs peakcenters_trunc
	
//	FuncFit Piecewiese_Linear_Double, coeffs, energies_trunc /X=peakcenters_trunc
	
	
end

function calc_piecewise_linear_v3(variable node)
	
	switch(node)
	 		case 1:
            Duplicate/O root:FitVictor:EDM_n1 EDM
				make /O /N=3 nodecolor = {65535, 0, 0} // red
            break;
        case 3:
            Duplicate/O root:FitVictor:EDM_n3 EDM
				make /O /N=3nodecolor = {0, 65535, 0} // green
            break;
        case 4:
            Duplicate/O root:FitVictor:EDM_n4 EDM
				make /O /N=3 nodecolor = {37779,5654,65535} // purple
            break;
    endswitch

	print "Node " + num2str(node) 
	
	wave peakcenters, peakwidths, Es, dks, dgams
	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM)
	[Es, peakcenters, dks, peakwidths, dgams] = get_all_lor2(EDM)
	wave energies = get_energies(EDM)
	
	duplicate/O /R=(*, 0.) energies, energies_trunc
	duplicate/O /R=(*, 0) peakcenters, peakcenters_trunc
	duplicate/O /R=(*, 0) dks, dks2
	peakcenters_trunc = peakcenters[p] - peakcenters(0)
	
	make/O /N=6 /D coeffs = {-0.02,-0.004,0.005, 0.015,-0.3,-0.8}

	make /O /N=(Dimsize(peakcenters_trunc, 0)) peakcenters_fit = Piecewise_Linear_double(coeffs, energies_trunc[p])
	
	
	display/VERT /W=(0,0,1080/3,400) peakcenters_trunc
	ModifyGraph mode(peakcenters_trunc)=3,marker(peakcenters_trunc)=8, rgb(peakcenters_trunc)=(nodecolor[0], nodecolor[1], nodecolor[2])
	appendtograph/VERT peakcenters_fit vs energies_trunc
	modifygraph rgb(peakcenters_fit)=(0,0,0)
	
	FuncFit/M=2 Piecewise_Linear_Double, coeffs, peakcenters_trunc /D=peakcenters_fit /I=1 /W=dks2 /F={0.68, 4}
	make/O /N=2 kinkpoints = coeffs[p+2];setscale /I x coeffs[0], coeffs[1], kinkpoints
	appendtograph/VERT kinkpoints
	ModifyGraph mode(kinkpoints)=3,marker(kinkpoints)=8,rgb(kinkpoints)=(0,0,0), mrkThick(kinkpoints)=1.2
	TextBox/C/N=text0/G=(nodecolor[0], nodecolor[1], nodecolor[2])/A=RT "\\F'Garamond'\\Z20Node " + num2str(node)
	modifygraph fSize(bottom)=20, fSize(left)=20, lsize(peakcenters_fit)=1.3, font="Garamond"

	Label bottom "k - k\BF\M (m\\Z15Å \\S -1 \\M\\Z20)\\u#2"
	Label left "E - E\BF\M (meV)\\u#2"
	
	ModifyGraph grid(bottom)=1,nticks(bottom)=4,gridStyle(bottom)=4,gridRGB(bottom)=(43690,43690,43690)
	ModifyGraph grid(left)=1,nticks(left)=4,gridStyle(left)=4,gridRGB(left)=(43690,43690,43690)

end


function temp()
	duplicate /O root:FitVictor:EDM_n1 EDM
	
	Duplicate/O/R=[][110] EDM, edmslice
	redimension/n=-1 edmslice
	display/k=1 edmslice
	variable x0, width
	wave coeffs
	[x0, width, coeffs] = get_peakcenter_and_width_voigt(EDM, 60)
	print x0, width
	variable i
	for (i=0; i < 5; i++)
		print "coeff", i, coeffs[i]
	endfor

end	

Function Piecewise_Linear1(w,x)
	Wave w
	Variable x
	// w = {y_kink, slope_left, slope_right, x_kink}

	variable result		
		if (x >= w[3])
			result =  w[0] + w[2] * (x - w[3])
		else
			result = w[0] + w[1] * (x - w[3])
		endif
	return result
End



function make_gui_kink_method2_test(variable doregionfit)
	variable node = 1, type=0
	// Node: 1, 3, 4. 
	// Type: 0 for peakcenters, 1 for peakwidths. 
	// Doregionfit: 1 to extend best fits accross entire region (kink2kink)
	duplicate /O root:FitVictor:EDM_n1 EDM
	
	variable fitwidth = 7

	wave peakcenters, peakwidths, energies_trunc

	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM)
	wave energies = get_energies(EDM)
	
	variable delta = DimDelta(energies, 0)
	variable fitwidth_energy = fitwidth * delta
	print 2 * fitwidth_energy
	
	Duplicate/O /R=(*, 0.005) energies energies_display, peakinfo_display
	make /O piecewise_line_coeffs = {-0.06,-1.95,-2,-0.015} 	// w = {y_kink, slope_left, slope_right, x_kink}
	
	peakinfo_display = Piecewise_Linear1(piecewise_line_coeffs, x)
	make/O /N=1 kink_indices = {38}
	make/O /N=2 center_indices = {28, 48}
	make/O /N=3 nodecolor = {1,16019,65535}
	string labelbottom = "Testing data"
	
	
	// Getting data for chisq graph	
	wave all_chisq, all_coeffs, all_coeffs_error
	[all_chisq, all_coeffs, all_coeffs_error] = fit_all_ranges_with_centerpeakcenters2(peakinfo_display, energies_display, fitwidth)
	
	duplicate /O /R=(*, -fitwidth_energy) all_chisq all_chisq_core
	duplicate /O /R=(*, -fitwidth_energy) all_coeffs all_coeffs_core
	duplicate /O /R=(-fitwidth_energy, *) all_chisq all_chisq_extra
	duplicate /O /R=(-fitwidth_energy, *) all_coeffs all_coeffs_extra
	
	// EDM / Dispersion graph
	DoWindow/K EDMVictor
	Display/N=EDMVictor /K=1 /W=(300,40,1080,500)
	Display/K=1/Host=EDMVictor/N=edm/W=(0, 0, 0.5, 1); 
//	AppendImage EDM;
//	ModifyImage edm ctab= {*,*,BlueHot256,1}
	
	
	// peakcenters
	Appendtograph energies_display vs peakinfo_display
	ModifyGraph rgb(energies_display)=(nodecolor[0], nodecolor[1], nodecolor[2]), mode(energies_display)=3, marker(energies_display)=8
	TextBox/C/N=text0/G=(nodecolor[0], nodecolor[1], nodecolor[2]) "Testing data" // Display node
	
	// displaying the kink position in the peakinfo graph
	variable size_kink = dimsize(kink_indices, 0)
	make /O /N=(size_kink) kink_chisq = all_chisq[kink_indices[p]]
	make /O /N=(size_kink) kink_energy = pnt2x(all_chisq, kink_indices[p])
	make /O /N=(size_kink) kink_x = peakinfo_display(kink_energy[p])
	
	print "Kink energy: ", kink_energy[0]
	appendtograph kink_energy vs kink_x
 	ModifyGraph mode(kink_energy)=3,marker(kink_energy)=19,rgb(kink_energy)=(nodecolor[0], nodecolor[1], nodecolor[2])
 	Setaxis left -0.0378, 0.005
// 	setaxis bottom -.1, 0
 	ModifyGraph grid(left)=1,nticks(left)=4,gridStyle(left)=4,gridRGB(left)=(43690,43690,43690)
 	Label left "\\$WMTEX$ E_b \\ (m \\$/WMTEX$eV)"
   Label bottom labelbottom
 	
 	// displaying best fits
 	variable size_center = dimsize(center_indices, 0)
 	make /O /N=(size_center) center_chisq = all_chisq[center_indices[p]]
	make /O /N=(size_center) center_energy = pnt2x(all_chisq, center_indices[p])
	make /O /N=(size_center) center_x = peakinfo_display(center_energy[p])
 	
 	variable i
 	make/O /N=(size_center, 2) bestfitx, bestfitE, regionfitx, regionfitE
	print "Node: "+ num2str(node) + ", type: " + labelbottom[0] + ". Center energy, slope, std-dev"
	
 	for (i = 0; i < size_center; i++) 
 		// we calculated the two endpoints for the line, so we can draw it
 		// the energy endpoints are center_cenergy pm fitwidthE
 		// the k endpoints are (if E = ak+ b) k_i = (E_i - b)/a
		bestfitE[i][0] = center_energy[i] - fitwidth_energy
		bestfitE[i][1] = center_energy[i] + fitwidth_energy
		
		variable E0 = all_coeffs[0][center_indices[i]], sl = all_coeffs[1][center_indices[i]]
		variable sldev = all_coeffs_error[1][center_indices[i]]	
			
		bestfitx[i][0] = (bestfitE[i][0] - E0) / sl	
		bestfitx[i][1] = (bestfitE[i][1] - E0) / sl
		print sl, E0
		string bestfit = "bestfit" + num2str(i)
		appendtograph bestfitE[i][]/TN=$bestfit vs bestfitx[i][]
		modifygraph rgb($bestfit)=(0,0,0)
		
		// Extending the line fit to the entire region (between the two kinks only)
		variable E1, E2
		if (i == 0)
			E1 = kink_energy[0]; E2 = 0.005; 
		elseif (i == size_center-1)
			E1 = kink_energy[i-1]; E2 = dimoffset(energies_display, 0); 
		endif
		
		
		regionfitE[i][0] = E1; regionfitE[i][1] = E2;
		regionfitx[i][0] = (regionfitE[i][0] - E0) / sl	
		regionfitx[i][1] = (regionfitE[i][1] - E0) / sl
		print sl, E0
	 	string regionfit = "regionfit" + num2str(i)
	 	if (doregionfit)
			appendtograph regionfitE[i][]/TN=$regionfit vs regionfitx[i][] 
			ModifyGraph lstyle($regionfit)=3, rgb($regionfit)=(0,0,0)
		endif
		print center_energy[i], sl, sldev
	endfor

 	// all_chisq graph
 	Display/K=1/Host=EDMVictor/N=chisq/W=(0.5, 0, 1, 1)
   AppendToGraph/VERT all_chisq_core
	appendtograph/Vert all_chisq_extra 
	modifygraph lstyle(all_chisq_extra) = 3
		
 	// Same y axis as EDM
// 	variable size_total = DimSize(EDM, 1)
// 	variable start_total = DimOffset(EDM, 1)
//	variable delta_total = DimDelta(EDM, 1)
 	Setaxis left -0.0378, 0.005
// 	if (type == 0)
//	 	setaxis bottom *, 5e-7
//	endif
//	if (type == 1)
//		setaxis bottom *, 10e-6
//	endif
 	string labelbottomchi = "\\$WMTEX$ \\chi^2 \\$/WMTEX$ (14 point fit)"
 	Label bottom labelbottomchi
 	label left ""
 	
   // display kink position in chisq graph
 	appendtograph kink_energy vs kink_chisq
	ModifyGraph mode(kink_energy)=3,marker(kink_energy)=19,rgb(kink_energy)=(nodecolor[0], nodecolor[1], nodecolor[2])
	ModifyGraph grid(left)=1,nticks(left)=4,gridStyle(left)=4,gridRGB(left)=(43690,43690,43690)
	appendtograph center_energy vs center_chisq
	ModifyGraph mode(center_energy)=3,marker(center_energy)=19, rgb(center_energy)=(0,0,0)
	end

function kink_derivative()
	duplicate /O root:FitVictor:EDM_n1 EDM
	wave Es, ks, dks, gams, dgams
	[Es, ks, dks, gams, dgams] = get_all_lor2(EDM)
	duplicate/O /R=(*, 0.005) ks, xs
	duplicate/O /R=(*, 0.005) Es, Es2
	duplicate/O /R=(*, 0.005) dks, dxs
	
	xs = ks[p] - ks(0)


	Smooth 10, xs

	variable size = dimsize(xs, 0), delta = dimdelta(xs, 0), offset = dimoffset(xs, 0)
	make /O /N=(size-1) der_xs = -delta / (xs[p+1] - xs[p])
	make /O /N=(size-1) dder_xs = delta / (xs[p+1] - xs[p]) * sqrt(dxs[p]^2 + dxs[p+1]^2)
	setscale /P x offset+delta/2, delta, der_xs
	setscale /P x offset+delta/2, delta, dder_xs
	
//	display energies_trunc vs peakcenters_trunc
//	display denergies vs dpeakcenters 	
	DoWindow/K DispVictor
	Display/N=DispVictor /K=1 /W=(300,40,1080,500)
	Display/K=1/Host=DispVictor/N=edm/W=(0, 0, 0.5, 1) Es2 vs xs;
	ModifyGraph mode=3,marker=8
	TextBox/C/N=text0/G=(65535,0,0)/A=RT "\\Z20\\F'Garamond'Node 1"
	
 	ModifyGraph grid(left)=1,nticks(left)=4,gridStyle(left)=4,gridRGB(left)=(43690,43690,43690)
	modifygraph fSize(bottom)=20, fSize(left)=20 
	modifygraph font="Garamond" 
	Label bottom "k - k\\BF\\M (m\\Z15Å \\S -1 \\M\\Z20)\\u#2"
	Label left "E - E\BF\M (meV)\\u#2"

	Display/K=1/Host=DispVictor/N=der/W=(0.5, 0, 1, 1)/VERT der_xs;
//	ModifyGraph mode=4, marker=8, zmrkSize(denergies)={denergies,*,*,1,1}
//	errorbars/W=DispVictor#der /T=0 /L=3 /RGB=(0, 65535, 0) der_xs X wave=(dder_xs, dder_xs)
	
	TextBox/C/N=text0/G=(65535,0,0)/A=RC "\\Z20\\F'Garamond'Smoothed"

	ModifyGraph grid(left)=1,nticks(left)=4,gridStyle(left)=4,gridRGB(left)=(43690,43690,43690)
	modifygraph fSize(bottom)=20, fSize(left)=20 
	modifygraph font="Garamond" 
	Label bottom "dE/dk (\\Z15Å \\Z20eV)\\u#2"
	Label left "E - E\BF\M (meV)\\u#2"
	setaxis bottom 1, 3
end

function plot_fd()
	
	make/O/N=100 fd
	setscale/I x, -37.8, 22, fd;
	fd = 1 / (1 + exp(x/1.29))
	display/k=1/VERT fd
	Label bottom "\\Z20\\F'Calibri' Fermi-Dirac distribution"
	Label left "\\Z20\\F'Calibri'Energy (meV)\\F'Calibri'\\u#2"
	modifygraph fsize(bottom)=18, fsize(left)=18
end