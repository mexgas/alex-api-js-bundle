CREATE FUNCTION fGetWeekday (@time smalldatetime)  
RETURNS int
AS  
BEGIN 
	DECLARE @wk int
	DECLARE @tmpDATEFIRST smallint
	
	--store & set new DATEFIRST setting
	SELECT @tmpDATEFIRST = @@DATEFIRST 

	--Get weekday
	IF (@tmpDATEFIRST=1)
	BEGIN
		SELECT @wk = DATEPART(dw, @time)
	END
	ELSE
	BEGIN
		SELECT @wk = DATEPART(dw, @time) -1
		IF (@wk = 0)
			SELECT @wk = 7
	END
	
	RETURN (@wk)
END