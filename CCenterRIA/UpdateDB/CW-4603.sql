/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/11/10
Description:

Database: CCenterRia
Required version: 123.12

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
SET @versionfix = 13
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

set @process = 'CW-4603 DROP PROCEDURE [dbo].[ccsp_GalateaLoadWorkGroup]'
set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaLoadWorkGroup'')
    begin
        DROP PROCEDURE ccsp_GalateaLoadWorkGroup;
    end'
EXEC(@sql)

set @process = 'CW-4603 CREATE PROCEDURE [dbo].ccsp_GalateaLoadWorkGroup'
set @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaLoadWorkGroup]
@Option smallint,
@areaId int
as
declare @agentes varchar(max)
declare @admins varchar(max)
declare @campsIn varchar(max)
declare @campsOut varchar(max)
declare @wgs varchar(max)
declare @count int
declare @id int
declare @wg int

if @option =1 --Obtiene las relaciones de los WG de una area
begin
	SELECT 
	ROW_NUMBER() OVER(ORDER BY idWG ASC) AS Row,
	IDWG,@agentes as agents,@admins as admins,@campsIn as campsIn,@campsOut as campsOut
	into #Relations
	FROM ccRIAAreaWorkGroup 
	WHERE IDArea = @areaId;

	if not exists(select * from ccRIACat_Areas where IDArea = @areaId) or (select count(idWG) from #Relations) = 0
	begin
		select Null as IDWG ,@agentes as agents, @admins as admins, @campsIn as campsIn, @campsOut as campsOut, @wgs as idsWg
		return (0)
	end

	select @count = count(idWG) from #Relations
	set @id =1
	while @id<=@count
	begin
		select @wg =idwg from #Relations where Row =@id
		select @agentes=null, @admins=null,@campsIn=null,@campsOut=null
		select @agentes = coalesce(@agentes + '','', '''') +  convert(varchar(12),wgu.user_id)
		from ccUsers u inner join ccRIAWorkGroupUsers wgu on wgu.User_id = u.User_id
		where TipoUser_id = 1 and u.IdArea = @areaId and wgu.IDWG =@wg
		order by u.user_id

		select @admins = coalesce(@admins + '','', '''') +  convert(varchar(12),u.user_id)
		from ccUsers u inner join ccRIAWorkGroupUsers wgu on wgu.User_id = u.User_id
		where u.TipoUser_id > 1 and u.IdArea = @areaId  and wgu.IDWG =@wg
		order by u.user_id

		select @campsIn = coalesce(@campsIn + '','', '''') +  convert(varchar(12),inbound_id)
		from ccInbound i inner join ccRIACampEspWG wg on wg.IdCampEsp =i.Inbound_id
		where IdArea = @areaId  and wg.IDWG = @wg and wg.Tipo=0
		order by inbound_id
	
		select @campsOut = coalesce(@campsOut + '','', '''') +  convert(varchar(12),cam_id)
		from ccCamps c inner join ccRIACampEspWG wg on wg.IdCampEsp = c.cam_id
		where IdArea = @areaId and wg.IDWG = @wg and wg.Tipo=1
		order by cam_id

		Update #Relations set agents= @agentes, admins=@admins, campsIn = @campsIn, CampsOut = @campsOut where IDWG= @wg
		set @id=@id+1
	end
	select Cast(IDWG as varchar(10)) as idwg,agents,admins,campsIn,CampsOut from #Relations

end'
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
