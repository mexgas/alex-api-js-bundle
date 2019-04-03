/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Armando Rodriguez
Date: 2019/04/02
Description:
correccion de reporte de llamadas contestadas y transferidas, se pone el nombre de la campaña cuando es una transferencia

Database: ccReportsRia
Required version: 63


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 64

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
		SET @process = 'CW correccion de rep contestadas y xfers '
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutAnswAndXferCalls]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
                select @from = convert(datetime,convert(varchar(11),getdate()))
select @to = getdate()

declare @IVA INT
declare @country as tinyint


select @IVA = convert(int,isnull(valor,0)) from ccsettings where setting_id = 25
select @country = convert(tinyint,isnull(valor,1)) from ccsettings where setting_id = 104


if @country is null set @country = 1


if @action = 1
begin
                --Borrar lo que esta para no repetir
                delete from RepOutAnswAndXferCalls with(rowlock) where date >= @from AND date < @to

                insert into RepOutAnswAndXferCalls
                select COALESCE([Call].cal_inicio,ccld.fecha) as [date],
                isnull(ccld.cal_id,0) as [callid],
                isnull(ccld.cam_id,0) as [campaignId],
                ISNULL(camps.cam_descripcion, ''systemTranslated_NoCampaign'') as [campaign],
                isnull([Call].user_id,0) as [userId],
                ISNULL(Usr.ApellidoPaterno + '' '' + ISNULL(Usr.ApellidoMaterno, '''') + '' '' + Usr.Nombres, ''N/A'') as [Agent],
                case when (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) end as [dialog],
                ccld.telefono as [telephone],
                isnull(Call.cal_manual,0) as [dialId],
                isnull((select [description] from dialType where dialId = Call.cal_manual),''systemTranslated_Auto'') as [dialType],
                ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
                dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType), COALESCE(Call.provedor_id,ccld.proBIDs) , case when (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) end) as [ncost],
                @IVA as iva,
                convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(COALESCE(Call.tipoLlamada_id, ccld.CallType), COALESCE(Call.provedor_id,ccld.proBIDs) , case when (COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60) <> 0 then COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) + (60 -(COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) % 60)) else 60 + COALESCE(Call.totalCall_Time + ISNULL(cal_tMsg,0), ccld.tdialing) end),0.00) * (1 + (@IVA / 100.00))) as total
                from (select *, [dbo].[GetProveedor](Telefono, Puerto,CallType) as proBIDs from (select *, tipoLlamada_id as CallType from ccologdials WITH(NOLOCK) where fecha >= @from and fecha < @to and answerbit = 1 ) as basequery ) ccld
                LEFT JOIN ccoCallsOut Call WITH(NOLOCK) on ccld.cal_id = Call.cal_id and ccld.answerbit = 1
                LEFT JOIN ccCamps camps ON camps.[cam_id] = ccld.[cam_id]
                LEFT JOIN ccUsers Usr ON Usr.[user_id] = Call.[user_id]
                LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = COALESCE(Call.[tipoLlamada_id],ccld.CallType) and tl.Country_id = @country)
                order by date

                insert into RepOutAnswAndXferCalls
                select dateadd(ss,-(clt.tAntesXfer + clt.tDespuesXfer),clt.fechaFin) as [date],
                clt.cal_id as [callid],
                COALESCE(co.cam_id,ci.inbound_id,''0'')  as [campaignId],
                COALESCE(camps.cam_descripcion, ACD.descripcion, ''systemTranslated_NoCampaign'') as [campaign],
                isnull((case tipo when 1 then ci.User_id else co.User_id end),0) as [userId],
                isnull((select nombres + '' '' + apellidopaterno + '' '' + apellidomaterno from ccusers nolock where user_id = 
                (case tipo when 1 then ci.User_id else co.User_id end)),''systemTranslated_NoName'') as [Agent],
                case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else 60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end as [dialog],
                case when modo = 0 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino)  
                when modo = 3 then isnull((select tel from telefonosConferencia where tel = clt.destino),clt.destino) 
                when modo = 4 then isnull((select top 1 tel from telefonosTransferencia where tel = clt.destino),clt.destino) 
                when modo = 5 then isnull((select Computer from ccposicion where pos_id = abs(clt.destino)),clt.destino) end as [telephone],
                3 as [dialId],
                (select [description] from dialType where dialId = 3) as [dialType],
                ISNULL(tl.descrip, ''systemTranslated_Indefinite'') as [CallTypes],
                ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId, case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else 60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end), 0) as [ncost],
                @IVA as iva,
                convert(decimal(10,2),ISNULL(dbo.fnGetCstoTarifa(clt.CallType, channel.proveedorId, case when ((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60) <> 0 then (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) + (60 -((ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) % 60)) else  60 + (ISNULL(clt.tAntesXfer,0) + ISNULL(clt.tDespuesXfer,0)) end),0.00) * (1 + (@IVA / 100.00))) as [total]
                from (select *, tipoLlamada_id as  CallType from cclogtransfers WITH(NOLOCK) where modo not in (1,2) and (tAntesXfer > 0 or tDespuesXfer > 0) and dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) >= @from and dateadd(ss,-(tAntesXfer + tDespuesXfer),fechaFin) < @to) clt
                LEFT JOIN cccallsin ci WITH(NOLOCK) on ci.cal_id=clt.cal_id and tipo=1
                LEFT JOIN ccocallsout co WITH(NOLOCK) on co.cal_id=clt.cal_id and tipo=2 
                LEFT JOIN ccChannelTransfer channel on clt.pbxId=channel.pbxId and clt.channel between channel.startChannel and channel.endChannel
                LEFT JOIN cstoTarifa tarifa on tarifa.provedor_id=channel.proveedorId and tarifa.tipoLlamada_id=dbo.fnGetTipoLlamada(clt.destino)
                LEFT JOIN cstoTipoLlamada tl ON (tl.[tipoLlamada_id] = clt.CallType and tl.Country_id = @country)
                LEFT JOIN ccCamps camps ON camps.[cam_id] = co.cam_id
                LEFT JOIN ccInbound ACD ON ACD.[Inbound_id] = ci.Inbound_id
                order by date 

end
'

		EXEC (@sql)


		IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
