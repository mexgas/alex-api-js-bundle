/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2018/10/11
Description:
Database: CCenterRia
Required version: 120.32

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 33
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

if  @actualVersion = @version and  @actualVersionFix = 31
	begin
		begin tran
		begin try

	set @process = 'CW-2376 -- DROP PROCEDURE getPrefixByAcdId'
    	set @Sql= 'if exists (select * from sys.procedures where name = N''getPrefixByAcdId'')
    begin
        DROP PROCEDURE getPrefixByAcdId;
    end'
	EXEC(@sql)

	set @process = 'CW-2376 Create SP getPrefixByAcdId'
    set @Sql= 'CREATE procedure getPrefixByAcdId 
@inboundId int 
as
select isnull(prefijo,'''') from ccInbound where Inbound_id = @inboundId'
    EXEC(@Sql)

	

	set @process = 'CW-2376 -- Alter SP ccsp_IVRGetEspecialidadByDnis'
    set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_IVRGetEspecialidadByDnis] 
@sDnis varchar (40),
@sAni varchar (19) = null
AS
set nocount on
-- Agregamos variables
declare @inbound_id integer, @nMaxQue smallint

set @nMaxQue=0
set @inbound_id=0

if @sDnis =  ''''
	set @inbound_id = 0
else
	select @inbound_id = inbound_id from ccInboundDnis where dni_id in (select dni_id from ccDnis where dni_numero like @sDnis)


if @inbound_id >0 begin
	select @nMaxQue = nMaxQue from ccInbound where inbound_id = @inbound_id
	
	-- Verificamos si el Dnis no esta bloqueado
	if exists (select dni_id from ccDnis where dni_status=1 and dni_isBlock=1 and dni_numero = @sDnis) begin
		select -1 inbound_id, @nMaxQue nMaxQue
		return(0)
	end

	-- Valida si el ani esta en lista negra
	if @inbound_id>0 and  
		exists(select telefono from ACDlistanegra A join ccListaNegra L on A.idtipolista = L.idtipolista where A.status=1 and telefono=@sAni and inbound_id=@inbound_id) begin
		select -1 inbound_id, @nMaxQue nMaxQue
		return(0)
	end

end 

select isNull(@inbound_id, 0) as inbound_id, 0 ''is900'', @nMaxQue nMaxQue
return(0)

set nocount off
        '
    EXEC(@Sql)

	
	
		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
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