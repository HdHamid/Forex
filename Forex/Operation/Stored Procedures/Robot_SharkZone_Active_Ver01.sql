CREATE PROCEDURE [Operation].[Robot_SharkZone_Active_Ver01] 
	@jumper decimal(38,5) = -0.5
as 
SET NOCOUNT ON

--====================================== Get weekly info

DECLARE
	@MxShortPrediction_		DECIMAL(38,5),
	@MxShortCor_			DECIMAL(38,5),
	@MinPrediction_			DECIMAL(38,5),
	@MinCor_				DECIMAL(38,5),
	@MxLongPrediction_		DECIMAL(38,5),
	@MxLongcor_				DECIMAL(38,5),
	@MinLongPrediction_		DECIMAL(38,5),
	@MinLongCor_			DECIMAL(38,5),
	@PredictionFullReg_		DECIMAL(38,5),
	@FullRegCor_			DECIMAL(38,5),
	@MaxSharkZone_			DECIMAL(38,5),
	@MinSharkZone_			DECIMAL(38,5),
	@MxDte1Short_			DATE ,
	@MxDte2Short_			DATE ,
	@MinDte1Short_			DATE ,
	@MinDte2Short_			DATE ,
	@LongReggressionDate_	DATE

--======================================= 
--declare @tt table 
--(
--	TrendID INT, 
--	ClassName VARCHAR(50),
--	TrendCandles INT	 ,
--	TrendDayCount INT	 ,
--	ClassAvgDayCount INT ,
--	DateFrom DATETIME	 ,
--	DateTo DATETIME
--)
--insert into @tt
--exec [dbo].[GetCurrentClass]

--DECLARE @ClassName varchar(50) = (select ClassName from @tt)

--if (Not exists (select 1 from @tt))
--begin
--	print 'There''s No Class'
--	return
--end 

-- last day of week dont release the signal 
declare @DayOfWeek tinyint =
	(select EnNoDayOfWeek from DimDate where endt = (select cast(max([Time]) as date) from EURUSD_H1))


--=============== بروزرسانی هفتگی
if (@DayOfWeek in(1,5) AND (SELECT DATEPART(HOUR,MAX([Time])) from EURUSD_H1) = 23)
--if ((SELECT DATEPART(HOUR,MAX([Time])) from EURUSD_H1) = 23)
begin
	exec calc.FillWeekly	
		
	EXEC [Operation].[GetWeeklyCondition]
	@MxShortPrediction_		= @MxShortPrediction_	OUT,
	@MxShortCor_			= @MxShortCor_			OUT,
	@MinPrediction_			= @MinPrediction_		OUT,
	@MinCor_				= @MinCor_				OUT,
	@MxLongPrediction_		= @MxLongPrediction_	OUT,
	@MxLongcor_				= @MxLongcor_			OUT,
	@MinLongPrediction_		= @MinLongPrediction_	OUT,
	@MinLongCor_			= @MinLongCor_			OUT,
	@PredictionFullReg_		= @PredictionFullReg_	OUT,
	@FullRegCor_			= @FullRegCor_			OUT,
	@MaxSharkZone_			= @MaxSharkZone_		OUT,
	@MinSharkZone_			= @MinSharkZone_		OUT,
	@MxDte1Short_			= @MxDte1Short_			OUT,
	@MxDte2Short_			= @MxDte2Short_			OUT,
	@MinDte1Short_			= @MinDte1Short_		OUT,
	@MinDte2Short_			= @MinDte2Short_		OUT,
	@LongReggressionDate_	= @LongReggressionDate_ OUT

	DROP TABLE IF EXISTS Operation.WeeklyInfo
	SELECT 
	@MxShortPrediction_	AS 	MxShortPrediction	,
	@MxShortCor_		AS 	MxShortCor			,
	@MinPrediction_		AS 	MinPrediction		,
	@MinCor_			AS 	MinCor				,
	@MxLongPrediction_	AS 	MxLongPrediction	,
	@MxLongcor_			AS 	MxLongcor			,
	@MinLongPrediction_	AS 	MinLongPrediction	,
	@MinLongCor_		AS 	MinLongCor			,
	@PredictionFullReg_	AS 	PredictionFullReg	,
	@FullRegCor_		AS 	FullRegCor			,
	@MaxSharkZone_		AS 	MaxSharkZone		,
	@MinSharkZone_		AS 	MinSharkZone		,
	@MxDte1Short_		AS 	MxDte1Short		,
	@MxDte2Short_		AS 	MxDte2Short		,
	@MinDte1Short_		AS	MinDte1Short	,
	@MinDte2Short_		AS	MinDte2Short	,
	@LongReggressionDate_ AS LongReggressionDate
	INTO Operation.WeeklyInfo
	--print CONCAT('@DayOfWeek in(2,6) ',': ',@DayOfWeek)
	--return
	
	EXEC [Calc].[FILL_WeeklyFullFeature] @WindowFrom = '10',@WindowTo = '10'
