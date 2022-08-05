#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function colourise(cmin, cmax)
	variable cmin, cmax
	
	string list = tracenamelist("", ";", 5)
	
	colortab2wave rainbow
	wave M_Colors
	duplicate/o M_Colors root:rainbow
	
//	string cstring = "root:newcolors"
	string cstring = "root:rainbow"
	
	wave cwave  = $cstring
	
	variable listlen = itemsinlist(list)
	
	variable ii, p, cval
	if(cmax>cmin)
		p=(cmax-cmin)/(listlen-1)-1
	else
		p=(cmax-cmin)/(listlen-1)
	endif
	
	for(ii=0;ii<listlen;ii+=1)
		cval = cmin+p*ii
		if(cval <= 0 )
			cval = 0
		elseif(cval>=511)
			cval=511
		endif
		modifygraph rgb($stringfromlist(ii, list))=(cwave[cval][0], cwave[cval][1], cwave[cval][2])
	endfor
end