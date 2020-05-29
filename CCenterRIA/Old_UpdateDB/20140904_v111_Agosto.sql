/*
Autor: Jesus Gallardo
Fecha: 2014/09/04
Descripcion:
	
	Se crea tabla de series de guatemala}
	
	Se inserta ccSettings 163 para el Call_Id
	Se inserta ccSettings 164 para permiso realizar llamadas con tarifas configuradas
	Se inserta cstoTipoLlamada para el plan de guatemala
	Se inserta SeriesGT para el plan de guatemala
	Se inserta ccRIACat_Country para el plan de marcacion de Guatemala

	Se crea indice IX_ccLogLogin_4 para ccLogLogin 
	Se crea indice IX_ccLogLogin_5 para ccLogLogin 
	Se crea indice IX_ccoCallsOut_14 para ccoCallsOut 
	
	Se actuliza ccsettings descripcion setting_id 160 asterisk
	Se actuliza ccsettings descripcion setting_id 104 para el plan de marcacion de Guatemala
	
	Se crea SP ccsp_CheckTarifas para validar si se permite llamadas con tarifas
	Se crea SP configuraIdiomaCatalogosPortugues para el plan de marcación de Guatemala	
	
	Se modifica SP ccsp_RIAMenuRoles para que al guardar un usuario de AVRS lo deje con tipo 6		
	Se modifica SP ccspADM_AniListLD para el plan de marcacion de Guatemala
	Se modifica SP ccsp_RIAccSettingsConfig para el plan de marcacion de Guatemala
	Se modifica SP ccsp_RIAAgentGetDialMask para el plan de marcacion de Guatemala
	Se modifica SP ccsp_AgentUpdateCallCALIF para el plan de marcacion de Guatemala
	Se modifica SP ccsp_Limpia para el plan de marcacion de Guatemala


	Se modifica Function TelAni para el plan de marcación de Guatemala
	Se modifica Function Completa_ListaNegra para el plan de marcación de Guatemala
	Se modifica Function Completa para el plan de marcación de Guatemala
	

	--PERFORMANCE
	Se modifica el SP ccsp_GetAgentIndividualCounters para performance
	Se modifica el Job CW Delete old records

Version requerida: 110
*/
set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = '111'
exec @Version_Actual = dbo.ccsp_getVersion 'BD'

if @Version_Actual = @Version-1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
	---------------- inicio SCRIPT @Sql ----------------

	set @process = 'Create table -- SeriesGT'
	set @Sql='create table SeriesGT(
zonaGeografica varchar (50),
indicativoDestino varchar(2),
rangoInicio varchar(8),
rangoFinal varchar(8));
'	

	EXEC(@Sql)

	set @process = 'insert ccSettings -- Mostrar CallID'
	set @Sql='insert ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings)  values 
	(163, 0, ''Mostrar CallID en AgenteRIA'', 1, ''AGT'', ''Muestra CallID de las llamadas en pantalla. 1-Si 0-No'', ''Show CallID in AgentRIA'', 0)
insert ccsettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings)  
values (164, 0, ''Validar tarifa configurada para llamada manual'', 1, ''AGT'', ''Verifica si puede marcar si tiene tarifas configuradas'', ''Validate the rate set for manually dialed calls'', 1)'	
	
	EXEC(@Sql)

	set @process = 'insert -- SeriesGT'
	set @Sql='insert into SeriesGT (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Zona Metropolitana (Ciudad de Guatemala)'',2,''0000000'',''9999999'')
insert into SeriesGT (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Zona Metropolitana Suburbana'',6,''0000000'',''9999999'')
insert into SeriesGT (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Zona Metropolitana Suburbana '',7,''0000000'',''9999999'')
insert into SeriesGT (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Telefonia Movil'',4,''0000000'',''9999999'')
insert into SeriesGT (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Telefonia Movil'',5,''0000000'',''9999999'')
insert into SeriesGT (zonaGeografica,indicativoDestino,rangoInicio,rangoFinal) values (''Telefonia Movil'',3,''0000000'',''9999999'')'	
		
	EXEC(@Sql)

	set @process = 'insert -- cstoTipoLlamada'
	set @Sql='insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (11,1,''Local'',8,''%'')
insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (11,2,''Movil'',8,''%'')
insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (11,3,''LD Nacional'',8,''%'')
insert into cstoTipoLlamada (country_id,tipoLlamada_id,descrip,longitud,prefijo) values (11,4,''LD Internacional'',8,''00%'')'	
		
	EXEC(@Sql)	


	set @process = 'Create index IX_ccLogLogin_4 -- ccLogLogin'
	set @Sql='CREATE NONCLUSTERED INDEX [IX_ccLogLogin_4] ON [dbo].[ccLogLogin]
(
	[User_id] ASC,
	[fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'	
	
	EXEC(@Sql)


	set @process = 'Create index IX_ccLogLogin_5 -- ccLogLogin'
	set @Sql='CREATE NONCLUSTERED INDEX [IX_ccLogLogin_5] ON [dbo].[ccloglogin]
(
	[TipoMov] ASC,
	[fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'	
	
	EXEC(@Sql)

	set @process = 'Create index IX_ccoCallsOut_14 -- ccoCallsOut'
	set @Sql='CREATE NONCLUSTERED INDEX [IX_ccoCallsOut_14] ON [dbo].[ccoCallsOut]
(
	[cal_Inicio] DESC,
	[cal_manual] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'	
	
	EXEC(@Sql)		

	set @process = 'insert -- ccRIACat_Country'
	set @Sql='insert into ccRIACat_Country  values (''Guatemala'', 502, 8, 8)'	
	
	EXEC(@Sql)


	set @process = 'update -- ccsettings asterisk'
	set @Sql='update ccsettings set [description] = ''asterisk integration'' where setting_id = 160'	
	
	EXEC(@Sql)

	set @process = 'update -- ccsettings pais'
	set @Sql='update ccsettings set detalle = ''1:Mexico, 2:Argentina, 3:Colombia, 4:USA, 5:Chile, 6: Venezuela, 7: Reino Unido, 8: Arabia saudita, 9: Australia, 10:Brasil, 11:Guatemala'', bLoadSettings = ''1'' where setting_id = 104'	
	
	EXEC(@Sql)

	set @process = 'Create SP -- ccsp_CheckTarifas'
	set @Sql='CREATE PROCEDURE [dbo].[ccsp_CheckTarifas]
@tel varchar(255)
AS
set nocount on

--declare @tel varchar(255)
declare @countryId tinyint
declare @len tinyint
declare @porcentaje tinyint
declare @typeLlamada tinyint

if (select valor from ccsettings where setting_id=164)= 1 begin

	--set @tel=dbo.limpia(''044 55 64234886'')
	set @tel = dbo.limpia(@tel)
	set @len = len(@tel)
	
	select @countryId=valor from ccsettings where setting_id=104

	select @typeLlamada=tipoLlamada_id
	from cstoTipoLlamada where country_id=@countryId and longitud in(@len,0) and prefijo = substring(@tel,0,CHARINDEX(''%'',prefijo))+''%''


	if exists (select * from cstoTarifa where tipoLlamada_Id= @typeLlamada)  select 0,''existe tarifa''
	else select 11,''No existe tarifa''

end
else begin 
	select 0
end

set nocount off'	
	
	EXEC(@Sql)

		set @process = 'Create SP -- configuraIdiomaCatalogosPortugues'
	set @Sql='CREATE PROCEDURE [dbo].[configuraIdiomaCatalogosPortugues]
AS
Print ''Iniciando proceso de configuracion en Portugues''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Semana'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Noite'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sabado'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Domingo'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady] 
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Não Clasified'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Pausa'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Casa de banho'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Com o cliente'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Esclarecimento'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Reunião'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Almoço'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Sistemas'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Outros '')

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
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Inicial'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Fora da agenda'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Fora de serviço'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''Não há agentes conectados'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''Em espera'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandonado'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Tempo de transbordo'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Tamanho da fila de transbordo'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''Com Mensagem'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10,''Mensagem atribuída'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11,''Atribuído'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12,''Mensagem compareceram'')
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''segunda-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''terça-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''quarta-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''quinta-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''sexta-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''sábado'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''domingo'')

Print ''Estableciendo resultados de marcacion''
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Resposta'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Ocupado'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Não resposta'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax / Modem'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Outros'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10,''NOservice'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11,''Correio de Voz / Máquina'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12,''Circuito ocupado'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13,''Cancelado'')

Print ''Estableciendo los tipos de estado de los agentes''
DELETE [dbo].[ccTipoStatusAgente]
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Desconhecido'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Pronto'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Conversando'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transferência'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Outros'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Cliente'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Tocando'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11,''Problema'')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21,''Espere por chamada manualmente'')

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agente'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''Acesso AVRS'')

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [dbo].[ccDias] ON
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (1, ''domingo'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (2, ''segunda-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (3, ''terça-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (4, ''quarta-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (5, ''quinta-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (6, ''sexta-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (7, ''sábado'')
SET IDENTITY_INSERT [dbo].[ccDias] OFF

truncate table cstoTarifa

Print ''Estableciendo los tipos de llamada''
delete cstoTipoLlamada
declare @country_id tinyint
select @country_id = valor from ccsettings where setting_id = 104
insert into cstoTipoLlamada(country_id,tipoLlamada_id,descrip,longitud,prefijo) values (@country_id,1,''Chamada padrão'', 8, ''%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] ON
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Adicionado à lista negra'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Bloqueado no carregamento'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removido da campanha'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Substituído da lista negra'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Excluído da lista negra'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Adicionado por Disposição'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Carregar lista negra'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Carga cliente lista negra'')
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Peça informações Geral'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Chame hung'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong Number'', 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Chamada eficaz'' , 0, 0, 1)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Deixe um recado '', 0, 1, 2)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong Number'', 0, 1, 3)

