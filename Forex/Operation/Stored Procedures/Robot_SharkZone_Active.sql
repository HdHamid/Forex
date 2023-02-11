CREATE PROCEDURE [Operation].[Robot_SharkZone_Active] 	
as 
SET NOCOUNT ON

--======================================

exec [Operation].[LiveFillWeekly]

--exec [Operation].[AlgoWeeklyRegression]


DROP TABLE IF EXISTS #RES
;with stp1 as 
(
	SELECT [time],StochasticRSI,StochasticRSIAvg2,IIF(StochasticRSI >= 0.50,'Buy','SELL') AS Signal FROM WeeklyFullFeature
)
, stp2 as 
(
	select *,LAG(Signal) OVER (ORDER BY [Time]) as LagSignal
	from stp1
), STP3 AS 
(
	select *,sum(IIF(LagSignal = Signal,0,1)) OVER(ORDER BY [Time]) AS Grp from stp2 
)
SELECT [Time],StochasticRSI,StochasticRSIAvg2,Signal,ROW_NUMBER() OVER(PARTITION BY Grp ORDER BY [Time]) AS Rn
	INTO #RES
FROM STP3


DECLARE 
	@Signal VARCHAR(50),@Rn TINYINT
	,@Stc DECIMAL(5,2)

SELECT TOP 1 @Signal = Signal,@Rn = Rn ,@Stc =  isnull(StochasticRSI,-1) FROM #RES
ORDER BY [Time] DESC

print 
concat('Signal = ',@Signal
		,' Rn = ',@Rn 
		,' Stoch = ',@Stc )

IF(@Rn > 1 AND @Signal = 'SELL')
	EXEC Operation.SellPosition
		@WindowFrom = 15,@WindowTo = 15

IF(@Rn > 1 AND @Signal = 'BUY')
	EXEC Operation.BuyPosition
		@WindowFrom = 15,@WindowTo = 15
		