#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// basic loader for MBS deflector maps in krx format. Feel free to distribute and/or adapt.
// written in Igor 8.04
//
// Felix Baumberger, University of Geneva Aug 21, 2019
//
// Revision Nov 4, 2020:
//		- Autodetect and read 32 bit and 64 bit versions of krx files.
//		- Autodetect recent changes in krx headers.
//
// set v_3Dflag = 1 for 3D output. 0 for 2D output


Function/wave load_krx_deflector_map64(v_3Dflag)
	Variable v_3Dflag
	
	Variable refnum
	Variable Is64bit
	Variable v0, v1
	Variable n_images, image_pos, header_pos, image_sizeX, image_sizeY
	Variable ii
	Variable x0, x1, y0, y1, e0, e1
	String w_basename = "image_"
	String w_name
	
	String header = PadString("", 1200, 32)	// 1200 bytes should do it
	String header_short
	
	Open/R/F="*:.krx;" refnum
	tic()
	
	// 32 bit - 64 bit autodetect: 
	// Data is written with little-endian -> The second 32 bit word is 0 for a 64 bit file unless the file contains > 2 10^9 images, which we will exclude.
	FSetPos refNum, 4
	FBinRead/B=3/F=3 refNum, v0
	if (v0 == 0)
		Is64bit = 1
	else
		Is64bit = 0
	endif
	
	// size and position of first image:
	// pointers can be 64 bit or 32 bit integers
	// data is 32 bit / 4 byte integers
	if (Is64bit)
		FSetPos refNum, 0
		FBinRead/B=3/F=6 refNum, v1					// F=6 reads 8 byte integer
		n_images = v1/3	
		
		FSetPos refNum, 8									// second number in 64-bit file starts at byte 8
		FBinRead/B=3/F=6 refNum, image_pos			// file-position of first image
		FSetPos refNum, 16
		FBinRead/B=3/F=6 refNum, image_sizeY		// Parallel detection angle
		FSetPos refNum, 24
		FBinRead/B=3/F=6 refNum, image_sizeX		// Energy coordinate
	else
		FSetPos refNum, 0
		FBinRead/B=3/F=3 refNum, v1					//F=3 reads four bytes
		n_images = v1/3	
		
		FSetPos refNum, 4									// second number in file starts at byte 4
		FBinRead/B=3/F=3 refNum, image_pos			// file-position of first image
		FSetPos refNum, 8
		FBinRead/B=3/F=3 refNum, image_sizeY		// seems to be parallel detection angle
		FSetPos refNum, 12
		FBinRead/B=3/F=3 refNum, image_sizeX		// seems to be energy coordinate
	endif
	
	// autodetect header format and get wave scaling from first header :
	header_pos = (image_pos + image_sizeX * image_sizeY + 1) * 4			// position of first header	
	FSetPos refNum, header_pos		
	FBinRead/B=3 refNum, header
	v0 = strsearch(header, "DATA:", 0)
	header_short = header[0,v0-1]
	
	if (stringmatch(header_short,"Lines*"))			
		// new headers starting with "Lines\t..."
		e0 = NumberByKey("Start K.E.", header_short,"\t","\r\n")
		e1 = NumberByKey("End K.E.", header_short,"\t","\r\n")
		x0 = NumberByKey("ScaleMin", header_short,"\t","\r\n")		// parallel detection
		x1 = NumberByKey("ScaleMax", header_short,"\t","\r\n")
		y0 = NumberByKey("MapStartX", header_short,"\t","\r\n")		// deflector
		y1 = NumberByKey("MapEndX", header_short,"\t","\r\n")
	else																
		// old header
		e0 = NumberByKey("Start K.E.", header_short,"\t","\r\n")
		e1 = NumberByKey("End K.E.", header_short,"\t","\r\n")
		x0 = NumberByKey("XScaleMin", header_short,"\t","\r\n")		// parallel detection
		x1 = NumberByKey("XScaleMax", header_short,"\t","\r\n")
		y0 = NumberByKey("YScaleMin", header_short,"\t","\r\n")		// deflector
		y1 = NumberByKey("YScaleMax", header_short,"\t","\r\n")
	endif
	
	// make a single precision floating point cube
	// 3D option is disabled for data containing a single image
	if (v_3Dflag && n_images>1)
		Make/O/N=(image_sizeY, n_images, image_sizeX) Intensity_cube		// x=parallel detection angle, y=deflector angle, z=energy
		SetScale/I x x0, x1, "deg" Intensity_cube
		SetScale/I y y0, y1, "deg" Intensity_cube
		SetScale/I z e0, e1, "eV" Intensity_cube	
		Note/K Intensity_cube, header_short		// write last header in wavenote
	endif
	
	Make/O/I/N=(image_sizeX, image_sizeY) databuffer	// note 32 bit integer format (runs faster). Change /I to /S for single precision floating point
	
	// read data & fill the cube or write individual 2D images
	for(ii = 0;ii<n_images;ii +=1)
		
		if (Is64bit)
			FSetPos refNum, (ii*3 + 1) * 8			// pointers to image positions are at bytes 8, 32, 56,... 
			FBinRead/B=3/F=6 refNum, image_pos		// this is the image position in 32 bit integers. Position in bytes is 4 times that
		else
			FSetPos refNum, (ii*3 + 1) * 4			// pointers to image positions are at bytes 4, 16, 28,... 
			FBinRead/B=3/F=3 refNum, image_pos		// this is the image position in 32 bit integers. Position in bytes is 4 times that
		endif
		
		//	read image
		FSetPos refNum, image_pos*4					// should still be OK for 64 bit
		FBinRead/B=3/F=3 refNum, databuffer
		
		// read header into string.
		FSetPos refNum, (image_pos + image_sizeX * image_sizeY + 1) * 4	// position of the header
		FBinRead/B=3 refNum, header
		v0 = strsearch(header, "DATA:", 0)
		header_short = header[0,v0-1]
	
		// paste images in 3D wave or generate one 2D wave per image (the latter is much faster)
		if (v_3Dflag && n_images>1)				
			Intensity_cube[][ii][] = databuffer[r][p]		// Note 'inverted indices' (faster than separate MatrixTranspose). x-coordinate of databuffer is energy, y is angle. Takes ~50 ms per image (at full resolution)
		else										
			w_name = w_basename + num2str(ii)
			Duplicate/O databuffer $w_name
			//Redimension/S $w_name								// Converts to SP floating point. Is rather slow.
			SetScale/I x e0, e1, "eV" $w_name
			SetScale/I y x0, x1, "deg" $w_name
			Note/K $w_name, header_short
		endif

	endfor

	Close refnum
	KillWaves/Z databuffer
	
	toc()
	return Intensity_cube
