#!/bin/bash

#
# This plugin, called "pairwise", evaluates duplicates over all solvers
# OUT_FILE: pw_stat.txt
# OUT_FORMAT: solver 1, process 1, solver 2, process 2,  # intersection of clause sets, # union of clauses
#

# get definitions and helpers
source ../defs.sh

# get problem instance
inst_dir=$1
inst_res_dir=$2
inst_id=$(basename "$inst_dir")

# set out file
# DO NOT USE *.tmp!
out_file="$inst_res_dir/$OUT_INST_PAIRWISE_DUP_STAT"

# Check if data for this instances is potentially noisy.
# Maybe there was not running for every solver-id a solver.
# Therefore, we filter out instances where the maximum solver does not occur in reports.
if [[ "$(awk -v"maxs=$MAX_SOLVER_PER_PROCESS" '{if(maxs==$6){print "found"; exit}}' |wc -l)" -gt "0" ]]; then
    echo "Did not created artefact $out_file because it may contain noisy data." >&2
    exit 0;
fi

# generate lists of produced clauses for each solver
awk -v"processes=${PAIRWISE_PROCESSES[*]}" -v"res_dir=$inst_res_dir" '
        BEGIN{split(processes,plist," ");for(i in plist){plookup[plist[i]]=1}}
        {if($5 in plookup && last[$5" "$6] != $2){
            last[$5" "$6]=$2;
            path=res_dir"/filtered_produced_sorted_"$5"_"$6".tmp";
            print $2 >> path
        }}' "$inst_dir/$PROD_SORTED_CLS_TMP"

# consider all pairs of solvers and determine pairwise overlap

for i in $(seq 0 $((${#PAIRWISE_PROCESSES[@]}-1))); do
    p="${PAIRWISE_PROCESSES[i]}"
    for s in $(seq 0 "$MAX_SOLVER_PER_PROCESS"); do

        buff1="$inst_res_dir/filtered_produced_sorted_${p}_${s}.tmp"
        if [ ! -f "$buff1" ]; then
            touch "$buff1"
        fi

        b1=$(cat "$buff1" |wc -l |xargs)

        for i2 in $(seq 0 "$i"); do
            p2="${PAIRWISE_PROCESSES[i2]}"
            max_s2="$MAX_SOLVER_PER_PROCESS"
            if [ "$p" == "$p2" ]; then
                max_s2=$((s-1))
                if [ "$max_s2" -le "-1" ]; then
                    continue
                fi
            fi
            for s2 in $(seq 0 "$max_s2"); do
                buff2="$inst_res_dir/filtered_produced_sorted_${p2}_${s2}.tmp"

                intersection=$(comm -12 "$buff1" "$buff2" |wc -l |xargs)
                b2=$(cat "$buff2" |wc -l |xargs)

                echo "$s $p $s2 $p2 $((b1+b2-intersection)) $intersection" >> $out_file
            done
        done
    done
done