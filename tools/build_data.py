"""Generate Data/Retail.lua and Data/Forever.lua: profession spell-focus objects as map pins.

1. Which foci: every SpellFocusObject a profession recipe requires (SpellCastingRequirements
   joined with SkillLineAbility), per game build, from wago.tools DB2 exports.
2. Which objects: game objects of type 8 (SPELL_FOCUS) whose data0 is one of those foci, from
   an emulator world database (the client has no object templates): TrinityCore TDB for retail,
   cmangos classic-db for Forever. Decoration lookalikes are a different type and drop out.
3. Where: retail - each object's Wowhead page (g_mapperData, coords per uiMapId).
   Forever - classic Wowhead has no coordinates, so spawns come from the QuestieDB addon's
   Forever build (installed in the Forever client), with its Forever areaId -> uiMapId table.

Downloads are cached under tools/.cache (gitignored) and Wowhead requests are throttled.
Usage: python tools/build_data.py [--game retail|forever|both] [--questiedb DIR] [--tdb FILE]
"""
import argparse, base64, collections, csv, glob, json, os, re, struct, sys, time, urllib.error, urllib.parse, urllib.request, zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sqldump import table_rows  # noqa: E402
import watermark  # noqa: E402  (keyed coordinate watermark; see tools/watermark.py)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, 'tools', '.cache')
BUILDS = {'retail': '12.1.5.70783', 'forever': '1.60.1.70840'}
CMANGOS_URL = 'https://raw.githubusercontent.com/cmangos/classic-db/master/Full_DB/ClassicDB_1_12_1_z2815.sql.gz'
TDB_URL = 'https://github.com/TrinityCore/TrinityCore/releases/download/TDB1210.26091/TDB_full_1210.26091_2026_09_09.7z'
DEFAULT_QDB = r'C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\QuestieDB'
SEVENZIP = r'C:\Program Files\7-Zip\7z.exe'
UA = 'Mozilla/5.0'
DELAY = 1.5  # pause before each request; requests are sequential (0.5 s drew a 403 block)
SPELL_FOCUS = 8

PROFESSIONS = {164: 'blacksmithing', 165: 'leatherworking', 171: 'alchemy', 185: 'cooking',
               197: 'tailoring', 202: 'engineering', 333: 'enchanting', 755: 'jewelcrafting',
               773: 'inscription', 129: 'firstaid', 186: 'mining', 182: 'herbalism',
               393: 'skinning', 356: 'fishing', 794: 'archaeology'}
# Category keys must match CATEGORIES in Core.lua.
CATEGORIES = ['anvil', 'forge', 'cooking', 'moonwell', 'alchemy', 'tailoring', 'leatherworking',
              'engineering', 'jewelcrafting', 'enchanting', 'inscription', 'blacksmithing', 'special']


def log(*a):
    print(*a, flush=True)


def category(name, uses):
    n = name.lower()
    if 'anvil' in n: return 'anvil'
    if 'forge' in n or 'foundry' in n: return 'forge'
    if 'cooking fire' in n or 'oven' in n: return 'cooking'
    if 'moonwell' in n: return 'moonwell'
    prof, count = uses.most_common(1)[0]
    if count * 2 > sum(uses.values()) and prof in CATEGORIES: return prof
    return 'special'


def download(url, path, delay=DELAY):
    if os.path.exists(path): return path
    os.makedirs(os.path.dirname(path), exist_ok=True)
    for attempt in range(5):
        time.sleep(delay * (1 + attempt * 3))
        try:
            req = urllib.request.Request(url, headers={'User-Agent': UA})
            with urllib.request.urlopen(req, timeout=300) as r, open(path + '.part', 'wb') as f:
                while chunk := r.read(1 << 20): f.write(chunk)
            os.replace(path + '.part', path)
            return path
        except urllib.error.HTTPError as e:
            if e.code == 404:  # no such page: cache the miss so reruns skip it
                open(path, 'wb').close()
                return path
            if e.code in (403, 429):  # the site is refusing us: stop, resume later; cached pages keep
                raise SystemExit(f'{url}: HTTP {e.code}; stopped. Rerun later (cached pages are kept) '
                                 'or build from the cache with --offline.')
            log(f'  retry {attempt + 1} {url}: {e}')
        except Exception as e:  # timeouts and resets: back off and retry
            log(f'  retry {attempt + 1} {url}: {e}')
    raise SystemExit(f'giving up on {url}')


