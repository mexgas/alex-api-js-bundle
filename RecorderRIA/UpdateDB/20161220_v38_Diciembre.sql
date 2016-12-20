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

