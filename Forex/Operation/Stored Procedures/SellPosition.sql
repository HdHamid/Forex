
--exec  [Operation].[SellPosition]
CREATE Procedure [Operation].[SellPosition]
  @ActiveAlgorithmPips decimal(38,5) = 0 -- چند پیپ بالا یا پایین پیوت پندینگ اوردر رو فعال کنه؟
 ,@WindowFrom INT = 5
 ,@WindowTo INT = 5
 ,@PipRangeFromPivot decimal(38,5) = 0.05 -- بعد از هر پیوت که شناخته تا چندتا بالاترش رفته؟ به پارامتر کندلهای بعدیش ویندو تو دقت کن که 5 گذاشته باشی خوب 30 پیپ مسخرس بعبارتی خواستم قدرت پیوت رو بسنجم
 ,@StopLosPips decimal(38,5) = -0.0100 -- استاپ لاس چند پیپ بالا یا پایین ماکز یا مین پیوت باشه
 ,@TargetsPips decimal(38,5) = 2
 ,@Candles int = 100000 -- چنتا کندل جلوتر اگز حد سود و ضرر اتفاق نیوفتاد ببنده
 ,@RegWindow int = 5 -- رگرشن
 ,@OppositeSignalPips decimal(38,5) = 0.1 -- 30 pips
 ,@OppositeSignalSlPips decimal(38,5) = 0.1 -- 30 pips nesbat be pending asli na opposite
 ,@OppositeSignalTpPips decimal(38,5) = 0.15 -- 300 pips pips nesbat be pending asli na opposite
 ,@isTest bit = 0
 ,@FreshPivotChecker decimal(38,5) = 0.05 
 ,@ClassName varchar(50) = 'There''s No Class'
AS 
set nocount on


--declare   @ActiveAlgorithmPips decimal(38,5) = 0.01 -- چند پیپ بالا یا پایین پیوت پندینگ اوردر رو فعال کنه؟
-- ,@WindowFrom nvarchar(5) = '5'
-- ,@WindowTo nvarchar(5) = '5'
-- ,@PipRangeFromPivot decimal(38,5) = 0.05 -- بعد از هر پیوت که شناخته تا چندتا بالاترش رفته؟ به پارامتر کندلهای بعدیش ویندو تو دقت کن که 5 گذاشته باشی خوب 30 پیپ مسخرس بعبارتی خواستم قدرت پیوت رو بسنجم
-- ,@StopLosPips decimal(38,5) = -0.2-- استاپ لاس چند پیپ بالا یا پایین ماکز یا مین پیوت باشه
-- ,@TargetsPips decimal(38,5) = 0.4
-- ,@Candles int = 15 -- چنتا کندل جلوتر اگز حد سود و ضرر اتفاق نیوفتاد ببنده
-- ,@RegWindow int = 5 -- رگرشن
-- ,@OppositeSignalPips decimal(38,5) = 0.02 -- 30 pips
-- ,@OppositeSignalSlPips decimal(38,5) = 0.1 -- 30 pips nesbat be pending asli na opposite
-- ,@OppositeSignalTpPips decimal(38,5) = 0.15 -- 300 pips pips nesbat be pending asli na opposite
-- ,@isTest bit = 0
-- ,@FreshPivotChecker decimal(38,5) = 0.05 



DECLARE	@cor DECIMAL(38,5) = -10

DROP TABLE IF EXISTS #PIVOT
CREATE TABLE #PIVOT
(
 xAxis			 INT
,RowNo			 INT
,[Time]			 DATETIME
,[Open]			 DECIMAL(38,5)
,[High]			 DECIMAL(38,5)
,[Low]			 DECIMAL(38,5)
,[Close]		 DECIMAL(38,5)
,CandleCeiling	 DECIMAL(38,5)
,CandleFloor	 DECIMAL(38,5)
,Volume			 BIGINT
,DateID			 INT
,MaxBetween		 DECIMAL(38,5)
,MinBetween		 DECIMAL(38,5)
,MaxFuture		 DECIMAL(38,5)
,MinFuture		 DECIMAL(38,5)
,Endt			 DATE
,MX				 BIT
,[Min]			 BIT
,EnDay			 TINYINT
,EnMonthName	 VARCHAR(50)
,EnYear			 INT
,VolLagPercent	 DECIMAL(38,5)
)				 

DECLARE @loopBreaker TINYINT = 0
--select * from #PIVOT
--order by rowno
WHILE (@cor < 0 AND @loopBreaker <= 3) -- کورلیشن برای پوزیشن فروش باید حتما مثبت باشد تا روی مینیمم ها رگرشن بگیریم و با شکست اون فعال شه تریگر فروش 
				-- گاهی این حالت پیش میاد که در بازه فریم ما مینیمم تاریخ اول از دومی به دلیل یک نویز بزرگتر میشه و این کارو خراب میکنه پس یه ویندو فریم جدید لازم دارم
