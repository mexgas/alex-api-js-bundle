CREATE PROCEDURE [dbo].[ccsp_ScriptingADM] 
	-- Add the parameters for the stored procedure here
	@option smallint, 
	@scriptingId smallint = NULL,
	@scriptingName varchar(40) = NULL,
	@scriptId int = NULL,
	@scriptLabel varchar(40) = NULL,
	@scriptPlot varchar(MAX) = NULL,
	@scriptAnswers varchar(MAX) = NULL,
	@scriptVariables varchar(MAX) = NULL,
	@scriptStatus varchar(MAX) = NULL,
	@answerId int = NULL,   
	@answerPlot varchar(MAX) = NULL,   
	@answerStatus  varchar(MAX) = NULL,  
	@answerNextPlot  varchar(MAX) = NULL,
	@agentId int = NULL,
	@agentWindowPosition varchar(20) = NULL,
	@agentWindowSize varchar(20) = NULL,
	@callId smallint = NULL,
	@callType tinyint = NULL
 
AS
	-- INTERNAL VARS
DECLARE @newIdTemplate smallint
SET @newIdTemplate = 0


----------------------
---- CASE OPTIONS


-- DO NOTHING
IF @option = 1
	BEGIN	
		SELECT 1
	END


-- INSERT A NEW SCRIPTING TEMPLATE
IF @option = 2 
	BEGIN
		IF ( SELECT COUNT(*) FROM ScriptingTemplate WHERE name = @scriptingName ) > 0
			BEGIN
				SELECT -1 --'The Scripting template name is already in use.'
			END
		ELSE
			BEGIN
				INSERT INTO ScriptingTemplate(name) VALUES (@scriptingName)
				
				SELECT @newIdTemplate = scope_identity()
							
				SELECT @newIdTemplate
			END
	END


-- UPDATE A SCRIPTING TEMPLATE
IF @option = 3 
BEGIN
	IF ( SELECT COUNT(*) FROM ScriptingTemplate WHERE scriptingId  = @scriptingId ) = 0
		BEGIN
			SELECT -1 --'The scripting does not exists'
		END
	ELSE
		BEGIN
			UPDATE ScriptingTemplate SET name = @scriptingName WHERE scriptingId =@scriptingId
		END
	SELECT @scriptingId
END


-- DELETE
IF @option = 4
BEGIN

IF( SELECT COUNT(*) FROM ScriptingTemplate WHERE scriptingId  = @scriptingId ) > 0
	BEGIN
		DELETE FROM ScriptingTemplateStruct WHERE scriptingId=@scriptingId
		DELETE FROM ScriptingAnswerTemplate WHERE scriptingId=@scriptingId
		DELETE FROM ScriptingTemplate  WHERE scriptingId  = @scriptingId
		SELECT @scriptingId
	END
ELSE
	BEGIN
		SELECT -1
	END
END


-- SELECT ALL SCRIPTING TEMPLATES
IF @option = 5
BEGIN
	IF @scriptingId = 0
		BEGIN
			SELECT scriptingId , name FROM ScriptingTemplate 
		END
	ELSE
		BEGIN
			SELECT scriptingId , name FROM ScriptingTemplate WHERE scriptingId  = @scriptingId
		END
END


-- INSERT A NEW SCRIPT
IF @option = 6 
BEGIN
	INSERT INTO ScriptingTemplateStruct (scriptingId, scriptId, scriptLabel, scriptPlot, scriptAnswers, scriptVariables,scriptStatus)
	VALUES (@scriptingId, @scriptId, @scriptLabel, @scriptPlot, @scriptAnswers, ISNULL(@scriptVariables, ''),ISNULL(@scriptStatus, ''))
END

-- SELECT ALL SCRIPTS
IF @option = 7
BEGIN
	SELECT scriptId, scriptLabel, scriptPlot, scriptAnswers, scriptVariables, scriptStatus
	FROM ScriptingTemplateStruct
	WHERE scriptingId = @scriptingId
END

