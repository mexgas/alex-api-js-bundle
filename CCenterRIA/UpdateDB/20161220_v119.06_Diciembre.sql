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
	Se agrega columna file_moved en ccoCallsOut y ccCallsIn

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

		set @process = 'validate if exists procedure [dbo].[ccsp_AgentTransfLstArea]'
		set @Sql= 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''ccsp_AgentTransfLstArea'')	DROP PROCEDURE ccsp_AgentTransfLstArea'
		EXEC(@sql)

		set @process = 'Drop SP -- ccsp_recordingStatus'
		set @Sql= 'if exists (select * from sys.procedures where name = N''ccsp_recordingStatus'') DROP PROCEDURE ccsp_recordingStatus'
		EXEC(@sql)


		set @process = 'Alter tabla ccoCallsOut'
		set @Sql= 'if not exists (select * from sys.columns where name = N''file_moved'' AND Object_ID = Object_ID(N''ccoCallsOut'') ) alter table ccoCallsOut add file_moved bit null'
		EXEC(@Sql)


		set @process = 'Alter tabla ccCallsIn'
		set @Sql= 'if not exists (select * from sys.columns where name = N''file_moved'' AND Object_ID = Object_ID(N''ccCallsIn'') ) alter table ccCallsIn add file_moved bit null'
		EXEC(@Sql)

		set @process = 'Alter tabla telefonosTransferencia'
		set @sql='if not exists (select * from sys.columns where name = N''IDArea'' AND object_id =object_id (N''telefonosTransferencia''))
		begin
		ALTER TABLE telefonosTransferencia ADD IDArea smallint
		end'
		EXEC(@sql)

		set @process = 'CREATE SP -- ccsp_recordingStatus'
		set @Sql= 'CREATE PROCEDURE [dbo].[ccsp_recordingStatus]
@callType int,
@id int,
@action int ,
@recordLocalization int
AS
begin
	if @action=0 begin
		declare @time int
		if @callType=0 begin
			select @time=cal_tDialog from ccoCallsOut where cal_id=@id
		end
		else begin
			select @time=cal_tDialog from ccCallsIn where cal_id=@id
		end
		select case when @time>0 then 1 else 0 end as result
	end
	else if @action=1 begin
		if @callType=0 begin
			update ccoCallsOut set file_moved=@recordLocalization where cal_id=@id
		end
		else begin
			update ccCallsIn set file_moved=@recordLocalization where cal_id=@id
		end
	end
