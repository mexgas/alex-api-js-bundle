/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: Miguel Perez
Date: 2015/03/07
Description:



Database: CCenterRia
Required version: 118.06

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
set @versionfix = 1
--select * from ccsettings where setting_id=77
/* Actual version (use your own script to do it) */
exec @actualVersion = ccsp_getVersion 'BD'


select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if @actualVersion = @version-1
	begin
		begin tran
		begin try



		set @process = ' insert into ccMenus  Twitter----- '
		set @sql='if not exists(select * from ccMenus where menu_id in (11000,11010,11020,11030,11040) ) begin
		insert into ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
values(11000,''Twitter|Twitter'',11000,''A'',11,3,'''',''ac7a2fd4c5d63bd0c014419d9d346e0d44d062246c8da8eba8f492282d36204c'')


insert into ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
values(11010,''Twitter por ACD|Twitter ACD'',11000,''B'',11,3,'''',''4edf4b5c9ccded5ad3b146fb67e7e732c35d893b39f4019f2c9d9519dd112b50'')


insert into ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
values(11020,''Twitter por Agente|Agent Twitter'',11000,''B'',11,3,'''',''dadf2054ee027fa4e15a09922211034bf69d8db17659ff8c9dbb1b858ed36ad85ea74d7b78f2a9ae6053b3868deb3998'')


insert into ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
values(11030,''Twitter Detalle|Twitter Detail'',11000,''B'',11,3,'''',''4356689ad0cefdbd48494873256e95368f54fbbe25f67712b06e843ab9593fcd'')


insert into ccMenus (menu_id,menu_descrip,parent,Nivel,ordengral,type,HelpSWF,release)
values(11040,''Twitter General|Twitter General'',11000,''B'',11,3,'''',''7b3fe5284cf4d30e0ca0383fb1c680976e6ed109dc62044baa3b498e5495f2236ee8d4b0d88ccaf51df41c5126eb09e9'')

end '
		EXEC(@sql)

		set @process = 'update ccmenus --- menu_id 19 y 54'
		set @sql='update ccmenus
set menu_descrip = ''Mensajes de audio|Automatic Messages'', release = ''6ba081beaebb7c3054834a5c627dd3ab16a48a99f24fe2df99842cb867a74008cd7b08a9115522c33904183226a16c00''
where menu_id = 19

update ccmenus
set menu_descrip = ''Mensajes de audio|Automatic Messages'', release = ''c7439dca463672a2f50dc0d2f578859ae81f5b2245ba654ab4f3617b1956cde0b438747786b6f92100897eb6ca415c0d''
where menu_id = 54'
		EXEC(@sql)


		set @process = 'alter column valor --ccSettings'
		set @sql='alter table ccsettings alter column valor varchar(200)'
		EXEC(@sql)

		set @process = 'alter column description --ccSettings'
		set @sql='alter table ccsettings alter column description varchar(600)'
		EXEC(@sql)

		set @process = 'update validate ccSettings --101'
		set @sql='update ccSettings set validate=''.*'' where setting_id=101'
		EXEC(@sql)

		set @process = 'insert into ccSettings 182-------- '
		set @sql='if not exists (select * from ccSettings where setting_id = 182) begin
		insert into ccSettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
 			values (182,0,''Habiliata el modo de reproduccion de Grabaciones'',1,''X'',''0/Jplayer 1/Applet 2/Dinamico'',''Type of player'',1,''.*'')
  		end'
		EXEC(@sql)

		set @process = 'insert setting_id 183'
		set @sql='if not exists (select * from ccSettings where setting_id = 183) begin
		insert ccsettings (setting_id,valor,descripcion,status,tipo,detalle,description,bloadsettings,validate)
values (183,'''',''WebRTC Configuration'',1,''AGT'',''Configuración para WebRTC <type>|<ws[,ws_gw]>|<private_identity>|<public_identity>|<password>|<realm>|<ice_servers>|<IMS>|<WebBreaker>'',
''WebRTC Configuration: <type>|<ws[,ws_gw]>|<private_identity>|<public_identity>|<password>|<realm>|<ice_servers>|<IMS>|<WebBreaker>'',1,''^[0-1]\|.*\|.*\|.*\|.*\|.*\|.*\|(true|false)\|(true|false)$'')
end'
		EXEC(@sql)

		set @process = 'Drop Constraint ContactMeanIn.connUser UNIQUE'
		set @sql='declare @name nvarchar(max),@sql2 nvarchar(max)
if exists(SELECT  OBJECT_NAME(ind.object_id) AS ObjectName
      , ind.name AS IndexName
      , col.name AS ColumnName
FROM    sys.indexes ind
        INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id AND ind.index_id = ic.index_id
        INNER JOIN sys.columns col ON ic.object_id = col.object_id AND ic.column_id = col.column_id
        INNER JOIN sys.tables t ON ind.object_id = t.object_id
WHERE   t.is_ms_shipped = 0 and OBJECT_NAME(ind.object_id)=''ContactMeanIn'' and col.name=''connUser'')
begin
	SELECT  @name= ind.name FROM    sys.indexes ind
			INNER JOIN sys.index_columns ic ON ind.object_id = ic.object_id AND ind.index_id = ic.index_id
			INNER JOIN sys.columns col ON ic.object_id = col.object_id AND ic.column_id = col.column_id
			INNER JOIN sys.tables t ON ind.object_id = t.object_id
	WHERE   t.is_ms_shipped = 0 and OBJECT_NAME(ind.object_id)=''ContactMeanIn'' and col.name=''connUser''
	set @sql2=''ALTER TABLE ContactMeanIn DROP CONSTRAINT ''+@name
	exec (@sql2)
end'
		EXEC(@sql)



		set @process = 'ADD COlumn ContactMeanIn.closeConversationTime'
		set @sql='alter table ContactMeanIn add closeConversationTime tinyint default(3)'
		EXEC(@sql)

		set @process = 'update ContactMeanIn.closeConversationTime default 3'
		set @sql='update ContactMeanIn set closeConversationTime=3'
		EXEC(@sql)


		set @process = 'Drop  Tables --Twitter'
		set @sql='if exists (select * from sys.tables where name = N''messageInTwitter'')  Drop table messageInTwitter
if exists (select * from sys.tables where name = N''searchInboundTwitter'')  Drop table searchInboundTwitter
if exists (select * from sys.tables where name = N''searchHashtagTwitter'')  Drop table searchHashtagTwitter
if exists (select * from sys.tables where name = N''searchConversationTwitter'')  Drop table searchConversationTwitter
if exists (select * from sys.tables where name = N''relationMessageDispositionTwit'')  Drop table relationMessageDispositionTwit
if exists (select * from sys.tables where name = N''messageUnAssingedTwit'')  Drop table messageUnAssingedTwit
if exists (select * from sys.tables where name = N''messageOutTwitter'')  Drop table messageOutTwitter
if exists (select * from sys.tables where name = N''conversationTwitter'')  Drop table conversationTwitter
if exists (select * from sys.tables where name = N''TipoTwit'')  Drop table TipoTwit
'
		EXEC(@sql)


		set @process = 'Insert -- meanContactType Twitter'
		set @sql='if not exists(select * from meanContactType where name=''Twitter'') begin
		SET IDENTITY_INSERT meanContactType ON
			insert into meanContactType(meanContactTypeId,name,isActive) values(2,''Twitter'',1)
		SET IDENTITY_INSERT meanContactType OFF
		end'
		EXEC(@sql)

		set @process = 'Create table -- conversationTwitter'
		set @sql='if not exists (select * from sys.tables where name = N''conversationTwitter'') begin
		create table conversationTwitter (
conversationTwitterId bigint primary key identity,
inboundId smallint not null,
isFinished bit not null default(0),
clientId varchar(255) not null,
screenNameClient varchar(100) not null,
screenNameInbound varchar(100) not null,
meanContactTypeId smallint not null,
[replayId] [varchar](255) NULL
)
end'
		EXEC(@sql)

		set @process = 'create table -- messageInTwitter'
		set @sql='if not exists (select * from sys.tables where name = N''messageInTwitter'') begin
		create table messageInTwitter (
messageInTwitterId bigint primary key identity,
conversationTwitterId bigint not null,
tipoTwitId tinyint not null default(1),---1 Post,2 Mensaje Directo
twitId varchar(255) not null,
[date] datetime not null
)
end'

	EXEC(@sql)


		set @process = 'create table -- messageOutTwitter'
		set @sql='if not exists (select * from sys.tables where name = N''messageOutTwitter'') begin
		create table messageOutTwitter (
messageOutTwitterId bigint primary key identity,
conversationTwitterId bigint not null,
messageStatusId int not null,
twitId varchar(255) not null default(''''),
tipoTwitId tinyint not null default(1),---1 Post,2 Mensaje Directo
[userId] smallint not null,
[tQueue] datetime null,
tWait int not null default(0),
tRetention int not null default(0),
tResponse int not null default(0),
tWrapUp tinyint not null default(0),
tSend [datetime] null,
isSender bit not null default (0),
date datetime not null,
ninteration int not null default(1),
messageInTwitterIdIni int not null,
messageInTwitterIdEnd int not null
)
end'

	EXEC(@sql)


		set @process = 'create table -- searchInboundTwitter'
		set @sql='if not exists (select * from sys.tables where name = N''searchInboundTwitter'') begin
		create table searchInboundTwitter(
		searchTwitterId int not null,
		inboundId smallint not null
		)
	end'

		EXEC(@sql)

		set @process = 'create table -- searchHashtagTwitter'
		set @sql='if not exists (select * from sys.tables where name = N''searchHashtagTwitter'') begin
		create table searchHashtagTwitter(
		searchTwitterId int primary key identity not null,
		hashtag varchar(100) not null UNIQUE
		)
	end'

		EXEC(@sql)


		set @process = 'create table -- searchConversationTwitter'
		set @sql='if not exists (select * from sys.tables where name = N''searchConversationTwitter'') begin
		create table searchConversationTwitter(
searchTwitterId int not null,
conversationTwitterId bigint not null,
)
end'

EXEC(@sql)

		set @process = 'create table -- relationMessageDispositionTwit'
		set @sql='if not exists (select * from sys.tables where name = N''relationMessageDispositionTwit'') begin
		create table relationMessageDispositionTwit(
messageOutTwitterId bigint,
dispositionId int not null,
subDispositionId int not null
)
end'
		EXEC(@sql)


		set @process = 'Create table -- TipoTwit '
		set @sql='if not exists (select * from sys.tables where name = N''tipoTwit'') begin
		Create table tipoTwit (
tipoTwit_Id tinyint primary key identity,
tipoTwit varchar(100) not null
)
end'

		EXEC(@sql)

		set @process = 'Create table -- messageUnAssingedTwit '
		set @sql='if not exists (select * from sys.tables where name = N''messageUnAssingedTwit'') begin
		Create table messageUnAssingedTwit (
messageOutTwitterId bigint,
userId int not null,
time int not null,
isLogout bit not null
)
end'

		EXEC(@sql)

		set @process = 'FOREIGN Keys - Add'
    set @Sql='
if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''conversationTwitter'' and  c1.[name]=''Inbound_id'')
ALTER TABLE [conversationTwitter] ADD FOREIGN KEY (inboundId) REFERENCES ccinbound (Inbound_id)

if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''conversationTwitter'' and  c1.[name]=''meanContactTypeId'')
ALTER TABLE [conversationTwitter] ADD FOREIGN KEY (meanContactTypeId) REFERENCES meanContactType (meanContactTypeId)

if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''messageOutTwitter'' and  c1.[name]=''messageStatusId'')
ALTER TABLE [messageOutTwitter] ADD FOREIGN KEY ([messageStatusId]) REFERENCES messageStatus (messageStatusId)

if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''messageOutTwitter'' and  c1.[name]=''tipoTwit_Id'')
ALTER TABLE [messageOutTwitter] ADD FOREIGN KEY ([tipoTwitId]) REFERENCES tipoTwit (tipoTwit_Id)

if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''messageInTwitter'' and  c1.[name]=''tipoTwit_Id'')
ALTER TABLE [messageInTwitter] ADD FOREIGN KEY ([tipoTwitId]) REFERENCES tipoTwit (tipoTwit_Id)

if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''messageInTwitter'' and  c1.[name]=''conversationTwitter'')
ALTER TABLE [messageInTwitter] ADD FOREIGN KEY (conversationTwitterId) REFERENCES [conversationTwitter] (conversationTwitterId)

if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''searchInboundTwitter'' and  c1.[name]=''Inbound_id'')
ALTER TABLE [searchInboundTwitter] ADD FOREIGN KEY ([inboundId]) REFERENCES ccinbound (Inbound_id)

if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''searchInboundTwitter'' and  c1.[name]=''searchTwitterId'')
ALTER TABLE [searchInboundTwitter] ADD FOREIGN KEY (searchTwitterId) REFERENCES searchHashtagTwitter (searchTwitterId)

if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''searchConversationTwitter'' and  c1.[name]=''conversationTwitterId'')
ALTER TABLE [searchConversationTwitter] ADD FOREIGN KEY ([conversationTwitterId]) REFERENCES conversationTwitter (conversationTwitterId )

if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''searchConversationTwitter'' and  c1.[name]=''conversationTwitterId'')
ALTER TABLE [searchConversationTwitter] ADD FOREIGN KEY (searchTwitterId) REFERENCES searchHashtagTwitter (searchTwitterId)

if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''relationMessageDispositionTwit'' and  c1.[name]=''messageOutTwitterId'')
ALTER TABLE relationMessageDispositionTwit ADD FOREIGN KEY (messageOutTwitterId) REFERENCES messageOutTwitter (messageOutTwitterId)

if not exists(SELECT f.* FROM sys.foreign_key_columns f INNER JOIN sys.all_columns c1  ON f.parent_object_id = c1.[object_id] AND f.parent_column_id = c1.column_id where OBJECT_NAME(f.parent_object_id)=''messageUnAssingedTwit'' and  c1.[name]=''messageOutTwitterId'')
ALTER TABLE messageUnAssingedTwit ADD FOREIGN KEY (messageOutTwitterId) REFERENCES messageOutTwitter (messageOutTwitterId)
'


	EXEC(@Sql)

	set @process = 'Insert --- tipoTwit'
	set @sql='insert into tipoTwit(tipoTwit) values(''Posting'')
insert into tipoTwit(tipoTwit) values(''Message Direct'')'
	EXEC(@Sql)

	set @process = 'Drop PROCEDURE  --- ccspADMaddConversationTweet,ccspADMaddConversationTweet'
	set @sql='if exists (select * from sys.procedures where name = N''ccspADMaddConversationTweet'') DROP PROCEDURE ccspADMaddConversationTweet
	if exists (select * from sys.procedures where name = N''ccsp_NetworkSocialAdminAccount'') DROP PROCEDURE ccsp_NetworkSocialAdminAccount
	if exists (select * from sys.procedures where name = N''ccsp_TwitterInitialStatistics'') DROP PROCEDURE ccsp_TwitterInitialStatistics
	if exists (select * from sys.procedures where name = N''ccsp_TwitterSave'') DROP PROCEDURE ccsp_TwitterSave
	'
	EXEC(@Sql)


	set @process = 'ALTER PROCEDURE [dbo].[ccsp_MailAdminAccount]--------'
	set @sql='ALTER PROCEDURE [dbo].[ccsp_MailAdminAccount]
@action int,
@meanContactTypeId smallint = 1,
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
/****
Conexion Info Email In
	protocol|server|ssl|port|cleanMail|revisionTime
Conexion Info Email Out
	serverOut|portOut|tls|sslOut
Conexion Info Twitter
	usuarioID|token|tokenSecret|time|daysTwitterRecord
***/


declare @isActiveMail bit
set @isActiveMail=0

if @action = 1 begin --checha si esta activo el servicio
	select @isActiveMail = valor from ccSettings where setting_id=152
	if @isActiveMail = 1 begin
		select @isActiveMail=(case when isActive = 1 and @isActiveMail = 1 then 1 else 0 end) from meanContactType where meanContactTypeId = 1
	end
	select @isActiveMail as isActiveMail
	return (0)
end
else if @action = 2 begin -- carga la relacion de especialidades y cuentas de email de entrada
	select A.inboundId,A.conexionInfo,A.connUser,A.connPass
		from ContactMeanIn A
			inner join ccInbound B on A.inboundId=B.Inbound_Id
		where meanContactTypeId = 1 and B.Status=1 and A.isActive=1
end
else if @action = 3 begin	--
	select name,conexionInfo,connUser,ConnPass,numMessages,timeAlertMessage,answerTimeOut from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 4 begin--insert or update relation mail whit ACD by in
	---Es necesario cambiar [ccsp_NetworkSocialAdminAccount] por que tambien se ocupa aqui
	DECLARE @tableConexionInfo TABLE(  id int, value varchar(255))
	if @connUser='''' 	set @connUser=''nuxiba@nuxiba.com''
	if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
		if not exists(select * from ContactMeanIn where connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin
		if @name is null set @name=''''
		if @conexionInfo is null and @meanContactTypeId=1  set @conexionInfo=''''
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
				set @revisionTime=isnull(@revisionTime,''5'')
				set @daysTwitterRecord=isnull(@daysTwitterRecord,''0'')
			end
			else begin
			select @conexionInfo
				insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
				set @conexionInfo=null

				SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

				SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''5'')) FROM @tableConexionInfo where id=4
				SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
			end
			set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
		end



		insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut,closeConversationTime)
				values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut,@closeConversationTime)
		select 1,''insert''
	end
		else select -1,''insert''
	end
	else begin
		if not exists(select * from ContactMeanIn where inboundId<>@inboundId and connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin

			select @name=isnull(@name,name), @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
				@numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
				@answerTimeOut= isnull(@answerTimeOut,answerTimeOut),@closeConversationTime=isnull(@closeConversationTime,closeConversationTime)
			from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId


			--Twitter deja los token
			if @meanContactTypeId= 2 begin
				--usuarioID|token|tokenSecret|time|daysTwitterRecord
				insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
				set @conexionInfo=null

				SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

				SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''5'')) FROM @tableConexionInfo where id=4
				SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
				set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
			end


			update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
				numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut,
				closeConversationTime=@closeConversationTime
				where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
			select 1,''update''
		end
		else select -1,''update''
	end
	return (0)
