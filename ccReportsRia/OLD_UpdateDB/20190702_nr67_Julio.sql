/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: Jesus Gallardo
Date: 2019/04/02
Description: CW-2945


Database: ccReportsRia
Required version: 65


IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 67

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
	
	SET @process = 'DISABLE TRIGGER MSmerge_tr_altertable'
	SET @Sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE [name] = N''MSmerge_tr_altertable'' AND type in (N''TR'') AND is_disabled = 0)
	BEGIN
	DISABLE TRIGGER MSmerge_tr_altertable ON DATABASE
	END'

	EXEC (@Sql)
	
		SET @process = 'CW-1386 Add Column ccoLogDials.TipoDialingMode'
		SET @sql = 'if not exists (select * from sys.columns where name = N''TipoDialingMode'' and Object_ID = Object_ID(N''ccoLogDials''))
    begin
        ALTER TABLE ccoLogDials  ADD TipoDialingMode Varchar(8)  NULL 
    end
'
		EXEC (@sql)
	
	SET @process = 'ENABLE TRIGGER MSmerge_tr_altertable'
		SET @Sql = 'IF EXISTS (SELECT * FROM sys.triggers WHERE [name] = N''MSmerge_tr_altertable'' AND type in (N''TR'') AND is_disabled = 1)
	BEGIN 
		ENABLE TRIGGER MSmerge_tr_altertable ON DATABASE
	END'

		EXEC (@Sql)
	
	
		SET @process = 'CW-1386 Add Column RepOutDialDetail.dialType'
		SET @sql = 'if not exists (select * from sys.columns where name = N''dialType'' and Object_ID = Object_ID(N''RepOutDialDetail''))
    begin
        ALTER TABLE RepOutDialDetail  ADD dialType Varchar(50)  NULL 
    end
'
		EXEC (@sql)

		SET @process = 'CW-1386 Update TranslatedReports id 4010 '
		SET @sql = 'Update TranslatedReports set [columns]=''campaign|billed|fileMoved|dialType''  where id=4010'
		EXEC (@sql)

		SET @process = 'CW-1386 Alter SP ccspRepOutDialDetail '
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail]  
@action as tinyint,  
@from as datetime = null,  
@to as datetime = null  
AS  
if @from is null  
select @from = convert(datetime,convert(varchar(11),getdate()))  
select @to = getdate()  
if @action = 1  begin  
	--Borrar lo que esta para no repetir  
	delete from RepOutDialDetail with(rowlock)  
	where date >= @from AND date < @to  

	--Inserta informaci?n de reporte  
	insert into RepOutDialDetail  
	SELECT fecha,isnull(isnull(dials.cal_key,cs.cal_key),'''') cal_key, telefono, dials.tiporesdial_id, isnull(descripcion,'''') as resultado, 
	dials.[cam_id],ISNULL(rtrim(ltrim(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') as campa, dials.tbusy as Msgtime,  
	datepart(yyyy,fecha), datepart(mm,fecha), datepart(dd,fecha), datepart(hh,fecha), datepart(mi,fecha), isnull(rl.name,'''')  
	,case when answerbit = 1 then ''systemTranslated_Charged'' else ''systemTranslated_NotCharged'' end as billed, 
	isnull(cs.Dato1,'''') as data1, isnull(cs.Dato2,'''') as data2, isnull(cs.Dato3,'''') as data3, isnull(cs.Dato4,'''') as data4, isnull(cs.Dato5,'''') as data5
	,case when dials.[file_moved] = 1 then ''systemTranslated_Remoto'' else ''Local'' end as file_Moved, dials.disconnectCause, COALESCE(dat.description, descripcion,''N/A'') DCCustomer
	,dials.dialType
	FROM 
	(select dial.logDial_id,dial.callout_id,dial.cam_id,dial.tipoResDial_id,dial.Telefono,dial.Puerto,dial.fecha,dial.tDialing,  
		case when Left(dial.TipoDialingMode,1)=''1'' then ''Preview'' else
			 case when right(dial.TipoDialingMode,2)=''00'' then ''systemTranslated_Auto'' 
			 when right(dial.TipoDialingMode,2) in (''10'',''01'') then ''systemTranslated_Manual'' end end as dialType,
		dial.tBusy,dial.answerbit,dial.canceledNoAgents,dial.cal_id,dial.disconnectCause, co.cal_key, co.file_moved 
		FROM ccoLogDials dial (nolock)
		left join ccocallsout co (nolock) on dial.cal_id=co.cal_id
		WHERE fecha >= @from AND fecha < @to) dials  
	LEFT JOIN ccoCallsOutSource cs (nolock) ON dials.callout_id = cs.callout_id  
	LEFT JOIN cctipoResultadoDial tr ON dials.tiporesdial_id=tr.tiporesdial_id  
	LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]  
	LEFT JOIN ccRIARegistryLists rl ON cs.list_id = rl.list_id 
	LEFT JOIN DC_Extra dat on(dat.id = substring(dials.disconnectCause,21,3))
	WHERE fecha >= @from AND fecha < @to  
	order by fecha  
 end'
		EXEC (@sql)

		


		--IF @actualVersion = @version - 1
			EXEC ccsp_getVersion 'BD', @version

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + ' Error process: ' + @process + ' Line: ' + cast(error_line() AS NVARCHAR) + ' Number: ' + cast(@@error AS NVARCHAR) + ' Message: ' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
ELSE
BEGIN
	/* Error generated based on database version */
	SELECT 'Incorrect database version, actual version: ' + cast(@actualVersion AS VARCHAR(5)) + ', version to release: ' + cast(@version AS VARCHAR(5))
END

SET NOCOUNT OFF
