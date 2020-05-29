/*
Autor: Raymundo Gonzalez
Fecha: 2014/07/09
Descripcion:
	Se inserta registro en la tanla ccmenus para menu de catalogo de cuentas de correo de salida de email
	Se inserta registro en la tabla ccsettings para setting de envio de callkey al hacer una transferencia a un ACD
	Se inserta registro en la tabla ccsettings para setting para reproducir audio cuando llegue mensaje de chat al agente
	se modifica el setting 131 para parametros  DTMF y cliente kamailio
	Se elimina y crea nuevo constraint en la tabla cccamps en el campo cam_graba y se actualiza su valor default a 1
	Se modifica el SP ccsp_AgentUpdateCallTimes para optimizacion de consultas
	Se modifica el SP ccsp_CstoCalculaCosto para optimizacion de consultas
	Se modifica el SP ccsp_RIABlackListLog para fix en busqueda de historial de listas negras
	Se modifica el SP ccsp_OUTUpdateDialJob para cambio de prioridad en callbacks
	Se modifica el SP ccsp_RIA_ABCACDGroups para fix al eliminar Grupos ACD
	Se modifica el SP ccsp_RIAAdmDelRegs para eliminar registros a traves del callkey
	Se modifica el SP ccsp_RIAGetCampsNvosCB para fix en informacion de cubetas del Administrador
	Se modifica el SP ccsp_RIAUpdateCallBack_Abandon para completar numeros que deberan ser marcados como callbacks
	Se modifica el SP xx_OUTInsertNewJOBS_WT_Camp para fix por espacios en los telefonos
	Se modifica el SP ccsp_AgentUpdateCallCALIF para validar que el numero a ingresar en la lista negra no se null
	Se modifica el SP ccsp_RIACATMenu para validacion de nuevos menus
	Se modifica el SP ccsp_RIAConfEspec para validaciones de servicio de email
	Se modifica el SP ccsp_RIAMenuRoles para seleccion de menus
	Se modifica el SP ccsp_RIAManageWG para para finder no muestra agentes nuevos asignados al workgroup
	Se modifica el Job ShrinkLogCCenterRia para fix de sintaxis
	
Version requerida: 108
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '109'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccmenus - Insert'
		set @Sql='insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF)  
values(82,''Catalogo de cuentas de correo de salida|Catalogo de cuentas de correo de salida'',16,''B'',40,1,'''')'
	
	EXEC(@Sql)

		set @process = 'ccsettings - Insert'
		set @Sql='if not exists (select * from ccsettings where setting_id = 161)
	begin
		insert into ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings)
		values(161,''0'',''Envia CallKey al hacer una transferencia a un ACD'',1,''AGT'',''0 no construye paquete para enviar CallKey y datos, 1 construye paquete'',''Send Callkey when use transfer to ACD'',1)
	end'
	
	EXEC(@Sql)

		set @process = 'ccSettings - Insert 2'
		set @Sql='insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings) 
values (162,''2'',''Reproducir sonido al llegar mensaje chat del cliente'',1,''AGT'',''0 sin sonido, 1,2,3 y 4 son los valores diferentes para los nuevos sonidos'',''Play chat audio tone'',1)'
	
	EXEC(@Sql)

	set @process = 'ccSettings - update Mizuphone'
		set @Sql='update ccsettings set valor= valor + ''|4||0'', detalle = ''Configuración para Mizuphone: CODEC|STUN|RPORT|LOG|SpeakerVol|MicroVol|DTMF|Cliente|FawLocalIp CODEC(1:G711U,2:G711A,3:G729) STUN(-1:Forzar IP privada,0:No,1:NAT simetrica,2:siempre,3:usar aun en ip publica) RPORT(0:No,1:NAT simetrica,2:siempre,3:aun en ip publica,9:peticion con señalizacion) LOG(0:Sin Log, 5:Activado) SpeakerVol|MicroVol(Volumen 0-100) DTMF(0:disabled,1:sipINFO,2:RFC2833 in RTP,3:BOTH,4:RFC2833 only) Cliente(Client for Kamailio) FawLocalIp(0:disabled,e.g:10.)'' where setting_id=131'
	
	EXEC(@Sql)

		set @process = 'ccCamps - Drop Constraint'
		set @Sql='alter table ccCamps drop constraint DF_ccCamps_cam_graba'
	
	EXEC(@Sql)

		set @process = 'ccCamps - Add Constraint'
		set @Sql='alter table ccCamps add constraint DF_ccCamps_cam_graba DEFAULT (1) FOR cam_graba'
	
	EXEC(@Sql)

		set @process = 'ccCamps - Update'
		set @Sql='update ccCamps set cam_graba=1 where cam_NoInt_graba>0'
	
	EXEC(@Sql)

		set @process = 'ccsp_AgentUpdateCallTimes - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_AgentUpdateCallTimes]
@IDCall int,
@cal_tXfer smallint,
@cal_tDialog smallint,
@cal_tNotas smallint,
@TipoCall tinyint,
@cal_tRing smallint=0,
@mtmoh smallint = 0,
@isChatCall bit = 0
AS
set nocount on
if @IDCall<=0 
	return(0)

declare @tMinAVRS smallint

if @TipoCall=1 --INBOUND
 begin
    If @mtmoh > 0
		Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
		 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, cal_tMoh=@mtmoh Where cal_id= @IDCall
    Else
       Update ccCallsIN with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
		 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13 Where cal_id= @IDCall

 
	-- Elimina callback generado por abandono
	Declare @ANI_x varchar(19)
	select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

	DELETE ccoWorkingTable with(rowlock) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
 end

if @TipoCall=2 --OUTBOUND
 begin
   If @mtmoh > 0
	Update ccoCallsOUT with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
	 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13,  cal_tMoh=@mtmoh, cal_manual=case when @isChatCall=1 then 3 else cal_manual end 
	 Where cal_id=@IDCall
   Else 
    Update ccoCallsOUT with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
	 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=13, cal_manual=case when @isChatCall=1 then 3 else cal_manual end 
	 Where cal_id=@IDCall

	-- calcula el costo de la llamada
	exec ccsp_CstoCalculaCosto @IDCall
 end

select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

if @cal_tDialog >= @tMinAVRS
 begin
	insert ccAVRSTransfer (cal_id, tipo) values (@IDCall, @TipoCall - 1)
	return(0)
 end

set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_CstoCalculaCosto - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_CstoCalculaCosto]
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
		set costo =  t.MinutoUno + case when cco.cal_txfer + cco.cal_tring + cco.cal_tDialog > 0 then((ceiling(( cco.cal_txfer + cco.cal_tring + cco.cal_tDialog ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
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
	set costo =  t.MinutoUno + case when cco.cal_txfer + cco.cal_tring + cco.cal_tDialog > 0 then((ceiling(( cco.cal_txfer + cco.cal_tring + cco.cal_tDialog ) / 60.0 )- 1) * t.MinutoAdicional ) else 0 end
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

update ccoCallsOut with(rowlock) set costo = @MinutoUno + 
case when cal_txfer + cal_tring + cal_tDialog > 0 then((ceiling(( cal_txfer + cal_tring + cal_tDialog ) / 60.0 )- 1) * @MinutoAdicional ) else 0 end
,provedor_id = case @provedor_id when 0 then provedor_id else @provedor_id end
,tipoLlamada_id = case @tipoLlamada_id when 0 then tipoLlamada_id else @tipoLlamada_id end
where cal_id = @idCall

set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIABlackListLog - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIABlackListLog]
@command tinyint,
@date varchar(22) = null,
@idtipomov int = 0,
@telephone varchar(15) = null,
@Scam_id varchar(1000) = ''0'',
@GenCSV tinyint,
@endDate varchar(22) = null
AS
set nocount on
declare @sql as nvarchar (4000), @params nvarchar(1000), @newDate nvarchar(22)

If @command=1
 begin
	select idtipomov, movimiento from cctipomovslistanegra
	return(0)
 end

set @params = ''@Ndate varchar(22), @Nidtipomov varchar(1),@Ntelephone varchar(20)''

select @sql = case @GenCSV when 1 then ''select '' else ''select top 200 '' end

select @newDate = convert(varchar(8), Cast(@endDate AS smalldatetime), 112)

set @sql = @sql + '' idhistorial, isnull(callout_id,'''''''') as callout_id, telefono, fecha, isnull(cam_descripcion,'''''''') as campaña, movimiento, a4.Tipolista 
from cchistoriallistanegra a1 
inner join cctipomovslistanegra a2 on (a1.idtipomov=a2.idtipomov) 
left join cccamps a3 on (a1.cam_id=a3.cam_id)
inner join cctiposlistanegra a4 on (a1.idtipolista = a4.idtipolista) 
where fecha between @Ndate and '' + nchar(39) + @newDate + '' 23:59:59'''' ''
+ case isnull(@idtipomov, 0) when ''0'' then '''' else '' and a1.idtipomov = @Nidtipomov '' end
+ case isnull(@telephone, 0) when ''0'' then '''' else '' and telefono = @Ntelephone '' end
+ case isnull(@Scam_id, 0) when ''0'' then '''' else '' and a1.cam_id in ('' + @Scam_id + '') '' end

execute sp_executesql @sql, @params,@Ndate=@date,@Nidtipomov=@idtipomov,@Ntelephone=@telephone

return(0)

set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_OUTUpdateDialJob - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
@callout_id int,
@CallResultDial tinyint
as
set nocount on
/*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine	*/
declare @nOcupado tinyint, @nNoContesta tinyint, @nFax tinyint, @nContestadora tinyint
declare @nShortCall tinyint, @nOtro tinyint, @cam_NoInt_ocupado tinyint, @cam_NoInt_graba tinyint
declare @cam_ocupado smallint, @cam_inter_ocupado smallint, @cam_nocontesto smallint
declare @cam_graba smallint, @cam_inter_graba smallint, @cam_inter_nocontesto smallint
declare @cam_fax smallint, @cam_inter_fax smallint
declare @DateNextDial smalldatetime, @DateNewDial smalldatetime, @cam_id smallint
declare @ExisteWT tinyint, @cam_NoInt_fax tinyint, @cam_NoInt_nocontesto tinyint
declare @sSQL nvarchar(max), @Telefono varchar(15)

