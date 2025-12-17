from types import prepare_class
import polars as pl
from pathlib import Path
from config import ROOT_DIR, EXP_SCHEMA


def scout_files():
    sub_dir = ROOT_DIR / "data" / "raw"
    beh_data_paths = sorted(sub_dir.rglob("*/*/beh/*.csv"))
    print("Subject files found!")
    return beh_data_paths


def load_subjects(paths_to_data):
    combined_data = pl.DataFrame()
    for current_path in paths_to_data:
        current_participant = pl.read_csv(current_path, schema=EXP_SCHEMA)
        combined_data = pl.concat([combined_data, current_participant])
    return combined_data


def norm_data(participant_data):
    norm_combined_data = participant_data.with_columns(
        (pl.col("x").truediv(pl.col("screen_width")) * 2 - 1).alias("norm_x"),
        (1 - pl.col("y").truediv(pl.col("screen_height")) * 2).alias("norm_y"),
    )
    return norm_combined_data


def save_preprocessed_data(preprocessed_data):
    data_csv_name = "preprocessed_data.csv"
    data_parquet_name = "preprocessed_data.parquet"
    path_to_data = ROOT_DIR / "data" / "preprocessed"
    if path_to_data.exists():
        preprocessed_data.write_csv(path_to_data / data_csv_name)
        preprocessed_data.write_parquet(path_to_data / data_parquet_name)
        print("Saved preprocessed data")
    else:
        Path.mkdir(path_to_data)
        preprocessed_data.write_csv(path_to_data / data_csv_name)
        preprocessed_data.write_parquet(path_to_data / data_parquet_name)
        print("Saved preprocessed data and created directory")
    return


def main():
    subject_paths = scout_files()
    combined_data = load_subjects(subject_paths)
    normalised_data = norm_data(combined_data)
    save_preprocessed_data(normalised_data)
    print(normalised_data)


if __name__ == "__main__":
    main()
