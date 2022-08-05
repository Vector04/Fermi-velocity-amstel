#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//Swe 0000 7_5_k Node 4 (S) (long k dir)
//Swe 0000 6_5_k Node 1 (W) (short k dir)
//Swe 0000 5_5_k Node 3 (N) (long k dir)



function/wave get_energies(inputwave)
	wave inputwave
	variable start, delta, size, i
	
	start = DimOffset(inputwave, 1)
	delta = DimDelta(inputwave, 1)
	size = DimSize(inputwave, 1)
	
	make/O /N=(size) energies
	for (i = 0; i < size; i++)
		energies[i] = start + i * delta
	endfor
	
	SetScale/P x start, delta, "eV", energies
	
		
	return energies
	
end

function VoigtVictor(wave w, variable x)
	return w[0]+w[1]* Voigt(w[2]*(x-w[3]), w[4])
end


function [variable v1, variable v2, wave c1] get_peakcenter_and_width_voigt(wave inputwave, variable eidx, [wave coeffs])
	
	if (paramisdefault(coeffs)) // 1 means not specified
		make/O coeffs = {1e5, 1e6, 20, -0.05, 1}
	endif
	 
	Duplicate/O/R=[][eidx] inputwave, edmslice
	redimension/n=-1 edmslice
	
	Funcfit/M=2 VoigtVictor, kwCWave=coeffs, edmslice
	variable width_gaussian = sqrt(ln(2)) / coeffs[2]
	variable width_lorentz = coeffs[4] / (coeffs[2])
	print "Gaussian width: ", width_gaussian
	print "Lorentzian width: ", width_lorentz, "Ratio: ", (width_gaussian/width_lorentz)
	variable width_voigt = width_lorentz + sqrt(width_lorentz^2 + width_gaussian^2)  
	
	return [coeffs[3], 2 * width_voigt, coeffs]

end

function [variable v1, variable v2] get_peakcenter_and_width_lor(wave inputwave, variable eidx)
	
	make/O /N=4 /D final_coeffs
	Duplicate/O/R=[][eidx] inputwave, edmslice
	redimension/n=-1 edmslice
	
	CurveFit/M=2 /Q lor, kwCWave=final_coeffs, edmslice
	return [final_coeffs[2], sqrt(final_coeffs[3])]

end


function[wave w1, wave w2] get_all_peakcenters_and_widths_voigt(wave inputwave)
	variable start, delta, size, eidx
	variable peakcenter, peakwidth
	
	start = DimOffset(inputwave, 1)
	delta = DimDelta(inputwave, 1)
	size = DimSize(inputwave, 1)
	
	make/O /N=(size) /D peakcenters
	make/O /N=(size) /D peakwidths
	SetScale/P x start, delta, "eV", peakcenters
	SetScale/P x start, delta, "eV", peakwidths
	make/O /D /N=5 coeffs={1e5, 1e6, 20, -0.05, 1}
	
	for (eidx=0; eidx < size; eidx+=1)
		[peakcenter, peakwidth, coeffs] = get_peakcenter_and_width_voigt(inputwave, eidx, coeffs=coeffs)
		peakcenters[eidx] = peakcenter
		peakwidths[eidx] = peakwidth
	endfor 
	return [peakcenters, peakwidths]
end


function[wave w1, wave w2] get_all_peakcenters_and_widths_lor(wave inputwave)
	variable start, delta, size, eidx
	variable peakcenter, peakwidth
	
	start = DimOffset(inputwave, 1)
	delta = DimDelta(inputwave, 1)
	size = DimSize(inputwave, 1)
	
	make/O /N=(size) /D peakcenters
	make/O /N=(size) /D peakwidths
	SetScale/P x start, delta, "eV", peakcenters
	SetScale/P x start, delta, "eV", peakwidths
	
	for (eidx=0; eidx < size; eidx+=1)
		[peakcenter, peakwidth] = get_peakcenter_and_width_lor(inputwave, eidx)
		peakcenters[eidx] = peakcenter
		peakwidths[eidx] = peakwidth
	endfor 
	return [peakcenters, peakwidths]
end

function [wave c1, wave c2, variable c3] fit_range_of_peakcenters(wave peakcenters_trunc, wave energies_trunc, variable Emin, variable Emax)
	
	make/O /D /N=2 coeffs
	make/O /D /N=2 coeffs_error
	CurveFit/Q line kwCWave=coeffs, energies_trunc[Emin, Emax] /X=peakcenters_trunc
	coeffs_error[0] = V_siga
	coeffs_error[1] = V_sigb
	return [coeffs, coeffs_error, V_chisq]
	
end

