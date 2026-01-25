#!/usr/bin/env python3
"""
Compare two neighbour-list dumps (before / inside shrink-graph, pre / post).
"""

import argparse
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional
from collections import defaultdict

# ────────────────  REGEXES  ────────────────────────────────────────────────
# now also accepts “(block N)” after the id
DP_RE = re.compile(
    r'^\s*datapoint\s+(\d+)(?:\s*\(block\s+\d+\))?\s*$', re.I
)
HDR_WITH_SIZE = re.compile(
    r'^\s*(old|new)\s+(forward|reverse)\s+\((\d+)\):\s*(.*)$', re.I
)
HDR_NO_SIZE = re.compile(
    r'^\s*(old|new)_(pre|post)\s*:\s*(.*)$', re.I
)

# ────────────────  PARSER  ────────────────────────────────────────────────
def parse_file(path: Path) -> Tuple[Dict[int, dict], Dict[int, List[str]]]:
    data:  Dict[int, dict]      = {}
    lines: Dict[int, List[str]] = {}

    dp_id: Optional[int]        = None
    block: List[str]            = []

    pending_key: Optional[str]  = None
    declared_len: Optional[int] = None
    vals: List[int]             = []

    def flush_pending() -> None:
        nonlocal pending_key, declared_len, vals
        if pending_key is None:
            return          # nothing to do
        if dp_id is None:   # header before first “datapoint …” → ignore
            pending_key = None
            declared_len = None
            vals = []
            return

        non_zero = [v for v in vals if v != 0]
        data[dp_id][pending_key]          = set(non_zero)
        data[dp_id][pending_key + '_len'] = (
            declared_len if declared_len is not None else len(non_zero)
        )
        pending_key  = None
        declared_len = None
        vals         = []

    with path.open() as fh:
        for raw in fh:
            line = raw.rstrip('\n')

            # blank line
            if not line.strip():
                if dp_id is not None:
                    block.append(line)
                continue

            # datapoint header
            m = DP_RE.match(line)
            if m:
                flush_pending()
                if dp_id is not None:
                    lines[dp_id] = block
                dp_id = int(m.group(1))
                data[dp_id] = {}
                block = [line]
                continue

            # header with or without size
            m = HDR_WITH_SIZE.match(line) or HDR_NO_SIZE.match(line)
            if m:
                flush_pending()
                if len(m.groups()) == 4:          # HDR_WITH_SIZE
                    kind, direction, n_str, tail = m.groups()
                    declared_len = int(n_str)
                else:                             # HDR_NO_SIZE
                    kind, direction, tail = m.groups()
                    declared_len = None
                pending_key = f'{kind.lower()}_{direction.lower()}'
                vals = [int(x) for x in tail.split()] if tail else []
                block.append(line)
                continue

            # continuation line
            if pending_key:
                vals.extend(int(x) for x in line.split())
                block.append(line)
            elif dp_id is not None:               # unknown line inside block
                block.append(line)

    if dp_id is not None:
        flush_pending()
        lines[dp_id] = block

    return data, lines

# ────────────────  COMPARISON (unchanged)  ────────────────────────────────
def compare_dp(a: dict, b: dict, stats: defaultdict) -> List[str]:
    reasons: List[str] = []
    lists = {k for k in a.keys() | b.keys() if not k.endswith('_len')}
    for key in sorted(lists):
        len_a = a.get(key + '_len')
        len_b = b.get(key + '_len')
        if len_a is not None and len_b is not None and len_a != len_b:
            stats[key + '_len'] += 1
            reasons.append(f'{key} length {len_a} vs {len_b}')

        set_a: Set[int] = a.get(key, set())
        set_b: Set[int] = b.get(key, set())
        if set_a != set_b:
            stats[key + '_set'] += 1
            reasons.append(
                f'{key} set differs '
                f'(missing {sorted(set_a-set_b)}  extra {sorted(set_b-set_a)})'
            )
    return reasons

# ────────────────  MAIN  (unchanged)  ──────────────────────────────────────
def main() -> None:
    ap = argparse.ArgumentParser(description='Compare neighbour-dump files')
    ap.add_argument('fileA', type=Path)
    ap.add_argument('fileB', type=Path)
    args = ap.parse_args()

    dataA, linesA = parse_file(args.fileA)
    dataB, linesB = parse_file(args.fileB)

    stats  = defaultdict(int)
    out: List[str] = []

    for dp in sorted(set(dataA) | set(dataB)):
        if dp not in dataA or dp not in dataB:
            stats['missing_dp_' + ('fileA' if dp in dataB else 'fileB')] += 1
            out.append(f'\n▶ datapoint {dp} present only in '
                       f'{"fileA" if dp in dataA else "fileB"}\n')
            if dp in linesA:
                out.append('-- fileA ------------------------------\n')
                out.append('\n'.join(linesA[dp]) + '\n')
            if dp in linesB:
                out.append('-- fileB ------------------------------\n')
                out.append('\n'.join(linesB[dp]) + '\n')
            continue

        reasons = compare_dp(dataA[dp], dataB[dp], stats)
        if reasons:
            out.append(f'\n▶ datapoint {dp} differs:\n')
            out.extend('  - ' + r + '\n' for r in reasons)
            out.append('-- fileA ------------------------------\n')
            out.append('\n'.join(linesA[dp]) + '\n')
            out.append('-- fileB ------------------------------\n')
            out.append('\n'.join(linesB[dp]) + '\n')

    if not out:
        print('✔  dumps are identical (sizes & sets)')
        return

    print('Summary of differences:')
    for k in sorted(stats):
        print(f'  {k:<22}: {stats[k]}')
    print('\nDetailed mismatch list follows:')
    print(''.join(out), end='')

if __name__ == '__main__':
    main()
