CREATE Procedure [dbo].[Robot_TrendBase_Active]
AS 

SET NOCOUNT ON

declare  @ActiveAlgorithmPips int = 3 -- چند پیپ بالا یا پایین پیوت پندینگ اوردر رو فعال کنه؟
 ,@WindowFrom nvarchar(5) = '8'
 ,@WindowTo nvarchar(5) = '2'
 ,@ForwardCandles int = 15

DROP TABLE IF EXISTS #PIVOT

DROP TABLE IF EXISTS #TBCUR
SELECT TOP 25  IIF([Open] > [Close] , [Open] , [Close] ) as CandleCeiling
	,IIF([Open] > [Close] , [Close] , [Open] ) as CandleFloor
,[Time] ,[Open] ,[High] ,[Low]  ,[Close],Volume ,DateId ,RegDate 
INTO #TBCUR FROM  Dbo.EURUSD_H1
ORDER BY [Time] DESC

SELECT 
ROW_NUMBER() OVER(ORDER BY [Time] desc) AS RowNoDesc
,ROW_NUMBER() OVER(ORDER BY [Time]) AS RowNo
,*
INTO #PIVOT
FROM #TBCUR


--select *															--@PivotFollowing
--	,max(CandleCeiling) over(order by [Time] rows between 5 preceding and 2 following) as MaxBetween  
--	,Min(CandleFloor) over(order by [Time] rows between 5 preceding and 2 following) as MinBetween 
--	,max(CandleCeiling) over(order by [Time] rows between current row and 2 following) as MaxFuture
--	,min(CandleFloor) over(order by [Time] rows between current row and 2 following) as MinFuture
--	,IIF([Open] > [Close] , 1 , 0 ) as IsRed
--	,IIF([Open] < [Close] , 1 , 0 ) as IsGreen
--	from #PIVOT	



DECLARE @TSQL NVARCHAR(MAX) = 
	
	'select *															--@PivotFollowing
	,max([High]) over(order by [Time] rows between '+@WindowFrom+' preceding and '+@WindowTo+' following) as MaxBetween  
	,Min([Low]) over(order by [Time] rows between '+@WindowFrom+' preceding and '+@WindowTo+' following) as MinBetween 
	,max(CandleCeiling) over(order by [Time] rows between current row and '+@WindowTo+' following) as MaxFuture
	,min(CandleFloor) over(order by [Time] rows between current row and '+@WindowTo+' following) as MinFuture
	,IIF([Open] > [Close] , 1 , 0 ) as IsRed
	,IIF([Open] < [Close] , 1 , 0 ) as IsGreen
	from #PIVOT	
	--where RowNoDesc <= @untilRowNoDesc
	'
DROP TABLE IF EXISTS #Intermediate
CREATE TABLE #Intermediate
(
RowNoDesc	INT ,
RowNo INT,
CandleCeiling	DECIMAL(38,5),
CandleFloor	DECIMAL(38,5),
[Time]	DATETIME,
[Open]		DECIMAL(38,5),
[High]		DECIMAL(38,5),
[Low]		DECIMAL(38,5),
[Close]		DECIMAL(38,5),
Volume		DECIMAL(38,5),
DateId	INT,
RegDate	DATETIME,
MaxBetween	DECIMAL(38,5),
MinBetween	DECIMAL(38,5),
MaxFuture	DECIMAL(38,5),
MinFuture	DECIMAL(38,5),
MaxRegBetween DECIMAL(38,5),
MinRegBetween DECIMAL(38,5),
MaxRegFuture DECIMAL(38,5),
MinRegFuture DECIMAL(38,5),
IsRed INT,
IsGreen INT
)

insert into #Intermediate
(
RowNoDesc	
,RowNo
,CandleCeiling	
,CandleFloor	
,[Time]	
,[Open]		
,[High]		
,[Low]		
,[Close]		
,Volume		
,DateId	
,RegDate	
,MaxBetween	
,MinBetween	
,MaxFuture	
,MinFuture	
,IsRed
,IsGreen
)
exec sp_executesql @TSQL


DECLARE @MaxMinRatio decimal(38,5)
DECLARE @SumDiff decimal(38,5)
DECLARE @Ceiling decimal(38,5)
DECLARE @Floor decimal(38,5)
DECLARE @IsMax bit
DECLARE @IsVawePos bit
DECLARE @DateTime DateTime
DECLARE @IsGreen bit
DECLARE @DegreeScaler decimal(6,5) = 0.009803
DECLARE @CandleForVawe int = 23
DECLARE @SumDegree DECIMAL(38,2)
DECLARE @AvgDegree DECIMAL(38,2)
 ,@MinRowNumberDescFilter int = 2 -- حد اقل چنتا کندل جلوی سیگنال باشه؟
 ,@MaxRowNumberDescFilter int = 7 -- حد اکثر چنتا کندل جلوی سیگنال باشه؟

DECLARE @Degree decimal(38,5) 


