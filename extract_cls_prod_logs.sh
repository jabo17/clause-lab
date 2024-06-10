#!/bin/bash

parallel_jobs=10
parallel_tmp_dir="tmp" # should point to a tmp dir in the working directory

script=$0
cmd=$1

if [ "$cmd" == "--extract-all-parallel" ]; then
    shift 1
    first_job_id=$1 # this is the internal_id of the (first) jobs in processed_jobs.out
    num_jobs=$2 # this is the number of jobs
    # logging dir of experiments which includes a directory for each formula starting with $first_job_id
    dir=$3

    mkdir -p "$dir/jobs"

    par_jobs="par_jobs.tmp"
    rm par_jobs 2> /dev/null
    for i in $(seq 1 $num_jobs); do
        mkdir -p "$dir/jobs/$i"
        i_offset=$((i + first_job_id - 1)) # job id in Mallob

        echo "$script --extract-job $dir $i $i_offset" >> $par_jobs
    done

    mkdir -p tmp
    parallel -j $parallel_jobs --tmpdir="$parallel_tmp_dir" --eta --progress < $par_jobs

    rm -r tmp
    rm $par_jobs

elif [ "$cmd" == "--extract-job" ]; then

    shift 1
    dir=$1
    id=$2
    original_id=$3

    # iterate over all processes to obtain logs for job i
    if [ ! -f "$dir/jobs/$id/FINISHED_EXTRACT" ]; then
	    rm "$dir/jobs/$id/cls_produced.txt" 2> /dev/null
        p=0
        while [ -d "$dir/${original_id}/$p" ]; do
            # iterate over all solvers of process p to obtain logs for this job
            for log in $dir/${original_id}/$p/produced_cls_*.log; do
                s="${log#*produced_cls_}"
                s="${s%.log}"
                awk -v "p=$p" -v "s=$s" '{print $0, p, s}' "$log" >> "$dir/jobs/$id/cls_produced.txt"
            done
            p=$((p+1))
        done

        # milestone
        touch "$dir/jobs/$id/FINISHED_EXTRACT"
    fi

    # clean up and proceed only if artefact exist and milestone was reached
    if [ -f "$dir/jobs/$id/cls_produced.txt" ] && [ -f "$dir/jobs/$id/FINISHED_EXTRACT" ]; then
        p=0
        while [ -d "$dir/${original_id}/$p" ]; do
            rm $dir/${original_id}/$p/produced_cls_*.log
            p=$((p+1))
        done
    fi


    if [ ! -f "$dir/jobs/$id/FINISHED_EXTRACT" ]; then
        echo "Something went wrong during extraction for $dir/jobs/$id/cls_produced.txt"
        exit 1
    fi


    # sort by clause hash (primary key), timestamp (secondary key)
    agg_filename_sorted="cls_produced_sorted.txt"
    agg_file_sorted="$dir/jobs/$id/$agg_filename_sorted"
    if [ ! -f "$dir/jobs/$id/FINISHED_SORTED" ]; then

        sort "$dir/jobs/$id/cls_produced.txt" -k2,2 -k1,1g > "$agg_file_sorted"
        exit_code=$?

        if [ $exit_code -eq 0 ] && [ -f $agg_file_sorted ]; then
            touch "$dir/jobs/$id/FINISHED_SORTED"
            rm "$dir/jobs/$id/cls_produced.txt"
        else
            echo "Sort failed for $dir/jobs/$id/cls_produced.txt"
            exit 1
        fi
    fi


    # compress cls_produced_sorted
    agg_sorted_zip="$dir/jobs/$id/cls_produced_sorted.tar.gz"
    if [ ! -f "$dir/jobs/$id/FINISHED_TAR" ] && [ -f "$dir/jobs/$id/FINISHED_SORTED" ]; then
        agg_sorted_zip="$dir/jobs/$id/cls_produced_sorted.tar.gz"

        tar -czvf "$agg_sorted_zip" -C "$dir/jobs/$id" "$agg_filename_sorted"
        exit_code=$?
        if [ ! $exit_code -eq 0 ] || [ ! -f "$agg_sorted_zip" ]; then
            echo "Tar failed for $agg_file_sorted"
            exit 1
        else
            touch "$dir/jobs/$id/FINISHED_TAR"
        fi
    fi

    # if some how script was re-run and tar was already created, unzip tar
    if [ ! -f $agg_file_sorted ]; then
        tar -xvf "$agg_sorted_zip" -C "$dir/jobs/$id"
        exit_code=$?
        if [ ! $exit_code -eq 0 ] || [ ! -f "$agg_file_sorted" ]; then
            echo "Tar extraction failed for $agg_sorted_zip"
            exit 1
        fi
    fi

    if [ -f "$dir/jobs/$id/FINISHED_TAR" ] && [ -f "$agg_sorted_zip" ]; then
        rm $agg_file_sorted 2> /dev/null
    fi

    echo "Finished $id!"

fi
