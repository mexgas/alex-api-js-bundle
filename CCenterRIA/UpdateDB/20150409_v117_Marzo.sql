/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Jesus Gallardo
Date: 2014/10/06
Description:

	Create table -- SeriesSV
	ALTER TABLE  -- ccTipoCalif
	ALTER TABLE -- cctipocalifSub


	insert into -- ccRIACat_Country
	update ccsettings -- detalle Pais Salvador
	insert cstoTipoLlamada -- Salvador

	update ccmenus -- menu_descrip
	update ccMenus -- parent
	UPDATE dbo.ccMenus -- Nivel
	update ccmenus -- ordengral

	Alter function -- Verifica
	Alter function -- TelAni
	Alter FUNCTION -- Completa_ListaNegra
	Alter FUNCTION -- Completa
	Alter function -- fnGetTimeZone

	Alter SP -- ccsp_RIAccSettingsConfig
	Alter SP -- ccspADM_AniListLD
	Alter SP -- ccsp_RIAAgentGetDialMask
	Alter SP -- ccsp_Limpia

	Alter SP -- ccsp_RIALoadACDGroups
	Alter SP -- ccsp_RIACATQualifications
	Alter SP -- Alter SP -- ccsp_AgentGetCalificaciones
	ALTER SP -- ccsp_RIAScheduleEsp
	ALTER SP -- ccsp_RIAInsertChat


Database: CCenterRia
Required version: 116

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 117

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

			/* Start script release */
	set @process = 'CREATE TABLE -- ccRIAImages'
	set @sql='if not exists (select * from sys.tables where name = N''ccRIAImages'')
	CREATE TABLE [dbo].[ccRIAImages](
		[idImage] [smallint] IDENTITY(1,1) NOT NULL,
		[path] [varchar](100) NOT NULL
	) ON [PRIMARY]'
	EXEC(@sql)

	set @process = 'Create table -- SeriesSV'
	set @Sql='if not exists (select * from sys.tables where name = N''SeriesSV'') begin
create table SeriesSV(
zonaGeografica varchar (50),
indicativoDestino varchar(3),
rangoInicio varchar(8),
rangoFinal varchar(8))
end
'
	EXEC(@sql)

	set @process = 'ALTER TABLE  -- ccTipoCalif'
	set @sql='if not exists (select * from sys.columns where name = N''EndConversation'' and Object_ID = Object_ID(N''ccTipoCalif'')) ALTER TABLE ccTipoCalif ADD EndConversation bit default (0)'
	EXEC(@sql)

	set @process = 'ALTER TABLE -- cctipocalifSub'
	set @sql='if not exists (select * from sys.columns where name = N''EndConversation'' and Object_ID = Object_ID(N''cctipocalifSub''))  ALTER TABLE cctipocalifSub ADD EndConversation bit default (0)'
	EXEC(@sql)

	set @process = 'update cctipocalifSub -- EndConversation'
	set @sql='update ccTipoCalif set EndConversation=0'
	EXEC(@sql)

	set @process = 'update cctipocalifSub -- EndConversation'
	set @sql='update cctipocalifSub set EndConversation=0'
	EXEC(@sql)

	set @process = 'insert into -- SeriesSV'
	set @sql='if not exists (select * from SeriesSV where zonaGeografica=''Fijo'') begin
	insert into SeriesSV (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Fijo'',2,''0000000'',''9999999'')
insert into SeriesSV (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Movil'',6,''0000000'',''9999999'')
insert into SeriesSV (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Movil'',7,''0000000'',''9999999'')
end'
	EXEC(@sql)

	set @process = 'insert cstoTipoLlamada -- Salvador'
	set @sql='if not exists (select * from cstoTipoLlamada where country_id=13) begin
	insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (13,1,''Fijo'',8,''2%'')
insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (13,2,''Movil'',8,''6%|7%'')
insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (13,3,''LD Internacional'',0,''00%'')
end'
	EXEC(@sql)

	set @process = 'insert into -- ccRIACat_Country'
	set @sql='if not exists (select * from ccRIACat_Country where CtyName=''Salvador'')
	insert into dbo.ccRIACat_Country ( CtyName,CtyCode, minPhoneLength, maxPhoneLength) values (''Salvador'',503,8,8)'
	EXEC(@sql)


	set @process = 'update ccsettings -- detalle Pais Salvador'
	set @sql='update ccsettings
set detalle=''1:Mexico, 2:Argentina, 3:Colombia, 4:USA, 5:Chile, 6: Venezuela, 7: Reino Unido, 8: Arabia saudita, 9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador''
where setting_id=104'
	EXEC(@sql)


	set @process = 'update ccmenus -- menu_descrip'
	set @sql='update ccmenus set menu_descrip=''Recursos Humanos|Human Resources'' where menu_id=2
update ccmenus set menu_descrip=''Gestión de áreas|Areas Management'' where menu_id=3
update ccmenus set menu_descrip=''Vista de áreas|Areas View'' where menu_id=45
update ccmenus set menu_descrip=''Vista de grupos de trabajo|Workgroups View'' where menu_id=46
update ccmenus set menu_descrip=''Gestión de grupos de trabajo|Workgroups Management'' where menu_id=4
update ccmenus set menu_descrip=''Gestión de grupos de mi área|My Area Workgroups Management'' where menu_id=50
update ccmenus set menu_descrip=''Formatos de evaluación|Scoring Templates'' where menu_id=74
update ccmenus set menu_descrip=''Permisos de agente|Agent Permissions'' where menu_id=5
update ccmenus set menu_descrip=''Gestión de roles|Management Profiles'' where menu_id=65
update ccmenus set menu_descrip=''Permisos de menú|Administrator Menu Rights'' where menu_id=29
update ccmenus set menu_descrip=''Permisos de administrador|Administrator Permissions'' where menu_id=49
update ccmenus set menu_descrip=''Tipos de no disponible|Unavailable Options'' where menu_id=7
update ccmenus set menu_descrip=''Administradores conectados|Administrators Online'' where menu_id=64
update ccmenus set menu_descrip=''Configuración|Configuration'' where menu_id=10
update ccmenus set menu_descrip=''Horarios|Schedules'' where menu_id=11
update ccmenus set menu_descrip=''Inicio automático|Auto Start Configuration'' where menu_id=12
update ccmenus set menu_descrip=''Vista|View'' where menu_id=47
update ccmenus set menu_descrip=''Carga de base de datos|Data Import'' where menu_id=13
update ccmenus set menu_descrip=''Calificaciones|Dispositions'' where menu_id=15
update ccmenus set menu_descrip=''Mensajes de audio|Audio Messages Assignment'' where menu_id=54
update ccmenus set menu_descrip=''Asociación de encuesta|Survey Association'' where menu_id=70
update ccmenus set menu_descrip=''Llamadas por agente|Calls per Agent'' where menu_id=58
update ccmenus set menu_descrip=''Números ANI por clave lada|Local ANI'' where menu_id=63
update ccmenus set menu_descrip=''Asignación de puertos|Dialer Ports Assignment'' where menu_id=14
update ccmenus set menu_descrip=''Monitor de puertos|Dialer Ports Monitor'' where menu_id=69
update ccmenus set menu_descrip=''Configuración|Configuration'' where menu_id=17
update ccmenus set menu_descrip=''Horarios|Schedules'' where menu_id=18
update ccmenus set menu_descrip=''Mensajes de audio|Audio Messages Assignment'' where menu_id=19
update ccmenus set menu_descrip=''Números DNIS|DNIS Assignment'' where menu_id=20
update ccmenus set menu_descrip=''Calificaciones|Dispositions'' where menu_id=21
update ccmenus set menu_descrip=''Asociación de campaña|Campaign Association'' where menu_id=52
update ccmenus set menu_descrip=''Configuración de callbacks|Callbacks Configuration'' where menu_id=57
update ccmenus set menu_descrip=''Plantillas de chat|Web Chat Templates'' where menu_id=79
update ccmenus set menu_descrip=''Listas Negras|Do Not Call List''  where menu_id=22
update ccmenus set menu_descrip=''Catálogo|Management'' where menu_id=23
update ccmenus set menu_descrip=''Carga|Import'' where menu_id=24
update ccmenus set menu_descrip=''Historial de carga|Import Log'' where menu_id=26
update ccmenus set menu_descrip=''Búsqueda|Search'' where menu_id=27
update ccmenus set menu_descrip=''Asignación de campaña|Campaign Assignment'' where menu_id=44
update ccmenus set menu_descrip=''Asignación de calificación|Disposition Assignment'' where menu_id=48
update ccmenus set menu_descrip=''Asignación de grupo ACD|ACD Group Assignment'' where menu_id=62
update ccmenus set menu_descrip=''Guion de agentes|Scripting'' where menu_id=72
update ccmenus set menu_descrip=''Acerca de ...|About'' where menu_id=40
update ccmenus set menu_descrip=''Temas de ayuda|Help Contents'' where menu_id=61
update ccmenus set menu_descrip=''Configuraciones avanzadas|Advanced Configuration'' where menu_id=30
update ccmenus set menu_descrip=''Historial de cambios|Administrator Changes Log'' where menu_id=43
update ccmenus set menu_descrip=''Perfiles de exportación|Export Profiles'' where menu_id=75
update ccmenus set menu_descrip=''Configuración de AVRS|AVRS Configuration'' where menu_id=76
update ccmenus set menu_descrip=''Catálogo de mensajes|Audio Messages Import'' where menu_id=35
update ccmenus set menu_descrip=''Configuración de posiciones|Workstations Configuration'' where menu_id=42
update ccmenus set menu_descrip=''Configuración de buzón de voz|Voicemail Configuration'' where menu_id=56
update ccmenus set menu_descrip=''Puertos de marcación|Dialer Ports'' where menu_id=36
update ccMenus set menu_descrip=''Medios unificados|Unified Media''  where menu_id=80
update dbo.ccMenus set menu_descrip=''Acerca de ...|About'' where menu_id=40
update ccmenus set menu_descrip=''Configuración de vistas|View Configuration'' where menu_id=59'
	EXEC(@sql)

	set @process = 'update ccMenus -- parent'
	set @sql='update dbo.ccMenus set parent=2 where menu_id=64
update dbo.ccMenus set parent=2 where menu_id=74
update dbo.ccMenus set parent=9 where menu_id=69
update dbo.ccMenus set parent=9 where menu_id=38
update dbo.ccMenus set parent=0 where menu_id=73
update dbo.ccMenus set parent=16 where menu_id=59
update dbo.ccMenus set parent=32 where menu_id=75
update dbo.ccMenus set parent=32 where menu_id=42
update dbo.ccMenus set parent=32 where menu_id=59
update dbo.ccMenus set parent=32 where menu_id=76
UPDATE dbo.ccMenus SET PARENT=80 WHERE MENU_ID=83
UPDATE dbo.ccMenus SET PARENT=80 WHERE MENU_ID=71
update dbo.ccMenus set parent=60 where menu_id=40
update dbo.ccMenus set parent=0 where menu_id=80
update dbo.ccMenus set parent=80 where menu_id=79
'
	EXEC(@sql)

	set @process = 'UPDATE dbo.ccMenus -- Nivel'
	set @sql='UPDATE dbo.ccMenus set parent=0,Nivel=''A''  where menu_id=80
update dbo.ccMenus set Nivel=''B'' where menu_id=40
update dbo.ccMenus set Nivel=''A'' where menu_id=61
'
	EXEC(@sql)

	set @process = 'update ccmenus -- ordengral'
	set @sql='update ccmenus set ordengral=41 where menu_id=23
update ccmenus set ordengral=42 where menu_id=24
update ccmenus set ordengral=43 where menu_id=26
update ccmenus set ordengral=44 where menu_id=44
update ccmenus set ordengral=46 where menu_id=48
update ccmenus set ordengral=45 where menu_id=62
update ccmenus set ordengral=47 where menu_id=27
update ccmenus set ordengral=42 where  menu_id=23
update ccmenus set ordengral=41 where  menu_id=24
update ccmenus set ordengral=2 where menu_id=45
update ccmenus set ordengral=3 where menu_id=3
update ccmenus set ordengral=4 where menu_id=46
update ccmenus set ordengral=5 where menu_id=4
update ccmenus set ordengral=6 where menu_id=50
update ccmenus set ordengral=7 where menu_id=49
update ccmenus set ordengral=8 where menu_id=29
update ccmenus set ordengral=9 where menu_id=53
update ccmenus set ordengral=10 where menu_id=8
update ccmenus set ordengral=11 where menu_id=65
update ccmenus set ordengral=12 where menu_id=64
update ccmenus set ordengral=13 where menu_id=74
update ccmenus set ordengral=22 where menu_id=47
update ccmenus set ordengral=23 where menu_id=10
update ccmenus set ordengral=24 where menu_id=11
update ccmenus set ordengral=25 where menu_id=12
update ccmenus set ordengral=26 where menu_id=13
update ccmenus set ordengral=27 where menu_id=15
update ccmenus set ordengral=28 where menu_id=54
update ccmenus set ordengral=29 where menu_id=70
update ccmenus set ordengral=30 where menu_id=58
update ccmenus set ordengral=31 where menu_id=63
update ccmenus set ordengral=32 where menu_id=14
update ccmenus set ordengral=33 where menu_id=69
update ccmenus set ordengral=34 where menu_id=38
update ccmenus set ordengral=18 where menu_id=17
update ccmenus set ordengral=19 where menu_id=18
update ccmenus set ordengral=20 where menu_id=20
update ccmenus set ordengral=21 where menu_id=21
update ccmenus set ordengral=22 where menu_id=19
update ccmenus set ordengral=23 where menu_id=52
update ccmenus set ordengral=24 where menu_id=57
update ccmenus set ordengral=33 where menu_id=36
update ccmenus set ordengral=34 where menu_id=42
update ccmenus set ordengral=35 where menu_id=35
update ccmenus set ordengral=36 where menu_id=55
update ccmenus set ordengral=37 where menu_id=75
update ccmenus set ordengral=38 where menu_id=51
update ccmenus set ordengral=39 where menu_id=43
update ccmenus set ordengral=40 where menu_id=56
update ccmenus set ordengral=41 where menu_id=59
update ccmenus set ordengral=42 where menu_id=76
update ccmenus set ordengral=43 where menu_id=30
update ccmenus set ordengral=83 where menu_id=71
update ccmenus set ordengral=81 where menu_id=72
update ccmenus set ordengral=84 where menu_id=79
update ccmenus set ordengral=82 where menu_id=83
'
	EXEC(@sql)

	set @process = 'Alter function -- fnGetTimeZone'
	set @sql='ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
