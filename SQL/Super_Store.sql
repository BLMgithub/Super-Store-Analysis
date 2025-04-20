

/*-------------------------------------------------------------------------------------------------*/
/*------------------------------------- TABLE OF CONTENTS -----------------------------------------*/
/*-------------------------------------------------------------------------------------------------*/

/*
        LINE   26 - 59	 ................................... CREATING TABLE TO STORE RAW DATA

        LINE   60 - 84	 ................................... IMPORTING DATA

        LINE   85 - 594	 ................................... DATA INSPECTION

        LINE  595 - 781	 ................................... DATA CLEANING

        LINE  782 - 835	 ................................... ADDING DATE RELATED COLUMNS

        LINE  836 - 1132 ................................... DATA EXPLORATION

        LINE 1132 - 1334 ................................... DATA FOR EXPORT / DASHBOARD
*/


USE Super_Store

/*-------------------------------------------------------------------------------------------------*/
/*----------------------------- CREATING TABLE TO STORE RAW DATA ----------------------------------*/
/*-------------------------------------------------------------------------------------------------*/


IF OBJECT_ID('Stores') IS NOT NULL DROP TABLE Stores;

CREATE TABLE Stores(
    RowID           INT NULL,
    OrderID         NVARCHAR(70) NULL,
    OrderDate       DATE NULL,
    Shipdate        DATE NULL,
    Shipmode        NVARCHAR(30) NULL,
    CustomerID      NVARCHAR(30) NULL,
    CustomerName    NVARCHAR(70) NULL,
    Segment         NVARCHAR(30) NULL,
    City            NVARCHAR(100) NULL,
    State           NVARCHAR(100) NULL,
    Country         NVARCHAR(100) NULL,
    Market          NVARCHAR(30) NULL,
    Region          NVARCHAR(30) NULL,
    ProductID       NVARCHAR(100) NULL,
    Category        NVARCHAR(30) NULL,
    SubCategory     NVARCHAR(30) NULL,
    ProductName     NVARCHAR(255) NULL,
    Sales           DECIMAL(10,2) NULL,
    Quantity        TINYINT NULL,
    Discount        DECIMAL(5,3) NULL,
    Profit          DECIMAL(10,2) NULL,
    ShippingCost    Decimal(10,2) NULL,
    OrderPriority   NVARCHAR(30) NULL
    );


/*-------------------------------------------------------------------------------------------------*/
/*------------------------------------ IMPORTING DATA ---------------------------------------------*/
/*-------------------------------------------------------------------------------------------------*/


BULK INSERT Stores

FROM
    'D:\_Projects\2025_Project_2_Super_Store\Data\Global-Superstore.csv'

WITH (
    FORMAT= 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
    );


-- Checking Result 
SELECT
    TOP 10 *
FROM
    Stores;


/*-------------------------------------------------------------------------------------------------*/
/*-------------------------------------- DATA INSPECTION ------------------------------------------*/
/*-------------------------------------------------------------------------------------------------*/


/**  Creating Dataset Information  **/

-- Creating Summary Table
IF OBJECT_ID('#DataInfo') IS NOT NULL DROP TABLE #DataInfo;

CREATE TABLE #DataInfo(
    ColumnName      NVARCHAR(100),
    DataType        NVARCHAR(30),
    NullCount       INT,
    DistinctCount   INT
);

-- Store String Query
DECLARE @GetNulls_DistinctCount NVARCHAR(MAX);

-- Constructing Query
SELECT @GetNulls_DistinctCount = 
    
    'INSERT INTO #DataInfo ' +
    
    STRING_AGG(
        CAST('SELECT 
                ''' + name + ''' AS ColumnName,
                '''+ DATA_TYPE +''' As DataType,
                COUNT(CASE WHEN ' + name + ' IS NULL THEN 1 END) AS NullCount,
                COUNT(DISTINCT ' + name +') AS DistinctCount
            FROM
                Stores'
                AS NVARCHAR(MAX)        -- Bypass 8000-byte limit on STRING_AGG  
                ),
            ' UNION ALL ' 
            )
FROM
    sys.columns AS Syscol
        JOIN
    INFORMATION_SCHEMA.Columns as InfoCol
    ON Syscol.name = InfoCol.COLUMN_NAME
WHERE
    object_id = OBJECT_ID('Stores')
        AND
    TABLE_NAME = 'Stores';

-- Executing Stored Query
EXEC(@GetNulls_DistinctCount);


-- Checking Result
SELECT
    *
FROM
    #DataInfo


/*-------------------------------------------------------------------------------------------------*/


/** Checking Duplicates on dataset **/

-- Store String Query
DECLARE @GetDuplicates NVARCHAR(MAX);

