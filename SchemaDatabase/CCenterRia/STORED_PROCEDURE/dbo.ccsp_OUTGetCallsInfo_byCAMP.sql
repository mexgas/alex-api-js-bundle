CREATE PROCEDURE ccsp_OUTGetCallsInfo_byCAMP
@CamID int
AS

declare @nAnswer int, @nBusy int, @nNoAnswer int, @nFaxModem int
declare @mToday as smalldatetime
declare @bRestarting as tinyint
declare @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

select @bRestarting = 1
if @bRestarting = 0 begin
	select @mToday = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
	SELECT
		@nAnswer 	= count( case tipoResDial_id when 1 then 1 else null end), 
		@nBusy 	= count( case tipoResDial_id when 2 then 1 else null end),
		@nNoAnswer	= count( case tipoResDial_id when 3 then 1 else null end), 
		@nFaxModem	= count( case tipoResDial_id when 4 then 1 else null end) 
	FROM ccoLogDials
	WHERE cam_id=@CamID
	AND fecha >  @mToday
	if @idioma = 1
	SELECT 'Answered'=@nAnswer, 'Busy'=@nBusy, 'Not Answer'=@nNoAnswer, 'Fax/Modem'=@nFaxModem
	else
	SELECT 'Contestadas'=@nAnswer, 'Ocupados'=@nBusy, 'NO Conestan'=@nNoAnswer, 'Fax/Modem'=@nFaxModem
end else begin
	if @idioma = 1
	SELECT 'Answered'=0, 'Busy'=0, 'Not Answer'=0, 'Fax/Modem'=0
	else
	SELECT 'Contestadas'=0, 'Ocupados'=0, 'NO Conestan'=0, 'Fax/Modem'=0
end

/*
-- CONTESTADAS
SELECT @nAnswer=count (*)
FROM ccoLogDials
WHERE tipoResDial_id = 1
AND cam_id=@CamID
AND fecha >  @mToday
-- OCUPADOS
SELECT @nBusy=count (*)
FROM ccoLogDials
WHERE tipoResDial_id = 2
AND cam_id=@CamID
AND fecha >  @mToday
-- NO CONTESTA
SELECT @nNoAnswer=count (*)
FROM ccoLogDials
WHERE tipoResDial_id = 3
AND cam_id=@CamID
AND fecha >  @mToday
-- FAX_MODEM
SELECT @nFaxModem=count (*)
FROM ccoLogDials
WHERE tipoResDial_id = 4
AND cam_id=@CamID
AND fecha >  @mToday
SELECT 'Contestadas'=@nAnswer, 'Ocupados'=@nBusy, 'NO Conestan'=@nNoAnswer, 'Fax/Modem'=@nFaxModem
*/