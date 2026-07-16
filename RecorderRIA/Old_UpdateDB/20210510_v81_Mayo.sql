set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 81
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

    set @process = 'CW-4384 Alter colum Database'
		set @Sql = '
	if (SELECT COL.max_length
			From sys.columns COL
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id
			where TAB.name = ''ccCallsIn'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE ccCallsIn ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length
			From sys.columns COL
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id
			where TAB.name = ''GRAB_DUPLICATE_ROWS_IN_BCKUP'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE GRAB_DUPLICATE_ROWS_IN_BCKUP ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length
			From sys.columns COL
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id
			where TAB.name = ''GRAB_DUPLICATE_ROWS_OUT_BCKUP'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE GRAB_DUPLICATE_ROWS_OUT_BCKUP ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length
			From sys.columns COL
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id
			where TAB.name = ''RIA_GRABACION'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE RIA_GRABACION ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length
			From sys.columns COL
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id
			where TAB.name = ''RIA_GRABACIONCONSULTA'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE RIA_GRABACIONCONSULTA ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END

	if (SELECT COL.max_length
			From sys.columns COL
				INNER JOIN sys.tables TAB On COL.object_id = TAB.object_id
			where TAB.name = ''RIA_GRABACIONCONSULTABackUp'' and COL.name = ''cal_Key'') < 40
	BEGIN
		ALTER TABLE RIA_GRABACIONCONSULTABackUp ALTER COLUMN cal_Key VARCHAR (40) NOT NULL
	END'
		EXEC(@Sql)



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
