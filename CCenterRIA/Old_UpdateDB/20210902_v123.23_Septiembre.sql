/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/07/01
Description:

Database: CCenterRia
Required version: 123.14

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 23
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

    set @process = 'CW-5629 ccsp_CleanNodeBaseX - Se quita el SP ccsp_CleanNodeBaseX si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_CleanNodeBaseX'')
            begin
          DROP PROCEDURE ccsp_CleanNodeBaseX;
            end'
    EXEC(@sql)

    set @process = 'CW-5629 ccsp_CleanNodeBaseX - Se modifica SP ccsp_CleanNodeBaseX'
    set @sql = 'CREATE Procedure [dbo].[ccsp_CleanNodeBaseX]

	@option int
	AS
	BEGIN

		declare @percentage int,@setting int
		declare @top int
		declare @table table(id bigint primary key,node xml not null,dateStart datetime, status	tinyint not null)
		declare @tableNotExists table(id bigint primary key)

		set @percentage=20 --porcentaje de registros que se pasaran esta en funcion del setting 188

		select  @setting  = valor from ccSettings where setting_id = 188
		if @setting is null set @setting = 40000
		set @top=@setting/@percentage
	
		if @option = 1 begin
		
				insert into @table
				select top (@top)  A.chatId, A.node,A.dateIn, status from ccChatsNode A with(nolock) where A.status in(1,3) order by chatId
		
				insert into @tableNotExists
				select A.id from  @table A 
				left join ccChatsNodeHistory  B with(nolock)  on B.chatId=A.id 
				where B.chatId is null
		
				insert into ccChatsNodeHistory(chatId,node,dateIn,status)		
				select  A.id,A.node,A.dateStart,A.status from @table A
				inner join @tableNotExists B on A.id=B.id

				delete from ccChatsNode where chatId in(select id from @table)

		end
		else if @option = 3  begin
	
			insert into @table
			select top (@top)  A.emailId, A.node,A.dateIn,status from ccEmailNode A with(nolock) where A.status in(1,3) order by emailId
		
			insert into @tableNotExists
			select A.id from  @table A 
			left join ccEmailNodeHistory  B with(nolock)  on B.emailId=A.id 
			where B.emailId is null
		
			insert into ccEmailNodeHistory(emailId,node,dateIn,status)		
			select  A.id,A.node,A.dateStart,A.status from @table A
			inner join @tableNotExists B on A.id=B.id

			delete from ccEmailNode where emailId in(select id from @table)
		end
		else if @option = 4  begin
	
			insert into @table
			select top (@top)  A.conversationTwitterId, A.node,A.dateIn,status from ccTwitterNode A with(nolock) where A.status in(1,3) order by conversationTwitterId
		
			insert into @tableNotExists
			select A.id from  @table A 
			left join ccTwitterNodeHistory  B with(nolock)  on B.conversationTwitterId=A.id 
			where B.conversationTwitterId is null
		
			insert into ccTwitterNodeHistory(conversationTwitterId,node,dateIn,status)		
			select  A.id,A.node,A.dateStart,A.status from @table A
			inner join @tableNotExists B on A.id=B.id

			delete from ccTwitterNode where conversationTwitterId in(select id from @table)
		end

	END'
    EXEC(@sql)		

	
	set @process = 'CW-5762 Drop contraint ccRIACat_Areas_maxWhats'
    set @sql = 'declare @name nvarchar(max),@sql2 nvarchar(max)
SELECT 
    @name=   dc.Name   
FROM sys.tables t
INNER JOIN sys.default_constraints dc ON t.object_id = dc.parent_object_id
INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND c.column_id = dc.parent_column_id
where t.name=''ccRIACat_Areas'' and c.name=''maxWhats''  and dc.name<>''ccRIACat_Areas_maxWhats''
ORDER BY t.Name

if @name is not null begin
 set @sql2=''ALTER TABLE ccRIACat_Areas DROP CONSTRAINT ''+@name
    exec (@sql2)
end	
	
	IF EXISTS
          (SELECT * FROM SYS.COLUMNS WHERE OBJECT_ID = OBJECT_ID(''ccRIACat_Areas'')
                                           AND NAME = ''maxWhats''
          )
BEGIN    	
	ALTER TABLE ccRIACat_Areas ALTER COLUMN maxWhats TINYINT;    	
END
else begin
	ALTER TABLE ccRIACat_Areas ADD maxWhats TINYINT;
end



'
    EXEC(@sql)

	set @process = 'CW-5762 Valor por default para maximo de WhatsApp por agente'
    set @sql = 'if not exists (
SELECT 
    dc.Name   
FROM sys.tables t
INNER JOIN sys.default_constraints dc ON t.object_id = dc.parent_object_id
INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND c.column_id = dc.parent_column_id
where t.name=''ccRIACat_Areas'' and c.name=''maxWhats'' and dc.name=''ccRIACat_Areas_maxWhats''

)
    begin
        ALTER TABLE [ccRIACat_Areas] ADD CONSTRAINT ccRIACat_Areas_maxWhats DEFAULT 3 FOR [maxWhats];
		UPDATE ccRIACat_Areas SET maxWhats = 3 WHERE maxWhats IS NULL;
    end'
    EXEC(@sql)

    set @process = 'Correcion Del catalogo configuraIdiomaCatalogosEspañol'
    set @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEspañol]
	AS