SELECT @cam_id=cam_id, @nOcupado=IsNull(nOcupado, 0), @nNoContesta=IsNull(nNoContesta,0),
	@nFax=IsNull(nFax, 0), @nContestadora=IsNull(nContestadora, 0),@nShortCall=IsNull(nShortCall,0),
	@nOtro=IsNull(nOtro,0),@DateNextDial=cal_fechaDial
FROM ccoWorkingTable WHERE callout_id = @callout_id

select @ExisteWT=case when @cam_id is not null then 1 else 0 end


IF @CallResultDial=20 -- CONTACTADO
 BEGIN
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial=1 -- CONTESTO
 BEGIN
	if (select abandonCallback from ccCamps where cam_id = @cam_id) = 1 begin
		EXEC ccsp_OUTCancelDialJOB @callout_id, 1, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	end
	else begin
		EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	end
	return(0)
 END

IF @CallResultDial in (2,12) -- OCUPADO
 BEGIN
	SELECT @cam_ocupado =cam_ocupado, @cam_inter_ocupado=cam_inter_ocupado, @cam_NoInt_ocupado=cam_NoInt_ocupado, @nOcupado= @nOcupado+1
	FROM ccCamps WHERE cam_id=@cam_id
	
	IF @cam_ocupado=1 -- Opcion Ocupado HABILITADA
	 BEGIN
		IF @nOcupado>@cam_NoInt_ocupado or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		-- Change priority and obtain the next telephone
		update ccoCallsOutSource set nNoContesta=case when nNoContesta < 255 then isnull(nNoContesta,0)+1 else nNoContesta end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT
		
		SELECT @DateNewDial=dateadd(mi, @cam_inter_ocupado, getdate())

		-- Programacion de CALLBACK
		IF @DateNewDial>@DateNextDial
		 BEGIN	-- Nueva fecha de Call BACk
			UPDATE  ccoWorkingTable SET nOcupado=@nOcupado, cal_fechaDial=@DateNewDial, cal_status=1 WHERE callout_id = @callout_id
			return(0)
		 END

		-- Mantiene la fecha de Call BACK
		UPDATE  ccoWorkingTable SET nOcupado=@nOcupado, cal_status=1, cal_telefono=@Telefono  WHERE callout_id = @callout_id

		return(0)
	 END

-- ELSE: Opcion Ocupado DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
  END

