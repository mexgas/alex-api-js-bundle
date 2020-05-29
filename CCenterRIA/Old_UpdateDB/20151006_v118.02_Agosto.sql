/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2014/10/06
Description:

--------CREATE TABLE [dbo].[SeriesCOfetel]
--------alter table cccamps 2621-----
--------alter table ccinbound 2621-----
------- -insert into ccSettings  2624--------
-------- insert into ccsettings 2622--------- 
-------- insert into ccSettings ---- insert redes sociales
-------- update ccSettings ------ fix
-------- update cccamps 2621--------
-------- update ccmenus ----------
-------- ALTER function [dbo].[fnGetTipoLlamada] 2621-----
-------- ALTER function [dbo].[fGet_CampAcd_Area] -----------
-------- ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDayForced] 2540
-------- ALTER procedure [dbo].[ccsp_AgentSetCallStatus] 2621
-------- ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp] 2621
-------- ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec] 2621
-------- ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig] 2621
-------- ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig] 2621
--------  ALTER procedure [dbo].[ccsp_RIAUpdateHangUpAgent] 2621
-------- ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent] 2621
-------- ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
-------- ALTER PROCedure [dbo].[ccsp_RIALoadCamps]
-------- ALTER procedure [dbo].[ccsp_OUTcheckTimeZone] 
-------- ALTER procedure [dbo].[ccsp_DLRGetDialInfo]
-------- ALTER PROCEDURE [dbo].[ccsp_IVRChecaInboundHorario]




Database: CCenterRia
Required version: 117

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
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 118 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 118--**********actualizar a 118 sin fix
set @versionfix = 2
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @actualVersion and @actualVersionFix = @versionfix -1
	begin
		begin tran
		begin try

		set @process = 'CREATE TABLE [dbo].[SeriesCOfetel] 2624-------- '
		set @sql='if not exists (select * from sys.tables where name = N''SeriesCOfetel'')
	begin
		CREATE TABLE [dbo].[SeriesCOfetel](
	[CLAVE CENSAL] [varchar](255) NULL,
	[POBLACION] [varchar](255) NULL,
	[MUNICIPIO] [varchar](255) NULL,
	[ESTADO] [varchar](255) NULL,
	[PRESUSCRIPCION] [varchar](255) NULL,
	[REGION] [varchar](255) NULL,
	[ASL] [varchar](255) NULL,
	[CLD] [varchar](255) NULL,
	[SERIE] [varchar](255) NULL,
	[NUMERACION INICIAL] [varchar](255) NULL,
	[NUMERACION FINAL] [varchar](255) NULL,
	[OCUPACION] [varchar](255) NULL,
	[TIPO DE RED] [varchar](255) NULL,
	[MODALIDAD] [varchar](255) NULL,
	[RAZON SOCIAL] [varchar](255) NULL,
	[FECHA ASIGNACION] [varchar](255) NULL,
	[FECHA CONSOLIDACION] [varchar](255) NULL,
	[FECHA MIGRACION] [varchar](255) NULL,
	[CLD ANTERIOR] [varchar](255) NULL
)
	end'
		EXEC(@sql)

		set @process = 'alter table add column cccamps 2621-----'
		set @sql='if not exists (select * from sys.columns where name = N''callBackSurveyAgent'' and Object_ID = Object_ID(N''cccamps''))	alter table cccamps add callBackSurveyAgent bit CONSTRAINT cccamps_surverCallBackAgent DEFAULT (1) NOT NULL
if not exists (select * from sys.columns where name = N''callBackSurveyClient'' and Object_ID = Object_ID(N''cccamps'')) alter table cccamps add callBackSurveyClient bit CONSTRAINT cccamps_surverCallBackClient DEFAULT (1) NOT NULL'
		EXEC(@sql)


		

		set @process = 'alter table alter column startStopRecording cccamps -----Fix'
		set @sql='if not exists (select * from sysobjects where xtype in (N''C'', N''D'', N''F'', N''PK'', N''R'', N''UQ'') and name = N''startStopRecording'')
	begin
		update cccamps set startStopRecording =isnull(startStopRecording ,0)
		ALTER TABLE cccamps ALTER COLUMN startStopRecording bit NOT NULL
		ALter table cccamps ADD CONSTRAINT cccamps_startStopRecording DEFAULT (0) FOR startStopRecording
	end'
		EXEC(@sql)

		set @process = 'alter table ccinbound  2621-----'
		set @sql='if not exists (select * from sys.columns where name = N''callBackSurveyAgent'' and Object_ID = Object_ID(N''ccinbound'')) alter table ccinbound add callBackSurveyAgent bit CONSTRAINT ccinbound_surverCallBackAgent DEFAULT (1) NOT NULL
if not exists (select * from sys.columns where name = N''callBackSurveyClient'' and Object_ID = Object_ID(N''ccinbound'')) alter table ccinbound add callBackSurveyClient bit CONSTRAINT ccinbound_surverCallBackClient DEFAULT (1) NOT NULL'
		EXEC(@sql)

		set @process = 'insert into ccSettings  2622,2624.2528--------'
		set @sql='if not exists (select * from ccSettings where setting_id in(171,172,173))
	begin
		insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
