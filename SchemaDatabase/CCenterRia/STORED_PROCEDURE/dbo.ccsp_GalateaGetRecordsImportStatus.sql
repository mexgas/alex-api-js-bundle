CREATE PROCEDURE [dbo].[ccsp_GalateaGetRecordsImportStatus]
-- @Type = 1:Detalle general de carga de registros | 2:Detalle específico de carga de registros | 3:Porcentaje de carga de registros
@action tinyint, 
@loadID int = NULL, 
@userID smallint = NULL

AS
declare @today datetime
select @today =convert(datetime, convert(varchar(11),getdate(),121),121)
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

if exists (select * from ccUsers_Roles where User_id = @userID and Rol_id = (select Rol_id from ccRoles where Level = 7))
    BEGIN
        SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked as regsNotLoaded, state, loadDate
        FROM ccRIALoading riaLoad
        JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
        WHERE 
        loadDate>=@today
        ORDER BY riaLoad.loadDate DESC
    END
else
    BEGIN
        SELECT DISTINCT load_id, cccamps.cam_descripcion as camName, pctg, regsLoaded+alreadyLoaded as regsLoaded, regsNotLoaded+regsBlocked as regsNotLoaded, state, loadDate
        FROM ccRIALoading riaLoad
        JOIN ccSupervisorCam superCam ON riaLoad.cam_id = superCam.cam_id
        JOIN ccCamps cccamps ON riaLoad.cam_id = cccamps.cam_id
        WHERE 
        loadDate>=@today AND
        superCam.user_id = @userID
        AND superCam.tipo = 1
        ORDER BY riaLoad.loadDate DESC
    END

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