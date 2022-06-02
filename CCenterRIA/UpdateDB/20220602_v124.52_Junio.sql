/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/02/15
Description: Merge con los cambios de sorteos

Database: CCenterRia
Required version: 123.27

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
SET @version = 123 --**********actualizar a 123 sin fix
SET @versionfix = 30
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= 30
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-6946 ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateWhatsAppConfiguration]'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateWhatsAppConfiguration]
  @inboundId        smallint,
  @frame          smallint  = null,
  @description      varchar(50) = null,
  @mediaType        tinyint   = null,
  @status         smallint  = null,
  @number         varchar(400)= null,
  @maxAnswerTime      tinyint   = null,
  @muTimeOutClient    int     = null,
  @tNotas         int     = null,
  @exitWrapUpDisposition  bit     = null,
  @showCalifWnd     bit     = null
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @graph_id smallint

  UPDATE ccInbound SET
    descripcion = ISNULL(@description, descripcion),
    chat = ISNULL(@mediaType, chat),
    Status = ISNULL(@status, Status),
    tNotas = ISNULL(@tNotas, tNotas),
    ExitWrapUpDisposition = ISNULL(@exitWrapUpDisposition, ExitWrapUpDisposition)
  WHERE Inbound_id = @inboundId

  DECLARE @descUpdate varchar(50)
  DECLARE @statusCCInbound smallint
  select @descUpdate = ISNULL(@description, descripcion), @statusCCInbound = status from ccInbound where Inbound_id =@inboundId

  IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId=@inboundId) 
    BEGIN
        INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) 
    values (5, @descUpdate, @inboundId, @statusCCInbound);
    END

  IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inboundId) 
    BEGIN

set @number = case when  @number is null or @number in('''',''0'') then '''' else @number end

    UPDATE contactMeanIn set name=@descUpdate, conexionInfo=ISNULL(@number, conexionInfo)
,connUser=ISNULL(@number, connUser)
,ConnPass=ISNULL(@number, ConnPass) 
    ,closeConversationTime = ISNULL(@maxAnswerTime, closeConversationTime),
    answerTimeoutClient = ISNULL(@muTimeOutClient, 30)
    where inboundId = @inboundId;

update ccWhatsAppNumbers set inboundId=0 where inboundId=@inboundId
if @number <> '''' begin
update ccWhatsAppNumbers set inboundId=@inboundId where inboundId=0 and number=@number
end

    END

  IF @frame IS NOT NULL
  BEGIN
    SELECT @graph_id = graphic_id from ccRIAGraphics where frame = @frame and [type_id] = 1
    UPDATE ccRIAInboundGraph set graphic_id = ISNULL(@graph_id, graphic_id) where inbound_id = @inboundId
  END

  IF @showCalifWnd = 1
    BEGIN
    IF EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inboundId AND tipo = 0)
        BEGIN
      UPDATE ccInbound SET ShowCalifWnd = ISNULL(@showCalifWnd, ShowCalifWnd)
            WHERE inbound_id = @inboundId
      SELECT 1 [Result]
      RETURN(0)
        END

        SELECT -1 [Result]
        RETURN(0)
     END
     ELSE
   BEGIN
    UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inboundId;
   END

   SELECT 1 [Result]
   RETURN(0)

  SET NOCOUNT OFF;
END
  '
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