SET NOCOUNT ON

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
delete from [dbo].[ccStatusLLamada]

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
truncate table [dbo].[ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo resultados de marcacion''
delete from [dbo].[ccTipoResultadoDial]

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
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, convert(text, N''Transferencia Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, convert(text, N''Ringing Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, convert(text, N''ReconnectKolob'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, convert(text, N''Ready PreviewPro'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (32, convert(text, N''Preview'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, convert(text, N''Agente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, convert(text, N''AVRS Calidad'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
DBCC CHECKIDENT (''[ccDias]'', RESEED, 0)
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
delete from [dbo].cstoTarifa
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''LD nacional'',''12'',''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Cel'',''13'',''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''Cel LD'',''13'',''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''LD USA'',''13'',''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''LD inter'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''LADA local 2 dígitos'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''Local lada 3 digitos'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''Local lada 4 digitos'',''6'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''Cel LADA local 2 dígitos'',''10'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''Cel LADA local 3 dígitos'',''9'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''Cel LADA local 4 dígitos'',''8'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Larga distancia'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Cel larga distancia'',''13'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Celular'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''LD Nacional'',''11'',''1%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''LD Nacional'',''10'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Celular'',''11'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Cel'',''11'',''07%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''LD inter'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''LD anterior'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Cel'',''10'',''05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''LD actual'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''LD inter'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''LD inter'',''0'',''0011%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Cel'',''10'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Movil '',''8'',''6%|7%|8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''Celular 9 dígitos '',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''LD Nacional'',''10'',''02%|03%|04%|05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''Cel LD nacional'',''10'',''06%|07%|08%|09%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''Cel LD nacional 9 dígitos'',''11'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''LD internacional'',''19'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Movil'',''8'',''3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''LD Nacional'',''8'',''7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''LD internacional'',''8'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''Telefonía SIP'',''8'',''4%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Telefonía móvil'',''8'',''5%|6%|7%|8%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Cobro Revertido'',''10'',''800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Tarifa Prima'',''10'',''90%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Acceso Internet'',''10'',''900%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Especial'',''0'',''08%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Fijo'',''8'',''2%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Movil'',''8'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Celular'',''9'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Servicios web'',''9'',''5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''LD nacional'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Cel'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''LD inter'',''0'',''00%'')

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
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, convert(text, N''Solicita información general'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, convert(text, N''Se cortó la llamada'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, convert(text, N''Número equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0)

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
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telular'')

Print ''Mensajes voz defualt''
DELETE [dbo].[ccMsgFiles]
DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default5'', ''Mensaje Bienvenida'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default4'', ''Mensaje Transferencia'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default3'', ''Mensaje Fuera de servicio'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default2'', ''Mensaje Fuera de horario'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default1'', ''Mensaje En espera'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default7'', ''Mensaje Sin agentes firmados'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default9'', ''Mensaje VoiceMail'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default10'', ''Mensaje Desborde'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default11'', ''Lista Negra'')


Print ''Mensajes default chat''
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default5'', ''!Bienvenido!'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default3'', ''El servicio no se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default2'', ''Nuestro horario de atención ha terminado'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default1'', ''Por favor espere mientras uno de nuestros agentes se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default7'', ''No hay agentes disponibles'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default10'', ''No podemos tomar su solicitud'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default12'', ''La sesión de chat ha estado inactiva mucho tiempo'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default13'', ''La sesión de chat ha concluido'')
'
    EXEC(@sql)

    set @process = 'CW-5781 Drop CONSTRAINT ccChatsNode.status'
    set @sql = 'declare @name nvarchar(max),@sql2 nvarchar(max)
SELECT
    @name=   dc.Name  
FROM sys.tables t
INNER JOIN sys.default_constraints dc ON t.object_id = dc.parent_object_id
INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND c.column_id = dc.parent_column_id
where t.name=''ccChatsNode'' and c.name=''status'' 
ORDER BY t.Name
 

if @name is not null begin

 set @sql2=''ALTER TABLE ccChatsNode DROP CONSTRAINT ''+@name
    exec (@sql2)
end'
    EXEC(@sql)

	set @process = 'CW-5781  Drop index ccChatsNode.IX_status'
    set @sql = 'if exists (select * from sys.indexes where name = N''IX_status'' and object_id = OBJECT_ID(N''ccChatsNode''))
    begin
        Drop index ccChatsNode.IX_status
    end'
    EXEC(@sql)

    set @process = 'CW-5781 Alter Column ccChatsNode.status'
    set @sql = 'ALTER TABLE ccChatsNode alter column status smallint 
ALTER TABLE ccChatsNodeHistory alter column status smallint '
    EXEC(@sql)

    set @process = 'CW-5781 CREATE TABLE ccWhatsAppNode'
    set @sql = 'IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''ccWhatsAppNode'')
BEGIN
    CREATE TABLE [dbo].[ccWhatsAppNode]([conversationId] [INT] NOT NULL
                                      , [node]           [XML] NULL
                                      , [dateIn]         [DATETIME] NULL
                                      , [dateOut]        [DATETIME] NULL
                                      , [status]         [smallint] NULL
                                      , PRIMARY KEY CLUSTERED([conversationId] ASC)
                                        WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
    )
    ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

    ALTER TABLE [dbo].[ccWhatsAppNode]
    ADD DEFAULT(NULL) FOR [dateOut];

    ALTER TABLE [dbo].[ccWhatsAppNode]
    ADD DEFAULT((0)) FOR [status];

END;'
    EXEC(@sql)

    set @process = 'CW-5781 Create table ccWhatsAppNodeHistory'
    set @sql = 'IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = ''ccWhatsAppNodeHistory'')
BEGIN
    CREATE TABLE [dbo].[ccWhatsAppNodeHistory]([conversationId] [INT] NOT NULL
                                             , [node]           [XML] NULL
                                             , [dateIn]         [DATETIME] NULL
                                             , [dateOut]        [DATETIME] NULL
                                             , [status]         [smallint] NULL
                                             , PRIMARY KEY CLUSTERED([conversationId] ASC)
    );

END;'
    EXEC(@sql)

    set @process = 'CW-5781 ALTER ccFinderServices columns tableName,tableNameHistory,columnId'
    set @sql = '

IF NOT EXISTS
              (SELECT * FROM sys.columns WHERE name = N''tableName''
                                               AND Object_ID = OBJECT_ID(N''ccFinderServices'')
              )
BEGIN
    ALTER TABLE ccFinderServices
    ADD tableName [VARCHAR](255) NULL;
END;

IF NOT EXISTS
              (SELECT * FROM sys.columns WHERE name = N''tableNameHistory''
                                               AND Object_ID = OBJECT_ID(N''ccFinderServices'')
              )
BEGIN
    ALTER TABLE ccFinderServices
    ADD tableNameHistory [VARCHAR](255) NULL;
END;

IF NOT EXISTS
              (SELECT * FROM sys.columns WHERE name = N''columnId''
                                               AND Object_ID = OBJECT_ID(N''ccFinderServices'')
              )
BEGIN
    ALTER TABLE ccFinderServices
    ADD columnId [VARCHAR](255) NULL;
END;

IF NOT EXISTS
              (SELECT * FROM sys.columns WHERE name = N''isActive''
                                               AND Object_ID = OBJECT_ID(N''ccFinderServices'')
              )
BEGIN
    ALTER TABLE ccFinderServices
    ADD isActive bit NUll;
END;'
    EXEC(@sql)

    set @process = 'CW-5781 update data ccFinderServices'
    set @sql = '
    UPDATE ccFinderServices
           SET
               tableName = ''ccChatsNode''
             , tableNameHistory = ''ccChatsNodeHistory''
             , columnId = ''chatId''
			 ,isActive=1
    WHERE id = 1;
    UPDATE ccFinderServices
           SET
               tableName = ''RIA_RecNode''
             , tableNameHistory = ''RIA_RecNodeHistory''
             , columnId = ''grab_id''
			 ,isActive=1
    WHERE id = 2;
    UPDATE ccFinderServices
           SET
               tableName = ''ccEmailNode''
             , tableNameHistory = ''ccEmailNodeHistory''
             , columnId = ''emailId''
			 ,isActive=1
    WHERE id = 3;
    UPDATE ccFinderServices
           SET
               tableName = ''ccTwitterNode''
             , tableNameHistory = ''ccTwitterNodeHistory''
             , columnId = ''conversationTwitterId''
			 ,isActive=1
    WHERE id = 4;'
    EXEC(@sql)

    set @process = 'CW-5781 Add ccFinderServices WhastApp'
    set @sql = 'IF NOT EXISTS(SELECT * FROM ccFinderServices WHERE name = ''WhastApp'')
BEGIN
    INSERT INTO ccFinderServices
    (name
   , ref
   , tableName
   , tableNameHistory
   , columnId
   ,isActive
    )
    VALUES(''WhastApp'', ''R05'', ''ccWhatsAppNode'', ''ccWhatsAppNodeHistory'', ''conversationId'',1);
END;'
    EXEC(@sql)

    set @process = 'CW-5781 Alter SP ccsp_CreateNodeMultimedia'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_CreateNodeMultimedia] @conversationId BIGINT
                                                , @supervisor     VARCHAR(255) = ''''
                                                , @template       VARCHAR(255) = ''''
                                                , @ScoreTemplate  INT          = 0
                                                , @type           INT                                                
AS
BEGIN

    DECLARE @xml XML, @dateStart DATETIME;
    DECLARE @info VARCHAR(255);
    DECLARE @infoEscape VARCHAR(MAX);
    DECLARE @charEscape VARCHAR(255), @charReplace VARCHAR(MAX);
    SET @charEscape = ''"|''''''''|<|>|&'';
    SET @charReplace = ''&quot;|&apos;|&lt;|&gt;|&amp;'';

    DECLARE @existAttached BIT, @numInteracion SMALLINT;
    IF @type = 1
    BEGIN--CHAT
        SELECT @xml = CONVERT(XML, ''<R01 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126))) 
            + ''" CID="'' + CONVERT(VARCHAR(MAX), ccRIAChats.inboundid) 
        + ''" CType="1'' 
        + ''" C01="'' + CONVERT(VARCHAR(MAX), chatId) 
        + ''" C02="'' + CONVERT(VARCHAR(MAX), ISNULL(ccinbound.descripcion, '''')) 
        + ''" C03="'' + CONVERT(VARCHAR(MAX), domain) 
        + ''" C04="'' + CONVERT(VARCHAR(MAX), ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'')) 
        + ''" C05="'' + CONVERT(VARCHAR(MAX), tchatting) 
        + ''" C06="'' + CONVERT(VARCHAR(MAX), ISNULL(cctipocalif.[Description], ''N/A'')) 
        + ''" C07="'' + CONVERT(VARCHAR(MAX), ISNULL(cctipocalifsub.califSubdesc, ''N/A'')) 
        + ''" C08="'' + CONVERT(VARCHAR(MAX), clientname) 
        + ''" C09="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126))) 
        + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
        + ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
        + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
        + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(ccusers.[Login], '''')) 
        + ''"/>'')
             , @dateStart = ISNULL(chatDate, requestDate) FROM ccRIAChats
                                                               LEFT OUTER JOIN ccinbound ON ccinbound.inbound_id = ccRIAChats.inboundid
                                                               LEFT OUTER JOIN ccusers ON ccusers.user_id = ccRIAChats.userid
                                                               LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = ccRIAChats.disposition
                                                               LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = ccRIAChats.subdisposition
                                                                                                 AND ccRIAChats.subdisposition <> 0
        WHERE chatId = @conversationId
              AND chatStatus = 4              

    END;
    ELSE
        IF @type = 3
        BEGIN--EMAIL
            SELECT @existAttached = CASE WHEN COUNT(*) > 0
                                    THEN 1 ELSE 0
                                    END FROM attached
            WHERE messageId IN(SELECT messageId FROM message WHERE conversationId = @conversationId);
            SELECT @numInteracion = COUNT(*) FROM message WHERE conversationId = @conversationId;
            --Replaza los caracteres por los comunes
            SELECT @info = info FROM conversation WHERE conversationId = @conversationId;
            SELECT @info = replace(@info, A.Value, B.Value) FROM dbo.fn_RIASplitDelimited(@charEscape, ''|'') A
                                                                 INNER JOIN dbo.fn_RIASplitDelimited(@charReplace, ''|'') B ON A.Id = B.Id;

            SELECT @xml = CONVERT(XML, ''<R03 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126))) 
                + ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid) 
            + ''" CType="1'' 
            + ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationId) 
            + ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126))) 
            + ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion)) 
            + ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''''))) 
            + ''" C05="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalif.[Description], ''N/A''))) 
            + ''" C06="'' + CONVERT(VARCHAR, MAX(replace(replace(a.mailClient, ''<'', '' ''), ''>'', '' ''))) 
            + ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup)) 
            + ''" C08="'' + CONVERT(VARCHAR(MAX), MIN(ISNULL(@info, ''''))) 
            + ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid)) 
            + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0)) 
            + ''" C11="'' + CONVERT(VARCHAR(MAX), @existAttached) 
            + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
            + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
            + ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
            + ''" C15="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalifsub.califSubdesc, ''N/A''))) 
            + ''" C16="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), '''')) 
            + ''"/>'')
                 , @dateStart = ISNULL(MAX(b.tsend), GETDATE()) FROM conversation a
                                                                     INNER JOIN message b ON a.conversationid = b.conversationid
                                                                     LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
                                                                     LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
                                                                     LEFT OUTER JOIN relationmessageDisposition e ON e.messageId = b.messageId
                                                                     LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = e.dispositionId
                                                                     LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = e.subdispositionId
                                                                                                       AND e.subdispositionId <> 0
            WHERE a.conversationId = @conversationId
            GROUP BY a.conversationId
                   , a.inboundid;

        END;
        ELSE
            IF @type = 4
            BEGIN--Twitter
                SELECT @numInteracion = SUM(ninteration) FROM messageOutTwitter
                WHERE conversationTwitterId = @conversationId;

                SELECT @xml = CONVERT(XML, ''<R04 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126))) 
                    + ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid) 
                + ''" CType="1'' 
                + ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationTwitterId) 
                + ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126))) 
                + ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion)) 
                + ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''''))) 
                + ''" C05="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalif.[Description], ''N/A''))) 
                + ''" C06="'' + MAX(a.screenNameClient) 
                + ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup)) 
                + ''" C08="'' + MAX(a.screenNameInbound) 
                + ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid)) 
                + ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0)) 
                + ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
                + ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
                + ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
                + ''" C14="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalifsub.califSubdesc, ''N/A''))) 
                + ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), '''')) 
                + ''"/>'')
                     , @dateStart = ISNULL(MIN(b.date), GETDATE()) FROM conversationTwitter a
                                                                        INNER JOIN messageOutTwitter b ON a.conversationTwitterId = b.conversationTwitterId
                                                                        LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
                                                                        LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
                                                                        LEFT OUTER JOIN relationMessageDispositionTwit e ON e.messageOutTwitterId = b.messageOutTwitterId
                                                                        LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = e.dispositionId
                                                                        LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = e.subdispositionId
                                                                                                          AND e.subdispositionId <> 0
                WHERE a.conversationTwitterId = @conversationId
                GROUP BY a.conversationTwitterId
                       , a.inboundid;
            END;
            ELSE
                IF @type = 5
                BEGIN --WhatsApp
                    SELECT @xml = CONVERT(XML, ''<R05 CDATE="'' + CONVERT(VARCHAR(23), ISNULL(conversationDate, requestDate), 126) 
                        + ''" CID="'' + CONVERT(VARCHAR(MAX), A.inboundid) 
                    + ''" CType="1'' 
                    + ''" C01="'' + CONVERT(VARCHAR(MAX), A.conversationId) 
                    + ''" C02="'' + ISNULL(inbound.descripcion, '''') 
                    + ''" C03="'' + ISNULL(ccusers.[Login], '''') 
                    + ''" C04="'' + ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'') 
                    + ''" C05="'' + clientId 
                    + ''" C06="'' + CONVERT(VARCHAR(MAX), tChatting) 
                    + ''" C07="'' + ISNULL(cctipocalif.[Description], ''N/A'') 
                    + ''" C08="'' + ISNULL(cctipocalifsub.califSubdesc, ''N/A'') 
                    + ''" C09="'' + CONVERT(VARCHAR(MAX), A.agentId) 
                    + ''" C10="'' + phoneACD 
                    + ''" C11="'' + CONVERT(VARCHAR(MAX), A.agentId) 
                    + ''" C12="'' + ISNULL(@supervisor, '''') 
                    + ''" C13="'' + ISNULL(@template, '''') 
                    + ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
                    + ''"/>'')
                         , @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversations A
                                                                                   LEFT OUTER JOIN ccinbound inbound ON inbound.inbound_id = A.inboundid
                                                                                   LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId
                                                                                   LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                                                                                   LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
                    WHERE A.conversationId = @conversationId;

                END;

    DECLARE @sql NVARCHAR(MAX), @tableName NVARCHAR(MAX), @columnId NVARCHAR(MAX), @tableNameHistory NVARCHAR(MAX);
    DECLARE @parameterDefinition NVARCHAR(MAX);

    SELECT @tableName = tableName
         , @tableNameHistory = tableNameHistory
         , @columnId = columnId FROM ccFinderServices
    WHERE id = @type;

	SET @parameterDefinition = N''@conversationId bigint,@xml xml,@dateStart datetime'';

    IF @xml IS NOT NULL
    BEGIN        

        SET @sql = ''IF EXISTS(SELECT * FROM '' + @tableNameHistory + '' WHERE ''+@columnId+'' = @conversationId)
        BEGIN
            UPDATE '' + @tableNameHistory + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
        END
        else IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
        BEGIN
            UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
        END
        else begin
            INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, 0);
        end     
        '';
        
    END
	else begin
		 SET @sql ='' IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
        BEGIN
            UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = -1 WHERE ''+@columnId+'' = @conversationId;
        END
        else begin
            INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, -1);
        end '';
	end

	 EXECUTE sp_executesql
                @sql
              , @parameterDefinition
              , @conversationId = @conversationId
              , @xml = @xml
              , @dateStart = @dateStart;

END;'
    EXEC(@sql)

    set @process = 'CW-5781 Alter SP ccspGalatea_Finder'
    set @sql = 'ALTER PROCEDURE [dbo].[ccspGalatea_Finder] @action       INT
                                         , @userId       INT    = 0
                                         , @conversationId BIGINT = 0
AS
     IF @action = 1
     BEGIN--trae el nombre de la base de datos en BX
         SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value]
              , CAST(WGCam.Tipo AS INT) + 1 AS callType
              , c.cam_descripcion AS label FROM ccRIAWorkGroupUsers Wguser
                                                INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                                                INNER JOIN ccCamps c ON WGCam.IdCampEsp = c.cam_id
                                                                        AND WGCam.Tipo = 1
         WHERE Wguser.User_id = @userId
         UNION
         SELECT CAST(WGCam.IdCampEsp AS INT) AS [Value]
              , CAST(WGCam.Tipo AS INT) + 1 AS callType
              , inb.descripcion AS label FROM ccRIAWorkGroupUsers Wguser
                                              INNER JOIN ccRIACampEspWG WGCam ON WGCam.IDWG = Wguser.IDWG
                                              INNER JOIN ccInbound inb ON WGCam.IdCampEsp = inb.Inbound_id
                                                                          AND WGCam.Tipo = 0
         WHERE Wguser.User_id = @userId;
     END;
     ELSE
         IF @action = 2
         BEGIN
             WITH WgId
                  AS (SELECT IDWG FROM ccRIAWorkGroupUsers Wguser WHERE Wguser.User_id = @userId)
                  SELECT DISTINCT
                         CAST(Wguser.User_id AS INT) AS [Value]
                       , ccUsers.Login AS label FROM ccRIAWorkGroupUsers Wguser
                                                     INNER JOIN WgId ON Wguser.IDWG = WgId.IDWG
                                                     INNER JOIN ccUsers ON ccUsers.User_id = Wguser.User_id
                                                                           AND TipoUser_id = 1;
         END;
         ELSE
             IF @action = 3
             BEGIN--Informacion de la conversacion de whatsApp
                 SELECT A.ConversationID
                      , A.inboundId AS AcdId
					  , isnull(graph.graphic_id,1) as GraphicId
                      , A.phoneACD AS PhoneAcd
                      , A.clientId AS PhoneClient
                      , ISNULL(B.descripcion, ''N/A'') AS AcdName
                      , ISNULL(cctipocalif.[Description], ''N/A'') AS Disposition
                      , ISNULL(cctipocalifsub.califSubdesc, ''N/A'') AS SubDisposition
                      , ISNULL(conversationDate, requestDate) DateStart FROM ccWhatsAppConversations A
                                                                             LEFT JOIN ccInbound B ON A.inboundId = B.Inbound_id
                                                                             LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = A.disposition
                                                                             LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = A.subdisposition
																			 left join ccRIAInboundGraph graph on graph.Inbound_id=A.inboundId
                 WHERE A.conversationId = @conversationId;

             END;'
    EXEC(@sql)

    set @process = 'CW-5781 Alter SP ccsp_TwitterSave'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_TwitterSave]
 @action int,
 @conversationId int=0,
 @messageOutTwitterId bigint=null,
 @userId int=0,
 @isLogout bit=0,
 @messageId int =null,
 @messageStatusId int=null,
 @inboundId smallint=null,
 @twitId varchar(255)=null,
 @dispositionId smallint=0,
 @subDispositionId smallint=0,
 @timeAtt int = 0,
 @tWrapUp int =0,
 @tRetention int = 0,

 ---Finder
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0
AS
BEGIN

declare @meanContactTypeId smallint
declare @isEndConversation bit
declare @xmlnode xml

set @meanContactTypeId = 2 --Twitter


 if @action = 1 BEGIN  -- desasignar
	if @messageOutTwitterId = 0 begin
		insert into [messageUnAssingedTwit](messageOutTwitterId,userId,[time],isLogout)
		select messageOutTwitterId,userId,datediff(ss,tQueue,getdate()) as [time],1 from [messageOutTwitter]  where userId=@userId and messageStatusId in (2,3)

		update [messageOutTwitter] set twitId='''',tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0 where userId=@userId and messageStatusId in (2,3)
	end
	else begin
		insert into [messageUnAssingedTwit](messageOutTwitterId,userId,[time],isLogout)
		select messageOutTwitterId,userId,datediff(ss,tQueue,getdate()) as [time],0 as isLogout from [messageOutTwitter] where userId=@userId and messageOutTwitterId=@messageOutTwitterId and messageStatusId in (2,3)

		update [messageOutTwitter] set twitId='''',tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0 where userId=@userId and messageOutTwitterId=@messageOutTwitterId and messageStatusId in (2,3)
	end
END
else if @action = 2 begin --Coloca el valor del TwitId
	update [messageOutTwitter] set twitId=@twitId where messageOutTwitterId=@messageOutTwitterId
end
else if @action = 5 BEGIN --Twitter por contestar
	--Status DOWNLOAD,Assigned,READ,UnaSSIGNED
	select A.conversationTwitterId,B.userId,A.screenNameClient,A.screenNameInbound,B.messageStatusId,B.messageOutTwitterId as messageId
		from conversationTwitter A
		inner join [messageoutTwitter] B on A.conversationTwitterId = B.conversationTwitterId
		where A.inboundId = @inboundId and B.messageStatusId in(1,2,3,4) and meanContactTypeId = @meanContactTypeId
		and b.messageOutTwitterId=(select max(bb.messageOutTwitterId)--esta subconsulta permite conocer el maximo messageOutTwitterId de la conversacion de la consulta principal 
				from messageOutTwitter bb
				inner join conversationTwitter aa on aa.conversationTwitterId = bb.conversationTwitterId
				where bb.conversationTwitterId=aa.conversationTwitterId
				and bb.conversationTwitterId=b.conversationTwitterid 
				and aa.inboundId=@inboundId
				GROUP BY bb.conversationTwitterId)
		GROUP BY A.conversationTwitterId,A.inboundId,A.screenNameClient,A.screenNameInbound,B.messageStatusId,B.userId,b.messageOutTwitterId
END
else if @action = 6 BEGIN --update Time Attention, Retencion
	select @messageId=max(messageOutTwitterId) from messageOutTwitter with(nolock) where conversationTwitterId=@conversationId
	update messageOutTwitter set tResponse=@timeAtt,tRetention=@tRetention,isSender=1,messageStatusId=@messageStatusId where messageOutTwitterId=@messageId
END
else if @action = 7 BEGIN --Cambia el status del mensaje
	select @messageId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId

	--Status Read
	if @messageStatusId=3  update [messageOutTwitter] set tWait=DATEDIFF(ss,tQueue, getdate()) where messageOutTwitterId=@messageId
	--Status Send
	if @messageStatusId=6  begin
		select @isEndConversation=isFinished from conversationTwitter where conversationTwitterId=@conversationId

		if @isEndConversation = 1 set @messageStatusId=11--Close conversation by Agent
		update [messageOutTwitter] set tSend=getdate() where messageOutTwitterId=@messageId

	end
	update [messageOutTwitter] set messageStatusId=@messageStatusId where messageOutTwitterId=@messageId

	--Answered,Send,CLose Conversation system or agent
	if @messageStatusId in (5,6,10,11)  begin
		exec ccsp_CreateNodeMultimedia @type=4, @conversationId=@conversationId		
	end

END
else if @action = 10 begin --Carga las conversaciones pendientes
	if @conversationId = 0 begin
		select A.conversationTwitterId,max(B.messageOutTwitterId) as messageId,B.userId,A.inboundId,max(C.twitId) as twitId
			from conversationTwitter A
			inner join messageOutTwitter B on A.conversationTwitterId = B.conversationTwitterId
			inner join messageInTwitter C on C.conversationTwitterId=B.conversationTwitterId
			where A.meanContactTypeId = @meanContactTypeId
			and B.messageStatusId in(5,7,8,9) and isSender=1 and A.inboundId=@inboundId
			GROUP BY A.conversationTwitterId,A.inboundId,B.userId
	end
	else begin
	select A.conversationTwitterId,max(B.messageOutTwitterId) as messageId,B.userId,A.inboundId,max(C.twitId) as twitId
			from conversationTwitter A
			inner join messageOutTwitter B on A.conversationTwitterId = B.conversationTwitterId
			inner join messageInTwitter C on C.conversationTwitterId=B.conversationTwitterId
			where A.meanContactTypeId = @meanContactTypeId
			and A.conversationTwitterId = @conversationId
			GROUP BY A.conversationTwitterId,A.inboundId,B.userId
	end
end
else if @action = 11 BEGIN --Califica el mensaje y pone el tiempo Notas
	if @subDispositionId <> 0 begin
		select @isEndConversation=isnull(EndConversation,0) from ccTipoCalifSub where califSub_id=@subDispositionId
	end
	else begin
		select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@dispositionId
	end
	if not exists(select * from relationMessageDispositionTwit where messageOutTwitterId=@messageId) begin
		insert into relationMessageDispositionTwit(messageOutTwitterId,dispositionId,subDispositionId) values(@messageId,@dispositionId,@subDispositionId)
	end
	else begin
		update relationMessageDispositionTwit set dispositionId=@dispositionId,subDispositionId=@subDispositionId where messageOutTwitterId=@messageId
	end
	update [messageOutTwitter] set tWrapUp=@tWrapUp where messageOutTwitterId=@messageId
	if @isEndConversation = 1 begin
		select @conversationId=conversationTwitterId from [messageOutTwitter]where messageOutTwitterId=@messageId
		update conversationTwitter set isFinished=@isEndConversation where conversationTwitterId=@conversationId
	end
END
else if @action = 12 BEGIN  --Tiempo de cola
	select @messageId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId
	update [messageOutTwitter] set tQueue=getdate(),userId=@userId where messageOutTwitterId=@messageId
END
else if @action = 13 BEGIN  --Limpia las conversaciones quedaron abiertas por cerrar la aplicacion
	update [messageoutTwitter] set @messageStatusId=1,twitId='''',tQueue=null,userId=0,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0  where messageStatusId in(2,3)
END
else if @action = 14 begin --Asignar una evaluacion
	exec ccsp_CreateNodeMultimedia @type=4, @conversationId=@conversationId,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate
END
else if @action = 15 BEGIN  --Descartar Tweet
	select @messageId=max(messageOutTwitterId) from messageOutTwitter with(nolock) where conversationTwitterId=@conversationId
	
	update messageOutTwitter set messageStatusId=14,userId=@userId,tResponse=@timeAtt,tRetention=@tRetention,isSender=0 where messageOutTwitterId=@messageId   
	update conversationTwitter set isFinished=1 where meanContactTypeId = @meanContactTypeId and conversationTwitterId=@conversationId

	exec ccsp_CreateNodeMultimedia @type=4, @conversationId=@conversationId		

END

END'
    EXEC(@sql)

    set @process = 'CW-5781 Alter SP ccsp_SaveDispositionsMultimedia'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_SaveDispositionsMultimedia] @action         INT
                                                      , @conversationId bigint      = 0
                                                      , @disposition    SMALLINT = 0
                                                      , @subDisposition SMALLINT = 0
                                                      , @tWrapUp        SMALLINT = 0
                                                      , @mediaType      SMALLINT = 0
AS
BEGIN

    SET NOCOUNT ON;

    IF @action = 1
    BEGIN --Califica la conversación y pone el tiempo Notas
        DECLARE @Temp NVARCHAR(1000),@type int
		set @type=CASE @mediaType WHEN 6 then 1 else @mediaType end ---revisar tabla ccfinderServices

		set @Temp= N''UPDATE '' +
                (SELECT CASE @mediaType WHEN 5
                        THEN ''ccWhatsAppConversations'' WHEN 6
                        THEN ''chat'' ELSE ''''
                        END AS MediaTypeString
                ) + '' SET disposition= @disposition ,subDisposition= @subDisposition ,tWrapUp= @tWrapUp WHERE conversationId= @conversationId;'';
        EXEC sp_executesql
             @temp
           , N''@disposition SMALLINT, @subDisposition SMALLINT, @tWrapUp SMALLINT, @conversationId INT''
           , @disposition
           , @subDisposition
           , @tWrapUp
           , @conversationId;


		exec ccsp_CreateNodeMultimedia @conversationId=@conversationId, @type=@type

    END;
END;'
    EXEC(@sql)

    set @process = 'CW-5629,CW-5781 Alter SP ccsp_RIAInsertChat'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAInsertChat]
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
update ccRIAChats set inboundId = @inboundId, chatStatus = @status, userId = case when @userId = 0 then userId else @userId end, tTimeout = @tTimeout where chatId = @chatId
end

else if @action = 3 begin -- Update Status
update ccRIAChats set chatStatus = @status where chatId = @chatId
end

else if @action = 4 begin -- Save Final Status
if @firstMessage = 0
       begin
             update ccRIAChats set finishedBy = @finished, userID =case when @userId = 0 then userId else @userId end where chatId = @chatId
       end
else
       begin
             update ccRIAChats set finishedBy = @finished, firstMessageTime  = @firstMessageTime where chatId = @chatId
       end
end

else if @action in (5,6) begin -- Save Chatting Time /*comentario: la insercion del nodo (registro final para el finder) se recomiendo en esta action, no olvidar validar status = 4, finishedby != null y validar los tiempos para garantizar el dato final */
       if @action = 5 begin
             update ccRIAChats set tChatting = @chattingTime, userId = case when @userId = 0 then userId else @userId end, chatDate = @startTime where chatId = @chatId
       end

	   if @action = 6 begin
			update ccRIAChats set userId = case when @userId = 0 then userId else @userId end  where chatId = @chatId
	   end
	   
	   exec ccsp_CreateNodeMultimedia @conversationId=@chatId, @type=1,@supervisor=@supervisor,@template =@template,@ScoreTemplate=@ScoreTemplate
      
end'
    EXEC(@sql)

    set @process = 'CW-5781 Alter SP ccsp_RIAChatDispositions'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAChatDispositions] @action         SMALLINT
                                               , @chatId         SMALLINT
                                               , @disposition    SMALLINT
                                               , @subDisposition SMALLINT
                                               , @wrapUpTime     SMALLINT = 0
AS
     IF @action = 1
     BEGIN

         UPDATE ccRIAChats
                SET
                    disposition = @disposition
                  , subDisposition = @subDisposition
                  , tWrapUp = @wrapUpTime
         WHERE chatId = @chatId;
         
		 exec ccsp_CreateNodeMultimedia @conversationId=@chatId, @type=1
		 		 

     END;'
    EXEC(@sql)

    set @process = 'CW-5781 Alter SP ccsp_MailSave'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_MailSave]
@action int,
@uid varchar(max)=null,
@date datetime=null,
@conversationId int=0,
@inboundId smallint=null,
@userId smallint=0,
@messageStatusId int=null,
@isInbox bit=1,
@messageId int =null,
@timeAtt int = 0,
@pathFile varchar(255)= null,
@mailClient varchar(255)= null,
@mailACD varchar(60)= null,
@isSender bit=0,
@isUser bit = 0,
@info varchar(255)=null,
@dispositionId smallint=0,
@subDispositionId smallint=0,
@tWrapUp int =0,
@tRetention int = 0,
@email varchar(255) = null,

---Finder
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0,
@top int=30,

---Embedded images
@contentId varchar(255)=null,
@isEmbedded bit = null
AS
BEGIN


declare @isEndConversation bit
declare @meanContactTypeId smallint
declare @xmlnode xml
declare @existAttached bit, @numInteracion smallint
declare @ids varchar(max)

set @meanContactTypeId = 1
SET NOCOUNT ON;

if @action = 1 begin --find uid ConversationMail
if not exists(select A.uid,C.mailInbound from messageMail A 
    inner join [message] B on A.messageId=B.messageId
    inner join [conversation] C on C.conversationId=B.conversationId
    where A.[uid]=@uid and C.mailInbound=@mailACD) 
    select 0
else select 1
  return (0)
end
else if @action = 2 BEGIN --new Conversation
    if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin
        insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)
        select @conversationId=SCOPE_IDENTITY()
        insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,0,@date,@messageStatusId)
        select @messageId=SCOPE_IDENTITY()
        insert into [messageMail](messageId,[uid]) values (@messageId,@uid)
        select @conversationId as ConversationId,@messageId as MessageId,0 as LastUserId
        return (0)
    end
    else begin
        select 0 as ConversationId,0 as MessageId,0 as LastUserId
        return (0)
    end
END
else if @action = 3 BEGIN --new Messages
    if @date is null set @date=getdate()
    if @mailACD is null select @mailACD=mailInbound from conversation where conversationId=@conversationId
    if not exists(select * from [conversation] where conversationId=@conversationId) begin --si el id conversacion no existe
        insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)
        select @conversationId=SCOPE_IDENTITY()
    end

    if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin     
        insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,@userId,@date,@messageStatusId)
        select @messageId=SCOPE_IDENTITY()
    end
    else begin
        select 0 as ConversationId,0 as MessageId,0 as LastUserId
        return (0)
    end

    if @uid is null --for outbound messages
        select @uid = dbo.md5(cast(@conversationId as varchar(10)) + ''_'' + cast(@messageId as varchar(10)))

    insert into [messageMail](messageId,[uid]) values (@messageId,@uid)

    --Finder
    select @existAttached =case when count(*)>0 then 1 else 0 end  from attached where messageId in (select messageId from message where conversationId=@conversationId)
    select @numInteracion = count(*) from message where conversationId=@conversationId
    
	--Actualiza un nodo del finder	
    exec ccsp_CreateNodeMultimedia @type=3, @conversationId=@conversationId
    
    select @conversationId as ConversationId,@messageId as MessageId,0 as LastUserId

END
else if @action = 4 BEGIN --new attachment
	insert into [attached](messageId,pathFile,isUser,contentId,isEmbedded) values(@messageId,@pathFile,@isUser,@contentId,@isEmbedded)
    select SCOPE_IDENTITY() as attachedId
END
else if @action = 5 BEGIN --Correos por contestar Status DOWNLOAD,Assigned,READ,UnaSSIGNED   
	select top(@top) A.conversationId,B.userId,A.mailClient,A.mailInbound,A.info,B.messageStatusId,B.messageId from (
	select A.conversationId,max(A.mailClient) as mailClient ,max(A.mailInbound) as mailInbound,min(A.info) as info,
		max(B.messageId) as messageId from conversation  A 
	inner join message B on A.conversationId = B.conversationId
	where A.inboundId = @inboundId and A.isFinished=0 and meanContactTypeId = @meanContactTypeId
	group by A.conversationId
	) A 
	inner join message B on A.conversationId = B.conversationId and A.messageId = B.messageId
	where B.messageStatusId in(1,2,3,4)

END
else if @action = 6 BEGIN --update Time Attention, Retencion
    select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
    update [message] set tResponse=@timeAtt,tRetention=@tRetention,isSender=@isSender,messageStatusId=@messageStatusId,userId=@userId where messageId=@messageId
END
else if @action = 7 BEGIN --Cambia el status del mensaje
    select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
    --Status Read
    if @messageStatusId=3  update [message] set tWait=DATEDIFF(ss,isnull(tQueue,getdate()), getdate()) where messageId=@messageId

    --Status Send
    if @messageStatusId=6  begin
        select @isEndConversation=isFinished from conversation where conversationId=@conversationId
        if @isEndConversation = 1 set @messageStatusId=11--Close conversation by Agent
        update [message] set tSend=getdate() where messageId=@messageId
    end
    update [message] set messageStatusId=@messageStatusId where messageId=@messageId

    --Answered,Send,CLose Conversation system or agent
    if @messageStatusId in (5,6,10,11)  begin
        exec ccsp_CreateNodeMultimedia @type=3, @conversationId=@conversationId
    end

END
else if @action = 8 BEGIN --info del ultimo correo
    select messageId,GP.inboundId,C.connUser mailInbound,mailClient,mediaType,messageStatusId,info,I.descripcion,IG.graphic_id,I.tNotas,isnull(C.answerTimeOut,10) tTimeOut,C.timeAlertMessage tAlert
    from (
        select max(B.messageId) messageId,A.inboundId,A.mailClient, case A.meanContactTypeId when 1 then 3 else -1 end mediaType, B.messageStatusId, max(A.info) info
        from conversation A inner join message B  on A.conversationId = B.conversationId  where A.conversationId=@conversationId  GROUP BY A.inboundId,A.mailClient, A.meanContactTypeId, B.messageStatusId, B.userId) GP
    inner join contactMeanIn C on C.inboundId=GP.inboundId
    inner join ccInbound I on I.Inbound_id=GP.inboundId
    inner join ccRIAInboundGraph IG on IG.Inbound_id=GP.inboundId
END
else if @action = 9 BEGIN --carga adjuntos del ultimo mensaje
    if @conversationId is null or @conversationId=0 begin
        set @conversationId=0
        select @conversationId=conversationId from message where messageId=@messageId 
    end
    
    select pathFile as NameFile,isUser from attached A
    inner join message B on A.messageId=B.messageId and B.conversationId=@conversationId
    where B.conversationId=@conversationId
END
else if @action = 10 BEGIN --Correos por enviar
    select A.conversationId as ConversationId,B.messageId as MessageId,B.userId as AgentId,A.inboundId as AcdId,A.mailInbound as MailInbound
	 from (
	select A.inboundId,A.conversationId as ConversationId,max(B.messageId) as MessageId,A.mailInbound   from conversation A 
	inner join message B on A.conversationId = B.conversationId
	where A.meanContactTypeId = 1 and A.inboundId = @inboundId
	GROUP BY A.conversationId,A.inboundId,A.mailInbound 
	) A
	inner join message B on A.MessageId = B.messageId
	where B.messageStatusId in(5,7,8,9) 
END

else if @action = 11 BEGIN --Califica el mensaje y pone el tiempo Notas
    if @subDispositionId <> 0 begin
        select @isEndConversation=isnull(EndConversation,0) from ccTipoCalifSub where califSub_id=@subDispositionId
    end
    else begin
        select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@dispositionId
    end
    if not exists(select * from relationMessageDisposition where messageId=@messageId) begin
        insert into relationMessageDisposition(messageId,dispositionId,subDispositionId) values(@messageId,@dispositionId,@subDispositionId)
    end
    else begin
        update relationMessageDisposition set dispositionId=@dispositionId,subDispositionId=@subDispositionId where messageId=@messageId
    end
        update message set tWrapUp=@tWrapUp where messageId=@messageId
        if @isEndConversation = 1 begin
        select @conversationId=conversationId from [message] where messageId=@messageId
        update conversation set isFinished=@isEndConversation where conversationId=@conversationId
    end
END
else if @action = 12 begin --Tiempo de cola
    select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
    update [message] set tQueue=getdate(),userId=@userId where messageId=@messageId
end
else if @action = 13 BEGIN  -- desasignar
    if @messageId = 0 begin
        insert into [messageUnAssigned](messageId,userId,[time],isLogout)
        select messageId,userId,datediff(ss,tQueue,getdate()) as [time],1 as isLogout from [message] where userId=@userId and messageStatusId in (2,3)
        update [message] set tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0 where userId=@userId and messageStatusId in (2,3)
    end
    else begin
        insert into [messageUnAssigned](messageId,userId,[time],isLogout)
        select messageId,userId,datediff(ss,tQueue,getdate()) as [time],0 as isLogout from [message] where userId=@userId and messageId=@messageId and messageStatusId in (2,3)
        update [message] set tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0 where userId=@userId and messageId=@messageId and messageStatusId in (2,3)
    end
end
else if @action = 14 begin
 update [message] set @messageStatusId=1,tQueue=null,userId=0,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0  where messageStatusId in(2,3)
end
else if @action = 15 begin
    SELECT @existAttached = case when count(*)>0 then 1 else 0 end
    from attached where messageId in (select messageId from message where conversationId=@conversationId)

    select max(B.messageId) as MessageID, cast(max(A.inboundid) as int) as InboundID, max(A.conversationid) as ConversationID,
        max(A.mailClient) as ClientEmail, min(B.[date]) as [Date], @existAttached isAttached, max(C.descripcion) as ACDName,
        max(B.tSend) as tSend, max(D.Nombres+'' ''+D.ApellidoPaterno+'' ''+D.ApellidoMaterno) as NameAgent,
        cast(max(E.timeAlertMessage) as int) tAlertMessage, cast(max(E.answerTimeOut) as int) tAnswerTimeOut, max(C.tNotas) as tWrapUp,
        max(A.mailInbound) as InboundEmail, isnull(max(E.name), '''') as SenderName, cast(max(F.graphic_id) as int) as ACDGraphicID,
		max(B.[date]) MsgTimestamp, cast(max(case when C.inbound_id = H.inboundId then 1 else 0 end) as bit) as IsAzure
    from conversation A
    inner join message B  on A.conversationId = B.conversationId
    inner join ccinbound C on A.inboundid= C.inbound_id
    left join ccUsers D on B.userId = D.User_id
    inner join contactMeanIn E on E.inboundId=C.Inbound_id and E.meanContactTypeId=@meanContactTypeId
	inner join ccRIAinboundGraph F on C.Inbound_id = F.Inbound_id
	inner join ccRIAGraphics G on F.graphic_id = g.graphic_id
	left join contactMeanInAzure H on C.Inbound_id = H.inboundId
    where A.conversationId=@conversationId
end
else if @action = 16 begin
    select A.inboundid,B.messageid,a.conversationid,c.pathFile
    from conversation A
    inner join message B  on A.conversationId = B.conversationId
    inner join attached C on B.messageid= C.messageid
    where A.conversationId=@conversationId
end
else if @action = 17 begin --Asignar una evluacion
	exec ccsp_CreateNodeMultimedia @type=3, @conversationId=@conversationId,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate    
end
else if @action = 18 begin --cerrar conversacion por tiempo
    if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date)
    if @conversationId = 0
        select 0
    else begin
        declare @closeConversation tinyint
        declare @tRsponse datetime
        select @tRsponse = isnull(max(tSend), getdate()) from message where messageId = @conversationId
        select @closeConversation = closeConversationTime from contactMeanIn
         if datediff(dd,getdate(),@tRsponse ) > @closeConversation
            select 0
        else
            select @conversationId
        end
    return 0
end
else if @action = 19 begin
    select isnull(max(C.Uid),0) [maxUid] from conversation A
    inner join message B on A.conversationId=B.conversationId
    inner join messageMail C on C.messageId=B.MessageId
    where inboundId=@inboundId and mailInbound=@mailACD
end
else if @action = 20 begin
    if @messageId is null begin
        select @ids=COALESCE(@ids + '','', '''') + cast(messageId as varchar(max))  from message where conversationId=@conversationId
        select @inboundId=inboundId from conversation where conversationId=@conversationId
        select @ids as ids,@inboundId as inboundId
    end
    else begin
        select case when count(*)>0 then 1 else 0 end  from attached where messageId=@messageId
    end
end
else if @action = 21 begin
    declare @isFinished bit
    set @isFinished = 0

    select @isFinished=isFinished from conversation where conversationId=@conversationId
    select @isFinished
end
else if @action = 22 begin
   
   declare @correo varchar(255)
   select  @correo = mailClient from conversation where conversationId = @conversationId      
   
   insert into emailSpam (inboundId,agentId,conversationId,correo,fecha) values (@inboundId,@userId,@conversationId,@correo,getDate())   

   update Conversation set isFinished = 1 where mailClient = @correo
   update message set messageStatusId = 13 where messageId = @messageId

   select distinct conversationId as ConversationId,inboundId as AcdId from emailSpam where correo = @correo

end
else if @action = 23 begin      
   if exists (select  * from emailSpam where correo like ''%''+@email+''%'') begin
        select 1
   end
   else begin
        select 0 
   end
end
else if @action = 24 begin      
	select count(*) as [Amount] from attached A inner join message B on A.messageId=B.messageId 
	where A.messageId = @messageId and isEmbedded = 1
end
else if @action = 25 begin      
	select pathFile as NameFile from attached A inner join message B on A.messageId=B.messageId 
	where A.messageId = @messageId and contentId = @contentId and isEmbedded = 1
end
else if @action = 26 begin      -- Discard Email
	update conversation set isFinished = 1 where conversationId = @conversationId
	update message set messageStatusId = 14, userId = @userId where messageId = @messageId
end
else if @action = 27 begin
	select count(*) as [Amount] 
	from attached nolock where messageId in (select messageId from message nolock where conversationId=@conversationId)
end
else if @action = 28 begin --carga adjuntos del ultimo mensaje para cuentas Azure
    if @conversationId is null or @conversationId=0 begin
        set @conversationId=0
        select @conversationId=conversationId from message where messageId=@messageId 
    end
    
    select pathFile as NameFile, contentId [ContentId], isEmbedded [IsEmbedded] from attached A
    inner join message B on A.messageId=B.messageId and B.conversationId=@conversationId
    where B.conversationId=@conversationId
end

END'
    EXEC(@sql)

    

    set @process = 'CW-5781 Alter SP ccsp_ConversationWASave'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
                                              , @conversationId     INT         = 0
                                              , @inboundId          SMALLINT    = NULL
                                              , @phoneACD           VARCHAR(50) = NULL
                                              , @clientId           VARCHAR(25) = NULL
                                              , @conversationStatus SMALLINT    = 0
                                              , @tChatting          SMALLINT    = 0
                                              , @tWrapUp            SMALLINT    = 0
                                              , @finishedBy         TINYINT     = 0
                                              , @onQueue            BIT         = NULL
                                              , @tQueue             SMALLINT    = 0
                                              , @tTimeout           INT         = 0
                                              , @disposition        SMALLINT    = 0
                                              , @subDisposition     SMALLINT    = 0
                                              , @agentId            INT
AS
BEGIN
    DECLARE @isEndConversation BIT;
    DECLARE @meanContactTypeId SMALLINT;

    SET @meanContactTypeId = 1;
    SET NOCOUNT ON;

    IF @action = 1
    BEGIN --new Conversation
        IF NOT EXISTS
                      (SELECT A.conversationId conversationId FROM ccWhatsAppConversations A
                       WHERE A.conversationId = @conversationId
                      )
        BEGIN
            INSERT INTO [ccWhatsAppConversations]
            (inboundId
           , phoneACD
           , clientId
           , conversationStatus
           , tChatting
           , tWrapUp
           , finishedBy
           , onQueue
           , tQueue
           , tTimeout
           , disposition
           , subDisposition
           , agentId
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
            SELECT @conversationId = SCOPE_IDENTITY();
            SELECT @conversationId AS ConversationId;
            RETURN(0);
        END;
        ELSE
        BEGIN
            SELECT 0 AS ConversationId;
            RETURN(0);
        END;
    END;

    IF @action = 2
    BEGIN --save conversation Times
        UPDATE ccWhatsAppConversations
               SET
                   tChatting = DATEDIFF(ss, conversationDate, GETDATE())
                 , conversationStatus = @conversationStatus
                 , finishedBy = 1
                 , tConversation = DATEDIFF(ss, requestDate, GETDATE())
        WHERE conversationId = @conversationId;


		exec ccsp_CreateNodeMultimedia @conversationId=@conversationId, @type=5

    END;

    IF @action = 3
    BEGIN --save conversation Status
        UPDATE ccWhatsAppConversations
               SET
                   conversationDate = GETDATE()
                 , conversationStatus = @conversationStatus
        WHERE conversationId = @conversationId;
    END;
END;'
    EXEC(@sql)

    set @process = 'CW-5781 Alter SP ccsp_BaseXmngr'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@ids varchar(max)=null,
@name varchar(25) = NULL,
@top int = 0,
@dateIni datetime =null,
@dateEnd datetime =null,
@dateStart dateTime= null,
@userId int = 0
AS

declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
set @sql = ''''

select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=@option 

if @action in (1,6) begin --obtiene los nodos a insertar en BX
    if @action = 1 set @status =0
    else if @action = 6 set @status = 2

    if @option <>2 begin

    declare @auxTag nvarchar(10)
    
    select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02''
	else ''@CDATE''	end
    set @parameterDefinition =N''@status int, @top int,@option int''
    set @sql=''declare @basexName varchar(max)
select @basexName=Xname from ccBaseXDB where serviceId=@option and isFull=0;
    with node ( ''+@columnId+ '',xmlString,dateNode)
    AS(
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableName + '' A with(rowlock)
        where A.status =@status
        union
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableNameHistory + '' A with(rowlock)
        where A.status =@status  
    )

    select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
    left join ccBaseXDB baseX on baseX.serviceId= @option and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
    order by baseX.Xname''
	--print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top,@option=@option
    end
end
else if @action in (2,7) begin--actualiza los nodos insertados en BX
    if @action = 2 set @status =0
    else if @action = 7 set @status = 2

    set @parameterDefinition =N''@status int''

    set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    select @tableName,@columnId,@ids,@sql
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
    set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status

end
else if @action = 3 --trae el nombre de la base de datos en BX
begin
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
    insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
end
else if @action = 5 begin --obtener servicios disponibles    
    select id, ref  from ccFinderServices where isActive=1
end
else if @action = 8 begin--trae la lista de las bases para la busqueda
    select Xname from ccBaseXDB where serviceId = @option
    and (

    @dateIni between dateStart and dateEnd
    or @dateEnd between dateStart and dateEnd
    or dateStart between @dateIni and @dateEnd
    )
    union
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
    and (
        dateStart between @dateIni and @dateEnd
        or @dateIni>=dateStart

    )
end
else if @action = 9 begin--Cierra la base datos
       update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()), dateStart=isnull(@dateStart,dateStart) where serviceId= @option and  isfull = 0 and dateEnd is null
       and Xname=@name
end

else if @action = 10 begin
    declare @filterWg varchar(max)
    declare @len int
    set @filterWg=''''
         
        select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId
         
        set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
        select SUBSTRING(@filterWg,0, @len)
end


else if @action = 11 begin--trae el nombre de la base de datos en BX

	set @sql=''
	declare @dateStart datetime
	set @dateStart= convert(datetime,convert(varchar(10),getdate(),121))
	SELECT isnull(min(dateIn),@dateStart) as node FROM ''+@tableName+'' where status = 0	''
    EXECUTE sp_executesql  @sql

end'
    EXEC(@sql)

    set @process = 'SorteosTec - mejoramiento en tiempos de respuesta y estado en dialogo correcto'
    set @sql = '
	ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS     INT, 
                                                            @sup_id AS   INT = 0, 
                                                            @agent_id AS INT = 0, 
                                                            @WG AS       INT = 0,
															@AgentsIds as VARCHAR(MAX) = '''',
															@campId AS INT = 0,
															@CampType AS SMALLINT = 1
            AS
             SET NOCOUNT ON;
             IF @type = 1
                 BEGIN
                     WITH TableUserAgent(userId)
                          AS (SELECT DISTINCT 
                                   wgAgt.User_id  AS Id --,usr.login 
                              FROM ccriaworkgroupusers wgAdmin
                                   INNER JOIN ccriaworkgroupusers wgAgt ON wgAdmin.IDWG = wgAgt.IDWG
                                   INNER JOIN ccUsers usr ON usr.User_id = wgAgt.User_id
                                                             AND usr.TipoUser_id = 1
                              WHERE wgAdmin.User_id = @sup_id)
                          SELECT CAST(a.User_id AS INT) Id, 
                                 a.login AS Username, 
                                 a.Nombres + '' '' + a.ApellidoPaterno + '' '' + a.ApellidoMaterno AS Name
                          FROM ccusers a(NOLOCK)--, ccGenViewRelsSupsAgent b
                               INNER JOIN TableUserAgent b ON a.User_id = b.userId
                          ORDER BY a.Login ASC;
             END;
             IF @type = 2
                 BEGIN
                    SELECT CAST(u.User_id AS INT) Id,
					Login Username, 
                    Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno Name,
					CASE WHEN p.publicIp is null or p.publicIp = '''' then ''000.000.000.000'' else p.publicIp end IP
					FROM ccUsers u
					LEFT JOIN ccPosicion p on p.user_id = @agent_id
					WHERE u.User_id = @agent_id;
             END;
             IF @type = 3 --Agents by supervisor and WG
                 BEGIN
                     DECLARE @table2 TABLE
                     (userId INT
                      PRIMARY KEY NOT NULL
                     );
                     INSERT INTO @table2
                            SELECT DISTINCT 
                                   wg.User_id
                            FROM ccRIAWorkGroupUsers wg
                                 LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                            WHERE us.TipoUser_id = 1
                                  AND wg.IDWG IN
                            (
                                SELECT IDWG
                                FROM ccRIAWorkGroupUsers
                                WHERE User_id = @sup_id
                                      AND IDWG <> @WG
                            );
                     SELECT CAST(B.User_id AS int) AS Id
                     FROM @table2 A
                          RIGHT JOIN
                     (
                         SELECT DISTINCT 
                                wg.User_id
                         FROM ccRIAWorkGroupUsers wg
                              LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                         WHERE wg.IDWG = @WG
                               AND us.TipoUser_id = 1
                     ) B ON A.userId = B.User_id
                     WHERE A.userId IS NULL;
             END;

           IF @type = 4 --Agents IDs by WG
             BEGIN
            SELECT  CAST(wg.User_id AS INT) Id  
            FROM ccRIAWorkGroupUsers wg
            JOIN CCUsers u on u.user_id = wg.user_id AND u.TipoUser_id = 1
            where IDWG = @WG
             END;

           IF @type = 5 --Agents IDs by Campaign
             BEGIN
            SELECT Distinct(CAST(U.User_id AS INT)) Id FROM ccRIACampEspWG camp
            JOIN ccRIAWorkGroupUsers wg ON camp.IDWG = wg.IDWG
            JOIN ccUsers U ON U.User_id = WG.User_id AND U.TipoUser_id = 1
            WHERE IdCampEsp = @campId AND TIPO = @CampType
             END;

            IF @type = 6 -- Get Agent current state
           BEGIN
            WITH UserMaxFecha(User_id,fecha) as(
              SELECT User_id,max(fecha) as fecha from ccLogAgentesDia where fecha>=convert(date,getdate()) group by User_id
            )

            SELECT CASE WHEN CurrentState.currentStatus is null or  CurrentState.currentStatus<0 
                  then 0 else CAST(CurrentState.currentStatus as int) end CurrentState
            from ccUsers u
            left join 
            (
            select A.User_id,B.currentStatus from UserMaxFecha A 
            inner join ccLogAgentesDia  B on A.User_id=B.User_id and A.fecha=B.fecha
            ) CurrentState on u.User_id=CurrentState.User_id
            where u.TipoUser_id=1 and u.User_id = @agent_id
           END

           IF @type = 7 -- Get superuser id''s except root
           BEGIN
            declare @superuserId as int
            set @superuserId = (select Rol_id from ccRoles where Level = 7) -- obtenemos el id del rol superusuario

            select CAST(cr.User_id AS INT) User_id 
            from ccUsers_Roles cr
            where Rol_id = @superuserId
            and cr.User_id not in (1) 
           END

           IF @type = 8 -- Get all Agent''s ID, Login and Full Names related to a workgroup
           BEGIN
				declare @dateStart datetime

				set @dateStart=convert(date,getdate())

				;with lastState As(
				select user_id,max(fecha) dateStart from ccLogAgentesDia with(nolock) where  fecha>@dateStart group by user_id
				), wgAgt as
				(
				select distinct A.User_id, us.Login Username, --se agrega distinct porque el agente si puede estar en dos grupos de trabajo diferentes
				us.Nombres + '' '' + us.ApellidoPaterno + '' '' + us.ApellidoMaterno Name
				from ccRIAWorkGroupUsers A
				inner join ccusers us on A.User_id=us.User_id 
				where IDWG=@WG and us.TipoUser_id=1
				)

				select Convert(INT,us.User_id) as Id, us.Username as Username,
							  us.Name							  
							  , LastStateId= CASE WHEN B.currentStatus is null or  B.currentStatus<0 
								  then 0 else B.currentStatus  
								  end
							  from wgAgt us
				left join lastState A on A.User_id=us.User_id
				left join ccLogAgentesDia B on A.User_id=B.User_id and A.dateStart=B.fecha
           END

		   IF @type = 9 -- GET AGENT IP
			   BEGIN
					SELECT publicIp FROM ccPosicion where user_id = @agent_id
			   END

			IF @type = 10 -- GET ONLINE AGENTS IP
				BEGIN
					SELECT CAST ( user_id AS INT )    AgentId,  publicIp Ip FROM ccPosicion where user_id <> 0
				END

		   IF @type = 11
		   BEGIN
				WITH UserMaxFecha(User_id,fecha) as(
				  SELECT User_id,max(fecha) as fecha from ccLogAgentesDia where fecha>=convert(date,getdate()) group by User_id
				)

				SELECT CAST(u.User_id AS INT) as UserId, CASE WHEN CurrentState.currentStatus is null or  CurrentState.currentStatus<0 
					  then 0 else CAST(CurrentState.currentStatus as int) end CurrentState
				from ccUsers u
				left join 
				(
				select A.User_id, B.currentStatus from UserMaxFecha A 
				inner join ccLogAgentesDia  B on A.User_id=B.User_id and A.fecha=B.fecha
				) CurrentState on u.User_id=CurrentState.User_id
				where u.TipoUser_id=1 and u.User_id in (select value from dbo.fn_RIASplitDelimited(@AgentsIds, '','')) 
				--and CurrentState.currentStatus = 4 or CurrentState.currentStatus = 5
		   END

           SET NOCOUNT ON;
	
	'

    EXEC(@sql)

    set @process = 'CW-5476 drop procedure ccsp_GalateaAdminSubdispositionRelations'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSubdispositionRelations'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminSubdispositionRelations;
            end'
    EXEC(@sql)

    set @process = 'CW-5476 create procedure ccsp_GalateaAdminSubdispositionRelations'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSubdispositionRelations]
@command int,
@type tinyint = null, --0=Outbound, 1=Inbound
@califSub_id varchar(max) = null,
@calif_id smallint = null
AS
set nocount on

If @command = 1
begin
	select cast(1 as int) [type],
		r.calif_id,
		r.califSub_id
	from cctipoSubCalifRel r inner join ccTipoCalifSub t on r.califSub_id = t.califSub_id and r.tipoSubRel = 1
	where t.califSub_Status = 1
	UNION
	select cast(0 as int) [type],
		r.calif_id,
		r.califSub_id
	from cctipoSubCalifRel r inner join ccTipoCalifSubOUT t on r.califSub_id = t.califSub_id and r.tipoSubRel = 0
	where t.califSubOut_Status = 1
	order by [type] desc, calif_id, califSub_id
end
if @command=2  --Asignar subcalificacion a una calificacion
begin
	if @type=1 and (select cast(sum(isnull(cast(canReprogram as tinyint),0)) as bit) FROM cctipocalifSub where califSub_id in
	(select value from dbo.fn_RIASplitDelimited (@califSub_id, '','')))>0 
	and exists (select IB.Inbound_id from cctipocalif CO join ccCalifCamp CF on  CF.calif_id = CO.calif_id and CF.tipo = 0 
	join ccInbound IB on IB.Inbound_id = CF.cam_id where IB.cam_id is null and CO.calif_id = @calif_id)
	begin
		select cast(-2 as smallint) [result]	-- Cant reprogram, there are not assigned campaign
		return(0)
	end

	insert cctipoSubCalifRel (calif_id, califSub_id, tipoSubRel)
	select @calif_id [calif_id], S.value [califSub_id], @type [Tipo]
	from dbo.fn_RIASplitDelimited (@califSub_id, '','') S
	where cast(@calif_id as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@type as varchar(10)) not in
   (select cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) from cctipoSubCalifRel)
	and S.value is not null

	if @type=0
	begin
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end
	
	select cast(1 as smallint) [result]	 -- Done! 
	return(0)
end
if @command=3	--Desasignacion de subcalificacion
begin
	delete cctipoSubCalifRel
    where cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) in
    (select cast(@calif_id as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@type as varchar(10))
    from dbo.fn_RIASplitDelimited (@califSub_id, '','') S)

    if @type=0
	begin
      update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end
end

set nocount off'
    EXEC(@sql)
	
	set @process = 'ccsp_GalateaConfAggrFct - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaConfAggrFct'')
            begin
          DROP PROCEDURE ccsp_GalateaConfAggrFct;
            end'
    EXEC(@sql)

	set @process = 'SP Calls by Agent'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaConfAggrFct]
@Type tinyint,    -- 1:Muestra | 2:Actualiza Camp | 3:Actualiza Todas por Usuario
@cam_id varchar(255) = null,
@User_id int = null,
@aggressionFactor float = null
AS
set nocount on
if @Type=1
 begin
	if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
			select cam_id, cam_Descripcion, aggressionFactor
			from ccCamps where cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
			order by cam_descripcion
		end
		else begin
			select cam_id, cam_Descripcion, aggressionFactor from ccCamps where cam_activo <> 0 and IDArea is not null
		end
    return(0)
 end

if @Type=2
 begin
    UPDATE ccCamps SET aggressionFactor = isnull(@aggressionFactor,aggressionFactor) 
    Where cam_id in (select value from dbo.fn_RIASplitDelimited(@cam_id, '',''))

	if @@ROWCOUNT > 0
		select cam_id, aggressionFactor from ccCamps Where cam_id in (select value from dbo.fn_RIASplitDelimited(@cam_id, '',''))
    return(0)
 end

if @Type=3
 begin
	if @user_id > 0 and not exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
			UPDATE ccCamps SET aggressionFactor = isnull(@aggressionFactor,aggressionFactor)
			Where cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))

			if @@ROWCOUNT > 0
				select cam_id, aggressionFactor from ccCamps where cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
		end
		else begin
			UPDATE ccCamps SET aggressionFactor = isnull(@aggressionFactor,aggressionFactor)
			where cam_activo <> 0 and IDArea is not null

			if @@ROWCOUNT > 0
				select cam_id, aggressionFactor from ccCamps where cam_activo <> 0 and IDArea is not null
		end
    return(0)
 end

set nocount off
'
    EXEC(@sql)

	    set @process = 'CW-5781 update ccFinderServices isActive=1'
	    set @sql = 'update ccFinderServices set isActive=1 where id<=5'
	    EXEC(@sql)

	    set @process = 'CW-5750 Create table ccVonageConfigurations'
	    set @sql = 'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[ccVonageConfigurations]'') AND type in (N''U''))
					BEGIN
					CREATE TABLE [dbo].[ccVonageConfigurations](
						[vonageId][int] IDENTITY(1,1) NOT NULL, 
						[serviceType][smallint] NOT NULL,
						[applicationId] [varchar](50) NOT NULL,
						[secretKey] [varchar](MAX) NOT NULL,
						[messagesUrl] [varchar](50) NOT NULL, 
						PRIMARY KEY (vonageId))
					END'
	    EXEC(@sql)

	    set @process = 'CW-5750 Create table WhatsAppNumbers'
	    set @sql = 'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[ccWhatsAppNumbers]'') AND type in (N''U''))
					BEGIN
					CREATE TABLE [dbo].[ccWhatsAppNumbers](
						[vonageId][int] NOT NULL, 
						[number] [varchar](30) NOT NULL,
						[inboundId] [int] NOT NULL DEFAULT(0),
						[status] [bit] NOT NULL DEFAULT (0),
						PRIMARY KEY (number))
					END'
	    EXEC(@sql)

	    set @process = 'CW-5750 Drop procedure ccsp_MultimediaConfigurations'
	    set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_MultimediaConfigurations'')
		            BEGIN
		          		DROP PROCEDURE ccsp_MultimediaConfigurations;
		            END'
	    EXEC(@sql)

	    set @process = 'CW-5750 Create procedure ccsp_MultimediaConfigurations'
	    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_MultimediaConfigurations] 
					@Option AS SMALLINT,
					@ServiceType AS SMALLINT = 0
					AS
					BEGIN
					    SET NOCOUNT ON;
						BEGIN
					    IF(@Option = 1) -- Get Vonage Configurations depending the Service Type 
							BEGIN
								SELECT applicationId AS ApplicationId,
									   secretKey AS SecretKey,
									   messagesUrl AS MessagesUrl
								FROM ccVonageConfigurations
								WHERE serviceType = @ServiceType   -- 5 = WhatsApp
							END 

						IF(@Option = 2) -- Get WhatsApp registered numbers 
							BEGIN
								SELECT number AS AvailableNumbers FROM ccWhatsAppNumbers Numbers 
								INNER JOIN ccVonageConfigurations Configurations 
								ON Numbers.vonageId = Configurations.vonageId 
								AND Numbers.inboundId = 0 
								AND Numbers.status = 1 
								AND Configurations.serviceType = 5
							END 
						END
					END'
	    EXEC(@sql)

	    set @process = 'CW-5750 Drop procedure ccsp_UpdateACDWhatsappConfig'
	    set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_UpdateACDWhatsappConfig'')
		            BEGIN
		          		DROP PROCEDURE ccsp_UpdateACDWhatsappConfig;
		            END'
	    EXEC(@sql)

	    set @process = 'CW-5750 Create procedure ccsp_UpdateACDWhatsappConfig with inbound id insertion in ccWhatsAppNumbers table'
	    set @sql = 'CREATE procedure  [dbo].[ccsp_UpdateACDWhatsappConfig]

					@ConexionInfo varchar(400),
					@inbound_id int,
					@ConnUser varchar(60),
					@tNotas int,
					@closeConversationTime tinyint,
					@ShowCalifWnd bit 

					AS
					set nocount on
					    IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
					    BEGIN
					        UPDATE contactMeanIn SET conexionInfo = @conexionInfo, connUser = @connUser, closeConversationTime = @closeConversationTime where inboundId = @inbound_id;
							UPDATE ccWhatsAppNumbers SET inboundId = @inbound_id WHERE number = @conexionInfo
					    END;

					    IF EXISTS (SELECT Inbound_id FROM ccInbound WHERE Inbound_id = @inbound_id) 
					    BEGIN
					        UPDATE ccInbound SET tNotas = @tNotas, ShowCalifWnd = @ShowCalifWnd where Inbound_id = @inbound_id;
					    END;
					SELECT @inbound_id;
					return(@inbound_id)

					set nocount off'
	    EXEC(@sql)
		
		set @process = 'CW-5786 crea tabla ccWAMessagesConversations'
    set @sql = 'IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[ccWAMessagesConversations]'') AND type in (N''U''))
BEGIN
CREATE TABLE [dbo].[ccWAMessagesConversations](
	[messageId] [varchar](75) NOT NULL,
	[conversationId] [int] NOT NULL,
	[timeStampMessage] [datetime] NOT NULL,
	[originType] [varchar](15) NOT NULL,
	[price] [varchar](10) NOT NULL,
	[messageIdUi] [int] NULL,
	[currency] [varchar](10) NULL,
	[typeMessage] [varchar](25) NULL,
	[content] [varchar](max) NULL,
	[clientNum] [varchar](15) NULL,
	[vonageNum] [varchar](15) NULL,
	[timeStampMessageUTC] [datetime] NULL,
 CONSTRAINT [pk_ccWAMessagesConvs_1] PRIMARY KEY CLUSTERED 
(
	[messageId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE [dbo].[ccWAMessagesConversations]  WITH CHECK ADD  CONSTRAINT [fk_WAConversationId_1] FOREIGN KEY([conversationId])
REFERENCES [dbo].[ccWhatsAppConversations] ([conversationId])

ALTER TABLE [dbo].[ccWAMessagesConversations] CHECK CONSTRAINT [fk_WAConversationId_1]
END
'
EXEC(@sql)

 set @process = 'CW-5774 create cambia nombre de columna '
    set @sql = '
	IF EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N''firstMessageTime''
          AND Object_ID = Object_ID(N''ccWhatsAppConversations''))
BEGIN
	EXEC sp_rename ''ccWhatsAppConversations.firstMessageTime'', ''assignDate'', ''COLUMN'';
END
	'
	EXEC(@sql)

   	set @process = 'CW-5774 Valida si existe SP ccsp_ConversationWASave'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_ConversationWASave'')
            begin
          DROP PROCEDURE ccsp_ConversationWASave;
            end'
    EXEC(@sql) 

    set @process = 'CW-5774 create SP ccsp_ConversationWASave '
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
                                              , @conversationId     INT         = 0
                                              , @inboundId          SMALLINT    = NULL
                                              , @phoneACD           VARCHAR(50) = NULL
                                              , @clientId           VARCHAR(25) = NULL
                                              , @conversationStatus SMALLINT    = 0
                                              , @tChatting          SMALLINT    = 0
                                              , @tWrapUp            SMALLINT    = 0
                                              , @finishedBy         TINYINT     = 0
                                              , @onQueue            BIT         = NULL
                                              , @tQueue             SMALLINT    = 0
                                              , @tTimeout           INT         = 0
                                              , @disposition        SMALLINT    = 0
                                              , @subDisposition     SMALLINT    = 0
                                              , @agentId            INT         = 0
											  --VAR MESSAGES
											  , @messageId          VARCHAR(50) = NULL
											  , @messageIdUi        INT			= NULL
											  , @clientNum			VARCHAR(15) = NULL
											  , @vonageNum			VARCHAR(15) = NULL
											  , @typeMessage		VARCHAR(25) = ''''
											  , @content			VARCHAR(MAX)= NULL
											  , @timeStampMessage   DATETIME	= NULL
											  , @timeStampMessageUTC DATETIME	= NULL
											  , @originType         VARCHAR(15) = NULL
											  , @currency			VARCHAR(10) = NULL
											  ,	@price				VARCHAR(10) = NULL
AS
BEGIN
    DECLARE @isEndConversation BIT;
    DECLARE @meanContactTypeId SMALLINT;

    SET @meanContactTypeId = 1;
    SET NOCOUNT ON;

    IF @action = 1
    BEGIN --new Conversation
        IF NOT EXISTS
                      (SELECT A.conversationId conversationId FROM ccWhatsAppConversations A
                       WHERE A.conversationId = @conversationId
                      )
        BEGIN
            INSERT INTO [ccWhatsAppConversations]
            (inboundId
           , phoneACD
           , clientId
           , conversationStatus
           , tChatting
           , tWrapUp
           , finishedBy
           , onQueue
           , tQueue
           , tTimeout
           , disposition
           , subDisposition
           , agentId
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
            SELECT @conversationId = SCOPE_IDENTITY();
            SELECT @conversationId AS ConversationId;
            RETURN(0);
        END;
        ELSE
        BEGIN
            SELECT 0 AS ConversationId;
            RETURN(0);
        END;
    END;

    IF @action = 2
    BEGIN --save conversation Times
        UPDATE ccWhatsAppConversations
               SET
                   tChatting = DATEDIFF(ss, conversationDate, GETDATE())
                 , conversationStatus = @conversationStatus
                 , finishedBy = case when @conversationStatus = 10 then 2 else 1 end
                 , tConversation = DATEDIFF(ss, requestDate, GETDATE())
				 ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else tQueue end
				 ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
        WHERE conversationId = @conversationId;


		exec ccsp_CreateNodeMultimedia @conversationId=@conversationId, @type=5

    END;

    IF @action = 3
    BEGIN --save conversation Status
        UPDATE ccWhatsAppConversations
               SET
                   conversationDate = GETDATE()
                 , conversationStatus = @conversationStatus
        WHERE conversationId = @conversationId;
    END;

	IF @action = 4 BEGIN --save messages from conversation
		IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId) BEGIN
			INSERT INTO [ccWAMessagesConversations](
												messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price) values 
											   (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price)
			SELECT @messageId=SCOPE_IDENTITY()
			SELECT @messageId as MessageId
			RETURN (0)
		END
		ELSE BEGIN
			SELECT 0 AS MessageId
			RETURN (0)
		END
	END;

	IF @action = 5
    BEGIN --save onQueue 
        UPDATE ccWhatsAppConversations
               SET onQueue = 1
        WHERE conversationId = @conversationId;
    END;

	IF @action = 6
    BEGIN --save agent, assigdate and tqueue
        UPDATE ccWhatsAppConversations
               SET agentId = @agentId,
			   assignDate = getdate(),
			   conversationStatus = @conversationStatus
        WHERE conversationId = @conversationId;

		UPDATE ccWhatsAppConversations
               SET tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
        WHERE conversationId = @conversationId;
    END;
END;'
    EXEC(@sql)
	
	set @process = 'CW-5791 Drop sp ccsp_GalateaAdminANIListLD'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminANIListLD'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminANIListLD;
            end'
    EXEC(@sql)

    set @process = 'CW-5791 Create Procedure ccsp_GalateaAdminANIListLD'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminANIListLD]
