
CREATE PROCEDURE [Operation].[Ins_H1]
@Time datetime
,@Open decimal(38,5)
,@High decimal(38,5)
,@Low decimal(38,5)
,@Close decimal(38,5)
,@Volume bigint
as 

DECLARE @DateId int
SELECT @DateId = ID FROM DimDate WHERE Endt = CAST(@Time AS date)

INSERT INTO Dbo.EURUSD_H1 
           ([Time]
           ,[Open]
           ,[High]
           ,[Low]
           ,[Close]
           ,[Volume]
           ,[DateId])
     VALUES
           (@Time
           ,@Open
           ,@High
           ,@Low
           ,@Close
           ,@Volume
           ,@DateId)
