USE [CCenterRia]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_GalateaExcelTemplatesABC]    Script Date: 10/09/2019 11:28:47 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

          CREATE PROCEDURE [dbo].[ccsp_GalateaGetRecordsImportStatus]
          -- @Type = 1:Detalle general de carga de registros | 2:Detalle específico de carga de registros | 3:Porcentaje de carga de registros
          @action tinyint, 
          @loadID int = NULL, 
          @userID smallint = NULL

          AS
          SET nocount ON
          if @action not IN (1,2,3)
            raiserror('ERROR. No se ingreso parametro de entrada', 18, 1)

          if @action=1 -- Detalle general de carga de registros
           BEGIN
            if not exists(SELECT User_id FROM ccUsers WHERE TipoUser_id IN(2,6) AND Status>0 AND User_id=@userID)
             BEGIN
              raiserror('ERROR. invalid user id', 18, 1)
              return(0)
             END

            SELECT load_id, camName, pctg, regsLoaded, regsNotLoaded, state
            FROM ccRIALoading riaLoad
            JOIN ccSupervisorCam superCam ON riaLoad.cam_id = superCam.cam_id
            WHERE superCam.user_id = @userID
            AND superCam.tipo = 1

            return(0)
           END

          if @action=2 -- Detalle específico de carga de registros
           BEGIN
            if not exists(SELECT load_id FROM ccRIALoading)
             BEGIN
              raiserror('ERROR. invalid template ID', 18, 1)
              return(0)
             END

              SELECT regsLoaded, alreadyLoaded, regsBlocked, regsNotLoaded,
                     telsLoaded, telsBlocked, telsNotLoaded
              FROM ccRIALoading
              WHERE load_id  = @loadID
           
           END

          if @action=3 -- Porcentaje de carga de registros
           BEGIN
            if not exists(SELECT load_id FROM ccRIALoading)
             BEGIN
              raiserror('ERROR. invalid load ID', 18, 1)
              return(0)
             END

              SELECT state, pctg
              FROM ccRIALoading
              WHERE load_id  = @loadID

           END
          SET nocount off
          