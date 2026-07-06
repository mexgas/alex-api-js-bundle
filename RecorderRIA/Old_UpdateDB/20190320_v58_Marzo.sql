/*
Autor: Jesus Gallardo
Descripcion: trsp_FinderCRMNode


Version requerida: 56
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 58
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try


	set @process = 'CW-2386 Alter SP trsp_FinderCRMNode'
	set @Sql= 'ALTER PROCEDURE [dbo].[trsp_FinderCRMNode] @cal_id INT, @type INT, @node XML
AS
BEGIN
	IF NOT EXISTS (
			SELECT *
			FROM ccCRMNodes
			WHERE cal_id = @cal_id AND type = @type
			)
		INSERT INTO ccCRMNodes (cal_id, type, node)
		VALUES (@cal_id, @type, @node)
	ELSE
		UPDATE ccCRMNodes
		SET node = @node
		WHERE cal_id = @cal_id AND type = @type
END
'
    EXEC(@Sql)
	
	
	set @process = 'CW-2464 Update parameter. Correct format'
	set @Sql= 'update trec_parametros set par_valor=case isnumeric(par_valor) when 0 then 0 else par_valor end, par_detail=''Puede ser 0:wav, 1:mp3, 2:vox'' where par_id=35'
	EXEC(@Sql)
	
	set @process = 'CW-2464 Alter SP trsp_SaveAVRSBackupParameters'
	set @Sql= 'ALTER PROCEDURE [dbo].[trsp_SaveAVRSBackupParameters]
						  @settings AS VARCHAR(MAX),
						  @NetBiosSettings AS VARCHAR(MAX) = '''',
						  @FTPSettings AS VARCHAR(MAX) = '''',
						  @ExtDriveSettings AS VARCHAR(MAX) = ''''
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
						      
						  END'
	EXEC(@Sql)
	
	------------------ fin SCRIPT @Sql ------------------

	-- Updating DB Version

 	update trec_parametros set par_valor = @Version where par_id = 30
 	set @Version_Actual=@Version_Actual+1

	select par_valor from trec_parametros where par_id = 30

	commit tran

	end try
	begin catch
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end
 else begin
	select par_valor,'This version is incorrect, need version '+ convert(varchar(max),@Version-1) from trec_parametros where par_id = 30
 end
