
--exec [dbo].[Robot_SharkZone_Active] @isTest = 1
CREATE Procedure [dbo].[Robot_SharkZone_FirstStable]
  @ActiveAlgorithmPips decimal(38,5) = 0.01 -- چند پیپ بالا یا پایین پیوت پندینگ اوردر رو فعال کنه؟
 ,@WindowFrom nvarchar(5) = '7'
 ,@WindowTo nvarchar(5) = '13'
 ,@PipRangeFromPivot decimal(38,5) = 0.1 -- بعد از هر پیوت که شناخته تا چندتا بالاترش رفته؟ به پارامتر کندلهای بعدیش ویندو تو دقت کن که 5 گذاشته باشی خوب 30 پیپ مسخرس بعبارتی خواستم قدرت پیوت رو بسنجم
 ,@StopLosPips decimal(38,5) = -0.2-- استاپ لاس چند پیپ بالا یا پایین ماکز یا مین پیوت باشه
 ,@TargetsPips decimal(38,5) = 0.4 
 ,@Candles int = 40 -- چنتا کندل جلوتر اگز حد سود و ضرر اتفاق نیوفتاد ببنده
 ,@RegWindow int = 5 -- رگرشن
 ,@OppositeSignalPips decimal(38,5) = 0.02 -- 30 pips
 ,@OppositeSignalSlPips decimal(38,5) = 0.1 -- 30 pips nesbat be pending asli na opposite
 ,@OppositeSignalTpPips decimal(38,5) = 0.1 -- 300 pips pips nesbat be pending asli na opposite
 ,@isTest bit = 0
 
AS 
set nocount on


--declare   @ActiveAlgorithmPips decimal(38,5) = 0.01 -- چند پیپ بالا یا پایین پیوت پندینگ اوردر رو فعال کنه؟
-- ,@WindowFrom nvarchar(5) = '7'
-- ,@WindowTo nvarchar(5) = '13'
-- ,@PipRangeFromPivot decimal(38,5) = 0.1 -- بعد از هر پیوت که شناخته تا چندتا بالاترش رفته؟ به پارامتر کندلهای بعدیش ویندو تو دقت کن که 5 گذاشته باشی خوب 30 پیپ مسخرس بعبارتی خواستم قدرت پیوت رو بسنجم
-- ,@StopLosPips decimal(38,5) = -0.2-- استاپ لاس چند پیپ بالا یا پایین ماکز یا مین پیوت باشه
-- ,@TargetsPips decimal(38,5) = 0.4 
-- ,@Candles int = 40 -- چنتا کندل جلوتر اگز حد سود و ضرر اتفاق نیوفتاد ببنده
-- ,@RegWindow int = 5 -- رگرشن
-- ,@OppositeSignalPips decimal(38,5) = 0.02 -- 30 pips
-- ,@OppositeSignalSlPips decimal(38,5) = 0.1 -- 30 pips nesbat be pending asli na opposite
-- ,@OppositeSignalTpPips decimal(38,5) = 0.1 -- 300 pips pips nesbat be pending asli na opposite
-- ,@isTest bit = 0



DECLARE @CoefForSlTp DECIMAL(38,5)

DROP TABLE IF EXISTS #PIVOT

DROP TABLE IF EXISTS #TBCUR
SELECT TOP 500  ROW_NUMBER()OVER(ORDER BY [Time]) AS RowNo
	,IIF([Open] > [Close] , [Open] , [Close] ) as CandleCeiling
	,IIF([Open] > [Close] , [Close] , [Open] ) as CandleFloor
,
[Time] ,[Open] ,[High] ,[Low]  ,[Close],Volume ,DateId ,RegDate
INTO #TBCUR FROM  Dbo.EURUSD_H1
ORDER BY [Time] DESC


SELECT 
	@ActiveAlgorithmPips    = (MAX([High])-MIN([Low]))*@ActiveAlgorithmPips
	,@PipRangeFromPivot		= (MAX([High])-MIN([Low]))*@PipRangeFromPivot
	,@StopLosPips			= (MAX([High])-MIN([Low]))*@StopLosPips
	,@TargetsPips			= (MAX([High])-MIN([Low]))*@TargetsPips
	,@OppositeSignalPips	=(MAX([High])-MIN([Low]))*@OppositeSignalPips
	,@OppositeSignalSlPips	=(MAX([High])-MIN([Low]))*@OppositeSignalSlPips
	,@OppositeSignalTpPips	=(MAX([High])-MIN([Low]))*@OppositeSignalTpPips
