# Raw data (needed to re-run the notebook)

The raw file is **not** in this repo: it is 46 MB, and it is someone else's data, so I do not re-share it.

- **Dataset:** "Online Retail", UCI Machine Learning Repository: https://archive.ics.uci.edu/dataset/352/online+retail (also on Kaggle)
- **Save it as** `OnlineRetail.csv` in the same folder as the notebook. The notebook reads it with `encoding="latin-1"`.
- **Expected:** 541,909 rows and 8 columns: InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country
- **Check you have the right file:** run `python check_raw_data.py`

## What is already in this repo
- `outputs/`: cleaning log, key numbers, RFM table, segment summary and a 5,000-row sample of the cleaned data (the full cleaned file is too large for this repo)
- The notebook and `analysis.sql` need the raw file to run end to end.
