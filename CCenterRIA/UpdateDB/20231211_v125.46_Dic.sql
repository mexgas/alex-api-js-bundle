/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2023/07/04
Description: K089000

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
SET @versionfix = 46
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

	    -----------------------------------------------------BEGIN K042023-Indicador de creditos Ivan Martin ----------------------------------------------------------------

        SET @process = 'K042023 Se crea setting 258 para creditos globales de SMS'
        SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 258)
                    BEGIN
                        INSERT INTO ccSettings2(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
                        VALUES(258, ''0'', ''Contador global de créditos para campañas SMS'', 1, ''ADM'', ''Contador global de créditos para campañas SMS'',
                                         ''SMS Campaigns credits global counter'',0,''.*'') 
                    END'
        EXEC(@sql);

        -----------------------------------------------------END K042023-Indicador de creditos Ivan Martin ----------------------------------------------------------------

        	    -----------------------------------------------------BEGIN fix JCL ----------------------------------------------------------------

        SET @process = 'fix historial de cambios identifier Idioma'
        SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccGalateaIdentifiers WHERE Description = ''T&SET_TOOLSTRANSFER'')
                    BEGIN
                        insert into ccGalateaIdentifiers(Description,TagEs,TagEn,TagPt)
                        values(''T&SET_TOOLSTRANSFER'', ''Mostrar datos del contacto y controles de llamada en transferencias'', ''Show contact’s data and call controls on transfers'', ''Exibir dados do contato e controles de chamada em transferências'')          
                    END'
        EXEC(@sql);

        SET @process = 'fix historial de cambios relacion identifier'
        SET @sql = 'IF NOT EXISTS(SELECT 1 FROM relationTableColumnIdentifiers WHERE Identifiers = ''T&SET_TOOLSTRANSFER'')
                    BEGIN
                        insert into relationTableColumnIdentifiers(Identifiers,tableName,colunName)
                        values(''T&SET_TOOLSTRANSFER'', ''ccRIACat_Areas'', ''ToolsTransfer'')
                    END'
        EXEC(@sql);
       

        -----------------------------------------------------END fix JCL ----------------------------------------------------------------

		-----------------------------------------------------INICIO MACL-----------------------------------------------------------------
		SET @process = 'CW-8197 Actualiza SP ccsp_RIADNCList'
        SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_RIADNCList] @phoneNumber AS VARCHAR(30) = NULL, @idDNCList AS INTEGER, @tipoMov AS TINYINT, @calKey AS VARCHAR(40) = NULL
AS
DECLARE @hashCalKey bigint, @hashPhone BIGINT

IF @calKey IS NOT NULL
BEGIN
	SELECT @hashCalKey = dbo.hashList(@calKey)
END

IF @tipoMov = 1
BEGIN -- Inserta Lista Negra	
	EXEC ccsp_InsertDNCList @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null
	EXEC ccsp_InsertDNCListSms @telephone = null, @ln_id = @idDNCList, @hashCalKey = null, @calKey = null
	
END

IF @tipoMov = 2
BEGIN -- Borra Lista Negra	
	SELECT @hashPhone = dbo.hashPhone(@phoneNumber)

	IF @hashCalKey IS NULL
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey IS NULL AND idtipolista = @idDNCList
	END
	ELSE
	BEGIN
		DELETE
		FROM cclistanegra
		WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idDNCList
	END

	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	VALUES (@phoneNumber, 5, @idDNCList)
END

IF @tipoMov = 3
BEGIN -- Reemplaza Lista Negra
	INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
	SELECT telefono, ''4'', @idDNCList
	FROM cclistanegra
	WHERE idtipolista = @idDNCList

	DELETE
	FROM cclistanegra
	WHERE idtipolista = @idDNCList
END '
        EXEC(@sql);

		SET @process = 'CW-8197 Actualiza SP ccsp_InsertDNCList'
        SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30)=null,
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL
WITH RECOMPILE
AS

PRINT(@ln_id)
declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)
,@tel10 as varchar(30),@tel11 as varchar(30), @sqlcmd varchar(max), @tmpTableName varchar(40), @sqlcmd_replace varchar(max),
@dropTmpPhone varchar(max) = null

SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));

if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificación
BEGIN
	IF EXISTS (SELECT * from ccListaNegra where idtipolista = @ln_id and telefono = @telephone and HashKey = dbo.hashList(@calKey))
		RETURN 0;

	IF @calKey = ''''
		SET @calKey = ''''''''''''
	ELSE
		SET @calKey = '''''''' + @calKey + ''''''''

	set @tmpTableName = ''TMP_BLACKLIST_'' + @telephone;
	SET @dropTmpPhone = ''if exists (select * from sys.tables where name = N'''''' + @tmpTableName + '''''') drop table '' + @tmpTableName;

	SET @sqlcmd = ''CREATE TABLE '' + @tmpTableName + ''(
	[phoneNumber] VARCHAR(30),
	[calKey] VARCHAR(40)); 

	INSERT INTO '' + @tmpTableName + ''(phoneNumber, calKey) values(''+ @telephone +'', '' + ISNULL(@calKey, ''NULL'') + '');
	'';
	EXEC (@dropTmpPhone);
	EXEC (@sqlcmd);
END


select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

SET @sqlcmd =  ''
UPDATE '' + @tmpTableName + '' SET phoneNumber = dbo.completa(phoneNumber, '' + @pais + '',  '' + @ld + '');
DELETE '' + @tmpTableName + '' WHERE phoneNumber like ''''%E%'''';

INSERT INTO cclistanegra(telefono,idtipolista,HashKey, calKey)
SELECT phoneNumber, '' + CAST(@ln_id as varchar(10)) + '' as idtipolista, dbo.hashList(calKey) as HashKey, calkey 
FROM '' + @tmpTableName + '';

INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
SELECT phoneNumber as telefono, 7 as idtipomov, '' + CAST(@ln_id as varchar(10)) + '' as idtipolista 
FROM '' + @tmpTableName + '';''
EXEC(@sqlcmd);

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall


CREATE TABLE [dbo].[#mycamps] (	[campsid] [int] NULL)

CREATE CLUSTERED INDEX [IX_mycamps] ON [dbo].[#mycamps]([campsid]) 

insert #mycamps
select A.cam_id from Camplistanegra A
Inner join ccCamps B on A.cam_id=B.cam_id
where A.idtipolista = @ln_id and B.CampType not in(7,5)


CREATE TABLE [dbo].[#myprincipaltempCall](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE CLUSTERED INDEX [IX_myprincipaltemp] ON [dbo].[#myprincipaltempCall]([callout_id]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp2] ON [dbo].[#myprincipaltempCall]([cal_telefono]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp3] ON [dbo].[#myprincipaltempCall]([cal_telefono2]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp4] ON [dbo].[#myprincipaltempCall]([cal_telefono3]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp5] ON [dbo].[#myprincipaltempCall]([cal_telefono4]) 
CREATE NONCLUSTERED INDEX [IX_myprincipaltemp6] ON [dbo].[#myprincipaltempCall]([cal_telefono5]) 

CREATE TABLE [dbo].[#helpTempCall](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

CREATE TABLE [dbo].[#mytempCall](
	[callout_id] [int] NULL, 
	[telefono] [varchar] (15) NULL ,
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL
)

CREATE CLUSTERED INDEX [IX_mytemp] ON [dbo].[#mytempCall]([callout_id]) 

declare @fech datetime = getdate()-30
	SET @sqlcmd = ''
	insert into [#helpTempCall]
	SELECT a.callout_id as callout_id, a.cam_id,3, '' +  CAST(@ln_id as varchar(10))+ ''  as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
	FROM [ccoCallsOutSource] as a with(nolock)
	inner join #mycamps as b  on a.cam_id = b.campsid
	inner join '' + @tmpTableName +'' t on 
	t.phoneNumber IN ([SPACE_TEL]) 	AND t.calKey IS NULL
	where  cal_fechadial > getdate()-30
	''

	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono'')
	exec (@sqlcmd_replace)
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono2'')
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono3'')
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono4'')
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono5'')
	EXEC(@sqlcmd_replace)


	SET @sqlcmd = ''insert into [#helpTempCall]
	SELECT a.callout_id as callout_id, a.cam_id,3, '' +  CAST(@ln_id as varchar(10))+ ''  as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
	FROM [ccoCallsOutSource] as a with(nolock)
	inner join #mycamps as b  on a.cam_id = b.campsid
	inner join '' + @tmpTableName +'' t on a.cal_Key=t.calKey
	where cal_fechadial > getdate()-30;
	'';
	print( @sqlcmd)
	EXEC(@sqlcmd)

	INSERT INTO #myprincipaltempCall
	SELECT * FROM #helpTempCall
	GROUP BY callout_id, cam_id, tipomov, idtipolista, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5

if EXISTS (select * from #myprincipaltempCall)
begin
	declare @column nvarchar(max), @sql nvarchar(max)
	,@sqlDeleteWorking nvarchar(max)
	,@sqlUpdateWorking nvarchar(max)
	,@sqlCaseWorking nvarchar(max)
	,@params nvarchar(max)
	,@phoneEmpty varchar(1)
	,@sqlWithReplace nvarchar(max)

	set @phoneEmpty=''''
	set @column=''cal_telefono''
	set @params=''@phoneEmpty varchar(1),@fech datetime''
	set @sqlDeleteWorking=''and cs.cal_telefono2=@phoneEmpty
	and cs.cal_telefono3=@phoneEmpty
	and cs.cal_telefono4=@phoneEmpty
	and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono2<>@phoneEmpty then cs.cal_telefono2 
	when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
	when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
	when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
	else @phoneEmpty end ''

	set @sqlUpdateWorking=''-- Actualizamos WT al siguiente telefono disponbile (cuando no es el unico telefono)
	update wt 
	set cal_telefono = CASE_UPDATE_WT
	from ccoCallsOutSource cs 
	inner join ccoWOrkingTable wt on cs.callout_id = wt.callout_id
	inner join #mytempCall t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > @fech and cs.COLUMN_CHECK= wt.cal_telefono''

	set @sql=''
insert #mytempCall
select callout_id,COLUMN_CHECK,cam_id,tipomov,idtipolista
from [#myprincipaltempCall] as a with(nolock)
inner join '' + @tmpTableName + '' t on
t.phoneNumber = COLUMN_CHECK
where COLUMN_CHECK<>@phoneEmpty


if EXISTS (select * from #mytempCall)
begin		
	-- Borramos de WT todos los registros en los que el telefono1 sea el unico telefono y este en la lista negra
	delete wt with(rowlock)
	from ccoWOrkingTable wt 
	inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
	inner join #mytempCall t on wt.callout_id = t.callout_id
	where cs.cal_fechadial > @fech and
	cs.COLUMN_CHECK = wt.cal_telefono
	AND_DELETE_WT

	UPDATE_SMS_WT_QUERY

	--insertar el historial
	insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
	select * from #mytempCall where [telefono]<>@phoneEmpty

	-- Eliminamos el telefono1 de CS
	update ccoCallsOutSource 
	set COLUMN_CHECK = @phoneEmpty
	from ccoCallsOutSource cs 
	inner join #mytempCall t on cs.callout_id = t.callout_id
	where cs.cal_fechadial > @fech		

	truncate table #mytempCall
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
	print(@sqlWithReplace)	
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	

	/******************/
	/*** Telefono 2 ***/
	/******************/
	set @column=''cal_telefono2''
	
	set @sqlDeleteWorking='' and cs.cal_telefono3=@phoneEmpty
		and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono3<>@phoneEmpty then cs.cal_telefono3 
		when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
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
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	

	/******************/
	/*** Telefono 3 ***/
	/******************/
	set @column=''cal_telefono3''
	
	set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
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
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	
	
	/******************/
	/*** Telefono 4 ***/
	/******************/	
	
	set @column=''cal_telefono4''
	
	set @sqlDeleteWorking='' and cs.cal_telefono4=@phoneEmpty
		and cs.cal_telefono5=@phoneEmpty''
	
	set @sqlCaseWorking='' case when cs.cal_telefono4<>@phoneEmpty then cs.cal_telefono4 
		when cs.cal_telefono5<>@phoneEmpty then cs.cal_telefono5 
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
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	
	
	/******************/
	/*** Telefono 5 ***/
	/******************/

	set @column=''cal_telefono5''	
	set @sqlDeleteWorking='' and cs.cal_telefono5=@phoneEmpty''	
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
	exec sp_executesql @sqlWithReplace, @params, @phoneEmpty,@fech	

end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall
IF @dropTmpPhone IS NOT NULL EXEC (@dropTmpPhone);'
        EXEC(@sql);

		SET @process = 'CW-8197 Actualiza SP ccsp_InsertDNCListSms'
        SET @sql = '
		ALTER PROCEDURE [dbo].[ccsp_InsertDNCListSms]
@telephone as varchar(30),
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL

AS
SET NOCOUNT ON;  


declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)
,@tel10 as varchar(30),@tel11 as varchar(30), @sqlcmd varchar(max), @tmpTableName varchar(40), @sqlcmd_replace varchar(max),
@dropTmpPhone varchar(max) = null

SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempSms'') IS NOT NULL drop table #myprincipaltempSms
IF OBJECT_ID(N''tempdb..#mytempSms'') IS NOT NULL drop table #mytempSms
IF OBJECT_ID(N''tempdb..#helpTempSms]'') IS NOT NULL drop table #helpTempSms


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

CREATE TABLE [dbo].[#helpTempSms](
	[callout_id] [int] NULL, 
	[cam_id] [smallint] NULL ,
	[tipomov] [int] NULL,
	[idtipolista] [int] NULL,
	[cal_telefono] [varchar] (15) NULL ,
	[cal_telefono2] [varchar] (15) NULL ,
	[cal_telefono3] [varchar] (15) NULL ,
	[cal_telefono4] [varchar] (15) NULL ,
	[cal_telefono5] [varchar] (15) NULL
	)

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

declare @fech datetime = getdate()-30

	SET @sqlcmd = ''
	insert into [#helpTempSms]
	SELECT a.smsout_id as smsout_id, a.cam_id,3, '' +  CAST(@ln_id as varchar(10))+ ''  as idtipolista ,  a.sms_phoneNumber , a.sms_phoneNumber2, a.sms_phoneNumber3, a.sms_phoneNumber4, a.sms_phoneNumber5 
	FROM [smsOutSource] as a 
	inner join #mycamps as b with(nolock) on a.cam_id = b.campsid
	inner join '' + @tmpTableName +'' t on 
	t.phoneNumber IN ([SPACE_TEL]) 	AND t.calKey IS NULL
	where  sms_dateDial > getdate()-30
	''

	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber'')
	exec (@sqlcmd_replace)
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber2'')
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber3'')
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber4'')
	EXEC(@sqlcmd_replace)
	SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''sms_phoneNumber5'')
	EXEC(@sqlcmd_replace)


	SET @sqlcmd = ''insert into [#helpTempSms]
	SELECT a.smsout_id as smsout_id, a.cam_id,3, '' +  CAST(@ln_id as varchar(10))+ ''  as idtipolista ,  a.sms_phoneNumber , a.sms_phoneNumber2, a.sms_phoneNumber3, a.sms_phoneNumber4, a.sms_phoneNumber5 
	FROM [smsOutSource] as a
	inner join #mycamps as b with(nolock) on a.cam_id = b.campsid
	inner join '' + @tmpTableName +'' t on a.callKey=t.calKey
	where sms_dateDial > getdate()-30;
	'';
	print( @sqlcmd)
	EXEC(@sqlcmd)

	INSERT INTO #myprincipaltempSms
	SELECT * FROM #helpTempSms
	GROUP BY callout_id, cam_id, tipomov, idtipolista, cal_telefono, cal_telefono2, cal_telefono3, cal_telefono4, cal_telefono5
	
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
	set @params=''@phoneEmpty varchar(1),@fech datetime''
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
inner join '' + @tmpTableName + '' t on
t.phoneNumber = COLUMN_CHECK
where COLUMN_CHECK<>@phoneEmpty

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
	exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech	

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
	exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech

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
	exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech	

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
	exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech
		

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
	exec sp_executesql @sqlWithReplace, @params,@phoneEmpty,@fech
	
end

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempSms'') IS NOT NULL drop table #myprincipaltempSms
IF OBJECT_ID(N''tempdb..#mytempSms'') IS NOT NULL drop table #mytempSms
IF OBJECT_ID(N''tempdb..#helpTempSms]'') IS NOT NULL drop table #helpTempSms
'
EXEC(@sql)
------------------------------------------------FIN MACL------------------------------------------------------

        -----------------------------------------------------BEGIN HOTFIX K042023-Indicador de creditos Ivan Martin ----------------------------------------------------------------
        SET @process = 'HOTFIX K042023 Se agrega columna Exception a la tabla de ccSmsConversationsResult'
        SET @sql = 'if not exists (select * from sys.columns where name = N''Exception'' and Object_ID = Object_ID(N''ccSmsConversationsResult''))
                    begin
                        alter table ccSmsConversationsResult add Exception int null
                    end'
        EXEC(@sql);

        SET @process = 'HOTFIX K042023 Se ponen valores en 0 de la nueva columna'
        SET @sql = 'UPDATE ccSmsConversationsResult set Exception=0 where Exception is null'

        EXEC(@sql);

        SET @process = 'HOTFIX K042023:
                        Se modifica action 1 para solo regresar campañas si tienen registros en nuevos. 
                        Se mejora accesos a ccSettings2.  Línea (1311).
                        Y se hace merge con sql anterior (no hubo diferencia mas que una linea que yo puse que ya no va). 
                        Se agrega estado 6 en linea 1364. 
                        Se agregan action 11 y 12.
                        Se agrega linea 1361
                        Se agrega estado de Exception en lugares correspondientes'

        SET @sql = 'ALTER procedure [dbo].[ccspOutboundSmsMessage] 
                        @action int,
                        @camId int = null,
                        @SentMsg int=null,
                        @smsoutIds varchar(max)=null,
                        @SystemApiId varchar(100)=null,
                        @statusSystemsId int =null,
                        @InsufficientBalance int=null,
                        @date datetime =null,
                        @IsCharged BIT = null,
                        @smsOutId INT = NULL
                        as
                        declare @sql varchar(max)
                        if @action=1 begin
                            select distinct cast(c. cam_id as int) as CamId,cam_descripcion as [Name],cam_procesando as [Start] 
                            from ccCamps c with(nolock)
                            left join ccCampsNvosCB w with(nolock) on c.cam_id = w.id
                            where CampType=7 and c.IDArea is not null and( @camId is null or c.cam_id=@camId) and w.new >0
    
                        end
                        else if @action=2 begin
                            select tz_offset from ccTimeZones ORDER BY tz_id
                        end
                        else if @action=3 begin
                            select cast(camId as int) CamId,SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected 
                            from ccSmsConversationsResult where ( @camId is null or camId=@camId)
                        end
                        else if @action=4 begin
                            truncate table ccSmsConversationsResult
                        end
                        else if @action=5 begin
                            if not exists(select 1 from ccSmsConversationsResult where camId=@camId) begin
                                insert into ccSmsConversationsResult values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance,0)
                            end
                            else begin
                                update ccSmsConversationsResult set SentMsg=SentMsg+@SentMsg 
                                ,InsufficientBalance=InsufficientBalance+@InsufficientBalance
                                where camId=@camId
                            end
                        end
                        else if @action=6 begin 
                            set @sql=''declare @listCamId table(camId int,status bit)

                        declare @camId int
                        insert into @listCamId
                        select distinct cam_id,0 from smsWorkingTable with(nolock) where smsout_id in(''+@smsoutIds+'')

                        while exists(select 1 from @listCamId where status=0)begin
                            select top 1 @camId=CamId from @listCamId where status=0
                            
                            exec ccsp_GalateaGetCampsNvosCB @cam_id=@camId,@Tipo=2,@regval=1
                            update @listCamId set status=1 where status=0 and @camId=CamId 
                        end
                        delete from smsWorkingTable where smsout_id in(''+@smsoutIds+'')
                            ''
                            exec (@sql)
                        end
                        else if @action=7 begin

                            IF @IsCharged = 1
                            BEGIN
                                UPDATE ccSettings2 WITH(TABLOCK) SET valor = valor - 1 WHERE setting_id = 258 AND valor > 0;
                            END

                            declare @statusSystemsIdOld int
                            declare @ccSmsConversationsResult table(camId int,statusSystemsId int,description varchar(255), value int)
                            select top(1) @camId =cam_id,@statusSystemsIdOld=statusSystemsId, @smsOutId=smsout_id from smsccoLogDial with(nolock) where SystemApiId=@SystemApiId
                            update smsccoLogDial set statusSystemsId=@statusSystemsId where SystemApiId=@SystemApiId
                            
                            insert into @ccSmsConversationsResult
                            select camId, ROW_NUMBER() OVER(ORDER BY camId ASC)-1 AS statusSystemsId, description,value
                            from ccSmsConversationsResult
                            unpivot
                            (
                                value
                                for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected, Exception, InsufficientBalance)
                            ) unpiv
                            where camId= @camId

                            update @ccSmsConversationsResult set value =case when value>0 then value-1 else 0 end where statusSystemsId=@statusSystemsIdOld
                            update @ccSmsConversationsResult set value =value+1 where statusSystemsId=@statusSystemsId
                            
                            ;with res as(
                            select * from 
                            (
                                select camId, description, value
                                from @ccSmsConversationsResult 
                            ) src
                            pivot
                            (
                            sum(value)
                            for description in (SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected, Exception, InsufficientBalance)
                            ) piv
                            )

                            update B 
                            set B.SentMsg=A.SentMsg
                            ,B.Delivered=A.Delivered
                            ,B.NotDelivered=A.NotDelivered
                            ,B.RecipientRejected=A.RecipientRejected
                            ,B.CarrierRejected=A.CarrierRejected
                            ,B.Exception=A.Exception
                            ,B.InsufficientBalance=A.InsufficientBalance
                            from
                            res A
                            inner join ccSmsConversationsResult B on A.camId=B.camId

                            exec ccspOutboundSmsMessage @action = 11, @smsOutId=@smsOutId
                        end
                        else if @action=8 begin
                            update smsccoLogDial set Bill=0.70 where smsDate>=@date and statusSystemsId not in(3,4,5,6)
                        end
                        else if @action=9 begin
                            CREATE TABLE #TempSmsOutIds (
                            smsout_id INT
                            );

                            INSERT INTO #TempSmsOutIds (smsout_id)
                            SELECT DISTINCT wt.smsout_id
                            FROM smsWorkingTable wt
                            JOIN smsOutSource os ON wt.smsout_id = os.smsout_id
                            LEFT JOIN smsccoLogDial cco ON wt.smsout_id = cco.smsout_id
                            WHERE wt.sms_status IN(1,2) 
                            AND wt.cam_id = @camId;

                            UPDATE wt
                            SET wt.sms_status = 0, sms_dateDial = DATEADD(mi,30,GETDATE())
                            FROM smsWorkingTable wt
                            JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

                            DROP TABLE #TempSmsOutIds;
                        end

                        else if @action=10 begin
                            IF NOT EXISTS(SELECT 1 FROM smsWorkingTable WHERE cam_id = @camId) BEGIN
                                UPDATE ccCamps SET cam_procesando = 0 WHERE cam_id = @camId
                                SELECT CAST(0 AS BIT) 
                            END
                            ELSE BEGIN
                                SELECT CAST(1 AS BIT) -- Has unsent messages 
                            END
                        end

                        else if @action=11 begin
                            UPDATE wt
                            SET sms_status = 0, sms_dateDial = DATEADD(mi,30,GETDATE())
                            FROM smsWorkingTable wt with (rowlock) WHERE smsout_id = @smsOutId;
                        end
                        else if @action=12 begin
                            if exists(select 1 from ccSmsSchedules with(nolock) where cam_id = @camId and getdate() between iDate and fDate)
                            begin
                                if exists(select 1 from smsWorkingTable with(nolock) where cam_id = @camId)
                                begin
                                    select cast(1 as bit)
                                    return
                                end
                            end
                            select cast(0 as bit)
                            update ccCamps set cam_procesando=0 where cam_id=@camId
                        end'
        EXEC(@sql);

        SET @process = 'HOTFIX K042023 Se agrega útimo update para apagar la campaña cuando no hay creditos. Líneas 1595 a 1604'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_smsOUTResetJobs] 
                    @camid AS INT= 0
                    AS
                    BEGIN

                      CREATE TABLE #TempccoLogDials ( 
                        smsout_id INT, PRIMARY KEY (smsout_id)
                      );
                      DECLARE @today DATETIME;

                      SELECT @today = CONVERT(DATETIME, CONVERT(VARCHAR(11), GETDATE(), 121), 121);
                      
                      IF @camid = 0
                      BEGIN
                        INSERT INTO #TempccoLogDials
                             SELECT smsout_id
                             FROM smsccoLogDial AS ld WITH(NOLOCK)
                             WHERE smsDate >= @today
                             GROUP BY smsout_id;
                      END;
                         ELSE
                        IF @camid > 0
                        BEGIN
                          INSERT INTO #TempccoLogDials
                               SELECT smsout_id
                               FROM smsccoLogDial AS ld WITH(NOLOCK)
                               WHERE cam_id = @camid AND 
                                 smsDate >= @today
                               GROUP BY smsout_id;
                        END;

                      -- CALLBACKS Se han marcado recientemente
                      UPDATE smsWorkingTable WITH(ROWLOCK)
                        SET sms_status = 1
                      FROM smsWorkingTable wt
                         INNER JOIN
                         #TempccoLogDials ld
                         ON wt.smsout_id = ld.smsout_id
                      WHERE wt.sms_status = 2   

                      IF @camid = 0
                      BEGIN
                        -- NUEVAS - Nunca se han marcado
                        UPDATE smsWorkingTable --WITH(ROWLOCK)
                          SET sms_status = 0
                        WHERE sms_status = 2;
                      END;
                         ELSE
                      BEGIN  
                        -- NUEVAS - Nunca se han marcado
                        UPDATE smsWorkingTable WITH(ROWLOCK)
                          SET sms_status = 0
                        WHERE sms_status = 2 AND 
                            cam_id = @camid;
                      END;

                      UPDATE c
                      SET c.cam_procesando = 0
                      FROM ccCamps c
                      WHERE c.cam_id = @camid
                      AND EXISTS (
                        SELECT 1
                        FROM ccSettings2
                        WHERE setting_id = 258
                          AND valor = 0
                      );

                      DROP TABLE #TempccoLogDials;
                    END;'
        EXEC(@sql);
        -----------------------------------------------------END HOTFIX K042023-Indicador de creditos Ivan Martin ----------------------------------------------------------------

                -----------------------------------------------------BEGIN hotfix/125.20231211.0.4 Jesus Gallardo  ----------------------------------------------------------------

         SET @process = 'Create table replicationMergeClean '
        SET @sql = 'if not exists(select * from sys.tables where name=''replicationMergeClean'')begin
