# packages
import polars as pl
from pathlib import Path

# Constants
ROOT_DIR = Path(__file__).parents[2]
EXP_SCHEMA = {
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
