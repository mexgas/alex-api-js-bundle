/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K053000

Database: CCenterRia
Required version: 125.37

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 38
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	---------------------------------------BEGIN Jonathan Ramírez (KR095000 Setting deshabilitar campos editables en agent)---------------------------------------------------------

	SET @process = 'DEV1-409 Milla Alter SP ccsp_RIARegistryLists --return SELECT 200 as ReturnValue y se agrega withNolock'
	SET @sql = 'ALTER Procedure [dbo].[ccsp_RIARegistryLists]
@action tinyint = 0, 
@list_id int = 0,
@cam_id smallint = 0,
@name varchar(80) = '''',
@status tinyint = 0,
@sequence smallint = 0,
@load_id int = 0
AS

--Status lista 0: inactiva, 1:pausa, 2:procesar

--Insert
IF @action = 1 begin

	IF @cam_id <> 0 begin
		select @sequence = isnull(max( sequence ),0) from ccRIARegistryLists where cam_id = @cam_id
		set @sequence = @sequence + 1
		Insert into ccRIARegistryLists(cam_id,name,status,sequence) values (@cam_id, @name, 2, @sequence)
		select max(list_id) from ccRIARegistryLists
	end
end

--Update sequence
IF @action = 2 begin
	
	declare @oldSeq as int
	select @oldSeq = sequence, @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id

	if @oldSeq <> @sequence begin
		
		if @oldSeq > @sequence begin
			update ccRIARegistryLists set sequence = sequence + 1 where cam_id = @cam_id and sequence >= @sequence and sequence < @oldSeq
		end

		if @oldSeq < @sequence begin
			update ccRIARegistryLists set sequence = sequence - 1 where cam_id = @cam_id and sequence <= @sequence and sequence > @oldSeq
		end

		update ccRIARegistryLists set sequence = @sequence where list_id = @list_id

	end

end

--Change status
IF @action = 3 begin
	
	update ccRIARegistryLists set status = @status where list_id = @list_id
	SELECT 200 as ReturnValue

end

-- lista campañas y listas de registros
IF @action = 4 begin
	select a.cam_id, b.cam_descripcion, count(list_id) as NoListas, c.graphic_id as Frame 
	from ccRIARegistryLists a  with(nolock)
	left join cccamps b on a.cam_id = b.cam_id
	left join ccRIACampsGraph c on a.cam_id = c.cam_id
	where b.cam_activo = 1 and a.cam_id in ( select distinct(cam_id) from ccRIARegistryLists ) 
	group by a.cam_id,b.cam_descripcion,c.graphic_id order by a.cam_id asc

end

-- listas de registros y no. registros
IF @action = 5 
begin
	select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence   
	from ccRIARegistryLists a with(index(IX_ccRIARegistryLists_1),nolock) 
	left join ccocallsoutsource b with(index(IX_ccoCallsOutSource_13),nolock) 
	on b.cam_id = @cam_id and a.list_id = b.list_id 
	where a.status > 0 and a.cam_id = @cam_id and status > 0 
	group by a.list_id,a.name,a.sequence 
	order by a.sequence
end

-- borrar lista
IF @action = 6 begin

	select @cam_id = cam_id from ccRIARegistryLists where list_id = @list_id
	select @sequence = max(sequence) from ccRIARegistryLists where cam_id = @cam_id
	exec ccsp_RIARegistryLists @action = 3, @status = 0, @list_id = @list_id
	exec ccsp_RIARegistryLists @action = 2, @sequence = @sequence, @list_id = @list_id
	SELECT 200 as ReturnValue

end

-- Detalle de numero de registros
IF @action = 7 begin

	declare @total as int

	select @total = count(*) from ccocallsoutsource where list_id = @list_id
	select @total = (@total - count(*)) from ccoworkingtable where list_id = @list_id

	if exists(select list_id from ccoWorkingTable where list_id = @list_id) begin
		select @status = status from ccRIARegistryLists where list_id = @list_id
		select @list_id as list_id,cast(cam_id as smallint) as cam_id, @status as status,
			count(case cal_status when 0 then 1 else null end) as New,
			count(case cal_status when 1 then 1 else null end) as CB,
			count(case cal_status when 2 then 1 else null end) as Pro, 
			@total as Fin
		from ccoWorkingTable where list_id = @list_id group by cam_id
	end
	ELSE begin
		select list_id, cam_id, status, 
		0 as New,
		0 as CB,
		0 as Pro,
		0 as Fin
		from ccRIARegistryLists where list_id = @list_id
	end


end

-- Cambia de nombre a la lista
IF @action = 8 begin
	
	update ccRIARegistryLists set name = @name where list_id = @list_id

end

-- Borra listas sin registros y reordena las listas
IF @action = 9 begin

	Create table #TempRegs(
		list_id int,
		[name] varchar(100),
		NoRegistros int,
		sequence int)

	insert into #TempRegs 
		select a.list_id,a.name,count(b.list_id) as NoRegistros,a.sequence 
		from ccRIARegistryLists a with(index(IX_ccRIARegistryLists_1),nolock)
		left join ccocallsoutsource b with(index(IX_ccoCallsOutSource_14),nolock)
		on a.list_id = b.list_id
		where a.status > 0 and a.cam_id = @cam_id and status > 0 
		group by a.list_id,a.name,a.sequence,a.status order by a.sequence

	while ( exists( select list_id from #TempRegs where NoRegistros = 0 ) ) begin
		declare @listToDelete as int
		select top 1 @listToDelete = list_id from #TempRegs where NoRegistros = 0
		exec ccsp_RIARegistryLists @action = 6, @list_id = @listToDelete
		delete from #TempRegs where list_id =  @listToDelete
	end

	drop table #TempRegs
	
	select @sequence=min(sequence) from ccRIARegistryLists where  cam_id = @cam_id and status = 0 

	select @list_id= list_id from ccRIARegistryLists where sequence =(
	select  max(sequence) as sequence from ccRIARegistryLists where  cam_id = @cam_id and status > 0 ) and cam_id = @cam_id
	update ccRIALoading set list_id = @list_id where load_id=@load_id
	exec ccsp_RIARegistryLists @action=2,@list_id=@list_id,@sequence=@sequence

	end'
	EXEC(@sql);

	SET @process = 'DEV1-409 Milla '
	SET @sql = ''
	EXEC(@sql);

	-------------------------------Preview K004009 DetalleMarcación --------------------------------

	set @process = 'DEV1-409 create table ccDispositionDashboardResultOut'
    set @sql = 'if not exists(select * from sys.tables where name=''ccDispositionDashboardResultOut'') begin
create table ccDispositionDashboardResultOut (
		CamId int not null,		
		statusCallId tinyint not null,
		callId int not null,
		DispotitionId int not null,
		SubDispotitionId int not null,
		primary key (callId)
		)
end'
    EXEC(@sql)

    set @process = 'DEV1-409 create table ccDispositionDashboardResultIn'
    set @sql = 'if not exists(select * from sys.tables where name=''ccDispositionDashboardResultIn'') begin
create table ccDispositionDashboardResultIn (
		CamId int not null,		
		statusCallId tinyint not null,
		callId int not null,
		DispotitionId int not null,
		SubDispotitionId int not null,
		primary key (callId)
		)
end'
    EXEC(@sql)

    set @process = 'DEV1-409 DROP PROCEDURE ccspSaveDispositionResult'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccspSaveDispositionResult'')
    begin
        DROP PROCEDURE ccspSaveDispositionResult;
    end'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter SP ccsp_GalateaAdminGetPermissions --> Se agrega ccUsers users with(nolock) -->109 y 134'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
    @user_id varchar(255),
    @Type int
AS
set nocount on

declare @isRoot int;

if exists (Select Rol_id from ccUsers A join ccUsers_Roles B on A.User_id = B.User_id where A.User_id = @user_id and rol_id = 7)
set @isRoot = 1 else set @isRoot = 0;
--print @isRoot

IF @isRoot = 1
BEGIN
    Select 
    User_id as AgentId, 
    Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
    cast(dialMask & 1 as int) as AllowCellPhoneCalls,
    cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
    cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
    cast( xfermask as int) as AllowTransferCalls, 
    cast(CanChangeStatus as tinyint) CanChangeStatus,
    cast(XferAgents as tinyint) XferAgents,
    ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
    cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
    ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
    ISNULL(multimediaPermissions.AllowUnassign, 0) AS AllowUnassign,
    ISNULL(multimediaPermissions.AllowSpam, 0 ) AS AllowSpam,
    cast(AllowDeleteRecord as int) as AgentPermissionDelete
from 
    ccUsers users with(nolock)
left join ccRIAMultimediaUsersPermissions multimediaPermissions on
    users.User_id = multimediaPermissions.AgentId
where 
   tipoUser_id = 1
return(0)
END
ELSE
BEGIN
    Select distinct 
    A.User_id as AgentId, 
    Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
    cast(dialMask & 1 as int) as AllowCellPhoneCalls,
    cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
    cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
    cast( xfermask as int) as AllowTransferCalls, 
    cast(CanChangeStatus as tinyint) CanChangeStatus,
    cast(XferAgents as tinyint) XferAgents,
    ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
    cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
    ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
    ISNULL(multimediaPermissions.AllowUnassign, 0) AS AllowUnassign,
    ISNULL(multimediaPermissions.AllowSpam, 0 ) AS AllowSpam,
    cast(AllowDeleteRecord as int) as AgentPermissionDelete
from 
    ccUsers A with(nolock)
inner join ccRIAWorkGroupUsers B on A.user_id = B.user_id
left join ccRIAMultimediaUsersPermissions multimediaPermissions on A.User_id = multimediaPermissions.AgentId
where tipoUser_id = 1 and 
    IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
return(0)
END
set nocount off'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter SP ccsp_GalateaAdminSetPermissions Se agrega If y else 207 y se agrega cambio IF @allAgentsSelected = 0 linea 360'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
    @adminId SMALLINT,
    @areaId SMALLINT,
    @agentsIds VARCHAR(MAX),
    @allAgentsSelected BIT, 
    @permissionName VARCHAR(255),
    @permissionValue INT
AS
SET NOCOUNT ON


declare @changeBitTable table(permissionName VARCHAR(255), valueBit int)

insert into @changeBitTable values(''AllowCellPhoneCalls'',1)
insert into @changeBitTable values(''startStopRecording'',1)
insert into @changeBitTable values(''XferManual'',1)
insert into @changeBitTable values(''AllowTransferCalls'',1)
insert into @changeBitTable values(''AgentPermissionDailing'',1)
insert into @changeBitTable values(''DailingMode'',1)
insert into @changeBitTable values(''AgentPermissionDelete'',1)


insert into @changeBitTable values(''AllowLongDistanceCalls'',2)
insert into @changeBitTable values(''XferExt'',2)

insert into @changeBitTable values(''AllowLocalCalls'',4)
insert into @changeBitTable values(''XferCamps'',4)

insert into @changeBitTable values(''XferAgents'',8)

DECLARE @changeBit INT

set @changeBit=0

select @changeBit=valueBit from @changeBitTable where permissionName=@permissionName

--print(@changeBit)
IF @agentsIds IS NOT NULL
BEGIN
    DECLARE @AgentIdsTemp TABLE (AgentId INT, Status BIT)
    INSERT INTO @AgentIdsTemp SELECT VALUE, 0 FROM dbo.fn_RIASplitDelimited(@agentsIds,'','')

    IF @permissionName = ''AllowUnassign'' 
    BEGIN                       
        UPDATE permissions SET permissions.AllowUnassign = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAMultimediaUsersPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAMultimediaUsersPermissions(AgentId, AllowUnassign, AllowSpam)
        SELECT agentIds.AgentId , @permissionValue, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAMultimediaUsersPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END
   else  IF @permissionName = ''AllowSpam''
    BEGIN 
        UPDATE permissions SET permissions.AllowSpam = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAMultimediaUsersPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAMultimediaUsersPermissions(AgentId, AllowSpam, AllowUnassign)
        SELECT agentIds.AgentId , @permissionValue, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAMultimediaUsersPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END
	else begin
    UPDATE
        ccUsers
    SET DialMask =
        CASE
        WHEN @permissionName = ''AllowCellPhoneCalls''
        OR @permissionName = ''AllowLongDistanceCalls''
        OR @permissionName = ''AllowLocalCalls''
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (DialMask & @changeBit) <> @changeBit
                THEN DialMask ^ @changeBit
                ELSE DialMask
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (DialMask & @changeBit) = @changeBit
                THEN DialMask ^ @changeBit
                ELSE DialMask
                END
            END 
        ELSE DialMask
        END,
                            
        XferMask =
        CASE
        WHEN @permissionName = ''AllowTransferCalls''
        THEN
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (XferMask & @changeBit) <> @changeBit
                THEN XferMask ^ @changeBit
                ELSE XferMask
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (XferMask & @changeBit) = @changeBit
                THEN XferMask ^ @changeBit
                ELSE XferMask
                END
            END
        ELSE XferMask
        END,

        XferAgents =
        CASE
        WHEN @permissionName = ''XferAgents''
        OR @permissionName = ''XferCamps'' 
        OR @permissionName = ''XferExt'' 
        OR @permissionName = ''XferManual'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (XferAgents & @changeBit) <> @changeBit
                THEN XferAgents ^ @changeBit
                ELSE XferAgents
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (XferAgents & @changeBit) = @changeBit
                THEN XferAgents ^ @changeBit
                ELSE XferAgents
                END
            END
        ELSE XferAgents
        END,

        startStopRecording =
        CASE
        WHEN @permissionName = ''startStopRecording'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE startStopRecording
        END,

        DialingMode = 
        CASE
        WHEN @permissionName = ''DailingMode'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (DialingMode & @changeBit) <> @changeBit
                THEN DialingMode ^ @changeBit
                ELSE DialingMode
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (DialingMode & @changeBit) = @changeBit
                THEN DialingMode ^ @changeBit
                ELSE DialingMode
                END
            END 
        ELSE DialingMode
        END,
        AllowChangeDialingMode = 
        CASE
        WHEN @permissionName = ''AgentPermissionDailing'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE AllowChangeDialingMode
        END,
        AllowDeleteRecord= 
        CASE
        WHEN @permissionName = ''AgentPermissionDelete'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE AllowDeleteRecord
        END
    WHERE User_id IN (SELECT AgentId FROM @AgentIdsTemp)
	end
                    
    DECLARE @Login VARCHAR(20) = (SELECT Login FROM ccUsers WHERE User_id = @adminId)
    DECLARE @AreaName VARCHAR(50) = (SELECT AreaName FROM ccRIACat_Areas WHERE IDArea = @areaId)
    DECLARE @OperationType TINYINT = (SELECT CASE WHEN @permissionValue = 1 THEN 33 ELSE 35 END)
    DECLARE @Language TINYINT = (SELECT valor FROM ccSettings WHERE setting_id = 27)
    DECLARE @Tag varchar(100) = (SELECT PermissionTag FROM ccRIAUsersPermissions WHERE PermissionName = @permissionName)        
    DECLARE @Value VARCHAR(250) = (SELECT permissions.Value 
                                    FROM  dbo.fn_RIASplitDelimited(@Tag,''|'') permissions
                                    WHERE permissions.Id = @Language + 1)

    DECLARE @AgentId INT = 0
    DECLARE @AgentName VARCHAR(20) = ''''

    set @Value=isnull(@Value,@permissionName)

    IF @allAgentsSelected = 0
    BEGIN
		DECLARE @areaNameValue AS VARCHAR(50)
		DECLARE @loginNameValue AS VARCHAR(50)

		SET @areaNameValue = isnull(@areaName,'''')

		IF (left(@areaName, 1) = ''!'')
		BEGIN
			SELECT @areaNameValue = areaName
			FROM dbo.ccRIACat_Areas AS AREAS WITH (NOLOCK)
			WHERE AREAS.IDArea = right(@areaName, len(@areaName) - 1)
		END

		SET @loginNameValue = @login

		IF (left(@login, 1) = ''!'')
		BEGIN
			SELECT @loginNameValue = Login, 
			@areaNameValue = case datalength(@areaNameValue) when 0 then isnull(AreaName,'''') else @areaNameValue end
			FROM ccUsers us (nolock) left join ccRIACat_Areas area (nolock) on area.IDArea=us.IDArea
			WHERE [Login] = right(@login, len(@login) - 1)
		END

		INSERT INTO ccRIALog		
		SELECT @areaNameValue, GETDATE(), @operationType, @loginNameValue, 4, @value, U.Login
		FROM @AgentIdsTemp A
		inner join ccUsers U on A.AgentId=U.User_id
       
    END
    ELSE
    BEGIN
        SET @AgentName = (SELECT AllAgentsTag FROM ccRIAUserPermissionsStatusTags WHERE Language = @Language)
                        
        EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
        @login = @Login, @moduleId = 4, @value = @Value , @target = @AgentName
                            
        UPDATE @AgentIdsTemp SET Status = 1
    END


END

SET NOCOUNT OFF'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter SP ccsp_GalateaCallbacks se quita la tabla temporal y se cambia CTE'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaCallbacks]
@dateCallBack datetime,
@agentId int = 0
AS

