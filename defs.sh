#!/bin/bash

####################
# general configs
####################
export PLUGIN_DIR_INST="plugins/inst"
export PLUGIN_DIR_EXP="plugins/exp"
export PROD_SORTED_CLS_TMP="cls_produced_sorted.tmp"

####################
# extra meta data
#  must be provided
####################
export QUALIFIED_SOLUTION_STATUS="solution_status.txt" # in exp dir (line format: jobs-id SAT/UNSAT/UNKNOWN)
export QUALIFIED_RUNTIME="runtime.txt" # in exp dir (line format: job-id runtime)


####################
# configure plugins
# You might want to use artefacts (output files) from preceding plugins
#  naming convention artefacts: OUT_<LEVEL>_<PLUGIN_NAME>_<OPTIONAL_IDENT>
####################

# dup stat
export OUT_INST_DUP_STAT="dup_stat.txt"
export OUT_EXP_DUP_STAT="dup_stat.txt"

# clause size
export OUT_INST_CLAUSE_SIZE_STAT="cls_clause_size_stat.txt"
export OUT_INST_CLAUSE_SIZE_NORMALIZED="cls_clause_size_stat_normalized.txt"
export OUT_EXP_CLAUSE_SIZE_STAT_GMEAN="cls_clause_size_stat_gmean.txt"

# lbd
export OUT_INST_LBD_STAT="cls_lbd_stat.txt"
export OUT_INST_LBD_NORMALIZED="cls_lbd_stat_normalized.txt"
export OUT_EXP_LBD_STAT_GMEAN="cls_lbd_stat_gmean.txt"

# pairwise
export OUT_INST_PAIRWISE_DUP_STAT="pw_dup_stat.txt"
export OUT_EXP_PAIRWISE_GMEAN_DUP_STAT="pw_gmean_dup_stat.txt"
export OUT_EXP_PAIRWISE_MAX_DUP_STAT="pw_max_dup_stat.txt"
export PAIRWISE_PROCESSES=("0" "1") # process id for pairwise analysis
export PAIRWISE_GROUP_SIZE=15 # how many consecutive solvers should be group in the plot
export MAX_SOLVER_PER_PROCESS="31" # largest solver id of within a process

# time dup rel (time of duplicate clause relative to first appearance)
export OUT_INST_TIME_DUP_REL="time_dup_rel.txt"
export TIME_DUP_REL_MIN_RUNTIMES=("0" "30" "60") # seconds (restrict instances by minimum running time [s])


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