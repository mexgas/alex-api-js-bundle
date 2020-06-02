/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2014/10/06
Description:

	insert into -- ccmenus reportsRIA
	update  QROO -- ccTimeZoneArea
	Drop funcion AuthorizationCallLaw

	Alter SP -- ccsp_RIAInsertChat correcion nodos del finder
	Alter SP -- ccsp_RIACATHorario outbound
	Alter SP -- ccsp_OUTGetNewJobs outbound
	Create SP -- ccsp_CampHorario outbound
	Alter SP -- ccsp_ADMCampHorarios
	Alter SP -- ccsp_ManualCallApplyTimeZoneRules
	Alter SP -- ccsp_OUTcheckTimeZone
	Alter SP -- ccsp_OUTGetNewJobs
	Alter SP -- ccsp_OUTGetNewProviderJobs

Database: CCenterRia
Required version: 115

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 116

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

			/* Start script release */
	set @process = 'insert into -- ccmenus reportsRIA'
	set @sql='if not exists(select * from ccmenus where menu_id = 7000)
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (7000,''Especiales|Special'',7000,''A'',7,3,'''')

if not exists(select * from ccmenus where menu_id = 7090)
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (7090,''Reporte de abandono por porcentaje|Abandon report percentage'',7000,''B'',7,3,'''')

if not exists(select * from ccmenus where menu_id = 7070)
	insert into ccmenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF) values(7070,''MKT Agentes|MKT Agents'',7000,''B'',2,3,'''')

if not exists(select * from ccmenus where menu_id = 7110)
	insert into  ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (7110,''Reporte de abandono por tiempos|Abandon report times'',7000,''B'',7,3,'''')

if not exists(select * from ccmenus where menu_id = 7100)
	insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (7100,''Reporte de abandono perfiles|Abandon report profiles'',7000,''B'',7,3,'''')
'
	EXEC(@sql)


	set @process = 'update  QROO -- ccTimeZoneArea'
	set @sql='update [ccTimeZoneArea] set tz_standard = 32, tz_daylight = 16 where id_country = 1 and location = ''QROO'''
	EXEC(@sql)

	set @process = 'Drop function -- AuthorizationCallLaw'
	set @sql='if exists (select * from sys.objects where object_id = OBJECT_ID(N''AuthorizationCallLaw'') and type in (N''FN''))
begin
	 drop function dbo.AuthorizationCallLaw
end'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_RIAInsertChat'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAInsertChat]
@action int,
@inboundId smallint = 0,
@domain varchar(50) = '''',
@session varchar(50) = '''',
@tTimeout smallint = 0,
@chatId int = 0,
@status tinyInt = 0,
@userId smallint = 0,
@finished tinyInt = 0,
@chattingTime int = 0,
@startTime datetime = null,
@clientName varchar(50) = '''',
@firstMessage int = 0,
@firstMessageTime datetime = null,
@crmNode xml = null,
@supervisor varchar(100) =null,
@template varchar (100)= null,
@ScoreTemplate int = null
AS

declare @xml xml
declare @sql nvarchar(2000)

if @action = 1 begin -- Inserta nuevo chat request /*comentario: se recomienda hacer la busqueda del userid del CRM en esta action*/
	insert into ccRIAChats (domain,session,chatStatus,requestDate,inboundId,clientName)
	values(@domain,@session,@status,getDate(),0,@clientName)
	set @chatId = scope_identity()
	select @chatId
end

else if @action = 2 begin -- Save Initial Info
update ccRIAChats set inboundId = @inboundId, chatStatus = @status, userId = @userId, tTimeout = @tTimeout where chatId = @chatId
end

else if @action = 3 begin -- Update Status
update ccRIAChats set chatStatus = @status where chatId = @chatId
end

else if @action = 4 begin -- Save Final Status
if @firstMessage = 0
	begin
		update ccRIAChats set finishedBy = @finished where chatId = @chatId
	end
else
	begin
		update ccRIAChats set finishedBy = @finished, firstMessageTime  = @firstMessageTime where chatId = @chatId
	end
end

else if @action in (5,6) begin -- Save Chatting Time /*comentario: la insercion del nodo (registro final para el finder) se recomiendo en esta action, no olvidar validar status = 4, finishedby != null y validar los tiempos para garantizar el dato final */
	if @action = 5 begin
		update ccRIAChats set tChatting = @chattingTime, chatDate = @startTime where chatId = @chatId
	end



	select @xml = convert(xml,''<R01 C01="''+convert(varchar(max),chatId)+''" C02="''+convert(varchar(max),isnull(ccinbound.descripcion,''''))+''" C03="''+convert(varchar(max),domain)+''" C04="''+convert(varchar(max), Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno )+
	''" C05="''+convert(varchar(max),tchatting)+''" C06="''+convert(varchar(max),isnull(cctipocalif.[Description],''''))+''" C07="''+convert(varchar(max),isnull(cctipocalifsub.califSubdesc,''''))+''" C08="''+convert(varchar(max),clientname)+''" C09="''+rtrim(ltrim(convert(varchar(23), chatDate, 126)))+
	''" C10="''+convert(varchar(max),isnull(@supervisor,'''') ) + ''" C11="''+convert(varchar(max),isnull(@template,'''') )  + ''" C12="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +  ''"/>'')
	from ccRIAChats
	left outer join ccinbound on ccinbound.inbound_id = ccRIAChats.inboundid
	left outer join ccusers on ccusers.user_id = ccRIAChats.userid
	left outer join cctipocalif on cctipocalif.calif_id = ccRIAChats.disposition
	left outer join cctipocalifsub on cctipocalifsub.califsub_id = ccRIAChats.subdisposition and ccRIAChats.subdisposition <> 0
	where chatId = @chatId and chatStatus = 4 and requestDate is not null and chatDate is not null

	if @xml is not null
	begin
		select @crmNode = node from ccCRMNodes where chatId = @chatId
		if @crmNode is not null
		begin
			set @sql = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R01)[1]'''') ''
			execute sp_executesql @sql,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
		end
		if not exists(select * from ccChatsNode where chatId=@chatId) begin ---insert finder
			insert into ccChatsNode (chatId,node, dateIn,[status]) values (@chatId,@xml, getdate(),0)
		end
		else begin ---update finder<
			update ccChatsNode set [status] = 2, node =@xml  where chatId = @chatId
			select @chatId
		end
	end
end	'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_RIACATHorario'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIACATHorario]
@Descripcion varchar(40) = null,
@horario_id varchar(10) = null,
@HoraInicio varchar(2) = null,
@MinInicio varchar(3) = null,
@HoraFin varchar(2) = null,
@MinFin varchar(2) = null,
@Lunes varchar(1) = null,
@Martes varchar(1) = null,
@Miercoles varchar(1) = null,
@Jueves varchar(1) = null,
@Viernes varchar(1) = null,
@Sabado varchar(1) = null,
@Domingo varchar(1) = null,
@Tipo varchar(2) = null
as
set nocount on
if @Tipo=1
 begin
	select horario_id, Descripcion, dbo.RIAtimeFormat(HoraInicio) as HoraInicio, dbo.RIAtimeFormat(MinInicio) as MinInicio,
	 dbo.RIAtimeFormat(HoraFin) as HoraFin, dbo.RIAtimeFormat(MinFin) as MinFin, cast(Lunes as int) as Lunes,
	 cast(Martes as int) as Martes, cast(Miercoles as int)as Miercoles, cast(Jueves as int) as Jueves,
	 cast(Viernes as int) as Viernes, cast(Sabado as int) as Sabado, cast(Domingo as int) as Domingo
	from ccHorarios Order by Descripcion
	return(0)
 end

if @Tipo=2
 begin
	if exists(select Descripcion from ccHorarios where Descripcion = @Descripcion)
	 begin
	 	select 1, ''Nombre en Uso''
	 	return(0)
	 end

	Insert ccHorarios (Descripcion, HoraInicio, MinInicio, HoraFin, MinFin,
		Lunes, Martes, Miercoles, Jueves, Viernes, Sabado, Domingo)
	Select @Descripcion, @HoraInicio, @MinInicio, @HoraFin, @MinFin,
		@Lunes, @Martes, @Miercoles, @Jueves, @Viernes, @Sabado, @Domingo
	return(0)
 end

if @Tipo=3
 begin
	Update ccHorarios set Descripcion = ISNULL(@Descripcion,Descripcion), HoraInicio=ISNULL(@HoraInicio,HoraInicio),
	MinInicio=ISNULL(@MinInicio,MinInicio), HoraFin=ISNULL(@HoraFin,HoraFin), MinFin=ISNULL(@MinFin,MinFin),
	Lunes=ISNULL(@Lunes,Lunes), Martes=ISNULL(@Martes,Martes), Miercoles=ISNULL(@Miercoles,Miercoles),
	Jueves=ISNULL(@Jueves,Jueves), Viernes=ISNULL(@Viernes,Viernes), Sabado=ISNULL(@Sabado,Sabado),
	Domingo=ISNULL(@Domingo,Domingo) where horario_id = @horario_id

	if @@rowcount>0
		select 0 horario_id, cast(@horario_id as varchar(3)) + ''-'' + Descripcion from ccHorarios Where horario_id = @horario_id
	return(0)
 end

if @Tipo=4
 begin
	if exists(select Horario_id from ccInboundHorarios where horario_id = @horario_id)
	 begin
		select 1, ''Este Horario tiene alguna Especialidad asignada''
		return(0)
	 end

	select @Descripcion = Descripcion from ccHorarios Where horario_id = @horario_id
	Delete ccHorarios Where horario_id = @horario_id
	if @@ROWCOUNT=0
		select 2, ''No se elimino el horario, debido a que este no existe''

	select 0 horario_id, cast(@horario_id as varchar(3)) + ''-'' + @Descripcion Descripcion
	return(0)
 end
 if @Tipo = 5 begin --saber horarios asignados campaña
	select b.cam_id from ccHorarios a inner join ccCampsHorarios b on a.horario_id=b.horario_id where a.horario_id=@horario_id
	return(0)
 end
set nocount off'
	EXEC(@sql)

	set @process = 'Create SP -- ccsp_CampHorario'
	set @sql='CREATE PROCEDURE [dbo].[ccsp_CampHorario]
@campId as int
AS

declare @horaUniversal datetime
declare @isShudulerLey bit, @valueShudulerLey varchar(max),@hourStart int,@hourEnd int,@minStart int,@minEnd int
declare @shourStart varchar(max),@shourEnd varchar(max),@timeMaxContestacion tinyint,@revHorario bit

set @timeMaxContestacion=30
select @timeMaxContestacion=(cam_tNoContesta*2) from cccamps where cam_id=@campId

select @revHorario=valor from ccsettings where setting_id = 112
select @valueShudulerLey = valor from ccsettings where setting_id=166
select @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)) as int),@valueShudulerLey=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
select @timeMaxContestacion=cam_tNoContesta from cccamps where cam_id=@campId

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

select h.horario_id,Descripcion,
	case when HoraInicio>@hourStart then HoraInicio else @hourStart end HoraInicio,
	case when (horaInicio>@hourStart or (horaInicio=@hourStart and MinInicio>=@minStart) ) then MinInicio  else @minStart end MinInicio,
	case when horaFin<@hourEnd then horaFin else @hourEnd end HoraFin,
	case when ((horaFin < @hourEnd or (horaFin=@hourEnd and MinFin<=@minEnd) )) then MinFin  else @minEnd end MinFin,
	Lunes,Martes,Miercoles,Jueves,Viernes,Sabado,Domingo
 into #tempCampLaw
 from cchorarios h
	inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on h.horario_id = ccCampsHorarios.horario_id and ccCampsHorarios.cam_id = @campId
	where  horaInicio between @hourStart and @hourEnd or horaFin between @hourStart and @hourEnd


select distinct horario_id,HoraInicio,MinInicio,horaFin,MinFin into #tempCampLaw2 from
(
	select tz_id,
	dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
	datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora,
	datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
	datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
	from ccTimeZones
)zonas
inner join #tempCampLaw on
(
	(
		hora > HoraInicio OR  (hora = HoraInicio AND minuto >= MinInicio)
	)
	AND
	(
		hora < HoraFin 	OR  (hora = HoraFin AND minuto <= (MinFin-@timeMaxContestacion) )
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

select distinct #tempCampLaw2.horario_id id,
(HoraInicio*3600)+(MinInicio*60) ini,
(HoraFin*3600)+(MinFin*60) fin,
(case when HoraInicio<10 then ''0''+convert(varchar(2),HoraInicio) else convert(varchar(2),HoraInicio) end) + '':'' + (case when MinInicio<10 then ''0''+convert(varchar(2),MinInicio) else convert(varchar(2),MinInicio) end ) as HoraInicio ,
(case when HoraFin<10 then ''0''+convert(varchar(2),HoraFin) else convert(varchar(2),HoraFin) end) + '':'' + (case when MinFin<10 then ''0''+convert(varchar(2),MinFin) else convert(varchar(2),MinFin) end ) as HoraFin
into #tempCamp from #tempCampLaw2

select id,min(ini) ini,max(fin) fin,min(HoraInicio) HoraInicio,max(HoraFin) HoraFin,@timeMaxContestacion timeMaxContestacion
 from(
select distinct min(a.id) id,(a.ini) ini,(case when a.fin>b.fin then a.fin else b.fin end) fin,min(a.HoraInicio) HoraInicio,
max(case when a.fin>b.fin then a.HoraFin else b.HoraFin end) HoraFin
 from #tempCamp a, #tempCamp b
where a.fin>b.ini and b.ini between a.ini and a.fin and a.id <> b.id
group by a.ini,(case when a.fin>b.fin then a.fin else b.fin end)
union
select a.* from #tempCamp a
where a.id not in(select distinct b.id from #tempCamp a, #tempCamp b where a.fin>b.ini and b.ini between a.ini and a.fin and a.id <> b.id)
)x
group by id
order by ini



drop table #tempCamp
drop table #tempCampLaw
drop table #tempCampLaw2'
	EXEC(@sql)


	set @process = 'Alter SP -- ccsp_OUTcheckTimeZone'
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
	where  horaInicio between @hourStart and @hourEnd or horaFin between @hourStart and @hourEnd

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
		hora < HoraFin 	OR  (hora = HoraFin AND minuto <= (MinFin-@timeMaxContestacion) )
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

	set @process = 'Alter SP -- ccsp_ADMCampHorarios'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_ADMCampHorarios]
@cam_id smallint,
@horario_id smallint, -- Si Tipo =2, aqui viene el ID de Horario
@Tipo tinyint -- 1=ALTA, 2=Modificacion, 3=Borrar
AS
declare @Descripcion varchar(40),@valueShudulerLey varchar(max)
declare @idioma bit,@authorizationCallLaw bit,@msgLaw varchar(max)
declare @isShudulerLey bit,@shourStart varchar(max),@shourEnd varchar(max)

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

select @Descripcion=Upper(Descripcion) from ccHorarios where horario_id=@horario_id
if @Tipo=1 begin
	if ( select count(*) from ccCampsHorarios where cam_id = @cam_id and horario_id=@horario_id) > 0
		if @idioma = 1
		select 0, ''Schedule Already Assigned''
		else
		select 0, ''Horario ya Asignado''
	else
	begin
		select @valueShudulerLey = valor from ccsettings where setting_id=166
		select @isShudulerLey = cast(substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)) as int),@valueShudulerLey=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))

		if @valueShudulerLey='''' begin
			set @valueShudulerLey=''0|07:00|22:00''
			update ccsettings set valor=@valueShudulerLey where setting_id=166
		end

		if @isShudulerLey = 1 begin
			select @shourStart=substring(@valueShudulerLey, 0, charindex(''|'',@valueShudulerLey)),@shourEnd=substring(@valueShudulerLey, charindex(''|'',@valueShudulerLey) + 1, len(@valueShudulerLey))
		end
		else begin
			select @shourStart=''07:00'',@shourEnd=''22:00''
		end

		if @isShudulerLey = 0 begin
			set @msgLaw= case when @idioma = 1 then ''You can call 24 hours'' else ''Se podra llamar las 24 horas'' end
		end
		else begin
			set @msgLaw= case when @idioma = 1 then ''Only you can call on schedule ''+ @shourStart + '' to '' + @shourEnd
				else ''Solo se podra llamar en el horario ''+ @shourStart + '' a '' + @shourEnd end
		end
		Insert ccCampsHorarios (cam_id, Horario_id  ) Values ( @cam_id, @horario_id )
		if @idioma = 1
		select -1, ''Schedule: '' + @Descripcion + '' Assigned to the Campaign OK\n''+@msgLaw
		else
		select -1, ''Horario: '' + @Descripcion + '' Asignado en la Campaña OK\n''+@msgLaw
	end
end
if ( @Tipo=3 )
begin
	Delete ccCampsHorarios where cam_id = @cam_id and horario_id=@horario_id
	if @idioma = 1
	select -1, ''Schedule: '' + @Descripcion + '' Removed from Campaign''
	else
	select -1, ''Horario: '' + @Descripcion + '' Removido de la Campaña''
end'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_ManualCallApplyTimeZoneRules'
	set @sql='ALTER procedure [dbo].[ccsp_ManualCallApplyTimeZoneRules]
@campid as int, @tel varchar(15) as

set nocount on

declare @bIsDaylight bit
declare @revHorario bit
declare @country_id int
declare @iZonas int
declare @sql varchar(MAX)
declare @izonahoraria int
declare @izonahoraria_verano int
DECLARE @iZonasTable TABLE (value int)

create table #TimeZone(
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
izonahoraria int,
izonahoraria_verano int
)

/*** Revisa zona horaria incluyendo de verano ***/
select @izonahoraria = dbo.fnGetTimeZone(@tel,0)
select @izonahoraria_verano = dbo.fnGetTimeZone(@tel,1)

insert into #TimeZone
values (@campid,@tel,@izonahoraria,@izonahoraria_verano)

/*** Valida el pais y la lada configurada ***/
SELECT @country_id = valor  FROM ccSettings  WHERE setting_id = 104

select @revHorario = valor  from ccsettings  where setting_id = 112

/*** Coloca el primer dia de la semana a Lunes ***/
SET DATEFIRST 1

/*** Se revisa si es horario de verano ***/
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
select @iZonas=value from @iZonasTable

/*** Se revisa si la campaña tiene horarios configurados ***/
if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid) begin
	if @iZonas = 0
		begin
			SELECT 0 as CanCall,0 as CanCallLaw
			return
		end
end

set @izonahoraria = case @bIsDaylight when 1 then @izonahoraria_verano else @izonahoraria end

set @sql = ''CREATE TABLE #NEW_JOBS(
cam_id int,
cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS)

INSERT #NEW_JOBS
SELECT cam_id, '' + @tel + ''
FROM #TimeZone
WHERE cam_id = '' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
and (((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0))

if (SELECT count(*) FROM #NEW_JOBS where len(cal_telefono)>0) > 0
	begin
		select 1 as CanCall , 1 as CanCallLaw
	end
else
	begin
		select 0 as CanCall,0 as CanCallLaw
	end

DROP table #NEW_JOBS''

exec(@sql)

DROP table #TimeZone

set nocount off'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_OUTGetNewJobs'
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
		SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,
		izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
		izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2,
		izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3,
		izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4,
		izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
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
		SELECT callout_id, W.cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,
		izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
		izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2,
		izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3,
		izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4,
		izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5,
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
	set @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
	user_id, tz, tz2, tz3, tz4, tz5, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0''
end

set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print (@sql)
exec(@sql)

return(0)'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_OUTGetNewProviderJobs'
	set @sql='ALTER procedure [dbo].[ccsp_OUTGetNewProviderJobs]
@CAMPID as int,
@test as int=0,
@nAgentsLogin as int=1
as
set nocount on
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @sql varchar(MAX), @Order_Asc_Desc char(4)
declare @camSurvey int
DECLARE @iZonasTable TABLE (value int)

select @camSurvey = 0

select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

-- VALIDAMOS EL PAIS Y LADA CONFIGURADA --
SELECT @country_id =valor FROM ccSettings WHERE setting_id=104
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
		declare @horaUniversal as datetime
		set @horaUniversal=getutcdate()

		if @iZonas = 0 begin
			SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
			return
		end
		end

	else
	begin
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
tel varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel2 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel3 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel4 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
tel5 varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
dialOrder varchar(10),
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
set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
	begin
	select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

	select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isnull(R.sequence,0) as sequence
	FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
	on W.list_id = R.list_id
	left join ccocallsoutsource couts
	on W.callout_id = couts.callout_id
	WHERE W.cal_status=1 -- CallBacks
	and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
	and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
	and (
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by W.prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
	end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
	begin
	select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

	select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
	SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+'' as tz,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 as tz2,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 as tz3,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 as tz4,
	W.izonahoraria'' +case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 as tz5,
	couts.cal_telefono as tel,
	couts.cal_telefono2 as tel2,
	couts.cal_telefono3 as tel3,
	couts.cal_telefono4 as tel4,
	couts.cal_telefono5 as tel5, couts.dial_tels as dialOrder, W.list_id, isNull(R.sequence,0) as sequence
	FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists))
	on W.list_id = R.list_id
	left join ccocallsoutsource couts
	on W.callout_id = couts.callout_id
	WHERE W.cal_status=0 -- Nuevas sin Tiempo
	and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
	and (
		( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
		( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
		((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
	or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
	)
	and isnull(R.status,2) = 2
	order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', W.callout_id''

	end -- TOMA EN CUENTA LAS NUEVAS

----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @sql=@sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
	begin
	select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
	WHERE callout_id in(select callout_id from #NEW_JOBS)''
	end

select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
user_id, tz, tz2, tz3, tz4, tz5, tel, tel2, tel3, tel4, tel5, dialOrder, list_id, sequence FROM #NEW_JOBS where len(cal_telefono)>0''

select @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
--print @sql
exec(@sql)
return(0)'
	EXEC(@sql)

			/* End script release */

			/* Upgrade database version (use your own script to do it) */
			exec ccsp_getVersion 'BD', @version

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off