import sys
from datetime import datetime, timedelta

sys.path.append(".")
from src.evt_seq import util as evt_seq


def test_empty():
    seqs = evt_seq.extract_sequences([], verbose=False)
    assert seqs == []


def test_simple_uniform():
    N = 5
    t = datetime.now()
    L = timedelta(minutes=10)
    g = timedelta(minutes=3)

    rows = []
    for k in range(N):
        ts = t + k * (L + g)  # start to start
        rows.append((chr(97 + k), ts, ts + L))

    seqs = evt_seq.extract_sequences(rows, max_gap=timedelta(minutes=1), verbose=False)
    assert seqs == [[chr(97 + k)] for k in range(N)], "should get N of length 1"
    seqs = evt_seq.extract_sequences(
        rows, max_gap=timedelta(minutes=1), min_len=2, verbose=False
    )
    assert seqs == [], "should get nothing when min length"

    seqs = evt_seq.extract_sequences(rows, max_gap=timedelta(minutes=3), verbose=False)
    assert seqs == [[chr(97 + k) for k in range(N)]], "should get 1 of length N"
