UPDATE [dbo].[ccHorarios]
SET Descripcion = convert(text, N'Semana' collate SQL_Latin1_General_CP1_CI_AS),
    HoraInicio = 7,
    MinInicio = 0,
    HoraFin = 21,
    MinFin = 0,
    Lunes = 1,
    Martes = 1,
    Miercoles = 1,
    Jueves = 1,
    Viernes = 1,
    Sabado = 0,
    Domingo = 0
WHERE horario_id = 1;

UPDATE [dbo].[ccHorarios]
SET Descripcion = convert(text, N'Nocturno' collate SQL_Latin1_General_CP1_CI_AS),
    HoraInicio = 21,
    MinInicio = 0,
    HoraFin = 23,
    MinFin = 0,
    Lunes = 1,
    Martes = 1,
    Miercoles = 1,
    Jueves = 1,
    Viernes = 1,
    Sabado = 0,
    Domingo = 0
WHERE horario_id = 2;

UPDATE [dbo].[ccHorarios]
SET Descripcion = convert(text, N'Sabado' collate SQL_Latin1_General_CP1_CI_AS),
    HoraInicio = 8,
    MinInicio = 0,
    HoraFin = 20,
    MinFin = 0,
    Lunes = 0,
    Martes = 0,
    Miercoles = 0,
    Jueves = 0,
    Viernes = 0,
    Sabado = 1,
    Domingo = 0
WHERE horario_id = 3;

UPDATE [dbo].[ccHorarios]
SET Descripcion = convert(text, N'Domingo' collate SQL_Latin1_General_CP1_CI_AS),
    HoraInicio = 8,
    MinInicio = 0,
    HoraFin = 14,
    MinFin = 0,
    Lunes = 0,
    Martes = 0,
    Miercoles = 0,
    Jueves = 0,
    Viernes = 0,
    Sabado = 0,
    Domingo = 1
WHERE horario_id = 4;

-- Un solo SELECT al final para ver todos los cambios
SELECT * FROM [dbo].[ccHorarios];


-- ===========================
-- Actualización de ccTipoNotReady - SOLO UPDATE
-- ===========================

