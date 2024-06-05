#!/bin/awk

# Copyright: Jannick Borowitz
# Parses a clause log sorted by the clause hash (position 2), and secondly by timestamp (position 1)
# It prints the relative timestamps of duplicates with respect to the first found (identical clause hash)
# OUTPUT FORMAT: relative timestamps
BEGIN {
    LastHash=""
    FirstFoundT=""
}
{
    hash=$2
    timestamp=$1

    if(hash==LastHash) {
        print timestamp-FirstFoundT
    }else {
        FirstFoundT=timestamp
        LastHash=hash
    }
}