BEGIN 
	SET @loopBreaker = @loopBreaker+1

	DELETE #PIVOT

	DECLARE @Top INT = 200
	 ,@UniqueTableName nvarchar(50) 

	EXEC Calc.PivotFinder  @Top = @Top,@WindowFrom = @WindowFrom ,@WindowTo = @WindowTo , @UniqueTableName = @UniqueTableName OUT
  

	DECLARE @SQLCC NVARCHAR(MAX) = CONCAT('SELECT * FROM ',@UniqueTableName)
	INSERT INTO #PIVOT
	exec sp_executesql @SQLCC




	DECLARE @Dte DATETIME
	select @Dte = max([Time]) from #PIVOT 

	DECLARE @LowPrc1 DECIMAL(38,5)
	DECLARE @LowPrc2 DECIMAL(38,5)

	DECLARE @MinPrc1 DECIMAL(38,5)
	DECLARE @MinPrc2 DECIMAL(38,5)

	DECLARE @Dte1 DATETIME
	DECLARE @Dte2 DATETIME



	SELECT top 1 @Dte2 = [Time] , @LowPrc2 = [Low],@LowPrc1 = lag([Low]) over(order by [time]),@Dte1 = lag([time]) over(order by [time])   FROM #PIVOT 
		where [Min] = 1 AND DATEDIFF(HOUR,[Time],@Dte) > cast(@WindowTo as int)
	order by [Time] desc 

	
	DECLARE
		@sy DECIMAL(38,5),
		@sx DECIMAL(38,5),
		@sxx DECIMAL(38,5),
		@sxy DECIMAL(38,5),
		@syy DECIMAL(38,5),
		@count DECIMAL(38,5),
		@alpha DECIMAL(38,5),
		@beta DECIMAL(38,5)


	SELECT  -- فاصلخ این دو نقطه را 1 درنظر میگیریم و در ادامه با نسبتی از این یک فاصله محل پیشبینی را محاسبه میکنیم
		@sy = @LowPrc1+@LowPrc2,
		@sx = 3,
		@sxx = (1*1)+(2*2),
		@sxy = @LowPrc1+(2*@LowPrc2),
		@syy = (@LowPrc1*@LowPrc1)+(@LowPrc2*@LowPrc2),
		@count = 2
	
		SELECT @alpha = ((@sy*@sxx) - (@sx*@sxy))
						/( (@count*@sxx) - (@sx*@sx) )
			   ,@beta = ((@count*@sxy) - (@sx*@sy))
						/( (@count*@sxx) - (@sx*@sx))
			   ,@cor = ((@count*@sxy) - (@sx*@sy))
						/NULLIF(SQRT(ABS( ((@count*@sxx)-(@sx*@sx)) * ((@count*@syy)-(@sy*@sy)))),0)

	SET @WindowFrom = @WindowFrom + 5 
	SET @WindowTo = @WindowTo + 5

	DECLARE @DateDiff1 DECIMAL(38,3),
	@DateDiff2 DECIMAL(38,3)
	SELECT @DateDiff1 = count(1) FROM EURUSD_H1 WHERE [Time] BETWEEN @Dte2 and @Dte
	SELECT @DateDiff2 = count(1) FROM EURUSD_H1 WHERE [Time] BETWEEN @Dte1 and @Dte2

	DECLARE @PredictionMin DECIMAL(38,5)
	SELECT @PredictionMin = @alpha+(@beta*(2+(@DateDiff1/@DateDiff2)))  

	DECLARE @corMin DECIMAL(38,5)
	SET @corMin = @cor

	

--SELECT 'MX Short' AS [Type],@Dte1 AS Dte1,@Dte2 AS Dte2,@PredictionMin AS PredictionHigh,@corMin AS cor
END

--==================Volume Percentage
DECLARE @Vol DECIMAL(5,2) = 0.2

DECLARE @LastPrc DECIMAL(38,5)
SELECT TOP 1 @LastPrc = [Close] FROM #PIVOT
ORDER BY [TIME] DESC 

--=================== SEND Signal
declare @prc decimal(38,5)
select @prc = [Close] from #PIVOT 
where RowNo = (select max(RowNo) from #PIVOT )


print '***********************************'

PRINT CONCAT(
'Message From SELL Position: ',char(10),
'Check This Conditions',char(10),
'Two Dates to calculate regression are: ',FORMAT(@Dte1,'yyyy/MM/dd HH'),',',FORMAT(@Dte2,'yyyy/MM/dd HH'),char(10),
'Last Price should be less than SELL MIN two h1 pivot Regression Prediction (@LastPrc > @PredictionMin): ',@LastPrc ,' > ', @PredictionMin,char(10),
'and Correlation of that should be more than ZERO: ',@corMin ,' > ', 0
)


IF(@LastPrc > @PredictionMin AND @corMin > 0)
BEGIN
	select 
	1 as ForwardCandles
	, 
	CONCAT('Sell',',',@PredictionMin-@ActiveAlgorithmPips,',',@PredictionMin-@StopLosPips,',',0,',',@Vol,',','CMNT+',@Candles,'+',REPLACE(@ClassName,'_',''))
	as Signals
	, 1 as GapAllIsValid
END