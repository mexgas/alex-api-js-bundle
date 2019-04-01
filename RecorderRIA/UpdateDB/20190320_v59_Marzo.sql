/*
Autor: Daniel Vega
Descripcion: tarea de reproductor externo


Version requerida: 58
*/
set nocount on
declare @Version int
declare @Version_Actual int

declare @Sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
---------------- VERSION ----------------
	Set @Version = 59
	Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual in(@Version, @Version -1) -- Aqui poner numero de nueva version
	 begin
	begin tran
	begin try



	SET @process = 'CW-2742 Create table Log Key LogKeyRec '
	SET @Sql = 'if not exists (select * from sys.tables where name = N''LogKeyRec'')
    begin
	CREATE TABLE LogKeyRec
	(Id            INT IDENTITY(1, 1), 
	 CurrentKeyEnc VARCHAR(MAX), 
	 NewKeyEnc     VARCHAR(MAX), 
	 DateUpdate    DATETIME
	)
    end'
	EXEC (@Sql)

	SET @process = 'CW-2742 Create Trigger SaveEncKey '
	SET @Sql = '
		IF EXISTS
		(
		    SELECT *
		    FROM sys.triggers
		    WHERE name = N''SaveEncKey''
		          AND parent_id = OBJECT_ID(N''TREC_PARAMETROS'')
		)
		    BEGIN
		        DROP TRIGGER SaveEncKey;
		END;

		exec(''CREATE TRIGGER SaveEncKey ON TREC_PARAMETROS
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
		     END;'')
	'
	EXEC (@Sql)



	SET @process = 'CW-2742 Create [ccsp_GetRecord]'
	SET @Sql = 'if exists (select * from sys.procedures where name = N''ccsp_GetRecord'')
    begin
        DROP PROCEDURE ccsp_GetRecord;
    end'
	EXEC (@Sql)


	SET @process = 'CW-2742 crear ccsp_GetRecord'
	SET @Sql = 'CREATE procedure [dbo].[ccsp_GetRecord] 
		@action int,
		@IdRepository int = 1,
		@DateStart Date,
		@DateEnd date
		as
		if @action =1
		begin
			select grab_id,cal_id,tipo_llamada,Prefijo 
			from RIA_GRABACION 
			where id_repositorio = @IdRepository and
			cast(finicio as Date) >= Cast(@DateStart As Date) and	cast(ffin as Date) <= cast(@DateEnd as Date)
			order by grab_id
		end

		if @action =2
		begin
			select grab_id,cal_id,tipo_llamada,Prefijo 
			from RIA_GRABACION where cast(finicio as Date) >= Cast(@DateStart As Date) and	cast(ffin as Date) <= cast(@DateEnd as Date)
			order by grab_id
		end
'
	EXEC (@Sql)



SET @process = 'CW-2742 modificacion de trsp_ConsultaRepositorio'
		SET @Sql = 'ALTER PROCEDURE [dbo].[trsp_ConsultaRepositorio]
		@id_repositorio tinyint =1 ,
		@action tinyint  =1
		AS
		BEGIN
		if @action = 1
			begin
				SELECT     Cast(id_repositorio as Int ) as id_repositorio, ruta_repositorio, ruta_local
				FROM       TREC_REPOSITORIOS
				WHERE      id_repositorio=@id_repositorio
			end
		if @action = 2
			begin
				SELECT     Cast(id_repositorio as Int ) as id_repositorio, ruta_repositorio, ruta_local,ruta_local_imagenes
				FROM       TREC_REPOSITORIOS
			end
		if @action = 3
			begin
				SELECT    id,domain,[user],[password]
				FROM       RIA_NETWORKCREDENTIALS
			end
		if @action = 4
			begin
				SELECT    id_repository,id_nwCredential
				FROM       TREC_REPO_NWCREDENTIALS
			end
		END
	'
EXEC (@Sql)
	
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
