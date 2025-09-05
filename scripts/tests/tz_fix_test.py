from datetime import datetime
import sys
import polars as pl

sys.path.append(".")
from scripts import tz_fix


if __name__ == "__main__":
    df = pl.DataFrame(
        [
            {"name": "summer", "start": datetime.fromisoformat("2025-06-13T15:34:20")},
            {"name": "winter", "start": datetime.fromisoformat("2025-01-13T15:34:20")},
        ]
    )

    df2 = tz_fix.tz_local_to_utc(df, tz="Europe/Stockholm", cols=("start",))

    print(df)
    print(df2)

    assert df2["start"].dt.hour().to_list() == [15, 15], "shouldnt change start hour"
    assert df2["start_utc"].dt.hour().to_list() == [13, 14], "should shift 2,1 h"
    assert df2["start_offset"].to_list() == [2 * 3600, 3600], "offset: 2,1 h"