function/wave fit_all_ranges_with_centerpeakcenters1(wave peakcenters_trunc, wave energies_trunc, int centeridx, int maxwidth)
	
	variable width
	variable chisq
	make/O /N=2 coeffs
	make/O /N=2 coeffs_error
	variable start = DimOffset(peakcenters_trunc, 0)
	variable delta = DimDelta(peakcenters_trunc, 0)
	variable size = Dimsize(peakcenters_trunc, 0)
	
	make/O /N=(2, 2 * maxwidth+1) /D all_coeffs = 0
	make/O /N=(2 * maxwidth+1) all_chisq = 0
	SetScale/P x start + (centeridx - maxwidth) * delta, delta, "eV", all_coeffs
	SetScale/P x start + (centeridx - maxwidth) * delta, delta, "eV", all_chisq
	
	
	for (width = 3; width <= maxwidth; width++)
		[coeffs, coeffs_error, chisq] = fit_range_of_peakcenters(peakcenters_trunc, energies_trunc, centeridx - width, centeridx + width)
		all_coeffs[][maxwidth - width] = coeffs[p]
		all_coeffs[][maxwidth + width] = coeffs[p]
		all_chisq[maxwidth - width] = chisq
		all_chisq[maxwidth + width] = chisq
	endfor
	
	return all_chisq
end	
		
function [wave w1, wave w2, wave w3] fit_all_ranges_with_centerpeakcenters2(wave peakcenters_trunc, wave energies_trunc, variable width)
		
	variable centeridx
	variable chisq
	make/O /N=2 coeffs
	make/O /N=2 coeffs_error
	
	variable start = DimOffset(peakcenters_trunc, 0)
	variable delta = DimDelta(peakcenters_trunc, 0)
	variable size = Dimsize(peakcenters_trunc, 0)
	
	make/O /N=(2, size - 2 * width) /D all_coeffs
	make/O /N=(2, size - 2 * width) /D all_coeffs_error
	make/O /N=(size - 2 * width) all_chisq
	SetScale/P x start + width * delta, delta,"eV", all_coeffs
	SetScale/P x start + width * delta, delta,"eV", all_coeffs_error
	SetScale/P x start + width * delta, delta,"eV", all_chisq
	
	for (centeridx = width; centeridx < (size - width); centeridx++)
		[coeffs, coeffs_error, chisq] = fit_range_of_peakcenters(peakcenters_trunc, energies_trunc, centeridx - width, centeridx + width)
		all_coeffs[][centeridx - width] = coeffs[p]
		all_coeffs_error[][centeridx - width] = coeffs_error[p]
		all_chisq[centeridx - width] = chisq
	endfor
	
	return [all_chisq, all_coeffs, all_coeffs_error]	
	
end

function make_gui_kink_method1()

	Duplicate/O root:FitVictor:EDM_n1 EDM

	wave peakcenters, peakwidths

	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_voigt(EDM)
	wave energies = get_energies(EDM)

	Duplicate/O /R=(*, 0.000) peakcenters peakcenters_trunc
	Duplicate/O /R=(*, 0.000) peakwidths peakwidths_trunc
	Duplicate/O /R=(*, 0.000) energies energies_trunc
	
	variable size = dimsize(energies_trunc, 0)
	variable delta = dimdelta(energies_trunc, 0)
	
	
	make/O /N=(3, (size / 6) -2) all_chisq_all
	
	wave all_chisq = fit_all_ranges_with_centerpeakcenters1(peakcenters_trunc, energies_trunc, 5 * size / 6, size / 4)
	duplicate/O /R=(*, 0) all_chisq all_chisq1
	//display/k=1 all_chisq1
	wave all_chisq = fit_all_ranges_with_centerpeakcenters1(peakcenters_trunc, energies_trunc, 3 * size / 6, size / 4)
	duplicate/O all_chisq all_chisq2
	//appendtograph all_chisq2
	wave all_chisq = fit_all_ranges_with_centerpeakcenters1(peakcenters_trunc, energies_trunc, 1 * size / 6, size / 4)
	duplicate/O all_chisq all_chisq3
	//appendtograph all_chisq3
	
	make/O /N=3 centerpoints_chi = 0
	make/O /N=3 centerpoints_edm = peakcenters_trunc[(1 + 2 * p) * size / 6]
	setscale/P x pnt2x(energies_trunc, size/6), size * delta / 3, centerpoints_chi
	setscale/P x pnt2x(energies_trunc, size/6), size * delta / 3, centerpoints_edm

	
	DoWindow/K EDMVictor
	Display/N=EDMVictor /K=1 /W=(300,40,1080,600);   
	Display/K=1/Host=EDMVictor/N=edm/W=(0, 0, 0.4, 0.6)