def text(url, path, delay=None):
    return open(download(url, path, DELAY if delay is None else delay), encoding='utf-8', errors='replace').read()


def db2(table, build, locale=None):
    query = f'build={build}' + (f'&locale={locale}' if locale else '')
    suffix = f'-{locale}' if locale else ''
    path = download(f'https://wago.tools/db2/{table}/csv?{query}',
                    os.path.join(CACHE, 'wago', f'{table}-{build}{suffix}.csv'), delay=0.5)
    return list(csv.DictReader(open(path, encoding='utf-8')))


# Every non-English client locale; enGB clients read the English names.
LOCALES = ['deDE', 'esES', 'esMX', 'frFR', 'itIT', 'koKR', 'ptBR', 'ruRU', 'zhCN', 'zhTW']


# ruRU stores many focus names as the requirement phrase ("находиться рядом с наковальней", "be
# next to the anvil"); these are the nominative names, keyed by English name. Machine-made.
RU_NAMES = {
    'Alchemy Lab': 'Алхимическая лаборатория', 'Altar of Shadows': 'Алтарь Теней',
    'Anvil': 'Наковальня', 'Anvil of the Thunder Forges': 'Наковальня Кузни Грома',
    'Black Anvil': 'Черная наковальня', 'Black Forge': 'Черная кузня',
    'Cooking Fire': 'Очаг для приготовления пищи', 'Forge': 'Горн',
    'Ghostly Cooking Fire': 'Призрачный очаг', 'Icebellow Anvil': 'Наковальня Ледяного грохота',
    'Loom': 'Ткацкий станок', 'Madam Goya': 'Мадам Гойя', 'Moonwell': 'Лунный колодец',
    "Crusader's Loom": 'Рыцарский ткацкий станок', "Crusader's Tanning Rack": 'Рыцарская дубильная стойка',
    'Iron Oven': 'Железная печь', 'Radiant Forge': 'Сияющий горн',
}


def localized_names(build, foci):
    """The game's own translations: ({focus id: {locale: name}}, {locale: {profession key: name}})."""
    focus_names, prof_names = collections.defaultdict(dict), {}
    for loc in LOCALES:
        for r in db2('SpellFocusObject', build, loc):
            fid, name = int(r['ID']), r['Name_lang'].strip()
            if fid not in foci: continue
            if loc == 'ruRU' and foci[fid][0] in RU_NAMES:
                name = RU_NAMES[foci[fid][0]]
            name = name[:1].upper() + name[1:]  # some locales store names lowercase
            if name and name != foci[fid][0]:
                focus_names[fid][loc] = name
            if loc == 'ruRU' and name.lower().startswith('находиться'):
                raise SystemExit(f'ruRU requirement phrase for {foci[fid][0]!r}: add it to RU_NAMES')
        lines = {int(r['ID']): r['DisplayName_lang'].strip() for r in db2('SkillLine', build, loc)}
        prof_names[loc] = {key: lines[sid] for sid, key in PROFESSIONS.items() if lines.get(sid)}
    return focus_names, prof_names


def profession_foci(build):
    """{focus id: (focus name, category)} for foci a profession recipe requires in this build."""
    lines = {int(r['ID']): r for r in db2('SkillLine', build)}

    def root(i):
        for _ in range(6):
            parent = int(lines.get(i, {}).get('ParentSkillLineID') or 0)
            if not parent: break
            i = parent
        return i

    spell_prof = {}
    for r in db2('SkillLineAbility', build):
        prof = PROFESSIONS.get(root(int(r['SkillLine'])))
        if prof: spell_prof[int(r['Spell'])] = prof
    names = {int(r['ID']): r['Name_lang'].strip() for r in db2('SpellFocusObject', build)}
    uses = collections.defaultdict(collections.Counter)
    for r in db2('SpellCastingRequirements', build):
        focus, spell = int(r['RequiresSpellFocus'] or 0), int(r['SpellID'])
        if focus and spell in spell_prof and names.get(focus):
            uses[focus][spell_prof[spell]] += 1
    return {f: (names[f], category(names[f], u), u) for f, u in uses.items()}


