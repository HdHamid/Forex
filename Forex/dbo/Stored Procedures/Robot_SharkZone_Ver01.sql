
CREATE Procedure [dbo].[Robot_SharkZone_Ver01]
 @ActiveAlgorithmPips int = 3 -- چند پیپ بالا یا پایین پیوت پندینگ اوردر رو فعال کنه؟
 ,@Window nvarchar(5) = '20'
 ,@StopLosPips int = -25 -- استاپ لاس چند پیپ بالا یا پایین ماکز یا مین پیوت باشه
 ,@TargetsPips int = 100 
 ,@Candles int = 20 -- چنتا کندل جلوتر اگز حد سود و ضرر اتفاق نیوفتاد ببنده
AS 
set nocount on



--declare @Window nvarchar(5) = '38'

DROP TABLE IF EXISTS #PIVOT

DROP TABLE IF EXISTS #TBCUR
SELECT TOP 500  ROW_NUMBER()OVER(ORDER BY [Time]) AS RowNo
	,IIF([Open] > [Close] , [Open] , [Close] ) as CandleCeiling
	,IIF([Open] > [Close] , [Close] , [Open] ) as CandleFloor
,[Time] ,[Open] ,[High] ,[Low]  ,[Close],Volume ,DateId ,RegDate 
INTO #TBCUR FROM  [dbo].[EURUSD_H1]
ORDER BY [Time] DESC


--ALTER TABLE [dbo].[EURUSD_H1]
--ADD DateId INT 

--Update w set DateId = d.id
--FROM  [dbo].[EURUSD_H1] W INNER JOIN dbo.DimDate D ON D.Endt = cast(W.Time as date)



