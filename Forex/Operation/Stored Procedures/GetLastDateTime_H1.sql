
CREATE PROCEDURE [Operation].[GetLastDateTime_H1]
as 
select FORMAT(Max([Time]),'yyyy-MM-dd HH:mm:ss') as [Time]  from Dbo.EURUSD_H1
 