def listed_professions(uses):
    """Professions a focus is listed under in the options: the main user, plus any profession
    with at least two recipes needing it (one stray recipe is noise)."""
    top = uses.most_common(1)[0][0]
    return sorted((p for p, n in uses.items() if p == top or n >= 2), key=lambda p: -uses[p])


def focus_objects(dump, foci):
    """{object id: (object name, focus id)} for type-8 templates pointing at a profession focus."""
    out = {}
    for cols, row in table_rows(dump, 'gameobject_template'):
        c = {k.lower(): i for i, k in enumerate(cols)}
        if row[c['type']] == SPELL_FOCUS and row[c['data0']] in foci:
            out[row[c['entry']]] = (row[c['name']].strip(), row[c['data0']])
    return out


def spawned_ids(dump):
    ids = set()
    for cols, row in table_rows(dump, 'gameobject'):
        ids.add(row[cols.index('id')])
    return ids


def coord(x, y):
    """Percent coordinates -> HandyNotes coord (what HandyNotes:getCoord makes of 0-1 values)."""
    return int(round(x * 100)) * 10000 + int(round(y * 100))


# ---------------------------------------------------------------- retail (TDB + Wowhead)

def tdb_world_sql(archive):
    out = os.path.join(CACHE, 'tdb')
    found = glob.glob(os.path.join(out, 'TDB_full_world_*.sql'))
    if not found:
        import subprocess
        subprocess.run([SEVENZIP, 'e', '-y', f'-o{out}', archive, 'TDB_full_world_*.sql', '-r'], check=True,
                       stdout=subprocess.DEVNULL)
        found = glob.glob(os.path.join(out, 'TDB_full_world_*.sql'))
    if len(found) != 1: raise SystemExit(f'expected one TDB_full_world_*.sql in {out}, found {found}')
    return found[0]


def wowhead_located(candidates, objects, offline):
    """Candidates worth a page fetch. Most TDB objects have no retail Wowhead page (404), so one
    name search per object name keeps ids Wowhead lists with a location; a search that hit the
    1000-row cap cannot rule anything out, so its names keep every candidate. Offline, ids
    whose search is not cached are kept and counted as pending by the caller."""
    by_name = collections.defaultdict(list)
    for oid in candidates:
        by_name[objects[oid][0]].append(oid)
    keep = []
    for name, ids in sorted(by_name.items()):
        path = os.path.join(CACHE, 'wowhead-search', re.sub(r'[^a-z0-9]+', '_', name.lower()) + '.html')
        if not name or (offline and not os.path.exists(path)):
            keep += ids
            continue
        rows = listview_data(text('https://www.wowhead.com/objects/name:' + urllib.parse.quote(name), path))
        if len(rows) >= 1000:
            keep += ids
            continue
        located = {r['id'] for r in rows if r.get('location')}
        keep += [oid for oid in ids if oid in located]
    return sorted(keep)


def listview_data(html):
    m = re.search(r'"data":\s*\[', html)
    if not m: return []
    data, _ = json.JSONDecoder().raw_decode(html[m.end() - 1:])
    return data


def build_retail(foci, tdb, offline=False):
    world = tdb_world_sql(tdb or download(TDB_URL, os.path.join(CACHE, 'tdb', os.path.basename(TDB_URL))))
    objects = focus_objects(world, foci)
    spawned = spawned_ids(world)
    log(f'retail: {len(objects)} focus templates, {sum(1 for o in objects if o in spawned)} spawned in TDB')
    pins, found = collections.defaultdict(dict), 0
    candidates = sorted(o for o in objects if o in spawned)  # unspawned templates have nothing to locate
    ids = wowhead_located(candidates, objects, offline)
    pending = 0
    for i, oid in enumerate(ids):
        page = os.path.join(CACHE, 'wowhead', f'{oid}.html')
        if offline and not os.path.exists(page):
            pending += 1
            continue
        html = text(f'https://www.wowhead.com/object={oid}', os.path.join(CACHE, 'wowhead', f'{oid}.html'))
        m = re.search(r'g_mapperData\s*=\s*(\{.*?\});\s*\n', html)
        if m:
            found += 1
            for zone in json.loads(m.group(1)).values():
                # A floor-keyed dict (old multi-level zones) carries no uiMapId and is skipped below.
                for floor in (zone.values() if isinstance(zone, dict) else zone):
                    mid = floor.get('uiMapId')
                    for x, y in (floor.get('coords') or []) if mid else []:
                        pins[int(mid)][coord(x, y)] = objects[oid]
        if i % 100 == 0: log(f'  wowhead {i}/{len(ids)}')
    partial = f', PARTIAL: {pending} objects not fetched yet' if pending else ''
    return pins, f'TrinityCore TDB 12.1.0 templates + Wowhead coordinates, {found} of {len(ids)} objects located{partial}'


