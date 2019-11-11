CREATE    PROCEDURE [dbo].[trsp_ConsultaTransferencia]
		   	@grabID bigint
			AS
			DECLARE @idTransfer as bigint

			SELECT @idTransfer = ID FROM TREC_TRANSFERENCIA
			WHERE GRAB_ID = @grabID


			SELECT distinct (TREC_TRANSFERENCIA.grab_id),extension,pos_pc,finicio,dbo.fGetHHmmSS (duracion) as duracion,age_ap_paterno+' '+age_ap_materno+' '+age_nombre as nombre,puerto_id, TREC_GRABACION.age_id as user_id, TREC_TRANSFERENCIA.id as trans_id
			FROM TREC_TRANSFERENCIA INNER JOIN TREC_GRABACION ON TREC_TRANSFERENCIA.grab_id = TREC_GRABACION.grab_id
			LEFT JOIN TREC_AGENTE ON TREC_GRABACION.age_id = TREC_AGENTE.age_id 
			WHERE duracion > 0 AND id = @idTransfer ORDER BY TREC_TRANSFERENCIA.grab_id