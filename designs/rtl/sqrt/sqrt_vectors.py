import random
from sqrt_model import sqrt_alg, sqrt_hw

EDGE = [
    0,
    1,
    2,
    3,
    4,
    15,
    16,
    17,
    99,
    100,
    255,
    256,
    65535,
    65536,
    0x7FFFFFFF,
    0x80000000,
    0xFFFE0000,
    0xFFFE0001,
    0xFFFFFFFF,
]


def make_vectors():
    rnd = random.Random(6)
    xs = EDGE + [rnd.getrandbits(32) for _ in range(16)]
    for x in xs:
        assert sqrt_hw(x) == sqrt_alg(x), hex(x)
    return [(x, sqrt_hw(x)) for x in xs]


if __name__ == "__main__":
    for x, y in make_vectors():
        print(f"    check_sqrt(32'h{x:08x}, 32'h{y:08x});")