//   appendimage EDM;
//	ModifyImage edm ctab= {*,*,BlueHot256,1}
	appendtograph energies_trunc vs peakcenters_trunc;
	setaxis bottom -0.12, 0
	setaxis left -0.0378, 0.000
	
	
	ModifyGraph rgb(energies_trunc)=(32769,65535,32768)
	appendtograph/VERT centerpoints_edm
	ModifyGraph mode(centerpoints_edm)=3,marker(centerpoints_edm)=19,rgb(centerpoints_edm)=(0,65535,0)

 	
 	Display/K=1/Host=EDMVictor/N=chisq/W=(0.4, 0, 0.8, 0.6)
 	appendtograph /VERT all_chisq1, all_chisq2, all_chisq3, centerpoints_chi
 	ModifyGraph mode(centerpoints_chi)=3,marker(centerpoints_chi)=19,rgb(centerpoints_chi)=(0,65535,0)
 	variable size_total = DimSize(EDM, 1)
 	variable start_total = DimOffset(EDM, 1)
	variable delta_total = DimDelta(EDM, 1)
 	Setaxis left -0.0378, 0.000
 	setaxis bottom 0, *
 	string labelbottom = "\\$WMTEX$ \\chi^2 \\$/WMTEX$"
 	Label bottom labelbottom
 
end
	
	
function make_gui_kink_method2(variable node, variable type, variable doregionfit)
	// Node: 1, 3, 4. 
	// Type: 0 for peakcenters, 1 for peakwidths. 
	// Doregionfit: 1 to extend best fits accross entire region (kink2kink)
	variable switchvar = node + 10 * type // Case for both node and type
	switch(switchvar)
	 		case 1:
            Duplicate/O root:FitVictor:EDM_n1 EDM
				make /O /N=2 kink_indices = {59, 31}
				make /O /N=3 center_indices = {68, 37, 16}
				make /O /N=3 nodecolor = {65535, 0, 0} // red
            break;
        case 3:
            Duplicate/O root:FitVictor:EDM_n3 EDM
				make /O /N=2 kink_indices = {61, 28}
				make /O /N=3 center_indices = {67, 54, 5}
				make /O /N=3nodecolor = {0, 65535, 0} // green
            break;
        case 4:
            Duplicate/O root:FitVictor:EDM_n4 EDM
				make /O /N=3 kink_indices = {63, 34}
				make /O /N=3 center_indices = {67, 45, 19}
				make /O /N=3 nodecolor = {37779,5654,65535} // purple
            break;
        case 11:
            Duplicate/O root:FitVictor:EDM_n1 EDM
				make /O /N=1 kink_indices = {54}
				make /O /N=3 center_indices = {64, 49}
				make /O /N=3 nodecolor = {65535, 0, 0} // red
            break;
        case 13:
            Duplicate/O root:FitVictor:EDM_n3 EDM
				make /O /N=2 kink_indices = {53}
				make /O /N=3 center_indices = {60, 47}
				make /O /N=3nodecolor = {0, 65535, 0} // green
            break;
        case 14:
            Duplicate/O root:FitVictor:EDM_n4 EDM
				make /O /N=3 kink_indices = {52}
				make /O /N=3 center_indices = {61, 38}
				make /O /N=3 nodecolor = {37779,5654,65535} // purple
            break;
    endswitch
	
	variable fitwidth = 7

	wave peakcenters, peakwidths, energies_trunc

	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM)
	wave energies = get_energies(EDM)
	
	variable delta = DimDelta(energies, 0)
	variable fitwidth_energy = fitwidth * delta
	print 2 * fitwidth_energy

	// peak info (centre or width) display
	string labelbottom
	switch (type)
		case 0:
			Duplicate/O /R=(*, 0.005) peakcenters peakinfo_display, peakinfo_calc
			labelbottom = "Peakcentre"
		break;
		case 1:
			Duplicate/O /R=(*, 0.005) peakwidths peakinfo_display, peakinfo_calc
//			peakinfo_display = log(peakinfo_calc[p])
			labelbottom = "peakwidth HWHM"
		break;
	endswitch
	Duplicate/O /R=(*, 0.005) energies, energies_display
	// Show some testing data
