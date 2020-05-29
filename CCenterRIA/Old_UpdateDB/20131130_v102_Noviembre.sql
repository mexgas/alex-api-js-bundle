/*
Autor: Raymundo Gonzalez
Fecha: 2013/11/30
Descripcion:
	Se crea el indice IX_ccoCallsOutSource_12 para mejora en el performance del proceso de carga de listas negras
	Se insertan registros en la tabla ccmenus para nuevos reportes
	Se modidica el SP ccsp_RIAUpdateCallBack_Abandon para fix en programación de callbacks
	Se modifica el SP ccsp_ExtAppsCallHistory para devolver la actividad de más de un agente al Web Service
	Se modifica el SP ccsp_InsertDNCList para mejora en el performance del proceso de carga de listas negras
	Se modifica el SP ccsp_IVRChecaInboundHorario para desbordes por tiempo o cola de un ACD
	Se altualizan los registros de desborde en ccInbound a ACD|id si y solo si existen Nombre|ID
Version requerida: 101
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '102'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'IX_ccoCallsOutSource_12 - Create Index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccoCallsOutSource_12]
ON [dbo].[ccoCallsOutSource] ([cal_fechaDial])
INCLUDE ([callout_id],[cam_id],[cal_telefono],[cal_telefono2],[cal_telefono3],[cal_telefono4],[cal_telefono5])'
	
	EXEC(@Sql)

		set @process = 'ccmenus - Insert'
		set @Sql='insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4120,''Llamadas con transferencia|Calls with Transference'',4000,''B'',4,3,'''')
insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3140,''Tiempos|Times'',3000,''B'',3,3,'''')
insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3141,''Abandonadas|Abandoned'',3140,''C'',3,3,'''')
insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3142,''Contestadas|Answered'',3140,''C'',3,3,'''')
insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4130,''Llamadas contestadas por estatus|Answered Calls by Status'',4000,''B'',4,3,'''')
insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (7000,''Especiales|Special'',7000,''A'',7,3,'''')
insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (7010,''Reportes de abandono|Abandon reports'',7000,''B'',7,3,'''')
insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (7020,''Resumen por agente|Agent summary'',7000,''B'',7,3,'''')
insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (7050,''Rend. por asesor|Performance per agent'',7000,''B'',7,3,'''')
insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (7030,''Movimientos por campaña|Movements per campaign'',7000,''B'',7,3,'''')
insert ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (7040,''Promesas por campaña|Promises per campaign'',7000,''B'',7,3,'''')'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIAUpdateCallBack_Abandon - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAUpdateCallBack_Abandon]
@cal_id int,
@nStatus tinyint
as
set nocount on

declare @ANI varchar(13), @cam_id int, @inbound_id int, @fechadial varchar(40), @callout_id int, 
 @statuscall_id_Array varchar(1000), @minCallBackAbandon smallint

select @ANI=C.cal_ANI, @cam_id=I.cam_id, @inbound_id=I.inbound_id, 
@statuscall_id_Array=statuscall_id_Array, @minCallBackAbandon=minCallBackAbandon
from cccallsin C join ccInbound I on I.Inbound_id=C.Inbound_id where cal_id=@cal_id

select @fechadial=convert(varchar(16), dateadd(minute, @minCallBackAbandon, getdate()), 121)

if @nStatus not in (select value from dbo.fn_RIASplitDelimited(@statuscall_id_Array, '','')) or isnull(@cal_id,0)=0
 return(0)

if isnull(@cam_id, 0)=0
	return(0)

if exists (select cal_ANI from ccRIAUpdateCallBack_Abandon where cal_ANI=@ANI)
	return(0)

if (select substring(dbo.completa(@ANI),1,1))= ''E''
	return(0)

 begin try
	insert ccRIAUpdateCallBack_Abandon (cal_id, cal_ANI, cam_id, callout_id, inbound_id, minCallBackAbandon)
	select @cal_id, @ANI, @cam_id, @callout_id, @inbound_id, @fechadial

	select @ANI=dbo.completa(@ANI)
	exec ccsp_INInsertaCallBack @cal_id, @cam_id, @ANI, @fechadial, ''Callback by abandon'', @fechadial, '''', '''', '''', 1, 0

	select top 1 @callout_id=callout_id from ccoWorkingTable WITH(INDEX(PK_ccoWorkingTable)) WHERE cal_telefono=@ANI
	select @fechadial=dateadd(minute, minCallBackAbandonXpire, @fechadial) from ccInbound where Inbound_id=@inbound_id
	update ccRIAUpdateCallBack_Abandon set callout_id=@callout_id, minCallBackAbandonXpire=@fechadial where cal_id=@cal_id
	return(0)
 end try

 begin catch
	return(0)
 end catch
set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_ExtAppsCallHistory - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory]
@action smallint,
@call_id int = 0,
@startDate varchar(30) = null,
@endDate varchar(30) = null,
@state int = 0,
@multipleCall_id as varchar(500) = null,
@multipleUser_id as varchar(500) = null,
@agentId int = 0
AS 

-- INBOUND x cal_id
if @action = 1
 begin
	select top 500 cal_id as call_id,c.inbound_id,isnull(a.descripcion,'''') as acdGroup,cal_ani as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,'''') as login,
	isnull(e.description,'''') as disposition,d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing,  cal_key as callKey
	from cccallsin c with(nolock)
	left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
	left join ccusers b on (c.user_id = b.user_id) 
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalif e on ( c.calif_id = e.calif_id )
	where cal_id >= @call_id
 end

-- OUTBOUND x cal_id
if @action = 2 
 begin
	select top 500 cal_id as call_id,c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,c.cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
	d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_manual as CallManual,  c.cal_key as callKey,
	list_id
	from ccocallsout c with(nolock)
	left join ccocallsoutsource cs (nolock) on (cs.callout_id = c.callout_id)
	left join ccusers b on (c.user_id = b.user_id) 
	left join cccamps a on (c.cam_id = a.cam_id)
	left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
	left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
	where cal_id >= @call_id
 end

if @action = 3 --Session time
	begin
		declare @fecha_ini datetime
		declare @fecha_fin datetime	

		if (@startDate is null or @endDate is null) or (@startDate = '''' or @endDate = '''') begin
			select @fecha_ini = convert(datetime,convert(varchar(30),getdate()))
			select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))	
		end
		else begin
			select @fecha_ini = convert(datetime,convert(varchar(30),@startDate))
			select @fecha_fin = convert(datetime,convert(varchar(30),@endDate))
		end

		select user_id, login, logout, datediff(ss,login,logout) as logintime 
		from(select a.user_id, a.fecha as ''login'',
				(select isnull(max(Fecha),getdate())
					from ccLogLogin b with(nolock)
					where b.user_id = a.user_id and
					b.tipomov = 0 and
					b.fecha >= a.fecha and
					b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
								from ccLogLogin with(nolock)
								where user_id = b.user_id and
								tipomov = 1 and
								fecha > a.fecha)) as ''logout''
				from ccLogLogin a
				where a.tipomov=1
				and fecha >= @fecha_ini
				and fecha <= @fecha_fin) as sessiontime
		order by user_id, login
	end

	if @action = 4 -- Estados de los agentes
	begin	
		select User_id, tStatus, fecha from cclogagentesdia with(nolock) where TipoStatusAge_id = @state and fecha >= @startDate and fecha < @endDate order by User_id,fecha
	end

	if @action = 5 -- Sinlge Call id Inbound
	 begin
		select top 500 cal_id as call_id,c.inbound_id,isnull(a.descripcion,'''') as acdGroup,cal_ani as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,'''') as login,
		isnull(e.description,'''') as disposition,d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_key as callKey
		from cccallsin c with(nolock)
		left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
		left join ccusers b on (c.user_id = b.user_id) 
		left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
		left join ccTipoCalif e on ( c.calif_id = e.calif_id )
		where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') ) 
	 end


	-- Single call_id Outbound
	if @action = 6
	 begin
		select top 500 cal_id as call_id,c.cam_id,isnull(a.cam_descripcion,'''') as Campaign,c.cal_telefono as phoneNumber,isnull(b.user_id,0) as user_id,isnull(login,''''),isnull(e.description,'''') as disposition,
		d.descripcion as call_status,cal_tDialog as call_tDialog,cal_inicio as call_date, cal_tNotas as WrapUp, cal_tXfer as Xfer, cal_tRing as Ringing, cal_manual as CallManual, c.cal_key as callKey,
		cs.list_id
		from ccocallsout c with(nolock)
		left join ccocallsoutsource cs (nolock) on (cs.callout_id = c.callout_id)
		left join ccusers b on (c.user_id = b.user_id) 
		left join cccamps a on (c.cam_id = a.cam_id)
		left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
		left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
		where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') ) 
	 end

if @action = 7 begin --Status Agente
	select tipostatusAge_id, tstatus, dateadd(ss,(-1*tstatus),fecha) from cclogagentesdia with(nolock) where user_id = @agentId and fecha >= @startDate and fecha < @endDate order by fecha
end

if @action = 8 begin
	select tipostatusAge_id, tstatus, dateadd(ss,(-1*tstatus),fecha) fecha,user_id from cclogagentesdia with(index(IX_ccLogAgentesDia_4),nolock) 
	where user_id in (select value from fn_RIASplitDelimited(@multipleUser_id,'','')) and fecha between @startDate and @endDate order by user_id,fecha
end'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_InsertDNCList - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30),
@ln_id as integer
AS

declare @ld varchar(4), @tel as varchar(30)

insert into cclistanegra values(@telephone, @ln_id)

CREATE TABLE [dbo].[#mycamps] (
	[campsid] [int] NULL
	)

CREATE UNIQUE INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select cam_id from Camplistanegra where idtipolista = @ln_id

CREATE TABLE [dbo].[#myprincipaltemp](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE UNIQUE INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltemp]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltemp]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltemp]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltemp]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltemp]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltemp]([cal_telefono5]) 

CREATE TABLE [dbo].[#mytemp](
	[callout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
	)

CREATE UNIQUE INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) 

select @ld = valor from ccSettings where setting_id = 17
select @tel = dbo.completa(@telephone)

declare @Sql nvarchar(max)

set @Sql = ''insert into [#myprincipaltemp] '' +
''SELECT callout_id as callout_id, cam_id,''''3'''','' + cast(@ln_id as nvarchar) + '' as idtipolista , [cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5] '' +
''FROM [ccoCallsOutSource] a inner join #mycamps b on (a.cam_id = b.campsid) '' +
''WHERE ('''''' + @tel + '''''' IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) '' +
''or right('''''' + @tel + '''''',10) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5]) '' +
''or right('''''' + @tel + '''''',11) IN ([cal_telefono] , [cal_telefono2], [cal_telefono3], [cal_telefono4], [cal_telefono5])) '' +
''and  cal_fechadial > dateadd(dd,-30,getdate())''

EXEC(@Sql)

if (select count(*) from #myprincipaltemp with(nolock)) > 0
	begin
		/******************/
		/*** Telefono 1 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where cal_telefono = @tel

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono = wt.cal_telefono
			and rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
								 + cs.cal_telefono3 + ''         ''
								 + cs.cal_telefono4 + ''         ''
								 + cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono2 + ''         ''
												+ cs.cal_telefono3 + ''         ''
												+ cs.cal_telefono4 + ''         ''
												+ cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono1 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 2 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono2,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where cal_telefono2 = @tel

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono2= wt.cal_telefono 
			and rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
								 + cs.cal_telefono4 + ''         ''
								 + cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono3 + ''         ''
												+ cs.cal_telefono4 + ''         ''
												+ cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono2= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono2 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono2 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 3 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono3,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where cal_telefono3 = @tel

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono3= wt.cal_telefono  
			and  rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
								  + cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono4 + ''         ''
												+ cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono3= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono3 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono3 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 4 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono4,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where cal_telefono4 = @tel

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono4= wt.cal_telefono 
			and rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13)) = ''''

			-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
			update ccoWOrkingTable with(rowlock)
			set cal_telefono = rtrim(left(ltrim(cs.cal_telefono5 + ''         ''),13))
			from ccoCallsOutSource cs 
			inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
			inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30 
			and cs.cal_telefono4= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono4 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono4 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30

			truncate table #mytemp
		end

		/******************/
		/*** Telefono 5 ***/
		/******************/
		insert #mytemp
		select callout_id,cal_telefono5,cam_id,tipomov,idtipolista
		from [#myprincipaltemp] with(nolock)
		where cal_telefono5 = @tel

		if (select count(*) from #mytemp with(nolock)) > 0
		begin
			-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
			delete ccoWOrkingTable with(rowlock)
			from ccoWOrkingTable wt 
			inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
			inner join #mytemp t on wt.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
			and cs.cal_telefono5= wt.cal_telefono

			---insertar el historial
			insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
			select * from #mytemp

			-- Eliminamos el telefono5 de CS
			update ccoCallsOutSource with(rowlock)
			set cal_telefono5 = ''''
			from ccoCallsOutSource cs inner join #mytemp t on cs.callout_id = t.callout_id
			where cs.cal_fechadial > getdate()-30
		end
	end

drop table [#myprincipaltemp]
drop table #mytemp
drop table [dbo].[#mycamps]'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_IVRChecaInboundHorario - Alter Procedure'
		set @Sql='ALTER PROCEDURE [dbo].[ccsp_IVRChecaInboundHorario]
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

	SET DATEFIRST 1

	select @fecha =  getdate()
	select @dia = datepart(dw,@fecha), @hora = datepart(hh,@fecha), @minuto = datepart(mi,@fecha)
	if ( @dia=1 )	--LUNES
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
	if @dia=2	--MARTES
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
	if @dia=3	--MIERCOLES
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
	if @dia=4	--JUEVES
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
	if @dia=5	--VIERNES
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
	if @dia=6	--SABADO
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
	if @dia=7	--DOMINGO
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
	--- Para ver si esta en Operacion o No esta Campaa
	select @OutOFService = count(*)
	from ccInbound
	where Inbound_id = @inbound_id
	and standby = 0
	IF ( @OutOFService =1 AND @Active=1 and (select valor from ccsettings where setting_id = 4) = 1)
	BEGIN
--			SI ESTA EN SERVICO
		select  @tHoldCall = tMaxWaitCall, @bnocturno =bnocturno, @stopRecording=stopRecording,
			@tel_noct=tel_noct, @tel_maxqueue=tel_maxqueue, @tel_maxwait=tel_maxwait, @tel_outservice=tel_outservice
			from ccInbound I
			Where I.Inbound_id = @inbound_id
	END
	ELSE
	BEGIN
		IF ( @OutOFService = 0 and (select valor from ccsettings where setting_id = 4) = 1)
		BEGIN -- ESPECIALIDAD NO ACTIVA
			select @Cuantos= -1, @tHoldCall =0, @bnocturno ='''', @tel_noct ='''', @tel_maxqueue='''', @tel_maxwait='''', @tel_outservice=''''
			--from ccInbound
			--Where Inbound_id = @inbound_id
		END
		IF ( @Active = 0 )
		BEGIN -- ESPECIALIDAD FUERA DE SERVICIO TEMPORAL
			select @Cuantos= -2, @tHoldCall =0, @bnocturno ='''', @tel_noct ='''', @tel_maxqueue='''', @tel_maxwait='''', @tel_outservice=tel_outservice
			from ccInbound
			Where Inbound_id = @inbound_id
		END 
	END
	SET DATEFIRST 7

	select ''Cuantos''=@Cuantos, ''tHoldCall''=@tHoldCall, ''bNocturno''=1, ''tel_MaxWait''=@tel_maxwait, ''tel_MaxQueue''=@tel_maxqueue, ''tel_Noct''=@tel_noct, ''tel_outservice''=@tel_outservice, ''stopRecording''=@stopRecording
set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_IVRChecaInboundHorario - Alter Procedure'
		set @Sql= 'update ccinbound set tel_maxqueue = ''ACD''+substring(tel_maxqueue, charindex(''|'', tel_maxqueue), len(tel_maxqueue))
from ccinbound where charindex(''|'', tel_maxqueue) > 0

update ccinbound set tel_maxwait = ''ACD''+substring(tel_maxwait, charindex(''|'', tel_maxwait), len(tel_maxwait))
from ccinbound where charindex(''|'', tel_maxwait) > 0'

	EXEC(@Sql)

	------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			exec dbo.ccsp_getVersion 'BD', @Version

	commit tran
	end try
	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off
