import sys

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import argparse

import config

def plot_barplot(outfile, title, data, labels, ymin=None, ymax=None, stepsize=None, ylabel="", xlabel=""):
    config.init_matplotlib()

    fig, ax = plt.subplots(figsize=(5, 4))

    for idx, df in enumerate(data):
        ax.bar(df[df.columns[0]], df[df.columns[1]], label=labels[idx])

    ax.set_title(title, pad=11)
    ax.yaxis.grid(True)

    [ymin2, ymax2] = ax.get_ylim()
    if ymin is not None:
        ymin2 = ymin

    if ymax is not None:
        ymax2 = ymax
    ax.set_ylim([ymin2, ymax2])

    if stepsize is not None:
        ax.yaxis.set_ticks(np.arange(ymin2, ymax2 + stepsize, stepsize))

    plt.ylabel(ylabel)
    plt.xlabel(xlabel)
    plt.grid(True)
    plt.legend(loc="upper right")
    plt.tight_layout()
    plt.savefig(outfile)


if __name__ == "__main__":

    # parse arguments
    parser = argparse.ArgumentParser(description="Plot barplots")

    parser.add_argument("-o", "--outfile", nargs=1, metavar="outfile", type=str, help="output file", required=True)
    parser.add_argument("-t", "--title", nargs=1, metavar="title", type=str, help="title in plot")

    group = parser.add_argument_group(title="data", description="data-row (x,y) with label for bins along the x-axis")
    group.add_argument("-d", "--datafile", nargs="*", metavar="datafile", type=str, help="data files")
    group.add_argument("-l", "--label", nargs="*", metavar="label", type=str, help="labels")

    parser.add_argument("--ylabel", nargs=1, metavar="ylabel", type=str, help="ylabel")
    parser.add_argument("--xlabel", nargs=1, metavar="xlabel", type=str, help="xlabel")
    parser.add_argument("--ymin", nargs=1, metavar="ymin", type=float, help="min value (scaling)")
    parser.add_argument("--ymax", nargs=1, metavar="ymax", type=float, help="max value (scaling)")
    parser.add_argument("--ystepsize", nargs=1, metavar="ystepsize", type=float, help="stepsize of y-ticks")

    args = parser.parse_args()
    if len(args.datafile) != len(args.label):
        print("Number of data files and labels must be the same.", file=sys.stderr)
        quit(1)

    data = []
    for file in args.datafile:
        df = pd.read_csv(file, header=None, index_col=False, delimiter=" ")
        data.append(df)

    ylabel = ""
    if args.ylabel and len(args.ylabel) > 0:
        ylabel = args.ylabel[0]

    xlabel = ""
    if args.xlabel and len(args.xlabel) > 0:
        xlabel = args.xlabel[0]

    title = ""
    if args.title and len(args.title) > 0:
        title = args.title[0]

    ymin = None
    if args.ymin and len(args.ymin) > 0:
        ymin = args.ymin[0]

    ymax = None
    if args.ymax and len(args.ymax) > 0:
        ymax = args.ymax[0]

    stepsize = None
    if args.ystepsize and len(args.ystepsize) > 0:
        stepsize = args.ystepsize[0]

    print(args)
    # plot boxplot
    plot_barplot(args.outfile[0], title, data, args.label, ymin=ymin, ymax=ymax, stepsize=stepsize, ylabel=ylabel,
                 xlabel=xlabel)
