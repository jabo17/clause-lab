#!/bin/awk

# Copyright: Jannick Borowitz
# Parses a clause log sorted by the clause hash (position 2)
# and counts produced clauses and duplicate clauses per attrbute at position $ATTR
# Use this script with -v"ATTR=x" where x is the column of your attribute in the clause log
# OUTPUT FORMAT: attr, clauses with this attribute, duplicate clauses with this attribute
BEGIN {LastHash = ""}
{   hash = $2;
    reports[$ATTR_POS]++;
    if (LastHash == hash) { dup[$ATTR_POS]++}
    else {LastHash = hash}
}
END {for (attr in reports) {
    if (!(attr in dup)) {dup[attr] = 0};
    print attr, reports[attr], dup[attr]
}}