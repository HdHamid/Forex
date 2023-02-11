CREATE PROCEDURE [Test].[GetClass]
AS
set nocount on

TRUNCATE TABLE EURUSD_H1 
INSERT INTO EURUSD_H1
SELECT * FROM EURUSD_H1_History 
WHERE [Time] <=  '2020-05-01 00:00:00.000'



DROP TABLE IF EXISTS #Res
CREATE TABLE #Res 
(
	ID INT IDENTITY(1,1),
	TrendID	INT,
	ClassName VARCHAR(50),
	TrendCandles INT,
	TrendDayCount	INT,
	ClassAvgDayCount INT, 
	DateFrom  DATETIME,
	DateTo DATETIME
)




WHILE EXISTS 
	(SELECT 1 FROM EURUSD_H1_History H WHERE NOT EXISTS (SELECT 1 FROM EURUSD_H1 H1 WHERE H1.[Time] = H.[Time]))
BEGIN	
	DECLARE @Date DATETIME = (SELECT MAX([Time]) FROM EURUSD_H1)

	DECLARE @Res TABLE  
	(		
		TrendID	INT,
		ClassName VARCHAR(50),
		TrendCandles INT,
		TrendDayCount	INT,
		ClassAvgDayCount INT, 
		DateFrom  DATETIME,
		DateTo DATETIME
	)


	insert into EURUSD_H1
	select TOP 24 * from EURUSD_H1_History 
	where [Time] > @Date
	ORDER BY [Time]

	INSERT INTO @Res
	EXEC [dbo].[GetCurrentClass]

	INSERT INTO #Res 
	SELECT * FROM @Res V WHERE NOT EXISTS (SELECT 1 FROM #Res R WHERE R.ClassName = V.ClassName AND R.DateFrom = V.DateFrom AND R.DateTo = V.DateTo)
END 




