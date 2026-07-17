/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Vic Gonzalez

		
Date: 2019/04/11
Description: 

Database: CCenterRia
Required version: 121.35

Se agrega la tarea
CW-SETTNGS

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
SET @version = 121 --**********actualizar a 119 sin fix
SET @versionfix = 35

/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 34
BEGIN
	BEGIN TRAN

	BEGIN TRY
		SET @process = 'CW-2805 Drop SP ccsp_GalateaAdminSettings'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSettings'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminSettings;
    end'

		EXEC (@Sql)

		SET @process = 'CW-2805 Galatea Settings'
		SET @Sql = '	CREATE PROCEDURE ccsp_GalateaAdminSettings
AS
BEGIN
	CREATE TABLE #Settings (setting_id tinyint , valor varchar(300), ip_host tinyint)

	INSERT INTO #Settings 
	EXEC  ccsp_RIAADMLoadSettings @ip_admin =''''

	INSERT INTO #Settings (setting_id,valor) 
	SELECT setting_id, valor 
	FROM ccSettings
	WHERE setting_id in(160, 199, 53)
 
	SELECT distinct setting_id, valor from #Settings ORDER BY setting_id 

	DROP TABLE #Settings;
END
'

		EXEC (@Sql)

		-- *********************** END  121.03-3_201900307 *********************** ---
		-- *********************** START 121.03-5_20190417 *********************** ---
		SET @process = 'CW-2737 Drop Table xxClienteCarga'
		SET @Sql = 'if exists (SELECT * FROM sys.tables WHERE name = N''xxClienteCarga'')
		begin
		DROP TABLE xxClienteCarga;
		end'

		EXEC (@Sql)

		SET @process = 'CW-2737 Create Table xxClienteCarga'
		SET @Sql = 
			'	CREATE TABLE xxClienteCarga (
			[cuenta] [varchar](20) NOT NULL,
			[tel1] [varchar](13) NOT NULL,
			[tel2] [varchar](13) NOT NULL,
			[tel3] [varchar](13) NOT NULL,
			[tel4] [varchar](13) NOT NULL,
			[tel5] [varchar](13) NOT NULL,
			[dato1] [varchar](255) NOT NULL,
			[dato2] [varchar](255) NOT NULL,
			[dato3] [varchar](255) NOT NULL,
			[dato4] [varchar](255) NOT NULL,
			[dato5] [varchar](255) NOT NULL,
			[callout_id] [int] NULL,
			[cam_id] [int] NULL,
			[FCallBack] [smalldatetime] NULL,
			[User_id] [int] NOT NULL,
		 CONSTRAINT [PK_clienteCarga] PRIMARY KEY CLUSTERED 
		(
			[cuenta] ASC
		))

		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_tel1]  DEFAULT ('''') FOR [tel1]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_tel2]  DEFAULT ('''') FOR [tel2]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_tel3]  DEFAULT ('''') FOR [tel3]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_tel4]  DEFAULT ('''') FOR [tel4]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_tel5]  DEFAULT ('''') FOR [tel5]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_dato1]  DEFAULT ('''') FOR [dato1]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_dato2]  DEFAULT ('''') FOR [dato2]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_dato3]  DEFAULT ('''') FOR [dato3]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_dato4]  DEFAULT ('''') FOR [dato4]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_dato5]  DEFAULT ('''') FOR [dato5]
		ALTER TABLE [xxClienteCarga] ADD  CONSTRAINT [DF_xxClienteCarga_User_id] DEFAULT ((0)) FOR [User_id]
		'

		EXEC (@Sql)

		SET @process = 'CW-2737 Drop Procedure xx_ChecaHorario'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''xx_ChecaHorario'')
		begin
		DROP PROCEDURE xx_ChecaHorario;
		end'

		EXEC (@Sql)

		SET @process = 'CW-2737 Create Procedure xx_ChecaHorario'
		SET @Sql = '	CREATE PROCEDURE xx_ChecaHorario
		as
		declare @hora integer

		set  @hora = datepart( hh, getdate())

		if @hora > 6 or @hora < 22
			select 1 as ok	-- valido (dentro de horario de operaciones)
		else
			select 0 as ok -- invalido (fuera de horario de operaciones)
		'

		EXEC (@Sql)

		SET @process = 'CW-2737 Drop Procedure xx_Inserta'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''xx_Inserta'')
		begin
		DROP PROCEDURE xx_Inserta;
		end'

		EXEC (@Sql)

		SET @process = 'CW-2737 Create Procedure xx_Inserta'
		SET @Sql = 
			'	CREATE PROCEDURE xx_Inserta 
@cal_key varchar(20),
@cal_telefono varchar(19),
@cal_telefono2 varchar(19),
@cal_telefono3 varchar(19),
@cal_telefono4 varchar(19),
@cal_telefono5 varchar(19),
@dato1 varchar(255),
@dato2 varchar(255),
@dato3 varchar(255),
@dato4 varchar(255),
@dato5 varchar(255),
@cam_id integer,
@FCallBack smalldatetime = '''',
@cal_status tinyint=0,
@User_id integer=0
as
declare @calloutid int
if (@cal_status=0) set @FCallBack=getdate()
Insert into ccoCallsOutSource ( cal_key, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, dato1, dato2, dato3, dato4, dato5, cam_id, cal_fechaDial, cal_status, user_id)
values ( @cal_key, @cal_telefono, @cal_telefono2, @cal_telefono3, @cal_telefono4, @cal_telefono5, @dato1, @dato2, @dato3, @dato4, @dato5, @cam_id, @FCallBack, @cal_status, @User_id)
select @calloutid=scope_identity()
Insert into xxClienteHistorial ( callout_id , fechaAct ) values ( @calloutid, getdate() )
select @calloutid
		'

		EXEC (@Sql)

		SET @process = 'CW-2737 Drop Procedure xx_OUTInsertNewJOBS_WT_Camp'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''xx_OUTInsertNewJOBS_WT_Camp'')
		begin
		DROP PROCEDURE xx_OUTInsertNewJOBS_WT_Camp;
		end'

		EXEC (@Sql)

		SET @process = 'CW-2737 Create Procedure xx_OUTInsertNewJOBS_WT_Camp'
		SET @Sql = 
			'	CREATE PROCEDURE xx_OUTInsertNewJOBS_WT_Camp