-- Constructing Query
SELECT @GetDuplicates =
    'SELECT 
        COUNT(*) AS DuplicateCounter,
        ' + STRING_AGG(QUOTENAME(name), ', ') + '
    FROM 
        Stores 
    GROUP BY
        ' + STRING_AGG(QUOTENAME(name), ', ') + '
    HAVING
        COUNT(*) > 1'
FROM
	sys.columns
WHERE
	object_id = OBJECT_ID('Stores');

-- Executing Stored Query
EXEC(@GetDuplicates);


/*-------------------------------------------------------------------------------------------------*/


/**  Checking Data Consistency for CustomerID and CustomerName (TO DROP: Mismatch Count)  **/
SELECT
    COUNT(DISTINCT(CustomerName)) AS UniqueCustomer,
    COUNT(DISTINCT(CustomerID)) AS UniqueCustomerID
FROM
    Stores;


/*-------------------------------------------------------------------------------------------------*/


/**  Checking Data Consistency for ProductID and ProductName (TO DROP: Mismatch Count)	 **/
SELECT
    COUNT(DISTINCT(ProductName)) AS UniqueProduct,
    COUNT(DISTINCT(ProductID)) AS UniqueProductID
FROM
    Stores;


/*-------------------------------------------------------------------------------------------------*/


/** Checking Country count for each market (TO FIX: combine US and Canada into NA 'NorthAmerica') **/
SELECT
    Market,
    COUNT(DISTINCT Country) AS CountryCount
FROM
    Stores
GROUP BY
    Market;


/*-------------------------------------------------------------------------------------------------*/


/**  Checking Market & Country Hierarchy (TO FIX: Inconsistentcy)  **/
SELECT
    COUNT(DISTINCT(Country)) AS UniqueCountry,
    (
    SELECT
        COUNT(DISTINCT(MC.MarketCountry))               -- Unique Count of Market &
    FROM (                                              -- Country Combination
        SELECT											
            CONCAT(Market, Country) AS MarketCountry    -- Stores combined Market & Country
        FROM
            Stores
        GROUP BY
            Market,
            Country
        ) AS MC
    ) AS UniqueMarketCountry                            -- Result Column Name
FROM
    Stores;


/*-------------------------------------------------------------------------------------------------*/


/** Checking SubCategory count for each Category  **/
SELECT
    *
FROM
    #DataInfo;

--

SELECT
    Category,
    COUNT(DISTINCT SubCategory) AS SubCategoryCount
FROM
    Stores
GROUP BY
    Category;


/*-------------------------------------------------------------------------------------------------*/


/**  Checking Category & SubCategory Hierachy  **/
SELECT
    COUNT(DISTINCT(SubCategory)) AS UniqueSubCategory,
    (
    SELECT
        COUNT(DISTINCT(CS.CategorySubcategory))                     -- Unique Count of Category &
    FROM (                                                          -- SubCategory Combination
        SELECT
            CONCAT(Category, SubCategory) AS CategorySubcategory	-- Stores combined 
        FROM								                        -- Category & SubCategory
            Stores
        GROUP BY
            Category,
            SubCategory
        ) AS CS
    ) AS UniqueCategorySubcategory                                  -- Result Column Name
FROM
    Stores;


/*-------------------------------------------------------------------------------------------------*/


/** Checking Product count for each SubCategory  **/
SELECT
    Category,
    SubCategory,
    COUNT(DISTINCT ProductName) AS ProductNameCount
FROM
    Stores
GROUP BY
    Category,
    SubCategory
ORDER BY
    Category,
    ProductNameCount DESC;


/*-------------------------------------------------------------------------------------------------*/


/**  Checking SubCategory & ProductName Hierarchy (TO FIX: Inconsistency)  **/
SELECT
    COUNT(DISTINCT(ProductName)) AS UniqueProduct,
    (
    SELECT
        COUNT(DISTINCT(SP.SubcategoryProduct))                      -- Unique Count of Combined
    FROM (                                                          -- SubCategory & ProductName
        SELECT
            CONCAT(SubCategory, ProductName) AS SubcategoryProduct  -- Stores combined
        FROM                                                        -- SubCategory & ProductName
            Stores
        GROUP BY
            SubCategory,
            ProductName
        ) AS SP
    ) AS UniqueSubcategoryProduct                                   -- Result Column Name
FROM
    Stores;


/*-------------------------------------------------------------------------------------------------*/


/** Cheking Continuous Variables **/
SELECT
    *
FROM
    #DataInfo
WHERE
    DataType != 'Nvarchar';

-- Creating Temporary table for Continuous variable

SELECT
    ColumnName
INTO #ContinuousVariables
FROM
    #DataInfo
WHERE
    ColumnName IN ('Sales', 'Quantity', 'Discount', 'Profit', 'ShippingCost');


/** Cheking Range of Continuous Variables **/

