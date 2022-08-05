 
Function Voigt(X,Y)
	variable X,Y

	variable/C W,U,T= cmplx(Y,-X)
	variable S =abs(X)+Y

	if( S >= 15 )								//        Region I
		W= T*0.5641896/(0.5+T*T)
	else
		if( S >= 5.5 ) 							//        Region II
			U= T*T
			W= T*(1.410474+U*0.5641896)/(0.75+U*(3+U))
		else
			if( Y >= (0.195*ABS(X)-0.176) ) 	//        Region III
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
