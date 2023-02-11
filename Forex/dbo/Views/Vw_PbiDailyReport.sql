



CREATE view [dbo].[Vw_PbiDailyReport]
as
with stp1 as 
(
	select ROW_NUMBER() over(order by PivotDateTime,FirstSignalDateTime) as Rn,FrYear,FrMonth,FrMonthName,SeqPersianYearMonth,Frdt,Pip 
	,PivotDateTime,FirstSignalDateTime
	from CheckResult r inner join DimDate d on d.Endt = r.Endt 
	where Pip < 0
)
select  FrYear,FrMonth,FrMonthName,SeqPersianYearMonth,Frdt
,iif(pip<0 and Rn%20 = 0,0,pip ) as Pip
--,Pip
,0.05 as StopLosTrailed
,PivotDateTime,FirstSignalDateTime from stp1
UNION ALL 
select FrYear,FrMonth,FrMonthName,SeqPersianYearMonth,Frdt
,Pip
,0.05 as StopLosTrailed
,PivotDateTime,FirstSignalDateTime
from CheckResult r inner join DimDate d on d.Endt = r.Endt 
where Pip >= 0
--order by FrYear,FrMonth,FrMonthName,SeqPersianYearMonth
