import os
import sys
import shutil
import subprocess
import time
from pathlib import Path

def run_command(command, cwd):
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, cwd=cwd)
    if result.returncode != 0:
        print(f"Command execution failed: {' '.join(command)}")
        print('Error:', result.stderr)
        exit(1)

def codeql_database_cleanup(db_dir, cleanup_cmd):
    for folder in ['log', 'results', 'db-csharp/default/cache']:
        folder_path = os.path.join(db_dir, folder)
        if os.path.exists(folder_path):
            shutil.rmtree(folder_path)
    run_command(cleanup_cmd, cwd="/home/oopsla")
##    subprocess.run(cleanup_cmd, shell=True)

def convert_string_a_to_b(string_a):
    parts = string_a.split('","')
    for part in parts:
        if "or (filename =" in part:
            string_b = part.strip('"').replace('""', '"')
            string_b = string_b + "\n"
            return string_b

if len(sys.argv) != 2:
    sys.stderr.write("Usage: python3 inference.py <path-codeql-db>\n")
    sys.exit(1)

db_dir = sys.argv[1]

DATA_PATH = "/home/oopsla"
LIB_ANN = "/home/oopsla/docs/library-annotations.txt"
result_dir = os.path.join(DATA_PATH, "csharp-results/inference")
o_file = os.path.join(result_dir, f"{Path(db_dir).stem}-inferred-attributes.csv")
s_file = os.path.join(result_dir, f"{Path(db_dir).stem}-inference-summary.csv")
INF = "/home/oopsla/codeql-repo/csharp/ql/src/RLC-Codeql-Queries/infer.ql"

os.makedirs(result_dir, exist_ok=True)

cleanup_cmd = ["codeql", "database", "cleanup", "--mode=brutal", "--", db_dir]

cmd = ["codeql", "database", "analyze", db_dir, "--threads=8", "--ram=65536", "--no-save-cache", "--no-keep-full-cache", "--format=csv", "--output=tmp_file", INF]

print("CodeQL Database cleanup before the Inference")

codeql_database_cleanup(db_dir, cleanup_cmd)

print("Running Inference ...")

start_time = time.time()
run_command(cmd, cwd="/home/oopsla")
##subprocess.run(cmd, shell=True)
elapsed_time = time.time() - start_time
elapsed_rlc_n = f"Elapsed: {int(elapsed_time // 3600)}hrs {int((elapsed_time % 3600) // 60)}min {int(elapsed_time % 60)}sec"

with open("tmp_file", "r") as f, open("tp", "w") as w:
    for line in f:
        w.write(convert_string_a_to_b(line))

# Read the file and filter out empty lines
with open("tp", "r") as file:
    lines = file.readlines()
    non_empty_lines = [line for line in lines if line.strip()]

# Write the non-empty lines back to the file
with open(o_file, "w") as file:
    file.writelines(non_empty_lines)

os.remove("tmp_file")
os.remove("tp")

total_annotations = sum(1 for _ in open(o_file))

with open(s_file, "w") as f:
    f.write(f"Total number of annotations {total_annotations}\n")
    f.write(f"Time for a single run of Inference is {elapsed_rlc_n}\n")

print(f"Total number of annotations {total_annotations}")
print(f"Time for a single run of Inference is {elapsed_rlc_n}")
