/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author: Jesus Gallardo
Date: 2014/10/06
Description:
	Se modifca ccsettings el tamaño de la columna descripcion
	Se crea la funcion fn_RIASplitDelimited regresa un objeto tipo tabla
	
	Se agrega setting 166 para validar hora de marcacion independiente de los horarios de las campañas
	Se agrega setting 167 para servicio de descarga del finder
	Se actualiza setting 112 la descripcion para informar que tiene mayor precedencia el setting 166
	Se actualiza setting 131 para agregar el parametro memoria incial de applet de mizu
	Se agrega funcion AuthorizationCallLaw para validar hora y zonas horarias marcada por la ley 
	Se modifica SP ccsp_ADMCampHorarios para validar hora y zonas horarias marcada por la ley 
	Se modifica SP ccsp_ManualCallApplyTimeZoneRules para validar hora y zonas horarias marcada por la ley 
	Se modifica SP ccsp_OUTcheckTimeZone para validar hora y zonas horarias marcada por la ley 
	Se modifica SP ccsp_OUTGetNewJobs para validar hora y zonas horarias marcada por la ley  ccsp_OUTGetNewJobs
	Se modifica SP ccsp_OUTGetNewProviderJobs para validar hora y zonas horarias marcada por la ley 
	Se modifica SP ccsp_AgentGetStartStopPermission
	Se modifica SP ccsp_RIAManageAreas

