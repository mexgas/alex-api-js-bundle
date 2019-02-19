/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Armando Rodriguez
Date: 2017/04/26
Description:
	CW-2092 ccsp_GalateaCallbacksDays Returns days with callbacks made by an agent
Database: CCenterRia
Required version: 120.24

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

set @version = 121--**********actualizar a 119 sin fix
set @versionfix = 31
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version  and  @actualVersionFix = 24
	begin
		begin tran
		begin try	


	set @process = 'CW-2525 Deshardcodear ícono de llamada en historial y llamada manual'
    set @Sql= '
ALTER PROCEDURE [dbo].[ccsp_RIACampsManualCall]
		@UserID int,
		@onChat int = 0
		AS
		set nocount on

		if (@onChat = 0)
		begin
			declare @mod smallint
			select @mod = defCampaing from ccRIACat_Areas A
			where A.IDArea = (select IDArea from ccUsers where User_id = @UserID) 

			select distinct c.cam_id, c.cam_descripcion, case when ca.cam_id=@mod then 1 else 0 end [isDefault],  g.graphic_id
			from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
			join ccRIACampsGraph g ON g.cam_id = c.cam_id
			where ca.user_id = @UserID and cam_modoManual = 1
			order by cam_descripcion
		end
		else
			select distinct c.cam_id, c.cam_descripcion,  g.graphic_id
			from ccCamps c with(index(PK_ccCamps)) join ccCampsAgente ca on c.cam_id=ca.cam_id
			join ccRIACampsGraph g ON g.cam_id = c.cam_id
			where ca.user_id = @UserID and manualCallOnChat = 1
			order by cam_descripcion

set nocount off'
    EXEC(@Sql)


	set @process = 'CW-2525 Deshardcodear ícono de llamada en historial y llamada manual'
    set @Sql= '
	ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id int AS
set nocount on

declare @lastCallAgt table(
id int not null,
tipo varchar(10) not null,
Hora varchar(10) not null,
Telefono varchar(55) not null,
EspCamp varchar(55) not null,
Calificacion varchar(60),
Duracion varchar(10) not null,
CallBack varchar(60),
cal_key varchar(20),
IDCampEsp smallint not null,
prefijo varchar(maX) null,
GraphicID int 
)
insert into @lastCallAgt
select top 10 c.cal_id as id, ''IN'' as Tipo, convert(varchar(10), cal_inicio, 108) as Hora, cal_ani as Telefono, descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, 
convert(varchar(14), dateadd(second, 
cal_tDialog - cal_tMoh 
    +  case when stopRecording=0 then isnull( t.tDespuesXfer ,0) else 0 end
,0), 108) Duracion,
'''' as CallBack, cal_key, c.inbound_id as IDCampEsp,ISNULL(ccInbound.prefijo,'''') Prefijo,
graph.graphic_id GraphicID
from ccCallsIn c with(nolock index(IX_ccCallsIn_4)) 
join ccRIAInboundGraph graph on graph.Inbound_id = c.Inbound_id
inner join ccInbound on ccInbound.Inbound_id=c.Inbound_id
left join ccTipoCalif cal on c.calif_id = cal.calif_id
left join 
(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer  from ccLogTransfers where tipo=1  group by cal_id,tipo ) as t  
 on c.cal_id=t.cal_id 
where user_id = @user_id and cal_inicio > dateadd(hh, -3, getdate())
order by c.cal_inicio desc


insert into @lastCallAgt
select top 10 c.cal_id as id, ''OUT'' as Tipo,convert(varchar(10), cal_inicio, 108) as Hora,cal_telefono as Telefono,cam_descripcion as EspCamp, 
isnull(cal.Description, '''') as Calificacion, 
 CONVERT(varchar(8), DATEADD(ss, 
    cal_tDialog - cal_tMoh 
    +  case when stopRecording=0 then isnull( t.tDespuesXfer ,0) else 0 end
    , 0), 114)  as Duracion,
    isnull(convert(varchar(16), cal_fcallback, 121) ,'''') as CallBack, cal_key, c.cam_id as IDCampEsp , ISNULL(ccCamps.prefijo,'''') Prefijo,
	graph.graphic_id GraphicID
from ccoCallsOut c
inner join ccCamps on ccCamps.cam_id=c.cam_id
left join ccRIACampsGraph graph on graph.cam_id = c.cam_id
left join ccTipoCalifOut cal on c.calif_id = cal.calif_id
left join  
(select cal_id,tipo,sum(tAntesXfer) as tAntesXfer,sum(tDespuesXfer) as tDespuesXfer from ccLogTransfers where tipo=2 group by cal_id,tipo) as t  
on c.cal_id=t.cal_id 

where user_id = @user_id and cal_inicio > dateadd(hh, -3, getdate())
order by c.cal_inicio desc

select * from @lastCallAgt
order by hora desc

set nocount off 


'
    EXEC(@Sql)

    set @process = 'CW-2568 Deshardcodear conexión segura - eliminar funcion split'
    set @Sql= 'IF OBJECT_ID(''dbo.splitstring'') IS NOT NULL
				BEGIN
				DROP FUNCTION splitstring
				END'
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