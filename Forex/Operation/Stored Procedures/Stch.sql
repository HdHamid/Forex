CREATE PROCEDURE Operation.Stch
as
with stp1 as 
(
	select [Time],StochasticRSI,StchSignal,IIF(StochasticRSI >= StchSignal,1,0) AS StcGrt from WeeklyFullFeature 
),
STP2 AS 
(	
	SELECT *,LAG(StcGrt) OVER(ORDER BY [Time]) AS LagStc FROM STP1 
)
SELECT *, IIF(StcGrt <>LagStc , 1 , 0 ) AS Signal FROM STP2
order by [time]