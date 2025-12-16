from types import prepare_class
import polars as pl
from pathlib import Path

# Constants
ROOT_DIR = Path(__file__).parents[2]


def scout_files():
    sub_dir = ROOT_DIR / "data" / "raw"
    beh_data_paths = sorted(sub_dir.rglob("*/*/beh/*.csv"))
    print("Subject files found!")
    return beh_data_paths


def load_subjects(paths_to_data):
    participant_schema = {
        "participant_id": pl.Int64,
        "group": pl.Int64,
        "round_index": pl.Int64,
        "onset": pl.Float64,
        "x": pl.Float64,
        "y": pl.Float64,
        "quadrant": pl.Int64,
        "was_target": pl.Int64,
        "screen_width": pl.Int64,
        "screen_height": pl.Int64,
    }

    combined_data = pl.DataFrame()
    for current_path in paths_to_data:
        current_participant = pl.read_csv(current_path, schema=participant_schema)
        combined_data = pl.concat([combined_data, current_participant])
    print(combined_data)
    return combined_data


def norm_data(participant_data):
    norm_combined_data = participant_data.with_columns(
        (pl.col("x").truediv(pl.col("screen_width")) * 2 - 1).alias("norm_x"),
        (1 - pl.col("y").truediv(pl.col("screen_height")) * 2).alias("norm_y"),
    )

    print(norm_combined_data)
    return norm_combined_data


def save_preprocessed_data(preprocessed_data):
    data_csv_name = "preprocessed_data.csv"
    data_parquet_name = "preprocessed_data.parquet"
    path_to_data = ROOT_DIR / "data" / "preprocessed"
    if path_to_data.exists():
        preprocessed_data.write_csv(path_to_data / data_csv_name)
        preprocessed_data.write_parquet(path_to_data / data_parquet_name)
    else:
        Path.mkdir(path_to_data)
        preprocessed_data.write_csv(path_to_data / data_csv_name)
        preprocessed_data.write_parquet(path_to_data / data_parquet_name)
    return


def main():
    subject_paths = scout_files()
    combined_data = load_subjects(subject_paths)
    normalised_data = norm_data(combined_data)
    save_preprocessed_data(normalised_data)
    print(normalised_data)


if __name__ == "__main__":
    main()
