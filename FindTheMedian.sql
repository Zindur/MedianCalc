-- MEDIANA v1 Bad Performance but right way
;WITH x2 AS (
        -- double info for Mediana
        SELECT t1.*
        FROM dbo.TableName t1
        UNION ALL
        SELECT t1.*
        FROM dbo.TableName t1
)
SELECT AVG (DISTINCT ColumnForMedian)
FROM x2
WHERE
    (
        SELECT COUNT(*)
        FROM x2 xx2
        WHERE ColumnForMedian <= x2.ColumnForMedian
    ) >= (SELECT COUNT(*) FROM dbo.TableName)
AND
    (
        SELECT Count(*)
        FROM x2 xx2
        WHERE ColumnForMedian >= x2.ColumnForMedian
    ) >= (SELECT COUNT(*) FROM dbo.TableName)



-- MEDIANA v2 better perfomance (no duplcation)
-- index should exist on ColumnForMedian
;WITH BottomPrice as (
        SELECT p1.IdColumn, p1.ColumnForMedian
        FROM dbo.TableName p1
        INNER JOIN dbo.TableName p2 ON p1.ColumnForMedian <= p2.ColumnForMedian
        GROUP BY p1.IdColumn, p1.ColumnForMedian
        HAVING COUNT(*) >= (SELECT Ceiling(COUNT(*)/2) FROM dbo.TableName)
),
TopPrice as(
        SELECT p1.IdColumn, p1.ColumnForMedian
        FROM dbo.TableName p1
        INNER JOIN dbo.TableName p2 ON p1.ColumnForMedian >= p2.ColumnForMedian
        GROUP BY p1.IdColumn, p1.ColumnForMedian
        HAVING COUNT(*) >= (SELECT Ceiling(COUNT(*)/2) FROM dbo.TableName)
),MiddlePrice as (
        SELECT * 
        FROM BottomPrice
        WHERE ColumnForMedian = (SELECT MIN (ColumnForMedian) FROM TopPrice)
        UNION ALL
        SELECT * 
        FROM TopPrice
        WHERE ColumnForMedian = (SELECT MAX (ColumnForMedian) FROM BottomPrice)
)
SELECT AVG(ColumnForMedian)
FROM MiddlePrice


-- Mediana v3 
;WITH MyProduct (IdColumn,ColumnForMedian,Num1) AS
            (
            SELECT  IdColumn
                    ,ColumnForMedian
                    ,Row_Number() OVER (ORDER BY ColumnForMedian ASC)
            FROM dbo.TableName t1
            )
SELECT AVG(ColumnForMedian)
FROM MyProduct 
WHERE
    -- Dealling Pair and not pair count
    Num1 IN (SELECT Ceiling(COUNT(*)/2.0) FROM dbo.TableName
            UNION ALL
            SELECT FLOOR(COUNT(*)/2.0 + 1) FROM dbo.TableName
            )


-- Mediana v4
-- MSSQL >= 2012 
-- tested and was getting really bad performance :(
 
SELECT TOP 1 PERCENTILE_CONT (0.5)
        WITHIN GROUP (ORDER BY ColumnForMedian)
        OVER ()
FROM dbo.TableName



-- Mediana v5
-- use temp table
CREATE TABLE  #ColumnForMedian
(
    ColumnForMedian money
    ,Amount int
)
INSERT INTO #ColumnForMedian
SELECT ColumnForMedian, Count(*)
FROM dbo.TableName 
GROUP BY ColumnForMedian
 
create index ind on #ColumnForMedian (ColumnForMedian)
 
CREATE TABLE  #ColumnForMedian2
(
    ColumnForMedian money
    ,Less int
    ,LessOrEqual int
)
 
INSERT INTO #ColumnForMedian2
SELECT p1.ColumnForMedian
    ,Sum(p2.Amount) - p1.Amount
    ,Sum(p2.Amount)
FROM #ColumnForMedian p1
INNER JOIN #ColumnForMedian p2 ON p1.ColumnForMedian > = p2.ColumnForMedian
GROUP BY p1.ColumnForMedian, p1.Amount
 
DECLARE @Half real
SELECT @Half = MAX(LessOrEqual)/2.0
FROM #ColumnForMedian2
 
-- callc mediana
SELECT AVG(ColumnForMedian)
FROM #ColumnForMedian2
WHERE @Half BETWEEN Less and LessOrEqual
 
drop table #ColumnForMedian
drop table #ColumnForMedian2