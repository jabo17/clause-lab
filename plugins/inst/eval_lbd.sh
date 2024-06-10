#!/bin/bash

#
# This plugin, called "lbd", evaluates the duplicate production ratios
# with respect to the LBD.
# OUT_FILE: lbd_stat
# OUT_FORMAT: lbd, clauses, dup prod. clauses
#

# get file names
script=$0
scriptdir=$(dirname $script)

source $scriptdir/../../defs.sh

# get problem instance
inst_dir=$1
res_inst_dir=$2

# depends on; otherwise try to create file or exit
depends_on_res_inst_file "$inst_dir" "$res_inst_dir" "dup_stat" "$OUT_INST_DUP_STAT"

# set out file
# DO NOT USE *.tmp!
out_file="$res_inst_dir/$OUT_INST_LBD_STAT"
out_file2="$res_inst_dir/$OUT_INST_LBD_NORMALIZED"

# determine produced (duplicate) clauses for each clause size
awk -v "ATTR_POS=4" -f $scriptdir/../../awk/dist_cls_over_attr.awk "$inst_dir/$PROD_SORTED_CLS_TMP" |sort -k1,1n > "$out_file"

# normalize to total number of reports
awk -v "reports=$(awk '{print $2}' "$res_inst_dir/$OUT_INST_DUP_STAT")" '
    {print $1, $2/reports, $3/reports}
    ' "$out_file" > "$out_file2"

exit 0
