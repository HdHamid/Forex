
CREATE PROCEDURE [Calc].[KnnGroups] 
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
select TOP 1 @Perecentile = PERCENTILE_CONT(0.05) WITHIN GROUP(ORDER BY Distance) over() from #res	


--select * from #res	
--	WHERE Distance <= 0.348673299200412
--order by id , Distance

DROP TABLE IF EXISTS ##RESKnn
SELECT id AS Ident1,SecId  AS Ident2 INTO ##RESKnn FROM #res
	WHERE Distance <= @Perecentile;
--order by id , Distance





--================== cHANGES

--DECLARE @Perecentile DECIMAL(38,5)
--select TOP 1 @Perecentile = PERCENTILE_CONT(0.05) WITHIN GROUP(ORDER BY Distance) over() from #res	

DECLARE @RecordsCount DECIMAL(38,2) = (SELECT COUNT(1) FROM GroupsToReggression)

DROP TABLE IF EXISTS #Certified
select * INTO #Certified from #res 	
	WHERE Distance <= @Perecentile
order by id , Distance

DROP TABLE IF EXISTS #PrepForeach
SELECT ROW_NUMBER() OVER(ORDER BY count(1)/@RecordsCount DESC,ID ) RN,ID,count(1)/@RecordsCount AS Cnt ,
	CONCAT(ID,',',STRING_AGG(SecId,',')) AS SecIds
INTO #PrepForeach FROM #res
	WHERE Distance <= @Perecentile
group by id


DECLARE @RN INT = 1
WHILE EXISTS(SELECT 1 FROM #PrepForeach R WHERE R.RN > @RN )
BEGIN 	
	DECLARE @ID INT = (SELECT ID FROM #PrepForeach R WHERE R.RN = @RN)
	DELETE #PrepForeach WHERE ID IN (SELECT SecId FROM #Certified WHERE ID = @ID )	
	SET @RN = @RN + 1
END 


DROP TABLE IF EXISTS #PrepForeach2
SELECT DENSE_RANK() OVER(ORDER BY RN) AS rn,id,CONCAT(DENSE_RANK() OVER(ORDER BY RN),'_','CLASS') AS ClassName,v.value as secIds,ROW_NUMBER() over(partition by value order by rn) as Rem into #PrepForeach2 
	FROM #PrepForeach r 
cross apply string_split(r.secids,',') v

DELETE from #PrepForeach2 
where Rem > 1


SELECT RN,ClassName,ID,count(1) AS CNT,CONCAT(ID,',',STRING_AGG(secIds,',')) AS SecIds FROM #PrepForeach2
GROUP BY RN,ID ,ClassName
HAVING count(1) > 2 
ORDER BY count(1) DESC 


DROP TABLE IF EXISTS calc.KnnGroupsRes
SELECT rn,P.ClassName as GrpId,v.value as Ident INTO calc.KnnGroupsRes
	FROM #PrepForeach2 P 
	CROSS APPLY string_split(P.secids,',') v


