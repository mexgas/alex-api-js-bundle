set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
    Set @Version = 95
    Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if 1=1 -- @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
begin
    begin tran
    begin try

   ---------------------------------------BEGIN KR087000 Modificaciones Recordings Manager Exportacion Automatica ---------------------------------------------------------

   	SET @process = 'DEV1-474 KR087000 Drop procedure trsp_ExportManagerAutomatic'
	SET @sql = 'if exists (select * from sys.procedures where name = N''trsp_ExportManagerAutomatic'')
    begin
        DROP PROCEDURE trsp_ExportManagerAutomatic;
    end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Drop procedure trsp_GetParametersExportService'
	SET @sql = 'if exists (select * from sys.procedures where name = N''trsp_GetParametersExportService'')
    begin
        DROP PROCEDURE trsp_GetParametersExportService;
    end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Drop procedure trsp_SaveAVRSExportParameters'
	SET @sql = 'if exists (select * from sys.procedures where name = N''trsp_SaveAVRSExportParameters'')
    begin
        DROP PROCEDURE trsp_SaveAVRSExportParameters;
    end'
	EXEC(@sql)

    SET @process = 'DEV1-474 KR087000 create table ccConfigurationExportManagerAutomatic'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccConfigurationExportManagerAutomatic'') begin
create table ccConfigurationExportManagerAutomatic(
	ccConfigurationExportId bigint Not null identity primary key,
	DateStartExport datetime null,
	DateEndExport  datetime null,
	Json varchar(4000) not null,	
	ExportStatus tinyint not null--0 Create,1 Process ,2 End,3 Cancelada
)
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 create table ccExportStatusConfiguration'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccExportStatusConfiguration'') begin
create table ccExportStatusConfiguration(
	ExportStatusId tinyint not null primary key,
	Description varchar(150) not null
)
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 create table ccExportManagerAutomatic'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccExportManagerAutomatic'') begin
create table ccExportManagerAutomatic(
	GrabId bigint Not null,
	ccConfigurationExportId bigint not null,
	DateDownload datetime not null,
	StatusId tinyint not null,
	FOREIGN KEY (ccConfigurationExportId) REFERENCES ccConfigurationExportManagerAutomatic(ccConfigurationExportId)
)
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 create table ccStatusExportManager'
	SET @sql = 'if not exists(select * from sys.tables where name=''ccStatusExportManager'') begin
create table ccStatusExportManager(
	StatusId tinyint not null primary key,
	Description varchar(150) not null
)
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 update TREC_PARAMETROS par_id=65'
	SET @sql = 'update TREC_PARAMETROS 
set par_valor=''1'' 
where par_id=65 and par_valor=''C:\Centerware/Sites/CWAdminEngine/AVRSExportRecs'''
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Add insert ccStatusExportManager y ccExportStatusConfiguration'
	SET @sql = 'if not exists(select * from ccStatusExportManager) begin
	insert into ccStatusExportManager values(0,''Scheduled'')
	insert into ccStatusExportManager values(1,''Downloaded'')
	insert into ccStatusExportManager values(2,''Export error'')
	insert into ccStatusExportManager values(3,''Cancelled'')
end
if not exists(select * from ccExportStatusConfiguration) begin
	insert into ccExportStatusConfiguration values(0,''Create'')
	insert into ccExportStatusConfiguration values(1,''Process'')
	insert into ccExportStatusConfiguration values(2,''End'')
	insert into ccExportStatusConfiguration values(3,''Cancelada'')
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Add TREC_PARAMETROS par_id 77 y 78'
	SET @sql = 'if not exists(select * from TREC_PARAMETROS where par_id =77) begin
	insert into TREC_PARAMETROS values(77,''Configuracion Automatica descarga Ftp AvrsExport'','''',''Configuracion formato Json para exportar grabaciones'');
end
if not exists(select * from TREC_PARAMETROS where par_id =78) begin
	insert into TREC_PARAMETROS values(78,''Id Export Configuration'',''0'',''Id de la tabla ccConfigurationExportManagerAutomatic'');