IF @CallResultDial in (3,5,8) -- NO CONTESTA
 BEGIN
	--select NO Contesta
	SELECT @cam_nocontesto =cam_nocontesto, @cam_inter_nocontesto=cam_inter_nocontesto, @cam_NoInt_nocontesto=cam_NoInt_nocontesto, @nNoContesta=@nNoContesta+1
	FROM ccCamps WHERE cam_id=@cam_id

	--SELECT @cam_nocontesto, @cam_inter_nocontesto, @cam_NoInt_nocontesto, @nNoContesta
	IF @cam_nocontesto=1 -- Opcion NoContesta HABILITADA
	 BEGIN
		--select No Contesta Habilitada
		IF @nNoContesta>@cam_NoInt_nocontesto or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		-- Change priority and obtain the next telephone
		update ccoCallsOutSource set nNoContesta=case when nNoContesta < 255 then isnull(nNoContesta,0)+1 else nNoContesta end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT

		SELECT @DateNewDial=dateadd(mi, @cam_inter_nocontesto, getdate())
		-- Programacion de CALLBACK
		UPDATE ccoWorkingTable SET nNoContesta =@nNoContesta, cal_status=1, cal_telefono=@Telefono, 
		cal_fechaDial=case when @DateNewDial>@DateNextDial then @DateNewDial else cal_fechaDial end
		WHERE callout_id = @callout_id

		return(0)
	 END

	-- Opcion NoContesta DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial=4 -- Fax/Modem
 BEGIN
	SELECT @cam_fax =cam_fax, @cam_inter_fax=cam_inter_fax, @cam_NoInt_fax=cam_NoInt_fax, @nFax=@nFax +1
	FROM ccCamps WHERE cam_id=@cam_id

	IF @cam_fax=1 -- Opcion Fax/Modem HABILITADA
	 BEGIN
		IF @nFax>@cam_NoInt_fax or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		-- Change priority and obtain the next telephone
		update ccoCallsOutSource set nFax=case when nFax < 255 then isnull(nFax,0)+1 else nFax end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT

		SELECT @DateNewDial=dateadd(mi, @cam_inter_fax, getdate())

		-- Programacion de CALLBACK
		UPDATE ccoWorkingTable SET nFax =@nFax, cal_status=1, cal_telefono=@Telefono,
		cal_fechaDial=case when @DateNewDial>@DateNextDial then @DateNewDial else cal_fechaDial end
		WHERE callout_id = @callout_id

		return(0)
	 END

	-- Opcion Fax/Modem DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial=11 -- Maquina Contestadora
 BEGIN
	SELECT @cam_graba =cam_graba, @cam_inter_graba=cam_inter_graba, @cam_NoInt_graba=cam_NoInt_graba, @nContestadora=@nContestadora+1
	FROM ccCamps WHERE cam_id=@cam_id

	IF @cam_graba=1 -- Opcion Maquina Contestadora HABILITADA
	 BEGIN
		IF @nContestadora>@cam_NoInt_graba or @nShortCall>4
		 BEGIN
			EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
			return(0)
		 END

		 -- Change priority and obtain the next telephone
		 update ccoCallsOutSource set nContestadora=case when nContestadora < 255 then isnull(nContestadora,0)+1 else nContestadora end
			,dial_tels = cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)) 
			+ replace(''2345NNN'',cast(case when cast(substring(dial_tels,1,1) as tinyint) < 5 then cast(substring(dial_tels,1,1) as tinyint)+1 else 1 end as varchar(1)),''1'')
			WHERE callout_id=@callout_id
		select @sSQL=''select @outA=rtrim(left(ltrim(cal_telefono'' + case substring(dial_tels,1,1) when 1 then '''' else substring(dial_tels,1,1) end + ''+''''         ''''+'' 
            + ''cal_telefono'' + case substring(dial_tels,2,1) when 1 then '''' else substring(dial_tels,2,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,3,1) when 1 then '''' else substring(dial_tels,3,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,4,1) when 1 then '''' else substring(dial_tels,4,1) end + ''+''''         ''''+''
            + ''cal_telefono'' + case substring(dial_tels,5,1) when 1 then '''' else substring(dial_tels,5,1) end + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id=''
			+cast(@callout_id as varchar(15)) from ccocallsoutsource nolock where callout_id=@callout_id
		exec sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA=@Telefono OUTPUT

		SELECT @DateNewDial=dateadd(mi, @cam_inter_graba, getdate())

		-- Programacion de CALLBACK
		UPDATE ccoWorkingTable SET nContestadora =@nContestadora, cal_status=1, cal_telefono=@Telefono,
		cal_fechaDial= case when @DateNewDial>@DateNextDial then @DateNewDial else cal_fechaDial end
		WHERE callout_id = @callout_id
		
		return(0)
	 END

	-- Opcion Maquina Contestadora DESHABILITADA
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

IF @CallResultDial=10 --No Dial Tone, otros, NoService
 BEGIN
	EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
	return(0)
 END

return(0)
set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIA_ABCACDGroups - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIA_ABCACDGroups]
@option smallint,
@userid int,
@descripcion varchar(40),
@inbound_id varchar(1000),
@idarea smallint = null,
@frame tinyint
as
set nocount on
declare @new_inbound_id smallint, @graph_id smallint

if @option = 0 -- all acd
 begin
	 select acd.inbound_id, acd.descripcion, isnull(acd.idarea,0) as idarea,
	isnull(areas.areaname,'''') as areaname
	 from ccinbound as acd with(nolock)
	 left join dbo.ccriacat_areas as areas with(nolock) on acd.idarea = areas.idarea
	 return(0)
 end

if @option = 1 -- select acd
 begin
	 select a1.inbound_id, a1.descripcion, a3.frame, a1.showcalifwnd, a1.starttimeronhangup, isnull(a1.idarea,0), isnull(a1.cam_id,0) cam_id
	 from ccinbound a1 
	  inner join ccriainboundgraph a2 on (a1.inbound_id=a2.inbound_id)
	  inner join ccriagraphics a3 on (a2.graphic_id=a3.graphic_id)
	 where a3.type_id = 1 and a1.inbound_id = (cast(@inbound_id as int))
	 order by descripcion
	 return(0)
 end

if @option = 2 -- insert
 begin
	if exists (select descripcion from ccinbound where descripcion = @descripcion and status = 1)
	 begin
			select -1--, ''nombre en uso''
			return(0)
	 end
	
	if @idarea = 0
	set @idarea = null
	
	insert into ccinbound (descripcion, starttimeronhangup, idarea, showcalifwnd)
	select @descripcion, 1, @idarea, case when exists(select calif_id from cctipocalif) then 1 else 0 end
	
	if @@rowcount = 1
		select @new_inbound_id = inbound_id from ccinbound where descripcion = @descripcion and status = 1

	else
	 begin
		select -2 -- Error al insertar
		return(0)
	 end

	insert into cccalifcamp (calif_id, cam_id, tipo) select calif_id, @new_inbound_id, 0 from cctipocalif where CanReprogram=0 and Calif_Status = 1

	if not exists (select msg_id from ccInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccMsgFiles where msgFile like ''%\Default%''))
	 begin
		insert into ccInboundMsgs (msg_id, inbound_id, orden, type, queue)
		select msg_id, @new_inbound_id, 0, cast(substring(msgFile, 19,3) as integer),0 from ccMsgFiles where msgFile like ''%\Default%''
	 end

	if not exists (select msg_id from ccRIAChatInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccRIAChatMsg where Descripcion like ''%\Default%''))
	 begin
		insert into ccRIAChatInboundMsgs (msg_id, inbound_id, orden, type)
		select msg_id, @new_inbound_id, 0, cast(substring(Descripcion, 19,3) as integer) from ccRIAChatMsg where Descripcion like ''%\Default%''
	 end

	if not exists(select frame from ccriagraphics where frame = @frame and type_id = 1)
	 insert into ccriagraphics (frame,type_id) values (@frame,1)
	
	 select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
	 
	 insert into ccriainboundgraph(Inbound_id,graphic_id) values(@new_inbound_id,@graph_id)
	 select @new_inbound_id
	 return(0) 
 end

if @option = 3 -- update
 begin
	 if not exists (select frame from ccriagraphics where frame=@frame and type_id=1)
		insert into ccriagraphics (frame, type_id) values (@frame, 1)

	 select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
	 update ccinbound set descripcion = @descripcion where inbound_id = (cast(@inbound_id as int))
	 update ccriainboundgraph set graphic_id = @graph_id where inbound_id = (cast(@inbound_id as int))
	 return(0)
 end

if @option = 4 -- delete
 begin
	 delete cccalifcamp where cam_id = @inbound_id and tipo = 0
	 delete ccinboundhorarios where inbound_id = @inbound_id
	 delete ccriainboundgraph where inbound_id = @inbound_id
	 delete ccInboundMsgs where inbound_id = @inbound_id
	 delete ccRIAChatInboundMsgs where inbound_id = @inbound_id
	 delete ccinbound where inbound_id = @inbound_id
	 return(0)
 end

if @option = 5 -- asignar campaña a ACD
 begin
	if not exists (select inbound_id from ccInbound where inbound_id=@inbound_id) or
	 (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
		not exists (select cam_id from ccCamps where cam_id=@descripcion))
	 begin
		select -3 -- Campaña o ACD invalido
		return(0)
	 end
	
	if @descripcion=0
		set @descripcion = null
	
	update ccInbound set cam_id = @descripcion where Inbound_id = @inbound_id
		
	if @@rowcount=0
		select -4 -- Error al actualizar

	return(0)
 end
set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIAAdmDelRegs - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAAdmDelRegs]
	@tipoDel int, -- 1 Registros Nuevos / 2 Registros CallBack / 3 Registros sin meter a WT / 4 Registros CallBack - Excepto los programados por Agentes
	@cam_id int,
	@phone varchar(30) = '''',
	@calkey varchar(20) = '''',
	@exact bit = 1
	AS

	if @tipoDel = 1 --nuevos
	 begin
		delete ccoWorkingTable with(rowlock) where cam_id = @cam_id and cal_status = 0
	 end

	if @tipoDel = 2 --callbacks
	 begin
		delete ccoWorkingTable  with(rowlock) where cam_id = @cam_id and cal_status = 1
	 end

	if @tipoDel = 3 -- 3 Registros sin meter a WT
	 begin
		update ccocallsoutsource with(rowlock)
		set cal_Status = 5 
		where cam_id = @cam_id 
		and cal_status in(0, 7)
		
		Delete ccUploadTemporal with(rowlock) where cam_id = @cam_id
	 end

	if @tipoDel = 4 --callbacks
	 begin
		delete ccoWorkingTable with(rowlock) where cam_id = @cam_id and cal_status = 1 and user_id=0
	 end

	if @tipoDel = 5 --callbacks
	 begin
		delete ccoWorkingTable with(rowlock) where cam_id = @cam_id and cal_status = 3
	 end

	if @tipoDel = 6 -- Delete a record from a specific campaign containing a specific phone number
	begin	
		delete ccoWorkingTable with(rowlock) 
		where callout_id in (select isnull(callout_id,0) 
								from ccocallsoutsource with(nolock)
								where cam_id = @cam_id 
								and (cal_telefono = @phone or 
										cal_telefono2 = @phone or 
										cal_telefono3 = @phone or 
										cal_telefono4 = @phone or 
										cal_telefono5 = @phone))

		update ccocallsoutsource with(rowlock)
		set cal_Status = 5 
		where callout_id in (select isnull(callout_id,0) 
								from ccocallsoutsource with(nolock)
								where cam_id = @cam_id 
								and (cal_telefono = @phone or 
										cal_telefono2 = @phone or 
										cal_telefono3 = @phone or 
										cal_telefono4 = @phone or 
										cal_telefono5 = @phone))
	end

	if @tipoDel = 7 -- Delete all the records from a specific campaign
	begin
		delete from ccoWorkingTable with(rowlock) where cam_id = @cam_id

		update ccocallsoutsource with(rowlock) set cal_Status = 5 where cam_id = @cam_id
	end

	if @tipoDel = 8 --delete records by specific callkey
	 begin
		if @exact = 1
			delete ccoWorkingTable with(rowlock) where cal_keyw = @calkey and cal_status <> 2
		else
			delete ccoWorkingTable with(rowlock) where cal_keyw like ''%'' + @calkey + ''%'' and cal_status <> 2
	 end'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIAGetCampsNvosCB - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB] @cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0 as
