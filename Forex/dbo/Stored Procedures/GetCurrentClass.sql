CREATE procedure [dbo].[GetCurrentClass]
	--@Window varchar(50) = '50'
AS 	
set nocount on

 
--declare   @ActiveAlgorithmPips decimal(38,5) = 0.01 -- چند پیپ بالا یا پایین پیوت پندینگ اوردر رو فعال کنه؟
-- ,@WindowFrom nvarchar(5) = '7'
-- ,@WindowTo nvarchar(5) = '13'
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

DECLARE @CoefForSlTp DECIMAL(38,5)

DROP TABLE IF EXISTS #PIVOT

DROP TABLE IF EXISTS #TBCUR
SELECT TOP 500  ROW_NUMBER()OVER(ORDER BY [Time]) AS RowNo
	,IIF([Open] > [Close] , [Open] , [Close] ) as CandleCeiling
	,IIF([Open] > [Close] , [Close] , [Open] ) as CandleFloor
	,[Time] ,[Open] ,[High] ,[Low]  ,[Close],Volume ,DateId ,RegDate
INTO #TBCUR FROM  Dbo.EURUSD_H1
ORDER BY [Time] DESC



	
DROP TABLE IF EXISTS #Intermediate
CREATE TABLE #Intermediate
(
xAxis INT,
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
xAxis
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
)
select 
	ROW_NUMBER()OVER(ORDER BY [Time]) AS xAxis
	,*															--@PivotFollowing
	,max([HIGH]) over(order by RowNo rows between 125 preceding and 125  following) as MaxBetween  
	,Min([LOW]) over(order by RowNo rows between 125  preceding and 125  following) as MinBetween 
	,max([HIGH]) over(order by RowNo rows between current row and 125  following) as MaxFuture
	,min([LOW]) over(order by RowNo rows between current row and 125  following) as MinFuture
from #TBCUR	



DROP TABLE IF EXISTS #PivotFinded
SELECT *
	,IIF([low] = MinBetween	,1,0)	AS PivotMin60
	,IIF([high] = MaxBetween	,1,0)   AS PivotMax60
INTO #PivotFinded FROM #Intermediate 



DROP TABLE if EXISTS #res0

;with stp1 as 
(
	SELECT 
		*
		,lag(PivotMax60) Over(order by [Time]) as LagPivMax
		,lag(PivotMin60) Over(order by [Time]) as LagPivMin	
	FROM #PivotFinded
	WHERE PivotMin60 = 1 OR PivotMax60 = 1
)
,stp2 as 
(
select 
	s.[Time],
	s.[open],
	s.[Close],
	s.[High],
	s.[Low],
	s.MaxBetween,
	s.MinBetween,
	S.PivotMax60,
	S.PivotMin60,
	S.Volume,
	SUM(IIF(LagPivMax=PivotMax60,0,1)) over(order by [Time]) AS GrpMax,
	SUM(IIF(LagPivMin=PivotMin60,0,1)) over(order by [Time]) AS GrpMin
	from stp1 s
)
SELECT 
	s.[Time],
	s.[open],
	s.[Close],
	s.[High],
	s.[Low],
	s.MaxBetween,
	s.MinBetween,
	S.PivotMax60,
	S.PivotMin60,
	S.Volume,
	s.GrpMax,
	s.GrpMin,
	MAX([High]) OVER(PARTITION BY GrpMax) as HighGrp,
	MIN([Low]) OVER(PARTITION BY GrpMin) as LowGrp
Into #res0
FROM stp2 s 



DROP TABLE IF EXISTS #res1
;with stp1 as 
(
SELECT 
	s.[Time],
	s.[open],
	s.[Close],
	s.[High],
	s.[Low],
	s.MaxBetween,
	s.MinBetween,
	S.PivotMax60,
	S.PivotMin60,
	S.Volume,
	GrpMax,
	GrpMin,
	IIF(HighGrp = [High] and PivotMax60 = 1, 1 , NULL) AS ISMaxGrp,
	IIF(LowGrp = [Low] and PivotMin60 = 1, 1 , NULL) AS ISMinGrp
FROM #res0 s 
)
SELECT 
	s.[Time],
	s.[open],
	s.[Close],
	s.[High],
	s.[Low],
	s.MaxBetween,
	s.MinBetween,
	S.PivotMax60,
	S.PivotMin60,
	S.Volume
INTO #res1
FROM stp1 S
	WHERE ISMaxGrp IS NOT NULL OR ISMinGrp IS NOT NULL
ORDER BY [Time]


DROP TABLE IF EXISTS #ResFin
;WITH STP1 AS 
(
	SELECT *,
		lAG([Time],1) OVER(ORDER BY [Time]) AS LagDte
	FROM #res1
)
SELECT 
	IIF(S.PivotMax60 = 1 , 'Max','Min') AS [Type],
	s.LagDte,
	s.[Time],	
	DATEDIFF(DAY,LagDte,[Time]) AS DteDiff	
INTO #ResFin
FROM STP1 S 

--delete #ResFin where DteDiff < 10


---DECLARE RANGE OF DATE

