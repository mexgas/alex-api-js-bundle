/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Guadalupe Colin
Date: 2017/08/10
Description: 
********************************************************************************************

   Se modifican el SPs CRMxUploader


Database: CW_CRMx
Required version: 7

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it

*/

SET NOCOUNT ON

DECLARE @VERSION INT
DECLARE @ACTUALVERSION INT
DECLARE @SQL VARCHAR(MAX)
DECLARE @ERRORGENERATED VARCHAR(MAX)
DECLARE @PROCESS VARCHAR(MAX)

/* VERSION TO RELEASE (USE THE VERSION OF YOUR OWN DATABSE)*/
SET @VERSION = 8

/* ACTUAL VERSION (USE YOUR OWN SCRIPT TO DO IT) */
SET @ACTUALVERSION =  (SELECT VALUE FROM SETTINGS WHERE ID = 1)

IF @ACTUALVERSION in( @VERSION - 1, @VERSION )
  BEGIN
    BEGIN TRAN
    BEGIN TRY

  /* START SCRIPT RELEASE */

    set @process = 'ALTER SP -- CRMxUploader CW-1151'
    set @Sql= 'ALTER PROCEDURE [dbo].[CRMxUploader]
	-- Add the parameters for the stored procedure here
	@option INT,				-- Type of Action/proceess to perform
	@templateId INT = null,       -- Template id
	@dataKeyCollection VARCHAR(MAX) = null, -- Collection of dataKeys. ''datakey1'',''datakey2'',...,''datakeyn''
	@componentIdCollection VARCHAR(MAX) = null, -- Collection of componentId''s. ''textInpu1'', ''texTinput2'',....,''numeric1''
	@isLoading BIT = NULL,
	-- LoadingTemplateRelationships
	@loadTempRelId INT = NULL,
	@loadName NVARCHAR(141) = NULL,
	@loadId INT = NULL,
	@loadType TINYINT = 0,
	@crmxRelation XML = NULL,
	@cwxRelation XML = NULL,
	@isUsingHeaders BIT = NULL,
	@fileNameExcel NVARCHAR(125) = NULL,
	@tableName NVARCHAR(145)=NULL,
	@conString NVARCHAR(100)=NULL

AS

DECLARE @SQL VARCHAR(MAX)
DECLARE @currentDataTemplateTable VARCHAR(100)
DECLARE @searchPattern VARCHAR(MAX)

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Get Record Id by cal_key
	IF @option = 1
	BEGIN
		IF (LEN(@dataKeyCollection) = 0	or @dataKeyCollection IS NULL)
		BEGIN
		  SELECT -1
		END
		ELSE
		BEGIN
			SET @SQL = ''SELECT crmxRecordId, dataKeyValue FROM crmxdata'' + CAST(@templateId AS VARCHAR(100))
			+ '' Where dataKeyValue in ('' + @dataKeyCollection + '')''
			EXEC(@SQL)
		END


	END

	-- Delete by cal_key (bulkdelete)
	IF @option = 2
	BEGIN
		IF ((LEN(@dataKeyCollection) = 0	or @dataKeyCollection IS NULL) and
			(LEN(@componentIdCollection) = 0	or @componentIdCollection IS NULL) )
		BEGIN
		  SELECT -1
		END
		ELSE
		BEGIN
			SET @SQL = ''DELETE FROM crmxRawdata'' + CAST(@templateId AS VARCHAR(100))
			+ '' Where crmxRecordId in (SELECT crmxRecordId FROM crmxData''+ CAST(@TemplateId as VARCHAR(100)) + '' WHERE dataKeyValue IN (''  + @dataKeyCollection + '')) and
				componentId in ('' + @componentIdCollection + '')''
			EXEC(@SQL)
		END
	END


	-- Update CRMxData (set Date)
	IF @option = 3
	BEGIN
		IF (LEN(@dataKeyCollection) = 0	or @dataKeyCollection IS NULL)
		BEGIN
		  SELECT -3
		END
		ELSE
		BEGIN
			SET @SQL = ''Update crmxdata'' + CAST(@templateId AS VARCHAR(100))
			+ '' set dateValue = GETDATE() where dataKeyValue in ('' + @dataKeyCollection + '')''
			exec (@SQL)
		END
	END

