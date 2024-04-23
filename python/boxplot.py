import sys

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import argparse

import config


def plot_boxplot(outfile, title, data, labels, ymin=None, ymax=None, stepsize=None, showoutliers=True, ylabel=""):
    config.init_matplotlib()

    fig, ax = plt.subplots(figsize=(5, 4))

    boxplot = ax.boxplot(data, labels=labels, showfliers=showoutliers)

    ax.set_title(title, pad=11)
    ax.yaxis.grid(True)

    [ymin2, ymax2] = ax.get_ylim()
    if ymin is not None:
        ymin2 = ymin

    if ymax is not None:
        ymax2 = ymax
    ax.set_ylim([ymin2, ymax2])

    # show number of datapoints above each boxplot
    for idx, label in enumerate(labels):
        plt.text(idx + 1, ymax2 + (ymax2 - ymin2) * 0.01, f'({len(data[idx])})', horizontalalignment='center')

    if stepsize is not None:
        ax.yaxis.set_ticks(np.arange(ymin2, ymax2 + stepsize, stepsize))

    plt.ylabel(ylabel)
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(outfile)


if __name__ == "__main__":

    # parse arguments
    parser = argparse.ArgumentParser(description="Plot boxplots")

    parser.add_argument("-o", "--outfile", nargs=1, metavar="outfile", type=str, help="output file", required=True)
    parser.add_argument("-t", "--title", nargs=1, metavar="title", type=str, help="title in plot")

    group = parser.add_argument_group(title="data", description="data-row with label")
    group.add_argument("-d", "--datafile", nargs="*", metavar="datafile", type=str, help="data files")
    group.add_argument("-l", "--label", nargs="*", metavar="label", type=str, help="labels")

    parser.add_argument("--ylabel", nargs=1, metavar="ylabel", type=str, help="ylabel (scaling)")
    parser.add_argument("--ymin", nargs=1, metavar="ymin", type=float, help="min value (scaling)")
    parser.add_argument("--ymax", nargs=1, metavar="ymax", type=float, help="max value (scaling)")
    parser.add_argument("--ystepsize", nargs=1, metavar="ystepsize", type=float, help="stepsize of y-ticks")
    parser.add_argument("--dis-fliers", nargs=1, metavar="dis-fliers", type=bool, help="disable outliers")

    args = parser.parse_args()
    if len(args.datafile) != len(args.label):
        print("Number of data files and labels must be the same.", file=sys.stderr)
        quit(1)

    data = []
    for file in args.datafile:
        df = pd.read_csv(file, header=None)
        data.append(df[df.columns[0]].to_list())

    ylabel = ""
    if args.ylabel and len(args.ylabel) > 0:
        ylabel = args.ylabel[0]

    title = ""
    if args.title and len(args.title) > 0:
        title = args.title[0]

    ymin = None
    if args.ymin and len(args.ymin) > 0:
        ymin = args.ymin[0]

    ymax = None
    if args.ymax and len(args.ymax) > 0:
        ymax = args.ymax[0]

    print(args)
    stepsize = None
    if args.ystepsize and len(args.ystepsize) > 0:
        stepsize = args.ystepsize[0]

    dis_fliers = False
    if args.dis_fliers and len(args.dis_fliers) > 0:
        dis_fliers = True

    # plot boxplot
    plot_boxplot(args.outfile[0], title, data, args.label, ymin=ymin, ymax=ymax, stepsize=stepsize,
                 showoutliers=dis_fliers, ylabel=ylabel)
