/*
Autor: Raymundo Gonzalez
Fecha: 2013/10/31
Descripcion:
	Se crea la tabla ccNPALocalPrefixes para plan de marcacion de USA
	Se agrega la columna cal_key a la tabla ccoLogDials
	Se agrega la columna type la tabla ccMenu_Views
	Se actualiza el campo type de la tabla ccMenu_Views
	Se elimina la llave primaria y foranea de las tablas ccmenus y ccMenu_Views respectivamente
	Se crea la llave primaria y foranea de las tablas ccmenus y ccMenu_Views respectivamente
	Se insertan los settings con id 149 para pla de marcacion de USA, 150 para obtencion de XML con los tips del dia y 151 para verificar sitio ccReports (version anterior de reportes) en la tabla ccSettings
	Se insertan registros en la tabla ccmenus para menus de nuevos reportes por usuario
	Se insertan registros en la tabla ccRIACat_AdminRole para menus de nuevos reportes por usuario
	Se insertan registros en la tabla ccRIARoleMenu para menus de nuevos reportes por usuario
	Se modifica el SP ccsp_DLRSaveDialResult para guardar cal_key de marcacion
	Se modifica el SP ccsp_ExtAppsGetDialInfo para guardar cal_key de marcacion
	Se modifica el SP ccsp_LimpiaUsa para plan de marcacion de USA
	Se modifica el SP ccsp_MenuViews para menus de nuevos reportes por usuario
	Se mofifica el SP ccsp_RIACATMenu para menus de nuevos reportes por usuario
	Se modifica el SP ccsp_RIAMenuRoles para menus de nuevos reportes por usuario
	Se crea el Job ShrinkLogCCenterRia para performance	
	
Version requerida: 100
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '101'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccNPALocalPrefixes - Create Table'
		set @Sql='create table ccNPALocalPrefixes (NPA varchar(5), NXX varchar(5))'
	
	EXEC(@Sql)
	
		set @process = 'ccoLogDials - Alter Table'
		set @Sql = 'ALTER TABLE [dbo].[ccoLogDials] ADD [cal_key] VARCHAR(20) NOT NULL CONSTRAINT DF_ccoLogDials_cal_key DEFAULT '''''
		
	EXEC(@Sql)
	
		set @process = 'ccMenu_Views - Alter Table'
		set @Sql = 'ALTER TABLE ccMenu_Views ADD [type] [tinyint]'
		
	EXEC(@Sql)

		set @process = 'ccMenu_Views - Update'
		set @Sql = 'update menuV 
set menuV.type = menu.type 
from ccMenu_Views menuV 
inner join ccmenus menu on menu.menu_id = menuV.menu_id'
		
	EXEC(@SQl)

		set @process = 'ccmenus and ccMenu_Views - Drop Constraint'
		set @Sql = 'ALTER TABLE ccMenu_Views DROP CONSTRAINT FK_ccMenu_Views_ccMenus
ALTER TABLE ccmenus DROP CONSTRAINT PK_ccMenus'
		
	EXEC(@Sql)

		set @process = 'ccmenus and ccMenu_Views - Add Constraint'
		set @Sql = 'ALTER TABLE ccmenus ADD CONSTRAINT PK_ccMenus PRIMARY KEY (menu_id,[type])
ALTER TABLE ccMenu_Views ADD CONSTRAINT FK_ccMenu_Views_ccMenus FOREIGN KEY (menu_id,[type]) REFERENCES ccmenus(menu_id,[type])'
		
	EXEC(@Sql)

		set @process = 'ccSettings - Insert'
		set @Sql='insert into ccSettings (setting_id, valor, descripcion, Status, Tipo, Detalle, description, bLoadSettings)
values (149,''10|10'',''Plan de marcación (USA)'',1,''GRL'',''Formato: #|#|#|# (HNPA Local|HNPA Toll|FNPA Local|FNPA Toll). Formato 2: #|# (HNPA|FNPA)'',''NPA Dialing Plan (USA)'',0)

insert into ccSettings (setting_id, valor, descripcion, Status, Tipo, Detalle, description, bLoadSettings)
values (150,'''',''URL para obtener el XML de Tips'',1,''GRL'',''URL para obtener el XML de Tips'',''URL to get Tips'',0)

insert into ccsettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings) 
values(151,''0'',''Muestra si esta activo sitio ccReports'',1,''X'',''0 no esta instalado y 1 esta instalado el sitio'',''0 not installed and 1 is installed on site'',1)'
	
	EXEC(@Sql)
	
		set @process = 'ccmenus - Insert'
		set @Sql = 'insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (1000,''Archivo|File'',1000,''A'',1,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (1010,''Supervisor Grupos|Supervisor Groups'',1000,''B'',1,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (2000,''Agentes|Agents'',2000,''A'',2,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (2010,''Información General|General Information'',2000,''B'',2,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (2020,''Sesiones|Sessions'',2000,''B'',2,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (2030,''No Disponible|Unavailable'',2000,''B'',2,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (2040,''Detalle de no disponible|Unavailable Detail'',2000,''B'',2,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (2050,''Reporte KPI Agentes|KPI Agents Report'',2000,''B'',2,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3000,''Especialidades|ACD Groups'',3000,''A'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3010,''Detalle de Llamadas|Call Detail'',3000,''B'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3020,''Llamadas por  Grupo ACD/DID/general/WG/Area|Calls by ACD Group DID general WG Area'',3000,''B'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3030,''No Transferidas por Grupo ACD/general/WG/Area|Not Transferred by ACD Group general WG Area'',3000,''B'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3040,''Calificaciones por Grupo ACD/general/WG/Area|Call Disposition by ACD Group general WG Area'',3000,''B'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3060,''Chats Effectiveness|Effectiveness'',3000,''B'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3070,''Tendencia de flujo|Change flow'',3000,''B'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3080,''Costo 01 900|Billing 01 900'',3000,''B'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3100,''Resumen por DID|Resume per DID'',3000,''B'',3,3,''Error'')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3110,''Llamadas Rechazadas|Rejected Calls'',3000,''B'',3,3,''Error'')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3120,''Sub Calificaciones|Call SubDisposition'',3000,''B'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3130,''Chats|Chats'',3000,''B'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3131,''Chats por ACD|ACD Chats'',3130,''C'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3132,''Chats No Contactados|Chats Not Contacted'',3130,''C'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3133,''Detalle de chats|Chats Detail'',3130,''C'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3134,''Tiempo Promedio de Respuesta|Average Answer Time'',3130,''C'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3135,''Chats Efectividad|Chats Effectiveness'',3130,''C'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (3136,''General Llamadas y Chats|General Calls and Chats'',3130,''C'',3,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4000,''Campaña|CampaignM'',4000,''A'',4,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4010,''Detalle de Marcación|Dialing Detail'',4000,''B'',4,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4020,''Detalle de llamadas Cont.|Answered Calls Detail'',4000,''B'',4,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4030,''Llamadas contestadas por Campaña/general/wg/area|Answered Calls by Campaign general wg area'',4000,''B'',4,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4040,''Calificaciones por campaña/wg/area|Call Disposition campaign wg area'',4000,''B'',4,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4050,''Marcación por Campaña/wg/area|Dialing by Campaign wg area'',4000,''B'',4,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4060,''Costos|Call Billing'',4000,''B'',4,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4070,''Llamadas Contestadas por número de teléfono|Answered Calls per telephone number'',4000,''B'',4,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4090,''Reporte KPI Outbound|KPI Outbound Report'',4000,''B'',4,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4100,''Sub Calificaciones|Call SubDisposition'',4000,''B'',4,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (4110,''Reprogramación|CallBacks'',4000,''B'',4,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (6000,''IVR|IVR'',6000,''A'',6,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (6010,''Detalle de IVR|IVR Detail'',6000,''B'',6,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (6020,''IVR General|IVR General'',6000,''B'',6,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (6030,''Primera opción del menu|First optionselected'',6000,''B'',6,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (6040,''Por Opciones|By Options'',6000,''B'',6,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8000,''General|General'',8000,''A'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8010,''Ocupación de puertos|Trunks busy'',8000,''B'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8020,''Ocupación de puertos outbound|Outbound Trunks busy'',8000,''B'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8030,''Ocupación de puertos inbound|Inbound Trunks busy'',8000,''B'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8040,''Tiempos Especiales|Special Times'',8000,''B'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8050,''AVRS|AVRS'',8050,''A'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8060,''Calidad|Quality'',8050,''B'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8061,''Agente|Agent'',8060,''C'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8062,''Supervisor|Supervisor'',8060,''C'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8063,''Concepto|Section'',8060,''C'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8070,''Detalle|Detail'',8050,''B'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8071,''Detalles Pregunta|Question Detail'',8070,''C'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8072,''Detalles Calificación|Rate Detail'',8070,''C'',8,3,'''')
insert into ccmenus(menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF) values (8080,''Calificación|disposition'',8000,''B'',8,3,'''')'
		
	EXEC(@Sql)

		set @process = 'ccRIACat_AdminRole - Insert'
		set @Sql = 'insert into ccRIACat_AdminRole values (11,''Campañas|Campaigns''       ,2,3)
insert into ccRIACat_AdminRole values (12,''Especialidades|ACD Groups'',3,3)
insert into ccRIACat_AdminRole values (13,''Ambas|Both''               ,1,3)
insert into ccRIACat_AdminRole values (14,''Personalizado|Custom''     ,4,3)'
		
	EXEC(@Sql)
	
		set @process = 'ccRIARoleMenu - Insert'
		set @Sql = 'insert into ccRIARoleMenu (Role_id,id_Menu,type) values(11,4010,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(11,4020,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(11,4030,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(11,4040,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(11,4050,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(11,4060,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(11,4070,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(11,4090,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(11,4100,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(11,4110,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3010,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3020,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3030,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3040,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3060,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3070,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3080,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3100,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3110,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3120,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3131,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3132,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3133,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3134,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3135,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(12,3136,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,4010,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,4020,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,4030,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,4040,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,4050,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,4060,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,4070,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,4090,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,4100,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,4110,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3010,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3020,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3030,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3040,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3060,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3070,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3080,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3100,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3110,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3120,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3131,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3132,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3133,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3134,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3135,3)
insert into ccRIARoleMenu (Role_id,id_Menu,type) values(13,3136,3)'
		
	EXEC(@Sql)

		set @process = 'ccsp_DLRSaveDialResult - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_DLRSaveDialResult]
@callout_id int,
@cam_id smallint,
@tipoResDial_id tinyint,
@Telefono varchar(30),
@Puerto smallint,
@tDialing tinyint=0,
@tBusy smallint=0,
@call_id int = 0,
@answerbit bit = null,
@tAnswerBit smallint = 0,
@canceledNoAgents bit =0,
@disconnectCause varchar(250) = '''',
@cal_key varchar(20) = ''''
AS
set nocount on
declare @tNow as datetime, @RecicleSIC tinyint
declare @logDial_id int
declare @tAnswerBitFinal as datetime

SELECT @RecicleSIC=IsNull(valor, 0) FROM ccSettings WHERE setting_id = 60
select @tNow=getdate()

select @tAnswerBitFinal = dateadd(ss,-@tAnswerBit,@tNow)

if @call_id > 0 and @tipoResDial_id = 1
BEGIN
	INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key)
	select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''0000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key
END
ELSE
BEGIN
	INSERT ccoLogDials (callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy, TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key)
	select @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tDialing, @tNow, @answerbit, @tBusy, ''0000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key
END

select @logDial_id=scope_identity()

if (@RecicleSIC=1)
 begin
	UPDATE ccoWorkingTable SET tipoResDial_id = @tipoResDial_id where callout_id = @callout_id
 end

select @logDial_id

-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
if @call_id > 0 and @tipoResDial_id = 1
begin
	update ccoCallsOut set cal_manual = 2, cal_puerto = @Puerto	where cal_manual =1 and cal_id = @call_id and cal_puerto = 0
	exec ccsp_CstoCalculaCosto @call_id
end

-- inserta informacion para reportes de workgroup
insert ccRIAWorkGroup_logDial_id (IDWG, logDial_id, cam_id, timestamp)
select IDWG, @logDial_id, IdCampEsp, getdate() 
from ccRIACampEspWG where tipo = 1 and IdCampEsp = @cam_id

-- Guarda configuracion de TipoDialingMode
update ccoLogDials set TipoDialingMode = dbo.fn_getDialingMode(@call_id, 0, @logDial_id, @cam_id) where logDial_id=@logDial_id
set nocount off'
		
	EXEC(@Sql)

		set @process = 'ccsp_ExtAppsGetDialInfo - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_ExtAppsGetDialInfo]
@action tinyint = 0,
@logDial_id int = null
As
Begin

	If @action = 1 begin
		select count(*) from ccologdials with(nolock) where logDial_id >= @logDial_id
	end

	if @action = 2 begin
		select top 500 logDial_id, callout_id, isnull(c.cam_descripcion,a.cam_id) as camId, isnull(b.descripcion,''Unknown'') as DialResult, Telefono, fecha, tDialing, tBusy, isnull(cal_id,0) as cal_id, cal_key 
		from ccologdials a with(nolock) 
		inner join ccTipoResultadoDial b 		
		on a.tiporesdial_id = b.tiporesdial_id		
		inner join ccCamps c
		on a.cam_id = c.cam_id		
		where logDial_id >= @logDial_id
	end

End'
		
	EXEC(@Sql)

		set @process = 'ccsp_LimpiaUsa - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_LimpiaUsa]
@tel varchar(20),
@Camp int = 0
as
set nocount on
declare @lon tinyint

select @tel = dbo.limpia(@tel)
select @lon = len(@tel)

if @lon not in (7, 10, 11) and @tel <> ''911''
 begin
	select 1 as res, @tel as tel --Longitud invalida
	return(0)
 end

if @tel = ''911''
 begin
 	select 0 as res, @tel as tel -- ok
 	return(0)
 end

declare @ld varchar(4)
select @ld = valor from ccsettings where setting_id = 17

declare @len tinyint, @plans tinyint, @hl tinyint, @ht tinyint, @fl tinyint, @ft tinyint
declare @plan varchar(15), @tel10 varchar(10)
select @plan = valor from ccSettings where setting_id = 149
select @plans = COUNT(*) from dbo.fn_RIASplitDelimited(@plan,''|'')
if @plans = 4
begin
	select 
	 @hl = case when id = 1 then cast(value as tinyint) else @hl end,
	 @ht = case when id = 2 then cast(value as tinyint) else @ht end,
	 @fl = case when id = 3 then cast(value as tinyint) else @fl end,
	 @ft = case when id = 4 then cast(value as tinyint) else @ft end from dbo.fn_RIASplitDelimited(@plan,''|'')
	 print @hl
end
else if @plans = 2
begin
	select 
	 @hl = case when id = 1 then cast(value as tinyint) else @hl end,
	 @ft = case when id = 2 then cast(value as tinyint) else @ft end from dbo.fn_RIASplitDelimited(@plan,''|'')
	 select @ht = @hl, @fl = @ft
end
select @tel10 = RIGHT(@ld + @tel, 10)
if SUBSTRING(@tel10, 1, LEN(@ld)) = @ld
begin --HNPA
	set @len = @hl
	if @hl <> @ht and (select COUNT(*) from ccNPALocalPrefixes) > 0 and not exists(select * from ccNPALocalPrefixes where NPA+NXX = SUBSTRING(@tel10, 1, 6))
		set @len = @ht
end
else --FNPA
begin
	set @len = @ft
	if @fl <> @ft and (select COUNT(*) from ccNPALocalPrefixes) > 0 and exists(select * from ccNPALocalPrefixes where NPA+NXX = SUBSTRING(@tel10, 1, 6))
		set @len = @fl
end

select @tel = case @len when 7 then SUBSTRING(@tel10, 4, 7) when 10 then @tel10 when 11 then ''1'' + @tel10 end

-- lista negra
if exists(select a2.idtipolista from cclistanegra a1 inner join camplistanegra a2 with(index(IX_Camplistanegra))
on (a1.idtipolista=a2.idtipolista) where status=1 and cam_id=@Camp and telefono = right(@ld + @tel, 10 ))
 begin
	select 4 as res, @tel as tel -- lista negra
	return (0)
 end

-- devolver telefono correcto.
--	select 2 as res, @tel as tel -- Digitos incorrectos
select 0 as res, @tel as tel
set nocount off'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_MenuViews - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_MenuViews]
@superID as int = 0,
@mView_id As smallint = null,
@mode As smallint = null
as
set nocount on
declare @langU as tinyint, @XML as xml
select @langU=valor from ccSettings where setting_id=27

if isnull(@mView_id,0) <= 0
 begin
	SELECT @XML = (
		SELECT * FROM (
			SELECT distinct 1 as TAG, NULL as Parent, [view].menu_id as "view!1!menuId",
				case @langU when 0 then substring(Menu.menu_descrip, 1, charindex(''|'', Menu.menu_descrip)-1)
			   else substring(Menu.menu_descrip, charindex(''|'', Menu.menu_descrip)+1, len(Menu.menu_descrip))
			   end as "view!1!menu_descrip", NULL as "viewMode!2!id", NULL as "viewMode!2!selected"
			FROM ccMenu_Views as [view] 
			join ccMenus as Menu on [view].menu_id = Menu.menu_id and [view].type = Menu.type
			join ccMenuUser Users on [view].menu_id = Users.id_menu and [view].type = Users.type
			where [view].status=1 and id_User = @superID
			UNION ALL
			SELECT distinct 2, 1, [view].menu_id, NULL, viewMode.typeView, case when viewMode.typeView = dbo.fn_viewMode (@superID, [view].menu_id) then 1 else 0 end
			FROM ccMenu_Views as viewMode
			join ccMenu_Views as [view] on viewMode.mView_id = [view].mView_id
			where viewMode.status=1
		) X
		ORDER BY "view!1!menuId", tag
		FOR XML EXPLICIT, TYPE
	)
	select @XML
	--select isnull(cast(@XML as varchar(max)),'''')
	return(0)
 end

declare @mView_idNew smallint, @mView_idDel smallint, @menu_Log varchar(100), @language tinyint
select @language=valor from ccSettings where setting_id = 27
select @mView_idNew=mView_id from ccMenu_Views where menu_id = @mView_id and typeView = @mode

select @menu_Log=case @language when 0 then substring(menu_descrip, 1, charindex(''|'',menu_descrip)-1) 
else substring(menu_descrip, charindex(''|'',menu_descrip)+1, len(menu_descrip)) end
from ccMenus where menu_id=@mView_id

if not exists (select User_id from ccMenu_ViewsUser where User_id=@superID and mView_id=@mView_idNew)
 begin
	select @mView_idDel = a.mView_id FROM ccMenu_Views a join ccMenu_ViewsUser b on a.mView_id = b.mView_id where b.User_id = @superID and a.menu_id = @mView_id
	delete ccMenu_ViewsUser where User_id=@superID and mView_id = @mView_idDel
	insert into ccMenu_ViewsUser select @superID, @mView_idNew
 end

select isnull(@mView_idNew, -1), @menu_Log menu
return(0)

set nocount off'
	
	EXEC(@Sql)

		set @process = 'ccsp_RIACATMenu - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_RIACATMenu]
@id_User varchar(2000),
@id_Menu int,
@Type tinyint,
@ReportRol tinyint = 1,
@CM tinyint = 1,
@AE tinyint = 1
as
set nocount on
Declare @NRS tinyint
Declare @AVRS tinyint
Declare @RelationCampInbNotReady tinyint
Declare @IVRScripting tinyint
Declare @MenusChat tinyint

select @AE = valor from ccsettings where setting_id = 71
select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
select @AVRS = valor from ccSettings where setting_id = 124
select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
select @IVRScripting = valor from ccsettings where setting_id = 125
select @MenusChat = valor from ccsettings where setting_id = 145


if @Type=1
begin
	if @ReportRol = 1
	begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
		and ((menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79)) 
		or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
		or (menu_id in (71,72) and @IVRScripting = 1)
		or (menu_id in (73,74,75,76) and @AVRS = 1)
		or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
		or (menu_id = 79 and @MenusChat > 0))
		order by ordengral asc
		return(0)
		
	end
	else if @ReportRol = 3 begin
		Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) and menu_id not in (select distinct Parent from ccMenus where menu_id >= 2000 and type = 3)
		and (menu_id not in (3131,3132,3133,3134,3135,3136,8061,8062,8063,8071,8072,8080))
		or  (menu_id     in (3131,3132,3133,3134,3135,3136) and @MenusChat > 0 )
		or  (menu_id     in (8061,8062,8063,8071,8072,8080) and @AVRS > 0)
		order by ordengral asc
		return(0)
	end
	
		Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
		where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
		return(0)

	--if @AVRS = 1
	--begin
	--	Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
	--	and ((menu_id not in (41,42,53,71,72,77,78)) or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
	--	or (menu_id = 77 and @RelationCampInbNotReady = 1) or (menu_id = 78 and @RelationCampInbNotReady = 1)
	--	or (menu_id = 71 and @IVRScripting = 1) or (menu_id = 72 and @IVRScripting = 1))
	--	order by ordengral asc
	--	return(0)
	--end
	--else
	--begin
	--	Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
	--	and ((menu_id not in (41,42,53,71,72,73,74,75,76,77,78)) or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
	--	or (menu_id = 77 and @RelationCampInbNotReady = 1) or (menu_id = 78 and @RelationCampInbNotReady = 1)
	--	or (menu_id = 71 and @IVRScripting = 1) or (menu_id = 72 and @IVRScripting = 1))
	--	order by ordengral asc
	--	return(0)
	--end
end

if @Type=2
begin
  delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu and type = @ReportRol
  return(0)
end

if @Type=3
begin
  insert into ccMenuUser(id_User,id_Menu,type) values (@id_User, @id_Menu,@ReportRol)
  return(0)
end

if @Type=4
begin
  declare @lan varchar(3), @page varchar(200)
  select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
  select @lan = case valor when 0 then ''ES'' else ''EN'' end from ccSettings where setting_id = 27
  
  select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
  return(0)
end

set nocount off'
		
	EXEC(@Sql)

		set @process = 'ccsp_RIAMenuRoles - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIAMenuRoles]
@Type tinyint,
@User_id smallint = null,
@Role_id smallint = null,
@InsertMenu_id smallint = null,
@DeleteMenu_id smallint = null,

@firstSup smallint = null,
@reportRol tinyint = 1,
@AVRS tinyint = null,
@CM tinyint = 0,
@AE tinyint = 0
as
set nocount on
select @reportRol = case @reportRol when 0 then 1 else @reportRol end, 
 @role_id = case @role_id when 0 then 1 else @role_id end

select @AE = valor from ccsettings where setting_id = 71

Declare @NRS tinyint
declare @MenusChat tinyint
declare @RelationCampInbNotReady tinyint

select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
--Activa menus relacionados con campañas
select @MenusChat = valor from ccsettings where setting_id = 145


If @Type = 1 -- Carga todos los roles
 begin
      select Role_id, Description from ccRIACat_AdminRole where type = @reportRol order by priority
      return(0)
 end

If @Type = 2 -- Carga los menus de un supervisor
 begin
  Select a.id_User, a.id_Menu, b.menu_descrip, Nivel, ordengral 
  from ccMenuUser a inner join ccMenus b with(index(IX_ccMenus)) on a.id_Menu = b.menu_id and a.type = b.type
  where id_User = @User_id and a.Type = @reportRol and ((a.id_Menu not in (41,42, 53)) or 
  (a.id_Menu = 41 and @CM = 1) or (a.id_Menu = 42 and @AE > 0) or (a.id_Menu = 53 and @NRS = 1))
  order by ordengral asc
  return(0)
 end

If @Type = 3 -- Return the menus of a rol
 begin
  select a.Role_id, b.menu_id, b.menu_descrip, b.Nivel, b.ordengral 
  from ccRIARoleMenu a inner join ccMenus b with(index(IX_ccMenus)) on b.menu_id = a.id_Menu and a.type = b.type
  where a.Role_id = @Role_id and 
  a.type = @reportRol and 
  ((b.menu_id not in (41,42,53)) or (b.menu_id = 41 and @CM = 1) or (b.menu_id = 42 and @ae > 0) or (b.menu_id = 53 and @NRS = 1))
  order by a.Role_id, b.ordengral asc
  return(0)
 end

If @Type = 4 -- Insert 
 begin
	--roles personalisados 1 ADmin, 10 Reports , 14 ReportsRia
	if @Role_id in (1, 10, 14) and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
	 begin
		if @InsertMenu_id <> 0 begin
			Insert into ccMenuUser (id_User, id_Menu, type) values(@User_id, @InsertMenu_id, @reportRol)
		end
		if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40)
					Insert into ccMenuUser (id_User, id_Menu, type)values(@User_id,40,@reportRol)		
		else If @reportRol = 2 and not exists(select id_User from ccMenuUser where id_User = @User_id and (id_Menu between 1000 and 1999))
					Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, menu_id, @reportRol from ccMenus with(index(IX_ccMenus)) where menu_id between 1000 and 1999
		else if @reportRol = 3 begin									
			Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, id_Menu, @reportRol from ccRIARoleMenu  where Role_id = @Role_id 			 			
		end
		
	 end
	

	else if ((@InsertMenu_id = 53 and @NRS = 1) or (@InsertMenu_id <> 53) )
	 begin
		if @InsertMenu_id <> 40
			  delete ccMenuUser where id_User = @User_id and type = @reportRol		
		
		Insert into ccMenuUser (id_User, id_Menu, type)
		select @User_id, id_Menu, @reportRol from ccRIARoleMenu where Role_id = @Role_id and type = @reportRol
		If @reportRol = 1
			  Insert into ccMenuUser (id_User, id_Menu, type) values(@User_id,40,@reportRol)
	 end
	
	
	
	If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
		Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol

	else
		insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
	
	--Solo es necesario en caso admin y reports
	if @reportRol in(1,2) begin 
		--    inserta parent en caso de no haberlo hecho en rol personalizado        
		Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from               
		(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
		where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
		where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)
	end
	return(0)
 end

If @Type = 5 -- delete
 begin
      delete ccMenuUser where id_User = @User_id and id_Menu = @DeleteMenu_id and type = @reportRol
      If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
  Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol

      else
            insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)

      return(0)
 end

If @Type = 6 -- Get userMenus
 begin
      select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
      from ccRIAUserRole a inner join ccMenuUser b on a.user_id = b.id_user
       inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
      where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol and 
      ((b.id_Menu not in (41,42,53)) or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)) 
		and ( b.id_Menu not in(77,78) or (@RelationCampInbNotReady = 1 and b.id_Menu in(77,78)))  
		and ( b.id_Menu not in(79) or (@MenusChat > 0 and b.id_Menu in(79)))  
	  order by ordengral asc
      return(0)
 end

If @Type = 7 -- Get language
 begin
      select valor from ccSettings where setting_id = 27
      return(0)
 end

If @Type = 8 -- Insert the personalized menus of a supervisor
 begin
      insert into ccMenuUser (id_User, id_Menu, type)
      select @User_id, id_Menu, @reportRol from ccMenuUser where id_User = @firstSup and type = @reportRol

      If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
       begin
            Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
            return(0)
       end

      insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
      return(0)
 end

If @Type = 9 -- Delete all supervisor menus 
 begin
      delete ccMenuUser where id_User = @User_id and type = @reportRol
      return(0)
 end

If @Type = 10 -- update all supervisor menus 
 begin
      update ccUsers set tipoUser_id = @AVRS where user_id = @User_id 
      return(0)
 end

If @Type = 11 -- Verify level A menus
 begin
 --   inserta parent en caso de no haberlo hecho en rol personalizado        
      Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from 
      (select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
      where m.menu_id in (1000,2000,3000,4000) and u.id_User = @User_id and u.type = @reportRol
      group by m.parent) parent where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

      return(0)
 end

If @Type = 12
 begin
      declare @lan as tinyint
      select @lan = valor from ccSettings where setting_id = 27
      select menu_descrip from ccMenus with(index(IX_ccMenus)) where menu_id = @Role_id
      return(0)
 end

return(0)
set nocount off'
	
	EXEC(@Sql)

		set @process = 'ShrinkLogCCenterRia - Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [ShrinkLogCCenterRia]    Script Date: 10/23/2013 11:22:32 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 10/23/2013 11:22:33 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''ShrinkLogCCenterRia'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Shrink Log DB CCenterRia'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Call Center Activity Task]    Script Date: 10/23/2013 11:22:33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Call Center Activity Task'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''declare @fecha_ini datetime
declare @fecha_fin datetime

select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))
select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))

IF EXISTS (SELECT uid, max(ext) ext, login, isnull(max(logout),getdate()) logout, 
datediff(s,login,isnull(max(logout),getdate())) loginTime
FROM (SELECT uid, ext, login, ISNULL(logout, 
(SELECT MIN(fecha) FROM ccLogLogin with (nolock, index(IX_ccLogLogin_2))  
WHERE tipomov = 1 AND fecha > det.login AND [user_id] = det.uid AND extension = det.ext)) as logout   
FROM (SELECT ccLogLogin.[user_id] AS [uid], extension AS ext, fecha AS [login], Login.logout   
FROM (SELECT uid, ext, MAX(login) as login, logout
FROM(SELECT Login.[user_id] AS [uid], extension AS ext, fecha AS [login], (SELECT MIN(subLogin.fecha)
FROM ccLogLogin subLogin with (nolock, index(IX_ccLogLogin_2)) WHERE subLogin.tipomov = 0      
AND subLogin.fecha > Login.fecha AND subLogin.[user_id] = Login.[user_id]) AS [logout]      
FROM ccLogLogin Login with (nolock, index(IX_ccLogLogin_2))     
WHERE login.fecha >= dateadd(dd, -5, @fecha_ini) and tipomov = 1     
GROUP BY  Login.[user_id], Login.extension, Login.fecha) LogDetail     
WHERE logout IS not NULL GROUP BY uid, ext, logout) Login    
RIGHT OUTER JOIN ccLogLogin  with (nolock, index(IX_ccLogLogin_2))   
ON (ccLogLogin.[user_id] = Login.uid AND ccLogLogin.fecha = Login.login 
AND ccLogLogin.extension = Login.ext)   WHERE tipomov = 1   and ccLogLogin.fecha 
>= dateadd( dd, -5, @fecha_ini)) Det   ) LoginDetail WHERE logout IS NULL 
and login >= @fecha_ini and login < @fecha_fin 
GROUP BY uid, login)
BEGIN
  RAISERROR(''''''''Agents online.'''', 11, 1);
END
ELSE
BEGIN
	RETURN
END'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Database Integrity Task]    Script Date: 10/23/2013 11:22:33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Database Integrity Task'', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC CHECKDB WITH NO_INFOMSGS'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Checkpoint DB]    Script Date: 10/23/2013 11:22:33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Checkpoint DB'', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''CHECKPOINT'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Log Task]    Script Date: 10/23/2013 11:22:33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Shrink Log Task'', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DBCC SHRINKFILE(''''ccenter_Log'''',1)'', 
		@database_name=N''CCenterRia'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Weekly'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20000101, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:'
	
	EXEC(@Sql)

		set @process = 'addPosicionManual'
		set @Sql='create procedure addPosicionIpManual
@pos varchar(40),
@ip varchar(40)
as
insert into ccMonitorExt values (@ip,1,1)
insert into ccposicion ( computer,ext_id, user_id, status, tipoConexion, ip)
values (@pos, scope_identity(),0,1,0,'''')

update ccsettings set valor =''2'' where setting_id = 71 -- posicion
update ccsettings set valor =''1'' where setting_id = 83  -- extmanual'
		
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