end

else if @action = 5 begin--parameters check conection Mail In
	select conexionInfo,connUser,connPass from ContactMeanIn with(nolock) where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 6 begin--parameters check conection Mail Out
	select conexionInfo,connUser,connPass
		from ContactMeanOut with(nolock) where contactMeanOutId  = @contactMeanId
end
else if @action = 7 begin--list mail out by ACD
	select A.contactMeanOutId,A.name, A.conexionInfo,A.connUser,A.connPass,A.isActive
		from ContactMeanOut A with(nolock)

end
else if @action = 8 begin--insert account mail out
	if not exists(select * from ContactMeanOut where connUser=@connUser) begin
		insert into ContactMeanOut (meanContactTypeId,name,conexionInfo,connUser,ConnPass,isActive)
			values (@meanContactTypeId,@name,@conexionInfo,@connUser,@connPass,@isActive)
		select 1
		return(0)
	end
	else select -1
end
else if @action = 9 begin--update account mail out
	if not exists(select * from ContactMeanOut where contactMeanOutId <> @contactMeanId  and connUser=@connUser) begin

		select  @meanContactTypeId=isnull(@meanContactTypeId,meanContactTypeId),@name=isnull(@name,name),
			@conexionInfo=isnull(@conexionInfo,conexionInfo),@connUser=isnull(@connUser,connUser),
			@connPass=isnull(@connPass,ConnPass),@isActive=isnull(@isActive,isActive)
			from ContactMeanOut where contactMeanOutId = @contactMeanId

		update ContactMeanOut set meanContactTypeId=@meanContactTypeId,name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,isActive=@isActive
		 where contactMeanOutId = @contactMeanId
		 select 1,''update ''
	end
	else select -1
end
else if @action = 10 begin	--insert relation mail out and ACD
	if not exists(select * from relationContactMeanOutInbound where contactMeanOutId=@contactMeanId) begin
		insert into relationContactMeanOutInbound(contactMeanOutId,inboundId) values (@contactMeanId,@inboundId)
	end
end
else if @action = 11 begin --delete relation mail out and ACD
	delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId and inboundId=@inboundId
end
else if @action = 12 begin --delete mail out
	delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId
	delete ContactMeanOut where contactMeanOutId=@contactMeanId
end
else if @action = 13 begin --delete mail out
	if not exists(select * from ContactMeanOut where contactMeanOutId=@contactMeanId) begin
		update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
		select 1
	end
	else select -1
end
else if @action = 14 begin
	select * from relationContactMeanOutInbound
end
else if @action = 15 begin
	select * from relationContactMeanOutInbound where inboundId=@inboundId
end
--else if @action = 16 begin
--	update ccRIACat_Areas set maxMails = @maxMails where IDArea=@idArea
--end
else if @action = 17 begin	--
	select A.conexionInfo,A.connUser,A.connPass,A.isActive from ContactMeanIn A where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
