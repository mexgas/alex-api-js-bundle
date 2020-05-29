/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Hugo Longoria, 
Date: 2017/11/07
Description:
	*CW-1143-Bugfix munoz. Cambios para almacenar los tiempos de dialogo y notas correctamente


Database: CCenterRia
Required version: 119.09-4

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
set @versionfix = 101
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and (@actualVersionFix = 94 or @actualVersionFix = 101 )
	begin
		begin tran
		begin try

		set @process = 'Setting 200 para cadena en marcaciones no efectivas. CW-1143-Bugfix munoz'
		set @Sql= 'if not exists(select * from ccsettings where setting_id=200)
insert ccsettings (setting_id,valor,descripcion,status,tipo,detalle,description,bloadsettings,validate) 
	values (200,''0'',''Cadena de llamada entrante en llamandas manuales no contactadas (Preview)'',1,''AGT'',''Cadena de llamada entrante en llamandas manuales no contactadas (Preview)'',''Incoming call command (preview)'',1,''.*'')
'
    	EXEC(@Sql)
		
		set @process = 'ALTER PROCedure [dbo].[ccsp_AgentUpdateCallTimes] CW-1143-Bugfix munoz'
		set @Sql= 'ALTER procedure [dbo].[ccsp_AgentUpdateCallTimes]
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
	Update ccoCallsOUT with(rowlock) Set cal_tXfer=case when @cal_tXfer > 0 then @cal_tXfer else cal_tXfer end, 
	cal_tDialog=case when @cal_tDialog > 0 then @cal_tDialog else cal_tDialog end, 
	cal_tNotas=case when @cal_tNotas > 0 then @cal_tNotas else cal_tNotas end, 
	cal_tMoh=case when @mtmoh > 0 then @mtmoh else cal_tMoh end,
	cal_tRing=case when @cal_tRing > 0 then @cal_tRing else cal_tRing end, 
	cal_manual=case when @isChatCall=1 then 3 else cal_manual end,
	cal_colgada=0, statusCall_id=13
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
		
    	set @process = 'ALTER PROCedure [dbo].[ccsp_SaveStatusAgent] CW-1143-Bugfix munoz'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus int,
@TipoCall  tinyint,
@Camp smallint,
--@isTransferSurvey bit=0, --0 Callback, 1 Realiza Transferencia inmediata
@callout_id int=0,
@call_id int=0,
@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog int =0 ,
@currentStatus int =-2,--NUEVO PARÁMETRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null
AS
if @Fecha4 is null set @Fecha4 = getdate()

if @TipoCall > 0 set @TipoCall = @TipoCall - 1

