CREATE PROCEDURE [dbo].[CRMxABCTemplates]
	-- Add the parameters for the stored procedure here
    @option int = 0,

    -- Templates
	@templateId int = NULL,
	@templateName VARCHAR(100) = NULL,
	@templateDescription VARCHAR(MAX) = NULL,
	@isActive bit =NULL,
	@displayData bit =NULL,
	@dataSavingModality varchar(50) =NULL,
	@dataKeyType varchar(50)=null,
	@servicesType varchar(50)=NULL,
	@templateServicesRelation xml= NULL,
	@hasSavedData bit =NULL,
	@hasBeenLogicDeleted bit =NULL,
	--tabSheets
	@tabSheetId int = NULL,
	@tabSheetsXml xml = NULL,
	@xmlCountsId xml = NULL,
	@dataKey VARCHAR(50) = NULL,
	@query nvarchar(max) = NULL

AS
	DECLARE @new_template_id int
	DECLARE @tabSheeter VARCHAR(100)
BEGIN

-- GET ALL templates
IF @option = 2
	IF ( SELECT COUNT(id) FROM CRMxTemplates WITH(NOLOCK) WHERE hasBeenLogicDeleted=0) = 0
		BEGIN
			SELECT -1 --'No hay templates
		END
	ELSE
	  BEGIN
		SELECT * FROM dbo.CRMxTemplates WITH(NOLOCK) WHERE hasBeenLogicDeleted=0
	  END

-- CREATE template
IF @option = 3
	BEGIN
		   INSERT INTO dbo.CRMxTemplates (name, description,isActive,displayData,dataSavingModality,dataKeyType,servicesType,servicesRelation,hasSavedData,hasBeenLogicDeleted)
		   VALUES (@templateName,@templateDescription,@isActive,@displayData,@dataSavingModality,@dataKeyType,@servicesType, @templateServicesRelation,@hasSavedData,@hasBeenLogicDeleted)

			SELECT @new_template_id = scope_identity()
			SELECT @new_template_id
	END

-- UPDATE template
IF @option = 4
	IF not exists( SELECT * FROM dbo.CRMxTemplates WITH(NOLOCK) WHERE id = @templateId) BEGIN
		SELECT -1 --'No existe el template
	END
	ELSE BEGIN		
		UPDATE CRMxTemplates WITH(ROWLOCK) SET name= isnull(@templateName,name),description=ISNULL(@templateDescription,description)
		,isActive=ISNULL(@isActive,isActive)
		,displayData=ISNULL(@displayData,displayData)
		,dataSavingModality=ISNULL(@dataSavingModality,dataSavingModality)
		,dataKeyType=ISNULL(@dataKeyType,dataKeyType)
		,servicesType=ISNULL(@servicesType,servicesType)
		,servicesRelation=ISNULL(@templateServicesRelation,servicesRelation)
		WHERE Id=@templateId

		SELECT 1
END

--	GET tabSheets ordered
 IF @option = 5
	IF not exists( SELECT * FROM CRMxTabSheets WITH(NOLOCK) WHERE templateId = @templateId) BEGIN
		SELECT -1 --'No tiene tabSheets
	END
	ELSE BEGIN
		SELECT CRMxTemplates.id,
		CRMxTemplates.name,
		CRMxTemplates.description,
		CRMxTemplates.isActive,
		CRMxTemplates.displayData,
		CRMxTemplates.dataSavingModality,
		CRMxTemplates.dataKeyType,
		CRMxTemplates.servicesType,
		CRMxTemplates.servicesRelation,
		CRMxTemplates.hasSavedData,
		CRMxTemplates.hasBeenLogicDeleted,
		CRMxTemplates.isLoadingData,
		PropertiesByTemplate.CountIds,
		CRMxTabSheets.tabSheetIndex,
		CRMxTabSheets.tabSheetXml
		FROM CRMxTemplates INNER JOIN CRMxTabSheets ON CRMxTemplates.id=CRMxTabSheets.templateId
		INNER JOIN PropertiesByTemplate ON CRMxTabSheets.templateId=PropertiesByTemplate.idTemplate
		where CRMxTemplates.id=@templateId
		ORDER BY CRMxTabSheets.tabSheetIndex ASC
	  END

-- DELETE template WITH IT'S tabSheets USING id
 IF @option = 6
	IF not exists( SELECT id FROM dbo.CRMxTemplates WITH(NOLOCK) WHERE id = @templateId and hasBeenLogicDeleted = 0) BEGIN
		SELECT -1 --'No existe el template
	END
	ELSE BEGIN
		IF ( SELECT COUNT(id) FROM dbo.CRMxTemplates WITH(NOLOCK) WHERE id = @templateId and hasSavedData = 1) = 1
		BEGIN  -- Tiene datos guardados
			UPDATE  dbo.CRMxTemplates WITH(ROWLOCK) SET hasBeenLogicDeleted = 1 WHERE id = @templateId
			SELECT 1
		END
		ELSE -- No tiene datos, borramos la tabla CRMxData
		BEGIN
				DELETE FROM dbo.CRMxTemplates WHERE id = @templateId
				IF EXISTS( SELECT * FROM sysobjects WHERE name='CRMxData' + CAST(@templateId AS VARCHAR(MAX))  + '')
				BEGIN
					DECLARE @droppableTable AS VARCHAR(MAX)
					SET @droppableTable = 'DROP TABLE [CRMxData' + CAST(@templateId AS VARCHAR(MAX))  + ']'
					EXEC(@droppableTable)
				END
				SELECT 1
		END
	END

