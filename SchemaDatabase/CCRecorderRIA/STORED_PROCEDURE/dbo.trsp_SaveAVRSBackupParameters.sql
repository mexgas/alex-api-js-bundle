CREATE PROCEDURE [dbo].[trsp_SaveAVRSBackupParameters]
						  @settings AS VARCHAR(MAX),
						  @NetBiosSettings AS VARCHAR(MAX) = '',
						  @FTPSettings AS VARCHAR(MAX) = '',
						  @ExtDriveSettings AS VARCHAR(MAX) = ''
						  AS
						  BEGIN
						    
						    UPDATE TREC_PARAMETROS
						    SET par_valor = @settings
						    WHERE par_id = 67

						    --NetBios
						    IF LEN(@NetBiosSettings) > 0
						      BEGIN
						    
						        UPDATE TREC_PARAMETROS
						        SET par_valor = @NetBiosSettings
						        WHERE par_id = 68
						        
						      END

						    --FTP 
						    IF LEN(@FTPSettings) > 0
						      BEGIN
						    
						        UPDATE TREC_PARAMETROS
						        SET par_valor = @FTPSettings
						        WHERE par_id = 69
						        
						      END

						    --ExtDrive  
						    IF LEN(@ExtDriveSettings) > 0
						      BEGIN
						    
						        UPDATE TREC_PARAMETROS
						        SET par_valor = @ExtDriveSettings
						        WHERE par_id = 70
						        
						      END
						      
						  END