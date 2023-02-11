CREATE PROCEDURE GetMidTermRegression 
	@CandleCount INT = 500
AS

DROP TABLE IF EXISTS #PIVOT

DROP TABLE IF EXISTS #TBCUR
SELECT TOP (@CandleCount) ROW_NUMBER()OVER(ORDER BY [Time]) As RowNo,
	IIF([Open] > [Close] , [Open] , [Close] ) as CandleCeiling
	,IIF([Open] > [Close] , [Close] , [Open] ) as CandleFloor
	,[Time] ,[Open] ,[High] ,[Low]  ,[Close],Volume ,DateId ,RegDate
	,2 AS MX
	,-1 AS [Min]
INTO #TBCUR FROM  Dbo.EURUSD_H1
ORDER BY [Time] DESC


select 
	ROW_NUMBER()OVER(ORDER BY [Time]) AS xAxis
	,*
into #PIVOT
from #TBCUR


DECLARE
	@syHigh DECIMAL(38,5),
	@sxHigh DECIMAL(38,5),
	@sxxHigh DECIMAL(38,5),
	@sxyHigh DECIMAL(38,5),
	@syyHigh DECIMAL(38,5),
	@countHigh DECIMAL(38,5),
	@alphaHigh DECIMAL(38,5),
	@betaHigh DECIMAL(38,5),
	@Corelation DECIMAL(38,5)



DROP TABLE IF EXISTS #PreRegHigh
;WITH stp1 AS 
	(
		SELECT [time], xAxis AS x ,f.[high] AS y 
		FROM #PIVOT f		
	)
SELECT * INTO #PreRegHigh FROM stp1


SELECT 
	@syHigh = sum(y),
	@sxHigh = sum(x),
	@sxxHigh = sum(x*x),
	@sxyHigh = sum(x*y),
	@syyHigh = sum(y*y),
	@countHigh = Count(1)
FROM #PreRegHigh

select @alphaHigh = ((@syHigh*@sxxHigh) - (@sxHigh*@sxyHigh))
				/( (@countHigh*@sxxHigh) - (@sxHigh*@sxHigh) )
	   ,@betaHigh = ((@countHigh*@sxyHigh) - (@sxHigh*@syHigh))
				/( (@countHigh*@sxxHigh) - (@sxHigh*@sxHigh))
	   ,@Corelation = ((@countHigh*@sxyHigh) - (@sxHigh*@syHigh))
				/SQRT( ((@countHigh*@sxxHigh)-(@sxHigh*@sxHigh)) * ((@countHigh*@syyHigh)-(@syHigh*@syHigh)))

DECLARE @PredictionHigh DECIMAL(38,5)
		,@PredTimeHigh DATETIME
SELECT @PredTimeHigh = DATEADD(HOUR,1,MAX([Time])),@PredictionHigh = @alphaHigh+(@betaHigh*(max(x)+1))  FROM #PreRegHigh


select @Corelation AS Correclation,(SELECT MIN([Time]) FROM #PIVOT) AS MinTime,(SELECT MAX([Time]) FROM #PIVOT) AS MaxTime
