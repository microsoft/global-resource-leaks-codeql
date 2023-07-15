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

# Create directories  
os.makedirs(db_dir, exist_ok=True)  

# Lucene CodeQL Database Creation  

# Cloning Lucene.Net  

print("Cloning Lucene.Net repository")
lucene_dir = os.path.join(dir_path, "csharp-open-source-projects", "lucenenet")  
run_command(["git", "clone", "https://github.com/apache/lucenenet.git"], cwd=os.path.dirname(lucene_dir))  

# Checkout specific commit  
run_command(["git", "checkout", "b5ea527c5bd125dd1db34d8b914e1a5d72e08ffa"], cwd=lucene_dir)  

# DB Creation  
print("Creating DB for Lucene.Net")
lucene_db_dir = os.path.join(db_dir, "lucene-db")
if os.path.exists(lucene_db_dir):  
    shutil.rmtree(lucene_db_dir)
run_command(["codeql", "database", "create", lucene_db_dir, "--language=csharp"], cwd=lucene_dir)  

# EF Core CodeQL Database Creation  

# Cloning EF Core  

print("Cloning EF Core repository")
efcore_dir = os.path.join(dir_path, "csharp-open-source-projects", "efcore")  
run_command(["git", "clone", "https://github.com/dotnet/efcore.git"], cwd=os.path.dirname(efcore_dir))  

# Checkout specific commit  
run_command(["git", "checkout", "df614b8c6b1dcc1caabe707ef8c887111392cdaa"], cwd=efcore_dir)  

# DB Creation  
print("Creating DB for EF Core")
efcore_db_dir = os.path.join(db_dir, "efcore-db")
if os.path.exists(efcore_db_dir):  
    shutil.rmtree(efcore_db_dir)
run_command(["codeql", "database", "create", efcore_db_dir, "--language=csharp"], cwd=efcore_dir)  