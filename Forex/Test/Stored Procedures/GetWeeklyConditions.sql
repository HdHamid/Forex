CREATE PROCEDURE Test.GetWeeklyConditions
AS
DROP TABLE IF EXISTS #PIVOT
DROP TABLE IF EXISTS #PreReg
DROP TABLE IF EXISTS #TBCUR


SELECT MAX([Time]) AS LastDateInTbl FROM EURUSD_W


EXEC [Calc].[FILL_WeeklyFullFeature] @WindowFrom = '5',@WindowTo = '5'

DECLARE @Dte DATE
select @Dte = cast(max([Time]) as date) from EURUSD_W 

DECLARE @HighPrc1 DECIMAL(38,5)
DECLARE @HighPrc2 DECIMAL(38,5)

DECLARE @MinPrc1 DECIMAL(38,5)
DECLARE @MinPrc2 DECIMAL(38,5)

DECLARE @Dte1 DATE
DECLARE @Dte2 DATE


-------------- For MX

SELECT top 1 @Dte2 = [Time] , @HighPrc2 = [High],@HighPrc1 = lag([High]) over(order by [time]),@Dte1 = lag([time]) over(order by [time])   FROM WeeklyFullFeature 
	where mx = 1 AND DATEDIFF(WEEK,[Time],@Dte) > 5
order by [DateTime] desc 

DECLARE @Now DATE
SELECT @Now = CAST(MAX([TIME]) AS DATE) FROM EURUSD_W

--select @Now,@Dte1,@Dte2,DATEDIFF(WEEK,@Dte1,@Dte2),DATEDIFF(WEEK,@Dte2,@Now)

DECLARE
	@sy DECIMAL(38,5),
	@sx DECIMAL(38,5),
	@sxx DECIMAL(38,5),
	@sxy DECIMAL(38,5),
	@syy DECIMAL(38,5),
	@count DECIMAL(38,5),
	@alpha DECIMAL(38,5),
	@beta DECIMAL(38,5),
	@cor DECIMAL(38,5)


SELECT 
	@sy = @HighPrc1+@HighPrc2,
	@sx = 3,
	@sxx = (1*1)+(2*2),
	@sxy = @HighPrc1+(2*@HighPrc2),
	@syy = (@HighPrc1*@HighPrc1)+(@HighPrc2*@HighPrc2),
	@count = 2
	
	SELECT @alpha = ((@sy*@sxx) - (@sx*@sxy))
					/( (@count*@sxx) - (@sx*@sx) )
		   ,@beta = ((@count*@sxy) - (@sx*@sy))
					/( (@count*@sxx) - (@sx*@sx))
		   ,@cor = ((@count*@sxy) - (@sx*@sy))
					/SQRT(ABS(((@count*@sxx)-(@sx*@sx)) * ((@count*@syy)-(@sy*@sy))))


DECLARE @PredictionHigh DECIMAL(38,5)
SELECT @PredictionHigh = @alpha+(@beta*(2+(DATEDIFF(WEEK,@Dte2,@Now)*1.00/DATEDIFF(WEEK,@Dte1,@Dte2))))  

DECLARE @corHigh DECIMAL(38,5)
SET @corHigh = @cor

SELECT 'MX Short' AS [Type],@Dte1 AS Dte1,@Dte2 AS Dte2,@PredictionHigh AS PredictionHigh,@corHigh AS cor

-------------- For MIN

SELECT top 1 @Dte2 = [Time] , @MinPrc2 = [Low],@MinPrc1 = lag([Low]) over(order by [time]),@Dte1 = lag([time]) over(order by [time])  FROM WeeklyFullFeature 
	where [min] = 1 AND DATEDIFF(WEEK,[Time],@Dte) > 5
order by [DateTime] desc 


