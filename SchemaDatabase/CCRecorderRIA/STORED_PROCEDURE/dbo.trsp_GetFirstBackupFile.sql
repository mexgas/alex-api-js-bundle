CREATE PROCEDURE [dbo].[trsp_GetFirstBackupFile]
					@isItegratedRIA bit
					AS
					DECLARE @FirstBackupFile as bigint
					DECLARE @LastGrabAr as bigint
					DECLARE @MinTime as integer
					DECLARE @Date as datetime
					Declare @MinHistorico as bigint
					Declare @ExistHist as bit

					BEGIN
					IF @isItegratedRIA = 1
						BEGIN
							--delete RIA_ARCHIVO_GRABACION where hecho = 0
							if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RIA_GRABACIONConsulta]'))
								set @ExistHist = 1
							else
								set @ExistHist = 0
							SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
							IF (@MinTime is NULL)
							BEGIN
								SELECT @MinTime=5
							END

							--SELECT @LastGrabAr=MAX(grab_id_max) FROM RIA_ARCHIVO_GRABACION
							SELECT @LastGrabAr=MAX(grab_id)  FROM TREC_BACKUPS
							IF (@LastGrabAr is NULL)
							BEGIN
								SELECT @LastGrabAr=-1
							END
							if @ExistHist = 1
							begin
								SELECT @MinHistorico = MIN(grab_id) FROM RIA_GRABACIONConsulta with (index(IX_RIA_GRABACIONCONSULTA_2)) 
									WHERE duracion >= @MinTime AND grab_id>@LastGrabAr
								if (@MinHistorico is NULL)
								begin	
									SELECT  @FirstBackupFile=grab_id, @Date=finicio 
										FROM RIA_GRABACION 
										WHERE grab_id =(SELECT MIN(grab_id) 
											FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) 
											WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
								end
								else
								begin
									SELECT  @FirstBackupFile=grab_id, @Date=finicio 
										FROM RIA_GRABACIONConsulta 
										WHERE grab_id =@MinHistorico
								end
							end
							else
							begin
								SELECT  @FirstBackupFile=grab_id, @Date=finicio 
									FROM RIA_GRABACION 
									WHERE grab_id =(SELECT MIN(grab_id) 
										FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) 
										WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
							end

							SELECT 'FirstBackupFile'=@FirstBackupFile, 'Date'=@Date
						END
					ELSE
						BEGIN
							--delete RIA_ARCHIVO_GRABACION where hecho = 0
							if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[TREC_GRABACIONConsulta]'))
								set @ExistHist = 1
							else
								set @ExistHist = 0
							SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
							IF (@MinTime is NULL)
							BEGIN
								SELECT @MinTime=5
							END

							--SELECT @LastGrabAr=MAX(grab_id_max) FROM RIA_ARCHIVO_GRABACION
							SELECT @LastGrabAr=MAX(grab_id)  FROM TREC_BACKUPS
							IF (@LastGrabAr is NULL)
							BEGIN
								SELECT @LastGrabAr=-1
							END
							if @ExistHist = 1
							begin
								SELECT @MinHistorico = MIN(grab_id) FROM TREC_GRABACIONConsulta with (index(IX_TREC_GRABACIONCONSULTA_2)) 
									WHERE duracion >= @MinTime AND grab_id>@LastGrabAr
								if (@MinHistorico is NULL)
								begin	
									SELECT  @FirstBackupFile=grab_id, @Date=finicio 
										FROM TREC_GRABACION 
										WHERE grab_id =(SELECT MIN(grab_id) 
											FROM TREC_GRABACION  with (index(IX_TREC_GRABACION_2)) 
											WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
								end
								else
								begin
									SELECT  @FirstBackupFile=grab_id, @Date=finicio 
										FROM TREC_GRABACIONConsulta 
										WHERE grab_id =@MinHistorico
								end
							end
							else
							begin
								SELECT  @FirstBackupFile=grab_id, @Date=finicio 
									FROM TREC_GRABACION 
									WHERE grab_id =(SELECT MIN(grab_id) 
										FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) 
										WHERE duracion >= @MinTime AND grab_id>@LastGrabAr)
							end

							SELECT 'FirstBackupFile'=@FirstBackupFile, 'Date'=@Date
						END 

					END