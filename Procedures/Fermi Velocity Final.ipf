#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3     // Use modern global access method and strict wave access.



function [variable v1, variable v2, variable v3, variable v4] get_peakcenter_and_width_lor2(wave inputwave, variable eidx)
    // Returns the k0, dk0, Gamma, dGamma
        
    make/O /N=4 /D coeffs, dcoeffs
    Duplicate/O/R=[][eidx] inputwave, edmslice
    redimension/n=-1 edmslice
    make/O W_ParamConfidenceInterval
    CurveFit/M=2 /Q lor, kwCWave=coeffs, edmslice /F={.68, 4}
    // We return x0, dx0, Gamma, dGamma = dB/2sqrt(B) (error propagation)
    variable gam = sqrt(coeffs[3])
    return [coeffs[2], W_paramConfidenceInterval[2], gam, W_paramConfidenceInterval[3]/(2 * gam)]

end


function[wave w1, wave w2, wave w3, wave w4, wave w5] get_all_lor2(wave inputwave)
    variable start, delta, size, eidx
    variable E, k, dk, gam, dgam
    
    start = DimOffset(inputwave, 1)
    delta = DimDelta(inputwave, 1)
    size = DimSize(inputwave, 1)

    // We could also make one 5 by N wave, but oke
    make/O /N=(size) /D Es, ks, dks, gams, dgams
    SetScale/P x start, delta, "eV", Es, ks, dks, gams, dgams
    Es = x
    
    for (eidx=0; eidx < size; eidx+=1)
        [k, dk, gam, dgam] = get_peakcenter_and_width_lor2(inputwave, eidx)
        ks[eidx] = k
        dks[eidx] = dk
        gams[eidx] = gam 
        dgams[eidx] = dgam 
    endfor 
    return [Es, ks, dks, gams, dgams]
end

function [wave w1, variable c1, variable c2] fit_range2(wave xs, wave dxs, variable Emin, variable Emax)
    
    make/O /D /N=2 coeffs
    make/O W_ParamConfidenceInterval
    
    CurveFit/Q line kwCWave=coeffs, xs(Emin, Emax) /I=1 /W=dxs /F={0.68, 4}
    coeffs[1] = 1 / coeffs[1]
    variable dslope = abs(1/coeffs[1]^2) * W_paramConfidenceInterval[1]
    return [coeffs, dslope, V_chisq]
    
end


function [wave w1, wave w2, wave w3] fit_all_ranges2(wave xs, wave dxs, variable fitwidthE)
        
    variable centerE
    variable dslope, chisq
    make/O /N=2 coeffs
    
    variable start = DimOffset(xs, 0), delta = DimDelta(xs, 0), size = Dimsize(xs, 0)
    variable finish = start + delta * size
    
    variable fitpts = round(fitwidthE / delta)-0.5
//  print "All coeffs size: ", size - 2 * fitpts
    make/O /N=(2, size - 2 * fitpts) /D all_coeffs
    make/O /N=(size - 2 * fitpts) /D all_dslopes, all_chisq
    
    SetScale/P x start + fitwidthE, delta, "eV", all_coeffs, all_dslopes, all_chisq
    
    for (centerE = start+fitwidthE; centerE < (finish - fitwidthE); centerE+=delta)
        [coeffs, dslope, chisq] = fit_range2(xs, dxs, centerE - fitwidthE, centerE + fitwidthE)
        variable centeridx = x2pnt(all_coeffs, centerE)
//      print centeridx
        all_coeffs[][centeridx] = coeffs[p]
        all_dslopes[centeridx] = dslope
        all_chisq[centeridx] = chisq
    endfor
    
    return [all_coeffs, all_dslopes, all_chisq] 
    
end


function test()
    setdatafolder root:FitVictor
   Duplicate/O root:FitVictor:EDM_n1 EDM

    wave Es, ks, dks, gams, dgams
    [Es, ks, dks, gams, dgams] = get_all_lor2(EDM)
    wave all_coefffs, all_dslopes, all_chisq
    [all_coefffs, all_dslopes, all_chisq] = fit_all_ranges2(ks, dks, 0.005)
    display all_chisq
end

