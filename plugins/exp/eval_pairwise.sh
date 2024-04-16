#!/bin/bash

source ../../defs.sh

# exp dir
exp_dir=$1
# res dir
res_dir=$2

# out file
out_file1="$res_dir/$OUT_EXP_DUP_STAT"
out_file2="$res_dir/sorted_dcpr.txt"

# reduce dup stat over all jobs sorted by job id
awk '{print $0}' < $(stream_inst_artefact "$exp_dir" "$OUT_INST_DUP_STAT") |sort -k1,1n > "$out_file1"
# compute DCPR for every jobs and sort them ascending
awk '{if($2>0){print $4/$2}else{print 0}}' < "$out_file1" |sort -k1,1g > "$out_file2"