/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Ernesto Rangel
Date: 2019/10/01
Description: 
********************************************************************************************

   Se modifican el SPs GetCRMInfo


Database: CW_CRMx
Required version: 11

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it

*/

SET NOCOUNT ON

DECLARE @VERSION INT
DECLARE @ACTUALVERSION INT
DECLARE @SQL VARCHAR(MAX)
DECLARE @ERRORGENERATED VARCHAR(MAX)
DECLARE @PROCESS VARCHAR(MAX)

/* VERSION TO RELEASE (USE THE VERSION OF YOUR OWN DATABSE)*/
SET @VERSION = 12

/* ACTUAL VERSION (USE YOUR OWN SCRIPT TO DO IT) */
SET @ACTUALVERSION =  (SELECT VALUE FROM SETTINGS WHERE ID = 1)

IF @ACTUALVERSION in( @VERSION - 1, @VERSION )
  BEGIN
    BEGIN TRAN
    BEGIN TRY

  /* START SCRIPT RELEASE */
    
  
    set @process = 'Alter SP GetCRMInfo' 
	set @Sql= '
ALTER PROCEDURE [dbo].[GetCRMInfo]
			@action tinyint,
			@crmTemplateId nvarchar(100) = null

			AS

			DECLARE @SQL VARCHAR(MAX)
			DECLARE @currentDataTemplateTable VARCHAR(100)

			declare @pivot1_descriptionT nvarchar(max)
			declare @pivot1_descriptionN nvarchar(max)
			declare @query nvarchar(max)


			begin
				if @action = 0 begin -- Get all templates
					select id,name as [description], servicesRelation, ''templateCRMId'' as dbColumn  from CRMxTemplates WITH(NOLOCK) where hasBeenLogicDeleted = 0 and hasSavedData = 1
				end

				if @action = 1 begin -- Get Fields Table
					select tabSheetXML from [CRMxTabSheets] WITH(NOLOCK) where templateId=@crmTemplateId
				end
				if @action = 2 begin -- Get services Relation
					--select * from crmxdata48
					set @query = ''select distinct serviceSource from crmxData'' + @crmTemplateId +'' WITH(NOLOCK)''
					exec(@query)
					--select servicesRelation from [CRMxTemplates] where id=@crmTemplateId
				end

				if @action = 3 begin -- Pivot Info
					begin
					set @query=''declare @pivot1_descriptionT nvarchar(max)
						declare @pivot1_descriptionN nvarchar(max)
						declare @pivot2_descriptionN nvarchar(max)
						declare @query nvarchar(max)
						declare @finalFills varchar(max)
						declare @view_statement nvarchar(10)
						select @pivot1_descriptionN = coalesce(@pivot1_descriptionN + '''','''', '''''''') + ''''isnull(MAX('''' + QuoteName(componentId) + ''''),'''''''''''''''') AS '''' + QuoteName(componentHeader),
						@pivot1_descriptionT = coalesce(@pivot1_descriptionT + '''','''','''''''','''''''''''''''') + QuoteName(componentId),
						@pivot2_descriptionN = coalesce(@pivot2_descriptionN + '''','''', '''''''') + QuoteName(componentHeader)
						from (
						select  tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') as ''''componentId'''',tabsheet.comp.value(''''(@headerLabel)'''',''''varchar(max)'''') as ''''componentHeader'''' from crmxtabsheets WITH(NOLOCK)
						cross apply crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
						where templateid='' + @crmTemplateId + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') is not null AND tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') is not null
						and tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') = ''''true''''
						) T1_descriptionN

						select @finalFills=@pivot1_descriptionN

						select @finalFills = Replace(REPLACE(@finalFills,''''MAX('''',''''''''),''''])'''','''']'''')

						select @finalFills=''''select crmx_Date, crmxSource,crmx_calId,crmx_callKey,crmx_telephone,crmx_duration,crmx_userId,crmx_username,crmx_dispositionId ,crmx_disposition,crmx_subDispositionId,crmx_subDisposition,''''+CHAR(13) + CHAR(10)+ @finalFills+ '''' from(''''


						IF EXISTS(SELECT * FROM sys.views WHERE name = ''''CRMxView''+ @crmTemplateId + '''''')
						BEGIN
							SET @view_statement = ''''ALTER''''
						END
						ELSE
						BEGIN
							SET @view_statement = ''''CREATE''''
						END

						set @query = @view_statement + '''' VIEW CRMxView'' + @crmTemplateId + '' as ''''+ @finalFills+ ''''
						select a.crmxRecordId, a.dateValue AS crmx_Date, a.serviceSource AS crmxSource,
						callData.value(''''''''(/callData/call/@id)[1]'''''''',''''''''varchar(50)'''''''') crmx_calId,
						callData.value(''''''''(/callData/call/@key)[1]'''''''',''''''''varchar(50)'''''''') crmx_callKey,
						callData.value(''''''''(/callData/call/@telephone)[1]'''''''',''''''''varchar(50)'''''''') crmx_telephone,
						callData.value(''''''''(/callData/call/@length)[1]'''''''',''''''''varchar(50)'''''''') crmx_duration,
						callData.value(''''''''(/callData/agent/@id)[1]'''''''',''''''''varchar(50)'''''''') crmx_userId,
						callData.value(''''''''(/callData/agent/@name)[1]'''''''',''''''''varchar(50)'''''''') crmx_username,
						callData.value(''''''''(/callData/disposition/@id)[1]'''''''',''''''''varchar(50)'''''''') crmx_dispositionId,
						callData.value(''''''''(/callData/disposition/@name)[1]'''''''',''''''''varchar(50)'''''''') crmx_disposition,
						callData.value(''''''''(/callData/subdisposition/@id)[1]'''''''',''''''''varchar(50)'''''''') crmx_subDispositionId,
						callData.value(''''''''(/callData/subdisposition/@name)[1]'''''''',''''''''varchar(50)'''''''') crmx_subDisposition, 
						B.dataValue, B.componentId
						from CRMxData'' + @crmTemplateId + '' as A 
						inner join CRMxRawData'' + @crmTemplateId + '' B WITH(NOLOCK) on A.crmxRecordId=B.crmxRecordId
						where A.callData is not null and 
						B.componentId  IN(''''+ REPLACE( REPLACE(@pivot1_descriptionT,''''['''',''''''''''''''''),'''']'''','''''''''''''''')+'''')

						

						) as SourceTable
						pivot(
						MAX(dataValue)
						FOR componentId IN(''''+@pivot1_descriptionT+'''')
						)as PivoTable''''

						EXEC( @query )''

						IF(SELECT hasSavedData FROM crmxtemplates WHERE id = @crmTemplateId) = 1
						BEGIN
							EXEC( @query)
						END
					END

				END

				if @action = 4 begin -- Creating Views unused
					begin
					set @query=''
						IF EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N''''RepCRMXView''+ @crmTemplateId + '''''') AND type = (N''''U'''')) DROP TABLE RepCRMXView'' + @crmTemplateId
						exec ( @query)
						set @query=''
							   create table RepCRMXView'' + @crmTemplateId +''(date datetime,Source varchar(10))   ''

							   -- Create indexes

						exec ( @query)
					end

				end
				if @action = 5 begin -- get headers
					select templateid as templateId,tabsheetindex as tabSheetIndex,tabsheet.comp.value(''(@headerLabel)'',''varchar(max)'') as ''header'', ''data'' + tabsheet.comp.value(''(@headerIndex)'',''varchar(max)'') as ''dataColumn''  from crmxtabsheets
					cross apply crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)
					where templateid=@crmTemplateId and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') is not null
					and tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') = ''true''


					--select tabSheetIndex, header,dataColumn from RepCRMxHeaders where templateId = @crmTemplateId;
				end
				if @action = 6 begin -- get Number of values
					select count(templateid) from crmxtabsheets WITH(NOLOCK)
					cross apply crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)
					where templateid=@crmTemplateId and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') is not null
					and tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') = ''true''

				end
				if @action = 7 begin --Get Components for graphs
					select templateid as templateId,tabsheetindex as tabSheetIndex, tabsheet.comp.value(''local-name(.)[1]'', ''VARCHAR(MAX)'') AS ParentNodeName,tabsheet.comp.value(''(@headerLabel)'',''varchar(max)'') as ''header'', ''data'' + tabsheet.comp.value(''(@headerIndex)'',''varchar(max)'') as ''dataColumn''  from crmxtabsheets WITH(NOLOCK)
					CROSS APPLY crmxtabsheets.tabsheetxml.nodes(''/tabSheet/*'')  tabsheet(comp)
					where templateid = @crmTemplateId and tabsheet.comp.value(''(@id)'',''varchar(max)'') is not null AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') is not null
					AND tabsheet.comp.value(''(@reportable)'', ''varchar(max)'') = ''true''
					AND (tabsheet.comp.value(''local-name(.)[1]'', ''VARCHAR(MAX)'')= ''ComboBox'' OR tabsheet.comp.value(''local-name(.)[1]'', ''VARCHAR(MAX)'')= ''checkBoxGroup'' OR tabsheet.comp.value(''local-name(.)[1]'', ''VARCHAR(MAX)'')= ''radioButtonGroup'')
			 end
			 if @action=8
			 begin
			 set @query=''declare @pivot1_descriptionT nvarchar(max)
						declare @pivot1_descriptionN nvarchar(max)
						declare @query nvarchar(max)
						declare @view_statement nvarchar(10)
						select @pivot1_descriptionN = coalesce(@pivot1_descriptionN + '''','''', '''''''') + ''''isnull(MAX('''' + QuoteName(componentId) + ''''),'''''''''''''''') AS '''' + QuoteName(componentHeader)
						from (
						select  tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') as ''''componentId'''',tabsheet.comp.value(''''(@headerLabel)'''',''''varchar(max)'''') as ''''componentHeader'''' from crmxtabsheets WITH(NOLOCK)
						cross apply crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
						where templateid='' + @crmTemplateId + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') is not null  AND tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') is not null) T1_descriptionN


						select @pivot1_descriptionT = coalesce(@pivot1_descriptionT + '''','''','''''''','''''''''''''''') + QuoteName(componentId)
						from  (select  tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') as ''''componentId'''',tabsheet.comp.value(''''(@headerLabel)'''',''''varchar(max)'''') as ''''componentHeader'''' from crmxtabsheets WITH(NOLOCK)
						cross apply crmxtabsheets.tabsheetxml.nodes(''''/tabSheet/*'''')  tabsheet(comp)
						where templateid='' + @crmTemplateId + '' and tabsheet.comp.value(''''(@id)'''',''''varchar(max)'''') is not null AND tabsheet.comp.value(''''(@reportable)'''', ''''varchar(max)'''') is not null
						) T1_descriptionT

						IF EXISTS(SELECT * FROM sys.views WHERE name = ''''CRMxRawView''+ @crmTemplateId + '''''')
						BEGIN
							SET @view_statement = ''''ALTER''''
						END
						ELSE
						BEGIN
							SET @view_statement = ''''CREATE''''
						END


						set @query = @view_statement + '''' VIEW CRMxRawView'' + @crmTemplateId + '' as select a.crmxRecordId as crmxRecordId ,  '''' + @pivot1_descriptionN + ''''
						from (select crmxRecordId as RowID,dataValue,componentId from CRMxRawData'' + @crmTemplateId + '' WITH(NOLOCK)) as P
						pivot (max(dataValue) for componentId in ('''' + @pivot1_descriptionT + ''''))  as PV_descriptionT, CRMxData'' + @crmTemplateId + '' a
						where a.crmxRecordId = RowID
						group by [RowID], a.serviceSource, a.crmxRecordId''''

						exec( @query )''
						IF(SELECT hasSavedData FROM crmxtemplates WHERE id = @crmTemplateId) = 1
						BEGIN
							EXEC( @query)
						END
			 end

			end'
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