# ---------------------------------------------------------------- forever (cmangos + QuestieDB)

def cbor(b, i=0):
    ib = b[i]; mt, ai = ib >> 5, ib & 31; i += 1
    if mt == 7 and ai in (25, 26, 27):
        if ai == 25:
            h = struct.unpack('>H', b[i:i + 2])[0]
            s, e, f = h >> 15, (h >> 10) & 31, h & 1023
            v = f / 1024 * 2 ** -14 if e == 0 else (1 + f / 1024) * 2 ** (e - 15)
            return (-v if s else v), i + 2
        n = 4 if ai == 26 else 8
        return struct.unpack('>f' if ai == 26 else '>d', b[i:i + n])[0], i + n
    if ai < 24: val = ai
    elif ai == 24: val, i = b[i], i + 1
    elif ai == 25: val, i = struct.unpack('>H', b[i:i + 2])[0], i + 2
    elif ai == 26: val, i = struct.unpack('>I', b[i:i + 4])[0], i + 4
    elif ai == 27: val, i = struct.unpack('>Q', b[i:i + 8])[0], i + 8
    else: raise ValueError('indefinite CBOR length')
    if mt == 0: return val, i
    if mt == 1: return -1 - val, i
    if mt in (2, 3): return b[i:i + val].decode('utf-8', 'replace'), i + val
    if mt == 4:
        out = []
        for _ in range(val):
            v, i = cbor(b, i); out.append(v)
        return out, i
    if mt == 5:
        out = {}
        for _ in range(val):
            k, i = cbor(b, i); v, i = cbor(b, i); out[k] = v
        return out, i
    if mt == 6: return cbor(b, i)
    return {20: False, 21: True, 22: None}.get(val), i


def build_forever(foci, qdb):
    cm = download(CMANGOS_URL, os.path.join(CACHE, 'cmangos', os.path.basename(CMANGOS_URL)))
    objects = focus_objects(cm, foci)
    meta = {}
    with open(os.path.join(qdb, 'QuestieDB_Forever.toc'), encoding='utf-8', errors='replace') as f:
        for line in f:
            if line.startswith('## X-Object') or line.startswith('## Version:'):
                k, v = line[3:].split(':', 1)
                meta[k.strip()] = v.strip()

    def stored(key):
        v = meta.get(key)
        m = v and re.fullmatch(r'~(\d+)~', v)
        if m: v = ''.join(meta[f'{key}-{n}'] for n in range(1, int(m.group(1)) + 1))
        return v

    src = open(os.path.join(qdb, 'support', 'Forever', 'Zones', 'areaIdToUiMapId.lua'), encoding='utf-8').read()
    area = {}
    for block in re.findall(r'\[\[return \{(.*?)\}\]\]', src, re.S):  # override block first, then the DBC map
        for a, u in re.findall(r'\[(\d+)\]\s*=\s*(\d+)', block):
            area.setdefault(int(a), int(u))
    pins, used, missing, unmapped = collections.defaultdict(dict), 0, [], collections.Counter()
    for oid in sorted(objects):
        sp = stored(f'X-Object-{oid}-4')
        if not sp:
            missing.append(oid); continue
        spawns = cbor(base64.b64decode(sp))[0]
        used += 1
        for zone, points in (spawns.items() if isinstance(spawns, dict) else enumerate(spawns, 1)):
            mid = area.get(int(zone))
            if not mid:
                unmapped[int(zone)] += len(points or []); continue
            for p in points or []:
                if p and p[0] >= 0 and p[1] >= 0:
                    pins[mid][coord(p[0], p[1])] = objects[oid]
    log(f'forever: {len(objects)} focus templates in cmangos, {used} with QuestieDB spawns, {len(missing)} without')
    if unmapped: log(f'  areas with no uiMap (skipped): {dict(unmapped)}')
    return pins, f'cmangos classic-db templates + QuestieDB {meta.get("Version", "?")} (Forever) spawns, {used} objects'


