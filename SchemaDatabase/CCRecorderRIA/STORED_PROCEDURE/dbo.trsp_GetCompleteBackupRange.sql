CREATE PROCEDURE [dbo].[trsp_GetCompleteBackupRange]
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
						      if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RIA_GRABACIONCONSULTA]'))
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

						      SELECT 'MinFile'=@MinFile,  'MaxFile'=@MaxExist, 'Size'=(@Count+@CountHist)
						    END
						  ELSE
						    BEGIN
						      if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[TREC_GRABACIONCONSULTA]'))
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

						      SELECT 'MinFile'=@MinFile,  'MaxFile'=@MaxExist, 'Size'=(@Count+@CountHist)

						    END

						  END