/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Alan Minor 
Date: 2018/02/16
Description:



Database: CCenterRia
Required version: 119.10.2

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 119 sin fix
set @versionfix = 122
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 121
	begin
		begin tran
		begin try

		set @process = 'CW-1382  Version 119.114 Drop SP -- ccsp_AvrsSyncronization'
		set @Sql= 'if exists (select * from sys.procedures where name = ''ccsp_AvrsSyncronization'') DROP PROCEDURE [dbo].[ccsp_AvrsSyncronization]'
		EXEC(@sql)
	 

		set @process = 'CW-1330 -- Update en tabla ccSettings. Valor de setting 183'
    	set @Sql= 'if exists (select valor from ccSettings where setting_id=183 and valor <> '''')
		begin
			declare @valor table (Id int, Value varchar(255))
			insert into @valor select * from fn_RIASplitDelimited((select valor from ccSettings where setting_id=183),''|'')
	
			if SUBSTRING((select Value from @valor where Id=7),1,1) <> ''"''
			begin
				declare @stun varchar(255), @newvalue varchar(255)
				select @stun = ''"'' + (select Value from @valor where Id=7) + ''"'' 
				UPDATE @valor set Value = @stun where Id=7
				select @newvalue = COALESCE(@newvalue + ''|'', '''') + Value FROM @valor

				UPDATE ccSettings set valor = @newvalue where setting_id=183
			end
		end
		else
			UPDATE CCSettings set valor=''0|ws://192.168.1.246:10080|#UserIP#|sip:#UserIP#@#UserIP#|||"stun.l.google.com:19302"|true|true|3|4|root|false|5||true|true|3'' where setting_id=183'
    	EXEC(@Sql)

		set @process = 'Agregar columnas a las tablas ccoCallsOut para guardar tiempo total-- CW-1338'
    	set @Sql= 'if not exists(select totalCall_Time from ccoCallsOut)
			Alter table ccoCallsOut ADD totalCall_Time int'
		EXEC(@Sql)

		set @process = 'Agregar columnas a las tablas ccCallsIn para guardar id de llamada de salida-- CW-1338'
    	set @Sql= 'if not exists(select callout_id from ccCallsIn) 
			Alter table ccCallsIn ADD callout_id int'
		EXEC(@Sql)

		set @process = 'Agregar columnas a las tablas ccoCallsOut, ccCallsIn y ivrcallsin para guardar tiempos-- CW-1338'
    	set @Sql= 'if not exists(select callout_id, tincall from ivrcallsin) 
			Alter table ivrcallsin ADD callout_id int, tincall int'
		EXEC(@Sql)

		set @process = 'CW-1382 Version 119.114 -- CREATE SP ccsp_AvrsSyncronization'
    	set @Sql= 'Create procedure [dbo].[ccsp_AvrsSyncronization]