values (172,''0|4|7|03:00|http://dset01.cft.gob.mx/filespnn/pnn_publico.zip'',''Descarga automática de las series COFETEL'',1,''GRL'',
''Activo(0|1)|# Semana Ejecucion|Dia Ejecucion(1:LU,2:Ma,3:Mi,4:Ju,5:Vi,6:Sa,7:Do)|Hora Inicio(00:00)|IP cofetel(Ftp o uri)'',''COFETEL number series automatic download'',1,
''/^[0-1]\|[1-5]\|[1-7]\|([01]?[0-9]|2[0-3]):[0-5][0-9]\|((ht|f)tp(s?)\:\/\/)?[\w]+\.+[\w\/\_\-\#\:\?\;&]+((\.)+([\w]{2,5})){1,2}+((\/|\#|\.)+[\w]*)*+$/'')
insert into ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
values (171,0,''0 desactivado, 1 activado para validar que el formato del número sea correcto'',1
,''AGT'',''Si el setting 108 se encuentra activo se tomara en cuenta la longuitud de dicho setting independientemente del plan de marcacion en el que se encuentre'',
''0enabled,1disabled to validate the accuracy of the number format''
,1,''^[0-1]$'')
insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
values (173,''0'',''Habilita el nuevo Redes Sociales Twitter'',1,''XXX'',''Habilita Redes Sociales Twitter'',''Enable Network Social Twitter'',1,''/^[0-1]$/'')
	end'
		EXEC(@sql)


		set @process = 'update ccSettings ------ fix'
		set @sql='update ccSettings set descripcion=''Ubicacion del subcriptor de CCenteria (HOSTNAME|IP) de ReportsRIA'' where setting_id=137
update ccSettings set descripcion=''Ubicacion del subcriptor de CCenteria (HOSTNAME|IP) de AVRS'' where setting_id=138'
		EXEC(@sql)
		

		set @process = 'update ccmenus ----------Fix'
		set @sql='update ccmenus set menu_descrip = ''Catálogo de cuentas de correo de salida|Sender Email Addresses'' where menu_id = 82'
		EXEC(@sql)

		set @process = 'ALTER function [dbo].[fnGetTipoLlamada] 2621-----'
		set @sql='ALTER function [dbo].[fnGetTipoLlamada]( @tel varchar(20) )
returns int
as
 begin
	declare @len integer, @tipo integer, @country varchar(5)
	declare @tipoLlamada_id smallint
	declare @prefijo varchar(15), @longitud varchar(15)

	declare @table table(
	id int not null,
	prefijo nvarchar(100) not null
	)

	select @country = valor from ccsettings where setting_id = 104
	set @len = len( @tel )
	set @tipo = 0

	declare @prefixTable table(
	tipoLlamada_id smallint not null,
	longitud varchar(15) not null,
	prefijo varchar(15) not null,
	[status] bit not null
	)

	insert into @prefixTable
	select tipoLlamada_id, longitud, prefijo, 0
	from cstoTipoLlamada with(index(IX_cstoTipoLlamada),nolock) 
	where country_id = @country 
	and (country_id <> 1 or (country_id = 1 and tipoLlamada_id not in (8,9,10,11))) --no incluir tarifas por region (Mexico)
	order by len(prefijo) desc -- para tomar el mas especifico si se devuelven varios patrones

	while (select count(*) from @prefixTable where [status] = 0) > 0
	begin
		select top 1 @tipoLlamada_id = tipoLlamada_id, @longitud = longitud, @prefijo = prefijo
		from @prefixTable 
		where [status] = 0

		insert into @table
		select * from fn_RIASplitDelimited(@prefijo,''|'') order by len(value) desc

		if (select count(*) from fn_RIASplitDelimited(@longitud,''|'') where value=@len) = 1
			begin
				if (select count(*)	from @table	where @tel like prefijo) = 1
					set @tipo = @tipoLlamada_id
			end
		else if @longitud = ''0''
			begin
				if (select count(*)	from @table	where @tel like prefijo) = 1
					set @tipo = @tipoLlamada_id
			end

		if @tipo <> 0
			update @prefixTable
			set [status] = 1
		else
			begin
				update @prefixTable
				set [status] = 1
				where tipoLlamada_id = @tipoLlamada_id

				delete @table
			end
	end

	return @tipo
 end'
		EXEC(@sql)



		set @process = 'ALTER function [dbo].[fGet_CampAcd_Area] ----------- '
		set @sql='ALTER function [dbo].[fGet_CampAcd_Area] (@user int, @tipo int)
returns @camps table (cam_id int)
as
begin
if (select login from ccusers where user_id=@user) = ''root''
      set @user=0

if @tipo = 1 begin
      insert @camps select distinct c.cam_id 
      from ccusers u join ccCamps c on u.IDArea = c.IDArea 
      where isnull(u.user_id, 0) = case when @user>0 then @user else isnull(u.user_id, 0) end
      end

else if @tipo = 2 begin
      insert @camps select distinct c.Inbound_id 
      from ccusers u join ccinbound c on u.IDArea = c.IDArea 
      where isnull(u.user_id, 0) = case when @user>0 then @user else isnull(u.user_id, 0) end
      end
if @tipo = 3 begin --Solo trae los seleccionados en el wg
      insert @camps 
      select distinct c.cam_id cam_id from ccUsers u  
      inner join ccRIAWorkGroupUsers wg on wg.User_id=u.User_id
      inner join ccRIACampEspWG wgCamAcd on wgCamAcd.IDWG=wg.IDWG and tipo=1
      inner join ccCamps c on c.cam_id=wgCamAcd.IdCampEsp
      where u.User_id=@user 
      end

else if @tipo = 4 begin --Solo trae los seleccionados en el wg
      insert @camps 
select distinct c.Inbound_id cam_id from ccUsers u    
      inner join ccRIAWorkGroupUsers wg on wg.User_id=u.User_id
      inner join ccRIACampEspWG wgCamAcd on wgCamAcd.IDWG=wg.IDWG and tipo=0
      inner join ccInbound c on c.Inbound_id=wgCamAcd.IdCampEsp
      where u.User_id=@user 
      end
return
end'
		EXEC(@sql)

		set @process = 'ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDayForced] 2540---------'
		set @sql='ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDayForced]
@type smallint,
@cam_id smallint,
@calif_id smallint = null
AS 
set nocount on
create table #CalifTemp (id int identity,
tipo integer, 
Cam_id varchar(50), 
Calificacion varchar(50), 
subCalificacion varchar(50) null,
calif_id smallint null,
Total int ) 

declare @today datetime
set @today = convert(datetime, convert (varchar(11), getdate(), 101))

-- Seleccion de idioma -- 
declare @nIdioma varchar(22)
select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
from ccsettings where setting_id = 27 -- 0esp


if @type=0 
insert into #CalifTemp 
select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13
		then case when description is not null 
					then description 
					else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end
else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end end as Calificacion,
case when count(co.califSub_id) > 0 then 1 else 0 end as Subcalificacion,co.calif_id as calif_id,count(*) cantidad
from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
left join ccTipoCalifSubOUT tcsout on co.califSub_id = tcsout.califSub_id
left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
left join ccCamps ci on ci.cam_id = co.cam_id 
where co.cal_inicio > @today
and co.cam_id = @cam_id
group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id



if @type=1 
insert into #CalifTemp 
select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end as Calificacion,count(ci.califSub_id) as subCalificacion,ci.calif_id,count(*)  as total
from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) 
left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
left join ccInbound cci on cci.inbound_id = ci.inbound_id 
where ci.cal_inicio > @today
and ci.inbound_id = @cam_id
and statuscall_id = 13 
group by description, cci.inbound_id,ci.califSub_id,ci.calif_id



-- Se corrigio suma de totales -- 
Alter table #CalifTemp add iTotal4Campaign int null

if (select valor from ccSettings where setting_id = 78) = 0
update #CalifTemp set iTotal4Campaign = 0

else	
update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
from (select cam_id, sum(A.Total) iTotal4Campaign 
from #CalifTemp A group by cam_id) t join #CalifTemp c
on t.cam_id = c.cam_id

if @type=1 
select tipo, cam_id, calificacion,subCalificacion,calif_id ,sum( total ) as totales from (
	select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
	 else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end as Calificacion,0 as subCalificacion ,0 as calif_id,count(disposition) as Total--,0 as iTotal4Campaign
	from ccriachats a left join ccTipoCalif b 
	on a.disposition=b.calif_id 
	where a.chatDate > @today
	and a.inboundId = @cam_id
	group by inboundId, Description
	
	union all
	
	
	select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
	else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end as Calificacion,
	case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total  --iTotal4Campaign -- para ver total por campaña
	from #CalifTemp 
	group by tipo, case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
	else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end, Cam_id,calif_id, iTotal4Campaign
)  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id order by tipo,cam_id 
if @type=0 

select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end as Calificacion,subCalificacion, calif_id ,sum(Total) as Total -- , iTotal4Campaign -- para ver total por campaña
from #CalifTemp 
group by tipo, case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end, Cam_id,subCalificacion, calif_id, iTotal4Campaign



if @type = 3 begin -----entrada acd''s
	select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
	else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end as Calificacion,isnull(ctcs.califSubDesc,''Sin Subcalificacion'') as subCalificacion, count(*) as totales 
	from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
	left join ccInbound cci on cci.inbound_id = ci.inbound_id 
	left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
	where ci.cal_inicio > @today
	and ci.inbound_id = @cam_id
	and statuscall_id = 13 
	and ci.calif_id = @calif_id
	group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id 
end

if @type = 4 begin --salida campañas
		select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
			then case when description is not null 
						then description 
						else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end
	else case when sll.descripcion is not null 
	then ''cw:'' + sll.descripcion else ''cw:'' + substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end end as Calificacion,isnull(cso.califSubDesc,''Sin Subcalificacion'') ,count(*) cantidad 
	from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
	left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
	left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
	left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
	left join ccCamps ci on ci.cam_id = co.cam_id 
	where co.cal_inicio > @today
	and co.cam_id = @cam_id
	group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
end 
 

drop table #CalifTemp 
set nocount off'
		EXEC(@sql)


		set @process = 'ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay] 2540--------'
		set @sql='ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]
@type smallint,
@inbound_id smallint = null,
@calif_id smallint = null
AS 
set nocount on
create table #CalifTemp (id int identity,
tipo integer, 
Cam_id varchar(50), 
Calificacion varchar(50), 
subCalificacion varchar(50) null,
calif_id smallint null,
Total int ) 

declare @today datetime
set @today =convert(datetime, convert (varchar(11), getdate(), 101))

-- Seleccion de idioma -- 
declare @nIdioma varchar(22)
select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
from ccsettings where setting_id = 27 -- 0esp

if @type=0 
insert into #CalifTemp 
select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
		then case when description is not null 
					then description
					else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end
else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end end as Calificacion,0 as subCalificaion,
co.calif_id,count(*) cantidad 
from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
left join ccCamps ci on ci.cam_id = co.cam_id 
where co.cal_inicio > @today
group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id


if @type=1 
insert into #CalifTemp 