create table replicationMergeClean (
dateStart datetime not null,
dateEnd datetime not null,
num_genhistory_rows int not null,
num_contents_rows int not null,
num_tombstone_rows int not null,
MSmerge_contents int not null,
MSmerge_genhistory int not null,
MSmerge_tombstone  int not null,
)
end
'
        EXEC(@sql);


        SET @process = 'Add Column ccSmsConversationsResult.Exception int'
        SET @sql = 'if not exists (select * from sys.columns where name = N''Exception'' and Object_ID = Object_ID(N''ccSmsConversationsResult''))
begin
    alter table ccSmsConversationsResult add Exception int null
end'
        EXEC(@sql);

        SET @process = 'update ccSmsConversationsResult set Exception=0 where Exception is null'
        SET @sql = 'update ccSmsConversationsResult set Exception=0 where Exception is null'
        EXEC(@sql);
        


        SET @process = 'Alter SP ccspSaveDispositionResult Se agrega With(nolock)'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccspSaveDispositionResult]
@action int,
@callType TINYINT=null,
@camId int =null,
@callid BIGINT=0,
@statusCallId int=0,
@dispotitionId int=null,
@subDispotitionId int=null
AS

declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
declare @callTypeInOut tinyint
if @action in(3,4) begin
    select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
    from ccsettings where setting_id = 27 -- 0 esp
    
end
if @action in(5,6) begin    
    select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
    from ccsettings where setting_id = 27 -- 0 esp  
end

set @callTypeInOut= case when @callType=1 then 0 else 1 end


if @action=0 begin
    declare @today date
    set @today =CONVERT(date,getdate())

    truncate table ccDispositionDashboardResultOut
    truncate table ccDispositionDashboardResultIn

    insert into ccDispositionDashboardResultOut
    select cam_id as CamId,statusCall_id as statusCallId,cal_id as callId
    ,calif_id as Disposition
    ,case  when califSub_id<=0 or califSub_id is null then 0 else califSub_id end as SubDispotitionId 
    from ccoCallsOut 
    where cal_Inicio>=@today

    insert into ccDispositionDashboardResultIn
    select Inbound_id as CamId,statusCall_id as statusCallId,cal_id as callId
    ,calif_id as Disposition
    ,case  when califSub_id<=0 or califSub_id is null then 0 else califSub_id end as SubDispotitionId 
    from ccCallsIn 
    where cal_Inicio>=@today
end
else if @action=1 begin
    set @dispotitionId=0
    set @subDispotitionId=0
    if @callType=1 begin
        insert into ccDispositionDashboardResultOut values(@camId,@statusCallId,@callid,@dispotitionId,@subDispotitionId)
    end
    else begin
        insert into ccDispositionDashboardResultIn values(@camId,@statusCallId,@callid,@dispotitionId,@subDispotitionId)
    end
end
else if @action=2 begin
    set @subDispotitionId=case when @subDispotitionId is null then null when @subDispotitionId>0 then @subDispotitionId else 0 end
    if @callType=1 begin
        update ccDispositionDashboardResultOut set statusCallId=@statusCallId,DispotitionId=isnull(@dispotitionId,DispotitionId)
        ,SubDispotitionId=isnull(@subDispotitionId,SubDispotitionId)
        where callId=@callid 
    end
    else begin
        update ccDispositionDashboardResultIn set statusCallId=@statusCallId,DispotitionId=isnull(@dispotitionId,DispotitionId)
        ,SubDispotitionId=isnull(@subDispotitionId,SubDispotitionId)
        where callId=@callid 
    end
end
else if @action=3 begin 
    select @callTypeInOut as tipo,dash.CamId as CamId
    ,case when dash.statusCallId = 13 then
        case when ca.[description] is not null then ca.[description] else @nIdioma end
        else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma end
    end as Calificacion
    ,case when count( case when dash.SubDispotitionId>0 then 1 end ) > 0 then 1 else 0 end as WithSubDisposition
    ,dash.DispotitionId as DispotitionId
    ,count(*) Amount
    ,ISNULL(GraphColor,''1DB4E2'') GraphColor
    ,CASE WHEN ISNULL(rel.calif_id, 0) = 0 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS IsSubDisp
    from ccDispositionDashboardResultOut dash with(nolock)
    left join ccTipoCalifOut ca on dash.DispotitionId = ca.calif_id 
    left join ccTipoCalifSubOUT tcsout on dash.SubDispotitionId = tcsout.califSub_id
    left join ccstatusllamada sll on sll.statuscall_id = dash.statusCallId
    left join ccCamps ci on ci.cam_id = dash.CamId
    LEFT join cctipoSubCalifRel rel on rel.calif_id = ca.calif_id and dash.SubDispotitionId = rel.califSub_id and tipoSubRel = 0
    where CamId=@camId
    group by  dash.CamId, dash.statusCallId,ca.[description],sll.descripcion,dash.DispotitionId,GraphColor,rel.calif_id

end
else if @action=4 begin 
    select @callTypeInOut as tipo
    ,dash.CamId
    ,case when ca.[Description] is not null then ca.[Description] else @nIdioma end as Calificacion
    ,case when count( case when dash.SubDispotitionId>0 then 1 end ) > 0 then 1 else 0 end as WithSubDisposition
    ,dash.DispotitionId
    ,count(*)  as Amount
    ,ISNULL(GraphColor,''1DB4E2'') GraphColor
    ,0 IsSubDisp
    from ccDispositionDashboardResultIn dash with(nolock)
    left join ccTipoCalif ca on dash.DispotitionId = ca.calif_id 
    left join ccInbound cci on cci.inbound_id = dash.CamId 
    where dash.CamId = @camId and dash.statusCallId = 13 
    group by ca.[Description], dash.CamId,dash.SubDispotitionId,dash.DispotitionId,GraphColor

end

else if @action=5 begin 
    select 0 as Type,co.CamId as CampId,
    case when co.statusCallId = 13
    then case when description is not null
    then description else @nIdioma end
    else
    case when sll.descripcion is not null
    then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma
    end
    end as Calification,
    isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(cso.califSub_id) Quantity
    from ccDispositionDashboardResultOut co
    left join ccTipoCalifOut ca on co.DispotitionId = ca.calif_id
    left join ccTipoCalifSubOUT cso on co.SubDispotitionId = cso.califSub_id 
    left join ccstatusllamada sll on sll.statuscall_id = co.statusCallId
    left join ccCamps ci on ci.cam_id = co.CamId
    where co.CamId = @camId
    and co.DispotitionId = @dispotitionId
    group by  co.CamId, co.statusCallId,description,descripcion,cso.califSubDesc
end
else if @action=6 begin 
    select 0 as [type],CamId as CampId
    , ca.[description] as Calification
    , isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName
    , count(ctcs.califSubDesc) as Quantity
    --,dash.DispotitionId
    from ccDispositionDashboardResultIn dash
    left join ccTipoCalif ca on dash.DispotitionId = ca.calif_id
    left join ccInbound cci on cci.inbound_id = dash.CamId
    left join ccTipoCalifSub ctcs on dash.SubDispotitionId = ctcs.califSub_id
    where dash.CamId=@camId and dash.statusCallId=13 and dash.DispotitionId=@dispotitionId
    group by ca.description, dash.CamId,ctcs.califSubDesc,dash.DispotitionId
end
'
        EXEC(@sql);
       

        SET @process = 'Alter SP ccsp_GalateaGetCampsNvosCB Se quita proceso que no ocupa Kolob y se agrega agrupacion para no poner datos dobles @TotalNew'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0, @tcpa int=0
as
set nocount on

declare @TipoJobs as int, @isExecOutbound bit

set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

    declare @id AS INTEGER;

    CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,campType INT)
    CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime,campType INT)

    create table #tempoutsource (cam_id int,Pend  int)

    create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

    if @cam_id = 0 begin
        if @user_id > 0 and not exists (select 1 from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
            insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
            select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
            ,isnull(cam.CampType,0) as CampType
            from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
            where user_id = @user_id and tipo = 1
        end
        else begin
            insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
            select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
            ,isnull(cam.CampType,0) as CampType
            from ccCamps cam (nolock)
        end
    end
    else begin
        if @Tipo = 2
            insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
            select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
            ,isnull(cam.CampType,0) as CampType
            from ccCamps cam with(nolock) 
            where cam.cam_id = @cam_id
        else
            if @user_id > 0 and not exists (select 1 from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) begin
                insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
                select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
                ,isnull(cam.CampType,0) as CampType
                from ccCamps cam with(nolock) 
                inner join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
                where user_id = @user_id and tipo = 1 and cam.cam_id = @cam_id
            end
            else begin
                insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,campType)
                select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
                ,isnull(cam.CampType,0) as CampType
                from ccCamps cam (nolock) 
                where cam_activo=1  and cam.cam_id = @cam_id
            end
    end
    
    ;with ccCampsNvosCBTmp as(
    select A.*,dateUpdate from #Tcamps A
    left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
    where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null
    )
    insert into #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate,campType)
    select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate),max(campType) as campType 
    from ccCampsNvosCBTmp
    group by cam_id

    if exists(select 1 from #Tcamps2) BEGIN

        if exists(select 1 from #Tcamps2 where campType=7) BEGIN
            insert into #tempoutsource(cam_id,Pend)
            SELECT sos.cam_id, count(sos.cam_id) as Pend
            FROM dbo.smsOutSource AS sos  with(index(IX_smsOutSource_1),nolock)
            inner join #Tcamps2 tcam on sos.cam_id = tcam.cam_id
            WHERE tcam.campType=7 and sos.sms_status in(0, 7)
            GROUP BY sos.cam_id

            insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
            SELECT swt.cam_id,
            count(case swt.sms_status when 0 then 1 else null end) as New,
            count(case swt.sms_status when 1 then 1 else null end) as Cb,
            count(case swt.sms_status when 2 then 1 else null end) as Pro,
            count(case swt.sms_status when 3 then 1 else null end) as Fin
            FROM dbo.smsWorkingTable AS swt  with(index(IX_smsWorkingTable_1),nolock)
            inner join #Tcamps2 B on swt.cam_id = B.cam_id 
            where B.campType=7
            GROUP BY swt.cam_id 
        end
            insert into #tempoutsource(cam_id,Pend)
            SELECT ccos.cam_id, count(ccos.cam_id) as Pend
            FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
            join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
            WHERE tcam.campType<>7 and cal_status in(0, 7)
            GROUP BY ccos.cam_id

            insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
            SELECT A.cam_id,
            count(case cal_status when 0 then 1 else null end) as New,
            count(case cal_status when 1 then 1 else null end) as Cb,
            count(case cal_status when 2 then 1 else null end) as Pro,
            count(case cal_status when 3 then 1 else null end) as Fin
            FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
            inner join #Tcamps2 B on A.cam_id = B.cam_id
            WHERE B.campType<>7 
            GROUP BY A.cam_id   
        
        if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
            update #Tcamps2 set status =1,cantidad=0  where cam_id = @cam_id
        end        

        declare @TotalNew table(
            cam_id int primary key,
            OverallTotalNew int 
            )
        


            insert into @TotalNew
        select CampNvosCB.id,max(isnull( CASE WHEN CampNvosCB.OverallTotalNew = 0 THEN NULL ELSE CampNvosCB.OverallTotalNew END,CampNvosCB.new) )
        from ccCampsNvosCB CampNvosCB with(nolock)
        inner join #Tcamps2 tcamp on CampNvosCB.id = tcamp.cam_id
        group by CampNvosCB.id

            delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
            where CampNvosCB.id = tcamp.cam_id

            INSERT into ccCampsNvosCB 
        SELECT distinct cams.cam_id, cams.cam_descripcion,
            isNull(wt.New,0) as new, isNull(wt.Cb,0) as cb,
            isNull(cs.Pend,0) as pend,
            isNull(wt.Pro,0) as pro,
            isNull(cams.procesando,0) cam_procesando,
            isNull(cams.cam_tipojobs,0) cam_tipojobs,
            isNull(wt.Fin,0) Fin,
            isNull(cams.cantidad,0) cantidad,
            getdate(),
            isnull(T.OverallTotalNew,0)  as OverallTotalNew
            FROM #Tcamps2 cams with(nolock)
            LEFT JOIN #temWorkinTable  wt on cams.cam_id = wt.cam_id
            LEFT JOIN #tempoutsource cs on cams.cam_id = cs.cam_id
            LEFT JOIN @TotalNew  T on T.cam_id = cams.cam_id

    end

    if @isExecOutbound = 0 begin

    if @Tipo = 2 begin
        -- devuelve resultado de la taba, solo las camps del usuario
        SELECT res.id, res.campaña, res.new, res.cb, res.pro, res.pen, cc.cam_procesando as st, res.job, res.Fin, 
        isnull(prio.prioridad,''12345NNN'') as Prioridad, NextDial,cc.aggressionFactor, OverallTotalNew
        FROM #Tcamps tcam
        left join  ccCampsNvosCB res (nolock) on tcam.cam_id  = res.id
        LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
        inner join cccamps cc (nolock) on res.id=cc.cam_id
    end
    else 
        SELECT id, campaña, new, cb, pro, pen,cc.cam_procesando as st, job, Fin, isnull(prioridad,''12345NNN'')  as Prioridad, NextDial,
        cc.aggressionFactor, OverallTotalNew
        FROM ccCampsNvosCB res (nolock)
        LEFT JOIN ccCampsPrioridadTel prio (nolock) on res.id = prio.cam_id
        inner join cccamps cc (nolock) on res.id=cc.cam_id
        WHERE res.id = @cam_id
    end

    drop table #Tcamps
    drop table #Tcamps2
    drop table #tempoutsource
    drop table #temWorkinTable

    return(0)

end

set nocount off'
        EXEC(@sql);

        SET @process = 'Alter Sp ccsp_GalateaArtificialIntelligence IF @option = 7 obtener el ultimo id de la carga'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaArtificialIntelligence] 

@option AS SMALLINT, 
@tableName varchar(255) = null,
@tableNameTmpIA varchar(255) = null,
@columnNameId varchar(255) = null,
@dateLastCheck datetime = null,
@columnWhereDays varchar(255)=null,
@EnableOrDisableTrigger bit =0,
@listLoadings varchar(8000) =null,
@IAState int =null

AS
BEGIN
SET NOCOUNT ON;

DECLARE @object_name SYSNAME, @object_id INT;
DECLARE @SQL NVARCHAR(MAX) = '''', @primaryKey NVARCHAR(max), @CONSTRAINT NVARCHAR(max) = ''''
DECLARE @columns XML,@index nvarchar(max)=''''

IF @option in(0,1) begin
    SELECT @object_name = ''['' + s.name + ''].['' + o.name + '']'', @object_id = o.object_id
    FROM sys.objects AS o WITH (NOWAIT)
    INNER JOIN sys.schemas AS s WITH (NOWAIT) ON o.schema_id = s.schema_id
    WHERE o.name = @tableName AND o.type = ''U'' AND o.is_ms_shipped = 0;
end

IF @option = 0   --Create Table
BEGIN  
    SET @columns = (
    SELECT CHAR(9) + '', ['' + c.name + ''] '' 
    + CASE 
    WHEN c.is_computed = 1
        THEN ''AS '' + cc.DEFINITION
    ELSE UPPER(tp.name) + CASE 
            WHEN tp.name IN (''varchar'', ''char'', ''varbinary'', ''binary'', ''text'')
                THEN ''('' + CASE 
                        WHEN c.max_length = - 1
                            THEN ''MAX''
                        ELSE CAST(c.max_length AS VARCHAR(5))
                        END + '')''
            WHEN tp.name IN (''nvarchar'', ''nchar'', ''ntext'')
                THEN ''('' + CASE 
                        WHEN c.max_length = - 1
                            THEN ''MAX''
                        ELSE CAST(c.max_length / 2 AS VARCHAR(5))
                        END + '')''
            WHEN tp.name IN (''datetime2'', ''time2'', ''datetimeoffset'')
                THEN ''('' + CAST(c.scale AS VARCHAR(5)) + '')''
            WHEN tp.name = ''decimal''
                THEN ''('' + CAST(c.precision AS VARCHAR(5)) + '','' + CAST(c.scale AS VARCHAR(5)) + '')''
            ELSE ''''
            END + CASE 
            WHEN c.collation_name IS NOT NULL
                THEN '' COLLATE '' + c.collation_name
            ELSE ''''
            END + CASE 
            WHEN c.is_nullable = 1
                THEN '' NULL''
            ELSE '' NOT NULL''
            END  
                
    END + CHAR(13) 
    FROM sys.columns AS c WITH (NOWAIT)
    INNER JOIN sys.types AS tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
    --inner join @tableColumn T on c.name=T.columnName
    LEFT JOIN sys.computed_columns AS cc WITH (NOWAIT) ON c.object_id = cc.object_id
        AND c.column_id = cc.column_id
    LEFT JOIN sys.default_constraints AS dc WITH (NOWAIT) ON c.default_object_id != 0
        AND c.object_id = dc.parent_object_id
        AND c.column_id = dc.parent_column_id
    LEFT JOIN sys.identity_columns AS ic WITH (NOWAIT) ON c.is_identity = 1
        AND c.object_id = ic.object_id
        AND c.column_id = ic.column_id
    WHERE c.object_id = @object_id
        AND c.name <> ''rowguid''
    ORDER BY c.column_id
    FOR XML PATH(''''), TYPE
    )

    SELECT @primaryKey = isnull(CHAR(9) + '', CONSTRAINT ['' + k.name + ''] PRIMARY KEY ('' + (
                SELECT STUFF((
                            SELECT '', ['' + c.name + ''] '' + CASE WHEN ic.is_descending_key = 1 THEN ''DESC'' ELSE ''ASC'' END
                            FROM sys.index_columns AS ic WITH (NOWAIT)
                            INNER JOIN sys.columns AS c WITH (NOWAIT) ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                            WHERE ic.is_included_column = 0 AND ic.object_id = k.parent_object_id AND ic.index_id = k.unique_index_id
                            FOR XML PATH(N''''), TYPE
                            ).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''')
                ) + '')'' + CHAR(13), '''') + '')'' + CHAR(13)
    FROM sys.key_constraints AS k WITH (NOWAIT)
    WHERE k.parent_object_id = @object_id AND k.type = ''PK'';


    SELECT @SQL = ''CREATE TABLE '' + @object_name + CHAR(13) + ''('' + CHAR(13)  + CHAR(9)+'' ''
    + STUFF((@columns).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''')
    + isnull(@primaryKey,'')'')
    + @CONSTRAINT
    + @index

    select @SQL as [query];

END;

ELSE IF @option = 1  -- Alter Table Add Column
BEGIN
    SELECT  
    ''if not exists (select * from sys.columns where name = N'''''' + c.name + '''''' and Object_ID = Object_ID(N'''''' + @tableName + 
        '''''')) begin '' + ''ALTER TABLE '' + @tableName + '' ADD ['' + c.name + ''] '' + CASE 
    WHEN c.is_computed = 1
        THEN ''AS '' + cc.DEFINITION
    ELSE UPPER(tp.name) + CASE 
            WHEN tp.name IN (''varchar'', ''char'', ''varbinary'', ''binary'', ''text'')
                THEN ''('' + CASE 
                        WHEN c.max_length = - 1
                            THEN ''MAX''
                        ELSE CAST(c.max_length AS VARCHAR(5))
                        END + '')''
            WHEN tp.name IN (''nvarchar'', ''nchar'', ''ntext'')
                THEN ''('' + CASE 
                        WHEN c.max_length = - 1
                            THEN ''MAX''
                        ELSE CAST(c.max_length / 2 AS VARCHAR(5))
                        END + '')''
            WHEN tp.name IN (''datetime2'', ''time2'', ''datetimeoffset'')
                THEN ''('' + CAST(c.scale AS VARCHAR(5)) + '')''
            WHEN tp.name = ''decimal''
                THEN ''('' + CAST(c.precision AS VARCHAR(5)) + '','' + CAST(c.scale AS VARCHAR(5)) + '')''
            ELSE ''''
            END + CASE 
            WHEN c.collation_name IS NOT NULL
                THEN '' COLLATE '' + c.collation_name
            ELSE ''''
            END + CASE 
            WHEN c.is_nullable = 1
                THEN '' NULL''
            ELSE '' NOT NULL''
            END  
                
    END + CHAR(13) + '' end'' as [query]
    FROM sys.columns AS c WITH (NOWAIT)
    INNER JOIN sys.types AS tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
    --inner join @tableColumn T on c.name=T.columnName
    LEFT JOIN sys.computed_columns AS cc WITH (NOWAIT) ON c.object_id = cc.object_id
    AND c.column_id = cc.column_id
    LEFT JOIN sys.default_constraints AS dc WITH (NOWAIT) ON c.default_object_id != 0
    AND c.object_id = dc.parent_object_id
    AND c.column_id = dc.parent_column_id
    LEFT JOIN sys.identity_columns AS ic WITH (NOWAIT) ON c.is_identity = 1
    AND c.object_id = ic.object_id
    AND c.column_id = ic.column_id
    WHERE c.object_id = @object_id
    AND c.name <> ''rowguid''
    ORDER BY c.column_id

END;

ELSE IF @option = 2  -- Get Tables Configuration
BEGIN
    update [ccAIReplicaConfiguration] set dateLastCheck=null;
    
    SELECT idConfig,
    tableName,
    columnPrimaryKey,
    triggerName,
    active,
    timeCheck,
    dateLastCheck,
    columnWhereDays,
    isnull(copyContent,1)  as copyContent FROM [ccAIReplicaConfiguration] WHERE active = 1


End;

ELSE IF @option = 3  -- Get DataTable
BEGIN   
    DECLARE @params NVARCHAR(4000) = ''@dateLastCheck datetime''
    
    if @dateLastCheck is not null begin
        set @SQL=''select B.* from ''+@tableNameTmpIA+ '' A with(nolock) 
        inner join '' +@tableName+'' B with(nolock) on A.''+@columnNameId+''=B.''+@columnNameId+''
        where A.dateUpdate>@dateLastCheck ''
    end
    else begin
        declare @where NVARCHAR(MAX) = ''''
        declare @datenow datetime= dateadd(dd,-30,convert(date,getdate()))
        set @dateLastCheck=@datenow
        if @columnWhereDays is not null or @columnWhereDays<>'''' begin
            set @where='' where ''+@columnWhereDays+''>@dateLastCheck''
        end

        set @SQL=''select A.* from ''+@tableName +'' A with(nolock) ''
        + case when @tableName in(''ccUsers'') then '' '' else
         ''inner join ccCamps c with(nolock) on c.cam_id=A.cam_id and c.CampType=4 '' end
         + @where
    end

    
    if @tableName=''ccRIALoading'' begin
    set @SQL=@SQL+'' and ia_state=1 ''
    end
    
    print @SQL
    --select @dateLastCheck
    EXEC sp_executesql @SQL, @params, @dateLastCheck=@dateLastCheck;
End;

ELSE IF @option = 4   -- Enable and Disable trigger
BEGIN
    declare @command varchar(10) = case when @EnableOrDisableTrigger=0 then ''DISABLE'' else ''ENABLE'' end
    declare @i int
    declare @tmpTable table(idConfig SMALLINT primary key,
    tableName varchar(255) not null,
    triggerName varchar(255) not null,status bit
    )
    insert into @tmpTable
    select idConfig,tableName,triggerName,0 from ccAIReplicaConfiguration
    while exists(select * from @tmpTable where status=0) begin
        select top 1 @columnNameId=triggerName,@tableName=tableName,@i=idConfig from @tmpTable where status=0

        set @SQL=@command+'' TRIGGER ''+@columnNameId+'' ON ''+@tableName
        update @tmpTable set status=1 where idConfig=@i
        --print(@sql)
        exec (@SQL)
        
    end
End;

ELSE IF @option = 5   -- Update Last Check Date
BEGIN
    IF EXISTS (SELECT * FROM ccAIReplicaConfiguration WHERE tableName = @tableName)
    BEGIN
        UPDATE ccAIReplicaConfiguration SET dateLastCheck = @dateLastCheck WHERE tableName = @tableName
    END;
End;

ELSE IF @option = 6   -- Erase Temporary Tables Data
BEGIN
declare @id int

declare @tableTruncate table(
    id int identity primary key,
    tableName varchar(255) not null,
    status bit not null
)
    insert into @tableTruncate(tableName,status)
    select tableName+''TmpIA'',0 from [ccAIReplicaConfiguration]
    while exists(select * from @tableTruncate where status=0) begin
        select top 1 @id=id,@tableNameTmpIA=tableName from @tableTruncate where status=0
            set @sql=''IF EXISTS (SELECT * FROM sys.tables WHERE name = N''''''+@tableNameTmpIA+'''''')
        BEGIN
            TRUNCATE TABLE ''+@tableNameTmpIA+''
        END;''
        exec (@sql)
        update  @tableTruncate set status=1 where @id=id
    end

    update [ccAIReplicaConfiguration] set dateLastCheck=null;
    SELECT CAST(1 AS BIT) AS Result
End;
ELSE IF @option = 7   -- List Loading
BEGIN
    declare @tableRegistry table(
    LoadId int not null,    
    ListId int not null,
    CamId int not null
    )
    insert into @tableRegistry
    select A.load_id,A.list_id,A.cam_id from ccRIALoading A 
    inner join ccCamps C on A.cam_id=C.cam_id and C.CampType=4
    where (@dateLastCheck is null or A.loadDate>=@dateLastCheck) and A.ia_state=1 and pctg=100
    order by loadDate 
    if exists(select * from @tableRegistry) begin
        select max(A.LoadId) LoadId,max(A.ListId) ListId,A.CamId,B.callout_id as CalloutId from @tableRegistry A
        inner join ccoCallsOutSource B on A.listId=B.list_id
        group by A.CamId,B.callout_id
        order by CalloutId
    end
End;

ELSE IF @option = 8 and @listLoadings is not null  -- update State Loading
BEGIN
    
    update B set B.ia_state=@IAState from  dbo.fn_RIASplitDelimited(@listLoadings,'','') A
    inner join ccRIALoading B on A.value=B.load_id

    if @IAState =2 begin
        select @dateLastCheck= max(B.loadDate) from  dbo.fn_RIASplitDelimited(@listLoadings,'','') A
        inner join ccRIALoading B on A.value=B.load_id

        update [ccAIReplicaConfiguration] set dateLastCheck=@dateLastCheck where tableName=''ccRIALoading''
    end
    
End;
ELSE IF @option = 9  -- update State Loading
BEGIN
    update B set B.cal_fechaDial=A.DateDial from cc_CalloutDateIA A
    inner join ccoCallsOutSource B on A.CalloutId=B.callout_id
    

End;
End;
'
        EXEC(@sql);

        SET @process = 'Alter SP ccsp_GalateaAdminCampaigns'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
@Option AS      SMALLINT, 
@CampType AS    SMALLINT = 0, 
@WorkgroupId AS INT      = 0, 
@Id AS          INT      = 0, 
@AdminId AS     SMALLINT = 0, 
@PinUpdate AS   SMALLINT = 0, 
@LoadId AS      INT      = 0, 
@Type AS        SMALLINT = 0,
@InboundType    SMALLINT = 0,
@AreaId         SMALLINT = 0,
@multi_type     varchar(max) = null
AS
BEGIN
    SET NOCOUNT ON;
IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
        
    IF @CampType = 1 BEGIN-- Campaigns Out
        
    IF @WorkgroupId IS NOT NULL BEGIN
        SELECT CAST(IdCampEsp AS INT) AS Id FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId AND Tipo = 1
        ORDER BY IdCampEsp ASC;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
    END;
END;
    IF @CampType = 0 BEGIN-- Campaigns In (ACD)
        IF @WorkgroupId IS NOT NULL BEGIN
            SELECT CAST(IdCampEsp AS INT) AS Id FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId AND Tipo = 0
            ORDER BY IdCampEsp ASC;
        END;
        ELSE
        BEGIN
            RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
        END;
    END;
    RETURN 0;
END;
IF @Option = 2 BEGIN-- Get Campaign complete information per Campaign Type and Campaign Id      
    IF @CampType = 1 BEGIN-- Campaigns Out      
        IF @Id IS NOT NULL BEGIN
            SELECT DISTINCT 
            CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
            isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
            camps.cam_procesando IsStarted, 
            ISNULL(a.AreaName, '''') AS Area, 
            CAST(ISNULL(camps.IDArea, 0) AS INT) as AreaId,
            CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType,
            CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 ELSE isnull(camps.CampType,0) END as OutboundType,
            ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule,
            a.ToolsTransfer         
            FROM ccCamps camps
            LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
            LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
            LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
            WHERE camps.cam_id = @Id
            ORDER BY camps.cam_descripcion ASC;
        END;
        ELSE BEGIN
            RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
        END;
    END;
    ELSE IF @CampType = 0 -- Campaigns In (ACD)
        BEGIN
            IF @Id IS NOT NULL
                BEGIN
                    SELECT DISTINCT 
                    CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, 
                    ISNULL(a.AreaName, '''') AS Area, 
                            CAST(ISNULL(inb.IDArea, 0) AS INT) as AreaId, inb.chat AS InboundType, 0 as OutboundType,
                            a.ToolsTransfer
                    FROM ccInbound inb
                            LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
                            LEFT JOIN ccRIACat_Areas a ON a.IDArea = inb.IDArea
                    WHERE inb.Inbound_id = @Id
                            ORDER BY inb.descripcion ASC;
            END;
            ELSE
                BEGIN
                    RAISERROR(''ERROR. No existe campañas de entrada con el id especificado'', 18, 1);
            END;
    END;
    RETURN 0;
END;
ELSE IF @Option = 3  BEGIN -- Update OverallTotalNew By Campaign

    IF @Id IS NOT NULL BEGIN
        UPDATE ccCampsNvosCB SET  OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
    END;
    RETURN 0;
END;
ELSE IF @Option = 4 -- Update Pin from Campaign per Admin
BEGIN
    IF @Id IS NOT NULL
        AND @AdminId IS NOT NULL
    BEGIN
        IF @PinUpdate = 1
        BEGIN
            INSERT INTO PinedCampaigns (CampId, AdminId, Type)
            VALUES (@Id, @AdminId, @Type);
        END;

        IF @PinUpdate = 0
        BEGIN
            DELETE
            FROM PinedCampaigns
            WHERE CampId = @Id
                AND AdminId = @AdminId
                AND Type = @Type;
        END;
    END;
    ELSE
    BEGIN
        RAISERROR (''ERROR. La campañas o administrador no existen'', 18, 1
                );
    END;

    RETURN 0;
END;

ELSE IF @Option = 5 BEGIN  -- Get Pin from Campaign Ids per Admin       
    IF @AdminId IS NOT NULL BEGIN
        SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
        ORDER BY Id ASC;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
    END;
    RETURN 0;
END;
ELSE IF @Option = 6 -- Get Blacklist Ids by Campaign Id
BEGIN
    IF @Id IS NOT NULL
    BEGIN
        DECLARE @BlackListIds VARCHAR(MAX);

        SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR
                    (MAX)), CAST(idtipolista AS VARCHAR(MAX)))
        FROM Camplistanegra
        WHERE cam_id = @Id
            AND STATUS = 1;

        SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
    END;
    ELSE
    BEGIN
        RAISERROR (''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
    END;

    RETURN 0;
END;
    
ELSE IF @Option = 7 -- Get RegistryListIds Ids by Campaign Id
BEGIN
    IF (
            @Id IS NOT NULL
            AND EXISTS (
                SELECT *
                FROM cccamps
                WHERE cam_id = @Id
                )
            )
    BEGIN
        SELECT TOP 1 list_id
        FROM ccRIARegistryLists
        WHERE cam_id = @Id
            AND STATUS = 2
        ORDER BY list_id DESC;
    END;
    ELSE
    BEGIN
        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
        RAISERROR (''ERROR. No existe una campaña con el id especificado'', 18, 1);
    END;

    RETURN 0;
END;

ELSE IF @Option = 8 -- Delete RegistryListIds Ids by LoadId
BEGIN
    IF (
            @LoadId IS NOT NULL
            AND EXISTS (
                SELECT *
                FROM ccRIARegistryLists
                WHERE list_id = @loadID
                    AND STATUS <> 0
                )
            )
    BEGIN
        UPDATE ccoCallsOutSource
        SET cal_status = ''5''
        WHERE list_id = @loadID;

        DELETE
        FROM ccoWorkingTable
        WHERE list_id = @LoadId;

        EXEC ccsp_RIARegistryLists @action = 6, @list_id = @LoadId;
    END;
    ELSE
    BEGIN
        --Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
        RAISERROR (''ERROR. No existe una carga el id especificado'', 18, 1);
    END;

    RETURN 0;
END;

ELSE IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
BEGIN
    DECLARE @table TABLE (camId INT, campType TINYINT, PRIMARY KEY (camId, campType)
        );

    INSERT INTO @table
    SELECT DISTINCT IdCampEsp, Tipo
    FROM ccRIACampEspWG wg
    WHERE wg.IDWG IN (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers
            WHERE IDWG <> @WorkgroupId
                AND User_id = @AdminId
            );

    SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
    FROM @table A
    RIGHT JOIN (
        SELECT wg.IdCampEsp, wg.Tipo
        FROM ccRIACampEspWG wg
        WHERE wg.IDWG = @WorkgroupId
        ) B ON A.camId = B.IdCampEsp
        AND A.campType = B.Tipo
    WHERE A.camId IS NULL
    ORDER BY IdCampEsp;

    RETURN 0;
END;

ELSE IF @option = 10 BEGIN -- Get Agents States with totals per campaign by admin id and campaign type
    DECLARE @date DATETIME = CONVERT(DATE, DATEADD(hh, - 3, GETDATE()));
    DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY (id));
    DECLARE @AgentsList TABLE (id INT, PRIMARY KEY (id));
    DECLARE @tmpCamAgent TABLE (
        camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY (camId, userId
            )
        );
    DECLARE @AgentStatus TABLE (CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT
        );
    DECLARE @CurrentStatus TABLE (userId INT, CurrentState INT, IdCampEsp INT, camType INT
        );
    DECLARE @campDataTotal TABLE (
        camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY (camId
            )
        );

    INSERT INTO @AdminWorkgroups
    SELECT DISTINCT IDWG
    FROM ccRIAWorkGroupUsers WG, ccUsers_Roles R
    WHERE WG.User_id = @AdminId
        OR (
            R.User_id = @AdminId
            AND R.Rol_id = 7
            );

    INSERT INTO @AgentsList
    SELECT DISTINCT A.User_id
    FROM ccRIAWorkGroupUsers A
    INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
    INNER JOIN ccUsers C ON A.User_id = C.User_id
        AND C.TipoUser_id = 1
    ORDER BY A.User_id;

    INSERT INTO @tmpCamAgent
    SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id, CASE WHEN @Id = 0
                AND @CampType = 0 THEN inbound.chat ELSE NULL END
    FROM ccRIACampEspWG campPerWg
    INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
    INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
    INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
    LEFT JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp
        AND @CampType = 0
    LEFT JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp
        AND @CampType = 1
    WHERE C.TipoUser_id = 1
        AND campPerWg.Tipo = @CampType
        AND (
            @Id = 0
            OR campPerWg.IdCampEsp = @Id
            );;

    WITH lastState
    AS (
        SELECT A.user_id, MAX(A.fecha) AS fecha
        FROM ccLogAgentesDia A
        INNER JOIN @AgentsList B ON A.User_id = B.id
        WHERE fecha >= @date
        GROUP BY user_id
        )
    INSERT INTO @CurrentStatus
    SELECT B.User_id, CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS 
        currentStatus, B.IdCampEsp, B.Tipo
    FROM lastState A
    INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
        AND A.fecha = B.fecha;

    IF @Id = 0
        AND @CampType = 0
    BEGIN
        DELETE
        FROM @tmpCamAgent
        WHERE multimediaType = 5
    END

    DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;

    IF @CampType = 1
    BEGIN
        SELECT @MultimediaType = meanContactTypeId
        FROM contactMeanOut
        WHERE camp_id = @Id
    END
    ELSE
    BEGIN
        SELECT @chatType = ci.chat
        FROM dbo.ccInbound AS ci
        WHERE ci.Inbound_id = @Id;

        SELECT @MultimediaType = meanContactTypeId
        FROM contactMeanIn
        WHERE inboundId = @Id
    END

    IF (@chatType = 1)
    BEGIN
        SET @MultimediaType = 1
    END

    DECLARE @StateIds VARCHAR(100) = (
            SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN 
                            ''23'' ELSE ''4,5,6,9'' END
            ) -- Add more for multimediaTypes

    INSERT INTO @AgentStatus
    SELECT A.camId, A.userId, B.CurrentState, (
            CASE WHEN @chatType = 1 THEN CASE WHEN B.CurrentState IN (
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(@StateIds, '','')
                                    ) THEN @CampType ELSE CASE WHEN B.CurrentState IN (
                                            SELECT value
                                            FROM dbo.fn_RIASplitDelimited(
                                                    @StateIds, '','')
                                            )
                                        AND B.IdCampEsp = A.camId
                                        AND B.camType = @CampType THEN @CampType ELSE 
                                        NULL END END END
            ) AS isCampDialog, B.camType
    FROM @tmpCamAgent A
    INNER JOIN @CurrentStatus B ON A.userId = B.userId
    WHERE (
            @Id = 0
            OR A.camId = @Id
            )

    IF @CampType = 1
    BEGIN
            ;

        WITH campDataTotal
        AS (
            SELECT camId, count(*) total
            FROM @tmpCamAgent A
            GROUP BY camId
            )
        INSERT INTO @campDataTotal
        SELECT A.camId, B.cam_descripcion AS campName, A.Total, C.AreaName AS Area
        FROM campDataTotal A
        INNER JOIN ccCamps B ON A.camId = B.cam_id
        INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END
    ELSE
    BEGIN
            ;

        WITH campDataTotal
        AS (
            SELECT camId, count(*) total
            FROM @tmpCamAgent A
            GROUP BY camId
            )
        INSERT INTO @campDataTotal
        SELECT A.camId, B.descripcion AS campName, A.Total, C.AreaName AS Area
        FROM campDataTotal A
        INNER JOIN ccInbound B ON A.camId = B.Inbound_id
        INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
    END;

    WITH stateCamp
    AS (
        SELECT A.CampId, count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready, 
            count(CASE WHEN A.CurrentState NOT IN (- 2, - 1, 0, 3, 4, 5, 6, 9, 30, 34
                            ) THEN 1 WHEN A.CurrentState IN (6, 34, 4
                            )
                        AND (
                            A.CampId != C.IdCampEsp
                            OR A.campType != @CampType
                            ) THEN 1 ELSE NULL END) AS notReady, COUNT(isCampDialog) AS 
            dialog, COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS 
            disconnected
        FROM @AgentStatus A
        INNER JOIN @CurrentStatus C ON A.userId = C.userId
        GROUP BY A.CampId
        )
    SELECT A.camId, A.campName, A.Total, ISNULL(B.ready, 0) AS Ready, ISNULL(B.notReady, 
            0) AS NotReady, ISNULL(B.dialog, 0) AS Dialog, CASE WHEN B.disconnected IS NULL 
                THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END 
        Disconnected, A.Area
    FROM @campDataTotal A
    LEFT JOIN stateCamp B ON A.camId = B.CampId
    ORDER BY A.campName

    RETURN 0;
