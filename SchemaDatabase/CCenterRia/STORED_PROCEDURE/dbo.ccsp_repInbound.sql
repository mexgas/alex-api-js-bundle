CREATE PROCEDURE ccsp_repInbound
@Inbound_id smallint,
@sFini varchar(20),
@sFfin varchar(20)
AS
declare @Total int
declare @Dialog int
declare @Dialogs35 int
declare @HoldCalls int
declare @TimeOut int
declare @Overflow int
declare @Abadoned int
declare @AveAtencion int
declare @AveHoldCalls int
declare @FIni datetime
declare @FFin datetime
select @FIni=convert(datetime, @sFini, 101), @FFin=convert(datetime, @sFfin, 101)
-- LLAMADAS TOTALES
SELECT @Total=count(*)
From ccCallsIN
Where cal_Inicio >= @FIni
AND cal_Inicio < @FFin
AND Inbound_id =@Inbound_id
-- LLAMADAS CONTESTADAS
SELECT @Dialog=count(*)
From ccCallsIN
Where cal_Inicio >= @FIni
AND cal_Inicio < @FFin
AND statusCall_id in (13)
AND Inbound_id =@Inbound_id
-- LLAMADAS ABANDONADAS
SELECT @Abadoned=count(*)
From ccCallsIN
Where cal_Inicio >= @FIni
AND cal_Inicio < @FFin
AND statusCall_id in (4,6)
AND Inbound_id =@Inbound_id
-- LLAMADAS TERMINADAS POR MAXIMO LLAMADAS EN ESPERA
SELECT @Overflow=count(*)
From ccCallsIN
Where cal_Inicio >= @FIni
AND cal_Inicio < @FFin
AND statusCall_id in (8)
AND Inbound_id =@Inbound_id
-- LLAMADAS TERMINADAS POR TIME OUT
SELECT @TimeOut=count(*)
From ccCallsIN
Where cal_Inicio >= @FIni
AND cal_Inicio < @FFin
AND statusCall_id in (7)
AND Inbound_id =@Inbound_id
-- LLAMADAS QUE ESTUVIERON EN ESPERA
SELECT @HoldCalls=count(*)
From ccCallsIN
Where cal_Inicio >= @FIni
AND cal_Inicio < @FFin
AND cal_que >0
AND Inbound_id =@Inbound_id
-- LLAMADAS CON DIALOGO < 35 SEGS
SELECT @Dialogs35=count(*)
From ccCallsIN
Where cal_Inicio >= @FIni
AND cal_Inicio < @FFin
AND statusCall_id in (13)
AND cal_tDialog <35
AND Inbound_id =@Inbound_id
-- TIEMPO PROMEDIO DE ATENCION
SELECT @AveAtencion =ISNULL( avg( cal_tDialog + cal_tNotas ), 0)
From ccCallsIN 
Where cal_Inicio >= @FIni
AND cal_Inicio < @FFin
AND statusCall_id in (13)
AND Inbound_id =@Inbound_id
-- TIEMPO DE LAS LLAMADAS EN ESPERA
SELECT @AveHoldCalls=ISNULL( avg( cal_tWait ), 0)
From ccCallsIN 
Where cal_Inicio >= @FIni
AND cal_Inicio < @FFin
AND statusCall_id in ( 13) AND cal_que > 0 
AND Inbound_id =@Inbound_id
select 
	'Totales'=@Total,
	'Dialog'=@Dialog,
	'Dialogs35'=@Dialogs35,
	'TimeOut'=@TimeOut,
	'Overflow'=@Overflow,
	'HoldCalls'=@HoldCalls,
	'Abadoned'=@Abadoned,
	'AveAtencion'=@AveAtencion,
	'AveHoldCalls'=@AveHoldCalls