select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end as Calificacion,count(isnull(ctcs.califSubDesc,'''')) as subCalificacion,ci.calif_id
,count(*) as total
 
from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id
left join ccInbound cci on cci.inbound_id = ci.inbound_id 
left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
where ci.cal_inicio > @today
and statuscall_id = 13 
group by description, cci.inbound_id,ci.calif_id

-- Se corrigio suma de totales -- 
Alter table #CalifTemp add iTotal4Campaign int null

if (select valor from ccSettings where setting_id = 78) = 0
update #CalifTemp set iTotal4Campaign = 0

else	
update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
from (select cam_id, sum(A.Total) iTotal4Campaign 
from #CalifTemp A group by cam_id) t join #CalifTemp c
on t.cam_id = c.cam_id

if @type=1 
select tipo, cam_id, calificacion,subCalificacion,calif_id ,sum( total ) as totales from (
	select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
	 else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end as Calificacion, 0 as subCalificacion,0 as calif_id, 	 
	 count(disposition) as Total,0 count,0 iTotal4Campaign
	from ccriachats a left join ccTipoCalif b
	on a.disposition=b.calif_id 
	where a.chatDate > @today
	group by inboundId, Description
	
	union all

	select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
	else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end as Calificacion
	,case when count(subCalificacion)>0 then 1 else 0 end subCalificacion,
	isnull(calif_id,'''') as calif_id
	 ,sum(Total) as Total, count(*) count , iTotal4Campaign -- para ver total por campaña
	from #CalifTemp 
	group by tipo, case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
	else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end,calif_id,Cam_id, iTotal4Campaign
)  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id order by tipo,cam_id,calif_id 

if @type=0 
select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end as Calificacion,case when count(subCalificacion)>0 then 1 else 0 end subCalificacion, calif_id,sum(Total) as Total-- , iTotal4Campaign -- para ver total por campaña
from #CalifTemp 
group by tipo, case when total > iTotal4Campaign / 100 or calificacion = substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) then calificacion 
else substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) end, Cam_id, iTotal4Campaign,calif_id

if @type = 3 begin -----entrada acd''s
	select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
	else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end as Calificacion,isnull(ctcs.califSubDesc,''Sin Subcalificacion'') as subCalificacion, count(*) as totales 
	from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
	left join ccInbound cci on cci.inbound_id = ci.inbound_id 
	left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
	where ci.cal_inicio > @today
	and ci.inbound_id = @inbound_id
	and statuscall_id = 13 
	and ci.calif_id = @calif_id
	group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id 
end

if @type = 4 begin --salida campañas
		select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
			then case when description is not null 
						then description 
						else substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end
	else case when sll.descripcion is not null 
	then ''cw:'' + sll.descripcion else ''cw:'' + substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) end end as Calificacion,isnull(cso.califSubDesc,''Sin Subcalificacion'') ,count(*) cantidad 
	from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
	left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
	left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
	left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
	left join ccCamps ci on ci.cam_id = co.cam_id 
	where co.cal_inicio > @today
	and co.cam_id = @inbound_id
	group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
end 
drop table #CalifTemp 
set nocount off'
		EXEC(@sql)

		
		
		set @process = 'ALTER procedure [dbo].[ccsp_AgentSetCallStatus] 2621--------'
		set @sql='ALTER procedure [dbo].[ccsp_AgentSetCallStatus]