-- CREATE a tabSheet
IF @option = 7
	BEGIN
		If exists (select * from CRMxtemplates where id=@templateId)-- and hasSavedData=0)
		BEGIN
			insert into dbo.CRMxTabSheets (templateId, tabSheetIndex,tabSheetXml) VALUES (@templateId,@tabSheetId,@tabSheetsXml)

			IF ( SELECT COUNT(idTemplate) FROM dbo.PropertiesByTemplate WITH(NOLOCK) WHERE idTemplate = @templateId) = 0
			BEGIN
				insert into dbo.PropertiesByTemplate (idTemplate,countIds) VALUES (@templateId,@xmlCountsId)
			END
			ELSE
			BEGIN
				UPDATE PropertiesByTemplate SET countIds=@xmlCountsId WHERE idTemplate=@templateId
			END
		END
	END

-- get hasSavedData By Template
IF @option = 8
 IF ( SELECT COUNT(*) FROM CRMxTemplates WITH(NOLOCK) WHERE id =  @templateId AND hasBeenLogicDeleted=0) = 0
		BEGIN
			SELECT -1
		END
	ELSE
	  BEGIN
		SELECT hasSavedData FROM dbo.CRMxTemplates WHERE id =  @templateId
	  END

 -- DELETE all tabSheets OF 'x' template, se ocupa para la insercin de los tab de una nueva platilla
  IF @option = 9
		BEGIN
			If exists (select * from CRMxtemplates where id=@templateId)-- and hasSavedData=0)
				delete from CRMxTabSheets where templateId=@templateId
		END

-- duplicate template
IF @option = 11
		BEGIN
		-- Insercion en tabla CRMxTemplate
			DECLARE @countCopy varchar(15)

			set @countCopy= (SELECT
				count(id)
				FROM CRMxTemplates WITH(NOLOCK) where name like ( SELECT name FROM CRMxTemplates WITH(NOLOCK) where id=@templateId)+'%'  and hasBeenLogicDeleted<>1)

			set @countCopy='('+@countCopy+')'

			INSERT INTO dbo.CRMxTemplates (
				name,
				description,
				displayData,
				dataSavingModality,
				dataKeyType)
			SELECT
				name+' '+@countCopy,
				description,
				displayData,
				dataSavingModality,
				dataKeyType
				FROM CRMxTemplates WITH(NOLOCK)  where id=@templateId

			SET @new_template_id = scope_identity()

		--- Insercion de tabSheets

			INSERT INTO dbo.CRMxTabSheets (
				templateId,
				tabSheetIndex,
				tabSheetXml
				)
			SELECT
				@new_template_id,
				tabSheetIndex,
				tabSheetXml
				FROM CRMxTabSheets WITH(NOLOCK) where templateId=@templateId

			INSERT INTO dbo.PropertiesByTemplate (idTemplate,countIds)
			SELECT @new_template_id,countIds FROM PropertiesByTemplate WHERE idTemplate=@templateId

			SELECT * FROM crmxTemplates WITH(NOLOCK) WHERE id=@new_template_id

		END
IF @option = 12 -- Delete non existing components*
	BEGIN
		/*
		DECLARE @componentDescription nvarchar(max)

		SELECT @componentDescription = COALESCE(@componentDescription + ',','','') + '''' + componentId + '''' FROM(
		SELECT tabsheet.comp.value('(@id)','varchar(max)') AS 'componentId'  FROM crmxtabsheets WITH(NOLOCK)
		CROSS APPLY crmxtabsheets.tabsheetxml.nodes('/tabSheet/*')  tabsheet(comp)
		WHERE templateid = @templateId and tabsheet.comp.value('(@id)','varchar(max)') is not null AND tabsheet.comp.value('(@reportable)', 'varchar(max)') is not null
		) T1_descriptionT
		*/*/

		--DECLARE @SQL VARCHAR(max)
		If EXISTS (SELECT * FROM CRMxtemplates WHERE id=@templateId AND hasSavedData=1)
		BEGIN
		--	SET @SQL = 'DELETE FROM CRMxRawData' + CONVERT(VARCHAR(MAX), @templateId) + ' WHERE componentId NOT IN (' + @componentDescription + ')'
		--	EXEC(@SQL)
			--Update Views
			EXEC getCRMInfo @action = 3,@crmTemplateId = @templateId
			EXEC getCRMInfo @action = 8,@crmTemplateId = @templateId

		END

	END

--if @option = 12 -- Ensure CRMxView Structure
--	BEGIN
--		declare @nTemplateColumns int
--		declare @nViewColumns int
--		declare @dataColumn int
--		select @nViewColumns =  COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'CRMxView'  and SUBSTRING(COLUMN_NAME,0,5) = 'data'

--		IF NOT EXISTS(select * FROM INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'CRMxView'  and SUBSTRING(COLUMN_NAME,0,5) = 'data')
--			BEGIN
--				set @dataColumn=0
--			END
--		ELSE
--			BEGIN
--				set @dataColumn=@nViewColumns
--		END

--		select @nTemplateColumns = COUNT(templateId)  from crmxtabsheets
--		cross apply crmxtabsheets.tabsheetxml.nodes('/tabSheet/*')  tabsheet(comp)
--		where templateid = @templateId and tabsheet.comp.value('(@id)','varchar(max)') is not null AND tabsheet.comp.value('(@reportable)', 'varchar(max)') is not null
--		and tabsheet.comp.value('(@reportable)', 'varchar(max)') = 'true'
--		WHILE (@nTemplateColumns > @dataColumn)
--			BEGIN
--				set @dataColumn= @dataColumn+ 1
--				set @query='ALTER TABLE CRMxView
--					ADD data' + CAST(@dataColumn as nvarchar(max)) + ' nvarchar(max) NULL' --DEFAULT '''''
--				exec(@query)

--			END
--	END

END