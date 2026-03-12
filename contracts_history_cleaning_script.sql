/*
============================================================
PROJECT: Government Procurement Analysis
AUTHOR: Iheb Ben Hammouda
DESCRIPTION:
This script combines, cleans, and prepares CanadaBuys
contract history data for downstream analysis in Power BI.

SOURCE TABLES:
- dbo.contracts_2020_2021_raw
- dbo.contracts_2021_2022_raw
- dbo.contracts_2022_2023_raw
- dbo.contracts_2023_2024_raw
- dbo.contracts_2024_2025_raw
- dbo.contracts_2025_2026_raw

FINAL OUTPUT TABLE:
- dbo.contracts_history_clean
============================================================
*/

USE gov_procurement_analysis;
GO

SET NOCOUNT ON;
GO

-- 1. COMBINE RAW TABLES

DROP TABLE IF EXISTS dbo.contracts_all_raw;
DROP TABLE IF EXISTS dbo.contracts_history_clean;

SELECT *
INTO dbo.contracts_all_raw
FROM dbo.contracts_2020_2021_raw

UNION ALL
SELECT * FROM dbo.contracts_2021_2022_raw

UNION ALL
SELECT * FROM dbo.contracts_2022_2023_raw

UNION ALL
SELECT * FROM dbo.contracts_2023_2024_raw

UNION ALL
SELECT * FROM dbo.contracts_2024_2025_raw

UNION ALL
SELECT * FROM dbo.contracts_2025_2026_raw;
GO

-- 2. CREATE CLEAN ANALYTICAL TABLE

SELECT
    [title-titre-eng] AS title,
    [contractNumber-numeroContrat] AS contract_number,
    [amendmentNumber-numeroModification] AS amendment_number,

    CASE
        WHEN [amendmentNumber-numeroModification] = '000' THEN 'Original contract'
        ELSE 'Amendment'
    END AS record_type,

    TRY_CAST([contractAwardDate-dateAttributionContrat] AS DATE) AS award_date,
    TRY_CAST([amendmentDate-dateModification] AS DATE) AS amendment_date,
    TRY_CAST([contractStartDate-contratDateDebut] AS DATE) AS start_date,
    TRY_CAST([contractEndDate-dateFinContrat] AS DATE) AS end_date,

    TRY_CAST([contractAmount-montantContrat] AS FLOAT) AS contract_amount,
    TRY_CAST([totalContractValue-valeurTotaleContrat] AS FLOAT) AS total_contract_value,
    [contractCurrency-contratMonnaie] AS currency,

    [contractingEntityName-nomEntitContractante-eng] AS department,
    [supplierStandardizedName-nomNormaliseFournisseur-eng] AS supplier_name,
    [supplierEmployeeCount-fournisseurNombreEmployes-eng] AS supplier_employee_size,

    [procurementMethod-methodeApprovisionnement-eng] AS procurement_method,
    [procurementCategory-categorieApprovisionnement] AS procurement_category,
    [selectionCriteria-criteresSelection-eng] AS selection_criteria,
    [tradeAgreements-accordsCommerciaux-eng] AS trade_agreements,

    [gsin-nibs] AS gsin_code,
    [gsinDescription-nibsDescription-eng] AS gsin_description,
    [unspsc] AS unspsc_code,
    [unspscDescription-eng] AS unspsc_description
INTO dbo.contracts_history_clean
FROM dbo.contracts_all_raw;
GO

-- 3. STANDARDIZE TEXT VALUES

-- Standardize department naming
UPDATE dbo.contracts_history_clean
SET department = 'Public Services and Procurement Canada'
WHERE department IN (
    'Public Works and Government Services Canada',
    'Department of Public Works and Government Services (PSPC)'
);
GO