@callout_id int,
@cal_id int,
@TipoCall tinyint,	-- 1= IN,  2=Out
@TipoMov tinyint,	-- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
@cal_tXfer tinyint=0,
@cal_tring  smallint=0,
@user_id smallint=0,
@extension varchar(5)='''',
@isChatCall bit = 0
AS
set nocount on

declare @RecicleSIC tinyint
SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id=60
Declare @ANI_x varchar(19)
declare @cal_inicio datetime
declare @callout_id_IN int
declare @cal_key varchar(20)
declare @cam_id int
declare @cal_telefono varchar(30)
declare @surveycamid int
declare @inbound_id int

if @TipoMov=4 or @TipoMov=14 -- DIALOG OnDialog
 begin
	if @TipoCall=2
	 begin
		if @TipoMov = 4 begin
			Update ccoCallsOUT with(rowlock) Set statusCall_id=13, cal_manual=case when @isChatCall=1 then 3 else cal_manual end Where cal_id=@cal_id			
		end
		else if @TipoMov = 14
			Update ccoCallsOUT with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

		if @RecicleSIC=0
			DELETE ccoWorkingTable with(rowlock) WHERE callout_id=@callout_id

		update ccoCallBacks
		set [status] = 1, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 13		

		-- calcula el costo de la llamada
		exec ccsp_CstoCalculaCosto @cal_id		

		--select @cal_key = cal_Key, @cam_id = cam_id, @cal_telefono = cal_telefono
		--from ccoCallsOUT with(index(IX_ccoCallsOut_11),nolock)
		--where callout_id = @callout_id
		--and statusCall_id = 13
		--and cal_id = @cal_id		

		--select @surveycamid = isnull(surveycamid,0) from cccamps where cam_id = @cam_id

		--if @surveycamid > 0
		--	begin
		--		if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100 
		--		begin
		--			insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial) 
		--			values(right((cast(@cal_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,1, dateadd(mi, 6, getdate()))
		--		end
		--	end

		return(0)
	end

	if @TipoMov = 4
		Update ccCallsIN with(rowlock) Set statusCall_id=13 Where cal_id=@cal_id
	else if @TipoMov = 14
		Update ccCallsIN with(rowlock) Set statusCall_id=13, cal_tRing=@cal_tring, user_id=@user_id, cal_extension=@extension Where cal_id=@cal_id

	-- Elimina callback generado por abandono
	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x
	
	update ccoCallBacks with(rowlock)
	set [status] = 1, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	DELETE ccoWorkingTable with(rowlock) WHERE callout_id in (select distinct(callout_id) from ccRIAUpdateCallBack_Abandon with(rowlock) where cal_ani=@ANI_x)
	DELETE ccRIAUpdateCallBack_Abandon with(rowlock) WHERE cal_ANI=@ANI_x

	--select @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani
	--from ccCallsIN with(index(IX_ccCallsIn_6),nolock)
	--where cal_id = @cal_id
	--and statusCall_id = 13

	--select @surveycamid = isnull(cam_id,0) from ccinbound where inbound_id = @inbound_id

	--if exists (select cam_id from cccamps where cam_id = @surveycamid and isnull(callsBySurvey,0) > 0 and isnull(ivrScript,0) > 0)
	--begin
	--	if (select surveyPctg from ccCamps where cam_id = @surveycamid) >= rand() *100 
	--	begin
	--		insert into ccoCallsOUTSource(cal_Key,cam_id,cal_telefono,cal_status, cal_fechaDial) 
	--		values(right((cast(@cal_id as varchar) + '','' + @cal_Key),20),@surveycamid,@cal_telefono,1, dateadd(mi, 6, getdate()) )
	--	end
	--end

	return(0)
 end

if @TipoMov=7 --OTHER OFFHook_OnXfer
 begin
	if @cal_id<=0
		return(0)

	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 16

		exec ccsp_CstoCalculaCosto @cal_id
		return(0)
	 end

	Update ccCallsIN with(rowlock) Set statusCall_id=16 Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock) 
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

if  @TipoMov=9 --RING CallNoAnswered
 begin
	if @TipoCall=2
	 begin
		Update ccoCallsOUT with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id
		-- calcula el costo de la llamada

		update ccoCallBacks
		set [status] = 2, schedulerStatus = 1, cal_fcallback = cal_inicio
		from ccoCallBacks a with(index(IX_ccoCallBacks),nolock), ccoCallsOUT b with(index(IX_ccoCallsOut_11),nolock)
		where a.callout_id = b.callout_id
		and b.callout_id = @callout_id
		and b.cal_id = @cal_id
		and [status] = 0
		AND statusCall_id = 15

		exec ccsp_CstoCalculaCosto @cal_id
	 end
	
	Update ccCallsIN with(rowlock) Set statusCall_id=15, cal_tXFer =@cal_txFer, cal_tRing=@cal_tring  Where cal_id=@cal_id

	select @ANI_x=cal_ani, @cal_inicio = cal_inicio from cccallsin with(index(PK_ccCallsIn)) where cal_id=@cal_id
	select @callout_id_IN from ccRIAUpdateCallBack_Abandon where cal_ani=@ANI_x

	update ccoCallBacks with(rowlock) 
	set [status] = 2, schedulerStatus = 1, cal_fcallback = @cal_inicio
	where callout_id = @callout_id_IN
	and [status] = 0

	return(0)
 end

set nocount off'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp] 2621---------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
@User_id smallint 
AS 
set nocount on
	select a1.cam_id, cam_Descripcion
	 , cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
	 , cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
	 , cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
	 , detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
	 , cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
	 , stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, cam_maxqueue as queSize,
	 DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
     ,cast (startStopRecording as tinyint)startStopRecording, leaveRecMessage, manualCallOnChat
	 ,callBackSurveyAgent,callBackSurveyClient,case when surveycamid is null or surveycamid = 0 then 0 else 1 end isRelationSurvey
	 from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
	 inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id) 
	 where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
	 order by cam_descripcion
	return(0)
 set nocount off'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec] 2621------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
@User_id int
AS
set nocount on

select  A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat mode, A.inactiveChatTime, A.maxChats, isnull(A.chatDomain,'''') chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
isnull(A.startStopRecording,0) startStopRecording
,isnull(B.name,'''') as nameMail,isnull(B.conexionInfo,'''') as conexionInfo,isnull(B.connUser,'''') as connUser,
isnull(B.ConnPass,'''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage,
isnull(B.IsActive,0) as Active, isnull(B.answerTimeOut,0) as answerTimeOut,A.callBackSurveyAgent,A.callBackSurveyClient,
case when C.CallsBySurvey is null or C.CallsBySurvey = 0 then 0 else 1 end isRelationSurvey,
isnull(nameTwitter,'''') nameTwitter,isnull(userTwitter,'''') userTwitter,isnull(numMessagesTwitter,3) numMessagesTwitter,
isnull(timeAlertMessageTwitter,10) timeAlertMessageTwitter,isnull(ActiveTwitter,0) ActiveTwitter,isnull(answerTimeOutTwitter,10) answerTimeOutTwitter
from ccInbound A
left join ContactMeanIn B on A.inbound_id=B.inboundId and B.meanContactTypeId=1
left join ccCamps C on C.cam_id=A.cam_id
left join (
select D.inboundId,
D.name as nameTwitter,D.connUser as userTwitter,D.numMessages as numMessagesTwitter,
D.timeAlertMessage as timeAlertMessageTwitter,
D.IsActive as ActiveTwitter, D.answerTimeOut as answerTimeOutTwitter
from ContactMeanIn D
where D.meanContactTypeId=2) D on A.Inbound_id=D.inboundId
where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 2))
return(0)
set nocount off'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig] 2621-------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
@cam_id smallint,
@cam_descripcion varchar(40) = null,
@cam_tnotas smallint = null,
@cam_ocupado tinyint = null,
@cam_NoInt_ocupado tinyint = null,
@cam_inter_ocupado smallint = null,
@cam_nocontesto tinyint = null,
@cam_NoInt_nocontesto tinyint = null,
@cam_inter_nocontesto smallint = null,
@cam_fax tinyint = null,
@cam_NoInt_fax tinyint = null,
@cam_inter_fax smallint = null,
@cam_ModoManual tinyint= null,
@ANI varchar(15) = null,
@cam_ShowCalifWnd bit = null,
@cam_StartTimerOnHangUp bit = null,
@editableCallKey bit = null, 
@cam_tNoContesta tinyint = null,
@cam_intensive_dialing tinyint = null, 
@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
@compliance TinyInt = null, 
@cam_inter_graba smallint = null,
@cam_NoInt_graba tinyint = null,
@progDial smallint = null,
@excCallBack Tinyint = null,
@dialOrder Tinyint = null,
@dialPrefix varchar(10) = null,
@dialPrefixMan varchar(10) = null,
@dialPrefixXfe varchar(10) = null,
@listenManualCall bit = null,
@stopRecording bit = null,
@abandonCallback bit = null,
@autoCB smallint = null,
@id_listAni int = null,
@tDialonWrapUp smallint = null,
@quesize smallint=null,
@DNCScrub int=null,
@callerIdDesc varchar(15)=null,
@timeZoneRule int=null,
@callsBySurvey int=null,
@ivrScript int=null,
@surveyPctg int=null,
@call_record tinyint=null,
@dRestrictPlay bit = null,
@leaveRecMessage bit = null,
@manualCallOnChat bit = null,
@callBackSurveyClient bit = null,
@callBackSurveyAgent bit = null
as
set nocount on
UPDATE ccCamps SET 
 cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
 cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
 cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
 cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
 cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
 cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
 cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
 cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
 cam_fax = isnull(@cam_fax,cam_fax),
 cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
 cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
 cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
 ANI = isnull(@ANI,ANI),
 cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
 editableCallKey = isnull(@editableCallKey, editableCallKey),
 cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
 iTipoDial = isnull(@cam_intensive_dialing, iTipoDial), 
 detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine), 
 detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
 compliance = isnull(@compliance, compliance),
 cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
 cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
 cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
 progDial = isnull(@progDial, progDial),
 excCallBack = isnull(@excCallBack,excCallBack),
 dialOrder = isnull(@dialOrder, dialOrder),
 dialPrefix = isnull(@dialPrefix, dialPrefix),
 dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
 dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
 listenManualCall = isnull(@listenManualCall, listenManualCall),
 stopRecording = isnull(@stopRecording, stopRecording),
 abandonCallback = isnull(@abandonCallback, abandonCallback),
 t_autoCB = isnull(@autoCB,t_autoCB),
 id_anilist = isnull(@id_listAni,id_anilist),
 tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
 cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
 cam_maxqueue = isnull(@quesize,cam_maxqueue),
 DNCScrub = isnull(@DNCScrub,DNCScrub),
 callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
 timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
 callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
 ivrScript = isnull(@ivrScript,ivrScript),
 surveyPctg = isnull(@surveyPctg,surveyPctg),
 call_record = isnull(@call_record,call_record),
 startStopRecording = isnull(@dRestrictPlay, startStopRecording),
 leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
 manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
 callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
 callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent )
Where cam_id = @cam_id 

if @cam_ShowCalifWnd = 1
 begin
	If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
	 begin
		select 0
		return(0)
	 end
	 
	UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
	where cam_id = @cam_id
	select 1
	return(0)
  end

--else
UPDATE ccCamps SET 
cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
where cam_id = @cam_id
return(0)
set nocount off'
		EXEC(@sql)

		set @process = 'ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig] 2621-------'
		set @sql='ALTER procedure [dbo].[ccsp_RIAUpdateEspecConfig]
