/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/04/28
Description: 

Database: CCenterRia
Required version: 121.41

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
SET @version = 122 --**********actualizar a 122 sin fix
SET @versionfix = 11
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF (@actualVersion = @version AND @actualVersionFix >= 11) OR (@actualVersion = @version-1 AND @actualVersionFix >= 41)
BEGIN
	BEGIN TRAN

	BEGIN TRY
	
	set @process = 'CW-3557 Error en totales de registros cargados'
	set @sql = '
	ALTER PROCEDURE [dbo].[ccsp_GalateaGetRecordsImportStatus]
		          -- @Type = 1:Detalle general de carga de registros | 2:Detalle específico de carga de registros | 3:Porcentaje de carga de registros
		          @action tinyint, 
		          @loadID int = NULL, 
		          @userID smallint = NULL

		          AS
				  declare @today datetime
				  select @today =convert(datetime, convert(varchar(11),getdate(),121),121)
		          SET nocount ON
		          if @action not IN (1,2,3)
		            raiserror(''ERROR. No se ingreso parametro de entrada'', 18, 1)

		          if @action=1 -- Detalle general de carga de registros
		           BEGIN
		            if not exists(SELECT User_id FROM ccUsers WHERE TipoUser_id IN(2,6) AND Status>0 AND User_id=@userID)
		             BEGIN
		              raiserror(''ERROR. invalid user id'', 18, 1)
		              return(0)
		             END

		            SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked as regsNotLoaded, state, loadDate
		            FROM ccRIALoading riaLoad
		            JOIN ccSupervisorCam superCam ON riaLoad.cam_id = superCam.cam_id
					JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
		            WHERE 
					loadDate>=@today AND
					superCam.user_id = @userID
		            AND superCam.tipo = 1
					ORDER BY riaLoad.loadDate DESC

		            return(0)
		           END

		          if @action=2 -- Detalle específico de carga de registros
		           BEGIN
		            if not exists(SELECT load_id FROM ccRIALoading)
		             BEGIN
		              raiserror(''ERROR. invalid template ID'', 18, 1)
		              return(0)
		             END

		              SELECT regsLoaded, alreadyLoaded, regsBlocked, regsNotLoaded,
		                     telsLoaded, telsBlocked, telsNotLoaded
		              FROM ccRIALoading
		              WHERE load_id  = @loadID
		           
		           END

		          if @action=3 -- Porcentaje de carga de registros
		           BEGIN
		            if not exists(SELECT load_id FROM ccRIALoading)
		             BEGIN
		              raiserror(''ERROR. invalid load ID'', 18, 1)
		              return(0)
		             END

		              SELECT state, pctg
		              FROM ccRIALoading
		              WHERE load_id  = @loadID

		           END
		          SET nocount off

'
	exec (@sql)
	set @process = 'CW-3610 Setting_ID 217 Información del certificado'
	    set @Sql= '
		IF not exists (SELECT * FROM ccSettings WHERE setting_id = 217)
		INSERT INTO ccSettings (setting_id, valor, descripcion,	Status,	Tipo,detalle,description,bLoadSettings,	validate)
		VALUES	(217, 
				''D:\Centerware\certs\nuxiba_pfx.pfx|e7451896fd98715c9e67f110351b5719'',
				''Parámetros del Certificado de seguridad (.PFX)'',	
				1,
				''X'',
				''Información del certificado de seguridad Ubicación|Contraseña cifrada'',
				''Security Certificate Information'',
				0,
				 ''.*'')
		'
	exec (@sql)

	set @process = 'CW-3653 Setting_ID 219 Tiempo de retraso para refrezcar informacion de campaña'
	set @Sql= '
		IF not exists (SELECT * FROM ccSettings WHERE setting_id = 219)
		INSERT INTO ccSettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate)
		VALUES  (219,
				''10000'', 
				''Tiempo de retraso para refrezcar informacion de campaña'',
				1, 
				''ADM'', 
				''Tiempo de retraso para refrezcar informacion de campaña en Admin de Galatea'', 
				''Time delay to refresh campaign information'', 
				1,
				''.*'')
		'
	exec (@sql)

	set @process = 'CW-3653 Add column OverallTotalNew'
	set @Sql= 'if not exists (select * from sys.columns where name = N''OverallTotalNew'' and Object_ID = Object_ID(N''ccCampsNvosCB''))
			   begin
			        ALTER TABLE ccCampsNvosCB
					ADD OverallTotalNew int; 
			   end'
	exec (@sql)

	set @process = 'CW-3653 Drop if exists ccsp_GalateaUpdateOverallTotalNew'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUpdateOverallTotalNew'')
    begin
        DROP PROCEDURE ccsp_GalateaUpdateOverallTotalNew;
    end'
    exec (@sql)

	set @process = 'CW-3653 Update overall time'
	set @Sql= 'CREATE PROCEDURE [dbo].[ccsp_GalateaUpdateOverallTotalNew] @CampId AS SMALLINT
				AS
				BEGIN
					set nocount on
					if @CampId is not null
						BEGIN
							UPDATE ccCampsNvosCB set OverallTotalNew = ccCampsNvosCB.new where id = @CampId
						END
				END'
	exec (@sql) 

	set @process = 'CW-3653 Add overall time column'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0, @tcpa int=0
as
set nocount on

declare @TipoJobs as int,@isExecOutbound bit


