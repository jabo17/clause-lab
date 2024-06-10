#!/bin/bash

# Register your plugin here.
# They are executed in this order, so that you can use the artefacts of a preceding plugin.
REGISTER_INST_PLUGINS=("dup_stat" "clause_size" "lbd" "pairwise" "time_dup_rel") # "clause_size" "lbd" "pairwise")

REGISTER_EXP_PLUGINS=("dup_stat" "clause_size" "lbd" "pairwise" "time_dup_rel") # "clause_size" "lbd" "pairwise")

export REGISTER_INST_PLUGINS;
export REGISTER_EXP_PLUGINS;