@inbound_id smallint,
@descripcion varchar(50) = null,
@Status tinyint = null,
@tNotas int = null,
@tMaxWaitCall int = null,
@nMaxQue int = null,
@tel_maxwait varchar(15) = null,
@tel_MaxQueue varchar(15) = null,
@tel_outservice varchar(15) = null,
@tel_noct varchar(15) = null,
@ShowCalifWnd bit = null,
@StartTimerOnHangUp bit = null,
@editableCallKey bit = null,
@queuePosition bit = null,
@tMaxQueueCallBack smallint = null,
@stopRecording bit = null,
@dialPrefixOverflow varchar(10) = null,
@OpriorityT smallint= null,
@callerIdDesc varchar(15) = null,
@chat tinyint = null,
@inactiveChatTime smallint = null,
@maxChats tinyint = null,
@chatDomain varchar(max) = null,
@chatQueue smallint = null,
@chatTime smallint = null,
@dRestrictPlay bit = null,
@callBackSurveyAgent bit = null,
@callBackSurveyClient bit = null
as
set nocount on
UPDATE ccInbound SET
descripcion = isnull(@descripcion,descripcion),
Status = isnull(@status,status),
tNotas = isnull(@tNotas,tNotas),
tMaxWaitCall = isnull(@tMaxWaitCall,tMaxWaitCall),
nMaxQue = isnull(@nMaxQue,nMaxQue),
tel_maxwait = isnull(@tel_maxwait,tel_maxwait),
tel_MaxQueue = isnull(@tel_MaxQueue,tel_MaxQueue),
tel_outservice = isnull(@tel_outservice,tel_outservice),
tel_noct = isnull(@tel_noct,tel_noct),
bnocturno = case when isnull(@tel_noct,''0'')=''0'' or @tel_noct='''' then ''0'' else ''1'' end,
StartTimerOnHangUp = isnull(@StartTimerOnHangUp,StartTimerOnHangUp),
editableCallKey = isnull(@editableCallKey,editableCallKey),
queuePosition = isnull(@queuePosition,queuePosition),
tMaxQueueCallBack = isnull(@tMaxQueueCallBack,tMaxQueueCallBack),
stopRecording = isnull(@stopRecording, stopRecording),
dialPrefixOverflow = isnull(@dialPrefixOverflow, dialPrefixOverflow),
OpriorityT = isnull(@OpriorityT, OpriorityT),
callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
chat = isnull(@chat,chat),
inactiveChatTime = isnull(@inactiveChatTime,inactiveChatTime),
maxChats = isnull(@maxChats,maxChats),
chatQueueOverflow = isnull(@chatQueue,isnull(chatQueueOverflow,15)),
chatTimeOverflow = isnull(@chatTime,isnull(chatTimeOverflow,300)),
startStopRecording = isnull(@dRestrictPlay,startStopRecording),
callBackSurveyAgent = isnull(@callBackSurveyAgent,callBackSurveyAgent),
callBackSurveyClient = isnull(@callBackSurveyClient,callBackSurveyClient)
where inbound_id = @inbound_id

if not exists( select inbound_id from ccinbound where inbound_id <> @inbound_id and chatDomain = @chatDomain ) begin
if isnull(@chatDomain,'''') <> '''' begin
	update ccinbound set chatDomain = @chatDomain where inbound_id = @inbound_id
end
end
else begin
raiserror(''Domain already in another ACD Group'',15,4)
end


if @ShowCalifWnd = 1
begin
If exists(select cam_id from ccCalifCamp where cam_id = @inbound_id and tipo = 0)
	begin
	UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd,ShowCalifWnd)
	where inbound_id = @inbound_id
	select 1
	return(0)
	end

select 0
return(0)
end

else
UPDATE ccInbound SET ShowCalifWnd = isnull(@ShowCalifWnd,ShowCalifWnd)
where inbound_id = @inbound_id
return(0)
set nocount off'
		EXEC(@sql)

		set @process = 'ALTER procedure [dbo].[ccsp_RIAUpdateHangUpAgent] 2621-----------'
		set @sql='ALTER procedure [dbo].[ccsp_RIAUpdateHangUpAgent]
@IDCall int,
@TipoCall tinyint, --1 = entrada, 2 = salida
@isTransferSurvey bit=0 --0 Callback, 1 Realiza Transferencia inmediata 
as
set nocount on
--declare @cam_id int,@surveycamId int
--declare @cal_telefono varchar(30)
--declare @cal_key varchar(20)
--declare @inbound_id int

if @TipoCall = 1 begin
	UPDATE ccCallsIn   SET cal_whoHung = case when @isTransferSurvey = 0 then 1 else 2 end WHERE cal_id = @IDCall	
end
else begin
	UPDATE ccoCallsOut SET cal_whoHung = case when @isTransferSurvey =0 then 1 else 2 end WHERE cal_id = @IDCall	
end

set nocount off'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent] 2621-----------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady tinyint,
@tStatus int,
@TipoCall  tinyint,
@Camp smallint,
--@isTransferSurvey bit=0, --0 Callback, 1 Realiza Transferencia inmediata 
@callout_id int=0,
@call_id int=0
AS
declare @Fecha4 datetime
set @Fecha4 = getdate()

if @TipoCall > 0
	set @TipoCall = @TipoCall - 1

if (@User_id > 0 )
begin
	if (@TipoStatusAge_id=4) -- 4 = Dialogo
	 begin
		declare @tStatus3 int, @Fecha3 datetime
		select top 1 @tStatus3=tstatus, @Fecha3=fecha from ccLogAgentesDia where TipoStatusAge_id=3 and user_id=@User_id order by fecha desc
		insert into ccLogAgentesDia_Dialog (User_id,Cam_id,fecha_Calc_ms,tStatus_Dispo,fecha_Dispo,tStatus_Dialog,fecha_Dialog)
		select @User_id, cam_id, datediff(ms, dateadd(ss, -@tStatus3, @Fecha3), dateadd(ss, -@tStatus, @Fecha4)), @tStatus3, @Fecha3, @tStatus, @Fecha4
		from cccampsagente where user_id = @User_id

		declare @cam_id int,@surveycamId int
		declare @cal_telefono varchar(30)
		declare @cal_key varchar(20)
		declare @inbound_id int
		declare @callBackSurveyClients bit
		declare @cal_whoHung tinyint
		---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
		if @call_id>0 begin
			if @TipoCall = 0 begin --IN
										
					select @cal_key = cal_Key, @inbound_id = inbound_id, @cal_telefono = cal_ani ,@cal_whoHung=cal_whoHung
						from ccCallsIN with(index(IX_ccCallsIn_6),nolock) where cal_id = @call_id and statusCall_id = 13
					
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
				select @cam_id = cam_id from ccoCallsOut where cal_id = @call_id
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

	INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo )
	VALUES( @User_id, @TipoStatusAge_id, @tStatus, @Fecha4, @Camp, @TipoCall )

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
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps] ----------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCCamps]
@option smallint,
@UserId int,
@Descripcion varchar(40),
@Cam_id varchar(1000),
@Activa tinyint,
@IDArea smallint = null,
@frame tinyint, 
@MirrorInbound_Id smallint = null
as
set nocount on

if @option = 0
 begin
	 select cam_id,ISNULL(cam_descripcion,'''') as cam_descripcion
	  ,ISNULL(CAMP.IDArea,0) as IDArea, ISNULL(AREas.AreaName,'''') as AreaName
	 from ccCamps as CAMP with(nolock)
	 left join ccRIACat_Areas as AREas with(nolock)
	 on CAMP.IDArea = AREas.IDArea
	 return(0)
 end

if @option = 1 -- select Camp
 begin
	 select a1.cam_id, cam_descripcion, cam_ShowCalifWnd,
	  cam_StartTimeronHangUp, frame, cam_activo, isnull(IDArea,0)
	 from ccCamps a1
	  inner join ccRIACampsGraph a2 on (a1.cam_id = a2.cam_id)
	  inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
	 where a3.type_id = 1 and a1.cam_id = (CasT(@Cam_id as smallint))
	 return(0)
 end

if @option = 4 --Delete
 begin
 	 if exists (select inbound_id from ccInbound where cam_id = @Cam_id)
	  begin
		declare @error varchar(70)
		Select @error=case valor when 0 then ''No es posible eliminar la campaña, esta asociada a una especialidad'' 
		 else ''Campaign can not be deleted, it has an association with an ACD'' end
		from ccsettings where setting_id = 27
		raiserror (@error,18,1)		
		return(0)
	  end

	 delete ccCampsHorarios where cam_id = @Cam_id
	 insert into ccCampsMovs (cam_id, TipoMov, NewRecords, CBRecords, user_id)
	  Values(@Cam_id, 5, 0, 0, @UserId)
	 Delete ccCalifCamp where cam_id = @Cam_id and tipo = 1
	 Delete ccRIACampsGraph where cam_id = @Cam_id
	 delete ccHistorialListaNegra where cam_id = @Cam_id
	 delete ccRIARegistryLists where cam_id = @Cam_id

	/*** Se elimina la funcionalidad de paso de informacion de CCenterRIA a ccReports y borrado de información cuando una campaña es eliminada ***/
	/*
	-- Se inicia proceso de scheduler service para pasar informacion de ccocallsout antes de eliminarla
	 declare @server varchar(200), @sql varchar(8000), @from datetime, @to datetime
	select @server=valor from ccsettings where setting_id=22

	set @from=convert(smalldatetime,convert(varchar(16),dateadd(mi,-70,getdate()),121)+ '':00'',121)
	set @to=convert(smalldatetime,convert(varchar(16),dateadd(mi,-60,getdate()),121)+ '':00'',121)

	set @sql=''declare @calIni as varchar(15), @calfin as varchar(15), @Cam_id as smallint
	select @calIni=isnull(max(cal_id),1) from '' + @server + ''.dbo.ccocallsout WITH(NOLOCK) where cam_id = @Cam_id
	select @calfin=max(cal_id) from ccocallsout with(index (IX_ccoCallsOut_2),NOLOCK) where cam_id = @Cam_id 
	SET IDENTITY_INSERT '' + @server + ''.dbo.ccocallsout ON ''

	set @sql = @sql + ''
	insert into '' + @server + ''.dbo.ccocallsout (cal_id,callout_id, cal_telefono,cal_puerto,cam_id,user_id,cal_extension,cal_colgada,cal_key,
	statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,
	cal_tlinebusy,costo,provedor_id,tipollamada_id,cal_tMoh)
	select cal_id,callout_id, cal_telefono,cal_puerto,cam_id,user_id,cal_extension,cal_colgada,cal_key,
	statuscall_id,calif_id,cal_que,cal_tdialog,cal_tnotas,cal_txfer,cal_tring,cal_inicio,cal_fcallback,cal_manual,cal_tdialogdialer,
	cal_tlinebusy,costo,provedor_id,tipollamada_id,cal_tMoh from ccocallsout WITH(NOLOCK) WHERE cal_id>@calIni and cal_id<=@calfin 
	and cam_id=''+cast(@Cam_id as varchar(10))+'' 
	SET IDENTITY_INSERT '' + @server + ''.dbo.ccocallsout OFF ''
	exec(@sql)

	delete ccoCallsOut where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @Cam_id)
	delete ccoCallsOutSource where cam_id = @Cam_id
	Delete ccCamps where cam_id = @Cam_id
	 */
	 return(0)
 end

if @option = 2 --Insert
 begin
	declare @new_cam_id smallint

	if exists(select cam_descripcion from ccCamps where cam_descripcion = @Descripcion)
	 begin
		select -1 --, ''Nombre en Uso''
		return(0)  
	 end

	-- ODC: la campaña siempre esta activa
	set @Activa = 1

	Insert into ccCamps (cam_descripcion, cam_StartTimeronHangUp, cam_activo ,IDArea, cam_bNew, cam_ShowCalifWnd)
	select @Descripcion, 1, @Activa, case @IDArea when 0 then null else @IDArea end, 1,
	case when exists (select calif_id from ccTipoCalifOUT) then 1 else 0 end

	if @@rowcount = 1
	select @new_cam_id = scope_identity()

	else
	 begin
		select -2 --, ''Error al crear campaña''
		return(0)
	 end

	if isnull(@MirrorInbound_Id, 0)<>0
	 begin
		if not exists(select inbound_id from ccInbound where inbound_id=@MirrorInbound_Id)
		 begin
			select -3 -- Error al asignar campaña a ACD, el ACD no existe o no pertenece a la misma area
			return(0)
		 end

		update ccinbound set cam_id=@new_cam_id where inbound_id=@MirrorInbound_Id -- and isnull(idarea, 0)=isnull(@IDArea, 0)
		update cccamps set idarea = (select idarea from ccinbound where inbound_id=@MirrorInbound_Id) where cam_id=@new_cam_id
	 end

	insert into ccoDialerCamp (dialer_id, cam_id)
	select dialer_id, @new_cam_id from ccoDialers where status = 1

	insert into ccCalifCamp (calif_id, cam_id, tipo) select calif_id, @new_cam_id, 1 from ccTipoCalifOUT where CalifOut_Status = 1

	If not exists (select frame from ccRIAGraphics where frame = @frame and type_id = 1)
	 begin
		insert into ccRIAGraphics (frame, type_id) values (@frame, 1)
	 end

	insert into ccRIACampsGraph (cam_id, graphic_id)
	select @new_cam_id, graphic_id from ccRIAGraphics where frame = @frame and type_id = 1

	--inserta la lista negra por default
	if (select valor from ccsettings where setting_id=152)=''1''
	begin
		declare @tempId as int
		DECLARE @dnclId TABLE 
		(
		  id int 
		);
		insert into @dnclId
		exec dbo.ccsp_RIACATBList null, null, 5
		select @tempId=id from @dnclId;
		exec ccsp_RIABlackListCamp 4, @IDArea, @new_cam_id, @tempId, null
	end

	select @new_cam_id
	return(0)
 end

if @option = 3 -- Update
 begin
	 if not exists(select frame from ccRIAGraphics where frame = @frame and type_id = 1)
	  insert into ccRIAGraphics (frame,type_id) values (@frame,1)

	 Update ccCamps set cam_descripcion = @Descripcion, cam_activo = @Activa where cam_id = @Cam_id

	 update ccRIACampsGraph
	  set graphic_id = (select graphic_id from ccRIAGraphics where frame = @frame and type_id = 1)
	  where cam_id = @Cam_id

	 return(0)
 end

 if @option = 5 --Obtener relaciones de campañas - campañas
   begin
      if not exists (select cam_id from ccCamps where cam_id = @Cam_id) or
	 (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
		not exists (select cam_id from ccCamps where cam_id=@descripcion))
	 begin
		select -3 -- Campaña invalida
		return(0)
	 end
	
	if @descripcion=0
		set @descripcion = null

	update ccCamps set surveyCamId = @descripcion where cam_id = @Cam_id
	if @@rowcount=0
		select -4 -- Error al actualizar
		
	else
	 begin
		delete cccalifcamp where tipo=0 and cam_id=@Cam_id and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

	 end

	return(0)
   end

if @option = 6
	begin
		select cam_id, isnull(surveycamid,0)
		from cccamps with(nolock)
		where cam_id = @Cam_id
		return(0)
	end

return(0)
set nocount off'
		EXEC(@sql)

		set @process = 'ALTER PROCedure [dbo].[ccsp_RIALoadCamps] ------------'
		set @sql='ALTER PROCedure [dbo].[ccsp_RIALoadCamps]
@option smallint,
@AreaId smallint = null,
@Sup smallint = null
as
set nocount on
if @option = 1 -- Todas las campañas
begin
      select a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea,0), isnull(DNCscrub,0)
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      where a3.type_id = 1 and a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@Sup, 1))
      order by 5,2
      return(0)
end
 
if @option = 2 -- Campañas de un Area
begin
      select distinct a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea,0)
      IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      where a3.type_id = 1 and isnull(IDArea, 0) = isnull(@AreaId, 0)
      order by cam_descripcion
      return(0)
end
 
if @option = 3 -- Campañas por Supervisor
begin
      select distinct a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(a1.IDArea,0) IDArea
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      join ccSupervisorCam a4 on a1.cam_id = a4.cam_id
      where a3.type_id = 1 and a4.tipo = 1 and a4.user_id = @Sup
      order by 5, 2
      return(0)
end
 
if @option = 4 -- Rels Camps-Agents
begin
      select Login, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea, min(rel_id) rel_id
      from (select A.Login, A.User_id, Prioridad, Skill, C.cam_id, C.cam_descripcion, isnull(C.IDArea,0) IDArea, CA.rel_id
            from ccCamps C join ccCampsAgente CA on C.cam_id = CA.cam_id
            join ccRIACampsGraph a2 on C.cam_id = a2.cam_id
            join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
            join ccUsers A on A.User_id = CA.User_id and A.TipoUser_id = 1 and A.Status = 1
            where C.cam_id in(select cam_id from ccsupervisorcam where user_id = case isnull(@Sup,0)
             when 0 then user_id else @Sup end and tipo=1)) Relations
      group by Login, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea
      order by User_id, cam_descripcion, cam_id, Prioridad
      return(0)
end
 
if @option = 5 -- Campañas por Supervisor
      begin
			select @AreaId= IDArea from ccUsers where User_id=@sup

            select distinct Camps.cam_id, Camps.cam_descripcion, a3.frame, Camps.cam_procesando, isnull(Camps.IDArea,0)IDArea,
            IsNull(CN.New, 0) as New, IsNull(CN.CB, 0) as CB, IsNull(CN.Pro, 0) as Pro,
            IsNull(CN.pen, 0) as Pen, cast(Camps.cam_procesando as int) as St, Camps.cam_TipoJobs as Job,
            isnull(CN.Fin, 0)Fin, isnull(CP.prioridad,''12345NNN'') prioridad, cast(camps.dialorder as tinyint) dialorder,
            cast(camps.progDial as tinyint) progDial, U.monitored
            from ccCamps Camps left join ccCampsPrioridadTel CP on CP.cam_id = Camps.cam_id
            left join ccCampsNvosCB CN on CN.id = Camps.cam_id
            join ccRIACampsGraph a2 on (Camps.cam_id = a2.cam_id)
            join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
            join ccSupervisorCam U on Camps.cam_id = U.cam_id
            where U.user_id = @sup
            and tipo = 1
            and a3.type_id = 1
            and Camps.cam_id in (select cam_id from ccSupervisorCam where tipo = 1 and user_id = @sup)
			and Camps.IDArea=@AreaId
            order by 5, cam_procesando desc, cam_descripcion
            return(0)
      end
 
if @option = 7 -- Una sola
begin
      select distinct a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(IDArea,0) IDArea,
      isnull(DNCscrub,0) DNCScrub
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      where a3.type_id=1 and isnull(a1.cam_id,0)=isnull(@AreaId,0)
      order by 5,2
      return(0)
end
 
if @option = 8 -- Campañas de un Agente
begin
      select distinct a1.cam_id, a1.cam_descripcion, a3.frame
      from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
      join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
      join ccCampsAgente a4 on a1.cam_id = a4.cam_id
      where a3.type_id=1 and a4.user_id = @Sup
      order by 2
      return(0)
end
 
return(0)
set nocount off'
		EXEC(@sql)

		set @process = 'ALTER procedure [dbo].[ccsp_OUTcheckTimeZone] -----------------'
		set @sql='ALTER procedure [dbo].[ccsp_OUTcheckTimeZone]
@cam_id as int
AS
set nocount on
declare @horaUniversal datetime, @revHorario bit,@isShudulerLey bit
declare @valueShudulerLey varchar(max),@hourStart int,@hourEnd int,@minStart int,@minEnd int
declare @shourStart varchar(max),@shourEnd varchar(max)
declare @timeMaxContestacion tinyint

set @timeMaxContestacion=60

select @revHorario=valor from ccsettings where setting_id = 112
select @valueShudulerLey = valor from ccsettings where setting_id=166
select @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)) as int),@valueShudulerLey=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
select @timeMaxContestacion=(cam_tNoContesta*2) from cccamps where cam_id=@cam_id

set @timeMaxContestacion=CEILING(cast(@timeMaxContestacion as decimal(10,2)) / cast(60 as decimal(10,2)))

if @valueShudulerLey='''' begin
      set @valueShudulerLey=''0|07:00|22:00''
      update ccsettings set valor=@valueShudulerLey where setting_id=166
end
if @isShudulerLey = 1 begin
      select @shourStart=substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)),@shourEnd=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
      select @hourStart=substring(@shourStart, 0, charindex('':'',@shourStart)),@minStart=substring(@shourStart, charindex('':'',@shourStart) + 1, len(@shourStart))
      select @hourEnd=substring(@shourEnd, 0, charindex('':'',@shourEnd)),@minEnd=substring(@shourEnd, charindex('':'',@shourEnd) + 1, len(@shourEnd))