-- Storing String Query
DECLARE @GetMinMax NVARCHAR(MAX);

-- Constructing Query
SELECT @GetMinMax = 
    
    STRING_AGG(
            ('SELECT 
                ''' + name + ''' AS ColumnName,
                MIN('+ name + ') AS MinValue,
                MAX(' + name +') AS MaxValue
            FROM
                Stores'
                ),
            ' UNION ALL ' 
            )
FROM
    sys.columns AS SysCol
        RIGHT JOIN
    #ContinuousVariables AS ContVar
    ON SysCol.name = ContVar.ColumnName

WHERE
    object_id = OBJECT_ID('Stores')

-- Executing Stored Query
EXEC(@GetMinMax);


/*-------------------------------------------------------------------------------------------------*/


/** Checking Suspicious Values **/

SELECT
    *
FROM
    Stores
WHERE
    Sales = 22638.480

--

SELECT
    *
FROM
    Stores
WHERE
    Profit IN(-6599.980, 8399.980)

--

SELECT
    *
FROM
    #DataInfo

/*-------------------------------------------------------------------------------------------------*/


/** Checking on negative profit values **/

SELECT
    *
FROM
    Stores
WHERE
    Profit < 0
ORDER BY
    Profit ASC;


/*-------------------------------------------------------------------------------------------------*/


/** Calculating Negative to Positve Profit ratio **/

WITH NegativeProfit AS (
        SELECT
            Year,
            SUM(Profit) AS NegativeProfit
        FROM
            Stores
        WHERE
            Profit < 0
        GROUP BY
            Year
),
    PositiveProfit AS (
        SELECT
            Year,
            SUM(Profit) AS PositiveProfit
        FROM
            Stores
        WHERE
            Profit > 0
        GROUP BY
            Year
)
SELECT
    NP.Year,
    FORMAT(NP.NegativeProfit, 'N0') AS NegativeProfit,
    FORMAT(PP.PositiveProfit, 'N0') AS PositiveProfit,
    FORMAT(ABS(NP.NegativeProfit)/PP.PositiveProfit, 'P2') AS NegativeToPositiveRatio
FROM
    NegativeProfit AS NP
        JOIN
    PositiveProfit AS PP
    ON NP.Year = PP.Year
ORDER BY
    NP.Year;


/*-------------------------------------------------------------------------------------------------*/


/** Identifying which categories contribute the most to cumulative negative profit over time **/

SELECT
    Year,
    Category,
    FORMAT(SUM(Profit), 'N0') AS NegativeProfit,
    FORMAT(
        SUM(Profit) + LAG(SUM(Profit)) OVER(PARTITION BY Category ORDER BY Year)
        , 'N0') AS YearlyIncreaseProfitLoss 
FROM
    Stores
WHERE
    Profit < 0
GROUP BY
    Year,
    Category
ORDER BY
    Category,
    Year;


/*-------------------------------------------------------------------------------------------------*/


/** Identifying which Markets and Segments contribute the most to negative profit transactions **/

WITH NegativeProfitMarketSegment AS (
    SELECT
        Market,
        Segment,
        SUM(Profit) AS TotalNegativeProfit,
        COUNT(Profit) AS TotalOrders
    FROM
        Stores
    WHERE
        Profit < 0
    GROUP BY
        Market,
        Segment
)
SELECT
    Market,
    Segment,
    DENSE_RANK() OVER(PARTITION BY Market ORDER BY TotalNegativeProfit) AS SegmentRank,
    FORMAT(TotalNegativeProfit, 'N0') AS TotalNegativeProfit,
    FORMAT(TotalOrders, 'N0') AS TotalOrder
FROM
    NegativeProfitMarketSegment
ORDER BY
    Market,
    SegmentRank;


/*-------------------------------------------------------------------------------------------------*/

/** Breaking down negative profit by shipping mode to uncover patterns or potential refund behavior **/

SELECT
    Shipmode,
    FORMAT(COUNT(OrderID),'N0') AS TotalOrders,
    FORMAT(SUM(Profit), 'N0') AS NegativeProfit,
    FORMAT(SUM(profit) / ( SUM(profit)
                            + (
                                SELECT 
                                    SUM(profit)
                                FROM
                                    stores
                                WHERE  
                                    profit < 0
                                    ) 
                                ), 'P2') AS Portion
FROM
    Stores
WHERE
    Profit < 0
GROUP BY
    Shipmode
ORDER BY
    SUM(Profit);


/*-------------------------------------------------------------------------------------------------*/


/** Creating a list of random OrderIDs to inspect and verify conclusion **/

SELECT
    OrderID,
    COUNT(OrderID) AS TotalOrders,
    SUM(Profit) AS TotalProfit
FROM
    Stores
WHERE
    Shipmode = 'Standard Class'
