CREATE PROCEDURE Common.PivotFinder
	@Pvt pvt readonly 
AS

;WITH STP1 AS
(
	SELECT 
		*
		,MAX([High]) OVER(ORDER BY [time] ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING ) AS MaxOver
		,MIN([Low])  OVER(ORDER BY [time] ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING ) AS MinOver
	FROM @Pvt
)
SELECT [Time],[High],[Low]
	,IIF(MaxOver = [High], 1, 0) AS IsMax
	,IIF(MinOver = [Low],1 ,0) AS IsMin
FROM STP1


