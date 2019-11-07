CREATE procedure [dbo].[ccsp_EngineLogTransfers]
@action as tinyint,
@cal_id as integer,
@tipo as tinyint,
@modo as tinyint,
@destino as varchar(50),
@tantes integer = 0,
@tdespues integer = 0,
@pbxId tinyint =0,
@channel int =0
as
-- tipo: 1 inbound, 2 outbound
-- modo: 0 externa ciega, 1 agente, 2 acd, 3 confer, 4 externa supervisada, 5 desborde
		 
declare @totalCall_Time integer
declare @callout_id int
		 
if @action = 1 begin
    if @modo = 4 begin
	   insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id) 
	   values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, getdate(), @pbxId,@channel, dbo.fnGetTipoLlamada(@destino) )
	   if @tdespues > 0 begin
		      select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tdespues
		      update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
	   end
    end
    else begin
	   if not exists (select * from ccLogTransfers where cal_id = @cal_id and tipo = @tipo)
		  insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin,pbxId,channel, tipoLlamada_id) 
		  values ( @cal_id, @tipo, @modo, @destino, 0, @tantes, getdate() ,@pbxId,@channel, dbo.fnGetTipoLlamada(@destino) )
		 
	   if @tipo = 2 begin
		  if @modo = 5 begin
		      select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
		      update ccLogTransfers set tDespuesXfer = @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2), tAntesXfer = @tdespues + (select tAntesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)  where cal_id = @cal_id and tipo = 2
		  end
		         
		  if @modo in (0,1,2) begin
		      select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
		      update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
		  end
	   end
		 
	   else begin
		  if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
		      select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
		      select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
		      update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
		  end
	   end
    end
    --Valida que no existe y que el tiempo minimo de la grabacion se mayor al establecido para que lo tome el detector de gritos
    if not exists(select * from ccAVRSTransfer where cal_id=@cal_id and tipo= @tipo-1) begin
    declare @tMinAVRS smallint,@cal_tDialog int,@cal_manual int
    set @tMinAVRS=5
    set @cal_manual=0
    select @tMinAVRS=valor from ccSettings where setting_id=65
    if @tipo=2 begin
	   select @cal_tDialog=cal_tDialog,@cal_manual=cal_manual from ccoCallsOut where cal_id=@cal_id
    end
    else begin
	   select @cal_tDialog=cal_tDialog from ccCallsIn where cal_id=@cal_id
    end
		 
    if @cal_tDialog >= @tMinAVRS and @cal_manual<>1 begin
	   insert into ccAVRSTransfer (cal_id,tipo) values(@cal_id,@tipo-1)
    end
    end
end
		 
else if @action = 2 begin   
    if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
	   select @cal_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
	   update ccLogTransfers set tDespuesXfer = @tdespues + @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2)  where cal_id = @cal_id and tipo = 2
	   select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
	   update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
    end
end
		 
else if @action = 4 begin
    select @totalCall_Time = ISNULL((select sum(tincall) from IVRCallsIn where callout_id = @cal_id), 0) + ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0)
    update ccoCallsOut set totalCall_Time = @totalCall_Time, tipoLlamada_id = dbo.fnGetTipoLlamada(@destino) where cal_id = @cal_id
end