set nocount on

declare @regval as int



-- Actualiza todas las camps
if @Tipo=2
	begin
		declare @ultimo as datetime,@id AS INTEGER

		select @ultimo = isnull( convert(datetime, valor, 121), dateadd(hh, -1, getdate() ) ) from ccSettings where setting_id = 21

		if datediff(ss, @ultimo, getdate()) > 120
			begin
				CREATE TABLE #Tcamps
				(cam_id int,
				cantidad int)

				DECLARE CCamp CURSOR FOR 
				select cam_id from ccCamps

				Open CCamp
				Fetch Next From CCamp
				Into @id
				if @@FETCH_STATUS = 0
					Begin 
						While @@FETCH_STATUS = 0
							Begin 
								EXEC @regval = ccsp_OUTGetNewJobs @id,2,0

								INSERT #Tcamps
								select @id,@regval
								Fetch Next From CCamp
								Into  @id
							End
					End
				CLOSE CCamp
				DEALLOCATE CCamp

				UPDATE ccSettings set valor = convert( varchar(23), getdate(),121) where setting_id = 21

				delete ccCampsNvosCB

				INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial)
				SELECT cams.cam_id, cams.cam_descripcion, 
				isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb, 
				isNull(cs.Pend,0) as pend,
				isNull(wt.Pro,0) as pro,
				isNull(cams.cam_procesando,0) cam_procesando, 
				isNull(cams.cam_tipojobs,0) cam_tipojobs,
				isNull(wt.Fin,0) Fin,
				isNull(tc.cantidad,0) cantidad
				FROM ccCamps cams with(nolock)
				LEFT JOIN
				(
					SELECT cam_id,
					count(case cal_status when 0 then 1 else null end) as New,
					count(case cal_status when 1 then 1 else null end) as Cb,
					count(case cal_status when 2 then 1 else null end) as Pro,
					count(case cal_status when 3 then 1 else null end) as Fin
					FROM ccoworkingtable with(nolock)
					GROUP BY cam_id
				) wt on cams.cam_id = wt.cam_id
				LEFT JOIN
				(
					SELECT cam_id, count(cam_id) as Pend
					FROM ccocallsoutsource with(nolock index(IX_ccoCallsOutSource))
					WHERE cal_status in(0, 7)
					GROUP BY cam_id
				) cs on cams.cam_id = cs.cam_id
				left join #Tcamps tc on (tc.cam_id = cams.cam_id)

				drop table #Tcamps
			end

		-- devuelve resultado de la taba, solo las camps del usuario
		SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, res.st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial
		FROM ccCampsNvosCB res
		LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
		WHERE res.id in(select cam_id from ccSupervisorCam where tipo = 1 and user_id = @user_id)

		return(0)
	end

