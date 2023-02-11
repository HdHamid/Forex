CREATE PROCEDURE [Calc].[FillWeekly] 
AS 

DROP TABLE IF EXISTS #Weekly
select 
	dd.EnYear,
	dd.EnMonth,
	dd.EnMonthName,
	dd.WeekOfYr,
	DD.Endt,
	FIRST_VALUE([Open])  over(partition by dd.EnYear,dd.EnMonth,dd.EnMonthName,dd.WeekOfYr order by h1.[Time]) AS W1_Open,
	max([High])  over(partition by dd.EnYear,dd.EnMonth,dd.EnMonthName,dd.WeekOfYr) AS W1_High,
	min([Low])  over (partition by dd.EnYear,dd.EnMonth,dd.EnMonthName,dd.WeekOfYr) AS W1_Low,
	LAST_VALUE([Close]) over(partition by dd.EnYear,dd.EnMonth,dd.EnMonthName,dd.WeekOfYr order by h1.[Time] ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS W1_Close,
	SUM(Volume) over(partition by dd.EnYear,dd.EnMonth,dd.EnMonthName,dd.WeekOfYr) AS Vol	
into #Weekly
from EURUSD_H1	h1 
	inner join DimDate dd on dd.ID = h1.DateId


DROP TABLE IF EXISTS #stp1
;WITH STP1 AS 
(
SELECT ROW_NUMBER() over(partition by 
	EnYear,		
	WeekOfYr
	order by Endt) as rn
	,* FROM #Weekly w 
)
SELECT *
INTO #stp1
FROM STP1 WHERE RN = 1 

TRUNCATE TABLE EURUSD_W

;WITH STP1 AS 
(
SELECT ROW_NUMBER() OVER(PARTITION BY DD.EnDt ORDER BY D.Endt) AS RN,DD.FrDayOfWeek,DD.EnNoDayOfWeek,DD.Endt,E.W1_Open,E.W1_High,E.W1_Low,E.W1_Close,E.Vol
FROM #stp1 E 
	INNER JOIN 	DimDate D ON D.Endt = E.Endt
	INNER JOIN 	DimDate DD ON DD.SeqWeekEn = D.SeqWeekEn AND DD.EnNoDayOfWeek = 1 --AND D.WeekOfYr IS NOT NULL
)
INSERT INTO EURUSD_W ([Time],[OPEN],[HIGH],[LOW],[CLOSE],[VOLUME],DateId)
SELECT 
	E.Endt,W1_Open,W1_High,W1_Low,W1_Close,Vol,D.ID
FROM STP1 E 
	INNER JOIN DimDate D ON D.Endt = E.Endt AND RN = 1

--SELECT * FROM EURUSD_W WHERE [Time] BETWEEN '2020-12-20' AND '2021-01-27'
--ORDER BY [Time]
	

