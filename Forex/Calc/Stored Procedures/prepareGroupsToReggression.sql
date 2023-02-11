CREATE PROCEDURE [Calc].[prepareGroupsToReggression]
as 
DROP TABLE IF EXISTS #PivotFinded
;with stp1 as 
(
	select *
		,min([low]) over(order by [time] rows between 125 preceding and 125 following) as Min60
		,max([high])  over(order by [time] rows between 125 preceding and 125 following) as Max60
	from EURUSD_H1
)
SELECT *
	,IIF([low] = Min60	,1,0)	AS PivotMin60
	,IIF([high] = Max60	,1,0)   AS PivotMax60
INTO #PivotFinded FROM stp1 


DROP TABLE if EXISTS #res0

;with stp1 as 
(
	SELECT 
		*
		,lag(PivotMax60) Over(order by [Time]) as LagPivMax
		,lag(PivotMin60) Over(order by [Time]) as LagPivMin	
	FROM #PivotFinded
	WHERE PivotMin60 = 1 OR PivotMax60 = 1
)
,stp2 as 
(
select 
	s.[Time],
	s.[open],
	s.[Close],
	s.[High],
	s.[Low],
	s.Max60,
	s.Min60,
	S.PivotMax60,
	S.PivotMin60,
	S.Volume,
	SUM(IIF(LagPivMax=PivotMax60,0,1)) over(order by [Time]) AS GrpMax,
	SUM(IIF(LagPivMin=PivotMin60,0,1)) over(order by [Time]) AS GrpMin
	from stp1 s
)
SELECT 
	s.[Time],
	s.[open],
	s.[Close],
	s.[High],
	s.[Low],
	s.Max60,
	s.Min60,
	S.PivotMax60,
	S.PivotMin60,
	S.Volume,
	s.GrpMax,
	s.GrpMin,
	MAX([High]) OVER(PARTITION BY GrpMax) as HighGrp,
	MIN([Low]) OVER(PARTITION BY GrpMin) as LowGrp
Into #res0
FROM stp2 s 


DROP TABLE IF EXISTS #res1
;with stp1 as 
(
SELECT 
	s.[Time],
	s.[open],
	s.[Close],
	s.[High],
	s.[Low],
	s.Max60,
	s.Min60,
	S.PivotMax60,
	S.PivotMin60,
	S.Volume,
	GrpMax,
	GrpMin,
	IIF(HighGrp = [High] and PivotMax60 = 1, 1 , NULL) AS ISMaxGrp,
	IIF(LowGrp = [Low] and PivotMin60 = 1, 1 , NULL) AS ISMinGrp
FROM #res0 s 
)
SELECT 
	s.[Time],
	s.[open],
	s.[Close],
	s.[High],
	s.[Low],
	s.Max60,
	s.Min60,
	S.PivotMax60,
	S.PivotMin60,
	S.Volume
INTO #res1
FROM stp1 S
	WHERE ISMaxGrp IS NOT NULL OR ISMinGrp IS NOT NULL
ORDER BY [Time]


TRUNCATE TABLE GroupsToReggression
;WITH STP1 AS 
(
	SELECT *,
		lAG([Time],1,(select min([time]) from EURUSD_H1)) OVER(ORDER BY [Time]) AS LagDte
	FROM #res1
)
INSERT INTO GroupsToReggression
(
	Type,MinDte,MaxDte,DayCount
)
SELECT 
	IIF(S.PivotMax60 = 1 , 'Max','Min') AS [Type],
	s.LagDte,
	s.[Time],	
	DATEDIFF(DAY,LagDte,[Time]) AS DteDiff	
FROM STP1 S 


DELETE from GroupsToReggression where DayCount <= 10
 