End
else if @action = 18 begin	--
	select A.contactMeanOutId,A.conexionInfo,A.connUser,A.connPass from contactMeanOut A where isActive=1

end
else if @action = 19 begin	--
	select contactMeanOutId,inboundId from relationContactMeanOutInbound where inboundId = @inboundId or @inboundId = 0 order by inboundId

end
else if @action = 20 begin --relation MailOut and ACD
	select B.inboundId,A.conexionInfo,A.connUser,A.connPass
	from ContactMeanOut A join relationContactMeanOutInbound B
	on B.contactMeanOutId=A.contactMeanOutId
	where B.inboundId = @inboundId or @inboundId = 0
end
else if @action = 21 begin --relation MailOut and ACD
	update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
end
else if @action = 22 begin --Update type
	if @meanContactTypeId = 2 --Twitter
		set @conexionInfo=''|||5|0''
	else
		set @conexionInfo=''''
	update ContactMeanIn set name = '''', conexionInfo = @conexionInfo, connUser = '''', isActive = 0 where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
	select 1,''unAssigned''
end
END'
	EXEC(@sql)

	set @process = 'create PROCEDURE -- ccspADMaddConversationTweet'
	set @sql='CREATE PROCEDURE [dbo].[ccspADMaddConversationTweet]
@action int,
@inboundId int = null,
@clientId varchar(255)= null,
@isFinished bit = 0,
@screenNameClient varchar(100) = null,
@screenNameInbound varchar(100) = null,
@meanContactTypeId smallint = null,
@twitId varchar(255) = null,
@conversationId bigint = null,
@date datetime=null,
@replayId varchar(255)=null,
@tipoTwitId tinyint=1,
@messageId bigint = null,
@dispositionId smallint=0,
@subDispositionId smallint=0,
@tWrapUp int =0

as
set nocount on

declare @ninteration int ,@messageOutTwitterId bigint
declare @userId int
declare @isEndConversation bit


if @action = 1 begin --Revisa que exista la conversacion
	select @conversationId =  isnull(max(conversationTwitterId),0) from conversationTwitter where isFinished = 0 and meanContactTypeId = 2 and ClientId = @clientId and inboundId=@inboundId
	if @conversationId = 0
		select 0,''New Conversation''
	else begin
		declare @closeConversation tinyint
		declare @tRsponse datetime
		select @tRsponse = isnull(max(tSend),getdate()) from messageOutTwitter where conversationTwitterId = @conversationId
		select @closeConversation = closeConversationTime from contactMeanIn
		 if datediff(dd,getdate(),@tRsponse ) > @closeConversation
			select 0,''New Conversation Close System''
		else
			select @conversationId
	end
    return 0
end
else if @action = 2 begin --Nueva conversacion y mensaje entrada y salida
    --agregar tabla de messagetwit fecha de descarga
	if @replayId is null or @replayId=''''
		set @replayId= ''0''
    insert into conversationTwitter (inboundId,ClientId,isFinished,screenNameClient,screenNameInbound,meanContactTypeId,replayId)
    values(@inboundId,@clientId,@isFinished,@screenNameClient,@screenNameInbound,@meanContactTypeId,@replayId)
    set  @conversationId  = SCOPE_IDENTITY()
	insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
	set @messageId=SCOPE_IDENTITY()
	insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
	values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)
    select 0 as userId,@conversationId as conversationId, @messageId as messageId
    return
end
else if @action = 3 begin --Nuevo mensaje Entrada
	---Revisa que no se contesto el twitt
	select @messageOutTwitterId=max(A.messageOutTwitterId),@ninteration= count(B.messageInTwitterId)
	from messageOutTwitter A inner join messageInTwitter B on A.conversationTwitterId=B.conversationTwitterId
	where A.conversationTwitterId=@conversationId and A.messageStatusId not in (5,6,7,8,9,10,11)

	insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
	set @messageId=SCOPE_IDENTITY()

	if  @messageOutTwitterId is null begin
		insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
		values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)
		set @messageOutTwitterId=SCOPE_IDENTITY()
	end
	else begin
		update messageOutTwitter set messageInTwitterIdEnd=@messageId,[date]=@date,ninteration=@ninteration
		where messageOutTwitterId=@messageOutTwitterId
	end
	select @userId = userId  from messageOutTwitter with(nolock) where messageOutTwitterId=@messageOutTwitterId
	select @userId as userId,@conversationId as conversationId, @messageId as messageId
end
else if @action = 4 begin --Obtiene el maximo messageOutTwitterId por conversacion
    select @messageOutTwitterId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId
	select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
	select @messageOutTwitterId as messageOutTwitterId,@replayId as replayId
end
else if @action = 5 begin --Ultimo mensaje en por ACD
    select isnull(max(twitId),0),max(date) from messageInTwitter as A
	inner join conversationTwitter as B on A.conversationTwitterId=B.conversationTwitterId
	where B.inboundId=@inboundId
end
else if @action = 6 begin --Obtiene conversación dependiendo del replayId
	if exists(select conversationTwitterId  from conversationTwitter where replayId=@replayId) begin
		select @conversationId=conversationTwitterId  from conversationTwitter where replayId=@replayId
		select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
	end
	else begin
		select 0 as conversationId,''0'' as replayId
	end
	select @conversationId as conversationId,@replayId as replayId
end

set nocount off'
	EXEC(@sql)

	set @process = 'CREATE PROCEDURE [dbo].[ccsp_NetworkSocialAdminAccount] --------------------------'
	set @sql='CREATE PROCEDURE [dbo].[ccsp_NetworkSocialAdminAccount]
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
				set @revisionTime=isnull(@revisionTime,''5'')
				set @daysTwitterRecord=isnull(@daysTwitterRecord,''0'')
			end
			else begin
			select @conexionInfo
				insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
				set @conexionInfo=null

				SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

				SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''5'')) FROM @tableConexionInfo where id=4
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

			SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''5'')) FROM @tableConexionInfo where id=4
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
	select isnull(max(conexionInfo),''usuarioID|token|tokenSecret|5|0'') from contactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
END'
		EXEC(@sql)


		set @process = 'Create SP --  ccsp_TwitterInitialStatistics'
		set @sql='CREATE PROCEDURE [dbo].[ccsp_TwitterInitialStatistics]
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
		where inboundId=@inboundId and [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121)
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
		and [date] between convert(varchar(10),getdate(),121) and convert(varchar(10),getdate()+1,121)
		GROUP BY InboundId
	END
