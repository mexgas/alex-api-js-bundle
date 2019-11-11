CREATE TRIGGER SaveEncKey ON TREC_PARAMETROS
		INSTEAD OF UPDATE
		AS
		     SET NOCOUNT ON;
		     DECLARE @SettingId INT;
		     SELECT @SettingId = par_id
		     FROM inserted;
		     IF @SettingId = 75
		         BEGIN
		             INSERT INTO LogKeyRec
		             (CurrentKeyEnc, 
		              NewKeyEnc, 
		              DateUpdate
		             )
		                    SELECT trec.par_valor, 
		                           temp.par_valor, 
		                           GETDATE()
		                    FROM TREC_PARAMETROS AS trec
		                         JOIN inserted AS temp ON trec.par_id = temp.par_id
		                    WHERE trec.par_id = 75;
		             UPDATE TREC_PARAMETROS
		               SET 
		                   trec_parametros.par_id = temp.par_id, 
		                   trec_parametros.par_detail = temp.par_detail, 
		                   trec_parametros.par_descripcion = temp.par_descripcion, 
		                   TREC_PARAMETROS.par_valor = temp.par_valor
		             FROM inserted AS temp
		                  INNER JOIN TREC_PARAMETROS trec ON trec.par_id = temp.par_id
		             WHERE trec.par_id = 75;
		     END;
		         ELSE
		         BEGIN
		             UPDATE TREC_PARAMETROS
		               SET 
		                   trec_parametros.par_id = temp.par_id, 
		                   trec_parametros.par_detail = temp.par_detail, 
		                   trec_parametros.par_descripcion = temp.par_descripcion, 
		                   TREC_PARAMETROS.par_valor = temp.par_valor
		             FROM inserted AS temp
		                  INNER JOIN TREC_PARAMETROS trec ON trec.par_id = temp.par_id;
		     END;