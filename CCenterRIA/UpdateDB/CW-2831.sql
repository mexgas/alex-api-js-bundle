		SET @process = 'CW-2831 Alter ccsp_GalateaGetCustomErrorMessages'
		SET @Sql = '
					ALTER PROCEDURE [dbo].[ccsp_GalateaGetCustomErrorMessages]
					@cal_id INT
					AS
						DECLARE @disconnectCause AS VARCHAR(250)
						--VALIDA QUE EL SETTING PARA MENSAJES PERSONALIZADOS ESTA ACTIVO
						DECLARE @callout_id AS INT
						IF EXISTS(SELECT * FROM ccSettings WHERE setting_id = 212 and valor = 1)
						BEGIN
							--VALIDA QUE EL CALLOUT_ID EXISTA EN CCOLOGDIALS
							SELECT @callout_id=callout_id FROM ccoCallsOut WHERE cal_id = @cal_id
							IF @callout_id IS NOT NULL
							BEGIN
								--SE OBTIENE EL TIPO DE USUARIO YA REGISTRADO
								SELECT @disconnectCause=disconnectCause
								FROM ccoLogDials
								WHERE callout_id = @callout_id

								WHILE PATINDEX(''%[^0-9]%'',@disconnectCause) <> 0
								BEGIN
								    --ELIMINA LAS LETRAS PARA DEJAR SOLO NUMEROS
								    SET @disconnectCause = STUFF(@disconnectCause,PATINDEX(''%[^0-9]%'',@disconnectCause),1,'''')
								END

								--VALIDA QUE EXISTA UN MENSAJE DE ERROR PARA EL CODIGO
								IF EXISTS (SELECT message_description FROM ccGalateaCustomErrorMessages WHERE message_id = @disconnectCause)
								BEGIN
									--REGRESA MENSAJE ASOCIADO AL CODIGO DE ERROR
									SELECT message_description
									FROM ccGalateaCustomErrorMessages
									WHERE message_id = @disconnectCause
								END
								ELSE
								BEGIN
									--REGRESA MENSAJE DE ERROR NO ENCONTRADO SI AL MOMENTO DE CONSULTAR NO EXISTE UN ERROR
									IF (@disconnectCause ='''')
									BEGIN
										SELECT ''ERROR_NOT_FOUND'' ''message_description''
									END
									ELSE
									BEGIN
										--REGRESA MENSAJE POR DEFAULT SI NO SE ENCUENTRA UNO ASOCIADO AL COIGO DE ERROR
										SELECT message_description
										FROM ccGalateaCustomErrorMessages
										WHERE message_id = ''DEFAULT''
									END
								END
							END
							ELSE
							BEGIN
								--REGRESA MENSAJE POR DEFAULT SI NO SE ENCUENTRA EN CCOLOGDIALS EL CALLOUT_ID
								SELECT message_description
								FROM ccGalateaCustomErrorMessages
								WHERE message_id = ''DEFAULT''
							END
						END
						ELSE
						BEGIN
							--REGRESA UN MENSAJE PREDETERMINADO PARA INFORMAR QUE EL SETTING EST? DESHABILITADO
							SELECT ''SETTING_DISABLED'' ''message_description''
						END
						'