End

//Steef Smit changed for AMSTEL 04/2021
//Loads Individual .krx EDMS, or multiple
Function/WAVE load_krx_EDM64()

	Variable v_3Dflag
	
	Variable refnum
	Variable Is64bit
	Variable v0, v1
	Variable n_images, image_pos, header_pos, image_sizeX, image_sizeY
	Variable ii
	Variable x0, x1, y0, y1, e0, e1
	String w_basename = "image_"
	String w_name
	
	String header = PadString("", 1200, 32)	// 1200 bytes should do it
	String header_short
	
	Open/R/F="*:.krx;" refnum
	tic()
	
	// 32 bit - 64 bit autodetect: 
	// Data is written with little-endian -> The second 32 bit word is 0 for a 64 bit file unless the file contains > 2 10^9 images, which we will exclude.
	FSetPos refNum, 4
	FBinRead/B=3/F=3 refNum, v0
	if (v0 == 0)
		Is64bit = 1
	else
		Is64bit = 0
	endif
	
	// size and position of first image:
	// pointers can be 64 bit or 32 bit integers
	// data is 32 bit / 4 byte integers
	if (Is64bit)
		FSetPos refNum, 0
		FBinRead/B=3/F=6 refNum, v1					// F=6 reads 8 byte integer
		n_images = v1/3	
		
		FSetPos refNum, 8									// second number in 64-bit file starts at byte 8
		FBinRead/B=3/F=6 refNum, image_pos			// file-position of first image
		FSetPos refNum, 16
		FBinRead/B=3/F=6 refNum, image_sizeY		// Parallel detection angle
		FSetPos refNum, 24
		FBinRead/B=3/F=6 refNum, image_sizeX		// Energy coordinate
	else
		FSetPos refNum, 0
		FBinRead/B=3/F=3 refNum, v1					//F=3 reads four bytes
		n_images = v1/3	
		
		FSetPos refNum, 4									// second number in file starts at byte 4
		FBinRead/B=3/F=3 refNum, image_pos			// file-position of first image
		FSetPos refNum, 8
		FBinRead/B=3/F=3 refNum, image_sizeY		// seems to be parallel detection angle
		FSetPos refNum, 12
		FBinRead/B=3/F=3 refNum, image_sizeX		// seems to be energy coordinate
	endif
	
	// autodetect header format and get wave scaling from first header :
	header_pos = (image_pos + image_sizeX * image_sizeY + 1) * 4			// position of first header	
	FSetPos refNum, header_pos		
	FBinRead/B=3 refNum, header
	v0 = strsearch(header, "DATA:", 0)
	header_short = header[0,v0-1]
	
	if (stringmatch(header_short,"Lines*"))			
		// new headers starting with "Lines\t..."
		e0 = NumberByKey("Start K.E.", header_short,"\t","\r\n")
		e1 = NumberByKey("End K.E.", header_short,"\t","\r\n")
		x0 = NumberByKey("ScaleMin", header_short,"\t","\r\n")		// parallel detection
		x1 = NumberByKey("ScaleMax", header_short,"\t","\r\n")
		y0 = NumberByKey("MapStartX", header_short,"\t","\r\n")		// deflector
		y1 = NumberByKey("MapEndX", header_short,"\t","\r\n")
	else																
		// old header
		e0 = NumberByKey("Start K.E.", header_short,"\t","\r\n")
		e1 = NumberByKey("End K.E.", header_short,"\t","\r\n")
		x0 = NumberByKey("XScaleMin", header_short,"\t","\r\n")		// parallel detection
		x1 = NumberByKey("XScaleMax", header_short,"\t","\r\n")
		y0 = NumberByKey("YScaleMin", header_short,"\t","\r\n")		// deflector
		y1 = NumberByKey("YScaleMax", header_short,"\t","\r\n")
	endif
	
	//Added SS_2021
	string filename = StringByKey("Gen. Name", header,"\t","\r\n")
	String fname = replacestring(".krx", filename,"")
	//
	
	Make/O/I/N=(image_sizeX, image_sizeY) databuffer	// note 32 bit integer format (runs faster). Change /I to /S for single precision floating point
	
	// read data & fill the cube or write individual 2D images
	for(ii = 0;ii<n_images;ii +=1)
		
		if (Is64bit)
			FSetPos refNum, (ii*3 + 1) * 8			// pointers to image positions are at bytes 8, 32, 56,... 
			FBinRead/B=3/F=6 refNum, image_pos		// this is the image position in 32 bit integers. Position in bytes is 4 times that
		else
			FSetPos refNum, (ii*3 + 1) * 4			// pointers to image positions are at bytes 4, 16, 28,... 
			FBinRead/B=3/F=3 refNum, image_pos		// this is the image position in 32 bit integers. Position in bytes is 4 times that
		endif
		
		//	read image
		FSetPos refNum, image_pos*4					// should still be OK for 64 bit
		FBinRead/B=3/F=3 refNum, databuffer
		
		// read header into string.
		FSetPos refNum, (image_pos + image_sizeX * image_sizeY + 1) * 4	// position of the header
		FBinRead/B=3 refNum, header
		v0 = strsearch(header, "DATA:", 0)
		header_short = header[0,v0-1]
	
		// paste images in 3D wave or generate one 2D wave per image (the latter is much faster)

			w_name = w_basename + num2str(ii)
			Duplicate/O databuffer $w_name
			//Redimension/S $w_name								// Converts to SP floating point. Is rather slow.
			SetScale/I x e0, e1, "eV" $w_name
			SetScale/I y x0, x1, "deg" $w_name
			Note/K $w_name, header_short
	endfor
	
	Matrixtranspose $w_name
	rename $w_name , $fname
	Close refnum
	KillWaves/Z databuffer
	
	toc()
