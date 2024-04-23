#!/bin/bash

source ../../defs.sh

# exp dir
exp_dir=$1
# res dir
res_dir=$2

# out file
out_file1="$res_dir/$OUT_EXP_DUP_STAT"

# reduce dup stat over all jobs sorted by job id
ls_inst_artefact "$res_dir" "$OUT_INST_PAIRWISE_DUP_STAT" |xargs -I {} awk '{print $0}' "{}" |sort -k1,1n > "$out_file1"