RETURNS int
AS
 BEGIN
	declare @lada as varchar(5)
	declare @timeZone as int

	select @lada = valor from ccsettings where setting_id = 17

	declare @country as tinyInt
	select @country = valor from ccSettings where setting_id = 104

		if @country = 1 begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
			where id_country = @country and (
			( len(@phone) = 8 and @lada = area and len(area) = 2 )
			or
			( len(@phone) = 7 and @lada = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 2) = area and len(area) = 2 ))
		end

		if @country = 2 begin
			declare @telTemp varchar(15)
			set @telTemp = @phone
			select @phone = dbo.Completa(@phone)
			if left(@phone,1) = ''E'' begin set @phone = @telTemp end
			select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaArgDetail where
						( len(@phone) = 6 and @lada = area and len(area) = 4 )
						or
						( len(@phone) = 7 and @lada = area and len(area) = 3 )
						or
						( len(@phone) = 8 and @lada = area and len(area) = 2 )
						or
						( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
						or
						( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
						or
						( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
						or
						( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
						or
						( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
						or
						( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 )
						if @timeZone is null
							begin
								select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
								where id_country = @country and (
									( len(@phone) = 6 and @lada = area and len(area) = 4 )
									or
									( len(@phone) = 7 and @lada = area and len(area) = 3 )
									or
									( len(@phone) = 8 and @lada = area and len(area) = 2 )
									or
									( len(@phone) = 11 and substring(@phone, 2, 2) = area and len(area) = 2 )
									or
									( len(@phone) = 11 and substring(@phone, 2, 3) = area and len(area) = 3 )
									or
									( len(@phone) = 11 and substring(@phone, 2, 4) = area and len(area) = 4 )
									or
									( len(@phone) = 13 and substring(@phone, 2, 2) = area and len(area) = 2 )
									or
									( len(@phone) = 13 and substring(@phone, 2, 3) = area and len(area) = 3 )
									or
									( len(@phone) = 13 and substring(@phone, 2, 4) = area and len(area) = 4 ))
							end
		end

	if @country = 3 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 7 and @lada = area )
		or
		( len(@phone) = 8 and left(@phone,1) = area )
		or
		( len(@phone) in(10,11) and (left(@phone,1) = ''3'' or substring(@phone,2,1) = ''3'')))
	end

	if @country = 4

		begin
			select @timeZone =  case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneAreaUsaDetail where
			( len(@phone) = 7 and @lada = area and len(area) = 3 )
			or
			( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 and left(right(@phone, 7), 3) = prefix)
			if @timeZone is null
				begin
					select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
					where id_country = @country and (
					( len(@phone) = 7 and @lada = area and len(area) = 3 )
					or
					( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
				end
		end

	if @country = 5 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 6 and @lada = area )
		or
		( len(@phone) = 7 and @lada = area )
		or
		( len(@phone) = 8 and left(@phone,1) = area )
		or
		( len(@phone) = 8 and left(@phone,2) = area )
		or
		( len(@phone) = 9 and left(@phone,2) = area )
		or
		( len(@phone) = 10 and substring(@phone,3,1) = area and left(@phone,2) = ''09'' ))
	end

	if @country = 6 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end  from ccTimeZoneArea
		where id_country = @country and (
		( len(@phone) = 7 and @lada = area and len(area) = 3 )
		or
		( len(@phone) >= 10 and left(right(@phone, 10), 3) = area and len(area) = 3 ))
	end

	if @country = 7 begin
		declare @phoneTemp as varchar(10)
		select @phoneTemp = right ( @phone, 10 )
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
		where id_country = @country and (
		(len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 9 and left(@phoneTemp,5) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,4) = area ) or
		(len(@phoneTemp) = 9 and left(@phoneTemp,4) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,3) = area ) or
		(len(@phoneTemp) = 10 and left(@phoneTemp,2) = area )
		)
	end

	if @country = 8 begin
		select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
		where id_country = @country and (
		(len(@phone) = 7 and @lada = area) or
		(len(@phone) = 9 and substring(@phone, 2, 1) = area) or
		(len(@phone) = 10 and substring(@phone, 2, 1) = area) or
		(len(@phone) = 11 and substring(@phone, 2, 1) = area))
	end

	if @country = 9 begin
		select @phone = dbo.Completa(@phone)
		-- len(@phone) = 10
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
			where id_country = @country and (
			(convert (int, substring(@phone, 1, 4)) = convert (int, area) and len(area) = 4) or
			(convert (int, substring(@phone, 1, 2)) = convert (int, area) and len(area) = 2))
		end
	end

	if @country = 10 begin
		select @phone = dbo.Completa(@phone)
		-- 8 <= len(@phone) <= 19
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then tz_daylight else tz_standard end from ccTimeZoneArea
			where id_country = @country and (
			((len(@phone) between  8 and  9)                                      and                   @lada = area) or
			((len(@phone) between 10 and 11)                                      and substring(@phone, 1, 2) = area) or
			((len(@phone) between 12 and 13) and substring(@phone, 1, 4) = ''9090'' and                   @lada = area) or
			((len(@phone)       = 13       )                                      and substring(@phone, 4, 2) = area) or
			((len(@phone) between 14 and 15) and substring(@phone, 1, 2) = ''90''   and substring(@phone, 5, 2) = area) or
			((len(@phone)       = 14       ) and substring(@phone, 1, 1) = ''0''    and substring(@phone, 4, 2) = area))
		end
	end

	if @country = 11 begin
		select @phone = dbo.Completa(@phone)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	if @country = 12 begin
		select @phone = dbo.Completa(@phone)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	if @country = 13 begin
		select @phone = dbo.Completa(@phone)
		if (substring(@phone, 1, 1) <> ''E'') begin
			select @timeZone = case @bIsDaylight when 1 then 32 else 64 end
		end
	end

	return isNull(@timeZone,0)
 END'
	EXEC(@sql)


	set @process = 'Alter FUNCTION -- Completa'
	set @sql='ALTER function [dbo].[Completa](@Cadena varchar(32))
RETURNS varchar(32)
AS
BEGIN
declare @resultado varchar(32)
declare @ld varchar(5)
declare @pais varchar(2)

select @pais = valor from ccSettings where setting_id = 104
select @ld = valor from ccSettings where setting_id = 17
select @resultado = dbo.limpia(@Cadena)

--Completa 1:México 2:Argentina 3:Colombia 4:USA 5:Chile 6: venezuela 7: UK 8: arabia saudita 9: Australia 10:Brasil 11:Guatemala 12:Costa Rica 13:Salvador
if @pais = 1
 begin
	--Empieza Mexico
	select @resultado = case
	 when (len(@resultado)=8 and len(@ld)=2) or (len(@resultado)=7 and len(@ld)=3) then @resultado
	 when len(@resultado)=10 then
	   case when left(@resultado, len(@ld)) = @ld
		then right(@resultado, 10 - len(@ld)) else ''01'' + @resultado end
	 when len(@resultado)=12 then
	   case when left(@resultado, 2) = ''01'' then
		 case when substring(@resultado, 3, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	 when len(@resultado)=13 then
	   case when left(@resultado, 3) in (''044'', ''045'') then
		 case when substring(@resultado, 4, len(@ld)) = @ld then
		   ''044'' + right(@resultado, 10) else ''045'' + right(@resultado, 10)
		 end
	   else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	--Termina Mexico
	return @resultado
 end

if @pais = 2
 begin
	-- Empieza Argentina
	select @resultado = case
	 when (len(@resultado)=7 and len(@ld)=3) or (len(@resultado)=6 and len(@ld)=4) then
		@resultado
	-- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
	-- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
	 when len(@resultado) = 8 then
		case when len(@ld) = 4 then
			case when left(@resultado,2) = ''15'' then @resultado end
		else
			case when len(@ld) = 2 then @resultado end
		end
	-- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
	 when len(@resultado)=9 then
		case when left(@resultado, 2) = ''15'' then @resultado else ''E_NV_Cel'' end
	-- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
	 -- Si es diferente se le agrega un 0 para llamadas de larga distancia
	 when len(@resultado)=10 then
	   case when left(@resultado, len(@ld)) = @ld
		then right(@resultado, 10 - len(@ld)) else
			case when left(@resultado,2) = ''15'' then @resultado else ''0'' + @resultado end
	   end
	-- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
	-- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
	 when len(@resultado)=11 then
	   case when left(@resultado, 1) = ''0'' then
		 case when substring(@resultado, 2, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	-- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
	-- si no es local se le agrega el 0 y se marca el numero
	 when len(@resultado)=12 then
		case when left(@resultado, len(@ld)) = @ld then
			case when substring(@resultado, len(@ld) + 1, 2) = ''15'' then
				right(@resultado,12 - len(@ld)) else ''E_NV_Cel'' end else ''0'' + @resultado end
	-- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
	 when len(@resultado)=13 then
		case when left(@resultado, 1) = ''0'' then
			case when substring(@resultado, 2, len(@ld)) = @ld then substring(@resultado, len(@ld) + 2, 12 - len(@ld)) else @resultado end
		else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	--Termina Argentina
	return @resultado
 end

if @pais = 3
 begin
	--Empieza colombia
	select @resultado = case
	--Si son 7 digitos, se regresa igual
	 when len(@resultado)=7 then
		@resultado
	--Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
	 when len(@resultado) = 8  then
		case when left(@resultado,1) = @ld then right(@resultado,7) else @resultado end
	-- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
	 when len(@resultado)=10 then
		case when left(@resultado,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then ''0'' + @resultado
		else
			''E_NV_Cel''
		end
	--Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
	--prefijo de celular
	 when len(@resultado)=11 then
		case when left(@resultado,1)=''0'' then
			case when substring(@resultado,2,3) in (''300'',''301'',''302'',''303'',''304'',''305'',''310'',''311'',''312'',''313'',''314'',''315'',''316'',''317'',''318'',''319'',''320'') then @resultado else ''E_NV_Cel'' end
		else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	-- Termina Colombia
	return @resultado
 end

if @pais = 4
 begin
	--Empieza USA
	select @resultado = case len(@resultado)
	 when 3 then
		case @resultado when ''911'' then @resultado else ''E_NV_Longitud'' end
	 when 7 then @resultado
	 when 10 then
	   case when left(@resultado, len(@ld)) = @ld
		then right(@resultado, 10 - len(@ld)) else ''1'' + @resultado end
	 when 11 then
	   case when left(@resultado, 1) = ''1'' then
		 case when substring(@resultado, 2, len(@ld)) = @ld
		   then right(@resultado, 10 - len(@ld)) else @resultado end
		else ''E_NV_LD'' end
	else ''E_NV_Longitud'' end

	--Termina USA
	return @resultado
 end

if @pais = 5
 begin
	select @resultado = case len(@resultado)
	 when 6 then @resultado
	 when 7 then @resultado
	-- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
	 when 8 then

		case when @ld = left(@resultado,len(@ld)) then right(@resultado,8-len(@ld)) else
			case when left(@resultado,1) in (8,9) then ''09'' + @resultado else
				case when left(@resultado,1) = ''6'' then case when left(@resultado,2) in (61,63,64,65,67) then  @resultado else ''09'' + @resultado end
				 else case when left(@resultado,1) = ''7'' then case when left(@resultado,2) in (71,72,73,75) then @resultado else ''09'' + @resultado end else @resultado end end
			 end
		end
	-- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
	-- de telefonia voIp se le agrega el 0 al inicio
	 when 9 then
		case when @ld = left(@resultado,2) then right(@resultado,7) else
			case when left(@resultado,2) in (41,32,65) then @resultado else
				case when left(@resultado,2) = ''44'' then ''0'' + @resultado else
					case when left(@resultado,1) = ''9'' and substring(@resultado,2,1) in (6,7,8,9) then ''0'' + @resultado else ''E_NV_Longitud'' end
				 end
			end
		end
	 when 10 then
		case when left(@resultado,2) = ''09'' then @resultado else ''E_NV_Cel'' end
	else ''E_NV_Longitud'' end

	-- Termina Chile
	return @resultado
 end

-- Venezuela
if @pais = 6 begin
	select @resultado = case len(@resultado)
		when 7 then @resultado
		when 10 then ''0'' + @resultado
		when 11 then
			case when left(@resultado,1) = ''0'' then @resultado else ''E_NV_Longitud'' end
		else
		''E_NV_Longitud'' end
end
--Termina Venezuela

-- UK
if @pais = 7 begin
	select @resultado = case len(@resultado)
		when 11 then
			case left(@resultado,1)
				when ''0'' then @resultado else ''E_NV_Longitud''
			end
		when 10 then
			case left(@resultado,1)
				when ''0'' then @resultado else ''0'' + @resultado
			end
		when 9 then
			case when left(@resultado,1) <> ''0'' then ''0'' + @resultado else ''E_NV_Longitud'' end
		when 8 then
			case when substring(@resultado, 1, 2) = ''08'' then @resultado else ''E_NV_Longitud'' end
		when 7 then
			case when left(@resultado,1) = ''8'' then ''0'' + @resultado else ''E_NV_Longitud'' end
		else
		''E_NV_Longitud''
	end
end
-- Termina UK

if @pais = 8 begin -- arabia saudita
	select @resultado = case len(@resultado)
	when 7 then @resultado
	when 8 then case substring(@resultado, 1, 1) when @ld then right(@resultado, 7) else ''0'' + @resultado end
	when 9 then case substring(@resultado, 1, 1) when ''5'' then ''0'' + @resultado
				when ''0'' then case substring(@resultado, 2, 1)
						when @ld then right(@resultado, 7) else @resultado end
				else ''E_NV_Longitud''
				end
	when 10 then case substring(@resultado, 2, 1) when ''5'' then @resultado else ''E_NV_Longitud'' end
	when 11 then case substring(@resultado, 2, 1)
					when ''8'' then case substring(@resultado, 3, 3)
									when ''111'' then @resultado else ''E_NV_Longitud'' end
					else case when substring(@resultado, 3, 3) = ''510'' or substring(@resultado, 3, 3) = ''511'' then @resultado else ''E_NV_Longitud'' end
					end
	when 13 then @resultado
	else ''E_NV_Longitud'' end
end -- arabia saudita

if @pais = 9 --Australia
begin
	select @resultado = case len(@resultado)
	when 8 then
		/*case when exists (select AreaCode
						  from SeriesAU
						  where convert(int,LD) = convert(int,@ld)
						  and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then*/
			case substring(@resultado, 1, 4) when ''5550'' then ''E_NV_LD'' else @ld +  @resultado end
		/*else case when exists (select AreaCode
						  from SeriesAU
						  where convert(int,LD) = convert(int,''04'')
						  and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then
		''04'' +  @resultado
		else ''E_NV_Cel'' end end*/
	when 9 then
		case when left(@resultado,1) <> ''0'' then
			case substring(@resultado, 2, 4) when ''5550'' then ''E_NV_LD'' else ''0'' + @resultado end
		else ''E_NV_LD'' end
	when 10 then
		case substring(@resultado, 3, 4) when ''5550'' then ''E_NV_LD'' else @resultado end
	else ''E_NV_Longitud'' end
end


if @pais = 10 --Brasil
begin

	select @resultado = case len(@resultado)
--llamada local fijo o celular
	when 8 then @resultado
	when 9 then @resultado
	when 10 then  -- Numero nacional
		case when left(@resultado, 2) = @ld
			then right(@resultado,8) else @resultado end
	when 11 then	-- Este caso solomente es para numero celular
			case when left(@resultado, 2) = @ld
				 then right(@resultado,9) else @resultado end
	when 12 then	-- llamadas por cobrar local
		case when (left(@resultado,4) = ''9090'') then right(@resultado,8) else ''E_NV_PC'' end
	when 13 then
		case when left(@resultado,4) = ''9090'' then right(@resultado,9) -- llamadas por cobrar local celular
			 when left(@resultado,1) = ''0'' then
			case when substring(@resultado,4,2)=@ld then right(@resultado,8) else right(@resultado,10) end -- llamadas de LDN
		else ''E_NV_Longitud'' end
	when 14 then
			case when left(@resultado,2) = ''90'' then -- llamadas por cobrar larga distancia
					case when substring(@resultado,5,2) = @ld then right(@resultado,8) else right(@resultado,11) end
				 when left(@resultado,1) = ''0''  then --llamada larga distancia a celular
						case when substring(@resultado,4,2)= @ld then right(@resultado,9) else right(@resultado,11) end
			else ''E_NV_Longitud'' end
	when 15 then
		case when left(@resultado,2) = ''90'' then -- Llamadas por cobrar a celular LD
				case when substring(@resultado,5,2)=@ld then right(@resultado,9) else right(@resultado,11) end
			else ''E_NV_Longitud'' end

	else ''E_NV_Longitud'' end

end

if @pais = 11 --Guatemala
begin
	if len(@resultado)=8
		begin
			if charindex(substring(@resultado,1,1),''2,3,4,5,6,7'') <= 0
				select @resultado = ''E_'' + @resultado
		end
	else
		select @resultado = ''E_NV_Longitud''
end

if @pais = 12 --Costa Rica
begin
	if len(@resultado)=8
		begin
			if charindex(substring(@resultado,1,1),''2,3,4,5,6,7,8'') <= 0
				select @resultado = ''E_'' + @resultado
		end
	else if len(@resultado)=10
		begin
			if charindex(substring(@resultado,1,3),''800,900,905'') <= 0
				select @resultado = ''E_'' + @resultado
		end
	else
		begin
			if charindex(substring(@resultado,1,2),''00,08'') <= 0
				select @resultado = ''E_'' + @resultado
		end
end

if @pais = 13 --Salvador
begin
	if len(@resultado)=8
		begin



			if charindex(substring(@resultado,1,1),''2,6,7'') <= 0
				select @resultado = ''E_'' + @resultado
		end
	else
		begin

			if charindex(substring(@resultado,1,2),''00'') <= 0
				select @resultado = ''E_'' + @resultado
		end
end


-- Termina
return @resultado

end'
	EXEC(@sql)

	set @process = 'Alter FUNCTION -- Completa_ListaNegra'
	set @sql='ALTER FUNCTION [dbo].[Completa_ListaNegra] (@Cadena varchar(30))
RETURNS varchar(30) AS
begin
declare @resultado varchar(30), @ld varchar(6), @pais tinyint, @BLActivo tinyint
select @resultado=dbo.Completa(@Cadena)

select @ld=valor from ccSettings where setting_id=17
select @pais = valor from ccsettings where setting_id = 104
select @BLActivo = valor from ccsettings where setting_id = 114

if @BLActivo = 1 begin
	if @pais in (1,4)
	 begin
		if left(@resultado, 1)=''E''
			return @resultado

		select @resultado = case
		 when len(@resultado)in(7,8) then @ld + @resultado
		 when @resultado=''911'' OR len(@resultado)=10 then @resultado
		 when len(@resultado) in (11,12,13) then right(@resultado,10)
		 else ''E_NV_Longitud''
		 end

		 return @resultado
	 end

	if @pais = 2
	 begin
		select @resultado = dbo.fnClearPhoneArg(@cadena)
		return @resultado
	 end

	if @pais = 3 and left(@resultado,1) <> ''E''
	 begin
		select @resultado = case
			when len(@resultado) = 7 then @ld + @resultado
			when len(@resultado) in(8,10) then @resultado
			when len(@resultado) = 11 then right(@resultado,10)
			else ''E_NV_Longitud'' end
		return @resultado
	 end

	if @pais = 5 and left(@resultado,1) <> ''E''
	 begin
		select @resultado = case
			when len(@resultado) in (6,7) then @ld + @resultado
			when len(@resultado) in (8,9) then @resultado
			when len(@resultado) = 10 then right(@resultado,9)
			else ''E_NV_Longitud'' end
		return @resultado
	 end

	if @pais = 6 and left(@resultado,1) <> ''E''
	begin
		select @resultado = case
			when len(@resultado) = 7 then @ld + @resultado
			when len(@resultado) = 10 then @resultado
			when len(@resultado) = 11 then right(@resultado,10)
			else ''E_NV_Longitud'' end
		return @resultado
	end

	if @pais = 7 and left(@resultado,1) <> ''E''
	begin
		select @resultado = right(@resultado,10)
		return @resultado
	end

	if @pais = 8
	begin
		if left(@resultado,1) = ''E''
		begin
			return @resultado
		end
		select @resultado = case
			when len(@resultado) = 7 then ''0'' + @ld + @resultado
			when len(@resultado) = 9 and substring(@resultado,1,1) = ''0'' then @resultado
			when len(@resultado) = 10 and substring(@resultado,2,1) = ''5'' then @resultado
			when len(@resultado) = 11 and substring(@resultado,3,3) in (''111'',''510'',''511'') then @resultado
			else ''E_NV_Longitud'' end
		return @resultado
	end

	if @pais = 9 and left(@resultado,1) <> ''E''
	begin
		return @resultado
	end


	-- Brasil
	if @pais = 10 and left(@resultado,1) <> ''E''
	begin
		return @resultado
	end

	--Guatemala
	if @pais = 11 and left(@resultado,1) <> ''E''
	begin
		return @resultado
	end

	--Costa Rica
	if @pais = 12 and left(@resultado,1) <> ''E''
	begin
		return @resultado
	end

	--Salvador
	if @pais = 13 and left(@resultado,1) <> ''E''
	begin
		return @resultado
	end
end
else begin
 select @resultado = dbo.Limpia(@cadena)
end

return @resultado
end'
	EXEC(@sql)

	set @process = 'Alter function -- Verifica'
	set @sql='ALTER FUNCTION [dbo].[Verifica](@tel varchar(32))
RETURNS varchar(32) AS
 BEGIN
	declare @ld varchar(7)
	declare @lon tinyint
	declare @result tinyint
	declare @mod varchar(10)
	declare @Cadena varchar(32)
	declare @cldLocal varchar(7)
	declare @pais tinyint

	select  @cldLocal = valor from ccsettings where setting_id = 17
	select @tel = dbo.limpia(@tel)

	select @pais = valor from ccSettings where setting_id = 104

	if @pais = 1 begin --Empieza Mexico
		select @lon = len(@tel)
		if @lon between 7 and 8 begin
			set @tel = @cldLocal + @tel
		end
		select @tel = right(@tel, 10)
		select @lon = len(@tel)

		if @lon = 10 begin
			select @ld = case when left(@tel, 2) in (''55'', ''33'', ''81'') then left(@tel, 2) else left(@tel, 3) end

			select @mod = modalidad from series where cld = @ld and serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

			select @tel = case
				when @mod in (''FIJO'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''01'' + @tel end
				when @mod = ''CPP'' then case when @ld = @cldLocal then ''044'' + @tel else ''045'' + @tel end
				else ''E_'' + @tel
			end
		end else begin
			if @lon > 0 begin
				select @tel = ''E_'' + @tel
			end
		end
		return @tel
	end --Termina Mexico

	-- Empieza Argentina
	if @pais = 2 begin
		select @tel = dbo.completa(@tel)
		if left(@tel,1) = ''E'' begin return @tel end
		select @lon = len(@tel)
		if @lon in(6,7,8) and left(@tel,2) <> ''15'' begin
			set @tel = @cldLocal + @tel
		end

		if @lon in (8,9,10) and left(@tel,2) = ''15'' begin
			set @tel = @cldLocal + substring(@tel,3,@lon - 2)
		end

		--Buscamos el 15
		if @lon = 13 begin
			declare @index as int
			select @index = charindex(''15'',@tel)
			--El unico caso en el que la lada tiene un 15 es con lada 3715
			if @index < 2 begin
				select @tel = ''E_'' + @tel
				return @tel
			end
			else begin
				if substring(@tel,@index-2,4) = ''3715''
					begin
						select @ld = ''3715''
						set @tel = @ld + right(@tel,6)
					end
				else
					begin
						select @ld = substring(@tel,2,@index-2)
						set @tel = @ld + right(@tel,13 - (@index + 1))
					end
			end
		end

		select @tel = right(@tel, 10)

		if len(@tel) = 10 begin
			declare @serie as varchar(5)
			begin
				-- Buscamos la lada, empezando por 4 digitos hasta 2, si la lada no existe se regresa error
				declare @contLD as int
				declare @cont as int
				set @contLD=4
					BuscaLada:
					if isnull(@ld,'''') = '''' and @contLD >= 2
						begin
							select @ld = cld from seriesArg where cld=left(@tel,@contLD)
							if isnull(@ld,'''') = '''' begin
								set @contLD = @contLD - 1
								goto BuscaLada
							end
						end
					else begin
							if isnull(@ld,'''') = '''' begin
								select @tel = ''E_'' + @tel
							end
					end
			end

			-- Buscamos la serie, dependiendo de la longitud de la lada, se busca la serie hasta que encuentra una que existe
			begin
			if len(@ld) = 2 begin
					set @cont = 5
					buscaSerie2:
					if isnull(@serie,'''') = '''' and @cont >= 4 begin
						select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,3,@cont)
						if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie2 end
					end
			end
			else begin
				if len(@ld) = 3 begin
					set @cont = 4
					buscaSerie3:
					if isnull(@serie,'''') = '''' and @cont >= 3 begin
						select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,4,@cont)
						if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie3 end
					end
				end
				else begin
					if len(@ld) = 4 begin
						set @cont = 3
						buscaSerie4:
						if isnull(@serie,'''') = '''' and @cont >= 2 begin
							select @serie = serie from seriesArg where cld = @ld and serie = substring(@tel,5,@cont)
							if isnull(@serie,'''') = '''' begin set @cont = @cont - 1 goto buscaSerie4 end
						end
					end
				end
			end

			end

			select @mod = modalidad from seriesArg where cld = @ld and serie = @serie and right(@tel, 10 - len(@ld) - len(@serie)) between [NUMERACION INICIAL] and [NUMERACION FINAL]

			-- Si la serie es nula, existe una posibilidad de que la lada este mal, asi que se quita un numero de la lada y se vuelve a buscar la serie
			--select @ld,@serie,@mod,@contLD
			if isNull(@serie,'''') = '''' and @contLD>1 begin
			set @contLD = len(@ld) - 1
			set @ld = null
			goto BuscaLada
			end

			select @tel = case
				when @mod in (''BASICA'', ''MPP'') then case when @ld = @cldLocal then right(@tel, 10 - len(@ld)) else ''0'' + @tel end
				when @mod = ''CPP'' then case when @ld = @cldLocal then ''15'' + right(@tel,10-len(@ld)) else ''0'' + @ld + ''15'' + right(@tel,10-len(@ld)) end
				else ''E_'' + @tel
			end
		end else begin
			if len(@tel) > 0 begin
				select @tel = ''E_'' + @tel
			end
		end
		return @tel
	end  --Termina Argentina

	if @pais = 3 begin  --Empieza Colombia
		select @tel = dbo.completa(@tel)
		if left(@tel,1) = ''E'' begin
			return @tel
		end

		if len(@tel) not in (7,8,10,11) begin
			return ''E_'' + @tel
		end

		if len(@tel) = 7 begin
			if exists(select serie from seriesCol where serie = left(@tel,4) and @cldLocal = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				return @tel
			end
			else begin
				return ''E_'' + @tel
			end
		end

		if len(@tel) = 8 begin
			if exists(select serie from seriesCol where serie = substring(@tel,2,4) and left(@tel,1) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				return @tel
			end
			else begin
				return ''E_'' + @tel
			end
		end

		if len(@tel) = 10 begin
			if exists(select serie from seriesCol where serie = substring(@tel,5,3) and (left(@tel,3) + ''-'' + substring(@tel,4,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				return @tel
			end
			else begin
				return ''E_'' + @tel
			end
		end

		if len(@tel) = 11 begin
			if exists(select serie from seriesCol where serie = substring(@tel,6,3) and (substring(@tel,2,3) + ''-'' + substring(@tel,5,1)) = region and (right(@tel,3) between numeracionInicial and numeracionFinal)) begin
				return @tel
			end
			else begin
				return ''E_'' + @tel
			end
		end
	end  --Termina Colombia

	-- Empieza Chile
	if @pais = 5 begin
		select @tel = dbo.completa(@tel)
		if left(@tel,1) = ''E'' begin
			return @tel
		end

		if len(@tel) = 6 and len(@cldLocal) = 2 begin
			if exists(select serie from seriesChi where cld = @cldLocal and left(@tel,3) = serie and right(@tel,3) between numeracioninicial and numeracionFinal) begin
				return @tel
			end
			else begin return ''E_'' + @tel end
		end

		if len(@tel) = 7 begin
			if @cldLocal in (2,41,44,32) begin
				if exists(select serie from serieschi where serie = left(@tel,4)) begin return @tel end
				else begin
					if left(@tel,3) = ''200'' and exists(select serie from serieschi where serie = left(@tel,3) ) begin return @tel end
				end
			end
		end

		if len(@tel) = 8 begin
			if left(@tel,1) = ''2'' begin
					if exists(select serie from serieschi where serie = substring(@tel,2,4)) begin return @tel end
					else begin
						if exists(select serie from serieschi where serie = substring(@tel,2,5)) begin return @tel end
						else begin return ''E_'' + @tel end
					end
			end
			else begin
				return @tel
			end
		end

		if len(@tel) = 10 begin
			if left(@tel,2) = ''09'' begin
				if exists(select serie from serieschi where cld=substring(@tel,3,1) and serie = substring(@tel,5,3)) begin
					return @tel
				end
				else begin
					return ''E_'' + @tel
				end
			end

		end
	end
	--Termina Chile

	if @pais = 6 begin --Empieza Venezuela
		select @lon = len(@tel)
		if @lon = 7  begin
			set @tel = @cldLocal + @tel
		end

		select @tel = right(@tel, 10)

		if len(@tel) = 10 begin
			select @ld = left(@tel,3)
			select @mod = tipo from seriesVen where left(@tel,3) = LD

			if @mod = ''CPP'' begin
				if exists( select * from seriesVen where LD = @ld ) begin
					if @ld = @cldLocal begin
						select @tel = right(@tel,7)
					end
					else begin
						select @tel = ''0'' + @tel
					end
				end
				else begin
					select @tel = ''E_'' + @tel
				end
			end
			else begin
				if @mod = ''FIJO'' begin
					if exists( select serie from seriesVen where serie = substring(@tel, len(@ld) + 1, 6 - len(@ld)) and right(@tel, 4) between [Inicio] and [Fin]) begin
						if @ld = @cldLocal begin
							select @tel = right(@tel,7)
						end
						else begin
							select @tel = ''0'' + @tel
						end
					end
					else begin
						select @tel = ''E_'' + @tel
					end
				end
				else begin
					select @tel = ''E_'' + @tel
				end
			end
		end
		else begin
			if len(@tel) > 0 begin
				select @tel = ''E_'' + @tel
			end
		end
		return @tel
	end --Termina Venezuela

	if @pais = 7 begin -- Empieza UK
		select @tel = dbo.completa(@tel)
		if left(@tel, 1) = ''E'' begin -- regresa error por longitud
			return @tel
		end
		select @lon = len(@tel)

		--numeros no geograficos
		if (left(@tel, 2) in(''03'', ''07'', ''09'') and @lon <> 11) or (left(@tel, 3) in(''055'', ''056'', ''070'') and @lon <> 11) begin
			return ''E_'' + @tel --error por longitud con lada correcta
		end
		else begin
			if left(@tel, 7) in(''0845464'') or left(@tel, 5) = ''07624'' or left(@tel, 4) in(''0500'', ''0800'') or left(@tel, 3) in(''055'', ''056'', ''070'', ''76'') or left(@tel, 2) in(''03'', ''07'', ''08'', ''09'') begin
				return @tel; --longitud correcta y numero no geografico
			end
		end

		--numeros geograficos (revisar a mano porque son pocas claves LD). *El cero no es parte de la clave LD
		if (left(@tel, 7) in(''0159575'', ''0159576'')) or
			(left(@tel, 5) in(''02820'',''02821'',''02825'',''02827'',''02828'',''02829'',''02830'',''02837'',''02838'',''02840'',''02841'',''02842'',''02843'',''02844'',''02866'',''02867'',''02868'',''02870'',''02871'',''02877'',''02879'',''02880'',''02881'',''02882'',''02885'',''02886'',''02887'',''02889'',''02890'',''02891'',''02892'',''02893'',''02894'',''02895'',''02897'') and @lon = 11) or --claves 2xxx tienen formato 4-6
			(left(@tel, 4) in(''0113'', ''0114'',''0115'',''0116'',''0117'',''0118'',''0121'',''0131'',''0141'',''0151'',''0161'',''0238'',''0239'') and @lon = 11) or --3-digit area codes have 7-digit subscribers.
			(left(@tel, 3) in(''020'',''024'',''029'') and @lon = 11) begin --2-digit area codes have 8-digit subscribers.
			return @tel;
		end

		--numeros geograficos con 01 (los que faltan por verificar tienen longitud variable)
		if left(@tel, 2) = ''01'' begin
			select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,4) --mayor numero de ladas (va primero por ser mas probable)
			if @ld > 0 begin
				return @tel;
			end
			else begin
				select @ld = count(cld) from seriesuk where cld = substring(@tel, 2,5) --ladas restantes
				if @ld > 0 begin
					return @tel;
				end
			end
		end --si no encontro ni error ni coincidencia entonces esta mal
		return ''E_'' + @tel
	end --Termina UK

	if @pais = 8 begin --Empieza Arabia Saudita
		select @tel = dbo.completa(@tel)
		select @lon = len(@tel)
		if @lon = 7 begin
			set @tel = ''0'' + @cldLocal + @tel
		end
		select @lon = len(@tel)

		if @lon = 9 begin
			if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,2) = cld) begin
				if (substring(@tel,2,1) = @cldLocal)
				begin
					return right(@tel,7)
				end else begin
					return @tel
				end
			end
			else begin
				return ''E_'' + @tel
			end
		end
		if @lon = 10 begin
			if exists(select regiones from seriesSA where right(@tel,4) between [numeracion inicial] and [numeracion final] and substring(@tel,4,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 4 and left(@tel,3) = cld) begin
				return @tel
			end
			else begin
				return ''E_'' + @tel
			end
		end
		if @lon = 11 begin
			if exists(select regiones,* from seriesSA where right(@tel,6) between [numeracion inicial] and [numeracion final] and substring(@tel,3,3) between [serie inicio] and [serie fin] and len([numeracion inicial]) = 6 and left(@tel,2) = cld) begin
				return @tel
			end
			else begin
				return ''E_'' + @tel
			end
		end
	end --Termina Arabia Saudita

	if @pais = 9
		begin --Empieza Australia
			select @tel = dbo.completa(@tel)
			select @lon = len(@tel)

			if left(@tel,1) <> ''E''
				begin
					if exists(select Regiones
							  from SeriesAU
							  where convert(int,LD) = convert(int,substring(@tel, 1, 2))
							  and convert(int,AreaCode) = convert(int,substring(@tel, 3, 2))
							  and convert(int,substring(@tel, 5, 6)) between convert(int,SerieInicio) and convert(int,SerieFin))
						begin
							return @tel
						end
					else
						begin
							return ''E_'' + @tel
						end
				end
			else
				begin
					return @tel
				end
		end --Termina Australia

	if @pais= 10
		begin -- Inicia Brasil
			select @tel = dbo.completa(@tel)
			select @lon = len(@tel)
			if left(@tel,1) <> ''E''
				begin
					if @lon in (8,9) begin --numero local
						if exists(
						select Regiones
							from seriesBR where
								convert(int,AreaCode) = convert(int,@cldLocal) and
								convert(int,@tel) between convert(int,SerieInicio) and convert(int,SerieFin)
						)
						begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end
					if @lon in (10,11) begin --numero nacional
						if exists(
						select Regiones
							from seriesBR where
								convert(int,AreaCode) = convert(int,left(@tel,2)) and
								convert(int,right(@tel, @lon-2)) between convert(int,SerieInicio) and convert(int,SerieFin)
						)
						begin
							return @tel
						end
						else begin
							return ''E_'' + @tel
						end
					end
				end

			else begin
				return @tel
			end
		end -- Termina Brasil

	if @pais= 11
		begin -- Inicia Guatemala
			select @tel = dbo.completa(@tel)
			if left(@tel,1) <> ''E''
				begin
					if exists(select zonaGeografica from seriesGT (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
						return @tel
					else
						return ''E_'' + @tel
				end
			else
				return @tel
		end -- Termina Guatemala

		if @pais= 12
		begin -- Inicia Costa Rica
			select @tel = dbo.completa(@tel)
			if left(@tel,1) <> ''E''
				begin
					if len(@tel)=8
						if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
							return @tel
						else
							return ''E_'' + @tel
				end
			else if len(@tel)=10
				begin
					if exists(select zonaGeografica from seriesCR (nolock) where indicativoDestino = substring(@tel,1,3) and right(@tel, 7) between rangoInicio and rangoFinal)
							return @tel
						else
							return ''E_'' + @tel
				end
			else
				if charindex(substring(@tel,1,2),''00,08'') <= 0
					return ''E_'' + @tel
				else
					return @tel
		end -- Termina Costa Rica

	if @pais= 13
		begin -- Inicia Salvador
			select @tel = dbo.completa(@tel)
			if left(@tel,1) <> ''E''
				begin
					if len(@tel)=8
						if exists(select zonaGeografica from seriesSV (nolock) where indicativoDestino = substring(@tel,1,1) and right(@tel, 7) between rangoInicio and rangoFinal)
							return @tel
						else
							return ''E_'' + @tel
				end
			else
				if charindex(substring(@tel,1,2),''00'') <= 0
					return ''E_'' + @tel
				else
					return @tel
		end -- Termina Salvador

	return @tel
 end'
	EXEC(@sql)

	set @process = 'Alter function -- TelAni'
	set @sql='ALTER function [dbo].[TelAni](@tel varchar(32), @lista smallint)
RETURNS varchar(32)
AS
BEGIN
--declare @edo varchar(250)
declare @cldLocal varchar(10), @pais tinyint, @lon tinyint, @ret as varchar(10)

select  @cldLocal = valor from ccsettings where setting_id = 17
select @pais = valor, @ret = '''' from ccSettings where setting_id = 104

	if @lista = 0 begin
		select @tel = ''''
	end

	if @pais = 1 begin --Empieza Mexico
		select @lon = len(@tel)
		if @lon >= 7 and @lon <=13 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
			(( len(@tel) = 8 and @cldlocal = area and len(area) = 2 )
				or
				( len(@tel) = 7 and @cldlocal = area and len(area) = 3 )
				or
				( len(@tel) >= 10 and left(right(@tel, 10), 3) = area and len(area) = 3 )
				or
				( len(@tel) >= 10 and left(right(@tel, 10), 2) = area and len(area) = 2 ))
		end
		else begin
			select @tel = ''''
		end

		return @tel
	end --Termina Mexico

	if @pais = 2 begin  -- Empieza Argentina
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=13 begin
			select @tel = telAni from ccEstadosAni where id_anilist = @lista and
							(( @lon = 6 and left(@tel,4) = area and len(area) = 4 )
							or
							( @lon = 7 and left(@tel,3) = area and len(area) = 3 )
							or
							( @lon = 8 and left(@tel,2) = area and len(area) = 2 )
							or
							( @lon = 11 and substring(@tel, 2, 2) = area and len(area) = 2 )
							or
							( @lon = 11 and substring(@tel, 2, 3) = area and len(area) = 3 )
							or
							( @lon = 11 and substring(@tel, 2, 4) = area and len(area) = 4 )
							or
							( @lon = 13 and substring(@tel, 2, 2) = area and len(area) = 2 )
							or
							( @lon = 13 and substring(@tel, 2, 3) = area and len(area) = 3 )
							or
							( @lon = 13 and substring(@tel, 2, 4) = area and len(area) = 4 ))
		end
		else begin
			select @tel = ''''
		end
			return @tel
	end  --Termina Argentina

	if @pais = 3 begin  --Empieza Colombia
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=13 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
				(( len(@tel) = 7 and @cldlocal = area )
				or
				( len(@tel) = 8 and left(@tel,5) = area )
				or
				( len(@tel) in(10,11) and (left(@tel,1) = ''3'' or substring(@tel,2,1) = ''3'')))
		end
		else begin
			select @tel = ''''
		end
		return @tel
	end  --Termina Colombia

	if @pais = 4 begin --Empieza USA
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=15 begin
			if @lon = 7 begin
				set @tel = @cldLocal + @tel
			end
			set @tel = right(@tel, 10)
			--select @edo = location from ccTimeZoneAreaUsa where area = left(@tel,3)
			select @tel = telani from ccEstadosAni where area = left(@tel,3) and id_anilist = @lista
		end
		else begin
			select @tel = ''''
		end
		return @tel
	end --Termina USA

	if @pais = 5 begin -- Empieza Chile
		select @lon = len(@tel)
		if @lon >= 6 and @lon <=15 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
			(( len(@tel) = 6 and @cldlocal = area )
			or
			( len(@tel) = 7 and @cldlocal = area )
			or
			( len(@tel) = 8 and left(@tel,1) = area )
			or
			( len(@tel) = 8 and left(@tel,2) = area )
			or
			( len(@tel) = 9 and left(@tel,2) = area )
			or
			( len(@tel) = 10 and substring(@tel,3,1) = area and left(@tel,2) = ''09'' ))
		end
		else begin
			select @tel = ''''
		end
		return @tel
	end --Termina Chile

	if @pais = 6 begin -- Venezuela
		select @lon = len(@tel)
		if @lon >= 7 and @lon <=11 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
				(len(@tel) = 7 and left(@tel,3) = area or
				len(@tel) = 11 and substring(@tel,2,3) = area)
		end
		else begin
			select @tel = ''''
		end

		return @tel
	end --Termina Venezuela

	if @pais = 7 begin -- Empieza UK
		select @lon = len(@tel)
		if left(@tel,1) = ''0'' begin
			set  @tel = substring(@tel,2,(len(@tel)-1))
		end

		if @lon >= 9 and @lon <=11 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
			(( len(@tel) = 10 and substring(@tel,1,5) = area )
			or
			( len(@tel) = 10 and substring(@tel,1,4) = area )
			or
			( len(@tel) = 10 and substring(@tel,1,3) = area )
			or
			( len(@tel) = 10 and substring(@tel,1,2) = area )
			or
			( len(@tel) = 9 and substring(@tel,1,5) = area )
			or
			( len(@tel) = 9 and substring(@tel,1,4) = area ) )
		end
		else begin
			select @tel = ''''
		end
		return @tel
	end --Termina UK

	if @pais = 8 begin --Empieza Arabia Saudita
		select @lon = len(@tel)
		if @lon >= 7 and @lon <=13 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and
				(len(@tel) = 7 and ''0''+@cldlocal + ''-''+ substring(@tel,1,1) + ''00'' = area or
				len(@tel) = 9 and substring(@tel,1,3) + ''00'' = replace(area,''-'','''') or
				len(@tel) = 10 and substring(@tel,1,4) + ''00'' = replace(area,''-'','''') or
				len(@tel) = 11 and substring(@tel,1,4)+ ''0'' = replace(area,''-'','''') or
				len(@tel) = 11 and substring(@tel,1,5) = replace(area,''-'',''''))
		end
		else begin
			select @tel = ''''
		end

		return @tel
	end --Termina Arabia Saudita

	if @pais = 9 --Empieza Australia
		begin
			select @lon = len(@tel)
			if @lon >= 8 and @lon <=10
				begin
					select @tel = telani from ccEstadosAni where id_anilist = @lista
					and (len(@tel) = 8 and @cldLocal + substring(@tel,1,2) = area or
						 len(@tel) = 9 and ''0'' + substring(@tel,1,3) = area or
						 len(@tel) = 10 and substring(@tel,1,4) = area)
				end
			else
				begin
					select @tel = ''''
				end

			return @tel
		end --Termina Australia

	if @pais = 10 begin -- Empieza Brasil
		select @lon = len(@tel)
		if @lon >= 8 and @lon <=15 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and (
				((@lon       = 8        )                                    and             @cldlocal = area) or
				((@lon       = 9        ) and substring(@tel, 1, 1) = ''9''    and             @cldlocal = area) or
				((@lon between 10 and 11)                                    and substring(@tel, 1, 2) = area) or
				((@lon between 12 and 13) and substring(@tel, 1, 4) = ''9090'' and             @cldlocal = area) or
				((@lon       = 13       )                                    and substring(@tel, 4, 2) = area) or
				((@lon between 14 and 15) and substring(@tel, 1, 2) = ''90''   and substring(@tel, 5, 2) = area) or
				((@lon       = 14       ) and substring(@tel, 1, 1) = ''0''    and substring(@tel, 4, 2) = area))
		end
		else begin
			select @tel = ''''
		end

		return @tel
	end -- Termina Brasil

	if @pais = 11 begin --Empieza Guatemala
		if len(@tel) = 8  begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
		end
		else begin
			select @tel = ''''
		end

		return @tel
	end --Termina Guatemala

	if @pais = 12 begin --Empieza Costa Rica
		if len(@tel) = 8  begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
		end
		else if len(@tel) = 10 begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 3) = area
		end
		else begin
			if charindex(substring(@tel,1,2),''00,08'') <= 0
				select @tel = ''''
			else
				select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
		end

		return @tel
	end --Termina Costa Rica

	if @pais = 13 begin --Empieza Salvador
		if len(@tel) = 8  begin
			select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 1) = area
		end
		else begin
			if charindex(substring(@tel,1,2),''00'') <= 0
				select @tel = ''''
			else
				select @tel = telani from ccEstadosAni where id_anilist = @lista and substring(@tel, 1, 2) = area
		end

		return @tel
	end --Termina Salvador

	return @ret
END'
	EXEC(@sql)

	set @process = 'DROP STOREPROCEDURE -- ccsp_RIAImageHandler'
	set @sql='IF EXISTS (SELECT * FROM sysobjects WHERE name=''ccsp_RIAImageHandler'')  DROP PROCEDURE dbo.ccsp_RIAImageHandler'
	EXEC(@sql)


	set @process = 'Alter SP -- ccsp_RIAccSettingsConfig'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
@command tinyint,
@setting_id smallint = null,
@value varchar(200) = null
AS
set nocount on

declare @idioma tinyint
declare @activeChat tinyint

select @idioma=valor from ccSettings where setting_id=27
Select @activeChat=valor from ccSettings where setting_id=145

if @command=0
 begin
	SELECT case @idioma when 0 then descripcion else [description] end descripcion
	FROM ccSettings WITH(NOLOCK, index(PK_ccSettings)) WHERE setting_id=@setting_id
	order by descripcion
	return(0)
 end

if @command=1
 begin
	Select setting_id, case @idioma when 0 then descripcion else [description] end descripcion, valor, tipo
	from ccSettings WITH(NOLOCK, index(PK_ccSettings)) where tipo in (''AGT'',''ADM'',''GRL'',''REP'',''SV'')
	and (setting_id not in (139,140,141)
	or   setting_id     in (139,140,141) and @activeChat > 0)
	order by tipo, descripcion
	return(0)
 end

if @command=2
 begin
	if @setting_id = 27 and @value not in(''0'',''1'') begin
		set @value = 0
	end
	else if @setting_id = 104 and @value not in(''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'',''10'',''11'',''12'',''13'') begin
		set @value = 1
	end
	update ccSettings set valor=@value where setting_id = @setting_id
	return(0)
 end

set nocount off'
	EXEC(@sql)

	set @process = 'Alter SP -- ccspADM_AniListLD'
	set @sql='
ALTER PROCEDURE [dbo].[ccspADM_AniListLD]
@type as tinyint,
@idArea as smallint,
@descriptionList as varchar(40) = NULL,
@IdAniLista as smallint = NULL,
@cld as varchar(40)= NULL,
@AniTel as varchar(40)= NULL,
@edo as varchar(40) = NULL
AS
set nocount on
declare @pais tinyint, @listEdos varchar(4000), @idLista as integer, @sql as varchar(500)
select @pais = valor from ccsettings where setting_id = 104

select @listEdos = ''select distinct '' + case @type when 1 then
case @pais	when 1  then ''estado, cld as area ''
			when 2  then ''estado, cld as area ''
			when 3  then ''municipio as estado, region +''''+ serie as area ''
			when 4  then ''location as estado, area ''
			when 5  then ''cld as estado, cld as area ''
			when 6  then ''region as estado, LD as area ''
			when 7  then ''region as estado, CLD as area ''
			when 8  then ''Regiones as estado, cld +''''-''''+ [serie inicio] as area ''
			when 9  then ''Regiones as estado, LD + AreaCode as area ''
			when 10 then ''Regiones as estado, AreaCode as area ''
			when 11 then ''zonaGeografica as estado, indicativoDestino as area ''
			when 12 then ''zonaGeografica as estado, indicativoDestino as area ''
			when 13 then ''zonaGeografica as estado, indicativoDestino as area ''
			else '''' end
when 4 then
case @pais	when 1  then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 2  then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 3  then ''municipio as estado, region +''''+ serie as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 4  then ''location as estado, area, @id_anilist as id_anilist, '''''''' as telani ''
			when 5  then ''cld as estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 6  then ''region as estado, LD as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 7  then ''region as estado, CLD as area, @id_anilist as id_anilist, '''''''' as telani''
			when 8  then ''Regiones as estado, cld +''''-''''+ [serie inicio] as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 9  then ''Regiones as estado, LD + AreaCode as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 10 then ''Regiones as estado, AreaCode as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 11 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 12 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 13 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
			else '''' end end + ''from '' +
case @pais	when 1  then ''series''
			when 2  then ''seriesarg where estado <> '''' order by 1''
			when 3  then ''seriescol''
			when 4  then ''ccTimeZoneArea where id_country = '' + convert(varchar(5),@pais) + ''''
			when 5  then ''serieschi''
			when 6  then ''SeriesVen''
			when 7  then ''SeriesUK''
			when 8  then ''SeriesSA''
			when 9  then ''SeriesAU''
			when 10 then ''SeriesBR''
			when 11 then ''SeriesGT''
			when 12 then ''SeriesCR''
			when 13 then ''SeriesSV''
			else '''' end + ''''

if @type = 1

begin
	exec(@listEdos + '' order by estado'')
	--print(@listEdos + '' order by estado'')
	return(0)
end

if @type = 2
begin
	select @sql = ''select id_AniList, description from ccEdoAniList where idArea = '' + convert(varchar(5),@idArea) +  case when isnull(@IdAniLista,'''') <> '''' then '' and id_AniList = '' + convert(varchar(5),@IdAniLista) else '''' end
	exec(@sql)
	return(0)
end

if @type = 3
begin
	select @sql = ''select id_AniList, Estado, telAni, area from ccEstadosAni where id_AniList = '' + convert(varchar(5),@IdAniLista) + '' and estado like ''''%'' + @edo + ''%'''' and telani <> '''''''' and id_AniList in (select id_AniList from ccEdoAniList where idArea
= '' +
	 convert(varchar(5),@idArea) + '') order by estado''
	exec(@sql)
	--print(@sql)
	return(0)
end

if @type = 4
begin  --insert new aniList
	if @descriptionList <> '''' begin
		if exists(select * from dbo.ccEdoAniList where [description] = @descriptionList )
		 begin
			--raiserror(''ERROR. invalid ID'', 18, 1)
			select 1
			return(0)
		 end
		insert into ccEdoAniList values(@descriptionList, @idArea)
		select @idLista = id_anilist from ccEdoAniList where [description] = @descriptionList
		set @listEdos = ''insert into ccEstadosAni (estado, area, id_anilist, telani) '' + @listEdos
		set @listEdos = replace(@listEdos, ''@id_anilist'', convert(varchar(6),@idLista))
		exec(@listEdos)
		--print(@listEdos)
	end
	return(0)
end

if @type = 5
begin --update ccEstadosAni
	if not exists(select * from dbo.ccEstadosAni WHERE id_anilist = @IdAniLista and area = @cld )
	 begin
		--raiserror(''ERROR. invalid ID'', 18, 1)
		select 1
		return(0)
	 end

	update ccEstadosAni set telani= ISNULL(@AniTel, TELANI) WHERE id_anilist = @IdAniLista and area = @cld
	if @@rowcount>0
		select 0 id, [description]+''(Ld:''+cast(@cld as varchar(10))+'')'' [description] from ccEdoAniList WHERE id_anilist = @IdAniLista
	return(0)
end

if @type = 6
begin --borra listas
	if not exists(select id_anilist from ccEdoAniList WHERE id_anilist = @IdAniLista and idarea = @idArea )
	 begin
		select 1
		return(0)
	 end

	select @descriptionList=[description] from ccEdoAniList WHERE id_anilist = @IdAniLista and idarea = @idArea
	delete from ccEstadosAni where id_anilist = @IdAniLista
	delete from ccEdoAniList WHERE id_anilist = @IdAniLista

	if @@rowcount>0
		select 0 id, @descriptionList descriptionList
	return(0)
end'
	EXEC(@sql)

	set @process = 'Alter -- ccsp_RIAAgentGetDialMask'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
@user_id integer,
@tel varchar(15)
AS
declare @mask integer, @idioma integer, @value integer, @lada integer
declare @country as tinyint

set @value = 0
select @mask = isnull(dialmask,7) from ccusers where user_id=@user_id
select @country = valor from ccsettings where setting_id = 104

-- Restricciones por pais 1:Mexico 2:Argentina 3:Colombia 4:USA 5:Chile 6:Venezuela 7:uk 8:Arabia Saudita, 9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador
if @country = 1
 begin
	--Restringe celulares
	if (@mask & 1)>0
	 begin
		if ((left(ltrim(rtrim(@tel)),3) = ''044'' Or left(ltrim(rtrim(@tel)),3) = ''045''))
		 begin
			set @value = 4
		 end
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if ((left(ltrim(rtrim(@tel)),2) = ''01'') and len(ltrim(rtrim(@tel))) = 12)
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
			 begin
				set @value = 6
			 end
		 end
	 end
 end

-- Argentina
if @country = 2
 begin
	--Restringe celulares
	if ((@mask & 1) > 0)
	 begin
		if (left(@tel,2)=''15'') or (len(@tel)>=13 and substring(@tel,1,1)=''0'' and
			(substring(@tel,4,2)=''15'' or substring(@tel,5,2)=''15'' or substring(@tel,3,2)=''15''))
		 begin
			set @value = 4
		 end
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if ((left(ltrim(rtrim(@tel)),2) = ''0'') and len(ltrim(rtrim(@tel))) = 11)
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask&4)>0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
			 begin
				set @value=6
			 end
		 end
	 end
 end

if @country = 3 --Colombia
 begin
	--Restringe Celulares
	if ((@mask & 1) > 0)
	 begin
		if len(@tel) > 8
		 begin
			set @value = 4
		 end
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if len(@tel) = 8 or left(@tel,1) = ''0''
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
			 begin
				set @value = 6
			 end
		 end
	 end
 end

if @country = 4 --USA
 begin
	--Restringe larga distancia usa
	if ((@mask & 2) > 0)
	 begin
		if len(ltrim(rtrim(@tel))) >= 11  and (left(ltrim(rtrim(@tel)),1) = ''1'')
		 begin
			set @value = 5
		 end
	 end

	--Restringe locales usa
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			--if Len(ltrim(rtrim(@tel))) = 7
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
			 begin
				set @value = 6
			end
		 end
	 end
 end

--Chile
if @country = 5
 begin

		--Restringe Celulares
	if ((@mask & 1) > 0)
	 begin
		if len(@tel) >= 10 and left(@tel,2) = ''09''
		 begin
			set @value = 4
		 end
	 end

		--Restringe Locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			if Len(@tel) in (6,7)
			 begin
				set @value = 6
			 end
		 end
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if len(@tel) >= 8 and len(@tel) < 10
			 begin
				set @value = 5
			 end
		 end
	 end
 end

--Venezuela
if @country = 6
begin
		--Restringe Celulares
	if ((@mask & 1) > 0)
	 begin
		if len(@tel) >= 10 and left(@tel,2) = ''04''
		 begin
			set @value = 4
		 end
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if len(@tel) >= 10 and left(@tel,1) = ''0''
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
			 begin
				set @value = 6
			 end
		 end
	 end

end

--United Kingdom
if @country = 7
begin
		--Restringe Celulares
	if ((@mask & 1) > 0)
	 begin
		if (len(@tel) >= 9) and left(@tel,2) = ''07''
		 begin
			set @value = 4
		 end
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if len(@tel) >= 9 and left(@tel,1) = ''0''
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			if len(@tel) >= 9 and left(@tel,1) <> ''0''
			 begin
				set @value = 6
			 end
		 end
	 end

end

--arabia saudita
if @country = 8
begin

	--Restringe celulares
	if (@mask & 1)>0
	 begin
		if (left(ltrim(rtrim(@tel)),2) = ''05'' and len(ltrim(rtrim(@tel))) = 10 )
		 begin
			set @value = 4
		 end
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if ( left(ltrim(rtrim(@tel)),2) <> ''05'' and len(ltrim(rtrim(@tel))) in (11, 9))
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
			 begin
				set @value = 6
			 end
		 end
	 end
end

--Australia
if @country = 9
begin

	--Restringe celulares
	if (@mask & 1)>0
	 begin
		if (left(ltrim(rtrim(@tel)),2) = ''04'' and len(ltrim(rtrim(@tel))) = 10)
		 begin
			set @value = 4
		 end
	 end

	--Restringe larga distancia
	if(@value=0)
	 begin
		if ((@mask & 2) > 0)
		 begin
			if ( left(ltrim(rtrim(@tel)),2) <> ''04'' and len(ltrim(rtrim(@tel))) = 10)
			 begin
				set @value = 5
			 end
		 end
	 end

	--Restringe locales
	if(@value=0)
	 begin
		if ((@mask & 4) > 0)
		 begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if ((Len(ltrim(rtrim(@tel))) = 8) or
				(''0'' + left(ltrim(rtrim(@tel)),1) = @lada and Len(ltrim(rtrim(@tel))) = 9) or
				(left(ltrim(rtrim(@tel)),2) = @lada and Len(ltrim(rtrim(@tel))) = 10))
			 begin
				set @value = 6
			 end
		 end
	 end
end

--Brasil
if @country = 10
	begin
		declare @lon int
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			set @lon=len(@tel)
			if
				(@lon in(7,8) and left(@tel,1) in (''6'',''7'',''8'',''9'') )
				or (@lon=9 and left(@tel,1) = ''9'' )
				or (@lon=10 and substring(@tel,3,1) in (''6'',''7'',''8'',''9'') )
				or (@lon=11 and substring(@tel,3,1) = ''9'')
				--or (@lon=12 and substring(@tel,5,1) in (''6'',''7'',''8'',''9'') )
				--or (@lon=13 and substring(@tel,5,1) = ''9'' )
				--or (@lon=13 and substring(@tel,5,1) = ''9'' )
				begin
					set @value = 4
				end
		end

		--Restringe larga distancia
		if(@value=0)
		begin
			if ((@mask & 2) > 0)
			begin
				select @lada=valor from ccSettings WHERE setting_id=17
				set @tel=ltrim(rtrim(@tel))
				set @lon=len(@tel)
				if  @lon>=10 and left(@tel,2) <> @lada
				begin
					set @value = 5
				end
			end
		end
		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				select @lada=valor from ccSettings WHERE setting_id=17
				set @tel=ltrim(rtrim(@tel))
				set @lon=len(@tel)
				if @lon in (7,8,9) or (@lon in (10,11) and left(@tel,2)= @lada)
				begin
					set @value = 6
				end
			end
		end

		--Restringe por cobrar
		if(@value=0)
		begin
			declare @llamadasPorCobrar varchar(4);
			select @llamadasPorCobrar= valor from ccSettings where setting_id=126
			set @tel=ltrim(rtrim(@tel))
			set @lon=len(@tel)
			if @lon >= 12 and  left(@tel,2) = ''90'' and @llamadasPorCobrar=''0''
			begin
				set @value = 10 -- pone para llamadas por cobrar
			end
		end

	end -- Termina Brasil


--Guatemala
if @country = 11
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''3,4,5'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''2,6,7'') > 0
					set @value = 6
			end
		end

	end -- Termina Guatemala

--Costa Rica
if @country = 12
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''5,6,7,8'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''2,3,4'') > 0
					set @value = 6
			end
		end

	end -- Termina Costa Rica

--Salvador
if @country = 13
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''6,7'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''2'') > 0
					set @value = 6
			end
		end

	end -- Termina Salvador

select @value'
	EXEC(@sql)

	set @process = ''
	set @sql='ALTER procedure [dbo].[ccsp_Limpia]
@tel varchar(30),
@Camp int = 0
as
set nocount on
declare @lon tinyint, @ld varchar(4), @pais varchar(3), @extLen smallint
select @tel = dbo.limpia(@tel)
select @lon = len(@tel)
select @ld = valor from ccsettings where setting_id = 17
select @pais = valor from ccsettings where setting_id = 104
select @extLen = valor from ccsettings where setting_id = 108
declare @telTemp as varchar(15)

if @extLen=@lon and @lon>1
 begin
	select 0 as res, @tel as tel -- Extension
	return(0)
 end

if @pais = 1
 begin
	if @lon < 7 or @lon = 7 and len(@ld) = 2 or @lon = 8 and len(@ld) = 3 or @lon in (9, 11) or @lon > 13
	 begin
		select 1 as res, @tel as tel --Longitud invalida
		return(0)
	 end

	if @lon = 12 and left(@tel, 2) <> ''01'' or @lon = 13 and left(@tel, 3) <> ''044'' and left(@tel, 3) <> ''045'' and left(@tel, 3) <> ''001''
	 begin
		select 2 as res, @tel as tel--Digitos incorrectos
		return(0)
	 end

	if left(@tel, 3) = ''001''
	 begin
		select 0 as res, @tel as tel
		return(0)
	 end

	declare @mod varchar(5)
	select @tel = case when @lon in (7, 8) then @ld + @tel else right(@tel, 10) end
	select @mod = modalidad from series where cld + serie = left(@tel, 6) and right(@tel, 4) between [NUMERACION INICIAL] and [NUMERACION FINAL]

	if exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra))
	on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
	 begin
		select 4 as res, @tel as tel
		return(0)
	 end

	if @mod = ''CPP''
	 begin
		select 0 as res, case left(@tel, len(@ld)) when @ld then ''044'' else ''045'' end + @tel as tel
		return(0)
	 end

	if @mod in (''FIJO'', ''MPP'')
	 begin
		select 0 as res, case left(@tel, len(@ld)) when @ld then right(@tel, 10 - len(@ld)) else ''01'' + @tel end as tel
		return(0)
	 end

	--if @mod is null
	select 3 as res, @tel as tel--No encontrado
	return(0)
 end

if @pais = 2
 begin
	select @telTemp = @tel
	set @tel = dbo.completa(@tel)
	if left(@tel,1)=''E'' begin
		select 1 as res, @telTemp --Longitud Invalida
		return
	end

	select @tel = dbo.fnClearPhoneArg(@tel)

	if len(@tel) = 10 and left(@tel,1) <> ''E'' begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
	   begin
			select  @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		end else begin
			select 4 as res, @tel
			return(0)
		end
	end else begin select 2 as res, @telTemp as tel end --Digitos incorrectos
 end

if @pais = 3
 begin
	select @telTemp = @tel
	if @lon < 7 or @lon = 9 or (@lon = 10 and  left(@telTemp,1) <> ''3'') or (@lon = 11 and  left(@telTemp,2) <> ''03'') begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	end
	select @tel = dbo.Completa_ListaNegra(@tel)

	if (len(@tel) = 8 or len(@tel) = 10) and left(@tel,1) <> ''E''
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin
			select @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end
		else
		 begin
			select 4 as res, @tel
			return(0)
		 end
	 end
	else
	 begin
		select 2 as res, @telTemp as tel
	 end --Digitos incorrectos
 end

if @pais = 4
 begin
	exec ccsp_LimpiaUsa @tel, @Camp
	return(0)
 end

if @pais = 5
 begin
	select @telTemp = @tel
	if left(@tel,1)=''E''
	 begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	 end

	select @tel = dbo.Completa_ListaNegra(@tel)

	if len(@tel) in(8,9) and left(@tel,1) <> ''E''
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin
			select  @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end
		else
		 begin
			select 4 as res, @tel
			return(0)
		 end
	 end
	else
	 begin
		select 2 as res, @telTemp as tel
	 end --Digitos incorrectos
 end

if @pais = 6
 begin
	select @telTemp = @tel
	if left(@tel,1)=''E''
	 begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	 end

	select @tel = dbo.Completa_ListaNegra(@tel)


	if len(@tel) = 10 and left(@tel,1) <> ''E''
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin
			select @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		 end
		else
		 begin
			select 4 as res, @tel
			return(0)
		 end
	 end
	else
	 begin
		select 2 as res, @telTemp as tel
	 end --Digitos incorrectos
 end

if @pais = 7

 begin
	select @telTemp = @tel
	if left(@tel,1)=''E''
	 begin
		select 1 as res, @telTemp --Longitud Invalida
		return(0)
	 end

	select @tel = dbo.Completa_ListaNegra(@tel)

	if (len(@tel) = 9 or len(@tel) = 10) and left(@tel,1) <> ''E''
	 begin
		if not Exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		 begin

			select @tel = dbo.verifica(@tel)
			if left(@tel,1)=''E'' begin
				select 3 as res, @telTemp -- No existe el telefono
			end
			else begin
				select 0 as res, @telTemp  -- Todo Bien
			end
			return(0)
		 end
		else
		 begin
			select 4 as res, @tel --lista negra
			return(0)
		 end
	 end
	else
	 begin
		select 2 as res, @telTemp as tel
	 end --Digitos incorrectos
 end


if @pais = 8
 begin
	select @telTemp = @tel
	select @tel = dbo.Completa_ListaNegra(@tel)

	if left(@tel,1)=''E'' begin
		select 1 as res, @telTemp --Longitud Invalida
		return (0)
	end

	if (len(@tel) = 9 or len(@tel) = 10 or len(@tel) = 11 )
	begin
		if not exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra)) on (a1.idtipolista=a2.idtipolista) where cam_id=@Camp and telefono = @tel and status=1)
		begin
			select  @tel = dbo.verifica(@tel)
			select 0 as res, @tel
			return(0)
		end
		else
		begin
			select 4 as res, @tel
			return(0)
		end
	end
 end

if @pais = 9 --Australia
 begin
	select @telTemp = @tel
	select @tel = dbo.Completa_ListaNegra(@tel)

	if left(@tel,1)=''E''
		begin
			select 1 as res, @telTemp --Longitud Invalida
			return (0)
		end
	else
		begin
			if not exists(select a2.idtipolista
						  from cclistanegra a1
						  inner join camplistanegra a2 with(index(IX_Camplistanegra))
						  on (a1.idtipolista=a2.idtipolista)
						  where cam_id=@Camp
						  and telefono = @tel
						  and status=1)
				begin
					select  @tel = dbo.verifica(@tel)
					if left(@tel,1) <> ''E''
						begin
							select 0 as res, @tel
							return(0)
						end
					else
						begin
							select 2 as res, @telTemp as tel
							return(0)
						end
				end
			else
				begin
					select 4 as res, @tel
					return(0)
				end
		end
 end

if @pais = 10 -- Brasil
begin
	select @telTemp = @tel
	select @tel = dbo.Completa_ListaNegra(@tel)
	set @lon = len(@tel)
	if left(@tel,1)=''E''
		begin
			select 1 as res, @telTemp --Longitud Invalida
			return (0)
		end
	else
		begin
			if not exists(select a2.idtipolista
						  from cclistanegra a1
						  inner join camplistanegra a2 with(index(IX_Camplistanegra))
						  on (a1.idtipolista=a2.idtipolista)
						  where cam_id=@Camp
						  and telefono = @tel
						  and status=1)
				begin
					select  @tel = dbo.verifica(@tel)
					if left(@tel,1) <> ''E''
						begin
							select 0 as res, @tel
							return(0)
						end
					else
						begin
							select 2 as res, @telTemp as tel --digitos incorrectos
							return(0)
						end
				end
			else
				begin
					select 4 as res, @tel
					return(0)
				end
		end
end

if @pais = 11 -- Guatemala
begin
	select @telTemp = @tel
	select @tel = dbo.Completa_ListaNegra(@tel)
	if left(@tel,1)=''E''
		begin
			select 1 as res, @telTemp --Longitud Invalida
			return (0)
		end
	else
		begin
			if not exists(select a2.idtipolista
						  from cclistanegra a1
						  inner join camplistanegra a2 with(index(IX_Camplistanegra))
						  on (a1.idtipolista=a2.idtipolista)
						  where cam_id=@Camp
						  and telefono = @tel
						  and status=1)
				begin
					select  @tel = dbo.verifica(@tel)
					if left(@tel,1) <> ''E''
						begin
							select 0 as res, @tel
							return(0)
						end
					else
						begin
							select 2 as res, @telTemp as tel --digitos incorrectos
							return(0)
						end
				end
			else
				begin
					select 4 as res, @tel
					return(0)
				end
		end
end

if @pais = 12 -- Costa Rica
begin
	select @telTemp = @tel
	select @tel = dbo.Completa_ListaNegra(@tel)
	if left(@tel,1)=''E''
		begin
			select 1 as res, @telTemp --Longitud Invalida
			return (0)
		end
	else
		begin
			if not exists(select a2.idtipolista
						  from cclistanegra a1
						  inner join camplistanegra a2 with(index(IX_Camplistanegra))
						  on (a1.idtipolista=a2.idtipolista)
						  where cam_id=@Camp
						  and telefono = @tel
						  and status=1)
				begin
					select  @tel = dbo.verifica(@tel)
					if left(@tel,1) <> ''E''
						begin
							select 0 as res, @tel
							return(0)
						end
					else
						begin
							select 2 as res, @telTemp as tel --digitos incorrectos
							return(0)
						end
				end
			else
				begin
					select 4 as res, @tel
					return(0)
				end
		end
end

---
if @pais = 13 -- Salvador
begin
	select @telTemp = @tel
	select @tel = dbo.Completa_ListaNegra(@tel)
	if left(@tel,1)=''E''
		begin
			select 1 as res, @telTemp --Longitud Invalida
			return (0)
		end
	else
		begin
			if not exists(select a2.idtipolista
						  from cclistanegra a1
						  inner join camplistanegra a2 with(index(IX_Camplistanegra))
						  on (a1.idtipolista=a2.idtipolista)
						  where cam_id=@Camp
						  and telefono = @tel
						  and status=1)
				begin
					select  @tel = dbo.verifica(@tel)
					if left(@tel,1) <> ''E''
						begin
							select 0 as res, @tel
							return(0)
						end
					else
						begin
							select 2 as res, @telTemp as tel --digitos incorrectos
							return(0)
						end
				end
			else
				begin
					select 4 as res, @tel
					return(0)
				end
		end
end

set nocount off'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_RIALoadACDGroups'
	set @sql='ALTER PROCedure [dbo].[ccsp_RIALoadACDGroups]
@option smallint,
@AreaId smallint,
@Sup smallint,
@inbound_id int = 0,
@tipoModalidad tinyint = 0 -- llamada 0, chat 1 y ambos 2
AS
set nocount on
if @option = 1 -- Todas los ACDGroups
begin
select a1.inbound_id, descripcion, frame, isnull(IDArea,0)
from ccinbound a1 join ccRIAinboundGraph a2 on (a1.inbound_id = a2.inbound_id)
join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
where a3.type_id = 1
order by descripcion
return(0)
end

if @option = 2 -- ACDGroups de un Area
begin

	select distinct a1.inbound_id, descripcion, frame, isnull(IDArea,0) IDArea, dbo.fn_CampEspWG(a1.inbound_id, 2) relationsWG,a1.chat mode, skillDif
		from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
		inner join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
		left join (select inbound_id,case when (sum(skill)/count(user_id)) = max(skill) then 0 else 1 end skillDif from ccSkills GROUP BY inbound_id)
			S on S.Inbound_id=a1.inbound_id
		where a3.type_id = 1 and isnull(IDArea, 0) = isnull(@AreaId, 0)
		order by descripcion

return(0)
end

if @option = 3 -- ACDGroups por Supervisor
begin
select distinct a1.inbound_id, descripcion, frame, isnull(IDArea,0) as IDArea, U.monitored,a1.chat mode
from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
join ccSupervisorCam U on a1.inbound_id = U.cam_id
where U.user_id = @sup
and tipo = 0
and a3.type_id = 1
and a1.inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@Sup, 2))
order by descripcion
return(0)
end

if @option = 4 -- Rels ACD-Agents
begin
select inbound_id, descripcion, User_id, Login, skill, prioridad, IDArea, min(rel_id) rel_id
 from (select E.inbound_id, E.descripcion, A.User_id, A.Login, G.skill, G.prioridad, isnull(E.IDArea, 0) IDArea, G.rel_id
 from ccinboundAgentes G join ccinbound E on G.inbound_id = E.inbound_id
 join ccUsers A on A.User_id = G.User_id and A.TipoUser_Id = 1 and A.Status > 0
 where E.inbound_id in (select cam_id from ccsupervisorcam where user_id = case isnull(@Sup,0)
  when 0 then user_id else @Sup end and tipo = 0)) as Relations
 group by inbound_id, descripcion, User_id, Login, skill, prioridad, IDArea
order by User_id, inbound_id, descripcion, prioridad
return(0)
end

if @option = 5 -- Todos los ACDGroups
begin
option5:
select a1.inbound_id, descripcion, frame, isnull(IDArea,0)
from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
where a3.type_id = 1
order by descripcion
return(0)
end

if @option = 7 -- Un solo ACDGroups
begin
select a1.inbound_id, descripcion, frame, isnull(IDArea,0)
from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
where a3.type_id = 1 and status = 1 and a1.inbound_id = @inbound_id
order by descripcion
return(0)
end

if @option = 8 -- ACDGroups de un Agente
begin
select distinct a1.inbound_id, a1.descripcion, a3.frame
from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
 join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
 join ccInboundAgentes a4 on a1.inbound_id = a4.inbound_id
where a3.type_id=1 and a4.user_id = @Sup
order by 2
return(0)
end

if @option = 9 -- ACDGroups por Supervisor para mensajes llamadas o chat filtra las campaÃ±as
begin
select distinct a1.inbound_id, descripcion, frame, isnull(IDArea,0) as IDArea, U.monitored
from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
join ccSupervisorCam U on a1.inbound_id = U.cam_id
where U.user_id = @sup
and tipo = 0
and a3.type_id = 1
and a1.inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@Sup, 2))
and a1.chat IN (2,@tipoModalidad)
order by descripcion
return(0)
end

return(0)
set nocount off'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_RIAsubCalif'
	set @sql='alter procedure [dbo].[ccsp_RIAsubCalif]
@action tinyint = 0,
@tipo tinyint = null, -- 0:Outbound / 1:Inbound
@calif_id varchar(max) = nulesol,
@califSub_id varchar(max) = null,
@califSubDesc varchar(40) = null,
@canReprogramSub tinyint = null,
@orden varchar(3) = null,
@idTipoLista int = null,
@keepDial tinyint = null,
@autoCallback tinyint = null,
@endConversation tinyint = null
as
set nocount on
begin try
 declare @sxML as varchar(max), @xml as xml, @succesValue varchar(2), @succesType varchar(2)
 set @xml = cast(''<?xml version="1.0"?> <MainSubQualificationLoad/>'' as xml)
 set @xml.modify(''insert element action {""} as last into (/MainSubQualificationLoad)[1]'')
 set @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/MainSubQualificationLoad/action)[1]'')

 if @action = 0
  begin
  select @succesValue=0, @succesType=1 -- No se ingreso el action
  goto Success
  end

 if @action=1 -- Muestra info de Inbound
  begin
  set @xml.modify(''insert element qualifications {""} as last into (/MainSubQualificationLoad)[1]'')
  set @xml.modify(''insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]'')
  set @xml.modify(''insert element subQualifications {""} as last into (/MainSubQualificationLoad)[1]'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  calif_id as "qualification!1!qualif_id", Description as "qualification!1!qualification",
  CanReprogram as "qualification!1!canReprogram", orden as "qualification!1!sort", isnull(endConversation,0) as "qualification!1!endConversation"
  from cctipocalif where Calif_Status=1) as x order by tag, "qualification!1!sort",
  "qualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<qualifications/>'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification", isnull(O.canReprogram,0) "qualifRelation!1!canReprogram", isnull(O.EndConversation,0) "qualifRelation!1!endConversation"
  from cctipoSubCalifRel R join cctipocalifSub O on R.califSub_id = O.califSub_id
  where R.tipoSubRel=1 and R.calif_id in (select top 1 calif_id from cctipocalif where Calif_Status=1 order by orden, Description)) as x
  order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  califSub_id as "subQualification!1!qualif_id", califSubDesc as "subQualification!1!qualification",
  isnull(CanReprogram, 0) as "subQualification!1!canReprogram", isnull(orden, 0) as "subQualification!1!sort", isnull(EndConversation, 0) as "subQualification!1!endConversation"
  from cctipocalifSub where CalifSub_Status=1 ) as x order by tag, "subQualification!1!sort",
  "subQualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<subQualifications/>'')

  select @xml
  return(0)
  end

 if @action=2 -- Muestra Info de Outbound
  begin
  set @xml.modify(''insert element qualifications {""} as last into (/MainSubQualificationLoad)[1]'')
  set @xml.modify(''insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]'')
  set @xml.modify(''insert element subQualifications {""} as last into (/MainSubQualificationLoad)[1]'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  calif_id as "qualification!1!qualif_id", Description as "qualification!1!qualification",
  CanReprogram as "qualification!1!canReprogram", orden as "qualification!1!sort",
  autoCallback as "qualification!1!AutoCB", keepDial as "qualification!1!keepDial"
  from cctipocalifOUT where CalifOut_Status=1) as x order by tag, "qualification!1!sort",
  "qualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<qualifications/>'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification", isnull(O.canReprogram,0) "qualifRelation!1!canReprogram"
  from cctipoSubCalifRel R join cctipocalifSubOUT O on R.califSub_id = O.califSub_id
  where R.tipoSubRel=0 and R.calif_id in (select top 1 calif_id from cctipocalifOUT where CalifOUT_Status=1 order by orden, Description)) as x
  order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  califSub_id as "subQualification!1!qualif_id", califSubDesc as "subQualification!1!qualification",
  isnull(CanReprogram,0) as "subQualification!1!canReprogram", isnull(orden,0) as "subQualification!1!sort",
  isnull(autoCallback,0) as "subQualification!1!AutoCB", isnull(keepDial,0) as "subQualification!1!keepDial"
  from cctipocalifSubOUT where CalifSubOut_Status=1 ) as x order by tag, "subQualification!1!sort",
  "subQualification!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<subQualifications/>'')

  select @xml
  return(0)
  end

  if @tipo is null
  begin
  select @succesValue=0, @succesType=2 -- No se ingreso el tipo
  goto Success
  end

 if @action=3 -- Muestra relacion de Calificaciones con subCalificaciones
  begin
  set @xml.modify(''insert element relQualif {""} as last into (/MainSubQualificationLoad)[1]'')

  if @tipo=0
   begin
   select @sxML = cast((select * from (select 1 as tag, null as parent,
   R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification",
   isnull(O.canReprogram,0) "qualifRelation!1!canReprogram", autoCallback "qualifRelation!1!autoCallback"
   from cctipoSubCalifRel R join cctipocalifSubOUT O on R.califSub_id = O.califSub_id
   where R.tipoSubRel=0 and R.calif_id in (select value from dbo.fn_RIASplitDelimited(@calif_id,'',''))) as x
   order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
   select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')
   select @xml
   return(0)
   end

  select @sxML = cast((select * from (select 1 as tag, null as parent,
  R.califSub_id "qualifRelation!1!qualif_id", O.califSubDesc "qualifRelation!1!qualification",
  isnull(O.canReprogram,0) "qualifRelation!1!canReprogram"
  from cctipoSubCalifRel R join cctipocalifSub O on R.califSub_id = O.califSub_id
  where R.tipoSubRel=1 and R.calif_id in (select value from dbo.fn_RIASplitDelimited(@calif_id,'',''))) as x
  order by tag, "qualifRelation!1!qualification" for xml explicit, type) as varchar(max))
  select @xml=dbo.xmlAppend(@xml, @sxML, ''<relQualif/>'')
  select @xml
  return(0)
  end

 if @action=4 -- Alta de subcalificaciones
  begin
  if isnull(@califSubDesc, '''')=''''
   begin
   select @succesValue=0, @succesType=6 -- No se ingreso el nombre de la subcalificacion
   goto Success
   end

  if @tipo=0
   begin
   if exists(select califSub_id from cctipocalifSubOUT where califSubOut_Status=1 and califSubDesc=@califSubDesc)
    begin
    select @succesValue=0, @succesType=3 -- La subCalificacion ya existe
    goto Success
    end

   insert cctipocalifSubOUT (califSubDesc, canReprogram, orden, idTipoLista, califSubOut_Status, keepDial, autoCallback)
   select @califSubDesc, @canReprogramSub, @orden, @idTipoLista, 1, @keepDial, @autoCallback
   select @succesType=scope_identity(), @succesValue=1
   goto Success
   end

  if exists(select califSub_id from cctipocalifSub where califSub_Status=1 and califSubDesc=@califSubDesc)
   begin
   select @succesValue=0, @succesType=3 -- La subCalificacion ya existe
   goto Success
   end
  insert cctipocalifSub (califSubDesc,orden,canReprogram,califSub_Status,EndConversation)
        select @califSubDesc, @orden, @canReprogramSub, 1,isnull(@endConversation, 0)
  select @succesType=scope_identity(), @succesValue=1
  goto Success
  end

 if @action=5 -- baja de subcalificaciones
  begin
   delete cctipoSubCalifRel where tipoSubRel=@tipo and califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, '',''))

  if @tipo=0
   begin
   update cctipocalifSubOUT set califSubOut_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, '',''))
   update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
   select @succesValue=1
   goto Success
   end

  update cctipocalifSub set califSub_Status=0 where califSub_id in (select value from dbo.fn_RIASplitDelimited(@califSub_id, '',''))
  select @succesValue=1
  goto Success
  end

 if @action=6 -- Actualizacion de subcalificaciones
  begin
   if @tipo=0
   begin
   if not exists(select califSub_id from cctipocalifSubOUT where califSub_id = cast(@califSub_id as smallint))
    begin
    select @succesValue=0, @succesType=4 -- La subCalificacion no existe
    goto Success
    end

   update cctipocalifSubOUT set califSubDesc=isnull(@califSubDesc, califSubDesc), canReprogram=isnull(@canReprogramSub, canReprogram),
    orden=isnull(@orden, orden), idTipoLista=isnull(@idTipoLista, idTipoLista), keepDial=isnull(@keepDial, keepDial),
    autoCallback=isnull(@autoCallback, autoCallback) where califSub_id = cast(@califSub_id as smallint)
   update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
   select @succesValue=1
   goto Success
   end

  if not exists(select califSub_id from cctipocalifSub where califSub_id = cast(@califSub_id as smallint))
   begin
   select @succesValue=0, @succesType=4 -- La subCalificacion no existe
   goto Success
   end

  if @canReprogramSub=1
         begin
   declare @asignada bit, @can bit
   select @asignada=IB.inbound_id, @can=IB.cam_id from cctipoSubCalifRel CR join cctipoCalif TC on CR.calif_id = TC.calif_id and CR.tipoSubRel=1
      join ccCalifCamp CM on TC.calif_id = CM.calif_id and CM.tipo = 0 join ccInbound IB on CM.cam_id = IB.inbound_id where califSub_id = cast(@califSub_id as smallint)
            if @asignada is not null and @can is null
       begin
       select @succesValue=0, @succesType=5 -- No se puede reprogramar ya que no hay campaña asignada
       goto Success
       end
         end

  update cctipocalifSub set califSubDesc=isnull(@califSubDesc, califSubDesc), orden=isnull(@orden, orden),
   canReprogram=isnull(@canReprogramSub, canReprogram), EndConversation = isnull(@endConversation, 0) where califSub_id = cast(@califSub_id as smallint)

  exec ccsp_RIACATQualifications @Type = 4, @CamEspId = 0, @canReprogram = @canReprogramSub, @qualif_id = @califSub_id
  select @succesValue=1
  goto Success
  end

 if @action=7 -- Asignacion de Calfs / SubCalfs
  begin
  if @tipo=1 and (select cast(sum(isnull(cast(canReprogram as tinyint),0)) as bit) FROM cctipocalifSub where califSub_id in
  (select value from dbo.fn_RIASplitDelimited (@califSub_id, '','')))>0 and not exists (select IB.cam_id from cctipocalif CO
  join ccCalifCamp CF on  CF.calif_id = CO.calif_id and CF.tipo = 0 join ccInbound IB on IB.Inbound_id = CF.cam_id
  where IB.cam_id is not null and CO.calif_id in (select value from dbo.fn_RIASplitDelimited (@calif_id, '','')))
   begin
   select @succesValue=0, @succesType=5 -- No se puede reprogramar ya que no hay campaña asignada
   goto Success
   end

  insert cctipoSubCalifRel (calif_id, califSub_id, tipoSubRel)
  select C.value calif_id, S.value califSub_id, @tipo Tipo
  from dbo.fn_RIASplitDelimited (@califSub_id, '','') S
   cross join dbo.fn_RIASplitDelimited (@calif_id, '','') C
  where cast(C.value as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@tipo as varchar(10)) not in
   (select cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) from cctipoSubCalifRel)
  and C.value is not null and S.value is not null

  if @tipo=0
   update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)

  select @succesValue=1
  goto Success
  end

 if @action=8 -- Desasignacion de Calfs / SubCalfs
  begin
  delete cctipoSubCalifRel
  where cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) in
  (select cast(C.value as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@tipo as varchar(10))
   from dbo.fn_RIASplitDelimited (@califSub_id, '','') S cross join dbo.fn_RIASplitDelimited (@calif_id, '','') C)

  if @tipo=0
   update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)

  select @succesValue=1
  goto Success
  end

 return(0)
 end try

begin catch
 select @succesValue=0, @succesType=0 -- error no controlado
 goto Success
end catch

Success: -- <success value=''n'' type=''n''/>
set @xml.modify(''insert element success {""} as last into (/MainSubQualificationLoad)[1]'')
set @xml.modify(''insert attribute value {sql:variable("@succesValue")} as last into (/MainSubQualificationLoad/success)[1]'')
if isnull(@succesType, 0) <> 0
 begin
 set @xml.modify(''insert attribute type {sql:variable("@succesType")} as last into (/MainSubQualificationLoad/success)[1]'')
 end
select @xml
return(0)
set nocount off'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_RIACATQualifications'
	set @sql='alter PROCEDURE [dbo].[ccsp_RIACATQualifications]
@qualif_id varchar(max),
@Description varchar(40)=null,
@order varchar(3)=null,
@canReprogram varchar(1)=null,
@Type smallint,
@CamEspId smallint,
@keepDial bit=null,
@autoCB bit=null,
@endConversation varchar(1)=null
AS
set nocount on
declare @sql nvarchar(1000)

if @Type=0
 begin
 if @CamEspId=0
  begin
  SELECT calif_id, description FROM ccTipoCalif WITH(NOLOCK) WHERE Calif_Status=1 and description=@qualif_id
  return(0)
  end

 SELECT calif_id, description FROM ccTipoCalifOUT  WHERE CalifOut_Status=1 and description=@qualif_id
 return(0)
 end

if @Type=1 -- Load cctipoCalif
 begin
 Select C.calif_id, C.Description, C.orden, cast(C.canReprogram as int) as canReprogram, cast(count(R.califRel_id)as tinyint) hasSub
 ,isnull(C.EndConversation,0) conversationEnd
 from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
 where C.Calif_Status=1
 group by C.calif_id, C.Description, C.orden, cast(C.canReprogram as int)  ,C.EndConversation
 order by 2
 return(0)
 end

If @Type=2 -- Load cctipoCalifOUT
 begin
 Select C.calif_id, C.Description, cast(C.canReprogram as int) as canReprogram, C.orden,
 cast(C.keepDial as int) as keepDial, cast(C.autocallback as int) autocallback, cast(count(R.califRel_id)as tinyint) hasSub
 from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
 where C.CalifOut_Status=1
 group by C.calif_id, C.Description, cast(C.canReprogram as int), C.orden, cast(C.keepDial as int), cast(C.autocallback as int)
 order by 2
 return(0)
 end

If @Type=3 -- New cctipoCalif
 begin
 If exists(select description from ccTipoCalif where Calif_Status=1 and description=@Description)
  begin
  select 2
  return(0)
  end

 If exists(select description from ccTipoCalif where Calif_Status=0 and description=@Description)
 begin
  update ccTipoCalif set orden=@order, CanReprogram=isnull(@canReprogram,0),EndConversation=isnull(@endConversation,0), Calif_Status=1
  where description=@Description
  return(0)
 end

 insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation)
 select isnull(max(calif_id), 0) + 1,@Description, @order, isnull(@canReprogram,0), isnull(@endConversation,0) from ccTipoCalif
 return(0)
 end

If @Type=4 -- Update cctipoCalif
 begin
 If exists(select description from ccTipoCalif where Calif_Status=1 and description=@Description)
  set @Description=null

 UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
 canReprogram=isnull(@canReprogram, canReprogram), EndConversation=isnull(@endConversation,EndConversation)
 where calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))

 delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
 tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

 return(0)
 end

If @Type=5 -- elimina calif
 begin
 delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
 delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
 update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
 return(0)
 end

If @Type=6 -- New cctipoCalifOUT
 begin
 If exists(select description from ccTipoCalifOut where CalifOut_Status=1 and description=@Description)
  begin
  select 2
  return(0)
  end

 If exists(select description from ccTipoCalifOut where CalifOut_Status=0 and description=@Description)
 begin
  update ccTipoCalifOut set orden=@order, CanReprogram=isnull(@canReprogram,0),
  Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0)
  where description=@Description
  return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram,keepDial, autocallback )
 select isnull(max(calif_id), 0) + 1, @Description, @order , 0, @canReprogram, isnull(@keepDial,0), isnull(@autoCB,0) from ccTipoCalifOut
 return(0)
 end

If @Type=7 -- Update cctipoCalifOUT
 begin
 If exists(select Description from ccTipoCalifOUT where CalifOut_Status=1 and Description=@Description)
  set @Description=null

 UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
 canReprogram=isnull(@canReprogram, canReprogram), keepDial=isnull(@keepDial,keepDial), autocallback = isnull(@autoCB,autocallback)
 where calif_id=@qualif_id

 if @keepDial is not null
  begin
  update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
  end
 return(0)
 end

If @Type=8 -- elimina calif OUT
 begin
 delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
 delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
 update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@qualif_id, '',''))
 update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
 return(0)
 end

If @Type=9
 begin
 select o.cam_id, cam_descripcion , c.calif_id, co.description as Calificacion, canReprogram, orden, cast(autoCallback as tinyint) autoCallback
 from ccCamps o left join ccCalifCamp c on o.cam_id=c.cam_id and c.tipo=1
 inner join ccTipoCalifOUT co on c.calif_id=co.calif_id
 where co.CalifOut_Status=1 and o.cam_id=@CamEspId
 order by 4
 return(0)
 end

If @Type=10
 begin
 select i.inbound_id as cam_id, descripcion, c.calif_id, ci.description as Calificacion, orden, cast(ci.canreprogram as integer) canreprogram, cast(isnull(ci.EndConversation,0) as integer) EndConversation
 from ccInbound i left join ccCalifCamp c on i.inbound_id=c.cam_id and c.tipo=0
 inner join ccTipoCalif ci on c.calif_id=ci.calif_id
 where ci.Calif_Status=1 and inbound_id=@CamEspId
 order by 4
 return(0)
 end
set nocount off'
	EXEC(@sql)

	set @process = 'Alter SP -- ccsp_AgentGetCalificaciones'
	set @sql='alter procedure dbo.ccsp_AgentGetCalificaciones
@InOut tinyint, --0 in, 1 out
@cam_id int --campaÏa
AS
set nocount on

IF @InOut = 0
 BEGIN
 if exists(select calif.calif_id from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
  left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
  left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
  where cam_id = @cam_id and tipo = @InOut)
  begin
  select distinct 1 as tag, null as parent, calif.calif_id "selection!1!id", calif.Description "selection!1!string", calif.orden "selection!1!califorden", isnull(calif.EndConversation,0) "selection!1!endConversation",
  null "subSelection!2!id", null "subSelection!2!string", null "subSelection!2!orden",  null "subSelection!2!endConversation"
  from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
  left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
  left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
  where cam_id = @cam_id and tipo = @InOut
  union
  select distinct 2 as tag, 1 as parent, calif.calif_id "selection!1!id", null "selection!1!string", calif.orden "selection!1!califorden", isnull(calif.EndConversation,0) "selection!1!endConversation",
  sb.califsub_id "subSelection!2!id", sb.califSubDesc "subSelection!2!string", cast(sb.orden as int) "subSelection!2!orden" ,isnull(sb.EndConversation,0) "subSelection!2!endConversation"
  from ccTipoCalif calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
  left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=1
  left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
  where cam_id = @cam_id and tipo = @InOut and sb.califsub_id is not null
  order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden"
  for xml explicit, type
  end
 return(0)
 END

IF @InOut = 1
 BEGIN
 if exists(select calif.calif_id from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
  left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
  left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
  where cam_id = @cam_id and tipo = @InOut)
  begin
   select distinct 1 as tag, null as parent, calif.calif_id "selection!1!id", calif.Description "selection!1!string", calif.keepDial "selection!1!keepOnDial",
   calif.orden "selection!1!califorden", null "subSelection!2!id", null "subSelection!2!string", null "subSelection!2!keepOnDial",
   null "subSelection!2!orden"
  from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
  left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
  left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
  where cam_id = @cam_id and tipo = @InOut
  union
  select distinct 2 as tag, 1 as parent, calif.calif_id "selection!1!id", null "selection!1!string", null "selection!1!keepOnDial",
  calif.orden "selection!1!califorden", sb.califsub_id "subSelection!2!id", sb.califSubDesc "subSelection!2!string", sb.keepDial "subSelection!2!keepOnDial",
  cast(sb.orden as int) "subSelection!2!orden"
  from ccTipoCalifOUT calif join ccCalifCamp camp on camp.calif_id=calif.calif_id
  left join cctipoSubCalifRel rel on calif.calif_id=rel.calif_id and rel.tipoSubRel=0
  left join ccTipoCalifSubOUT sb on rel.califsub_id=sb.califsub_id
  where cam_id = @cam_id and tipo = @InOut and sb.califsub_id is not null
  order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden"
  for xml explicit, type
  end
 return(0)
 END

IF @InOut = 10
 BEGIN
  select distinct S.califSub_id, S.califSubDesc, orden
  from cctipoSubCalifRel R join cctipoCalifSub S on R.califSub_id = S.califSub_id
 where R.tipoSubRel=1 and S.califSub_Status=1 and R.calif_id=@cam_id
 order by S.orden, S.califSubDesc
 return(0)
 END

IF @InOut = 11
 BEGIN
  select distinct S.califSub_id, S.califSubDesc, orden
  from cctipoSubCalifRel R join cctipoCalifSubOut S on R.califSub_id = S.califSub_id
 where R.tipoSubRel=0 and S.califSubOut_Status=1 and R.calif_id=@cam_id
 order by S.orden, S.califSubDesc
 return(0)
 END

set nocount off'
	EXEC(@sql)

	set @process = 'ALTER SP -- ccsp_RIAScheduleEsp'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAScheduleEsp]
@Type smallint,
@Type2 smallint,
@IDArea smallint=0,
@CamEspID smallint,
@User_id smallint,
@InOut_Id smallint,
@InsertSchedule_id varchar(1000),
@DeleteSchedule_id varchar(1000)
AS
set nocount on

If @Type=1--get camps
 begin
	SELECT a1.cam_id, a1.cam_descripcion, a3.frame,CASE a1.CallsBySurvey WHEN 0 THEN 0 ELSE 1 END as ''CallsBySurvey''  FROM ccCamps a1
	inner join ccRIACampsGraph a2 on(a1.cam_id=a2.cam_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where isnull(IDArea, -1) = case
	when @IDArea = 0 then -1
	when (select login from ccusers where user_id = @User_id) = ''root'' then isnull(IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

If @Type=2--get ACDGroups
 begin
	SELECT a1.Inbound_id, descripcion, a2.graphic_id, a3.frame,a1.chat mode from ccInbound a1
	inner join ccRIAInboundGraph a2 on(a1.Inbound_id=a2.Inbound_id)
	inner join ccRIAGraphics a3 on(a2.graphic_id=a3.graphic_id)
	where isnull(a1.IDArea, -1) = case when @IDArea=0 then -1
	when (select login from ccusers where user_id = @User_id) = ''root'' then isnull(a1.IDArea, -1)
	else @IDArea end
	order by 2
	return(0)
 end

IF @Type=3--query
 begin
	If(@Type2=0)--ACDGroup
	 begin
		select c.inbound_id, c.descripcion as c_descripcion, ih.horario_id, h.descripcion as h_descripcion,
		cast(lunes as int)as lunes, cast(martes as int)as martes, cast(miercoles as int)as miercoles, cast(jueves as int)as jueves, cast(viernes as int)as viernes, cast(sabado as int)as sabado, cast(domingo as int)as domingo,
		dbo.RIAtimeFormat(horainicio)as horaInicio, dbo.RIAtimeFormat(mininicio)as minInicio, dbo.RIAtimeFormat(horafin)as horaFin, dbo.RIAtimeFormat(minfin)as minFin
		from ccInbound c left join ccInboundHorarios ih on c.inbound_id=ih.inbound_id
		inner join ccHorarios h on ih.horario_id=h.horario_id where status=1
		and c.inbound_id=@CamEspID--in(select cam_id from ccSupervisorCam where tipo=0 and user_id=@User_id and cam_id=@CamEspID)
		ORDER BY 4
		return(0)
	 end

	If(@Type2=1)--Camp
	 begin
	  	select c.cam_id, c.cam_descripcion as c_descripcion, ch.horario_id, h.descripcion as h_descripcion,
	 	cast(lunes as int)as lunes, cast(martes as int)as martes, cast(miercoles as int)as miercoles, cast(jueves as int)as jueves, cast(viernes as int)as viernes, cast(sabado as int)as sabado, cast(domingo as int)as domingo,
	 	dbo.RIAtimeFormat(horainicio)as horaInicio, dbo.RIAtimeFormat(mininicio)as minInicio, dbo.RIAtimeFormat(horafin)as horaFin, dbo.RIAtimeFormat(minfin)as minFin
	 	from ccCamps c left join ccCampsHorarios ch on c.cam_id=Ch.cam_id
	 	inner join ccHorarios h on ch.horario_id=h.horario_id
	 	where c.cam_id=@CamEspID--in(select cam_id from ccSupervisorCam where tipo=0 and user_id=@User_id and cam_id=@CamEspID)
		ORDER BY 4
		return(0)
	 end
 end

If @Type=4
 begin
	if exists(select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id)
	and (select login from ccUsers where user_id=@User_id)<>''root''
		select a.* from ccRIACAT_Areas a join ccusers c on a.idarea = c.idarea where a.StatusArea=1 and c.user_id = @user_id
	else
		select * from ccRIACAT_Areas where StatusArea=1 order by AreaName
	return(0)
 end

declare @sql as nvarchar(1000), @nIDArea as varchar(10)

if @Type=5--Insert Schedules
 begin
	If @Type2=3
	 begin
		If exists(select inbound_id from ccInboundHorarios where inbound_id=@CamEspID and horario_id=@InsertSchedule_id)
			select 2
		else
			insert ccInboundHorarios(inbound_id, horario_id) select @CamEspID, @InsertSchedule_id
		return(0)
	 end

	If @Type2=2
	 begin
		If exists(select cam_id from ccCampsHorarios where cam_id=@CamEspID and horario_id=@InsertSchedule_id)
			select 2
		else
			insert ccCampsHorarios(cam_id, horario_id) select top 1 @CamEspID, @InsertSchedule_id
		return(0)
	 end

	If @Type2<>1
		return(0)

	If @InOut_Id=0--ACD
	 begin
		If @IDArea=0
		 begin
			set @sql=''insert ccInboundHorarios
			select distinct a.inbound_id, b.horario_id from ccInbound a, ccHorarios b where
			b.horario_id in(''+@InsertSchedule_id+'')
			and not exists(select c.inbound_id, e.horario_id from ccInboundHorarios c
			join ccHorarios e on e.horario_id=c.horario_id
			join ccInbound d on d.inbound_id=c.inbound_id and IDArea is null
			where c.inbound_id=a.inbound_id and b.horario_id=e.horario_id)
			and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea is null)''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''insert ccInboundHorarios select distinct a.inbound_id, b.horario_id
		from ccInbound a, ccHorarios b where b.horario_id in(''+@InsertSchedule_id+'')
		and not exists(select c.inbound_id, e.horario_id from ccInboundHorarios c
		join ccHorarios e on e.horario_id=c.horario_id
		join ccInbound d on d.inbound_id=c.inbound_id and IDArea=''+@nIDArea+
		'' where c.inbound_id=a.inbound_id and b.horario_id=e.horario_id)
		and a.inbound_id in(select x.inbound_id from ccInbound x where IDArea=''+@nIDArea+'')''
		execute sp_executesql @sql
		return(0)
	 end

	If @InOut_Id=1--Camp
	 begin
		If @IDArea=0
		 begin
			set @sql=''insert ccCampsHorarios
			select distinct a.cam_id, b.horario_id from ccCamps a, ccHorarios b where
			b.horario_id in(''+@InsertSchedule_id+'')
			and not exists(select c.cam_id, e.horario_id from ccCampsHorarios c
			join ccHorarios e on e.horario_id=c.horario_id
			join ccCamps d on d.cam_id=c.cam_id and IDArea is null
			where c.cam_id=a.cam_id and b.horario_id=e.horario_id)
			and a.cam_id in(select x.cam_id from ccCamps x where IDArea is null)''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''insert ccCampsHorarios select distinct a.cam_id, b.horario_id
		from ccCamps a, ccHorarios b where b.horario_id in(''+@InsertSchedule_id+'')
		and not exists(select c.cam_id, e.horario_id from ccCampsHorarios c
		join ccHorarios e on e.horario_id=c.horario_id
		join ccCamps d on d.cam_id=c.cam_id and IDArea=''+@nIDArea+
		'' where c.cam_id=a.cam_id and b.horario_id=e.horario_id)
		and a.cam_id in(select x.cam_id from ccCamps x where IDArea=''+@nIDArea+'')''
		execute sp_executesql @sql
		return(0)
	 end
 end

If @Type=6--Delete Schedules
 begin
	If @Type2=3
	 begin
		delete ccInboundHorarios where inbound_id=@CamEspID	and horario_id=@DeleteSchedule_id
		return(0)
	 end

	If @Type2=2
	 begin
		delete ccCampsHorarios where cam_id=@CamEspID and horario_id=@DeleteSchedule_id
		return(0)
	 end

	If @Type2<>1
		return(0)

	If @InOut_Id=0--ACD
	 begin
		If @IDArea=0
		 begin
			set @sql=''delete ccInboundHorarios where inbound_id in(select inbound_id from
			ccInbound where IDArea is null) and Horario_id in(''+@DeleteSchedule_id+'')''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''delete ccInboundHorarios where inbound_id in(select inbound_id from
		ccInbound where IDArea=''+@nIDArea+'') and Horario_id in(''+@DeleteSchedule_id+'')''
		execute sp_executesql @sql
		return(0)
	 end

	If @InOut_Id=1--Camp
	 begin
		If @IDArea=0
		 begin
			set @sql=''delete ccCampsHorarios
			where cam_id in(select cam_id from ccCamps where IDArea is null)
			and Horario_id in(''+@DeleteSchedule_id+'')''
			execute sp_executesql @sql
			return(0)
		 end

		set @nIDArea=@IDArea
		set @sql=''delete ccCampsHorarios
		where cam_id in(select cam_id from ccCamps where IDArea=''+@nIDArea+'')
		and Horario_id in(''+@DeleteSchedule_id+'')''
		execute sp_executesql @sql
		return(0)
	 end
 end

return(0)
set nocount off'
	EXEC(@sql)



	set @process = 'ALTER SP -- ccsp_RIAInsertChat'
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

       set @crmNode = null

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
end'
	EXEC(@sql)

	set @process = 'Fix generated  -- ccFinderServices and ccBaseXDB'
	set @sql='declare @count int, @i int
declare @sql nvarchar(max),@name sysname

select serviceId,dateStart,Xname,isFull into #tempBaseXDB from ccBaseXDB where serviceId in (1,2)

delete ccBaseXDB
delete [ccFinderServices]


select ROW_NUMBER() OVER(ORDER BY name DESC) AS Row,*
into #tempNameConstraint
from(
select name from sys.default_constraints where parent_object_id= OBJECT_ID(N''ccBaseXDB'', N''U'')
union
SELECT OBJECT_NAME(f.constraint_object_id) FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''ccBaseXDB'' and  c1.[name]=''serviceId'')X

select @count=count(*),@i=1 from #tempNameConstraint
while @i<@count begin
	select @name = name from #tempNameConstraint where row=@i
	set @i=@i+1
	set @sql=''ALTER TABLE [dbo].[ccBaseXDB] DROP CONSTRAINT [''+@name+'']''
	exec(@sql)
end

DROP TABLE [dbo].[ccBaseXDB]
DROP TABLE [dbo].[ccFinderServices]


CREATE TABLE [dbo].[ccBaseXDB](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[serviceId] [int] NULL,
	[dateStart] [datetime] NULL,
	[dateEnd] [datetime] NULL,
	[Xname] [varchar](25) NULL,
	[isFull] [bit] NULL,
PRIMARY KEY CLUSTERED
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE TABLE [dbo].[ccFinderServices](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](20) NULL,
	[ref] [varchar](3) NULL,
PRIMARY KEY CLUSTERED
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


ALTER TABLE [dbo].[ccBaseXDB] ADD  DEFAULT (NULL) FOR [dateEnd]
ALTER TABLE [dbo].[ccBaseXDB] ADD  DEFAULT ((0)) FOR [isFull]
ALTER TABLE [dbo].[ccBaseXDB]  WITH CHECK ADD FOREIGN KEY([serviceId]) REFERENCES [dbo].[ccFinderServices] ([id])



if not exists (select * from ccFinderServices where name = N''Chat'')
begin
	insert into ccFinderServices (name, ref) values (''Chat'', ''R01'')
	insert into ccFinderServices (name, ref) values (''Rec'', ''R02'')
end


insert into ccBaseXDB(serviceId,dateStart,Xname,isFull)
select serviceId,dateStart,Xname,isFull   from #tempBaseXDB



drop table #tempNameConstraint
drop table #tempBaseXDB'
	EXEC(@sql)

	set @process = 'CREATE STOREPROCEDURE -- ccsp_RIAImageHandler'
		set @sql='CREATE  procedure [dbo].[ccsp_RIAImageHandler]
	@option int,
	@imageId int= null,
	@path varchar(100)= null

	AS

	if @option = 1 --Load All images
	begin
		select * from ccRIAImages where idImage=@imageId
	end





	if @option = 2 --insert images
	begin
		if (select count(path) from ccRIAImages where path=@path) > 0
			begin
				select -1 -- Ya existe imagen con ese nombre
			end
		else
			begin
				insert into ccRIAImages values (@path)
				select @imageId = scope_identity()
				select @imageId
			end
	end



	if @option = 3 --Update Path images
	begin
		if ( select count(idImage) from ccRIAImages where idImage=@imageId) = 0
			begin
				select -1 --EL Id no se encuentra asociado
			end
		else
			begin
				update ccRIAImages set path=@path where idImage=@imageId
			end
	end







	if @option = 4 --Delete images
	begin
		if ( select count(idImage) from ccRIAImages where idImage=@imageId) = 0
			begin
				select -1 --EL Id no se encuentra asociado
			end
		else
			begin
				delete ccRIAImages where idImage=@imageId
			end
	end





	if @option = 5 --Load All images
	begin
		if (select count(idImage) from ccRIAImages) > 0
			BEGIN
				select * from ccRIAImages  order by 1
			END
		ELSE
			BEGIN
				select -1
			END
	end



	if @option = 6 --Return path images
	begin
		if ( select count(idImage) from ccRIAImages where idImage=@imageId) = 0
			begin
				select -1 --EL Id no se encuentra asociado
			end
		else
			begin
				select path from ccRIAImages where idImage=@imageId
			end
	end'
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