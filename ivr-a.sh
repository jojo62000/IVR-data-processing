# WE NEED TO PROVIDE 4 DIFFERENT INPUT PARAMETERS DURING RUN TIME  - FOR EXECUTING THE COMPLED C PROGRAM
# 1 INPUT FILE AND 3 OUTPUT FILE.
# THE INPUT FILE WILL BE OPENED IN 'READ' MODE AND THE OUTPUT FILES WILL EBE OPEENED IN 'WRITE' MODE



#FIRST, CREATE 4 VARIABLE WHICH WOULD SERVE THE PURPOSE OF PROVIDING THE PATH NAMES AND FURTHER AUTOMATION
echo "defining the directory locations for input and output files"
#input log file
ivr_input_file=/home/jojo/ivrold10000sample.txt

#output text files
ivrheaderlocation=/home/jojo/data/ivrheader.txt
ivrstatelocation=/home/jojo/data/ivrstate.txt
ivrfunctionlocation=/home/jojo/data/ivrfunction.txt

echo "Invoking the C file for log file conversion"
./ivr_conversion.out $ivr_input_file $ivrheaderlocation $ivrstatelocation $ivrfunctionlocation > ivr_conversion_log.txt
echo  "Successfully converted the IVR log file"
