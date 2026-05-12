USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_DLRgetXferInfo]    Script Date: 01/04/2026 11:07:59 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[ccsp_DLRgetXferInfo]
@camEspecId smallint=0,
@iPortNumber smallint = 0,
@type smallint,
@typeTransfer smallint = 0,
@phone varchar(50) = '',
@trunkId int=0
as
-- @type: 1 transferencia entrada, 2 transferencia salida, 3 desborde (siempre es entrada, con o sin especialidad)
declare @prefix as varchar(15), @trunk varchar(200)
declare @timeout int
declare @ani as varchar(32)
declare @stop int
declare @ivr_script smallint, @surveycamid int

set @prefix =''
set @timeout = 20
set @ani = ''
set @stop = 0

-- Prefijo por puerto
select @prefix = prefix, @trunk=isnull(trunk,'') from cstoProvedor nolock where provedor_id = (
	select provedor_id from ccodialers nolock where puerto = @iPortNumber )
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
	select @ani = callerIdDesc, @stop = isnull(stopRecording, 0) from ccCamps nolock where cam_id = @camEspecId
else
begin
	select @ani = callerIdDesc, @stop = stopRecording, @surveycamid = isnull(extend.SurveyCamId,0)
	from ccInbound i (nolock)
	left join ccInboundExtend extend on extend.Inbound_id = i.Inbound_id
	where i.inbound_id= @camEspecId

	if @surveycamid > 0
		select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid
end

if (@typeTransfer in (0,4) and @type = 2 and @phone is not null and @phone <> '')
begin
	select @stop = case when @typeTransfer = 0 then isnull(stopRecording, 1) else ISNULL(stopRecordingAssisted, 1) end from telefonosTransferencia where tel = @phone
end

select @prefix as sDialPrefix, @timeout as tNoContesta, @ani as ani, @stop as stopRecording, @ivr_script as ivrScript,
dbo.GetRoute(@phone,'',@trunkId) destination, @trunk trunk