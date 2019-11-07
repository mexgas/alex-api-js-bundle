CREATE PROCEDURE [dbo].[trsp_AdmSaveMailConfigInfo]
	-- Add the parameters for the stored procedure here

@MailType as tinyint,
@Server as varchar(50),
@Port as int,
@User as varchar(50),
@Pass as varchar(50),
@MailFile as varchar(50),
@Domain as varchar(50),
@Ssl as varchar(50),
@Authentication as varchar(50),
@From as nvarchar(80),
@Display as nvarchar(250)

AS
BEGIN

	SET NOCOUNT ON;

Declare @count as smallint

set @count = (select count(*) from TREC_PARAMMAIL)


IF @count > 0 BEGIN

Update TREC_PARAMMAIL set MailType=@MailType,[Server]=@Server,Port=@Port,[User]=@User,
Pass=@Pass,MailFile=@MailFile,Domain=@Domain,Ssl=@Ssl,Authentication=@Authentication, [From] =@User, Display=@Display

Update TREC_PARAMETROS set par_valor = @Server where par_id = 6
Update TREC_PARAMETROS set par_valor = @Display where par_id = 24

END

ELSE BEGIN

Insert TREC_PARAMMAIL(MailType,[Server],Port,[User],Pass,MailFile,Domain,Ssl,Authentication,[From],Display) values
(@MailType,@Server,@Port,@User,@Pass,@MailFile,@Domain,@Ssl,@Authentication,@User,@Display)

Update TREC_PARAMETROS set par_valor = @Server where par_id = 6
Update TREC_PARAMETROS set par_valor = @Display where par_id = 24

END

END