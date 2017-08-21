/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Armando Rodriguez
Date: 2017/04/26
Description:
	CW-1087 Setting de Cola mensajeria
	CW-1058 Programar notReady en la maquina de estados

Database: CCenterRia
Required version: 119.74

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

set @version = 119--**********actualizar a 129 sin fix
set @versionfix = 81
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and (@actualVersionFix = 7 or @actualVersionFix = @versionfix)
	begin
		begin tran
		begin try

    set @process = 'CW-1087 Setting de Cola mensajeria'
    set @Sql= 'if not exists(select * from ccsettings where setting_id = 199) begin
	insert ccsettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
	values(199,''127.0.0.1|0|/|adminNuxiba|Nuxiba2017'',''Parámetros para cola mensajería'',1,''AGT'',
		''Configuracion rabbit IP|Port|VirtualHost|User|Password)'',''Parameters for messenger queue'',0,''.*'')
end'
    EXEC(@Sql)

    set @process = 'CW-1058 Programar notReady en la maquina de estados'
    set @Sql= 'ALTER procedure [dbo].[ccsp_RIAGetSelectedNotReady]
@user_id int = 0,
@tipoNR int

AS

-- Para horarios depues de las 12 de la noche
declare @inicioTurno integer
declare @fecha smalldatetime
declare @fStart datetime
declare @fEnd datetime
declare @AcumTime int

set @inicioTurno = 2 --Cambio de dia a las 2 de la mañana
set @fecha = getdate()
if datepart( hh,  @fecha ) > @inicioTurno - 1
begin	
	set @fStart = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
	set  @fEnd = dateadd( d,1, @fstart )
end
else
begin
	set @fEnd = convert( datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
	set  @fStart = dateadd( d,-1, @fEnd )
end

select @AcumTime =isnull( sum(tStatus),0)  from ccRIALogAgentesNotReady where fecha between @fStart and @fEnd and tiponotready_id=@tipoNR and (user_id = @user_id)

select a1.tiponotready_id,descripcion, frame, time_acum, time_xev,  pas_sup, nextstatus, @AcumTime as AcumTime, 
dbo.NeventsNRdisp(@user_id, nextstatus, getdate())  as NeventsNRdisp
 from cctiponotready a1
inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
where a1.tiponotready_id=@tipoNR
'
    EXEC(@Sql)

    set @process = ''
    set @Sql= ''
    EXEC(@Sql)

    set @process = ''
    set @Sql= ''
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
