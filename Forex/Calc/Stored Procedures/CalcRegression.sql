-- exec CalcRegression  
CREATE PROCEDURE [Calc].[CalcRegression] 
as
set nocount on
--TRUNCATE TABLE Regression


DECLARE
@DateFrom DATETIME 
,@DateTo DATETIME 
,@ID INT


DECLARE CR CURSOR 
FOR SELECT ID,MinDte,MaxDte FROM GroupsToReggression

OPEN CR 
FETCH CR INTO @ID,@DateFrom,@DateTo


WHILE @@FETCH_STATUS <> -1
	BEGIN

		DROP TABLE IF EXISTS #PIVOT

		DROP TABLE IF EXISTS #TBCUR
		SELECT 
			 IIF([Open] > [Close] , [Open] , [Close] ) as CandleCeiling
			,IIF([Open] > [Close] , [Close] , [Open] ) as CandleFloor
			,[Time] ,[Open] ,[High] ,[Low]  ,[Close],Volume ,DateId ,RegDate	
		INTO #TBCUR FROM  Dbo.EURUSD_H1
		WHERE [Time] BETWEEN @DateFrom AND @DateTo

		DROP TABLE IF EXISTS #PIVOT
		SELECT *,ROW_NUMBER()OVER(ORDER BY [Time]) AS xAxis
			INTO #PIVOT
		FROM #TBCUR

		DECLARE
			@sy DECIMAL(38,5),
			@sx DECIMAL(38,5),
			@sxx DECIMAL(38,5),
			@sxy DECIMAL(38,5),
			@syy DECIMAL(38,5),
			@count DECIMAL(38,5),
			@alpha DECIMAL(38,5),
			@beta DECIMAL(38,5),
			@cor DECIMAL(38,5)



		DROP TABLE IF EXISTS #PreReg
		;WITH stp1 AS 
			(
				SELECT [time], xAxis AS x ,(f.CandleCeiling+f.CandleFloor)/2 AS y 
				FROM #PIVOT f
			)
		SELECT * INTO #PreReg FROM stp1


		SELECT 
			@sy = sum(y),
			@sx = sum(x),
			@sxx = sum(x*x),
			@sxy = sum(x*y),
			@syy = sum(y*y),
			@count = Count(1)
		FROM #PreReg

		select @alpha = ((@sy*@sxx) - (@sx*@sxy))
						/( (@count*@sxx) - (@sx*@sx) )
			   ,@beta = ((@count*@sxy) - (@sx*@sy))
						/( (@count*@sxx) - (@sx*@sx))
			   ,@cor = ((@count*@sxy) - (@sx*@sy))
						/SQRT( ((@count*@sxx)-(@sx*@sx)) * ((@count*@syy)-(@sy*@sy)))


		--SELECT *,'ORG' AS typ 
		--FROM #PreReg
		--UNION ALL 
		--SELECT DATEADD(HOUR,1,MAX([Time])) AS [Time],MAX(X)+1 AS x,@alpha+(@beta*(max(x)+1)) AS Y,'PRED' AS typ FROM #PreReg

		DECLARE @Prediction DECIMAL(38,5)
				,@PredTime DATETIME
		SELECT @PredTime = DATEADD(HOUR,1,MAX([Time])),@Prediction = @alpha+(@beta*(max(x)+1))  FROM #PreReg



		DROP TABLE IF EXISTS #Degr
		;WITH STP1 AS 
		(
			SELECT R.Time,CAST(R.x AS DECIMAL(38,5)) AS x,R.y,@alpha+(@beta*x) as Regg
			FROM #PreReg R
		),
		STP2 AS 
		(
		SELECT *,
			MAX(Y) OVER() AS mxY,
			MIN(Y) OVER() AS mnY,
			MAX(X) OVER() AS mxX,
			MIN(X) OVER() AS mnX
		FROM STP1
		)
		,STP3 as 
		(
		SELECT *,
			(y-mnY)/(mxY-mnY) AS ScaledY,
			(X-mnX)/(mxX-mnX) AS ScaledX
		FROM STP2
		)
		SELECT *
			into #Degr
		FROM STP3



		DECLARE 
			@x1 decimal(38,5),
			@y1 decimal(38,5),
			@x2 decimal(38,5),
			@y2 decimal(38,5)

		SELECT @x1 = ScaledX,@y1 = ScaledY
		FROM #Degr WHERE X = (SELECT MIN(X) FROM #Degr)

		SELECT @x2 = ScaledX,@y2 = ScaledY
		FROM #Degr WHERE X =(SELECT MAX(X) FROM #Degr)


		DECLARE @Degree decimal(38,2)
		SELECT @Degree = DEGREES(ATN2(@y2-@y1,@x2-@x1))


		

		DECLARE @MSE Decimal(38,5)
				,@MAE Decimal(38,5)
				,@DiffRegY Decimal(38,5)
				
		DECLARE @MaxX DECIMAL(38,2)
		select @MaxX = MAX(d.x) from #Degr d
		
		;WITH stp1 AS 
		(
		SELECT *,
			Power((Regg*1000)-(y*1000),2) AS MSE, -- عدد اعشاری ریزه به توان که میرسه 0 میشه 
			ABS(Regg-y) AS MAE,
			IIF( X BETWEEN @MaxX*0.05 AND @MaxX*0.95, ABS(Regg-y),null) AS DiffRegY
		FROM #Degr
		)
		,STP2 AS 
		(
			SELECT *,
			MAX(MSE) OVER() AS mxMSE,
			MIN(MSE) OVER() AS mnMSE,
			MAX(MAE) OVER() AS mxMAE,
			MIN(MAE) OVER() AS mnMAE			
			FROM stp1
		)
		,stp3 AS 
		(
			SELECT 
				*,
				(MSE-mnMSE)	/ NULLIF((mxMSE-mnMSE),0) AS MSEScaled,
				(MAE-mnMAE) / NULLIF((mxMAE-mnMAE),0) AS MAEScaled
			FROM STP2
		)
		SELECT 
			@MSE = AVG(MSEScaled) 
			,@MAE = AVG(MAEScaled)
			,@DiffRegY = MAX(DiffRegY)			
		FROM stp3


		DELETE Regression WHERE GroupsToReggID = @ID
		insert into Regression
		(
			GroupsToReggID	
			,Time			
			,x				
			,y				
			,Regg			
			,mxY				
			,mnY				
			,mxX				
			,mnX				
			,ScaledY			
			,ScaledX			
		)
		SELECT 
		@ID AS GroupsToReggID
		,Time			
		,x				
		,y				
		,Regg			
		,mxY				
		,mnY				
		,mxX				
		,mnX				
		,ScaledY			
		,ScaledX			
		FROM #Degr


		UPDATE GroupsToReggression 
		SET Correlation = @cor,
			MSE = @MSE,
			MAE = @MAE,
			Degree = @Degree,
			MaxDiffRegY	= @DiffRegY
		WHERE id = @ID
	FETCH  CR INTO @ID,@DateFrom,@DateTo
END

