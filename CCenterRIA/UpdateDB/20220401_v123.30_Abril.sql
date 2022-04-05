/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

Database: CCenterRia
Required version: 123.27

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 123 --**********actualizar a 123 sin fix
SET @versionfix = 30
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-Roles permiso gestionar chats'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10015)
    begin
        insert into ccPermissions values (10015, ''Gestionar chat con agentes'', ''RolesPermissionChatManagement'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar chats'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10015)
    begin
        insert into ccRoles_Permissions values(1,10015)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar llamada'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10016)
    begin
        insert into ccPermissions values (10016, ''Gestionar monitoreo de llamada'', ''RolesPermissionCallMonitoring'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar llamada'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10016)
    begin
        insert into ccRoles_Permissions values(1,10016)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso solo monitoreo'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10017)
    begin
        insert into ccPermissions values (10017, ''Solo monitoreo'', ''RolesPermissionMonitoring'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol solo monitoreo'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10017)
    begin
        insert into ccRoles_Permissions values(1,10017)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar formatos'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10018)
    begin
        insert into ccPermissions values (10018, ''Gestionar formatos de evaluacion'', ''RolesPermissionFormsManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar formatos'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10018)
    begin
        insert into ccRoles_Permissions values(1,10018)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar historial'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10019)
    begin
        insert into ccPermissions values (10019, ''Gestionar historial de actividad'', ''RolesPermissionActivityLogManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar historial'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10019)
    begin
        insert into ccRoles_Permissions values(1,10019)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar autoinicio'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10020)
    begin
        insert into ccPermissions values (10020, ''Gestionar inicio automatico'', ''RolesPermissionAutostartManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar autoinicio'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10020)
    begin
        insert into ccRoles_Permissions values(1,10020)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar calificaciones'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10021)
    begin
        insert into ccPermissions values (10021, ''Gestionar calificaciones'', ''RolesPermissionDispositionManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar calificaciones'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10021)
    begin
        insert into ccRoles_Permissions values(1,10021)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar marcacion'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10022)
    begin
        insert into ccPermissions values (10022, ''Gestionar factor de marcacion fijo'', ''RolesPermissionDialFactorManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar marcacion'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10022)
    begin
        insert into ccRoles_Permissions values(1,10022)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar ani local'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10023)
    begin
        insert into ccPermissions values (10023, ''Gestionar lista de ANI local'', ''RolesPermissionANIListManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rolgestionar ani local'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10023)
    begin
        insert into ccRoles_Permissions values(1,10023)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar dnis'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10024)
    begin
        insert into ccPermissions values (10024, ''Gestionar numeros DNIS'', ''RolesPermissionDnisNumManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar dnis'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10024)
    begin
        insert into ccRoles_Permissions values(1,10024)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso gestionar listas negras'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10025)
    begin
        insert into ccPermissions values (10025, ''Gestionar listas negras'', ''RolesPermissionBlacklistManage'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol gestionar listas negras'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10025)
    begin
        insert into ccRoles_Permissions values(1,10025)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso acceder a reporteador'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10026)
    begin
        insert into ccPermissions values (10026, ''Acceder a reporteador'', ''RolesPermissionReporter'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol acceder a reporteador'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10026)
    begin
        insert into ccRoles_Permissions values(1,10026)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles permiso acceder a buscador'
    set @sql = 'if not exists (select * from ccPermissions where Permissions_Id=10027)
    begin
        insert into ccPermissions values (10027, ''Acceder a buscador'', ''RolesPermissionFinder'',0,0,0,''N/A'',1)
    end'
    EXEC(@sql)

    set @process = 'CW-Roles se agrega relacion permiso-rol acceder a buscador'
    set @sql = 'if not exists (select * from ccRoles_Permissions where Rol_Id=1 and Permissions_Id=10027)
    begin
        insert into ccRoles_Permissions values(1,10027)
    end'
    EXEC(@sql)
	set @process = 'CW-5608 add column to RepAVRSDetailChat'
	set @sql = 'if not exists (select * from sys.columns where name = N''chatId'' and Object_ID = Object_ID(N''RepAVRSDetailChat''))
    begin
        alter table RepAVRSDetailChat add chatId int default 0 not null
    end'
	EXEC(@sql)
	set @process = 'CW-5608 drop procedure ccspRepAVRSDetailChat'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepAVRSDetailChat'')
            begin
          DROP PROCEDURE ccspRepAVRSDetailChat;
            end'
	EXEC(@sql)
	set @process = 'CW-5608 create procedure ccspRepAVRSDetailChat'
	set @sql = '
	CREATE PROCEDURE  [dbo].[ccspRepAVRSDetailChat]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN		
	---Before insert delete first table dbo.RepAVRSQuestionDetail 
	DELETE FROM dbo.RepAVRSDetailChat with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSDetailChat

		select
		DATEADD(dd, 0, f.fecha_calif) AS fecha,
		a.User_id,
		a.Login,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		t.id_formato,
		t.nombre,
		p.enunciado_pregunta,
		r.etiquetas,
		r.peso as avgDisposition,
		i.Inbound_id AS inboundId,
		i.descripcion AS inbound,
		c.chatId
	from RIA_RESULTADOSFORMA_CHAT r
	INNER JOIN dbo.RIA_FORMACALIF_CHAT f ON f.id_forma = r.id_forma
	INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
	INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1 and tipo=2
								GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
	INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
	INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
	INNER JOIN ccinbound AS i ON c.inboundId = i.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
				
set nocount off
END'
	EXEC(@sql)
	set @process = 'CW-5611 add column to RepAvgAnswerTimeChats'
	set @sql = '
	 if not exists (select * from sys.columns where name = N''chatId'' and Object_ID = Object_ID(N''RepAvgAnswerTimeChats''))
    begin
        alter table RepAvgAnswerTimeChats add chatId int default 0 not null
    end'
	EXEC(@sql)
	set @process = 'CW-5611 drop procedure ccspRepAvgAnswerTimeChats'
	set @sql = '
	CREATE PROCEDURE [dbo].[ccspRepAvgAnswerTimeChats]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
	delete RepAvgAnswerTimeChats where date >= @from and date < @to

	insert into RepAvgAnswerTimeChats
	select 
	CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121) as [date], userId, [Login], inboundId, [inbound],
	[user], 
	 convert(decimal(10,2),isnull( sum([answerTime])/count(*),0.00)) as [avgAnswerTime]		
	, datepart(yyyy,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
	, datepart(mm,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
	, datepart(dd,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
	, datepart(hh,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
	, datepart(mi,CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121))
	, chatId
	from(
	select requestDate as [date], userId, [Login] as [login], 
	inboundId, c.descripcion as [inbound], nombres + '' '' + apellidopaterno + '' '' + apellidomaterno as [user],
	case when firstMessageTime is null then convert(int,isnull(firstMessageTime,0)) 
	else datediff(ss,chatdate,firstMessageTime) end as [answerTime], a.chatId as [chatId]
	from ccriachats a
	left join ccUserView b on (a.userId = b.user_id)
	left join ccinbound c on (a.inboundId = c.inbound_id)
	where b.user_id is not null
	and c.inbound_id is not null
	and a.chatstatus = 4) as answerTime
	group by CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121), userId, [Login], inboundId, [inbound], [user], [chatId]

end'
	EXEC(@sql)
	

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END


