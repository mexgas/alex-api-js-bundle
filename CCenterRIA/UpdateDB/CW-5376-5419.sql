/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/04/06
Description:

Database: CCenterRia
Required version: 123.18


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 19
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;



IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY




  set @process = 'CW-5376 5419 DROP PROCEDURE ccsp_GalateaAdminSubdispositionRelations'	
  set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSubdispositionRelations'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminSubdispositionRelations;
    end'
  EXEC(@sql)


  set @process = 'CW-5376 5419 CREATE PROCEDURE ccsp_GalateaAdminSubdispositionRelations'	
  set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSubdispositionRelations]
@command int,
@type tinyint = null, --0=Outbound, 1=Inbound
@califSub_id varchar(max) = null,
@calif_id smallint = null
AS
set nocount on

If @command = 1
begin
	select cast(0 as int) [type],
		r.calif_id,
		r.califSub_id
	from cctipoSubCalifRel r inner join ccTipoCalifSub t on r.califSub_id = t.califSub_id and r.tipoSubRel = 1
	where t.califSub_Status = 1
	UNION
	select cast(1 as int) [type],
		r.calif_id,
		r.califSub_id
	from cctipoSubCalifRel r inner join ccTipoCalifSubOUT t on r.califSub_id = t.califSub_id and r.tipoSubRel = 0
	where t.califSubOut_Status = 1
	order by [type], calif_id, califSub_id
end
if @command=2  --Asignar subcalificacion a una calificacion
begin
	if @type=1 and (select cast(sum(isnull(cast(canReprogram as tinyint),0)) as bit) FROM cctipocalifSub where califSub_id in
	(select value from dbo.fn_RIASplitDelimited (@califSub_id, '','')))>0 
	and not exists (select IB.cam_id from cctipocalif CO join ccCalifCamp CF on  CF.calif_id = CO.calif_id and CF.tipo = 0 
	join ccInbound IB on IB.Inbound_id = CF.cam_id where IB.cam_id is not null and CO.calif_id = @calif_id)
	begin
		select cast(-2 as smallint) [result]	-- Cant reprogram, there are not assigned campaign
		return(0)
	end

	insert cctipoSubCalifRel (calif_id, califSub_id, tipoSubRel)
	select @calif_id [calif_id], S.value [califSub_id], @type [Tipo]
	from dbo.fn_RIASplitDelimited (@califSub_id, '','') S
	where cast(@calif_id as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@type as varchar(10)) not in
   (select cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) from cctipoSubCalifRel)
	and S.value is not null

	if @type=0
	begin
		update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end
	
	select cast(1 as smallint) [result]	 -- Done! 
	return(0)
end
if @command=3	--Desasignacion de subcalificacion
begin
	delete cctipoSubCalifRel
    where cast(calif_id as varchar(10))+''|''+cast(califSub_id as varchar(10))+''|''+cast(tipoSubRel as varchar(10)) in
    (select cast(@calif_id as varchar(10))+''|''+cast(S.value as varchar(10))+''|''+cast(@type as varchar(10))
    from dbo.fn_RIASplitDelimited (@califSub_id, '','') S)

    if @type=0
	begin
      update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	end
end

set nocount off'
  EXEC(@sql)





		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