//	make/O /N=4 piecewise_test_coeff = {0.005, -1/2, -1/1.9, -0.015}
//	peakinfo_display = Piecewise_Linear1(piecewise_test_coeff, x)
//	make /O /N=3 kink_indices = {38}
//	make /O /N=3 center_indices = {48, 28}
//	make /O /N=3 nodecolor = {0, 0,65535}
		
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
	ModifyGraph log(bottom)=0, rgb(energies_display)=(nodecolor[0], nodecolor[1], nodecolor[2]), mode(energies_display)=3, marker(energies_display)=8
	TextBox/C/N=text0/G=(nodecolor[0], nodecolor[1], nodecolor[2]) "Node " + num2str(node) // Display node
	
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
	modifygraph fSize(bottom)=20, fSize(left)=20   
	Label bottom "\\Z20\\F'Calibri'" + labelbottom + " (m\\Z16Å \\S-\\F'Calibri'1 \\M\\Z20)\\u#2"
	Label left "\\Z20\\F'Calibri'Energy (meV)\\F'Calibri'\\u#2"

   
 	
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
		string bestfit = "bestfit" + num2str(i)
		appendtograph bestfitE[i][]/TN=$bestfit vs bestfitx[i][]
		modifygraph rgb($bestfit)=(0,0,0)
		
		// Extending the line fit to the entire region (between the two kinks only)
		variable E1, E2
		if (i == 0)
			E1 = kink_energy[0]; E2 = 0.005; 
		elseif (0 < i && i < size_center-1)
			E1 = kink_energy[1]; E2 = kink_energy[0]; 
		elseif (i == size_center-1)
			E1 = kink_energy[i-1]; E2 = dimoffset(energies_display, 0); 
		endif
		
		
		regionfitE[i][0] = E1; regionfitE[i][1] = E2;
		regionfitx[i][0] = (regionfitE[i][0] - E0) / sl	
		regionfitx[i][1] = (regionfitE[i][1] - E0) / sl
	 	string regionfit = "regionfit" + num2str(i)
	 	if (doregionfit)
			appendtograph regionfitE[i][]/TN=$regionfit vs regionfitx[i][] 
			ModifyGraph lstyle($regionfit)=3, rgb($regionfit)=(0,0,0)
		endif
		print center_energy[i], sl, sldev
	endfor
	print kink_energy

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
 	if (type == 0)
	 	setaxis bottom 0, 5e-7
	endif
	if (type == 1)
		setaxis bottom 0, 10e-6
	endif

 	modifygraph fSize(bottom)=20, fSize(left)=20   
	Label bottom "\\Z20\\F'Calibri'\\$WMTEX$ \\chi^2 \\$/WMTEX$ (14 point fit)"
 	Label left "\\u#2"
 	
 	
   // display kink position in chisq graph
 	appendtograph kink_energy vs kink_chisq
	ModifyGraph mode(kink_energy)=3,marker(kink_energy)=19,rgb(kink_energy)=(nodecolor[0], nodecolor[1], nodecolor[2])
	ModifyGraph grid(left)=1,nticks(left)=4,gridStyle(left)=4,gridRGB(left)=(43690,43690,43690)
	appendtograph center_energy vs center_chisq
	ModifyGraph mode(center_energy)=3,marker(center_energy)=19, rgb(center_energy)=(0,0,0)
	
	end

function plot_all_dispersions()
	Duplicate/O root:CorrectedData:EDM_SWE5 EDM_n1
	Duplicate/O root:CorrectedData:EDM_SWE6 EDM_n3
	Duplicate/O root:CorrectedData:EDM_SWE7 EDM_n4
	
	
	wave peakcenters, peakwidths
	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM_n1)
	Duplicate/O /R=(*, 0) peakcenters peakcenters_n1_trunc
//	peakcenters_n1_trunc = peakcenters_n1_trunc[p] - peakcenters(0)
	
	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM_n3)
	Duplicate/O /R=(*, 0) peakcenters peakcenters_n3_trunc
	peakcenters_n3_trunc = peakcenters_n3_trunc[p] - peakcenters(0)
	
	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM_n4)
	Duplicate/O /R=(*, 0) peakcenters peakcenters_n4_trunc
	peakcenters_n4_trunc = peakcenters_n4_trunc[p] - peakcenters(0)
	
	display/k=1/VERT peakcenters_n1_trunc//, peakcenters_n3_trunc, peakcenters_n4_trunc
	modifygraph mode(peakcenters_n1_trunc)=3, marker(peakcenters_n1_trunc)=8
	//ModifyGraph rgb(peakcenters_n3_trunc)=(0,65535,0),rgb(peakcenters_n4_trunc)=(37779,5654,65535)
	ModifyGraph grid(bottom)=1,gridStyle(bottom)=4,gridRGB(bottom)=(48059,48059,48059), fsize(bottom)=24, fsize(left)=24
	ModifyGraph grid=1,gridStyle=4,gridRGB=(48059,48059,48059)

	Label bottom "\\Z24\\F'Calibri' Momentum (m\\Z16Å \\S-\\F'Calibri'1 \\M\\Z20)\\u#2"
	Label left "\\Z24\\F'Calibri'Energy (meV)\\F'Calibri'\\u#2"
