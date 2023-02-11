CREATE procedure [Test].[Capital]	
as 

DECLARE @BALANCE DECIMAL(38,2) = 1000
DECLARE @CapitalRatioPlay DECIMAL(3,2) = 0.1
DECLARE @Leverage  DECIMAL(3,0) = 100

DECLARE @VolLot DECIMAL(38,2) = @Leverage*@CapitalRatioPlay*1000

drop table if exists #CheckResult
select * 
	INTO #CheckResult
from [dbo].[Vw_PbiDailyReport]

drop table if exists #ee
;WITH S AS 
(
SELECT null AS PivotDateTime,null AS FirstSignalDateTime,NULL as pip,null AS k,1000 AS Balance
UNION ALL 
select 
	PivotDateTime,FirstSignalDateTime,
	pip,
	pip*0.0001 AS k,
	(pip*0.0001)*@VolLot
from [dbo].[Vw_PbiDailyReport]
)
SELECT *,sum(Balance)over(order by PivotDateTime,FirstSignalDateTime ) as SumBalance into #ee FROM S
order by PivotDateTime,FirstSignalDateTime


drop table if exists #RecStart
select 
	ROW_NUMBER() over(order by PivotDateTime,FirstSignalDateTime) Rn,
	PivotDateTime,FirstSignalDateTime,
	pip,
	pip*0.0001 AS k
	into #RecStart
from [dbo].[Vw_PbiDailyReport]

declare @FirstDate datetime = (select dateadd(day,-1,min(PivotDateTime)) from #RecStart)

;with stp1 as
(
	SELECT cast(0 as bigint) as RN ,@FirstDate AS PivotDateTime
	,@FirstDate AS FirstSignalDateTime
	, cast(NULL as numeric) as pip,cast(null as decimal(38,5)) AS k
	,@BALANCE AS Balance 
	union all
	select r.Rn,r.PivotDateTime,r.FirstSignalDateTime
	,cast(r.Pip as numeric),cast(r.k as decimal(38,5))
	,Balance+cast(r.k*((s.Balance*@CapitalRatioPlay)*@Leverage) as decimal(38,2)) 
	from #RecStart r inner join stp1 s on s.RN = r.Rn - 1
)
select s.*,Frdt,FrYear,FrMonth,FrMonthName,SeqPersianYearMonth,@CapitalRatioPlay as CapitalRatioPlay from stp1 S
	INNER JOIN DimDate D ON D.Endt = FORMAT(FirstSignalDateTime,'yyyy-MM-dd')
option(maxrecursion 20000)
