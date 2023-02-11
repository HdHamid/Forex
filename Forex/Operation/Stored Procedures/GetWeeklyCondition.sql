CREATE PROCEDURE [Operation].[GetWeeklyCondition]
@MxShortPrediction_		DECIMAL(38,5) OUT,
@MxShortCor_			DECIMAL(38,5) OUT,
@MinPrediction_			DECIMAL(38,5) OUT,
@MinCor_				DECIMAL(38,5) OUT,
@MxLongPrediction_		DECIMAL(38,5) OUT, 
@MxLongcor_				DECIMAL(38,5) OUT,
@MinLongPrediction_		DECIMAL(38,5) OUT, 
@MinLongCor_			DECIMAL(38,5) OUT,
@PredictionFullReg_		DECIMAL(38,5) OUT, 
@FullRegCor_			DECIMAL(38,5) OUT,
@MaxSharkZone_			DECIMAL(38,5) OUT, 
@MinSharkZone_			DECIMAL(38,5) OUT,
@MxDte1Short_			DATE OUT,
@MxDte2Short_			DATE OUT,
@MinDte1Short_			DATE OUT,
@MinDte2Short_			DATE OUT, 
@LongReggressionDate_	DATE OUT,
@LongReggressionType_	VARCHAR(3) OUT
AS

--============= Regression 

DECLARE @WindowToShort int
DECLARE @WindowToLong int = 10


DECLARE @Dte DATE
select @Dte = cast(max([Time]) as date) from EURUSD_W 

DECLARE @HighPrc1 DECIMAL(38,5)
DECLARE @HighPrc2 DECIMAL(38,5)

DECLARE @MinPrc1 DECIMAL(38,5)
DECLARE @MinPrc2 DECIMAL(38,5)

DECLARE @Dte1 DATE
DECLARE @Dte2 DATE

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

DECLARE @PredictionHigh DECIMAL(38,5)

DECLARE @corHigh DECIMAL(38,5)

DECLARE @Now DATE
SELECT @Now = CAST(MAX([TIME]) AS DATE) FROM EURUSD_W

DECLARE @PredictionLow DECIMAL(38,5)

DECLARE @corLow DECIMAL(38,5)





--============= LongTermReggression 
EXEC [Calc].[FILL_WeeklyFullFeature] @WindowFrom = '50',@WindowTo = @WindowToLong


--DECLARE @Dte DATE
--select @Dte = cast(max([Time]) as date) from EURUSD_W 
-------------- For MX

SELECT top 1 @Dte2 = [Time] , @HighPrc2 = [High],@HighPrc1 = lag([High]) over(order by [time]),@Dte1 = lag([time]) over(order by [time])   FROM WeeklyFullFeature 
	where mx = 1 AND DATEDIFF(WEEK,[Time],@Dte) > @WindowToLong
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


DECLARE @DateDiff1 DECIMAL(38,3),
@DateDiff2 DECIMAL(38,3)
SELECT @DateDiff1 = count(1) FROM EURUSD_H1 WHERE [Time] BETWEEN @Dte2 and @Now
SELECT @DateDiff2 = count(1) FROM EURUSD_H1 WHERE [Time] BETWEEN @Dte1 and @Dte2


SELECT @PredictionHigh = @alpha+(@beta*(2+(@DateDiff1/@DateDiff2)))  


SET @corHigh = @cor

--SELECT 'MX Long' AS [Type],@Dte1 AS Dte1,@Dte2 AS Dte2,@PredictionHigh AS PredictionHigh,@corHigh AS cor

SET @MxLongPrediction_ = @PredictionHigh
SET @MxLongcor_ = @corHigh

-------------- For MIN

SELECT top 1 @Dte2 = [Time] , @MinPrc2 = [Low],@MinPrc1 = lag([Low]) over(order by [time]),@Dte1 = lag([time]) over(order by [time])  FROM WeeklyFullFeature 
	where [min] = 1 AND DATEDIFF(WEEK,[Time],@Dte) > @WindowToLong
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


SELECT @DateDiff1 = count(1) FROM EURUSD_H1 WHERE [Time] BETWEEN @Dte2 and @Now
SELECT @DateDiff2 = count(1) FROM EURUSD_H1 WHERE [Time] BETWEEN @Dte1 and @Dte2

SELECT @PredictionLow = @alpha+(@beta*(2+(@DateDiff1/@DateDiff2)))

SET @corLow = @cor

--SELECT 'MIN Long' AS [Type],@Dte1 AS Dte1,@Dte2 AS Dte2,@PredictionLow AS PredictionLow,@corLow AS cor

SET @MinLongPrediction_ = @PredictionLow
SET @MinLongCor_ = @corLow



--============= Full Regression

