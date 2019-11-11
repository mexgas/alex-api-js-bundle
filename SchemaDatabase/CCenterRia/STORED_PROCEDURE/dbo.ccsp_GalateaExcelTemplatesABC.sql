CREATE procedure [dbo].[ccsp_GalateaExcelTemplatesABC]
          -- @Type = 1:Consulta de plantillas por archivo | 2:Detalle de plantilla por id
          @action tinyint, 
          @userID smallint = null, 
          @camID smallint = null, 
          @filename varchar(100) = null,
          @tempID smallint = null 

          AS
          set nocount on
          if @action not in (1,2) or (isnull(@userID,0)=0 and isnull(@camID,0)=0 and isnull(@filename,'')='')
            raiserror('ERROR. No se ingreso parametro de entrada', 18, 1)

          Declare @idioma tinyint
          select @idioma=valor from ccsettings where setting_id=27

          if @action=1 -- Catalogo de Templates
           begin
            if not exists(select User_id from ccUsers where TipoUser_id in(2,6) and Status>0 and User_id=@userID)
             begin
              raiserror('ERROR. invalid user id', 18, 1)
              return(0)
             end

            select Temp_id as id, Temp_Desc as name from ccTideWater_Templates
            where User_id = @userID
            AND cam_id = @camID
            AND PathFile = @filename


            return(0)
           end

          if @action=2 -- Detalle de plantilla por id
           begin
            if not exists(select Temp_id from ccTideWater_Templates where TempStatus>0 and Temp_id=@tempID)
             begin
              raiserror('ERROR. invalid template ID', 18, 1)
              return(0)
             end
           end
          set nocount off