function make_gui_m2_v2(variable node, variable type, variable doregionfit)
    // Node: 1, 3, 4. 
    // Type: 0 for peakcenters, 1 for peakwidths. 
    // Doregionfit: 1 to extend best fits accross entire region (kink2kink)
    variable switchvar = node + 10 * type // Case for both node and type
    switch(switchvar)
            case 1:
            		Duplicate/O root:FitVictor:EDM_n1 EDM
                make /O /N=2 kink_indices = {63, 31}
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
                make /O /N=1 kink_indices = {58}
                make /O /N=3 center_indices = {64, 49}
                make /O /N=3 nodecolor = {65535, 0, 0} // red
            break;
        case 13:
                Duplicate/O root:FitVictor:EDM_n3 EDM
                make /O /N=2 kink_indices = {56}
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
    
    string panelleft, panelright
    switch (node)
        case 1:
            panelleft = "a)"
            panelright = "b)"
            break
        case 3:
            panelleft = "c)"
            panelright = "d)"
            break
        case 4:
            panelleft = "e)"
            panelright = "f)"
            break
    endswitch
    
//    //fitwidth 10 pts
//    make /O /N=3 kink_indices = {57, 34}
//    make /O /N=3 center_indices = {61, 40, 14}

  //fitwidth 5 pts
    make /O /N=3 kink_indices = {66, 34}
    make /O /N=3 center_indices = {69, 52, 13}
   
    
    variable fitwidth = 5

    wave ks, dks, gams, dgams, Es

    [Es, ks, dks, gams, dgams] = get_all_lor2(EDM)
    
    variable delta = DimDelta(Es, 0)
    variable fitwidth_energy = fitwidth * delta
    print 2 * fitwidth_energy

    // xs(centre or width) display
    string labelbottom
    switch (type)
        case 0:
            Duplicate/O /R=(*, 0.005) ks, xs
            xs = ks[p] - ks(0)
            Duplicate/O /R=(*, 0.005) dks, dxs
            labelbottom = "Momentum k - k\\BF \\M"
        break;
        case 1:
            Duplicate/O /R=(*, 0.005) gams, xs
            Duplicate/O /R=(*, 0.005) dgams, dxs
            labelbottom = "peakwidth Γ"
        break;
    endswitch
    // Show some testing data
//  make/O /N=4 piecewise_test_coeff = {0.005, -1/2, -1/1.9, -0.015}
//  xs = Piecewise_Linear1(piecewise_test_coeff, x)
//  duplicate /O xs dxs
//  dxs = 0.001
//  make /O /N=3 kink_indices = {38}
//  make /O /N=3 center_indices = {48, 28}
//  make /O /N=3 nodecolor = {0, 0,65535}
        
    // Getting data for chisq graph 
    wave all_chisq, all_coeffs, all_dslopes
    [all_coeffs, all_dslopes, all_chisq] = fit_all_ranges2(xs, dxs, fitwidth_energy)
    
    duplicate /O /R=(*, -fitwidth_energy) all_chisq all_chisq_core
    duplicate /O /R=(*, -fitwidth_energy) all_coeffs all_coeffs_core
    duplicate /O /R=(-fitwidth_energy, *) all_chisq all_chisq_extra
    duplicate /O /R=(-fitwidth_energy, *) all_coeffs all_coeffs_extra
        
    // EDM / Dispersion graph
    DoWindow/K EDMVictor
    Display/N=EDMVictor /K=1 /W=(300,40,1080,500)
    Display/K=1/Host=EDMVictor/N=edm/W=(0, 0, 0.5, 1); 
//  AppendImage EDM;
//  ModifyImage edm ctab= {*,*,BlueHot256,1}
    
    
    // Es vs xs graph
    Appendtograph Es vs xs
//  errorbars/T=0 Es, X wave=(dxs, dxs)
    ModifyGraph log(bottom)=0, rgb(Es)=(nodecolor[0], nodecolor[1], nodecolor[2]), mode(Es)=3, marker(Es)=8
    TextBox/C/N=text0/G=(nodecolor[0], nodecolor[1], nodecolor[2]) "\\Z20\\F'Garamond'Node " + num2str(node) // Display node
    
    // displaying the kink position in the peakinfo graph
    variable size_kink = dimsize(kink_indices, 0)
    make /O /N=(size_kink) kink_chisq = all_chisq[kink_indices[p]]
    make /O /N=(size_kink) kink_energy = pnt2x(all_chisq, kink_indices[p])
    make /O /N=(size_kink) kink_x = xs(kink_energy[p])
    
    print "Kink energy: ", kink_energy[0]
    appendtograph kink_energy vs kink_x
    ModifyGraph mode(kink_energy)=3,marker(kink_energy)=19,rgb(kink_energy)=(nodecolor[0], nodecolor[1], nodecolor[2])
    Setaxis left -0.0378, 0.005
