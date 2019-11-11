CREATE PROCEDURE [dbo].[trsp_GetListaBorrarRespaldo]
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