#!/bin/bash

#
# This plugin, called "dup_stat", evaluates duplicates over all solvers
# OUT_FILE: dup_stat
# OUT_FORMAT: instance id, cls. prod., clauses hashes, dup. clause prod, dup. clause hashes
#

# get file names
script=$0
scriptdir=$(dirname $script)

source $scriptdir/../../defs.sh

# get instance
inst_dir=$1
inst_res_dir=$2
inst_id=$(basename "$inst_dir")

# set out file
# DO NOT USE *.tmp!
out_file="$inst_res_dir/$OUT_INST_DUP_STAT"

awk '{print $2}' "$inst_dir/$PROD_SORTED_CLS_TMP" |uniq -c |awk -v "instance=$inst_id" '
        BEGIN {reports=0; hashes=0; dup_reports=0; dup_hashes=0}
        {reports+=$1; if ($1>1){dup_hashes+=1}}
        END {
            hashes=NR; dup_reports=reports-hashes
            print instance, reports, hashes, dup_reports, dup_hashes}

    ' > "$out_file"