# ---------------------------------------------------------------- output

def lua_names(names):
    return ', '.join('%s=%s' % (loc, json.dumps(names[loc], ensure_ascii=False)) for loc in LOCALES if loc in names)


def lua_names_by_key(names):
    return ', '.join('%s=%s' % (k, json.dumps(names[k], ensure_ascii=False)) for k in sorted(names))


def write_lua(game, pins, foci, source, focus_names, prof_names):
    # Every profession focus of this game is listed, pinned or not, so each one has its own
    # toggle and can be recorded in game.
    focus_ids = sorted(foci, key=lambda f: foci[f][0].casefold())
    focus_index = {f: i + 1 for i, f in enumerate(focus_ids)}
    kinds = sorted({k for m in pins.values() for k in m.values()}, key=lambda k: (foci[k[1]][0], k[0]))
    index = {k: i + 1 for i, k in enumerate(kinds)}
    guard = 'if not ns.IS_FOREVER then return end' if game == 'forever' else 'if ns.IS_FOREVER then return end'
    out = ['-- GENERATED by tools/build_data.py; do not edit.',
           'local _, ns = ...', guard, '',
           'ns.seedSource = %s' % json.dumps(source),
           '-- The game\'s own profession names per client locale (SkillLine); English is Core.lua PROFESSIONS.',
           'ns.professionNames = {']
    for loc in LOCALES:
        out.append('\t%s = { %s },' % (loc, lua_names_by_key(prof_names.get(loc, {}))))
    out += ['}',
            '-- index -> station type: English name (the settings key), the game\'s names per locale,',
            '-- icon category (Core.lua CATEGORIES), and recipes needing it per profession (Core.lua',
            '-- PROFESSIONS), listed under each of those professions',
            'ns.foci = {']
    for f in focus_ids:
        name, cat, uses = foci[f]
        profs = ', '.join('%s=%d' % (p, uses[p]) for p in listed_professions(uses))
        out.append('\t{ name = %s, names = { %s }, category = "%s", recipes = { %s } },' % (
            json.dumps(name), lua_names(focus_names.get(f, {})), cat, profs))
    out += ['}', '-- index -> { object name, ns.foci index }', 'ns.seedKinds = {']
    out += ['\t{ %s, %d },' % (json.dumps(k[0]), focus_index[k[1]]) for k in kinds]
    out += ['}', '-- uiMapID -> { [HandyNotes coord] = kind index }', 'ns.seed = {']
    total = 0
    for mid in sorted(pins):
        entries = sorted(pins[mid].items())
        total += len(entries)
        out.append('\t[%d] = { %s },' % (mid, ', '.join('[%d]=%d' % (c, index[k]) for c, k in entries)))
    out.append('}')
    path = os.path.join(ROOT, 'Data', game.capitalize() + '.lua')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(out) + '\n')
    per_cat = collections.Counter(foci[k[1]][1] for m in pins.values() for k in m.values())
    log(f'{game}: {total} pins on {len(pins)} maps, {len(kinds)} kinds -> {path}\n  {dict(per_cat)}')


def main():
    global DELAY
    ap = argparse.ArgumentParser()
    ap.add_argument('--game', choices=['retail', 'forever', 'both'], default='both')
    ap.add_argument('--questiedb', default=DEFAULT_QDB)
    ap.add_argument('--tdb', help='local TDB_full_*.7z (downloaded otherwise)')
    ap.add_argument('--offline', action='store_true', help='retail: use cached Wowhead pages only')
    ap.add_argument('--delay', type=float, default=DELAY, help='seconds to pause before each request')
    a = ap.parse_args()
    DELAY = a.delay
    for game in (['retail', 'forever'] if a.game == 'both' else [a.game]):
        foci = profession_foci(BUILDS[game])
        log(f'{game}: {len(foci)} profession foci')
        pins, source = build_retail(foci, a.tdb, a.offline) if game == 'retail' else build_forever(foci, a.questiedb)
        write_lua(game, watermark.apply(pins), foci, source, *localized_names(BUILDS[game], foci))


if __name__ == '__main__':
    main()
