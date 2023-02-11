
--exec  [Operation].[BuyPosition]
CREATE Procedure [Operation].[BuyPosition]
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



DECLARE	@cor DECIMAL(38,5) = 10

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

DECLARE @Dte1 DATETIME
DECLARE @Dte2 DATETIME
DECLARE @loopBreaker TINYINT = 0
DECLARE @PredictionHigh DECIMAL(38,5)

--select * from #PIVOT
--order by rowno
WHILE (isnull(@cor,1) > 0 AND @loopBreaker <= 3) -- کورلیشن برای پوزیشن خرید باید حتما منفی باشد تا روی ماکزیمم ها رگرشن بگیریم و با شکست اون فعال شه تریگر خرید 
				-- گاهی این حالت پیش میاد که در بازه فریم ما ماکزیمم تاریخ اول از دومی به دلیل یک نویز کوچیکتر میشه و این کارو خراب میکنه پس یه ویندو فریم جدید لازم دارم
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

	DECLARE @HighPrc1 DECIMAL(38,5)
	DECLARE @HighPrc2 DECIMAL(38,5)

	DECLARE @MinPrc1 DECIMAL(38,5)
	DECLARE @MinPrc2 DECIMAL(38,5)




	SELECT top 1 @Dte2 = [Time] , @HighPrc2 = [High],@HighPrc1 = lag([High]) over(order by [time]),@Dte1 = lag([time]) over(order by [time])   FROM #PIVOT 
		where [MX] = 1 AND DATEDIFF(HOUR,[Time],@Dte) > cast(@WindowTo as int)
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
						/NULLIF(SQRT(ABS( ((@count*@sxx)-(@sx*@sx)) * ((@count*@syy)-(@sy*@sy)))),0)

	DECLARE @RNDte INT = (select rowNo from #PIVOT where [Time] = @Dte)
	DECLARE @RNDte1 INT = (select rowNo from #PIVOT where [Time] = @Dte1)
	DECLARE @RNDte2 INT = (select rowNo from #PIVOT where [Time] = @Dte2)
																	   
	SET @WindowFrom = @WindowFrom + 5 
	SET @WindowTo = @WindowTo + 5

	SELECT @PredictionHigh = @alpha+(@beta*(2+((@RNDte-@RNDte2)*1.00/(@RNDte2-@RNDte1))))  
		
	
	DECLARE @corHigh DECIMAL(38,5)
	SET @corHigh = @cor

--SELECT 'MX Short' AS [Type],@Dte1 AS Dte1,@Dte2 AS Dte2,@PredictionMin AS PredictionHigh,@corHigh AS cor
END

--==================Volume Percentage
DECLARE @Vol DECIMAL(5,2) = 0.1

DECLARE @LastPrc DECIMAL(38,5)
SELECT TOP 1 @LastPrc = [Close] FROM #PIVOT
ORDER BY [TIME] DESC 

--=================== SEND Signal
declare @prc decimal(38,5)
select @prc = [Close] from #PIVOT 
where RowNo = (select max(RowNo) from #PIVOT )

print '***********************************'

PRINT CONCAT(
'Message From Buy Position: ',char(10),
'Check This Conditions',char(10),
'Two Dates to calculate regression are: ',FORMAT(@Dte1,'yyyy/MM/dd HH'),',',FORMAT(@Dte2,'yyyy/MM/dd HH'),char(10),
'Last Price should be less than Buy MAX two h1 pivot Regression Prediction (@LastPrc < @PredictionHigh): ',@LastPrc ,' < ', @PredictionHigh,char(10),
'and Correlation of that should be less than ZERO: ',@corHigh ,' < ', 0
)

IF(@LastPrc < @PredictionHigh AND @corHigh < 0)
BEGIN
	select 
	1 as ForwardCandles
	, 
	CONCAT('Buy',',',@PredictionHigh+@ActiveAlgorithmPips,',',@PredictionHigh+@StopLosPips,',',0,',',@Vol,',','CMNT+',@Candles,'+',REPLACE(@ClassName,'_',''))
	as Signals
	, 1 as GapAllIsValid
END