DECLARE
@DateFrom DATETIME = (select max([Time]) from #ResFin) --(select max(LagDte) from #ResFin)
,@DateTo DATETIME =  (select max([Time]) from Dbo.EURUSD_H1) --(select max([Time]) from #ResFin)
,@ID INT

DECLARE @Type varchar(5) = (select [type] from #ResFin where [Time] = @DateTo)


IF (SELECT COUNT(1) FROM Dbo.EURUSD_H1 WHERE [TIME] > (select max([Time]) from #ResFin)) <= 15  -- کمتر از سه روز ترندش  استیبل نشده که بررسی کنیم
BEGIN
	SET @DateFrom =(select max(LagDte) from #ResFin)
	SET @DateTo =  (select max([Time]) from #ResFin)
END 


--================= Get Candle Count AND DayCount

DECLARE @CandleCount INT = (SELECT COUNT(1) FROM  Dbo.EURUSD_H1 WHERE [Time] BETWEEN @DateFrom AND @DateTo)

DECLARE @DayCount int = DATEDIFF(day,@DateFrom,@DateTo) 


--================= Calc Regression 




DROP TABLE IF EXISTS #PIVOT

DROP TABLE IF EXISTS #TBCUR2
SELECT 
	 IIF([Open] > [Close] , [Open] , [Close] ) as CandleCeiling
	,IIF([Open] > [Close] , [Close] , [Open] ) as CandleFloor
	,[Time] ,[Open] ,[High] ,[Low]  ,[Close],Volume ,DateId ,RegDate	
INTO #TBCUR2 FROM  Dbo.EURUSD_H1
WHERE [Time] >= @DateFrom --AND @DateTo

DROP TABLE IF EXISTS #PIVOT
SELECT *,ROW_NUMBER()OVER(ORDER BY [Time]) AS xAxis
	INTO #PIVOT
FROM #TBCUR2

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



DROP TABLE IF EXISTS #PreReg
;WITH stp1 AS 
	(
		SELECT [time], xAxis AS x ,(f.CandleCeiling+f.CandleFloor)/2 AS y 
		FROM #PIVOT f
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
				/SQRT(abs(((@count*@sxx)-(@sx*@sx)) * ((@count*@syy)-(@sy*@sy))))


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
		FROM #Degr WHERE X = (SELECT MIN(X) FROM #Degr)

		SELECT @x2 = ScaledX,@y2 = ScaledY
		FROM #Degr WHERE X =(SELECT MAX(X) FROM #Degr)


		DECLARE @Degree decimal(38,2)
		SELECT @Degree = DEGREES(ATN2(@y2-@y1,@x2-@x1))


		

		DECLARE @MSE Decimal(38,5)
				,@MAE Decimal(38,5)
				,@DiffRegY Decimal(38,5)
				
		DECLARE @MaxX DECIMAL(38,2)
		select @MaxX = MAX(d.x) from #Degr d
		
		;WITH stp1 AS 
		(
		SELECT *,
			Power((Regg*1000)-(y*1000),2) AS MSE, -- عدد اعشاری ریزه به توان که میرسه 0 میشه 
			ABS(Regg-y) AS MAE,
			IIF( X BETWEEN @MaxX*0.05 AND @MaxX*0.95, ABS(Regg-y),null) AS DiffRegY
		FROM #Degr
		)
		,STP2 AS 
		(
			SELECT *,
			MAX(MSE) OVER() AS mxMSE,
			MIN(MSE) OVER() AS mnMSE,
			MAX(MAE) OVER() AS mxMAE,
			MIN(MAE) OVER() AS mnMAE			
			FROM stp1
		)
		,stp3 AS 
		(
			SELECT 
				*,
				(MSE-mnMSE)	/ NULLIF((mxMSE-mnMSE),0) AS MSEScaled,
				(MAE-mnMAE) / NULLIF((mxMAE-mnMAE),0) AS MAEScaled
			FROM STP2
		)
		SELECT 
			@MSE = AVG(MSEScaled) 
			,@MAE = AVG(MAEScaled)
			,@DiffRegY = MAX(DiffRegY)			
		FROM stp3

--select @Degree as Degree,@MSE as MSE,@MAE as MAE,@DiffRegY as DiffRegY,@cor as cor,@count as [count]

DECLARE 
@yBigger	 DECIMAL(38,5),
@yhatBigger	 DECIMAL(38,5),
@yEqual		 DECIMAL(38,5)

SELECT 
		@yBigger= (SUM(IIF(y>Regg,1,0))*1.00)/sum(1) 
		,@yhatBigger =(SUM(IIF(y<Regg,1,0))*1.00)/sum(1) 
		,@yEqual = (SUM(IIF(abs(y-Regg)<0.0001,1,0))*1.00)/sum(1) 
FROM #Degr WHERE [Time] BETWEEN @DateFrom AND @DateTo


--=============== FindNeighbors
DROP TABLE IF EXISTS #res


;with stp0 as 
(
select 	ID,Type,MinDte,MaxDte,Correlation,MSE,MAE,Degree,DayCount,MaxDiffRegY,yBigger,yhatBigger,yEqual	
from GroupsToReggression
union all 
select 
	0 as ID
	,@Type as Type
	,@DateFrom AS MinDte
	,@DateTo AS MaxDte
	,@cor AS Correlation 
	,@MSE AS MSE
	,@MAE AS MAE
	,@Degree AS Degree
	,@DayCount AS DayCount
	,@DiffRegY AS MaxDiffRegY
	,@yBigger AS yBigger
	,@yhatBigger AS yhatBigger
	,@yEqual AS yEqual	

)
,stp1 as 
(
select 
	 ID
	,Type
	,MinDte
	,MaxDte
	,Correlation
	,MSE
	,MAE
	,Degree
	,MaxDiffRegY
	,yBigger
	,yhatBigger
	,yEqual
	,CAST(DayCount AS DECIMAL(38,5)) AS DayCount 
	,min(Correlation) over() as MinCor
	,max(Correlation) over() as MaxCor
	,min(MSE) over() as MinMSE
	,max(MSE) over() as MaxMSE
	,min(MAE) over() as MinMAE
	,max(MAE) over() as MaxMAE
	,min(Degree) over() as MinDegree
	,max(Degree) over() as MaxDegree
	,min(CAST(DayCount AS DECIMAL(38,5))) over() as MinDayCount
	,max(CAST(DayCount AS DECIMAL(38,5))) over() as MaxDayCount
	,Min(MaxDiffRegY) OVER() as Min_MaxDiffRegY
	,MAX(MaxDiffRegY) OVER() as Max_MaxDiffRegY
	,Min(yBigger) OVER() as Min_yBigger
	,MAX(yBigger) OVER() as Max_yBigger
	,Min(yhatBigger) OVER() as Min_yhatBigger
	,MAX(yhatBigger) OVER() as Max_yhatBigger
	,Min(yEqual) OVER() as Min_yEqual
	,MAX(yEqual) OVER() as Max_yEqual
from stp0
),
stp2 as 
(
	select 
		 ID
		,Type
		,MinDte
		,MaxDte
		,(Correlation-MinCor)/(MaxCor-MinCor) AS Correlation
		,(MSE-MinMSE)/(MaxMSE-MinMSE) AS MSE
		,(MAE-MinMAE)/(MaxMAE-MinMAE) AS MAE
		,(Degree-MinDegree)/(MaxDegree-MinDegree) AS Degree
		,(DayCount-MinDayCount)/(MaxDayCount-MinDayCount) AS DayCount	
		,(MaxDiffRegY-Min_MaxDiffRegY)/(Max_MaxDiffRegY-Min_MaxDiffRegY) as MaxDiffRegY	
		,(yBigger-Min_yBigger)/(Max_yBigger-Min_yBigger) as MaxDiffyBigger	
		,(yhatBigger-Min_yhatBigger)/(Max_yhatBigger-Min_yhatBigger) as MaxDiffyhatBigger	
		,(yEqual-Min_yEqual)/(Max_yEqual-Min_yEqual) as MaxDiffyEqual	
	from stp1 
)
SELECT 
	r1.*,r2.ID as SecId
	,SQRT(SQUARE(R1.Correlation-R2.Correlation)*1.5
	--+SQUARE(r1.DayCount - r2.DayCount)*1
	--+SQUARE(r1.Degree-r2.Degree)
	+SQUARE(r1.MAE-r2.MAE)*1
	+SQUARE(r1.MSE-r2.MSE)*1
	--+SQUARE(r1.MaxDiffRegY-r2.MaxDiffRegY)	
	--+SQUARE(r1.MaxDiffyBigger-r2.MaxDiffyBigger)
	--+SQUARE(r1.MaxDiffyhatBigger-r2.MaxDiffyhatBigger)
	--+SQUARE(r1.MaxDiffyEqual-r2.MaxDiffyEqual)
	) AS Distance 
	into #res 
FROM stp2 r1 
	inner join stp2 r2 on r1.ID <> r2.ID AND R1.ID = 0

DECLARE @SECID INT 
SELECT TOP 1 @SECID = SecId FROM #res 
ORDER BY Distance

--select @SECID AS TrendID,@DateFrom as DateFrom,@DateTo as DateTo
--select *,@DateFrom,@DateTo,@DayCount from calc.KnnGroupsRes where ident = @SECID

print concat('TrendID @SECID = ', @SECID,',',format(@DateFrom,'yyyy/MM/dd HH:mm') ,',',format(@DateTo,'yyyy/MM/dd HH:mm'))

DECLARE @GrpAvg int 

select @GrpAvg = AVG(DayCount) from GroupsToReggression WHERE ID IN
(
	select Ident
	from calc.KnnGroupsRes 
	where ident = @SECID
)

select @SECID AS TrendID, GrpId AS ClassName,@CandleCount AS TrendCandles,@DayCount AS TrendDayCount 
,@GrpAvg as ClassAvgDayCount,@DateFrom AS DateFrom,@DateTo AS DateTo
from calc.KnnGroupsRes where ident = @SECID



