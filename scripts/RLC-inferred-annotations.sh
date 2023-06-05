#!/bin/bash

CODEQL_REPO=$1
l_dir=$2
app=`basename $l_dir | cut -d. -f1`

## PATH Info

RLC="$CODEQL_REPO/csharp/ql/src/RLC.ql"
DISP="$CODEQL_REPO/csharp/ql/src/Dispose.qll"

DATA_PATH=`pwd`/results
LIB_ANN="`pwd`/docs/library-annotations.txt"
result_dir="$DATA_PATH/rlc-warnings/$app"
i_file="$DATA_PATH/inferred-attributes/$app/inferred-attributes.csv"

mkdir -p $result_dir

## Check the existence of inferred attributes

if [[ ! -f "$i_file" ]];
then
        echo "No inferred attributes available"
	echo "Run Inference first"
        exit 1
fi

## Prepare the CodeQL queries

cp `pwd`/src/RLC.ql $RLC
cp `pwd`/src/Dispose.qll $DISP

## Preparing RLC#

echo "" >>$RLC
echo "" >>$RLC
echo "predicate readAnnotation(string filename, string lineNumber, string programElementType, string programElementName, string annotation) {" >>$RLC
cat $LIB_ANN >>$RLC
cat $i_file >>$RLC
echo "}" >>$RLC

## Function for translating Linux paths to Windows paths

func_result=""

translate_paths() {
	echo $1 | sed 's/\/mnt\/c\//C:\\/' | tr '/' '\\'
}

## Relevant variables

dir="$(translate_paths "$l_dir")"
cleanup_cmd="codeql database cleanup --mode=brutal -- $dir"
query="$(translate_paths "$RLC")"
ofile="$(translate_paths "$result_dir/rlc-i-all.csv")"
filtered_file="$result_dir/f-rlc-i-all.csv"

## CodeQL database cleanup

codeql_database_cleanup() {
	rm -rf $l_dir/log $l_dir/results $l_dir/db-csharp/default/cache
	powershell.exe "$cleanup_cmd"
}

## Run RLC with inferred attributes

codeql_database_cleanup

cmd="codeql database analyze $dir --threads=8 --ram=20480 --no-save-cache --no-keep-full-cache --format=csv --output=$ofile $query"

SECONDS=0
powershell.exe "$cmd"
ELAPSED_RLC_N="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"

rm -rf $RLC
rm -rf $DISP

total_warnings=`cat  "$result_dir/rlc-i-all.csv" | sort -u | wc -l`
actual_leaks=`cat  "$result_dir/rlc-i-all.csv" | grep -v "Missing" | grep -v "Verifying" | sort -u | wc -l`

cat $result_dir/rlc-i-all.csv | cut -d, -f4- | grep "Resource Leak" >$filtered_file

echo "Total number of warnings " $total_warnings >"$result_dir/rlc-with-inference-summary.csv"
echo "Total number of resource leaks " $actual_leaks >>"$result_dir/rlc-with-inference-summary.csv"
echo "Time for a single run of RLC# with inferred annotations for " $app " is " $ELAPSED_RLC_N >>"$result_dir/rlc-with-inference-summary.csv"

echo ""
cat "$result_dir/rlc-with-inference-summary.csv"
