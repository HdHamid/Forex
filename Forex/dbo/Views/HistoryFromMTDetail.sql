


CREATE view [dbo].[HistoryFromMTDetail]
as 	
WITH S AS 
(
select DISTINCT
	Type
	,Volume
	,cast(sd.[Open Date Time] as date) as OpenDate
	,cast(sd.[Open Date Time] as datetime) as OpenDateTime
	,TRY_CONVERT(decimal(38,2),[Position PnL]) as [Position PnL]
	,LEFT(Comment,CHARINDEX('/',Comment) - 1) AS Comment
from [dbo].[HistoryExported] sd
)
SELECT *
,sum([Position PnL])over(order by OpenDateTime) as sumOver
,reverse(left(REVERSE(Comment),charindex('+',REVERSE(Comment))-1)) as Class
FROM S
