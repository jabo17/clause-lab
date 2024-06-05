import math
import sys

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import argparse

import config


def plot_ppco_matrix(outfile, title, data, num_processes, num_solvers, group_size=None, vmax=None, vstepsize=0.05, cb_label=""):
    config.init_matplotlib()

    n = num_processes * num_solvers
    ppco_matrix = [([0.0] * n) for _ in range(n)]

    processes = sorted(list(set([0] + [int(row["p1"]) for index, row in data.iterrows()])))
    assert (len(processes) <= num_processes)

    look_up_p_idx = {p: i for i, p in enumerate(processes)}

    def idx(process, solver):
        return look_up_p_idx[int(process)] * num_solvers + int(solver)

    max_val = data["ppco"].max()
    for i, row in data.iterrows():
        i1 = idx(row["p1"], row["s1"])
        i2 = idx(row["p2"], row["s2"])
        ppco_matrix[i2][i1] = ppco_matrix[i1][i2] = row["ppco"]



    fig, ax = plt.subplots()
    ppco_matrix_plot = ax.imshow(ppco_matrix, vmax=vmax)

    # separate processes with white lines
    ax.hlines([j*num_solvers-0.5 for j in range(1,num_processes)], *ax.get_xlim(), color="white")
    ax.vlines([j*num_solvers-0.5 for j in range(1,num_processes)], *ax.get_ylim(), color="white")

    # separate groups with gray dashed lines
    if group_size is not None and group_size > 0:
        ax.hlines([j*group_size-0.5 for j in range(1,int(math.ceil(n/group_size)))], *ax.get_xlim(), color="gray", linestyle="--")
        ax.vlines([j*group_size-0.5 for j in range(1,int(math.ceil(n/group_size)))], *ax.get_ylim(), color="gray", linestyle="--")


    # add labels to show global solver ids
    def get_label(process, solver):
        if idx(process, solver) % 4 == 0:
            return str(process*num_solvers+solver)
        return ""
    labels = [get_label(p, s) for p in processes for s in range(num_solvers)]
    ax.set_xticks(np.arange(n), labels=labels)
    ax.set_yticks(np.arange(n), labels=labels)

    # modify color bar
    cbar = ax.figure.colorbar(ppco_matrix_plot, ax=ax)
    cbar.ax.set_ylabel(cb_label, rotation=-90, va="bottom", fontsize=14)
    # If vmax is given, restrict colorbar to vmax.
    # If max_value>vmax, add ">" to legend of colorbar.
    if vmax is not None:
        vticks = np.arange(0, max_val, vstepsize)
        vticks_labels = [str(t) for t in vticks]
        if vmax < max_val:
            vticks_labels[-1] = "$\geq " + vticks_labels[-1]
        cbar.set_ticks(vticks)
        cbar.set_ticklabels(vticks_labels)

    ax.set_title(title)
    plt.tight_layout()
    plt.savefig(outfile)


if __name__ == "__main__":

    # parse arguments
    parser = argparse.ArgumentParser(description="Plot PPCO matrices.")

    parser.add_argument("-o", "--outfile", nargs=1, metavar="outfile", type=str, help="output file", required=True)
    parser.add_argument("-t", "--title", nargs=1, metavar="title", type=str, help="title in plot")

    parser.add_argument("-d", "--datafile", nargs=1, metavar="datafile", type=str, help="data file of line format: s1 p1 s2 p2 ppco", required=True)

    parser.add_argument("-p", "--processes", nargs=1, metavar="processes", type=int, help="number of processes", required=True)
    parser.add_argument("-s", "--solvers", nargs=1, metavar="solvers", type=int, help="number of solvers per process", required=True)
    parser.add_argument("-g", "--group_size", nargs=1, metavar="group_size", type=int,
                        help="group every --group_size consecutive solvers")

    parser.add_argument("--vmax", nargs=1, metavar="vmax", type=int,
                        help="max for colorbar")
    parser.add_argument( "--vstepsize", nargs=1, metavar="vstepsize", type=int,
                        help="stepsize in colorbar")

    args = parser.parse_args()
    print(args)

    group_size = None
    if args.group_size is not None:
        group_size = args.group_size[0]

    data = pd.read_csv(args.datafile[0], sep=" ", names=["s1", "p1", "s2", "p2", "ppco"])

    vmax = None
    if args.vmax is not None:
        vmax = args.vmax[0]

    vstepsize = None
    if args.vstepsize is not None:
        vstepsize = args.vstepsize[0]

    # plot ppco matrix
    plot_ppco_matrix(args.outfile[0], args.title[0], data, num_processes=args.processes[0], num_solvers=args.solvers[0],
                    group_size=group_size, vmax=vmax, vstepsize=vstepsize)
