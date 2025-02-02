/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 02/02/2024
Description: K089000

Database: CCenterRia
Required version: 125.48

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
SET @versionfix = 48
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 5;

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

        SET @process = 'update ccCamps set CampType =0 where CampType is null'
        SET @sql = 'update ccCamps set CampType =0 where CampType is null'
        EXEC(@sql);

        --------------------------------------------------- START DEV2-380 Hugo Longoria -------------------------------------------------------------

        set @process = 'DROP FUNCTION fn_getSIPHeaderCfg'
        set @sql = 'IF EXISTS (SELECT 1 FROM sys.objects 
                       WHERE Name = ''fn_getSIPHeaderCfg'' 
                         AND Type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
            BEGIN
                DROP FUNCTION dbo.fn_getSIPHeaderCfg
            END'
        EXEC(@sql)

        set @process = 'CREATE FUNCTION fn_getSIPHeaderCfg'
        set @sql = 'CREATE function [dbo].[fn_getSIPHeaderCfg](@callout_id int, @format varchar(500))
            returns varchar(500)
            as
            begin
                declare @result varchar(500)
                DECLARE @col varchar(MAX);
                SELECT @col = coalesce(@col,'''')+case when charindex(value,@format)>0 then value else '''' end
                FROM dbo.fn_RIASplitDelimited(''_CAMID_|_KEY_|_D1_|_D2_|_D3_|_D4_|_D5_|_CALLOUT_'',''|'')
                if len(isnull(@col,'''')) = 0 return isnull(@format,'''')

                SELECT 
                    @result = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@format,''_CAMID_'',cast(cam_id as varchar(5))),''_KEY_'',cal_Key),''_D1_'',Dato1),''_D2_'',Dato2),''_D3_'',Dato3),''_D4_'',Dato4),''_D5_'',Dato5),''_CALLOUT_'',cast(@callout_id as varchar(10)))
                FROM ccocallsoutsource nolock where callout_id=@callout_id

                return isnull(@result,'''')
            end'
        EXEC(@sql)

        ---------------------------------------------------- END DEV2-380 Hugo Longoria --------------------------------------------------------------

        set @process = 'Alter SP ccsp_OUTGetNewJobs se modifica la linea exec @iZonas=ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0'
        set @sql = '
ALTER PROCEDURE ccsp_OUTGetNewJobs
@CAMPID int,
@test int=0,
@nAgentsLogin int=1,
@iZonas int = NULL,
@isDashboardApi BIT = 0
as
--set nocount on
declare @total int
declare @topCount smallint, @bIsDaylight bit, @revHorario bit
declare @country_id int, @TipoJobs int
--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
declare @sql varchar(MAX), @Order_Asc_Desc char(4)
declare @camSurvey INT, @campType INT;
select @camSurvey = 0
DECLARE @iZonasTable TABLE (value int)
declare @maxRecs varchar(3) = 0

select @maxRecs = valor from ccsettings (nolock) where setting_id = 251 and Status = 1      
select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0;
SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id =  @CAMPID;

-- VALIDAMOS EL IDIOMA Y LADA CONFIGURADA --
SELECT @country_id=valor FROM ccSettings WHERE setting_id=104
select @revHorario=valor from ccsettings where setting_id = 112
-- VALIDAMOS EL ORDER EN COMO SE VAN A MOSTRAR LOS REGISTROS --
SELECT @Order_Asc_Desc=case dialOrder when 1 then ''desc'' else ''asc'' end FROM ccCamps WHERE cam_id=@CAMPID
SELECT @Order_Asc_Desc=isnull(@Order_Asc_Desc,''asc'')

SET DATEFIRST 1
--Checamos si es horario de verano
select @bIsDaylight = dbo.fnIsDayLight (@country_id, getdate())

if @iZonas is null begin

        exec @iZonas=ccsp_OUTcheckTimeZone @cam_id=@campid,@isReturnSelect=0              
--Checamos si la campaña tiene horarios configurados
        if exists(select cam_id from ccCampsHorarios with(index(IX_ccCampsHorarios)) where cam_id=@campid)
        begin
                    if @iZonas = 0 begin
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                    end
        end
        else begin
            if @camSurvey > 0
                    begin
                        SELECT 0 as callout_id, 0 as cam_id, '''' as cal_telefono, 0 as cal_status, '''' as cal_fechaDial, 0 as user_id, 0 as tz where 1=0
                        return
                    end
        end
end

set @sql=''CREATE TABLE #NEW_JOBS
(callout_id int,
        cam_id int,
        cal_telefono varchar(15)collate SQL_Latin1_General_CP1_CI_AS,
        cal_status tinyint,
        cal_fechaDial datetime,
        user_id int,
        tz int,
tz2 int,
tz3 int,
tz4 int,
tz5 int,
list_id int,
sequence smallint,
calkey varchar(max),
nDescartes int,
name_agent varchar(max),
SimultaneousRecs int,
tz_tmp int,
tz2_tmp int,
tz3_tmp int,
tz4_tmp int,
tz5_tmp int
)''


-- 0=Ambas, 1=CallBacks, 2=Nuevas
select @topCount=valor from ccSettings where setting_id=94

if isnull(@topCount,0)=0
select @topCount=case when @nAgentsLogin<3 then 30
        when @nAgentsLogin>=3 and @nAgentsLogin<6 then 70
        when @nAgentsLogin>=6 and @nAgentsLogin<10 then 120
        when @nAgentsLogin>=10 and @nAgentsLogin<16 then 180
        when @nAgentsLogin>=16 then 240 else 20 end

select @TipoJobs=cam_TipoJobs from ccCamps where cam_id=@CAMPID

declare @isVerano varchar(max)
set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' END        

if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
begin

            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';
            select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5
FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
left join ccCampsExtend ce on ce.cam_id=W.cam_id
WHERE W.cal_status=1 -- CallBacks
and W.cal_fechaDial<getdate() -- Los vencidos hasta Ahora
and W.cam_id='' + cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
and (
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
        ((W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
)
and isnull(R.status,2) = 2
order by prioridad_cb desc, W.cal_fechaDial ''  + @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc-- Solo se aplica el order en registros Nuevos (cal_status=0)
                    
end -- TOMA EN CUENTA LOS CALLBACKS

if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
begin
            select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar );

            select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS'';
            
select @sql=@sql+nchar(13)+ ''SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5
FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
left join ccCampsExtend ce on ce.cam_id=W.cam_id
WHERE W.cal_status=0 -- Nuevas
and W.cal_fechaDial<getdate()-- Los vencidos hasta Ahora
and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
and (
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
)
and isnull(R.status,2) = 2
order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc

end -- TOMA EN CUENTA LAS NUEVAS
----------------------- RETORNA LOS RESULTADOS OBTENIDOS -------------------------------
select @sql=@sql+nchar(13)+ ''SET rowcount 0''
if @Test=0
        begin
select @sql=@sql+nchar(13)+ ''UPDATE ccoWorkingTable with (rowlock) SET cal_status=2 --CALLBACK IN PROGRESS
WHERE callout_id in(select callout_id from #NEW_JOBS)''
end

if @Test = 2
begin
        select @sql=@sql+nchar(13)+ '' SELECT @outA=count(*) FROM #NEW_JOBS where len(cal_telefono)>0''
        declare @nSQL nvarchar(4000)
        set @nSQL=cast(@sql as nvarchar(4000))
        exec sp_executesql @nSQL, N''@outA int OUTPUT'',@outA=@total OUTPUT
        return(@total)
end
else
BEGIN
    IF(@isDashboardApi = 1)
    BEGIN
select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
+@isVerano+'',''
+@isVerano+''2,''
+@isVerano+''3,''
+@isVerano+''4,''
+@isVerano+''5,
W.list_id, isNull(R.sequence,0) as sequence,
cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey, W.nDescartes,
isnull(us.nombres, '''''''') + '''' '''' + isnull(us.ApellidoPaterno, '''''''') + '''' '''' + isnull(us.ApellidoMaterno, '''''''') Name_agent, SimultaneousRecs,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'',
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 ,
cs.iZonaHoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5
FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
left join ccUsers us (nolock) on us.User_id=w.user_id
left join ccCampsExtend ce on ce.cam_id=W.cam_id
WHERE W.cal_status= 1 -- Procesando
and W.cal_fechaDial< getdate()-- Los vencidos hasta Ahora
and W.cam_id=''+ cast(isnull(@CAMPID,''0'') as varchar(7)) + ''
and (
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+'' & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''=0) or
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''2=0) or
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''3=0) or
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''4=0) or
        ( (W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5 & '' + cast(isnull(@iZonas,0) as varchar(20))+ '')>0
or W.izonahoraria''+case @bIsDaylight when 1 then ''_verano'' else '''' end+''5=0)
)
and isnull(R.status,2) = 2
order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id ''+ @Order_Asc_Desc
    -- TOMA EN CUENTA LOS REGISTROS PROCESANDOSE
    END

    select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, user_id,
case when tz>0  then tz  else tz_tmp end as tz,
case when tz2>0 then tz2 else tz2_tmp end as tz2,
case when tz3>0 then tz3 else tz3_tmp end as tz3,
case when tz4>0 then tz4 else tz4_tmp end as tz4,
case when tz5>0 then tz5 else tz5_tmp end as tz5,
case when tz is null then '''''''' else cal_telefono end as tel,
case when tz2 is null then '''''''' else cal_telefono end as tel2,
case when tz3 is null then '''''''' else cal_telefono end as tel3,
case when tz4 is null then '''''''' else cal_telefono end as tel4,
case when tz5 is null then '''''''' else cal_telefono end as tel5,
NULL as dialOrder, list_id, sequence, calkey,
0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type, nDescartes, name_agent, SimultaneousRecs,'' + @maxRecs + '' maxRecs
FROM #NEW_JOBS where len(cal_telefono)>0

---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
declare @regval int
SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0    
    ''
end

set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
-- print (@sql)
exec(@sql)

return(0)
    '
    EXEC(@sql)

     SET @process = 'ALTER SP ccsp_WhatsAppGlobalIds select @globalId as globalId'
     SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_WhatsAppGlobalIds]  
        @ConversationType TINYINT = -1,
        @ConversationId INT = 0,
        @MessageId VARCHAR(MAX) = '''',
        @AssociatedNumber VARCHAR (30), 
        @ClientNumber VARCHAR(30)
AS  
SET NOCOUNT ON;  

    IF @ConversationType = 0 AND NOT EXISTS(SELECT 1 FROM ccWhatsAppConversations WHERE conversationId = @ConversationId)
    BEGIN
        RAISERROR(''ERROR. No existe una conversación de entrada con el id especificado'', 18, 1);
        RETURN(0);
    END;
    ELSE IF @ConversationType = 1 AND NOT EXISTS(SELECT * FROM ccWhatsAppConversationsOut WHERE conversationId = @ConversationId)
    BEGIN
        RAISERROR(''ERROR. No existe una conversación de salida con el id especificado'', 18, 1);
        RETURN(0);
    END;
    ELSE
    BEGIN
        DECLARE @originType VARCHAR(20) = '''';
        DECLARE @firstMessageDateFromAgent DATETIME = NULL;
        DECLARE @messageStatus VARCHAR(20) = '''';
        DECLARE @firstMessageConversationIdFromAgent INT = NULL;
        DECLARE @firstMessageConversationTypeFromAgent TINYINT = NULL;
        DECLARE @isBilled BIT = 0;

        IF @ConversationType = 0 
        BEGIN
            SET @originType = (SELECT originType FROM ccWAMessagesConversations WHERE messageId = @MessageId);
            SELECT @firstMessageDateFromAgent = timeStampMessage, @messageStatus = messageStatus
            FROM ccWAMessagesConversations
            WHERE messageId = @MessageId AND @originType = ''Agent'';
        END;
        ELSE 
        BEGIN
            SET @originType = (SELECT originType FROM ccWAMessagesConversationsOut WHERE messageId = @MessageId);
            SELECT @firstMessageDateFromAgent = timeStampMessage, @messageStatus = messageStatus
            FROM ccWAMessagesConversationsOut
            WHERE messageId = @MessageId AND @originType = ''Agent'';
        END;

        DECLARE @globalId INT = (SELECT MAX(GlobalId) FROM ccWhatsAppGlobalIds WHERE AssociatedNumber = @AssociatedNumber AND ClientNumber = @ClientNumber);

        IF @originType = ''Agent'' AND @messageStatus NOT IN(''rejected'', ''undeliverable'', ''submitted'')
        BEGIN
            SET @firstMessageConversationIdFromAgent = @ConversationId;
            SET @firstMessageConversationTypeFromAgent = @ConversationType;
            SET @isBilled = 1;
        END
        ELSE
        BEGIN
            SET @firstMessageDateFromAgent = NULL
        END

        IF @globalId IS NULL
        BEGIN
            INSERT INTO ccWhatsAppGlobalIds (AssociatedNumber, ClientNumber, FirstMessageDateFromAgent, FirstMessageConversationIdFromAgent, FirstMessageConversationTypeFromAgent, IsBilled)
            VALUES (@AssociatedNumber, @ClientNumber, @firstMessageDateFromAgent, @firstMessageConversationIdFromAgent, @firstMessageConversationTypeFromAgent, @isBilled);

            SET @globalId = SCOPE_IDENTITY();
        END

        DECLARE @TempFirstMessageDate DATETIME = (SELECT FirstMessageDateFromAgent FROM ccWhatsAppGlobalIds WHERE GlobalId = @globalId);
                        
        --Update if message status changes
        IF @originType = ''Agent'' AND @messageStatus NOT IN(''rejected'', ''undeliverable'', ''submitted'') AND @globalId IS NOT NULL
        BEGIN
            UPDATE ccWhatsAppGlobalIds SET IsBilled = 1 WHERE GlobalId = @globalId
        END

        IF DATEDIFF(HOUR, @TempFirstMessageDate, GETDATE()) >= 24 
        BEGIN 
            INSERT INTO ccWhatsAppGlobalIds (AssociatedNumber, ClientNumber, FirstMessageDateFromAgent, FirstMessageConversationIdFromAgent, FirstMessageConversationTypeFromAgent, IsBilled)
            VALUES (@AssociatedNumber, @ClientNumber, @firstMessageDateFromAgent, @firstMessageConversationIdFromAgent, @firstMessageConversationTypeFromAgent, @isBilled);

            SET @globalId = SCOPE_IDENTITY();   
        END

        -- If the message is from agent update the date 
        IF @originType = ''Agent'' AND @TempFirstMessageDate IS NULL
        BEGIN
            UPDATE ccWhatsAppGlobalIds SET FirstMessageDateFromAgent = @firstMessageDateFromAgent,
                                            FirstMessageConversationIdFromAgent =  @ConversationId,
                                            FirstMessageConversationTypeFromAgent = @ConversationType,
                                            IsBilled = @isBilled
            WHERE GlobalId = @globalId;
        END
        -- Insert into ccWhatsAppGlobalIdsRelationship
        IF @globalId != 0 AND NOT EXISTS(SELECT GlobalId FROM ccWhatsAppGlobalIdsRelationship WHERE GlobalId = @globalId AND ConversationId = @ConversationId AND @ConversationType = ConversationType)
        BEGIN
            INSERT INTO ccWhatsAppGlobalIdsRelationship(GlobalId, ConversationId, ConversationType)
            VALUES (@globalId, @ConversationId, @ConversationType)
        END

        select @globalId as globalId

        RETURN(@globalId)
        
    END
SET NOCOUNT OFF'
     EXEC(@sql);


     SET @process = 'Add Column ccWhatsAppConversationsOut.IsAgentLoggingOut'
        SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = N''IsAgentLoggingOut'' and Object_ID = Object_ID(N''ccWhatsAppConversationsOut'')) BEGIN
    ALTER TABLE ccWhatsAppConversationsOut ADD IsAgentLoggingOut BIT null
END '
        EXEC(@sql);

    set @process = 'Alter Sp ccsp_ConversationWASave IF @action = 6 Se modifica para agregar with(nolock) y action=18'
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
            (SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock)
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
            DECLARE @RequestDate DATETIME = NULL;
            SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversations WITH(NOLOCK) WHERE conversationId = @conversationId;

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
            , requestDate
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
            SELECT @conversationIdNew = SCOPE_IDENTITY();

            INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
                                                                , conversationIdAfter)
                VALUES (@conversationId, @conversationIdNew);
            --Save new request by reassign
            UPDATE ccWAOperatingSummary SET Request = (Request + 1)
            WHERE InboundId = @inboundId

        EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

        SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship with(nolock) where conversationIdBefore = @conversationId;
        RETURN(0);
    END;
END;

ELSE IF @action = 2
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
    , finishedBy = case when @conversationStatus in(4,10,17,18) then 2
    when @conversationStatus in(11) then 1
    else 0 end
    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

        WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
    BEGIN
        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

        IF @conversationStatus in(4,10,11,13,17,18) BEGIN
            DECLARE @conversationDateTemp INT;
            select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
            from ccWhatsAppConversations with(nolock) where conversationId = @conversationId;

            IF @conversationStatus = 13 BEGIN
                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
                END
            END
            ELSE IF @conversationStatus in(4,10,17,18) BEGIN --Save conversation Ended by system
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

ELSE IF @action = 3
BEGIN --save conversation Status
    UPDATE ccWhatsAppConversations SET conversationStatus = @conversationStatus
    WHERE conversationId = @conversationId;
END;

ELSE IF @action = 4 BEGIN --save messages from conversation
    IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock) WHERE A.conversationId=@conversationId)
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
        SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
        UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
    END;

ELSE IF @action = 6
BEGIN --save agent, assigdate and tqueue
    declare @agentIdTmp int
    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A with(nolock) where A.conversationId = @conversationId

    IF (@agentIdTmp is null or @agentIdTmp=0)
    BEGIN
        UPDATE ccWhatsAppConversations
                SET agentId = @agentId,
                assignDate = getdate(),
                conversationStatus = @conversationStatus
                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
        WHERE conversationId = @conversationId;

        SELECT @conversationId as conversationId
    SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
    declare @onQueueInt int

    IF @onQueue = 1 BEGIN
        UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1),@onQueueInt =OnQueue WHERE InboundId = @inboundId
        if @onQueueInt<=0 or exists(select * from ccWAOperatingSummary WHERE InboundId = @inboundId and OnQueue<0)begin

            select          
            @onQueueInt=count(case when onQueue =1 then 1 end)
            from ccWhatsAppConversations with(nolock)
            where inboundId= @inboundId
            and requestDate>=convert(date,getdate(),121)

            UPDATE ccWAOperatingSummary SET OnQueue = @onQueueInt WHERE InboundId = @inboundId

        end

    END
    END
END;

ELSE IF @action = 7
BEGIN --update price message
    UPDATE ccWAMessagesConversations
            SET price = @price,
                currency = @currency
    WHERE messageId = @messageId;
END;

ELSE IF @action = 8
BEGIN --update status message
    IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
        UPDATE ccWAMessagesConversations
                SET messageStatus = @messageStatus
        WHERE messageId = @messageId;
    END;
END;

ELSE IF @action = 9
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

ELSE IF @action = 10
BEGIN --drop and insert register by conversationID
    DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
END;

ELSE IF @action = 11
BEGIN --register desconnection agent by conversationID
    UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
END;

ELSE IF @action = 12
BEGIN --Obtain conversationsWA post MCS reset

    declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
    UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

    declare @from as datetime;-- = ''01-07-2022'';
    select @from = convert(datetime,convert(varchar(11),getdate()))
    set @from=DATEADD(dd,-1,@from);
        select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
        ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
        from ccWhatsAppConversations A with(nolock)
        left join ccWAMessagesConversations B on A.conversationId = B.conversationId
        left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp          
        where A.requestDate >= @from 
            and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
        order by agentId desc, requestDate,timeStampMessage, inboundId, clientId 
END;
ELSE IF @action = 13
BEGIN ---Obtain agents ON STATUS READY
    WITH agents
    AS(
        SELECT c.User_id, c.fecha, c.currentStatus
        FROM ccLogAgentesDia c
        INNER JOIN 
        (
            SELECT User_id, MAX(fecha) max_time
            FROM ccLogAgentesDia with(nolock)
            where fecha>=CONVERT(date,getdate(),121)
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

ELSE IF @action = 14
BEGIN --register desconnection MCS
    INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
END;

ELSE IF @action = 15
BEGIN --update content message
    IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
        UPDATE ccWAMessagesConversations
                SET content = @content
        WHERE messageId = @messageId;
    END;
END;

ELSE IF @action = 16
BEGIN --update agent status for reassigning error message
    UPDATE ccWhatsAppConversations
    SET IsAgentLoggingOut = @IsAgentLoggingOut
    WHERE conversationId = @conversationId;
END;

ELSE IF @action = 18 BEGIN
    DECLARE @dateNow DATETIME;
    SET @dateNow = DATEADD(HOUR, -23, GETDATE());

    UPDATE ccWhatsAppConversations
    SET finishedBy = 2, conversationStatus=17
    WHERE finishedBy = 0 AND requestDate <= @dateNow    
END;
END;'
    EXEC(@sql)


        

        SET @process = 'ALTER SP ccsp_WhatsAppInformation @Option=1 se modifica para poder validar que este no regrese valores negativos'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_WhatsAppInformation]
@Option SMALLINT,
@InboundId SMALLINT = 0,
@ConversationId INT = 0,
@AgentsAvailables INT = 0,
@IncreaseDecreaseAgent BIT = NULL

AS
SET NOCOUNT ON

IF @Option = 0 BEGIN-- Reset TABLES
    TRUNCATE TABLE ccWAOperatingSummary;
    TRUNCATE TABLE ccWAAverageConversations;
    TRUNCATE TABLE ccLastMessageAgentByConversation;
END


IF @InboundId IS NULL or  
NOT EXISTS (SELECT * FROM ccInbound with(nolock) WHERE Inbound_id = @InboundId AND chat = 5) 
BEGIN
RETURN (-1)
END

    DECLARE @Today SMALLDATETIME = CAST( GETDATE() AS DATE );
    
IF @Option = 1 -- Generate Averages and Obtain all WhatsApp Campaign Information
BEGIN
    IF EXISTS (SELECT * FROM ccWAAverageConversations with(nolock)
                WHERE InboundId = @InboundId
                AND (LastUpdate IS NULL
                OR ( StatusUpdate = 1 AND  DATEDIFF(ss, LastUpdate, GETDATE()) >= 5)
                OR  DATEDIFF(MI, LastUpdate, GETDATE()) >= 5))
    BEGIN
        -------------------------- ----------------------- Variable Declaration ---------------------------------------------------

        DECLARE @AverageConversationTime INT = 0;
        DECLARE @AverageDialogTime INT = 0;
        DECLARE @AverageWaitingTime INT = 0;
        DECLARE @MaximumWaitingTime INT = 0;
        DECLARE @DefaultValue INT = (SELECT CASE 
                WHEN defaultServiceLevelParameter IS NULL THEN 2 
                WHEN defaultServiceLevelParameter = 0 THEN 2
                ELSE defaultServiceLevelParameter END
        FROM contactMeanIn WHERE inboundId = @InboundId);
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
        FROM ccWhatsAppConversations WHERE inboundId = @InboundId
        AND requestDate >= @Today

        SET @ServiceLevel = CASE WHEN @ReceivedConversations = 0 THEN 0 ELSE ROUND(((@LessThanDefault*1.0) / @ReceivedConversations) * 100, 2) END

        ----------------------------------------------------- Update table --------------------------------------------------------

        IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
        BEGIN
            UPDATE ccWAAverageConversations
            SET AverageConversationTime = @AverageConversationTime,
                AverageDialogTime = @AverageDialogTime,
                AverageWaitingTime = @AverageWaitingTime,
                MaximumWaitingTime = @MaximumWaitingTime,
                ServiceLevel = @ServiceLevel,
                StatusUpdate = 0,
                LastUpdate = GETDATE()
            WHERE InboundId = @InboundId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversations (InboundId, AverageConversationTime, AverageDialogTime,
                                                    AverageWaitingTime, MaximumWaitingTime, ServiceLevel, StatusUpdate, LastUpdate)
            VALUES(@InboundId, @AverageConversationTime, @AverageDialogTime, @AverageWaitingTime, @MaximumWaitingTime,
                    @ServiceLevel, 0 , GETDATE())
        END
    END
    --------------------------------- Results -----------------------------------

    if exists (select * from ccWAOperatingSummary with(nolock) where Inboundid=@InboundId
    and (OnQueue<0 or Assigned<0)
    ) begin                                
        set @Today =convert(date,getdate(),121)

        ;with waOperationSummary as(
                select 
        inboundId
        --,count(case when finishedBy=1 then 1 end) Attend
        ,count(case when onQueue=1 and finishedBy=0 then 1 end) onQueue
        ,count(case when finishedBy=0 and agentId>0 then 1 end) Assigned
        --,count(*) Request
        --,count(case when finishedBy=2 then 1 end) EndedBySystem
        from ccWhatsAppConversations with(nolock)
        where inboundId=@InboundId
        and requestDate>=@Today
        group by inboundId
        )
        update A 
        set A.OnQueue=B.onQueue, A.Assigned=B.Assigned
        from ccWAOperatingSummary A 
        inner join waOperationSummary B on A.Inboundid=B.inboundId
    end


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
    FROM ccWAAverageConversations conv
    RIGHT JOIN ccWAOperatingSummary summary ON conv.InboundId = summary.InboundId
    WHERE conv.inboundId = @InboundId OR summary.InboundId = @InboundId
END
ELSE IF @Option = 2 -- Set Status Change in any column (Average Conversation Time, Average Dialog Time,
    -- Average Queue/Waiting Time, and Service Level)
    BEGIN
        IF EXISTS (SELECT * FROM ccWAAverageConversations WHERE InboundId = @InboundId)
        BEGIN
            UPDATE ccWAAverageConversations SET StatusUpdate = 1
            WHERE InboundId = @InboundId
        END
        ELSE
        BEGIN
            INSERT INTO ccWAAverageConversations (InboundId, StatusUpdate)
            VALUES(@InboundId, 1)
        END
    END
ELSE IF @Option = 3 -- Save time from accepted conversation by agent
    BEGIN
        IF @ConversationId IS NOT NULL
        BEGIN
            UPDATE ccWhatsAppConversations SET conversationDate = GETDATE() WHERE conversationId = @ConversationId;
            --Save Conversation Assigned
            SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
            UPDATE ccWAOperatingSummary SET Assigned = (Assigned + 1) WHERE InboundId = @inboundId
            --EXEC ccsp_WhatsAppOperatingSummary @Option = 2, @InboundId = @CampIdTemp;
        END
    END
ELSE IF @Option = 4 -- Get Disposition Information
    BEGIN
        declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
        select @nIdioma = case valor when 0 then ''Sin calificación'' else ''No disposition'' end
        from ccsettings where setting_id = 27 -- 0esp
        SELECT ISNULL(disposition.Description, @nIdioma) AS DispositionName,
                        ISNULL(disposition.calif_id, 0) AS DispositionId,
                        COUNT(whatsConv.disposition) AS Total,
                        ISNULL(disposition.GraphColor, ''1DB4E2'') AS GraphColor,
                        COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
        FROM ccWhatsAppConversations whatsConv with(nolock) 
        LEFT JOIN cctipocalif disposition ON disposition.calif_id = whatsConv.disposition
        WHERE inboundId = @InboundId AND assignDate >= @Today
                and whatsConv.conversationStatus != 2
        GROUP BY disposition.calif_id, disposition.Description, disposition.GraphColor
    END
ELSE IF @Option = 5 -- Get Subdisposition Information
    BEGIN
        SELECT relation.calif_id AS DispositionId,
                subDispositions.califSubDesc AS SubDispositionsName,
                COUNT(CASE WHEN whatsConv.subDisposition != 0 THEN 1 END) AS SubDispositionQuantity
        FROM cctipoSubCalifRel relation
        INNER JOIN ccTipoCalifSub subDispositions ON subDispositions.califSub_id = relation.califSub_id
        INNER JOIN ccWhatsAppConversations whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
        WHERE whatsConv.inboundId = @InboundId AND
                whatsConv.assignDate >= @Today AND
                relation.tipoSubRel = 1
        GROUP BY subDispositions.califSubDesc, relation.calif_id
    END
ELSE IF @Option = 6 -- Agents Availables
    BEGIN
    IF NOT EXISTS (SELECT InboundId FROM ccWAOperatingSummary WHERE InboundId = @InboundId)
        BEGIN
            INSERT INTO ccWAOperatingSummary (InboundId, Available) VALUES (@InboundId, @AgentsAvailables);
        END
    ELSE
    BEGIN
        UPDATE ccWAOperatingSummary SET Available = @AgentsAvailables WHERE InboundId = @InboundId
    END
END

RETURN(0)
SET NOCOUNT OFF'
        EXEC(@sql);
        
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
        FROM ccWhatsAppConversationsOut with(nolock) WHERE camId = @camId
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

    if exists (select * from ccWAOperatingSummaryOut with(nolock) where CamId=@camId
                and (OnQueue<0 or Assigned<0)
                ) begin
                
            set @Today =convert(date,getdate(),121)

            ;with waOperationSummary as(
            select 
            CamId
            ,count(case when finishedBy=1 then 1 end) Attended
            ,count(case when onQueue=1 and finishedBy=0 then 1 end) onQueue
            ,count(case when finishedBy=0 and agentId>0 then 1 end) Assigned
            ,count(*) Request
            ,count(case when finishedBy=2 then 1 end) EndedBySystem
            from ccWhatsAppConversationsOut with(nolock)
            where camId = @camId and requestDate>=@Today
            group by CamId
            )
            update A 
            set A.Attended=B.Attended, A.Assigned=B.Assigned
            
            ,A.Request=B.Request,A.EndedBySystem=B.EndedBySystem
            from ccWAOperatingSummaryOut A 
            inner join waOperationSummary B on A.CamId=B.CamId
    end

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
        SELECT @camId = camId FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;
        UPDATE ccWAOperatingSummaryOut SET Assigned = (Assigned + 1) WHERE camId = @camId
        
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
FROM ccWhatsAppConversationsOut whatsConv with(nolock)
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
    INNER JOIN ccWhatsAppConversationsOut whatsConv with(nolock) ON whatsConv.subDisposition = subDispositions.califSub_id
    WHERE whatsConv.camId = @camId AND
            whatsConv.assignDate >= @Today AND
            relation.tipoSubRel = 0
    GROUP BY subDispositions.califSubDesc, relation.calif_id
END
ELSE IF @Option = 6 -- Agents Availables
BEGIN
    IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId)
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
    ---------------------------------- Begin fix/125.20231211.0.10 ----------------------------------
     SET @process = 'Alter SP CofetelActions'
     SET @sql = 'ALTER PROCEDURE [dbo].[CofetelActions]
@type tinyint
as
if @type = 1
begin
    truncate table SeriesTmp
end
        
if @type = 2
begin
    if exists(select * from SeriesTmp) begin
        truncate table Series
    end
end'
     EXEC(@sql);

      SET @process = 'ALTER Sp CofetelUpdateData Add Transaction'
     SET @sql = 'ALTER PROCEDURE [dbo].[CofetelUpdateData]
@type tinyint
as
if @type = 1
begin

    BEGIN TRAN  
        exec CofetelActions @type=2     
        if not exists(select * from Series) begin
            insert into Series
            select * from SeriesTmp
        end     
    COMMIT TRAN
end'
     EXEC(@sql);
    
---------------------------------- Begin fix/125.20231211.0.10 ----------------------------------
               
----------------------------------------------------------------------------------- BEGIN Ivan Martin Fix Numeros Duplicados WhatsApp --------------------------------------------------------------------------

     SET @process = 'Drop procedure ccsp_MultimediaCommon'
     SET @sql = 'if exists (select 1 from sys.procedures where name = N''ccsp_MultimediaCommon'')
                begin
                    DROP PROCEDURE ccsp_MultimediaCommon;
                end'
     EXEC(@sql);


     SET @process = 'Se modifica action 1 para que tome el campo de Phone de ccWhatsAppNumbers en lugar de contactMeanIn, homologando esto con el accion 0'
     SET @sql = '
                    CREATE PROCEDURE [dbo].[ccsp_MultimediaCommon]
                    @Option AS SMALLINT,
                    @inboundId AS SMALLINT = 0,
                    @conversationId AS INT = 0,
                    @ServiceType AS SMALLINT = 0,
                    @status as SMALLINT =0,
                    @messagesList as varchar(max) = '''',
                    @agentId AS SMALLINT = 0,
                    @CampType bit =0
                    AS
                    BEGIN
                        SET NOCOUNT ON;

                    IF @Option = 0 --  Get Campaigns Configuration List
                    BEGIN
                            SELECT CAST(campaign.cam_id AS INT) AS Id,
                                    campaign.cam_descripcion AS [Name],
                                    ISNULL(configuration.number, '''') AS Phone,
                                    CAST(graphics.graphic_id AS INT) AS GraphicId
                            FROM  ccCamps campaign 
                            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
                            INNER JOIN  ccWhatsAppNumbers configuration ON campaign.cam_id = configuration.camp_id where configuration.status != 0 AND campaign.CampType = 5
                                                                
                    END

                    ELSE IF @Option = 1 --  Get Acds Configuration List
                    BEGIN
                                                                
                        SELECT --inbound.chat AS ServiceType,
                        CAST(inbound.Inbound_id AS INT) AS Id,
                        inbound.descripcion AS [Name],
                        ISNULL(numbers.number, '''') AS Phone,
                        CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                        inbound.tNotas AS WrapUpTime,
                        CAST(graphics.graphic_id AS INT) AS GraphicId
                        FROM  ccInbound inbound
                        INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
                        INNER JOIN contactMeanIn configuration ON inbound.Inbound_id = configuration.inboundId 
                        INNER JOIN ccWhatsAppNumbers numbers ON inbound.Inbound_id = numbers.inboundId
                        where inbound.Status != 0 AND configuration.meanContactTypeId = 5 and numbers.status != 0 
                                                                
                    END

                    ELSE IF(@Option = 2)
                    BEGIN


                        DECLARE @OldAgentId INT = 0
                        DECLARE @OldConversationId INT = 0
                        if @campType =0 begin --ACD
                            SELECT  @OldAgentId = conv.agentId,
                                    @OldConversationId = rel.conversationIdBefore
                            FROM ccWhatsAppConversationsRelationship rel 
                            RIGHT JOIN ccWhatsAppConversations conv ON conv.conversationId = rel.conversationIdBefore
                            WHERE rel.conversationIdAfter = @conversationId

                        SELECT
                        cast(i.chat as int) AS ServiceType,
                        cast(c.conversationId as int) as ConversationID,
                        c.clientId as ClientId,
                        cm.conexionInfo as [To],
                        cast(i.Inbound_id as int) as ACDId,
                        i.descripcion as ACDName,
                        cast(g.graphic_id as int) as ACDGraphicId,
                        cast(cm.closeConversationTime as int) as [TimeOut],
                        cast(cm.answerTimeOut as int) as [TimeOutWarning],
                        i.ExitWrapUpDisposition as [ExitWrapUpDisposition],
                        i.tNotas as [WrapUpTime],
                        i.ShowCalifWnd,
                        cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient],
                        ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent),0) as [SecTimeOutLastMessageAgent],
                        isnull(permission.AllowUnassign,0) as AllowUnassign,
                        isnull(permission.AllowSpam,0) as AllowSpam,
                        ISNULL(@OldAgentId, 0) AS OldAgentId,
                        ISNULL(@OldConversationId, 0) AS OldConversationId,
                        c.agentId AS AgentId,
                        c.IsAgentLoggingOut AS IsAgentLoggingOut
                        from ccWhatsAppConversations c
                        left join ccInbound i on c.inboundId = i.Inbound_id 
                        left JOIN  contactMeanIn cm  ON i.Inbound_id = cm.inboundId    
                        LEFT JOIN ccRIAInboundGraph g on g.Inbound_id = i.Inbound_id
                        LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
                        LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId

                        where c.conversationId = @conversationId

                                                
                        End
                        ELSE BEGIN --Camp
                            SELECT  @OldAgentId = conv.agentId,
                                    @OldConversationId = rel.conversationIdBefore
                            FROM ccWhatsAppConversationsRelationshipOut rel 
                            RIGHT JOIN ccWhatsAppConversationsOut conv ON conv.conversationId = rel.conversationIdBefore
                            WHERE rel.conversationIdAfter = @conversationId

                            SELECT
                            cast(i.CampType as int) AS ServiceType,
                            cast(c.conversationId as int) as ConversationID,
                            c.clientId as ClientId,
                            c.phoneCamp as [To],
                            cast(i.cam_id as int) as ACDId,
                            i.cam_descripcion as ACDName,
                            cast(g.graphic_id as int) as ACDGraphicId,
                            cast(cm.closeConversationTime as int) as [TimeOut],
                            cast(cm.answerTimeoutClient as int) as [TimeOutWarning],
                            i.exitAssisted as [ExitWrapUpDisposition],              
                            cast(i.cam_tnotas as int) [WrapUpTime],
                            i.cam_ShowCalifWnd as ShowCalifWnd, 
                            cast(ISNULL(answerTimeoutClient, 30) AS int) as [AnswerTimeoutClient],
                            ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent),0) as [SecTimeOutLastMessageAgent],
                            isnull(permission.AllowUnassign,0) as AllowUnassign,
                            isnull(permission.AllowSpam,0) as AllowSpam,
                            ISNULL(@OldAgentId, 0) AS OldAgentId,
                            ISNULL(@OldConversationId, 0) AS OldConversationId,
                            c.agentId AS AgentId
                            FROM  ccWhatsAppConversationsOut c
                            LEFT JOIN  ccCamps i ON c.camId = i.cam_id 
                            LEFT JOIN  contactMeanOut cm  ON c.camId = cm.camp_id
                            LEFT JOIN ccRIACampsGraph g on g.cam_id = c.camId
                            LEFT JOIN ccLastMessageAgentByConversationOut lm ON lm.conversationId = c.conversationId
                            LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId

                            where c.conversationId = @conversationId
                        END
                    END
                    ELSE IF(@Option = 3)
                    BEGIN
                        if @campType =0 begin --ACD
                            SELECT
                            CAST(inbound.Inbound_id AS INT) AS Id,
                            inbound.descripcion AS Name,
                            ISNULL(configuration.conexionInfo, '''') AS Phone,
                            CAST(ISNULL(configuration.answerTimeOut, 0) AS int) AS TimeOut,
                            inbound.tNotas AS WrapUpTime,
                                CAST(graphics.graphic_id AS INT) AS GraphicId
                            FROM  ccInbound inbound
                            INNER JOIN ccRIAInboundGraph graphics ON inbound.Inbound_id = graphics.Inbound_id
                            INNER JOIN  contactMeanIn configuration ON (inbound.Inbound_id = configuration.inboundId and inbound.Inbound_id = @inboundId)
                        end
                        else begin
                        SELECT
                            CAST(campaign.cam_id AS INT) AS Id,
                            campaign.cam_descripcion AS Name,
                            ISNULL(configuration.conexionInfo, '''') AS Phone,
                            CAST(ISNULL(configuration.answerTimeoutClient, 0) AS int) AS TimeOut,
                            cast(campaign.cam_tnotas as int) AS WrapUpTime,
                            CAST(graphics.graphic_id AS INT) AS GraphicId
                            FROM  ccCamps campaign
                            INNER JOIN ccRIACampsGraph graphics ON campaign.cam_id = graphics.cam_id
                            INNER JOIN  contactMeanOut configuration ON (campaign.cam_id = configuration.camp_id and campaign.cam_id = @inboundId)
                        end
                    END
                    ELSE IF(@Option = 4)
                    Begin
                            declare @pathFile as varchar(max)
                            declare @filetype as varchar(5)
                            DECLARE @mensajes TABLE(idMessage VARCHAR(100));
                            DECLARE @tmpMessageConversations TABLE(
                                    [messageId] VARCHAR(75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
                                ,[conversationId] INT NOT NULL
                                ,[timeStampMessage] DATETIME NOT NULL
                                ,[originType] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
                                ,[price] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
                                ,[messageIdUi] INT NULL
                                ,[currency] VARCHAR(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                                ,[typeMessage] VARCHAR(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                                ,[content] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                                ,[clientNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                                ,[vonageNum] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                                ,[timeStampMessageUTC] DATETIME NULL
                                ,[messageStatus] VARCHAR(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
                            );

                        insert into @mensajes
                        select value from dbo.fn_RIASplitDelimited(@messagesList,'','')
                                                            
                            if(@CampType = 0)
                            BEGIN
                                INSERT INTO @tmpMessageConversations(messageId, conversationId, timeStampMessage, originType
                                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
                                messageStatus) 
                                select messageId, conversationId,timeStampMessageUTC timeStampMessage, originType
                                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
                                messageStatus
                            
                                FROM ccWAMessagesConversations  where messageId in (select idMessage from @mensajes)
                            END
                            if(@CampType = 1)
                            BEGIN
                                INSERT INTO @tmpMessageConversations(messageId, conversationId, timeStampMessage, originType
                                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
                                messageStatus) 
                                select messageId, conversationId,timeStampMessageUTC timeStampMessage, originType
                                ,price, messageIdUi, currency, typeMessage, content, clientNum, vonageNum, timeStampMessageUTC,
                                messageStatus
                                FROM ccWAMessagesConversationsOut  where messageId in (select idMessage from @mensajes)
                            END
                            select @pathFile = valor from ccSettings where setting_id=230
                        select
                            messageId as MessageId,
                            messageStatus as Status,
                            originType as Origin,
                            case when originType =''Client'' then 3
                                    when originType =''Agent'' then 2
                                    when originType =''Admin'' then 1
                            else 0 end as OriginType,
                            timeStampMessage as [Timestamp],
                            case when typeMessage IN (''text'', ''template'')  then content else '''' end as Content,
                            typeMessage as Type,
                            case 
                                    when typeMessage not in( ''text'' ,''location'', ''file'', ''template'') then content
                                    else
                                        case
                                            when typeMessage = ''file'' then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) 
                                                    else '''' end
                                    end as Caption,
                            case 
                                    when originType = ''Client''
                                    then
                                        case
                                                when typeMessage = ''text'' or typeMessage = ''location''
                                                or (typeMessage = ''file'' and (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) = '''' )
                                            then ''''
                                                else char(92)+char(92)+''WhatsApp''+char(92)+char(92)+ CASE WHEN @CampType = 0 THEN ''INBOUND'' ELSE ''OUTBOUND'' END +char(92)+char(92)+cast(conversationId/1000 as varchar(30))+char(92)+char(92)+cast(conversationId as varchar(20))+char(92)+char(92)+ typeMessage + char(92)+char(92)+ messageId +
                                                case
                                                        when typeMessage = ''video'' then ''.mp4''
                                                        when typeMessage = ''image'' then ''.jpg''
                                                        when typeMessage = ''audio'' then ''.mp3''
                                                        when typeMessage = ''file''
                                                        then (select substring(content, LEN(content) - CHARINDEX(''.'',REVERSE(content))+1, len(content)))
                                                    else '''' end
                                        end
                                    else
                                        case
                                            when typeMessage = ''text'' or typeMessage = ''location'' OR typeMessage = ''template''
                                            then ''''
                                            else content
                                    end
                                end as [Url],
                                case when typeMessage = ''file'' 
                                then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2)
                                else '''' end as [FileSize],
                                case when typeMessage = ''file'' 
                                then (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2)
                                else '''' end as [FileName],
                            case when typeMessage = ''location''
                            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 1),'':'') where id=2) else '''' end as [Address],
                            case when typeMessage = ''location''
                            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) else '''' end as [Lat],
                            case when typeMessage = ''location''
                            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [Long],
                            case when typeMessage = ''location''
                            then  (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 4),'':'') where id=2) else '''' end as [Name],
                            case when typeMessage = ''location''
                            then ''https://www.google.com/maps/search/'' + (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 2),'':'') where id=2) + '','' +
                                (select value from dbo.fn_RIASplitDelimited((select value from dbo.fn_RIASplitDelimited(content,''|'') where id = 3),'':'') where id=2) else '''' end as [LocationURL]
                                from @tmpMessageConversations
                            order by Timestamp asc

                    End
                                                                                
                    ELSE IF(@Option = 5)
                    BEGIN
                        if @CampType =0 begin
                            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
                                FROM contactMeanIn
                            WHERE inboundId = @inboundId
                        end 
                        else begin
                            SELECT CAST(ISNULL(answerTimeoutClient, 30) AS int) AS AnswerTimeoutClient 
                                FROM contactMeanOut
                            WHERE camp_id = @inboundId
                        end 
                    END
                    ELSE IF(@Option = 6)
                    BEGIN
                        SELECT [Login] AS ''OriginName''
                            FROM [CCenterRIA].[dbo].[ccUsers]
                        WHERE [User_id] = @agentId
                    END
                    END'
     EXEC(@sql);

     ----------------------------------------------------------------------------------- END Ivan Martin Fix Numeros Duplicados WhatsApp --------------------------------------------------------------------------


     ----------------------------------------------------------------------------------- BEGIN Marco García --------------------------------------------------------------------------
     

--------------- TT9016-AdminKolob-Eroor en listas negras ---------

SET @process = 'TT9016-AdminKolob-Eroor en listas negras eliminar función Completa si existe'
        SET @sql = 'IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N''[dbo].[Completa]'')
                  AND type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
            BEGIN
              DROP FUNCTION [dbo].[Completa]
            END'
        EXEC(@sql)

SET @process = 'TT9016-AdminKolob-Eroor en listas negras crea función Completa si existe, se modificó el apartado de Guatemala'
        SET @sql = 'CREATE FUNCTION [dbo].[Completa] (@phone VARCHAR(32), @pais VARCHAR(2) = '''', @cldLocal VARCHAR(5) = '''')
RETURNS VARCHAR(32)
AS
BEGIN
    DECLARE @resultado VARCHAR(32)
    DECLARE @ld VARCHAR(7)
    DECLARE @isLocal BIT
    IF @pais = ''''
    BEGIN
        SELECT @pais = valor
        FROM ccSettings WITH (NOLOCK)
        WHERE setting_id = 104
    END
    IF @cldLocal = ''''
    BEGIN
        SELECT @cldLocal = valor
        FROM ccSettings WITH (NOLOCK)
        WHERE setting_id = 17
    END
    SELECT @phone = dbo.limpia(@phone)
    SELECT @resultado = @phone
    DECLARE @lenPhone INT, @lenLd INT
    SET @lenPhone = len(@resultado)
    SET @lenLd = len(@cldLocal)
    IF @pais = 1
    BEGIN --Empieza Mexico      
        IF @lenPhone < 10
        BEGIN
            RETURN ''E_NV_Longitud'';
        END
        IF @lenPhone = 12 AND left(@phone, 2) <> ''01''
        BEGIN
            RETURN ''E_NV_Longitud'';
        END
        IF @lenPhone = 13 AND left(@phone, 3) NOT IN (''044'', ''045'')
        BEGIN
            RETURN ''E_NV_Longitud'';
        END
        SET @resultado = right(@resultado, 10)
        SET @isLocal = 0
        DECLARE @specialDialPlan TINYINT
        SELECT @specialDialPlan = valor
        FROM ccsettings WITH (NOLOCK)
        WHERE setting_id = 195
        IF EXISTS (
                SELECT TOP 1 area
                FROM ccRiaArecode NOLOCK
                WHERE area = left(@resultado, 3)
                )
            SELECT @ld = left(@resultado, 3), @isLocal = 1
        ELSE IF EXISTS (
                SELECT TOP 1 area
                FROM ccRiaArecode NOLOCK
                WHERE area = left(@resultado, 2)
                )
            SELECT @ld = left(@resultado, 2), @isLocal = 1
        ELSE
        BEGIN
            SET @ld = @cldLocal
            IF left(@resultado, len(@ld)) = @ld
            BEGIN
                SET @isLocal = 1
            END
        END
        SET @lenLd = len(@ld)
        IF @specialDialPlan = 1
        BEGIN
            --Number local 10 digit
            --Number LD 12 digit
            --Number Cell 13 digit
            SELECT @resultado = CASE WHEN @lenPhone = 10 THEN CASE WHEN @isLocal = 1 THEN @resultado ELSE ''01'' + @resultado END --10 Dig Local, LD
                    WHEN @lenPhone = 12 THEN CASE WHEN @isLocal = 1 THEN @resultado ELSE @phone END --12 Dig Local, LD
                    WHEN @lenPhone = 13 THEN CASE WHEN @isLocal = 1 THEN ''044'' + @resultado ELSE ''045'' + @resultado END --13 Dig Local, LD
                    ELSE ''E_NV_Longitud'' END --Other Long
        END
        ELSE IF @specialDialPlan = 0
        BEGIN
            --Number local 7 o 8 digit
            --Number LD 12 digit
            --Number Cell 13 digit
            SELECT @resultado = CASE WHEN @lenPhone = 10 THEN CASE WHEN @isLocal = 1 THEN right(@resultado, 10 - @lenLd) ELSE ''01'' + @resultado END --10 Dig Local, LD
                    WHEN @lenPhone = 12 THEN CASE WHEN @isLocal = 1 THEN right(@resultado, 10 - @lenLd) ELSE @phone END --12 Dig Local, LD                          
                    WHEN @lenPhone = 13 THEN CASE WHEN @isLocal = 1 THEN ''044'' + @resultado ELSE ''045'' + @resultado END --13 Dig Local, LD
                    ELSE ''E_NV_Longitud'' END
        END
        --Termina Mexico
        RETURN @resultado
    END
    ELSE IF @pais = 2
    BEGIN -- Empieza Argentina
        SELECT @resultado = CASE WHEN (@lenPhone = 7 AND @lenLd = 3) OR (@lenPhone = 6 AND @lenLd = 4) THEN @resultado
                        -- cuando son 8 digitos y la lada es de 2 digitos, se regresa el telefono tal cual
                        -- cuando la lada es de 4 digitos, se revisa la posibiidad de que sea un celular, si es asi se regresa
                WHEN @lenPhone = 8 THEN CASE WHEN @lenLd = 4 THEN CASE WHEN left(@resultado, 2) = ''15'' THEN @resultado END ELSE CASE WHEN @lenLd = 2 THEN @resultado END END
                        -- Este caso solamente es cuando el telefono es un celular y la lada es de 3 digitos
                WHEN @lenPhone = 9 THEN CASE WHEN left(@resultado, 2) = ''15'' THEN @resultado ELSE ''E_NV_Cel'' END
                        -- Cuando son 10 numeros y la lada es igual, solo se marcan los numeros restantes para llamada local
                        -- Si es diferente se le agrega un 0 para llamadas de larga distancia
                WHEN @lenPhone = 10 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE CASE WHEN left(@resultado, 2) = ''15'' THEN @resultado ELSE ''0'' + @resultado END END
                        -- Cuando el numero telefonico viene con un 0 al inicio, se verifica la lada
                        -- si no es la misma lada, pero el telefono empieza con 0, se regresa tal cual
                WHEN @lenPhone = 11 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE @resultado END ELSE ''E_NV_LD'' END
                        -- Celular, si tiene 12 numeros y el numero es local, solo se marca el 15 y el numero
                        -- si no es local se le agrega el 0 y se marca el numero
                WHEN @lenPhone = 12 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN CASE WHEN substring(@resultado, @lenLd + 1, 2) = ''15'' THEN right(@resultado, 12 - @lenLd) ELSE ''E_NV_Cel'' END ELSE ''0'' + @resultado END
                        -- Celular, con 0 al inicio si es local, quita el area y marca apartir del 15, si no, lo regresa igual
                WHEN @lenPhone = 13 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN substring(@resultado, @lenLd + 2, 12 - @lenLd) ELSE @resultado END ELSE ''E_NV_Cel'' END ELSE ''E_NV_Longitud'' END
        --Termina Argentina
        RETURN @resultado
    END
    ELSE IF @pais = 3
    BEGIN --Empieza colombia
        SELECT @resultado = CASE 
                --Si son 7 digitos, se regresa igual
                WHEN @lenPhone = 7 THEN @resultado
                        --Cuando son 8 digitos si la lada es igual se quita y se regresan 7 numeros
                WHEN @lenPhone = 8 THEN CASE WHEN left(@resultado, 1) = @cldLocal THEN right(@resultado, 7) ELSE @resultado END
                        -- Cuando son 10 digitos, se revisa que tenga prefijo celular y se agrega un 0
                WHEN @lenPhone = 10 THEN CASE WHEN left(@resultado, 3) IN (''300'', ''301'', ''302'', ''303'', ''304'', ''305'', ''310'', ''311'', ''312'', ''313'', ''314'', ''315'', ''316'', ''317'', ''318'', ''319'', ''320'') THEN ''0'' + @resultado ELSE ''E_NV_Cel'' END
                        --Cuando son 11 digitos, se revisa que el primer numero sea un 0 y que los siguientes 3 numeros sean
                        --prefijo de celular
                WHEN @lenPhone = 11 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 2, 3) IN (''300'', ''301'', ''302'', ''303'', ''304'', ''305'', ''310'', ''311'', ''312'', ''313'', ''314'', ''315'', ''316'', ''317'', ''318'', ''319'', ''320'') THEN @resultado ELSE ''E_NV_Cel'' END ELSE ''E_NV_Cel'' END ELSE ''E_NV_Longitud'' END
        -- Termina Colombia
        RETURN @resultado
    END
    ELSE IF @pais = 4
    BEGIN --Empieza USA
        SELECT @resultado = CASE @lenPhone WHEN 3 THEN CASE @resultado WHEN ''911'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 7 THEN @resultado WHEN 10 THEN CASE WHEN left(@resultado, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE ''1'' + @resultado END WHEN 11 THEN CASE WHEN left(@resultado, 1) = ''1'' THEN CASE WHEN substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 10 - @lenLd) ELSE @resultado END ELSE ''E_NV_LD'' END ELSE ''E_NV_Longitud'' END
        --Termina USA
        RETURN @resultado
    END
    ELSE IF @pais = 5
    BEGIN --5:Chile
        SELECT @resultado = CASE @lenPhone WHEN 6 THEN @resultado WHEN 7 THEN @resultado
                        -- se revisa si es un celular, si es asi se le agrega el 09 excepto con los prefijos que se mezclan con ladas
                WHEN 8 THEN CASE WHEN @cldLocal = left(@resultado, @lenLd) THEN right(@resultado, 8 - @lenLd) ELSE CASE WHEN left(@resultado, 1) IN (8, 9) THEN ''09'' + @resultado ELSE CASE WHEN left(@resultado, 1) = ''6'' THEN CASE WHEN left(@resultado, 2) IN (61, 63, 64, 65, 67) THEN @resultado ELSE ''09'' + @resultado END ELSE CASE WHEN left(@resultado, 1) = ''7'' THEN CASE WHEN left(@resultado, 2) IN (71, 72, 73, 75) THEN @resultado ELSE ''09'' + @resultado END ELSE @resultado END END END END
                        -- Se revisa que sea la lada permitida a 9 numeros, si es asi se regresa igual, si tiene el prefijo
                        -- de telefonia voIp se le agrega el 0 al inicio
                WHEN 9 THEN CASE WHEN @cldLocal = left(@resultado, 2) THEN right(@resultado, 7) ELSE CASE WHEN left(@resultado, 2) IN (41, 32, 65) THEN @resultado ELSE CASE WHEN left(@resultado, 2) = ''44'' THEN ''0'' + @resultado ELSE CASE WHEN left(@resultado, 1) = ''9'' AND substring(@resultado, 2, 1) IN (6, 7, 8, 9) THEN ''0'' + @resultado ELSE ''E_NV_Longitud'' END END END END WHEN 10 THEN CASE WHEN left(@resultado, 2) = ''09'' THEN @resultado ELSE ''E_NV_Cel'' END ELSE ''E_NV_Longitud'' END
        -- Termina Chile
        RETURN @resultado
    END
    IF @pais = 6
    BEGIN -- Venezuela
        SELECT @resultado = CASE @lenPhone WHEN 7 THEN @resultado WHEN 10 THEN ''0'' + @resultado WHEN 11 THEN CASE WHEN left(@resultado, 1) = ''0'' THEN @resultado ELSE ''E_NV_Longitud'' END ELSE ''E_NV_Longitud'' END
        RETURN @resultado
    END
            --Termina Venezuela
    ELSE IF @pais = 7
    BEGIN --7: Reino Unido
        SELECT @resultado = CASE @lenPhone WHEN 11 THEN CASE left(@resultado, 1) WHEN ''0'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 10 THEN CASE left(@resultado, 1) WHEN ''0'' THEN @resultado ELSE ''0'' + @resultado END WHEN 9 THEN CASE WHEN left(@resultado, 1) <> ''0'' THEN ''0'' + @resultado ELSE ''E_NV_Longitud'' END WHEN 8 THEN CASE WHEN substring(@resultado, 1, 2) = ''08'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 7 THEN CASE WHEN left(@resultado, 1) = ''8'' THEN ''0'' + @resultado ELSE ''E_NV_Longitud'' END ELSE ''E_NV_Longitud'' END
        RETURN @resultado
    END
            -- Termina UK
    ELSE IF @pais = 8
    BEGIN -- arabia saudita
        SELECT @resultado = CASE @lenPhone WHEN 7 THEN @resultado WHEN 8 THEN CASE substring(@resultado, 1, 1) WHEN @cldLocal THEN right(@resultado, 7) ELSE ''0'' + @resultado END WHEN 9 THEN CASE substring(@resultado, 1, 1) WHEN ''5'' THEN ''0'' + @resultado WHEN ''0'' THEN CASE substring(@resultado, 2, 1) WHEN @cldLocal THEN right(@resultado, 7) ELSE @resultado END ELSE ''E_NV_Longitud'' END WHEN 10 THEN CASE substring(@resultado, 2, 1) WHEN ''5'' THEN @resultado ELSE ''E_NV_Longitud'' END WHEN 11 THEN CASE substring(@resultado, 2, 1) WHEN ''8'' THEN CASE substring(@resultado, 3, 3) WHEN ''111'' THEN @resultado ELSE ''E_NV_Longitud'' END ELSE CASE WHEN substring(@resultado, 3, 3) = ''510'' OR substring(@resultado, 3, 3) = ''511'' THEN @resultado ELSE ''E_NV_Longitud'' END END WHEN 13 THEN @resultado ELSE ''E_NV_Longitud'' END
        RETURN @resultado
    END -- arabia saudita
    ELSE IF @pais = 9
    BEGIN --Australia
        SELECT @resultado = CASE @lenPhone WHEN 8 THEN
                        /*case when exists (select AreaCode
              from SeriesAU
              where convert(int,LD) = convert(int,@cldLocal)
              and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then*/
                        CASE substring(@resultado, 1, 4) WHEN ''5550'' THEN ''E_NV_LD'' ELSE @cldLocal + @resultado END
                        /*else case when exists (select AreaCode
              from SeriesAU
              where convert(int,LD) = convert(int,''04'')
              and convert(int,AreaCode) = convert(int,substring(@resultado, 1, 2))) then
    ''04'' +  @resultado
    else ''E_NV_Cel'' end end*/
                WHEN 9 THEN CASE WHEN left(@resultado, 1) <> ''0'' THEN CASE substring(@resultado, 2, 4) WHEN ''5550'' THEN ''E_NV_LD'' ELSE ''0'' + @resultado END ELSE ''E_NV_LD'' END WHEN 10 THEN CASE substring(@resultado, 3, 4) WHEN ''5550'' THEN ''E_NV_LD'' ELSE @resultado END ELSE ''E_NV_Longitud'' END
        RETURN @resultado
    END
    ELSE IF @pais = 10
    BEGIN --Brasil
        SELECT @resultado = CASE @lenPhone
                --llamada local fijo o celular
                WHEN 8 THEN @resultado WHEN 9 THEN @resultado WHEN 10 THEN -- Numero nacional
                        CASE WHEN left(@resultado, 2) = @cldLocal THEN right(@resultado, 8) ELSE @resultado END WHEN 11 THEN -- Este caso solomente es para numero celular
                        CASE WHEN left(@resultado, 2) = @cldLocal THEN right(@resultado, 9) ELSE @resultado END WHEN 12 THEN -- llamadas por cobrar local
                        CASE WHEN (left(@resultado, 4) = ''9090'') THEN right(@resultado, 8) ELSE ''E_NV_PC'' END WHEN 13 THEN CASE WHEN left(@resultado, 4) = ''9090'' THEN right(@resultado, 9) -- llamadas por cobrar local celular
                            WHEN left(@resultado, 1) = ''0'' THEN CASE WHEN substring(@resultado, 4, 2) = @cldLocal THEN right(@resultado, 8) ELSE right(@resultado, 10) END -- llamadas de LDN
                            ELSE ''E_NV_Longitud'' END WHEN 14 THEN CASE WHEN left(@resultado, 2) = ''90'' THEN -- llamadas por cobrar larga distancia
                                    CASE WHEN substring(@resultado, 5, 2) = @cldLocal THEN right(@resultado, 8) ELSE right(@resultado, 11) END WHEN left(@resultado, 1) = ''0'' THEN --llamada larga distancia a celular
                                    CASE WHEN substring(@resultado, 4, 2) = @cldLocal THEN right(@resultado, 9) ELSE right(@resultado, 11) END ELSE ''E_NV_Longitud'' END WHEN 15 THEN CASE WHEN left(@resultado, 2) = ''90'' THEN -- Llamadas por cobrar a celular LD
                                    CASE WHEN substring(@resultado, 5, 2) = @cldLocal THEN right(@resultado, 9) ELSE right(@resultado, 11) END ELSE ''E_NV_Longitud'' END ELSE ''E_NV_Longitud'' END
        RETURN @resultado
    END
    ELSE IF @pais = 11
    BEGIN --Guatemala
        if @lenPhone <> 8 BEGIN
            SELECT @resultado = ''E_NV_Longitud''
        END
        ELSE IF CHARINDEX(substring(@resultado, 1, 1), ''2,3,4,5,6,7,8,9'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END     
        RETURN @resultado
    END
    ELSE IF @pais = 12
    BEGIN --Costa Rica
        IF @lenPhone = 8 AND charindex(substring(@resultado, 1, 1), ''2,3,4,5,6,7,8'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        ELSE IF @lenPhone = 10 AND charindex(substring(@resultado, 1, 3), ''800,900,905'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        ELSE IF charindex(substring(@resultado, 1, 2), ''00,08'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        RETURN @resultado
    END
    ELSE IF @pais = 13
    BEGIN --Salvador
        IF @lenPhone = 8 AND charindex(substring(@resultado, 1, 1), ''2,6,7'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        ELSE IF charindex(substring(@resultado, 1, 2), ''00'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        RETURN @resultado
    END
    ELSE IF @pais = 14
    BEGIN --Spain
        IF @lenPhone = 9 AND charindex(substring(@resultado, 1, 1), ''5,6,7,8,9'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        ELSE IF charindex(substring(@resultado, 1, 2), ''00'') <= 0
        BEGIN
            SELECT @resultado = ''E_'' + @resultado
        END
        RETURN @resultado
    END
    ELSE IF @pais = 15
    BEGIN --Peru
        SELECT @resultado = CASE WHEN (@lenPhone = 7 AND @lenLd = 1) OR (@lenPhone = 6 AND @lenLd = 2) THEN @resultado WHEN @lenPhone = 8 THEN CASE WHEN substring(@resultado, 1, @lenLd) = @cldLocal THEN right(@resultado, 8 - @lenLd) ELSE ''0'' + @resultado END WHEN @lenPhone = 9 THEN CASE WHEN left(@resultado, 1) = ''0'' AND substring(@resultado, 2, @lenLd) = @cldLocal THEN right(@resultado, 8 - @lenLd) ELSE @resultado END ELSE ''E_NV_Longitud'' END
        RETURN @resultado
    END --Termina Peru
    ELSE IF @pais = 16
    BEGIN --Panama
        SELECT @resultado = CASE WHEN (@lenPhone = 7) THEN CASE WHEN substring(@resultado, 1, 1) IN (''2'', ''3'', ''4'', ''5'', ''7'', ''9'') THEN @resultado ELSE ''E_'' + @resultado END WHEN (@lenPhone = 8) THEN CASE WHEN substring(@resultado, 1, 1) = ''6'' THEN @resultado ELSE ''E_'' + @resultado END ELSE CASE WHEN substring(@resultado, 1, 2) = ''00'' THEN @resultado ELSE ''E_'' + @resultado END END
        RETURN @resultado
    END
    -- Termina
    RETURN @resultado
END'
        EXEC(@sql)

        


SET @process = 'TT9016-AdminKolob-Eroor en listas negras eliminar sp ccsp_InsertDNCList si existe'
        SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_InsertDNCList'')
            BEGIN
                DROP PROCEDURE ccsp_InsertDNCList
            END'
        EXEC(@sql)

SET @process = 'TT9016-AdminKolob-Eroor en listas negras crear sp ccsp_InsertDNCList,  se modifico para el proceso de insertar telefono indivual para lista negra'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_InsertDNCList]
@telephone as varchar(30)=null,
@ln_id as integer,
@hashCalKey bigint=NULL,
@calKey VARCHAR(40) = NULL

AS

Set nocount on


declare @pais varchar(2), @ld varchar(5), @tel as varchar(30)
,@tel10 as varchar(30),@tel11 as varchar(30), @sqlcmd nvarchar(max), @tmpTableName varchar(40), @sqlcmd_replace nvarchar(max),
@dropTmpPhone varchar(max) = null

SET @tmpTableName = ''TMP_BLACKLIST_'' + CAST(@ln_id as varchar(10));

if (@telephone is not null) -- Para insertar un solo numero cuando se manda a BL por calificación
BEGIN
    IF EXISTS (SELECT * from ccListaNegra where idtipolista = @ln_id and telefono = @telephone and HashKey = dbo.hashList(@calKey)) begin
        RETURN 0;
    end

    set @tmpTableName = ''TMP_BLACKLIST_'' + @telephone;
    SET @dropTmpPhone = ''if exists (select * from sys.tables where name = N'''''' + @tmpTableName + '''''') drop table '' + @tmpTableName;

    SET @sqlcmd = ''CREATE TABLE '' + @tmpTableName + ''(
    [phoneNumber] VARCHAR(30),
    [calKey] VARCHAR(40)); 

    INSERT INTO '' + @tmpTableName + ''(phoneNumber, calKey) values(@telephone,@calKey );
    '';
    EXEC (@dropTmpPhone);   
    EXEC sp_executesql @sqlcmd, N''@telephone varchar(40), @calKey VARCHAR(40)'', @telephone,@calKey;
END


select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

SET @sqlcmd =  ''
UPDATE '' + @tmpTableName + '' SET phoneNumber = dbo.completa(phoneNumber, @pais, @ld);
DELETE '' + @tmpTableName + '' WHERE phoneNumber like ''''%E%'''';

INSERT INTO cclistanegra(telefono,idtipolista,HashKey, calKey)
SELECT phoneNumber, @ln_id as idtipolista, dbo.hashList(calKey) as HashKey, calkey 
FROM '' + @tmpTableName + '';

INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
SELECT phoneNumber as telefono, 7 as idtipomov, @ln_id as idtipolista 
FROM '' + @tmpTableName + '';''

EXEC sp_executesql @sqlcmd, N''@pais varchar(2), @ld VARCHAR(5),@ln_id int'', @pais, @ld,@ln_id;

IF OBJECT_ID(N''tempdb..#mycamps'') IS NOT NULL drop table #mycamps
IF OBJECT_ID(N''tempdb..#myprincipaltempCall'') IS NOT NULL drop table #myprincipaltempCall
IF OBJECT_ID(N''tempdb..#mytempCall'') IS NOT NULL drop table #mytempCall
IF OBJECT_ID(N''tempdb..#helpTempCall]'') IS NOT NULL drop table #helpTempCall


CREATE TABLE [dbo].[#mycamps] ( [campsid] [int] NULL)

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
    SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
    FROM [ccoCallsOutSource] as a with(nolock)
    inner join #mycamps as b  on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on 
    t.phoneNumber IN ([SPACE_TEL])  AND t.calKey IS NULL
    where  cal_fechadial > getdate()-30
    ''
    
    SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono'')   
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;
    
    SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono2'')  
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

    SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono3'')  
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

    SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono4'')  
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

    SET @sqlcmd_replace = REPLACE(@sqlcmd,''SPACE_TEL'',''cal_telefono5'')
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

    

    SET @sqlcmd = ''insert into [#helpTempCall]
    SELECT a.callout_id as callout_id, a.cam_id,3, @ln_id as idtipolista, a.[cal_telefono] , a.[cal_telefono2], a.[cal_telefono3], a.[cal_telefono4], a.[cal_telefono5] 
    FROM [ccoCallsOutSource] as a with(nolock)
    inner join #mycamps as b  on a.cam_id = b.campsid
    inner join '' + @tmpTableName +'' t on a.cal_Key=t.calKey
    where cal_fechadial > getdate()-30;
    '';
    
    EXEC sp_executesql @sqlcmd_replace, N''@ln_id int'', @ln_id;

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
        EXEC(@sql)

SET @process = 'TT9016-AdminKolob-Eroor en listas negras eliminar sp ccsp_GalateaAdminUploadBLst si existe'
        SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAdminUploadBLst'')
            BEGIN
                DROP PROCEDURE ccsp_GalateaAdminUploadBLst
            END'
        EXEC(@sql)

    SET @process = 'CW-8532 CW-8452_TT9016-AdminKolob-Eroor en listas negras crear sp ccsp_GalateaAdminUploadBLst,  se modifico para el proceso de eliminar telefono indivual, Error IF @command = 5 --Delete by idtipolista'
    SET @sql = 'Create PROCEDURE [dbo].[ccsp_GalateaAdminUploadBLst]  @command TINYINT, @telephone VARCHAR(20) = 0, @idtipolista INT, @calKey AS VARCHAR(40) = NULL, @isKolob bit=0
AS
DECLARE @hashCalKey BIGINT, @hashPhone BIGINT

SELECT @hashPhone = dbo.hashPhone(@telephone)

IF @calKey IS NOT NULL
BEGIN
    SELECT @hashCalKey = dbo.hashList(@calKey)
END
        
IF @hashCalKey IS NULL
BEGIN
    IF @command IN (1, 4) --LookForNumber 
    AND EXISTS (
        SELECT idtipolista
        FROM cclistanegra
        WHERE Hashtel = @hashPhone AND (HashKey IS NULL OR HashKey = 0) AND idtipolista = @idtipolista
        )
    BEGIN
    SELECT 1

    RETURN (0)
    END
END
ELSE
        
BEGIN
    IF @command IN (1, 4) --LookForNumber 
    AND EXISTS (
        SELECT idtipolista
        FROM cclistanegra
        WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
        )
    BEGIN
    SELECT 1

    RETURN (0)
    END
END
        
IF @command = 1 --Insert Number
BEGIN
    EXEC ccsp_InsertDNCList @telephone, @idtipolista, @hashCalKey, @calKey
    --print  @telephone
    INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
    VALUES (@telephone, 1, @idtipolista)

    SELECT 200
END

IF @command = 2 --Delete Number
BEGIN
    --Check if phone number exists
    IF EXISTS(SELECT cln.Hashtel FROM dbo.ccListaNegra AS cln WHERE cln.Hashtel = @hashPhone AND cln.idtipolista = @idtipolista)
    BEGIN
            IF @hashCalKey IS NULL OR @hashCalKey = 0
            BEGIN
            --Check if request is from kolob or xion
            IF(@isKolob = 1)
            BEGIN
                --Check if phone number has calKey assigned
                SELECT @hashCalKey = cln.HashKey FROM dbo.ccListaNegra AS cln WHERE cln.Hashtel = @hashPhone AND cln.idtipolista = @idtipolista
                IF (@hashCalKey > 0)
                BEGIN
                    SELECT CAST(-1 AS INT) --Phone number need a calkey to delete it
                END
                ELSE
                BEGIN
                    INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
                    VALUES (@telephone, 5, @idtipolista)

                    DELETE
                    FROM cclistanegra
                    WHERE Hashtel = @hashPhone AND (HashKey IS NULL OR HashKey = 0) AND idtipolista = @idtipolista;
                    SELECT CAST(1 AS INT)
                END
            END
            ELSE
            BEGIN
                INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
                VALUES (@telephone, 5, @idtipolista)

                DELETE
                FROM cclistanegra
                WHERE Hashtel = @hashPhone AND (HashKey IS NULL OR HashKey = 0) AND idtipolista = @idtipolista
            END
            END
            ELSE
            BEGIN
            --Check if phone with calKey exist
            IF NOT EXISTS (SELECT cln.HashKey FROM dbo.ccListaNegra AS cln WHERE cln.HashKey = @hashCalKey AND cln.idtipolista = @idtipolista)
            BEGIN
                SELECT CAST(-4 AS INT) --Phone Number with calKey not exist
            END
            ELSE
            BEGIN
                INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
                VALUES (@telephone, 5, @idtipolista)

                DELETE
                FROM cclistanegra
                WHERE Hashtel = @hashPhone AND HashKey = @hashCalKey AND idtipolista = @idtipolista
                IF(@isKolob = 1)
                BEGIN
                    SELECT CAST(1 AS INT)
                END
            END
            END
    END
    ELSE
    BEGIN
        SELECT CAST(-3 AS INT) --Phone Number not exist
    END
    RETURN (0)
END

IF @command = 3 --Reemplaza
BEGIN
    INSERT cchistoriallistanegra (telefono, idtipomov, idtipolista)
    SELECT telefono, 4, @idtipolista
    FROM cclistanegra
    WHERE idtipolista = @idtipolista

    DELETE
    FROM cclistanegra
    WHERE idtipolista = @idtipolista

    RETURN (0)
END

IF @command = 5 --Delete by idtipolista
BEGIN
    UPDATE ccTiposListaNegra
    SET STATUS = 0
    WHERE idtipolista = @idtipolista

    DELETE ccAgendaListaNegra
    WHERE idagenda IN (
        SELECT idagenda
        FROM ccAgenda_TipolistaNegra
        WHERE idtipolista = @idtipolista
        )

    DELETE ccAgenda_TipolistaNegra
    WHERE idtipolista = @idtipolista

    DELETE cccalifblacklist
    WHERE idtipolista = @idtipolista

    DELETE Camplistanegra
    WHERE idtipolista = @idtipolista    

    INSERT INTO cchistoriallistanegra (telefono, idtipomov, idtipolista)
    
    SELECT  telefono,5,@idtipolista
    FROM ccListaNegra
    WHERE idtipolista = @idtipolista

    
    DELETE
    FROM cclistanegra
    WHERE idtipolista = @idtipolista


    RETURN (0)
END

SET NOCOUNT OFF'
        EXEC(@sql)
------------------------------------ TT9016-AdminKolob-Eroor en listas negras ----------------------------


------------------------------------ CW-8394 Permiso para hacer llamadas Manual en el agente ----------------------------

SET @process = 'CW-8394 Permiso para hacer llamadas Manual en el agente, se elimina el sp ccsp_RIAAgentGetDialMask, si existe '
        SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIAAgentGetDialMask'')
            BEGIN
                DROP PROCEDURE ccsp_RIAAgentGetDialMask
            END'
        EXEC(@sql)

SET @process = 'CW-8394 Permiso para hacer llamadas Manual en el agente, se modifico para que tome el plan 2, donde los números son de 10 digitos para México'
        SET @sql = '
        CREATE PROCEDURE [dbo].[ccsp_RIAAgentGetDialMask]
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

    if @specialDialPlan = 2 select @phoneType=dbo.fnGetTipoLlamada(@tel)

    --Restringe celulares
    if (@mask & 1)>0
        begin
        if ((left(ltrim(rtrim(@tel)),3) = ''044'' Or left(ltrim(rtrim(@tel)),3) = ''045'') and len(ltrim(rtrim(@tel))) = 13) or (@specialDialPlan = 2 and (@phoneType=3 or @phoneType=4))
            begin
            set @value = 4
            end
        end

    --Restringe larga distancia
    if(@value=0)
        begin
        if ((@mask & 2) > 0)
            begin
            if ((left(ltrim(rtrim(@tel)),2) = ''01'') and len(ltrim(rtrim(@tel))) = 12) or (@specialDialPlan = 2 and @phoneType=2)
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
            if (Len(@lada) + Len(ltrim(rtrim(@tel))) = 10 and @specialDialPlan = 0) or (@specialDialPlan = 2 and @phoneType=1)
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
------------------------------------ CW-8394 Permiso para hacer llamadas Manual en el agente ----------------------------
---------------------------------------- BEGIN fix/125.20231211.011 -------------------------------------------------
    SET @process = 'Alter SP ccsp_GetInfoDash Se cambia el decimal(5,2) a decimal(10,2)'
    SET @sql = 'ALTER procedure [dbo].[ccsp_GetInfoDash]
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

        declare @vop1 decimal(12,2)
        declare @vop2 decimal(12,2)
        declare @vop3 decimal(12,2)
        declare @vop4 decimal(12,2)

        select @vop1 = count(distinct(callout_id)) from ccocallsout with(nolock)
        where cam_id = @CampId and statuscall_id=13 and cal_inicio>= @today
        group by cam_id
        select @vop2 = count(distinct(callout_id)), @vop4 = count(distinct telefono) from ccoLogDials with(nolock) 
        where cam_id = @CampId and fecha >= @today
        group by cam_id
        select @vop3 = count(distinct telefono) from ccoLogDials with(nolock) 
        where cam_id = @CampId and fecha >= @today
        group by cam_id, Telefono having count(1) > 1
        
        if @vop2 is null 
            set @vop2=0

        if @vop3 is null 
            set @vop3=0

        if @vop4 is null 
            set @vop4=0     
        
        update ccCampsInfo set
             contact_reg=isnull( case when @vop2=0 then 0 else (@vop1/@vop2)*100 end,0)
            , dial_retries=isnull(case when @vop4=0 then 0 else(@vop3/@vop4)*100 end,0)
            , date_update=getdate()
    end
end

select
cam_id, contact_reg, dial_retries, date_update, calls_per_second
from ccCampsInfo
where cam_id = @CampId


set nocount off'
    EXEC(@sql);

    SET @process = 'Alter Sp ccsp_RIA_ABCAgents se agrega delete from ccUsers_Roles where User_id=@UserId'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
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
  delete from ccUsers_Roles where User_id=@UserId
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
    EXEC(@sql);


    SET @process = 'Alter SP ccsp_RIAUpdateCamConfigExtend se valida @recordCalls es nulo y el el valor tabla es nullo se pone 1'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfigExtend]
    @cam_id smallint,
    @zipCodeSchedule BIT = NULL,
    @userId SMALLINT = NULL,
    @idArea SMALLINT = NULL, 
    @isCreating SMALLINT = NULL,
    @simultaneousRecs SMALLINT = NULL,
    @module INT = -1,
    @recordCalls tinyint = 1,
    @editableContactData BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @country INT = (select valor from ccSettings where setting_id = 104); 
    DECLARE @excludeIdentifier VARCHAR(255) = CASE WHEN @country = 4 THEN ''COMMON_INTERNATIONAL_RECORD_CALLS'' ELSE ''COMMON_USA_RECORD_CALLS'' END;
    if exists(select * from ccCampsExtend where cam_id=@cam_id) begin

        EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCampsExtend'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

        Create table #ccCampsExtendTable 
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )

        DECLARE @Camptype INT = (SELECT [CampType] FROM ccCamps WHERE cam_id = @cam_id);
        DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
            CASE 
                WHEN @Camptype = 6  THEN 44
                WHEN @Camptype = 5  THEN 46
                WHEN @Camptype = 4  THEN 48
                WHEN @Camptype = 7  THEN 50
                ELSE 42 END
        ELSE 
            CASE 
                WHEN @Camptype = 6  THEN 55
                WHEN @Camptype = 5  THEN 56
                WHEN @Camptype = 4  THEN 57
                WHEN @Camptype = 7  THEN 58
                ELSE 54 END
        END;

        
        UPDATE ccCampsExtend SET
            zipCodeSchedule = isnull(@zipCodeSchedule,zipCodeSchedule),
            simultaneousRecs = isnull(@simultaneousRecs,simultaneousRecs),
            RecordCalls = case when @recordCalls is null and RecordCalls is null then 1 else  ISNULL(@recordCalls, RecordCalls) end,
            EditableContactData = isnull(@editableContactData,EditableContactData)
        Where cam_id = @cam_id  

        select @recordCalls =RecordCalls from ccCampsExtend Where cam_id = @cam_id  


        IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsExtendTable'';

        IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            @operation, 
            @module, 
            CCCE.identifierInfo,
            CASE WHEN CCCE.identifierInfo IS NOT NULL AND CCCE.identifierInfo <> '''' THEN
                CASE 
                    WHEN CCCE.identifierInfo IN (''SETTINGS_CHANGED_AREAS_ZIP'', ''COMMON_INTERNATIONAL_RECORD_CALLS'', ''EDIT_CALL_DATASET'') THEN
                        CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                    WHEN CCCE.identifierInfo IN (''COMMON_USA_RECORD_CALLS'') THEN
                        CASE WHEN CCCE.dataInfo = 1 THEN ''COMMON_USA_RECORD_CALLS_MODE_ALL''
                            WHEN CCCE.dataInfo = 2 THEN ''COMMON_USA_RECORD_CALLS_MODE_AUTH''
                            WHEN CCCE.dataInfo = 4 THEN ''COMMON_USA_RECORD_CALLS_MODE_NOAUTH''
                            ELSE ''COMMON_DISABLED'' END
                    ELSE CCCE.dataInfo END
            ELSE '''' END,
            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
        FROM #ccCampsExtendTable AS CCCE where CCCE.identifierInfo != @excludeIdentifier;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCampsExtend'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
        IF OBJECT_ID(N''tempdb..#ccCampsExtendTable'') IS NOT NULL DROP TABLE #ccCampsExtendTable

    end
    else begin
        INSERT INTO ccCampsExtend(cam_id,zipCodeSchedule,SimultaneousRecs, RecordCalls, EditableContactData) values (@cam_id,@zipCodeSchedule,@simultaneousRecs, @recordCalls, @editableContactData)
    end



    update ccCamps set call_record = case when call_record is null and @recordCalls is null then 1 else ISNULL(@recordCalls, call_record) end where cam_id = @cam_id

    set nocount off
END'
    EXEC(@sql);

    SET @process = 'Alter Sp ccsp_UnassignedElementsInAreas delete from ccoDialerCamp where cam_id = @Id --Elimina los puertos'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_UnassignedElementsInAreas]   
@Action INT,   
@AreaId INT = 0,
@Ids VARCHAR(max) = ''''
AS    
BEGIN
    DECLARE @IdsTemp TABLE (Id INT);
    DECLARE @RestTable TABLE (Id INT);


    DECLARE @Id VARCHAR(max);
    DECLARE @Result VARCHAR(max);
    INSERT INTO @IdsTemp(Id)
    SELECT cast(VALUE as int) FROM dbo.fn_RIASplitDelimited(@Ids,'','')

    set @Result=''''
    -- Return results 
    IF @Action IN (0, 3, 6) -- User names 
    BEGIN 
        SELECT @Result=@Result+ 
        case when login is not null then login+'','' else '''' end  --AS ElementNames
        FROM @IdsTemp ids
        INNER JOIN ccUsers users ON users.User_id = ids.Id  
    END

   else IF @Action IN (1, 4, 7) -- Campaign names
    BEGIN 
        
        SELECT  @Result=@Result+ 
        case when cam_descripcion is not null then cam_descripcion+'','' else '''' end  --AS ElementNames       
        FROM @IdsTemp ids
        INNER JOIN ccCamps campaign ON campaign.cam_id = ids.Id
    END

   else IF @Action IN (2, 5, 8) -- Acd names
    BEGIN 
        SELECT @Result=@Result+ 
        case when descripcion is not null then descripcion+'','' else '''' end  --AS ElementNames       
        FROM @IdsTemp ids
        INNER JOIN ccInbound acd ON acd.Inbound_id = ids.Id
    END
    -------------------------------------------------------
    IF @Action = 0 -- Assign Users to Unassigned area 
    BEGIN
        UPDATE ccUsers
        SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END,
            status = 1
        FROM @IdsTemp ids
        WHERE ccUsers.User_id = ids.Id
        AND NOT EXISTS (SELECT 1 FROM ccUsers WHERE IDArea = @AreaId AND User_id = ids.Id)
    END

   else IF @Action = 1 -- Assign Users to Campaigns area 
    BEGIN
        UPDATE ccCamps
        SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END
        FROM @IdsTemp ids
        WHERE ccCamps.cam_id = ids.Id
        AND NOT EXISTS (SELECT 1 FROM ccCamps WHERE IDArea = @AreaId AND cam_id = ids.Id)
    END

   else IF @Action = 2 -- Assign Users to Acds area 
    BEGIN       
        UPDATE ccInbound
        SET IDArea = CASE @AreaId WHEN 0 THEN NULL ELSE @AreaId END,
            status = 1
        FROM @IdsTemp ids
        WHERE ccInbound.Inbound_id = ids.Id
        AND NOT EXISTS (SELECT 1 FROM ccInbound WHERE IDArea = @AreaId AND Inbound_Id = ids.Id)
    END

    IF @Action in (3, 4, 5, 6, 7, 8)
    BEGIN       

        SET @Id = ''0''
        WHILE EXISTS( SELECT Id FROM @IdsTemp ) 
        BEGIN
            SELECT TOP 1 @Id =Id FROM @IdsTemp 

            IF @Action = 3 -- Unassign Users from area 
            BEGIN
                EXEC ccsp_RIAManageAreas @option = 2, @DeleteUserId = @Id
            END

            IF @Action = 4 -- Unassign Campaigns from area 
            BEGIN
                DECLARE @TempResult INT;
                EXEC @TempResult = ccsp_RIAManageAreas @option=4, @DeleteCamId = @Id;
                IF @TempResult = -4 
                BEGIN
                    SET @Result = ''-1'';
                END
            END 

            IF @Action = 5 -- Unassign Acds from area 
            BEGIN
                insert into @RestTable
                EXEC ccsp_RIAManageAreas @option = 6, @DeleteACDGroupId = @Id
            END

            IF @Action = 6 -- Delete Users from area 
            BEGIN
                EXEC ccsp_RIA_ABCAgents @option=4, @UserId = @Id, @Login = '''', @Nombres='''',@ApellidoPaterno='''',@ApellidoMaterno='''',@Password='''',@Sexo=0,@canChangeStatus=0,@AreaId=0,@UserType=0,@IDWG=0
            END

            IF @Action = 7 -- Delete Campaigns from area 
            BEGIN
                EXEC ccsp_RIA_ABCCamps @option = 4, @UserId = 0, @Descripcion = '''', @Cam_id = @Id, @Activa = 0, @IDArea = 0, @frame = 0
                delete ccCamps with(rowlock) where cam_id = @Id
                delete ccCampsExtend with(rowlock) where cam_id = @Id
                delete from ccoDialerCamp where cam_id = @Id --Elimina los puertos
            END

            IF @Action = 8 -- Delete Acds from area 
            BEGIN
                EXEC ccsp_RIA_ABCACDGroups @option = 4, @UserId = 0, @Descripcion = '''', @Inbound_id = @Id, @IDArea = 0, @frame = 0
                delete ccInbound with(rowlock) where Inbound_id = @Id
                delete ccInboundExtend with(rowlock) where Inbound_Id = @Id
            END

            DELETE FROM @IdsTemp WHERE Id = @Id
        END
    END

    if @Result<>'''' begin
        set @Result= substring(@Result,1,len(@Result)-1)
    end

    SELECT @Result
END'
    EXEC(@sql);

     SET @process = 'Se crea setting 274 version de liberacion del instalador'
    SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 274)
BEGIN
    INSERT INTO ccSettings2(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
    VALUES(274, ''125.20231211.0.14'', ''Version del instalador'', 1, ''XXX'', ''Version del instalador '',
                     ''Installer version'',0,''.*'') 
END'
    EXEC(@sql);

        SET @process = 'Se crea setting 275 ubicacion de lectura de archivos de excel en el adminMachine'
    SET @sql = 'IF NOT EXISTS(SELECT 1 FROM ccSettings2 WHERE setting_id = 275)
BEGIN
    INSERT INTO ccSettings2(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
    VALUES(275, ''..\..\Sites\Galatea\GalateaAdminWS\ExcelFiles'', ''Ruta donde esta gurdado los archivos de excel'', 1, ''XXX'', ''Path where the excel files are saved'',
                     ''Ruta donde esta gurdado los archivos de excel'',0,''.*'') 
END'
    EXEC(@sql);


    SET @process = 'Alter Sp ccsp_GalateaAdminRotativeANI se agrega cast smallint id_RAniList'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminRotativeANI]
    @type SMALLINT,
    @idArea SMALLINT = NULL,
    @descriptionList VARCHAR(50) = NULL,
    @id_RAniList SMALLINT = NULL,
    @PageIndex      INT = 0,
    @PageSize       INT = 0,
    @UserId         SMALLINT = 0

AS
BEGIN
    SET NOCOUNT ON;

    IF (@type = 1) -- Read Rotative ANI List Catalog
    BEGIN
        SELECT CAST(cral.id_RAniList AS SMALLINT) id_RAniList,
               cral.description,
               cral.idArea
        FROM dbo.ccRotativeANIList AS cral
        WHERE cral.idArea IN (@idArea,-1) 
        AND cral.id_RAniList = ISNULL(@id_RAniList, cral.id_RAniList);
        RETURN 0;
    END;
    IF (@type = 2)
    BEGIN
        SELECT * 
        FROM
            (SELECT ROW_NUMBER() OVER(ORDER BY loadDate ASC) AS RowNum,
                CAST(id_RAniList AS SMALLINT) id_RAniList,
                telAni,
                loadDate
            FROM dbo.ccRotativeANIListDetail
            WHERE id_RAniList = @id_RAniList) tmp
        WHERE  tmp.RowNum > @PageSize * (@PageIndex - 1)
        AND tmp.RowNum <= @PageSize * @PageIndex
        RETURN 0;
    END;
    If @type=3 --Create Rotative ANI List
    begin
        declare @newANILstId SMALLINT = -1 --Name in use

        if not exists(select id_RAniList from ccRotativeANIList where description = @descriptionList)
        begin
            insert into ccRotativeANIList (description,idArea) values(@descriptionList, @idArea)
            select @newANILstId = SCOPE_IDENTITY() 
        end

        select @newANILstId as [result]
        return(0)
    end
    If @type=4 --Update Rotative ANI List
    begin
        declare @idAreaOfExistingLst smallint

        select @idAreaOfExistingLst = idArea from ccRotativeANIList where id_RAniList = @id_RAniList
        if(@idAreaOfExistingLst = -1 and @idArea <> @idAreaOfExistingLst)   --Changing from global to particular idArea
        begin
            if exists(select cam_id from ccCamps where IDArea <> @idArea and id_anilist = @id_RAniList and ISNULL(rotativeAlgo, 0) > 0)
            begin
                select -2 as [result] --Cant change idArea cause the ANI list is related to camps on other IDArea
                return(0)
            end
        end

        if exists(select id_RAniList from ccRotativeANIList where [description] = @descriptionList and id_RAniList <> @id_RAniList)
        begin
            SELECT -1 as [result] --Name in use
            return(0)
        end

        update ccRotativeANIList set [description] = @descriptionList, idArea = @idArea where id_RAniList = @id_RAniList
        SELECT 1 as [result]
        return(0)
    end
    If @type=5 --Delete Rotative ANI List
    begin
        declare @result int = -2   --ANI list is related to campaign

        if not exists(select cam_id from ccCamps where id_anilist = @id_RAniList and ISNULL(rotativeAlgo, 0) > 0)
        begin
            delete ccRotativeANIListDetail where id_RAniList = @id_RAniList
            delete ccRotativeANIList where id_RAniList = @id_RAniList
            select @result = 1
        end

        select @result as [result]
        return(0)
    END
    IF (@type = 6) -- Read Rotative ANI List By Id
    BEGIN
        SELECT CAST(cral.id_RAniList AS SMALLINT) id_RAniList,
               cral.description,
               cral.idArea
        FROM dbo.ccRotativeANIList AS cral
        WHERE cral.id_RAniList = @id_RAniList
        RETURN 0;
    END

    IF (@type = 7) -- Get List size
    BEGIN
        SELECT COUNT(*) AS listSize FROM dbo.ccRotativeANIListDetail WHERE id_RAniList = @id_RAniList
        RETURN 0;
    END
    IF(@type = 8) --Check if exist an other process executing
    BEGIN 
        SELECT CASE WHEN COUNT(crl.load_id) > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS isProcessExecuting FROM dbo.ccRIALoading AS crl
        WHERE crl.cam_id = @id_RAniList AND crl.state IN (0,2) AND crl.loadType = 2;
        RETURN (0);
    END
    IF(@type = 9) --Check if exist a campaign executing
    BEGIN
        SELECT CASE WHEN COUNT(cc.cam_id) > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS isCampaignExecuting   FROM dbo.ccCamps AS cc
        WHERE cc.id_anilist = @id_RAniList AND cc.rotativeAlgo IN (1,2,3)
        AND cc.cam_procesando = 1
        RETURN 0;
    END
    IF(@type = 10) --Update current Rotative ANI List loads to error
    BEGIN
        IF(@UserId = 0)
        BEGIN
            UPDATE ccRIALoading SET [state] = 4 WHERE loadType = 2 AND [state] < 3
        END
        UPDATE ccRIALoading SET [state] = 4
        WHERE loadType = 2 AND [state] < 3 AND userID = @UserId 
        SELECT CASE WHEN @@ROWCOUNT > 0 THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS LoadError
        RETURN 0;
    END
    IF(@type = 11) -- Get campaign and area by ani list id
    BEGIN
        SELECT cc.id_anilist, crg.frame, cc.cam_descripcion,crca.AreaName
        FROM dbo.ccCamps AS cc INNER JOIN dbo.ccRIACat_Areas AS crca ON crca.IDArea = cc.IDArea
        INNER JOIN dbo.ccRIACampsGraph AS crcg ON crcg.cam_id = cc.cam_id
        INNER JOIN dbo.ccRIAGraphics AS crg ON crg.graphic_id = crcg.graphic_id
        WHERE cc.id_anilist = @id_RAniList AND cc.rotativeAlgo IN (1,2,3)
    END
SET NOCOUNT OFF

END'
    EXEC(@sql);

    SET @process = 'Alter SP ccspAgent_GetLastCalls Correcion para no tomar el tiempo Hold'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
AS
SET NOCOUNT ON;
DECLARE @lastCallAgt TABLE(id           INT NOT NULL
                        , tipo         VARCHAR(10) NOT NULL
                        , Hora         DATETIME NOT NULL --VARCHAR(19) NOT NULL, 
                        , Telefono     VARCHAR(55) NOT NULL
                        , EspCamp      VARCHAR(55) NOT NULL
                        , Calificacion VARCHAR(150)
                        , Duracion     VARCHAR(10) NOT NULL
                        , CallBack     DATETIME
                        , cal_key      VARCHAR(40)
                        , IDCampEsp    SMALLINT NOT NULL
                        , prefijo      VARCHAR(255) NULL
                        , GraphicID    INT
                        , CamManualMode INT
                        , SelectRotativeANI INT
                        , PRIMARY KEY(id,tipo)
);

DECLARE @pais TINYINT;
DECLARE @maxHours SMALLINT;
DECLARE @topRows INT;
DECLARE @setting VARCHAR(6);
DECLARE @hidePhone BIT;
DECLARE @dateStart DATETIME;

SET @hidePhone = 1;

SELECT @setting = valor FROM ccSettings WHERE setting_id = 255;

SET @maxHours = CAST(SUBSTRING(@setting, 1, (SELECT PATINDEX(''%|%'', @setting)) - 1) AS SMALLINT);
SET @topRows = CAST(SUBSTRING(@setting, (SELECT PATINDEX(''%|%'', @setting)) + 1, LEN(@setting)) AS INT);

IF @maxHours = 0
BEGIN
    SELECT Id
        , tipo
        , (CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) AS Hora
        , Telefono
        , EspCamp
        , Calificacion
        , CallBack
        , Duracion
        , '''' AS CallBack
        , cal_key
        , IDCampEsp
        , prefijo
        , GraphicID
        , SelectRotativeANI
        , @hidePhone AS HidePhone FROM @lastCallAgt;

    RETURN 0;
END;

SELECT @pais = valor FROM ccSettings WHERE setting_id = 104;

SELECT @hidePhone = CASE WHEN valor = ''0''
                    THEN 0 ELSE 1
                    END FROM ccSettings WHERE setting_id = 223;

IF @topRows = 0
BEGIN
    SET @topRows = 10000;
END;

SET @dateStart = DATEADD(hh, -@maxHours, GETDATE());

WITH timeTransfer
    AS (SELECT cal_id
            , tipo
            , SUM(tAntesXfer) AS tAntesXfer
            , SUM(tDespuesXfer) AS tDespuesXfer FROM ccLogTransfers
        WHERE fechaFin > @dateStart
        GROUP BY cal_id
                , tipo)

    INSERT INTO @lastCallAgt
            ---Insert OUT
            SELECT TOP (@topRows) c.cal_id AS id
                                , ''OUT'' AS Tipo
                                , cal_inicio
                                , cal_telefono AS Telefono
                                , cam_descripcion AS EspCamp
                                , ISNULL(cal.Description, '''') AS Calificacion
                                , CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - case when ccCamps.recordHold=1 then 0 else cal_tMoh end 
                                + CASE WHEN stopRecording = 0
                                                                                        THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                        END, 0), 114) AS Duracion
                                , cal_fcallback AS CallBack
                                , cal_key
                                , c.cam_id AS IDCampEsp
                                , ISNULL(ccCamps.prefijo, '''') Prefijo
                                , graph.graphic_id GraphicID
                                , cam_ModoManual as CamManualMode 
                                , ISNULL(selectRotativeANI, 0) as SelectRotativeANI FROM ccoCallsOut c
                                                                INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
                                                                LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
                                                                LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
                                                                LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                            AND t.tipo = 2
            WHERE user_id = @user_id
                AND cal_inicio > @dateStart
            UNION
            --- IN
            SELECT TOP (@topRows) c.cal_id AS id
                                , ''IN'' AS Tipo
                                , cal_inicio
                                , cal_ani AS Telefono
                                , descripcion AS EspCamp
                                , ISNULL(cal.Description, '''') AS Calificacion
                                , CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - case when ccInbound.recordHold=1 then 0 else cal_tMoh end  
                                + CASE WHEN stopRecording = 0
                                                                                                THEN ISNULL(t.tDespuesXfer, 0) ELSE 0
                                                                                                END, 0), 108) Duracion
                                , NULL AS CallBack
                                , cal_key
                                , c.inbound_id AS IDCampEsp
                                , ISNULL(ccInbound.prefijo, '''') Prefijo
                                , graph.graphic_id GraphicID
                                , '''' as CamManualMode 
                                , 0 as SelectRotativeANI FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
                                                              inner JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
                                                                INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
                                                                LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
                                                                LEFT JOIN timeTransfer t ON c.cal_id = t.cal_id
                                                                                            AND t.tipo = 1
            WHERE user_id = @user_id
                AND cal_inicio > @dateStart;

SELECT Id
    , tipo
    , CASE WHEN @pais = 4
    THEN(CONVERT(VARCHAR(10), Hora, 101) + '' '' + CONVERT(VARCHAR(8), Hora, 108)) ELSE(CONVERT(VARCHAR(10), Hora, 103) + '' '' + CONVERT(VARCHAR(8), Hora, 14))
    END AS Hora
    , Telefono
    , EspCamp
    , Calificacion
    , ISNULL(CONVERT(VARCHAR(16), CallBack, 121), '''') AS CallBack
    , Duracion
    , CallBack
    , cal_key
    , IDCampEsp
    , prefijo
    , GraphicID
    , @hidePhone AS HidePhone 
    , CamManualMode 
    , SelectRotativeANI FROM @lastCallAgt
ORDER BY hora DESC;
SET NOCOUNT OFF;'
    EXEC(@sql);
   

    SET @process = 'Alter SP ccsp_GalateaManageWG @Type = 1 para validar si ya esta la relacion cargada'
    SET @sql = 'ALTER PROCedure [dbo].[ccsp_GalateaManageWG]
@option smallint,
@IDWG smallint,
@Type smallint = 0,
@usersList varchar(max) ='''',
@ListCampsIn varchar(max) = '''',
@ListCampsOut varchar(max) ='''',
@idNewArea int = 0,
@LoginId int = 0,
@AreaId int = 0
as
set nocount on
declare @count int
declare @id int
declare @user int
declare @IDCampEsp varchar(max)
declare @Assigned  varchar(max)
declare @AssignedCampsIn  varchar(max)
declare @AssignedCampsOut  varchar(max)

set @id = 1
set @Assigned = ''''
set @AssignedCampsIn = ''''
set @AssignedCampsOut = ''''


IF OBJECT_ID(''tempdb..#UsersList'') IS NOT NULL DROP TABLE #UsersList;
IF OBJECT_ID(''tempdb..#CampsInOutList'') IS NOT NULL DROP TABLE #CampsInOutList;

select *  into #CampsInOutList from (
select ROW_NUMBER() OVER(ORDER BY [CampEsp] ASC) AS Row, [CampEsp], [Type] from (
    select 0 as [Type],
    [value] As [CampEsp]
    FROM fn_RIASplitDelimited(@ListCampsIn, '','') where [value] > 0
    union
    select 1 as [Type],
    [value] As [CampEsp]
    FROM fn_RIASplitDelimited(@ListCampsOut, '','') where [value] > 0
    ) as Camps ) as CampsInOut

select ROW_NUMBER() OVER(ORDER BY value ASC) AS Row,
    value As user_id
    into #UsersList
    FROM fn_RIASplitDelimited(@usersList, '','')

select @count = count(user_id) from #UsersList

IF(@option = 1 OR @option = 2) BEGIN

    DECLARE @areaName VARCHAr(50);
    DECLARE @userLogin VARCHAR(40);
    DECLARE @workGroupName VARCHAR(40);
    DECLARE @userToAffect VARCHAR(40);
    DECLARE @campName VARCHAR(40);

END

if @option = 1 -- Insert Agente-Supervisor in WorkGroup
 begin

    while @id<=@count
    begin
        select @user = user_id from #UsersList where Row= @id
        select @Type = tipoUser_id from ccUsers where user_id = @user

        if @Type in(1, 2, 6)
        begin

            if not exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
            begin
            

                If @Type = 1
                 begin

                        If (select count(User_id) from ccRIAWorkGroupUsers where User_id = @user) < (select valor from ccSettings where setting_id = 63)
                         begin
                            insert into ccRIAWorkGroupUsers(IDWG, User_id) values(@IDWG,@user)

                            --INSERT LOG RECORD (ASSIGN AGENT)
                            SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                            SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                            SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 23, 3, '''', @userToAffect, @workGroupName);

                            select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                            --insert skill media
                            exec ccsp_Skills @action= 5,@userId=@user

                            --select * from cccampsAgente where user_id=@user and 

                            insert into cccampsAgente (user_id, cam_id, prioridad, skill, IDWG)
                            select @user [User_id], A.idCampEsp [cam_id], dbo.fn_Calcula_UsrPriority(@user,0) [prioridad], 1 [skill], @IDWG IDWG
                            
                            from ccRIACampEspWG A
                            inner join ccCamps C on A.Tipo=1 and A.idCampEsp=C.cam_id                           
                            where A.tipo = 1 and A.IDWG = @IDWG and
                             idCampEsp not in (select cam_id from cccampsAgente where user_id=@user and IDWG=@IDWG)
                             


                           insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, IDWG)
                            select @user, A.idCampEsp, 0, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
                            from ccRIACampEspWG A
                            inner join ccInbound C on A.Tipo=0 and A.idCampEsp=C.Inbound_id
                            where A.tipo = 0 and IDWG = @IDWG and

                            idCampEsp not in (select inbound_id from ccInboundAgentes where user_id=@user and IDWG=@IDWG)

                            if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
                                insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
                            end
                        end
                 end
                 else if @Type in(2, 6)
                 begin
                    -- -Supervisor  @Type in (2,6)
                    insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @user)

                    --INSERT LOG RECORD (ASSIGN ADMIN)
                    SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                    SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                    SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 30, 3, '''', @userToAffect, @workGroupName);

                    select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                    if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
                        insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
                    end

                    insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                    select @user, idCampEsp, 0, @IDWG
                    from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
                     and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)

                    update ccSupervisorCam
                    set monitored = 1
                    where user_id = @user
                    and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)
                    and tipo = 0
                    and IDWG <> @IDWG
                    and monitored = 0

                    insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                    select @user, idCampEsp, 1, @IDWG
                    from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
                     and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)

                    update ccSupervisorCam
                    set monitored = 1
                    where user_id = @user
                    and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)
                    and tipo = 1
                    and IDWG <> @IDWG
                    and monitored = 0
                end
                
            end
        end
        set @id = @id+1
    end
end




if @option = 2 -- Delete Agent-Supervisor from WorkGroup
 begin

    while @id<=@count
    begin
        select @user = user_id from #UsersList where Row= @id
        select @Type = tipoUser_id from ccUsers where user_id = @user
        
        if @Type = 1 --delete skill media
        exec ccsp_Skills @action= 4,@userId=@user,@idwg=@IDWG
        
        if exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
        begin
        
            Delete ccRIAWorkGroupUsers where IDWG = @IDWG and User_id = @user
        

            if @Type = 1 -- Agente
             begin

                --INSERT LOG RECORD (UNASSIGN AGENT)

                SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 24, 3, '''', @userToAffect, @workGroupName);

                select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG   from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
                insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG

                delete from cccampsagente where user_id=@user and IDWG=@IDWG
                delete from ccInboundagentes where user_id=@user and IDWG=@IDWG

                --update preview permission
                update ccusers set 
                AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
                DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
                select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
                where progDial=3 and user_id = @user group by user_id)c on us.User_id=c.user_id
                where us.user_id = @user
                --select @Type
             end
             else if @Type in(2, 6) -- Supervisor
             begin

                --INSERT LOG RECORD (UNASSIGN ADMIN)

                SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 31, 3, '''', @userToAffect, @workGroupName);

                select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
                delete ccSupervisorCam where user_id=@user and IDWG=@IDWG
                --select @Type
            end
        end
        set @id = @id+1
    end
end
if @option in (1,2)
begin
    if LEN(@Assigned) > 0
        select SUBSTRING(@Assigned,0,Len(@Assigned))
    else
        select @Assigned

    return(0)
end

if @option = 3 -- Insert WorkGroup in Camp or ACDGroup  
  begin
    select @count = count(CampEsp) from #CampsInOutList

    while @id<=@count
    begin
         select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id
         

         if (select count(IdCampEsp) from ccRIACampEspWG where IdCampEsp=@IDCampEsp and Tipo=@Type) < (select valor from ccSettings where setting_id=180) -- limit
             begin

                if (select count(IDWG) from ccRIACampEspWG where IDWG=@IDWG) < (select valor from ccSettings where setting_id=64) -- limit
                    begin

                        if not exists (select IDWG from ccRIACampEspWG where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) -- No existe el grupo en el ACD o Especialidad
                        begin

                            insert into ccRIACampEspWG (IDWG, Tipo, IdCampEsp, priority) values (@IDWG, @Type, @IDCampEsp, 1)
                            if not exists(select * from ccRIACampEspWGConsulta where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) begin
                                insert into ccRIACampEspWGConsulta (IDWG, Tipo, IdCampEsp) values (@IDWG, @Type, @IDCampEsp)
                            end   

                            SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                            
                            IF(@Type = 1) SET @campName = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @IDCampEsp)
                            ELSE SET @campName = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @IDCampEsp)
                             
                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                            VALUES (
                                (SELECT [AreaName] FROM ccRIACat_Areas AS CRA, ccRIAAreaWorkGroup AS CRAW WHERE CRAW.IDWG = @IDWG AND CRA.IDArea = CRAW.IDArea), 
                                getDate(), 
                                @userLogin, 
                                36, 
                                3, 
                                '''', 
                                @campName,
                                (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG)
                            );

                            exec ccsp_RIACalcula_WGPriority @IDWG, @IDCampEsp, @Type
                            if @Type in (0, 1) -- ACDGroup
                            begin

                                if @IDWG is not null or @IDWG = 0
                                begin
                                    if @Type=0 --ACDGroup
                                    begin
                                        select @AssignedCampsIn = @AssignedCampsIn+ cast(@IDCampEsp as varchar(5))+'',''
                                        insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
                                        SELECT distinct u.user_id, @IDCampEsp, 0 cli_id, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG 
                                        FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
                                            join ccusers s on u.user_id = s.user_id
                                        WHERE c.tipo=0 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and c.IDWG=@IDWG 
                                        and u.User_id not in (select User_id from ccInboundAgentes where Inbound_id=@IDCampEsp and IDWG=@IDWG)

                                        insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                                        select b.user_id, @IDCampEsp, 0, @IDWG
                                        from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
                                            join ccusers s on b.user_id = s.user_id
                                        where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=0
                                            and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=0 and IDWG=@IDWG)
             
                                        --return(0)
                                    end

                                    else if @Type = 1 -- Camp
                                    begin
                                        select @AssignedCampsOut = @AssignedCampsOut+ cast(@IDCampEsp as varchar(5))+'',''
                                        insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
                                        SELECT distinct u.user_id, @IDCampEsp, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG
                                        FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
                                        join ccusers s on u.user_id = s.user_id
                                        WHERE c.tipo=1 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and u.IDWG=@IDWG 
                                            and u.User_id not in (select User_id from ccCampsAgente where cam_id=@IDCampEsp and IDWG=@IDWG)
            
                                        insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                                        select b.user_id, @IDCampEsp, 1, @IDWG
                                        from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
                                            join ccusers s on b.user_id = s.user_id
                                        where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=1
                                            and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=1 and IDWG=@IDWG)
                                    end
                            end
                        end
                    end
                end
            end
        set @id = @id + 1
   end
end

if @option = 3
begin
    
if LEN(@AssignedCampsIn) > 0 or LEN(@AssignedCampsOut) > 0
        select SUBSTRING(@AssignedCampsIn,0,Len(@AssignedCampsIn)) as CampsInAssigned, SUBSTRING(@AssignedCampsOut,0,Len(@AssignedCampsOut)) as CampsOutAssigned 
    else
        select @AssignedCampsIn as CampsInAssigned, @AssignedCampsOut as CampsOutAssigned

    return(0)
end

if @option = 4  --Delete relatoion Camp with WG
begin
declare @multipleAgents varchar(1000)
declare @multipleAdmins varchar(2000)
declare @sql varchar(max)

select @count = count(CampEsp) from #CampsInOutList
 while @id<=@count
  begin

        select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id

        SELECT @multipleAgents = coalesce(@multipleAgents + '','', '''') + CAST(A.user_id AS VARCHAR(40))
        FROM ccRIAWorkGroupUsers A
        JOIN ccUsers B ON A.user_id = B.user_id
        WHERE IDWG = @IDWG AND TipoUser_id = 1

        SELECT @multipleAdmins = coalesce(@multipleAdmins + '','', '''') + CAST(A.user_id AS VARCHAR(40))
        FROM ccRIAWorkGroupUsers A
        JOIN ccUsers B ON A.user_id = B.user_id
        WHERE IDWG = @IDWG AND TipoUser_id = 2


        if right( @multipleAgents,1)='','' begin
            set @multipleAgents=SUBSTRING(@multipleAgents,0,len(@multipleAgents)-1)
        end
        if right( @multipleAdmins,1)='','' begin
            set @multipleAdmins=SUBSTRING(@multipleAdmins,0,len(@multipleAdmins)-1)
        end


        --Delete Agent from WorkGroup
           set @sql = ''ccsp_RIA_ABCAgents @option=7,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
                    @AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAgents+''''''''
           
           exec(@sql)

         --Delete Supervisor from WorkGroup

         set @sql = ''ccsp_RIA_ABCAgents @option=8,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
                    @AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAdmins+''''''''
           
           exec(@sql)

        --Delete WokGroup from ACD or Camp 

        SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                            
        IF(@Type = 1) SET @campName = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @IDCampEsp)
        ELSE SET @campName = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @IDCampEsp)
                             
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        VALUES (
            (SELECT [AreaName] FROM ccRIACat_Areas AS CRA, ccRIAAreaWorkGroup AS CRAW WHERE CRAW.IDWG = @IDWG AND CRA.IDArea = CRAW.IDArea), 
            getDate(), 
            @userLogin, 
            59, 
            3, 
            '''', 
            @campName,
            (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG)
        );


         set @sql = ''exec ccsp_RIA_ABCWorkGroups @option=7,@IDWG=''+cast(@IDWG as varchar(4))+'',@IDCampEsp=''''''+cast(@IDCampEsp as varchar(4))+'''''',@Type=''+cast(@Type as varchar(4))+''''
         exec(@sql)
         
        set @id = @id + 1
    
    end

    select 1
    return 0
end

if @option = 5  --Change Admin Administrator.
begin
declare @user_id int
select @user_id = value FROM fn_RIASplitDelimited(@usersList, '','')
select @Type = TipoUser_id from ccUsers where User_id = @user_id

        if @Type = 1 -- Agente
        begin

            if(select count(user_id) from ccCampsAgente where user_id = @user_id) >0 or 
            (select count(user_id) from ccInboundAgentes where user_id = @user_id) >0 or
            (select count(user_id) from ccRIAWorkGroupUsers where user_id = @user_id) > 0
            begin
                select -1
                return 0
            end
            else

                SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user_id AND CCRA.IDArea = CCU.IDArea;
                SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                VALUES (@areaName, getDate(), @userLogin, 27, 3, ''T&CHANGE_USER_AREA'', (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idNewArea), @userToAffect);

                update ccUsers set IDArea = @idNewArea where user_id = @user_id
        end

        
    if @Type in (2, 6) -- Supervisor
    begin

        if(select count(user_id) from ccSupervisorCam where user_id = @user_id) > 0 or
        (select count(user_id) from ccRIAWorkGroupUsers where user_id = @user_id) > 0
        begin
            select -1
            return 0
        end
        else

            SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user_id AND CCRA.IDArea = CCU.IDArea;
            SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            VALUES (@areaName, getDate(), @userLogin, 34, 3, ''T&CHANGE_USER_AREA'', (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idNewArea), @userToAffect);

            update ccUsers set IDArea = @idNewArea where user_id = @user_id
    end

    update ccPosicion set user_id = 0 where user_id = @user_id

    select 1

end

set nocount off'
    EXEC(@sql);

    

---------------------------------------- BEGIN fix/125.20231211.012 -------------------------------------------------
   

    set @process = 'Create table ccLogAgentesDiaLast'
    set @sql = 'if not exists (select * from sys.tables where name = N''ccLogAgentesDiaLast'')
    begin
        CREATE TABLE [dbo].[ccLogAgentesDiaLast]
(
      [User_id] SMALLINT NOT NULL
    , [TipoStatusAge_id] TINYINT NOT NULL
    , [tStatus] FLOAT NULL
    , [fecha] DATETIME NOT NULL
    , [IdCampEsp] SMALLINT NULL
    , [Tipo] SMALLINT NULL
    , [currentStatus] INT NULL
    , [callID] INT NULL
    , CONSTRAINT [PK__ccLogAge__206A9DF893323245] PRIMARY KEY ([User_id] ASC)
)

ALTER TABLE [dbo].[ccLogAgentesDiaLast] WITH CHECK ADD CONSTRAINT [FK_ccLogAgentesDiaLast_ccTipoStatusAgente] FOREIGN KEY([TipoStatusAge_id]) REFERENCES [dbo].[ccTipoStatusAgente] ([TipoStatusAge_id])
ALTER TABLE [dbo].[ccLogAgentesDiaLast] CHECK CONSTRAINT [FK_ccLogAgentesDiaLast_ccTipoStatusAgente]
    end'
        EXEC(@sql);

        SET @process = 'TT8053 DROP VIEW ccLogAgentesDiaViewLast'
        SET @sql = 'IF EXISTS(SELECT * FROM sys.views WHERE name=''ccLogAgentesDiaViewLast'')
                    BEGIN
                    DROP VIEW ccLogAgentesDiaViewLast;
                    END;'
        EXEC(@sql);

        SET @process = 'TT8053 Create ccLogAgentesDiaViewLast for better access to last status by agent'
        SET @sql = 'CREATE VIEW ccLogAgentesDiaViewLast AS
SELECT User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo, currentStatus, callId
FROM ccLogAgentesDiaLast with(nolock)      ;
                    '
        EXEC(@sql);

        SET @process = 'CW-8638 Alter ccsp_SaveStatusAgent se agrega ccLogAgentesDiaLast
Landus se agrega with(nolock) ccLogAgentesDiaLast '
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_SaveStatusAgent]
@User_id smallint,
@TipoStatusAge_id tinyint,
@TipoNotReady smallint,
@tStatus float,
@TipoCall  tinyint,
@Camp smallint,
@callout_id int=0,
@call_id int=0,
@isLogout smallint=0, --Agrega el tiempo cuando esta dialogo y se desloguea
@tDialog float =0 ,
@currentStatus int =-2,--NUEVO PARAMETRO PARA LA NUEVA COLUMNA
@Fecha4 datetime=null,
@tMusicHold int =0,
@isTransferEngine bit = 0
AS

if @Fecha4 is null set @Fecha4 = getdate()

if @TipoCall > 0 set @TipoCall = @TipoCall - 1

 IF @User_id <= 0 OR (@tStatus = 0 AND @TipoStatusAge_id = 30)
        RETURN 0;

declare @cam_id int,@surveycamId int
declare @cal_telefono varchar(30)
declare @cal_key varchar(40)
declare @inbound_id int
declare @callBackSurveyClients bit
declare @cal_whoHung tinyint
DECLARE @cal_tXfer float,   @cal_tRing float
declare @cal_tDialog int
declare @cal_tNotas float
declare @cal_tNotaOri int
declare @tMinAVRS smallint
declare @calInicio datetime
declare @sumCall float
declare @cal_manual int 

set @cal_tNotas =0
set @cal_tNotaOri=0

if @TipoStatusAge_id=32 set @tStatus=CONVERT(DECIMAL(10,2), ROUND(@tStatus, 0, 1))

set @cal_manual =0
--4 Dialog,6 Notas, 27 Notas Fallida

 IF @TipoStatusAge_id IN (4, 6, 27) AND @call_id > 0 and @isLogout=1
BEGIN
   if @TipoStatusAge_id=4  set @tDialog=@tStatus --Dialogo
   if @TipoStatusAge_id=6  set @cal_tNotas=@tStatus --Notas

   
     if @TipoCall = 0 
     begin -- BEING IN @TipoCall = 0  ---
        SELECT @calInicio = cal_Xfer,
        @sumCall = cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas,
        @Camp = Inbound_id,
        @cal_tDialog = cal_tDialog,
        @cal_tNotaOri = cal_tNotas,
        @cal_key = cal_Key,
        @inbound_id = inbound_id,
        @cal_telefono = cal_ani,
        @cal_whoHung = cal_whoHung,
        @cal_tXfer = cal_tXfer,
        @cal_tRing = cal_tRing
        FROM ccCallsIN WITH (NOLOCK)
        WHERE cal_id = @call_id
        AND statusCall_id = 13

        IF @cal_tXfer = 0 AND @cal_tRing = 0
        BEGIN
            SELECT @cal_tXfer = CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE @cal_tXfer END,
                @cal_tRing = CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE @cal_tRing END
            FROM ccLogAgentesDia WITH (NOLOCK)
            WHERE User_id = @User_id
                AND callID = @call_id
                AND Tipo = @TipoCall
                AND TipoStatusAge_id IN (5, 9)
        END
        IF @cal_tDialog = 0 AND @tDialog > 0            
        BEGIN
            IF @Fecha4 < DATEADD(ms, (@sumCall + @tDialog + @cal_tNotas) * 1000, @calInicio)
            BEGIN
                SET @tStatus = CASE WHEN @tStatus > 0 THEN @tStatus - 1 ELSE @tStatus END

                IF @TipoStatusAge_id = 4
                    SET @tDialog = @tDialog - 1

                IF @TipoStatusAge_id = 6
                BEGIN
                    IF @cal_tNotas > 0
                        SET @cal_tNotas = @cal_tNotas - 1
                    ELSE
                        SET @tDialog = @tDialog - 1
                END
            END

            UPDATE ccCallsIN
            WITH (ROWLOCK)

            SET cal_tDialog = @tDialog,
                cal_tNotas = @cal_tNotas,
                cal_tMoh = @tMusicHold,
                cal_tXfer=@cal_tXfer,
                cal_tRing=@cal_tRing
            WHERE cal_id = @call_id
                AND statusCall_id = 13
        END
        ----------------------------
        IF @isTransferEngine = 1
        BEGIN 
            DECLARE @minimoDialogo TINYINT

            SELECT @minimoDialogo = valor
            FROM ccSettings
            WHERE setting_id = 13

            IF @cal_tDialog < @minimoDialogo
            BEGIN
                --el status 18 es para llamada cortada con transferencia en Reminder
                EXEC ccsp_RIAUpdateCallBack_Abandon @cal_id = @call_id, @nStatus = 18
            END
        END
        -----------------------------
     END -- END IN @TipoCall = 0  ---
     Else 
     begin -- BEING IN @TipoCall = 1  ---
        SELECT @calInicio = cal_inicio,
        @sumCall = cal_tXfer + cal_tRing + cal_tDialog + cal_tNotas,
        @cam_id = cam_id,
        @cal_tDialog = cal_tDialog,
        @cal_tNotaOri = cal_tNotas,
        @cal_tXfer = cal_tXfer,
        @cal_tRing = cal_tRing
        FROM ccoCallsOut WITH (NOLOCK)
        WHERE cal_id = @call_id

        SET @Camp = @cam_id

        if @cal_tXfer=0 and @cal_tRing=0 begin
            SELECT @cal_tXfer = CASE WHEN TipoStatusAge_id = 5 THEN tStatus ELSE @cal_tXfer END,
            @cal_tRing = CASE WHEN TipoStatusAge_id = 9 THEN tStatus ELSE @cal_tRing END
            FROM ccLogAgentesDia WITH (NOLOCK)
            WHERE User_id = @User_id
            AND callID = @call_id
            AND Tipo = @TipoCall
            AND TipoStatusAge_id IN (5, 9)

        end

        if @cal_tDialog = 0 and @tDialog>0 begin
            IF @Fecha4 < DATEADD(ss, @sumCall + @tDialog + @cal_tNotas, @calInicio)
                BEGIN
                    SET @tStatus = CASE WHEN @tStatus > 0 THEN @tStatus - 1 ELSE @tStatus END

                    IF @TipoStatusAge_id = 4
                        SET @tDialog = @tDialog - 1
                    IF @TipoStatusAge_id = 6
                    BEGIN
                        IF @cal_tNotas > 0
                            SET @cal_tNotas = @cal_tNotas - 1
                        ELSE
                            SET @tDialog = @tDialog - 1
                    END
                END

                UPDATE ccoCallsOut
                WITH (ROWLOCK)
                SET cal_tDialog = @tDialog,
                    totalCall_Time = @tDialog,
                    cal_tNotas = @cal_tNotas,
                    cal_tMoh = @tMusicHold,
                    cal_tXfer = @cal_tXfer,
                    cal_tRing = @cal_tRing
                WHERE cal_id = @call_id
                    AND statusCall_id = 13

        end
        else if @TipoStatusAge_id=4 and @cal_tDialog = 0 and @tDialog>0
            update ccoCallsOut with(rowlock) set cal_tDialog=@tDialog, totalCall_Time=@tDialog  
            ,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
            where cal_id = @call_id
        else if @TipoStatusAge_id=6 and @cal_tNotaOri = 0 and @cal_tNotas>0
            update ccoCallsOut with(rowlock) set cal_tNotas=@cal_tNotas 
            ,cal_tXfer=@cal_tXfer,cal_tRing=@cal_tRing
            where cal_id = @call_id 
     END -- END OUT @TipoCall = 1  ---
    
    select @tMinAVRS=isnull(valor,5) from ccSettings where setting_id=65

    if (@cal_tDialog>=@tMinAVRS or @tDialog>=@tMinAVRS) and @isLogout=1 and @cal_manual<>1 begin
        insert ccAVRSTransfer (cal_id, tipo) values (@call_id, @TipoCall)
    end

    if @TipoStatusAge_id in(6,27) begin
    --Valida que el agente no pudo guardar el status antes de desloguear
    if not exists(select  * from ccLogAgentesDia with(nolock) where User_id=@User_id and TipoStatusAge_id=4 and fecha between dateadd(ss,-@tDialog-@tStatus-@cal_tNotaOri-2,@Fecha4) and @Fecha4 )
        INSERT ccLogAgentesDia ( User_id, TipoStatusAge_id, tStatus, fecha, IdCampEsp, Tipo,currentStatus,callID ) VALUES( @User_id, 4, @tDialog, DATEADD(ss,-@tStatus, @Fecha4), @Camp, @TipoCall,@TipoStatusAge_id,@call_id )
    end
end --@TipoStatusAge_id IN (4, 6, 27) AND @call_id > 0 and @isLogout=1 --


IF (@TipoStatusAge_id = 4)
BEGIN -- 4 = Dialogo
    DECLARE @tStatus3 FLOAT, @Fecha3 DATETIME

    SELECT TOP 1 @tStatus3 = tstatus, @Fecha3 = fecha
    FROM ccLogAgentesDia WITH (NOLOCK)
    WHERE TipoStatusAge_id = 3 AND user_id = @User_id
    ORDER BY fecha DESC

    INSERT INTO ccLogAgentesDia_Dialog (
        User_id,
        Cam_id,
        fecha_Calc_ms,
        tStatus_Dispo,
        fecha_Dispo,
        tStatus_Dialog,
        fecha_Dialog
        )
    SELECT @User_id, cam_id,
        datediff(ms, dateadd(ms, - (@tStatus3 * 1000), @Fecha3), dateadd(ms, - (@tStatus3 * 1000
                    ), @Fecha4)),
        @tStatus3,
        @Fecha3,
        @tStatus,
        @Fecha4
    FROM cccampsagente
    WHERE user_id = @User_id

    ---Agregar callback en caso de este activo setting en campañas o acd y tenga relacion de campaña de encuesta
    IF @call_id > 0
    BEGIN
        IF @TipoCall = 0
        BEGIN --IN
            SELECT @surveycamid = isnull(extend.SurveyCamId, 0),
                @callBackSurveyClients = i.callBackSurveyClient
            FROM ccinbound i
            LEFT JOIN ccInboundExtend extend
                ON i.inbound_id = extend.inbound_id
            WHERE i.inbound_id = @inbound_id

            IF @surveycamId > 0
                AND (
                    @callBackSurveyClients = 1
                    OR @cal_whoHung = 1
                    )
            BEGIN
                IF EXISTS (
                        SELECT cam_id
                        FROM cccamps
                        WHERE cam_id = @surveycamid
                            AND isnull(callsBySurvey, 0) > 0
                            AND isnull(ivrScript, 0) > 0
                        )
                BEGIN
                    IF (
                            SELECT surveyPctg
                            FROM ccCamps
                            WHERE cam_id = @surveycamid
                            ) >= rand() * 100
                    BEGIN
                        INSERT INTO ccoCallsOUTSource (
                            cal_Key,
                            cam_id,
                            cal_telefono,
                            cal_status,
                            cal_fechaDial
                            )
                        VALUES (
                            right((cast(@call_id AS VARCHAR) + '''' + @cal_Key), 40),
                            @surveycamid,
                            @cal_telefono,
                            0,
                            dateadd(mi, 6, getdate())
                            )
                    END
                END
            END
        END --@TipoCall = 0
        ELSE
        BEGIN --OUT
            SELECT @surveycamId = isnull(surveycamid, 0),
                @callBackSurveyClients = callBackSurveyClient
            FROM cccamps
            WHERE cam_id = @cam_id

            SELECT @cal_key = cal_Key,
                @cam_id = cam_id,
                @cal_telefono = cal_telefono,
                @cal_whoHung = cal_whoHung
            FROM ccoCallsOUT WITH (
                    INDEX (IX_ccoCallsOut_11),
                    NOLOCK
                    )
            WHERE callout_id = @callout_id
                AND statusCall_id = 13
                AND cal_id = @call_id

            IF @surveycamId > 0
                AND (
                    @callBackSurveyClients = 1
                    OR @cal_whoHung = 1
                    )
            BEGIN
                IF (
                        SELECT surveyPctg
                        FROM ccCamps
                        WHERE cam_id = @surveycamId
                        ) >= rand() * 100
                BEGIN
                    INSERT INTO ccoCallsOUTSource (
                        cal_Key,
                        cam_id,
                        cal_telefono,
                        cal_status,
                        cal_fechaDial
                        )
                    VALUES (
                        right((cast(@call_id AS VARCHAR) + '''' + @cal_Key), 40),
                        @surveycamid,
                        @cal_telefono,
                        0,
                        dateadd(mi, 6, getdate())
                        )
                END
            END
        END
    END --@callout_id>0
END --End -- 4 = Dialogo


IF @isLogout = 0 AND @TipoStatusAge_id = 6
BEGIN --- BEGIN Insert ccLogAgentesDia @isLogout = 0 AND @TipoStatusAge_id = 6 -----
    --Valida que el ccserver no haya guardado antes el status antes al desloguear
    IF NOT EXISTS (
            SELECT *
            FROM ccLogAgentesDia WITH (NOLOCK)
            WHERE User_id = @User_id
                AND TipoStatusAge_id = 4
                AND fecha BETWEEN dateadd(ss, - 10, @Fecha4) AND @Fecha4
                AND tStatus = @tStatus + 1
            )
    BEGIN
        INSERT ccLogAgentesDia (
            User_id,
            TipoStatusAge_id,
            tStatus,
            fecha,
            IdCampEsp,
            Tipo,
            currentStatus,
            callID
            )
        VALUES (
            @User_id,
            @TipoStatusAge_id,
            @tStatus,
            @Fecha4,
            @Camp,
            @TipoCall,
            @currentStatus,
            @call_id
            )

        IF NOT EXISTS (
                SELECT *
                FROM [ccLogAgentesDiaLast] with(nolock)
                WHERE User_id = @User_id
                )
        BEGIN
            INSERT [ccLogAgentesDiaLast] (
                User_id,
                TipoStatusAge_id,
                tStatus,
                fecha,
                IdCampEsp,
                Tipo,
                currentStatus,
                callID
                )
            VALUES (
                @User_id,
                @TipoStatusAge_id,
                @tStatus,
                @Fecha4,
                @Camp,
                @TipoCall,
                @currentStatus,
                @call_id
                )
        END
        ELSE
        BEGIN
            UPDATE [ccLogAgentesDiaLast] WITH (ROWLOCK)
            SET TipoStatusAge_id = @TipoStatusAge_id,
                tStatus = @tStatus,
                fecha = @Fecha4,
                IdCampEsp = @Camp,
                Tipo = @TipoCall,
                currentStatus = @currentStatus,
                callID = @call_id
            WHERE USER_ID = @User_id
        END
    END
END --- END Insert ccLogAgentesDia @isLogout = 0 AND @TipoStatusAge_id = 6 -----
ELSE 
BEGIN --- BEGIN ELSE DIFF -----
    INSERT ccLogAgentesDia (
        User_id,
        TipoStatusAge_id,
        tStatus,
        fecha,
        IdCampEsp,
        Tipo,
        currentStatus,
        callID
        )
    VALUES (
        @User_id,
        @TipoStatusAge_id,
        @tStatus,
        @Fecha4,
        @Camp,
        @TipoCall,
        @currentStatus,
        @call_id
        )

    IF NOT EXISTS (
            SELECT *
            FROM [ccLogAgentesDiaLast] with(nolock)
            WHERE User_id = @User_id
            )
    BEGIN
        INSERT [ccLogAgentesDiaLast] (
            User_id,
            TipoStatusAge_id,
            tStatus,
            fecha,
            IdCampEsp,
            Tipo,
            currentStatus,
            callID
            )
        VALUES (
            @User_id,
            @TipoStatusAge_id,
            @tStatus,
            @Fecha4,
            @Camp,
            @TipoCall,
            @currentStatus,
            @call_id
            )
    END
    ELSE
    BEGIN
        UPDATE [ccLogAgentesDiaLast] WITH (ROWLOCK)
        SET TipoStatusAge_id = @TipoStatusAge_id,
            tStatus = @tStatus,
            fecha = @Fecha4,
            IdCampEsp = @Camp,
            Tipo = @TipoCall,
            currentStatus = @currentStatus,
            callID = @call_id
        WHERE USER_ID = @User_id
    END
END --- END ELSE DIFF -----


IF (@TipoStatusAge_id = 2)
BEGIN  -- 2 = No Disponible
    INSERT ccLogAgentesNotReady (
        User_id,
        TipoNotReady_id,
        tStatus,
        fecha,
        IdCampEsp,
        Tipo
        )
    VALUES (
        @User_id,
        @TipoNotReady,
        @tStatus,
        @Fecha4,
        @Camp,
        @TipoCall
        )

    ---Para Agente RIA: OAYC
    INSERT ccRIALogAgentesNotReady (
        User_id,
        TipoNotReady_id,
        tStatus,
        fecha
        )
    VALUES (
        @User_id,
        @TipoNotReady,
        @tStatus,
        @Fecha4
        )
END


-- Actualiza para reporte de tiempos especiales (Boan)
IF @Camp > 0
BEGIN
    declare @today datetime=convert(date,getdate(),121)
    IF EXISTS (
            SELECT *
            FROM ccLogAgentesDia WITH (
                    INDEX (IX_ccLogAgentesDia_5),
                    NOLOCK
                    )
            WHERE IdCampEsp = 0
                AND user_id = @User_id
            )
    BEGIN
        UPDATE ccLogAgentesDia
        WITH (ROWLOCK)

        SET IdCampEsp = @Camp,
            Tipo = @TipoCall
        WHERE fecha>@today and
         IdCampEsp = 0
            AND user_id = @User_id
    END

    IF EXISTS (
            SELECT *
            FROM ccLogAgentesNotReady WITH (
                    INDEX (IX_ccLogAgentesNotReady_4),
                    NOLOCK
                    )
            WHERE IdCampEsp = 0
                AND user_id = @User_id
            )
    BEGIN
        UPDATE ccLogAgentesNotReady
        WITH (ROWLOCK)

        SET IdCampEsp = @Camp,
            Tipo = @TipoCall
        WHERE fecha>@today and
        IdCampEsp = 0
            AND user_id = @User_id
    END
END


IF (
        @TipoStatusAge_id = 34
        AND @call_id > 0
        ) -- Dialogo WhatsApp
BEGIN
    IF @TipoCall = 0
    BEGIN
        UPDATE ccWhatsAppConversations
        SET tChatting = (tChatting + @tStatus)
        WHERE conversationId = @call_id;

        SET @Camp = (
                SELECT inboundId
                FROM ccWhatsAppConversations
                WHERE conversationId = @call_id
                );

        EXEC ccsp_WhatsAppInformation @Option = 2,
            @InboundId = @Camp
    END
    ELSE
    BEGIN
        UPDATE ccWhatsAppConversationsOut
        SET tChatting = (tChatting + @tStatus)
        WHERE conversationId = @call_id;

        SET @Camp = (
                SELECT camId
                FROM ccWhatsAppConversationsOut
                WHERE conversationId = @call_id
                );

        EXEC ccsp_WhatsAppInformationOut @Option = 2,
            @camId = @Camp
    END
END
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

        ---------------------------------------- END fix/125.20231211.0.12 -------------------------------------------------

---------------------------------------- BEGIN fix/125.20231211.0.13 -------------------------------------------------
    SET @process = 'Alter SP ccsp_GalateaAdminGetPermissions los permisos AllowCellPhoneCalls,AllowLongDistanceCalls AllowLocalCalls se invierte el bit, valida datos dobles'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetPermissions]
    @user_id varchar(255),
    @Type int
    AS
    set nocount on

    declare @isRoot int;

    if exists (Select Rol_id from ccUsers A join ccUsers_Roles B on A.User_id = B.User_id where A.User_id = @user_id and rol_id = 7) set @isRoot = 1 else set @isRoot = 0;
    print @isRoot

    IF @isRoot = 1
    BEGIN
        Select DISTINCT
        User_id as AgentId, 
        Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
        1-cast(dialMask & 1 as int) as AllowCellPhoneCalls,
        1-cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
        1-cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
        cast( xfermask as int) as AllowTransferCalls, 
        cast(CanChangeStatus as tinyint) CanChangeStatus,
        cast(XferAgents as tinyint) XferAgents,
        ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
        cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
        ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
        ISNULL(agentsPermissions.AllowUnassign, 0) AS AllowUnassign,
        ISNULL(agentsPermissions.AllowSpam, 0 ) AS AllowSpam,
        ISNULL(agentsPermissions.AllowPlayRecordsOnCallHistory, 0) AS AllowPlayRecordsOnCallHistory,
        cast(AllowDeleteRecord as int) as AgentPermissionDelete,
        AllowMarks as AllowMarks,
        ISNULL(allowSelectCamp,0) as AllowSelectCamp
    from 
        ccUsers users
        left join ccRIAAgentsPermissions agentsPermissions on
        users.User_id = agentsPermissions.AgentId
    where 
       tipoUser_id = 1
    return(0)
    END
    ELSE
    BEGIN
        Select  DISTINCT
        A.User_id as AgentId, 
        Login as Username, Nombres + '' '' + isNull(apellidoPaterno,'''') + '' '' + isNull(ApellidoMaterno, '''') as FullName, 
        1-cast(dialMask & 1 as int) as AllowCellPhoneCalls,
        1-cast( (dialMask & 2) /2 as int) as AllowLongDistanceCalls, 
        1-cast((dialMask & 4) / 4 as int) as AllowLocalCalls,
        cast( xfermask as int) as AllowTransferCalls, 
        cast(CanChangeStatus as tinyint) CanChangeStatus,
        cast(XferAgents as tinyint) XferAgents,
        ISNULL(cast(startStopRecording as tinyint), 0) startStopRecording,
        cast(AllowChangeDialingMode as int) as AgentPermissionDailing,
        ISNULL(cast( DialingMode & 1 as int), 0) as DailingMode,
        ISNULL(agentsPermissions.AllowUnassign, 0) AS AllowUnassign,
        ISNULL(agentsPermissions.AllowSpam, 0 ) AS AllowSpam,
        ISNULL(agentsPermissions.AllowPlayRecordsOnCallHistory, 0) AS AllowPlayRecordsOnCallHistory,
        cast(AllowDeleteRecord as int) as AgentPermissionDelete,
        AllowMarks as AllowMarks,
        ISNULL(allowSelectCamp,0) as AllowSelectCamp
    from 
        ccUsers A
    join ccRIAWorkGroupUsers B on 
        A.user_id = B.user_id
    left join ccRIAAgentsPermissions agentsPermissions on
        A.User_id = agentsPermissions.AgentId
    where 
        tipoUser_id = 1 and 
        IDWG in (select IDWG from ccRIAWorkGroupUsers where user_id = @user_id)
    return(0)
    END
set nocount off'
    EXEC(@sql);

    SET @process = 'Alter Sp ccsp_GalateaAdminSetPermissions se voltea los valores AllowCellPhoneCalls,AllowLongDistanceCalls,AllowLocalCalls para guardar '
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminSetPermissions]
@adminId SMALLINT,
@areaId SMALLINT,
@agentsIds VARCHAR(MAX),
@allAgentsSelected BIT, 
@permissionName VARCHAR(255),
@permissionValue INT
AS
SET NOCOUNT ON


declare @changeBitTable table(permissionName VARCHAR(255), valueBit int)

insert into @changeBitTable values(''AllowCellPhoneCalls'',1)
insert into @changeBitTable values(''startStopRecording'',1)
insert into @changeBitTable values(''XferManual'',1)
insert into @changeBitTable values(''AllowTransferCalls'',1)
insert into @changeBitTable values(''AgentPermissionDailing'',1)
insert into @changeBitTable values(''DailingMode'',1)
insert into @changeBitTable values(''AgentPermissionDelete'',1)
insert into @changeBitTable values(''AllowSelectCamp'',1)

insert into @changeBitTable values(''AllowLongDistanceCalls'',2)
insert into @changeBitTable values(''XferExt'',2)

insert into @changeBitTable values(''AllowLocalCalls'',4)
insert into @changeBitTable values(''XferCamps'',4)

insert into @changeBitTable values(''XferAgents'',8)

DECLARE @changeBit INT

set @changeBit=0

select @changeBit=valueBit from @changeBitTable where permissionName=@permissionName

--print(@changeBit)
IF @agentsIds IS NOT NULL
BEGIN
    DECLARE @AgentIdsTemp TABLE (AgentId INT, Status BIT)
    INSERT INTO @AgentIdsTemp SELECT VALUE, 0 FROM dbo.fn_RIASplitDelimited(@agentsIds,'','')

    IF @permissionName = ''AllowUnassign'' 
    BEGIN                       
        UPDATE permissions SET permissions.AllowUnassign = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
        SELECT agentIds.AgentId , @permissionValue, 0, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END
    else IF @permissionName = ''AllowSpam''
    BEGIN 
        UPDATE permissions SET permissions.AllowSpam = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowSpam, AllowUnassign, AllowPlayRecordsOnCallHistory)
        SELECT agentIds.AgentId , @permissionValue, 0, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END

else IF @permissionName = ''AllowPlayRecordsOnCallHistory''
    BEGIN 
        UPDATE permissions SET permissions.AllowPlayRecordsOnCallHistory = @permissionValue FROM @AgentIdsTemp agentIds
        INNER JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId

        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowPlayRecordsOnCallHistory, AllowSpam, AllowUnassign)
        SELECT agentIds.AgentId , @permissionValue, 0, 0 FROM @AgentIdsTemp agentIds
        LEFT JOIN ccRIAAgentsPermissions permissions ON agentIds.AgentId = permissions.AgentId
        WHERE permissions.AgentId IS NULL
    END
else begin
    set @permissionValue= CASE
        WHEN @permissionName in(''AllowCellPhoneCalls'',''AllowLongDistanceCalls'',''AllowLocalCalls'')
        THEN  case when @permissionValue=1 then 0 else 1 end
        else @permissionValue end   
    
    UPDATE
        ccUsers
    SET DialMask =
        CASE
        WHEN @permissionName = ''AllowCellPhoneCalls''
        OR @permissionName = ''AllowLongDistanceCalls''
        OR @permissionName = ''AllowLocalCalls''
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (DialMask & @changeBit) <> @changeBit
                THEN DialMask ^ @changeBit
                ELSE DialMask
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (DialMask & @changeBit) = @changeBit
                THEN DialMask ^ @changeBit
                ELSE DialMask
                END
            END 
        ELSE DialMask
        END,
                        
        XferMask =
        CASE
        WHEN @permissionName = ''AllowTransferCalls''
        THEN
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (XferMask & @changeBit) <> @changeBit
                THEN XferMask ^ @changeBit
                ELSE XferMask
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (XferMask & @changeBit) = @changeBit
                THEN XferMask ^ @changeBit
                ELSE XferMask
                END
            END
        ELSE XferMask
        END,

        XferAgents =
        CASE
        WHEN @permissionName = ''XferAgents''
        OR @permissionName = ''XferCamps'' 
        OR @permissionName = ''XferExt'' 
        OR @permissionName = ''XferManual'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (XferAgents & @changeBit) <> @changeBit
                THEN XferAgents ^ @changeBit
                ELSE XferAgents
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (XferAgents & @changeBit) = @changeBit
                THEN XferAgents ^ @changeBit
                ELSE XferAgents
                END
            END
        ELSE XferAgents
        END,

        startStopRecording =
        CASE
        WHEN @permissionName = ''startStopRecording'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE startStopRecording
        END,

        DialingMode = 
        CASE
        WHEN @permissionName = ''DailingMode'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN
                CASE
                WHEN (DialingMode & @changeBit) <> @changeBit
                THEN DialingMode ^ @changeBit
                ELSE DialingMode
                END
            WHEN @permissionValue = 0
            THEN
                CASE
                WHEN (DialingMode & @changeBit) = @changeBit
                THEN DialingMode ^ @changeBit
                ELSE DialingMode
                END
            END 
        ELSE DialingMode
        END,
        AllowChangeDialingMode = 
        CASE
        WHEN @permissionName = ''AgentPermissionDailing'' 
        THEN 
            CASE
            WHEN @permissionValue = 3
            THEN 1
            WHEN @permissionValue = 2
            THEN 0
            END
        ELSE AllowChangeDialingMode
        END,
        AllowDeleteRecord= 
        CASE
        WHEN @permissionName = ''AgentPermissionDelete'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE AllowDeleteRecord
        END,
        AllowMarks= 
        CASE
        WHEN @permissionName = ''AllowMarks'' 
        THEN 
            CASE
            WHEN @permissionValue = 1 THEN 1
            WHEN @permissionValue = 0 THEN 0
            END
        ELSE AllowMarks
        END,
        allowselectcamp=
        CASE
        WHEN @permissionName = ''AllowSelectCamp'' 
        THEN 
            CASE
            WHEN @permissionValue = 1
            THEN 1
            WHEN @permissionValue = 0
            THEN 0
            END
        ELSE allowselectcamp
        END
    WHERE User_id IN (SELECT AgentId FROM @AgentIdsTemp)
    end
                
    DECLARE @Login VARCHAR(20) = (SELECT Login FROM ccUsers WHERE User_id = @adminId)
    DECLARE @AreaName VARCHAR(50) = (SELECT AreaName FROM ccRIACat_Areas WHERE IDArea = @areaId)
    DECLARE @OperationType TINYINT = (SELECT CASE WHEN @permissionValue = 1 THEN 33 ELSE 35 END)
    DECLARE @Language TINYINT = (SELECT valor FROM ccSettings WHERE setting_id = 27)
    DECLARE @Tag varchar(100) = (SELECT PermissionTag FROM ccRIAAgentsPermissionsTags WHERE PermissionName = @permissionName)        
    DECLARE @Value VARCHAR(250) = (SELECT permissions.Value 
                                    FROM  dbo.fn_RIASplitDelimited(@Tag,''|'') permissions
                                    WHERE permissions.Id = @Language + 1)

    DECLARE @AgentId INT = 0
    DECLARE @AgentName VARCHAR(20) = ''''

    set @Value = isnull(@Value,@permissionName)

    IF @allAgentsSelected = 0
    BEGIN
        WHILE EXISTS(SELECT * FROM @AgentIdsTemp WHERE Status = 0)
        BEGIN 
            SELECT TOP 1 @AgentId = AgentId FROM @AgentIdsTemp WHERE Status = 0
            SET @AgentName = (SELECT Login FROM ccUsers WHERE User_id = @AgentId)
                    
            EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
            @login = @Login, @moduleId = 4, @value = @Value , @target = @AgentName
                        
            UPDATE @AgentIdsTemp SET Status = 1 WHERE AgentId = @AgentId
        END
    END
    ELSE
    BEGIN
        SET @AgentName = (SELECT AllAgentsTag FROM ccRIAUserPermissionsStatusTags WHERE Language = @Language)
                    
        EXEC ccsp_RIA_ABCLog @option = 2, @areaName = @AreaName, @operationType = @OperationType, 
        @login = @Login, @moduleId = 4, @value = @Value , @target = @AgentName
                        
        UPDATE @AgentIdsTemp SET Status = 1
    END


END

SET NOCOUNT OFF
    '
    EXEC(@sql);

---------------------------------------- BEGIN fix/125.20231211.0.12 -------------------------------------------------
    SET @process = 'Alter SP ccsp_RIAOUTInsertNewJOBS_WT_Camp se quita with index para mejorar el procesamiento tome el plan de ejecuccion'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAOUTInsertNewJOBS_WT_Camp] @camp_id AS INT, @reciclar AS INT = 1, @top AS INT = 3000
AS
SET NOCOUNT ON

DECLARE @prioridad VARCHAR(8)
DECLARE @batchsizeIni AS INT
DECLARE @batchsizeFin AS INT
DECLARE @rango AS DECIMAL
DECLARE @rowstoInsert AS INT
DECLARE @campType AS INT
DECLARE @recordsQuantitySetting VARCHAR(8)
DECLARE @settingValueP1 VARCHAR(25)

SET @rowstoInsert = 0
SET @batchsizeIni = 0
SET @batchsizeFin = 0
SET @rango = 0.00

IF EXISTS(SELECT * FROM sys.views WHERE NAME = ''VIEW_SETTINGS'') BEGIN
    SELECT @recordsQuantitySetting = [valor] FROM VIEW_SETTINGS WHERE setting_id = 257;
    IF(@recordsQuantitySetting IS NOT NULL AND @recordsQuantitySetting <> '''') BEGIN
        SELECT @settingValueP1 = SUBSTRING(@recordsQuantitySetting, CHARINDEX(''|'', @recordsQuantitySetting)+1, LEN(@recordsQuantitySetting)),
                @top = (SUBSTRING(@settingValueP1, 1, CHARINDEX(''|'', @settingValueP1)-1));
    END ELSE SET @top = 3000
END ELSE SET @top = 3000

SELECT @prioridad = isnull(Prioridad, ''12345NNN'')
FROM ccCampsPrioridadTel WITH (NOLOCK)
WHERE cam_id = @camp_id

SELECT @campType = cc.CampType FROM dbo.ccCamps AS cc WHERE cc.cam_id = @camp_id;

DELETE ccUploadTemporal
WHERE cam_id = @camp_id

IF(@campType = 7)
BEGIN
        CREATE TABLE #tempsmsOutSource (Id INT PRIMARY KEY identity, smsout_id INT, cam_id INT, sms_phoneNumber VARCHAR(19), sms_status TINYINT, sms_dateDial DATETIME, cal_keyw VARCHAR(40), iTimeZone INT, iTimeZone_summer INT, iTimeZone2 INT, iTimeZone_summer2 INT, iTimeZone3 INT, iTimeZone_summer3 INT, iTimeZone4 INT, iTimeZone_summer4 INT, iTimeZone5 INT, iTimeZone_summer5 INT, list_id INT)

        CREATE TABLE #smsoutIdSource (smsout_id INT NOT NULL PRIMARY KEY)

        CREATE TABLE #smsoutIdSource2 (smsout_id INT NOT NULL PRIMARY KEY)

        INSERT INTO #smsoutIdSource
        SELECT top(@top) sos.smsout_id
        FROM dbo.smsOutSource AS sos  WITH (INDEX (IX_smsOutSource_2), NOLOCK)
        inner join dbo.smsWorkingTable AS swt WITH (INDEX (IX_smsWorkingTable_2), NOLOCK) 
        on sos.callkey = swt.cal_keyw AND sos.cam_id = swt.cam_id 
        WHERE sos.cam_id = @camp_id and sos.sms_status IN (0, 7) AND swt.sms_status <= 2

        UNION

        SELECT top(@top) swt2.smsout_id
        FROM dbo.smsOutSource AS sos2 WITH (INDEX (IX_smsOutSource_2), NOLOCK)
        inner join dbo.smsWorkingTable AS swt2 (NOLOCK)on sos2.smsout_id = swt2.smsout_id 
        WHERE sos2.cam_id = @camp_id AND (sos2.sms_status < 2 OR sos2.sms_status = 7)

        INSERT INTO #smsoutIdSource2
        SELECT top(@top) sos.smsout_id
        FROM dbo.smsOutSource AS sos WITH (INDEX (IX_smsOutSource_1), NOLOCK)
        WHERE sos.sms_status IN (0, 1, 7) AND cam_id = @camp_id

        INSERT #tempsmsOutSource(smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, cal_keyw, iTimeZone, 
        iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4,
            iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id)
        SELECT TOP(@top) smsout_id, cam_id, RTRIM(LEFT(LTRIM(sms_phoneNumber + ''        '' + sms_phoneNumber2 + ''         '' 
        + sms_phoneNumber3 + ''         '' + sms_phoneNumber4 + ''         '' + sms_phoneNumber5 + ''         ''), 13)) AS sms_phoneNumber,
            CASE sms_status WHEN 7 THEN 1 ELSE sms_status END sms_status, sms_dateDial, callkey, 
            CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone ELSE NULL END iTimeZone,
            CASE WHEN LEN(sms_phoneNumber) > 0 THEN iTimeZone_summer ELSE NULL END iTimeZone_summer, 
            CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone2 ELSE NULL END iTimeZone2,
            CASE WHEN LEN(sms_phoneNumber2) > 0 THEN iTimeZone_summer2 ELSE NULL END iTimeZone_summer2, 
            CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone3 ELSE NULL END iTimeZone3, 
            CASE WHEN LEN(sms_phoneNumber3) > 0 THEN iTimeZone_summer3 ELSE NULL END iTimeZone_summer3,
            CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone4 ELSE NULL END iTimeZone4, 
            CASE WHEN LEN(sms_phoneNumber4) > 0 THEN iTimeZone_summer4 ELSE NULL END iTimeZone_summer4, 
            CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone5 ELSE NULL END iTimeZone5, 
            CASE WHEN LEN(sms_phoneNumber5) > 0 THEN iTimeZone_summer5 ELSE 
                    NULL END iTimeZone_summer5, list_id
        FROM dbo.smsOutSource  WITH (INDEX (IX_smsOutSource_1), NOLOCK)
        WHERE cam_id = @camp_id AND (sms_status < 2 OR sms_status = 7) 

        SELECT @rowstoInsert = COUNT(*) FROM #tempsmsOutSource AS tos;

            
        IF EXISTS(SELECT * FROM #tempsmsOutSource)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempsmsOutSource  WITH (NOLOCK)

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                -- Nuevos Jobs
                INSERT INTO dbo.smsWorkingTable
                WITH (TABLOCKX) (smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, attemps, user_id,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id)
                SELECT smsout_id, cam_id, sms_phoneNumber, sms_status, sms_dateDial, 0, 0 ,cal_keyw, iTimeZone, iTimeZone_summer, iTimeZone2, iTimeZone_summer2, iTimeZone3, iTimeZone_summer3, iTimeZone4, iTimeZone_summer4, iTimeZone5, iTimeZone_summer5, list_id
                FROM #tempsmsOutSource 
                WHERE id > @batchsizeIni AND id <= @batchsizeFin

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE dbo.smsOutSource
            SET sms_status = 2
            FROM dbo.smsOutSource AS sos WITH (NOLOCK), #smsoutIdSource2  cis3 WITH (NOLOCK)
            WHERE sos.smsout_id = cis3.smsout_id
        END

        DROP TABLE #smsoutIdSource

        DROP TABLE #smsoutIdSource2

        DROP TABLE #tempsmsOutSource
END
ELSE
BEGIN
        CREATE TABLE #tempCallsOutSource (Id INT PRIMARY KEY identity, callout_id INT, cam_id INT, cal_telefono VARCHAR(19), cal_status TINYINT, cal_fechaDial DATETIME, cal_keyw VARCHAR(40), iZonaHoraria INT, iZonaHoraria_verano INT, iZonaHoraria2 INT, iZonaHoraria_verano2 INT, iZonaHoraria3 INT, iZonaHoraria_verano3 INT, iZonaHoraria4 INT, iZonaHoraria_verano4 INT, iZonaHoraria5 INT, iZonaHoraria_verano5 INT, list_id INT, new_status int)

        INSERT INTO #tempCallsOutSource (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, 
        iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4,
            iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id, new_status)
        SELECT TOP(@top) cs.callout_id, cs.cam_id, CASE WHEN ISNULL(recycleType, 1) = 0 THEN 
        CASE 
            WHEN recyclePhone = 1 THEN cs.cal_telefono
            WHEN recyclePhone = 2 THEN cal_telefono2
            WHEN recyclePhone = 3 THEN cal_telefono3
            WHEN recyclePhone = 4 THEN cal_telefono4
            else cal_telefono5
        END
        ELSE rtrim(left(ltrim(cs.cal_telefono + ''        '' + cal_telefono2 + ''         '' 
            + cal_telefono3 + ''         '' + cal_telefono4 + ''         '' + cal_telefono5 + ''         ''), 13)) 
        END AS cal_telefono,
            CASE cs.cal_status WHEN 7 THEN 1 ELSE cs.cal_status END cal_status, cs.cal_fechaDial, cal_key, 
            CASE WHEN LEN(cs.cal_telefono) > 0 THEN cs.iZonaHoraria ELSE NULL END iZonaHoraria,
            CASE WHEN LEN(cs.cal_telefono) > 0 THEN cs.iZonaHoraria_verano ELSE NULL END iZonaHoraria_verano, 
            CASE WHEN LEN(cal_telefono2) > 0 THEN cs.iZonaHoraria2 ELSE NULL END iZonaHoraria2,
            CASE WHEN LEN(cal_telefono2) > 0 THEN cs.iZonaHoraria_verano2 ELSE NULL END iZonaHoraria_verano2, 
            CASE WHEN LEN(cal_telefono3) > 0 THEN cs.iZonaHoraria3 ELSE NULL END iZonaHoraria3, 
            CASE WHEN LEN(cal_telefono3) > 0 THEN cs.iZonaHoraria_verano3 ELSE NULL END iZonaHoraria_verano3,
            CASE WHEN LEN(cal_telefono4) > 0 THEN cs.iZonaHoraria4 ELSE NULL END iZonaHoraria4, 
            CASE WHEN LEN(cal_telefono4) > 0 THEN cs.iZonaHoraria_verano4 ELSE NULL END iZonaHoraria_verano4, 
            CASE WHEN LEN(cal_telefono5) > 0 THEN cs.iZonaHoraria5 ELSE NULL END iZonaHoraria5, 
            CASE WHEN LEN(cal_telefono5) > 0 THEN cs.iZonaHoraria_verano5 ELSE 
                    NULL END iZonaHoraria_verano5, cs.list_id,
        case when wt.callout_id is not null then 4 else cs.cal_status end new_status
        FROM ccoCallsOutSource cs WITH ( NOLOCK)
        LEFT JOIN ccoWorkingTable wt WITH ( NOLOCK) 
        on cs.callout_id = wt.callout_id
        WHERE cs.cam_id = @camp_id and cs.cal_status IN (0,1,7)

        IF exists(SELECT * FROM #tempCallsOutSource where new_status=4) 
        BEGIN
            UPDATE ccoCallBacks
            SET [status] = 6, schedulerStatus = 1
            WHERE callout_id IN (
                    SELECT callout_id
                    FROM #tempCallsOutSource where new_status=4)

            UPDATE ccoCallsOutSource
            SET cal_Status = 4
            WHERE callout_id IN (
                    SELECT callout_id
                    FROM #tempCallsOutSource where new_status=4)
        END

        SELECT @rowstoInsert = COUNT(*) FROM #tempCallsOutSource where new_status != 4

        IF EXISTS(SELECT * FROM #tempCallsOutSource where new_status != 4)
        BEGIN
            SELECT @rango = ISNULL(CEILING(CAST((MAX(Id) * 1.00) / 3 AS DECIMAL(10, 2))), 0.00)
            FROM #tempCallsOutSource WITH (NOLOCK) where new_status != 4

            SET @batchsizeFin = @batchsizeFin + @rango

            WHILE 1 = 1
            BEGIN
                -- Nuevos Jobs
                INSERT INTO ccoWorkingTable
                WITH (TABLOCKX) (callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id)
                SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial, cal_keyw, iZonaHoraria, iZonaHoraria_verano, iZonaHoraria2, iZonaHoraria_verano2, iZonaHoraria3, iZonaHoraria_verano3, iZonaHoraria4, iZonaHoraria_verano4, iZonaHoraria5, iZonaHoraria_verano5, list_id
                FROM #tempCallsOutSource 
                WHERE new_status != 4 AND id > @batchsizeIni AND id <= @batchsizeFin

                IF @batchsizeFin > @rowstoInsert
                    BREAK
                ELSE
                BEGIN
                    SET @batchsizeIni = @batchsizeIni + @rango
                    SET @batchsizeFin = @batchsizeFin + @rango
                END
            END

            UPDATE ccoCallsOutSource
            SET cal_status = 2, nOcupado = 0, nNoContesta = 0, nFax = 0, nContestadora = 0, nShortCall = 0, nOtro = 0
            WHERE callout_id in (
                    SELECT callout_id
                    FROM #tempCallsOutSource)
        END

        DROP TABLE #tempCallsOutSource
END

UPDATE ccCampsNvosCB
SET dateUpdate = NULL
WHERE id = @camp_id

SET NOCOUNT OFF'
    EXEC(@sql);

     
----------------------------------------------------- START TT9314 Uriel Cabrera  ----------------------------------------------------------------
    
SET @process = 'TT9314 Se modifica el procedimiento ccsp_GalateaAdminLogin para prevenir el areaId del administrador con valor 0, tomando ahora la primera área activa'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminLogin] @Login       VARCHAR(40) = '''', 
                                               @Password    VARCHAR(40) = '''', 
                                               @PasswordLwC VARCHAR(40) = NULL, 
                                               @IPAddress   VARCHAR(20) = '''', 
                                               @adminId     INT         = 0
AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @LoginOK BIT= 0, @PswdOK BIT= 0, @User_id SMALLINT, @Nombre VARCHAR(100), @ADMServer VARCHAR(300), @AreaId SMALLINT, @ViewAvrs INT, @changeRecDisposition INT, @PasswordExpired INT= 0, @UsernameMatch BIT= 1, @UserBlocked BIT= 0, @LastPasswordChange DATETIME, @Ext VARCHAR(80), @ViewAgents BIT= 0, @Theme SMALLINT= 0, @UserBlockedByMaxAttempts BIT = 0;
        CREATE TABLE #temp
        (LoginOK              INT, 
         PswdOK               INT, 
         User_id              SMALLINT, 
         Nombre               VARCHAR(100), 
         ADMServer            VARCHAR(300), 
         AreaId               SMALLINT, 
         ViewAvrs             INT, 
         changeRecDisposition INT, 
         LastPasswordchange   INT
        );
                
        INSERT INTO #temp
        EXEC ccsp_RIAADMChecaLogin 
             @Login, 
             @Password, 
             @PasswordLwC, 
             @adminId,
                         1;
        SELECT @LoginOK = LoginOK, @PswdOK = PswdOK, @Nombre = Nombre, @ADMServer = ADMServer, @AreaId = AreaId, @ViewAvrs = ViewAvrs, @changeRecDisposition = changeRecDisposition, @PasswordExpired = LastPasswordchange
        FROM #temp;

                if @AreaId is null or @AreaId=0
                select top 1 @AreaId= IDArea from ccRIACat_Areas where StatusArea=1

        IF @LoginOK = 1
            BEGIN
                        IF (SELECT isBlocked
                        FROM ccUsers
                        WHERE User_id = @User_id) = 1
                        BEGIN
                        SET @UserBlockedByMaxAttempts = 1;
                        END
                        ELSE
                        BEGIN
                        
                                IF ((SELECT DATEDIFF(DAY, LastPasswordChange, GETDATE()) FROM ccUsers
                                WHERE User_id = @User_id) > 30 AND @PswdOK = 1)
                                BEGIN
                                SET @PasswordExpired = 1;
                                END
                SELECT @User_id = User_id, @ViewAgents = viewAgents, @Theme = theme
                FROM ccUsers
                WHERE Login = @Login;
                DECLARE @LastLoginAttempt DATETIME, @LoginAttempts INT, @MaxAttemptsAllow INT, @TimeBloqued INT, @TimeFromLastAttempt INT;
                SELECT @LastLoginAttempt = LastLoginAttempt, @LoginAttempts = LoginAttempts, @LastPasswordChange = LastPasswordChange
                FROM ccUsers
                WHERE User_id = @User_id;
                                
                                IF (SELECT valor
                                FROM ccSettings
                                WHERE setting_id = 207) = 1
                                BEGIN
                                        IF (SELECT LoginAttempts
                                        FROM ccUsers
                                        WHERE User_id = @User_id) > 3
                                        BEGIN
                                                SET @UserBlockedByMaxAttempts = 1;
                                                UPDATE ccUsers SET isBlocked = 1 WHERE User_id = @User_id;
                                        END
                                END
                                ELSE
                                BEGIN
                                
                SELECT @MaxAttemptsAllow = valor
                FROM ccSettings
                WHERE setting_id = 198;
                SELECT @TimeBloqued = valor
                FROM ccSettings
                WHERE setting_id = 197;
                SELECT @TimeFromLastAttempt = DATEDIFF(MINUTE, @LastLoginAttempt, GETDATE());
                IF @LoginAttempts > @MaxAttemptsAllow
                    BEGIN
                        SET @LoginAttempts = 0;
                        UPDATE ccUsers
                          SET 
                              LoginAttempts = 0, 
                              LastLoginAttempt = GETDATE()
                        WHERE User_id = @User_id;
                END;
                IF(@LoginAttempts >= @MaxAttemptsAllow
                   AND @TimeFromLastAttempt < @TimeBloqued)
                    BEGIN
                        SET @UserBlocked = 1;
                END;

                                END
                --Checks Username match case sensitive    
                IF CAST(@Login AS VARBINARY(200)) <>
                (
                    SELECT CAST(LOGIN AS VARBINARY(200))
                    FROM ccUsers
                    WHERE User_id = @User_id
                )
                    BEGIN
                        SET @UsernameMatch = 0;
                END;

                --Increments attemps if error
                IF (@UserBlocked = 0
                   AND (@UsernameMatch = 0
                        OR @PswdOK = 0)) AND @UserBlockedByMaxAttempts = 0
                    BEGIN
                        UPDATE ccUsers
                          SET 
                              LoginAttempts = @LoginAttempts + 1, 
                              LastLoginAttempt = GETDATE(), 
                              onLine = 0
                        WHERE User_id = @User_id;
                END;

                --Sets to default to try another attempt
                DECLARE @ExpirationTime INT;
                SELECT @ExpirationTime = valor
                FROM ccSettings
                WHERE setting_id = 29;
                SELECT @PasswordExpired = (CASE
                                               WHEN DATEDIFF(DAY, LastPasswordChange, GETDATE()) > @ExpirationTime
                                                    AND @ExpirationTime > 0 THEN 1 ELSE 0
                                           END)
                FROM ccUsers
                                WHERE User_id = @User_id;
                IF @UserBlocked = 0
                   AND @UsernameMatch = 1
                   AND @PswdOK = 1
                   AND @PasswordExpired = 0
                    BEGIN
                        UPDATE ccUsers
                          SET 
                              LoginAttempts = 0, 
                              LastLoginAttempt = GETDATE(), 
                              onLine = 1
                        WHERE User_id = @User_id;
                END;
                SELECT @Ext = dbo.fn_Ext_X_ip(@IPAddress);
                DECLARE @WorkGroup VARCHAR(MAX);
                SELECT @WorkGroup = COALESCE(@WorkGroup + ''|'' + CAST(IDWG AS VARCHAR(MAX)), CAST(IDWG AS VARCHAR(MAX)))
                FROM ccRIAWorkGroupUsers
                WHERE User_id = @User_id;
                DECLARE @Roles VARCHAR(MAX);
                SELECT @Roles = STUFF(
                (
                    SELECT '', '' + CAST(ur.Rol_id AS VARCHAR)
                    FROM ccUsers_Roles ur
                    WHERE User_id = @User_id FOR XML PATH('''')
                ), 1, 2, '''');
        END;
                END;
                
                IF (SELECT valor
                FROM ccSettings
                WHERE setting_id = 207) = 1
                BEGIN
                        IF (SELECT LoginAttempts
                        FROM ccUsers
                        WHERE User_id = @User_id) > 3
                        BEGIN
                                SET @UserBlockedByMaxAttempts = 1;
                                UPDATE ccUsers SET isBlocked = 1 WHERE User_id = @User_id;
                        END
                        IF ((SELECT DATEDIFF(DAY, LastPasswordChange, GETDATE()) FROM ccUsers
                        WHERE User_id = @User_id) > 30 AND @PswdOK = 1)
                        BEGIN
                        SET @PasswordExpired = 1;
                        END
                END
        SELECT @LoginOK UserExists, @UserBlocked UserBlocked, @UsernameMatch UsernameMatch, @PswdOK PasswordMatch, CAST(@PasswordExpired AS BIT) PasswordExpired, @User_id UserID, @Nombre Name, @ADMServer ADMServer, @AreaId AreaId, @ViewAvrs ViewAvrs, @changeRecDisposition ChangeRecDisposition, @Ext Ext, ISNULL(@ViewAgents, 0) ViewAgents, ISNULL(@WorkGroup, 0) WorkGroup, ISNULL(@Theme, 0) Theme, ISNULL(@Roles, 0) Roles, @UserBlockedByMaxAttempts UserBlockedByMaxAttempts;
    END;'
    EXEC(@sql); 

---------------------------------------- END fix/125.20231211.0.12 -------------------------------------------------        

---------------------------------------- Begin fix/125.20231211.0.9 fix/125.20231211.0.14 - -------------------------------------------------        

SET @process = 'Hotfix SMS - Adding indexes'
        SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_smsccoLogDial_2'' and object_id = OBJECT_ID(N''smsccoLogDial''))
    begin
        CREATE INDEX IX_smsccoLogDial_2 ON smsccoLogDial(smsDate,statusSystemsId);
    end'
        EXEC(@sql);

SET @process = 'Hotfix SMS - Create new table for messages without a status update'
        SET @sql = 'IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = ''UnchangedStatusSmsMessages'')
    BEGIN
        CREATE TABLE UnchangedStatusSmsMessages (
            SystemApiId VARCHAR(100) NOT NULL,
            StatusSystemsId INT NOT NULL
        );
    END;'
        EXEC(@sql);




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

    set @process = 'Raccon -- Alter SP ccsp_DLRGetDialInfo se modifica para agergar  datos a tabla temporal para no repetir consulta @tmpccoCallsOutSource
Landus se agrega with(nolock) ccoCallPriorityOrder'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRGetDialInfo]
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
    ,case when cpo.priorityCall is not null then cpo.priorityCall else ISNULL(cpt.Prioridad,''12345NNN'') end dial_tels
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
    left join ccoCallPriorityOrder cpo with(nolock) on cpo.callout_id = c.callout_id
    left join ccCampsPrioridadTel cpt on cpt.cam_id = @cam_id
    left join (SELECT * FROM (SELECT pid,ani FROM @Anis)a PIVOT(MAX(ani) FOR pid IN(p1,p2,p3,p4,p5)) AS pt) anis on 0=0
    WHERE C.callout_id = @callout_id
    return
end 
set nocount off
    '
EXEC(@sql);

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
set @daysAdd=dateadd(dd,@rangeDays,getdate())

select @rangeDays=valor from ccSettings where setting_id=35

-- Returns days with callbacks made by an agent
SELECT cal_fusercallback Day
FROM ccoCallBacks cb with(nolock)
WHERE user_id = @userID
and cal_fusercallback between @currentDay and @daysAdd
order by Day'
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

    set @process = 'Alter Sp ccsp_RIA_ABCACDGroups if @option = 1 y 5 -- select acd para que se pueda asignar desde RIA campañas encuesta'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIA_ABCACDGroups]
@option smallint,
@userid int,
@descripcion varchar(40),
@inbound_id varchar(1000),
@idarea smallint = null,
@frame tinyint,
@Prefijo varchar(40) = null,
@MediaType int = 0,
@chatDomain varchar(500) = null
AS
SET NOCOUNT ON

declare @new_inbound_id smallint, @graph_id smallint

if @option = 0 -- all acd
    begin
        select acd.inbound_id, acd.descripcion, isnull(acd.idarea,0) as idarea,
    isnull(areas.areaname,'''') as areaname
        from ccinbound as acd with(nolock)
        left join dbo.ccriacat_areas as areas with(nolock) on acd.idarea = areas.idarea
        return(0)
    end

if @option = 1 -- select acd
    begin
        select a1.inbound_id, a1.descripcion, a3.frame, a1.showcalifwnd, a1.starttimeronhangup, isnull(a1.idarea,0)
        ,case when ext.SurveyCamId is not null or ext.SurveyCamId >0 then isnull(ext.SurveyCamId,0) else isnull(a1.cam_id,0) end cam_id,
        prefijo as Prefijo
        from ccinbound a1 
        inner join ccriainboundgraph a2 on (a1.inbound_id=a2.inbound_id)
        inner join ccriagraphics a3 on (a2.graphic_id=a3.graphic_id)
        left join ccInboundExtend  ext on ext.Inbound_id=a1.Inbound_id
        where a3.type_id = 1 and a1.inbound_id = (cast(@inbound_id as int))
        order by descripcion
        return(0)
    end

if @option = 2 -- insert
    begin
                 
    if exists (select descripcion from ccinbound where descripcion = @descripcion and status = 1)
    begin
        select -1   -- ''Nombre en uso''
        return(0)
    end
                    
    if (@MediaType = 1 and @chatDomain <> '''' and @chatDomain is not null)
    begin
        if exists (select 1 from ccInbound where chatDomain = @chatDomain and Status = 1)
        begin
            select -3   -- ''Domain in use''
            return(0)
        end
    end
                    
    if @idarea = 0
        set @idarea = null

    declare @pref int
    select  @pref = valor from ccSettings where setting_id = 201
    if (@pref = 0)
        set @Prefijo = ''''
                    
    DECLARE @tempDesc VARCHAR(40);
    SET @tempDesc = CASE WHEN @MediaType = 5 THEN @descripcion ELSE @descripcion+''Tmp'' END;

    insert into ccinbound (descripcion, starttimeronhangup, idarea, showcalifwnd,prefijo)
    select @tempDesc, 1, @idarea,case when exists(select calif_id from cctipocalif where Calif_Status = 1) then 1 else 0 end, @Prefijo
                    
    if @@rowcount = 1
        select @new_inbound_id = inbound_id from ccinbound where descripcion = @tempDesc and status = 1
    else
    begin
        select -2 -- Error al insertar
        return(0)
    end

    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @new_inbound_id, @userId= @userid

    UPDATE ccInbound SET descripcion = @descripcion, ShowCalifWnd = case when exists(select calif_id from cctipocalif where Calif_Status = 1) then 1 else 0 end
    WHERE Inbound_id = @new_inbound_id

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    Create table #ccInboundTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @new_inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';  
                    
    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        CASE 
            WHEN @MediaType = 5 THEN 40
            WHEN @MediaType = 1 THEN 63
            ELSE 60 END, 
        3, 
        CASE WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                CASE WHEN @MediaType = 5 THEN ''IN_SHOW_DISPOSITIONS_WHATS'' ELSE  CCIT.identifierInfo END
                WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN ''''
        ELSE
            CCIT.identifierInfo
        END,
        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
            CASE 
                WHEN CCIT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'') THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                WHEN CCIT.identifierInfo = ''IN_CALL_EDIT_NAME'' THEN ''''
                ELSE CCIT.dataInfo END
        ELSE '''' END, 
        (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @new_inbound_id)
    FROM #ccInboundTable AS CCIT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @new_inbound_id, @userId = @userid;

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable

    insert into cccalifcamp (calif_id, cam_id, tipo) select calif_id, @new_inbound_id, 0 from cctipocalif where CanReprogram=0 and Calif_Status = 1

    if not exists (select msg_id from ccInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccMsgFiles where msgFile like ''%\Default%''))
    begin
        insert into ccInboundMsgs (msg_id, inbound_id, orden, type, queue)
        select msg_id, @new_inbound_id, 0, cast(substring(msgFile, 19,3) as integer),0 from ccMsgFiles where msgFile like ''%\Default%''
    end

    if not exists (select msg_id from ccRIAChatInboundMsgs where Inbound_id=@new_inbound_id and msg_id in (select msg_id from ccRIAChatMsg where Descripcion like ''%\Default%''))
    begin
        insert into ccRIAChatInboundMsgs (msg_id, inbound_id, orden, type)
        select msg_id, @new_inbound_id, 0, cast(substring(Descripcion, 19,3) as integer) from ccRIAChatMsg where Descripcion like ''%\Default%''
    end

    if not exists(select frame from ccriagraphics where frame = @frame and type_id = 1)
        insert into ccriagraphics (frame,type_id) values (@frame,1)
                    
    select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
                     
    insert into ccriainboundgraph(Inbound_id,graphic_id) values(@new_inbound_id,@graph_id)
    select @new_inbound_id
    return(0) 
    end

if @option = 3 -- update
    begin
        if not exists (select frame from ccriagraphics where frame=@frame and type_id=1)
        insert into ccriagraphics (frame, type_id) values (@frame, 1)

        select @graph_id = graphic_id from ccriagraphics where frame = @frame and type_id = 1
        update ccinbound set descripcion = @descripcion where inbound_id = (cast(@inbound_id as int))
        update ccriainboundgraph set graphic_id = @graph_id where inbound_id = (cast(@inbound_id as int))
        return(0)
    end

if @option = 4 -- delete
    begin
        delete cccalifcamp where cam_id = @inbound_id and tipo = 0
        delete ccinboundhorarios where inbound_id = @inbound_id
        delete ccriainboundgraph where inbound_id = @inbound_id
        delete ccInboundMsgs where inbound_id = @inbound_id
        delete ccRIAChatInboundMsgs where inbound_id = @inbound_id
        delete ccSkills where inbound_id = @inbound_id
        return(0)
    end

if @option = 5 -- asignar campana a ACD
    begin
    if not exists (select inbound_id from ccInbound where inbound_id=@inbound_id) or
        (@descripcion is not null and @descripcion <> '''' and @descripcion <> ''0'' and 
        not exists (select cam_id from ccCamps where cam_id=@descripcion))
        begin
        select -3 -- Campana o ACD invalido
        return(0)
        end
                    
    declare @cam_id int,@oldCamId int

    if @descripcion=0 begin

        set @descripcion = null
        --quitamos calificaciones relacionadas a la campana
        DELETE c FROM ccCalifCamp c
        INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id
        Where c.cam_id=@inbound_id and ci.CanReprogram =1
        --quitamos subcalificaciones relacionadas a la calificacion
        DELETE rel FROM ccCalifCamp c
        INNER JOIN ccTipoCalif ci ON  ci.calif_id=c.calif_id and tipo=0
        inner join cctipoSubCalifRel rel on rel.calif_id=ci.calif_id and rel.tipoSubRel=1
        left join ccTipoCalifSub sb on rel.califsub_id=sb.califsub_id
        Where c.cam_id=@inbound_id and sb.canReprogram=1
                         
            update ccInbound set cam_id = 0 where Inbound_id = @inbound_id       
            update ccInboundExtend set SurveyCamId = 0 where Inbound_id = @inbound_id       
    end
    set @cam_id=@descripcion
    if @cam_id is null set @cam_id=0
                    


    if exists( select * from ccCamps where cam_id=@cam_id and ( 
    (CampType is null or CampType not in(5,7,8) ) and callsBySurvey=0 and ivrScript=0
                    
    )) begin
        update ccInbound set cam_id = @cam_id where Inbound_id = @inbound_id
    end
    else begin
        update ccInboundExtend set SurveyCamId = @cam_id where Inbound_id = @inbound_id
    end
                        
    if @@rowcount=0
        select -4 -- Error al actualizar

    return(0)
    end
set nocount off'
    EXEC(@sql)

    set @process = 'Alter Sp ccsp_RIAUpdateCamConfig cambios se agrega para validar si @callsBySurvey y @ivrScript para poner de tipo encuesta'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
@cam_id smallint,
@cam_descripcion varchar(40) = null,
@cam_tnotas smallint = null,
@cam_ocupado tinyint = null,
@cam_NoInt_ocupado tinyint = null,
@cam_inter_ocupado smallint = null,
@cam_nocontesto tinyint = null,
@cam_NoInt_nocontesto tinyint = null,
@cam_inter_nocontesto smallint = null,
@cam_fax tinyint = null,
@cam_NoInt_fax tinyint = null,
@cam_inter_fax smallint = null,
@cam_ModoManual tinyint= null,
@ANI varchar(15) = null,
@cam_ShowCalifWnd bit = null,
@cam_StartTimerOnHangUp bit = null,
@editableCallKey bit = null,
@cam_tNoContesta tinyint = null,
@cam_intensive_dialing tinyint = null,
@detectAnswerMachine smallint = null, -- defualt 0 | nivel de confianza: 1 rapido, pero no tan exacto | 2 normal | 3 menos rapido, mas exacto
@detectVoiceMail TinyInt = null, -- permitidos 0,1 (bandera para activar)
@compliance TinyInt = null,
@cam_inter_graba smallint = null,
@cam_NoInt_graba tinyint = null,
@progDial smallint = null,
@excCallBack Tinyint = null,
@dialOrder Tinyint = null,
@dialPrefix varchar(10) = null,
@dialPrefixMan varchar(10) = null,
@dialPrefixXfe varchar(10) = null,
@listenManualCall bit = null,
@stopRecording bit = null,
@abandonCallback bit = null,
@autoCB smallint = null,
@id_listAni int = null,
@tDialonWrapUp smallint = null,
@quesize smallint=null,
@DNCScrub int=null,
@callerIdDesc varchar(15)=null,
@timeZoneRule int=null,
@callsBySurvey int=null,
@ivrScript int=null,
@surveyPctg int=null,
@call_record tinyint=null,
@dRestrictPlay bit = null,
@leaveRecMessage bit = null,
@manualCallOnChat bit = null,
@callBackSurveyClient bit = null,
@callBackSurveyAgent bit = null,
@funcEspDtmf int =null,
@sipHdrsCfg varchar(255) = null,
@cam_inter_cancelled smallint = null,
@prefijo varchar(max) = null,
@exitAssisted bit = null,
@previewDiscard bit = null,
@rotativeAlgo tinyint = null,
@timesPreview tinyint = null,
@cam_tPreview smallint = null,
@timesDiscard tinyint = null,
@CampType int = null,
@agentCloseConversationTime SMALLINT = NULL,
@adminCloseConversationTime INT = NULL,
@ConexionInfo VARCHAR(400) = NULL,
@allowFileAttachments BIT = NULL,
@selectRotativeANI int = null,
@messagingOrder bit = null,
@autoStart bit = null,
@recordHold bit = null,
@userId                SMALLINT     = NULL, 
@idArea                SMALLINT     = NULL, 
@isCreating            SMALLINT          = NULL,
@module INT = -1
as
set nocount on
DECLARE @timesDiscardActual int = (SELECT timesDiscard FROM ccCamps WHERE cam_id = @cam_id)
DECLARE @CheckCamp int = (Select case when cam_procesando=0 and progDial=3 then 1 else 0 end from ccCamps where cam_id=@cam_id)
    DECLARE @PrevName VARCHAR(MAX) = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccCamps'', @columnNameId=''cam_id'', @valueId= @cam_id, @userId= @userid

UPDATE ccCamps SET
cam_descripcion = isnull(@cam_descripcion,cam_descripcion),
cam_tnotas = isnull(@cam_tnotas,cam_tnotas),
cam_ocupado = isnull(@cam_ocupado,cam_ocupado),
cam_NoInt_ocupado = isnull(@cam_NoInt_ocupado,cam_NoInt_ocupado),
cam_inter_ocupado = isnull(@cam_inter_ocupado,cam_inter_ocupado),
cam_nocontesto = isnull(@cam_nocontesto,cam_nocontesto),
cam_NoInt_nocontesto = isnull(@cam_NoInt_nocontesto,cam_NoInt_nocontesto),
cam_inter_nocontesto = isnull(@cam_inter_nocontesto,cam_inter_nocontesto),
cam_inter_cancelled = isnull(@cam_inter_cancelled,cam_inter_cancelled),
cam_fax = isnull(@cam_fax,cam_fax),
cam_NoInt_fax = isnull(@cam_NoInt_fax,cam_NoInt_fax),
cam_inter_fax = isnull(@cam_inter_fax, cam_inter_fax),
cam_ModoManual = isnull(@cam_ModoManual, cam_ModoManual),
ANI = isnull(@ANI,ANI),
cam_StartTimerOnHangUp = isnull(@cam_StartTimerOnHangUp,cam_StartTimerOnHangUp),
editableCallKey = isnull(@editableCallKey, editableCallKey),
cam_tNoContesta = isnull(@cam_tNoContesta, cam_tNoContesta),
iTipoDial = isnull(@cam_intensive_dialing, iTipoDial),
detectAnswerMachine = isnull(@detectAnswerMachine, detectAnswerMachine),
detectVoiceMail = isnull(@detectVoiceMail, detectVoiceMail),
compliance = isnull(@compliance, compliance),
cam_inter_graba = isnull(@cam_inter_graba, cam_inter_graba),
cam_NoInt_graba = isnull(@cam_NoInt_graba, cam_NoInt_graba),
cam_graba = isnull(convert(bit, @cam_NoInt_graba), cam_graba),
progDial = isnull(@progDial, progDial),
excCallBack = isnull(@excCallBack,excCallBack),
dialOrder = isnull(@dialOrder, dialOrder),
dialPrefix = isnull(@dialPrefix, dialPrefix),
dialPrefixMan = isnull(@dialPrefixMan, dialPrefixMan),
dialPrefixXfe = isnull(@dialPrefixXfe, dialPrefixXfe),
listenManualCall = isnull(@listenManualCall, listenManualCall),
stopRecording = isnull(@stopRecording, stopRecording),
abandonCallback = isnull(@abandonCallback, abandonCallback),
t_autoCB = isnull(@autoCB,t_autoCB),
id_anilist = isnull(@id_listAni,id_anilist),
tDialonWrapUp = case when @cam_tnotas<@tDialonWrapUp and @cam_tnotas<>-1 then @cam_tnotas else isnull(@tDialonWrapUp,tDialonWrapUp) end,
cam_fDialOnWU = case @tDialonWrapUp when 0 then 0 else 2 end,
cam_maxqueue = isnull(@quesize,cam_maxqueue),
DNCScrub = isnull(@DNCScrub,DNCScrub),
callerIdDesc = isnull(@callerIdDesc,callerIdDesc),
timeZoneRule = isnull(@timeZoneRule,timeZoneRule),
callsBySurvey = isnull(@callsBySurvey,callsBySurvey),
ivrScript = isnull(@ivrScript,ivrScript),
surveyPctg = isnull(@surveyPctg,surveyPctg),
call_record = isnull(@call_record,call_record),
startStopRecording = isnull(@dRestrictPlay, startStopRecording),
leaveRecMessage = isnull(@leaveRecMessage, leaveRecMessage),
manualCallOnChat = isnull(@manualCallOnChat, manualCallOnChat),
callBackSurveyClient = isnull(@callBackSurveyClient, callBackSurveyClient),
callBackSurveyAgent = isnull(@callBackSurveyAgent , callBackSurveyAgent ),
funcEspDtmf =  isnull(@funcEspDtmf , funcEspDtmf ),
sipHdrFormat = isnull(@sipHdrsCfg, sipHdrFormat),
prefijo = isnull(@prefijo, prefijo),
exitAssisted = isnull(@exitAssisted, exitAssisted),
previewDiscard = isnull(@previewDiscard, previewDiscard),
rotativeAlgo = isnull(@rotativeAlgo, rotativeAlgo),
timesPreview = isnull(@timesPreview, timesPreview),
cam_tPreview = isnull(@cam_tPreview,cam_tPreview),
timesDiscard = isnull(@timesDiscard, timesDiscard),
CampType = (CASE  WHEN @CampType is not null THEN @CampType WHEN @progDial = 2 THEN 6 WHEN @progDial IS NOT NULL AND @progDial <> 2 THEN 0 WHEN CampType is not null THEN CampType ELSE 0 END),
selectRotativeANI = isnull(@selectRotativeANI, selectRotativeANI),
messagingOrder = isnull(@messagingorder, messagingOrder),
autoStart = isnull(@autoStart,autoStart),
recordHold = isnull(@recordHold, recordHold)

Where cam_id = @cam_id

if @callsBySurvey is not null and @ivrScript is not null begin
        
    UPDATE ccCamps SET CampType=case when @callsBySurvey=0 and @ivrScript=0 then 0 else 8 end 
    Where cam_id = @cam_id
end
    

        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

        Create table #ccCampsTable 
        (
            columnInfo VARCHAR(255),
            dataInfo VARCHAR(255),
            identifierInfo VARCHAR(255)
        )

        DECLARE @operation SMALLINT = CASE WHEN @isCreating = 1 THEN 
                                                                    CASE 
                                                                        WHEN @Camptype = 6  THEN 44
                                                                        WHEN @Camptype = 5  THEN 46
                                                                        WHEN @Camptype = 4  THEN 48
                                                                        WHEN @Camptype = 7  THEN 50
                                                                        ELSE 42 END
                                                                ELSE 
                                                                    CASE 
                                                                        WHEN @Camptype = 6  THEN 55
                                                                        WHEN @Camptype = 5  THEN 56
                                                                        WHEN @Camptype = 4  THEN 57
                                                                        WHEN @Camptype = 7  THEN 58
                                                                        ELSE 54 END
                                                                END;
        
        IF(@isCreating > 0 AND @module > -1) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#ccCampsTable'';

        IF(@isCreating = 1) DELETE FROM #ccCampsTable WHERE columnInfo IN (''cam_descripcion'');
            
        DELETE FROM #ccCampsTable WHERE columnInfo IN (''startStopRecording'');
        DELETE FROM #ccCampsTable WHERE dataInfo = '''''''';
            
        IF(@CampType = 6) DELETE FROM #ccCampsTable WHERE columnInfo IN (''CampType'', ''cam_fDialOnWU'', ''ProgDial'');
        ELSE IF(@CampType = 5 AND @isCreating = 2) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'', ''cam_descripcion'', ''exitAssisted'');
        ELSE IF(@CampType = 5) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''cam_ModoManual'');
        ELSE IF(@CampType = 7) DELETE FROM #ccCampsTable WHERE columnInfo NOT IN (''messagingOrder'', ''autoStart'', ''rotativeAlgo'', ''id_anilist'', ''cam_descripcion'');
        ELSE DELETE FROM #ccCampsTable WHERE columnInfo IN (''previewDiscard'', ''CampType'', ''cam_fDialOnWU'', ''ProgDial'');

        IF(@idArea IS NULL OR @idArea = -1) SET @idArea = (SELECT [IDArea] FROM ccCamps WHERE cam_id = @cam_id)

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT [AreaName] FROM ccRIACat_Areas  WHERE IDArea = @idArea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            @operation, 
            @module,
            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> ''''
                THEN
                    CASE
                        WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN
                            CASE WHEN @isCreating = 1 THEN '''' ELSE CCCT.identifierInfo END
                        WHEN CCCT.identifierInfo = ''OUT_EXIT_ASSISTED'' THEN 
                            CASE WHEN @CampType = 5 THEN ''OUT_WHATS_EXIT_ASSISTED'' ELSE CCCT.identifierInfo END
                        WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
                            CASE WHEN @Camptype = 5 THEN ''OUT_MANUAL_DIALING_WHATS'' ELSE CCCT.identifierInfo END
                        ELSE
                            CCCT.identifierInfo
                        END
                ELSE
                ''''
                END,
            CASE WHEN CCCT.identifierInfo IS NOT NULL AND CCCT.identifierInfo <> '''' THEN
                CASE 
                    WHEN CCCT.identifierInfo IN (''IN_SHOW_DISPOSITIONS'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                        CASE WHEN CCCT.dataInfo = ''VOICEMAIL'' 
                            THEN ''COMMON_VOICE_MAIL'' 
                            ELSE 
                                CASE WHEN CCCT.dataInfo IS NOT NULL THEN CCCT.dataInfo ELSE ''T&COMMON_NONE'' END 
                            END
                    WHEN CCCT.identifierInfo = ''OUT_DIALING_ORDER'' THEN 
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_DESCENDING'' ELSE ''COMMON_ASCENDING'' END

                    WHEN CCCT.identifierInfo = ''OUT_SMS_MESSAGING_ORDER'' THEN 
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ASCENDING'' ELSE ''COMMON_DESCENDING'' END

                    WHEN CCCT.identifierInfo = ''OUT_ANSWER_MACHINE_DETC'' THEN 
                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_BASIC'' 
                            WHEN CCCT.dataInfo = 1 THEN ''COMMON_LIGHT''
                            WHEN CCCT.dataInfo = 2 THEN ''COMMON_MODERATE''
                            WHEN CCCT.dataInfo = 3 THEN ''COMMON_HIGH''
                            ELSE ''T&COMMON_NONE'' END

                    WHEN CCCT.identifierInfo = ''OUT_ANI_MODE'' THEN 
                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_ANI_LOCAL'' 
                            WHEN CCCT.dataInfo = 1 THEN ''COMMON_ANI_ROTATIVE''
                            WHEN CCCT.dataInfo = 2 THEN ''COMMON_ANI_ROTATIVE_REG''
                            WHEN CCCT.dataInfo = 3 THEN ''COMMON_ANI_ROTATIVE_SMART''
                            ELSE ''T&COMMON_NONE'' END

                    WHEN CCCT.identifierInfo = ''OUT_DIALING_MODE'' THEN 
                        CASE WHEN CCCT.dataInfo = 0 THEN ''COMMON_PREDICTIVE'' 
                            WHEN CCCT.dataInfo = 1 THEN ''COMMON_PROGRESIVE''
                            ELSE ''COMMON_ASSISTED'' END

                    WHEN CCCT.identifierInfo = ''OUT_MANUAL_DIALING'' THEN
                        CASE WHEN  @CampType = 5 THEN 
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                        ELSE
                            CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_VIA_KEYPAD_LOG''
                                WHEN CCCT.dataInfo = 2 THEN ''COMMON_VIA_CALLS_LOG''
                                WHEN CCCT.dataInfo = 3 THEN ''COMMON_VIA_CALLS_LOG''
                                ELSE ''T&COMMON_NONE'' END
                        END

                    WHEN CCCT.identifierInfo = ''OUT_ANI_LIST'' THEN
                                ISNULL((SELECT [description] FROM ccRotativeANIList WHERE id_RAniList = CCCT.dataInfo), CCCT.dataInfo)

                    WHEN CCCT.identifierInfo = ''OUT_CONDUCT_SURVEY'' THEN
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
                    WHEN CCCT.identifierInfo IN (''OUT_MANUAL_DIALING_ON_CHAT'', ''OUT_TIME_ZONE_VALIDATION_MANUAL'', ''OUT_INTENSIVE_DIALING'', ''OUT_CALLBACK_EXCLUSIVE_AGENT'', ''OUT_VOIEMAIL_DETECTION'',
                                                ''OUT_CALLBACK_FAILED'', ''OUT_EXIT_ASSISTED'', ''OUT_SHOW_DISPOSITIONS'', ''OUT_EDIT_CALL_KEY'', ''OUT_STOP_RECORDING'', ''OUT_LEAVE_PRERECORDED'',
                                                ''OUT_CONDUCT_CALLBACK_SURVEY'', ''OUT_RECEIVE_DTMF'', ''OUT_SELECT_ANI_ON_DIALING'', ''OUT_SMS_START_CAMP_AUTO'', ''OUT_RECORD_ON_HOLD'', ''OUT_LISTEN_TONE'', ''OUT_UNASSIGN_RECORDS'') THEN
                        CASE WHEN CCCT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                        
                    ELSE CCCT.dataInfo END
            ELSE '''' END, 
            CASE WHEN CCCT.identifierInfo = ''OUT_CALL_EDIT_NAME'' THEN @PrevName ELSE (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id) END
        FROM #ccCampsTable AS CCCT;

        EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccCamps'', @columnNameId = ''cam_id'', @valueId = @cam_id, @userId = @userid;
        IF OBJECT_ID(N''tempdb..#ccCampsTable'') IS NOT NULL DROP TABLE #ccCampsTable

if (@timesDiscard < @timesDiscardActual and @CheckCamp=1)
begin
    EXECUTE ccsp_CheckTimesDiscard @action=0,@camId = @cam_id
end

IF (@CampType IS NOT NULL AND @CampType IN (3, 5))
BEGIN
    IF NOT EXISTS(SELECT camp_id FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id)
    BEGIN
        SELECT 0
        RETURN(0)
    END

    IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

    Create table #contactMeanOutTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    EXEC InsertLogAdminGalatea @action=1, @tableName=''contactMeanOut'', @columnNameId=''camp_id'', @valueId= @cam_id, @userId= @userid

    DECLARE @PrevConexionInfo VARCHAR(MAX) = (SELECT [conexionInfo] FROM contactMeanOut WHERE @CampType = meanContactTypeId AND camp_id = @cam_id);

    set @ConexionInfo = case when  @ConexionInfo is null or @ConexionInfo in('''',''0'',''None'',''Ninguno'') then CASE WHEN @isCreating > 0 AND @PrevConexionInfo <> '''' THEN ''Ninguno'' ELSE '''' END else @ConexionInfo end
    UPDATE contactMeanOut SET conexionInfo = @ConexionInfo, ConnPass = @ConexionInfo, connUser = @ConexionInfo,
                                            closeConversationTime = CAST(@agentCloseConversationTime AS INT), answerTimeoutClient = @adminCloseConversationTime,
                            allowFileAttachments = @allowFileAttachments
    WHERE @CampType = meanContactTypeId AND camp_id = @cam_id

        
    IF(@isCreating > 0 AND @module > -1) BEGIN 
        EXEC InsertLogAdminGalatea @action=2, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid, @tableTemp=''#contactMeanOutTable'';
        IF(@ConexionInfo IS NULL OR @ConexionInfo IN ('''',''0'',''None'',''Ninguno'') AND @PrevConexionInfo <> @ConexionInfo) UPDATE contactMeanOut SET conexionInfo = '''' WHERE @CampType = meanContactTypeId AND camp_id = @cam_id
    END

    DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''conexionInfo'') AND  dataInfo = '''''''';
    DELETE FROM #contactMeanOutTable WHERE columnInfo IN (''ConnPass'', ''connUser'') ;

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        @operation, 
        @module, 
        CMOT.identifierInfo,
        CASE WHEN CMOT.identifierInfo IS NOT NULL AND CMOT.identifierInfo <> '''' THEN
            CASE
                WHEN CMOT.identifierInfo = ''OUT_WHATS_ATTACH_FILES'' THEN
                    CASE WHEN CMOT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                WHEN CMOT.identifierInfo = ''OUT_WHATS_ASSOCIATED_PHONE'' THEN
                    CASE WHEN CMOT.dataInfo = ''Ninguno'' THEN ''COMMON_NONE_O'' ELSE CMOT.dataInfo END
                ELSE CMOT.dataInfo END
        ELSE '''' END, 
        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id)
    FROM #contactMeanOutTable AS CMOT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''contactMeanOut'', @columnNameId = ''camp_id'', @valueId = @cam_id, @userId = @userid;
    IF OBJECT_ID(N''tempdb..#contactMeanOutTable'') IS NOT NULL DROP TABLE #contactMeanOutTable

    IF @CampType = 5 BEGIN
        update ccWhatsAppNumbers set camp_id=0 where camp_id=@cam_id
        IF(@ConexionInfo <> '''')
        BEGIN 
            UPDATE ccWhatsAppNumbers SET camp_id = @cam_id WHERE number = @ConexionInfo
        END
    END
END 
DECLARE @prevCalif BIT = (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id);

IF @cam_ShowCalifWnd = 1
BEGIN
    IF NOT EXISTS(SELECT cam_id FROM ccCalifCamp WHERE cam_id = @cam_id and tipo = 1)
    BEGIN
        SELECT 0
        RETURN(0)
    END

    UPDATE ccCamps SET
    cam_ShowCalifWnd = ISNULL(@cam_ShowCalifWnd,cam_ShowCalifWnd)
    WHERE cam_id = @cam_id


    IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        SELECT 
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            @operation, 
            3, 
            ''OUT_SHOW_DISPOSITIONS'',
            CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
            (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
    END

    SELECT 1
    RETURN(0)
END

UPDATE ccCamps SET
cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
where cam_id = @cam_id

IF(@prevCalif <> @cam_ShowCalifWnd) BEGIN
    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        @operation, 
        3, 
        ''OUT_SHOW_DISPOSITIONS'',
        CASE WHEN (SELECT [cam_ShowCalifWnd] FROM ccCamps WHERE cam_id = @cam_id) = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END, 
        (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @cam_id);
END

SELECT 2
RETURN(0)

set nocount off'
    EXEC(@sql)


    ---------------------------------------END Jesus Gallardo hotfix/125.20231211.0.9---------------------------------------------------------

    ---------------------------------------BEGIN Ivan Martin hotfix/125.20231211.0.9---------------------------------------------------------

set @process = 'Dineria Hotfix se agrega sigo de igual para que tome tambien las horas en linea 6451'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_OUTcheckTimeZone] @cam_id AS INT,@isReturnSelect bit=1
            AS
            SET NOCOUNT ON

            DECLARE @horaUniversal DATETIME, @revHorario BIT, @isShudulerLey BIT, @dateNow DATETIME
            DECLARE @hourStart INT, @hourEnd INT, @minStart INT, @minEnd INT
            DECLARE @timeMaxContestacion INT, @campType INT;

            SET @timeMaxContestacion = 60

            SELECT @revHorario = valor
            FROM ccsettings
            WHERE setting_id = 112

            SELECT @timeMaxContestacion = (cam_tNoContesta * 2)
            FROM cccamps
            WHERE cam_id = @cam_id

            SET @timeMaxContestacion = CEILING(cast(@timeMaxContestacion AS DECIMAL(10, 2)) / cast(60 AS DECIMAL(10, 2)))

            declare @schLaw table (hourStart int not null,minStart int not null,hourEnd int not null,minEnd int not null)

            SELECT @campType = CampType
            FROM ccCamps
            WHERE cam_id = @cam_id;

            DECLARE @isSmsCamp BIT = CASE WHEN @campType = 7 THEN 1 ELSE 0 END;

            insert into @schLaw
            exec ccsp_GetHourLaw @isSms = @isSmsCamp
            SELECT @hourStart = hourStart, @minStart = minStart, @hourEnd = hourEnd, @minEnd = minEnd from @schLaw

            SET DATEFIRST 1
            SET @horaUniversal = getutcdate()
            SET @dateNow = getdate()
            declare @iZonas int
            -- Si la campaña no tiene horarios asignados, marcar todas las zonas
            IF @revHorario = 0
            BEGIN
                IF NOT EXISTS (
                        SELECT cam_id
                        FROM ccCampsHorarios WITH (INDEX (IX_ccCampsHorarios))
                        WHERE cam_id = @cam_id
                        )
                BEGIN
                    SELECT @iZonas=sum(DISTINCT tz_id)
                    FROM (
                        SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha, 
                        datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora, 
                        datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto, 
                        datepart(dw, dateadd(mi, tz_offset * 60, @horaUniversal)) AS dia
                        FROM ccTimeZones
                        ) zonas
                    WHERE (
                            hora > @hourStart OR ( hora = @hourStart AND minuto >= @minStart)
                            )
                        AND (
                            hora < @hourEnd OR ( hora = @hourEnd AND minuto <= @minEnd)
                            )

                if @isReturnSelect=1 begin
                    select @iZonas as iZonas
                end
                return @iZonas
                END
            END

            IF @campType <> 7
            BEGIN
                
                SELECT h.horario_id, Descripcion, CASE WHEN HoraInicio > @hourStart THEN HoraInicio ELSE @hourStart END HoraInicio
                , CASE WHEN (horaInicio > @hourStart OR (horaInicio = @hourStart    AND MinInicio >= @minStart) ) THEN MinInicio ELSE @minStart END MinInicio
                , CASE WHEN horaFin < @hourEnd THEN horaFin ELSE @hourEnd END HoraFin
                , CASE WHEN (
                    (horaFin < @hourEnd OR (horaFin = @hourEnd AND MinFin <= @minEnd)
                        )
                    ) THEN MinFin ELSE @minEnd END MinFin, Lunes, Martes, Miercoles, Jueves, Viernes, Sabado, Domingo
                INTO #tempCamp
                FROM cchorarios h
                INNER JOIN ccCampsHorarios WITH (INDEX (IX_ccCampsHorarios)) ON h.horario_id = ccCampsHorarios.horario_id
                    AND ccCampsHorarios.cam_id = @cam_id

                SELECT @iZonas=isnull(sum(DISTINCT tz_id), 0)
                FROM (
                    SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha, 
                    datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora, 
                    datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto, 
                    datepart(dw, dateadd(mi, tz_offset * 60, @horaUniversal)) AS dia
                    FROM ccTimeZones
                    ) zonas
                INNER JOIN #tempCamp ON (
                        (
                            hora > HoraInicio OR ( hora = HoraInicio AND minuto >= MinInicio)
                            )
                        AND (
                            hora < HoraFin OR (hora = HoraFin AND minuto <= (MinFin - @timeMaxContestacion))
                            )
                        AND (
                            Lunes = dia
                            OR Martes * 2 = dia
                            OR Miercoles * 3 = dia
                            OR Jueves * 4 = dia
                            OR Viernes * 5 = dia
                            OR Sabado * 6 = dia
                            OR domingo * 7 = dia
                            )
                        )

                DROP TABLE #tempCamp
                if @isReturnSelect=1 begin
                    select @iZonas as iZonas
                end
                return @iZonas
            END
            ELSE
            BEGIN
                    ;

                WITH sch
                AS (
                    SELECT DATEPART(hh, idate) AS HoraInicio, DATEPART(mi, iDate) AS MinInicio, 
                    DATEPART(hh, fdate) HoraFin, DATEPART(mi, fdate) MinFin
                    FROM ccSmsSchedules
                    WHERE cam_id = @cam_id
                        AND @dateNow BETWEEN dateadd(hh,-12,iDate) AND dateadd(hh,12,fDate)
                    ), daysch
                AS (
                    SELECT CASE WHEN HoraInicio > @hourStart THEN HoraInicio ELSE @hourStart END HoraInicio
                    , CASE WHEN (horaInicio > @hourStart OR (horaInicio = @hourStart AND MinInicio >= @minStart )
                                    ) THEN MinInicio ELSE @minStart END MinInicio
                    , CASE WHEN horaFin < @hourEnd THEN horaFin ELSE @hourEnd END HoraFin
                    , CASE WHEN ((  horaFin < @hourEnd OR ( horaFin = @hourEnd AND MinFin <= @minEnd))
                                    ) THEN MinFin ELSE @minEnd END MinFin
                    FROM sch
                    ), zonas
                AS (
                    SELECT tz_id, dateadd(mi, tz_offset * 60, @horaUniversal) AS fecha
                    , datepart(hh, dateadd(mi, tz_offset * 60, @horaUniversal)) AS hora
                    , datepart(mi, dateadd(mi, tz_offset * 60, @horaUniversal)) AS minuto
                    FROM ccTimeZones
                    )
                SELECT @iZonas=isnull(sum(DISTINCT B.tz_id), 0)
                FROM daysch A
                INNER JOIN zonas B ON (
                        hora >= HoraInicio OR ( hora = HoraInicio AND minuto >= MinInicio)
                        )
                    AND (
                        hora < HoraFin OR (hora = HoraFin AND minuto <= (MinFin - @timeMaxContestacion))
                        )

                if @isReturnSelect=1 begin
                    select @iZonas as iZonas
                end
                return @iZonas
            END
    '
    EXEC(@sql)

     set @process = 'Dineria: Se crea nueva tabla de ProcessingSmsStatusUpdates'
    set @sql='IF NOT EXISTS(SELECT * FROM sys.tables WHERE name = N''ProcessingSmsStatusUpdates'') BEGIN
                CREATE TABLE ProcessingSmsStatusUpdates (
                SystemApiId VARCHAR(100) PRIMARY KEY,
                StatusSystemsId INT,
                IsCharged bit);
              END'
    EXEC(@sql)


    set @process = 'Dineria: Se cambia action 1 para que regrese solo campañas con horario valido. Se cambia completamente action 7 para que actualice los estados en paquetes de la tabla ProcessingSmsStatusUpdates. Se agrega WITH(NOLOCK) en acceso a tablas smsOutSource/smsccoLogDial en actions 7 y 9'
    set @sql='ALTER procedure [dbo].[ccspOutboundSmsMessage] 
        @action int,
        @camId int = null,
        @SentMsg int=null,
        @smsoutIds varchar(max)=null,
        @SystemApiId varchar(100)=null,
        @statusSystemsId int =null,
        @InsufficientBalance int=null,
        @date datetime =null,
        @addingCampaign bit = null
        as
        declare @sql varchar(max)
        if @action=1 begin
            set @date=getdate()

            if @addingCampaign = 1 begin
                select distinct cast(c. cam_id as int) as CamId,
                                cam_descripcion as [Name],
                                cam_procesando as [Start],
                                0 AS MessageQuantity
                from ccCamps c
                where CampType=7 and c.IDArea is not null and c.cam_id=@camId
            end
            else begin
                SELECT DISTINCT CAST(c. cam_id AS INT) AS CamId,
                                cam_descripcion AS Name,
                                cam_procesando AS Start,
                                ISNULL((w.new + w.pro),0) AS MessageQuantity
                FROM ccCamps c
                LEFT JOIN ccSmsSchedules s ON s.cam_id = c.cam_id
                LEFT JOIN ccCampsNvosCB  w ON c.cam_id = w.id
                WHERE CampType=7 AND c.IDArea IS NOT NULL AND(@camId IS NULL or @camId=0 OR c.cam_id = @camId)
                AND @date BETWEEN dateadd(hh,-12,iDate) AND dateadd(hh,12,fDate)
            end
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
            if not exists(select * from ccSmsConversationsResult where camId=@camId) begin
                insert into ccSmsConversationsResult(camId,SentMsg,Delivered,NotDelivered,RecipientRejected,CarrierRejected,InsufficientBalance,Exception)
                values(@camId,@SentMsg,0,0,0,0,@InsufficientBalance,0)
            end
            else begin
                update ccSmsConversationsResult set SentMsg=SentMsg+@SentMsg 
                ,InsufficientBalance=InsufficientBalance+@InsufficientBalance
                where camId=@camId
            end
        end
        else if @action=6 begin 
            set @sql=''delete from smsWorkingTable where smsout_id in(''+@smsoutIds+'')''
            exec (@sql)
        end
        else if @action=7 begin
            DECLARE @TemporalProcessingSmsStatusUpdates TABLE(SystemApiId VARCHAR(100) PRIMARY KEY, StatusSystemsId INT, IsCharged BIT)
            INSERT INTO @TemporalProcessingSmsStatusUpdates
            SELECT SystemApiId, StatusSystemsId, IsCharged FROM ProcessingSmsStatusUpdates

            DECLARE @ChargedMessages INT = (SELECT SUM(CASE WHEN IsCharged = 1 THEN 1 ELSE 0 END) FROM @TemporalProcessingSmsStatusUpdates)
            IF @ChargedMessages <> 0
            BEGIN
                UPDATE ccSettings2 WITH(TABLOCK) SET valor = valor - @ChargedMessages WHERE setting_id = 258 AND valor > 0;
            END

            DECLARE @UpdatingSmsWorkingTable TABLE(SystemApiId VARCHAR(100) PRIMARY KEY, OldStatusSystemsId INT, NewStatusSystemsId INT, CampaignId INT)
            INSERT INTO @UpdatingSmsWorkingTable
            SELECT S.SystemApiId, S.StatusSystemsId, T.StatusSystemsId, S.cam_id FROM smsccoLogDial S WITH(NOLOCK)
            INNER JOIN @TemporalProcessingSmsStatusUpdates T ON S.SystemApiId = T.SystemApiId
            
            ;WITH CTE AS (
            SELECT
                CampaignId,
                COUNT(CASE WHEN NewStatusSystemsId = 0 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 0 THEN 1 END) AS SentMsg,
                COUNT(CASE WHEN NewStatusSystemsId = 1 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 1 THEN 1 END) AS Delivered,
                COUNT(CASE WHEN NewStatusSystemsId = 2 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 2 THEN 1 END) AS NotDelivered,
                COUNT(CASE WHEN NewStatusSystemsId = 3 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 3 THEN 1 END) AS RecipientRejected,
                COUNT(CASE WHEN NewStatusSystemsId = 4 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 4 THEN 1 END) AS CarrierRejected,
                COUNT(CASE WHEN NewStatusSystemsId = 5 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 5 THEN 1 END) AS Exception,
                COUNT(CASE WHEN NewStatusSystemsId = 6 THEN 1 END) - COUNT(CASE WHEN OldStatusSystemsId = 6 THEN 1 END) AS InsufficientBalance

            FROM @UpdatingSmsWorkingTable
            GROUP BY CampaignId
            )

            MERGE INTO ccSmsConversationsResult AS Target
            USING CTE AS Source ON Target.camId = Source.CampaignId
            WHEN MATCHED THEN
                UPDATE SET
                    Target.SentMsg = CASE WHEN (Target.SentMsg + Source.SentMsg) < 0 THEN 0 ELSE (Target.SentMsg + Source.SentMsg) END,
                    Target.Delivered = CASE WHEN (Target.Delivered + Source.Delivered) < 0 THEN 0 ELSE (Target.Delivered + Source.Delivered) END,
                    Target.NotDelivered = CASE WHEN (Target.NotDelivered + Source.NotDelivered) < 0 THEN 0 ELSE (Target.NotDelivered + Source.NotDelivered) END,
                    Target.RecipientRejected = CASE WHEN (Target.RecipientRejected + Source.RecipientRejected) < 0 THEN 0 ELSE (Target.RecipientRejected + Source.RecipientRejected) END,
                    Target.CarrierRejected = CASE WHEN (Target.CarrierRejected + Source.CarrierRejected) < 0 THEN 0 ELSE (Target.CarrierRejected + Source.CarrierRejected) END,
                    Target.Exception = CASE WHEN (Target.Exception + Source.Exception) < 0 THEN 0 ELSE (Target.Exception + Source.Exception) END,
                    Target.InsufficientBalance = CASE WHEN (Target.InsufficientBalance + Source.InsufficientBalance) < 0 THEN 0 ELSE (Target.InsufficientBalance + Source.InsufficientBalance) END

            WHEN NOT MATCHED BY TARGET THEN
            INSERT (camId, SentMsg, Delivered, NotDelivered, RecipientRejected, CarrierRejected, Exception, InsufficientBalance)
            VALUES (Source.CampaignId, Source.SentMsg, Source.Delivered, Source.NotDelivered, Source.RecipientRejected, Source.CarrierRejected, Source.Exception, Source.InsufficientBalance);

            UPDATE smsccoLogDial SET Bill = (CASE WHEN T.StatusSystemsId IN (0, 1, 2) THEN 0.7 ELSE 0 END),
                                     statusSystemsId = T.StatusSystemsId
            FROM smsccoLogDial S WITH(NOLOCK)
            INNER JOIN @TemporalProcessingSmsStatusUpdates T ON T.SystemApiId = S.SystemApiId

            DELETE FROM ProcessingSmsStatusUpdates 
            WHERE SystemApiId IN (SELECT SystemApiId FROM @TemporalProcessingSmsStatusUpdates);

            SELECT @@ROWCOUNT;
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
            FROM smsWorkingTable wt WITH(NOLOCK)
            JOIN smsOutSource os WITH(NOLOCK) ON wt.smsout_id = os.smsout_id
            LEFT JOIN smsccoLogDial cco WITH(NOLOCK) ON wt.smsout_id = cco.smsout_id
            WHERE wt.cam_id=@camId and wt.sms_status IN(1,2) 
            AND cco.smsout_id IS NULL;
            

            UPDATE wt
            SET wt.sms_status = 0
            FROM smsWorkingTable wt
            JOIN #TempSmsOutIds temp ON wt.smsout_id = temp.smsout_id;

            DROP TABLE #TempSmsOutIds;
        end
        else if @action=10 begin
            SELECT COUNT(*) FROM smsWorkingTable with (NOLOCK) WHERE cam_id = @camId
        end
        else if @action=12 begin
            IF EXISTS (SELECT 1 FROM ccSmsSchedules WITH (NOLOCK) WHERE cam_id = @camId 
            AND GETDATE() BETWEEN dateadd(hh,-12,iDate) AND dateadd(hh,12,fDate)
            )
            AND EXISTS (SELECT 1 FROM smsWorkingTable WITH (NOLOCK) WHERE cam_id = @camId)
            BEGIN
                SELECT CAST(0 AS BIT);
                RETURN;
            END
            ELSE BEGIN
                UPDATE ccCamps SET cam_procesando = 0 WHERE cam_id = @camId
                SELECT CAST(1 AS BIT);
                RETURN;
            END
        end'
    EXEC(@sql)

    set @process = 'Alter SP ccsp_AgentHistoricalChat, add folder (INBOUND & OUTBOUND) into file path, action 4'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_AgentHistoricalChat] 
@option SMALLINT, 
@clientNum VARCHAR(15) = '''', 
@conversationId AS INT = 0, 
@inboundId AS SMALLINT = 0, 
@serviceType AS SMALLINT = 0,
@campType AS INT = 0
AS
BEGIN
    IF @option = 1 --whatsapp, get conversation ids
    BEGIN
        DECLARE @tempId INT = 0
        IF @campType = 0 -- INBOUND
        BEGIN
            SELECT conversationId AS ConversationId,
                   @campType AS CampType,
                   assignDate AS Date
            FROM ccWhatsAppConversations with(nolock)
            WHERE clientId = @clientNum AND assignDate IS NOT NULL
            GROUP BY conversationId, assignDate
        END
        ELSE
        BEGIN  -- OUTBOUND
            SELECT conversationId AS ConversationId,
                   @campType AS CampType,
                   assignDate AS Date
            FROM ccWhatsAppConversationsOut with(nolock)
            WHERE clientId = @clientNum AND assignDate IS NOT NULL
            GROUP BY conversationId, assignDate
        END
    END

    IF @option = 2 --whatsapp, get acdId by conversation id
    BEGIN
        IF @campType = 0
        BEGIN
            SELECT CAST(inboundId AS INT)
            FROM [ccWhatsAppConversations] with(nolock)
            WHERE conversationId = @conversationId
        END
        ELSE
        BEGIN
            SELECT CAST(camId AS INT)
            FROM [ccWhatsAppConversationsOut] with(nolock)
            WHERE conversationId = @conversationId
        END
    END

    IF @option = 3 --get data conversation
    BEGIN
        DECLARE @OldAgentId INT = 0
        DECLARE @OldConversationId INT = 0

        SELECT @OldAgentId = conv.agentId, @OldConversationId = rel.conversationIdBefore
        FROM ccWhatsAppConversationsRelationship rel with(nolock)
        RIGHT JOIN ccWhatsAppConversations conv with(nolock) ON conv.conversationId = rel.conversationIdBefore
        WHERE rel.conversationIdAfter = @conversationId

        SELECT cast(i.chat AS INT) AS ServiceType, cast(c.conversationId AS INT) AS ConversationID, c.clientId AS ClientId, cm.conexionInfo AS [To], cast(i.Inbound_id AS INT) AS ACDId, i.descripcion AS ACDName, cast(g.
                graphic_id AS INT) AS ACDGraphicId, cast(cm.closeConversationTime AS INT) AS [TimeOut], cast(cm.answerTimeOut AS INT) AS [TimeOutWarning], i.ExitWrapUpDisposition AS [ExitWrapUpDisposition], i.tNotas AS 
            [WrapUpTime], i.ShowCalifWnd, cast(ISNULL(answerTimeoutClient, 30) AS INT) AS [AnswerTimeoutClient], ISNULL(DATEDIFF(ss, lm.timeStampLastMessageAgent, lm.desconnectionAgent), 0) AS 
            [SecTimeOutLastMessageAgent], isnull(permission.AllowUnassign, 0) AS AllowUnassign, isnull(permission.AllowSpam, 0) AS AllowSpam, ISNULL(@OldAgentId, 0) AS OldAgentId, ISNULL(@OldConversationId, 0) AS 
            OldConversationId, c.agentId AS AgentId
        FROM ccInbound i
        INNER JOIN contactMeanIn cm ON i.Inbound_id = cm.inboundId
        INNER JOIN ccWhatsAppConversations c with(nolock) ON (
                c.inboundId = i.Inbound_id
                AND c.conversationId = @conversationId
                )
        INNER JOIN ccRIAInboundGraph g ON g.Inbound_id = i.Inbound_id
        LEFT JOIN ccLastMessageAgentByConversation lm ON lm.conversationId = c.conversationId
        LEFT JOIN ccRIAAgentsPermissions permission ON permission.AgentId = c.agentId
        WHERE i.chat = @serviceType
            AND i.Inbound_id = @inboundId

    END

    IF @option = 4 --get messages from conversation id
    BEGIN
        DECLARE @filetype AS VARCHAR(5)
        DECLARE @camp_acd_id INT = 0;

        IF @campType = 0
        BEGIN
            SET @camp_acd_id = (SELECT inboundId FROM ccWhatsAppConversations with(nolock) WHERE conversationId = @conversationId)

            SELECT messageId AS MessageId, messageStatus AS STATUS, originType AS Origin, CASE 
            WHEN originType = ''Client''
                THEN 3
            WHEN originType = ''Agent''
                THEN 2
            WHEN originType = ''Admin''
                THEN 1
            ELSE 0
            END AS OriginType, timeStampMessage AS [Timestamp], CASE 
            WHEN typeMessage <> ''text''
                THEN ''''
            ELSE content
            END AS Content, typeMessage AS Type, CASE 
            WHEN typeMessage NOT IN (''text'', ''location'')
                THEN content
            ELSE ''''
            END AS Caption, CASE 
            WHEN originType = ''Client''
                THEN CASE 
                        WHEN typeMessage = ''text''
                            OR typeMessage = ''location''
                            THEN ''''
                        ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + ''INBOUND'' + CHAR(92)+ CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
                            typeMessage + CHAR(92) + CHAR(92) + messageId + ''.'' + CASE 
                                WHEN typeMessage = ''video''
                                    THEN ''mp4''
                                WHEN typeMessage = ''image''
                                    THEN ''jpg''
                                WHEN typeMessage = ''audio''
                                    THEN ''mp3''
                                WHEN typeMessage = ''file''
                                    THEN (
                                            SELECT substring(content, CHARINDEX(''.'', content) + 1, len(content))
                                            )
                                ELSE ''''
                                END
                        END
            ELSE CASE 
                    WHEN typeMessage = ''text''
                        OR typeMessage = ''location''
                        THEN ''''
                    ELSE content
                    END
            END AS [Url], CASE 
            WHEN typeMessage = ''location''
                THEN (
                        SELECT value
                        FROM dbo.fn_RIASplitDelimited((
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                    WHERE id = 1
                                    ), '':'')
                        WHERE id = 2
                        )
            ELSE ''''
            END AS [Address], CASE 
            WHEN typeMessage = ''location''
                THEN (
                        SELECT value
                        FROM dbo.fn_RIASplitDelimited((
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                    WHERE id = 2
                                    ), '':'')
                        WHERE id = 2
                        )
            ELSE ''''
            END AS [Lat], CASE 
            WHEN typeMessage = ''location''
                THEN (
                        SELECT value
                        FROM dbo.fn_RIASplitDelimited((
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                    WHERE id = 3
                                    ), '':'')
                        WHERE id = 2
                        )
            ELSE ''''
            END AS [Long], CASE 
            WHEN typeMessage = ''location''
                THEN (
                        SELECT value
                        FROM dbo.fn_RIASplitDelimited((
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                    WHERE id = 4
                                    ), '':'')
                        WHERE id = 2
                        )
            ELSE ''''
            END AS [Name], CASE 
            WHEN typeMessage = ''location''
                THEN ''https://www.google.com/maps/search/'' + (
                        SELECT value
                        FROM dbo.fn_RIASplitDelimited((
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                    WHERE id = 2
                                    ), '':'')
                        WHERE id = 2
                        ) + '','' + (
                        SELECT value
                        FROM dbo.fn_RIASplitDelimited((
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                    WHERE id = 3
                                    ), '':'')
                        WHERE id = 2
                        )
            ELSE ''''
            END AS [LocationURL],
            graphics.graphic_id AS GraphicId
            FROM ccWAMessagesConversations
            LEFT JOIN ccRIAInboundGraph graphics ON Inbound_id = @camp_acd_id
            WHERE conversationId = @conversationId
            ORDER BY TIMESTAMP ASC
        END
        ELSE
        BEGIN
            SET @camp_acd_id = (SELECT camId FROM ccWhatsAppConversationsOut with(nolock) WHERE conversationId = @conversationId)

            SELECT messageId AS MessageId, messageStatus AS STATUS, originType AS Origin, CASE 
            WHEN originType = ''Client''
                THEN 3
            WHEN originType = ''Agent''
                THEN 2
            WHEN originType = ''Admin''
                THEN 1
            ELSE 0
            END AS OriginType, timeStampMessage AS [Timestamp], CASE 
            WHEN typeMessage IN (''text'', ''template'')
                THEN content 
            ELSE ''''
            END AS Content, typeMessage AS Type, CASE 
            WHEN typeMessage NOT IN (''text'', ''location'', ''template'')
                THEN content
            ELSE ''''
            END AS Caption, CASE 
            WHEN originType = ''Client''
                THEN CASE 
                        WHEN typeMessage = ''text''
                            OR typeMessage = ''location''
                            THEN ''''
                        ELSE CHAR(92) + CHAR(92) + ''WhatsApp'' + CHAR(92) + CHAR(92) + ''OUTBOUND'' + CHAR(92)+ CHAR(92) + cast(conversationId / 1000 AS VARCHAR(30)) + CHAR(92) + CHAR(92) + cast(conversationId AS VARCHAR(20)) + CHAR(92) + CHAR(92) + 
                            typeMessage + CHAR(92) + CHAR(92) + messageId + ''.'' + CASE 
                                WHEN typeMessage = ''video''
                                    THEN ''mp4''
                                WHEN typeMessage = ''image''
                                    THEN ''jpg''
                                WHEN typeMessage = ''audio''
                                    THEN ''mp3''
                                WHEN typeMessage = ''file''
                                    THEN (
                                            SELECT substring(content, CHARINDEX(''.'', content) + 1, len(content))
                                            )
                                ELSE ''''
                                END
                        END
            ELSE CASE 
                    WHEN typeMessage = ''text''
                        OR typeMessage = ''location''
                        OR typeMessage = ''template''
                        THEN ''''
                    ELSE content
                    END
            END AS [Url], CASE 
            WHEN typeMessage = ''location''
                THEN (
                        SELECT value
                        FROM dbo.fn_RIASplitDelimited((
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                    WHERE id = 1
                                    ), '':'')
                        WHERE id = 2
                        )
            ELSE ''''
            END AS [Address], CASE 
            WHEN typeMessage = ''location''
                THEN (
                        SELECT value
                        FROM dbo.fn_RIASplitDelimited((
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                    WHERE id = 2
                                    ), '':'')
                        WHERE id = 2
                        )
            ELSE ''''
            END AS [Lat], CASE 
            WHEN typeMessage = ''location''
                THEN (
                        SELECT value
                        FROM dbo.fn_RIASplitDelimited((
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                    WHERE id = 3
                                    ), '':'')
                        WHERE id = 2
                        )
            ELSE ''''
            END AS [Long], CASE 
            WHEN typeMessage = ''location''
                THEN (
                        SELECT value
                        FROM dbo.fn_RIASplitDelimited((
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                    WHERE id = 4
                                    ), '':'')
                        WHERE id = 2
                        )
            ELSE ''''
            END AS [Name], CASE 
            WHEN typeMessage = ''location''
                THEN ''https://www.google.com/maps/search/'' + (
                        SELECT value
                        FROM dbo.fn_RIASplitDelimited((
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                    WHERE id = 2
                                    ), '':'')
                        WHERE id = 2
                        ) + '','' + (
                        SELECT value
                        FROM dbo.fn_RIASplitDelimited((
                                    SELECT value
                                    FROM dbo.fn_RIASplitDelimited(content, ''|'')
                                    WHERE id = 3
                                    ), '':'')
                        WHERE id = 2
                        )
            ELSE ''''
            END AS [LocationURL],
            graphics.graphic_id AS GraphicId
            
            FROM ccWAMessagesConversationsOut
            LEFT JOIN ccRIACampsGraph graphics ON cam_id = @camp_acd_id
            WHERE conversationId = @conversationId
            ORDER BY TIMESTAMP ASC
        END
        
    END

    IF @option = 5 --get if conversation is reassigned
    BEGIN
        IF @campType = 0
        BEGIN
            SELECT CASE 
                WHEN EXISTS (
                        SELECT *
                        FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationship] with(nolock)
                        WHERE conversationIdAfter = @conversationId
                        )
                    THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
                END
        END
        ELSE
        BEGIN
            SELECT CASE 
                WHEN EXISTS (
                        SELECT *
                        FROM [CCenterRIA].[dbo].[ccWhatsAppConversationsRelationshipOut] with(nolock)
                        WHERE conversationIdAfter = @conversationId
                        )
                    THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
                END
        END
    END
END'
    EXEC(@sql)

    SET @process = 'CW-8321 Se modifica la opcion 9 para usar el campType 4 y evitar que las campañas de IA reciban el tipo de campaña 0'
        SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIALoadCamps] @option SMALLINT, @AreaId SMALLINT = NULL, @Sup SMALLINT = NULL, @WGID SMALLINT = NULL
        AS
        SET NOCOUNT ON

        DECLARE @loginDays INT

        SET @loginDays = 0

        IF @option = 1 -- Todas las campa?as
        BEGIN
            SELECT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0), isnull(DNCscrub, 0)
            FROM ccCamps a1
            JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
            JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
            WHERE a3.type_id = 1 AND a1.cam_id IN (
                    SELECT cam_id
                    FROM dbo.fGet_CampAcd_Area(@Sup, 1)
                    )
            ORDER BY 5, 2

            RETURN (0)
        END

        IF @option = 2 -- Campa?as de un Area
        BEGIN
            SELECT DISTINCT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG, CASE WHEN a1.ivrScript <> 0 AND a1.callsBySurvey <> 0 THEN 8 ELSE ISNULL(a1.CampType, 0) END as mode
            FROM ccCamps a1
            JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
            JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
            WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
            ORDER BY cam_descripcion

            RETURN (0)
        END

        IF @option = 3 -- Campa?as por Supervisor
        BEGIN
            SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(a1.IDArea, 0) IDArea
            FROM ccCamps a1
            JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
            JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
            JOIN ccSupervisorCam a4 ON a1.cam_id = a4.cam_id
            WHERE a3.type_id = 1 AND a4.tipo = 1 AND a4.user_id = @Sup
            ORDER BY 5, 2

            RETURN (0)
        END

        IF @option = 4 -- Rels Camps-Agents
        BEGIN
            SELECT @loginDays = valor
            FROM ccSettings
            WHERE setting_id = 211 --Numero dias que cargara las relaciones

            SELECT LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea, min(rel_id) rel_id
            FROM (
                SELECT A.LOGIN, A.User_id, Prioridad, Skill, C.cam_id, C.cam_descripcion, isnull(C.IDArea, 0) IDArea, CA.rel_id
                FROM ccCamps C
                JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id
                JOIN ccRIACampsGraph a2 ON C.cam_id = a2.cam_id
                JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
                JOIN ccUsers A ON A.User_id = CA.User_id AND A.TipoUser_id = 1 AND A.STATUS = 1 AND (@loginDays = 0 OR DATEDIFF(dd, LastLoginAttempt, getdate()) <= @loginDays)
                WHERE C.cam_id IN (
                        SELECT cam_id
                        FROM ccsupervisorcam
                        WHERE user_id = CASE isnull(@Sup, 0) WHEN 0 THEN user_id ELSE @Sup END AND tipo = 1
                        )
                ) Relations
            GROUP BY LOGIN, User_id, Prioridad, Skill, cam_id, cam_descripcion, IDArea
            ORDER BY User_id, cam_descripcion, cam_id, Prioridad

            RETURN (0)
        END

        IF @option = 5 -- Campa?as por Supervisor
        BEGIN
            SELECT @AreaId = IDArea
            FROM ccUsers
            WHERE User_id = @sup

            SELECT DISTINCT Camps.cam_id, Camps.cam_descripcion, a3.frame, Camps.cam_procesando, isnull(Camps.IDArea, 0) IDArea, IsNull(CN.New, 0) AS New, IsNull(CN.CB, 0) AS CB, IsNull(CN.Pro, 0) AS Pro, IsNull(CN.pen, 0) AS Pen, cast(Camps.cam_procesando AS INT) AS St, Camps.cam_TipoJobs AS Job, isnull(CN.Fin, 0) Fin, isnull(CP.prioridad, ''12345NNN'') prioridad, cast(camps.dialorder AS TINYINT) dialorder, cast(camps.progDial AS TINYINT) progDial, U.monitored, Camps.aggressionFactor
            FROM ccCamps Camps
            LEFT JOIN ccCampsPrioridadTel CP ON CP.cam_id = Camps.cam_id
            LEFT JOIN ccCampsNvosCB CN ON CN.id = Camps.cam_id
            JOIN ccRIACampsGraph a2 ON (Camps.cam_id = a2.cam_id)
            JOIN ccRIAGraphics a3 ON (a2.graphic_id = a3.graphic_id)
            JOIN ccSupervisorCam U ON Camps.cam_id = U.cam_id
            WHERE U.user_id = @sup AND tipo = 1 AND a3.type_id = 1 AND Camps.cam_id IN (
                    SELECT cam_id
                    FROM ccSupervisorCam
                    WHERE tipo = 1 AND user_id = @sup
                    ) AND Camps.IDArea = @AreaId
            ORDER BY 5, cam_procesando DESC, cam_descripcion

            RETURN (0)
        END

        IF @option = 7 -- Una sola
        BEGIN
            SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame, a1.cam_procesando, isnull(IDArea, 0) IDArea, isnull(DNCscrub, 0) DNCScrub
            FROM ccCamps a1
            JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
            JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
            WHERE a3.type_id = 1 AND isnull(a1.cam_id, 0) = isnull(@AreaId, 0)
            ORDER BY 5, 2

            RETURN (0)
        END

        IF @option = 8 -- Campa?as de un Agente
        BEGIN
            SELECT DISTINCT a1.cam_id, a1.cam_descripcion, a3.frame
            FROM ccCamps a1
            JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
            JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
            JOIN ccCampsAgente a4 ON a1.cam_id = a4.cam_id
            WHERE a3.type_id = 1 AND a4.user_id = @Sup
            ORDER BY 2

            RETURN (0)
        END
        IF @option = 9 -- Campa?as de un Area
        BEGIN
            (SELECT DISTINCT a1.cam_id as CamID, cam_descripcion as CamDescription, frame as Frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) as RelationsWG,1 CamType, 
            ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 1 and IdCampEsp = a1.cam_id and IDWG = @WGID group by IdCampEsp),0) IsAssignedToCurrentWG,
            CAST(CASE WHEN a1.progDial = 3 THEN 6 WHEN a1.CampType = 4 THEN 4 WHEN a1.CampType = 5 THEN 5 WHEN a1.CampType=7 THEN 7 WHEN a1.ivrScript <> 0 AND a1.callsBySurvey <> 0 THEN 8 ELSE 0 END as [tinyint]) [MediaType]
            FROM ccCamps a1
            JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
            JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
            WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
            UNION
            SELECT DISTINCT b1.inbound_id, descripcion, frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(b1.inbound_id, 2) relationsWG, 0 CampType, 
            ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 0 and IdCampEsp = b1.inbound_id and IDWG = @WGID group by IdCampEsp),0) isAssignedToCurrentWG,
            b1.chat [MediaType]
            FROM ccinbound b1
            JOIN ccRIAinboundGraph b2 ON b1.inbound_id = b2.inbound_id
            INNER JOIN ccRIAGraphics b3 ON b2.graphic_id = b3.graphic_id
            LEFT JOIN (
                SELECT inbound_id, CASE WHEN (sum(skill) / count(user_id)) = max(skill) THEN 0 ELSE 1 END skillDif
                FROM ccSkills
                GROUP BY inbound_id
                ) S ON S.Inbound_id = b1.inbound_id
            WHERE b3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
            ) ORDER BY camtype desc,cam_descripcion

            RETURN (0)
        END

        RETURN (0)

        SET NOCOUNT OFF
                    '
        EXEC(@sql);

        SET @process = 'TT7955 Se crea prcedimeinto para relaciones de campañas agente en GalateaAgent'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaGetAgentsRelations] @Option AS SMALLINT,
                    @Type AS SMALLINT = 0
                    AS
                    BEGIN
                        SET NOCOUNT ON;
                        IF @Option = 1 BEGIN
                            SELECT C.cam_id, C.cam_descripcion, CA.prioridad, A.Login, A.User_id, CA.skill 
                            FROM ccCamps AS C
                            JOIN ccCampsAgente AS CA ON C.cam_id = CA.cam_id 
                            JOIN ccUsers AS A  ON A.User_id = CA.User_id AND A.TipoUser_id=1 AND A.Status = 1 AND C.cam_activo=1 and A.IDArea = C.IDArea
                            WHERE (@Type = 2 AND C.cam_bNew = 2) OR @Type != 2
                            ORDER BY C.cam_id, CA.prioridad
                        END
                        ELSE IF @Option = 2 BEGIN
                            SELECT distinct I.Inbound_id, I.descripcion, prioridad, A.Login, A.User_id, skill
                            FROM ccInboundAgentes G JOIN ccInbound I ON G.Inbound_id = I.Inbound_id
                            JOIN ccUsers A  ON A.user_id = G.user_id AND A.Status = 1 AND I.IDArea = A.IDArea
                            ORDER BY I.Inbound_id, Prioridad
                        END
                    END
                    '
        EXEC(@sql);


set @process = 'ALTER sp ccsp_RIAUpdateEspecConfig TT7668 -AgenteKolob - Configuración en el tiempo de notas'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAUpdateEspecConfig] 
    @inbound_id              SMALLINT, 
    @descripcion             VARCHAR(50)  = NULL, 
    @Status                  TINYINT      = NULL, 
    @tNotas                  INT          = NULL, 
    @tMaxWaitCall            INT          = NULL, 
    @nMaxQue                 INT          = NULL, 
    @tel_maxwait             VARCHAR(15)  = NULL, 
    @tel_MaxQueue            VARCHAR(15)  = NULL, 
    @tel_outservice          VARCHAR(15)  = NULL, 
    @tel_noct                VARCHAR(15)  = NULL, 
    @ShowCalifWnd            BIT          = NULL, 
    @StartTimerOnHangUp      BIT          = NULL, 
    @editableCallKey         BIT          = NULL, 
    @queuePosition           BIT          = NULL, 
    @tMaxQueueCallBack       SMALLINT     = NULL, 
    @stopRecording           BIT          = NULL, 
    @dialPrefixOverflow      VARCHAR(10)  = NULL, 
    @OpriorityT              SMALLINT     = NULL, 
    @callerIdDesc            VARCHAR(15)  = NULL, 
    @chat                    TINYINT      = NULL, 
    @inactiveChatTime        SMALLINT     = NULL, 
    @maxChats                TINYINT      = NULL, 
    @chatDomain              VARCHAR(MAX) = NULL, 
    @chatQueue               SMALLINT     = NULL, 
    @chatTime                SMALLINT     = NULL, 
    @dRestrictPlay           BIT          = NULL, 
    @callBackSurveyAgent     BIT          = NULL, 
    @callBackSurveyClient    BIT          = NULL, 
    @agts_notavailable       VARCHAR(15)  = NULL, 
    @editableDtmf            BIT          = NULL, 
    @prefijo                 VARCHAR(MAX) = NULL, 
    @addDataCallBackReminder BIT          = NULL,
    @recordHold              BIT          = NULL,
    @editableContactData     BIT          = NULL,
    @userId                  SMALLINT     = NULL, 
    @idArea                  SMALLINT     = NULL, 
    @isCreating              BIT          = NULL
AS
SET NOCOUNT ON;

declare @domainInUse bit = 0
declare @returnValue int = 2

EXEC InsertLogAdminGalatea @action=1, @tableName=''ccInbound'', @columnNameId=''Inbound_id'', @valueId= @inbound_id, @userId= @userid

UPDATE ccInbound
SET 
    descripcion = ISNULL(@descripcion, descripcion), 
    STATUS = ISNULL(@status, STATUS), 
    tNotas = ISNULL(@tNotas, tNotas),
    tMaxWaitCall = ISNULL(@tMaxWaitCall, tMaxWaitCall), 
    nMaxQue = ISNULL(@nMaxQue, nMaxQue), 
    tel_maxwait = ISNULL(@tel_maxwait, tel_maxwait), 
    tel_MaxQueue = ISNULL(@tel_MaxQueue, tel_MaxQueue), 
    tel_outservice = ISNULL(@tel_outservice, tel_outservice), 
    tel_noct = ISNULL(@tel_noct, tel_noct), 
    bnocturno = CASE
                    WHEN ISNULL(@tel_noct, 0) = ''0''
                        OR @tel_noct = ''''
                    THEN ''0''
                    ELSE ''1''
                END, 
    StartTimerOnHangUp = ISNULL(@StartTimerOnHangUp, StartTimerOnHangUp), 
    editableCallKey = ISNULL(@editableCallKey, editableCallKey), 
    queuePosition = ISNULL(@queuePosition, queuePosition), 
    tMaxQueueCallBack = ISNULL(@tMaxQueueCallBack, tMaxQueueCallBack), 
    stopRecording = ISNULL(@stopRecording, stopRecording), 
    dialPrefixOverflow = ISNULL(@dialPrefixOverflow, dialPrefixOverflow), 
    OpriorityT = ISNULL(@OpriorityT, OpriorityT), 
    callerIdDesc = ISNULL(@callerIdDesc, callerIdDesc), 
    chat = ISNULL(@chat, chat), 
    inactiveChatTime = ISNULL(@inactiveChatTime, inactiveChatTime), 
    maxChats = ISNULL(@maxChats, maxChats), 
    chatQueueOverflow = ISNULL(@chatQueue, ISNULL(chatQueueOverflow, 15)), 
    chatTimeOverflow = ISNULL(@chatTime, ISNULL(chatTimeOverflow, 300)), 
    startStopRecording = ISNULL(@dRestrictPlay, startStopRecording), 
    callBackSurveyAgent = ISNULL(@callBackSurveyAgent, callBackSurveyAgent), 
    callBackSurveyClient = ISNULL(@callBackSurveyClient, callBackSurveyClient), 
    agts_notavailable = ISNULL(@agts_notavailable, agts_notavailable), 
    editableDtmf = ISNULL(@editableDtmf, editableDtmf), 
    prefijo = ISNULL(@prefijo, prefijo), 
    addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder),
    recordHold = ISNULL(@recordHold, recordHold),
    EditableContactData = ISNULL(@editableContactData, EditableContactData)
WHERE inbound_id = @inbound_id;


IF NOT EXISTS (SELECT inbound_id FROM ccinbound WHERE inbound_id <> @inbound_id AND chatDomain = @chatDomain AND chatDomain <> '''')
BEGIN
    IF @chatDomain IS NOT NULL
    BEGIN
        UPDATE ccinbound SET chatDomain = @chatDomain WHERE inbound_id = @inbound_id
    END
END
ELSE
BEGIN
    UPDATE ccinbound SET chatDomain = '''' WHERE inbound_id = @inbound_id
    set @domainInUse = 1
END


IF @ShowCalifWnd = 1
BEGIN
    IF EXISTS (SELECT cam_id FROM ccCalifCamp WHERE cam_id = @inbound_id AND tipo = 0)
    BEGIN
        UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inbound_id;
        SET @returnValue = 1
    END
    ELSE
    BEGIN
        SET @returnValue = 0
    END
END;
ELSE
    UPDATE ccInbound SET ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd) WHERE inbound_id = @inbound_id;



IF(@chat <> 5) 
BEGIN
    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
    Create table #ccInboundTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )
    
    IF(@isCreating > 0) EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid, @tableTemp=''#ccInboundTable'';

    DELETE FROM #ccInboundTable WHERE columnInfo IN (''bnocturno'');

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
        CASE
            WHEN @chat = 1 THEN 63
            ELSE 60 END,
        3, 
        CCIT.identifierInfo,
        CASE WHEN CCIT.identifierInfo IS NOT NULL AND CCIT.identifierInfo <> '''' THEN
            CASE 
                WHEN CCIT.identifierInfo IN (''IN_DESTINATION_WAIT_TIME'', ''IN_DESTINATION_QUEUE_TIME'', ''IN_DESTINATION_OUT_SERVIVE'', ''IN_DESTINATION_OUT_SCHEDULE'') THEN
                    CASE WHEN CCIT.dataInfo = ''VOICEMAIL'' 
                        THEN ''COMMON_VOICE_MAIL'' 
                        ELSE 
                            CASE WHEN CCIT.dataInfo IS NOT NULL THEN CCIT.dataInfo ELSE ''T&COMMON_NONE'' END 
                        END
                WHEN CCIT.identifierInfo IN (''IN_RECORD_ON_HOLD'',''IN_PLAY_QUEUE_ORDER'', ''IN_STOP_RECORDING'', ''IN_SHOW_DISPOSITIONS'', ''IN_CALL_KEY'', ''IN_CONDUCT_CALLBACK_SURVEY'', ''IN_RECEIVE_DTMF_TONES'', ''IN_CALL_BACK'', ''EDIT_CALL_DATASET'') THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_ENABLED'' ELSE ''COMMON_DISABLED'' END
                WHEN CCIT.identifierInfo = ''IN_CONDUCT_SURVEY'' THEN
                    CASE WHEN CCIT.dataInfo = 1 THEN ''COMMON_CALLBACK'' ELSE ''COMMON_IMMEDIATE'' END
                ELSE CCIT.dataInfo END
        ELSE '''' END, 
        (SELECT [descripcion] FROM ccInbound WHERE inbound_id = @inbound_id)
    FROM #ccInboundTable AS CCIT;

    EXEC InsertLogAdminGalatea @action=3, @tableName = ''ccInbound'', @columnNameId = ''Inbound_id'', @valueId = @inbound_id, @userId = @userid;

    IF OBJECT_ID(N''tempdb..#ccInboundTable'') IS NOT NULL DROP TABLE #ccInboundTable
END

IF @chat = 5 
BEGIN
    IF NOT EXISTS (SELECT inboundId FROM contactMeanIn WHERE inboundId = @inbound_id) 
    BEGIN
        INSERT INTO contactMeanIn (meanContactTypeId, name, inboundId, isActive) values (@chat, @descripcion, @inbound_id, (select status from ccInbound where Inbound_id = @inbound_id));

        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        VALUES (
            (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idarea),
            getDate(), 
            (SELECT [Login] FROM ccUsers WHERE User_id = @userid), 
            40, 
            3,'''','''', 
            @descripcion);
    END
END;

if (@domainInUse = 1)
BEGIN
    RAISERROR(''Domain already in another ACD Group'', 15, 4)
END

if(@returnValue <> 2)
    SELECT @returnValue
ELSE
    SELECT 2
RETURN(0)

SET NOCOUNT OFF
    ';
EXEC(@sql)   

--------------------------------------------- ulises begin -----------------------------------------------------------------------
        
                --------------------------------------------- ulises End -------------------------------------------------------------------------
                -----------------------------------------------------BEGIN Carlos Chavez ----------------------------------------------------------------

        SET @process = 'DROP INDEX ccoCallBacks.IX_ccoCallBacks2'
        SET @sql = 'if exists (select * from sys.indexes where name = N''IX_ccoCallBacks2'' and object_id = OBJECT_ID(N''ccoCallBacks''))
                begin
                        DROP INDEX ccoCallBacks.IX_ccoCallBacks2
                end'
        EXEC(@sql);

        SET @process = 'DROP INDEX ccoCallBacks.IX_ccoCallBacks3'
        SET @sql = 'if exists (select * from sys.indexes where name = N''IX_ccoCallBacks3'' and object_id = OBJECT_ID(N''ccoCallBacks''))
                begin
                        DROP INDEX ccoCallBacks.IX_ccoCallBacks3
                end'
        EXEC(@sql);

        SET @process = 'DROP INDEX ccoCallBacks.IX_ccoCallBacks4'
        SET @sql = 'if exists (select * from sys.indexes where name = N''IX_ccoCallBacks4'' and object_id = OBJECT_ID(N''ccoCallBacks''))
                begin
                        DROP INDEX ccoCallBacks.IX_ccoCallBacks4
                end'
        EXEC(@sql);

        SET @process = 'DROP INDEX ccoCallBacks.IX_ccoCallBacks5'
        SET @sql = 'if exists (select * from sys.indexes where name = N''IX_ccoCallBacks5'' and object_id = OBJECT_ID(N''ccoCallBacks''))
                begin
                        DROP INDEX ccoCallBacks.IX_ccoCallBacks5
                end'
        EXEC(@sql);

        SET @process = 'CREATE INDEX IX_cctipoSubCalifRel_calif_id_califSub_id_tipoSubRel'
        SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_cctipoSubCalifRel_calif_id_califSub_id_tipoSubRel'' and object_id = OBJECT_ID(N''cctipoSubCalifRel''))
        begin
                CREATE UNIQUE NONCLUSTERED INDEX IX_cctipoSubCalifRel_calif_id_califSub_id_tipoSubRel
                ON dbo.cctipoSubCalifRel (calif_id, califSub_id, tipoSubRel)
        end';
        EXEC(@sql);

        SET @process = 'CREATE INDEX IX_ccoCallBacks_user_id_cal_fusercallback'
        SET @sql = 'if not exists (select * from sys.indexes where name = N''IX_ccoCallBacks_user_id_cal_fusercallback'' and object_id = OBJECT_ID(N''ccoCallBacks''))
        begin
                CREATE NONCLUSTERED INDEX [IX_ccoCallBacks_user_id_cal_fusercallback] 
                ON [dbo].[ccoCallBacks] ([user_id], [cal_fusercallback])
        end';
        EXEC(@sql);


        SET @process = 'ALTER PROCEDURE [dbo].[ccsp_AgentGetCalificaciones]'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AgentGetCalificaciones] 
@inOut  TINYINT,                                --0 in, 1 out
@cam_id INT, 
@isXml  BIT = 1
AS
SET NOCOUNT ON;
DECLARE @sql NVARCHAR(MAX);
IF @inOut = 0
BEGIN
    IF EXISTS
    (
        SELECT top 1 calif.calif_id
        FROM ccTipoCalif AS calif JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND tipo = 0
        WHERE cam_id = @cam_id 
    )
    BEGIN
        DECLARE @relationCamId INT;

        SELECT @relationCamId = cam_id FROM ccInbound WHERE Inbound_id = @cam_id;
        IF @relationCamId IS NULL
        BEGIN
                        SET @relationCamId = 0
        END;

        SET @sql = '';WITH disposition
                AS (SELECT DISTINCT
             1 AS tag,NULL AS parent,calif.calif_id AS "selection!1!id",calif.Description AS "selection!1!string",calif.orden AS "selection!1!califorden",
                         ISNULL(calif.EndConversation,0) AS "selection!1!endConversation",NULL AS "subSelection!2!id",
                         NULL AS "subSelection!2!string",NULL AS "subSelection!2!orden",NULL AS "subSelection!2!endConversation",
                         ISNULL(calif.CanReprogram,0) AS "selection!1!canReprogram",NULL AS "subSelection!2!canReprogram"
        FROM ccTipoCalif AS calif
        INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND camp.cam_id = @cam_id AND camp.tipo = 0
        WHERE calif.CanReprogram = 0 OR calif.CanReprogram = 1 AND @relationCamId > 0
        UNION
        SELECT DISTINCT
             2 AS tag,1 AS parent,calif.calif_id AS "selection!1!id",NULL AS "selection!1!string",calif.orden AS "selection!1!califorden",
                         ISNULL(calif.EndConversation,0) AS "selection!1!endConversation",sb.califsub_id AS "subSelection!2!id",
                         sb.califSubDesc AS "subSelection!2!string",CAST(sb.orden AS INT) AS "subSelection!2!orden",
                         ISNULL(sb.EndConversation,0) AS "subSelection!2!endConversation",NULL AS "selection!1!canReprogram",ISNULL(sb.CanReprogram,0) AS "subSelection!2!canReprogram"
        FROM ccTipoCalif AS calif
        INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND camp.cam_id = @cam_id AND camp.tipo = 0
        LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 1
        LEFT JOIN ccTipoCalifSub AS sb ON rel.califsub_id = sb.califsub_id
        WHERE sb.califsub_id IS NOT NULL AND (sb.CanReprogram = 0 OR sb.CanReprogram = 1 AND @relationCamId > 0))'';

        IF @isXml = 1
        BEGIN
                        SET @sql = @sql + '' select * from disposition order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type '';
        END;
        ELSE
        BEGIN
                        SET @sql = @sql + ''select 
                tag as Tag, isnull(parent,0) as Parent, "selection!1!id" as Id,isnull("selection!1!string",'''''''') as Description,
                cast("selection!1!califorden" as int) as Orden, 
                "selection!1!endConversation" EndConversation, isnull("subSelection!2!id",0) as SubId,
                isnull("subSelection!2!string",'''''''') as SubDescription, 
                cast(isnull("subSelection!2!orden",0) as int) as SubOrden,   
                --CAST(  ROW_NUMBER() OVER(PARTITION BY parent ORDER BY "subSelection!2!orden" ASC) as INT) AS SubOrden,
                isnull("subSelection!2!endConversation",0) as SubEndConversation, 
                isnull("selection!1!canReprogram",0) as CanReprogram,isnull("subSelection!2!canReprogram",0) as SubCanReprogram
                FROM disposition'';
        END;
        --PRINT @sql

        EXEC sp_executesql 
            @sql, 
            N''@cam_id int, @InOut tinyint,@relationCamId int'', 
            @cam_id, 
            @inOut, 
            @relationCamId;
    END;
    RETURN 0;
END;
ELSE
BEGIN
        IF @inOut = 1
        BEGIN
                IF EXISTS
                (
                        SELECT top 1 calif.calif_id
                        FROM ccTipoCalifOUT AS calif JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND tipo = 1
                        WHERE cam_id = @cam_id 
                )
                BEGIN
                        SET @sql = '';WITH disposition
                AS (SELECT DISTINCT
                   1 AS tag,NULL AS parent,calif.calif_id AS "selection!1!id",calif.Description AS "selection!1!string",calif.keepDial AS "selection!1!keepOnDial",
                   calif.orden AS "selection!1!califorden",ISNULL(calif.finishPreview,0) AS "selection!1!finishPreview",ISNULL(calif.finishRecordPreview,0) AS "selection!1!finishRecordPreview",
                   NULL AS "subSelection!2!id",NULL AS "subSelection!2!string",NULL AS "subSelection!2!keepOnDial",
                   NULL AS "subSelection!2!orden",ISNULL(calif.CanReprogram,0) AS "selection!1!canReprogram",NULL AS "subSelection!2!canReprogram"
                FROM ccTipoCalifOUT AS calif
                INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND tipo = 1
                WHERE cam_id = @cam_id 
                UNION
                SELECT DISTINCT
                   2 AS tag,1 AS parent,calif.calif_id AS "selection!1!id",NULL AS "selection!1!string",NULL AS "selection!1!keepOnDial",calif.orden AS "selection!1!califorden",ISNULL(calif.finishPreview,0) AS
                   "selection!1!finishPreview", ISNULL(calif.finishRecordPreview,0) AS "selection!1!finishRecordPreview", sb.califsub_id AS "subSelection!2!id",sb.califSubDesc AS "subSelection!2!string", 
                   sb.keepDial AS "subSelection!2!keepOnDial",CAST(sb.orden AS INT) AS "subSelection!2!orden",NULL AS"selection!1!canReprogram",
                   ISNULL(sb.CanReprogram,0) AS "subSelection!2!canReprogram"
                FROM ccTipoCalifOUT AS calif
                INNER JOIN ccCalifCamp AS camp ON camp.calif_id = calif.calif_id AND tipo = 1
                LEFT JOIN cctipoSubCalifRel AS rel ON calif.calif_id = rel.calif_id AND rel.tipoSubRel = 0
                LEFT JOIN ccTipoCalifSubOUT AS sb ON rel.califsub_id = sb.califsub_id
                WHERE cam_id = @cam_id AND sb.califsub_id IS NOT NULL)'';

                        IF @isXml = 1
                        BEGIN
                                SET @sql = @sql + '' select * from disposition order by "selection!1!califorden", "selection!1!id", "subSelection!2!orden" for xml explicit, type '';
                        END;
                        ELSE
                        BEGIN
                                SET @sql = @sql + '' SELECT tag AS Tag,ISNULL(parent,0) AS Parent,"selection!1!id" AS Id,ISNULL("selection!1!string",'''''''') AS Description,
                ISNULL("selection!1!keepOnDial",'''''''') AS KeepOnDial,
                --"selection!1!califorden" AS Orden,
                CAST(  ROW_NUMBER() OVER(ORDER BY "selection!1!califorden" ASC, "selection!1!string" ASC) as int) AS Orden,
                "selection!1!finishPreview" AS
                FinishPreview,
                "selection!1!finishRecordPreview" AS
                FinishRecordPreview,
                ISNULL("subSelection!2!id",0) AS SubId,ISNULL("subSelection!2!string",'''''''') AS SubDescription
                ,ISNULL("subSelection!2!keepOnDial",0) AS SubKeepOnDial,
                ISNULL("subSelection!2!orden",0) AS SubOrden,    
                ISNULL("selection!1!canReprogram",0) AS CanReprogram,ISNULL("subSelection!2!canReprogram",0) AS SubCanReprogram
                FROM disposition'';
                        END;
                        --PRINT @sql

                        EXEC sp_executesql 
                                @sql, 
                                N''@cam_id int, @InOut int'', 
                                @cam_id, 
                                @inOut;
                END;
                RETURN 0;
        END;
        ELSE
        BEGIN
                IF @inOut = 10
                BEGIN
                        SELECT DISTINCT 
                                S.califSub_id, S.califSubDesc, orden
                        FROM cctipoSubCalifRel AS R
                                JOIN cctipoCalifSub AS S ON R.califSub_id = S.califSub_id
                        WHERE R.tipoSubRel = 1
                                AND S.califSub_Status = 1
                                AND R.calif_id = @cam_id
                                ORDER BY S.orden, S.califSubDesc;
                        RETURN 0;
                END;
                ELSE
                BEGIN
                        IF @inOut = 11
                        BEGIN
                                SELECT DISTINCT 
                                        S.califSub_id, S.califSubDesc, orden
                                FROM cctipoSubCalifRel AS R
                                        JOIN cctipoCalifSubOut AS S ON R.califSub_id = S.califSub_id
                                WHERE R.tipoSubRel = 0
                                        AND S.califSubOut_Status = 1
                                        AND R.calif_id = @cam_id
                                        ORDER BY S.orden, S.califSubDesc;
                                RETURN 0;
                        END;
                END;
        END;
END;
SET NOCOUNT OFF;'
        EXEC(@sql);

                ----------------------------------------------------- END Carlos Chavez  ----------------------------------------------------------------
        ----------------------------------------------------- BEGIN Uriel Cabrera  ----------------------------------------------------------------
    SET @process = 'CREATE setting 261 - Admin Machine Location'
        SET @sql = 'IF NOT EXISTS (Select * from ccSettings2 where setting_id = 261) begin
                    INSERT INTO ccSettings2 VALUES (261, '''', ''UbicaciÃ³n del AdminMachine'',
                        1, ''GRL'', ''IP o Hostname del servidor donde se encuentra el AdminMachine'',
                        ''AdminMachine location'',0,
                        ''^(([01]?\d\d?|2[0-4]\d|25[0-5])\.){3}(25[0-5]|[01]?\d\d?|2[0-4]\d)$'')
                end'
        EXEC(@sql);

    SET @process = 'DROP PROCEDURE ccsp_GalateaSettingsExtend'
        SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaSettingsExtend'')
                begin
                    DROP PROCEDURE ccsp_GalateaSettingsExtend;
                end'
        EXEC(@sql);

    SET @process = 'CREATE PROCEDURE ccsp_GalateaSettingsExtend'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaSettingsExtend]
                    @Ids VARCHAR(1000) = NULL
                AS
                BEGIN
                    SET NOCOUNT ON;

                    DECLARE @IdList TABLE (Id SMALLINT);
                    DECLARE @Delimiter CHAR(1) = '','';
                    DECLARE @Pos INT;
                    DECLARE @NextPos INT;
                    DECLARE @Id VARCHAR(255);

                    SET @Ids = LTRIM(RTRIM(@Ids))+ '','';
                    SET @Pos = CHARINDEX(@Delimiter, @Ids, 1);

                    WHILE (@Pos > 0)
                    BEGIN
                        SET @Id = LTRIM(RTRIM(LEFT(@Ids, @Pos - 1)));
                        IF (@Id != '''')
                        BEGIN
                            INSERT INTO @IdList (Id) VALUES (@Id);
                        END
                        SET @Ids = RIGHT(@Ids, LEN(@Ids) - @Pos);
                        SET @Pos = CHARINDEX(@Delimiter, @Ids, 1);
                    END;

                    SELECT [setting_id], [valor]
                    FROM
                    (
                        SELECT [setting_id], [valor], 1 AS [Tabla]
                        FROM [dbo].[ccSettings] WITH(NOLOCK)
                        WHERE ([setting_id] IN (SELECT Id FROM @IdList WHERE Id <= 255) and Status = 1 ) or Tipo = ''AGT''
                        UNION ALL
                        SELECT [setting_id], [valor], 2 AS [Tabla]
                        FROM [dbo].[ccSettings2] WITH(NOLOCK)
                        WHERE [setting_id] IN (SELECT Id FROM @IdList WHERE Id > 255) and Status = 1
                    ) AS AllSettings
                    ORDER BY [setting_id], [Tabla];

                END'
        EXEC(@sql);

    SET @process = 'DROP PROCEDURE ccsp_GalateaSetSocketConfiguration'
        SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaSetSocketConfiguration'')
                begin
                    DROP PROCEDURE ccsp_GalateaSetSocketConfiguration;
                end'
        EXEC(@sql);

    SET @process = 'CREATE PROCEDURE ccsp_GalateaSetSocketConfiguration'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaSetSocketConfiguration]
                @ip varchar(300)
                    AS
                set nocount on
                    update ccSettings2 set valor= @ip where setting_id = 261'
        EXEC(@sql);

    SET @process = 'DROP PROCEDURE ccsp_GalateaSettingsExtendById'
        SET @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaSettingsExtendById'')
                begin
                    DROP PROCEDURE ccsp_GalateaSettingsExtendById;
                end'
        EXEC(@sql);

    SET @process = 'CREATE PROCEDURE ccsp_GalateaSettingsExtendById'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaSettingsExtendById]
                                                @Id smallint = NULL
                                        AS
                                        BEGIN

                                                SET NOCOUNT ON;

                                                SELECT [setting_id]
                                                                ,[valor]
                                                                ,[Status]
                                                                ,[Tipo]
                                                                ,[bLoadSettings]
                                                        FROM [dbo].[ccSettings2] WITH(NOLOCK)
                                                        WHERE (@Id IS NULL OR [setting_id]=@Id)

                                        END'
        EXEC(@sql);

        ----------------------------------------------------- END Uriel Cabrera  ----------------------------------------------------------------
        ----------------------------------------------------- START Jonathan Ramirez  ----------------------------------------------------------------
        SET @process = '1 - JR 1211.0.14, 15 -> SP ccsp_ConversationOutWASave, Valida si la conversaciÃ³n de entrada existe. Se valida que el usuario exista si no mandar pendiente por asignar'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationOutWASave] 
@action             INT
, @conversationId     INT         = 0
, @campId             INT         = NULL        
, @phoneCamp          VARCHAR(50) = NULL
, @clientId           VARCHAR(25) = NULL
, @conversationStatus SMALLINT    = 0
, @tChatting          FLOAT       = 0
, @tWrapUp            SMALLINT    = 0
, @finishedBy         TINYINT     = 0
, @onQueue            BIT         = NULL
, @tQueue             SMALLINT    = 0
, @tTimeout           INT         = 0
, @disposition        SMALLINT    = 0
, @subDisposition     SMALLINT    = 0
, @agentId            INT         = 0

AS
BEGIN
    SET NOCOUNT ON;
                        
    declare @conversationIdTemporal     INT;

IF @action = 1 BEGIN --new Conversation
    select @phoneCamp= number from ccWhatsAppNumbers where camp_id= @campId
                            
    if @phoneCamp is null or @phoneCamp='''' begin
        select 0 as [ConversationId],0 as [MessageId]
        return(0)
    end
    DECLARE @dateNow DATETIME;
    SET @dateNow = DATEADD(HOUR, -23, GETDATE());


    declare @existsConversationOut bit
    declare @existsConversation bit
    set @existsConversationOut =0
    set @existsConversation =0

    
    
    if not exists (select * from ccWhatsAppConversationsOut with(nolock) where
    phoneCamp = @phoneCamp and clientId = @clientId and finishedBy=0 AND requestDate <= @dateNow) 
    begin       
        set @existsConversationOut=0
    end 
    else begin
        set @existsConversationOut=1
        UPDATE ccWhatsAppConversationsOut
        SET finishedBy = 2 ,conversationStatus=17
        WHERE finishedBy = 0  AND requestDate <= @dateNow
        and phoneCamp = @phoneCamp and clientId = @clientId
    end
    
    if not exists (select * from ccWhatsAppConversations with(nolock) where
    phoneACD = @phoneCamp and clientId = @clientId and finishedBy=0 AND requestDate <= @dateNow) 
    begin       
        set @existsConversation=0
    end 
    else begin
        set @existsConversation=1
        UPDATE ccWhatsAppConversations
        SET finishedBy = 2 ,conversationStatus=17
        WHERE finishedBy = 0  AND requestDate <= @dateNow
        and phoneACD = @phoneCamp and clientId = @clientId
    end
    
    if not exists (select 1 from ccWhatsAppConversationsOut with(nolock) 
        where phoneCamp = @phoneCamp and clientId = @clientId 
        and finishedBy = 0 and requestDate > @dateNow) 
    begin
        set @existsConversationOut=0
    end
    else begin
        set @existsConversationOut=1
    end
    
    if not exists (select 1 from ccWhatsAppConversations with(nolock) 
        where phoneACD = @phoneCamp and clientId = @clientId 
        and finishedBy = 0 and requestDate > @dateNow) 
    begin
        set @existsConversation=0
    end
    else begin
        set @existsConversation=1
    end
    
    if @existsConversationOut=0
    begin
        if @existsConversation = 0
        begin
            INSERT INTO [ccWhatsAppConversationsOut]
            ([camId] , [phoneCamp], clientId, conversationStatus, tChatting
            , tWrapUp, finishedBy, onQueue, tQueue, requestDate
            , tTimeout, disposition, subDisposition, agentId)
            VALUES(@campId, @phoneCamp, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, 
            @onQueue, @tQueue, GETDATE(), @tTimeout, @disposition, @subDisposition, @agentId);
                        
            SELECT @conversationIdTemporal = SCOPE_IDENTITY();    
            SELECT @conversationIdTemporal AS [ConversationId],0 as [MessageId]
        end
        else begin
            select A.descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId
            ,B.conversationId as conversationIdExists
            ,case when C.Login  is null then ''Pendiente por asignar'' else C.Login end Username
            FROM ccInbound A INNER JOIN ccWhatsAppConversations B WITH(NOLOCK)
            ON B.clientId = @clientId AND B.finishedBy = 0 and B.inboundId=A.Inbound_id
            left JOIN ccUsers C ON B.agentId = C.User_id;
        end  
    end
    else begin
        select A.cam_descripcion CamDescription, B.requestDate RequestDate, B.agentId UserId
        ,B.conversationId as conversationIdExists
        ,case when C.Login  is null then ''Pendiente por asignar'' else C.Login end Username
        FROM ccCamps A INNER JOIN ccWhatsAppConversationsOut B WITH(NOLOCK)
        ON B.clientId = @clientId AND B.finishedBy = 0 and B.camId=A.cam_id
        left JOIN ccUsers C ON B.agentId = C.User_id;
    end  
END 
ELSE IF @action = 2 -- Get Outbound Templates
BEGIN
    IF @campId IS NOT NULL
    BEGIN
        DECLARE @AsociatedNumber VARCHAR(30) = (SELECT number from ccWhatsAppNumbers WHERE @campId = camp_id);
        SELECT * FROM ccWhatsAppOutboundTemplates WHERE AsociatedNumber = @AsociatedNumber AND Status = 1;
    END
END
END'
        EXEC(@sql);

        SET @process = '2 - JR 1211.0.14 -> SP ccsp_ConversationWASave, Se agrega update a la info del resumen de whats IN'
        SET @sql = '
        ALTER PROCEDURE [dbo].[ccsp_ConversationWASave] @action             INT
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
(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock)
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

            DECLARE @RequestDate DATETIME = NULL;
            SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversations WITH(NOLOCK) WHERE conversationId = @conversationId;

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
            , requestDate
            )
            VALUES(@inboundId, @phoneACD, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
            SELECT @conversationIdNew = SCOPE_IDENTITY();

            INSERT INTO ccWhatsAppConversationsRelationship (conversationIdBefore
                                                                , conversationIdAfter)
                VALUES (@conversationId, @conversationIdNew);
            --Save new request by reassign
UPDATE ccWAOperatingSummary SET Request = (Request + 1), Assigned = (Assigned - 1),EndedBySystem=EndedBySystem+1
WHERE InboundId = @inboundId

        EXEC ccsp_ConversationWASave @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationship with(nolock) where conversationIdBefore = @conversationId;
        RETURN(0);
    END;
END;

ELSE IF @action = 2
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
    , finishedBy = case when @conversationStatus in(4,10,17,18) then 2
    when @conversationStatus in(11) then 1
    else 0 end
    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

        WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
    BEGIN
        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=5

    IF @conversationStatus in(4,10,11,13,17,18) BEGIN
            DECLARE @conversationDateTemp INT;
            select @inboundId = inboundId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
            from ccWhatsAppConversations with(nolock) where conversationId = @conversationId;

            IF @conversationStatus = 13 BEGIN
                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam where NumberClient = @clientId) BEGIN
                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@inboundId, @agentId, @conversationId, @clientId);
                END
            END
            ELSE IF @conversationStatus in(4,10,17,18) BEGIN --Save conversation Ended by system
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

ELSE IF @action = 3
BEGIN --save conversation Status
UPDATE ccWhatsAppConversations SET conversationStatus = @conversationStatus
    WHERE conversationId = @conversationId;
END;

ELSE IF @action = 4 BEGIN --save messages from conversation
IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversations A with(nolock) WHERE A.conversationId=@conversationId)
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
SELECT @inboundId = inboundId FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
        UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue + 1) WHERE InboundId = @inboundId
    END;

ELSE IF @action = 6
BEGIN --save agent, assigdate and tqueue
    declare @agentIdTmp int
    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversations A with(nolock) where A.conversationId = @conversationId

    IF (@agentIdTmp is null or @agentIdTmp=0)
    BEGIN
        UPDATE ccWhatsAppConversations
                SET agentId = @agentId,
                assignDate = getdate(),
                conversationStatus = @conversationStatus
                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
        WHERE conversationId = @conversationId;

        SELECT @conversationId as conversationId
SELECT @inboundId = inboundId,  @onQueue = onQueue FROM ccWhatsAppConversations with(nolock) where conversationId=@conversationId;
declare @onQueueInt int

    IF @onQueue = 1 BEGIN
        UPDATE ccWAOperatingSummary SET OnQueue = (OnQueue - 1),@onQueueInt =OnQueue WHERE InboundId = @inboundId
        if @onQueueInt<=0 or exists(select * from ccWAOperatingSummary WHERE InboundId = @inboundId and OnQueue<0)begin

            select          
            @onQueueInt=count(case when onQueue =1 then 1 end)
            from ccWhatsAppConversations with(nolock)
            where inboundId= @inboundId
            and requestDate>=convert(date,getdate(),121)

            UPDATE ccWAOperatingSummary SET OnQueue = @onQueueInt WHERE InboundId = @inboundId

        end

    END
    END
END;

ELSE IF @action = 7
    BEGIN --update price message
        UPDATE ccWAMessagesConversations
                SET price = @price,
                    currency = @currency
        WHERE messageId = @messageId;
    END;

ELSE IF @action = 8
    BEGIN --update status message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversations
                    SET messageStatus = @messageStatus
            WHERE messageId = @messageId;
        END;
    END;

ELSE IF @action = 9
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

ELSE IF @action = 10
    BEGIN --drop and insert register by conversationID
        DELETE FROM ccLastMessageAgentByConversation WHERE conversationId = @conversationId;
    END;

ELSE IF @action = 11
    BEGIN --register desconnection agent by conversationID
        UPDATE ccLastMessageAgentByConversation SET desconnectionAgent = getDate() WHERE conversationId = @conversationId;
    END;

ELSE IF @action = 12
    BEGIN --Obtain conversationsWA post MCS reset

        declare @disconnectionIdTemp int = (select top 1 disconnectionId from ccDisconnectionMCS where timeStampConnection is null order by timeStampDisconnection desc);
        UPDATE ccDisconnectionMCS SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

        declare @from as datetime;-- = ''01-07-2022'';
        select @from = convert(datetime,convert(varchar(11),getdate()))
        set @from=DATEADD(dd,-1,@from);
            select A.conversationId, A.inboundId, A.phoneACD, A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, A.onQueue, A.agentId, isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
            ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
            from ccWhatsAppConversations A with(nolock)
            left join ccWAMessagesConversations B on A.conversationId = B.conversationId
            left join ccDisconnectionMCS C on C.disconnectionId = @disconnectionIdTemp
            where A.requestDate >= @from 
                and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
            order by agentId desc, requestDate,timeStampMessage, inboundId, clientId 
    END;
ELSE IF @action = 13
    BEGIN ---Obtain agents ON STATUS READY
        WITH agents
        AS(
            SELECT c.User_id, c.fecha, c.currentStatus
            FROM ccLogAgentesDia c
            INNER JOIN 
            (
                SELECT User_id, MAX(fecha) max_time
                FROM ccLogAgentesDia with(nolock)
                where fecha>=CONVERT(date,getdate(),121)
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

ELSE IF @action = 14
    BEGIN --register desconnection MCS
        INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
    END;

ELSE IF @action = 15
    BEGIN --update content message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversations A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversations
                    SET content = @content
            WHERE messageId = @messageId;
        END;
    END;

ELSE IF @action = 16
    BEGIN --update agent status for reassigning error message
            UPDATE ccWhatsAppConversations
            SET IsAgentLoggingOut = @IsAgentLoggingOut
            WHERE conversationId = @conversationId;
    END;

ELSE IF @action = 18 BEGIN
        DECLARE @dateNow DATETIME;
        SET @dateNow = DATEADD(HOUR, -23, GETDATE());

        UPDATE ccWhatsAppConversations
        SET finishedBy = 2, conversationStatus=17
        WHERE finishedBy = 0 AND requestDate <= @dateNow    
    END;
END;'
        EXEC(@sql);

        SET @process = '3 - JR 1211.0.14 -> SP ccsp_ConversationWASaveOut, Se agrega update a la info del resumen de whats OUT
        se agrega with(nolock), se valida para el modo finalizar las conversaciones'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ConversationWASaveOut] @action             INT
, @conversationId     INT         = 0
, @camId          SMALLINT    = NULL
, @phoneCam           VARCHAR(50) = NULL
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
    IF NOT EXISTS (SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A with(nolock)
    WHERE A.conversationId = @conversationId)
    BEGIN
        INSERT INTO [ccWhatsAppConversationsOut]
        (camId, phoneCamp , clientId, conversationStatus, tChatting , tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId)
        VALUES(@camId, @phoneCam, @clientId, @conversationStatus, @tChatting, @tWrapUp, @finishedBy, @onQueue, @tQueue, @tTimeout, @disposition, @subDisposition, @agentId);
        
        
        SELECT @conversationId = SCOPE_IDENTITY();
        SELECT @conversationId AS ConversationId;

--        Save new request
        IF NOT EXISTS (SELECT camId FROM ccWAOperatingSummaryOut WHERE camId = @camId) BEGIN
           INSERT INTO ccWAOperatingSummaryOut (camId, Request) VALUES (@camId, 1);
        END
        ELSE BEGIN
            UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1) WHERE camId = @camId
        END
        RETURN(0);
    END
    ELSE BEGIN
        DECLARE @conversationStatusTemp INT = @conversationStatus;
        IF @conversationStatus in(17,18) BEGIN
            SET @conversationStatusTemp = 1
        END 

        DECLARE @RequestDate DATETIME = NULL;
        SELECT @RequestDate = [requestDate] FROM ccWhatsAppConversationsOut WITH(NOLOCK) WHERE conversationId = @conversationId;

        INSERT INTO [ccWhatsAppConversationsOut]
            (camId, phoneCamp, clientId, conversationStatus, tChatting, tWrapUp, finishedBy, onQueue, tQueue, tTimeout, disposition, subDisposition, agentId, requestDate)
        VALUES(@camId, @phoneCam, @clientId, @conversationStatusTemp, @tChatting, @tWrapUp, @finishedBy, @onQueue, 
            @tQueue, @tTimeout, @disposition, @subDisposition, @agentId, @RequestDate);
        SELECT @conversationIdNew = SCOPE_IDENTITY();

        INSERT INTO ccWhatsAppConversationsRelationshipOut (conversationIdBefore, conversationIdAfter)
        VALUES (@conversationId, @conversationIdNew);
        --Save new request by reassign
        UPDATE ccWAOperatingSummaryOut SET Request = (Request + 1), Assigned = (Assigned - 1),EndedBySystem=EndedBySystem+1
        WHERE camId = @camId

    EXEC ccsp_ConversationWASaveOut @action = 2, @conversationId = @conversationId, @conversationStatus = @conversationStatus

    SELECT conversationIdAfter as ConversationId FROM ccWhatsAppConversationsRelationshipOut where conversationIdBefore = @conversationId;
    RETURN(0);
END;
END;

else IF @action = 2
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
    
    UPDATE ccWhatsAppConversationsOut
    SET
    conversationStatus = @conversationStatus
    , finishedBy = case when @conversationStatus in(4,10,17,18) then 2
    when @conversationStatus in(11) then 1
        else 0 end
    , tConversation =  case when @conversationStatus = 10 OR conversationDate is null then 0 else DATEDIFF(ss, conversationDate, GETDATE()) end
    ,tQueue = case when @conversationStatus = 10 then DATEDIFF(ss,requestDate,getdate()) else tQueue end
    ,onQueue = case when @conversationStatus = 10 then 1 else onQueue end
    WHERE conversationId IN (SELECT conversationId FROM @TablaTemp);

    WHILE exists(SELECT conversationId FROM @TablaTemp where status=0)
    BEGIN
        select top 1 @conversationIdTemp=conversationId FROM @TablaTemp where status=0
        exec ccsp_CreateNodeMultimedia @conversationId=@conversationIdTemp, @type=6

        IF @conversationStatus in(4,10,11,13,17,18) BEGIN
            DECLARE @conversationDateTemp INT;
            select @camId = CamId, @agentId = agentId, @clientId = clientId, @conversationDateTemp = case when conversationDate is not null then 1 else 0 end 
            from ccWhatsAppConversationsOut where conversationId = @conversationId;

            IF @conversationStatus = 13 BEGIN
                IF NOT EXISTS (SELECT NumberClient from ccWhatsAppSpam with(nolock) where NumberClient = @clientId) BEGIN
                    INSERT INTO ccWhatsAppSpam (InboundId, AgentId, ConversationId, NumberClient) VALUES (@camId, @agentId, @conversationId, @clientId);
                END
            END
            ELSE IF @conversationStatus in(4,10,17,18) BEGIN --Save conversation Ended by system
                IF @conversationDateTemp > 0 BEGIN
                    UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
                END
                ELSE BEGIN
                        UPDATE ccWAOperatingSummaryOut SET EndedBySystem = (EndedBySystem + 1) WHERE CamId = @camId
                END
            END
            ELSE IF @conversationStatus = 11 BEGIN --Save conversation Ended by AGENT
                UPDATE ccWAOperatingSummaryOut SET Attended = (Attended + 1), Assigned = (Assigned - 1) WHERE CamId = @camId
            END
        END
        update @TablaTemp set status=1 where conversationId=@conversationIdTemp
    END

END;

else IF @action = 3
BEGIN --save conversation Status
    UPDATE ccWhatsAppConversationsOut SET conversationStatus = @conversationStatus WHERE conversationId = @conversationId;
END;

else IF @action = 4 BEGIN --save messages from conversation
    IF EXISTS(SELECT A.conversationId conversationId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId)
        AND NOT EXISTS(SELECT A.messageId messageId FROM ccWAMessagesConversationsOut A with(nolock) WHERE A.messageId=@messageId)
    BEGIN
        IF (@originType = ''Agent'' OR @originType = ''Admin'') AND NOT EXISTS
            (SELECT messageIdUi
                FROM ccWAMessagesConversationsOut
                WHERE originType IN (''Agent'', ''Admin'')
                AND conversationId = @conversationId)
            BEGIN
                UPDATE ccWhatsAppConversationsOut
                    SET FirstMessageAgent = @timeStampMessage
                    WHERE conversationId = @conversationId;
            END

        INSERT INTO [ccWAMessagesConversationsOut](
                                            messageId, messageIdUi, clientNum, vonageNum, typeMessage, content, conversationId, timeStampMessage, timeStampMessageUTC, originType, currency, price, messageStatus) values
                                            (@messageId, @messageIdUi, @clientNum, @vonageNum, @typeMessage, @content, @conversationId, @timeStampMessage, @timeStampMessageUTC, @originType, @currency, @price, @messageStatus)
        SELECT @messageId=SCOPE_IDENTITY()
       
       SELECT @camId=camId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId
        if not exists(select * from ccWAConversationsResult where camId=@camId)begin
            insert into ccWAConversationsResult values(@camId,0,0,0,0,0)
        end
        exec ccsp_ConversationWASaveOut @action=16,@messageStatus=@messageStatus,@conversationId=@conversationId
        
         SELECT @messageId as MessageId
        
        RETURN (0)
    END
    ELSE BEGIN
        SELECT 0 AS MessageId
        RETURN (0)
    END
END;

else IF @action = 5
BEGIN --save onQueue
    UPDATE ccWhatsAppConversationsOut
            SET onQueue = 1,
            conversationStatus = @conversationStatus
    WHERE conversationId = @conversationId;
    SELECT @camId = camId FROM ccWhatsAppConversationsOut where conversationId=@conversationId;
    UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue + 1) WHERE camId = @camId
END;

else IF @action = 6
BEGIN --save agent, assigdate and tqueue
    declare @agentIdTmp int
    SELECT @agentIdTmp = A.agentId FROM ccWhatsAppConversationsOut A with(nolock) where A.conversationId = @conversationId
       
        UPDATE ccWhatsAppConversationsOut
                SET agentId = @agentId,
                assignDate = getdate(),
                conversationStatus = @conversationStatus
                ,tQueue = case when onQueue = 1 then DATEDIFF(ss,requestDate,isnull(assignDate,getdate())) else 0 end
        WHERE conversationId = @conversationId;

    SELECT @conversationId as conversationId
    SELECT @camId = camId,  @onQueue = onQueue FROM ccWhatsAppConversationsOut with(nolock) where conversationId=@conversationId;

    IF @onQueue = 1 BEGIN
     UPDATE ccWAOperatingSummaryOut SET OnQueue = (OnQueue - 1) WHERE camId = @camId   
    END
END;

 Else IF @action = 7
BEGIN --update price message
    UPDATE ccWAMessagesConversationsOut SET price = @price, currency = @currency WHERE messageId = @messageId;
END;
else IF @action = 8
BEGIN --update status message
    IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A with(nolock) 
        WHERE A.messageId=@messageId) <> ''read'' 
    BEGIN
        UPDATE ccWAMessagesConversationsOut
                SET messageStatus = @messageStatus
        WHERE messageId = @messageId;
        exec ccsp_ConversationWASaveOut @action=16,@messageStatus=@messageStatus,@conversationId=@conversationId
        
    END;
END;

else IF @action = 9
BEGIN --Save last message time by conversationID
    IF (SELECT A.conversationId conversationID FROM ccLastMessageAgentByConversationOut A with(nolock) 
        WHERE A.conversationId=@conversationId) IS NULL BEGIN
        INSERT INTO ccLastMessageAgentByConversationOut (conversationId) VALUES (@conversationId)
    END;
    ELSE
        BEGIN
            UPDATE ccLastMessageAgentByConversationOut
                SET timeStampLastMessageAgent = getDate()
            WHERE conversationId = @conversationId;
        END;
END;

else IF @action = 10
BEGIN --drop and insert register by conversationID
    DELETE FROM ccLastMessageAgentByConversationOut WHERE conversationId = @conversationId;
END;

Else IF @action = 11
BEGIN --register desconnection agent by conversationID
    exec ccsp_ConversationWASaveOut @action = 9, @conversationId=@conversationId
END;

else IF @action = 12  BEGIN --Obtain conversationsWA post MCS reset
    declare @disconnectionIdTemp int = (select top 1 disconnectionId from [ccDisconnectionMCSOut] with(nolock) 
    where timeStampConnection is null order by timeStampDisconnection desc);
    UPDATE ccDisconnectionMCSOut SET timeStampConnection = GETDATE() WHERE disconnectionId = @disconnectionIdTemp;

    declare @from as datetime;
    select @from = convert(datetime,convert(varchar(11),getdate()))
    set @from=DATEADD(dd,-1,@from);
        select A.conversationId, A.camId as inboundId, A.phoneCamp as phoneACD
        , A.clientId, A.conversationStatus, A.requestDate, isnull(A.conversationDate,'''') conversationDate, isnull(A.onQueue,0) onQueue, A.agentId, 
        isnull(B.timeStampMessage,'''') timeStampMessage, isnull(B.originType,'''') originType, isnull(B.price,'''') price, isnull(B.messageIdUi,'''') messageIdUi, 
        isnull(B.messageId,'''') messageId, isnull(B.typeMessage,'''') typeMessage, isnull(B.content,'''') content, isnull(B.messageStatus,'''') messageStatus
        ,isnull(C.timeStampDisconnection,'''') timeStampDisconnection, isnull(C.timeStampConnection,'''') timeStampConnection
        from ccWhatsAppConversationsOut A with(nolock) 
        left join ccWAMessagesConversationsOut B with(nolock) on A.conversationId = B.conversationId
        left join [ccDisconnectionMCSOut] C with(nolock) on C.disconnectionId = @disconnectionIdTemp        
        where A.requestDate >= @from 
            and A.conversationStatus not in (4, 10, 11, 13, 17, 18)
        order by agentId desc, requestDate,timeStampMessage, camId, clientId 
END;
else IF @action = 13
BEGIN ---Obtain agents ON STATUS READY
    WITH agents
    AS(
        SELECT c.User_id, c.fecha, c.currentStatus
        FROM ccLogAgentesDia c
        INNER JOIN 
        (
            SELECT User_id, MAX(fecha) max_time
            FROM ccLogAgentesDia with(nolock)
            where fecha>=CONVERT(date,getdate(),121)
            GROUP BY User_id
        ) AS t
        ON c.fecha = t.max_time
        AND c.User_id=t.User_id AND currentStatus in (3,34)
    ), usersByCampigns
    AS (
        select IdCampEsp, User_id from ccRIACampEspWG A
        Inner join ccRIAWorkGroupUsers B
        on A.IDWG = B.IDWG
        Inner join contactMeanOut C
        ON A.idCampEsp = C.camp_id
        where A.IDWG = 1 and A.Tipo = 1
        AND C.meanContactTypeId = 5
    )

    select DISTINCT A.User_Id from agents A
    left join usersByCampigns B on A.User_Id = B.User_Id
END;

else IF @action = 14
BEGIN --register desconnection MCS
    INSERT INTO ccDisconnectionMCS (timeStampDisconnection) VALUES(GETDATE());
END;
ELSE IF @action = 15
    BEGIN --update content message
        IF (SELECT A.messageStatus messageStatus FROM ccWAMessagesConversationsOut A WHERE A.messageId=@messageId) <> ''read'' BEGIN
            UPDATE ccWAMessagesConversationsOut
                    SET content = @content
            WHERE messageId = @messageId;
        END;
    END;
ELSE IF @action = 16 BEGIN --update content message
    if @camId is null or @camId=0 begin 
        SELECT @camId=camId FROM ccWhatsAppConversationsOut A with(nolock) WHERE A.conversationId=@conversationId
    end
                
    if @messageStatus=''submitted'' begin
        update ccWAConversationsResult set SentMsg= SentMsg+1
    end
    else if @messageStatus=''delivered'' begin
        update ccWAConversationsResult set SentMsg= SentMsg-1,Delivered=Delivered+1
    end
    else if @messageStatus=''read'' begin
        update ccWAConversationsResult set Delivered=Delivered-1,ReadMsg=ReadMsg+1
    end
    else if @messageStatus=''rejected'' begin
        update ccWAConversationsResult set SentMsg= SentMsg-1,NotDelivered=NotDelivered+1
    end

    SELECT @messageId as MessageId
END;
ELSE IF @action = 17 BEGIN --update agent status for reassigning error message
    UPDATE ccWhatsAppConversationsOut
    SET IsAgentLoggingOut = @IsAgentLoggingOut
    WHERE conversationId = @conversationId;
END;
ELSE IF @action = 18 BEGIN
        DECLARE @dateNow DATETIME;
        SET @dateNow = DATEADD(HOUR, -23, GETDATE());

        UPDATE ccWhatsAppConversationsOut 
    SET finishedBy = 2, conversationStatus=17
        WHERE finishedBy = 0  AND requestDate <= @dateNow   
    END;
END;'
        EXEC(@sql);

        SET @process = '4.1 - JR 1211.0.14 -> VIEW InfoCampsView, Se elimina la vista en caso de existir'
        SET @sql = 'IF EXISTS(SELECT * FROM sys.views WHERE name=''InfoCampsView'')
                    BEGIN
                    DROP VIEW InfoCampsView;
                    END;'
        EXEC(@sql);

        SET @process = '4.2 - JR 1211.0.14 -> VIEW InfoCampsView, Se crea la vista'
        SET @sql = 'CREATE VIEW InfoCampsView AS

select L.cam_id, L.Campana,
                ((L.Contestan*100)/ L.Marcaciones) as pContesta,
                ((L.Ocupado*100)/ L.Marcaciones) as pOcupado,
                ((L.NoContesta*100)/ L.Marcaciones) as pNoContesta,
                ((L.FaxModem*100)/ L.Marcaciones) as pFaxModem,
                ((L.NoService*100)/ L.Marcaciones) as pNoService,
                L.Marcaciones, L.Contestan, L.Ocupado, L.NoContesta, L.FaxModem, L.NoService
                ,L.Otro,L.Cancelado,L.buzon,L.NoDialTone,L.congestion
                ,isnull(Assigned,0) As Assigned,isnull(Attended,0) As Attended,isnull(Abandon,0) As Abandoned
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
                Where fecha >  convert(smalldatetime, convert(varchar(11), getdate() ), 101)
                group by cam_id
                ) L 
                left join (select 
                cam_id
                ,count(case statuscall_id when 6 then 1 else null end) as Abandon
                ,count(*) as Contesta
                ,count(case when statuscall_id in(11, 12,15,16)  then 1 else null end) as [Assigned]
                ,count(case statuscall_id when 13 then 1 else null end) as [Attended]
                from ccoCallsOut with(nolock index(IX_ccoCallsOut_2))
                where cal_Inicio > convert(smalldatetime, convert(varchar(11), getdate() ), 101)
                group by cam_id) callsOut on L.cam_id = callsOut.cam_id'
        EXEC(@sql);
        ----------------------------------------------------- END Jonathan Ramirez  ----------------------------------------------------------------

        -----------------------Begin Frida Orta---------------------------------------------------------------------------------
    set @process = 'Delete ccsp_GalateaManageWG'
    set @sql='
        if exists (select * from sys.procedures where name = N''ccsp_GalateaManageWG'')
    begin
        DROP PROCEDURE ccsp_GalateaManageWG;
    end'
    EXEC(@sql)

        set @process = 'CW-8569 Create sp ccsp_GalateaManageWG se modifica condiciÃ³n option= 3 se cambia < por <= '
    set @sql='CREATE PROCEDURE ccsp_GalateaManageWG
@option smallint,
@IDWG smallint,
@Type smallint = 0,
@usersList varchar(max) ='''',
@ListCampsIn varchar(max) = '''',
@ListCampsOut varchar(max) ='''',
@idNewArea int = 0,
@LoginId int = 0,
@AreaId int = 0
as
set nocount on
declare @count int
declare @id int
declare @user int
declare @IDCampEsp varchar(max)
declare @Assigned  varchar(max)
declare @AssignedCampsIn  varchar(max)
declare @AssignedCampsOut  varchar(max)
declare @settings table (
setting_id tinyint,
valor varchar(300)
)
insert into @settings (setting_id, valor) select setting_id,valor from ccSettings where setting_id in (63,64,180)

set @id = 1
set @Assigned = ''''
set @AssignedCampsIn = ''''
set @AssignedCampsOut = ''''


IF OBJECT_ID(''tempdb..#UsersList'') IS NOT NULL DROP TABLE #UsersList;
IF OBJECT_ID(''tempdb..#CampsInOutList'') IS NOT NULL DROP TABLE #CampsInOutList;

select *  into #CampsInOutList from (
select ROW_NUMBER() OVER(ORDER BY [CampEsp] ASC) AS Row, [CampEsp], [Type] from (
    select 0 as [Type],
    [value] As [CampEsp]
    FROM fn_RIASplitDelimited(@ListCampsIn, '','') where [value] > 0
    union
    select 1 as [Type],
    [value] As [CampEsp]
    FROM fn_RIASplitDelimited(@ListCampsOut, '','') where [value] > 0
    ) as Camps ) as CampsInOut

select ROW_NUMBER() OVER(ORDER BY value ASC) AS Row,
    value As user_id
    into #UsersList
    FROM fn_RIASplitDelimited(@usersList, '','')

select @count = count(user_id) from #UsersList

IF(@option = 1 OR @option = 2) BEGIN

    DECLARE @areaName VARCHAr(50);
    DECLARE @userLogin VARCHAR(40);
    DECLARE @workGroupName VARCHAR(40);
    DECLARE @userToAffect VARCHAR(40);
    DECLARE @campName VARCHAR(40);

END

if @option = 1 -- Insert Agente-Supervisor in WorkGroup
 begin

    while @id<=@count
    begin
        select @user = user_id from #UsersList where Row= @id
        select @Type = tipoUser_id from ccUsers where user_id = @user

        if @Type in(1, 2, 6)
        begin

            if not exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
            begin
            

                If @Type = 1
                 begin

                        If (select count(User_id) from ccRIAWorkGroupUsers where User_id = @user) < (select valor from @settings where setting_id=63)
                         begin
                            insert into ccRIAWorkGroupUsers(IDWG, User_id) values(@IDWG,@user)

                            --INSERT LOG RECORD (ASSIGN AGENT)
                            SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                            SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                            SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 23, 3, '''', @userToAffect, @workGroupName);

                            select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                            --insert skill media
                            exec ccsp_Skills @action= 5,@userId=@user

                            --select * from cccampsAgente where user_id=@user and 

                            insert into cccampsAgente (user_id, cam_id, prioridad, skill, IDWG)
                            select @user [User_id], A.idCampEsp [cam_id], dbo.fn_Calcula_UsrPriority(@user,0) [prioridad], 1 [skill], @IDWG IDWG
                            
                            from ccRIACampEspWG A
                            inner join ccCamps C on A.Tipo=1 and A.idCampEsp=C.cam_id                           
                            where A.tipo = 1 and A.IDWG = @IDWG and
                             idCampEsp not in (select cam_id from cccampsAgente where user_id=@user and IDWG=@IDWG)
                             


                           insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, IDWG)
                            select @user, A.idCampEsp, 0, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
                            from ccRIACampEspWG A
                            inner join ccInbound C on A.Tipo=0 and A.idCampEsp=C.Inbound_id
                            where A.tipo = 0 and IDWG = @IDWG and

                            idCampEsp not in (select inbound_id from ccInboundAgentes where user_id=@user and IDWG=@IDWG)

                            if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
                                insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
                            end
                        end
                 end
                 else if @Type in(2, 6)
                 begin
                    -- -Supervisor  @Type in (2,6)
                    insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @user)

                    --INSERT LOG RECORD (ASSIGN ADMIN)
                    SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                    SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                    SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 30, 3, '''', @userToAffect, @workGroupName);

                    select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                    if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
                        insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
                    end

                    insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                    select @user, idCampEsp, 0, @IDWG
                    from ccRIACampEspWG where tipo=0 and IDWG=@IDWG
                     and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)

                    update ccSupervisorCam
                    set monitored = 1
                    where user_id = @user
                    and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=0 and IDWG=@IDWG)
                    and tipo = 0
                    and IDWG <> @IDWG
                    and monitored = 0

                    insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                    select @user, idCampEsp, 1, @IDWG
                    from ccRIACampEspWG where tipo=1 and IDWG=@IDWG
                     and idCampEsp not in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)

                    update ccSupervisorCam
                    set monitored = 1
                    where user_id = @user
                    and cam_id in (select cam_id from ccSupervisorCam where user_id=@user and tipo=1 and IDWG=@IDWG)
                    and tipo = 1
                    and IDWG <> @IDWG
                    and monitored = 0
                end
                
            end
        end
        set @id = @id+1
    end
end




if @option = 2 -- Delete Agent-Supervisor from WorkGroup
 begin

    while @id<=@count
    begin
        select @user = user_id from #UsersList where Row= @id
        select @Type = tipoUser_id from ccUsers where user_id = @user
        
        if @Type = 1 --delete skill media
        exec ccsp_Skills @action= 4,@userId=@user,@idwg=@IDWG
        
        if exists(select IDWG from ccRIAWorkGroupUsers where IDWG = @IDWG AND User_id = @user)
        begin
        
            Delete ccRIAWorkGroupUsers where IDWG = @IDWG and User_id = @user
        

            if @Type = 1 -- Agente
             begin

                --INSERT LOG RECORD (UNASSIGN AGENT)

                SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 24, 3, '''', @userToAffect, @workGroupName);

                select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG   from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
                insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG

                delete from cccampsagente where user_id=@user and IDWG=@IDWG
                delete from ccInboundagentes where user_id=@user and IDWG=@IDWG

                --update preview permission
                update ccusers set 
                AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
                DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
                select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
                where progDial=3 and user_id = @user group by user_id)c on us.User_id=c.user_id
                where us.user_id = @user
                --select @Type
             end
             else if @Type in(2, 6) -- Supervisor
             begin

                --INSERT LOG RECORD (UNASSIGN ADMIN)

                SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user AND CCRA.IDArea = CCU.IDArea;
                SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                SET @workGroupName = (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) VALUES (@areaName, getDate(), @userLogin, 31, 3, '''', @userToAffect, @workGroupName);

                select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
                insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
                delete ccSupervisorCam where user_id=@user and IDWG=@IDWG
                --select @Type
            end
        end
        set @id = @id+1
    end
end
if @option in (1,2)
begin
    if LEN(@Assigned) > 0
        select SUBSTRING(@Assigned,0,Len(@Assigned))
    else
        select @Assigned

    return(0)
end

if @option = 3 -- Insert WorkGroup in Camp or ACDGroup  
  begin
    select @count = count(CampEsp) from #CampsInOutList

    while @id<=@count
    begin
         select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id
         

         if (select count(IdCampEsp) from ccRIACampEspWG where IdCampEsp=@IDCampEsp and Tipo=@Type) <= (select valor from @settings where setting_id=180) -- limit
             begin

                if (select count(IDWG) from ccRIACampEspWG where IDWG=@IDWG) <= (select valor from @settings where setting_id=64) -- limit
                    begin

                        if not exists (select IDWG from ccRIACampEspWG where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) -- No existe el grupo en el ACD o Especialidad
                        begin

                            insert into ccRIACampEspWG (IDWG, Tipo, IdCampEsp, priority) values (@IDWG, @Type, @IDCampEsp, 1)
                            if not exists(select * from ccRIACampEspWGConsulta where IDWG=@IDWG and Tipo=@Type and IdCampEsp=@IDCampEsp) begin
                                insert into ccRIACampEspWGConsulta (IDWG, Tipo, IdCampEsp) values (@IDWG, @Type, @IDCampEsp)
                            end   

                            SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                            
                            IF(@Type = 1) SET @campName = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @IDCampEsp)
                            ELSE SET @campName = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @IDCampEsp)
                             
                            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                            VALUES (
                                (SELECT [AreaName] FROM ccRIACat_Areas AS CRA, ccRIAAreaWorkGroup AS CRAW WHERE CRAW.IDWG = @IDWG AND CRA.IDArea = CRAW.IDArea), 
                                getDate(), 
                                @userLogin, 
                                36, 
                                3, 
                                '''', 
                                @campName,
                                (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG)
                            );

                            exec ccsp_RIACalcula_WGPriority @IDWG, @IDCampEsp, @Type
                            if @Type in (0, 1) -- ACDGroup
                            begin

                                if @IDWG is not null or @IDWG = 0
                                begin
                                    if @Type=0 --ACDGroup
                                    begin
                                        select @AssignedCampsIn = @AssignedCampsIn+ cast(@IDCampEsp as varchar(5))+'',''
                                        insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, idwg)
                                        SELECT distinct u.user_id, @IDCampEsp, 0 cli_id, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG 
                                        FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
                                            join ccusers s on u.user_id = s.user_id
                                        WHERE c.tipo=0 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and c.IDWG=@IDWG 
                                        and u.User_id not in (select User_id from ccInboundAgentes where Inbound_id=@IDCampEsp and IDWG=@IDWG)

                                        insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                                        select b.user_id, @IDCampEsp, 0, @IDWG
                                        from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
                                            join ccusers s on b.user_id = s.user_id
                                        where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=0
                                            and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=0 and IDWG=@IDWG)
             
                                        --return(0)
                                    end

                                    else if @Type = 1 -- Camp
                                    begin
                                        select @AssignedCampsOut = @AssignedCampsOut+ cast(@IDCampEsp as varchar(5))+'',''
                                        insert into CCCAMPSAGENTE (user_id, cam_id, prioridad, skill, IDWG)
                                        SELECT distinct u.user_id, @IDCampEsp, dbo.fn_Calcula_UsrPriority(u.User_id,0), 1 skill, @IDWG
                                        FROM ccRIAWorkGroupUsers u join ccRIACampEspWG c on u.IDWG = c.IDWG
                                        join ccusers s on u.user_id = s.user_id
                                        WHERE c.tipo=1 and s.tipouser_id=1 and c.idCampEsp=@IDCampEsp and u.IDWG=@IDWG 
                                            and u.User_id not in (select User_id from ccCampsAgente where cam_id=@IDCampEsp and IDWG=@IDWG)
            
                                        insert into ccSupervisorCam (user_id, cam_id, tipo, IDWG)
                                        select b.user_id, @IDCampEsp, 1, @IDWG
                                        from ccRIACampEspWG a join ccRIAWorkGroupUsers b on a.idwg = b.idwg
                                            join ccusers s on b.user_id = s.user_id
                                        where s.tipouser_id <> 1 and a.idcampesp=@IDCampEsp and b.idwg=@IDWG and a.tipo=1
                                            and b.User_id not in (select User_id from ccSupervisorCam where cam_id=@IDCampEsp and tipo=1 and IDWG=@IDWG)
                                    end
                            end
                        end
                    end
                end
            end
        set @id = @id + 1
   end
end

if @option = 3
begin
    
if LEN(@AssignedCampsIn) > 0 or LEN(@AssignedCampsOut) > 0
        select SUBSTRING(@AssignedCampsIn,0,Len(@AssignedCampsIn)) as CampsInAssigned, SUBSTRING(@AssignedCampsOut,0,Len(@AssignedCampsOut)) as CampsOutAssigned 
    else
        select @AssignedCampsIn as CampsInAssigned, @AssignedCampsOut as CampsOutAssigned

    return(0)
end

if @option = 4  --Delete relatoion Camp with WG
begin
declare @multipleAgents varchar(1000)
declare @multipleAdmins varchar(2000)
declare @sql varchar(max)

select @count = count(CampEsp) from #CampsInOutList
 while @id<=@count
  begin

        select @IDCampEsp = CampEsp, @Type = Type from #CampsInOutList where Row= @id

        SELECT @multipleAgents = coalesce(@multipleAgents + '','', '''') + CAST(A.user_id AS VARCHAR(40))
        FROM ccRIAWorkGroupUsers A
        JOIN ccUsers B ON A.user_id = B.user_id
        WHERE IDWG = @IDWG AND TipoUser_id = 1

        SELECT @multipleAdmins = coalesce(@multipleAdmins + '','', '''') + CAST(A.user_id AS VARCHAR(40))
        FROM ccRIAWorkGroupUsers A
        JOIN ccUsers B ON A.user_id = B.user_id
        WHERE IDWG = @IDWG AND TipoUser_id = 2


        if right( @multipleAgents,1)='','' begin
            set @multipleAgents=SUBSTRING(@multipleAgents,0,len(@multipleAgents)-1)
        end
        if right( @multipleAdmins,1)='','' begin
            set @multipleAdmins=SUBSTRING(@multipleAdmins,0,len(@multipleAdmins)-1)
        end


        --Delete Agent from WorkGroup
           set @sql = ''ccsp_RIA_ABCAgents @option=7,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
                    @AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAgents+''''''''
           
           exec(@sql)

         --Delete Supervisor from WorkGroup

         set @sql = ''ccsp_RIA_ABCAgents @option=8,@UserId=''''0'''',@Login='''''''',@Nombres='''''''',@ApellidoPaterno='''''''',@ApellidoMaterno='''''''',@Password='''''''',@Sexo=0,@canChangeStatus=0,
                    @AreaId=0,@UserType=0,@IDWG=''+cast(@IDWG as varchar(4))+'',@DeleteUsers=0,@InOut=''+cast(@Type as varchar(4))+'',@IDCampEsp=''+cast(@IDCampEsp as varchar(4))+'',@multipleUsers=''''''+@multipleAdmins+''''''''
           
           exec(@sql)

        --Delete WokGroup from ACD or Camp 

        SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);
                            
        IF(@Type = 1) SET @campName = (SELECT [cam_descripcion] FROM ccCamps WHERE cam_id = @IDCampEsp)
        ELSE SET @campName = (SELECT [descripcion] FROM ccInbound WHERE Inbound_id = @IDCampEsp)
                             
        INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
        VALUES (
            (SELECT [AreaName] FROM ccRIACat_Areas AS CRA, ccRIAAreaWorkGroup AS CRAW WHERE CRAW.IDWG = @IDWG AND CRA.IDArea = CRAW.IDArea), 
            getDate(), 
            @userLogin, 
            59, 
            3, 
            '''', 
            @campName,
            (SELECT [WGName] FROM ccRIACat_WorkGroup WHERE IDWG = @IDWG)
        );


         set @sql = ''exec ccsp_RIA_ABCWorkGroups @option=7,@IDWG=''+cast(@IDWG as varchar(4))+'',@IDCampEsp=''''''+cast(@IDCampEsp as varchar(4))+'''''',@Type=''+cast(@Type as varchar(4))+''''
         exec(@sql)
         
        set @id = @id + 1
    
    end

    select 1
    return 0
end

if @option = 5  --Change Admin Administrator.
begin
declare @user_id int
select @user_id = value FROM fn_RIASplitDelimited(@usersList, '','')
select @Type = TipoUser_id from ccUsers where User_id = @user_id

        if @Type = 1 -- Agente
        begin

            if(select count(user_id) from ccCampsAgente where user_id = @user_id) >0 or 
            (select count(user_id) from ccInboundAgentes where user_id = @user_id) >0 or
            (select count(user_id) from ccRIAWorkGroupUsers where user_id = @user_id) > 0
            begin
                select -1
                return 0
            end
            else

                SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user_id AND CCRA.IDArea = CCU.IDArea;
                SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);

                INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
                VALUES (@areaName, getDate(), @userLogin, 27, 3, ''T&CHANGE_USER_AREA'', (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idNewArea), @userToAffect);

                update ccUsers set IDArea = @idNewArea where user_id = @user_id
        end

        
    if @Type in (2, 6) -- Supervisor
    begin

        if(select count(user_id) from ccSupervisorCam where user_id = @user_id) > 0 or
        (select count(user_id) from ccRIAWorkGroupUsers where user_id = @user_id) > 0
        begin
            select -1
            return 0
        end
        else

            SELECT @userToAffect = CCU.Login, @areaName = CCRA.AreaName FROM ccUsers AS CCU, ccRIACat_Areas AS CCRA WHERE CCU.user_id = @user_id AND CCRA.IDArea = CCU.IDArea;
            SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @LoginId);

            INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
            VALUES (@areaName, getDate(), @userLogin, 34, 3, ''T&CHANGE_USER_AREA'', (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @idNewArea), @userToAffect);

            update ccUsers set IDArea = @idNewArea where user_id = @user_id
    end

    update ccPosicion set user_id = 0 where user_id = @user_id

    select 1

end

set nocount off
        '
    EXEC(@sql)
        -----------------------End Frida Orta---------------------------------------------------------------------------------

set @process = 'Alter SP ccsp_getVersion --fix Version '
    set @sql='ALTER PROCEDURE [dbo].[ccsp_getVersion]
    @Module VARCHAR(3) = NULL,
    @Version INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Idioma BIT;
    SELECT @Idioma = CAST(valor AS BIT) FROM ccSettings WHERE setting_id = 27;

    set @Module=UPPER(@Module)

    IF ISNULL(@Module, '''') NOT IN (''BD'', ''ADM'', ''AGT'', ''ALL'', ''BDF'')
    BEGIN
        SELECT ''-2'' AS ID, 
               CASE @Idioma WHEN 0 THEN ''ERROR. Modulo no valido'' ELSE ''ERROR. Invalid Module'' END AS [Description];
        RETURN 0;
    END

    DECLARE @nVersion VARCHAR(30);
    SELECT @nVersion = CAST(valor AS VARCHAR(15)) FROM ccSettings WHERE setting_id = 77;

    BEGIN TRY
        DECLARE @version_1 VARCHAR(15), @version_2 VARCHAR(9), @version_3 VARCHAR(6), @version_4 VARCHAR(6);
        DECLARE @Prueba TABLE (id INT, value NVARCHAR(100));

        INSERT INTO @Prueba SELECT * FROM fn_RIASplitDelimited(@nVersion, ''.'');

        IF NOT EXISTS (SELECT value FROM @Prueba WHERE id = 4)
        BEGIN
            UPDATE ccSettings SET valor = valor + ''.00'' WHERE setting_Id = 77;
            INSERT INTO @Prueba (value) VALUES (''00'');
        END
    END TRY
    BEGIN CATCH
        SELECT ''-1'' AS ID, ERROR_MESSAGE() AS [Description];
        RETURN 0;
    END CATCH

    
    IF ISNULL(@Version, 0) = 0 --Saber la version
    BEGIN
        SELECT @version_1 = value FROM @Prueba WHERE id = 1;
        SELECT @version_2 = value FROM @Prueba WHERE id = 2;
        SELECT @version_3 = value FROM @Prueba WHERE id = 3;
        SELECT @version_4 = value FROM @Prueba WHERE id = 4;

        IF @Module in(''ALL'',''BDF'')
        BEGIN
            IF @Module = ''ALL''
                SELECT @version_1 + ''.'' + @version_2 + ''.'' + @version_3 + ''.'' + @version_4;
            ELSE IF @Module = ''BDF''
                SELECT @version_1 + ''.'' + @version_4;

            RETURN 0;
        END
        ELSE
        BEGIN
            SELECT @Version = CAST(CASE @Module
                                   WHEN ''BD'' THEN @version_1
                                   WHEN ''ADM'' THEN @version_2
                                   WHEN ''AGT'' THEN @version_3
                                   END AS INT);
            SELECT @Version AS Version;
            RETURN @Version;
        END
    END

    IF @Module = ''BD'' AND (@Version <= CAST(@version_1 AS INT) OR (@Version - CAST(@version_1 AS INT)) > 1)
    BEGIN
        SELECT ''-3'' AS ID, 
               CASE @Idioma 
                    WHEN 0 THEN ''ERROR. Version no Valida para BD. Version Actual: '' + @version_1
                    ELSE ''ERROR. Invalid Version for BD. Current Version: '' + @version_1
               END AS [Description];
        RETURN 0;
    END


    IF @Version <= CAST(CASE @Module
                        WHEN ''BD'' THEN @version_1
                        WHEN ''ADM'' THEN @version_2
                        ELSE @version_3
                        END AS INT)
    BEGIN
        SELECT ''-3'' AS ID, 
               CASE @Idioma 
                    WHEN 0 THEN ''ERROR. Version no Valida para '' + @Module + ''. Version Actual: '' +
                                CASE UPPER(@Module)
                                     WHEN ''BD'' THEN @version_1
                                     WHEN ''ADM'' THEN @version_2
                                     ELSE @version_3
                                END
                    ELSE ''ERROR. Invalid Version for '' + @Module + ''. Current Version: '' +
                                CASE UPPER(@Module)
                                     WHEN ''BD'' THEN @version_1
                                     WHEN ''ADM'' THEN @version_2
                                     ELSE @version_3
                                END
               END AS [Description];
        RETURN 0;
    END

    SELECT @version_1 = value FROM @Prueba WHERE id = 1;
    SELECT @version_2 = value FROM @Prueba WHERE id = 2;
    SELECT @version_3 = value FROM @Prueba WHERE id = 3;
    SELECT @version_4 = ISNULL(MAX(value), ''00'') FROM @Prueba WHERE id = 4;

    IF UPPER(@Module) = ''BD'' begin
        if cast(@version_1 as int) in (@Version-1) begin            
            set  @version_4 = ''00''
        end
        SET @version_1 = @Version;
    end
    ELSE IF UPPER(@Module) = ''ADM'' SET @version_2 = @Version;
    ELSE IF UPPER(@Module) = ''AGT'' SET @version_3 = @Version;
    ELSE SET @version_4 = @Version;

    SET @nVersion = @version_1 + ''.'' + @version_2 + ''.'' + @version_3 + ''.'' + @version_4;
    UPDATE ccSettings SET valor = @nVersion WHERE setting_id = 77;

    IF @@ROWCOUNT = 1
        SELECT ''0'' AS ID, ''Actualizado a version: '' + @nVersion AS [Description];
    ELSE
        SELECT ''-4'' AS ID, 
               CASE @Idioma 
                    WHEN 0 THEN ''ERROR generado al actualizar a version '' + @nVersion
                    ELSE ''ERROR introduced when upgrading to version '' + @nVersion
               END AS [Description];

    RETURN 0;
    SET NOCOUNT OFF;
END
'
    EXEC(@sql)


        ---------------------------- BEGIN Marco García TT10870 ------------------------------------------------------------------------------

        SET @process = 'TT10870-Engine-Error mensajes automáticos delete procedure ccsp_GalateaAgentAutomaticMessages'
        SET @sql = ' IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAgentAutomaticMessages'')
                BEGIN
                        DROP PROCEDURE ccsp_GalateaAgentAutomaticMessages;
                END';
        EXEC(@sql);


        SET @process = 'TT10870-Engine-Error mensajes automáticos create procedure ccsp_GalateaAgentAutomaticMessages'
        SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAgentAutomaticMessages] 
        @action as tinyint,
        @msgName as varchar(40) = '''',
        @msgFile as varchar(100) = null,
        @Description as varchar(40) = '''',
        @duration as int = -1,
        @CampType tinyint = 0,
        @msgIdLst varchar(8000) = null,
        @camId int =null,
        @MsgId int = null,
        @userId smallint = NULL,
        @idArea smallint = NULL,
        @messageType tinyint = NULL
        AS
        BEGIN
        SET NOCOUNT ON
        declare @tableMsgId table(MsgId int not null)
        declare @campName varchar(70)
                declare @idCampUnassign int
                DECLARE @operation INT

                if @action in (3,7) begin --Assin/Unassign
                        if @CampType=0
                                        select @campName =descripcion from ccInbound where Inbound_id=@camId
                        else
                                        select @campName =cam_descripcion from ccCamps where cam_id=@camId
        end

        if @action = 1  -- GET_AUDIO_CATALOG
        begin
                        select ISNULL(msgName, msgFile) [MsgName], [Description] [MsgDescription], [MsgFile] [MsgFile], [MsgId] [MsgId], [idArea][IdArea], [messageType][MessageType] from ccAgentMsgFiles where idArea in (-1, @idArea)        
                        return (0)
        end
        else if @action = 2 --CREATE_NEW_MSG
        begin
                        if EXISTS(select msgName from ccAgentMsgFiles where msgName=@msgName)
                                        begin
                                                        select -1 as result
                                        end
                        else
                                        begin
                                                        insert into ccAgentMsgFiles (msgFile, [Description], Duration, msgName, idArea, messageType) 
                                                        values (@msgFile, @Description, @duration, @msgName, @idArea, @messageType)
                                                        select cast(@@identity as int) result              
                        end 

        end 
        else IF @action = 3 -- Assing
        begin   
                        if not exists(select MsgId from ccAgentMsgFiles where MsgId=@MsgId)
                        begin
                                        select ''0'' as result
                                        return(0)
                        end

                        if exists(select MsgId from [ccAgentMsgRelationFiles] where CamId=@camId and CamType=@CampType and MsgType = @messageType)
                        begin
                                        select ''-1'' as result
                                        return(0)
                        end

                        insert into ccAgentMsgRelationFiles (MsgId, CamId, CamType, MsgType) values(@MsgId,@camId,@CampType,@messageType)

                        select @campName

        end

        else IF @action = 4 -- GET_CAMP_MESSAGES_RELATION
        begin   
                        select MsgId from [ccAgentMsgRelationFiles] where CamId=@camId and CamType=@CampType and MsgType = @messageType          
        end
        else IF @action = 5 -- DELETE_AUDIO_MSG
        begin

                        insert into @tableMsgId
                        select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')

                        if exists(select A.MsgId from [ccAgentMsgRelationFiles] A 
                                                          inner join @tableMsgId B on A.MsgId=B.MsgId
                        )
                        begin
                                        select 0 as result
                                        return(0)
                        end

                         delete A from ccAgentMsgFiles A 
                         inner join @tableMsgId B on A.MsgId=B.MsgId
         
                         select 1 as result  
                         return(0)
        end
        
        else if @action = 6 --EDIT_AUDIO_MSG
        BEGIN    
                        update ccAgentMsgFiles set [Description] = isnull(@Description,[Description]), MsgName = isnull(@msgName,MsgName),
                        MsgFile = isnull(@msgFile,MsgFile), Duration=case when @duration is null or @duration<=0 then Duration else @duration end,
                                idArea = isnull(@idArea, idArea)
                        where MsgId = @MsgId    
        END
        else IF @action = 7 -- UnAssing
        begin           
                        if not exists(select MsgId from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType and MsgType = @messageType)
                        begin
                                        select ''-1'' as result
                                        return(0)
                        end
                                else begin
                                        select @idCampUnassign =CamId from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType and MsgType = @messageType
                                end

                        delete from [ccAgentMsgRelationFiles] where MsgId=@MsgId and CamId=@camId and CamType=@CampType and MsgType = @messageType
                        select @campName
        end

        else IF @action = 8 -- list fileName
        begin                           
                        insert into @tableMsgId
                        select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')
        
                        select A.MsgFile from ccAgentMsgFiles A 
                                                          inner join @tableMsgId B on A.MsgId=B.MsgId
        end
        else IF @action = 9 -- Relation CampIn and MsgFile
        begin                           
                        select A.CamId,B.MsgFile,B.Duration from [ccAgentMsgRelationFiles] A
                        inner join ccAgentMsgFiles B on A.MsgId=B.MsgId
                        where CamType=@CampType AND B.messageType = ISNULL(@messageType, B.messageType )

        end
        else IF @action = 10 -- Relation CampIn and MsgFile
        begin
                        select MsgId,MsgFile ,Duration from ccAgentMsgFiles where MsgId=@MsgId

        END
        ELSE IF @action = 11 -- Relation Campaign and Audio Msg
                BEGIN
                                (select CC.cam_id as Camp_Id, Camp_Type = 1,ISNULL(cam_descripcion,'''''''') as [Name], Graphics.frame as Frame, Type = ISNULL(IM.MsgType ,17), ISNULL(CC.IDArea,0) as IdArea, ISNULL(AREas.AreaName,'''') as AreaName
                                from ccCamps as CC with(nolock) 
                                left join ccRIACat_Areas as AREas with(nolock) on CC.IDArea = AREas.IDArea
                                inner join ccRIACampsGraph as CampsGraph on CC.cam_id = CampsGraph.cam_id
                                inner join ccRIAGraphics as Graphics on Graphics.graphic_id = CampsGraph.graphic_id
                                inner join ccAgentMsgRelationFiles IM on IM.CamId = CC.cam_id
                                Where IM.MsgId = @MsgId and IM.CamType = 1) 
                                        UNION
                                (select IC.Inbound_id as Camp_Id, Camp_Type = 0,ISNULL(descripcion,'''''''') as [Name], Graphics.frame as Frame, Type = ISNULL(IM.MsgType ,16), ISNULL(IC.IDArea,0) as IdArea, ISNULL(AREas.AreaName,'''') as AreaName
                                from ccInbound as IC with(nolock) 
                                left join ccRIACat_Areas as AREas with(nolock) on IC.IDArea = AREas.IDArea
                                inner join ccRIAInboundGraph as CampsGraph on IC.Inbound_id = CampsGraph.Inbound_id
                                inner join ccRIAGraphics as Graphics on Graphics.graphic_id = CampsGraph.graphic_id
                                inner join ccAgentMsgRelationFiles IM on IM.CamId = IC.Inbound_id
                                Where IM.MsgId = @MsgId and IM.CamType = 0)
                END
                else IF @action = 12 -- list MsgName
        begin                           
                        insert into @tableMsgId
                        select value from dbo.fn_RIASplitDelimited(@msgIdLst, '','')
        
                        select A.MsgName from ccAgentMsgFiles A 
                                                          inner join @tableMsgId B on A.MsgId=B.MsgId
        end
                else IF @action = 13 -- getAudioInformation
        begin                           
                        select [MsgName] [MsgName], [Description] [MsgDescription], [MsgFile] [MsgFile], [idArea][IdArea] from ccAgentMsgFiles where MsgId = @MsgId
        end
        
        END'

        EXEC(@sql);



        --------------------------- END Marco Garcia TT10870 ----------------------------------------------------------------------------------
---------------------------- BEGIN Roberto Nava TT7953 ------------------------------------------------------------------------------
--------------------------- END Roberto Nava TT7953 ----------------------------------------------------------------------------------
--------------------------- START Jonathan Ramirez 125.20231211.0.15-----------------------------------------------------------------------------------
SET @process = '0.15 - 1 - Se modifica SP ccsp_OutboundMultimediaCommon, Se cambia InitialDate, por InitialTime'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_OutboundMultimediaCommon] 
                    @Action INT,
                    @ConversationId INT = NULL
                    AS
                    BEGIN
                    SET NOCOUNT ON;

                        IF @Action = 0 -- Get WhatsApp Campaigns List
                        BEGIN 
                            SELECT CAST(campaigns.cam_id AS INT) AS Id,
                                   campaigns.cam_descripcion AS Name,
                                   waNumbers.number AS Phone,
                                   5 as [Type]
                            FROM ccCamps campaigns
                            INNER JOIN ccWhatsAppNumbers waNumbers
                            ON campaigns.cam_id = waNumbers.camp_id
                            WHERE campaigns.CampType = 5 AND waNumbers.status = 1
                            ORDER BY campaigns.cam_id 
                        END

                        ELSE IF @Action = 1 -- Get Outbound WhatsApp conversation by conversation id
                        BEGIN 
                            DECLARE @ServiceType VARCHAR(20) = ''whatsapp''
                            SELECT conversationId AS ConversationID,
                                   clientId AS ClientId,
                                   phoneCamp AS CampaignPhone,
                                   agentId AS AgentId,
                                   @ServiceType AS ServiceType,
                                   requestDate AS InitialTime
                            FROM ccWhatsAppConversationsOut
                            WHERE conversationId = @ConversationId
                        END
                    END';
        EXEC(@sql);
--------------------------- START Jonathan Ramirez 125.20231211.0.15-----------------------------------------------------------------------------------
----------------------------------------------------------- Begin David Medina -----------------------------------------------------------------------
SET @process = 'Ticket TT10862-AdminKolob-No guardan cambios en ND'
SET @sql = '
        IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaUnavailableStates'')
        BEGIN
                DROP PROCEDURE ccsp_GalateaUnavailableStates
        END
'
EXEC(@sql)

SET @process = 'TT10862 Se quita casteo a tinyint a variable TipoNotReady_id cuando se realiza un update'
SET @sql = '
        CREATE PROCEDURE [dbo].[ccsp_GalateaUnavailableStates]
        @NotReady_id smallint = null,
        @Description varchar(30)='''',
        @Acc_Time int = null,
        @Intervals int = null,
        @Pass_Supv tinyint = null,
        @NextStatus int = null,
        @Frame smallint = null,
        @Type varchar(1)='''',
        @IsSupv int = null,
        @NotReady_ids varchar(max)=''''
        AS
        set nocount on
        DECLARE @sql nvarchar(4000), @graph nvarchar(1000), @id smallint, @newGraph smallint
        if @Type = 1 -- LOAD
                begin
                        SELECT distinct a1.TipoNotReady_id as NotReady_Id, a1.Descripcion as Description, a1.Time_Acum as Acc_Time, a1.Time_xEv as Intervals, 
                        cast(a1.Pas_Sup as bit) Pass_Supv, a1.NextStatus, frame as Frame, cast(a1.IsSup as bit) IsSupv
                        FROM ccTipoNotReady a1 
                        inner join ccRIAnotreadyGraph a2 on (a1.tiponotready_id=a2.tiponotready_id)
                        inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
                        where a1.StatusTipoNotReady=1
                        order by 2
                end
        If @Type=2 -- INSERT
                begin
                if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Description)
                        begin           
                        select -1
                        return(0)
                        end
                if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=0 and Descripcion=@Description)
                        begin           
                                select @id=TipoNotReady_id from ccTipoNotReady where Descripcion=@Description
                                update ccTipoNotReady set 
                                Time_acum=@Acc_Time,
                                Time_xEv=@Intervals,
                                Pas_Sup=@Pass_Supv,
                                NextStatus=@NextStatus,
                                IsSup=@IsSupv,
                                StatusTipoNotReady=1
                                where Descripcion=@Description
                                If not exists(select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
                                        Begin
                                                insert into ccRIAGraphics (frame, type_id) select @Frame,4
                                        End
                                insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
                                select cast(@id as int)
                                return(0)               
                        end
                If not exists(select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
                        Begin
                        insert into ccRIAGraphics (frame, type_id) select @Frame,4
                        End
                insert ccTipoNotReady (Descripcion, Time_Acum, Time_xEv, Pas_Sup, NextStatus, IsSup, StatusTipoNotReady) 
                select @Description, @Acc_Time, @Intervals, @Pass_Supv, @NextStatus, @IsSupv,1
                select @id=SCOPE_IDENTITY()
                insert into ccRIANotReadyGraph select @id, graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
                select cast(@id as int)
                end
        If @Type=3 -- DELETE
                begin
                        declare @NDs_Ids table (id int primary key not null)
                if @NotReady_id is null
                        begin
                        insert into @NDs_Ids
                        select value from dbo.fn_RIASplitDelimited (@NotReady_ids, '','')
                        end
                else
                        begin
                        insert into @NDs_Ids
                        select @NotReady_id
                        end
                exec ccsp_AdminNotready 3,0,@NotReady_id,0, @NotReady_ids
                delete ccRIANotReadyGraph where tipoNotReady_id in (select id from @NDs_Ids)
                delete from ccUnavailableRelation where idUnavailable in (select id from @NDs_Ids)
                update ccTipoNotReady set StatusTipoNotReady=0 where tipoNotReady_id in (select id from @NDs_Ids)
                update ccTipoNotReady set NextStatus=-1 where NextStatus in (select id from @NDs_Ids)
                select cast(id as smallint) NotReady_Id, 0 as Related from @NDs_Ids
                end
        if(@Type=4) --UPDATE
                begin
                if exists(select Descripcion from ccTipoNotReady where StatusTipoNotReady=1 and Descripcion=@Description and TipoNotReady_id not in (@NotReady_id))
                        begin           
                        select -1
                        return(0)
                        end
                update ccTipoNotReady set 
                        Descripcion=case @Description when '''' then Descripcion else @Description end,
                        Time_Acum=ISNULL(@Acc_Time,Time_Acum),
                        Time_xEv=ISNULL(@Intervals,Time_xEv),
                        Pas_Sup=ISNULL(@Pass_Supv,Pas_Sup), 
                        NextStatus=ISNULL(@NextStatus,NextStatus), 
                        IsSup=ISNULL(@IsSupv,IsSup)
                where TipoNotReady_id=@NotReady_id
                IF ISNULL(@Frame,'''') not in('''')
                        BEGIN
                        If not exists (select frame from ccRIAGraphics where frame = @Frame and type_id = 4)
                                begin
                                insert into ccRIAGraphics (frame, type_id) select @Frame,4
                                end
                        select @graph = graphic_id from ccRIAGraphics where frame = @Frame and type_id = 4
                        update ccRIANotReadyGraph set graphic_id=@graph where TipoNotReady_id=@NotReady_id
                        END
                        select 1
                end
        if @Type = 5
                begin
                select cast(NextStatus as smallint) NotReady_Id, cast(TipoNotReady_id as int) Related
                from ccTipoNotReady 
                where StatusTipoNotReady=1 and NextStatus in (select value from dbo.fn_RIASplitDelimited (@NotReady_ids, '',''))
                end
        set nocount off
'
EXEC(@sql)


----------------------------------------------------------- END David Medina -------------------------------------------------------------------------
--------------------------- START Brian Omar Mejia Magos 125.20231211.0.16-----------------------------------------------------------------------------------
SET @process = 'Ticket TT12519_TT12395_TT12396_TT11343 Admin Crash'
SET @sql = '
        ALTER PROCEDURE [dbo].[ccspSaveDispositionResult]
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
if @action in(5,6,7) begin    
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
    --,CASE WHEN ISNULL(rel.calif_id, 0) = 0 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS IsSubDisp
        ,CASE WHEN SUM(SubDispotitionId) > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsSubDisp
    from ccDispositionDashboardResultOut dash with(nolock)
    left join ccTipoCalifOut ca on dash.DispotitionId = ca.calif_id 
    left join ccTipoCalifSubOUT tcsout on dash.SubDispotitionId = tcsout.califSub_id
    left join ccstatusllamada sll on sll.statuscall_id = dash.statusCallId
    left join ccCamps ci on ci.cam_id = dash.CamId
    LEFT join cctipoSubCalifRel rel on rel.calif_id = ca.calif_id and dash.SubDispotitionId = rel.califSub_id and tipoSubRel = 0
    where CamId=@camId
    group by  dash.CamId, dash.statusCallId,ca.[description],sll.descripcion,dash.DispotitionId,GraphColor--,rel.calif_id

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
else if @action=7 begin 
        if @callType= 1 begin

                select 0 as Type,co.CamId as CampId,
                isnull(ca.calif_id,0) as Id,
                case when co.statusCallId = 13
                then case when description is not null
                then description else @nIdioma end
                else
                case when sll.descripcion is not null
                then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma + ''CamId''
                end
                end as Calification,
                isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(*) Quantity
                from ccDispositionDashboardResultOut co
                left join ccTipoCalifOut ca on co.DispotitionId = ca.calif_id
                left join ccTipoCalifSubOUT cso on co.SubDispotitionId = cso.califSub_id 
                left join ccstatusllamada sll on sll.statuscall_id = co.statusCallId
                left join ccCamps ci on ci.cam_id = co.CamId
                where co.CamId = @camId    
                group by  co.CamId,ca.calif_id, co.statusCallId,description,descripcion,cso.califSubDesc
        end
        else begin
                select 0 as [type],CamId as CampId
                , isnull(ca.calif_id,0) as Id
                , ca.[description] as Calification
                , isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName
                , count(*) as Quantity
                --,dash.DispotitionId
                from ccDispositionDashboardResultIn dash
                left join ccTipoCalif ca on dash.DispotitionId = ca.calif_id
                left join ccInbound cci on cci.inbound_id = dash.CamId
                left join ccTipoCalifSub ctcs on dash.SubDispotitionId = ctcs.califSub_id
                where dash.CamId=@camId and dash.statusCallId=13-- and dash.DispotitionId=@dispotitionId
                group by ca.description, dash.CamId,  ca.calif_id,ctcs.califSubDesc,dash.DispotitionId
        end
end

'
EXEC(@sql)
SET @process = 'Ticket TT12519_TT12395_TT12396_TT11343 Admin Crash'
SET @sql = '
        ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]
    @type smallint = null,
    @inbound_id smallint = null,
    @calif_id smallint = null,
    @cam_id smallint = NULL,
    @isKolob BIT = 0
    AS
    set nocount on
    create table #CalifTemp (
    id int identity,
    tipo integer,
    Cam_id varchar(60),
    Calificacion varchar(60),
    subCalificacion varchar(60) null,
    calif_id smallint null,
    Total int,
    iTotal4Campaign int null)

    declare @typeACD smallint --= 0
    declare @today datetime
    declare @nIdioma varchar(22),@nIdiomaSub varchar(22)

    set @today = convert(datetime, convert (varchar(11), getdate(), 101))
    select @typeACD = chat from ccInbound  where Inbound_id = @inbound_id


    select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end,
    @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
    from ccsettings where setting_id = 27 -- 0 esp

    ---------------OUT ----------------------------
    if @type=0 begin
        insert into #CalifTemp
        select 0 as tipo,co.cam_id as cam_id,
        case when co.statuscall_id = 13
            then case when description is not null
            then description else @nIdioma end
        else case when sll.descripcion is not null then ''cw:'' + sll.descripcion
        else ''cw:'' + @nIdioma
        end end as Calificacion
        ,0 as subCalificaion,
        co.calif_id,count(*) cantidad,0 as iTotal4Campaign
        from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
        left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
        left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
        left join ccCamps ci on ci.cam_id = co.cam_id
        where co.cal_inicio > @today
        group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id

        select tipo,Cam_id, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end as Calificacion,
        case when count(subCalificacion)>0 then 1 else 0 end subCalificacion, calif_id,sum(Total) as Total
        from #CalifTemp
        group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma then calificacion else @nIdioma end, Cam_id, iTotal4Campaign,calif_id

    end
    ---------------IN ----------------------------
    else if @type = 1 begin

        if @typeACD = 0 begin  --Calls
        insert into #CalifTemp
        select @typeACD as tipo,cci.inbound_id as cam_id, description as Calificacion
                ,case when count(ci.califSub_id) >0 then 1 else 0 end as subCalificacion,ci.calif_id
                ,count(*) as total,0 as iTotal4Campaign
                from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
                left join ccTipoCalif ca on ci.calif_id = ca.calif_id
                left join ccInbound cci on cci.inbound_id = ci.inbound_id
                left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
                where ci.cal_inicio > @today and statuscall_id = 13 and cci.Inbound_id=@inbound_id
                group by description, cci.inbound_id,ci.calif_id

        if (select valor from ccSettings where setting_id = 78) = 0 begin
            update #CalifTemp set iTotal4Campaign = 0
        end
        else begin
        update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign
            from (
                select cam_id, sum(A.Total) iTotal4Campaign from #CalifTemp A group by cam_id) t
            inner join #CalifTemp c on t.cam_id = c.cam_id
        end
        end
        else if @typeACD = 1 begin--Chats
        insert into #CalifTemp(tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
        select @typeACD as tipo, inboundId as Cam_id, [description] as Calificacion,
                case when sum(case when a.subDisposition = 0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
                a.disposition as calif_id, count(disposition) as Total
                from ccriachats a
                left join ccTipoCalif b on a.disposition=b.calif_id
            where a.chatDate > @today and
            a.chatStatus=4 and a.inboundId=@inbound_id
        group by inboundId, [description],disposition
        end
        else if @typeACD = 3 begin ---Mail
        insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
        select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
        case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
        relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
        from conversation conver
        inner join message mess on mess.conversationId = conver.conversationId
        left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
        left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
        where mess.date > @today and
        conver.inboundId=@inbound_id and mess.messageStatusId >= 5
        group by conver.inboundId,relmesdis.dispositionId,disp.Description

        end
        else if @typeACD = 4 begin --calif twetter
        insert into #CalifTemp (tipo ,Cam_id , Calificacion , subCalificacion ,calif_id,Total)
        select @typeACD as tipo,conver.inboundId, disp.Description as calificacion,
        case when sum( case when relmesdis.subDispositionId is null or relmesdis.subDispositionId=0 then 0 else 1 end) >0 then 1 else 0 end as subCalificacion,
        relmesdis.dispositionId as calif_id,COUNT(relmesdis.dispositionId) as total
        from conversationTwitter conver
        inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
        left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
        left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
        where mess.date > @today and
        conver.inboundId=@inbound_id and mess.messageStatusId >= 5
        group by conver.inboundId,relmesdis.dispositionId,disp.Description

        end
        select camtemp.tipo,camtemp.cam_id,
        case when tipcal.Description is not null then tipcal.Description else @nIdioma end as Calificacion,
        camtemp.subcalificacion,camtemp.calif_id,camtemp.total
        from #CalifTemp camtemp
        left join ccTipoCalif tipcal on camtemp.calif_id =  tipcal.calif_id
    end
    -------------------SUBCALIFICACIONES IN-------------------
    else if @type = 2 BEGIN
        if @typeACD = 0 begin --Calls
            exec ccspSaveDispositionResult @action=7,@callType=0,@camId=@inbound_id,@dispotitionId=@calif_id        
        end
        else if @typeACD = 1 
        BEGIN --Chat
            IF(@isKolob = 1)
            BEGIN
                select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
                isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName, count(ctcs.califSubDesc) as Quantity,
                ctcs.califSub_id AS Id
                from ccriachats a
                left join ccTipoCalif b on a.disposition=b.calif_id
                left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
                where a.chatDate > @today and
                a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id AND ctcs.califSub_id IS NOT NULL
                group by inboundId, [description],ctcs.califSubDesc, ctcs.califSub_id
            END
            ELSE
            BEGIN
                select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
                isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
                from ccriachats a
                left join ccTipoCalif b on a.disposition=b.calif_id
                left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
                where a.chatDate > @today and
                a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id
                group by inboundId, [description],ctcs.califSubDesc
            END
        end
        else if @typeACD = 3 begin --Mail
        select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
        isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
        from conversation conver
        inner join message mess on mess.conversationId = conver.conversationId
        left join relationMessageDisposition relmesdis on relmesdis.messageId = mess.messageId
        left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
        left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
        where mess.date > @today and
        mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
        group by conver.inboundId,disp.Description,subDisp.califSubDesc


        end
        else if @typeACD = 4 begin --Twitter
        select @typeACD as tipo,conver.inboundId as camid, disp.Description as calificacion,
        isnull(subDisp.califSubDesc,@nIdiomaSub) as subCalificacion, count(subDisp.califSubDesc) as totales
        from conversationTwitter conver
        inner join messageOutTwitter mess on mess.conversationTwitterId = conver.conversationTwitterId
        left join relationMessageDispositionTwit relmesdis on relmesdis.messageOutTwitterId = mess.messageOutTwitterId
        left join ccTipoCalif disp on disp.calif_id=relmesdis.dispositionId
        left join ccTipoCalifSub subDisp on subDisp.califSub_id=relmesdis.subDispositionId
        where mess.date > @today and
        mess.messageStatusId >= 5 and conver.inboundId=@inbound_id and disp.calif_id=@calif_id
        group by conver.inboundId,disp.Description,subDisp.califSubDesc
        end

    end
    -------------------SUBCALIFICACIONES OUT-------------------
    else if @type = 4 begin     
        exec ccspSaveDispositionResult @action=7,@callType=1,@camId=@inbound_id,@dispotitionId=@calif_id
    end

    drop table #CalifTemp
    set nocount off
'
EXEC(@sql)
----------------------------------------------------------- Brian Omar Mejia Magos -------------------------------------------------------------------------

----------------------------------------------------------- Start Hugo Longoria -------------------------------------------------------------------------

    set @process = 'Alter SP ccsp_DLRInsertCall'
    set @sql='ALTER PROCEDURE [dbo].[ccsp_DLRInsertCall]
        @callout_id int,
        @cam_id smallint,
        @cal_Key varchar(20),
        @cal_Telefono varchar(14),
        @Puerto smallint,
        @logDial_id int=0
        AS

        INSERT ccoCallsOUT ( callout_id, cam_id, cal_Key, cal_telefono, cal_puerto, cal_Inicio, statusCall_id ) --Status 6=Pide Agente
          VALUES ( @callout_id, @cam_id, @cal_Key, @cal_Telefono, @Puerto, getdate(), 6 )

        select scope_identity() as cal_id
        '
    EXEC(@sql)



----------------------------------------------------------- End Hugo Longoria -------------------------------------------------------------------------
---------------------------------------- End fix/125.20231211.0.9 fix/125.20231211.0.15 fix/125.20231211.0.16- -------------------------------------------------
    SET @process = 'Alter ccsp_AvrsSyncronization para cambiar la duration cuando se graba el hold, se agrega para IsVoicemail y borrado de varios registros'
    SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AvrsSyncronization]
@action SMALLINT,
@maxRecordsToTransfer INT = 10,
@ids varchar(max)= 0
AS
BEGIN
SET NOCOUNT ON;

IF @action = 1
BEGIN
    DECLARE @countrId INT;
    SET @countrId = 1;

    SELECT @countrId = valor
    FROM ccSettings
    WHERE setting_id = 104;

          -- Declarar la variable tipo tabla
        declare @tempCalls table(
        cal_id INT,
        user_id INT,
        Inbound_id INT,
        calif_id int,
        cal_extension INT,
        cal_inicio DATETIME,
        phone VARCHAR(50),
        duration INT,
        cal_key VARCHAR(50),
        cal_manual int,
        cal_puerto INT,
        dni_id INT,
        fvalida datetime,
        cal_whohung int,
        califSub_id int,
        cal_tMoh INT,
        dateEnd DATETIME,
        callType INT,
        avrsId INT,
        prefijo VARCHAR(20),
        isCallRecord BIT,
        DNIS VARCHAR(50),
        IDWG INT,
        IsVoicemail BIT
    );

        declare @deleteRow table(id int primary key);
        declare @relationCallIdUser table(cal_id int, user_id int);

    WITH callsIn AS (
        SELECT TOP (@maxRecordsToTransfer) 
            calls.cal_id as CallId,
            user_id,
            calls.Inbound_id,
            calls.calif_id,
            CAST(cal_extension AS INT) AS cal_extension,
            cal_inicio,
            cal_ANI AS phone,
            ISNULL(cal_tDialog - CASE WHEN ccInbound.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0) 
            + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
            cal_key,
            0 AS cal_manual,
            cal_puerto,
            calls.dni_id,
            fvalida,
            cal_whohung,
            ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
            CASE 
                WHEN trans.tAntesXfer IS NULL THEN cal_tMoh 
                WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 
                ELSE cal_tMoh - trans.tAntesXfer 
            END AS cal_tMoh,
            DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
            avrs.tipo + 1 AS callType,
            avrs.id AS avrsId,
            ccInbound.prefijo,
            CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
            ISNULL(dni.dni_numero, '''') AS DNIS,
            dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
            0 AS IsVoicemail                        
        FROM ccCallsIn AS calls WITH (NOLOCK)
        INNER JOIN ccInbound ON ccInbound.Inbound_id = calls.Inbound_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 0
        LEFT JOIN ccDNIS dni ON dni.dni_id = calls.dni_id
        LEFT JOIN ccInboundExtend inbExt ON inbExt.Inbound_id = calls.Inbound_id
        LEFT JOIN (
            SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers  with(nolock)
            WHERE tipo = 1 AND modo != 7
            GROUP BY cal_id, tipo
        ) trans ON calls.cal_id = trans.cal_id    
    ),
    callsOut AS (
        SELECT TOP (@maxRecordsToTransfer) 
            calls.cal_id AS CallId,
            user_id AS UserId,
            calls.cam_id AS camAcdId,
            CAST(calls.calif_id AS SMALLINT) AS califId,
            CAST(cal_extension AS INT) AS extension,
            cal_inicio,
            cal_telefono,
            ISNULL(cal_tDialog - CASE WHEN camps.recordHold = 1 THEN 0 ELSE cal_tMoh END, 0) 
            + CASE WHEN stopRecording = 0 THEN ISNULL(trans.tDespuesXfer, 0) ELSE 0 END AS duration,
            cal_key,
            cal_manual,
            cal_puerto,
            0 AS dni_id,
            fvalida,
            cal_whohung,
            ISNULL(CAST(califSub_id AS SMALLINT), 0) AS califSub_id,
            CASE 
                WHEN trans.tAntesXfer IS NULL THEN cal_tMoh 
                WHEN cal_tMoh - trans.tAntesXfer < 0 THEN 0 
                ELSE cal_tMoh - trans.tAntesXfer 
            END AS cal_tMoh,
            DATEADD(ss, ISNULL(cal_tDialog, 0), cal_inicio) AS dateEnd,
            avrs.tipo + 1 AS callType,
            avrs.id AS avrsId,
            camps.prefijo,
            CONVERT(BIT, CASE WHEN ISNULL(calls.file_moved, 1) = 2 THEN 0 ELSE 1 END) AS isCallRecord,
            '''' AS DNIS,
            dbo.AsignaIDWS(calls.cal_id, avrs.tipo) AS IDWG,
            CASE WHEN calls.statusCall_id = 19 THEN 1 ELSE 0 END AS IsVoicemail                        
        FROM ccoCallsOut AS calls WITH (NOLOCK)
        INNER JOIN ccCamps camps ON camps.cam_id = calls.cam_id
        INNER JOIN ccAVRSTransfer avrs ON calls.cal_id = avrs.cal_id AND avrs.tipo = 1
        LEFT JOIN (
            SELECT cal_id, tipo, SUM(tAntesXfer) AS tAntesXfer, SUM(tDespuesXfer) AS tDespuesXfer
            FROM ccLogTransfers with(nolock)
            WHERE tipo = 2
            GROUP BY cal_id, tipo
        ) trans ON calls.cal_id = trans.cal_id      
    )

    INSERT INTO @tempCalls                
    SELECT * FROM callsIn
    UNION 
    SELECT * FROM callsOut;


    insert into @deleteRow
    select min(avrsId) id
    from @tempCalls
    group by cal_id,callType 
    having count(*)>1
    
    delete from @tempCalls where avrsId in( select id from @deleteRow )
        delete from ccAVRSTransfer where id in( select id from @deleteRow )

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and callType=0)
    BEGIN   
                insert into @relationCallIdUser
                select A.cal_id,aglog.User_id from @tempCalls A
                inner join ccCallsIn B with(nolock) on A.cal_id=B.cal_id and A.callType=0
                inner join ccLogAgentesDia aglog with(nolock) on aglog.callID=B.cal_id and aglog.Tipo=A.callType and aglog.TipoStatusAge_id=4

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join ccCallsIn B with(nolock) on A.cal_id=B.cal_id 

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join @tempCalls B on A.cal_id=B.cal_id and B.callType=0
                
                delete from @relationCallIdUser
        END

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and callType=1 and IsVoicemail =0)
    BEGIN   
                insert into @relationCallIdUser
                select A.cal_id,aglog.User_id from @tempCalls A
                inner join ccoCallsOut B with(nolock) on A.cal_id=B.cal_id and A.callType=1
                inner join ccLogAgentesDia aglog with(nolock) on aglog.callID=B.cal_id and aglog.Tipo=A.callType and aglog.TipoStatusAge_id=4

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join ccoCallsOut B with(nolock) on A.cal_id=B.cal_id 

                update B set B.User_id=A.User_id
                from @relationCallIdUser A
                inner join @tempCalls B on A.cal_id=B.cal_id and B.callType=1
        END

     -- Revisar si hay registros con IsVoicemail = 1
    IF EXISTS (SELECT 1 FROM @tempCalls WHERE IsVoicemail = 1)
    BEGIN            
                update A
                set A.duration=B.tDialing
                FROM @tempCalls A
                Inner JOIN ccoLogDials B with(nolock) ON A.cal_id=B.cal_id
        WHERE A.IsVoicemail = 1;
    END

        IF EXISTS (SELECT 1 FROM @tempCalls WHERE user_id=0 and IsVoicemail=0)
    BEGIN
                delete A from ccAVRSTransfer A
                inner join @tempCalls t on A.id=t.avrsId 
                where t.user_id=0 and t.IsVoicemail=0
        END
        
    -- Si no hay registros con IsVoicemail, simplemente devolver los resultados de la variable tipo tabla
    SELECT * FROM @tempCalls;
        
END
ELSE IF @action = 2
BEGIN
    Delete A
    from ccAVRSTransfer A
    inner join dbo.fn_RIASplitDelimited(@ids,'','') t on A.id=t.Value
    
END
END;
'
        EXEC(@sql);
        
        SET @process = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr] landus Correcion log Campañas '
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@ids varchar(max)=null,
@name varchar(25) = NULL,
@top int = 0,
@dateIni datetime =null,
@dateEnd datetime =null,
@dateStart dateTime= null,
@userId int = 0,
@node varchar(10) = null,
@grabIds varchar(4000) = null
AS

declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
declare @filterWg varchar(max)
declare @len int
declare @tipo int
declare @serviceId varchar(10)

set @sql = ''''

select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=@option 

if @action in (1,6) begin --obtiene los nodos a insertar en BX
    if @action = 1 set @status =0
    else if @action = 6 set @status = 2

    if @option <>2 begin

    declare @auxTag nvarchar(10)
                            
    select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02''
    else ''@CDATE''   end
    set @parameterDefinition =N''@status int, @top int,@option int''
    set @sql=''declare @basexName varchar(max)
select @basexName=Xname from ccBaseXDB where serviceId=@option and isFull=0;
    with node ( ''+@columnId+ '',xmlString,dateNode)
    AS(
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableName + '' A with(rowlock)
        where A.status =@status
        union
        select top(@top) ''+@columnId+ '', replace(replace(convert(nvarchar(max),node),''''{'''',''''&#123;''''),''''}'''',''''&#125;'''') xmlString
        ,isNull(node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/@CDATE)[1]'''',''''datetime''''),node.value(''''(/R0'' + cast(@option as nvarchar(3)) + ''/''+@auxTag+'')[1]'''',''''datetime'''')) as dateNode
        from ''+ @tableNameHistory + '' A with(rowlock)
        where A.status =@status  
    )

    select node.''+@columnId+ '',node.xmlString,isnull(baseX.Xname,@basexName) Xname from node
    left join ccBaseXDB baseX on baseX.serviceId= @option and node.dateNode between baseX.dateStart and isnull(baseX.dateEnd,getdate())
    order by Xname''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status,@top=@top,@option=@option
    end
end
else if @action in (2,7) begin--actualiza los nodos insertados en BX
    if @action = 2 set @status =0
    else if @action = 7 set @status = 2

    set @parameterDefinition =N''@status int''

    set @sql = ''update ''+@tableName+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    select @tableName,@columnId,@ids,@sql
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status
    set @sql = ''update ''+@tableNameHistory+'' with(rowlock) set [status] = @status + 1 , dateOut = getDate() where ''+@columnId+'' in(''+@ids+'') and [status] = @status''
    --print(@sql)
    EXECUTE sp_executesql  @sql, @parameterDefinition, @status=@status

end
else if @action = 3 --trae el nombre de la base de datos en BX
begin
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
end
else if @action = 4 --inserta el nombre del xml en BX
begin
    insert into ccBaseXDB (serviceId, dateStart, Xname,[isFull]) values (@option,@dateStart, @name,0)
end
else if @action = 5 begin --obtener servicios disponibles    
    select id, ref  from ccFinderServices where isActive=1
end
else if @action = 8 begin--trae la lista de las bases para la busqueda
    select Xname from ccBaseXDB where serviceId = @option
    and (

    @dateIni between dateStart and dateEnd
    or @dateEnd between dateStart and dateEnd
    or dateStart between @dateIni and @dateEnd
    )
    union
    select Xname from ccBaseXDB where serviceId = @option and isFull=0
    and (
        dateStart between @dateIni and @dateEnd
        or @dateIni>=dateStart

    )
end
else if @action = 9 begin--Cierra la base datos
    update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()), dateStart=isnull(@dateStart,dateStart) where serviceId= @option and  isfull = 0 and dateEnd is null
    and Xname=@name
end

else if @action = 10 begin
    
    set @tipo = CASE WHEN @node = ''R06'' THEN 1 ELSE 0 END
    set @filterWg=''''
    if @node is null or @node = ''R02''
    begin
        select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId
                        
    end
    else
    begin
    
    set @serviceId = (select convert(varchar(10), id) from ccFinderServices where ref = @node)
    select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+@serviceId+'') or '' from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        where Wguser.User_id=@userId and WGCam.Tipo=@tipo
    end


    set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
    select SUBSTRING(@filterWg,0, @len)
    end


else if @action = 11 begin--trae el nombre de la base de datos en BX

    set @sql=''
    declare @dateStart datetime
    set @dateStart= convert(datetime,convert(varchar(10),getdate(),121))
    SELECT isnull(min(dateIn),@dateStart) as node FROM ''+@tableName+'' where status = 0  ''
    EXECUTE sp_executesql  @sql

end

else if @action = 13 begin
    set @sql = ''''
    select @tableName=tableName,@tableNameHistory=tableNameHistory,@columnId=columnId from ccFinderServices where id=5 
    select @tableName,@tableNameHistory,@columnId
    set @sql=''
    ;
    with duplicateIds as(
    select ''+@columnId+'',dateIn from ''+@tableName+'' where ''+@columnId+'' in(''+@grabIds+'')
    union
    select ''+@columnId+'',dateIn from ''+@tableNameHistory+'' where ''+@columnId+'' in(''+@grabIds+'')
    )

    select A.''+@columnId+'' as Id,min(B.Xname) Xname from duplicateIds A
    inner join ccbasexDB B on B.serviceId=2 and( A.dateIn between B.dateStart and B.dateEnd or A.dateIn>= B.dateStart)
    group by A.''+@columnId+'',A.dateIn
    Having count(*)>1
    order by Xname
    ''
    exec (@sql)

end

else if @action = 14 begin
    declare @CidNameOut varchar(100),@CidNameIn varchar(100)
    declare @filterCamId varchar(max), @filterInboundId varchar(max);
    declare @campType int
    declare @cidOut varchar(max)=''''
    declare @cidin varchar(max)=''''

    set @filterWg=''''
    if @node is null begin
        set @node=''R02''
    end

    set @CidNameOut=''$CID_OUT''
    set @CidNameIn=''$CID_IN''

    set @filterCamId=''''
    
    select @filterCamId=@filterCamId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
    from ccRIAWorkGroupUsers Wguser
    inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
    inner join ccCamps c on c.cam_id=WGCam.IdCampEsp --and c.CampType not in(5,7)
    where Wguser.User_id=@userId and WGCam.Tipo=1                               
    

    if @filterCamId<>'''' begin
        set @filterWg=''let ''+@CidNameOut+'':=(''

        set @filterCamId=SUBSTRING(@filterCamId,0,len(@filterCamId))
        set @filterCamId=@filterCamId+'')''+char(10)    

        set @filterWg=@filterWg+@filterCamId
        set @cidOut=''(exists(index-of($CID_OUT, $r/@CID)) and $r/@CType = CTYPE_REMPLACE)''
    end

    SET @filterInboundId= ''''
            
    select @filterInboundId=@filterInboundId+''"''+ convert(varchar(max), WGCam.IdCampEsp) +''",''
    from ccRIAWorkGroupUsers Wguser
        inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
        inner join ccInbound c on c.Inbound_id=WGCam.IdCampEsp
        where Wguser.User_id=@userId and WGCam.Tipo=0
    
    if @filterInboundId<>'''' begin
        set @filterInboundId=SUBSTRING(@filterInboundId,0,len(@filterInboundId))
        set @filterInboundId=@filterInboundId+'')''+char(10)    

        set @filterWg=@filterWg+''let ''+@CidNameIn+'':=(''+@filterInboundId
        set @cidin=''(exists(index-of($CID_IN, $r/@CID)) and $r/@CType = CTYPE_REMPLACE)''
    end
    
    select @filterWg as VarCamInOut,@cidOut as CidOut,@cidin as CidIn
end
else if @action = 15 begin --Saber si hacer busqueda en basex
  select @tableName=tableName,@tableNameHistory=tableNameHistory from ccFinderServices where ref=@node
  if @node=''R02'' begin
    select 1
    return(0)
  end

  set @sql=''if exists(select * from ''+@tableName+'') begin
        select 1
    end
    else if exists(select * from ''+@tableNameHistory+'') begin
        select 1
    end
    select 0''
    exec (@sql)
    
end'
    EXEC(@sql);

SET @process = 'Drop procedure ccsp_DLRAfterInsertCall'
    SET @sql = 'if exists (select 1 from sys.procedures where name = N''ccsp_DLRAfterInsertCall'')
begin
    DROP PROCEDURE ccsp_DLRAfterInsertCall;
end'
     EXEC(@sql);

     SET @process = 'feature/KR179003 Alter SP ccsp_DLRAfterInsertCall'
     SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_DLRAfterInsertCall]
@cam_id smallint,
@cal_id BIGINT=0,
@status int=0
AS
set nocount on

if @status = 0 begin
  set @status = 6 --Status 6=Pide Agente
end
else if @status=19
begin
    update ccoCallsOut set statusCall_id=@status where cal_id =@cal_id;
    insert into ccAVRSTransfer(cal_id,tipo) values(@cal_id,1)
    return
end

insert into ccRIAWorkGroup_Calid (IDWG, cal_id, User_id, timestamp, tipo)
select idwg, @cal_id, 0 as user_id, getdate() timestamp, 1 as tipo from ccRIACampEspWG wg with(nolock)
where wg.Tipo=1 and wg.idcampesp=@cam_id

exec ccspSaveDispositionResult @action=1,@callid=@cal_id, @camId=@cam_id,@callType=1,@statusCallId=@status

set nocount off'
    EXEC(@sql);
       

        SET @process = 'feature/KR179003 Alter SP ccsp_DLRSaveDialResult 
landus ccRIAWorkGroup_logDial_id se quita por que no se ocupa en los reportes'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRSaveDialResult] 
@callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
@tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
@canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '''', @cal_key VARCHAR(40)= '''', @call_TS VARCHAR(15)='''',
@ani varchar(32)=''''
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @tNow AS DATETIME, @RecicleSIC TINYINT;
    DECLARE @logDial_id INT;
    DECLARE @tAnswerBitFinal AS DATETIME;
    DECLARE @tTotal SMALLINT;

    SELECT @RecicleSIC = ISNULL(valor, 0)
    FROM ccSettings
    WHERE setting_id = 60;

    SELECT @tTotal = @tDialing + @tAnswerBit;

    SELECT @tNow = GETDATE();

    SELECT @tAnswerBitFinal = DATEADD(ss, -@tAnswerBit, @tNow);


-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
IF @call_id > 0 AND @tipoResDial_id = 1 and @cal_key = ''''
    BEGIN
    SELECT @cal_key = cal_key
    FROM ccoCallsOutSource WITH(NOLOCK)
    WHERE @callout_id = callout_id;         
END;

IF @call_id > 0 AND @tipoResDial_id = 1
BEGIN
        INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
        TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani )
               SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
               ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.
               fnGetTipoLlamada( @Telefono ), @ani;
    END;
         ELSE
    BEGIN
        INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
        TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id, ani )
               SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
               ''000000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(
               @Telefono ), @ani;
    END;

    SELECT @logDial_id = SCOPE_IDENTITY();

    IF @RecicleSIC = 1
    BEGIN
        UPDATE ccoWorkingTable WITH(ROWLOCK)
          SET tipoResDial_id = @tipoResDial_id
        WHERE callout_id = @callout_id;
    END;

    -- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
IF @call_id > 0 AND @tipoResDial_id = 1
    BEGIN
        UPDATE ccoCallsOut WITH(ROWLOCK)
    SET cal_puerto = @Puerto, cal_manual = CASE WHEN cal_manual = 1 THEN 2 ELSE cal_manual END
    WHERE cal_id = @call_id AND cal_puerto = 0;

        EXEC ccsp_CstoCalculaCosto @call_id;
    END;
        else IF @call_id > 0 AND @tipoResDial_id = 11
BEGIN
        UPDATE ccoCallsOut WITH(ROWLOCK)
    SET cal_puerto = @Puerto
    WHERE cal_id = @call_id AND cal_puerto = 0;

end
  
    -- Guarda configuracion de TipoDialingMode
    UPDATE ccoLogDials WITH(ROWLOCK)
      SET TipoDialingMode = dbo.fn_getDialingMode( @call_id, 0, @logDial_id, @cam_id )
    WHERE logDial_id = @logDial_id;
    SET NOCOUNT OFF;
END;

    SELECT @logDial_id as LogDialId'
        EXEC(@sql);

        SET @process = 'feature/KR179003 update ccSettings setting_id=236'
        SET @sql = 'update ccSettings 
set detalle=''Habilita la grabacion de audio antes de que se conteste la llamada (Early Media). 0-Deshabilitado, 1-Habilitado,2- grabacion early media en buzon''
,description=''Enable audio recording before the call is answered (Early Media). 0-Disabled, 1-Enabled, 2- recording early media en voicemail''
where setting_id=236
'
        EXEC(@sql);

        SET @process = 'feature/KR179003 Add ccStatusLLamada Buzon'
        SET @sql = 'if not exists(select * from ccStatusLLamada where statusCall_id=19) begin
        insert into ccStatusLLamada (statusCall_id,descripcion,inAbandonConfig)
        values (19,''Buzon'',0)
end'
        EXEC(@sql);

        SET @process = 'Alter Funcion fnGetTipoLlamada mejora en el manejo y se valida si no es mexico no compare la lada'
        SET @Sql = 'ALTER FUNCTION [dbo].[fnGetTipoLlamada](@tel VARCHAR(32))
RETURNS TINYINT
AS
BEGIN
    DECLARE @ladatemp VARCHAR(5), @ldlocal VARCHAR(10), @serie VARCHAR(10), @numeracion SMALLINT, @length TINYINT
    DECLARE @mod VARCHAR(10), @country TINYINT, @lengthStr VARCHAR(10)
    DECLARE @tipoLlamada_id SMALLINT = 0, @tipo TINYINT = 0, @cantidadLL TINYINT

    -- Recuperar cÃ³digo de paÃ­s y cÃ³digo de Ã¡rea local de las configuraciones
    SELECT @country = valor FROM ccsettings WITH (NOLOCK) WHERE setting_id = 104
    SELECT @ldlocal = valor FROM ccSettings WITH (NOLOCK) WHERE setting_id = 17

        set @length = LEN(@tel)
    SET @lengthStr = CONVERT(VARCHAR(10), @length)

    -- Tabla para almacenar los tipos de llamadas
    DECLARE @t_tipos TABLE (
        tipollamada_id INT NOT NULL,
        prefijo NVARCHAR(100) NOT NULL,
        rowid INT NOT NULL
    )

    -- Si el paÃ­s es igual a 1
    IF @country = 1
    BEGIN
        -- Insertar prefijos especÃ­ficos para el paÃ­s 1 (local)
        INSERT INTO @t_tipos
        SELECT tipoLlamada_id, prefijo, ROW_NUMBER() OVER (ORDER BY LEN(prefijo) DESC) AS rowid
        FROM cstoTipoLlamada WITH (INDEX(IX_cstoTipoLlamada), NOLOCK)
        WHERE country_id = 1
        AND tipoLlamada_id NOT IN (8, 9, 10, 11, 12)  -- Excluir ciertos tipos de llamadas
        AND CHARINDEX(@lengthStr, longitud) > 0  -- Usamos CHARINDEX para encontrar la longitud
    END
    ELSE
    BEGIN
        -- Insertar prefijos para paÃ­ses que no son el paÃ­s 1
        INSERT INTO @t_tipos
        SELECT tipoLlamada_id, prefijo, ROW_NUMBER() OVER (ORDER BY LEN(prefijo) DESC) AS rowid
        FROM cstoTipoLlamada WITH (INDEX(IX_cstoTipoLlamada), NOLOCK)
        WHERE country_id = @country
        AND CHARINDEX(@lengthStr, longitud) > 0  -- Usamos CHARINDEX en lugar de LIKE
    END

    -- Verificar si existen registros coincidentes
    SELECT @cantidadLL = COUNT(*) FROM @t_tipos

    IF @cantidadLL > 0
    BEGIN
        -- Buscar la mejor coincidencia (para ambos casos de paÃ­s)
        SELECT TOP 1 @tipo = tipollamada_id
        FROM @t_tipos t
        CROSS APPLY dbo.fn_RIASplitDelimited(t.prefijo, ''|'') AS splitPrefijo
        WHERE @tel LIKE splitPrefijo.value + ''%''
        ORDER BY LEN(splitPrefijo.value) DESC
    END
    ELSE
    BEGIN
        -- BÃºsqueda por defecto en cstoTipoLlamada si no hay coincidencias
        SELECT TOP 1 @tipoLlamada_id = tipoLlamada_id
        FROM cstoTipoLlamada WITH (INDEX(IX_cstoTipoLlamada), NOLOCK)
        CROSS APPLY dbo.fn_RIASplitDelimited(cstoTipoLlamada.prefijo, ''|'') AS split
        WHERE country_id = @country
        AND longitud = ''0''
        AND @tel LIKE split.value + ''%''
        AND (country_id <> 1 OR (country_id = 1 AND tipoLlamada_id NOT IN (8, 9, 10, 11, 12)))
        ORDER BY LEN(split.value) DESC

        IF @tipoLlamada_id > 0
        BEGIN
            SET @tipo = @tipoLlamada_id
        END
        ELSE IF @country != 1
        BEGIN
            -- Si no es el paÃ­s 1 y no hay coincidencias, regresar @tipo
            RETURN @tipo
        END
        ELSE
        BEGIN
            -- LÃ³gica adicional cuando es el paÃ­s 1
            IF @length = 10 - LEN(@ldlocal)
            BEGIN
                -- Ajustar el nÃºmero de telÃ©fono segÃºn la longitud
                SELECT @tel = CONVERT(VARCHAR(3), @ldlocal) + @tel
            END

            -- Reestructurar el nÃºmero para verificar prefijos
            SELECT @tel = RIGHT(@tel, 10)
            SELECT @ladatemp = LEFT(@tel, 2)

            -- Verificar prefijos de dos dÃ­gitos
            IF @ladatemp IN (''55'', ''56'', ''33'', ''81'')
            BEGIN
                SELECT @serie = SUBSTRING(@tel, 3, 4), 
                       @numeracion = RIGHT(@tel, 4)                
            END
            ELSE
            BEGIN
                -- Verificar prefijos de tres dÃ­gitos                
                SELECT @ladatemp = LEFT(@tel, 3), 
                                           @serie = SUBSTRING(@tel, 4, 3), 
                       @numeracion = RIGHT(@tel, 4)                
            END

            -- Buscar modalidad en la tabla `Series`
            SELECT TOP 1 @mod = MODALIDAD 
            FROM Series WITH (NOLOCK) 
            WHERE CLD = @ladatemp 
            AND SERIE = @serie 
            AND @numeracion BETWEEN [NUMERACION INICIAL] AND [NUMERACION FINAL]

            -- Verificar si el nÃºmero es local
            DECLARE @isLocal BIT = 0

            IF EXISTS (SELECT 1 FROM ccRiaArecode WITH (NOLOCK) WHERE area = @ladatemp)
               OR @ldlocal = @ladatemp
            BEGIN
                SET @isLocal = 1;
            END

            -- Determinar el tipo de llamada segÃºn la modalidad y si es local
            IF @mod IN (''FIJO'', ''MPP'')
            BEGIN
                -- Llamada fija o mÃ³vil postpago
                SET @tipo = CASE 
                            WHEN @isLocal = 1 THEN 1  -- Llamada local
                            ELSE 2                     -- Llamada de larga distancia
                        END;
            END
            ELSE IF @mod = ''CPP''
            BEGIN
                -- Llamada celular prepago
                SET @tipo = CASE 
                            WHEN @isLocal = 1 THEN 3  -- Llamada celular local
                            ELSE 4                    -- Llamada celular de larga distancia
                        END;
            END
        END
    END

    RETURN @tipo
END
'
         EXEC (@Sql)
--------------------------- End Jesus 125.20231211.0.18 ----------------------------------------------------------------------------------
----------------------------------------------------------- Begin Luis Miguel Zamora Nuñez 125.20231211.0.19-------------------------------------------------------------------------

SET @process = 'K069001, K69003 - ccsp_GalateaCreateUser - SP Edited, Editado para corregir el registro de usuarios (Agentes y Administradores), 
Se asigna el LastName a @ApellidoPaterno = @LastName, y NombreOpcionalExtra a  @ApellidoMaterno = @NombreOpcionalExtra'
SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaCreateUser]
@UserId int,
@Login varchar(40),
@Nombres varchar(45),
@LastName varchar(45),
@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
@Password varchar(200),
@Sexo bit,
@canChangeStatus bit,
@AreaId int,
@UserType tinyint,
@AdminId int
as

Declare @ApellidoMaterno varchar(45)
Declare @ApellidoPaterno varchar(45)

--Obtiene el idioma de de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

set @ApellidoPaterno = @LastName
set @ApellidoMaterno = @NombreOpcionalExtra

-- validaciones 
    if exists(select Login from ccUsers where Login=@Login)
    begin
    select -1 as ResponseCode--,Login en Uso
    return(0)
    end

    if exists(select Login from ccUsers_Consulta where Login = @Login)
    begin
    select -4 as ResponseCode -- Login en Uso aunque el usuario ya se halla borrado de la base de datos -- quiza falta la validacion cuando el usuario ya se ha borrado pero mediante borrado logico
    return(0)
    end

    if exists(select Nombres from ccUsers where Nombres=@Nombres
    and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
    begin
    select -2 as ResponseCode--,Nombre completo en Uso-- valida todos los campos de nombre para ver que no existan en la base de datos
    return(0)
    end


--insert
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
    select -3 as ResponseCode --Error_when_inserting_user
    return(0)
    end

    set identity_insert ccusers on
    insert into ccUsers(user_id,Login,Nombres,ApellidoPaterno,ApellidoMaterno,Password,TipoUser_id, Status,TipoLLamadas,Sexo,canChangeStatus,IDArea)
    select @UserId, @Login,@Nombres,@ApellidoPaterno,@ApellidoMaterno,@Password,@UserType,1,3,@Sexo,@canChangeStatus, case when @AreaId=0 then null else @AreaId end
    set identity_insert ccusers off

    delete ccMenuUser where id_User = @UserId
    delete ccRIAUserRole where user_id = @UserId

    exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

    --Insert Agent into ccRIAAgentsPermissions
    IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
    BEGIN
    IF NOT EXISTS (SELECT * FROM ccRIAAgentsPermissions WHERE AgentId = @UserId)
    BEGIN 
        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
        VALUES (@UserId, 0, 0, 1)
    END
    END

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

    --INSERT INTO ACTIVITY LOG, CREATE AGENT
    DECLARE @areaName AS VARCHAR(40);
    DECLARE @userLogin AS VARCHAR(40);
    SET @userLogin = (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId);

    IF(@AreaId <> 0) BEGIN
        SET @areaName = (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId);
    END

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
    VALUES (CASE WHEN @AreaID = 0 THEN NULL ELSE @areaName END, getDate(), @userLogin, CASE WHEN @UserType = 1 THEN 22 ELSE 29 END, 3, '''', '''', @Login);

END
    insert into ccMenuUser(id_User,id_Menu,type) select @UserId,id_Menu,1 from ccRIARoleMenu where Role_id=3
    insert into ccMenuUser(id_User,id_Menu,type)values(@UserId,40,1)
    insert into ccRIAUserRole(User_id,Role_id,type)values(@UserId,3,1)
    --Menu para roles RepotsRia
    exec ccsp_RIAMenuRoles @Type= 13,@User_id = @UserId

    --Insert Agent into ccRIAAgentsPermissions
    IF EXISTS (SELECT * FROM ccUsers WHERE User_id = @UserId AND TipoUser_id = 1) 
    BEGIN
    IF NOT EXISTS (SELECT * FROM ccRIAAgentsPermissions WHERE AgentId = @UserId)
    BEGIN 
        INSERT INTO ccRIAAgentsPermissions(AgentId, AllowUnassign, AllowSpam, AllowPlayRecordsOnCallHistory)
        VALUES (@UserId, 0, 0, 1)
    END 
    END
select 200 as ResponseCode -- indica que se agrego correctamente un nuevo usuario
'
EXEC(@sql)

SET @process = 'K069002, K069004 - ccsp_GalateaUpdateUser - SP Edited, 
Se asigna el LastName a @ApellidoPaterno = @LastName, y NombreOpcionalExtra a  @ApellidoMaterno = @NombreOpcionalExtra'
SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateUser]
@UserId int,
@Login varchar(40),
@Nombres varchar(45),
@LastName varchar(45),
@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
@Sexo bit,
@canChangeStatus bit,
@AdminId int,
@AreaId int
as

Declare @ApellidoMaterno varchar(45)
Declare @ApellidoPaterno varchar(45)
Declare @userIdOnDb int
Declare @LoginOnDb varchar(40)
--Obtiene el idioma de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

set @ApellidoPaterno = @LastName
set @ApellidoMaterno = @NombreOpcionalExtra

-- validaciones 
    if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
        begin
        select -5 as ResponseCode--,''el usuario no existe''
        return(0)
        end

  if exists(select Nombres from ccUsers where Nombres=@Nombres
  and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
    begin

        select @userIdOnDb =User_id from ccUsers where Nombres=@Nombres
      and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

        select @LoginOnDb =User_id from ccUsers where Nombres=@Nombres
      and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

      if @UserId <> @userIdOnDb and @Login <> @LoginOnDb
        begin
            select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
            return(0)
        end
    end

--update and insert into activity log a record for each modified property

    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId=@UserId, @userId= @userId

    Update ccUsers set 
    Nombres=@Nombres,
    ApellidoPaterno=@ApellidoPaterno,
    ApellidoMaterno=@ApellidoMaterno,
    Sexo=@Sexo,
    canChangeStatus=@canChangeStatus
    where User_id=@UserId

    DECLARE @CCUsersTable TABLE 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    )

    INSERT INTO @CCUsersTable EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccUsers'', @columnNameId = ''User_id'', @valueId = @UserId, @userId = @userId;

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target) 
    SELECT 
        (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId),
        getDate(), 
        (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
        CASE WHEN (SELECT [TipoUser_id] FROM ccUsers WHERE User_id = @UserId) = 1 THEN 25 ELSE 32 END, 
        3, 
        CUT.identifierInfo,
        CASE WHEN CUT.identifierInfo IS NOT NULL THEN
            CASE 
                WHEN CUT.identifierInfo = ''T&EDIT_GENDER_USER'' THEN CONCAT(CUT.identifierInfo, CASE WHEN CUT.dataInfo = 1 THEN ''_M'' ELSE ''_F'' END)
                ELSE CUT.dataInfo END
        ELSE '''' END, 
        (SELECT [Login] FROM ccUsers WHERE User_id = @UserId)
    FROM @CCUsersTable AS CUT;

    EXEC InsertLogAdminGalatea @action=3, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId = @UserId, @userId = @userId

select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
'
EXEC(@sql)


SET @process = 'ccsp_GalateaLoadUsersForManagement - SP Edited, Editado para el envio correcto de datos al front.
Se asigna el LastName a @ApellidoPaterno = @LastName, y NombreOpcionalExtra a  @ApellidoMaterno = @NombreOpcionalExtra'
SET @sql = 'ALTER PROCEDURE ccsp_GalateaLoadUsersForManagement
    @option SMALLINT,
    @AreaId SMALLINT = null,
    @UserType INT = null,
    @Username VARCHAR(200) = null,
    @userId INT = 0,
    @groupList VARCHAR(MAX) = null
AS

--Obtiene el idioma de de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para espanol, 1 para ingles, 2 para portugues

IF @option = 1 --Agentes/supervisores de un Area
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  ApellidoPaterno as LastName,
  ApellidoMaterno as OptionalExtraName,
  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
        AND DATEDIFF(dd, LastLoginAttempt, getdate()) < 60
  ORDER BY LOGIN, Nombres, ApellidoPaterno,Sexo, User_id

  RETURN (0)
END

IF @option = 2 -- obtiene Agente o supervisor en base a su nombre de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  ApellidoPaterno as LastName,
  ApellidoMaterno as OptionalExtraName,
  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE Login=@Username

  RETURN (0)
END

IF @option = 3 -- obtiene Agente o supervisor en base a su ID de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  ApellidoPaterno as LastName,
  ApellidoMaterno as OptionalExtraName,
  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE user_id=@userId

  RETURN (0)
END

IF @option = 4 -- supervisores en Area/Sistema
BEGIN
        DECLARE @Admins TABLE (UserId smallint, Username varchar(50), Names varchar(50), LastName varchar(50), OptionalExtraName varchar(50), AreaId smallint, primary key(UserId))
        INSERT INTO @Admins
        SELECT User_id as UserId,
        LOGIN as Username,
        Nombres as Names,
        ApellidoPaterno as LastName,
        ApellidoMaterno as OptionalExtraName,

        isnull(IDArea, 0) as AreaId
        FROM ccusers
        WHERE TipoUser_id = 2 AND STATUS = 1


        IF NOT EXISTS(SELECT * FROM ccUsers_Roles WHERE User_id=@userId and Rol_id=7) BEGIN
                SELECT UserId, Username, Names, LastName, OptionalExtraName
                FROM @Admins
                WHERE AreaId = (SELECT IDArea FROM ccUsers WHERE User_id=@userId)
                ORDER BY Username, Names, LastName, UserId
        END
        ELSE BEGIN
                SELECT UserId, Username, Names, LastName, OptionalExtraName
                FROM @Admins
                ORDER BY Username, Names, LastName, UserId
        END
        Return(0)
END

IF @option = 5 --Usuarios inactivos por mas de 60 dias por area
BEGIN
        SELECT [User_id] as UserId,
        LOGIN as Username
        FROM CCUSERS WHERE DATEDIFF(dd, LastLoginAttempt, getdate()) >= 60
        AND @AreaId = IDArea
        RETURN 0;
END

IF @option = 6 -- Usuarios inactivos por más de 60 días por grupo de trabajo, correccion del ticket TT13248
BEGIN
        DECLARE @tempTable TABLE (Id INT)

        INSERT INTO @tempTable
        SELECT value FROM fn_RIASplitDelimited(@groupList, '','')


        SELECT 
        CAST(wgu.IDWG AS VARCHAR(10)) AS idwg,
        STUFF((
                SELECT '', '' + CAST(wgu2.User_id AS VARCHAR)
                FROM ccUsers u2
                INNER JOIN ccRIAWorkGroupUsers wgu2 ON wgu2.User_id = u2.User_id
                WHERE wgu2.IDWG = wgu.IDWG
                        AND u2.LastLoginAttempt <= DATEADD(DAY, -60, GETDATE())
                FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''') AS agents
        FROM ccUsers u
        INNER JOIN ccRIAWorkGroupUsers wgu ON wgu.User_id = u.User_id
        WHERE 
               wgu.IDWG IN (SELECT Id FROM @tempTable)
                AND u.LastLoginAttempt <= DATEADD(DAY, -60, GETDATE())
        GROUP BY wgu.IDWG
        ORDER BY wgu.IDWG;
        RETURN 0;

END'
EXEC(@sql)
----------------------------------------------------------- End Luis Miguel Zamora Nuñez -------------------------------------------------------------------------
        SET @process = 'landus Alter SP InsertLogAdminGalatea @action=2  Correcion log Campañas '
        SET @sql = 'ALTER procedure [dbo].[InsertLogAdminGalatea]
@action int 
,@tableName VARCHAR(255)
,@columnNameId VARCHAR(255)
,@valueId VARCHAR(255)
,@userId int
,@tableTemp varchar(255)=null
as
SET NOCOUNT ON;

    -- Insert statements for procedure here
declare @sql nvarchar(max),@sql2 nvarchar(max)
DECLARE @tableNameTmp VARCHAR(255) = ''##''+@tableName+''_''+convert(varchar(10),@userId)

if @action =1 begin --Antes del cambio

        set @sql=''IF OBJECT_ID(N''''tempdb..''+@tableNameTmp+'''''') IS NOT NULL DROP TABLE ''+@tableNameTmp+''
        SELECT * INTO ''+@tableNameTmp+'' FROM ''+@tableName+'' WHERE ''+@columnNameId+'' = ''+@valueId
        --print(@sql)
        exec(@sql)

end
else if @action=2 begin
    DECLARE @columns NVARCHAR(MAX) = '''';
        DECLARE @conditions NVARCHAR(MAX) = '''';
        DECLARE @caseStatements NVARCHAR(MAX) = '''';
        DECLARE @batchSize INT = 10; -- Tamaño del bloque de columnas
        DECLARE @counter INT = 0;
        declare @emtpy varchar(2)=''''
        

        -- Declarar una variable de tipo tabla para almacenar los IDs de cada bloque
        DECLARE @BatchColumns TABLE (
                name NVARCHAR(128),
                batch_id INT
        );
        -- Insertar en @BatchColumns las columnas de la tabla, dividiéndolas en bloques
        INSERT INTO @BatchColumns (name, batch_id)
        SELECT 
                name,
                (ROW_NUMBER() OVER (ORDER BY column_id) - 1) / @batchSize AS batch_id
        FROM 
                sys.columns
        WHERE 
                object_id = OBJECT_ID(@tableName)
                AND name <> @columnNameId  -- Excluir la columna clave primaria
                AND name <> ''rowguid'';  -- Excluir la columna clave primaria

        -- Insertar batch_ids únicos en la variable de tipo tabla @BatchIds
        DECLARE @BatchIds TABLE (
                batch_id INT PRIMARY KEY
        );

        INSERT INTO @BatchIds
        SELECT DISTINCT batch_id FROM @BatchColumns;

        DECLARE @batch_id INT = 0;

        -- Bucle para procesar cada bloque de columnas
        WHILE EXISTS (SELECT 1 FROM @BatchIds WHERE batch_id = @batch_id)
        BEGIN
                -- Construir las expresiones CASE y las condiciones WHERE para este bloque
                SET @caseStatements = '''';
                SET @conditions = '''';

                -- Construir el CASE y el WHERE para cada columna en el bloque actual
                SELECT 
                        @caseStatements = @caseStatements + 
                        ''SELECT '''''' + name + '''''' AS columnInfo, CONVERT(VARCHAR(300), A.'' + QUOTENAME(name) + '') AS dataInfo '' +
                        ''FROM '' + @tableName + '' AS A '' +
                        ''FULL OUTER JOIN '' + @tableNameTmp + '' AS B ON A.'' + QUOTENAME(@columnNameId) + '' = B.'' + QUOTENAME(@columnNameId) + '' '' +
                        ''WHERE A.'' + QUOTENAME(name) + '' <> B.'' + QUOTENAME(name) + '' UNION ALL ''
                FROM 
                        @BatchColumns
                WHERE 
                        batch_id = @batch_id;                   

                -- Construir las condiciones WHERE para el bloque actual
                SELECT @conditions = @conditions + 
                CASE WHEN @conditions = '''' THEN '''' ELSE '' OR '' END +
                ''A.'' + QUOTENAME(name) + '' <> B.'' + QUOTENAME(name)
                FROM 
                        @BatchColumns
                WHERE 
                        batch_id = @batch_id;

                -- Remover el último UNION ALL sobrante
                SET @caseStatements = LEFT(@caseStatements, LEN(@caseStatements) - LEN('' UNION ALL ''));
                
                -- Construir y ejecutar la consulta para este bloque
                IF @caseStatements <> ''''
                BEGIN
                        SET @sql = ''
                        INSERT INTO ''+@tableTemp+'' (columnInfo, dataInfo)
                        '' + @caseStatements + ''                       
                        '';

                        --print @sql
                        -- Ejecutar la consulta dinámica
                        EXEC sp_executesql @sql;
                END     

                -- Avanzar al siguiente bloque
                SET @batch_id = @batch_id + 1;
        END


        -- Consultar el resultado final de cambios
        set @sql=
        ''SELECT distinct A.columnInfo,A.dataInfo,isnull(B.Identifiers,@emtpy) as identifierInfo 
        FROM ''+@tableTemp+'' A 
        left join relationTableColumnIdentifiers B on A.columnInfo=B.colunName and B.tableName=@tableName
        ''
        
        if @tableTemp is not null and @tableTemp<>'''' begin
                set @sql= ''insert into ''+@tableTemp +'' ''+ @sql
        end
        print @tableName
        print @sql
        EXEC sp_executesql @sql
        ,N''@tableName varchar(255), @emtpy varchar(2)'',
    @tableName = @tableName,@emtpy=@emtpy

end
else if @action =3 begin
        set @sql=''IF OBJECT_ID(N''''tempdb..''+@tableNameTmp+'''''') IS NOT NULL DROP TABLE ''+@tableNameTmp
        --print(@sql)
        exec(@sql)
end'
        EXEC(@sql);

--------------------------- End Jesus 125.20231211.0.18 ----------------------------------------------------------------------------------
        --------------------------- Begin Jesus 125.20231211.0.20 ----------------------------------------------------------------------------------
         SET @process = 'ALTER SP ccsp_ccActivityDataQuery @action 12,13,14 cambio @packageData por filas de 8000 caracetres'
        SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_ccActivityDataQuery]
@action int,@userId int=0,@camId int=0,@dnisId int=0,@WgId int=0,@tipo int =null
,@camIdOuts varchar(1000)='''',@camIdIns varchar(1000)='''',@userIds varchar(max)=''''
AS
set nocount on

declare @valdiate int
declare @packageData varchar(max)
DECLARE @blockSize INT = 8000; -- Tamaño del bloque.
declare @nTipoCallTotal int
set @packageData =''''
set @valdiate=0
set @nTipoCallTotal=0

if @action=1 begin      
if exists(select * from cccamps nolock where cam_bNew=1) begin
        set @valdiate=1
        Update ccCamps SET cam_bNew=0 Where cam_bNew=2
        Update ccCamps SET cam_bNew=2 Where cam_bNew=1
end     
select @valdiate as isUpdate
end
else if @action=2 begin         
if exists(select * from cccamps nolock where cam_bNew=3) begin
set @valdiate=1
        Update ccCamps SET cam_bNew=0 Where cam_bNew=4
        Update ccCamps SET cam_bNew=4 Where cam_bNew=3
end
select @valdiate as isUpdate
end
else if @action=3 begin         
SELECT User_id, TipoLlamadas FROM ccUsers WHERE User_ID = @userId
end
else if @action=4 begin 
SELECT A.Login, A.User_id, prioridad, skill, A.TipoLlamadas, C.cam_id, C.cam_descripcion, C.cli_id 
FROM ccCamps C JOIN ccCampsAgente CA ON C.cam_id = CA.cam_id 
JOIN ccUsers A  ON A.User_id = CA.User_id 
AND A.TipoUser_Id =1 AND C.cam_id =  @camId
order by A.Login, A.User_id, CA.prioridad, CA.skill, C.cam_id
end
else if @action=5 begin 
SELECT Login, TipoLlamadas, User_id, password, Nombres +'' ''+ ApellidoPaterno FROM ccUsers nolock WHERE User_id = @userId
end
else if @action=6 begin 
SELECT Inbound_id, descripcion, cli_id FROM ccInbound nolock WHERE Inbound_id =@camId
end
else if @action=7 begin 
SELECT Inbound_id, descripcion, cli_id, tnotas, nMaxQue FROM ccInbound WHERE Inbound_id = @camId
end
else if @action=8 begin 
SELECT dni_id, dni_numero, T.tipodni_id, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join ccTipoDNIS T on D.tipodni_id = T.tipodni_id 
WHERE dni_id = @dnisId and dni_tipo=2
end
else if @action=9 begin 
SELECT dni_id, dni_numero, dni_tipo, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join ccTipoDNIS T on D.tipodni_id=T.tipodni_id 
WHERE dni_id = @dnisId and dni_tipo=2
end
else if @action=10 begin        
SELECT dni_id, dni_numero, D.tipodni_id, prioridad, dni_tpoMaxEspera 
FROM ccDNIS D join cctipoDnis TD on D.tipodni_id = TD.tipodni_id
WHERE dni_tipo=2
end
else if @action=11 begin        
SELECT Inbound_id, descripcion, tNotas, nMaxQue FROM ccInbound
end
else if @action = 12 begin 
; with WgUser AS(
select 
WG.IDWG,A.IdCampEsp,A.Tipo from ccRIAWorkGroupUsers WG
inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
inner join ccRIACampEspWG A on A.IDWG=WG.IDWG   
where WG.IDWG<>@WgId
)
, wGCamp AS(
select IDWG, IdCampEsp,Tipo from ccRIACampEspWG A
where A.IDWG in(select IDWG from WgUser) or A.IDWG=@WgId
), dataDiferent as
(
select distinct 
convert(varchar, A.IdCampEsp)+''-''+convert(varchar,A.Tipo+1)  
+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1)) 
+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))
as CampAndType
from wGCamp A
left join WgUser B on A.IdCampEsp=B.IdCampEsp and A.Tipo=B.Tipo 
left join ccCampsAgente campAgent on A.IdCampEsp = campAgent.cam_id and A.Tipo=1
left join ccInboundAgentes inboundAgent on A.IdCampEsp = inboundAgent.inbound_id and A.Tipo=0
where B.IdCampEsp is null
)
select @packageData=CampAndType+'',''+@packageData from dataDiferent    

select  @nTipoCallTotal = A.Tipo+1 +@nTipoCallTotal 
from ccRIAWorkGroupUsers WG
inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
inner join ccRIACampEspWG A on A.IDWG=WG.IDWG   
where WG.User_id=@userId
group by A.Tipo                 

;WITH BlockIndices AS (
        SELECT TOP ((LEN(@packageData) + @blockSize - 1) / @blockSize) -- Calcula cuántos bloques son necesarios.
                   (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) * @blockSize + 1 AS StartIndex
        FROM master.dbo.spt_values -- Usamos una tabla auxiliar para generar números.
)
SELECT                  
        convert(varchar(8000), SUBSTRING(@packageData, StartIndex, @blockSize)) AS packageData, @nTipoCallTotal as nTipoCallTotal
FROM BlockIndices
WHERE StartIndex <= LEN(@packageData); -- Asegúrate de no exceder la longitud.


end

else if @action = 13 begin 
; with WgCamp As(
select IDWG,IdCampEsp,tipo from ccRIACampEspWG A
where tipo=@tipo and IdCampEsp=@camId and IDWG<>@WgId
)
, WgUserCamp as(
select C.Login,WGUser.User_id,WgCamp.* from ccRIAWorkGroupUsers WGUser
inner join WgCamp on WGUser.IDWG=WgCamp.IDWG 
inner join ccUsers C on WGUser.User_id=C.User_id and C.TipoUser_id=1
), dataDiferent as(     

select distinct convert(varchar, WG.User_id)
+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1))
+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))        CampAndType
from ccRIAWorkGroupUsers WG     
inner join ccUsers C on WG.User_id=C.User_id and C.TipoUser_id=1
left join ccCampsAgente campAgent on campAgent.user_id=c.User_id
left join ccInboundAgentes inboundAgent on inboundAgent.User_id=c.User_id
where Wg.IDWG=@WgId and Wg.User_id not in(select User_id from WgUserCamp)
)

select @packageData=CampAndType+'',''+@packageData from dataDiferent 

-- Generar un rango de índices para dividir la cadena en bloques.
;WITH BlockIndices AS (
        SELECT TOP ((LEN(@packageData) + @blockSize - 1) / @blockSize) -- Calcula cuántos bloques son necesarios.
                   (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) * @blockSize + 1 AS StartIndex
        FROM master.dbo.spt_values -- Usamos una tabla auxiliar para generar números.
)
SELECT                  
        convert(varchar(8000), SUBSTRING(@packageData, StartIndex, @blockSize)) AS packageData
FROM BlockIndices
WHERE StartIndex <= LEN(@packageData); -- Asegúrate de no exceder la longitud.

end
else if @action = 14 begin --Delete WG
; with wgCam as (
select Value as camId,1 calltype from dbo.fn_RIASplitDelimited(@camIdOuts,'','')
union
select Value as camId,0 calltype from dbo.fn_RIASplitDelimited(@camIdIns,'','')
)
, relationUser as(

select campWg.IdCampEsp as camId,campWg.Tipo from ccRIAWorkGroupUsers WG
inner join ccRIACampEspWG campWg on campWg.IDWG=Wg.IDWG         
where WG.User_id=@userId
)
, dataDiferent  as
(       
select distinct convert(varchar, wgCam.camId)+''-''+convert(varchar,wgCam.callType+1)   as CampAndType
from wgCam
left join relationUser A on wgCam.camId=A.camId and wgCam.calltype=A.Tipo
where A.camId is null
)

select @packageData=CampAndType+'',''+@packageData from dataDiferent

select  @nTipoCallTotal = A.Tipo+1 +@nTipoCallTotal 
from ccRIAWorkGroupUsers WG
inner join ccRIACat_WorkGroup CatWg on CatWg.IDWG=WG.IDWG and WG.User_id=@userId
inner join ccRIACampEspWG A on A.IDWG=WG.IDWG   
where WG.User_id=@userId
group by A.Tipo 

;WITH BlockIndices AS (
        SELECT TOP ((LEN(@packageData) + @blockSize - 1) / @blockSize) -- Calcula cuántos bloques son necesarios.
                   (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) * @blockSize + 1 AS StartIndex
        FROM master.dbo.spt_values -- Usamos una tabla auxiliar para generar números.
)
SELECT                  
        convert(varchar(8000), SUBSTRING(@packageData, StartIndex, @blockSize)) AS packageData, @nTipoCallTotal as nTipoCallTotal
FROM BlockIndices
WHERE StartIndex <= LEN(@packageData); -- Asegúrate de no exceder la longitud.

end
else if @action = 15 begin 
; with 
tempUserIds as(
        select cast(Value as int) as userId from dbo.fn_RIASplitDelimited(@userIds,'','')
), WgUser AS(
select distinct
u.UserId,
A.IdCampEsp,A.Tipo from ccRIAWorkGroupUsers WG
inner join ccRIACampEspWG A on A.IDWG=WG.IDWG
inner join tempUserIds u on u.userId=WG.User_id
where WG.IDWG<>@WgId
)
, wGCamp AS(
select u.userId, A.IdCampEsp,A.Tipo from ccRIACampEspWG A
cross join tempUserIds u
where A.IDWG=@WgId
)
, campData as(
select wg.* from wGCamp wg
left join WgUser w on wg.userId=w.userId and wg.IdCampEsp=w.IdCampEsp and wg.Tipo=w.Tipo
where w.IdCampEsp is null
)
, dataDiferent as(
select 
convert(varchar, A.userId)+''-''+
convert(varchar, A.IdCampEsp)+''-''+convert(varchar,A.Tipo+1)  
+''-''+convert(varchar,COALESCE (campAgent.prioridad ,inboundAgent.prioridad,1)) 
+''-''+convert(varchar,COALESCE (campAgent.skill ,inboundAgent.skill,1))
as UserIdCampAndType
from campData A
left join ccCampsAgente campAgent on A.IdCampEsp = campAgent.cam_id and A.Tipo=1 and A.userId=campAgent.user_id
left join ccInboundAgentes inboundAgent on A.IdCampEsp = inboundAgent.inbound_id and A.Tipo=0 and A.userId=inboundAgent.user_id
)
select @packageData=UserIdCampAndType+'',''+@packageData from dataDiferent   

;WITH BlockIndices AS (
        SELECT TOP ((LEN(@packageData) + @blockSize - 1) / @blockSize) -- Calcula cuántos bloques son necesarios.
                   (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1) * @blockSize + 1 AS StartIndex
        FROM master.dbo.spt_values -- Usamos una tabla auxiliar para generar números.
)
SELECT                  
        convert(varchar(8000), SUBSTRING(@packageData, StartIndex, @blockSize)) AS packageData
FROM BlockIndices
WHERE StartIndex <= LEN(@packageData); -- Asegúrate de no exceder la longitud.


end'
        EXEC(@sql);


        set @process = 'Alter SP ccsp_RIAGetCampsNvosCB se quita la opcion ir al job para no tarde ya que no se utiliza ese dato'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAGetCampsNvosCB]
@cam_id integer = 0, @Tipo tinyint = 0, @user_id int = 0,
@regval int =0, @tcpa int=0
as
set nocount on

declare @TipoJobs as int,@isExecOutbound bit


set @isExecOutbound= case when @regval=0 then 0 else 1 end

-- Actualiza todas las camps
if @Tipo in (1,2) begin

declare @id AS INTEGER

CREATE TABLE #Tcamps(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int)
CREATE TABLE #Tcamps2(cam_id int primary key,procesando int,cam_tipojobs int,cam_descripcion varchar(40),cantidad int,status int,dateUpdate datetime)

create table #temccocallsoutsource (cam_id int,Pend  int)

create table #temWorkinTable(cam_id int,New int,Cb int,Pro int,Fin int)

if @cam_id = 0 begin
if @user_id > 0 begin
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
        from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
        where user_id = @user_id and tipo = 1
end
else begin
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
        from ccCamps cam (nolock) join ccSupervisorCam supcam with(nolock) on tipo=1 and cam.cam_id  =  supcam.cam_id
end

end
else begin
if @Tipo = 2
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select distinct cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam.cam_descripcion,0,0
        from ccCamps cam with(nolock)
        join ccSupervisorCam supcam with(nolock) on tipo=1 and cam.cam_id  =  supcam.cam_id
        where cam.cam_id = @cam_id
else
        if @user_id > 0 begin
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select distinct cam.cam_id ,isNull(cam_procesando,0),isNull(cam_tipojobs,0), cam.cam_descripcion,0,0
        from ccCamps cam with(nolock) join ccSupervisorCam supcam with(nolock) on cam.cam_id  =  supcam.cam_id
        where user_id = @user_id and tipo = 1
        end
        else begin
        insert into  #Tcamps (cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status)
        select cam.cam_id ,isNull(cam_procesando,0) as cam_procesando,isNull(cam_tipojobs,0) as cam_tipojobs, cam_descripcion,0,0
        from ccCamps cam (nolock) join ccSupervisorCam supcam with(nolock) on tipo = 1 and cam.cam_id  =  supcam.cam_id
        where user_id = @user_id and cam_activo=1
        end
end



insert into  #Tcamps2(cam_id,procesando,cam_tipojobs,cam_descripcion,cantidad,status,dateUpdate)
select cam_id,max(procesando),max(cam_tipojobs),max(cam_descripcion),0,0,max(dateUpdate) from(
select A.*,dateUpdate from #Tcamps A
left join ccCampsNvosCB B (nolock) on A.cam_id=B.id
where datediff(ss,B.dateUpdate,getdate())> case @tcpa when 1 then 1 else 5 end or B.dateUpdate is null)X
group by cam_id



if (select count(*) from #Tcamps2)>0 begin

insert into #temccocallsoutsource(cam_id,Pend)
SELECT ccos.cam_id, count(ccos.cam_id) as Pend
FROM ccocallsoutsource ccos with(index(IX_ccoCallsOutSource_17),nolock)
join #Tcamps2 tcam on ccos.cam_id = tcam.cam_id
WHERE cal_status in(0, 7)
GROUP BY ccos.cam_id

insert into #temWorkinTable(cam_id,New,Cb,Pro,Fin)
SELECT A.cam_id,
count(case cal_status when 0 then 1 else null end) as New,
count(case cal_status when 1 then 1 else null end) as Cb,
count(case cal_status when 2 then 1 else null end) as Pro,
count(case cal_status when 3 then 1 else null end) as Fin
FROM ccoworkingtable A with(index(IX_ccoWorkingTable),nolock)
join #Tcamps2 B on A.cam_id = B.cam_id
GROUP BY A.cam_id       


if (@regval = 0 and @cam_id >0 and @Tipo =2) or @tcpa = 1 begin
        update #Tcamps2 set status =1,cantidad=@regval  where cam_id = @cam_id
end       

declare @TotalNew table(
                cam_id int primary key,
                OverallTotalNew int 
        )
        
        

        

begin Tran updateccCampsNvosCB

        insert into @TotalNew
        select CampNvosCB.id,isnull(CampNvosCB.OverallTotalNew,CampNvosCB.new)  from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
        where CampNvosCB.id = tcamp.cam_id

        delete ccCampsNvosCB from ccCampsNvosCB CampNvosCB with(nolock), #Tcamps2 tcamp
        where CampNvosCB.id = tcamp.cam_id

        INSERT into ccCampsNvosCB 
        SELECT cams.cam_id, cams.cam_descripcion,
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
        LEFT JOIN #temccocallsoutsource cs on cams.cam_id = cs.cam_id
        LEFT JOIN @TotalNew  T on T.cam_id = cams.cam_id

COMMIT TRAN updateccCampsNvosCB
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
drop table #temccocallsoutsource
drop table #temWorkinTable

return(0)

end

set nocount off'
        EXEC(@sql)

        set @process = 'Alter Sp fn_RIASplitDelimited mejora performance'
        set @sql = 'ALTER FUNCTION [dbo].[fn_RIASplitDelimited]
(   
    @List NVARCHAR(max),
    @SplitOn NVARCHAR(3)
)
RETURNS @RtnValue TABLE (
    Id INT IDENTITY(1,1),
    Value NVARCHAR(255)
)
AS
BEGIN
    DECLARE @Pos INT = 1
    DECLARE @NextPos INT
    DECLARE @Fragment NVARCHAR(255)

    IF LEN(@List) = 0  -- Verificar si la lista está vacía y salir
        RETURN

    WHILE @Pos > 0
    BEGIN
        SET @NextPos = CHARINDEX(@SplitOn, @List, @Pos)
        
        IF @NextPos > 0
        BEGIN
            SET @Fragment = SUBSTRING(@List, @Pos, @NextPos - @Pos)
            IF LEN(@Fragment) > 0  -- Solo insertar si el fragmento tiene longitud
            BEGIN
                INSERT INTO @RtnValue (Value)
                VALUES (LTRIM(RTRIM(@Fragment)))
            END
            SET @Pos = @NextPos + 1
        END
        ELSE
        BEGIN
            SET @Fragment = SUBSTRING(@List, @Pos, LEN(@List) - @Pos + 1)
            IF LEN(@Fragment) > 0
            BEGIN
                INSERT INTO @RtnValue (Value)
                VALUES (LTRIM(RTRIM(@Fragment)))
            END
            SET @Pos = 0
        END
    END

    RETURN
END
'
        EXEC(@sql)
		        --------------------------- Begin Omar 125.20231211.0.20 ----------------------------------------------------------------------------------
	set @process = 'ALTER ccsp_GalateaAdminCampaigns TT13271-AdminMachine-Alto consumo de CPU se agrega action 16'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns]
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
@multi_type     varchar(max) = null,
@groupList as varchar (MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
IF @Option = 1 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type     
    IF @WorkgroupId IS NOT NULL BEGIN
        SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type FROM ccRIACampEspWG WHERE IDWG = @WorkgroupId
        ORDER BY IdCampEsp ASC;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. No existe una lista de campañas con el id de grupo de trabajo especificado'', 18, 1);
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
        FROM ccLogAgentesDiaViewLast A
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

    ;with stateDialog as(
    SELECT cast(value as int) as CurrentState FROM dbo.fn_RIASplitDelimited(@StateIds,'','')
)
    INSERT INTO @AgentStatus
    SELECT A.camId, A.userId, B.CurrentState,
    (CASE
        WHEN @chatType = 1 THEN
            CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) THEN 1 ELSE 0 END
        ELSE
            CASE WHEN B.CurrentState IN (SELECT CurrentState FROM stateDialog) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN 1 ELSE 0
        END
    END) AS isCampDialog, B.camType

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
                            ) THEN 1 ELSE NULL END) AS notReady,
                            COUNT(CASE WHEN A.isCampDialog = 1 THEN 1 ELSE NULL END) AS dialog, 
                            COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected
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
                                    CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
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
                                CAST(CASE WHEN (ccc.ivrScript = 0 AND ccc.callsBySurvey = 0) THEN isnull(CampType,0) ELSE 8 END AS INT) AS Channel,
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
ELSE IF @Option = 16 BEGIN -- Get Campaigns Ids List Per Workgroup and Campaign Type
    IF @groupList IS NOT NULL BEGIN
		IF OBJECT_ID(''tempdb..#WGDelete'') IS NOT NULL DROP TABLE #WGDelete;
        SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, '','')
        SELECT CAST(IdCampEsp AS INT) AS Id, tipo as Type, IDWG AS IdWg FROM ccRIACampEspWG WHERE IDWG in (select IDwg from #WGDelete)
        ORDER BY IdCampEsp ASC;
    END;
    ELSE BEGIN
        RAISERROR(''ERROR. No existe una lista de campañas con los ids de grupo de trabajo especificados'', 18, 1);
    END;
    RETURN 0;
END;

END;'
        EXEC(@sql)
		
		set @process = 'TT13271-AdminMachine-Alto consumo de CPU Alter SP ccsp_GalateaAdminGetAgentCounters se agrega action 16'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS      INT, --Corrección del Ticket TT13271-AdminMachine-Alto consumo de CPU
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
	 IF @type = 13 --Agents IDs by WGs
         BEGIN
			 declare @wgIdsList table (wgId int primary key)
             insert into @wgIdsList
			 select distinct value from dbo.fn_RIASplitDelimited(@workgroupIds,'','') 
             
             SELECT CAST(wg.User_id AS INT) Id, IDWG AS IdWg
             FROM ccRIAWorkGroupUsers wg
				  inner join @wgIdsList w on w.wgId=wg.IDWG
                  JOIN CCUsers u ON u.user_id = wg.user_id
                                    AND u.TipoUser_id = 1
             RETURN 0;
     END;
     SET NOCOUNT ON;'
        EXEC(@sql)
				--------------------------- End Omar 125.20231211.0.20 ----------------------------------------------------------------------------------
        set @process = ''
        set @sql = ''
        EXEC(@sql)

--------------------------- End Jesus 125.20231211.0.20 ----------------------------------------------------------------------------------

--------------------------- Begin Luis Miguel Zamora Nuñez 125.20231211.0.20 ----------------------------------------------------------------------------------
set @process = 'ALTER FUNCTION [dbo].[hashList] --Agregada validación de @calKey para Lista Negra TT13136'
set @sql = '
ALTER FUNCTION [dbo].[hashList] (@calKey varchar(255)) 
RETURNS bigint AS
BEGIN
declare @codigo varchar(max)
declare @hash bigint
if @calKey is null or @calKey='''' 
return @hash
set @codigo=''''
set @hash=0
declare @i int,@len int
select @i=1,@len=len(@calKey)
while @i<=@len begin
        select @codigo=@codigo+convert(varchar(max), ASCII(SUBSTRING(@calKey,@i,1)))
        
        if @i%5=0 begin
                set @hash=@hash+cast(@codigo as bigint)
                set @codigo=''''
        end     
        set @i=@i+1
end
if @codigo<>''''
set @hash=@hash+cast(@codigo as bigint)
return @hash % 99999999999973
END
'
EXEC(@sql)
--------------------------- End Luis Miguel Zamora Nuñez 125.20231211.0.20 ----------------------------------------------------------------------------------------------       

--------------------------- Begin Landus 125.20231211.0.20 ----------------------------------------------------------------------------------------------
SET @process = 'Landus Alter Sp ccsp_AplicaListaNegra se cambia IX_ccoCallsOutSource_4 por IX_ccoCallsOutSource_12'
SET @sql = 'ALTER PROCEDURE [dbo].[ccsp_AplicaListaNegra]
AS

declare @pais varchar(2)
declare @ld varchar(4)
declare @idagenda  int
declare @campsid int
declare @fechacal datetime
declare @Listid int

SET NOCOUNT ON

CREATE TABLE [dbo].[#mycamps] ( [campsid] [int]  NOT NULL primary key) ON [PRIMARY]

select top 1 @idagenda = idagenda, @campsid = campsid, @fechacal=fecharegs from ccagendalistanegra with(index(IX_ccagendalistanegra_4),nolock)
        where status= 1 and fechaaplicar < getdate() order by fechaaplicar asc

IF @idagenda is not  null
BEGIN

select top 1 @Listid = idtipolista from ccagenda_tipolistanegra with(nolock) 
        where idagenda = @idagenda order by idtipolista asc

update ccagendalistanegra with(rowlock) set inicio=getdate() where idagenda=@idagenda


insert #mycamps
select  campsid  from ccagendalistanegra where idagenda=@idagenda and  status= 1 and fechaaplicar < getdate() order by fechaaplicar asc

CREATE TABLE [dbo].[#mytemp] (
        [callout_id] [int] NOT NULL,
    [telefono] [varchar] (15) NOT NULL ,
        [cam_id] [smallint] NOT NULL ,
        [tipomov] [int] NOT NULL,
    [idtipolista] [int] NOT NULL
) ON [PRIMARY]

create table #tempListNegra(telefono varchar(32) NOT NULL,      idtipolista int NOT NULL)
CREATE NONCLUSTERED INDEX IX_tempListNegra_1 ON [dbo].#tempListNegra (telefono ASC)

--CREATE  UNIQUE  INDEX [IX_mytemp] ON [dbo].[#mytemp]([callout_id]) ON [PRIMARY] -- Nunca usa el callout id y siempre se trunca por telefono.

select @pais = valor from ccSettings with(nolock) where setting_id = 104
select @ld = valor from ccSettings with(nolock) where setting_id = 17

insert into #tempListNegra select dbo.Completa(telefono, @pais, @ld),idtipolista from ccListaNegra
-----------------------------------------------------------------------------  telefono1
IF @campsid=0
BEGIN
        
        IF @Listid = 0
        BEGIN
                

        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
        select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono =ln.telefono
        where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
        select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono = ln.telefono
        where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
        insert #mytemp
        ---Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
        select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono = ln.telefono
        INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
        where  cal_fechadial >  @fechacal
        
           END
           ELSE
           BEGIN
              insert #mytemp
        ---Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono1 en lista negra
        select callout_id,cal_telefono,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln on cs.cal_telefono = ln.telefono
        INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
        where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END



-- Borramos de WT todos los registros en los que el telefono1 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono= wt.cal_telefono and  rtrim(left(ltrim(            cs.cal_telefono2 + ''         ''
                                                         + cs.cal_telefono3 + ''         ''
                                                         + cs.cal_telefono4 + ''         ''
                                                         + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable with(rowlock) set cal_telefono =
rtrim(left(ltrim(            cs.cal_telefono2 + ''         ''
                                                         + cs.cal_telefono3 + ''         ''
                                                         + cs.cal_telefono4 + ''         ''
                                                         + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono1 de CS
update ccoCallsOutSource with(rowlock)
set cal_telefono = ''''
from ccoCallsOutSource cs 
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp


----------------------------------------------------------------------------------- -telefono 2
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
        select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono2 =ln.telefono
        where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
             insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
        select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono2 = ln.telefono
        where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
    
           END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
        select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono2 = ln.telefono
        INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
        where  cal_fechadial >  @fechacal
           END
           ELSE
           BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
        select callout_id,cal_telefono2,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln on cs.cal_telefono2 = ln.telefono
        INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
        where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
           END
END

-- Borramos de WT todos los registros en los que el telefono2 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono2= wt.cal_telefono and rtrim(left(ltrim(            cs.cal_telefono3 + ''         ''
                                                         + cs.cal_telefono4 + ''         ''
                                                         + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable with(rowlock) set cal_telefono =
rtrim(left(ltrim(            cs.cal_telefono3 + ''         ''
                                                         + cs.cal_telefono4 + ''         ''
                                                         + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono2= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono2 de CS
update ccoCallsOutSource with(rowlock) set cal_telefono2 = ''''
from ccoCallsOutSource cs inner join #mytemp t
on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 3
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono3 en lista negra
        select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono3 =ln.telefono
        where cal_fechadial > @fechacal
           END
           ELSE
           BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono3 en lista negra
        select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono3 = ln.telefono
        where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
           END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono3 en lista negra
        select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono3 = ln.telefono
        INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
        where  cal_fechadial >  @fechacal
           END
           ELSE
           BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono3 en lista negra
        select callout_id,cal_telefono3,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln on cs.cal_telefono3 = ln.telefono
        INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
        where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono3= wt.cal_telefono  and  rtrim(left(ltrim(            cs.cal_telefono4 + ''         ''
                                                         + cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable with(rowlock) set cal_telefono =
rtrim(left(ltrim(             cs.cal_telefono4 + ''         ''
                                                         + cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono3= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono3 de CS
update ccoCallsOutSource set cal_telefono3 = ''''
from ccoCallsOutSource cs 
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 4
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono4 en lista negra
        select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono4 =ln.telefono
        where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono4 en lista negra
        select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono4 = ln.telefono
        where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono4 en lista negra
        select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono4 = ln.telefono
        INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
        where  cal_fechadial >  @fechacal
            END
            ELSE
            BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono4 en lista negra
        select callout_id,cal_telefono4,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln on cs.cal_telefono4 = ln.telefono
        INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
        where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono4= wt.cal_telefono and  rtrim(left(ltrim(            cs.cal_telefono5 + ''         ''),13)) = ''''

-- Actualizamos WT al siguiente telefono disponbile (cuando no es el único telefono)
update ccoWOrkingTable set cal_telefono =
rtrim(left(ltrim(            cs.cal_telefono5 + ''         ''),13))
from ccoCallsOutSource cs
inner join ccoWorkingTable wt on cs.callout_id = wt.callout_id
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono4= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono4 de CS
update ccoCallsOutSource set cal_telefono4 = ''''
from ccoCallsOutSource cs 
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

truncate table #mytemp

----------------------------------------------------------------------------------- -telefono 5
IF @campsid=0
BEGIN
           IF @Listid = 0
           BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
        select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs  with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono5 =ln.telefono
        where cal_fechadial > @fechacal
            END
            ELSE
            BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono5 en lista negra
        select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono5 = ln.telefono
        where cal_fechadial > @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra with(index(IX_ccAgenda_TipolistaNegra),nolock) where idagenda=@idagenda)
            END
END
ELSE
BEGIN
           IF @Listid = 0
           BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono2 en lista negra
        select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln with(index(IX_tempListNegra_1),nolock) on cs.cal_telefono5 = ln.telefono
        INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
        where  cal_fechadial >  @fechacal
            END
            ELSE
            BEGIN
        insert #mytemp
        --Guardamos en una tabla temporal los callout_id de todos los registros que tengan telefono5 en lista negra
        select callout_id,cal_telefono5,cam_id,''3'',idtipolista from ccoCallsOutSource cs with(index(IX_ccoCallsOutSource_4),nolock)
        inner join #tempListNegra ln on cs.cal_telefono5 = ln.telefono
        INNER JOIN #mycamps ca ON cs.cam_id=ca.campsid
        where  cal_fechadial >  @fechacal and ln.idtipolista in (select idtipolista from ccagenda_tipolistanegra where idagenda=@idagenda)
    
            END
END

-- Borramos de WT todos los registros en los que el telefono4 sea el único telefono y este en la lista negra
delete ccoWOrkingTable with(rowlock)
from ccoWOrkingTable wt 
inner join ccoCallsOutSource cs on wt.callout_id = cs.callout_id
inner join #mytemp t on wt.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal and cs.cal_telefono5= wt.cal_telefono

---insertar el historial
insert cchistoriallistanegra (callout_id,telefono,cam_id,idtipomov,idtipolista)
select * from #mytemp

-- Eliminamos el telefono5 de CS
update ccoCallsOutSource set cal_telefono5 = ''''
from ccoCallsOutSource cs 
inner join #mytemp t on cs.callout_id = t.callout_id
where cs.cal_fechadial > @fechacal

update ccagendalistanegra set termino=getdate() where idagenda=@idagenda
update ccagendalistanegra set status=''0'' where idagenda=@idagenda
drop table #mytemp
drop table #tempListNegra
END


drop table #mycamps'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccLogAgentesDia_2] ON [ccLogAgentesDia];'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccLogAgentesDia_2'' AND object_id = OBJECT_ID(''ccLogAgentesDia''))
    DROP INDEX [IX_ccLogAgentesDia_2] ON [ccLogAgentesDia];'
EXEC(@sql);

SET @process = 'Landus  DROP INDEX [IX_ccoCallsOut_6] ON ccoCallsOut;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoCallsOut_6'' AND object_id = OBJECT_ID(''ccoCallsOut''))
    DROP INDEX [IX_ccoCallsOut_6] ON ccoCallsOut;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoCallsOut_5] ON ccoCallsOut;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoCallsOut_5'' AND object_id = OBJECT_ID(''ccoCallsOut''))
    DROP INDEX [IX_ccoCallsOut_5] ON ccoCallsOut;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoCallsOut_1] ON ccoCallsOut;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoCallsOut_1'' AND object_id = OBJECT_ID(''ccoCallsOut''))
    DROP INDEX [IX_ccoCallsOut_1] ON ccoCallsOut;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoCallsOutSource_15] ON ccoCallsOutSource;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoCallsOutSource_15'' AND object_id = OBJECT_ID(''ccoCallsOutSource''))
    DROP INDEX [IX_ccoCallsOutSource_15] ON ccoCallsOutSource;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoCallsOutSource_12] ON ccoCallsOutSource;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoCallsOutSource_12'' AND object_id = OBJECT_ID(''ccoCallsOutSource''))
    DROP INDEX [IX_ccoCallsOutSource_12] ON ccoCallsOutSource;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoCallsOutSource_2] ON ccoCallsOutSource;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoCallsOutSource_2'' AND object_id = OBJECT_ID(''ccoCallsOutSource''))
    DROP INDEX [IX_ccoCallsOutSource_2] ON ccoCallsOutSource;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoCallsOutSource] ON ccoCallsOutSource;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoCallsOutSource'' AND object_id = OBJECT_ID(''ccoCallsOutSource''))
    DROP INDEX [IX_ccoCallsOutSource] ON ccoCallsOutSource;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoWorkingTable_15] ON ccoWorkingTable;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoWorkingTable_15'' AND object_id = OBJECT_ID(''ccoWorkingTable''))
    DROP INDEX [IX_ccoWorkingTable_15] ON ccoWorkingTable;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoWorkingTable_13] ON ccoWorkingTable;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoWorkingTable_13'' AND object_id = OBJECT_ID(''ccoWorkingTable''))
    DROP INDEX [IX_ccoWorkingTable_13] ON ccoWorkingTable;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoWorkingTable_7] ON ccoWorkingTable;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoWorkingTable_7'' AND object_id = OBJECT_ID(''ccoWorkingTable''))
    DROP INDEX [IX_ccoWorkingTable_7] ON ccoWorkingTable;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoWorkingTable_6] ON ccoWorkingTable;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoWorkingTable_6'' AND object_id = OBJECT_ID(''ccoWorkingTable''))
    DROP INDEX [IX_ccoWorkingTable_6] ON ccoWorkingTable;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoWorkingTable_5] ON ccoWorkingTable;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoWorkingTable_5'' AND object_id = OBJECT_ID(''ccoWorkingTable''))
    DROP INDEX [IX_ccoWorkingTable_5] ON ccoWorkingTable;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoWorkingTable_2] ON ccoWorkingTable;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoWorkingTable_2'' AND object_id = OBJECT_ID(''ccoWorkingTable''))
    DROP INDEX [IX_ccoWorkingTable_2] ON ccoWorkingTable;'
EXEC(@sql);

SET @process = 'Landus DROP INDEX [IX_ccoLogDials_5] ON ccoLogDials;'
SET @sql = 'IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = ''IX_ccoLogDials_5'' AND object_id = OBJECT_ID(''ccoLogDials''))
    DROP INDEX [IX_ccoLogDials_5] ON ccoLogDials;'
EXEC(@sql);

--------------------------- End Landus 125.20231211.0.20 ----------------------------------------------------------------------------------------------

--------------------------- Begin Luis Miguel Zamora Nuñez 125.20231211.0.22 ----------------------------------------------------------------------------------------------

SET @process = 'K069003-CW-8946 - ccsp_GalateaUpdateUser - SP Edited, 
Se modifica para solucionar relacion entre InsertLogAdminGalatea y el Historial de Actividad'
SET @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateUser]
        @UserId int,
        @Login varchar(40),
        @Nombres varchar(45),
        @LastName varchar(45),
        @NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
        @Sexo bit,
        @canChangeStatus bit,
        @AdminId int,
        @AreaId int
        as

        Declare @ApellidoMaterno varchar(45)
        Declare @ApellidoPaterno varchar(45)
        Declare @userIdOnDb int
        Declare @LoginOnDb varchar(40)
        --Obtiene el idioma de Centerware
        Declare @lenguageXion varchar
        select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

        set @ApellidoPaterno = @LastName
        set @ApellidoMaterno = @NombreOpcionalExtra

        -- validaciones 
            if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
                begin
                select -5 as ResponseCode--,''el usuario no existe''
                return(0)
                end

          if exists(select Nombres from ccUsers where Nombres=@Nombres
          and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
            begin

                select @userIdOnDb =User_id from ccUsers where Nombres=@Nombres
              and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

                select @LoginOnDb =User_id from ccUsers where Nombres=@Nombres
              and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno

              if @UserId <> @userIdOnDb and @Login <> @LoginOnDb
                begin
                    select -2 as ResponseCode--,''Nombre completo en Uso''-- valida todos los campos de nombre para ver que no existan en la base de datos
                    return(0)
                end
            end

                --update and insert into activity log a record for each modified property

    EXEC InsertLogAdminGalatea @action=1, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId=@UserId, @userId= @userId

    Update ccUsers set 
    Nombres=@Nombres,
    ApellidoPaterno=@ApellidoPaterno,
    ApellidoMaterno=@ApellidoMaterno,
    Sexo=@Sexo,
    canChangeStatus=@canChangeStatus
    where User_id=@UserId

        CREATE TABLE #CCUsersTable 
    (
        columnInfo VARCHAR(255),
        dataInfo VARCHAR(255),
        identifierInfo VARCHAR(255)
    );

    EXEC InsertLogAdminGalatea @action=2, @tableName = ''ccUsers'', @columnNameId = ''User_id'', @valueId = @UserId, @userId = @userId, @tableTemp=''#CCUsersTable'';

        DELETE FROM #CCUsersTable WHERE identifierInfo IS NULL OR identifierInfo = '''';

    INSERT INTO ccGalateaActivityLog (Area, ActivityDate, Login, OperationId, ModuleId, Identifier, Value, Target)
        SELECT 
                (SELECT [AreaName] FROM ccRIACat_Areas WHERE IDArea = @AreaId),
                GETDATE(), 
                (SELECT [Login] FROM ccUsers WHERE User_id = @AdminId), 
                CASE WHEN (SELECT [TipoUser_id] FROM ccUsers WHERE User_id = @UserId) = 1 THEN 25 ELSE 32 END, 
                3, 
                ISNULL(CUT.identifierInfo, ''''),  -- Asegura que sea '''' si es NULL
                CASE 
                        WHEN CUT.identifierInfo IS NOT NULL THEN
                                CASE 
                                        WHEN CUT.identifierInfo = ''T&EDIT_GENDER_USER'' THEN CONCAT(CUT.identifierInfo, CASE WHEN CUT.dataInfo = 1 THEN ''_M'' ELSE ''_F'' END)
                                        ELSE CUT.dataInfo 
                                END
                        ELSE '''' 
                END, 
                (SELECT [Login] FROM ccUsers WHERE User_id = @UserId)
        FROM #CCUsersTable AS CUT
        WHERE (CUT.identifierInfo IS NOT NULL AND CUT.identifierInfo <> ''''); -- Filtra las filas sin identifierInfo


    EXEC InsertLogAdminGalatea @action=3, @tableName=''ccUsers'', @columnNameId=''User_id'', @valueId = @UserId, @userId = @userId

        IF OBJECT_ID(N''tempdb..#CCUsersTable'') IS NOT NULL DROP TABLE #CCUsersTable

        select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
'
EXEC(@sql);

SET @process = 'K069003-CW-8946 - InsertLogAdminGalatea - SP Edited, 
Se modifica para solucionar problema del Historial de Actividad al Editar Usuario'
SET @sql = '
ALTER procedure [dbo].[InsertLogAdminGalatea]
    @action int 
    ,@tableName VARCHAR(255)
    ,@columnNameId VARCHAR(255)
    ,@valueId VARCHAR(255)
    ,@userId int
    ,@tableTemp varchar(255)=null
AS
SET NOCOUNT ON;

declare @sql nvarchar(max), @sql2 nvarchar(max)
DECLARE @tableNameTmp VARCHAR(255) = ''##''+@tableName+''_''+convert(varchar(10),@userId)

if @action =1 begin --Antes del cambio
    set @sql=''IF OBJECT_ID(N''''tempdb..''+@tableNameTmp+'''''') IS NOT NULL DROP TABLE ''+@tableNameTmp+'' 
    SELECT * INTO ''+@tableNameTmp+'' FROM ''+@tableName+'' WHERE ''+@columnNameId+'' = ''+@valueId
    -- Ejecutar el SQL para crear la tabla temporal
    exec(@sql)
end
else if @action=2 begin
    DECLARE @columns NVARCHAR(MAX) = '''';
    DECLARE @conditions NVARCHAR(MAX) = '''';
    DECLARE @caseStatements NVARCHAR(MAX) = '''';
    DECLARE @batchSize INT = 10; -- Tamaño del bloque de columnas
    DECLARE @counter INT = 0;
    declare @emtpy varchar(2)=''''

    -- Declarar una variable de tipo tabla para almacenar los IDs de cada bloque
    DECLARE @BatchColumns TABLE (
            name NVARCHAR(128),
            batch_id INT
    );

    -- Insertar en @BatchColumns las columnas de la tabla, dividiéndolas en bloques
    INSERT INTO @BatchColumns (name, batch_id)
    SELECT 
            name,
            (ROW_NUMBER() OVER (ORDER BY column_id) - 1) / @batchSize AS batch_id
    FROM 
            sys.columns
    WHERE 
            object_id = OBJECT_ID(@tableName)
            AND name <> @columnNameId  -- Excluir la columna clave primaria
            AND name <> ''rowguid'';  -- Excluir la columna GUID si existe

    -- Insertar batch_ids únicos en la variable de tipo tabla @BatchIds
    DECLARE @BatchIds TABLE (
            batch_id INT PRIMARY KEY
    );

    INSERT INTO @BatchIds
    SELECT DISTINCT batch_id FROM @BatchColumns;

    DECLARE @batch_id INT = 0;

    -- Bucle para procesar cada bloque de columnas
    WHILE EXISTS (SELECT 1 FROM @BatchIds WHERE batch_id = @batch_id)
    BEGIN
        -- Construir las expresiones CASE y las condiciones WHERE para este bloque
        SET @caseStatements = '''';
        SET @conditions = '''';

        -- Construir el CASE y el WHERE para cada columna en el bloque actual
        SELECT 
                @caseStatements = @caseStatements + 
                ''SELECT '''''' + name + '''''' AS columnInfo, CONVERT(VARCHAR(300), A.'' + QUOTENAME(name) + '') AS dataInfo '' +
                ''FROM '' + @tableName + '' AS A '' +
                ''FULL OUTER JOIN '' + @tableNameTmp + '' AS B ON A.'' + QUOTENAME(@columnNameId) + '' = B.'' + QUOTENAME(@columnNameId) + '' '' +
                ''WHERE A.'' + QUOTENAME(name) + '' <> B.'' + QUOTENAME(name) + '' UNION ALL ''
        FROM 
                @BatchColumns
        WHERE 
                batch_id = @batch_id;                   

        -- Construir las condiciones WHERE para el bloque actual
        SELECT @conditions = @conditions + 
        CASE WHEN @conditions = '''' THEN '''' ELSE '' OR '' END +
        ''A.'' + QUOTENAME(name) + '' <> B.'' + QUOTENAME(name)
        FROM 
                @BatchColumns
        WHERE 
                batch_id = @batch_id;

        -- Remover el último UNION ALL sobrante
        SET @caseStatements = LEFT(@caseStatements, LEN(@caseStatements) - LEN('' UNION ALL ''));
        
        -- Construir y ejecutar la consulta para este bloque
        IF @caseStatements <> ''''
        BEGIN
            SET @sql = ''
            INSERT INTO ''+@tableTemp+'' (columnInfo, dataInfo)
            '' + @caseStatements + ''                       
            '';
            -- Ejecutar la consulta dinámica
            EXEC sp_executesql @sql;
        END     

        -- Avanzar al siguiente bloque
        SET @batch_id = @batch_id + 1;
    END

    -- Consultar el resultado final de cambios
    set @sql= 
    ''SELECT distinct A.columnInfo, A.dataInfo, ISNULL(B.Identifiers, @emtpy) as identifierInfo 
    FROM ''+@tableTemp+'' A 
    LEFT JOIN relationTableColumnIdentifiers B 
        ON A.columnInfo = B.colunName 
        AND B.tableName = @tableName'';

    -- Si la tabla temporal existe, insertar los resultados allí
    if @tableTemp is not null and @tableTemp <> '''' begin
        set @sql = ''INSERT INTO '' + @tableTemp + '' '' + @sql
    end

    -- Ejecutar la consulta de inserción
    EXEC sp_executesql @sql, N''@tableName VARCHAR(255), @emtpy VARCHAR(2)'', @tableName = @tableName, @emtpy = @emtpy;

end
else if @action =3 begin
    set @sql=''IF OBJECT_ID(N''''tempdb..''+@tableNameTmp+'''''') IS NOT NULL DROP TABLE ''+@tableNameTmp
    -- Ejecutar la eliminación de la tabla temporal
    exec(@sql)
end
'
EXEC(@sql);
--------------------------- End Luis Miguel Zamora Nuñez 125.20231211.0.22 ----------------------------------------------------------------------------------------------
 
--------------------------- Begin LRSV KR154000 ----------------------------------------------------------------------------------

SET @process = 'KR154000 se crea permiso 10043'
SET @sql = '
IF NOT EXISTS (select 1 from ccPermissions where Permissions_Id = 10043)
BEGIN
	insert into ccPermissions values (10043, ''Habilitar/deshabilitar marcación progresiva'', ''RolesPermissionProgressiveDialing'', 0, 0, 0, ''N/A'', 1)
END'
EXEC(@sql);

SET @process = 'KR154000 se crea permiso 10042'
SET @sql = '
IF NOT EXISTS (select 1 from ccPermissions where Permissions_Id = 10042)
BEGIN
	insert into ccPermissions values (10042, ''Marcar en orden ascendente/descendente'', ''RolesPermissionDialingOrder'', 0, 0, 0, ''N/A'', 1)
END'
EXEC(@sql);

SET @process = 'KR154000 se asigna permiso 10043 a root'
SET @sql = '
IF NOT EXISTS (select 1 from ccRoles_Permissions where Rol_Id = 1 AND Permissions_Id = 10043)
BEGIN
	insert into ccRoles_Permissions values (1, 10043)
END'
EXEC(@sql);

SET @process = 'KR154000 se asigna permiso 10042 a root'
SET @sql = '
IF NOT EXISTS (select 1 from ccRoles_Permissions where Rol_Id = 1 AND Permissions_Id = 10042)
BEGIN
	insert into ccRoles_Permissions values (1, 10042)
END'
EXEC(@sql);

--------------------------- END LRSV KR154000 ----------------------------------------------------------------------------------


--------------------------- Begin Ricardo Nuñez Alanis 126.20231211.0.22 ----------------------------------------------------------------------------------
SET @process = 'Create table ccMenuRol'
SET @sql = 'IF OBJECT_ID(''ccMenuRol'', ''U'') IS NOT NULL
BEGIN
    PRINT ''La tabla ccMenuRol ya existe.''
END
ELSE
BEGIN
    CREATE TABLE ccMenuRol (
        Rol_id INT,
        menu_id SMALLINT,
        "type" TINYINT,
        CONSTRAINT fk_rol FOREIGN KEY (Rol_id) REFERENCES ccRoles(Rol_id),
        CONSTRAINT fk_menu FOREIGN KEY (menu_id, "type") REFERENCES ccMenus(menu_id, "type")
    );
    PRINT ''La tabla ccMenuRol ha sido creada exitosamente.''
END;'
EXEC(@sql);

SET @process = 'Insert default data to ccMenuRol manually'
SET @sql = 'IF Exists(select * from ccRoles where Rol_id=1) and  NOT EXISTS (SELECT 1 FROM ccMenuRol where Rol_id=1) begin
	INSERT INTO ccMenuRol (menu_id, type, Rol_id)
	SELECT m.menu_id, m.type, 1 AS Rol_id  -- Root
    FROM ccMenus m
    WHERE m.parent IN (
        2000, 3000, 3140, 4000, 3130, 10000, 11000, 12000, 
        6000, 8000, 8050, 8060, 8080, 7000, 13000, 14000
    )
    AND m.type = 3
    AND m.menu_id NOT IN (2130, 12015, 12017, 8083, 7230, 13030, 1010) -- Excluir estos menu_id
end


IF Exists(select * from ccRoles where rol_id=6) and NOT EXISTS (SELECT 1 FROM ccMenuRol where Rol_id=6) begin
	INSERT INTO ccMenuRol (menu_id, type, Rol_id)
	SELECT menu_id, type, 6 AS Rol_id  -- Supervisor
        FROM ccMenus m
    WHERE m.parent IN (
        2000, 3000, 4000, 3130, 10000, 11000, 12000, 
        6000
    )
    AND m.type = 3
    AND m.menu_id NOT IN (2130, 12015, 12017, 8083, 7230, 13030, 1010) -- Excluir estos menu_id
end

IF Exists(select * from ccRoles where rol_id=8) and NOT EXISTS (SELECT 1 FROM ccMenuRol where Rol_id=8) begin
	INSERT INTO ccMenuRol (menu_id, type, Rol_id)
	SELECT menu_id, type, 8 AS Rol_id  -- Analista de Calidad
    FROM ccMenus m
    WHERE m.parent IN (
        2000, 3000, 4000, 8050
    )
    AND m.type = 3
    AND m.menu_id NOT IN (2130, 12015, 12017, 8083, 7230, 13030, 1010) -- Excluir estos menu_id
end

IF Exists(select * from ccRoles where rol_id=9) and NOT EXISTS (SELECT 1 FROM ccMenuRol where Rol_id=9) begin
	INSERT INTO ccMenuRol (menu_id, type, Rol_id)
	SELECT menu_id, type, 9 AS Rol_id  -- Monitor
    FROM ccMenus m
    WHERE m.parent IN (
        2000, 3000, 4000, 8050
    )
    AND m.type = 3
    AND m.menu_id NOT IN (2130, 12015, 12017, 8083, 7230, 13030, 1010) -- Excluir estos menu_id
end
'
EXEC(@sql);

set @process = 'Delete ccsp_GalateaMenuReporte'
    set @sql='
        if exists (select * from sys.procedures where name = N''ccsp_GalateaMenuReporte'')
    begin
        DROP PROCEDURE ccsp_GalateaMenuReporte;
    end'
    EXEC(@sql)

SET @process = 'Creation of ccsp_GalateaMenuReporte'
SET @sql = '

CREATE PROCEDURE [dbo].[ccsp_GalateaMenuReporte]
    @action SMALLINT,
    @Rol_id VARCHAR(MAX) = NULL,
	@id_User VARCHAR(MAX) = NULL,	
	@menu_id VARCHAR(MAX) = NULL,
	@ids_list VARCHAR(MAX) = NULL,
	@IsAdminsIds BIT = NULL,
	@RowsAffected INT = @@ROWCOUNT
AS

BEGIN
    IF @action = 1
	--Busca el id rol y regresa todos los menu id que tenga relacionados
    BEGIN
		IF @IsAdminsIds = 0
		BEGIN
			SELECT distinct CAST(menu_id as int) as MenuID --0 as RolID, 0 as type
			FROM ccMenuRol
			WHERE (Rol_id IN(Select Value from dbo.fn_RIASplitDelimited(@Rol_id, '','')))
		END
		ELSE
		BEGIN
			SELECT DISTINCT CAST(id_Menu AS INT) as MenuID
			FROM ccMenuUser 
			WHERE (id_User = @id_User) and type = 3 and id_Menu not in (1000, 1010);
		END
	END;

	IF @action = 2
	--Manda la información faltante para que el Front sepa todos los menus
	BEGIN
		SET NOCOUNT ON;
		SELECT CAST(menu_id as int) as MenuID, menu_descrip as MenuDesc, CAST(parent as int) as Parent
		FROM ccMenus 
	    WHERE parent IN (
            2000, 3000, 3140, 4000, 3130, 10000, 11000, 12000, 
            6000, 8000, 8050, 8060, 8080, 7000, 13000, 14000
        )
        AND type = 3
        AND menu_id NOT IN (2130, 12015, 12017, 8083, 7230, 13030)
	END;

	IF @action = 3
	--Guarda información ya sea en la tabla ccMenuUser o ccMenuRol
	BEGIN
		IF @IsAdminsIds  = 0
		BEGIN
			SET NOCOUNT ON;
			INSERT INTO ccMenuRol(menu_id, Rol_id, type)
			SELECT DISTINCT t2.Value AS menu_id, t1.Value AS Rol_id, 3 as type
			FROM (SELECT Value FROM dbo.fn_RIASplitDelimited(@ids_list, '','')) t1
			CROSS JOIN 
			(SELECT Value FROM dbo.fn_RIASplitDelimited(@menu_id, '','')) t2
			WHERE NOT EXISTS 
			(SELECT 1 FROM ccMenuRol
			WHERE ccMenuRol.Rol_id = t1.Value
			AND ccMenuRol.menu_id = t2.Value);

			-- Determinar el resultado directamente con @@ROWCOUNT
			SELECT CASE 
				WHEN @@ROWCOUNT > 0 THEN 1 -- Se insertaron filas
				WHEN (LEN(@ids_list) - LEN(REPLACE(@ids_list, '','', ''''))) = 0 THEN -1 -- Solo un id en la lista, pero sin cambios
				ELSE -2 -- Múltiples ids, pero sin cambios
			END AS Result;
		END
		ELSE
		BEGIN
			SET NOCOUNT ON;
			INSERT INTO ccMenuUser(id_Menu, id_User, type)
			SELECT DISTINCT t2.Value AS id_Menu, t1.Value AS id_User, 3 as type
			FROM (SELECT Value FROM dbo.fn_RIASplitDelimited(@ids_list, '','')) t1
			CROSS JOIN 
			(SELECT Value FROM dbo.fn_RIASplitDelimited(@menu_id, '','')) t2
			WHERE NOT EXISTS 
			(SELECT 1 FROM ccMenuUser
			WHERE ccMenuUser.id_User = t1.Value
			AND ccMenuUser.id_Menu = t2.Value);

			-- Determinar el resultado directamente con @@ROWCOUNT
			SELECT CASE 
				WHEN @@ROWCOUNT > 0 THEN 1 -- Se insertaron filas
				WHEN (LEN(@ids_list) - LEN(REPLACE(@ids_list, '','', ''''))) = 0 THEN -1 -- Solo un id en la lista, pero sin cambios
				ELSE -2 -- Múltiples ids, pero sin cambios
			END AS Result;
		END
	END;


IF @action = 4
	--Elimina información ya sea en la tabla ccMenuUser o ccMenuRol
	BEGIN
		IF @IsAdminsIds = 0
		BEGIN
			SET NOCOUNT ON;
			DELETE FROM ccMenuRol
			WHERE EXISTS (
				SELECT 1
				FROM dbo.fn_RIASplitDelimited(@ids_list, '','') t1
				CROSS JOIN dbo.fn_RIASplitDelimited(@menu_id, '','') t2
				WHERE ccMenuRol.Rol_id = t1.Value
				AND ccMenuRol.menu_id = t2.Value
			);

			-- Determinar el resultado directamente con @@ROWCOUNT
			SELECT CASE 
				WHEN @@ROWCOUNT > 0 THEN 1 -- Se eliminaron filas
				WHEN (LEN(@ids_list) - LEN(REPLACE(@ids_list, '','', ''''))) = 0 THEN -1 -- Solo un id en la lista, pero sin cambios
				ELSE -2 -- Múltiples ids, pero sin cambios
			END AS Result;
		END
		ELSE
		BEGIN
			SET NOCOUNT ON;
			DELETE FROM ccMenuUser
			WHERE EXISTS (
				SELECT 1
				FROM dbo.fn_RIASplitDelimited(@ids_list, '','') t1
				CROSS JOIN dbo.fn_RIASplitDelimited(@menu_id, '','') t2
				WHERE ccMenuUser.id_User = t1.Value
				AND ccMenuUser.id_Menu = t2.Value
			);

			-- Determinar el resultado directamente con @@ROWCOUNT
			SELECT CASE 
				WHEN @@ROWCOUNT > 0 THEN 1 -- Se eliminaron filas
				WHEN (LEN(@ids_list) - LEN(REPLACE(@ids_list, '','', ''''))) = 0 THEN -1 -- Solo un id en la lista, pero sin cambios
				ELSE -2 -- Múltiples ids, pero sin cambios
			END AS Result;
		END
	END;
	IF @action = 5
	--Busca el id rol y regresa todos los menu id que tenga relacionados
    BEGIN
		IF @IsAdminsIds = 0
		BEGIN
			SELECT distinct CAST(menu_id as int) as MenuID --0 as RolID, 0 as type
			FROM ccMenuRol
			WHERE (Rol_id IN(Select Value from dbo.fn_RIASplitDelimited(@ids_list, '','')))
		END
		ELSE
		BEGIN
			SELECT DISTINCT CAST(id_Menu AS INT) as MenuID
			FROM ccMenuUser 
			WHERE (id_User = @ids_list) and type = 3 and id_Menu not in (1000, 1010);
		END
	END;
END;
'
EXEC(@sql);
--------------------------- End Ricardo Nuñez Alanis 126.20231211.0.22 ----------------------------------------------------------------------------------

--------------------------- BEGIN IC 125.20231211.0.22 ----------------------------------------------------------------------------------

SET @process = 'TT12493-Outbound-No se respetan tiempo de remarcacion.'
SET @sql = '
IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_OUTUpdateDialJobCommon'')
BEGIN
    DROP PROCEDURE ccsp_OUTUpdateDialJobCommon;
END
'
EXEC(@sql);

SET @process = 'TT12493-Outbound-No se respetan tiempo de remarcacion.'
SET @sql = '
CREATE PROCEDURE ccsp_OUTUpdateDialJobCommon
@action int,
@callout_id     INT,
@cam_id INT=0,
@prioridadLlamada CHAR(8) OUTPUT,
@Telefono VARCHAR(15)='''' OUTPUT

AS
SET NOCOUNT ON
if @action=1 begin
	DECLARE @ExistePriorityOrder TINYINT
	SELECT 
        @prioridadLlamada = priorityCall,
        @ExistePriorityOrder = CASE WHEN callout_id IS NOT NULL THEN 1 ELSE 0 END
    FROM ccoCallPriorityOrder WITH (NOLOCK)
    WHERE callout_id = @callout_id

    IF @ExistePriorityOrder IS NULL
    BEGIN
        SELECT @prioridadLlamada = Prioridad
        FROM ccCampsPrioridadTel WITH (NOLOCK)
        WHERE cam_id = @cam_id

        INSERT INTO ccoCallPriorityOrder 
        VALUES (@callout_id, @prioridadLlamada)
    END
end
if @action=2 begin
	-- Cambiar la prioridad
    SET @prioridadLlamada = dbo.ChangePriorityCall(@prioridadLlamada)

    -- Actualizar la prioridad
    UPDATE ccoCallPriorityOrder WITH (rowlock)
    SET priorityCall = @prioridadLlamada
    WHERE callout_id = @callout_id

    -- Seleccionar el pr�ximo tel�fono
    DECLARE @sSQL NVARCHAR(MAX)
    SET @sSQL = ''SELECT @outA = RTRIM(LEFT(LTRIM(cal_telefono'' 
        + CASE SUBSTRING(@prioridadLlamada, 1, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 1, 1) END
        + ''+''''         ''''+cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 2, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 2, 1) END
        + ''+''''         ''''+cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 3, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 3, 1) END
        + ''+''''         ''''+cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 4, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 4, 1) END
        + ''+''''         ''''+cal_telefono'' + CASE SUBSTRING(@prioridadLlamada, 5, 1) WHEN 1 THEN '''' ELSE SUBSTRING(@prioridadLlamada, 5, 1) END
        + ''+''''         ''''),13)) FROM ccoCallsOutSource WITH (NOLOCK) WHERE callout_id=''
        + CAST(@callout_id AS VARCHAR(15))

    EXEC sp_executesql @sSQL, N''@outA VARCHAR(15) OUTPUT'', @outA = @Telefono OUTPUT
end
SET NOCOUNT OFF
'
EXEC(@sql);

SET @process = 'TT12493-Outbound-No se respetan tiempo de remarcacion.'
SET @sql = '
IF EXISTS (SELECT * FROM sys.procedures WHERE name = N''ccsp_OUTUpdateDialJob'')
BEGIN
    DROP PROCEDURE ccsp_OUTUpdateDialJob;
END
'
EXEC(@sql);

SET @process = 'TT12493-Outbound-No se respetan tiempo de remarcacion.'
SET @sql = '
CREATE PROCEDURE [dbo].[ccsp_OUTUpdateDialJob]
@callout_id     INT,
@CallResultDial TINYINT,
@isTCPA         BIT     = 0
AS
BEGIN

	SET NOCOUNT ON

	/*1:Contesto | 2:Ocupada | 3:No contestada | 4:Fax/Modem | 5:No Dial Tone | 7:Colgado durante transferencia
	++8:short call | ++9:Otro | 8:Other | 10:NoService | 11:Machine	*/

	DECLARE @nOcupado TINYINT, @nNoContesta TINYINT, @nFax TINYINT, @nContestadora TINYINT
	DECLARE @nShortCall TINYINT, @nOtro TINYINT, @cam_NoInt_ocupado TINYINT, @cam_NoInt_graba TINYINT
	DECLARE @cam_ocupado SMALLINT, @cam_inter_ocupado SMALLINT, @cam_nocontesto SMALLINT
	DECLARE @cam_graba SMALLINT, @cam_inter_graba SMALLINT, @cam_inter_nocontesto SMALLINT
	DECLARE @cam_fax SMALLINT, @cam_inter_fax SMALLINT
	DECLARE @DateNextDial DATETIME, @DateNewDial DATETIME, @cam_id SMALLINT
	DECLARE @ExisteWT TINYINT, @cam_NoInt_fax TINYINT, @cam_NoInt_nocontesto TINYINT, @cal_status TINYINT
	DECLARE @sSQL NVARCHAR(MAX), @Telefono VARCHAR(15), @prioridadLlamada CHAR(8)
	DECLARE @ExistePriorityOrder TINYINT
			 
	SELECT @cam_id = cam_id,
		@nOcupado = ISNULL(nOcupado, 0),
		@nNoContesta = ISNULL(nNoContesta, 0),
		@nFax = ISNULL(nFax, 0),
		@nContestadora = ISNULL(nContestadora, 0),
		@nShortCall = ISNULL(nShortCall, 0),
		@nOtro = ISNULL(nOtro, 0),
		@DateNextDial = cal_fechaDial
	FROM ccoWorkingTable with(nolock)
	WHERE callout_id = @callout_id

	SELECT @ExisteWT = CASE WHEN @cam_id IS NOT NULL THEN 1 ELSE 0 END
	SELECT @cal_status = CASE WHEN @isTCPA = 1 THEN 0 ELSE 1 END--si esta en modo TCPA no gene|rar callbacks

	IF @CallResultDial = 20 BEGIN-- CONTACTADO
		EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
		RETURN(0)
	END
	IF @CallResultDial = 1 BEGIN-- CONTESTO
		IF @isTCPA = 1 BEGIN
			UPDATE ccoWorkingTable with(rowlock) SET cal_status = @cal_status WHERE callout_id = @callout_id
		END
		ELSE 
		BEGIN
			IF (SELECT campType FROM ccCamps WHERE cam_id = @cam_id) = 6
				RETURN(0)
			IF (SELECT abandonCallback FROM ccCamps WHERE cam_id = @cam_id) = 1
				BEGIN
					EXEC ccsp_OUTCancelDialJOB @callout_id,1,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
			END
			ELSE BEGIN
				EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
			END
		END
		RETURN(0)
	END
	IF @CallResultDial IN(2, 12) BEGIN -- OCUPADO
		SELECT @cam_ocupado = cam_ocupado,
		@cam_inter_ocupado = cam_inter_ocupado,
		@cam_NoInt_ocupado = cam_NoInt_ocupado,
		@nOcupado = @nOcupado + 1
		FROM ccCamps
		WHERE cam_id = @cam_id

		IF @cam_ocupado = 1 
		BEGIN -- Opcion Ocupado HABILITADA
			IF @nOcupado > @cam_NoInt_ocupado OR @nShortCall > 4 
			BEGIN
				EXEC ccsp_OUTCancelDialJOB @callout_id,0,@nOcupado,@nNoContesta,@nFax,@nContestadora,@nShortCall,@nOtro,@ExisteWT
				RETURN(0)
			END
	
			exec ccsp_OUTUpdateDialJobCommon @action=1,@callout_id=@callout_id,@cam_id= @cam_id, @prioridadLlamada =@prioridadLlamada OUTPUT

			-- Change priority and obtain the next telephone
			UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1	ELSE nNoContesta END
			WHERE callout_id = @callout_id

			exec ccsp_OUTUpdateDialJobCommon @action=2,@callout_id=@callout_id, @prioridadLlamada =@prioridadLlamada,@Telefono =@Telefono OUTPUT

			SELECT @DateNewDial = DATEADD(mi, @cam_inter_ocupado, GETDATE())

			-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
			IF @DateNewDial > @DateNextDial 
			BEGIN	-- Nueva fecha de Call BACk
				UPDATE ccoWorkingTable with(rowlock) SET nOcupado = @nOcupado, cal_fechaDial = @DateNewDial, cal_status = @cal_status
				WHERE callout_id = @callout_id			
				RETURN(0)
			END

			-- Mantiene la fecha de Call BACK
			UPDATE ccoWorkingTable with(rowlock) SET nOcupado = @nOcupado, cal_status = @cal_status, cal_telefono = @Telefono
			WHERE callout_id = @callout_id
			RETURN(0)
		END

		-- ELSE: Opcion Ocupado DESHABILITADA
		EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
		RETURN(0)
	END
	IF @CallResultDial IN(3, 5, 8) BEGIN-- NO CONTESTA
		--select NO Contesta
		SELECT @cam_nocontesto = cam_nocontesto,
		@cam_inter_nocontesto = cam_inter_nocontesto,
		@cam_NoInt_nocontesto = cam_NoInt_nocontesto,
		@nNoContesta = @nNoContesta + 1
		FROM ccCamps
		WHERE cam_id = @cam_id

		IF @cam_nocontesto = 1 
		BEGIN-- Opcion NoContesta HABILITADA
			IF @nNoContesta > @cam_NoInt_nocontesto OR @nShortCall > 4 
			BEGIN --select No Contesta Habilitada
				EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
				RETURN(0)
			END

			exec ccsp_OUTUpdateDialJobCommon @action=1,@callout_id=@callout_id,@cam_id= @cam_id, @prioridadLlamada =@prioridadLlamada OUTPUT
		
			-- Change priority and obtain the next telephone
			UPDATE ccoCallsOutSource with(rowlock) SET nNoContesta = CASE WHEN nNoContesta < 255 THEN ISNULL(nNoContesta, 0) + 1
			ELSE nNoContesta END
			WHERE callout_id = @callout_id

			exec ccsp_OUTUpdateDialJobCommon @action=2,@callout_id=@callout_id, @prioridadLlamada =@prioridadLlamada,@Telefono =@Telefono OUTPUT

			SELECT @DateNewDial = DATEADD(mi, @cam_inter_nocontesto, GETDATE())

			UPDATE ccoWorkingTable with(rowlock) SET nNoContesta = @nNoContesta, cal_status = @cal_status, cal_telefono = @Telefono,
			cal_fechaDial = CASE WHEN @DateNewDial > @DateNextDial THEN @DateNewDial ELSE cal_fechaDial	END
			WHERE callout_id = @callout_id
			RETURN(0)
		END

		-- Opcion NoContesta DESHABILITADA
		EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
		RETURN(0)
	END
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
			IF @nFax > @cam_NoInt_fax OR @nShortCall > 4 
			BEGIN
				EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
				RETURN(0)
			END

			exec ccsp_OUTUpdateDialJobCommon @action=1,@callout_id=@callout_id,@cam_id= @cam_id, @prioridadLlamada =@prioridadLlamada OUTPUT

			-- Change priority and obtain the next telephone
			UPDATE ccoCallsOutSource with(rowlock) SET nFax = CASE WHEN nFax < 255 THEN ISNULL(nFax, 0) + 1 ELSE nFax END
			WHERE callout_id = @callout_id

			exec ccsp_OUTUpdateDialJobCommon @action=2,@callout_id=@callout_id, @prioridadLlamada =@prioridadLlamada,@Telefono =@Telefono OUTPUT

			SELECT @DateNewDial = DATEADD(mi, @cam_inter_fax, GETDATE())

			-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
			UPDATE ccoWorkingTable with(rowlock) SET nFax = @nFax, cal_status = @cal_status, cal_telefono = @Telefono,
			cal_fechaDial = CASE WHEN @DateNewDial > @DateNextDial	THEN @DateNewDial ELSE cal_fechaDial END
			WHERE callout_id = @callout_id
			RETURN(0)
		END

		-- Opcion Fax/Modem DESHABILITADA
		EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
		RETURN(0)
	END
	IF @CallResultDial = 11 
	BEGIN-- Maquina Contestadora
		SELECT @cam_graba = cam_graba,
		@cam_inter_graba = cam_inter_graba,
		@cam_NoInt_graba = cam_NoInt_graba,
		@nContestadora = @nContestadora + 1
		FROM ccCamps
		WHERE cam_id = @cam_id

		IF @cam_graba = 1 BEGIN-- Opcion Maquina Contestadora HABILITADA
			IF @nContestadora > @cam_NoInt_graba OR @nShortCall > 4 
			BEGIN
				EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
				RETURN(0)
			END

			exec ccsp_OUTUpdateDialJobCommon @action=1,@callout_id=@callout_id,@cam_id= @cam_id, @prioridadLlamada =@prioridadLlamada OUTPUT

			-- Change priority and obtain the next telephone
			UPDATE ccoCallsOutSource with(rowlock) SET nContestadora = CASE WHEN nContestadora < 255 THEN ISNULL(nContestadora, 0) + 1 ELSE nContestadora END
			WHERE callout_id = @callout_id

			exec ccsp_OUTUpdateDialJobCommon @action=2,@callout_id=@callout_id, @prioridadLlamada =@prioridadLlamada,@Telefono =@Telefono OUTPUT

			SELECT @DateNewDial = DATEADD(mi, @cam_inter_graba, GETDATE())

			-- Programacion de CALLBACK, si esta en TCPA se pasa a nuevos
			UPDATE ccoWorkingTable with(rowlock) SET nContestadora = @nContestadora, cal_status = @cal_status, cal_telefono = @Telefono,
			cal_fechaDial = CASE WHEN @DateNewDial > @DateNextDial THEN @DateNewDial ELSE cal_fechaDial END
			WHERE callout_id = @callout_id
			RETURN(0)
		END

		-- Opcion Maquina Contestadora DESHABILITADA
		EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
		RETURN(0)
	END
	IF @CallResultDial IN(10, 90) 
	BEGIN--No Dial Tone, otros, NoService
		EXEC ccsp_OUTCancelDialJOB @callout_id, 0, @nOcupado, @nNoContesta, @nFax, @nContestadora, @nShortCall, @nOtro, @ExisteWT
		RETURN(0)
	END
	IF @CallResultDial > 13 AND @CallResultDial <> 51   BEGIN--Dial Result not register
		EXEC ccsp_OUTUpdateDialJob @callout_id = @callout_id, @CallResultDial = 8, @isTCPA = @isTCPA
	END

	RETURN(0)
	SET NOCOUNT OFF
END
'
EXEC(@sql);
--------------------------- END IC 125.20231211.0.22 ------------------------------------------------------------------------------------

set @process = 'DROP FUNCTION Limpia2'
set @sql = 'IF EXISTS (SELECT 1 FROM sys.objects 
               WHERE Name = ''Limpia2'' 
                 AND Type IN ( N''FN'', N''IF'', N''TF'', N''FS'', N''FT'' ))
    BEGIN
        DROP FUNCTION dbo.Limpia2
    END'
EXEC(@sql)


SET @process = 'CREATE FUNCTION [dbo].[Limpia2]'
SET @sql = 'CREATE FUNCTION [dbo].[Limpia2](@Phone varchar(32))
RETURNS varchar(32) AS  
BEGIN
DECLARE @limpiada NVARCHAR(MAX) = ''''

DECLARE @index INT = 1
DECLARE @longitud INT = LEN(@Phone)

WHILE @index <= @longitud
BEGIN
    DECLARE @caracter NVARCHAR(1) = SUBSTRING(@Phone, @index, 1)
    
    IF PATINDEX(''%[0-9]%'', @caracter) > 0 OR (@caracter = ''+'' AND @index = 1) -- Mantener solo números y el símbolo de más al inicio
    BEGIN
        SET @limpiada = @limpiada + @caracter
    END

    SET @index = @index + 1
END

declare @codeCountry varchar(10), @codeCountryLen int
set @codeCountry= (select valor from ccSettings2 where setting_id = 272)
set @codeCountry=REPLACE(@codeCountry,''+'','''')
set @codeCountryLen=len(@codeCountry)




IF LEFT(@limpiada,1)<>''+'' begin
        IF LEFT(@limpiada, len(@codeCountry)) = @codeCountry  begin
                return ''N_''+ substring(@limpiada,@codeCountryLen,len(@limpiada)-@codeCountryLen)
        end
        return ''N_''+@limpiada
end
set @limpiada=replace(@limpiada,''+'','''')

IF LEFT(@limpiada, len(@codeCountry)) = @codeCountry  begin
        return ''N_''+ substring(@limpiada,@codeCountryLen,len(@limpiada)-@codeCountryLen)
end
return ''I_''+@limpiada



end'
EXEC(@sql);

SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccCamps_IA'
        SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccCamps_IA'' and parent_id = OBJECT_ID(N''ccCamps''))
begin      
        drop trigger [tg_ccCamps_IA]    
end';
        EXEC(@sql);

        SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccoCallsOutSource_IA'
        SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccoCallsOutSource_IA'' and parent_id = OBJECT_ID(N''ccoCallsOutSource''))
begin 
        drop trigger [tg_ccoCallsOutSource_IA]    
end';
        EXEC(@sql);

        SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccoCallsOut_IA'
        SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccoCallsOut_IA'' and parent_id = OBJECT_ID(N''ccoCallsOut''))
begin      
        drop trigger [tg_ccoCallsOut_IA]    
end';
        EXEC(@sql);

        SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccoLogDials_IA'
        SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccoLogDials_IA'' and parent_id = OBJECT_ID(N''ccoLogDials''))
begin 
        drop trigger [tg_ccoLogDials_IA]    
end';
        EXEC(@sql);

        SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccUsersTmp_IA'
        SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccUsersTmp_IA'' and parent_id = OBJECT_ID(N''ccUsers''))
begin 
        drop trigger [tg_ccUsersTmp_IA]    
end
';
        EXEC(@sql);

        SET @process = 'K038009-Servicio IA Service replicación de Drop TRIGGER tg_ccRIALoading_IA'
        SET @sql = 'if exists (select * from sys.triggers where name = N''tg_ccRIALoading_IA'' and parent_id = OBJECT_ID(N''ccRIALoading''))
begin 
        drop trigger [tg_ccRIALoading_IA]    
end
';
        EXEC(@sql);

SET @process = ' '
SET @sql = ''
EXEC(@sql);


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

