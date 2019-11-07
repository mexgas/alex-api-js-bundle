CREATE PROCEDURE [dbo].[saveMyCRMxRecord]  
@crmxRecord XML,  
@crmxCallData varchar(max) = null  
AS  BEGIN  
    
    SET NOCOUNT ON;  
  
    IF @crmxRecord IS NULL  
     SELECT -9991  
  
    DECLARE @templateID INT,  
      @dataTName NVARCHAR(50),  
      @rawDTName NVARCHAR(50),  
      @crmxRecId INT,  
      @sql NVARCHAR(MAX),
	  @parameterDefinition nvarchar(200)
  
    create TABLE #tempTable(  
       tabSheetIndex INT not NULL,  
       componentId VARCHAR(100) NOT NULL,         
       dataValue VARCHAR(2000) Not NULL,
	   primary key( tabSheetIndex, componentId)
    )  
  
    DECLARE @compTable TABLE (
	componentId varchar(100) NOT NULL,
	 primary key( componentId))  
      
    SELECT @templateID = @crmxRecord.value('(/Template/@id)[1]','INT')  
    SELECT @crmxRecID = @crmxRecord.value('(/Template/crmxRecord/@id)[1]','INT')  
  
  
    INSERT @compTable  
     SELECT tabsheet.comp.value('(@id)','varchar(max)') AS 'componentId'  FROM crmxtabsheets WITH(NOLOCK)  
     CROSS APPLY crmxtabsheets.tabsheetxml.nodes('/tabSheet/*')  tabsheet(comp)  
     WHERE templateid = @templateID and tabsheet.comp.value('(@id)','varchar(max)') is not null AND tabsheet.comp.value('(@reportable)', 'varchar(max)') IS NOT NULL       
  
    SET @dataTName = N'CRMxData' + CAST(@templateID AS NVARCHAR(10))  
    SET @rawDTName = N'CRMxRawData' + CAST(@templateID AS NVARCHAR(10))  
  
    -- Pre-save the obtained xml data unto table form  
    INSERT #tempTable  
     SELECT tabSheet.value('@index', 'INT') AS tabSheetIndex,  
        component.value('@id', 'NVARCHAR(100)') AS componentId,  
        component.value('@value', 'NVARCHAR(2000)') AS dataValue  
     FROM  @crmxRecord.nodes('Template/tabSheets/tabSheet') AS TabSheets(tabSheet)  
     OUTER APPLY TabSheets.tabSheet.nodes('node()') AS Components(component)  
     WHERE component.value('@id', 'NVARCHAR(100)') IN (SELECT componentId FROM @compTable)  
  	
	set @parameterDefinition =N'@crmxRecID int,@crmxCallData varchar(max)'
	set @sql='update A set A.dataValue=B.dataValue from [dbo].['+@rawDTName+'] A 
	left join #tempTable B on B.componentId=A.componentId and B.tabSheetIndex=A.tabSheetIndex
	where A.crmxRecordId=@crmxRecId and B.componentId is not null	
	
	insert into ['+@rawDTName+'] 
	select  @crmxRecID as crmxRecordId,A.tabSheetIndex,A.componentId,''none'' as bindingType,A.dataValue
	 from  #tempTable A 
	left join [dbo].['+@rawDTName+']B on B.componentId=A.componentId and B.tabSheetIndex=A.tabSheetIndex and B.crmxRecordId=@crmxRecId
	where B.componentId is null

	UPDATE [' + @dataTName + '] WITH(ROWLOCK) SET [dateValue] = GETDATE(),calldata=@crmxCallData WHERE [crmxRecordId] = @crmxRecId'
          
    EXECUTE sp_executesql  @sql, @parameterDefinition, @crmxRecId=@crmxRecId,@crmxCallData=@crmxCallData
	--print(@sql)
  
	drop table #tempTable
END