
CREATE view [dbo].[VW_USD_H1]
as 
SELECT 
CAST([<DATE>]+' '+[<TIME>] AS DATETIME) AS TIME
,[<OPEN>]  as [OPEN]
,[<HIGH>] 	as [HIGH]
,[<LOW>] 	as [LOW]
,[<CLOSE>] 	as [CLOSE]
,[<VOL>] 	as [VOLume]
FROM [dbo].[EURUSD_H1_TMP]
