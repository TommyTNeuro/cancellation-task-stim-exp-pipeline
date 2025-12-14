import polars as pl
from pathlib import Path

def scout_files():
    root_dir = Path(__file__).parents[2]
    sub_dir = root_dir / 'data' / 'raw'
    beh_data_paths = sorted(sub_dir.rglob('*/*/beh/*.csv'))
    return beh_data_paths

if __name__ == "__main__":
    scout_files()