End

function/S LoadManyKrx64()
    String message = "Select one or more files"
    String outputPaths
    String fileFilters = "Data Files (*.txt,*.dat,*.csv,*.krx):.txt,.dat,.csv,.krx;"
    fileFilters += "All Files:.*;"

    Open /D /R /MULT=1 /F=fileFilters /M=message refNum
    outputPaths = S_fileName
    
    if (strlen(outputPaths) == 0)
        Print "Cancelled"
    else
        Variable numFilesSelected = ItemsInList(outputPaths, "\r")
        Variable jj
        for(jj=0; jj<numFilesSelected; jj+=1)
            String path_1 = StringFromList(jj, outputPaths, "\r")
            Printf "%d: %s\r", jj, path_1
            // Add commands here to load the actual waves.  An example command
            // is included below but you will need to modify it depending on how
            // the data you are loading is organized.
            //LoadWave/A/D/J/W/K=0/V={" "," $",0,0}/L={0,2,0,0,0} path

				Variable refnum
				Variable Is64bit
				Variable v0, v1
				Variable n_images, image_pos, header_pos, image_sizeX, image_sizeY
				Variable ii
				Variable x0, x1, y0, y1, e0, e1
				String w_basename = "image_"
				String w_name
				
				String header = PadString("", 1200, 32)	// 1200 bytes should do it
				String header_short
				
				Open/R/F="*:.krx;" refNum as path_1
				tic()
				
				// 32 bit - 64 bit autodetect: 
				// Data is written with little-endian -> The second 32 bit word is 0 for a 64 bit file unless the file contains > 2 10^9 images, which we will exclude.
				FSetPos refNum, 4
				FBinRead/B=3/F=3 refNum, v0
				if (v0 == 0)
					Is64bit = 1
				else
					Is64bit = 0
				endif
				
				// size and position of first image:
				// pointers can be 64 bit or 32 bit integers
				// data is 32 bit / 4 byte integers
				if (Is64bit)
					FSetPos refNum, 0
					FBinRead/B=3/F=6 refNum, v1					// F=6 reads 8 byte integer
					n_images = v1/3	
					
					FSetPos refNum, 8									// second number in 64-bit file starts at byte 8
					FBinRead/B=3/F=6 refNum, image_pos			// file-position of first image
					FSetPos refNum, 16
					FBinRead/B=3/F=6 refNum, image_sizeY		// Parallel detection angle
					FSetPos refNum, 24
					FBinRead/B=3/F=6 refNum, image_sizeX		// Energy coordinate
				else
					FSetPos refNum, 0
					FBinRead/B=3/F=3 refNum, v1					//F=3 reads four bytes
					n_images = v1/3	
					
					FSetPos refNum, 4									// second number in file starts at byte 4
					FBinRead/B=3/F=3 refNum, image_pos			// file-position of first image
					FSetPos refNum, 8
					FBinRead/B=3/F=3 refNum, image_sizeY		// seems to be parallel detection angle
					FSetPos refNum, 12
					FBinRead/B=3/F=3 refNum, image_sizeX		// seems to be energy coordinate
				endif
				
				// autodetect header format and get wave scaling from first header :
				header_pos = (image_pos + image_sizeX * image_sizeY + 1) * 4			// position of first header	
				FSetPos refNum, header_pos		
				FBinRead/B=3 refNum, header
				v0 = strsearch(header, "DATA:", 0)
				header_short = header[0,v0-1]
				
				if (stringmatch(header_short,"Lines*"))			
					// new headers starting with "Lines\t..."
					e0 = NumberByKey("Start K.E.", header_short,"\t","\r\n")
					e1 = NumberByKey("End K.E.", header_short,"\t","\r\n")
					x0 = NumberByKey("ScaleMin", header_short,"\t","\r\n")		// parallel detection
					x1 = NumberByKey("ScaleMax", header_short,"\t","\r\n")
					y0 = NumberByKey("MapStartX", header_short,"\t","\r\n")		// deflector
					y1 = NumberByKey("MapEndX", header_short,"\t","\r\n")
				else																
					// old header
					e0 = NumberByKey("Start K.E.", header_short,"\t","\r\n")
					e1 = NumberByKey("End K.E.", header_short,"\t","\r\n")
					x0 = NumberByKey("XScaleMin", header_short,"\t","\r\n")		// parallel detection
					x1 = NumberByKey("XScaleMax", header_short,"\t","\r\n")
					y0 = NumberByKey("YScaleMin", header_short,"\t","\r\n")		// deflector
					y1 = NumberByKey("YScaleMax", header_short,"\t","\r\n")
				endif
				
				//Added SS_2021
				string filename = StringByKey("Gen. Name", header,"\t","\r\n")
				String fname = replacestring(".krx", filename,"")
				//
				
				Make/O/I/N=(image_sizeX, image_sizeY) databuffer	// note 32 bit integer format (runs faster). Change /I to /S for single precision floating point
				
				// read data & fill the cube or write individual 2D images
				for(ii = 0;ii<n_images;ii +=1)
					
					if (Is64bit)
						FSetPos refNum, (ii*3 + 1) * 8			// pointers to image positions are at bytes 8, 32, 56,... 
						FBinRead/B=3/F=6 refNum, image_pos		// this is the image position in 32 bit integers. Position in bytes is 4 times that
					else
						FSetPos refNum, (ii*3 + 1) * 4			// pointers to image positions are at bytes 4, 16, 28,... 
						FBinRead/B=3/F=3 refNum, image_pos		// this is the image position in 32 bit integers. Position in bytes is 4 times that
					endif
					
					//	read image
					FSetPos refNum, image_pos*4					// should still be OK for 64 bit
					FBinRead/B=3/F=3 refNum, databuffer
					
					// read header into string.
					FSetPos refNum, (image_pos + image_sizeX * image_sizeY + 1) * 4	// position of the header
					FBinRead/B=3 refNum, header
					v0 = strsearch(header, "DATA:", 0)
					header_short = header[0,v0-1]
				
					// paste images in 3D wave or generate one 2D wave per image (the latter is much faster)
			
						w_name = w_basename + num2str(ii)
						Duplicate/O databuffer $w_name
						//Redimension/S $w_name								// Converts to SP floating point. Is rather slow.
						SetScale/I x e0, e1, "eV" $w_name
						SetScale/I y x0, x1, "deg" $w_name
						Note/K $w_name, header_short
				endfor
				
				Matrixtranspose $w_name
				rename $w_name , $fname
				Close refnum
				KillWaves/Z databuffer
				

				            
            

		 
				        
				        
			endfor
		endif
    
    return outputPaths      // Will be empty if user canceled

