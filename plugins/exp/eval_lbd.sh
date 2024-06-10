#!/bin/bash

script=$0
scriptdir=$(dirname $script)

source $scriptdir/../../defs.sh

# exp dir
exp_dir=$1
# res dir
res_dir=$2

# out file
# OUTPUT FORMAT: clause size, GEOMEAN(clauses with size / clauses), GEOMEAN(dup clauses with size / clauses)
out_file1="$res_dir/$OUT_EXP_LBD_STAT_GMEAN"
out_file2="$res_dir/barplot_lbd.pdf"

# Compute for each clause size the geometric mean over the normalized reports and dup (by reports)
# on the set of problem instances where at least on duplicate clause was produced for given clause size
ls_inst_artefacts "$res_dir" "$OUT_INST_LBD_NORMALIZED" |xargs -I {} cat {} |awk '{
        if($3>0){reports[$1]++; log_reports_normalized[$1]+=log($2); log_dup_normalized[$1]+=log($3)}
    }
    END {for(x in reports){
        print x, exp(log_reports_normalized[x]/reports[x]), exp(log_dup_normalized[x]/reports[x])
    }}
    ' |sort -k1,1g > "$out_file1"


datarow_1="$res_dir/gmean_normalized_reports_per_lbd.tmp"
datarow_2="$res_dir/gmean_dcpr_per_lbd.tmp"
awk '{print $1, 100*$2}' $out_file1 > $datarow_1
awk '{print $1, 100*$3}' $out_file1 > $datarow_2
python3 ../python/barplot.py -o=$out_file2 --ylabel="\$\#\$ clause productions [$\%$]" --xlabel="LBD \$l\$" --ymin="0" \
                                 -d "$datarow_1" "$datarow_2" -l "all" "dup"

# compute DCPR for every jobs and sort them ascending
#awk '{if($2>0){print $4/$2}else{print 0}}' < "$out_file1" |sort -k1,1g > "$out_file2"