end

function plot_width()
	Duplicate/O root:CorrectedData:EDM_SWE5 EDM_n1
	Duplicate/O root:CorrectedData:EDM_SWE6 EDM_n3
	Duplicate/O root:CorrectedData:EDM_SWE7 EDM_n4
	
	
	wave peakcenters, peakwidths
	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM_n1)
	Duplicate/O /R=(*, 0) peakwidths peakwidths_n3_trunc
	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM_n3)
	Duplicate/O /R=(*, 0) peakwidths peakwidths_n1_trunc
	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM_n4)
	Duplicate/O /R=(*, 0) peakwidths peakwidths_n4_trunc
	

	// See make_gui_method2()
	make /O /N=2 kink_indices_n1 = {31, 59}
	make /O /N=2 kink_indices_n3 = {28, 61}
	make /O /N=3 kink_indices_n4 = {34, 63}
	
	// Transfer indices to energies and widths
	duplicate /O root:FitVictor:all_chisq all_chisq
	// There seems to be something weird causing all_chisq to lose its scaling values
	setscale /P x, -0.0342706,  0.000504202, all_chisq
	
	make /O /N=2 kink_energies_n1; kink_energies_n1 = pnt2x(all_chisq, kink_indices_n1[p])
	make /O /N=2 kink_energies_n3; kink_energies_n3 = pnt2x(all_chisq, kink_indices_n3[p])
	make /O /N=2 kink_energies_n4; kink_energies_n4 = pnt2x(all_chisq, kink_indices_n4[p])
	make /O /N=2 kink_widths_n1; kink_widths_n1 = peakwidths_n1_trunc(kink_energies_n1[p])
	make /O /N=2 kink_widths_n3; kink_widths_n3 = peakwidths_n3_trunc(kink_energies_n3[p])
	make /O /N=2 kink_widths_n4; kink_widths_n4 = peakwidths_n4_trunc(kink_energies_n4[p])

	// Optional: Some smoothing
//	smooth 2, peakwidths_n3_trunc, peakwidths_n1_trunc, peakwidths_n4_trunc
	display/k=1 peakwidths_n1_trunc, peakwidths_n3_trunc, peakwidths_n4_trunc
	ModifyGraph rgb(peakwidths_n3_trunc)=(0,65535,0),rgb(peakwidths_n4_trunc)=(37779,5654,65535)
	ModifyGraph grid(bottom)=1,gridStyle(bottom)=4,gridRGB(bottom)=(48059,48059,48059)
	ModifyGraph grid=1,gridStyle=4,gridRGB=(48059,48059,48059)
	
	variable i; print "Kink energy, kink width"
	for (i = 0; i < 2; i++)
		print kink_energies_n4[i], kink_widths_n4[i]
	endfor
//	appendtograph kink_widths_n3 vs kink_energies_n3; appendtograph kink_widths_n1 vs kink_energies_n1;appendtograph kink_widths_n4 vs kink_energies_n4
//	ModifyGraph rgb(kink_widths_n3)=(65535,21845,0),rgb(kink_widths_n4)=(0,65535,0)
//	ModifyGraph mode(kink_widths_n3)=3,mode(kink_widths_n1)=3,mode(kink_widths_n4)=3;	ModifyGraph marker(kink_widths_n3)=19, marker(kink_widths_n1)=19,marker(kink_widths_n4)=19
		
//	SetAxis bottom *, 2e-7
	SetAxis left 0,*
	Legend/C/N=text0 /A=LB /J "\\s(peakwidths_n1_trunc) Node 1\r\\s(peakwidths_n3_trunc) Node 3\r\\s(peakwidths_n4_trunc) Node 4"
	
//	wave energies = get_energies(EDM)
	
end 

