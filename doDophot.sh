#!/bin/bash

##################################################################################################################################
# doDophot.sh is a script for batch processing a set of FITS image files with Dophot. 		                                 #
#													                         #
# It implements a pipeline that sequentially passes input files to dophot.  				                         #
# Image files to be processed must be placed in the folder data2process.				                         #
# No other files should be in data2process, clear out any files that are not intended for processing.	                         #
# Results of processing are written out to the folder ProcessedData.					                         #
# A copy of dophot, pm, params_default_c and folders data2process,ProcessedData need to be in the same                           #
# folder as the script itself.										                         #
# Automatically cleans out the ProcessedData folder before processing a new batch of images.		                         #
# If dophot processing parameters need adjustment do this in the file pm in the same folder as doDophot                          #
#													                         #
# Tim Natusch	29/4/2018			Version 1.0 : written and tested on MAC OS X 10.9.5	                         #
#		28/5/2018			Version 1.1 : Added code to compute RA+DEC of objects                            #
# Tawrid Hyder	04/5/2019                       Version 1.2 : Modified the script to fix the bug in executing multiple FITS file #												#
##################################################################################################################################


#Test number of CPU and Cores for possible use in parallelising code at a later date
nCPU=$(sysctl -n hw.physicalcpu)
echo "Number of CPU = " $nCPU
nCores=$(sysctl -n hw.logicalcpu)
echo "Number of cores = " $nCores



#clean directory structure of any old files so new files requiring processing are properly identified and accounted for
rm  -rf ProcessedData/*

#Get information about files to process: numImages = no. of files in data2process folder
#ls data2process/ > DirFileList.txt 					#create an ordered list of file names from data2process input folder
find ./data2process -type f | grep .fit > DirFileList.txt
numImages=$(cat DirFileList.txt | grep .fit$ | wc -l) 				#count the number of input files to process
echo "Number of images to process = "  $numImages

# copy fresh versions of dophot and param_default files to data2process; keep a pristine copy of pm (the parameter modification file), work with pmtemp
cp pm pmtemp
cp param_default_c data2process/param_default_c
cp dophot data2process/dophot


#run a loop that calls dophot with a version of pmtemp configured for each individual file found in data2process
for i in `seq 1 "$numImages"`
do
	replace=$(head -n $i DirFileList.txt | tail -1)      		#set replace = current file name
	echo "Replace is "$replace
	relativePathName=$(echo $replace | sed 's/\.\/data2process\///g')
	echo "Relative path name is "$relativePathName
	replaceShortened=$(echo $relativePathName | cut -d'.' -f1) 		#define cut delimiter as . , grab field 1 to eliminate the extension .fits
	echo "Replace Shortened is "$replaceShortened
	folderName=$(echo $replaceShortened)
	echo "Folder name is "$folderName
	folderNameNoSlash=$(echo $folderName | sed 's/\//_/')
	echo "Folder no slash name is "$folderNameNoSlash
	fileName=$(basename $replace)
	echo "File name is "$fileName
	
	
  # mkdir ProcessedData/$replaceShortened
	mkdir -p ProcessedData/$folderName
#        echo "The replaceShortened value is " $replaceShortened
	# Create a file of Fits Header values so transformation from pixel to sky coords can be done later
	head -n 1 $replace > ProcessedData/$folderName/FH_$fileName

	echo "Index is "$i". Filename is "$replace 						#print out file names and sequence no. for confirmation of progress
	cp $replace data2process/

	#replace entries in dophot input parameter file pmtemp with relevant settings for current file
	sed -i.bak "s/.*IMAGE_IN.*/IMAGE_IN = '$fileName'/" pmtemp
	sed -i.bak "s/.*IMAGE_OUT.*/IMAGE_OUT ='image_out_$fileName'/" pmtemp
	sed -i.bak "s/.*OBJECTS_OUT.*/OBJECTS_OUT='objs_out_$fileName'/" pmtemp
	sed -i.bak "s/.*ERRORS_OUT.*/ERRORS_OUT='errors_out_$fileName'/" pmtemp
	sed -i.bak "s/.*EMP_SUBRAS_OUT.*/EMP_SUBRAS_OUT='psf_out_$fileName'/" pmtemp
	sed -i.bak "s/.*COVARS_OUT.*/COVARS_OUT='covar_out_$fileName'/" pmtemp
	sed -i.bak "s/.*LOGFILE.*/LOGFILE='log_$folderNameNoSlash_$fileName.txt'/" pmtemp

	# move modified parameter file to data2process folder and move there, i.e. do processing in data2process
	cp pmtemp data2process/pmtemp
	cd data2process
        chmod 777 ./dophot
#        ls -alt ./pmtemp
#        echo "Before run"
#        cat ./pmtemp
	# call dophot using parameter file template (pmtemp) modified for current input file
	./dophot ./pmtemp #> /dev/null  					# remove redirect >/dev/null if you want dophot output sent to screen during execution
#	pID=$(ps -A | grep -m1 dophot | awk '{print $1}')
#	echo "Current instance of dophot has pid = " $pID
#	echo "After run"
	# test for each running instance of dophot and wait for it to terminate before starting it with a new input file
	while pgrep -u root dophot > /dev/null; do sleep 0.2; done

	# jump back to working_data "top level" directory
	cd ../

