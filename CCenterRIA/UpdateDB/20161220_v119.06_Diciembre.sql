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
	Se elimina el SP ccsp_CreateNodeMail se sustituye por ccsp_CreateNodeMultimedia
	Se quitan los conflictos de replicas

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

		set @process = 'Drop SP -- ccsp_CreateNodeMail'
		set @Sql= 'if exists (select * from sys.procedures where name = N''ccsp_CreateNodeMail'') DROP PROCEDURE ccsp_CreateNodeMail'
		EXEC(@Sql)

		set @process = 'Insert ccTipoStatusAgente 26,27'
		set @Sql= 'if exists(select valor from ccSettings where setting_id=27 and valor=''1'') begin
	if not exists(select * from ccTipoStatusAgente where TipoStatusAge_id=25) insert into ccTipoStatusAgente(TipoStatusAge_id,descripcion) values(25,''Transferencia Fallida'')
	if not exists(select * from ccTipoStatusAgente where TipoStatusAge_id=26) insert into ccTipoStatusAgente(TipoStatusAge_id,descripcion) values(26,''Ringing Fallida'')
end
else begin
	if not exists(select * from ccTipoStatusAgente where TipoStatusAge_id=25) insert into ccTipoStatusAgente(TipoStatusAge_id,descripcion) values(25,''Xfer Fail'')
	if not exists(select * from ccTipoStatusAgente where TipoStatusAge_id=26) insert into ccTipoStatusAgente(TipoStatusAge_id,descripcion) values(26,''Ringing Fail'')
end'
		EXEC(@Sql)

		set @process = 'Inser new Reports -- 4180'
		set @Sql= 'if not exists(select * from ccmenus where type=3 and menu_id=4180)
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
values(4180,''Detalle de resultados de marcación|Dialing Results Detail'',4000,''B'',2,3,'''',''db47a2867c7795a221f61d9e0dccebfb32d8fb3e0026848cfc108c677051317d6f93de038e1f16b80f67b6139265c86e669c7602ede198536f899842d56c5d37'')
'
		EXEC(@Sql)

		set @process = 'Delete conflict Replication'
		set @Sql= 'if exists(select * from sys.tables where name=''MSmerge_conflicts_info'') begin

	SELECT  ROW_NUMBER() OVER(ORDER BY c.rowguid) as row,s.conflict_table, c.rowguid, c.origin_datasource
	INTO #temp_conflicts
	FROM dbo.MSmerge_conflicts_info c
	JOIN sysmergearticles s ON c.tablenick = s.nickname

	--Setup local variables
	DECLARE @conflict_table nvarchar(255)
	DECLARE @row uniqueidentifier
	DECLARE @origin_datasource nvarchar(255)
	declare @count int,@i int

	select @count=count(*),@i=1 from #temp_conflicts

	while @i<=@count begin
		select @conflict_table=conflict_table, @row=rowguid, @origin_datasource=origin_datasource from #temp_conflicts where row=@i
		EXEC sp_deletemergeconflictrow
		@conflict_table = @conflict_table,        -- conflict table name from sysmergearticles
		@rowguid = @row,                                      -- row identifier from msmerge_conflicts_info
		@origin_datasource = @origin_datasource   -- origin of the conflict from msmerge_conflicts_info
		set @i=@i+1
	end

	DROP table #temp_conflicts
end'
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

		set @process = 'Insert ccSettings -- Limit of calls per seconds'
set @sql='if exists (select * from sys.tables where name = N''ccSettings'')
    begin
	UPDATE ccSettings SET valor = ''0'', descripcion = ''Porcentaje de limite de llamadas por segundo'', Status = 1, Tipo = ''ADM'', detalle = ''0 funcion inhabilitada, 1-100 porcentaje de puertos de salida por segundo'', description = ''Percent of limit of calls per seconds'', bLoadSettings = 1, validate = ''^(100|\d{1,2})$'' WHERE setting_id = 190
	end
		else
	begin
	INSERT INTO ccSettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate) VALUES (190, ''0'',''Porcentaje de limite de llamadas por segundo'',1,''ADM'',''0 funcion inhabilitada, 1-100 porcentaje de puertos de salida por segundo'',''Percent of limit of calls per seconds'',1,''^(100|\d{1,2})$'')
    end'
EXEC(@sql)

set @process = 'Insert ccSettings -- Telephone transfer list'
set @sql='if exists (select * from sys.tables where name = N''ccSettings'')
    begin
    UPDATE ccSettings SET valor = ''0'', descripcion = ''Restringir transferencia de llamadas por área'', Status = 1, Tipo = ''GRL'', detalle = ''1:Activar 0:Desactivar'', description = ''Restrict transfer directory by area'', bLoadSettings = 1, validate = ''^[0-1]$'' WHERE setting_id = 191
	end
		else
	begin
    INSERT INTO ccSettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate) VALUES (191, ''0'',''Restringir transferencia de llamadas por área'',1,''GRL'',''1:Activar 0:Desactivar'',''Restrict transfer directory by area'',1,''^[0-1]$'')
    end'
EXEC(@sql)

set @process = 'validate if exists procedure [dbo].[ccsp_AgentTransfLstArea]'
set @Sql= 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''ccsp_AgentTransfLstArea'')
		DROP PROCEDURE ccsp_AgentTransfLstArea'
EXEC(@sql)

	set @process = 'Create procedure -- [dbo].[ccsp_AgentTransfLstArea]'
	set @sql='CREATE PROCEDURE [dbo].[ccsp_AgentTransfLstArea]
@userID INT,
@current INTEGER = 0
AS
set nocount on

BEGIN
declare @value int

select @value = valor from ccSettings where setting_id = 191

	IF @value = 0
		begin
			select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as nomb from ccusers cu join
			(
				select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp
				join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
			)
			x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
			Order by nomb
		end

	if @value = 1
		begin
			if (@current <> 0)
				begin
					select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as nomb from ccusers cu join
					(
						select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp
						join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
					)
					x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
					and IDArea in (select cu.IDArea from ccUsers cu join ccInbound ci on cu.IDArea = ci.IDArea where inbound_id =  @current)
					Order by nomb
				end
			else
				begin
					select x.extid, Nombres + '' '' + isNull( apellidoPAterno, '''') as nomb from ccusers cu join
					(
						select user_id, case when cp.ext_id > 0 then Extension else pos_id * -1 end as extId from ccposicion cp
						join ccmonitorext ce on cp.ext_id = ce.ext_id where user_id > 0
					)
					x on x.user_id = cu.user_id where cu.status = 1 and cu.xfermask = 1 and cu.user_id <> @userID
					and IDArea in (select IDArea from ccUsers where User_id = @userID)
					Order by nomb
				end
		end
END
set nocount off'
	EXEC(@sql)

	set @process = 'Alter procedure -- [dbo].[ccsp_AgentGetEspecialidadesActivas]'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_AgentGetEspecialidadesActivas]
