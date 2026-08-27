import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent / 'src'))
import pandas as pd
from trading_analytics.load import load_star_schema

HERE = Path(__file__).parent
db = HERE / "data" / "analytics.duckdb"
schema = HERE / "analytics-schema.sql"

accounts = pd.read_csv(HERE / "data" / "sample_accounts.csv")
instruments = pd.read_csv(HERE / "data" / "sample_instruments.csv")
orders = pd.read_csv(HERE / "data" / "sample_orders.csv")

load_star_schema(db, schema, accounts, instruments, orders)
print(f"Loaded analytical star schema into {db}")