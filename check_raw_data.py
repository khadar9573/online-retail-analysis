import sys, pandas as pd
FILE = "OnlineRetail.csv"
COLS = ["InvoiceNo", "StockCode", "Description", "Quantity", "InvoiceDate", "UnitPrice", "CustomerID", "Country"]
try:
    d = pd.read_csv(FILE, encoding="latin-1")
except FileNotFoundError:
    sys.exit(f"{FILE} not found. Download it (see DATA.md) and save it next to this script.")
ok = len(d) == 541909 and list(d.columns) == COLS
print(f"{FILE}: {len(d):,} rows, {len(d.columns)} columns ->", "PASS" if ok else "FAIL (expected 541,909 rows and the 8 columns in DATA.md)")
