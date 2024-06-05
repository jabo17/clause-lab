#!/bin/bash

source ../defs.sh

# exp dir
exp_dir=$1
# res dir
res_dir=$2

# out file
out_file1="$res_dir/$OUT_EXP_PAIRWISE_GMEAN_DUP_STAT"
out_file2="$res_dir/gmean_ppco_matrix.pdf"

out_file3="$res_dir/$OUT_EXP_PAIRWISE_MAX_DUP_STAT"
out_file4="$res_dir/max_ppco_matrix.pdf"

# gmean ppco
ls_inst_artefacts "$res_dir" "$OUT_INST_PAIRWISE_DUP_STAT" |xargs -I {} cat {} |
     awk '{k=$1" "$2" "$3" "$4;if($5>0 && $6>0){count[k]+=1;buckets[k]+=log($6/$5)}} END{for(k in buckets){print k, exp(buckets[k]/count[k])}}'> "$out_file1"

# max ppco
ls_inst_artefacts "$res_dir" "$OUT_INST_PAIRWISE_DUP_STAT" |xargs -I {} cat {} |
     awk '{k=$1" "$2" "$3" "$4;if($5>0 && $6>0){ppco=$6/$5;if(ppco>buckets[k]){buckets[k]=$6/$5}}} END{for(k in buckets){print k, buckets[k]}}'> "$out_file3"

processes=2
if [[ "$PROCESSES" -lt "$procecces" ]]; then
    processes=1
fi
python3 ../python/ppcomatrix.py -o=$out_file2 -d="$out_file1" -t="Geom. Mean PPCO Matrix ($(ls_inst_artefacts "$res_dir" "$OUT_INST_PAIRWISE_DUP_STAT" |wc -l| xargs))" -p="${#PAIRWISE_PROCESSES[@]}" -s="$((MAX_SOLVER_PER_PROCESS+1))" -g="$PAIRWISE_GROUP_SIZE"
python3 ../python/ppcomatrix.py -o=$out_file4 -d="$out_file3" -t="Max. PPCO Matrix ($(ls_inst_artefacts "$res_dir" "$OUT_INST_PAIRWISE_DUP_STAT" |wc -l| xargs))" -p="${#PAIRWISE_PROCESSES[@]}" -s="$((MAX_SOLVER_PER_PROCESS+1))" -g="$PAIRWISE_GROUP_SIZE"
