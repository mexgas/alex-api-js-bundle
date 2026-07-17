/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/05/06
Description:

Database: CCenterRia
Required version: 122.19

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
SET @versionfix = 21
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 19
BEGIN
	BEGIN TRAN

	BEGIN TRY

		set @process = 'CW-4303-Crear nuevo setting globar con id 222 para hunaku'
		set @sql = 'if not exists(select * from ccSettings where setting_id=222) begin
		insert into ccSettings(setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate)
 values(222,''1'',''Lugar donde hunaku guarda grabaciones'',1,''X'',''Lugar donde los hunakus guardan las grabaciones. Este setting afecta a todos los hunakus. 0=GUARDA EN LOCAL. 1=GUARDA EN REMOTO'',
 ''Place where hunaku keeps recordings'',0,''/^[0-1]$/'')
 end'
		EXEC(@sql)

		set @process = 'CW-4303 drop sp para cambiar a grabacion local en hunaku'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccspHunaku_record_locally'')
	    begin
	        DROP PROCEDURE ccspHunaku_record_locally;
	    end'
		EXEC(@sql)

		set @process = 'CW-4303 agregar sp para cambiar a grabacion local en hunaku'
		set @sql = 'create procedure ccspHunaku_record_locally
as
update ccSettings set valor=0 where setting_id=222'
		EXEC(@sql)


		set @process = 'CW-4303 drop sp para cambiar a grabacion remota en hunaku'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccspHunaku_record_remotely'')
	    begin
	        DROP PROCEDURE ccspHunaku_record_remotely;
	    end'
		EXEC(@sql)

		set @process = 'CW-4303 agregar sp para cambiar a grabacion remota en hunaku'
		set @sql = 'create procedure ccspHunaku_record_remotely
as
update ccSettings set valor=1 where setting_id=222'
		EXEC(@sql)


		set @process = 'CW-4269 proximos a marcar getCampsNvsCB'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GetCampsNvosCB]
@cam_id integer = 0,
@Tipo tinyint=0,
@user_id int=0
AS
set nocount on
declare @RecicleSIC tinyint,@sFin int,@sql varchar(8000)
select @RecicleSIC=IsNull(valor,0)FROM ccSettings WHERE setting_id=60
select @sFin=case when @RecicleSIC=0 and USER_NAME()<>''dbo'' then 0 else 1 end