declare @dateStart datetime,@dateEnd datetime
set @dateStart=convert(datetime,convert(varchar(10),@dateCallBack,121))
set @dateEnd=DATEADD(dd,1,@dateStart)
;with CallBackHours as(
select  DATEPART(HOUR, cal_fcallback) ''Hour'',CAST( 1 as int) callback
from ccoCallsOut with(nolock)
where cal_fcallback between @dateStart and @dateEnd
and User_id = @agentId
)

SELECT  CAST(Hour AS smallint) [Hour], SUM(callback) ''CallBacks'' FROM CallBackHours
GROUP BY [Hour]
ORDER BY Hour
'
    EXEC(@sql)    

    set @process = 'DEV1-409 create SP ccspSaveDispositionResult'
    set @sql = 'CREATE PROCEDURE [dbo].[ccspSaveDispositionResult]
@action int,
@callType TINYINT=null,
@camId int =null,
@callid BIGINT=0,
@statusCallId int=0,
@dispotitionId int=null,
@subDispotitionId int=null
AS

declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
declare @callTypeInOut tinyint
if @action in(3,4) begin
	select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
	from ccsettings where setting_id = 27 -- 0 esp
	
end
if @action in(5,6) begin	
	select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
	from ccsettings where setting_id = 27 -- 0 esp	