//  setaxis bottom -.1, 0
    ModifyGraph grid(left)=1,nticks(left)=4,gridStyle(left)=4,gridRGB(left)=(43690,43690,43690)
    modifygraph font="Garamond"
    modifygraph fSize(bottom)=20, fSize(left)=20   
    Label bottom labelbottom + " (m\\Z15Å \\S -1 \\M\\Z20)\\u#2"
    Label left "E - E\BF\M (meV)\\u#2"

   
    // displaying best fits
    variable size_center = dimsize(center_indices, 0)
    make /O /N=(size_center) center_chisq = all_chisq[center_indices[p]]
    make /O /N=(size_center) center_energy = pnt2x(all_chisq, center_indices[p])
    make /O /N=(size_center) center_x = xs(center_energy[p])
    
    variable i
    make/O /N=(size_center, 2) bestfitx, bestfitE, regionfitx, regionfitE
    print "Node: "+ num2str(node) + ", type: " + labelbottom + ". Center energy, slope, dslope"
    
    for (i = 0; i < size_center; i++) 
        // we calculated the two endpoints for the line, so we can draw it
        // the energy endpoints are center_cenergy pm fitwidthE
        // the k endpoints are (if E = ak+ b) k_i = (E_i - b)/a
        bestfitE[i][0] = center_energy[i] - fitwidth_energy
        bestfitE[i][1] = center_energy[i] + fitwidth_energy
        
        variable E0 = all_coeffs[0][center_indices[i]], sl = all_coeffs[1][center_indices[i]]
        variable sldev = all_dslopes[center_indices[i]] 
            
        bestfitx[i][0] = E0 + bestfitE[i][0] / sl   
        bestfitx[i][1] = E0 + bestfitE[i][1] / sl   
        
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
            E1 = kink_energy[i-1]; E2 = dimoffset(Es, 0); 
        endif
        
        
        regionfitE[i][0] = E1; regionfitE[i][1] = E2;
        regionfitx[i][0] = E0 + regionfitE[i][0] / sl   
        regionfitx[i][1] = E0 + regionfitE[i][1] / sl   
        string regionfit = "regionfit" + num2str(i)
        if (doregionfit)
            appendtograph regionfitE[i][]/TN=$regionfit vs regionfitx[i][] 
            ModifyGraph lstyle($regionfit)=3, rgb($regionfit)=(0,0,0)
        endif
        print center_energy[i], sl, sldev
    endfor
    // Label panel
    TextBox/C/N=text1/F=0/A=LT/E=2 "\Z20\\F'Garamond'" + panelleft

    
    
    print kink_energy

    // all_chisq graph
    Display/K=1/Host=EDMVictor/N=chisq/W=(0.5, 0, 1, 1)
   AppendToGraph/VERT all_chisq_core
    appendtograph/Vert all_chisq_extra 
    modifygraph lstyle(all_chisq_extra) = 3
        
    // Same y axis as EDM
//  variable size_total = DimSize(EDM, 1)
//  variable start_total = DimOffset(EDM, 1)
//  variable delta_total = DimDelta(EDM, 1)
    Setaxis left -0.0378, 0.005
    if (type == 0)
        setaxis bottom 0, 50
    endif
    if (type == 1)
        setaxis bottom 0, 25
    endif
    
    modifygraph fSize(bottom)=20, fSize(left)=20  
    modifygraph font="Garamond" 
    Label bottom "χ² of fit"
    Label left "\\u#2"
    
   // display kink position in chisq graph
    appendtograph kink_energy vs kink_chisq
    ModifyGraph mode(kink_energy)=3,marker(kink_energy)=19,rgb(kink_energy)=(nodecolor[0], nodecolor[1], nodecolor[2])
    ModifyGraph grid(left)=1,nticks(left)=4,gridStyle(left)=4,gridRGB(left)=(43690,43690,43690)
    appendtograph center_energy vs center_chisq
    ModifyGraph mode(center_energy)=3,marker(center_energy)=19, rgb(center_energy)=(0,0,0)
    
    // Label panel
    TextBox/C/N=text1/F=0/A=LT/E=2 "\Z20\\F'Garamond'" + panelright

    
    end
    
    
function plot_all_dispersions1()
    Duplicate/O root:CorrectedData:EDM_SWE5 EDM_n1
    Duplicate/O root:CorrectedData:EDM_SWE6 EDM_n3
    Duplicate/O root:CorrectedData:EDM_SWE7 EDM_n4
    
    
    wave peakcenters, peakwidths
    [peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM_n1)
    Duplicate/O /R=(*, 0) peakwidths peakcenters_n1_trunc