#Code to map x,y in dophot output files to RA,Dec. At this stage obj_out file exists, modify it, add extra columns for RA, Dec, ... of each object

	# get image information,: exposure time, JD, JD-Helio, CCD temp, airmass, ...
	JD=$(awk '{for(i=1; i<=NF; i++) if($i~/JD/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName | tr '\n' ' ' | cut -d " " -f 1)
#	JD-HELIO=$(awk '{for(i=1; i<=NF; i++) if($i~/JD-HELIO/) print $(i+2)}' ProcessedData/$replaceShortened/FH_$replace | tr '\n' ' ' | cut -d " " -f 1)
	AIRMASS=$(awk '{for(i=1; i<=NF; i++) if($i~/AIRMASS/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)
	OBJECT=$(awk '{for(i=1; i<=NF; i++) if($i~/OBJECT/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)

	# get Fits header scaling, rotation, ... parameters
	CRPIX1=$(awk '{for(i=1; i<=NF; i++) if($i~/CRPIX1/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)
	CRPIX2=$(awk '{for(i=1; i<=NF; i++) if($i~/CRPIX2/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)
	CROTA1=$(awk '{for(i=1; i<=NF; i++) if($i~/CROTA1/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)
	CROTA2=$(awk '{for(i=1; i<=NF; i++) if($i~/CROTA2/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)
	CDELT1=$(awk '{for(i=1; i<=NF; i++) if($i~/CDELT1/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)
	CDELT2=$(awk '{for(i=1; i<=NF; i++) if($i~/CDELT2/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)
	CRVAL1=$(awk '{for(i=1; i<=NF; i++) if($i~/CRVAL1/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)
	CRVAL2=$(awk '{for(i=1; i<=NF; i++) if($i~/CRVAL2/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)
	CD11=$(awk '{for(i=1; i<=NF; i++) if($i~/CD1_1/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)
	CD12=$(awk '{for(i=1; i<=NF; i++) if($i~/CD1_2/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)
	CD21=$(awk '{for(i=1; i<=NF; i++) if($i~/CD2_1/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)
	CD22=$(awk '{for(i=1; i<=NF; i++) if($i~/CD2_2/) print $(i+2)}' ProcessedData/$folderName/FH_$fileName)



# output image information to objs_out file for use in analysis, also to screen for diagnostics/verification of progress: remove if not needed later

	echo "OBJECT = " $OBJECT
	echo "JD = " $JD
	echo "AIRMASS = " $AIRMASS

	echo "CRVAL1 = " $CRVAL1
	echo "CRVAL2 = " $CRVAL2


	#compute the sky positions RA,DEC from image pixel values
	awk -v CRVAL1="$CRVAL1" -v CRPIX1="$CRPIX1" -v CRVAL2="$CRVAL2" -v CRPIX2="$CRPIX2" -v CD11="$CD11" -v CD12="$CD12" -v CD21="$CD21" -v CD22="$CD22" -v OBJECT="$OBJECT" -v JD="$JD" -v AIRMASS="$AIRMASS" '{print CRVAL1+CD11*($3-CRPIX1)+CD21*($4-CRPIX2),CRVAL2+CD22*($3-CRPIX1)+CD22*($4-CRPIX2),OBJECT,JD,AIRMASS}' data2process/objs_out_$fileName > data2process/temp_objs_out_$fileName


	#add computed RA,DEC, ... information to dophot output file; i.e. create an "augmented" version of file
	paste data2process/objs_out_$fileName data2process/temp_objs_out_$fileName > data2process/RADECobjs_out_$fileName

	#sort augmented file by Dophot object type; type 1 = stellar objects
	sort -k2 data2process/RADECobjs_out_$fileName -o data2process/RADECobjs_out_$fileName


#rm data2process/?
mv data2process/temp* ProcessedData/$folderName/.
mv data2process/image* ProcessedData/$folderName/.
mv data2process/covar* ProcessedData/$folderName/.
mv data2process/objs* ProcessedData/$folderName/.
mv data2process/errors* ProcessedData/$folderName/.
mv data2process/psf* ProcessedData/$folderName/.
mv data2process/log* ProcessedData/$folderName/.
mv data2process/RADECobjs_out* ProcessedData/$folderName/.
mv data2process/shad_out* ProcessedData/$folderName/.

rm data2process/$fileName

psf=$(cat $folderName/objs_out_$fileName | head -n 1 | awk '{print $8}')
echo "Typical psf of Type 1 / Stellar objects = "$psf" pixels"


done # end of for loop

#Tidy up so process can be safely run again and we have a consistent structure and location for processed data
rm DirFileList.txt
rm data2process/dophot
rm pmtem*
rm data2process/pmtemp
rm data2process/param*


#Analyse processed data and generate useful output lists, graphs, ...
cd ProcessedData
echo "*****************************************************************"
echo ""
echo "Look in ProcessedData folder and subfolders for the results of processing the " $numIMages " input images"
echo ""
