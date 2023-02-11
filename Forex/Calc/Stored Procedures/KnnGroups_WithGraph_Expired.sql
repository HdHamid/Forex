CREATE PROCEDURE [Calc].[KnnGroups_WithGraph_Expired] 
as 

DROP TABLE IF EXISTS #res

;with stp1 as 
(
select 
	 ID
	,Type
	,MinDte
	,MaxDte
	,Correlation
	,MSE
	,MAE
	,Degree
	,MaxDiffRegY
	,yBigger
	,yhatBigger
	,yEqual
	,CAST(DayCount AS DECIMAL(38,5)) AS DayCount 
	,min(Correlation) over() as MinCor
	,max(Correlation) over() as MaxCor
	,min(MSE) over() as MinMSE
	,max(MSE) over() as MaxMSE
	,min(MAE) over() as MinMAE
	,max(MAE) over() as MaxMAE
	,min(Degree) over() as MinDegree
	,max(Degree) over() as MaxDegree
	,min(CAST(DayCount AS DECIMAL(38,5))) over() as MinDayCount
	,max(CAST(DayCount AS DECIMAL(38,5))) over() as MaxDayCount
	,Min(MaxDiffRegY) OVER() as Min_MaxDiffRegY
	,MAX(MaxDiffRegY) OVER() as Max_MaxDiffRegY
	,Min(yBigger) OVER() as Min_yBigger
	,MAX(yBigger) OVER() as Max_yBigger
	,Min(yhatBigger) OVER() as Min_yhatBigger
	,MAX(yhatBigger) OVER() as Max_yhatBigger
	,Min(yEqual) OVER() as Min_yEqual
	,MAX(yEqual) OVER() as Max_yEqual
from GroupsToReggression
),
stp2 as 
(
	select 
		 ID
		,Type
		,MinDte
		,MaxDte
		,(Correlation-MinCor)/(MaxCor-MinCor) AS Correlation
		,(MSE-MinMSE)/(MaxMSE-MinMSE) AS MSE
		,(MAE-MinMAE)/(MaxMAE-MinMAE) AS MAE
		,(Degree-MinDegree)/(MaxDegree-MinDegree) AS Degree
		,(DayCount-MinDayCount)/(MaxDayCount-MinDayCount) AS DayCount	
		,(MaxDiffRegY-Min_MaxDiffRegY)/(Max_MaxDiffRegY-Min_MaxDiffRegY) as MaxDiffRegY	
		,(yBigger-Min_yBigger)/(Max_yBigger-Min_yBigger) as MaxDiffyBigger	
		,(yhatBigger-Min_yhatBigger)/(Max_yhatBigger-Min_yhatBigger) as MaxDiffyhatBigger	
		,(yEqual-Min_yEqual)/(Max_yEqual-Min_yEqual) as MaxDiffyEqual	
	from stp1 
)
SELECT 
	r1.*,r2.ID as SecId
	,SQRT(SQUARE(R1.Correlation-R2.Correlation)*1.5
	--+SQUARE(r1.DayCount - r2.DayCount)*1
	--+SQUARE(r1.Degree-r2.Degree)
	--+SQUARE(r1.MAE-r2.MAE)*1
	--+SQUARE(r1.MSE-r2.MSE)*1
	--+SQUARE(r1.MaxDiffRegY-r2.MaxDiffRegY)	
	--+SQUARE(r1.MaxDiffyBigger-r2.MaxDiffyBigger)
	--+SQUARE(r1.MaxDiffyhatBigger-r2.MaxDiffyhatBigger)
	--+SQUARE(r1.MaxDiffyEqual-r2.MaxDiffyEqual)
	) AS Distance 
	into #res 
FROM stp2 r1 
	inner join stp2 r2 on r1.ID <> r2.ID


DECLARE @Perecentile DECIMAL(38,5)
select TOP 1 @Perecentile = PERCENTILE_CONT(0.04) WITHIN GROUP(ORDER BY Distance) over() from #res	


--select * from #res	
--	WHERE Distance <= 0.348673299200412
--order by id , Distance

DROP TABLE IF EXISTS ##RESKnn
SELECT id AS Ident1,SecId  AS Ident2 INTO ##RESKnn FROM #res
	WHERE Distance <= @Perecentile;
--order by id , Distance


DROP TABLE IF EXISTS #FinRes;

DROP TABLE IF EXISTS #CTE_Idents;
WITH
CTE_Idents -- اول میایم تمام آی دی ها رو در میاریم در قالب یک ستون
AS
(
    SELECT DISTINCT Ident1 AS Ident
    FROM ##RESKnn

    UNION

    SELECT DISTINCT Ident2 AS Ident
    FROM ##RESKnn
)
SELECT * INTO #CTE_Idents FROM CTE_Idents;


DROP TABLE IF EXISTS #CTE_Pairs;