//    peakcenters_n1_trunc = peakcenters_n1_trunc[p] - peakcenters(0)
    
    [peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM_n3)
    Duplicate/O /R=(*, 0) peakwidths peakcenters_n3_trunc
//    peakcenters_n3_trunc = peakcenters_n3_trunc[p] - peakcenters(0) //+ 0.005
    
    [peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM_n4)
    Duplicate/O /R=(*, 0) peakwidths peakcenters_n4_trunc
//    peakcenters_n4_trunc = peakcenters_n4_trunc[p] - peakcenters(0) //+ 0.01
    
    display/k=1/VERT peakcenters_n1_trunc, peakcenters_n3_trunc, peakcenters_n4_trunc
    modifygraph mode(peakcenters_n1_trunc)=3, marker(peakcenters_n1_trunc)=8, mode(peakcenters_n3_trunc)=3, marker(peakcenters_n3_trunc)=8, mode(peakcenters_n4_trunc)=3, marker(peakcenters_n4_trunc)=8
    ModifyGraph rgb(peakcenters_n3_trunc)=(0,65535,0),rgb(peakcenters_n4_trunc)=(37779,5654,65535)
    ModifyGraph grid(bottom)=1,gridStyle(bottom)=4,gridRGB(bottom)=(48059,48059,48059), fsize(bottom)=24, fsize(left)=24
    ModifyGraph grid=1,gridStyle=4,gridRGB=(48059,48059,48059)
    modifygraph fSize(bottom)=20, fSize(left)=20  
    Legend/C/N=text0/J/A=RT "\\Z20\\F'Garamond'\\s(peakcenters_n1_trunc)Node 1 \r\\s(peakcenters_n3_trunc)Node 2\r\\s(peakcenters_n4_trunc)Node 3"
    modifygraph font="Garamond" 
    Label bottom "Momentum k - k\\BF \\M (m\\Z15Å \\S -1 \\M\\Z20)\\u#2"
    Label left "E - E\BF\M (meV)\\u#2"
end


function plot_all_dispersions2()
    Duplicate/O root:CorrectedData:EDM_SWE5 EDM_n1
    Duplicate/O root:CorrectedData:EDM_SWE6 EDM_n3
    Duplicate/O root:CorrectedData:EDM_SWE7 EDM_n4
    
    
    wave Es, ks, dks, gams, dgams
    [Es, ks, dks, gams, dgams] = get_all_lor2(EDM_n1)
    Duplicate/O /R=(*, 0) gams peakcenters_n1_trunc
    Duplicate/O /R=(*, 0) dgams, dks_n1
//    peakcenters_n1_trunc = peakcenters_n1_trunc[p] - ks(0)
//    print ks(0)
    
    [Es, ks, dks, gams, dgams] = get_all_lor2(EDM_n3)
    Duplicate/O /R=(*, 0) gams, peakcenters_n3_trunc
    Duplicate/O /R=(*, 0) dgams, dks_n3
//    peakcenters_n3_trunc = peakcenters_n3_trunc[p] - ks(0) 
//  print ks(0)
    
    [Es, ks, dks, gams, dgams] = get_all_lor2(EDM_n4)
    Duplicate/O /R=(*, 0) gams, peakcenters_n4_trunc
    Duplicate/O /R=(*, 0) dgams, dks_n4