END;
ELSE IF @Option = 11 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
    IF NOT EXISTS (
            SELECT *
            FROM ccUsers_Roles WITH (NOLOCK)
            WHERE User_id = @AdminId
                AND Rol_id = 7
            )
    BEGIN
        --print ''xxxx SIn Super''
            ;

        WITH wgId
        AS (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers WITH (NOLOCK)
            WHERE user_id = @AdminId
            )
        SELECT DISTINCT CAST(IdCampEsp AS INT) AS Id
        FROM ccRIACampEspWG A WITH (NOLOCK)
        INNER JOIN wgId ON wgId.IDWG = A.IDWG
            AND A.Tipo = @CampType;
    END;
    ELSE
    BEGIN
        --print ''xxxx Super''
        IF @CampType = 1
        BEGIN
            SELECT DISTINCT CAST(cam_id AS INT) AS Id
            FROM ccCamps WITH (NOLOCK)
            WHERE IDArea IS NOT NULL
        END
        ELSE
        BEGIN
            SELECT DISTINCT CAST(Inbound_id AS INT) AS Id
            FROM ccInbound WITH (NOLOCK)
            WHERE IDArea IS NOT NULL
        END
    END;

    RETURN 0;
END;

ELSE IF @Option = 12 BEGIN-- Get All Campaigns complete information per Campaign Type and Campaign Id
    IF @CampType = 1 -- Campaigns Out
    BEGIN
                    SELECT DISTINCT 
                    CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
                    isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
                    camps.cam_procesando IsStarted, a.AreaName AS Area, CAST(a.IDArea as INT) AS AreaId,
                    CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, 
                    CASE WHEN ivrScript <> 0 AND callsBySurvey <> 0 THEN 8 ELSE isnull(camps.CampType,0) END as OutboundType,
                    ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
        FROM ccCamps camps(NOLOCK)
        INNER JOIN ccRIACampsGraph graph(NOLOCK) ON camps.cam_id = graph.cam_id
        INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = camps.IDArea
        LEFT JOIN ccCampsExtend extended(NOLOCK) ON camps.cam_id = extended.cam_id
        ORDER BY camps.cam_descripcion ASC;
    END;
    ELSE
    BEGIN
        SELECT DISTINCT CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name, isnull
            (CAST(graph.graphic_id AS INT), 1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(
                inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, CAST(a.IDArea AS INT) AS 
            AreaId, inb.chat AS InboundType, 0 AS OutboundType
        FROM ccInbound inb(NOLOCK)
                            INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
        INNER JOIN ccRIACat_Areas a(NOLOCK) ON a.IDArea = inb.IDArea
        ORDER BY inb.descripcion ASC;
    END;

    RETURN 0;
END;

ELSE IF @Option = 13
BEGIN
    BEGIN
        IF NOT EXISTS (
                SELECT *
                FROM ccUsers_Roles NOLOCK
                WHERE User_id = @AdminId
                    AND Rol_id = 7
                )
        BEGIN
            IF @CampType = 1
            BEGIN
                WITH wgId
                AS (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS CampId,
                                    cam_descripcion AS Description,
                                    isnull(IDArea, -1) AS AreaID,
                                    CAST(-1 AS SMALLINT) AS CampaignType,
                                    CAST(-1 AS INT) AS RelatedCampId,
                                    CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN CampType ELSE 8 END AS INT) AS Channel,
                                    CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
                                    CAST(1 AS INT) As CampType
                FROM ccRIACampEspWG A
                INNER JOIN wgId ON wgId.IDWG = A.IDWG
                    AND A.Tipo = 1
                                    INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id
                                    LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
            END
            ELSE
            BEGIN
                WITH wgId
                AS (
                    SELECT IDWG
                    FROM ccRIAWorkGroupUsers NOLOCK
                                    WHERE user_id = @AdminId)
                                SELECT DISTINCT 
                                    CAST(IdCampEsp AS INT) AS CampId,
                                    descripcion AS Description,
                                    isnull(IDArea, -1) AS AreaID,
                                    CAST(chat AS SMALLINT) AS CampaignType,
                                    CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                    CAST(chat AS INT) AS Channel,
                                    CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                    CAST(0 AS INT) As CampType
                FROM ccRIACampEspWG A(NOLOCK)
                INNER JOIN wgId ON wgId.IDWG = A.IDWG
                    AND A.Tipo = 0
                INNER JOIN ccInbound cci(NOLOCK) ON A.IdCampEsp = cci.Inbound_id
                                    LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                                    LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                                    AND ((@multi_type is null AND cci.chat = @InboundType)
                                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
            END
        END;
        ELSE
        BEGIN
            IF @CampType = 1
            BEGIN
                        SELECT DISTINCT 
                                CAST(ccc.cam_id AS INT) AS CampId,
                                cam_descripcion AS Description,
                                isnull(IDArea, -1) AS AreaID,
                                CAST(-1 AS SMALLINT) AS CampaignType,
                                -1 AS RelatedCampId,
                                CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN CampType ELSE 8 END AS INT) AS Channel,
                                CAST(ISNULL(ccRCG.graphic_id, 1) AS INT) As Frame,
                                CAST(1 AS INT) As CampType
                        FROM ccCamps AS ccc (NOLOCK) 
                            LEFT JOIN ccRIACampsGraph ccRCG ON (ccc.cam_id = ccRCG.cam_id)
                        where IDArea = @AreaId
            END
            ELSE
            BEGIN
                        SELECT DISTINCT 
                                CAST(cci.Inbound_id AS INT) AS CampId,
                                descripcion AS Description,
                                isnull(IDArea, -1) AS AreaID,
                                CAST(chat AS SMALLINT) AS CampaignType,
                                CAST(chat AS INT) AS Channel,
                                CAST(isnull(cci.cam_id,-1) AS INT) AS RelatedCampId,
                                CAST(isnull(ccRCG.graphic_id,1) AS INT) As Frame,
                                CAST(0 AS INT) As CampType
                FROM ccInbound cci(NOLOCK)
                            LEFT JOIN ccRIACampsGraph ccRCG ON (cci.Inbound_id = ccRCG.cam_id)
                            LEFT JOIN ccInboundExtend ccie ON (cci.Inbound_id = ccie.Inbound_id)
                        where IDArea = @AreaId
                        AND ((@multi_type is null AND cci.chat = @InboundType)
                            OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

            END
        END;

        RETURN 0;
    END;
END;
ELSE IF @Option = 14
BEGIN
    IF NOT EXISTS (
            SELECT *
            FROM ccUsers_Roles NOLOCK
            WHERE User_id = @AdminId
                AND Rol_id = 7
            )
    BEGIN
        WITH wgId
        AS (
            SELECT IDWG
            FROM ccRIAWorkGroupUsers NOLOCK
                                WHERE user_id = @AdminId)
                            SELECT DISTINCT 
                                CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
        FROM ccRIACampEspWG A(NOLOCK)
        INNER JOIN wgId ON wgId.IDWG = A.IDWG
            AND A.Tipo = 0
                                INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id AND isnull(cci.cam_id,-1) = -1
                                AND ((@multi_type is null AND cci.chat = @InboundType)
                                    OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

    END
    ELSE
    BEGIN
                    SELECT DISTINCT 
                    CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
                    FROM ccInbound cci (NOLOCK) where IDArea = @AreaId AND isnull(cam_id,-1) = -1
                    AND ((@multi_type is null AND cci.chat = @InboundType)
                        OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

    END
END

ELSE IF @Option = 15
BEGIN
            SELECT DISTINCT 
            CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
            FROM ccInbound NOLOCK where cam_id = @Id
END

END;
'
        EXEC(@sql);

        SET @process = 'Alter SP ccsp_GalateaAdminGetAgentCounters Se agrega @workgroupIds para filtrar las campañas al iniciar sesion'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS      INT, 
                                                          @sup_id AS    INT          = 0, 
                                                          @agent_id AS  INT          = 0, 
                                                          @WG AS        INT          = 0, 
                                                          @AgentsIds AS VARCHAR(MAX) = '''', 
                                                          @campId AS    INT          = 0, 
                                                          @CampType AS  SMALLINT     = 1,
                                                          @workgroupIds  varchar(max)=''0''
AS
     SET NOCOUNT ON;
     DECLARE @dateStart DATETIME;
     IF @type = 1
         BEGIN
             WITH TableUserAgent(userId)
                  AS (SELECT DISTINCT 
                             wgAgt.User_id AS Id --,usr.login 
                      FROM ccriaworkgroupusers wgAdmin
                           INNER JOIN ccriaworkgroupusers wgAgt ON wgAdmin.IDWG = wgAgt.IDWG
                           INNER JOIN ccUsers usr ON usr.User_id = wgAgt.User_id
                                                     AND usr.TipoUser_id = 1
                      WHERE wgAdmin.User_id = @sup_id)
                  SELECT CAST(a.User_id AS INT) Id, a.login AS Username, a.Nombres + '' '' + a.ApellidoPaterno + '' '' + a.ApellidoMaterno AS Name
                  FROM ccusers a with(NOLOCK)
                       INNER JOIN TableUserAgent b ON a.User_id = b.userId
                         ORDER BY a.Login ASC;
             RETURN 0;
     END;
     IF @type = 2
         BEGIN
             SELECT CAST(u.User_id AS INT) Id, Login Username, Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno Name,
                                                                                                                       CASE WHEN p.publicIp IS NULL
                                                                                                                                 OR p.publicIp = '''' THEN ''000.000.000.000''
                                                                                                                       ELSE p.publicIp
                                                                                                                       END IP
             FROM ccUsers u
                  LEFT JOIN ccPosicion p ON p.user_id = @agent_id
             WHERE u.User_id = @agent_id;
             RETURN 0;
     END;
     IF @type = 3 --Agents by supervisor and WG
         BEGIN
             DECLARE @table2 TABLE(userId INT PRIMARY KEY NOT NULL);
             INSERT INTO @table2
                    SELECT DISTINCT 
                           wg.User_id
                    FROM ccRIAWorkGroupUsers wg
                         LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                    WHERE us.TipoUser_id = 1
                          AND wg.IDWG IN
                    (
                        SELECT IDWG
                        FROM ccRIAWorkGroupUsers
                        WHERE User_id = @sup_id
                              AND IDWG <> @WG
                    );
             SELECT CAST(B.User_id AS INT) AS Id
             FROM @table2 A
                  RIGHT JOIN
             (
                 SELECT DISTINCT 
                        wg.User_id
                 FROM ccRIAWorkGroupUsers wg
                      LEFT JOIN ccUsers us ON wg.User_id = us.User_id
                 WHERE wg.IDWG = @WG
                       AND us.TipoUser_id = 1
             ) B ON A.userId = B.User_id
             WHERE A.userId IS NULL;
             RETURN 0;
     END;
     IF @type = 4 --Agents IDs by WG
         BEGIN
             SELECT CAST(wg.User_id AS INT) Id
             FROM ccRIAWorkGroupUsers wg
                  JOIN CCUsers u ON u.user_id = wg.user_id
                                    AND u.TipoUser_id = 1
             WHERE IDWG = @WG;
             RETURN 0;
     END;
     IF @type = 5 --Agents IDs by Campaign
         BEGIN
             SELECT DISTINCT
                    (CAST(U.User_id AS INT)) Id
             FROM ccRIACampEspWG camp
                  JOIN ccRIAWorkGroupUsers wg ON camp.IDWG = wg.IDWG
                  JOIN ccUsers U ON U.User_id = WG.User_id
                                    AND U.TipoUser_id = 1
             WHERE IdCampEsp = @campId
                   AND TIPO = @CampType;
             RETURN 0;
     END;
     IF @type = 6 -- Get Agent current state
         BEGIN
             WITH UserMaxFecha(User_id, fecha)
                  AS (SELECT User_id, MAX(fecha) AS fecha
                      FROM ccLogAgentesDia
                      WHERE fecha >= CONVERT(DATE, GETDATE())
                      GROUP BY User_id)
                  SELECT CASE WHEN CurrentState.currentStatus IS NULL
                                   OR CurrentState.currentStatus < 0 THEN 0
                         ELSE CAST(CurrentState.currentStatus AS INT)
                         END CurrentState
                  FROM ccUsers u
                       LEFT JOIN
                  (
                      SELECT A.User_id, B.currentStatus
                      FROM UserMaxFecha A
                           INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
                                                           AND A.fecha = B.fecha
                  ) CurrentState ON u.User_id = CurrentState.User_id
                  WHERE u.TipoUser_id = 1
                        AND u.User_id = @agent_id;
             RETURN 0;
     END;
     IF @type = 7 -- Get superuser id''s except root
         BEGIN
             DECLARE @superuserId AS INT;
             SET @superuserId =
             (
                 SELECT Rol_id
                 FROM ccRoles
                 WHERE Level = 7
             ); -- obtenemos el id del rol superusuario

             SELECT CAST(cr.User_id AS INT) User_id
             FROM ccUsers_Roles cr
             WHERE Rol_id = @superuserId
                   --AND cr.User_id NOT IN(1);
             RETURN 0;
     END;
     IF @type = 8 -- Get all Agent''s ID, Login and Full Names related to a workgroup
         BEGIN
             SET @dateStart = CONVERT(DATE, GETDATE());
             declare @wgIds table (wgId int primary key)

             insert into @wgIds
             select distinct value from dbo.fn_RIASplitDelimited(@workgroupIds,'','') 

             ;
             WITH wgAgt AS (
                SELECT DISTINCT 
                A.User_id, us.Login Username, --se agrega distinct porque el agente si puede estar en dos grupos de trabajo diferentes
                us.Nombres + '' '' + us.ApellidoPaterno + '' '' + us.ApellidoMaterno Name
                FROM ccRIAWorkGroupUsers A
                INNER JOIN ccusers us ON A.User_id = us.User_id
                inner join @wgIds w on w.wgId=A.IDWG
                WHERE us.TipoUser_id = 1
            ), lastState AS (
            SELECT user_id, MAX(fecha) dateStart
            FROM ccLogAgentesDia WITH(NOLOCK)
            WHERE fecha > @dateStart and User_id in(select [User_id] from wgAgt)
            GROUP BY user_id
            )
                  
            SELECT CONVERT(INT, us.User_id) AS Id, us.Username AS Username, us.Name
            , LastStateId = CASE WHEN B.currentStatus IS NULL OR B.currentStatus < 0 THEN 0
                ELSE B.currentStatus END
            FROM wgAgt us
            LEFT JOIN lastState A ON A.User_id = us.User_id
            LEFT JOIN ccLogAgentesDia B ON A.User_id = B.User_id AND A.dateStart = B.fecha;
             RETURN 0;
     END;
     ELSE
         IF @type = 9 -- GET AGENT IP
             BEGIN
                 SELECT publicIp
                 FROM ccPosicion with(nolock)
                 WHERE user_id = @agent_id;
                 RETURN 0;
         END;
         ELSE
             IF @type = 10 -- GET ONLINE AGENTS IP
                 BEGIN
                     SELECT CAST(user_id AS INT) AgentId, publicIp Ip
                     FROM ccPosicion
                     WHERE user_id <> 0;
                     RETURN 0;
             END;
     IF @type = 11
         BEGIN
             WITH UserMaxFecha(User_id, fecha)
                  AS (SELECT User_id, MAX(fecha) AS fecha
                      FROM ccLogAgentesDia
                      WHERE fecha >= CONVERT(DATE, GETDATE())
                      GROUP BY User_id)
                  SELECT CAST(u.User_id AS INT) AS UserId,
                                                   CASE WHEN CurrentState.currentStatus IS NULL
                                                             OR CurrentState.currentStatus < 0 THEN 0
                                                   ELSE CAST(CurrentState.currentStatus AS INT)
                                                   END CurrentState
                  FROM ccUsers u
                       LEFT JOIN
                  (
                      SELECT A.User_id, B.currentStatus
                      FROM UserMaxFecha A
                           INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
                                                           AND A.fecha = B.fecha
                  ) CurrentState ON u.User_id = CurrentState.User_id
                  WHERE u.TipoUser_id = 1
                        AND u.User_id IN
                  (
                      SELECT value
                      FROM dbo.fn_RIASplitDelimited(@AgentsIds, '','')
                  );
             RETURN 0;
     END;
     IF @type = 12
         BEGIN
             SET @dateStart = CONVERT(DATE, GETDATE());
             WITH lastState
                  AS (SELECT user_id, MAX(fecha) dateStart
                      FROM ccLogAgentesDia WITH(NOLOCK)
                      WHERE fecha > @dateStart
                      GROUP BY user_id),
                  currentState
                  AS (SELECT A.User_id,
                               CASE WHEN B.currentStatus IS NULL
                                         OR B.currentStatus < 0 THEN 0
                               ELSE B.currentStatus
                               END AS LastStateId
                      FROM lastState A
                           INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
                                                           AND A.dateStart = B.fecha)
                  SELECT CONVERT(INT, us.User_id) AS Id, us.Login Username, --se agrega distinct porque el agente si puede estar en dos grupos de trabajo diferentes
                  us.Nombres + '' '' + us.ApellidoPaterno + '' '' + us.ApellidoMaterno AS Name, ISNULL(B.LastStateId, 0) LastStateId
                  ,isnull(c.publicIp,''0.0.0.0'') as [Ip]
                  FROM ccusers us
                       LEFT JOIN currentState B ON us.User_id = B.User_id
                       left join ccposicion C on C.user_id=us.user_id
                  WHERE us.TipoUser_id = 1;
             RETURN 0;
     END;
     SET NOCOUNT ON;'
        EXEC(@sql);

        SET @process = 'Alter Sp ccsp_GalateaAdminRolesManagement se agrega CTE PermissionsTmp en lugar tabla temporal'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminRolesManagement]
    @action SMALLINT,
    @User_id VARCHAR(MAX)= '''',
    @subaction VARCHAR(50)= '''',
    @description VARCHAR(250)= '''',
    @keyJson VARCHAR(250)= '''',
    @active BIT= 1,
    @Roles_id VARCHAR(MAX)= '''',
    @Permissions_Id VARCHAR(MAX)= '''',
    @menus_id VARCHAR(250)= ''''
AS

BEGIN TRY
    BEGIN TRANSACTION;-- Inicia el bloque de la transaccion
    DECLARE @resultado varchar(50) = '''';
    DECLARE @returnValue SMALLINT;
    BEGIN
     IF @action = 1
        BEGIN
        IF @subaction = ''Permissions''
            BEGIN

            ;with PermissionsTmp as(
                
                SELECT DISTINCT
                       (rp.Permissions_id) as Permissions_id
                
                FROM ccUsers_Roles ur
                     INNER JOIN ccRoles_Permissions rp WITH(NOLOCK) ON rp.Rol_id = ur.Rol_id
                WHERE User_id = @User_id
            )
                SELECT p.Permissions_Id, 
                       p.KeyJson, 
                       p.Parent, 
                       p.Type, 
                       p.OrderGrl,
                       CASE
                           WHEN tp.Permissions_Id IS NOT NULL
                           THEN 1
                           ELSE 0
                       END AS State
                FROM ccPermissions p
                     LEFT JOIN PermissionsTmp tp WITH(NOLOCK) ON tp.Permissions_Id = p.Permissions_Id
                ORDER BY OrderGrl, 
                         Parent;


        END;
        IF @subaction = ''Roles''
            BEGIN
                SELECT r.Rol_id AS RolId, 
                       r.KeyJson, 
                       r.Description,
                       r.Level,
                       CONVERT(VARCHAR(10), r.CreateDate, 103) AS CreateDate,
                       CASE
                           WHEN ur.Rol_id IS NOT NULL
                           THEN 1
                           ELSE 0
                       END AS State,
                       STUFF(
                                (SELECT '', '' + CAST(ur.User_id AS varchar)
                                FROM ccUsers_Roles ur
                                INNER JOIN ccRoles C ON ur.Rol_id = C.Rol_id
                                WHERE c.Rol_id = r.Rol_id
                                FOR XML PATH ('''')),
                            1,2,'''')As Users_Ids,
                        STUFF(
                                (SELECT '', '' + CAST(pr.Permissions_Id AS varchar)
                                FROM ccRoles_Permissions pr
                                INNER JOIN ccRoles C ON pr.Rol_id = C.Rol_id
                                WHERE c.Rol_id = r.Rol_id
                                FOR XML PATH ('''')),
                            1,2,'''')As Permissions_ids
                FROM ccRoles r
                     LEFT JOIN ccUsers_Roles ur WITH(NOLOCK) ON r.Rol_id = ur.Rol_id
                                                                AND ur.User_id = @User_id AND ur.User_id = @User_id where r.Active=1
        END;
        IF @subaction = ''Users''
            BEGIN
                if exists (select * from ccUsers_Roles where User_id = @user_id and Rol_id = (select Rol_id from ccRoles where Level = 7)) --User super root
                begin
                    SELECT User_id, Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno AS Names
                    FROM ccUsers
                    WHERE TipoUser_id = 2 AND User_id > 1;
                end
                else
                begin 
                    declare @idArea int
                    set @idArea = (select IDArea from ccUsers where User_id = @User_id)
                    
                    SELECT User_id, Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno AS Names
                    FROM ccUsers
                    WHERE TipoUser_id = 2 AND User_id > 1 AND IDArea = @idArea
                end
        END;
    END;
    END;
    IF @action = 2
        BEGIN
            SELECT p.Permissions_id, 
                   Parent, 
                   Type, 
                   OrderGrl
            FROM ccUsers_Roles ur
                 INNER JOIN ccRoles r WITH(NOLOCK) ON r.Rol_id = ur.Rol_id
                 INNER JOIN ccRoles_Permissions rp WITH(NOLOCK) ON rp.Rol_Id = ur.Rol_id
                 INNER JOIN ccPermissions p WITH(NOLOCK) ON p.Permissions_id = rp.Permissions_id
            WHERE ur.User_Id = @User_id
                  AND r.Active = 1
                  AND p.Active = 1;
    END;
    IF @action = 3 -- assign roles to user
        BEGIN
            IF OBJECT_ID(''tempdb..#Users_Ids'') IS NOT NULL DROP TABLE #Users_Ids
            IF OBJECT_ID(''tempdb..#Users_split'') IS NOT NULL DROP TABLE #Users_split
            IF OBJECT_ID(''tempdb..#Roles_split'') IS NOT NULL DROP TABLE #Roles_split
            
            SELECT value
            INTO #Users_split
            FROM fn_RIASplitDelimited(@User_id, '','')

            SELECT value
            INTO #Roles_split
            FROM fn_RIASplitDelimited(@Roles_id, '','')

            SELECT DISTINCT(User_id)
            INTO #Users_Ids
            FROM ccUsers_Roles
            WHERE User_id in (SELECT value FROM #Users_split)

            IF @subaction = ''NewRelate''
            BEGIN
                IF EXISTS( select top 1 * from #Users_Ids)
                    BEGIN
                        DELETE ccUsers_Roles
                        WHERE User_id IN (select * from #Users_Ids);
                    END
                END
            IF @Roles_id <> ''''
            BEGIN
                INSERT INTO ccUsers_Roles
                select a.value User_id,b.value as Rol_id from #Users_split a
                CROSS JOIN #Roles_split b

            END
            SET @returnValue = (select top 1 * from  #Users_split)
    END;
    IF @action = 4 -- Delete Roles
        BEGIN
            IF OBJECT_ID(''tempdb..#UsersIds'') IS NOT NULL DROP TABLE #UsersIds
            SET @resultado = STUFF(
                    (SELECT Distinct('', '' + CAST(ur.User_id AS varchar))
                    FROM ccUsers_Roles ur
                    INNER JOIN ccRoles C ON ur.Rol_id = C.Rol_id
                    WHERE c.Rol_id in (SELECT value FROM fn_RIASplitDelimited(@Roles_id, '',''))
                    FOR XML PATH ('''')),
                1,2,'''')
            IF OBJECT_ID(''tempdb..#roles_permissions'') IS NOT NULL DROP TABLE #roles_permissions
            IF OBJECT_ID(''tempdb..#Users_Roles'') IS NOT NULL DROP TABLE #Users_Roles

            SELECT DISTINCT(Rol_id)
            INTO #roles_permissions
                FROM ccroles_permissions a
                        INNER JOIN
                (
                    SELECT value
                    FROM fn_RIASplitDelimited(@Roles_id, '','')
                ) b ON b.value = a.Rol_Id

            SELECT  DISTINCT(value) AS Rol_id
            INTO #Users_Roles
            FROM fn_RIASplitDelimited(@Roles_id, '','') a
                    INNER JOIN ccUsers_Roles b ON b.Rol_id = a.Value
            WHERE b.Rol_id IS NOT NULL
            IF EXISTS(SELECT TOP 1 * FROM #roles_permissions)
            BEGIN
                --select * from #roles_permissions
                DELETE ccroles_permissions WHERE Rol_id in (select Rol_id from #roles_permissions )
            END
            IF EXISTS(SELECT TOP 1 * FROM #Users_Roles)
            BEGIN
                --select * from #Users_Roles
                DELETE ccUsers_Roles WHERE Rol_id in (select Rol_id from #Users_Roles )
            END
            IF EXISTS(select top 1 Rol_id from ccRoles where Rol_id in (SELECT  DISTINCT(value) FROM fn_RIASplitDelimited(@Roles_id, '','')))
            BEGIN
                --select * from ccRoles where Rol_id in (SELECT  DISTINCT(value) FROM fn_RIASplitDelimited(@Roles_id, '',''))
                DELETE ccRoles WHERE Rol_id in (SELECT  DISTINCT(value) FROM fn_RIASplitDelimited(@Roles_id, '',''))
                IF(@resultado IS NULL OR @resultado = '''') SET @resultado = ''1''
            END
        END;
    IF @action = 5 -- New Role
        BEGIN
            IF @menus_id <> ''''
               OR @Permissions_Id <> ''''
                BEGIN
                    DECLARE @exists BIT;
                    SET @returnValue = 0;
                    SET @exists = 1;

                    /*IF @menus_id <> '''' --Check if role with same menus exists
                        BEGIN
                            Para cuando esten los menus
                        END*/

                    IF @Permissions_Id <> ''''
                       AND @exists = 1 --Check if role with same permissions exists
                        BEGIN
                            IF NOT EXISTS
                            (
                                SELECT c.Rol_Id
                                FROM ccroles_permissions a
                                     INNER JOIN
                                (
                                    SELECT value
                                    FROM fn_RIASplitDelimited(@Permissions_Id, '','')
                                ) b ON b.value = a.Permissions_Id
                                     INNER JOIN
                                (
                                    SELECT Rol_id, 
                                           COUNT(*) AS contador
                                    FROM ccRoles_Permissions
                                    GROUP BY Rol_Id
                                ) AS c ON c.Rol_id = a.Rol_id
                                     INNER JOIN
                                (
                                    SELECT COUNT(*) AS contador
                                    FROM fn_RIASplitDelimited(@Permissions_Id, '','')
                                ) d ON d.contador = c.contador
                                GROUP BY c.Rol_Id
                                HAVING COUNT(*) =
                                (
                                    SELECT COUNT(*) AS contador
                                    FROM fn_RIASplitDelimited(@Permissions_Id, '','')
                                )
                            )
                                SET @exists = 0;
                    END;
                    IF @exists = 0 -- IF not exist role with same menus and permissions create
                        BEGIN
                            SELECT @exists = COUNT(*)
                            FROM ccRoles
                            WHERE Description = @description;
                            IF @exists = 0
                                BEGIN
                                    DECLARE @newRoleId INT;
                                    INSERT INTO ccroles
                                    (Description, 
                                     KeyJson, 
                                     CreateDate, 
                                     Active,
                                     Level
                                    )
                                    VALUES
                                    (@description, 
                                     @keyJson, 
                                     GETDATE(), 
                                     @active,
                                     1001
                                    );
                                    SELECT @newRoleId = SCOPE_IDENTITY();
                                    IF @Permissions_Id <> ''''
                                        BEGIN
                                            INSERT INTO ccroles_permissions
                                                   SELECT @newRoleId, 
                                                          value
                                                   FROM fn_RIASplitDelimited(@Permissions_Id, '','') AS a
                                                        INNER JOIN ccPermissions b ON a.value = b.Permissions_Id
                                                   GROUP BY value;
                                    END;
                                    SET @returnValue = @newRoleId; --  if new role was created return Role_id
                            END;
                                ELSE
                                BEGIN
                                    SET @returnValue = -1;
                            END;-- else if role name exists, return -1
                    END;
                    --SELECT @returnValue; --  else if exists role with same menus & permissions, return 0
            END;
    END;
    COMMIT TRANSACTION;
    if @resultado <>''''
    begin
        select @resultado
    end
    else
    begin
    -- Indica que la operación se efectuo correctamente
        SELECT @returnValue
    end
END TRY

/* Manejo de error de la transacción */

BEGIN CATCH
    SET @returnValue = -1;
    SELECT @returnValue
    ROLLBACK TRANSACTION;
END CATCH;
        '
        EXEC(@sql);

        SET @process = 'Alter SP ccsp_GalateaAreas se agrega if @option = 2 borrar la tabla #Areas'
        SET @sql = 'ALTER procedure [dbo].[ccsp_GalateaAreas] 
    @option int = 2,
    @IDArea smallint = 0,
    @Descripcion varchar(40) = NULL,
    @maxMails smallint = 3,
    @maxChats smallint = 3,
    @maxTweets smallint = 3,
    @defCampaing smallint = 0,
    @movesfromArea bit = 0,
    @userId int = NULL,
    @groupAreas varchar (MAX) = NULL,
    @toolsTransfer tinyint = NULL
AS

SET NOCOUNT ON;
    
    declare @opt int = @option -1
    
    DECLARE @userLogin as varchar(40);
    SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @userId);

    if @option = 1 --Superuser info
    begin
        create table #campsIds(
            id int,
            cadena varchar(max)
        )
            
        declare @sql varchar(max),@idPivots varchar(max),@idConcat varchar(max)
            
        set @idPivots =''''
        set @idConcat=''''
            
        select @idPivots=@idPivots+Id+'','',
            @idConcat=@idConcat+''case when ''+id+'' is not null then convert(varchar(max),''+ id+'') + '''','''' else '''''''' end + 
            ''
            from (
            select distinct ''[''+convert(varchar(max),cam_id)+'']'' as Id from ccCamps   
            )x
            
        set @idPivots =SUBSTRING(@idPivots,0,len(@idPivots))
        set @idConcat =SUBSTRING(@idConcat,0,len(@idConcat)-7)
            
        set @sql=''
            select IDArea,''+@idConcat+'' from 
            (   select IDArea, cam_id from ccCamps) as T
            PIVOT (
            max(cam_id) for cam_id in (''+@idPivots+'') ) as P''

        insert into #campsIds
        exec(@sql)
            
        select a.IDArea Id, 
            a.AreaName Name, 
            a.StatusArea Status, 
            a.maxMails Mails, 
            a.maxChats Chats, 
            a.maxTweets Tweets, 
            a.CreateDate as CreateDate,         
            ISNULL(b.cadena, 0) as CampaignIds  
        from ccRIACat_Areas a --Falta el datetime 
        left join #campsIds b on a.IDArea = b.id

        drop table #campsIds
    end
    if @option = 2 -- Select de las areas
    begin
        IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
        Create table #Areas(
            IDArea smallint,
            AreaName varchar(MAX),
            maxChats tinyint ,
            maxMails tinyint ,
            users int,
            admins int,
            camps int,
            acds int,
            maxTweets tinyint,
            toolsTransfer tinyint
        )
        insert into #Areas
        EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@defCampaing=@defCampaing, @isKolob=1
        select a.*,rca.CreateDate,Isnull(rca.defCampaing,0) as defCampaing
        from #Areas a
        inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea

        IF OBJECT_ID(''tempdb..#Areas'') IS NOT NULL DROP TABLE #Areas;
    end
    if @option = 3 -- Insert new area
    begin
    IF OBJECT_ID(''tempdb..#InsertAreas'') IS NOT NULL DROP TABLE #InsertAreas;
        Create table #InsertAreas(
            result int,
            idAreas decimal
        )
        insert into #InsertAreas
        EXEC ccsp_RIA_ABCAreas 
            @option = @opt,
            @IDArea=@IDArea,
            @Descripcion=@Descripcion,
            @maxMails=@maxMails,
            @maxChats=@maxChats,
            @maxTweets=@maxTweets,
            @defCampaing=@defCampaing,
            @toolsTransfer=@toolsTransfer
        if (select result from #InsertAreas) = 1
            begin

                --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD AL CREAR UN AREA
                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@Descripcion, getDate(), @userLogin, 17, 3, '''', '''', @Descripcion);

                if(@movesfromArea = 1) begin
                    Update ccUsers set IDArea = (select idAreas from #InsertAreas), status = 1 where User_id = @userId
                end
            end
        Select * from #InsertAreas
    end
    if @option = 4 -- Delete Areas
    begin
        IF OBJECT_ID(''tempdb..#AreasDelete'') IS NOT NULL DROP TABLE #AreasDelete;
        SELECT value As IDArea into #AreasDelete FROM fn_RIASplitDelimited(@groupAreas, '','')
        
        
        if (exists(select IDArea from ccUsers where IDArea=(Select top 1 IDArea from #AreasDelete)) or exists(select IDArea from ccCamps where IDArea = (Select top 1 IDArea from #AreasDelete))
          or exists(select IDArea from ccInbound where IDArea=(Select top 1 IDArea from #AreasDelete))) and (select valor from ccSettings where setting_id=95)<>1
        BEGIN
            Select -1 as result
        END
        ELSE
        BEGIN
            declare @DWorkGroups as varchar(500)
            insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG)
            select user_id,cam_id,prioridad,skill,rel_id,IDWG
            from ccCampsAgente
            where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG)
            select user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG
            from ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            Delete ccCampsAgente where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))
            Delete ccInboundAgentes where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored)
            select user_id,cam_id,tipo,IDWG,monitored
            from ccSupervisorCam
            where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            Delete ccSupervisorCam where user_id in (select user_id from ccusers with(index(PK_ccUsers)) where IDArea in (Select IDArea from #AreasDelete))

            delete ccoDialerCamp where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
            delete ccoWorkingTable where cam_id in (select cam_id from ccCamps with(index(PK_ccCamps)) where IDArea in (Select IDArea from #AreasDelete))
            delete ccoWorkingTable where callout_id in (select callout_id from ccoCallsOutSource with(index(IX_ccoCallsOutSource_1))
            where cam_id in (select cam_id from ccCamps where IDArea in (Select IDArea from #AreasDelete)))

            Delete ccInboundHorarios Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))
            Delete ccInboundMsgs Where Inbound_id in (select Inbound_id from ccInbound with(index(PK_ccInbound)) where IDArea in (Select IDArea from #AreasDelete))

            Delete from ccRIAWorkGroupUsers where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
            Delete from ccRIACat_WorkGroup where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))
            Delete from ccRIACampEspWG where IDWG in (select IDWG from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete))

            select @DWorkGroups = coalesce(@DWorkGroups + '''','''', '''') + CAST(IDWG as varchar(40)) FROM ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)
            Delete from ccRIAAreaWorkGroup where IDArea in (Select IDArea from #AreasDelete)

            if (select valor from ccSettings where setting_id=95)=1
            begin
            Update ccInbound set IDArea=NULL, status=0 where IDArea in (Select IDArea from #AreasDelete)
            Update ccCamps set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
            Update ccUsers set IDArea=NULL where IDArea in (Select IDArea from #AreasDelete)
            end

            Update ccRIACat_Areas set StatusArea=0 where IDArea in (Select IDArea from #AreasDelete)

            --INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA AREA ELIMINADA
            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
            SELECT AreaName, getDate(), @userLogin, 19, 3, '''', '''', AreaName
            FROM ccRIACat_Areas 
            WHERE IDArea in (Select IDArea from #AreasDelete);

            select 1 as result
        END
    end
    if @option = 5 -- update Areas
    begin
        if exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion and IDArea <> @IDArea)
            begin
                select -1 as result
                return
            end
        else
            begin

                --INICIO - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

                DECLARE @PrevDescription AS VARCHAR(50);
                DECLARE @SelectedArea AS VARCHAR(10) = CAST(@IDArea AS varchar(10));

                SELECT @PrevDescription = AreaName
                FROM ccRIACat_Areas 
                WHERE IDArea = @IDArea;

                EXEC InsertLogAdminGalatea @action=1, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                DECLARE @AreasTable TABLE 
                (
                    columnInfo VARCHAR(255),
                    dataInfo VARCHAR(255),
                    identifierInfo VARCHAR(255)
                )

                update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=isnull(@defCampaing, 0), ToolsTransfer=case when @toolsTransfer = 3 then ToolsTransfer else @toolsTransfer end where IDArea=@IDArea

                INSERT INTO @AreasTable EXEC InsertLogAdminGalatea @action=2, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId;

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                SELECT 
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                    ELSE '''' END,
                    getDate(), 
                    @userLogin, 
                    18, 
                    3, 
                    AT.identifierInfo,
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @Descripcion
                            WHEN AT.identifierInfo = ''T&SET_CAMPAIGN'' THEN 
                                CASE 
                                    WHEN @defCampaing IS NOT NULL AND @defCampaing <> 0 THEN
                                        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @defCampaing)
                                    ELSE ''T&COMMON_NONE'' END
                            WHEN AT.identifierInfo = ''T&SET_TOOLSTRANSFER'' THEN
                                CASE
                                    WHEN @toolsTransfer = 1 THEN ''COMMON_ENABLED''
                                    ELSE ''COMMON_DISABLED'' END
                            ELSE AT.dataInfo END
                    ELSE '''' END, 
                    CASE WHEN AT.identifierInfo IS NOT NULL THEN
                        CASE 
                            WHEN AT.identifierInfo = ''T&EDIT_NAME'' THEN @PrevDescription ELSE isNull(@Descripcion, @PrevDescription) END
                    ELSE '''' END
                FROM @AreasTable AS AT;

                EXEC InsertLogAdminGalatea @action=3, @tableName=''ccRIACat_Areas'', @columnNameId=''IDArea'', @valueId=@SelectedArea, @userId= @userId

                --FIN - INSERTA UN REGISTRO EN EL HISTORIAL DE ACTIVIDAD POR CADA PROPIEDAD EDITADA*******

            end
        if @maxChats is not null
            begin
                Update ccinbound set maxChats=@maxChats where IDArea=@IDArea
            end
        if @movesfromArea = 1
        Begin
            Update ccUsers set IDArea = @IDArea, status = 1 where User_id = @userId
        End
        select 1 as result
    end
SET NOCOUNT ON;'
        EXEC(@sql);

        SET @process = 'Alter SP ccsp_GalateaLoadWorkGroup #Relations se pone para que elimine las tabla temporal '
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaLoadWorkGroup]
@Option smallint,
@areaId int
as
declare @agentes varchar(max)
declare @admins varchar(max)
declare @campsIn varchar(max)
declare @campsOut varchar(max)
declare @wgs varchar(max)
declare @count int
declare @id int
declare @wg int

if @option =1 --Obtiene las relaciones de los WG de una area
begin

    IF OBJECT_ID(''tempdb..#Relations'') IS NOT NULL DROP TABLE #Relations;

    SELECT 
    ROW_NUMBER() OVER(ORDER BY idWG ASC) AS Row,
    IDWG,@agentes as agents,@admins as admins,@campsIn as campsIn,@campsOut as campsOut
    into #Relations
    FROM ccRIAAreaWorkGroup 
    WHERE IDArea = @areaId;

    if not exists(select * from ccRIACat_Areas where IDArea = @areaId) or (select count(idWG) from #Relations) = 0
    begin
        select Null as IDWG ,@agentes as agents, @admins as admins, @campsIn as campsIn, @campsOut as campsOut, @wgs as idsWg
        return (0)
    end

    select @count = count(idWG) from #Relations
    set @id =1
    while @id<=@count
    begin
        select @wg =idwg from #Relations where Row =@id
        select @agentes=null, @admins=null,@campsIn=null,@campsOut=null
        select @agentes = coalesce(@agentes + '','', '''') +  convert(varchar(12),wgu.user_id)
        from ccUsers u inner join ccRIAWorkGroupUsers wgu on wgu.User_id = u.User_id
        where TipoUser_id = 1 and u.IdArea = @areaId and wgu.IDWG =@wg
        order by u.user_id

        select @admins = coalesce(@admins + '','', '''') +  convert(varchar(12),u.user_id)
        from ccUsers u inner join ccRIAWorkGroupUsers wgu on wgu.User_id = u.User_id
        where u.TipoUser_id > 1 and u.IdArea = @areaId  and wgu.IDWG =@wg
        order by u.user_id

        select @campsIn = coalesce(@campsIn + '','', '''') +  convert(varchar(12),inbound_id)
        from ccInbound i inner join ccRIACampEspWG wg on wg.IdCampEsp =i.Inbound_id
        where IdArea = @areaId  and wg.IDWG = @wg and wg.Tipo=0
        order by inbound_id
    
        select @campsOut = coalesce(@campsOut + '','', '''') +  convert(varchar(12),cam_id)
        from ccCamps c inner join ccRIACampEspWG wg on wg.IdCampEsp = c.cam_id
        where IdArea = @areaId and wg.IDWG = @wg and wg.Tipo=1
        order by cam_id

        Update #Relations set agents= @agentes, admins=@admins, campsIn = @campsIn, CampsOut = @campsOut where IDWG= @wg
        set @id=@id+1
    end
    select Cast(IDWG as varchar(10)) as idwg,agents,admins,campsIn,CampsOut from #Relations
    IF OBJECT_ID(''tempdb..#Relations'') IS NOT NULL DROP TABLE #Relations;
end'
        EXEC(@sql);

        
        SET @process = 'Alter SP configuraIdiomaCatalogosEspañol Agregando estado de email(34) y Whatsapp(36)'
        SET @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEspañol] AS
SET NOCOUNT ON

Print ''Iniciando proceso de configuracion en Español''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Semana'' collate SQL_Latin1_General_CP1_CI_AS), 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Nocturno'' collate SQL_Latin1_General_CP1_CI_AS), 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS), 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''No Clasificado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Break'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Tocador'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Con Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Aclaracion'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Junta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Comida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Sistemas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))

DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
delete from [dbo].[ccStatusLLamada]

INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, convert(text, N''Inicial'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, convert(text, N''Fuera de Horario'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, convert(text, N''Fuera de Servicio'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, convert(text, N''Sin Agentes Firmados'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, convert(text, N''En espera'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, convert(text, N''Colgada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, convert(text, N''Desborde por Tiempo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, convert(text, N''Desborde por Cantidad'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, convert(text, N''Con Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, convert(text, N''Asignada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, convert(text, N''Asignada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, convert(text, N''Atendida Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, convert(text, N''Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, convert(text, N''Cancelada Mensaje'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, convert(text, N''Asignada y No Contestada'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, convert(text, N''Asignada y Toma Linea'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (18, convert(text, N''Abandonada (Reminder)'' collate SQL_Latin1_General_CP1_CI_AS))
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8, 18 )

Print ''Estableciendo los tipos de dias''
truncate table [dbo].[ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo resultados de marcacion''
delete from [dbo].[ccTipoResultadoDial]

INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, convert(text, N''Contestan'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, convert(text, N''Ocupado'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, convert(text, N''No Contesta'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, convert(text, N''Fax/Modem'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, convert(text, N''NoDialTone'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, convert(text, N''Otro'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, convert(text, N''NoService'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, convert(text, N''Buzon/Maquina'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, convert(text, N''Congestion'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, convert(text, N''Cancelado'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de estado de los agentes''
Delete [dbo].[ccTipoStatusAgente]

INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, convert(text, N''LogOut'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, convert(text, N''Desconocido'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, convert(text, N''No Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, convert(text, N''Disponible'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, convert(text, N''Dialogo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, convert(text, N''Transferencia'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, convert(text, N''Notas'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, convert(text, N''Otra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, convert(text, N''Cliente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, convert(text, N''Ringing'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, convert(text, N''Problema'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, convert(text, N''Espera llamada manual'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, convert(text, N''Transferencia Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, convert(text, N''Ringing Fallida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, convert(text, N''ReconnectKolob'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, convert(text, N''Ready PreviewPro'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (32, convert(text, N''Preview'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (33, convert(text, N''Asistida'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (34, convert(text, N''Dialogo de Whatsapp'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (35, convert(text, N''Inactivo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (36, convert(text, N''En diálogo Correo'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, convert(text, N''Agente'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, convert(text, N''Supervisor'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, convert(text, N''AVRS Calidad'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
DBCC CHECKIDENT (''[ccDias]'', RESEED, 0)
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, convert(text, N''Domingo'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, convert(text, N''Lunes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, convert(text, N''Martes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, convert(text, N''Miercoles'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, convert(text, N''Jueves'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, convert(text, N''Viernes'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, convert(text, N''Sabado'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccDias] OFF

Print ''Estableciendo los tipos de llamada''
delete from [dbo].cstoTarifa
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''LD nacional'',''12'',''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Cel'',''13'',''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''Cel LD'',''13'',''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''LD USA'',''13'',''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''LD inter'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''LADA local 2 dígitos'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''Local lada 3 digitos'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''Local lada 4 digitos'',''6'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''Cel LADA local 2 dígitos'',''10'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''Cel LADA local 3 dígitos'',''9'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''Cel LADA local 4 dígitos'',''8'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Larga distancia'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Cel larga distancia'',''13'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Celular'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''LD Nacional'',''11'',''1%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''LD Nacional'',''10'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Celular'',''11'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Cel'',''11'',''07%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''LD inter'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''LD anterior'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Cel'',''10'',''05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''LD actual'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''LD inter'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''LD inter'',''0'',''0011%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Cel'',''10'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Movil '',''8'',''6%|7%|8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''Celular 9 dígitos '',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''LD Nacional'',''10'',''02%|03%|04%|05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''Cel LD nacional'',''10'',''06%|07%|08%|09%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''Cel LD nacional 9 dígitos'',''11'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''LD internacional'',''19'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Movil'',''8'',''3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''LD Nacional'',''8'',''7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''LD internacional'',''8'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''Telefonía SIP'',''8'',''4%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Telefonía móvil'',''8'',''5%|6%|7%|8%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Cobro Revertido'',''10'',''800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Tarifa Prima'',''10'',''90%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Acceso Internet'',''10'',''900%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Especial'',''0'',''08%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Fijo'',''8'',''2%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Movil'',''8'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Celular'',''9'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''LD internacional'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Servicios web'',''9'',''5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''LD nacional'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Cel'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''LD inter'',''0'',''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, convert(text, N''Lista Negra en Carga de Registros'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, convert(text, N''Eliminado por Aplicar Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, convert(text, N''Eliminado de Lista Negra por Remplazo '' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, convert(text, N''Borrado de Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, convert(text, N''Agregado por calificación por campaña'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, convert(text, N''Carga Lista Negra'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, convert(text, N''Carga Registro Cliente Lista Negra''collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (9, convert(text, N''Agregado por calificación por ACD'' collate SQL_Latin1_General_CP1_CI_AS))
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, convert(text, N''Solicita información general'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, convert(text, N''Se cortó la llamada'' collate SQL_Latin1_General_CP1_CI_AS), 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, convert(text, N''Número equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, convert(text, N''Gestión Efectiva'' collate SQL_Latin1_General_CP1_CI_AS), 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, convert(text, N''Se deja recado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, convert(text, N''Numero Equivocado'' collate SQL_Latin1_General_CP1_CI_AS), 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [dbo].[cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telmex'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Maxcom'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Avantel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''AT&T'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telnor'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Axtel'')
INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Telular'')

Print ''Mensajes voz default''
DELETE [dbo].[ccMsgFiles]
DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default5'', ''Mensaje Bienvenida'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default4'', ''Mensaje Transferencia'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default3'', ''Mensaje Fuera de servicio'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default2'', ''Mensaje Fuera de horario'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default1'', ''Mensaje En espera'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default7'', ''Mensaje Sin agentes firmados'' )
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default9'', ''Mensaje VoiceMail'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default10'', ''Mensaje Desborde'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_Sp\Default11'', ''Lista Negra'')


Print ''Mensajes default chat''
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default5'', ''!Bienvenido!'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default3'', ''El servicio no se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default2'', ''Nuestro horario de atención ha terminado'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default1'', ''Por favor espere mientras uno de nuestros agentes se encuentra disponible'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default7'', ''No hay agentes disponibles'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default10'', ''No podemos tomar su solicitud'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default12'', ''La sesión de chat ha estado inactiva mucho tiempo'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_Sp\Default13'', ''La sesión de chat ha concluido'')'
        EXEC(@sql);

        SET @process = 'Alter SP configuraIdiomaCatalogosEnglish Agregando estado de email(34) y Whatsapp(36)'
		SET @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosEnglish]
AS
Print ''Iniciando proceso de configuracion en Ingles''

Print ''Estableciendo Horarios''
Delete [ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Week'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Night shift'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Saturday'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sunday'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [ccTipoNotReady]
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Not Clasified'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Break'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Bathroom'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''With client'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Clarification'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Meeting'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Lunch'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Systems'')
INSERT [ccTipoNotReady] ([Descripcion]) VALUES (''Other'')


DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
delete from [ccStatusLLamada]

INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Initial'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Out of Schedule'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Out of Service'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''No Agents Logged in'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''On Hold'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandoned'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Time overflow'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Queue size overflow'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''With Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10, ''Assigned Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11, ''Assigned'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12, ''Attended Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (13, ''Answered'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (14, ''Canceled Message'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (15, ''Assigned and Not Answered'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (16, ''Assigned and took line'')
INSERT [ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (18, ''Abandoned (Reminder)'')
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8, 18 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [ccTipoDias]
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''Monday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''Tuesday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''Wednesday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''Thursday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''Friday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''Saturday'')
INSERT [ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''Sunday'')

Print ''Estableciendo resultados de marcacion''
delete from [ccTipoResultadoDial]

INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Answer'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Busy'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Not Answer'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax/Modem'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Other'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10, ''NoService'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11, ''VoiceMail/Machine'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12, ''Circuit busy'')
INSERT [ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13, ''Cancelled'')

Print ''Estableciendo los tipos de estado de los agentes''
DELETE [ccTipoStatusAgente]

INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Unknown'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Ready'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Talking'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transfer'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Other'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Client'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Ringing'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11, ''Problem'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21, ''Wait for manual call'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, ''Xfer Fail'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, ''Ringing Fail'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, ''ReconnectKolob'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, ''Ready PreviewPro'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (32, ''Preview'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (33, convert(text, N''Assisted'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (34, convert(text, N''Whatsapp Dialog'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (35, convert(text, N''Idle'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (36, convert(text, N''Engaged Email'' collate SQL_Latin1_General_CP1_CI_AS))

Print ''Estableciendo los tipos de usuario''
Delete [ccTipoUsers]
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agent'')
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
INSERT [ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''AVRS Access'')

Print ''Estableciendo los dias''
Delete [ccDias]
DBCC CHECKIDENT (''[ccDias]'', RESEED, 0)
SET IDENTITY_INSERT [ccDias] ON
INSERT [ccDias] ([dia_id], [Name]) VALUES (1, ''Sunday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (2, ''Monday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (3, ''Tuesday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (4, ''Wednesday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (5, ''Thursday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (6, ''Friday'')
INSERT [ccDias] ([dia_id], [Name]) VALUES (7, ''Saturday'')
SET IDENTITY_INSERT [ccDias] OFF

Print ''Estableciendo los tipos de llamada''
delete from cstoTarifa
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''National LD'',''12'',''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Mobile'',''13'',''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''LD Mobile'',''13'',''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''USA LD'',''13'',''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''Inter LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''2-digit Local Area Code'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''3-digit Local Area Code'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''4-digit Local Area Code'',''6'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''2-digit Local Mobile Area Code'',''10'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''3-digit Local Mobile Area Code'',''9'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''4-digit Local Mobile Area Code'',''8'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Long Distance'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Long Distance Mobile'',''13'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Mobile'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''National LD'',''11'',''1%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''National LD'',''10'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Mobile'',''11'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Mobile'',''11'',''07%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''Inter LD'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''Old LD'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Mobile'',''10'',''05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''New LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''Inter LD'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''Inter LD'',''0'',''0011%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Mobile'',''10'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Mobile '',''8'',''6%|7%|8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''9-digit Mobile'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''National LD'',''10'',''02%|03%|04%|05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''National Mobile LD'',''10'',''06%|07%|08%|09%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''9-digit National Mobile LD'',''11'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''International LD'',''19'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Mobile'',''8'',''3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''National LD'',''8'',''7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''International LD'',''8'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''SIP Telephony'',''8'',''4%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Mobile Telephony'',''8'',''5%|6%|7%|8%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Reverse Charge'',''10'',''800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Premium Rate'',''10'',''90%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Internet Access'',''10'',''900%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Special'',''0'',''08%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Landline'',''8'',''2%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Mobile'',''8'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Mobile'',''9'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Webservices'',''9'',''5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''National LD'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Mobile'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''Inter LD'',''0'',''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [ccTipoMovsListaNegra]
SET IDENTITY_INSERT [ccTipoMovsListaNegra] ON
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Added to black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Blocked on loading'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removed from campaign'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Replaced from black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Deleted from black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Added by Disposition'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Load black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Load customer black list'')
INSERT [ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (9, ''Added by Inbound Disposition'')
SET IDENTITY_INSERT [ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [ccTipoCalif]
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Wrong area'', 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Disconnected call'', 0)
INSERT [ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong number'', 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [ccTipoCalifOUT]
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Effective call'', 0, 0, 1)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Leave a message'', 0, 1, 2)
INSERT [ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong number'', 0, 1, 3)

Print ''Estableciendo proveedores''
Delete [cstoProvedor]
DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
INSERT [cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes an individual message to agent'' where TipoMsgChat=1
Update ccRIAChat_TipoMsg set MsgDetalle=''Agent writes a message to Administrator'' where TipoMsgChat=2
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrator writes a global message'' where TipoMsgChat=3

Print ''Mensajes default''
DELETE [ccMsgFiles]
DBCC CHECKIDENT (''[ccMsgFiles]'', RESEED, 0)
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Welcome message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Transfer message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Out of service message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''After hours message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''In queue message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''No agents signed in message'' )
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''VoiceMail message'')
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Overflow message'')
INSERT [ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''DNC list'')

Print ''Mensajes default chat''
DELETE [ccRIAChatInboundMsgs]
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Welcome!'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Service currently unavailable'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Our schedule service has finished'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Please hold while one of our agents is available'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''There are not available agents'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Your request can not be processed'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Chat session has been inactive for too long'')
INSERT [ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Chat session has finished'')';
		EXEC(@sql);

        SET @process = 'Alter SP configuraIdiomaCatalogosPortugues Agregando estado de email(34) y Whatsapp(36)'
		SET @sql = 'ALTER PROCEDURE [dbo].[configuraIdiomaCatalogosPortugues]
AS
Print ''Iniciando proceso de configuracion en Portugues''

Print ''Estableciendo Horarios''
Delete [dbo].[ccHorarios]
DBCC CHECKIDENT (''[ccHorarios]'', RESEED, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Semana'', 7, 0, 21, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Noite'', 21, 0, 23, 0, 1, 1, 1, 1, 1, 0, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Sabado'', 8, 0, 20, 0, 0, 0, 0, 0, 0, 1, 0)
INSERT [dbo].[ccHorarios] ([Descripcion], [HoraInicio], [MinInicio], [HoraFin], [MinFin], [Lunes], [Martes], [Miercoles], [Jueves], [Viernes], [Sabado], [Domingo]) VALUES (''Domingo'', 8, 0, 14, 0, 0, 0, 0, 0, 0, 0, 1)

Print ''Estableciendo Not Ready y graficas''
Delete [ccRIANotReadyGraph]
Delete [dbo].[ccTipoNotReady] 
Delete [ccRIAGraphics]

DBCC CHECKIDENT (''[ccTipoNotReady]'', RESEED, 0)
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Não Clasified'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Pausa'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Casa de banho'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Com o cliente'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Supervisor'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Esclarecimento'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Reunião'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Almoço'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Sistemas'')
INSERT [dbo].[ccTipoNotReady] ([Descripcion]) VALUES (''Outros '')

--EXEC sp_generate_inserts ''ccRIANotReadyGraph''
DBCC CHECKIDENT (''[ccRIAGraphics]'', RESEED, 0)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(16,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(17,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(18,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(19,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(20,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(21,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(22,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(23,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(24,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(25,1)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(1,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(2,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(3,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(4,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(5,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(6,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(7,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(8,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(9,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(10,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(11,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(12,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(13,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(14,4)
INSERT INTO [ccRIAGraphics] ([frame],[type_id])VALUES(15,4)

INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(1,26)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(2,27)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(3,28)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(4,29)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(5,30)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(6,31)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(8,32)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(9,33)
INSERT INTO [ccRIANotReadyGraph] ([TipoNotReady_id],[graphic_id])VALUES(10,36)

Print ''Estableciendo Status de llamadas''
TRUNCATE TABLE [dbo].[ccStatusLLamada]
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (1, ''Inicial'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (2, ''Fora da agenda'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (3, ''Fora de serviço'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (4, ''Não há agentes conectados'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (5, ''Em espera'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (6, ''Abandonado'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (7, ''Tempo de transbordo'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (8, ''Tamanho da fila de transbordo'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (9, ''Com Mensagem'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (10,''Mensagem atribuída'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (11,''Atribuído'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12,''Mensagem compareceram'')
INSERT [dbo].[ccStatusLLamada] ([statusCall_id], [descripcion]) VALUES (12,''Abandonada (Reminder)'')
update ccStatusLLamada set inAbandonConfig=1 where statusCall_id in (2, 3, 4, 6, 7, 8, 18 )

Print ''Estableciendo los tipos de dias''
TRUNCATE TABLE [dbo].[ccTipoDias]
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (1, ''segunda-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (2, ''terça-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (3, ''quarta-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (4, ''quinta-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (5, ''sexta-feira'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (6, ''sábado'')
INSERT [dbo].[ccTipoDias] ([dia_id], [descripcion]) VALUES (7, ''domingo'')

Print ''Estableciendo resultados de marcacion''
TRUNCATE TABLE [dbo].[ccTipoResultadoDial]
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (1, ''Resposta'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (2, ''Ocupado'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (3, ''Não resposta'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (4, ''Fax / Modem'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (5, ''NoDialTone'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (8, ''Outros'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (10,''NOservice'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (11,''Correio de Voz / Máquina'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (12,''Circuito ocupado'')
INSERT [dbo].[ccTipoResultadoDial] ([tipoResDial_id], [descripcion]) VALUES (13,''Cancelado'')

Print ''Estableciendo los tipos de estado de los agentes''
DELETE [dbo].[ccTipoStatusAgente]
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (0, ''LogOut'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (1, ''Desconhecido'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (2, ''Not Ready'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (3, ''Pronto'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (4, ''Conversando'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (5, ''Transferência'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (6, ''Wrapup'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (7, ''Outros'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (8, ''Cliente'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (9, ''Tocando'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (11,''Problema'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (21,''Espere por chamada manualmente'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (23, convert(text, N''ChatReq'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (24, convert(text, N''Chatting'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (25, ''Transferência Fail'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (26, ''Tocando Fail'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (30, ''ReconnectKolob'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (31, ''Ready PreviewPro'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (32, ''Preview'')
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (33, convert(text, N''Assisted'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (34, convert(text, N''Em diálogo Whatsapp'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (35, convert(text, N''Idle'' collate SQL_Latin1_General_CP1_CI_AS))
INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (36, convert(text, N''Em diálogo E-mail'' collate SQL_Latin1_General_CP1_CI_AS))


Print ''Estableciendo los tipos de usuario''
Delete [dbo].[ccTipoUsers]
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (1, ''Agente'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (2, ''Supervisor'')
INSERT [dbo].[ccTipoUsers] ([TipoUser_id], [descripcion]) VALUES (6, ''Acesso AVRS'')

Print ''Estableciendo los dias''
Delete [dbo].[ccDias]
SET IDENTITY_INSERT [dbo].[ccDias] ON
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (1, ''domingo'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (2, ''segunda-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (3, ''terça-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (4, ''quarta-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (5, ''quinta-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (6, ''sexta-feira'')
INSERT [dbo].[ccDias] ([dia_id], [Name]) VALUES (7, ''sábado'')
SET IDENTITY_INSERT [dbo].[ccDias] OFF

truncate table cstoTarifa

Print ''Estableciendo los tipos de llamada''
delete cstoTipoLlamada

INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,1,''Local'',''7|8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,2,''National LD'',''12'',''01%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,3,''Mobile'',''13'',''044%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,4,''LD Mobile'',''13'',''045%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,5,''01800'',''12'',''01800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,6,''USA LD'',''13'',''001%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,7,''Inter LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,8,''On Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,9,''Off Net'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,10,''On Ring'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(1,11,''Triangle'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,1,''2-digit Local Area Code'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,2,''3-digit Local Area Code'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,3,''4-digit Local Area Code'',''6'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,4,''2-digit Local Mobile Area Code'',''10'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,5,''3-digit Local Mobile Area Code'',''9'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,6,''4-digit Local Mobile Area Code'',''8'',''15%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,7,''Long Distance'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(2,8,''Long Distance Mobile'',''13'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,2,''LD'',''8'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(3,3,''Mobile'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(4,2,''National LD'',''11'',''1%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,1,''Local'',''9'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(5,2,''National LD'',''10'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(6,3,''Mobile'',''11'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,2,''LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,3,''Mobile'',''11'',''07%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(7,4,''Inter LD'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,1,''Local'',''7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,2,''Old LD'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,3,''Mobile'',''10'',''05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,4,''New LD'',''11'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(8,5,''Inter LD'',''13'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,1,''Local'',''10'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,2,''Inter LD'',''0'',''0011%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(9,3,''Mobile'',''10'',''04%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,1,''Local'',''8'',''2%|3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,2,''Mobile '',''8'',''6%|7%|8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,3,''9-digit Mobile'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,4,''National LD'',''10'',''02%|03%|04%|05%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,5,''National Mobile LD'',''10'',''06%|07%|08%|09%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,6,''9-digit National Mobile LD'',''11'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(10,7,''International LD'',''19'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,1,''Local'',''8'',''2%|6%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,2,''Mobile'',''8'',''3%|4%|5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,3,''National LD'',''8'',''7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(11,4,''International LD'',''8'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,1,''Local'',''8'',''2%|3%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,2,''SIP Telephony'',''8'',''4%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,3,''Mobile Telephony'',''8'',''5%|6%|7%|8%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,4,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,5,''Reverse Charge'',''10'',''800%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,6,''Premium Rate'',''10'',''90%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,7,''Internet Access'',''10'',''900%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(12,8,''Special'',''0'',''08%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,1,''Landline'',''8'',''2%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,2,''Mobile'',''8'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(13,3,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,1,''Local'',''9'',''8%|9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,2,''Mobile'',''9'',''6%|7%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,3,''International LD'',''0'',''00%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(14,4,''Webservices'',''9'',''5%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,1,''Local'',''6|7'',''%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,2,''National LD'',''9'',''0%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,3,''Mobile'',''9'',''9%'')
INSERT INTO [cstoTipoLlamada] ([country_id],[tipoLlamada_id],[descrip],[longitud],[prefijo])VALUES(15,4,''Inter LD'',''0'',''00%'')

Print ''Estableciendo los movimientos de lista negra''
Delete [dbo].[ccTipoMovsListaNegra]
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] ON
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (1, ''Adicionado à lista negra'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (2, ''Bloqueado no carregamento'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (3, ''Removido da campanha'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (4, ''Substituído da lista negra'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (5, ''Excluído da lista negra'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (6, ''Adicionado por Disposição'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (7, ''Carregar lista negra'')
INSERT [dbo].[ccTipoMovsListaNegra] ([idtipomov], [movimiento]) VALUES (8, ''Carga cliente lista negra'')
SET IDENTITY_INSERT [dbo].[ccTipoMovsListaNegra] OFF

Print ''Estableciendo los tipos de calificacion''
Delete [dbo].[ccTipoCalif]
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (1, ''Peça informações Geral'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (2, ''Chame hung'', 0)
INSERT [dbo].[ccTipoCalif] ([calif_id], [Description], [orden]) VALUES (3, ''Wrong Number'', 0)

Print ''Estableciendo los tipos de calificacion de salida''
Delete [dbo].[ccTipoCalifOUT]
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (1, ''Chamada eficaz'' , 0, 0, 1)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (2, ''Deixe um recado '', 0, 1, 2)
INSERT [dbo].[ccTipoCalifOUT] ([calif_id], [Description], [autoTime], [CanReprogram], [orden]) VALUES (3, ''Wrong Number'', 0, 1, 3)

--Pendiente validar rpoveedores portugal
--Print ''Estableciendo proveedores''
--Delete [dbo].[cstoProvedor]
--DBCC CHECKIDENT (''[cstoProvedor]'', RESEED, 0)
--INSERT [dbo].[cstoProvedor] ([descrip]) VALUES (''Carrier 1'')

Print ''Tipo Msg ChatLog'' -- No se hace delete ni truncate ya que se perderia la integridad si ya hay registros, los id ya deberian estar creados por lo cual se genera el update
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrador escreve única mensagem para um agente'' where TipoMsgChat=1
Update ccRIAChat_TipoMsg set MsgDetalle=''Agente escreve uma mensagem para o Administrador'' where TipoMsgChat=2
Update ccRIAChat_TipoMsg set MsgDetalle=''Administrador escreve uma mensagem global'' where TipoMsgChat=3

Print ''Mensajes defualt''
DELETE [dbo].[ccMsgFiles]
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default5'', ''Mensagem de boas vindas'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default4'', ''Mensagem de transferência'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default3'', ''Mensagem de falta de serviço'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default2'', ''Depois de horas de mensagens'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default1'', ''Na fila de mensagens'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default7'', ''Nenhum agente assinado em mensagem'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default9'', ''Mensagem de voz'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default10'', ''Mensagem de Overflow'')
INSERT [dbo].[ccMsgFiles] ([msgFile], [Descripcion]) VALUES ( ''Default_En\Default11'', ''Lista DNC'')

Print ''Mensajes default chat''
DELETE [dbo].[ccRIAChatInboundMsgs]
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default5'', ''Bem-vindo!'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default3'', ''Serviço está disponível no momento'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default2'', ''Nosso horário de serviço terminou'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default1'', ''Por favor aguarde enquanto um dos nossos agentes está disponível'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default7'', ''Há agentes não disponíveis'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default10'', ''Sua solicitação não pode ser processada'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default12'', ''Sessão de chat foi-inativo por muito tempo'')
INSERT [dbo].[ccRIAChatMsg](descripcion, msg) values(''Default_En\Default13'', ''Sessão de chat terminou'')';
		EXEC(@sql);

        SET @process = 'Add Status Whatsapp Dialog and Engaged Email'
        SET @sql = 'declare @lang int

select @lang=valor from ccSettings where setting_id=27
if not exists( select * from ccTipoStatusAgente where TipoStatusAge_id in(34,36))begin
	if @lang=2 begin
	INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (34, N''Em diálogo Whatsapp'')
	INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (36, N''Em diálogo E-mail'' )
	end
	else if @lang=0 begin	
		INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (34, N''Dialogo de Whatsapp'')
		INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (36, N''En diálogo Correo'' )
	end
	else begin
		INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (34, N''Whatsapp Dialog'')
		INSERT [ccTipoStatusAgente] ([TipoStatusAge_id], [descripcion]) VALUES (36, N''Engaged Email'' )	
	end
end
'       EXEC(@sql);

        -----------------------------------------------------BEGIN hotfix/125.20231211.0.4 Jesus Gallardo  ----------------------------------------------------------------

 ---------------------------------------BEGIN Jesus Gallardo hotfix/125.20231211.0.9---------------------------------------------------------

    set @process = 'Dineria -- alter Table smsccoLogDial add Message'
    set @sql='if not exists (select * from sys.columns where name = N''Message'' and Object_ID = Object_ID(N''smsccoLogDial''))
begin
    alter Table smsccoLogDial add Message varchar(200) null
end
'
    EXEC(@sql)

    set @process = 'Dineria --  Add Column smsccoLogDial.Bill decimal'
    set @sql='if not exists (select * from sys.columns c 
inner join sys.types t on c.system_type_id=t.system_type_id
where c.name = N''Bill'' and c.Object_ID = Object_ID(N''smsccoLogDial'')
and t.name=''float''
)
begin
   alter Table smsccoLogDial alter Column Bill decimal(10,2) not null
end'
    EXEC(@sql)

    set @process = 'Dineria -- CREATE IX_smsccoLogDial_3 '
    set @sql='if not exists (select * from sys.indexes where name = N''IX_smsccoLogDial_3'' and object_id = OBJECT_ID(N''smsccoLogDial''))
    begin
        CREATE NONCLUSTERED INDEX IX_smsccoLogDial_3
ON [dbo].[smsccoLogDial] ([SystemApiId])
    end
'
    EXEC(@sql)

    set @process = 'Raccon --  Alter SP ccsp_DLRInsertCall Quitar Costo'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_DLRInsertCall]
@callout_id int,
@cam_id smallint,
@cal_Key varchar(20),
@cal_Telefono varchar(14),
@Puerto smallint,
@logDial_id int=0
AS
declare @fecha as datetime
declare @cal_id as int

select @fecha=getdate()
INSERT ccoCallsOUT ( callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id ) --''Status 6=Pide Agente
  VALUES ( @callout_id, @cam_id, @cal_Key, @cal_Telefono, @Puerto,  @fecha, 6 )

select @cal_id = scope_identity()

insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo from ccRIACampEspWG wg with(nolock)
where wg.Tipo=1 and wg.idcampesp=@cam_id


exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=6

-- calcula el costo de la llamada
--exec ccsp_CstoCalculaCosto @cal_id --Se quita por que es una llamada nueva

select @cal_id as cal_id
'
    EXEC(@sql)

    set @process = 'Raccon -- Alter SP ccsp_DLRGetDialInfo se modifica para agergar  datos a tabla temporal para no repetir consulta @tmpccoCallsOutSource'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_DLRGetDialInfo]
@callout_id int,
@cam_id smallint=0,
@iPortNumber smallint = 0
AS
set nocount on
declare @message_name as varchar(8000), @messageDNCL_name as varchar(max), @messageDNCLConfirm_name as varchar(max)    
declare @prefix as varchar(15)
declare @prefixCalKey as varchar(30)
declare @tNoContesta as tinyint
declare @ani as varchar(32)
declare @iTipoDial tinyint, @detectAnswerMachine as smallint, @detectVoiceMail as tinyint, @rotativeAlgo tinyint
declare @cam_tnotas as smallint, @keepDial as bit, @lista_id smallint
declare @ivr_script smallint, @surveycamid int
declare @call_record_cam as tinyint
declare @pais as tinyint 
declare @sipHdrFormat varchar(255)
declare @PrefixRec varchar(40)
declare @recordHold bit

set @prefix =''''
set @tNoContesta = 25
set @ani=''''
set @iTipoDial = 0
set @detectAnswerMachine = 0
set @detectVoiceMail =1
set @cam_tnotas = 30
set @keepDial = 0

select @pais = valor from ccsettings where setting_id = 104

-- Mensajes
select @message_name=msg_mostrar, @messageDNCL_name=msg_mostrar_dnc, @messageDNCLConfirm_name = msg_mostrar_dnc_confirm
from dbo.fn_ccCamps_SelMessage(@cam_id)

-- Prefijo por puerto
select @prefix = prefix from cstoProvedor nolock where provedor_id = (select provedor_id from ccodialers nolock where puerto = @iPortNumber )
-- Prefijo por campa?a
if @prefix =''''
    select @prefix = dialPrefix from ccCamps nolock where cam_id = @cam_id
-- Prefijo general, si es que esta habilitado
if @prefix ='''' and ((select cast(valor as int) from ccsettings nolock where setting_id =102) & 1 = 1)
    select @prefix = valor from ccsettings nolock where setting_id =101

select @iPortNumber = 0, @surveycamid = 0, @ivr_script = 0

-- Propiedades de campa?a
select @sipHdrFormat=isnull(sipHdrFormat,''''),@tNoContesta=cam_tNoContesta, @ani=ani, @iTipoDial=iTipoDial, @detectAnswerMachine=detectAnswerMachine,
@detectVoiceMail=detectVoiceMail, @cam_tnotas=cam_tnotas, @keepDial=keepDial,@lista_id =id_anilist,
@call_record_cam = isnull(call_record,1), @surveycamid = isnull(surveycamid,0), @rotativeAlgo=isnull(rotativeAlgo,0), @recordHold=ISNULL(recordHold,0)
,@PrefixRec=ISNULL(prefijo,'''')
from ccCamps C (nolock) where C.cam_id=@cam_id

if @surveycamid > 0
    select @ivr_script = isnull(ivrscript,0) from cccamps nolock where cam_id = @surveycamid

--Custom MOH Files
DECLARE @MohFiles VARCHAR(8000), @sipheader varchar(500)
SELECT @MohFiles = COALESCE(@MohFiles + '','', '''') + V.msgfile 
FROM ccCampsMsgs VE (nolock) join ccMsgfiles V (nolock) ON VE.Msg_id = V.Msg_id WHERE cam_id = @cam_id and TYPE = 15 ORDER BY orden

--Agrega prefijo Marcacion con directo
declare @mainPrefix varchar(1), @phones varchar(max)
set @prefixCalKey=''''
select @mainPrefix = valor from ccSettings where setting_id=202
declare @tmpccoCallsOutSource table(callout_id int primary key,dialPrefix   varchar(30) null
,cal_Key    varchar(40)
,cal_telefono   varchar(30),cal_telefono2   varchar(30),cal_telefono3   varchar(30),cal_telefono4   varchar(30),cal_telefono5   varchar(30)
,Dato1  varchar(255),Dato2  varchar(255),Dato3  varchar(255),Dato4  varchar(255),Dato5  varchar(255)
,recyclePhone   smallint,recycleType bit
)
insert into @tmpccoCallsOutSource
select callout_id,dialPrefix,cal_Key,
cal_telefono,cal_telefono2,cal_telefono3,cal_telefono4,cal_telefono5,
Dato1,Dato2,Dato3,Dato4,Dato5,
recyclePhone,recycleType
FROM ccoCallsOutSource NOLOCK WHERE callout_id=@callout_id 


SELECT @prefixCalKey=CASE WHEN @mainPrefix=''1'' THEN isnull(dialPrefix,'''') ELSE '''' END,
    @phones=cal_telefono+'';''+cal_telefono2+'';''+cal_telefono3+'';''+cal_telefono4+'';''+cal_telefono5
FROM @tmpccoCallsOutSource

if @iPortNumber >= 0 
begin
    declare @Anis table(id int, pid varchar(2), phone varchar(32), ani varchar(32))

    insert @Anis
    exec ccsp_DLRGetRotativeANI @callout_id=@callout_id,@phones=@phones,@aniList=@lista_id,@algo=@rotativeAlgo

    SELECT @sipheader = dbo.fn_getSIPHeaderCfg(@callout_id,@sipHdrFormat)
    
    SELECT c.callout_id, ''cal_key''=c.cal_key+''~''+rtrim(dato1)+''~''+rtrim(dato2)+''~''+rtrim(dato3)+''~''+rtrim(dato4)+''~''+rtrim(dato5)
    , ISNULL(cpt.Prioridad,''12345NNN'') dial_tels
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 1) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE C.cal_telefono  END cal_telefono
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 2) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono2 END cal_telefono2
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 3) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono3 END cal_telefono3
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 4) AND ISNULL(recycleType, 1) = 0) THEN '''' ELSE c.cal_telefono4 END cal_telefono4
    , CASE WHEN (NOT(ISNULL(recyclePhone, 0) = 5) AND ISNULL(recycleType, 1) = 0) THEN '''' Else c.cal_telefono5 END cal_telefono5
    , isnull(@message_name, '''') as message_name
    , @tNoContesta as tNoContesta, @prefix+@prefixCalKey as sDialPrefix    
    , case when anis.p1 <> '''' then anis.p1 else @ani end ani
    , case when anis.p2 <> '''' then anis.p2 else @ani end ani2
    , case when anis.p3 <> '''' then anis.p3 else @ani end ani3
    , case when anis.p4 <> '''' then anis.p4 else @ani end ani4
    , case when anis.p5 <> '''' then anis.p5 else @ani end ani5
    , @iTipoDial iTipoDial, @detectAnswerMachine detectAnswerMachine, @detectVoiceMail detectVoiceMail
    , @cam_tnotas cam_tnotas, @keepDial keepDial
    , isnull(@messageDNCL_name, '''') as messageDNCL_name
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono) as call_record
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono2) as call_record2
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono3) as call_record3
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono4) as call_record4
    ,dbo.EnableCallRecord(@call_record_cam,@pais,c.cal_telefono5) as call_record5
    , isnull(@messageDNCLConfirm_name, '''') as messageDNCLConfirm_name
    , isnull(@MohFiles,'''') as mohFiles
    ,@ivr_script ivrScript
    ,@sipheader data
    ,@PrefixRec as Prefijo,
    dbo.GetCarrierByTel(C.cal_telefono) carrier1, 
    dbo.GetCarrierByTel(cal_telefono2) carrier2, 
    dbo.GetCarrierByTel(cal_telefono3) carrier3, 
    dbo.GetCarrierByTel(cal_telefono4) carrier4, 
    dbo.GetCarrierByTel(cal_telefono5) carrier5,
    @recordHold as recordHold
    FROM @tmpccoCallsOutSource C
    left join ccoCallPriorityOrder cpo on cpo.callout_id = c.callout_id
    left join ccCampsPrioridadTel cpt on cpt.cam_id = @cam_id
    left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
    WHERE C.callout_id = @callout_id
    return
end 
set nocount off
    '
    EXEC(@sql)

    set @process = 'Sorteos -- Alter SP ccsp_AgentOutGetTels valida @callout_id=0 y se evita consulta doble '
    set @sql='ALTER PROCEDURE [dbo].[ccsp_AgentOutGetTels]
@callout_id int
AS

declare @sSQL varchar(500)
declare @telefono1 varchar(20)
declare @telefono2 varchar(20)
declare @telefono3 varchar(20)
declare @telefono4 varchar(20)
declare @telefono5 varchar(20)
declare @i tinyint
declare @idioma as bit

Select @idioma = isnull(valor,0) from ccSettings where setting_id = 27

set @i = 1
if @callout_id=0 begin
    if @idioma = 1 begin
        select ''Other'' Other
    end
    else begin
        select ''Otro'' Other
    end
    
    return 
end


select @Telefono1=cal_telefono, @Telefono2=cal_telefono2, @Telefono3=cal_telefono3, @Telefono4=cal_telefono4, @Telefono5=cal_telefono5
from ccoCallsOutSource with(nolock)
where callout_id=@callout_id
select @sSql = ''select ''
if (@telefono1 is not null and @telefono1 > '''') select @ssql = @ssql + '' ''''Telefono 1 - '' + @Telefono1 + '''''' as Telefono1,''
if (@telefono2 is not null and @telefono2 > '''') select @ssql = @ssql + '' ''''Telefono 2 - '' + @Telefono2 + '''''' as Telefono2,''
if (@telefono3 is not null and @telefono3 > '''') select @ssql = @ssql + '' ''''Telefono 3 - '' + @Telefono3 + '''''' as Telefono3,''
if (@telefono4 is not null and @telefono4 > '''') select @ssql = @ssql + '' ''''Telefono 4 - '' + @Telefono4 + '''''' as Telefono4,''
if (@telefono5 is not null and @telefono5 > '''') select @ssql = @ssql + '' ''''Telefono 5 - '' + @Telefono5 + '''''' as Telefono5,''

select @ssql = @ssql + '' ''''Otro'''' as Other ''

if @idioma = 1
begin
set @ssql = replace(@ssql, ''Telefono'', ''Telephone'')
set @ssql = replace(@ssql, ''Otro'', ''Other'')
end

--print(@ssql)
exec(@ssql)'
    EXEC(@sql)

    set @process = 'Sorteos -- DROP PROCEDURE ccsp_AgentOutGetTelsKolob'
    set @sql='if exists (select * from sys.procedures where name = N''ccsp_AgentOutGetTelsKolob'')
    begin
        DROP PROCEDURE ccsp_AgentOutGetTelsKolob;
    end'
    EXEC(@sql)

    set @process = 'Sorteos -- CREATE SP ccsp_AgentOutGetTelsKolob'
    set @sql='CREATE PROCEDURE [dbo].[ccsp_AgentOutGetTelsKolob]
@callout_id int
AS
if @callout_id=0 begin
    select ''Other'' Other
    return 
end
declare @telefono1 varchar(30)
declare @telefono2 varchar(30)
declare @telefono3 varchar(30)
declare @telefono4 varchar(30)
declare @telefono5 varchar(30)

select @Telefono1=cal_telefono, @Telefono2=cal_telefono2, @Telefono3=cal_telefono3, @Telefono4=cal_telefono4, @Telefono5=cal_telefono5
from ccoCallsOutSource with(nolock)
where callout_id=@callout_id


select @Telefono1 Phone1,@Telefono2 Phone2,@Telefono3 Phone3,@Telefono4 Phone4,@Telefono5 Phone5,''Other'' Other'
    EXEC(@sql)

    set @process = 'Sorteos -- Alter Table ccsp_Callbacks with(nolock)'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_Callbacks]
@cam_id as int
AS
select año,mes,dia,hora, callbacks from ccRIACallbacks with(nolock)

where cam_id=@cam_id order by año,mes,dia,hora'
    EXEC(@sql)

    set @process = 'Sorteos -- ALTER SP  ccsp_DLRGetRotativeANI se valida @aniList es cero o menor'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_DLRGetRotativeANI]
@callout_id int,
@phones varchar(max),
@aniList int,
@algo tinyint
AS
set nocount on
DECLARE @Tels table (id int, pid varchar(2), phone varchar(32), ani varchar(32))
if @aniList<=0 begin
    SELECT * FROM @Tels
    return(0)
end

DECLARE @aniIdx varchar(500), @aniCnt smallint, @aniCurList int, @usedAniCnt int, @phoneCnt int, @ani varchar(32), @idx varchar(8)
DECLARE @id_phone INT, @phone varchar(32), @usedAni varchar(30)

SELECT @aniCnt = count(*) FROM ccRotativeAniListDetail NOLOCK WHERE id_RAniList = @aniList          
SELECT @aniCurList=isnull(id_RAniList,0),@aniIdx=isnull(ani_idx,'''') FROM ccoWorkingTable NOLOCK WHERE callout_id = @callout_id

IF @aniList != @aniCurList SET @aniIdx = ''''

IF isnull(@aniCnt,0) > 0
BEGIN
    INSERT @Tels 
    SELECT id,''p''+cast(id as varchar(1)),value,'''' FROM fn_RIASplitDelimited(@phones, '';'') WHERE len(value)>0

    IF OBJECT_ID(''tempdb..#UsedAniList'') IS NOT NULL DROP TABLE #UsedAniList;
    SELECT * INTO #UsedAniList FROM fn_RIASplitDelimited(@aniIdx, '','') WHERE len(value)>0
    SELECT @usedAniCnt=count(*) FROM #UsedAniList

    IF @algo = 3 and @usedAniCnt > 0 and @usedAniCnt < 2
    SELECT @usedAni = telAni FROM RowRotativeAniListDetail NOLOCK WHERE id_RAniList = @aniList AND RowNum=(SELECT TOP 1 value from #UsedAniList)

    DECLARE CUR_TEST CURSOR FAST_FORWARD FOR SELECT Id, phone FROM @Tels ORDER BY Id;
    OPEN CUR_TEST FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone

    WHILE @@FETCH_STATUS = 0
    BEGIN
            
        IF @usedAniCnt >= @aniCnt SET @aniIdx = ''''

        IF @algo = 0
        BEGIN
            SELECT @ani = dbo.TelAni(@phone,@aniList)
        END
        ELSE IF @algo = 1
        BEGIN
            SELECT TOP 1 @ani=telAni, @idx=idx FROM fnGetRotativeANI(@aniList, @aniIdx, default, default)
        END
        ELSE IF @algo = 2 or @algo = 3
        BEGIN
            DECLARE @cld varchar(3), @serie varchar(4), @cldCnt smallint
            IF len(@phone) < 10
            BEGIN
                FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone
                CONTINUE
            END
            IF @algo = 3 and @usedAniCnt > 0 and @usedAniCnt < 2
            BEGIN
                IF EXISTS(SELECT TOP 1 1 FROM Series NOLOCK WHERE CLD=left(@usedAni, 2))
                    SELECT @serie = substring(@usedAni, 3, 4)
                ELSE
                    SELECT @serie = substring(@usedAni, 4, 3)
            END
            IF @algo = 2 or (@algo = 3 and @usedAniCnt < 2)
            BEGIN
                IF EXISTS(SELECT TOP 1 1 FROM Series NOLOCK WHERE CLD=left(@phone, 2))
                    SET @cld = left(@phone, 2)
                ELSE
                    SET @cld = left(@phone, 3)
            END
            SELECT @cldCnt = count(*) 
            FROM ccRotativeAniListDetail NOLOCK 
            WHERE id_RAniList = @aniList 
                AND (((@algo = 2 or (@algo = 3 and @usedAniCnt < 2)) and left(telAni, len(@cld))=@cld) or (@algo = 3 and @usedAniCnt >= 2))
                AND (@algo = 2 OR @usedAni is null OR left(telAni, 6) != left(@usedAni, 6) OR @usedAniCnt >= 2)
            IF @cldCnt > 0 and @usedAniCnt >= @cldCnt and @algo = 2 SET @aniIdx = ''''
            SELECT TOP 1 @ani=telAni, @idx=idx 
            FROM fnGetRotativeANI(@aniList, @aniIdx
                , case when @cldCnt > 0 and (@algo = 2 or (@algo = 3 and @usedAniCnt < 2)) then @cld else '''' end
                , case when @algo = 2 then '''' when @usedAniCnt = 1 and @serie is not null then @serie else '''' end)
        END

        SELECT @aniIdx = @aniIdx+'',''+@idx, @usedAniCnt = @usedAniCnt+1, @usedAni = @ani

        UPDATE @Tels SET ani=@ani WHERE id=@id_phone

        FETCH NEXT FROM CUR_TEST INTO @id_phone, @phone
    END
    CLOSE CUR_TEST
    DEALLOCATE CUR_TEST

    UPDATE ccoWorkingTable SET id_RAniList=@aniList, ani_idx=isnull(@aniIdx,'''') WHERE callout_id=@callout_id
END

SELECT * FROM @Tels

set nocount off'
    EXEC(@sql)

   
    set @process = 'Sorteos -- Alter SP ccsp_GalateaCallbacksDays'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_GalateaCallbacksDays]
@userID int
AS
declare @currentDay datetime,@rangeDays int 
declare @daysAdd datetime



set @currentDay =getdate()
set @dateadd=dateadd(dd,@rangeDays,getdate())

select @rangeDays=valor from ccSettings where setting_id=35

-- Returns days with callbacks made by an agent
SELECT cal_fusercallback Day
FROM ccoCallBacks cb with(nolock)
WHERE user_id = @userID
and cal_fusercallback between @currentDay and @dateadd
order by Day'
    EXEC(@sql)

    set @process = 'Sorteos -- ALTER SP ccsp_RIA_ABCAgents if @option=4--Delete'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
@option smallint,
@UserId int,
@Login varchar(40)='''',
@Nombres varchar(25)=null,
@ApellidoPaterno varchar(25)='''',
@ApellidoMaterno varchar(25)='''',
@Password varchar(33)='''',
@Sexo bit=null,
@canChangeStatus bit=null,
@AreaId int=null,
@UserType tinyint=1,
@IDWG int=0,
@DeleteUsers int=1,
@inOut int=null,
@IDCampEsp int=null,
@multipleUsers varchar(1000)=null
as
set nocount on

if @option=0--All Users
  begin
  select User_id,Login,ISnull(AREas.AreaName,'''')as AreaName

from ccusers as users with(nolock)
    left join ccRIACat_Areas as areas with(nolock)
    on users.IDArea=areas.IDArea
  return(0)
  end

if @option=1--selected User
  begin
  select User_id,Login,Nombres,isnull(apellidoPaterno,''''),
    isnull(ApellidoMaterno,''''),Sexo,canChangeStatus,isnull(IDArea,0),tipouser_id
  from ccusers where User_id=@UserId
  order by IDArea,Nombres,ApellidoPaterno,User_id
  return(0)
  end

if @option=2--insert
  begin
  if exists(select Login from ccUsers where Login=@Login)
    begin
    select -1--,''Login en Uso''
    return(0)
    end

  if exists(select Login from ccUsers_Consulta where Login = @Login)
  begin
    select -4 -- ''Login habia estado en Uso''
    return(0)
  end

  if exists(select Nombres from ccUsers where Nombres=@Nombres
  and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
    begin
    select -2--,''Nombre en Uso''
    return(0)
    end

IF( select isnull(max(user_id),0) from ccusers) > 32700
BEGIN
  set @UserId = null
  SELECT @UserId = d.rn FROM (SELECT d.rn, ROW_NUMBER() OVER (ORDER BY d.rn) AS recID
  FROM (SELECT ROW_NUMBER() OVER (ORDER BY user_id) AS rn FROM ccusers) AS d
  LEFT JOIN ccusers AS s ON s.user_id = d.rn WHERE s.user_id IS NULL ) AS d
  INNER JOIN ( SELECT  user_id, ROW_NUMBER() OVER (ORDER BY user_id DESC) AS recID
  FROM ccusers) AS w ON w.recID = d.recID

  if @UserId is null
  begin
    select -2--insert Error
    return(0)
  end

  set identity_insert ccusers on
  insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
    Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
  select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
    1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
  set identity_insert ccusers off

  delete ccMenuUser where id_User = @UserId
  delete ccRIAUserRole where user_id = @UserId

  exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

END
ELSE
BEGIN
  insert into ccUsers(Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id,
    Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
  select @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,
    1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end

  if @@rowcount=1
    select @UserId=scope_identity()
  else
    begin
    select -2--insert Error
    return(0)
    end
END
  insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
  insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
  insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
  --Menu para roles RepotsRia
  exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

  select @UserId,'' Usuario '' + @Login + '' Dado de Alta''
  return(0)
  end

if @option=3--Update
  begin
  if @Login='''' and @Password <> ''''
    begin
    Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId
    return(0)
    end

  Update ccUsers
  set Login= case when @Login <> '''' then @Login else Login end,
  Nombres=@Nombres,
  ApellidoPaterno=@ApellidoPaterno,ApellidoMaterno=@ApellidoMaterno,
  Password=case when @Password <> '''' then @Password else Password end,
  Sexo=@Sexo,canChangeStatus=@canChangeStatus
  where User_id=@UserId
  return(0)
  end

if @option=4--Delete
  begin
  delete from ccSkills where user_id =@UserId
  delete from ccMenu_ViewsUser where user_id =@UserId
  delete from dbo.ccRIAWorkGroupUsers where user_id =@UserId
delete from ccRIAAgentsPermissions where AgentId=@UserId
  delete from ccUsers where user_id=@UserId
  return(0)
  end

declare @Type tinyint, @users int,@sql varchar(8000), @NinOut nvarchar(10)

if @option=5--insert Agente-Supervisor in WorkGroup
  begin
  select @Type=TipoUser_id from ccUsers where User_id=@UserId

  if @Type not in(1,2,6)
    return(0)

  if @Type=1 and((select count(User_id)from ccRIAWorkGroupUsers where User_id=@UserId)>=(select valor from ccSettings where setting_id=63))
    begin
    select 3
    return(0)
    end

  if exists(select @UserId from ccRIAWorkGroupUsers where User_id=@UserId and IDWG=@IDWG)
    begin
    select 1
    return(0)
    end

  insert into ccRIAWorkGroupUsers(IDWG,User_id)values(@IDWG,@UserId)

  if @Type=1
    begin

    if @IDWG is null or @IDWG = 0
      begin
      select 28
      return(0)
      end
    insert into cccampsAgente(user_id,cam_id,prioridad,skill,IDWG)

    select @UserId,idCampEsp,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
    from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
      and idCampEsp not in(select cam_id from cccampsAgente where user_id=@UserId and IDWG=@IDWG)

    insert into ccinboundAgentes(User_id,Inbound_id,cli_id,prioridad,skill,IDWG)
    select @UserId,idCampEsp,0,dbo.fn_Calcula_UsrPriority(@UserId,0),1,@IDWG
    from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
      and idCampEsp not in(select inbound_id from ccinboundAgentes where user_id=@UserId and IDWG=@IDWG)

    return(0)
    end

--else @Type=2 or @Type=6--Supervisor
  insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
  select @UserId,idCampEsp,0,@IDWG
  from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
    and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=0 and IDWG=@IDWG)

  insert into ccSupervisorCam(user_id,cam_id,tipo,IDWG)
  select @UserId,idCampEsp,1,@IDWG
  from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
    and idCampEsp not in(select cam_id from ccSupervisorCam where user_id=@UserId and tipo=1 and IDWG=@IDWG)
  return(0)
  end

if @option=6--Delete Agent-Supervisor from WorkGroup
  begin
  if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)=0
    select @UserId = @multipleUsers

        else if isnull(@UserId, 0) = 0 and CHARINDEX('','', @multipleUsers)>0
          select @UserId = cast(substring(@multipleUsers, 1,
          CHARINDEX('','', @multipleUsers)-1) as int)

    select @Type=case when @UserType <> 0 then @UserType else TipoUser_id end,
    @multipleUsers=isnull(@multipleUsers,cast(@Userid as varchar(10)))
  from ccUsers where User_id=@UserId

  Declare @sqlDelete nvarchar(4000)
  if @Type in(1,2,6)--1:Agente / 2,6:Supervisor
    begin
    set @sqlDelete=N''Delete from '' + case @Type when 1 then ''cccampsagente where '' else ''ccSupervisorCam where tipo=0 and '' end
    + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
    + '' Delete from '' + case @Type when 1 then ''ccinboundagentes where '' else ''ccSupervisorCam where tipo=1 and '' end
    + ''user_id in(''+ isnull(@multipleUsers,''user_id'') + '') and IDWG=''+cast(@IDWG as varchar(10))
    exec(@sqlDelete)
    end

  if isnull(@UserId, 0) = 0 or isnull(@multipleUsers, ''0'') = ''0''
    begin
    select -9 -- Se ingreso mal el id del usuario
    --delete ccinboundagentes where idwg=@IDWG
    --delete cccampsagente where idwg=@IDWG
    --delete ccSupervisorCam where idwg=@IDWG
    end

  if @DeleteUsers=1
    Delete ccRIAWorkGroupUsers where IDWG=@IDWG and User_id=@UserId

  return(0)
  end

if @option=7--Delete Agent from WorkGroup
  begin
  select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end
  set @sql=''delete '' + case @NinOut when ''1'' then ''ccCampsAgente'' else ''ccInboundAgentes'' end +
    '' where user_id in('' + isnull(@multipleUsers, ''0'') +'') and '' + case @NinOut when ''1'' then ''cam_id'' else ''inbound_id'' end +
    ''='' + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' + cast(@IDWG as varchar(10)) +
    '' delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
  exec(@sql)
  --update preview permission
  set @sql = ''update ccusers set 
      AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
      DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
      select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
      where progDial=3 and user_id in ('' + isnull(@multipleUsers, ''0'') +'') group by user_id)c on us.User_id=c.user_id
      where us.user_id in ('' + isnull(@multipleUsers, ''0'') +'')''
  exec(@sql)
return(0)
  end

if @option=8--Delete Supervisor from WorkGroup
  begin
  select @NinOut=case when @inOut <> 1 then ''0'' else ''1'' end

        set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and user_id in('' + isnull(@multipleUsers, ''0'') + '') and cam_id=''
          + cast(@IDCampEsp as varchar(10)) + '' and IDWG='' +cast(@IDWG as varchar(10)) + ''
          delete ccRIACampEspWG where tipo='' + @NinOut + '' and IDWG='' + cast(@IDWG as varchar(10)) + '' and IdCampEsp='' + cast(@IDCampEsp as varchar(10))
        exec(@sql)

  set @sql=''delete ccSupervisorCam where tipo='' + @NinOut + '' and cam_id='' + cast(@IDCampEsp as varchar(10)) + ''and '' +
    ''user_id in ('' + isnull(@multipleUsers, ''0'') + '') and IDWG='' + cast(@IDWG as varchar(10))
  exec(@sql)
  return(0)
  end

if @option=9
  begin

  update ccusers set NotReadyRestricted=@canChangeStatus where [User_id]=@UserId

select Login from ccUsers where [User_id]=@UserId
  return(0)
  end
set nocount off'
    EXEC(@sql)

    set @process = 'Sorteos -- Alter SP ccsp_RIAADMgetAbandonoSalida_Fix'
    set @sql='ALTER procedure [dbo].[ccsp_RIAADMgetAbandonoSalida_Fix]
as
set nocount on
declare @to smalldatetime, @from smalldatetime
declare @interval int
declare @i int
declare @row int

declare @tempChart table(
cam_id  int,
countAbnd int,
countAll int,
timestamp   smalldatetime
)

set @interval=10
set @to = convert(datetime, convert(varchar(13), getdate(), 121)+'':00:00'',121)

set @to = dateadd(mi,10,@to)
set @from = dateadd( mi, -@interval*30, @to)

set @row=DATEDIFF(mi,@from,@to)
select @row=ABS( CEILING(1.0*@row/@interval))


;WITH Numbers AS
(
    SELECT TOP (@row) n = CONVERT(INT, ROW_NUMBER() OVER (ORDER BY s1.[object_id]))
    FROM sys.all_objects AS s1 CROSS JOIN sys.all_objects AS s2
)
, times as(
    SELECT  ROW_NUMBER() OVER (ORDER BY n) as [ID], DATEADD(MINUTE,@interval* (n-1), @from) as [Start], DATEADD(MINUTE,@interval* (n), @from) as [Stop]
    FROM Numbers
), tempChart as(
    select cam_id,case statuscall_id when 6 then 1 end  as countAbnd
    ,convert(datetime,  convert(varchar(15), cal_inicio, 121)+''0:00'',121) as timeSpam     
    from ccoCallsOut
    with( index(IX_ccoCallsOut_2),nolock )
    where cal_manual in (0,2 ) and cal_inicio between @from and @to
),timeCamps as(
    select c.cam_id,t.Start as timeSpam from times t
    cross join ccCamps c
    where c.IDArea is not null
),tempChartGroup as(
    select cam_id,count(countAbnd) as countAbnd,
    COUNT(*) as countAll,timeSpam
    from tempChart
    group by cam_id,timeSpam
)

insert into @tempChart
select tCamp.cam_id,isnull(countAbnd,0) as countAbnd,isnull(countAll,0) countAll
,tCamp.timeSpam from timeCamps tCamp
left join tempChartGroup chart on tCamp.cam_id=chart.cam_id and tCamp.timeSpam=chart.timeSpam

truncate table ccAbandonoSalida_Chart

insert into ccAbandonoSalida_Chart
select cam_id,
CONVERT(decimal(10,2),
case when countAll=0 then 0 else countAbnd*100.00/countAll end
),[timestamp]
  from @tempChart order by cam_id 

truncate table ccAbandonoSalida  
  
 insert into ccAbandonoSalida
 select cam_id,
 CONVERT(decimal(10,2),
 case when sum(countAll) =0 then 0 else 
 SUM(countAbnd*100.0)/sum(countAll) end 
 ) as AbndPctg 

 from @tempChart
 group by cam_id
 
set nocount off'
    EXEC(@sql)

    set @process = 'Sorteos -- Alter SP ccsp_RIAAgentGetDialMask if @mask=0 begin'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
@user_id integer,
@tel varchar(15)
AS
declare @mask integer, @idioma integer, @value integer, @lada integer
declare @country as tinyint

set @value = 0
select @mask = isnull(dialmask,7) from ccusers where user_id=@user_id
select @country = valor from ccsettings where setting_id = 104

if @mask=0 begin
	select @value Response
	return
end

-- Restricciones por pais 1:Mexico 2:Argentina 3:Colombia 4:USA 5:Chile 6:Venezuela 7:uk 8:Arabia Saudita, 9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador
if @country = 1
	begin

	DECLARE @specialDialPlan TINYINT, @phoneType TINYINT
	SELECT @specialDialPlan = valor, @phoneType = 0
	FROM ccsettings WITH (NOLOCK)
	WHERE setting_id = 195

	if @specialDialPlan = 1 select @phoneType=dbo.fnGetCallType(@tel)

	--Restringe celulares
	if (@mask & 1)>0
		begin
		if ((left(ltrim(rtrim(@tel)),3) = ''044'' Or left(ltrim(rtrim(@tel)),3) = ''045'') and len(ltrim(rtrim(@tel))) = 13) or (@specialDialPlan = 1 and (@phoneType=3 or @phoneType=4))
			begin
			set @value = 4
			end
		end

	--Restringe larga distancia
	if(@value=0)
		begin
		if ((@mask & 2) > 0)
			begin
			if ((left(ltrim(rtrim(@tel)),2) = ''01'') and len(ltrim(rtrim(@tel))) = 12) or (@specialDialPlan = 1 and @phoneType=2)
				begin
				set @value = 5
				end
			end
		end

	--Restringe locales
	if(@value=0)
		begin
		if ((@mask & 4) > 0)
			begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if (Len(@lada) + Len(ltrim(rtrim(@tel))) = 10 and @specialDialPlan = 0) or (@specialDialPlan = 1 and @phoneType=1)
				begin
				set @value = 6
				end
			end
		end
	end

-- Argentina
if @country = 2
	begin
	--Restringe celulares
	if ((@mask & 1) > 0)
		begin
		if (left(@tel,2)=''15'') or (len(@tel)>=13 and substring(@tel,1,1)=''0'' and
			(substring(@tel,4,2)=''15'' or substring(@tel,5,2)=''15'' or substring(@tel,3,2)=''15''))
			begin
			set @value = 4
			end
		end

	--Restringe larga distancia
	if(@value=0)
		begin
		if ((@mask & 2) > 0)
			begin
			if ((left(ltrim(rtrim(@tel)),2) =''0'') and len(ltrim(rtrim(@tel))) = 11)
				begin
				set @value = 5
				end
			end
		end

	--Restringe locales
	if(@value=0)
		begin
		if ((@mask&4)>0)
			begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
				begin
				set @value=6
				end
			end
		end
	end

if @country = 3 --Colombia
	begin
	--Restringe Celulares
	if ((@mask & 1) > 0)
		begin
		if len(@tel) > 8
			begin
			set @value = 4
			end
		end

	--Restringe larga distancia
	if(@value=0)
		begin
		if ((@mask & 2) > 0)
			begin
			if len(@tel) = 8 or left(@tel,1) = ''0''
				begin
				set @value = 5
				end
			end
		end

	--Restringe locales
	if(@value=0)
		begin
		if ((@mask & 4) > 0)
			begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
				begin
				set @value = 6
				end
			end
		end
	end

if @country = 4 --USA
	begin
	--Restringe larga distancia usa
	if ((@mask & 2) > 0)
		begin
		if len(ltrim(rtrim(@tel))) >= 11  and (left(ltrim(rtrim(@tel)),1) = ''1'')
			begin
			set @value = 5
			end
		end

	--Restringe locales usa
	if(@value=0)
		begin
		if ((@mask & 4) > 0)
			begin
			select @lada=valor from ccSettings WHERE setting_id=17
			--if Len(ltrim(rtrim(@tel))) = 7
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
				begin
				set @value = 6
			end
			end
		end
	end

--Chile
if @country = 5
	begin

		--Restringe Celulares
	if ((@mask & 1) > 0)
		begin
		if len(@tel) >= 10 and left(@tel,2) = ''09''
			begin
			set @value = 4
			end
		end

		--Restringe Locales
	if(@value=0)
		begin
		if ((@mask & 4) > 0)
			begin
			if Len(@tel) in (6,7)
				begin
				set @value = 6
				end
			end
		end

	--Restringe larga distancia
	if(@value=0)
		begin
		if ((@mask & 2) > 0)
			begin
			if len(@tel) >= 8 and len(@tel) < 10
				begin
				set @value = 5
				end
			end
		end
	end

--Venezuela
if @country = 6
begin
		--Restringe Celulares
	if ((@mask & 1) > 0)
		begin
		if len(@tel) >= 10 and left(@tel,2) = ''04''
			begin
			set @value = 4
			end
		end

	--Restringe larga distancia
	if(@value=0)
		begin
		if ((@mask & 2) > 0)
			begin
			if len(@tel) >= 10 and left(@tel,1) = ''0''
				begin
				set @value = 5
				end
			end
		end

	--Restringe locales
	if(@value=0)
		begin
		if ((@mask & 4) > 0)
			begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 10
				begin
				set @value = 6
				end
			end
		end

end

--United Kingdom
if @country = 7
begin
		--Restringe Celulares
	if ((@mask & 1) > 0)
		begin
		if (len(@tel) >= 9) and left(@tel,2) = ''07''
			begin
			set @value = 4
			end
		end

	--Restringe larga distancia
	if(@value=0)
		begin
		if ((@mask & 2) > 0)
			begin
			if len(@tel) >= 9 and left(@tel,1) = ''0''
				begin
				set @value = 5
				end
			end
		end

	--Restringe locales
	if(@value=0)
		begin
		if ((@mask & 4) > 0)
			begin
			if len(@tel) >= 9 and left(@tel,1) <> ''0''
				begin
				set @value = 6
				end
			end
		end

end

--arabia saudita
if @country = 8
begin

	--Restringe celulares
	if (@mask & 1)>0
		begin
		if (left(ltrim(rtrim(@tel)),2) = ''05'' and len(ltrim(rtrim(@tel))) = 10 )
			begin
			set @value = 4
			end
		end

	--Restringe larga distancia
	if(@value=0)
		begin
		if ((@mask & 2) > 0)
			begin
			if ( left(ltrim(rtrim(@tel)),2) <> ''05'' and len(ltrim(rtrim(@tel))) in (11, 9))
				begin
				set @value = 5
				end
			end
		end

	--Restringe locales
	if(@value=0)
		begin
		if ((@mask & 4) > 0)
			begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if Len(@lada) + Len(ltrim(rtrim(@tel))) = 8
				begin
				set @value = 6
				end
			end
		end
end

--Australia
if @country = 9
begin

	--Restringe celulares
	if (@mask & 1)>0
		begin
		if (left(ltrim(rtrim(@tel)),2) = ''04'' and len(ltrim(rtrim(@tel))) = 10)
			begin
			set @value = 4
			end
		end

	--Restringe larga distancia
	if(@value=0)
		begin
		if ((@mask & 2) > 0)
			begin
			if ( left(ltrim(rtrim(@tel)),2) <> ''04'' and len(ltrim(rtrim(@tel))) = 10)
				begin
				set @value = 5
				end
			end
		end

	--Restringe locales
	if(@value=0)
		begin
		if ((@mask & 4) > 0)
			begin
			select @lada=valor from ccSettings WHERE setting_id=17
			if ((Len(ltrim(rtrim(@tel))) = 8) or
				(''0'' + left(ltrim(rtrim(@tel)),1) = @lada and Len(ltrim(rtrim(@tel))) = 9) or
				(left(ltrim(rtrim(@tel)),2) = @lada and Len(ltrim(rtrim(@tel))) = 10))
				begin
				set @value = 6
				end
			end
		end
end

--Brasil
if @country = 10
	begin
		declare @lon int
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			set @lon=len(@tel)
			if
				(@lon in(7,8) and left(@tel,1) in (''6'',''7'',''8'',''9'') )
				or (@lon=9 and left(@tel,1) = ''9'' )
				or (@lon=10 and substring(@tel,3,1) in (''6'',''7'',''8'',''9'') )
				or (@lon=11 and substring(@tel,3,1) = ''9'')
				--or (@lon=12 and substring(@tel,5,1) in (''6'',''7'',''8'',''9'') )
				--or (@lon=13 and substring(@tel,5,1) = ''9'' )
				--or (@lon=13 and substring(@tel,5,1) = ''9'' )
				begin
					set @value = 4
				end
		end

		--Restringe larga distancia
		if(@value=0)
		begin
			if ((@mask & 2) > 0)
			begin
				select @lada=valor from ccSettings WHERE setting_id=17
				set @tel=ltrim(rtrim(@tel))
				set @lon=len(@tel)
				if  @lon>=10 and left(@tel,2) <> @lada
				begin
					set @value = 5
				end
			end
		end
		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				select @lada=valor from ccSettings WHERE setting_id=17
				set @tel=ltrim(rtrim(@tel))
				set @lon=len(@tel)
				if @lon in (7,8,9) or (@lon in (10,11) and left(@tel,2)= @lada)
				begin
					set @value = 6
				end
			end
		end

		--Restringe por cobrar
		if(@value=0)
		begin
			declare @llamadasPorCobrar varchar(4);
			select @llamadasPorCobrar= valor from ccSettings where setting_id=126
			set @tel=ltrim(rtrim(@tel))
			set @lon=len(@tel)
			if @lon >= 12 and  left(@tel,2) = ''90'' and @llamadasPorCobrar=''0''
			begin
				set @value = 10 -- pone para llamadas por cobrar
			end
		end

	end -- Termina Brasil


--Guatemala
if @country = 11
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''3,4,5'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''2,6,7'') > 0
					set @value = 6
			end
		end

	end -- Termina Guatemala

--Costa Rica
if @country = 12
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''5,6,7,8'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''2,3,4'') > 0
					set @value = 6
			end
		end

	end -- Termina Costa Rica

--Salvador
if @country = 13
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''6,7'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''2'') > 0
					set @value = 6
			end
		end

	end -- Termina Salvador

--Spain
if @country = 14
	begin
		--Restringe celulares
		if (@mask & 1)>0
		begin
			set @tel=ltrim(rtrim(@tel))
			if charindex(substring(@tel,1,1),''6,7'') > 0
				set @value = 4
		end

		--Restringe locales
		if(@value=0)
		begin
			if ((@mask & 4) > 0)
			begin
				set @tel=ltrim(rtrim(@tel))
				if charindex(substring(@tel,1,1),''8,9'') > 0
					set @value = 6
			end
		end

	end -- Termina Spain

select @value Response'
    EXEC(@sql)

    set @process = 'Sorteos --  Alter Sp ccsp_RIAGetNotReadyHistory'
    set @sql='ALTER  procedure [dbo].[ccsp_RIAGetNotReadyHistory]
@user_id int = 0
AS
set nocount on
-- Para horarios depues de las 12 de la noche
declare @fStart datetime, @fEnd datetime
declare @inicioTurno int, @AcumTime int
declare @fecha smalldatetime

set @inicioTurno = 2 --Cambio de dia a las 2 de la mañana
set @fecha = getdate()

if datepart(hh,@fecha)>@inicioTurno-1
 begin	
	set @fStart=convert(datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
	set @fEnd=dateadd(d,1,@fstart)
 end

else
 begin
	set @fEnd=convert(datetime, convert(varchar(11), @fecha, 121) + cast(@inicioTurno as varchar) +'':00'', 121)
	set @fStart=dateadd(d,-1,@fEnd)
 end

select 
	l.tiponotready_id, Descripcion, frame, 
	CONVERT(CHAR(8),DATEADD(second,sum(tStatus),0),108) as Tiempo,
	count(l.tiponotready_id) as veces, ''1900-01-01 00:00:00'' as fecha, time_Acum,time_xEv,
	CONVERT(CHAR(8),DATEADD(second,time_Acum,0),108) as maxTimeAcum
	from ccLogAgentesNotReady l with(nolock)
	inner join ccTipoNotReady t on l.tiponotready_id = t.tiponotready_id
	inner join ccRIAnotreadyGraph a2 on (t.tiponotready_id=a2.tiponotready_id)
	inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
	where fecha between @fStart and @fEnd and user_id = @user_id
	group by t.descripcion, l.tiponotready_id, frame,time_Acum,time_xEv

union all

select l.TipoNotReady_id, Descripcion, 0 as frame,
CONVERT(CHAR(8),DATEADD(second,tStatus,0),108) as Tiempo, 
 0 as veces, fecha, 0 as time_Acum,0  as time_xEv, ''00:00:00'' as maxTimeAcum
from ccLogAgentesNotReady l with(nolock)
inner join ccTipoNotReady t on l.tiponotready_id = t.tiponotready_id
where fecha between @fStart and @fEnd and (user_id = @user_id)
order by l.TipoNotReady_id, fecha

set nocount off'
    EXEC(@sql)

    set @process = 'Alter SP ccsp_WhatsAppInformationOut --IF @Option = 0  error nombre ccWAAverageConversationsOut'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformationOut]
@Option SMALLINT,
@camId SMALLINT = 0,
@ConversationId INT = 0,
@AgentsAvailables INT = 0,
@IncreaseDecreaseAgent BIT = NULL

AS
SET NOCOUNT ON
IF @camId>0 and NOT EXISTS (SELECT * FROM ccCamps WHERE cam_Id = @camId AND CampType = 5) BEGIN
	print (''Camp Is Not WhatsApp'')
	return(-1);
End

 
      
DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
--set @Today SMALLDATETIME = ''2022-03-24''
IF @Option = 0 BEGIN-- Reset TABLES
	TRUNCATE TABLE ccWAConversationsResult
	TRUNCATE table ccWAOperatingSummaryOut;
	TRUNCATE TABLE ccWAAverageConversationsOut;
	TRUNCATE TABLE ccLastMessageAgentByConversationOut;
END    
else IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut
                WHERE CamId = @camId
                AND (LastUpdate IS NULL
                OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
    BEGIN
        -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

        DECLARE @AverageConversationTime INT = 0;
        DECLARE @AverageDialogTime INT = 0;
        DECLARE @AverageWaitingTime INT = 0;
        DECLARE @MaximumWaitingTime INT = 0;
        DECLARE @DefaultValue INT = 2
		--(SELECT CASE 
		--WHEN defaultServiceLevelParameter IS NULL THEN 2 
		--WHEN defaultServiceLevelParameter = 0 THEN 2
		--ELSE defaultServiceLevelParameter END
		--FROM contactMeanIn WHERE inboundId = @camId);

		SET @DefaultValue = @DefaultValue * 60;
        DECLARE @LessThanDefault INT = 0;
        DECLARE @ReceivedConversations INT = 0;
        DECLARE @ServiceLevel SMALLINT = 0;

        --------- Modify Average Conversation, Dialog Time, Queue/Waiting Time, Maximum Waiting Time and Service Level ------------

        SELECT @AverageConversationTime = ROUND(AVG(tConversation), 4),
                @AverageDialogTime = ROUND(AVG(tChatting), 4),
                @AverageWaitingTime = ROUND(AVG(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END), 4),
                @MaximumWaitingTime = MAX(CASE WHEN tQueue > 0 THEN tQueue ELSE NULL END),
                @ReceivedConversations = COUNT(conversationDate),
                @LessThanDefault = COUNT(CASE WHEN DATEDIFF(SECOND, assignDate , FirstMessageAgent) <= @DefaultValue THEN 1 ELSE NULL END)
        FROM ccWhatsAppConversationsOut WHERE camId = @camId
        AND requestDate >= @Today

        SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

        ----------------------------------------------------- Update table --------------------------------------------------------

        IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE camId = @camId)
        BEGIN
            UPDATE ccWAAverageConversationsOut
            SET AverageConversationTime = @AverageConversationTime,
                AverageDialogTime = @AverageDialogTime,
                AverageWaitingTime = @AverageWaitingTime,
                MaximumWaitingTime = @MaximumWaitingTime,
                ServiceLevel = @ServiceLevel,
                StatusUpdate = 0,
                LastUpdate = GETDATE()
            WHERE CamId = @camId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversationsOut (CamId, AverageConversationTime, AverageDialogTime,
                                                    AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
            VALUES(@camId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                    @ServiceLevel, 0 , GETDATE())
        END
    END
    --------------------------------- Results -----------------------------------

    SELECT ISNULL(conv.AverageConversationTime, 0) AS AverageConversationTime,
            ISNULL(AverageDialogTime, 0) AS AverageDialogTime,
            ISNULL(AverageWaitingTime, 0) AS AverageWaitingTime,
            ISNULL(MaximumWaitingTime, 0) AS MaximumWaitingTime,
            ISNULL(ServiceLevel, 0) AS ServiceLevel,
            ISNULL(Attended, 0) AS Attended,
            ISNULL(Assigned, 0) AS Assigned,
            ISNULL(OnQueue, 0) AS OnQueue,
            ISNULL(EndedBySystem, 0) AS EndedBySystem,
            ISNULL(Available, 0) AS Available,
            ISNULL(Request, 0) AS Request
    FROM ccWAAverageConversationsOut conv
    RIGHT JOIN ccWAOperatingSummaryOut summary ON conv.CamId = summary.camId
    WHERE conv.CamId = @camId OR summary.camId = @camId
END
else IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
                -- Average Queue/Waiting Time, and Service Level)
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversationsOut WHERE CamId = @camId)
        BEGIN
            UPDATE ccWAAverageConversationsOut SET StatusUpdate = 1
            WHERE CamId = @camId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversationsOut (CamId, StatusUpdate)
            VALUES(@camId, 1)
        END
END
else IF @Option = 3 -- Save time from accepted conversation by agent
BEGIN
    IF @ConversationId IS NOT NULL
    BEGIN
        UPDATE ccWhatsAppConversationsOut SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
        --Save Conversation Assigned
        SELECT @camId = camId FROM ccWhatsAppConversationsOut where conversationId=@conversationId;
        UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE InboundId = @camId
        
    END
END
else IF @Option = 4 -- Get Disposition Information
BEGIN
declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
select @nIdioma = case valor when 0 then ''Sin calificaci?n'' else ''No disposition'' end
from ccsettings where setting_id = 27 -- 0esp
SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
		ISNULL(disposition.calif_id, 0) AS DispositionId,
		COUNT(whatsConv.disposition) AS Total,
		ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
		COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
FROM ccWhatsAppConversationsOut whatsConv
LEFT JOIN ccTipoCalifOUT disposition ON disposition.calif_id = whatsConv.disposition
WHERE camId = @camId AND assignDate >= @Today
	and whatsConv.conversationStatus != 2
GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
END
else IF @Option = 5 -- Get Subdisposition Information
BEGIN
    SELECT relation.calif_id AS DispositionId,
            subDispositions.califSubDesc AS SubDispositionsName,
            COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
    FROM cctipoSubCalifRel relation
    INNER JOIN ccTipoCalifSubOUT subDispositions ON subDispositions.califSub_id = relation.califSub_id
    INNER JOIN ccWhatsAppConversationsOut whatsConv ON whatsConv.subDisposition = subDispositions.califSub_id
    WHERE whatsConv.camId = @camId AND
            whatsConv.assignDate >= @Today AND
            relation.tipoSubRel = 0
    GROUP BY subDispositions.califSubDesc, relation.calif_id
END
ELSE IF @Option = 6 -- Agents Availables
BEGIN
    IF NOT EXISTS (SELECT camId FROM ccWAConversationsResult WHERE camId = @camId)
        BEGIN
            INSERT INTO ccWAOperatingSummaryOut (camId, Available) VALUES (@camId, @AgentsAvailables);
        END
    ELSE
        BEGIN
            UPDATE ccWAOperatingSummaryOut SET Available = @AgentsAvailables WHERE camId = @camId
        END
END

ELSE IF @Option = 7 -- Whats Conversations Results
BEGIN
	SELECT ISNULL(SentMsg, 0) AS SentMsg,
			ISNULL(Delivered, 0) AS Delivered,
			ISNULL(NotDelivered, 0) AS NotDelivered,
			ISNULL(ReadMsg, 0) AS ReadMsg,
			ISNULL(NotSupported, 0) AS NotSupported
	FROM ccWAConversationsResult
	WHERE camId = @camId
END
    
SET NOCOUNT OFF'
    EXEC(@sql)

    set @process = 'Dineria Alter Sp ccsp_OUTGetNewJobsSMS se agrega and msg.message is not null'
    set @sql='ALTER procedure [dbo].[ccsp_OUTGetNewJobsSMS]
@CAMPID INT,
@action INT=0, --0 select and update, 1 select registry
@topCount INT=50

as
set nocount on
DECLARE @iZonas INT = NULL
DECLARE @bIsDaylight bit, @revHorario bit
DECLARE @country_id INT, @TipoJobs INT

DECLARE @sql nvarchar(MAX), @Order_Asc_Desc char(4)
declare @sqlInsertGeneric nvarchar(MAX)
declare @parameters nvarchar(MAX)
		
-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
SELECT @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
SELECT @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

exec @iZonas= ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0

if exists(SELECT cam_id from ccSmsSchedules where cam_id=@campid)
begin
	if @iZonas = 0 begin
		print ''Sin Zona horaria''
		SELECT 0 as SmsOutId, 0 as CamId, '''' as Phone, 0 as SmsStatus, '''' as DateDial, 0 as user_id, 0 as tz where 1=0		
		return
	end
end


IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS

CREATE TABLE #NEW_JOBS (
	SmsOutId INT
	,CamId INT
	,Phone VARCHAR(30) collate SQL_Latin1_General_CP1_CI_AS
	,SmsStatus TINYINT
	,DateDial DATETIME
	,Tz1 INT
	,Tz2 INT
	,Tz3 INT
	,Tz4 INT
	,Tz5 INT
	,CallKey VARCHAR(40)
	,Message VARCHAR(255)
	)
set @sql=''''

DECLARE @new_calls_date VARCHAR(max) = '''';
		

SELECT @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

DECLARE @isVerano varchar(max)

	set @isVerano = ''W.iTimeZone'' + case @bIsDaylight when 1 then ''_summer'' else '''' END

	select @sqlInsertGeneric=nchar(13)+ ''INSERT #NEW_JOBS
SELECT top(@topCount) W.smsout_id, W.cam_id, W.sms_phoneNumber, W.sms_status, W.sms_dateDial,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
sos.callkey as CallKey
,msg.message as Message
FROM smsWorkingTable W with(nolock)
left join smsOutSource sos with(nolock) on sos.smsout_id=W.smsout_id
left join smsoutSourceMessage msg with(nolock) on msg.smsout_id =W.smsout_id
WHERE STATUS_REPLACE_QUERY
and DATE_REPLACE_QUERY
and W.cam_id=@CAMPID
and msg.message is not null
and (
   ( (''+@isVerano+''  & @iZonas)>0 or ''+@isVerano+''=0) 
or ( (''+@isVerano+''2 & @iZonas)>0 or ''+@isVerano+''2=0) 
or ( (''+@isVerano+''3 & @iZonas)>0 or ''+@isVerano+''3=0) 
or ( (''+@isVerano+''4 & @iZonas)>0 or ''+@isVerano+''4=0)
or ( (''+@isVerano+''5 & @iZonas)>0 or ''+@isVerano+''5=0)
)''

if @TipoJobs in(0,2)--** INCLUIR LOS NUEVAS
begin				
	select @sql=@sql+nchar(13)+''--INCLUIR LAS NUEVAS--''
	select @sql=@sql+REPLACE(
	REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.sms_dateDial < dateadd(mi, 5, getdate())'')
		,''STATUS_REPLACE_QUERY'',''W.sms_status=0'')
	select @sql=@sql+nchar(13)+'' order by W.sms_dateDial ''+ @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc
	--print(@sql)
end -- TOMA EN CUENTA LAS NUEVAS

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin
	select @sql=@sql+nchar(13)+''--INCLUIR LOS CALLBACKS--''
	select @sql=@sql+nchar(13)+REPLACE(
		REPLACE(@sqlInsertGeneric,''DATE_REPLACE_QUERY'',''W.sms_dateDial<dateadd(mi, 5, getdate())'')
	,''STATUS_REPLACE_QUERY'',''W.sms_status=1 -- CallBacks'')
	select @sql=@sql+nchar(13)+'' order by priority_cb desc, W.sms_dateDial ''  + @Order_Asc_Desc +'', smsout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
		
					
end -- TOMA EN CUENTA LOS CALLBACKS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
set @parameters=''@CAMPID int,@topCount int,@iZonas int''		

if @action=0
begin	
	SELECT @sql=@sql+nchar(13)+ ''UPDATE smsWorkingTable with (rowlock) SET sms_status=2 --CALLBACK IN PROGRESS
	WHERE smsout_id in(SELECT SmsOutId from #NEW_JOBS)''	
end

		
	select @sql=@sql+nchar(13)+ ''SELECT SmsOutId, CamId, Phone, SmsStatus, DateDial,
Tz1,Tz2,Tz3,Tz4,Tz5,CallKey as RegistryClient,Message
FROM #NEW_JOBS where len(Phone)>0
''


--print (@sql)
--print ''@iZonas:'' +convert(varchar(max),@iZonas)

exec sp_executesql  @sql,@parameters,
@CAMPID=@CAMPID
,@topCount=@topCount
,@iZonas=@iZonas

IF OBJECT_ID(N''tempdb..#NEW_JOBS'') IS NOT NULL  DROP TABLE #NEW_JOBS

return(0)'
    EXEC(@sql)


    set @process = 'CW-8341 El Valor de registros contactados no cambia de 0.0% Alter Sp ccsp_GetInfoDash correcion @vop3 cuando es null'
    set @sql='ALTER procedure [dbo].[ccsp_GetInfoDash]
@CampId as smallint
as
set nocount on				
declare @upd_date as datetime
declare @cps  as int 
declare @today datetime

select @cps = [valor] from ccSettings  where setting_id=238
select
	@upd_date = date_update
from ccCampsInfo with(nolock) where cam_id = @CampId

set @today=convert(date,getdate(),121)

if @upd_date is null begin
	insert into ccCampsInfo(cam_id,contact_reg,dial_retries,date_update,calls_per_second)
	values(@CampId,0,0,getdate(),@cps)

	set @upd_date=@today
end

if (datediff(ss, @upd_date, getdate()) > 300) begin
	if not exists(select cam_id from ccocallsout with(nolock)
	where cam_id=@CampId and statuscall_id=13 and cal_inicio>= @today)
	begin
		update ccCampsInfo
			set contact_reg=0, dial_retries=0, date_update = getdate(), calls_per_second=@cps
		where cam_id = @CampId		
	end else
	begin

		declare @vop1 decimal(5,2)
		declare @vop2 decimal(5,2)
		declare @vop3 decimal(5,2)
		declare @vop4 decimal(5,2)

		select @vop1 = count(distinct(callout_id)) from ccocallsout with(nolock)
		where cam_id = @CampId and statuscall_id=13 and cal_inicio>= @today
		group by cam_id
		select @vop2 = count(distinct(callout_id)), @vop4 = count(distinct telefono) from ccoLogDials with(nolock) 
		where cam_id = @CampId and fecha >= @today
		group by cam_id
		select @vop3 = count(distinct telefono) from ccoLogDials with(nolock) 
		where cam_id = @CampId and fecha >= @today
		group by cam_id, Telefono having count(1) > 1
		
		if @vop3 is null 
			set @vop3=0
	
		update ccCampsInfo set
			 contact_reg=case when @vop2=0 then 0 else (@vop1/@vop2)*100 end
			, dial_retries=case when @vop4=0 then 0 else(@vop3/@vop4)*100 end
			, date_update=getdate()
	end
end

select
cam_id, contact_reg, dial_retries, date_update, calls_per_second
from ccCampsInfo
where cam_id = @CampId


set nocount off'
    EXEC(@sql)

    set @process = 'Alter Sp ccsp_ConversationWASave IF @action = 6'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
                    , @conversationId     INT         = 0
                    , @inboundId          SMALLINT    = NULL
                    , @phoneACD           VARCHAR(50) = NULL
                    , @clientId           VARCHAR(25) = NULL
                    , @conversationStatus SMALLINT    = 0
                    , @tChatting          FLOAT    = 0
                    , @tWrapUp            SMALLINT    = 0
                    , @finishedBy         TINYINT     = 0
                    , @onQueue            BIT         = NULL
                    , @tQueue             SMALLINT    = 0
                    , @tTimeout           INT         = 0
                    , @disposition        SMALLINT    = 0
                    , @subDisposition     SMALLINT    = 0
                    , @agentId            INT         = 0
                    --VAR MESSAGES
                    , @messageId          VARCHAR(50) = NULL
                    , @messageIdUi        INT         = NULL
                    , @clientNum          VARCHAR(15) = NULL
                    , @vonageNum          VARCHAR(15) = NULL
                    , @typeMessage        VARCHAR(25) = ''''
                    , @content            NVARCHAR(MAX)= NULL
                    , @timeStampMessage   DATETIME    = NULL
                    , @timeStampMessageUTC DATETIME   = NULL
                    , @originType         VARCHAR(15) = NULL
                    , @currency           VARCHAR(10) = ''-''
                    , @price              VARCHAR(10) = ''0.00''
                    , @messageStatus      VARCHAR(15) = ''N/A''
                    , @listConversationsIds   VARCHAR(MAX) = NULL
					, @IsAgentLoggingOut  BIT = 0
AS
BEGIN
	DECLARE @isEndConversation BIT;
	DECLARE @meanContactTypeId SMALLINT;
	DECLARE @conversationIdNew INT;
	SET @meanContactTypeId = 1;
	SET NOCOUNT ON;

	IF @action = 1
	BEGIN --new Conversation
		IF NOT EXISTS
			(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A
			WHERE A.conversationId = @conversationId
			)
		BEGIN
			INSERT INTO [ccWhatsAppConversations]
			(inboundId
			, phoneACD
			, clientId
			, conversationStatus
			, tChatting
			, tWrapUp
			, finishedBy
			, onQueue
			, tQueue
			, tTimeout
			, disposition
			, subDisposition
			, agentId
			)
			VALUES(@inboundId, @phoneACD, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);

			IF NOT EXISTS (SELECT WhatsAppSpamId FROM ccWhatsAppSpam WHERE NumberClient = @clientId and InboundId = @inboundId) BEGIN
				SELECT @conversationId = SCOPE_IDENTITY();
				SELECT @conversationId AS ConversationId;
			END
			ELSE BEGIN

				declare @conversationIdTemporal     INT;
				SELECT @conversationIdTemporal = SCOPE_IDENTITY();
				EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationIdTemporal, @conversationStatus = 13
				SELECT 0 AS ConversationId;
			END;

			--Save new request
			IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @inboundId)
				BEGIN
					INSERT INTO ccWAOperatingSummary (InboundId, Request) VALUES (@inboundId, 1);
				END
			ELSE
				BEGIN
					UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId
				END



			RETURN(0);
		END
		ELSE
		BEGIN
			DECLARE @conversationStatusTemp INT = @conversationStatus;
			IF @conversationStatus in(17,18) BEGIN
				SET @conversationStatusTemp = 1
			END
				INSERT INTO [ccWhatsAppConversations]
			(inboundId
			, phoneACD
			, clientId
			, conversationStatus
			, tChatting
			, tWrapUp
			, finishedBy
			, onQueue
			, tQueue
			, tTimeout
			, disposition
			, subDisposition
			, agentId
			)
			VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
			SELECT @conversationIdNew = SCOPE_IDENTITY();

			INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
					                                            , conversationIdAfter)
				VALUES (@conversationId, @conversationIdNew);
			--Save new request by reassign
			UPDATE ccWAOperatingSummary SET Request = (Request + 1) WHERE InboundId = @inboundId

		EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

		SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship where conversationIdBefore = @conversationId;
		RETURN(0);
	END;
END;

IF @action = 2
BEGIN --save conversation Times
	DECLARE @conversationIdTemp INT;
	DECLARE @TablaTemp TABLE (conversationId INT, status bit);

	IF @listConversationsIds IS NOT NULL begin
		INSERT INTO @TablaTemp
		SELECT value,0
		FROM fn_RIASplitDelimited(@listConversationsIds, '','')
		where value is not null and value<>''''
	end
	else begin
		INSERT INTO @TablaTemp values(@conversationId,0)
	end

	UPDATE ccWhatsAppConversations
	SET
	conversationStatus = @conversationStatus
	, finishedBy = case when @conversationStatus = 10 then 2
		when @conversationStatus = 17 then 2
		when @conversationStatus = 18 then 2
		else 1 end
	, tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
	,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
	,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
	WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

		WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
	BEGIN
		select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
		exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

		IF @conversationStatus in(13,10,17,18,11) BEGIN
			DECLARE @conversationDateTemp INT;
			select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end from ccWhatsAppConversations where conversationId = @conversationId;

			IF @conversationStatus = 13 BEGIN
				IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
					INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
				END
			END
			ELSE IF @conversationStatus in(10,17,18) BEGIN --Save conversation Ended by system
				IF @conversationDateTemp > 0 BEGIN
					UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
				END
				ELSE BEGIN
					    UPDATE ccWAOperatingSummary SET EndedBySystem = (EndedBySystem + 1) WHERE InboundId = @inboundId
				END
			END
			ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
				UPDATE ccWAOperatingSummary SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE InboundId = @inboundId
			END
		END
		update @TablaTemp set status=1 where conversationId=@conversationIdTemp
	END

END;

IF @action = 3
BEGIN --save conversation Status
	UPDATE ccWhatsAppConversations
			SET
				--conversationDate = GETDATE(),
				conversationStatus = @conversationStatus
	WHERE conversationId = @conversationId;
END;

IF @action = 4 BEGIN --save messages from conversation
	IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A WHERE A.conversationId=@conversationId)
		AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversations A WHERE A.messageId=@messageId)
	BEGIN
		IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
			(SELECT messageIdUi
				FROM ccWAMessagesConversations
				WHERE originType IN (''Agent'', ''Admin'')
				AND conversationId = @conversationId)
			BEGIN
				UPDATE ccWhatsAppConversations
					SET FirstMessageAgent = @timeStampMessage
					WHERE conversationId = @conversationId;
			END

		INSERT INTO [ccWAMessagesConversations](
					                        messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
					                        (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
		SELECT @messageId=SCOPE_IDENTITY()
		SELECT @messageId as MessageId
		RETURN (0)
	END
	ELSE BEGIN
		SELECT 0 AS MessageId
		RETURN (0)
	END
END;

	IF @action = 5
	BEGIN --save onQueue
		UPDATE ccWhatsAppConversations
				SET onQueue = 1,
				conversationStatus = @conversationStatus
		WHERE conversationId = @conversationId;
		SELECT @inboundId = inboundId FROM ccWhatsAppConversations where conversationId=@conversationId;
		UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
	END;

IF @action = 6
BEGIN --save agent, assigdate and tqueue
	declare @agentIdTmp int
	SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A where A.conversationId = @conversationId

	IF (@agentIdTmp is null or @agentIdTmp=0)
	BEGIN
		UPDATE ccWhatsAppConversations
				SET agentId = @agentId,
				assignDate = getdate(),
				conversationStatus = @conversationStatus
				,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
		WHERE conversationId = @conversationId;

		SELECT @conversationId as conversationId
	SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations where conversationId=@conversationId;
	declare @onQueueInt int

	IF @onQueue = 1 BEGIN
		UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1),@onQueueInt =OnQueue WHERE InboundId = @inboundId
		if @onQueueInt<=0 or exists(select * from ccWAOperatingSummary WHERE InboundId = @inboundId and OnQueue<0)begin

			select			
			@onQueueInt=count(case when onQueue =1 then 1 end) onQueue			
			from ccWhatsAppConversations with(nolock)
			where inboundId= @inboundId
			and requestDate>=convert(date,getdate(),121)

			UPDATE ccWAOperatingSummary SET OnQueue = @onQueueInt WHERE InboundId = @inboundId

		end

	END
	END
END;

	IF @action = 7
	BEGIN --update price message
		UPDATE ccWAMessagesConversations
				SET price = @price,
					currency = @currency
		WHERE messageId = @messageId;
	END;

	IF @action = 8
	BEGIN --update status message
		IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
			UPDATE ccWAMessagesConversations
					SET messageStatus = @messageStatus
			WHERE messageId = @messageId;
		END;
	END;

	IF @action = 9
	BEGIN --Save last message time by conversationID
		IF not exists(SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversation A WHERE A.conversationId=@conversationId) BEGIN
			INSERT INTO ccLastMessageAgentByConversation (conversationId,timeStampLastMessageAgent) VALUES (@conversationId,getDate())
		END;
		ELSE
			BEGIN
				UPDATE ccLastMessageAgentByConversation
					SET timeStampLastMessageAgent = getDate()
				WHERE conversationId = @conversationId;
			END;
	END;

	IF @action = 10
	BEGIN --drop and insert register by conversationID
		DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
	END;

	IF @action = 11
	BEGIN --register desconnection agent by conversationID
		UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
	END;

	IF @action = 12
	BEGIN --Obtain conversationsWA post MCS reset

		declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
		UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

		declare @from as datetime;-- = ''01-07-2022'';
		select @from = convert(datetime,convert(varchar(11),getdate()))
		set @from=DATEADD(dd,-1,@from);
			select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
			,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
			from ccWhatsAppConversations A
			left join ccWAMessagesConversations B on A.conversationId = B.conversationId
			left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp
			--where B.conversationId is null
			where A.requestDate >= @from 
				and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
			order by agentId desc, requestDate,timeStampMessage, inboundId, clientId 
	END;
	IF @action = 13
	BEGIN ---Obtain agents ON STATUS READY
		WITH agents
		AS(
			SELECT c.User_id, c.fecha, c.currentStatus
			FROM ccLogAgentesDia c
			INNER JOIN 
			(
				SELECT User_id, MAX(fecha) max_time
				FROM ccLogAgentesDia
				GROUP BY User_id
			) AS t
			ON c.fecha = t.max_time
			AND c.User_id=t.User_id AND currentStatus in (3,34)
		), usersByCampigns
		AS (
			select IdCampEsp, User_id from ccRIACampEspWG A
			Inner join ccRIAWorkGroupUsers B
			on A.IDWG = B.IDWG
			Inner join contactMeanIn C
			ON A.idCampEsp = C.inboundId
			where A.IDWG = 1 and A.Tipo = 0
			AND C.meanContactTypeId = 5
		)

		select DISTINCT A.User_Id from agents A
		left join usersByCampigns B on A.User_Id = B.User_Id
	END;

	IF @action = 14
	BEGIN --register desconnection MCS
		INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
	END;

	IF @action = 15
	BEGIN --update content message
		IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
			UPDATE ccWAMessagesConversations
					SET content = @content
			WHERE messageId = @messageId;
		END;
	END;

	IF @action = 16
	BEGIN --update agent status for reassigning error message
		IF EXISTS(SELECT 0 FROM ccWhatsAppConversations WHERE conversationId = @conversationId)
		BEGIN
			UPDATE ccWhatsAppConversations
			SET IsAgentLoggingOut = @IsAgentLoggingOut
			WHERE conversationId = @conversationId;
		END;
	END;
END;'
    EXEC(@sql)

    set @process = ''
    set @sql=''
    EXEC(@sql)

    set @process = ''
    set @sql=''
    EXEC(@sql)

    set @process = ''
    set @sql=''
    EXEC(@sql)

    set @process = ''
    set @sql=''
    EXEC(@sql)

    set @process = ''
    set @sql=''
    EXEC(@sql)

    set @process = ''
    set @sql=''
    EXEC(@sql)

    ---------------------------------------BEGIN Jesus Gallardo hotfix/125.20231211.0.9---------------------------------------------------------




        /* End script release */        /* Upgrade database version (first and the last number of setting 77) */
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
