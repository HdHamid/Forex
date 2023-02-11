
CREATE Procedure [dbo].[FullFeatures]
AS 
set nocount on

DROP TABLE IF EXISTS #PIVOT

DROP TABLE IF EXISTS #TBCUR
SELECT ROW_NUMBER()OVER(ORDER BY cast([Time] as DateTime)) AS RowNo
	,IIF([Open] > [Close] , [Open] , [Close] ) as CandleCeiling
	,IIF([Open] > [Close] , [Close] , [Open] ) as CandleFloor
,* INTO #TBCUR FROM [dbo].[EURUSD_H1_History]

--ALTER TABLE [dbo].[EURUSD_H1]
--ADD DateId INT 

--Update w set DateId = d.id
--FROM  [dbo].[EURUSD_H1] W INNER JOIN dbo.DimDate D ON D.Endt = cast(W.Time as date)



declare @untilRowNo int = (select Max(RowNo) from  #TBCUR) - 23

DECLARE @DegreeScaler decimal(6,5) = 0.009803
--nullif((s2.CandleCeiling*0.00003/5.1),0) -- select 0.00003 / 5.1 = .00000588
--nullif((s2.CandleCeiling*0.05/5.1),0) -- select 0.05/5.1 = 0.009803



;with stp1 as 
(
	select *															--@PivotFollowing
	,max(CandleCeiling) over(order by RowNo rows between 23 preceding and 5 following) as MaxBetween  -- Bazeye 23 + 23 baraye shenasaee Price pivot MAX  
	,Min(CandleFloor) over(order by RowNo rows between 23 preceding and 5 following) as MinBetween 	-- Bazeye 23 + 23 baraye shenasaee Price pivot MIN  
	from #TBCUR	
) 
, stp2 as 
(
	select stp1.*,dt.Endt,iif(MaxBetween=CandleCeiling or RowNo = @untilRowNo,1,0) as MX ,iif(minBetween=CandleFloor or RowNo = @untilRowNo,1,0) as Min,dt.EnDay,dt.EnMonthName,dt.EnYear -- Shenasaee tarikhe PivotHa
	,iif(MaxBetween=High,1,0) as IsMXBecauseOfMaxBetween,iif(minBetween=High,1,0)IsMinBecauseOfMinBetween
	from stp1 
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


--=========================== VolLag
;WITH A AS 
(
	SELECT *,((volume*1.00) - lag(volume) over(order by RowNo))/nullif(lag(volume) over(order by RowNo),0) AS VolLag FROM 
	#PIVOT 

)
Update A set VolLagPercent = VolLag


--SELECT * FROM #PIVOT-- where mx = 1 
--order by DateID

--select * from #PIVOT
--order by dateid
--=================================== RSI 

--DECLARE @DegreeScaler decimal(6,5) = 0.009803

drop table if exists #tbl
Create table #tbl (Rn int,RowNo int,ClosePrc decimal(26,6),Vol decimal(26,6),Chng decimal(26,6))



insert into #tbl(rn,RowNo,ClosePrc,Vol,Chng)
select RowNo AS Rn,e.RowNo,e.[Close],e.Volume,e.[Close] - LAG(e.[Close]) over(Order by RowNo) Chngs
--sum(case when ClosePrc > 0 then ClosePrc else 0 end) over(order by NmdID,DteID Rows 14 Preceding)
from #TBCUR e

CREATE CLUSTERED INDEX IX ON #tbl (Rn)


drop table if exists #ee
create table #ee (Rn int,RowNo int,ClosePrc decimal(26,6),Vol Decimal(26,6),Chng decimal(26,6),GainAvg decimal(26,6),LossAvg decimal(26,6),Prmtr int)

declare @days int = 14 

declare @Q nvarchar(Max) = N';with a as (
select *, 
sum(case when Chng > 0 then Chng else 0 end) over(order by RowNo Rows '+cast(@days-1 as nvarchar(50))+' Preceding) / '+cast(@days as nvarchar(50))+'  as GainAvg,
sum(case when Chng < 0 then abs(Chng) else 0 end) over(order by RowNo Rows '+cast(@days-1 as nvarchar(50))+' Preceding) / '+cast(@days as nvarchar(50))+' as LossAvg 
from #tbl where rn <= '+cast(@days+1 as nvarchar(50))+'
Union all 
select t.* 
, (a.GainAvg * '+cast(@days-1 as nvarchar(50))+' + case when t.Chng > 0.0 then t.Chng else 0.0 end) / '+cast(@days as nvarchar(50))+'
, (a.LossAvg * '+cast(@days-1 as nvarchar(50))+' + case when t.Chng < 0.0 then abs(t.Chng) else 0.0 end) / '+cast(@days as nvarchar(50))+'
from #tbl t 
inner join a on t.Rn = a.Rn + 1 and t.Rn > '+cast(@days+1 as nvarchar(50))+')
select *,'+cast(@days as nvarchar(50))+' as Prmtr from a option (maxrecursion 0)'
insert into #ee(Rn,RowNo,ClosePrc,Vol,Chng,GainAvg,LossAvg,Prmtr)
exec (@Q)


set @days = 5 

set @Q  = N';with a as (
select *, 
sum(case when Chng > 0 then Chng else 0 end) over(order by RowNo Rows '+cast(@days-1 as nvarchar(50))+' Preceding) / '+cast(@days as nvarchar(50))+'  as GainAvg,
sum(case when Chng < 0 then abs(Chng) else 0 end) over(order by RowNo Rows '+cast(@days-1 as nvarchar(50))+' Preceding) / '+cast(@days as nvarchar(50))+' as LossAvg 
from #tbl where rn <= '+cast(@days+1 as nvarchar(50))+'
Union all 
select t.* 
, (a.GainAvg * '+cast(@days-1 as nvarchar(50))+' + case when t.Chng > 0 then t.Chng else 0 end) / '+cast(@days as nvarchar(50))+'
, (a.LossAvg * '+cast(@days-1 as nvarchar(50))+' + case when t.Chng < 0 then abs(t.Chng) else 0 end) / '+cast(@days as nvarchar(50))+'
from #tbl t 
inner join a on t.Rn = a.Rn + 1 and t.Rn > '+cast(@days+1 as nvarchar(50))+')
select *,'+cast(@days as nvarchar(50))+' as Prmtr  from a option (maxrecursion 0)'
insert into #ee(Rn,RowNo,ClosePrc,Vol,Chng,GainAvg,LossAvg,Prmtr)
exec (@Q)