end
else begin
      select @hourStart=0,@minStart=0,@hourEnd=23,@minEnd=59
end

SET DATEFIRST 1
set @horaUniversal = getutcdate()

-- Si la campaña no tiene horarios asignados, marcar todas las zonas
if @revHorario = 0
begin
      if not exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@cam_id)
            begin
                  select sum(distinct tz_id) from (
                  select tz_id,
                        dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
                        datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora,
                        datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
                        datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
                        from ccTimeZones
                  )zonas
                  where (hora > @hourStart or (hora = @hourStart and minuto >= @minStart) )and
                        ( hora < @hourEnd  or (hora = @hourEnd and minuto <= @minEnd) )
            return(0)
            end
end


select h.horario_id,Descripcion,
      case when HoraInicio>@hourStart then HoraInicio else @hourStart end HoraInicio,
      case when (horaInicio>@hourStart or (horaInicio=@hourStart and MinInicio>=@minStart) ) then MinInicio  else @minStart end MinInicio,
      case when horaFin<@hourEnd then horaFin else @hourEnd end HoraFin,
      case when ((horaFin < @hourEnd or (horaFin=@hourEnd and MinFin<=@minEnd) )) then MinFin  else @minEnd end MinFin,
      Lunes,Martes,Miercoles,Jueves,Viernes,Sabado,Domingo  
 into #tempCamp
 from cchorarios h
      inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on h.horario_id = ccCampsHorarios.horario_id and ccCampsHorarios.cam_id = @cam_id    


