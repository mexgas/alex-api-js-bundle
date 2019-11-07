CREATE PROCEDURE [dbo].[trsp_GetListaBorrarSinRespaldo]
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