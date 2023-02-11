

CREATE PROCEDURE [Operation].[FillHistoryExported]
@PositionID			VARCHAR(50)
,@Type				VARCHAR(50)
,@Symbol			VARCHAR(50)
,@Volume			VARCHAR(50)
,@OpenDateTime		VARCHAR(50)
,@OpenPrice			VARCHAR(50)
,@CloseDateTime		VARCHAR(50)
,@ClosePrice		VARCHAR(50)
,@TakeProfit		VARCHAR(50)
,@StopLoss			VARCHAR(50)
,@PositionPnL		VARCHAR(50)
,@Swap				VARCHAR(50)
,@Commission		VARCHAR(50)
,@TotalPnL			VARCHAR(50)
,@MagicNumber		VARCHAR(50)
,@Comment			VARCHAR(50)
,@DealinID			VARCHAR(50)
,@DealoutID			VARCHAR(50)
AS 

insert into [dbo].[HistoryExported]
(	   [Position ID]
      ,[Type]
      ,[Symbol]
      ,[Volume]
      ,[Open Date Time]
      ,[Open Price]
      ,[Close Date Time]
      ,[Close Price]
      ,[TakeProfit]
      ,[StopLoss]
      ,[Position PnL]
      ,[Swap]
      ,[Commission]
      ,[Total PnL]
      ,[MagicNumber]
      ,[Comment]
      ,[Deal in ID]
      ,[Deal out ID]
  )
select 
@PositionID		
,@Type			
,@Symbol		
,@Volume		
,@OpenDateTime	
,@OpenPrice		
,@CloseDateTime	
,@ClosePrice	
,@TakeProfit	
,@StopLoss		
,@PositionPnL	
,@Swap			
,@Commission	
,@TotalPnL		
,@MagicNumber	
,@Comment		
,@DealinID		
,@DealoutID		
where not exists(select 1 from [dbo].[HistoryExported] h where h.[Open Date Time] = @OpenDateTime)
