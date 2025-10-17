#!/usr/bin/env python3
"""
my_name < email@example.com >

DESCRIPTION:
  Demo skeleton showing ensure-style thread cleanup:
  submit N items, always wait for completion, collect results & errors.

USAGE:
  skeleton.py 1 2 --required foo --sum --move paper --workers 8 --fail-prob 0.3

LICENSE: ____
"""

import argparse
import sys
import time
import random
import traceback
from concurrent.futures import ThreadPoolExecutor, as_completed

def parse_args(argv=None):
    p = argparse.ArgumentParser(description='description for skeleton program to ...')
    p.add_argument('integers', metavar='N', type=int, nargs='+',
                   help='an integer for the accumulator')
    p.add_argument('--sum', dest='accumulate', action='store_const',
                   const=sum, default=max,
                   help='sum the integers (default: find the max)')
    p.add_argument('--move', choices=['rock', 'paper', 'scissors'])
    p.add_argument('--required', required=True)
    p.add_argument('--workers', type=int, default=None,
                   help='max worker threads (default: library chooses)')
    p.add_argument('--fail-prob', type=float, default=0.30,
                   help='probability a task raises (0.0–1.0)')
    p.add_argument('--seed', type=int, default=None, help='random seed for reproducibility')
    p.add_argument('-v', '--verbose', action='store_true', help='verbose output')
    p.add_argument('-d', '--debug', action='store_true', help='debug output')
    return p.parse_args(argv)

# --- workload ---------------------------------------------------------------

def handle(item, fail_prob=0.3):
    """Simulate work; sometimes fail."""
    time.sleep(random.uniform(0.05, 0.25))
    if random.random() < fail_prob:
        raise RuntimeError(f"boom on {item}")
    return f"processed {item}"

# --- orchestration with ensure-style cleanup --------------------------------

def process_all(items, max_workers=None, fail_prob=0.3, verbose=False):
    results, errors = [], []
    executor = ThreadPoolExecutor(max_workers=max_workers)
    futures = {executor.submit(handle, it, fail_prob): it for it in items}

    try:
        for fut in as_completed(futures):
            item = futures[fut]
            try:
                out = fut.result()
                results.append(out)
                if verbose:
                    print(f"[ok] {out}")
            except Exception as e:
                tb = traceback.format_exc()
                errors.append((item, e, tb))
                if verbose:
                    print(f"[err] item={item} err={e}\n{tb}")
    finally:
        # ensure-style: always join threads and tear down
        executor.shutdown(wait=True)

    return results, errors

# --- main -------------------------------------------------------------------

def main(argv=None):
    args = parse_args(argv)
    if args.seed is not None:
        random.seed(args.seed)

    try:
        sum_of_items = args.accumulate(args.integers)
        items = list(range(sum_of_items))
        results, errors = process_all(
            items,
            max_workers=args.workers,
            fail_prob=args.fail_prob,
            verbose=args.verbose
        )

        print("Results:")
        for r in results:
            print("  ", r)

        print("\nErrors:")
        for item, exc, tb in errors:
            print(f"  item={item} err={exc}")
            if args.verbose:
                print(tb)

        # Example: do something with --move just to use it
        if args.move:
            print(f"\nYou played: {args.move}")

        return 0 if not errors else 1

    except KeyboardInterrupt:
        # Still safe: executor is shut down in finally block
        print("\nInterrupted by user.", file=sys.stderr)
        return 130
    except Exception as e:
        # Print a brief message and detailed traceback
        print(f"ERROR: {e}", file=sys.stderr)
        print(traceback.format_exc(), file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())