select @sql=''declare @ultimo as datetime
if ''+cast(isnull(@Tipo,0) as varchar(10))+''=0
	begin
		if ''+cast(isnull(@cam_id,0) as varchar(10))+''=0 begin
			select Camps.cam_id as ID,cam_descripcion as ''''CampaÃ±a'''',
				IsNull(Jobs.New,0)as New,IsNull(Jobs.CB,0)as CB,IsNull(Jobs.Pro,0)as Pro,
				IsNull(Pends.pend,0)as Pen,''+case when @sFin=1 then ''IsNull(Jobs.Fin,0)as Fin,'' else '''' end+''
				case cam_procesando when 1 then ''''Pro''''	when 0 then '''''''' end as St,
				case cam_TipoJobs when 2 then ''''New'''' when 1 then ''''CB'''' when 0 then ''''Amb'''' end as Job			
			from ccCamps Camps(nolock)Left Join 
			(select cam_id,
				count(case cal_status when 0 then 1 else null end)as New,
				count(case cal_status when 1 then 1 else null end)as CB,
				count(case cal_status when 2 then 1 else null end)as Pro''
				+case when @sFin=1 then '',count(case cal_status when 3 then 1 else null end)as Fin'' else '''' end+''
			from ccoWorkingTable(nolock) group by cam_id)Jobs
			on Camps.cam_id=Jobs.cam_id Left Join
			(select cam_id,count(*)as Pend
					from ccocallsoutsource(nolock)where cal_status=0
					and cal_fechadial>dateadd(dd,-5,getdate())
					group by cam_id)Pends
			On Camps.cam_id=Pends.cam_id
			Order by cam_procesando desc,cam_descripcion
		end 
		else
		begin
			select wt.cam_id,cam_descripcion,
			count(case cal_status when 0 then 1 else null end)as Nuevos,
			count(case cal_status when 1 then 1 else null end)as CB
			from ccoworkingtable wt(nolock)inner join cccamps c(nolock)
			on wt.cam_id=c.cam_id and wt.cam_id=''+cast(isnull(@cam_id,0) as varchar(10))+'' group by wt.cam_id,cam_descripcion
			order by cam_descripcion
		end
	end

	if ''+cast(isnull(@Tipo,0) as varchar(10))+''=1
	begin
		if(''+cast(isnull(@cam_id,0) as varchar(10))+''>0)
			begin
			select Camps.cam_id as ID,cam_descripcion as ''''CampaÃ±a'''',
				IsNull(Jobs.New,0)as New,IsNull(Jobs.CB,0)as CB,IsNull(Jobs.Pro,0)as Pro,
				IsNull(Pends.pend,0)as Pen,''+case when @sFin=1 then ''IsNull(Jobs.Fin,0)as Fin,'' else '''' end+''
				case cam_procesando when 1 then ''''Pro'''' when 0 then '''''''' end as St,
				case cam_TipoJobs when 2 then ''''New'''' when 1 then ''''CB''''	when 0 then ''''Amb''''	end as Job
			from ccCamps Camps(nolock)Left Join 
			(select cam_id,
				count(case cal_status when 0 then 1 else null end)as New,
				count(case cal_status when 1 then 1 else null end)as CB,
				count(case cal_status when 2 then 1 else null end)as Pro''
				+case when @sFin=1 then '',count(case cal_status when 3 then 1 else null end)as Fin'' else '''' end+''
			from ccoWorkingTable(nolock) group by cam_id)Jobs
			on Camps.cam_id=Jobs.cam_id Left Join
			(select cam_id,count(*)as Pend
					from ccocallsoutsource(nolock)where cal_status=0
					and cal_fechadial>dateadd(dd,-5,getdate())
					group by cam_id)Pends
			On Camps.cam_id=Pends.cam_id
			Where Camps.cam_id=''+cast(isnull(@cam_id,0) as varchar(10))+''
			Order by cam_procesando desc,cam_descripcion
		end
	end

	if ''+cast(isnull(@Tipo,0) as varchar(10))+''=2
	begin
		if(''+cast(isnull(@user_id,0) as varchar(10))+''>0)
			begin
			select distinct Camps.cam_id as ID,cam_descripcion as ''''CampaÃ±a'''',
				IsNull(Jobs.New,0)as New,IsNull(Jobs.CB,0)as CB,IsNull(Jobs.Pro,0)as Pro,
				isnull(Pends.Pend,0)Pen,''+case when @sFin=1 then ''IsNull(Jobs.Fin,0)as Fin,'' else '''' end+''
				case cam_procesando when 1 then ''''Pro'''' when 0 then '''''''' end as St,			
				case cam_TipoJobs when 2 then ''''New'''' when 1 then ''''CB'''' when 0 then ''''Amb'''' end as Job			
			from ccCamps Camps(nolock)Left Join 
			ccCampsNvosCB jobs(nolock)on Camps.cam_id=Jobs.id
			inner join ccSupervisorCam U(nolock)on Camps.cam_id=U.cam_id left Join
			(select cam_id,count(*)as Pend
					from ccocallsoutsource(nolock)where cal_status=0
					and cal_fechadial>dateadd(dd,-5,getdate())
					group by cam_id)Pends
			On Camps.cam_id=Pends.cam_id
			Where U.user_id=''+cast(isnull(@user_id,0) as varchar(10))+'' and tipo=1
			Order by Camps.cam_id desc,cam_descripcion
		end
	end

	if ''+cast(isnull(@Tipo,0) as varchar(10))+''=3
	begin

		select @ultimo=isnull(cast(valor as datetime),dateadd(hh,-1,getdate())) from ccSettings where setting_id=21
		if datediff(mi,@ultimo,getdate())>=1 begin
			update ccsettings set valor=convert(varchar(25),getdate(),121)where setting_id=21
			delete ccCampsNvosCB
			insert ccCampsNvosCB(ID,CampaÃ±a,new,cb,pen,pro,''+case when @sFin=1 then ''fin,'' else '''' end+''st,job)
			select Camps.cam_id as ID,cam_descripcion as ''''CampaÃ±a'''',
				IsNull(Jobs.New,0)as New,IsNull(Jobs.CB,0)as CB,0 as pen,IsNull(Jobs.Pro,0)as Pro,''+case when @sFin=1 then ''IsNull(Jobs.Fin,0)as Fin,'' else '''' end+''cam_procesando as st,cam_TipoJobs as Job
				from ccCamps Camps(nolock)Left Join 
				(	select cam_id,
					count(case cal_status when 0 then 1 else null end)as New,
					count(case cal_status when 1 then 1 else null end)as CB,
					count(case cal_status when 2 then 1 else null end)as Pro''
					+case when @sFin=1 then '',count(case cal_status when 3 then 1 else null end)as Fin'' else '''' end+''
					from ccoWorkingTable(nolock)
					group by cam_id
				)Jobs on Camps.cam_id=Jobs.cam_id
		end
		select ID,CampaÃ±a,St as cam_procesando,Job as cam_tipoJobs,New,CB,Pro''+case when @sFin=1 then '',Fin'' else '''' end+''
		from ccCampsNvosCB (nolock)
		Order by ID
	end''

exec(@sql)
set nocount off
'
		EXEC(@sql)

		set @process = 'CW-4269 proximos a marcar ccsp_OUTGetNewJobs'
		set @sql = 'ALTER procedure [dbo].[ccsp_OUTGetNewJobs]
		@CAMPID int,
		@test int=0,
		@nAgentsLogin int=1,
		@iZonas int = null
		as
		--set nocount on
		declare @total int
		declare @topCount smallint, @bIsDaylight bit, @revHorario bit
		declare @country_id int, @TipoJobs int
		--declare @iZonas int --Zonas que se van a incluir en la marcacion 2 ^ zona
		declare @sql varchar(MAX), @Order_Asc_Desc char(4)
		declare @camSurvey int
		select @camSurvey = 0
		DECLARE @iZonasTable TABLE (value int)

		select @camSurvey = cam_id from cccamps  where cam_id = @CAMPID  and isnull(callsBySurvey,0) > 0  and isnull(ivrScript,0) > 0

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

			  INSERT INTO @iZonasTable exec ccsp_OUTcheckTimeZone @cam_id=@campid
			  select @iZonas=value from @iZonasTable
		--Checamos si la campaÃ±a tiene horarios configurados
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
		calkey varchar(max)
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
		set @isVerano = ''W.izonahoraria'' + case @bIsDaylight when 1 then ''_verano'' else '''' end

		if @TipoJobs in(0,1)--** INCLUIR LOS CALLBACKS
		begin

					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
					+@isVerano+'',''
					+@isVerano+''2,''
					+@isVerano+''3,''
					+@isVerano+''4,''
					+@isVerano+''5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					WHERE W.cal_status=1 -- CallBacks
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
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
					order by prioridad_cb desc, W.cal_fechaDial '' -- + @Order_Asc_Desc -- Solo se aplica el order en registros Nuevos (cal_status=0)
					
					--select @sql
		end -- TOMA EN CUENTA LOS CALLBACKS

		if @TipoJobs in(0,2)--** INCLUIR LAS NUEVAS
		begin
					select @sql=@sql+nchar(13)+ ''SET ROWCOUNT '' + cast( @topCount/2 as varchar )

					select @sql=@sql+nchar(13)+ ''INSERT #NEW_JOBS
					SELECT W.callout_id, W.cam_id, W.cal_telefono, W.cal_status, W.cal_fechaDial, W.user_id,''
					+@isVerano+'',''
					+@isVerano+''2,''
					+@isVerano+''3,''
					+@isVerano+''4,''
					+@isVerano+''5,
					W.list_id, isNull(R.sequence,0) as sequence,
					cs.cal_key+''''~''''+rtrim(dato1)+''''~''''+rtrim(dato2)+''''~''''+rtrim(dato3)+''''~''''+rtrim(dato4)+''''~''''+rtrim(dato5) calkey
					FROM ccoWorkingTable W left join ccRIARegistryLists R with (index (IX_ccRIARegistryLists)) on W.list_id = R.list_id
					left join ccocallsoutsource cs (nolock) on cs.callout_id=W.callout_id
					WHERE W.cal_status=0 -- Nuevas
					and W.cal_fechaDial<dateadd(mi, 5, getdate())-- Los vencidos hasta Ahora
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
					order by R.sequence, W.cal_fechaDial ''+ @Order_Asc_Desc +'', callout_id''

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
		begin
			  select @sql=@sql+nchar(13)+ ''SELECT callout_id, cam_id, cal_telefono, cal_status, cal_fechaDial,
		user_id, tz, tz2, tz3, tz4, tz5,
		case when tz is null then '''''''' else cal_telefono end as tel,
		case when tz2 is null then '''''''' else cal_telefono end as tel2,
		case when tz3 is null then '''''''' else cal_telefono end as tel3,
		case when tz4 is null then '''''''' else cal_telefono end as tel4,
		case when tz5 is null then '''''''' else cal_telefono end as tel5,
		NULL as dialOrder, list_id, sequence, calkey,
		0 tel_type, 0 tel2_type, 0 tel3_type, 0 tel4_type, 0 tel5_type
		FROM #NEW_JOBS where len(cal_telefono)>0

		---Recarga info de las cubetas de usuario en la tabla ccCampsNvosCB
		declare @regval int
		SELECT @regval=count(*) FROM #NEW_JOBS where len(cal_telefono)>0
		exec ccsp_GetCampsNvosCB @cam_id=1,@Tipo=0,@user_id =0
		''
		end

		set @sql=@sql+nchar(13)+ ''DROP table #NEW_JOBS''
		print (@sql)
		exec(@sql)

		return(0)'
		EXEC(@sql)

		set @process = 'Twitter drop sp ccspADMaddConversationTweet'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccspADMaddConversationTweet'')
		    begin
		        DROP PROCEDURE ccspADMaddConversationTweet;
		    end'
		EXEC(@sql)

		set @process = 'ModificaciÃ³n a sp ccspADMaddConversationTweet para regresar nombres correctos'
		set @sql = 'CREATE PROCEDURE [dbo].[ccspADMaddConversationTweet]
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
				select cast(0 as bigint) as Id
			else begin
				declare @closeConversation tinyint
				declare @tRsponse datetime
				select @tRsponse = isnull(max(tSend),getdate()) from messageOutTwitter where conversationTwitterId = @conversationId
				select @closeConversation = closeConversationTime from contactMeanIn where inboundId=@inboundId
				 if datediff(dd,getdate(),@tRsponse ) > @closeConversation
					select  cast(0 as bigint)  as Id
				else
					select @conversationId as Id
			end
		    return 0
		end
		else if @action = 2 begin --Nueva conversacion y mensaje entrada y salida
		    --agregar tabla de messagetwit fecha de descarga
			if @replayId is null or @replayId=''''
				set @replayId= ''0''
		    if NOT EXISTS (select * from messageInTwitter where twitId = @twitId) 
			BEGIN
				insert into conversationTwitter (inboundId,ClientId,isFinished,screenNameClient,screenNameInbound,meanContactTypeId,replayId)
				values(@inboundId,@clientId,@isFinished,@screenNameClient,@screenNameInbound,@meanContactTypeId,@replayId)
				set  @conversationId  = SCOPE_IDENTITY()
			
					insert into messageInTwitter(conversationTwitterId,tipoTwitId,twitId,[date]) values(@conversationId,@tipoTwitId,@twitId,@date)
					set @messageId=SCOPE_IDENTITY()
			
				insert into messageOutTwitter(conversationTwitterId,messageStatusId,tipoTwitId,userId,[date],ninteration,messageInTwitterIdIni,messageInTwitterIdEnd)
				values(@conversationId,1,@tipoTwitId,0,@date,1,@messageId,@messageId)

			END
		    select 0 as LastUserId,@conversationId as Id, @messageId as MessageId
		    return 0
		end
		else if @action = 3 begin --Nuevo mensaje Entrada
			---Revisa que no se contesto el twitt
			select @messageOutTwitterId=max(A.messageOutTwitterId),@ninteration= count(B.messageInTwitterId)
			from messageOutTwitter A inner join messageInTwitter B on A.conversationTwitterId=B.conversationTwitterId
			where A.conversationTwitterId=@conversationId and A.messageStatusId not in (5,6,7,8,9,10,11)
			
			SELECT TOP 1  @messageId=messageInTwitterId from messageInTwitter where twitId = @twitId

			IF @messageId is null 
			BEGIN
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
			end
			select @userId = userId  from messageOutTwitter with(nolock) where messageOutTwitterId=@messageOutTwitterId
			select @userId as LastUserId,@conversationId as Id, @messageId as MessageId
			return 0
		end
		else if @action = 4 begin --Obtiene el maximo messageOutTwitterId por conversacion
		    select @messageOutTwitterId=max(messageOutTwitterId) from [messageOutTwitter] with(nolock) where conversationTwitterId=@conversationId
			select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
			select @messageOutTwitterId as messageOutTwitterId,@replayId as replayId
			return 0
		end
		else if @action = 5 begin --Ultimo mensaje en por ACD
		    select cast(isnull(max(twitId),0)as bigint) as Id, max(date) as Date from messageInTwitter as A
			inner join conversationTwitter as B on A.conversationTwitterId=B.conversationTwitterId
			where B.inboundId=@inboundId
			return 0
		end
		else if @action = 6 begin --Obtiene conversaciÃ³n dependiendo del replayId
			select @conversationId=conversationTwitterId  from messageOutTwitter where twitId=@replayId
			if @conversationId is not null begin
				select @replayId=replayId from conversationTwitter where conversationTwitterId=@conversationId
			end
			else begin
				select 0 as conversationId,''0'' as replayId
			end
			select @conversationId as conversationId,@replayId as replayId
			return 0
		end

		set nocount off'
		EXEC(@sql)

		set @process = 'Twitter drop COLUMN maxDownloadTweetsNumber'
		set @sql = 'if not exists (select * from sys.columns where name = N''maxDownloadTweetsNumber'' and Object_ID = Object_ID(N''ccInbound''))
	    begin
	    	ALTER TABLE ccInbound ADD maxDownloadTweetsNumber INT DEFAULT 20;
	    end'
		EXEC(@sql)
		
		set @process = 'Twitter modify COLUMN maxDownloadTweetsNumber'
		set @sql = 'if exists (select * from sys.columns where name = N''maxDownloadTweetsNumber'' and Object_ID = Object_ID(N''ccInbound''))
	    begin
			update ccInbound set maxDownloadTweetsNumber = 20  where addDataCallBackReminder = 0
	    end'
		EXEC(@sql)

		set @process = 'Twitter drop sp ccspTwitterConfiguration'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccspTwitterConfiguration'')
		    begin
		        DROP PROCEDURE ccspTwitterConfiguration;
		    end'
		EXEC(@sql)

		set @process = 'Twitter add sp ccspTwitterConfiguration'
		set @sql = 'CREATE PROCEDURE [dbo].[ccspTwitterConfiguration]     @Option AS SMALLINT,
												   @InboundId as INT
		AS
		BEGIN
			set nocount on
			IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type 
			BEGIN
				IF @InboundId IS NOT NULL
					BEGIN
						SELECT maxDownloadTweetsNumber AS maxDownloadTweetsNumber FROM ccInbound WHERE Inbound_id = @InboundId 
					END
				ELSE
					BEGIN
						raiserror(''ERROR. No existe una campa?a de salida con el id especificado'', 18, 1)
					END	
			END
		END'
		EXEC(@sql)

	set @process = 'CW-4245 -- Actualiza SP ccsp_RIAConfCamp'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfCamp]
@User_id smallint
AS
set nocount on
	declare @tableExistsRec table (camId int primary key,existRec bit)

	insert into @tableExistsRec
	select B.cam_id,case when count(A.cal_id) >0 then 1 else 0 end as existRec 
	from dbo.fGet_CampAcd_Area (@User_id, 1) B
	left join ccoCallsOut A on A.cam_id=B.cam_id
	group by B.cam_id

	select a1.cam_id, cam_Descripcion
	, cam_tNotas, cast(cam_ocupado as int) as cam_ocupado, cam_noInt_ocupado, cam_inter_ocupado, cast(cam_nocontesto as int) as cam_nocontesto
	, cam_noInt_nocontesto, cam_inter_nocontesto, cast(cam_fax as int) as cam_fax, cam_noInt_fax, cam_inter_fax
	, cast(cam_modomanual as int) as cam_modomanual, ANI, cam_ShowCalifWnd, cam_StartTimerOnHangUp, editableCallKey, cam_tNoContesta, iTipoDial
	, detectAnswerMachine, detectVoiceMail, compliance, cam_inter_graba, cam_noint_graba, cast(progDial as tinyint)progDial
	, cast(excCallBack as tinyint)excCallBack, dialOrder, dialPrefix, dialPrefixMan, dialPrefixXfe, listenManualCall
	, stopRecording, cast(abandonCallback as tinyint)abandonCallback, a3.frame, a1.t_autoCB, a1.id_anilist, a1.tDialonWrapUp, dbo.fn_viewMode(@User_id, 10) viewMode, 
	cam_maxqueue as queSize,
	DNCScrub, callerIdDesc, timeZoneRule, callsBySurvey, ivrScript, surveyPctg, isnull(a1.call_record,1) as call_record
		,cast (startStopRecording as tinyint)startStopRecording, leaveRecMessage, manualCallOnChat
	,callBackSurveyAgent,callBackSurveyClient,case when surveycamid is null or surveycamid = 0 then 0 else 1 end isRelationSurvey,isnull(a1.funcEspDtmf,0)
	,isnull(sipHdrFormat, '''') sipHdrFormat
	,cam_inter_cancelled
	,prefijo,	enbleprefix = case when existRec = 0 then 1 else 0 end
	from ccCamps a1 inner join ccRIACampsGraph a2 on (a1.cam_id=a2.cam_id)
	inner join ccRIAGraphics a3 on (a2.graphic_id=a3.graphic_id)
	inner join @tableExistsRec a4 on a1.cam_id=a4.camId
	--where a1.cam_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 1))
	order by cam_descripcion
	return(0)
	set nocount off'
		EXEC(@sql)
        
        set @process = 'CW-4245 -- Actualiza SP ccsp_RIAConfEspec'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAConfEspec]
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
declare @tableExistsRec table (camId int primary key,existRec bit)