@userID INT,
@current integer = 0
as
declare @fecha datetime
declare @dia smallint
declare @hora smallint
declare @minuto smallint
declare @value int

	SET DATEFIRST 1

	select @fecha =  getdate()
	select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)

	--set @value = 0
	select @value = valor from ccSettings where setting_id = 191

	if @value = 0
		begin
			select -1, ''IVR''
			union
			select inbound_id, descripcion from ccInbound where inbound_id in
			(
				select inbound_id from ccInboundHorarios where horario_id in
				(
					select horario_id  from ccHorarios
					where
					( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
					AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
					AND (
						Lunes  = @dia or
						Martes *2 = @dia or
						Miercoles*3 = @dia or
						Jueves*4 = @dia or
						Viernes*5 = @dia or
						Sabado*6 = @dia or
						domingo*7 = @dia
					)
				)
			)
			and inbound_id <> @current
			-- las activas
			and status <> 0
			-- las que tienen agentes firmados
			-- and inbound_id  in ( select distinct inbound_id from ccInboundAgentes where user_id in ( select user_id from ccPosicion where user_id > 0 ))
			order by 2
		end

	if @value = 1
		begin
			if (@current <> 0)
				begin
					select -1, ''IVR''
					union
					select inbound_id, descripcion from ccInbound where inbound_id in
					(
						select inbound_id from ccInboundHorarios where horario_id in
						(
							select horario_id  from ccHorarios
							where
							( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
							AND (
								Lunes  = @dia or
								Martes *2 = @dia or
								Miercoles*3 = @dia or
								Jueves*4 = @dia or
								Viernes*5 = @dia or
								Sabado*6 = @dia or
								domingo*7 = @dia
							)
						)
					)
					and inbound_id <> @current
					-- las activas
					and status <> 0
					and IDArea in (select cu.IDArea from ccUsers cu join ccInbound ci on cu.IDArea = ci.IDArea where inbound_id =  @current)
					order by 2
				end
			else
				begin
					select -1, ''IVR''
					union
					select inbound_id, descripcion from ccInbound where inbound_id in
					(
						select inbound_id from ccInboundHorarios where horario_id in
						(
							select horario_id  from ccHorarios
							where
							( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
							AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
							AND (
								Lunes  = @dia or
								Martes *2 = @dia or
								Miercoles*3 = @dia or
								Jueves*4 = @dia or
								Viernes*5 = @dia or
								Sabado*6 = @dia or
								domingo*7 = @dia
							)
						)
					)
					and inbound_id <> @current
					-- las activas
					and status <> 0
					and IDArea in (
					select IDArea from ccUsers where User_id = @userID
					)
					-- las que tienen agentes firmados
					-- and inbound_id  in ( select distinct inbound_id from ccInboundAgentes where user_id in ( select user_id from ccPosicion where user_id > 0 ))
					order by 2
				end
		end'
	EXEC(@sql)

		set @process = 'Alter SP -- ccsp_SaveStatusAgent'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus int,
@TipoCall  tinyint,
@Camp smallint,
--@isTransferSurvey bit=0, --0 Callback, 1 Realiza Transferencia inmediata
@callout_id int=0,
@call_id int=0,
@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog int =0 ,
@currentStatus int =-2,--NUEVO PARÁMETRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null
AS
if @Fecha4 is null set @Fecha4 = getdate()

if @TipoCall > 0 set @TipoCall = @TipoCall - 1

if (@User_id > 0 ) begin

	declare @cam_id int,@surveycamId int
	declare @cal_telefono varchar(30)
	declare @cal_key varchar(20)
	declare @inbound_id int
	declare @callBackSurveyClients bit
	declare @cal_whoHung tinyint
	declare @cal_tDialog int
	declare @cal_tNotas int
	declare @cal_tNotaOri int
	declare @tMinAVRS smallint
	declare @calInicio datetime
	declare @sumCall int
	set @cal_tNotas =0
	set @cal_tNotaOri=0
	--4 Dialog,6 Notas, 27 Notas Fallida
	if @TipoStatusAge_id in (4,6,27) and @call_id>0 begin
		if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
		if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


		if @TipoCall = 0 begin --IN
			select @calInicio=cal_Xfer,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas, @Camp=Inbound_id, @cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas, @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
						from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13

			if @cal_tDialog = 0 and @tDialog >0  and @isLogout=1  begin
				if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
					set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
					if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
					if @TipoStatusAge_id=6  begin
						if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
						else  set @tDialog=@tDialog-1
					end
				end

				update ccCallsIN with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas where cal_id = @call_id and statusCall_id = 13
			end
		end
		else begin --OUT
			select @calInicio=cal_inicio,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,
			@cam_id = cam_id,@cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas from ccoCallsOut where cal_id = @call_id
			set @Camp=@cam_id

			if @cal_tDialog = 0 and @tDialog>0 and @isLogout=1  begin
				if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
					set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
					if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
					if @TipoStatusAge_id=6  begin
						if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
						else  set @tDialog=@tDialog-1
					end
				end

				update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas where cal_id = @call_id and statusCall_id = 13
			end
		end

		select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

		if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1
		begin
			insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
		end

		if @TipoStatusAge_id in(6,27)  and @isLogout=1  begin
			--Valida que el agente no pudo guardar el status antes de desloguear
			if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
				INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
		end


	end


	if (@TipoStatusAge_id=4) begin-- 4 = Dialogo
		declare @tStatus3 int, @Fecha3 datetime
		select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
		insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
		select @User_id, cam_id, datediff(ms, dateadd(ss, -@tStatus3, @Fecha3), dateadd(ss, -@tStatus, @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
		from cccampsagente where user_id = @User_id


		---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
		if @call_id>0 begin
			if @TipoCall = 0 begin --IN

					select @surveycamid = isnull(cam_id,0),@callBackSurveyClients = callBackSurveyClient  from ccinbound where inbound_id = @inbound_id

					if @surveycamId>0  and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
						if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
							begin
								if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100
								begin
									insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
									values(right((cast(@call_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()) )
								end
							end
					end
			end	--@TipoCall = 0
			else begin	--OUT



				select @surveycamId = isnull(surveycamid,0),@callBackSurveyClients= callBackSurveyClient from cccamps where cam_id = @cam_id
				select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono,@cal_whoHung=cal_whoHung
					from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
					where callout_id = @callout_id and statusCall_id = 13 and cal_id = @call_id

				if @surveycamId>0 and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
					if (select surveyPctg from ccCamps where cam_id = @surveycamId) >= rand() *100
					begin
						insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
						values(right((cast(@call_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()))
					end
				end
			end
		end--@isTransferSurvey = 0 and @callout_id>0


	 end


	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)	VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )


	if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
	begin
		INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )

		---Para Agente RIA: OAYC
		INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )
	end

	-- Actualiza para reporte de tiempos especiales (Boan)
	if @Camp > 0
		begin
			if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesDia with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end

			if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesNotReady with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
		end
end'
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