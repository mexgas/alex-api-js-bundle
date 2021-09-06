/*
Fecha: 2014/05/12
Descripcion: 	

Version requerida: 13
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 14
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'Create Table- ccRIACampEspWGConsulta'
	set @Sql='
	if  not exists(SELECT * FROM sysobjects WHERE name=''ccRIACampEspWGConsulta'') 
	
	begin 
		CREATE TABLE [dbo].[ccRIACampEspWGConsulta](
			[IDWG] [smallint] NOT NULL,
			[Tipo] [smallint] NOT NULL,
			[IdCampEsp] [smallint] NOT NULL		
		) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_ccRIACampEspWG] ON [dbo].[ccRIACampEspWGConsulta] ([IdCampEsp] ASC)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_ccRIACampEspWG_1] ON [dbo].[ccRIACampEspWGConsulta]([IDWG] ASC)
			WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_ccRIACampEspWG_2] ON [dbo].[ccRIACampEspWGConsulta] ([Tipo] ASC,	[IdCampEsp] ASC)
			WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]


		insert into ccRIACampEspWGConsulta(IDWG,Tipo,IdCampEsp) select IDWG,Tipo,IdCampEsp from ccRIACampEspWG
	end
	'
	EXEC(@Sql)

	set @process = 'ccRIAWorkGroupUsersConsulta - Create table, indexes and insert'
	set @Sql = 'if  not exists(SELECT * FROM sysobjects WHERE name=''ccRIAWorkGroupUsersConsulta'') 
	begin 
		CREATE TABLE [dbo].[ccRIAWorkGroupUsersConsulta](
			[IDWG] [smallint] NOT NULL,
			[User_id] [smallint] NOT NULL
		) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [IX_ccRIAWorkGroupUsers] ON [dbo].[ccRIAWorkGroupUsersConsulta]([IDWG] ASC)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]


		insert into ccRIAWorkGroupUsersConsulta(IDWG,User_id) select IDWG,User_id from ccRIAWorkGroupUsers
	end'

	EXEC(@Sql)

	set @process = 'Create stored- trsp_AdmGetIsXION'
	set @Sql='
	Create procedure [dbo].[trsp_AdmGetIsXION]
	as
	set nocount on
	--declare @version varchar(max)
	SELECT par_valor  from trec_parametros where par_id = 29
	'
	EXEC(@Sql)



	set @process = 'Update Stored- trsp_AdmRecSearchNodeCamp'
	set @Sql='
	
	ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeCamp]
	@Workgroup int

	AS
	BEGIN

		SET NOCOUNT ON;

		select a.idCampEsp, b.cam_descripcion,isnull(d.frame,1) frame from ccRIACampEspWGConsulta a
		inner join ccCamps b on b.cam_id = a.idCampEsp
		left join ccRIACampsGraph c on  c.cam_id = a.idCampEsp
		left join ccRIAGraphics d on d.graphic_id = c.graphic_id
		where a.IDWG = @Workgroup and a.Tipo = 1

	END
	'
	EXEC(@Sql)


	set @process = 'Update Stored- trsp_AdmRecSearchNodeWorkgroup'
	set @Sql='

		ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeWorkgroup]
		@User_id int

		AS
		BEGIN

			SET NOCOUNT ON;

			select b.IDWG, c.WGName from ccusers a inner join ccRIAWorkGroupUsersConsulta b
			on b.user_id = @User_id inner join ccRIACat_WorkGroup c on c.IDWG = b.IDWG and c.StatusWorkGroup = 1
			where a.user_id = @User_id order by 1

		END
	'
	EXEC(@Sql)



	set @process = 'Update Stored- trsp_AdmRecSearchAllRecs'
	set @Sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]

@Sup_id int,
@Finicio datetime,
@Ffin datetime

AS
BEGIN

	SET NOCOUNT ON;

declare @fecha  datetime

set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

	select r.id_grabacion, avg(r.total_forma) as total_forma
	into #tempRiaFormaCalif from ria_formacalif r 
	inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t 
	on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
	group by r.id_grabacion		
	
	select distinct a.IdCampEsp, case when a.Tipo =0 then 1 else 2 end Tipo_llamada
	into #tempCampEspWG from ccRIACampEspWGConsulta a 
	inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG


if (@Finicio >= @fecha and @Ffin >= @fecha) 
	begin
	
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (z.total_forma,0) as total_forma,a.id_repositorio,
		CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
		a.grab_id as grabID, isnull(g.IDWG,0)as IDWG
		from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))		
		left join ccPosicion b on b.pos_id = a.cal_extension * -1
		--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
		left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
		left join ccTipoCalif AS f ON a.calif_id = f.calif_id
		left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
		left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
		inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp 
		where a.finicio BETWEEN  @Finicio AND @Ffin
			

	end
else if (@Finicio < @fecha and @Ffin < @fecha ) 
	begin
	
	select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (z.total_forma,0) as total_forma,a.id_repositorio,
		CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
		a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
		from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3)) 		
		left join ccPosicion b on b.pos_id = a.cal_extension * -1
		--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
		left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
		left join ccTipoCalif AS f ON a.calif_id = f.calif_id
		left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
		left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
		inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp 
		where a.finicio BETWEEN  @Finicio AND @Ffin
	
	end
else if (@Finicio <= @fecha and @Ffin >= @fecha ) 
	begin
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (z.total_forma,0) as total_forma,a.id_repositorio,
		CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion, 
		a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
		from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))		
		left join ccPosicion b on b.pos_id = a.cal_extension * -1
		--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
		left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
		left join ccTipoCalif AS f ON a.calif_id = f.calif_id
		left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
		left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
		inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp 
		where a.finicio BETWEEN  @Finicio AND @Ffin
		union
		select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
		finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
		isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
		isnull (z.total_forma,0) as total_forma,a.id_repositorio,
		CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
		CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
		a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
		from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))		
		left join ccPosicion b on b.pos_id = a.cal_extension * -1
		--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
		left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
		left join ccTipoCalif AS f ON a.calif_id = f.calif_id
		left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
		left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
		inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp 
		where a.finicio BETWEEN  @Finicio AND @Ffin

	end

	drop table #tempRiaFormaCalif
	drop table #tempCampEspWG
	
END'
	EXEC(@Sql)



	set @process = 'Update stored- trsp_AdmRecSearchNodeACD'
	set @Sql='
	ALTER PROCEDURE  [dbo].[trsp_AdmRecSearchNodeACD]
	-- Add the parameters for the stored procedure here

	@Workgroup int

	AS
	BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

	    -- Insert statements for procedure here

		select a.idCampEsp, b.descripcion, isnull(d.frame,1) from ccRIACampEspWGConsulta a
		inner join ccInbound b on b.Inbound_id = a.idCampEsp
		left join ccRIAInboundGraph c on  c.Inbound_id = a.idCampEsp
		left join ccRIAGraphics d on d.graphic_id = c.graphic_id
		where a.IDWG = @Workgroup and a.Tipo = 0

	END
	'
	EXEC(@Sql)


	set @process = 'Update stored- trsp_AdmRecSearchNodeAgent'
	set @Sql='
	ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeAgent] 

	@Workgroup int

	AS
	BEGIN

		SET NOCOUNT ON;

	select a.User_id, a.Nombres, b.IDWG from ccUsers a
	inner join ccRIAWorkGroupUsersConsulta b
	on b.IDWG = @Workgroup
	where a.User_id = b.User_id and a.TipoUser_id = 1

	END
	'
	EXEC(@Sql)


	set @process = 'Update stored- trsp_GetFilesAnalisisGritos'
	set @Sql='

	ALTER PROCEDURE [dbo].[trsp_GetFilesAnalisisGritos] 
	@idRepositorios as varchar(32),
	@sExtension as varchar(10) = ''.vox''
	AS

	declare @Integrado as int
	declare @FInicio as datetime
	declare @sSql1 as nvarchar(180)
	declare @sSql2 as nvarchar (180)
	declare @sSql3 as nvarchar(180) 
	declare @sSql as nvarchar (512)
	declare @dLenAnt as tinyint
	declare @dLenNew as tinyint


	set @FInicio = dateadd(MINUTE, -1, getdate())
	set @sSql = N''''
	set @sSql3 = N''''
	set @sExtension = (select par_valor from trec_parametros where par_id = 54)

	select @integrado = par_valor from trec_parametros where par_id = 29

	--AVRS Integrada
	if (@integrado = 1)

		BEGIN

			set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
			set @sSql2 = '', isnull(tipo_llamada,0) from trec_grabacion NOLOCK where finicio < @fecInicio ''
			set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''

		END

	--AVRS Standalone
	else if(@integrado = 0)

		BEGIN

			set @sSql1 = ''Select top(1000) grab_id, grab_id, cast(grab_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
			set @sSql2 = '', isnull(tipo_llamada,0) from trec_grabacion NOLOCK where finicio < @fecInicio ''
			set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''

		END

	--AVRS XION
	else if(@integrado = 2)
		BEGIN

			set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
			set @sSql2 = '', isnull(tipo_llamada,0) from ria_grabacion NOLOCK where finicio < @fecInicio ''
			set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''

		END

	if (@idRepositorios <> '''')
	begin
		set @dLenAnt = len(@idRepositorios)
		set @idRepositorios = replace(@idRepositorios, ''NULL'', '''')
		if (len(@idRepositorios) = 0)   -- solo solicita NULL
			set @sSql3 = '' and id_repositorio is NULL ''
		else
		begin
			set @dLenNew = len(@idRepositorios) 
			if (@dLenNew = @dLenAnt)
				set @sSql3 = '' and id_repositorio in ('' + @idRepositorios +'')''
			else
			begin
				set @idRepositorios = right(@idRepositorios, @dLenNew-1)
				set @sSql3 = '' and (id_repositorio in ('' + @idRepositorios +'') or (id_repositorio is NULL)) ''
			end
		end
	end
	set @sSql = @sSql1 + @sSql2 + @sSql3 + N'' order by finicio asc''
	exec sp_executesql @sSql, N''@fecInicio datetime'', @fecInicio = @FInicio		
	'
	EXEC(@Sql)


	set @process = 'Update stored- trsp_GetCompleteBackupRange'
	set @Sql='
	
	ALTER PROCEDURE [dbo].[trsp_GetCompleteBackupRange]
	@EndDate DATETIME,
	@isIntegratedRIA BIT

	AS
	DECLARE @Count AS BIGINT
	DECLARE @CountHist AS BIGINT
	DECLARE @MaxExist AS bigint
	DECLARE @MinTime AS INT
	DECLARE @MinFile AS bigint
	DECLARE @MaxFileAr AS bigint
	declare @UsoHist as Bit
	Declare @ExistHist as bit
	
	BEGIN

	IF @isIntegratedRIA  = 1
		BEGIN
			if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[RIA_GRABACIONCONSULTA]''))
				set @ExistHist = 1
			else
				set @ExistHist = 0
			SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
			IF (@MinTime is NULL)
			BEGIN
				SELECT @MinTime=5
			END

			SELECT @MaxFileAr=MAX(grab_id) FROM TREC_BACKUPS
			IF (@MaxFileAr is NULL)
			BEGIN
				SELECT @MaxFileAr=-1
			END
	
			set @UsoHist =1
			if @ExistHist = 1
			begin
				SELECT @MinFile=MIN(grab_id) FROM RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_2)) 
					WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
				if (@MinFile is NULL)
				begin
					SELECT @MinFile=MIN(grab_id) FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) 
						WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
					set @UsoHist = 0
				end
			end
			else
			begin
				SELECT @MinFile=MIN(grab_id) FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) 
					WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
				set @UsoHist = 0
			end

			SELECT @MaxExist=MAX(grab_id) FROM RIA_GRABACION with (index(IX_RIA_GRABACION_3)) WHERE finicio <= @EndDate 
			IF (@MaxExist is NULL)
			BEGIN
				if (@UsoHist = 1)
				begin
					SELECT @MaxExist=MAX(grab_id) FROM RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_3)) WHERE finicio <= @EndDate
				end
				else
					SELECT @MaxExist=0
			END 
			if (@MinFile>@MaxExist)
			begin
				set @MaxExist = @MinFile
			end
			set @CountHist = 0
			if (@UsoHist = 1)
			begin
				SELECT @CountHist=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_4)) 
					WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
					AND (tamano > 0) AND (duracion >= @MinTime)		

				IF (@CountHist is NULL)
				BEGIN
					SELECT @CountHist = 0
				END
			end
			SELECT @Count=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM RIA_GRABACION with (index(IX_RIA_GRABACION_4)) 
				WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
				AND (tamano > 0) AND (duracion >= @MinTime)		

			IF (@Count is NULL)
			BEGIN
				SELECT @Count = 0
			END

			SELECT ''MinFile''=@MinFile,  ''MaxFile''=@MaxExist, ''Size''=(@Count+@CountHist)
		END
	ELSE
		BEGIN
			if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[TREC_GRABACIONCONSULTA]''))
				set @ExistHist = 1
			else
				set @ExistHist = 0
			SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
			IF (@MinTime is NULL)
			BEGIN
				SELECT @MinTime=5
			END

			SELECT @MaxFileAr=MAX(grab_id) FROM TREC_BACKUPS
			IF (@MaxFileAr is NULL)
			BEGIN
				SELECT @MaxFileAr=-1
			END
	
			set @UsoHist =1
			if @ExistHist = 1
			begin
				SELECT @MinFile=MIN(grab_id) FROM TREC_GRABACIONCONSULTA with (index(IX_TREC_GRABACIONCONSULTA_2)) 
					WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
				if (@MinFile is NULL)
				begin
					SELECT @MinFile=MIN(grab_id) FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) 
						WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
					set @UsoHist = 0
				end
			end
			else
			begin
				SELECT @MinFile=MIN(grab_id) FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) 
					WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
				set @UsoHist = 0
			end

			SELECT @MaxExist=MAX(grab_id) FROM TREC_GRABACION with (index(IX_TREC_GRABACION_3)) WHERE finicio <= @EndDate
			IF (@MaxExist is NULL)
			BEGIN
				if (@UsoHist = 1)
				begin
					SELECT @MaxExist=MAX(grab_id) FROM TREC_GRABACIONCONSULTA with (index(IX_TREC_GRABACIONCONSULTA_3)) WHERE finicio <= @EndDate
				end
				else
					SELECT @MaxExist=0
			END 
			if (@MinFile>@MaxExist)
			begin
				set @MaxExist = @MinFile
			end
			set @CountHist = 0
			if (@UsoHist = 1)
			begin
				SELECT @CountHist=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM TREC_GRABACIONCONSULTA with (index(IX_TREC_GRABACIONCONSULTA_4)) 
					WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
					AND (tamano > 0) AND (duracion >= @MinTime)		

				IF (@CountHist is NULL)
				BEGIN
					SELECT @CountHist = 0
				END
			end
			SELECT @Count=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM TREC_GRABACION with (index(IX_TREC_GRABACION_4)) 
				WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
				AND (tamano > 0) AND (duracion >= @MinTime)		

			IF (@Count is NULL)
			BEGIN
				SELECT @Count = 0
			END

			SELECT ''MinFile''=@MinFile,  ''MaxFile''=@MaxExist, ''Size''=(@Count+@CountHist)

		END

	END
	'
	EXEC(@Sql)


	set @process = 'Update stored- trsp_GetFirstBackupFile'
	set @Sql='
	
	ALTER PROCEDURE [dbo].[trsp_GetFirstBackupFile]
	@isItegratedRIA bit
	AS
	DECLARE @FirstBackupFile as bigint
	DECLARE @LastGrabAr as bigint
	DECLARE @MinTime as integer
	DECLARE @Date as datetime
	Declare @MinHistorico as bigint
	Declare @ExistHist as bit

	BEGIN
	IF @isItegratedRIA = 1
		BEGIN
			--delete RIA_ARCHIVO_GRABACION where hecho = 0
			if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[RIA_GRABACIONConsulta]''))
				set @ExistHist = 1
			else
				set @ExistHist = 0
			SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
			IF (@MinTime is NULL)
			BEGIN
				SELECT @MinTime=5
			END

			--SELECT @LastGrabAr=MAX(grab_id_max) FROM RIA_ARCHIVO_GRABACION
			SELECT @LastGrabAr=MAX(grab_id)  FROM TREC_BACKUPS
			IF (@LastGrabAr is NULL)
			BEGIN
				SELECT @LastGrabAr=-1
			END
			if @ExistHist = 1
			begin
				SELECT @MinHistorico = MIN(grab_id) FROM RIA_GRABACIONConsulta with (index(IX_RIA_GRABACIONCONSULTA_2)) 
					WHERE duracion >= @MinTime AND grab_id>@LastGrabAr
				if (@MinHistorico is NULL)
				begin	
					SELECT  @FirstBackupFile=grab_id, @Date=finicio 
						FROM RIA_GRABACION 
						WHERE grab_id =(SELECT MIN(grab_id) 
							FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) 
							WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
				end
				else
				begin
					SELECT  @FirstBackupFile=grab_id, @Date=finicio 
						FROM RIA_GRABACIONConsulta 
						WHERE grab_id =@MinHistorico
				end
			end
			else
			begin
				SELECT  @FirstBackupFile=grab_id, @Date=finicio 
					FROM RIA_GRABACION 
					WHERE grab_id =(SELECT MIN(grab_id) 
						FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) 
						WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
			end

			SELECT ''FirstBackupFile''=@FirstBackupFile, ''Date''=@Date
		END
	ELSE
		BEGIN
			--delete RIA_ARCHIVO_GRABACION where hecho = 0
			if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[TREC_GRABACIONConsulta]''))
				set @ExistHist = 1
			else
				set @ExistHist = 0
			SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
			IF (@MinTime is NULL)
			BEGIN
				SELECT @MinTime=5
			END

			--SELECT @LastGrabAr=MAX(grab_id_max) FROM RIA_ARCHIVO_GRABACION
			SELECT @LastGrabAr=MAX(grab_id)  FROM TREC_BACKUPS
			IF (@LastGrabAr is NULL)
			BEGIN
				SELECT @LastGrabAr=-1
			END
			if @ExistHist = 1
			begin
				SELECT @MinHistorico = MIN(grab_id) FROM TREC_GRABACIONConsulta with (index(IX_TREC_GRABACIONCONSULTA_2)) 
					WHERE duracion >= @MinTime AND grab_id>@LastGrabAr
				if (@MinHistorico is NULL)
				begin	
					SELECT  @FirstBackupFile=grab_id, @Date=finicio 
						FROM TREC_GRABACION 
						WHERE grab_id =(SELECT MIN(grab_id) 
							FROM TREC_GRABACION  with (index(IX_TREC_GRABACION_2)) 
							WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
				end
				else
				begin
					SELECT  @FirstBackupFile=grab_id, @Date=finicio 
						FROM TREC_GRABACIONConsulta 
						WHERE grab_id =@MinHistorico
				end
			end
			else
			begin
				SELECT  @FirstBackupFile=grab_id, @Date=finicio 
					FROM TREC_GRABACION 
					WHERE grab_id =(SELECT MIN(grab_id) 
						FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) 
						WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
			end

			SELECT ''FirstBackupFile''=@FirstBackupFile, ''Date''=@Date
		END 

	END
	'
	EXEC(@Sql)

	set @process = 'Update stored- trsp_AdmCheckForMarks'
	set @Sql='
	ALTER PROCEDURE [dbo].[trsp_AdmCheckForMarks]
	-- Add the parameters for the stored procedure here
	@cal_id int,
	@tipo_llamada int

	AS
	BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

	    -- Insert statements for procedure here

	declare @grab_id int


	--set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)


	select count(*) from CCRecorderRIA.dbo.RIA_MARCAS where call_id = @cal_id and tipo_llamada = @tipo_llamada

	END
	'
	EXEC(@Sql)





------------------ fin SCRIPT @Sql ------------------
	--Generamos nueva version
	--exec dbo.ccsp_getVersion 'BD', @Version

	-- Updating DB Version
	
 	update trec_parametros set par_valor = @Version where par_id = 30 

	commit tran

	end try	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off