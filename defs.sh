#!/bin/bash

PLUGIN_DIR_INST="plugin/inst"
PLUGIN_DIR_EXP="plugin/exp"

# export names that are used around the evaluation
export PROD_SORTED_CLS_TMP="cls_produced_sorted.tmp"

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
# Stream list of artefacts (file paths) from all jobs.
# Arguments:
#   exp_dir
#   artefact
###################################
function stream_inst_artefacts(){
    exp_dir=$0
    artefact=$1

    ls -1 "$exp_dir/*/$artefact"
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
function depends_on_inst_file(){
    inst_dir=$0
    plugin=$1
    file=$2
    if [ ! -f "$inst_dir/$artefact" ]; then
      bash "${PLUGIN_DIR_INST}/eval_${plugin}.sh" $inst_dir
      exit_code=$?
      if [ ! -f "$inst_dir/$artefact" ] || [ ! $exit_code -eq 0 ]; then
        echo "Depending on ${inst_dir}/${artefact}, but the file was not found and cannot be created by plugin ${plugin}!" >&2
        exit 1
      fi
    fi

}

export -f stream_inst_artefacts