from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent

def read_mif(name, count, bits, signed=False):
    text = (ROOT / name).read_text()
    entries = {int(a): int(v, 16) for a, v in re.findall(r'^\s*(\d+)\s*:\s*([0-9A-Fa-f]+)\s*;', text, re.M)}
    if set(entries) != set(range(count)):
        raise ValueError(f'{name}: missing or unexpected addresses')
    values = [entries[i] for i in range(count)]
    if any(v >= 1 << bits for v in values):
        raise ValueError(f'{name}: value exceeds width')
    if signed:
        values = [v - (1 << bits) if v >= 1 << (bits-1) else v for v in values]
    return values

image = read_mif('image.mif', 64, 8)
params = read_mif('weights.mif', 410, 16, signed=True)
expected = []
for f in range(4):
    print(f'Filter {f+1}:')
    for r in range(6):
        row = []
        for c in range(6):
            total = params[36+f] << 8
            for kr in range(3):
                for kc in range(3):
                    total += image[(r+kr)*8+c+kc] * params[f*9+kr*3+kc]
            row.append(max(0, min(32767, total >> 8)))
        expected.extend(row)
        print(row)
(ROOT / 'expected_conv.hex').write_text(''.join(f'{v:04X}\n' for v in expected))
print(f'Wrote {len(expected)} values to expected_conv.hex')