-- Actualiza una camp
if @Tipo=1
	begin
		exec @regval = ccsp_OUTGetNewJobs @cam_id,2,0

		delete ccCampsNvosCB with(rowlock) where id = @cam_id

		INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial)
		SELECT cams.cam_id, cams.cam_descripcion, 
		isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb, 
		isNull(cs.Pend,0) as pend,
		isNull(wt.Pro,0) as pro,
		isNull(cams.cam_procesando,0) cam_procesando, 
		isNull(cams.cam_tipojobs,0) cam_tipojobs,
		isNull(wt.Fin,0) Fin,
		isnull(@regval,0) NextDial
		FROM ccCamps cams with(nolock)
		LEFT JOIN
		(
			SELECT @cam_id as cam_id,
			count(case cal_status when 0 then 1 else null end) as New,
			count(case cal_status when 1 then 1 else null end) as Cb,
			count(case cal_status when 2 then 1 else null end) as Pro,
			count(case cal_status when 3 then 1 else null end) as Fin
			FROM ccoworkingtable with(nolock index(IX_ccoWorkingTable))
			WHERE cam_id = @cam_id

		) wt on cams.cam_id = wt.cam_id
		LEFT JOIN
		(
			SELECT @cam_id as cam_id, count(cam_id) as Pend
			FROM ccocallsoutsource with(nolock index(IX_ccoCallsOutSource_11))
			WHERE cal_status in (0,7) 

			AND cam_id = @cam_id
		) cs on cams.cam_id = cs.cam_id
		WHERE cams.cam_id = @cam_id

		-- devuelve resultado de la taba
		SELECT id, campaña, new, cb, pro, pen,st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial
		FROM ccCampsNvosCB res

		LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
		WHERE res.id = @cam_id

		return(0)
	end

set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIAUpdateCallBack_Abandon - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]
@cal_id int,
@nStatus tinyint
as
set nocount on

declare @ANI varchar(13), @cam_id int, @inbound_id int, @fechadial varchar(40), @callout_id int, 
 @statuscall_id_Array varchar(1000), @minCallBackAbandon smallint

select @ANI=C.cal_ANI, @cam_id=I.cam_id, @inbound_id=I.inbound_id, 
@statuscall_id_Array=statuscall_id_Array, @minCallBackAbandon=minCallBackAbandon
from cccallsin C join ccInbound I on I.Inbound_id=C.Inbound_id where cal_id=@cal_id

select @fechadial=convert(varchar(16), dateadd(minute, @minCallBackAbandon, getdate()), 121)

