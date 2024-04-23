#!/bin/bash

script=$0
scriptdir=$(dirname $script)

source $scriptdir/defs.sh
source $scriptdir/register_plugin.sh
source $scriptdir/register_global_plugin.sh


cmd=$1
shift 1;

#
# This script helps you to evaluate an experiment given its logs of produced clauses.
# Since, you probably intend to analyse the overlaps from multiple and many perspectives
# the evaluation is structured as an evaluation pipeline which split into multiple steps which
# you can freely program with so-called evaluation plugins.
#
# If you have obtained your logs, the evaluation pipeline consists of the following depended steps
# Once a stage was successfully completed, you can proceed with the next stage.
#
# STAGES: eval-inst-all > eval-exp > eval-global
#
# eval-inst-all:
# Evaluates logs of a single problem instance (job) in parallel. If you plan to do heavy statistics
# restricted to a single problem instance, then writing a plugin for this stage is probably a good idea.
#
# eval-exp:
# Does statistics over all problem instances. Typically you put the problem-specific statistical evaluation into
# the previous stage and aggregate your results at this stage in an extra plugin.
#
# eval-global:
# TODO what does eval-global?
#

if [ "$cmd" == "--eval-inst-all" ]; then

    exp_dir=$1
    res_dir=$2
    num_parallel_jobs=$3
    max_jobs=$4
    jobs_dir="$exp_dir/jobs"
    shift 3;

    mkdir -p $res_dir

    if [ ! -d "$jobs_dir" ]; then
        echo "$jobs_dir does not exist" >&2
        exit 1
    fi

    # preparing parallel run
    eval_jobs_file="eval_jobs.tmp"
    eval_jobs_tmp_dir="eval_jobs_tmp"
    mkdir -p $eval_jobs_tmp_dir

    # run
    seq 1 "$max_jobs" |parallel -j "$num_parallel_jobs" --tempdir "$eval_jobs_tmp_dir" --progress --eta bash "$script" --eval-inst "$jobs_dir/{}" "$res_dir/{}" $@

    exit 0;

elif [ "$cmd" == "--eval-inst" ]; then

    inst_dir=$1
    inst_res_dir=$2
    shift 2;

    if [ ! -d "$inst_dir" ]; then
        echo "$inst_dir does not exist" >&2
        exit 1
    fi

    mkdir -p "$inst_res_dir"


    # TODO preprocessing
    prod_sorted_cls_archive="$inst_dir/cls_produced_sorted.tar.gz"
    prod_sorted_cls_file="$inst_dir/$PROD_SORTED_CLS_TMP"

    tar -xf "$prod_sorted_cls_archive" -C "$inst_dir" 1>/dev/null
    mv "$inst_dir/cls_produced_sorted.txt" "$prod_sorted_cls_file" # work around


    # run plugins
    for plugin in "${REGISTER_INST_PLUGINS[@]}"; do


        # check if plugin is skipped
        skip=false
        for arg in "$@"; do
            if [ "$arg" == "--dis-pl-$plugin" ]; then
                 skip=true
                 break;
            fi
        done
        if [ "$skip" == "true" ]; then
            continue;
        fi

        # prepare parallel job
        bash "$scriptdir/$PLUGIN_DIR_INST/eval_$plugin.sh" "$inst_dir" "$inst_res_dir"
    done

    # post processing
    rm $inst_dir/*.tmp 2> /dev/null
    rm $inst_res_dir/*.tmp 2> /dev/null

    exit 0;
elif [ "$cmd" == "--eval-exp" ]; then

    exp_dir=$1;
    res_dir=$2;

    # TODO preprocessing stuff

    # run exp specific evaluations
    for plugin in "${REGISTER_EXP_PLUGINS[@]}"; do

        # check if plugin is skipped
        skip=false
        for arg in "$@"; do
            if [ "$arg" == "--dis-pl-$plugin" ]; then
                 skip=true
                 break;
            fi
        done
        if [ "$skip" == "true" ]; then
            continue;
        fi

        # prepare parallel job
        bash "$scriptdir/$PLUGIN_DIR_EXP/eval_$plugin.sh" "$exp_dir" "$res_dir"
    done

    # remove tmp files
    rm -r $exp_dir/*.tmp 2>/dev/null
    rm -r $res_dir/*.tmp 2>/dev/null

    exit 0;

elif [ "$cmd" == "--eval-global" ]; then
    exit 0;
fi
