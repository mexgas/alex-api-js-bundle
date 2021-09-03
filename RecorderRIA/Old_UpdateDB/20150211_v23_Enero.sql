/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/* 
Author: Raymundo Gonzalez
Date: 2015/02/011
Description: Finder AVRS

	se crea tabla RIA_FORMACALIF_CHAT
	se crea tabla RIA_RESULTADOSFORMA_CHAT
	Se crea la tabla RIA_RecNode para almacenamiento de registros de las grabaciones para Finder
	Se crea la tabla ccCRMNodes para guardar datos de CRM en caso de existir

	Add  column tipo en RIA_FORMATOS 
	Add  colum tipo,tipo_llamada,cam_id en RIA_FORMACALIF
	Add  column video en ria_grabacion
	Add  column video en ria_grabacionConsulta

	Se crean los indices IX_dateIn, IX_dateOut, e IX_status en la tabla RIA_RecNode
	Se crea el indice IX_grabId en la tabla ccCRMNodes	

	Se crea funcion fn_RIASplitDelimited

	Se crea SP trsp_AdmVerifyMarksToExport2
	Se crea SP trsp_AdmRecSearchRecs
	Se crea SP trsp_AdmGetRecExportProfile
	Se crea SP trsp_AdmGetMarkTimeToCut2
	Se crea SP trsp_AdmGetExportFields
	Se crea SP trsp_SaveScoresFormaCalifChat
	Se crea SP trsp_SaveScoresResultFormaChat
	Se crea SP trsp_AdmGetNumericAnswerChat
	Se crea SP trsp_AdmGetQualityTemplateScored
	Se crea SP trsp_AdmVerifyingChatFormatEditing
	Se crea SP trsp_AdmUpdateSaveChatScores
	Se crea SP trsp_AdmSaveChatScoresFormaCalif
	Se crea SP trsp_AdmGetChatInfoFormatScored	
	Se crea SP trsp_AdmGetSatisfactionScore
	Se crea el SP ccsp_BaseXmngr para administracion de registros de BaseX
	Se crea el SP trsp_InsertRecNode para insertar nodos XML de chat para Finder
	Se crea el SP trsp_UpdateShoutDetection
	Se crea el SP ccsp_AdmGetAgentIdOnChat
	Se crea el SP trsp_GetTemplateandSupervisor
	Se crea el SP trsp_AdmRecSearchANI para busqueda por ANI en Finder 1.0

	Se actualiza el SP trsp_AdmSaveQualityFormats para diferencia entre formatos para Formatos de Calidad y Encuestas de Satisfaccion
	se Actualiza el SP trsp_AdmGetQualityDiferentFormats
	Se Actualiza el SP trsp_AdmGetQualityAnswersScored
	se Actualiza el SP trsp_AdmVerifyingFormatEditing
	Se actualiza el SP trsp_AdmSaveScoresFormaCalif para diferencia entre formatos para Formatos de Calidad y Encuestas de Satisfaccion
	Se Actualiza el SP trsp_AdmAVRSReportCallInfo
	Se Actualiza el SP trsp_AdmAVRSReportDemo
	Se Actualiza el SP trsp_AdmAVRSReportLanguage
	Se Actualiza el SP trsp_GetFilesAnalisisGritos
	Se Actualiza el SP trsp_AdmRecSearchNodeAgent para que muestre el nombre completo desde seccion de filtros de Finder 1.0

Database: CCRecorderRia
Required version: 22

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/

set nocount on

declare @version int
declare @actualVersion int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)

/* Version to release (use the version of your own databse)*/
set @version = 23

/* Actual version (use your own script to do it) */
set @actualVersion =  (select par_valor from trec_parametros where par_id = 30)

