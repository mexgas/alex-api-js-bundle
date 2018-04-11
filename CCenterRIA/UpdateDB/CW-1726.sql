/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Alan Minor
Date: 2018/04/10
Description:



Database: CCenterRia
Required version: 119.119.131

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
set @versionfix = 132
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version --and  @actualVersionFix >= 132
	begin
		begin tran
		begin try

		set @process = 'CW-1726 Version 119.124 -- alter SP ccsp_AGENTInsertCallOut'
    	set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_AGENTInsertCallOut]
@cam_id smallint,
@cal_Key varchar(20),
@cal_Telefono varchar(30),
@user_id int,
@cal_extension varchar(7),
@sData varchar(255) = '''', --HLAS para guardar notas de la llamada
@existCallOut as int = 0,
@callmode as smallint = 0
AS
set 
nocount on
declare @fecha as datetime, @callout_id as int, @cal_id as int, @calloutMaxTime as int
select @fecha=getdate()

if @callmode = 1 begin
	INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
	select @existCallOut, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 0, @cal_extension
	select @cal_id = scope_identity()

	insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
	select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
	from ccRIACampEspWG wg 
	where wg.tipo = 1 and wg.idcampesp =@cam_id

	select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
	select @existCallOut as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
  return(0)
end

if @existCallOut=0  begin
	declare @LasCallKey varchar(20)
	set @LasCallKey = @cal_Key
	declare @settingCallKey as int
	select @settingCallKey = valor from ccSettings where setting_id = 194
  
	if(@settingCallKey = 1) begin
		if (@cal_Key='''' or @cal_Key is null) begin   
			select top 1 @LasCallKey=cal_Key from ccoCallsOut where cam_id=@cam_id and cal_Inicio>=convert(datetime,getdate()) and cal_manual=0 order by cal_id desc
			set @cal_Key= @LasCallKey
		end
	end

	INSERT ccocallsoutsource (cal_key, cam_id, cal_telefono, cal_status, user_id, cal_fechaDial, dato1)
	select @cal_Key, @cam_id, substring(@cal_Telefono, 1, 19), 6, @user_id, @fecha, @sData
	select @callout_id = scope_identity()

	INSERT ccoCallsOUT (callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id, user_id, cal_manual, cal_extension) --''Status 11=Iniciada
	select @callout_id, @cam_id, @cal_Key, @cal_Telefono, 0,  @fecha, 11, @user_id, 1, @cal_extension
	select @cal_id = scope_identity()

	
 end

else begin --@existCallOut<>0
	Update ccocallsoutsource set cam_id=@cam_id, cal_telefono=substring(@cal_Telefono, 1, 19), dato1=@sData where callout_id = @existCallOut	
	Update ccocallsout set cam_id=@cam_id, cal_telefono=@cal_Telefono where callout_id = @existCallOut
	
	set @callout_id = @existCallOut

	select top 1 @cal_id=cal_id from ccocallsout where callout_id = @callout_id order by cal_id desc
	 
 end
	
insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo 
from dbo.ccRIACampEspWG wg 
where wg.tipo = 1 and wg.idcampesp =@cam_id


select @calloutMaxTime = cam_tNoContesta from ccCamps where cam_id=@cam_id
select @callout_id as [callout_id], @cal_id as [cal_id], @calloutMaxTime as [calloutMaxTime],@cal_Key as [callKey]
return(0)
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
