CREATE PROCEDURE ccsp_OUTDialResultIsAnswered
@callout_id int,
@nOcupado tinyint,
@nNoContesta tinyint,
@nFax tinyint,
@nContestadora tinyint,
@nShortCall tinyint,
@nOtro  tinyint
AS
	if ( ( select count(*) from ccWorkingTable WHERE callout_id = @callout_id ) > 0 )
	begin
		INSERT ccoLogDials (callout_id, TipoResDial_id ) Values ( @callout_id, 1 )
		UPDATE ccoCallsOutSource 
			SET	cal_intentos = ( @nOcupado + @nNoContesta + @nFax + @nContestadora + @nShortCall + @nOtro),
				nOcupado=@nOcupado, nNoContesta=@nNoContesta, nFax=@nFax, nContestadora=@nContestadora,
				nShortCall=@nShortCall, nOtro=@nOtro
		WHERE callout_id = @callout_id
	end