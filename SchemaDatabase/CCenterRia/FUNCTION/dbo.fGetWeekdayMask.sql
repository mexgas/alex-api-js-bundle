CREATE FUNCTION fGetWeekdayMask (@time smalldatetime)  
RETURNS int
AS  
BEGIN 
	DECLARE @wk int
	DECLARE @wkm int
	DECLARE @tmp int
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
	
	--initializes @wkm & @tmp
	SELECT @wkm = 1
	SELECT @tmp = @wk
	
	--calculate @wkm
	wkloop:
	SELECT @tmp = @tmp - 1
	IF (@tmp > 0)
	BEGIN
		SELECT @wkm = @wkm * 2
		GOTO wkloop
	END
	
	RETURN (@wkm)
END