WITH CTE_Pairs 
AS
-- حالا جفتهای غیر همسان رو میکشیم بیرون یبار سرجاشون یبارم ستونها رو جابجا میکنیم تا تمام تاپلها رو داشته باشیم
			-- یعنی مثلا اگر 3 و 1 داریم 1 و 3 هم داشته باشیم 
/*
gives the list of all edges of the graph in both directions. Again, UNION is used to remove any duplicates.
*/
(
    SELECT Ident1, Ident2
    FROM ##RESKnn
    WHERE Ident1 <> Ident2

    UNION

    SELECT Ident2 AS Ident1, Ident1 AS Ident2
    FROM ##RESKnn
    WHERE Ident1 <> Ident2
)
SELECT * INTO #CTE_Pairs FROM CTE_Pairs

CREATE CLUSTERED INDEX id ON #CTE_Pairs(Ident1,Ident2)



DROP TABLE IF EXISTS #CTE_Recursive;

WITH CTE_Recursive
AS
/*
CTE_Recursive is the main part of the query that recursively traverses the graph starting from each unique Identifier.
These starting rows are produced by the first part of UNION ALL. The second part of UNION ALL recursively joins to itself linking Ident2 to Ident1.
Since we pre-made CTE_Pairs with all edges written in both directions, we can always link only Ident2 to Ident1 and we'll get all paths in the graph.

At the same time the query builds IdentPath - a string of comma-delimited Identifiers that have been traversed so far. It is used in the WHERE filter:
								
									CTE_Recursive.IdentPath NOT LIKE CAST('%,' + CTE_Pairs.Ident2 + ',%' AS varchar(8000))
*/

(
    SELECT
        CAST(CTE_Idents.Ident AS varchar(8000)) AS AnchorIdent 
        , Ident1
        , Ident2
        , CAST(',' + CAST(Ident1 AS varchar(8000)) + ',' + CAST(Ident2 AS varchar(8000))+ ',' AS varchar(8000)) AS IdentPath
        , 1 AS Lvl
    FROM 
        #CTE_Pairs AS CTE_Pairs
        INNER JOIN #CTE_Idents AS CTE_Idents ON CTE_Idents.Ident = CTE_Pairs.Ident1 -- اون سی تی ای که همه آی دیا رو میاورد رو جوین میدیم 
																		--با جفت شده ها روی ستون اولش و شروع میکنیم کانکت کردنشون
																
    UNION ALL

	/*
		As soon as we come across the Identifier that had been included in the Path before,
		the recursion stops as the list of connected nodes is exhausted. AnchorIdent is the starting Identifier for the recursion,
		it will be used later to group results. Lvl is not really used, I included it for better understanding of what is going on.
	*/

    SELECT 
        CTE_Recursive.AnchorIdent 
        , CTE_Pairs.Ident1
        , CTE_Pairs.Ident2
        , CAST(CTE_Recursive.IdentPath + CAST(CTE_Pairs.Ident2 AS varchar(8000))+ ',' AS varchar(8000)) AS IdentPath
        , CTE_Recursive.Lvl + 1 AS Lvl
    FROM
        #CTE_Pairs AS CTE_Pairs 
        INNER JOIN CTE_Recursive ON CTE_Recursive.Ident2 = CTE_Pairs.Ident1 -- جوین 
    WHERE
        CTE_Recursive.IdentPath NOT LIKE CAST('%,' + CAST(CTE_Pairs.Ident2 AS varchar(8000))+ ',%' AS varchar(8000))
)
SELECT * INTO #CTE_Recursive FROM CTE_Recursive
OPTION (MAXRECURSION 32000)

DROP TABLE IF EXISTS #CTE_RecursionResult;
WITH CTE_RecursionResult
AS
(
    SELECT AnchorIdent, Ident1, Ident2
    FROM #CTE_Recursive
)
SELECT * INTO #CTE_RecursionResult FROM CTE_RecursionResult;

WITH CTE_CleanResult
AS
/*
	CTE_CleanResult leaves only relevant parts from CTE_Recursive and again merges both Ident1 and Ident2 using UNION.
*/
(
    SELECT AnchorIdent, Ident1 AS Ident
    FROM #CTE_RecursionResult

    UNION

    SELECT AnchorIdent, Ident2 AS Ident
    FROM #CTE_RecursionResult
)
, FinRes AS
(
	SELECT Ident,STRING_AGG(AnchorIdent,',') Class FROM CTE_CleanResult
	GROUP BY Ident
)
SELECT *,'Class'+ CAST( DENSE_RANK() over(order by Class) AS VARCHAR(50)) as GrpId into #FinRes
FROM FinRes

DROP TABLE IF EXISTS ##FinRes
SELECT * INTO ##FinRes FROM #FinRes

SELECT * FROM ##FinRes
