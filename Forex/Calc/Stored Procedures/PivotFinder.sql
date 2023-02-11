CREATE PROCEDURE Calc.PivotFinder
  @Top INT = 200
 ,@WindowFrom nvarchar(5) = '5'
 ,@WindowTo nvarchar(5) = '5'
 ,@UniqueTableName nvarchar(50) OUT
As

DROP TABLE IF EXISTS #TBCUR
SELECT TOP (@Top)  ROW_NUMBER()OVER(ORDER BY [Time]) AS RowNo
	,IIF([Open] > [Close] , [Open] , [Close] ) as CandleCeiling
	,IIF([Open] > [Close] , [Close] , [Open] ) as CandleFloor
,
[Time] ,[Open] ,[High] ,[Low]  ,[Close],Volume ,DateId ,RegDate
INTO #TBCUR FROM  Dbo.EURUSD_H1
ORDER BY [Time] DESC

DECLARE @untilRowNo int = (select Max(RowNo) from  #TBCUR) - cast(@WindowTo as int)


DECLARE @TSQL NVARCHAR(MAX) = 
	
	'select 
	ROW_NUMBER()OVER(ORDER BY [Time]) AS xAxis
	,*															--@PivotFollowing
	,max([High]) over(order by RowNo rows between '+@WindowFrom+' preceding and '+@WindowTo+' following) as MaxBetween  
	,Min([Low]) over(order by RowNo rows between '+@WindowFrom+' preceding and '+@WindowTo+' following) as MinBetween 
	,max([High]) over(order by RowNo rows between current row and '+@WindowTo+' following) as MaxFuture
	,min([Low]) over(order by RowNo rows between current row and '+@WindowTo+' following) as MinFuture
	from #TBCUR	
	--where RowNo <= @untilRowNo
	'
DROP TABLE IF EXISTS #Intermediate
CREATE TABLE #Intermediate
(
xAxis INT,
RowNo	INT ,
CandleCeiling	DECIMAL(38,5),
CandleFloor	DECIMAL(38,5),
[Time]	DATETIME,
[Open]		DECIMAL(38,5),
[High]		DECIMAL(38,5),
[Low]		DECIMAL(38,5),
[Close]		DECIMAL(38,5),
Volume		DECIMAL(38,5),
DateId	INT,
RegDate	DATETIME,
MaxBetween	DECIMAL(38,5),
MinBetween	DECIMAL(38,5),
MaxFuture	DECIMAL(38,5),
MinFuture	DECIMAL(38,5),
MaxRegBetween DECIMAL(38,5),
MinRegBetween DECIMAL(38,5),
MaxRegFuture DECIMAL(38,5),
MinRegFuture DECIMAL(38,5)
)

insert into #Intermediate
(
xAxis
,RowNo	
,CandleCeiling	
,CandleFloor	
,[Time]	
,[Open]		
,[High]		
,[Low]		
,[Close]		
,Volume		
,DateId	
,RegDate	
,MaxBetween	
,MinBetween	
,MaxFuture	
,MinFuture	
)
exec sp_executesql @TSQL

DECLARE @TblHashName nvarchar(50)= CONCAT('##',REPLACE(NEWID(),'-',''))
SET @UniqueTableName = @TblHashName

DECLARE @SQLQuery2 NVARCHAR(MAX)
= CONCAT(
'
;WITH stp2 as 
(
	select stp1.*,dt.Endt,iif(MaxBetween=[High] or RowNo = ',@untilRowNo,' ,1,0) as MX ,iif(minBetween=[Low] or RowNo = ',@untilRowNo,',1,0) as Min,dt.EnDay,dt.EnMonthName,dt.EnYear -- Shenasaee tarikhe PivotHa
	,iif(MaxBetween=[High],1,0) as IsMXBecauseOfMaxBetween,iif(minBetween=[Low],1,0)IsMinBecauseOfMinBetween
	from #Intermediate as stp1
	inner join dbo.DimDate dt on dt.ID = stp1.DateID
) 

select 
xAxis
,RowNo
,[Time]
,[Open]
,[High]
,[Low]
,[Close]
,CandleCeiling
,CandleFloor
,Volume
,DateID
,MaxBetween
,MinBetween
,MaxFuture
,MinFuture
,Endt
,iif(RowNo = ',@untilRowNo,' and IsMXBecauseOfMaxBetween = 0 , 0 ,MX) as MX
,iif(RowNo = ',@untilRowNo,' and IsMinBecauseOfMinBetween = 0 , 0 ,min) as Min
,EnDay
,EnMonthName
,EnYear
, CAST(NULL AS DECIMAL(6,4)) AS VolLagPercent
	INTO ',@TblHashName,'
from stp2 S
')
exec sp_executesql @SQLQuery2