end

set @callTypeInOut= case when @callType=1 then 0 else 1 end


if @action=0 begin
	declare @today date
	set @today =CONVERT(date,getdate())

	truncate table ccDispositionDashboardResultOut
	truncate table ccDispositionDashboardResultIn

	insert into ccDispositionDashboardResultOut
	select cam_id as CamId,statusCall_id as statusCallId,cal_id as callId
	,calif_id as Disposition
	,case  when califSub_id<=0 or califSub_id is null then 0 else califSub_id end as SubDispotitionId 
	from ccoCallsOut 
	where cal_Inicio>=@today

	insert into ccDispositionDashboardResultIn
	select Inbound_id as CamId,statusCall_id as statusCallId,cal_id as callId
	,calif_id as Disposition
	,case  when califSub_id<=0 or califSub_id is null then 0 else califSub_id end as SubDispotitionId 
	from ccCallsIn 
	where cal_Inicio>=@today
end
else if @action=1 begin
	set @dispotitionId=0
	set @subDispotitionId=0
	if @callType=1 begin
		insert into ccDispositionDashboardResultOut values(@camId,@statusCallId,@callid,@dispotitionId,@subDispotitionId)
	end
	else begin
		insert into ccDispositionDashboardResultIn values(@camId,@statusCallId,@callid,@dispotitionId,@subDispotitionId)
	end
end
else if @action=2 begin
	set @subDispotitionId=case when @subDispotitionId is null then null when @subDispotitionId>0 then @subDispotitionId else 0 end
	if @callType=1 begin
		update ccDispositionDashboardResultOut set statusCallId=@statusCallId,DispotitionId=isnull(@dispotitionId,DispotitionId)
		,SubDispotitionId=isnull(@subDispotitionId,SubDispotitionId)
		where callId=@callid 
	end
	else begin
		update ccDispositionDashboardResultIn set statusCallId=@statusCallId,DispotitionId=isnull(@dispotitionId,DispotitionId)
		,SubDispotitionId=isnull(@subDispotitionId,SubDispotitionId)
		where callId=@callid 
	end
end
else if @action=3 begin	
	select @callTypeInOut as tipo,dash.CamId as CamId
	,case when dash.statusCallId = 13 then
		case when ca.[description] is not null then ca.[description] else @nIdioma end
		else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma end
	end as Calificacion
	,case when count( case when dash.SubDispotitionId>0 then 1 end ) > 0 then 1 else 0 end as WithSubDisposition
	,dash.DispotitionId as DispotitionId
	,count(*) Amount
	,ISNULL(GraphColor,''1DB4E2'') GraphColor
	from ccDispositionDashboardResultOut dash with(nolock)
	left join ccTipoCalifOut ca on dash.DispotitionId = ca.calif_id 
	left join ccTipoCalifSubOUT tcsout on dash.SubDispotitionId = tcsout.califSub_id
	left join ccstatusllamada sll on sll.statuscall_id = dash.statusCallId
	left join ccCamps ci on ci.cam_id = dash.CamId
	where CamId=@camId
	group by  dash.CamId, dash.statusCallId,ca.[description],sll.descripcion,dash.DispotitionId,GraphColor

end
else if @action=4 begin	
	select @callTypeInOut as tipo
	,dash.CamId
	,case when ca.[Description] is not null then ca.[Description] else @nIdioma end as Calificacion
	,case when count( case when dash.SubDispotitionId>0 then 1 end ) > 0 then 1 else 0 end as WithSubDisposition
	,dash.DispotitionId
	,count(*)  as Amount
	,ISNULL(GraphColor,''1DB4E2'') GraphColor
	from ccDispositionDashboardResultIn dash with(nolock)
	left join ccTipoCalif ca on dash.DispotitionId = ca.calif_id 
	left join ccInbound cci on cci.inbound_id = dash.CamId 
	where dash.CamId = @camId and dash.statusCallId = 13 
	group by ca.[Description], dash.CamId,dash.SubDispotitionId,dash.DispotitionId,GraphColor

end

else if @action=5 begin	
	select 0 as Type,co.CamId as CampId,
	case when co.statusCallId = 13
	then case when description is not null
	then description else @nIdioma end
	else
	case when sll.descripcion is not null
	then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma
	end
	end as Calification,
	isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(cso.califSub_id) Quantity
	from ccDispositionDashboardResultOut co
	left join ccTipoCalifOut ca on co.DispotitionId = ca.calif_id
	left join ccTipoCalifSubOUT cso on co.SubDispotitionId = cso.califSub_id 
	left join ccstatusllamada sll on sll.statuscall_id = co.statusCallId
	left join ccCamps ci on ci.cam_id = co.CamId
	where co.CamId = @camId
	and co.DispotitionId = @dispotitionId
	group by  co.CamId, co.statusCallId,description,descripcion,cso.califSubDesc
end
else if @action=6 begin	
	select 0 as [type],CamId as CampId
	, ca.[description] as Calification
	, isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName
	, count(ctcs.califSubDesc) as Quantity
	--,dash.DispotitionId
	from ccDispositionDashboardResultIn dash
	left join ccTipoCalif ca on dash.DispotitionId = ca.calif_id
	left join ccInbound cci on cci.inbound_id = dash.CamId
	left join ccTipoCalifSub ctcs on dash.SubDispotitionId = ctcs.califSub_id
	where dash.CamId=@camId and dash.statusCallId=13 and dash.DispotitionId=@dispotitionId
	group by ca.description, dash.CamId,ctcs.califSubDesc,dash.DispotitionId
