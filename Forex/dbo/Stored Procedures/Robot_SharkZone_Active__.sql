
--exec [dbo].[Robot_SharkZone_Active] @isTest = 1
CREATE Procedure [dbo].[Robot_SharkZone_Active__]
  @ActiveAlgorithmPips decimal(38,5) = 0.01 -- چند پیپ بالا یا پایین پیوت پندینگ اوردر رو فعال کنه؟
 ,@WindowFrom nvarchar(5) = '7'
 ,@WindowTo nvarchar(5) = '23'
 ,@PipRangeFromPivot decimal(38,5) = 0.05 -- بعد از هر پیوت که شناخته تا چندتا بالاترش رفته؟ به پارامتر کندلهای بعدیش ویندو تو دقت کن که 5 گذاشته باشی خوب 30 پیپ مسخرس بعبارتی خواستم قدرت پیوت رو بسنجم
 ,@StopLosPips decimal(38,5) = -0.5-- استاپ لاس چند پیپ بالا یا پایین ماکز یا مین پیوت باشه
 ,@TargetsPips decimal(38,5) = 0.5
 ,@Candles int = 50 -- چنتا کندل جلوتر اگز حد سود و ضرر اتفاق نیوفتاد ببنده
 ,@RegWindow int = 5 -- رگرشن
 ,@OppositeSignalPips decimal(38,5) = 0.02 -- 30 pips
 ,@OppositeSignalSlPips decimal(38,5) = 0.1 -- 30 pips nesbat be pending asli na opposite
 ,@OppositeSignalTpPips decimal(38,5) = 0.15 -- 300 pips pips nesbat be pending asli na opposite
 ,@isTest bit = 0
 ,@FreshPivotChecker decimal(38,5) = 0.05 
AS 
set nocount on


if((select count(1) from EURUSD_H1)> 500)
begin
	;with stp1 as 
	(
		select ROW_NUMBER() over(order by time desc) rn ,* from EURUSD_H1
	)
	delete stp1 where rn > 500
end

--declare   @ActiveAlgorithmPips decimal(38,5) = 0.01 -- چند پیپ بالا یا پایین پیوت پندینگ اوردر رو فعال کنه؟
-- ,@WindowFrom nvarchar(5) = '7'
-- ,@WindowTo nvarchar(5) = '13'
-- ,@PipRangeFromPivot decimal(38,5) = 0.05 -- بعد از هر پیوت که شناخته تا چندتا بالاترش رفته؟ به پارامتر کندلهای بعدیش ویندو تو دقت کن که 5 گذاشته باشی خوب 30 پیپ مسخرس بعبارتی خواستم قدرت پیوت رو بسنجم
-- ,@StopLosPips decimal(38,5) = -2-- استاپ لاس چند پیپ بالا یا پایین ماکز یا مین پیوت باشه
-- ,@TargetsPips decimal(38,5) = 0.5 
-- ,@Candles int = 40 -- چنتا کندل جلوتر اگز حد سود و ضرر اتفاق نیوفتاد ببنده
-- ,@RegWindow int = 5 -- رگرشن
-- ,@OppositeSignalPips decimal(38,5) = 0.02 -- 30 pips
-- ,@OppositeSignalSlPips decimal(38,5) = 0.1 -- 30 pips nesbat be pending asli na opposite
-- ,@OppositeSignalTpPips decimal(38,5) = 0.15 -- 300 pips pips nesbat be pending asli na opposite
-- ,@isTest bit = 0
-- ,@FreshPivotChecker decimal(38,5) = 0.05 


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
	,@FreshPivotChecker		= (MAX([High])-MIN([Low]))*@FreshPivotChecker
FROM #TBCUR

--SELECT 
--@ActiveAlgorithmPips		AS 	ActiveAlgorithmPips		
--,@PipRangeFromPivot			AS 	PipRangeFromPivot		
--,@StopLosPips				AS	StopLosPips			
--,@TargetsPips				AS	TargetsPips			
--,@OppositeSignalPips		AS	OppositeSignalPips	
--,@OppositeSignalSlPips		AS	OppositeSignalSlPips
--,@OppositeSignalTpPips		AS	OppositeSignalTpPips
--,@FreshPivotChecker			AS FreshPivotChecker

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
, CAST(NULL AS DECIMAL(6,4)) AS VolLagPercent
INTO #PIVOT 
from stp2 S

