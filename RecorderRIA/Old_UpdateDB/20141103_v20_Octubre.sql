
/*
Fecha: 2014/05/12
Descripcion: 	

	Se modifica parametro de la publicacion  generation_leveling_threshold y actuliza migration migration datStart y dateEnd 		

	Se agrega cambio en stored trsp_GetListaBorrarSinRespaldo para evitar time out 
	Se agrega cambio en stored trsp_GetListaBorrarRespaldo para evitar time out
	Se agrega cambio en stored trsp_AdmRecSearchAllRecs para cambiar forma de consulta y aun moviendo registros todos los dias encuentre los registros. 
Version requerida: 19
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 20
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'Change Publication -- generation_leveling_threshold'
	set @Sql='if exists (select * from sysobjects where name=''sysmergepublications'' and type=''U'')  begin

		declare @i int, @count int
		declare @sql nvarchar(max),@name sysname
		CREATE TABLE #publicaction (id int,name sysname)

		INSERT INTO #publicaction (id,name)
		select ROW_NUMBER() OVER(ORDER BY name) AS Row,name from sysmergepublications where generation_leveling_threshold>0 and publisher_db=''CCenterRia''

		select @i=1,@count=count(*) from #publicaction

		while @i<=@count begin 
			select @name=name from #publicaction where id=@i
			set @sql=''exec sp_changemergepublication @publication = ''''''+ @name + '''''', @property = ''''generation_leveling_threshold'''', @value = 0''
			set @i=@i+1

			update migration set dateStart=''19000101'',dateEnd=''19000101'' where description=@name
			update migrationAVRS set dateStart=''19000101'',dateEnd=''19000101'' where description=@name
			exec(@sql)
		end

		drop table #publicaction
	end'				
	

	set @process = 'ALter stored - trsp_GetListaBorrarSinRespaldo'
	set @Sql='
		ALTER PROCEDURE [dbo].[trsp_GetListaBorrarSinRespaldo]
		@cwIntegrated AS INT,
		@cwIntegratedRIA AS INT
		AS
		BEGIN

			-- SET NOCOUNT ON added to prevent extra result sets from
			-- interfering with SELECT statements.
			SET NOCOUNT ON;
			DECLARE @maxBorrado INT
			DECLARE @datosTabla INT
			DECLARE @maxGrabId INT	
			declare @minGrabIDBackup int
			declare @maxGrabIDBackup int


		    -- Insert statements for procedure here
			SELECT @maxBorrado = MAX(grab_id) from trec_backups where status_audio = 4 or status_audio = 5;
			SELECT @datosTabla = COUNT(grab_id) from trec_backups where grab_id > @maxBorrado;
			SELECT @maxGrabId = MAX(grab_id) from trec_backups;
			IF @datosTabla < 10000
			   BEGIN
					IF @cwIntegratedRIA = 1
						BEGIN
							insert into TREC_BACKUPS (grab_id,status_audio)
							select grab_id,2 as status_audio from RIA_GRABACION where grab_id between @maxGrabId+1 and @maxGrabId+(10000-@datosTabla);
						END
					ELSE
						BEGIN
							insert into TREC_BACKUPS (grab_id,status_audio)
							select grab_id,2 as status_audio from TREC_GRABACION where grab_id between @maxGrabId+1 and @maxGrabId+(10000-@datosTabla);
						END		
			   END
			IF @cwIntegrated = 1
			    BEGIN
				--select top 10000 TREC_BACKUPS.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio, status_video from TREC_BACKUPS inner join
				--(select grab_id, cal_id, Tipo_Llamada from TREC_GRABACION union select grab_id, cal_id, Tipo_Llamada from TREC_GRABACIONCONSULTA)as GRABACIONES
				--on TREC_BACKUPS.grab_id = GRABACIONES.grab_id  where status_audio = 1 or status_audio = 2 order by grab_id asc;

				create table #tempGrabID (grab_id bigint not null primary Key, status_audio smallint null)
				insert into #tempGrabID
				select top 10000 grab_id,status_audio
				from TREC_BACKUPS with (index (IX_TREC_BACKUPS_1) , nolock)
				where status_audio = 1 or status_audio = 2 order by grab_id asc

				select @minGrabIDBackup =  min(grab_id) from #tempGrabID
				select @maxGrabIDBackup =  max(grab_id) from #tempGrabID

				create table #tempTREC_GRABACION (grab_id bigint not null primary Key,cal_id int null,Tipo_Llamada smallint null)

				insert into #tempTREC_GRABACION
				select grab_id, cal_id, Tipo_Llamada  
				from TREC_GRABACION  with (nolock)
				where grab_id between @minGrabIDBackup and @maxGrabIDBackup
				union
				select grab_id, cal_id, Tipo_Llamada  
				from TREC_GRABACIONCONSULTA  with (nolock)
				where grab_id between @minGrabIDBackup and @maxGrabIDBackup


				select A.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio  from #tempGrabID  as A left outer join #tempTREC_GRABACION as B
				on (A.grab_id=B.grab_id)

				drop table #tempGrabID
				drop table #tempTREC_GRABACION

			    END
			ELSE IF @cwIntegratedRIA = 1
				BEGIN
					--select top 10000 TREC_BACKUPS.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio, status_video from TREC_BACKUPS inner join
					--(select grab_id, cal_id, Tipo_Llamada from RIA_GRABACION union select grab_id, cal_id, Tipo_Llamada from RIA_GRABACIONCONSULTA)as GRABACIONES
					--on TREC_BACKUPS.grab_id = GRABACIONES.grab_id  where status_audio = 1 or status_audio = 2 order by grab_id asc;

					create table #tempGrabIDRIA (grab_id bigint not null primary Key, status_audio smallint null)
					insert into #tempGrabIDRIA
					select top 10000 grab_id,status_audio
					from TREC_BACKUPS with (index (IX_TREC_BACKUPS_1) , nolock)
					where status_audio = 1 or status_audio = 2 order by grab_id asc

					select @minGrabIDBackup =  min(grab_id) from #tempGrabIDRIA
					select @maxGrabIDBackup =  max(grab_id) from #tempGrabIDRIA

					create table #tempRIA_GRABACION (grab_id bigint not null primary Key,cal_id int null,Tipo_Llamada smallint null)

					insert into #tempRIA_GRABACION
					select grab_id, cal_id, Tipo_Llamada  
					from RIA_GRABACION  with (nolock)
					where grab_id between @minGrabIDBackup and @maxGrabIDBackup
					union
					select grab_id, cal_id, Tipo_Llamada  
					from RIA_GRABACIONCONSULTA  with (nolock)
					where grab_id between @minGrabIDBackup and @maxGrabIDBackup


					select A.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio  from #tempGrabIDRIA  as A left outer join #tempRIA_GRABACION as B
					on (A.grab_id=B.grab_id)

					drop table #tempGrabIDRIA
					drop table #tempRIA_GRABACION
				END
			ELSE
			    BEGIN
				select top 10000 grab_id, status_audio, status_video from trec_backups where status_audio = 1 or status_audio = 2 order by grab_id asc;
			    END
		END
	'
	EXEC(@Sql)


	set @process = 'ALter stored - trsp_GetListaBorrarRespaldo'
	set @Sql='
	ALTER PROCEDURE [dbo].[trsp_GetListaBorrarRespaldo]
	@cwIntegrated AS INT,
	@cwIntegratedAVRSRIA AS INT
	AS
	BEGIN
		declare @minGrabID  int
		declare @maxGrabID  int

	    IF @cwIntegrated = 1
		BEGIN
		    --select top 1000 TREC_BACKUPS.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio from TREC_BACKUPS with (index (IX_TREC_BACKUPS)) inner join 
			--(select grab_id, cal_id, Tipo_Llamada from TREC_GRABACION union select grab_id, cal_id, Tipo_Llamada from TREC_GRABACIONCONSULTA)as GRABACIONES
			--ON TREC_BACKUPS.grab_id = GRABACIONES.grab_id  where status_audio = 1 order by grab_id asc;

			create table #tempGrabID (grab_id bigint not null primary Key, status_audio smallint null)
			insert into #tempGrabID
			select top 10000 grab_id,status_audio
			from TREC_BACKUPS with (index (IX_TREC_BACKUPS_1) , nolock)
			where status_audio = 1 order by grab_id asc

			select @minGrabID =  min(grab_id) from #tempGrabID
			select @maxGrabID =  max(grab_id) from #tempGrabID

			create table #tempTREC_GRABACION (grab_id bigint not null primary Key,cal_id int null,Tipo_Llamada smallint null)

			insert into #tempTREC_GRABACION
			select grab_id, cal_id, Tipo_Llamada  
			from TREC_GRABACION  with (nolock)
			where grab_id between @minGrabID and @maxGrabID
			union
			select grab_id, cal_id, Tipo_Llamada  
			from TREC_GRABACIONCONSULTA  with (nolock)
			where grab_id between @minGrabID and @maxGrabID


			select A.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio  from #tempGrabID  as A left outer join #tempTREC_GRABACION as B
			on (A.grab_id=B.grab_id)

			drop table #tempGrabID
			drop table #tempTREC_GRABACION


		END
		ELSE IF @cwIntegratedAVRSRIA = 1
		BEGIN
			--select top 10000 TREC_BACKUPS.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio from TREC_BACKUPS with (index (IX_TREC_BACKUPS)) inner join 
			--(select grab_id, cal_id, Tipo_Llamada from RIA_GRABACION union select grab_id, cal_id, Tipo_Llamada from RIA_GRABACIONCONSULTA)as GRABACIONES
			--ON TREC_BACKUPS.grab_id = GRABACIONES.grab_id  where status_audio = 1 order by grab_id asc;

			create table #tempGrabIDRIA (grab_id bigint not null primary Key, status_audio smallint null)
			insert into #tempGrabIDRIA
			select top 10000 grab_id,status_audio
			from TREC_BACKUPS with (index (IX_TREC_BACKUPS_1) , nolock)
			where status_audio = 1 order by grab_id asc

			select @minGrabID =  min(grab_id) from #tempGrabIDRIA
			select @maxGrabID =  max(grab_id) from #tempGrabIDRIA

			create table #tempRIA_GRABACION (grab_id bigint not null primary Key,cal_id int null,Tipo_Llamada smallint null)

			insert into #tempRIA_GRABACION
			select grab_id, cal_id, Tipo_Llamada  
			from RIA_GRABACION  with (nolock)
			where grab_id between @minGrabID and @maxGrabID
			union
			select grab_id, cal_id, Tipo_Llamada  
			from RIA_GRABACIONCONSULTA  with (nolock)
			where grab_id between @minGrabID and @maxGrabID


			select A.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio  from #tempGrabIDRIA  as A left outer join #tempRIA_GRABACION as B
			on (A.grab_id=B.grab_id)

			drop table #tempGrabIDRIA
			drop table #tempRIA_GRABACION
		END
		ELSE
		BEGIN
		    select top 10000 grab_id, status_audio from trec_backups where status_audio = 1 order by grab_id asc
		END
	END
	'
	EXEC(@Sql)

	set @process = 'ALter stored - trsp_AdmRecSearchAllRecs'
	set @Sql='
	ALTER PROCEDURE [dbo].[trsp_AdmRecSearchAllRecs]

	@Sup_id int,
	@Finicio datetime,
	@Ffin datetime

	AS
	BEGIN

		
		SET NOCOUNT ON

		declare @sql1 nvarchar(max)
		declare @sql2 nvarchar(max)
		declare @sql3 nvarchar(max)

		select r.id_grabacion, avg(r.total_forma) as total_forma
		into #tempRiaFormaCalif from ria_formacalif r 
		inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t 
		on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
		group by r.id_grabacion		
		
		select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
		into #tempCampEspWG from ccRIACampEspWGConsulta a 
		inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG

		SELECT @sql1 = CASE WHEN EXISTS (
			select top 1 1 
			from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))		
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
			where a.finicio BETWEEN  @Finicio AND @Ffin
			) THEN ''select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
			finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
			isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
			isnull (z.total_forma,0) as total_forma,a.id_repositorio,
			CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
			CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
			a.grab_id as grabID, isnull(g.IDWG,0)as IDWG
			from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))		
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
			where a.finicio BETWEEN '''''' + cast(@Finicio as nvarchar) + '''''' AND '''''' + cast(@Ffin as nvarchar) + '''''''' ELSE '''' END

		select @sql2 = '' union ''

		SELECT @sql3 = CASE WHEN EXISTS (
			select top 1 1 
			from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3)) 		
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
			where a.finicio BETWEEN  @Finicio AND @Ffin
			) THEN ''select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
			finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
			isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
			isnull (z.total_forma,0) as total_forma,a.id_repositorio,
			CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
			CASE WHEN duracion / 3600 < 10 THEN ''''0'''' ELSE '''''''' END + RTRIM(a.duracion / 3600) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 / 60), 2) + '''':'''' + RIGHT(''''0'''' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
			a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
			from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3)) 		
			left join ccPosicion b on b.pos_id = a.cal_extension * -1
			left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
			left join ccTipoCalif AS f ON a.calif_id = f.calif_id
			left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
			left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
			inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
			where a.finicio BETWEEN '''''' + cast(@Finicio as nvarchar) + '''''' AND '''''' + cast(@Ffin as nvarchar) + '''''''' ELSE '''' END

			if (@sql1 <> '''' and @sql3 <> '''')
				exec (@sql1 + @sql2 + @sql3)
			else if (@sql1 <> '''' and @sql3 = '''')
				exec (@sql1)
			else if (@sql1 = '''' and @sql3 <> '''')
				exec (@sql3)
			else
				exec (@sql1)

			--if (@sql1 <> '''' and @sql3 <> '''')
			--	print (@sql1 + @sql2 + @sql3)
			--else if (@sql1 <> '''' and @sql3 = '''')
			--	print (@sql1)
			--else if (@sql1 = '''' and @sql3 <> '''')
			--	print (@sql3)
			--else
			--	print (@sql1)
						
		drop table #tempRiaFormaCalif
		drop table #tempCampEspWG	
		
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