GROUP BY
    OrderID
ORDER BY
    SUM(Profit);


/*-------------------------------------------------------------------------------------------------*/


/** Inspecting random OrderIDs **/

SELECT
    OrderDate,
    OrderID,
    Sales,
    Discount,
    Quantity,
    FORMAT(Sales * Discount, 'N2') AS DiscountValue,
    FORMAT(Sales - (Sales * Discount), 'N2') AS NetRevenue,
    Profit,
    CASE
        WHEN Profit <0 THEN '-'
        ELSE '+'
    END AS 'ProfitFlag'
FROM
    Stores
WHERE
    OrderID IN('CA-2013-108196', 'CA-2011-169019', 'CA-2014-134845',
                'TU-2011-6790', 'CA-2013-130946', 'CA-2014-151750')     -- Random Selection
ORDER BY
    OrderID,
    Profit;

/*

Deep diving into negative profit revealed extreme cases where negative profit exceeds total sales value.

Which logically shouldn't happen. Is likely result from one or more of the following:

1. System glitches or data quality issues leading to invalid profit entries.
2. Double-counting discounts or misapplied business logic in ETL/Profit calculation.
3. As this is dummy data, the issue might stems from random value generation in the profit column.

*/



/*-------------------------------------------------------------------------------------------------*/
/*--------------------------------------- DATA CLEANING -------------------------------------------*/
/*-------------------------------------------------------------------------------------------------*/


/**  Fix for Combining US and Canada into 1 Market 'NorthAmerica' **/
BEGIN TRAN
UPDATE
    Stores
    SET Market=
        'NA'
    FROM
        Stores
    WHERE
        Market IN ('US', 'Canada');

-- ROLLBACK;
-- COMMIT;


/*-------------------------------------------------------------------------------------------------*/


/**  Fix for Market & Country Hierarchy Inconsistency  **/

--  Identifying Inconsistency
WITH Duplicates AS(
    SELECT
        MC.Country,
        COUNT(MC.Country) AS UniqueCount            -- Counts Unique Country (Serves as Flag)
        FROM (
            SELECT						            -- Stores combined Market & Country
                Market, 
                Country
            FROM
                Stores
            GROUP BY
                Market,
                Country
            ) AS MC
    GROUP BY
        MC.Country
)
SELECT
    ST.Market,
    ST.Country,
    COUNT(ST.Country) AS RegCount
FROM
    Stores AS ST
        JOIN
    Duplicates AS DU
    ON ST.Country = DU.Country
WHERE
    DU.UniqueCount > 1                              -- Return data with more than 1 unique count
GROUP BY
    ST.Market,
    ST.Country;


/*-------------------------------------------------------------------------------------------------*/


-- Assigning Correct Value, to be map for each Associated RowID in Update Statement
SELECT
    RowID,
    Market,
    Country,
    CASE
        WHEN Market = 'EMEA' AND Country = 'Austria' THEN 'EU'
        WHEN Market = 'EMEA' AND Country = 'Mongolia' THEN 'APAC'
    END AS CorrectMarket
INTO #ToChangeMarketCountry                         -- Saved Into Temporary Table
FROM
    Stores
WHERE
    Market = 'EMEA' AND Country = 'Austria'	
    OR Market = 'EMEA' AND Country = 'Mongolia';


/*-------------------------------------------------------------------------------------------------*/


-- Mapping Correct 'Market' for identified inconsistent data.
BEGIN TRAN
UPDATE
    Stores
    SET Market =
        CASE
            WHEN MC.RowID = ST.RowID THEN MC.CorrectMarket
        END
    FROM
        Stores AS ST
            LEFT JOIN
        #ToChangeMarketCountry AS MC
        ON MC.RowID = ST.RowID
    WHERE
        MC.RowID = ST.RowID;                                    -- Only matching RowID will be
                                                                -- affected by the update
-- ROLLBACK;
-- COMMIT;


/*-------------------------------------------------------------------------------------------------*/


/**  Fix for SubCategory & ProductName Hierarchy Inconsistency  **/

--  Identifying Inconsistency
WITH Duplicates AS(
    SELECT
        SP.ProductName,
        COUNT(SP.ProductName) AS UniqueCount                -- Count Unique ProductName (Servers as Flag)
        FROM (
            SELECT                                          -- Stores combined SubCategory 
                SubCategory,                                -- & ProductName
                ProductName
            FROM
                Stores
            GROUP BY
                SubCategory, 
                ProductName
            ) AS SP
    GROUP BY
        SP.ProductName
)
SELECT
    ST.Category,
    ST.SubCategory,
    ST.ProductName,
    COUNT(ST.ProductName) AS RegCount
FROM
    Stores AS ST
        JOIN
    Duplicates AS DU								
    ON ST.ProductName = DU.ProductName
