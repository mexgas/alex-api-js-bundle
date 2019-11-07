CREATE PROCEDURE [dbo].[trsp_GetFilesForBackup]
							@start bigint,
							@end bigint,
							@isIntegratedRIA bit
							AS
							DECLARE @MinTime AS INT
							Declare @ExistHist as bit
							declare @ExistRepositorio as bit

							BEGIN

							  IF @isIntegratedRIA = 1
							    BEGIN
							      if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RIA_GRABACIONConsulta]'))
							        set @ExistHist = 1
							      else
							        set @ExistHist = 0
							      if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[TREC_Repositorios]'))
							        set @ExistRepositorio = 1
							      else
							        set @ExistRepositorio = 0
							      SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
							      IF (@MinTime is NULL)
							      BEGIN
							        SELECT @MinTime=7
							      END
							      if @ExistHist = 1
							      begin
							        if @ExistRepositorio = 1
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2))  WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end 
							          union
							          SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM RIA_GRABACIONConsulta with (index(IX_RIA_GRABACIONCONSULTA_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							        else
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, 0, 0  FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end 
							          union
							          SELECT grab_id, tipo_llamada, cal_id, 0, 0  FROM RIA_GRABACIONConsulta with (index(IX_RIA_GRABACIONCONSULTA_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							      end
							      else
							      begin
							        if @ExistRepositorio = 1
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM RIA_GRABACION  with (index(IX_RIA_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							        else
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, 0,0  FROM RIA_GRABACION with (index(IX_RIA_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							      end
							    END
							  ELSE
							    BEGIN
							      if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[TREC_GRABACIONConsulta]'))
							        set @ExistHist = 1
							      else
							        set @ExistHist = 0
							      if exists (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[TREC_Repositorios]'))
							        set @ExistRepositorio = 1
							      else
							        set @ExistRepositorio = 0
							      SELECT @MinTime=CONVERT(int,par_valor) FROM TREC_PARAMETROS WHERE par_id = 4
							      IF (@MinTime is NULL)
							      BEGIN
							        SELECT @MinTime=7
							      END
							      if @ExistHist = 1
							      begin
							        if @ExistRepositorio = 1
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM TREC_GRABACION with(index(IX_TREC_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end 
							          union
							          SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM TREC_GRABACIONConsulta with (index(IX_TREC_GRABACIONCONSULTA_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							        else
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, 0, 0  FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end 
							          union
							          SELECT grab_id, tipo_llamada, cal_id, 0, 0  FROM TREC_GRABACIONConsulta with (index(IX_TREC_GRABACIONCONSULTA_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							      end
							      else
							      begin
							        if @ExistRepositorio = 1
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, isnull(id_repositorio,0) as id_repositorio, isnull(id_rep_video,0) as id_rep_video FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							        else
							        begin
							          SELECT grab_id, tipo_llamada, cal_id, 0,0  FROM TREC_GRABACION with (index(IX_TREC_GRABACION_2)) WHERE duracion >= @MinTime AND grab_id >= @start AND grab_id <= @end order by grab_id
							        end
							      end

							    END

							END