@camp_id as int
AS
set nocount on
declare @prioridad varchar(8)

Insert ccoWorkingTable ( callout_id, user_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano,
iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5  )
SELECT callout_id, user_id, cam_id, 
rtrim(left(ltrim(cal_telefono + ''         ''
		  + cal_telefono2 + ''         ''
		  + cal_telefono3 + ''         ''
		  + cal_telefono4 + ''         ''
		  + cal_telefono5 + ''         ''),13)) as cal_telefono,
case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key, 
case when len( cal_telefono ) > 0 then iZonaHoraria else null end, case when len( cal_telefono ) > 0 then iZonaHoraria_verano else null end, 
case when len( cal_telefono2 ) > 0 then iZonaHoraria2 else null end, case when len( cal_telefono2 ) > 0 then iZonaHoraria_verano2 else null end, 
case when len( cal_telefono3 ) > 0 then iZonaHoraria3 else null end, case when len( cal_telefono3 ) > 0 then iZonaHoraria_verano3 else null end, 
case when len( cal_telefono4 ) > 0 then iZonaHoraria4 else null end, case when len( cal_telefono4 ) > 0 then iZonaHoraria_verano4 else null end, 
case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end
FROM ccoCallsOutSource with( index(IX_ccoCallsOutSource_11), nolock)
WHERE cam_id = @camp_id and (cal_status <2 or cal_status=7) -- Nuevos Jobs

--la prioridad establecidad (si existe) 
select @prioridad = NULL
select @prioridad = Prioridad from ccCampsPrioridadTel (nolock) where cam_id = @camp_id

UPDATE ccoCallsOutSource with(rowlock) SET cal_status = 3, dial_tels = isNull( @prioridad, ''12345NNN''), nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) and cam_id = @camp_id
		'

		EXEC (@Sql)

		SET @process = 'CW-2737 Drop Procedure xx_Redirecciona'
		SET @Sql = 'if exists (select * from sys.procedures where name = N''xx_Redirecciona'')
		begin
		DROP PROCEDURE xx_Redirecciona;
		end'

		EXEC (@Sql)

		SET @process = 'CW-2737 Create Procedure xx_Redirecciona'
		SET @Sql = '	CREATE PROCEDURE xx_Redirecciona
