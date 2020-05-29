/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author: Raymundo Gonzalez
Date: 2015/02/11
Description: 
	
	Se crea la tabla ccChatsNode para almacenamiento de registros de chat para Finder
	Se crea la tabla ccFinderServices para catalogo de servicios incorporados al Finder
	Se crea la tabla ccBaseXDB para guardar relacion de BD de BaseX y su informacion
	Se crea la tabla ccCRMNodes para guardar datos de CRM en caso de existir
	Se crean los indices IX_dateIn, IX_dateOut, e IX_status en la tabla ccChatsNode
	Se crean los indices IX_serviceId, IX_dateStart e IX_dateEnd en la tabla ccBaseXDB
	Se crea el indice IX_chatId en la tabla ccCRMNodes
	Se insertan registros a la tabla ccFinderServices
	Se insertan los registros para pasar la informacion procesada al nuevo finder a la tabla ccChatsNode
	Se crea el SP ccsp_BaseXmngr para administracion de registros de BaseX
	Se actualiza el SP ccsp_RIAInsertChat para insertar nodos XML de chat para Finder
	se crea ccspFinderChat para la crea los archicos de chats

	Satisfaction Survey

	Se Eliminan registros de tabla ccMenus
	Se Eliminan registros de tabla ccMenuUser
	
	Se Agregar registros a tabla ccMenus
	
	Se crea SP ccsp_AdmGetAgentIdOnChat
	Se crea SP ccsp_AdmGetSupervisorsForAgent
	Se crea SP ccsp_RIAInsertChat

	Se inserta menu 168 en la tabla ccsettings para CRM
	Se modifica el SP ccsp_GetAgentIndividualCounters para contadores de tiempos promedio de atencion por agente
	Se inserta menu de CRM

	Se crea la tabla ccChatsNode para almacenamiento de registros de chat para Finder
	Se crea la tabla ccFinderServices para catalogo de servicios incorporados al Finder
	Se crea la tabla ccBaseXDB para guardar relacion de BD de BaseX y su informacion
	Se crea la tabla ccCRMNodes para guardar datos de CRM en caso de existir
	Se crean los indices IX_dateIn, IX_dateOut, e IX_status en la tabla ccChatsNode
	Se crean los indices IX_serviceId, IX_dateStart e IX_dateEnd en la tabla ccBaseXDB
	Se crea el indice IX_chatId en la tabla ccCRMNodes
	Se insertan registros a la tabla ccFinderServices
	Se insertan los registros para pasar la informacion procesada al nuevo finder a la tabla ccChatsNode
	Se crea el SP ccsp_BaseXmngr para administracion de registros de BaseX
	se crea ccspFinderChat para la crea los archicos de chats

Database: CCenterRia
Required version: 114

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 115

