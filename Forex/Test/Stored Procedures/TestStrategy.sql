CREATE PROCEDURE [Test].[TestStrategy] 
as


truncate table [dbo].[HistoryExported]

truncate table EURUSD_H1
insert into EURUSD_H1
select * from EURUSD_H1_History 
WHERE [Time] BETWEEN '2021-01-01 00:00:00.000' AND '2022-01-01 00:00:00.000'

TRUNCATE TABLE Operation.WeeklyInfo

TRUNCATE TABLE EURUSD_W
exec calc.FillWeekly


--- clustering
exec [Calc].[prepareGroupsToReggression]
exec [Calc].[CalcRegression] 
exec [Calc].[FeatureEnginiering]
exec [Calc].[KnnGroups] 


--insert into EURUSD_H1_History  
--select * from EURUSD_H1 hh where not exists(select 1 from EURUSD_H1_History h where h.[Time] = hh.[Time])


select min([Time]),max([Time]) from EURUSD_H1_History 
select min(MinDte),max(MinDte) from GroupsToReggression

select top 100 * from EURUSD_H1 
order by [time] desc 


--delete  Dbo.ForexAlgoCandles 
--where [Time] >= '2015-03-17'

select * from [dbo].[HistoryExported]

--truncate table [dbo].[HistoryExported]

select cOUNT(1),SUM([Position PnL]) from [dbo].[HistoryFromMTDetail]







select * from [dbo].[Vw_CheckDataDateDiff]
----Fill History Feom H1
--truncate table EURUSD_H1_History 
--insert into EURUSD_H1_History
--select * from EURUSD_H1
