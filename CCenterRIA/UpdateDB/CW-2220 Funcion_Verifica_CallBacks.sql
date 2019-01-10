/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
		
Date: 
Description:

Database: CCenterRia
Required version: 

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

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 22
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 15
	begin
		begin tran
		begin try
			

		set @process = 'CW-2220 Funcion Verifica CallBack '
		set @Sql= 'if not exists (select * from sys.columns where name = N''telFormato'' and Object_ID = Object_ID(N''ccinbound''))
	    begin
			alter table ccinbound add telFormato tinyint null
	    end'
		EXEC(@Sql)
	

		set @process = 'CW-2220 Funcion Verifica CallBack alter SP ccsp_RIAAbandon_Config'
        set @Sql= '
        ALTER procedure [dbo].[ccsp_RIAAbandon_Config]
@Type smallint, -- 1:Muestra ACD | 2:Muestra Tiempos y Status (ACD) | 3:Actualiza Configuracion
@User_id smallint,
@Inbound_id smallint=null,
@minCallBackAbandon varchar(10)=null,
@minCallBackAbandonXpire varchar(10)=null,
@statuscall_id_Array varchar(1000)=null,
@telFormato TinyInt= null

as
set nocount on
declare @IDarea smallint
select @IDarea=IDarea from ccUsers where user_id=@user_id

if isnull(@IDarea,'''')=''''
 begin
	select -1, ''invalid user area''
	return(0)
 end

if @Type=1
 begin
	select distinct I.inbound_id, I.descripcion, A.frame, C.cam_procesando
	from ccinbound I join ccRIAinboundGraph G on I.inbound_id = G.inbound_id
	join ccRIAGraphics A on G.graphic_id = A.graphic_id
	join ccCamps C on I.cam_id=C.cam_id
	where A.type_id = 1 and I.cam_id is not null and I.IDArea=@IDarea
	order by descripcion
	return(0)
 end

if not exists(select inbound_id from ccInbound where cam_id is not null and inbound_id=@inbound_id and IDArea=@IDArea)
 begin
	select -2, ''invalid inbound_id''
	return(0)
 end

if @Type=2
 begin
	select @statuscall_id_Array = statuscall_id_Array from ccInbound where inbound_Id=@inbound_Id
	select 0 [type], (minCallBackAbandon/60) setHrs, (minCallBackAbandon-((minCallBackAbandon/60)*60)) setMin, 
	(minCallBackAbandonXpire/60) expHrs, (minCallBackAbandonXpire-((minCallBackAbandonXpire/60)*60)) expMin, 
	null statusCall_id,null descripcion,null chk
	from ccInbound where inbound_id=@Inbound_id
	union
	select 1, null, null, null, null, SL.statusCall_id, SL.descripcion, cast(cast(isnull(F.value,0) as bit)as tinyint) chk
	from ccStatusLLamada SL left join dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','') 
	F on SL.statusCall_id = F.value where SL.inAbandonConfig=1 
	order by [type], descripcion
	return(0)
 end

if @Type=3
 begin
	update ccInbound set 
	 minCallBackAbandon=case when @minCallBackAbandon is null then minCallBackAbandon else @minCallBackAbandon end,
	 minCallBackAbandonXpire=case when @minCallBackAbandonXpire is null then minCallBackAbandonXpire else @minCallBackAbandonXpire end,
	 statuscall_id_Array=case when @statuscall_id_Array is null then statuscall_id_Array else @statuscall_id_Array end,
	 telFormato = case when @telFormato is null then telFormato else @telFormato end	 
	 where inbound_id=@Inbound_id
	return(0)
 end

set nocount off    
   	'
        EXEC(@Sql)        
	

	set @process = 'CW-2220 Funcion Verifica CallBack alter SP ccsp_RIAUpdateCallBack_Abandon'
    set @Sql= '
    ALTER procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]
@cal_id int,
@nStatus tinyint
as
set nocount on
declare @ANI varchar(13), @cam_id int, @inbound_id int, @fechadial varchar(40), @callout_id int, 
 @statuscall_id_Array varchar(1000), @minCallBackAbandon smallint, @pais varchar(2), @ld varchar(5), @telFormat tinyint

declare @lenExt int

select @ANI=C.cal_ANI, @cam_id=I.cam_id, @inbound_id=I.inbound_id, 
@statuscall_id_Array=statuscall_id_Array, @minCallBackAbandon=minCallBackAbandon,@telFormat = I.telFormato
from cccallsin C join ccInbound I on I.Inbound_id=C.Inbound_id where cal_id=@cal_id

select @fechadial=convert(varchar(16), dateadd(minute, @minCallBackAbandon, getdate()), 121)

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @lenExt = case when valor=''''then 0 else valor end from ccSettings with(nolock) where setting_id = 108
if @nStatus not in (select value from dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','')) or isnull(@cal_id,0)=0
 return(0)
 
if isnull(@cam_id, 0)=0
	return(0)

	
--set @ANI =dbo.Limpia(@ANI)
--if @lenExt<>len(@ANI)
--	select @ANI = dbo.completa(@ANI, @pais, @ld)

	if @telFormat = 0
	set @ANI =dbo.Limpia(@ANI)
	else if @telFormat = 1
	select @ANI = dbo.completa(@ANI, @pais, @ld)

if (select substring(@ANI,1,1))= ''E''
	return(0)

if exists (select cal_ANI from ccRIAUpdateCallBack_Abandon where cal_ANI=@ANI)
	return(0)

 begin try
	insert ccRIAUpdateCallBack_Abandon (cal_id, cal_ANI, cam_id, callout_id, inbound_id, minCallBackAbandon)
	select @cal_id, @ANI, @cam_id, @callout_id, @inbound_id, @fechadial
	declare @dato1 varchar (max),  @dato2 varchar (max), @dato3 varchar (max), @dato4 varchar (max), @dato5 varchar (max)
	set @dato1 = ''''	set @dato2 = ''''	set @dato3 = ''''	set @dato4 = ''''	set @dato5 = ''''
	
	select @dato1 = ISNULL(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 1''
	select @dato2 = ISNULL(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 2''
	select @dato3 = ISNULL(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 3''
	select @dato4 = ISNULL(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 4''
	select @dato5 = ISNULL(Data,'''') from DataCallIn where CallId = @cal_id and Description = ''Dato 5''
	
	exec ccsp_INInsertaCallBack @cal_id, @cam_id, @ANI, @fechadial, @dato1,@dato2,@dato3,@dato4,@dato5, 1, 0, 1

	select top 1 @callout_id=callout_id from ccoWorkingTable WITH(INDEX(PK_ccoWorkingTable)) WHERE cal_telefono=@ANI
	select @fechadial=dateadd(minute, minCallBackAbandonXpire, @fechadial) from ccInbound where Inbound_id=@inbound_id
	update ccRIAUpdateCallBack_Abandon set callout_id=@callout_id, minCallBackAbandonXpire=@fechadial where cal_id=@cal_id
	return(0)
 end try

 begin catch
	return(0)
 end catch
set nocount off
   		'
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
