CREATE PROCEDURE [dbo].[FundProcess]
as 

DROP TABLE IF EXISTS #set
select * into #set from ForexFund where stars = 3 

drop table if exists #dimdate
select * into #dimdate from DimDate d where exists (select 1 from #set f where f.Date = d.Endt and f.Actual is not null)

drop table if exists #res
select d.Endt,a.Cur,a.EventCode,isnull([Type],'') as [Type] into #res from  #dimdate d inner join 
	(select Cur,EventCode,[Type],min(Date) as MinDte from #set f where f.Actual is not null group by EventCode,[Type],Cur) as A on d.Endt between a.MinDte and '2022-12-26'
	

drop table if exists #res2
select r.Endt,r.EventCode,r.Type,r.Cur,f.Actual,f.Forecast,f.Previous
	,sum(iif(f.Id is not null,1,0)) over(partition by r.Cur,r.EventCode,r.[Type] order by r.Endt) as Grp
	,iif(f.Id is not null,1,0) as IsORG
into #res2
from #res r
	left join #set f on f.EventCode = r.EventCode and f.Date = r.Endt and isnull(f.[Type],'') = r.[Type] and r.Cur = f.Cur

drop table if exists #TargetLead01
select 
	Endt	
	,EventCode	
	,Type	
	,Cur	
	,Actual	
	,Forecast	
	,Previous	
	,iif(IsORG = 1 , Grp-1,Grp) AS Grp	
	,IsORG
into #TargetLead01
 from #res2
WHERE EventCode = 'Fed Interest Rate Decision'

drop table if exists #TargetLead
select * 
	,LAST_VALUE(Actual) over(partition by Cur,EventCode,[Type],Grp order by Endt ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) as    FutureActualInterestRate
into #TargetLead
from #TargetLead01


drop table if exists #FundFillDown
select r.Cur,r.Endt,r.EventCode,r.Type,r.IsORG
	,FIRST_VALUE(r.Actual) over(partition by   r.Cur,r.EventCode,r.[Type],r.Grp order by r.Endt) as LastActual
	,FIRST_VALUE(r.Forecast) over(partition by r.Cur,r.EventCode,r.[Type],r.Grp order by r.Endt) as LastForecast 
	,FIRST_VALUE(r.Previous) over(partition by r.Cur,r.EventCode,r.[Type],r.Grp order by r.Endt) as LastPrevious 
	,FutureActualInterestRate
into #FundFillDown
from #res2 r 
	left join #TargetLead l on l.Endt = r.Endt 


select d.EnYear,d.EnMonth,d.EnMonthName,f.* from #FundFillDown f inner join DimDate d on d.Endt = f.Endt 

	

select *,1-(nullif(LastPrevious,0)/nullif(LastActual,0)) from #FundFillDown where Cur = 'USD' and Endt = '2021-05-12' and EventCode = 'Fed Interest Rate Decision' 

select * from #FundFillDown where EventCode = 'Fed Interest Rate Decision' 
and Endt = '2018-11-14'

select * from ForexFund where EventCode = 'Fed Interest Rate Decision' 
and Date = '2018-11-14'  

select * from #FundFillDown where EventCode = 'Fed Interest Rate Decision' 
order by Endt



--SELECT max(Endt) FROM #FundFillDown



--declare @Col nvarchar(max) = (select Stuff(((select distinct ',['+EventCode+']' 
--from #FundFillDown
--for xml path(''),type).value('.','Nvarchar(Max)')),1,1,''))

--declare @SQL nvarchar(max) = N'select Endt,'+@Col+'
--into ##res1
--From 
--(select EventCode,Endt,LastActual 
--from #FundFillDown) UP 
--pivot (sum(LastActual) for EventCode in ('+@Col+')) as v
--'
--exec (@SQL)


--set @SQL  = N'select Endt,'+@Col+'
--From 
--(select EventCode,Endt,LastForecast 
--from #FundFillDown) UP 
--pivot (sum(LastForecast) for EventCode in ('+@Col+')) as v
--'
--exec (@SQL)
	
	

--set @SQL  = N'select Endt,'+@Col+'
--From 
--(select EventCode,Endt,LastPrevious 
--from #FundFillDown) UP 
--pivot (sum(LastPrevious) for EventCode in ('+@Col+')) as v
--'
--exec (@SQL)
	
	