if @nStatus not in (select value from dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','')) or isnull(@cal_id,0)=0
 return(0)

if isnull(@cam_id, 0)=0
	return(0)

select @ANI = dbo.completa(@ANI)

if (select substring(@ANI,1,1))= ''E''
	return(0)

if exists (select cal_ANI from ccRIAUpdateCallBack_Abandon where cal_ANI=@ANI)
	return(0)

 begin try
	insert ccRIAUpdateCallBack_Abandon (cal_id, cal_ANI, cam_id, callout_id, inbound_id, minCallBackAbandon)
	select @cal_id, @ANI, @cam_id, @callout_id, @inbound_id, @fechadial

	select @ANI=dbo.completa(@ANI)
	exec ccsp_INInsertaCallBack @cal_id, @cam_id, @ANI, @fechadial, ''Callback by abandon'', @fechadial, '''', '''', '''', 1, 0, 1

	select top 1 @callout_id=callout_id from ccoWorkingTable WITH(INDEX(PK_ccoWorkingTable)) WHERE cal_telefono=@ANI
	select @fechadial=dateadd(minute, minCallBackAbandonXpire, @fechadial) from ccInbound where Inbound_id=@inbound_id
	update ccRIAUpdateCallBack_Abandon set callout_id=@callout_id, minCallBackAbandonXpire=@fechadial where cal_id=@cal_id
	return(0)
 end try

 begin catch
	return(0)
 end catch
set nocount off'
	
	EXEC(@Sql)

		set @process = 'xx_OUTInsertNewJOBS_WT_Camp - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[xx_OUTInsertNewJOBS_WT_Camp]
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
FROM ccoCallsOutSource with( index(IX_ccoCallsOutSource_1), nolock)
WHERE cam_id = @camp_id and (cal_status <2 or cal_status=7) -- Nuevos Jobs

--la prioridad establecidad (si existe) 
select @prioridad = NULL
select @prioridad = Prioridad from ccCampsPrioridadTel (nolock) where cam_id = @camp_id

UPDATE ccoCallsOutSource SET cal_status = 3, dial_tels = isNull( @prioridad, ''12345NNN''), nOcupado=0, nNoContesta=0, nFax=0, nContestadora=0, nShortCall=0, nOtro=0
where cal_status in (0, 1, 7) and cam_id = @camp_id'
	
	EXEC(@Sql)

		set @process = 'ccsp_AgentUpdateCallCALIF - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_AgentUpdateCallCALIF]
@IDCall int,
@calif_id smallint,
@TipoCall smallint,
@Origin int=0,
@cal_key varchar(20)=null,
@callOutId int=0,
@subId smallint=0
as
set nocount on
declare @RecicleSIC tinyint, @Reprogram tinyint, @DateNewDial smalldatetime, @idTipoLista int, @autoCB tinyint, @tel varchar(30), @camp int, @iddncList as int
declare @userid int
select @RecicleSIC=valor FROM ccSettings WHERE setting_id=60
select @RecicleSIC=IsNull(@RecicleSIC, 0)

if @TipoCall=1
 begin
	Update ccCallsIN Set calif_id=@calif_id, cal_origin_id=@Origin, cal_key=isnull(@cal_key, cal_key), 
	califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall
	return(0)
 end

if @TipoCall=2
 begin
 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @autoCB=autocallback from ccTipoCalifSubout where califSub_Id = @subId
	
	-- Si no tiene subcalificacion toma la de la calificacion
	if @autoCB is null
	 begin
		select @autoCB = autocallback from cctipocalifout where calif_id = @calif_id
	 end

	if @autoCB = 1
	begin
		select @callOutId=callout_id, @camp=cam_id,@userid=user_id from ccocallsout where Cal_id=@IDCall
		select @DateNewDial=dateadd(mi,t_autoCB,getdate()) from cccamps cam where cam.cam_id = @camp

		exec ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
	end

	Update ccoCallsOUT Set calif_id=@calif_id, califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall

	if exists(select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id)
	and not exists (select co.cal_telefono from ccoCallsOut co with (index (PK_ccoCallsOut))
	join ccListaNegra bl on dbo.Completa_ListaNegra(co.cal_telefono)=bl.telefono or co.cal_telefono=bl.telefono where co.cal_id=@idCall
	and bl.idtipolista in (select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id))
	 begin		
		select @tel=dbo.Completa_ListaNegra(co.cal_telefono), @iddncList = cbl.idTipoLista 
		from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
		where co.cal_id=@idCall and dbo.Completa_ListaNegra(co.cal_telefono)<>''E_NV_Longitud'' and cbl.tipo=1


		if @tel is not null and @iddncList is not null begin
			exec ccsp_InsertDNCList @tel, @iddncList

			insert ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			select dbo.Completa_ListaNegra(co.cal_telefono), cbl.idTipoLista, co.cam_id, getdate(), co.callout_id, 6
			from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
			where co.cal_id=@idCall and dbo.Completa_ListaNegra(co.cal_telefono)<>''E_NV_Longitud'' and cbl.tipo=1
		end
	 end

	if @RecicleSIC=1
	 begin
	 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
		select @Reprogram=CanReprogram from ccTipoCalifSubout where califSub_Id = @subId
		
		-- Si no tiene subcalificacion toma la de la calificacion
		if @Reprogram is null
		 begin
			select @Reprogram=CanReprogram from ccTipoCalifOUT where calif_id=@calif_id
		 end

		if @callOutId=0
			select @callOutId=callout_id from ccocallsout where Cal_id=@IDCall

		Update ccoWorkingTable Set calif_id=@calif_id, 
		 cal_status=case @Reprogram when 0 then 3 else cal_status end
		Where callout_id=@callOutId

	 end
	declare @keepDial bit
	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @keepDial=keepDial from ccTipoCalifSubout where califSub_Id = @subId
	
	-- Si no tiene subcalificacion toma la de la calificacion
	if @keepDial is null
	 begin
		select @keepDial=keepDial from ccTipoCalifout where calif_id = @calif_id
	 end

	if @keepDial=1
	 begin
		update ccologdials set TipoDialingMode=dbo.fn_getDialingMode(@IDCall, 3, 0, @camp) 
		where logDial_id in (select top 1 L.logDial_id from 
			ccoLogDials L with(index(IX_ccoLogDials_2), nolock) 
			 join ccoCallsOut O with(index(PK_ccoCallsOut), nolock) 
			 on L.callout_id = O.callout_id where O.cal_id=@IDCall
			order by L.logDial_id desc)
	 end
	 
	select @keepDial
	return(0)
 end

set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIACATMenu - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
Declare @AVRS tinyint
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenusChat tinyint
Declare @MenuMail tinyint

set @MenuMail=0

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155

---Mail MenuId (81)
if @Type=1
begin
	if @ReportRol = 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
		and (
		(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82)) 
		or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
		or (menu_id in (71,72) and @IVRScripting = 1)
		or (menu_id in (73,74,75,76) and @AVRS = 1)
		or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
		or (menu_id = 79 and @MenusChat > 0)
		or (menu_id in (81,82) and @MenuMail = 1)--Mail
		)
		order by ordengral asc
		return(0)
		
	end
	else if @ReportRol = 3 begin
		select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) and menu_id not in (select distinct Parent from ccMenus where menu_id >= 2000 and type = 3)
		and (menu_id not in (3131,3132,3133,3134,3135,3136,8061,8062,8063,8071,8072,8080))
		or  (menu_id     in (3131,3132,3133,3134,3135,3136) and @MenusChat > 0 )
		or  (menu_id     in (8061,8062,8063,8071,8072,8080) and @AVRS > 0)
		order by ordengral asc
		return(0)
	end
	else begin	
		select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)
	end
	
end

if @Type=2
begin
  delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu and type = @ReportRol
  return(0)
end

if @Type=3
begin
  insert into ccMenuUser(id_User,id_Menu,type) values (@id_User, @id_Menu,@ReportRol)
  return(0)
end

if @Type=4
begin
  declare @lan varchar(3), @page varchar(200)
  select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
  select @lan = case valor when 0 then ''ES'' else ''EN'' end from ccSettings where setting_id = 27
  
  select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
  return(0)
end

set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIAConfEspec - Alter Procedure'
		set @Sql='ALTER procEDURE [dbo].[ccsp_RIAConfEspec] 
@User_id int 
AS 
set nocount on

declare @sql nvarchar(max)

if not exists (SELECT * FROM sysobjects WHERE type = ''U'' AND name = ''ContactMeanIn'') begin
	set @sql=''select A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd, 
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat, A.inactiveChatTime, A.maxChats, A.chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
A.startStopRecording,'''''''' as nameMail,'''''''' as conexionInfo,'''''''' as connUser,'''''''' as connPass,3 as numMessages,10 as timeAlertMessage
from ccInbound A where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (''+convert(nvarchar(max),@User_id)+'', 2))''	

end
else begin
	set @sql=''select A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd, 
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat, A.inactiveChatTime, A.maxChats, A.chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
A.startStopRecording,isnull(B.name,'''''''') as nameMail,isnull(B.conexionInfo,'''''''') as conexionInfo,isnull(B.connUser,'''''''') as connUser,
isnull(B.ConnPass,'''''''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage
from ccInbound A 
left join ContactMeanIn B on A.inbound_id=B.inboundId
where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (''+convert(nvarchar(max),@User_id)+'', 2))''
	end

exec (@sql)

return(0)
set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIAMenuRoles - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAMenuRoles]
@Type tinyint,
@User_id smallint = null,
@Role_id smallint = null,
@InsertMenu_id smallint = null,
@DeleteMenu_id smallint = null,

@firstSup smallint = null,
@reportRol tinyint = 1,
@AVRS tinyint = null,
@CM tinyint = 0,
@AE tinyint = 0
as
set nocount on

select @reportRol = case @reportRol when 0 then 1 else @reportRol end, @role_id = case @role_id when 0 then 1 else @role_id end



Declare @NRS tinyint
declare @MenusChat tinyint
declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenuMail tinyint

set @MenuMail=0


select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

---Checar si esta se aplica
select @AVRS = valor from ccSettings where setting_id = 124
select @IVRScripting = valor from ccsettings where setting_id = 125

select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
--Activa menus relacionados con campañas
select @MenusChat = valor from ccsettings where setting_id = 145
select @MenuMail = valor from ccsettings where setting_id = 155

If @Type = 1 -- Carga todos los roles
 begin
      select Role_id, Description from ccRIACat_AdminRole where type = @reportRol order by priority
      return(0)
 end

If @Type = 2 -- Carga los menus de un supervisor
 begin
  Select a.id_User, a.id_Menu, b.menu_descrip, Nivel, ordengral 
  from ccMenuUser a inner join ccMenus b with(index(IX_ccMenus)) on a.id_Menu = b.menu_id and a.type = b.type
  where id_User = @User_id and a.Type = @reportRol and ((a.id_Menu not in (41,42, 53)) or 
  (a.id_Menu = 41 and @CM = 1) or (a.id_Menu = 42 and @AE > 0) or (a.id_Menu = 53 and @NRS = 1))
  order by ordengral asc
  return(0)
 end

If @Type = 3 -- Return the menus of a rol
 begin
  select a.Role_id, b.menu_id, b.menu_descrip, b.Nivel, b.ordengral 
  from ccRIARoleMenu a inner join ccMenus b with(index(IX_ccMenus)) on b.menu_id = a.id_Menu and a.type = b.type
  where a.Role_id = @Role_id and 
  a.type = @reportRol and 
  ((b.menu_id not in (41,42,53)) or (b.menu_id = 41 and @CM = 1) or (b.menu_id = 42 and @ae > 0) or (b.menu_id = 53 and @NRS = 1))
  order by a.Role_id, b.ordengral asc
  return(0)
 end

If @Type = 4 -- Insert 
 begin	
	if (@InsertMenu_id <> 0) or not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
	begin	
		if @Role_id in (1, 10, 14) begin			
			if @InsertMenu_id <> 0 and not exists(select * from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
				insert into ccMenuUser (id_User, id_Menu, type) values(@User_id, @InsertMenu_id, @reportRol)
			if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40)begin						
				Insert into ccMenuUser (id_User, id_Menu, type)values(@User_id,40,@reportRol)		
			end
			else If @reportRol = 2 and not exists(select id_User from ccMenuUser where id_User = @User_id and (id_Menu between 1000 and 1999)) begin					
					Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, menu_id, @reportRol from ccMenus with(index(IX_ccMenus)) where menu_id between 1000 and 1999
				end
			else if @reportRol = 3 begin				
				insert into ccMenuUser (id_User, id_Menu, type) select @User_id, id_Menu, @reportRol from ccRIARoleMenu  where Role_id = @Role_id 			 			
			end
		end
		else if ((@InsertMenu_id = 53 and @NRS = 1) or (@InsertMenu_id <> 53) ) 
		begin			
			if @InsertMenu_id <> 40	delete ccMenuUser where id_User = @User_id and type = @reportRol		
				insert into ccMenuUser (id_User, id_Menu, type)	select @User_id, id_Menu, @reportRol from ccRIARoleMenu where Role_id = @Role_id and type = @reportRol
			if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40 and type = @reportRol)
				insert into ccMenuUser (id_User, id_Menu, type) values(@User_id,40,@reportRol)
		end		
	end		
	--Asigna un rol por default o lo actuliza
	if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
	else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
	
	--Solo es necesario en caso admin y reports
	if @reportRol in(1,2) begin 
		--    inserta parent en caso de no haberlo hecho en rol personalizado        
		insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from               
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
		where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0

		select @User_id, parent, @reportRol from               
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
		where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0
		
	end
	return (0)
 end

If @Type = 5 -- delete
 begin
      delete ccMenuUser where id_User = @User_id and id_Menu = @DeleteMenu_id and type = @reportRol
      if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
      else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
      return(0)
 end

If @Type = 6 -- Get userMenus
 begin
	if @reportRol = 2 begin --Reports version vieja
		select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
      from ccRIAUserRole a inner join ccMenuUser b on a.user_id = b.id_user
       inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
      where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol and 
      ((b.id_Menu not in (41,42,53)) or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)) 
		and ( b.id_Menu not in(77,78) or (@RelationCampInbNotReady = 1 and b.id_Menu in(77,78)))  
		and ( b.id_Menu not in(79) or (@MenusChat > 0 and b.id_Menu in(79)))  
	  order by ordengral asc
      return(0)
	end
	else begin ---Sitio del administrador
		if not exists( select * from ccRIAUsr_AdminPermissions where User_id=@user_id and per_id=6)
		set @AVRS =0
		
		select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
      
	  from ccRIAUserRole a 
		inner join ccMenuUser b on a.user_id = b.id_user
		inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
      where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol 
		and (	
			(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82)) 
			or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)
			or (menu_id in (71,72) and @IVRScripting = 1)		
			or (menu_id in (73,74,75,76) and @AVRS = 1)
			or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
			or (menu_id = 79 and @MenusChat > 0)
			or (menu_id in (81,82) and @MenuMail = 1)--Mail
			)
      order by ordengral asc
		return(0)
	end
 end

If @Type = 7 -- Get language
 begin
      select valor from ccSettings where setting_id = 27
      return(0)
 end

If @Type = 8 -- Insert the personalized menus of a supervisor
 begin
      insert into ccMenuUser (id_User, id_Menu, type)
      select @User_id, id_Menu, @reportRol from ccMenuUser where id_User = @firstSup and type = @reportRol

      If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
       begin
            Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
            return(0)
       end

      insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
      return(0)
 end

If @Type = 9 -- Delete all supervisor menus 
 begin
      delete ccMenuUser where id_User = @User_id and type = @reportRol
      return(0)
 end

If @Type = 10 -- update all supervisor menus 
 begin
      update ccUsers set tipoUser_id = @AVRS where user_id = @User_id 
      return(0)
 end

If @Type = 11 -- Verify level A menus
 begin
 --   inserta parent en caso de no haberlo hecho en rol personalizado        
      Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from 
      (select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
      where m.menu_id in (1000,2000,3000,4000) and u.id_User = @User_id and u.type = @reportRol
      group by m.parent) parent where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

      return(0)
 end

If @Type = 12
 begin
      declare @lan as tinyint
      select @lan = valor from ccSettings where setting_id = 27
      select menu_descrip from ccMenus with(index(IX_ccMenus)) where menu_id = @Role_id
      return(0)
 end
 
 if @Type = 13 --Agrega Menus por default a Admin en ReportsRia Agentes,ACD y Campañas
 begin
	insert into ccMenuUser([id_user],[id_Menu],[type])
	select a.User_id, b.menu_id, b.type 
		from ccUsers a cross join ccMenus b
		left join ccMenuUser d on d.id_User = a.User_id and d.id_Menu = b.menu_id	
		where a.TipoUser_id = 2 and b.type = 3 and d.id_User IS null and 
		b.menu_id >= 2000 and b.menu_id < 5000 and a.User_id = @User_id

	insert into ccRIAUserRole([User_id],[Role_id],[type])
		select a.[User_id], 14 as role_id, 3 as type from ccUsers a
			left join ccRIAUserRole d on d.User_id = a.User_id and d.type = 3
			where d.User_id IS null and a.TipoUser_id = 2 and a.User_id = @User_id
				
	return (0)
	
 end

return(0)
set nocount off'
	
	EXEC(@Sql)

	set @process = 'ccsp_RIAManageWG - Alter Procedure'
	set @Sql='ALTER PROCedure [dbo].[ccsp_RIAManageWG]
@option smallint,
@IDWG smallint,
@Type smallint,
@UserId smallint,
@Descripcion varchar(25),
@IDArea as int
as
set nocount on

if @option = 3 -- Insert WokGroup
 begin
	Insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
	select @IDWG = scope_identity()
			
	Insert into ccRIAAreaWorkGroup(IDWG, IDArea) values(@IDWG, @IDArea)
	select @IDWG
	return(0)
 end

select @Type = TipoUser_id from ccUsers where User_id = @UserId

if @option = 1 -- Insert Agente-Supervisor in WorkGroup
 begin
	if @Type not in(1, 2, 6)
		return(0)

	if exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @UserId)
	 begin
		 select 1
		 return(0)
	 end

	If @Type = 1
	 begin
		
		If (select count(User_id) from ccRIAWorkGroupUsers where User_id = @UserId) > = (select valor from ccSettings where setting_id = 63)
		 begin
			select 3
			return(0)
		 end

		insert into ccRIAWorkGroupUsers(IDWG, User_id) values(@IDWG,@UserId)		

		if @IDWG is null or @IDWG = 0
		 begin
			select 38
			return(0)
		 end
		 
		insert into cccampsAgente (user_id, cam_id, prioridad, skill, IDWG)
		select @UserId, idCampEsp, dbo.fn_Calcula_UsrPriority(@UserId,0), 1, @IDWG
		from ccRIACampEspWG where tipo = 1 and IDWG = @IDWG and 
		 idCampEsp not in (select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

		insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, IDWG)
		select @UserId, idCampEsp, 0, dbo.fn_Calcula_UsrPriority(@UserId,0), 1, @IDWG
		from ccRIACampEspWG where tipo = 0 and IDWG = @IDWG and 
		 idCampEsp not in (select inbound_id from ccInboundAgentes where user_id=@UserId and IDWG=@IDWG)

		if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@UserId) begin	
			insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@UserId)
		end
		return(0)
	 end	

	-- -Supervisor	@Type in (2,6)
	insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @UserId)
	if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@UserId) begin	
		insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@UserId)
	end

	insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
	select @UserId, idCampEsp, 0, @IDWG 
	from ccRIACampEspWG where tipo=0 and IDWG=@IDWG 
	 and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

	update ccSupervisorCam
	set monitored = 1
	where user_id = @UserId
	and cam_id in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)
	and tipo = 0
	and IDWG <> @IDWG
	and monitored = 0

	insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
	select @UserId, idCampEsp, 1, @IDWG
	from ccRIACampEspWG where tipo=1 and IDWG=@IDWG 
	 and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)

	update ccSupervisorCam
	set monitored = 1
	where user_id = @UserId
	and cam_id in (select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
	and tipo = 1
	and IDWG <> @IDWG
	and monitored = 0

	return(0)
 end

if @option = 2 -- Delete Agent-Supervisor from WorkGroup
 begin
	Delete ccRIAWorkGroupUsers where IDWG = @IDWG and User_id = @UserId

	if @Type = 1 -- Agente
	 begin
		delete from cccampsagente where user_id=@UserId and IDWG=@IDWG
		delete from ccInboundagentes where user_id=@UserId and IDWG=@IDWG
		select @Type
		return(0)
	 end
	 
	--else if @Type in(2, 6) -- Supervisor
 	delete ccSupervisorCam where user_id=@UserId and IDWG=@IDWG
	select @Type
	return(0)
end
return(0)
set nocount off'

	EXEC(@Sql)


		set @process = 'ShrinkLogCCenterRia - Delete and Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ShrinkLogCCenterRia]    Script Date: 07/09/2014 19:44:44 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''ShrinkLogCCenterRia'')
EXEC msdb.dbo.sp_delete_job @job_name=N''ShrinkLogCCenterRia'', @delete_unused_schedule=1

/****** Object:  Job [ShrinkLogCCenterRia]    Script Date: 07/02/2014 00:05:42 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 07/02/2014 00:05:42 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ShrinkLogCCenterRia'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Shrink Log DB CCenterRia'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Call Center Activity Task]    Script Date: 07/02/2014 00:05:43 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Call Center Activity Task'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
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
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Database Integrity Task]    Script Date: 07/02/2014 00:05:43 ******/
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
		@command=N''DBCC CHECKDB WITH NO_INFOMSGS'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Checkpoint DB]    Script Date: 07/02/2014 00:05:43 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Checkpoint DB'', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''CHECKPOINT'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Log Task]    Script Date: 07/02/2014 00:05:43 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Log Task'', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKFILE(''''ccenter_Log'''',1)'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Weekly'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20000101, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)

	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			exec dbo.ccsp_getVersion 'BD', @Version

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