--Pendiente validar rpoveedores portugal
--Print ''Estableciendo proveedores''
--Delete [dbo].[cstoProvedor]
--DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
--INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrador escreve única mensagem para um agente'' where TipoMsgChat=1
Update ccRIAChat_TipoMsg set MsgDetalle=''Agente escreve uma mensagem para o Administrador'' where TipoMsgChat=2
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrador escreve uma mensagem global'' where TipoMsgChat=3

Print ''Mensajes defualt''
DELETE [dbo].[ccMsgFiles]
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Mensagem de boas vindas'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Mensagem de transferência'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Mensagem de falta de serviço'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''Depois de horas de mensagens'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''Na fila de mensagens'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''Nenhum agente assinado em mensagem'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''Mensagem de voz'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Mensagem de Overflow'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''Lista DNC'')

Print ''Mensajes default chat''
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Bem-vindo!'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Serviço está disponível no momento'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Nosso horário de serviço terminou'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Por favor aguarde enquanto um dos nossos agentes está disponível'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''Há agentes não disponíveis'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Sua solicitação não pode ser processada'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Sessão de chat foi-inativo por muito tempo'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Sessão de chat terminou'')'	
	
	EXEC(@Sql)


	set @process = 'update Stored  - [ccsp_RIAMenuRoles]'
	set @Sql='
		ALTER procedure [dbo].[ccsp_RIAMenuRoles]
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

		select @reportRol = case @reportRol when 0 then 1 else @reportRol end, @role_id = case @role_id when 0 then 1 else @role_id end



		Declare @NRS tinyint
		declare @MenusChat tinyint
		declare @RelationCampInbNotReady tinyint
		Declare @IVRScripting tinyint
		Declare @MenuMail tinyint

		set @MenuMail=0


		select @AE = valor from ccsettings where setting_id = 71
		select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

		---Checar si esta se aplica
		select @AVRS = valor from ccSettings where setting_id = 124
		select @IVRScripting = valor from ccsettings where setting_id = 125

		select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
		--Activa menus relacionados con campañas
		select @MenusChat = valor from ccsettings where setting_id = 145
		select @MenuMail = valor from ccsettings where setting_id = 155

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
			if (@InsertMenu_id <> 0) or not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
			begin	
				if @Role_id in (1, 10, 14) begin			
					if @InsertMenu_id <> 0 and not exists(select * from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
						insert into ccMenuUser (id_User, id_Menu, type) values(@User_id, @InsertMenu_id, @reportRol)
					if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40)begin						
						Insert into ccMenuUser (id_User, id_Menu, type)values(@User_id,40,@reportRol)		
					end
					else If @reportRol = 2 and not exists(select id_User from ccMenuUser where id_User = @User_id and (id_Menu between 1000 and 1999)) begin					
							Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, menu_id, @reportRol from ccMenus with(index(IX_ccMenus)) where menu_id between 1000 and 1999
						end
					else if @reportRol = 3 begin				
						insert into ccMenuUser (id_User, id_Menu, type) select @User_id, id_Menu, @reportRol from ccRIARoleMenu  where Role_id = @Role_id 			 			
					end
				end
				else if ((@InsertMenu_id = 53 and @NRS = 1) or (@InsertMenu_id <> 53) ) 
				begin			
					if @InsertMenu_id <> 40	delete ccMenuUser where id_User = @User_id and type = @reportRol		
						insert into ccMenuUser (id_User, id_Menu, type)	select @User_id, id_Menu, @reportRol from ccRIARoleMenu where Role_id = @Role_id and type = @reportRol
					if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40 and type = @reportRol)
						insert into ccMenuUser (id_User, id_Menu, type) values(@User_id,40,@reportRol)
				end		
			end		
			--Asigna un rol por default o lo actuliza
			if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
				Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
			else
				insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
			
			--Solo es necesario en caso admin y reports
			if @reportRol in(1,2) begin 
				--    inserta parent en caso de no haberlo hecho en rol personalizado        
				insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from               
				(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
				where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
				where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0

				select @User_id, parent, @reportRol from               
				(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
				where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
				where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0
				
			end
			return (0)
		 end

		If @Type = 5 -- delete
		 begin
		      delete ccMenuUser where id_User = @User_id and id_Menu = @DeleteMenu_id and type = @reportRol
		      if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
				Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
		      else
				insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
		      return(0)
		 end

		If @Type = 6 -- Get userMenus
		 begin
			if @reportRol = 2 begin --Reports version vieja
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
			else begin ---Sitio del administrador
				if not exists( select * from ccRIAUsr_AdminPermissions where User_id=@user_id and per_id=6)
				set @AVRS =0
				
				select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
		      
			  from ccRIAUserRole a 
				inner join ccMenuUser b on a.user_id = b.id_user
				inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
		      where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol 
				and (	
					(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82)) 
					or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)
					or (menu_id in (71,72) and @IVRScripting = 1)		
					or (menu_id in (73,74,75,76) and @AVRS = 1)
					or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
					or (menu_id = 79 and @MenusChat > 0)
					or (menu_id in (81,82) and @MenuMail = 1)--Mail
					)
		      order by ordengral asc
				return(0)
			end
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
		 
			  if @AVRS = 1
				begin 	
					update ccUsers set tipoUser_id = 6 where user_id = @User_id 
					return(0)
				end
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
		 
		 if @Type = 13 --Agrega Menus por default a Admin en ReportsRia Agentes,ACD y Campañas
		 begin
			insert into ccMenuUser([id_user],[id_Menu],[type])
			select a.User_id, b.menu_id, b.type 
				from ccUsers a cross join ccMenus b
				left join ccMenuUser d on d.id_User = a.User_id and d.id_Menu = b.menu_id	
				where a.TipoUser_id = 2 and b.type = 3 and d.id_User IS null and 
				b.menu_id >= 2000 and b.menu_id < 5000 and a.User_id = @User_id

			insert into ccRIAUserRole([User_id],[Role_id],[type])
				select a.[User_id], 14 as role_id, 3 as type from ccUsers a
					left join ccRIAUserRole d on d.User_id = a.User_id and d.type = 3
					where d.User_id IS null and a.TipoUser_id = 2 and a.User_id = @User_id
						
			return (0)
			
		 end

		return(0)
		set nocount off'	

	EXEC(@Sql)

	set @process = 'Alter SP -- ccsp_AgentUpdateCallCALIF'
	set @Sql='ALTER procedure [dbo].[ccsp_AgentUpdateCallCALIF]
