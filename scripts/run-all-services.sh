#!/bin/bash

HOME=""
CODEQL_REPO="$HOME/codeql-home/codeql-repo/"

set -e

## Check if it takes atleast one argument

if (( $# == 0 ))
then
        printf "%b" "Usage: ./run-all-services.sh <list-of-codeql-databases>\n" >&2
        exit 1
fi

for app in "$@"
do
	echo "Inference"
	echo ""
	./scripts/inference.sh $CODEQL_REPO $app
	echo ""
done

for app in "$@"
do
	echo "RLC#"
	echo ""
	./scripts/RLC-inferred-annotations.sh $CODEQL_REPO $app
	echo ""
done