SELECT 
	@sy = @MinPrc2+@MinPrc1,
	@sx = 3,
	@sxx = (1*1)+(2*2),
	@sxy = @MinPrc1+(2*@MinPrc2),
	@syy = (@MinPrc1*@MinPrc1)+(@MinPrc2*@MinPrc2),
	@count = 2
	
	SELECT @alpha = ((@sy*@sxx) - (@sx*@sxy))
					/( (@count*@sxx) - (@sx*@sx) )
		   ,@beta = ((@count*@sxy) - (@sx*@sy))
					/( (@count*@sxx) - (@sx*@sx))
		   ,@cor = ((@count*@sxy) - (@sx*@sy))
					/SQRT( ABS(((@count*@sxx)-(@sx*@sx)) * ((@count*@syy)-(@sy*@sy))))

DECLARE @PredictionLow DECIMAL(38,5)
SELECT @PredictionLow = @alpha+(@beta*(2+(DATEDIFF(WEEK,@Dte2,@Now)*1.00/DATEDIFF(WEEK,@Dte1,@Dte2))))

DECLARE @corLow DECIMAL(38,5)
SET @corLow = @cor

SELECT 'MIN Short' AS [Type],@Dte1 AS Dte1,@Dte2 AS Dte2,@PredictionLow AS PredictionLow,@corLow AS cor











--============= LongTermReggression 
EXEC [Calc].[FILL_WeeklyFullFeature] @WindowFrom = '100',@WindowTo = '7'


--DECLARE @Dte DATE
--select @Dte = cast(max([Time]) as date) from EURUSD_W 



-------------- For MX

SELECT top 1 @Dte2 = [Time] , @HighPrc2 = [High],@HighPrc1 = lag([High]) over(order by [time]),@Dte1 = lag([time]) over(order by [time])   FROM WeeklyFullFeature 
	where mx = 1 AND DATEDIFF(WEEK,[Time],@Dte) > 7
order by [DateTime] desc 

--select @Now,@Dte1,@Dte2,DATEDIFF(WEEK,@Dte1,@Dte2),DATEDIFF(WEEK,@Dte2,@Now)

SELECT 
	@sy = @HighPrc1+@HighPrc2,
	@sx = 3,
	@sxx = (1*1)+(2*2),
	@sxy = @HighPrc1+(2*@HighPrc2),
	@syy = (@HighPrc1*@HighPrc1)+(@HighPrc2*@HighPrc2),
	@count = 2
	
	SELECT @alpha = ((@sy*@sxx) - (@sx*@sxy))
					/( (@count*@sxx) - (@sx*@sx) )
		   ,@beta = ((@count*@sxy) - (@sx*@sy))
					/( (@count*@sxx) - (@sx*@sx))
		   ,@cor = ((@count*@sxy) - (@sx*@sy))
					/SQRT( ((@count*@sxx)-(@sx*@sx)) * ((@count*@syy)-(@sy*@sy)))



SELECT @PredictionHigh = @alpha+(@beta*(2+(DATEDIFF(WEEK,@Dte2,@Now)*1.00/DATEDIFF(WEEK,@Dte1,@Dte2))))  


SET @corHigh = @cor

SELECT 'MX Long' AS [Type],@Dte1 AS Dte1,@Dte2 AS Dte2,@PredictionHigh AS PredictionHigh,@corHigh AS cor


-------------- For MIN

SELECT top 1 @Dte2 = [Time] , @MinPrc2 = [Low],@MinPrc1 = lag([Low]) over(order by [time]),@Dte1 = lag([time]) over(order by [time])  FROM WeeklyFullFeature 
	where [min] = 1 AND DATEDIFF(WEEK,[Time],@Dte) > 7
order by [DateTime] desc 


SELECT 
	@sy = @MinPrc2+@MinPrc1,
	@sx = 3,
	@sxx = (1*1)+(2*2),
	@sxy = @MinPrc1+(2*@MinPrc2),
	@syy = (@MinPrc1*@MinPrc1)+(@MinPrc2*@MinPrc2),
	@count = 2
	
	SELECT @alpha = ((@sy*@sxx) - (@sx*@sxy))
					/( (@count*@sxx) - (@sx*@sx) )
		   ,@beta = ((@count*@sxy) - (@sx*@sy))
					/( (@count*@sxx) - (@sx*@sx))
		   ,@cor = ((@count*@sxy) - (@sx*@sy))
					/SQRT( ((@count*@sxx)-(@sx*@sx)) * ((@count*@syy)-(@sy*@sy)))


