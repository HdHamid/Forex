CREATE PROCEDURE Operation.Scalp 
AS 
DROP TABLE IF EXISTS #Temp
SELECT TOP 20 [Time],[Close],[High],[Low],[Open]
	INTO #Temp
FROM EURUSD_H1 
ORDER BY [Time] DESC 

DROP TABLE IF EXISTS #PIVOT
SELECT *,IIF([Close]>=[Open],'Green','Red') AS CandleType,ROW_NUMBER() OVER(ORDER BY [Time]) AS X INTO #PIVOT
FROM #Temp

DECLARE
	@sy DECIMAL(38,5),
	@sx DECIMAL(38,5),
	@sxx DECIMAL(38,5),
	@sxy DECIMAL(38,5),
	@syy DECIMAL(38,5),
	@count DECIMAL(38,5),
	@alpha DECIMAL(38,5),
	@beta DECIMAL(38,5)


DECLARE	@cor DECIMAL(38,5) 
	

SELECT  -- فاصلخ این دو نقطه را 1 درنظر میگیریم و در ادامه با نسبتی از این یک فاصله محل پیشبینی را محاسبه میکنیم
	@sy = SUM([Close]) ,
	@sx = SUM(X),
	@sxx = SUM(SQUARE(X)),
	@sxy = SUM(X*[CLOSE]),
	@syy = SUM(SQUARE([CLOSE])),
	@count = COUNT(1)
FROM #PIVOT

	SELECT @alpha = ((@sy*@sxx) - (@sx*@sxy))
					/( (@count*@sxx) - (@sx*@sx) )
		   ,@beta = ((@count*@sxy) - (@sx*@sy))
					/( (@count*@sxx) - (@sx*@sx))
		   ,@cor = ((@count*@sxy) - (@sx*@sy))
					/NULLIF(SQRT(ABS( ((@count*@sxx)-(@sx*@sx)) * ((@count*@syy)-(@sy*@sy)))),0)


DECLARE @Prediction DECIMAL(38,5)
SELECT @Prediction = @alpha+(@beta*(@count+1))  


DECLARE @Type VarChar(50) 
,@Vol decimal(38,2) = 0.1
,@RedCount INT
,@GreenCount INT


select Top 9 * 
	into #Cnt
from #PIVOT
ORDER BY [TIME] DESC

SELECT @RedCount = COUNT(1) FROM #Cnt WHERE CandleType = 'Red'
SELECT @GreenCount = COUNT(1) FROM #Cnt WHERE CandleType = 'Green'

SELECT 
	@Type =	
		CASE
			WHEN @cor > 0.8 AND @GreenCount > @RedCount THEN 'Sell'
			WHEN @cor < -0.8 AND @GreenCount < @RedCount THEN 'Buy'
		END 
	

IF(@Type IS NOT NULL)
select 
	1 as ForwardCandles
	, 
	CONCAT(@Type,','
	,0 -- Price
	,',' 
	,0 -- SL
	,','
	,0 --  TP		
	,','
	,@Vol
	,','
	,'CMNT+',5,'+','ChandelierExit' -- Comment
	)
	as Signals
	, 1 as GapAllIsValid

--ForwardCandles	Signals	GapAllIsValid
--1	,1.02580,1.00964,1.05812,0.10000,CMNT+50000+ChandelierExit	1


