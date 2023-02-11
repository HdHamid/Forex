CREATE PROCEDURE [Operation].[_Robot_SharkZone_Active_Chandelier_Exit]
AS
BEGIN 


	

	-- last day of week dont release the signal 
	declare @DayOfWeek tinyint =
		(select EnNoDayOfWeek from DimDate where endt = (select cast(max([Time]) as date) from EURUSD_H1))


	--=============== بروزرسانی هفتگی
	if (@DayOfWeek in(1,5) AND (SELECT DATEPART(HOUR,MAX([Time])) from EURUSD_H1) = 23)
	--if ((SELECT DATEPART(HOUR,MAX([Time])) from EURUSD_H1) = 23)
	begin
		exec calc.FillWeekly	
	end 

	EXEC [Operation].[Chandelier_Exit]
	
END 