WHERE
    DU.UniqueCount > 1                                      -- Return data with more than 1 unique count
GROUP BY
    ST.Category,
    ST.SubCategory,
    ST.ProductName;


/*-------------------------------------------------------------------------------------------------*/


-- Assigning Correct Value, to be map for each Associated RowID in Update Statement
SELECT
    RowID,
    SubCategory,
    ProductName,
    'Fasteners' AS CorrectSubCategory,
    'Office Supplies' AS CorrectCategory
INTO #ToChangeSubCategoryProductName                        -- Saved into Temporary Table
FROM
    Stores
WHERE
    SubCategory != 'Fasteners' AND ProductName = 'Staples';


/*-------------------------------------------------------------------------------------------------*/


-- Mapping Correct 'SubCategory' for identified inconsistent data
BEGIN TRAN
UPDATE
    Stores
    SET SubCategory =
        CASE
            WHEN SP.RowID = ST.RowID THEN SP.CorrectSubCategory     -- Maps Correct Values
        END,
    Category =
        CASE
            WHEN SP.RowID = ST.RowID THEN SP.CorrectCategory
        END
    FROM
        Stores AS ST
            LEFT JOIN
        #ToChangeSubCategoryProductName AS SP
        ON SP.RowID = ST.RowID
    WHERE
        SP.RowID = ST.RowID;                                        -- Only matching RowID will be
                                                                    -- affected by the update
 --ROLLBACK;
-- COMMIT;


/*-------------------------------------------------------------------------------------------------*/
/*------------------------------ ADDING DATE RELATED COLUMNS --------------------------------------*/
/*-------------------------------------------------------------------------------------------------*/


-- Adding Date related columns
ALTER TABLE Stores
ADD MonthName	NVARCHAR(30) NULL, 
    MonthNo		TINYINT NULL,
    QuarterNo	NVARCHAR(5) NULL,
    Year		SMALLINT NULL;


/*-------------------------------------------------------------------------------------------------*/


-- Inspecting Result before populating the table
SELECT
    TOP 5 LEFT(DATENAME(MONTH,OrderDate),3) AS MonthName,
    MONTH(OrderDate) AS MonthNo,
    CONCAT('Q', DATEPART(QUARTER,OrderDate)) AS QuarterNo,
    YEAR(Orderdate) AS Year
FROM
    Stores;


/*-------------------------------------------------------------------------------------------------*/


-- Populating the columns.
BEGIN TRAN
UPDATE Stores
SET 
    MonthName = LEFT(DATENAME(MONTH, OrderDate), 3),
    QuarterNo = CONCAT('Q', DATEPART(QUARTER,OrderDate)),
    MonthNo = MONTH(OrderDate),
    Year = YEAR(OrderDate)
WHERE
    OrderDate IS NOT NULL;

--ROLLBACK;
--COMMIT;


/*-------------------------------------------------------------------------------------------------*/


-- Checking Result
SELECT
    TOP 5 *
FROM
    Stores;


/*-------------------------------------------------------------------------------------------------*/
/*------------------------------------- DATA EXPLORATION ------------------------------------------*/
/*-------------------------------------------------------------------------------------------------*/


/** Calculate Yearly sales, orders, Profit margin, and YoY sales increase **/

SELECT
    Year,
    FORMAT(SUM(Sales), 'N0') AS TotalSales,
    FORMAT(COUNT(Segment), 'N0') AS TotalOrders,
    FORMAT(SUM(Profit)/ SUM(Sales), 'P2') AS ProfitMargin,
    FORMAT(
        (SUM(Sales) - LAG(SUM(Sales)) OVER(ORDER BY Year)) / LAG(SUM(Sales)) OVER(ORDER BY Year)
        , 'P2') AS YoYSalesIncrease
FROM
    Stores
GROUP BY
    Year
ORDER BY
    Year DESC;


/*-------------------------------------------------------------------------------------------------*/


/** Calculates quarterly and monthly sales and orders totals to identify trends **/

SELECT
    QuarterNo,
    MonthName,
    FORMAT(SUM(Sales), 'N0') AS TotalSales,
    FORMAT(COUNT(Segment), 'N0') AS TotalOrders
FROM
    Stores
GROUP BY
    QuarterNo,
    MonthNo,
    MonthName
ORDER BY
    MonthNo;


/*-------------------------------------------------------------------------------------------------*/


/** Analyzes market performance by average sales, and order volume  **/

SELECT
    COUNT(DISTINCT Country) AS CountryCount,
    Market,
    FORMAT(AVG(Sales), 'N0') AS AvgSales,
    FORMAT(COUNT(Market), 'N0') AS TotalOrder
FROM
    Stores
GROUP BY
    Market
ORDER BY
    CountryCount; 


/*-------------------------------------------------------------------------------------------------*/

