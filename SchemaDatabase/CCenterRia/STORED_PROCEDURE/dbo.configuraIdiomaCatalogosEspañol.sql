CREATE PROCEDURE [dbo].[configuraIdiomaCatalogosEspañol]
AS
Print 'Iniciando proceso de configuracion en Español'

Print 'Estableciendo Horarios'
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT ('[ccHorarios]', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N'Semana' collate SQL_Latin1_General_CP1_CI_AS), 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N'Nocturno' collate SQL_Latin1_General_CP1_CI_AS), 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N'Sabado' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N'Domingo' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print 'Estableciendo Not Ready y graficas'
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT ('[ccTipoNotReady]', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N'No Clasificado' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N'Break' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N'Tocador' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N'Con Cliente' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N'Supervisor' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N'Aclaracion' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N'Junta' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N'Comida' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N'Sistemas' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N'Otro' collate SQL_Latin1_General_CP1_CI_AS))

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
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, convert(text, N'Inicial' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, convert(text, N'Fuera de Horario' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, convert(text, N'Fuera de Servicio' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, convert(text, N'Sin Agentes Firmados' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, convert(text, N'En espera' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, convert(text, N'Colgada' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, convert(text, N'Desborde por Tiempo' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, convert(text, N'Desborde por Cantidad' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, convert(text, N'Con Mensaje' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, convert(text, N'Asignada Mensaje' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, convert(text, N'Asignada' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, convert(text, N'Atendida Mensaje' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, convert(text, N'Contestada' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, convert(text, N'Cancelada Mensaje' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, convert(text, N'Asignada y No Contestada' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, convert(text, N'Asignada y Toma Linea' collate SQL_Latin1_General_CP1_CI_AS))
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8 )

Print 'Estableciendo los tipos de dias'
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, convert(text, N'Lunes' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, convert(text, N'Martes' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, convert(text, N'Miercoles' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, convert(text, N'Jueves' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, convert(text, N'Viernes' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, convert(text, N'Sabado' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, convert(text, N'Domingo' collate SQL_Latin1_General_CP1_CI_AS))

Print 'Estableciendo resultados de marcacion'
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, convert(text, N'Contestan' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, convert(text, N'Ocupado' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, convert(text, N'No Contesta' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, convert(text, N'Fax/Modem' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, convert(text, N'NoDialTone' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, convert(text, N'Otro' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, convert(text, N'NoService' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, convert(text, N'Buzon/Maquina' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, convert(text, N'Congestion' collate SQL_Latin1_General_CP1_CI_AS))

Print 'Estableciendo los tipos de estado de los agentes'
Delete [dbo].[ccTipoStatusAgente]
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, convert(text, N'LogOut' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, convert(text, N'Desconocido' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, convert(text, N'No Disponible' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, convert(text, N'Disponible' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, convert(text, N'Dialogo' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, convert(text, N'Transferencia' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, convert(text, N'Notas' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, convert(text, N'Otra' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, convert(text, N'Cliente' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, convert(text, N'Ringing' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, convert(text, N'Problema' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, convert(text, N'Espera llamada manual' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N'ChatReq' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N'Chatting' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, convert(text, N'Transferencia Fallida' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, convert(text, N'Ringing Fallida' collate SQL_Latin1_General_CP1_CI_AS))

Print 'Estableciendo los tipos de usuario'
Delete [dbo].[ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, convert(text, N'Agente' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, convert(text, N'Supervisor' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, convert(text, N'AVRS Calidad' collate SQL_Latin1_General_CP1_CI_AS))

Print 'Estableciendo los dias'
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, convert(text, N'Domingo' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, convert(text, N'Lunes' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, convert(text, N'Martes' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, convert(text, N'Miercoles' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, convert(text, N'Jueves' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, convert(text, N'Viernes' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, convert(text, N'Sabado' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccDias] OFF

Print 'Estableciendo los tipos de llamada'
truncate table cstoTarifa
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,'Local','7|8','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,'LD nacional','12','01%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,'Cel','13','044%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,'Cel LD','13','045%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,'01800','12','01800%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,'LD USA','13','001%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,'LD inter','0','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,'On Net','10','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,'Off Net','10','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,'On Ring','10','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,'Triangle','10','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,'LADA local 2 dígitos','8','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,'Local lada 3 digitos','7','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,'Local lada 4 digitos','6','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,'Cel LADA local 2 dígitos','10','15%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,'Cel LADA local 3 dígitos','9','15%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,'Cel LADA local 4 dígitos','8','15%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,'Larga distancia','11','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,'Cel larga distancia','13','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,'Local','7','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,'LD','8','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,'Celular','11','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,'Local','7','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,'LD Nacional','11','1%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,'Local','9','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,'LD Nacional','10','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,'Local','7','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,'LD','11','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,'Celular','11','04%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,'Local','10','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,'LD','11','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,'Cel','11','07%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,'LD inter','13','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,'Local','7','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,'LD anterior','9','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,'Cel','10','05%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,'LD actual','11','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,'LD inter','13','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,'Local','10','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,'LD inter','0','0011%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,'Cel','10','04%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,'Local','8','2%|3%|4%|5%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,'Movil ','8','6%|7%|8%|9%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,'Celular 9 dígitos ','9','9%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,'LD Nacional','10','02%|03%|04%|05%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,'Cel LD nacional','10','06%|07%|08%|09%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,'Cel LD nacional 9 dígitos','11','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,'LD internacional','19','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,'Local','8','2%|6%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,'Movil','8','3%|4%|5%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,'LD Nacional','8','7%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,'LD internacional','8','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,'Local','8','2%|3%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,'Telefonía SIP','8','4%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,'Telefonía móvil','8','5%|6%|7%|8%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,'LD internacional','0','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,'Cobro Revertido','10','800%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,'Tarifa Prima','10','90%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,'Acceso Internet','10','900%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,'Especial','0','08%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,'Fijo','8','2%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,'Movil','8','6%|7%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,'LD internacional','0','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,'Local','9','8%|9%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,'Celular','9','6%|7%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,'LD internacional','0','00%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,'Servicios web','9','5%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,'Local','6|7','%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,'LD nacional','9','0%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,'Cel','9','9%')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,'LD inter','0','00%')

Print 'Estableciendo los movimientos de lista negra'
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, convert(text, N'Carga Lista Negra' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, convert(text, N'Lista Negra en Carga de Registros' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, convert(text, N'Eliminado por Aplicar Lista Negra' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, convert(text, N'Eliminado de Lista Negra por Remplazo ' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, convert(text, N'Borrado de Lista Negra' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print 'Estableciendo los tipos de calificacion'
Delete [dbo].[ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, convert(text, N'Solicita información general' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, convert(text, N'Se cortó la llamada' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, convert(text, N'Número equivocado' collate SQL_Latin1_General_CP1_CI_AS), 0)

Print 'Estableciendo los tipos de calificacion de salida'
Delete [dbo].[ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, convert(text, N'Gestión Efectiva' collate SQL_Latin1_General_CP1_CI_AS), 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, convert(text, N'Se deja recado' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, convert(text, N'Numero Equivocado' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 3)

Print 'Estableciendo proveedores'
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT ('[cstoProvedor]', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES ('Telmex')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES ('Maxcom')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES ('Avantel')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES ('AT&T')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES ('Telnor')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES ('Axtel')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES ('Telular')

Print 'Mensajes default chat'
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_Sp\Default5', '!Bienvenido!')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_Sp\Default3', 'El servicio no se encuentra disponible')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_Sp\Default2', 'Nuestro horario de atención ha terminado')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_Sp\Default1', 'Por favor espere mientras uno de nuestros agentes se encuentra disponible')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_Sp\Default7', 'No hay agentes disponibles')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_Sp\Default10', 'No podemos tomar su solicitud')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_Sp\Default12', 'La sesión de chat ha estado inactiva mucho tiempo')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values('Default_Sp\Default13', 'La sesión de chat ha concluido')