end
'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter Sp ccsp_RIAADMGetCalifDay else if @type = 2 begin linea 702, else if @type = 4 Linea 755'
    set @sql = 'ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]
@type smallint = null,
@inbound_id smallint = null,
@calif_id smallint = null,
@cam_id smallint = null
AS
set nocount on
create table #CalifTemp (
id int identity,
tipo integer,
Cam_id varchar(60),
Calificacion varchar(60),
subCalificacion varchar(60) null,
calif_id smallint null,
Total int,
iTotal4Campaign int null)

declare @typeACD smallint --= 0
declare @today datetime
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)

set @today = convert(datetime, convert (varchar(11), getdate(), 101))
select @typeACD = chat from ccInbound  where Inbound_id = @inbound_id


select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end,
@nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
from ccsettings where setting_id = 27 -- 0 esp

---------------OUT ----------------------------
if @type=0 begin
	insert into #CalifTemp
	select 0 as tipo,co.cam_id as cam_id,
	case when co.statuscall_id = 13
		then case when description is not null
		then description else @nIdioma end
	else case when sll.descripcion is not null then ''cw:'' + sll.descripcion
	else ''cw:'' + @nIdioma
	end end as Calificacion
	,0 as subCalificaion,
	co.calif_id,count(*) cantidad,0 as iTotal4Campaign
	from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
	left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
	left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
	left join ccCamps ci on ci.cam_id = co.cam_id
	where co.cal_inicio > @today
	group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id

	select tipo,Cam_id, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end as Calificacion,
	case when count(subCalificacion)>0 then 1 else 0 end subCalificacion, calif_id,sum(Total) as Total
	from #CalifTemp
	group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end, Cam_id, iTotal4Campaign,calif_id

end
---------------IN ----------------------------
else if @type = 1 begin

	if @typeACD = 0 begin  --Calls
		insert into #CalifTemp
		select @typeACD as tipo,cci.inbound_id as cam_id, description as Calificacion
		,case when count(ci.califSub_id) >0 then 1 else 0 end as subCalificacion,ci.calif_id
		,count(*) as total,0 as iTotal4Campaign
		from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
		left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		left join ccInbound cci on cci.inbound_id = ci.inbound_id
		left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
		where ci.cal_inicio > @today and statuscall_id = 13	and cci.Inbound_id=@inbound_id
		group by description, cci.inbound_id,ci.calif_id

	if (select valor from ccSettings where setting_id = 78) = 0 begin
		update #CalifTemp set iTotal4Campaign = 0
	end
	else begin
	update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign
		from (
			select cam_id, sum(A.Total) iTotal4Campaign from #CalifTemp A group by cam_id) t
		inner join #CalifTemp c on t.cam_id = c.cam_id
	end
	end
	else if @typeACD = 1 begin--Chats
		insert into #CalifTemp(tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
		select @typeACD as tipo, inboundId as Cam_id, [description] as Calificacion,
		case when sum(case when a.subDisposition = 0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
		a.disposition as calif_id, count(disposition) as Total
		from ccriachats a
		left join ccTipoCalif b on a.disposition=b.calif_id
		where a.chatDate > @today and
		a.chatStatus=4 and a.inboundId=@inbound_id
		group by inboundId, [description],disposition
	end
	else if @typeACD = 3 begin ---Mail
		insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
		select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
		case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
		relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
		from conversation conver
		inner join message mess on mess.conversationId = conver.conversationId
		left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
		left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
		where mess.date > @today and
		conver.inboundId=@inbound_id and mess.messageStatusId >= 5
		group by conver.inboundId,relmesdis.dispositionId,disp.Description

	end
	else if @typeACD = 4 begin --calif twetter
		insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
		select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
		case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
		relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
		from conversationTwitter conver
		inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
		left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
		left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
		where mess.date > @today and
		conver.inboundId=@inbound_id and mess.messageStatusId >= 5
		group by conver.inboundId,relmesdis.dispositionId,disp.Description

	end
	select camtemp.tipo,camtemp.cam_id,
	case when tipcal.Description is not null then tipcal.Description else @nIdioma end as Calificacion,
	camtemp.subcalificacion,camtemp.calif_id,camtemp.total
	from #CalifTemp camtemp
	left join ccTipoCalif tipcal on camtemp.calif_id =  tipcal.calif_id
end
-------------------SUBCALIFICACIONES IN-------------------
else if @type = 2 begin
	if @typeACD = 0 begin --Calls		
		exec ccspSaveDispositionResult @action=6,@callType=0,@camId=@inbound_id,@dispotitionId=@calif_id

		--select @typeACD as Type,cci.inbound_id as CampId,  [description] as Calification,
		--isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName, count(ctcs.califSubDesc) as Quantity
		--from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
		--left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		--left join ccInbound cci on cci.inbound_id = ci.inbound_id
		--left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
		--where ci.cal_inicio > @today
		--and ci.inbound_id = @inbound_id  and statuscall_id = 13  and ci.calif_id = @calif_id
		--group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id
	end
	else if @typeACD = 1 begin --Chat
		select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
				isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
				from ccriachats a
				left join ccTipoCalif b on a.disposition=b.calif_id
				left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
				where a.chatDate > @today and
				a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id
				group by inboundId, [description],ctcs.califSubDesc
	end
	else if @typeACD = 3 begin --Mail
	select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
	isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
	from conversation conver
	inner join message mess on mess.conversationId = conver.conversationId
	left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
	left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
	left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
	where mess.date > @today and
	mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
	group by conver.inboundId,disp.Description,subDisp.califSubDesc


	end
	else if @typeACD = 4 begin --Twitter
	select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
	isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
	from conversationTwitter conver
	inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
	left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
	left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
	left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
	where mess.date > @today and
	mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
	group by conver.inboundId,disp.Description,subDisp.califSubDesc
	end

end
-------------------SUBCALIFICACIONES OUT-------------------
else if @type = 4 begin
	exec ccspSaveDispositionResult @action=5,@callType=1,@camId=@inbound_id,@dispotitionId=@calif_id
	
end


drop table #CalifTemp
set nocount off'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter SP ccsp_RIAADMGetCalifDayForced if @type=0 begin linea 811, if @type=1 begin linea 836'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAADMGetCalifDayForced]
@type smallint,
@cam_id smallint,
@calif_id smallint = null
AS 
set nocount on
create table #CalifTemp (id int identity,
tipo integer, 
Cam_id varchar(50), 
Calificacion varchar(60), 
subCalificacion varchar(60) null,
calif_id smallint null,
Total int,
GraphColor varchar(15)) 

declare @today datetime
set @today = convert(datetime, convert (varchar(11), getdate(), 101))
--set @today =convert(datetime, convert (varchar(11), ''2015-10-01 17:50:20.470'', 101))

-- Seleccion de idioma -- 
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
from ccsettings where setting_id = 27 -- 0esp

select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
from ccsettings where setting_id = 27 -- 0 esp

if @type=0 begin
insert into #CalifTemp 
exec ccspSaveDispositionResult @action=3,@callType=1,@camId=@cam_id

end


if @type=1 begin
insert into #CalifTemp
exec ccspSaveDispositionResult @action=4,@callType=0,@camId=@cam_id

end


-- Se corrigio suma de totales -- 
Alter table #CalifTemp add iTotal4Campaign int null

if (select valor from ccSettings where setting_id = 78) = 0 begin
	update #CalifTemp set iTotal4Campaign = 0
