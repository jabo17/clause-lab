#!/bin/bash

source ../../defs.sh

# exp dir
exp_dir=$1
# res dir
res_dir=$2

# out file
# OUTPUT FORMAT: clause size, GEOMEAN(clauses with size / clauses), GEOMEAN(dup clauses with size / clauses)
out_file1="$res_dir/$OUT_EXP_CLAUSE_SIZE_STAT_GMEAN"

# Compute for each clause size the geometric mean over the normalized reports and dup (by reports)
# on the set of problem instances where at least on duplicate clause was produced for this specific clause size
awk '{
        if($3>0){print count[$1]++;log_reports_normalized[$1]=+log($2); log_dup_normalized+=log($3)}
    }
    END {for(size in count){
        print size, exp(log_reports_normalized[size]/count[size]), exp(log_dup_normalized[size]/count[size])
    }}
    ' < $(stream_inst_artefact "$exp_dir" "$OUT_INST_CLAUSE_SIZE_NORMALIZED") |sort -k1,1g > "$out_file1"
# compute DCPR for every jobs and sort them ascending
awk '{if($2>0){print $4/$2}else{print 0}}' < "$out_file1" |sort -k1,1g > "$out_file2"