declare @untilRowNo int = (select Max(RowNo) from  #TBCUR) - 23

DECLARE @DegreeScaler decimal(6,5) = 0.009803
--nullif((s2.CandleCeiling*0.00003/5.1),0) -- select 0.00003 / 5.1 = .00000588
--nullif((s2.CandleCeiling*0.05/5.1),0) -- select 0.05/5.1 = 0.009803



DECLARE @TSQL NVARCHAR(MAX) = 
	
	'select *															--@PivotFollowing
	,max(CandleCeiling) over(order by RowNo rows between '+@Window+' preceding and '+@Window+' following) as MaxBetween  -- Bazeye 23 + 23 baraye shenasaee Price pivot MAX  
	,Min(CandleFloor) over(order by RowNo rows between '+@Window+' preceding and '+@Window+' following) as MinBetween -- Bazeye 23 + 23 baraye shenasaee Price pivot MIN  
	,max(CandleCeiling) over(order by RowNo rows between current row and '+@Window+' following) as MaxFuture
	,min(CandleFloor) over(order by RowNo rows between current row and '+@Window+' following) as MinFuture
	from #TBCUR	
	--where RowNo <= @untilRowNo
	'

CREATE TABLE #Intermediate
(
RowNo	INT ,
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
MinFuture	DECIMAL(38,5)
)

insert into #Intermediate
(
RowNo	
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
)
exec sp_executesql @TSQL

;WITH stp2 as 
(
	select stp1.*,dt.Endt,iif(MaxBetween=CandleCeiling or RowNo = @untilRowNo,1,0) as MX ,iif(minBetween=CandleFloor or RowNo = @untilRowNo,1,0) as Min,dt.EnDay,dt.EnMonthName,dt.EnYear -- Shenasaee tarikhe PivotHa
	,iif(MaxBetween=High,1,0) as IsMXBecauseOfMaxBetween,iif(minBetween=High,1,0)IsMinBecauseOfMinBetween
	from #Intermediate as stp1
	inner join dbo.DimDate dt on dt.ID = stp1.DateID
) 
,stp3 as 
(
	select * 
	,lag(MaxBetween) over(order by RowNo) as lgMax  --Ruye Har Pivot MAX Meghdare Pivot MAX Ghabli ro miarim
	,lag(RowNo) over(order by RowNo) as lgRowNoMax
	,RowNo - lag(RowNo) over(order by RowNo) as DiffMaxCount -- tedad ruzhaye beyne 2 pivot
	from stp2 where mx = 1 
)
,stp4 as 
(
	select * 
	,lag(MinBetween) over(order by RowNo) as LgMin --Ruye Har Pivot MIN Meghdare Pivot MIN Ghabli ro miarim
	,lag(RowNo) over(order by RowNo) as lgRowNoMin
	,RowNo - lag(RowNo) over(order by RowNo) as DiffMinCount  -- tedad ruzhaye beyne 2 pivot
	from stp2 where Min = 1 	
)
,stp5 as 
(
	select s2.*
	,s3.lgMax,s4.LgMin
	,s2.RowNo -s3.lgRowNoMax as CandleDiffFromLagMaxPivot,s2.RowNo - s4.lgRowNoMin as CandleDiffFromLagMinPivot
	,IIF( s3.DiffMaxCount>0,degrees(atn2((s3.CandleCeiling-s3.lgMax)/nullif((s3.CandleCeiling*@DegreeScaler),0),s3.DiffMaxCount)),NULL)  as PivotToPivotMaxDegree
	,IIF( s4.DiffMinCount>0,degrees(atn2((s4.CandleFloor-s4.LgMin)/nullif((s4.CandleFloor*@DegreeScaler),0),s4.DiffMinCount))  ,NULL) as PivotToPivotMinDegree
	,IIF( s2.RowNo -s3.lgRowNoMax>0,degrees(atn2((s2.CandleCeiling-s3.lgMax)/nullif((s2.CandleCeiling*@DegreeScaler),0),s2.RowNo -s3.lgRowNoMax)),NULL)  as PivotToCurrentMaxDegree
	,IIF( s2.RowNo -s4.lgRowNoMin>0,degrees(atn2((s2.CandleFloor-s4.LgMin)/nullif((s2.CandleFloor*@DegreeScaler),0),s2.RowNo -s4.lgRowNoMin))  ,NULL) as PivotToCurrentMinDegree	
	from stp2 s2 
		LEFT join stp3 s3 on s2.RowNo between s3.lgRowNoMax+1 and s3.RowNo
		LEFT join stp4 s4 on s2.RowNo between s4.lgRowNoMin+1 and s4.RowNo
)
select 
RowNo
,[Time]
,[Open]
,[High]
,[Low]
,[Close]
,CandleCeiling
,CandleFloor
,Volume
,DateID
,MaxBetween
,MinBetween
,MaxFuture
,MinFuture
,Endt
,iif(RowNo = @untilRowNo and IsMXBecauseOfMaxBetween = 0 , 0 ,MX) as MX
,iif(RowNo = @untilRowNo and IsMinBecauseOfMinBetween = 0 , 0 ,min) as Min
,EnDay
,EnMonthName
,EnYear
,lgMax
,LgMin
,[close] - LgMin AS ClosePriceDiffLgMin
,LgMax - [close] AS ClosePriceDiffLgMax
,[High] - LgMin AS HighPriceDiffLgMin
,LgMax - [High] AS HighPriceDiffLgMax
,[Low] - LgMin AS LowPriceDiffLgMin
,LgMax - [Low] AS LowPriceDiffLgMax
,CandleDiffFromLagMaxPivot
,CandleDiffFromLagMinPivot
,PivotToPivotMaxDegree
,PivotToPivotMinDegree
,PivotToCurrentMaxDegree
,PivotToCurrentMinDegree
, CAST(NULL AS DECIMAL(6,4)) AS VolLagPercent
INTO #PIVOT 
from stp5 S
where  RowNo <= @untilRowNo

--select * from #PIVOT
--order by rowno


--============================BreakMaxMin
DROP TABLE IF EXISTS #BreakMaxMin

;with STP1 as 
(
	select *
		,max(a.CandleCeiling) over(order by RowNo rows between 3 preceding and 3 following) Mx3 
		,max(a.CandleCeiling) over(order by RowNo rows between 5 preceding and 5 following) Mx5
		,max(a.CandleCeiling) over(order by RowNo rows between 8 preceding and 8 following) Mx8 
		,max(a.CandleCeiling) over(order by RowNo rows between 13 preceding and 13 following) Mx13 
		,max(a.CandleCeiling) over(order by RowNo rows between 34 preceding and 34 following) Mx34
		,min(a.CandleFloor) over(order by RowNo rows between 3 preceding and 3 following) Mn3 
		,min(a.CandleFloor) over(order by RowNo rows between 5 preceding and 5 following) Mn5
		,min(a.CandleFloor) over(order by RowNo rows between 8 preceding and 8 following) Mn8 
		,min(a.CandleFloor) over(order by RowNo rows between 13 preceding and 13 following) Mn13 
		,min(a.CandleFloor) over(order by RowNo rows between 34 preceding and 34 following) Mn34
	from #PIVOT A
)
, stp2 AS 
(
SELECT *
	,IIF(Mx3 = CandleCeiling,1,0) as breakMx3
	,IIF(Mx5 = CandleCeiling,1,0) as breakMx5
	,IIF(Mx8 = CandleCeiling,1,0) as breakMx8
	,IIF(Mx13 = CandleCeiling,1,0) as breakMx13
	,IIF(Mx34 = CandleCeiling,1,0) as breakMx34
	,IIF(Mn3 = CandleFloor,1,0) as breakMn3
	,IIF(Mn5 = CandleFloor,1,0) as breakMn5
	,IIF(Mn8 = CandleFloor,1,0) as breakMn8
	,IIF(Mn13 = CandleFloor,1,0) as breakMn13
	,IIF(Mn34 = CandleFloor,1,0) as breakMn34
FROM STP1 
), stp3 as 
(
	select *
	,sum(breakMx3) over(order by RowNo) GrpMx3 
	,sum(breakMx5) over(order by RowNo) GrpMx5
	,sum(breakMx8) over(order by RowNo) GrpMx8 
	,sum(breakMx13) over(order by RowNo) GrpMx13
	,sum(breakMx34) over(order by RowNo) GrpMx34
	,sum(breakMn3) over(order by RowNo) GrpMn3 
	,sum(breakMn5) over(order by RowNo) GrpMn5
	,sum(breakMn8) over(order by RowNo) GrpMn8 
	,sum(breakMn13) over(order by RowNo) GrpMn13
	,sum(breakMn34) over(order by RowNo) GrpMn34
	from stp2 
),
STP4 AS 
(
	select *
		,FIRST_VALUE(CandleCeiling) over(partition by GrpMx3	ORDER BY RowNo) as MaxPrice3
		,FIRST_VALUE(CandleCeiling) over(partition by GrpMx5	ORDER BY RowNo)	as MaxPrice5
		,FIRST_VALUE(CandleCeiling) over(partition by GrpMx8	ORDER BY RowNo)	as MaxPrice8
		,FIRST_VALUE(CandleCeiling) over(partition by GrpMx13	ORDER BY RowNo)	as MaxPrice13
		,FIRST_VALUE(CandleCeiling) over(partition by GrpMx34	ORDER BY RowNo)	as MaxPrice34
		,FIRST_VALUE(CandleFloor) over(partition by GrpMn3	ORDER BY RowNo)	as MinPrice3
		,FIRST_VALUE(CandleFloor) over(partition by GrpMn5	ORDER BY RowNo)	as MinPrice5
		,FIRST_VALUE(CandleFloor) over(partition by GrpMn8	ORDER BY RowNo)	as MinPrice8
		,FIRST_VALUE(CandleFloor) over(partition by GrpMn13	ORDER BY RowNo)	as MinPrice13
		,FIRST_VALUE(CandleFloor) over(partition by GrpMn34	ORDER BY RowNo)	as MinPrice34
	from stp3
) 
SELECT 
	RowNo
	,Time
	,[Open]
	,[High]
	,[Low]
	,[Close]
	,CandleCeiling
	,CandleFloor
	,Volume
	,DateID
	,MaxBetween
	,MinBetween
	,MaxFuture
	,MinFuture
	,Endt
	,MX
	,Min
	,EnDay
	,EnMonthName
	,EnYear
	,lgMax
	,LgMin
	,ClosePriceDiffLgMin
	,ClosePriceDiffLgMax
	,HighPriceDiffLgMin
	,HighPriceDiffLgMax
	,LowPriceDiffLgMin
	,LowPriceDiffLgMax
	,CandleDiffFromLagMaxPivot
	,CandleDiffFromLagMinPivot
	,PivotToPivotMaxDegree
	,PivotToPivotMinDegree
	,PivotToCurrentMaxDegree
	,PivotToCurrentMinDegree
	,VolLagPercent	
	--,[+Di14]
	--,[-Di14]
	--,ADX
	,IIF(CandleCeiling > MaxPrice3,1,0) as IsBiggerThanMaxPrice3
	,IIF(CandleCeiling > MaxPrice5,1,0) as IsBiggerThanMaxPrice5
	,IIF(CandleCeiling > MaxPrice8,1,0) as IsBiggerThanMaxPrice8
	,IIF(CandleCeiling > MaxPrice13,1,0) as IsBiggerThanMaxPrice13
	,IIF(CandleCeiling > MaxPrice34,1,0) as IsBiggerThanMaxPrice34
	,IIF(CandleFloor < MinPrice3,1,0) as IsLessThanMinPrice3
	,IIF(CandleFloor < MinPrice5,1,0) as IsLessThanMinPrice5
	,IIF(CandleFloor < MinPrice8,1,0) as IsLessThanMinPrice8
	,IIF(CandleFloor < MinPrice13,1,0) as IsLessThanMinPrice13	
	,IIF(CandleFloor < MinPrice34,1,0) as IsLessThanMinPrice34
	
	,abs(CandleCeiling - MaxPrice3	)/MaxPrice3		as ResistantDistanceMaxPrice3
	,abs(CandleCeiling - MaxPrice5	)/MaxPrice5		as ResistantDistancePrice5
	,abs(CandleCeiling - MaxPrice8	)/MaxPrice8		as ResistantDistancePrice8
	,abs(CandleCeiling - MaxPrice13	)/MaxPrice13		as ResistantDistancePrice13
	,abs(CandleCeiling - MaxPrice34	)/MaxPrice34		as ResistantDistancePrice34
	,abs(CandleFloor - MinPrice3	)/MinPrice3	as SupportDistanceMinPrice3
	,abs(CandleFloor - MinPrice5	)/MinPrice5	as SupportDistanceMinPrice5
	,abs(CandleFloor - MinPrice8	)/MinPrice8	as SupportDistanceMinPrice8
	,abs(CandleFloor - MinPrice13	)/MinPrice13	as SupportDistanceMinPrice13	
	,abs(CandleFloor - MinPrice34	)/MinPrice34	as SupportDistanceMinPrice34


INTO #BreakMaxMin
FROM STP4 s4


DROP TABLE IF EXISTS ##ResFin
;WITH stp1 AS
(
SELECT *
	,IIF(a.[Open] > a.[Close] , 1 , 0 ) as IsRed
	,IIF(a.[Open] < a.[Close] , 1 , 0 ) as IsGreen
	,(a.[High]-a.[Low])			as [_PriceRange]	
	,(a.[High]-a.[Low])/NULLIF(a.[Close],0) as PriceRangeWidthPrcnt
	,(a.[close]+a.[open]) / 2 as MiddleBodyPrice
	,(a.[high]+a.[Low]) / 2 as MiddleFullPrice
	,a.ClosePriceDiffLgMax/a.lgMax AS ResistantDistancePrcnt
	,a.ClosePriceDiffLgMin/a.LgMin AS SupportDistancePrcnt
	,a.CandleCeiling - a.CandleFloor AS FloorToCieling
	FROM #BreakMaxMin a
)
, stp2 as 
(
SELECT *
	,(CandleCeiling - CandleFloor) / NULLIF([Close],0) as CandleBodyRangeWidthPrcnt --- اندازه بدنه کندل 
	,(ABS([close]-[open])/NULLIF([_PriceRange],0))		as [_CloseOpenPrcnt]
	,([High]-CandleCeiling)/NULLIF([_PriceRange],0)		as [_HighCielingPrcnt]
	,(CandleFloor-[Low])/NULLIF([_PriceRange],0)			as [_FloorLowPrcnt]
FROM stp1 s
),
Stp3 as 
(
select *
	,lag(IsRed) over(order by RowNo) as	  OneLagIsRed
	,lag(IsGreen) over(order by RowNo) as OneLagIsGreen
	,lag(CandleCeiling) over(order by RowNo) as OneLagCandleCeiling
	,lag(CandleFloor) over(order by RowNo) as OneLagCandleFloor
	,lag([High]) over(order by RowNo) as OneLagHigh
	,lag([low]) over(order by RowNo) as OneLagLow
	,lag(CandleBodyRangeWidthPrcnt) over(order by RowNo) as OneCandleBodyRangeWidthPrcnt
	,lag(FloorToCieling) over(order by RowNo) as OneFloorToCieling
from stp2
)
, STP4 AS 
(
select * 
	,IIF(OneFloorToCieling < FloorToCieling * 0.2 AND OneCandleBodyRangeWidthPrcnt > 0.00015 AND ABS(CandleFloor - OneLagCandleFloor) < CandleCeiling - OneLagCandleFloor
	,1 
	,0) AS MonsterCandle_Bullish

	,IIF(OneFloorToCieling < FloorToCieling * 0.2 AND OneCandleBodyRangeWidthPrcnt > 0.00015 AND ABS(CandleCeiling - OneLagCandleCeiling) <  OneLagCandleCeiling - CandleFloor
	,1 
	,0) AS MonsterCandle_Bearish
	
	,IIF([_HighCielingPrcnt] > .7 AND CandleBodyRangeWidthPrcnt > 0.00015, 1 ,0) AS UHAMMER

	,IIF([_FloorLowPrcnt] > .7 AND CandleBodyRangeWidthPrcnt > 0.00015, 1 ,0) AS LHAMMER

	,IIF(CandleDiffFromLagMinPivot in (1,2) AND IsGreen = 1 AND CandleBodyRangeWidthPrcnt > 0.001 , 1 , 0) as IsSharkZone



from Stp3 
)
SELECT try_convert(datetime,[Time]) AS [DateTime],* INTO ##ResFin FROM STP4 s

create clustered index IX on ##ResFin([DateTime])

--select * from ##ResFin


---======================= Regression







--=============== SIGNAL	
--exec Features
---========= برای سقف یابی و پوزیشن فروش
--Declare @ActiveAlgorithmPips int = 3
--declare @PivotFollowing int = 5
--Declare @StopLosPips int = -5
--Declare @TargetsPips int = 100
--Declare @Candles int = 20

-- ماکزیممها رو از ریزالتن میکشه بیرون
-- از ماکزی تا دوتا ماکز بعد حمایت و مقاومت رو معتبر میدونیم و هر قیمتی بیاد توش ازش تاثیر میگیره
DROP TABLE IF EXISTS #MX
SELECT 
	RowNo
	,[DateTime]	
	,f.[High]
	,ABS(10000*(CandleCeiling-lag(CandleCeiling)over(order by [DateTime]))) as DiffPipCandleCeiling
INTO #MX
FROM ##ResFin f WHERE mx=1 AND (F.CandleCeiling - MinFuture) * 10000 > (@TargetsPips/2)



DROP TABLE IF EXISTS #MXSignal
select top 2
	*
	,M.[High]-(@ActiveAlgorithmPips*1.00000/10000) AS SellTriggerPrice
	,M.[High]-(@StopLosPips*1.00000/10000) AS StopLoss
	,M.[High]-(@TargetsPips*1.00000/10000) AS TakeProfit
	,@Candles as ForwardCandles
	,'Sell' AS SignalType 
into #MXSignal
from #MX M
	--where DiffPipCandleCeiling > 0
ORDER BY [DateTime] DESC 




---========= برای کف یابی و پوزیشن خرید

DROP TABLE IF EXISTS #MN
SELECT 
	RowNo
	,[DateTime]
	,f.[Low]
	,ABS(10000*(CandleFloor-lag(CandleFloor)over(order by [DateTime]))) as DiffPipCandleFloor
INTO #MN
FROM ##ResFin f WHERE [Min]=1 AND (MaxFuture - F.CandleFloor) * 10000 > (@TargetsPips/2)


DROP TABLE IF EXISTS #MNSignal
select top 2 
	*
	,M.[Low]+(@ActiveAlgorithmPips*1.00000/10000) AS BuyTriggerPrice 
	,M.[Low]+(@StopLosPips*1.00000/10000) AS StopLoss
	,M.[Low]+(@TargetsPips*1.00000/10000) AS TakeProfit
	,@Candles as ForwardCandles
	,'Buy' AS SignalType 
into #MNSignal
from #MN M
	--where DiffPipCandleFloor > 0
ORDER BY [DateTime] DESC 




--- RESULT

;WITH stp1 AS 
(
SELECT [DateTime],[High] as HighLow,SellTriggerPrice AS PendingPrice,StopLoss,TakeProfit,ForwardCandles,SignalType
	,CONCAT(SellTriggerPrice,',',StopLoss,',',TakeProfit,',',ForwardCandles)AS FullStr FROM #MXSignal
UNION ALL
SELECT [DateTime],[Low],BuyTriggerPrice,StopLoss,TakeProfit,ForwardCandles,SignalType
	,CONCAT(BuyTriggerPrice,',',StopLoss,',',TakeProfit,',',ForwardCandles)FROM #MNSignal
)
,stp2 as 
(
SELECT 
ROW_NUMBER() over(order by SignalType,[DateTime]) RN,* from stp1
)
select 
	[DateTime]
	,HighLow
	,PendingPrice--,IIF(rn%2 > 0,0,PendingPrice) as PendingPrice
	,StopLoss
	,TakeProfit
	,ForwardCandles
	,SignalType
	,FullStr
from stp2
ORDER BY SignalType,[DateTime]  
