/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/

/*
Author: 
		
Date: 2018/05/15
Description:

Database: CCenterRia
Required version: 120.14

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
set @version = 118  y  ccsp_getVersion ''BD'' se utilizara para cambiar de 117 a 118 en caso de que se tenga la version 119 y se vaya a agragar un fix
sera necesario poner solo el fix es decir @version = 01 y ccsp_getVersion ''BDF'' se tendra que tener cuidado con las versiones ya que */

set @version = 120--**********actualizar a 119 sin fix
set @versionfix = 22
--select * from ccsettings where setting_id=77
--
/* Actual version (use your own script to do it)*/
exec @actualVersion = ccsp_getVersion 'BD'
exec @actualVersionFix = ccsp_getVersion 'BDF'

select @versionALL = valor from ccsettings where setting_id=77;
select @actualVersionFix=cast(isnull(max(value),'0') as int) from dbo.fn_RIASplitDelimited(@versionALL,'.') where id=4;

if  @actualVersion = @version and  @actualVersionFix >= 14
	begin
		begin tran
		begin try

		set @process = 'CW-2022 -- VERSION 120.14 Alter SP ccsp_RIAvoiceMail '
		set @Sql= 'ALTER procedure [dbo].[ccsp_RIAvoiceMail]
@type as tinyint,
@msgId int=null,
@bSent int=null,
@mailType int = 0 -- Other=0; ChatMailAdmin=1; ChatMailClient=2
as
set nocount on
if @type=1 -- getSettings
 begin
	declare @SMTP_setting varchar(255)
	declare @svr as varchar(50), @usr as varchar(50), @pwd as varchar(50), @ssl as bit, @typeSend as bit
	declare @smtpPort as integer

	select @SMTP_setting=valor from ccsettings where setting_id=98
	select @svr = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 1
	select @usr = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 2
	select @pwd = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 3	
	select @smtpPort = cast(value as integer) from  dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 4
	select @ssl = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 5
	select @typeSend = value from dbo.fn_RIASplitDelimited(@SMTP_setting, ''|'') where id = 6
	if isnull(@smtpPort,0)=0 set @smtpPort=25
	if isnull(@ssl,0)=0 set @ssl=0
	if isnull(@typeSend,0)=0 set @typeSend=0
	
	select isNull(@svr,'''')  as svr, isNull(@usr,'''') as usr, isNull(@pwd,'''') as pwd, @smtpPort as smtpPt, @ssl as [ssl], @typeSend as [typeSend]
	return(0)
 end

else if @type=2 begin-- getMailBoxes 
	if isnull(@msgId,0)=0
	 begin
		raiserror(''Missing msgId'', 18, 1)
		return(0)
	 end

	declare @inbound_id int, @calid int, @acdName varchar(50)

	if @mailType = 0 begin
		select @calid=cal_id from ccRIA_vmMessages where vmID=@msgId
		select @inbound_id=inbound_id from ccCallsIn where cal_id=@calid
	end
	else begin
		select @calid=chatId from ccRIAChatMailbox where ID=@msgId
		select @inbound_id=inboundId from ccRIAChats where chatId=@calid
	end
	
	select @acdName = descripcion from ccInbound where Inbound_id = @inbound_id
	
	if @mailType = 2 begin
		select '''', @acdName as acdName
		return(0)
	end

	select mailbox, @acdName as acdName from ccRIA_vmMailBoxes M join ccRIA_vmACDMailBoxes A on M.vmID = A.vmID
	where A.inbound_id in (0,@inbound_id)
	return(0)
 end

else if @type=3 begin-- getNext
 
 declare @mailBySend table(
	idm int,
	nameFile varchar(256),
	[type] int,
	Inbound_id int,
	acdName varchar(100)
	)

	insert into @mailBySend
	select top 30  * from (
	select vmID, archivo, 1 as [type],C.Inbound_id,ISNULL(I.descripcion,'''') as acdName from ccRIA_vmMessages M
	inner join ccCallsIn C on M.cal_id=C.cal_id
	left join ccInbound I on C.Inbound_id=I.Inbound_id
	where vmStatus=0  
	union
	select M.ID, M.[file] as [file],2 as [type],C.inboundId,ISNULL(I.descripcion,'''') as acdName   from ccRIAChatMailbox M
	inner join ccRIAChats C on M.chatID=C.chatID
	left join ccInbound I on C.inboundId=I.Inbound_id
	where M.[status] = 0 
	)x
	where 
	Inbound_id in(

	select distinct A.inbound_id  from ccRIA_vmMailBoxes M 
	inner join ccRIA_vmACDMailBoxes A on M.vmID = A.vmID 
	)

	

	update A set vmintentos=vmintentos+1 from ccRIA_vmMessages A 
	inner join @mailBySend B on A.vmID=B.idm and B.type=1

	update A set tries=tries+1 from ccRIAChatMailbox A 
	inner join @mailBySend B on A.ID=B.idm and B.type=2
	
	select * from @mailBySend

	return(0)
 end

else if @type=4 begin-- setResult 
	if @bSent is null or isnull(@msgId,0)=0
	 begin
		raiserror(''Missing data'', 18, 1)
		return(0)
	 end

 	if @bSent=1  begin
		if @mailType = 0 begin
			update ccRIA_vmMessages set vmStatus=1 where vmID=@msgId			
		end
		else begin
			update ccRIAChatMailbox set [status] = 1 where ID = @msgId						
		end
		return(0)
	 end

	if @mailType = 0  begin
		update ccRIA_vmMessages set vmStatus=case when vmintentos<10 then vmStatus else 2 end where vmID=@msgId 
	end
	else begin
		update ccRIAChatMailbox set [status]=case when tries<10 then [status] else 2 end where ID=@msgId 
	end		
	return(0)	
	
	
 end
else if @type=5  begin-- reset vmintentos
	if @mailType = 0 begin
		update ccRIA_vmMessages set vmintentos=case when vmintentos>1 then vmintentos-1 else 0 end where vmID=@msgId		
	end
	else begin
		update ccRIAChatMailbox set tries=case when tries>1 then tries-1 else 0 end where [ID]=@msgId		
	end
 end'
		EXEC(@Sql)
				
		/* End script release */

		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
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