end




--====================== دریافت اطلاعات روند هفتگی
SELECT 
	@MxShortPrediction_		= MxShortPrediction	, -- پیشبینی ماکزیمم قیمت بر اساس رگرشن پیوت ماکزیمم کوتاه مدت هفتگی
	@MxShortCor_			= MxShortCor		, -- کورلیشن بر اساس رگرشن پیوت ماکزیمم کوتاه مدت هفتگی
	@MinPrediction_			= MinPrediction		, -- پیشبینی مینیمم قیمت بر اساس رگرشن پیوت مینیمم کوتاه مدت هفتگی 
	@MinCor_				= MinCor			, -- کورلیشن بر اساس رگرشن پیوت مینیمم کوتاه مدت هفتگی	
	@MxLongPrediction_		= MxLongPrediction	, -- پیشبینی ماکزیمم قیمت بر اساس رگرشن پیوت ماکزیمم بلند مدت هفتگی
	@MxLongcor_				= MxLongcor			, -- کورلیشن بر اساس رگرشن پیوت ماکزیمم بلند مدت هفتگی
	@MinLongPrediction_		= MinLongPrediction	, -- پیشبینی مینیمم قیمت بر اساس رگرشن پیوت مینیمم بلند مدت هفتگی 
	@MinLongCor_			= MinLongCor		, -- کورلیشن بر اساس رگرشن پیوت مینیمم بلند مدت هفتگی	
	@PredictionFullReg_		= PredictionFullReg	, -- پیش بینی یک قیمت بر اساس تمام قیمتهای رگرشن بلند مدت
	@FullRegCor_			= FullRegCor		, -- کورلیشن بر اساس تمام قیمتهای رگرشن بلند مدت
	@MaxSharkZone_			= MaxSharkZone		, -- بیشینه ی شارک زون بلند مدت 
	@MinSharkZone_			= MinSharkZone		,  -- کمینه ی شارک زون بلند مدت 
	@MxDte1Short_			= MxDte1Short		, 
	@MxDte2Short_			= MxDte2Short		,
	@MinDte1Short_			= MinDte1Short		,
	@MinDte2Short_			= MinDte2Short		,
	@LongReggressionDate_	= LongReggressionDate
FROM
 Operation.WeeklyInfo


--=================== شناسایی رگرشن 50 ساعت اخیر
DROP TABLE IF EXISTS #PIVOT

DROP TABLE IF EXISTS #TBCUR
SELECT TOP 30 ROW_NUMBER()OVER(ORDER BY [Time]) As RowNo,
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

DECLARE @LastPrice DECIMAL(38,5)

--SELECT top 1 @LastPrice = [Close] FROM #TBCUR 
--ORDER BY [Time] DESC


SELECT @LastPrice = [Close] FROM #TBCUR 
ORDER BY [Time] DESC
	OFFSET 1 ROWS
FETCH NEXT 1 ROW ONLY

DECLARE @LastDate datetime