@type as tinyint,
@idArea as smallint,
@descriptionList as varchar(40) = NULL,
@idAniList as smallint = NULL,
@cld as varchar(max)= NULL,
@aniTel as varchar(30)= NULL,
@edo as varchar(350) = NULL
AS
set nocount on
declare @pais tinyint, @listEdos varchar(4000), @idLista as integer, @sql as varchar(500)
select @pais = valor from ccsettings where setting_id = 104

select @listEdos = ''select distinct '' + case @type when 1 then
case @pais	when 1  then ''estado as [state] ''
			when 2  then ''estado as [state] ''
			when 3  then ''municipio as [state] ''
			when 4  then ''location as [state] ''
			when 5  then ''cld as [state] ''
			when 6  then ''region as [state] ''
			when 7  then ''region as [state] ''
			when 8  then ''Regiones as [state] ''
			when 9  then ''Regiones as [state] ''
			when 10 then ''Regiones as [state] ''
			when 11 then ''zonaGeografica as [state] ''
			when 12 then ''zonaGeografica as [state] ''
			when 13 then ''zonaGeografica as [state] ''
			when 14 then ''provincia as [state] ''
			else '''' end
when 4 then
case @pais	when 1  then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 2  then ''estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 3  then ''municipio as estado, region +''''''''+ serie as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 4  then ''location as estado, area, @id_anilist as id_anilist, '''''''' as telani ''
			when 5  then ''cld as estado, cld as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 6  then ''region as estado, LD as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 7  then ''region as estado, CLD as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 8  then ''Regiones as estado, cld +''''-''''+ [serie inicio] as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 9  then ''Regiones as estado, LD + AreaCode as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 10 then ''Regiones as estado, AreaCode as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 11 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 12 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 13 then ''zonaGeografica as estado, indicativoDestino as area, @id_anilist as id_anilist, '''''''' as telani ''
			when 14 then ''provincia as estado, indicativoProvincia as area, @id_anilist as id_anilist, '''''''' as telani ''
			else '''' end 
