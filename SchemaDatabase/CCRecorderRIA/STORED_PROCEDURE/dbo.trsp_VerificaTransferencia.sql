CREATE    PROCEDURE [dbo].[trsp_VerificaTransferencia]
   @grabID bigint
AS

DECLARE @idTransfer bigint

SELECT ISNULL(ID,0) FROM TREC_TRANSFERENCIA
WHERE GRAB_ID = @grabID