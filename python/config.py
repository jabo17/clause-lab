import matplotlib.pyplot as plt


def init_matplotlib():
    params = {'text.usetex': False, 'mathtext.fontset': "cm", "font.family": "STIXGeneral"}
    plt.rcParams.update(params)