end + ''from '' +
case @pais	when 1  then ''series''
			when 2  then ''seriesarg where estado <> ''''''''''
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
			when 14 then ''SeriesEsp''
			else '''' end + ''''

if @type=1
begin	--Get locations / states
	exec(@listEdos + '' order by [state]'')
	return(0)
end

if @type=2
begin
	select @sql = ''select id_AniList, description from ccEdoAniList where idArea = '' + convert(varchar(5),@idArea) +  
	case when isnull(@idAniList,'''') <> '''' then '' and id_AniList = '' + convert(varchar(5),@idAniList) else '''' end
	exec(@sql)
	return(0)
end

if @type=3
begin	-- Get Outbound telAni with Area Codes
	select @sql = ''select id_AniList, Estado, telAni, area from ccEstadosAni where id_AniList = '' + convert(varchar(5),@idAniList) + 
	'' and estado like ''''%'' + @edo + ''%'''' and id_AniList in (select id_AniList from ccEdoAniList where idArea = '' +
	 convert(varchar(5),@idArea) + '') order by estado''
	exec(@sql)
	--print(@sql)
	return(0)
end

if @type=4
begin  --Insert new aniList
	if @descriptionList <> '''' begin
		if exists(select * from dbo.ccEdoAniList where [description]=@descriptionList )
		begin
			select cast(2 as int) [result]
			return(0)
		end
		insert into ccEdoAniList values(@descriptionList, @idArea)
		select @idLista = id_anilist from ccEdoAniList where [description] = @descriptionList
		set @listEdos = ''insert into ccEstadosAni (estado, area, id_anilist, telani) '' + @listEdos
		set @listEdos = replace(@listEdos, ''@id_anilist'', convert(varchar(6),@idLista))
		exec(@listEdos)
		--print(@listEdos)
		select cast(1 as int) [result]
		return(0)
	end
	select cast(0 as int) [result]
	return(0)
end

if @type=5
begin --Save ANI number
	update ccEstadosAni set telani= ISNULL(@aniTel, TELANI) WHERE id_anilist = @idAniList 
	and area in (select value from dbo.fn_RIASplitDelimited(@cld, '',''))

	select cast(1 as int) [result]
	return(0)
end

if @type=6
begin --Delete ANI list
	if not exists(select id_anilist from ccEdoAniList WHERE id_anilist = @idAniList and idarea = @idArea )
	 begin
		select cast(-1 as int) [result]
		return(0)
	 end

	delete from ccEstadosAni where id_anilist = @idAniList
	delete from ccEdoAniList WHERE id_anilist = @idAniList

	select cast(1 as int) [result]
	return(0)
end

if @type=7
begin --Update ANI list name
	if(exists(select [description] from ccEdoAniList where [description]=@descriptionList and id_AniList<>@idAniList))
	begin
		select cast(2 as int) [result]
		return(0)
	end

	update ccEdoAniList set [description]=@descriptionList where id_AniList=@idAniList
	select cast(1 as int) [result]
	return(0)
end
'
    EXEC(@sql)
	
    set @process = 'CW-5740 Se agrega propiedad a detalle'
    set @sql = 'UPDATE ccsettings 
	            SET detalle = ''Activo(0:apagado,1:Mensual,2:semanal,3:diario)|# Semana Ejecucion|Dia Ejecucion(1:LU,2:Ma,3:Mi,4:Ju,5:Vi,6:Sa,0:Do)|Hora Inicio(00:00)|Servidor FTP|usuario FTP|contraseña FTP|Ruta de descarga FTP|Tiene SSL (1 si, 0 no)''
	            WHERE setting_id=228'
    EXEC(@sql)

    set @process = 'CW-5829 Drop procedure ccsp_UpdateACDWhatsappConfig'
    set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_UpdateACDWhatsappConfig'')
	            BEGIN
	          		DROP PROCEDURE ccsp_UpdateACDWhatsappConfig;
	            END'
    EXEC(@sql)

    set @process = 'CW-5829 Create procedure ccsp_UpdateACDWhatsappConfig'
    set @sql = 'CREATE procedure  [dbo].[ccsp_UpdateACDWhatsappConfig]

					@ConexionInfo varchar(400),
					@inbound_id int,
					@ConnUser varchar(60),
					@tNotas int,
					@closeConversationTime tinyint,
					@ShowCalifWnd bit 

					AS
					set nocount on
					    IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
					    BEGIN
					        UPDATE contactMeanIn SET conexionInfo = @conexionInfo, connUser = @connUser, closeConversationTime = @closeConversationTime,
													 ConnPass = ''N/A'', numMessages = 3, timeAlertMessage = 5, answerTimeOut = 10 					 
							where inboundId = @inbound_id;
							UPDATE ccWhatsAppNumbers SET inboundId = @inbound_id WHERE number = @conexionInfo
					    END;

					    IF EXISTS (SELECT Inbound_id FROM ccInbound WHERE Inbound_id = @inbound_id) 
					    BEGIN
					        UPDATE ccInbound SET tNotas = @tNotas, ShowCalifWnd = @ShowCalifWnd where Inbound_id = @inbound_id;
					    END;
					SELECT @inbound_id;
					return(@inbound_id)

					set nocount off'
    EXEC(@sql)

    set @process = 'CW-5820 Se agrega columna ExitWrapUpDisposition'
    set @sql = '
    IF not exists (SELECT * FROM sys.columns WHERE name = N''ExitWrapUpDisposition'' AND Object_ID = Object_ID(N''ccInbound''))
    BEGIN
        ALTER TABLE ccInbound ADD ExitWrapUpDisposition BIT NOT NULL DEFAULT (0);
    END'
    EXEC(@sql)

    set @process = 'CW-5820 Drop procedure ccsp_MultimediaCommon'
    set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_MultimediaCommon'')
	            BEGIN
	          		DROP PROCEDURE ccsp_MultimediaCommon;
	            END'
    EXEC(@sql)

    set @process = 'CW-5820 update procedure ccsp_MultimediaCommon'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon] 
		@Option AS SMALLINT, 
		@inboundId AS SMALLINT = 0, 
		@conversationId AS INT = 0, 
		@ServiceType AS SMALLINT = 0,
		@status as SMALLINT =0
		AS
		BEGIN
		    SET NOCOUNT ON;

		    IF(@Option = 1)
				BEGIN

					 SELECT --inbound.chat AS ServiceType,
					   CAST(inbound.Inbound_id AS INT) AS ACDId,
					   inbound.descripcion AS ACDName,
					   ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
					   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
					   inbound.tNotas AS WrapUpTime

					   FROM  ccInbound inbound
					   INNER JOIN  contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId
				END      

			IF(@Option = 2)
				BEGIN
					SELECT 
						cast(i.chat as int) AS ServiceType,
						cast(c.conversationId as int) as ConversationID,
						c.clientId as ClientId,
						cm.conexionInfo as [To],
						cast(i.Inbound_id as int) as ACDId,
						i.descripcion as ACDName,
						cast(g.graphic_id as int) as ACDGraphicId,
						cast(cm.closeConversationTime as int) as [TimeOut],
						cast(cm.answerTimeOut as int) as [TimeOutWarning],
						i.ExitWrapUpDisposition as [ExitWrapUpDisposition],
						i.tNotas as [WrapUpTime],
						i.ShowCalifWnd
					FROM  ccInbound i
						INNER JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId
						INNER JOIN ccWhatsAppConversations c ON (c.inboundId = i.Inbound_id and c.conversationId = @conversationId)
						INNER JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
					WHERE i.chat = @ServiceType and i.Inbound_id = @inboundId
				END
			IF(@Option = 3)
				BEGIN
					 SELECT 
					   CAST(inbound.Inbound_id AS INT) AS ACDId,
					   inbound.descripcion AS ACDName,
					   ISNULL(configuration.conexionInfo, '''') AS PhoneACD,
					   CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
					   inbound.tNotas AS WrapUpTime

					   FROM  ccInbound inbound
					   INNER JOIN  contactMeanIn configuration ON (inbound.Inbound_id = configuration.inboundId and inbound.Inbound_id = @inboundId)
				END   	
		END'
    EXEC(@sql)

    set @process = 'CW-5820 Drop procedure ccsp_UpdateACDWhatsappConfig'
    set @sql = 'IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_UpdateACDWhatsappConfig'')
	            BEGIN
	          		DROP PROCEDURE ccsp_UpdateACDWhatsappConfig;
	            END'
    EXEC(@sql)

    set @process = 'CW-5820 update procedure ccsp_UpdateACDWhatsappConfig'
    set @sql = 'CREATE procedure  [dbo].[ccsp_UpdateACDWhatsappConfig]

					@ConexionInfo varchar(400),
					@inbound_id int,
					@ConnUser varchar(60),
					@tNotas int,
					@closeConversationTime tinyint,
					@ShowCalifWnd bit,
					@ExitWrapUpDisposition bit

					AS
					set nocount on
					    IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
					    BEGIN
					        UPDATE contactMeanIn SET conexionInfo = @conexionInfo, connUser = @connUser, closeConversationTime = @closeConversationTime,
													 ConnPass = ''N/A'', numMessages = 3, timeAlertMessage = 5, answerTimeOut = 10 					 
							where inboundId = @inbound_id;
							UPDATE ccWhatsAppNumbers SET inboundId = @inbound_id WHERE number = @conexionInfo
					    END;

					    IF EXISTS (SELECT Inbound_id FROM ccInbound WHERE Inbound_id = @inbound_id) 
					    BEGIN
					        UPDATE ccInbound SET tNotas = @tNotas, ShowCalifWnd = @ShowCalifWnd, ExitWrapUpDisposition = @ExitWrapUpDisposition where Inbound_id = @inbound_id;
					    END;
					SELECT @inbound_id;
					return(@inbound_id)

					set nocount off'
    EXEC(@sql)

    set @process = 'CW-XX Se agrega fila para el tipo de WhatsApp en meanContactType '
    set @sql = 'if not exists(select * from meanContactType where meanContactTypeId=5) begin
	SET IDENTITY_INSERT meanContactType ON
	insert into meanContactType (meanContactTypeId, name, isActive) values (5, ''WhatsApp'', 1)
	SET IDENTITY_INSERT meanContactType OFF
	end'
    EXEC(@sql)
    
  set @process = 'Totales de contactacion ccsp_GalateaTotalContact'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaTotalContact'')
            begin
          DROP PROCEDURE ccsp_GalateaTotalContact;
            end'
    EXEC(@sql)

	  set @process = 'Totales de contactacion ccsp_GalateaTotalContact'
    set @sql = '