/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

		/* Start script release */

		set @process = 'update ccsettings'
		set @sql='if (select count(*) from ccsettings where setting_id = 153) > 0
					update ccsettings
					set valor = ''C:\Program Files\BaseX|192.168.1.64|1984|admin|nuxiba|10|10''
					where setting_id = 153'
		EXEC(@sql)		

		set @process = 'delete relation ccMenuUser'
		set @sql=' Delete from ccMenuUser where id_menu in (8050,80601,8061,8062,8063,8070,8071,8072,8080)'
		EXEC(@sql)
		
		set @process = 'delete relation ccMenus'
		set @sql=' Delete from ccMenus where menu_id in (8050,8060,8061,8062,8063,8070,8071,8072,8080)'
		EXEC(@sql)
		
		set @process = 'ccsp_AdmGetAgentIdOnChat - Drop if exists'
		set @sql='if exists (select * from sys.procedures where name = N''ccsp_AdmGetAgentIdOnChat'') DROP PROCEDURE ccsp_AdmGetAgentIdOnChat'
		EXEC(@sql)

		set @process = 'ccsp_AdmGetSupervisorsForAgent - Drop if exists'
		set @sql='if exists (select * from sys.procedures where name = N''ccsp_AdmGetSupervisorsForAgent'') DROP PROCEDURE ccsp_AdmGetSupervisorsForAgent'
		EXEC(@sql)

		set @process = 'ccsp_RIAInsertChat - Drop if exists'
		set @sql='if exists (select * from sys.procedures where name = N''ccsp_RIAInsertChat'') DROP PROCEDURE ccsp_RIAInsertChat'
		EXEC(@sql)

		set @process = 'ccChatsNode - Create Table'
			set @sql='if not exists (select * from sys.tables where name = N''ccChatsNode'')
				create table ccChatsNode(
				chatId int not null primary key,
				node xml,
				dateIn datetime,
				dateOut dateTime default null,
				[status] tinyint default 0
				)'	
			EXEC(@sql)

			set @process = 'ccFinderServices - Create Table'
			set @sql='if not exists (select * from sys.tables where name = N''ccFinderServices'')
				create table ccFinderServices(
				id int identity primary key,
				name varchar(20),
				ref varchar(3),
				)'	
			EXEC(@sql)

			set @process = 'ccBaseXDB - Create Table'
			set @sql='if not exists (select * from sys.tables where name = N''ccBaseXDB'')
				create table ccBaseXDB(
				id [int] identity primary key,
				serviceId [int],
				dateStart [datetime],
				dateEnd [datetime] default null,
				Xname [varchar](25),
				isFull [bit] default 0,
				foreign key (serviceId) references ccFinderServices(id)
				)'	
			EXEC(@sql)	
			
			set @process = 'ccCRMNodes - Create Table'
			set @sql = 'if not exists (select * from sys.tables where name = N''ccCRMNodes'')
				create table ccCRMNodes(
				chatId int,
				node xml, 
				foreign key (chatId) references ccChatsNode(chatId) on delete cascade
				)'	
			EXEC(@sql)

		
		set @process = 'Insert values in ccmenus'
		set @sql='if not exists (select * from sys.tables where name = N''ccmenus'')
			begin
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF) values(8050,''Calidad|Quality'',8050,''A'',8,3,'''')
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8060,''Formatos de calificacion|Scoring Templates'',8050,''B'',8,3,'''')	
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8061,''Agente(Formatos de Calificación)|AgentScoringTemplates'',8060,''C'',8,3,'''')		
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8062,''Supervisor(Formatos de Calificación)|SupervisorScoringTemplates'',8060,''C'',8,3,'''')		
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8063,''Conceptos(Formatos de Calificación)|SectionsScoringTemplates'',8060,''C'',8,3,'''')		
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8064,''Preguntas(Formatos de Calificación)|QuestionsScoringTemplates'',8060,''C'',8,3,'''')		
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8071,''Calificaciones(Formatos de Calificación)|DispositionsScoringTemplates'',8060,''C'',8,3,'''')		
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8072,''Detalle(Formatos de Calificación)|DetailScoringTemplates'',8060,''C'',8,3,'''')		
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8080,''Encuestas de Satisfaccion|Customer Satisfaction Service'',8050,''B'',8,3,'''')		
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8081,''Agente(Encuestas de Satisfacción)|AgentCustomerSatisfactionService'',8080,''C'',8,3,'''')		
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8082,''Preguntas(Encuestas de Satisfacción)|QuestionsCustomerSatisfactionService'',8080,''C'',8,3,'''')		
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8083,''Calificaciones(Encuestas de Satisfacción)|DispositionsCustomerSatisfactionService'',8080,''C'',8,3,'''')		
				insert into ccmenus (menu_id,menu_descrip,parent,Nivel,ordengral,[type],HelpSWF)values(8084,''Detalle(Encuestas de Satisfacción)|DetailCustomerSatisfactionService'',8080,''C'',8,3,'''')
			end
			'
		EXEC(@sql)

		set @process = 'ccChatsNode - Create Indexes'
		set @sql='if not exists (select * from sys.indexes where name = N''IX_dateIn'' and object_id = OBJECT_ID(N''ccChatsNode'')) create nonclustered index IX_dateIn on ccChatsNode(dateIn desc)
				if not exists (select * from sys.indexes where name = N''IX_dateOut'' and object_id = OBJECT_ID(N''ccChatsNode'')) create nonclustered index IX_dateOut on ccChatsNode(dateOut desc)
				if not exists (select * from sys.indexes where name = N''IX_status'' and object_id = OBJECT_ID(N''ccChatsNode'')) create nonclustered index IX_status on ccChatsNode([status] desc)'
	
			EXEC(@sql)
	
		set @process = 'ccBaseXDB -Create Indexes'
		set @sql = 'if not exists (select * from sys.indexes where name = N''IX_serviceId'' and object_id = OBJECT_ID(N''ccBaseXDB'')) create nonclustered index IX_serviceId on ccBaseXDB(serviceId desc)
				if not exists (select * from sys.indexes where name = N''IX_dateStart'' and object_id = OBJECT_ID(N''ccBaseXDB'')) create nonclustered index IX_dateStart on ccBaseXDB(dateStart desc)
				if not exists (select * from sys.indexes where name = N''IX_dateEnd'' and object_id = OBJECT_ID(N''ccBaseXDB'')) create nonclustered index IX_dateEnd on ccBaseXDB(dateStart desc)'
		
			EXEC(@sql)

		set @process = 'ccCRMNodes - Create Index'
		set @sql = 'if not exists (select * from sys.indexes where name = N''IX_chatId'' and object_id = OBJECT_ID(N''ccCRMNodes'')) create nonclustered index IX_chatId on ccCRMNodes(chatId desc)'
			
			EXEC(@sql)
	
		set @process = 'ccFinderServices - Insert'
		set @sql='if not exists (select * from ccFinderServices where name = N''Chat'')
				begin
					insert into ccFinderServices (name, ref) values (''Chat'', ''R01'')
					insert into ccFinderServices (name, ref) values (''Rec'', ''R02'')
				end'
		
			EXEC(@sql)

		set @process = 'ccChatsNode - Insert data'
		set @sql='if (select count(*) from ccChatsNode)=0
				begin
					declare @from datetime,@day int
					declare @i int, @count int,@xml xml
					set @i=1

					select @day=valor from ccsettings where setting_id=159
					set @from =DATEADD(dd,-@day,getdate())

					select chatId as C01, isnull(ccinbound.descripcion,'''''''') as C02, domain as C03,isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno,'''') as C04, 
						tchatting as C05, isnull([description],'''') as C06, isnull(califSubdesc,'''') as C07, 
						clientName as C08, convert(varchar(23), chatDate, 126) as C09 
						into #tempFinderNode 
						 from ccRIAChats with (nolock)
						left outer join ccinbound on ccinbound.inbound_id = ccRIAChats.inboundid
						left outer join ccusers on ccusers.user_id = ccRIAChats.userid
						left outer join cctipocalif on cctipocalif.calif_id = ccRIAChats.disposition 
						left outer join cctipocalifsub on cctipocalifsub.califsub_id = ccRIAChats.subdisposition and ccRIAChats.subdisposition <> 0
						where chatStatus = 4 and requestDate is not null and chatDate is not null and requestDate>=@from 

					insert into ccChatsNode(chatId,node,dateIn,status)
					select C01,convert(xml,''<R01 C01="''+convert(varchar(max),C01)+''" C02="''+convert(varchar(max),C02)+''" C03="''+convert(varchar(max),C03)+''" C04="''+convert(varchar(max),C04)+
						''" C05="''+convert(varchar(max),C05)+''" C06="''+convert(varchar(max),C06)+''" C07="''+convert(varchar(max),C07)+''" C08="''+convert(varchar(max),C08)+''" C09="''+rtrim(ltrim(C09))+''" C10="" C11="" C12="0" />''),getdate(),0
						from #tempFinderNode

					drop table #tempFinderNode
				end'
	
			EXEC(@sql)

		set @process = 'Create SP -- ccsp_AdmGetAgentIdOnChat'
		if not exists (select * from sys.procedures where name = N'ccsp_AdmGetAgentIdOnChat')
			set @sql='CREATE PROCEDURE  [dbo].[ccsp_AdmGetAgentIdOnChat]
			@chat_id int
			AS
			BEGIN
				select userId from ccRIAChats where chatId=@chat_id
			END
			'
		else
			set @sql = ''		
		EXEC(@sql)

		set @process = 'Create SP -- ccsp_AdmGetSupervisorsForAgent'
		if not exists (select * from sys.procedures where name = N'ccsp_AdmGetSupervisorsForAgent')
			set @sql='CREATE PROCEDURE  [dbo].[ccsp_AdmGetSupervisorsForAgent]
			@chat_id int

			AS
			BEGIN

				SET NOCOUNT ON;

				declare @age_id int

				set @age_id = (select userId from ccRIAChats where chatId=@chat_id)


				select distinct a1.user_id as agt, a5.user_id as sup, a5.login, a5.Nombres, a5.ApellidoPaterno, a5.ApellidoMaterno from ccusers a1 
				inner join ccriaworkgroupusers a2 on (a1.user_id=a2.user_id and tipouser_id=1)
				inner join 
				(select a3.user_id, a4.IDWG, a3.login, a3.Nombres, a3.ApellidoPaterno,a3.ApellidoMaterno  from ccusers a3 
				inner join ccriaworkgroupusers a4 on (a3.user_id=a4.user_id and (tipouser_id=2 or tipouser_id=6))) a5 on (a2.IDWG=a5.IDWG)
				where a1.user_id = @age_id
				order by a1.user_id,a5.user_id

			END'
		else
			set @sql = ''
		
		EXEC(@sql)

		set @process = 'Create SP -- ccsp_RIAInsertChat'
		if not exists (select * from sys.procedures where name = N'ccsp_RIAInsertChat')
			set @sql='CREATE PROCEDURE [dbo].[ccsp_RIAInsertChat]
				@action int,
				@inboundId smallint = 0,
				@domain varchar(50) = '''',
				@session varchar(50) = '''',
				@tTimeout smallint = 0,
				@chatId int = 0,
				@status tinyInt = 0,
				@userId smallint = 0,
				@finished tinyInt = 0,
				@chattingTime int = 0,
				@startTime datetime = null,
				@clientName varchar(50) = '''',
				@firstMessage int = 0,
				@firstMessageTime datetime = null,
				@crmNode xml = null,
				@supervisor varchar(100) =null,
				@template varchar (100)= null,
				@ScoreTemplate int = null
				AS

				declare @xml xml 
				declare @sql nvarchar(2000)

				if @action = 1 begin -- Inserta nuevo chat request /*comentario: se recomienda hacer la busqueda del userid del CRM en esta action*/
					insert into ccRIAChats (domain,session,chatStatus,requestDate,inboundId,clientName)
					values(@domain,@session,@status,getDate(),0,@clientName)
					set @chatId = scope_identity()
					--set @crmNode = ''<CRM id="xxx" atr1="???" atr2="???" atrn="???"/>''
					--insert into ccCRMNodes (chatId, node) values (@chatId, @crmNode)
					select @chatId
				end

				if @action = 2 begin -- Save Initial Info
				update ccRIAChats set inboundId = @inboundId, chatStatus = @status, userId = @userId, tTimeout = @tTimeout where chatId = @chatId
				end

				if @action = 3 begin -- Update Status
				update ccRIAChats set chatStatus = @status where chatId = @chatId
				end

				if @action = 4 begin -- Save Final Status
				if @firstMessage = 0
					begin
						update ccRIAChats set finishedBy = @finished where chatId = @chatId
					end
				else
					begin
						update ccRIAChats set finishedBy = @finished, firstMessageTime  = @firstMessageTime where chatId = @chatId
					end
				end

				if @action = 5 begin -- Save Chatting Time /*comentario: la insercion del nodo (registro final para el finder) se recomiendo en esta action, no olvidar validar status = 4, finishedby != null y validar los tiempos para garantizar el dato final */
					update ccRIAChats set tChatting = @chattingTime, chatDate = @startTime where chatId = @chatId
					select @xml = convert(xml,''<R01 C01="''+convert(varchar(max),chatId)+''" C02="''+convert(varchar(max),isnull(ccinbound.descripcion,''''))+''" C03="''+convert(varchar(max),domain)+''" C04="''+convert(varchar(max), Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno )+
					''" C05="''+convert(varchar(max),tchatting)+''" C06="''+convert(varchar(max),tchatting)+''" C07="''+convert(varchar(max),isnull(califSubdesc,''''))+''" C08="''+convert(varchar(max),clientName)+''" C09="''+rtrim(ltrim(convert(varchar(23), chatDate, 126)))+''" C10="" C11="" C12="0" />'')
					from ccRIAChats 
					left outer join ccinbound on ccinbound.inbound_id = ccRIAChats.inboundid
					left outer join ccusers on ccusers.user_id = ccRIAChats.userid
					left outer join cctipocalif on cctipocalif.calif_id = ccRIAChats.disposition 
					left outer join cctipocalifsub on cctipocalifsub.califsub_id = ccRIAChats.subdisposition and ccRIAChats.subdisposition <> 0
					where chatId = @chatId and chatStatus = 4 and requestDate is not null and chatDate is not null
					
					if @xml is not null
					begin
						select @crmNode = node from ccCRMNodes where chatId = @chatId
						if @crmNode is not null
						begin
							set @sql = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R01)[1]'''') ''
							execute sp_executesql @sql,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
						end
						insert into ccChatsNode (chatId,node, dateIn,[status]) values (@chatId,@xml, getdate(),0)
					end
				end

				if @action = 6 --Update Chat Node 
				 begin
				 	select @xml = convert(xml,''<R01 C01="''+convert(varchar(max),chatId)+''" C02="''+convert(varchar(max),isnull(ccinbound.descripcion,''''))+''" C03="''+convert(varchar(max),domain)+''" C04="''+convert(varchar(max), Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno )+
					''" C05="''+convert(varchar(max),tchatting)+''" C06="''+convert(varchar(max),tchatting)+''" C07="''+convert(varchar(max),isnull(califSubdesc,''''))+''" C08="''+convert(varchar(max),clientName)+''" C09="''+rtrim(ltrim(convert(varchar(23), chatDate, 126)))+
					''" C10="''+convert(varchar(max),@supervisor ) + ''" C11="''+convert(varchar(max),@template )  + ''" C12="''+convert(varchar(max),@ScoreTemplate ) +  ''"/>'')
					from ccRIAChats 
					left outer join ccinbound on ccinbound.inbound_id = ccRIAChats.inboundid
					left outer join ccusers on ccusers.user_id = ccRIAChats.userid
					left outer join cctipocalif on cctipocalif.calif_id = ccRIAChats.disposition 
					left outer join cctipocalifsub on cctipocalifsub.califsub_id = ccRIAChats.subdisposition and ccRIAChats.subdisposition <> 0
					where chatId = @chatId and chatStatus = 4 and requestDate is not null and chatDate is not null
					
					if @xml is not null
					begin
						set  @crmNode =null
						select @crmNode  = node from ccCRMNodes where chatId = @chatId
						
						if @crmNode  is not null
						begin
							set @sql = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R01)[1]'''') ''
							execute sp_executesql @sql,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
						end

						--insert into ccChatsNode (chatId,node, dateIn) values (@chatId,@xml, getdate())
						update ccChatsNode set [status] = 2, node =@xml  where chatId = @chatId
						select @chatId
						
					end
				end'
		else
			set @sql = ''
		
		EXEC(@sql)

		set @process = 'ccsp_BaseXmngr - Create Procedure'
			if not exists (select * from sys.procedures where name = N'ccsp_BaseXmngr')
				set @sql='CREATE PROCEDURE [dbo].[ccsp_BaseXmngr]
					@action int = 0,
					@option int = 0,
					@idF int = 0,
					@idL int = 0,
					@idService int = 0,
					@name varchar(25) = NULL,
					@top varchar(max) = NULL
					AS
					declare @sql nvarchar(max)
					set @sql = ''''
					if @action = 1 --obtiene los nodos a insertar en BX
					begin
						if @option = 1
						begin
							set @sql = ''select top '' + @top + '' chatId, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ccChatsNode with(rowlock) where status = 0''
							exec(@sql)
						end
					end
					if @action = 2 --actualiza los nodos insertados en BX
						if @option = 1
						begin
							update ccChatsNode with(rowlock) set [status] = 1, dateOut = getDate() where chatId between @idF and @idL and [status] = 0
						end
					if @action = 3 --trae el nombre de la base de datos en BX
					begin
						select Xname from ccBaseXDB where serviceId = @option and isFull = 0
					end
					if @action = 4 --inserta el nombre del xml en BX
					begin
						insert into ccBaseXDB (serviceId, dateStart, Xname) values (@option, getDate(), @name)	
					end
					if @action = 5 --obtener servicios disponibles
					begin
						select id, ref from ccFinderServices
					end
					if @action = 6 begin --obtener valores con status 2
					set @sql = ''select top '' + @top + '' chatId,replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ccChatsNode with(rowlock) where status = 2''
						exec(@sql)
					end
					if @action = 7 --actualiza los nodos insertados en BX
						if @option = 1
						begin
							update ccChatsNode with(rowlock) set [status] = 3, dateOut = getDate() where chatId between @idF and @idL and [status] = 2
						end


					--nota: las acciones 3 y 4 hacerlas para casos dinamicos, (i.e.) si se va controlor por tamaño y asignar un xml nuevo, conusltar Daniel de CW :)'
			else
				set @sql = ''
						
			EXEC(@sql)

			set @process='Create SP -- ccspFinderChat'
			if not exists (select * from sys.procedures where name = N'ccspFinderChat')
				set @sql='CREATE PROCEDURE [dbo].[ccspFinderChat]
					  @action int,@chatIds nvarchar(max)=null

					AS
					BEGIN

					SET NOCOUNT ON

					declare @sql nvarchar(max)
					if @action = 1 begin 
						set @sql=''select chatId,clientName,userId as agentId from ccRIAChats where chatId in(''+@chatIds+'')''
						--print (@sql)
						exec (@sql)
					end


					END	'
			else
				set @sql = ''

			EXEC(@sql)

		set @process = 'Insert -- ccsettings'
		set @sql='if exists (select * from sys.tables where name = N''ccsettings'')
			begin
				insert into ccsettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings)
				values(168,''0'',''Muestra si esta activa la funcionalidad de CRM'',1,''X'',''0 not enabled and 1 is enabled'',''Indicates if the CRM functionality is enabled'',1)
				insert into ccsettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings)
				values(169,''0'',''Habilita el nuevo finder'',1,''X'',''Habilita el nuevo finder y deshabilita finder de avrs y chats'',''Enable new finder and disables finder of AVRs and Chats'',1)
				INSERT INTO ccsettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings)
				VALUES (N''170'',N'' '',N''Ubicación del CRM'',N''1'',N''X'', N''IP o Hostname del servidor donde se encuentra el CRM'',N''CRM location'',N''1'')
			end'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_GetAgentIndividualCounters'
		if not exists (select * from sys.procedures where name = N'ccsp_GetAgentIndividualCounters')
			set @sql='ALTER PROCEDURE [dbo].[ccsp_GetAgentIndividualCounters] @type as int, @sup_id as int = 0 as
				set nocount on

				declare @fecha_ini datetime
				select @fecha_ini = convert(datetime,convert(varchar(11),getdate()))

				if @type = 1 --Session time
					begin
						SELECT User_id, case 
							WHEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) > 0 
								THEN sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov))  
							ELSE sum(convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), fecha, 14)))*(1-2*tipomov)) + 
								convert(int,DateDiff(second, ''00:00'', Convert(VARCHAR(30), getdate(), 14)))
							END as logintime
						FROM ccLogLogin a with(index(IX_ccLogLogin_4)), ccGenViewRelsSupsAgent b
						where fecha >= @fecha_ini
						and a.User_id = b.agt
						and b.sup = @sup_id
						GROUP BY User_id
					end

				if @type = 2 --Status agent
					begin
						SELECT User_id, TipoStatusAge_id, sum(tStatus) As segundos 
						FROM ccLogAgentesDia a with(index(IX_ccLogAgentesDia_4)), ccGenViewRelsSupsAgent b 
						WHERE fecha >= @fecha_ini
						AND a.User_id = b.agt
						and b.sup = @sup_id
						GROUP BY User_id, TipoStatusAge_id 
						ORDER BY User_id
					end

				if @type = 3
					begin

				        select calls.user_id, calls.total_calls, calls.type_calls, users.login, calls.nCalls, calls.tDialog, calls.tWrapup, calls.tHold
						from ccusers As users ,
				        (
							SELECT User_id AS ''user_id'' , count(*) AS ''total_calls'', 
							CASE  
							  WHEN statuscall_id = 15 THEN 5  --OutBound Asignada pero no contestada          
							  WHEN cal_manual = 2 THEN 3      --OutBound llamada manual
							  ELSE 2                          --Llamada de OutBound          
							END AS ''type_calls'',
							count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
							sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end) tDialog,
							sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end) tWrapup,
							sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold
							FROM ccoCallsOut a WITH (NOLOCK index(IX_ccoCallsOut_10)) , ccGenViewRelsSupsAgent b
							WHERE a.User_id = b.agt
							and b.sup = @sup_id
							AND statuscall_id <> 11  --OutBound sin estado definitivo 
							AND cal_inicio >= @fecha_ini		
							GROUP BY User_id, statuscall_id, cal_manual
					        
							UNION

							SELECT User_id AS ''user_id'' , count(*) AS ''total_calls'', 
							CASE  
							  WHEN statuscall_id = 15 THEN 4  --InBound Asignada pero no contestada          
							  ELSE 1                          --Llamada de InBound          
							END AS ''type_calls'',
							count(case when statuscall_id=13 and cal_tdialog>0 then 1 else null end) nCalls,
							sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tdialog else 0 end) tDialog,
							sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tnotas else 0 end) tWrapup,
							sum(case when statuscall_id=13 and cal_tdialog>0 then cal_tMoh else 0 end) tHold
							FROM ccCallsIn a WITH (NOLOCK index(IX_ccCallsIn_5)), ccGenViewRelsSupsAgent b
							WHERE a.User_id = b.agt
							and b.sup = @sup_id
							AND statuscall_id <> 11  --InBound sin estado definitivo 
							AND cal_inicio >= @fecha_ini		
							GROUP BY User_id, statuscall_id
				        ) AS calls 
				        where users.user_id = calls.user_id	

					end

				if @type = 4
					begin
				        select a.user_id, a.login 
				        from ccusers a, ccGenViewRelsSupsAgent b
						where user_id = b.agt
						and b.sup = @sup_id
				    end

				set nocount on'
		else
			set @sql = ''

		EXEC(@sql)
					

		set @process = 'Alter Procedure -- ccsp_ExtAppsCallHistory'
		if exists (select * from sys.procedures where name = N'ccsp_ExtAppsCallHistory')
			set @sql='ALTER PROCEDURE [dbo].[ccsp_ExtAppsCallHistory]
				@action smallint,
				@call_id int = 0,
				@startDate varchar(30) = null,
				@endDate varchar(30) = null,
				@state int = 0,
				@multipleCall_id as varchar(500) = null,
				@multipleUser_id as varchar(500) = null,
				@agentId int = 0
				AS 

				-- INBOUND x cal_id
				if @action = 1
				 begin
					select top 500
						cal_id as call_id,
						c.inbound_id,
						isnull(a.descripcion,'''') as acdGroup,
						cal_ani as phoneNumber,
						isnull(b.user_id,0) as [user_id],
						isnull(login,'''') as login,
						isnull(e.description,'''') as disposition,
						d.descripcion as call_status,
						cal_tDialog as call_tDialog,
						cal_inicio as call_date,
						cal_tNotas as WrapUp,
						cal_tXfer as Xfer,
						cal_tRing as Ringing,
						cal_key as callKey,
						isnull(e.calif_id,'''') as dispositionId,
						isnull(f.califSubDesc,'''') as subDisposition,
						isnull(f.califSub_id,'''') as subDispositionId
					from cccallsin c with(nolock)
					left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
					left join ccusers b on (c.user_id = b.user_id) 
					left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
					left join ccTipoCalif e on ( c.calif_id = e.calif_id )
					left join ccTipoCalifSub f on ( c.califSub_id = f.califSub_id )
					where cal_id >= @call_id
				 end

				-- OUTBOUND x cal_id
				if @action = 2 
				 begin
					select top 500
						cal_id as call_id,
						c.cam_id,
						isnull(a.cam_descripcion,'''') as Campaign,
						c.cal_telefono as phoneNumber,
						isnull(b.user_id,0) as user_id,
						isnull(login,''''),
						isnull(e.description,'''') as disposition,
						d.descripcion as call_status,
						cal_tDialog as call_tDialog,
						cal_inicio as call_date,
						cal_tNotas as WrapUp,
						cal_tXfer as Xfer,
						cal_tRing as Ringing,
						cal_manual as CallManual,
						c.cal_key as callKey,
						list_id,
						isnull(e.calif_id,'''') as dispositionId,
						isnull(f.califSubDesc,'''') as subDisposition,
						isnull(f.califSub_id,'''') as subDispositionId
					from ccocallsout c with(nolock)
					left join ccocallsoutsource cs on (cs.callout_id = c.callout_id)
					left join ccusers b on (c.user_id = b.user_id) 
					left join cccamps a on (c.cam_id = a.cam_id)
					left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
					left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
					left join ccTipoCalifSubOUT f on ( c.califSub_id = f.califSub_id )
					where cal_id >= @call_id
				 end

				if @action = 3 --Session time
					begin
						declare @fecha_ini datetime
						declare @fecha_fin datetime	

						if (@startDate is null or @endDate is null) or (@startDate = '''' or @endDate = '''') begin
							select @fecha_ini = convert(datetime,convert(varchar(30),getdate()))
							select @fecha_fin = dateadd(ss,-1,dateadd(dd,1,convert(datetime,convert(varchar(11),getdate()))))	
						end
						else begin
							select @fecha_ini = convert(datetime,convert(varchar(30),@startDate))
							select @fecha_fin = convert(datetime,convert(varchar(30),@endDate))
						end

						select user_id, login, logout, datediff(ss,login,logout) as logintime 
						from(select a.user_id, a.fecha as ''login'',
								(select isnull(max(Fecha),getdate())
									from ccLogLogin b with(nolock)
									where b.user_id = a.user_id and
									b.tipomov = 0 and
									b.fecha >= a.fecha and
									b.fecha <= (select isnull(min(fecha),''99991231 23:59:59.998'')
												from ccLogLogin with(nolock)
												where user_id = b.user_id and
												tipomov = 1 and
												fecha > a.fecha)) as ''logout''
								from ccLogLogin a
								where a.tipomov=1
								and fecha >= @fecha_ini
								and fecha <= @fecha_fin) as sessiontime
						order by user_id, login
					end

					if @action = 4 -- Estados de los agentes
					begin	
						select User_id, tStatus, fecha from cclogagentesdia with(nolock) where TipoStatusAge_id = @state and fecha >= @startDate and fecha < @endDate order by User_id,fecha
					end

					if @action = 5 -- Sinlge Call id Inbound
					 begin
						select top 500
							cal_id as call_id,
							c.inbound_id,
							isnull(a.descripcion,'''') as acdGroup,
							cal_ani as phoneNumber,
							isnull(b.user_id,0) as user_id,
							isnull(login,'''') as login,
							isnull(e.description,'''') as disposition,
							d.descripcion as call_status,
							cal_tDialog as call_tDialog,
							cal_inicio as call_date,
							cal_tNotas as WrapUp,
							cal_tXfer as Xfer,
							cal_tRing as Ringing,
							cal_key as callKey,
							isnull(e.calif_id,'''') as dispositionId,
							isnull(f.califSubDesc,'''') as subDisposition,
							isnull(f.califSub_id,'''') as subDispositionId
						from cccallsin c with(nolock)
						left join ccInbound a on ( c.Inbound_id = a.Inbound_id )
						left join ccusers b on (c.user_id = b.user_id) 
						left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
						left join ccTipoCalif e on ( c.calif_id = e.calif_id )
						left join ccTipoCalifSub f on ( c.califSub_id = f.califSub_id )
						where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') ) 
					 end


					-- Single call_id Outbound
					if @action = 6
					 begin
						select top 500
							cal_id as call_id,
							c.cam_id,
							isnull(a.cam_descripcion,'''') as Campaign,
							c.cal_telefono as phoneNumber,
							isnull(b.user_id,0) as user_id,isnull(login,''''),
							isnull(e.description,'''') as disposition,
							d.descripcion as call_status,
							cal_tDialog as call_tDialog,
							cal_inicio as call_date,
							cal_tNotas as WrapUp,
							cal_tXfer as Xfer,
							cal_tRing as Ringing,
							cal_manual as CallManual,
							c.cal_key as callKey,
							cs.list_id,
							isnull(e.calif_id,'''') as dispositionId,
							isnull(f.califSubDesc,'''') as subDisposition,
							isnull(f.califSub_id,'''') as subDispositionId
						from ccocallsout c with(nolock)
						left join ccocallsoutsource cs (nolock) on (cs.callout_id = c.callout_id)
						left join ccusers b on (c.user_id = b.user_id) 
						left join cccamps a on (c.cam_id = a.cam_id)
						left join ccStatusLLamada d on ( c.statusCall_id = d.statusCall_id )
						left join ccTipoCalifOUT e on ( c.calif_id = e.calif_id )
						left join ccTipoCalifSubOUT f on ( c.califSub_id = f.califSub_id )
						where cal_id in ( select value from fn_RIASplitDelimited(@multipleCall_id,'','') ) 
					 end

				if @action = 7 --Status Agente
				begin 
					select tipostatusAge_id, tstatus, dateadd(ss,(-1*tstatus),fecha), IdCampEsp, Tipo 
					from cclogagentesdia with(nolock) 
					where user_id = @agentId 
					and fecha >= @startDate 
					and fecha < @endDate 
					order by fecha
				end

				if @action = 8 
				begin
					select tipostatusAge_id, tstatus, dateadd(ss,(-1*tstatus),fecha) fecha, IdCampEsp, Tipo, user_id 
					from cclogagentesdia with(index(IX_ccLogAgentesDia_4),nolock) 
					where user_id in (select value from fn_RIASplitDelimited(@multipleUser_id,'','')) 
					and fecha between @startDate 
					and @endDate 
					order by user_id,fecha
				end'
		else
			set @sql = ''

		EXEC(@sql)

		set @process = 'Alter Procedure -- ccsp_RIAManageAreas'
		if exists (select * from sys.procedures where name = N'ccsp_RIAManageAreas')
			set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAManageAreas]
				@option tinyint,
				@IDArea smallint = 0,
				@InsertUserId smallint =null,
				@DeleteUserId varchar(255)=null,
				@InsertCamId smallint=null,
				@DeleteCamId smallint=null,
				@InsertACDGroupId smallint=null,
				@DeleteACDGroupId smallint=null
				as
				set nocount on

				if @option = 1 -- Insert User Area
				 begin
					if not exists(select IDArea from ccUsers where IDArea = @IDArea AND User_id = @InsertUserId)
					 begin
						Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @InsertUserId
						return(0)
					 end	
					 
					select 1
					return(0)
				 end

				if @option = 3 -- Insert camp area
				 begin
					if not exists(select IDArea from ccCamps where IDArea = @IDArea and cam_id = @InsertCamId)
					 begin
						Update ccCamps set IDArea = case @IDArea when 0 then null else @IDArea end
						where cam_id = @InsertCamId
						return(0)
					 end

					select 1
					return(0)
				 end

				if @option = 4 -- Delete camp area
				 begin
					insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId
				 
					delete from ccCampsAgente where cam_id = @DeleteCamId
					delete from ccoDialerCamp where cam_id = @DeleteCamId
					delete from ccoWorkingTable where cam_id = @DeleteCamId

					insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1	

					delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
					delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	
					delete from ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource where cam_id = @DeleteCamId)

					if exists(select cam_id from ccInbound where cam_id=@DeleteCamId)
					 begin
						select -4
						return(0)	 
					 end

					Update ccCamps set IDArea= null where cam_id=@DeleteCamId--, cam_activo = 0 
					return(0)
				 end

				if @option = 5 -- Insert ACDGroup area
				 begin
					if not exists(select IDArea from ccInbound where IDArea = @IDArea and Inbound_Id = @InsertACDGroupId)
					 begin
						Update ccInbound set IDArea = @IDArea, status = 1 where Inbound_id = @InsertACDGroupId
						return(0)
					 end

					select 1
					return(0)
				 end

				if @option = 6 -- Delete ACDGroup area
				 begin
						insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

					delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
					delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId

					insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId and A.tipo = 0

					delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
					delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
					delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

					Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId
					select 1
					return(0)
				 end

				if @option in (2, 9, 10, 11)
				 begin
						declare @Type tinyint
					select @Type = TipoUser_id from ccUsers where User_id = @DeleteUserId
					
					if @option in (2, 10, 11) -- Delete User area
					 begin
						if @Type = 1 -- Agente
						 begin

							insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
							insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

							delete from ccCampsAgente where user_id = @DeleteUserId
							delete from ccInboundAgentes where user_id = @DeleteUserId

							if @option = 11
								begin
									select IDWG, User_id into #WorkGroupUsers from ccRIAWorkGroupUsers where user_id = @DeleteUserId

									delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
									
									select * from #WorkGroupUsers
									drop table #WorkGroupUsers
									
									return(0)
								end
						 end

						else if @Type in (2, 6) -- Supervisor
						begin
							insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
							delete from ccSupervisorCam where user_id = @DeleteUserId
						end

						delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
						
						if @option=2
						 begin
							update ccPosicion set user_id = 0 where user_id = @DeleteUserId
							update ccUsers set IDArea = null where user_id = @DeleteUserId	
						 end
						return(0)
					end

					declare @UserWG varchar(100)
					-- @option = 9 -- Delete User area and get his workgroups

					select @UserWG = IDWG from ccRIAWorkGroupUsers where user_id = @DeleteUserId

					if @Type = 1 -- Agente
					 begin
				 		insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId
						insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id = @DeleteUserId

						delete from ccCampsAgente where user_id = @DeleteUserId
						delete from ccInboundAgentes where user_id = @DeleteUserId
					 end

					if @Type in (2, 6) -- Supervisor
					 begin
				 		insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id = @DeleteUserId

				 		delete from ccSupervisorCam where user_id = @DeleteUserId
						delete from ccMenuUser where id_User = @DeleteUserId
					 end

					delete from ccRIAWorkGroupUsers where user_id = @DeleteUserId
					update ccPosicion set user_id = 0 where user_id = @DeleteUserId
					
					if @option <> 11
						update ccUsers set IDArea = null where user_id = @DeleteUserId
					
					select @UserWG, @Type
					return(0)
				 end

				declare @AllWG varchar(400), @CurrentWG varchar(400), @AreaDescripcion varchar(40)

				if @option = 7 -- Delete camp area
				 begin
						if exists(select cam_id from ccInbound where cam_id=@DeleteCamId)
					begin
						update ccInbound set cam_id = null where cam_id=@DeleteCamId		 
					end

					select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
					from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

					insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId

					delete from ccCampsAgente where cam_id = @DeleteCamId
					delete from ccoWorkingTable where cam_id = @DeleteCamId or callout_id 
					 in (select callout_id from ccoCallsOutSource where cam_id = @DeleteCamId)

					insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteCamId and A.tipo = 1

					delete from ccSupervisorCam where cam_id = @DeleteCamId and tipo = 1
					delete from ccRIACampEspWG where IdCampEsp = @DeleteCamId and tipo = 1	

					select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
					from ccRIACampEspWG where IDCampEsp = @DeleteCamId and tipo = 1

					select @AreaDescripcion = area.AreaName
					from ccCamps as camp with(nolock)inner join ccRIACat_Areas as area 
					 with(nolock) on camp.IDArea = area.IDArea
					where camp.cam_id = @DeleteCamId
					Update ccCamps set IDArea = null where cam_id = @DeleteCamId

					If @CurrentWG is null
						set @CurrentWG = 0

					If @AllWG is null
						set @AllWG = 0

					select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
					return(0)
				 end

				if @option = 8 --Delete ACDGroup area
				 begin
					if (select cam_id from ccInbound where Inbound_id = @DeleteACDGroupId) is not null
					begin
						update ccInbound set cam_id = null where Inbound_id = @DeleteACDGroupId
					end

					select @AllWG = coalesce(@AllWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
					from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

					insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.Inbound_id = @DeleteACDGroupId

					delete ccInboundHorarios Where Inbound_id = @DeleteACDGroupId
					delete ccInboundMsgs Where Inbound_id = @DeleteACDGroupId

					insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.cam_id = @DeleteACDGroupId 

					delete ccSupervisorCam where cam_id = @DeleteACDGroupId and tipo = 0
					delete ccInboundAgentes where Inbound_id = @DeleteACDGroupId
					delete ccRIACampEspWG where IdCampEsp = @DeleteACDGroupId and tipo = 0

					select @CurrentWG = coalesce(@CurrentWG + '''','''', '''') + CAST(IDWG as varchar(400)) 
					from ccRIACampEspWG where IDCampEsp = @DeleteACDGroupId and tipo = 0

					select @AreaDescripcion = area.AreaName
					from ccInbound as ACD with(nolock) inner join ccRIACat_Areas as area 
					 with(nolock) on ACD.IDArea = area.IDArea
					where ACD.Inbound_id = @DeleteACDGroupId
					Update ccInbound set IDArea = null, status = 0 where Inbound_id = @DeleteACDGroupId

					If @CurrentWG is null
						set @CurrentWG = 0

					If @AllWG is null
						set @AllWG = 0

					select @AllWG as beforeDelete, @CurrentWG as afterDelete, coalesce(@AreaDescripcion,'''') as areaName
					return(0)
				 end

				return(0)
				set nocount off'
		else
			set @sql = ''

		EXEC(@sql)

		set @process = 'Add new access to CRMx capabilities at CCenterRia'
		set @sql='IF (SELECT COUNT(menu_id) FROM ccmenus WHERE menu_id = 9000) = 0
				BEGIN
					INSERT INTO ccmenus (menu_id,menu_descrip, parent, Nivel, ordengral, type, HelpSWF) VALUES (9000,''CRM|CRM'',9000,''A'',9,3,'''')
				END

			IF (SELECT COUNT(menu_id) FROM ccmenus WHERE menu_id = 9010) = 0
				BEGIN
					INSERT INTO ccmenus (menu_id,menu_descrip, parent, Nivel, ordengral, type, HelpSWF) VALUES (9010,''General|General'',9000,''B'',9,3,'''')
				END

			--CRM Menu
			IF (SELECT COUNT(menu_id) FROM ccmenus WHERE menu_id = 83) = 0
				BEGIN
					INSERT INTO ccmenus (menu_id,menu_descrip, parent, Nivel, ordengral, type, HelpSWF) VALUES (83,''CRM|CRM'',32,''B'',86,1,'''')
				END'
		EXEC(@sql)

		set @process = 'Alter Procedure -- ccsp_RIAMenuRoles'
		if exists (select * from sys.procedures where name = N'ccsp_RIAMenuRoles')
			set @sql='ALTER procedure [dbo].[ccsp_RIAMenuRoles]
				@Type tinyint,
				@User_id smallint = null,
				@Role_id smallint = null,
				@InsertMenu_id smallint = null,
				@DeleteMenu_id smallint = null,

				@firstSup smallint = null,
				@reportRol tinyint = 1,
				@AVRS tinyint = null,
				@CM tinyint = 0,
				@AE tinyint = 0
				as
				set nocount on

				select @reportRol = case @reportRol when 0 then 1 else @reportRol end, @role_id = case @role_id when 0 then 1 else @role_id end

				Declare @NRS tinyint
				declare @MenusChat tinyint
				declare @RelationCampInbNotReady tinyint
				Declare @IVRScripting tinyint
				Declare @MenuMail tinyint
				Declare @MenuCRM tinyint

				set @MenuMail = 0
				set @MenuCRM = 0

				select @AE = valor from ccsettings where setting_id = 71
				select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87

				---Checar si esta se aplica
				select @AVRS = valor from ccSettings where setting_id = 124
				select @IVRScripting = valor from ccsettings where setting_id = 125

				select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
				--Activa menus relacionados con campañas
				select @MenusChat = valor from ccsettings where setting_id = 145
				select @MenuMail = valor from ccsettings where setting_id = 155
				select @MenuCRM = valor from ccsettings where setting_id = 168

				If @Type = 1 -- Carga todos los roles
					begin
						select Role_id, Description from ccRIACat_AdminRole where type = @reportRol order by priority
						return(0)
					end

				If @Type = 2 -- Carga los menus de un supervisor
					begin
					Select a.id_User, a.id_Menu, b.menu_descrip, Nivel, ordengral 
					from ccMenuUser a inner join ccMenus b with(index(IX_ccMenus)) on a.id_Menu = b.menu_id and a.type = b.type
					where id_User = @User_id and a.Type = @reportRol and ((a.id_Menu not in (41,42, 53)) or 
					(a.id_Menu = 41 and @CM = 1) or (a.id_Menu = 42 and @AE > 0) or (a.id_Menu = 53 and @NRS = 1))
					order by ordengral asc
					return(0)
					end

				If @Type = 3 -- Return the menus of a rol
					begin
					select a.Role_id, b.menu_id, b.menu_descrip, b.Nivel, b.ordengral 
					from ccRIARoleMenu a inner join ccMenus b with(index(IX_ccMenus)) on b.menu_id = a.id_Menu and a.type = b.type
					where a.Role_id = @Role_id and 
					a.type = @reportRol and 
					((b.menu_id not in (41,42,53)) or (b.menu_id = 41 and @CM = 1) or (b.menu_id = 42 and @ae > 0) or (b.menu_id = 53 and @NRS = 1))
					order by a.Role_id, b.ordengral asc
					return(0)
					end

				If @Type = 4 -- Insert 
					begin	
					if (@InsertMenu_id <> 0) or not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
					begin	
						if @Role_id in (1, 10, 14) begin			
							if @InsertMenu_id <> 0 and not exists(select * from ccMenuUser where id_User = @User_id and id_Menu = @InsertMenu_id and type = @reportRol)
								insert into ccMenuUser (id_User, id_Menu, type) values(@User_id, @InsertMenu_id, @reportRol)
							if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40)begin						
								Insert into ccMenuUser (id_User, id_Menu, type)values(@User_id,40,@reportRol)		
							end
							else If @reportRol = 2 and not exists(select id_User from ccMenuUser where id_User = @User_id and (id_Menu between 1000 and 1999)) begin					
									Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, menu_id, @reportRol from ccMenus with(index(IX_ccMenus)) where menu_id between 1000 and 1999
								end
							else if @reportRol = 3 begin				
								insert into ccMenuUser (id_User, id_Menu, type) select @User_id, id_Menu, @reportRol from ccRIARoleMenu  where Role_id = @Role_id 			 			
							end
						end
						else if ((@InsertMenu_id = 53 and @NRS = 1) or (@InsertMenu_id <> 53) ) 
						begin			
							if @InsertMenu_id <> 40	delete ccMenuUser where id_User = @User_id and type = @reportRol		
								insert into ccMenuUser (id_User, id_Menu, type)	select @User_id, id_Menu, @reportRol from ccRIARoleMenu where Role_id = @Role_id and type = @reportRol
							if @reportRol = 1 and not exists(select id_User from ccMenuUser where id_User = @User_id and id_Menu = 40 and type = @reportRol)
								insert into ccMenuUser (id_User, id_Menu, type) values(@User_id,40,@reportRol)
						end		
					end		
					--Asigna un rol por default o lo actuliza
					if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
						Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
					else
						insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
							
					--Solo es necesario en caso admin y reports
					if @reportRol in(1,2) begin 
						--    inserta parent en caso de no haberlo hecho en rol personalizado        
						insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from               
						(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
						where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
						where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0

						select @User_id, parent, @reportRol from               
						(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
						where u.id_User = @User_id and u.type = @reportRol group by m.parent) parent 
						where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id) and parent<>0
								
					end
					return (0)
					end

				If @Type = 5 -- delete
					begin
						delete ccMenuUser where id_User = @User_id and id_Menu = @DeleteMenu_id and type = @reportRol
						if exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
						Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
						else
						insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
						return(0)
					end

				If @Type = 6 -- Get userMenus
					begin
					if @reportRol = 2 begin --Reports version vieja
						select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
						from ccRIAUserRole a inner join ccMenuUser b on a.user_id = b.id_user
						inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
						where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol and 
						((b.id_Menu not in (41,42,53)) or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)) 
						and ( b.id_Menu not in(77,78) or (@RelationCampInbNotReady = 1 and b.id_Menu in(77,78)))  
						and ( b.id_Menu not in(79) or (@MenusChat > 0 and b.id_Menu in(79)))
						and ( b.id_Menu not in(83) or (@MenuCRM > 0 and b.id_Menu in(83)))  
						order by ordengral asc
						return(0)
					end
					else begin ---Sitio del administrador
						if not exists( select * from ccRIAUsr_AdminPermissions where User_id=@user_id and per_id=6)
						set @AVRS =0
								
						select distinct a.Role_id, b.id_Menu, c.menu_descrip, c.Nivel, c.parent, c.ordengral, dbo.fn_viewMode (@user_id, (case b.id_Menu when 46 then 4 when 50 then 4 else b.id_Menu end)) viewMode
						      
						from ccRIAUserRole a 
						inner join ccMenuUser b on a.user_id = b.id_user
						inner join ccMenus c with(index(IX_ccMenus)) on b.id_Menu = c.menu_id and b.type = c.type
						where a.user_id = @user_id and a.Type = @reportRol and b.Type = @reportRol 
						and (	
							(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82)) 
							or (b.id_Menu = 41 and @CM = 1) or (b.id_Menu = 42 and @ae > 0) or (b.id_Menu = 53 and @NRS = 1)
							or (menu_id in (71,72) and @IVRScripting = 1)		
							or (menu_id in (73,74,75,76) and @AVRS = 1)
							or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
							or (menu_id = 79 and @MenusChat > 0)
							or (menu_id in (81,82) and @MenuMail = 1)--Mail
							or (menu_id = 83 and @MenuCRM > 0)
							)
						order by ordengral asc
						return(0)
					end
					end

				If @Type = 7 -- Get language
					begin
						select valor from ccSettings where setting_id = 27
						return(0)
					end

				If @Type = 8 -- Insert the personalized menus of a supervisor
					begin
						insert into ccMenuUser (id_User, id_Menu, type)
						select @User_id, id_Menu, @reportRol from ccMenuUser where id_User = @firstSup and type = @reportRol

						If exists(select user_id from ccRIAUserRole where user_id = @user_id and type = @reportRol)
						begin
						    Update ccRIAUserRole set Role_id = @Role_id where user_id = @user_id and type = @reportRol
						    return(0)
						end

						insert into ccRIAUserRole (User_id, Role_id, type) values (@user_id, @Role_id, @reportRol)
						return(0)
					end

				If @Type = 9 -- Delete all supervisor menus 
					begin
						delete ccMenuUser where id_User = @User_id and type = @reportRol
						return(0)
					end

				If @Type = 10 -- update all supervisor menus 
					begin
						 
						if @AVRS = 1
						begin 	
							update ccUsers set tipoUser_id = 6 where user_id = @User_id 
							return(0)
						end
					end

				If @Type = 11 -- Verify level A menus
					begin
					--   inserta parent en caso de no haberlo hecho en rol personalizado        
						Insert into ccMenuUser (id_User, id_Menu, type) select @User_id, parent, @reportRol from 
						(select m.parent from ccMenuUser u join ccMenus m with(index(IX_ccMenus)) on u.id_Menu = m.menu_id and u.type = m.type
						where m.menu_id in (1000,2000,3000,4000) and u.id_User = @User_id and u.type = @reportRol
						group by m.parent) parent where parent not in (select id_Menu from ccMenuUser where id_User =  @User_id)

						return(0)
					end

				If @Type = 12
					begin
						declare @lan as tinyint
						select @lan = valor from ccSettings where setting_id = 27
						select menu_descrip from ccMenus with(index(IX_ccMenus)) where menu_id = @Role_id
						return(0)
					end
						 
					if @Type = 13 --Agrega Menus por default a Admin en ReportsRia Agentes,ACD y Campañas
					begin
					insert into ccMenuUser([id_user],[id_Menu],[type])
					select a.User_id, b.menu_id, b.type 
						from ccUsers a cross join ccMenus b
						left join ccMenuUser d on d.id_User = a.User_id and d.id_Menu = b.menu_id	
						where a.TipoUser_id = 2 and b.type = 3 and d.id_User IS null and 
						b.menu_id >= 2000 and b.menu_id < 5000 and a.User_id = @User_id

					insert into ccRIAUserRole([User_id],[Role_id],[type])
						select a.[User_id], 14 as role_id, 3 as type from ccUsers a
							left join ccRIAUserRole d on d.User_id = a.User_id and d.type = 3
							where d.User_id IS null and a.TipoUser_id = 2 and a.User_id = @User_id
										
					return (0)
							
					end

				return(0)
				set nocount off'
		else
			set @sql = ''

		EXEC(@sql)

		set @process = 'Alter Procedure -- ccsp_RIACATMenu'
		if exists (select * from sys.procedures where name = N'ccsp_RIACATMenu')
			set @sql='ALTER procedure [dbo].[ccsp_RIACATMenu]
				@id_User varchar(2000),
				@id_Menu int,
				@Type tinyint,
				@ReportRol tinyint = 1,
				@CM tinyint = 1,
				@AE tinyint = 1
				as
				set nocount on
				Declare @NRS tinyint
				Declare @AVRS tinyint
				Declare @RelationCampInbNotReady tinyint
				Declare @IVRScripting tinyint
				Declare @MenusChat tinyint
				Declare @MenuMail tinyint
				Declare @MenuCRM tinyint

				set @MenuMail=0
				set @MenuCRM = 0

				select @AE = valor from ccsettings where setting_id = 71
				select @NRS = case valor when 4 then 1 else 0 end from ccsettings where setting_id = 87
				select @AVRS = valor from ccSettings where setting_id = 124
				select @RelationCampInbNotReady = valor from ccsettings where setting_id = 135
				select @IVRScripting = valor from ccsettings where setting_id = 125
				select @MenusChat = valor from ccsettings where setting_id = 145
				select @MenuMail = valor from ccsettings where setting_id = 155
				select @MenuCRM = valor from ccsettings where setting_id = 168

				---Mail MenuId (81)
				if @Type=1
				begin
					if @ReportRol = 1
					begin
						Select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus)) where type = 1
						and (
						(menu_id not in (41,42,53,71,72,73,74,75,76,77,78,79,81,82)) 
						or (menu_id = 41 and @CM = 1) or (menu_id = 42 and @AE > 0)  or (menu_id = 53 and @NRS = 1)
						or (menu_id in (71,72) and @IVRScripting = 1)
						or (menu_id in (73,74,75,76) and @AVRS = 1)
						or (menu_id in (77,78) and @RelationCampInbNotReady = 1)
						or (menu_id = 79 and @MenusChat > 0)
						or (menu_id in (81,82) and @MenuMail = 1)--Mail
						or (menu_id = 83 and @MenuCRM > 0)
						)
						order by ordengral asc
						return(0)
						
					end
					else if @ReportRol = 3 begin
						select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
						where type = @ReportRol and (menu_id >= 2000) and menu_id not in (select distinct Parent from ccMenus where menu_id >= 2000 and type = 3)
						and (menu_id not in (3131,3132,3133,3134,3135,3136,8061,8062,8063,8071,8072,8080))
						or  (menu_id     in (3131,3132,3133,3134,3135,3136) and @MenusChat > 0 )
						or  (menu_id     in (8061,8062,8063,8071,8072,8080) and @AVRS > 0)
						or  (menu_id     in (9000,9010) and @MenuCRM > 0 )
						order by ordengral asc
						return(0)
					end
					else begin	
						select distinct Nivel, menu_descrip, menu_id,ordengral from ccmenus with(index(IX_ccMenus))
						where type = @ReportRol and (menu_id >= 2000) order by ordengral asc
						return(0)
					end
					
				end

				if @Type=2
				begin
				  delete from ccMenuUser where id_User = @id_User and id_Menu = @id_Menu and type = @ReportRol
				  return(0)
				end

				if @Type=3
				begin
				  insert into ccMenuUser(id_User,id_Menu,type) values (@id_User, @id_Menu,@ReportRol)
				  return(0)
				end

				if @Type=4
				begin
				  declare @lan varchar(3), @page varchar(200)
				  select @page = ''http://''+valor+''/'' from ccSettings where setting_id = 58
				  select @lan = case valor when 0 then ''ES'' else ''EN'' end from ccSettings where setting_id = 27
				  
				  select ''Help/''+@lan+''/''+ cast(@id_Menu as varchar)+''.swf'' HelpSWF, @page page, @lan lang
				  return(0)
				end

				set nocount off'
		else
			set @sql = ''

		EXEC(@sql)

		set @process = 'Alter Procedure -- ccsp_RIAChecaLogin'
		if exists (select * from sys.procedures where name = N'ccsp_RIAChecaLogin')
			set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAChecaLogin]
				@Login varchar(12),
				@Password varchar(40),
				@Computer varchar(20),
				@PasswordLwC varchar(40) = null
				AS
				declare @LoginOK tinyint, @PswdOK tinyint, @CompuOK tinyint, @ExtenOK tinyint, @TeclaOK tinyint, @XferAgents tinyint
				declare @Nombre varchar(60), @Extension varchar(15), @UserID smallint, @CCServer varchar(20)

				--Para posiciones ip, by ODC
				declare @ext_id int, @pos_id int, @isIP bit, @ipExtension varchar(15)

				-- Para live connected
				-- Tipo de conexion: 0 normal, 1 liveconnected
				declare @tipoConexion smallint

				SELECT @LoginOK=0, @PswdOK=0, @CompuOK=0, @ExtenOK=0, @TeclaOK=0, @XferAgents=0,
				 @Extension='' '', @UserID='' '', @Nombre='' '', @tipoConexion = 0, @ipExtension='''', @isIP=0
				SELECT @CCServer=valor FROM ccSettings WHERE setting_id=7

				IF not exists(select Login from ccUsers Where Login=@Login and status>0 and tipoUser_id=1)
					GOTO Mostrar
				else	
					set @LoginOK=1

				IF not exists(select Login from ccUsers Where Login = @Login
				 AND (Password=@Password OR Password = dbo.md5(@password) OR dbo.md5(Password)=@Password
				 or Password=@PasswordLwC OR Password = dbo.md5(@PasswordLwC) OR dbo.md5(Password)=@PasswordLwC) 
				 and status > 0 and tipoUser_id = 1)
					GOTO Mostrar
				else
					set @PswdOK=1

				-- Se actualiza a Lower Case
				update ccUsers with(rowlock) set Password=isnull(@PasswordLwC, Password) where Login=@Login and status>0 and tipoUser_id=1

				if not exists (select Computer from ccPosicion Where Status=1 and Computer=@Computer)
					insert ccposicion (computer, ext_id) select @Computer, 0

				set @CompuOK = 1

				if not exists(select Computer from ccPosicion P join ccMonitorExt M on P.ext_id= M.ext_id 
				 Where p.Status=1 and M.Status=1 and Computer=@Computer)
					GOTO Mostrar
				else
					set @ExtenOK=1

				select @Extension=Extension, @ext_id=p.ext_id, @pos_id=p.pos_id, @tipoConexion=p.tipoConexion, @isIP=isIP
				from ccPosicion P join  ccMonitorExt M on P.ext_id= M.ext_id
				Where Computer = @Computer

				select @TeclaOK=count(*) from ccTeclaExtensionPuerto T join ccMonitorExt M on T.ext_id=M.ext_id where M.Extension=@Extension

				select @UserID=user_id, @Nombre=Nombres + '' '' + isnull(ApellidoPaterno,'''') + '' '' +isnull(ApellidoMaterno,''''), @XferAgents=XferAgents
				from ccUsers Where Login = @Login AND TipoUser_id=1 AND status = 1

				Mostrar:
				--Para posiciones ip, by ODC 
				-- No verifica ccTeclaExtensionPuerto, @TeclaOK =1 
				-- Regresa un etension ''virtual''.  Debe ser diferente a cualquiera de ccMonitorExt.Extension
				IF @ext_id=0
				 BEGIN
					select @TeclaOK =1, @Extension=cast(@pos_id * -1 as varchar(15))
				 END

				---Por OAYC IPExtension, extension, para cuando es posición IP con alguna extension asignada
				IF(@ext_id > 0  and @isIP=1)
				 BEGIN
					select @TeclaOK =1, @ipExtension = @Extension, @Extension = cast( @pos_id * -1 as varchar(15))
				 END
				-----------

				IF @tipoConexion = 1
					select @TeclaOK =1

				--	CRMx
				DECLARE @crmxActive TINYINT
				SET @crmxActive = 0
				IF (SELECT COUNT(setting_id) FROM ccsettings WHERE setting_id = 168) = 1
					BEGIN
						SELECT @crmxActive = valor FROM ccsettings WHERE setting_id = 168
					END


				SELECT ''LoginOK''=@LoginOK, ''PswdOK''=@PswdOK, ''CompuOK''= @CompuOK, ''ExtenOK''=@ExtenOK, ''Extension''=@Extension, ''UserID''=@UserID, ''Nombre''=@Nombre, ''CCServer''=@CCServer, ''TeclaOK''=@TeclaOK, ''TipoConexion'' = @tipoConexion, ''ipExtension'' = @ipExtension, ''XferAgents'' = @XferAgents, ''CRMx'' = @crmxActive'
		else
			set @sql = ''

		EXEC(@sql)

		set @process = 'Alter Procedure -- ccsp_RIAConfEspec'
		if exists (select * from sys.procedures where name = N'ccsp_RIAConfEspec')
			set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec] 
				@User_id int 
				AS 
				set nocount on

				declare @sql nvarchar(max)

				if not exists (SELECT * FROM sysobjects WHERE type = ''U'' AND name = ''ContactMeanIn'') begin
					set @sql=''select A.inbound_id, A.Descripcion, A.Status, A.tNotas,
				A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd, 
				A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
				A.OpriorityT, A.callerIdDesc, A.chat, A.inactiveChatTime, A.maxChats, A.chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
				A.startStopRecording,'''''''' as nameMail,'''''''' as conexionInfo,'''''''' as connUser,'''''''' as connPass,3 as numMessages,10 as timeAlertMessage, 0 as Active, 0 as answerTimeOut
				from ccInbound A where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (''+convert(nvarchar(max),@User_id)+'', 2))''	

				end
				else begin
					set @sql=''select A.inbound_id, A.Descripcion, A.Status, A.tNotas,
				A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd, 
				A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
				A.OpriorityT, A.callerIdDesc, A.chat, A.inactiveChatTime, A.maxChats, A.chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
				A.startStopRecording,isnull(B.name,'''''''') as nameMail,isnull(B.conexionInfo,'''''''') as conexionInfo,isnull(B.connUser,'''''''') as connUser,
				isnull(B.ConnPass,'''''''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage, isnull(B.IsActive,0) as Active, 0 as answerTimeOut
				from ccInbound A 
				left join ContactMeanIn B on A.inbound_id=B.inboundId
				where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (''+convert(nvarchar(max),@User_id)+'', 2))''
					end

				exec (@sql)

				return(0)
				set nocount off'
		else
			set @sql = ''

		EXEC(@sql)

		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version

		commit tran
		end try

		begin catch	

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + ' Error process: ' + @process + ' Line: ' + cast(error_line() as nvarchar) + ' Number: ' + cast(@@error as nvarchar) + ' Message: ' + error_message()
			RAISERROR(@errorGenerated, 11, 1)
		
		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ', version to release: ' + cast(@version as varchar(5))
	end

set nocount off

/**************************/
/***** GUIDE AND HELP *****/
/**************************/

/* IMPORTANT: Consider objects manipulation in the sequence exposed in order to get consistency in the script, uncommon objects are prior to common ones in case of exist except replication */

/***** Language Reference *****/
/*
DDL (Data Definition Language)
	* Create
	* Drop
	* Alter

DML (Data Manipulation Language)
	* Select
	* Update
	* Delete
	* Insert

Contraint Object Types
	* C = CHECK constraint
	* D = DEFAULT (constraint or stand-alone)
	* F = FOREIGN KEY constraint
	* PK = PRIMARY KEY constraint
	* R = Rule (old-style, stand-alone)
	* UQ = UNIQUE constraint

Function Object Types
	* FN Scalar function
	* IF Inline table-valued function
	* TF Table-valued-function
	* FS Assembly (CLR) scalar-function
	* FT Assembly (CLR) table-valued function
*/

/***** Most common objects *****/
/* 
TABLES
-- When table exists
if exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

-- When table does not exists
if not exists (select * from sys.tables where name = N'yourTableName')
	begin
		Use DDL or DML as you need
	end

COLUMNS
-- When column exists
if exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When column does not exists
if not exists (select * from sys.columns where name = N'yourColumnName' and Object_ID = Object_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

CONSTRAINTS
-- When constraint exists
if exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not exists
if not exists (select * from sysobjects where xtype in (N'C', N'D', N'F', N'PK', N'R', N'UQ') and name = N'yourConstraintName')
	begin
		Use DDL or DML as you need
	end

-- When constraint primariy key 
if exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''yourTableName'') 
	begin
		Use DDL or DML as you need
	end

-- When constraint does not primariy key 
if not exists (select o.* from sys.objects o INNER JOIN sys.schemas s on o.schema_id = s.schema_id  where o.Type = ''PK'' and OBJECT_NAME(o.parent_object_id) = ''yourTableName'') 
	begin
		Use DDL or DML as you need
	end

-- When constraint does not foreign key 
if exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''yourTableName'' and  c1.[name]=''yourColumnName'')
	begin
		Use DDL or DML as you need
	end

-- When constraint does not foreign key 
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''yourTableName'' and  c1.[name]=''yourColumnName'')
	begin
		Use DDL or DML as you need
	end

INDEXES
-- When index exists
if exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When index does not exists
if not exists (select * from sys.indexes where name = N'yourIndexName' and object_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

TRIGGERS
-- When trigger exists
if exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

-- When trigger does not exists
if not exists (select * from sys.triggers where name = N'yourTriggerName' and parent_id = OBJECT_ID(N'yourTableName'))
	begin
		Use DDL or DML as you need
	end

FUNCTIONS
-- When function exists
if exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

-- When function does not exists
if not exists (select * from sys.objects where object_id = OBJECT_ID(N'yourFunctionName') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	begin
		Use DDL or DML as you need
	end

STORED PROCEDURES
-- When stored procedure exists
if exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

-- When stored procedure does not exists
if not exists (select * from sys.procedures where name = N'yourStoreProcedureName')
	begin
		Use DDL or DML as you need
	end

VIEWS
-- When view exists
if exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

-- When view does not exists
if not exists (select * FROM sys.views where name = N'yourViewName')
	begin
		Use DDL or DML as you need
	end

JOBS (In this case be careful about what to do)
-- if you want to create, modify or delete use the script below
if exists (select * from msdb.dbo.sysjobs_view where name = N'yourJobName')
	begin
		exec msdb.dbo.sp_delete_job @job_name = N'yourJobName', @delete_unused_schedule=1
	end

-- After that, you could run the script to create the Job despite of being new or being modified
*/

/***** Uncommon objects *****/
/*
DATABASES
-- When database exists
if exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

-- When database does not exists
if not exists (select * from master.sys.databases where name = N'yourDatabaseName')
	begin
		Use DDL or DML as you need
	end

LOGINS
-- When login exists
if exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

-- When login does not exists
if not exists (select * from master.sys.syslogins where name = N'yourUserName')
	begin
		Use DDL or DML as you need
	end

SERVER ROLES
-- When server role exists
if exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

-- When server role does not exists
if not exists (select * from sys.database_principals where name = N'yourRoleName' and Type = N'R')
	begin
		Use DDL or DML as you need
	end

SCHEMAS
-- When schema exists
if exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

-- When schema does not exists
if not exists (select * from sys.schemas where name = N'yourSchemaName')
	begin
		Use DDL or DML as you need
	end

Replication
-- Replication scripts are generated apart so you have to check them and consider the validations implemented on those scripts
	* Publications
	* Subscriptions on publisher
	* Subscriptions
	* Snapshots
*/