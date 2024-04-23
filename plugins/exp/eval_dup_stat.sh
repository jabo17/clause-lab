#!/bin/bash

source ../defs.sh

# exp dir
exp_dir=$1
# res dir
res_dir=$2

# out file
out_file1="$res_dir/$OUT_EXP_DUP_STAT"
out_file2="$res_dir/sorted_dcpr.txt"
out_file3="$res_dir/boxplot_dcpr.pdf"

# reduce dup stat over all jobs sorted by job id
ls_inst_artefacts "$res_dir" "$OUT_INST_DUP_STAT" |xargs -I {} cat "{}" |sort -k1,1n > "$out_file1"
# compute DCPR for every jobs and sort them ascending
awk '{if($2>0){print $4/$2}else{print 0}}' < "$out_file1" |sort -k1,1g > "$out_file2"


# plots
# box plot of dcpr
datarow_sat="$res_dir/dcpr_sat.tmp"
datarow_unsat="$res_dir/dcpr_unsat.tmp"

join -j 1 "$exp_dir/$QUALIFIED_SOLUTION_STATUS" $out_file1 |awk -v "satfile=$datarow_sat" -v "unsatfile=$datarow_unsat" \
    '{dcpr=0; if($5>0){dcpr=$3/$5}; if($2=="SAT"){print dcpr >> satfile}else if($2=="UNSAT"){print dcpr >> unsatfile}}'

python3 ../python/boxplot.py -o=$out_file3 --ylabel="DCPR" --ymin="0" --ymax="1" --ystepsize="0.1" \
    -d "$out_file2" "$datarow_sat" "$datarow_unsat" -l "all" "sat" "unsat"
