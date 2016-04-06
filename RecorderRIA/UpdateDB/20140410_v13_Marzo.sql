/*

Fecha: 2014/04/210
Descripcion: 	

Version requerida: 12
*/

set nocount on
declare @Version int
declare @Version_Actual int
---------------- VERSION ----------------
Set @Version = 13
Set @Version_Actual = (select par_valor from trec_parametros where par_id = 30)

if @Version_Actual = @Version -1 -- Aqui poner numero de nueva version
 begin
	begin tran
	begin try
	declare @Sql varchar(max)
	declare @errorGenerated varchar(max)
	declare @process varchar(max)
---------------- inicio SCRIPT @Sql ----------------

	set @process = 'RIA_GRABACION - Alter Table'
	set @Sql='ALTER TABLE dbo.RIA_GRABACION 
	 		  ALTER COLUMN ani VARCHAR (30) NOT NULL'
	EXEC(@Sql)


	set @process = 'RIA_GRABACIONCONSULTA - Alter Table'
	set @Sql='ALTER TABLE dbo.RIA_GRABACIONCONSULTA
 		ALTER COLUMN ani VARCHAR (30) NOT NULL'

	EXEC(@Sql)



	set @process = 'Update stored- trsp_GetListaBorrarSinRespaldo'
	set @Sql='

	ALTER PROCEDURE [dbo].[trsp_GetListaBorrarSinRespaldo]
	@cwIntegrated AS INT,
	@cwIntegratedRIA AS INT
	AS
	BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @maxBorrado INT
	DECLARE @datosTabla INT
	DECLARE @maxGrabId INT

    -- Insert statements for procedure here
	SELECT @maxBorrado = isnull(MAX(grab_id),0) from trec_backups where status_audio = 4 or status_audio = 5;
	SELECT @datosTabla = COUNT(grab_id) from trec_backups where grab_id > @maxBorrado;
	SELECT @maxGrabId = isnull(MAX(grab_id),0) from trec_backups;
	IF @datosTabla < 10000
	   BEGIN
			IF @cwIntegratedRIA = 1
				BEGIN
					insert into TREC_BACKUPS (grab_id,status_audio)
					select grab_id,2 as status_audio from RIA_GRABACION where grab_id between @maxGrabId+1 and @maxGrabId+(10000-@datosTabla)
					--union all
					insert into TREC_BACKUPS (grab_id,status_audio)
					select grab_id,2 as status_audio from RIA_GRABACIONCONSULTA where grab_id between @maxGrabId+1 and @maxGrabId+(10000-@datosTabla);
				END
			ELSE
				BEGIN
					insert into TREC_BACKUPS (grab_id,status_audio)
					select grab_id,2 as status_audio from TREC_GRABACION where grab_id between @maxGrabId+1 and @maxGrabId+(10000-@datosTabla)
					--union all

					insert into TREC_BACKUPS (grab_id,status_audio)
					select grab_id,2 as status_audio from TREC_GRABACIONCONSULTA where grab_id between @maxGrabId+1 and @maxGrabId+(10000-@datosTabla);
				END		
	   END
	IF @cwIntegrated = 1
	    BEGIN
		select top 10000 TREC_BACKUPS.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio, status_video from TREC_BACKUPS inner join
		(select grab_id, cal_id, Tipo_Llamada from TREC_GRABACION union select grab_id, cal_id, Tipo_Llamada from TREC_GRABACIONCONSULTA)as GRABACIONES
		on TREC_BACKUPS.grab_id = GRABACIONES.grab_id  where status_audio = 1 or status_audio = 2 order by grab_id asc;
	    END
	ELSE IF @cwIntegratedRIA = 1
		BEGIN
			select top 10000 TREC_BACKUPS.grab_id as grab_id, isnull(cal_id,0), Tipo_Llamada, status_audio, status_video from TREC_BACKUPS inner join
			(select grab_id, cal_id, Tipo_Llamada from RIA_GRABACION union select grab_id, cal_id, Tipo_Llamada from RIA_GRABACIONCONSULTA)as GRABACIONES
			on TREC_BACKUPS.grab_id = GRABACIONES.grab_id  where status_audio = 1 or status_audio = 2 order by grab_id asc;
		END
	ELSE
	    BEGIN
		select top 10000 grab_id, status_audio, status_video from trec_backups where status_audio = 1 or status_audio = 2 order by grab_id asc;
	    END
	END'

	EXEC(@Sql)


	set @process = 'Update stored - trsp_GetFirstBackupFile'
	set @Sql='


	ALTER PROCEDURE [dbo].[trsp_GetFirstBackupFile]
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
			if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[RIA_GRABACIONConsulta]''))
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

			SELECT ''FirstBackupFile''=@FirstBackupFile, ''Date''=@Date
		END
	ELSE
		BEGIN
			--delete RIA_ARCHIVO_GRABACION where hecho = 0
			if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[TREC_GRABACIONConsulta]''))
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

			SELECT ''FirstBackupFile''=@FirstBackupFile, ''Date''=@Date
		END 

	END 
	'
	EXEC(@Sql)

	set @process = 'Update stored - trsp_GetCompleteBackupRange'
	set @Sql='
	
	ALTER PROCEDURE [dbo].[trsp_GetCompleteBackupRange]
	@EndDate DATETIME,
	@isIntegratedRIA BIT

	AS
	DECLARE @Count AS BIGINT
	DECLARE @CountHist AS BIGINT
	DECLARE @MaxExist AS bigint
	DECLARE @MinTime AS INT
	DECLARE @MinFile AS bigint
	DECLARE @MaxFileAr AS bigint
	declare @UsoHist as Bit
	Declare @ExistHist as bit
	BEGIN

	IF @isIntegratedRIA  = 1
		BEGIN
			if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[RIA_GRABACIONCONSULTA]''))
				set @ExistHist = 1
			else
				set @ExistHist = 0
			SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
			IF (@MinTime is NULL)
			BEGIN
				SELECT @MinTime=5
			END

			SELECT @MaxFileAr=MAX(grab_id) FROM TREC_BACKUPS
			IF (@MaxFileAr is NULL)
			BEGIN
				SELECT @MaxFileAr=-1
			END
	
			set @UsoHist =1
			if @ExistHist = 1
			begin
				SELECT @MinFile=MIN(grab_id) FROM RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_2)) 
					WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
				if (@MinFile is NULL)
				begin
					SELECT @MinFile=MIN(grab_id) FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) 
						WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
					set @UsoHist = 0
				end
			end
			else
			begin
				SELECT @MinFile=MIN(grab_id) FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) 
					WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
				set @UsoHist = 0
			end

			SELECT @MaxExist=MAX(grab_id) FROM RIA_GRABACION with (index(IX_RIA_GRABACION_3)) WHERE finicio <= @EndDate 
			IF (@MaxExist is NULL)
			BEGIN
				if (@UsoHist = 1)
				begin
					SELECT @MaxExist=MAX(grab_id) FROM RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_3)) WHERE finicio <= @EndDate
				end
				else
					SELECT @MaxExist=0
			END 
			if (@MinFile>@MaxExist)
			begin
				set @MaxExist = @MinFile
			end
			set @CountHist = 0
			if (@UsoHist = 1)
			begin
				SELECT @CountHist=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_4)) 
					WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
					AND (tamano > 0) AND (duracion >= @MinTime)		

				IF (@CountHist is NULL)
				BEGIN
					SELECT @CountHist = 0
				END
			end
			SELECT @Count=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM RIA_GRABACION with (index(IX_RIA_GRABACION_4)) 
				WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
				AND (tamano > 0) AND (duracion >= @MinTime)		

			IF (@Count is NULL)
			BEGIN
				SELECT @Count = 0
			END

			SELECT ''MinFile''=@MinFile,  ''MaxFile''=@MaxExist, ''Size''=(@Count+@CountHist)
		END
	ELSE
		BEGIN
			if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N''[dbo].[TREC_GRABACIONCONSULTA]''))
				set @ExistHist = 1
			else
				set @ExistHist = 0
			SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
			IF (@MinTime is NULL)
			BEGIN
				SELECT @MinTime=5
			END

			SELECT @MaxFileAr=MAX(grab_id) FROM TREC_BACKUPS
			IF (@MaxFileAr is NULL)
			BEGIN
				SELECT @MaxFileAr=-1
			END
	
			set @UsoHist =1
			if @ExistHist = 1
			begin
				SELECT @MinFile=MIN(grab_id) FROM TREC_GRABACIONCONSULTA with (index(IX_TREC_GRABACIONCONSULTA_2)) 
					WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
				if (@MinFile is NULL)
				begin
					SELECT @MinFile=MIN(grab_id) FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) 
						WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
					set @UsoHist = 0
				end
			end
			else
			begin
				SELECT @MinFile=MIN(grab_id) FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) 
					WHERE grab_id > @MaxFileAr AND duracion>=@MinTime
				set @UsoHist = 0
			end

			SELECT @MaxExist=MAX(grab_id) FROM TREC_GRABACION with (index(IX_TREC_GRABACION_3)) WHERE finicio <= @EndDate
			IF (@MaxExist is NULL)
			BEGIN
				if (@UsoHist = 1)
				begin
					SELECT @MaxExist=MAX(grab_id) FROM TREC_GRABACIONCONSULTA with (index(IX_TREC_GRABACIONCONSULTA_3)) WHERE finicio <= @EndDate
				end
				else
					SELECT @MaxExist=0
			END 
			if (@MinFile>@MaxExist)
			begin
				set @MaxExist = @MinFile
			end
			set @CountHist = 0
			if (@UsoHist = 1)
			begin
				SELECT @CountHist=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM TREC_GRABACIONCONSULTA with (index(IX_TREC_GRABACIONCONSULTA_4)) 
					WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
					AND (tamano > 0) AND (duracion >= @MinTime)		

				IF (@CountHist is NULL)
				BEGIN
					SELECT @CountHist = 0
				END
			end
			SELECT @Count=(SUM(CONVERT(BIGINT,tamano) ) / 1024) FROM TREC_GRABACION with (index(IX_TREC_GRABACION_4)) 
				WHERE (grab_id BETWEEN @MinFile AND @MaxExist)
				AND (tamano > 0) AND (duracion >= @MinTime)		

			IF (@Count is NULL)
			BEGIN
				SELECT @Count = 0
			END

			SELECT ''MinFile''=@MinFile,  ''MaxFile''=@MaxExist, ''Size''=(@Count+@CountHist)

		END

	END'
	EXEC(@Sql)

------------------ fin SCRIPT @Sql ------------------
	--		Generamos nueva version
			--exec dbo.ccsp_getVersion 'BD', @Version

	-- Updating DB Version
	
 	update trec_parametros set par_valor = @Version where par_id = 30 

	commit tran

	end try	
	begin catch	
		select @errorGenerated = 'DB Script Version: ' + cast(@Version as nvarchar) + ' Error Process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
		RAISERROR(@errorGenerated, 11, 1)
	rollback tran
	end catch
 end

else
 begin
	select 'Version incorrecta de base de datos, version actual: ' 
	+ cast(@Version_Actual as varchar(5))
	+ ', version que desea ingresar: ' + cast(@Version as varchar(5))
 end
set nocount off