end
else begin	
	update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
	from (select cam_id, sum(A.Total) iTotal4Campaign
	from #CalifTemp A group by cam_id) t join #CalifTemp c
	on t.cam_id = c.cam_id
end

if @type=1 begin
	select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total, GraphColor from (
	select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
	 else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	 end as Calificacion,0 as subCalificacion ,0 as calif_id,count(disposition) as Total,ISNULL(GraphColor,''1DB4E2'') GraphColor--,0 as iTotal4Campaign
	from ccriachats a left join ccTipoCalif b 
	on a.disposition=b.calif_id 
	where a.chatDate > @today
	and a.inboundId = @cam_id
	group by inboundId, Description, GraphColor
	
	union all
	
	
	select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	then calificacion 
	else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
	end as Calificacion,
	case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor  --iTotal4Campaign -- para ver total por campaña
	from #CalifTemp 
	group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	then calificacion 
	else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
	end, Cam_id,calif_id, iTotal4Campaign, GraphColor
	)  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id,GraphColor order by tipo,cam_id 
end
if @type=0 begin

	select tipo as Type,Cam_id as CampId,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	then calificacion 
	else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
	end as Calification,subCalificacion as SubCalificationQuantity, calif_id as CalificationId,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor -- , iTotal4Campaign -- para ver total por campaña
	from #CalifTemp 
	group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	then calificacion 
	else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
	end, Cam_id,subCalificacion, calif_id, iTotal4Campaign, GraphColor
end


if @type = 3 begin -----entrada acd''s
	select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
	else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	end as Calificacion,isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(*) as totales 
	from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
	left join ccInbound cci on cci.inbound_id = ci.inbound_id 
	left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
	where ci.cal_inicio > @today
	and ci.inbound_id = @cam_id
	and statuscall_id = 13 
	and ci.calif_id = @calif_id
	group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id 
end

if @type = 4 begin --salida campañas
	select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
		then case when description is not null 
					then description 
					else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
					end
	else case when sll.descripcion is not null 
	then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	end end as Calificacion,isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad 
	from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
	left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
	left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
	left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
	left join ccCamps ci on ci.cam_id = co.cam_id 
	where co.cal_inicio > @today
	and co.cam_id = @cam_id
	group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
end 
 

drop table #CalifTemp 
set nocount off'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter Sp spInsertCall se agerga ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER PROCEDURE [dbo].[spInsertCall]
@Pto smallint,
@DNIS varchar(14),
@ANI as varchar(14),
@inbound_id smallint=0,
@IVR_id int = 0, --Id del IVR
@CALLDATA as varchar(1275) = ''''
AS
declare @dni_id as smallint
declare @cal_id as int
declare @datacall as varchar(100)

select @Ani = left(rtrim(ltrim(@ANI)), 13)
select @DNIS = rtrim(ltrim(@DNIS))

  --busca dni_id
  select @dni_id = isnull ( ( select dni_id From ccDNIS Where dni_numero =  @DNIS and dni_status = 1 ), 0)
  
  --busca especialidad
  IF @inbound_id =0 and @dni_id >0
    select @Inbound_id=ED.Inbound_id from ccInboundDnis ED where ED.dni_id = @dni_id
  
  INSERT ccCallsIN ( cal_ANI, dni_id, cal_puerto, cal_Inicio, inbound_id, IVR_id )
  VALUES ( @ANI, @dni_id, @Pto, getdate(), @inbound_id, @IVR_id )

  select @cal_id = scope_identity()

  exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@inbound_id,@callType=0,@statusCallId=1

  IF @inbound_id > 0 
  BEGIN
    insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
    select idwg, @cal_id, 0 as user_id, getdate() timestamp, 0 as tipo from ccRIACampEspWG wg   
    where wg.tipo = 0 and wg.IdCampEsp = @Inbound_id

  END

  IF @CALLDATA <> ''''  BEGIN -- Transfer Reminder
    set @CALLDATA=SUBSTRING(@CALLDATA,0,len(@CALLDATA)-2)
    insert into DataCallIn (CallId, Data, Description) 
    select @cal_id,value,''Dato ''+cast(id as varchar(max)) from dbo.[fn_RIASplitDelimited](@CALLDATA,''~'')
  END

  Select @cal_id as IDCall, @dni_id as IDdnis'
    EXEC(@sql)

    set @process = 'DEV1-409 DEV1-409 Alter Sp ccsp_AGENTInsertCallOut se agerga ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AGENTInsertCallOut]
@cam_id smallint,
@cal_Key varchar(40),
@cal_Telefono varchar(30),
@user_id int,
@cal_extension varchar(7),
@sData varchar(255) = '''', --HLAS para guardar notas de la llamada
@existCallOut as int = 0,
@callmode as smallint = 0
AS
set 
nocount on
declare @fecha as datetime, @callout_id as int, @cal_id as int, @calloutMaxTime as int
select @fecha=getdate()
declare @dialPrefix integer
select @dialPrefix = valor from ccSettings where setting_id = 202

if @callmode = 1 begin
	INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
	select @existCallOut, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 0, @cal_extension
	select @cal_id = scope_identity()

	exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=11

	insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
	select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
	from ccRIACampEspWG wg 
	where wg.tipo = 1 and wg.idcampesp =@cam_id

	select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
	select @existCallOut as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
  return(0)
end

if @existCallOut=0  begin
	declare @prefijoMarcacion varchar(100) 
	set @prefijoMarcacion = ''''
	declare @LasCallKey varchar(20)
	set @LasCallKey = @cal_Key
	declare @settingCallKey as int
	select @settingCallKey = valor from ccSettings where setting_id = 194

	if(@settingCallKey = 1) begin
		if (@cal_Key='''' or @cal_Key is null) begin   
			select top 1 @LasCallKey=cal_Key from ccoCallsOut where cam_id=@cam_id and cal_Inicio>=convert(datetime,getdate()) and cal_manual=0 order by cal_id desc
			set @cal_Key= @LasCallKey
		end
	end

	if @dialPrefix = 1 and len(@cal_telefono)>20
		begin
			set @prefijoMarcacion = LEFT(@cal_telefono ,len(@cal_telefono)-10)
			set @cal_telefono = RIGHT(@cal_telefono,10)		
		end
	else 
		begin
			set @prefijoMarcacion =''''			 
		end

	INSERT ccocallsoutsource (cal_key, cam_id, cal_telefono, cal_status, user_id, cal_fechaDial, dato1,dialPrefix)
	select @cal_Key, @cam_id, substring(@cal_Telefono, 1, 19), 6, @user_id, @fecha, @sData,@prefijoMarcacion
	select @callout_id = scope_identity()

	INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
	select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension
	select @cal_id = scope_identity()

	exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=11
 end

else begin --@existCallOut<>0
	Update ccocallsoutsource set cam_id=@cam_id, cal_telefono=substring(@cal_Telefono, 1, 19), dato1=@sData where callout_id = @existCallOut	
	Update ccocallsout set cam_id=@cam_id, cal_telefono=@cal_Telefono where callout_id = @existCallOut

	set @callout_id = @existCallOut

	select top 1 @cal_id=cal_id from ccocallsout where callout_id = @callout_id order by cal_id desc

	if exists(select * from ccoLogDials where cal_id=@cal_id) begin
		INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
		select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension
		select @cal_id = scope_identity()

		exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=11
	end
 
 end

insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
from dbo.ccRIACampEspWG wg 
where wg.tipo = 1 and wg.idcampesp =@cam_id


select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
select @callout_id as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
return(0)
set nocount off
		'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter Sp ccsp_DLRAfterXferAge se agerga ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRAfterXferAge]
@cal_id int,
@User_id smallint,
@cal_extension varchar(7)

AS
set nocount on
if @cal_id=0
 return(0)
		
Update ccoCallsOut SET user_id=@User_id, cal_extension=@cal_extension, statusCall_id=11  -- 11=Asignada
where cal_id=@cal_id

update ccRIAWorkGroup_Calid set user_id=@User_id where cal_id = @cal_id and tipo = 1

exec ccspSaveDispositionResult @action=2,@callid=@cal_id,@callType=1,@statusCallId=11

-- calcula el costo de la llamada
exec ccsp_CstoCalculaCosto @cal_id
return(0)
set nocount off'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter SP ccsp_DLRInsertCall ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRInsertCall]
@callout_id int,
@cam_id smallint,
@cal_Key varchar(20),
@cal_Telefono varchar(14),
@Puerto smallint,
@logDial_id int=0
AS
declare @fecha as datetime
declare @cal_id as int

select @fecha=getdate()
INSERT ccoCallsOUT ( callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id ) --''Status 6=Pide Agente
  VALUES ( @callout_id, @cam_id, @cal_Key, @cal_Telefono, @Puerto,  @fecha, 6 )

select @cal_id = scope_identity()

insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo from ccRIACampEspWG wg with(nolock)
where wg.Tipo=1 and wg.idcampesp=@cam_id


exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=6

-- calcula el costo de la llamada
exec ccsp_CstoCalculaCosto @cal_id

select @cal_id as cal_id
'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter Sp ccsp_DLRUpdateCallSetStatus ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRUpdateCallSetStatus]
@cal_id int,
@nStatus tinyint
AS
IF @nStatus=5 	--En Espera
BEGIN
	Update ccoCallsOut SET cal_que=1, statusCall_id=5 --En Espera
	where cal_id=@cal_id
END
ELSE
BEGIN
	Update ccoCallsOut SET statusCall_id=@nStatus
	where cal_id=@cal_id	
END

exec ccspSaveDispositionResult @action=2,@callid=@cal_id,@callType=1,@statusCallId=@nStatus'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter Sp ccsp_AgentSetCallStatus ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentSetCallStatus] 
@callout_id INT, 
@cal_id     INT, 
@TipoCall   TINYINT, -- 1= IN,  2=Out
@TipoMov    TINYINT, -- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
@cal_tXfer  TINYINT    = 0, 
@cal_tring  SMALLINT   = 0, 
@user_id    SMALLINT   = 0, 
@extension  VARCHAR(5) = '''', 
@isChatCall BIT        = 0
AS
SET NOCOUNT ON
DECLARE @RecicleSIC TINYINT

SELECT @RecicleSIC = ISNULL(valor, 0)
FROM ccSettings
WHERE setting_id = 60

DECLARE @ANI_x VARCHAR(19)
DECLARE @cal_inicio DATETIME
DECLARE @callout_id_IN INT
DECLARE @cal_key VARCHAR(20)
DECLARE @cam_id INT
DECLARE @cal_telefono VARCHAR(30)
DECLARE @surveycamid INT
DECLARE @inbound_id INT
IF @TipoMov in(4 ,14) BEGIN-- DIALOG OnDialog    
   IF @TipoCall = 2 BEGIN
		IF @TipoMov = 4 BEGIN
            UPDATE ccoCallsOUT WITH(ROWLOCK)
            SET cal_Inicio = GETDATE(), 
                statusCall_id = 13, 
                cal_manual = CASE
                                WHEN @isChatCall = 1
                                THEN 3
                                ELSE cal_manual
                            END
            WHERE cal_id = @cal_id
		END
		ELSE IF @TipoMov = 14 begin
            UPDATE ccoCallsOUT WITH(ROWLOCK)
            SET statusCall_id = 13, 
                cal_tRing = @cal_tring, 
                user_id = case when user_id=0 and @user_id>0 then @user_id else user_id end, 
                cal_extension = case when cal_extension=0 and @extension>0 then @extension else cal_extension end
            WHERE cal_id = @cal_id
		end
        IF @RecicleSIC = 0
            BEGIN
                DELETE ccoWorkingTable WITH(ROWLOCK)
                WHERE callout_id = @callout_id

                DELETE ccoCallPriorityOrder WITH(ROWLOCK)
                WHERE callout_id = @callout_id
        END

        UPDATE ccoCallBacks
        SET [status] = 1, 
            schedulerStatus = 1, 
            cal_fcallback = cal_inicio
        FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
        WHERE a.callout_id = b.callout_id
            AND b.callout_id = @callout_id
            AND b.cal_id = @cal_id
            AND [status] = 0
            AND statusCall_id = 13

		exec ccspSaveDispositionResult @action=2, @callid=@cal_id,@callType=1,@statusCallId=13
        -- calcula el costo de la llamada
        EXEC ccsp_CstoCalculaCosto @cal_id

    RETURN(0)
	END
    IF @TipoMov = 4 begin            
		UPDATE ccCallsIN WITH(ROWLOCK)
		SET statusCall_id = 13
		WHERE cal_id = @cal_id
	end

    ELSE IF @TipoMov = 14 begin
        UPDATE ccCallsIN WITH(ROWLOCK)
        SET statusCall_id = 13, 
            cal_tRing = @cal_tring, 
            user_id = case when user_id=0 and @user_id>0 then @user_id else user_id end, 
            cal_extension = case when cal_extension=0 and @extension>0 then @extension else cal_extension end
        WHERE cal_id = @cal_id
	end

	exec ccspSaveDispositionResult @action=2, @callid=@cal_id,@callType=0,@statusCallId=13
    -- Elimina callback generado por abandono
    SELECT @ANI_x = cal_ani, 
        @cal_inicio = cal_inicio
    FROM cccallsin WITH (INDEX(PK_ccCallsIn))
    WHERE cal_id = @cal_id

    SELECT @callout_id_IN = callout_id
    FROM ccRIAUpdateCallBack_Abandon
    WHERE cal_ani = @ANI_x

    UPDATE ccoCallBacks WITH(ROWLOCK)
    SET [status] = 1, 
        schedulerStatus = 1, 
        cal_fcallback = @cal_inicio
    WHERE callout_id = @callout_id_IN
        AND [status] = 0

    DELETE ccoWorkingTable WITH(ROWLOCK)
    WHERE callout_id IN
    (
        SELECT DISTINCT
            (callout_id)
        FROM ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
        WHERE cal_ani = @ANI_x
    )

    DELETE ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
    WHERE cal_ANI = @ANI_x

    RETURN(0)
END
IF @TipoMov = 7 BEGIN--OTHER OFFHook_OnXfer
	IF @cal_id <= 0
		RETURN(0)
    IF @TipoCall = 2 BEGIN
        UPDATE ccoCallsOUT WITH(ROWLOCK)
        SET statusCall_id = 16
        WHERE cal_id = @cal_id
        -- calcula el costo de la llamada

        UPDATE ccoCallBacks
        SET [status] = 2, 
            schedulerStatus = 1, 
            cal_fcallback = cal_inicio
        FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
        WHERE a.callout_id = b.callout_id
            AND b.callout_id = @callout_id
            AND b.cal_id = @cal_id
            AND [status] = 0
            AND statusCall_id = 16


		exec ccspSaveDispositionResult @action=2, @callid=@cal_id,@callType=1,@statusCallId=16

        EXEC ccsp_CstoCalculaCosto @cal_id

		RETURN(0)
    END

    UPDATE ccCallsIN WITH(ROWLOCK)
    SET statusCall_id = 16
    WHERE cal_id = @cal_id

	--exec ccspSaveDispositionResult @action=2, @callid=@cal_id,@callType=0,@statusCallId=16

    SELECT @ANI_x = cal_ani, 
        @cal_inicio = cal_inicio
    FROM cccallsin WITH (INDEX(PK_ccCallsIn))
    WHERE cal_id = @cal_id

    SELECT @callout_id_IN
    FROM ccRIAUpdateCallBack_Abandon
    WHERE cal_ani = @ANI_x

    UPDATE ccoCallBacks WITH(ROWLOCK)
    SET [status] = 2, 
        schedulerStatus = 1, 
        cal_fcallback = @cal_inicio
    WHERE callout_id = @callout_id_IN
        AND [status] = 0

    RETURN(0)
END
IF @TipoMov = 9 BEGIN--RING CallNoAnswered    
    IF @TipoCall = 2 BEGIN
        
        UPDATE ccoCallsOUT WITH(ROWLOCK)
        SET statusCall_id = 15, 
            cal_tXFer = @cal_txFer, 
            cal_tRing = @cal_tring
        WHERE cal_id = @cal_id

		exec ccspSaveDispositionResult @action=2, @callid=@cal_id,@callType=1,@statusCallId=15

        -- calcula el costo de la llamada

        UPDATE ccoCallBacks
        SET [status] = 2, 
            schedulerStatus = 1, 
            cal_fcallback = cal_inicio
        FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
        WHERE a.callout_id = b.callout_id
            AND b.callout_id = @callout_id
            AND b.cal_id = @cal_id
            AND [status] = 0
            AND statusCall_id = 15

        EXEC ccsp_CstoCalculaCosto @cal_id

		return (0);
    END

    UPDATE ccCallsIN WITH(ROWLOCK)
    SET statusCall_id = 15, 
        cal_tXFer = @cal_txFer, 
        cal_tRing = @cal_tring
    WHERE cal_id = @cal_id

	--exec ccspSaveDispositionResult @action=2, @callid=@cal_id,@callType=0,@statusCallId=15

    SELECT @ANI_x = cal_ani, 
        @cal_inicio = cal_inicio
    FROM cccallsin WITH (INDEX(PK_ccCallsIn))
    WHERE cal_id = @cal_id

    SELECT @callout_id_IN
    FROM ccRIAUpdateCallBack_Abandon
    WHERE cal_ani = @ANI_x

    UPDATE ccoCallBacks WITH(ROWLOCK)
    SET [status] = 2, 
        schedulerStatus = 1, 
        cal_fcallback = @cal_inicio
    WHERE callout_id = @callout_id_IN
        AND [status] = 0

    RETURN(0)
END
SET NOCOUNT OFF'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter Sp ccsp_AgentUpdateCallCALIF ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentUpdateCallCALIF] @IDCall INT, @calif_id SMALLINT, @TipoCall SMALLINT, @Origin INT = 0, @cal_key VARCHAR(20) = NULL, @callOutId INT = 0, @subId SMALLINT = 0
AS
SET NOCOUNT ON

DECLARE @RecicleSIC TINYINT, @Reprogram TINYINT, @DateNewDial SMALLDATETIME, @idTipoLista INT, @autoCB TINYINT, @tel VARCHAR(30), @camp INT, @iddncList AS INT
DECLARE @userid INT
declare @statusCallId int
SELECT @RecicleSIC = valor
FROM ccSettings
WHERE setting_id = 60

SELECT @RecicleSIC = IsNull(@RecicleSIC, 0)

DECLARE @hashTel INT
DECLARE @killListID INT = (
		SELECT idtipolista
		FROM ccTiposListaNegra
		WHERE Tipolista = ''default/KillList''
		)
DECLARE @killListSetting INT = (
		SELECT STATUS
		FROM ccSettings
		WHERE setting_id = 215
		)

IF @TipoCall = 1
BEGIN
	UPDATE ccCallsIN
	SET calif_id = @calif_id, cal_origin_id = @Origin, cal_key = isnull(@cal_key, cal_key)
	, califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
	,@statusCallId=statusCall_id
	WHERE cal_id = @IDCall


	exec ccspSaveDispositionResult @action=2, @callid=@IDCall, @camId=@camp,@callType=0,
	@dispotitionId=@calif_id,@subDispotitionId=@subId,@statusCallId=13

	IF EXISTS (
			SELECT idTipoLista
			FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
			WHERE tipo = 0 AND calif_id = @calif_id
			)
	BEGIN
		SELECT @tel = dbo.Completa_ListaNegra(ci.cal_ANI), @iddncList = cbl.idTipoLista
		FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
		JOIN cccalifblacklist AS cbl ON ci.calif_id = cbl.calif_id
		WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0

		IF @tel IS NOT NULL AND @iddncList IS NOT NULL
		BEGIN
			--insert ccListaNegra
			INSERT INTO cclistanegra (telefono, idtipolista)
			VALUES (@tel, @iddncList)

			--insert cc_killlist
			IF (@killListSetting = 1 AND @iddncList = @killListID) -- verifies if kill list setting is active and if the list_id matches killList id
			BEGIN
				select @hashTel = dbo.hashPhone(@tel)

				IF NOT EXISTS (
						SELECT hashtel
						FROM cc_KillList
						WHERE hashTel = @hashTel
						)
				BEGIN
					INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
					VALUES (@hashTel, @iddncList, GETDATE())
				END
			END

			INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			SELECT dbo.Completa_ListaNegra(ci.cal_ANI), cbl.idTipoLista, ci.Inbound_id, getdate(), ci.dni_id, 6
			FROM ccCallsIN ci WITH (INDEX (PK_ccCallsIn))
			JOIN cccalifblacklist cbl ON ci.calif_id = cbl.calif_id
			WHERE ci.cal_id = @idCall AND left(dbo.Completa_ListaNegra(ci.cal_ANI), 1) <> ''E'' AND cbl.tipo = 0
		END
	END

	RETURN (0)
END

IF @TipoCall = 2
BEGIN
	-- Toma como prioridad la configuraci?n de la subcalificaci?n (en caso de existir)
	SELECT @autoCB = autocallback
	FROM ccTipoCalifSubout
	WHERE califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	IF @autoCB IS NULL
	BEGIN
		SELECT @autoCB = autocallback
		FROM cctipocalifout
		WHERE calif_id = @calif_id
	END

	SELECT @callOutId = callout_id, @camp = cam_id, @userid = user_id
	,@statusCallId=statusCall_id
		FROM ccocallsout
		WHERE Cal_id = @IDCall

	IF @autoCB = 1
	BEGIN
		--SELECT @callOutId = callout_id, @camp = cam_id, @userid = user_id
		--FROM ccocallsout
		--WHERE Cal_id = @IDCall

		SELECT @DateNewDial = dateadd(mi, t_autoCB, getdate())
		FROM cccamps cam
		WHERE cam.cam_id = @camp

		EXEC ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
	END

	UPDATE ccoCallsOUT
	SET calif_id = @calif_id, califSub_id = CASE @subId WHEN 0 THEN NULL ELSE @subId END
	WHERE cal_id = @IDCall

	exec ccspSaveDispositionResult @action=2, @callid=@IDCall, @camId=@camp,@callType=1,
	@dispotitionId=@calif_id,@subDispotitionId=@subId,@statusCallId=@statusCallId

	IF EXISTS (
			SELECT idTipoLista
			FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
			WHERE tipo = 1 AND calif_id = @calif_id
			) AND NOT EXISTS (
			SELECT co.cal_telefono
			FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
			JOIN ccListaNegra bl ON dbo.Completa_ListaNegra(co.cal_telefono) = bl.telefono OR co.cal_telefono = bl.telefono
			WHERE co.cal_id = @idCall AND bl.idtipolista IN (
					SELECT idTipoLista
					FROM cccalifblacklist WITH (INDEX (IX_cccalifblacklist))
					WHERE tipo = 1 AND calif_id = @calif_id
					)
			)
	BEGIN --IF

		CREATE TABLE #NUMANDBL (id int identity,  iddncList int)
		CREATE TABLE #NUMBERS (id int identity, number varchar(30))
		DECLARE @allnumbersToBl BIT
		DECLARE @number varchar(30)

		SELECT @allnumbersToBl = allNumbersToBlacklist FROM ccTipoCalifOUT WHERE calif_id = @calif_id

		IF(@allnumbersToBl = 1)
		BEGIN
			DECLARE @camid SMALLINT
			SELECT @camid = cam_id FROM ccoCallsOut WITH (INDEX (PK_ccoCallsOut)) WHERE cal_id = @IDCall
			DECLARE @i SMALLINT = 0
			WHILE (@i < 5 )
			BEGIN
				SELECT @number = CASE @i 
									WHEN 0 THEN cal_telefono 
									WHEN 1 THEN cal_telefono2
									WHEN 2 THEN cal_telefono3
									WHEN 3 THEN cal_telefono4
									WHEN 4 THEN cal_telefono5
									END FROM ccoCallsOutSource WHERE callout_id = @callOutId AND cam_id = @camid
				SET @number = dbo.Completa_ListaNegra(@number)
				IF(LEFT(@number, 1) <> ''E'') 
				BEGIN
					INSERT INTO #NUMBERS (number) VALUES (@number)
				END
				SET @i = @i + 1
			END
		END
		ELSE
		BEGIN
			SELECT @number = co.cal_telefono
			FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
			WHERE co.cal_id = @idCall 
			SET @number = dbo.Completa_ListaNegra(@number)
			IF(LEFT(@number, 1) <> ''E'') 
			BEGIN
				INSERT INTO #NUMBERS (number) VALUES (@number)
			END
		END

		IF((SELECT COUNT(*) FROM #NUMBERS) > 0) begin
			INSERT INTO #NUMANDBL (iddncList) 
			select cbl.idTipoLista from cccalifblacklist cbl  where cbl.calif_id=@calif_id and cbl.tipo = 1
		END

		DECLARE @Count int		
		WHILE (SELECT count(id) from #NUMANDBL) > 0
		BEGIN  --WHILE
			select @Count = count(id) from #NUMANDBL
			SELECT @iddncList = iddncList from #NUMANDBL where id = @Count
			DECLARE @countNumbers INT, @indexNumbers INT = 1
			SELECT @countNumbers = COUNT(*) FROM #NUMBERS
			WHILE( @indexNumbers <= @countNumbers) --WHILE NUMBERS
			BEGIN 
				SELECT @tel = number FROM #NUMBERS WHERE id = @indexNumbers
				IF @tel IS NOT NULL AND @iddncList IS NOT NULL
				BEGIN--Tel adn iddnclist
					EXEC ccsp_InsertDNCList @tel, @iddncList

					IF (@killListSetting = 1 AND @iddncList = @killListID)
					BEGIN
						select @hashTel = dbo.hashPhone(@tel)

						IF NOT EXISTS (SELECT hashtel FROM cc_KillList WHERE hashTel = @hashTel)
						BEGIN
							INSERT INTO cc_KillList (hashTel, id_tipoLista, DATE)
							VALUES (@hashTel, @iddncList, GETDATE())
						END
					END

					INSERT ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
					SELECT @tel, @iddncList, co.cam_id, getdate(), co.callout_id, 6
					FROM ccoCallsOut co WITH (INDEX (PK_ccoCallsOut))
					--JOIN cccalifblacklist cbl ON co.calif_id = cbl.calif_id
					WHERE co.cal_id = @idCall 
				END --Tel adn iddnclist
				SET @indexNumbers = @indexNumbers + 1
			END --WHILE NUMBERS
			delete from #NUMANDBL where id = @Count
		END --WHILE
		DROP TABLE #NUMANDBL
		DROP TABLE #NUMBERS
	END --IF
	IF @RecicleSIC = 1
	BEGIN
		-- Toma como prioridad la configuraci?n de la subcalificaci?n (en caso de existir)
		SELECT @Reprogram = CanReprogram
		FROM ccTipoCalifSubout
		WHERE califSub_Id = @subId

		-- Si no tiene subcalificacion toma la de la calificacion
		IF @Reprogram IS NULL
		BEGIN
			SELECT @Reprogram = CanReprogram
			FROM ccTipoCalifOUT
			WHERE calif_id = @calif_id
		END

		IF @callOutId = 0
			SELECT @callOutId = callout_id
			FROM ccocallsout
			WHERE Cal_id = @IDCall

		UPDATE ccoWorkingTable
		SET calif_id = @calif_id, cal_status = CASE @Reprogram WHEN 0 THEN 3 ELSE cal_status END
		WHERE callout_id = @callOutId
	END

	DECLARE @keepDial BIT
	DECLARE @finishPreview SMALLINT

	-- Toma como prioridad la configuraci?n de la subcalificaci?n (en caso de existir)
	SELECT @keepDial = keepDial
	FROM ccTipoCalifSubout
	WHERE califSub_Id = @subId

	-- Si no tiene subcalificacion toma la de la calificacion
	IF @keepDial IS NULL
	BEGIN
		SELECT @keepDial = keepDial
		FROM ccTipoCalifout
		WHERE calif_id = @calif_id
	END

	SELECT @finishPreview = isnull(finishPreview, 0)
	FROM ccTipoCalifout
	WHERE calif_id = @calif_id

	IF @keepDial = 1
	BEGIN
		UPDATE ccologdials
		SET TipoDialingMode = dbo.fn_getDialingMode(@IDCall, 3, 0, @camp)
		WHERE logDial_id IN (
				SELECT TOP 1 L.logDial_id
				FROM ccoLogDials L WITH (INDEX (IX_ccoLogDials_2), NOLOCK)
				JOIN ccoCallsOut O WITH (INDEX (PK_ccoCallsOut), NOLOCK) ON L.callout_id = O.callout_id
				WHERE O.cal_id = @IDCall
				ORDER BY L.logDial_id DESC
				)
	END

	SELECT @keepDial, @finishPreview

	RETURN (0)
END

SET NOCOUNT OFF'
    EXEC(@sql)

    set @process = 'DEV1-409 Alter Sp ccsp_AgentUpdateCallTimes ejecucion ccspSaveDispositionResult'
    set @sql = 'ALTER procedure [dbo].[ccsp_AgentUpdateCallTimes]
@IDCall int,
@cal_tXfer smallint,
@cal_tDialog smallint,
@cal_tNotas smallint,
@TipoCall tinyint,
@cal_tRing smallint=0,
@mtmoh smallint = 0,
@isChatCall bit = 0,
@isErroManualCall bit =0,
@isTransferEngine bit =0
AS
set nocount on
if @IDCall<=0 
    return(0)

declare @tMinAVRS smallint
declare @cal_manual int
declare @minimoDialogo tinyint 
select @minimoDialogo = valor from ccSettings where setting_id = 13

set @cal_manual=0

if @TipoCall=1 begin--INBOUND
  if @cal_tDialog < @minimoDialogo and @isTransferEngine =1 begin
    --el status 18 es para llamada cortada con transferencia en Reminder
    exec ccsp_RIAUpdateCallBack_Abandon @cal_id = @IDCall, @nStatus = 18
  end
  Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
  cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
  cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
  Where cal_id= @IDCall

  exec ccspSaveDispositionResult @action=2, @callid=@IDCall,@callType=0,@statusCallId=13


  --Actualizar tiempo total de llamada
  exec ccsp_EngineLogTransfers 2, @IDCall, @TipoCall, 2, null, @cal_tXfer, @cal_tDialog

  -- Elimina callback generado por abandono
  
  if @isTransferEngine = 0  begin
  Declare @ANI_x varchar(19)
  select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

  DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
  DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
  end
end
else if @TipoCall=2 begin--OUTBOUND 
    Update ccoCallsOUT with(rowlock) Set cal_tXfer=case when @cal_tXfer > 0 then @cal_tXfer else cal_tXfer end, 
    cal_tDialog=case when @cal_tDialog > 0 then @cal_tDialog else cal_tDialog end, 
    @cal_tDialog=case when @cal_tDialog > 0 then @cal_tDialog else cal_tDialog end,
    cal_tNotas=case when @cal_tNotas > 0 then @cal_tNotas else cal_tNotas end, 
    cal_tMoh=case when @mtmoh > 0 then @mtmoh else cal_tMoh end,
    cal_tRing=case when @cal_tRing > 0 then @cal_tRing else cal_tRing end, 
    cal_manual=case when @isChatCall=1 then 3 else cal_manual end,
    cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end,
    totalCall_Time=case when totalCall_Time is null then @cal_tDialog else totalCall_Time end 
    Where cal_id=@IDCall

	exec ccspSaveDispositionResult @action=2, @callid=@IDCall,@callType=1,@statusCallId=13

    -- calcula el costo de la llamada
    exec ccsp_CstoCalculaCosto @IDCall
  select @cal_manual=cal_manual from ccoCallsOUT with(nolock) Where cal_id=@IDCall

 end

select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

if @cal_tDialog >= @tMinAVRS and @cal_manual<>1
  and not exists(select * from ccAVRSTransfer where cal_id=@IDCall and tipo=@TipoCall - 1) 
  begin 
        insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
end

return(0)
 

set nocount off'
    EXEC(@sql)

    

    set @process = 'DEV1-409 '
    set @sql = ''
    EXEC(@sql)



	/* End script release */
	/* Upgrade database version (first and the last number of setting 77) */
	EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
	EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

	COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END