/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Alan Minor 
Date: 2018/03/01
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
set @versionfix = 123
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 122
	begin
		begin tran
		begin try

	 

		set @process = 'CW-934 -- Creacion de tabla nueva DataCallIn'
    	set @Sql= 'if not exists (select * from sys.tables where name = N''DataCallIn'')
    begin
        create table DataCallIn (CallId int, Data varchar(100) null, Description varchar(100), primary key(CallId,Description))
    end'
    	EXEC(@Sql)

		set @process = 'CW-934 -- Validar si existe el SP ccsp_RIAUpdateDataCallIn'
    	set @Sql= 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateDataCallIn'')
    begin
        DROP PROCEDURE ccsp_RIAUpdateDataCallIn;
    end'
    	EXEC(@Sql)

		set @process = 'CW-934 -- Crear el SP ccsp_RIAUpdateDataCallIn'
    	set @Sql= 'CREATE procedure [dbo].[ccsp_RIAUpdateDataCallIn]
@calloutid int,
@callid int,
@typecall smallint,
@data1 varchar(100),
@data2 varchar(100),
@data3 varchar(100),
@data4 varchar(100),
@data5 varchar(100)

AS

if @typecall = 1 --Inbound 
begin
	Update DataCallIn set Data=@data1 where CallId=@callid and Description = ''Dato 1''
	Update DataCallIn set Data=@data2 where CallId=@callid and Description = ''Dato 2''
	Update DataCallIn set Data=@data3 where CallId=@callid and Description = ''Dato 3''
	Update DataCallIn set Data=@data4 where CallId=@callid and Description = ''Dato 4''
	Update DataCallIn set Data=@data5 where CallId=@callid and Description = ''Dato 5''
end
	
if @typecall = 2 --Outbound 
begin
	update ccocallsoutsource set Dato1 = @data1,
			Dato2 = @data2,
			Dato3 = @data3,
			Dato4 = @data4,
			Dato5 = @data5 where callout_id = @calloutid
end'
    	EXEC(@Sql)

		set @process = 'CW-934 -- Modificar el SP spInsertCall'
    	set @Sql= 'ALTER PROCEDURE [dbo].[spInsertCall]
@Pto smallint,
@DNIS varchar(14),
@ANI as varchar(14),
@inbound_id smallint=0,
@IVR_id int = 0, --Id del IVR
@CALLDATA as varchar(500) = ''''
AS
declare @dni_id as smallint
declare @cal_id as int
declare @datacall as varchar(100)

select @Ani = left(rtrim(ltrim(@ANI)), 13)
select @DNIS = rtrim(ltrim(@DNIS))

	--busca dni_id
	select @dni_id = isnull ( ( select dni_id From ccDNIS Where dni_numero =  @DNIS and dni_status = 1 ), 0)
	
	--busca especialidad
	IF @inbound_id =0 and @dni_id >0
		select @Inbound_id=ED.Inbound_id from ccInboundDnis ED where ED.dni_id = @dni_id
	
	INSERT ccCallsIN ( cal_ANI, dni_id, cal_puerto, cal_Inicio, inbound_id, IVR_id )
	VALUES ( @ANI, @dni_id, @Pto, getdate(), @inbound_id, @IVR_id )

	select @cal_id = scope_identity()

	IF @inbound_id > 0 
	BEGIN
		insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
		select idwg, cal_id, 0 as user_id, getdate() timestamp, 0 as tipo from cccallsin cc
		right join dbo.ccRIACampEspWG wg on (wg.idcampesp = cc.inbound_id )
		where wg.tipo = 0 and cal_id = @cal_id
	END

	IF @CALLDATA <> ''''
	--select @CALLDATA
	BEGIN
		set @CALLDATA=SUBSTRING(@CALLDATA,0,len(@CALLDATA)-2)
		insert into DataCallIn (CallId, Data, Description) 
		select @cal_id,value,''Dato ''+cast(id as varchar(max)) from dbo.[fn_RIASplitDelimited](@CALLDATA,''~'')
	END

	Select ''IDCall''=@cal_id, ''IDdnis''=@dni_id'
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