@IDCall int,
@calif_id smallint,
@TipoCall smallint,
@Origin int=0,
@cal_key varchar(20)=null,
@callOutId int=0,
@subId smallint=0
as
set nocount on
declare @RecicleSIC tinyint, @Reprogram tinyint, @DateNewDial smalldatetime, @idTipoLista int, @autoCB tinyint, @tel varchar(30), @camp int, @iddncList as int
declare @userid int
select @RecicleSIC=valor FROM ccSettings WHERE setting_id=60
select @RecicleSIC=IsNull(@RecicleSIC, 0)

if @TipoCall=1
 begin
	Update ccCallsIN Set calif_id=@calif_id, cal_origin_id=@Origin, cal_key=isnull(@cal_key, cal_key), 
	califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall
	return(0)
 end

if @TipoCall=2
 begin
 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @autoCB=autocallback from ccTipoCalifSubout where califSub_Id = @subId
	
	-- Si no tiene subcalificacion toma la de la calificacion
	if @autoCB is null
	 begin
		select @autoCB = autocallback from cctipocalifout where calif_id = @calif_id
	 end

	if @autoCB = 1
	begin
		select @callOutId=callout_id, @camp=cam_id,@userid=user_id from ccocallsout where Cal_id=@IDCall
		select @DateNewDial=dateadd(mi,t_autoCB,getdate()) from cccamps cam where cam.cam_id = @camp

		exec ccsp_OUTInsertaCallBack @IDCall, '''', @camp, @DateNewDial, @callOutId, 1, @userid, '''', 1
	end

	Update ccoCallsOUT Set calif_id=@calif_id, califSub_id=case @subId when 0 then null else @subId end Where cal_id=@IDCall

	if exists(select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id)
	and not exists (select co.cal_telefono from ccoCallsOut co with (index (PK_ccoCallsOut))
	join ccListaNegra bl on dbo.Completa_ListaNegra(co.cal_telefono)=bl.telefono or co.cal_telefono=bl.telefono where co.cal_id=@idCall
	and bl.idtipolista in (select idTipoLista from cccalifblacklist with(index(IX_cccalifblacklist)) where tipo = 1 and calif_id=@calif_id))
	 begin		
		select @tel=dbo.Completa_ListaNegra(co.cal_telefono), @iddncList = cbl.idTipoLista 
		from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
		where co.cal_id=@idCall and left(dbo.Completa_ListaNegra(co.cal_telefono),1)<>''E'' and cbl.tipo=1


		if @tel is not null and @iddncList is not null begin
			exec ccsp_InsertDNCList @tel, @iddncList

			insert ccHistorialListaNegra (telefono, idtipolista, cam_id, fecha, callout_id, idtipomov)
			select dbo.Completa_ListaNegra(co.cal_telefono), cbl.idTipoLista, co.cam_id, getdate(), co.callout_id, 6
			from ccoCallsOut co with (index (PK_ccoCallsOut)) join cccalifblacklist cbl on co.calif_id=cbl.calif_id
			where co.cal_id=@idCall and left(dbo.Completa_ListaNegra(co.cal_telefono),1)<>''E'' and cbl.tipo=1
		end
	 end

	if @RecicleSIC=1
	 begin
	 	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
		select @Reprogram=CanReprogram from ccTipoCalifSubout where califSub_Id = @subId
		
		-- Si no tiene subcalificacion toma la de la calificacion
		if @Reprogram is null
		 begin
			select @Reprogram=CanReprogram from ccTipoCalifOUT where calif_id=@calif_id
		 end

		if @callOutId=0
			select @callOutId=callout_id from ccocallsout where Cal_id=@IDCall

		Update ccoWorkingTable Set calif_id=@calif_id, 
		 cal_status=case @Reprogram when 0 then 3 else cal_status end
		Where callout_id=@callOutId

	 end
	declare @keepDial bit
	-- Toma como prioridad la configuración de la subcalificación (en caso de existir)
	select @keepDial=keepDial from ccTipoCalifSubout where califSub_Id = @subId
	
	-- Si no tiene subcalificacion toma la de la calificacion
	if @keepDial is null
	 begin
		select @keepDial=keepDial from ccTipoCalifout where calif_id = @calif_id
	 end

	if @keepDial=1
	 begin
		update ccologdials set TipoDialingMode=dbo.fn_getDialingMode(@IDCall, 3, 0, @camp) 
		where logDial_id in (select top 1 L.logDial_id from 
			ccoLogDials L with(index(IX_ccoLogDials_2), nolock) 
			 join ccoCallsOut O with(index(PK_ccoCallsOut), nolock) 
			 on L.callout_id = O.callout_id where O.cal_id=@IDCall
			order by L.logDial_id desc)
	 end
	 
	select @keepDial
	return(0)
 end