END'
		EXEC(@sql)


		set @process = 'Create SP  -- ccsp_TwitterSave'
		set @sql='CREATE PROCEDURE [dbo].[ccsp_TwitterSave]
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
	update [messageoutTwitter] set @messageStatusId=1,twitId='''',tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0  where messageStatusId in(2,3)
END

END'
		EXEC(@sql)

		set @process = ''
		set @sql=''
		EXEC(@sql)


		set @process = 'Alter SP --ccsp_RIAConfEspec Twitter'
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
isnull(conexionInfoTwitter,''usuarioID|token|tokenSecret|5|0'') conexionInfoTwitter
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


		set @process = 'Alter SP -- ccsp_MailAdminAccount'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_MailAdminAccount]
@action int,
@meanContactTypeId smallint = 1,
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
/****
Conexion Info Email In
	protocol|server|ssl|port|cleanMail|revisionTime
Conexion Info Email Out
	serverOut|portOut|tls|sslOut
Conexion Info Twitter
	usuarioID|token|tokenSecret|time|daysTwitterRecord
***/


declare @isActiveMail bit
set @isActiveMail=0

if @action = 1 begin --checha si esta activo el servicio
	select @isActiveMail = valor from ccSettings where setting_id=152
	if @isActiveMail = 1 begin
		select @isActiveMail=(case when isActive = 1 and @isActiveMail = 1 then 1 else 0 end) from meanContactType where meanContactTypeId = 1
	end
	select @isActiveMail as isActiveMail
	return (0)
end
else if @action = 2 begin -- carga la relacion de especialidades y cuentas de email de entrada
	select A.inboundId,A.conexionInfo,A.connUser,A.connPass
		from ContactMeanIn A
			inner join ccInbound B on A.inboundId=B.Inbound_Id
		where meanContactTypeId = 1 and B.Status=1 and A.isActive=1
end
else if @action = 3 begin	--
	select name,conexionInfo,connUser,ConnPass,numMessages,timeAlertMessage,answerTimeOut from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 4 begin--insert or update relation mail whit ACD by in
	---Es necesario cambiar [ccsp_NetworkSocialAdminAccount] por que tambien se ocupa aqui
	DECLARE @tableConexionInfo TABLE(  id int, value varchar(255))
	if @connUser='''' 	set @connUser=''nuxiba@nuxiba.com''
	if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
		if not exists(select * from ContactMeanIn where connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin
		if @name is null set @name=''''
		if @conexionInfo is null and @meanContactTypeId=1  set @conexionInfo=''''
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
				set @revisionTime=isnull(@revisionTime,''5'')
				set @daysTwitterRecord=isnull(@daysTwitterRecord,''0'')
			end
			else begin
			select @conexionInfo
				insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
				set @conexionInfo=null

				SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

				SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''5'')) FROM @tableConexionInfo where id=4
				SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
			end
			set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
		end



		insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut,closeConversationTime)
				values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut,@closeConversationTime)
		select 1,''insert''
	end
		else select -1,''insert''
	end
	else begin
		if not exists(select * from ContactMeanIn where inboundId<>@inboundId and connUser=@connUser) or @connUser=''nuxiba@nuxiba.com'' begin

			select @name=isnull(@name,name), @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
				@numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
				@answerTimeOut= isnull(@answerTimeOut,answerTimeOut),@closeConversationTime=isnull(@closeConversationTime,closeConversationTime)
			from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId


			--Twitter deja los token
			if @meanContactTypeId= 2 begin
				--usuarioID|token|tokenSecret|time|daysTwitterRecord
				insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,''|'')
				set @conexionInfo=null

				SELECT @conexionInfo= COALESCE(@conexionInfo + ''|'', '''') + value FROM @tableConexionInfo where id<4

				SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),''5'')) FROM @tableConexionInfo where id=4
				SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),''0'')) FROM @tableConexionInfo where id=5
				set @conexionInfo=@conexionInfo+''|''+@revisionTime+''|''+@daysTwitterRecord
			end


			update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
				numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut,
				closeConversationTime=@closeConversationTime
				where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
			select 1,''update''
		end
		else select -1,''update''
	end
	return (0)
end

else if @action = 5 begin--parameters check conection Mail In
	select conexionInfo,connUser,connPass from ContactMeanIn with(nolock) where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
end
else if @action = 6 begin--parameters check conection Mail Out
	select conexionInfo,connUser,connPass
		from ContactMeanOut with(nolock) where contactMeanOutId  = @contactMeanId
end
else if @action = 7 begin--list mail out by ACD
	select A.contactMeanOutId,A.name, A.conexionInfo,A.connUser,A.connPass,A.isActive
		from ContactMeanOut A with(nolock)

end
else if @action = 8 begin--insert account mail out
	if not exists(select * from ContactMeanOut where connUser=@connUser) begin
		insert into ContactMeanOut (meanContactTypeId,name,conexionInfo,connUser,ConnPass,isActive)
			values (@meanContactTypeId,@name,@conexionInfo,@connUser,@connPass,@isActive)
		select 1
		return(0)
	end
	else select -1
end
else if @action = 9 begin--update account mail out
	if not exists(select * from ContactMeanOut where contactMeanOutId <> @contactMeanId  and connUser=@connUser) begin

		select  @meanContactTypeId=isnull(@meanContactTypeId,meanContactTypeId),@name=isnull(@name,name),
			@conexionInfo=isnull(@conexionInfo,conexionInfo),@connUser=isnull(@connUser,connUser),
			@connPass=isnull(@connPass,ConnPass),@isActive=isnull(@isActive,isActive)
			from ContactMeanOut where contactMeanOutId = @contactMeanId

		update ContactMeanOut set meanContactTypeId=@meanContactTypeId,name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,isActive=@isActive
		 where contactMeanOutId = @contactMeanId
		 select 1,''update ''
	end
	else select -1
end
else if @action = 10 begin	--insert relation mail out and ACD
	if not exists(select * from relationContactMeanOutInbound where contactMeanOutId=@contactMeanId) begin
		insert into relationContactMeanOutInbound(contactMeanOutId,inboundId) values (@contactMeanId,@inboundId)
	end
end
else if @action = 11 begin --delete relation mail out and ACD
	delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId and inboundId=@inboundId
end
else if @action = 12 begin --delete mail out
	delete relationContactMeanOutInbound where contactMeanOutId=@contactMeanId
	delete ContactMeanOut where contactMeanOutId=@contactMeanId
end
else if @action = 13 begin --delete mail out
	if not exists(select * from ContactMeanOut where contactMeanOutId=@contactMeanId) begin
		update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
		select 1
	end
	else select -1
end
else if @action = 14 begin
	select * from relationContactMeanOutInbound
end
else if @action = 15 begin
	select * from relationContactMeanOutInbound where inboundId=@inboundId
end
--else if @action = 16 begin
--	update ccRIACat_Areas set maxMails = @maxMails where IDArea=@idArea
--end
else if @action = 17 begin	--
	select A.conexionInfo,A.connUser,A.connPass from ContactMeanIn A where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
End
else if @action = 18 begin	--
	select A.contactMeanOutId,A.conexionInfo,A.connUser,A.connPass from contactMeanOut A where isActive=1

end
else if @action = 19 begin	--
	select contactMeanOutId,inboundId from relationContactMeanOutInbound where inboundId = @inboundId or @inboundId = 0 order by inboundId

end
else if @action = 20 begin --relation MailOut and ACD
	select B.inboundId,A.conexionInfo,A.connUser,A.connPass
	from ContactMeanOut A join relationContactMeanOutInbound B
	on B.contactMeanOutId=A.contactMeanOutId
	where B.inboundId = @inboundId or @inboundId = 0
end
else if @action = 21 begin --relation MailOut and ACD
	update ContactMeanOut set isActive=@isActive where contactMeanOutId = @contactMeanId
end
else if @action = 22 begin --Update type
	if @meanContactTypeId = 2 --Twitter
		set @conexionInfo=''|||5|0''
	else
		set @conexionInfo=''''
	update ContactMeanIn set name = '''', conexionInfo = @conexionInfo, connUser = '''', isActive = 0 where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
	select 1,''unAssigned''
end
END'
		EXEC(@sql)



		set @process = 'ALTER PROCEDURE [dbo].[ccsp_Multimedia]---------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_Multimedia]
@action int,@inboundId tinyint=0,@userId int =0,@meanContactTypeId tinyint = 1
AS
BEGIN

SET NOCOUNT ON;

if @action = 1 begin --Cuentas acd por tipo

	if @inboundId=0 begin
		select distinct A.inbound_id,A.chat as mode,cast(A.status as bit) [status],cast(isnull(b.isActive,0) as bit) isActive,cast(isnull(B.numMessages,3) as int) numMessages,
			case A.chat when 0 then ''call'' when 1 then ''chat'' when 2 then ''call and chat'' when 3 then ''mail'' when 4 then ''twitter'' else ''multimedia'' end  as typeMedia from ccInbound A
			left join ContactMeanIn B on B.inboundId =  A.inbound_id and A.chat = case when @meanContactTypeId =1 then 3 when  @meanContactTypeId =2 then 4 else -1 end
			where isnull(A.IDArea,0)> 0 and B.meanContactTypeId=@meanContactTypeId
	end
	else begin
		select A.inbound_id,A.chat as mode,cast(A.status as bit) [status],cast(isnull(b.isActive,0) as bit) isActive,cast(isnull(B.numMessages,3) as int) numMessages,
			case A.chat when 0 then ''call'' when 1 then ''chat'' when 2 then ''call and chat'' when 3 then ''mail'' when 4 then ''twitter'' else ''multimedia'' end  as typeMedia from ccInbound A
			left join ContactMeanIn B on B.inboundId =  A.inbound_id and A.chat = case when @meanContactTypeId =1 then 3 when  @meanContactTypeId =2 then 4 else -1 end
			where A.inbound_id = @inboundId and B.meanContactTypeId=@meanContactTypeId

	end
end
else if @action = 2 begin --Relacion entre agenetes y acd
	if @inboundId=0 and @userId = 0 begin --- Carga todas las relaciones
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
		order by  C.idCampEsp
	end
	else if @inboundId>0 and @userId = 0 begin
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and D.Inbound_id=@inboundId and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
		order by  C.idCampEsp
	end
	else if @inboundId=0 and @userId > 0 begin
		select A.User_id as [userId],C.idCampEsp inboundId,isnull(skill,1) skill,D.chat mode
		from ccRIAWorkGroupUsers A
		inner join ccusers B on A.User_id=B.User_id
		inner join ccRIACampEspWG C on C.IDWG = A.IDWG and C.Tipo=0
		inner join ccInbound D on C.idCampEsp = D.inbound_id
		left join ccskills S on S.inbound_id=D.inbound_id and S.user_id=B.user_id
		where B.TipoUser_id=1 and B.User_id=@userId and D.chat = case when @meanContactTypeId = 1 then 3 when @meanContactTypeId = 2 then 4 else -1 end
		order by  C.idCampEsp
	end
end
else if @action =3 begin -- Cargar relacion de agentes
	if	@userId is null or @userId=0 begin
		select user_id,Login,isnull(maxmails,3) maxMails from ccusers us (nolock)
			left join ccriacat_areas area (nolock) on area.idarea=us.idarea where TipoUser_id=1
	end
	else begin
	select user_id,Login,isnull(maxmails,3) maxMails from ccusers us (nolock)
			left join ccriacat_areas area (nolock) on area.idarea=us.idarea
			where TipoUser_id=1 and  us.User_id=@userId
	end
end
END'
		EXEC(@sql)

		set @process = 'ALter SP -- ccsp_MailSave'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_MailSave]
@action int,
@uid varchar(max)=null,
@date datetime=null,
@conversationId int=0,
@inboundId smallint=null,
@userId smallint=0,
@messageStatusId int=null,
@isInbox bit=1,
@messageId int =null,
@timeAtt int = 0,
@pathFile varchar(255)= null,
@mailClient varchar(60)= null,
@mailACD varchar(60)= null,
@isSender bit=0,
@isUser bit = 0,
@info varchar(255)=null,
@dispositionId smallint=0,
@subDispositionId smallint=0,
@tWrapUp int =0,
@tRetention int = 0,

---Finder
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0
AS
BEGIN


declare @isEndConversation bit
declare @meanContactTypeId smallint
declare @xmlnode xml
declare @existAttached bit, @numInteracion smallint

set @meanContactTypeId = 1
SET NOCOUNT ON;

if @action = 1 begin --find uid ConversationMail
  select count(*) from messageMail where [uid]=@uid
  return (0)
end
else if @action = 2 BEGIN --new Conversation
if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin
	insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)
	select @conversationId=SCOPE_IDENTITY()
	insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,0,@date,@messageStatusId)
	select @messageId=SCOPE_IDENTITY()
	insert into [messageMail](messageId,[uid]) values (@messageId,@uid)
	select @conversationId as conversationId,@messageId as messageId,0 as lastUserId
	return (0)
end
else begin
	select 0 as conversationId,0 as messageId,0 as lastUserId
	return (0)
end
END
else if @action = 3 BEGIN --new Messages
	if @date is null set @date=getdate()
	if @mailACD is null	select @mailACD=mailInbound from conversation where conversationId=@conversationId
	if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin
		update [conversation] set info=@info where conversationId=@conversationId
		insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,@userId,@date,@messageStatusId)
		select @messageId=SCOPE_IDENTITY()
	end
else begin
	select 0 as conversationId,0 as messageId,0 as lastUserId
	return (0)
end

	if @uid is null --for outbound messages
		select @uid = dbo.md5(cast(@conversationId as varchar(10)) + ''_'' + cast(@messageId as varchar(10)))

	insert into [messageMail](messageId,[uid]) values (@messageId,@uid)

	--Finder
	select @existAttached =case when count(*)>0 then 1 else 0 end  from attached where messageId in (select messageId from message where conversationId=@conversationId)
	select @numInteracion = count(*) from message where conversationId=@conversationId
    exec ccsp_CreateNodeMail @conversationId, @xml = @xmlnode OUTPUT

	if not exists(select * from ccEmailNode where emailId=@conversationId) begin
		insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
	end
	else begin
		update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
	end
	select @conversationId as conversationId,@messageId as messageId,0 as lastUserId

END
else if @action = 4 BEGIN --new attachment
	insert into [attached](messageId,pathFile,isUser) values(@messageId,@pathFile,@isUser)
	select SCOPE_IDENTITY() as attachedId
END
else if @action = 5 BEGIN --Correos por contestar Status DOWNLOAD,Assigned,READ,UnaSSIGNED
	select A.conversationId,B.userId,A.mailClient,A.mailInbound,A.info,B.messageStatusId,max(B.messageId) as messageId
	from conversation A inner join message B on A.conversationId = B.conversationId
	where A.inboundId = @inboundId and B.messageStatusId in(1,2,3,4) and meanContactTypeId = @meanContactTypeId
	GROUP BY A.conversationId,A.inboundId,A.info,A.mailClient,A.mailInbound,B.messageStatusId,B.userId