@action smallint,
@maxRecordsToTransfer int=10,
@id int=0
AS
set nocount on
if @action=1 begin

	Select top(@maxRecordsToTransfer) call.cal_id, user_id, inbound_id, call.calif_id, cast(cal_extension as integer) as cal_extension,  
	cal_inicio, cal_ANI as phone, 
	cal_tDialog - case when trans.tAntesXfer is null then cal_tMoh			else cal_tMoh-trans.tAntesXfer end 	+ isnull( trans.tDespuesXfer ,0) as duration,
	cal_key, 0 as cal_manual, cal_puerto, dni_id , fvalida , cal_whohung,
	isnull(cast(califSub_id as smallint),0) as califSub_id,
	case when trans.tAntesXfer is null then cal_tMoh when cal_tMoh-trans.tAntesXfer<0 then 0  else cal_tMoh-trans.tAntesXfer end  as cal_tMoh ,
	dateadd(ss,cal_tDialog, cal_inicio) dateEnd,avrs.tipo+1 as callType,avrs.id as avrsId		
	from ccCallsIn as  call
	inner join ccAVRSTransfer avrs on call.cal_id=avrs.cal_id and avrs.tipo=0	
	left join 
		(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer from ccLogTransfers where tipo=1 group by cal_id,tipo 
			)trans 	
	on call.cal_id=trans.cal_id 
	union		
	Select top(@maxRecordsToTransfer) call.cal_id as CallId, user_id as UserId, cam_id as camAcdId, cast(call.calif_id as smallint) as califId, cast(cal_extension as integer) as extension,  
	cal_inicio, cal_telefono, 
	cal_tDialog - case when trans.tAntesXfer is null then cal_tMoh			else cal_tMoh-trans.tAntesXfer end 	+ isnull( trans.tDespuesXfer ,0) as duration,
	cal_key, cal_manual, cal_puerto,  0 as dni_id , fvalida , cal_whohung,
	isnull(cast(califSub_id as smallint),0) as califSub_id,
	case when trans.tAntesXfer is null then cal_tMoh when cal_tMoh-trans.tAntesXfer<0 then 0  else cal_tMoh-trans.tAntesXfer end  as cal_tMoh ,
	dateadd(ss,cal_tDialog, cal_inicio) dateEnd,avrs.tipo+1 as callType,avrs.id as avrsId				
	from ccoCallsOut  as call	
	inner join ccAVRSTransfer avrs on call.cal_id=avrs.cal_id and avrs.tipo=1	
	left join 
		(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer from ccLogTransfers where tipo=2 group by cal_id,tipo 
			)trans 	
	on call.cal_id=trans.cal_id 
end 
else if @action=2 begin
	delete from ccAVRSTransfer where id = @id
end'
    	EXEC(@Sql)

		set @process = 'Modificacion al SP ccsp_EngineLogTransfers-- CW-1338'
    	set @Sql= 'ALTER procedure [dbo].[ccsp_EngineLogTransfers]
@action as tinyint,
@cal_id as integer,
@tipo as tinyint,
@modo as tinyint,
@destino as varchar(50),
@tantes integer = 0,
@tdespues integer = 0
as
-- tipo: 1 inbound, 2 outbound
-- modo: 0 externa ciega, 1 agente, 2 acd, 3 confer, 4 externa supervisada, 5 desborde

declare @totalCall_Time integer
declare @callout_id int

if @action = 1 begin
	if @modo = 4 begin
		insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin)  values ( @cal_id, @tipo, @modo, @destino, @tantes, @tdespues, getdate() )
		if @tdespues = 0
			select @totalCall_Time = ISNULL((select cal_tDialog from ccoCallsOut where cal_id = @cal_id), 0) + ISNULL((select cal_twait from ccoCallsOut where cal_id = @cal_id), 0) + ISNULL((select cal_tXfer from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
		else
			select @totalCall_Time = ISNULL((select cal_tDialog from ccoCallsOut where cal_id = @cal_id), 0) + ISNULL((select cal_twait from ccoCallsOut where cal_id = @cal_id), 0) + ISNULL((select cal_tXfer from ccoCallsOut where cal_id = @cal_id), 0) + @tdespues
		update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
	end
	else begin
		if not exists (select * from ccLogTransfers where cal_id = @cal_id and tipo = @tipo)
			insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin) values ( @cal_id, @tipo, @modo, @destino, 0, @tantes, getdate() )

		if @modo = 5 begin
			select @callout_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
			select @cal_id = (select cal_id from ccoCallsOut where callout_id = @callout_id)
			update ccLogTransfers set tDespuesXfer = @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2), tAntesXfer = @tdespues + (select tAntesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2) where cal_id = @cal_id and tipo = 2
		end
		
		select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
		update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
	end
	if not exists(select * from ccAVRSTransfer where cal_id=@cal_id and tipo= @tipo-1) begin
		insert into ccAVRSTransfer (cal_id,tipo) values(@cal_id,@tipo-1)
	end
end

else if @action = 2 begin	
	if (select callout_id from ccCallsIn where cal_id = @cal_id) > 0 begin
		select @callout_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
		select @cal_id = (select cal_id from ccoCallsOut where callout_id = @callout_id)
		update ccLogTransfers set tDespuesXfer = @tdespues + @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2) where cal_id = @cal_id and tipo = 2
		select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
		update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
	end
end

