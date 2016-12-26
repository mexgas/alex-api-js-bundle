/*
Autor: Jesus Gallardo
Fecha: 2016/12/20
Descripcion:

	SP ccsp_CleanNodeBaseX se modifica para guardar el historial y regresar el primer y ultimo fecha
Version requerida: 35
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 38
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

---------------- inicio SCRIPT @Sql ----------------

	--Index

	--Tables

	--Functions

  	--SP

  	set @process = ''
  	set @sql=''
  	EXEC(@sql)

  	set @process = 'ALTER SP -- ccsp_CleanNodeBaseX'
  	set @sql='ALTER PROCEDURE [dbo].[ccsp_CleanNodeBaseX]
@option int,@dateStart datetime output,@dateEnd datetime output
AS
BEGIN

declare @count int ,@setting int

declare @nodos table (fecha varchar(100))
--declare @dateStart datetime, @dateEnd datetime
declare @res int
set @res = -1

	select  @setting  = valor from ccSettings where setting_id = 188
	if @setting is null set @setting = 40000

	select @count = COUNT (grab_id) from RIA_RecNode with(nolock) where status in(1,3)
	if @count >=  @setting begin

	begin try
			begin tran elimina

			if @option = 2 begin

				insert into RIA_RecNodeHistory
				select grab_id,node,dateIn,dateOut,status from RIA_RecNode where status in(1,3)

				insert into @nodos
				SELECT node.value(''(/R02/@CDATE)[1]'',''varchar(100)'') as node FROM RIA_RecNode where status in(1,3) order by node

				select @dateStart = convert(datetime,MIN(fecha)) ,@dateEnd = convert(datetime, MAX(fecha)) from @nodos

				--update ccBaseXDB set isfull = 1, dateStart=isnull(@dateStart,dateStart),dateEnd=isnull(@dateEnd,getdate()) where serviceId= @option and  isfull = 0 and dateEnd is null

				delete from RIA_RecNode where status in(1,3)
			end
			commit tran elimina
		end try
		begin catch
			rollback  transaction elimina
			set @res = 0
		end catch
	end
	select @res
END'
  	EXEC(@sql)

  	set @process = 'ALTER SP -- trsp_GetParametersExportService'
  	set @sql='ALTER PROCEDURE [dbo].[trsp_GetParametersExportService]
				AS
				BEGIN

				DECLARE  @avrs_enviroment AS INT
				DECLARE @SQL AS NVARCHAR(MAX)

				SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

				IF @avrs_enviroment = 2
					BEGIN
						SET @SQL = 'SELECT * FROM
						(SELECT par_valor,par_id,par_descripcion FROM TREC_PARAMETROS
						WHERE par_id in (2,15,29,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,62,63,65,66,67)
						UNION
						SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66,''''
						FROM RIA_GRABACION)x
						ORDER BY x.par_id'
					END
				ELSE
					BEGIN

						SET @SQL = 'SELECT * FROM
						(SELECT par_valor,par_id FROM TREC_PARAMETROS
						WHERE par_id in (2,15,29,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,62,63,65,66,67)
						UNION
						SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
						FROM TREC_GRABACION)x
						ORDER BY x.par_id'
					END
					EXEC sp_executesql @SQL
			END'
  	EXEC(@sql)

  	set @process = ''
  	set @sql=''
  	EXEC(@sql)

------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

