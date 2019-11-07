CREATE PROCEDURE [dbo].[ccsp_IVRADM]
@option smallint, 
@idScript smallint = NULL, 
@name varchar(40) = NULL,  
@dnis varchar(400) = NULL, 
@blockId smallint = NULL,  
@blockType tinyint = NULL,  
@blockLabel varchar(40) = NULL, 
@variablesStruct varchar (MAX) = NULL, 
@retCodeStruct varchar (MAX) = NULL,
@storeProcedureName varchar (MAX) = NULL,
@storeProcedureParams varchar (MAX) = NULL,
@audioFile varchar(40) = NULL, 
@audioDescription varchar(40) = NULL

AS
-- INTERNAL VARS
DECLARE @newIdTemplate smallint
SET @newIdTemplate = 0
DECLARE @newAudioIdTemplate smallint
SET @newAudioIdTemplate = 0


----------------------
---- CASE OPTIONS


-- DO NOTHING
IF @option = 1
	BEGIN	
		SELECT 1
	END


-- INSERT A NEW TEMPLATE
IF @option = 2 
BEGIN
	IF EXISTS (SELECT * FROM IVRTemplate WHERE name = @name  ) 	
		BEGIN
			SELECT -1 --'The IVR template name is already in use.'
		END
	ELSE
		BEGIN
			INSERT INTO IVRTemplate(name, dnis) VALUES (@name, @dnis)			
			SELECT @newIdTemplate = scope_identity()						
			SELECT @newIdTemplate
		END
END


-- UPDATE AN IVRTEMPLATE
IF @option = 3 
BEGIN
	IF NOT EXISTS (SELECT * FROM IVRTemplate WHERE idScript = @idScript  ) 	
		BEGIN
			SELECT -1 --'The ivr  does not exists'
		END
	ELSE
		BEGIN
			UPDATE IVRTemplate SET name = @name, dnis = @dnis WHERE idScript=@idScript
		END
	SELECT @idScript
END


IF @option = 4 
BEGIN 
    BEGIN TRAN
    BEGIN TRY
           DELETE FROM IVRTemplate WHERE idScript=@idScript 
           DELETE FROM IVRTemplateStruct WHERE idScript = @idScript
           SELECT @idScript
           COMMIT TRAN
    END TRY
    BEGIN CATCH
           select -1  
           ROLLBACK TRAN
    END CATCH
END



-- SELECT ALL IVR TEMPLATES
IF @option = 5
BEGIN
	SELECT idScript, name, dnis FROM IVRTemplate 
END


-- INSERT A NEW BLOCK
IF @option = 6 
BEGIN
	INSERT INTO IVRTemplateStruct (idScript, idBlock, TypeBlock, LabelBlock, VariablesBlock, RetCodeBlock)
	VALUES (@idScript, @blockId, @blockType, ISNULL(@blockLabel, ''), @variablesStruct, @retCodeStruct)
END

-- SELECT ALL BLOCKS
IF @option = 7
BEGIN
	SELECT idBlock, TypeBlock, LabelBlock, VariablesBlock, RetCodeBlock
	FROM IVRTemplateStruct
	WHERE idScript = @idScript
END


-- DELETE ALL BLOCKS (IVR STRUCT) OF IVR ID PROVIDED
IF @option = 8
BEGIN
	DELETE IVRTemplateStruct WHERE idScript = @idScript
END


--------------------------------
--------------------------------
--- STORE PROCEDURE VERIFICATION

-- CHECK IF EXISTS STORE PROCEDURE
IF @option = 9
BEGIN
	IF OBJECT_ID (@storeProcedureName) is NULL
		BEGIN
			SELECT 0 -- 'There is not even a single object with the provided id'
		END
	ELSE
		BEGIN
			IF OBJECTPROPERTY(OBJECT_ID (@storeProcedureName), 'isProcedure') = 1
				BEGIN
					SELECT 1 -- 'The supposed store, actually is.'
				END
			ELSE IF OBJECTPROPERTY(OBJECT_ID (@storeProcedureName), 'isExtenerProc') = 2
				BEGIN
					SELECT 2 -- 'The supposed store is an Extended Procedure'
				END
			ELSE 
				BEGIN
					SELECT 3 -- 'The supposed store, is not a store and is a non-null object; it 's something else.
				END
		END
END


-- CHECK CURRENT PARAMETERS OF THE STORE PROCEDURE
IF @option = 10
BEGIN
	SELECT SCHEMA_NAME(SCHEMA_ID) AS [Schema], 
			SO.name AS [ObjectName],
			SO.Type_Desc AS [ObjectType (UDF/SP)],
			P.parameter_id AS [ParameterID],
			P.name AS [ParameterName],
			TYPE_NAME(P.user_type_id) AS [ParameterDataType],
			P.max_length AS [ParameterMaxBytes],
			P.is_output AS [IsOutPutParameter],
			P.has_default_value AS [IsRequired],
			P.default_value AS [DefValue]
	FROM sys.objects AS SO
	INNER JOIN sys.parameters AS P 
	ON SO.OBJECT_ID = P.OBJECT_ID
	WHERE SO.OBJECT_ID  = object_id(@storeProcedureName)
	ORDER BY [Schema], SO.name, P.parameter_id
END


-- TRIES THE STORE PROCEDURE WITH ITS PARAMETERS
IF @option = 11
BEGIN
	BEGIN TRAN
	BEGIN TRY
		   EXEC @storeProcedureName @storeProcedureParams
		   SELECT 1 
		   COMMIT TRAN
	END TRY
	BEGIN CATCH
		   SELECT -1 
		   ROLLBACK TRAN
	END CATCH
END


-- SELECT ALL AUDIOS FOR IVR TEMPLATES
IF @option = 12
BEGIN
	SELECT ivrAudioId,audioFile,description FROM IVRTemplateAudio
END

-- DELETE AUDIO FOR IVR TEMPLATES
IF @option = 13
BEGIN
    BEGIN TRAN
    BEGIN TRY
           DELETE FROM IVRTemplateAudio WHERE ivrAudioId = @idScript 
           SELECT @idScript
           COMMIT TRAN
    END TRY
    BEGIN CATCH
           select -1  
           ROLLBACK TRAN
    END CATCH
END



-- INSERT AUDIO FOR IVR TEMPLATES
IF @option = 14
BEGIN
	insert into IVRTemplateAudio values (@audioFile,@audioDescription)
	SELECT @newAudioIdTemplate = scope_identity()							
	SELECT @newAudioIdTemplate
END

IF @option = 15
BEGIN
	IF ( select count(*) from ccDnis) = 0
			begin	
				select -1 --'No hay 
			end
	 ELSE
			begin
				select dni_id, dni_numero, dni_descripcion, cast(dni_isBlock as tinyint) dni_isBlock 
				from ccDnis where dni_Status=1  order by 2
				--and dni_id not in(select dni_id from ccInboundDnis)
		--return(0)
			end
END