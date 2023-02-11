CREATE PROCEDURE [Temp].[GetDataFromTestForexFund] 
as
drop table if exists Temp.ForexFund

select 
	CAST (f.[Column 7] as int) as Id
	,Time
	,[Cur ] as Cur
	,Event 
	,Actual
	,Forecast
	,Previous
into Temp.ForexFund
from Test..FundForex f
	where f.[Imp ] = ''


--- Time
update Temp.ForexFund 
set time = NULL 
where time = 'Tentative'

update Temp.ForexFund 
set time = NULL 
where len(time) <= 5


update Temp.ForexFund 
set time = substring([time],charindex(' ',[time])+1,len([time])) from Temp.ForexFund 
where time is not null 
-- Time






--- NULL
update Temp.ForexFund
set Actual = null 
where Actual = ''

update Temp.ForexFund
set Previous = null 
where Previous = ''


update Temp.ForexFund
set Forecast = null 
where Forecast = ''


update Temp.ForexFund
set Cur = null 
where Cur = ''

update Temp.ForexFund
set Event = null 
where Event = ''
---! NULL



--- NULL
update Temp.ForexFund
set Actual = replace(Actual,'"','') 


update Temp.ForexFund
set Previous = replace(Previous,'"','') 


update Temp.ForexFund
set Forecast = replace(Forecast,'"','') 


update Temp.ForexFund
set Cur = replace(Cur,'"','') 

update Temp.ForexFund
set Event = replace(Event,'"','') 

---! NULL



DROP TABLE IF EXISTS #STP1
;with stp1 as 
(
select 
	f.Id,
	f.Time,
	f.[Cur],
	f.Event,
	Previous,
	case
		when f.Previous like '%[%]%' then replace(f.Previous,'%','')
		when f.Previous like '%K' then  replace(f.Previous,'K','')
		when f.Previous like '%B' then  replace(f.Previous,'B','')
		when f.Previous like '%M' then  replace(f.Previous,'M','')
		when f.Previous like '%T' then  replace(f.Previous,'T','')
		else f.Previous
	end as PreviousProc	,
	f.Actual,	
	case
		when f.Actual like '%[%]%' then replace(f.Actual,'%','')
		when f.Actual like '%K' then	replace(f.Actual,'K','')
		when f.Actual like '%B' then	replace(f.Actual,'B','')
		when f.Actual like '%M' then	replace(f.Actual,'M','')
		when f.Actual like '%T' then	replace(f.Actual,'T','')
		else f.Actual
	end as ActualProc	,
	f.Forecast,
	case
		when f.Forecast like '%[%]%' then replace(f.Forecast,'%','')
		when f.Forecast like '%K' then    replace(f.Forecast,'K','')
		when f.Forecast like '%B' then    replace(f.Forecast,'B','')
		when f.Forecast like '%M' then    replace(f.Forecast,'M','')
		when f.Forecast like '%T' then    replace(f.Forecast,'T','')
		else f.Forecast
	end as ForecastProc	,
	replace(
			iif(
				CHARINDEX('(',[Event]) > 0,LEFT([Event],CHARINDEX('(',[Event])-1),[Event]		
			)
		,nchar(160),'')AS [EventCode] 
from Temp.ForexFund f
)
select 
	Id,
	Time,
	Cur,
	Event,
	Previous,
	TRY_CONVERT(DECIMAL(38,5),PreviousProc) AS PreviousProc,
	Actual,
	TRY_CONVERT(DECIMAL(38,5),ActualProc) AS ActualProc,
	Forecast,
	TRY_CONVERT(DECIMAL(38,5),ForecastProc) AS ForecastProc,
	EventCode
INTO #STP1
from stp1 



DROP TABLE IF EXISTS #STP2 
;WITH STP2 AS 
(
	SELECT 
	Id,
	Time,
	Cur,
	Event,
	case
		when f.Previous like '%[%]%' then   PreviousProc/100.00
		when f.Previous like '%K' then		PreviousProc*1000
		when f.Previous like '%B' then		PreviousProc*1000000000
		when f.Previous like '%M' then		PreviousProc*1000000
		when f.Previous like '%T' then		PreviousProc*1000000000000
		else f.PreviousProc
	end	
	AS Previous,	
	case
		when f.Actual like '%[%]%' then	 ActualProc/100.00
		when f.Actual like '%K' then	 ActualProc*1000
		when f.Actual like '%B' then	 ActualProc*1000000000
		when f.Actual like '%M' then	 ActualProc*1000000
		when f.Actual like '%T' then	 ActualProc*1000000000000
		else f.ActualProc
	end	AS Actual,
	Case
		when f.Forecast like '%[%]%' then  ForecastProc/100.00
		when f.Forecast like '%K' then     ForecastProc*1000
		when f.Forecast like '%B' then     ForecastProc*1000000000
		when f.Forecast like '%M' then     ForecastProc*1000000
		when f.Forecast like '%T' then     ForecastProc*1000000000000
		else f.ForecastProc
	end AS Forecast,
	EventCode
	FROM #STP1 F
)
SELECT *
	INTO #STP2 	
FROM STP2



--- FillDownDate
DROP TABLE IF EXISTS dbo.ForexFund 
;with stp3 as 
(
	select sum(iif(time is null,0,1)) OVER(ORDER BY Id) as TimegRP,*
	from #STP2
)
,stp2 as 
(
	SELECT FIRST_VALUE([time]) over(partition by TimegRP order by Id) as NewTime,* FROM stp3
)
select 
	Id,cast(NewTime as Date) as [Date],Cur,Event,Previous,Actual,Forecast,EventCode
	,CASE 
		when Event like '%(YOY)%' THEN 'YOY'
		when Event like '%(MOM)%' THEN 'MOM'
		when Event like '%(WOW)%' THEN 'WOW'
		when Event like '%(QOQ)%' THEN 'QOQ'
	END AS [Type]
into dbo.ForexFund 
from stp2
WHERE Event is not null 

CREATE CLUSTERED INDEX ix ON ForexFund (Id)

--select * from  ForexFund 
--where  Event like '%(%' and [Type] is null 

Update dbo.ForexFund 
 set cur = replace(trim(cur),nchar(160),'') 

Update dbo.ForexFund 
 set EventCode = replace(trim(EventCode),nchar(160),'')  