set nocount off'	
		
	EXEC(@Sql)

	set @process = 'Alter SP -- ccsp_Limpia'
	set @Sql='ALTER procedure [dbo].[ccsp_Limpia]
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

set nocount off'	
		
	EXEC(@Sql)

	set @process = 'Alter SP -- ccspADM_AniListLD'
	set @Sql='ALTER PROCEDURE [dbo].[ccspADM_AniListLD]
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
	
	EXEC(@Sql)

	set @process = 'ALTER SP -- ccsp_RIAccSettingsConfig'
	set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAccSettingsConfig]
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
	from ccSettings WITH(NOLOCK, index(PK_ccSettings)) where tipo in (''AGT'',''ADM'',''GRL'',''REP'') 
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
	else if @setting_id = 104 and @value not in(''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'',''10'',''11'') begin
		set @value = 1
	end
	update ccSettings set valor=@value where setting_id = @setting_id
	return(0)
 end

set nocount off'	
	
	EXEC(@Sql)

	set @process = 'ALTER function -- TelAni'
	set @Sql='ALTER function [dbo].[TelAni](@tel varchar(32), @lista smallint)
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

	return @ret
END'	
	
	EXEC(@Sql)


	set @process = 'Alter SP --- ccsp_GetAgentIndividualCounters'
	set @Sql='ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters] @type as int, @sup_id as int = 0 as
