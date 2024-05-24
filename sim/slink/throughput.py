#!/usr/bin/env python3

from _csv import Error, __version__, writer, reader, register_dialect
from pathlib import Path
import re
import types
import csv
import os

# This program reads the simulation output csv and displays the throughput of the operations
# Run this script after running run.py

# The path of the folder where the csv files are located is defined
ROOT = Path(__file__).parent
csv_path = ROOT / "vunit_out" / "outcsv"

# To choose the design an environment variable is defined. 'mult' value by default.
DESIGN = os.environ.get("DESIGN","mult")

# Specify the csv output file according to envvar
if DESIGN == "mult":
    csv_file = csv_path / "tb_mult_wfifos_axis_throughput.csv"
elif DESIGN == "multp-wfifos":
    csv_file = csv_path / "tb_multp_wfifos_axis_throughput.csv"
elif DESIGN == "multp":
    csv_file = csv_path / "tb_multp_axis_throughput.csv"
else:
    print("The valid envvar values are: mult, multp-wfifos and multp")
    exit()

# The lists are defined
time=[]
time_num=[]
line=[]
sent=[]
received=[]

# Function to open csv and read from it
with open(csv_file, newline='') as csvfile:
    # Reading function; ',' delimeter is selected
    csv_reader = csv.reader(csvfile, delimiter=',', quotechar='|')
    # Take the first value of the fourth column (Name of vhdl file where the csv comes from)    
    name=next(csv_reader)[3]
    # Reset the csv file handle
    csvfile.seek(0)
    # Loop through the csv file 
    for row in csv_reader:
        # Filling the time/line lists with the second column (time of the operations) and the fifth column (line where the operation comes from)
        time.append(row[1])
        line.append(row[4])

# Loop for remove " fs"
for i in range(0, len(time)):
    a=time[i]
    a=a.replace(" fs","")
    time_num.append(a)

# Define the matrix with the time and lines information
matrix = [time_num,line]

# Filling the sent and the received lists
# Note that to have the line information the vu.enable_location_preprocessing() function must be in the program run.py
for k in range(0,len(line)):
    if int(matrix[1][k]) == 100: # If the time information comes from line 99 is sent information
        sent.append(matrix[0][k]) # Save the sent time information
    elif int(matrix[1][k]) == 109: # If the time information comes from line 108 is received information
        received.append(matrix[0][k]) # Save the received time information

if len(sent) != len(received):
    print("Error: the sent length is not equal to the received length")
    exit()

# Print the name of vhdl file where the csv comes from
print("---- For",name,"file ----")

# Loop for display the throughput of the operations
for z in range(0,len(received)-1):
    # Casting from string to integer
    k = int(received[z+1]) - int(received[z])
    if z == 0:
        print("The throughput is: 1/"+str(int(k/10000000))+" data per cycle")
    # Data throughput
    print("Between data",z+1,"and",z+2,"is: 1/"+str(int(k/10000000))+" data per cycle")

