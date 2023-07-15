import pandas as pd  
import os
import re
import subprocess

script_name1 = '/home/oopsla/scripts/time-inference.py'
script_name2 = '/home/oopsla/scripts/time-rlc.py'
db1 = '/home/oopsla/csharp-open-source-projects/codeql-databases/lucene-db'
db2 = '/home/oopsla/csharp-open-source-projects/codeql-databases/efcore-db'

print("Run Inference for Lucene.Net for 3 runs\n")
subprocess.call(['python3', script_name1, db1, '3'])

print("\nRun Inference for EF Core for 3 runs\n")
subprocess.call(['python3', script_name1, db2, '3'])

print("\nRun RLC# with inferred annotations for Lucene.Net for 3 runs\n")
subprocess.call(['python3', script_name2, db1, '2', '3'])

print("\nRun RLC# with inferred annotations for EF Core for 3 runs\n")
subprocess.call(['python3', script_name2, db2, '2', '3'])

# Replace with your actual column headings  
column_headings = ["Benchmark", "Inference Time", "Verification Time"]  

# Replace with the path to your data file  
Lfile1 = "/home/oopsla/csharp-results/inference/lucene-db-inference-time.txt"  
Lfile2 = "/home/oopsla/csharp-results/rlc/lucene-db-rlc-with-inferred-annotations-time.txt"  

Efile1 = "/home/oopsla/csharp-results/inference/efcore-db-inference-time.txt"  
Efile2 = "/home/oopsla/csharp-results/rlc/efcore-db-rlc-with-inferred-annotations-time.txt"  

data_file = "/home/oopsla/temp"

pattern = r'Average time for 3 runs of Inference is (.*)'

# Read the file and search for the pattern For Lucene
with open(Lfile1, "r") as f:
    for line in f:
        match = re.search(pattern, line)
        if match:
            number1 = match.group(1)
            break

with open(Efile1, "r") as f:
    for line in f:
        match = re.search(pattern, line)
        if match:
            number2 = match.group(1)
            break

pattern = r'Average time for 3 runs of RLC# with inferred annotations is (.*)'

# Read the file and search for the pattern For Lucene
with open(Lfile2, "r") as f:
    for line in f:
        match = re.search(pattern, line)
        if match:
            number3 = match.group(1)
            break

with open(Efile2, "r") as f:
    for line in f:
        match = re.search(pattern, line)
        if match:
            number4 = match.group(1)
            break
           
# Create a new file
with open(data_file, "w") as f:  
    f.write(f"Lucene.Net, {number1}, {number3}\n")  
    f.write(f"EF Core, {number2}, {number4}\n")  

# Replace with the path to your output file  
result_dir = "/home/oopsla/csharp-results/overall-results" 
output_file = f"{result_dir}/table3.txt"  

os.makedirs(result_dir, exist_ok=True)

# Read the data file into a DataFrame  
data = pd.read_csv(data_file, header=None, names=column_headings)  

# Generate the table string  
table_string = data.to_string(index=False)  

# Print the table to stdout  
print("\n")
print(table_string)  
print("\n")

# Write the table to a file  
with open(output_file, "w") as f:  
    f.write(table_string)  

os.remove(data_file)