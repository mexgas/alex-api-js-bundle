/*
Autor: Raymundo Gonzalez
Fecha: 2013/01/31
Descripcion: 	
	Se inserta el setting 124 y 125 para activar o desactivar funcionalidades de AVRS  y de Reminder integradas a CW
	Se insertan los menus 71 y 72 para funcionalidades de IVR y del 73 al 76 para funcionalidades de AVRS ambas integradas a CW
	Se crean las tablas IVRTemplateStruct, IVRTemplateAudio e IVRTemplate para funcionalidades de IVR integradas a CW
	Se crea el SP ccsp_CheckAVRSIntegrated para revisar setting de configuración de AVRS
	Se crea el SP ccsp_IVRADM para funcionalidades de IVR integradas a CW	
	Se actualiza la tabla ccsettings para las traducciones del idioma ingles y correcciones ortograficas
	Se actualiza la tabla ccsettings en su setting_id 100 para inhabilitar setting de vista de agentes conectados y desconectados global
	Se agrega la columna viewAgents a la tabla ccusers para guardar configuracion de agentes conectados o desconectados
	Se corrigen registros de la tabla ccHorarioVerano para UK
	Se insertan registros de la tabla ccHorarioVerano para Chile
	Se crean las tablas ccRIACat_DataGrid y ccDataGridByUser para guardar configuracion de Grids en cuanto a su orden de columnas
	Se creal el indice IX_ccoCallBacks2 para agilizar consultas
	Se inserta registro en la tabla ccRIACat_DataGrid para la ventana de Actividad de Agentes
	Se crea el SP ccsp_RIA_ConfigDataGridColumnsOrder para leer y guardar configuracion de Grids en cuanto a su orden de columnas
	Se modifica el SP ccsp_RIA_ConfigMonitoredCampAndAcd para guardar configuracion de agentes conectados o desconectados segun configuracion
	Se modifica el SP ccsp_RIALoadAgents para ver aganetes conectados o desconectados segun configuracion	
	Se modifica el SP configuraIdiomaCatalogosEnglish por correccion de fix
	Se modifica el SP configuraIdiomaCatalogosEspañol por correccion de fix
	Se modifica el SP ccsp_RIADispMonitor para almacenar calificaciones a monitorear
	Se modifica Job CW Delete old records para depurar tablas utilizadas para generacion de informacion de Amatech (Muñoz)
	Se modifica Job NuxibaMaintenancePlan como actualizacion de plan de mantenimiento
	Se modifica el sp ccsp_DLRgetDialPrefix para manejo correcto de prefijos
	Se modifica el sp ccsp_DLRGetDialInfo para manejo correcto de prefijos
	Se modifica el sp ccsp_DLRgetDialPrefix para manejo correcto de prefijos
	Se insertan los valores necesarios en las tablas ccRIAExternalApplications y ccRIAClassPath, para componentes de integracion
	Se modifica el sp ccsp_IVRAfterXferAge, no debe guardar el cal_twait, ya que siempre es 0

Version requerida: 88
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '89'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

		set @process = 'ccSettings - Insert'
		set @Sql='INSERT INTO [dbo].[ccSettings] ([setting_id], [valor], [descripcion], [Status], [Tipo], [detalle], [description], [bLoadSettings]) 
VALUES(124, ''0'', ''Activa las funcionalidades de AVRS'', 1, ''X'', ''0- Para cuando no queramos las funcionalidades de AVRS 1- Para activar las funcionalidades de AVRS'', ''Enables all the features from AVRS in CW'', 0)
INSERT INTO [dbo].[ccSettings] ([setting_id], [valor], [descripcion], [Status], [Tipo], [detalle], [description], [bLoadSettings]) 
VALUES(125, ''0'', ''Activa las funcionalidades de Reminder'', 1, ''X'', ''0- Para cuando no queramos las funcionalidades de Reminder 1- Para activar las funcionalidades de Reminder'', ''Enables all the features from Reminder in CW'', 0)'
	
	EXEC(@Sql)
	
		set @process = 'ccMenus - Insert'
		set @Sql='insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type) values (71,''IVR|IVR'',60,''B'',84,1)	 
insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,type) values (72,''Guión Agentes|Scripting'',60,''B'',85,1)
INSERT INTO [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES(73, ''Grabadora|Recorder'', 0, ''A         '', 100, 1, '''')
INSERT INTO [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES(74, ''Formatos de calificacion| Quality Formats'', 100, ''B         '', 101, 1, '''')
INSERT INTO [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES(75, ''Perfiles de exportacion| Export Profiles'', 100, ''B         '', 102, 1, '''')
INSERT INTO [dbo].[ccMenus] ([menu_id], [menu_descrip], [parent], [Nivel], [ordengral], [type], [HelpSWF]) VALUES(76, ''Configuraciones AVRS|AVRS Configurations'', 100, ''B         '', 103, 1, '''')'
		
	EXEC(@Sql)

		set @process = 'IVR Tables - Create Table'
		set @Sql='CREATE TABLE [dbo].[IVRTemplateStruct](
	[IdScript] [smallint] NULL,
	[IdBlock] [smallint] NULL,
	[TypeBlock] [tinyint] NULL,
	[LabelBlock] [varchar](80) NULL,
	[VariablesBlock] [varchar](max) NULL,
	[RetCodeBlock] [varchar](max) NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[IVRTemplateAudio](
	[ivrAudioId] [int] IDENTITY(1,1) NOT NULL,
	[audioFile] [varchar](50) NULL,
	[description] [varchar](50) NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[IVRTemplate](
	[IdScript] [smallint] IDENTITY(1,1) NOT NULL,
	[name] [varchar](40) NOT NULL,
	[Dnis] [varchar](400) NOT NULL
) ON [PRIMARY]'
	
	EXEC(@Sql)

		set @process = 'ccsp_CheckAVRSIntegrated - Create Procedure'
		set @Sql='Create PROCEDURE [dbo].[ccsp_CheckAVRSIntegrated] 
AS

Select valor from ccSettings where setting_id = 124'
	
	EXEC(@Sql)
	
		set @process = 'ccsp_IVRADM - Create Procedure'
		set @Sql='CREATE PROCEDURE [dbo].[ccsp_IVRADM]
@option smallint, 
@idScript smallint = NULL, 
@name varchar(40) = NULL,  
@dnis varchar(400) = NULL, 
@blockId smallint = NULL,  
@blockType tinyint = NULL,  
@blockLabel varchar(40) = NULL, 
@variablesStruct varchar (MAX) = NULL, 
@retCodeStruct varchar (MAX) = NULL,
@storeProcedureName varchar (MAX) = NULL,
@storeProcedureParams varchar (MAX) = NULL,
@audioFile varchar(40) = NULL, 
@audioDescription varchar(40) = NULL

AS
-- INTERNAL VARS
DECLARE @newIdTemplate smallint
SET @newIdTemplate = 0
DECLARE @newAudioIdTemplate smallint
SET @newAudioIdTemplate = 0


----------------------
---- CASE OPTIONS


-- DO NOTHING
IF @option = 1
	BEGIN	
		SELECT 1
	END


-- INSERT A NEW TEMPLATE
IF @option = 2 
BEGIN
	IF EXISTS (SELECT * FROM IVRTemplate WHERE name = @name  ) 	
		BEGIN
			SELECT -1 --''The IVR template name is already in use.''
		END
	ELSE
		BEGIN
			INSERT INTO IVRTemplate(name, dnis) VALUES (@name, @dnis)			
			SELECT @newIdTemplate = scope_identity()						
			SELECT @newIdTemplate
		END
END


-- UPDATE AN IVRTEMPLATE
IF @option = 3 
BEGIN
	IF NOT EXISTS (SELECT * FROM IVRTemplate WHERE idScript = @idScript  ) 	
		BEGIN
			SELECT -1 --''The ivr  does not exists''
		END
	ELSE
		BEGIN
			UPDATE IVRTemplate SET name = @name, dnis = @dnis WHERE idScript=@idScript
		END
	SELECT @idScript
END


IF @option = 4 
BEGIN 
    BEGIN TRAN
    BEGIN TRY
           DELETE FROM IVRTemplate WHERE idScript=@idScript 
           DELETE FROM IVRTemplateStruct WHERE idScript = @idScript
           SELECT @idScript
           COMMIT TRAN
    END TRY
    BEGIN CATCH
           select -1  
           ROLLBACK TRAN
    END CATCH
END



-- SELECT ALL IVR TEMPLATES
IF @option = 5
BEGIN
	SELECT idScript, name, dnis FROM IVRTemplate 
END


-- INSERT A NEW BLOCK
IF @option = 6 
BEGIN
	INSERT INTO IVRTemplateStruct (idScript, idBlock, TypeBlock, LabelBlock, VariablesBlock, RetCodeBlock)
	VALUES (@idScript, @blockId, @blockType, ISNULL(@blockLabel, ''''), @variablesStruct, @retCodeStruct)
END

-- SELECT ALL BLOCKS
IF @option = 7
BEGIN
	SELECT idBlock, TypeBlock, LabelBlock, VariablesBlock, RetCodeBlock
	FROM IVRTemplateStruct
	WHERE idScript = @idScript
END


-- DELETE ALL BLOCKS (IVR STRUCT) OF IVR ID PROVIDED
IF @option = 8
BEGIN
	DELETE IVRTemplateStruct WHERE idScript = @idScript
END


--------------------------------
--------------------------------
--- STORE PROCEDURE VERIFICATION

-- CHECK IF EXISTS STORE PROCEDURE
IF @option = 9
BEGIN
	IF OBJECT_ID (@storeProcedureName) is NULL
		BEGIN
			SELECT 0 -- ''There is not even a single object with the provided id''
		END
	ELSE
		BEGIN
			IF OBJECTPROPERTY(OBJECT_ID (@storeProcedureName), ''isProcedure'') = 1
				BEGIN
					SELECT 1 -- ''The supposed store, actually is.''
				END
			ELSE IF OBJECTPROPERTY(OBJECT_ID (@storeProcedureName), ''isExtenerProc'') = 2
				BEGIN
					SELECT 2 -- ''The supposed store is an Extended Procedure''
				END
			ELSE 
				BEGIN
					SELECT 3 -- ''The supposed store, is not a store and is a non-null object; it ''s something else.
				END
		END
END


-- CHECK CURRENT PARAMETERS OF THE STORE PROCEDURE
IF @option = 10
BEGIN
	SELECT SCHEMA_NAME(SCHEMA_ID) AS [Schema], 
			SO.name AS [ObjectName],
			SO.Type_Desc AS [ObjectType (UDF/SP)],
			P.parameter_id AS [ParameterID],
			P.name AS [ParameterName],
			TYPE_NAME(P.user_type_id) AS [ParameterDataType],
			P.max_length AS [ParameterMaxBytes],
			P.is_output AS [IsOutPutParameter],
			P.has_default_value AS [IsRequired],
			P.default_value AS [DefValue]
	FROM sys.objects AS SO
	INNER JOIN sys.parameters AS P 
	ON SO.OBJECT_ID = P.OBJECT_ID
	WHERE SO.OBJECT_ID  = object_id(@storeProcedureName)
	ORDER BY [Schema], SO.name, P.parameter_id
END


-- TRIES THE STORE PROCEDURE WITH ITS PARAMETERS
IF @option = 11
BEGIN
	BEGIN TRAN
	BEGIN TRY
		   EXEC @storeProcedureName @storeProcedureParams
		   SELECT 1 
		   COMMIT TRAN
	END TRY
	BEGIN CATCH
		   SELECT -1 
		   ROLLBACK TRAN
	END CATCH
END


-- SELECT ALL AUDIOS FOR IVR TEMPLATES
IF @option = 12
BEGIN
	SELECT ivrAudioId,audioFile,description FROM IVRTemplateAudio
END

-- DELETE AUDIO FOR IVR TEMPLATES
IF @option = 13
BEGIN
    BEGIN TRAN
    BEGIN TRY
           DELETE FROM IVRTemplateAudio WHERE ivrAudioId = @idScript 
           SELECT @idScript
           COMMIT TRAN
    END TRY
    BEGIN CATCH
           select -1  
           ROLLBACK TRAN
    END CATCH
END



-- INSERT AUDIO FOR IVR TEMPLATES
IF @option = 14
BEGIN
	insert into IVRTemplateAudio values (@audioFile,@audioDescription)
	SELECT @newAudioIdTemplate = scope_identity()							
	SELECT @newAudioIdTemplate
END'
	
	EXEC(@Sql)

		set @process = 'ccSettings - Update(1)'
		set @sql = 'update ccsettings
set [description] = ''Maximum time for transfer (sec)''
where setting_id = 1

update ccsettings
set [description] = ''TTL message''
where setting_id = 2

update ccsettings
set [description] = ''Out of service''
where setting_id = 3

update ccsettings
set [description] = ''ccServer status''
where setting_id = 4

update ccsettings
set [description] = ''ccActivity status''
where setting_id = 5

update ccsettings
set [description] = ''ccOut status''
where setting_id = 6

update ccsettings
set [description] = ''ccServer location''
where setting_id = 7

update ccsettings
set [description] = ''ccActivity location''
where setting_id = 8

update ccsettings
set [description] = ''ccOut location''
where setting_id = 9

update ccsettings
set [description] = ''Send Info to the ccActivity''
where setting_id = 15

update ccsettings
set [description] = ''Last generation date of online reports''
where setting_id = 16

update ccsettings
set [description] = ''Area code related to the received call''
where setting_id = 17

update ccsettings
set [description] = ''Use of predefined messages''
where setting_id = 18

update ccsettings
set [description] = ''Make call blending to Link Channel''
where setting_id = 19

update ccsettings
set [description] = ''Available records last update''
where setting_id = 21

update ccsettings
set [description] = ''Pass information to ccReports database''
where setting_id = 22

update ccsettings
set [description] = ''Last generation date of campaign summary''
where setting_id = 24

update ccsettings
set [description] = ''Outbound abandoment last update''
where setting_id = 25

update ccsettings
set [description] = ''Hang up IP calls when closing agent''
where setting_id = 26

update ccsettings
set [description] = ''Unavailable - Supervisor''
where setting_id = 28

update ccsettings
set [description] = ''Password effective date''
where setting_id = 29

update ccsettings
set [description] = ''Sound while transferring agent call''
where setting_id = 32

update ccsettings
set [description] = ''Update data window in outbound''
where setting_id = 33

update ccsettings
set [description] = ''Allow reschedule to other telephone''
where setting_id = 34

update ccsettings
set [description] = ''Date rank to reschedule calls''
where setting_id = 35

update ccsettings
set [description] = ''Manual transfer to customized number''
where setting_id = 40

update ccsettings
set [description] = ''Database table for manual call''
where setting_id = 41

update ccsettings
set [description] = ''Field 1 (name) for manual call''
where setting_id = 42

update ccsettings
set [description] = ''Field 2 (telephone) for manual call''
where setting_id = 43

update ccsettings
set [description] = ''Agent application path''
where setting_id = 44

update ccsettings
set [description] = ''Flash (swf) file for calls icons''
where setting_id = 45

update ccsettings
set [description] = ''Flash (swf) file for campaign icons''
where setting_id = 46

update ccsettings
set [description] = ''Flash (swf) file for unavailable icons''
where setting_id = 47

update ccsettings
set [description] = ''Flash (swf) file for agent''
where setting_id = 48

update ccsettings
set [description] = ''XML language file''
where setting_id = 49

update ccsettings
set [description] = ''XML failures file''
where setting_id = 50

update ccsettings
set [description] = ''XML warnings file''
where setting_id = 51

update ccsettings
set [description] = ''Flash (swf) file for agent pre-load''
where setting_id = 52

update ccsettings
set [description] = ''Agent internal softphone''
where setting_id = 53

update ccsettings
set [description] = ''Reproduction devices''
where setting_id = 54

update ccsettings
set [description] = ''Recording devices''
where setting_id = 55

update ccsettings
set descripcion = ''Ruta de la aplicación del administrador'', [description] = ''Administrator application path''
where setting_id = 58

update ccsettings
set [description] = ''Time for recycle again''
where setting_id = 59

update ccsettings
set [description] = ''Recycle in SIC mode''
where setting_id = 60

update ccsettings
set [description] = ''Maximum number of work groups by agents''
where setting_id = 63

update ccsettings
set descripcion = ''Número máximo de campañas/grupos ACD por grupo de trabajo'', [description] = ''Maximum number of campaigns/ACD groups by work group''
where setting_id = 64

update ccsettings
set [description] = ''Minimum time for AVRS integration''
where setting_id = 65

update ccsettings
set [description] = ''Engine location''
where setting_id = 66

update ccsettings
set [description] = ''Records load server''
where setting_id = 67

update ccsettings
set [description] = ''Show call monitoring menu''
where setting_id = 68

update ccsettings
set [description] = ''Differentiate men and women''
where setting_id = 70

update ccsettings
set [description] = ''Show positions menu''
where setting_id = 71

update ccsettings
set [description] = ''Use predefined records load server''
where setting_id = 72

update ccsettings
set [description] = ''Use predefined records load server''
where setting_id = 73

update ccsettings
set [description] = ''ASPX file of integration services''
where setting_id = 74

update ccsettings
set [description] = ''Extra condition for records load''
where setting_id = 75

update ccsettings
set [description] = ''Database version''
where setting_id = 77

update ccsettings
set [description] = ''Group dispositions <1% in "others" status''
where setting_id = 78

update ccsettings
set [description] = ''Show button (call summary)''
where setting_id = 79

update ccsettings
set [description] = ''Enable call backs by hour''
where setting_id = 81

update ccsettings
set [description] = ''Show transfer button''
where setting_id = 82

update ccsettings
set [description] = ''Maximum time while talking (seconds)''
where setting_id = 84

update ccsettings
set [description] = ''Maximum time during available status (seconds)''
where setting_id = 85

update ccsettings
set [description] = ''Type of unavailable status (supervisor)''
where setting_id = 87

update ccsettings
set [description] = ''Automatic unavailable status while re-entering the system''
where setting_id = 88

update ccsettings
set [description] = ''Show DNIS for AgentRIA''
where setting_id = 90

update ccsettings
set [description] = ''Show campaign name''
where setting_id = 91

update ccsettings
set descripcion = ''Registro remoto''
where setting_id = 92

update ccsettings
set descripcion = ''Outbound Serv| no. de registros a marcar|0:predefinido'', [description] = ''Outbound Serv|no. of records that are going to be dialed|0:predefined''
where setting_id = 94

update ccsettings
set [description] = ''Delete areas and its dependencies''
where setting_id = 95

update ccsettings
set [description] = ''Maintain manual dialing window visible''
where setting_id = 96

update ccsettings
set [description] = ''Drag previous value into service level''
where setting_id = 97

update ccsettings
set [description] = ''Extended wrap up time (0|1|2)''
where setting_id = 99

update ccsettings
set [description] = ''Show agents into dashboard 0: only connected, 1: all''
where setting_id = 100

update ccsettings
set [description] = ''General dialing prefix''
where setting_id = 101

update ccsettings
set [description] = ''Use prefix 1:predictive, 2:manual, 4:transfer, 8:overflow''
where setting_id = 102

update ccsettings
set [description] = ''Show call control in "other" status''
where setting_id = 103

update ccsettings
set [description] = ''Dial same telephone by day''
where setting_id = 105

update ccsettings
set [description] = ''Show user ID into dashboard''
where setting_id = 107

update ccsettings
set [description] = ''Dialing time during transfer by overflow (seconds)''
where setting_id = 109

update ccsettings
set [description] = ''Allow ADM and AGT''
where setting_id = 110

update ccsettings
set [description] = ''Allow multiple conferences''
where setting_id = 111

update ccsettings
set [description] = ''Only dial if the campaign has a schedule''
where setting_id = 112

update ccsettings
set descripcion = ''Mostrar nuevo admin. Grupo de trabajo predefinido'', [description] = ''Show new administrator. Predefined work group''
where setting_id = 113

update ccsettings
set descripcion = ''Activar o desactivar validación de registros en lista negra'', [description] = ''Enable or disable records validation into do not call list''
where setting_id = 114

update ccsettings
set [description] = ''Force field name during manual calls''
where setting_id = 115

update ccsettings
set descripcion = ''Depuracion por inactividad'', detalle = ''Indica los días hacia atrás para iniciar depuración'', [description] = ''Inactivity by purification''
where setting_id = 116

update ccsettings
set descripcion = ''Enviar a IVR y mantener llamada'', [description] = ''Send to IVR and maintain call''
where setting_id = 117

update ccsettings
set valor = ''0,acc,pwd,login'', descripcion = ''Estado y cuenta de acceso a DNCScrub.com'', [description] = ''DNCScrub.com status and account''
where setting_id = 118

update ccsettings
set [description] = ''Agent dialer''
where setting_id = 119

update ccsettings
set [description] = ''Enable two calls for agents''
where setting_id = 120

update ccsettings
set [description] = ''URL for AgentWS events''
where setting_id = 121

update ccsettings
set [description] = ''URL for AgentWS failures''
where setting_id = 122

update ccsettings
set [description] = ''Enable or disable changes warning into work groups''
where setting_id = 123'

	EXEC(@sql)

		set @process = 'ccSettings - Update(2)'
		set @Sql='update ccsettings
set status = ''0'', tipo = ''X''
where setting_id = 100'
			
	EXEC(@Sql)
	
		set @process = 'ccusers - Alter Table'
		set @Sql='alter table ccusers
add viewAgents int null default 1'
			
	EXEC(@Sql)

		set @process = 'ccHorarioVerano - Delete and Insert Table'
		set @Sql='delete ccHorarioVerano
where country_id = 7

insert into ccHorarioVerano(country_id, inicio, fin) values(7,''2012/03/25 01:00:00.000'', ''2012/10/28 02:00:00.000'') 
insert into ccHorarioVerano(country_id, inicio, fin) values(7,''2013/03/31 01:00:00.000'', ''2013/10/27 02:00:00.000'') 
insert into ccHorarioVerano(country_id, inicio, fin) values(7,''2014/03/30 01:00:00.000'', ''2014/10/26 02:00:00.000'') 
insert into ccHorarioVerano(country_id, inicio, fin) values(7,''2015/03/29 01:00:00.000'', ''2015/10/25 02:00:00.000'') 
insert into ccHorarioVerano(country_id, inicio, fin) values(7,''2016/03/27 01:00:00.000'', ''2016/10/30 02:00:00.000'') 
insert into ccHorarioVerano(country_id, inicio, fin) values(7,''2017/03/26 01:00:00.000'', ''2017/10/29 02:00:00.000'') 
insert into ccHorarioVerano(country_id, inicio, fin) values(7,''2018/03/25 01:00:00.000'', ''2018/10/28 02:00:00.000'') 
insert into ccHorarioVerano(country_id, inicio, fin) values(7,''2019/03/31 01:00:00.000'', ''2019/10/27 02:00:00.000'')'
		
	EXEC(@Sql)
	
		set @process = 'ccHorarioVerano - Insert Table'
		set @Sql = 'insert into ccHorarioVerano values(''Oct  10 2010  2:00AM'',''Mar  13 2011  2:00AM'',5)
insert into ccHorarioVerano values(''Oct  9 2011  2:00AM'',''Mar  11 2012  2:00AM'',5)
insert into ccHorarioVerano values(''Oct  14 2012  2:00AM'',''Mar  10 2013  2:00AM'',5)
insert into ccHorarioVerano values(''Oct  13 2013  2:00AM'',''Mar  9 2014  2:00AM'',5)
insert into ccHorarioVerano values(''Oct  12 2014  2:00AM'',''Mar  8 2015  2:00AM'',5)
insert into ccHorarioVerano values(''Oct  11 2015  2:00AM'',''Mar  13 2016  2:00AM'',5)
insert into ccHorarioVerano values(''Oct  9 2016  2:00AM'',''Mar  12 2017  2:00AM'',5)
insert into ccHorarioVerano values(''Oct  8 2017  2:00AM'',''Mar  11 2018  2:00AM'',5)
insert into ccHorarioVerano values(''Oct  14 2018  2:00AM'',''Mar  10 2019  2:00AM'',5)
insert into ccHorarioVerano values(''Oct  13 2019  2:00AM'',''Mar  8 2020  2:00AM'',5)
insert into ccHorarioVerano values(''Oct  11 2020  2:00AM'',''Mar  14 2021  2:00AM'',5)'
		
	EXEC(@Sql)

		set @process = 'DataGrid Tables - Create Table'
		set @Sql='create table ccRIACat_DataGrid(
idGrid int not null,
gridName varchar(100) not null,
[columns] varchar(max) not null
)

create table ccDataGridByUser(
[user_id] int not null,
idGrid int not null,
columnsOrder varchar(255) not null
)'
		
	EXEC(@Sql)
	
		set @process = 'ccRIACat_DataGrid - Insert'
		set @sql='insert into ccRIACat_DataGrid
values (1,''AgentDashboard|AgentActivity'',''Estado|Tiempo|Usuario|TotalDeLlamadas|LlamadasDeACD|LlamadasDeCampaña|LlamadasNoContestadasIN|LlamadasNoContestadasOUT|LlamadasManules|LlamadasAutomaticas|TiempoDeSesion|TiempoOcupado|TiempoDisponible|TiempoNoDisponible|Calificacion1Cantidad|Calificacion1FactorConversion|Calificacion2Cantidad|Calificacion2FactorConversion|Calificacion3Cantidad|Calificacion3FactorConversion'')'

	EXEC(@Sql)

		set @process = 'IX_ccoCallBacks2 - Create Index'
		set @Sql='CREATE NONCLUSTERED INDEX [IX_ccoCallBacks2] ON [dbo].[ccoCallBacks] 
(
	[schedulerStatus] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIA_ConfigDataGridColumnsOrder - Create Procedure'
		set @sql = 'CREATE procedure [dbo].[ccsp_RIA_ConfigDataGridColumnsOrder]
@option int,
@user_id int,
@idGrid int,
@columnsOrder varchar(1000)
as
set nocount on

if @option = 1
	begin
		select columnsOrder
		from ccDataGridByUser
		where user_id = @user_id 
		and idGrid = @idGrid
	end

if @option = 2
	begin
		if exists (select * from ccDataGridByUser where user_id = @user_id and idGrid = @idGrid)
			begin
				update ccDataGridByUser
				set columnsOrder = @columnsOrder
				where user_id = @user_id
				and idGrid = @idGrid
			end
		else
			insert into ccDataGridByUser
			values (@user_id,@idGrid,@columnsOrder)
	end

set nocount off'
		
	EXEC(@sql)

		set @process = 'ccsp_RIA_ConfigMonitoredCampAndAcd - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIA_ConfigMonitoredCampAndAcd]
@option smallint,
@user_id smallint,
@cam_id varchar(1000),
@inbound_id varchar(1000),
@viewAgents int
as
set nocount on

if @option = 1
	begin
		if @cam_id <> ''''
			begin
				update ccSupervisorCam
				set monitored = 1
				where user_id = @user_id
				and tipo = 1

				update ccSupervisorCam
				set monitored = 0
				where cam_id not in (select value from fn_RIASplitDelimited(@cam_id,'',''))
				and tipo = 1
				and user_id = @user_id
			end
		else
			begin
				update ccSupervisorCam
				set monitored = 0
				where user_id = @user_id
				and tipo = 1
			end

		if @inbound_id <> ''''
			begin
				update ccSupervisorCam
				set monitored = 1
				where user_id = @user_id
				and tipo = 0
				
				update ccSupervisorCam
				set monitored = 0
				where cam_id not in (select value from fn_RIASplitDelimited(@inbound_id,'',''))
				and tipo = 0
				and user_id = @user_id
			end
		else
			begin
				update ccSupervisorCam
				set monitored = 0
				where user_id = @user_id
				and tipo = 0
			end
	
	end

if @option = 2
	begin
		update ccusers
		set viewAgents = @viewAgents
		where user_id = @user_id
	end

set nocount off'
		
	EXEC(@Sql)
	
		set @process = 'ccsp_RIALoadAgents - Alter Procedure'
		set @Sql='ALTER procedure [dbo].[ccsp_RIALoadAgents]
@option smallint,
@AreaId smallint,
@Sup smallint,
@UserType smallint,
@IDWG smallint = null,
@IDCampACD varchar(max) = null
AS
set nocount on
if @option in(1,7) --1:Todos los agentes/supervisores | 7:UN solo agente/supervisor
 begin
	SELECT User_id, Login, TipoLlamadas, Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea,0) IDArea, Sexo
	From ccUsers with(readpast)
	Where TipoUser_id&2 = case @UserType when 1 then 0 else 2 end And Status > 0 and user_id = case @option when 7 then isnull(@sup,user_id) else user_id end
	ORDER by IDArea, Nombres, ApellidoPaterno, User_id
	return(0)
 end

if @option=2 --Agentes/supervisores de un Area
 begin
	SELECT User_id, Login, TipoLlamadas, Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea,0) IDArea, Sexo
	from ccusers
	Where isnull(IDArea,0) = isnull(@AreaId,0) And TipoUser_id&2 = case @UserType when 1 then 0 else 2 end
	 And status = 1 -- case isnull(@AreaId,0) when 0 then 0 else 1 end
	 ORDER by Sexo, Nombres, ApellidoPaterno, User_id
	return(0)
 end

if @option=3 --Agentes por Supervisor
 begin
	select a3.user_id, a3.Login, a3.TipoLlamadas, a3.Nombres + isnull('' ''+ a3.ApellidoPaterno,'''') + isnull('' '' + a3.ApellidoMaterno, '''') name,
	 isnull(a3.IDArea,0) IDArea, a3.Sexo
	from ccsupervisorcam a1 join cccampsagente a2 on a1.cam_id=a2.cam_id join ccusers a3 on a2.user_id=a3.user_id
	where a1.tipo=''1'' and a1.user_id=@Sup and a3.TipoUser_id = 1 and a3.status>0
	union
	select a3.user_id, a3.Login, a3.TipoLlamadas, a3.Nombres + isnull('' ''+ a3.ApellidoPaterno,'''') + isnull('' '' + a3.ApellidoMaterno, '''') name,
	 isnull(a3.IDArea,0) IDArea, a3.Sexo
	from ccsupervisorcam a1 join ccInboundagentes a2 on a1.cam_id=a2.Inbound_id join ccusers a3 on a2.user_id=a3.user_id
	where a1.tipo=''0'' and a1.user_id=@Sup and a3.TipoUser_id = 1 and a3.status>0
	Order by 5,4,1
	return(0)
 end

If @option=4 --Load All Supervisors
 begin
	SELECT User_id, Login, Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name
	from ccUsers where TipoUser_id in(2,6) and Status>0
	return(0)
 end

if @option=5 --Agentes por Supervisor de sus WG
 begin
	select distinct a1.user_id, a1.Login, a1.TipoLlamadas, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name,
	 isnull(a1.IDArea,0) IDArea, Sexo, isnull(IP, ''0.0.0.0'') IP
	from ccusers a1	join ccRIAWorkGroupUsers a2 on a1.user_id=a2.user_id left join ccPosicion a3 on a1.user_id=a3.user_id
	join ccRIACampEspWG a4 on a2.idwg = a4.idwg
	where a1.tipouser_id=1 and a2.IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id=@Sup)
	return(0)
 end

if @option=6 --Agentes por Supervisor de sus WG
 begin
	select distinct a1.user_id, a1.Login, a1.TipoLlamadas, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	from ccusers a1 join ccRIAWorkGroupUsers a2 on a1.user_id=a2.user_id
	where tipouser_id in(2,6) and IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id=@Sup)
	return(0)
 end

If @option in(8,9) --8:Agentes de un WG | 9:Supervisores de un WG
 begin
	declare @wgUsers as varchar(500)
	select @wgUsers = coalesce(@wgUsers + '','', '''') + CAST(A.user_id as varchar(40))
	FROM ccRIAWorkGroupUsers A join ccUsers B on A.user_id = B.user_id where IDWG=@IDWG 
	 -- and TipoUser_id&2 = case @option when 8 then 0 else 2 end -- Si se quiere tomar en cuenta tipo 2 y 6 como admin en vez de solo tipo 2
	 and TipoUser_id = case @option when 8 then 1 else 2 end 
	select @wgUsers wgUsers
	return(0)
 end

if @option=10 --Todos los agentes/supervisores
 begin
	SELECT User_id, Login, Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea,0) IDArea, Sexo 
	From ccUsers with(readpast)
	Where TipoUser_id in(/*2,*/6) And Status > 0
	ORDER by login, IDArea, Nombres, ApellidoPaterno, User_id
	return(0)
 end