function make_waterfall(variable node, variable fitmethod) // 0->voigt, 1-> lor
	switch(node)
		 case 1:
            Duplicate/O root:FitVictor:EDM_n1 EDM
            break;
        case 3:
            Duplicate/O root:FitVictor:EDM_n3 EDM
            break;
        case 4:
            Duplicate/O root:FitVictor:EDM_n4 EDM
            break;
    endswitch
   
	// We plot an MDC at different energy levels in the same graph.
	variable sizek = dimsize(EDM, 0), sizeE = dimsize(EDM, 1), deltak = dimdelta(EDM, 0), deltaE = dimdelta(EDM, 1), offsetk = dimoffset(EDM, 0), offsetE = dimoffset(EDM, 1)
	variable kmax = offsetk + sizek * deltak
	variable N_falls = 8
	variable deltafalls = -offsetE / (N_falls - 1)
	
	make/O /N=(N_falls) fall_energies, peak_k, peak_I
	fall_energies = offsetE + p * deltafalls
	
	make/O /N=(N_falls, sizek) waterfall, waterfall_lor, waterfall_voigt
	setscale /p x, offsetE, deltafalls, waterfall
	setscale /P y, offsetk, deltak, waterfall
	setscale /p x, offsetE, deltafalls, waterfall_lor
	setscale /P y, offsetk, deltak, waterfall_lor
	setscale /p x, offsetE, deltafalls, waterfall_voigt
	setscale /P y, offsetk, deltak, waterfall_voigt
	waterfall = EDM(y)(x) + p * 1.5e6
	
	DoWindow/K waterfallgraph
	Display/N=waterfallgraph /K=1 /W=(300,40,1080,500)
	Display/K=1/Host=waterfallgraph/W=(0, 0, 1, 1); 
	variable i; 
	for (i = 0; i < N_falls; i++)
		string name = "E = " + num2str(1000*fall_energies[i]) + "meV"
		appendtograph waterfall[i][] /TN=$name
		modifygraph mode($name)=3, marker($name)=8
		tag /F=2 /L=0 /Z=0 /X=0 /Y=0 $name 0.9*kmax, name
		
		string legendcontent = "\\s('E = -0.0378') MDC"
		
		if (fitmethod == 1)
			make/O /N=4 /D coeffs_lor; 
			CurveFit/M=2/W=2 /Q lor, kwCWave=coeffs_lor, waterfall[i][] /D=waterfall_lor[i][]
			string name_lor = name + "lor"	
			appendtograph waterfall_lor[i][] /TN=$name_lor
			modifygraph rgb($name_lor)=(0, 65535, 0)
			legendcontent += "\r\\s('E = -0.0378lor') Lorenz Fit"
			// display peak according to fit
			peak_k[i] = coeffs_lor[2]
			peak_I[i] = waterfall_lor[i](coeffs_lor[2])	
		endif
		if (fitmethod == 0)
			make /O /N=5 /D coeffs_voigt
			CurveFit/M=2/W=2 /Q voigt, kwCWave=coeffs_voigt, waterfall[i][] /D=waterfall_voigt[i][]
			string name_voigt = name + "voigt"
			appendtograph waterfall_voigt[i][] /TN=$name_voigt
			modifygraph rgb($name_voigt)=(16385,28398,65535)
			legendcontent += "\r\\s('E = -0.0378voigt') Voigt Fit	"
			peak_k[i] = coeffs_voigt[2]
			peak_I[i] = waterfall_voigt[i](coeffs_voigt[2])	
		endif
	endfor 

//	appendtograph peak_I vs peak_k
	modifygraph rgb(peak_I) = (16385,28398,65535), mode(peak_I)=3	
	
  Legend/C/N=text8/J/A=RT legendcontent
  TextBox/C/N=text9/A=LT "Node " + num2str(node)
  Label bottom "\\Z20\\F'Calibri' Momentum (\\Z16Å \\S-\\F'Calibri'1 \\M\\Z20)\\u#2"
Label left "\\Z20\\F'Calibri'Intensity (a.u.)\\F'Calibri'\\u#2"
  
end

