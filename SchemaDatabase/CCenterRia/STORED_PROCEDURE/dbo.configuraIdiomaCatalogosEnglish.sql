CREATE PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
AS
Print 'Iniciando proceso de configuracion en Ingles'

Print 'Estableciendo Horarios'
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT ('[ccHorarios]', RESEED, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES ('Week', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES ('Night shift', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES ('Saturday', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES ('Sunday', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print 'Estableciendo Not Ready y graficas'
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT ('[ccTipoNotReady]', RESEED, 0)
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES ('Not Clasified')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES ('Break')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES ('Bathroom')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES ('With client')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES ('Supervisor')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES ('Clarification')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES ('Meeting')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES ('Lunch')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES ('Systems')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES ('Other')

--EXEC sp_generate_inserts 'ccRIANotReadyGraph'
DBCC CHECKIDENT ('[ccRIAGraphics]', RESEED, 0)
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

Print 'Estableciendo Status de llamadas'
TRUNCATE TABLE [dbo].[ccStatusLLamada]
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, 'Initial')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, 'Out of Schedule')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, 'Out of Service')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, 'No Agents Logged in')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, 'On Hold')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, 'Abandoned')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, 'Time overflow')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, 'Queue size overflow')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, 'With Message')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, 'Assigned Message')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, 'Assigned')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, 'Attended Message')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, 'Answered')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, 'Canceled Message')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, 'Assigned and Not Answered')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, 'Assigned and took line')
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print 'Estableciendo los tipos de dias'
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (1, 'Monday')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (2, 'Tuesday')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (3, 'Wednesday')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (4, 'Thursday')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (5, 'Friday')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (6, 'Saturday')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (7, 'Sunday')

Print 'Estableciendo resultados de marcacion'
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, 'Answer')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, 'Busy')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, 'Not Answer')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, 'Fax/Modem')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, 'NoDialTone')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, 'Other')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, 'NoService')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, 'VoiceMail/Machine')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, 'Circuit busy')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, 'Cancelled')

Print 'Estableciendo los tipos de estado de los agentes'
DELETE [dbo].[ccTipoStatusAgente]
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, 'LogOut')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, 'Unknown')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, 'Not Ready')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, 'Ready')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, 'Talking')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, 'Transfer')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, 'Wrapup')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, 'Other')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, 'Client')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, 'Ringing')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, 'Problem')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, 'Wait for manual call')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N'ChatReq' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N'Chatting' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, 'Xfer Fail')
INSERT [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, 'Ringing Fail')

Print 'Estableciendo los tipos de usuario'
Delete [dbo].[ccTipoUsers]
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, 'Agent')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, 'Supervisor')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, 'AVRS Access')

Print 'Estableciendo los dias'
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [dbo].[ccDias] ON
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (1, 'Sunday')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (2, 'Monday')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (3, 'Tuesday')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (4, 'Wednesday')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (5, 'Thursday')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (6, 'Friday')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (7, 'Saturday')
SET IDENTITY_INSERT [dbo].[ccDias] OFF

truncate table cstoTarifa

Print 'Estableciendo los tipos de llamada'
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,'Local','7|8','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,'National LD','12','01%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,'Mobile','13','044%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,'LD Mobile','13','045%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,'01800','12','01800%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,'USA LD','13','001%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,'Inter LD','0','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,'On Net','10','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,'Off Net','10','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,'On Ring','10','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,'Triangle','10','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,'2-digit Local Area Code','8','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,'3-digit Local Area Code','7','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,'4-digit Local Area Code','6','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,'2-digit Local Mobile Area Code','10','15%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,'3-digit Local Mobile Area Code','9','15%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,'4-digit Local Mobile Area Code','8','15%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,'Long Distance','11','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,'Long Distance Mobile','13','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,'Local','7','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,'LD','8','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,'Mobile','11','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,'Local','7','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,'National LD','11','1%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,'Local','9','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,'National LD','10','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,'Local','7','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,'LD','11','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,'Mobile','11','04%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,'Local','10','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,'LD','11','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,'Mobile','11','07%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,'Inter LD','13','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,'Local','7','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,'Old LD','9','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,'Mobile','10','05%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,'New LD','11','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,'Inter LD','13','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,'Local','10','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,'Inter LD','0','0011%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,'Mobile','10','04%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,'Local','8','2%|3%|4%|5%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,'Mobile ','8','6%|7%|8%|9%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,'9-digit Mobile','9','9%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,'National LD','10','02%|03%|04%|05%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,'National Mobile LD','10','06%|07%|08%|09%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,'9-digit National Mobile LD','11','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,'International LD','19','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,'Local','8','2%|6%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,'Mobile','8','3%|4%|5%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,'National LD','8','7%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,'International LD','8','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,'Local','8','2%|3%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,'SIP Telephony','8','4%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,'Mobile Telephony','8','5%|6%|7%|8%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,'International LD','0','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,'Reverse Charge','10','800%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,'Premium Rate','10','90%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,'Internet Access','10','900%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,'Special','0','08%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,'Landline','8','2%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,'Mobile','8','6%|7%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,'International LD','0','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,'Local','9','8%|9%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,'Mobile','9','6%|7%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,'International LD','0','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,'Webservices','9','5%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,'Local','6|7','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,'National LD','9','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,'Mobile','9','9%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,'Inter LD','0','00%')

Print 'Estableciendo los movimientos de lista negra'
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] ON
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, 'Added to black list')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, 'Blocked on loading')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, 'Removed from campaign')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, 'Replaced from black list')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, 'Deleted from black list')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, 'Added by Disposition')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, 'Load black list')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, 'Load customer black list')
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] OFF

Print 'Estableciendo los tipos de calificacion'
Delete [dbo].[ccTipoCalif]
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, 'Wrong area', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, 'Disconnected call', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, 'Wrong number', 0)

Print 'Estableciendo los tipos de calificacion de salida'
Delete [dbo].[ccTipoCalifOUT]
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, 'Effective call', 0, 0, 1)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, 'Leave a message', 0, 1, 2)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, 'Wrong number', 0, 1, 3)

Print 'Estableciendo proveedores'
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT ('[cstoProvedor]', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES ('Carrier 1')

Print 'Tipo Msg ChatLog' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
Update ccRIAChat_TipoMsg set MsgDetalle='Administrator writes an individual message to agent' where TipoMsgChat=1
Update ccRIAChat_TipoMsg set MsgDetalle='Agent writes a message to Administrator' where TipoMsgChat=2
Update ccRIAChat_TipoMsg set MsgDetalle='Administrator writes a global message' where TipoMsgChat=3

Print 'Mensajes defualt'
DELETE [dbo].[ccMsgFiles]
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( 'Default_En\Default5', 'Welcome message' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( 'Default_En\Default4', 'Transfer message' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( 'Default_En\Default3', 'Out of service message' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( 'Default_En\Default2', 'After hours message' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( 'Default_En\Default1', 'In queue message' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( 'Default_En\Default7', 'No agents signed in message' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( 'Default_En\Default9', 'VoiceMail message')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( 'Default_En\Default10', 'Overflow message')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( 'Default_En\Default11', 'DNC list')

Print 'Mensajes default chat'
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_En\Default5', 'Welcome!')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_En\Default3', 'Service currently unavailable')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_En\Default2', 'Our schedule service has finished')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_En\Default1', 'Please hold while one of our agents is available')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_En\Default7', 'There are not available agents')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_En\Default10', 'Your request can not be processed')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_En\Default12', 'Chat session has been inactive for too long')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_En\Default13', 'Chat session has finished')