CREATE PROCEDURE ccsp_GalateaTotalContact
 @option int, 
 @agent_id  int = 0
AS BEGIN
	declare @dateStart datetime
	set @dateStart =convert(date,getdate())

	IF(@option = 1)
	BEGIN
		declare @outbound int = 0 , @inboud int = 0 , @twiter int = 0 , @email int = 0 , @whatsapp int = 0 , @chat int = 0 
		select @outbound = count(cal_id)
			from ccoCallsOut with(nolock) where cal_inicio>@dateStart and User_id = @agent_id and statusCall_id = 13
		select @inboud = count(cal_id)
			from ccCallsIn  with(nolock) where cal_inicio>@dateStart and User_id = @agent_id and statusCall_id = 13
		select @chat = count(chatId)
			from ccRIAChats  with(nolock) where requestDate>@dateStart and userId = @agent_id

		SELECT @agent_id AgentId, @outbound Outbound, @inboud Inbound, @chat Chat, @email Email, @whatsapp Whatsapp, @twiter Twitter
	END
	
	IF(@option = 2)
	BEGIN
		select CAST(User_id as INT) AgentId,count(*) Count,''OUTBOUND'' as media from ccoCallsOut with(nolock) where cal_inicio>@dateStart  and statusCall_id = 13 group by User_id
		union
		select CAST(User_id as INT) AgentId, count(*) Count,''INBOUND'' from ccCallsIn with(nolock) where cal_inicio>@dateStart and statusCall_id = 13  group by User_id
		union
		select CAST(userId as INT) AgentId, count(*) Count,''CHAT'' from ccRIAChats with(nolock) where requestDate>@dateStart and userId>0 group by userId
	END
