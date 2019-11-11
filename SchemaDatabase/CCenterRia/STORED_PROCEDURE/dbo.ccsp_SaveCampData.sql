CREATE PROCEDURE ccsp_SaveCampData
@Inbound_id int,
@nXfer smallint,
@nQue smallint,
@nXferQue smallint,
@nDialogs smallint,
@tDialog int,
@tXfer int,
@tWrapUp int,
@tWClient int,
@tRinging int,
@tNoAnswer int
AS
Insert ccDataCamps ( Inbound_id, nXfer, nQue, nXferQue, nDialogs, tDialog, tXfer, tWrapUp, tRinging )
		Values ( @Inbound_id, @nXfer, @nQue, @nXferQue, @nDialogs, @tDialog, @tXfer, @tWrapUp, @tRinging )