/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K089000

Database: CCenterRia
Required version: 125.37

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 43
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	-----------------------------------------------------BEGIN Rodrigo Salazar -----------------------------------------------------------------
	SET @process = 'KR103000 drop sp ccsp_CreateNodeMultimedia'
	SET @sql = '
		if exists(select * from sys.procedures where name = ''ccsp_CreateNodeMultimedia'')
		begin
			DROP PROCEDURE ccsp_CreateNodeMultimedia
		end'
	EXEC(@sql);

	SET @process = 'KR103000 create sp ccsp_CreateNodeMultimedia'
	SET @sql = '
		CREATE PROCEDURE [dbo].[ccsp_CreateNodeMultimedia] @conversationId BIGINT
							, @supervisor     VARCHAR(255) = ''''
							, @template       VARCHAR(255) = ''''
							, @ScoreTemplate  INT          = 0
							, @type           INT                                                
		AS
		BEGIN

		DECLARE @xml XML, @dateStart DATETIME, @DispXML XML, @SubXML XML;
		DECLARE @info VARCHAR(255);
		DECLARE @infoEscape VARCHAR(MAX);
		DECLARE @disp varchar(255);
		declare @subdisp varchar(255);
		DECLARE @charEscape VARCHAR(255), @charReplace VARCHAR(MAX);
		SET @charEscape = ''"|''''''''|<|>|&'';
		SET @charReplace = ''&quot;|&apos;|&lt;|&gt;|&amp;'';

		DECLARE @existAttached BIT, @numInteracion SMALLINT;
		IF @type = 1
		BEGIN--CHAT

			select @disp = Description from ccRIAChats c left join ccTipoCalif b on c.disposition = b.calif_id where c.chatId = @conversationId
			select @subdisp = califSubDesc from ccRIAChats c left join ccTipoCalifSub b on c.subDisposition = b.califSub_id and c.subdisposition <> 0 where c.chatId = @conversationId 

			SET @DispXML = (
				SELECT ''" C06="'' + @disp         
				FOR XML PATH('''')
			);

			SET @SubXML = (
				SELECT ''" C07="'' + @subdisp         
				FOR XML PATH('''')
			);

			SELECT @xml = CONVERT(XML, ''<R01 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126))) 
				+ ''" CID="'' + CONVERT(VARCHAR(MAX), ccRIAChats.inboundid) 
			+ ''" CType="1'' 
			+ ''" C01="'' + CONVERT(VARCHAR(MAX), chatId) 
			+ ''" C02="'' + CONVERT(VARCHAR(MAX), ISNULL(ccinbound.descripcion, '''')) 
			+ ''" C03="'' + CONVERT(VARCHAR(MAX), domain) 
			+ ''" C04="'' + CONVERT(VARCHAR(MAX), ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'')) 
			+ ''" C05="'' + CONVERT(VARCHAR(MAX), tchatting) 
			+ ISNULL(CAST(@DispXML as varchar(MAX)), ''N/A'')
			+ ISNULL(CAST(@SubXML as varchar(MAX)), ''N/A'')
			+ ''" C08="'' + CONVERT(VARCHAR(MAX), clientname) 
			+ ''" C09="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(chatDate, requestDate), 126))) 
			+ ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
			+ ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
			+ ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
			+ ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(ccusers.[Login], '''')) 
			+ ''"/>'')
					, @dateStart = ISNULL(chatDate, requestDate) FROM ccRIAChats
																	LEFT OUTER JOIN ccinbound ON ccinbound.inbound_id = ccRIAChats.inboundid
																	LEFT OUTER JOIN ccusers ON ccusers.user_id = ccRIAChats.userid                                                            
			WHERE chatId = @conversationId
					AND chatStatus = 4              

		END;
		ELSE IF @type = 3
		BEGIN--EMAIL
			SELECT @existAttached = CASE WHEN COUNT(*) > 0
									THEN 1 ELSE 0
									END FROM attached
			WHERE messageId IN(SELECT messageId FROM message WHERE conversationId = @conversationId);
			SELECT @numInteracion = COUNT(*) FROM message WHERE conversationId = @conversationId;
			--Replaza los caracteres por los comunes
			SELECT @info = info FROM conversation WHERE conversationId = @conversationId;
			SELECT @info = replace(@info, A.Value, B.Value) FROM dbo.fn_RIASplitDelimited(@charEscape, ''|'') A
																	INNER JOIN dbo.fn_RIASplitDelimited(@charReplace, ''|'') B ON A.Id = B.Id;

			select @disp = t.Description, @subdisp = ts.califSubDesc 
			from conversation c
			left join message m on c.conversationId = m.conversationId
			left join relationMessageDisposition r on m.messageId = r.messageId
			left join ccTipoCalif t on r.dispositionId = t.calif_id
			left join ccTipoCalifSub ts on r.subDispositionId = ts.califSub_id and r.subdispositionId <> 0
			where c.conversationId = @conversationId

			SET @DispXML = (
				SELECT ''" C05="'' + @disp         
				FOR XML PATH('''')
			);

			SET @SubXML = (
				SELECT ''" C15="'' + @subdisp         
				FOR XML PATH('''')
			);

			SELECT @xml = CONVERT(XML, ''<R03 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126))) 
				+ ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid) 
			+ ''" CType="1'' 
			+ ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationId) 
			+ ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), ISNULL(MAX(b.tsend), GETDATE()), 126))) 
			+ ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion)) 
			+ ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''''))) 
			+ ISNULL(CAST(@DispXML as varchar(MAX)), ''N/A'')
			+ ''" C06="'' + CONVERT(VARCHAR, MAX(replace(replace(a.mailClient, ''<'', '' ''), ''>'', '' ''))) 
			+ ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup)) 
			+ ''" C08="'' + CONVERT(VARCHAR(MAX), MIN(ISNULL(@info, ''''))) 
			+ ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid)) 
			+ ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0)) 
			+ ''" C11="'' + CONVERT(VARCHAR(MAX), @existAttached) 
			+ ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
			+ ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
			+ ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
			+ ISNULL(CAST(@SubXML as varchar(MAX)), ''N/A'')
			+ ''" C16="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), '''')) 
			+ ''"/>'')
					, @dateStart = ISNULL(MAX(b.tsend), GETDATE()) FROM conversation a
																		INNER JOIN message b ON a.conversationid = b.conversationid
																		LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
																		LEFT OUTER JOIN ccusers d ON d.user_id = b.userid                                                                
			WHERE a.conversationId = @conversationId
			GROUP BY a.conversationId
					, a.inboundid;

		END;
		ELSE IF @type = 4
		BEGIN--Twitter
			SELECT @numInteracion = SUM(ninteration) FROM messageOutTwitter
			WHERE conversationTwitterId = @conversationId;

			SELECT @xml = CONVERT(XML, ''<R04 CDATE="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126))) 
				+ ''" CID="'' + CONVERT(VARCHAR(MAX), a.inboundid) 
			+ ''" CType="1'' 
			+ ''" C01="'' + CONVERT(VARCHAR(MAX), a.conversationTwitterId) 
			+ ''" C02="'' + RTRIM(LTRIM(CONVERT(VARCHAR(23), MIN(b.date), 126))) 
			+ ''" C03="'' + CONVERT(VARCHAR(MAX), MAX(c.descripcion)) 
			+ ''" C04="'' + CONVERT(VARCHAR, MAX(ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''''))) 
			+ ''" C05="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalif.[Description], ''N/A''))) 
			+ ''" C06="'' + MAX(a.screenNameClient) 
			+ ''" C07="'' + CONVERT(VARCHAR(MAX), SUM(b.tRetention + b.tResponse + b.tWrapup)) 
			+ ''" C08="'' + MAX(a.screenNameInbound) 
			+ ''" C09="'' + CONVERT(VARCHAR(MAX), MAX(b.messageStatusid)) 
			+ ''" C10="'' + CONVERT(VARCHAR(MAX), ISNULL(@numInteracion, 0)) 
			+ ''" C11="'' + CONVERT(VARCHAR(MAX), ISNULL(@supervisor, '''')) 
			+ ''" C12="'' + CONVERT(VARCHAR(MAX), ISNULL(@template, '''')) 
			+ ''" C13="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
			+ ''" C14="'' + CONVERT(VARCHAR, MAX(ISNULL(cctipocalifsub.califSubdesc, ''N/A''))) 
			+ ''" C15="'' + CONVERT(VARCHAR(MAX), ISNULL(MAX(d.[Login]), '''')) 
			+ ''"/>'')
					, @dateStart = ISNULL(MIN(b.date), GETDATE()) FROM conversationTwitter a
																	INNER JOIN messageOutTwitter b ON a.conversationTwitterId = b.conversationTwitterId
																	LEFT OUTER JOIN ccinbound c ON c.inbound_id = a.inboundid
																	LEFT OUTER JOIN ccusers d ON d.user_id = b.userid
																	LEFT OUTER JOIN relationMessageDispositionTwit e ON e.messageOutTwitterId = b.messageOutTwitterId
																	LEFT OUTER JOIN cctipocalif ON cctipocalif.calif_id = e.dispositionId
																	LEFT OUTER JOIN cctipocalifsub ON cctipocalifsub.califsub_id = e.subdispositionId
																										AND e.subdispositionId <> 0
			WHERE a.conversationTwitterId = @conversationId
			GROUP BY a.conversationTwitterId
					, a.inboundid;
		END;
		ELSE IF @type = 5 BEGIN --WhatsApp In

			select @disp = Description from ccWhatsAppConversations c left join ccTipoCalif b on c.disposition = b.calif_id where c.conversationId = @conversationId
			select @subdisp = califSubDesc from ccWhatsAppConversations c left join ccTipoCalifSub b on c.subDisposition = b.califSub_id where c.conversationId = @conversationId

			--select * from ccWhatsAppConversations

			SET @DispXML = (
				SELECT ''" C07="'' + @disp         
				FOR XML PATH('''')
			);

			SET @SubXML = (
				SELECT ''" C08="'' + @subdisp         
				FOR XML PATH('''')
			);

			SELECT @xml = CONVERT(XML, ''<R05 CDATE="'' + CONVERT(VARCHAR(23), ISNULL(conversationDate, requestDate), 126) 
				+ ''" CID="'' + CONVERT(VARCHAR(MAX), A.inboundid) 
			+ ''" CType="5'' 
			+ ''" C01="'' + CONVERT(VARCHAR(MAX), A.conversationId) 
			+ ''" C02="'' + ISNULL(inbound.descripcion, '''') 
			+ ''" C03="'' + ISNULL(ccusers.[Login], '''') 
			+ ''" C04="'' + ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'') 
			+ ''" C05="'' + clientId 
			+ ''" C06="'' + CONVERT(VARCHAR(MAX), tConversation) 
			+ ISNULL(CAST(@DispXML as varchar(MAX)), ''N/A'')
			+ ISNULL(CAST(@SubXML as varchar(MAX)), ''N/A'')
			+ ''" C09="'' + CONVERT(VARCHAR(MAX), A.agentId) 
			+ ''" C10="'' + phoneACD 
			+ ''" C11="'' + CONVERT(VARCHAR(MAX), A.agentId) 
			+ ''" C12="'' + ISNULL(@supervisor, '''') 
			+ ''" C13="'' + ISNULL(@template, '''') 
			+ ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
			+ ''"/>'')
					, @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversations A
																			LEFT OUTER JOIN ccinbound inbound ON inbound.inbound_id = A.inboundid
																			LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId                                                                   
			WHERE A.conversationId = @conversationId;

		END;
		ELSE IF @type = 6 BEGIN --WhatsApp Out

			select @disp = Description from ccWhatsAppConversationsOut c left join ccTipoCalifOUT b on c.disposition = b.calif_id where c.conversationId = @conversationId
			select @subdisp = califSubDesc from ccWhatsAppConversationsOut c left join ccTipoCalifSubOUT b on c.subDisposition = b.califSub_id where c.conversationId = @conversationId

			SET @DispXML = (
				SELECT ''" C07="'' + @disp         
				FOR XML PATH('''')
			);

			SET @SubXML = (
				SELECT ''" C08="'' + @subdisp         
				FOR XML PATH('''')
			);

			SELECT @xml = CONVERT(XML, ''<R06 CDATE="'' + CONVERT(VARCHAR(23), ISNULL(conversationDate, requestDate), 126) 
				+ ''" CID="'' + CONVERT(VARCHAR(MAX), A.camId) 
			+ ''" CType="6'' 
			+ ''" C01="'' + CONVERT(VARCHAR(MAX), A.conversationId) 
			+ ''" C02="'' + ISNULL(c.cam_descripcion, '''') 
			+ ''" C03="'' + ISNULL(ccusers.[Login], '''') 
			+ ''" C04="'' + ISNULL(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno, ''N/A'') 
			+ ''" C05="'' + clientId 
			+ ''" C06="'' + CONVERT(VARCHAR(MAX), isnull(tConversation,0)) 
			+ ISNULL(CAST(@DispXML as varchar(MAX)), ''N/A'')
			+ ISNULL(CAST(@SubXML as varchar(MAX)), ''N/A'')
			+ ''" C09="'' + CONVERT(VARCHAR(MAX), A.agentId) 
			+ ''" C10="'' + phoneCamp 
			+ ''" C11="'' + CONVERT(VARCHAR(MAX), A.agentId) 
			+ ''" C12="'' + ISNULL(@supervisor, '''') 
			+ ''" C13="'' + ISNULL(@template, '''') 
			+ ''" C14="'' + CONVERT(VARCHAR(MAX), ISNULL(@ScoreTemplate, 0)) 
			+ ''"/>'')
					, @dateStart = ISNULL(conversationDate, requestDate) FROM ccWhatsAppConversationsOut A
																			LEFT OUTER JOIN ccCamps c ON c.cam_id=A.camId
																			LEFT OUTER JOIN ccusers ON ccusers.user_id = A.agentId
			WHERE A.conversationId = @conversationId;

		END;

		DECLARE @sql NVARCHAR(MAX), @tableName NVARCHAR(MAX), @columnId NVARCHAR(MAX), @tableNameHistory NVARCHAR(MAX);
		DECLARE @parameterDefinition NVARCHAR(MAX);

		SELECT @tableName = tableName
				, @tableNameHistory = tableNameHistory
				, @columnId = columnId FROM ccFinderServices
		WHERE id =  @type;

		SET @parameterDefinition = N''@conversationId bigint,@xml xml,@dateStart datetime'';

		IF @xml IS NOT NULL
		BEGIN        

			SET @sql = ''IF EXISTS(SELECT * FROM '' + @tableNameHistory + '' WHERE ''+@columnId+'' = @conversationId)
			BEGIN
				UPDATE '' + @tableNameHistory + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
			END
			else IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
			BEGIN
				UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = 2 WHERE ''+@columnId+'' = @conversationId;
			END
			else begin
				INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, 0);
			end     
			'';
                            
		END
		else begin
				SET @sql ='' IF EXISTS(SELECT * FROM '' + @tableName + '' WHERE ''+@columnId+'' = @conversationId)
			BEGIN
				UPDATE '' + @tableName + '' SET node = @xml ,dateIn=@dateStart, STATUS = -1 WHERE ''+@columnId+'' = @conversationId;
			END
			else begin
				INSERT INTO '' + @tableName + '' (''+@columnId+'', node, dateIn, STATUS) VALUES(@conversationId, @xml, @dateStart, -1);
			end '';
		end


			EXECUTE sp_executesql
					@sql
					, @parameterDefinition
					, @conversationId = @conversationId
					, @xml = @xml
					, @dateStart = @dateStart;

		END;'
	EXEC(@sql);

	-----------------------------------------------------END Rodrigo Salazar -----------------------------------------------------------------s
	/* End script release */
	/* Upgrade database version (first and the last number of setting 77) */
	EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
	EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

	COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END