CREATE PROCEDURE [Calc].[WeeklyChandelier_Exit]
	 @trend int OUT 
AS

--atr = MathMax(high[i-k],close[MathMax(i-k-1,0)])- MathMin(low[i-k],close[MathMax(i-k-1,0)]); 
DROP TABLE IF EXISTS #stp1
;with stp1 as 
(
	SELECT 
	top 50
		H1.[Time] AS [Time]
		,h1.[Close]
		,h1.[High]
		,h1.[Low]
		,h1.[Open]		
		,LAG([close],2) over(order by [time]) AS [Lag2Close]
		,LAG([High]) over(order by [time]) AS [LagHigh]
		,LAG([Low]) over(order by [time]) AS [LagLow]	
	FROM EURUSD_W H1
	ORDER BY [Time] DESC 
)
, stpAtr as 
(
	SELECT * 
		,IIF([LagHigh]>[Lag2Close],[LagHigh],[Lag2Close]) - IIF([LagLow]<[Lag2Close],[LagLow],[Lag2Close]) AS Atr -- Formula from MT5 sample
	FROM stp1
)
select 
	ROW_NUMBER() OVER(ORDER BY [TIME]) AS i
	,*
	,IIF([High]>[LagHigh],[High],[LagHigh]) AS _max
	,IIF([Low]<[LagLow],[Low],[LagLow])	AS _min
into #stp1 from stpAtr


--work[i][_hi1]    = _max-AtrMultiplier1*_atr;
--work[i][_lo1]    = _min+AtrMultiplier1*_atr;
DROP TABLE IF EXISTS #Stp2
;WITH STP1 AS
(
	SELECT *
		,_max-(2*Atr) AS _hi1 
		,_min+(2*Atr) AS _lo1
	FROM #stp1
)
SELECT * 
	,LAG([_hi1]) over(order by [time]) AS [Lag_hi1]
	,LAG([_lo1]) over(order by [time]) AS [Lag_lo1]
INTO #Stp2
FROM STP1



--work[i][_trend1] = (i>0) ? work[i-1][_trend1] : 0;
--if(close[i] > work[i-1][_lo1]) work[i][_trend1]=  1;
--if(close[i] < work[i-1][_hi1]) work[i][_trend1]= -1;
DROP TABLE IF EXISTS #stp3
;WITH STP3 AS 
(
	SELECT *,0 as [Trend] FROM #Stp2 S WHERE i=1
	UNION ALL 
	SELECT S2.*
		,ISNULL(CASE 
					WHEN S2.[Close] < S2.Lag_hi1 THEN -1
					WHEN S2.[Close] > S2.Lag_lo1 THEN 1
				END,
				S3.Trend) AS [Trend] 
	FROM #Stp2 S2 
	INNER JOIN STP3 S3 ON S3.i = S2.i-1
)
SELECT * INTO #stp3 FROM STP3
OPTION(MAXRECURSION 32000)

SELECT TOP 1 @trend = Trend FROM #stp3
ORDER BY [Time] DESC 


--SELECT * FROM #stp3
--ORDER BY [Time] 


