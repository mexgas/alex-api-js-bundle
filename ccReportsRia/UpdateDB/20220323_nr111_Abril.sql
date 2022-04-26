SET NOCOUNT ON

DECLARE @version INT
DECLARE @actualVersion INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)

/* Version to release (use the version of your own databse)*/
SET @version = 111

/* Actual version (use your own script to do it) */
EXEC @actualVersion = ccsp_getVersion 'BD'

IF @actualVersion IN (@version, @version - 1)
BEGIN
	BEGIN TRAN

	BEGIN TRY

	set @process = 'CW-5608 add column to RepAVRSDetailChat'
	set @sql = 'if not exists (select * from sys.columns where name = N''chatId'' and Object_ID = Object_ID(N''RepAVRSDetailChat''))
    begin
        alter table RepAVRSDetailChat add chatId int default 0 not null
    end'
	EXEC(@sql)

	set @process = 'CW-5611 add column to RepAvgAnswerTimeChats'
	set @sql = '
	 if not exists (select * from sys.columns where name = N''chatId'' and Object_ID = Object_ID(N''RepAvgAnswerTimeChats''))
    begin
        alter table RepAvgAnswerTimeChats add chatId int default 0 not null
    end'
	EXEC(@sql)
	
	set @process = 'CW-5608 create procedure ccspRepAVRSDetailChat'
	set @sql = 'ALTER PROCEDURE  [dbo].[ccspRepAVRSDetailChat]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS
set nocount on

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
BEGIN		
	---Before insert delete first table dbo.RepAVRSQuestionDetail 
	DELETE FROM dbo.RepAVRSDetailChat	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSDetailChat

		select
		DATEADD(dd, 0, DATEDIFF(dd, 0, f.fecha_calif)) AS fecha,
		a.User_id,
		a.Login,
		(a.apellidopaterno+'' ''+a.apellidomaterno+'' ''+a.nombres) AS agent, 
		t.id_formato,
		t.nombre,
		p.enunciado_pregunta,
		r.etiquetas,
		r.peso as avgDisposition,
		i.Inbound_id AS inboundId,
		i.descripcion AS inbound,
		c.chatId
	from RIA_RESULTADOSFORMA_CHAT r
	INNER JOIN dbo.RIA_FORMACALIF_CHAT f ON f.id_forma = r.id_forma
	INNER JOIN dbo.ccUserView a ON f.age_id = a.User_id
	INNER JOIN (SELECT id_formato,nombre,MAX(version)AS version
								FROM dbo.RIA_FORMATOS
								WHERE activo = 1 and tipo=2
								GROUP BY id_formato,nombre) as t ON t.id_formato= f.id_formato
	INNER JOIN RIA_PREGUNTAS p ON r.id_pregunta = p.id_pregunta
	INNER JOIN dbo.ccriachats c ON f.id_chat=c.chatId
	INNER JOIN ccinbound AS i ON c.inboundId = i.Inbound_id
	WHERE f.fecha_calif >= @from AND f.fecha_calif < @to
				
set nocount off
END
'
	EXEC(@sql)
	
	set @process = 'CW-5611 ALTER procedure ccspRepAvgAnswerTimeChats'
	set @sql = 'ALTER PROCEDURE [dbo].[ccspRepAvgAnswerTimeChats] @action AS TINYINT, @from AS DATETIME = NULL, @to AS DATETIME = NULL
AS
IF @from IS NULL
	SELECT @from = convert(DATETIME, convert(VARCHAR(11), getdate()))

IF @to IS NULL
	SELECT @to = getdate()

IF @action = 1
BEGIN
	DELETE RepAvgAnswerTimeChats
	WHERE DATE >= @from
		AND DATE < @to;

	WITH answerTime
	AS (
		SELECT CONVERT(SMALLDATETIME, CONVERT(VARCHAR(13), requestDate, 121) + '':00'', 121) AS [date], userId, [Login] AS [login], inboundId, c.descripcion AS [inbound], nombres + '' '' + apellidopaterno + '' '' + apellidomaterno AS 
			[user], CASE 
				WHEN firstMessageTime IS NULL
					THEN convert(INT, isnull(firstMessageTime, 0))
				ELSE datediff(ss, chatdate, firstMessageTime)
				END AS [answerTime], a.chatId AS [chatId]
		FROM ccriachats a
		LEFT JOIN ccUserView b ON (a.userId = b.user_id)
		LEFT JOIN ccinbound c ON (a.inboundId = c.inbound_id)
		WHERE b.user_id IS NOT NULL
			AND c.inbound_id IS NOT NULL
			AND a.chatstatus = 4
			AND requestDate BETWEEN @from
				AND @to
		)
	INSERT INTO RepAvgAnswerTimeChats
	SELECT [date] AS [date], userId, [Login], inboundId, [inbound], [user], convert(DECIMAL(10, 2), isnull(sum([answerTime]) / count(*), 0.00)) AS [avgAnswerTime], datepart(yyyy, [date]), datepart(mm, [date]), datepart(dd
			, [date]), datepart(hh, [date]), 0 AS [minute], chatId
	FROM answerTime
	GROUP BY [date], userId, [Login], inboundId, [inbound], [user], [chatId]
END
'
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
