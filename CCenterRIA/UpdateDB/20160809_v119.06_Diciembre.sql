/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2016/12/20
Description:
	Se agrega estados del agente en caso de no exisir por idioma
	se modfiica el SP ccsp_BaseXmngr para agregar el primer registro y ultimo para buscar en baseX
	se modifica el SP ccsp_CleanNodeBaseX para pasar la informacion a la base de historico

Database: CCenterRia
Required version: 119.05

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 129 sin fix
set @versionfix = 6
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and (@actualVersionFix = @versionfix - 1 or @actualVersionFix = @versionfix)
	begin
		begin tran
		begin try

		set @process = ''
		set @Sql= 'if exists(select valor from ccSettings where setting_id=27 and valor=''1'') begin
	if not exists(select * from ccTipoStatusAgente where TipoStatusAge_id=25) insert into ccTipoStatusAgente(TipoStatusAge_id,descripcion) values(25,''Transferencia Fallida'')
	if not exists(select * from ccTipoStatusAgente where TipoStatusAge_id=26) insert into ccTipoStatusAgente(TipoStatusAge_id,descripcion) values(26,''Ringing Fallida'')
end
else begin
	if not exists(select * from ccTipoStatusAgente where TipoStatusAge_id=25) insert into ccTipoStatusAgente(TipoStatusAge_id,descripcion) values(25,''Xfer Fail'')
	if not exists(select * from ccTipoStatusAgente where TipoStatusAge_id=26) insert into ccTipoStatusAgente(TipoStatusAge_id,descripcion) values(26,''Ringing Fail'')
