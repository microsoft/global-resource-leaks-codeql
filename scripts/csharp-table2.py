import pandas as pd  
import os
import re 
import subprocess

script_name = '/home/oopsla/scripts/rlc.py'
db1 = '/home/oopsla/csharp-open-source-projects/codeql-databases/lucene-db'
db2 = '/home/oopsla/csharp-open-source-projects/codeql-databases/efcore-db'

print("Run RLC# for Lucene.Net with no annotations\n")
subprocess.call(['python3', script_name, db1, '0'])

print("\nRun RLC# for Lucene.Net with inferred annotations\n")
subprocess.call(['python3', script_name, db1, '2'])

print("\nRun RLC# for EF Core with no annotations\n")
subprocess.call(['python3', script_name, db2, '0'])

print("\nRun RLC# for EF Core with inferred annotations\n")
subprocess.call(['python3', script_name, db2, '2'])

# Replace with your actual column headings  
column_headings = ["Benchmark", "RLC# warnings with no annotations", "RLC# warnings with inferred annotations"]  

# Replace with the path to your data file  
Lfile1 = "/home/oopsla/csharp-results/rlc/lucene-db-rlc-summary-with-no-annotations.csv"  
Lfile2 = "/home/oopsla/csharp-results/rlc/lucene-db-rlc-summary-with-inferred-annotations.csv"  
Efile1 = "/home/oopsla/csharp-results/rlc/efcore-db-rlc-summary-with-no-annotations.csv"  
Efile2 = "/home/oopsla/csharp-results/rlc/efcore-db-rlc-summary-with-inferred-annotations.csv"  

data_file="/home/oopsla/temp"

pattern = r'Total number of warnings (\d+)'  
  
# Read the file and search for the pattern For Lucene 
with open(Lfile1, "r") as f:  
    for line in f:  
        match = re.search(pattern, line)  
        if match:  
            number1 = int(match.group(1))  
            break

with open(Lfile2, "r") as f:  
    for line in f:  
        match = re.search(pattern, line)  
        if match:  
            number2 = int(match.group(1))  
            break

# Read the file and search for the pattern For EF Core

with open(Efile1, "r") as f:  
    for line in f:  
        match = re.search(pattern, line)  
        if match:  
            number3 = int(match.group(1))  
            break

with open(Efile2, "r") as f:  
    for line in f:  
        match = re.search(pattern, line)  
        if match:  
            number4 = int(match.group(1))  
            break

# Read the content of file1  
with open(data_file, "w") as f:
    f.write(f"Lucene.Net, {number1}, {number2}\n")
    f.write(f"EF Core, {number3}, {number4}\n")

# Replace with the path to your output file  
result_dir = "/home/oopsla/csharp-results/overall-results" 
output_file = f"{result_dir}/table2.txt"  

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