if @actualVersion = @version - 1
	begin
		begin tran
		begin try

	/* Start script release */
	set @process = 'CREATE TABLE -  RIA_FORMACALIF_CHAT'
	set @sql='if not exists (select * from sys.tables where name = N''RIA_FORMACALIF_CHAT'')
	begin
		CREATE TABLE [dbo].[RIA_FORMACALIF_CHAT](
		[id_forma] [int] IDENTITY(1,1) NOT NULL,
		[fecha_calif] [smalldatetime] NOT NULL,
		[id_formato] [int] NOT NULL,
		[age_id] [int] NOT NULL,
		[version] [int] NOT NULL,
		[id_chat] [int] NULL,
		[total_forma] [int] NULL
		) ON [PRIMARY]
	end'
	EXEC(@sql)

	set @process = 'CREATE TABLE -  RIA_RESULTADOSFORMA_CHAT'
	set @sql='if not exists (select * from sys.tables where name = N''RIA_RESULTADOSFORMA_CHAT'')
		begin
		CREATE TABLE [dbo].[RIA_RESULTADOSFORMA_CHAT](
		[id_forma] [int] NOT NULL,
		[id_pregunta] [int] NOT NULL,
		[id_respuesta] [int] NOT NULL,
		[etiquetas] [varchar](max) NOT NULL,
		[peso] [int] NULL
		) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
		end'
	EXEC(@sql)

	set @process = 'RIA_RecNode - Create Table'
	set @sql='if not exists (select * from sys.tables where name = N''RIA_RecNode'')
	begin
	create table RIA_RecNode(
			  [grab_id] [bigint] primary key NOT NULL,
			  [node] [xml] NULL,
			  [dateIn] [datetime] NULL,
			  [dateOut] [datetime] NULL,
			  [status] [tinyint] NULL
		)
	end'
			
	EXEC(@sql)

	set @process = 'ccCRMNodes - Create Table'
	set @sql = 'if not exists (select * from sys.tables where name = N''ccCRMNodes'')
	begin
	create table ccCRMNodes(
		[cal_id] [int] NOT NULL,
		[type] [int] NOT NULL,
		[grab_id] [bigint] NULL,
		[node] [xml] NOT NULL
		foreign key (grab_id) references RIA_RecNode(grab_id) on delete cascade
		)
	end'
	EXEC(@sql)

	set @process = 'add colum - RIA_FORMATOS'
	set @sql='if not exists (select * from sys.columns where name = N''tipo'' and Object_ID = Object_ID(N''RIA_FORMATOS''))
	ALTER TABLE RIA_FORMATOS ADD tipo INT NOT NULL DEFAULT 0'
	EXEC(@sql)

	set @process = 'add colum - RIA_FORMACALIF'
	set @sql='if not exists (select * from sys.columns where name = N''tipo'' and Object_ID = Object_ID(N''RIA_FORMACALIF'')) ALTER TABLE RIA_FORMACALIF ADD tipo smallint NOT NULL DEFAULT 0
		if not exists (select * from sys.columns where name = N''tipo_llamada'' and Object_ID = Object_ID(N''RIA_FORMACALIF'')) ALTER TABLE RIA_FORMACALIF ADD tipo_llamada smallint NOT NULL DEFAULT 0
		if not exists (select * from sys.columns where name = N''cam_id'' and Object_ID = Object_ID(N''RIA_FORMACALIF'')) ALTER TABLE RIA_FORMACALIF ADD cam_id smallint NOT NULL DEFAULT 0'
	EXEC(@sql)

	set @process = 'add colum - ria_grabacion'
	set @sql='if not exists (select * from sys.columns where name = N''video'' and Object_ID = Object_ID(N''ria_grabacion''))  ALTER TABLE ria_grabacion ADD video INT NOT NULL DEFAULT 0'
	EXEC(@sql)

	set @process = 'add colum - ria_grabacionConsulta'
	set @sql='if not exists (select * from sys.columns where name = N''video'' and Object_ID = Object_ID(N''ria_grabacionConsulta'')) ALTER TABLE ria_grabacionConsulta ADD video INT NOT NULL DEFAULT 0'
	EXEC(@sql)

	set @process = 'RIA_RecNode - Create Indexes'
	set @sql='if not exists (select * from sys.indexes where name = N''IX_dateIn'' and object_id = OBJECT_ID(N''RIA_RecNode'')) create nonclustered index IX_dateIn on RIA_RecNode(dateIn desc)
			  if not exists (select * from sys.indexes where name = N''IX_dateOut'' and object_id = OBJECT_ID(N''RIA_RecNode'')) create nonclustered index IX_dateOut on RIA_RecNode(dateOut desc)
			  if not exists (select * from sys.indexes where name = N''IX_status'' and object_id = OBJECT_ID(N''RIA_RecNode'')) create nonclustered index IX_status on RIA_RecNode([status] desc)'
	EXEC(@sql)
				
	set @process = 'ccCRMNodes - Create Index'
	set @sql = 'if not exists (select * from sys.indexes where name = N''IX_dateIn'' and object_id = OBJECT_ID(N''ccCRMNodes'')) create nonclustered index IX_grabId on ccCRMNodes(grab_id desc)'		
	EXEC(@sql)

	set @process = 'Drop function -- fn_RIASplitDelimited'
	set @sql='if exists (select * from sys.objects where object_id = OBJECT_ID(N''fn_RIASplitDelimited'') and type in (N''FN'', N''IF'', N''TF'', N''FS'', N''FT''))
				DROP FUNCTION dbo.fn_RIASplitDelimited'
	EXEC(@sql)

	
	set @process = 'Genereate info baseX '
	set @sql='	declare @from datetime,@day int


	declare @grabId int 
	declare @callType as nvarchar(20)	
	declare @language as int
	declare @shoutLevel as nvarchar(20)	
	declare @start as int
	declare @xml as xml
	declare @rating as nvarchar(20)
		
	select @day=valor from ccsettings where setting_id=159
	set @from =DATEADD(dd,-@day,getdate())
	
	--Get languange
	select @language = case when valor in (''0'',''1'') then valor else 0 end from ccSettings where setting_id = 27
	

	create table #tempRecNode(
		C01 bigint not null,
		C02 varchar(30) not null,
		C03 varchar(50) not null,
		C04 varchar(40) not null,
		C05 varchar(20) not null,
		C06 varchar(23) not null,
		C07 varchar(20) not null,
		C08 int not null,
		C09 varchar(15) not null,
		C10 varchar(15) not null,
		C11 varchar(20) not null,
		C12 varchar(20) not null,
		C13 varchar(MAX) not null,
		C14 varchar(MAX) not null,
		C15 varchar(MAX) not null,
		C16 varchar(MAX) not null,
		C17 varchar(MAX) not null,
		C18 varchar(MAX) not null,
		C19 varchar(MAX) not null,
		C20 varchar(MAX) not null,
		C21 varchar(MAX) not null,
		C22 varchar(MAX) not null,
		C23 varchar(MAX) not null,
		C24 varchar(MAX) not null,
		C25 varchar(MAX) not null
	)


	insert into #tempRecNode
	select rec.grab_id C01, ''Inbound'' C02, inb.descripcion C03,
	case when  @language = 0 then substring(sho.nombre_nivel,0,charindex(''|'',@shoutLevel))  else substring(sho.nombre_nivel,charindex(''|'',sho.nombre_nivel)+1,len(sho.nombre_nivel)-1) end C04,
	usr.Login C05, convert(varchar(23), finicio, 126) C06,
				   pos.Computer C07, rec.duracion C08,rec.ani C09, rec.dni C10, rec.cal_key C11,case when cal_manual = 0 then ''N/A'' else ''Manual'' end C12,
				   usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.Inbound_id as ''@C15'',
									CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
									+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
									isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(calif.total_forma,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
									isnull(CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
									usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',isnull(sup.Nombres + '' '' + sup.ApellidoPaterno + '' '' + sup.ApellidoMaterno,'''') as ''@C24'',isnull(formatos.nombre,'''') as ''@C25''
			from RIA_GRABACION rec with(nolock)
			inner join ccinbound inb on rec.cam_id = inb.Inbound_id
			inner join ccUsers usr on usr.User_id = rec.age_id
			inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
			inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1			
			left  join ria_formacalif calif on calif.id_grabacion = rec.grab_id
			left join ccTipoCalifOUT  e ON rec.calif_id = e.calif_id 
			left join ccTipoCalif  f ON rec.calif_id = f.calif_id
			left join RIA_FORMATOS formatos on formatos.id_formato=calif.id_formato
			inner join ccUsers sup on sup.User_id = calif.id_supervisor
			where  rec.tipo_llamada = 1 and calif.tipo = 1
			and finicio>= @from
	union
	select rec.grab_id C01, ''Inbound'' C02, inb.descripcion C03,
	case when  @language = 0 then substring(sho.nombre_nivel,0,charindex(''|'',@shoutLevel))  else substring(sho.nombre_nivel,charindex(''|'',sho.nombre_nivel)+1,len(sho.nombre_nivel)-1) end C04,
	usr.Login C05, convert(varchar(23), finicio, 126) C06,
				   pos.Computer C07, rec.duracion C08,rec.ani C09, rec.dni C10, rec.cal_key C11,case when cal_manual = 0 then ''N/A'' else ''Manual'' end C12,
				    usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.Inbound_id as ''@C15'',
									CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
									+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
									isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(calif.total_forma,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
									isnull(CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
									usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',isnull(sup.Nombres + '' '' + sup.ApellidoPaterno + '' '' + sup.ApellidoMaterno,'''') as ''@C24'',isnull(formatos.nombre,'''') as ''@C25''
			from RIA_GRABACIONCONSULTA rec with(nolock)
			inner join ccinbound inb on rec.cam_id = inb.Inbound_id
			inner join ccUsers usr on usr.User_id = rec.age_id
			inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
			inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1			
			left  join ria_formacalif calif on calif.id_grabacion = rec.grab_id
			left join ccTipoCalifOUT  e ON rec.calif_id = e.calif_id 
			left join ccTipoCalif  f ON rec.calif_id = f.calif_id
			left join RIA_FORMATOS formatos on formatos.id_formato=calif.id_formato
			inner join ccUsers sup on sup.User_id = calif.id_supervisor
			where  rec.tipo_llamada = 1 and calif.tipo = 1
			and finicio>= @from


	insert into #tempRecNode
	select rec.grab_id C01, ''Outbound'' C02, inb.cam_descripcion C03, 
		case when  @language = 0 then substring(sho.nombre_nivel,0,charindex(''|'',@shoutLevel))  else substring(sho.nombre_nivel,charindex(''|'',sho.nombre_nivel)+1,len(sho.nombre_nivel)-1) end C04,
		usr.Login C05, convert(varchar(23), finicio, 126) C06,
		pos.Computer C07, rec.duracion C08,rec.ani C09, rec.dni C10, rec.cal_key C11, case when cal_manual = 0 then ''N/A'' else ''Manual'' end C12,
				   usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
									CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
									+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
									isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(calif.total_forma,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
									isnull(CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
									usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',isnull(sup.Nombres + '' '' + sup.ApellidoPaterno + '' '' + sup.ApellidoMaterno,'''') as ''@C24'',isnull(formatos.nombre,'''') as ''@C25''
			from RIA_GRABACION rec with(nolock)
			inner join cccamps inb on rec.cam_id = inb.cam_id
			inner join ccUsers usr on usr.User_id = rec.age_id
			inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
			inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1			
			left  join ria_formacalif calif on calif.id_grabacion = rec.grab_id
			left join ccTipoCalifOUT  e ON rec.calif_id = e.calif_id 
			left join ccTipoCalif  f ON rec.calif_id = f.calif_id
			left join RIA_FORMATOS formatos on formatos.id_formato=calif.id_formato
			inner join ccUsers sup on sup.User_id = calif.id_supervisor
			where  rec.tipo_llamada = 2 and calif.tipo = 1
			and finicio>= @from
	union
	select rec.grab_id C01, ''Outbound'' C02, inb.cam_descripcion C03, 
		case when  @language = 0 then substring(sho.nombre_nivel,0,charindex(''|'',@shoutLevel))  else substring(sho.nombre_nivel,charindex(''|'',sho.nombre_nivel)+1,len(sho.nombre_nivel)-1) end C04,
		usr.Login C05, convert(varchar(23), finicio, 126) C06,
		pos.Computer C07, rec.duracion C08,rec.ani C09, rec.dni C10, rec.cal_key C11, case when cal_manual = 0 then ''N/A'' else ''Manual'' end C12,
				   usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
									CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
									+ '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
									isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(calif.total_forma,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
									isnull(CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END,'''') AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
									usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',isnull(sup.Nombres + '' '' + sup.ApellidoPaterno + '' '' + sup.ApellidoMaterno,'''') as ''@C24'',isnull(formatos.nombre,'''') as ''@C25''
			from RIA_GRABACION rec with(nolock)
			inner join cccamps inb on rec.cam_id = inb.cam_id
			inner join ccUsers usr on usr.User_id = rec.age_id
			inner join RIA_TIPO_GRITOS sho on rec.id_nivel_grito = sho.id_nivel_grito
			inner join ccPosicion pos on pos.pos_id = rec.cal_extension * -1			
			left  join ria_formacalif calif on calif.id_grabacion = rec.grab_id
			left join ccTipoCalifOUT  e ON rec.calif_id = e.calif_id 
			left join ccTipoCalif  f ON rec.calif_id = f.calif_id
			left join RIA_FORMATOS formatos on formatos.id_formato=calif.id_formato
			inner join ccUsers sup on sup.User_id = calif.id_supervisor
			where  rec.tipo_llamada = 2 and calif.tipo = 1
			and finicio>= @from

	insert into ria_RecNode (grab_id, node, dateIn,status) 
	select C01,
		convert(xml,''<R02 C01="''+convert(varchar(max),C01)+''" C02="''+convert(varchar(max),C02)+''" C03="''+convert(varchar(max),C03)+''" C04="''+
			convert(varchar(max),C04)+''" C05="''+convert(varchar(max),C05)+''" C06="''+convert(varchar(max),C06)+''" C07="''+convert(varchar(max),C07)
			+''" C08="''+convert(varchar(max),C08)+''" C09="''+convert(varchar(max),C09)+''" C10="''+convert(varchar(max),C10)+''" C11="
			''+convert(varchar(max),C11)+''" C12="''+convert(varchar(max),C12)+''" C13="''+convert(varchar(max),C13)
			+''" C14="''+convert(varchar(max),C14)+''" C15="''+convert(varchar(max),C15)+''" C16="''+convert(varchar(max),C16)
			+''" C17="''+convert(varchar(max),C17)+''" C18="''+convert(varchar(max),C18)+''" C19="''+convert(varchar(max),C19)
			+''" C20="''+convert(varchar(max),C20)+''" C21="''+convert(varchar(max),C21)+''" C22="''+convert(varchar(max),C22)
			+''" C23="''+convert(varchar(max),C02)+''" C24="''+convert(varchar(max),C02)+''" C25="''+convert(varchar(max),C02)+ ''" />'') node,getdate() dateIn,0 status 
	
	from #tempRecNode order by C01
		
	drop table #tempRecNode'
	EXEC(@sql)


	set @process = 'Create function -- fn_RIASplitDelimited'
	if not exists (select * from sys.objects where object_id = OBJECT_ID(N'fn_RIASplitDelimited') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
		set @sql='CREATE FUNCTION [dbo].[fn_RIASplitDelimited]
			(	
				@List nvarchar(2000),
				@SplitOn nvarchar(1)
			)
			RETURNS @RtnValue table (
				Id int identity(1,1),
				Value nvarchar(100)
			)
			AS
			BEGIN
				While (Charindex(@SplitOn,@List)>0)
				Begin 
					Insert Into @RtnValue (value)
					Select 
						Value = ltrim(rtrim(Substring(@List,1,Charindex(@SplitOn,@List)-1))) 
					Set @List = Substring(@List,Charindex(@SplitOn,@List)+len(@SplitOn),len(@List))
				End 
				
				Insert Into @RtnValue (Value)
			    Select Value = ltrim(rtrim(@List))

			    Return
			END'
	else
		set @sql = ''
	
	EXEC(@sql)

	set @process = 'trsp_SaveScoresFormaCalifChat - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_SaveScoresFormaCalifChat'') DROP PROCEDURE trsp_SaveScoresFormaCalifChat'
	EXEC(@sql)

	set @process = 'trsp_SaveScoresResultFormaChat - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_SaveScoresResultFormaChat'') DROP PROCEDURE trsp_SaveScoresResultFormaChat'
	EXEC(@sql)

	set @process = 'trsp_AdmGetNumericAnswerChat - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmGetNumericAnswerChat'') DROP PROCEDURE trsp_AdmGetNumericAnswerChat'
	EXEC(@sql)

	set @process = 'trsp_AdmVerifyingChatFormatEditing - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmVerifyingChatFormatEditing'') DROP PROCEDURE trsp_AdmVerifyingChatFormatEditing'
	EXEC(@sql)

	set @process = 'trsp_AdmUpdateSaveChatScores - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmUpdateSaveChatScores'') DROP PROCEDURE trsp_AdmUpdateSaveChatScores'
	EXEC(@sql)

	set @process = 'trsp_AdmSaveChatScoresFormaCalif - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmSaveChatScoresFormaCalif'') DROP PROCEDURE trsp_AdmSaveChatScoresFormaCalif'
	EXEC(@sql)

	set @process = 'trsp_AdmGetSatisfactionScore - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmGetSatisfactionScore'') DROP PROCEDURE trsp_AdmGetSatisfactionScore'
	EXEC(@sql)

	set @process = 'trsp_AdmGetChatInfoFormatScored - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmGetChatInfoFormatScored'') DROP PROCEDURE trsp_AdmGetChatInfoFormatScored'
	EXEC(@sql)	

	set @process = 'trsp_AdmGetExportFields - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmGetExportFields'') DROP PROCEDURE trsp_AdmGetExportFields'
	EXEC(@sql)

	set @process = 'trsp_AdmGetMarkTimeToCut2 - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmGetMarkTimeToCut2'') DROP PROCEDURE trsp_AdmGetMarkTimeToCut2'
	EXEC(@sql)

	set @process = 'trsp_AdmGetRecExportProfile - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmGetRecExportProfile'') DROP PROCEDURE trsp_AdmGetRecExportProfile'
	EXEC(@sql)

	set @process = 'trsp_AdmRecSearchRecs - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmRecSearchRecs'') DROP PROCEDURE trsp_AdmRecSearchRecs'
	EXEC(@sql)

	set @process = 'trsp_AdmVerifyMarksToExport2 - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmVerifyMarksToExport2'') DROP PROCEDURE trsp_AdmVerifyMarksToExport2'
	EXEC(@sql)

	set @process = 'ccsp_BaseXmngr - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''ccsp_BaseXmngr'') DROP PROCEDURE ccsp_BaseXmngr'
	EXEC(@sql)

	set @process = 'trsp_InsertRecNode - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_InsertRecNode'') DROP PROCEDURE trsp_InsertRecNode'
	EXEC(@sql)

	set @process = 'trsp_UpdateShoutDetection - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_UpdateShoutDetection'') DROP PROCEDURE trsp_UpdateShoutDetection'
	EXEC(@sql)

	set @process = 'ccsp_AdmGetAgentIdOnChat - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''ccsp_AdmGetAgentIdOnChat'') DROP PROCEDURE ccsp_AdmGetAgentIdOnChat'
	EXEC(@sql)

	set @process = 'trsp_GetTemplateandSupervisor - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_GetTemplateandSupervisor'') DROP PROCEDURE trsp_GetTemplateandSupervisor'
	EXEC(@sql)

	set @process = 'trsp_AdmRecSearchANI - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmRecSearchANI'') DROP PROCEDURE trsp_AdmRecSearchANI'
	EXEC(@sql)

	set @process = 'trsp_FinderCRMNode - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_FinderCRMNode'') DROP PROCEDURE trsp_FinderCRMNode'
	EXEC(@sql)

	set @process = 'trsp_AdmUpdateSaveScores - Drop if exists'
	set @sql='if exists (select * from sys.procedures where name = N''trsp_AdmUpdateSaveScores'') DROP PROCEDURE trsp_AdmUpdateSaveScores'
	EXEC(@sql)

	set @process = 'Create stored -- trsp_FinderCRMNode'
	if not exists (select * from sys.procedures where name = N'trsp_FinderCRMNode')
		set @sql='CREATE PROCEDURE  [dbo].[trsp_FinderCRMNode]
			@cal_id int,@type int,@node xml

			AS
			BEGIN
			---Type 1 In 2 Out
			if not exists(select * from ccCRMNodes where cal_id=@cal_id and type=@type)
				insert into ccCRMNodes (cal_id,type,node) values(@cal_id,@type,@node)
			else 
				update ccCRMNodes  set node=@node where cal_id=@cal_id and type=@type

			END'
	else
		set @sql = ''
	
	EXEC(@sql)

	set @process = 'Create stored -- trsp_AdmVerifyMarksToExport2'
	if not exists (select * from sys.procedures where name = N'trsp_AdmVerifyMarksToExport2')
		set @sql='CREATE PROCEDURE  [dbo].[trsp_AdmVerifyMarksToExport2]
			@grabIds nvarchar(max)

			AS
			BEGIN
			declare @sql nvarchar(max)
						
			set @sql=''select count(*) from (select * from RIA_Grabacion where grab_id in(''+@grabids +'') 
			 union select * from RIA_GrabacionConsulta where grab_id in(''+@grabids +'')) A 
			 inner join RIA_MARCAS B on B.tipo_llamada = A.tipo_llamada and B.call_Id=A.cal_id''
			 --print (@sql)
			 exec(@sql)

			END'
	else
		set @sql = ''
	
	EXEC(@sql)

	set @process = 'Create stored -- trsp_AdmRecSearchRecs'
	if not exists (select * from sys.procedures where name = N'trsp_AdmRecSearchRecs')
		set @sql='CREATE PROCEDURE [dbo].[trsp_AdmRecSearchRecs]
			@grabIds nvarchar(max)

			AS
			BEGIN

				
			SET NOCOUNT ON

			declare @sql nvarchar(max)
			declare @isEncrypted bit

			select @isEncrypted=par_valor from TREC_PARAMETROS where par_id=15

					
			select id_repositorio, ruta_repositorio 
			into #tmpRepositorios
			from TREC_REPOSITORIOS 
			where id_repositorio = (select id_repository from TREC_REPO_NWCREDENTIALS where TREC_REPO_NWCREDENTIALS.id_nwCredential = 
				(select id from RIA_NETWORKCREDENTIALS where RIA_NETWORKCREDENTIALS.type = 1)) order by id_repositorio

				
			set @sql=''select a.grab_id as grabID,a.cal_id, a.Tipo_llamada, a.id_repositorio,b.ruta_repositorio as repository,
				case a.Tipo_llamada when 2 then ''''OUTBOUND\'''' else ''''INBOUND\'''' end + cast(floor(a.cal_id/1000) as nvarchar(max)) as subpath,
				case a.Tipo_llamada when 2 then ''''O_'''' else ''''I_'''' end + cast(a.cal_id as nvarchar(max)) + ''''.wav'''' 
				+ case ''+cast(@isEncrypted as nvarchar(max)) +'' when 1 then ''''.enc'''' else '''''''' end  fileAudio
				from RIA_GRABACION a
				inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio 
				where a.grab_id in(''+@grabIds+'')	
				union
				select a.grab_id as grabID,a.cal_id, a.Tipo_llamada, a.id_repositorio,b.ruta_repositorio as repository,
				case a.Tipo_llamada when 2 then ''''OUTBOUND\'''' else ''''INBOUND\'''' end + cast(floor(a.cal_id/1000) as nvarchar(max)) as subpath,
				case a.Tipo_llamada when 2 then ''''O_'''' else ''''I_'''' end + cast(a.cal_id as nvarchar(max)) + ''''.wav'''' 
				+ case ''+cast(@isEncrypted as nvarchar(max)) +'' when 1 then ''''.enc'''' else '''''''' end  fileAudior
				from RIA_GRABACIONCONSULTA a
				inner join #tmpRepositorios b on a.	id_repositorio = b.id_repositorio 
				where a.grab_id in(''+@grabIds+'')''

			exec (@sql)			
															
			drop table #tmpRepositorios

			END'
	else
		set @sql = ''
	
	EXEC(@sql)


	set @process = 'Create stored -- trsp_AdmGetRecExportProfile'
	if not exists (select * from sys.procedures where name = N'trsp_AdmGetRecExportProfile')
		set @sql='CREATE PROCEDURE [dbo].[trsp_AdmGetRecExportProfile]
			@id_usuario int
			AS
			BEGIN
				SET NOCOUNT ON;
			select isnull(max(campos),'''') from CCRecorderRIA.dbo.RIA_PERFILES_EXPORTACION where id_usuario = @id_usuario and active =1
			END'
	else
		set @sql = ''

	EXEC(@sql)

	set @process = 'Create stored -- trsp_AdmGetMarkTimeToCut2'
	if not exists (select * from sys.procedures where name = N'trsp_AdmGetMarkTimeToCut2')
		set @sql='CREATE PROCEDURE [dbo].[trsp_AdmGetMarkTimeToCut2]
			@grabId bigint

			AS
			BEGIN

			declare @sql nvarchar(max)

				 set @sql=''select top 1 isnull(B.marca,''''00:00:00'''') from (select * from RIA_Grabacion where grab_id=''+cast(@grabId as nvarchar(max))
			 +''union select * from RIA_GrabacionConsulta where grab_id=''+cast(@grabId as nvarchar(max))
			 +'') A left join RIA_MARCAS B on B.tipo_llamada = A.tipo_llamada and B.call_Id=A.cal_id''
			 --print (@sql)
			 exec(@sql)

			END	'
	else
		set @sql = ''
	
	EXEC(@sql)

	set @process = 'Create stored -- trsp_AdmGetExportFields'
	if not exists (select * from sys.procedures where name = N'trsp_AdmGetExportFields')
		set @sql='CREATE PROCEDURE [dbo].[trsp_AdmGetExportFields]
			 @usuarioId int,@grabId bigint

			AS
			BEGIN

			SET NOCOUNT ON

			declare @campos nvarchar(max),@columns nvarchar(max),@sql nvarchar(max)

			select @campos=isnull(max(campos),'''') from RIA_PERFILES_EXPORTACION where id_usuario = @usuarioId and active =1

			select @columns = coalesce (@columns+'','', '''') + b.Campo from dbo.fn_RIASplitDelimited(@campos,'','') a
			 inner join TREC_FORM_ARCHIVOSEXPORT b on a.value=b.id

			 
			 set @sql=''select '' + @columns + '' from RIA_Grabacion where grab_id=''+cast(@grabId as nvarchar(max))
			 +''union select ''+@columns+'' from RIA_GrabacionConsulta where grab_id=''+cast(@grabId as nvarchar(max))
			 --print (@sql)
			 exec(@sql)

			END	'
	else
		set @sql = ''

	EXEC(@sql)

	set @process = 'CREATE stored - trsp_SaveScoresFormaCalifChat'
	if not exists (select * from sys.procedures where name = N'trsp_SaveScoresFormaCalifChat')
		set @sql='CREATE PROCEDURE [dbo].[trsp_SaveScoresFormaCalifChat]
			@id_formato int,
			@total_weight int,
			@age_id int,
			@version int,
			@id_chat int

			AS

			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

			Insert CCRecorderRIA.dbo.RIA_FORMACALIF_CHAT (fecha_calif,id_formato,age_id,version,id_chat, total_forma)
			values
			(GetDate(),@id_formato,@age_id,@version,@id_chat, @total_weight)

			select Scope_Identity()

			END'
	else
		set @sql = ''

	EXEC(@sql)

	set @process = 'CREATE stored - trsp_SaveScoresResultFormaChat'
	if not exists (select * from sys.procedures where name = N'trsp_SaveScoresResultFormaChat')
		set @sql='CREATE  PROCEDURE [dbo].[trsp_SaveScoresResultFormaChat]
			@id_format int,
			@id_question int,
			@id_answer int,
			@answer_weight int,
			@label nvarchar(MAX)

			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

			Insert CCRecorderRIA.dbo.RIA_RESULTADOSFORMA_CHAT (id_forma,id_pregunta,id_respuesta,etiquetas,peso)
			values(@id_format,@id_question, @id_answer,@label,@answer_weight)

			END'
	else
		set @sql = ''

	EXEC(@sql)

	set @process = 'CREATE stored - trsp_AdmGetNumericAnswerChat'
	if not exists (select * from sys.procedures where name = N'trsp_AdmGetNumericAnswerChat')
		set @sql='CREATE  PROCEDURE [dbo].[trsp_AdmGetNumericAnswerChat]
			@id_formato int,
			@version int,
			@id_pregunta int,
			@id_chat int

			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here
			declare @id_forma as int

			set @id_forma = (select id_forma from CCRecorderRIA.dbo.RIA_FORMACALIF where version = @version and id_grabacion = @id_chat and id_formato = @id_formato and tipo=2)

			select ISNULL(peso,0) from CCRecorderRIA.dbo.RIA_RESULTADOSFORMA where id_forma = @id_forma and id_pregunta = @id_pregunta

			END'
	else
		set @sql = ''

	EXEC(@sql)

	set @process = 'CREATE stored - trsp_AdmGetQualityTemplateScored'
	if not exists (select * from sys.procedures where name = N'trsp_AdmGetQualityTemplateScored')
		set @sql='CREATE PROCEDURE [dbo].[trsp_AdmGetQualityTemplateScored]
			@id_chat int,
			@id_formato int
			AS
			BEGIN
				SET NOCOUNT ON;
				select total_forma from [dbo].[RIA_FORMACALIF] where id_grabacion = @id_chat AND tipo=2 AND id_formato=@id_formato
			END'
	else
		set @sql = ''

	EXEC(@sql)

	set @process = 'CREATE stored - trsp_AdmVerifyingChatFormatEditing'
	if not exists (select * from sys.procedures where name = N'trsp_AdmVerifyingChatFormatEditing')
		set @sql='CREATE PROCEDURE [dbo].[trsp_AdmVerifyingChatFormatEditing]
			@id_chat int,
			@id_formato int


			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			declare @grab_id int,
			@id_forma int

			    -- Insert statements for procedure here

			set @id_forma = (Select isnull(id_forma,0) from CCRecorderRIA.dbo.RIA_FORMACALIF where id_grabacion = @id_chat and id_formato = @id_formato and tipo=2)


			--Retrieving the id forma
			select isnull(@id_forma,0)

			END'
	else
		set @sql = ''

	EXEC(@sql)

	set @process = 'CREATE stored - trsp_AdmUpdateSaveChatScores'
	if not exists (select * from sys.procedures where name = N'trsp_AdmUpdateSaveChatScores')
		set @sql='CREATE PROCEDURE [dbo].[trsp_AdmUpdateSaveChatScores]
			@id_forma int,
			@id_chat int,
			@id_calificador int,
			@id_supervisor int,
			@id_formato int,
			@total_forma int,
			@version int


			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

			Delete from CCRecorderRIA.dbo.RIA_RESULTADOSFORMA where id_forma = @id_forma

			Update CCRecorderRIA.dbo.RIA_FORMACALIF 
			set fecha_calif = GetDate(), id_calificador=@id_calificador,id_supervisor=@id_supervisor,total_forma=@total_forma, version=@version 
			where id_forma=@id_forma and id_grabacion=@id_chat and id_formato=@id_formato

			select @id_forma

			END'
	else
		set @sql = ''

	EXEC(@sql)

	set @process = 'CREATE stored - trsp_AdmSaveChatScoresFormaCalif'
	if not exists (select * from sys.procedures where name = N'trsp_AdmSaveChatScoresFormaCalif')
		set @sql='CREATE PROCEDURE [dbo].[trsp_AdmSaveChatScoresFormaCalif]
			@chat_id int,
			@id_calificador int,
			@id_supervisor int,
			@id_formato int,
			@total_forma int,
			@age_id int,
			@version int

			AS

			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			declare @cam_id int 

			set @cam_id = (select InboundId from ccriachats where chatId = @chat_id )

			Insert CCRecorderRIA.dbo.RIA_FORMACALIF (fecha_calif,id_calificador,id_supervisor,id_grabacion,id_formato,total_forma,age_id,version, tipo,cam_id)
			values
			(GetDate(),@id_calificador,@id_supervisor,@chat_id,@id_formato,@total_forma,@age_id,@version, 2,@cam_id)

			select Scope_Identity()

			END'
	else
		set @sql = ''

	EXEC(@sql)

	set @process = 'CREATE stored - trsp_AdmGetChatInfoFormatScored'
	if not exists (select * from sys.procedures where name = N'trsp_AdmGetChatInfoFormatScored')
		set @sql='CREATE  PROCEDURE [dbo].[trsp_AdmGetChatInfoFormatScored]
			@chat_id int,
			@id_formato int

			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

			declare @version int

			set @version = (select MAX(version) from CCRecorderRIA.dbo.RIA_FORMACALIF where id_grabacion = @chat_id and id_formato = @id_formato)
			select id_forma, fecha_calif, id_calificador, id_supervisor, id_grabacion, id_formato,total_forma,age_id, version from CCRecorderRIA.dbo.RIA_FORMACALIF where version = @version and id_grabacion = @chat_id and id_formato = @id_formato

			END'
	else
		set @sql = ''

	EXEC(@sql)


	set @process = 'CREATE stored - [dbo].[trsp_AdmGetSatisfactionScore]'
	if not exists (select * from sys.procedures where name = N'[dbo].[trsp_AdmGetSatisfactionScore]')
		set @sql='CREATE  PROCEDURE [dbo].[trsp_AdmGetSatisfactionScore]
			@id_chat as Int
			AS
			BEGIN
				SET NOCOUNT ON;
				select total_forma from RIA_FORMACALIF_CHAT where id_chat = @id_chat
			END'
	else
		set @sql = ''

	EXEC(@sql)


	set @process = 'Create stored trsp_AdmRecSearchANI'
	if not exists (select * from sys.procedures where name = N'trsp_AdmRecSearchANI')			
		set @sql='CREATE PROCEDURE [dbo].[trsp_AdmRecSearchANI]
			@Sup_id int,
			@ani as varchar(100)

			AS
			BEGIN

			SET NOCOUNT ON;

			declare @fecha  datetime

			set @fecha = CAST(CONVERT(VARCHAR(8), DATEADD(DD,-30,GETDATE()), 1) AS DATETIME)

				select r.id_grabacion, avg(r.total_forma) as total_forma
				into #tempRiaFormaCalif from ria_formacalif r 
				inner join (select id_formato,id_grabacion,max(version) as version from ria_formacalif group by id_grabacion,id_formato)t 
				on r.id_grabacion=t.id_grabacion and r.id_formato=t.id_formato and r.version=t.version
				group by r.id_grabacion		
				
				select distinct a.IdCampEsp, a.Tipo as Tipo_llamada
				into #tempCampEspWG from ccRIACampEspWGConsulta a 
				inner join  ccRIAWorkGroupUsersConsulta b on b.User_id = @Sup_id and a.IDWG = b.IDWG

				select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
				finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
				isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
				isnull (z.total_forma,0) as total_forma,a.id_repositorio,
				CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
				CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion, 
				a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
				from RIA_GRABACION a with (index(IX_RIA_GRABACION_3))		
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
				left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
				left join ccTipoCalif AS f ON a.calif_id = f.calif_id
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
				left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
				inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
				where a.ani = @ani
				union
				select a.cal_id, a.Tipo_llamada, a.cam_id, a.calif_id, a.duracion, isnull(a.id_nivel_grito,-1) as id_nivel_grito, a.age_id,
				finicio,a.ani, a.dni, a.cal_key, isnull(a.cal_manual,0) as cal_manual,
				isnull(CASE WHEN b.ext_id = 0 THEN b.pos_id ELSE b.ext_id END,-1) as pos_id, b.Computer,
				isnull (z.total_forma,0) as total_forma,a.id_repositorio,
				CASE WHEN a.tipo_llamada = 2 THEN e.description ELSE f.description END AS score,
				CASE WHEN duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(a.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 / 60), 2) + '':'' + RIGHT(''0'' + RTRIM(a.duracion % 3600 % 60), 2) AS formato_duracion,
				a.grab_id as grabID,isnull(g.IDWG,0)as IDWG
				from RIA_GRABACIONCONSULTA a with (index(IX_RIA_GRABACIONCONSULTA_3))		
				left join ccPosicion b on b.pos_id = a.cal_extension * -1
				--left join RIA_FORMACALIF d on d.id_grabacion = a.grab_id 
				left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
				left join ccTipoCalif AS f ON a.calif_id = f.calif_id
				left join ccRIAWorkGroup_Calid AS g ON g.cal_id = a.cal_id and g.user_id=a.age_id and g.tipo= (a.Tipo_llamada -1 ) 
				left join #tempRiaFormaCalif z on a.grab_id=z.id_grabacion
				inner join #tempCampEspWG campEspWg on a.cam_id = campEspWg.idCampEsp and campEspWg.Tipo_llamada = (a.Tipo_llamada -1 ) 
				where a.ani = @ani

				drop table #tempRiaFormaCalif
				drop table #tempCampEspWG
				
			END	
			'
	else
		set @sql = ''
	EXEC(@sql)

	--------------------------------------

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
				if @option = 2
				begin
					set @sql = ''select top '' + @top + '' grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ria_RecNode with(rowlock) where status = 0''
					exec(@sql)
				end
			end
			if @action = 2 begin--actualiza los nodos insertados en BX
				if @option = 2
				begin
					update ria_RecNode with(rowlock) set [status] = 1, dateOut = getDate() where grab_id between @idF and @idL and [status] = 0
				end
			end
			if @action = 6 begin --obtener valores con status 2
				set @sql = ''select top '' + @top + '' grab_id, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ria_RecNode with(rowlock) where status = 2''
				exec(@sql)
			end
			if @action = 7 begin--actualiza los nodos insertados en BX
				if @option = 2
				begin
					update ria_RecNode with(rowlock) set [status] = 1, dateOut = getDate() where grab_id between @idF and @idL and [status] = 2
				end
			end'
	else
		set @sql = ''

	EXEC(@sql)
	
	set @process = 'trsp_InsertRecNode - CREATE Procedure'
	if not exists (select * from sys.procedures where name = N'trsp_InsertRecNode')
		set @sql = 'CREATE procedure [dbo].[trsp_InsertRecNode]
			        @grabId int,
                    @type int 
                    as 
                    begin

                    declare @sql as nvarchar(max)
                    declare @callType as nvarchar(20)
                    declare @shoutLevel as nvarchar(20)
                    declare @date as datetime
                    declare @formatedDate as nvarchar(50)
                    declare @language as int
                    declare @start as int
                    declare @country as int
                    declare @xml as xml
                    declare @crmNode as xml
                    declare @manual as nvarchar(10)
                    declare @rating as nvarchar(20)
                    declare @sqlCRM nvarchar(2000)
                    declare @supervisor as nvarchar(50)
                    declare @template as nvarchar(50)
                    declare @callID as nvarchar(50)

                    declare @table as nvarchar(20)
                    set @table=''RIA''
                    --declare @score as nvarchar(20)

                    --Get languange
                    set @language = (
                           select valor
                           from ccSettings
                           where setting_id = 27)

                    --Get call type
                    set @callType = (
                           select tipo_llamada
                           from ria_grabacion
                           where grab_id = @grabId)

                    --Get shout level
                    set @shoutlevel = (
                           select sho.nombre_nivel
                           from 
                           ria_grabacion rec
                           inner join ria_tipo_gritos sho
                           on rec.id_nivel_grito = sho.id_nivel_grito
                           where rec.grab_id = @grabId
                    )

                    set @start = (
                           select charindex(''|'',@shoutLevel) 
                    )

                    --Spanish
                    if @language = 0
                           begin
                                  set @shoutlevel = (
                                        select substring(@shoutlevel,0,@start)
                                  )
                           end
                    else
                           begin
                                  set @shoutlevel = (
                                        select substring(@shoutlevel,(@start+1),(LEN(@shoutlevel)-1))
                                  )
                           end
                    
                    --Get date
                    set @date = ( 
                           select finicio
                           from ria_grabacion
                           where grab_id = @grabId )

                    --Set format date
                    set @formatedDate = (
                           select convert(varchar(23), @date, 126))

                    --Call manual
                    declare @manualId as int
                    
                    set @manualId = (
                           select cal_manual
                           from RIA_GRABACION
                           where grab_id = @grabId
                    )

                    if @manualId = 0
                           begin
                                  set @manual = (''N/A'')
                           end
                    else
                           begin
                                  set @manual = (''Manual'')
                           end

                    --Get rating
                    set @rating = (
                           select  top 1 isnull (total_forma,0)           
                           from ria_formacalif
                           where id_grabacion = @grabId order by fecha_calif desc)

             

                    ----Get score
                    --set @score = (
                    --     select   top 1 isnull (total_forma,0)          
                    --     from ria_formacalif
                    --     where id_grabacion = @grabId order by fecha_calif desc
                           
                    --     --left join ccTipoCalifOUT AS e ON a.calif_id = e.calif_id 
                    --     --left join ccTipoCalif AS f ON a.calif_id = f.calif_id
                    --     )
                    
                           
                    /*           
                           C01-----> grab_id
                           C02-----> Type of Recording (Inbound/Outbound)
                           C03-----> Camp/ACD descripcion
                           C04-----> ShoutLevel 
                           C05-----> Agent Login
                           C06-----> Formated date
                           C07-----> Position Computer
                           C08-----> Duration
                           C09-----> Ani
                           C10-----> Dnis
                           C11-----> Calkey
                           C12-----> Manual
                           C13-----> User ID
                           C14-----> cal ID
                           C15-----> Cam /ACD ID 
                           C16-----> Duration Recording as 00:00:00
                           C17-----> Position Extension
                           C18-----> rating(Scoring Template) 
                           C19-----> Reposiory ID
                           C20-----> Disposition
                           C21-----> Disposition ID
                           C22-----> Has Video
                           C23-----> Agent Full Name
                           C24-----> Supervisor Name
                           c25-----> Score Template
                    */

                    if @type =0 ---Process to Insert
                    BEGIN
                           if @callType = 1 --Inbound
                                  BEGIN
                                  
                                        select  @callID = cal_id from ria_grabacion where grab_id = @grabId
                    
                                        set @xml = (
                                                            select top 1 rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',  
                                                            @formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'', 
                                                            rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
                                                            CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
                                                            + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
                                                            isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
                                                            CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
                                                            usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'','''' as ''@C24'','''' as ''@C25''
                                        from 
                                        ria_grabacion rec 
                                        inner join ccRIAWorkGroup_Calid wgc
                                               on rec.cal_id = wgc.cal_id
                                        inner join ccriacat_workgroup cwg
                                               on wgc.IDWG = cwg.IDWG 
                                        inner join ccRIACampEspWGConsulta cewg
                                               on cwg.IDWG = cewg.IDWG
                                        inner join ccinbound inb
                                               on cewg.IdCampEsp = inb.Inbound_id
                                        inner join ccUsers usr
                                               on usr.User_id = rec.age_id
                                        inner join RIA_TIPO_GRITOS sho
                                               on rec.id_nivel_grito = sho.id_nivel_grito
                                        inner join ccPosicion pos
                                               on pos.pos_id = rec.cal_extension * -1
                                        left join ccTipoCalifOUT AS e 
                                               ON rec.calif_id = e.calif_id 
                                        left join ccTipoCalif AS f 
                                               ON rec.calif_id = f.calif_id
                                        where
                                        (rec.tipo_llamada = 1)
                                        and (cewg.Tipo = 0)
                                        and (wgc.tipo = 0)
                                        and (inb.chat = 0)
                                        and (rec.cam_id=cewg.IdCampEsp )                      
                                        and (rec.grab_id = @grabId)

                                        for xml path(''R02''))

                                        --Get crm node
                                        if @xml is not null
                                               begin
                                                      select @crmNode = node from ccCRMNodes where [type]=1 and cal_id=@callID
                                                      if @crmNode is not null
                                                            begin
                                                                   update ccCRMNodes set grab_id=@grabId where [type]=1 and cal_id=@callID 
                                                                   set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
                                                                   execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
                                                            end                                            
                                               end
                                  
                                  
                                  END 
                           else
                                  BEGIN  

                                        select  @callID = cal_id from ria_grabacion where grab_id = @grabId
                                  
                                        set @xml = (
                                                            select top 1 rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'', inb.cam_descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',  
                                                            @formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'', 
                                                            rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
                                                            CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
                                                            + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
                                                            isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
                                                            CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
                                                            usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'','''' as ''@C24'','''' as ''@C25''
                                        from 
                                        ria_grabacion rec 
                                        inner join ccRIAWorkGroup_Calid wgc
                                               on rec.cal_id = wgc.cal_id
                                        inner join ccriacat_workgroup cwg
                                               on wgc.IDWG = cwg.IDWG 
                                        inner join ccRIACampEspWG cewg
                                               on cwg.IDWG = cewg.IDWG
                                        inner join cccamps inb
                                               on cewg.IdCampEsp = inb.cam_id
                                        inner join ccUsers usr
                                               on usr.User_id = rec.age_id
                                        inner join RIA_TIPO_GRITOS sho
                                               on rec.id_nivel_grito = sho.id_nivel_grito
                                        inner join ccPosicion pos
                                               on pos.pos_id = rec.cal_extension * -1
                                        left join ccTipoCalifOUT AS e 
                                               ON rec.calif_id = e.calif_id 
                                        left join ccTipoCalif AS f 
                                               ON rec.calif_id = f.calif_id
                                        where
                                        (rec.tipo_llamada = 2)
                                        and (cewg.Tipo = 1)
                                        and (wgc.tipo = 1)
                                        and (rec.cam_id=cewg.IdCampEsp )
                                        and (rec.grab_id = @grabId)
                                        for xml path(''R02'')) 

                                        --Get crm node
                                        if @xml is not null
                                               begin
                                                      select @crmNode = node from ccCRMNodes where [type]=2 and cal_id=@callID
                                                      if @crmNode is not null
                                                            begin
                                                                   update ccCRMNodes set grab_id=@grabId where [type]=2 and cal_id=@callID
                                                                   set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
                                                                   execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
                                                            end                                            
                                               end

                                  END
                                               
                                  if (@xml IS NOT NULL)
                                        insert into ria_RecNode (grab_id,node,dateIn,[status]) values (@grabId,@xml, getdate(),0)
                           
                    END

                    if @type =1 ---Process to Update
                    BEGIN
                    
                    if (select count (*) grab_id from RIA_GRABACION where grab_id=@grabId) > 0

                           begin -- Node in RIA_GRABACION
                                  
                                  select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
                                  RIA_FORMATOS as formatos 
                                  inner join RIA_FORMACALIF formatosCalif
                                        on formatosCalif.id_formato=formatos.id_formato
                                  inner join RIA_GRABACION grabacion 
                                        on grabacion.grab_id= formatosCalif.id_grabacion
                                  inner join ccUsers supervisor
                                        on supervisor.User_id = formatosCalif.id_supervisor
                                  where
                                  formatosCalif.tipo=1
                                  and grabacion.grab_id=@grabId

                                  if @callType = 1
                                  BEGIN

                                        select  @callID = cal_id from ria_grabacion where grab_id = @grabId
                           
                                        set @xml = (
                                                            select top 1 rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',  
                                                            @formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'', 
                                                            rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
                                                            CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
                                                            + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
                                                            isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
                                                            CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
                                                            usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'', @supervisor as ''@C24'',@Template as ''@C25''
                                        from 
                                        ria_grabacion rec 
                                        inner join ccRIAWorkGroup_Calid wgc
                                               on rec.cal_id = wgc.cal_id
                                        inner join ccriacat_workgroup cwg
                                               on wgc.IDWG = cwg.IDWG 
                                        inner join ccRIACampEspWGConsulta cewg
                                               on cwg.IDWG = cewg.IDWG
                                        inner join ccinbound inb
                                               on cewg.IdCampEsp = inb.Inbound_id
                                        inner join ccUsers usr
                                               on usr.User_id = rec.age_id
                                        inner join RIA_TIPO_GRITOS sho
                                               on rec.id_nivel_grito = sho.id_nivel_grito
                                        inner join ccPosicion pos
                                               on pos.pos_id = rec.cal_extension * -1
                                        left join ccTipoCalifOUT AS e 
                                               ON rec.calif_id = e.calif_id 
                                        left join ccTipoCalif AS f 
                                               ON rec.calif_id = f.calif_id
                                        where
                                        (rec.tipo_llamada = 1)
                                        and (cewg.Tipo = 0)
                                        and (wgc.tipo = 0)
                                        and (inb.chat = 0)
                                        and (rec.cam_id=cewg.IdCampEsp )                      
                                        and (rec.grab_id = @grabId)

                                        for xml path(''R02''))

                                        --Get crm node
                                        if @xml is not null
                                               begin
                                               
                                               select @crmNode = node from ccCRMNodes where [type]=1 and cal_id=@callID
                                               if @crmNode is not null
                                                            begin
                                                                   update ccCRMNodes set grab_id=@grabId where [type]=1 and cal_id=@callID 
                                                                   set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
                                                                   execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
                                                            end                                                  
                                               end
                                  
                                  
                                  END 
                           else
                                  BEGIN  

                                        set @xml = (
                                                            select  top 1  rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'', inb.cam_descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',  
                                                            @formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'', 
                                                            rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
                                                            CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
                                                            + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
                                                            isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
                                                            CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
                                                            usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',@supervisor as ''@C24'',@Template as ''@C25''
                                        from 
                                        ria_grabacion rec 
                                        inner join ccRIAWorkGroup_Calid wgc
                                               on rec.cal_id = wgc.cal_id
                                        inner join ccriacat_workgroup cwg
                                               on wgc.IDWG = cwg.IDWG 
                                        inner join ccRIACampEspWG cewg
                                               on cwg.IDWG = cewg.IDWG
                                        inner join cccamps inb
                                               on cewg.IdCampEsp = inb.cam_id
                                        inner join ccUsers usr
                                               on usr.User_id = rec.age_id
                                        inner join RIA_TIPO_GRITOS sho
                                               on rec.id_nivel_grito = sho.id_nivel_grito
                                        inner join ccPosicion pos
                                               on pos.pos_id = rec.cal_extension * -1
                                        left join ccTipoCalifOUT AS e 
                                               ON rec.calif_id = e.calif_id 
                                        left join ccTipoCalif AS f 
                                               ON rec.calif_id = f.calif_id
                                        where
                                        (rec.tipo_llamada = 2)
                                        and (cewg.Tipo = 1)
                                        and (wgc.tipo = 1)
                                        and (rec.cam_id=cewg.IdCampEsp )
                                        and (rec.grab_id = @grabId)
                                        for xml path(''R02'')) 

                                        --Get crm node
                                        if @xml is not null
                                               begin
                                                      select @crmNode = node from ccCRMNodes where [type]=2 and cal_id=@callID
                                                      if @crmNode is not null
                                                            begin
                                                                   update ccCRMNodes set grab_id=@grabId where [type]=2 and cal_id=@callID 
                                                                   set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
                                                                   execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
                                                            end                                     
                                               end

                                  END


                           end
                    else   -- Node in RIA_GRABACIONCONSULTA
                           begin 
                                  select @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
                                  RIA_FORMATOS as formatos 
                                  inner join RIA_FORMACALIF formatosCalif
                                        on formatosCalif.id_formato=formatos.id_formato
                                  inner join RIA_GRABACIONCONSULTA grabacion 
                                        on grabacion.grab_id= formatosCalif.id_grabacion
                                  inner join ccUsers supervisor
                                        on supervisor.User_id = formatosCalif.id_supervisor
                                  where
                                  formatosCalif.tipo=1
                                  and grabacion.grab_id=@grabId

                                  if @callType = 1
                                  BEGIN

                    
                                        set @xml = (
                                                            select rec.grab_id as ''@C01'', ''Inbound'' as ''@C02'', inb.descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',  
                                                            @formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'', 
                                                            rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
                                                            CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
                                                            + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
                                                            isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
                                                            CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
                                                            usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',@supervisor as ''@C24'',@Template as ''@C25''
                                        from 
                                        ria_grabacionconsulta rec 
                                        inner join ccRIAWorkGroup_Calid wgc
                                               on rec.cal_id = wgc.cal_id
                                        inner join ccriacat_workgroup cwg
                                               on wgc.IDWG = cwg.IDWG 
                                        inner join ccRIACampEspWGConsulta cewg
                                               on cwg.IDWG = cewg.IDWG
                                        inner join ccinbound inb
                                               on cewg.IdCampEsp = inb.Inbound_id
                                        inner join ccUsers usr
                                               on usr.User_id = rec.age_id
                                        inner join RIA_TIPO_GRITOS sho
                                               on rec.id_nivel_grito = sho.id_nivel_grito
                                        inner join ccPosicion pos
                                               on pos.pos_id = rec.cal_extension * -1
                                        left join ccTipoCalifOUT AS e 
                                               ON rec.calif_id = e.calif_id 
                                        left join ccTipoCalif AS f 
                                               ON rec.calif_id = f.calif_id
                                        where
                                        (rec.tipo_llamada = 1)
                                        and (cewg.Tipo = 0)
                                        and (wgc.tipo = 0)
                                        and (inb.chat = 0)
                                        and (rec.cam_id=cewg.IdCampEsp )                      
                                        and (rec.grab_id = @grabId)

                                        for xml path(''R02''))

                                        --Get crm node
                                        if @xml is not null
                                               begin
                                                      select @crmNode = node from ccCRMNodes where [type]=1 and cal_id=@callID
                                                      if @crmNode is not null
                                                            begin
                                                                   update ccCRMNodes set grab_id=@grabId where [type]=1 and cal_id=@callID 
                                                                   set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
                                                                   execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
                                                            end                                            
                                               end
                                  
                                  
                                  END 
                           else
                                  BEGIN  

                                        set @xml = (
                                                            select rec.grab_id as ''@C01'', ''Outbound'' as ''@C02'', inb.cam_descripcion as ''@C03'', @shoutLevel as ''@C04'', usr.Login as ''@C05'',  
                                                            @formatedDate as ''@C06'',pos.Computer as ''@C07'', convert(nvarchar(10),rec.duracion) as ''@C08'',rec.ani as ''@C09'', rec.dni as ''@C10'', 
                                                            rec.cal_key as ''@C11'', @manual AS ''@C12'',usr.[User_id] AS ''@C13'',rec.cal_id AS ''@C14'',inb.cam_id as ''@C15'',
                                                            CASE WHEN rec.duracion / 3600 < 10 THEN ''0'' ELSE '''' END + RTRIM(rec.duracion / 3600) + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 / 60), 2) 
                                                            + '':'' + RIGHT(''0'' + RTRIM(rec.duracion % 3600 % 60), 2) AS ''@C16'',
                                                            isnull(CASE WHEN pos.ext_id = 0 THEN pos.pos_id ELSE pos.ext_id END,-1) as ''@C17'',isnull(@rating,0) as ''@C18'', rec.id_repositorio  as ''@C19'',
                                                            CASE WHEN rec.tipo_llamada = 2 THEN e.description ELSE f.description END AS ''@C20'',rec.calif_id AS ''@C21'',rec.video as ''@C22'',
                                                            usr.Nombres + '' '' + usr.ApellidoPaterno + '' '' + usr.ApellidoMaterno as ''@C23'',@supervisor as ''@C24'',@Template as ''@C25''
                                        from 
                                        ria_grabacionconsulta rec 
                                        inner join ccRIAWorkGroup_Calid wgc
                                               on rec.cal_id = wgc.cal_id
                                        inner join ccriacat_workgroup cwg
                                               on wgc.IDWG = cwg.IDWG 
                                        inner join ccRIACampEspWG cewg
                                               on cwg.IDWG = cewg.IDWG
                                        inner join cccamps inb
                                               on cewg.IdCampEsp = inb.cam_id
                                        inner join ccUsers usr
                                               on usr.User_id = rec.age_id
                                        inner join RIA_TIPO_GRITOS sho
                                               on rec.id_nivel_grito = sho.id_nivel_grito
                                        inner join ccPosicion pos
                                               on pos.pos_id = rec.cal_extension * -1
                                        left join ccTipoCalifOUT AS e 
                                               ON rec.calif_id = e.calif_id 
                                        left join ccTipoCalif AS f 
                                               ON rec.calif_id = f.calif_id
                                        where
                                        (rec.tipo_llamada = 2)
                                        and (cewg.Tipo = 1)
                                        and (wgc.tipo = 1)
                                        and (rec.cam_id=cewg.IdCampEsp )
                                        and (rec.grab_id = @grabId)
                                        for xml path(''R02'')) 

                                        --Get crm node
                                        if @xml is not null
                                               begin
                                                      select @crmNode = node from ccCRMNodes where [type]=2 and cal_id=@callID
                                                      if @crmNode is not null
                                                            begin
                                                                   update ccCRMNodes set grab_id=@grabId where [type]=2 and cal_id=@callID 
                                                                   set @sqlCRM = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R02)[1]'''') ''
                                                                   execute sp_executesql @sqlCRM,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
                                                            end                                            
                                               end

                                  END

                           end
                           
                                               
                                  if (@xml IS NOT NULL)
                                        update ria_RecNode set node =@xml,[status]=2 where grab_id = @grabId

                    END
                    
                    
             end'
	else
		set @sql = ''

	EXEC(@sql)


	set @process = 'Create SP -- trsp_UpdateShoutDetection'
	if not exists (select * from sys.procedures where name = N'trsp_UpdateShoutDetection')
		set @sql='CREATE PROCEDURE [dbo].[trsp_UpdateShoutDetection]
			@isXION int,
			@shoutLevel int,
			@grabId int,
			@hasVideo int
			AS
			BEGIN

				IF @isXION = 1 
					BEGIN

						IF  EXISTS (SELECT 1 FROM RIA_GRABACION WHERE grab_id = @grabId)
							BEGIN

								UPDATE RIA_GRABACION
								SET id_nivel_grito = @shoutLevel,video= @hasVideo
								WHERE grab_id = @grabId

							END
						ELSE
							BEGIN

								UPDATE RIA_GRABACIONCONSULTA
								SET id_nivel_grito = @shoutLevel,video= @hasVideo
								WHERE grab_id = @grabId

							END

						--Only in XION to build the finder
						exec trsp_InsertRecNode  @grabId,0

					END
				ELSE
					BEGIN

					IF EXISTS (SELECT 1 FROM RIA_GRABACION WHERE grab_id = @grabId)
							BEGIN

								UPDATE TREC_GRABACION
								SET id_nivel_grito = @shoutLevel
								WHERE grab_id = @grabId

							END
						ELSE
							BEGIN

								UPDATE TREC_GRABACIONCONSULTA
								SET id_nivel_grito = @shoutLevel
								WHERE grab_id = @grabId

							END
						 
					END

			END
			'
	else
		set @sql = ''

	EXEC(@sql)



	set @process = 'Create SP -- ccsp_AdmGetAgentIdOnChat'
	if not exists (select * from sys.procedures where name = N'ccsp_AdmGetAgentIdOnChat')
		set @sql='create PROCEDURE [dbo].[ccsp_AdmGetAgentIdOnChat]
			@chat_id int 
			AS
			BEGIN

			SET NOCOUNT ON;
			select userId from ccRIAChats where chatId=@chat_id
			END'
	else
		set @sql = ''

	EXEC(@sql)


	set @process = 'Create SP -- trsp_GetTemplateandSupervisor'
	if not exists (select * from sys.procedures where name = N'trsp_GetTemplateandSupervisor')
		set @sql='create PROCEDURE [dbo].[trsp_GetTemplateandSupervisor] 
			@type integer =0,
			@sIdChat Integer
			AS

			declare @supervisor as nvarchar(50)
			declare @template as nvarchar(50)

			if (@type = 0)
				BEGIN

				select top 1 @Template =  formatos.nombre,@supervisor= (supervisor.Nombres + '' '' + supervisor.ApellidoPaterno + '' '' + supervisor.ApellidoMaterno)  from
						RIA_FORMATOS as formatos 
						inner join RIA_FORMACALIF formatosCalif
							on formatosCalif.id_formato=formatos.id_formato
						inner join ccUsers supervisor
							on supervisor.User_id = formatosCalif.id_supervisor
						where
						formatosCalif.tipo=2
						and formatosCalif.id_grabacion=@sIdChat order by formatosCalif.fecha_calif desc

				select @Template,@supervisor

				END'
	else
		set @sql = ''

	EXEC(@sql)



	set @process = 'alter SP  - trsp_AdmSaveQualityFormats'
	if exists (select * from sys.procedures where name = N'trsp_AdmSaveQualityFormats')
		set @sql='ALTER PROCEDURE [dbo].[trsp_AdmSaveQualityFormats]		
			@bCrea smallint,
			@id_formato int,
			@version int,
			@sup_id int,
			@nombre_formato varchar(50),
			@peso_formato int,
			@type int=1

			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

				IF (@bCrea = 1)
					BEGIN
						set @id_formato = (select isnull(max(id_formato),0) from RIA_FORMATOS) + 1
						set @version = 1
						insert CCRecorderRIA.dbo.RIA_FORMATOS (id_formato, nombre,id_creador,fecha_creado,activo,peso,version,tipo) values (@id_formato, @nombre_formato, @sup_id, GetDate(),1, @peso_formato,@version,@type)
					END

				ELSE
					BEGIN

					set @version = @version + 1
					insert CCRecorderRIA.dbo.RIA_FORMATOS (id_formato, nombre,id_creador,fecha_creado,activo,peso,version,tipo) values (@id_formato, @nombre_formato, @sup_id, GetDate(),1, @peso_formato,@version,@type)

					END

			END'
	else
		set @sql = ''

	EXEC(@sql)


	

	set @process = 'alter stored  - trsp_AdmGetQualityDiferentFormats'
	if exists (select * from sys.procedures where name = N'trsp_AdmGetQualityDiferentFormats')
		set @sql='ALTER PROCEDURE [dbo].[trsp_AdmGetQualityDiferentFormats]
			@type as tinyint = 1
			AS
			BEGIN
				SET NOCOUNT ON;
				select distinct id_formato from RIA_FORMATOS where tipo=@type
			END'
	else
		set @sql = ''

	EXEC(@sql)

	set @process = 'alter stored - trsp_AdmGetQualityAnswersScored'
	if exists (select * from sys.procedures where name = N'trsp_AdmGetQualityAnswersScored')
		set @sql='ALTER PROCEDURE [dbo].[trsp_AdmGetQualityAnswersScored]
			@id_pregunta int,
			@id_respuesta int,
			@id_forma int,
			@tipo int = 1

			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

					select b.id_respuesta, b.etiquetas, a.peso 
					from CCRecorderRIA.dbo.RIA_RESPUESTAS a 
					Inner join CCRecorderRIA.dbo.RIA_RESULTADOSFORMA b
					on a.id_pregunta = @id_pregunta and a.id_respuesta = @id_respuesta  and b.id_pregunta = @id_pregunta and b.id_respuesta = @id_respuesta and b.id_forma = 
					(select ISNULL(id_forma,0) from RIA_FORMACALIF where id_forma=@id_forma and tipo=@tipo) order by a.id_respuesta

			END'
	else
		set @sql = ''
	EXEC(@sql)

	set @process = 'alter stored - trsp_AdmVerifyingFormatEditing'
	if exists (select * from sys.procedures where name = N'trsp_AdmVerifyingFormatEditing')
		set @sql='ALTER PROCEDURE [dbo].[trsp_AdmVerifyingFormatEditing]
			@cal_id int,
			@tipo_llamada int,
			@id_formato int


			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			declare @grab_id int,
			@id_forma int

			    -- Insert statements for procedure here

			set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

			set @id_forma = (Select isnull(id_forma,0) from CCRecorderRIA.dbo.RIA_FORMACALIF where id_grabacion = @grab_id and id_formato = @id_formato and tipo=1)


			--Retrieving the id forma
			select isnull(@id_forma,0)

			END'
	else
		set @sql = ''

	EXEC(@sql)


	set @process = 'alter SP  - trsp_AdmSaveScoresFormaCalif'
	if exists (select * from sys.procedures where name = N'trsp_AdmSaveScoresFormaCalif')
		set @sql='
			ALTER PROCEDURE [dbo].[trsp_AdmSaveScoresFormaCalif]
			-- Add the parameters for the stored procedure here

			@cal_id int,
			@tipo_llamada int,
			@id_calificador int,
			@id_supervisor int,
			@id_formato int,
			@total_forma int,
			@version int


			AS
			BEGIN
				-- SET NOCOUNT ON added to prevent extra result sets from
				-- interfering with SELECT statements.
				SET NOCOUNT ON;

			    -- Insert statements for procedure here

			declare @grab_id int
			declare @cam_id int,
			@age_id int


			set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)
			set @cam_id = (select cam_id from (select cam_id from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select cam_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)
			set @age_id = (select age_id from (select age_id from CCRecorderRIA.dbo.RIA_GRABACION  with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select age_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)


			Insert CCRecorderRIA.dbo.RIA_FORMACALIF (fecha_calif,id_calificador,id_supervisor,id_grabacion,id_formato,total_forma,age_id,version,tipo,tipo_llamada,cam_id)
			values
			(GetDate(),@id_calificador,@id_supervisor,@grab_id,@id_formato,@total_forma,@age_id,@version, 1,@tipo_llamada,@cam_id)

			exec trsp_InsertRecNode @grab_id,1

			select Scope_Identity()

			END'
	else
		set @sql = ''

	EXEC(@sql)

	set @process = 'Create stored -- trsp_AdmUpdateSaveScores'
	if not exists (select * from sys.procedures where name = N'trsp_AdmUpdateSaveScores')
		set @sql='CREATE PROCEDURE [dbo].[trsp_AdmUpdateSaveScores]
			 -- Add the parameters for the stored procedure here

			@id_forma int,
			@cal_id int,
			@tipo_llamada int,
			@id_calificador int,
			@id_supervisor int,
			@id_formato int,
			@total_forma int,
			@version int


			AS
			BEGIN
			 -- SET NOCOUNT ON added to prevent extra result sets from
			 -- interfering with SELECT statements.
			 SET NOCOUNT ON;

			    -- Insert statements for procedure here


			declare @grab_id int

			set @grab_id = (select grab_id from (select grab_id from CCRecorderRIA.dbo.RIA_GRABACION with (index(IX_RIA_GRABACION_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada UNION select grab_id from CCRecorderRIA.dbo.RIA_GRABACIONCONSULTA with (index(IX_RIA_GRABACIONCONSULTA_1)) where cal_id = @cal_id and tipo_llamada = @tipo_llamada) x)

			Delete from CCRecorderRIA.dbo.RIA_RESULTADOSFORMA where id_forma = @id_forma

			Update CCRecorderRIA.dbo.RIA_FORMACALIF 
			set fecha_calif = GetDate(), id_calificador=@id_calificador,id_supervisor=@id_supervisor,total_forma=@total_forma, version=@version 
			where id_forma=@id_forma and id_grabacion=@grab_id and id_formato=@id_formato

			exec trsp_InsertRecNode @grab_id,1

			select @id_forma

			END'
	else
		set @sql = ''
	
	EXEC(@sql)

	set @process = 'alter stored - trsp_AdmAVRSReportCallInfo'
	if exists (select * from sys.procedures where name = N'trsp_AdmAVRSReportCallInfo')
		set @sql='ALTER  PROCEDURE [dbo].[trsp_AdmAVRSReportCallInfo]
			@id_formato int,
			@version int,
			@call_id int,
			@tipo int,
			@medio int
			AS
			BEGIN
			declare @id_grabacion as int

			if @medio =2
				BEGIN
					set @id_grabacion = @call_id
					 
					SELECT    Age.Nombres + '' '' + Age.ApellidoPaterno AS Agente, Super.Nombres + '' '' + Super.ApellidoPaterno AS Supervisor, 
					  Calificador.Nombres+'' ''+Calificador.ApellidoPaterno AS Calificador,chat.domain AS Telfono ,
					  Tipo= ''inbound'',chat.chatDate AS Fecha,chat.chatId AS [Id de llamada],'''' AS [Id de Grabacion],
					  '''' AS [Cal key],dbo.ft_getTime(chat.tChatting,''2'') AS Duracion,	[Campaña/GrupO ACD]=
					  ( SELECT ccInbound.descripcion FROM ccriachats INNER JOIN ccInbound ON ccriachats.inboundId = ccInbound.Inbound_id
						WHERE (ccriachats.chatId = @id_grabacion)),
						RIA_FORMATOS.nombre AS [Formato de calificacion],RIA_FORMACALIF.fecha_calif[Fecha revision]
				FROM  RIA_FORMACALIF INNER JOIN
						ccUsers AS Age ON RIA_FORMACALIF.age_id = Age.User_id INNER JOIN
						ccUsers AS Super ON RIA_FORMACALIF.id_supervisor = Super.User_id INNER JOIN
						ccUsers AS Calificador ON RIA_FORMACALIF.id_calificador = Calificador.User_id INNER JOIN
						RIA_FORMATOS ON  RIA_FORMACALIF.id_formato =  RIA_FORMATOS.id_formato INNER JOIN
						ccriachats AS chat ON chat.chatId = RIA_FORMACALIF.id_grabacion
				WHERE RIA_FORMACALIF.id_formato=@id_formato and
						RIA_FORMACALIF.version=@version and
						RIA_FORMACALIF.id_grabacion=@id_grabacion and
						RIA_FORMATOS.version=@version
				END
			else
			BEGIN 
				
				IF EXISTS (select grab_id from ria_grabacion where cal_id=@call_id and tipo_llamada=@tipo)
					BEGIN
					
						set @id_grabacion = (select grab_id from ria_grabacion where cal_id=@call_id and tipo_llamada=@tipo)

						SELECT    Age.Nombres + '' '' + Age.ApellidoPaterno AS Agente, Super.Nombres + '' '' + Super.ApellidoPaterno AS Supervisor, 
						  Calificador.Nombres+'' ''+Calificador.ApellidoPaterno AS Calificador,RIA_GRABACION.ani AS Telfono ,Tipo=
																								CASE WHEN (SELECT tipo_llamada 
																											FROM RIA_GRABACION 
																											WHERE grab_id=@id_grabacion)=1 THEN ''inbound'' 
																								ELSE ''outbound'' 
																								END,
											  RIA_GRABACION.finicio AS Fecha,RIA_GRABACION.cal_id AS [Id de llamada],RIA_GRABACION.grab_id AS [Id de Grabacion],
											  RIA_GRABACION.cal_key AS [Cal key],dbo.ft_getTime(RIA_GRABACION.duracion,''2'') AS Duracion,
											  [Campaña/GrupO ACD]=
												CASE WHEN (SELECT tipo_llamada 
														   FROM RIA_GRABACION 
														   WHERE grab_id=@id_grabacion)=1 THEN (SELECT ccInbound.descripcion
																					   FROM RIA_GRABACION INNER JOIN
																					   ccInbound ON RIA_GRABACION.cam_id = ccInbound.Inbound_id
																					   WHERE (RIA_GRABACION.grab_id = @id_grabacion)) 
					     						ELSE (SELECT     ccCamps.cam_descripcion
													  FROM       RIA_GRABACION INNER JOIN
													  ccCamps ON RIA_GRABACION.cam_id = ccCamps.cam_id
													  WHERE     (RIA_GRABACION.grab_id = @id_grabacion))
												END,
											  RIA_FORMATOS.nombre AS [Formato de calificacion],RIA_FORMACALIF.fecha_calif[Fecha revision]
										FROM  RIA_FORMACALIF INNER JOIN
											 ccUsers AS Age ON RIA_FORMACALIF.age_id = Age.User_id INNER JOIN
											  ccUsers AS Super ON RIA_FORMACALIF.id_supervisor = Super.User_id INNER JOIN
											  ccUsers AS Calificador ON RIA_FORMACALIF.id_calificador = Calificador.User_id INNER JOIN
											  RIA_GRABACION ON RIA_FORMACALIF.id_grabacion = RIA_GRABACION.grab_id INNER JOIN
											  RIA_FORMATOS ON  RIA_FORMACALIF.id_formato =  RIA_FORMATOS.id_formato
										WHERE RIA_FORMACALIF.id_formato=@id_formato and
											  RIA_FORMACALIF.version=@version and
											  RIA_FORMACALIF.id_grabacion=@id_grabacion and
											  RIA_FORMATOS.version=@version

					END
				ELSE
					BEGIN

						set @id_grabacion =(select grab_id from RIA_GRABACIONCONSULTA where cal_id=@call_id and tipo_llamada=@tipo)

						SELECT    Age.Nombres + '' '' + Age.ApellidoPaterno AS Agente, Super.Nombres + '' '' + Super.ApellidoPaterno AS Supervisor, 
						  Calificador.Nombres+'' ''+Calificador.ApellidoPaterno AS Calificador,RIA_GRABACIONCONSULTA.ani AS Telfono ,Tipo=
																								CASE WHEN (SELECT tipo_llamada 
																											FROM RIA_GRABACIONCONSULTA 
																											WHERE grab_id=@id_grabacion)=1 THEN ''inbound'' 
																								ELSE ''outbound'' 
																								END,
											  RIA_GRABACIONCONSULTA.finicio AS Fecha,RIA_GRABACIONCONSULTA.cal_id AS [Id de llamada],RIA_GRABACIONCONSULTA.grab_id AS [Id de Grabacion],
											  RIA_GRABACIONCONSULTA.cal_key AS [Cal key],dbo.ft_getTime(RIA_GRABACIONCONSULTA.duracion,''2'') AS Duracion,
											  [Campaña/GrupO ACD]=
												CASE WHEN (SELECT tipo_llamada 
														   FROM RIA_GRABACIONCONSULTA 
														   WHERE grab_id=@id_grabacion)=1 THEN (SELECT ccInbound.descripcion
																					   FROM RIA_GRABACIONCONSULTA INNER JOIN
																					   ccInbound ON RIA_GRABACIONCONSULTA.cam_id = ccInbound.Inbound_id
																					   WHERE (RIA_GRABACIONCONSULTA.grab_id = @id_grabacion)) 
					     						ELSE (SELECT     ccCamps.cam_descripcion
													  FROM       RIA_GRABACIONCONSULTA INNER JOIN
													  ccCamps ON RIA_GRABACIONCONSULTA.cam_id = ccCamps.cam_id
													  WHERE     (RIA_GRABACIONCONSULTA.grab_id = @id_grabacion))
												END,
											  RIA_FORMATOS.nombre AS [Formato de calificacion],RIA_FORMACALIF.fecha_calif[Fecha revision]
										FROM  RIA_FORMACALIF INNER JOIN
											 ccUsers AS Age ON RIA_FORMACALIF.age_id = Age.User_id INNER JOIN
											  ccUsers AS Super ON RIA_FORMACALIF.id_supervisor = Super.User_id INNER JOIN
											  ccUsers AS Calificador ON RIA_FORMACALIF.id_calificador = Calificador.User_id INNER JOIN
											  RIA_GRABACIONCONSULTA ON RIA_FORMACALIF.id_grabacion = RIA_GRABACIONCONSULTA.grab_id INNER JOIN
											  RIA_FORMATOS ON  RIA_FORMACALIF.id_formato =  RIA_FORMATOS.id_formato
										WHERE RIA_FORMACALIF.id_formato=@id_formato and
											  RIA_FORMACALIF.version=@version and
											  RIA_FORMACALIF.id_grabacion=@id_grabacion and
											  RIA_FORMATOS.version=@version

					
					END
				END
			END
		'
	else
		set @sql = ''

	EXEC(@sql)

	set @process = 'alter stored - trsp_AdmAVRSReportDemo'
	if exists (select * from sys.procedures where name = N'trsp_AdmAVRSReportDemo')
		set @sql='ALTER PROCEDURE [dbo].[trsp_AdmAVRSReportDemo]
			@id_formato int,
			@version int,
			@call_id int,
			@tipo int,
			@medio int

			AS

			BEGIN
				CREATE TABLE #tbl_ReporteConcepto(id int primary key identity(1,1),id_concepto int,concepto varchar(max));
				CREATE TABLE #tbl_ReportePregunta(id int primary key identity(1,1),id_pregunta int,pregunta varchar(max),id_concepto int,respuesta nvarchar(max),peso int,valor int);
				CREATE TABLE #tbl_Reporte(id int primary key identity(1,1),conceptopregunta varchar(max),respuesta varchar(max),puntos nvarchar(max),valorTotal nvarchar(max));

				declare @iter as int
				declare @iter1 as int
				declare @id_concepto int
				declare @respuesta varchar(max)
				declare @idForma as int
				declare @id_grabacion as int
				set @iter=1
				set @iter1=1
				
				if @medio =1
					BEGIN
						IF EXISTS (select grab_id from ria_grabacion where cal_id=@call_id and tipo_llamada=@tipo)
							BEGIN
						
								set @id_grabacion = (select grab_id from RIA_GRABACION where cal_id=@call_id and tipo_llamada=@tipo)

							END
						ELSE
							BEGIN

								set @id_grabacion = (select grab_id from RIA_GRABACIONCONSULTA where cal_id=@call_id and tipo_llamada=@tipo)
						
							END
					
						set @idForma=(select id_forma from ria_formacalif where id_grabacion=@id_grabacion and id_formato=@id_formato and version =@version)
					END
				else
					BEGIN
						set @id_grabacion = @call_id

						set @idForma=(select id_forma from ria_formacalif where id_grabacion=@id_grabacion and id_formato=@id_formato and version =@version)
						
					END


				INSERT into #tbl_ReporteConcepto select id_concepto,con_descripcion from RIA_CONCEPTOS where id_formato=@id_formato and version=@version

				while @iter <=(select count(1)  from #tbl_ReporteConcepto)
				begin
					select @id_concepto=id_concepto from #tbl_ReporteConcepto where id=@iter
					INSERT into #tbl_ReportePregunta  SELECT  RIA_PREGUNTAS.id_pregunta, RIA_PREGUNTAS.enunciado_pregunta, RIA_PREGUNTAS.id_concepto,RIA_RESULTADOSFORMA.etiquetas, RIA_RESULTADOSFORMA.peso,RIA_PREGUNTAS.peso
									  FROM         RIA_PREGUNTAS INNER JOIN
									  RIA_RESULTADOSFORMA ON RIA_PREGUNTAS.id_pregunta = RIA_RESULTADOSFORMA.id_pregunta
									  where id_concepto=@id_concepto and RIA_RESULTADOSFORMA.id_forma=@idForma;
				set @iter = @iter+1;
				end

				while @iter1 <= (select count(1)  from #tbl_ReporteConcepto) 
				begin
					INSERT into #tbl_Reporte select concepto,'''','''','''' from #tbl_ReporteConcepto where id=@iter1
					select @id_concepto=id_concepto from #tbl_ReporteConcepto where id=@iter1
					INSERT into #tbl_Reporte select pregunta,respuesta,peso,valor from #tbl_ReportePregunta where id_concepto=@id_concepto
					set @iter1 = @iter1+1;
				end	

				INSERT into #tbl_Reporte
				select ''Total'','''',convert(nvarchar(max),sum(convert(int,puntos)))as peso,convert(nvarchar(max),sum(convert(int,valorTotal)))as valor From #tbl_Reporte
				
				select * from #tbl_Reporte

			END
		'
	else
		set @sql = ''

	EXEC(@sql)


	set @process = 'alter stored - trsp_AdmAVRSReportLanguage'
		if exists (select * from sys.procedures where name = N'trsp_AdmAVRSReportLanguage')
			set @sql='ALTER PROCEDURE [dbo].[trsp_AdmAVRSReportLanguage]
				@idioma as int
				AS
				BEGIN					
					SET NOCOUNT ON;
					if @idioma=1
					begin
						select ''Reporte de Evaluacion de Llamadas'' as [001], 
						       ''Información de la Llamada'' as [002], 
							   ''agente'' as [003],
							   ''Supervisor'' as [004],
							   ''Teléfono'' as [005],
							   ''Tipo de Llamada'' as [006],
							   ''Fecha'' as [007],
							   ''ID de LLamada'' as [008],
							   ''ID de Grabación'' as [009],
							   ''CallKey'' as [010],
							   ''Duración'' as [011],
							   ''Campaña/ACD'' as [012],
							   ''Formato de Calificacion'' as [013],
							   ''Fecha de Revisión'' as [014],
							   ''Firma de Agente'' as [015],
							   ''Firma de Supervisor'' as [016],
							   ''Firma de Calidad'' as [017],

							   ''Detalles de Evaluación'' as [018],
							   ''Concepto/Pregunta'' as [019],
							   ''Respuesta'' as [020],
							   ''Puntos'' as [021],
							   ''Valor Total'' as [022],
							   ''Reporte de Evaluacion de Chat'' as [023],
							   ''Información de Chat'' as [024],
							   ''Dominio'' as [025],
							   ''ID de Chat'' as [026]
					end
					else if @idioma=2
					begin
						select ''Call Evaluation Report'' as [001], 
						       ''Call Information'' as [002], 
							   ''Agent'' as [003],
							   ''Supervisor'' as [004],
							   ''Phone'' as [005],
							   ''Call Type'' as [006],
							   ''Date'' as [007],
							   ''Call ID'' as [008],
							   ''Recording ID'' as [009],
							   ''CallKey'' as [010],
							   ''Length'' as [011],
							   ''Camp./ACD '' as [012],
							   ''Score Template'' as [013],
							   ''Revision Date'' as [014],
							   ''        Agent'' as [015],
							   ''        Supervisor'' as [016],
							   ''    Quality Dept.'' as [017],

							   ''Rating Details'' as [018],
							   ''Topic/Question'' as [019],
							   ''Answer'' as [020],
							   ''Points'' as [021],
							   ''Score'' as [022],
							   ''Chat Evaluation Reportt'' as [023],
							   ''Chat Information'' as [024],
							   ''Dominio'' as [025],
							   ''ID de Chat'' as [026]
					end
				END
			'
		else
			set @sql = ''

		EXEC(@sql)



	set @process = 'alter SP  - trsp_GetFilesAnalisisGritos'
		if exists (select * from sys.procedures where name = N'trsp_GetFilesAnalisisGritos')
		set @sql='ALTER PROCEDURE [dbo].[trsp_GetFilesAnalisisGritos] 
			--@idRepositorios as varchar(32),
			@sExtension as varchar(10) = ''.vox''
			AS

			declare @Integrado as int
			declare @FInicio as datetime
			declare @sSql1 as nvarchar(180)
			declare @sSql2 as nvarchar (180)
			declare @sSql3 as nvarchar(180) 
			declare @sSql as nvarchar (512)
			declare @dLenAnt as tinyint
			declare @dLenNew as tinyint


			set @FInicio = dateadd(MINUTE, -1, getdate())
			set @sSql = N''
			set @sSql3 = N''
			set @sExtension = (select par_valor from trec_parametros where par_id = 54)

			select @integrado = par_valor from trec_parametros where par_id = 29

			--AVRS Integrada
			if (@integrado = 1)

				BEGIN

					set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
					set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from trec_grabacion NOLOCK where finicio < @fecInicio ''
					set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''

				END

			--AVRS Standalone
			else if(@integrado = 0)

				BEGIN

					set @sSql1 = ''Select top(1000) grab_id, grab_id, cast(grab_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
					set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from trec_grabacion NOLOCK where finicio < @fecInicio ''
					set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL''

				END

			--AVRS XION
			else if(@integrado = 2)
				BEGIN

					set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
					set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from ria_grabacion NOLOCK where finicio < @fecInicio ''
					set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL and cal_id in ( select cal_id from ccRIAWorkGroup_Calid)''

					--set @sSql1 = ''Select top(1000) grab_id, cal_id, cast(cal_id as varchar(20))+''+char(0x27)+@sExtension+char(0x27)
					--set @sSql2 = '', isnull(tipo_llamada,0), id_repositorio from ria_grabacion NOLOCK where finicio < @fecInicio ''
					--set @sSql2 = @sSql2 + '' and id_nivel_grito is NULL and grab_id=13''

				END

			set @sSql = @sSql1 + @sSql2 + N'' order by finicio asc''
			exec sp_executesql @sSql, N''@fecInicio datetime'', @fecInicio = @FInicio		
			'
	else
		set @sql = ''

	EXEC(@sql)


	set @process = 'alter SP  - trsp_GetFilesAnalisisGritos'
		if exists (select * from sys.procedures where name = N'trsp_GetFilesAnalisisGritos')
		set @sql='ALTER PROCEDURE [dbo].[trsp_AdmRecSearchNodeAgent] 

            @Workgroup int
            AS
            BEGIN

            SET NOCOUNT ON;

            select a.User_id, a.Nombres + '' '' +  a.ApellidoPaterno+ '' '' +  a.ApellidoMaterno, b.IDWG from ccUsers a
            inner join ccRIAWorkGroupUsersConsulta b
            on b.IDWG = @Workgroup
            where a.User_id = b.User_id and a.TipoUser_id = 1
            union 
            select a.User_id, a.Nombres + '' '' +  a.ApellidoPaterno+ '' '' +  a.ApellidoMaterno, b.IDWG from ccUsers a
            inner join ccRIAWorkGroupUsers b
            on b.IDWG = @Workgroup
            where a.User_id = b.User_id and a.TipoUser_id = 1
           END'
	else
		set @sql = ''

	EXEC(@sql)

		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		update trec_parametros set par_valor = @Version where par_id = 30 

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