@calkey as varchar(50),
@camOrigen as integer,
@camDestino as integer
as
update ccoCallsOutSource set cam_id = @camDestino where cam_id = @camOrigen and cal_key = @calkey and len(@calkey) > 0
update ccoWorkingtable  set cam_id = @camDestino where cam_id = @camOrigen and cal_keyw = @calkey and len(@calkey) > 0
if( @@ROWCOUNT = 0 )
begin
    -- No esta cargada, vuelve a cargar
    update ccoCallsOutSource set cal_status =0 where cam_id = @camDestino and cal_key = @calkey and len(@calkey) > 0
end
		'

		EXEC (@Sql)

		-- *********************** END 	121.03-5_20190417 *********************** ---
		-- *********************** START 	121.03-5_20190430 *********************** ---
		SET @process = 'CW-2901 alter SP ccsp_RIAGetCampsNvosCB--Cortizo'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
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

	begin Tran updateccCampsNvosCB

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
		getdate()
		FROM #Tcamps2 cams with(nolock)
		LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
		LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id		

	COMMIT TRAN updateccCampsNvosCB
	end

	if @isExecOutbound = 0 begin

	if @Tipo = 2
		-- devuelve resultado de la taba, solo las camps del usuario
		SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, res.st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor
		FROM #Tcamps tcam
		left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
		LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
		inner join cccamps cc (nolock) on res.id=cc.cam_id
	else
		SELECT id, campaña, new, cb, pro, pen,st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,cc.aggressionFactor
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

		EXEC (@Sql)

		SET @process = 'CW-2901 Alter SP ccsp_RIAOUTInsertNewJOBS_WT_Camp --Cortizo'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1
AS
SET NOCOUNT ON

CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(20), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT)

DECLARE @prioridad VARCHAR(8)
DECLARE @batchsizeIni AS INT
DECLARE @batchsizeFin AS INT
DECLARE @rango AS DECIMAL
DECLARE @rowstoInsert AS INT
declare @top int

SET @rowstoInsert = 0
SET @batchsizeIni = 0
SET @batchsizeFin = 0
SET @rango = 0.00
set @top=3000

SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
FROM ccCampsPrioridadTel WITH (NOLOCK)
WHERE cam_id = @camp_id

DELETE ccUploadTemporal
WHERE cam_id = @camp_id

CREATE NONCLUSTERED INDEX [IX_TempCOS] ON [dbo].[#tempCallsOutSource] ([Id] ASC)
	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

CREATE TABLE #calloutIdSource (callout_id INT NOT NULL PRIMARY KEY)

CREATE TABLE #calloutIdSource2 (callout_id INT NOT NULL PRIMARY KEY)

INSERT INTO #calloutIdSource
SELECT top(@top) cs.callout_id
FROM ccoCallsOutSource cs WITH (INDEX (IX_ccoCallsOutSource_15), NOLOCK)
inner join ccoWorkingTable wt WITH (INDEX (IX_ccoWorkingTable_15), NOLOCK) 
on cs.cal_key = wt.cal_keyw AND cs.cam_id = wt.cam_id 
WHERE cs.cam_id = @camp_id and cs.cal_status IN (0, 7) AND wt.cal_status <= 2

UNION

SELECT top(@top) Cout.callout_id
FROM ccoCallsOutSource Cout WITH (INDEX (IX_ccoCallsOutSource_16), NOLOCK)
inner join ccoworkingtable Wtab(NOLOCK)on Cout.callout_id = Wtab.callout_id 
WHERE Cout.cam_id = @camp_id AND (COUT.cal_status < 2 OR COUT.cal_status = 7)

INSERT INTO #calloutIdSource2
SELECT top(@top) callout_id
FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_11), NOLOCK)
WHERE cal_status IN (0, 1, 7) AND cam_id = @camp_id

