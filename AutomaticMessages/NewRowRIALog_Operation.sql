if not exists(select * from ccRIALog_Operation where operationType=194) begin
	INSERT INTO ccRIALog_Operation VALUES(194, 'EDITAR ORDEN DE AUDIO/VARIABLE|EDIT AUDIO/VARIABLE ORDER');
end