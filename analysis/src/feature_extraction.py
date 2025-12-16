import polars as pl
from pathlib import Path

# Constants
ROOT_DIR = Path(__file__).parents[2]


def import_files():
    data_dir = sorted(ROOT_DIR.rglob("data/preprocessed/*.parquet"))
    cleaned_subject_data = pl.read_parquet(data_dir)

    return cleaned_subject_data


def subjective_epicentre(data):
    subjective_epicentre = data.group_by("participant_id").agg(pl.mean("norm_x"))
    subjective_epicentre = pl.concat([data, subjective_epicentre])
    return subjective_epicentre


def save_data(data):
    data_csv_name = "feature_extraction.csv"
    path_to_data = ROOT_DIR / "data" / "feature_extraction"
    if path_to_data.exists():
        data.write_csv(path_to_data / data_csv_name)
    else:
        Path.mkdir(path_to_data)
        data.write_csv(path_to_data / data_csv_name)
    return


def main():
    cancellation_data = import_files()
    subjective_epicentre_data = subjective_epicentre(cancellation_data)
    print(subjective_epicentre_data)
    save_data(subjective_epicentre_data)


if __name__ == "__main__":
    main()