END
else if @action = 6 BEGIN --update Time Attention, Retencion
	select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
	update [message] set tResponse=@timeAtt,tRetention=@tRetention,isSender=@isSender,messageStatusId=@messageStatusId,userId=@userId where messageId=@messageId
END
else if @action = 7 BEGIN --Cambia el status del mensaje
	select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
	--Status Read
	if @messageStatusId=3  update [message] set tWait=DATEDIFF(ss,tQueue, getdate()) where messageId=@messageId

	--Status Answered or Send Generate Node BaseX
	if @messageStatusId in(5,6)  begin
		exec ccsp_CreateNodeMail @conversationId, @xml = @xmlnode OUTPUT
			if not exists(select * from ccEmailNode where emailId=@conversationId) begin
			insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
		end
		else begin
			update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
			end
	end
	--Status Send
	if @messageStatusId=6  begin
		select @isEndConversation=isFinished from conversation where conversationId=@conversationId
		if @isEndConversation = 1 set @messageStatusId=11--Close conversation by Agent
		update [message] set tSend=getdate() where messageId=@messageId
	end
	--Answered,Send,CLose Conversation system or agent
	if @messageStatusId in (5,6,10,11)  begin
	exec ccsp_CreateNodeMail @conversationId, @xml = @xmlnode OUTPUT
		if not exists(select * from ccEmailNode where emailId=@conversationId) begin
		insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
	end
	else begin
		update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
		end
	end
	update [message] set messageStatusId=@messageStatusId where messageId=@messageId
END
else if @action = 8 BEGIN --info del ultimo correo
	select messageId,GP.inboundId,C.connUser mailInbound,mailClient,mediaType,messageStatusId,info,I.descripcion,IG.graphic_id,I.tNotas,isnull(C.answerTimeOut,10) tTimeOut,C.timeAlertMessage tAlert
	from (
		select max(B.messageId) messageId,A.inboundId,A.mailClient, case A.meanContactTypeId when 1 then 3 else -1 end mediaType, B.messageStatusId, max(A.info) info
		from conversation A inner join message B  on A.conversationId = B.conversationId  where A.conversationId=@conversationId  GROUP BY A.inboundId,A.mailClient, A.meanContactTypeId, B.messageStatusId, B.userId) GP
	inner join contactMeanIn C on C.inboundId=GP.inboundId
	inner join ccInbound I on I.Inbound_id=GP.inboundId
	inner join ccRIAInboundGraph IG on IG.Inbound_id=GP.inboundId
END
else if @action = 9 BEGIN --carga adjuntos del ultimo mensaje
	if isnull(@conversationId,0) = 0
		select pathFile,isUser from attached where messageId=@messageId and isUser=@isUser
	else
	select pathFile,isUser from attached A
	inner join message B on A.messageId=B.messageId and B.conversationId=@conversationId
	where B.conversationId=@conversationId
END
else if @action = 10 BEGIN --Correos por enviar
	select A.conversationId,max(B.messageId) as messageId,B.userId,A.inboundId,A.mailInbound
	from conversation A
	inner join message B on A.conversationId = B.conversationId
	where B.messageStatusId in(5,7,8,9) and A.meanContactTypeId = 1 and isSender=1
	GROUP BY A.conversationId,A.inboundId,A.info,A.mailClient,A.mailInbound,B.messageStatusId,B.userId
END

else if @action = 11 BEGIN --Califica el mensaje y pone el tiempo Notas
	if @subDispositionId <> 0 begin
		select @isEndConversation=isnull(EndConversation,0) from ccTipoCalifSub where califSub_id=@subDispositionId
	end
	else begin
		select @isEndConversation=isnull(EndConversation,0) from cctipoCalif where calif_id=@dispositionId
	end
	if not exists(select * from relationMessageDisposition where messageId=@messageId) begin
		insert into relationMessageDisposition(messageId,dispositionId,subDispositionId) values(@messageId,@dispositionId,@subDispositionId)
	end
	else begin
		update relationMessageDisposition set dispositionId=@dispositionId,subDispositionId=@subDispositionId where messageId=@messageId
	end
		update message set tWrapUp=@tWrapUp where messageId=@messageId
		if @isEndConversation = 1 begin
		select @conversationId=conversationId from [message] where messageId=@messageId
		update conversation set isFinished=@isEndConversation where conversationId=@conversationId
	end
END
else if @action = 12 begin --Tiempo de cola
	select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
	update [message] set tQueue=getdate(),userId=@userId where messageId=@messageId
end
else if @action = 13 BEGIN  -- desasignar
	if @messageId = 0 begin
		insert into [messageUnAssigned](messageId,userId,[time],isLogout)
		select messageId,userId,datediff(ss,tQueue,getdate()) as [time],1 as isLogout from [message] where userId=@userId and messageStatusId in (2,3)
		update [message] set tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0 where userId=@userId and messageStatusId in (2,3)
	end
	else begin
		insert into [messageUnAssigned](messageId,userId,[time],isLogout)
		select messageId,userId,datediff(ss,tQueue,getdate()) as [time],0 as isLogout from [message] where userId=@userId and messageId=@messageId and messageStatusId in (2,3)
		update [message] set tQueue=null,userId=0,messageStatusId=4,tWait=0,tResponse=0,tRetention=0 where userId=@userId and messageId=@messageId and messageStatusId in (2,3)
	end