IF @option = 4
	BEGIN
		IF(@templateID is NULL or @templateId = 0)
		BEGIN
			SELECT -1
		END
		ELSE
		BEGIN
			SET @SQL = ''SELECT  tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') AS ''''componentId'''', crmxtabsheets.tabSheetIndex as ''''tabSheetIndex'''' FROM crmxtabsheets WITH(NOLOCK)
			CROSS APPLY crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
			WHERE templateid='' + CAST(@templateId AS VARCHAR(100))  + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') IS NOT NULL and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') not in(''+ @componentIdCollection +'')''
			EXEC(@SQL)

		END

  END

IF @option = 5
	BEGIN
		SELECT COUNT([NAME]) FROM SYS.TABLES WHERE [NAME] = ''CRMxData'' + CAST(@templateId AS VARCHAR(100)) or [NAME]= ''CRMxRawData'' + CAST(@templateId AS VARCHAR(100));
	END


/** ***************************************************************************
	LoadingTemplateRelationships
* ****************************************************************************/

/*	CREATE
		Create a new relationship.
*/
IF @option = 6
	BEGIN
		IF @templateID IS NULL
		OR	@loadName IS NULL
		OR	@loadID IS NULL
		OR	@loadType IS NULL
		OR	@crmxRelation IS NULL
		OR	@cwxRelation IS NULL
		--OR  @fileNameExcel IS NULL
		OR  @tableName IS NULL
			BEGIN
				SELECT ''-6 : A parameter is not provided or is null (templateID, loadName, loadID, loadType, crmxRelation, cwxRelation).''
			END
		INSERT INTO LoadingTemplateRelationships (crmxTemplateId, name, lastUsage, loadId, loadType, crmxRelation, cwxRelation, usingHeaders, fileNameExcel,tableName,conString)
		VALUES (@templateID, @loadName, GETDATE(), @loadId, @loadType, @crmxRelation, @cwxRelation, @isUsingHeaders,@fileNameExcel, @tableName,@conString)
	END

/*	READ
		Get all the relationships for a specified template. And orders it by date.
*/
IF @option = 7
	BEGIN
		IF @templateID IS NULL
			BEGIN
				SELECT ''-7 : TemplateID not provided or is null.''
			END
		ELSE
			BEGIN
				SELECT id, crmxTemplateId,name,lastUsage,usingHeaders
				FROM LoadingTemplateRelationships
				WITH(NOLOCK)
				WHERE crmxTemplateId = @templateID
				AND logicDeleted = 0
				ORDER BY lastUsage DESC
			END
	END

/*	UPDATE
		Update a specified loadingTemplateRelationship.
*/
IF @option = 8
	BEGIN
		IF @loadTempRelId = NULL
			BEGIN
				SELECT ''-8 : loadTempRelId not provided or is null''
			END
		ELSE
			BEGIN
				SET @SQL = ''
				UPDATE LoadingTemplateRelationships
				SET lastUsage = GETDATE()''
				IF @loadName IS NOT NULL
					BEGIN
						SET @SQL = @SQL + '', name = '' + '''''''' + CAST(@loadName AS NVARCHAR(141)) + ''''''''
					END
				IF @loadID IS NOT NULL
					BEGIN
						SET @SQL = @SQL + '', loadID = '' + CAST(@loadId AS NVARCHAR(100))
					END
				IF @loadType IS NOT NULL
					BEGIN
						SET @SQL = @SQL + '', loadType = '' + CAST(@loadType AS NVARCHAR(10))
					END
				IF @crmxRelation IS NOT NULL
					BEGIN
						SET @SQL = @SQL + '', crmxRelation = N'' + '''''''' + CAST(@crmxRelation AS NVARCHAR(MAX)) + ''''''''
					END
				IF @cwxRelation IS NOT NULL
					BEGIN
						SET @SQL = @SQL + '', cwxRelation = N'' + '''''''' + CAST(@cwxRelation AS NVARCHAR(MAX)) + ''''''''
					END
				IF @isUsingHeaders IS NOT NULL
					BEGIN
						SET @SQL = @SQL + '', usingHeaders = N'' + '''''''' + CAST(@isUsingHeaders AS NVARCHAR(MAX)) + ''''''''
					END
				 SET @SQL = @SQL + ''
				 WHERE id = '' + CAST(@loadTempRelId AS NVARCHAR(MAX))
				PRINT(@SQL)
				EXEC(@SQL)
			END

	END

