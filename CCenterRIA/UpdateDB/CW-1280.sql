/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Description:	


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
set @versionfix = 102
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and (@actualVersionFix >=101)
	begin
		begin tran
		begin try
		
	 set @process = 'CW-1273 CW-1280 Alter SP ccsp_AgentUpdateCallTimes'
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
    
 
	-- Elimina callback generado por abandono
	Declare @ANI_x varchar(19)
	select @ANI_x=cal_ani from cccallsin with(index(PK_ccCallsIn), nolock) where cal_id=@IDCall

	DELETE ccoWorkingTable with(rowlock	) WHERE callout_id in (select callout_id from ccRIAUpdateCallBack_Abandon with(index(PK_ccRIAUpdateCallBack_Abandon), nolock) where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x
 end

if @TipoCall=2 --OUTBOUND
 begin   
	Update ccoCallsOUT with(rowlock) Set cal_tXfer=@cal_tXfer, cal_tDialog=@cal_tDialog, cal_tNotas=@cal_tNotas, 
	 cal_tRing=@cal_tRing, cal_colgada=0, statusCall_id=case when @isErroManualCall=0 then 13 else statusCall_id end, 
	 cal_tMoh= case when @mtmoh>0 then  @mtmoh else cal_tMoh end, 
	 cal_manual=case when @isChatCall=1 then 3 else cal_manual end 
	 Where cal_id=@IDCall
  select * from ccoCallsOUT Where cal_id=@IDCall

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
		
    	
    	/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		--exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end