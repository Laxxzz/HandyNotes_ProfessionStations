#!/usr/bin/env python3
"""Keyed watermark for the seeded pin coordinates (ns.seed in Data/*.lua).

Each HandyNotes coord is xxxxyyyy (percent * 100). Only the decimals of x and y change, by
1..9 hundredths (<= 0.09), e.g. 40.70 -> 40.73 or 47.89 -> 47.96 (may cross the first decimal
or the whole percent). The change is a keyed per-axis permutation (secret key, map, axis) with no
fixed points, so every pin moves, two pins can never collide, and the whole transform can be
undone with the key. The key never enters the repo.

  python tools/watermark.py                apply to Data/*.lua in place (once per generated file)
  python tools/watermark.py --check FILE   count how many pins of a suspect Lua file carry this
                                           watermark vs. the unmarked source coordinates
build_data.py applies the same transform before writing, so regenerated data stays marked.
"""
import functools, glob, hashlib, hmac, json, os, re, secrets, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_FILE = os.environ.get('PSTATIONS_WATERMARK_FILE') or os.path.join(os.path.expanduser('~'), '.pstations-watermark.json')


def _state(create=True):
    try:
        with open(KEY_FILE, encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        if not create:
            raise SystemExit(f'no watermark key at {KEY_FILE}')
        state = {'key': secrets.token_hex(32), 'applied': []}
        _save(state)
        print(f'watermark: created new key file {KEY_FILE} (back it up; it is the only proof of ownership)', file=sys.stderr)
        return state


def _save(state):
    with open(KEY_FILE, 'w', encoding='utf-8') as f:
        json.dump(state, f, indent=1)


SPAN = 10000  # one axis: 0.00 .. 99.99 in hundredths


@functools.lru_cache(maxsize=None)
def _perm(key, mid, axis):
    """Permutation of one whole axis (0..9999 hundredths) for (map, axis), and its inverse.

    The axis is cut into keyed runs of 2..10 consecutive values, and each run is deranged
    (no value stays put). A value therefore moves by 1..9 hundredths (<= 0.09), may cross a
    tenth or whole-percent boundary, and the map is bijective by construction.
    """
    kb = bytes.fromhex(key)
    perm, pos = [0] * SPAN, 0
    while pos < SPAN:
        size = 2 + hmac.digest(kb, f'{mid}|{axis}|{pos}|size'.encode(), 'sha256')[0] % 9
        if SPAN - pos - size == 1:
            size += 1 if size < 10 else -1
        size = min(size, SPAN - pos)
        for t in range(10000):
            rnd = hmac.digest(kb, f'{mid}|{axis}|{pos}|run|{t}'.encode(), 'sha256')
            order = sorted(range(size), key=lambda d: (rnd[d], d))
            if all(order[d] != d for d in range(size)):
                break
        else:
            raise RuntimeError('no derangement found')
        for d in range(size):
            perm[pos + d] = pos + order[d]
        pos += size
    inv = [0] * SPAN
    for i, j in enumerate(perm):
        inv[j] = i
    return tuple(perm), tuple(inv)


def _digit(key, mid, axis, half, inverse):
    return _perm(key, mid, axis)[1 if inverse else 0][half]


def transform(key, mid, coord, inverse=False):
    x, y = divmod(coord, 10000)
    return _digit(key, mid, 'x', x, inverse) * 10000 + _digit(key, mid, 'y', y, inverse)


def apply(pins, inverse=False, key=None):
    """pins: {uiMapID: {coord: value}} -> same shape with watermarked coords."""
    key = key or _state()['key']
    out = {}
    for mid, entries in pins.items():
        moved = {transform(key, mid, c, inverse): v for c, v in entries.items()}
        assert len(moved) == len(entries), 'coordinate collision'
        out[mid] = moved
    return out


# ---------------------------------------------------------------- Lua files

MAP = re.compile(r'^(\t\[(\d+)\] = \{ )(.*)( \},)$')
PIN = re.compile(r'\[(\d+)\]=(\d+)')


def rewrite_lua(text, key):
    lines, in_seed, n = text.split('\n'), False, 0
    for i, raw in enumerate(lines):
        line, cr = raw.rstrip('\r'), raw[len(raw.rstrip('\r')):]  # keep CRLF checkouts intact
        if line == 'ns.seed = {':
            in_seed = True
        elif in_seed and line == '}':
            in_seed = False
        elif in_seed and (m := MAP.match(line)):
            mid = int(m.group(2))
            pins = {int(c): int(k) for c, k in PIN.findall(m.group(3))}
            new = apply({mid: pins}, key=key)[mid]
            lines[i] = m.group(1) + ', '.join('[%d]=%d' % (c, k) for c, k in sorted(new.items())) + m.group(4) + cr
            n += len(pins)
    return '\n'.join(lines), n


def seed_pins(text):
    """{uiMapID: set(coords)} from any Lua text shaped like ns.seed."""
    pins, mid = {}, None
    for line in text.split('\n'):
        m = re.match(r'\s*\[(\d+)\]\s*=\s*\{', line)
        if m:
            mid = int(m.group(1))
            pins.setdefault(mid, set()).update(int(c) for c, _ in PIN.findall(line))
    return pins


def check(path):
    key = _state(False)['key']
    with open(path, encoding='utf-8') as f:
        suspect = seed_pins(f.read())
    total = marked = plain = 0
    for mid, coords in suspect.items():
        for c in coords:
            total += 1
            marked += c in _bundled(key).get(mid, ())
            plain += c in _bundled(key, plain=True).get(mid, ())
    print(f'{total} pins: {marked} match the watermarked data, {plain} match the unmarked source coords')
    print('Many marked matches (and few plain ones) = copied from this data; ~1% marked by chance.')


@functools.lru_cache(maxsize=None)
def _bundled(key, plain=False):
    pins = {}
    for path in glob.glob(os.path.join(ROOT, 'Data', '*.lua')):
        with open(path, encoding='utf-8') as f:
            for mid, coords in seed_pins(f.read()).items():
                pins.setdefault(mid, set()).update(coords)
    if plain:
        pins = {mid: {transform(key, mid, c, inverse=True) for c in coords} for mid, coords in pins.items()}
    return pins


def main():
    if len(sys.argv) == 3 and sys.argv[1] == '--check':
        return check(sys.argv[2])
    if len(sys.argv) != 1:
        raise SystemExit(__doc__)
    state = _state()
    for path in sorted(glob.glob(os.path.join(ROOT, 'Data', '*.lua'))):
        with open(path, encoding='utf-8', newline='') as f:
            text = f.read()
        digest = hashlib.sha256(text.encode('utf-8')).hexdigest()
        if digest in state['applied']:
            print(f'{os.path.basename(path)}: already watermarked, skipped')
            continue
        new, n = rewrite_lua(text, state['key'])
        if not n:
            raise SystemExit(f'{path}: no ns.seed pins found; file left untouched')
        with open(path, 'w', encoding='utf-8', newline='') as f:
            f.write(new)
        state['applied'].append(hashlib.sha256(new.encode('utf-8')).hexdigest())
        _save(state)
        print(f'{os.path.basename(path)}: {n} pins moved')


if __name__ == '__main__':
    main()
