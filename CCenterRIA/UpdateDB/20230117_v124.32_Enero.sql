/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124.25

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
SET @version = 124 --**********actualizar a 123 sin fix
SET @versionfix = 32
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version and @actualVersionFix >= @versionfix - 1
BEGIN
	BEGIN TRAN

	BEGIN TRY

	/**---------------------------------- BEGIN K029000 MARCO GARCIA - MARCO CHAGOLLA ----------------------------------------------------------*/
	SET @process = 'K029000-Configuración de buzón de voz delete procedure ccsp_RIACATvoiceMail'
	SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIACATvoiceMail'')
		BEGIN
			DROP PROCEDURE ccsp_RIACATvoiceMail;
		END';
	EXEC(@sql);

	SET @process = 'K029000-Configuración de buzón de voz create procedure ccsp_RIACATvoiceMail'
	SET @sql = '
	CREATE PROCEDURE [dbo].[ccsp_RIACATvoiceMail]
	@type TINYINT,
	@user_id SMALLINT,
	@ACDvm_id VARCHAR(1000)=NULL,
	@vmID VARCHAR(1000)=NULL,
	@mailbox VARCHAR(50)=NULL,
	@inbound_id SMALLINT=NULL,
	@isKolob BIT=0
	AS
	SET NOCOUNT ON
	DECLARE @IDarea SMALLINT;

	SELECT @IDarea=IDarea FROM ccUsers WHERE user_id=@user_id

	IF ISNULL(@IDarea,'''')=''''
	 BEGIN
		SELECT -1, ''invalid user area''
		RETURN(0)
	 END

	IF @type=1 -- Get acd catalog
	 BEGIN
	 IF(@isKolob = 1)
		BEGIN
			SELECT Inbound_id, descripcion from ccInbound where IDArea=@IDArea AND chat = 0 order by descripcion
		END
		ELSE
		BEGIN
			SELECT Inbound_id, descripcion from ccInbound where IDArea=@IDArea order by descripcion
		END
		return(0)
	 end

	if @type=2 -- Get mail vs inbound_id relationship by inbound_id
	 begin
		select r.ACDvm_id, m.mailbox, m.vmID, m.IDArea, r.inbound_id
		from ccRIA_vmMailBoxes m join ccRIA_vmACDMailBoxes r on m.vmID=r.vmID
		where r.inbound_id=@inbound_id and m.IDArea=@IDarea order by m.mailbox
		return(0)
	 end

	if @type=3 -- Get email catalog by user area
	 begin
		select vmID, mailbox, IDArea from ccRIA_vmMailBoxes where IDArea=@IDarea
		return(0)
	 end

	if @type=4 -- add mail vs inbound_id relationship
	 BEGIN
		if not exists(select vmID from ccRIA_vmMailBoxes where IDArea=@IDArea and vmID in (select value from dbo.fn_RIASplitDelimited(@vmID, '',''))) 
		 begin
			select CAST(-5 AS INT) --, ''invalid mailbox id''
			return(0)
		 end

		if not exists(select inbound_id from ccInbound where inbound_id=@inbound_id and IDArea=@IDArea)
		 begin
			select CAST(-3 AS INT) --, ''invalid inbound_id''
			return(0)
		 end

		if not exists(select ACDvm_id from ccRIA_vmACDMailBoxes where inbound_id=@inbound_id and vmID in (select value from dbo.fn_RIASplitDelimited(@vmID, '','')))
			insert ccRIA_vmACDMailBoxes (vmID, inbound_id) 
			select vmID, @inbound_id from ccRIA_vmMailBoxes where IDArea=@IDArea and vmID in (select value from dbo.fn_RIASplitDelimited(@vmID, '','')) and
			cast(vmID as char(5))+''-''+cast(@inbound_id as char(5)) not in (select cast(vmID as char(5))+''-''+cast(inbound_id as char(5)) from ccRIA_vmACDMailBoxes)
			select CAST(1 AS INT) -- isnull(SCOPE_IDENTITY(), -7), ''relation exists''
		return(0)
	 end

	if @type=5 -- del mail vs inbound_id relationship
	 begin
 		if not exists(select ACDvm_id from ccRIA_vmACDMailBoxes where ACDvm_id in (select value from dbo.fn_RIASplitDelimited(@ACDvm_id, '','')))
		 begin
			select CAST(-4 AS INT) --, ''invalid relationship''
			return(0)
		 end

		select top 1 @inbound_id = inbound_id from ccRIA_vmACDMailBoxes where ACDvm_id in (select value from dbo.fn_RIASplitDelimited(@ACDvm_id, '',''))
		delete ccRIA_vmACDMailBoxes where ACDvm_id in (select value from dbo.fn_RIASplitDelimited(@ACDvm_id, '',''))
		select CAST(@inbound_id AS INT)
 		return(0)
	 end

	if @type=6 -- Insert email into catalog
	 begin
		if len(replace(isnull(@mailbox,''''),'' '',''''))<10
		 begin
			select CAST(-2 AS int)--, ''invalid mailbox adress''
			return(0)
		 end

		if not exists (select mailbox from ccRIA_vmMailBoxes where mailbox=@mailbox and @IDArea=IDArea)
			insert ccRIA_vmMailBoxes (mailbox, IDarea) select @mailbox, @IDarea

		select CAST(isnull(SCOPE_IDENTITY(),-6) AS int)--, ''mailbox exists''
		return(0)
	 end

	if @type=7 -- update mail
	 begin
		if not exists(select mailbox from ccRIA_vmMailBoxes where vmID=@vmID and IDArea=@IDArea) 
		 begin
			select CAST(-5 AS int)--, ''invalid mailbox id''
			return(0)
		 end

		if len(replace(isnull(@mailbox,''''),'' '',''''))<10 
		 begin
			select CAST(-2 AS int)--, ''invalid mailbox adress''
			return(0)
		 end

		if exists(select mailbox from ccRIA_vmMailBoxes where mailbox=@mailbox and IDArea=@IDArea and vmID<>@vmID) 
		 begin
			select CAST(-6 AS int)
			return(0)
		 end

	
		if(@isKolob = 1)
		begin
			update ccRIA_vmMailBoxes set mailbox=@mailbox where vmID=@vmID
			select CAST(@vmID AS int)
		end
		else
		begin
			update ccRIA_vmMailBoxes set mailbox=@mailbox where vmID=@vmID
		end
		return(0)
	 end

	if @type=8 -- check mail references
	 begin
		if exists(select ACDvm_id from ccRIA_vmACDMailBoxes where vmID in (select vmID from ccRIA_vmMailBoxes where vmID=@vmID and IDArea=@IDArea))
			select -8, ''mail with active relationships''	
		return(0)
	 end

	if @type=9 -- del mail
	 BEGIN
		if not exists(select mailbox from ccRIA_vmMailBoxes where vmID IN (select value from dbo.fn_RIASplitDelimited(@vmID, '','')) and IDArea=@IDArea) 
		 BEGIN
			IF (@iskolob = 1) 
			BEGIN
				SELECT ''-5'' --, ''invalid mailbox id'' ; 
			END
			ELSE
			BEGIN
				SELECT CAST(-5 AS INT) --, ''invalid mailbox id'' 
			END
		 end

		IF EXISTS(SELECT crvamb.inbound_id FROM dbo.ccRIA_vmACDMailBoxes AS crvamb INNER JOIN dbo.ccRIA_vmMailBoxes AS crvmb
		ON crvmb.vmID = crvamb.vmID WHERE crvamb.vmID IN (select value from dbo.fn_RIASplitDelimited(@vmID, '',''))
		AND crvmb.IDArea = @IDArea
		GROUP BY crvamb.inbound_id)
		BEGIN

			SELECT @inbound_id = crvamb.inbound_id FROM dbo.ccRIA_vmACDMailBoxes AS crvamb INNER JOIN dbo.ccRIA_vmMailBoxes AS crvmb
			ON crvmb.vmID = crvamb.vmID WHERE crvamb.vmID IN (select value from dbo.fn_RIASplitDelimited(@vmID, '',''))
			AND crvmb.IDArea = @IDArea
			GROUP BY crvamb.inbound_id

			DELETE dbo.ccRIA_vmACDMailBoxes WHERE vmID IN (select value from dbo.fn_RIASplitDelimited(@vmID, '','')) AND inbound_id = @inbound_id
		END

		if(@isKolob = 1)
		begin
			DELETE ccRIA_vmMailBoxes where vmID IN (select value from dbo.fn_RIASplitDelimited(@vmID, '',''))
			select @vmID
		end
		else
		begin
			DELETE ccRIA_vmMailBoxes where vmID IN (select value from dbo.fn_RIASplitDelimited(@vmID, '',''))
		END
		return(0)
	 end

	set nocount off';

	EXEC(@sql);	

	/**---------------------------------- END K029000 MARCO GARCIA - MARCO CHAGOLLA ----------------------------------------------------------*/

		/* End script release */
		/* Upgrade database version (use your own script to do it) */
		--exec ccsp_getVersion 'BD', @version
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
