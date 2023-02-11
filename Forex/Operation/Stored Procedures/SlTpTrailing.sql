--exec [Operation].[SlTpTrailing] @IsBuy = 1
CREATE PROCEDURE [Operation].[SlTpTrailing]
	 @DteTime    Date = '2020-01-01'
	,@OldSl		 varchar(500) = '0'
	,@OldTp		 varchar(500) = '0'
	,@PosProfit	 varchar(500) = '0'
	,@PriceOpen	 varchar(500) = '0'
	,@posVol	 varchar(500) = '0'
	,@IsBuy		 bit		   
	,@TrailingWavePrcnt decimal(5,3) = 0.2 
as

--DECLARE 
--@DteTime		DATE='2022-01-13 10:03:15'
--,@OldSl		varchar(500)			=N'1.64682'
--,@OldTp		varchar(500)	=N'0'
--,@PosProfit	varchar(500)		=N'64'
--,@PriceOpen	varchar(500)		=N'1.14684'
--,@posVol	varchar(500)		=N'1'
--,@IsBuy		bit	=0
--,@TrailingWavePrcnt decimal(5,3) = 0.2 



declare 
 @OldSl_		 decimal(38,5) = (select cast(@OldSl	 as decimal(38,5)))
,@OldTp_		 decimal(38,5) = (select cast(@OldTp	 as decimal(38,5)))
,@PosProfit_	 decimal(38,5) = (select cast(@PosProfit as decimal(38,5)))
,@PriceOpen_	 decimal(38,5) = (select cast(@PriceOpen as decimal(38,5)))
,@posVol_	 decimal(38,5)	   = (select cast(@posVol	 as decimal(38,5)))


declare @Wave decimal(38,5)
;with stp1 as 
(
SELECT TOP 500 
	[High] ,[Low]
FROM  Dbo.EURUSD_H1
ORDER BY [Time] DESC
)
select @Wave = (max([high])-Min([Low])) from stp1



declare @WavePrcnt decimal(38,5) = (select @Wave*@TrailingWavePrcnt)


--IF @PosProfit_ <= @WavePrcnt -- اگر هنوزبه سود نرفته که استاپ قبلی معتبره
--BEGIN
--	select concat(@OldSl,',',@OldTp) as sltp
--	RETURN 
--END 



--====================== Get Weekly
BEGIN
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
	@MinSharkZone_			DECIMAL(38,5)

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
	@MinSharkZone_			= MinSharkZone		  -- کمینه ی شارک زون بلند مدت 
FROM
 Operation.WeeklyInfo

END 


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

DECLARE @Top INT = 200
	 ,@UniqueTableName nvarchar(50) 

IF(@PosProfit_ <= 0) -- اگر هنوز به سود نرفته بود بهش فرصت بیشتری میدیم و رو پیوتهای 25 تایی دنبال حد ضرر میگردیم
BEGIN
		
	EXEC Calc.PivotFinder  @Top = @Top,@WindowFrom = 25 ,@WindowTo = 25 , @UniqueTableName = @UniqueTableName OUT  
END


IF(@PosProfit_ > 0) -- وقتی میره تو سود دیگه سختگیر تر میشیم و پیوتها رو در بازه های 10 تایی در نظر میگیریم
BEGIN
	
	EXEC Calc.PivotFinder  @Top = @Top,@WindowFrom = 10 ,@WindowTo = 10 , @UniqueTableName = @UniqueTableName OUT  
END



DECLARE @SQLCC NVARCHAR(MAX) = CONCAT('SELECT * FROM ',@UniqueTableName)
INSERT INTO #PIVOT
exec sp_executesql @SQLCC


DECLARE @LastPrice DECIMAL(38,5)
SELECT TOP 1 @LastPrice = [CLOSE] FROM #PIVOT
ORDER BY [TIME] DESC 

declare @newsl decimal(38,5) 
declare @newtp decimal(38,5) 
declare @slPivotDate datetime 


IF (@IsBuy = 0)
begin
	
	;with stp1 as 
	(
		select [time],[High],lag([High]) over(order by [Time]) AS LgHigh,lag([Time]) over(order by [Time]) AS LgTime from #PIVOT WHERE MX = 1 
	)
	select top 1 @slPivotDate = IIF([High] >= LgHigh,[time],LgTime),@newsl=IIF([High] >= LgHigh,[High],LgHigh) from stp1 
	order by [time] desc 
	
	--select @newtp = @OldTp-abs(@newsl- @OldSl)
	select @newtp =@MinPrediction_ 
	print FORMAT(@slPivotDate,'yyyy-MM-dd HH')
	select concat(isnull(@newsl,@OldSl),',',isnull(IIF(@newtp > @LastPrice,0,@newtp),0)) as sltp
	RETURN
end

IF (@IsBuy = 1)
begin 
	;with stp1 as 
	(
		select [time],ROW_NUMBER() over(order by [Time] desc ) rn , [Low] from #PIVOT WHERE [Min] = 1 
	)
	select @slPivotDate = [Time],@newsl=[Low] from stp1 WHERE rn = 3
	--select @newtp = @OldTp+abs(@newsl- @OldSl)
	select @newtp = @MxShortPrediction_
	print FORMAT(@slPivotDate,'yyyy-MM-dd HH')
	select concat(isnull(@newsl,@OldSl),',',isnull(IIF(@newtp < @LastPrice,0,@newtp),0)) as sltp
	RETURN
end 




