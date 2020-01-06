/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author: 

		
Date: 2019/12/02
Description: 

Database: CCenterRia
Required version: 122.11

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
SET @version = 122 --**********actualizar a 122 sin fix
SET @versionfix = 12
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF (@actualVersion = @version AND @actualVersionFix >= 11) OR (@actualVersion = @version-1 AND @actualVersionFix >= 41)
BEGIN
	BEGIN TRAN

	BEGIN TRY
	

		set @process = 'CW-3517 - Insert discarded message status in table messageStatus'
		set @sql='if not exists(select * from messageStatus where messageStatusId = 14) begin
		SET IDENTITY_INSERT messageStatus ON
			insert into messageStatus ([messageStatusId], [name], [description], [isFinished]) values (14, ''Discarded'', ''Message discarded by agent'', 0)
		SET IDENTITY_INSERT messageStatus OFF
		end'
		EXEC(@sql)


		set @process = 'CW-3517 Alter procedure ccsp_TwitterSave'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_TwitterSave]
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
 @tRetention int = 0,

 ---Finder
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0
AS
BEGIN

declare @meanContactTypeId smallint
declare @isEndConversation bit
declare @xmlnode xml

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
	select A.conversationTwitterId,B.userId,A.screenNameClient,A.screenNameInbound,B.messageStatusId,B.messageOutTwitterId as messageId
		from conversationTwitter A
		inner join [messageoutTwitter] B on A.conversationTwitterId = B.conversationTwitterId
		where A.inboundId = @inboundId and B.messageStatusId in(1,2,3,4) and meanContactTypeId = @meanContactTypeId
		and b.messageOutTwitterId=(select max(bb.messageOutTwitterId)--esta subconsulta permite conocer el maximo messageOutTwitterId de la conversacion de la consulta principal 
				from messageOutTwitter bb
				inner join conversationTwitter aa on aa.conversationTwitterId = bb.conversationTwitterId
				where bb.conversationTwitterId=aa.conversationTwitterId
				and bb.conversationTwitterId=b.conversationTwitterid 
				and aa.inboundId=@inboundId
				GROUP BY bb.conversationTwitterId)
		GROUP BY A.conversationTwitterId,A.inboundId,A.screenNameClient,A.screenNameInbound,B.messageStatusId,B.userId,b.messageOutTwitterId
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

	--Answered,Send,CLose Conversation system or agent
	if @messageStatusId in (5,6,10,11)  begin
		exec ccsp_CreateNodeMultimedia @type=2, @conversationId=@conversationId, @xml = @xmlnode OUTPUT
		if not exists(select * from [ccTwitterNode] where [conversationTwitterId]=@conversationId) begin
			insert into [ccTwitterNode]([conversationTwitterId],[node],dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
		end
		else begin
			update [ccTwitterNode] set node=@xmlnode,status=2 where [conversationTwitterId]=@conversationId
		end
	end

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
else if @action = 14 begin --Asignar una evaluacion
	exec ccsp_CreateNodeMultimedia @type=2, @conversationId=@conversationId, @xml = @xmlnode OUTPUT,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate
	if not exists(select * from ccEmailNode where emailId=@conversationId) begin
		insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
	end
	else begin
		update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
	end
END
else if @action = 15 BEGIN  --Descartar Tweet
	select @messageId=max(messageOutTwitterId) from messageOutTwitter with(nolock) where conversationTwitterId=@conversationId
	
	update messageOutTwitter set messageStatusId=14,userId=@userId,tResponse=@timeAtt,tRetention=@tRetention,isSender=0 where messageOutTwitterId=@messageId   
	update conversationTwitter set isFinished=1 where meanContactTypeId = @meanContactTypeId and conversationTwitterId=@conversationId

	exec ccsp_CreateNodeMultimedia @type=2, @conversationId=@conversationId, @xml = @xmlnode OUTPUT
	if not exists(select * from [ccTwitterNode] where [conversationTwitterId]=@conversationId) begin
		insert into [ccTwitterNode]([conversationTwitterId],[node],dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
	end
	else begin
		update [ccTwitterNode] set node=@xmlnode,status=2 where [conversationTwitterId]=@conversationId
	end

END

END'
		exec (@sql)

		set @process = 'CW- -- Add Permission CenterScript'
		set @sql='if not exists(select * from ccRIACat_AdminPermissions where per_id=12) begin
	insert into ccRIACat_AdminPermissions(per_desc,bStatus,release) values(''CenterScript|CenterScript'',1,''a7b041ea0b143f558de011020bdbb46745b87c972c042d729d4aca41457a31c4'')
end'
		EXEC(@sql)


			set @process = 'CW-3731 Error en Callbacks de llamadas de entrada'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccspGalateaINInsertaCallBack'')
    begin
        DROP PROCEDURE ccspGalateaINInsertaCallBack;
    end'
    exec (@sql)

				set @process = 'CW-3731 Error en Callbacks de llamadas de entrada'
	set @sql = 'CREATE PROCEDURE ccspGalateaINInsertaCallBack
@cal_key varchar(20) ='''',
@acd_id smallint,
@cal_telefono varchar(19),
@fechadial varchar(17),
@dato1 varchar(255),
@dato2 varchar(255),
@dato3 varchar(255),
@dato4 varchar(255),
@dato5 varchar(255),
@TelReprograma smallint = -1,
@user_id int=0,
@isAuto bit=0
AS
BEGIN
set nocount on
	DECLARE @cam_id SMALLINT
	SELECT @cam_id = isnull(cam_id, 0) FROM  ccinbound WHERE Inbound_id = @acd_id
	exec ccsp_INInsertaCallBack @cal_key, @cam_id, @cal_telefono, @fechadial, @dato1, @dato2, @dato3, @dato4, @dato5, @TelReprograma , @user_id, @isAuto
set nocount off
END
'
    exec (@sql)


    set @process = 'CW-3701 Se borra store en caso de existir'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaDeleteRegistryList'')
    begin
        DROP PROCEDURE ccsp_GalateaDeleteRegistryList;
    end'
    exec (@sql)

    set @process = 'CW-3701 Se agrega store para borrado de pendientes y nuevos'
	set @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaDeleteRegistryList]
		@loadID INT
		AS

		IF (@loadID IS NOT NULL AND EXISTS(SELECT * FROM ccRIARegistryLists WHERE list_id = @loadID and status <> 0))
		BEGIN
			UPDATE ccoCallsOutSource SET cal_status = ''5'' WHERE list_id = @loadID
			DELETE FROM ccoWorkingTable WHERE list_id = @loadID 
			exec ccsp_RIARegistryLists @action=6, @list_id = @loadID 
		END
		ELSE
		BEGIN
			--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
			raiserror(''ERROR. No existe una carga el id especificado'', 18, 1)
		END			
	'
    exec (@sql)

    set @process = 'CW-3701 Se borra store en caso de existir'
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaGetRegistryListID'')
    begin
        DROP PROCEDURE ccsp_GalateaGetRegistryListID;
    end'
    exec (@sql)

    set @process = 'CW-3701 Se agrega store para obtención de id de carga de registros'
	set @sql = '
		CREATE PROCEDURE [dbo].[ccsp_GalateaGetRegistryListID]
		@camID INT
		AS

		IF (@camID IS NOT NULL AND EXISTS(SELECT * FROM cccamps WHERE cam_id = @camID))
		BEGIN
			SELECT TOP 1 list_id FROM ccRIARegistryLists WHERE cam_id = @camID AND status = 2 ORDER BY list_id DESC
		END
		ELSE
		BEGIN
			--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
			raiserror(''ERROR. No existe una campaña con el id especificado'', 18, 1)
		END	
	'
    exec (@sql)

	set @process = 'CW-3489 Creacion de la tabla ccoCallPriorityOrder '
		set @sql = 'IF NOT EXISTS
(
    SELECT *
    FROM sys.tables
    WHERE name = N''ccoCallPriorityOrder''
)
    BEGIN
        CREATE TABLE [dbo].[ccoCallPriorityOrder]
        ([callout_id]   [INT] NOT NULL, 
         [priorityCall] [CHAR](8) NULL, 
         CONSTRAINT [PK_ccoCallPriorityOrder] PRIMARY KEY([callout_id] ASC)
        )
        ON [PRIMARY]
END'

		exec (@sql)

		set @process = 'CW-3489 Alter del sp ccsp_OUTUpdateDialJob para cambiar la tabla de ccoCallsoutsource por ccoCallPriorityOrder'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
@callout_id     INT, 
@CallResultDial TINYINT, 
@isTCPA         BIT     = 0
AS
     SET NOCOUNT ON

/*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine	*/

     DECLARE @nOcupado TINYINT, @nNoContesta TINYINT, @nFax TINYINT, @nContestadora TINYINT
     DECLARE @nShortCall TINYINT, @nOtro TINYINT, @cam_NoInt_ocupado TINYINT, @cam_NoInt_graba TINYINT
     DECLARE @cam_ocupado SMALLINT, @cam_inter_ocupado SMALLINT, @cam_nocontesto SMALLINT
     DECLARE @cam_graba SMALLINT, @cam_inter_graba SMALLINT, @cam_inter_nocontesto SMALLINT
     DECLARE @cam_fax SMALLINT, @cam_inter_fax SMALLINT
     DECLARE @DateNextDial SMALLDATETIME, @DateNewDial SMALLDATETIME, @cam_id SMALLINT
     DECLARE @ExisteWT TINYINT, @cam_NoInt_fax TINYINT, @cam_NoInt_nocontesto TINYINT, @cal_status TINYINT
     DECLARE @sSQL NVARCHAR(MAX), @Telefono VARCHAR(15), @prioridadLlamada CHAR(8)
     SELECT @cam_id = cam_id, 
            @nOcupado = ISNULL(nOcupado, 0), 
            @nNoContesta = ISNULL(nNoContesta, 0), 
            @nFax = ISNULL(nFax, 0),  
            @nContestadora = ISNULL(nContestadora, 0), 
            @nShortCall = ISNULL(nShortCall, 0), 
            @nOtro = ISNULL(nOtro, 0), 
            @DateNextDial = cal_fechaDial
     FROM ccoWorkingTable
     WHERE callout_id = @callout_id
     SELECT @ExisteWT = CASE
                            WHEN @cam_id IS NOT NULL
                            THEN 1
                            ELSE 0
                        END
     SELECT @cal_status = CASE
                              WHEN @isTCPA = 1
                              THEN 0
                              ELSE 1
                          END--si esta en modo TCPA no gene|rar callbacks

     IF @CallResultDial = 20 -- CONTACTADO
         BEGIN
             EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta, 
                  @nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
             RETURN(0)
     END
     IF @CallResultDial = 1
         BEGIN-- CONTESTO 
             IF @isTCPA = 1
                 BEGIN
                     UPDATE ccoWorkingTable SET cal_status = @cal_status
                     WHERE callout_id = @callout_id
             END
             ELSE
                 BEGIN
                     IF (SELECT abandonCallback FROM ccCamps WHERE cam_id = @cam_id) = 1
                         BEGIN
                             EXEC ccsp_OUTCancelDialJOB @callout_id,1,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
                     END
                     ELSE
                         BEGIN
                             EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
                     END
             END
             RETURN(0)
     END
     ELSE
         IF @CallResultDial IN(2, 12)
             BEGIN -- OCUPADO 
                 SELECT @cam_ocupado = cam_ocupado,
						@cam_inter_ocupado = cam_inter_ocupado,
						@cam_NoInt_ocupado = cam_NoInt_ocupado,
						@nOcupado = @nOcupado + 1
                 FROM ccCamps
                 WHERE cam_id = @cam_id

                 IF @cam_ocupado = 1
                 -- Opcion Ocupado HABILITADA	 
                     BEGIN
                         IF @nOcupado > @cam_NoInt_ocupado OR @nShortCall > 4
                             BEGIN
                                 EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
                                 RETURN(0)
                         END
                         IF NOT EXISTS (SELECT priorityCall FROM ccoCallPriorityOrder WHERE callout_id = @callout_id)
                             BEGIN
                                 SELECT @prioridadLlamada = Prioridad
                                 FROM ccCampsPrioridadTel
                                 WHERE cam_id = @cam_id

                                 INSERT INTO ccoCallPriorityOrder 
                                 VALUES (@callout_id,@prioridadLlamada)
                         END
                         -- Change priority and obtain the next telephone
                         UPDATE ccoCallsOutSource SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1	ELSE nNoContesta END
                         WHERE callout_id = @callout_id
                         UPDATE ccoCallPriorityOrder SET priorityCall = CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)) 
								+ REPLACE(''2345NNN'', CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)), ''1'') WHERE callout_id = @callout_id
                         SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(priorityCall, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 1, 1) END 
							+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 2, 1) END 
							+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 3, 1) END 
							+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 4, 1) END 
							+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 5, 1) END 
							+ ''+''''         ''''),13)) from ccoCallsOutSource nolock where callout_id='' 
							+ CAST(@callout_id AS VARCHAR(15))
                         FROM ccoCallPriorityOrder pll WITH(NOLOCK)
                         WHERE callout_id = @callout_id
                         EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

                         SELECT @DateNewDial = DATEADD(mi, @cam_inter_ocupado, GETDATE())

                         -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
                         IF @DateNewDial > @DateNextDial
                             BEGIN	-- Nueva fecha de Call BACk
                                 UPDATE ccoWorkingTable SET nOcupado = @nOcupado, cal_fechaDial = @DateNewDial, cal_status = @cal_status
                                 WHERE callout_id = @callout_id
                                 RETURN(0)
                         END
                         -- Mantiene la fecha de Call BACK
                         UPDATE ccoWorkingTable SET nOcupado = @nOcupado, cal_status = @cal_status, cal_telefono = @Telefono
                         WHERE callout_id = @callout_id
                         RETURN(0)
                 END

                 -- ELSE: Opcion Ocupado DESHABILITADA
                 EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                 RETURN(0)
         END
             ELSE
             IF @CallResultDial IN(3, 5, 8)
                 BEGIN-- NO CONTESTA 
                     --select NO Contesta
                     SELECT @cam_nocontesto = cam_nocontesto, 
                            @cam_inter_nocontesto = cam_inter_nocontesto, 
                            @cam_NoInt_nocontesto = cam_NoInt_nocontesto, 
                            @nNoContesta = @nNoContesta + 1
                     FROM ccCamps
                     WHERE cam_id = @cam_id
                     IF @cam_nocontesto = 1
                         BEGIN-- Opcion NoContesta HABILITADA	 
                             IF @nNoContesta > @cam_NoInt_nocontesto
                                OR @nShortCall > 4
                                 BEGIN --select No Contesta Habilitada
                                     EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                                     RETURN(0)
                             END

                             IF NOT EXISTS (SELECT priorityCall FROM ccoCallPriorityOrder WHERE callout_id = @callout_id)
                                 BEGIN
                                     SELECT @prioridadLlamada = Prioridad
                                     FROM ccCampsPrioridadTel
                                     WHERE cam_id = @cam_id

                                     INSERT INTO ccoCallPriorityOrder
                                     VALUES (@callout_id, @prioridadLlamada)
                             END

                             -- Change priority and obtain the next telephone
                             UPDATE ccoCallsOutSource SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1 ELSE nNoContesta END
                             WHERE callout_id = @callout_id
                             UPDATE ccoCallPriorityOrder SET priorityCall = CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)) 
									+ replace(''2345NNN'', CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)), ''1'')
							 WHERE callout_id = @callout_id

                             SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(priorityCall, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 1, 1) END 
								+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 2, 1) END 
								+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 3, 1) END 
								+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 4, 1) END 
								+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 5, 1) END 
								+ ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id='' 
								+ CAST(@callout_id AS VARCHAR(15))
                             FROM ccoCallPriorityOrder WITH(NOLOCK)
                             WHERE callout_id = @callout_id

                             EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

                             SELECT @DateNewDial = DATEADD(mi, @cam_inter_nocontesto, GETDATE())

                             UPDATE ccoWorkingTable SET nNoContesta = @nNoContesta, cal_status = @cal_status, cal_telefono = @Telefono, 
									cal_fechaDial = CASE
                                                       WHEN @DateNewDial > @DateNextDial
                                                       THEN @DateNewDial
                                                       ELSE cal_fechaDial
                                                    END
                             WHERE callout_id = @callout_id
                             RETURN(0)
                     END

                     -- Opcion NoContesta DESHABILITADA
                     EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                     RETURN(0)
             END
             ELSE
                 IF @CallResultDial = 4
                     BEGIN-- Fax/Modem 
                         SELECT @cam_fax = cam_fax,
                                @cam_inter_fax = cam_inter_fax, 
                                @cam_NoInt_fax = cam_NoInt_fax, 
                                @nFax = @nFax + 1
                         FROM ccCamps
                         WHERE cam_id = @cam_id
                         IF @cam_fax = 1
                             BEGIN-- Opcion Fax/Modem HABILITADA	 
                                 IF @nFax > @cam_NoInt_fax
                                    OR @nShortCall > 4
                                     BEGIN
                                         EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                                         RETURN(0)
                                 END
                                 IF NOT EXISTS (SELECT priorityCall FROM ccoCallPriorityOrder WHERE callout_id = @callout_id)
                                     BEGIN
                                         SELECT @prioridadLlamada = Prioridad
                                         FROM ccCampsPrioridadTel
                                         WHERE cam_id = @cam_id

                                         INSERT INTO ccoCallPriorityOrder
                                         VALUES (@callout_id, @prioridadLlamada)
                                 END

                                 -- Change priority and obtain the next telephone
                                 UPDATE ccoCallsOutSource SET nFax = CASE WHEN nFax < 255 THEN ISNULL(nFax, 0) + 1 ELSE nFax END
                                 WHERE callout_id = @callout_id

                                 UPDATE ccoCallPriorityOrder SET priorityCall = CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1))  
								    + replace(''2345NNN'', CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)), ''1'') 
								 WHERE callout_id = @callout_id

                                 SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(priorityCall, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 1, 1) END 
								 + ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 2, 1) END 
								 + ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 3, 1) END 
								 + ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 4, 1) END 
								 + ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 5, 1) END 
								 + ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id='' 
								 + CAST(@callout_id AS VARCHAR(15))
                                 FROM ccoCallPriorityOrder WITH(NOLOCK)
                                 WHERE callout_id = @callout_id
                                 
								 EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

                                 SELECT @DateNewDial = DATEADD(mi, @cam_inter_fax, GETDATE())

                                 -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
                                 UPDATE ccoWorkingTable SET nFax = @nFax, cal_status = @cal_status, cal_telefono = @Telefono, 
                                       cal_fechaDial = CASE
                                                           WHEN @DateNewDial > @DateNextDial
                                                           THEN @DateNewDial
                                                           ELSE cal_fechaDial
                                                       END
                                 WHERE callout_id = @callout_id
                                 RETURN(0)
                         END

                         -- Opcion Fax/Modem DESHABILITADA
                         EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                         RETURN(0)
                 END
                     ELSE
                     IF @CallResultDial = 11
                         BEGIN-- Maquina Contestadora 
                             SELECT @cam_graba = cam_graba, 
                                    @cam_inter_graba = cam_inter_graba, 
                                    @cam_NoInt_graba = cam_NoInt_graba, 
                                    @nContestadora = @nContestadora + 1
                             FROM ccCamps
                             WHERE cam_id = @cam_id
                             IF @cam_graba = 1 -- Opcion Maquina Contestadora HABILITADA
                                 BEGIN
                                     IF @nContestadora > @cam_NoInt_graba OR @nShortCall > 4
                                         BEGIN
                                             EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                                             RETURN(0)
                                     END
                                     IF NOT EXISTS (SELECT priorityCall FROM ccoCallPriorityOrder WHERE callout_id = @callout_id)
                                         BEGIN
                                             SELECT @prioridadLlamada = Prioridad
                                             FROM ccCampsPrioridadTel
                                             WHERE cam_id = @cam_id
                                             INSERT INTO ccoCallPriorityOrder
                                             VALUES (@callout_id, @prioridadLlamada)
                                     END

                                     -- Change priority and obtain the next telephone
                                     UPDATE ccoCallsOutSource SET nContestadora = CASE WHEN nContestadora < 255 THEN ISNULL(nContestadora, 0) + 1 ELSE nContestadora END
                                     WHERE callout_id = @callout_id

                                     UPDATE ccoCallPriorityOrder SET priorityCall = CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)) 
										+ replace(''2345NNN'', CAST(CASE WHEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) < 5 THEN CAST(SUBSTRING(priorityCall, 1, 1) AS TINYINT) + 1 ELSE 1 END AS VARCHAR(1)), ''1'')
                                     WHERE callout_id = @callout_id

                                     SELECT @sSQL = ''select @outA=rtrim(left(ltrim(cal_telefono'' + CASE SUBSTRING(priorityCall, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 1, 1) END 
										+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 2, 1) END 
										+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 3, 1) END 
										+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 4, 1) END 
										+ ''+''''         ''''+'' + ''cal_telefono'' + CASE SUBSTRING(priorityCall, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(priorityCall, 5, 1) END 
										+ ''+''''         ''''),13)) from ccocallsoutsource nolock where callout_id='' 
										+ CAST(@callout_id AS VARCHAR(15))
                                     FROM ccoCallPriorityOrder WITH(NOLOCK)
                                     WHERE callout_id = @callout_id

                                     EXEC sp_executesql @sSQL, N''@outA varchar(15) OUTPUT'', @outA = @Telefono OUTPUT

                                     SELECT @DateNewDial = DATEADD(mi, @cam_inter_graba, GETDATE())

                                     -- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
                                     UPDATE ccoWorkingTable SET nContestadora = @nContestadora, cal_status = @cal_status, cal_telefono = @Telefono, 
                                           cal_fechaDial = CASE
                                                               WHEN @DateNewDial > @DateNextDial
                                                               THEN @DateNewDial
                                                               ELSE cal_fechaDial
                                                           END
                                     WHERE callout_id = @callout_id
                                     RETURN(0)
                             END

                             -- Opcion Maquina Contestadora DESHABILITADA
                             EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                             RETURN(0)
                     END
                         ELSE
                         IF @CallResultDial IN(10, 90)
                             BEGIN--No Dial Tone, otros, NoService 
                                 EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
                                 RETURN(0)
                         END
                             ELSE
                             IF @CallResultDial > 13 AND @CallResultDial <> 51
                                 BEGIN--Dial Result not register
                                     EXEC ccsp_OUTUpdateDialJob @callout_id = @callout_id, @CallResultDial = 8, @isTCPA = @isTCPA
                             END

     RETURN(0)
     SET NOCOUNT OFF'

		exec (@sql)

		set @process = 'CW-3489 Alter del SP ccsp_OUTCancelDialJOB para eliminar los registros de la tabla ccoCallPriorityOrder'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_OUTCancelDialJOB] 
	@callout_id    INT, 
	@IsAnswer      TINYINT, 
    @nOcupado      TINYINT, 
    @nNoContesta   TINYINT, 
    @nFax          TINYINT, 
    @nContestadora TINYINT, 
    @nShortCall    TINYINT, 
    @nOtro         TINYINT, 
    @ExisteWT      TINYINT = 1
AS
     DECLARE @RecicleSIC TINYINT;

     SELECT @RecicleSIC = ISNULL(valor, 0)
     FROM ccSettings
     WHERE setting_id = 60;

     -- En workingtable
     IF(@ExisteWT > 0)
         BEGIN
             IF(@IsAnswer = 1)
                 BEGIN
                     UPDATE ccoWorkingTable 
						SET cal_fechaDial = DATEADD(hh, 1, GETDATE()),
							cal_status = 1,
							nOcupado = 1,
							nNoContesta = 1,
							nShortCall = nShortCall + 1
                     WHERE callout_id = @callout_id;
             END
                 ELSE
                 BEGIN
                     IF(@RecicleSIC = 0)
                         BEGIN

                             DELETE ccoWorkingTable
                             WHERE callout_id = @callout_id;

                             DELETE ccoCallPriorityOrder
                             WHERE callout_id = @callout_id;
                     END
             END
     END'

		exec (@sql)

		set @process = 'CW-3489 Alter de SP ccsp_AgentSetCallStatus para eliminar los registros de la tabla ccoCallPriorityOrder para llamadas contestadas'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentSetCallStatus] 
	@callout_id INT, 
    @cal_id     INT, 
    @TipoCall   TINYINT, -- 1= IN,  2=Out
    @TipoMov    TINYINT, -- 4 OnDialog, 7=OFFHook_OnXfer, 9=CallNoAnswered
    @cal_tXfer  TINYINT    = 0, 
    @cal_tring  SMALLINT   = 0, 
    @user_id    SMALLINT   = 0, 
    @extension  VARCHAR(5) = '''', 
    @isChatCall BIT        = 0
AS
     SET NOCOUNT ON
     DECLARE @RecicleSIC TINYINT

     SELECT @RecicleSIC = ISNULL(valor, 0)
     FROM ccSettings
     WHERE setting_id = 60

     DECLARE @ANI_x VARCHAR(19)
     DECLARE @cal_inicio DATETIME
     DECLARE @callout_id_IN INT
     DECLARE @cal_key VARCHAR(20)
     DECLARE @cam_id INT
     DECLARE @cal_telefono VARCHAR(30)
     DECLARE @surveycamid INT
     DECLARE @inbound_id INT
     IF @TipoMov = 4 OR @TipoMov = 14 -- DIALOG OnDialog
         BEGIN
             IF @TipoCall = 2
                 BEGIN
                     IF @TipoMov = 4
                         BEGIN
                             UPDATE ccoCallsOUT WITH(ROWLOCK)
                               SET cal_Inicio = GETDATE(), 
                                   statusCall_id = 13, 
                                   cal_manual = CASE
                                                    WHEN @isChatCall = 1
                                                    THEN 3
                                                    ELSE cal_manual
                                                END
                             WHERE cal_id = @cal_id
                     END
                         ELSE
                         IF @TipoMov = 14
                             UPDATE ccoCallsOUT WITH(ROWLOCK)
                               SET statusCall_id = 13, 
                                   cal_tRing = @cal_tring, 
                                   user_id = @user_id, 
                                   cal_extension = @extension
                             WHERE cal_id = @cal_id
                     IF @RecicleSIC = 0
                         BEGIN
                             DELETE ccoWorkingTable WITH(ROWLOCK)
                             WHERE callout_id = @callout_id

                             DELETE ccoCallPriorityOrder WITH(ROWLOCK)
                             WHERE callout_id = @callout_id
                     END
                     UPDATE ccoCallBacks
                       SET [status] = 1, 
                           schedulerStatus = 1, 
                           cal_fcallback = cal_inicio
                     FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
                     WHERE a.callout_id = b.callout_id
                           AND b.callout_id = @callout_id
                           AND b.cal_id = @cal_id
                           AND [status] = 0
                           AND statusCall_id = 13

                     -- calcula el costo de la llamada
                     EXEC ccsp_CstoCalculaCosto @cal_id

                     RETURN(0)
             END
             IF @TipoMov = 4
                 UPDATE ccCallsIN WITH(ROWLOCK)
                   SET statusCall_id = 13
                 WHERE cal_id = @cal_id

                 ELSE
                 IF @TipoMov = 14
                     UPDATE ccCallsIN WITH(ROWLOCK)
                       SET statusCall_id = 13, 
                           cal_tRing = @cal_tring, 
                           user_id = @user_id, 
                           cal_extension = @extension
                     WHERE cal_id = @cal_id

             -- Elimina callback generado por abandono
             SELECT @ANI_x = cal_ani, 
                    @cal_inicio = cal_inicio
             FROM cccallsin WITH (INDEX(PK_ccCallsIn))
             WHERE cal_id = @cal_id

             SELECT @callout_id_IN = callout_id
             FROM ccRIAUpdateCallBack_Abandon
             WHERE cal_ani = @ANI_x

             UPDATE ccoCallBacks WITH(ROWLOCK)
               SET [status] = 1, 
                   schedulerStatus = 1, 
                   cal_fcallback = @cal_inicio
             WHERE callout_id = @callout_id_IN
                   AND [status] = 0

             DELETE ccoWorkingTable WITH(ROWLOCK)
             WHERE callout_id IN
             (
                 SELECT DISTINCT
                        (callout_id)
                 FROM ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
                 WHERE cal_ani = @ANI_x
             )

             DELETE ccRIAUpdateCallBack_Abandon WITH(ROWLOCK)
             WHERE cal_ANI = @ANI_x

             RETURN(0)
     END
     IF @TipoMov = 7 --OTHER OFFHook_OnXfer
         BEGIN
             IF @cal_id <= 0
                 RETURN(0)
             IF @TipoCall = 2
                 BEGIN
                     UPDATE ccoCallsOUT WITH(ROWLOCK)
                       SET statusCall_id = 16
                     WHERE cal_id = @cal_id
                     -- calcula el costo de la llamada

                     UPDATE ccoCallBacks
                       SET [status] = 2, 
                           schedulerStatus = 1, 
                           cal_fcallback = cal_inicio
                     FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
                     WHERE a.callout_id = b.callout_id
                           AND b.callout_id = @callout_id
                           AND b.cal_id = @cal_id
                           AND [status] = 0
                           AND statusCall_id = 16

                     EXEC ccsp_CstoCalculaCosto 
                          @cal_id

                     RETURN(0)
             END
             UPDATE ccCallsIN WITH(ROWLOCK)
               SET statusCall_id = 16
             WHERE cal_id = @cal_id

             SELECT @ANI_x = cal_ani, 
                    @cal_inicio = cal_inicio
             FROM cccallsin WITH (INDEX(PK_ccCallsIn))
             WHERE cal_id = @cal_id

             SELECT @callout_id_IN
             FROM ccRIAUpdateCallBack_Abandon
             WHERE cal_ani = @ANI_x

             UPDATE ccoCallBacks WITH(ROWLOCK)
               SET [status] = 2, 
                   schedulerStatus = 1, 
                   cal_fcallback = @cal_inicio
             WHERE callout_id = @callout_id_IN
                   AND [status] = 0

             RETURN(0)
     END
     IF @TipoMov = 9 --RING CallNoAnswered
         BEGIN
             IF @TipoCall = 2
                 BEGIN
                     UPDATE ccoCallsOUT WITH(ROWLOCK)
                       SET statusCall_id = 15, 
                           cal_tXFer = @cal_txFer, 
                           cal_tRing = @cal_tring
                     WHERE cal_id = @cal_id

                     -- calcula el costo de la llamada

                     UPDATE ccoCallBacks
                       SET [status] = 2, 
                           schedulerStatus = 1, 
                           cal_fcallback = cal_inicio
                     FROM ccoCallBacks a WITH (INDEX(IX_ccoCallBacks), NOLOCK), ccoCallsOUT b WITH (INDEX(IX_ccoCallsOut_11), NOLOCK)
                     WHERE a.callout_id = b.callout_id
                           AND b.callout_id = @callout_id
                           AND b.cal_id = @cal_id
                           AND [status] = 0
                           AND statusCall_id = 15

                     EXEC ccsp_CstoCalculaCosto @cal_id
             END

             UPDATE ccCallsIN WITH(ROWLOCK)
               SET statusCall_id = 15, 
                   cal_tXFer = @cal_txFer, 
                   cal_tRing = @cal_tring
             WHERE cal_id = @cal_id

             SELECT @ANI_x = cal_ani, 
                    @cal_inicio = cal_inicio
             FROM cccallsin WITH (INDEX(PK_ccCallsIn))
             WHERE cal_id = @cal_id

             SELECT @callout_id_IN
             FROM ccRIAUpdateCallBack_Abandon
             WHERE cal_ani = @ANI_x

             UPDATE ccoCallBacks WITH(ROWLOCK)
               SET [status] = 2, 
                   schedulerStatus = 1, 
                   cal_fcallback = @cal_inicio
             WHERE callout_id = @callout_id_IN
                   AND [status] = 0

             RETURN(0)
     END
     SET NOCOUNT OFF'

		exec (@sql)

		set @process = 'drop procedure en caso de existir'
		set @sql = '

		if exists (select * from sys.procedures where name = N''CS_GetAdminProps'')
    begin
        drop PROCEDURE CS_GetAdminProps
    end

		'
exec (@sql)

		set @process = 'CenterScript admin props'
		set @sql = '
			CREATE PROCEDURE [dbo].[CS_GetAdminProps] @admin_id INT
AS
SET NOCOUNT ON;

SELECT convert(int,user_id) as [user_id], Nombres as [name]
	,Upper(left(nombres, 1) + left(apellidopaterno, 1)) AS [initials]
FROM ccUsers a
WHERE TipoUser_id = 2
	AND User_id = @admin_id
		'
		exec (@sql)

			
		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		exec ccsp_getVersion 'BD', @version
		EXEC ccsp_getVersion 'BDF', @versionFix

		COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END