FROM #TBCUR

--SELECT 
--@ActiveAlgorithmPips		AS 	ActiveAlgorithmPips		
--,@PipRangeFromPivot			AS 	PipRangeFromPivot		
--,@StopLosPips				AS	StopLosPips			
--,@TargetsPips				AS	TargetsPips			
--,@OppositeSignalPips		AS	OppositeSignalPips	
--,@OppositeSignalSlPips		AS	OppositeSignalSlPips
--,@OppositeSignalTpPips		AS	OppositeSignalTpPips


--ALTER TABLE [dbo].[EURUSD_H1]
--ADD DateId INT 

--Update w set DateId = d.id
--FROM  [dbo].[EURUSD_H1] W INNER JOIN dbo.DimDate D ON D.Endt = cast(W.Time as date)



declare @untilRowNo int = (select Max(RowNo) from  #TBCUR) - cast(@WindowTo as int)

DECLARE @DegreeScaler decimal(6,5) = 0.00184
--nullif((s2.CandleCeiling*0.00003/5.1),0) -- select 0.00003 / 5.1 = .00000588
--nullif((s2.CandleCeiling*0.05/5.1),0) -- select 0.05/5.1 = 0.009803



DECLARE @TSQL NVARCHAR(MAX) = 
	
	'select *															--@PivotFollowing
	,max(CandleCeiling) over(order by RowNo rows between '+@WindowFrom+' preceding and '+@WindowTo+' following) as MaxBetween  
	,Min(CandleFloor) over(order by RowNo rows between '+@WindowFrom+' preceding and '+@WindowTo+' following) as MinBetween 
	,max(CandleCeiling) over(order by RowNo rows between current row and '+@WindowTo+' following) as MaxFuture
	,min(CandleFloor) over(order by RowNo rows between current row and '+@WindowTo+' following) as MinFuture
	from #TBCUR	
	--where RowNo <= @untilRowNo
	'
DROP TABLE IF EXISTS #Intermediate
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
MinFuture	DECIMAL(38,5),
MaxRegBetween DECIMAL(38,5),
MinRegBetween DECIMAL(38,5),
MaxRegFuture DECIMAL(38,5),
MinRegFuture DECIMAL(38,5)
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
	,IIF(Mx3 = CandleCeiling,1,0) as	breakMx3
	,IIF(Mx5 = CandleCeiling,1,0) as	breakMx5
	,IIF(Mx8 = CandleCeiling,1,0) as	breakMx8
	,IIF(Mx13 = CandleCeiling,1,0) as	breakMx13
	,IIF(Mx34 = CandleCeiling,1,0) as	breakMx34
	,IIF(Mn3 = CandleFloor,1,0) as		breakMn3
	,IIF(Mn5 = CandleFloor,1,0) as		breakMn5
	,IIF(Mn8 = CandleFloor,1,0) as		breakMn8
	,IIF(Mn13 = CandleFloor,1,0) as		breakMn13
	,IIF(Mn34 = CandleFloor,1,0) as		breakMn34
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
	,breakMx3
	,breakMx5
	,breakMx8
	,breakMx13
	,breakMx34
	,breakMn3
	,breakMn5
	,breakMn8
	,breakMn13
	,breakMn34
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


INTO #BreakMaxMin -- اینجا همه دیتا رو آوردیم و اون آنتیل رو نامبر رو نذاشتیم 
FROM STP4 s4



DROP TABLE IF EXISTS #ResFin
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
	,(CandleFloor-[Low])/NULLIF([_PriceRange],0)		as [_FloorLowPrcnt]
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
SELECT try_convert(datetime,[Time]) AS [DateTime],* INTO #ResFin FROM STP4 s
where  RowNo <= @untilRowNo

create clustered index IX on #ResFin([DateTime])

--select * from #ResFin


---======================= Regression

--DECLARE
--	@sy DECIMAL(38,5),
--	@sx DECIMAL(38,5),
--	@sxx DECIMAL(38,5),
--	@sxy DECIMAL(38,5),
--	@syy DECIMAL(38,5),
--	@count DECIMAL(38,5),
--	@alpha DECIMAL(38,5),
--	@beta DECIMAL(38,5),
--	@cor DECIMAL(38,5)

--DECLARE @ismax BIT = 1


--;with stp1 as 
--(
--	SELECT RowNo,[Time],CandleCeiling-LAG(CandleCeiling)over(order by RowNo) DiffCeil,CandleFloor-LAG(CandleFloor) over(order by RowNo) DiffFloo
--	FROM #BreakMaxMin f
--	WHERE RowNo >= (select max(RowNo) from #BreakMaxMin) - 7
--)
--SELECT @ismax = IIF((SUM(DiffCeil)+SUM(DiffFloo))>0,0,1) FROM stp1


--DROP TABLE IF EXISTS #PreReg
--;WITH stp1 AS 
--	(
--		SELECT [time],ROW_NUMBER() OVER(ORDER BY [time]) AS x,IIF(@ismax = 1 , f.[high],f.[low]) AS y 
--		FROM #BreakMaxMin f
--		WHERE RowNo >= (select max(RowNo) from #BreakMaxMin) - 7
--	)
--SELECT * INTO #PreReg FROM stp1

--SELECT 
--	@sy = sum(y),
--	@sx = sum(x),
--	@sxx = sum(x*x),
--	@sxy = sum(x*y),
--	@syy = sum(y*y),
--	@count = Count(1)
--FROM #PreReg

--select @alpha = ((@sy*@sxx) - (@sx*@sxy))
--				/( (@count*@sxx) - (@sx*@sx) )
--	   ,@beta = ((@count*@sxy) - (@sx*@sy))
--				/( (@count*@sxx) - (@sx*@sx))
--	   ,@cor = ((@count*@sxy) - (@sx*@sy))
--				/SQRT( ((@count*@sxx)-(@sx*@sx)) * ((@count*@syy)-(@sy*@sy)))


----SELECT *,'ORG' AS typ 
----FROM #PreReg
----UNION ALL 
----SELECT DATEADD(HOUR,1,MAX([Time])) AS [Time],MAX(X)+1 AS x,@alpha+(@beta*(max(x)+1)) AS Y,'PRED' AS typ FROM #PreReg

--DECLARE @Prediction DECIMAL(38,5)
--		,@PredTime DATETIME
--SELECT @PredTime = DATEADD(HOUR,1,MAX([Time])),@Prediction = @alpha+(@beta*(max(x)+1))  FROM #PreReg



--=============== SIGNAL	
--exec Features
---========= برای سقف یابی و پوزیشن فروش
--Declare @ActiveAlgorithmPips int = 3
--declare @PivotFollowing int = 5
--Declare @StopLosPips int = -5
--Declare @TargetsPips int = 100
--Declare @Candles int = 20

-- ماکزیممها رو از ریزالت میکشه بیرون
-- از ماکزی تا دوتا ماکز بعد حمایت و مقاومت رو معتبر میدونیم و هر قیمتی بیاد توش ازش تاثیر میگیره
DROP TABLE IF EXISTS #MX
SELECT 
	RowNo
	,[DateTime]	
	,f.[High]
	,ABS(10000*(CandleCeiling-lag(CandleCeiling)over(order by [DateTime]))) as DiffPipCandleCeiling
INTO #MX
FROM #ResFin f WHERE mx=1 AND (F.CandleCeiling - MinFuture) > @PipRangeFromPivot



DROP TABLE IF EXISTS #MXSignal
select top 1
	*
	,M.[High]-(@ActiveAlgorithmPips*1.00000) AS SellTriggerPrice
	,M.[High]-(@StopLosPips*1.00000) AS StopLoss
	,M.[High]-(@TargetsPips*1.00000) AS TakeProfit
	,@Candles as ForwardCandles
	,'Sell' AS SignalType 
into #MXSignal
from #MX M
	where DiffPipCandleCeiling > 0
ORDER BY [DateTime] DESC 




---========= برای کف یابی و پوزیشن خرید

DROP TABLE IF EXISTS #MN
SELECT 
	RowNo
	,[DateTime]
	,f.[Low]
	,ABS(10000*(CandleFloor-lag(CandleFloor)over(order by [DateTime]))) as DiffPipCandleFloor
INTO #MN
FROM #ResFin f WHERE [Min]=1 AND (MaxFuture - F.CandleFloor) > @PipRangeFromPivot


DROP TABLE IF EXISTS #MNSignal
select top 1 
	*
	,M.[Low]+(@ActiveAlgorithmPips*1.00000) AS BuyTriggerPrice 
	,M.[Low]+(@StopLosPips*1.00000) AS StopLoss
	,M.[Low]+(@TargetsPips*1.00000) AS TakeProfit
	,@Candles as ForwardCandles
	,'Buy' AS SignalType 
into #MNSignal
from #MN M
	where DiffPipCandleFloor > 0
ORDER BY [DateTime] DESC 


--- RESULT
DROP TABLE IF EXISTS #Stp3
;WITH stp1 AS 
(
SELECT [DateTime],[High] as HighLow,SellTriggerPrice AS PendingPrice,StopLoss,TakeProfit,ForwardCandles,SignalType
	 FROM #MXSignal
UNION ALL
SELECT [DateTime],[Low],BuyTriggerPrice,StopLoss,TakeProfit,ForwardCandles,SignalType
	FROM #MNSignal
)
,stp2 as 
(
SELECT 
ROW_NUMBER() over(order by SignalType,[DateTime]) RN,*
--	,CASE
--		WHEN @ismax = 0 AND SignalType = 'Sell' AND (PendingPrice - @Prediction)*10000 between 0 and @ActiveAlgorithmPips THEN 1
--		WHEN @ismax = 1 AND SignalType = 'Buy' AND  (@Prediction - PendingPrice)*10000 between 0 and @ActiveAlgorithmPips THEN 1		
--	ELSE 0
--END AS ReggActivated
--,@Prediction AS ReggressionPred
,case 
	when SignalType = 'Sell' AND NOT EXISTS(select 1 from #BreakMaxMin r where /*R.RowNo <= (select max(RowNo) from #BreakMaxMin) - 7 هفتا کندل آخر رو در نظر نمیگیرم AND */ s.DateTime < r.[Time] AND (r.[High]-s.PendingPrice ) > 0.0050/*از ده پیپ بیشتر شکسته شده باشه این پیوت معتبر نیست*/ ) then 1
	when SignalType = 'Buy' AND NOT EXISTS(select 1 from #BreakMaxMin r where /*R.RowNo <= (select max(RowNo) from #BreakMaxMin) - 7 AND */ s.DateTime < r.[Time] AND (s.PendingPrice - r.[Low]) > 0.0050) then 1
	else 0 
	end 
as IsFresh
from stp1 s
)
,STP3 AS 
(select 
	[DateTime]
	,HighLow
	,IIF(IsFresh = 1,PendingPrice,0) as PendingPrice --,IIF(ReggActivated = 1,ReggressionPred,0) AS PendingPrice--,IIF(rn%2 > 0,0,PendingPrice) as PendingPrice	
	,StopLoss--,IIF(SignalType = 'Buy', ReggressionPred+(@StopLosPips*1.00000/10000),ReggressionPred-(@StopLosPips*1.00000/10000)) AS StopLoss
	,TakeProfit--,IIF(SignalType = 'Buy', ReggressionPred+(@TargetsPips*1.00000/10000),ReggressionPred-(@StopLosPips*1.00000/10000)) AS TakeProfit
	,ForwardCandles
	,SignalType
	--,ReggActivated
	--,ReggressionPred
	--,PendingPrice AS pppp
from stp2 s 	
)
select * into #Stp3 from STP3
  

DROP TABLE IF EXISTS #Stp4
SELECT
	s.[DateTime],s.HighLow,s.PendingPrice,s.StopLoss,s.TakeProfit,s.ForwardCandles,s.SignalType
	,Count(1) AS Cnt
INTO #Stp4
FROM #Stp3 S
	left JOIN #MX R 
			ON S.SignalType = 'Sell' AND ABS(S.PendingPrice - r.[High]) < 0.0020
	left JOIN #Mn N 		
			ON S.SignalType = 'Buy' AND ABS(S.PendingPrice - N.[Low]) <  0.0020
group by s.[DateTime],s.HighLow,s.PendingPrice,s.StopLoss,s.TakeProfit,s.ForwardCandles,s.SignalType


--select PivotToCurrentMaxDegree,PivotToCurrentMinDegree,PivotToPivotMaxDegree,PivotToPivotMinDegree from #BreakMaxMin


DROP TABLE IF EXISTS #stp5

SELECT 
	[DateTime],
	s.HighLow,
	s.PendingPrice + IIF(SignalType='Sell',@OppositeSignalPips,-1*@OppositeSignalPips) AS PendingPrice,
	s.PendingPrice + IIF(SignalType='Sell',@OppositeSignalPips,-1*@OppositeSignalPips) -- NewPendingPrice From Query Above
		+ IIF(SignalType='Sell',-1*@OppositeSignalSlPips,@OppositeSignalSlPips) AS StopLoss,
	s.PendingPrice + IIF(SignalType='Sell',@OppositeSignalPips,-1*@OppositeSignalPips) -- NewPendingPrice
		+ IIF(SignalType='Sell',@OppositeSignalTpPips,-1*@OppositeSignalTpPips) AS TakeProfit,
	s.ForwardCandles,
	IIF(SignalType='Sell','Buy','Sell') AS SignalType,	
	s.Cnt
	into #stp5
FROM #Stp4 s 
where s.Cnt > 1


DECLARE @GapAll decimal(38,5) = (select max(PendingPrice) - NULLIF(min(PendingPrice),0) from #Stp4)


--DECLARE @GapSell decimal(38,5) = (select max(PendingPrice) - min(PendingPrice) from #Stp4 where SignalType = 'Sell')
--DECLARE @GapBuy decimal(38,5) = (select max(PendingPrice) - min(PendingPrice) from #Stp4 where SignalType = 'Buy')

--print '@GapAll	:' + CAST(@GapAll	AS VARCHAR(50))
--print '@GapSell	:' + CAST(@GapSell	AS VARCHAR(50))
--print '@GapBuy	:' + CAST(@GapBuy	AS VARCHAR(50))

if(@isTest = 1)
begin

	SELECT @GapAll AS GapAll

	select * from #Stp4
	order by SignalType,[DateTime] desc 

	select * from #stp5
	order by SignalType,[DateTime] desc 


end


INSERT INTO #Stp4
(
	[DateTime],
	HighLow,
	PendingPrice,
	StopLoss,
	TakeProfit,
	ForwardCandles,
	SignalType,
	Cnt
)
select * from #stp5


if (1=0)--IF(@GapAll >= 0.005  or @GapAll IS NULL)  -- همه رو بیاره 
BEGIN
	;with stp1 as 
	(
		select 
			--s.[DateTime],s.HighLow,IIF(cnt>1,s.PendingPrice,0) AS PendingPrice,s.StopLoss,s.TakeProfit,s.ForwardCandles,s.SignalType
			--,CONCAT(SignalType,',',IIF(cnt>1,s.PendingPrice,0),',',StopLoss,',',TakeProfit)AS FullStr
			s.[DateTime],s.HighLow,s.PendingPrice,s.StopLoss,s.TakeProfit,s.ForwardCandles,s.SignalType
			,CONCAT(SignalType,',',s.PendingPrice,',',StopLoss,',',TakeProfit,','+format(s.[DateTime],'yyyy-MM-dd HH:mm:ss'))AS FullStr
		
		from #Stp4 s
	)
	SELECT @Candles AS ForwardCandles,STRING_AGG(FullStr,'_') AS Signals 
		,IIF(@GapAll > 0.005,1,0) AS GapAllIsValid
	FROM stp1
	RETURN
END

if(1 = 1) --IF(@GapAll < 0.005) -- فقط ریورسها رو بیاره
BEGIN
	;with stp1 as 
	(
		select 
			s.[DateTime],s.HighLow,s.PendingPrice,s.StopLoss,s.TakeProfit,s.ForwardCandles,s.SignalType
			,CONCAT(SignalType,',',s.PendingPrice,',',StopLoss,',',TakeProfit,','+format(s.[DateTime],'yyyy-MM-dd HH:mm:ss'))AS FullStr
		
		from #Stp5 s
	)
	SELECT @Candles AS ForwardCandles,STRING_AGG(FullStr,'_') AS Signals 
		,IIF(@GapAll > 0.005,1,0) AS GapAllIsValid
	FROM stp1
	RETURN
END



