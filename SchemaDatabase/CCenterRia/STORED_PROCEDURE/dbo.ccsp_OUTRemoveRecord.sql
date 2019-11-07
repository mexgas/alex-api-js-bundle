CREATE PROCEDURE ccsp_OUTRemoveRecord
@callout_id int
AS
/***********************************
	Realizo: Alfredo Salvador
	Fecha Creacion: 22-Abril-2002
	Descripcion: Para Remover de TBCIMA_WORKINGTABLE un Registro 
	Comentarios:
	Fecha Ultima Modificacion:
	Cambio Realizado:
************************************/
declare @nOcupado tinyint, @nNoContesta tinyint, @nFax tinyint, @nContestadora tinyint, @nShortCall tinyint, @nOtro  tinyint
	IF ( ( select count(*) from ccoWorkingTable WHERE callout_id = @callout_id ) > 0 )
	BEGIN
		SELECT @nOcupado=nOcupado, @nNoContesta=nNoContesta, @nFax=nFax, @nContestadora=nContestadora, @nShortCall=nShortCall, @nOtro=nOtro
		FROM ccoWorkingTable
		WHERE callout_id = @callout_id
		DELETE ccoWorkingTable WHERE callout_id = @callout_id
		SELECT @nOcupado= IsNull( @nOcupado, 0), @nNoContesta= IsNull( @nNoContesta, 0), @nFax= IsNull( @nFax, 0), @nContestadora= IsNull( @nContestadora, 0),
			 @nShortCall= IsNull( @nShortCall, 0), @nOtro= IsNull( @nOtro, 0)
		UPDATE ccoCallsOutSource
			SET	cal_intentos = ( @nOcupado + @nNoContesta + @nFax + @nContestadora +  @nShortCall + @nOtro),
				nOcupado=@nOcupado, nNoContesta=@nNoContesta, nFax=@nFax, nContestadora=@nContestadora,
				nShortCall=@nShortCall, cal_status=4 --, nOtro=@nOtro
		WHERE callout_id = @callout_id
	end