#!/bin/bash

PLUGIN_DIR_INST="plugins/inst"
PLUGIN_DIR_EXP="plugins/exp"

# export names that are used around the evaluation
export PROD_SORTED_CLS_TMP="cls_produced_sorted.tmp"
export QUALIFIED_SOLUTION_STATUS="solution_status.txt" # in exp dir

# You might want to use artefacts from preceding plugins
# naming convention: OUT_<LEVEL>_<PLUGIN_NAME>_<OPTIONAL_IDENT>
export OUT_INST_DUP_STAT="dup_stat.txt"
export OUT_INST_PAIRWISE_DUP_STAT="pw_dup_stat.txt"
export OUT_EXP_DUP_STAT="dup_stat.txt"
export OUT_INST_CLAUSE_SIZE_STAT="cls_clause_size_stat.txt"
export OUT_INST_CLAUSE_SIZE_NORMALIZED="cls_clause_size_stat_normalized.txt"
export OUT_INST_LBD_STAT="cls_lbd_stat.txt"
export OUT_INST_LBD_NORMALIZED="cls_lbd_stat_normalized.txt"
export OUT_EXP_CLAUSE_SIZE_STAT_GMEAN="cls_clause_size_stat_gmean.txt"


# some useful helper functions

###################################
# Creates list of artefacts (file paths) from all jobs.
# Arguments:
#   dir
#   artefact
###################################
function ls_inst_artefacts(){
    dir=$1
    artefact=$2

    ls -1 $dir/*/$artefact
}

###################################
# State on which file, your plugin depends.
# In case the artefact does not exists, it tries to produce it.
# If the artefact cannot not be created after all, it kills the calling process.
# Arguments:
#   inst_dir
#   plugin
#   file
#
###################################
function depends_on_res_inst_file(){
    inst_dir=$1
    inst_res_dir=$2
    plugin=$3
    file=$4
    if [ ! -f "$inst_res_dir/$file" ]; then
      bash "${PLUGIN_DIR_INST}/eval_${plugin}.sh" "$inst_dir" "$inst_res_dir"
      exit_code=$?
      if [ ! -f "$inst_dir/$file" ] || [ ! $exit_code -eq 0 ]; then
        echo "Depending on ${inst_res_dir}/${file}, but the file was not found and cannot be created by plugin ${plugin}!" >&2
        exit 1
      fi
    fi

}

export -f ls_inst_artefacts