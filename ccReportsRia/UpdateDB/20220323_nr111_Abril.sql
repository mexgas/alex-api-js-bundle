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
	set @process = 'CW-5608 drop procedure ccspRepAVRSDetailChat'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspRepAVRSDetailChat'')
            begin
          DROP PROCEDURE ccspRepAVRSDetailChat;
            end'
	EXEC(@sql)
	set @process = 'CW-5608 create procedure ccspRepAVRSDetailChat'
	set @sql = '
	CREATE PROCEDURE  [dbo].[ccspRepAVRSDetailChat]
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
	DELETE FROM dbo.RepAVRSDetailChat with(rowlock)
	where date >= @from AND date < @to

	INSERT INTO dbo.RepAVRSDetailChat

		select
		DATEADD(dd, 0, f.fecha_calif) AS fecha,
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
END'
	EXEC(@sql)
	set @process = 'CW-5611 add column to RepAvgAnswerTimeChats'
	set @sql = '
	 if not exists (select * from sys.columns where name = N''chatId'' and Object_ID = Object_ID(N''RepAvgAnswerTimeChats''))
    begin
        alter table RepAvgAnswerTimeChats add chatId int default 0 not null
    end'
	EXEC(@sql)
	set @process = 'CW-5611 drop procedure ccspRepAvgAnswerTimeChats'
	set @sql = '
	CREATE PROCEDURE [dbo].[ccspRepAvgAnswerTimeChats]
@action as tinyint,
@from as datetime = null,
@to as datetime = null
AS

if @from is null
	select @from = convert(datetime,convert(varchar(11),getdate()))
if @to is null
	select @to = getdate()

if @action = 1
begin
	delete RepAvgAnswerTimeChats where date >= @from and date < @to

	insert into RepAvgAnswerTimeChats
	select 
	CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121) as [date], userId, [Login], inboundId, [inbound],
	[user], 
	 convert(decimal(10,2),isnull( sum([answerTime])/count(*),0.00)) as [avgAnswerTime]		
	, datepart(yyyy,CONVERT(smalldatetime,date))
	, datepart(mm,CONVERT(smalldatetime,date))
	, datepart(dd,CONVERT(smalldatetime,date))
	, datepart(hh,CONVERT(smalldatetime,date))
	, datepart(mi,CONVERT(smalldatetime,date))
	, chatId
	from(
	select requestDate as [date], userId, [Login] as [login], 
	inboundId, c.descripcion as [inbound], nombres + '' '' + apellidopaterno + '' '' + apellidomaterno as [user],
	case when firstMessageTime is null then convert(int,isnull(firstMessageTime,0)) 
	else datediff(ss,chatdate,firstMessageTime) end as [answerTime], a.chatId as [chatId]
	from ccriachats a
	left join ccUserView b on (a.userId = b.user_id)
	left join ccinbound c on (a.inboundId = c.inbound_id)
	where b.user_id is not null
	and c.inbound_id is not null
	and a.chatstatus = 4) as answerTime
	group by CONVERT(smalldatetime,CONVERT(varchar(13),date,121)+ '':00'',121), userId, [Login], inboundId, [inbound], [user], [chatId]

end'
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
