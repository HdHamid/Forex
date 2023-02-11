
CREATE PROCEDURE [Calc].[FeatureEnginiering]
AS

;WITH STP1 AS 
(
	SELECT GroupsToReggID
		,(SUM(IIF(y>Regg,1,0))*1.00)/sum(1) AS yBigger
		,(SUM(IIF(y<Regg,1,0))*1.00)/sum(1) AS yhatBigger
		,(SUM(IIF(abs(y-Regg)<0.0001,1,0))*1.00)/sum(1) AS yEqual
	FROM Regression
	GROUP BY GroupsToReggID
)
UPDATE g 
SET 
	g.yBigger =		s1.yBigger		,
	g.yhatBigger =	s1.yhatBigger	,
	g.yEqual =		s1.yEqual
FROM STP1 S1 
	INNER JOIN GroupsToReggression G ON S1.GroupsToReggID = G.ID

SELECT * FROM GroupsToReggression

--SELECT *	
--FROM  Regression r
--	inner join GroupsToReggression g ON R.GroupsToReggID = G.ID

--select * from GroupsToReggression

