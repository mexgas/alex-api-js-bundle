/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:

Date: 2023/10/03
Description: K060000-ChatBot

Database: CCReportsRia
*/
*/
SET NOCOUNT ON

DECLARE @version INT, @versionFix INT
DECLARE @actualVersion INT, @actualVersionFix INT
DECLARE @sql VARCHAR(max)
DECLARE @errorGenerated VARCHAR(max)
DECLARE @process VARCHAR(max)
DECLARE @versionALL VARCHAR(max);


IF 1=1
BEGIN
	BEGIN TRAN
	BEGIN TRY

	-------------------------------------------- BEGIN Enrique Ruiz ---------------------------------------------------------------------------------
	SET @process = 'K060017 Insert the new Reports into the Menu list'
	SET @sql = 'IF NOT EXISTS (SELECT * FROM ccMenus WHERE menu_id = 15000)
				BEGIN
					INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release) VALUES
					(15000, ''Chatbot|Chatbot'', 15000, ''A'', 12, 3, '''', ''33b95227bffa5d65c9153de6446d153bd6852b9bf809975e12d665594f21f41b'')
				END

				IF NOT EXISTS (SELECT * FROM ccMenus WHERE menu_id = 15010)
				BEGIN
					INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release) VALUES
					(15010, ''Detalle de conversaciones|Conversations Detail'', 15000, ''B'', 12, 3, '''', ''accb20a46285ea9856ace61e5e3ffd452de1f55f20c7a005ce8e05a503060fb18beee994719b6abd36ad36efaffd0370'')
				END

				IF NOT EXISTS (SELECT * FROM ccMenus WHERE menu_id = 15020)
				BEGIN
					INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release) VALUES
					(15020, ''Conversaciones por chatbot|Conversations by Chatbot'', 15000, ''B'', 12, 3, '''', ''2605c8244920fb599fb936a4bf94521abfec097ca281c5864874691fe77a9dcb497d9428f876069fee726e663efa2ea23fd5c333b0be8fbc714d53e1fcb087c8'')
				END

				IF NOT EXISTS (SELECT * FROM ccMenus WHERE menu_id = 15030)
				BEGIN
					INSERT INTO ccMenus (menu_id, menu_descrip, parent, Nivel, ordengral, type, HelpSWF, release) VALUES
					(15030, ''Conversaciones transferidas a WhatsApp|Transferred Conversations to WhatsApp'', 15000, ''B'', 12, 3, '''',
					''2605c8244920fb599fb936a4bf94521ac1d8958f95ce9d3d1dcfbee594bd612c14c53787eec7f5671ec8aeeced55be43d4aafdd18714a1f51cd96626558813a4e4e0613c02e23f40e9f6b8341c44cf20'')
				END'		
	EXEC(@sql)
	
	SET @process = 'K060017 Add the new filter to the available list'
	SET @sql = 'IF NOT EXISTS (SELECT * FROM Filters WHERE id = 33 AND name = ''chatbots'')
				BEGIN
					INSERT INTO Filters (id, name, type, xmlParentNode, xmlChildNode) VALUES (33, ''chatbots'', 33, ''Chatbots'', ''Chatbot'')
				END'
	EXEC(@sql)

	SET @process = 'K060017 Create the table and index with the structure to the report with 15030'
	SET @sql = 'IF NOT EXISTS(SELECT * FROM SYS.TABLES WHERE NAME = N''RepChatbotConversationsTransferredWA'')
				BEGIN
					CREATE TABLE RepChatbotConversationsTransferredWA
						(	dateChatbot DATETIME NOT NULL,
							chatbotId INT NOT NULL,
							conversationIdChatbot BIGINT NOT NULL,
							chatbotName VARCHAR(255) NOT NULL,
							conversationEndStatusChatbot VARCHAR(100) NOT NULL,
							conversationIdWhatsApp INT NOT NULL,
							inboundId INT NOT NULL,
							campaign VARCHAR(30) NOT NULL,
							date DATE NOT NULL,
							dispositionId SMALLINT,
							disposition VARCHAR(60),
							subDispositionId SMALLINT,
							subDisposition VARCHAR(60),
							conversationTimeWhatsApp INT NOT NULL
						)

					CREATE INDEX IX_RepChatbotConversationsTransferredWA ON RepChatbotConversationsTransferredWA([date] ASC, inboundId, chatbotId);
				END'
	EXEC(@sql)

	SET @process = 'K060017 Add the relation of the filters to the corresponding report'
	SET @sql = 'IF NOT EXISTS (SELECT * FROM ReportsFilters WHERE id = 15030 AND filterName = ''acds'')
				BEGIN
					INSERT INTO ReportsFilters (reportName, filterName, id) VALUES (''Transferred Conversations to WhatsApp'', ''acds'', 15030)
				END

				IF NOT EXISTS (SELECT * FROM ReportsFilters WHERE id = 15030 AND filterName = ''chatbots'')
				BEGIN
					INSERT INTO ReportsFilters (reportName, filterName, id) VALUES (''Transferred Conversations to WhatsApp'', ''chatbots'', 15030)
				END'
	EXEC(@sql)

	SET @process = 'K060017 Add the ReportFiltersmenus'
	SET @sql = 'IF NOT EXISTS (SELECT * FROM ReportsFiltersMenus WHERE idReport = 15030 AND filterMenuName = ''filterby'')
				BEGIN
					INSERT INTO ReportsFiltersMenus (idReport,filterMenuName) VALUES (15030, N''filterby'')
				END

				IF NOT EXISTS (SELECT * FROM ReportsFiltersMenus WHERE idReport = 15030 AND filterMenuName = ''date'')
				BEGIN
					INSERT INTO ReportsFiltersMenus (idReport,filterMenuName) VALUES (15030, N''date'')
				END'
	EXEC(@sql)

	SET @process = 'K060017 Add the chatbot filter to list'
	SET @sql = 'CREATE OR ALTER PROCEDURE [dbo].[ccspRepCatalogos]
				@type as tinyint,
				@action tinyint = 0 -- 0 Filter select; 1 Filters Range
				,@userId int =0 ---- se agrega parametro para filtros

				AS
				declare @tablatemp table (id int, description varchar(100) null)
				declare @tempwork table (idwg int)

				if @action = 0
				begin


					-- CAMPAIGNS
				if @type = 1 begin

					if @userId <> 0 begin

						insert into @tablatemp
						select distinct caesp.IdCampEsp,'' '' as description  from ccUserView us
						inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
						inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=1
						where us.[User_id] = @userId

						SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn
							from ccCamps camp
							inner join @tablatemp A on camp.cam_id = A.id

					end
					else begin
						SELECT cam_id as id, cam_descripcion as description, ''campaignId'' as dbColumn
							from ccCamps camp

					end
				end


					-- DIAL RESULTS
				if @type = 2 begin
					Select tiporesdial_id as id, descripcion as description, ''dialResultId'' as dbColumn
					from ccTipoResultadoDial
					order by descripcion
				end

					-- WORKGROUPS
				if @type = 3 begin
					if @userId <> 0 begin
						select v.IDWG as id, c.WGName as description, ''workgroupId'' as dbColumn
						from ccWgByAcdView v
						inner join ccriacat_workgroup c on c.IDWG=v.IDWG
						where USER_ID= @userId
						return
					end
					else  begin
						select idwg as id, wgname as description, ''workgroupId'' as dbColumn
						from ccRIACat_WorkGroup
						group by idwg, wgname	select * from ccRIACat_WorkGroup
						order by wgname
					end
				end


				-- AREAS
				if @type = 4 begin
				if @userId <> 0 begin

					insert into @tablatemp
					select distinct isnull(us.IDArea,0) as IDArea, wgu.User_id from ccUserView us
					inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
					where us.[User_id] = @userId

					select distinct idArea as id, isnull(AreaName,''S/AREA'') as description, ''areaId'' as dbColumn
					from ccRIACat_Areas area inner join @tablatemp tem on area.IDArea = tem.id
					return
				end
					else begin

						select idArea as id, AreaName as description, ''areaId'' as dbColumn
						from ccRIACat_Areas
						group by idArea, AreaName
						order by AreaName
					end
				end

				-- DISPOSITIONS OUT
				if @type = 5 begin
					SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
					FROM ccTipoCalifOut
					order by [description]
				end

					-- USER
				if @type = 6 	begin
					if @userId <> 0 begin

							insert into @tempwork
									select IDWG from ccRIAWorkGroupUsers with (index (IX_ccRIAWorkGroupUsers_I)) where User_id = @userId

							select distinct us.User_id as id, us.Login as description,  ''userId'' as dbcolumn from ccUserView us
							inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id

							inner join @tempwork awg on wgu.IDWG = awg.idwg
							where us.TipoUser_id = 1 and [status] = 1

							return
						end

						else begin

							SELECT [user_id] as id, [login] AS description, ''userId'' as dbColumn
							FROM ccUserView B WHERE [status] = 1 and TipoUser_id = 1
							ORDER BY description
						end
				end

					-- ACDS**************
				if @type = 7 begin
					if @userId <> 0 begin

							insert into @tablatemp
							select distinct caesp.IdCampEsp,'''' as description  from ccUserView us
							inner join ccRIAWorkGroupUsers wgu on us.User_id = wgu.User_id
							inner join ccRIACampEspWG caesp on wgu.IDWG = caesp.IDWG and caesp.Tipo=0
							where us.[User_id] = @userId


							SELECT inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
								from ccinbound B
								inner join @tablatemp A on B.inbound_id = A.id
								return
						end
						else begin
							select inbound_id as id, descripcion as description, ''inboundId'' as dbColumn
								from ccinbound
						end
				end

					-- DIDS
				if @type = 8 	begin
					select 0 as id, ''S/DNIS''  as description, ''dnisId'' as dbColumn
					union
					select dni_id as id, CASE WHEN dni_Descripcion = '''' then convert(varchar,dni_numero) else dni_Descripcion end  as description, ''dnisId'' as dbColumn
					from ccdnis
				end

					--DISPOSITIONS IN
				if @type = 9 begin
					SELECT calif_id as id, [description] as description, ''dispositionId'' as dbColumn
					FROM ccTipoCalif
					order by [description]
				end

					--SUBDISPOSITIONS IN
				if @type = 10	begin
					SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
					FROM ccTipoCalifSub
					order by [description]
				end

					--PROVIDER
				if @type = 11 begin
					SELECT provedor_id as id,descrip as description, ''providerId'' as dbColumn
					FROM cstoProvedor
					order by [description]
				end

					-- UNAVAILABLES
				if @type = 12 begin
					SELECT tiponotready_id as id, descripcion as description, ''tiponotreadyId'' as dbColumn
					FROM cctiponotready
					order by descripcion
				end

					-- DIALERS
				if @type = 13 begin
					SELECT dialer_id as id, descripcion as description, ''dialerId'' as dbColumn
					FROM ccoDialers
					order by descripcion
				end

					-- CallTYpes
				if @type = 14	begin
						SELECT statusCall_id as id, descripcion as description, ''callStatusId'' as dbColumn
						FROM ccStatusLlamada
					order by descripcion
				end

					-- SUBDISPOSITIONS OUT
				if @type = 21	begin
					SELECT califSub_id as id, [califSubDesc] as description, ''subDispositionId'' as dbColumn
					FROM cctipocalifsubout
					order by [description]
				end

					--AVRS TEMPLATE-SECTION
				if @type = 15 	begin
					SELECT fc.id as id, (rf.nombre +'' ''+ rc.con_descripcion)+'' ''+convert(varchar(10),fc.id) as description, ''templateSectionId'' as dbColumn
					FROM RIA_FORMATOCONCEPTO fc
					INNER JOIN  (SELECT id_formato, nombre, MAX(version) as version
													FROM RIA_FORMATOS
													WHERE activo = 1
													group by id_formato, nombre) as rf
					ON rf.id_formato = fc.templateId
					inner join RIA_CONCEPTOS rc ON rc.id_concepto = fc.sectionId
					order by fc.id
				END

				--exec dbo.ccspRepCatalogos @type=15,@action=0

					--AVRS TEMPLATES
				if @type = 16 	begin
					SELECT f.id_formato as id, f.nombre as description, ''templateId'' as dbColumn
					FROM RIA_FORMATOS f INNER JOIN (SELECT id_formato,MAX(version) as version
													FROM RIA_FORMATOS
													WHERE activo = 1
													group by id_formato) as t
					ON f.id_formato = t.id_formato AND f.version = t.version
					order by f.nombre
				end

					--AVRS TEMPLATES
				if @type = 31 	begin
					SELECT c.id_concepto as id, c.con_descripcion as description, ''sectionId'' as dbColumn
					FROM RIA_CONCEPTOS c INNER JOIN (SELECT id_concepto,MAX(version) as version
													FROM RIA_CONCEPTOS
													group by id_concepto) as t
					ON c.id_concepto = t.id_concepto AND c.version = t.version
					order by c.con_descripcion
				END

					--AVRS QUESTIONS
				if @type = 23 	begin
					SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
					FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
													FROM RIA_PREGUNTAS
													group by id_pregunta) as t
					ON p.id_pregunta = t.id_pregunta
					order by p.enunciado_pregunta
				END


				--AVRS QUESTIONS CHAT
				if @type = 24 	begin
					SELECT p.id_pregunta as id, p.enunciado_pregunta as description, ''questionId'' as dbColumn
					FROM RIA_PREGUNTAS p INNER JOIN (SELECT id_pregunta
													FROM RIA_PREGUNTAS
													group by id_pregunta) as t
					ON p.id_pregunta = t.id_pregunta
					order by p.enunciado_pregunta
				END

					-- AVRS SUPERVISOR
				if @type = 17 	begin
					SELECT [user_id] as id, [login] AS description, ''supervisorId'' as dbColumn
					FROM ccUserView
					WHERE [status] = 1
					and TipoUser_id = 2
					ORDER BY [login]
				end

					--Status Call
				if @type = 25 	begin
					select statusCall_id as id, [descripcion] as description, ''statusCallId'' as dbcolumn
					from ccstatusllamada
					order by [descripcion]
				end

					--Survey
				if @type = 26 	begin
					select surveyId as id, [description] as description, ''surveyId'' as dbcolumn
					from Survey
					order by [description]
				end

				--dialType
				if @type = 29 begin
					select dialId as id, [description] as description, ''dialId'' as dbcolumn
					from dialType
					order by [description]
				end

					--dial
				if @type = 30 	begin
					select id as id, [description] as description, ''dialId'' as dbcolumn
					from Dials
					order by [description]
				end

				--Chatbot
				IF @type = 33 	BEGIN
					SELECT DISTINCT id AS id, [ProjectName] AS description, ''chatbotId'' AS dbcolumn
					FROM AzureKnowledge
					ORDER BY [description]
				END

				end
				-----------------------------------------------------------
				if @action = 1 begin
					-- TRUNKS
					if @type = 13
					begin
						SELECT MIN(trunk) as [min],MAX(trunk) as [max],''trunk'' as dbColumn  from RepTrunkBusy
					end

					-- AVRS DISPOSITION
					if @type = 18
					begin
						SELECT 0 as [min], 100 as [max],''Disposition'' as dbColumn
					end

					-- AVG DISPOSITION
					if @type = 19
					begin
						SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
					end

					-- SCORE
					if @type = 20
					begin
						SELECT 0 as [min], 100 as [max],''avgDisposition'' as dbColumn
					end
				end'
	EXEC(@sql)

	SET @process = 'K060017 Create the SP for Chatbot Transfered Conversations Report'
	SET @sql = 'CREATE OR ALTER procedure [dbo].[ccspRepChatbotConversationsTransferredWA]
				@action as tinyint,
				@from as datetime = null,
				@to as datetime = null

				AS
				if @from is null
					select @from = convert(datetime,convert(varchar(11),getdate()))
					set @from=DATEADD(dd,-1,@from)
				if @to is null
					select @to = getdate()
					
				if @action = 1	begin

					DELETE FROM RepChatbotConversationsTransferredWA  WITH(ROWLOCK) WHERE [date] >= @from AND [date] < @to;

					INSERT INTO RepChatbotConversationsTransferredWA
					SELECT  CAST(B.FirstMessageTime AS DATETIME) AS [dateChatbot],
							A.id AS chatbotId,
							B.ChatBotConversationId AS conversationIdChatbot,
							A.ProjectName AS chatbotName,
							C.description AS conversationEndStatusChatbot,
							D.conversationId AS conversationIdWhatsApp,
							D.inboundId AS inboundId,
							E.descripcion AS campaign,
							CAST(B.FirstMessageTime AS DATE) AS [date],
							D.disposition AS dispositionId,
							isnull(F.Description,'''') AS disposition,
							D.subdisposition AS subDispositionId,
							isnull(G.califSubDesc,'''') AS subDisposition,
							isnull(D.tConversation,D.tChatting) AS cconversationTimeWhatsApp
							FROM ccWhatsAppConversations D
							LEFT JOIN ccinbound E ON E.inbound_id = D.inboundId
							LEFT JOIN cctipocalif F ON F.calif_id = D.disposition
							LEFT JOIN cctipocalifsub G on G.califSub_id = D.subDisposition
							LEFT JOIN ChatBotWhatsAppConversation H ON H.WhatsAppConversationId = D.conversationId
							JOIN ChatBotConversation B ON B.ChatBotConversationId = H.ChatBotConversationId
							JOIN ChatBotConversationEndStatus C ON C.id = B.EndStatus
							JOIN AzureKnowledge A ON A.id = B.ChatBotId
							WHERE D.requestDate between @from AND @to
							ORDER BY conversationIdChatbot ASC;
				END'
	EXEC(@sql)

	SET @process = 'K060017 Add the conversation end status to the translation table'
	SET @sql = 'IF NOT EXISTS (SELECT * FROM TranslatedReports WHERE id = 15030)
				BEGIN
					INSERT INTO TranslatedReports (id, columns) VALUES (15030,
                    ''conversationEndStatusChatbot'')
				END'
	EXEC(@sql)

	---------------------------------------- END Enrique Ruiz ---------------------------------------------------------------------------------

	
	
	SET @process = ''
	SET @sql = ''
	EXEC(@sql)

		
		/* End script release */		/* Upgrade database version (first and the last number of setting 77) */
		-- EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
		-- EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