DROP TABLE IF EXISTS #AfterRsi

;with Stp1 as 
(
select *
	,case when LossAvg = 0 then NULL else GainAvg/LossAvg end as RS
	,case when LossAvg = 0 then 100 else 100 - (100/(1+(GainAvg/LossAvg))) end RSI
from #ee
) 
select p.*,s.RSI as RSI14,s2.RSI as RSI5
INTO #AfterRsi
from Stp1 s 
	inner join #PIVOT p on p.RowNo = s.RowNo and s.Prmtr = 14
	inner join Stp1 s2 on p.RowNo = s2.RowNo and s2.Prmtr = 5


--select * from #AfterRsi p
--order by p.RowNo
--=========================== OBV

ALTER TABLE #AfterRsi
ADD ID INT 

;WITH a AS
(
	SELECT *,ROW_NUMBER() OVER(ORDER BY RowNo) as Rn1 FROM #AfterRsi
)
UPDATE A SET A.ID = RN1 FROM A

CREATE CLUSTERED INDEX IX ON #AfterRsi (ID)

drop table if exists #Obv
DECLARE @MinDate int = (select min(RowNo) from #AfterRsi)

;WITH Rcrsv as(
select t.*,Volume as OBV from #AfterRsi t where t.RowNo = @MinDate
Union ALL
select t.*,
case when t.[Close] = r.[Close] then r.OBV when t.[Close] > r.[Close] 
then r.OBV+t.Volume when t.[Close] < r.[Close] then r.OBV-t.Volume end 
from #AfterRsi t inner join Rcrsv r on r.ID+1 = t.iD
)
select * into #Obv from Rcrsv  option (maxrecursion 0)

--select * from #Obv
--order by RowNo


--================================ CCI

DROP TABLE IF EXISTS #TB
;with NewTbl as (select *,cast((((High+Low)+[Close])/(3)) as decimal(38,5)) TypPrc 
from #Obv f )
, ToCCI as (select *,AVG(TypPrc) over(Order by RowNo rows 13 preceding) AS [DaySMAofTP] from NewTbl)
select *,
(Abs([DaySMAofTP]-TypPrc)+Abs([DaySMAofTP]-LAG(TypPrc,13) over(Order by RowNo)) + Abs([DaySMAofTP]-LAG(TypPrc,12) over(Order by RowNo)) 
+ Abs([DaySMAofTP]-LAG(TypPrc,11) over(Order by RowNo)) + Abs([DaySMAofTP]-LAG(TypPrc,10) over(Order by RowNo)) + Abs([DaySMAofTP]-LAG(TypPrc,9) over(Order by RowNo)) 
+ Abs([DaySMAofTP]-LAG(TypPrc,8) over(Order by RowNo)) + Abs([DaySMAofTP]-LAG(TypPrc,7) over(Order by RowNo)) + Abs([DaySMAofTP]-LAG(TypPrc,6) over(Order by RowNo)) 
+ Abs([DaySMAofTP]-LAG(TypPrc,5) over(Order by RowNo)) + Abs([DaySMAofTP]-LAG(TypPrc,4) over(Order by RowNo)) + Abs([DaySMAofTP]-LAG(TypPrc,3) over(Order by RowNo)) 
+ Abs([DaySMAofTP]-LAG(TypPrc,2) over(Order by RowNo)) + Abs([DaySMAofTP]-LAG(TypPrc,1) over(Order by RowNo)))/ 14 as MeanDeviation
into #TB
from ToCCI


DROP TABLE IF EXISTS #CCI
select 
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
,RSI14
,RSI5
,ID
,OBV
,(TypPrc - [DaySMAofTP]) / (0.015*iif(MeanDeviation <> 0 ,MeanDeviation , NULL)) as [CCI] INTO #CCI  from #TB

--select * from #CCI
--Order by RowNo

----============================== ADX
--drop table if exists #r 
--drop table if exists #step1 
--drop table if exists #step2
--drop table if exists #step3
--drop table if exists #step4

--;with step1 as (select * 
--, [high] - [low] crmaxmin 
--, abs([high] - lag([close]) over(order by RowNo)) crmaxlgcls
--, abs([low] - lag([close]) over(order by RowNo)) crminlgcls
--, [high] - lag([high]) over(order by RowNo) as crmaxlagmax
--, lag([low]) over(order by RowNo) - [low] as lagmincrmin
--from #cci)
--SELECT * INTO #step1 FROM step1 

--;WITH step2 as (
--select id rn,RowNo , 
--case 
--when crmaxmin >= crmaxlgcls and crmaxmin >= crminlgcls then crmaxmin
--when crmaxlgcls >= crmaxmin and crmaxlgcls >= crminlgcls then crmaxlgcls
--when crminlgcls >= crmaxlgcls and crminlgcls >= crmaxmin then crminlgcls
--end tr, 
--case when crmaxlagmax > lagmincrmin then iif(crmaxlagmax>0,crmaxlagmax,0)
--else 0 end [+dm1],
--case when lagmincrmin > crmaxlagmax then iif(lagmincrmin>0,lagmincrmin,0)
--else 0 end [-dm1]
--from #step1)
--SELECT * INTO #step2 FROM step2 

--CREATE CLUSTERED INDEX IX ON #step2 (rn)

--;WITH step3 as (
--select *,
--sum(tr) over(order by RowNo rows 13 preceding) tr14,
--sum([+dm1]) over(order by RowNo rows 13 preceding) [+dm14],
--sum([-dm1]) over(order by RowNo rows 13 preceding) [-dm14]
--from #step2 where rn <= 15
--union all
--select s2.*,
--s3.tr14-(s3.tr14/14)+s2.tr  ,
--s3.[+dm14] - (s3.[+dm14]/14)+s2.[+dm1] , 
--s3.[-dm14] - (s3.[-dm14]/14)+s2.[-dm1] 
--from #step2 s2 inner join step3 s3 on s2.rn - 1 = s3.rn 
--where s2.rn > 15
--)
--SELECT * INTO #step3 FROM step3
--option (maxrecursion 0)

--CREATE CLUSTERED INDEX IX ON #step3 (rn)

--;with step4 as (
--select *
--,100 * [+dm14]/iif(tr14<> 0,tr14,null) as [+di14] 
--,100 * [-dm14]/iif(tr14<> 0,tr14,null) as [-di14] 
-- from #step3 
-- )
-- SELECT * INTO #step4 FROM step4

--CREATE CLUSTERED INDEX IX ON #step4 (rn)

--;with step5 as 
--(select *,
--abs([+di14]-[-di14]) as [di14diff],
--[+di14]+[-di14] as [di14sum],
--100 * (abs([+di14]-[-di14])/iif(([+di14]+[-di14])<> 0 ,([+di14]+[-di14]) , null) ) dx
--from #step4)
--select * into #r from step5 

-- Create clustered index IX on #r (rn)

--drop table if exists #preadx

--;with step6 as 
--(select *,
--avg(dx) over(order by rn rows 13 preceding) adx
--from #r where rn between 15 and 27
--union all 
--select r.* , ((s.adx * 13) + r.dx) / 14
--from #r r inner join step6 s on r.rn - 1 = s.rn
-- where r.rn > 27 
--)
--select RowNo,[+di14],[-di14],[adx] into #preadx
--from step6 option (maxrecursion 0)

--drop table if exists #adx

--select c.*,p.[+Di14],p.[-Di14],p.[ADX] into #adx from #cci c left join #preadx p on c.RowNo = p.RowNo

----select RowNo,[+di14],[-di14],[adx] from #adx


----select * from  #adx
----order by RowNo




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
	from #CCI A
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
	,RSI14
	,RSI5
	,ID
	,OBV
	,CCI
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


--SELECT * FROM #BreakMaxMin


--========================

DROP TABLE IF EXISTS #AfterIchi 
DROP TABLE IF EXISTS #Ichi 


; With Ichi1 as (select RowNo,[Close] as ClosePrc
,Max([High]) over(Order by RowNo rows 8 preceding)Hihgest9,MIN([Low]) over(Order by RowNo rows 8 preceding)Lowest9
,Max([High]) over(Order by RowNo rows 25 preceding)Hihgest26,MIN([Low]) over(Order by RowNo rows 25 preceding)Lowest26
,Max([High]) over(Order by RowNo rows 51 preceding)Hihgest52,MIN([Low]) over(Order by RowNo rows 51 preceding)Lowest52
from #BreakMaxMin)
,Ichi2 as (select *
,(Hihgest9+Lowest9)/2 as [Tenkan-sen]
,(Hihgest26+Lowest26)/2 as [Kijun-sen]
from Ichi1)
select RowNo,[ClosePrc],[Tenkan-sen],[Kijun-sen]
,([Tenkan-sen]+[Kijun-sen]) / 2 as [Senkou Span A] 
,(Hihgest52+Lowest52) / 2 as [Senkou Span B]
,LEAD(ClosePrc,26) over(order by RowNo) [Chinkou Span] 
into #Ichi
from Ichi2

select b.*,i.[Kijun-sen],i.[Chinkou Span],i.[Senkou Span A],i.[Senkou Span B],i.[Tenkan-sen] INTO #AfterIchi from #BreakMaxMin b Left join #Ichi i on b.RowNo = i.RowNo


-- =========================== EMA , SMA 
--DECLARE @DegreeScaler decimal(6,5) = 0.009803
DROP TABLE IF EXISTS #SmaEma
DROP TABLE IF EXISTS #SmaEma1
DROP TABLE IF EXISTS #SmaEma2


SELECT *
	,CAST(AVG(([High]+[Low]+(2*[Close]))/4) OVER(ORDER BY RowNo ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS DECIMAL(38,5)) AS SMA
	,Cast(NULL AS DECIMAL(38,5)) AS EMA
	,Cast(NULL AS DECIMAL(38,5)) AS DiffSmaEmaOverClosePrcnt
	,Cast(NULL AS bit) AS IsSmaOveEma
	,Cast(NULL AS DECIMAL(6,4)) AS SmaDegree
	,Cast(NULL AS DECIMAL(6,4)) AS EmaDegree
INTO #SmaEma
FROM #BreakMaxMin 

declare @P decimal(38,5),@daysForEma decimal(38,5) = 50
set @p = (2 / (@daysForEma + 1))

;with stp1 as 
(
SELECT *
	,CAST(AVG(([High]+[Low]+(2*[Close]))/4) OVER(ORDER BY RowNo ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS DECIMAL(38,5)) AS SMAForEMA
FROM #BreakMaxMin 
)
select * into #SmaEma2 from stp1

create clustered index ix on #SmaEma2(RowNo)

;with Rcrsv as(
select t.*,SMAForEMA as EMA from #SmaEma2 t where RowNo = @daysForEma
Union ALL
select t.*,cast((((t.[High]+t.[Low]+(2*t.[Close]))/4)*@P) + r.EMA *(1-@p) as Decimal(38,5))
from #SmaEma2 t inner join Rcrsv r on t.RowNo = r.RowNo+1
)
select * into #SmaEma1 from Rcrsv  option (maxrecursion 0)

Update e set e.EMA = e1.EMA 
			,e.DiffSmaEmaOverClosePrcnt = ABS(e.SMA - e1.EMA)/E.[Close]
			,e.IsSmaOveEma = IIF(e.SMA > e1.EMA , 1 , 0)
FROM #SmaEma E INNER JOIN #SmaEma1 E1 ON E.RowNo = E1.RowNo

;WITH Stp1 as 
(
	SELECT *
	,LAG(SMA,13) OVER (ORDER BY RowNo) AS LgSma 
	,LAG(EMA,13) OVER (ORDER BY RowNo) AS LgEma
	FROM #SmaEma
) 
UPDATE S 
SET 
	EmaDegree =  DEGREES(ATN2((EMA-LgEma)/(EMA*@DegreeScaler),13))
	,SmaDegree = DEGREES(ATN2((Sma -LgSma )/(Sma *@DegreeScaler),13)) 
FROM Stp1 S 

--SELECT * FROM #SmaEma
--order by rowno
--=====================  Price Def -- 	Japanese Candle Patterns

DROP TABLE IF EXISTS ##ResFin
;WITH stp1 AS
(
SELECT *
	,IIF(a.[Open] > a.[Close] , 1 , 0 ) as IsRed
	,IIF(a.[Open] < a.[Close] , 1 , 0 ) as IsGreen
	,(a.[High]-a.[Low])			as [_PriceRange]	
	,(a.[High]-a.[Low])/nullif(a.[Close],0) as PriceRangeWidthPrcnt
	,(a.[close]+a.[open]) / 2 as MiddleBodyPrice
	,(a.[high]+a.[Low]) / 2 as MiddleFullPrice
	,a.ClosePriceDiffLgMax/nullif(a.lgMax,0) AS ResistantDistancePrcnt
	,a.ClosePriceDiffLgMin/nullif(a.LgMin,0) AS SupportDistancePrcnt
	,a.CandleCeiling - a.CandleFloor AS FloorToCieling
	FROM #SmaEma a
)
, stp2 as 
(
SELECT *
	,(CandleCeiling - CandleFloor) / nullif([Close],0) as CandleBodyRangeWidthPrcnt --- اندازه بدنه کندل 
	,(ABS([close]-[open])/nullif([_PriceRange],0))		as [_CloseOpenPrcnt]
	,([High]-CandleCeiling)/nullif([_PriceRange],0)		as [_HighCielingPrcnt]
	,(CandleFloor-[Low])/nullif([_PriceRange],0)			as [_FloorLowPrcnt]
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
	--,lag(FloorLowPrcnt) over(order by RowNo) as OneFloorLowPrcnt
	--,lag(HighCielingPrcnt) over(order by RowNo) as OneHighCielingPrcnt
	--,lag(CloseOpenPrcnt) over(order by RowNo) as OneCloseOpenPrcnt
	--,lag(MiddleBodyPrice) over(order by RowNo) as OneMiddleBodyPrice


	--,lag(IsRed,2) over(order by RowNo) as	  TwoLagIsRed
	--,lag(IsGreen,2) over(order by RowNo) as TwoLagIsGreen
	--,lag(CandleCeiling,2) over(order by RowNo) as TwoLagCandleCeiling
	--,lag(CandleFloor,2) over(order by RowNo) as TwoLagCandleFloor
	--,lag([High],2) over(order by RowNo) as TwoLagHigh
	--,lag([low],2) over(order by RowNo) as TwoLagLow
	--,lag(CandleBodyRangeWidthPrcnt,2) over(order by RowNo) as TwoCandleBodyRangeWidthPrcnt
	--,lag(FloorLowPrcnt,2) over(order by RowNo) as TwoFloorLowPrcnt
	--,lag(HighCielingPrcnt,2) over(order by RowNo) as TwoHighCielingPrcnt
	--,lag(CloseOpenPrcnt,2) over(order by RowNo) as TwoCloseOpenPrcnt
	--,lag(MiddleBodyPrice,2) over(order by RowNo) as TwoMiddleBodyPrice
from stp2
)
, STP4 AS 
(
select * 
	--,IIF(CandleBodyRangeWidthPrcnt <= 0.00005,1,0) AS DOJI
	--,IIF(
	--CandleBodyRangeWidthPrcnt <= 0.00005 AND OneLagIsRed = 1 AND OneLagCandleFloor > CandleCeiling 
	--AND OneLagLow > CandleCeiling
	--,1
	--,0) AS DOJI_Bullish
	--,IIF(
	--CandleBodyRangeWidthPrcnt <= 0.00005 AND OneLagIsGreen = 1 AND OneLagCandleCeiling < CandleFloor
	--AND OneLagHigh < CandleFloor
	--,1
	--,0) AS DOJI_Bearish

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









--=============== BackTest
--exec Features
---========= برای سقف یابی و پوزیشن فروش
Declare @ActiveAlgorithmPips int = 3 -- چند پیپ از ماکز یا مین پیوت پندینگ اوردر رو بذاره
declare @PivotFollowing int = 5 -- از چند کندل به بعد فعال شه
Declare @StopLosPips int = -5 -- استاپ لاس چند پیپ بالاتر از ماکز یا مین پیوت باشد
Declare @TargetsPips int = 100
Declare @Candles int = 20

-- ماکزیممها رو از ریزالتن میکشه بیرون
-- از ماکزی تا دوتا ماکز بعد حمایت و مقاومت رو معتبر میدونیم و هر قیمتی بیاد توش ازش تاثیر میگیره
DROP TABLE IF EXISTS #MX
SELECT 
	RowNo
	,[DateTime]
	,DATEADD(HOUR,@PivotFollowing+1,[DateTime]) AS FromDate -- با بالا هماهنگه که پیوت رو بین 23 تا قبل و 5 تا بعد گرفته اینم از 6 تا بعدی دنبال موقعیت میگرده
	,LEAD([DateTime],2,GETDATE()+100) OVER(ORDER BY [DateTime]) AS Todate -- تا دو پیوت بعدی هنوز فرش بحساب میاد
	,f.[High]
INTO #MX
FROM ##ResFin f WHERE mx=1 


---- هر قیمتی تو این بازه به 3 پیپ یا کمتر نزدیک به ماکزیممها بشه سیگناله
--SELECT m.*,F.[High]*10000 as Fhigh,M.[High]*10000 as Mhigh, ABS(F.[High]*10000-M.[High]*10000)
--FROM ##ResFin F 
--INNER JOIN #MX M ON F.[DateTime] BETWEEN M.FromDate AND M.Todate
--WHERE ABS(F.[High]*10000-M.[High]*10000)<3 --pip


-- محل اصلی الگوریتم
-- همون بالاییه فقط
-- اولین سیگنال هر روز رو میگیریم و اون رو در نظر میگیریم 
DROP TABLE IF EXISTS #MySignals
;WITH STP1 AS 
(
	SELECT M.DateTime AS PivotDateTime,M.High as PivotHigh
	,f.RowNo,F.DateTime as FirstSignalDateTime,F.[TIME],F.[Close],F.[High],F.CCI,F.Endt,ROW_NUMBER()OVER(PARTITION BY F.ENDT ORDER BY F.[TIME]) RN
	,M.[High]-(@ActiveAlgorithmPips*1.00000/10000) AS SellTriggerPrice

	--SellTriggerPrice - Stoploss (عدد استاپلاس منفیه اینجا منها درسته)
	--,(M.[High]-(@ActiveAlgorithmPips*1.00000/10000))-(@StopLosPips*1.00000/10000) AS StopLoss
	

	-- Max Price Pivote + Stoploss (عدد استاپلاس منفیه اینجا منها درسته)
	,M.[High]-(@StopLosPips*1.00000/10000) AS StopLoss


	FROM ##ResFin F 
	INNER JOIN #MX M ON F.[DateTime] BETWEEN M.FromDate AND M.Todate
	WHERE M.[High]*10000-F.[High]*10000 BETWEEN 0 AND @ActiveAlgorithmPips --pip

)
SELECT * into #MySignals FROM STP1 
	where rn = 1
	

--ORDER BY [DateTime] DESC 

--select * from #MySignals
--ORDER BY [DateTime] DESC 


DROP TABLE IF EXISTS #MySignals2
select 
	m.*
	,f.[Close] as FClose
	,SellTriggerPrice*10000-f.[Close]*10000 as Diff -- تعداد پیپ بییست کندل جلوتر و قیمتی که سیگنال شده 
	,f.[DateTime] as CandlesLaterDateTime 
into #MySignals2
from #MySignals m inner join ##ResFin f on f.RowNo = m.RowNo+@Candles 
-- به تعداد 
--@Candles 
--جلوتر بره ببینه چی شده 



-- حالا چک میکنیم ببینیم با حد ضرر 2 پیپ و حد سود 10 پیپ چی میشده تو این بازه 20 کندل
DROP TABLE IF EXISTS #CheckResult
select 
	m.*
	,f.[Close] as FClose
	,SellTriggerPrice*10000-f.[Close]*10000 as Diff
	
	,StopLoss*10000-f.[High]*10000 as vsStoploss -- باید با تعداد پیپ استاپلاس مقایسه کنیم ببینیم زده یا نه
	-- بعبارتی اگر استاپلاس را 5 پیپ گذاشته باشیم باید این عدد از منفی 5 بزرگتر باشد

	,f.[DateTime] as FDateTime 
	,f.RowNo AS RowNoSeries
	,f.[Low] as LowPriceSeries
into #CheckResult
from #MySignals m inner join ##ResFin f on f.RowNo between m.RowNo+1 and m.RowNo+@Candles


-- برای چک کردن اینکه در کندلهای بعد از سیگنال 
-- آیا سل استاپ یا سل لیمیت اصلا فعال میشده یا نه
delete s
from #MySignals2 s
where							-- اوردر پندینگ فروش وقت فعال میشه که قیمت اون رو رو به پایین قطع کرده باشه دیگه وگرنه اصلا فعال نمیشه
	not exists (select 1 from #CheckResult c where SellTriggerPrice > LowPriceSeries and s.RowNo = c.RowNo)


-- حد ضرر 10 پیپ 
-- 238 معامله
Drop table if exists ##CheckResult 

select *,(t.StopLoss - SellTriggerPrice)*-10000 as Pip,'StopLoss' as OprType,'MaxPvt' as TradeType 
into ##CheckResult
	--count(1)*@StopLosPips -- -2380
from #MySignals2 t where exists (select 1 from #CheckResult c where vsStoploss <= @StopLosPips and c.RowNo = t.RowNo)
	and not exists (select 1 from #CheckResult c where Diff >=@TargetsPips and c.RowNo = t.RowNo)


-- اونهایی که حد سود رو زدن حد ضرر هم زدن ولی حد ضرر اول خورده پس با ضرر خروج میزنن
-- 30 معامله
DROP TABLE IF EXISTS #Common
;WITH StopLoss as 
(select RowNo,min(c.FDateTime) as StopLossMinDateTime from #CheckResult c where vsStoploss <= @StopLosPips 
	group by RowNo)
, Tgt as
(select RowNo,min(c.FDateTime) as StopTrgtMinDateTime from #CheckResult c where Diff >= @TargetsPips
	group by RowNo)

select t.*,s.StopLossMinDateTime,g.StopTrgtMinDateTime
	into #Common
from #MySignals2 t 
	inner join StopLoss s on s.RowNo = t.RowNo
	inner join Tgt g on g.RowNo = t.RowNo
--where s.StopLossMinDateTime<g.StopTrgtMinDateTime




-- حد سود تا 20 کندل بعد 50 پیپ
-- 64 معامله
insert into ##CheckResult
select *,@TargetsPips,'Target' as OprType,'MaxPvt' as TradeType
	--count(1)*@TargetsPips -- -3200
from #MySignals2 t where exists (select 1 from #CheckResult c where Diff >=@TargetsPips and c.RowNo = t.RowNo)
and not exists (select 1 from #Common c where c.RowNo = t.RowNo and c.StopLossMinDateTime<c.StopTrgtMinDateTime) -- در حدضرر زودتر خورده ها نیست



-- 30 معامله
insert into ##CheckResult
select *,(t.StopLoss - t.SellTriggerPrice)*-10000,'StopLoss' as OprType,'MaxPvt' as TradeType
	--count(1)*@StopLosPips -- -300
from #MySignals2 t where exists (select 1 from #CheckResult c where Diff >=@TargetsPips and c.RowNo = t.RowNo)
and exists (select 1 from #Common c where c.RowNo = t.RowNo and c.StopLossMinDateTime<c.StopTrgtMinDateTime) -- در حد ضرر زودتر خورده ها هست



-- هر کدوم بالا رخ نداد یعنی همون 20 امین کندل ببند
-- یعنی نه حد ضرر رو زدن تو این 20 تا نه حد سود 
-- رو کندل 20 میبندیم بره 
-- 104 معامله
insert into ##CheckResult
select * ,diff,'Between' as OprType,'MaxPvt' as TradeType
	--sum(t.Diff) -- 1845.50000 pip
	from #MySignals2 t where not exists (select 1 from #CheckResult c where vsStoploss <= @StopLosPips and c.RowNo = t.RowNo)
	and not exists (select 1 from #CheckResult c where Diff >=@TargetsPips and c.RowNo = t.RowNo)


--select (1845.50000 +3200)-300-2380   --= 2456 سود
--select 2365.50000*1000 -- 2365500 دلار سود 


--select 104+64 + 30+238 --=== 436



---========= برای کف یابی و پوزیشن خرید

DROP TABLE IF EXISTS #MN
SELECT 
	RowNo
	,[DateTime]
	,DATEADD(HOUR,@PivotFollowing+1,[DateTime]) AS FromDate
	,LEAD([DateTime],2,GETDATE()+100) OVER(ORDER BY [DateTime]) AS Todate
	,f.[Low]
INTO #MN
FROM ##ResFin f WHERE [Min]=1 


--SELECT m.*,F.[Low]*10000 as Fhigh,M.[Low]*10000 as Mhigh, ABS(F.[Low]*10000-M.[Low]*10000)
--FROM ##ResFin F 
--INNER JOIN #MN M ON F.[DateTime] BETWEEN M.FromDate AND M.Todate
--WHERE ABS(F.[Low]*10000-M.[Low]*10000)<3 --pip




DROP TABLE IF EXISTS #MyMinSignals0
;WITH STP1 AS 
(
	SELECT M.DateTime AS PivotDateTime,M.[Low] as PivotLow
	,f.RowNo,F.DateTime as FirstSignalDateTime,F.[TIME],F.[Close],F.[Low],F.CCI,F.Endt,ROW_NUMBER()OVER(PARTITION BY F.ENDT ORDER BY F.[TIME]) RN

	,M.[Low]+(@ActiveAlgorithmPips*1.00000/10000) AS BuyTriggerPrice
	
	--SellTriggerPrice - Stoploss (عدد استاپلاس منفیه اینجا بعلاوه درسته)
	--,(M.[Low]+(@ActiveAlgorithmPips*1.00000/10000))+(@StopLosPips*1.00000/10000) AS StopLoss


	,M.[Low]+(@StopLosPips*1.00000/10000) AS StopLoss

	FROM ##ResFin F 
	INNER JOIN #MN M ON F.[DateTime] BETWEEN M.FromDate AND M.Todate
	WHERE ABS(F.[Low]*10000-M.[Low]*10000) < @ActiveAlgorithmPips--pip
	
)
SELECT * into #MyMinSignals0 FROM STP1 
	where rn = 1


--select * from #MyMinSignals0
--ORDER BY [DateTime] DESC 



DROP TABLE IF EXISTS #MyMinSignals
select m.*
	,f.[Close] as FClose
	,f.[Close]*10000-BuyTriggerPrice*10000 as Diff
	,f.[DateTime] as CandlesLaterDateTime 
into #MyMinSignals
from #MyMinSignals0 m inner join ##ResFin f on f.RowNo = m.RowNo+@Candles


-- حالا چک میکنیم ببینیم با حد ضرر 2 پیپ و حد سود 10 پیپ چی میشده تو این بازه 20 کندل
DROP TABLE IF EXISTS #CheckMnResult
select 
	m.*
	,f.[Close] as FClose
	,f.[Close]*10000-BuyTriggerPrice*10000 as Diff
	,f.Low*10000 - BuyTriggerPrice*10000   as vsStoploss
	-- باید با تعداد پیپ استاپلاس مقایسه کنیم ببینیم زده یا نه
	-- بعبارتی اگر استاپلاس را 5 پیپ گذاشته باشیم باید این عدد از منفی 5 بزرگتر باشد

	,f.[DateTime] as FDateTime 
	,f.RowNo AS RowNoSeries
	,f.[High] as HighPriceSeries
into #CheckMnResult
from #MyMinSignals0 m inner join ##ResFin f on f.RowNo between m.RowNo+1 and m.RowNo+@Candles


-- برای چک کردن اینکه در کندلهای بعد از سیگنال 
-- آیا بای استاپ یا بای لیمیت اصلا فعال میشده یا نه
delete s
from #MyMinSignals s
where 
	not exists (select 1 from #CheckMnResult c where BuyTriggerPrice < HighPriceSeries and s.RowNo = c.RowNo)


-- حد ضرر 10 پیپ 
-- 78 معامله
insert into ##CheckResult
select *,(t.StopLoss - t.BuyTriggerPrice) * 10000,'StopLoss' as OprType,'MinPvt' as TradeType
	--count(1)*@StopLosPips -- -2770
from #MyMinSignals t where exists (select 1 from #CheckMnResult c where vsStoploss <= @StopLosPips and c.RowNo = t.RowNo)
			and not exists (select 1 from #CheckMnResult c where Diff >=@TargetsPips and c.RowNo = t.RowNo)

-- اونهایی که حد سود رو زدن حد ضرر هم زدن ولی حد ضرر اول خورده پس با ضرر خروج میزنن
-- 30 معامله
DROP TABLE IF EXISTS #CommonMn
;WITH StopLoss as 
(select RowNo,min(c.FDateTime) as StopLossMinDateTime from #CheckMnResult c where vsStoploss <= @StopLosPips 
	group by RowNo)
, Tgt as
(select RowNo,min(c.FDateTime) as StopTrgtMinDateTime from #CheckMnResult c where Diff >= @TargetsPips
	group by RowNo)

select t.*,s.StopLossMinDateTime,g.StopTrgtMinDateTime
	into #CommonMn
from #MyMinSignals t 
	inner join StopLoss s on s.RowNo = t.RowNo
	inner join Tgt g on g.RowNo = t.RowNo
--where s.StopLossMinDateTime<g.StopTrgtMinDateTime




-- حد سود تا 20 کندل بعد 50 پیپ
-- 63 معامله
insert into ##CheckResult
select *,@TargetsPips ,'Target' as OprType,'MinPvt' as TradeType
	--count(1)*@TargetsPips -- 3200
from #MyMinSignals t where exists (select 1 from #CheckMnResult c where Diff >=@TargetsPips and c.RowNo = t.RowNo)
and not exists (select 1 from #CommonMn c where c.RowNo = t.RowNo and c.StopLossMinDateTime<c.StopTrgtMinDateTime) -- در حدضرر زودتر خورده ها نیست



-- 30 معامله
insert into ##CheckResult
select *,(t.StopLoss - t.BuyTriggerPrice) * 10000,'StopLoss' as OprType,'MinPvt' as TradeType
	--count(1)*@StopLosPips -- -220
from #MyMinSignals t where exists (select 1 from #CheckMnResult c where Diff >=@TargetsPips and c.RowNo = t.RowNo)
and exists (select 1 from #CommonMn c where c.RowNo = t.RowNo and c.StopLossMinDateTime<c.StopTrgtMinDateTime) --حد ضرر زودتر خورده


-- هر کدوم بالا رخ نداد یعنی همون 20 امین کندل ببند
-- یعنی نه حد ضرر رو زدن تو این 20 تا نه حد سود 
-- رو کندل 20 میبندیم بره 
-- 95 معامله

insert into ##CheckResult
select * ,Diff,'Between' as OprType,'MinPvt' as TradeType
	--sum(Diff) -- 1390.20000 pip
	from #MyMinSignals t where not exists (select 1 from #CheckMnResult c where vsStoploss <= @StopLosPips and c.RowNo = t.RowNo)
	and not exists (select 1 from #CheckMnResult c where Diff >=@TargetsPips and c.RowNo = t.RowNo)

