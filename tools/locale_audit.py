"""Check the locale files against the code: every T["..."] key and every Plural `other` text the
code uses must be translated in each Locale/*.lua, and no locale may keep a key the code no
longer uses. Exit 1 on any gap. Usage: python tools/locale_audit.py"""
import glob, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CODE = ['Core.lua', 'Plugin.lua']
STRING = r'"((?:[^"\\]|\\.)*)"'


def code_keys():
    keys = set()
    for name in CODE:
        src = open(os.path.join(ROOT, name), encoding='utf-8').read()
        keys.update(re.findall(r'T\[' + STRING + r'\]', src))
        for block in re.findall(r'Plural\(\{(.*?)\}\)', src, re.S):
            m = re.search(r'other\s*=\s*' + STRING, block)
            if m: keys.add(m.group(1))
    return keys


def main():
    want, bad = code_keys(), 0
    files = sorted(glob.glob(os.path.join(ROOT, 'Locale', '*.lua')))
    for path in files:
        src = open(path, encoding='utf-8').read()
        have = set(re.findall(r'^\t\[' + STRING + r'\]\s*=', src, re.M))
        missing, stale = sorted(want - have), sorted(have - want)
        for k in missing: print(f'{os.path.basename(path)}: missing {k!r}')
        for k in stale: print(f'{os.path.basename(path)}: stale {k!r}')
        bad += len(missing) + len(stale)
    print(f'{len(want)} keys, {len(files)} locales, {bad} problem(s)')
    sys.exit(1 if bad or len(files) != 10 else 0)


if __name__ == '__main__':
    main()
