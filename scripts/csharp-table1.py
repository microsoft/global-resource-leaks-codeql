import pandas as pd  
import os
import re
import subprocess

script_name = '/home/oopsla/scripts/inference.py'
script_name_alt = '/home/oopsla/scripts/compare-attributes.py'
db1 = '/home/oopsla/csharp-open-source-projects/codeql-databases/lucene-db'
db2 = '/home/oopsla/csharp-open-source-projects/codeql-databases/efcore-db'

print("Run Inference for Lucene.Net\n")
subprocess.call(['python3', script_name, db1])

print("\nRun Inference for EF Core\n")
subprocess.call(['python3', script_name, db2])

subprocess.call(['python3', script_name_alt, db1])
subprocess.call(['python3', script_name_alt, db2])

# Replace with your actual column headings  
column_headings = ["Benchmark", "@Owning Final Fields", "@Owning Non-Final Fields", "@Owning Parameters", "@MustCallAlias", "@Calls", "@MustCall on Class", "@Not Owning", "Total"]  

# Replace with the path to your data file  
file1 = "/home/oopsla/csharp-results/attr-compare/lucene-db-attr-cmp.txt"  
file2 = "/home/oopsla/csharp-results/attr-compare/efcore-db-attr-cmp.txt"  

data_file = "/home/oopsla/temp"

# Read the content of file1  
with open(file1, "r") as f1:  
    file1_content = f1.read()

# Read the content of file2  
with open(file2, "r") as f2:  
    file2_content = f2.read()  
            
# Replace with the path to your output file  
result_dir = "/home/oopsla/csharp-results/overall-results" 
output_file = f"{result_dir}/table1.txt"  

os.makedirs(result_dir, exist_ok=True)

# Create a new file
with open(data_file, "w") as f:  
    f.write(f"Lucene.Net, {file1_content}")  
    f.write(f"EF Core, {file2_content}")  

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