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
    return subjective_epicentre


def main():
    cancellation_data = import_files()
    subjective_epicentre_data = subjective_epicentre(cancellation_data)
    print(subjective_epicentre_data)


if __name__ == "__main__":
    main()
