CREATE PROCEDURE ccsp_SaveCampsData
@fecha varchar(12),
@Inbound_id int,
@TipoCalls tinyint,
@nCalls smallint,
@nXfer smallint,
@nXferQue smallint,
@nXferFails smallint,
@nQue smallint,
@nDialogs smallint,
@nOverFlow smallint,
@nTimeOut smallint,
@nLost smallint,
@nDialogService smallint,
@nShortDialog smallint,
@nNoAnswer smallint, 
@tDialogService int,
@tShortDialog int,
@tAveQueWait smallint,
@tASA smallint,
@tAcumQue int,
@tXfer int,
@tDialog int,
@tRinging int,
@tWrapUp int
AS
declare @Dia as smalldatetime
select @Dia  = convert( smalldatetime, @fecha, 101)
if ( @TipoCalls = 1 )  --ESPECIALIDADES
begin
	Insert ccDataCamps ( Inbound_id, TipoCall, nCalls, nDialogs, nDialogService, nShortDialog, nNoAnswer,
				nXfer, nQue, nXferQue, nXferFails, nOverFlow, nTimeOut, nLost,
				tDialogService, tShortDialog, tDialog, tAcumQue, tAveQueWait,
				tASA, tXfer, tWrapUp, tRinging, fecha )
	
			Values ( @Inbound_id, 1, @nCalls, @nDialogs, @nDialogService, @nShortDialog, @nNoAnswer,
				@nXfer, @nQue, @nXferQue, @nXferFails, @nOverFlow, @nTimeOut, @nLost,
				@tDialogService, @tShortDialog, @tDialog, @tAcumQue, @tAveQueWait,
				@tASA, @tXfer, @tWrapUp, @tRinging, @Dia)
end
if ( @TipoCalls = 2 )  --CAMPA?AS
begin
	Insert ccDataCamps ( Inbound_id, TipoCall, nCalls, nDialogs, nDialogService, nShortDialog, nNoAnswer,
				nXfer, nQue, nXferQue, nXferFails, nOverFlow, nTimeOut, nLost,
				tDialogService, tShortDialog, tDialog, tAcumQue, tAveQueWait,
				tASA, tXfer, tWrapUp, tRinging, fecha  )
	
			Values ( @Inbound_id, 2, @nCalls, @nDialogs, @nDialogService, @nShortDialog, @nNoAnswer,
				@nXfer, @nQue, @nXferQue, @nXferFails, @nOverFlow, @nTimeOut, @nLost,
				@tDialogService, @tShortDialog, @tDialog, @tAcumQue, @tAveQueWait,
				@tASA, @tXfer, @tWrapUp, @tRinging, @Dia )
end