DROP TABLE IF EXISTS #Stp1
SELECT *
	,IIF(MaxBetween = [high],1,0) AS MX
	,IIF(MinBetween = [Low],1,0) AS [Min]
	,CandleCeiling - LAG(CandleCeiling,@CandleForVawe)	OVER(ORDER BY [Time]) CeilDiff -- اختلاف کف با قبلی 
	,CandleFloor - LAG(CandleFloor,@CandleForVawe)	OVER(ORDER BY [Time]) FloorDiff -- اختلاف سقف با قبلی 	
INTO #Stp1
FROM #Intermediate


DROP TABLE IF EXISTS #Stp2
SELECT *,
	degrees(atn2((S1.FloorDiff)/nullif((S1.CandleFloor*@DegreeScaler),0),@CandleForVawe*1.00))  as Degree
	INTO #Stp2
FROM #Stp1 S1


SELECT 
	@MaxMinRatio = SUM(IsGreen)*1.00/SUM(IsRed)	, -- منطقش اینه که اگر سبزها بیشتر باشن احتمالا صعودیه و .. 
	@SumDiff = sum(CeilDiff)+sum(FloorDiff), --این کارا برای اینه که بفهمیم ترند  صعودی هست یا نزولی دیگه نریم سراغ رکرشن و زاویه و .... 
	@SumDegree = sum(Degree),
	@AvgDegree = avg(Degree)
FROM #Stp2
where RowNoDesc <= @CandleForVawe



select @IsVawePos = 1 where @SumDegree > 0 
select @IsVawePos = 0 where @SumDegree < 0

--select @IsVawePos,@SumDegree

SELECT @Degree = Degree FROM #Stp2 WHERE RowNoDesc = 1  -- درجه زاویه ترند چنده؟
PRINT @Degree
PRINT @AvgDegree

-- پیوت یابی مینیمم
SELECT TOP 1 @Ceiling = [High]+.0002 , @Floor = [Low]-.0002 , @IsMax = MX,@DateTime = [Time] ,@IsGreen = IsGreen
FROM #Stp2 s WHERE  @IsVawePos = 0 and [Min] = 1 and RowNoDesc BETWEEN @MinRowNumberDescFilter AND @MaxRowNumberDescFilter
ORDER BY [Time] DESC 


-- پیوت یابی ماکزیمم
SELECT TOP 1 @Ceiling = [High]+.0002 , @Floor = [Low]-.0002 , @IsMax = MX,@DateTime = [Time] ,@IsGreen = IsGreen
FROM #Stp2 S WHERE  @IsVawePos = 1 and MX = 1 and RowNoDesc BETWEEN @MinRowNumberDescFilter AND @MaxRowNumberDescFilter
ORDER BY [Time] DESC 


DECLARE  @sl DECIMAL(38,5) 

;with stp1 as 
(
select * 
	, MAX(CandleCeiling) OVER(ORDER BY [Time] ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS MaxSl
	, MIN(CandleFloor) OVER(ORDER BY [Time] ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS MinSl
from #Stp2 
	where [Time] > @DateTime
)
select TOP 1 @sl = iif(@IsVawePos = 1 ,MinSl,MaxSl) from stp1 where MinSl = CandleFloor or MaxSl = CandleCeiling


--select @IsVawePos as IsVawePos,@MaxMinRatio as MinMaxRatio,@SumDiff as SumDiff
--,@IsMax as IsMax,@Ceiling as [Ceiling],@Floor as [Floor]


IF(@Floor IS NOT NULL AND /*ABS(@Degree) > 1 AND*/ @IsVawePos = 0 AND NOT EXISTS (SELECT 1 FROM #Stp1 S1 WHERE [Time] > @DateTime AND CandleFloor < @Floor))
BEGIN
	SELECT @DateTime AS [DateTime],@Floor as PendingPrice, /*@sl*/ 0 as StopLoss,@Floor-((@sl - @Floor)*3) as TakeProfit,@ForwardCandles AS ForwardCandles, 'Sell' as SignalType
	RETURN
END 


IF(@Ceiling IS NOT NULL AND /*ABS(@Degree) > 1 AND*/ @IsVawePos = 1 AND NOT EXISTS (SELECT 1 FROM #Stp1 S1 WHERE [Time] > @DateTime AND CandleCeiling > @Ceiling))
BEGIN
	SELECT @DateTime AS [DateTime],@Ceiling as PendingPrice, /*@sl*/ 0 as StopLoss,@Ceiling+((@Ceiling - @sl)*3) as TakeProfit,@ForwardCandles AS ForwardCandles, 'Buy' as SignalType
	RETURN
END


-- فقط برای اینکه خروجی داده باشیم
SELECT '1990-1-01 00:00:00' AS [DateTime],0 as PendingPrice, 0 as StopLoss,0 as TakeProfit,@ForwardCandles AS ForwardCandles, 'Buy' as SignalType
RETURN


--DateTime	HighLow	PendingPrice	StopLoss	TakeProfit	ForwardCandles	SignalType	FullStr