select isnull(sum( distinct tz_id),0) from
(
      select tz_id,
      dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
      datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora,
      datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
      datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
      from ccTimeZones
)zonas
inner join #tempCamp on
(
      (
            hora > HoraInicio OR  (hora = HoraInicio AND minuto >= MinInicio)
      )
      AND
      (
            hora < HoraFin    OR  (hora = HoraFin AND minuto <= (MinFin-@timeMaxContestacion) )
      )
      AND
      (
            Lunes  = dia or
            Martes *2 = dia or
            Miercoles*3 = dia or
            Jueves*4 = dia or
            Viernes*5 = dia or
            Sabado*6 = dia or
            domingo*7 = dia
      )

)
drop table #tempCamp'
		EXEC(@sql)

		set @process = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs] ------------------------------'
		set @sql='ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
@CAMPID int,
@test int=0,
@nAgentsLogin int=1,
@iZonas int = null
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @sql varchar(4000), @Order_Asc_Desc char(4)
declare @camSurvey int
select @camSurvey = 0
DECLARE @iZonasTable TABLE (value int)

select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

if @iZonas is null begin

      INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
      select @iZonas=value from @iZonasTable    
--Checamos si la campaña tiene horarios configurados
      if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
      begin
                  if @iZonas = 0 begin                
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                  end
      end
      else begin
            if @camSurvey > 0
                  begin                   
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                  end
      end
end

set @sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
      cam_id int,
      cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
      cal_status tinyint,
      cal_fechaDial datetime,
      user_id int,
      tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint
)''


-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
select @topCount=case when @nAgentsLogin<3 then 30
      when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
      when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
      when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
      when @nAgentsLogin>=16 then 240 else 20 end

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

declare @isVerano varchar(max)
set @isVerano = ''izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin

            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )
            
            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,
            W.list_id, isNull(R.sequence,0) as sequence
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
            WHERE cal_status=1 -- CallBacks
            and cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
            and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                  ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                  ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by prioridad_cb desc, cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)

            --select @sql
end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
            SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,''
            +@isVerano+'',''
            +@isVerano+''2,''
            +@isVerano+''3,''
            +@isVerano+''4,''
            +@isVerano+''5,                
            W.list_id, isNull(R.sequence,0) as sequence
            FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
            WHERE cal_status=0 -- Nuevas sin Tiempo
            and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
            and (
                  ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
                   ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
            or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
            )
            and isnull(R.status,2) = 2
            order by R.sequence, cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''

end -- TOMA EN CUENTA LAS NUEVAS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @sql=@sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
      begin
            select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
            WHERE callout_id in(select callout_id from #NEW_JOBS)''
end

if @Test = 2
begin
      select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
      declare @nSQL nvarchar(4000)
      set @nSQL=cast(@sql as nvarchar(4000))
      exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
      return(@total)
end
else
begin
      select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5,
case when tz is null then '''''''' else cal_telefono end as tel,
case when tz2 is null then '''''''' else cal_telefono end as tel2,
case when tz3 is null then '''''''' else cal_telefono end as tel3,
case when tz4 is null then '''''''' else cal_telefono end as tel4,
case when tz5 is null then '''''''' else cal_telefono end as tel5,
NULL as dialOrder, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0''
end

set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
print (@sql)
exec(@sql)

return(0)'
		EXEC(@sql)

		set @process = 'ALTER procedure [dbo].[ccsp_DLRGetDialInfo] --------------'
		set @sql='ALTER procedure [dbo].[ccsp_DLRGetDialInfo]
@callout_id int,
@cam_id smallint=0,
@iPortNumber smallint = 0
AS
set nocount on
declare @message_name as varchar(max), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)
declare @prefix as varchar(15)
declare @tNoContesta as tinyint
declare @ani as varchar(32)
declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint
declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
declare @ivr_script smallint, @surveycamid int
declare @call_record_cam as tinyint
declare @pais as tinyint 

set @prefix =''''
set @tNoContesta = 25
set @ani=''''
set @iTipoDial = 0
set @detectAnswerMachine = 0
set @detectVoiceMail =1
set @cam_tnotas = 30
set @keepDial = 0