end'
		EXEC(@Sql)

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)

		set @process = ''
		set @Sql= ''
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_BaseXmngr'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@idF bigint = 0,
@idL bigint = 0,
@name varchar(25) = NULL,
@top varchar(max) = NULL,
@dateIni datetime =null,
@dateEnd datetime =null
AS
declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
set @sql = ''''
--nota: las acciones 3 y 4 hacerlas para casos dinamicos, (i.e.) si se va controlor por tamaño y asignar un xml nuevo, conusltar Daniel de CW :)

if @action in (1,6) begin --obtiene los nodos a insertar en BX
	if @action = 1 set @status =0
	else if @action = 6 set @status = 2

	if @option = 1 begin
		set @tableName=''ccChatsNode''
		set @columnId=''chatId''
	end
	else if @option = 3 begin
		set @tableName=''ccEmailNode''
		set @columnId=''emailId''
	end
	else if @option = 4 begin
		set @tableName=''ccTwitterNode''
		set @columnId=''conversationTwitterId''
	end
	if @option in (1,3,4) begin
		set @sql = ''select top '' + @top + '' ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ''
		+ @tableName + '' with(rowlock) where status = ''+ cast(@status as nvarchar(max))
		--print(@sql)
		exec(@sql)
	end
end
else if @action in (2,7) begin--actualiza los nodos insertados en BX
	if @action = 2 set @status =0
	else if @action = 7 set @status = 2
	if @option = 1
		update ccChatsNode with(rowlock) set [status] = @status+1, dateOut = getDate() where chatId between @idF and @idL and [status] =@status
	else if @option = 3
		update ccEmailNode with(rowlock) set [status] = @status+1, dateOut = getDate() where emailId between @idF and @idL and [status] = @status
	else if @option = 4
		update ccTwitterNode with(rowlock) set [status] = @status+1, dateOut = getDate() where conversationTwitterId between @idF and @idL and [status] =@status

end
else if @action = 3 --trae el nombre de la base de datos en BX
begin
	select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
	insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option, getDate(), @name,0)
end
else if @action = 5 begin --obtener servicios disponibles
	select @chat= 0,@rec= 2,@email= 0,@twitter=0
	select @chat = case when valor > 1 then 1 else 0 end from ccSettings where setting_id = 145
	select @email = case when valor = 1 then 3 else 0 end from ccSettings where setting_id = 155
	select @twitter = case when valor = 1 then 4 else 0 end from ccSettings where setting_id = 173
	select id, ref 	from ccFinderServices where id in (@chat, @rec, @email,@twitter)

end
else if @action = 8 begin--trae la lista de las bases para la busqueda
	select Xname from ccBaseXDB where serviceId = @option
	 and (

		@dateIni between dateStart and dateEnd
		or @dateEnd between dateStart and dateEnd
		or dateStart between @dateIni and @dateEnd
	)
	union
	select Xname from ccBaseXDB where serviceId = @option and isFull=0
	 and (
		 dateStart between @dateIni and @dateEnd
		 or @dateIni>=dateStart

	)
end
else if @action = 9 begin--Cierra la base datos
	update ccBaseXDB set isfull = 1, dateStart=isnull(@dateIni,dateStart),dateEnd=isnull(@dateEnd,getdate()) where serviceId= @option and  isfull = 0 and dateEnd is null
end'
		EXEC(@Sql)

		set @process = 'Alter SP -- ccsp_CleanNodeBaseX'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_CleanNodeBaseX]
@option int,@dateStart datetime output,@dateEnd datetime output
AS
BEGIN

declare @count int , @setting int
declare @nodos table (fecha varchar(100))
declare @res int
set @res = -1
	select  @setting  = valor from ccSettings where setting_id = 189
	if @setting is null set @setting = 40000

	if @option = 1  select @count = COUNT (chatId) from ccChatsNode with(nolock)
	else if @option = 3  select @count = COUNT (emailId) from ccEmailNode with(nolock)
	else if @option = 4  select @count = COUNT (conversationTwitterId) from ccTwitterNode with(nolock)

	if @count >=  @setting begin

	begin try
			begin tran elimina

			if @option = 1 begin

				insert into ccChatsNodeHistory
				select chatId,node,dateIn,dateOut,status from ccChatsNode where status in(1,3)

				insert into @nodos
				SELECT node.value(''(/R01/@CDATE)[1]'',''varchar(100)'') as node FROM ccChatsNode where status in(1,3) order by node

				select @dateStart = convert(datetime,MIN(fecha)) ,@dateEnd = convert(datetime, MAX(fecha)) from @nodos

				update ccBaseXDB set isfull = 1, dateStart=@dateStart,dateEnd=@dateEnd where serviceId = @option and isfull = 0 and dateEnd is null

				delete from ccChatsNode where status in(1,3)
			end
			else if @option = 3  begin
				insert into ccEmailNodeHistory
				select emailId,node,dateIn,dateOut,status from ccEmailNode where status in(1,3)

				insert into @nodos
				SELECT node.value(''(/R03/@CDATE)[1]'',''varchar(100)'') as node FROM ccEmailNode where status in(1,3) order by node

				select @dateStart = convert(datetime,MIN(fecha)) ,@dateEnd = convert(datetime, MAX(fecha)) from @nodos

				update ccBaseXDB set isfull = 1,dateStart=@dateStart,dateEnd=@dateEnd  where serviceId = @option and isfull = 0 and dateEnd is null

				delete from ccEmailNode where status in(1,3)
			end
			else if @option = 4  begin
				insert into ccTwitterNodeHistory
				select conversationTwitterId,node,dateIn,dateOut,status from ccTwitterNode where status in(1,3)

				insert into @nodos
				SELECT node.value(''(/R04/@CDATE)[1]'',''varchar(100)'') as node FROM ccTwitterNode where status in(1,3) order by node

				select @dateStart = convert(datetime,MIN(fecha)) ,@dateEnd = convert(datetime, MAX(fecha)) from @nodos

				update ccBaseXDB set isfull = 1, dateStart=@dateStart,dateEnd=@dateEnd  where serviceId = @option and isfull = 0 and dateEnd is null

				delete from ccTwitterNode where status in(1,3)
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
		EXEC(@Sql)



		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end