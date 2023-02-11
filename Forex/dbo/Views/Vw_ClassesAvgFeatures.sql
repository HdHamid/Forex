CREATE VIEW Vw_ClassesAvgFeatures
AS
select k.GrpId,avg(r.Correlation) as Correlation,avg(r.DayCount) as DayCount,avg(r.MAE) as MAE,avg(r.MSE) as MSE from calc.KnnGroupsRes k 
	inner join GroupsToReggression r on r.ID = k.Ident 
group by k.GrpId

