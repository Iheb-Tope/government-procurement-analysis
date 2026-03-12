# Government Procurement Analysis — Process Log

## Project Overview

This project analyzes Canadian federal procurement contract data from the CanadaBuys Contract History dataset. The objective was to simulate a realistic data preparation and analytics workflow similar to what a business analyst or data analyst might perform when preparing government procurement data for reporting and operational analysis.

The project includes the full pipeline from raw data ingestion to data cleaning, validation, and preparation of an analytical dataset used to build a Power BI dashboard.

---

# 1. Dataset Identification

The dataset used for this project is the **CanadaBuys Contract History dataset**, available from the Government of Canada Open Data Portal.

This dataset contains historical records of federal procurement contracts issued by **Public Services and Procurement Canada (PSPC)**.

The dataset includes information such as:

- contract title
- contract number
- amendment number
- contracting department
- supplier
- contract values
- procurement method
- procurement category
- classification codes (GSIN and UNSPSC)

Because the dataset records **contract history**, each contract may appear across multiple rows due to amendments.

---

# 2. Dataset Selection

Six fiscal year datasets were selected to capture recent procurement activity while maintaining enough history for trend analysis.

The datasets used:

- 2020–2021
- 2021–2022
- 2022–2023
- 2023–2024
- 2024–2025
- 2025–2026

Each dataset was downloaded as a CSV file.

---

# 3. Development Environment

The project was developed using the following tools:

- SQL Server Developer Edition
- SQL Server Management Studio (SSMS)
- Python
- Power BI Desktop

SQL Server instance:


localhost\MSSQLSERVER01


Project database:


gov_procurement_analysis


---

# 4. Initial Data Ingestion Attempt

The initial ingestion attempt used the **SSMS Flat File Import Wizard**.

Several issues occurred:

- incorrect datatype detection
- text truncation errors
- fields incorrectly marked as NOT NULL
- inconsistent handling of bilingual columns
- long text fields causing schema issues

Because of these problems, the ingestion strategy was changed.

---

# 5. Python-Based Data Ingestion

A Python script was created to load the CSV files into SQL Server.

The script uses **pandas and SQLAlchemy** to read the CSV files and insert them into SQL Server tables.

Each dataset was loaded into its own **raw staging table**:


contracts_2020_2021_raw
contracts_2021_2022_raw
contracts_2022_2023_raw
contracts_2023_2024_raw
contracts_2024_2025_raw
contracts_2025_2026_raw


These tables preserve the original dataset structure.

---

# 6. Raw Data Consolidation

The six raw tables were combined into a single staging table:


contracts_all_raw


This table contains the combined raw dataset covering six years of procurement history.

---

# 7. Creation of Analytical Table

A new analytical table was created:


contracts_history_clean


Only the columns relevant for analysis were selected from the raw dataset.

The bilingual column names were renamed to standardized **snake_case field names**.

Example transformations:


contractNumber-numeroContrat → contract_number
contractAwardDate-dateAttributionContrat → award_date
contractAmount-montantContrat → contract_amount


---

# 8. Record Type Classification

The dataset contains both original contracts and amendments.

A derived column `record_type` was created using the following rule:


amendment_number = '000' → Original contract
otherwise → Amendment


This allows the analysis to distinguish initial contract awards from later amendments.

---

# 9. Text Cleaning and Normalization

Several text-cleaning operations were performed:

- trimming leading and trailing whitespace
- converting empty strings to NULL
- converting literal `"NULL"` values into actual SQL NULL values

Department names were standardized.

Example:


Public Works and Government Services Canada
Department of Public Works and Government Services (PSPC)


were normalized to:


Public Services and Procurement Canada


---

# 10. Supplier Name Propagation

Many amendment rows contained missing supplier names.

Supplier values were propagated across rows sharing the same `contract_number` when possible.

This was done using aggregated supplier values derived from original contracts or other amendment records.

---

# 11. Procurement Category Standardization

Procurement category codes were converted to readable labels.

Example mappings:


*GD → Goods
*SRV → Services
*CNST → Construction
*SRVTGD → Goods and Services


Rows with missing procurement categories were removed.

---

# 12. Monetary Value Cleaning

Contract value fields were cleaned:

- negative values were treated as invalid and converted to NULL
- zero values were also converted to NULL because they do not represent meaningful contract amounts

---

# 13. Date Validation

Rows where the contract end date occurred before the start date were considered invalid and removed.


end_date < start_date


---

# 14. Duplicate Detection and Removal

Duplicate rows were removed using a **ROW_NUMBER window function** based on key contract fields.

This ensured that only unique records were preserved while maintaining valid amendment history.

---

# 15. Feature Engineering

Additional analytical columns were created to support reporting.

Derived fields include:


award_year
contract_value_category


Contract value categories:


Small (< $10,000)
Medium (< $100,000)
Large (≥ $100,000)


---

# 16. Data Validation

Final validation checks were performed:

- total row counts
- null coverage checks
- procurement category distribution
- record type distribution
- duplicate detection
- date anomaly checks

These checks confirmed that the dataset was consistent and suitable for analysis.

---

# 17. Data Export for Visualization

The final cleaned dataset was exported from SQL Server as a CSV file:


contracts_history_clean.csv


This dataset was then used as the source for the Power BI dashboard.

---

# 18. Dashboard Development

The cleaned dataset was loaded into Power BI.

The dashboard was designed to analyze:

- procurement spending trends
- contract value distribution
- procurement categories
- supplier activity
- department-level procurement patterns

This step translated the cleaned dataset into a visual analytical tool for procurement insights.
