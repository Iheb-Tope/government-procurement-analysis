# Government Procurement Analysis

## Project Overview

This project analyzes Canadian federal procurement contract data using the **CanadaBuys Contract History** dataset. The objective was to build a realistic end-to-end analytics workflow that mirrors the type of work performed in business analysis and data preparation projects.

The project covers the full pipeline from raw CSV ingestion to SQL-based cleaning and transformation, followed by dashboard development in Power BI.

This project demonstrates:

- Python-based data ingestion
- SQL data cleaning and transformation
- data quality validation
- feature engineering
- preparation of an analytical dataset for Power BI
- dashboard development for procurement trend analysis

---

## Business Objective

The purpose of this project is to identify procurement patterns and trends in Canadian federal contract history data and prepare an analysis-ready dataset that can support reporting, trend analysis, and process improvement discussions.

The project was designed to simulate a practical analytics workflow relevant to roles such as:

- Business Analyst
- Data Analyst
- Solutions Engineer
- BI Analyst

---

## Data Source

**Dataset:** CanadaBuys Contract History  
**Source:** Government of Canada Open Data Portal

The dataset contains historical records of federal procurement contracts awarded by **Public Services and Procurement Canada (PSPC)** on behalf of government departments and agencies.

Key fields include:

- contract title
- contract number
- amendment number
- supplier
- contracting department
- contract award date
- amendment date
- contract value
- procurement method
- procurement category
- GSIN and UNSPSC classifications

Because the source is a **contract history** dataset, contracts can appear across multiple rows due to amendments and revisions.

---

## Data Pipeline Architecture

CanadaBuys Contract History CSV files
        │
        ▼
Python ingestion script
(load_all_procurement_data.py)
        │
        ▼
SQL Server raw staging tables
contracts_2020_2021_raw
contracts_2021_2022_raw
contracts_2022_2023_raw
contracts_2023_2024_raw
contracts_2024_2025_raw
contracts_2025_2026_raw
        │
        ▼
Combined raw table
contracts_all_raw
        │
        ▼
SQL cleaning and transformation pipeline
(contracts_history_cleaning_script.sql)
        │
        ▼
Clean analytical table
contracts_history_clean
        │
        ▼
CSV export for reporting
contracts_history_clean.csv
        │
        ▼
Power BI dashboard
Government_Procurement_Dashboard
Project Workflow
**1. Raw Data Ingestion**

Six fiscal-year CSV files were imported into SQL Server using a Python ingestion script after initial attempts with the SSMS Flat File Import Wizard produced schema and datatype issues.

Raw staging tables created:

contracts_2020_2021_raw

contracts_2021_2022_raw

contracts_2022_2023_raw

contracts_2023_2024_raw

contracts_2024_2025_raw

contracts_2025_2026_raw

**2. Data Consolidation**

The yearly raw tables were combined into a single staging table:

contracts_all_raw

This created one consolidated raw layer covering six fiscal years of procurement history.

**3. Data Cleaning and Transformation**

A cleaned analytical table named contracts_history_clean was built in SQL Server.

Main transformations included:

selecting analytically relevant columns

renaming bilingual source columns into standardized snake_case names

converting date and numeric fields into usable analytical types

classifying records as Original contract or Amendment

trimming whitespace and converting blank strings to NULL

converting literal "NULL" text values into actual SQL NULL

standardizing department names

propagating supplier names across related contract records where possible

standardizing procurement category values

removing invalid date rows

converting invalid monetary values to NULL

removing exact duplicate rows

**4. Feature Engineering**

Additional analytical fields were created to support reporting and segmentation:

award_year

contract_value_category

These fields were added to make trend analysis and contract value grouping easier in Power BI.

**5. Data Validation**

Final validation checks were performed to confirm the quality of the cleaned dataset, including:

total row count verification

null coverage checks across key fields

procurement category distribution

record type distribution

duplicate detection

date anomaly checks

**6. Dashboard Development**

The cleaned analytical table was exported to CSV and used as the source for a Power BI dashboard.

The dashboard was designed to analyze:

procurement trends over time

contract value distribution

supplier activity

procurement categories

procurement methods

department-level procurement patterns

**SQL Cleaning Highlights**

The SQL pipeline includes logic for:

multi-year data consolidation

data type conversion with TRY_CAST

text normalization using LTRIM, RTRIM, and NULLIF

supplier backfilling using grouped contract logic

deduplication using ROW_NUMBER()

invalid value cleanup for monetary fields

date consistency filtering

derived analytical fields for reporting

This structure reflects a realistic SQL-based data preparation workflow rather than a simple dashboard-only project.

**Repository Structure**

government-procurement-analysis/
│
├── python/
│   └── load_all_procurement_data.py
│
├── sql/
│   └── contracts_history_cleaning_script.sql
│
├── data/
│   └── contracts_history_clean.csv
│
├── dashboard/
│   └── Government_Procurement_Dashboard.pbix
│
├── docs/
│   └── process_log.md
│
└── README.md

**Tools Used**

Python

SQL Server

SQL Server Management Studio (SSMS)

Power BI Desktop

Project Deliverables

This project includes:

Python ingestion script

SQL cleaning and transformation script

cleaned analytical dataset

process log documenting the workflow

Power BI dashboard for procurement analysis

**Outcome**

The final result of this project is a cleaned and structured procurement dataset prepared from six years of federal contract history data and transformed into a dashboard-ready analytical source.

This project demonstrates the ability to:

ingest raw multi-file data into SQL Server

design a staging and analytical data workflow

clean and normalize messy real-world data

validate data quality through SQL checks

engineer features for business intelligence reporting

present procurement analysis in Power BI

Reproduction Steps

Create the SQL Server database:

gov_procurement_analysis

Load the raw CSV files using:

load_all_procurement_data.py

Run the SQL cleaning pipeline:

contracts_history_cleaning_script.sql

Export the cleaned analytical table:

contracts_history_clean.csv

Load the cleaned dataset into Power BI and open the dashboard file.

**Author**

Iheb Ben Hammouda