/** Calculates Market's Segments Total Sales Distribution **/

SELECT
    Market,
    FORMAT(Consumer, 'N0') AS ConsumerSales,
    FORMAT(Corporate, 'N0') AS CorporateSales,
    FORMAT([Home Office], 'N0') AS HomeOfficeSales
FROM
    (
    SELECT
        Market,
        Segment,
        Sales
    FROM
        Stores
        ) AS TableSource
            PIVOT
        (
            SUM(Sales)						-- Creates 3 columns that represents 
            FOR Segment						-- each segments total sales
            IN ([Consumer], [Corporate], [Home Office])
        ) AS PivoTable


/*-------------------------------------------------------------------------------------------------*/


/** Analyzes Total Orders, Sales for each segments and Average Sales per order **/

SELECT
    Segment,
    FORMAT(COUNT(Segment), 'N0') AS TotalOrders,
    FORMAT(SUM(Sales), 'N0') AS TotalSales,
    ROUND(CAST(AVG(Sales) AS FLOAT),2) AS AvgSales
FROM
    Stores
GROUP BY
    Segment
ORDER BY
    Segment;


/*-------------------------------------------------------------------------------------------------*/


/** Calculates Orders distribution in % for each segment, and discounted products impact **/

WITH OrderDistribution AS (
    SELECT                                                      -- Pivoted table with each segments
        QuarterNo,                                              -- data converted to percentage
        MonthName,
        SUM(CAST(Consumer AS FLOAT))  / SUM(SUM(Consumer)) OVER() AS Consumer,
        SUM(CAST(Corporate AS FLOAT)) / SUM(SUM(Corporate)) OVER()  AS Corporate,
        SUM(CAST([Home Office] AS FLOAT)) / SUM(SUM([Home Office])) OVER() AS HomeOffice
    FROM
    (
        SELECT
            QuarterNo,
            MonthName,
            MonthNo,
            ProductName,
            Segment
        FROM
            Stores
            ) AS TableSource
                PIVOT
            (
                COUNT(ProductName)                              -- Count order per segment
                FOR Segment
                IN ([Consumer], [Corporate], [Home Office])     -- Creates 3 columns for each segments
            ) AS PivotTable                                     -- with each having total order
    GROUP BY
        QuarterNo,
        MonthName
    ),
MonthlyDiscounts AS (
    SELECT
        MonthNo,
        MonthName,
        SUM(CASE
                WHEN Discount > 0.000 THEN 1                    -- 1 represents a product was sold with
                ELSE 0                                          -- with discount. Enables to calculate
            END) AS DiscountedProductCount                      -- total products sold with discount
    FROM
        Stores
    GROUP BY
        MonthNo,
        MonthName
)
SELECT                                                          -- Formatted data for clarity
    TD.MonthName,
    FORMAT(TD.Consumer, 'P2') AS 'ConsumerOrder(%)',
    FORMAT(TD.Corporate, 'P2') AS 'CorporateOrder(%)',
    FORMAT(TD.HomeOffice, 'P2') AS 'HomeOfficeOrder(%)',
    FORMAT(MD.DiscountedProductCount, 'N0') AS DiscountedProductCount
FROM
    OrderDistribution AS TD
        JOIN
    MonthlyDiscounts AS MD
    ON TD.MonthName = MD.MonthName
ORDER BY
    TD.QuarterNo,
    MD.MonthNo;


/*-------------------------------------------------------------------------------------------------*/


/** Creating a table to store a random sample, avoiding NEWID() reordering for reproducibility. **/

IF OBJECT_ID('RandomSample_Sales') IS NOT NULL DROP TABLE RandomSample_Sales;

CREATE TABLE RandomSample_Sales (
    ShippingCost	DECIMAL(10,2),
    Discount		DECIMAL(5,3),
    Sales		DECIMAL(10,2)
)

-- Populating Random Sample Table
INSERT INTO RandomSample_Sales (ShippingCost, Discount, Sales)
    SELECT 
        TOP 1000
        ShippingCost,
        Discount,
        Sales
    FROM 
        Stores
    ORDER BY 
        NEWID();


-- Checking Result

SELECT
    *
FROM
    RandomSample_Sales;


/*-------------------------------------------------------------------------------------------------*/


/** Creates a benchmark to filter products perfomance by SubCategory **/

WITH ProductSalesInfo AS (
    SELECT
        Category,
        SubCategory,
        ProductName,
        AVG(Sales) AS AvgSales,
        SUM(Sales) AS TotalSales
    FROM
        Stores
    GROUP BY
        Category,
        SubCategory,
        ProductName
    ),