--select * from #PIVOT
--order by rowno


--============================BreakMaxMin

DROP TABLE IF EXISTS #ResFin
SELECT try_convert(datetime,[Time]) AS [DateTime],* INTO #ResFin FROM #PIVOT s
where  RowNo <= @untilRowNo

create clustered index IX on #ResFin([DateTime])

--select * from #ResFin


---======================= Regression

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

DECLARE @ismax BIT = 1


;with stp1 as 
(
	SELECT RowNo,[Time],CandleCeiling-LAG(CandleCeiling)over(order by RowNo) DiffCeil,CandleFloor-LAG(CandleFloor) over(order by RowNo) DiffFloo
	FROM #PIVOT f
	WHERE RowNo >= (select max(RowNo) from #PIVOT) - 7
)
SELECT @ismax = IIF((SUM(DiffCeil)+SUM(DiffFloo))>0,0,1) FROM stp1


DROP TABLE IF EXISTS #PreReg
;WITH stp1 AS 
	(
		SELECT [time],ROW_NUMBER() OVER(ORDER BY [time]) AS x,IIF(@ismax = 1 , f.[high],f.[low]) AS y 
		FROM #PIVOT f
		--WHERE RowNo >= (select max(RowNo) from #PIVOT) - 7
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


--SELECT *,'ORG' AS typ 
--FROM #PreReg
--UNION ALL 
--SELECT DATEADD(HOUR,1,MAX([Time])) AS [Time],MAX(X)+1 AS x,@alpha+(@beta*(max(x)+1)) AS Y,'PRED' AS typ FROM #PreReg

DECLARE @Prediction DECIMAL(38,5)
		,@PredTime DATETIME
SELECT @PredTime = DATEADD(HOUR,1,MAX([Time])),@Prediction = @alpha+(@beta*(max(x)+1))  FROM #PreReg



DROP TABLE IF EXISTS #Degr
;WITH STP1 AS 
(
	SELECT R.Time,CAST(R.x AS DECIMAL(38,5)) AS x,R.y,@alpha+(@beta*x) as Regg
	FROM #PreReg R
),
STP2 AS 
(
SELECT *,
	MAX(Y) OVER() AS mxY,
	MIN(Y) OVER() AS mnY,
	MAX(X) OVER() AS mxX,
	MIN(X) OVER() AS mnX
FROM STP1
)
,STP3 as 
(
SELECT *,
	(y-mnY)/(mxY-mnY) AS ScaledY,
	(X-mnX)/(mxX-mnX) AS ScaledX
FROM STP2
)
SELECT *
	into #Degr
FROM STP3

DECLARE 
	@x1 decimal(38,5),
	@y1 decimal(38,5),
	@x2 decimal(38,5),
	@y2 decimal(38,5)

SELECT @x1 = ScaledX,@y1 = ScaledY
FROM #Degr WHERE X = 1

SELECT @x2 = ScaledX,@y2 = ScaledY
FROM #Degr WHERE X =(SELECT MAX(X) FROM #Degr)


DECLARE @Degree decimal(38,2)
SELECT @Degree = DEGREES(ATN2(@y2-@y1,@x2-@x1))


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
	when SignalType = 'Sell' AND NOT EXISTS(select 1 from #PIVOT r 
			where /*R.RowNo <= (select max(RowNo) from #PIVOT) - 7 هفتا کندل آخر رو در نظر نمیگیرم AND */ 
			s.DateTime < r.[Time] AND (r.[High]-s.PendingPrice ) > abs(@FreshPivotChecker)/*از ده پیپ بیشتر شکسته شده باشه این پیوت معتبر نیست*/ ) 
			then 1
	when SignalType = 'Buy' AND NOT EXISTS(select 1 from #PIVOT r 
			where /*R.RowNo <= (select max(RowNo) from #PIVOT) - 7 AND */ 
			s.DateTime < r.[Time] AND (s.PendingPrice - r.[Low]) > abs(@FreshPivotChecker)) then 1
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


--select PivotToCurrentMaxDegree,PivotToCurrentMinDegree,PivotToPivotMaxDegree,PivotToPivotMinDegree from #PIVOT



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
--where s.Cnt > 1


DECLARE @GapAll decimal(38,5) = (select  NULLIF(max(PendingPrice),0) - NULLIF(min(PendingPrice),0) from #Stp4)




--DECLARE @GapSell decimal(38,5) = (select max(PendingPrice) - min(PendingPrice) from #Stp4 where SignalType = 'Sell')
--DECLARE @GapBuy decimal(38,5) = (select max(PendingPrice) - min(PendingPrice) from #Stp4 where SignalType = 'Buy')

--print '@GapAll	:' + CAST(@GapAll	AS VARCHAR(50))
--print '@GapSell	:' + CAST(@GapSell	AS VARCHAR(50))
--print '@GapBuy	:' + CAST(@GapBuy	AS VARCHAR(50))

if(@isTest = 1)
begin

	SELECT @GapAll AS GapAll,@Degree as Degree

	select * from #Stp4
	order by SignalType,[DateTime] desc 

	select * from #stp5
	order by SignalType,[DateTime] desc 


end


--if(ISNULL(@GapAll,0) < @TargetsPips/3)
--BEGIN
--	print IIF(@GapAll is null,'#Stp4 Is Empty, 
--			','@GapAll: '+cast(@GapAll as varchar(50))+' is lower than @TargetsPips: '+cast(@TargetsPips/3 as varchar(50))
--			)
--	return
--END

--INSERT INTO #Stp4
--(
--	[DateTime],
--	HighLow,
--	PendingPrice,
--	StopLoss,
--	TakeProfit,
--	ForwardCandles,
--	SignalType,
--	Cnt
--)
--select * from #stp5


IF (@Degree < -15)
	BEGIN 
		DELETE #Stp4 WHERE SignalType = 'Buy'
		DELETE #Stp5 WHERE SignalType = 'Buy'
	END

ELSE IF(@Degree > 15)
	BEGIN 
		DELETE #Stp4 WHERE SignalType = 'Sell'
		DELETE #Stp5 WHERE SignalType = 'Sell'
	END

	



if (@Degree <= 15 AND @Degree >= -15)--IF(@GapAll >= 0.005  or @GapAll IS NULL)  -- همه رو بیاره 
BEGIN
	;with stp1 as 
	(
		select 
			--s.[DateTime],s.HighLow,IIF(cnt>1,s.PendingPrice,0) AS PendingPrice,s.StopLoss,s.TakeProfit,s.ForwardCandles,s.SignalType
			--,CONCAT(SignalType,',',IIF(cnt>1,s.PendingPrice,0),',',StopLoss,',',TakeProfit)AS FullStr
			s.[DateTime],s.HighLow,s.PendingPrice,s.StopLoss,s.TakeProfit,s.ForwardCandles,s.SignalType
			,CONCAT(SignalType,',',s.PendingPrice,',',StopLoss,',',TakeProfit,','+format(s.[DateTime],'yyyy-MM-dd HH:mm:ss'),'+',@Candles)AS FullStr
		
		from #Stp4 s
	)
	SELECT @Candles AS ForwardCandles,STRING_AGG(FullStr,'_') AS Signals 
		,IIF(@GapAll > 0.005,1,0) AS GapAllIsValid
	FROM stp1
	RETURN
END

ELSE 
BEGIN
	;with stp1 as 
	(
		select 
			s.[DateTime],s.HighLow,s.PendingPrice,s.StopLoss,s.TakeProfit,s.ForwardCandles,s.SignalType
			,CONCAT(SignalType,',',s.PendingPrice,',',StopLoss,',',TakeProfit,','+format(s.[DateTime],'yyyy-MM-dd HH:mm:ss'),'+',@Candles)AS FullStr
		
		from #Stp5 s
	)
	SELECT @Candles AS ForwardCandles,STRING_AGG(FullStr,'_') AS Signals 
		,IIF(@GapAll > 0.005,1,0) AS GapAllIsValid
	FROM stp1
	RETURN
END



