/*
Autor: Jesus Gallardo
Descripcion: Optimization BaseX


Version requerida: 56
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 57
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try


	set @process = 'CW-2620 Alter SP ccsp_CleanNodeBaseX'
	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_CleanNodeBaseX]
AS
BEGIN
	DECLARE @percentage INT, @setting INT
	DECLARE @nodos TABLE (fecha VARCHAR(100))
	DECLARE @top INT
	DECLARE @table TABLE (grabId BIGINT PRIMARY KEY, node XML NOT NULL, dateIn DATETIME NOT NULL, STATUS TINYINT NOT NULL)
	DECLARE @tableNotExists TABLE (grabId BIGINT PRIMARY KEY)

	SET @percentage = 20 --porcentaje de registros que se pasaran esta en funcion del setting 188

	SELECT @setting = valor
	FROM ccSettings
	WHERE setting_id = 188

	IF @setting IS NULL
		SET @setting = 40000
	SET @top = @setting * 100 / @percentage

	INSERT INTO @table
	SELECT TOP (@top) A.grab_id, A.node, A.dateIn, STATUS
	FROM ria_RecNode A WITH (NOLOCK)
	WHERE A.STATUS IN (1, 3)
	ORDER BY grab_id

	INSERT INTO @tableNotExists
	SELECT A.grabId
	FROM @table A
	LEFT JOIN RIA_RecNodeHistory B WITH (NOLOCK) ON B.grab_id = A.grabId
	WHERE B.grab_id IS NULL

	INSERT INTO RIA_RecNodeHistory (grab_id, node, dateIn, dateOut, STATUS)
	SELECT A.grabId, A.node, A.dateIn, getdate(), A.STATUS
	FROM @table A
	INNER JOIN @tableNotExists B ON A.grabId = B.grabId

	DELETE
	FROM ria_RecNode
	WHERE grab_id IN (
			SELECT grabId
			FROM @table
			)
END
'
    EXEC(@Sql)
	
	set @process = 'CW-2644 DROP SP ccsp_RIA_ABCLog'
	set @Sql= 'IF EXISTS ( SELECT * 
							FROM   sysobjects 
							WHERE  id = object_id(N''[dbo].[ccsp_RIA_ABCLog]'') 
								   and OBJECTPROPERTY(id, N''IsProcedure'') = 1 )
				BEGIN
					DROP PROCEDURE [dbo].[ccsp_RIA_ABCLog]
				END'
	EXEC(@Sql)
	set @process = 'CW-2644 Alter SP ccsp_RIA_ABCLog'
	set @Sql= 'CREATE PROCEDURE [dbo].[ccsp_RIA_ABCLog] @moduleId SMALLINT, @operationType SMALLINT, @login VARCHAR(20), @target VARCHAR(250), @value VARCHAR(250)
				AS
				SET NOCOUNT ON

				declare @cw_dbpath varchar(250)
				declare @sql varchar(max)
				select @cw_dbpath=par_valor from trec_parametros where par_id=49
				set @sql = ''exec ''+@cw_dbpath+''ccsp_RIA_ABCLog @option=2''+
							'',@operationType=''+cast(@operationType as varchar(5))+
							'',@moduleId=''+cast(@moduleId as varchar(5))+
							'',@login=''+char(39)+@login+char(39)+
							'',@value=''+char(39)+@value+char(39)+
							'',@target=''+char(39)+@target+char(39)

				exec(@sql)

				SET NOCOUNT OFF'
	EXEC(@Sql)
	
	set @process = 'CW-2644 DROP SP trsp_AdmRecSearchRecs'
	set @Sql= 'IF EXISTS ( SELECT * 
							FROM   sysobjects 
							WHERE  id = object_id(N''[dbo].[trsp_AdmRecSearchRecs]'') 
								   and OBJECTPROPERTY(id, N''IsProcedure'') = 1 )
				BEGIN
					DROP PROCEDURE [dbo].[trsp_AdmRecSearchRecs]
				END'
	EXEC(@Sql)
	set @process = 'CW-2644 Alter SP ccsp_RIA_ABCLog'
	set @Sql= 'CREATE PROCEDURE [dbo].[trsp_AdmRecSearchRecs]
				@grabIds nvarchar(max)

				AS
				BEGIN

				SET NOCOUNT ON

					declare @sql nvarchar(max)
					declare @isEncrypted bit

					select @isEncrypted=par_valor from TREC_PARAMETROS where par_id=15


					select id_repositorio, ruta_repositorio
					into #tmpRepositorios
					from TREC_REPOSITORIOS
					where id_repositorio = (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential =
						(select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio


					set @sql=''select a.grab_id as grabID,a.cal_id, a.Tipo_llamada, a.id_repositorio,b.ruta_repositorio as repository,
						case a.Tipo_llamada when 2 then ''''OUTBOUND\'''' else ''''INBOUND\'''' end + cast(floor(a.cal_id/10000) as nvarchar(max)) as subpath,
						case a.Tipo_llamada when 2 then ''''O_'''' else ''''I_'''' end + cast(a.cal_id as nvarchar(max)) + 
						case a.Tipo_llamada when 2 then 	
							case isnull(camp.prefijo,'''''''') when '''''''' then '''''''' else ''''_'''' + camp.prefijo end 	
							else
							case isnull(acds.prefijo,'''''''') when '''''''' then '''''''' else ''''_'''' + acds.prefijo end 				
						end + ''''.wav'''' +
						case ''+cast(@isEncrypted as nvarchar(max)) +'' when 1 then ''''.enc'''' else '''''''' end  fileAudio,
						case a.tipo_llamada when 2 then camp.cam_descripcion else acds.descripcion end campacd
						from RIA_GRABACION a
						inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio
						left join cccamps camp on a.cam_id = camp.cam_id
						left join ccinbound acds on a.cam_id = acds.Inbound_id
						where a.grab_id in(''+@grabIds+'')
						union
						select a.grab_id as grabID,a.cal_id, a.Tipo_llamada, a.id_repositorio,b.ruta_repositorio as repository,
						case a.Tipo_llamada when 2 then ''''OUTBOUND\'''' else ''''INBOUND\'''' end + cast(floor(a.cal_id/10000) as nvarchar(max)) as subpath,
						case a.Tipo_llamada when 2 then ''''O_'''' else ''''I_'''' end + cast(a.cal_id as nvarchar(max)) +
						case a.Tipo_llamada when 2 then 	
							case isnull(camp.prefijo,'''''''') when '''''''' then '''''''' else ''''_'''' + camp.prefijo end 	
							else
							case isnull(acds.prefijo,'''''''') when '''''''' then '''''''' else ''''_'''' + acds.prefijo end 					
						end + ''''.wav'''' +
						case ''+cast(@isEncrypted as nvarchar(max)) +'' when 1 then ''''.enc'''' else '''''''' end  fileAudior,
						case a.tipo_llamada when 2 then camp.cam_descripcion else acds.descripcion end campacd
						from RIA_GRABACIONCONSULTA a
						inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio
						left join cccamps camp on a.cam_id = camp.cam_id
						left join ccinbound acds on a.cam_id = acds.Inbound_id
						where a.grab_id in(''+@grabIds+'')''
					print @sql
					exec (@sql)

					drop table #tmpRepositorios

				END'
	EXEC(@Sql)
	
	set @process = 'CW-2644 DROP SP trsp_AdmRecSearchGreaterThatGrabID'
	set @Sql= 'IF EXISTS ( SELECT * 
							FROM   sysobjects 
							WHERE  id = object_id(N''[dbo].[trsp_AdmRecSearchGreaterThatGrabID]'') 
								   and OBJECTPROPERTY(id, N''IsProcedure'') = 1 )
				BEGIN
					DROP PROCEDURE [dbo].[trsp_AdmRecSearchGreaterThatGrabID]
				END'
	EXEC(@Sql)
	set @process = 'CW-2644 Alter SP ccsp_RIA_ABCLog'
	set @Sql= 'CREATE PROCEDURE [dbo].[trsp_AdmRecSearchGreaterThatGrabID]
				@Sup_id int,
				@Grab_id int
				AS
				BEGIN

				SET NOCOUNT ON

				declare @sql1 nvarchar(max)

				--Tabla con toda la informaciom
				CREATE TABLE #tempRiAAllInfo(
					cal_id int,
					tipo_llamada smallint,
					cam_id smallint,
					calif_id smallint,
					duracion int,
					id_nivel_grito int,
					[user_id] int,
					finicio datetime,
					ani varchar (100),
					dni varchar (100),
					cal_key varchar (100),
					cal_manual tinyint,
					posicion int,
					computer varchar(100),
					total_forma int,
					id_repositorio tinyint,
					score varchar (100),
					formato_duracion varchar(15),
					grab_id bigint,
					IDWG varchar (800),
					califSub_id varchar(800),
					cal_tMoh smallint,
					Prefijo varchar(max)
				)

				CREATE CLUSTERED INDEX [IX_tempRiAAllInfodate] ON [#tempRiAAllInfo]
				(
				[finicio] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


				create table #auxOutbound(
					cal_id int,
					tipo_llamada smallint,
					cam_id smallint,
					calif_id smallint,
					duracion int,
					id_nivel_grito int,
					[user_id] int,
					finicio datetime,
					ani varchar (100),
					dni varchar (100),
					cal_key varchar (100),
					cal_manual tinyint,
					posicion int,
					computer varchar(100),
					total_forma int,
					id_repositorio tinyint,
					score varchar (100),
					formato_duracion varchar(15),
					grab_id bigint,
					IDWG varchar (800),
					califSub_id  varchar(800),
					cal_tMoh smallint,
					Prefijo varchar(max)
					)

				--Segmento de Calificaciones
				create table #tempRiaFormaCalif6(
				id_grabacion bigint,
				total_forma int)

				insert into #tempRiaFormaCalif6 (id_grabacion,total_forma)
				select r.id_grabacion, avg(r.total_forma) as total_forma
				from ria_formacalif r
				inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t
				on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
				group by r.id_grabacion


				--Segmento de Supervisor
				create table #tempCampEspWG6(
				IdCampEsp smallint,
				Tipo smallint,
				[user_id] smallint)

				CREATE NONCLUSTERED INDEX [IX_tempCampEspWG6] ON [#tempCampEspWG6]
				(
				[user_id] ASc
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]

				insert into #tempCampEspWG6 (IdCampEsp,Tipo,user_id)
				  select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id
				from ccRIACampEspWGConsulta a
				inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on a.IDWG = b.IDWG
				and b.User_id = case @Sup_id when 0 then b.User_id else @Sup_id end

				--Segmento de usurios asociados al supervisor
				create table #tempComplete6(
				IdCampEsp smallint,
				Tipo smallint,
				[user_id] int,
				IDWG smallint)

				CREATE NONCLUSTERED INDEX [IX_tempComplete6User] ON [#tempComplete6]
				(
				[user_id] ASC
				)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]


					insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)
					select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
					from  ccRIACampEspWGConsulta a  inner join
					(select IDWG,user_id from ccRIAWorkGroupUsersConsulta where IDWG in
						(select  distinct a.IDWG from ccRIACampEspWGConsulta a
							inner join  ccRIAWorkGroupUsersConsulta b with (index(IX_ccRIAWorkGroupUsersConsulta2)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
							)and user_id <> @Sup_id
					) b on a.IDWG=b.IDWG

								set @sql1 =''
								insert into #tempRiAAllInfo
								select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
											finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
											isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
											isnull (z.total_forma,0) as total_forma,a.id_repositorio,
											isnull (f.description,'''''''')  AS score,
											CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
											grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh, ISNULL(a.prefijo,'''''''')
								from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
								left join ccTipoCalif AS f ON a.calif_id = f.calif_id
								left join cctipocalifsub p on p.califSub_id=a.califSub_id
								left join ccPosicion b on b.pos_id = a.cal_extension * -1
								left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
								left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
								inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
								where a.grab_id > '' + cast(@Grab_id as varchar(5)) +'' and a.tipo_llamada=1''

								--print @sql1
								exec (@sql1)

								set @sql1 =''
								insert into #tempRiAAllInfo
								select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
											finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
											isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
											isnull (z.total_forma,0) as total_forma,a.id_repositorio,
											isnull (f.description,'''''''')  AS score,
											CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
											grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh,ISNULL(a.prefijo,'''''''')
								from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
								left join ccTipoCalif AS f ON a.calif_id = f.calif_id
								left join cctipocalifsub p on p.califSub_id=a.califSub_id
								left join ccPosicion b on b.pos_id = a.cal_extension * -1
								left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
								left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
								inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
								where a.grab_id > '' + cast(@Grab_id as varchar(5)) +'' and a.tipo_llamada=1''

								--print @sql1
								exec (@sql1)

								set @sql1 =''
								insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
												finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
												id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh,prefijo)
								select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
												finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
												isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
												isnull (z.total_forma,0) as total_forma,a.id_repositorio,
												isnull (e.description,'''''''')  AS score,
												CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
												grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh,ISNULL(a.prefijo,'''''''')
								from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
								left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
								left join cctipocalifsubout k on k.califSub_id=a.califSub_id
								left join ccPosicion b on b.pos_id = a.cal_extension * -1
								left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
								left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
								where a.grab_id > '' + cast(@Grab_id as varchar(5)) +'' and a.tipo_llamada=2''
							
								--print @sql1
								exec (@sql1)
								
								insert into #tempRiAAllInfo
								select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
												finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
												id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh, prefijo from #auxOutbound a
								inner join #tempComplete6 U  on a.user_id=U.user_id

								insert into #tempRiAAllInfo
								select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
												finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
												id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh, prefijo from #auxOutbound a
								inner join #tempCampEspWG6 U  on a.user_id=U.user_id

								
								if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where grab_id > @Grab_id)> 0
								begin
										set @sql1 =''
										insert into #tempRiAAllInfo
										select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
												finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
												isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
												isnull (z.total_forma,0) as total_forma,a.id_repositorio,
												isnull (f.description,'''''''')  AS score,
												CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
												grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh ,''''''''
										from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
										left join ccTipoCalif AS f ON a.calif_id = f.calif_id
										left join cctipocalifsub p on p.califSub_id=a.califSub_id
										left join ccPosicion b on b.pos_id = a.cal_extension * -1
										left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
										left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
										inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
										where a.IDWG is not null and a.grab_id > '' + cast(@Grab_id as varchar(5)) +'' and a.tipo_llamada=1''

										--print @sql1
										exec (@sql1)

										set @sql1 =''
										insert into #tempRiAAllInfo
										select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
													finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
													isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
													isnull (z.total_forma,0) as total_forma,a.id_repositorio,
													isnull (f.description,'''''''')  AS score,
													CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
													grab_id as grabID, a.IDWG as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh, ''''''''
										from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
										left join ccTipoCalif AS f ON a.calif_id = f.calif_id
										left join cctipocalifsub p on p.califSub_id=a.califSub_id
										left join ccPosicion b on b.pos_id = a.cal_extension * -1
										left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
										left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
										inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
										where a.IDWG is not null and a.grab_id > '' + cast(@Grab_id as varchar(5)) +'' and a.tipo_llamada=1''

										--print @sql1
										exec (@sql1)

										set @sql1 =''
										insert into #auxOutbound(cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
													finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
													id_repositorio ,score ,formato_duracion ,grab_id ,IDWG ,califSub_id ,cal_tMoh)
										select DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
														finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
														isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
														isnull (z.total_forma,0) as total_forma,a.id_repositorio,
														isnull (e.description,'''''''')  AS score,
														CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
														grab_id as grabID, a.IDWG as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh , ''''''''
										from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
										left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
										left join cctipocalifsubout k on k.califSub_id=a.califSub_id
										left join ccPosicion b on b.pos_id = a.cal_extension * -1
										left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
										left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
										where a.IDWG is not null and a.grab_id > '' + cast(@Grab_id as varchar(5)) +'' and a.tipo_llamada=2''

										--print @sql1
										exec (@sql1)

										insert into #tempRiAAllInfo
										select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
														finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
														id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh,a.Prefijo from #auxOutbound a
										inner join #tempComplete6 U  on a.user_id=U.user_id

										insert into #tempRiAAllInfo
										select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
														finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
														id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh,a.Prefijo from #auxOutbound a
										inner join #tempCampEspWG6 U  on a.user_id=U.user_id

								end

				--Seleccionar info de tabla global
				select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,user_id,
					   finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
					   id_repositorio,score,formato_duracion,grab_id,IDWG,califSub_id,cal_tMoh,Prefijo
				from #tempRiAAllInfo with (index(IX_tempRiAAllInfodate))  order by finicio asc

				drop table #tempRiaFormaCalif6
				drop table #tempCampEspWG6
				drop table #tempComplete6
				drop table #tempRiAAllInfo
				drop table #auxOutbound

				END'
	EXEC(@Sql)
    
------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

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