SubCategoryBenchmark AS (                               -- Percentiles for each Subcategory
    SELECT                                              -- AvgSales that would serve as Benchmark
        DISTINCT SubCategory,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY AvgSales) OVER (PARTITION BY SubCategory) AS P25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY AvgSales) OVER (PARTITION BY SubCategory) AS P50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY AvgSales) OVER (PARTITION BY SubCategory) AS P75
    FROM
        ProductSalesInfo
)
SELECT
    PSI.Category,
    PSI.SubCategory,
    PSI.ProductName,
    PSI.TotalSales,
    CASE                                                -- Flag for products AvgSales performance
        WHEN PSI.AvgSales >= SCB.P75 THEN 'High'
        WHEN PSI.AvgSales >= SCB.P50 AND PSI.AvgSales < SCB.P75 THEN 'Moderate'
        ELSE 'Low'
    END AS AvgSalesPerformance
INTO #ProductPerformance                                -- Saved into temporary table
FROM
    ProductSalesInfo AS PSI
        JOIN
    SubCategoryBenchmark AS SCB
    ON PSI.SubCategory = SCB.SubCategory
ORDER BY
    PSI.Category,
    PSI.AvgSales DESC;


/** Calcutes Product count, Total Sales and Sales distribution in % for each Product Performance **/

SELECT
    AvgSalesPerformance,
    COUNT(ProductName) AS ProductCount,
    FORMAT(SUM(TotalSales), 'N0') AS TotalSales,
    FORMAT(SUM(TotalSales)/ SUM(SUM(TotalSales)) OVER(), 'P2') AS 'SalesDistribution%'
FROM
    #ProductPerformance
GROUP BY
    AvgSalesPerformance
ORDER BY
    SUM(TotalSales) DESC;


/*-------------------------------------------------------------------------------------------------*/


/** Calculates the percentage distribution of total sales within each categories performance group **/

SELECT
    Category,                                           -- Formatted for clarity
    FORMAT(High, 'P2') AS High,
    FORMAT(Moderate, 'P2') AS Moderate,
    FORMAT(Low, 'P2') AS Low
FROM
(
    
    SELECT                                              -- Calculates Sales distribution
        Category,                                       -- percentage for each category
        AvgSalesPerformance,                            -- and product performance
        SUM(TotalSales) / SUM(SUM(TotalSales)) OVER(PARTITION BY Category) AS TotalSalesPercentage
    FROM
        #ProductPerformance
    GROUP BY
        Category,
        AvgSalesPerformance
    )AS TableSource
        PIVOT
        (
        SUM(TotalSalesPercentage)                       -- Sum of total Sales percentage
        FOR AvgSalesPerformance	                        -- for each product performance
        IN ([High], [Moderate], [Low])
        )AS PivotTable;


/*-------------------------------------------------------------------------------------------------*/
/*------------------------------------- DATA FOR DASHBOARD ----------------------------------------*/
/*-------------------------------------------------------------------------------------------------*/


/** Product Table **/

-- Creating Product Table
IF OBJECT_ID('DIM_Product') IS NOT NULL DROP TABLE DIM_Product;

CREATE TABLE DIM_Product (
    ProductID		NVARCHAR(150) UNIQUE NOT NULL,
    ProductName		NVARCHAR(250) UNIQUE NOT NULL,
    Performance		NVARCHAR(50) NOT NULL,
    SubCategory		NVARCHAR(50) NOT NULL,
    Category		NVARCHAR(50) NOT NULL
);

-- Populating Product Table
INSERT INTO DIM_Product(ProductID, ProductName, Performance, SubCategory, Category)

SELECT                                                  -- Creates combined abbrevation of
    CONCAT(                                             -- Category and SubCategory with product 
        UPPER(LEFT(Category, 3)), '-',                  -- number starting at 100,000 and increment by 1
        UPPER(LEFT(SubCategory, 2)), '-',               -- increment reset to 0 for each SubCategory
        CAST(ROW_NUMBER() OVER(PARTITION BY SubCategory ORDER BY Category) + 100000 
    AS NVARCHAR)) AS ProductID,
    ProductName,
    AvgSalesPerformance,
    SubCategory,
    Category
FROM
    #ProductPerformance;


/*-------------------------------------------------------------------------------------------------*/


/** Country Market Table **/

-- Creating Country Table
IF OBJECT_ID('DIM_CountryMarket') IS NOT NULL DROP TABLE DIM_CountryMarket;

CREATE TABLE DIM_CountryMarket(
    CountryID       NVARCHAR(50) NOT NULL,
    CountryName     NVARCHAR(70) UNIQUE NOT NULL,
    Market          NVARCHAR(50) NOT NULL
);

-- Populating Country Market Table
INSERT INTO DIM_CountryMarket(CountryID, CountryName, Market)

