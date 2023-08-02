import os  
import subprocess  
import shutil

def run_command(command, cwd):  
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, cwd=cwd)  
    if result.returncode != 0:  
        print(f"Command execution failed: {' '.join(command)}")  
        print('Error:', result.stderr)  
        exit(1)  

dir_path = "/home/oopsla"  
db_dir = os.path.join(dir_path, "csharp-open-source-projects", "codeql-databases")  

# Lucene CodeQL Database Creation  

lucene_dir = os.path.join(dir_path, "csharp-open-source-projects", "lucenenet")  

# DB Creation  
print("Creating DB for Lucene.Net")
lucene_db_dir = os.path.join(db_dir, "lucene-db")
if os.path.exists(lucene_db_dir):  
    shutil.rmtree(lucene_db_dir)
run_command(["codeql", "database", "create", lucene_db_dir, "--language=csharp"], cwd=lucene_dir)  

# EF Core CodeQL Database Creation  

efcore_dir = os.path.join(dir_path, "csharp-open-source-projects", "efcore")  

# DB Creation  
print("Creating DB for EF Core")
efcore_db_dir = os.path.join(db_dir, "efcore-db")
if os.path.exists(efcore_db_dir):  
    shutil.rmtree(efcore_db_dir)
run_command(["codeql", "database", "create", efcore_db_dir, "--language=csharp"], cwd=efcore_dir)  