--DECLARE @Dte DATE
--select @Dte = cast(max([Time]) as date) from EURUSD_W 


DECLARE @LongRegDte DATE,@LongReggressionType VARCHAR(3)
SELECT top 1 @LongRegDte = [Time],@LongReggressionType = IIF(mx = 1, 'MAX','MIN') FROM WeeklyFullFeature 
	where (mx = 1 or [min] = 1) AND DATEDIFF(WEEK,[Time],@Dte) > 7 -- @WindowToLong
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

--SELECT 'LongFullReg' AS [Type],@LongRegDte AS Dte1,@Now AS Dte2,@PredictionFullReg AS PredictionFullReg,@cor AS FullRegCor 

SET @PredictionFullReg_	= @PredictionFullReg
SET @FullRegCor_		= @cor
SET @LongReggressionDate_ = @LongRegDte
SET @LongReggressionType_ = @LongReggressionType
--========================= SharkZone
--DECLARE @Dte DATE
--select @Dte = cast(max([Time]) as date) from EURUSD_W 
DECLARE @MaxSharkZone DECIMAL(38,5)
DECLARE @MinSharkZone DECIMAL(38,5)

SELECT top 1 @MaxSharkZone = [High] FROM WeeklyFullFeature where mx = 1 
AND DATEDIFF(WEEK,[Time],@Dte) > @WindowToLong
order by [time] desc

SELECT top 1 @MinSharkZone = [Low] FROM WeeklyFullFeature where [min] = 1 
AND DATEDIFF(WEEK,[Time],@Dte) > @WindowToLong
order by [time] desc


--select @MaxSharkZone AS MaxSharkZone,@MinSharkZone AS MinSharkZone

SET @MaxSharkZone_	= @MaxSharkZone	
SET @MinSharkZone_	= @MinSharkZone






--============= ShortTermReggression 

IF(@FullRegCor_ < -0.93)
	SET @WindowToShort = 2
ELSE 
	SET @WindowToShort = 4

EXEC [Calc].[FILL_WeeklyFullFeature] @WindowFrom = @WindowToShort,@WindowTo = @WindowToShort


-------------- For MX
SELECT top 1 @Dte2 = [Time] , @HighPrc2 = [High],@HighPrc1 = lag([High]) over(order by [time]),@Dte1 = lag([time]) over(order by [time])   FROM WeeklyFullFeature 
	where mx = 1 AND DATEDIFF(WEEK,[Time],@Dte) > @WindowToShort -- از 5 هفته بیشتر گذشته باشه
order by [DateTime] desc 



--select @Now,@Dte1,@Dte2,DATEDIFF(WEEK,@Dte1,@Dte2),DATEDIFF(WEEK,@Dte2,@Now)

PRINT CONCAT('@Dte1,@Dte2 ',@Dte1,' to ',@Dte2)




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




SELECT @DateDiff1 = count(1) FROM EURUSD_H1 WHERE [Time] BETWEEN @Dte2 and @Now
SELECT @DateDiff2 = count(1) FROM EURUSD_H1 WHERE [Time] BETWEEN @Dte1 and @Dte2

SELECT @PredictionHigh = @alpha+(@beta*(2+(@DateDiff1/@DateDiff2)))  


SET @corHigh = @cor

--SELECT 'MX Short' AS [Type],@Dte1 AS Dte1,@Dte2 AS Dte2,@PredictionHigh AS PredictionHigh,@corHigh AS cor

SET @MxShortPrediction_	= @PredictionHigh 
SET @MxShortCor_ = @corHigh
SET @MxDte1Short_ = @Dte1
SET @MxDte2Short_ = @Dte2

-------------- For MIN

SELECT top 1 @Dte2 = [Time] , @MinPrc2 = [Low],@MinPrc1 = lag([Low]) over(order by [time]),@Dte1 = lag([time]) over(order by [time])  FROM WeeklyFullFeature 
	where [min] = 1 AND DATEDIFF(WEEK,[Time],@Dte) > @WindowToShort
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



SELECT @DateDiff1 = count(1) FROM EURUSD_H1 WHERE [Time] BETWEEN @Dte2 and @Now
SELECT @DateDiff2 = count(1) FROM EURUSD_H1 WHERE [Time] BETWEEN @Dte1 and @Dte2

SELECT @PredictionLow = @alpha+(@beta*(2+(@DateDiff1/@DateDiff2)))


SET @corLow = @cor

--SELECT 'MIN Short' AS [Type],@Dte1 AS Dte1,@Dte2 AS Dte2,@PredictionLow AS PredictionLow,@corLow AS cor

SET @MinPrediction_	 = @PredictionLow
SET @MinCor_ = @corLow
SET @MinDte1Short_ = @Dte1
SET @MinDte2Short_ = @Dte2














