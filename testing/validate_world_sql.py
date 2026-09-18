#!/usr/bin/env python
"""Validate the world.sql test fixture.

The E2E test (testing/phpmyadmin_test.py) asserts that importing
testing/world.sql executes exactly 5326 queries. This script fails fast if the
fixture drifts from the expected shape so the import test reports a clear
error instead of a confusing UI assertion.

Usage: python testing/validate_world_sql.py [path-to-world.sql]
Exit code 0 when the fixture matches expectations, 1 otherwise.
"""

import os
import re
import sys

EXPECTED_INSERTS = 5302
EXPECTED_STATEMENTS = 5326

INSERT_RE = re.compile(r'^\s*INSERT INTO', re.IGNORECASE)
STATEMENT_RE = re.compile(r';\s*$')


def count_inserts(path):
    count = 0
    with open(path, 'r') as handle:
        for line in handle:
            if INSERT_RE.match(line):
                count += 1
    return count


def count_statements(path):
    count = 0
    with open(path, 'r') as handle:
        for line in handle:
            if STATEMENT_RE.search(line):
                count += 1
    return count


def main():
    if len(sys.argv) > 1:
        path = sys.argv[1]
    else:
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'world.sql')

    inserts = count_inserts(path)
    statements = count_statements(path)

    print('world.sql: {0} INSERT statements, {1} total statements'.format(inserts, statements))
    print('expected:  {0} INSERT statements, {1} total statements'.format(
        EXPECTED_INSERTS, EXPECTED_STATEMENTS))

    if inserts != EXPECTED_INSERTS:
        print('ERROR: INSERT statement count drifted from the expected fixture shape!')
        return 1
    if statements != EXPECTED_STATEMENTS:
        print('ERROR: total statement count drifted from the expected fixture shape!')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())