//    peakcenters_n4_trunc = peakcenters_n4_trunc[p] - ks(0)
//  print ks(0)
    
    print dks_n1(-0.01)
    
    DoWindow/K DispVic
    Display/N=DispVic /K=1 /W=(300,40,1080,400)     
    Display/K=1/Host=DispVic/N=N1/W=(0, 0, 1/3, 1);
    Display/K=1/Host=DispVic/N=N3/W=(1/3, 0, 2/3, 1);
    Display/K=1/Host=DispVic/N=N4/W=(2/3, 0, 1, 1);
    
    appendtograph/VERT/W=DispVic#N1 peakcenters_n1_trunc
    appendtograph/VERT/W=DispVic#N3 peakcenters_n3_trunc
    appendtograph/VERT/W=DispVic#N4 peakcenters_n4_trunc
    
    dks_n1 = 10*dks_n1[p]
    dks_n3 = 10*dks_n3[p]
    dks_n4 = 10*dks_n4[p]
    
    errorbars/W=DispVic#N1 /T=0 peakcenters_n1_trunc, Y, wave=(dks_n1, dks_n1)
    errorbars/W=DispVic#N3 /T=0 peakcenters_n3_trunc, Y, wave=(dks_n3, dks_n3)
    errorbars/W=DispVic#N4 /T=0 peakcenters_n4_trunc, Y, wave=(dks_n4, dks_n4)

        
    modifygraph/W=DispVic#N1 mode(peakcenters_n1_trunc)=3, marker(peakcenters_n1_trunc)=8
    modifygraph/W=DispVic#N3 mode(peakcenters_n3_trunc)=3, marker(peakcenters_n3_trunc)=8
    modifygraph/W=DispVic#N4 mode(peakcenters_n4_trunc)=3, marker(peakcenters_n4_trunc)=8
    
    ModifyGraph/W=DispVic#N3 rgb(peakcenters_n3_trunc)=(0,65535,0)
    modifygraph/W=DispVic#N4 rgb(peakcenters_n4_trunc)=(37779,5654,65535)
    
    TextBox/W=DispVic#N1/N=text0/C/G=(65535,0,0)/A=RT "\\Z20\\F'Garamond'Node 1"
    TextBox/W=DispVic#N3/N=text0/C/G=(0,65535,0)/A=RT "\\Z20\\F'Garamond'Node 3"
    TextBox/W=DispVic#N4/N=text0/C/G=(37779,5654,65535)/A=RT "\\Z20\\F'Garamond'Node 4"
    
    TextBox/W=DispVic#N1/N=text1/C/F=0/A=LT/E=2 "\\Z20\\F'Garamond'a)"
	 TextBox/W=DispVic#N3/N=text1/C/F=0/A=LT/E=2 "\\Z20\\F'Garamond'b)"
	 TextBox/W=DispVic#N4/N=text1/C/F=0/A=LT/E=2 "\\Z20\\F'Garamond'c)"
    

    variable i=0;make/O /T windows={"DispVic#N1", "DispVic#N3", "DispVic#N4"}
    make/O/N=5 xticks = 0.015 + p * 0.05
    


    for (i=0; i < 3; i++)
//        setaxis/W=$windows[i] bottom 0, 0.025
		  setaxis/W=$windows[i] bottom 0.015, 0.030
        ModifyGraph/W=$windows[i] nticks(bottom)=4, grid(bottom)=1,gridStyle(bottom)=4,gridRGB(bottom)=(48059,48059,48059), fsize(bottom)=24, fsize(left)=24
        ModifyGraph/W=$windows[i] grid=1,gridStyle=4,gridRGB=(48059,48059,48059)
        modifygraph/W=$windows[i] fSize(bottom)=20, fSize(left)=20  
        modifygraph/W=$windows[i] font="Garamond" 
//        Label/W=$windows[i] bottom "k - k\\BF \\M (m\\Z15Å \\S -1 \\M\\Z20)\\u#2"
        label/W=$windows[i] bottom "Peakwidth Γ (m\\Z15Å \\S -1 \\M\\Z20)\\u#2"
        Label/W=$windows[i] left "\\u#2"
    
    endfor
    Label/W=$windows[0] left "E - E\BF\M (meV)\\u#2"

end

function lorvoigt()
	Duplicate/O root:CorrectedData:EDM_SWE5 EDM_n1
	wave peakcenters, peakwidths
	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_lor(EDM_n1)
	duplicate/O /R=(*, 0) peakcenters, ks_lor
	ks_lor = ks_lor[p] - peakcenters(0)
	
	[peakcenters, peakwidths] = get_all_peakcenters_and_widths_voigt(EDM_n1)
	duplicate/O /R=(*, 0) peakcenters, ks_voigt
	ks_voigt = ks_voigt[p] - peakcenters(0)
	
	display/k=1/VERT ks_lor, ks_voigt
	
	ModifyGraph mode(ks_voigt)=3,marker(ks_voigt)=8,rgb(ks_voigt)=(16386,65535,16385)
	ModifyGraph mode(ks_lor)=3,marker(ks_lor)=43
	
	ModifyGraph nticks(bottom)=4, grid(bottom)=1,gridStyle(bottom)=4,gridRGB(bottom)=(48059,48059,48059), fsize(bottom)=24, fsize(left)=24
   ModifyGraph grid=1,gridStyle=4,gridRGB=(48059,48059,48059)
	Legend/C/N=text0/J/A=LT/E=2 "\\Z20\\F'Garamond'\r\\s(ks_lor) Lorentzian fitting\r\\s(ks_voigt) Voigt fitting"
	modifygraph fSize(bottom)=20, fSize(left)=20, font="Garamond"  
	Label bottom "k - k\\BF \\M (m\\Z15Å \\S -1 \\M\\Z20)\\u#2"
   Label left "E - E\BF\M (meV)\\u#2"

	
	
end