END
'
EXEC(@sql)

set @process = 'CW-Dnis ccsp_GalateaDnis - Se quita el SP si ya existe'
    set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaDnis'')
            begin
          DROP PROCEDURE ccsp_GalateaDnis;
            end'
    EXEC(@sql)


    set @process = 'CW-Dnis ccsp_GalateaDnis - Se quita el SP  si ya existe'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaDnis]
--declare
@User varchar(10),
@Tipo tinyint,
@Dnis varchar(40) = null,
@Inbound_id smallint = null,
@dni_id as smallint = null,
@dnis_ids as varchar(MAX) = null,
@dni_description as varchar(40) = null,
@dni_isBlock as bit = null
as
set nocount on

if @Tipo = 1 -- carga dnis
 begin
	select dni_id, dni_numero as dni_number, dni_descripcion as dni_description, case when dni_id in(select dni_id from ccInboundDnis) then 1 else 0 end dni_isRelated
	from ccDnis where dni_Status=1 order by 2
	return(0)
 end

if @Tipo = 2 -- carga relaciones de dnis
 begin
	if cast(@user as smallint) > 0 and not exists (select * from ccUsers_Roles where User_id = cast(@user as smallint) and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
		select a1.Inbound_id, cast(0 as smallint) dni_id, a1.descripcion as description,'''' as dni_number,'''' as dni_description, cast(0 as tinyint) dni_isBlock
		from ccInbound a1
		inner join ccRIAInboundGraph a2 on (a1.Inbound_id = a2.Inbound_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		where a3.type_id = 1
		AND a1.Inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User, 2) where cam_id not in (select Inbound_id from ccInboundDnis))
		union
		select ci.inbound_id, cid.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
		from ccInboundDnis cid 
		left join ccInbound ci on ci.inbound_id = cid.inbound_id 
		join ccDnis cd on cd.dni_id = cid.dni_id 
		where cd.dni_Status=1
		order by 3,4
		return(0)
	end
	else begin
		select a1.Inbound_id, cast(0 as smallint) dni_id, a1.descripcion as description,'''' as dni_number,'''' as dni_description, cast(0 as tinyint) dni_isBlock
		from ccInbound a1
		inner join ccRIAInboundGraph a2 on (a1.Inbound_id = a2.Inbound_id)
		inner join ccRIAGraphics a3 on (a2.graphic_id = a3.graphic_id)
		where a3.type_id = 1 and IDArea is not null and a1.Inbound_id not in (select Inbound_id from ccInboundDnis)
		union
		select ci.inbound_id, cid.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
		from ccInboundDnis cid 
		left join ccInbound ci on ci.inbound_id = cid.inbound_id 
		join ccDnis cd on cd.dni_id = cid.dni_id 
		where cd.dni_Status=1
		order by 3,4
		return(0)
	end
	return(0)
 end

