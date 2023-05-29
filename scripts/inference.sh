#!/bin/bash

CODEQL_REPO=$1
l_dir=$2 
app=`basename $l_dir | cut -d. -f1`

## PATH Info

INF="$CODEQL_REPO/csharp/ql/src/infer.ql"

DATA_PATH=`pwd`/results
LIB_ANN="`pwd`/docs/library-annotations.txt"
result_dir="$DATA_PATH/inferred-attributes/$app"
o_file="$result_dir/inferred-attributes.csv"

mkdir -p $result_dir

## Prepare the CodeQL queries

cp `pwd`/src/infer.ql $INF

## Relevant variables

cleanup_cmd="codeql database cleanup --mode=brutal -- $l_dir"

## CodeQL database cleanup

codeql_database_cleanup() {
	rm -rf $l_dir/log $l_dir/results $l_dir/db-csharp/default/cache
	$cleanup_cmd
}

## Actual code

codeql_database_cleanup

cmd="codeql database analyze $l_dir --threads=8 --ram=20480 --no-save-cache --no-keep-full-cache --format=csv --output=tmp_file $INF"

SECONDS=0
$cmd
ELAPSED_RLC_N="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"

cat tmp_file | grep ^\"Inference | sed 's/^\"Inference.*recommendation\",\"//' | sed 's/)\",.*/)/' >tp
cat tmp_file | grep "^or (filename" | sed 's/)\",.*/)/' >>tp
cat tp | sed 's/\"\"/\"/g' | sort -u >$o_file
rm -rf tmp_file

rm -rf $INF

total_annotations=`cat  "$o_file" | sort -u | wc -l`

echo "Total number of annotations " $total_annotations >"$result_dir/inference-summary.csv"
echo "Time for a single run of Inference " $app " is " $ELAPSED_RLC_N >>"$result_dir/inference-summary.csv"