end'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 alter COLUMN TREC_PARAMETROS par_valor'
	SET @sql = 'alter table TREC_PARAMETROS ALTER COLUMN par_valor varchar(4000);'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 alter Sp trsp_AdmRecSearchCallIdStr'
	SET @sql = 'ALTER PROCEDURE [dbo].[CW_trsp_AdmRecSearchAllRecs]
@Sup_id int,
@dateStart datetime,
@dateEnd datetime,
@IdCallList varchar(MAX) =null,
@UserList varchar(MAX) =null,
@IDWGList varchar(MAX) =null,
@TypeCall int = null,
@CampaingsList varchar(MAX) =null,
@ACDList varchar(MAX) =null,
@DispositionList varchar(MAX) =null,
@SubdispositionList varchar(MAX) =null,
@GrabId bigInt = null,
@TopRecords int = 0

AS
		declare @encrypted bit
		select @encrypted = par_valor from TREC_PARAMETROS where par_id = 15
;
			
IF OBJECT_ID(''tempdb..#userAgent'') IS NOT NULL
	DROP TABLE #userAgent
IF OBJECT_ID(''tempdb..#tmpRecords'') IS NOT NULL
	DROP TABLE #tmpRecords
IF OBJECT_ID(''tempdb..#WorkGroupCamps'') IS NOT NULL
	DROP TABLE #WorkGroupCamps
IF OBJECT_ID(''tempdb..#tmpWGconcat'') IS NOT NULL
	DROP TABLE #tmpWGconcat

CREATE TABLE #userAgent(UserId smallint);

IF((select [User_id] from ccUsers WHERE [Login] = ''root'') = @Sup_id)
BEGIN
	INSERT INTO #userAgent(UserId)
		select distinct User_id as UserId from ccRIAWorkGroupUsersConsulta
END
ELSE
BEGIN
	INSERT INTO #userAgent(UserId)
	select distinct User_id as UserId from ccRIAWorkGroupUsersConsulta where IDWG in(
		select distinct IDWG from ccRIAWorkGroupUsersConsulta where User_id = @Sup_id)
END

CREATE TABLE #WorkGroupCamps(IDWG smallint, WGName varchar(50),  cam_id smallint, campType smallint, campName varchar(50));

INSERT INTO #WorkGroupCamps(IDWG, WGName, cam_id, campType, campName)
SELECT WG.IDWG,WG.WGName, cCamp.cam_id, cWG.Tipo, cCamp.cam_descripcion
FROM cccamps cCamp
inner join ccRIACampEspWG cWG on cWG.IdCampEsp = cCamp.cam_id AND cWG.Tipo = 1
inner join ccRIACat_WorkGroup WG on WG.IDWG = cWG.IDWG
UNION
SELECT WG.IDWG,WG.WGName, cCamp.Inbound_id, cWG.Tipo, cCamp.descripcion
FROM ccinbound cCamp
inner join ccRIACampEspWG cWG on cWG.IdCampEsp = cCamp.Inbound_id AND cWG.Tipo = 0
inner join ccRIACat_WorkGroup WG on WG.IDWG = cWG.IDWG


SELECT  cam_id, campType,
	STUFF((
	SELECT '', '' + wgc.WGName
	FROM #WorkGroupCamps wgc WHERE (wgc.cam_id = wgc1.cam_id and wgc.campType = wgc1.campType) 
	FOR XML PATH ('''')),1,2,'' '') AS WGNames,
	STUFF((
	SELECT '', '' + CAST(wgc.IDWG AS VARCHAR(MAX))
	FROM #WorkGroupCamps wgc WHERE (wgc.cam_id = wgc1.cam_id and wgc.campType = wgc1.campType)
	FOR XML PATH ('''')),1,2,'' '') AS WGIDs
INTO #tmpWGconcat
FROM #WorkGroupCamps wgc1
GROUP BY cam_id, campType


select cal_id,tipo_llamada,A.cam_id,
case when a.tipo_llamada=2 then  campOut.cam_descripcion else campIn.descripcion end  AS campDescription,
A.calif_id,duracion,id_nivel_grito,age_id as user_id, U.login as [username],
	U.Nombres + '' '' +  U.ApellidoPaterno+ '' '' +  U.ApellidoMaterno as [FullName],
finicio,A.ani,dni,cal_key,cal_manual,
isnull(P.pos_id,0) as posicion,P.computer,isnull (z.total_forma,0) as total_forma, A.id_repositorio,
case when a.tipo_llamada=2 then  isnull (dispOut.[Description],'''') else isnull (dispIn.[Description],'''') end  AS score,
convert(varchar(8),DATEADD(ss, duracion, 0),114) as formato_duracion,A.grab_id,
case when a.tipo_llamada=2 then  isnull( subOut.califSubDesc ,'''') else isnull( subIn.califSubDesc ,'''') end  AS califSub_id,
a.cal_tMoh as cal_tMoh,repositorios.ruta_repositorio,
@encrypted as IsEncrypted, A.Prefijo as Prefix
INTO #tmpRecords
from RIA_GRABACION A
inner join #userAgent on #userAgent.userId=A.age_id
inner join trec_repositorios repositorios on repositorios.id_repositorio=A.id_repositorio
left join ccPosicion P on A.cal_extension * -1 =P.pos_id
left join (select id_grabacion,avg(total_forma) as total_forma from ria_formacalif group by id_grabacion) Z on A.grab_id=Z.id_grabacion
left join cctipocalifout AS dispOut ON A.calif_id = dispOut.calif_id and a.tipo_llamada=2
left join cctipocalifsubout subOut on subOut.califSub_id=a.califSub_id and a.tipo_llamada=2
left join cctipocalif AS dispIn ON A.calif_id = dispIn.calif_id and a.tipo_llamada=1
left join cctipocalifsub subIn on subIn.califSub_id=a.califSub_id and a.tipo_llamada=1
left join cccamps campOut on campOut.cam_id=a.cam_id and a.tipo_llamada=2
left join ccinbound campIn on campIn.Inbound_id=a.cam_id and a.tipo_llamada=1
left join ccUsers U on A.age_id=U.user_id
where 
(
(A.finicio >= @dateStart and A.finicio <=@dateEnd) or
	(@IdCallList is not null and @IdCallList <>'''')
	
)
and (
	@IdCallList is null or @IdCallList ='''' or
		A.cal_id in (select Value from dbo.fn_RIASplitDelimited(@IdCallList,'',''))
)
and (
	@UserList is null or @UserList ='''' or
		A.age_id in (select Value from dbo.fn_RIASplitDelimited(@UserList,'',''))
)
and (
	@TypeCall is null or a.tipo_llamada=@TypeCall
)
and (
	@CampaingsList is null or @CampaingsList ='''' or
	( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@CampaingsList,'','')) and a.tipo_llamada=2 )
)
and (
	@ACDList is null or @ACDList ='''' or
	( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@ACDList,'','')) and a.tipo_llamada=1 )
)
and (
	@DispositionList is null or @DispositionList ='''' or
	( A.calif_id in (select Value from dbo.fn_RIASplitDelimited(@DispositionList,'','')) )
)
and (
	@SubdispositionList is null or @SubdispositionList ='''' or
	( A.califSub_id in (select Value from dbo.fn_RIASplitDelimited(@SubdispositionList,'','')) )
)
and (
	@GrabId is null or @GrabId = 0 or
		A.grab_id > @GrabId
)
union all
select cal_id,tipo_llamada,A.cam_id,
case when a.tipo_llamada=2 then  campOut.cam_descripcion else campIn.descripcion end  AS campDescription,
A.calif_id,duracion,id_nivel_grito,age_id as user_id, U.login as [username],
	U.Nombres + '' '' +  U.ApellidoPaterno+ '' '' +  U.ApellidoMaterno as [FullName],
finicio,A.ani,dni,cal_key,cal_manual,
isnull(P.pos_id,0) posicion,P.computer,isnull (z.total_forma,0) as total_forma, A.id_repositorio,
case when a.tipo_llamada=2 then  isnull (dispOut.[Description],'''') else isnull (dispIn.[Description],'''') end  AS score,
convert(varchar(8),DATEADD(ss, duracion, 0),114) as formato_duracion,A.grab_id, 
case when a.tipo_llamada=2 then  isnull( subOut.califSubDesc ,'''') else isnull( subIn.califSubDesc ,'''') end  AS califSub_id,
a.cal_tMoh as cal_tMoh,repositorios.ruta_repositorio,
@encrypted as IsEncrypted, A.Prefijo as Prefix 
from RIA_GRABACIONConsulta A
inner join #userAgent on #userAgent.userId=A.age_id
inner join trec_repositorios repositorios on repositorios.id_repositorio=A.id_repositorio
left join ccPosicion P on A.cal_extension * -1 =P.pos_id
left join (select id_grabacion,avg(total_forma) as total_forma from ria_formacalif group by id_grabacion) Z on A.grab_id=Z.id_grabacion
left join cctipocalifout AS dispOut ON A.calif_id = dispOut.calif_id and a.tipo_llamada=2
left join cctipocalifsubout subOut on subOut.califSub_id=a.califSub_id and a.tipo_llamada=2
left join cctipocalif AS dispIn ON A.calif_id = dispIn.calif_id and a.tipo_llamada=1
left join cctipocalifsub subIn on subIn.califSub_id=a.califSub_id and a.tipo_llamada=1
left join cccamps campOut on campOut.cam_id=a.cam_id and a.tipo_llamada=2
left join ccinbound campIn on campIn.Inbound_id=a.cam_id and a.tipo_llamada=1
left join ccUsers U on A.age_id=U.user_id
where 
( 
(A.finicio >= @dateStart and A.finicio <=@dateEnd) or 
(@IdCallList is not null and @IdCallList <>'''')
)
and (
	@IdCallList is null or @IdCallList ='''' or
		A.cal_id in (select Value from dbo.fn_RIASplitDelimited(@IdCallList,'',''))
)
and (
	@UserList is null or @UserList ='''' or
		A.age_id in (select Value from dbo.fn_RIASplitDelimited(@UserList,'',''))
)
and (
	@TypeCall is null or a.tipo_llamada=@TypeCall
)
and (
	@CampaingsList is null or @CampaingsList ='''' or
	( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@CampaingsList,'','')) and a.tipo_llamada=2 )
)
and (
	@ACDList is null or @ACDList ='''' or
	( A.cam_id in (select Value from dbo.fn_RIASplitDelimited(@ACDList,'','')) and a.tipo_llamada=1 )
)
and (
	@DispositionList is null or @DispositionList ='''' or
	( A.calif_id in (select Value from dbo.fn_RIASplitDelimited(@DispositionList,'','')) )
)
and (
	@SubdispositionList is null or @SubdispositionList ='''' or
	( A.califSub_id in (select Value from dbo.fn_RIASplitDelimited(@SubdispositionList,'','')) )
)
and (
	@GrabId is null or @GrabId = 0 or
		A.grab_id > @GrabId
)
order by finicio

IF (@TopRecords = 0) 
BEGIN
	SELECT cal_id, tipo_llamada, tr.cam_id, campDescription, calif_id, duracion, id_nivel_grito,
	user_id, username, FullName, finicio, ani, dni, cal_key, cal_manual, posicion, computer,
	total_forma, id_repositorio, score, formato_duracion, grab_id, ISNULL(wgc.WGIDs, ''0'') IDWG, califSub_id, 
	cal_tMoh, ruta_repositorio, IsEncrypted, Prefix, ISNULL(wgc.WGNames, ''0'') WGName
	FROM #tmpRecords tr
	LEFT JOIN #tmpWGconcat wgc on tr.cam_id = wgc.cam_id and tr.tipo_llamada-1 = wgc.campType
	order by finicio
				
END
ELSE BEGIN
	SELECT TOP(@TopRecords) 
	cal_id, tipo_llamada, tr.cam_id, campDescription, calif_id, duracion, id_nivel_grito,
	user_id, username, FullName, finicio, ani, dni, cal_key, cal_manual, posicion, computer,
	total_forma, id_repositorio, score, formato_duracion, grab_id, ISNULL(wgc.WGIDs, ''0'') IDWG, califSub_id, 
	cal_tMoh, ruta_repositorio, IsEncrypted, Prefix, ISNULL(wgc.WGNames, ''0'') WGName
	FROM #tmpRecords tr
	LEFT JOIN #tmpWGconcat wgc on tr.cam_id = wgc.cam_id and tr.tipo_llamada-1 = wgc.campType
	order by finicio
END


	
IF OBJECT_ID(''tempdb..#userAgent'') IS NOT NULL
	DROP TABLE #userAgent
IF OBJECT_ID(''tempdb..#tmpRecords'') IS NOT NULL
	DROP TABLE #tmpRecords
IF OBJECT_ID(''tempdb..#WorkGroupCamps'') IS NOT NULL
	DROP TABLE #WorkGroupCamps
IF OBJECT_ID(''tempdb..#tmpWGconcat'') IS NOT NULL
	DROP TABLE #tmpWGconcat

'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 Alter SP trsp_AdmRecSearchNodeWorkgroup Remove Index'
	SET @sql = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeWorkgroup]
@User_id int,
@WG_id int = 0
AS
BEGIN
	SET NOCOUNT ON;

	if @User_id in( 0,1)
	begin
		select IDWG,WGName from ccRIACat_WorkGroup nolock
	end
	else
	if @WG_id = 0
	begin
		select distinct IDWG,WGName from (
		select b.IDWG, c.WGName from ccusers a inner join ccRIAWorkGroupUsersConsulta b
		on b.user_id = @User_id inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG /*and c.StatusWorkGroup = 1*/
		where a.user_id = @User_id
		union --camp history
		select distinct a.IDWG,WGName
		from ccRIACampEspWGConsulta a inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG where cast(a.IdCampEsp as varchar(6))+''&''+cast(a.Tipo as varchar(6)) in (
		select distinct cast(a.IdCampEsp as varchar(6))+''&''+cast(a.Tipo as varchar(6)) from ccRIACampEspWGConsulta a
		inner join  ccRIAWorkGroupUsersConsulta b with (nolock) on b.User_id = @User_id and a.IDWG = b.IDWG)
		union --user history
		select distinct a.IDWG,WGName
		from ccRIAWorkGroupUsersConsulta a inner join ccRIACat_WorkGroup c on c.IDWG = a.IDWG where user_id in (
		select user_id from ccRIAWorkGroupUsersConsulta where IDWG in (
		select distinct a.IDWG from ccRIACampEspWGConsulta a
		inner join  ccRIAWorkGroupUsersConsulta b with (nolock) on b.User_id = @User_id and a.IDWG = b.IDWG))
		)x
		order by 1
	end
	else
		select IDWG,WGName from ccRIACat_WorkGroup nolock where IDWG = @WG_id
END'
	EXEC(@sql)

	

	SET @process = 'DEV1-474 KR087000 create SP trsp_ExportManagerAutomatic'
	SET @sql = 'CREATE PROCEDURE [dbo].[trsp_ExportManagerAutomatic] @action int
,@grabIds varchar(max)='''',@ccConfigurationExportId bigint=0,@ExportStatus tinyint=0,@StatusId tinyint=0
AS
BEGIN
	declare @sql varchar(max)
	declare @grabIdTmp table (grabId bigint not null)
	if @action=0 begin -- Insert Status
		if @grabIds='''' or @ccConfigurationExportId=0 begin
		return
		end

		insert into @grabIdTmp
		select convert(bigint, value) grabId from dbo.fn_RIASplitDelimited(@grabIds,'','')
		
		insert into ccExportManagerAutomatic
		select T.grabId,@ccConfigurationExportId ccConfigurationExportId,getdate() DateDownload,0 StatusId
		from @grabIdTmp T
		left join ccExportManagerAutomatic E on T.grabId=E.GrabId and E.ccConfigurationExportId=@ccConfigurationExportId
		where E.ccConfigurationExportId is null

		update ccConfigurationExportManagerAutomatic set ExportStatus=1 
		where ccConfigurationExportId=@ccConfigurationExportId and ExportStatus=0
	end
	else if @action=1 begin --GetStatus ccExportManagerAutomatic
		select ExportStatus from ccConfigurationExportManagerAutomatic where ccConfigurationExportId=@ccConfigurationExportId
	end
	else if @action=2 begin --Update Status ccExportManagerAutomatic
		insert into @grabIdTmp
		select convert(bigint, value) grabId from dbo.fn_RIASplitDelimited(@grabIds,'','')
		
		insert into ccExportManagerAutomatic
		select T.grabId,@ccConfigurationExportId ccConfigurationExportId,getdate() DateDownload,@StatusId StatusId
		from @grabIdTmp T
		left join ccExportManagerAutomatic E on T.grabId=E.GrabId and E.ccConfigurationExportId=@ccConfigurationExportId
		where E.ccConfigurationExportId is null

		update E set
		E.StatusId=@StatusId
		--select T.grabId,@ExportStatus
		from @grabIdTmp T
		inner join ccExportManagerAutomatic E on T.grabId=E.GrabId and E.ccConfigurationExportId=@ccConfigurationExportId	
	end
	else if @action=3 begin --Update Status ccExportManagerAutomatic
		
		select isnull(min(GrabId),0) GrabId from ccExportManagerAutomatic 
		where StatusId=0 and ccConfigurationExportId=@ccConfigurationExportId
	end
	else if @action=4 begin --Update Status ccExportManagerAutomatic
		
		update ccConfigurationExportManagerAutomatic set ExportStatus=@ExportStatus 
		where ccConfigurationExportId=@ccConfigurationExportId

		if @ExportStatus=2 begin
			update ccExportManagerAutomatic set StatusId=3 where ccConfigurationExportId=@ccConfigurationExportId and StatusId=0
		end
	end

END'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 create procedure trsp_GetParametersExportService'
	SET @sql = 'CREATE PROCEDURE [dbo].[trsp_GetParametersExportService]
AS
BEGIN

DECLARE  @avrs_enviroment AS INT

SET @avrs_enviroment = (SELECT par_valor FROM TREC_PARAMETROS WHERE par_id=29)

IF @avrs_enviroment = 2
	BEGIN
		SELECT * FROM
		(
			SELECT par_valor,par_id,par_descripcion FROM TREC_PARAMETROS
			WHERE par_id in (2,15,29,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,62,63,65,67,77,78)
			Union
			SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66,'''' FROM RIA_GRABACION
			union
			select @@Servername+''|''+valor as par_valor,66 as par_id,descripcion as par_descripcion from ccsettings where setting_id=8
		)x
		ORDER BY x.par_id
	END
ELSE
	BEGIN
		SELECT * FROM
		(
			SELECT par_valor,par_id FROM TREC_PARAMETROS
			WHERE par_id in (2,15,29,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,57,60,62,63,65,66,67,77,78)
			UNION
			SELECT CONVERT(VARCHAR(MAX),MAX(grab_id)),66
			FROM TREC_GRABACION)x
			ORDER BY x.par_id
	END	
END'
	EXEC(@sql)


	SET @process = 'DEV1-474 KR087000 create procedure trsp_SaveAVRSExportParameters'
	SET @sql = 'CREATE PROCEDURE [dbo].[trsp_SaveAVRSExportParameters] @export_mode AS INT, @netcred_id 
	AS INT = - 1, @net_user AS VARCHAR(100) = '''', @net_password AS VARCHAR(100) = '''', 
	@net_sever AS VARCHAR(max) = '''', @net_path AS VARCHAR(max) = '''', @ftp_user AS VARCHAR(
		100) = '''', @ftp_password AS VARCHAR(100) = '''', @ftp_sever AS VARCHAR(max) = '''', 
	@ftp_path AS VARCHAR(max) = '''', @ftp_port AS INT = - 1, @ftp_protocol AS INT = - 1, 
	@time_export AS VARCHAR(100) = '''', @grabid_start AS INT = - 1, @csv_log AS INT = - 1, 
	@delete_rec AS INT = - 1, @export_format AS INT = 1, @export_encrypted AS BIT = 0, 
	@file_encrypted AS BIT, @AutomaticConfigurationDto VARCHAR(max) = ''''
	,@DateStartExport	datetime null,@DateEndExport	datetime =null
AS
BEGIN
	DECLARE @repo_Id AS INT
	declare @ccConfigurationExportId bigint=0

	IF LEN(@time_export) > 0
	BEGIN
		UPDATE TREC_PARAMETROS
		SET par_valor = @time_export
		WHERE par_id = 33
	END

	UPDATE TREC_PARAMETROS
	SET par_valor = @export_format
	WHERE par_id = 35

	-- Update FTP Parameters
	IF @export_mode = 1
	BEGIN
		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_path
		WHERE par_id = 41

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_protocol
		WHERE par_id = 42

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_sever
		WHERE par_id = 43

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_user
		WHERE par_id = 44

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_password
		WHERE par_id = 45

		UPDATE TREC_PARAMETROS
		SET par_valor = @ftp_port
		WHERE par_id = 46		
		
	END
	ELSE
	BEGIN
		-- Update NetBios parameters
		DECLARE @avrs_enviroment AS INT
		
		SELECT @avrs_enviroment=par_valor
		FROM TREC_PARAMETROS
		WHERE par_id = 29
				

		IF @avrs_enviroment = 2
		BEGIN
			UPDATE RIA_NETWORKCREDENTIALS
			SET [domain] = @net_sever, [user] = @net_user, [password] = @net_password
			WHERE id = @netcred_id
		END
		ELSE
		BEGIN
			UPDATE TREC_NETWORKCREDENTIALS
			SET [domain] = @net_sever, [user] = @net_user, [password] = @net_password
			WHERE id = @netcred_id
		END

		UPDATE TREC_PARAMETROS
		SET par_valor = @net_path
		WHERE par_id = 36
	END

	

	IF @grabid_start <> - 1
	BEGIN
		UPDATE TREC_PARAMETROS
		SET par_valor = @grabid_start
		WHERE par_id = 40
	END

	UPDATE TREC_PARAMETROS
	SET par_valor = @csv_log
	WHERE par_id = 50

	UPDATE TREC_PARAMETROS
	SET par_valor = @export_mode
	WHERE par_id = 51

	UPDATE TREC_PARAMETROS
	SET par_valor = @delete_rec
	WHERE par_id = 57

	UPDATE TREC_PARAMETROS
	SET par_valor = @file_encrypted
	WHERE par_id = 61

	UPDATE TREC_PARAMETROS
	SET par_valor = @export_encrypted
	WHERE par_id = 62

	if @AutomaticConfigurationDto<>'''' begin
		UPDATE TREC_PARAMETROS
		SET par_valor =case when @AutomaticConfigurationDto='''' then par_valor else  @AutomaticConfigurationDto end
		WHERE par_id = 77
		select @ccConfigurationExportId=case when par_valor='''' then 0 else  convert(bigint,par_valor) end 
		from TREC_PARAMETROS WHERE par_id = 78

		if @ccConfigurationExportId=0 begin		
			insert into ccConfigurationExportManagerAutomatic(DateStartExport,DateEndExport,Json,ExportStatus)
			values(@DateStartExport,@DateEndExport, @AutomaticConfigurationDto,0) 
			select @ccConfigurationExportId=@@IDENTITY
		end
		else begin
			declare @ExportStatus tinyint 
			select @ExportStatus=ExportStatus from ccConfigurationExportManagerAutomatic
			where ccConfigurationExportId=@ccConfigurationExportId
			if @ExportStatus =0 begin--Create
				update ccConfigurationExportManagerAutomatic set [Json]=@AutomaticConfigurationDto where ccConfigurationExportId=@ccConfigurationExportId
			end
			else if @ExportStatus =1 begin--Process
				update ccExportManagerAutomatic set StatusId=3 where ccConfigurationExportId=@ccConfigurationExportId
				update ccConfigurationExportManagerAutomatic set ExportStatus =3 where ccConfigurationExportId=@ccConfigurationExportId
				set @ExportStatus=3
			end
			if @ExportStatus in(2,3) begin--2 End,3 Cancelada
				insert into ccConfigurationExportManagerAutomatic(DateStartExport,DateEndExport,Json,ExportStatus)
				values(@DateStartExport,@DateEndExport, @AutomaticConfigurationDto,0) 
				select @ccConfigurationExportId=@@IDENTITY				
			end		
		end
		UPDATE TREC_PARAMETROS
		SET par_valor =convert(varchar(100),@ccConfigurationExportId)
		WHERE par_id = 78
	end
END'
	EXEC(@sql)

	SET @process = 'DEV1-474 KR087000 '
	SET @sql = ''
	EXEC(@sql)

	---------------------------------------END KR087000 Modificaciones Recordings Manager Exportacion Automatica ---------------------------------------------------------


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