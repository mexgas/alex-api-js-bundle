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

	-------------------------  Start CCC --------------------------------------------------
	 set @process = 'Se añade columna para permitir archivos adjuntos'
     set @sql = 'if not exists (select * from sys.columns where name = N''allowFileAttachments'' and Object_ID = Object_ID(N''yourTableName''))
				begin
					ALTER TABLE dbo.contactMeanIn ADD allowFileAttachments bit;
				end'
	 EXEC(@sql)

	 set @process = 'Se añade opción de archivos adjuntos para historial'
     set @sql = 'if not exists (select * from ccRIALog_Operation where operationType = 193)
				begin
					insert into  ccRIALog_Operation values (193,''Adjuntar archivos|Attach files'')
				end'
	 EXEC(@sql)


	 set @process = 'Cambio en SP [ccsp_GalateaGetInboundConfiguration]'
     set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetInboundConfiguration]
        @command int,
        @inboundId int
      AS
      BEGIN

      SET NOCOUNT ON;

      if @command=0
      begin
        select descripcion from ccInbound where Inbound_id = @inboundId
      end
      if @command=1 -- Voice campaign
      begin
        select 
        A.Inbound_id [InboundId],
        A.descripcion [Description],
        A.chat [MediaType],
        A.Status,
        isnull(gra.graphic_id,1) [Frame],
        A.tNotas,
        A.tMaxWaitCall,
        A.nMaxQue,
        A.tel_maxwait,
        A.tel_maxqueue,
        A.tel_outservice,
        A.tel_noct,
        A.ShowCalifWnd,
        A.editableCallKey [EditableCallKey],
        A.queuePosition [QueuePosition],
        A.tMaxQueueCallBack,
        A.stopRecording [StopRecording],
        A.dialPrefixOverflow [DialPrefixOverflow],
        isnull(A.callerIdDesc, '''') [CallerIdDesc],
        isnull(A.startStopRecording,0) [StartStopRecording],
        case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyAgent  else cast(0 as bit) end [CallBackSurveyAgent],
        case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyClient else cast(0 as bit) end [CallBackSurveyClient],
        case when A.cam_id > 0  and C.callsBySurvey>0 then cast(1 as bit) else cast(0 as bit) end [IsRelationSurvey],
        isnull(A.editableDtmf,0) [EditableDtmf],
        isnull(A.addDataCallBackReminder,0) [AddDataCallBackReminder]
        from ccInbound A
        left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
        left join ccCamps C on C.cam_id=A.cam_id
        where A.Inbound_id=@inboundId
      end
      if @command=2 -- WhatsApp campaign
      begin
        declare @numbers varchar(max)
        select @numbers=COALESCE(@numbers + '','', '''') + number from ccWhatsAppNumbers where inboundId = 0 and status = 1

        select i.Inbound_id [InboundId], i.descripcion [Description], i.chat [MediaType], i.Status, isnull(g.graphic_id,1) [Frame],
        ISNULL(c.conexionInfo,'''') [Number],
        ISNULL(@numbers,'''') [FreeNumbersStr],
        ISNULL(c.closeConversationTime, 0) [MaxAnswerTime],
        ISNULL(c.answerTimeoutClient, 30) [MUTimeOutClient],
		ISNULL(c.allowFileAttachments, 0) [AllowFileAttachments],
        i.tNotas [tNotas],
        i.ExitWrapUpDisposition,
        i.ShowCalifWnd
        from ccInbound i left join ccRIAInboundGraph g on i.Inbound_id = g.Inbound_id
        left join contactMeanIn c on i.Inbound_id = c.inboundId and i.chat = 5 and c.meanContactTypeId = 5
        where i.Inbound_id=@inboundId
      end
      if @command=3 -- Email campaign
      begin
        select 
        A.Inbound_id [InboundId],
        A.descripcion [Description],
        A.chat [MediaType],
        A.Status,
        isnull(gra.graphic_id,1) [Frame],
        A.tNotas,
        A.ShowCalifWnd,
        C.conexionInfo [ConnInfo],
        C.connUser  [ConnUserName],
        C.ConnPass [ConnPwd],
        C.isActive [IsActive],
        C.timeAlertMessage,
        C.closeConversationTime [CloseConversationTime],
        C.answerTimeOut [AnswerTimeOut],
        C.name [SenderName]
        from ccInbound A
        left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
        left join contactMeanIn C on A.Inbound_id = C.inboundId and C.meanContactTypeId=1
        where A.Inbound_id=@inboundId
      end
      RETURN(0)
        
      SET NOCOUNT OFF;    
      END
		'
	 EXEC(@sql)

	 set @process = 'Se cambia ccsp_UpdateACDWhatsappConfig'
     set @sql = 'ALTER PROCEDURE  [dbo].[ccsp_UpdateACDWhatsappConfig]
      @ConexionInfo varchar(400),
      @inbound_id int,
      @ConnUser varchar(60),
      @tNotas int,
      @closeConversationTime tinyint,
      @ShowCalifWnd bit,
      @ExitWrapUpDisposition bit,
      @MUTimeOutClient int,
	  @allowFileAttachments bit
      AS
      set nocount on
        IF EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
        BEGIN
          UPDATE contactMeanIn SET conexionInfo = @conexionInfo, connUser = @connUser, closeConversationTime = @closeConversationTime,
                        ConnPass = ''N/A'', numMessages = 3, timeAlertMessage = 5, answerTimeOut = 10 , answerTimeoutClient = @MUTimeOutClient, allowFileAttachments = @allowFileAttachments        
          where inboundId = @inbound_id;
          UPDATE ccWhatsAppNumbers SET inboundId = @inbound_id WHERE number = @conexionInfo
        END;

        IF EXISTS (SELECT Inbound_id FROM ccInbound WHERE Inbound_id = @inbound_id) 
        BEGIN
          UPDATE ccInbound SET tNotas = @tNotas, ShowCalifWnd = @ShowCalifWnd, ExitWrapUpDisposition = @ExitWrapUpDisposition where Inbound_id = @inbound_id;
        END;
      SELECT @inbound_id;
      return(@inbound_id)

      set nocount off'')'
	 EXEC(@sql)

	 set @process = 'Se cambia ccsp_GalateaUpdateWhatsAppConfiguration'
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
        @showCalifWnd     bit     = null,
		@allowFileAttachments bit    = null
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
          answerTimeoutClient = ISNULL(@muTimeOutClient, 30),
		  allowFileAttachments = ISNULL(@allowFileAttachments, allowFileAttachments)
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
      END'
	 EXEC(@sql)
		----------------------- End CCC   ---------------------------------------------

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


