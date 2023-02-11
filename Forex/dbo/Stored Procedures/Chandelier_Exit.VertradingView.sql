CREATE PROCEDURE [Chandelier_Exit.VertradingView]
AS
WITH STP1 AS 
(
	SELECT *,LAG([Close])OVER(ORDER BY [TIME]) AS LagClose FROM EURUSD_H1
)
,STP2 AS 
(
	SELECT 
		*,
		2*dbo.MathMax(s1.[high]-s1.[low],ABS([High]-LagClose),ABS([Low]-LagClose),DEFAULT,DEFAULT) AS ATR
	FROM STP1 s1
)
,STP3 AS
(
	SELECT 
		*
		,dbo.MathMax([close],[LagClose],DEFAULT,DEFAULT,DEFAULT) - ATR AS longStop
		,dbo.MathMin([close],[LagClose],DEFAULT,DEFAULT,DEFAULT) + ATR AS ShortStop
	FROM STP2 
)
,STP4 AS
(
	SELECT *,
		LAG(longStop)OVER(ORDER BY [Time]) AS longStopPrev,
		LAG(ShortStop)OVER(ORDER BY [Time]) AS shortStopPrev
	FROM STP3
),STP5 as
(
	SELECT * ,
		IIF(LagClose > longStopPrev,dbo.MathMax(longStop,longStopPrev,DEFAULT,DEFAULT,DEFAULT),longStop) AS longStop_,
		IIF(LagClose < shortStopPrev,dbo.MathMin(ShortStop,shortStopPrev,DEFAULT,DEFAULT,DEFAULT),ShortStop) AS ShortStop_
	FROM STP4
),STP6 AS 
(
	SELECT 
		*,
		CASE 
			WHEN [Close] > shortStopPrev THEN 1 
			WHEN [Close] < longStopPrev THEN -1 
			ELSE 1
		END AS Dir
	FROM STP5
)
,STP7 AS 
(
	SELECT *,LAG(Dir) OVER (ORDER BY [Time]) AS LagDir FROM STP6
)
SELECT *
	,CASE WHEN 	[Dir] = 1 AND [LagDir] = -1 THEN 'Buy'
		  WHEN 	[Dir] = -1 AND [LagDir] = 1 THEN 'Sell'
	 END AS Signal
FROM STP7
ORDER BY [Time] DESC 

/*
longStop = (useClose ? highest(close, length) : highest(length)) - atr
longStopPrev = nz(longStop[1], longStop) 
longStop := close[1] > longStopPrev ? max(longStop, longStopPrev) : longStop

shortStop = (useClose ? lowest(close, length) : lowest(length)) + atr
shortStopPrev = nz(shortStop[1], shortStop)
shortStop := close[1] < shortStopPrev ? min(shortStop, shortStopPrev) : shortStop

var int dir = 1
dir := close > shortStopPrev ? 1 : close < longStopPrev ? -1 : dir

buySignal = dir == 1 and dir[1] == -1

sellSignal = dir == -1 and dir[1] == 1
*/