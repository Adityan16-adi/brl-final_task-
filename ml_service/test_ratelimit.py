from ratelimit import SlidingWindowLimiter


def test_allows_up_to_limit_then_blocks():
    lim = SlidingWindowLimiter(limit=3, window=60)
    assert [lim.hit("a", now=100 + i) for i in range(3)] == [None, None, None]
    wait = lim.hit("a", now=103)
    assert wait is not None and 1 <= wait <= 60


def test_window_slides():
    lim = SlidingWindowLimiter(limit=2, window=10)
    lim.hit("a", now=0)
    lim.hit("a", now=1)
    assert lim.hit("a", now=5) is not None   # still inside the window
    assert lim.hit("a", now=11) is None      # first hit expired


def test_callers_are_independent():
    lim = SlidingWindowLimiter(limit=1, window=60)
    assert lim.hit("a", now=0) is None
    assert lim.hit("b", now=0) is None
    assert lim.hit("a", now=1) is not None


def test_limit_zero_disables():
    lim = SlidingWindowLimiter(limit=0, window=60)
    assert all(lim.hit("a", now=i) is None for i in range(100))


def test_old_keys_are_swept():
    lim = SlidingWindowLimiter(limit=5, window=10)
    lim.hit("a", now=0)
    lim.hit("b", now=100)   # triggers a sweep, "a" is long expired
    assert "a" not in lim._hits