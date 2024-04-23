#!/bin/bash

#
# This plugin, called "pairwise", evaluates duplicates over all solvers
# OUT_FILE: pw_stat.txt
# OUT_FORMAT: solver 1, process 1, solver 2, process 2,  # intersection of clause sets, # union of clauses
#

# get file names
source ../../defs.sh

# get problem instance
inst_dir=$1
inst_res_dir=$2
inst_id=$(basename "$inst_dir")

# set out file
# DO NOT USE *.tmp!
out_file="$inst_res_dir/$OUT_INST_PAIRWISE_DUP_STAT"

# select processes to which the pairwise analysis should be restricted
processes=("0" "1") # TODO move to defs

# generate lists of produced clauses for each solver
awk -v"processes=${processes[*]}" -v"res_dir=$inst_res_dir" 'BEGIN{split(processes,plist," "); max_solver=0}
        {if($5 in plist && last[$5" "$6] != $2){
            last[$5" "$6]=$2;
            if($6>max_solver) {max_solver=$6}
            print $2 > res_dir/filtered_produced_sorted_"$5"_"$6".tmp"
        }}
        END {print max_solver}' "$inst_res_dir/$PROD_SORTED_CLS_TMP" > "$inst_dir/max_solver.tmp"

max_solver=$(cat "$inst_dir/max_solver.tmp")
# consider all pairs of solvers and determine pairwise overlap

for i in $(seq 0 ${#processes[@]}); do
    p=${processes[i]}
    for s in $(seq 0 "$max_solver"); do

        buff1="$inst_dir/filtered_produced_sorted_${p}_${s}.tmp"
        if [ ! -f "$buff1" ]; then
            touch "$buff1"
        fi

        b1=$(wc -l < "$buff1")

        for i2 in $(seq 0 "$i"); do
            p2=${processes[i2]}
            max_s2="$max_solver"
            if [ "$p" == "$p2" ]; then
                max_s2=$((s-1))
            fi
            for s2 in s$(seq 0 $max_s2); do
                buff2="$inst_dir/filtered_produced_sorted_${p2}_${s2}.tmp"

                intersection=$(comm -12 "$buff1" "$buff2" |wc -l)
                b2=$(wc -l < "$buff2")

                echo "$s $p $s2 $p2 $((b1+b2-intersection)) $intersection" >> $out_file
            done
        done
    done
done