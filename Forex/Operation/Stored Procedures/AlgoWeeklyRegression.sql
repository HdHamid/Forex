CREATE PROCEDURE [Operation].[AlgoWeeklyRegression]
AS 
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
	@LongReggressionDate_	DATE ,
	@LongReggressionType_	CHAR(3)
exec Operation.LiveFillWeekly


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
	@LongReggressionDate_	= LongReggressionDate,
	@LongReggressionType_   = LongReggressionType
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

--DECLARE @pvt pvt 

--INSERT INTO @pvt([time],[High],[Low])
--SELECT [time],[High],[Low] FROM #PIVOT

--DROP TABLE IF EXISTS #ResPvt
--CREATE TABLE #ResPvt 
--(
--	[time] DATETIME
--	,[High] DECIMAL(38,5)
--	,[Low] DECIMAL(38,5)
--	,IsMax BIT
--	,IsMin BIT
--)
--INSERT INTO #ResPvt
--exec Common.PivotFinder @pvt

--SELECT top 1 @LastPrice = IIF(IsMax = 1 ,[High],[Low]),@LastDate = [Time] FROM #ResPvt
--	WHERE IsMax = 1 OR IsMin = 1
--ORDER BY [time] DESC 



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
	--@LongReggressionType_ = 'MAX'
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
	--@LongReggressionType_ = 'MIN'
	--AND 	
	@FullRegCor_ > 0.40		
	AND 
	@LastPrice - @MinPrediction_  between -1*(@MxShortPrediction_ - @MinPrediction_) * 0.1  and (@MxShortPrediction_ - @MinPrediction_) * 0.1  -- میخوایم نزدیک به مقاومت هفتگی باشد
	)
BEGIN
	set @WhichBlockUsed = 2	
	exec [Operation].[BuyPosition] @ClassName = 'BuyPosition'
	
END


PRINT CONCAT(
	'Message from @WhichBlockUsed IN (1,2) ** A weekly support or resistance based on reggression touched **',char(10),char(10),

	'Last Price in the H1 Table in ', FORMAT(@LastDate,'yyyy-MM-dd HH') ,' is: ',@LastPrice,char(10),char(10),

	'FULL Regresseion since '+	@LongReggressionType_ +' pivot on : ',@LongReggressionDate_,' is: ',@FullRegCor_,char(10),char(10),

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
	