set nocount on

declare @fecha_ini datetime
select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

if @type = 1 --Session time
	begin
		SELECT User_id, case 
			WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0 
				THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))  
			ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) + 
				convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
			END as logintime
		FROM ccLogLogin a with(index(IX_ccLogLogin_4)), ccGenViewRelsSupsAgent b
		where fecha >= @fecha_ini
		and a.User_id = b.agt
		and b.sup = @sup_id
		GROUP BY User_id
	end

if @type = 2 --Status agent
	begin
		SELECT User_id, TipoStatusAge_id, sum(tStatus) As segundos 
		FROM ccLogAgentesDia a with(index(IX_ccLogAgentesDia_4)), ccGenViewRelsSupsAgent b 
		WHERE fecha >= @fecha_ini
		AND a.User_id = b.agt
		and b.sup = @sup_id
		GROUP BY User_id, TipoStatusAge_id 
		ORDER BY User_id
	end

if @type = 3
	begin

        select calls.*, users.login
		from ccusers As users ,
        (
			SELECT User_id AS ''user_id'' , count(*) AS ''total_calls'', 
			CASE  
			  WHEN statuscall_id = 15 THEN 5  --OutBound Asignada pero no contestada          
			  WHEN cal_manual = 2 THEN 3      --OutBound llamada manual
			  ELSE 2                          --Llamada de OutBound          
			END AS ''type_calls''
			FROM ccoCallsOut a WITH (NOLOCK index(IX_ccoCallsOut_10)) , ccGenViewRelsSupsAgent b
			WHERE a.User_id = b.agt
			and b.sup = @sup_id
			AND statuscall_id <> 11  --OutBound sin estado definitivo 
			AND cal_inicio >= @fecha_ini		
			GROUP BY User_id, statuscall_id, cal_manual
	        
			UNION

			SELECT User_id AS ''user_id'' , count(*) AS ''total_calls'', 
			CASE  
			  WHEN statuscall_id = 15 THEN 4  --InBound Asignada pero no contestada          
			  ELSE 1                          --Llamada de InBound          
			END AS ''type_calls''
			FROM ccCallsIn a WITH (NOLOCK index(IX_ccCallsIn_5)), ccGenViewRelsSupsAgent b
			WHERE a.User_id = b.agt
			and b.sup = @sup_id
			AND statuscall_id <> 11  --InBound sin estado definitivo 
			AND cal_inicio >= @fecha_ini		
			GROUP BY User_id, statuscall_id
        ) AS calls 
        where users.user_id = calls.user_id	

	end