if @option=11 -- Agentes por ACD
 begin
	select distinct a1.user_id, a1.Login, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name, a1.Sexo, a2.prioridad
	from ccusers a1	join ccInboundAgentes a2 on a1.user_id=a2.user_id 
	where a1.tipouser_id=1 and a2.Inbound_id in (select value from dbo.fn_RIASplitDelimited(@IDCampACD,'',''))
	return(0)
 end

if @option=12 -- Agentes por Camp
 begin
	select distinct a1.user_id, a1.Login, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name, a1.Sexo, a2.prioridad
	from ccusers a1	join ccCampsAgente a2 on a1.user_id=a2.user_id 
	where a1.tipouser_id=1 and a2.cam_id in (select value from dbo.fn_RIASplitDelimited(@IDCampACD,'',''))
	return(0)
 end

if @option=13 -- Sups por ACD
 begin
	select distinct a1.user_id, a1.Login, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	from ccusers a1	join ccSupervisorCam a2 on a1.user_id = a2.user_id
	where a1.tipouser_id&2=2 and tipo = 0 and a2.cam_id in (select value from dbo.fn_RIASplitDelimited(@IDCampACD,'',''))
	return(0)
 end

if @option=14 -- Sups por Camp
 begin
	select distinct a1.user_id, a1.Login, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	from ccusers a1	join ccSupervisorCam a2 on a1.user_id = a2.user_id
	where a1.tipouser_id&2=2 and tipo = 1 and a2.cam_id in (select value from dbo.fn_RIASplitDelimited(@IDCampACD,'',''))
	return(0)
 end

