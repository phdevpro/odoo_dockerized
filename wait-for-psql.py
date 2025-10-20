#!/usr/bin/env python3
import argparse
import sys
import time

try:
    import psycopg2  # provided by Odoo's dependencies
except Exception as e:
    print("psycopg2 is not available: {}".format(e), file=sys.stderr)
    sys.exit(1)

parser = argparse.ArgumentParser(description="Wait for PostgreSQL to accept connections")
parser.add_argument("--host", required=True)
parser.add_argument("--port", type=int, default=5432)
parser.add_argument("--user", required=True)
parser.add_argument("--password", default="")
parser.add_argument("--database", default="postgres")
parser.add_argument("--timeout", type=int, default=60)
args = parser.parse_args()

deadline = time.time() + args.timeout
while time.time() < deadline:
    try:
        conn = psycopg2.connect(
            host=args.host,
            port=args.port,
            user=args.user,
            password=args.password,
            dbname=args.database,
        )
        conn.close()
        sys.exit(0)
    except Exception:
        time.sleep(2)

print(f"Could not connect to PostgreSQL at {args.host}:{args.port} within {args.timeout}s", file=sys.stderr)
sys.exit(1)