UPDATE [dbo].[ccTipoNotReady]
SET Descripcion = convert(text, N'No Clasificado' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoNotReady_id = 1;

UPDATE [dbo].[ccTipoNotReady]
SET Descripcion = convert(text, N'Break' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoNotReady_id = 2;

UPDATE [dbo].[ccTipoNotReady]
SET Descripcion = convert(text, N'Tocador' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoNotReady_id = 3;

UPDATE [dbo].[ccTipoNotReady]
SET Descripcion = convert(text, N'Con Cliente' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoNotReady_id = 4;

UPDATE [dbo].[ccTipoNotReady]
SET Descripcion = convert(text, N'Supervisor' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoNotReady_id = 5;

UPDATE [dbo].[ccTipoNotReady]
SET Descripcion = convert(text, N'Aclaracion' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoNotReady_id = 6;

UPDATE [dbo].[ccTipoNotReady]
SET Descripcion = convert(text, N'Junta' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoNotReady_id = 7;

UPDATE [dbo].[ccTipoNotReady]
SET Descripcion = convert(text, N'Comida' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoNotReady_id = 8;

UPDATE [dbo].[ccTipoNotReady]
SET Descripcion = convert(text, N'Sistemas' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoNotReady_id = 9;

UPDATE [dbo].[ccTipoNotReady]
SET Descripcion = convert(text, N'Otro' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoNotReady_id = 10;

-- Finalmente, un solo SELECT para ver todos los cambios
SELECT * FROM [dbo].[ccTipoNotReady];


-- ===========================
-- Actualización de ccStatusLLamada - SOLO UPDATE
-- ===========================

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Inicial' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 1;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Fuera de horario' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 2;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Fuera de servicio' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 3;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Sin agentes conectados' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 4;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'En espera' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 5;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Abandonada' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 6;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Desbordada (tiempo de espera excedido)' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 7;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Desbordada (número en espera excedido)' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 8;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Con Mensaje' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 9;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Asignada Mensaje' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 10;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Asignada en falla' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 11;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Atendida Mensaje' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 12;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Atendida' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 13;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Cancelada Mensaje' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 14;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Asignada y perdida' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 15;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Asignada en tono de línea' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 16;

UPDATE [dbo].[ccStatusLLamada]
SET descripcion = convert(text, N'Abandonada (Reminder)' collate SQL_Latin1_General_CP1_CI_AS)
WHERE statusCall_id = 18;

-- Finalmente, un solo SELECT para verificar todos los cambios
SELECT * FROM [dbo].[ccStatusLLamada];


-- ===========================
-- Actualización de ccTipoDias - SOLO UPDATE
-- ===========================

UPDATE [dbo].[ccTipoDias]
SET descripcion = convert(text, N'Lunes' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 1;

UPDATE [dbo].[ccTipoDias]
SET descripcion = convert(text, N'Martes' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 2;

UPDATE [dbo].[ccTipoDias]
SET descripcion = convert(text, N'Miercoles' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 3;

UPDATE [dbo].[ccTipoDias]
SET descripcion = convert(text, N'Jueves' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 4;

UPDATE [dbo].[ccTipoDias]
SET descripcion = convert(text, N'Viernes' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 5;

UPDATE [dbo].[ccTipoDias]
SET descripcion = convert(text, N'Sabado' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 6;

UPDATE [dbo].[ccTipoDias]
SET descripcion = convert(text, N'Domingo' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 7;

-- Un solo SELECT al final para validar todos los cambios
SELECT * FROM [dbo].[ccTipoDias];

-- ===========================
-- Actualización de ccTipoResultadoDial - SOLO UPDATE
-- ===========================

UPDATE [dbo].[ccTipoResultadoDial]
SET descripcion = convert(text, N'Contestan' collate SQL_Latin1_General_CP1_CI_AS)
WHERE tipoResDial_id = 1;

UPDATE [dbo].[ccTipoResultadoDial]
SET descripcion = convert(text, N'Ocupado' collate SQL_Latin1_General_CP1_CI_AS)
WHERE tipoResDial_id = 2;

UPDATE [dbo].[ccTipoResultadoDial]
SET descripcion = convert(text, N'No Contesta' collate SQL_Latin1_General_CP1_CI_AS)
WHERE tipoResDial_id = 3;

UPDATE [dbo].[ccTipoResultadoDial]
SET descripcion = convert(text, N'Fax/Modem' collate SQL_Latin1_General_CP1_CI_AS)
WHERE tipoResDial_id = 4;

UPDATE [dbo].[ccTipoResultadoDial]
SET descripcion = convert(text, N'NoDialTone' collate SQL_Latin1_General_CP1_CI_AS)
WHERE tipoResDial_id = 5;

UPDATE [dbo].[ccTipoResultadoDial]
SET descripcion = convert(text, N'Otro' collate SQL_Latin1_General_CP1_CI_AS)
WHERE tipoResDial_id = 8;

UPDATE [dbo].[ccTipoResultadoDial]
SET descripcion = convert(text, N'NoService' collate SQL_Latin1_General_CP1_CI_AS)
WHERE tipoResDial_id = 10;

UPDATE [dbo].[ccTipoResultadoDial]
SET descripcion = convert(text, N'Buzon/Maquina' collate SQL_Latin1_General_CP1_CI_AS)
WHERE tipoResDial_id = 11;

UPDATE [dbo].[ccTipoResultadoDial]
SET descripcion = convert(text, N'Congestion' collate SQL_Latin1_General_CP1_CI_AS)
WHERE tipoResDial_id = 12;

UPDATE [dbo].[ccTipoResultadoDial]
SET descripcion = convert(text, N'Cancelado' collate SQL_Latin1_General_CP1_CI_AS)
WHERE tipoResDial_id = 13;

-- Un solo SELECT para validar todos los cambios
SELECT * FROM [dbo].[ccTipoResultadoDial];

-- ===========================
-- Actualización de ccTipoStatusAgente - SOLO UPDATE
-- ===========================

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'LogOut' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 0;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Desconocido' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 1;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'No Disponible' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 2;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Disponible' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 3;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Dialogo' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 4;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Transferencia' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 5;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Notas' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 6;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Otra' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 7;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Cliente' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 8;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Ringing' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 9;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Problema' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 11;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Espera llamada manual' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 21;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'ChatReq' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 23;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Chatting' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 24;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Transferencia Fallida' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 25;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Ringing Fallida' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 26;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'ReconnectKolob' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 30;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Ready PreviewPro' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 31;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Preview' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 32;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Asistida' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 33;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Dialogo de Whatsapp' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 34;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Inactivo' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 35;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'En diálogo Correo' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 36;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Disponible auxiliar' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 37;

UPDATE [dbo].[ccTipoStatusAgente]
SET descripcion = convert(text, N'Transferencia Agent' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoStatusAge_id = 38;

-- Un solo SELECT para validar todos los cambios
SELECT * FROM [dbo].[ccTipoStatusAgente];

UPDATE [dbo].[ccTipoUsers]
SET descripcion = convert(text, N'Agente' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoUser_id = 1;

UPDATE [dbo].[ccTipoUsers]
SET descripcion = convert(text, N'Supervisor' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoUser_id = 2;

UPDATE [dbo].[ccTipoUsers]
SET descripcion = convert(text, N'AVRS Calidad' collate SQL_Latin1_General_CP1_CI_AS)
WHERE TipoUser_id = 6;

-- Un solo SELECT al final para verificar los cambios
SELECT * FROM [dbo].[ccTipoUsers];

-- ===========================
-- Actualización de ccDias - SOLO UPDATE
-- ===========================

UPDATE [dbo].[ccDias]
SET Name = convert(text, N'Domingo' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 1;

UPDATE [dbo].[ccDias]
SET Name = convert(text, N'Lunes' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 2;

UPDATE [dbo].[ccDias]
SET Name = convert(text, N'Martes' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 3;

UPDATE [dbo].[ccDias]
SET Name = convert(text, N'Miercoles' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 4;

UPDATE [dbo].[ccDias]
SET Name = convert(text, N'Jueves' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 5;

UPDATE [dbo].[ccDias]
SET Name = convert(text, N'Viernes' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 6;

UPDATE [dbo].[ccDias]
SET Name = convert(text, N'Sabado' collate SQL_Latin1_General_CP1_CI_AS)
WHERE dia_id = 7;

-- Un solo SELECT al final para verificar todos los cambios
SELECT * FROM [dbo].[ccDias];

-- ===========================
-- Actualización de cstoTipoLlamada - SOLO UPDATE
-- ===========================

UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '7|8', prefijo = '%' WHERE country_id = 1 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD nacional', longitud = '12', prefijo = '01%' WHERE country_id = 1 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cel', longitud = '13', prefijo = '044%' WHERE country_id = 1 AND tipoLlamada_id = 3;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cel LD', longitud = '13', prefijo = '045%' WHERE country_id = 1 AND tipoLlamada_id = 4;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = '01800', longitud = '12', prefijo = '01800%' WHERE country_id = 1 AND tipoLlamada_id = 5;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD USA', longitud = '13', prefijo = '001%' WHERE country_id = 1 AND tipoLlamada_id = 6;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD inter', longitud = '0', prefijo = '00%' WHERE country_id = 1 AND tipoLlamada_id = 7;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'On Net', longitud = '10', prefijo = '%' WHERE country_id = 1 AND tipoLlamada_id = 8;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Off Net', longitud = '10', prefijo = '%' WHERE country_id = 1 AND tipoLlamada_id = 9;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'On Ring', longitud = '10', prefijo = '%' WHERE country_id = 1 AND tipoLlamada_id = 10;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Triangle', longitud = '10', prefijo = '%' WHERE country_id = 1 AND tipoLlamada_id = 11;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LADA local 2 dígitos', longitud = '8', prefijo = '%' WHERE country_id = 2 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local lada 3 digitos', longitud = '7', prefijo = '%' WHERE country_id = 2 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local lada 4 digitos', longitud = '6', prefijo = '%' WHERE country_id = 2 AND tipoLlamada_id = 3;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cel LADA local 2 dígitos', longitud = '10', prefijo = '15%' WHERE country_id = 2 AND tipoLlamada_id = 4;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cel LADA local 3 dígitos', longitud = '9', prefijo = '15%' WHERE country_id = 2 AND tipoLlamada_id = 5;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cel LADA local 4 dígitos', longitud = '8', prefijo = '15%' WHERE country_id = 2 AND tipoLlamada_id = 6;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Larga distancia', longitud = '11', prefijo = '0%' WHERE country_id = 2 AND tipoLlamada_id = 7;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cel larga distancia', longitud = '13', prefijo = '0%' WHERE country_id = 2 AND tipoLlamada_id = 8;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '7', prefijo = '%' WHERE country_id = 3 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD', longitud = '8', prefijo = '%' WHERE country_id = 3 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Celular', longitud = '11', prefijo = '0%' WHERE country_id = 3 AND tipoLlamada_id = 3;

-- País 4
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '7', prefijo = '%' WHERE country_id = 4 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD Nacional', longitud = '11', prefijo = '1%' WHERE country_id = 4 AND tipoLlamada_id = 2;

-- País 5
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '9', prefijo = '%' WHERE country_id = 5 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD Nacional', longitud = '10', prefijo = '0%' WHERE country_id = 5 AND tipoLlamada_id = 2;

-- País 6
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '7', prefijo = '%' WHERE country_id = 6 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD', longitud = '11', prefijo = '0%' WHERE country_id = 6 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Celular', longitud = '11', prefijo = '04%' WHERE country_id = 6 AND tipoLlamada_id = 3;

-- País 7
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '10', prefijo = '%' WHERE country_id = 7 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD', longitud = '11', prefijo = '0%' WHERE country_id = 7 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cel', longitud = '11', prefijo = '07%' WHERE country_id = 7 AND tipoLlamada_id = 3;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD inter', longitud = '13', prefijo = '00%' WHERE country_id = 7 AND tipoLlamada_id = 4;

-- País 8
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '7', prefijo = '%' WHERE country_id = 8 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD anterior', longitud = '9', prefijo = '0%' WHERE country_id = 8 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cel', longitud = '10', prefijo = '05%' WHERE country_id = 8 AND tipoLlamada_id = 3;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD actual', longitud = '11', prefijo = '0%' WHERE country_id = 8 AND tipoLlamada_id = 4;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD inter', longitud = '13', prefijo = '00%' WHERE country_id = 8 AND tipoLlamada_id = 5;

-- País 9
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '10', prefijo = '%' WHERE country_id = 9 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD inter', longitud = '0', prefijo = '0011%' WHERE country_id = 9 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cel', longitud = '10', prefijo = '04%' WHERE country_id = 9 AND tipoLlamada_id = 3;

-- País 10
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '8', prefijo = '2%|3%|4%|5%' WHERE country_id = 10 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Movil ', longitud = '8', prefijo = '6%|7%|8%|9%' WHERE country_id = 10 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Celular 9 dígitos ', longitud = '9', prefijo = '9%' WHERE country_id = 10 AND tipoLlamada_id = 3;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD Nacional', longitud = '10', prefijo = '02%|03%|04%|05%' WHERE country_id = 10 AND tipoLlamada_id = 4;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cel LD nacional', longitud = '10', prefijo = '06%|07%|08%|09%' WHERE country_id = 10 AND tipoLlamada_id = 5;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cel LD nacional 9 dígitos', longitud = '11', prefijo = '%' WHERE country_id = 10 AND tipoLlamada_id = 6;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD internacional', longitud = '19', prefijo = '00%' WHERE country_id = 10 AND tipoLlamada_id = 7;

-- País 11
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '8', prefijo = '2%|6%' WHERE country_id = 11 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Movil', longitud = '8', prefijo = '3%|4%|5%' WHERE country_id = 11 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD Nacional', longitud = '8', prefijo = '7%' WHERE country_id = 11 AND tipoLlamada_id = 3;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD internacional', longitud = '8', prefijo = '00%' WHERE country_id = 11 AND tipoLlamada_id = 4;

-- País 12
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '8', prefijo = '2%|3%' WHERE country_id = 12 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Telefonía SIP', longitud = '8', prefijo = '4%' WHERE country_id = 12 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Telefonía móvil', longitud = '8', prefijo = '5%|6%|7%|8%' WHERE country_id = 12 AND tipoLlamada_id = 3;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD internacional', longitud = '0', prefijo = '00%' WHERE country_id = 12 AND tipoLlamada_id = 4;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cobro Revertido', longitud = '10', prefijo = '800%' WHERE country_id = 12 AND tipoLlamada_id = 5;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Tarifa Prima', longitud = '10', prefijo = '90%' WHERE country_id = 12 AND tipoLlamada_id = 6;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Acceso Internet', longitud = '10', prefijo = '900%' WHERE country_id = 12 AND tipoLlamada_id = 7;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Especial', longitud = '0', prefijo = '08%' WHERE country_id = 12 AND tipoLlamada_id = 8;

-- País 13
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Fijo', longitud = '8', prefijo = '2%' WHERE country_id = 13 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Movil', longitud = '8', prefijo = '6%|7%' WHERE country_id = 13 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD internacional', longitud = '0', prefijo = '00%' WHERE country_id = 13 AND tipoLlamada_id = 3;

-- País 14
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '9', prefijo = '8%|9%' WHERE country_id = 14 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Celular', longitud = '9', prefijo = '6%|7%' WHERE country_id = 14 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD internacional', longitud = '0', prefijo = '00%' WHERE country_id = 14 AND tipoLlamada_id = 3;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Servicios web', longitud = '9', prefijo = '5%' WHERE country_id = 14 AND tipoLlamada_id = 4;

-- País 15
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Local', longitud = '6|7', prefijo = '%' WHERE country_id = 15 AND tipoLlamada_id = 1;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD nacional', longitud = '9', prefijo = '0%' WHERE country_id = 15 AND tipoLlamada_id = 2;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'Cel', longitud = '9', prefijo = '9%' WHERE country_id = 15 AND tipoLlamada_id = 3;
UPDATE [dbo].[cstoTipoLlamada] SET descrip = 'LD inter', longitud = '0', prefijo = '00%' WHERE country_id = 15 AND tipoLlamada_id = 4;

-- Final SELECT
SELECT * FROM [dbo].[cstoTipoLlamada]
ORDER BY country_id, tipoLlamada_id;

-- ===========================
-- Actualización de ccTipoMovsListaNegra - SOLO UPDATE
-- ===========================

UPDATE [dbo].[ccTipoMovsListaNegra]
SET movimiento = convert(text, N'Carga Lista Negra' collate SQL_Latin1_General_CP1_CI_AS)
WHERE idtipomov = 1;

UPDATE [dbo].[ccTipoMovsListaNegra]
SET movimiento = convert(text, N'Lista Negra en Carga de Registros' collate SQL_Latin1_General_CP1_CI_AS)
WHERE idtipomov = 2;

UPDATE [dbo].[ccTipoMovsListaNegra]
SET movimiento = convert(text, N'Eliminado por Aplicar Lista Negra' collate SQL_Latin1_General_CP1_CI_AS)
WHERE idtipomov = 3;

UPDATE [dbo].[ccTipoMovsListaNegra]
SET movimiento = convert(text, N'Eliminado de Lista Negra por Remplazo' collate SQL_Latin1_General_CP1_CI_AS)
WHERE idtipomov = 4;

UPDATE [dbo].[ccTipoMovsListaNegra]
SET movimiento = convert(text, N'Borrado de Lista Negra' collate SQL_Latin1_General_CP1_CI_AS)
WHERE idtipomov = 5;

UPDATE [dbo].[ccTipoMovsListaNegra]
SET movimiento = convert(text, N'Agregado por calificación por campaña' collate SQL_Latin1_General_CP1_CI_AS)
WHERE idtipomov = 6;

UPDATE [dbo].[ccTipoMovsListaNegra]
SET movimiento = convert(text, N'Carga Lista Negra' collate SQL_Latin1_General_CP1_CI_AS)
WHERE idtipomov = 7;

UPDATE [dbo].[ccTipoMovsListaNegra]
SET movimiento = convert(text, N'Carga Registro Cliente Lista Negra' collate SQL_Latin1_General_CP1_CI_AS)
WHERE idtipomov = 8;

UPDATE [dbo].[ccTipoMovsListaNegra]
SET movimiento = convert(text, N'Agregado por calificación por ACD' collate SQL_Latin1_General_CP1_CI_AS)
WHERE idtipomov = 9;

-- Un solo SELECT para validar los cambios
SELECT * FROM [dbo].[ccTipoMovsListaNegra];

-- ===========================
-- Actualización de ccTipoCalif - SOLO UPDATE
-- ===========================

UPDATE [dbo].[ccTipoCalif]
SET Description = convert(text, N'Solicita información general' collate SQL_Latin1_General_CP1_CI_AS),
    orden = 0
WHERE calif_id = 1;

UPDATE [dbo].[ccTipoCalif]
SET Description = convert(text, N'Se cortó la llamada' collate SQL_Latin1_General_CP1_CI_AS),
    orden = 0
WHERE calif_id = 2;

UPDATE [dbo].[ccTipoCalif]
SET Description = convert(text, N'Número equivocado' collate SQL_Latin1_General_CP1_CI_AS),
    orden = 0
WHERE calif_id = 3;

-- Un solo SELECT para validar todos los cambios
SELECT * FROM [dbo].[ccTipoCalif];

-- ===========================
-- Actualización de ccTipoCalifOUT - SOLO UPDATE
-- ===========================

UPDATE [dbo].[ccTipoCalifOUT]
SET Description = convert(text, N'Gestión Efectiva' collate SQL_Latin1_General_CP1_CI_AS),
    autoTime = 0,
    CanReprogram = 0,
    orden = 1
WHERE calif_id = 1;

UPDATE [dbo].[ccTipoCalifOUT]
SET Description = convert(text, N'Se deja recado' collate SQL_Latin1_General_CP1_CI_AS),
    autoTime = 0,
    CanReprogram = 1,
    orden = 2
WHERE calif_id = 2;

UPDATE [dbo].[ccTipoCalifOUT]
SET Description = convert(text, N'Numero Equivocado' collate SQL_Latin1_General_CP1_CI_AS),
    autoTime = 0,
    CanReprogram = 1,
    orden = 3
WHERE calif_id = 3;

-- Un solo SELECT para validar los cambios
SELECT * FROM [dbo].[ccTipoCalifOUT];

PRINT 'Mensajes voz default - Actualización por msg_id';

UPDATE [dbo].[ccMsgFiles]
SET msgFile = 'Default_Sp\Default5',
    Descripcion = 'Mensaje Bienvenida'
WHERE msg_id = 1;

UPDATE [dbo].[ccMsgFiles]
SET msgFile = 'Default_Sp\Default4',
    Descripcion = 'Mensaje Transferencia'
WHERE msg_id = 2;

UPDATE [dbo].[ccMsgFiles]
SET msgFile = 'Default_Sp\Default3',
    Descripcion = 'Mensaje Fuera de servicio'
WHERE msg_id = 3;

UPDATE [dbo].[ccMsgFiles]
SET msgFile = 'Default_Sp\Default2',
    Descripcion = 'Mensaje Fuera de horario'
WHERE msg_id = 4;

UPDATE [dbo].[ccMsgFiles]
SET msgFile = 'Default_Sp\Default1',
    Descripcion = 'Mensaje En espera'
WHERE msg_id = 5;

UPDATE [dbo].[ccMsgFiles]
SET msgFile = 'Default_Sp\Default7',
    Descripcion = 'Mensaje Sin agentes firmados'
WHERE msg_id = 6;

UPDATE [dbo].[ccMsgFiles]
SET msgFile = 'Default_Sp\Default9',
    Descripcion = 'Mensaje VoiceMail'
WHERE msg_id = 7;

UPDATE [dbo].[ccMsgFiles]
SET msgFile = 'Default_Sp\Default10',
    Descripcion = 'Mensaje Desborde'
WHERE msg_id = 8;

UPDATE [dbo].[ccMsgFiles]
SET msgFile = 'Default_Sp\Default11',
    Descripcion = 'Lista Negra'
WHERE msg_id = 9;

-- Visualización final para confirmar
SELECT * FROM [dbo].[ccMsgFiles];

-- ===========================
-- Actualización de ccRIAChatMsg - usando msg_id como clave
-- ===========================

UPDATE [dbo].[ccRIAChatMsg]
SET descripcion = 'Default_Sp\Default5',
    msg = '!Bienvenido!'
WHERE msg_id = 1;

UPDATE [dbo].[ccRIAChatMsg]
SET descripcion = 'Default_Sp\Default3',
    msg = 'El servicio no se encuentra disponible'
WHERE msg_id = 2;

UPDATE [dbo].[ccRIAChatMsg]
SET descripcion = 'Default_Sp\Default2',
    msg = 'Nuestro horario de atención ha terminado'
WHERE msg_id = 3;

UPDATE [dbo].[ccRIAChatMsg]
SET descripcion = 'Default_Sp\Default1',
    msg = 'Por favor espere mientras uno de nuestros agentes se encuentra disponible'
WHERE msg_id = 4;

UPDATE [dbo].[ccRIAChatMsg]
SET descripcion = 'Default_Sp\Default7',
    msg = 'No hay agentes disponibles'
WHERE msg_id = 5;

UPDATE [dbo].[ccRIAChatMsg]
SET descripcion = 'Default_Sp\Default10',
    msg = 'No podemos tomar su solicitud'
WHERE msg_id = 6;

UPDATE [dbo].[ccRIAChatMsg]
SET descripcion = 'Default_Sp\Default12',
    msg = 'La sesión de chat ha estado inactiva mucho tiempo'
WHERE msg_id = 7;

UPDATE [dbo].[ccRIAChatMsg]
SET descripcion = 'Default_Sp\Default13',
    msg = 'La sesión de chat ha concluido'
WHERE msg_id = 8;

-- Validación final
SELECT * FROM [dbo].[ccRIAChatMsg];