function plot_residuals(variable node, variable type)
	string panelleft, panelright
	switch(node)
	 		case 1:
            Duplicate/O root:FitVictor:EDM_n1 EDM
				make /O /N=3 nodecolor = {65535, 0, 0} // red
				panelleft = "a)"; panelright = "b)"
            break;
        case 3:
            Duplicate/O root:FitVictor:EDM_n3 EDM
				make /O /N=3nodecolor = {0, 65535, 0} // green
				panelleft = "c)"; panelright = "d)"
            break;
        case 4:
            Duplicate/O root:FitVictor:EDM_n4 EDM
				make /O /N=3 nodecolor = {37779,5654,65535} // purple
				panelleft = "e)"; panelright = "f)"
            break;
    endswitch
    
    variable Nfits = 21, Nresid=30
    make/O rainbow = {{65535, 0, 0}, {65535, 19660, 0}, {65535, 39321, 0}, {65535, 58981, 0}, {52427, 65535, 0}, {32767, 65535, 0}, {13107, 65535, 0}, {0, 65535, 6553}, {0, 65535, 26214}, {0, 65535, 45874}, {0, 65535, 65535}, {0, 45874, 65535}, {0, 26214, 65535}, {0, 6553, 65535}, {13106, 0, 65535}, {32767, 0, 65535}, {52428, 0, 65535}, {65535, 0, 58981}, {65535, 0, 39320}, {65535, 0, 19660}, {0,0,0}, {0,0,0}}
    
    wave ks, gams, Es, dks, dgams
	[Es, ks, dks, gams, dgams] = get_all_lor2(EDM)
	duplicate /O /R=(-0.02, 0) Es energies_trunc

	variable zoomE; string labelbottom
	switch (type)
		case 0: // dispersion
			duplicate /O /R=(-0.02, 0) ks xs
			duplicate /O /R=(-0.02, 0) dks dxs
			xs = xs[p] - ks(0)
			zoomE = -0.010
			labelbottom =  "k - k\\BF\\M (m\\Z15Å \\S -1 \\M\\Z20)\\u#2"
		break
		case 1: // widths
			duplicate /O /R=(-0.02, 0) gams xs
			duplicate /O /R=(-0.02, 0) dgams dxs
			 zoomE = -0.015
			labelbottom =  "Peakwidth Γ (m\\Z15Å \\S -1 \\M\\Z20)\\u#2"
		break
	endswitch
	
		
	// We should use the coefficients of the fit only
	variable Npoints=dimsize(xs, 0), delta=dimdelta(xs, 0)
	make/O /N=(Nfits, 2) /D all_coeffs, all_ks, all_dcoeffs
	make/O /N=2 /D coeffs
	wave W_paramConfidenceInterval
	
	// compute all coefficients
	variable i;
	for (i = 2; i < Nfits; i+=2)
		Curvefit/M=2/Q line kwcWave=coeffs xs[Npoints-i, Npoints-1] /I=1 /W=dxs[Npoints-i, Npoints-1] /F={0.68, 4}	
		all_coeffs[i][0] = coeffs[0] // y0
		all_coeffs[i][1] = 1 / coeffs[1] // slope
		all_dcoeffs[i][0] = W_paramConfidenceInterval[0]
		all_dcoeffs[i][1] = W_paramConfidenceInterval[1] / coeffs[1]^2
	endfor
	
//	i = 2 <-> 2 pnt fit <-> allcoeffs[2] en 1 mev
//	4 mev <-> 8 pnt fit <-> all_coeffs[8]
	make/O kink_energy = {0, 8, 0, 8, 6}
//	print all_coeffs[kink_energy[node]][0], " ± ", all_dcoeffs[kink_energy[node]][0]
//	print "Slope: ", all_coeffs[kink_energy[node]][1], " ± ", all_dcoeffs[kink_energy[node]][1]
	
	// compute residuals
	make/O /N=(Nfits, Nresid) all_residuals
	setscale/P y, 1.5126e-5, -delta, all_residuals
	all_residuals[][] = all_coeffs[p][0] + y / all_coeffs[p][1] - xs(y)	// p selects which fit, q selects which energy
	
	// Plotting
	DoWindow/K EDMVictor
	Display/N=EDMVictor /K=1 /W=(300,40,1080,500)
	Display/K=1/Host=EDMVictor/N=edm/W=(0, 0, 0.5, 1); 
	appendtograph/VERT xs
	ModifyGraph mode(xs)=3,marker(xs)=8, rgb(xs)=(nodecolor[0], nodecolor[1], nodecolor[2])
	
	modifygraph font="Garamond", fSize(bottom)=20, fSize(left)=20
	label bottom labelbottom
	Label left "E - E\BF\M (meV)\\u#2"
	TextBox/C/N=text0/G=(nodecolor[0], nodecolor[1], nodecolor[2]) "\\Z20\\F'Garamond'Node" + num2str(node)
	
	// Draw rectangle to indicate zoom
	variable zoomk1 = xs(0), zoomk2 = xs(zoomE)
	make/N=5 /O zoomsk = {zoomk1, zoomk1, zoomk2, zoomk2, zoomk1}, zoomsE = {0, zoomE, zoomE, 0, 0}
	appendtograph zoomsE vs zoomsk
	modifygraph rgb(zoomsE)=(0,0,0)
	TextBox/C/N=text1/F=0/A=LT/E=2 "\Z20\\F'Garamond'" + panelleft
	
	
	Display/K=1/Host=EDMVictor/N=res/W=(0.5, 0, 1, 1);
	for (i=2; i < Nfits; i+=2)
		string rn; sprintf rn, "%.0f meV", (1e3 * delta * (i)) //residual name
		appendtograph/VERT all_residuals[i][]/TN=$rn
		modifygraph rgb($rn) = (rainbow[0][i-2],rainbow[1][i-2], rainbow[2][i-2])
	endfor
	
	Legend/C/N=text0/J "\\Z20\\F'Garamond'\\s('1 meV') 1 meV\r\\s('2 meV') 2 meV\r\\s('3 meV') 3 meV\r\\s('4 meV') 4 meV\r\\s('5 meV') 5 meV\r\\s('6 meV') 6 meV\r\\s('7 meV') 7 meV\r\\s('8 meV') 8 meV\r\\s('9 meV') 9 meV\r\\s('10 meV') 10 meV "
	
