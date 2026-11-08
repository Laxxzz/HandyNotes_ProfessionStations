"""Stream rows of one table out of a MySQL dump (cmangos / TrinityCore), without a database."""
import gzip, re

_TOKEN = re.compile(r"\s*(?:'((?:[^'\\]|\\.)*)'|(NULL)|([-+0-9.eE]+))\s*(,|\))")


def _rows(values):
    i, n = 0, len(values)
    while i < n:
        j = values.find('(', i)
        if j < 0: return
        i, row = j + 1, []
        while True:
            m = _TOKEN.match(values, i)
            if not m: raise ValueError('cannot parse near: ' + values[i:i + 80])
            s, null, num, end = m.groups()
            if s is not None:
                row.append(re.sub(r'\\(.)', r'\1', s))
            elif null:
                row.append(None)
            else:
                row.append(float(num) if any(c in num for c in '.eE') else int(num))
            i = m.end()
            if end == ')': break
        yield row


def table_rows(path, table, opener=None):
    """Yield (columns, row) for `table` from a .sql or .sql.gz dump."""
    open_ = opener or (gzip.open if path.endswith('.gz') else open)
    columns, create = [], False
    with open_(path, 'rt', encoding='utf-8', errors='replace') as f:
        for line in f:
            if line.startswith(f'CREATE TABLE `{table}`'):
                create, columns = True, []
                continue
            if create:
                m = re.match(r'\s*`([^`]+)`', line)
                if m: columns.append(m.group(1))
                if line.startswith(')'): create = False
                continue
            if line.startswith(f'INSERT INTO `{table}` VALUES'):
                for row in _rows(line[line.index('VALUES') + 6:]):
                    yield columns, row