if @Tipo = 3 -- Agrega Dnis
 begin
	if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis)
	 begin
		insert into ccDnis (dni_id, dni_numero, dni_tpoMaxEspera, tipodni_id, dni_Descripcion, dni_tipo)
		select isNull(max(dni_id), 0) + 1, @Dnis , 0, 1, @dni_description, 2 from ccDnis
		select top(1) dni_id from ccDNIS order by dni_id desc
		return(0)
	 end
	 
	select cast(-1 as smallint)
 end

if @Tipo = 4 -- Elimina Dnis
 begin
	delete from ccInboundDnis where inbound_id = @Inbound_Id and dni_id = @dni_id
	
	select ci.inbound_id, cd.dni_id, ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock
	from ccInbound ci , ccDNIS cd
	where ci.Inbound_id=@Inbound_id and dni_id=@dni_id
 end

if @Tipo = 5 -- Agrega Relacion
 begin
	insert into ccInboundDnis (Inbound_id, dni_id)
	select @Inbound_Id,B.Value from  dbo.fn_RIASplitDelimited (@dnis_Ids, '','') B
	left join ccInboundDnis A on A.dni_id=B.Value 
	where  A.dni_id is null

	select cast(@Inbound_Id as smallint) inbound_id,cast(B.Value as smallint) dni_id, 
	ci.descripcion as description, cd.dni_numero as dni_number, dni_descripcion as dni_description, cast(dni_isBlock as tinyint) dni_isBlock		
	,case when cid.Inbound_id is null then 0 else 1 end isAssigned
	from  dbo.fn_RIASplitDelimited (@dnis_Ids, '','') B
	left join ccInboundDnis cid on cid.dni_id=B.Value and cid.Inbound_id=@Inbound_Id
	left join ccInbound ci on ci.inbound_id = @Inbound_Id
	inner join ccDnis cd on cd.dni_id = B.Value
	order by 3,4
 end

