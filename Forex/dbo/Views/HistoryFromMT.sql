
CREATE View [dbo].[HistoryFromMT]
as 
select 
	isnull(IIF(TRY_CONVERT(decimal(38,2),[Position PnL]) > 0,'Prof_','Loss_'),'TOTAL') as Category
	,count(1) as Cnt
	,sum(TRY_CONVERT(decimal(38,2),[Position PnL])) AS SumProfit
	,max(TRY_CONVERT(decimal(38,2),[Position PnL])) as MaxPnL
	,min(TRY_CONVERT(decimal(38,2),[Position PnL])) as minPnL
	,avg(TRY_CONVERT(decimal(38,2),[Position PnL])) as avgPnL
	from [dbo].[HistoryExported]
group by rollup(IIF(TRY_CONVERT(decimal(38,2),[Position PnL]) > 0,'Prof_','Loss_'))
