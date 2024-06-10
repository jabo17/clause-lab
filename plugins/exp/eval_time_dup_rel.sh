#!/bin/bash

#
# This plugin, called "eval_time_dup_rel", evaluates duplicates over all solvers
# OUT_FILE: pw_stat.txt
# OUTPUT: sorted relative timestamps of duplicate reports
#

script=$0
scriptdir=$(dirname $script)

source $scriptdir/../../defs.sh

# exp dir
exp_dir=$1
# res dir
res_dir=$2

out_file="$res_dir/cdf_total_time_dup_rel.pdf"

data_lines=()
labels=()
for min_runtime in "${TIME_DUP_REL_MIN_RUNTIMES[@]}"; do
    filtered=()
    while IFS= read -r instance; do
        filtered+=("$res_dir/$instance/$OUT_INST_TIME_DUP_REL")
    done < <(awk -v"min_runtime=$min_runtime" '$2 > min_runtime {print $1}' "$exp_dir/$QUALIFIED_RUNTIME")

    if [ "${#filtered[@]}" -eq "0" ]; then
        # no data
        continue;
    fi

    # compute CDF of for total duplicates
    data_line="$res_dir/cdf_time_dup_rel_$min_runtime.tmp"
    sort -k1,1g -m "${filtered[@]}" | awk -f ../awk/cdf.awk > $data_line

    echo "STATISTIC: delay [s] of duplicate reports since first found (total set of reports among instances with a min runtime of ${min_runtime}s)"
    sort -k1,1g -m "${filtered[@]}" | awk -f ../awk/stats.awk

    # add arguments for plotting
    data_lines+=("$data_line")
    if [ "$(echo "$min_runtime == 0" | bc)" -eq 1 ]; then
        labels+=("all")
    else
        labels+=("\$\geq\$ ${min_runtime}s")
    fi
done

python3 ../python/lineplot.py -o=$out_file --ylabel="Share of duplicates with \$t_{rel}\leq t\$  [$\%$]" \
        --xlabel="Time \$t\$ (log. scale) [s]" --ymin="0" --xlog -d "${data_lines[@]}" -l "${labels[@]}"