insert into @tableExistsRec
select I.cam_id,case when count(O.cal_id) >0 then 1 else 0 end as existRec 
from dbo.fGet_CampAcd_Area (@User_id, 4) I
left join ccCallsIn O on I.cam_id=O.inbound_id
group by I.cam_id

select  A.inbound_id, A.Descripcion, A.Status, A.tNotas,
A.tMaxWaitCall, A.nMaxQue,tel_maxwait, A.tel_MaxQueue, A.tel_outservice, A.tel_noct, A.ShowCalifWnd,
A.StartTimerOnHangUp, A.editableCallKey, A.queuePosition, A.tMaxQueueCallBack, A.stopRecording, A.dialPrefixOverflow,
A.OpriorityT, A.callerIdDesc, A.chat mode, A.inactiveChatTime, A.maxChats, isnull(A.chatDomain,'''') chatDomain, A.chatQueueOverflow, A.chatTimeOverflow,
isnull(A.startStopRecording,0) startStopRecording
,isnull(B.name,'''') as nameMail,isnull(B.conexionInfo,'''') as conexionInfo,isnull(B.connUser,'''') as connUser,
isnull(B.ConnPass,'''') as connPass,isnull(B.numMessages,3) as numMessages,isnull(B.timeAlertMessage,10)  as timeAlertMessage,
isnull(B.IsActive,0) as Active, isnull(B.answerTimeOut,0) as answerTimeOut,
case when A.cam_id > 0   and C.callsBySurvey>0 then A.callBackSurveyAgent else 0 end callBackSurveyAgent,
case when A.cam_id > 0  and C.callsBySurvey>0 then A.callBackSurveyClient else 0 end callBackSurveyClient,
case when A.cam_id > 0  and C.callsBySurvey>0 then 1 else 0 end isRelationSurvey,
isnull(A.agts_notavailable,'''') as agts_notavailable,
isnull(nameTwitter,'''') nameTwitter,isnull(userTwitter,'''') userTwitter,isnull(numMessagesTwitter,3) numMessagesTwitter,
isnull(timeAlertMessageTwitter,10) timeAlertMessageTwitter,isnull(ActiveTwitter,0) ActiveTwitter,isnull(answerTimeOutTwitter,10) answerTimeOutTwitter,
--usuarioID|token|tokenSecret|time|daysTwitterRecord
isnull(conexionInfoTwitter,''usuarioID|token|tokenSecret|1|0'') conexionInfoTwitter
,isnull(closeConversationTimeTwitter,3) closeConversationTimeTwitter,isnull(closeConversationTime,3) closeConversationTimeEmail
,isnull(A.editableDtmf,0) as editableDtmf
,isnull(gra.graphic_id,1) as frame
,isnull(A.prefijo,'''') as prefijo
,isnull(A.addDataCallBackReminder,0) as addDataCallBackReminder
,isnull(Conv.hasMessage,0) as hasMessageMail
, enbleprefix = case when R.existRec = 0 then 1 else 0 end
from ccInbound A
left join ccRIAInboundGraph gra on gra.Inbound_id=A.Inbound_id
left join ContactMeanIn B on A.inbound_id=B.inboundId and B.meanContactTypeId=1
left join ccCamps C on C.cam_id=A.cam_id
left join(

select GP.inboundId,case when count(*)>0 then 1 else 0 end hasMessage 
 from (
  select A.inboundId, A.conversationId, max(B.messageId) messageId  from conversation A 
  inner join message B  on A.conversationId = B.conversationId  where A.isFinished=0
    GROUP BY A.inboundId,A.conversationId
  ) GP
inner join message M on GP.messageId=M.messageId and messageStatusId not in(6,10,11,12,13)
group by inboundId

)  Conv on Conv.inboundId=A.inbound_id

left join (
select D.inboundId,
D.name as nameTwitter,D.connUser as userTwitter,D.numMessages as numMessagesTwitter,
D.timeAlertMessage as timeAlertMessageTwitter,
D.IsActive as ActiveTwitter, D.answerTimeOut as answerTimeOutTwitter,D.conexionInfo as conexionInfoTwitter,
closeConversationTime as  closeConversationTimeTwitter
from ContactMeanIn D
where D.meanContactTypeId=2) D on A.Inbound_id=D.inboundId
inner join @tableExistsRec R on A.inbound_id=R.camId
--where A.inbound_id in (select cam_id from dbo.fGet_CampAcd_Area (@User_id, 4))
return(0)
set nocount off'
		EXEC(@sql)


	set @process = 'CW-4297 -- actualiza SP ccsp_DLRSaveDialResult'
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_DLRSaveDialResult] 
				@callout_id INT, @cam_id SMALLINT, @tipoResDial_id TINYINT, @Telefono VARCHAR(30), @Puerto SMALLINT,
				@tDialing TINYINT= 0, @tBusy SMALLINT= 0, @call_id INT= 0, @answerbit BIT= NULL, @tAnswerBit SMALLINT= 0,
				@canceledNoAgents BIT= 0, @disconnectCause VARCHAR(250)= '''', @cal_key VARCHAR(20)= '''', @call_TS VARCHAR(15)=
				''''
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

	IF @call_id > 0 AND 
	   @tipoResDial_id = 1
	BEGIN
		INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
		TipoDialingMode, cal_id, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id )
			   SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
			   ''00000000'', @call_id, @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.
			   fnGetTipoLlamada( @Telefono );
	END;
		 ELSE
	BEGIN
		INSERT INTO ccoLogDials( callout_id, cam_id, tipoResDial_id, Telefono, Puerto, tDialing, fecha, answerbit, tbusy,
		TipoDialingMode, tAnswerBit, canceledNoAgents, disconnectCause, cal_key, call_TS, tipoLlamada_id )
			   SELECT @callout_id, @cam_id, @tipoResDial_id, @Telefono, @Puerto, @tTotal, @tNow, @answerbit, @tBusy,
			   ''00000000'', @tAnswerBitFinal, @canceledNoAgents, @disconnectCause, @cal_key, @call_TS, dbo.fnGetTipoLlamada(
			   @Telefono );
	END;

	SELECT @logDial_id = SCOPE_IDENTITY();

	IF @RecicleSIC = 1
	BEGIN
		UPDATE ccoWorkingTable WITH(ROWLOCK)
		  SET tipoResDial_id = @tipoResDial_id
		WHERE callout_id = @callout_id;
	END;

	SELECT @logDial_id;

	-- para marcaciones manuales, actualiza puerto de marcacion y costo de la llamada. Solo llamadas contestadas
	IF @call_id > 0 AND 
	   @tipoResDial_id = 1
	BEGIN
		UPDATE ccoCallsOut WITH(ROWLOCK)
		  SET cal_puerto = @Puerto, cal_manual = CASE
												 WHEN cal_manual = 1 THEN 2
													  ELSE cal_manual
												 END
		WHERE cal_id = @call_id AND 
			  cal_puerto = 0;

		EXEC ccsp_CstoCalculaCosto @call_id;

		IF @cal_key = ''''
		BEGIN
			SELECT @cal_key = cal_key
			FROM ccoCallsOutSource WITH(NOLOCK)
			WHERE @callout_id = callout_id;

			UPDATE ccologdials WITH(ROWLOCK)
			  SET cal_key = @cal_key
			WHERE logDial_id = @logDial_id;
		END;
	END;


	--2020-06-04 para marcaciones manuales no efectivas guarda el cal_id
					if @call_id > 0 and @tipoResDial_id != 1
					begin
						update ccologdials with(rowlock) set cal_id=@call_id where logDial_id=@logDial_id
					end

	-- inserta informacion para reportes de workgroup
	INSERT INTO ccRIAWorkGroup_logDial_id( IDWG, logDial_id, cam_id, TIMESTAMP )
		   SELECT IDWG, @logDial_id, IdCampEsp, GETDATE()
		   FROM ccRIACampEspWG
		   WHERE tipo = 1 AND 
				 IdCampEsp = @cam_id;

	-- Guarda configuracion de TipoDialingMode
	UPDATE ccoLogDials WITH(ROWLOCK)
	  SET TipoDialingMode = dbo.fn_getDialingMode( @call_id, 0, @logDial_id, @cam_id )
	WHERE logDial_id = @logDial_id;
	SET NOCOUNT OFF;
END;'
		EXEC(@sql)




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
