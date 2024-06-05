#!/bin/awk

# Copyright: Jannick Borowitz
# Parses a sorted file while considering the first column and outputs a CDF.

BEGIN {
    last=""
    counter=-1
}
{
    if($1==last) {
        a[counter]++
    }else {
        counter++
        a[counter]=1
        elem[counter]=$1
        last=$1
    }
}
END {
    i = 0
    sum = 0
    while(i < counter) {
        sum+=a[i]
        print elem[i], sum/NR
        i++
    }
}