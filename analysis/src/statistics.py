import polars as pl
from pathlib import Path
from scipy import stats
from config import ROOT_DIR


def t_test():
    data_path = ROOT_DIR / "data" / "feature_extraction" / "*.csv"
    dataframe = pl.read_csv(data_path)
    print(dataframe)
    subjective_epicentre = dataframe["subjective_epicentre"]
    t_stat, p_val = stats.ttest_1samp(subjective_epicentre, popmean=0)
    print(t_stat)
    print(p_val)


def main():
    t_test()


if __name__ == "__main__":
    main()
