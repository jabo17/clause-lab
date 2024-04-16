#!/bin/bash

#
# This plugin, called "clause_size", evaluates the duplicate production ratios
# with respect to the clause size.
# OUT_FILE: clause_size_stat
# OUT_FORMAT: clause size, clauses, dup prod. clauses
#

# get file names
source ../../defs.sh

# get problem instance
inst_dir=$1

# depends on; otherwise try to create file or exit
depends_on_inst_file "$inst_dir" "dup_stat" "$OUT_DUP_STAT"

# set out file
# DO NOT USE *.tmp!
out_file="$inst_dir/$OUT_INST_CLAUSE_SIZE_STAT"
out_file2="$inst_dir/$OUT_INST_CLAUSE_SIZE_STAT_NORMALIZED"

# determine produced (duplicate) clauses for each clause size
awk -v "ATTR_POS=3" -f ../../awk/dist_cls_over_attr.awk "$inst_dir/$PROD_SORTED_CLS_TMP" > "$out_file"

# normalize to overall number of reports
awk -v "reports=$(awk '{print $2}' "$inst_dir"/"$OUT_DUP_STAT")" '
    {print $1, $2/reports, $3/reports}}
    ' "$out_file" > "$out_file2"

exit 0