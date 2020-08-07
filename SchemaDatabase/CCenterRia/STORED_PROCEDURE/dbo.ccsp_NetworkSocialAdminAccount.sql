CREATE PROCEDURE [dbo].[ccsp_NetworkSocialAdminAccount]
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
				select 0, 'Error: acount already exists'
				return -1
			end
			if not exists(select * from ContactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId) begin
			if @name is null set @name=''
				--if @conexionInfo is null set @conexionInfo=''
				if @connUser is null set @connUser=''
				if @connPass is null set @connPass=''
				if @numMessages is null set @numMessages=3
				if @timeAlertMessage is null set @timeAlertMessage=5
				if @isActive is null set @isActive=0
				if @answerTimeOut is null set @answerTimeOut=0
				if @closeConversationTime is null set @closeConversationTime=3

				--Twitter deja los token
				--conexion Info usuarioID|token|tokenSecret|time|daysTwitterRecord
				if @meanContactTypeId= 2 begin

					if @conexionInfo is null begin
						set @conexionInfo='usuarioID|token|tokenSecret'
						set @revisionTime=isnull(@revisionTime,'1')
						set @daysTwitterRecord=isnull(@daysTwitterRecord,'0')
					end
					else begin
						insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,'|')
						set @conexionInfo=null

						SELECT @conexionInfo= COALESCE(@conexionInfo + '|', '') + value FROM @tableConexionInfo where id<4

						SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),'1')) FROM @tableConexionInfo where id=4
						SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),'0')) FROM @tableConexionInfo where id=5
						SELECT @closeConversationTime=  isnull(@closeConversationTime,isnull(max(value),'3')) FROM @tableConexionInfo where id=6
					end
					set @conexionInfo=@conexionInfo+'|'+@revisionTime+'|'+@daysTwitterRecord
				end


				insert into ContactMeanIn (meanContactTypeId,name,conexionInfo,inboundId,connUser,ConnPass,numMessages,timeAlertMessage,isActive,answerTimeOut,closeConversationTime)
						values (@meanContactTypeId,@name,@conexionInfo,@inboundId,@connUser,@connPass,@numMessages,@timeAlertMessage,@isActive,@answerTimeOut,@closeConversationTime)
				select 1,'insert'
			end
			else begin
				select @conexionInfo = isnull(@conexionInfo,conexionInfo),@connUser= isnull(@connUser,connUser),@connPass= isnull(@connPass,ConnPass),
						@numMessages= isnull(@numMessages,numMessages),@timeAlertMessage= isnull(@timeAlertMessage,timeAlertMessage),@isActive= isnull(@isActive,isActive),
						@answerTimeOut= isnull(@answerTimeOut,answerTimeOut),@name=isnull(@name,name),@closeConversationTime=isnull(@closeConversationTime,closeConversationTime)
						from ContactMeanIn where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId

				--Twitter deja los token
				if @meanContactTypeId= 2 begin
					--usuarioID|token|tokenSecret|time|daysTwitterRecord|closeConversation
					insert into @tableConexionInfo  select * from dbo.fn_RIASplitDelimited(@conexionInfo,'|')
					set @conexionInfo=null

					SELECT @conexionInfo= COALESCE(@conexionInfo + '|', '') + value FROM @tableConexionInfo where id<4

					SELECT @revisionTime=  isnull(@revisionTime,isnull(max(value),'1')) FROM @tableConexionInfo where id=4
					SELECT @daysTwitterRecord=  isnull(@daysTwitterRecord,isnull(max(value),'0')) FROM @tableConexionInfo where id=5

					set @conexionInfo=@conexionInfo+'|'+@revisionTime+'|'+@daysTwitterRecord
				end



				update ContactMeanIn set name=@name,conexionInfo=@conexionInfo,connUser=@connUser,ConnPass=@connPass,
					numMessages=@numMessages,timeAlertMessage=@timeAlertMessage,isActive=@isActive,answerTimeOut=@answerTimeOut,
					closeConversationTime=@closeConversationTime
					where inboundId = @inboundId and meanContactTypeId=@meanContactTypeId
				select 1,'update'
			end
		end
		else if @action = 2 begin
			if @inboundId=0
				select cast(A.inboundId as smallint) as Id, A.conexionInfo as Credentials, A.connUser as AccountName, 
				A.ConnPass as Password, A.isActive as IsActive, A.name as Username from contactMeanIn A
				inner join ccInbound B on A.inboundId=B.Inbound_id
				and B.chat = case when A.meanContactTypeId=1 then 3 when A.meanContactTypeId=2 then 4 else -1 end
				where meanContactTypeId=@meanContactTypeId and isActive=1
			else
				select cast(A.inboundId as smallint) as Id, A.conexionInfo as Credentials, A.connUser as AccountName, 
				A.ConnPass as Password, A.isActive as IsActive, A.name as Username from contactMeanIn A
				inner join ccInbound B on A.inboundId=B.Inbound_id
				and B.chat = case when A.meanContactTypeId=1 then 3 when A.meanContactTypeId=2 then 4 else -1 end

				where meanContactTypeId=@meanContactTypeId and isActive=1 and inboundId=@inboundId
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
			select isnull(max(conexionInfo),'usuarioID|token|tokenSecret|1|0') from contactMeanIn where inboundId=@inboundId and meanContactTypeId=@meanContactTypeId
		end
		END