SELECT                                                  -- Creates a combine Market name with number
    CAST(                                               -- that starts from 1000 and increment by 1
        CONCAT(UPPER(Market), '-',                      -- reset to 0 for each market region
        ROW_NUMBER() OVER(PARTITION BY Market ORDER BY Country) + 1000) 
    AS NVARCHAR) AS CountryMarketID,
    CY.Country,
    Market
FROM
    (
    SELECT
        DISTINCT Country,
        Market
    FROM
        Stores
    )AS CY


/*-------------------------------------------------------------------------------------------------*/


/** Segment Table **/

-- Creating Segment Table
IF OBJECT_ID('DIM_Segment') IS NOT NULL DROP TABLE DIM_Segment;

CREATE TABLE DIM_Segment(
    SegmentID   TINYINT NOT NULL,
    Segment	    NVARCHAR(30) UNIQUE NOT NULL
);

-- Populating Segment Table
INSERT INTO DIM_Segment(SegmentID, Segment)

SELECT
    ROW_NUMBER() OVER(ORDER BY Segment) AS SegmentID,
    Segment
FROM
    (
    SELECT
        DISTINCT Segment
    FROM
        Stores
    ) AS Seg;


/*-------------------------------------------------------------------------------------------------*/


/** Date Table **/

-- Start and End Dates of the Dataset
SELECT
    MIN(OrderDate) AS StartDate,
    MAX(OrderDate) AS EndDate
FROM
    Stores;

-- Creating Date table
IF OBJECT_ID('DIM_Date') IS NOT NULL DROP TABLE DIM_Date;

CREATE TABLE DIM_Date(
    Date        DATE UNIQUE NOT NULL,
    Day         TINYINT NOT NULL,
    MonthNo     TINYINT NOT NULL,
    MonthName   NVARCHAR(30) NOT NULL,
    QuarterNo   NVARCHAR(30) NOT NULL,
    Year        SMALLINT NOT NULL
);

-- Populating Date Table
DECLARE @StartDate DATE = '2011-01-01';                     -- Dataset Start date
DECLARE @EndDate DATE = '2014-12-31';                       -- Dataset End date
DECLARE @Counter INT = 1;                                   -- Start No. (Day)

WHILE
    @StartDate <= @EndDate                                  -- A Condition, to stop
                                                            -- iteration if met
    BEGIN
        INSERT INTO DIM_Date(Date, Day, MonthNo, MonthName, QuarterNo, Year)

        VALUES
            (
                @StartDate,                                 -- Date 'YYYY-MM-DD'
                DAY(@StartDate),                            -- Date No.
                DATEPART(MM, @StartDate),                   -- Month No.
                LEFT(DATENAME(MONTH, @StartDate), 3),       -- Month Name First 3 letters
                CONCAT('Q',DATEPART(QUARTER, @StartDate)),  -- Quarter No.
                YEAR(@StartDate)                            -- Year No.
            )
        SET @Counter += 1                                   -- Increment by 1
        SET @StartDate = DATEADD(Day, 1, @StartDate)        -- Increment @StartDate by 1
                                                            -- for the next iteration
    END;


/*-------------------------------------------------------------------------------------------------*/


/** Creating Fact Table (Transaction Records) **/

-- Creating Fact table
IF OBJECT_ID('FACT_Sales') IS NOT NULL DROP TABLE FACT_Sales;

CREATE TABLE FACT_Sales(
    OrderDate	DATE NOT NULL,
    SegmentID	TINYINT NOT NULL,
    CountryID	NVARCHAR(50) NOT NULL,
    ProductID	NVARCHAR(150) NOT NULL,
    Sales       DECIMAL(10,2) NOT NULL,
    Quantity	TINYINT NOT NULL,
    Discount	DECIMAL(5,3) NOT NULL,
    Discounted	NVARCHAR(50) NOT NULL,
    Profit      DECIMAL(10,2) NOT NULL

);

-- Populating Fact table
INSERT INTO FACT_Sales(OrderDate, SegmentID, CountryID, ProductID, Sales, Quantity, Discount, Discounted, Profit)

SELECT
    ST.OrderDate,
    --DT.Date,
    --ST.Segment,
    DS.SegmentID,
    --ST.Country,
    DCM.CountryID,
    --ST.ProductName,
    DP.ProductID,
    ST.Sales,
    ST.Quantity,
    ST.Discount,
    CASE
        WHEN Discount > 0.000 THEN 'Yes'
        ELSE 'No'
    END AS IsDiscounted,
    ST.Profit
FROM
    Stores AS ST
        JOIN
    DIM_Date AS DT
    ON ST.OrderDate = DT.Date
        JOIN
    DIM_Segment AS DS
    ON ST.Segment = DS.Segment
        JOIN
    DIM_CountryMarket AS DCM
    ON ST.Country = DCM.CountryName
        JOIN
    DIM_Product AS DP
    ON ST.ProductName = DP.ProductName;