if @type = 4
	begin
        select a.user_id, a.login 
        from ccusers a, ccGenViewRelsSupsAgent b
		where user_id = b.agt
		and b.sup = @sup_id
    end

set nocount on'	
	
	EXEC(@Sql)

	set @process = 'Alter SP -- ccsp_RIAAgentGetDialMask'
	set @Sql='ALTER PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
@user_id integer,
@tel varchar(15)
AS
declare @mask integer, @idioma integer, @value integer, @lada integer
declare @country as tinyint

set @value = 0
select @mask = isnull(dialmask,7) from ccusers where user_id=@user_id
select @country = valor from ccsettings where setting_id = 104

-- Restricciones por pais 1:Mexico 2:Argentina 3:Colombia 4:USA 5:Chile 6:Venezuela 7:uk 8:Arabia Saudita, 9: Australia, 10:Brasil
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

select @value'	
	
	EXEC(@Sql)

	set @process = 'Alter funcion -- Completa'
	set @Sql='ALTER function [dbo].[Completa](@Cadena varchar(32))
RETURNS varchar(32) 
AS  
BEGIN
declare @resultado varchar(32)
declare @ld varchar(5)
declare @pais varchar(2)

select @pais = valor from ccSettings where setting_id = 104
select @ld = valor from ccSettings where setting_id = 17
select @resultado = dbo.limpia(@Cadena)

--Completa 1:México 2:Argentina 3:Colombia 4:USA 5:Chile 6: venezuela 7: UK 8: arabia saudita 9: Australia 10:Brasil 11:Guatemala
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


-- Termina
return @resultado

end'	
	
	EXEC(@Sql)

	set @process = 'Alter Function -- Completa_ListaNegra'
	set @Sql='ALTER FUNCTION [dbo].[Completa_ListaNegra] (@Cadena varchar(30))
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

end
else begin
 select @resultado = dbo.Limpia(@cadena)
end 

return @resultado
end'	
	
	EXEC(@Sql)

	set @process = 'Alter Function -- fnGetTimeZone'
	set @Sql='ALTER FUNCTION [dbo].[fnGetTimeZone](@phone varchar(20), @bIsDaylight bit)
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

	return isNull(@timeZone,0)
 END'	
	
	EXEC(@Sql)	

	set @process = 'Alter funcion -- Verifica'
	set @Sql='ALTER FUNCTION [dbo].[Verifica](@tel varchar(32))
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

	return @tel
 end'	
	
	EXEC(@Sql)

	set @process = 'ALTER - Job CW Delete old records'
	set @Sql='USE [msdb]
/****** Object:  Job [ShrinkLogCCenterRia]    Script Date: 07/09/2014 19:44:44 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''CW Delete old records'')
EXEC msdb.dbo.sp_delete_job @job_name=N''CW Delete old records'', @delete_unused_schedule=1

/****** Object:  Job [CW Delete old records]    Script Date: 14/08/2014 04:30:35 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 14/08/2014 04:30:35 PM ******/
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
/****** Object:  Step [Run sp]    Script Date: 14/08/2014 04:30:35 PM ******/
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
		@command=N''set nocount on

declare @meses int
set @meses = 9

-- Delete all the information
truncate table cclogInfo
truncate table ccBorrardasReciclaje
truncate table ccUploadTemporal
truncate table ccLogCampsAgentesDia 

-- Delete in order to have information for the last 15 days
delete ccRIAWorkGroup_logDial_id with(rowlock) where timestamp < dateadd(dd, -15, getdate())
delete ccRIAWorkGroup_Calid with(rowlock) where timestamp < dateadd(dd, -15, getdate())
delete ccRIALogAgentesNotReady with(rowlock) where fecha < dateadd(dd, -15, getdate())
delete ccPosicionEspecialidad with(rowlock) where Fecha < dateadd(dd, -15, getdate())
delete ccPosicionCamps with(rowlock) where Fecha < dateadd(dd, -15, getdate())
delete ccocallbacks with(rowlock) where cal_fecha < dateadd(dd, -15, getdate())
delete ccLogReciclaje with(rowlock) where fecha < dateadd(dd, -15, getdate())