set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

	declare @id AS INTEGER

	CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
	CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime)

	create table #temccocallsoutsource (cam_id int,Pend  int)

	create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

	if @cam_id = 0 begin
	if @user_id > 0 begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
		from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
		where user_id = @user_id and tipo = 1
	end
	else begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
		from ccCamps cam (nolock) join ccSupervisorCam supcam with(nolock) on tipo=1 and cam.cam_id  =  supcam.cam_id
	end

	end
	else begin
	if @Tipo = 2
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
		from ccCamps cam with(nolock)
		join ccSupervisorCam supcam with(nolock) on tipo=1 and cam.cam_id  =  supcam.cam_id
		where cam.cam_id = @cam_id
	else
		if @user_id > 0 begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
		from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
		where user_id = @user_id and tipo = 1
		end
		else begin
		insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
		select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
		from ccCamps cam (nolock) join ccSupervisorCam supcam with(nolock) on tipo = 1 and cam.cam_id  =  supcam.cam_id
		where user_id = @user_id and cam_activo=1
		end
	end



	insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate)
	select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate) from(
	select A.*,dateUpdate from #Tcamps A
	left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
	where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null)X
	group by cam_id


	
	if (select count(*) from #Tcamps2)>0 begin

	insert into #temccocallsoutsource(cam_id,Pend)
	SELECT ccos.cam_id, count(ccos.cam_id) as Pend
	FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
	join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
	WHERE cal_status in(0, 7)
	GROUP BY ccos.cam_id

	insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
	SELECT A.cam_id,
	count(case cal_status when 0 then 1 else null end) as New,
	count(case cal_status when 1 then 1 else null end) as Cb,
	count(case cal_status when 2 then 1 else null end) as Pro,
	count(case cal_status when 3 then 1 else null end) as Fin
	FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
	join #Tcamps2 B on A.cam_id = B.cam_id
	GROUP BY A.cam_id	

	
	if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
		update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @cam_id
	end
	else begin
		While exists(select * from #Tcamps2 where status = 0 and ( datediff(ss,dateUpdate,getdate())>60 or dateUpdate is null))  Begin
		set rowcount 1
		select @id = cam_id,@TipoJobs=cam_tipojobs from #Tcamps2 where status = 0 order by cam_id
		set rowcount 0
		EXEC @regval = ccsp_OUTGetNewJobs @id,2,0
		update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @id
		end
	end

	declare @TotalNew table(
			cam_id int primary key,
			OverallTotalNew int 
		)
		
		

		

	begin Tran updateccCampsNvosCB

		insert into @TotalNew
		select CampNvosCB.id,isnull(CampNvosCB.OverallTotalNew,CampNvosCB.new)  from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
		where CampNvosCB.id = tcamp.cam_id

		delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
		where CampNvosCB.id = tcamp.cam_id

		INSERT into ccCampsNvosCB 
		SELECT cams.cam_id, cams.cam_descripcion,
		isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
		isNull(cs.Pend,0) as pend,
		isNull(wt.Pro,0) as pro,
		isNull(cams.procesando,0) cam_procesando,
		isNull(cams.cam_tipojobs,0) cam_tipojobs,
		isNull(wt.Fin,0) Fin,
		isNull(cams.cantidad,0) cantidad,
		getdate(),
		isnull(T.OverallTotalNew,0)  as OverallTotalNew
		FROM #Tcamps2 cams with(nolock)
		LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
		LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
		LEFT JOIN @TotalNew  T on T.cam_id = cams.cam_id

	COMMIT TRAN updateccCampsNvosCB
	end

	if @isExecOutbound = 0 begin

	if @Tipo = 2 begin
		-- devuelve resultado de la taba, solo las camps del usuario
		SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, 
		isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor, OverallTotalNew
		FROM #Tcamps tcam
		left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
	end
	else 
		SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,
		cc.aggressionFactor, OverallTotalNew
		FROM ccCampsNvosCB res (nolock)
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
		WHERE res.id = @cam_id
	end

	drop table #Tcamps
	drop table #Tcamps2
	drop table #temccocallsoutsource
	drop table #temWorkinTable

	return(0)

end

set nocount off'
	exec (@sql) 

	set @process = 'CenterScript -- drop sp getACDCampaignList'
	set @sql = 'if exists (select * from sys.procedures where name = N''cs_GetACDCampaignList'')
    begin
        DROP PROCEDURE cs_GetACDCampaignList;
    end'
    exec (@sql)

    set @process = 'CenterScript -- create sp getACDCampaignList'
    set @sql = '
    	CREATE PROCEDURE [dbo].[cs_GetACDCampaignList] @action AS SMALLINT
AS
IF (@action = 1)
BEGIN
	SELECT cam_id AS [cam_id]
		,cam_descripcion AS [name]
	FROM ccCamps
	WHERE cam_activo = 1 and cam_id not in (select Cam_id from CW_CenterScript..Campaign )
		AND IDArea > 0
END

IF (@action = 2)
BEGIN
	SELECT inbound_id
		,descripcion AS [name]
	FROM ccInbound
	WHERE STATUS = 1 and Inbound_id not in (select Inbound_id from CW_CenterScript..ACD)
		AND IDArea > 0
END

IF (@action = 3)
BEGIN
	SELECT cam_id AS [cam_id]
		,cam_descripcion AS [name]
	FROM ccCamps
	WHERE cam_activo = 1 
		AND IDArea > 0
END

IF (@action = 4)
BEGIN
	SELECT inbound_id
		,descripcion AS [name]
	FROM ccInbound
	WHERE STATUS = 1 
		AND IDArea > 0
END

    ' 
    exec (@sql)
			
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
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
