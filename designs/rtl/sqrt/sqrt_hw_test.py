import os
import sys

sys.path.insert(
    0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "udm", "sw")
)

from udm import udm
from sqrt_vectors import make_vectors

CSR_SQRT_X_ADDR = 0x10000000
CSR_SQRT_Y_ADDR = 0x20000000
BAUDRATE = 921600


def connect(port):
    print(f"connecting to {port} at {BAUDRATE} baud")
    return udm(port, BAUDRATE)


def check_sqrt(dev, x, y_exp):
    dev.wr32(CSR_SQRT_X_ADDR, x)
    y = dev.rd32(CSR_SQRT_Y_ADDR)
    ok = y == y_exp
    print(
        f"{'OK   ' if ok else 'ERROR'} x: 0x{x:08x}, y: 0x{y:08x}, expected: 0x{y_exp:08x}"
    )
    return ok


def run_tests(dev):
    vectors = make_vectors()
    errors = sum(not check_sqrt(dev, x, y) for x, y in vectors)
    print(f"### SQRT: {len(vectors)} checks, {errors} errors ###")
    return errors


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: python3 sqrt_hw_test.py <port>   (e.g. /dev/ttyUSB1)")
    dev = connect(sys.argv[1])
    errors = run_tests(dev)
    dev.disconnect()
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
