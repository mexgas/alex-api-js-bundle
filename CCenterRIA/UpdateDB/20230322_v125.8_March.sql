/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 8
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci�n para cuando pasamos a una nueva versi�n LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN

	BEGIN TRY
		-------------------------------------------- BEGIN IVAN OUTBOUND HISTORICAL CHAT ------------------------------
		SET @process = 'DEV1-19 Alter ccsp_AgentHistoricalChat se agrega camp type en option 1, 2, 4, y 5 para traer también conversaciones de salida'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentHistoricalChat] 
					@option SMALLINT, 
					@clientNum VARCHAR(15) = '''', 
					@conversationId AS INT = 0, 
					@inboundId AS SMALLINT = 0, 
					@serviceType AS SMALLINT = 0,
					@campType AS INT = 0
		            AS
		            BEGIN
		                IF @option = 1 --whatsapp, get conversation ids
		                BEGIN
							DECLARE @tempId INT = 0
							IF @campType = 0 -- INBOUND
							BEGIN
								SELECT conversationId
								FROM ccWhatsAppConversations
								WHERE clientId = @clientNum 
								GROUP BY conversationId
							END
							ELSE
							BEGIN  -- OUTBOUND
								SELECT conversationId
								FROM ccWhatsAppConversationsOut
								WHERE clientId = @clientNum 
								GROUP BY conversationId
							END
		                END

		                IF @option = 2 --whatsapp, get acdId by conversation id
		                BEGIN
							IF @campType = 0
							BEGIN
								SELECT CAST(inboundId AS INT)
								FROM [CCenterRIA].[dbo].[ccWhatsAppConversations]
								WHERE conversationId = @conversationId
							END
							ELSE
							BEGIN
								SELECT CAST(camId AS INT)
								FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsOut]
								WHERE conversationId = @conversationId
							END
		                END

		                IF @option = 3 --get data conversation
		                BEGIN
		                    DECLARE @OldAgentId INT = 0
		                    DECLARE @OldConversationId INT = 0

		                    SELECT @OldAgentId = conv.agentId, @OldConversationId = rel.conversationIdBefore
		                    FROM ccWhatsAppConversationsRelationship rel
		                    RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
		                    WHERE rel.conversationIdAfter = @conversationId

		                    SELECT cast(i.chat AS INT) AS ServiceType, cast(c.conversationId AS INT) AS ConversationID, c.clientId AS ClientId, cm.conexionInfo AS [To], cast(i.Inbound_id AS INT) AS ACDId, i.descripcion AS ACDName, cast(g.
		                            graphic_id AS INT) AS ACDGraphicId, cast(cm.closeConversationTime AS INT) AS [TimeOut], cast(cm.answerTimeOut AS INT) AS [TimeOutWarning], i.ExitWrapUpDisposition AS [ExitWrapUpDisposition], i.tNotas AS 
		                        [WrapUpTime], i.ShowCalifWnd, cast(ISNULL(answerTimeoutClient, 30) AS INT) AS [AnswerTimeoutClient], ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS 
		                        [SecTimeOutLastMessageAgent], isnull(permission.AllowUnassign, 0) AS AllowUnassign, isnull(permission.AllowSpam, 0) AS AllowSpam, ISNULL(@OldAgentId, 0) AS OldAgentId, ISNULL(@OldConversationId, 0) AS 
		                        OldConversationId, c.agentId AS AgentId
		                    FROM ccInbound i
		                    INNER JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId
		                    INNER JOIN ccWhatsAppConversations c ON (
		                            c.inboundId = i.Inbound_id
		                            AND c.conversationId = @conversationId
		                            )
		                    INNER JOIN ccRIAInboundGraph g ON g.Inbound_id = i.Inbound_id
		                    LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
		                    LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
		                    WHERE i.chat = @serviceType
		                        AND i.Inbound_id = @inboundId

		                END

		                IF @option = 4 --get messages from conversation id
		                BEGIN
							DECLARE @filetype AS VARCHAR(5)

							IF @campType = 0
							BEGIN

								SELECT messageId AS MessageId, messageStatus AS STATUS, originType AS Origin, CASE 
		                        WHEN originType = ''Client''
		                            THEN 3
		                        WHEN originType = ''Agent''
		                            THEN 2
		                        WHEN originType = ''Admin''
		                            THEN 1
		                        ELSE 0
		                        END AS OriginType, timeStampMessage AS [Timestamp], CASE 
		                        WHEN typeMessage <> ''text''
		                            THEN ''''
		                        ELSE content
		                        END AS Content, typeMessage AS Type, CASE 
		                        WHEN typeMessage NOT IN (''text'', ''location'')
		                            THEN content
		                        ELSE ''''
		                        END AS Caption, CASE 
		                        WHEN originType = ''Client''
		                            THEN CASE 
		                                    WHEN typeMessage = ''text''
		                                        OR typeMessage = ''location''
		                                        THEN ''''
		                                    ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
		                                        typeMessage + CHAR(92) + CHAR(92) + messageId + ''.'' + CASE 
		                                            WHEN typeMessage = ''video''
		                                                THEN ''mp4''
		                                            WHEN typeMessage = ''image''
		                                                THEN ''jpg''
		                                            WHEN typeMessage = ''audio''
		                                                THEN ''mp3''
		                                            WHEN typeMessage = ''file''
		                                                THEN (
		                                                        SELECT substring(content, CHARINDEX(''.'', content) + 1, len(content))
		                                                        )
		                                            ELSE ''''
		                                            END
		                                    END
		                        ELSE CASE 
		                                WHEN typeMessage = ''text''
		                                    OR typeMessage = ''location''
		                                    THEN ''''
		                                ELSE content
		                                END
		                        END AS [Url], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 1
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Address], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 2
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Lat], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 3
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Long], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 4
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Name], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN ''https://www.google.com/maps/search/'' + (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 2
		                                                ), '':'')
		                                    WHERE id = 2
		                                    ) + '','' + (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 3
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [LocationURL]
								FROM ccWAMessagesConversations
								WHERE conversationId = @conversationId
								ORDER BY TIMESTAMP ASC
							END
							ELSE
							BEGIN
								SELECT messageId AS MessageId, messageStatus AS STATUS, originType AS Origin, CASE 
		                        WHEN originType = ''Client''
		                            THEN 3
		                        WHEN originType = ''Agent''
		                            THEN 2
		                        WHEN originType = ''Admin''
		                            THEN 1
		                        ELSE 0
		                        END AS OriginType, timeStampMessage AS [Timestamp], CASE 
		                        WHEN typeMessage <> ''text''
		                            THEN ''''
		                        ELSE content
		                        END AS Content, typeMessage AS Type, CASE 
		                        WHEN typeMessage NOT IN (''text'', ''location'')
		                            THEN content
		                        ELSE ''''
		                        END AS Caption, CASE 
		                        WHEN originType = ''Client''
		                            THEN CASE 
		                                    WHEN typeMessage = ''text''
		                                        OR typeMessage = ''location''
		                                        THEN ''''
		                                    ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
		                                        typeMessage + CHAR(92) + CHAR(92) + messageId + ''.'' + CASE 
		                                            WHEN typeMessage = ''video''
		                                                THEN ''mp4''
		                                            WHEN typeMessage = ''image''
		                                                THEN ''jpg''
		                                            WHEN typeMessage = ''audio''
		                                                THEN ''mp3''
		                                            WHEN typeMessage = ''file''
		                                                THEN (
		                                                        SELECT substring(content, CHARINDEX(''.'', content) + 1, len(content))
		                                                        )
		                                            ELSE ''''
		                                            END
		                                    END
		                        ELSE CASE 
		                                WHEN typeMessage = ''text''
		                                    OR typeMessage = ''location''
		                                    THEN ''''
		                                ELSE content
		                                END
		                        END AS [Url], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 1
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Address], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 2
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Lat], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 3
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Long], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 4
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [Name], CASE 
		                        WHEN typeMessage = ''location''
		                            THEN ''https://www.google.com/maps/search/'' + (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 2
		                                                ), '':'')
		                                    WHERE id = 2
		                                    ) + '','' + (
		                                    SELECT value
		                                    FROM dbo.fn_RIASplitDelimited((
		                                                SELECT value
		                                                FROM dbo.fn_RIASplitDelimited(content, ''|'')
		                                                WHERE id = 3
		                                                ), '':'')
		                                    WHERE id = 2
		                                    )
		                        ELSE ''''
		                        END AS [LocationURL]
								FROM ccWAMessagesConversationsOut
								WHERE conversationId = @conversationId
								ORDER BY TIMESTAMP ASC
							END
		                    
		                END

		                IF @option = 5 --get if conversation is reassigned
		                BEGIN
							IF @campType = 0
							BEGIN
								SELECT CASE 
		                            WHEN EXISTS (
		                                    SELECT *
		                                    FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationship]
		                                    WHERE conversationIdAfter = @conversationId
		                                    )
		                                THEN CAST(1 AS BIT)
		                            ELSE CAST(0 AS BIT)
		                            END
							END
							ELSE
							BEGIN
								SELECT CASE 
		                            WHEN EXISTS (
		                                    SELECT *
		                                    FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationshipOut]
		                                    WHERE conversationIdAfter = @conversationId
		                                    )
		                                THEN CAST(1 AS BIT)
		                            ELSE CAST(0 AS BIT)
		                            END
							END
		                END
		            END'
		EXEC(@sql)

		-------------------------------------------- END IVAN OUTBOUND HISTORICAL CHAT ------------------------------
		SET @process = 'DEV1-19 Alter ccsp_SaveDispositionsMultimedia Se modifica para que tengamos option @mediaType 7 cuando es WhatsApp ccWhatsAppConversationsOut'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_SaveDispositionsMultimedia] @action         INT
                                                      , @conversationId bigint      = 0
                                                      , @disposition    SMALLINT = 0
                                                      , @subDisposition SMALLINT = 0
                                                      , @tWrapUp        SMALLINT = 0
                                                      , @mediaType      SMALLINT = 0
													  , @campType bit =0
					AS
					BEGIN

					    SET NOCOUNT ON;

					    IF @action = 1
					    BEGIN --Califica la conversación y pone el tiempo Notas
					        DECLARE @Temp NVARCHAR(1000),@tableName NVARCHAR(255),@type int
							
							set @mediaType= CASE when @mediaType=5 and @campType=1 then 7 else @mediaType end
							set @type=CASE @mediaType WHEN 6 then 1 else @mediaType end ---revisar tabla ccfinderServices

							set @tableName= CASE @mediaType 
										WHEN 5 THEN ''ccWhatsAppConversations'' 
										WHEN 6 THEN ''chat'' 
										WHEN 7 THEN ''ccWhatsAppConversationsOut'' 
										ELSE '''' END

							set @Temp= N''UPDATE '' +
					                @tableName + '' SET disposition= @disposition ,subDisposition= @subDisposition ,tWrapUp= @tWrapUp WHERE conversationId= @conversationId;'';
					        EXEC sp_executesql
					             @temp
					           , N''@disposition SMALLINT, @subDisposition SMALLINT, @tWrapUp SMALLINT, @conversationId INT''
					           , @disposition
					           , @subDisposition
					           , @tWrapUp
					           , @conversationId;


							exec ccsp_CreateNodeMultimedia @conversationId=@conversationId, @type=@type

					    END;
					END; '
		exec (@sql)

----------------------------------------------IVAN Fix Campaigns Configuration ---------------------------------------------
		SET @process = 'Se hace merge de Sps pasados para tener todos los datos'
		SET @sql = 'Alter PROCEDURE [dbo].[ccsp_GalateaGetOutboundConfiguration] @adminID INT, @campID INT
					AS
					BEGIN
						DECLARE @AllCampaigns TABLE (
							cam_id SMALLINT
							,cam_Descripcion VARCHAR(60)
							,cam_tNotas SMALLINT
							,cam_ocupado SMALLINT
							,cam_noInt_ocupado SMALLINT
							,cam_inter_ocupado SMALLINT
							,cam_nocontesto SMALLINT
							,cam_noInt_nocontesto SMALLINT
							,cam_inter_nocontesto SMALLINT
							,cam_fax SMALLINT
							,cam_noInt_fax SMALLINT
							,cam_inter_fax SMALLINT
							,cam_modomanual SMALLINT
							,ANI VARCHAR(15)
							,cam_ShowCalifWnd BIT
							,cam_StartTimerOnHangUp BIT
							,editableCallKey BIT
							,cam_tNoContesta SMALLINT
							,iTipoDial SMALLINT
							,detectAnswerMachine SMALLINT
							,detectVoiceMail SMALLINT
							,compliance SMALLINT
							,cam_inter_graba SMALLINT
							,cam_noint_graba SMALLINT
							,progDial SMALLINT
							,excCallBack SMALLINT
							,dialOrder SMALLINT
							,dialPrefix VARCHAR(10)
							,dialPrefixMan VARCHAR(10)
							,dialPrefixXfe VARCHAR(10)
							,listenManualCall BIT
							,stopRecording BIT
							,abandonCallback BIT
							,frame SMALLINT
							,t_autoCB SMALLINT
							,id_anilist INT
							,tDialonWrapUp SMALLINT
							,viewMode TINYINT
							,queSize SMALLINT
							,DNCScrub INT
							,callerIdDesc VARCHAR(15)
							,timeZoneRule INT
							,callsBySurvey INT
							,ivrScript INT
							,surveyPctg INT
							,call_record SMALLINT
							,startStopRecording BIT
							,leaveRecMessage BIT
							,manualCallOnChat BIT
							,callBackSurveyAgent BIT
							,callBackSurveyClient BIT
							,isRelationSurvey BIT
							,funcEspDtmf INT
							,sipHdrFormat VARCHAR(255)
							,cam_inter_cancelled SMALLINT
							,prefijo VARCHAR(40)
							,enbleprefix BIT
							,exitAssisted BIT
							,previewDiscard BIT
							,CampType INT
							,conexionInfo VARCHAR(50)
							,connUser VARCHAR(15)
							,closeConversationTime SMALLINT
							,answerTimeoutClient INT
							,allowFileAttachments BIT
							,CamTPreview SMALLINT
							,TimesPreview TINYINT
							,selectRotativeANI INT
							,rotativeAlgo TINYINT
							,autoStart BIT
							,messagingOrder BIT
							,timesDiscard TINYINT
							)
						DECLARE @numbers VARCHAR(max)

						SELECT @numbers = COALESCE(@numbers + '''', '''', '''''''') + number
						FROM ccWhatsAppNumbers
						WHERE camp_id = 0
							AND STATUS = 1

						INSERT INTO @AllCampaigns
						EXEC ccsp_RIAConfCamp @adminID
							,@campID

						SELECT dialPrefixMan DialPrefixMan
							,dialPrefixXfe DialPrefixXfe
							,listenManualCall ListenManualCall
							,stopRecording StopRecording
							,abandonCallback AbandonCallBack
							,t_autoCB AutoCB
							,id_anilist IdIstANI
							,tDialonWrapUp TDialOnWrapup
							,queSize Quesize
							,DNCScrub
							,callerIdDesc CallerIdDesc
							,timeZoneRule TimeZoneRule
							,callsBySurvey CallsBySurvey
							,ivrScript IvrScript
							,surveyPctg SurveyPctg
							,call_record CallRecord
							,startStopRecording StartStopRecording
							,leaveRecMessage LeaveRecMessage
							,manualCallOnChat ManualCallOnChat
							,callBackSurveyClient CallBackSurveyClient
							,callBackSurveyAgent CallBackSurveyAgent
							,funcEspDtmf FuncEspDtmf
							,sipHdrFormat SipHdrsCfg
							,dialPrefix DialPrefix
							,prefijo Prefix
							,dialOrder DialOrder
							,progDial ProgDial
							,cam_Descripcion CamDescription
							,cam_tNotas CamTnotas
							,cam_ocupado CamBusy
							,cam_noInt_ocupado CamNoIntBusy
							,cam_inter_ocupado CamInterBusy
							,cam_nocontesto CamNoAnswer
							,cam_noInt_nocontesto CamNoIntNoAnswer
							,cam_inter_nocontesto CamInterNoAnswer
							,(cam_inter_cancelled / 60) CamInterCancelled
							,cam_fax CamFax
							,cam_noInt_fax CamNoIntFax
							,cam_inter_fax CamInterFax
							,cam_modomanual CamModoManual
							,ANI
							,cam_StartTimerOnHangUp CamStartTimerOnHangUp
							,editableCallKey EditableCallKey
							,cam_tNoContesta CamTNoAnswer
							,iTipoDial CamIntensiveDialing
							,detectAnswerMachine DetectAnswerMachine
							,detectVoiceMail DetectVoiceMail
							,compliance Compliance
							,cam_inter_graba CamInterRecord
							,cam_noint_graba CamNoIntRecord
							,excCallBack ExcCallBack
							,cam_ShowCalifWnd CamShowCalifWnd
							,frame Frame
							,exitAssisted ExitAssistedDialMode
							,previewDiscard PreviewDiscard
							,CampType
							,conexionInfo ConexionInfo
							,connUser ConnUser
							,closeConversationTime CloseConversationTime
							,answerTimeoutClient MUTimeOutClient
							,allowFileAttachments AllowFileAttachments
							,CamTPreview
							,CAST(TimesPreview AS SMALLINT) TimesPreview
							,@numbers AS FreeNumbers
							,selectRotativeANI SelectRotativeANIManualCall
							,rotativeAlgo RotativeAlgo
							,autoStart AutoStart
							,messagingOrder MessagingOrder
							,timesDiscard TimesDiscard
						FROM @AllCampaigns
						WHERE cam_id = @campID
					END'
		exec (@sql)

		SET @process = 'Se hace merge de Sps pasados para tener todos los datos'
		SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp] @User_id SMALLINT, @campID INT = NULL
					AS
					SET NOCOUNT ON

					DECLARE @tableExistsRec TABLE (
						camId INT PRIMARY KEY
						,existRec BIT
						)
					DECLARE @camByUser TABLE (
						camId INT PRIMARY KEY
						,isCheck BIT
						)
					DECLARE @camId INT
						,@id INT;

					IF NOT EXISTS (
							SELECT *
							FROM ccUsers_Roles
							WHERE User_id = @User_id
								AND Rol_id = 7
							)
					BEGIN
						INSERT INTO @camByUser
						SELECT *
							,0
						FROM dbo.fGet_CampAcd_Area(@User_id, 1) B
						WHERE @campID IS NULL
							OR cam_id = @campID
					END
					ELSE
					BEGIN
						INSERT INTO @camByUser
						SELECT cam_id
							,0
						FROM ccCamps
						WHERE (
								IDArea > 0
								OR IDArea IS NULL
								)
							AND (
								@campID IS NULL
								OR cam_id = @campID
								)
					END

					WHILE EXISTS (
							SELECT *
							FROM @camByUser
							WHERE isCheck = 0
							)
					BEGIN
						SELECT TOP 1 @camId = camId
						FROM @camByUser
						WHERE isCheck = 0

						IF EXISTS (
								SELECT cam_id
								FROM ccoCallsOut
								WHERE cam_id = @camId
								)
						BEGIN
							INSERT INTO @tableExistsRec
							VALUES (
								@camId
								,1
								)
						END
						ELSE
						BEGIN
							INSERT INTO @tableExistsRec
							VALUES (
								@camId
								,0
								)
						END

						UPDATE @camByUser
						SET isCheck = 1
						WHERE camId = @camId
					END

					SELECT a1.cam_id
						,cam_Descripcion
						,cam_tNotas
						,cast(cam_ocupado AS INT) AS cam_ocupado
						,cam_noInt_ocupado
						,cam_inter_ocupado
						,cast(cam_nocontesto AS INT) AS cam_nocontesto
						,cam_noInt_nocontesto
						,cam_inter_nocontesto
						,cast(cam_fax AS INT) AS cam_fax
						,cam_noInt_fax
						,cam_inter_fax
						,cast(cam_modomanual AS INT) AS cam_modomanual
						,ANI
						,cam_ShowCalifWnd
						,cam_StartTimerOnHangUp
						,editableCallKey
						,cam_tNoContesta
						,iTipoDial
						,detectAnswerMachine
						,detectVoiceMail
						,compliance
						,cam_inter_graba
						,cam_noint_graba
						,cast(progDial AS TINYINT) progDial
						,cast(excCallBack AS TINYINT) excCallBack
						,dialOrder
						,dialPrefix
						,dialPrefixMan
						,dialPrefixXfe
						,listenManualCall
						,stopRecording
						,cast(abandonCallback AS TINYINT) abandonCallback
						,a3.frame
						,a1.t_autoCB
						,a1.id_anilist
						,a1.tDialonWrapUp
						,dbo.fn_viewMode(@User_id, 10) viewMode
						,cam_maxqueue AS queSize
						,DNCScrub
						,callerIdDesc
						,timeZoneRule
						,callsBySurvey
						,ivrScript
						,surveyPctg
						,isnull(a1.call_record, 1) AS call_record
						,cast(startStopRecording AS TINYINT) startStopRecording
						,leaveRecMessage
						,manualCallOnChat
						,callBackSurveyAgent
						,callBackSurveyClient
						,CASE 
							WHEN surveycamid IS NULL
								OR surveycamid = 0
								THEN 0
							ELSE 1
							END isRelationSurvey
						,isnull(a1.funcEspDtmf, 0)
						,isnull(sipHdrFormat, '''''''') sipHdrFormat
						,cam_inter_cancelled
						,prefijo
						,enbleprefix = CASE 
							WHEN existRec = 0
								THEN 1
							ELSE 0
							END
						,isnull(exitAssisted, 0) exitAssisted
						,isnull(previewDiscard, 0) PreviewDiscard	
						,isnull(CampType, 0) CampType
						,isnull(contact.conexionInfo, '''''''') conexionInfo
						,isnull(contact.connUser, '''''''') connUser
						,isnull(contact.closeConversationTime, 0) closeConversationTime
						,isnull(contact.answerTimeoutClient, 0) answerTimeoutClient
						,isnull(contact.allowFileAttachments, 0) allowFileAttachments
						,isnull(selectRotativeANI, 0) selectRotativeANI
						,ISNULL(rotativeAlgo, 0) rotativeAlgo
						,isnull(autoStart, 0) autoStart
						,isnull(messagingOrder, 0) messagingOrder
						,ISNULL(cam_tPreview, 0) AS CamTPreview
						,ISNULL(timesPreview, 0) AS TimesPreview
						,isnull(timesDiscard, 0) TimesDiscard
					FROM ccCamps a1
					INNER JOIN ccRIACampsGraph a2 ON (a1.cam_id = a2.cam_id)
					INNER JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
					INNER JOIN @tableExistsRec a4 ON a1.cam_id = a4.camId
					LEFT JOIN contactMeanOut contact ON a1.cam_id = contact.camp_id
					ORDER BY cam_descripcion

					RETURN (0)

					SET NOCOUNT OFF'
		exec (@sql)
----------------------------------------------------------------------------------------------------------------------------
		/* End script release */
		/* Upgrade database version (first and the last number of setting 77) */
		EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