else if @action = 3 begin
	select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
	update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id	
end

else if @action = 4 begin
	select @totalCall_Time = ISNULL((select sum(tincall) from IVRCallsIn where callout_id = @cal_id), 0) + ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0)
	update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
end'
		EXEC(@Sql)

		set @process = 'Modificacion al SP ccsp_AgentUpdateCallTimes-- CW-1338'
    	set @Sql= 'ALTER procedure [dbo].[ccsp_AgentUpdateCallTimes]
@IDCall int,
@cal_tXfer smallint,
@cal_tDialog smallint,
@cal_tNotas smallint,
@TipoCall tinyint,
@cal_tRing smallint=0,
@mtmoh smallint = 0,
@isChatCall bit = 0,
@isErroManualCall bit =0
AS
set nocount on
if @IDCall<=0 
	return(0)

declare @tMinAVRS smallint

if @TipoCall=1 --INBOUND
 begin
  Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
  cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, 
  cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end
  Where cal_id= @IDCall

  --Actualizar tiempo total de llamada
  exec ccsp_EngineLogTransfers 2, @IDCall, @TipoCall, 2, null, @cal_tXfer, @cal_tDialog

  -- Elimina callback generado por abandono
  Declare @ANI_x varchar(19)
  select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

  DELETE ccoWorkingTable with(rowlock ) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
  DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
 end

if @TipoCall=2 --OUTBOUND
 begin
	Update ccoCallsOUT with(rowlock) Set cal_tXfer=case when @cal_tXfer > 0 then @cal_tXfer else cal_tXfer end, 
	cal_tDialog=case when @cal_tDialog > 0 then @cal_tDialog else cal_tDialog end, 
	@cal_tDialog=case when @cal_tDialog > 0 then @cal_tDialog else cal_tDialog end,
	cal_tNotas=case when @cal_tNotas > 0 then @cal_tNotas else cal_tNotas end, 
	cal_tMoh=case when @mtmoh > 0 then @mtmoh else cal_tMoh end,
	cal_tRing=case when @cal_tRing > 0 then @cal_tRing else cal_tRing end, 
	cal_manual=case when @isChatCall=1 then 3 else cal_manual end,
	cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end 
	Where cal_id=@IDCall

	-- calcula el costo de la llamada
	exec ccsp_CstoCalculaCosto @IDCall

	--Actualizar tiempo total de llamada
	exec ccsp_EngineLogTransfers 3, @IDCall, @TipoCall, 0, null, @cal_tXfer, @cal_tDialog
 end

select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

if @cal_tDialog >= @tMinAVRS
 begin
	insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
	return(0)
 end

set nocount off'
		EXEC(@Sql)

		set @process = 'Modificacion al SP ccsp_IVRBeforeAskAge-- CW-1338'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_IVRBeforeAskAge]
@cal_id int,
@Inbound_id smallint,
@cal_Key varchar(20),
@callout_id int
AS
Update ccCallsIn SET Inbound_id= @Inbound_id, cal_key=@cal_Key, statusCall_id=11, callout_id=@callout_id
where cal_id=@cal_id'
		EXEC(@Sql)

		set @process = 'Modificacion al SP ccsp_IVRInCalls-- CW-1338'
    	set @Sql= 'ALTER procedure [dbo].[ccsp_IVRInCalls]