-- DELETE ALL SCRIPTS (SCRIPTING TEMPALTE STRUCT) OF SCRIPTING ID PROVIDED
IF @option = 8
BEGIN
	DELETE ScriptingTemplateStruct WHERE scriptingId = @scriptingId
	DELETE ScriptingAnswerTemplate WHERE scriptingId = @scriptingId
END

-- INSERT A NEW ANSWER SCRIPT
IF @option = 9
BEGIN
	INSERT INTO ScriptingAnswerTemplate (scriptingId, answerId, answerPlot, answerStatus, nextPlot)
	VALUES (@scriptingId, @answerId, @answerPlot, @answerStatus, @answerNextPlot)
END

-- SELECT ANSWER PLOT
IF @option = 10
BEGIN
	SELECT answerId,answerPlot,answerStatus , nextPlot
	FROM ScriptingAnswerTemplate
	WHERE scriptingId = @scriptingId
END

-- RESET SCRIPTING TABLES (TRUNCATE)
IF @option = 11
BEGIN
	TRUNCATE TABLE ScriptingTemplate
	TRUNCATE TABLE ScriptingTemplateStruct
	TRUNCATE TABLE ScriptingAnswerTemplate
	SELECT 1
END

-- RESET SCRIPTING AGENT CONFIGURATION (TRUNCATE)
IF @option = 12
BEGIN
	TRUNCATE TABLE ScriptingAgentConfiguration
	SELECT 1
END

-- SAVE CURRENT AGENT SCRIPTING WINDOW POSITION & SIZE
IF @option = 13
BEGIN
	IF ( SELECT COUNT(*) FROM ScriptingAgentConfiguration WHERE agentId = @agentId ) = 0
		BEGIN
			-- INSERT
			INSERT INTO ScriptingAgentConfiguration (agentId, windowPosition, windowSize)
			VALUES (@agentId, @agentWindowPosition, @agentWindowSize)
		END
	ELSE
		BEGIN
			UPDATE ScriptingAgentConfiguration
			SET windowPosition = @agentWindowPosition, windowSize = @agentWindowSize
			WHERE agentId=@agentId
		END
	SELECT @agentId
END


-- GET AGENT SCRIPTING CONFIGURATION DATA
IF @option = 14
BEGIN
	IF(@agentId = NULL)
		BEGIN
			SELECT * FROM ScriptingAgentConfiguration
		END
	ELSE
		BEGIN
			SELECT * FROM ScriptingAgentConfiguration WHERE agentId = @agentId
		END
END

-- ADD SCRIPTING-CAMPAIGN RELATIONSHIP
IF @option = 15
BEGIN
	DECLARE @campRelationFlag smallint
	SET @campRelationFlag = (SELECT COUNT(*) FROM ScriptingCampaignRelation WHERE callId = @callId AND callType = @callType)

	IF @campRelationFlag > 0
		BEGIN
			DELETE ScriptingCampaignRelation WHERE callId = @callId AND callType = @callType
		END

	BEGIN
		INSERT INTO ScriptingCampaignRelation (scriptingId, callId, callType)
		VALUES (@scriptingId, @callId, @callType)
	END
	SELECT 1
END


-- DELETE SCRIPTING-CAMPAIGN RELATIONSHIP
IF @option = 16
BEGIN
	DELETE ScriptingCampaignRelation WHERE scriptingId = @scriptingId
	SELECT 1
END


-- UPDATES AN EXISTING SCRIPTING-CAMPAIGN REALTIONSHIP
IF @option = 17
BEGIN
	UPDATE ScriptingCampaignRelation
	SET scriptingId = @scriptingId
	WHERE callId=@callId AND callType = @callType
	SELECT 1
END

-- SELECT ANSWER PLOT
IF @option = 18
BEGIN
	SELECT callType, callId
	FROM ScriptingCampaignRelation
	WHERE scriptingId = @scriptingId
END

-- Check relation ACd|Camp with Scripting
IF @option = 19
BEGIN
	IF EXISTS (SELECT * FROM ScriptingCampaignRelation WHERE callId=@callId and callType=@callType  ) 	
		begin
			SELECT scriptingId as result FROM ScriptingCampaignRelation WHERE callId=@callId and callType=@callType 
		end
	else
		begin
			select -1 as result
		end
END