select @pais = valor from ccsettings where setting_id = 104

-- Mensajes
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
from dbo.fn_ccCamps_SelMessage(@cam_id)

-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )
-- Prefijo por campaña
if @prefix =''''
    select @prefix = dialPrefix from ccCamps where cam_id = @cam_id
-- Prefijo general, si es que esta habilitado
if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 1 = 1)
    select @prefix = valor from ccsettings where setting_id =101

select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

-- Propiedades de campaña
select @tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0)
from ccCamps C (nolock) where C.cam_id=@cam_id

if @surveycamid > 0
    select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000) 
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

if @iPortNumber >= 0 
begin
    SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)
    , dial_tels
    , C.cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5, isnull(@message_name, '''') as message_name
    , @tNoContesta as tNoContesta, @prefix as sDialPrefix
    , case when dbo.TelAni(c.cal_telefono,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono,@lista_id) else @ani end ani
    , case when dbo.TelAni(c.cal_telefono2,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono2,@lista_id) else @ani end ani2
    , case when dbo.TelAni(c.cal_telefono3,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono3,@lista_id) else @ani end ani3
    , case when dbo.TelAni(c.cal_telefono4,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono4,@lista_id) else @ani end ani4
    , case when dbo.TelAni(c.cal_telefono5,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono5,@lista_id) else @ani end ani5
    , @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail
    , @cam_tnotas cam_tnotas, @keepDial keepDial
    , isnull(@messageDNCL_name, '''') as messageDNCL_name
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5
    , isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name
    , isnull(@MohFiles,'''') as mohFiles
    ,@ivr_script ivrScript
    FROM ccoCallsOutSource C 
    WHERE C.callout_id = @callout_id
    return
end 

set nocount off'
		EXEC(@sql)

		set @process = 'ALTER procedure [dbo].[ccsp_DLRgetDialPrefix] -----------'
		set @sql='ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
@cam_id smallint=0,
@iPortNumber smallint = 0,
@phone varchar(30) = ''''
as
declare @prefix as varchar(15)
declare @ani as varchar(32)
declare @call_record_cam as tinyint
declare @pais as tinyint 
declare @ivr_script smallint, @surveycamid int
declare @call_record bit, @tNoContesta tinyint, @detectAnswerMachine smallint, @detectVoiceMail tinyint

select @pais = valor from ccsettings where setting_id = 104
select @call_record_cam = call_record from ccCamps where cam_id = @cam_id

set @prefix =''''
-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )

-- Prefijo por campaña,
if @prefix =''''
    select @prefix = dialPrefixMan from ccCamps where cam_id = @cam_id

-- Prefijo general
if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 2 = 2)
    select @prefix = valor from ccsettings where setting_id =101

-- Ani
set @ani = dbo.TelAni(@phone, (select id_anilist from ccCamps where cam_id =@cam_id) )

--AnswerMachine Message Files
DECLARE @MsgFiles VARCHAR(8000) 
SELECT @MsgFiles = COALESCE(@MsgFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 8 ORDER BY orden

--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000) 
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

select @surveycamid = 0, @ivr_script = 0

select @tNoContesta = cam_tNoContesta, @ani = case when @ani = '''' then ani else @ani end
,@detectAnswerMachine = detectAnswerMachine, @detectVoiceMail = detectVoiceMail
,@call_record = dbo.EnableCallRecord(@call_record_cam,@pais,@phone), @surveycamid = isnull(surveycamid,0)
from ccCamps where cam_id = @cam_id

if @surveycamid > 0
    select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

select @prefix as sDialPrefix, @tNoContesta as tNoContesta, @ani as ani, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail,
@call_record as call_record, isnull(@MsgFiles,'''') as messageFiles, isnull(@MohFiles,'''') as mohFiles, @ivr_script ivrScript'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE [dbo].[ccsp_IVRChecaInboundHorario] ------------------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_IVRChecaInboundHorario]
@inbound_id int
AS
set nocount on
declare @fecha datetime
declare @dia smallint
declare @hora smallint
declare @minuto smallint
declare @Cuantos smallint
declare @bnocturno smallint
declare @tel_noct varchar(14)
declare @tel_maxqueue varchar(14)
declare @tel_maxwait varchar(14)
declare @tel_outservice varchar(14)
declare @tHoldCall int
declare @OutOFService tinyint
declare @Active tinyint
declare @stopRecording bit
declare @MohFiles varchar(8000)
declare @ivr_script smallint, @surveycamid int

    SET DATEFIRST 1

    select @fecha =  getdate()
    select @surveycamid = 0, @ivr_script = 0
    select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)
    if ( @dia=1 )     --LUNES
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND LUNES = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    if @dia=2   --MARTES
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND MARTES = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    if @dia=3   --MIERCOLES
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND MIERCOLES = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    if @dia=4   --JUEVES
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND JUEVES = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    if @dia=5   --VIERNES
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND VIERNES = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    if @dia=6   --SABADO
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND SABADO = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    if @dia=7   --DOMINGO
    begin
          select @Cuantos = count(*)
          from ccInbound I join ccInboundHorarios IH
          on I.Inbound_id = IH.Inbound_id
          join ccHorarios H on IH.horario_id = H.Horario_id
          Where I.Inbound_id = @inbound_id
          AND DOMINGO = 1
          AND ( @hora > HoraInicio OR ( @hora = HoraInicio AND @minuto >= MinInicio ) )
          AND ( @hora < HoraFin OR ( @hora = HoraFin AND @minuto <= MinFin ) )
    end
    --- Para ver si esta Activa la Especialidad
    select @Active = count(*)
    from ccInbound
    where Inbound_id = @inbound_id
    and Status =1
    --- Para ver si esta en Operacion o No esta Campaña
    select @OutOFService = count(*)
    from ccInbound
    where Inbound_id = @inbound_id
    and standby = 0
    IF ( @OutOFService =1 AND @Active=1 and (select valor from ccsettings where setting_id = 4) = 1)
    BEGIN
--                SI ESTA EN SERVICO
          select  @tHoldCall = tMaxWaitCall, @bnocturno =bnocturno, @stopRecording=stopRecording,
                @tel_noct=tel_noct, @tel_maxqueue=tel_maxqueue, @tel_maxwait=tel_maxwait, @tel_outservice=tel_outservice, @surveycamid = isnull(cam_id,0)
                from ccInbound I
                Where I.Inbound_id = @inbound_id

          if @surveycamid > 0
                select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

          --Custom MOH Files
          SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
          FROM ccInboundMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE Inbound_id = @Inbound_ID and TYPE = 15 ORDER BY orden
    END
    ELSE
    BEGIN
          IF ( @OutOFService = 0 and (select valor from ccsettings where setting_id = 4) = 1)
          BEGIN -- ESPECIALIDAD NO ACTIVA
                select @Cuantos= -1, @tHoldCall =0, @bnocturno ='''', @tel_noct ='''', @tel_maxqueue='''', @tel_maxwait='''', @tel_outservice='''', @MohFiles=''''
                --from ccInbound
                --Where Inbound_id = @inbound_id
          END
          IF ( @Active = 0 )
          BEGIN -- ESPECIALIDAD FUERA DE SERVICIO TEMPORAL
                select @Cuantos= -2, @tHoldCall =0, @bnocturno ='''', @tel_noct ='''', @tel_maxqueue='''', @tel_maxwait='''', @tel_outservice=tel_outservice, @MohFiles=''''
                from ccInbound
                Where Inbound_id = @inbound_id
          END 
    END
    SET DATEFIRST 7

    select ''Cuantos''=@Cuantos, ''tHoldCall''=@tHoldCall, ''bNocturno''=1, ''tel_MaxWait''=@tel_maxwait, ''tel_MaxQueue''=@tel_maxqueue, ''tel_Noct''=@tel_noct, ''tel_outservice''=@tel_outservice, ''stopRecording''=@stopRecording, ''mohFiles''=isnull(@MohFiles,''''), ''ivrScript''=@ivr_script 
set nocount off'
		EXEC(@sql)

	
			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			exec ccsp_getVersion 'BD', @version
			exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ''', version to release: ''' + cast(@version as varchar(5))
	end

set nocount off