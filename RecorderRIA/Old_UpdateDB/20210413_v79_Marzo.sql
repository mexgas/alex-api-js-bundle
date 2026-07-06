set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 79
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try
	
    SET @process = 'CW-5098 Alter ccsp_CleanNodeBaseX'
	SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_CleanNodeBaseX]
AS
BEGIN
	DECLARE @percentage INT, @setting INT
	DECLARE @nodos TABLE (fecha VARCHAR(100))
	DECLARE @top INT
	DECLARE @table TABLE (grabId BIGINT PRIMARY KEY, node XML NOT NULL, dateIn DATETIME NOT NULL, STATUS TINYINT NOT NULL)
	DECLARE @tableNotExists TABLE (grabId BIGINT PRIMARY KEY)

	SET @percentage = 20 --porcentaje de registros que se pasaran esta en funcion del setting 188

	SELECT @setting = valor
	FROM ccSettings
	WHERE setting_id = 188

	IF @setting IS NULL
		SET @setting = 40000
	SET @top = @setting * 100 / @percentage

	INSERT INTO @table
	SELECT TOP (@top) A.grab_id, A.node, A.dateIn, STATUS
	FROM ria_RecNode A WITH (NOLOCK)
	WHERE A.STATUS IN (1, 3) and node is not null
	ORDER BY grab_id

	INSERT INTO @tableNotExists
	SELECT A.grabId
	FROM @table A
	LEFT JOIN RIA_RecNodeHistory B WITH (NOLOCK) ON B.grab_id = A.grabId
	WHERE B.grab_id IS NULL

	INSERT INTO RIA_RecNodeHistory (grab_id, node, dateIn, dateOut, STATUS)
	SELECT A.grabId, A.node, A.dateIn, getdate(), A.STATUS
	FROM @table A
	INNER JOIN @tableNotExists B ON A.grabId = B.grabId

	DELETE
	FROM ria_RecNode
	WHERE grab_id IN (
			SELECT grabId
			FROM @table
			)
END
'
	EXEC (@sql)

	

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
