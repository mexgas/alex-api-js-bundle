set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 66
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try

		
		SET @process = 'CW-3892 trsp_AdmRecSearchAllRecs'
		SET @sql = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]
			@Sup_id int,
			@Finicio datetime,
			@Ffin datetime,
			@UserList varchar(MAX) =null,
			@IDWGList varchar(MAX) =null,
			@TypeCall int = null,
			@CampaingsList varchar(MAX) =null,
			@ACDList varchar(MAX) =null,
			@DispositionList varchar(MAX) =null,
			@SubdispositionList varchar(MAX) =null

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
				cal_tMoh smallint
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
				cal_tMoh smallint
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
			[user_id] smallint,
			IDWG smallint)
 
			CREATE NONCLUSTERED INDEX [IX_tempCampEspWG6] ON [#tempCampEspWG6] 
			(
			[user_id] ASc
			)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]
 
			insert into #tempCampEspWG6 (IdCampEsp,Tipo,user_id,IDWG)
			  select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id,a.IDWG
			from ccRIACampEspWG a
			inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = @Sup_id and a.IDWG = b.IDWG		

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
 
	

			if @UserList is not null and @UserList <> ''''
			BEGIN
				set @sql1=''insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)
						select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
						from ccRIACampEspWG a  inner join 
						(select IDWG,user_id from ccRIAWorkGroupUsers where IDWG in 
						(select  distinct a.IDWG from ccRIACampEspWG a
									inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = ''+cast(@Sup_id as nvarchar(max))+'' and a.IDWG = b.IDWG
						)and user_id <> ''+cast(@Sup_id as nvarchar(max))+'' and user_id in (''+@UserList+'')
						) b on a.IDWG=b.IDWG''
				exec (@sql1)
				
			END
			else
			BEGIN
				insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)  
				select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
				from  ccRIACampEspWG a  inner join
				(select IDWG,user_id from ccRIAWorkGroupUsers where IDWG in 
					(select  distinct a.IDWG from ccRIACampEspWG a
						inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
						)and user_id <> @Sup_id 
				) b on a.IDWG=b.IDWG
			END

		
			if @TypeCall is not null and @TypeCall <> ''''
				BEGIN
					if @TypeCall=1 -- Only Inbound 
						BEGIN
							set @sql1 =''
							insert into #tempRiAAllInfo
							select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
										finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
										isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
										isnull (z.total_forma,0) as total_forma,a.id_repositorio,
										isnull (f.description,'''''''')  AS score,
										CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
										grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
							from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
							left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
							left join cctipocalifsub p on p.califSub_id=a.califSub_id
							left join ccPosicion b on b.pos_id = a.cal_extension * -1
							left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
							left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
							left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
							inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
							where'' 
							if @IDWGList is not null and @IDWGList <> '''' 
								set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
											'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
							else
								--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
								set @sql1 = @sql1 + ''  a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
				
							if @ACDList is not null and @ACDList <> ''''
								set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' 						
					
							if @DispositionList is not null and @DispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

							if @SubdispositionList is not null and @SubdispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

							set @sql1 = @sql1 + '' and a.tipo_llamada=1''
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
										grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
							from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
							left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
							left join cctipocalifsub p on p.califSub_id=a.califSub_id
							left join ccPosicion b on b.pos_id = a.cal_extension * -1
							left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
							left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
							left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
							inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
							where'' 
							if @IDWGList is not null and @IDWGList <> '''' 
								set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
											'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
							else
								--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
								set @sql1 = @sql1 + '' a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
													
							if @ACDList is not null and @ACDList <> ''''
								set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''	
						
							if @DispositionList is not null and @DispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

							if @SubdispositionList is not null and @SubdispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

							set @sql1 = @sql1 + '' and a.tipo_llamada=1''
							--print @sql1
							exec (@sql1)

							if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where finicio BETWEEN cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) )> 0
								begin
									set @sql1 =''
									insert into #tempRiAAllInfo
									select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
											finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
											isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
											isnull (z.total_forma,0) as total_forma,a.id_repositorio,
											isnull (f.description,'''''''')  AS score,
											CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
											grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))			
									left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
									left join cctipocalifsub p on p.califSub_id=a.califSub_id
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
									left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
									inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
									where''	
					
									if @IDWGList is not null and @IDWGList <> '''' 
										set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
									else
										set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
										
						
									if @ACDList is not null and @ACDList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''
						
									if @DispositionList is not null and @DispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

									if @SubdispositionList is not null and @SubdispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''
																					
									set @sql1 = @sql1 + '' and a.tipo_llamada=1''
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
												grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))			
									left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
									left join cctipocalifsub p on p.califSub_id=a.califSub_id
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
									left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
									inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
									where''	
					
									if @IDWGList is not null and @IDWGList <> '''' 
										set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
									else
										set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
												
									if @ACDList is not null and @ACDList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''				
						
									if @DispositionList is not null and @DispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

									if @SubdispositionList is not null and @SubdispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''
																					
									set @sql1 = @sql1 + '' and a.tipo_llamada=1''
									--print @sql1
									exec (@sql1)
								end
						END
					ELSE
						BEGIN --Only Outbound
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
											grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
							from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
							left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
							left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
							left join ccPosicion b on b.pos_id = a.cal_extension * -1
							left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
							left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion			
							left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
							where'' 

							if @IDWGList is not null and @IDWGList <> '''' 
								set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
											'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
							else
								--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
								set @sql1 = @sql1 + ''  a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
						
							if @CampaingsList is not null and @CampaingsList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''							
				
							if @DispositionList is not null and @DispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

							if @SubdispositionList is not null and @SubdispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''								

							set @sql1 = @sql1 + '' and a.tipo_llamada=2''
							--print @sql1
							exec (@sql1)

							insert into #tempRiAAllInfo
							select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
											finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
											id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
							inner join #tempComplete6 U  on a.user_id=U.user_id

							insert into #tempRiAAllInfo
							select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
											finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
											id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
							inner join #tempCampEspWG6 U  on a.user_id=U.user_id
				
				
							if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where finicio BETWEEN cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) )> 0
								begin
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
													grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
									left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
									left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion			
									left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
									where''	
					
									if @IDWGList is not null and @IDWGList <> '''' 
										set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
									else
										set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
																		
									if @CampaingsList is not null and @CampaingsList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''							
						
									if @DispositionList is not null and @DispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

									if @SubdispositionList is not null and @SubdispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''		
																												
									set @sql1 = @sql1 + '' and a.tipo_llamada=2''
									--print @sql1
									exec (@sql1)

									insert into #tempRiAAllInfo
									select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
													finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
													id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
									inner join #tempComplete6 U  on a.user_id=U.user_id

									insert into #tempRiAAllInfo
									select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
													finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
													id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
									inner join #tempCampEspWG6 U  on a.user_id=U.user_id
						
								end
						END
				END
			ELSE
				BEGIN --NOT Inbound or Outbound this mean both
							set @sql1 =''
							insert into #tempRiAAllInfo
							select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
										finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
										isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
										isnull (z.total_forma,0) as total_forma,a.id_repositorio,
										isnull (f.description,'''''''')  AS score,
										CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
										grab_id as grabID, a.IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
							from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
							left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
							left join cctipocalifsub p on p.califSub_id=a.califSub_id
							left join ccPosicion b on b.pos_id = a.cal_extension * -1
							left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
							left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
							inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
							where'' 
							if @IDWGList is not null and @IDWGList <> '''' 
								set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
											'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
							else
								--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
								set @sql1 = @sql1 + '' a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
				
							if @ACDList is not null and @ACDList <> ''''
								set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' 						
				
							if @DispositionList is not null and @DispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

							if @SubdispositionList is not null and @SubdispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''	
						
							set @sql1 = @sql1 + '' and a.tipo_llamada=1''
							print @sql1
							exec (@sql1)

							set @sql1 =''
							insert into #tempRiAAllInfo
							select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
										finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
										isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
										isnull (z.total_forma,0) as total_forma,a.id_repositorio,
										isnull (f.description,'''''''')  AS score,
										CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
										grab_id as grabID, a.IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
							from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))			
							left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
							left join cctipocalifsub p on p.califSub_id=a.califSub_id
							left join ccPosicion b on b.pos_id = a.cal_extension * -1
							left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
							left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
							inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
							where'' 
							if @IDWGList is not null and @IDWGList <> '''' 
								set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
											'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
							else
								--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
								set @sql1 = @sql1 + ''  a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
													
							if @ACDList is not null and @ACDList <> ''''
								set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''	
							
							if @DispositionList is not null and @DispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

							if @SubdispositionList is not null and @SubdispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''
						
							set @sql1 = @sql1 + '' and a.tipo_llamada=1''
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
											grab_id as grabID, a.IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
							from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
							left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
							left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
							left join ccPosicion b on b.pos_id = a.cal_extension * -1
							left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
							left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion			
							where'' 

							if @IDWGList is not null and @IDWGList <> '''' 
								set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
											'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
							else
								--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
								set @sql1 = @sql1 + '' a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
						
							if @CampaingsList is not null and @CampaingsList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''							
				
							if @DispositionList is not null and @DispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

							if @SubdispositionList is not null and @SubdispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''	
																					
							set @sql1 = @sql1 + '' and a.tipo_llamada=2''
							--print @sql1
							exec (@sql1)

							insert into #tempRiAAllInfo
							select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
											finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
											id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
							inner join #tempComplete6 U  on a.user_id=U.user_id

							insert into #tempRiAAllInfo
							select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
											finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
											id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
							inner join #tempCampEspWG6 U  on a.user_id=U.user_id

							if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where finicio BETWEEN cast(@Finicio as nvarchar)  AND  cast(@Ffin as nvarchar) )> 0
							begin
									set @sql1 =''
									insert into #tempRiAAllInfo
									select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
											finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
											isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
											isnull (z.total_forma,0) as total_forma,a.id_repositorio,
											isnull (f.description,'''''''')  AS score,
											CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
											grab_id as grabID, a.IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))			
									left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
									left join cctipocalifsub p on p.califSub_id=a.califSub_id
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
									inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id  
									where''	
					
									if @IDWGList is not null and @IDWGList <> '''' 
										set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
									else
										set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
										
						
									if @ACDList is not null and @ACDList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''
						
									if @DispositionList is not null and @DispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

									if @SubdispositionList is not null and @SubdispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''
																							
									set @sql1 = @sql1 + '' and a.tipo_llamada=1''
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
												grab_id as grabID, a.IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))			
									left join ccTipoCalif AS f ON a.calif_id = f.calif_id			
									left join cctipocalifsub p on p.califSub_id=a.califSub_id
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
									inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id  
									where''	
					
									if @IDWGList is not null and @IDWGList <> '''' 
										set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
									else
										set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
						
						
									if @ACDList is not null and @ACDList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''				
						
									if @DispositionList is not null and @DispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

									if @SubdispositionList is not null and @SubdispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''
																						
									set @sql1 = @sql1 + '' and a.tipo_llamada=1''
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
													grab_id as grabID, a.IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
									left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id			
									left join cctipocalifsubout k on k.califSub_id=a.califSub_id		
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id 
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion			
									where''	
					
									if @IDWGList is not null and @IDWGList <> '''' 
										set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
									else
										set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
																		
									if @CampaingsList is not null and @CampaingsList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''							
						
									if @DispositionList is not null and @DispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

									if @SubdispositionList is not null and @SubdispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

									set @sql1 = @sql1 + '' and a.tipo_llamada=2''
									--print @sql1
									exec (@sql1)

									insert into #tempRiAAllInfo
									select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
													finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
													id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
									inner join #tempComplete6 U  on a.user_id=U.user_id

									insert into #tempRiAAllInfo
									select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
													finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
													id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a 
									inner join #tempCampEspWG6 U  on a.user_id=U.user_id

							end

				END

	

			--Seleccionar info de tabla global
			select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,i.user_id,
				   finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
				   id_repositorio,score,formato_duracion,grab_id, IDWG,califSub_id,cal_tMoh 
			from #tempRiAAllInfo i with (index(IX_tempRiAAllInfodate))  
			order by finicio asc

			drop table #tempRiaFormaCalif6
			drop table #tempCampEspWG6
			drop table #tempComplete6
			drop table #tempRiAAllInfo
			drop table #auxOutbound
	
			END'
		EXEC (@sql)

		SET @process = 'CW-3892 trsp_AdmRecSearchCallIdStr'
		SET @sql = 'ALTER PROCEDURE [dbo].[trsp_AdmRecSearchCallIdStr]
			@Sup_id int,
			@callIdList as nvarchar(max),
			@UserList varchar(MAX) =null,
			@IDWGList varchar(MAX) =null,
			@TypeCall int = null,
			@CampaingsList varchar(MAX) =null,
			@ACDList varchar(MAX) =null,
			@DispositionList varchar(MAX) =null,
			@SubdispositionList varchar(MAX) =null

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
			[user_id] smallint,
			IDWG smallint)

			CREATE NONCLUSTERED INDEX [IX_tempCampEspWG6] ON [#tempCampEspWG6]
			(
			[user_id] ASc
			)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [PRIMARY]

			insert into #tempCampEspWG6 (IdCampEsp,Tipo,user_id,IDWG)
			  select distinct a.IdCampEsp, a.Tipo as Tipo_llamada,b.User_id,a.IDWG
			from ccRIACampEspWG a
			inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = @Sup_id and a.IDWG = b.IDWG

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



			if @UserList is not null and @UserList <> ''''
			BEGIN
				set @sql1=''insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)
						select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
						from ccRIACampEspWG a  inner join
						(select IDWG,user_id from ccRIAWorkGroupUsers where IDWG in
						(select  distinct a.IDWG from ccRIACampEspWG a
									inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = ''+cast(@Sup_id as nvarchar(max))+'' and a.IDWG = b.IDWG
						)and user_id <> ''+cast(@Sup_id as nvarchar(max))+'' and user_id in (''+@UserList+'')
						) b on a.IDWG=b.IDWG''
				exec (@sql1)

			END
			else
			BEGIN
				insert into #tempComplete6  (IdCampEsp,Tipo,user_id,IDWG)
				select distinct a.IdCampEsp, a.Tipo as Tipo_llamada, b.user_id,b.IDWG
				from  ccRIACampEspWG a  inner join
				(select IDWG,user_id from ccRIAWorkGroupUsers where IDWG in
					(select  distinct a.IDWG from ccRIACampEspWG a
						inner join  ccRIAWorkGroupUsers b with (index(IX_ccRIAWorkGroupUsers_I)) on b.User_id = @Sup_id and a.IDWG = b.IDWG
						)and user_id <> @Sup_id
				) b on a.IDWG=b.IDWG
			END


			if @TypeCall is not null and @TypeCall <> ''''
				BEGIN
					if @TypeCall=1 -- Only Inbound
						BEGIN
							set @sql1 =''
							insert into #tempRiAAllInfo
							select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
										finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
										isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
										isnull (z.total_forma,0) as total_forma,a.id_repositorio,
										isnull (f.description,'''''''')  AS score,
										CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
										grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
							from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
							left join ccTipoCalif AS f ON a.calif_id = f.calif_id
							left join cctipocalifsub p on p.califSub_id=a.califSub_id
							left join ccPosicion b on b.pos_id = a.cal_extension * -1
							left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
							left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
							left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
							inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
							where''
							if @IDWGList is not null and @IDWGList <> ''''
								set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
											'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
							else
								--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
								set @sql1 = @sql1 + ''  a.cal_id in('' + @callIdList +'')''

							if @ACDList is not null and @ACDList <> ''''
								set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

							if @DispositionList is not null and @DispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

							if @SubdispositionList is not null and @SubdispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

							set @sql1 = @sql1 + '' and a.tipo_llamada=1''
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
										grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
							from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
							left join ccTipoCalif AS f ON a.calif_id = f.calif_id
							left join cctipocalifsub p on p.califSub_id=a.califSub_id
							left join ccPosicion b on b.pos_id = a.cal_extension * -1
							left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
							left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
							left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
							inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
							where''
							if @IDWGList is not null and @IDWGList <> ''''
								set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
											'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
							else
								--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
								set @sql1 = @sql1 + '' a.cal_id in('' + @callIdList +'')''

							if @ACDList is not null and @ACDList <> ''''
								set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

							if @DispositionList is not null and @DispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

							if @SubdispositionList is not null and @SubdispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

							set @sql1 = @sql1 + '' and a.tipo_llamada=1''
							--print @sql1
							exec (@sql1)

							if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where cal_id in (select * from split_me(@callIdList) ) )> 0
								begin
									set @sql1 =''
									insert into #tempRiAAllInfo
									select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
											finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
											isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
											isnull (z.total_forma,0) as total_forma,a.id_repositorio,
											isnull (f.description,'''''''')  AS score,
											CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
											grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
									left join ccTipoCalif AS f ON a.calif_id = f.calif_id
									left join cctipocalifsub p on p.califSub_id=a.califSub_id
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
									left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
									inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
									where''

									if @IDWGList is not null and @IDWGList <> ''''
										set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
									else
										set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''


									if @ACDList is not null and @ACDList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

									if @DispositionList is not null and @DispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

									if @SubdispositionList is not null and @SubdispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

									set @sql1 = @sql1 + '' and a.tipo_llamada=1''
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
												grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
									left join ccTipoCalif AS f ON a.calif_id = f.calif_id
									left join cctipocalifsub p on p.califSub_id=a.califSub_id
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
									left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
									inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
									where''

									if @IDWGList is not null and @IDWGList <> ''''
										set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
									else
										set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''

									if @ACDList is not null and @ACDList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

									if @DispositionList is not null and @DispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

									if @SubdispositionList is not null and @SubdispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

									set @sql1 = @sql1 + '' and a.tipo_llamada=1''
									--print @sql1
									exec (@sql1)
								end
						END
					ELSE
						BEGIN --Only Outbound
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
											grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
							from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
							left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
							left join cctipocalifsubout k on k.califSub_id=a.califSub_id
							left join ccPosicion b on b.pos_id = a.cal_extension * -1
							left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
							left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
							left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
							where''

							if @IDWGList is not null and @IDWGList <> ''''
								set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
											'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
							else
								--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
								set @sql1 = @sql1 + ''  a.cal_id in('' + @callIdList +'')''

							if @CampaingsList is not null and @CampaingsList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

							if @DispositionList is not null and @DispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

							if @SubdispositionList is not null and @SubdispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

							set @sql1 = @sql1 + '' and a.tipo_llamada=2''
							--print @sql1
							exec (@sql1)

							insert into #tempRiAAllInfo
							select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
											finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
											id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
							inner join #tempComplete6 U  on a.user_id=U.user_id

							insert into #tempRiAAllInfo
							select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
											finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
											id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
							inner join #tempCampEspWG6 U  on a.user_id=U.user_id


							if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where cal_id in (select * from split_me(@callIdList) ) )> 0
								begin
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
													grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
									left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
									left join cctipocalifsubout k on k.califSub_id=a.califSub_id
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
									left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
									where''

									if @IDWGList is not null and @IDWGList <> ''''
										set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
									else
										set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''

									if @CampaingsList is not null and @CampaingsList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

									if @DispositionList is not null and @DispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

									if @SubdispositionList is not null and @SubdispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

									set @sql1 = @sql1 + '' and a.tipo_llamada=2''
									--print @sql1
									exec (@sql1)

									insert into #tempRiAAllInfo
									select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
													finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
													id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
									inner join #tempComplete6 U  on a.user_id=U.user_id

									insert into #tempRiAAllInfo
									select distinct cal_id,tipo_llamada,cam_id,calif_id,duracion,id_nivel_grito,a.user_id,
													finicio,ani,dni,cal_key,cal_manual,posicion,computer,total_forma,
													id_repositorio,score,formato_duracion,grab_id,a.IDWG,califSub_id,cal_tMoh from #auxOutbound a
									inner join #tempCampEspWG6 U  on a.user_id=U.user_id

								end
						END
				END
			ELSE
				BEGIN --NOT Inbound or Outbound this mean both
							set @sql1 =''
							insert into #tempRiAAllInfo
							select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
										finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
										isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
										isnull (z.total_forma,0) as total_forma,a.id_repositorio,
										isnull (f.description,'''''''')  AS score,
										CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
										grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh, ISNULL(a.prefijo,'''''''')
							from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
							left join ccTipoCalif AS f ON a.calif_id = f.calif_id
							left join cctipocalifsub p on p.califSub_id=a.califSub_id
							left join ccPosicion b on b.pos_id = a.cal_extension * -1
							left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
							left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
							left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
							inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
							where''
							if @IDWGList is not null and @IDWGList <> ''''
								set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
											'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
							else
								--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
								set @sql1 = @sql1 + '' a.cal_id in('' + @callIdList +'')''

							if @ACDList is not null and @ACDList <> ''''
								set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

							if @DispositionList is not null and @DispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

							if @SubdispositionList is not null and @SubdispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

							set @sql1 = @sql1 + '' and a.tipo_llamada=1''
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
										grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh,ISNULL(a.prefijo,'''''''')
							from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
							left join ccTipoCalif AS f ON a.calif_id = f.calif_id
							left join cctipocalifsub p on p.califSub_id=a.califSub_id
							left join ccPosicion b on b.pos_id = a.cal_extension * -1
							left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
							left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
							left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
							inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
							where''
							if @IDWGList is not null and @IDWGList <> ''''
								set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
											'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
							else
								--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
								set @sql1 = @sql1 + ''  a.cal_id in('' + @callIdList +'')''

							if @ACDList is not null and @ACDList <> ''''
								set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

							if @DispositionList is not null and @DispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

							if @SubdispositionList is not null and @SubdispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

							set @sql1 = @sql1 + '' and a.tipo_llamada=1''
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
											grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh,ISNULL(a.prefijo,'''''''')
							from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))
							left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
							left join cctipocalifsubout k on k.califSub_id=a.califSub_id
							left join ccPosicion b on b.pos_id = a.cal_extension * -1
							left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
							left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
							left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
							where''

							if @IDWGList is not null and @IDWGList <> ''''
								set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
											'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
							else
								--set @sql1 = @sql1 + '' a.IDWG is not null and a.finicio BETWEEN '' + '''''''' + cast(@Finicio as nvarchar) + '''''''' +  '' AND '' + '''''''' + cast(@Ffin as nvarchar) + ''''''''
								set @sql1 = @sql1 + '' a.cal_id in('' + @callIdList +'')''

							if @CampaingsList is not null and @CampaingsList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

							if @DispositionList is not null and @DispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

							if @SubdispositionList is not null and @SubdispositionList <> ''''
								set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

							set @sql1 = @sql1 + '' and a.tipo_llamada=2''
			
							print @sql1
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

				
							if (select count(*) from RIA_GRABACIONConsulta with(index(IX_RIA_GRABACIONCONSULTA_3), nolock) where cal_id in (select * from split_me(@callIdList) ) )> 0
							begin
									set @sql1 =''
									insert into #tempRiAAllInfo
									select  DISTINCT a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
											finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
											isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, isnull(b.Computer,''''''''),
											isnull (z.total_forma,0) as total_forma,a.id_repositorio,
											isnull (f.description,'''''''')  AS score,
											CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
											grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh ,''''''''
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
									left join ccTipoCalif AS f ON a.calif_id = f.calif_id
									left join cctipocalifsub p on p.califSub_id=a.califSub_id
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
									left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
									inner join #tempComplete6 U with (index(IX_tempComplete6User)) on a.age_id=U.user_id
									where''

									if @IDWGList is not null and @IDWGList <> ''''
										set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
									else
										set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''


									if @ACDList is not null and @ACDList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

									if @DispositionList is not null and @DispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

									if @SubdispositionList is not null and @SubdispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

									set @sql1 = @sql1 + '' and a.tipo_llamada=1''
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
												grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull( p.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh, ''''''''
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
									left join ccTipoCalif AS f ON a.calif_id = f.calif_id
									left join cctipocalifsub p on p.califSub_id=a.califSub_id
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
									left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=0
									inner join #tempCampEspWG6 U with (index(IX_tempCampEspWG6)) on a.age_id=U.user_id
									where''

									if @IDWGList is not null and @IDWGList <> ''''
										set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
									else
										set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''


									if @ACDList is not null and @ACDList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@ACDList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

									if @DispositionList is not null and @DispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

									if @SubdispositionList is not null and @SubdispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

									set @sql1 = @sql1 + '' and a.tipo_llamada=1''
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
													grab_id as grabID, isnull(a.IDWG,h.IDWG) as IDWG,isnull(k.califSubDesc ,'''''''') AS califSub_id,a.cal_tMoh as cal_tMoh , ''''''''
									from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))
									left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id
									left join cctipocalifsubout k on k.califSub_id=a.califSub_id
									left join ccPosicion b on b.pos_id = a.cal_extension * -1
									left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id
									left join #tempRiaFormaCalif6 z on a.grab_id=z.id_grabacion
									left join #tempCampEspWG6 h on h.IdCampEsp=a.cam_id and h.Tipo=1
									where''

									if @IDWGList is not null and @IDWGList <> ''''
										set @sql1 = @sql1 + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.IDWG) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@IDWGList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ '''''''' +
												'' and a.IDWG is not null and a.cal_id in('' + @callIdList +'')''
									else
										set @sql1 = @sql1 + '' a.IDWG is not null and a.cal_id in('' + @callIdList +'')''

									if @CampaingsList is not null and @CampaingsList <> ''''
										set @sql1 = @sql1 + '' and'' + '' ('' + ''''''''+'',''+'''''''' + ''+ RTRIM(a.cam_id) + '' +''''''''+'',''+''''''''+'')'' + '' LIKE'' + ''''''''+ ''%,'' +''''''''+ ''+'' + ''''''''+ cast(@CampaingsList as nvarchar) + ''''''''+ ''+'' + ''''''''+ ''%,''+ ''''''''

									if @DispositionList is not null and @DispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.calif_id in (''+@DispositionList+'')''

									if @SubdispositionList is not null and @SubdispositionList <> ''''
										set  @sql1 = @sql1 +'' and a.califSub_id in (''+@SubdispositionList+'')''

									set @sql1 = @sql1 + '' and a.tipo_llamada=2''
									print @sql1
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

				END



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
		EXEC (@sql)

	
		
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
