# doDophot
This project is based on original DoPHOT (https://github.com/M1TDoPHOT/DoPHOT_C).
It is to analyse the astro-photometry PSF fitting data. The original project is modified to automate the batch obj_out file generation.

Steps to follow on Mac OSX:
1. In order for this to work in your machine, you will require to install NASA's cfitsio. The reference link is https://heasarc.gsfc.nasa.gov/fitsio/. 
2. After the cfitsio is installed in your local machine, clone this repo in to your local machine.
3. Then go to the DoPHOT_C folder and run 'make' and then run 'make test'
4. If all goes well this will generate an executable file called 'dophot' in the 'verif_data' directory. 
5. Copy the 'dophot' to same directory where 'doDophot.sh' shell script is.
6. Execute the 'doDophot.sh'. This will generate the processed files in to the 'ProcessedData' directory. You will find the obj_out files under the relevant folder, which is named out from the orirginal .fit file name.

Contributors:

Tim Nautusch

Tawrid Hyder 

