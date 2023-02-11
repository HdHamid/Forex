CREATE VIEW [dbo].[Vw_CheckDataDateDiff]
as
with stp1 as 
(
	select *,lag([time]) over(order by [time]) LgTm from EURUSD_H1
)
,stp2 as 
(
	select *,DATEDIFF(DAY,LgTm,[time]) dy from stp1
)
select * from stp2 where dy > 3

