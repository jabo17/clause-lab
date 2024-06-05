#!/bin/bash

#
# This plugin, called "eval_time_dup_rel", evaluates the relative timestamps of
# duplicates with respect to the first found.
# OUT_FILE: pw_stat.txt
# OUTPUT: sorted relative timestamps of duplicate reports
#

source ../defs.sh

inst_dir=$1
inst_res_dir=$2
inst_id=$(basename "$inst_dir")

out_file="$inst_res_dir/$OUT_INST_TIME_DUP_REL"

awk -f ../awk/time_dup_rel.awk $inst_dir/$PROD_SORTED_CLS_TMP |sort -k1,1g > $out_file