if @Tipo = 6 -- Elimina Dnis sin pedir inbound_id
 begin
	if exists(select dni_id from ccInboundDnis where dni_id in (select value from dbo.fn_RIASplitDelimited (@dnis_Ids, '','')) and isnull(inbound_id, 0) <> 0)
		select -1

	else begin
		update ccDNIS set dni_Status=0 where dni_id in (select value from dbo.fn_RIASplitDelimited (@dnis_Ids, '',''))--= @dni_id -- delete from ccdnis where dni_id = @dni_id
		select 1
	end
 end

if @tipo = 7
 begin
	if @Dnis = (select dni_numero from ccDNIS where dni_id=@dni_id) begin
		update ccDnis set 
		dni_Descripcion=isnull(@dni_description,dni_Descripcion)
		where dni_id = @dni_id 
		
		select 1
		return(0)
	end

	if not exists(select dni_numero from ccDnis where dni_Status=1 and dni_numero like @Dnis) begin
		update ccDnis set 
		dni_numero=case when @Dnis <> ''0'' then @Dnis else dni_numero end,
		dni_Descripcion=isnull(@dni_description,dni_Descripcion),
		dni_isBlock = isnull(@dni_isBlock,dni_isBlock)
		where dni_id = @dni_id 

		select 1
		--select dni_id,dni_numero as dni_number, dni_Descripcion as dni_Descriptiondni_id, dni_isBlock from ccDNIS where dni_id=@
		return(0)
	end
	
	select -1
 end

set nocount off'
    EXEC(@sql)

	set @process = 'CW-5860 add exitAssisted to ccCamps'
    set @sql = 'IF not exists (SELECT * FROM SYS.columns WHERE name=''exitAssisted'' AND OBJECT_ID = OBJECT_ID(''ccCamps''))
		begin
			alter table ccCamps add exitAssisted bit null
		end'
    EXEC(@sql)

	set @process = 'CW-5858 update procedure ccsp_GalateaGetOutboundConfiguration'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration]
		@adminID int,
		@campID int
		AS
		BEGIN

			declare @AllCampaigns table 
			(cam_id smallint, cam_Descripcion varchar(40), cam_tNotas smallint, cam_ocupado smallint,cam_noInt_ocupado smallint, cam_inter_ocupado smallint,
			cam_nocontesto smallint, cam_noInt_nocontesto smallint, cam_inter_nocontesto smallint, cam_fax smallint, cam_noInt_fax smallint, cam_inter_fax smallint,
			cam_modomanual smallint, ANI varchar(15), cam_ShowCalifWnd bit, cam_StartTimerOnHangUp bit, editableCallKey bit, cam_tNoContesta smallint, iTipoDial smallint,
			detectAnswerMachine smallint,detectVoiceMail smallint, compliance smallint, cam_inter_graba smallint, cam_noint_graba smallint, progDial smallint, excCallBack smallint, dialOrder smallint,
			dialPrefix varchar(10),dialPrefixMan varchar(10), dialPrefixXfe varchar(10),listenManualCall bit,  stopRecording bit,abandonCallback bit, frame smallint,
			t_autoCB smallint, id_anilist int, tDialonWrapUp smallint, viewMode tinyint, queSize smallint, DNCScrub int, callerIdDesc varchar (15), timeZoneRule int,
			callsBySurvey int, ivrScript int, surveyPctg int,call_record smallint,startStopRecording bit,  leaveRecMessage  bit, manualCallOnChat bit, 
			callBackSurveyAgent bit, callBackSurveyClient bit, isRelationSurvey bit, funcEspDtmf int,  sipHdrFormat varchar(255), cam_inter_cancelled smallint, 
			prefijo varchar(40),enbleprefix bit,exitAssisted bit )
	 
			 INSERT INTO @AllCampaigns EXEC ccsp_RIAConfCamp @adminID

			 SELECT dialPrefixMan DialPrefixMan, dialPrefixXfe DialPrefixXfe, listenManualCall  ListenManualCall, stopRecording StopRecording, abandonCallback AbandonCallBack,
			 t_autoCB AutoCB,id_anilist IdIstANI,tDialonWrapUp TDialOnWrapup, queSize Quesize, DNCScrub, callerIdDesc CallerIdDesc, timeZoneRule TimeZoneRule,callsBySurvey CallsBySurvey,
			 ivrScript IvrScript, surveyPctg SurveyPctg, call_record CallRecord,startStopRecording StartStopRecording, leaveRecMessage LeaveRecMessage,manualCallOnChat ManualCallOnChat,
			 callBackSurveyClient CallBackSurveyClient, callBackSurveyAgent CallBackSurveyAgent, funcEspDtmf FuncEspDtmf,sipHdrFormat SipHdrsCfg, dialPrefix DialPrefix,
			 prefijo Prefix, dialOrder DialOrder, progDial ProgDial, cam_Descripcion CamDescription, cam_tNotas CamTnotas, cam_ocupado CamBusy, cam_noInt_ocupado CamNoIntBusy,
			 cam_inter_ocupado CamInterBusy,cam_nocontesto CamNoAnswer, cam_noInt_nocontesto CamNoIntNoAnswer,cam_inter_nocontesto CamInterNoAnswer, (cam_inter_cancelled/60) CamInterCancelled,
			 cam_fax CamFax, cam_noInt_fax CamNoIntFax,cam_inter_fax CamInterFax, cam_modomanual CamModoManual,ANI ,cam_StartTimerOnHangUp CamStartTimerOnHangUp,
			 editableCallKey EditableCallKey, cam_tNoContesta CamTNoAnswer, iTipoDial  CamIntensiveDialing, detectAnswerMachine DetectAnswerMachine, detectVoiceMail DetectVoiceMail, 
			 compliance Compliance, cam_inter_graba CamInterRecord,cam_noint_graba CamNoIntRecord,excCallBack ExcCallBack, cam_ShowCalifWnd CamShowCalifWnd, frame Frame, exitAssisted ExitAssistedDialMode
			 from @AllCampaigns WHERE cam_id = @campID
		END'
    EXEC(@sql)

	set @process = 'CW-5858 update procedure ccsp_RIAConfCamp'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
		@User_id smallint
		AS
		set nocount on
			declare @tableExistsRec table (camId int primary key,existRec bit)

			insert into @tableExistsRec
			select B.cam_id,case when count(A.cal_id) >0 then 1 else 0 end as existRec 
			from dbo.fGet_CampAcd_Area (@User_id, 1) B
			left join ccoCallsOut A on A.cam_id=B.cam_id
			group by B.cam_id

			select a1.cam_id, cam_Descripcion
			, cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
			, cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
			, cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
			, detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
			, cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
			, stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, 
			cam_maxqueue as queSize,
			DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
				,cast (startStopRecording as tinyint)startStopRecording, leaveRecMessage, manualCallOnChat
			,callBackSurveyAgent,callBackSurveyClient,case when surveycamid is null or surveycamid = 0 then 0 else 1 end isRelationSurvey,isnull(a1.funcEspDtmf,0)
			,isnull(sipHdrFormat, '''') sipHdrFormat
			,cam_inter_cancelled
			,prefijo,	enbleprefix = case when existRec = 0 then 1 else 0 end,
			isnull(exitAssisted, 0) exitAssisted
			from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
			inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
			inner join @tableExistsRec a4 on a1.cam_id=a4.camId
			--where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
			order by cam_descripcion
			return(0)
			set nocount off'
    EXEC(@sql)

	set @process = 'CW-5858 update procedure ccsp_RIAUpdateCamConfig'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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
				@callBackSurveyAgent bit = null,
				@funcEspDtmf int =null,
				@sipHdrsCfg varchar(255) = null,
				@cam_inter_cancelled smallint = null,
				@prefijo varchar(max) = null,
				@exitAssisted bit = null
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
				 cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
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
				 callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
				 funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
				 sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
				 prefijo = isnull(@prefijo, prefijo),
				 exitAssisted = isnull(@exitAssisted, exitAssisted)
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
				select 2
				return(0)
				set nocount off'
    EXEC(@sql)

	set @process = 'CW-5858 drop procedure ccsp_AgentGetAssistedPermission'
    set @sql = 'IF exists (select * from sys.procedures where name = N''ccsp_AgentGetAssistedPermission'')
            BEGIN
				DROP PROCEDURE ccsp_AgentGetAssistedPermission;
            END'
    EXEC(@sql)

	set @process = 'CW-5858 create procedure ccsp_AgentGetAssistedPermission'
    set @sql = 'CREATE PROCEDURE [dbo].[ccsp_AgentGetAssistedPermission]
		@age_id int,
		@cam_id int
		AS
		BEGIN
			SET NOCOUNT ON;

			select isnull(exitAssisted,0) Allowed from ccCamps (nolock) where cam_id = @cam_id
		END'
    EXEC(@sql)

	set @process = 'CW-5860 add op 182 to ccRIALog_Operation'
    set @sql = 'if not exists (select operationType from ccRIALog_Operation where operationType=182)
		begin
			insert ccRIALog_Operation values (182,''Salir de Modo Asistido|Exit Assisted Dialing Mode'')
		end'
    EXEC(@sql)

	set @process = 'CW-5856 add Assisted to ccTipoStatusAgente'
    set @sql = 'if not exists (select TipoStatusAge_id from ccTipoStatusAgente where TipoStatusAge_id=28)
		begin
			insert ccTipoStatusAgente (TipoStatusAge_id, descripcion) values (28,''Assisted'')
		end'
    EXEC(@sql)


		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END