-- Delete in order to have information for the last month
delete ccRIAcallbacks with(rowlock) where año < datepart(yy,getdate())
delete ccRIAcallbacks with(rowlock) where mes < datepart(mm,getdate())

-- Delete in order to have information for the last 9 months
-- Centerware tables
delete cchistoriallistanegra with(rowlock) where fecha < dateadd(mm, -@meses, getdate())
delete ccRIAlog with(rowlock) where operationDate < dateadd(mm, -@meses, getdate())
delete ccRiaChat_log with(rowlock) where fecha_chat < dateadd(mm, -@meses, getdate())
delete xxclientehistorial with(rowlock) where fechaAct < dateadd(mm, -@meses, getdate())
delete ccLogAgentesDia with(rowlock) where fecha < dateadd(mm, -@meses, getdate())
delete ccLogAgentesNotReady with(rowlock) where fecha < dateadd(mm, -@meses, getdate())
delete ccLogLogin with(rowlock) where fecha < dateadd(mm, -@meses, getdate())
delete ccoLogDials with(rowlock) where fecha < dateadd(mm, -@meses, getdate())
delete ccoCallsOut with(rowlock) where cal_inicio < dateadd(mm, -@meses, getdate())
delete ccoWorkingTable with(rowlock) where cal_fechadial < dateadd(mm, -@meses, getdate())
delete ccoCallsOutSource with(rowlock) where cal_fechadial < dateadd(mm, -@meses, getdate())
delete cccallsreject with(rowlock) where cal_inicio < dateadd(mm, -@meses, getdate())
delete ccLogtransfers with(rowlock) where fechaFin < dateadd(mm, -@meses, getdate())
delete ccCallsIn with(rowlock) where cal_Inicio < dateadd(mm, -@meses, getdate())
delete ccriachats with(rowlock) where chatDate < dateadd(mm, -@meses, getdate())
delete ivrcallsin with(rowlock) where date < dateadd(mm, -@meses, getdate())
delete ivroptions with(rowlock) where date < dateadd(mm, -@meses, getdate())
delete ccLogAgentesDia_Dialog with(rowlock) where fecha_Dialog < dateadd(mm, -@meses, getdate())
delete ccCampsMovs with(rowlock) where fecha < dateadd(mm, -@meses, getdate())
delete ccRIALoading with(rowlock) where loadDate < dateadd(mm, -@meses, getdate())

-- Reports old version tables
delete ccGenAgent with(rowlock) where timegroup < dateadd(mm, -@meses, getdate())
delete ccGenAgentNotReady with(rowlock) where timegroup < dateadd(mm, -@meses, getdate())
delete ccGenInAbnd with(rowlock) where timegroup < dateadd(mm, -@meses, getdate())
delete ccGenInAnsw with(rowlock) where timegroup < dateadd(mm, -@meses, getdate())
delete ccGenInCalif with(rowlock) where timegroup < dateadd(mm, -@meses, getdate())
delete ccGenInCall with(rowlock) where timegroup < dateadd(mm, -@meses, getdate())
delete ccGenInCallDNI with(rowlock) where timegroup < dateadd(mm, -@meses, getdate())
delete ccGenInSpec with(rowlock) where timegroup < dateadd(mm, -@meses, getdate())
delete ccGenOutCall with(rowlock) where timegroup < dateadd(mm, -@meses, getdate())
delete ccGenOutCallCalif with(rowlock) where timegroup < dateadd(mm, -@meses, getdate())
delete ccGenOutCallDials with(rowlock) where timegroup < dateadd(mm, -@meses, getdate())
delete ccGenOutCamp with(rowlock) where timegroup < dateadd(mm, -@meses, getdate())
delete ccGenSession with(rowlock) where login < dateadd(mm, -@meses, getdate())'', 
		@database_name=N''CCenterRia'', 
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