/*	DELETE
		Sets a relationship as unreachable
*/
IF @option = 9
	BEGIN
		IF @templateId IS NULL
			BEGIN
				SELECT ''-9 : TemplateID is not provided or null.''
			END
		ELSE
			UPDATE LoadingTemplateRelationships
			SET logicDeleted = 1
			WHERE id = @templateID
	END

 /*  READ
		Select a
 */
 IF @option = 10
	BEGIN
		IF @loadID IS NULL
			BEGIN
				SELECT ''-10 : LoadID is not provided or null.''
			END
		ELSE
			BEGIN
				SELECT *
				FROM LoadingTemplateRelationships
				WITH(NOLOCK)
				WHERE id = @loadID
			END
	END


END

/** ***************************************************************************
	Mich uploader changes
* ****************************************************************************/

IF @option = 11
	BEGIN
		UPDATE CRMxTemplates SET isLoadingData = @isLoading WHERE id = @templateId
	END


-- Delete by cal_key 
IF @option = 12
BEGIN
	IF (LEN(@dataKeyCollection) = 0 or @dataKeyCollection IS NULL) 
	BEGIN
		SELECT -1
	END
	ELSE
	BEGIN
		SET @SQL = ''DELETE FROM crmxRawdata'' + CAST(@templateId AS VARCHAR(100))
		+ '' Where crmxRecordId in (SELECT crmxRecordId FROM crmxData''+ CAST(@TemplateId as VARCHAR(100)) + '' WHERE dataKeyValue IN (''  + @dataKeyCollection + '')) ''
		EXEC(@SQL)
	END
END'
EXEC(@Sql)





  /* END SCRIPT RELEASE */

    /* UPGRADE DATABASE VERSION (USE YOUR OWN SCRIPT TO DO IT) */
    UPDATE SETTINGS SET VALUE = @VERSION WHERE ID = 1

    COMMIT TRAN
    END TRY

    BEGIN CATCH

      /* ERROR GENERATED BASED ON SINTAX */
      SELECT @ERRORGENERATED = 'DB SCRIPT VERSION: ' + CAST(@VERSION AS NVARCHAR) +
      ' ERROR PROCESS: ' + @PROCESS +
      ' LINE: ' + CAST(ERROR_LINE() AS NVARCHAR) +
      ' NUMBER: ' + CAST(@@ERROR AS NVARCHAR) +
      ' MESSAGE: ' + ERROR_MESSAGE()
      RAISERROR(@ERRORGENERATED, 11, 1)

    ROLLBACK TRAN
    END CATCH
  END
ELSE
  BEGIN
    /* ERROR GENERATED BASED ON DATABASE VERSION */
    SELECT 'INCORRECT DATABASE VERSION, ACTUAL VERSION: ' + CAST(@ACTUALVERSION AS VARCHAR(5)) + ', VERSION TO RELEASE: ' + CAST(@VERSION AS VARCHAR(5))
  END

SET NOCOUNT OFF