SELECT @PredictionLow = @alpha+(@beta*(2+(DATEDIFF(WEEK,@Dte2,@Now)*1.00/DATEDIFF(WEEK,@Dte1,@Dte2))))

SET @corLow = @cor

SELECT 'MIN Long' AS [Type],@Dte1 AS Dte1,@Dte2 AS Dte2,@PredictionLow AS PredictionLow,@corLow AS cor




--============= Full Regression

--DECLARE @Dte DATE
--select @Dte = cast(max([Time]) as date) from EURUSD_W 

DECLARE @LongRegDte DATE
SELECT top 1 @LongRegDte = [Time] FROM WeeklyFullFeature 
	where (mx = 1 or [min] = 1) AND DATEDIFF(WEEK,[Time],@Dte) > 7
order by [DateTime] desc 



DROP TABLE IF EXISTS #PIVOT

DROP TABLE IF EXISTS #TBCUR
SELECT 
	 IIF([Open] > [Close] , [Open] , [Close] ) as CandleCeiling
	,IIF([Open] > [Close] , [Close] , [Open] ) as CandleFloor
	,[Time] ,[Open] ,[High] ,[Low]  ,[Close],Volume ,DateId 	
INTO #TBCUR FROM  Dbo.EURUSD_W
WHERE [Time] BETWEEN @LongRegDte AND @Now

DROP TABLE IF EXISTS #PIVOT
SELECT *,ROW_NUMBER()OVER(ORDER BY [Time]) AS xAxis
	INTO #PIVOT
FROM #TBCUR


DROP TABLE IF EXISTS #PreReg
;WITH stp1 AS 
	(
		SELECT [time], xAxis AS x ,(f.CandleCeiling+f.CandleFloor)/2 AS y 
		FROM #PIVOT f
	)
SELECT * INTO #PreReg FROM stp1


SELECT 
	@sy = sum(y),
	@sx = sum(x),
	@sxx = sum(x*x),
	@sxy = sum(x*y),
	@syy = sum(y*y),
	@count = Count(1)
FROM #PreReg

select @alpha = ((@sy*@sxx) - (@sx*@sxy))
				/( (@count*@sxx) - (@sx*@sx) )
	   ,@beta = ((@count*@sxy) - (@sx*@sy))
				/( (@count*@sxx) - (@sx*@sx))
	   ,@cor = ((@count*@sxy) - (@sx*@sy))
				/SQRT( ((@count*@sxx)-(@sx*@sx)) * ((@count*@syy)-(@sy*@sy)))

DECLARE @PredictionFullReg DECIMAL(38,5)
				,@PredTime DATETIME
		SELECT @PredTime = DATEADD(HOUR,1,MAX([Time])),@PredictionFullReg = @alpha+(@beta*(max(x)+1))  FROM #PreReg

SELECT 'LongFullReg' AS [Type],@LongRegDte AS Dte1,@Now AS Dte2,@PredictionFullReg AS PredictionFullReg,@cor AS FullRegCor 
--========================= SharkZone
--DECLARE @Dte DATE
--select @Dte = cast(max([Time]) as date) from EURUSD_W 
DECLARE @MaxSharkZone DECIMAL(38,5)
DECLARE @MinSharkZone DECIMAL(38,5)

SELECT top 1 @MaxSharkZone = [High] FROM WeeklyFullFeature where mx = 1 
AND DATEDIFF(WEEK,[Time],@Dte) > 7
order by [time] desc

SELECT top 1 @MinSharkZone = [Low] FROM WeeklyFullFeature where [min] = 1 
AND DATEDIFF(WEEK,[Time],@Dte) > 7
order by [time] desc


select @MaxSharkZone AS MaxSharkZone,@MinSharkZone AS MinSharkZone




