Create procedure [dbo].[ccsp_DLRgetXferInfo]
@camEspecId smallint=0,
@iPortNumber smallint = 0,
@type smallint
as
-- @type: 1 transferencia entrada, 2 transferencia salida, 3 desborde (siempre es entrada, con o sin especialidad)
declare @prefix as varchar(15)
declare @timeout int
declare @ani as varchar(32)
declare @stop int

set @prefix =''
set @timeout = 20
set @ani = ''
set @stop = 0

-- Prefijo por puerto
select @prefix = prefix from cstoProvedor where provedor_id = (select provedor_id from ccodialers where puerto = @iPortNumber )
-- Prefijo por campaña o especialidad
if @prefix =''
	if @type = 2
		select @prefix = dialPrefixXfe from ccCamps where cam_id = @camEspecId
	else
		select @prefix = dialPrefixOverflow from ccInbound where inbound_id= @camEspecId
-- Prefijo general
if @prefix ='' and (@type =1 or @type=2) and ((select cast(valor as int) from ccsettings where setting_id =102) & 4 = 4)
	select @prefix = valor from ccsettings where setting_id =101
if @prefix ='' and (@type =3) and ((select cast(valor as int) from ccsettings where setting_id =102) & 8 = 8)
	select @prefix = valor from ccsettings where setting_id =101

-- Tiempo de marcado
select @timeout = cast(valor as int) from ccSettings where setting_id = 109

-- Ani y stopRecord
if @type = 2
	select @ani = callerIdDesc, @stop = stopRecording from ccCamps where cam_id = @camEspecId
else
	select @ani = callerIdDesc, @stop = stopRecording from ccInbound where inbound_id= @camEspecId

select @prefix as sDialPrefix, @timeout as tNoContesta, @ani as ani, @stop as stopRecording