end'
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

		set @process = 'Inser new Reports -- 2070'
		set @Sql= 'if not exists(select * from ccMenus where menu_id=2070 and type=3)begin
					insert into ccMenus (menu_id, menu_descrip,parent, Nivel,ordengral,type,HelpSWF,release)
					values(2070,''Estados de agente y llamadas por intervalo|Agent and Call Statuses By Interval'',2000,''B'',2,3,'''',''9845b8194326d000bbf125cc69f93b76c97e97d0bdd431f0e04d5b455413f8fa1c2f669901ecb5f36e912e128c22c6773da345481c0c9c50286221101986c4c4b2f637f3e469b15dd8dca1fca72b0b33'')
					end'
		EXEC(@sql)

		set @process = 'Inser new Reports -- 4170'
		set @Sql= 'if not exists(select * from ccmenus where type=3 and menu_id=4170)
					insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
					values(4170,''Gestión de base|Management Base'',4000,''B'',2,3,'''',''d71e103870d96b6765f2ee439d2af114fb6f5574587bad77cc997e68802daa13912b5a4be80d1256d25e18e75aaeeb3f'')
					'
		EXEC(@Sql)

		set @process = 'INSERT REPORT - Answered Calls by Dialing Retries '
		set @Sql='IF NOT EXISTS (SELECT * FROM [CCenterRia].[dbo].[ccmenus] WHERE [CCenterRia].[dbo].[ccmenus].[menu_id] = 4190 AND [CCenterRia].[dbo].[ccmenus].[type]=3)
		BEGIN
			INSERT INTO [CCenterRia].[dbo].[ccmenus]
			(menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release)
			VALUES
			(4190, ''Llamadas contestadas por reintentos|Answered Calls by Dialing Retries'', 4000, ''B'', 4, 3, '''', ''7f9603c7b03b294b1e3bf597edce2c5231780fd215b73ce2a47392e356505240828532309bfa5e501bdc0ca946b446e3d47e09947906ed2b769889561b55592a3df3d2390391a69a1fdc8527f37dfc3a'')
		END
		'
		EXEC(@Sql)

		set @process = 'INSERT REPORT - Answered Calls by Dialing Retries '
		set @Sql='IF NOT EXISTS (SELECT * FROM [CCenterRia].[dbo].[ccmenus] WHERE [CCenterRia].[dbo].[ccmenus].[menu_id] = 2080 AND [CCenterRia].[dbo].[ccmenus].[type]=3)
		BEGIN
			INSERT INTO [CCenterRia].[dbo].[ccmenus]
			(menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release)
			VALUES
			(2080, ''Detalle de agente por día|Agent Detail by Day'', 2000, ''B'', 2, 3, '''',''eefae185aa125f584d532e0f80546a1fef657d9b4f60d1d23e66b78ef93ded3a0c9d78f2b1ec9493136e6cdae061236c'')
		END
		'
		EXEC(@Sql)

		set @process = 'UPDATE ccsetting 190'
		set @sql='if  exists(select * from ccsettings where setting_id=190)
		begin
		UPDATE ccSettings set description = ''Calls percentage by second'' where setting_id = 190
		end'
		EXEC(@sql)

		set @process = 'UPDATE ccsetting 191'
		set @sql='if  exists(select * from ccsettings where setting_id=191)
		begin
		UPDATE ccSettings set description = ''Display transfer directory by area'' where setting_id = 191
		end'
		EXEC(@sql)

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

		set @process = 'Alter SP  -- ccsp_RIA_ABCAgents'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
@option smallint,
@UserId int,
@Login varchar(20)='''',
@Nombres varchar(25)=null,
@ApellidoPaterno varchar(25)='''',
@ApellidoMaterno varchar(25)='''',
@Password varchar(33)='''',
@Sexo bit=null,
@canChangeStatus bit=null,
@AreaId int=null,
@UserType tinyint=1,
@IDWG int=0,
@DeleteUsers int=1,
@inOut int=null,
@IDCampEsp int=null,
@multipleUsers varchar(1000)=null
as
set nocount on

if @option=0--All Users
	begin
	select User_id,Login,ISnull(AREas.AreaName,'''')as AreaName

from ccusers as users with(nolock)
		left join ccRIACat_Areas as areas with(nolock)
		on users.IDArea=areas.IDArea
	return(0)
	end

if @option=1--selected User
	begin
	select User_id,Login,Nombres,isnull(apellidoPaterno,''''),
		isnull(ApellidoMaterno,''''),Sexo,canChangeStatus,isnull(IDArea,0),tipouser_id
	from ccusers where User_id=@UserId
	order by IDArea,Nombres,ApellidoPaterno,User_id
	return(0)
	end

if @option=2--insert
	begin
	if exists(select Login from ccUsers where Login=@Login)
		begin
		select -1--,''Login en Uso''
		return(0)
		end

	if exists(select Login from ccUsers_Consulta where Login = @Login)
	begin
		select -4 -- ''Login habia estado en Uso''
		return(0)
	end

	if exists(select Nombres from ccUsers where Nombres=@Nombres
	and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
		begin
		select -2--,''Nombre en Uso''
		return(0)
		end

IF( select isnull(max(user_id),0) from ccusers) > 32700
BEGIN
	set @UserId = null
	SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
	FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
	LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
	INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
	FROM ccusers) AS w ON w.recID = d.recID

	if @UserId is null
	begin
		select -2--insert Error
		return(0)
	end

	set identity_insert ccusers on
	insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
		Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
	select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
		1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
	set identity_insert ccusers off

	delete ccMenuUser where id_User = @UserId
	delete ccRIAUserRole where user_id = @UserId

	exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

END
ELSE
BEGIN
	insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
		Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
	select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
		1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

	if @@rowcount=1
		select @UserId=scope_identity()
	else
		begin
		select -2--insert Error
		return(0)
		end
END
	insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
	insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
	insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
	--Menu para roles RepotsRia
	exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

	select @UserId,''Usuario '' + @Login + '' Dado de Alta''
	return(0)
	end

if @option=3--Update
	begin
	if @Login='''' and @Password <> ''''
		begin
		Update ccUsers set Password=@Password where User_id=@UserId
		return(0)
		end

	Update ccUsers
	set Login= case when @Login <> '''' then @Login else Login end,
	Nombres=@Nombres,
	ApellidoPaterno=@ApellidoPaterno,ApellidoMaterno=@ApellidoMaterno,
	Password=case when @Password <> '''' then @Password else Password end,
	Sexo=@Sexo,canChangeStatus=@canChangeStatus where User_id=@UserId
	return(0)
	end

if @option=4--Delete
	begin
	delete from ccSkills where User_id=@UserId
	delete from ccMenu_ViewsUser where user_id =@UserId
	delete from dbo.ccRIAWorkGroupUsers where user_id =@UserId
	delete from ccUsers where user_id=@UserId
	return(0)
	end

declare @Type tinyint, @users int,@sql varchar(8000), @NinOut nvarchar(10)

if @option=5--insert Agente-Supervisor in WorkGroup
	begin
	select @Type=TipoUser_id from ccUsers where User_id=@UserId

	if @Type not in(1,2,6)
		return(0)

	if @Type=1 and((select count(User_id)from ccRIAWorkGroupUsers where User_id=@UserId)>=(select valor from ccSettings where setting_id=63))
		begin
		select 3
		return(0)
		end

	if exists(select @UserId from ccRIAWorkGroupUsers where User_id=@UserId and IDWG=@IDWG)
		begin
		select 1
		return(0)
		end

	insert into ccRIAWorkGroupUsers(IDWG,User_id)values(@IDWG,@UserId)

	if @Type=1
		begin

		if @IDWG is null or @IDWG = 0
			begin
			select 28
			return(0)
			end
		insert into cccampsAgente(user_id,cam_id,prioridad,skill,IDWG)

		select @UserId,idCampEsp,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
		from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
			and idCampEsp not in(select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

		insert into ccinboundAgentes(User_id,Inbound_id,cli_id,prioridad,skill,IDWG)
		select @UserId,idCampEsp,0,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
		from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
			and idCampEsp not in(select inbound_id from ccinboundAgentes where user_id=@UserId and IDWG=@IDWG)

		return(0)
		end

--else @Type=2 or @Type=6--Supervisor
	insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
	select @UserId,idCampEsp,0,@IDWG
	from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
		and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

	insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
	select @UserId,idCampEsp,1,@IDWG
	from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
		and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
	return(0)
	end

if @option=6--Delete Agent-Supervisor from WorkGroup
	begin
	if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)=0
		select @UserId = @multipleUsers

	else if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)>0
		select @UserId = cast(substring(@multipleUsers, 1,
		CHARINDEX('','', @multipleUsers)-1) as int)

		select @Type=case when @UserType <> 0 then @UserType else TipoUser_id end,
		@multipleUsers=isnull(@multipleUsers,cast(@Userid as varchar(10)))
	from ccUsers where User_id=@UserId

	Declare @sqlDelete nvarchar(4000)
	if @Type in(1,2,6)--1:Agente / 2,6:Supervisor
		begin
		set @sqlDelete=N''Delete from '' + case @Type when 1 then ''cccampsagente where '' else ''ccSupervisorCam where tipo=0 and '' end
		+ ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
		+ '' Delete from '' + case @Type when 1 then ''ccinboundagentes where '' else ''ccSupervisorCam where tipo=1 and '' end
		+ ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
		exec(@sqlDelete)
		end

	if isnull(@UserId, 0) = 0 or isnull(@multipleUsers, ''0'') = ''0''
		begin
		select -9 -- Se ingreso mal el id del usuario
		--delete ccinboundagentes where idwg=@IDWG
		--delete cccampsagente where idwg=@IDWG
		--delete ccSupervisorCam where idwg=@IDWG
		end

	if @DeleteUsers=1
		Delete ccRIAWorkGroupUsers where IDWG=@IDWG and User_id=@UserId

	return(0)
	end

if @option=7--Delete Agent from WorkGroup
	begin
	select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end
	set @sql=''delete '' + case @NinOut when ''1'' then ''ccCampsAgente'' else ''ccInboundAgentes'' end +
		'' where user_id in('' + isnull(@multipleUsers, ''0'') +'') and '' + case @NinOut when ''1'' then ''cam_id'' else ''inbound_id'' end +
		''='' + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' + cast(@IDWG as varchar(10)) +
		'' delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
	exec(@sql)
return(0)
	end

if @option=8--Delete Supervisor from WorkGroup
	begin
	select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end

	set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and user_id in('' + isnull(@multipleUsers, ''0'') + '') and cam_id=''
		+ cast(@IDCampEsp as varchar(10)) + '' and IDWG='' +cast(@IDWG as varchar(10)) + ''
		delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
	exec(@sql)

	set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and cam_id='' + cast(@IDCampEsp as varchar(10)) + ''and '' +
		''user_id in ('' + isnull(@multipleUsers, ''0'') + '') and IDWG='' + cast(@IDWG as varchar(10))
	exec(@sql)
	return(0)
	end

if @option=9
	begin
	update ccusers set NotReadyRestricted=@canChangeStatus where [User_id]=@UserId
	return(0)
	end
set nocount off'
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
		set @sql='if not exists (select * from ccSettings where setting_id=190)
					INSERT INTO ccSettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate) VALUES (190, ''0'',''Porcentaje de limite de llamadas por segundo'',1,''ADM'',''0 funcion inhabilitada, 1-100 porcentaje de puertos de salida por segundo'',''Percent of limit of calls per seconds'',1,''^(100|\d{1,2})$'')'
		EXEC(@sql)

		set @process = 'Insert ccSettings -- Telephone transfer list'
		set @sql='if not exists (select * from ccSettings where setting_id=191)
					INSERT INTO ccSettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate) VALUES (191, ''0'',''Restringir transferencia de llamadas por área'',1,''GRL'',''1:Activar 0:Desactivar'',''Restrict transfer directory by area'',1,''^[0-1]$'')'
		EXEC(@sql)


set @process = 'Insert ccSettings -- Hold Timer'
	set @sql='if not exists (select * from ccSettings where setting_id=193)
	insert ccsettings (setting_id,valor,descripcion,status,tipo,detalle,description,bLoadSettings,validate)
	values (193,''0|30'',''Configuración para mostrar el tiempo en Hold'',1,''AGT'',''[0:Desactivado/1:Activo/2:ActivoReset]|[Segundos Alerta]'',''Hold Timer Configuration'',1,''^[012]\|[\d]+$'')'
EXEC(@sql)


		set @process = 'Insert ccSettings -- hide the call queue in agent'
		set @sql='if not exists (select * from ccSettings where setting_id = 192)
				 begin 
					insert into ccSettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate) values(192, 1, ''Hide the queue call in agent|Mostrar cola ACD en agente'', 1, ''GRL'', ''1 Muestra la Lista 0 Lista Oculta'', ''Hide the queue call in agent'', 1, ''^[0-1]$'')
				 end '
		EXEC(@sql)


		set @process = 'validate if exists procedure [dbo].[ccsp_AgentTransfLstArea]'
		set @Sql= 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''ccsp_AgentTransfLstArea'')	DROP PROCEDURE ccsp_AgentTransfLstArea'
		EXEC(@sql)

		set @process = 'Drop sp ccsptelefonosTransferencia'
		set @sql='if exists (select * from sys.procedures where name = N''ccsptelefonosTransferencia'') 
		DROP PROCEDURE [dbo].[ccsptelefonosTransferencia]'
		EXEC(@sql)

		set @process = 'Create SP -- ccsptelefonosTransferencia'
		set @sql='CREATE PROCEDURE [dbo].[ccsptelefonosTransferencia]
		@userID INT
		as
		set nocount on

		BEGIN
		declare @value bit
		declare @IDArea int
		set @value = 0
		set @IDArea =1
		select @value = case when valor=''1'' then 1 else 0 end from ccSettings where setting_id = 191

		select @IDArea =IDArea from ccUsers where User_id = @userID

		if @value = 1
			begin	
			if @value = 1 begin	
				select numtra_id id, nombre name, tel number, isnull(IDArea,@IDArea) from telefonosTransferencia where idarea= @IDArea or IDArea is null order by nombre	
			end
			else
				begin
					select numtra_id id, nombre +'' ''+cast(numtra_id as varchar(20) )  name, tel number, isnull(IDArea,@IDArea) from telefonosTransferencia  order by nombre
				end
			end
		END'
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

set @process = 'Alter SP ccsp_RIACAT_PhoneConfig'
set @sql='ALTER proc [dbo].[ccsp_RIACAT_PhoneConfig]
@Type tinyint, -- 1:Show #conf | 2:Add #conf | 3:Upd #conf | 4:Del #conf | 5:Add #tran | 6:Upd #tran | 7:Del #tran | 8: Show #tran
@CT_id SmallInt=0, 
@Nombre varchar(50)='''',
@Telefono varchar(50)='''',
@IDArea smallint = 0 --parametro IDarea
as
set nocount on

BEGIN
declare @value bit

select @value = case when valor =''1'' then 1 else 0 end from ccSettings where setting_id = 191

if @Type=1
 begin
	select numcon_id id, nombre name, tel number from telefonosConferencia order by nombre
	return(0)
 end

if @Type=2
 begin
	IF exists (select numcon_id from telefonosConferencia where nombre=@Nombre)
	 begin
		select -3 -- El nombre ya esta asignado
		return(0)
	 end

	IF exists (select numcon_id from telefonosConferencia where tel=@Telefono)
	 begin
		select -4 -- El telefono ya esta asignado
		return(0)
	 end

	insert into telefonosConferencia (nombre, tel) select @Nombre, @Telefono
	select SCOPE_IDENTITY() numcon_id
	return(0)
 end

if @Type=3
 begin
 	IF exists (select numcon_id from telefonosConferencia where nombre=@Nombre and numcon_id<>@CT_id)
	 begin
		select -5 -- El nombre ya esta asignado
		return(0)
	 end

 	IF exists (select numcon_id from telefonosConferencia where tel=@Telefono and numcon_id<>@CT_id)
	 begin
		select -6 -- El telefono ya esta asignado
		return(0)
	 end

	update telefonosConferencia set nombre=@Nombre, tel=@Telefono where numcon_id=@CT_id
	return(0)
 end

if @Type=4
 begin
	delete telefonosConferencia where numcon_id=@CT_id
	return(0)
 end

if @Type=5
 begin
	IF exists (select numtra_id from telefonosTransferencia where nombre=@Nombre and IDArea=@IDArea)
	 begin
		select -3 -- El nombre ya esta asignado
		return(0)
	 end
	 
	 	IF exists (select numtra_id from telefonosTransferencia where tel=@Telefono and IDArea=@IDArea)
	 begin
		select -4 -- El telefono ya esta asignado
		return(0)
	 end

	insert into telefonosTransferencia (nombre, tel, IDArea) select @Nombre, @Telefono,@IDArea --se agrega IDArea 
	select SCOPE_IDENTITY() numtra_id
	return(0)
 end

if @Type=6
 begin
 	IF exists (select numtra_id from telefonosTransferencia where nombre=@Nombre and numtra_id<>@CT_id and IDArea=@IDArea )
	 begin
		select -5 -- El nombre ya esta asignado
		return(0)
	 end

 	IF exists (select numtra_id from telefonosTransferencia where tel=@Telefono and numtra_id<>@CT_id and IDArea=@IDArea )
	 begin
		select -6 -- El telefono ya esta asignado
		return(0)
	 end

	update telefonosTransferencia set nombre=@Nombre, tel=@Telefono where numtra_id=@CT_id and IDArea=@IDArea
	return(0)
 end

if @Type=7
 begin
	delete telefonosTransferencia where numtra_id=@CT_id
	return(0)
 end

if @Type=8
 begin	
	if @value = 1 
	begin	
		select numtra_id id, nombre name, tel number, isnull(IDArea,@IDArea) from telefonosTransferencia where idarea= @IDArea or IDArea is null order by nombre	
	end
	else
	begin
		select numtra_id id, cast(IDArea as varchar(20) )+'' - ''+  nombre name, tel number, isnull(IDArea,@IDArea) from telefonosTransferencia  order by nombre	
	end
	return(0)
 end

return(0)
set nocount off
end'
EXEC(@sql)

set @process = 'ALTER SP ccsp_AgentTransfLstArea'
set @sql='ALTER PROCEDURE [dbo].[ccsp_AgentTransfLstArea]
@userID INT,
@current INTEGER = 0
AS
set nocount on

BEGIN
declare @value int

set @value = 0
select @value = case when valor=''1'' then 1 else 0 end from ccSettings where setting_id = 191 

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

set @process = 'SP Alter ccsp_AgentGetEspecialidadesActivas'
set @sql='ALTER procedure [dbo].[ccsp_AgentGetEspecialidadesActivas]
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

	set @value = 0 
	select @value = case when valor=''1'' then 1 else 0 end from ccSettings where setting_id = 191

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

	set @value = 0
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

		set @process = 'Alter SP  -- ccsp_RIA_ABCAgents'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
@option smallint,
@UserId int,
@Login varchar(20)='''',
@Nombres varchar(25)=null,
@ApellidoPaterno varchar(25)='''',
@ApellidoMaterno varchar(25)='''',
@Password varchar(33)='''',
@Sexo bit=null,
@canChangeStatus bit=null,
@AreaId int=null,
@UserType tinyint=1,
@IDWG int=0,
@DeleteUsers int=1,
@inOut int=null,
@IDCampEsp int=null,
@multipleUsers varchar(1000)=null
as
set nocount on

if @option=0--All Users
	begin
	select User_id,Login,ISnull(AREas.AreaName,'''')as AreaName

from ccusers as users with(nolock)
		left join ccRIACat_Areas as areas with(nolock)
		on users.IDArea=areas.IDArea
	return(0)
	end

if @option=1--selected User
	begin
	select User_id,Login,Nombres,isnull(apellidoPaterno,''''),
		isnull(ApellidoMaterno,''''),Sexo,canChangeStatus,isnull(IDArea,0),tipouser_id
	from ccusers where User_id=@UserId
	order by IDArea,Nombres,ApellidoPaterno,User_id
	return(0)
	end

if @option=2--insert
	begin
	if exists(select Login from ccUsers where Login=@Login)
		begin
		select -1--,''Login en Uso''
		return(0)
		end

	if exists(select Login from ccUsers_Consulta where Login = @Login)
	begin
		select -4 -- ''Login habia estado en Uso''
		return(0)
	end

	if exists(select Nombres from ccUsers where Nombres=@Nombres
	and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
		begin
		select -2--,''Nombre en Uso''
		return(0)
		end

IF( select isnull(max(user_id),0) from ccusers) > 32700
BEGIN
	set @UserId = null
	SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
	FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
	LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
	INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
	FROM ccusers) AS w ON w.recID = d.recID

	if @UserId is null
	begin
		select -2--insert Error
		return(0)
	end

	set identity_insert ccusers on
	insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
		Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
	select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
		1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
	set identity_insert ccusers off

	delete ccMenuUser where id_User = @UserId
	delete ccRIAUserRole where user_id = @UserId

	exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

END
ELSE
BEGIN
	insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
		Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
	select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
		1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

	if @@rowcount=1
		select @UserId=scope_identity()
	else
		begin
		select -2--insert Error
		return(0)
		end
END
	insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
	insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
	insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
	--Menu para roles RepotsRia
	exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

	select @UserId,'' Usuario '' + @Login + '' Dado de Alta''
	return(0)
	end

if @option=3--Update
	begin
	if @Login='''' and @Password <> ''''
		begin
		Update ccUsers set Password=@Password where User_id=@UserId
		return(0)
		end

	Update ccUsers
	set Login= case when @Login <> '''' then @Login else Login end,
	Nombres=@Nombres,
	ApellidoPaterno=@ApellidoPaterno,ApellidoMaterno=@ApellidoMaterno,
	Password=case when @Password <> '''' then @Password else Password end,
	Sexo=@Sexo,canChangeStatus=@canChangeStatus where User_id=@UserId
	return(0)
	end

if @option=4--Delete
	begin
	delete from ccSkills where user_id =@UserId
	delete from ccMenu_ViewsUser where user_id =@UserId
	delete from dbo.ccRIAWorkGroupUsers where user_id =@UserId
	delete from ccUsers where user_id=@UserId
	return(0)
	end

declare @Type tinyint, @users int,@sql varchar(8000), @NinOut nvarchar(10)

if @option=5--insert Agente-Supervisor in WorkGroup
	begin
	select @Type=TipoUser_id from ccUsers where User_id=@UserId

	if @Type not in(1,2,6)
		return(0)

	if @Type=1 and((select count(User_id)from ccRIAWorkGroupUsers where User_id=@UserId)>=(select valor from ccSettings where setting_id=63))
		begin
		select 3
		return(0)
		end

	if exists(select @UserId from ccRIAWorkGroupUsers where User_id=@UserId and IDWG=@IDWG)
		begin
		select 1
		return(0)
		end

	insert into ccRIAWorkGroupUsers(IDWG,User_id)values(@IDWG,@UserId)

	if @Type=1
		begin

		if @IDWG is null or @IDWG = 0
			begin
			select 28
			return(0)
			end
		insert into cccampsAgente(user_id,cam_id,prioridad,skill,IDWG)

		select @UserId,idCampEsp,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
		from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
			and idCampEsp not in(select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

		insert into ccinboundAgentes(User_id,Inbound_id,cli_id,prioridad,skill,IDWG)
		select @UserId,idCampEsp,0,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
		from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
			and idCampEsp not in(select inbound_id from ccinboundAgentes where user_id=@UserId and IDWG=@IDWG)

		return(0)
		end

--else @Type=2 or @Type=6--Supervisor
	insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
	select @UserId,idCampEsp,0,@IDWG
	from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
		and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

	insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
	select @UserId,idCampEsp,1,@IDWG
	from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
		and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
	return(0)
	end

if @option=6--Delete Agent-Supervisor from WorkGroup
	begin
	if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)=0
		select @UserId = @multipleUsers

				else if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)>0
					select @UserId = cast(substring(@multipleUsers, 1,
					CHARINDEX('','', @multipleUsers)-1) as int)

		select @Type=case when @UserType <> 0 then @UserType else TipoUser_id end,
		@multipleUsers=isnull(@multipleUsers,cast(@Userid as varchar(10)))
	from ccUsers where User_id=@UserId

	Declare @sqlDelete nvarchar(4000)
	if @Type in(1,2,6)--1:Agente / 2,6:Supervisor
		begin
		set @sqlDelete=N''Delete from '' + case @Type when 1 then ''cccampsagente where '' else ''ccSupervisorCam where tipo=0 and '' end
		+ ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
		+ '' Delete from '' + case @Type when 1 then ''ccinboundagentes where '' else ''ccSupervisorCam where tipo=1 and '' end
		+ ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
		exec(@sqlDelete)
		end

	if isnull(@UserId, 0) = 0 or isnull(@multipleUsers, ''0'') = ''0''
		begin
		select -9 -- Se ingreso mal el id del usuario
		--delete ccinboundagentes where idwg=@IDWG
		--delete cccampsagente where idwg=@IDWG
		--delete ccSupervisorCam where idwg=@IDWG
		end

	if @DeleteUsers=1
		Delete ccRIAWorkGroupUsers where IDWG=@IDWG and User_id=@UserId

	return(0)
	end

if @option=7--Delete Agent from WorkGroup
	begin
	select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end
	set @sql=''delete '' + case @NinOut when ''1'' then ''ccCampsAgente'' else ''ccInboundAgentes'' end +
		'' where user_id in('' + isnull(@multipleUsers, ''0'') +'') and '' + case @NinOut when ''1'' then ''cam_id'' else ''inbound_id'' end +
		''='' + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' + cast(@IDWG as varchar(10)) +
		'' delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
	exec(@sql)
return(0)
	end

if @option=8--Delete Supervisor from WorkGroup
	begin
	select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end

				set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and user_id in('' + isnull(@multipleUsers, ''0'') + '') and cam_id=''
					+ cast(@IDCampEsp as varchar(10)) + '' and IDWG='' +cast(@IDWG as varchar(10)) + ''
					delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
				exec(@sql)

	set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and cam_id='' + cast(@IDCampEsp as varchar(10)) + ''and '' +
		''user_id in ('' + isnull(@multipleUsers, ''0'') + '') and IDWG='' + cast(@IDWG as varchar(10))
	exec(@sql)
	return(0)
	end

if @option=9
	begin
	update ccusers set NotReadyRestricted=@canChangeStatus where [User_id]=@UserId
	return(0)
	end
set nocount off'
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_RIAChecaLogin'
		set @Sql= '
		ALTER PROCEDURE [dbo].[ccsp_RIAChecaLogin]
				@Login varchar(20),
				@Password varchar(40),
				@Computer varchar(20),
				@PasswordLwC varchar(40) = null
				AS
				declare @LoginOK tinyint, @PswdOK tinyint, @CompuOK tinyint, @ExtenOK tinyint, @TeclaOK tinyint, @XferAgents tinyint
				declare @Nombre varchar(60), @Extension varchar(15), @UserID smallint, @CCServer varchar(20)

				--Para posiciones ip, by ODC
				declare @ext_id int, @pos_id int, @isIP bit, @ipExtension varchar(15)

				-- Para live connected
				-- Tipo de conexion: 0 normal, 1 liveconnected
				declare @tipoConexion smallint

				SELECT @LoginOK=0, @PswdOK=0, @CompuOK=0, @ExtenOK=0, @TeclaOK=0, @XferAgents=0,
				 @Extension='' '', @UserID='' '', @Nombre='' '', @tipoConexion = 0, @ipExtension='''', @isIP=0
				SELECT @CCServer=valor FROM ccSettings WHERE setting_id=7

				IF not exists(select Login from ccUsers Where Login=@Login and status>0 and tipoUser_id=1)
					GOTO Mostrar
				else
					set @LoginOK=1

				IF not exists(select Login from ccUsers Where Login = @Login
				 AND (Password=@Password OR Password = dbo.md5(@password) OR dbo.md5(Password)=@Password
				 or Password=@PasswordLwC OR Password = dbo.md5(@PasswordLwC) OR dbo.md5(Password)=@PasswordLwC)
				 and status > 0 and tipoUser_id = 1)
					GOTO Mostrar
				else
					set @PswdOK=1

				-- Se actualiza a Lower Case
				update ccUsers with(rowlock) set Password=isnull(@PasswordLwC, Password) where Login=@Login and status>0 and tipoUser_id=1

				if not exists (select Computer from ccPosicion Where Status=1 and Computer=@Computer)
					insert ccposicion (computer, ext_id) select @Computer, 0

				set @CompuOK = 1

				if not exists(select Computer from ccPosicion P join ccMonitorExt M on P.ext_id= M.ext_id
				 Where p.Status=1 and M.Status=1 and Computer=@Computer)
					GOTO Mostrar
				else
					set @ExtenOK=1

				select @Extension=Extension, @ext_id=p.ext_id, @pos_id=p.pos_id, @tipoConexion=p.tipoConexion, @isIP=isIP
				from ccPosicion P join  ccMonitorExt M on P.ext_id= M.ext_id
				Where Computer = @Computer

				select @TeclaOK=count(*) from ccTeclaExtensionPuerto T join ccMonitorExt M on T.ext_id=M.ext_id where M.Extension=@Extension

				select @UserID=user_id, @Nombre=Nombres + '' '' + isnull(ApellidoPaterno,'''') + '' '' +isnull(ApellidoMaterno,''''), @XferAgents=XferAgents
				from ccUsers Where Login = @Login AND TipoUser_id=1 AND status = 1

				Mostrar:
				--Para posiciones ip, by ODC
				-- No verifica ccTeclaExtensionPuerto, @TeclaOK =1
				-- Regresa un etension ''virtual''.  Debe ser diferente a cualquiera de ccMonitorExt.Extension
				IF @ext_id=0
				 BEGIN
					select @TeclaOK =1, @Extension=cast(@pos_id * -1 as varchar(15))
				 END

				---Por OAYC IPExtension, extension, para cuando es posición IP con alguna extension asignada
				IF(@ext_id > 0  and @isIP=1)
				 BEGIN
					select @TeclaOK =1, @ipExtension = @Extension, @Extension = cast( @pos_id * -1 as varchar(15))
				 END
				-----------

				IF @tipoConexion = 1
					select @TeclaOK =1

				--	CRMx
				DECLARE @crmxActive TINYINT
				SET @crmxActive = 0
				IF (SELECT COUNT(setting_id) FROM ccsettings WHERE setting_id = 168) = 1
					BEGIN
						SELECT @crmxActive = valor FROM ccsettings WHERE setting_id = 168
					END


				SELECT @LoginOK as [LoginOK], @PswdOK as [PswdOK], @CompuOK as [CompuOK], @ExtenOK as [ExtenOK], @Extension as [Extension],
@UserID as [UserID], @Nombre as [Nombre], @CCServer as [CCServer], @TeclaOK as TeclaOK, @tipoConexion as TipoConexion, @ipExtension as ipExtension,
@XferAgents as XferAgents, @crmxActive as [CRMx]
		'
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_RIAADMChecaLogin'
		set @Sql= '
		ALTER PROCEDURE [dbo].[ccsp_RIAADMChecaLogin]
			@Login varchar(20) = '''',
			@Password varchar(40) = '''',
			@PasswordLwC varchar(40) = null,
			@adminId int = 0

			as
			set nocount on

			declare @x int
			set @x=1

			if @adminId <> 0
				begin
					update ccUsers set onLine = 0 where User_id = @adminId
					return(0)
				end

			declare @UserID smallint
			--****
			declare @TipoUser_idx int
			declare @ver int
			declare @changeRecDisposition int
			set @ver = 0
			set @changeRecDisposition = 0

			--****
			select @UserID=User_id,@TipoUser_idx=TipoUser_id from ccUsers Where Login=@Login AND TipoUser_id in(2,6) and status>0

			if(@TipoUser_idx=2 or @TipoUser_idx=6)
			begin
			 if exists (SELECT * FROM ccRIAUsr_AdminPermissions WHERE User_id=@UserID and per_id in (2,6))
			 begin
				set @ver = 1
			 end
			 if exists (SELECT * FROM ccRIAUsr_AdminPermissions WHERE User_id=@UserID and per_id=7)
			 begin
				set @changeRecDisposition = 1
			 end
			end

			if not exists (select Login from ccUsers Where User_id=@UserID
			AND(Password=@Password OR Password = dbo.md5(@password) OR dbo.md5(Password)=@Password
			OR Password=@PasswordLwC OR Password = dbo.md5(@PasswordLwC) OR dbo.md5(Password)=@PasswordLwC))
			 begin
				SELECT case when @UserID is null then 0 else 1 end ''LoginOK'', 0 ''PswdOK'', 0 ''UserID'', 0 ''Nombre'', 0 ''ADMServer'', 0 ''AreaId'', 0 ''viewavrs'',0 ''changeRecDisposition''
				return(0)
			 end

			update ccUsers set Password=isnull(@PasswordLwC, Password) Where User_id=@UserID and Password<>@PasswordLwC

			update ccUsers set onLine = 1 where User_id = @UserID

			Select 1 ''LoginOK'', 1 ''PswdOK'', User_id ''UserID'',
			 Nombres +'' ''+ isnull(ApellidoPaterno,'''') +'' ''+isnull(ApellidoMaterno,'''') ''Nombre'',
			 (SELECT valor FROM ccSettings WHERE setting_id=8) [ADMServer],
			  isnull(IDArea,0) ''AreaId'',
			 @ver  ''ViewAvrs'', @changeRecDisposition  ''changeRecDisposition''
			From ccUsers Where User_id=@UserID
			return(0)
			set nocount off'
		EXEC(@Sql)

		set @process = 'Alter SP  -- ccsp_Limpia'
		set @Sql= '
		ALTER procedure [dbo].[ccsp_Limpia]
			@tel varchar(30),
			@Camp int = 0
			as
			set nocount on
			declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint
			select @tel = dbo.limpia(@tel)
			select @lon = len(@tel)
			select @pais = valor from ccSettings with(nolock) where setting_id = 104
			select @ld = valor from ccSettings with(nolock) where setting_id = 17
			select @extLen = valor from ccsettings with(nolock) where setting_id = 108
			declare @telTemp as varchar(15)

			if @extLen=@lon and @lon>1
			 begin
				select 0 as res, @tel as tel -- Extension
				return(0)
			 end

			if @pais = 1
			 begin
				if @lon = 3 and @tel = ''911''
				begin
					select 4 as res, @tel as tel
					return(0)
				end

				if @lon < 7 or @lon = 7 and len(@ld) = 2 or @lon = 8 and len(@ld) = 3 or @lon in (9, 11) or @lon > 13
				 begin
					select 1 as res, @tel as tel --Longitud invalida
					return(0)
				 end

				if @lon = 12 and left(@tel, 2) <> ''01'' or @lon = 13 and left(@tel, 3) <> ''044'' and left(@tel, 3) <> ''045'' and left(@tel, 3) <> ''001''
				 begin
					select 2 as res, @tel as tel--Digitos incorrectos
					return(0)
				 end

				if left(@tel, 3) = ''001''
				 begin
					select 0 as res, @tel as tel
					return(0)
				 end

				declare @mod varchar(5)
				select @tel = case when @lon in (7, 8) then @ld + @tel else right(@tel, 10) end
				select @mod = modalidad from series where cld + serie = left(@tel, 6) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

				if exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra))
				on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
				 begin
					select 4 as res, @tel as tel
					return(0)
				 end

				if @mod = ''CPP''
				 begin
					select 0 as res, case left(@tel, len(@ld)) when @ld then ''044'' else ''045'' end + @tel as tel
					return(0)
				 end

				if @mod in (''FIJO'', ''MPP'')
				 begin
					select 0 as res, case left(@tel, len(@ld)) when @ld then right(@tel, 10 - len(@ld)) else ''01'' + @tel end as tel
					return(0)
				 end

				--if @mod is null
				select 3 as res, @tel as tel--No encontrado
				return(0)
			 end

			if @pais = 2
			 begin
				select @telTemp = @tel
				set @tel = dbo.completa(@tel, @pais, @ld)
				if left(@tel,1)=''E'' begin
					select 1 as res, @telTemp --Longitud Invalida
					return
				end

				select @tel = dbo.fnClearPhoneArg(@tel)

				if (len(@tel) = 10 or len(@ld + @tel) = 10) and left(@tel,1) <> ''E'' begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and (telefono = @tel or telefono= @ld + @tel) and status=1)
				   begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					end else begin
						select 4 as res, @tel
						return(0)
					end
				end else begin select 2 as res, @telTemp as tel end --Digitos incorrectos
			 end

			if @pais = 3
			 begin
				select @telTemp = @tel
				if @lon < 7 or @lon = 9 or (@lon = 10 and  left(@telTemp,1) <> ''3'') or (@lon = 11 and  left(@telTemp,2) <> ''03'') begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				end
				select @tel = dbo.Completa_ListaNegra(@tel)

				if (len(@tel) = 8 or len(@tel) = 10) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 4
			 begin
				exec ccsp_LimpiaUsa @tel, @Camp
				return(0)
			 end

			if @pais = 5
			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)

				if len(@tel) in(8,9) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 6
			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)


				if len(@tel) = 10 and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 7

			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)

				if (len(@tel) = 9 or len(@tel) = 10) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin

						select @tel = dbo.verifica(@tel)
						if left(@tel,1)=''E'' begin
							select 3 as res, @telTemp -- No existe el telefono
						end
						else begin
							select 0 as res, @telTemp  -- Todo Bien
						end
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel --lista negra
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end


			if @pais = 8
			 begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)

				if left(@tel,1)=''E'' begin
					select 1 as res, @telTemp --Longitud Invalida
					return (0)
				end

				if (len(@tel) = 9 or len(@tel) = 10 or len(@tel) = 11 )
				begin
					if not exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra)) on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					end
					else
					begin
						select 4 as res, @tel
						return(0)
					end
				end
			 end

			if @pais = 9 --Australia
			 begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)

				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			 end

			if @pais = 10 -- Brasil
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				set @lon = len(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 11 -- Guatemala
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 12 -- Costa Rica
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 13 -- Salvador
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 14 -- Spain
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end  '
		EXEC(@Sql)

		set @process = 'validate if exists procedure [dbo].[ccspOtherDetails]'
		set @Sql= 'IF EXISTS (SELECT * FROM sys.objects WHERE type = ''P'' AND name = ''ccspOtherDetails'')	DROP PROCEDURE ccspOtherDetails'
		EXEC(@sql)

		set @process = 'Create procedure -- [dbo].[ccspOtherDetails]'
		set @sql = 'CREATE PROCEDURE [dbo].[ccspOtherDetails]
					@action as tinyint,
					@cam_id as tinyint,
					@to as datetime = null
					AS
					BEGIN
					SET ANSI_WARNINGS off
					SET NOCOUNT ON
					SELECT count(tipoResDial_id) as num, cam_id, tipoResDial_id, 
						 disconnectCause, convert(varchar(10),fecha,120) as [fecha]
					 FROM ccoLogDials
					 WHERE tipoResDial_id = 8
					 AND cam_id = @cam_id
					 AND convert(varchar(10),fecha,120) = convert(varchar(10),GETDATE(),120)
					 group by cam_id, tipoResDial_id, disconnectCause, convert(varchar(10),fecha,120)
					END'
		Exec(@sql)

		set @process = 'DROP Function  -- Verifica2'
		set @sql='if exists (select * from sys.objects where object_id = OBJECT_ID(N''Verifica2'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT'')) DROP FUNCTION Verifica2'
		EXEC(@sql)

		set @process = 'CREATE FUNCTION -- [dbo].[Verifica2]'
    	set @sql='CREATE FUNCTION [dbo].[Verifica2]
(@tel varchar(32),@pais tinyint = 0, @cldLocal varchar(7) = '''')
RETURNS varchar(32) AS
BEGIN
declare @ld varchar(7)
declare @lon tinyint
declare @result tinyint
declare @mod varchar(10)
declare @Cadena varchar(32)

if (@pais = 0 and @ld = '''')
begin
 select @pais = valor from ccSettings with(nolock) where setting_id = 104
 select @cldLocal = valor from ccSettings with(nolock) where setting_id = 17
end
select @tel = dbo.limpia(@tel)

if @pais = 1 begin --Empieza Mexico
 select @lon = len(@tel)
 if @lon between 7 and 8 begin
  set @tel = @cldLocal + @tel
 end
 select @tel = right(@tel, 10)
 select @lon = len(@tel)

 if @lon = 10 begin

  if(exists(select top 1 cld from series nolock where cld=left(@tel,2)))
   select @ld = left(@tel,2)
  else if(exists(select top 1 cld from series nolock where cld=left(@tel,3)))
   select @ld = left(@tel,3)
  else
   return ''E_'' + @tel

  select @mod = modalidad from series nolock where cld = @ld and serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

  select @tel = case
   when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''01'' + @tel end
   when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
   else ''E_'' + @tel
  end
 end else begin
  if @lon > 0 begin
   select @tel = ''E_'' + @tel
  end
 end
 return @tel
end --Termina Mexico

 -- Empieza Argentina
    if @pais = 2 begin
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel,1) = ''E'' begin return @tel end
     select @lon = len(@tel)
     if @lon in(6,7,8) and left(@tel,2) <> ''15'' begin
      set @tel = @cldLocal + @tel
     end

     if @lon in (8,9,10) and left(@tel,2) = ''15'' begin
      set @tel = @cldLocal + substring(@tel,3,@lon - 2)
     end

     --Buscamos el 15
     if @lon = 13 begin
      declare @index as int
      select @index = charindex(''15'',@tel)
      --El unico caso en el que la lada tiene un 15 es con lada 3715
      if @index < 2 begin
       select @tel = ''E_'' + @tel
       return @tel
      end
      else begin
       if substring(@tel,@index-2,4) = ''3715''
        begin
         select @ld = ''3715''
         set @tel = @ld + right(@tel,6)
        end
       else
        begin
         select @ld = substring(@tel,2,@index-2)
         set @tel = @ld + right(@tel,13 - (@index + 1))
        end
      end
     end

     select @tel = right(@tel, 10)

     if len(@tel) = 10 begin
      declare @serie as varchar(5)
      begin
       -- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
       declare @contLD as int
       declare @cont as int
       set @contLD=4
        BuscaLada:
        if isnull(@ld,'''') = '''' and @contLD >= 2
         begin
          select @ld = cld from seriesArg where cld=left(@tel,@contLD)
          if isnull(@ld,'''') = '''' begin
           set @contLD = @contLD - 1
           goto BuscaLada
          end
         end
        else begin
          if isnull(@ld,'''') = '''' begin
           select @tel = ''E_'' + @tel
          end
        end
      end

      -- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
      begin
      if len(@ld) = 2 begin
        set @cont = 5
        buscaSerie2:
        if isnull(@serie,'''') = '''' and @cont >= 4 begin
         select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,3,@cont)
         if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie2 end
        end
      end
      else begin
       if len(@ld) = 3 begin
        set @cont = 4
        buscaSerie3:
        if isnull(@serie,'''') = '''' and @cont >= 3 begin
         select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,4,@cont)
         if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie3 end
        end
       end
       else begin
        if len(@ld) = 4 begin
         set @cont = 3
         buscaSerie4:
         if isnull(@serie,'''') = '''' and @cont >= 2 begin
          select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,5,@cont)
          if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie4 end
         end
        end
       end
      end

      end

      select @mod = modalidad from seriesArg where cld = @ld and serie = @serie and right(@tel, 10 - len(@ld) - len(@serie)) between [NUMERACION INICIAL] and [NUMERACION FINAL]

      -- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie
      --select @ld,@serie,@mod,@contLD
      if isNull(@serie,'''') = '''' and @contLD>1 begin
      set @contLD = len(@ld) - 1
      set @ld = null
      goto BuscaLada
      end

      select @tel = case
       when @mod in (''BASICA'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''0'' + @tel end
       when @mod = ''CPP'' then case when @ld = @cldLocal then ''15'' + right(@tel,10-len(@ld)) else ''0'' + @ld + ''15'' + right(@tel,10-len(@ld)) end
       else ''E_'' + @tel
      end
     end else begin
      if len(@tel) > 0 begin
       select @tel = ''E_'' + @tel
      end
     end
     return @tel
    end  --Termina Argentina

    if @pais = 3 begin  --Empieza Colombia
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel,1) = ''E'' begin
      return @tel
     end

     if len(@tel) not in (7,8,10,11) begin
      return ''E_'' + @tel
     end

     if len(@tel) = 7 begin
      if exists(select serie from seriesCol where serie = left(@tel,4) and @cldLocal = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end

     if len(@tel) = 8 begin
      if exists(select serie from seriesCol where serie = substring(@tel,2,4) and left(@tel,1) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end

     if len(@tel) = 10 begin
      if exists(select serie from seriesCol where serie = substring(@tel,5,3) and (left(@tel,3) + ''-'' + substring(@tel,4,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end

     if len(@tel) = 11 begin
      if exists(select serie from seriesCol where serie = substring(@tel,6,3) and (substring(@tel,2,3) + ''-'' + substring(@tel,5,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end
    end  --Termina Colombia

    -- Empieza Chile
    if @pais = 5 begin
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel,1) = ''E'' begin
      return @tel
     end

     if len(@tel) = 6 and len(@cldLocal) = 2 begin
      if exists(select serie from seriesChi where cld = @cldLocal and left(@tel,3) = serie and right(@tel,3) between numeracioninicial and numeracionFinal) begin
       return @tel
      end
      else begin return ''E_'' + @tel end
     end

     if len(@tel) = 7 begin
      if @cldLocal in (2,41,44,32) begin
       if exists(select serie from serieschi where serie = left(@tel,4)) begin return @tel end
       else begin
        if left(@tel,3) = ''200'' and exists(select serie from serieschi where serie = left(@tel,3) ) begin return @tel end
       end
      end
     end

     if len(@tel) = 8 begin
      if left(@tel,1) = ''2'' begin
        if exists(select serie from serieschi where serie = substring(@tel,2,4)) begin return @tel end
        else begin
         if exists(select serie from serieschi where serie = substring(@tel,2,5)) begin return @tel end
         else begin return ''E_'' + @tel end
        end
      end
      else begin
       return @tel
      end
     end

     if len(@tel) = 10 begin
      if left(@tel,2) = ''09'' begin
       if exists(select serie from serieschi where cld=substring(@tel,3,1) and serie = substring(@tel,5,3)) begin
        return @tel
       end
       else begin
        return ''E_'' + @tel
       end
      end

     end
    end
    --Termina Chile

    if @pais = 6 begin --Empieza Venezuela
     select @lon = len(@tel)
     if @lon = 7  begin
      set @tel = @cldLocal + @tel
     end

     select @tel = right(@tel, 10)

     if len(@tel) = 10 begin
      select @ld = left(@tel,3)
      select @mod = tipo from seriesVen where left(@tel,3) = LD

      if @mod = ''CPP'' begin
       if exists( select * from seriesVen where LD = @ld ) begin
        if @ld = @cldLocal begin
         select @tel = right(@tel,7)
        end
        else begin
         select @tel = ''0'' + @tel
        end
       end
       else begin
        select @tel = ''E_'' + @tel
       end
      end
      else begin
       if @mod = ''FIJO'' begin
        if exists( select serie from seriesVen where serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [Inicio] and [Fin]) begin
         if @ld = @cldLocal begin
          select @tel = right(@tel,7)
         end
         else begin
          select @tel = ''0'' + @tel
         end
        end
        else begin
         select @tel = ''E_'' + @tel
        end
       end
       else begin
        select @tel = ''E_'' + @tel
       end
      end
     end
     else begin
      if len(@tel) > 0 begin
       select @tel = ''E_'' + @tel
      end
     end
     return @tel
    end --Termina Venezuela

    if @pais = 7 begin -- Empieza UK
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     if left(@tel, 1) = ''E'' begin -- regresa error por longitud
      return @tel
     end
     select @lon = len(@tel)

     --numeros no geograficos
     if (left(@tel, 2) in(''03'', ''07'', ''09'') and @lon <> 11) or (left(@tel, 3) in(''055'', ''056'', ''070'') and @lon <> 11) begin
      return ''E_'' + @tel --error por longitud con lada correcta
     end
     else begin
      if left(@tel, 7) in(''0845464'') or left(@tel, 5) = ''07624'' or left(@tel, 4) in(''0500'', ''0800'') or left(@tel, 3) in(''055'', ''056'', ''070'', ''76'') or left(@tel, 2) in(''03'', ''07'', ''08'', ''09'') begin
       return @tel; --longitud correcta y numero no geografico
      end
     end

     --numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
     if (left(@tel, 7) in(''0159575'', ''0159576'')) or
      (left(@tel, 5) in(''02820'',''02821'',''02825'',''02827'',''02828'',''02829'',''02830'',''02837'',''02838'',''02840'',''02841'',''02842'',''02843'',''02844'',''02866'',''02867'',''02868'',''02870'',''02871'',''02877'',''02879'',''02880'',''02881'',''02882'',''02885'',''02886'',''02887'',''02889'',''02890''
,''02891'',''02892'',''02893'',''02894'',''02895'',''02897'') and @lon = 11) or --claves 2xxx tienen formato 4-6
      (left(@tel, 4) in(''0113'', ''0114'',''0115'',''0116'',''0117'',''0118'',''0121'',''0131'',''0141'',''0151'',''0161'',''0238'',''0239'') and @lon = 11) or --3-digit area codes have 7-digit subscribers.
      (left(@tel, 3) in(''020'',''024'',''029'') and @lon = 11) begin --2-digit area codes have 8-digit subscribers.
      return @tel;
     end

     --numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
     if left(@tel, 2) = ''01'' begin
      select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,4) --mayor numero de ladas (va primero por ser mas probable)
      if @ld > 0 begin
       return @tel;
      end
      else begin
       select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,5) --ladas restantes
       if @ld > 0 begin
        return @tel;
       end
      end
     end --si no encontro ni error ni coincidencia entonces esta mal
     return ''E_'' + @tel
    end --Termina UK

    if @pais = 8 begin --Empieza Arabia Saudita
     select @tel = dbo.completa(@tel, @pais, @cldLocal)
     select @lon = len(@tel)
     if @lon = 7 begin
      set @tel = ''0'' + @cldLocal + @tel
     end
     select @lon = len(@tel)

     if @lon = 9 begin
      if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,2) = cld) begin
       if (substring(@tel,2,1) = @cldLocal)
       begin
        return right(@tel,7)
       end else begin
        return @tel
       end
      end
      else begin
       return ''E_'' + @tel
      end
     end
     if @lon = 10 begin
      if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,4,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,3) = cld) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end
     if @lon = 11 begin
      if exists(select regiones,* from seriesSA where right(@tel,6) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 6 and left(@tel,2) = cld) begin
       return @tel
      end
      else begin
       return ''E_'' + @tel
      end
     end
    end --Termina Arabia Saudita

    if @pais = 9
     begin --Empieza Australia
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      select @lon = len(@tel)

      if left(@tel,1) <> ''E''
       begin
        if exists(select Regiones
            from SeriesAU
            where convert(int,LD) = convert(int,substring(@tel, 1, 2))
            and convert(int,AreaCode) = convert(int,substring(@tel, 3, 2))
            and convert(int,substring(@tel, 5, 6)) between convert(int,SerieInicio) and convert(int,SerieFin))
         begin
          return @tel
         end
        else
         begin
          return ''E_'' + @tel
         end
       end
      else
       begin
        return @tel
       end
     end --Termina Australia

    if @pais= 10
     begin -- Inicia Brasil
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      select @lon = len(@tel)
      if left(@tel,1) <> ''E''
       begin
        if @lon in (8,9) begin --numero local
         if exists(
         select Regiones
          from seriesBR where
           convert(int,AreaCode) = convert(int,@cldLocal) and
           convert(int,@tel) between convert(int,SerieInicio) and convert(int,SerieFin)
         )
         begin
          return @tel
         end
         else begin
          return ''E_'' + @tel
         end
        end
        if @lon in (10,11) begin --numero nacional
         if exists(
         select Regiones
          from seriesBR where
           convert(int,AreaCode) = convert(int,left(@tel,2)) and
           convert(int,right(@tel, @lon-2)) between convert(int,SerieInicio) and convert(int,SerieFin)
         )
         begin
          return @tel
         end
         else begin
          return ''E_'' + @tel
         end
        end
       end

      else begin
       return @tel
      end
     end -- Termina Brasil

    if @pais= 11
     begin -- Inicia Guatemala
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      if left(@tel,1) <> ''E''
       begin
        if exists(select zonaGeografica from seriesGT (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
         return @tel
        else
         return ''E_'' + @tel
       end
      else
       return @tel
     end -- Termina Guatemala

     if @pais= 12
     begin -- Inicia Costa Rica
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      if left(@tel,1) <> ''E''
       begin
        if len(@tel)=8
         if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
          return @tel
         else
          return ''E_'' + @tel
        else if len(@tel)=10 begin
         if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,3) and right(@tel, 7) between rangoInicio and rangoFinal)
          return @tel
         else
          return ''E_'' + @tel
        end
        else
         if charindex(substring(@tel,1,2),''00,08'') <= 0
          return ''E_'' + @tel
         else
          return @tel
       end
     end -- Termina Costa Rica

    if @pais= 13
     begin -- Inicia Salvador
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      if left(@tel,1) <> ''E''
       begin
        if len(@tel)=8
         if exists(select zonaGeografica from seriesSV (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
          return @tel
         else
          return ''E_'' + @tel
        else
         if charindex(substring(@tel,1,2),''00'') <= 0
          return ''E_'' + @tel
         else
          return @tel
       end
     end -- Termina Salvador

    if @pais= 14
     begin -- Inicia Spain
      select @tel = dbo.completa(@tel, @pais, @cldLocal)
      if left(@tel,1) <> ''E''
       begin
        if len(@tel)=9
         if exists(select provincia from seriesEsp (nolock) where indicativo = substring(@tel,1,1) and right(@tel, 8) between numInicial and numFinal)
          return @tel
         else
          return ''E_'' + @tel
        else
         if charindex(substring(@tel,1,2),''00'') <= 0
          return ''E_'' + @tel
         else
          return @tel
       end
     end -- Termina España

    if @pais= 15 begin --Inicia Peru
     select @tel = dbo.Completa(@tel, @pais, @cldLocal)
     select @lon = len(@tel)
     if @lon between 6 and 7 begin
      set @tel = @cldLocal + @tel
     end
     select @tel = right(@tel, 9)
     select @lon = len(@tel)
     if left(@tel,1) <> ''E'' begin
      if @lon = 9 begin
       if exists(select zonaGeografica from seriesPE (nolock) where
        left(@tel,1) = 9 or
        substring(@tel,2,1) = 1 and areaNumeracion = 1 and right(@tel, 7) between rangoInicio and rangoFinal or
        substring(@tel,2,1) <> 1 and left(@tel,2) = areaNumeracion and right(@tel, 7) between rangoInicio and rangoFinal
       )
        return @tel
       else
        return ''E_'' + @tel
      end
     end
    end --Termina Peru

    return @tel
   end'
		EXEC(@sql)
		
		set @process = 'ALTER PROCEDURE -- [dbo].[ccsp_RIAADMGetPermisos]'
    	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAADMGetPermisos] 
					@user_id varchar(255), 
					@Type int, 
					@mask int = 0, 
					@xferMask int = 0,
					@xstartStopRecording int = 0,
					@CanChangeStatus bit = null,
					@XferAgents int = null
					AS 
					set nocount on

					If @Type = 1
					 begin
						Select distinct A.User_id as ID, Login, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' +
						isNull(ApellidoMaterno, '''') as ''Nombre'', cast(dialMask & 1 as int) as ''Restringe celular'',
						cast( (dialMask & 2) /2 as int) as ''Restringe ld'', cast((dialMask & 4) / 4 as int) as ''Restringe local'',
						cast( xfermask as int) as ''Recibe transferencia'', cast(CanChangeStatus as tinyint) CanChangeStatus, 
						cast(XferAgents as tinyint) XferAgents,
						cast(startStopRecording as tinyint) startStopRecording
						from ccUsers A
						join ccRIAWorkGroupUsers B on A.user_id = B.user_id
						where tipoUser_id = 1 and IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
						return(0)
					 end

					 if @Type = 3
					begin
						if(@xstartStopRecording <> -1)
							UPDATE ccUsers SET startStopRecording = @xstartStopRecording where tipoUser_id=1 and user_id in (select user_id from ccRIAWorkGroupUsers where idwg in (select IDWG from ccRIAWorkGroupUsers where user_id=@user_id))
						if(@xferMask <> -1)
							UPDATE ccUsers SET xfermask = @xferMask where tipoUser_id=1 and user_id in (select user_id from ccRIAWorkGroupUsers where idwg in (select IDWG from ccRIAWorkGroupUsers where user_id=@user_id))
						if(@mask <> 0)
							UPDATE ccUsers SET dialMask = case 
								when @mask > 0 and dialmask & @mask = 0 then dialmask + @mask
								when @mask < 0 and dialmask & abs(@mask) > 0 then dialmask - abs(@mask)
								else dialmask end
								where tipoUser_id=1 and user_id in (select user_id from ccRIAWorkGroupUsers where idwg in (select IDWG from ccRIAWorkGroupUsers where user_id=@user_id))
						if(@XferAgents <> 0)
							UPDATE ccUsers SET XferAgents = case 
								when @XferAgents > 0 and XferAgents & @XferAgents = 0 then XferAgents + @XferAgents
								when @XferAgents < 0 and XferAgents & abs(@XferAgents) > 0 then XferAgents - abs(@XferAgents)
								else XferAgents end
								where tipoUser_id=1 and user_id in (select user_id from ccRIAWorkGroupUsers where idwg in (select IDWG from ccRIAWorkGroupUsers where user_id=@user_id))
						return(0)
					end

					--if @Type = 2
					If @xferMask=-1 and @mask=-1 and @xstartStopRecording=-1
					 begin
						update ccUsers set NotReadyRestricted = ISNULL(@CanChangeStatus, NotReadyRestricted) , XferAgents = ISNULL(@XferAgents, XferAgents) 
						where user_id in (select value from dbo.fn_RIASplitDelimited(@user_id, '',''))
						return(0)
					 end

					If @xferMask=-1 and @xstartStopRecording=-1
					 begin
						UPDATE ccUsers SET dialMask = @mask where user_id in (select value from dbo.fn_RIASplitDelimited(@user_id, '',''))
					 end


					if @mask=-1 and @xstartStopRecording=-1
					 begin
						UPDATE ccUsers SET xfermask = @xferMask where user_id in (select value from dbo.fn_RIASplitDelimited(@user_id, '',''))
					 end

					if @mask=-1 and @xferMask=-1
					begin
						UPDATE ccUsers SET startStopRecording = @xstartStopRecording where user_id in (select value from dbo.fn_RIASplitDelimited(@user_id, '',''))
					 
					end

					return(0)
					set nocount off'
		EXEC(@sql)
		
		set @process = 'Insert ccSettings -- Teléfonos locales a 10 dígitos para marcación manual'
		set @sql='if not exists (select * from ccSettings where setting_id=195)
					insert ccsettings (setting_id,valor,descripcion,status,tipo,detalle,description,bloadsettings,validate) values 
					(195,0,''Teléfonos locales a 10 dígitos para marcación manual (México)'',1,''AGT'',''Teléfonos locales a 10 dígitos para marcación manual (México)'',''Phone length for manual call (Mexico)'',1,''^[01]$'')'
		EXEC(@sql)
		
		set @process = 'ALTER PROCEDURE -- [dbo].[ccsp_Limpia]'
    	set @sql='ALTER procedure [dbo].[ccsp_Limpia]
			@tel varchar(30),
			@Camp int = 0
			as
			set nocount on
			declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint
			select @tel = dbo.limpia(@tel)
			select @lon = len(@tel)
			select @pais = valor from ccSettings with(nolock) where setting_id = 104
			select @ld = valor from ccSettings with(nolock) where setting_id = 17
			select @extLen = valor from ccsettings with(nolock) where setting_id = 108
			declare @telTemp as varchar(15)

			if @extLen=@lon and @lon>1
			 begin
				select 0 as res, @tel as tel -- Extension
				return(0)
			 end

			if @pais = 1
			 begin
				if @lon = 3 and @tel = ''911''
				begin
					select 4 as res, @tel as tel
					return(0)
				end

				if @lon < 7 or @lon = 7 and len(@ld) = 2 or @lon = 8 and len(@ld) = 3 or @lon in (9, 11) or @lon > 13
				 begin
					select 1 as res, @tel as tel --Longitud invalida
					return(0)
				 end

				if @lon = 12 and left(@tel, 2) <> ''01'' or @lon = 13 and left(@tel, 3) <> ''044'' and left(@tel, 3) <> ''045'' and left(@tel, 3) <> ''001''
				 begin
					select 2 as res, @tel as tel--Digitos incorrectos
					return(0)
				 end

				if left(@tel, 3) = ''001''
				 begin
					select 0 as res, @tel as tel
					return(0)
				 end

				declare @mod varchar(5)
				select @tel = case when @lon in (7, 8) then @ld + @tel else right(@tel, 10) end
				select @mod = modalidad from series where cld + serie = left(@tel, 6) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

				if exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra))
				on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
				 begin
					select 4 as res, @tel as tel
					return(0)
				 end

				if @mod = ''CPP''
				 begin
					select 0 as res, case left(@tel, len(@ld)) when @ld then ''044'' else ''045'' end + @tel as tel
					return(0)
				 end

				if @mod in (''FIJO'', ''MPP'')
				 begin
					select 0 as res, case left(@tel, len(@ld)) when @ld then right(@tel, 10 - len(@ld)) else ''01'' + @tel end as tel
					return(0)
				 end

				--if @mod is null
				select 3 as res, @tel as tel--No encontrado
				return(0)
			 end

			if @pais = 2
			 begin
				select @telTemp = @tel
				set @tel = dbo.completa(@tel, @pais, @ld)
				if left(@tel,1)=''E'' begin
					select 1 as res, @telTemp --Longitud Invalida
					return
				end

				select @tel = dbo.fnClearPhoneArg(@tel)

				if (len(@tel) = 10 or len(@ld + @tel) = 10) and left(@tel,1) <> ''E'' begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and (telefono = @tel or telefono= @ld + @tel) and status=1)
				   begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					end else begin
						select 4 as res, @tel
						return(0)
					end
				end else begin select 2 as res, @telTemp as tel end --Digitos incorrectos
			 end

			if @pais = 3
			 begin
				select @telTemp = @tel
				if @lon < 7 or @lon = 9 or (@lon = 10 and  left(@telTemp,1) <> ''3'') or (@lon = 11 and  left(@telTemp,2) <> ''03'') begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				end
				select @tel = dbo.Completa_ListaNegra(@tel)

				if (len(@tel) = 8 or len(@tel) = 10) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 4
			 begin
				exec ccsp_LimpiaUsa @tel, @Camp
				return(0)
			 end

			if @pais = 5
			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)

				if len(@tel) in(8,9) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 6
			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)


				if len(@tel) = 10 and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin
						select @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end

			if @pais = 7

			 begin
				select @telTemp = @tel
				if left(@tel,1)=''E''
				 begin
					select 1 as res, @telTemp --Longitud Invalida
					return(0)
				 end

				select @tel = dbo.Completa_ListaNegra(@tel)

				if (len(@tel) = 9 or len(@tel) = 10) and left(@tel,1) <> ''E''
				 begin
					if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					 begin

						select @tel = dbo.verifica(@tel)
						if left(@tel,1)=''E'' begin
							select 3 as res, @telTemp -- No existe el telefono
						end
						else begin
							select 0 as res, @telTemp  -- Todo Bien
						end
						return(0)
					 end
					else
					 begin
						select 4 as res, @tel --lista negra
						return(0)
					 end
				 end
				else
				 begin
					select 2 as res, @telTemp as tel
				 end --Digitos incorrectos
			 end


			if @pais = 8
			 begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)

				if left(@tel,1)=''E'' begin
					select 1 as res, @telTemp --Longitud Invalida
					return (0)
				end

				if (len(@tel) = 9 or len(@tel) = 10 or len(@tel) = 11 )
				begin
					if not exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra)) on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
					begin
						select  @tel = dbo.verifica(@tel)
						select 0 as res, @tel
						return(0)
					end
					else
					begin
						select 4 as res, @tel
						return(0)
					end
				end
			 end

			if @pais = 9 --Australia
			 begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)

				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			 end

			if @pais = 10 -- Brasil
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				set @lon = len(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 11 -- Guatemala
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 12 -- Costa Rica
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 13 -- Salvador
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end

			if @pais = 14 -- Spain
			begin
				select @telTemp = @tel
				select @tel = dbo.Completa_ListaNegra(@tel)
				if left(@tel,1)=''E''
					begin
						select 1 as res, @telTemp --Longitud Invalida
						return (0)
					end
				else
					begin
						if not exists(select a2.idtipolista
									  from cclistanegra a1
									  inner join camplistanegra a2 with(index(IX_Camplistanegra))
									  on (a1.idtipolista=a2.idtipolista)
									  where cam_id=@Camp
									  and telefono = @tel
									  and status=1)
							begin
								select  @tel = dbo.verifica(@tel)
								if left(@tel,1) <> ''E''
									begin
										select 0 as res, @tel
										return(0)
									end
								else
									begin
										select 2 as res, @telTemp as tel --digitos incorrectos
										return(0)
									end
							end
						else
							begin
								select 4 as res, @tel
								return(0)
							end
					end
			end  '
		EXEC(@sql)
		
		set @process = 'Insert ccSettings -- Default campaign on manual call'
		set @sql='if not exists (select * from ccSettings where setting_id=196)
					insert ccsettings (setting_id,valor,descripcion,status,tipo,detalle,description,bloadsettings,validate) values 
					(196,6,''Campaña default para marcación manual'',1,''AGT'',''Campaña default para marcación manual'',''Default campaign for manual call'',1,''^\d*$'')'
		EXEC(@sql)
		
		set @process = 'ALTER PROCEDURE -- [dbo].[ccsp_RIACampsManualCall]'
    	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]
			@UserID int,
			@onChat int = 0
			AS
			set nocount on

			if (@onChat = 0)
			begin
				declare @mod smallint
				select @mod = valor from ccsettings where setting_id = 196

				select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [default]
				from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id 
				where (ca.user_id = @UserID and cam_modoManual = 1) or ca.cam_id=@mod
				order by cam_descripcion
			end
			else
				select distinct c.cam_id, c.cam_descripcion 
				from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id 
				where ca.user_id = @UserID and manualCallOnChat = 1 
				order by cam_descripcion

			set nocount off'
		EXEC(@sql)
		
		
		
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
