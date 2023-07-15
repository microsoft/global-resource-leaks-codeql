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

if len(sys.argv) != 3:  
    sys.stderr.write("Usage: python3 rlc.py <path-of-codeql-db> <kind-of-attr>\n")  
    sys.stderr.write("Usage: kind-of-attr: 0 for no annotations, 1 for manual annotations, 2 for inferred annotations\n")  
    sys.exit(1)  

db_dir = sys.argv[1]  
flag = int(sys.argv[2])  

if flag == 0:  
    type = "no"  
elif flag == 1:  
    type = "manual"  
elif flag == 2:  
    type = "inferred"  

DATA_PATH = "/home/oopsla"  
LIB_ANN = "/home/oopsla/docs/library-annotations.txt"  
result_dir = os.path.join(DATA_PATH, "csharp-results/rlc")  
o_file = os.path.join(result_dir, f"{Path(db_dir).stem}-raw-rlc-warnings-with-{type}-annotations.csv")  
f_file = os.path.join(result_dir, f"{Path(db_dir).stem}-rlc-warnings-with-{type}-annotations.csv")  
s_file = os.path.join(result_dir, f"{Path(db_dir).stem}-rlc-summary-with-{type}-annotations.csv")  
i_file = os.path.join(DATA_PATH, "csharp-results/inference", f"{Path(db_dir).stem}-inferred-attributes.csv")  
m_file = os.path.join("/home/oopsla/docs", f"{Path(db_dir).stem}-manual-attributes.csv")  

os.makedirs(result_dir, exist_ok=True)  

if flag == 1:  
    if not os.path.isfile(m_file):  
        print("No manual annotations available")  
        sys.exit(1)  
elif flag == 2:  
    if not os.path.isfile(i_file):  
        print("No inferred annotations available")  
        sys.exit(1)  

RLC = "/home/oopsla/codeql-repo/csharp/ql/src/RLC-Codeql-Queries/temp-RLC.ql"  
Backup_RLC = "/home/oopsla/codeql-repo/csharp/ql/src/RLC-Codeql-Queries/RLC.ql"  

shutil.copy(Backup_RLC, RLC)  

with open(RLC, "a") as f:  
    f.write("\n\n")  
    f.write("predicate readAnnotation(string filename, string lineNumber, string programElementType, string programElementName, string annotation) {\n")  
    with open(LIB_ANN, "r") as ann:  
        f.write(ann.read())  
    if flag == 1:  
        with open(m_file, "r") as m_ann:  
            f.write(m_ann.read())  
    elif flag == 2:  
        with open(i_file, "r") as inf_ann:  
            f.write(inf_ann.read())  
    f.write("}\n") 

cleanup_cmd = ["codeql", "database", "cleanup", "--mode=brutal", "--", db_dir]  

cmd = ["codeql", "database", "analyze", db_dir, "--threads=8", "--no-save-cache", "--no-keep-full-cache", "--format=csv", "--output="+o_file, RLC]  

print("CodeQL Database cleanup before the run of RLC#")

codeql_database_cleanup(db_dir, cleanup_cmd)  

print("Running RLC# ...")

start_time = time.time()  
run_command(cmd, cwd="/home/oopsla")
##subprocess.run(cmd, shell=True)  
elapsed_time = time.time() - start_time  
elapsed_rlc_n = f"Elapsed: {int(elapsed_time // 3600)}hrs {int((elapsed_time % 3600) // 60)}min {int(elapsed_time % 60)}sec"  

with open(o_file, "r") as f:  
    lines = sorted(set(f))  
    total_warnings = len(lines)  
    leaks = [line for line in lines if not ("Missing" in line or "Verifying" in line)]
    actual_leaks = len(leaks)  
              
with open(s_file, "w") as f:  
    f.write(f"Total number of warnings {total_warnings}\n")  
    f.write(f"Total number of resource leaks {actual_leaks}\n")  
    f.write(f"Time for a single run of RLC# with {type} annotations for {Path(db_dir).name} is {elapsed_rlc_n}\n")  
                          
print(f"Total number of warnings {total_warnings}")  
print(f"Total number of resource leaks {actual_leaks}")  
print(f"Time for a single run of RLC# with {type} annotations for {Path(db_dir).name} is {elapsed_rlc_n}")  
                          
with open(f_file, "w") as w:  
    for line in leaks:
        w.write(line)  

os.remove(RLC)