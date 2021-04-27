CREATE PROCEDURE ccsp_GalateaGetBlacklistImportStatus -- guiandose del sp ccsp_GalateaGetRecordsImportStatus(carga a campañas)
@action tinyint,
@loadID int = NULL

AS
declare @today datetime
select @today =convert(datetime, convert(varchar(11),getdate(),121),121)

SET nocount ON
if @action not IN (1,2)
	BEGIN
		raiserror('ERROR. No se ingreso parametro de entrada', 18, 1)
		return (0)
	END

if @action=1 -- Detalle general de carga de registros a listas Negras
BEGIN
     SELECT DISTINCT load_id as LoadId, camName as BlacklistName, cam_id as BlacklistId, pctg as ProgressPercentage , regsNotLoaded+regsBlocked as PhonesNotLoaded,
		regsLoaded as PhonesLoaded, state as LoadState, loadDate as StartLoadDate
        FROM ccRIALoading riaLoad
        WHERE 
        loadDate>=@today
        ORDER BY riaLoad.loadDate DESC
END

if @action=2 -- obtiene datos especificos de una carga a listas Negras a partir del id de carga
BEGIN
     SELECT DISTINCT load_id as LoadId, camName as BlacklistName, cam_id as BlacklistId, pctg as ProgressPercentage , regsNotLoaded+regsBlocked as PhonesNotLoaded,
		regsLoaded as PhonesLoaded, state as LoadState, loadDate as StartLoadDate
        FROM ccRIALoading riaLoad
        WHERE 
        load_id=@loadID
END