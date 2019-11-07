-- =============================================
-- Author:		<Castillo>
-- Create date: <15/APR/2015>
-- Description:	<Handles the agent's last position and size of the displaying template.>
-- =============================================
CREATE PROCEDURE [dbo].[mainAgentsTemplateConfigurationDisplayer]
	-- Add the parameters for the stored procedure here
	@option INT = NULL,
	@templateId INT = NULL,
	@agentId INT = NULL,
	@templatePosition NVARCHAR(50) = NULL,
	@templateSize NVARCHAR(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @version TINYINT,
			@sql NVARCHAR(MAX)
	SET  @version = 1

    -- Returns the current SP version.
	IF @option = 0 OR @option IS NULL
		BEGIN
			SET @SQL = 'mainAgentsTemplateConfigurationDisplayer v' + CAST(@version AS NVARCHAR(10)) + '
			'
			SET @SQL = @SQL +  '	1) ENSURE DATA (templateId, agentId, templatePosition, templateSize) 
			'
			SET @SQL = @SQL +  '	2) UPDATE (templateId, agentId, templatePosition, templateSize)
			'
			SET @SQL = @SQL +  '	3) READ
			'
			SET @SQL = @SQL +  '	4) DELETE
			'
			SET @SQL = @SQL +  '	9990)	RESET'

			PRINT @SQL
		END

	/* CREATE/UPDATE
		
			Ensures the data at a row.
	*/
	IF @option = 1
		BEGIN
			IF	(
					SELECT COUNT(templateId)
					FROM AgentsTemplateConfigurationDisplayer
					WITH(NOLOCK)
					WHERE templateId = @templateID
					AND agentId = @agentId
					--AND templatePosition = @templatePosition
					--AND templateSize = @templateSize
				) = 0
				BEGIN
					INSERT INTO AgentsTemplateConfigurationDisplayer(templateId, agentId, templatePosition, templateSize)
					VALUES (@templateId, @agentId, @templatePosition, @templateSize)
					SELECT '1'
				END
			ELSE
				BEGIN
					SET @sql =  'mainAgentsTemplateConfigurationDisplayer 
							@option = 2, 
							@templateId = ' + CAST(@templateId AS VARCHAR(10)) + ',
							@agentId = ' + CAST(@agentId AS VARCHAR(10)) + ',
							@templatePosition = N' + '''' + @templatePosition + '''' + ',
							@templateSize = N' + '''' + @templateSize + ''''
					EXEC(@sql)
					--PRINT(@sql)
				END
		END

	/*	UPDATE
			
			Updates the row with the provided data.
	*/
	IF @option = 2
		BEGIN
			IF	(
					SELECT COUNT(templateId)
					FROM AgentsTemplateConfigurationDisplayer
					WITH(NOLOCK)
					WHERE templateId = @templateID
					AND agentId = @agentId
				) = 1
				BEGIN
					UPDATE AgentsTemplateConfigurationDisplayer
					WITH(ROWLOCK)
					SET templatePosition = @templatePosition,
						templateSize = @templateSize
					WHERE	templateId = @templateId
						AND agentId = @agentId

					SELECT '2'
				END
			ELSE
				BEGIN
					SELECT '-2'
				END
		END

	/*	READ
		
			Gets the agent's conf data. 
			FULL table, only per TEMPLATE, or AGENT/TEMPLATE			
	*/
	IF @option = 3
		BEGIN
			IF	@agentId IS NOT NULL AND @templateId IS NOT NULL
				BEGIN
					SELECT *
					FROM AgentsTemplateConfigurationDisplayer
					WITH(NOLOCK)
					WHERE agentId = @agentId
					AND	templateId = @templateId
					ORDER BY templateId ASC, agentId ASC
				END
			ELSE
				BEGIN
					IF @templateID IS NOT NULL
						BEGIN
							SELECT *
							FROM AgentsTemplateConfigurationDisplayer
							WITH(NOLOCK)
							WHERE templateId = @templateId
							ORDER BY templateId
						END
					ELSE
						IF @agentID IS NOT NULL
							BEGIN
								SELECT *
								FROM AgentsTemplateConfigurationDisplayer
								WITH(NOLOCK)
								WHERE agentId = @agentId
								ORDER BY agentId
							END
						ELSE
							BEGIN
								SELECT *
								FROM AgentsTemplateConfigurationDisplayer
								WITH(NOLOCK)
								ORDER BY templateId ASC, agentId ASC
							END
				END
		END

	/*	DELETE
		
			Deletes the provided data.
	*/
	IF @option = 4
		BEGIN
			IF @agentId IS NULL AND @templateId IS NULL
				BEGIN
					SELECT '-4'
				END
			ELSE
				BEGIN
					IF	@agentId IS NOT NULL AND @templateId IS NOT NULL
						BEGIN
							DELETE AgentsTemplateConfigurationDisplayer
							WHERE agentId = @agentId
							AND	templateId = @templateId
						END
					ELSE
						BEGIN
							IF @templateID IS NOT NULL
								BEGIN
									DELETE AgentsTemplateConfigurationDisplayer
									WHERE templateId = @templateId
								END
							ELSE
								IF @agentId IS NOT NULL
									BEGIN
										DELETE AgentsTemplateConfigurationDisplayer
										WHERE agentId = @agentId
									END
						END
					
					SELECT '4'
				END
		END





	/*	************
	*	WARNING - RESET
	***************/
	IF @option = 9990
		BEGIN
			TRUNCATE TABLE AgentsTemplateConfigurationDisplayer
		END
END