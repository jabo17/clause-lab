#!/bin/bash

# Register your plugin here.
# They are executed in this order, so that you can use the artefacts of a preceding plugin.
REGISTER_INST_PLUGINS=("dup_stat" "clause_size" "lbd" "pairwise")

export REGISTER_INST_PLUGINS;