-- Trim whitespace and convert blank strings to NULL
UPDATE dbo.contracts_history_clean
SET
    title = NULLIF(LTRIM(RTRIM(title)), ''),
    contract_number = NULLIF(LTRIM(RTRIM(contract_number)), ''),
    amendment_number = NULLIF(LTRIM(RTRIM(amendment_number)), ''),
    record_type = NULLIF(LTRIM(RTRIM(record_type)), ''),
    currency = NULLIF(LTRIM(RTRIM(currency)), ''),
    department = NULLIF(LTRIM(RTRIM(department)), ''),
    supplier_name = NULLIF(LTRIM(RTRIM(supplier_name)), ''),
    supplier_employee_size = NULLIF(LTRIM(RTRIM(supplier_employee_size)), ''),
    procurement_method = NULLIF(LTRIM(RTRIM(procurement_method)), ''),
    procurement_category = NULLIF(LTRIM(RTRIM(procurement_category)), ''),
    selection_criteria = NULLIF(LTRIM(RTRIM(selection_criteria)), ''),
    trade_agreements = NULLIF(LTRIM(RTRIM(trade_agreements)), ''),
    gsin_code = NULLIF(LTRIM(RTRIM(gsin_code)), ''),
    gsin_description = NULLIF(LTRIM(RTRIM(gsin_description)), ''),
    unspsc_code = NULLIF(LTRIM(RTRIM(unspsc_code)), ''),
    unspsc_description = NULLIF(LTRIM(RTRIM(unspsc_description)), '');
GO

-- Convert literal 'NULL' strings to actual NULLs
UPDATE dbo.contracts_history_clean
SET
    supplier_name = NULLIF(supplier_name, 'NULL'),
    department = NULLIF(department, 'NULL'),
    gsin_code = NULLIF(gsin_code, 'NULL'),
    gsin_description = NULLIF(gsin_description, 'NULL');
GO

-- 4. PROPAGATE SUPPLIER NAMES WHERE POSSIBLE

ALTER TABLE dbo.contracts_history_clean
ADD supplier_name_original NVARCHAR(500);
GO

UPDATE dbo.contracts_history_clean
SET supplier_name_original = supplier_name
WHERE supplier_name_original IS NULL;
GO

WITH supplier_source AS (
    SELECT
        contract_number,
        MAX(
            CASE
                WHEN record_type = 'Original contract'
                     AND supplier_name IS NOT NULL
                THEN supplier_name
            END
        ) AS original_supplier,
        MAX(
            CASE
                WHEN supplier_name IS NOT NULL
                THEN supplier_name
            END
        ) AS any_supplier
    FROM dbo.contracts_history_clean
    GROUP BY contract_number
)
UPDATE ch
SET ch.supplier_name = COALESCE(ss.original_supplier, ss.any_supplier)
FROM dbo.contracts_history_clean AS ch
INNER JOIN supplier_source AS ss
    ON ch.contract_number = ss.contract_number
WHERE ch.supplier_name IS NULL;
GO

-- 5. STANDARDIZE PROCUREMENT CATEGORY

UPDATE dbo.contracts_history_clean
SET procurement_category =
    CASE
        WHEN procurement_category = '*GD' THEN 'Goods'
        WHEN procurement_category = '*SRV' THEN 'Services'
        WHEN procurement_category = '*CNST' THEN 'Construction'
        WHEN procurement_category = '*SRVTGD' THEN 'Goods and Services'
        ELSE procurement_category
    END;
GO

-- Remove rows with missing procurement category
DELETE FROM dbo.contracts_history_clean
WHERE procurement_category IS NULL;
GO

-- 6. CLEAN NUMERIC VALUES

-- Negative values are treated as invalid and set to NULL
UPDATE dbo.contracts_history_clean
SET contract_amount = NULL
WHERE contract_amount < 0;

UPDATE dbo.contracts_history_clean
SET total_contract_value = NULL
WHERE total_contract_value < 0;
GO

-- Zero values are treated as analytically unusable and set to NULL
UPDATE dbo.contracts_history_clean
SET contract_amount = NULL
WHERE contract_amount = 0;

UPDATE dbo.contracts_history_clean
SET total_contract_value = NULL
WHERE total_contract_value = 0;
GO

-- 7. REMOVE INVALID DATE RECORDS

DELETE FROM dbo.contracts_history_clean
WHERE end_date < start_date;
GO