IF exists(SELECT * FROM #calloutIdSource) 
BEGIN
	UPDATE ccoCallBacks
	SET [status] = 6, schedulerStatus = 1
	WHERE callout_id IN (
			SELECT callout_id
			FROM #calloutIdSource cis
			)

	UPDATE ccoCallsOutSource
	SET cal_Status = 4
	WHERE callout_id IN (
			SELECT callout_id
			FROM #calloutIdSource cis
			)
END

INSERT #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
 iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
SELECT top(@top) callout_id, cam_id, rtrim(left(ltrim(cal_telefono + ''        '' + cal_telefono2 + ''         '' 
+ cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13)) AS cal_telefono,
 CASE cal_status WHEN 7 THEN 1 ELSE cal_status END cal_status, cal_fechaDial, cal_key, 
 CASE WHEN len(cal_telefono) > 0 THEN iZonaHoraria ELSE NULL END iZonaHoraria,
  CASE WHEN len(cal_telefono) > 0 THEN iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
  CASE WHEN len(cal_telefono2) > 0 THEN iZonaHoraria2 ELSE NULL END iZonaHoraria2,
   CASE WHEN len(cal_telefono2) > 0 THEN iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
   CASE WHEN len(cal_telefono3) > 0 THEN iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
   CASE WHEN len(cal_telefono3) > 0 THEN iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
    CASE WHEN len(cal_telefono4) > 0 THEN iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
    CASE WHEN len(cal_telefono4) > 0 THEN iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
    CASE WHEN len(cal_telefono5) > 0 THEN iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
    CASE WHEN len(cal_telefono5) > 0 THEN iZonaHoraria_verano5 ELSE 
			NULL END iZonaHoraria_verano5, list_id
FROM ccoCallsOutSource WITH (INDEX (IX_ccoCallsOutSource_17), NOLOCK)
WHERE cam_id = @camp_id AND (cal_status < 2 OR cal_status = 7)

SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource

IF exists(SELECT * FROM #tempCallsOutSource)
BEGIN
	SELECT @rango = isnull(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
	FROM #tempCallsOutSource WITH (NOLOCK)

	SET @batchsizeFin = @batchsizeFin + @rango

	WHILE 1 = 1
	BEGIN
		-- Nuevos Jobs
		INSERT INTO ccoWorkingTable
		WITH (TABLOCKX) (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
		SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
		FROM #tempCallsOutSource
		WHERE id > @batchsizeIni AND id <= @batchsizeFin

		IF @batchsizeFin > @rowstoInsert
			BREAK
		ELSE
		BEGIN
			SET @batchsizeIni = @batchsizeIni + @rango
			SET @batchsizeFin = @batchsizeFin + @rango
		END
	END

	UPDATE ccoCallsOutSource
	SET cal_status = 2, dial_tels = @prioridad, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
	FROM ccoCallsOutSource co WITH (NOLOCK), #calloutIdSource2 cis3 WITH (NOLOCK)
	WHERE co.callout_id = cis3.callout_id
END

DROP TABLE #calloutIdSource

DROP TABLE #calloutIdSource2

DROP TABLE #tempCallsOutSource

UPDATE ccCampsNvosCB
SET dateUpdate = NULL
WHERE id = @camp_id

SET NOCOUNT OFF
'

		EXEC (@Sql)

		SET @process = 'CW-2901 Alter SP ccsp_RIARegistryLists--Cortizo'
		SET @Sql = 
			'ALTER Procedure [dbo].[ccsp_RIARegistryLists]
@action tinyint = 0, 
@list_id int = 0,
@cam_id smallint = 0,
@name varchar(80) = '''',
@status tinyint = 0,
@sequence smallint = 0
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

end

-- lista campañas y listas de registros
IF @action = 4 begin
	select a.cam_id, b.cam_descripcion, count(list_id) as NoListas, c.graphic_id as Frame from ccRIARegistryLists a 
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

end

-- Detalle de numero de registros
IF @action = 7 begin

	declare @total as int

	select @total = count(*) from ccocallsoutsource where list_id = @list_id
	select @total = (@total - count(*)) from ccoworkingtable where list_id = @list_id

	if exists(select list_id from ccoWorkingTable where list_id = @list_id) begin
		select @status = status from ccRIARegistryLists where list_id = @list_id
		select @list_id as list_id,cam_id, @status as status,
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

	exec ccsp_RIARegistryLists @action=2,@list_id=@list_id,@sequence=@sequence

end'

		EXEC (@Sql)
		
		SET @process = 'CW-2869 Create SP  ccsp_GalateaAdminLogin'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminLogin] 
	@Login varchar(20) = '''',
	@Password varchar(40) = '''',
	@PasswordLwC varchar(40) = null,
	@IPAddress varchar(20) = '''',
	@adminId int = 0
AS
begin
SET NOCOUNT ON

	DECLARE @LoginOK bit, 
			@PswdOK bit ,
			@User_id smallint, 
			@Nombre varchar(100), 
			@ADMServer varchar(300), 
			@AreaId smallint, 
			@ViewAvrs int, 
			@changeRecDisposition int, 
			@PasswordExpired int ,
			@UsernameMatch bit ,
			@UserBlocked bit ,
			@LastPasswordChange datetime,
			@Ext varchar(80);

select @LoginOK =0, 
			@PswdOK = 0,			
			@PasswordExpired = 0,
			@UsernameMatch  = 1,
			@UserBlocked = 0			

	CREATE TABLE #temp 
	(LoginOK int, 
		PswdOK int,
		User_id smallint, 
		Nombre varchar(100), 
		ADMServer varchar(300), 
		AreaId smallint, 
		ViewAvrs int, 
		changeRecDisposition int, 
		LastPasswordchange int );

	INSERT INTO #temp
	exec ccsp_RIAADMChecaLogin @Login, @Password, @PasswordLwC, @adminId

	SELECT  @LoginOK = LoginOK, @PswdOK = PswdOK,  @Nombre = Nombre, @ADMServer=ADMServer,@AreaId=AreaId,
		@ViewAvrs = ViewAvrs, @changeRecDisposition=changeRecDisposition, @PasswordExpired =LastPasswordchange	 FROM #temp
	
	IF @LoginOK = 1 
	BEGIN 
		SELECT @User_id =  User_id FROM ccUsers where Login = @Login
		DECLARE @LastLoginAttempt DATETIME, @LoginAttempts int, @MaxAttemptsAllow int, @TimeBloqued int, @TimeFromLastAttempt int
		SELECT @LastLoginAttempt = LastLoginAttempt,
				 @LoginAttempts = LoginAttempts, 
				 @LastPasswordChange = LastPasswordChange FROM  ccUsers WHERE User_id = @User_id 
		SELECT @MaxAttemptsAllow = valor FROM  ccSettings WHERE setting_id = 198
		SELECT @TimeBloqued = valor FROM  ccSettings WHERE setting_id = 197
		SELECT @TimeFromLastAttempt = DATEDIFF(MINUTE, @LastLoginAttempt, GETDATE())  

		IF @LoginAttempts > @MaxAttemptsAllow  
		BEGIN
			SET @LoginAttempts = 0
			UPDATE ccUsers SET LoginAttempts = 0, LastLoginAttempt = GETDATE() WHERE User_id = @User_id 
		END
		IF(@LoginAttempts >= @MaxAttemptsAllow AND @TimeFromLastAttempt < @TimeBloqued)
		BEGIN 
			SET @UserBlocked = 1
		END 

		
		--Checks Username match case sensitive    
		IF CAST(@Login as varbinary(200)) <> (SELECT CAST(LOGIN as varbinary(200)) FROM ccUsers WHERE User_id = @User_id )
		BEGIN 
			SET @UsernameMatch = 0
		END
		
		--Increments attemps if error
		IF   @UserBlocked = 0  AND (@UsernameMatch = 0 OR @PswdOK = 0)
		BEGIN
			UPDATE ccUsers SET LoginAttempts = @LoginAttempts + 1, LastLoginAttempt = GETDATE(), onLine = 0  WHERE User_id = @User_id 

		END
		
		--Sets to default to try another attempt
		DECLARE @ExpirationTime int 
		SELECT @ExpirationTime = valor FROM ccSettings where setting_id = 29
		SELECT @PasswordExpired = (CASE WHEN DATEDIFF(DAY,LastPasswordChange ,GETDATE()) > @ExpirationTime AND @ExpirationTime>0 THEN 1 ELSE 0 END )  FROM ccUsers

		IF   @UserBlocked = 0  AND @UsernameMatch = 1 AND  @PswdOK = 1 AND @PasswordExpired = 0
		BEGIN
			UPDATE ccUsers SET LoginAttempts = 0, LastLoginAttempt = GETDATE() , onLine = 1 WHERE User_id = @User_id 
		END
		
		SELECT @Ext = dbo.fn_Ext_X_ip (@IPAddress);
	END


	SELECT @LoginOK UserExists, @UserBlocked UserBlocked , @UsernameMatch UsernameMatch, @PswdOK PasswordMatch, CAST(@PasswordExpired AS BIT) PasswordExpired, @User_id UserID,
	@Nombre Name, @ADMServer ADMServer, @AreaId AreaId, @ViewAvrs ViewAvrs, @changeRecDisposition ChangeRecDisposition, @Ext Ext

END

'

		EXEC (@Sql)

		SET @process = 'CW-2770 Alter SP ccsp_RIAABCChat-- Version 121.34'
		SET @Sql = 
			'ALTER Procedure [dbo].[ccsp_RIAABCChat]
@OperationType tinyint = 0, -- 0:Select | 1:Insert | 2:Select Excel | 3:DateRange | 4:Admins | 5:Agents | 6:GalateaAdmin
@TipoMsgChat tinyint = null,
@User_id_Adm varchar(8000) = null,
@User_id_Agt varchar(8000) = null,
@ChatMsg varchar(1500) = null,
@Fecha_Chat_ini datetime = null,
@Fecha_Chat_fin datetime = null,
@IDArea int = null
AS
set nocount on

if @OperationType not in (0,1,2,3,4,5,6)
	raiserror(''Invalid Operation Type'', 18, 1)

if @OperationType=0
 begin
	Declare @User_id_Adm2 smallint, @User_id_Agt2 smallint, @Fecha2 varchar(10), @Fecha3 varchar(10), @Fecha4 varchar(10)
	CREATE TABLE #CHAT (id int identity, xmlType tinyint, User_id_Adm smallint, User_id_Agt smallint, date varchar(10),
	 iniTime varchar(10), endTime varchar(10), TipoMsgChat tinyint, text varchar(1500), time varchar(10))

	Declare CursorChat Cursor For
	-- Realizamos la Select para extraer las tablas
	select distinct User_id_Adm, User_id_Agt, convert(varchar(25), Fecha_Chat, 103) date
	 , min(convert(varchar(8), Fecha_Chat, 108)) iniTime
	 , max(convert(varchar(8), Fecha_Chat, 108)) endTime
	from ccRIAChat_Log --with (nolock, index(PK_ccRIAChat_Log))
	where TipoMsgChat = case when isnull(@TipoMsgChat,0)=0 then TipoMsgChat else @TipoMsgChat end
	 and User_id_Adm in (select case when isnull(@User_id_Adm,''0'') in (''0'','''') then User_id_Adm else value end from dbo.fn_RIASplitDelimited (@User_id_Adm, '',''))
	 and User_id_Agt in (select case when isnull(@User_id_Agt,''0'') in (''0'','''') then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
	 and Fecha_Chat between isnull(@Fecha_Chat_ini, ''19000101 00:00'')
	 and isnull(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))
	group by User_id_Adm, User_id_Agt, convert(varchar(25), Fecha_Chat, 103)
	Order by date desc, iniTime desc

	Open CursorChat
	Fetch Next From CursorChat
	Into @User_id_Adm2, @User_id_Agt2, @Fecha2, @Fecha3, @Fecha4

	if @@FETCH_STATUS = 0
	 Begin

	-- Mientras hay resultados para procesar
		While @@FETCH_STATUS = 0
		 Begin
			insert into #CHAT select ''1'' xmlType, @User_id_Adm2 User_id_Adm, @User_id_Agt2 User_id_Agt,
			 @Fecha2 date, @Fecha3 iniTime, @Fecha4 endTime, 0 TipoMsgChat, '''' text, '''' time

			-- Iniciamos el proceso
			insert into #CHAT select ''0'' xmlType, @User_id_Adm2 User_id_Adm, @User_id_Agt2 User_id_Agt, @Fecha2 date, '''' iniTime,
			'''' endTime, TipoMsgChat, ChatMsg text, convert(varchar(25), Fecha_Chat, 108) time
			from ccRIAChat_Log where User_id_Adm = @User_id_Adm2 and User_id_Agt = @User_id_Agt2 and convert(varchar(25), Fecha_Chat, 103) = @Fecha2
			order by time desc

			-- Recuperamos la siguiente fila
			Fetch Next From CursorChat
				Into @User_id_Adm2, @User_id_Agt2, @Fecha2, @Fecha3, @Fecha4
		 End
	 End


	Close CursorChat
	Deallocate CursorChat
	select C.xmlType, U2.Nombres + isnull('' '' + U2.ApellidoPaterno, '''') + isnull('' '' + U2.ApellidoMaterno, '''') Nombre_Adm,
	 U1.Nombres + isnull('' '' + U1.ApellidoPaterno, '''') + isnull('' '' + U1.ApellidoMaterno, '''') Nombre_Agt,
	C.date, C.iniTime, C.endTime, C.TipoMsgChat, C.text, C.time
	from #CHAT C join ccUsers U1 on U1.user_id = C.User_id_Agt
	 join ccUsers U2 on U2.user_id = C.User_id_Adm
	order by C.id
	return(0)
 end

if @OperationType=1
 begin
	if  @TipoMsgChat is NULL or @User_id_Adm is NULL or @User_id_Agt is NULL or @ChatMsg is NULL
		raiserror(''Invalid Data 3'', 18, 3)

	insert ccRIAChat_Log (TipoMsgChat, User_id_Adm, User_id_Agt, ChatMsg)
	select @TipoMsgChat, @User_id_Adm, @User_id_Agt, @ChatMsg
	select SCOPE_IDENTITY() ChatID
	return(0)
 end

if @OperationType=2
 begin
	-- Realizamos la Select para extraer las tablas
	if isnull(@User_id_Adm,''0'')=''0'' and isnull(@User_id_Agt,''0'')=''0'' and isnull(@TipoMsgChat,0)=0 and (@Fecha_Chat_ini is null and @Fecha_Chat_fin is null)
		raiserror(''Invalid Data 2'', 18, 2)

	create table #ExcelChat (Fecha_Chat datetime, TipoMsgChat varchar(30), Nombre_Adm varchar(100), Nombre_Agt varchar(100), ChatMsg varchar(2000))

	insert into #ExcelChat
	select Fecha_Chat,
	case C.TipoMsgChat when 1 then ''Admin -> Agent'' when 2 then ''Admin <- Agent'' else ''Admin -> Global'' end TipoMsgChat,
	U2.Nombres + isnull('' '' + U2.ApellidoPaterno, '''') + isnull('' '' + U2.ApellidoMaterno, '''') Nombre_Adm,
	U1.Nombres + isnull('' '' + U1.ApellidoPaterno, '''') + isnull('' '' + U1.ApellidoMaterno, '''') Nombre_Agt,
	''"''+ REPLACE(C.ChatMsg,''"'',''""'') + ''"'' as ChatMsg
	from ccRIAChat_Log C join ccUsers U1 on U1.user_id = C.User_id_Agt
	 join ccUsers U2 on U2.user_id = C.User_id_Adm
	where TipoMsgChat = case when isnull(@TipoMsgChat,0)=0 then TipoMsgChat else @TipoMsgChat end
	 and User_id_Adm in (select case when isnull(@User_id_Adm,''0'')=''0'' then User_id_Adm else value end from dbo.fn_RIASplitDelimited (@User_id_Adm, '',''))
	 and User_id_Agt in (select case when isnull(@User_id_Agt,''0'')=''0'' then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
	 and Fecha_Chat between isnull(@Fecha_Chat_ini, ''19000101 00:00'')
	 and isnull(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))

	if (select valor from ccsettings where setting_id=27) = 0
	 begin
		select convert(varchar(10), Fecha_Chat, 103)+'' ''+convert(varchar(8), Fecha_Chat, 108) Fecha_Chat, TipoMsgChat, Nombre_Adm, Nombre_Agt, ChatMsg from #ExcelChat Order by 1 desc
	 end

	else
	 begin
		select convert(varchar(10), Fecha_Chat, 101)+'' ''+convert(varchar(8), Fecha_Chat, 108) timestamp, TipoMsgChat MsgChatType, Nombre_Adm Adm_Name, Nombre_Agt Agt_Name, ChatMsg ChatMsg from #ExcelChat Order by 1 desc
	 end

	return(0)
 end

if @OperationType=3
 begin
	set @Fecha_Chat_fin=getdate()
	select @Fecha_Chat_ini=dateadd(year,-1,@Fecha_Chat_fin)
	from ccRIAChat_Log
	select  convert(varchar(11),@Fecha_Chat_ini ,103) Fecha_Chat_MIN, convert(varchar(11),@Fecha_Chat_fin,103)Fecha_Chat_MAX
	return(0)
 end

if @OperationType=4
 begin
	if not exists(select IDArea from ccRIACat_Areas where IDArea = @IDArea) or not exists(select user_id from ccusers where TipoUser_id in(2,6) and IDArea=@IDArea)
		raiserror(''Invalid Area'', 18, 4)

	select User_id, Login, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') Nombre
	from ccusers where TipoUser_id in(2,6) and IDArea=@IDArea
	order by login, Nombre
	return(0)
 end

if @OperationType=5
 begin
	if not exists(select IDArea from ccRIACat_Areas where IDArea = @IDArea) or not exists(select user_id from ccusers where TipoUser_id in(1) and IDArea=@IDArea)
		raiserror(''Invalid Area'', 18, 4)

	select User_id, Login, Nombres + isnull('' '' + ApellidoPaterno, '''') + isnull('' '' + ApellidoMaterno, '''') Nombre, Sexo gender
	from ccusers where TipoUser_id in(1) and IDArea=@IDArea
	order by login, Nombre
	return(0)
 end

 if @OperationType=6
 begin
	--This action was created for Galatea''s Agent Chat Log
	SELECT  convert(varchar(10),Fecha_Chat,108) HourChat,
	C.TipoMsgChat , u2.Login AdminLogin,
	U1.Login AgentLogin,
	''"''+ REPLACE(C.ChatMsg,''"'',''""'') + ''"'' AS ChatMsg
	FROM ccRIAChat_Log C join ccUsers U1 on U1.user_id = C.User_id_Agt
	 JOIN ccUsers U2 on U2.user_id = C.User_id_Adm
	WHERE 
	  User_id_Agt in (select case when isnull(@User_id_Agt,''0'')=''0'' then User_id_Agt else value end from dbo.fn_RIASplitDelimited (@User_id_Agt, '',''))
	 AND Fecha_Chat BETWEEN ISNULL(@Fecha_Chat_ini, ''19000101 00:00'')
	 AND ISNULL(@Fecha_Chat_fin, DATEADD(hh, 1, getdate()))

 end
select 0
set nocount off'

		EXEC (@Sql)

		SET @process = 'CW-XXXX Alter SP ccsp_Multimedia2 --Acd DUplicate'
		SET @Sql = 
			'ALTER PROCEDURE [dbo].[ccsp_Multimedia2] @action INT, @inboundId INT = NULL, @userId INT = NULL, @senderId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	IF @action = 1
	BEGIN --Lista  ACD
		SELECT DISTINCT A.inbound_id AS Id, A.chat AS Mode, C.maxMails MaxMails, cast(isnull(C.maxTweets, 3) AS TINYINT) AS MaxTweets, A.IDArea AS AreaId
		FROM ccInbound A
		INNER JOIN ccRIACat_Areas C ON A.IDArea = C.IDArea
		WHERE @inboundId IS NULL OR @inboundId = A.Inbound_id
	END
	ELSE IF @action = 2
	BEGIN --Lista Agentes  
		SELECT DISTINCT A.User_id AS [Id], C.idCampEsp AcdId, isnull(skill, 8) Skill
		FROM ccRIAWorkGroupUsers A
		INNER JOIN ccusers B ON A.User_id = B.User_id
		INNER JOIN ccRIACampEspWG C ON C.IDWG = A.IDWG AND C.Tipo = 0
		INNER JOIN ccInbound D ON C.idCampEsp = D.inbound_id
		LEFT JOIN ccskills S ON S.inbound_id = D.inbound_id AND S.user_id = B.user_id
		WHERE B.TipoUser_id = 1 AND (@userId IS NULL OR @userId = A.User_id)
		ORDER BY A.User_id
	END
	ELSE IF @action = 3
	BEGIN --List Sender Mail
		SELECT A.contactMeanOutId AS Id, ISNULL(R.inboundId, 0) AS AcdId, A.isActive AS IsActive
		FROM contactMeanOut A
		LEFT JOIN relationContactMeanOutInbound R ON A.contactMeanOutId = R.contactMeanOutId
		WHERE @senderId IS NULL OR @senderId = A.contactMeanOutId
	END
END
'

		EXEC (@Sql)

		-- *********************** END 	121.03-5_20190430 *********************** ---
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
