/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/08/18
Description: DEV1-306

Database: CCReportsRIA
Required version: 128

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
SET @version = 138 --**********actualizar a 124 sin fix

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY
-------------------------------------------------------------------BEGIN ULISES -----------------------------------------------------------------------------
	set @process = 'CW-8658 columnas faltantes'
	set @sql = '-- Verificar si la columna estado_funcional existe
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = ''RepSMSDayReportBySegments'' 
    AND COLUMN_NAME = ''estado_funcional''
)
BEGIN
    -- Agregar la columna estado_funcional con un valor por defecto
    ALTER TABLE RepSMSDayReportBySegments
    ADD estado_funcional VARCHAR(100) NOT NULL DEFAULT '''';
END;

-- Verificar si la columna corte_real existe
IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = ''RepSMSDayReportBySegments'' 
    AND COLUMN_NAME = ''corte_real''
)
BEGIN
    -- Agregar la columna corte_real con un valor por defecto
    ALTER TABLE RepSMSDayReportBySegments
    ADD corte_real VARCHAR(20) NOT NULL DEFAULT '''';
END;'
	EXEC(@sql)

	set @process = 'CW-8658 columnas faltantes'
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccspRepSMSDayReportBySegments'')
    begin
        DROP PROCEDURE ccspRepSMSDayReportBySegments;
    end
	'
	EXEC(@sql)

	set @process = 'CW-8658 columnas faltantes'
	set @sql = 'CREATE PROCEDURE [dbo].[ccspRepSMSDayReportBySegments]
	@action AS TINYINT = 1, 
	@from AS DATETIME = null,  
	@to AS DATETIME = null
AS
--declare
--	@action AS TINYINT = 1, 
--	@from AS DATETIME = ''2023-04-01'', 
--	@to AS DATETIME = getdate()
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

if(@to = convert(datetime,convert(varchar(11),getdate(),121)+''03:00:00'',121)) AND @from = DATEADD(dd,-1,@to)
BEGIN	
	select @from = convert(datetime,convert(varchar(11),@from))
END

IF @action = 1
BEGIN

	DELETE FROM RepSMSDayReportBySegments WHERE fecha_foto between @from AND @to;
	--select * from smsccoLogDial

	;with SMSBySegments as(
	select ROW_NUMBER() OVER (PARTITION BY srm.id_credito ORDER BY a.phone) rownumber,
			srm.id_credito,
			srm.credito credito,
			convert(date,a.smsDate,121) as fecha_foto,
			srm.MESES_VENCIDOS,
			srm.SEG_CUENTA,
			srm.FILA,
			srm.LOCACION,
			srm.DIA_CORTE,
			ss.segmentId,
			srm.SegmentoMC,
			(DATEPART(WEEK, DATEADD(DAY, -1, a.smsDate)) - DATEPART(WEEK, DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, a.smsDate), 0))) + 1) AS Semana,
			DATEPART(DW, GETDATE()) AS DiaSemana,
			srm.ESTADO_FUNCIONAL,
			srm.CORTE_REAL,
			a.phone as Phone,
			''systemTranslated_Resultado_ID_'' + cast(srm.RESULTADO_ID as varchar)  resultado,
			''systemTranslated_Resultado_Envio_'' + cast(a.statusSystemsId as varchar)  resultado_de_envio		
	from smsccoLogDial a
	--inner join SmsRemesasMuñozDay srm on srm.TDCT = a.callkey
	inner join SmsRemesasMuñozDay srm on srm.TDCT = a.registryClient
	inner join ccSmsSegments ss on ss.name = srm.SegmentoMC
	where a.smsDate between @from and @to
	)
	
	Insert into RepSMSDayReportBySegments
	select
		id_credito,
		credito,
		fecha_foto,
	max(MESES_VENCIDOS) meses_vencidos,
	max(SEG_CUENTA) seg_cuenta,
	max(FILA) fila,
	max(LOCACION) locacion,
	max(DIA_CORTE) dia_corte,
	max(segmentId) as SegmentId,
	max(SegmentoMC) segmentoMC,
	max(Semana) as semana,
	max(DiaSemana) as dia_semana,
	max(case when rownumber=1 then Phone else '''' end) telefonos1 ,
	max(case when rownumber=1 then resultado else '''' end) resultado1 ,
	max(case when rownumber=1 then resultado_de_envio else '''' end) resultado_de_envio1 ,
	max(case when rownumber=2 then Phone else '''' end) telefonos2 ,
	max(case when rownumber=2 then resultado else '''' end) resultado2 ,
	max(case when rownumber=2 then resultado_de_envio else '''' end) resultado_de_envio2 ,
	max(case when rownumber=3 then Phone else '''' end) telefonos3 ,
	max(case when rownumber=3 then resultado else '''' end) resultado3 ,
	max(case when rownumber=3 then resultado_de_envio else '''' end) resultado_de_envio3 ,
	max(case when rownumber=4 then Phone else '''' end) telefonos4 ,
	max(case when rownumber=4 then resultado else '''' end) resultado4 ,
	max(case when rownumber=4 then resultado_de_envio else '''' end) resultado_de_envio4 ,
	max(case when rownumber=5 then Phone else '''' end) telefonos5 ,
	max(case when rownumber=5 then resultado else '''' end) resultado5 ,
	max(case when rownumber=5 then resultado_de_envio else '''' end) resultado_de_envio5 ,
	max(case when rownumber=6 then Phone else '''' end) telefonos6 ,
	max(case when rownumber=6 then resultado else '''' end) resultado6 ,
	max(case when rownumber=6 then resultado_de_envio else '''' end) resultado_de_envio6 ,
	max(case when rownumber=7 then Phone else '''' end) telefonos7 ,
	max(case when rownumber=7 then resultado else '''' end) resultado7 ,
	max(case when rownumber=7 then resultado_de_envio else '''' end) resultado_de_envio7 ,
	max(case when rownumber=8 then Phone else '''' end) telefonos8 ,
	max(case when rownumber=8 then resultado else '''' end) resultado8 ,
	max(case when rownumber=8 then resultado_de_envio else '''' end) resultado_de_envio8 ,
	max(case when rownumber=9 then Phone else '''' end) telefonos9 ,
	max(case when rownumber=9 then resultado else '''' end) resultado9 ,
	max(case when rownumber=9 then resultado_de_envio else '''' end) resultado_de_envio9 ,
	max(case when rownumber=10 then Phone else '''' end) telefonos10 ,
	max(case when rownumber=10 then resultado else '''' end) resultado10 ,
	max(case when rownumber=10 then resultado_de_envio else '''' end) resultado_de_envio10,
	max(ESTADO_FUNCIONAL) estado_funcional,
	max(CORTE_REAL) corte_real
	from SMSBySegments
	group by id_credito,fecha_foto,credito
END'
	EXEC(@sql)
	
-------------------------------------------------------------------END ULISES -----------------------------------------------------------------------------
	
	------------------------------END Frida
	IF @actualVersion = @version - 1 EXEC ccsp_getVersion 'BD', @version

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
