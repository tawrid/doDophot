# doDophot
This project is based on original DoPHOT (https://github.com/M1TDoPHOT/DoPHOT_C).
It is to analyse and automate the astro-photometry PSF fitting images. The original project (DoPHOT_C) is modified to batch execute and generate obj_out file from large number of .fit images.

<b>Steps to follow on Mac OSX:</b>
1. In order for this project to work in your machine, you will require to install NASA's cfitsio. The reference link is https://heasarc.gsfc.nasa.gov/fitsio/. 
2. After the cfitsio is installed in your local machine, clone this repo.
3. Then go to the DoPHOT_C folder and run 'make' and then run 'make test'.
4. If all goes well, this will now generate an executable file called 'dophot' in the 'verif_data' directory. 
5. Copy the 'dophot' to top level directory where 'doDophot.sh' shell script is.
6. Execute the 'doDophot.sh'. This will generate the processed files in to the 'ProcessedData' directory. You will find the obj_out files under the relevant folder, which is named out from the orirginal .fit file name.
7. If you want to process more .fit files, just simply add those in the 'data2process' directory and then execute the 'doDophot.sh' again.

<b>Contributors:</b>

Tim Natusch

Tawrid Hyder 