end
--else if @action = 14 begin
-- select 1
--end
else if @action = 15 begin
	SELECT @existAttached = case when count(*)>0 then 1 else 0 end
	from attached where messageId in (select messageId from message where conversationId=@conversationId)
	select messageid,A.inboundid,a.conversationid,mailClient,date,@existAttached isAttached,C.descripcion,
	B.tSend,D.Nombres+'' ''+D.ApellidoPaterno+'' ''+D.ApellidoMaterno,E.timeAlertMessage,E.answerTimeOut,C.tNotas,
	E.connUser as MailInbound, isnull(E.name, '''') as name
	from conversation A
	inner join message B  on A.conversationId = B.conversationId
	inner join ccinbound C on A.inboundid= C.inbound_id
	left join ccUsers D on B.userId = D.User_id
	inner join contactMeanIn E on E.inboundId=C.Inbound_id   and E.meanContactTypeId=@meanContactTypeId
	where A.conversationId=@conversationId

end
else if @action = 16 begin
	select A.inboundid,B.messageid,a.conversationid,c.pathFile
	from conversation A
	inner join message B  on A.conversationId = B.conversationId
	inner join attached C on B.messageid= C.messageid
	where A.conversationId=@conversationId
end
else if @action = 17 begin
	exec ccsp_CreateNodeMail @conversationId=@conversationId, @xml = @xmlnode OUTPUT,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate
	if not exists(select * from ccEmailNode where emailId=@conversationId) begin
		select @conversationId
		insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
	end
	else begin
	update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
	end
end
else if @action = 18 begin --cerrar conversacion por tiempo
	if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date)
	if @conversationId = 0
		select 0
	else begin
		declare @closeConversation tinyint
		declare @tRsponse datetime
		select @tRsponse = isnull(max(tSend), getdate()) from message where messageId = @conversationId
		select @closeConversation = closeConversationTime from contactMeanIn
		 if datediff(dd,getdate(),@tRsponse ) > @closeConversation
			select 0
		else
			select @conversationId
		end
	return 0
end
END'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_RIALoadAgents'
		set @sql='ALTER procedure [dbo].[ccsp_RIALoadAgents]
@option smallint,
@AreaId smallint,
@Sup smallint,
@UserType smallint,
@IDWG smallint = null,
@IDCampACD varchar(max) = null
AS
set nocount on
declare @IDArea int
if @option in(1,7) --1:Todos los agentes/supervisores | 7:UN solo agente/supervisor
 begin
	SELECT User_id, Login, TipoLlamadas, Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea,0) IDArea, Sexo
	From ccUsers with(readpast)
	Where TipoUser_id&2 = case @UserType when 1 then 0 else 2 end And Status > 0 and user_id = case @option when 7 then isnull(@sup,user_id) else user_id end
	ORDER by IDArea, Nombres, ApellidoPaterno, User_id
	return(0)
 end

if @option=2 --Agentes/supervisores de un Area
 begin
	SELECT User_id, Login, TipoLlamadas, Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea,0) IDArea, Sexo
	from ccusers
	Where isnull(IDArea,0) = isnull(@AreaId,0) And TipoUser_id&2 = case @UserType when 1 then 0 else 2 end
	 And status = 1 -- case isnull(@AreaId,0) when 0 then 0 else 1 end
	 ORDER by Sexo, Nombres, ApellidoPaterno, User_id
	return(0)
 end

if @option=3 --Agentes por Supervisor
 begin
	select a3.user_id, a3.Login, a3.TipoLlamadas, a3.Nombres + isnull('' ''+ a3.ApellidoPaterno,'''') + isnull('' '' + a3.ApellidoMaterno, '''') name,
	 isnull(a3.IDArea,0) IDArea, a3.Sexo
	from ccsupervisorcam a1 join cccampsagente a2 on a1.cam_id=a2.cam_id join ccusers a3 on a2.user_id=a3.user_id
	where a1.tipo=''1'' and a1.user_id=@Sup and a3.TipoUser_id = 1 and a3.status>0
	union
	select a3.user_id, a3.Login, a3.TipoLlamadas, a3.Nombres + isnull('' ''+ a3.ApellidoPaterno,'''') + isnull('' '' + a3.ApellidoMaterno, '''') name,
	 isnull(a3.IDArea,0) IDArea, a3.Sexo
	from ccsupervisorcam a1 join ccInboundagentes a2 on a1.cam_id=a2.Inbound_id join ccusers a3 on a2.user_id=a3.user_id
	where a1.tipo=''0'' and a1.user_id=@Sup and a3.TipoUser_id = 1 and a3.status>0
	Order by 5,4,1
	return(0)
 end

If @option=4 --Load All Supervisors
 begin
	SELECT User_id, Login, Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name
	from ccUsers where TipoUser_id in(2,6) and Status>0
	return(0)
 end

if @option=5 --Agentes por Supervisor de sus WG
 begin
	select @IDArea = IDArea from ccUsers where User_id=@Sup
	select User_id,Login,TipoLlamadas,max(name)name ,IDArea,Sexo,IP,sum(sumMultimedia) sumMultimedia from(
		select distinct A.User_id,A.Login,a.TipoLLamadas,A.Nombres + isnull('' ''+ A.ApellidoPaterno,'''') + isnull('' '' + A.ApellidoMaterno, '''') name
		,isnull(A.IDArea,0) IDArea, A.Sexo, isnull(C.IP,''0.0.0.0'') IP
		,(case isnull(E.chat,0) when 3 then POWER(2,0) when 4 then POWER(2,1) else 0 end) as sumMultimedia--, E.chat mode,E.Inbound_id
		from ccUsers A
		inner join ccRIAWorkGroupUsers B on A.User_id=B.User_id
		left join ccPosicion C on C.user_id=A.User_id
		inner join ccRIACampEspWG D on D.IDWG = B.IDWG
		left join  ccInbound E on D.IdCampEsp=E.Inbound_id and E.IDArea=@IDArea
		where A.TipoUser_id=1 and B.IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id=@Sup)
	)x
	group by user_id,Login,TipoLlamadas,IDArea,Sexo,IP
	return(0)
 end

if @option=6 --Agentes por Supervisor de sus WG
 begin
	select distinct a1.user_id, a1.Login, a1.TipoLlamadas, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	from ccusers a1 join ccRIAWorkGroupUsers a2 on a1.user_id=a2.user_id
	where tipouser_id in(2,6) and IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id=@Sup)
	return(0)
 end

If @option in(8,9) --8:Agentes de un WG | 9:Supervisores de un WG
 begin
	declare @wgUsers as varchar(500)
	select @wgUsers = coalesce(@wgUsers + '','', '''') + CAST(A.user_id as varchar(40))
	FROM ccRIAWorkGroupUsers A join ccUsers B on A.user_id = B.user_id where IDWG=@IDWG
	 -- and TipoUser_id&2 = case @option when 8 then 0 else 2 end -- Si se quiere tomar en cuenta tipo 2 y 6 como admin en vez de solo tipo 2
	 and TipoUser_id = case @option when 8 then 1 else 2 end
	select @wgUsers wgUsers
	return(0)
 end

if @option=10 --Todos los agentes/supervisores
 begin
	SELECT User_id, Login, Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name, isnull(IDArea,0) IDArea, Sexo
	From ccUsers with(readpast)
	Where TipoUser_id in(/*2,*/6) And Status > 0
	ORDER by login, IDArea, Nombres, ApellidoPaterno, User_id
	return(0)
 end

if @option=11 -- Agentes por ACD
 begin
	select distinct a1.user_id, a1.Login, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name, a1.Sexo, a2.prioridad
	from ccusers a1	join ccInboundAgentes a2 on a1.user_id=a2.user_id
	where a1.tipouser_id=1 and a2.Inbound_id in (select value from dbo.fn_RIASplitDelimited(@IDCampACD,'',''))
	return(0)
 end

if @option=12 -- Agentes por Camp
 begin
	select distinct a1.user_id, a1.Login, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name, a1.Sexo, a2.prioridad
	from ccusers a1	join ccCampsAgente a2 on a1.user_id=a2.user_id
	where a1.tipouser_id=1 and a2.cam_id in (select value from dbo.fn_RIASplitDelimited(@IDCampACD,'',''))
	return(0)
 end

if @option=13 -- Sups por ACD
 begin
	select distinct a1.user_id, a1.Login, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	from ccusers a1	join ccSupervisorCam a2 on a1.user_id = a2.user_id
	where a1.tipouser_id&2=2 and tipo = 0 and a2.cam_id in (select value from dbo.fn_RIASplitDelimited(@IDCampACD,'',''))
	return(0)
 end

if @option=14 -- Sups por Camp
 begin
	select distinct a1.user_id, a1.Login, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name
	from ccusers a1	join ccSupervisorCam a2 on a1.user_id = a2.user_id
	where a1.tipouser_id&2=2 and tipo = 1 and a2.cam_id in (select value from dbo.fn_RIASplitDelimited(@IDCampACD,'',''))
	return(0)
 end

declare @sxML as varchar(max), @xml as xml, @action as int

if @option=15 -- Info Agentes
 begin
	set @action=@option-9
	set @xml = cast(''<?xml version="1.0"?> <AgentData/>'' as xml)

	select @sxML = cast((select * from (select 1 as tag, null as parent,
	User_id "Agent!1!id", login "Agent!1!login", Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') "Agent!1!name",
	Sexo "Agent!1!gender", isnull(IDArea,0) "Agent!1!areaID"
	From ccUsers with(readpast) Where TipoUser_id=1 And Status>0 and user_id=@sup
	) as x order by tag, "Agent!1!areaID", "Agent!1!name", "Agent!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<AgentData/>'')

	set @xml.modify(''insert element Workgroups {""} as last into (/AgentData/Agent)[1]'')
	select @sxML = cast((select * from (select 1 as tag, null as parent,
	W.IDWG "Workgroup!1!id", W.WGName "Workgroup!1!description"
	from ccRIACat_WorkGroup W join ccRIAWorkGroupUsers U on W.IDWG = U.IDWG
	where user_id = @sup
	) as x order by tag, "Workgroup!1!description" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<Workgroups/>'')

	set @xml.modify(''insert element Campaigns {""} as last into (/AgentData/Agent)[1]'')
	select @sxML = cast((select * from (select distinct 1 as tag, null as parent,
	a1.cam_id "Campaign!1!id", a1.cam_descripcion "Campaign!1!description", a3.frame "Campaign!1!frame", a1.cam_procesando "Campaign!1!processing"
	from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccCampsAgente a4 on a1.cam_id = a4.cam_id
	where a3.type_id = 1 and a4.user_id = @Sup
	) as x order by tag, "Campaign!1!processing", "Campaign!1!description", "Campaign!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<Campaigns/>'')

	set @xml.modify(''insert element ACDs {""} as last into (/AgentData/Agent)[1]'')
	select @sxML = cast((select * from (select distinct 1 as tag, null as parent,
	a1.inbound_id "ACD!1!id", descripcion "ACD!1!description", frame "ACD!1!frame"
	from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccInboundAgentes a4 on a1.Inbound_id = a4.Inbound_id
	where a3.type_id = 1 and a4.user_id = @Sup
	) as x order by tag, "ACD!1!description", "ACD!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<ACDs/>'')

	set @xml.modify(''insert element action {""} as last into (/AgentData)[1]'')
	set @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/AgentData/action)[1]'')
	select @xML
	return(0)
 end

if @option=16 -- Info Sups
 begin

 	set @action=@option-9
	set @xml = cast(''<?xml version="1.0"?> <SuperData/>'' as xml)

	select @sxML = cast((select * from (select 1 as tag, null as parent,
	User_id "Super!1!id", login "Super!1!login", Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') "Super!1!name",
	Sexo "Super!1!gender", isnull(IDArea,0) "Super!1!areaID"
	From ccUsers with(readpast) Where TipoUser_id&2=2 And Status>0 and user_id=@sup
	) as x order by tag, "Super!1!areaID", "Super!1!name", "Super!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<SuperData/>'')

	set @xml.modify(''insert element Workgroups {""} as last into (/SuperData/Super)[1]'')
	select @sxML = cast((select * from (select 1 as tag, null as parent,
	W.IDWG "Workgroup!1!id", W.WGName "Workgroup!1!description"
	from ccRIACat_WorkGroup W join ccRIAWorkGroupUsers U on W.IDWG = U.IDWG
	where user_id = @sup
	) as x order by tag, "Workgroup!1!description" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<Workgroups/>'')

	set @xml.modify(''insert element Campaigns {""} as last into (/SuperData/Super)[1]'')
	select @sxML = cast((select * from (select distinct 1 as tag, null as parent,
	a1.cam_id "Campaign!1!id", a1.cam_descripcion "Campaign!1!description", a3.frame "Campaign!1!frame", a1.cam_procesando "Campaign!1!processing"
	from ccCamps a1 join ccRIACampsGraph a2 on a1.cam_id = a2.cam_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccSupervisorCam a4 on a1.cam_id = a4.cam_id
	where a3.type_id=1 and a4.user_id = @Sup and a4.tipo=1
	) as x order by tag, "Campaign!1!processing", "Campaign!1!description", "Campaign!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<Campaigns/>'')

	set @xml.modify(''insert element ACDs {""} as last into (/SuperData/Super)[1]'')
	select @sxML = cast((select * from (select distinct 1 as tag, null as parent,
	a1.inbound_id "ACD!1!id", descripcion "ACD!1!description", frame "ACD!1!frame"
	from ccinbound a1 join ccRIAinboundGraph a2 on a1.inbound_id = a2.inbound_id
	join ccRIAGraphics a3 on a2.graphic_id = a3.graphic_id
	join ccSupervisorCam a4 on a1.inbound_id = a4.cam_id
	where a3.type_id=1 and a4.user_id = @Sup and a4.tipo=0
	) as x order by tag, "ACD!1!description", "ACD!1!id" for xml explicit, type) as varchar(max))
	select @xml=dbo.xmlAppend(@xml, @sxML, ''<ACDs/>'')

	set @xml.modify(''insert element action {""} as last into (/SuperData)[1]'')
	set @xml.modify(''insert attribute value {sql:variable("@action")} as last into (/SuperData/action)[1]'')
	select @xML
	return(0)
 end

if @option=17 -- Load all agents
begin
	select distinct user_id, Login, TipoLlamadas,
		Nombres + isnull('' ''+ ApellidoPaterno,'''') + isnull('' '' + ApellidoMaterno, '''') name,
		isnull(IDArea,0) IDArea, Sexo, ''0.0.0.0'' IP, 0 as flagMine
	into #allAgents
	from ccusers
	where tipouser_id = 1

	select distinct a1.user_id, a1.Login, a1.TipoLlamadas, a1.Nombres + isnull('' ''+ a1.ApellidoPaterno,'''') + isnull('' '' + a1.ApellidoMaterno, '''') name,
	 isnull(a1.IDArea,0) IDArea, Sexo, isnull(IP, ''0.0.0.0'') IP
	into #myAgents
	from ccusers a1	join ccRIAWorkGroupUsers a2 on a1.user_id=a2.user_id left join ccPosicion a3 on a1.user_id=a3.user_id
	join ccRIACampEspWG a4 on a2.idwg = a4.idwg
	where a1.tipouser_id=1 and a2.IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id=@Sup)

	update #allAgents
	set flagMine = 1
	from #allAgents a, #myAgents b
	where a.user_id = b.user_id

	select *
	from #allAgents

	drop table #allAgents
	drop table #myAgents

	return(0)
end

if @option = 18 -- View Agents
begin
	select isnull(viewAgents,0) as viewAgents
	from ccusers
	where tipouser_id = 2
	and user_id = @Sup
	return(0)
end

set nocount off'
		EXEC(@sql)

		set @process = 'Alter SP -- ccsp_RIAtmpChart'
		set @sql='ALTER procedure [dbo].[ccsp_RIAtmpChart]
@inbound_id smallint = NULL,
@graphicType smallint = NULL
as
SET NOCOUNT ON

declare @DT as int
select @DT = valor from ccsettings where setting_id = 12

Declare @Times Table (
	StartDate datetime not null,
	EndDate datetime not null,
	[timestamp] varchar(5) not null)

Declare @Start DateTime
Declare @End Datetime
Declare @descripcion varchar(50)

declare @DTChat as int
select @DTChat = valor from ccsettings where setting_id = 141

if @graphicType = 1 --Call
begin
	declare @Fecha smalldatetime, @FechaW smalldatetime

	select @Fecha=convert(varchar(10), getdate(), 121)

	if exists(select cal_Inicio from cccallsin_tmpChart where cal_inicio < @Fecha)  truncate table cccallsin_tmpChart

	delete cccallsin_tmpChart where inbound_id = @inbound_id and cal_inicio >= @Fecha
	select @FechaW=@Fecha

	 while @FechaW <= convert(varchar(15), getdate(), 121)+''0:00'' begin
		if exists(Select SL.inbound_id from (select NS.inbound_id, @fechaW cal_inicio, sum(NS.LCt) LCt,  sum(NS.LAt) LAt,  sum(NS.LS) LS,  sum(NS.LA) LA,  sum(NS.LDt) LDt,
			sum(NS.LDc) LDc, sum(NS.LC) LC, sum(NS.LNC) LNC, sum(NS.LP) LP, @DT DyTrh
			from (Select @inbound_id inbound_id, @fechaW cal_inicio,
			ISNULL(count(CASE WHEN(statuscall_id in(13))and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LCt,
			ISNULL(count(CASE WHEN(statuscall_id=6)and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LAt,
			ISNULL(count(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0)AS LS,
			ISNULL(count(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0)AS LA,
			ISNULL(count(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0)AS LDt,
			ISNULL(count(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0)AS LDc,
			ISNULL(count(CASE WHEN(statuscall_id in(13))THEN 1 ELSE NULL END),0)AS LC,
			ISNULL(count(CASE WHEN(statuscall_id=15)THEN 1 ELSE NULL END),0)AS LNC,
			ISNULL(count(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0)AS LP
			from cccallsin where inbound_id=@inbound_id and cal_inicio between @Fecha and @FechaW and statuscall_id IN(4,6,7,8,11,13,15,16)
			group by convert(varchar(15), cal_inicio, 121)+''0:00'') as NS group by NS.inbound_id) as SL)
	   begin
		   insert into cccallsin_tmpChart (inbound_id, cal_Inicio, LCt, LAt, LS, LA, LDt, LDc, LC, LNC, LP, DT, NS)
			select SL.* ,case when (LC+LA+LS+LDt+LDc+LNC+LP) = 0 then ''1'' else cast((cast((LCt+LAt) as float)/cast((LC+LA+LS+LDt+LDc+LNC+LP)
				as float))*100 as decimal(18,2))end ServN
					from (select NS.inbound_id, @fechaW cal_inicio, sum(NS.LCt) LCt,  sum(NS.LAt) LAt,  sum(NS.LS) LS,  sum(NS.LA) LA,  sum(NS.LDt) LDt,
				sum(NS.LDc) LDc, sum(NS.LC) LC, sum(NS.LNC) LNC, sum(NS.LP) LP, @DT DyTrh
					from (Select @inbound_id inbound_id, @fechaW cal_inicio,
						ISNULL(count(CASE WHEN(statuscall_id in(13))and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LCt,
						ISNULL(count(CASE WHEN(statuscall_id=6)and(cal_tWait+cal_tXfer+cal_tRing)<@DT THEN 1 ELSE NULL END),0)AS LAt,
						ISNULL(count(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),0)AS LS,
						ISNULL(count(CASE WHEN(statuscall_id=6)THEN 1 ELSE NULL END),0)AS LA,
						ISNULL(count(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),0)AS LDt,
						ISNULL(count(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),0)AS LDc,
						ISNULL(count(CASE WHEN(statuscall_id in(13))THEN 1 ELSE NULL END),0)AS LC,
						ISNULL(count(CASE WHEN(statuscall_id=15)THEN 1 ELSE NULL END),0)AS LNC,
						ISNULL(count(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),0)AS LP
					from cccallsin where inbound_id=@inbound_id and cal_inicio between @Fecha and @FechaW and statuscall_id IN(4,6,7,8,11,13,15,16)
				group by convert(varchar(15), cal_inicio, 121)+''0:00'') as NS group by NS.inbound_id) as SL
	   end

		else begin
			insert into cccallsin_tmpChart (inbound_id, cal_Inicio, LCt, LAt, LS, LA, LDt, LDc, LC, LNC, LP, DT, NS)
			Select @inbound_id, @FechaW, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		end

	  select @FechaW=dateadd(minute, 10, @FechaW)
	 end

	if not exists(select d.descripcion from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart)) join (select c.inbound_id, i.descripcion, c.NS, convert(varchar(5), max(c.cal_inicio), 108) timestamp
		from cccallsin_tmpChart c join ccinbound i on c.inbound_id = i.inbound_id
		where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id
		group by c.inbound_id, i.descripcion, c.NS) D on c.inbound_id = d.inbound_id
		where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id)
	begin
		raiserror(''without ACD Group information  '', 18, 1)
		return(0)
	end

 select * from
	(select top 20 @inbound_id inbound_id, d.descripcion, d.NS LastNS, convert(varchar(5), c.cal_inicio, 108) timestamp, c.NS
		from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart))
	inner join
	(select top 1 c.inbound_id, i.descripcion, c.NS, convert(varchar(5), max(c.cal_inicio), 108) timestamp
		from cccallsin_tmpChart c with(index(IX_cccallsin_tmpChart)) join ccinbound i on c.inbound_id = i.inbound_id
		where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id
  --and c.cal_inicio < convert(varchar(15), getdate(), 121)+''0:00''
		group by c.inbound_id, i.descripcion, c.NS order by timestamp desc) D on c.inbound_id = d.inbound_id
	where c.cal_inicio > dateadd(minute, -210, convert(varchar(15), getdate(), 121)+''0:00'') and c.inbound_id = @inbound_id
  --and c.cal_inicio < convert(varchar(15), getdate(), 121)+''0:00''
 order by 4 desc) as chart order by 4
 return(0)
end

if @graphicType in(2,3,4) begin--Init tabla timer

	set @End = getdate()
	set @Start = convert(varchar(15),dateadd(minute, -200, @end),121) + ''0:00''

	while @Start < @End begin
		insert @Times(StartDate, EndDate, [timestamp]) values(@Start, DateAdd(minute, 10, @Start), convert(varchar(5), convert(datetime,@Start), 108))
		set @Start = DateAdd(minute, 10, @Start)
	end

	select @descripcion = descripcion  from ccinbound where inbound_id = @inbound_id

	create table #MultimediaSummary(
		inboundId smallint not null,
		descripcion varchar(50) not null,
		LastNS decimal(10,2) not null,
		[timestamp] varchar(5) not null,
		NS decimal(10,2) not null
	)

	create table #MultimediaChart(
		inboundId smallint not null,
		descripcion varchar(50) not null,
		LastNS decimal(10,2) not null,
		[timestamp] varchar(5) not null,
		NS decimal(10,2) not null
	)


end

if @graphicType = 2 begin --CHAT
	insert into #MultimediaSummary
	 select inboundId, descripcion, 0.00 as LastNS,
	 convert(varchar(5), convert(datetime,Date), 108) [timestamp],
	 convert(decimal(10,2),convert(float,[Connected]) / convert(float, Total) * 100.00) as NS
	 from
		 (select inboundId, descripcion, Date,
		 sum([Connected>DT]) as [Connected],
		 sum([Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as NotConnected,
		 sum([Connected>DT] + [Connected<DT] + [Assigned] + [NoSignedAgents] + [Abandon] + [QueueOverflow] + [TimeOverflow]) as Total
		 from (
			 select inboundId, descripcion, convert(varchar(15), chatDate, 121)+''0:00'' as Date,
			 ISNULL(count(CASE WHEN chatstatus = 4 and tChatting >= @DTChat THEN 1 ELSE NULL END),0)AS [Connected>DT],
			 ISNULL(count(CASE WHEN chatstatus = 4 and tChatting < @DTChat THEN 1 ELSE NULL END),0)AS [Connected<DT],
			 ISNULL(count(CASE WHEN(chatstatus = 3)THEN 1 ELSE NULL END),0)AS [Assigned],
			 ISNULL(count(CASE WHEN(chatstatus = 7)THEN 1 ELSE NULL END),0)AS [NoSignedAgents],
			 ISNULL(count(CASE WHEN(chatstatus = 9)THEN 1 ELSE NULL END),0)AS [Abandon],
			 ISNULL(count(CASE WHEN(chatstatus = 10)THEN 1 ELSE NULL END),0)AS [QueueOverflow],
			 ISNULL(count(CASE WHEN(chatstatus = 11)THEN 1 ELSE NULL END),0)AS [TimeOverflow]
			 from ccRIAChats a
			 right outer join @times b on (chatDate >= StartDate and chatDate < EndDate)
			 left outer join ccInbound c on (inboundId = inbound_id)
			 where inboundId = @inbound_id and chatStatus in (3,4,7,9,10,11) and chatDate is not null
			 group by inboundId, descripcion, convert(varchar(15), chatDate, 121)+''0:00'') as ChatDetail
	group by inboundId, descripcion, Date) as ChatSummary

end

else if @graphicType = 4 begin--Email
	insert into #MultimediaSummary
	select	x.inboundId,x.descripcion, 0.00 as LastNS,
	convert(varchar(5), convert(datetime,Date), 108) [timestamp],
	convert(decimal(10,2),convert(float,sent+forwarding+closed) / convert(float, received) * 100.00) as NS
	from
		(select
		inboundId,c.descripcion, convert(varchar(15), msg.date, 121)+''0:00'' as Date,
		count(*) received,
		count(case when messageStatusId in (5,6) then 1 else null end) sent,
		count(case when messageStatusId = 9 then 1 else null end) forwarding,
		count(case when messageStatusId in (10,11) then 1 else null end) closed
		from messageOutTwitter msg (nolock) join conversationTwitter con (nolock) on con.conversationTwitterId=msg.conversationTwitterId
		right outer join @times b on msg.date >= StartDate and msg.date < EndDate
		left outer join ccInbound c on con.inboundId = c.inbound_id
		where inboundId = @inbound_id
		group by inboundId,c.descripcion, convert(varchar(15), date, 121)+''0:00''
		)x

end
else if @graphicType = 3 begin--Email
	insert into #MultimediaSummary
	select	x.inboundId,x.descripcion, 0.00 as LastNS,
	convert(varchar(5), convert(datetime,Date), 108) [timestamp],
	convert(decimal(10,2),convert(float,sent+forwarding+closed) / convert(float, received) * 100.00) as NS
	from
		(select
		inboundId,c.descripcion, convert(varchar(15), msg.date, 121)+''0:00'' as Date,
		count(*) received,
		count(case when messageStatusId in (5,6,1) then 1 else null end) sent,
		count(case when messageStatusId = 9 then 1 else null end) forwarding,
		count(case when messageStatusId in (10,11) then 1 else null end) closed
		from message msg (nolock) join conversation con (nolock) on con.conversationId=msg.conversationId
		right outer join @times b on msg.date >= StartDate and msg.date < EndDate
		left outer join ccInbound c on con.inboundId = c.inbound_id
		where inboundId = @inbound_id
		group by inboundId,c.descripcion, convert(varchar(15), date, 121)+''0:00''
		)x
end

if @graphicType in(2,3,4) begin--Se coloca al final la parte que son iguales todos los servicios multimedia

	insert into #MultimediaChart
	 select case when (inboundId is null) then @inbound_id else inboundID end as inboundId,
		case when (descripcion is null) then @descripcion else descripcion end as descripcion,
		case when (LastNS is null) then 0.00 else LastNS end as LastNS,
		case when (a.[timestamp] is null) then b.[timestamp] else a.[timestamp] end as [timestamp],
		case when (NS is null) then 0.00 else NS end as NS
		from #MultimediaSummary a
	 full outer join @times b on (a.[timestamp] = b.[timestamp])
	 order by b.[timestamp]

	 select a.inboundId, a.descripcion, b.NS as LastNS, a.[timestamp], a.NS
	 from #MultimediaChart a, #MultimediaChart b
	 where convert(varchar(5),dateadd(minute, -10, convert(datetime,a.[timestamp])), 108) = b.[timestamp]
	 order by a.[timestamp]


	drop table #MultimediaSummary
	drop table #MultimediaChart
end'
		EXEC(@sql)


		set @process = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr] --------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option int = 0,
@idF int = 0,
@idL int = 0,
@idService int = 0,
@name varchar(25) = NULL,
@top varchar(max) = NULL
AS
declare @sql nvarchar(max)
declare @chat int ,@rec int,@email int
set @sql = ''''

if @action = 1 begin --obtiene los nodos a insertar en BX
	if @option = 1 begin
		set @sql = ''select top '' + @top + '' chatId, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ccChatsNode with(rowlock) where status = 0''
		exec(@sql)
	end
	else if @option = 3 begin
		set @sql = ''select top '' + @top + '' emailId, replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ccEmailNode with(rowlock) where status = 0''
		exec(@sql)
	end
end
else if @action = 2 begin--actualiza los nodos insertados en BX
	if @option = 1
		update ccChatsNode with(rowlock) set [status] = 1, dateOut = getDate() where chatId between @idF and @idL and [status] = 0
	if @option = 3
		update ccEmailNode with(rowlock) set [status] = 1, dateOut = getDate() where emailId between @idF and @idL and [status] = 0

end
else if @action = 3 --trae el nombre de la base de datos en BX
begin
	select Xname from ccBaseXDB where serviceId = @option and isFull = 0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
	insert into ccBaseXDB (serviceId, dateStart, Xname) values (@option, getDate(), @name)
end
else if @action = 5 begin --obtener servicios disponibles
	select @chat= 0,@rec= 2,@email= 0
	select @chat = case when valor > 1 then 1 else 0 end from ccSettings where setting_id = 145
	select @email = case when valor = 1 then 3 else 0 end from ccSettings where setting_id = 155
	select id, ref 	from ccFinderServices where id in (@chat, @rec, @email)

end
else if @action = 6 begin --obtener valores con status 2
	if @option= 1 begin
		set @sql = ''select top '' + @top + '' chatId,replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ccChatsNode with(rowlock) where status = 2''
		exec(@sql)
	end
	else if @option= 3 begin
		set @sql = ''select top '' + @top + '' emailId,replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') from ccEmailNode with(rowlock) where status = 2''
		exec(@sql)
	end
end
else if @action = 7 begin--actualiza los nodos insertados en BX
	if @option = 1
		update ccChatsNode with(rowlock) set [status] = 3, dateOut = getDate() where chatId between @idF and @idL and [status] = 2
	else if @option = 3
		update ccEmailNode with(rowlock) set [status] = 3, dateOut = getDate() where emailId between @idF and @idL and [status] = 2

end

--nota: las acciones 3 y 4 hacerlas para casos dinamicos, (i.e.) si se va controlor por tamaño y asignar un xml nuevo, conusltar Daniel de CW :)'
		EXEC(@sql)


		set @process = 'ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB] --------'
		set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB] @cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0 as
set nocount on

declare @regval as int

-- Actualiza todas las camps
if @Tipo=2 or @Tipo = 1
	begin
		declare @ultimo as datetime,@id AS INTEGER

		select @ultimo = isnull( convert(datetime, valor, 121), dateadd(hh, -1, getdate() ) ) from ccSettings with(nolock) where setting_id = 21

		CREATE TABLE #Tcamps
				(cam_id int primary key,
				procesando int,
				cam_tipojobs int,
				cam_descripcion varchar(40),
				cantidad int,
				status int)

				create table #temccocallsoutsource
				(cam_id int,
				 Pend  int)

				create table #temWorkinTable
				(cam_id int,
				 New int,
				 Cb int,
				 Pro int,
				 Fin int)

		--if datediff(ss, @ultimo, getdate()) > 120
		if datediff(ss, @ultimo, getdate()) > 0
			begin

				if @cam_id = 0 begin
				insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
					select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
					from ccCamps cam left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
					where user_id = @user_id
					and tipo = 1
				end
				else begin
					if @Tipo = 2
						insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
							select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
							from ccCamps cam left join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
							where cam.cam_id = @cam_id
							and user_id = @user_id
							and tipo = 1
					else
						insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
							select cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
							from ccCamps
				end

				insert into #temccocallsoutsource(cam_id,Pend)
					SELECT ccos.cam_id, count(ccos.cam_id) as Pend
							FROM ccocallsoutsource ccos with(nolock index(IX_ccoCallsOutSource))
							left join #Tcamps tcam on ccos.cam_id = tcam.cam_id
							WHERE cal_status in(0, 7)
							GROUP BY ccos.cam_id

				insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
					SELECT cam_id,
						count(case cal_status when 0 then 1 else null end) as New,
						count(case cal_status when 1 then 1 else null end) as Cb,
						count(case cal_status when 2 then 1 else null end) as Pro,
						count(case cal_status when 3 then 1 else null end) as Fin
						FROM ccoworkingtable with(index(IX_ccoWorkingTable),nolock)
						GROUP BY cam_id

						While (select count(*) from #Tcamps where status = 0) > 0
						Begin
								set rowcount 1
									select @id = cam_id from #Tcamps where status = 0 order by cam_id
								set rowcount 0
								EXEC @regval = ccsp_OUTGetNewJobs @id,2,0

									update #Tcamps
									set cantidad = @regval , status =1
									where cam_id = @id
						end

				UPDATE ccSettings set valor = convert( varchar(23), getdate(),121) where setting_id = 21

				delete ccCampsNvosCB
				from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps tcamp
				where CampNvosCB.id = tcamp.cam_id

				INSERT into ccCampsNvosCB (id, campaña, new, cb, pen, pro, st, Job, Fin, NextDial)
				SELECT cams.cam_id, cams.cam_descripcion,
				isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
				isNull(cs.Pend,0) as pend,
				isNull(wt.Pro,0) as pro,
				isNull(cams.procesando,0) cam_procesando,
				isNull(cams.cam_tipojobs,0) cam_tipojobs,
				isNull(wt.Fin,0) Fin,
				isNull(tc.cantidad,0) cantidad
				FROM #Tcamps cams with(nolock)
					LEFT JOIN
						#temWorkinTable	 wt on cams.cam_id = wt.cam_id
					LEFT JOIN #temccocallsoutsource	cs on cams.cam_id = cs.cam_id
				left join #Tcamps tc on (tc.cam_id = cams.cam_id)

			end

		if @Tipo = 2
			-- devuelve resultado de la taba, solo las camps del usuario
			SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, res.st, res.job, res.Fin, isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial
			FROM #Tcamps tcam
			left join  ccCampsNvosCB res  on tcam.cam_id  = res.id
			LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
		else
			SELECT id, campaña, new, cb, pro, pen,st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial
			FROM ccCampsNvosCB res
			LEFT JOIN ccCampsPrioridadTel prio on res.id = prio.cam_id
			WHERE res.id = @cam_id

		drop table #Tcamps
		drop table #temccocallsoutsource
		drop table #temWorkinTable

		return(0)
	end

set nocount off'
		EXEC(@sql)

		set @process = 'ALTER PROCEDURE -- ccsp_GetAllAgentsECRelations] '
		set @sql='ALTER PROCEDURE [dbo].[ccsp_GetAllAgentsECRelations]
@User_id varchar(300)
AS
set nocount on

DECLARE @userTable TABLE (Id int,userId int)
DECLARE @userIn TABLE (userId int)

insert into @userTable select * from dbo.fn_RIASplitDelimited(@User_id,''|'')

insert into @userIn
select distinct A.user_id
	from ccInboundAgentes G join ccInbound E on G.inbound_id = E.inbound_id
	inner join ccUsers A  on A.user_id = G.user_id and A.TipoUser_id =1
	inner join @userTable B on A.User_id = B.userId
	Where A.status > 0


select
	case when CA.user_id is null and uIn.userId is null then 0
	when CA.user_id is null and uIn.userId is not null then 1
	when CA.user_id is not null and uIn.userId is null then 2
	else 3 end tipo,
	isnull(C.cam_id,0) as cam_id, B.user_id, isnull(prioridad,0) prioridad, isnull(skill,0) skill, isnull(C.cli_id,0) cli_id
	from @userTable A
	inner join ccUsers B  on A.userId = B.user_id and B.TipoUser_id =1
	left join ccCampsAgente CA on A.userId = CA.user_id
	left join ccCamps C  on C.cam_id = CA.cam_id
	left join @userIn uIn on uIn.userId = B.user_id
	Where B.status > 0
	order by tipo'
		EXEC(@sql)


		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		exec ccsp_getVersion 'BDF', @versionFix

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