End
//



// timing functions
Function tic()
	Variable/G tictoc = startMSTimer
End
 
Function toc()
	NVAR/Z tictoc
	Variable ttTime = stopMSTimer(tictoc)
	printf "%g seconds\r", (ttTime/1e6)
	killvariables/Z tictoc
End

// Florian Heringa 
// 08/07/2020
//
// LoadedWave is a 3D wave representing data from AMSTEL
// newDF should be set to 0 if you do not want a new datafolder to be made for the slicer
//
// The function can be called standalone from the commandline or be used by choosing the
// "krx (AMSTEL)" file format from the slicer interface
Function PutInCorrectFormatForSlicer(loadedWave, newDF)

	Wave loadedWave
	Variable newDF
	
	if(!(exists("root:mapcnt") ==2))
		SetDataFolder root:
		Variable/G mapcnt = 1
		String/G maplist="\"\""
		print mapcnt
		if (Datafolderexists("root:EDMS") == 0)
			NewDataFolder root:EDMS
			Make/T/N=(0,2) root:EDMS:photonenergies
		endif
		NewDataFolder/O root:kMAPS
	endif

	if (newDF)
		// From the 3Dblock_Diamond_kspace procedure
		make_newD("krx")
	EndIf
	
	NVAR ftype 
	ftype = 4
	
	Matrixop/O loadedTrWave = transposeVol(loadedWave, 1) // output = w[p][r][q]
	Duplicate/o loadedTrWave, Int3D
	SetScale/P x, dimOffset(loadedWave, 0), dimDelta(loadedWave, 0), "Angle (polar)", Int3D
	SetScale/P z, dimOffset(loadedWave, 1), dimDelta(loadedWave, 1), "Angle (tilt)", Int3D
	SetScale/P y, dimOffset(loadedWave, 2), dimDelta(loadedWave, 2), "Energy", Int3D
	String namewave = "Int3D"
	
	plot_3DD(namewave)
End