Database: CCenterRia
Required version: 113

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 114

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

			/* Start script release */
			set @process = 'Alter Table - column '
			set @sql='if exists (select * from sys.columns where name = N''detalle'' and Object_ID = Object_ID(N''ccsettings''))
				alter table ccsettings alter column detalle [varchar](600)'	
			EXEC(@sql)

			set @process = 'Insert settings - 166 and 167'
			set @sql='if exists (select * from sys.tables where name = N''ccsettings'')
				begin
					insert into ccsettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings) 
					values(166,''1|07:00|22:00'',''Marcar sólo en horarios permitidos por ley.'',1,''GRL'',''Configuracion el horario permitido indepentiende del horario de la campaña activo|hh:mm|hh:mm ejemplo(1|07:00|22:00)'',''Dial only during compliance schedules.'',1)
					insert into ccsettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings)
					values(167,'''',''Ubicacion del Downloader services'',1,''X'',''IP del servidor donde se encuentra el Downloader Service, se actualiza automaticamente cuando se abre el email service	Downloader Service'',''location (automatically updated when the Downloader service starts)'',1)
				end'
			EXEC(@sql)	

			set @process = 'Update ccsettings - setting_id 112 y 131'
			set @sql='if exists (select * from sys.tables where name = N''ccsettings'')
				begin
					update ccsettings set detalle =''Se convierte en obligatorio el tener un horario para poder hacer llamadas de salida 0:opcional, 1:obligatorio, tiene mayor prioridad el setting 166'' where setting_id=112
					
					if not exists (select detalle from ccsettings where setting_id = 131 and detalle like ''%Tamaño de memoria reservada para la maquina virtual(MB)%'')
						update ccsettings set valor=valor +''|64'',detalle =detalle +''|Tamaño de memoria reservada para la maquina virtual(MB)'' where setting_id=131
				end'	
			EXEC(@sql)	

			set @process = 'Drop function - AuthorizationCallLaw'
			set @sql='if object_id(''dbo.AuthorizationCallLaw'') is not null 
				drop function dbo.AuthorizationCallLaw'
			EXEC(@sql)	
	
			set @process = 'Create function - AuthorizationCallLaw'
			if not exists (select * from sys.objects where object_id = OBJECT_ID(N'AuthorizationCallLaw') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
				set @sql='CREATE FUNCTION [dbo].[AuthorizationCallLaw](@action int,@iZonas int)
					RETURNS varchar(max) AS  
					BEGIN

					if @iZonas is null set @iZonas = 0

					declare @isShudulerLey tinyint,@hourStart datetime,@hourEnd datetime,@hour datetime
					declare @shourStart varchar(30),@shourEnd varchar(30)
					declare @valor varchar(100),@msgLaw varchar(max)


					select @valor = valor from ccsettings where setting_id=166

					if @valor='''' set @valor=''0|07:00|22:00''	

					select @isShudulerLey = cast(substring(@valor, 0, charindex(''|'',@valor)) as int),@valor=substring(@valor, charindex(''|'',@valor) + 1, len(@valor)) 
					select @shourStart=substring(@valor, 0, charindex(''|'',@valor)),@shourEnd=substring(@valor, charindex(''|'',@valor) + 1, len(@valor))
					select @hourStart=convert(datetime,@shourStart+'':00'',108),@hourEnd=convert(datetime,@shourEnd +'':00'',108)
					if @action = 1 begin

						if @isShudulerLey = 0 return ''1''
						
						
						if @iZonas > 0 begin
							select @hour=dateadd(hh, tz_offset, getutcdate()) from ccTimeZones where tz_id=@iZonas
							set @hour=convert(datetime,convert(varchar,@hour,108))
						end
						else 
							set @hour=convert(datetime,convert(varchar,getdate(),108))
						
						if @hour >= @hourStart and @hour <= @hourEnd return ''1''
						else return ''0''
						
					end
					else if @action = 2 begin
						declare @idioma as bit
						select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

						if @isShudulerLey = 0 begin
							if @idioma = 1 return ''Se podra marcar las 24 horas''
							else return ''Se podra marcar las 24 horas''
						end
						
						if @idioma = 1 set @msgLaw=''Solo se podra marcar en el horario ''+ @shourStart + '' a '' + @shourEnd
						else set @msgLaw=''Solo se podra marcar en el horario ''+ @shourStart + '' a '' + @shourEnd
						
						return @msgLaw
						
							
					end
						return ''0''
					end'	
			else
				set @sql = ''
			EXEC(@sql)	
	
			set @process = 'Alter SP - ccsp_ADMCampHorarios'
			if exists (select * from sys.procedures where name = N'ccsp_ADMCampHorarios')
				set @sql='ALTER PROCEDURE [dbo].[ccsp_ADMCampHorarios]
					@cam_id smallint,
					@horario_id smallint, -- Si Tipo =2, aqui viene el ID de Horario
					@Tipo tinyint -- 1=ALTA, 2=Modificacion, 3=Borrar
					AS
					declare @Descripcion varchar(40)
					declare @idioma as bit
					declare @authorizationCallLaw as bit
					declare @msgLaw varchar(40)

					Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

					select @Descripcion=Upper(Descripcion) from ccHorarios where horario_id=@horario_id
					if @Tipo=1 begin
						if ( select count(*) from ccCampsHorarios where cam_id = @cam_id and horario_id=@horario_id
						) > 0
							if @idioma = 1
							select 0, ''Schedule Already Assigned''
							else
							select 0, ''Horario ya Asignado''
						else
						begin
							select @msgLaw=dbo.AuthorizationCallLaw(2,0)
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
			else
				set @sql = ''
			EXEC(@sql)	

			set @process = 'Alter SP - ccsp_ManualCallApplyTimeZoneRules'
			if exists (select * from sys.procedures where name = N'ccsp_ManualCallApplyTimeZoneRules')
				set @sql='ALTER procedure [dbo].[ccsp_ManualCallApplyTimeZoneRules] @campid as int, @tel varchar(15) as

					set nocount on

					declare @bIsDaylight bit
					declare @revHorario bit
					declare @country_id int
					declare @iZonas int
					declare @sql varchar(MAX)
					declare @izonahoraria int
					declare @izonahoraria_verano int

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

					/*** Se revisa si la campaña tiene horarios configurados ***/
					if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
						begin
							declare @horaUniversal as datetime 
							select @horaUniversal = getutcdate()

							select @iZonas = sum(distinct tz_id)
							from (select tz_id,
								  datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora, 
								  datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
								  datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
								  from ccTimeZones )zonas 
								  inner join cchorarios on((hora > HoraInicio OR(hora = HoraInicio AND minuto >= MinInicio))
								  AND (hora < HoraFin OR(hora = HoraFin AND minuto <= MinFin))
								  AND (Lunes = dia or
									   Martes*2 = dia or
									   Miercoles*3 = dia or
									   Jueves*4 = dia or
									   Viernes*5 = dia or
									   Sabado*6 = dia or
									   domingo*7 = dia)
								 ) 
							inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id = ccCampsHorarios.horario_id 
							and ccCampsHorarios.cam_id = @campid

							if @iZonas is null 
								begin
									SELECT 0 as CanCall,0 as CanCallLaw
									return
								end
						end 
					else
						begin
							if @revHorario = 0
								begin
									select @iZonas = sum(distinct tz_id)from ccTimeZones
								end
							else
								begin
									select @iZonas = Null
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
							select 1 as CanCall , dbo.AuthorizationCallLaw(1,''+ cast(isnull(@izonahoraria,0) as varchar(20)) + '') as CanCallLaw
						end
					else
						begin
							select 0 as CanCall,0 as CanCallLaw
						end

					DROP table #NEW_JOBS''

					exec(@sql)

					DROP table #TimeZone

					set nocount off'	
			else
				set @sql = ''
			EXEC(@sql)	

			set @process = 'Alter SP - ccsp_OUTcheckTimeZone'
			if exists (select * from sys.procedures where name = N'ccsp_OUTcheckTimeZone')
				set @sql='ALTER procedure [dbo].[ccsp_OUTcheckTimeZone]
					@cam_id as int
					AS
					set nocount on
					declare @horaUniversal datetime, @revHorario bit
					select @revHorario=valor from ccsettings where setting_id = 112

					-- Si la campaña no tiene horarios asignados, marcar todas las zonas
					if @revHorario = 0
					begin
						if not exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@cam_id)
						 begin
							select case when dbo.AuthorizationCallLaw(1,0) = 0 then sum(distinct tz_id) else 0 end from ccTimeZones  
							return(0)
						 end
					end

					SET DATEFIRST 1
					set @horaUniversal = getutcdate()
					select case when dbo.AuthorizationCallLaw(1,0) = 0 then isnull(sum( distinct tz_id),0) else 0 end from
					(
						select tz_id,
						dateadd(mi, tz_offset*60, @horaUniversal) as fecha,
						datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal) ) as hora, 
						datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal) ) as minuto,
						datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal) ) as dia
						from ccTimeZones 
					)zonas
					inner join cchorarios on
					(
						( hora > HoraInicio OR 
					( hora = HoraInicio AND minuto >= MinInicio ) )
						AND
						( hora < HoraFin OR ( hora = HoraFin AND minuto <= MinFin ) )
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
					inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id = ccCampsHorarios.horario_id and ccCampsHorarios.cam_id = @cam_id'	
			else
				set @sql = ''
			EXEC(@sql)	

			set @process = 'Alter SP - ccsp_OUTGetNewJobs'
			if exists (select * from sys.procedures where name = N'ccsp_OUTGetNewJobs')
				set @sql='ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
					@CAMPID as int,
					@test as int=0,
					@nAgentsLogin as int=1
					as
					--set nocount on
					declare @total int
					declare @topCount smallint, @bIsDaylight bit, @revHorario bit
					declare @country_id int, @TipoJobs int
					declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
					declare @sql varchar(4000), @Order_Asc_Desc char(4)
					declare @camSurvey int
					select @camSurvey = 0

					select @camSurvey = cam_id
					from cccamps 
					where cam_id = @CAMPID 
					and isnull(callsBySurvey,0) > 0 
					and isnull(ivrScript,0) > 0
					 
					-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
					SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
					select @revHorario=valor from ccsettings where setting_id = 112
					-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
					SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
					SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')
					 
					SET DATEFIRST 1
					--Checamos si es horario de verano
					select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())
					 
					--Checamos si la campaña tiene horarios configurados
					if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
					begin
						   declare @horaUniversal as datetime
						   set @horaUniversal=getutcdate()
					 
						   select @iZonas=sum(distinct tz_id)from
						   (select tz_id,
								 datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora,
								 datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
								 datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
								 from ccTimeZones
						   )zonas inner join cchorarios on
						   ((hora>HoraInicio OR(hora=HoraInicio AND minuto>= MinInicio))
								 AND (hora<HoraFin OR(hora=HoraFin AND minuto<= MinFin))
								 AND (
										Lunes=dia or
										Martes*2=dia or
										Miercoles*3=dia or
										Jueves*4=dia or
										Viernes*5=dia or
										Sabado*6=dia or
										domingo*7=dia
								  )
						   ) inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id=ccCampsHorarios.horario_id and ccCampsHorarios.cam_id=@campid
					 
						   if @iZonas is null begin
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

						   if @revHorario=0
								 select @iZonas=sum(distinct tz_id)from ccTimeZones -- No hay horarios, ponemos todas las zonas
						   else
								 select @iZonas=Null
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
						   (dbo.AuthorizationCallLaw(1,''+@isVerano+'') = 1 and ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0)) or
						   (dbo.AuthorizationCallLaw(1,''+@isVerano+''2) = 1 and ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0)) or
						   (dbo.AuthorizationCallLaw(1,''+@isVerano+''3) = 1 and ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0)) or
						   (dbo.AuthorizationCallLaw(1,''+@isVerano+''4) = 1 and ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0)) or
						   (dbo.AuthorizationCallLaw(1,''+@isVerano+''5) = 1 and ((izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0))
						   )
						   and isnull(R.status,2) = 2
						   order by prioridad_cb desc, cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
									
							select @sql
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
						   (dbo.AuthorizationCallLaw(1,''+@isVerano+'') = 1 and ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0)) or
						   (dbo.AuthorizationCallLaw(1,''+@isVerano+''2) = 1 and ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0)) or
						   (dbo.AuthorizationCallLaw(1,''+@isVerano+''3) = 1 and ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0)) or
						   (dbo.AuthorizationCallLaw(1,''+@isVerano+''4) = 1 and ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0)) or
						   (dbo.AuthorizationCallLaw(1,''+@isVerano+''5) = 1 and ( (izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
						   or izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0))
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
					--print @sql
					exec(@sql)
					return(0)'	
			else
				set @sql = ''
			EXEC(@sql)	

			set @process = 'Alter SP - ccsp_OUTGetNewProviderJobs'
			if exists (select * from sys.procedures where name = N'ccsp_OUTGetNewProviderJobs')
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
					select @camSurvey = 0

					select @camSurvey = cam_id
					from cccamps 
					where cam_id = @CAMPID 
					and isnull(callsBySurvey,0) > 0 
					and isnull(ivrScript,0) > 0

					-- VALIDAMOS EL PAIS Y LADA CONFIGURADA --
					SELECT @country_id =valor FROM ccSettings WHERE setting_id=104
					select @revHorario=valor from ccsettings where setting_id = 112
					-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
					SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
					SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

					SET DATEFIRST 1
					--Checamos si es horario de verano 
					select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

					--Checamos si la campaña tiene horarios configurados
					if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
					 begin
						declare @horaUniversal as datetime 
						set @horaUniversal=getutcdate()

						select @iZonas=sum(distinct tz_id)from 
						(select tz_id,
							datepart(hh, dateadd(mi, tz_offset*60, @horaUniversal))as hora, 
							datepart(mi, dateadd(mi, tz_offset*60, @horaUniversal))as minuto,
							datepart(dw, dateadd(mi, tz_offset*60, @horaUniversal))as dia
							from ccTimeZones 
						)zonas inner join cchorarios on
						((hora>HoraInicio OR(hora=HoraInicio AND minuto>= MinInicio))
							AND (hora<HoraFin OR(hora=HoraFin AND minuto<= MinFin))
							AND (
								Lunes=dia or
								Martes*2=dia or
								Miercoles*3=dia or
								Jueves*4=dia or
								Viernes*5=dia or
								Sabado*6=dia or
								domingo*7=dia
							)
						) inner join ccCampsHorarios with(index(IX_ccCampsHorarios)) on cchorarios.horario_id=ccCampsHorarios.horario_id and ccCampsHorarios.cam_id=@campid

						if @iZonas is null begin
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

						if @revHorario=0
							select @iZonas=sum(distinct tz_id)from ccTimeZones -- No hay horarios, ponemos todas las zonas
						else
							select @iZonas=Null
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
						(dbo.AuthorizationCallLaw(1,''+@isVerano+'') = 1 and ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0)) or
						(dbo.AuthorizationCallLaw(1,''+@isVerano+''2) = 1 and ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0)) or
						(dbo.AuthorizationCallLaw(1,''+@isVerano+''3) = 1 and ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0)) or
						(dbo.AuthorizationCallLaw(1,''+@isVerano+''4) = 1 and ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
						(dbo.AuthorizationCallLaw(1,''+@isVerano+''5) = 1 and ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0))
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
						(dbo.AuthorizationCallLaw(1,''+@isVerano+'') = 1 and ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0)) or
						(dbo.AuthorizationCallLaw(1,''+@isVerano+''2) = 1 and ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0)) or
						(dbo.AuthorizationCallLaw(1,''+@isVerano+''3) = 1 and ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0)) or
						(dbo.AuthorizationCallLaw(1,''+@isVerano+''4) = 1 and ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0)) or
						(dbo.AuthorizationCallLaw(1,''+@isVerano+''5) = 1 and ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0 
						or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0))
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
			else
				set @sql = ''
			EXEC(@sql)	

			set @process = 'Alter Procedure - ccsp_AgentGetStartStopPermission'
			if exists (select * from sys.procedures where name = N'ccsp_AgentGetStartStopPermission')
				set @sql='ALTER PROCEDURE [dbo].[ccsp_AgentGetStartStopPermission]
					@age_id int,
					@cam_id int,
					@call_type int
					AS
					BEGIN
						SET NOCOUNT ON;

						declare @agentRec int, @valor as int
						set @valor = 0
						set @agentRec = (select isnull(startStopRecording,0) from ccusers (nolock) where [User_id] = @age_id)

						IF @agentRec = 1
						BEGIN
							---------- Entra agente con permiso de StartStopRecording
							IF @call_type = 1 ------- Revisamos especialidad
								set @valor = (select isnull(startStopRecording,0) from ccInbound (nolock) where Inbound_id = @cam_id)
							ELSE ------- Revisamos Campaña
								set @valor = (select isnull(startStopRecording,0) from ccCamps (nolock) where cam_id = @cam_id)
						END

						select @valor
					END'
			else
				set @sql = ''
			EXEC(@sql)

			set @process = 'Alter SP - ccsp_RIAManageAreas'
			if exists (select * from sys.procedures where name = N'ccsp_AgentGetStartStopPermission')
				set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAManageAreas]
					@option tinyint,
					@IDArea smallint = 0,
					@InsertUserId smallint =null,
					@DeleteUserId varchar(255)=null,
					@InsertCamId smallint=null,
					@DeleteCamId smallint=null,
					@InsertACDGroupId smallint=null,
					@DeleteACDGroupId smallint=null
					as
					set nocount on

					if @option = 1 -- Insert User Area
					 begin
						if not exists(select IDArea from ccUsers where IDArea = @IDArea AND User_id = @InsertUserId)
						 begin
							Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @InsertUserId
							return(0)
						 end	
						 
						select 1
						return(0)
					 end

					if @option = 3 -- Insert camp area
					 begin
						if not exists(select IDArea from ccCamps where IDArea = @IDArea and cam_id = @InsertCamId)
						 begin
							Update ccCamps set IDArea = case @IDArea when 0 then null else @IDArea end
							where cam_id = @InsertCamId
							return(0)
						 end

						select 1
						return(0)
					 end

					if @option = 4 -- Delete camp area
					 begin
				 		insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId
					 
				 		delete from ccCampsAgente where cam_id = @DeleteCamId
						delete from ccoDialerCamp where cam_id = @DeleteCamId
						delete from ccoWorkingTable where cam_id = @DeleteCamId

						insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1	

						delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
						delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	
						delete from ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @DeleteCamId)

						if exists(select cam_id from ccInbound where cam_id=@DeleteCamId)
						 begin
							select -4
							return(0)	 
						 end

						Update ccCamps set IDArea= null where cam_id=@DeleteCamId--, cam_activo = 0 
						return(0)
					 end

					if @option = 5 -- Insert ACDGroup area
					 begin
						if not exists(select IDArea from ccInbound where IDArea = @IDArea and Inbound_Id = @InsertACDGroupId)
						 begin
							Update ccInbound set IDArea = @IDArea, status = 1 where Inbound_id = @InsertACDGroupId
							return(0)
						 end

						select 1
						return(0)
					 end

					if @option = 6 -- Delete ACDGroup area
					 begin
				 		insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

						delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
						delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId

						insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId and A.tipo = 0

						delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
						delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
						delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

						Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId
						select 1
						return(0)
					 end

					if @option in (2, 9, 10, 11)
					 begin
				 		declare @Type tinyint
						select @Type = TipoUser_id from ccUsers where User_id = @DeleteUserId
						
						if @option in (2, 10, 11) -- Delete User area
						 begin
							if @Type = 1 -- Agente
							 begin

								insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
								insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

								delete from ccCampsAgente where user_id = @DeleteUserId
								delete from ccInboundAgentes where user_id = @DeleteUserId
							 end

							else if @Type in (2, 6) -- Supervisor
							begin
								insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
								delete from ccSupervisorCam where user_id = @DeleteUserId
							end

							delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
							
							if @option=2
							 begin
								update ccPosicion set user_id = 0 where user_id = @DeleteUserId
								update ccUsers set IDArea = null where user_id = @DeleteUserId	
							 end
							return(0)
						end

						declare @UserWG varchar(100)
						-- @option = 9 -- Delete User area and get his workgroups

						select @UserWG = IDWG from ccRIAWorkGroupUsers where user_id = @DeleteUserId

						if @Type = 1 -- Agente
						 begin
					 		insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
							insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

							delete from ccCampsAgente where user_id = @DeleteUserId
							delete from ccInboundAgentes where user_id = @DeleteUserId
						 end

						if @Type in (2, 6) -- Supervisor
						 begin
					 		insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId

					 		delete from ccSupervisorCam where user_id = @DeleteUserId
							delete from ccMenuUser where id_User = @DeleteUserId
						 end

						delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
						update ccPosicion set user_id = 0 where user_id = @DeleteUserId
						
						if @option <> 11
							update ccUsers set IDArea = null where user_id = @DeleteUserId
						
						select @UserWG, @Type
						return(0)
					 end

					declare @AllWG varchar(400), @CurrentWG varchar(400), @AreaDescripcion varchar(40)

					if @option = 7 -- Delete camp area
					 begin
				 		if exists(select cam_id from ccInbound where cam_id=@DeleteCamId)
						begin
							update ccInbound set cam_id = null where cam_id=@DeleteCamId		 
						end

						select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
						from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

						insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId

						delete from ccCampsAgente where cam_id = @DeleteCamId
						delete from ccoWorkingTable where cam_id = @DeleteCamId or callout_id 
						 in (select callout_id from ccoCallsOutSource where cam_id = @DeleteCamId)

						insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1

						delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
						delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	

						select @CurrentWG = coalesce(@CurrentWG + '','', '''') + CAST(IDWG as varchar(400)) 
						from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

						select @AreaDescripcion = area.AreaName
						from ccCamps as camp with(nolock)inner join ccRIACat_Areas as area 
						 with(nolock) on camp.IDArea = area.IDArea
						where camp.cam_id = @DeleteCamId
						Update ccCamps set IDArea = null where cam_id = @DeleteCamId

						If @CurrentWG is null
							set @CurrentWG = 0

						If @AllWG is null
							set @AllWG = 0

						select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
						return(0)
					 end

					if @option = 8 --Delete ACDGroup area
					 begin
						if (select cam_id from ccInbound where Inbound_id = @DeleteACDGroupId) is not null
						begin
							update ccInbound set cam_id = null where Inbound_id = @DeleteACDGroupId
						end

						select @AllWG = coalesce(@AllWG + '','', '''') + CAST(IDWG as varchar(400)) 
						from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

						insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

						delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
						delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId

						insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId 

						delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
						delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
						delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

						select @CurrentWG = coalesce(@CurrentWG + '','', '''') + CAST(IDWG as varchar(400)) 
						from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

						select @AreaDescripcion = area.AreaName
						from ccInbound as ACD with(nolock) inner join ccRIACat_Areas as area 
						 with(nolock) on ACD.IDArea = area.IDArea
						where ACD.Inbound_id = @DeleteACDGroupId
						Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId

						If @CurrentWG is null
							set @CurrentWG = 0

						If @AllWG is null
							set @AllWG = 0

						select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
						return(0)
					 end

					return(0)
					set nocount off'
			else
				set @sql = ''
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

/**************************/
/***** GUIDE AND HELP *****/
/**************************/

/* IMPORTANT: Consider objects manipulation in the sequence exposed in order to get consistency in the script, uncommon objects are prior to common ones in case of exist except replication */

/***** Language Reference *****/
/*
DDL (Data Definition Language)
	* Create
	* Drop
	* Alter

DML (Data Manipulation Language)
	* Select
	* Update
	* Delete
	* Insert

Contraint Object Types
	* C = CHECK constraint
	* D = DEFAULT (constraint or stand-alone)
	* F = FOREIGN KEY constraint
	* PK = PRIMARY KEY constraint
	* R = Rule (old-style, stand-alone)
	* UQ = UNIQUE constraint

Function Object Types
	* FN Scalar function
	* IF Inline table-valued function
	* TF Table-valued-function
	* FS Assembly (CLR) scalar-function
	* FT Assembly (CLR) table-valued function
*/

/***** Most common objects *****/
/* 
TABLES
-- When table exists
if exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

-- When table does not exists
if not exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

COLUMNS
-- When column exists
if exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When column does not exists
if not exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

CONSTRAINTS
-- When constraint exists
if exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not exists
if not exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

INDEXES
-- When index exists
if exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When index does not exists
if not exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

TRIGGERS
-- When trigger exists
if exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When trigger does not exists
if not exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

FUNCTIONS
-- When function exists
if exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

-- When function does not exists
if not exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

STORED PROCEDURES
-- When stored procedure exists
if exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

-- When stored procedure does not exists
if not exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

VIEWS
-- When view exists
if exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

-- When view does not exists
if not exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

JOBS (In this case be careful about what to do)
-- if you want to create, modify or delete use the script below
if exists (select * from msdb.dbo.sysjobs_view where name = N'yourJobName')
	begin
		exec msdb.dbo.sp_delete_job @job_name = N'yourJobName', @delete_unused_schedule=1
	end

-- After that, you could run the script to create the Job despite of being new or being modified
*/

/***** Uncommon objects *****/
/*
DATABASES
-- When database exists
if exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

-- When database does not exists
if not exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

LOGINS
-- When login exists
if exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

-- When login does not exists
if not exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

SERVER ROLES
-- When server role exists
if exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

-- When server role does not exists
if not exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

SCHEMAS
-- When schema exists
if exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

-- When schema does not exists
if not exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

Replication
-- Replication scripts are generated apart so you have to check them and consider the validations implemented on those scripts
	* Publications
	* Subscriptions on publisher
	* Subscriptions
	* Snapshots
*/