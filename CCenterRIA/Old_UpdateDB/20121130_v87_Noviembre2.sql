/*
Autor: Raymundo Gonzalez
Fecha: 2012/11/30
Descripcion: 	
	Se crea la tabla ccRIADispMonitorRel para guardar calificaciones monitoreadas
	Se crea el indice IX_ccCallsIn_6 para acelerar consulta al generar registros de marcación de campañas encuesta
	Se inserta registro en la tabla ccMenus con el numero 70 para Relacion de Campañas en Campañas para configuración con Encuesta
	Se modifica la tabla ccMenus en su menu 52 para Relación de Campañas en ACD
	Se modifica la tabla ccCamps para agregar las columnas surveyCamId, callsBySurvey e ivrScript 
	Se modifica la tabla ccCamps_Consulta para agregar la columna surveyCamId
	Se modifica trigger tg_ccCamps_Consulta para pasar la columna surveyCamId al eliminar el registro de ccCamps
	Se crea el SP ccsp_RIADispMonitor para guardar calificaciones monitoreadas
	Se modifica el SP ccsp_RIAScheduleEsp que devuelve si una campaña es de encuesta
	Se modifica el SP ccsp_RIA_ABCCamps para crear relación con campaña de encuesta
	Se modifica el SP ccsp_RIAConfCamp para agregar campos de callsBySurvey e ivrScript en la configuracion de campañas
	Se modifica el SP ccsp_RIAUpdateCamConfig que agrega campos de callsBySurvey e ivrScript para configurar campañas encuesta
	Se modifica el SP ccsp_AgentSetCallStatus para insertar registro de marcación encuesta para llamadas de Out e In al pasar por el estado de dialogo
	Se modifica el SP ccsp_RIAOUTInsertNewJOBS_WT_Camp para subir registros de pendientes a nuevos en campañas de encuesta
	Se modifica el SP ccsp_OUTGetNewJobs para validar que la campaña encuesta tenga necesariamente horarios para iniciar marcación
	Se modifica el SP ccsp_OUTGetNewProviderJobs para validar que la campaña encuesta tenga necesariamente horarios para iniciar marcación
	Se actualiza el Job NuxibaMaintenancePlan
	Cambios en lista negra
Version requerida: 86
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '87'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @Sql='CREATE TABLE dbo.ccRIADispMonitorRel
	(
	relId int NOT NULL IDENTITY (1, 1),
	userId smallint NOT NULL,
	dispositionId smallint NOT NULL,
	type bit NOT NULL
	)  ON [PRIMARY]'
	
	EXEC(@Sql)

		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccCallsIn_6] ON [dbo].[ccCallsIn] 
(
	[cal_id] ASC,
	[statusCall_id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

		set @Sql='insert into ccmenus
values (70, ''Relación de Campañas|Campaign Relation'', 20, ''B'', 28, 1, '''')'
	
	EXEC(@Sql)

		set @Sql='update ccmenus
set menu_descrip = ''Relación de Campañas|Campaign Relation''
where menu_id = 52'
	
	EXEC(@Sql)

		set @Sql='ALTER TABLE dbo.ccRIADispMonitorRel ADD CONSTRAINT
	PK_ccRIADispMonitorRel PRIMARY KEY CLUSTERED 
	(
	relId
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
	
	EXEC(@Sql)

		set @Sql='ALTER TABLE dbo.ccCamps 
ADD surveyCamId int default 0'
	
	EXEC(@Sql)

		set @Sql='alter table ccCamps
add callsBySurvey int not null default 0'
	
	EXEC(@Sql)

		set @Sql='alter table ccCamps
add ivrScript int not null default 0'

	EXEC(@Sql)

		set @Sql='ALTER TABLE dbo.ccCamps_Consulta
ADD surveyCamId int default 0'
	
	EXEC(@Sql)

		set @sql='ALTER TRIGGER [dbo].[tg_ccCamps_Consulta] ON [dbo].[ccCamps]
after delete
as begin
set nocount on
insert into ccCamps_Consulta (cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, 
cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, 
cam_inter_ocupado, cam_inter_nocontesto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, 
cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql ,cam_tnotas, 
cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_tDialBeforeWU, 
cam_tDialBeforeReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, 
cam_fCreate, cam_MaxDlrXage, ani, IDArea, EditableCallKey, iTipoDial, detectAnswerMachine, 
detectVoiceMail, compliance, surveyCamId)
select cam_id, cli_id, cam_descripcion, cam_activo, cam_ModoManual, cam_modpredictivo, cam_TipoJobs, 
cam_tNoContesta, cam_SortColumns, cam_ocupado, cam_nocontesto, cam_graba, cam_fax, cam_callratio, 
cam_inter_ocupado, cam_inter_nocontesto, cam_inter_graba, cam_inter_fax, cam_NoInt_ocupado, 
cam_NoInt_nocontesto, cam_NoInt_graba, cam_NoInt_fax, cam_procesando, cam_dsn, cam_sql ,cam_tnotas, 
cam_tDialAfterWU, cam_tDialAfterDLG, cam_fDialOnWU, cam_fDialOnDLG, cam_tDialBeforeWU, 
cam_tDialBeforeReady, cam_bValidaTel, cam_bNew, cam_ShowCalifWnd, cam_StartTimerOnHangUp, 
cam_fCreate, cam_MaxDlrXage, ani, IDArea, EditableCallKey, iTipoDial, detectAnswerMachine, 
detectVoiceMail, compliance, surveyCamId
from deleted
set nocount off
end'
	
	EXEC(@Sql)

		set @Sql='CREATE PROCEDURE [dbo].[ccsp_RIADispMonitor]
@action tinyint = 0,
@userId smallint = 0,
@dispositionsIn varchar(40) = '''',
@dispositionsOUT varchar(40) = ''''
as
begin
	if @action = 1 begin			
		delete from ccRIADispMonitorRel where userId = @userId

		if @dispositionsIn <> '''' and left(@dispositionsIn,1) <> '','' begin
			insert into ccRIADispMonitorRel select @userId,value,0 from dbo.fn_RIASplitDelimited( left(@dispositionsIn,len(@dispositionsIn)-1) ,'','')
		end

		if @dispositionsOUT <> '''' and left(@dispositionsOUT,1) <> '','' begin
			insert into ccRIADispMonitorRel select @userId,value,1 from dbo.fn_RIASplitDelimited( left(@dispositionsOUT,len(@dispositionsOUT)-1),'','')
		end

		select 1
	end

	if @action = 2 begin
		select relId, userId, dispositionId,type from ccRIADispMonitorRel where userId = @userId order by relId desc		
	end
end'
	
	EXEC(@Sql)

		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAScheduleEsp]
@Type smallint,
@Type2 smallint,
@IDArea smallint=0,
@CamEspID smallint,
@User_id smallint,
@InOut_Id smallint,
@InsertSchedule_id varchar(1000),
@DeleteSchedule_id varchar(1000)
AS
set nocount on

If @Type=1--get camps
 begin
	SELECT a1.cam_id, a1.cam_descripcion, a3.frame,CASE a1.CallsBySurvey WHEN 0 THEN 0 ELSE 1 END as ''CallsBySurvey''  FROM ccCamps a1
	inner join ccRIACampsGraph a2 on(a1.cam_id=a2.cam_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where isnull(IDArea, -1) = case 
	when @IDArea = 0 then -1
	when (select login from ccusers where user_id = @User_id) = ''root'' then isnull(IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

If @Type=2--get ACDGroups
 begin
	SELECT a1.Inbound_id, descripcion, a2.graphic_id, a3.frame from ccInbound a1
	inner join ccRIAInboundGraph a2 on(a1.Inbound_id=a2.Inbound_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where isnull(a1.IDArea, -1) = case when @IDArea=0 then -1
	when (select login from ccusers where user_id = @User_id) = ''root'' then isnull(a1.IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

IF @Type=3--query
 begin
	If(@Type2=0)--ACDGroup
	 begin
		select c.inbound_id, c.descripcion as c_descripcion, ih.horario_id, h.descripcion as h_descripcion,
		cast(lunes as int)as lunes, cast(martes as int)as martes, cast(miercoles as int)as miercoles, cast(jueves as int)as jueves, cast(viernes as int)as viernes, cast(sabado as int)as sabado, cast(domingo as int)as domingo,
		dbo.RIAtimeFormat(horainicio)as horaInicio, dbo.RIAtimeFormat(mininicio)as minInicio, dbo.RIAtimeFormat(horafin)as horaFin, dbo.RIAtimeFormat(minfin)as minFin
		from ccInbound c left join ccInboundHorarios ih on c.inbound_id=ih.inbound_id
		inner join ccHorarios h on ih.horario_id=h.horario_id where status=1
		and c.inbound_id=@CamEspID--in(select cam_id from ccSupervisorCam where tipo=0 and user_id=@User_id and cam_id=@CamEspID)
		ORDER BY 4
		return(0)
	 end

	If(@Type2=1)--Camp
	 begin
	  	select c.cam_id, c.cam_descripcion as c_descripcion, ch.horario_id, h.descripcion as h_descripcion,
	 	cast(lunes as int)as lunes, cast(martes as int)as martes, cast(miercoles as int)as miercoles, cast(jueves as int)as jueves, cast(viernes as int)as viernes, cast(sabado as int)as sabado, cast(domingo as int)as domingo,
	 	dbo.RIAtimeFormat(horainicio)as horaInicio, dbo.RIAtimeFormat(mininicio)as minInicio, dbo.RIAtimeFormat(horafin)as horaFin, dbo.RIAtimeFormat(minfin)as minFin
	 	from ccCamps c left join ccCampsHorarios ch on c.cam_id=Ch.cam_id
	 	inner join ccHorarios h on ch.horario_id=h.horario_id
	 	where c.cam_id=@CamEspID--in(select cam_id from ccSupervisorCam where tipo=0 and user_id=@User_id and cam_id=@CamEspID)
		ORDER BY 4
		return(0)
	 end
 end

If @Type=4
 begin
	if exists(select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id)
	and (select login from ccUsers where user_id=@User_id)<>''root''
		select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	else
		select * from ccRIACAT_Areas where StatusArea=1 order by AreaName
	return(0)
 end

declare @sql as nvarchar(1000), @nIDArea as varchar(10)

if @Type=5--Insert Schedules
 begin
	If @Type2=3
	 begin
		If exists(select inbound_id from ccInboundHorarios where inbound_id=@CamEspID and horario_id=@InsertSchedule_id)
			select 2
		else
			insert ccInboundHorarios(inbound_id, horario_id) select @CamEspID, @InsertSchedule_id
		return(0)
	 end

	If @Type2=2
	 begin
		If exists(select cam_id from ccCampsHorarios where cam_id=@CamEspID and horario_id=@InsertSchedule_id)
			select 2
		else
			insert ccCampsHorarios(cam_id, horario_id) select top 1 @CamEspID, @InsertSchedule_id
		return(0)
	 end

	If @Type2<>1
		return(0)

	If @InOut_Id=0--ACD
	 begin
		If @IDArea=0
		 begin
			set @sql=''insert ccInboundHorarios
			select distinct a.inbound_id, b.horario_id from ccInbound a, ccHorarios b where
			b.horario_id in(''+@InsertSchedule_id+'')
			and not exists(select c.inbound_id, e.horario_id from ccInboundHorarios c
			join ccHorarios e on e.horario_id=c.horario_id
			join ccInbound d on d.inbound_id=c.inbound_id and IDArea is null
			where c.inbound_id=a.inbound_id and b.horario_id=e.horario_id)
			and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea is null)''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''insert ccInboundHorarios select distinct a.inbound_id, b.horario_id 
		from ccInbound a, ccHorarios b where b.horario_id in(''+@InsertSchedule_id+'')
		and not exists(select c.inbound_id, e.horario_id from ccInboundHorarios c
		join ccHorarios e on e.horario_id=c.horario_id
		join ccInbound d on d.inbound_id=c.inbound_id and IDArea=''+@nIDArea+
		'' where c.inbound_id=a.inbound_id and b.horario_id=e.horario_id)
		and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea=''+@nIDArea+'')''
		execute sp_executesql @sql
		return(0)
	 end

	If @InOut_Id=1--Camp
	 begin
		If @IDArea=0
		 begin
			set @sql=''insert ccCampsHorarios
			select distinct a.cam_id, b.horario_id from ccCamps a, ccHorarios b where
			b.horario_id in(''+@InsertSchedule_id+'')
			and not exists(select c.cam_id, e.horario_id from ccCampsHorarios c
			join ccHorarios e on e.horario_id=c.horario_id
			join ccCamps d on d.cam_id=c.cam_id and IDArea is null
			where c.cam_id=a.cam_id and b.horario_id=e.horario_id)
			and a.cam_id in(select x.cam_id from ccCamps x where IDArea is null)''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''insert ccCampsHorarios select distinct a.cam_id, b.horario_id
		from ccCamps a, ccHorarios b where b.horario_id in(''+@InsertSchedule_id+'')
		and not exists(select c.cam_id, e.horario_id from ccCampsHorarios c
		join ccHorarios e on e.horario_id=c.horario_id
		join ccCamps d on d.cam_id=c.cam_id and IDArea=''+@nIDArea+
		'' where c.cam_id=a.cam_id and b.horario_id=e.horario_id)
		and a.cam_id in(select x.cam_id from ccCamps x where IDArea=''+@nIDArea+'')''
		execute sp_executesql @sql
		return(0)
	 end
 end

If @Type=6--Delete Schedules
 begin
	If @Type2=3
	 begin
		delete ccInboundHorarios where inbound_id=@CamEspID	and horario_id=@DeleteSchedule_id
		return(0)
	 end

	If @Type2=2
	 begin
		delete ccCampsHorarios where cam_id=@CamEspID and horario_id=@DeleteSchedule_id
		return(0)
	 end

	If @Type2<>1
		return(0)

	If @InOut_Id=0--ACD
	 begin
		If @IDArea=0
		 begin
			set @sql=''delete ccInboundHorarios where inbound_id in(select inbound_id from 
			ccInbound where IDArea is null) and Horario_id in(''+@DeleteSchedule_id+'')''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''delete ccInboundHorarios where inbound_id in(select inbound_id from 
		ccInbound where IDArea=''+@nIDArea+'') and Horario_id in(''+@DeleteSchedule_id+'')''
		execute sp_executesql @sql
		return(0)
	 end

	If @InOut_Id=1--Camp
	 begin
		If @IDArea=0
		 begin
			set @sql=''delete ccCampsHorarios
			where cam_id in(select cam_id from ccCamps where IDArea is null)
			and Horario_id in(''+@DeleteSchedule_id+'')''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''delete ccCampsHorarios
		where cam_id in(select cam_id from ccCamps where IDArea=''+@nIDArea+'')
		and Horario_id in(''+@DeleteSchedule_id+'')''
		execute sp_executesql @sql
		return(0)
	 end
 end

return(0)
set nocount off'
	
	EXEC(@Sql)

		set @Sql='ALTER PROCedure [dbo].[ccsp_RIA_ABCCamps]
@option smallint,
@UserId int,
@Descripcion varchar(40),
@Cam_id varchar(1000),
@Activa tinyint,
@IDArea smallint = null,
@frame tinyint, 
@MirrorInbound_Id smallint = null
as
set nocount on

if @option = 0
 begin
	 select cam_id,ISNULL(cam_descripcion,'''') as cam_descripcion
	  ,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
	 from ccCamps as CAMP with(nolock)
	 left join ccRIACat_Areas as AREas with(nolock)
	 on CAMP.IDArea = AREas.IDArea
	 return(0)
 end

if @option = 1 -- select Camp
 begin
	 select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,
	  cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0)
	 from ccCamps a1
	  inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
	  inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
	 where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
	 return(0)
 end

if @option = 4 --Delete
 begin
 	 if exists (select inbound_id from ccInbound where cam_id = @Cam_id)
	  begin
		declare @error varchar(70)
		Select @error=case valor when 0 then ''No es posible eliminar la campaña, esta asociada a una especialidad'' 
		 else ''Campaign can not be deleted, it has an association with an ACD'' end
		from ccsettings where setting_id = 27
		raiserror (@error,18,1)		
		return(0)
	  end

	 delete ccCampsHorarios where cam_id = @Cam_id
	 insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id)
	  Values(@Cam_id, 5, 0, 0, @UserId)
	 Delete ccCalifCamp where cam_id = @Cam_id and tipo = 1
	 Delete ccRIACampsGraph where cam_id = @Cam_id
	 delete ccHistorialListaNegra where cam_id = @Cam_id

	-- Se inicia proceso de scheduler service para pasar informacion de ccocallsout antes de eliminarla
	 declare @server varchar(200), @sql varchar(8000), @from datetime, @to datetime
select @server=valor from ccsettings where setting_id=22

set @from=convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '':00'',121)
set @to=convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '':00'',121)

set @sql=''declare @calIni as varchar(15), @calfin as varchar(15)
select @calIni=isnull(max(cal_id),1) from '' + @server + ''.dbo.ccocallsout WITH(NOLOCK) where cam_id = @Cam_id
select @calfin=max(cal_id) from ccocallsout with(index (IX_ccoCallsOut_2),NOLOCK) where cam_id = @Cam_id''

set @sql = @sql + ''
insert into '' + @server + ''.dbo.ccocallsout (cal_id,callout_id, cal_telefono,cal_puerto,cam_id,user_id,cal_extension,cal_colgada,cal_key,
statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,
cal_tlinebusy,costo,provedor_id,tipollamada_id,cal_tMoh)
select cal_id,callout_id, cal_telefono,cal_puerto,cam_id,user_id,cal_extension,cal_colgada,cal_key,
statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,
cal_tlinebusy,costo,provedor_id,tipollamada_id,cal_tMoh from ccocallsout WITH(NOLOCK) WHERE cal_id>@calIni and cal_id<=@calfin 
and cam_id=''+cast(@Cam_id as varchar(10))+''''
exec(@sql)

	 delete ccoCallsOut where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @Cam_id)
	 delete ccoCallsOutSource where cam_id = @Cam_id
	 Delete ccCamps where cam_id = @Cam_id
	 return(0)
 end

if @option = 2 --Insert
 begin
	declare @new_cam_id smallint

	if exists(select cam_descripcion from ccCamps where cam_descripcion = @Descripcion)
	 begin
		select -1 --, ''Nombre en Uso''
		return(0)  
	 end

	-- ODC: la campaña siempre esta activa
	set @Activa = 1

	Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd)
	select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
	case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end

	if @@rowcount = 1
	select @new_cam_id = scope_identity()

	else
	 begin
		select -2 --, ''Error al crear campaña''
		return(0)
	 end

	if isnull(@MirrorInbound_Id, 0)<>0
	 begin
		if not exists(select inbound_id from ccInbound where inbound_id=@MirrorInbound_Id)
		 begin
			select -3 -- Error al asignar campaña a ACD, el ACD no existe o no pertenece a la misma area
			return(0)
		 end

		update ccinbound set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
		update cccamps set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
	 end

	insert into ccoDialerCamp (dialer_id, cam_id)
	select dialer_id, @new_cam_id from ccoDialers where status = 1

	insert into ccCalifCamp (calif_id, cam_id, tipo) select calif_id, @new_cam_id, 1 from ccTipoCalifOUT where CalifOut_Status = 1

	If not exists (select frame from ccRIAGraphics where frame = @frame and type_id = 1)
	 begin
		insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
	 end

	insert into ccRIACampsGraph (cam_id, graphic_id)
	select @new_cam_id, graphic_id from ccRIAGraphics where frame = @frame and type_id = 1

	select @new_cam_id
	return(0)
 end

if @option = 3 -- Update
 begin
	 if not exists(select frame from ccRIAGraphics where frame = @frame and type_id = 1)
	  insert into ccRIAGraphics (frame,type_id) values (@frame,1)

	 Update ccCamps set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

	 update ccRIACampsGraph
	  set graphic_id = (select graphic_id from ccRIAGraphics where frame = @frame and type_id = 1)
	  where cam_id = @Cam_id

	 return(0)
 end

 if @option = 5 --Obtener relaciones de campañas - campañas
   begin
      if not exists (select cam_id from ccCamps where cam_id = @Cam_id) or
	 (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
		not exists (select cam_id from ccCamps where cam_id=@descripcion))
	 begin
		select -3 -- Campaña invalida
		return(0)
	 end
	
	if @descripcion=0
		set @descripcion = null

	update ccCamps set surveyCamId = @descripcion where cam_id = @Cam_id
	if @@rowcount=0
		select -4 -- Error al actualizar
		
	else
	 begin
		delete cccalifcamp where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	 end

	return(0)
   end

if @option = 6
	begin
		select cam_id, isnull(surveycamid,0)
		from cccamps with(nolock)
		where cam_id = @Cam_id
		return(0)
	end

return(0)
set nocount off'
	
	EXEC(@Sql)

		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
@User_id smallint 
AS 
set nocount on
	select a1.cam_id, cam_Descripcion
	 , cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
	 , cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
	 , cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
	 , detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
	 , cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
	 , stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, cam_maxqueue as queSize,
	 DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript 
	 from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id) 
	 where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
	 order by cam_descripcion
	return(0)
 set nocount off'
	
	EXEC(@Sql)

		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
@cam_id smallint,
@cam_descripcion varchar(40) = null,
@cam_tnotas smallint = null,
@cam_ocupado tinyint = null,
@cam_NoInt_ocupado tinyint = null,
@cam_inter_ocupado smallint = null,
@cam_nocontesto tinyint = null,
@cam_NoInt_nocontesto tinyint = null,
@cam_inter_nocontesto smallint = null,
@cam_fax tinyint = null,
@cam_NoInt_fax tinyint = null,
@cam_inter_fax smallint = null,
@cam_ModoManual tinyint= null,
@ANI varchar(15) = null,
@cam_ShowCalifWnd bit = null,
@cam_StartTimerOnHangUp bit = null,
@editableCallKey bit = null, 
@cam_tNoContesta tinyint = null,
@cam_intensive_dialing tinyint = null, 
@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
@compliance TinyInt = null, 
@cam_inter_graba smallint = null,
@cam_NoInt_graba tinyint = null,
@progDial smallint = null,
@excCallBack Tinyint = null,
@dialOrder Tinyint = null,
@dialPrefix varchar(10) = null,
@dialPrefixMan varchar(10) = null,
@dialPrefixXfe varchar(10) = null,
@listenManualCall bit = null,
@stopRecording bit = null,
@abandonCallback bit = null,
@autoCB smallint = null,
@id_listAni int = null,
@tDialonWrapUp smallint = null,
@quesize smallint=null,
@DNCScrub int=null,
@callerIdDesc varchar(15)=null,
@timeZoneRule int=null,
@callsBySurvey int=null,
@ivrScript int=null
as
set nocount on
UPDATE ccCamps SET 
 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
 cam_fax = isnull(@cam_fax,cam_fax),
 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
 ANI = isnull(@ANI,ANI),
 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
 editableCallKey = isnull(@editableCallKey, editableCallKey),
 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial), 
 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine), 
 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
 compliance = isnull(@compliance, compliance),
 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
 progDial = isnull(@progDial, progDial),
 excCallBack = isnull(@excCallBack,excCallBack),
 dialOrder = isnull(@dialOrder, dialOrder),
 dialPrefix = isnull(@dialPrefix, dialPrefix),
 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
 listenManualCall = isnull(@listenManualCall, listenManualCall),
 stopRecording = isnull(@stopRecording, stopRecording),
 abandonCallback = isnull(@abandonCallback, abandonCallback),
 t_autoCB = isnull(@autoCB,t_autoCB),
 id_anilist = isnull(@id_listAni,id_anilist),
 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
 cam_maxqueue = isnull(@quesize,cam_maxqueue),
 DNCScrub = isnull(@DNCScrub,DNCScrub),
 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
 ivrScript = isnull(@ivrScript,ivrScript)
Where cam_id = @cam_id 

if @cam_ShowCalifWnd = 1
 begin
	If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
	 begin
		select 0
		return(0)
	 end
	 
	UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
	where cam_id = @cam_id
	select 1
	return(0)
  end

--else
UPDATE ccCamps SET 
cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
where cam_id = @cam_id
return(0)
set nocount off'
	
	EXEC(@Sql)

		set @Sql='ALTER procedure [dbo].[ccsp_AgentSetCallStatus]
@callout_id int,
@cal_id int,
@TipoCall tinyint,	-- 1= IN,  2=Out
@TipoMov tinyint,	-- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
@cal_tXfer tinyint=0,
@cal_tring  smallint=0,
@user_id smallint=0,
@extension varchar(5)=''''
AS
set nocount on

declare @RecicleSIC tinyint
SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id=60
Declare @ANI_x varchar(19)
declare @cal_inicio datetime
declare @callout_id_IN int
declare @cal_key varchar(20)
declare @cam_id int
declare @cal_telefono varchar(30)
declare @surveycamid int
declare @inbound_id int

if @TipoMov=4 or @TipoMov=14 -- DIALOG OnDialog
 begin
	if @TipoCall=2
	 begin
		if @TipoMov = 4
			Update ccoCallsOUT with(rowlock) Set statusCall_id=13 Where cal_id=@cal_id
		else if @TipoMov = 14
			Update ccoCallsOUT with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

		if @RecicleSIC=0
			DELETE ccoWorkingTable with(rowlock) WHERE callout_id=@callout_id

		update ccoCallBacks
		set [status] = 1, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 13

		-- calcula el costo de la llamada
		exec ccsp_CstoCalculaCosto @cal_id

		select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono
		from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
		where callout_id = @callout_id
		and statusCall_id = 13
		and cal_id = @cal_id

		select @surveycamid = isnull(surveycamid,0) from cccamps where cam_id = @cam_id

		if @surveycamid > 0
			begin
				insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status) 
				values( @cal_Key,@surveycamid,@cal_telefono,0)
			end

		return(0)
	end

	if @TipoMov = 4
		Update ccCallsIN with(rowlock) Set statusCall_id=13 Where cal_id=@cal_id
	else if @TipoMov = 14
		Update ccCallsIN with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

	-- Elimina callback generado por abandono
	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x
	
	update ccoCallBacks with(rowlock)
	set [status] = 1, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	DELETE ccoWorkingTable with(rowlock) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon WHERE cal_ANI=@ANI_x

	select @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani
	from ccCallsIN with(index(IX_ccCallsIn_6),nolock)
	where cal_id = @cal_id
	and statusCall_id = 13

	select @surveycamid = isnull(cam_id,0) from ccinbound where inbound_id = @inbound_id

	if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
		begin
			insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status) 
			values( @cal_Key,@surveycamid,@cal_telefono,0)
		end

	return(0)
 end

if @TipoMov=7 --OTHER OFFHook_OnXfer
 begin
	if @cal_id<=0
		return(0)

	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 16

		exec ccsp_CstoCalculaCosto @cal_id
		return(0)
	 end

	Update ccCallsIN with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock) 
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

if  @TipoMov=9 --RING CallNoAnswered
 begin
	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 15

		exec ccsp_CstoCalculaCosto @cal_id
	 end
	
	Update ccCallsIN with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock) 
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

set nocount off'
	
	EXEC(@Sql)

		set @sql='ALTER procedure [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp]
@camp_id as int,
@reciclar as int = 1
as
set nocount on

declare @prioridad varchar(8)
declare @camSurvey int
select @camSurvey = 0

select @camSurvey = cam_id
from cccamps 
where cam_id = @camp_id 
and isnull(callsBySurvey,0) > 0 
and isnull(ivrScript,0) > 0

Delete ccUploadTemporal with(rowlock)
where cam_id = @camp_id

update ccoCallBacks with(rowlock)
set [status] = 6, schedulerStatus = 1
where callout_id in (select cs.callout_id
from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_11),nolock) 
inner join ccoWorkingTable wt with(index(IX_ccoWorkingTable),nolock)
on cs.cal_key = wt.cal_keyw and cs.cam_id = wt.cam_id 
where cs.cam_id = @camp_id
and wt.cal_status <= 2
and cs.cal_status in(0,7))

if @camSurvey = 0
	update ccoCallsOutSource
	set cal_Status = 4 
	from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_11),nolock)
	inner join ccoWorkingTable wt with(index(IX_ccoWorkingTable),nolock)
	on cs.cal_key = wt.cal_keyw and cs.cam_id = wt.cam_id 
	where cs.cam_id = @camp_id
	and wt.cal_status <= 2
	and cs.cal_status in(0,7)

update ccoCallBacks with(rowlock)
set [status] = 6, schedulerStatus = 1
where callout_id in (select Cout.callout_id
from ccoCallsOutSource Cout with(index(IX_ccoCallsOutSource_11),nolock)
JOIN ccoworkingtable Wtab
ON Cout.callout_id = Wtab.callout_id 
WHERE Cout.cam_id = @camp_id 
and (COUT.cal_status < 2 or COUT.cal_status = 7))

if @camSurvey = 0
	update ccoCallsOutSource
	set cal_Status = 4 
	from ccoCallsOutSource Cout with(index(IX_ccoCallsOutSource_11),nolock)
	JOIN ccoworkingtable Wtab
	ON Cout.callout_id = Wtab.callout_id 
	WHERE Cout.cam_id = @camp_id 
	and (COUT.cal_status < 2 or COUT.cal_status = 7)

Insert ccoWorkingTable (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2,
	iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
SELECT callout_id, cam_id, 
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono,
case cal_status when 7 then 1 else cal_status end, cal_fechaDial, cal_key, 
case when len( cal_telefono ) > 0 then iZonaHoraria else null end, case when len( cal_telefono ) > 0 then iZonaHoraria_verano else null end, 
case when len( cal_telefono2 ) > 0 then iZonaHoraria2 else null end, case when len( cal_telefono2 ) > 0 then iZonaHoraria_verano2 else null end, 
case when len( cal_telefono3 ) > 0 then iZonaHoraria3 else null end, case when len( cal_telefono3 ) > 0 then iZonaHoraria_verano3 else null end, 
case when len( cal_telefono4 ) > 0 then iZonaHoraria4 else null end, case when len( cal_telefono4 ) > 0 then iZonaHoraria_verano4 else null end, 
case when len( cal_telefono5 ) > 0 then iZonaHoraria5 else null end, case when len( cal_telefono5 ) > 0 then iZonaHoraria_verano5 else null end,
list_id
FROM ccoCallsOutSource with(index(IX_ccoCallsOutSource_11),nolock)
WHERE cam_id = @camp_id 
and (cal_status < 2 or cal_status = 7) -- Nuevos Jobs

Insert into ccoCallBacks
SELECT callout_id, user_id, cam_id, cal_key,
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono1,
rtrim(left(ltrim(cal_telefono + ''        ''
		 + cal_telefono2 + ''         ''
		 + cal_telefono3 + ''         ''
		 + cal_telefono4 + ''         ''
		 + cal_telefono5 + ''         ''),13)) as cal_telefono2,cal_fechaDial,cal_fechaDial,NULL,0,1
FROM ccoCallsOutSource with(index(IX_ccoCallsOutSource_11),nolock)
WHERE cam_id = @camp_id 
and (cal_status < 2 or cal_status = 7) -- Nuevos Jobs

select @prioridad = isnull(Prioridad,''12345NNN'') from ccCampsPrioridadTel where cam_id = @camp_id

UPDATE ccoCallsOutSource with(rowlock)
SET cal_status = 2, dial_tels = @prioridad, nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) 
and cam_id = @camp_id

set nocount off'

	EXEC(@Sql)

		set @sql='ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID as int,
@test as int=0,
@nAgentsLogin as int=1
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @Sql varchar(4000), @Order_Asc_Desc char(4)
declare @camSurvey int
select @camSurvey = 0

select @camSurvey = cam_id
from cccamps 
where cam_id = @CAMPID 
and isnull(callsBySurvey,0) > 0 
and isnull(ivrScript,0) > 0
 
-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')
 
SET DATEFIRST 1
--Checamos si es horario de verano
       select @bIsDaylight=case when getdate()between inicio and fin then 1 else 0 end
       from ccHorarioVerano where year(getdate())=year(inicio) and country_id = @country_id
 
select @bIsDaylight=isnull(@bIsDaylight,1)
 
--Checamos si la campaña tiene horarios configurados
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
begin
       declare @horaUniversal as datetime
       set @horaUniversal=getutcdate()
 
       select @iZonas=sum(distinct tz_id)from
       (select tz_id,
             datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora,
             datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
             datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
             from ccTimeZones
       )zonas inner join cchorarios on
       ((hora>HoraInicio OR(hora=HoraInicio AND minuto>= MinInicio))
             AND (hora<HoraFin OR(hora=HoraFin AND minuto<= MinFin))
             AND (
                    Lunes=dia or
                    Martes*2=dia or
                    Miercoles*3=dia or
                    Jueves*4=dia or
                    Viernes*5=dia or
                    Sabado*6=dia or
                    domingo*7=dia
              )
       ) inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id=ccCampsHorarios.horario_id and ccCampsHorarios.cam_id=@campid
 
       if @iZonas is null begin
             SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
             return
       end
end
 
else
begin
	   if @camSurvey > 0
			begin
				SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
				return
			end

       if @revHorario=0
             select @iZonas=sum(distinct tz_id)from ccTimeZones -- No hay horarios, ponemos todas las zonas
       else
             select @iZonas=Null
end
 
set @Sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
cal_status tinyint,
cal_fechaDial datetime,
user_id int,
 tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint
)''
 
-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94
 
if isnull(@topCount,0)=0
select @topCount=case when @nAgentsLogin<3 then 30
  when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
  when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
  when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
  when @nAgentsLogin>=16 then 240 else 20 end
 
select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
	   select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )
 
	   select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
	   SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
	   W.list_id, isNull(R.sequence,0) as sequence
	   FROM ccoWorkingTable W left join ccRIARegistryLists R on W.list_id = R.list_id
	   WHERE cal_status=1 -- CallBacks
	   and cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
	   and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
	   and (
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	   )
	   and isnull(R.status,2) = 2
	   order by prioridad_cb desc, cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
 
end -- TOMA EN CUENTA LOS CALLBACKS
 
if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
	   select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )
 
	   select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
	   SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4,
	   izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
	   W.list_id, isNull(R.sequence,0) as sequence
	   FROM ccoWorkingTable W left join ccRIARegistryLists R on W.list_id = R.list_id
	   WHERE cal_status=0 -- Nuevas sin Tiempo
	   and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
	   and (
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	   ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	   )
	   and isnull(R.status,2) = 2
	   order by R.sequence, cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''
      
end -- TOMA EN CUENTA LAS NUEVAS
 
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @Sql=@Sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
 begin
	   select @Sql=@Sql+nchar(13)+ ''UPDATE ccoWorkingTable SET cal_status=2 --CALLBACK IN PROGRESS
	   WHERE callout_id in(select callout_id from #NEW_JOBS)''
end

if @Test = 2
begin
	select @Sql=@Sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
	declare @nSQL nvarchar(4000)
	set @nSQL=cast(@Sql as nvarchar(4000))
	exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
	return(@total)
end
else
begin
 
select @Sql=@Sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0''
end
 
select @Sql=@Sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print @Sql
exec(@Sql)
return(0)'
		
	EXEC(@Sql)

		set @sql='ALTER procedure [dbo].[ccsp_OUTGetNewProviderJobs]
@CAMPID as int, 
@test as int=0,
@nAgentsLogin as int=1
as
set nocount on
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @Sql varchar(MAX), @Order_Asc_Desc char(4)
declare @camSurvey int
select @camSurvey = 0

select @camSurvey = cam_id
from cccamps 
where cam_id = @CAMPID 
and isnull(callsBySurvey,0) > 0 
and isnull(ivrScript,0) > 0

-- VALIDAMOS EL PAIS Y LADA CONFIGURADA --
SELECT @country_id =valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano 
	select @bIsDaylight=case when getdate()between inicio and fin then 1 else 0 end
	from ccHorarioVerano where year(getdate())=year(inicio) and country_id = @country_id

select @bIsDaylight=isnull(@bIsDaylight,1)

--Checamos si la campaña tiene horarios configurados
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
 begin
	declare @horaUniversal as datetime 
	set @horaUniversal=getutcdate()

	select @iZonas=sum(distinct tz_id)from 
	(select tz_id,
		datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora, 
		datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
		datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
		from ccTimeZones 
	)zonas inner join cchorarios on
	((hora>HoraInicio OR(hora=HoraInicio AND minuto>= MinInicio))
		AND (hora<HoraFin OR(hora=HoraFin AND minuto<= MinFin))
		AND (
			Lunes=dia or
			Martes*2=dia or
			Miercoles*3=dia or
			Jueves*4=dia or
			Viernes*5=dia or
			Sabado*6=dia or
			domingo*7=dia
		)
	) inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id=ccCampsHorarios.horario_id and ccCampsHorarios.cam_id=@campid

	if @iZonas is null begin
		SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
		return
	end
 end 

else
begin
	if @camSurvey > 0
		begin
			SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
			return	
		end

	if @revHorario=0
		select @iZonas=sum(distinct tz_id)from ccTimeZones -- No hay horarios, ponemos todas las zonas
	else
		select @iZonas=Null
end

set @Sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
 cam_id int,
 cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
 cal_status tinyint,
 cal_fechaDial datetime,
 user_id int, 
 tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
tel varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel2 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel3 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel4 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel5 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
dialOrder varchar(10),
list_id int,
sequence smallint
)''

-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
 select @topCount=case when @nAgentsLogin<3 then 30
  when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
  when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
  when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
  when @nAgentsLogin>=16 then 240 else 20 end

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
 begin
	select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

	select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isnull(R.sequence,0) as sequence
	FROM ccoWorkingTable W left join ccRIARegistryLists R 
	on W.list_id = R.list_id 
	left join ccocallsoutsource couts    
	on W.callout_id = couts.callout_id 
	WHERE W.cal_status=1 -- CallBacks
	and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
	and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + '' 
	and (
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by W.prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
 end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
 begin
	select @Sql=@Sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

	select @Sql=@Sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id, 
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isNull(R.sequence,0) as sequence
	FROM ccoWorkingTable W left join ccRIARegistryLists R 
	on W.list_id = R.list_id 
	left join ccocallsoutsource couts    
	on W.callout_id = couts.callout_id 
	WHERE W.cal_status=0 -- Nuevas sin Tiempo
	and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + '' 
	and (
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
	((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', W.callout_id''
	
 end -- TOMA EN CUENTA LAS NUEVAS

----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @Sql=@Sql+nchar(13)+ ''SET rowcount 0''
if @Test=0 
 begin
	select @Sql=@Sql+nchar(13)+ ''UPDATE ccoWorkingTable SET cal_status=2 --CALLBACK IN PROGRESS
	WHERE callout_id in(select callout_id from #NEW_JOBS)''
 end

select @Sql=@Sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, 
user_id, tz, tz2, tz3, tz4, tz5, tel, tel2, tel3, tel4, tel5, dialOrder, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0''

select @Sql=@Sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print @Sql
exec(@Sql)
return(0)'
		
	EXEC(@Sql)

		set @Sql = 'USE [msdb]

/****** Object:  Job [NuxibaMaintenancePlan]    Script Date: 11/28/2012 08:44:30 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''NuxibaMaintenancePlan'')
EXEC msdb.dbo.sp_delete_job @job_name=N''NuxibaMaintenancePlan'', @delete_unused_schedule=1

/****** Object:  Job [NuxibaMaintenancePlan]    Script Date: 07/04/2012 11:56:51 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 07/04/2012 11:56:51 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[MaintenancePlan (Local)]''

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''NuxibaMaintenancePlan'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Delete and update the information for CCenterria DataBase, this job  attempts to improve the operation of the database'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT

/****** Object:  Step [Check Call Center Activity]    Script Date: 07/04/2012 11:56:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Call Center Activity'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=1, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''declare @fecha_ini datetime
declare @fecha_fin datetime

select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))
select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))

IF EXISTS (SELECT uid, max(ext) ext, login, isnull(max(logout),getdate()) logout, 
datediff(s,login,isnull(max(logout),getdate())) loginTime
FROM (SELECT uid, ext, login, ISNULL(logout, 
(SELECT MIN(fecha) FROM ccLogLogin with (nolock, index(IX_ccLogLogin_2))  
WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout   
FROM (SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout   
FROM (SELECT uid, ext, MAX(login) as login, logout
FROM(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha)
FROM ccLogLogin subLogin with (nolock, index(IX_ccLogLogin_2)) WHERE subLogin.tipomov = 0      
AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout]      
FROM ccLogLogin Login with (nolock, index(IX_ccLogLogin_2))     
WHERE login.fecha >= dateadd(dd, -5, @fecha_ini) and tipomov = 1     
GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail     
WHERE logout IS not NULL GROUP BY uid, ext, logout) Login    
RIGHT OUTER JOIN ccLogLogin  with (nolock, index(IX_ccLogLogin_2))   
ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login 
AND ccLogLogin.extension = Login.ext)   WHERE tipomov = 1   and ccLogLogin.fecha 
>= dateadd( dd, -5, @fecha_ini)) Det   ) LoginDetail WHERE logout IS NULL 
and login >= @fecha_ini and login < @fecha_fin 
GROUP BY uid, login)
BEGIN
  RAISERROR(''''Agents online.'''', 11, 1);
END
ELSE
BEGIN
	RETURN
END'', 
		@database_name=N''CCenterRia'', 
		@flags=0

/****** Object:  Step [Check Database Integrity Task]    Script Date: 07/04/2012 11:56:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Database Integrity Task'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''USE [CCenterRia]

DBCC CHECKDB WITH NO_INFOMSGS'', 
		@database_name=N''CCenterRia'', 
		@flags=0

/****** Object:  Step [Maintenance Cleanup Task]    Script Date: 06/26/2012 11:25:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Maintenance Cleanup Task'', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @currentdate datetime
declare @date datetime
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = dateadd(ww,-3,getdate())

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''HKEY_LOCAL_MACHINE'''', N''''Software\Microsoft\MSSQLServer\MSSQLServer'''',N''''BackupDirectory''''

select @rutaBak = Data
from #RutaBak

EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''bak'''',@date

drop table #RutaBak'', 
		@database_name=N''CCenterRia'', 
		@flags=0

/****** Object:  Step [Back Up Database Task]    Script Date: 06/26/2012 11:25:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Back Up Database Task'', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @currentdate datetime
declare @date varchar(200)
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = ''''CCenterRia_backup_MP'''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''.bak''''

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''HKEY_LOCAL_MACHINE'''', N''''Software\Microsoft\MSSQLServer\MSSQLServer'''',N''''BackupDirectory''''

select @rutaBak = Data
from #RutaBak

select @rutaBak= @rutaBak + ''''\'''' + @date

drop table #RutaBak

BACKUP DATABASE [CCenterRia] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10
'', 
		@database_name=N''CCenterRia'', 
		@flags=0

/****** Object:  Step [Rebuild Index Task]    Script Date: 06/26/2012 11:25:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Rebuild Index Task'', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''USE [CCenterRia]

ALTER INDEX [IX_axLicG729_Data] ON [dbo].[axLicG729_Data] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_Camplistanegra] ON [dbo].[Camplistanegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK__ccAbandonoSalida__39987BE6] ON [dbo].[ccAbandonoSalida] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAbandonoSalida_Chart] ON [dbo].[ccAbandonoSalida_Chart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAgenda_TipolistaNegra] ON [dbo].[ccAgenda_TipolistaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAgendaListaNegra] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAgendaListaNegra_1] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAgendaListaNegra_2] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAgendaListaNegra_3] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_INFOESPEC_FECHA] ON [dbo].[ccAllInfoEspec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_INFOESPEC_INBOUND_ID] ON [dbo].[ccAllInfoEspec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAVRSTransfer] ON [dbo].[ccAVRSTransfer] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccAVRSTransfer] ON [dbo].[ccAVRSTransfer] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_cccalifblacklist] ON [dbo].[cccalifblacklist] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCalifCamp] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCalifCamp_1] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [uc_ccCalifCamp] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallsIn] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallsIn_1] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallsIn_2] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallsIn_3] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallsIn_4] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallsIn_5] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccCallsIn] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_cccallsin_tmpChart] ON [dbo].[cccallsin_tmpChart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccCallsReject] ON [dbo].[ccCallsReject] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccCamps] ON [dbo].[ccCamps] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccCamps_Consulta] ON [dbo].[ccCamps_Consulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [iii] ON [dbo].[ccCampsAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccCampsAgente] ON [dbo].[ccCampsAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK__ccCampsDialInfo__453F38BC] ON [dbo].[ccCampsDialInfo] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCampsHorarios] ON [dbo].[ccCampsHorarios] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCampsMsgs] ON [dbo].[ccCampsMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCampsNvosCB] ON [dbo].[ccCampsNvosCB] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCampsPrioridadTel] ON [dbo].[ccCampsPrioridadTel] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccClientes] ON [dbo].[ccClientes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccDNIS] ON [dbo].[ccDNIS] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccDNIS] ON [dbo].[ccDNIS] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccEdoAniList] ON [dbo].[ccEdoAniList] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenAgent] ON [dbo].[ccGenAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenAgentNotReady] ON [dbo].[ccGenAgentNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenChart] ON [dbo].[ccGenChart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenInAbnd] ON [dbo].[ccGenInAbnd] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenInAnsw] ON [dbo].[ccGenInAnsw] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenInCalif] ON [dbo].[ccGenInCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenInCall] ON [dbo].[ccGenInCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenInCallDNI] ON [dbo].[ccGenInCallDNI] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSpec] ON [dbo].[ccGenInSpec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenOutCall] ON [dbo].[ccGenOutCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenOutCallCalif] ON [dbo].[ccGenOutCallCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenOutCallDials] ON [dbo].[ccGenOutCallDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSpecOut] ON [dbo].[ccGenOutCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenOutCstoResumen] ON [dbo].[ccGenOutCstoResumen] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenLogin] ON [dbo].[ccGenSession] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSessionAgent] ON [dbo].[ccGenSessionAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSessionInCall] ON [dbo].[ccGenSessionInCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSessionInSpec] ON [dbo].[ccGenSessionInSpec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSessionNotReady] ON [dbo].[ccGenSessionNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSessionOutCall] ON [dbo].[ccGenSessionOutCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSessionOutCamp] ON [dbo].[ccGenSessionOutCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccHistorialListaNegra] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccHistorialListaNegra_1] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccHistorialListaNegra_2] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccHistorialListaNegra_3] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccHistorialListaNegra] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccHorarios] ON [dbo].[ccHorarios] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccHorarioVerano] ON [dbo].[ccHorarioVerano] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccHorarioVeranoUsa] ON [dbo].[ccHorarioVeranoUsa] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccInbound] ON [dbo].[ccInbound] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccInbound_Consulta] ON [dbo].[ccInbound_Consulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccInboundAgentes] ON [dbo].[ccInboundAgentes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccInboundDNIS] ON [dbo].[ccInboundDnis] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccInboundHorarios] ON [dbo].[ccInboundHorarios] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccInboundMsgs] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccInboundMsgs_1] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccInboundMsgs_2] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccInboundMsgs_3] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccListaNegra] ON [dbo].[ccListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesDia] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesDia_1] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesDia_2] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesDia_3] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesDia_4] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccLogAgentesDia_Dialog] ON [dbo].[ccLogAgentesDia_Dialog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesNotReady] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesNotReady_2] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesNotReady_3] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK__ccLogInfo__03F0984C] ON [dbo].[ccLogInfo] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogLogin] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogLogin_1] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogLogin_2] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogLogin_3] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogReciclaje] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogReciclaje_1] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogReciclaje_2] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogTransfers_2] ON [dbo].[ccLogTransfers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccMenu_Views] ON [dbo].[ccMenu_Views] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccMenu_ViewsUser] ON [dbo].[ccMenu_ViewsUser] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccMenus] ON [dbo].[ccMenus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccMenus] ON [dbo].[ccMenus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccMenusReportes] ON [dbo].[ccMenusReportes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccMonitorExt] ON [dbo].[ccMonitorExt] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccMsgFiles] ON [dbo].[ccMsgFiles] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallBacks] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_1] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_10] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_11] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_2] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_3] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_4] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_5] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_6] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_7] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_8] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_9] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccoCallsOut] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_1] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_10] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_11] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_2] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_3] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_4] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_5] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_6] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_7] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_8] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_9] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccoDatos] ON [dbo].[ccoDatos] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccodialercamp] ON [dbo].[ccoDialerCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoDialers] ON [dbo].[ccoDialers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccodialers] ON [dbo].[ccoDialers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoLogDials] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoLogDials_1] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoLogDials_2] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoLogDials_3] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccoLogDials] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_1] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_10] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_11] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_12] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_13] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_14] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_2] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_3] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_4] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_5] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_6] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_7] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_8] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_9] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccoWorkingTable] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccPosicion] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccPosicion_1] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccPosicion_2] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccPosicion] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccPuertosPBX] ON [dbo].[ccPuertosPBX] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK__ccRIAAreaWorkGro__27CED166] ON [dbo].[ccRIAAreaWorkGroup] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallBacks] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACallBacks] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACallBacks_1] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACallBacks_2] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACallBacks_3] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACampEspWG] ON [dbo].[ccRIACampEspWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACampEspWG_1] ON [dbo].[ccRIACampEspWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACampEspWG_2] ON [dbo].[ccRIACampEspWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIACampsGraph] ON [dbo].[ccRIACampsGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIACat_Restrictions] ON [dbo].[ccRIACat_AdminRole] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK__ccRIACat_Areas__23FE4082] ON [dbo].[ccRIACat_Areas] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIACat_DialMode] ON [dbo].[ccRIACat_DialMode] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK__ccRIACat_WorkGro__24F264BB] ON [dbo].[ccRIACat_WorkGroup] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIACatFunExt] ON [dbo].[ccRIACatFunExt] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAChat_Log_1] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAChat_TipoMsg] ON [dbo].[ccRIAChat_TipoMsg] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAClienteCarga] ON [dbo].[ccRIAClienteCarga] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAClienteCarga_1] ON [dbo].[ccRIAClienteCarga] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAExternalApplications] ON [dbo].[ccRIAExternalApplications] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAGraphics] ON [dbo].[ccRIAGraphics] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAGraphicType] ON [dbo].[ccRIAGraphicType] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAInboundGraph] ON [dbo].[ccRIAInboundGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIALoading] ON [dbo].[ccRIALoading] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIALoading_1] ON [dbo].[ccRIALoading] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIALoading] ON [dbo].[ccRIALoading] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIALog] ON [dbo].[ccRIALog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIALog_Module] ON [dbo].[ccRIALog_Module] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIALog_Operation] ON [dbo].[ccRIALog_Operation] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIALogAgentesNotReady] ON [dbo].[ccRIALogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIALogAgentesNotReady_1] ON [dbo].[ccRIALogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIANotReadyGraph] ON [dbo].[ccRIANotReadyGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_Table_1] ON [dbo].[ccRIARegistryLists] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRiaRemoteLog] ON [dbo].[ccRiaRemoteLog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAUpdateCallBack_Abandon_1] ON [dbo].[ccRIAUpdateCallBack_Abandon] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAUpdateCallBack_Abandon] ON [dbo].[ccRIAUpdateCallBack_Abandon] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAWorkGroup_Calid_2] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAWorkGroup_Calid_3] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_WGCal_id] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_cccRIAWorkGroup_logdial_id_2] ON [dbo].[ccRIAWorkGroup_logDial_id] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_WGlogDial_id] ON [dbo].[ccRIAWorkGroup_logDial_id] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAWorkGroupUsers] ON [dbo].[ccRIAWorkGroupUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccSettings] ON [dbo].[ccSettings] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccStatusLLamada] ON [dbo].[ccStatusLLamada] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccSupervisorND] ON [dbo].[ccSupervisor_NotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [ix_tipo_1] ON [dbo].[ccSupervisorCam] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccSupervisorCam] ON [dbo].[ccSupervisorCam] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_TideWater_Templates] ON [dbo].[ccTideWater_Templates] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTideWater_Templates_Cols] ON [dbo].[ccTideWater_Templates_Cols] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTideWater_TipoConexion] ON [dbo].[ccTideWater_TipoConexion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_Timetable] ON [dbo].[ccTimetable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTimetablechange] ON [dbo].[ccTimetablechange] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTimetabledetail] ON [dbo].[ccTimetabledetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTimeZoneArea_1] ON [dbo].[ccTimeZoneArea] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [pk_areaprefix] ON [dbo].[ccTimeZoneAreaUsaDetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTimeZones] ON [dbo].[ccTimeZones] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoCalif] ON [dbo].[ccTipoCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoCalifOUT] ON [dbo].[ccTipoCalifOUT] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoCalifSub] ON [dbo].[ccTipoCalifSub] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoSubCalifOUT] ON [dbo].[ccTipoCalifSubOUT] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoFiltro] ON [dbo].[ccTipoFiltro] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoMovsListaNegra] ON [dbo].[ccTipoMovsListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoMsgs] ON [dbo].[ccTipoMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoNotReady] ON [dbo].[ccTipoNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoPBX] ON [dbo].[ccTipoPBX] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoResultadoDial] ON [dbo].[ccTipoResultadoDial] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTiposListaNegra] ON [dbo].[ccTiposListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoStatusAgente] ON [dbo].[ccTipoStatusAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_cctipoSubCalifRel] ON [dbo].[cctipoSubCalifRel] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccUploadTemporal] ON [dbo].[ccUploadTemporal] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccUploadTemporal_1] ON [dbo].[ccUploadTemporal] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccusers] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccusers_1] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccUsers] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccUsers_Consulta] ON [dbo].[ccUsers_Consulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_cstoProvedor] ON [dbo].[cstoProvedor] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_cstoTarifa] ON [dbo].[cstoTarifa] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_cstoTipoLlamada] ON [dbo].[cstoTipoLlamada] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY  = OFF, ONLINE = OFF )

ALTER INDEX [PK_IVR_ID_1] ON [dbo].[IVRCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_Series] ON [dbo].[Series] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_Series_1] ON [dbo].[Series] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK__seriesUK__4D2B3E9E] ON [dbo].[seriesUK] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_telefonosConferencia] ON [dbo].[telefonosConferencia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_telefonosTransferencia] ON [dbo].[telefonosTransferencia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_clienteCarga] ON [dbo].[xxClienteCarga] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
'', 
		@database_name=N''CCenterRia'', 
		@flags=0

/****** Object:  Step [History Cleanup Task]    Script Date: 06/26/2012 11:25:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''History Cleanup Task'', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @currentdate datetime
declare @dt datetime

set @currentdate = CURRENT_TIMESTAMP
select  @dt =dateadd(ww,-3,getdate())

exec msdb.dbo.sp_delete_backuphistory @dt

EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date=@dt

EXECUTE msdb..sp_maintplan_delete_log null,null,@dt'', 
		@database_name=N''CCenterRia'', 
		@flags=0

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1

EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''monthy'', 
		@enabled=1, 
		@freq_type=32, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=1, 
		@freq_recurrence_factor=1, 
		@active_start_date=20120615, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''

COMMIT TRANSACTION'

		EXEC(@Sql)

set @Sql ='CREATE PROCEDURE [dbo].[ccsp_RIADNCList]
@phoneNumber as varchar(30),
@idDNCList as integer,
@tipoMov as tinyint
AS

if @tipoMov = 1 begin -- Inserta Lista Negra	
	exec ccsp_InsertDNCList @telephone= @phoneNumber, @ln_id = @idDNCList
	insert cchistoriallistanegra (telefono,idtipomov,idtipolista) values (@phoneNumber,7,@idDNCList)
end

if @tipoMov = 2 begin -- Borra Lista Negra	
	delete from cclistanegra where telefono = @phoneNumber and idtipolista = @idDNCList
	insert cchistoriallistanegra (telefono,idtipomov,idtipolista) values (@phoneNumber,5,@idDNCList)
end

if @tipoMov = 3 begin -- Reemplaza Lista Negra
	insert cchistoriallistanegra(telefono,idtipomov,idtipolista) select telefono,''4'',@idDNCList from cclistanegra where idtipolista= @idDNCList
	delete from cclistanegra where idtipolista = @idDNCList
end'
		EXEC(@Sql)

	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @@ERROR ID, ERROR_MESSAGE() [DESC], ERROR_PROCEDURE()
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
