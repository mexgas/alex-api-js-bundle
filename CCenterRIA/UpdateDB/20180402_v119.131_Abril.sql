/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Alan Minor
Date: 2018/04/02
Description:



Database: CCenterRia
Required version: 119.119.124

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
set @versionfix = 131
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 123
	begin
		begin tran
		begin try

	 
		set @process = 'Bug de tiempo duplicado en totalCall_time'
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
	cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end,
	totalCall_Time=case when totalCall_Time is null then @cal_tDialog else totalCall_Time end 
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


		set @process = 'Bug de tiempo duplicado en totalCall_time '
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
		if @tdespues > 0 begin
				select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tdespues
				update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
		end
	end
	else begin
		if not exists (select * from ccLogTransfers where cal_id = @cal_id and tipo = @tipo)
			insert into ccLogTransfers(cal_id,tipo,modo,destino,tAntesXfer,tDespuesXfer,fechaFin) values ( @cal_id, @tipo, @modo, @destino, 0, @tantes, getdate() )

		if @tipo = 2 begin
			if @modo = 5 begin
				select @callout_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
				select @cal_id = (select cal_id from ccoCallsOut where callout_id = @callout_id)
				update ccLogTransfers set tDespuesXfer = @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2), tAntesXfer = @tdespues + (select tAntesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2) where cal_id = @cal_id and tipo = 2
			end
		
			if @modo in (0,1,2) begin
				select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
				update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
			end
		end

		else begin
			if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
				select @callout_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
				select @cal_id = (select cal_id from ccoCallsOut where callout_id = @callout_id)
				select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes
				update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
			end
		end
	end
	if not exists(select * from ccAVRSTransfer where cal_id=@cal_id and tipo= @tipo-1) begin
		insert into ccAVRSTransfer (cal_id,tipo) values(@cal_id,@tipo-1)
	end
end

else if @action = 2 begin	
	if (select callout_id from ccCallsIn where cal_id = @cal_id) <> 0 begin
		select @callout_id = (select callout_id from ccCallsIn where cal_id = @cal_id)
		select @cal_id = (select cal_id from ccoCallsOut where callout_id = @callout_id)
		update ccLogTransfers set tDespuesXfer = @tdespues + @tantes + (select tDespuesXfer from ccLogTransfers where cal_id = @cal_id and tipo = 2) where cal_id = @cal_id and tipo = 2
		select @totalCall_Time = ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0) + @tantes + @tdespues
		update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
	end
end

else if @action = 4 begin
	select @totalCall_Time = ISNULL((select sum(tincall) from IVRCallsIn where callout_id = @cal_id), 0) + ISNULL((select totalCall_Time from ccoCallsOut where cal_id = @cal_id), 0)
	update ccoCallsOut set totalCall_Time = @totalCall_Time where cal_id = @cal_id
end'
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
