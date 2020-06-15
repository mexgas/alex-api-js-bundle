SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 84

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

		SET @process = 'CW-3370 Alter SP_ccspRepOutDialDetail '
		SET @sql = 'ALTER PROCEDURE [dbo].[ccspRepOutDialDetail] 
@action AS TINYINT, 
@from AS   DATETIME = NULL, 
@to AS     DATETIME = NULL
AS
IF @from IS NULL
    SELECT @from =CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE())) - 15
if @to is null
SELECT @to = GETDATE()

IF @action = 1
    BEGIN  
        --Borrar lo que esta para no repetir  
        DELETE FROM RepOutDialDetail WITH(ROWLOCK)
        WHERE date >= @from
            AND date < @to
        DECLARE @country SMALLINT
        SELECT @country = valor
        FROM ccSettings
        WHERE setting_id = 104

        --Inserta informacon de reporte  
        INSERT INTO RepOutDialDetail
            SELECT fecha, 
                    ISNULL(ISNULL(dials.cal_key, cs.cal_key), '''') cal_key, 
                    telefono, 
                    dials.tiporesdial_id,
					CASE 
						WHEN dials.tipoResDial_id = 14
						THEN ''systemTranslated_CancelledBySystem''
						ELSE ISNULL(descripcion, '''')
					END AS resultado,
                    dials.[cam_id], 
                    ISNULL(RTRIM(LTRIM(camps.cam_descripcion)), ''systemTranslated_NoCampaign'') AS campa, 
                    dials.tbusy AS Msgtime, 
                    DATEPART(yyyy, fecha), 
                    DATEPART(mm, fecha), 
                    DATEPART(dd, fecha), 
                    DATEPART(hh, fecha), 
                    DATEPART(mi, fecha), 
                    ISNULL(rl.name, ''''),
                    CASE
                        WHEN answerbit = 1
                        THEN ''systemTranslated_Charged''
                        ELSE ''systemTranslated_NotCharged''
                    END AS billed, 
                    ISNULL(cs.Dato1, '''') AS data1, 
                    ISNULL(cs.Dato2, '''') AS data2, 
                    ISNULL(cs.Dato3, '''') AS data3, 
                    ISNULL(cs.Dato4, '''') AS data4, 
                    ISNULL(cs.Dato5, '''') AS data5,
                    CASE
                        WHEN dials.[file_moved] = 1
                        THEN ''systemTranslated_Remoto''
                        ELSE ''Local''
                    END AS file_Moved, 
                    dials.disconnectCause, 
                    COALESCE(dat.description, descripcion, ''N/A'') DCCustomer, 
                    dials.dialType,
                    CASE
                        WHEN @country = 1
                        THEN ISNULL(
            (
                SELECT CASE
                            WHEN dials.tipoLlamada_id IN(1, 2, 5)
                            THEN ''systemTranslated_fijo''
                            WHEN dials.tipoLlamada_id IN(3, 4)
                            THEN ''systemTranslated_cellPhone''
                            ELSE ''systemTranslated_Indefinite''
                        END
            ), ''systemTranslated_Indefinite'')
                        ELSE ''''
                    END AS TipoTel, 
                    ISNULL(CallDisposition, ''N/A'') AS CallDisposition, 
                    ISNULL(califSubDesc, ''N/A'') AS CallSubDisposition
            FROM
            (
                SELECT dial.logDial_id, 
                        dial.callout_id, 
                        dial.cam_id, 
                        CASE
							WHEN dial.canceledNoAgents = 1
							THEN 14
							ELSE dial.tipoResDial_id
						END AS tipoResDial_id,
                        dial.Telefono, 
                        dial.Puerto, 
                        dial.fecha, 
                        dial.tDialing,
                        CASE
                            WHEN LEFT(dial.TipoDialingMode, 1) = ''1''
                            THEN ''Preview''
                            ELSE CASE
                                    WHEN RIGHT(dial.TipoDialingMode, 2) = ''00''
                                    THEN ''systemTranslated_Auto''
                                    WHEN RIGHT(dial.TipoDialingMode, 2) IN(''10'', ''01'')
                                    THEN ''systemTranslated_Manual''
                                END
                        END AS dialType,
                        dial.tBusy, 
                        dial.answerbit, 
                        dial.canceledNoAgents, 
                        dial.cal_id, 
                        dial.disconnectCause, 
                        co.cal_key, 
                        co.file_moved, 
                        dial.tipoLlamada_id, 
                        tco.Description AS CallDisposition, 
                        tsco.califSubDesc
                FROM ccoLogDials dial(NOLOCK)
                        LEFT JOIN ccocallsout co(NOLOCK) ON dial.cal_id = co.cal_id
                        LEFT JOIN cctipocalifout tco WITH(NOLOCK) ON tco.calif_id = co.calif_id
                        LEFT JOIN cctipocalifsubout tsco WITH(NOLOCK) ON tsco.califSub_id = co.califSub_id
                WHERE fecha >= @from
                        AND fecha < @to
            ) dials
            LEFT JOIN ccoCallsOutSource cs(NOLOCK) ON dials.callout_id = cs.callout_id
            LEFT JOIN cctipoResultadoDial tr ON dials.tiporesdial_id = tr.tiporesdial_id
            LEFT JOIN ccCamps camps ON camps.[cam_id] = dials.[cam_id]
            LEFT JOIN ccRIARegistryLists rl ON cs.list_id = rl.list_id
            LEFT JOIN DC_Extra dat ON(dat.id = CASE
                                                    WHEN ISNUMERIC(SUBSTRING(dials.disconnectCause, 21, 3)) = 0
                                                    THEN ''''
                                                    ELSE SUBSTRING(dials.disconnectCause, 21, 3)
                                                END)
            WHERE fecha >= @from
                    AND fecha < @to
            ORDER BY fecha
END'
		EXEC(@sql)

		SET @process = 'CW-3370 update TranslatedReports '
		SET @sql = 'update TranslatedReports set columns=''campaign|billed|fileMoved|dialType|TipoTel|dialResult'' where id=4010'
		EXEC(@sql)

		SET @process = 'CW-3370 Alter table RepOutDialDetail '
		SET @sql = 'alter table RepOutDialDetail alter column dialResult varchar(50)'
		EXEC(@sql)

		
		IF @actualVersion = @version - 1
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
