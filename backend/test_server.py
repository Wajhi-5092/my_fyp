import sys
import os

print("Starting test script...", flush=True)

try:
    print("Attempting to import main...", flush=True)
    import main
    print("Import successful!", flush=True)
except Exception as e:
    print(f"Import failed: {e}", flush=True)
    import traceback
    traceback.print_exc()

print("Test script finished.", flush=True)