@action tinyint = 0 ,
@ani varchar(30) = null ,
@idIvr int = 0 ,
@option varchar(5)= null ,
@saveType tinyInt = null,
@dnis varchar(50) = null,
@name varchar(50) = null,
@questionId int = 0,
@surveyId int = 0,
@calId int = 0,
@callout_id int = 0,
@ttotalIVR int = 0
-- saveType 1 es menu 2 es dato
-- accion 1 siempre @ani  -> @idIvr
-- accion 2 siempre @idIvr @opcionDigitada -> nada
AS
IF @action = 1
BEGIN
    IF @ani IS NOT NULL
    BEGIN
        INSERT INTO IVRCallsIn(cal_ani,date,dnis,callout_id) values(@ani,getDate(),isnull(@dnis,''''),@callout_id);
        Select ''ID''=scope_identity()
    END
END
ELSE IF @action = 2
BEGIN
    IF @option IS NOT NULL AND @idIvr IS NOT NULL
    BEGIN
        INSERT INTO IVROptions(IVR_id,selectedOption,date,saveType,name, questionId, surveyId, cal_id) values (@idIvr,@option,getDate(),@saveType,@name,isnull(@questionId,0),isnull(@surveyId,0),isnull(@calId,0))
        select 0
    END
    ELSE select -1
END
ELSE IF @action = 3
BEGIN
	UPDATE IVRCallsIn set tincall = @ttotalIVR where IVR_id = @idIvr and callout_id = @callout_id
	if @callout_id > 0
		exec ccsp_EngineLogTransfers 4, @callout_id, 0, 0, null
END'
		EXEC(@Sql)

		set @process = 'Modificacion al SP ccsp_IVRUpdateCallEndNew-- CW-1338'
    	set @Sql= 'ALTER procEDURE [dbo].[ccsp_IVRUpdateCallEndNew]
@cal_id int,
@cal_tIVRCallDuration smallint,
@statuscal_id tinyint, 
-- Aqui solo se Aceptan Edos Terminales 2(Fuera de Horario), 3(Fuera de Servicio), 4(NoAgentesFirmados), 7(TimeOut), 8(DesbordeQue),
@cal_opciones varchar(10),
@cal_colgada tinyint,
@User_id smallint,
@cal_extension varchar(7),
@tWait smallint
AS
set nocount on

Update ccCallsIn SET statusCall_id = case when @statuscal_id in (2, 3, 4, 7, 8) then @statuscal_id else case when statusCall_id = 5 then 6 else statuscall_id end end, 
 user_id=@User_id, cal_extension=@cal_extension, cal_tWait=@tWait where cal_id=@cal_id

exec ccsp_RIAUpdateCallBack_Abandon @cal_id, @statuscal_id

--Actualizar tiempo total de llamada
exec ccsp_EngineLogTransfers 2, @cal_id, 2, 2, null, @tWait, @cal_tIVRCallDuration

set nocount off'
		EXEC(@Sql)

		set @process = 'Modificacion al SP ccsp_CstoCalculaCosto-- CW-1338'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_CstoCalculaCosto]
@IDCall int = 0,
@from AS smalldatetime = NULL,
@to AS smalldatetime = NULL
AS
set nocount on
declare @minutouno decimal(10,3), @minutoadicional decimal(10,3)
declare @puerto smallint, @provedor_id smallint
declare @longitud tinyint, @tipoLlamada_id tinyint
declare @telefono varchar(20)

if @IDCall = 0 -- Para calcular todo
 begin
    if @from is null and @to is null
     begin
        update ccoCallsOut
        --set costo =  t.MinutoUno + case when cco.cal_txfer + cco.cal_tring + cco.cal_tDialog > 0 then((ceiling(( cco.cal_txfer + cco.cal_tring + cco.cal_tDialog ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
        set costo =  t.MinutoUno + case when ISNULL(cco.totalCall_Time,0) > 0 then((ceiling(( ISNULL(cco.totalCall_Time,0) ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
         ,provedor_id = cd.provedor_id
         ,tipoLlamada_id = t.tipoLlamada_id
        from ccoCallsOut cco with(index(IX_ccoCallsOut_7), nolock), ccoDialers cd, cstoTarifa t
        where cco.cal_puerto = cd.puerto
         and cd.provedor_id = t.provedor_id 
         and t.tipoLlamada_id = dbo.fnGetTipoLlamada(ltrim(rtrim(cal_telefono)))--dbo.fnGetTipoLlamada(cco.cal_telefono)
         and cco.cal_manual <> 1
         return(0)
     end

    -- calcula en el rango de fechas, solo los que no tienen costo
    update ccoCallsOut
    --set costo =  t.MinutoUno + case when cco.cal_txfer + cco.cal_tring + cco.cal_tDialog > 0 then((ceiling(( cco.cal_txfer + cco.cal_tring + cco.cal_tDialog ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
    set costo =  t.MinutoUno + case when ISNULL(cco.totalCall_Time,0) > 0 then((ceiling(( ISNULL(cco.totalCall_Time,0) ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
    ,provedor_id = cd.provedor_id
    ,tipoLlamada_id = t.tipoLlamada_id
    from ccoCallsOut cco with(index(IX_ccoCallsOut_8), nolock), ccoDialers cd, cstoTarifa t
    where cco.cal_puerto = cd.puerto
     and cd.provedor_id = t.provedor_id 
     and t.tipoLlamada_id = dbo.fnGetTipoLlamada(cco.cal_telefono)
     and cco.cal_manual <> 1
     and cco.cal_inicio between @from and @to
     and cco.provedor_id is null
     return(0)
 end

select @puerto = cal_puerto, @longitud = len(cal_telefono) , @telefono = cal_telefono 
from ccoCallsOut with(index(PK_ccoCallsOut), nolock) where cal_id = @idCall

if @puerto = 0
    return(0)

select @minutouno = minutouno, @minutoadicional = minutoadicional, @provedor_id = d.provedor_id, @tipoLlamada_id = t.tipollamada_id 
from cstoTarifa t
inner join ccoDialers d on d.provedor_id = t.provedor_id
where t.tipollamada_id = dbo.fnGetTipoLlamada( @telefono )
and d.puerto = @puerto

update ccoCallsOut with(rowlock) 
--set costo = @MinutoUno + case when cal_txfer + cal_tring + cal_tDialog > 0 then((ceiling(( cal_txfer + cal_tring + cal_tDialog ) / 60.0 )- 1) * @MinutoAdicional ) else 0 end
set costo = @MinutoUno + case when ISNULL(totalCall_Time,0) > 0 then((ceiling(( ISNULL(totalCall_Time,0) ) / 60.0 )- 1) * @MinutoAdicional ) else 0 end
,provedor_id = case @provedor_id when 0 then provedor_id else @provedor_id end
,tipoLlamada_id = case @tipoLlamada_id when 0 then tipoLlamada_id else @tipoLlamada_id end
where cal_id = @idCall

set nocount off'
		EXEC(@Sql)

		set @process = 'CW-1382 Version 119.114 -- Alter SP ccspAgent_GetLastCalls'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id int AS
set nocount on

select top 10 c.cal_id as id, ''IN'' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_ani as Telefono, descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, 
convert(varchar(14), dateadd(second, cal_tDialog-cal_tMoh,0), 108) Duracion,
'''' as CallBack, cal_key, c.inbound_id as IDCampEsp
from ccCallsIn c with(nolock index(IX_ccCallsIn_4)) 
inner join ccInbound i on c.inbound_id = i.inbound_id
left join ccTipoCalif cal on c.calif_id = cal.calif_id
left join 
(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer  from ccLogTransfers where tipo=1  group by cal_id,tipo ) as t  
 on c.cal_id=t.cal_id 

where user_id = @user_id
and cal_inicio > dateadd(hh, -3, getdate())


Union

select top 10 c.cal_id as id, ''OUT'' as Tipo,convert(varchar(10), cal_inicio, 108) as Hora,cal_telefono as Telefono,cam_descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, 
 CONVERT(varchar(8), DATEADD(ss, 
	cal_tDialog -	 case when t.tAntesXfer is null then cal_tMoh else cal_tMoh-t.tAntesXfer end 	+ isnull( t.tDespuesXfer ,0)	
	, 0), 114)  as Duracion,
 	isnull(convert(varchar(16), cal_fcallback, 121) ,'''') as CallBack, cal_key, c.cam_id as IDCampEsp
from ccoCallsOut c
inner join ccCamps o on c.cam_id = o.cam_id
left join ccTipoCalifOut cal on c.calif_id = cal.calif_id
left join  
(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer from ccLogTransfers where tipo=2 group by cal_id,tipo) as t  
on c.cal_id=t.cal_id 

where user_id = @user_id
and cal_inicio > dateadd(hh, -3, getdate())

order by hora desc

set nocount off '
    	EXEC(@Sql)

		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
