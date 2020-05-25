/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/05/06
Description:

Database: CCenterRia
Required version: 122.17

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
SET @versionfix = 17
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 16
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-4065 Crear Setting para uso de Medios Unificados'
		set @sql='IF not exists (SELECT * FROM ccSettings WHERE setting_id = 220)
				insert into ccSettings (setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
				Values(220,''0'',''Mostrar icono para medios unificados'',1,''AGT'',''0:Oculta icono para medios unificados, 1:Muestra icono para medios unificados'',''Shows multimedia icon'',0,''^[0-1]$'')	'
		EXEC(@sql)

		set @process = 'CW-4074 Tiempo de espera para tecla de reprogramacion'
		set @sql='IF not exists (SELECT * FROM ccSettings WHERE setting_id = 221)
				INSERT INTO ccSettings (setting_id, valor, descripcion,	Status,	Tipo,detalle,description,bLoadSettings,	validate)
				VALUES	(221, 
						''5'',
						''Tiempo en el que el usuario puede teclear el digito para reprogramar la llamada'',	
						1,
						''X'',
						''Tiempo en el que el usuario puede teclear el digito para hacer una reprogramacion, cuando se encuentra en la cola de espera'',
						''Time in which the user can type the digit to do a reprogramming, when the user is in the waiting queue'',
						0,
			 			''*'')'
		EXEC(@sql)

		set @process = 'CW-4009 Campañas se siguen mostrando aunque el Admin ya no esté asociado a WG'
set @sql='ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS SMALLINT, 
												   @CampType AS SMALLINT = 0, 
												   @WorkgroupId AS INT = 0, 
												   @Id AS INT = 0,
												   @AdminId AS SMALLINT = 0, 
												   @PinUpdate AS SMALLINT = 0, 
												   @LoadId AS INT = 0
AS
BEGIN
	set nocount on
	IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type 
	BEGIN
		IF @CampType = 1 -- Campaigns Out 
		BEGIN
			IF @WorkgroupId IS NOT NULL
			BEGIN
				SELECT CAST(IdCampEsp AS INT) AS Id 
				FROM ccRIACampEspWG 
				WHERE IDWG = @WorkgroupId AND Tipo=1
				ORDER BY IdCampEsp ASC
			END
			ELSE
			BEGIN
				raiserror(''ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado'', 18, 1)
			END	
		END
		IF @CampType = 0 -- Campaigns In (ACD)
		BEGIN
			IF @WorkgroupId IS NOT NULL
			BEGIN
				SELECT CAST(IdCampEsp AS INT) AS Id 
				FROM ccRIACampEspWG 
				WHERE IDWG = @WorkgroupId AND Tipo=0
				ORDER BY IdCampEsp ASC
			END
			ELSE
			BEGIN
				raiserror(''ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado'', 18, 1)
			END	
		END
	END
	
	IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id 
		BEGIN
			IF @CampType = 1 -- Campaigns Out 
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
								rel.cam_id AS Id, 
								camps.cam_descripcion AS Name, 
								CAST(graph.graphic_id AS INT) AS Frame, 
								CAST(rel.tipo AS SMALLINT) AS Type,
								cam_procesando IsStarted
							FROM ccSupervisorCam rel
								LEFT JOIN ccCamps camps ON camps.cam_id = rel.cam_id
								LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
							WHERE rel.cam_id = @Id AND rel.tipo = 1
							ORDER BY camps.cam_descripcion ASC;
						END
					ELSE
					BEGIN
						raiserror(''ERROR. No existe campa?as de salida con el id especificado'', 18, 1)
					END	
				END
			IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
								rel.cam_id AS Id, 
								inbound.descripcion AS Name, 
								CAST(graph.graphic_id AS INT) AS Frame,
								0 Pin, 
								CAST(rel.tipo AS SMALLINT) AS Type,
								CAST(0 AS BIT) IsStarted
							FROM ccSupervisorCam rel
								LEFT JOIN ccInbound inbound ON inbound.Inbound_id = rel.cam_id
								LEFT JOIN ccRIAInboundGraph graph ON inbound.Inbound_id = graph.Inbound_id
							WHERE rel.cam_id = @Id AND rel.tipo = 0
							ORDER BY inbound.descripcion ASC;
						END
					ELSE
						BEGIN
							raiserror(''ERROR. No existe campa?as de entrada con el id especificado'', 18, 1)
						END	
				END
		END

	IF @Option = 3   -- Update OverallTotalNew By Campaign 
		BEGIN
			IF @Id IS NOT NULL
				BEGIN
					UPDATE ccCampsNvosCB SET OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id
				END
			ELSE
				BEGIN
					raiserror(''ERROR. No existe la campa?as de entrada con el id especificado'', 18, 1)
				END	
		END

	IF @Option = 4	 -- Update Pin from Campaign per Admin
		BEGIN
			IF @Id IS NOT NULL AND @AdminId IS NOT NULL
				BEGIN
					IF @PinUpdate = 1
						BEGIN
							INSERT INTO PinedCampaigns (CampId, AdminId)
								   VALUES (@Id, @AdminId);
						END;
					IF @PinUpdate = 0
						BEGIN
							DELETE FROM PinedCampaigns
							WHERE CampId = @Id AND AdminId = @AdminId;
						END;
				END
			ELSE
				BEGIN
					raiserror(''ERROR. La campa?as o administrador no existen'', 18, 1)
				END	
		END
	
	IF @Option = 5	 -- Get Pin from Campaign Ids per Admin
		BEGIN
			IF @AdminId IS NOT NULL
				BEGIN
					SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId
					ORDER BY Id ASC
				END
			ELSE
				BEGIN
					raiserror(''ERROR. El administrador con el id seleccionado no existe'', 18, 1)
				END	
		END

	IF @Option = 6	 -- Get Blacklist Ids by Campaign Id
	BEGIN
		IF @Id IS NOT NULL
			BEGIN
	            DECLARE @BlackListIds VARCHAR(MAX);
	            SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
	            FROM Camplistanegra
	            WHERE cam_id = @Id AND STATUS = 1;
	            SELECT isnull(@BlackListIds,''0'') AS BlackListIds;
			END
		ELSE
			BEGIN
				raiserror(''ERROR. La campa?as con el id seleccionado no existe'', 18, 1)
			END	
	END

	IF @Option = 7	 -- Get RegistryListIds Ids by Campaign Id
	BEGIN
		IF (@Id IS NOT NULL AND EXISTS(SELECT * FROM cccamps WHERE cam_id = @Id))
			BEGIN
				SELECT TOP 1 list_id FROM ccRIARegistryLists WHERE cam_id = @Id AND status = 2 ORDER BY list_id DESC
			END
		ELSE
			BEGIN
				--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
				raiserror(''ERROR. No existe una campa?a con el id especificado'', 18, 1)			
			END	
	END

	IF @Option = 8	 -- Delete RegistryListIds Ids by LoadId
	BEGIN
		IF (@LoadId IS NOT NULL AND EXISTS(SELECT * FROM ccRIARegistryLists WHERE list_id = @loadID and status <> 0))
			BEGIN
				UPDATE ccoCallsOutSource SET cal_status = ''5'' WHERE list_id = @loadID
				DELETE FROM ccoWorkingTable WHERE list_id = @LoadId 
				exec ccsp_RIARegistryLists @action=6, @list_id = @LoadId 
			END
		ELSE
			BEGIN
				--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
				raiserror(''ERROR. No existe una carga el id especificado'', 18, 1)
			END		
	END

	 IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
         BEGIN
             DECLARE @table TABLE
             (camId    INT, 
              campType TINYINT,
              PRIMARY KEY(camId, campType)
             );
             INSERT INTO @table
                    SELECT DISTINCT 
                           IdCampEsp, 
                           Tipo
                    FROM ccRIACampEspWG wg
                    WHERE wg.IDWG IN
                    (
                        SELECT IDWG
                        FROM ccRIAWorkGroupUsers
                        WHERE IDWG <> @WorkgroupId
                        AND User_id = @AdminId
                    );
             SELECT CAST(B.IdCampEsp AS INT) AS Id, 
                    B.Tipo AS Type
             FROM @table A
                  RIGHT JOIN
             (
                 SELECT wg.IdCampEsp, 
                        wg.Tipo
                 FROM ccRIACampEspWG wg
                 WHERE wg.IDWG = @WorkgroupId
             ) B ON A.camId = B.IdCampEsp
                    AND A.campType = B.Tipo
             WHERE A.camId IS NULL
             ORDER BY IdCampEsp;
     END;
END

		'
		EXEC(@sql)


		set @process = 'CW-4004 Ver total de resultado de marcacion'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_OUTGetCallsInfo_AllCamps'')
	    begin
	        DROP PROCEDURE ccsp_OUTGetCallsInfo_AllCamps;
	    end'
		EXEC(@sql)

		set @process = 'CW-4004 Ver total de resultado de marcacion'
		set @sql = '
		CREATE PROCEDURE [dbo].[ccsp_OUTGetCallsInfo_AllCamps]
		@Tipo as tinyint=0,
		@cam_id as smallint = 0,
		@sup_id as smallint=0
		AS

		declare @mToday as smalldatetime

		select @mToday = convert(smalldatetime, convert(varchar(11), getdate() ), 101)
		if @Tipo = 0
		begin
		  SELECT cam_id, cam_descripcion,
		    0 as pContesta,
		    0 as pOcupado,
		    0 as pNoContesta,
		    0 as pFaxModem,
		    0 as pNoService,
		    0 as Marcaciones, 0 as Contestan,  0 as Ocupado, 0 as NoContesta, 0 as FaxModem, 0 as NoService
		  FROM ccCamps
		  order by cam_id
		end

		else if @Tipo = 1
		begin
		  select cam_id, L.Campana,
		    ((L.Contestan*100)/ L.Marcaciones) as pContesta,
		    ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
		    ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
		    ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
		    ((L.NoService*100)/ L.Marcaciones) as pNoService,
		    L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
		    ,L.Otro,L.Cancelado,L.buzon,L.NoDialTone,L.congestion
		  from (
		  select cam_id, '''' as Campana,
		    count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
		    count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
		    count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		    count(*) as Marcaciones
		    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Otro
		    ,count(case tipoResDial_id when 13 then 1 else null end) as Cancelado
		    ,count(case tipoResDial_id when 11 then 1 else null end) as buzon
		    ,count(case tipoResDial_id when 5 then 1 else null end) as NoDialTone
		    ,count(case tipoResDial_id when 12 then 1 else null end) as congestion

		  from ccoLogDials with(nolock)
		  Where fecha >  @mToday
		  group by cam_id
		  ) L order by Campana

		end

		else if @Tipo = 2
		begin
		  select cam_id, L.Campana,
		    ((L.Contestan*100)/ L.Marcaciones) as pContesta,
		    ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
		    ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
		    ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
		    ((L.NoService*100)/ L.Marcaciones) as pNoService,
		    L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
		  from (
		  select C.cam_id as cam_id, cam_descripcion as Campana,
		    count(case tipoResDial_id when 1 then 1 else null end) as Contestan,
		    count(case tipoResDial_id when 2 then 1 else null end) as Ocupado,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoContesta,
		    count(case tipoResDial_id when 4 then 1 else null end) as FaxModem,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		    count(*) as Marcaciones
		  from ccoLogDials L with(nolock)
		  inner join ccCamps C on L.cam_id=C.cam_id
		  Where fecha >  @mToday
		  group by C.cam_id, cam_descripcion
		  ) L order by Campana
		end

		else if @Tipo = 3 --Busqueda por campaña
		begin
		  select L.cam_id,
		    L.Calls, L.Answer, L.Busy, L.NoAnswer, L.Fax, L.NoService
		    ,L.Other,L.Canceled,L.Machine,L.NoTone,L.Congestion, isnull(callsOut.Abandon,0) as Abandon
		  from (
		  select cam_id,
		    count(case tipoResDial_id when 1 then 1 else null end) as Answer,
		    count(case tipoResDial_id when 2 then 1 else null end) as Busy,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
		    count(case tipoResDial_id when 4 then 1 else null end) as Fax,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		    count(*) as Calls
		    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
		    ,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
		    ,count(case tipoResDial_id when 11 then 1 else null end) as Machine
		    ,count(case tipoResDial_id when 5 then 1 else null end) as NoTone
		    ,count(case tipoResDial_id when 12 then 1 else null end) as Congestion

		  from ccoLogDials with(nolock)
		  Where cam_id = @cam_id
		  and fecha >  @mToday
		  group by cam_id
		  ) L 
		  left join (select 
		    cam_id,
		    count(case statuscall_id when 6 then 1 else null end) as Abandon,
		    count(*) as Contesta    
		  from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
		  where cal_Inicio > @mToday
		  group by cam_id) callsOut on L.cam_id = callsOut.cam_id

		end

		else if @Tipo = 4-- Busqueda por campañas asociadas a admin
		begin
		  select L.cam_id,
		    L.Calls, L.Answer, L.Busy, L.NoAnswer, L.Fax, L.NoService
		    ,L.Other,L.Canceled,L.Machine,L.NoTone,L.Congestion, isnull(callsOut.Abandon,0) as Abandon
		  from (
		  select logDials.cam_id,
		    count(case tipoResDial_id when 1 then 1 else null end) as Answer,
		    count(case tipoResDial_id when 2 then 1 else null end) as Busy,
		    count(case tipoResDial_id when 3 then 1 else null end) as NoAnswer,
		    count(case tipoResDial_id when 4 then 1 else null end) as Fax,
		    count(case tipoResDial_id when 10 then 1 else null end) as NoService,
		    count(*) as Calls
		    ,count(case when tipoResDial_id= 8  or tipoResDial_id> 13 then 1   else null end) as Other
		    ,count(case tipoResDial_id when 13 then 1 else null end) as Canceled
		    ,count(case tipoResDial_id when 11 then 1 else null end) as Machine
		    ,count(case tipoResDial_id when 5 then 1 else null end) as NoTone
		    ,count(case tipoResDial_id when 12 then 1 else null end) as Congestion
		  from ccoLogDials logDials with(nolock)
		  right join (select distinct cam_id from ccSupervisorCam supCam where user_id=@sup_id) B ON logDials.cam_id = B.cam_id
		  Where fecha >  @mToday
		  group by logDials.cam_id
		  ) L 
		  left join (select 
		    cam_id,
		    count(case statuscall_id when 6 then 1 else null end) as Abandon,
		    count(*) as Contesta    
		  from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
		  where cal_Inicio > @mToday
		  group by cam_id) callsOut on L.cam_id = callsOut.cam_id
		  order by L.cam_id
		end
'
		EXEC(@sql)

		set @process = 'CW-4066 Add column contentId to table attached'
		set @Sql= 'if not exists (select * from sys.columns where name = N''contentId'' and Object_ID = Object_ID(N''attached''))
				   begin
						ALTER TABLE attached
						ADD contentId varchar(255) NULL; 
				   end'
		exec (@sql)

		set @process = 'CW-4066 Add column isEmbedded to table attached '
		set @Sql= 'if not exists (select * from sys.columns where name = N''isEmbedded'' and Object_ID = Object_ID(N''attached''))
				   begin
						ALTER TABLE attached
						ADD isEmbedded bit NULL; 
				   end'
		exec (@sql)

		set @process = 'CW-4066-4089 Alter stored procedure ccsp_SaveMail '
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_MailSave]
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
@mailClient varchar(255)= null,
@mailACD varchar(60)= null,
@isSender bit=0,
@isUser bit = 0,
@info varchar(255)=null,
@dispositionId smallint=0,
@subDispositionId smallint=0,
@tWrapUp int =0,
@tRetention int = 0,
@email varchar(255) = null,

---Finder
@supervisor varchar(100)='''' ,@template varchar (100)='''',@ScoreTemplate int =0,
@top int=30,

---Embedded images
@contentId varchar(255)=null,
@isEmbedded bit = null
AS
BEGIN


declare @isEndConversation bit
declare @meanContactTypeId smallint
declare @xmlnode xml
declare @existAttached bit, @numInteracion smallint
declare @ids varchar(max)

set @meanContactTypeId = 1
SET NOCOUNT ON;

if @action = 1 begin --find uid ConversationMail
if not exists(select A.uid,C.mailInbound from messageMail A 
    inner join [message] B on A.messageId=B.messageId
    inner join [conversation] C on C.conversationId=B.conversationId
    where A.[uid]=@uid and C.mailInbound=@mailACD) 
    select 0
else select 1
  return (0)
end
else if @action = 2 BEGIN --new Conversation
    if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin
        insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)
        select @conversationId=SCOPE_IDENTITY()
        insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,0,@date,@messageStatusId)
        select @messageId=SCOPE_IDENTITY()
        insert into [messageMail](messageId,[uid]) values (@messageId,@uid)
        select @conversationId as ConversationId,@messageId as MessageId,0 as LastUserId
        return (0)
    end
    else begin
        select 0 as ConversationId,0 as MessageId,0 as LastUserId
        return (0)
    end
END
else if @action = 3 BEGIN --new Messages
    if @date is null set @date=getdate()
    if @mailACD is null select @mailACD=mailInbound from conversation where conversationId=@conversationId
    if not exists(select * from [conversation] where conversationId=@conversationId) begin --si el id conversacion no existe
        insert into [conversation](inboundId,info,isInbox,isFinished,mailClient,mailInbound,meanContactTypeId) values (@inboundId,@info,@isInbox,0,@mailClient,@mailACD,@meanContactTypeId)
        select @conversationId=SCOPE_IDENTITY()
    end

    if not exists(select A.uid conversationId from messageMail A inner join [message] B on A.messageId=B.messageId where A.uid=@uid and B.date=@date) begin     
        insert into [message](conversationId,userId,[date],messageStatusId) values(@conversationId,@userId,@date,@messageStatusId)
        select @messageId=SCOPE_IDENTITY()
    end
    else begin
        select 0 as ConversationId,0 as MessageId,0 as LastUserId
        return (0)
    end

    if @uid is null --for outbound messages
        select @uid = dbo.md5(cast(@conversationId as varchar(10)) + ''_'' + cast(@messageId as varchar(10)))

    insert into [messageMail](messageId,[uid]) values (@messageId,@uid)

    --Finder
    select @existAttached =case when count(*)>0 then 1 else 0 end  from attached where messageId in (select messageId from message where conversationId=@conversationId)
    select @numInteracion = count(*) from message where conversationId=@conversationId
    --Actualiza un nodo del finder
    exec ccsp_CreateNodeMultimedia @type=1, @conversationId=@conversationId, @xml = @xmlnode OUTPUT
    if not exists(select * from ccEmailNode where emailId=@conversationId) begin
        insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
    end
    else begin
        update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
    end
    select @conversationId as ConversationId,@messageId as MessageId,0 as LastUserId

END
else if @action = 4 BEGIN --new attachment
    --insert into [attached](messageId,pathFile,isUser) values(@messageId,@pathFile,@isUser)
	insert into [attached](messageId,pathFile,isUser,contentId,isEmbedded) values(@messageId,@pathFile,@isUser,@contentId,@isEmbedded)
    select SCOPE_IDENTITY() as attachedId
END
else if @action = 5 BEGIN --Correos por contestar Status DOWNLOAD,Assigned,READ,UnaSSIGNED   
	select top(@top) A.conversationId,B.userId,A.mailClient,A.mailInbound,A.info,B.messageStatusId,B.messageId from (
	select A.conversationId,max(A.mailClient) as mailClient ,max(A.mailInbound) as mailInbound,min(A.info) as info,
		max(B.messageId) as messageId from conversation  A 
	inner join message B on A.conversationId = B.conversationId
	where A.inboundId = @inboundId and A.isFinished=0 and meanContactTypeId = @meanContactTypeId
	group by A.conversationId
	) A 
	inner join message B on A.conversationId = B.conversationId and A.messageId = B.messageId
	where B.messageStatusId in(1,2,3,4)

END
else if @action = 6 BEGIN --update Time Attention, Retencion
    select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
    update [message] set tResponse=@timeAtt,tRetention=@tRetention,isSender=@isSender,messageStatusId=@messageStatusId,userId=@userId where messageId=@messageId
END
else if @action = 7 BEGIN --Cambia el status del mensaje
    select @messageId=max(messageId) from [message] with(nolock) where conversationId=@conversationId
    --Status Read
    if @messageStatusId=3  update [message] set tWait=DATEDIFF(ss,isnull(tQueue,getdate()), getdate()) where messageId=@messageId

    --Status Send
    if @messageStatusId=6  begin
        select @isEndConversation=isFinished from conversation where conversationId=@conversationId
        if @isEndConversation = 1 set @messageStatusId=11--Close conversation by Agent
        update [message] set tSend=getdate() where messageId=@messageId
    end
    update [message] set messageStatusId=@messageStatusId where messageId=@messageId

    --Answered,Send,CLose Conversation system or agent
    if @messageStatusId in (5,6,10,11)  begin
        exec ccsp_CreateNodeMultimedia @type=1, @conversationId=@conversationId, @xml = @xmlnode OUTPUT
		if exists(select * from ccEmailNodeHistory where emailId=@conversationId) begin
            update ccEmailNodeHistory set node=@xmlnode,status=2 where emailId=@conversationId
        end
        if  exists(select * from ccEmailNode where emailId=@conversationId) begin
            update ccEmailNode set node=@xmlnode,status=2 where emailId=@conversationId
        end
        else begin
            insert into ccEmailNode(emailId,node,dateIn,status) values(@conversationId,@xmlnode,getdate(),0)
        end
    end

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
    if @conversationId is null or @conversationId=0 begin
        set @conversationId=0
        select @conversationId=conversationId from message where messageId=@messageId 
    end
    
    select pathFile as NameFile,isUser from attached A
    inner join message B on A.messageId=B.messageId and B.conversationId=@conversationId
    where B.conversationId=@conversationId
END
else if @action = 10 BEGIN --Correos por enviar
    select A.conversationId as ConversationId,B.messageId as MessageId,B.userId as AgentId,A.inboundId as AcdId,A.mailInbound as MailInbound
	 from (
	select A.inboundId,A.conversationId as ConversationId,max(B.messageId) as MessageId,A.mailInbound   from conversation A 
	inner join message B on A.conversationId = B.conversationId
	where A.meanContactTypeId = 1 --and (@inboundId is null or A.inboundId=3)
	GROUP BY A.conversationId,A.inboundId,A.mailInbound 
	) A
	inner join message B on A.MessageId = B.messageId
	where B.messageStatusId in(5,7,8,9) 
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
else if @action = 14 begin
 update [message] set @messageStatusId=1,tQueue=null,userId=0,tWait=0,tResponse=0,tRetention=0,tWrapUp=0,tSend=null,isSender=0  where messageStatusId in(2,3)
end
else if @action = 15 begin

    SELECT @existAttached = case when count(*)>0 then 1 else 0 end
    from attached where messageId in (select messageId from message where conversationId=@conversationId)

    select max(B.messageId) as MessageID, cast(max(A.inboundid) as int) as InboundID, max(A.conversationid) as ConversationID,
        max(A.mailClient) as ClientEmail, min(B.[date]) as [Date], @existAttached isAttached, max(C.descripcion) as ACDName,
        max(B.tSend) as tSend, max(D.Nombres+'' ''+D.ApellidoPaterno+'' ''+D.ApellidoMaterno) as NameAgent,
        cast(max(E.timeAlertMessage) as int) tAlertMessage, cast(max(E.answerTimeOut) as int) tAnswerTimeOut, max(C.tNotas) as tWrapUp,
        max(A.mailInbound) as InboundEmail, isnull(max(E.name), '''') as SenderName, cast(max(F.graphic_id) as int) as ACDGraphicID
    from conversation A
    inner join message B  on A.conversationId = B.conversationId
    inner join ccinbound C on A.inboundid= C.inbound_id
    left join ccUsers D on B.userId = D.User_id
    inner join contactMeanIn E on E.inboundId=C.Inbound_id   and E.meanContactTypeId=@meanContactTypeId
	inner join ccRIAinboundGraph F on C.Inbound_id = F.Inbound_id
	inner join ccRIAGraphics G on F.graphic_id = g.graphic_id
    where A.conversationId=@conversationId

end
else if @action = 16 begin
    select A.inboundid,B.messageid,a.conversationid,c.pathFile
    from conversation A
    inner join message B  on A.conversationId = B.conversationId
    inner join attached C on B.messageid= C.messageid
    where A.conversationId=@conversationId
end
else if @action = 17 begin --Asignar una evluacion
    exec ccsp_CreateNodeMultimedia @type=1, @conversationId=@conversationId, @xml = @xmlnode OUTPUT,@supervisor=@supervisor,@template=@template,@ScoreTemplate=@ScoreTemplate
    if not exists(select * from ccEmailNode where emailId=@conversationId) begin
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
else if @action = 19 begin
    select isnull(max(C.Uid),0) [maxUid] from conversation A
    inner join message B on A.conversationId=B.conversationId
    inner join messageMail C on C.messageId=B.MessageId
    where inboundId=@inboundId and mailInbound=@mailACD
end
else if @action = 20 begin
    if @messageId is null begin
        select @ids=COALESCE(@ids + '','', '''') + cast(messageId as varchar(max))  from message where conversationId=@conversationId
        select @inboundId=inboundId from conversation where conversationId=@conversationId
        select @ids as ids,@inboundId as inboundId
    end
    else begin
        select case when count(*)>0 then 1 else 0 end  from attached where messageId=@messageId
    end
end
else if @action = 21 begin
    declare @isFinished bit
    set @isFinished = 0

    select @isFinished=isFinished from conversation where conversationId=@conversationId
    select @isFinished
end

else if @action = 22 begin
   
   declare @correo varchar(255)
   select  @correo = mailClient from conversation where conversationId = @conversationId      
   
   insert into emailSpam (inboundId,agentId,conversationId,correo,fecha) values (@inboundId,@userId,@conversationId,@correo,getDate())   

   update Conversation set isFinished = 1 where mailClient = @correo
   update message set messageStatusId = 13 where messageId = @messageId

   select distinct conversationId as ConversationId,inboundId as AcdId from emailSpam where correo = @correo

end

else if @action = 23 begin      
   if exists (select  * from emailSpam where correo like ''%''+@email+''%'') begin
        select 1
   end
   else begin
        select 0 
   end
end

else if @action = 24 begin      
	select count(*) as [Amount] from attached A inner join message B on A.messageId=B.messageId 
	where A.messageId = @messageId and isEmbedded = 1
end

else if @action = 25 begin      
	select pathFile as NameFile from attached A inner join message B on A.messageId=B.messageId 
	where A.messageId = @messageId and contentId = @contentId and isEmbedded = 1
end

else if @action = 26 begin      -- Discard Email
	update conversation set isFinished = 1 where conversationId = @conversationId
	update message set messageStatusId = 14, userId = @userId where messageId = @messageId
end

END'
		exec (@sql)

		set @process = 'CW-4088 No procesa agentes con id 0'
		set @Sql= 'ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization] 
@action SMALLINT, 
@maxRecordsToTransfer INT = 10, 
@id INT = 0
AS
SET NOCOUNT ON

IF @action = 1
BEGIN
	DECLARE @countrId INT

	SET @countrId = 1

	SELECT @countrId = valor
	FROM ccSettings
	WHERE setting_id = 104
	

	SELECT TOP (@maxRecordsToTransfer) call.cal_id, user_id, call.Inbound_id, call.calif_id, cast(cal_extension AS INT) AS cal_extension, cal_inicio, cal_ANI AS phone, 
	cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration, cal_key, 0 AS cal_manual, cal_puerto, call.dni_id, fvalida, 
	cal_whohung, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id, 
	CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh, 
	dateadd(ss, cal_tDialog, cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, ccInbound.prefijo, 1 AS isCallRecord,isnull(dni.dni_numero,'''') as DNIS
	FROM ccCallsIn AS call
	INNER JOIN ccInbound ON ccInbound.Inbound_id = call.Inbound_id
	INNER JOIN ccAVRSTransfer avrs ON call.cal_id = avrs.cal_id AND avrs.tipo = 0
	LEFT JOIN ccDNIS dni on dni.dni_id=call.dni_id
	LEFT JOIN (
		SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
		FROM ccLogTransfers
		WHERE tipo = 1
		GROUP BY cal_id, tipo
		) trans ON call.cal_id = trans.cal_id
	where call.User_id>0
	
	UNION
	
	SELECT TOP (@maxRecordsToTransfer) call.cal_id AS CallId, user_id AS UserId, call.cam_id AS camAcdId, cast(call.calif_id AS SMALLINT) AS califId, cast(cal_extension AS INT) AS extension, 
	cal_inicio, cal_telefono, cal_tDialog - cal_tMoh + CASE WHEN stopRecording = 0 THEN isnull(trans.tDespuesXfer, 0) ELSE 0 END AS duration, cal_key, cal_manual, cal_puerto, 0 AS dni_id, fvalida, 
	cal_whohung, isnull(cast(califSub_id AS SMALLINT), 0) AS califSub_id, 
	CASE WHEN trans.tAntesXfer IS NULL THEN cal_tMoh WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 ELSE cal_tMoh - trans.tAntesXfer END AS cal_tMoh, 
	dateadd(ss, cal_tDialog, cal_inicio) dateEnd, avrs.tipo + 1 AS callType, avrs.id AS avrsId, camps.prefijo, dbo.EnableCallRecord(camps.call_record, @countrId, cal_telefono) AS isCallRecord, '''' as DNIS
	FROM ccoCallsOut AS call
	INNER JOIN ccCamps camps ON camps.cam_id = call.cam_id
	INNER JOIN ccAVRSTransfer avrs ON call.cal_id = avrs.cal_id AND avrs.tipo = 1
	LEFT JOIN (
		SELECT cal_id, tipo, sum(tAntesXfer) AS tAntesXfer, sum(tDespuesXfer) AS tDespuesXfer
		FROM ccLogTransfers
		WHERE tipo = 2
		GROUP BY cal_id, tipo
		) trans ON call.cal_id = trans.cal_id
   where call.User_id>0
END
ELSE IF @action = 2
BEGIN
	DELETE
	FROM ccAVRSTransfer
	WHERE id = @id
END

'
		exec (@sql)
		

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		-- exec ccsp_getVersion 'BD', @version
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
