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
	

    set @process = 'KR020000 Se borra job si existe de callbacks por campaña'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_OUTGetCB_Distribucion'')
    begin
        DROP PROCEDURE ccsp_OUTGetCB_Distribucion;
    end'
    EXEC(@sql)

    set @process = 'KR020000 Se actualiza job de callbacks por campaña'
    set @sql = '
        CREATE PROCEDURE [dbo].[ccsp_OUTGetCB_Distribucion]
        @CAMPID as int,
        @Tipo int=0
        as
        set nocount on
        declare @start datetime, @end datetime, @final datetime

        select @end=CONVERT(datetime,CONVERT(varchar(11),GETDATE(),121)+''00:00'',121)
        select @start=DATEADD(d,-1,@end)
        select @final=DATEADD(d,+1,@end)

        if @Tipo=0
        begin
            select count(case when(cal_fechaDial<@end) then 1 else null end) as Antes,
            count(case when(cal_fechaDial between @end and @final) then 1 else null end) as Hoy,
            count(case when(cal_fechaDial>@final) then 1 else null end) as Despues,
            count(callout_id) as Todos
            from ccoWorkingTable where cam_id = @CAMPID and cal_status=1
            return(0)
        end

        select datepart(hh, cal_fechaDial) as Hora, count(callout_id) as CB
            from ccoWorkingTable
            where cam_id=@CAMPID and cal_fechaDial BETWEEN @end AND @final and cal_status=1
            group by datepart(hh, cal_fechaDial)
            order by Hora
        return(0)'
    EXEC(@sql)

    set @process = 'CW-Settings permiso tiempo de consulta de callbacks por hora'
    set @sql = 'if not exists (select * from ccSettings where setting_id=231)
    begin
        insert into ccSettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values (231,5,
        ''Tiempo de consulta Callbacks por hora (mins)'',1,''ADM'',
        ''Tiempo (mins) para realizar la consulta de callbacks agrupados por hora en el Dashboard del Admin Kolob, default 5 min'',
        ''Time delay to refresh callbacks information (mins), default 5 min'',1,''.*'')
    end'
    EXEC(@sql)
	
	set @process = 'CW-6322 Drop sp ccsp_EngineLogTransfers'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_EngineLogTransfers'')
    begin
        DROP PROCEDURE ccsp_EngineLogTransfers;
    end'
    EXEC(@sql)
	
	set @process = 'CW-6322 Create sp ccsp_EngineLogTransfers'
    set @sql = 'CREATE procedure [dbo].[ccsp_EngineLogTransfers]
@action as tinyint,
@cal_id as integer,
@tipo as tinyint,
@modo as tinyint,
@destino as varchar(50),
@tantes integer = 0,
@tdespues integer = 0,
@pbxId tinyint =0,
@channel int =0
as
-- tipo: 1 inbound, 2 outbound
-- modo: 0 externa ciega, 1 agente, 2 acd, 3 confer, 4 externa supervisada, 5 desborde, 6 supervisada acd, 7 in callback
 
declare @totalCall_Time integer
declare @callout_id int
declare @xferDate datetime = getdate()
 
if @action = 1 begin
	if @modo = 4 begin
	   insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id) 
	   values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, @xferDate, @pbxId, @channel, dbo.fnGetTipoLlamada(@destino) )
	   if @tdespues > 0 begin
			  select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tdespues
			  update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
	   end
	end
	else begin
		if @modo = 5 and @tipo = 1 and @cal_id = 0 
		begin
			insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id) 
			values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, @xferDate, @pbxId, @channel, dbo.fnGetTipoLlamada(@destino) )
			return;
		end

	   if not exists (select * from ccLogTransfers where cal_id = @cal_id and tipo = @tipo)
		  insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id) 
		  values ( @cal_id, @tipo, @modo, @destino, 0, @tantes, @xferDate, @pbxId, @channel, dbo.fnGetTipoLlamada(@destino) )
 
	   if @tipo = 2 begin
		  if @modo = 5 begin
			  select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
			  update ccLogTransfers set tDespuesXfer = @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2), tAntesXfer = @tdespues + (select tAntesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)  where cal_id = @cal_id and tipo = 2
		  end
		 
		  if @modo in (0,1,2) begin
			  select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
			  update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
		  end
	   end
	   else begin
		  if @modo = 7 begin
			select @xferDate XferDate
			return(0)
		  end
		  if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
			  select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
			  select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
			  update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
		  end
	   end
	end
	--Valida que no existe y que el tiempo minimo de la grabacion se mayor al establecido para que lo tome el detector de gritos
	if not exists(select * from ccAVRSTransfer where cal_id=@cal_id and tipo= @tipo-1) begin
	declare @tMinAVRS smallint,@cal_tDialog int,@cal_manual int
	set @tMinAVRS=5
	set @cal_manual=0
	select @tMinAVRS=valor from ccSettings where setting_id=65
	if @tipo=2 begin
	   select @cal_tDialog=cal_tDialog,@cal_manual=cal_manual from ccoCallsOut where cal_id=@cal_id
	end
	else begin
	   select @cal_tDialog=cal_tDialog from ccCallsIn where cal_id=@cal_id
	end
 
	if @cal_tDialog >= @tMinAVRS and @cal_manual<>1 begin
	   insert into ccAVRSTransfer (cal_id,tipo) values(@cal_id,@tipo-1)
	end
	end
end
 
else if @action = 2 begin   
	if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
	   select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
	   update ccLogTransfers set tDespuesXfer = @tdespues + @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)  where cal_id = @cal_id and tipo = 2
	   select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
	   update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
	end
end
 
else if @action = 4 begin
	select @totalCall_Time = ISNULL((select sum(tincall) from IVRCallsIn where callout_id = @cal_id), 0) + ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0)
	update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
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


