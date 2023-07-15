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

if len(sys.argv) != 4:  
    sys.stderr.write("Usage: python3 time_rlc.py <path-of-codeql-db> <kind-of-attr> <num-of-runs>\n")  
    sys.stderr.write("Usage: kind-of-attr: 0 for no annotations, 1 for manual annotations, 2 for inferred annotations\n")  
    sys.exit(1)  
                                                                      
db_dir = sys.argv[1]  
flag = int(sys.argv[2])  
runs = int(sys.argv[3])  

if flag == 0:  
    type = "no"  
elif flag == 1:  
    type = "manual"  
elif flag == 2:  
    type = "inferred"  
                                                                                          
DATA_PATH = "/home/oopsla"  
LIB_ANN = "/home/oopsla/docs/library-annotations.txt"  
result_dir = os.path.join(DATA_PATH, "csharp-results/rlc")  
o_file = os.path.join(result_dir, f"{Path(db_dir).stem}-rlc-with-{type}-annotations-time.txt")  
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
        with open(m_file, "r") as man_ann:  
            f.write(man_ann.read())  
    elif flag == 2:  
        with open(i_file, "r") as inf_ann:  
            f.write(inf_ann.read())  
    f.write("}\n") 

cleanup_cmd = ["codeql", "database", "cleanup", "--mode=brutal", "--", db_dir]  

cmd = ["codeql", "database", "analyze", db_dir, "--threads=8", "--no-save-cache", "--no-keep-full-cache", "--format=csv", "--output="+o_file, RLC]  

total_time = 0  

for i in range(1, runs + 1):  
    print(f"CodeQL Database cleanup before RLC# with {type} annotations")

    codeql_database_cleanup(db_dir, cleanup_cmd)  

    print(f"RLC# with {type} annotations for run {i}")

    start_time = time.time()  
    run_command(cmd,cwd="/home/oopsla")
    elapsed_time = time.time() - start_time  
    total_time += elapsed_time  

    with open(o_file, "a") as f:  
        f.write(f"Run {i}: {elapsed_time:.2f} seconds\n")  

avg_total_time = total_time / runs

t_elapsed_rlc_n = f"{int(total_time // 3600)}hrs {int((total_time % 3600) // 60)}min {int(total_time % 60)}sec"  
avg_elapsed_rlc_n = f"{int(avg_total_time // 3600)}hrs {int((avg_total_time % 3600) // 60)}min {int(avg_total_time % 60)}sec"  

with open(o_file, "a") as f:  
    f.write(f"Total time for {runs} runs of RLC# with {type} annotations is {t_elapsed_rlc_n}\n")  
    f.write(f"Average time for {runs} runs of RLC# with {type} annotations is {avg_elapsed_rlc_n}\n")  

print(f"Total time for {runs} runs of RLC# with {type} annotations is {t_elapsed_rlc_n}")  
print(f"Average time for {runs} runs of RLC# with {type} annotations is {avg_elapsed_rlc_n}")  

os.remove(RLC)
