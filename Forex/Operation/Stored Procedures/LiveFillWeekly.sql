CREATE PROCEDURE [Operation].[LiveFillWeekly]
AS
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

--======================================= 
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
	@LongReggressionDate_	= @LongReggressionDate_ OUT,
	@LongReggressionType_	= @LongReggressionType_ OUT

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
	@LongReggressionDate_ AS LongReggressionDate,
	@LongReggressionType_ AS LongReggressionType
	INTO Operation.WeeklyInfo
	--print CONCAT('@DayOfWeek in(2,6) ',': ',@DayOfWeek)
	--return
	
	EXEC [Calc].[FILL_WeeklyFullFeature] @WindowFrom = '10',@WindowTo = '10'
end

