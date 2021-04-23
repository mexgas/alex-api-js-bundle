CREATE FUNCTION AsignaIDWS (@ID INT, @TIPO INT)
	RETURNS VARCHAR (1000)
	AS
	BEGIN
	DECLARE @RES VARCHAR (1000)=''
	DECLARE @TIDWG VARCHAR (5)
	DECLARE Cursor1 Cursor
		for SELECT IDWG from ccRIAWorkGroup_Calid WHERE User_id>0 AND cal_id=@ID AND tipo=@TIPO
	open Cursor1
	fetch Cursor1 INTO @TIDWG
	WHILE (@@FETCH_STATUS=0)
	BEGIN
	IF @RES=''
				SET @RES=@TIDWG
			ELSE
				SET @RES=@RES+','+@TIDWG
	fetch Cursor1 INTO @TIDWG
	END
	close Cursor1
	Deallocate Cursor1
	return @RES
	END;