if (@User_id > 0 ) begin

	declare @cam_id int,@surveycamId int
	declare @cal_telefono varchar(30)
	declare @cal_key varchar(20)
	declare @inbound_id int
	declare @callBackSurveyClients bit
	declare @cal_whoHung tinyint
	declare @cal_tDialog int
	declare @cal_tNotas int
	declare @cal_tNotaOri int
	declare @tMinAVRS smallint
	declare @calInicio datetime
	declare @sumCall int
	set @cal_tNotas =0
	set @cal_tNotaOri=0
	--4 Dialog,6 Notas, 27 Notas Fallida
	if @TipoStatusAge_id in (4,6,27) and @call_id>0 begin
		if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
		if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas


		if @TipoCall = 0 begin --IN
			select @calInicio=cal_Xfer,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas, @Camp=Inbound_id, @cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas, @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
						from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13

			if @cal_tDialog = 0 and @tDialog >0  and @isLogout=1  begin
				if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
					set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
					if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
					if @TipoStatusAge_id=6  begin
						if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
						else  set @tDialog=@tDialog-1
					end
				end

				update ccCallsIN with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas where cal_id = @call_id and statusCall_id = 13
			end
		end
		else begin --OUT
			select @calInicio=cal_inicio,@sumCall=cal_tXfer+cal_tRing+cal_tDialog+cal_tNotas,
			@cam_id = cam_id,@cal_tDialog=cal_tDialog,@cal_tNotaOri=cal_tNotas from ccoCallsOut where cal_id = @call_id
			set @Camp=@cam_id

			if @cal_tDialog = 0 and @tDialog>0 and @isLogout=1  begin
				if @Fecha4<DATEADD(ss,@sumCall+@tDialog+@cal_tNotas,@calInicio) begin
					set @tStatus= case when @tStatus>0 then @tStatus-1 else @tStatus end
					if @TipoStatusAge_id=4 set @tDialog=@tDialog-1
					if @TipoStatusAge_id=6  begin
						if @cal_tNotas>0 set @cal_tNotas=@cal_tNotas-1
						else  set @tDialog=@tDialog-1
					end
				end

				update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog,cal_tNotas=@cal_tNotas where cal_id = @call_id and statusCall_id = 13
			end
			else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
				update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog where cal_id = @call_id
			else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
				update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas where cal_id = @call_id
		end

		select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

		if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1
		begin
			insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
		end

		if @TipoStatusAge_id in(6,27)  and @isLogout=1  begin
			--Valida que el agente no pudo guardar el status antes de desloguear
			if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
				INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
		end


	end


	if (@TipoStatusAge_id=4) begin-- 4 = Dialogo
		declare @tStatus3 int, @Fecha3 datetime
		select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
		insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
		select @User_id, cam_id, datediff(ms, dateadd(ss, -@tStatus3, @Fecha3), dateadd(ss, -@tStatus, @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
		from cccampsagente where user_id = @User_id


		---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
		if @call_id>0 begin
			if @TipoCall = 0 begin --IN

					select @surveycamid = isnull(cam_id,0),@callBackSurveyClients = callBackSurveyClient  from ccinbound where inbound_id = @inbound_id

					if @surveycamId>0  and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
						if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
							begin
								if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100
								begin
									insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
									values(right((cast(@call_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()) )
								end
							end
					end
			end	--@TipoCall = 0
			else begin	--OUT



				select @surveycamId = isnull(surveycamid,0),@callBackSurveyClients= callBackSurveyClient from cccamps where cam_id = @cam_id
				select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono,@cal_whoHung=cal_whoHung
					from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
					where callout_id = @callout_id and statusCall_id = 13 and cal_id = @call_id

				if @surveycamId>0 and (@callBackSurveyClients=1 or @cal_whoHung=1) begin
					if (select surveyPctg from ccCamps where cam_id = @surveycamId) >= rand() *100
					begin
						insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial)
						values(right((cast(@call_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,0, dateadd(mi, 6, getdate()))
					end
				end
			end
		end--@isTransferSurvey = 0 and @callout_id>0


	 end

	if @TipoStatusAge_id =6  and @isLogout=0
	begin
			--Valida que el ccserver no haya guardado antes el status antes al desloguear
			if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-10,@Fecha4) and @Fecha4 and tStatus = @tStatus+1)
				INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)	VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )
	end
	else
		INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus,callID)	VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall,@currentStatus,@call_id )


	if ( @TipoStatusAge_id = 2 )   -- 2 = No Disponible
	begin
		INSERT ccLogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha, IdCampEsp, Tipo )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4, @Camp, @TipoCall )

		---Para Agente RIA: OAYC
		INSERT ccRIALogAgentesNotReady  ( User_id, TipoNotReady_id, tStatus, fecha )
			VALUES( @User_id, @TipoNotReady, @tStatus, @Fecha4 )
	end

	-- Actualiza para reporte de tiempos especiales (Boan)
	if @Camp > 0
		begin
			if exists (select * from ccLogAgentesDia with(index(IX_ccLogAgentesDia_5),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesDia with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end

			if exists (select * from ccLogAgentesNotReady with(index(IX_ccLogAgentesNotReady_4),nolock)
						where IdCampEsp = 0 and user_id = @User_id)
				begin
					update ccLogAgentesNotReady with(rowlock)
					set IdCampEsp = @Camp, Tipo = @TipoCall
					where IdCampEsp = 0
					and user_id = @User_id
				end
		end
end'
    	EXEC(@Sql)
		
		set @process = 'Fix -- lengh BDF length 2 -> 6'
		set @Sql= 'ALTER procedure [dbo].[ccsp_getVersion]
@Module varchar(3) = null,
@Version int = 0 output
as
set nocount on
declare @Idioma bit
select @Idioma = cast(valor as bit) from ccSettings where setting_id = 27

if upper(isnull(@Module, '''')) not in (''BD'', ''ADM'', ''AGT'', ''ALL'', ''BDF'')
 begin
	select ''-2'' ID, case @Idioma when 0 then ''ERROR. Modulo no valido''
	else ''ERROR. Invalid Module'' end [Description]
	return(0)
 end

declare @nVersion varchar(30)
select @nVersion = cast(valor as varchar(15)) from ccSettings where setting_id = 77

BEGIN TRY
	declare @version_1 varchar(15), @version_2 varchar(9), @version_3 varchar(6), @version_4 varchar(6)
	declare @Prueba table
	 (id int,
	  value nvarchar(100)
	 )
	 insert into @Prueba
		 select * from  fn_RIASplitDelimited (@nVersion,''.'')

	 IF not exists (select value from @Prueba where id = 4) begin

		update ccsettings
		set valor = valor +''.00''
		where setting_Id = 77

		insert into @Prueba (value)
		values(''00'')
	 end

END TRY

BEGIN CATCH
	select ''-1'' ID, ERROR_MESSAGE() [Description]
	return(0)
END CATCH

if isnull(@Version, 0) = 0
 begin

	select @version_1 = value from @Prueba where id = 1
	select @version_2 = value from @Prueba where id = 2
	select @version_3 = value from @Prueba where id = 3
	select @version_4 = value from @Prueba where id = 4

	if upper(@Module) = ''ALL'' or upper(@Module) = ''BDF'' begin
		if  upper(@Module) = ''ALL''
			select @version_1 + ''.'' + @version_2 + ''.'' + @version_3+''.''+ @version_4
		else if  upper(@Module) = ''BDF''
			select @version_1 + ''.'' + @version_4

		return(0)
	end
	else
		select @version = cast(case upper(@Module) when ''BD'' then @version_1
		when ''ADM'' then @version_2 when ''AGT'' then @version_3 end as int)
		select @version Version
		return(@version)

 end

--return

if upper(@Module) = ''BD'' and (@Version <= cast(@version_1 as int) or (@Version - cast(@version_1 as int))>1)
 begin
	select ''-3'' ID, case @Idioma when 0
	then ''ERROR. Version no Valida para BD. Version Actual: '' + @version_1
	else ''ERROR. Invalid Version for BD. Current Version: '' + @version_1
	end [Description]
	return(0)
 end

if @Version <= cast(case upper(@Module) when ''BD'' then @version_1
when ''ADM'' then @version_2 else @version_3 end as int)
 begin
	select ''-3'' ID, case @Idioma when 0
	then ''ERROR. Version no Valida para '' + @Module + ''. Version Actual: '' +
	 case upper(@Module) when ''BD'' then @version_1 when ''ADM'' then @version_2 else @version_3 end
	else ''ERROR. Invalid Version for '' + @Module + ''. Current Version: '' +
	 case upper(@Module) when ''BD'' then @version_1 when ''ADM'' then @version_2 else @version_3 end
	end [Description]
	return(0)
 end



	select @version_1 = value from @Prueba where id = 1
	select  @version_2 =value from @Prueba where id = 2
	select @version_3 = value from @Prueba where id = 3
	select @version_4 = isnull(max(value),0) from @Prueba where id = 4


if upper(@Module) = ''BD'' set @version_1 = @Version
else if upper(@Module) = ''ADM'' set @version_2 = @Version
else if upper(@Module) = ''AGT'' set @version_3 = @Version
else set @version_4 = @Version

set @nVersion = @version_1 + ''.'' + @version_2 + ''.'' + @version_3 + ''.'' + @version_4
update ccSettings set valor = @nVersion where setting_id = 77


if @@rowcount = 1
	select ''0'' ID, ''Actualizado a version: '' + @nVersion [Description]

else
	select ''-4'' ID, case @Idioma when 0
	then ''ERROR generado al actualizar a version '' + @nVersion
	else ''ERROR introduced when upgrading to version '' + @nVersion
	end [Description]

return (0)
set nocount off'
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