SELECT @LastDate = max([Time]) FROM #TBCUR 


---- ckeck for jumping price
--declare @lastChange decimal(38,5)
--;with s as 
--(
--	select [time]
--		,abs(CandleCeiling - LAG(CandleCeiling)OVER(ORDER BY [TIME])) AS  LastHigh
--		,abs(CandleCeiling - LAG(CandleFloor)OVER(ORDER BY [TIME])) AS  LastMin
--	from #TBCUR
--)
--select @lastChange = IIF(LastHigh>LastMin,LastHigh,LastMin) from s 
--where [time] = (select max([time]) from #TBCUR)
--if( abs(@lastChange) > abs(@jumper))
--begin
--	print CONCAT('abs(@lastChange) > abs(@StopLosPips) ',': ',abs(@lastChange),'>',abs(@jumper))
--	select abs(@lastChange) as lastChange,abs(@jumper) as StopLosPips
--	return
--end



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
				/SQRT(abs( ((@countHigh*@sxxHigh)-(@sxHigh*@sxHigh)) * ((@countHigh*@syyHigh)-(@syHigh*@syHigh))))

DECLARE @PredictionHigh DECIMAL(38,5)
		,@PredTimeHigh DATETIME
SELECT @PredTimeHigh = DATEADD(HOUR,1,MAX([Time])),@PredictionHigh = @alphaHigh+(@betaHigh*(max(x)+1))  FROM #PreRegHigh


--select @Corelation AS Correclation,(SELECT MIN([Time]) FROM #PIVOT) AS MinTime,(SELECT MAX([Time]) FROM #PIVOT) AS MaxTime


--print concat('@Corelation = ' ,@Corelation )
--print concat('@ClassName = ' ,@ClassName )


----if (@ClassName in ('1_Class','15_Class') and @Corelation < -0.6)
--if (@Corelation < -0.6)
--	exec [dbo].[Class1] @ClassName = @ClassName


----if (@ClassName in('3_Class','8_Class') and @Corelation > 0.6)
--if (@Corelation > 0.6)
--	exec [dbo].[Class2] @ClassName = @ClassName


--DECLARE @trend INT 
--EXEC [Calc].[WeeklyChandelier_Exit] @trend =@trend OUT

--IF @trend  = -1 
--	exec [Operation].[SellPosition] @ClassName = 'SellPosition'
	
--IF @trend  = 1 
--	exec [Operation].[BuyPosition] @ClassName = 'BuyPosition'

--================================ 
	
DECLARE @WhichBlockUsed tinyint = 0

IF(
	--@Corelation > 0
	--AND 	
	@FullRegCor_ < -0.40		
	AND 
	--@MxShortPrediction_ - @LastPrice between -1*(@MaxSharkZone_ - @MinSharkZone_) * 0.02 and (@MaxSharkZone_ - @MinSharkZone_) * 0.02 -- میخوایم نزدیک به مقاومت هفتگی باشد
	@MxShortPrediction_ - @LastPrice between -1*(@MxShortPrediction_ - @MinPrediction_) * 0.1 and (@MxShortPrediction_ - @MinPrediction_) * 0.1 -- میخوایم نزدیک به مقاومت هفتگی باشد
	)
BEGIN
	set @WhichBlockUsed = 1
	exec [Operation].[SellPosition] @ClassName = 'SellPosition'
	
END




IF(
	--@Corelation > 0
	--AND 	
	@FullRegCor_ > 0.40		
	AND 
	@LastPrice - @MinPrediction_  between -1*(@MaxSharkZone_ - @MinSharkZone_) * 0.02 and (@MaxSharkZone_ - @MinSharkZone_) * 0.02 -- میخوایم نزدیک به مقاومت هفتگی باشد
	)
BEGIN
	set @WhichBlockUsed = 2	
	exec [Operation].[BuyPosition] @ClassName = 'BuyPosition'
	
END


--IF(@WhichBlockUsed IN (1,2))
BEGIN 
	PRINT CONCAT(
	'Message from @WhichBlockUsed IN (1,2) ** A weekly support or resistance based on reggression touched **',char(10),char(10),

	'Last Price in the H1 Table in ', FORMAT(@LastDate,'yyyy-MM-dd HH') ,' is: ',@LastPrice,char(10),char(10),

	'FULL Regresseion since pivot(MIN or MAX) on : ',@LongReggressionDate_,' is: ',@FullRegCor_,char(10),char(10),

	'** SELL POS Dates For Max Short Time Pivots: ',@MxDte1Short_,', ', @MxDte2Short_,char(10),
	'** SELL POS And The Max Short Time Pivots Prediction: ',@MxShortPrediction_,char(10),char(10), 

	'&& BUY POS Dates For Min Short Time Pivots: ',@MinDte1Short_,', ', @MinDte2Short_,char(10),
	'&& BUY POS And The Min Short Time Pivots Prediction: ',@MinPrediction_,char(10),char(10),

	--'The formula to recognize SHARKZONE in weekly (@MaxSharkZone_ - @MinSharkZone_) * 0.02: ' ,(@MaxSharkZone_ - @MinSharkZone_) * 0.02,char(10),char(10),

	'-1*(@MxShortPrediction_ - @MinPrediction_) * 0.1: ' , -1*(@MxShortPrediction_ - @MinPrediction_) * 0.1,char(10),char(10),
	'(@MxShortPrediction_ - @MinPrediction_) * 0.1: ' , (@MxShortPrediction_ - @MinPrediction_) * 0.1,char(10),char(10),

	'** SELL And For Max Prediction the distance is(@MxShortPrediction_ - @LastPrice ): ',@MxShortPrediction_ - @LastPrice ,char(10),
	'&& BUY And For Min Prediction the distance is(@LastPrice - @MinPrediction_ ): ',@LastPrice - @MinPrediction_  ,char(10)
	)
	
	RETURN
END



--============== اگر در ناحیه مقاومت یا حمایت با توجه به رگرشن کوتاه مدت هفتگی نبود با این احتمال که در ترید قبلی موفق بوده در جهت پوزیشنی که داره 
--============== شروع میکنه به ترید کردن مجدد به شرط اینکه رگرشن بلند مدت هم خفن ناک در جهتی باشه که قصد ترید داریم

DECLARE @GetProfit DECIMAL(38,5)
,@HisTyp VARCHAR(50)
SELECT top 1 @GetProfit = [Position PnL],@HisTyp = [Type] FROM [dbo].[HistoryFromMTDetail]
ORDER BY OpenDateTime desc 


IF(	
	@FullRegCor_ < -0.90
	AND 
	@HisTyp = 'Sell' AND @GetProfit > 500
	)
BEGIN	
	set @WhichBlockUsed = 3
	exec [Operation].[SellPosition] @ClassName = 'SellPosition'
END


IF(	
	@FullRegCor_ > 0.90
		AND 
	@HisTyp = 'Buy' AND @GetProfit > 500 
	)
BEGIN
	set @WhichBlockUsed = 4
	exec [Operation].[BuyPosition] @ClassName = 'BuyPosition'
END

IF(@WhichBlockUsed IN (3,4))
BEGIN 
	PRINT CONCAT(
	'Message from @WhichBlockUsed IN (3,4) ** After successful trade you gain another **',char(10),char(10),

	'History succeed type was: ',@HisTyp,' with profit = ',@GetProfit ,char(10),char(10),

	'Last Price in the H1 Table in ', FORMAT(@LastDate,'yyyy-MM-dd HH') ,' is: ',@LastPrice,char(10),char(10),

	'FULL Regresseion since pivot(MIN or MAX) on : ',@LongReggressionDate_,' is: ',@FullRegCor_,char(10),char(10)
	)
	
	RETURN
END


--================ اگر هیچکدوم بالاییا نشد میتونیم در حالت بازار رنج به شارک زون فکر کنیم



DECLARE @MaxRangeH1 DECIMAL(38,5),
		@MinRangeH1 DECIMAL(38,5)

;WITH STP1 AS 
(
	SELECT TOP 500 [High] , [Low] FROM EURUSD_H1
	ORDER BY [TIME] DESC 
)
SELECT @MaxRangeH1 = MAX([High]),@MinRangeH1 = MIN([Low]) FROM STP1



-- Check Hammer Candles
DROP TABLE IF EXISTS #Hammer
;WITH STP1 AS 
(
	SELECT TOP 2
		*
	FROM WeeklyFullFeature e
	ORDER BY [Time] DESC 
)
SELECT * INTO #Hammer FROM STP1


DECLARE @MinHammer bit = 0,@MaxHammer bit = 0

SELECT @MinHammer = 1 
WHERE EXISTS (
select 1 FROM #Hammer WHERE LHAMMER = 1
)

SELECT @MaxHammer = 1 
WHERE EXISTS (
select 1 FROM #Hammer WHERE UHAMMER = 1
)


DECLARE @SharkWeeklyMax DECIMAL(38,5),
		@SharkWeeklyMaxDate DATE

SELECT TOP 1 @SharkWeeklyMaxDate = [Time], @SharkWeeklyMax = [High] FROM WeeklyFullFeature 
WHERE MX = 1 and DATEDIFF(WEEK,[Time],@LastDate) > 5
ORDER BY [Time] desc 

IF(
	@FullRegCor_ between -0.40	AND 0.40
	AND 
	(
		(@SharkWeeklyMax - @LastPrice between -1*(@MaxRangeH1 - @MinRangeH1) * 0.02 and (@MaxRangeH1 - @MinRangeH1) * 0.02) -- میخوایم نزدیک به مقاومت هفتگی باشد
		OR
		@MaxHammer = 1
	)
)
BEGIN
	set @WhichBlockUsed = 5

	exec [Operation].[SellPosition] @ClassName = 'SellPosition'

END



DECLARE @SharkWeeklyMin DECIMAL(38,5),
		@SharkWeeklyMinDate DATE

SELECT TOP 1 @SharkWeeklyMinDate = [Time] , @SharkWeeklyMin = [Min] FROM WeeklyFullFeature 
WHERE [Min] = 1 and DATEDIFF(WEEK,[Time],@LastDate) > 5
ORDER BY [Time] desc 

IF(
	@FullRegCor_ between -0.40	AND 0.40
	AND 
	(
		@LastPrice - @SharkWeeklyMin between -1*(@MaxRangeH1 - @MinRangeH1) * 0.02 and (@MaxRangeH1 - @MinRangeH1) * 0.02 -- میخوایم نزدیک به مقاومت هفتگی باشد
		OR
		@MinHammer = 1
	)
)
BEGIN
	set @WhichBlockUsed = 6

	exec [Operation].[BuyPosition] @ClassName = 'BuyPosition'
END


IF(@WhichBlockUsed IN (5,6))
BEGIN 
	PRINT CONCAT(
	'Message from @WhichBlockUsed IN (5,6) ** Range trend and SharkZone Based **',char(10),char(10),

	'Last Price in the H1 Table in ', FORMAT(@LastDate,'yyyy-MM-dd HH') ,' is: ',@LastPrice,char(10),char(10),

	'FULL Regresseion since pivot(MIN or MAX) on : ',@LongReggressionDate_,' is: ',@FullRegCor_,char(10),char(10),

	'the MIN SharkDate: ',@SharkWeeklyMinDate, ' and the MAX SharkDate: ' ,@SharkWeeklyMaxDate,char(10),char(10),

	'Price is between active range ', -1*(@MaxRangeH1 - @MinRangeH1) * 0.02 ,' and ',(@MaxRangeH1 - @MinRangeH1) * 0.02 ,char(10),char(10),

	'Min Hamer: ',@MinHammer ,' AND MaxHammer: ',@MaxHammer ,char(10),char(10),

	'** Sell @SharkWeeklyMax - @LastPrice: ' ,@SharkWeeklyMax - @LastPrice ,char(10),char(10),

	'&& Buy @SharkWeeklyMax - @LastPrice: ' ,@LastPrice - @SharkWeeklyMin
	)
	
	RETURN
END



--================== An output for no choice 
PRINT CONCAT(
	'No block has been chosen',char(10),char(10),

	'Last Price in the H1 Table in ', FORMAT(@LastDate,'yyyy-MM-dd HH') ,' is: ',@LastPrice,char(10),char(10),

	'FULL Regresseion since pivot(MIN or MAX) on : ',@LongReggressionDate_,' is: ',@FullRegCor_,char(10),char(10),

	'** SELL POS Dates For Max Short Time Pivots: ',@MxDte1Short_,', ', @MxDte2Short_,char(10),
	'** SELL POS And The Max Short Time Pivots Prediction: ',@MxShortPrediction_,char(10),char(10), 

	'&& BUY POS Dates For Min Short Time Pivots: ',@MinDte1Short_,', ', @MinDte2Short_,char(10),
	'&& BUY POS And The Min Short Time Pivots Prediction: ',@MinPrediction_,char(10),char(10),

	'The formula to recognize SHARKZONE in weekly (@MaxSharkZone_ - @MinSharkZone_) * 0.02: ' ,(@MaxSharkZone_ - @MinSharkZone_) * 0.02,char(10),char(10),

	'-1*(@MxShortPrediction_ - @MinPrediction_) * 0.05: ' , -1*(@MxShortPrediction_ - @MinPrediction_) * 0.1,char(10),char(10),
	'(@MxShortPrediction_ - @MinPrediction_) * 0.05: ' , (@MxShortPrediction_ - @MinPrediction_) * 0.1,char(10),char(10),


	'** SELL And For Max Prediction the distance is(@MxShortPrediction_ - @LastPrice ): ',@MxShortPrediction_ - @LastPrice ,char(10),
	'&& BUY And For Min Prediction the distance is(@LastPrice - @MinPrediction_ ): ',@LastPrice - @MinPrediction_  ,char(10)
	)


----================= No one active then 
--IF(@FullRegCor_ > 0.9)
--BEGIN 
--	set @WhichBlockUsed = 7

--	exec [Operation].[BuyPosition] @ClassName = 'BuyPosition'
--END 

--IF(@FullRegCor_ < -0.9)
--BEGIN 
--	set @WhichBlockUsed = 8

--	exec [Operation].SellPosition @ClassName = 'SELLSellPosition'
--END 



--IF(@WhichBlockUsed IN (7,8))
--BEGIN 
--	PRINT CONCAT(
--	'Message from @WhichBlockUsed IN (7,8) ** No one active then  **',char(10),char(10),

--	'Last Price in the H1 Table in ', FORMAT(@LastDate,'yyyy-MM-dd HH') ,' is: ',@LastPrice,char(10),char(10),

--	'FULL Regresseion since pivot(MIN or MAX) on : ',@LongReggressionDate_,' is: ',@FullRegCor_,char(10),char(10),

--	'the MIN SharkDate: ',@SharkWeeklyMinDate, ' and the MAX SharkDate: ' ,@SharkWeeklyMaxDate,char(10),char(10),

--	'Price is between active range ', -1*(@MaxRangeH1 - @MinRangeH1) * 0.02 ,' and ',(@MaxRangeH1 - @MinRangeH1) * 0.02 ,char(10),char(10),

--	'Min Hamer: ',@MinHammer ,' AND MaxHammer: ',@MaxHammer ,char(10),char(10),

--	'** Sell @SharkWeeklyMax - @LastPrice: ' ,@SharkWeeklyMax - @LastPrice ,char(10),char(10),

--	'&& Buy @SharkWeeklyMax - @LastPrice: ' ,@LastPrice - @SharkWeeklyMin
--	)
	
--	RETURN
--END