//	Legend/C/N=text0/J "\\Z20\\F'Garamond'\\s('1.01 meV') 1 meV\r\\s('2.02 meV') 2 meV\r\\s('3.03 meV') 3 meV\r\\s('4.03 meV') 4 meV\r\\s('5.04 meV') 5 meV";DelayUpdate
//	AppendText/N=text0 "\\s('6.05 meV') 6 meV\r\\s('7.06 meV') 7 meV\r\\s('8.07 meV') 8 meV\r\\s('9.08 meV') 9 meV\r\\s('10.08 meV') 10 meV"

	modifygraph font="Garamond", fSize(bottom)=20, fSize(left)=20   
	
	label bottom "Residual, fit - data (Δm\\Z15Å \\S -1 \\M\\Z20)\\u#2"
   label left "E - E\BF\M (meV)\\u#2"	
   setaxis left zoomE, 0
	ModifyGraph grid(bottom)=1,gridStyle(bottom)=4,gridRGB(bottom)=(48059,48059,48059)
	ModifyGraph grid(left)=1,gridStyle(left)=4,gridRGB(left)=(48059,48059,48059)
	TextBox/C/N=text1/F=0/A=LT/E=2 "\Z20\\F'Garamond'" + panelright
//	SavePICT/E=-5/B=576 as "N" + num2str(node) + " residual v2"

end


function compare_kink_positions()
	// -0.0070437, -0.0075479, -0.0080521
	make/O peak1 = {{-4.5, -4.5}, {-3.5, -3.5}, {-2.5, -2.5}}, peak2 = {{-18.6, -18.6}, {-20.1, -20.1}, {-17.1, -17.1}}
	make/O peak3 = {{-7, -7}, {-7.5, -7.5}, {-8, -8}}
	make/O /N=2 horizontal1 = {0.1, 0.9}, horizontal2 = {1, 1.8}
	make /O /N=(3, 3) nodecolors = {{65535, 0, 0}, {0, 65535, 0}, {37779,5654,65535}}
   
	variable i;
	display/k=1;
	for (i=0; i<3; i++)
//		make/N=2/O peak1plot = {peak1[i], peak1[i]}, peak2plot = {peak2[i], peak2[i]}
		string namepeak1 = "node1" + num2str(i)
		string namepeak2 = "node2" + num2str(i)
		string namepeak3 = "node3" + num2str(i)
		appendtograph peak1[][i]/TN=$namepeak1 vs horizontal1
		modifygraph rgb($namepeak1)=(nodecolors[0][i], nodecolors[1][i],nodecolors[2][i])
		appendtograph peak2[][i]/TN=$namepeak2 vs horizontal1
		modifygraph rgb($namepeak2)=(nodecolors[0][i], nodecolors[1][i],nodecolors[2][i])
		appendtograph peak3[][i]/TN=$namepeak3 vs horizontal2
		modifygraph rgb($namepeak3)=(nodecolors[0][i], nodecolors[1][i],nodecolors[2][i])

	endfor
	ModifyGraph nticks(bottom)=0,minor(bottom)=1,standoff(bottom)=0, fSize(left)=20

	setaxis left -37.8, 0
	setaxis bottom 0, 1.9
	Legend/C/N=text1/J "\\s(node10) Node 1\r\\s(node11) Node 3\r\\s(node12) Node 4"
	Label left "\\Z20\\F'Calibri'Energy (meV)\\F'Calibri'"

	end

function run()
  
//   make_gui_kink_method1()
//	make_gui_kink_method2(1, 1, 0)
// make_gui_kink_method2(4, 1)
//	make_waterfall(3)	
//	plot_width()
	
	
	make/O /N=3 nodes = {1,3,4}
	
//	variable n, j, t
//	for (t = 0; t < 2; t++) // type (peakcentre, width)
//		for (n = 0; n < 3; n++) // node
//			for (j = 0; j < 2; j++) // doregionfit y, n
//				make_gui_kink_method2(nodes[n], 1, 0)
//				SavePICT/E=-8/EF=1
//			endfor
//		endfor
//	endfor

variable i, j
	for (i = 0; i < 3; i++)
//		for (j = 0; j < 2; j++)
			make_gui_m2_v2(nodes[i], 1, 0)
			SavePICT/E=-5/B=144
//		endfor
	endfor
end


