CREATE PROCEDURE [Test].[GetLMSCorelations]
AS
set nocount on

TRUNCATE TABLE EURUSD_H1 
INSERT INTO EURUSD_H1
SELECT * FROM EURUSD_H1_History 
WHERE [Time] <=  '2020-05-01 00:00:00.000'



DROP TABLE IF EXISTS ##Res
CREATE TABLE ##Res 
(
	LongCor Decimal(10,5),
	MidCor Decimal(10,5),
	ShortCor Decimal(10,5),
	LongFromDate DATETIME,
	MidFromDate DATETIME,
	ShortFromDate DATETIME,
	ToDate DATETIME
)


WHILE EXISTS 
	(SELECT 1 FROM EURUSD_H1_History H WHERE NOT EXISTS (SELECT 1 FROM EURUSD_H1 H1 WHERE H1.[Time] = H.[Time]))
BEGIN	
	DECLARE @Date DATETIME = (SELECT MAX([Time]) FROM EURUSD_H1)

	DECLARE @TblL TABLE
	(
		LongCor DECIMAL(10,5),
		LongFromDate DATETIME,
		LongToDate DATETIME
	)
	
	DECLARE @TblM TABLE
	(
		MidCor DECIMAL(10,5),
		MidFromDate DATETIME,
		MidToDate DATETIME
	)
	
	DECLARE @TblS TABLE
	(
		ShortCor DECIMAL(10,5),
		ShortFromDate DATETIME,
		ShortToDate DATETIME
	)

	
	INSERT INTO @TblL
	exec GetLongTermRegression

	INSERT INTO @TblM
	exec GetMidTermRegression

	INSERT INTO @TblS
	exec GetShortTermRegression
	
	INSERT INTO ##Res 
	SELECT L.LongCor,M.MidCor,S.ShortCor,L.LongFromDate,M.MidFromDate,S.ShortFromDate,L.LongToDate FROM  @TblL L 
		INNER JOIN @TblM M ON 1=1 
		INNER JOIN @TblS S ON 1=1 

	insert into EURUSD_H1
	select TOP 24 * from EURUSD_H1_History 
	where [Time] > @Date
	ORDER BY [Time]

	DELETE @TblL 
	DELETE @TblM 
	DELETE @TblS 

END 


DROP TABLE IF EXISTS #Src
SELECT ROW_NUMBER() OVER(ORDER BY [TIME]) RN ,* INTO #Src FROM EURUSD_H1


DROP TABLE IF EXISTS #Chk1
SELECT R.LongCor,r.MidCor,r.ShortCor,H1.[Time],H1.[Close] AS CloseFrom,H2.[Close] AS CloseTo,(H1.[Close] - H2.[Close])*10000 AS Diff
	,IIF(H1.[Close] - H2.[Close] < 0 ,'Sell','Buy') as typ
INTO #Chk1
FROM ##Res R 
INNER JOIN #Src H1 ON R.ToDate = H1.[Time]
INNER JOIN #Src H2 ON H2.RN = H1.RN+50




;WITH STP1 AS 
(
	SELECT AVG(LongCor) AS AVGLongCor,AVG(MidCor) AS AVGMidCor,AVG(ShortCor) AS AVGShortCor,typ FROM #Chk1
	GROUP BY typ
),
STP2 AS 
(
	SELECT NTILE(2) OVER(PARTITION BY typ ORDER BY LongCor)NTILELongCor,
	 NTILE(2) OVER(PARTITION BY typ ORDER BY MidCor)NTILEMidCor,
	 NTILE(2) OVER(PARTITION BY typ ORDER BY ShortCor)NTILEShortCor,
	*
	FROM #Chk1	
)
,STP3 AS 
(
	SELECT MAX(LongCor) NTILELongCor,typ FROM STP2 WHERE NTILELongCor = 1
	GROUP BY typ
)
,STP4 AS 
(
	SELECT MAX(MidCor) NTILEMidCor,typ FROM STP2 WHERE NTILEMidCor = 1
	GROUP BY typ
)
,STP5 AS 
(
	SELECT MAX(ShortCor) NTILEShortCor,typ FROM STP2 WHERE NTILEShortCor = 1
	GROUP BY typ
)
SELECT * FROM STP1 S1
	INNER JOIN STP3	S3 ON  S1.typ =  S3.typ
	INNER JOIN STP4	S4 ON  S1.typ =  S4.typ
	INNER JOIN STP5	S5 ON  S1.typ =  S5.typ