-- 8. REMOVE EXACT DUPLICATES

WITH ranked_rows AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY
                   contract_number,
                   amendment_number,
                   record_type,
                   award_date,
                   amendment_date,
                   start_date,
                   end_date,
                   contract_amount,
                   total_contract_value,
                   supplier_name,
                   department,
                   procurement_method,
                   procurement_category,
                   title
               ORDER BY contract_number
           ) AS rn
    FROM dbo.contracts_history_clean
)
DELETE FROM ranked_rows
WHERE rn > 1;
GO

-- 9. ADD DERIVED ANALYTICAL COLUMNS

ALTER TABLE dbo.contracts_history_clean
ADD award_year INT;
GO

UPDATE dbo.contracts_history_clean
SET award_year = YEAR(award_date);
GO

ALTER TABLE dbo.contracts_history_clean
ADD contract_value_category VARCHAR(20);
GO

UPDATE dbo.contracts_history_clean
SET contract_value_category =
    CASE
        WHEN total_contract_value < 10000 THEN 'Small'
        WHEN total_contract_value < 100000 THEN 'Medium'
        WHEN total_contract_value IS NOT NULL THEN 'Large'
        ELSE NULL
    END;
GO

-- 10. OPTIONAL PERFORMANCE INDEXES


ALTER TABLE dbo.contracts_history_clean
ALTER COLUMN contract_number VARCHAR(50);
GO

ALTER TABLE dbo.contracts_history_clean
ALTER COLUMN supplier_name VARCHAR(255);
GO

CREATE INDEX idx_contract_number
ON dbo.contracts_history_clean(contract_number);
GO

CREATE INDEX idx_supplier
ON dbo.contracts_history_clean(supplier_name);
GO

CREATE INDEX idx_award_date
ON dbo.contracts_history_clean(award_date);
GO

-- 11. FINAL VALIDATION CHECKS

-- Row count
SELECT COUNT(*) AS total_rows
FROM dbo.contracts_history_clean;
GO

-- Null coverage
SELECT
    COUNT(*) AS total_rows,
    COUNT(contract_number) AS contract_number_not_null,
    COUNT(amendment_number) AS amendment_number_not_null,
    COUNT(record_type) AS record_type_not_null,
    COUNT(award_date) AS award_date_not_null,
    COUNT(contract_amount) AS contract_amount_not_null,
    COUNT(total_contract_value) AS total_contract_value_not_null,
    COUNT(supplier_name) AS supplier_name_not_null,
    COUNT(procurement_method) AS procurement_method_not_null,
    COUNT(procurement_category) AS procurement_category_not_null,
    COUNT(title) AS title_not_null
FROM dbo.contracts_history_clean;
GO

-- Procurement category distribution
SELECT
    procurement_category,
    COUNT(*) AS row_count
FROM dbo.contracts_history_clean
GROUP BY procurement_category
ORDER BY row_count DESC;
GO

-- Record type distribution
SELECT
    record_type,
    COUNT(*) AS row_count
FROM dbo.contracts_history_clean
GROUP BY record_type
ORDER BY row_count DESC;
GO

-- Duplicate check at contract/amendment level
SELECT
    contract_number,
    amendment_number,
    COUNT(*) AS row_count
FROM dbo.contracts_history_clean
GROUP BY contract_number, amendment_number
HAVING COUNT(*) > 1
ORDER BY row_count DESC;
GO

-- Remaining date anomalies
SELECT
    SUM(CASE WHEN end_date IS NOT NULL AND start_date IS NOT NULL AND end_date < start_date THEN 1 ELSE 0 END) AS end_before_start,
    SUM(CASE WHEN start_date IS NOT NULL AND award_date IS NOT NULL AND start_date < award_date THEN 1 ELSE 0 END) AS start_before_award,
    SUM(CASE WHEN amendment_date IS NOT NULL AND award_date IS NOT NULL AND amendment_date < award_date THEN 1 ELSE 0 END) AS amendment_before_award
FROM dbo.contracts_history_clean;
GO
