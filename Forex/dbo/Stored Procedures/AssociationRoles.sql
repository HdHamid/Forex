CREATE procedure [dbo].[AssociationRoles] 
as
;with sts1 as 
(
select k.GrpId,lead(GrpId) over(order by g.MinDte) as LeadGrp from GroupsToReggression g 
	inner join Calc.KnnGroupsRes k on k.Ident = g.ID
)
,stp2 as 
(
	select GrpId,LeadGrp,count(1) as Cnt,count(1)*1.00/Sum(count(1)) over(partition by GrpId) AS OccuredProb from sts1
		where LeadGrp is not null
	group by GrpId,LeadGrp
)
,stp3 as 
(
	select *, AVG(OccuredProb) over(partition by GrpId) as ProbAvg from stp2 
	--where OccuredProb > 50
)
select * from stp3 
	where (OccuredProb > ProbAvg or OccuredProb = 1)
order by GrpId,OccuredProb desc 