declare @sxML as varchar(max), @xml as xml, @action as int
 	
if @option=15 -- Info Agentes
 begin
	set @action=@option-9
	set @xml = cast(''<?xml version="1.0"?> <AgentData/>'' as xml)
	
	select @sxML = cast((select * from (select 1 as tag, null as parent, 
	User_id "Agent!1!id", login "Agent!1!login", Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') "Agent!1!name", 
	Sexo "Agent!1!gender", isnull(IDArea,0) "Agent!1!areaID"
	From ccUsers with(readpast) Where TipoUser_id=1 And Status>0 and user_id=@sup 
	) as x order by tag, "Agent!1!areaID", "Agent!1!name", "Agent!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<AgentData/>'')

	set @xml.modify(''insert element Workgroups {""} as last into (/AgentData/Agent)[1]'')
	select @sxML = cast((select * from (select 1 as tag, null as parent, 
	W.IDWG "Workgroup!1!id", W.WGName "Workgroup!1!description"
	from ccRIACat_WorkGroup W join ccRIAWorkGroupUsers U on W.IDWG = U.IDWG 
	where user_id = @sup
	) as x order by tag, "Workgroup!1!description" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<Workgroups/>'')

	set @xml.modify(''insert element Campaigns {""} as last into (/AgentData/Agent)[1]'')
	select @sxML = cast((select * from (select distinct 1 as tag, null as parent, 
	a1.cam_id "Campaign!1!id", a1.cam_descripcion "Campaign!1!description", a3.frame "Campaign!1!frame", a1.cam_procesando "Campaign!1!processing"
	from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccCampsAgente a4 on a1.cam_id = a4.cam_id
	where a3.type_id = 1 and a4.user_id = @Sup 
	) as x order by tag, "Campaign!1!processing", "Campaign!1!description", "Campaign!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<Campaigns/>'')

	set @xml.modify(''insert element ACDs {""} as last into (/AgentData/Agent)[1]'')
	select @sxML = cast((select * from (select distinct 1 as tag, null as parent, 
	a1.inbound_id "ACD!1!id", descripcion "ACD!1!description", frame "ACD!1!frame"
	from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccInboundAgentes a4 on a1.Inbound_id = a4.Inbound_id
	where a3.type_id = 1 and a4.user_id = @Sup
	) as x order by tag, "ACD!1!description", "ACD!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<ACDs/>'')
	
	set @xml.modify(''insert element action {""} as last into (/AgentData)[1]'')
	set @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/AgentData/action)[1]'')
	select @xML
	return(0)
 end

if @option=16 -- Info Sups
 begin
 
 	set @action=@option-9
	set @xml = cast(''<?xml version="1.0"?> <SuperData/>'' as xml)
	
	select @sxML = cast((select * from (select 1 as tag, null as parent, 
	User_id "Super!1!id", login "Super!1!login", Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') "Super!1!name", 
	Sexo "Super!1!gender", isnull(IDArea,0) "Super!1!areaID"
	From ccUsers with(readpast) Where TipoUser_id&2=2 And Status>0 and user_id=@sup 
	) as x order by tag, "Super!1!areaID", "Super!1!name", "Super!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<SuperData/>'')

	set @xml.modify(''insert element Workgroups {""} as last into (/SuperData/Super)[1]'')
	select @sxML = cast((select * from (select 1 as tag, null as parent, 
	W.IDWG "Workgroup!1!id", W.WGName "Workgroup!1!description"
	from ccRIACat_WorkGroup W join ccRIAWorkGroupUsers U on W.IDWG = U.IDWG 
	where user_id = @sup
	) as x order by tag, "Workgroup!1!description" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<Workgroups/>'')

	set @xml.modify(''insert element Campaigns {""} as last into (/SuperData/Super)[1]'')
	select @sxML = cast((select * from (select distinct 1 as tag, null as parent, 
	a1.cam_id "Campaign!1!id", a1.cam_descripcion "Campaign!1!description", a3.frame "Campaign!1!frame", a1.cam_procesando "Campaign!1!processing"
	from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccSupervisorCam a4 on a1.cam_id = a4.cam_id
	where a3.type_id=1 and a4.user_id = @Sup and a4.tipo=1
	) as x order by tag, "Campaign!1!processing", "Campaign!1!description", "Campaign!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<Campaigns/>'')

	set @xml.modify(''insert element ACDs {""} as last into (/SuperData/Super)[1]'')
	select @sxML = cast((select * from (select distinct 1 as tag, null as parent, 
	a1.inbound_id "ACD!1!id", descripcion "ACD!1!description", frame "ACD!1!frame"
	from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccSupervisorCam a4 on a1.inbound_id = a4.cam_id
	where a3.type_id=1 and a4.user_id = @Sup and a4.tipo=0
	) as x order by tag, "ACD!1!description", "ACD!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<ACDs/>'')
	
	set @xml.modify(''insert element action {""} as last into (/SuperData)[1]'')
	set @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/SuperData/action)[1]'')
	select @xML
	return(0)
 end

if @option=17 -- Load all agents
begin
	select distinct user_id, Login, TipoLlamadas, 
		Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name,
		isnull(IDArea,0) IDArea, Sexo, ''0.0.0.0'' IP, 0 as flagMine
	into #allAgents 
	from ccusers 
	where tipouser_id = 1

	select distinct a1.user_id, a1.Login, a1.TipoLlamadas, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name,
	 isnull(a1.IDArea,0) IDArea, Sexo, isnull(IP, ''0.0.0.0'') IP
	into #myAgents
	from ccusers a1	join ccRIAWorkGroupUsers a2 on a1.user_id=a2.user_id left join ccPosicion a3 on a1.user_id=a3.user_id
	join ccRIACampEspWG a4 on a2.idwg = a4.idwg
	where a1.tipouser_id=1 and a2.IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id=@Sup)

	update #allAgents
	set flagMine = 1
	from #allAgents a, #myAgents b
	where a.user_id = b.user_id

	select *
	from #allAgents
	return(0)
end

if @option = 18 -- View Agents
begin
	select isnull(viewAgents,0) as viewAgents
	from ccusers 
	where tipouser_id = 2
	and user_id = @Sup
	return(0)
end

set nocount off'
		
	EXEC(@Sql)

		set @process = 'configuraIdiomaCatalogosEnglish - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
AS
Print ''Iniciando proceso de configuracion en Ingles''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Week'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Night'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Saturday'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sunday'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady] 
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Not Clasified'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Break'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Bathroom'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''With client'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Clarification'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Meeting'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Lunch'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Systems'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Other'')

--EXEC sp_generate_inserts ''ccRIANotReadyGraph''
DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
TRUNCATE TABLE [dbo].[ccStatusLLamada]
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Initial'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Out of Schedule'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Out of Service'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''No Agents Logged in'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''On Hold'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandoned'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Time overflow'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Queue size overflow'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''With Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, ''Assigned Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, ''Assigned'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, ''Attended Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, ''Answered'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, ''Canceled Message'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, ''Assigned and Not Answered'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, ''Assigned and took line'')
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''Monday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''Tuesday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''Wednesday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''Thursday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''Friday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''Saturday'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''Sunday'')

Print ''Estableciendo resultados de marcacion''
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Answer'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Busy'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Not Answer'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax/Modem'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Other'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, ''NoService'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, ''VoiceMail/Machine'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, ''Circuit busy'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, ''Cancelled'')

Print ''Estableciendo los tipos de estado de los agentes''
DELETE [dbo].[ccTipoStatusAgente]
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Unknown'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Ready'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Talking'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transfer'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Other'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Client'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Ringing'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, ''Problem'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, ''Wait for manual call'')

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agent'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''AVRS Access'')

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [dbo].[ccDias] ON
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (1, ''Sunday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (2, ''Monday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (3, ''Tuesday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (4, ''Wednesday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (5, ''Thursday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (6, ''Friday'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (7, ''Saturday'')
SET IDENTITY_INSERT [dbo].[ccDias] OFF

truncate table cstoTarifa

Print ''Estableciendo los tipos de llamada''
delete cstoTipoLlamada
declare @country_id tinyint
select @country_id = valor from ccsettings where setting_id = 104
insert into cstoTipoLlamada values (@country_id,1,''Standard call'', 8, ''%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] ON
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Added to black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Blocked on loading'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removed from campaign'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Replaced from black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Deleted from black list'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Added by Disposition'')
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Ask for general information'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Call hung'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong Number'', 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Effective call'', 0, 0, 1)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Leave a message'', 0, 1, 2)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong Number'', 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes an individual message to agent'' where TipoMsgChat=1
Update ccRIAChat_TipoMsg set MsgDetalle=''Agent writes a message to Administrator'' where TipoMsgChat=2
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes a global message'' where TipoMsgChat=3

Print ''Mensajes defualt''
DELETE [dbo].[ccMsgFiles]
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Welcome message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Transfer message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Out of service message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''After hours message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''In queue message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''No agents signed in message'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''VoiceMail message'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Overflow message'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''DNC list'')'
		
	EXEC(@Sql)
	
		set @process = 'configuraIdiomaCatalogosEspañol - Alter Procedure'
		set @Sql = 'ALTER procEDURE [dbo].[configuraIdiomaCatalogosEspañol]
AS
Print ''Iniciando proceso de configuracion en Español''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Semana'' collate SQL_Latin1_General_CP1_CI_AS), 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Nocturno'' collate SQL_Latin1_General_CP1_CI_AS), 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady] 
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''No Clasificado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Break'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Tocador'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Con Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Aclaracion'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Junta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Comida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Sistemas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))

DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
TRUNCATE TABLE [dbo].[ccStatusLLamada]
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, convert(text, N''Inicial'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, convert(text, N''Fuera de Horario'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, convert(text, N''Fuera de Servicio'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, convert(text, N''Sin Agentes Firmados'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, convert(text, N''En espera'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, convert(text, N''Colgada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, convert(text, N''Desborde por Tiempo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, convert(text, N''Desborde por Cantidad'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, convert(text, N''Con Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, convert(text, N''Asignada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, convert(text, N''Asignada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, convert(text, N''Atendida Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, convert(text, N''Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, convert(text, N''Cancelada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, convert(text, N''Asignada y No Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, convert(text, N''Asignada y Toma Linea'' collate SQL_Latin1_General_CP1_CI_AS))
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo resultados de marcacion''
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, convert(text, N''Contestan'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, convert(text, N''Ocupado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, convert(text, N''No Contesta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, convert(text, N''Fax/Modem'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, convert(text, N''NoDialTone'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, convert(text, N''NoService'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, convert(text, N''Buzon/Maquina'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, convert(text, N''Congestion'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de estado de los agentes''
Delete [dbo].[ccTipoStatusAgente]
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, convert(text, N''LogOut'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, convert(text, N''Desconocido'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, convert(text, N''No Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, convert(text, N''Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, convert(text, N''Dialogo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, convert(text, N''Transferencia'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, convert(text, N''Notas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, convert(text, N''Otra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, convert(text, N''Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, convert(text, N''Ringing'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, convert(text, N''Problema'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, convert(text, N''Espera llamada manual'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, convert(text, N''Agente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, convert(text, N''AVRS Calidad'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccDias] OFF

Print ''Estableciendo los tipos de llamada''
truncate table cstoTarifa
delete cstoTipoLlamada
declare @country_id tinyint
select @country_id = valor from ccsettings where setting_id = 104

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,1,''Local'',8,''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,2,''LD nacional'',12,''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,3,''Cel'',13,''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,4,''Cel LD'',13,''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,5,''01800'',12,''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,6,''LD usa'',13,''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(@country_id,7,''LD inter'',0,''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, convert(text, N''Lista Negra en Carga de Registros'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, convert(text, N''Eliminado por Aplicar Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, convert(text, N''Eliminado de Lista Negra por Remplazo '' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, convert(text, N''Borrado de Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, convert(text, N''Solicita Informacion General'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, convert(text, N''Se Corto la Llamada'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, convert(text, N''Numero Equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, convert(text, N''Gestión Efectiva'' collate SQL_Latin1_General_CP1_CI_AS), 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, convert(text, N''Se deja recado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, convert(text, N''Numero Equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telmex'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Maxcom'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Avantel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''AT&T'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telnor'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Axtel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telular'')'
			
	EXEC(@Sql)

		set @process = 'ccsp_RIADispMonitor - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_RIADispMonitor]
@action tinyint = 0,
@userId smallint = 0,
@dispositionsIn varchar(40) = '''',
@dispositionsOUT varchar(40) = ''''
as
begin
	if @action = 1 begin			
		delete from ccRIADispMonitorRel where userId = @userId

		if @dispositionsIn <> '''' and left(@dispositionsIn,1) <> '','' begin
			insert into ccRIADispMonitorRel select @userId,value,0 from dbo.fn_RIASplitDelimited( @dispositionsIn ,'','')
		end

		if @dispositionsOUT <> '''' and left(@dispositionsOUT,1) <> '','' begin
			insert into ccRIADispMonitorRel select @userId,value,1 from dbo.fn_RIASplitDelimited( @dispositionsOUT ,'','')
		end

		select 1
	end

	if @action = 2 begin
		select relId, userId, dispositionId,type from ccRIADispMonitorRel where userId = @userId order by relId desc		
	end
end'
		
	EXEC(@Sql)
	
		set @process = 'CW Delete old records - Delete and Create Job'
		set @Sql='USE [msdb]
/****** Object:  Job [CW Delete old records]    Script Date: 01/03/2013 16:40:06 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''CW Delete old records'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW Delete old records'', @delete_unused_schedule=1

USE [msdb]
/****** Object:  Job [CW Delete old records]    Script Date: 01/03/2013 16:39:47 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 01/03/2013 16:39:47 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''CW Delete old records'', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run sp]    Script Date: 01/03/2013 16:39:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Run sp'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @meses int
set @meses = 8

truncate table cclogInfo
truncate table ccBorrardasReciclaje
truncate table ccUploadTemporal
truncate table ccLogCampsAgentesDia 

delete from cchistoriallistanegra where fecha < dateadd(mm, -@meses, getdate())
delete from ccRIAlog where operationDate < dateadd(mm, -@meses, getdate())
delete from ccRiaChat_log where fecha_chat < dateadd(mm, -@meses, getdate())

delete xxclientehistorial where fechaAct < dateadd(mm, -@meses, getdate())
delete ccRIAWorkGroup_logDial_id where timestamp < dateadd(dd, -15, getdate())
delete ccRIAWorkGroup_Calid where timestamp < dateadd(dd, -15, getdate())
delete ccRIALogAgentesNotReady where fecha < dateadd(dd, -15, getdate())
delete ccRIAcallbacks where año < datepart(yy,getdate())
delete ccRIAcallbacks where mes < datepart(mm,getdate())

delete from ccLogAgentesDia where fecha < dateadd(mm, -@meses, getdate())
delete from ccLogAgentesNotReady where fecha < dateadd(mm, -@meses, getdate())
delete from ccLogLogin where fecha < dateadd(mm, -@meses, getdate())
delete from ccoLogDials where fecha < dateadd(mm, -@meses, getdate())
delete from ccoCallsOut where cal_inicio < dateadd(mm, -@meses, getdate())
delete from ccoWorkingTable where cal_fechadial < dateadd(mm, -@meses, getdate())
delete from ccoCallsOutSource where cal_fechadial < dateadd(mm, -@meses-1, getdate())

delete from ccPosicionEspecialidad where Fecha < dateadd(dd, -15, getdate())
delete from ccPosicionCamps where Fecha < dateadd(dd, -15, getdate())
'', 
		@database_name=N''CCenterRIA'', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Every Sunday at 1:30'', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20041022, 
		@active_end_date=99991231, 
		@active_start_time=13000, 
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
	
		set @process = 'NuxibaMaintenancePlan - Delete and Create Job'
		set @Sql='USE [msdb]

/****** Object:  Job [NuxibaMaintenancePlan]    Script Date: 11/28/2012 08:44:30 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''NuxibaMaintenancePlan'')
EXEC msdb.dbo.sp_delete_job @job_name=N''NuxibaMaintenancePlan'', @delete_unused_schedule=1

/****** Object:  Job [NuxibaMaintenancePlan]    Script Date: 07/04/2012 11:56:51 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 07/04/2012 11:56:51 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[MaintenancePlan (Local)]''

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''NuxibaMaintenancePlan'', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''Delete and update the information for CCenterria DataBase, this job  attempts to improve the operation of the database'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''sa'', @job_id = @jobId OUTPUT

/****** Object:  Step [Check Call Center Activity]    Script Date: 07/04/2012 11:56:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Check Call Center Activity'', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=1, 
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
  RAISERROR(''''Agents online.'''', 11, 1);
END
ELSE
BEGIN
	RETURN
END'', 
		@database_name=N''CCenterRia'', 
		@flags=0

/****** Object:  Step [Check Database Integrity Task]    Script Date: 07/04/2012 11:56:51 ******/
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
		@command=N''USE [CCenterRia]

DBCC CHECKDB WITH NO_INFOMSGS'', 
		@database_name=N''CCenterRia'', 
		@flags=0

/****** Object:  Step [Maintenance Cleanup Task]    Script Date: 06/26/2012 11:25:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Maintenance Cleanup Task'', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @currentdate datetime
declare @date datetime
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = dateadd(ww,-3,getdate())

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''HKEY_LOCAL_MACHINE'''', N''''Software\Microsoft\MSSQLServer\MSSQLServer'''',N''''BackupDirectory''''

select @rutaBak = Data
from #RutaBak

EXECUTE master.dbo.xp_delete_file 0,@rutaBak,N''''bak'''',@date

drop table #RutaBak'', 
		@database_name=N''CCenterRia'', 
		@flags=0

/****** Object:  Step [Back Up Database Task]    Script Date: 06/26/2012 11:25:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Back Up Database Task'', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @currentdate datetime
declare @date varchar(200)
declare @rutaBak as nvarchar(2000)

set @currentdate = CURRENT_TIMESTAMP
select @date = ''''CCenterRia_backup_MP'''' + convert(varchar(19),dateadd(ww,-3,getdate()),112) + ''''.bak''''

create table #RutaBak(
Value nvarchar(2000) not null,
Data nvarchar(2000) not null)

insert into #RutaBak
EXEC master.dbo.xp_instance_regread  N''''HKEY_LOCAL_MACHINE'''', N''''Software\Microsoft\MSSQLServer\MSSQLServer'''',N''''BackupDirectory''''

select @rutaBak = Data
from #RutaBak

select @rutaBak= @rutaBak + ''''\'''' + @date

drop table #RutaBak

BACKUP DATABASE [CCenterRia] TO  DISK = @rutaBak WITH NOFORMAT, NOINIT,  NAME = @date, SKIP, REWIND, NOUNLOAD,  STATS = 10
'', 
		@database_name=N''CCenterRia'', 
		@flags=0

/****** Object:  Step [Rebuild Index Task]    Script Date: 06/26/2012 11:25:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Rebuild Index Task'', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''USE [CCenterRia]

ALTER INDEX [IX_axLicG729_Data] ON [dbo].[axLicG729_Data] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_Camplistanegra] ON [dbo].[Camplistanegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAbandonoSalida_Chart] ON [dbo].[ccAbandonoSalida_Chart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAgenda_TipolistaNegra] ON [dbo].[ccAgenda_TipolistaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAgendaListaNegra] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAgendaListaNegra_1] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAgendaListaNegra_2] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAgendaListaNegra_3] ON [dbo].[ccAgendaListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_INFOESPEC_FECHA] ON [dbo].[ccAllInfoEspec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_INFOESPEC_INBOUND_ID] ON [dbo].[ccAllInfoEspec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccAVRSTransfer] ON [dbo].[ccAVRSTransfer] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccAVRSTransfer] ON [dbo].[ccAVRSTransfer] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_cccalifblacklist] ON [dbo].[cccalifblacklist] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCalifCamp] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCalifCamp_1] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [uc_ccCalifCamp] ON [dbo].[ccCalifCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallsIn] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallsIn_1] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallsIn_2] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallsIn_3] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallsIn_4] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallsIn_5] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccCallsIn] ON [dbo].[ccCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_cccallsin_tmpChart] ON [dbo].[cccallsin_tmpChart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccCallsReject] ON [dbo].[ccCallsReject] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccCamps] ON [dbo].[ccCamps] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccCamps_Consulta] ON [dbo].[ccCamps_Consulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [iii] ON [dbo].[ccCampsAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccCampsAgente] ON [dbo].[ccCampsAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCampsHorarios] ON [dbo].[ccCampsHorarios] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCampsMsgs] ON [dbo].[ccCampsMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCampsNvosCB] ON [dbo].[ccCampsNvosCB] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCampsPrioridadTel] ON [dbo].[ccCampsPrioridadTel] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccClientes] ON [dbo].[ccClientes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccDNIS] ON [dbo].[ccDNIS] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccDNIS] ON [dbo].[ccDNIS] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccEdoAniList] ON [dbo].[ccEdoAniList] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenAgent] ON [dbo].[ccGenAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenAgentNotReady] ON [dbo].[ccGenAgentNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenChart] ON [dbo].[ccGenChart] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenInAbnd] ON [dbo].[ccGenInAbnd] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenInAnsw] ON [dbo].[ccGenInAnsw] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenInCalif] ON [dbo].[ccGenInCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenInCall] ON [dbo].[ccGenInCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenInCallDNI] ON [dbo].[ccGenInCallDNI] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSpec] ON [dbo].[ccGenInSpec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenOutCall] ON [dbo].[ccGenOutCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenOutCallCalif] ON [dbo].[ccGenOutCallCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenOutCallDials] ON [dbo].[ccGenOutCallDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSpecOut] ON [dbo].[ccGenOutCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenOutCstoResumen] ON [dbo].[ccGenOutCstoResumen] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenLogin] ON [dbo].[ccGenSession] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSessionAgent] ON [dbo].[ccGenSessionAgent] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSessionInCall] ON [dbo].[ccGenSessionInCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSessionInSpec] ON [dbo].[ccGenSessionInSpec] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSessionNotReady] ON [dbo].[ccGenSessionNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSessionOutCall] ON [dbo].[ccGenSessionOutCall] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccGenSessionOutCamp] ON [dbo].[ccGenSessionOutCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccgenTelMarcados] ON [dbo].[ccgenTelMarcados] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccHistorialListaNegra] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccHistorialListaNegra_1] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccHistorialListaNegra_2] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccHistorialListaNegra_3] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccHistorialListaNegra] ON [dbo].[ccHistorialListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccHorarios] ON [dbo].[ccHorarios] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccHorarioVerano] ON [dbo].[ccHorarioVerano] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccHorarioVeranoUsa] ON [dbo].[ccHorarioVeranoUsa] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccInbound] ON [dbo].[ccInbound] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccInbound_Consulta] ON [dbo].[ccInbound_Consulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccInboundAgentes] ON [dbo].[ccInboundAgentes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccInboundDNIS] ON [dbo].[ccInboundDnis] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccInboundHorarios] ON [dbo].[ccInboundHorarios] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccInboundMsgs] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccInboundMsgs_1] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccInboundMsgs_2] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccInboundMsgs_3] ON [dbo].[ccInboundMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccListaNegra] ON [dbo].[ccListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesDia] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesDia_1] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesDia_2] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesDia_3] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesDia_4] ON [dbo].[ccLogAgentesDia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccLogAgentesDia_Dialog] ON [dbo].[ccLogAgentesDia_Dialog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesNotReady] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesNotReady_2] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogAgentesNotReady_3] ON [dbo].[ccLogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogLogin] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogLogin_1] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogLogin_2] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogLogin_3] ON [dbo].[ccLogLogin] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogReciclaje] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogReciclaje_1] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogReciclaje_2] ON [dbo].[ccLogReciclaje] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccLogTransfers_2] ON [dbo].[ccLogTransfers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccMenu_Views] ON [dbo].[ccMenu_Views] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccMenu_ViewsUser] ON [dbo].[ccMenu_ViewsUser] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccMenus] ON [dbo].[ccMenus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccMenus] ON [dbo].[ccMenus] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccMenusReportes] ON [dbo].[ccMenusReportes] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccMonitorExt] ON [dbo].[ccMonitorExt] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccMsgFiles] ON [dbo].[ccMsgFiles] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallBacks] ON [dbo].[ccoCallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_1] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_10] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_11] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_2] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_3] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_4] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_5] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_6] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_7] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_8] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOut_9] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccoCallsOut] ON [dbo].[ccoCallsOut] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_1] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_10] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_11] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_2] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_3] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_4] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_5] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_6] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_7] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_8] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoCallsOutSource_9] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccoCallsOutSource] ON [dbo].[ccoCallsOutSource] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccoDatos] ON [dbo].[ccoDatos] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccodialercamp] ON [dbo].[ccoDialerCamp] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoDialers] ON [dbo].[ccoDialers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccodialers] ON [dbo].[ccoDialers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoLogDials] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoLogDials_1] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoLogDials_2] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoLogDials_3] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccoLogDials] ON [dbo].[ccoLogDials] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_1] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_10] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_11] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_12] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_13] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_14] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_2] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_3] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_4] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_5] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_6] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_7] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_8] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccoWorkingTable_9] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccoWorkingTable] ON [dbo].[ccoWorkingTable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccPosicion] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccPosicion_1] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccPosicion_2] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccPosicion] ON [dbo].[ccPosicion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccPuertosPBX] ON [dbo].[ccPuertosPBX] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccCallBacks] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACallBacks] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACallBacks_1] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACallBacks_2] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACallBacks_3] ON [dbo].[ccRIACallBacks] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACampEspWG] ON [dbo].[ccRIACampEspWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACampEspWG_1] ON [dbo].[ccRIACampEspWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIACampEspWG_2] ON [dbo].[ccRIACampEspWG] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIACampsGraph] ON [dbo].[ccRIACampsGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIACat_Restrictions] ON [dbo].[ccRIACat_AdminRole] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIACat_DialMode] ON [dbo].[ccRIACat_DialMode] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIACatFunExt] ON [dbo].[ccRIACatFunExt] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAChat_Log_1] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAChat_Log] ON [dbo].[ccRIAChat_Log] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAChat_TipoMsg] ON [dbo].[ccRIAChat_TipoMsg] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAClienteCarga] ON [dbo].[ccRIAClienteCarga] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAClienteCarga_1] ON [dbo].[ccRIAClienteCarga] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAExternalApplications] ON [dbo].[ccRIAExternalApplications] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAGraphics] ON [dbo].[ccRIAGraphics] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAGraphicType] ON [dbo].[ccRIAGraphicType] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAInboundGraph] ON [dbo].[ccRIAInboundGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIALoading] ON [dbo].[ccRIALoading] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIALoading_1] ON [dbo].[ccRIALoading] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIALoading] ON [dbo].[ccRIALoading] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIALog] ON [dbo].[ccRIALog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIALog_Module] ON [dbo].[ccRIALog_Module] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIALog_Operation] ON [dbo].[ccRIALog_Operation] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIALogAgentesNotReady] ON [dbo].[ccRIALogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIALogAgentesNotReady_1] ON [dbo].[ccRIALogAgentesNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIANotReadyGraph] ON [dbo].[ccRIANotReadyGraph] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_Table_1] ON [dbo].[ccRIARegistryLists] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRiaRemoteLog] ON [dbo].[ccRiaRemoteLog] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAUpdateCallBack_Abandon_1] ON [dbo].[ccRIAUpdateCallBack_Abandon] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccRIAUpdateCallBack_Abandon] ON [dbo].[ccRIAUpdateCallBack_Abandon] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAWorkGroup_Calid_2] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAWorkGroup_Calid_3] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_WGCal_id] ON [dbo].[ccRIAWorkGroup_Calid] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_cccRIAWorkGroup_logdial_id_2] ON [dbo].[ccRIAWorkGroup_logDial_id] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_WGlogDial_id] ON [dbo].[ccRIAWorkGroup_logDial_id] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccRIAWorkGroupUsers] ON [dbo].[ccRIAWorkGroupUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccSettings] ON [dbo].[ccSettings] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccStatusLLamada] ON [dbo].[ccStatusLLamada] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccSupervisorND] ON [dbo].[ccSupervisor_NotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [ix_tipo_1] ON [dbo].[ccSupervisorCam] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccSupervisorCam] ON [dbo].[ccSupervisorCam] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_TideWater_Templates] ON [dbo].[ccTideWater_Templates] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTideWater_Templates_Cols] ON [dbo].[ccTideWater_Templates_Cols] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTideWater_TipoConexion] ON [dbo].[ccTideWater_TipoConexion] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_Timetable] ON [dbo].[ccTimetable] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTimetablechange] ON [dbo].[ccTimetablechange] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTimetabledetail] ON [dbo].[ccTimetabledetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTimeZoneArea_1] ON [dbo].[ccTimeZoneArea] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [pk_areaprefix] ON [dbo].[ccTimeZoneAreaUsaDetail] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTimeZones] ON [dbo].[ccTimeZones] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoCalif] ON [dbo].[ccTipoCalif] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoCalifOUT] ON [dbo].[ccTipoCalifOUT] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoCalifSub] ON [dbo].[ccTipoCalifSub] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoSubCalifOUT] ON [dbo].[ccTipoCalifSubOUT] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoFiltro] ON [dbo].[ccTipoFiltro] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoMovsListaNegra] ON [dbo].[ccTipoMovsListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoMsgs] ON [dbo].[ccTipoMsgs] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoNotReady] ON [dbo].[ccTipoNotReady] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoPBX] ON [dbo].[ccTipoPBX] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoResultadoDial] ON [dbo].[ccTipoResultadoDial] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTiposListaNegra] ON [dbo].[ccTiposListaNegra] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccTipoStatusAgente] ON [dbo].[ccTipoStatusAgente] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_cctipoSubCalifRel] ON [dbo].[cctipoSubCalifRel] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccUploadTemporal] ON [dbo].[ccUploadTemporal] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccUploadTemporal_1] ON [dbo].[ccUploadTemporal] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccusers] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_ccusers_1] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccUsers] ON [dbo].[ccUsers] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_ccUsers_Consulta] ON [dbo].[ccUsers_Consulta] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_cstoProvedor] ON [dbo].[cstoProvedor] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_cstoTarifa] ON [dbo].[cstoTarifa] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_cstoTipoLlamada] ON [dbo].[cstoTipoLlamada] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY  = OFF, ONLINE = OFF )

ALTER INDEX [PK_IVR_ID_1] ON [dbo].[IVRCallsIn] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_Series] ON [dbo].[Series] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [IX_Series_1] ON [dbo].[Series] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_telefonosConferencia] ON [dbo].[telefonosConferencia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_telefonosTransferencia] ON [dbo].[telefonosTransferencia] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )

ALTER INDEX [PK_clienteCarga] ON [dbo].[xxClienteCarga] REBUILD WITH ( PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, SORT_IN_TEMPDB = OFF, ONLINE = OFF )
'', 
		@database_name=N''CCenterRia'', 
		@flags=0

/****** Object:  Step [History Cleanup Task]    Script Date: 06/26/2012 11:25:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''History Cleanup Task'', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command=N''DECLARE @currentdate datetime
declare @dt datetime

set @currentdate = CURRENT_TIMESTAMP
select  @dt =dateadd(ww,-3,getdate())

exec msdb.dbo.sp_delete_backuphistory @dt

EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date=@dt

EXECUTE msdb..sp_maintplan_delete_log null,null,@dt'', 
		@database_name=N''CCenterRia'', 
		@flags=0

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1

EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''monthy'', 
		@enabled=1, 
		@freq_type=32, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=1, 
		@freq_recurrence_factor=1, 
		@active_start_date=20120615, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959

EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''

COMMIT TRANSACTION'
			
	EXEC(@Sql)

		set @process = 'ccsp_DLRgetDialPrefix - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_DLRgetDialPrefix]
@cam_id smallint=0,
@iPortNumber smallint = 0,
@phone varchar(30) = ''''
as
declare @prefix as varchar(15)
declare @ani as varchar(32)

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

select @prefix as sDialPrefix, cam_tNoContesta as tNoContesta,
case when @ani = '''' then ani else @ani end as ani, detectAnswerMachine, detectVoiceMail
from ccCamps where cam_id = @cam_id'
	EXEC(@Sql)

		set @process = 'ccsp_DLRGetDialInfo - Alter Procedure'
		set @Sql = 'ALTER procedure [dbo].[ccsp_DLRGetDialInfo]
@callout_id int,
@cam_id smallint=0,
@iPortNumber smallint = 0
AS
set nocount on
declare @message_name as varchar(max), @messageDNCL_name as varchar(max)
declare @prefix as varchar(15)
declare @tNoContesta as tinyint
declare @ani as varchar(32)
declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint
declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint

set @prefix =''''
set @tNoContesta = 25
set @ani=''''
set @iTipoDial = 0
set @detectAnswerMachine = 0
set @detectVoiceMail =1
set @cam_tnotas = 30
set @keepDial = 0

-- Mensajes
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc
from dbo.fn_ccCamps_SelMessage(@cam_id)

-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )
-- Prefijo por campaña
if @prefix =''''
	select @prefix = dialPrefix from ccCamps where cam_id = @cam_id
-- Prefijo general, si es que esta habilitado
if @prefix ='''' and ((select cast(valor as int) from ccsettings where setting_id =102) & 1 = 1)
	select @prefix = valor from ccsettings where setting_id =101

set @iPortNumber = 0

-- Propiedades de campaña
select @tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist
from ccCamps C where C.cam_id=@cam_id

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
	FROM ccoCallsOutSource C 
	WHERE C.callout_id = @callout_id
	return
end 

/*
select @ldNew = case 
	when @iPortNumber < 751 then ''81''
	when @iPortNumber > 750 and @iPortNumber < 766 then ''722''
	when @iPortNumber > 765 and @iPortNumber < 781 then ''477''
	when @iPortNumber > 780 then ''33''
	else ''55'' end

SELECT c.callout_id, ''cal_ke''y''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5), 1 as nTryingContact, isnull(W.cal_status,0) cal_status, dial_tels, 3 as last_dialed, 
	dbo.CambiaLada(''55'', @ldNew, C.cal_telefono) as cal_telefono, 
	dbo.CambiaLada(''55'', @ldNew, cal_telefono2) as cal_telefono2, 
	dbo.CambiaLada(''55'', @ldNew,cal_telefono3) as cal_telefono3, 
	dbo.CambiaLada(''55'', @ldNew,cal_telefono4) as cal_telefono4, 
	dbo.CambiaLada(''55'', @ldNew,cal_telefono5) as cal_telefono5, 
	isnull(@message_name, '''') as ''message_name'', isnull(@tNoContesta, 25) as ''tNoContesta'', @prefix as sDialPrefix
	, case when dbo.TelAni(c.cal_telefono,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono,@lista_id) else @ani end ani
	, @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail, @prefixUse PrefixUse
	, @cam_tnotas cam_tnotas, @keepDial keepDial, isnull(@stopRecording,0) stopRecording
	, case when dbo.TelAni(c.cal_telefono2,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono2,@lista_id) else @ani end ani2
	, case when dbo.TelAni(c.cal_telefono3,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono3,@lista_id) else @ani end ani3
	, case when dbo.TelAni(c.cal_telefono4,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono4,@lista_id) else @ani end ani4
	, case when dbo.TelAni(c.cal_telefono5,@lista_id) <> '''' then dbo.TelAni(c.cal_telefono5,@lista_id) else @ani end ani5
	,isnull(@messageDNCL_name, '''') as ''messageDNCL_name''
FROM ccoCallsOutSource C left join ccoWorkingTable W ON C.callout_id = W.callout_id
WHERE W.callout_id = @callout_id
*/
set nocount off'
	EXEC(@Sql)

		set @process = 'ccsp_DLRgetXferInfo - Create Procedure'
		set @Sql = 'Create procedure [dbo].[ccsp_DLRgetXferInfo]
@camEspecId smallint=0,
@iPortNumber smallint = 0,
@type smallint
as
-- @type: 1 transferencia entrada, 2 transferencia salida, 3 desborde (siempre es entrada, con o sin especialidad)
declare @prefix as varchar(15)
declare @timeout int
declare @ani as varchar(32)
declare @stop int

set @prefix =''''
set @timeout = 20
set @ani = ''''
set @stop = 0

-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )
-- Prefijo por campaña o especialidad
if @prefix =''''
	if @type = 2
		select @prefix = dialPrefixXfe from ccCamps where cam_id = @camEspecId
	else
		select @prefix = dialPrefixOverflow from ccInbound where inbound_id= @camEspecId
-- Prefijo general
if @prefix ='''' and (@type =1 or @type=2) and ((select cast(valor as int) from ccsettings where setting_id =102) & 4 = 4)
	select @prefix = valor from ccsettings where setting_id =101
if @prefix ='''' and (@type =3) and ((select cast(valor as int) from ccsettings where setting_id =102) & 8 = 8)
	select @prefix = valor from ccsettings where setting_id =101

-- Tiempo de marcado
select @timeout = cast(valor as int) from ccSettings where setting_id = 109

-- Ani y stopRecord
if @type = 2
	select @ani = callerIdDesc, @stop = stopRecording from ccCamps where cam_id = @camEspecId
else
	select @ani = callerIdDesc, @stop = stopRecording from ccInbound where inbound_id= @camEspecId

select @prefix as sDialPrefix, @timeout as tNoContesta, @ani as ani, @stop as stopRecording'
	EXEC(@Sql)
		
		set @process = 'Integration Apps - Insert'
		set @Sql = '-- javascript
if not exists (select id from ccRIAExternalApplications where appUrl like ''%javascriptCoreIntegration%'')
Begin
	insert into ccRIAExternalApplications (type, title, iconURL, appURL, autoRun) 
	VALUES (''3'',''JavaScript Package'',''icon'',''./ExternalApps/JavascriptCoreIntegration.swf'',''0'')
	insert into ccRIAClassPath 
	values (SCOPE_IDENTITY(), ''com.nuxiba.agent.engine.Integration.JavascriptPackage.JavascriptCORE'')
End
-- socketbox
if not exists (select id from ccRIAExternalApplications where appUrl like ''%CoreSocket%'')
Begin
	insert into ccRIAExternalApplications (type, title, iconURL, appURL, autoRun) 
	VALUES (''3'',''Socket BOX'',''icon'',''./ExternalApps/CoreSocket.swf'',''0'')
	insert into ccRIAClassPath 
	values (SCOPE_IDENTITY(), ''com.nuxiba.agent.engine.Integration.SocketBox.SocketBoxCORE'')
End'
	EXEC(@Sql)

		set @process = 'ccsp_IVRAfterXferAge - Alter Procedure'
		set @Sql = 'ALTER PROCEDURE [dbo].[ccsp_IVRAfterXferAge]
@cal_id int,
@User_id smallint,
@cal_extension varchar(7),
@tWait smallint
AS
set nocount on
-- 2005-11-15 por ODC
-- colocar como asignada despues de transferir
Update ccCallsIn SET user_id=@User_id, cal_extension=@cal_extension,-- cal_tWait=@tWait,
cal_xfer=getdate(), statusCall_id=11  -- 11=Asignada
where cal_id=@cal_id

update ccRIAWorkGroup_Calid set user_id=@User_id where cal_id = @cal_id and tipo = 0

return(0)
set nocount off'
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
