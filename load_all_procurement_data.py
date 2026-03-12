import os
import pandas as pd
from sqlalchemy import create_engine

data_folder = r"C:\Users\ihebb\OneDrive\Desktop\Government Procurement\data"

connection_string = (
    "mssql+pyodbc://@localhost\\MSSQLSERVER01/gov_procurement_analysis"
    "?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
)

engine = create_engine(connection_string, fast_executemany=True)

for file_name in sorted(os.listdir(data_folder)):
    if not file_name.endswith(".csv"):
        continue

    file_path = os.path.join(data_folder, file_name)

    # Build clean table name like contracts_2020_2021_raw
    year_part = file_name.split("-contractHistory")[0]   # e.g. 2020-2021
    table_name = f"contracts_{year_part.replace('-', '_')}_raw"

    print(f"Reading {file_name}...")
    df = pd.read_csv(file_path, dtype=str, low_memory=False)

    print("Rows loaded:", len(df))
    print("Columns:", len(df.columns))
    print(f"Uploading to SQL Server table: {table_name}...")

    df.to_sql(
        table_name,
        engine,
        if_exists="replace",
        index=False,
        chunksize=100
    )

    print(f"{table_name} upload complete.\n")

print("All files uploaded successfully.")