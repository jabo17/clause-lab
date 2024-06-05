#!/bin/awk

# Copyright: Jannick Borowitz
# Gives statistics for a sorted data.

BEGIN{
    i=0
    max_set=0
    min_set=0
}
{
    a[i]=$1;i+=1;asum+=$1;
    if($1>0) {gsum+=log($1)} else {nogsum=1}
    if($1<min_elem || !min_set){min_elem=$1; min_set=1}
    if($1>max_elem || !max_set){max_elem=$1; max_set=1}
}
END {
    if(NR%2==0){median=(a[int(NR/2)]+a[int(NR/2-1)])*0.5}else{median=a[int(NR/2)]};
    if(NR%4==0){median25=(a[int(NR/4)]+a[int(NR/4-1)])*0.5}else{median25=a[int(NR/4)]};
    if(NR%4==0){median75=(a[int(NR*3/4)]+a[int(NR*3/4-1)])*0.5}else{median75=a[int(NR*3/4)]};
    if(nogsum==1){gmean="-"}else{gmean=exp(gsum/NR)};amean=asum/NR;
    print "amean="amean, "gmean="gmean, "median="median, "median25="median25, "median75="median75, "min="min_elem, "max="max_elem
}