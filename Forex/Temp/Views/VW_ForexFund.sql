
CREATE view [Temp].[VW_ForexFund]
as
select 
	f.Id,
	f.Time,
	f.[Cur],
	f.Event,
	f.Previous,
	f.Actual,	
	f.Forecast,
	replace(
			iif(
				CHARINDEX('(',[Event]) > 0,LEFT([Event],CHARINDEX('(',[Event])-1),[Event]		
			)
		,nchar(160),'')AS [EventCode] 
from Temp.ForexFund f

