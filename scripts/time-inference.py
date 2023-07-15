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

def convert_string_a_to_b(string_a):
    parts = string_a.split('","')
    for part in parts:
        if "or (filename =" in part:
            string_b = part.strip('"').replace('""', '"')
            string_b = string_b + "\n"
            return string_b

if len(sys.argv) != 3:
    sys.stderr.write("Usage: python3 time-inference.py <path-codeql-db> <num-of-runs>\n")
    sys.exit(1)

db_dir = sys.argv[1]
runs = int(sys.argv[2])

DATA_PATH = "/home/oopsla"
LIB_ANN = "/home/oopsla/docs/library-annotations.txt"
result_dir = os.path.join(DATA_PATH, "csharp-results/inference")
o_file = os.path.join(result_dir, f"{Path(db_dir).stem}-inference-time.txt")
INF = "/home/oopsla/codeql-repo/csharp/ql/src/RLC-Codeql-Queries/infer.ql"

os.makedirs(result_dir, exist_ok=True)

cleanup_cmd = ["codeql", "database", "cleanup", "--mode=brutal", "--", db_dir]
cmd = ["codeql", "database", "analyze", db_dir, "--threads=8", "--no-save-cache", "--no-keep-full-cache", "--format=csv", "--output=tmp_file", INF]

total_time = 0  

for i in range(1, runs + 1):  
    print(f"CodeQL Database cleanup before Inference")

    codeql_database_cleanup(db_dir, cleanup_cmd)  

    print(f"Inference for run {i}")

    start_time = time.time()  
    run_command(cmd, cwd="/home/oopsla")
    elapsed_time = time.time() - start_time  
    total_time += elapsed_time  
    elapsed_rlc_n = f"Elapsed: {int(elapsed_time // 3600)}hrs {int((elapsed_time % 3600) // 60)}min {int(elapsed_time % 60)}sec"  

    with open(o_file, "a") as f:  
        f.write(f"Run {i}: {elapsed_time:.2f} seconds\n")  

avg_total_time = total_time / runs  

t_elapsed_rlc_n = f"{int(total_time // 3600)}hrs {int((total_time % 3600) // 60)}min {int(total_time % 60)}sec"  
avg_elapsed_rlc_n = f"{int(avg_total_time // 3600)}hrs {int((avg_total_time % 3600) // 60)}min {int(avg_total_time % 60)}sec"  

with open(o_file, "a") as f:  
    f.write(f"Total time for {runs} runs of Inference is {t_elapsed_rlc_n}\n")  
    f.write(f"Average time for {runs} runs of Inference is {avg_elapsed_rlc_n}\n")  

print(f"Total time for {runs} runs of Inference is {t_elapsed_rlc_n}")  
print(f"Average time for {runs} runs of Inference is {avg_elapsed_rlc_n}")  

os.remove("tmp_file")