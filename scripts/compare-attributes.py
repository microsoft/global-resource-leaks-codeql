import sys 
import shutil 
import os  
import re  
from pathlib import Path  
import csv  

def main():  
    if len(sys.argv) != 2:  
        print("usage: compare-attributes.py <path-of-codeql-db>", file=sys.stderr)  
        sys.exit(1)  

    app = os.path.basename(sys.argv[1])  

    DATA_PATH = "/home/oopsla"  
    m_file = f"/home/oopsla/docs/{app}-manual-attributes.csv"
    f_i_file = f"/home/oopsla/docs/{app}-field-info.csv"  
    i_file = f"/home/oopsla/csharp-results/inference/{app}-inferred-attributes.csv"  
    result_dir = f"{DATA_PATH}/csharp-results/attr-compare"  
    o_file = f"{result_dir}/{app}-attr-cmp.txt"  
    temp_dir = "/tmp/attr-compare"  

    if not os.path.isfile(m_file):  
        print("No manual annotations available")  
        sys.exit(1)  

    if not os.path.isfile(i_file):  
        print("No inferred annotations available")  
        sys.exit(1)  

    os.makedirs(result_dir, exist_ok=True)  
    os.makedirs(temp_dir, exist_ok=True)  

    def read_csv(file_path):  
        with open(file_path, "r") as f:  
            return [line.strip().split("and") for line in f.readlines()]
  
    def match_lines(file1, file2):
        file1_data = read_csv(file1)
        file2_data = read_csv(file2)
        readonly_fields = []

        for row1 in file1_data:
            str = ""
            for row2 in file2_data:
                if row1[:-1] == row2[:-1] and row2[-1] == " type = \"OnlyRead\")":
                    str = str.join("and".join(row1))
            if str != "":
                new_str = str + "\n"
                readonly_fields.append(new_str)
        return readonly_fields

    field_info_readonly = match_lines(m_file, f_i_file)

    def find_lines_with_keywords(file_path, include_keywords, exclude_keywords):  
        with open(file_path, "r") as f:  
            lines = f.readlines()  
        
        matched_lines = [line for line in lines if all(any(option in line for option in keyword_group) for keyword_group in include_keywords) and not any(keyword in line for keyword in exclude_keywords)]  
        return matched_lines 

    include_keywords = [["Owning"], ["Field\"", "Property"]]
    exclude_keywords = []
    temp_m = find_lines_with_keywords(m_file, include_keywords, exclude_keywords)
    temp_i = find_lines_with_keywords(i_file, include_keywords, exclude_keywords)

    manual_of_f = []
    manual_of_nf = []
    infer_of_f = []
    infer_of_nf = []
    
    for line in temp_m:
        if line in field_info_readonly:
            manual_of_f.append(line)
        else:
            manual_of_nf.append(line)

    for line in temp_i:
        if line in field_info_readonly:
            infer_of_f.append(line)
        else:
            infer_of_nf.append(line)

    include_keywords = [["Owning"], ["Parameter"]]
    exclude_keywords = []
    manual_op = find_lines_with_keywords(m_file, include_keywords, exclude_keywords)
    infer_op = find_lines_with_keywords(i_file, include_keywords, exclude_keywords)

    include_keywords = [["NonOwning"], ["Method"]]
    exclude_keywords = []
    manual_nom = find_lines_with_keywords(m_file, include_keywords, exclude_keywords)
    infer_nom = find_lines_with_keywords(i_file, include_keywords, exclude_keywords)

    include_keywords = [["Owning"], ["Method"]]
    exclude_keywords = ["NonOwning"]
    manual_om = find_lines_with_keywords(m_file, include_keywords, exclude_keywords)
    infer_om = find_lines_with_keywords(i_file, include_keywords, exclude_keywords)

    include_keywords = [["EnsuresCalledMethods"], ["Method"]]
    exclude_keywords = []
    manual_ecm = find_lines_with_keywords(m_file, include_keywords, exclude_keywords)
    infer_ecm = find_lines_with_keywords(i_file, include_keywords, exclude_keywords)

    include_keywords = [["CreateMustCallFor"], ["Method"]]
    exclude_keywords = []
    manual_cmc = find_lines_with_keywords(m_file, include_keywords, exclude_keywords)
    infer_cmc = find_lines_with_keywords(i_file, include_keywords, exclude_keywords)

    include_keywords = [["MustCall\""]]
    exclude_keywords = []
    manual_mce = find_lines_with_keywords(m_file, include_keywords, exclude_keywords)
    infer_mce = find_lines_with_keywords(i_file, include_keywords, exclude_keywords)

    include_keywords = [["MustCallAlias"]]
    exclude_keywords = []
    manual_mca = find_lines_with_keywords(m_file, include_keywords, exclude_keywords)
    infer_mca = find_lines_with_keywords(i_file, include_keywords, exclude_keywords)

    include_keywords = [["MustCall"]]
    exclude_keywords = ["MustCall\"", "MustCallAlias", "CreateMustCallFor"]
    manual_mc = find_lines_with_keywords(m_file, include_keywords, exclude_keywords)
    infer_mc = find_lines_with_keywords(i_file, include_keywords, exclude_keywords)

    def compare_attributes(manual, infer):  
        return sorted(set(manual).intersection(set(infer)))  

    m_i_of_f = compare_attributes(manual_of_f, infer_of_f)  
    m_i_of_nf = compare_attributes(manual_of_nf, infer_of_nf)  
    m_i_op = compare_attributes(manual_op, infer_op)  
    m_i_om = compare_attributes(manual_om, infer_om)  
    m_i_nom = compare_attributes(manual_nom, infer_nom)  
    m_i_ecm = compare_attributes(manual_ecm, infer_ecm)  
    m_i_cmc = compare_attributes(manual_cmc, infer_cmc)  
    m_i_mce = compare_attributes(manual_mce, infer_mce)  
    m_i_mca = compare_attributes(manual_mca, infer_mca)  
    m_i_mc = compare_attributes(manual_mc, infer_mc)  

    f_ofo = len(m_i_of_f)  
    nf_ofo = len(m_i_of_nf)  
    opo = len(m_i_op)  
    omo = len(m_i_om)  
    nomo = len(m_i_nom)  
    ecmo = len(m_i_ecm)  
    cmco = len(m_i_cmc)  
    mceo = len(m_i_mce)  
    mcao = len(m_i_mca)  
    mco = len(m_i_mc)  

    f_ofm = len(manual_of_f)  
    nf_ofm = len(manual_of_nf)  
    opm = len(manual_op)  
    omm = len(manual_om)  
    nomm = len(manual_nom)  
    ecmm = len(manual_ecm)  
    cmcm = len(manual_cmc)  
    mcem = len(manual_mce)  
    mcam = len(manual_mca)  
    mcm = len(manual_mc)

    total_m = f_ofm + nf_ofm + opm + mcam + ecmm + mcm + nomm  
    total_o = f_ofo + nf_ofo + opo + mcao + ecmo + mco + nomo  
      
    per = int((total_o * 100) / total_m)  
        
    with open(o_file, "w") as f:  
        f.write(f"{f_ofo}/{f_ofm}, {nf_ofo}/{nf_ofm}, {opo}/{opm}, {mcao}/{mcam}, {ecmo}/{ecmm}, {mco}/{mcm}, {nomo}/{nomm}, {per}%\n")

##    print(f"{f_ofo}/{f_ofm}, {nf_ofo}/{nf_ofm}, {opo}/{opm}, {mcao}/{mcam}, {ecmo}/{ecmm}, {mco}/{mcm}, {nomo}/{nomm}, {per}%\n")
                    
    shutil.rmtree(temp_dir)  

if __name__ == "__main__":  
    main()