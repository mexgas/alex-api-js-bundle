/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K053000

Database: CCenterRia
Required version: 125.37

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
SET @version = 125 --**********actualizar a 124 sin fix
SET @versionfix = 39
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validacion para cuando pasamos a una nueva version LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
	SET @actualVersionFix = 0
	select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion and @versionfix >= @actualVersionFix 
BEGIN
	BEGIN TRAN
	BEGIN TRY

	---------------------------------------BEGIN Marco Garcia (CW8142 Error No hace la carga de Listas Negras)---------------------------------------------------------

	SET @process = 'CW-8142 Error No hace la carga de Listas Negras'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_InsertDNCListSms'')
		BEGIN
			DROP PROCEDURE ccsp_InsertDNCListSms
		END'
EXEC(@sql)

SET @process = 'CW-8142 Error No hace la carga de Listas Negras create store procedure [ccsp_InsertDNCListSms]'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_InsertDNCListSms]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL

AS
SET NOCOUNT ON;  


declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)
,@tel10 as varchar(30),@tel11 as varchar(30)

IF(@calKey IS NULL)
BEGIN
	if not exists(select * from ccListaNegra with(nolock) where telefono=@telephone and idtipolista=@ln_id 
	and HashKey IS NULL and calKey IS NULL) begin
		INSERT into cclistanegra(telefono,idtipolista,HashKey, calKey) values(@telephone, @ln_id,@hashCalKey, @calKey)
	END
END
ELSE 
BEGIN
	if not exists(select * from ccListaNegra with(nolock) where telefono=@telephone and idtipolista=@ln_id 
	and HashKey=@hashCalKey and calKey=@calKey) begin
		INSERT into cclistanegra(telefono,idtipolista,HashKey, calKey) values(@telephone, @ln_id,@hashCalKey, @calKey)
	END
END


IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempSms'') IS NOT NULL drop table #myprincipaltempSms
IF OBJECT_ID(N''tempdb..#mytempSms'') IS NOT NULL drop table #mytempSms


CREATE TABLE [dbo].[#mycamps] ([campsid] [int] NULL	)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id And B.CampType=7



CREATE TABLE [dbo].[#myprincipaltempSms](
	[smsout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[sms_phoneNumber] [varchar] (15) NULL ,
	[sms_phoneNumber2] [varchar] (15) NULL ,
	[sms_phoneNumber3] [varchar] (15) NULL ,
	[sms_phoneNumber4] [varchar] (15) NULL ,
	[sms_phoneNumber5] [varchar] (15) NULL
	)

CREATE CLUSTERED INDEX [IX_myprincipaltempSms] ON [dbo].[#myprincipaltempSms]([smsout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms2] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms3] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms4] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms5] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltempSms6] ON [dbo].[#myprincipaltempSms]([sms_phoneNumber5]) 

CREATE TABLE [dbo].[#mytempSms](
	[smsout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempSms]([smsout_id]) 

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17
select @tel = dbo.completa(@telephone, @pais, @ld)

set @tel10=RIGHT(@tel,10)
set @tel11=RIGHT(@tel,11)

declare @fech datetime = getdate()-30
if @hashCalKey is not null and @hashCalKey > 0
begin
	insert into [#myprincipaltempSms] 
	SELECT a.smsout_id as smsout_id, a.cam_id,3,@ln_id as idtipolista , a.sms_phoneNumber , a.sms_phoneNumber2, a.sms_phoneNumber3, a.sms_phoneNumber4, a.sms_phoneNumber5 
	FROM [smsOutSource] as a
	inner join #mycamps as b with(nolock) on a.cam_id = b.campsid
	WHERE dbo.hashList(callkey) = @hashCalKey and  sms_dateDial > @fech  
end
else begin	
	insert into [#myprincipaltempSms]
	SELECT a.smsout_id as smsout_id, a.cam_id,3,@ln_id  as idtipolista ,  a.sms_phoneNumber , a.sms_phoneNumber2, a.sms_phoneNumber3, a.sms_phoneNumber4, a.sms_phoneNumber5 
	FROM [smsOutSource] as a
	inner join #mycamps as b with(nolock) on a.cam_id = b.campsid	
	WHERE 
	(@tel  IN (sms_phoneNumber , sms_phoneNumber2, sms_phoneNumber3, sms_phoneNumber4, sms_phoneNumber5) 
	or @tel10 IN (sms_phoneNumber , sms_phoneNumber2, sms_phoneNumber3, sms_phoneNumber4, sms_phoneNumber5) 
	or @tel11 IN (sms_phoneNumber , sms_phoneNumber2, sms_phoneNumber3, sms_phoneNumber4, sms_phoneNumber5)) 
	and  sms_dateDial > @fech
end

if EXISTS (select * from #myprincipaltempSms)
	begin
	
	declare @column nvarchar(max), @sql nvarchar(max)
	,@sqlDeleteWorking nvarchar(max)
	,@sqlUpdateWorking nvarchar(max)
	,@sqlCaseWorking nvarchar(max)
	,@params nvarchar(max)
	,@phoneEmpty varchar(1)
	,@sqlWithReplace nvarchar(max)

	set @phoneEmpty=''''
	set @column=''sms_phoneNumber''
	set @params=''@tel varchar(30),@tel10 varchar(30),@tel11 varchar(30),@phoneEmpty varchar(1),@fech datetime''
	set @sqlDeleteWorking=''and cs.sms_phoneNumber2=@phoneEmpty
	and cs.sms_phoneNumber3=@phoneEmpty
	and cs.sms_phoneNumber4=@phoneEmpty
	and cs.sms_phoneNumber5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.sms_phoneNumber2<>@phoneEmpty then cs.sms_phoneNumber2 
	when cs.sms_phoneNumber3<>@phoneEmpty then cs.sms_phoneNumber3 
	when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
	when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
	else @phoneEmpty end ''

	set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
	update wt 
	set sms_phoneNumber = CASE_UPDATE_WT
	from smsOutSource cs 
	inner join smsWorkingTable wt on cs.smsout_id = wt.smsout_id
	inner join #mytempSms t on cs.smsout_id = t.smsout_id
	where cs.sms_dateDial > @fech and cs.COLUMN_CHECK= wt.sms_phoneNumber''

	set @sql=''insert #mytempSms
select smsout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempSms] with(nolock)
where COLUMN_CHECK in(@tel,@tel10,@tel11)

if EXISTS (select * from #mytempSms)
begin
	-- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
	delete wt with(rowlock)
	from smsWorkingTable wt 
	inner join smsOutSource cs on wt.smsout_id = cs.smsout_id
	inner join #mytempSms t on wt.smsout_id = t.smsout_id
	where cs.sms_dateDial > @fech and
	cs.COLUMN_CHECK = wt.sms_phoneNumber
	AND_DELETE_WT

	UPDATE_SMS_WT_QUERY

	--insertar el historial
	insert ccHistoryBlacklistSms (smsout_id,Phone,cam_id,movTypeId,listTypeId)
	select * from #mytempSms

	-- Eliminamos el telefono1 de CS
	update smsOutSource 
	set COLUMN_CHECK = @phoneEmpty
	from smsOutSource cs 
	inner join #mytempSms t on cs.smsout_id = t.smsout_id
	where cs.sms_dateDial > @fech		

	truncate table #mytempSms
end''
	/******************/
	/*** Telefono 1 ***/
	/******************/
	
	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech	

	/******************/
	/*** Telefono 2 ***/
	/******************/
	set @column=''sms_phoneNumber2''
	
	set @sqlDeleteWorking='' and cs.sms_phoneNumber3=@phoneEmpty
		and cs.sms_phoneNumber4=@phoneEmpty
		and cs.sms_phoneNumber5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.sms_phoneNumber3<>@phoneEmpty then cs.sms_phoneNumber3 
		when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
		when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech

	/******************/
	/*** Telefono 3 ***/
	/******************/
	set @column=''sms_phoneNumber3''
	
	set @sqlDeleteWorking='' and cs.sms_phoneNumber4=@phoneEmpty
		and cs.sms_phoneNumber5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
		when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech	

	/******************/
	/*** Telefono 4 ***/
	/******************/	
	
	set @column=''sms_phoneNumber4''
	
	set @sqlDeleteWorking='' and cs.sms_phoneNumber4=@phoneEmpty
		and cs.sms_phoneNumber5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.sms_phoneNumber4<>@phoneEmpty then cs.sms_phoneNumber4 
		when cs.sms_phoneNumber5<>@phoneEmpty then cs.sms_phoneNumber5 
		else @phoneEmpty end ''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',@sqlUpdateWorking),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech
		

	/******************/
	/*** Telefono 5 ***/
	/******************/

	set @column=''sms_phoneNumber5''	
	set @sqlDeleteWorking='' and cs.sms_phoneNumber5=@phoneEmpty''	
	set @sqlCaseWorking=''''

	set @sqlWithReplace=	
	Replace(		
	REPLACE(
	REPLACE(
		REPLACE(@sql,''UPDATE_SMS_WT_QUERY'',''''),
		''COLUMN_CHECK'',@column)
		,''AND_DELETE_WT'',@sqlDeleteWorking)
		,''CASE_UPDATE_WT'',@sqlCaseWorking
		)
	--print(@sqlWithReplace)
	exec sp_executesql @sqlWithReplace, @params, @tel,@tel10,@tel11,@phoneEmpty,@fech
	
end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempSms'') IS NOT NULL drop table #myprincipaltempSms
IF OBJECT_ID(N''tempdb..#mytempSms'') IS NOT NULL drop table #mytempSms'

			EXEC(@sql)

	---------------------------------------END Marco Garcia (CW8142 Error No hace la carga de Listas Negras)------------------------------------------------------------
	
	/* End script release */
	/* Upgrade database version (first and the last number of setting 77) */
	EXEC ccsp_getVersion 'BD', @version --- Update first number (Version)
	EXEC ccsp_getVersion 'BDF', @versionFix --- Update last number (FIX)

	COMMIT TRAN
	END TRY

	BEGIN CATCH
		/* Error generated based on sintax */
		SELECT @errorGenerated = 'DB script version: ' + cast(@version AS NVARCHAR) + '''.''' + cast(@versionfix AS NVARCHAR) + ''' Error process: ''' + @process + ''' Line: ''' + cast(error_line() AS NVARCHAR) + ''' Number: ''' + cast(@@error AS NVARCHAR) + ''' Message: ''' + error_message()

		RAISERROR (@errorGenerated, 11, 1)

		ROLLBACK TRAN
	END CATCH
END