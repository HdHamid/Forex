CREATE view [dbo].[Vw_EURUSD_M15]
as
select 
	cast([DATE]+' '+[Time] as DateTime) AS [Time],
	cast([OPEN] as Decimal(38,5)) as [OPEN],
	cast([High]  as Decimal(38,5)) as [High],
	cast([Low]  as Decimal(38,5)) as [Low],
	cast([Close]  as Decimal(38,5)) as [Close],
	cast(Vol as decimal(38,0)) as Volume,
	cast(format(cast([DATE] as date),'yyyyMMdd') as int) as DateId
from [dbo].[EURUSD_M15]

