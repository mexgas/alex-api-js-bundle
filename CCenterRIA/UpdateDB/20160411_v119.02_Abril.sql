/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Perez
Date: 2016/04/11
Description:



Database: CCenterRia
Required version: 119.01

IMPORTANT: In order to write the scripts to release in database go to the las part of this one to obtain guide and help to do it
*/
set nocount on

declare @version int,@versionFix int
declare @actualVersion int,@actualVersionFix int
declare @sql varchar(max)
declare @errorGenerated varchar(max)
declare @process varchar(max)
declare @versionALL varchar(max);

/* Version to release (use the version of your own databse)*/
/*******************************************************************************************************
Importante:la variable @version puede tener 2 valores dependiendo la necesidad que se tenga el primer ejemplo
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 118 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 119--**********actualizar a 118 sin fix
set @versionfix = 2
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version and @actualVersionFix = @versionfix-1
	begin
		begin tran
		begin try

		set @process = 'INSERT -------- ccMenus'
		set @sql ='if not exists(select * from ccmenus where type=3 and menu_id in(4220, 4230, 4240)) begin
						insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release ) values (4220, ''Reporte de teléfonos por estado de la república|Telephone report ordered by republic states'', 4000, ''B'', 4, 3, '''', ''60b188045ce43b6a1d77f7a81f67767fc90fbef71d57e4498d362c5c67a3c097d076f2f127f0f7af01beda4ac36008993c52871865dfbcc8d37183f0a429089f59ae97a60b9d269449063e6d38f93222a414d69d2a3fb7b721155619d8e6b4e2'')
						insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release ) values (4230, ''Reporte de Número de Teléfonos por Registro por Lista|Telephone Report per Registry List'',  4000, ''B'', 4, 3, '''',''074a6cc91623e51a5020bb702fad033d304b666112d87ff90249fb8676ec86395611c16cf4e162ebabf8555caeea9365241fede8508032e858587c216da52aa9fea8e00d5e2f12006bb1564615249179bb0886e83a3aa729313cdd7fcd79cf35'')
						insert into ccMenus(menu_id, menu_descrip, parent, Nivel, ordengral, [type], HelpSWF, release ) values (4240, ''Reporte de resultados de marcación|Dialing Result Report'', 4000, ''B'', 4, 3, '''', ''9cf7679f1b10838b63e4eae2368159813ae5d3eecaf4bccecfb21a247080897dc3e3d80988c85c0931f5a2fe77da619d446f04bcc6ff01e8247b5531a00ded6b'')
				   end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -------- mcaTipoLlamada'
		set @sql='if not exists (select * from sys.tables where name = N''mcaTipoLlamada'') begin
					CREATE TABLE [dbo].[mcaTipoLlamada](
					[tipoLlamada_id] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
					[descrip] [varchar](30) NOT NULL,
					CONSTRAINT [PK_mcaTipoLlamada] PRIMARY KEY CLUSTERED
					(
					[tipoLlamada_id] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					) ON [PRIMARY]
				 end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -------- mcaProtocolos'
		set @sql='if not exists (select * from sys.tables where name = N''mcaProtocolos'') begin
					CREATE TABLE [dbo].[mcaProtocolos](
					[protocolo_id] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
					[descrip] [varchar](30) NOT NULL,
					[nota] [varchar] (max)
					CONSTRAINT [PK_mcaProtocolos] PRIMARY KEY CLUSTERED
					(
					[protocolo_id] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					) ON [PRIMARY]
				 end'
		EXEC(@sql)

		set @process = 'CREATE TABLE -------- mcaProveedores'
		set @sql='if not exists (select * from sys.tables where name = N''mcaProveedores'') begin
					CREATE TABLE [dbo].[mcaProveedores](
					[provedor_id] [smallint] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
					[descrip] [varchar](30) NOT NULL,

					CONSTRAINT [PK_mcaProveedores] PRIMARY KEY CLUSTERED
					(
					[provedor_id] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON,  FILLFACTOR = 100) ON [PRIMARY]
					) ON [PRIMARY]
				 end'
		EXEC(@sql)

		set @process = 'CREATE TABLE --------mcaPlanMarcacion'
		set @sql='if not exists (select * from sys.tables where name = N''mcaPlanMarcacion'') begin
					CREATE TABLE [dbo].[mcaPlanMarcacion](
					[country_id] [smallint] NOT NULL,
					[provedor_id] [smallint] NOT NULL,
					[protocolo_id] [smallint] NOT NULL,
					[tipoLlamada_id] [smallint] NOT NULL,
					[prefijo] [varchar](15) NOT NULL,
					[longitud] [varchar](15) NULL
					CONSTRAINT [PK_mcaPlanMarcacion] PRIMARY KEY CLUSTERED
					(
						[country_id], [provedor_id], [protocolo_id], [tipoLlamada_id] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
					) ON [PRIMARY]
				  end'
		EXEC(@sql)

		set @process = 'INSERT -------- mcaTipoLlamada'
		set @sql='if not exists(select * from mcaTipoLlamada where tipoLlamada_id in(1, 2, 3, 4)) begin
					insert into mcaTipoLlamada (descrip) values (''Local'')
					insert into mcaTipoLlamada (descrip) values (''LD Nacional'')
					insert into mcaTipoLlamada (descrip) values (''Cel'')
					insert into mcaTipoLlamada (descrip) values (''Cel LD'')
				 end'
		EXEC(@sql)

		set @process = 'INSERT -------- mcaProveedores'
		set @sql='if not exists(select * from mcaProveedores where provedor_id in(1, 2, 3)) begin
					SET IDENTITY_INSERT [dbo].[mcaProveedores] ON
					INSERT [dbo].[mcaProveedores] ([provedor_id], [descrip]) VALUES (1, N''Maxcom'')
					INSERT [dbo].[mcaProveedores] ([provedor_id], [descrip]) VALUES (2, N''Marcatel'')
					INSERT [dbo].[mcaProveedores] ([provedor_id], [descrip]) VALUES (3, N''Telmex'')
					SET IDENTITY_INSERT [dbo].[mcaProtocolos] OFF
				 end'
		EXEC(@sql)

		set @process = 'INSERT -------- mcaProtocolos'
		set @sql='if not exists(select * from mcaProtocolos where protocolo_id in(1, 2, 3, 4, 5)) begin
					SET IDENTITY_INSERT [dbo].[mcaProtocolos] ON
					INSERT [dbo].[mcaProtocolos] ([protocolo_id], [descrip]) VALUES (1, N''ISDN sin ANI Rotatorio'')
					INSERT [dbo].[mcaProtocolos] ([protocolo_id], [descrip], [nota]) VALUES (2, N''ISDN con Ani Rotatorio'', ''En las ciudades con LADA donde Maxcom tiene numeración los números celulares van como locales, para las ciudades Monterrey, GDl y DF solo se toman 2 dígitos de la lada'')
					INSERT [dbo].[mcaProtocolos] ([protocolo_id], [descrip]) VALUES (3, N''SIP sin Ani Rotatorio'')
					INSERT [dbo].[mcaProtocolos] ([protocolo_id], [descrip], [nota]) VALUES (4, N''SIP con Ani Rotatorio'', ''En las ciudades con LADA donde Maxcom tiene numeración los números celulares van como locales, para las ciudades Monterrey, GDl y DF solo se toman 2 dígitos de la lada'')
					INSERT [dbo].[mcaProtocolos] ([protocolo_id], [descrip]) VALUES (5, N''R2'')
					SET IDENTITY_INSERT [dbo].[mcaProtocolos] OFF
				 end'
		EXEC(@sql)

		set @process = 'INSERT -------- mcaPlanMarcacion'
		set @sql='if not exists(select * from mcaPlanMarcacion where protocolo_id in(1, 2, 3, 4, 5) and tipoLlamada_id in (1, 2, 3, 4, 5)) begin
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 1, 1, ''%'', ''7'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 2, 1, ''%'', ''10'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 3, 1, ''%'', ''10'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 4, 1, ''%'', ''10'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 5, 1, ''%'', ''7'')

					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 1, 2, ''01%'', ''12'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 2, 2, ''%'', ''10'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 3, 2, ''01%'', ''12'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 4, 2, ''%'', ''10'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 5, 2, ''01%'', ''12'')

					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 1, 3, ''044%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 2, 3, ''044%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 3, 3, ''044%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 4, 3, ''044%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 5, 3, ''044%'', ''13'')

					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 1, 4, ''045%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 2, 4, ''045%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 3, 4, ''045%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 4, 4, ''045%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 1, 5, 4, ''045%'', ''13'')

					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 2, 3, 1, ''%'', ''10'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 2, 3, 2, ''01%'', ''12'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 2, 3, 3, ''044%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 2, 3, 4, ''045%'', ''13'')

					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 3, 5, 1, ''%'', ''7'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 3, 5, 2, ''01%'', ''12'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 3, 5, 3, ''044%'', ''13'')
					insert into mcaPlanMarcacion (country_id, provedor_id, protocolo_id, tipoLlamada_id, prefijo, longitud)
					values (1, 3, 5, 4, ''045%'', ''13'')
				 end'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_NetworkSocialAdminAccount'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_NetworkSocialAdminAccount]
@action int,
@meanContactTypeId smallint = 2,
@contactMeanId int=0,
@name	varchar(30)=null,
@conexionInfo	varchar(255)=null,
@inboundId	int=0,
@connUser	varchar(60)=null,
@ConnPass	varchar(30)=null,
@numMessages	tinyint=null,
@timeAlertMessage	tinyint=null,
@isActive bit =null,
@UserId int =null,
@idArea smallint =null,
@maxMails tinyint =3,
@answerTimeOut tinyint=null,
@revisionTime varchar(10)=null,
@daysTwitterRecord varchar(10)=null,
@closeConversationTime varchar(10)=null
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

declare @isActiveMail bit
set @isActiveMail=0

if @action = 1 begin--insert account twitter account
	DECLARE @tableConexionInfo TABLE(  id int, value varchar(255))
	if exists(select * from ContactMeanIn where conexionInfo = @conexionInfo and meanContactTypeId=@meanContactTypeId and inboundId<>@inboundId) begin
		select 0, ''Error: acount already exists''
		return -1
	end
	if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
	if @name is null set @name=''''
		--if @conexionInfo is null set @conexionInfo=''''
		if @connUser is null set @connUser=''''
		if @connPass is null set @connPass=''''
		if @numMessages is null set @numMessages=3
		if @timeAlertMessage is null set @timeAlertMessage=5
		if @isActive is null set @isActive=0
		if @answerTimeOut is null set @answerTimeOut=0
		if @closeConversationTime is null set @closeConversationTime=3

		--Twitter deja los token
		--conexion Info usuarioID|token|tokenSecret|time|daysTwitterRecord
		if @meanContactTypeId= 2 begin

			if @conexionInfo is null begin
				set @conexionInfo=''usuarioID|token|tokenSecret''
				set @revisionTime=isnull(@revisionTime,''1'')
				set @daysTwitterRecord=isnull(@daysTwitterRecord,''0'')
			end
			else begin
			select @conexionInfo
				insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
				set @conexionInfo=null

				SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

				SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
				SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
				SELECT @closeConversationTime=  isnull(@closeConversationTime,isnull(max(value),''3'')) FROM @tableConexionInfo where id=6
			end
			set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
		end


		insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut,closeConversationTime)
				values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut,@closeConversationTime)
		select 1,''insert''
	end
	else begin
		select @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
				@numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
				@answerTimeOut= isnull(@answerTimeOut,answerTimeOut),@name=isnull(@name,name),@closeConversationTime=isnull(@closeConversationTime,closeConversationTime)
				from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId

		--Twitter deja los token
		if @meanContactTypeId= 2 begin
			--usuarioID|token|tokenSecret|time|daysTwitterRecord|closeConversation
			insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
			set @conexionInfo=null

			SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

			SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''1'')) FROM @tableConexionInfo where id=4
			SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5

			set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
		end



		update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
			numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut,
			closeConversationTime=@closeConversationTime
			where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
		select 1,''update''
	end
end
else if @action = 2 begin
	if @inboundId=0
		select inboundId,conexionInfo,connUser,ConnPass,isActive,name from contactMeanIn where meanContactTypeId=@meanContactTypeId and isActive=1
	else
		select inboundId,conexionInfo,connUser,ConnPass,isActive,name from contactMeanIn where meanContactTypeId=@meanContactTypeId and isActive=1 and inboundId=@inboundId
end
else if @action = 3 begin
	select A.name,A.connUser,A.numMessages,A.timeAlertMessage,A.answerTimeOut ,B.tNotas,B.descripcion,C.graphic_id,D.frame
	from ContactMeanIn A
	inner join ccinbound B on A.inboundId=B.Inbound_id
	inner join ccRIAinboundGraph C on C.Inbound_id=B.Inbound_id
	inner join ccRIAGraphics D on D.graphic_id=C.graphic_id
	where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action=4 begin
	--Estos es para Twitter
	--usuarioID|token|tokenSecret|time|daysTwitterRecord
	select isnull(max(conexionInfo),''usuarioID|token|tokenSecret|1|0'') from contactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
END'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_RIAConfEspec'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
@User_id int
AS
set nocount on
/****
Conexion Info Email In
	protocol|server|ssl|port|cleanMail|revisionTime
Conexion Info Email Out
	serverOut|portOut|tls|sslOut
Conexion Info Twitter
	usuarioID|token|tokenSecret|time|daysTwitterRecord
***/
select  A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat mode, A.inactiveChatTime, A.maxChats, isnull(A.chatDomain,'''') chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
isnull(A.startStopRecording,0) startStopRecording
,isnull(B.name,'''') as nameMail,isnull(B.conexionInfo,'''') as conexionInfo,isnull(B.connUser,'''') as connUser,
isnull(B.ConnPass,'''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage,
isnull(B.IsActive,0) as Active, isnull(B.answerTimeOut,0) as answerTimeOut,A.callBackSurveyAgent,A.callBackSurveyClient,
case when C.CallsBySurvey is null or C.CallsBySurvey = 0 then 0 else 1 end isRelationSurvey,
isnull(nameTwitter,'''') nameTwitter,isnull(userTwitter,'''') userTwitter,isnull(numMessagesTwitter,3) numMessagesTwitter,
isnull(timeAlertMessageTwitter,10) timeAlertMessageTwitter,isnull(ActiveTwitter,0) ActiveTwitter,isnull(answerTimeOutTwitter,10) answerTimeOutTwitter,
--usuarioID|token|tokenSecret|time|daysTwitterRecord
isnull(conexionInfoTwitter,''usuarioID|token|tokenSecret|1|0'') conexionInfoTwitter
,isnull(closeConversationTimeTwitter,3) closeConversationTimeTwitter,isnull(closeConversationTime,3) closeConversationTimeEmail
from ccInbound A
left join ContactMeanIn B on A.inbound_id=B.inboundId and B.meanContactTypeId=1
left join ccCamps C on C.cam_id=A.cam_id
left join (
select D.inboundId,
D.name as nameTwitter,D.connUser as userTwitter,D.numMessages as numMessagesTwitter,
D.timeAlertMessage as timeAlertMessageTwitter,
D.IsActive as ActiveTwitter, D.answerTimeOut as answerTimeOutTwitter,D.conexionInfo as conexionInfoTwitter,
closeConversationTime as  closeConversationTimeTwitter
from ContactMeanIn D
where D.meanContactTypeId=2) D on A.Inbound_id=D.inboundId
where inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 4))
return(0)
set nocount off'
		EXEC(@sql)


		set @process = 'Alter SP -- ccsp_TwitterInitialStatistics'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_TwitterInitialStatistics]
@inboundId int=0,
@Option AS SMALLINT=0,
@User_id AS SMALLINT=0
AS
BEGIN

	SET NOCOUNT ON;

	if(@Option=0)
	begin
		select
		count(*) received,
		count(case when messageStatusId = 1 then 1 else null end) pending,
		count(case when messageStatusId in (2,3) then 1 else null end) assigned,
		count(case when messageStatusId = 4 then 1 else null end) unassigned,
		count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
		count(case when messageStatusId = 7 then 1 else null end) rejected,
		count(case when messageStatusId = 8 then 1 else null end) programFwd,
		count(case when messageStatusId = 9 then 1 else null end) forwarding,
		count(case when messageStatusId in (10,11) then 1 else null end) closed,
		count(case when messageStatusId = 3 then 1 else null end) active ,
		isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
		isnull(AVG(msg.twait),0) avgtWait,
		isnull(MAX(msg.twait),0) maxtWait
		from messageOutTwitter msg(nolock) join conversationTwitter con (nolock) on con.conversationTwitterId=msg.conversationTwitterId
		where inboundId=@inboundId --and [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121)
		and ( messageStatusId in (1,4) or [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121) )
	end
	if @Option = 1
	BEGIN
		select
		count(*) received,
		count(case when messageStatusId = 1 then 1 else null end) pending,
		count(case when messageStatusId in (2,3) then 1 else null end) assigned,
		count(case when messageStatusId = 4 then 1 else null end) unassigned,
		count(case when messageStatusId in (5,6,10,11) then 1 else null end) sent,
		count(case when messageStatusId = 7 then 1 else null end) rejected,
		count(case when messageStatusId = 8 then 1 else null end) programFwd,
		count(case when messageStatusId = 9 then 1 else null end) forwarding,
		count(case when messageStatusId in (10,11) then 1 else null end) closed,
		count(case when messageStatusId = 3 then 1 else null end) active ,
		isnull(AVG(msg.twait + msg.tretention + msg.tresponse),0) avgtAtention,
		isnull(AVG(msg.twait),0) avgtWait,
		isnull(MAX(msg.twait),0) maxtWait,
		InboundId inboundId
		from messageOutTwitter msg (nolock) join conversationTwitter con (nolock) on con.conversationTwitterId=msg.conversationTwitterId
		where inboundId in (select inbound_id from ccInbound where inbound_id in (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0) and chat = 4)
		and ( messageStatusId in (1,4) or [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121) )
		GROUP BY InboundId
	END
END'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_TwitterSave'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_TwitterSave]
 @action int,
 @conversationId int=0,
 @messageOutTwitterId bigint=null,
 @userId int=0,
 @isLogout bit=0,
 @messageId int =null,
 @messageStatusId int=null,
 @inboundId smallint=null,
 @twitId varchar(255)=null,
 @dispositionId smallint=0,
 @subDispositionId smallint=0,
 @timeAtt int = 0,
 @tWrapUp int =0,
 @tRetention int = 0
AS
BEGIN

declare @meanContactTypeId smallint
declare @isEndConversation bit

set @meanContactTypeId = 2 --Twitter


 if @action = 1 BEGIN  -- desasignar
	if @messageOutTwitterId = 0 begin
		insert into [messageUnAssingedTwit](messageOutTwitterId,userId,[time],isLogout)
		select messageOutTwitterId,userId,datediff(ss,tQueue,getdate()) as [time],1 from [messageOutTwitter]  where userId=@userId and messageStatusId in (2,3)

		update [messageOutTwitter] set twitId='''',tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0 where userId=@userId and messageStatusId in (2,3)
	end
	else begin
		insert into [messageUnAssingedTwit](messageOutTwitterId,userId,[time],isLogout)
		select messageOutTwitterId,userId,datediff(ss,tQueue,getdate()) as [time],0 as isLogout from [messageOutTwitter] where userId=@userId and messageOutTwitterId=@messageOutTwitterId and messageStatusId in (2,3)

		update [messageOutTwitter] set twitId='''',tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0 where userId=@userId and messageOutTwitterId=@messageOutTwitterId and messageStatusId in (2,3)
	end
END
else if @action = 2 begin --Coloca el valor del TwitId
	update [messageOutTwitter] set twitId=@twitId where messageOutTwitterId=@messageOutTwitterId
end
else if @action = 5 BEGIN --Twitter por contestar
	--Status DOWNLOAD,Assigned,READ,UnaSSIGNED
	select A.conversationTwitterId,B.userId,A.screenNameClient,A.screenNameInbound,B.messageStatusId,max(B.messageOutTwitterId) as messageId
		from conversationTwitter A
		inner join [messageoutTwitter] B on A.conversationTwitterId = B.conversationTwitterId
		where A.inboundId = @inboundId and B.messageStatusId in(1,2,3,4) and meanContactTypeId = @meanContactTypeId
		GROUP BY A.conversationTwitterId,A.inboundId,A.screenNameClient,A.screenNameInbound,B.messageStatusId,B.userId
END
else if @action = 6 BEGIN --update Time Attention, Retencion
	select @messageId=max(messageOutTwitterId) from messageOutTwitter with(nolock) where conversationTwitterId=@conversationId
	update messageOutTwitter set tResponse=@timeAtt,tRetention=@tRetention,isSender=1,messageStatusId=@messageStatusId where messageOutTwitterId=@messageId
END
else if @action = 7 BEGIN --Cambia el status del mensaje
	select @messageId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId

	--Status Read
	if @messageStatusId=3  update [messageOutTwitter] set tWait=DATEDIFF(ss,tQueue, getdate()) where messageOutTwitterId=@messageId
	--Status Send
	if @messageStatusId=6  begin
		select @isEndConversation=isFinished from conversationTwitter where conversationTwitterId=@conversationId

		if @isEndConversation = 1 set @messageStatusId=11--Close conversation by Agent
		update [messageOutTwitter] set tSend=getdate() where messageOutTwitterId=@messageId

	end
	update [messageOutTwitter] set messageStatusId=@messageStatusId where messageOutTwitterId=@messageId
END
else if @action = 10 begin --Carga las conversaciones pendientes
	if @conversationId = 0 begin
		select A.conversationTwitterId,max(B.messageOutTwitterId) as messageId,B.userId,A.inboundId,max(C.twitId) as twitId
			from conversationTwitter A
			inner join messageOutTwitter B on A.conversationTwitterId = B.conversationTwitterId
			inner join messageInTwitter C on C.conversationTwitterId=B.conversationTwitterId
			where A.meanContactTypeId = @meanContactTypeId
			and B.messageStatusId in(5,7,8,9) and isSender=1 and A.inboundId=@inboundId
			GROUP BY A.conversationTwitterId,A.inboundId,B.userId
	end
	else begin
	select A.conversationTwitterId,max(B.messageOutTwitterId) as messageId,B.userId,A.inboundId,max(C.twitId) as twitId
			from conversationTwitter A
			inner join messageOutTwitter B on A.conversationTwitterId = B.conversationTwitterId
			inner join messageInTwitter C on C.conversationTwitterId=B.conversationTwitterId
			where A.meanContactTypeId = @meanContactTypeId
			and A.conversationTwitterId = @conversationId
			GROUP BY A.conversationTwitterId,A.inboundId,B.userId
	end
end
else if @action = 11 BEGIN --Califica el mensaje y pone el tiempo Notas
	if @subDispositionId <> 0 begin
		select @isEndConversation=isnull(EndConversation,0) from ccTipoCalifSub where califSub_id=@subDispositionId
	end
	else begin
		select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@dispositionId
	end
	if not exists(select * from relationMessageDispositionTwit where messageOutTwitterId=@messageId) begin
		insert into relationMessageDispositionTwit(messageOutTwitterId,dispositionId,subDispositionId) values(@messageId,@dispositionId,@subDispositionId)
	end
	else begin
		update relationMessageDispositionTwit set dispositionId=@dispositionId,subDispositionId=@subDispositionId where messageOutTwitterId=@messageId
	end
	update [messageOutTwitter] set tWrapUp=@tWrapUp where messageOutTwitterId=@messageId
	if @isEndConversation = 1 begin
		select @conversationId=conversationTwitterId from [messageOutTwitter]where messageOutTwitterId=@messageId
		update conversationTwitter set isFinished=@isEndConversation where conversationTwitterId=@conversationId
	end
END
else if @action = 12 BEGIN  --Tiempo de cola
	select @messageId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId
	update [messageOutTwitter] set tQueue=getdate(),userId=@userId where messageOutTwitterId=@messageId
END
else if @action = 13 BEGIN  --Limpia las conversaciones quedaron abiertas por cerrar la aplicacion
	update [messageoutTwitter] set @messageStatusId=1,twitId='''',tQueue=null,userId=0,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0  where messageStatusId in(2,3)
END

END'
		EXEC(@sql)

		set @process = ''
		set @sql=''
		EXEC(@sql)

		set @process = ''
		set @sql=''
		EXEC(@sql)



		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
		--exec ccsp_getVersion 'BDF', @versionFix

		commit tran
		end try

		begin catch

			/* Error generated based on sintax */
			select @errorGenerated = 'DB script version: ' + cast(@version as nvarchar) + '''.''' + cast(@versionfix as nvarchar) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() as nvarchar) + ''' Number: ''' + cast(@@error as nvarchar) + ''' Message: '''+ error_message()
			RAISERROR(@errorGenerated, 11, 1)

		rollback tran
		end catch
	end
else
	begin
		/* Error generated based on database version */
		select 'Incorrect database version, actual version: ' + cast(@actualVersion as varchar(5)) + ''', version to release: ''' + cast(@version as varchar(5))
	end

set nocount off