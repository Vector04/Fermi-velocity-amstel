#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function display_horizontal_slice()
	
	Display;DelayUpdate
	AppendImage ::EDMS:SWE00005_5
	ModifyImage SWE00005_5 ctab= {*,*,BlueHot256,1}
	Label bottom "Angle (deg)"
	Label left "Energy"
	
	Duplicate/O root:EDMS:SWE00005_5, edm_victor

	Duplicate/O/R=()(1.87020) edm_victor, edmslice
	redimension/n=-1 edmslice
	
	display edmslice
	make/O /N=5 /D final_coeffs
	CurveFit/M=2/W=0/TBOX=(0x300) Voigt, kwCWave=final_coeffs, edmslice/D
	ModifyGraph mode(edmslice)=3,marker(edmslice)=8,useMrkStrokeRGB(edmslice)=1,mrkStrokeRGB(edmslice)=(65535,21845,0),lstyle(fit_edmslice)=2,rgb(fit_edmslice)=(32769,65535,32768)	
		
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
	variable Nenergies, eidx

	
	Nenergies = DimSize(inputwave, 1)
	make/O /N=(Nenergies) /D peakcenters
	SetScale/P x 1.835,0.000504202,"eV", peakcenters
	
	
	for (eidx=0; eidx < Nenergies; eidx+=1)
		peakcenters[eidx] = get_peakcenter(inputwave, eidx)
		
	endfor 
	return peakcenters
	
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
	return energies
end

function run()
   wave EDM
	Duplicate/O root:EDMS:SWE00005_5, EDM_Victor
	
	wave peakcenters = get_all_peakcenters(EDM_Victor)
	wave energies = get_energies(EDM_Victor)
	make_FD_dist(EDM_Victor, peakcenters, energies)
end