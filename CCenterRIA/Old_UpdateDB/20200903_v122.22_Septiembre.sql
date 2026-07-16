/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/05/06
Description:

Database: CCenterRia
Required version: 122.21

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
SET @versionfix = 22
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD' 

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

IF @actualVersion = @version AND @actualVersionFix >= 21
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
		
		set @process = 'agrega setting para ocultar telefonos'
		set @sql = 'if not exists(select * from ccSettings where setting_id=223) begin
			insert into ccsettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate) values(223,''1'',''ocultar telefono en ventanas del agente'',1,''AGT'',''setting para ocultar el telefono en el agente (0 lo muestra, 1 lo oculta)'',''Hide telephone number on CW agent'',1,''^[0-1]$'')
		end'
		EXEC(@sql)

		set @process = 'agrega setting para integracion ISAT'
		set @sql = 'if not exists(select * from ccSettings where setting_id=218) begin
			insert into ccSettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate) values (218, ''4747|20|12345'', ''Configuracion integracion Munoz-ISAT'', 1, ''AGT'', ''Parametros para integracion port|secsLookForConf|troncalID'', ''Configuration for Munoz-ISAT integration'', 0, ''.*'')
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

		set @process = 'CW-4255 Cambiar Rol a permiso'
		set @sql = 'IF NOT EXISTS
(
    SELECT Permissions_id
    FROM ccPermissions
    WHERE Description LIKE ''%Roles%''
)
    BEGIN
        INSERT INTO ccPermissions
        VALUES (10004,''Roles'',''RolesPermissionRoles'',0,0,0,''N/A'',1)
END
IF NOT EXISTS
(
    SELECT rol_id
    FROM ccRoles_Permissions
    WHERE Rol_Id = (select Rol_id from ccRoles where description = ''Root'')
          AND Permissions_id = 10004
)
    BEGIN
        INSERT INTO ccRoles_Permissions
        VALUES
        ((select Rol_id from ccRoles where description = ''Root''), 
         10004
        )
END
IF NOT EXISTS
(
    SELECT rol_id
    FROM ccRoles_Permissions
    WHERE Rol_Id = (select Rol_id from ccRoles where description = ''Admin'')
          AND Permissions_id = 10004
)
    BEGIN
        INSERT INTO ccRoles_Permissions
        VALUES
        ((select Rol_id from ccRoles where description = ''Admin''), 
         10004
        )
END
IF NOT EXISTS
(
    SELECT rol_id
    FROM ccRoles_Permissions
    WHERE Rol_Id = (select Rol_id from ccRoles where description = ''It Manager'')
          AND Permissions_id = 10004
)
    BEGIN
        INSERT INTO ccRoles_Permissions
        VALUES
        ((select Rol_id from ccRoles where description = ''It Manager''), 
         10004
        )
END
IF NOT EXISTS
(
    SELECT rol_id
    FROM ccRoles_Permissions
    WHERE Rol_Id = (select Rol_id from ccRoles where description = ''Manager'')
          AND Permissions_id = 10004
)
    BEGIN
        INSERT INTO ccRoles_Permissions
        VALUES
        ((select Rol_id from ccRoles where description = ''Manager''), 
         10004
        )
END'
		EXEC(@sql)

		set @process = 'CW-4258 Pre-asignar roles'
		set @sql = 'IF NOT EXISTS
(
    SELECT rol_id
    FROM ccRoles_Permissions
    WHERE Rol_Id = (select Rol_id from ccRoles where description = ''Manager'')
          AND Permissions_id = 10003
)
    BEGIN
        INSERT INTO ccRoles_Permissions
        VALUES
        ((select Rol_id from ccRoles where description = ''Manager''), 
         10003
        )
END
IF NOT EXISTS
(
    SELECT rol_id
    FROM ccRoles_Permissions
    WHERE Rol_Id = (select Rol_id from ccRoles where description = ''Supervisor'')
          AND Permissions_id = 10003
)
    BEGIN
        INSERT INTO ccRoles_Permissions
        VALUES
        ((select Rol_id from ccRoles where description = ''Supervisor''), 
         10003
        )
END'
		EXEC(@sql)

		set @process = 'CW-4290 Cambia tamaño de columna'
		set @sql = 'alter table ccSettings alter column descripcion varchar(150) not null'
		EXEC(@sql)

		set @process = 'CW-4290 Crear nuevo setting 224'
		set @sql = 'if not exists(select * from ccSettings where setting_id=224) begin
		insert into ccsettings (setting_id, valor, descripcion, Status, Tipo, detalle, description, bLoadSettings, validate) 
values(224,''0'',''Ocultar las opciones no detectar y desactivar CPA en el menú de configuración para máquina contestadora.'',1,''X'',
	''Setting para ocultar opciones de máquina contestadora (0-Muestra opciones / 1-Oculta opciones)'',
	''Hide the no detection and disable CPA options in the answering machine configuration menu.'',1,''^[0-1]$'')
 end'
		EXEC(@sql)

		set @process = 'CW-4387 hunaku marcacion Manual'
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
END;

	SELECT @logDial_id as LogDialId'
		EXEC(@sql)


SET @process = 'CW-4282 Se modifica sp ccsp_GalateaAdminRolesManagement'
        set @sql='
ALTER PROCEDURE [dbo].[ccsp_GalateaAdminRolesManagement]
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
--DECLARE
--	@action SMALLINT = 4,
--	@User_id VARCHAR(MAX) = ''2'',
--	@subaction VARCHAR(50)= '''',
--	@description VARCHAR(250)= ''aa'',
--	@keyJson VARCHAR(250)= '''',
--	@active BIT= 1,
--	@Roles_id VARCHAR(50)= ''1051'',
--	@Permissions_Id VARCHAR(MAX)= ''1,2'',
--	@menus_id VARCHAR(250)= '''';
BEGIN TRY
    BEGIN TRANSACTION;-- Inicia el bloque de la transaccion
	DECLARE @resultado varchar(50) = '''';
	DECLARE @returnValue SMALLINT;
    BEGIN
	 IF @action = 1
        BEGIN
        IF @subaction = ''Permissions''
            BEGIN
                IF OBJECT_ID(''tempdb..#Permissions'') IS NOT NULL DROP TABLE #Permissions;

				SELECT DISTINCT
					   (rp.Permissions_id)
				INTO #Permissions
				FROM ccUsers_Roles ur
					 INNER JOIN ccRoles_Permissions rp WITH(NOLOCK) ON rp.Rol_id = ur.Rol_id
				WHERE User_id = @User_id;
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
					 LEFT JOIN #Permissions tp WITH(NOLOCK) ON tp.Permissions_Id = p.Permissions_Id
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
                SELECT User_id, 
                       Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMaterno AS Names
                FROM ccUsers
                WHERE TipoUser_id = 2 AND User_id > 1;
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
END CATCH;'
		EXEC(@sql)

set @process = 'CW-4372 se modifica sp ccsp_IVRUpdateCallEndNew'
		set @sql = 'ALTER procEDURE [dbo].[ccsp_IVRUpdateCallEndNew]
@cal_id int,
@cal_tIVRCallDuration smallint,
@statuscal_id tinyint, 
-- Aqui solo se Aceptan Edos Terminales 2(Fuera de Horario), 3(Fuera de Servicio), 4(NoAgentesFirmados), 7(TimeOut), 8(DesbordeQue),
@cal_opciones varchar(10),
@cal_colgada tinyint,
@User_id smallint,
@cal_extension varchar(7),
@tWait smallint
AS
set nocount on



Update ccCallsIn SET statusCall_id = case when @statuscal_id in (2, 3, 4, 7, 8) then @statuscal_id else case when statusCall_id = 5 then 6 else statuscall_id end end, 
 user_id= case when user_id=0 and @User_id>0 then @User_id else user_id end, cal_extension= case when cal_extension=0 and @cal_extension>0 then @cal_extension else cal_extension end, cal_tWait=@tWait where cal_id=@cal_id

 

exec ccsp_RIAUpdateCallBack_Abandon @cal_id, @statuscal_id

--Actualizar tiempo total de llamada
exec ccsp_EngineLogTransfers 2, @cal_id, 2, 2, null, @tWait, @cal_tIVRCallDuration

set nocount off'
		EXEC(@sql)


set @process = 'CW-4372 Se modifica sp ccsp_IVRAfterXferAge'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_IVRAfterXferAge]
@cal_id int,
@User_id smallint,
@cal_extension varchar(7),
@tWait smallint
AS
set nocount on
-- 2005-11-15 por ODC
-- colocar como asignada despues de transferir
Update ccCallsIn SET user_id= case when user_id=0 and @User_id>0 then @User_id else user_id end, cal_extension= case when cal_extension=0 and @cal_extension>0 then @cal_extension else cal_extension end,-- cal_tWait=@tWait,
cal_xfer=getdate(), statusCall_id=11  -- 11=Asignada
where cal_id=@cal_id

update ccRIAWorkGroup_Calid set user_id=@User_id where cal_id = @cal_id and tipo = 0

return(0)
set nocount off'
		EXEC(@sql)


set @process = 'CW-4372 se modifica sp ccsp_AgentSetCallStatus'
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
                                   user_id = case when user_id=0 and @user_id>0 then @user_id else user_id end, 
                                   cal_extension = case when cal_extension=0 and @extension>0 then @extension else cal_extension end
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
                           user_id = case when user_id=0 and @user_id>0 then @user_id else user_id end, 
                           cal_extension = case when cal_extension=0 and @extension>0 then @extension else cal_extension end
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
		EXEC(@sql)


		set @process = 'CW-4244 Modificar sp ccsp_RIAGetAveTimeEspec'
		set @sql = '
ALTER PROCEDURE [dbo].[ccsp_RIAGetAveTimeEspec]
@CveCamp int
AS

declare @fechaI as datetime, @fechaF as datetime
declare @Dlgs as int
declare @DlgsAveTime as int
declare @Que as int
declare @QueueAveTime as int
declare @CallsLost as int
declare @SL1 as int
declare @SL2 as int
declare @answ_tres as smallint
declare @abnd_tres as smallint

declare @nanswer as smallint
declare @nno_answer as smallint
declare @nlost as smallint
declare @nabnd as smallint
declare @ntimeout as smallint
declare @noverflow as smallint
declare @nno_agent as smallint
declare @total as int
declare @setting as tinyint

declare @dia as varchar(11)

declare @tresRing as smallint
declare @tresDialog as smallint
declare @tresDelayIn as smallint

exec @tresRing = ccspConfigTresRing
exec @tresDialog = ccspConfigTresDialog
exec @tresDelayIn = ccspConfigtresDelayIn

--select @dia = ''2003/01/22'' --, @CveCamp=5
select @dia=CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))

select @fechaI = convert(datetime, @dia, 101)
select @fechaF = dateadd( d, 1, @fechaI )
select @setting = valor from ccsettings where setting_id = 127


declare @acdType tinyint 

select @acdType= chat from ccInbound where Inbound_id = @CveCamp

if @acdType= 0 begin --call
SELECT 
@Dlgs = count(case when statuscall_id = 13 then 1 else null end), 
@DlgsAveTime = ISNULL(sum( case when statuscall_id = 13 then cal_tDialog + cal_tNotas else null end), 0),

@Que = count(case when cal_que> 0 then 1 else null end), 
@QueueAveTime = ISNULL(sum( case when cal_que > 0 then cal_tWait else null end), 0),

@CallsLost= isnull(COUNT(CASE WHEN (statuscall_id IN (5,6) AND (cal_que > 0) AND (cal_xfer IS NULL))  THEN 1 ELSE NULL END), 0), -- ODC

@abnd_tres = COUNT(CASE WHEN((statuscall_id IN(5,6)AND cal_que>0 AND cal_xfer IS NULL)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END),
@answ_tres =  case when @setting = 0 then COUNT(CASE WHEN((statuscall_id=13 AND cal_tdialog>@tresDialog)AND(cal_twait + cal_txfer + cal_tring<@tresDelayIn))THEN 1 ELSE NULL END) else Count(case when (statuscall_id = 13 and (cal_twait + cal_txfer + cal_tring<@tresDelayIn)) then 1 else null end) end,

@SL1 = case when @setting = 0 then @abnd_tres + @answ_tres else @answ_tres end,

@nanswer = COUNT(CASE WHEN((statuscall_id=13)AND(cal_tdialog >@tresDialog))THEN 1 ELSE NULL END),
@nno_answer = COUNT(CASE WHEN((statuscall_id=15)AND(cal_tring>@tresRing))THEN 1 ELSE NULL END),
@nlost = COUNT(CASE WHEN(statuscall_id=16)THEN 1 ELSE NULL END),
@nabnd = COUNT(CASE WHEN(statuscall_id IN(5,6)AND(cal_que>0)AND(cal_xfer IS NULL))THEN 1 ELSE NULL END),
@ntimeout = COUNT(CASE WHEN(statuscall_id=7)THEN 1 ELSE NULL END),
@noverflow = COUNT(CASE WHEN(statuscall_id=8)THEN 1 ELSE NULL END),
@nno_agent = COUNT(CASE WHEN(statuscall_id=4)THEN 1 ELSE NULL END),
@total = count(*),

@SL2 = case when @setting = 0 then @nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent else @total end
FROM ccCallsIN
WHERE cal_Inicio between @fechaI AND @fechaF
AND Inbound_id = @CveCamp

select 
	''ID''=@CveCamp, 
	''DlgsAveTime''=@DlgsAveTime/ (@Dlgs+1), 
	''QueueAveTime''=@QueueAveTime / (@Que +1),
	''SL'' = case 
		when @SL2 > 0 
		then 100 * @SL1 / @SL2 
		else 0 end, 
	''sl2'' = case 
		when @setting = 0 
		then 
			case 
				when (@nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent) > 0 
				then 100 * (@abnd_tres + @answ_tres) / (@nanswer + @nno_answer + @nlost + @nabnd + @ntimeout + @noverflow + @nno_agent)
				else 0 end 
		else case 
			when @total > 0 
			then 100 * @answ_tres/@total 
			else 0 end end
	 ,@acdType as acdType
end

else if @acdType= 1 begin

declare @CC int,@CCAb int,@ccme int,@ccma int,@cAs int,@cs int,@cAb int,@cDt int,@cDe int
select @CC=0,@ccme=0,@ccma=0,@cAs=0,@cs=0,@cAb=1,@cDt=0,@cDe=0,@DlgsAveTime=0

select
@CC = count(case when chatStatus=4 then 1 else null end) ,
@CCAb = count(case when chatStatus=9 and tQueue<@tresDialog then 1 else null end) ,
@DlgsAveTime = isnull(sum(case when chatStatus=4 then tChatting+tWrapUp else null end),0) ,
@ccme = count(case when chatStatus=4 and tChatting<@tresDialog and finishedBy=0 then 1 else null end),
@ccma = count(case when chatStatus=4 and tChatting>@tresDialog then 1 else null end) ,
@cAs= count(case when chatStatus=3 then 1 else null end) ,
@cs = count(case when chatStatus=7 then 1 else null end) ,
@cAb = count(case when chatStatus=9 and tQueue>=@tresDialog then 1 else null end) ,
@cDt = count(case when chatStatus=11 then 1 else null end) ,
@cDe = count(case when chatStatus=10 then 1 else null end),
@Que = count(case when onQueue > 0 then 1 else null end), 
@QueueAveTime = ISNULL(sum( case when onQueue > 0 then tQueue else null end), 0),
@SL2 = @ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe
from ccRIAChats 
where requestDate between @fechaI AND @fechaF
and inboundId=@CveCamp 
group by inboundId 

select 
	@CveCamp as ID, 
	isnull(@DlgsAveTime/ (@CC+1),0) as DlgsAveTime, 
	isnull(@QueueAveTime / (@Que +1),0) as QueueAveTime,
	case when @SL2>0 then (@CC+@CCAb)*100/(@SL2) else 0 end as SL,
	isnull((@CC+@CCAb)*100/nullif(@ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe,0),0) as Sl2,
	@acdType as acdType,
	@CC+@CCAb as CC,
	@SL2 as SumSL
end
		'
		EXEC(@sql)


		set @process = 'CW-4373 Se Modifica sp ccsp_RIAInsertChat'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_RIAInsertChat]
@action int,
@inboundId smallint = 0,
@domain varchar(50) = '''',
@session varchar(50) = '''',
@tTimeout smallint = 0,
@chatId int = 0,
@status tinyInt = 0,
@userId smallint = 0,
@finished tinyInt = 0,
@chattingTime int = 0,
@startTime datetime = null,
@clientName varchar(50) = '''',
@firstMessage int = 0,
@firstMessageTime datetime = null,
@crmNode xml = null,
@supervisor varchar(100) =null,
@template varchar (100)= null,
@ScoreTemplate int = null
AS

declare @xml xml
declare @sql nvarchar(2000)

if @action = 1 begin -- Inserta nuevo chat request /*comentario: se recomienda hacer la busqueda del userid del CRM en esta action*/
       insert into ccRIAChats (domain,session,chatStatus,requestDate,inboundId,clientName)
       values(@domain,@session,@status,getDate(),0,@clientName)
       set @chatId = scope_identity()
       select @chatId
end

else if @action = 2 begin -- Save Initial Info
update ccRIAChats set inboundId = @inboundId, chatStatus = @status, userId = @userId, tTimeout = @tTimeout where chatId = @chatId
end

else if @action = 3 begin -- Update Status
update ccRIAChats set chatStatus = @status where chatId = @chatId
end

else if @action = 4 begin -- Save Final Status
if @firstMessage = 0
       begin
             update ccRIAChats set finishedBy = @finished where chatId = @chatId
       end
else
       begin
             update ccRIAChats set finishedBy = @finished, firstMessageTime  = @firstMessageTime where chatId = @chatId
       end
end

else if @action in (5,6) begin -- Save Chatting Time /*comentario: la insercion del nodo (registro final para el finder) se recomiendo en esta action, no olvidar validar status = 4, finishedby != null y validar los tiempos para garantizar el dato final */
       if @action = 5 begin
             update ccRIAChats set tChatting = @chattingTime, chatDate = @startTime where chatId = @chatId
       end

	   if @action = 6 begin
			update ccRIAChats set userId = @userId where chatId = @chatId
	   end

	   set @crmNode = null

	   exec ccsp_CreateNodeMultimedia @conversationId=@chatId, @type=0,@xml=@xml OUTPUT,@supervisor=@supervisor,@template =@template,@ScoreTemplate=@ScoreTemplate

       if @xml is not null
       begin
             select @crmNode = node from ccCRMNodes where chatId = @chatId
             if @crmNode is not null
             begin
                    set @sql = N'' set @xml.modify(''''insert''++CONVERT(NVARCHAR(2000),@crmNode)+'' into(/R01)[1]'''') ''
                    execute sp_executesql @sql,N''@xml XML Output,@crmNode XML'',@xml OUTPUT,@crmNode
             end

             if not exists(select * from ccChatsNode where chatId=@chatId) begin ---insert finder
                insert into ccChatsNode (chatId,node, dateIn,[status]) values (@chatId,@xml, getdate(),0)
             end
             else begin ---update finder
				update ccChatsNode set [status] = 2, node =@xml  where chatId = @chatId
                --select @chatId
             end
       end
end'
		EXEC(@sql)

		set @process = 'CW-XXXX Se Modifica sp ccsp_BaseXmngr'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_BaseXmngr]
@action int,
@option tinyint = 0,
@ids varchar(max)=null,
@name varchar(25) = NULL,
@top int = 0,
@dateIni datetime =null,
@dateEnd datetime =null,
@dateStart dateTime= null,
@userId int = 0
AS

declare @sql nvarchar(max),@tableName nvarchar(max),@columnId nvarchar(max),@tableNameHistory nvarchar(max)
declare @parameterDefinition nvarchar(max)
declare @chat tinyint ,@rec tinyint,@email tinyint,@twitter tinyint
declare @status tinyint
set @sql = ''''


if @action in (1,2,6,7) begin
	if @option = 1 begin
		set @tableName=''ccChatsNode''
		set @columnId=''chatId''
		set @tableNameHistory = ''ccChatsNodeHistory''
	end
	else if @option = 3 begin
		set @tableName=''ccEmailNode''
		set @columnId=''emailId''
		set @tableNameHistory = ''ccEmailNodeHistory''
		end
	else if @option = 4 begin
		set @tableName=''ccTwitterNode''
		set @columnId=''conversationTwitterId''
		set @tableNameHistory = ''ccTwitterNodeHistory''
	end
end



if @action in (1,6) begin --obtiene los nodos a insertar en BX
	if @action = 1 set @status =0
	else if @action = 6 set @status = 2

	if @option in (1,3,4) begin

	declare @auxTag nvarchar(4)
	
	select @auxTag =case when @option = 1 then ''@C09'' when @option in (3,4) then ''@C02'' end
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
	order by baseX.Xname''

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
	print(@sql)
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
	select @chat= 0,@rec= 2,@email= 0,@twitter=0
	select @chat = case when valor >= 1 then 1 else 0 end from ccSettings where setting_id = 145
	select @email = case when valor = 1 then 3 else 0 end from ccSettings where setting_id = 155
	select @twitter = case when valor = 1 then 4 else 0 end from ccSettings where setting_id = 173
	select id, ref  from ccFinderServices where id in (@chat, @rec, @email,@twitter)	
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
	update ccBaseXDB set isfull = 1,dateEnd=isnull(@dateEnd,getdate()) where serviceId= @option and  isfull = 0 and dateEnd is null
end

else if @action = 10 begin
	declare @filterWg varchar(max)
	declare @len int
	set @filterWg=''''
		 
		select @filterWg=@filterWg+''(@CID='' +convert(varchar(max), WGCam.IdCampEsp)+ '' and @CType=''+convert(varchar(max), WGCam.Tipo+1)+'') or '' from ccRIAWorkGroupUsers Wguser
		inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
		where Wguser.User_id=@userId
		 
		set @len=len(@filterWg)- CHARINDEX(''ro )'', REVERSE(@filterWg))
		select SUBSTRING(@filterWg,0, @len)
end


else if @action = 11 begin--trae el nombre de la base de datos en BX

	if @option =1 begin
	SELECT isnull(ISNULL(min(node.value(''(/R01/@CDATE)[1]'',''datetime'')),min(node.value(''(/R01/@C09)[1]'',''datetime''))),GETDATE()) as node FROM ccChatsNode where status = 0
	end
	if @option =3 begin
	SELECT isnull(ISNULL(min(node.value(''(/R03/@CDATE)[1]'',''datetime'')),min(node.value(''(/R03/@C02)[1]'',''datetime''))),GETDATE()) as node FROM ccEmailNode where status = 0
	end
	if @option =4  begin
	SELECT isnull(ISNULL(min(node.value(''(/R04/@CDATE)[1]'',''datetime'')),min(node.value(''(/R04/@C02)[1]'',''datetime''))),GETDATE()) as node FROM ccTwitterNode where status = 0
	end

end'
		EXEC(@sql)

		set @process = 'CW-XXXX Se Modifica sp ccsp_CreateNodeMultimedia'
		set @sql = 'ALTER PROCEDURE [dbo].[ccsp_CreateNodeMultimedia]
@conversationId bigint,
@xml xml OUTPUT,
@supervisor varchar(255)='''',
@template varchar (255)='''',
@ScoreTemplate int=0,
@type int =1--1 EMAIL , 2 Twitter
AS
BEGIN
declare @info varchar(255)
declare @infoEscape varchar(max)
declare @charEscape varchar(255),@charReplace varchar(max)
set @charEscape=''"|''''''''|<|>|&''
set @charReplace=''&quot;|&apos;|&lt;|&gt;|&amp;''

declare @existAttached bit,@numInteracion smallint
if @type=0 begin--CHAT

    select @xml = convert(xml,''<R01 CDATE="''+rtrim(ltrim(convert(varchar(23), isNull(chatDate,requestDate), 126))) +
	''" CID="''+convert(varchar(max),ccRIAChats.inboundid) +
	''" CType="1''+
    ''" C01="''+convert(varchar(max),chatId) +
    ''" C02="''+convert(varchar(max),isnull(ccinbound.descripcion,'''')) +
    ''" C03="''+convert(varchar(max),domain) +
    ''" C04="''+convert(varchar(max), isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno,''N/A'') ) +
    ''" C05="''+convert(varchar(max),tchatting) +
    ''" C06="''+convert(varchar(max),isnull(cctipocalif.[Description],''N/A'')) +
    ''" C07="''+convert(varchar(max),isnull(cctipocalifsub.califSubdesc,''N/A'')) +
    ''" C08="''+convert(varchar(max),clientname) +
    ''" C09="''+rtrim(ltrim(convert(varchar(23), chatDate, 126))) +
    ''" C10="''+convert(varchar(max),isnull(@supervisor,'''') ) +
    ''" C11="''+convert(varchar(max),isnull(@template,'''') )  +
    ''" C12="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +
    ''" C13="''+convert(varchar(max),isnull(ccusers.[Login],'''')) + ''"/>'')
    from ccRIAChats
    left outer join ccinbound on ccinbound.inbound_id = ccRIAChats.inboundid
    left outer join ccusers on ccusers.user_id = ccRIAChats.userid
    left outer join cctipocalif on cctipocalif.calif_id = ccRIAChats.disposition
    left outer join cctipocalifsub on cctipocalifsub.califsub_id = ccRIAChats.subdisposition and ccRIAChats.subdisposition <> 0
    where chatId = @conversationId and chatStatus = 4 and requestDate is not null and chatDate is not null

end
else if @type=1 begin--EMAIL
    SELECT @existAttached = case when count(*)>0 then 1 else 0 end
    from attached where messageId in (select messageId from message where conversationId=@conversationId)
    select @numInteracion = count(*) from message where conversationId=@conversationId
    --Replaza los caracteres por los comunes
    select @info=info from conversation where conversationId=@conversationId
    select @info=replace(@info,A.Value,B.Value) from dbo.fn_RIASplitDelimited(@charEscape,''|'') A
    inner join dbo.fn_RIASplitDelimited(@charReplace,''|'') B on A.Id=B.Id


    select @xml = convert(xml,''<R03 CDATE="''+ rtrim(ltrim(convert(varchar(23), isnull(max(b.tsend), getdate()), 126))) +
	''" CID="''+convert(varchar(max),a.inboundid) +
	''" CType="1''+
    ''" C01="''+ convert(varchar(max),a.conversationId) +
    ''" C02="''+ rtrim(ltrim(convert(varchar(23), isnull(max(b.tsend), getdate()), 126))) +
    ''" C03="''+ convert(varchar(max),max(c.descripcion)) +
    ''" C04="''+ convert(varchar,max(isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno,''''))) +
    ''" C05="''+ convert(varchar,max(isnull(cctipocalif.[Description],''N/A''))) +
    ''" C06="''+ convert(varchar,max(replace(replace(a.mailClient,''<'','' ''),''>'','' ''))) +
    ''" C07="''+ convert(varchar(max),sum(b.tRetention+b.tResponse+b.tWrapup)) +
    ''" C08="''+ convert(varchar(max),min(isnull(@info,''''))) +
    ''" C09="''+ convert(varchar(max),max(b.messageStatusid) ) +''" C10="''+  convert(varchar(max), isnull(@numInteracion,0)) +
    ''" C11="''+ convert(varchar(max),@existAttached) +''" C12="''+ convert(varchar(max),isnull(@supervisor,'''') ) +
    ''" C13="''+ convert(varchar(max),isnull(@template,'''') )  +''" C14="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +
    ''" C15="''+ convert(varchar,max(isnull(cctipocalifsub.califSubdesc,''N/A''))) +
    ''" C16="''+ convert(varchar(max),isnull(max(d.[Login]),'''')) + ''"/>'')
    from conversation a
    inner join message b on a.conversationid=b.conversationid
    left outer join ccinbound c on c.inbound_id = a.inboundid
    left outer join ccusers d on d.user_id = b.userid
    left outer join relationmessageDisposition e on e.messageId=b.messageId
    left outer join cctipocalif on cctipocalif.calif_id = e.dispositionId
    left outer join cctipocalifsub on cctipocalifsub.califsub_id = e.subdispositionId and e.subdispositionId <> 0
    where a.conversationId=@conversationId
    group by a.conversationId,a.inboundid

end
else if @type=2 begin--Twitter
    select @numInteracion = sum(ninteration) from messageOutTwitter where conversationTwitterId=@conversationId

    select @xml = convert(xml,''<R04 CDATE="''+rtrim(ltrim(convert(varchar(23), min(b.date), 126))) +
	''" CID="''+convert(varchar(max),a.inboundid) +
	''" CType="1''+
    ''" C01="''+convert(varchar(max),a.conversationTwitterId) +
    ''" C02="''+rtrim(ltrim(convert(varchar(23), min(b.date), 126))) +
    ''" C03="''+convert(varchar(max),max(c.descripcion)) +
    ''" C04="''+ convert(varchar,max(isnull(Nombres + '' '' + ApellidoPaterno + '' '' + ApellidoMAterno,''''))) +
    ''" C05="''+convert(varchar,max(isnull(cctipocalif.[Description],''N/A''))) +
    ''" C06="''+ max(a.screenNameClient) +
    ''" C07="''+convert(varchar(max),sum(b.tRetention+b.tResponse+b.tWrapup)) +
    ''" C08="''+ max(a.screenNameInbound) +
    ''" C09="''+convert(varchar(max),max(b.messageStatusid) ) +
    ''" C10="''+  convert(varchar(max), isnull(@numInteracion,0)) +
    ''" C11="''+ convert(varchar(max),isnull(@supervisor,'''') ) +
    ''" C12="''+convert(varchar(max),isnull(@template,''''))  +
    ''" C13="''+convert(varchar(max),isnull(@ScoreTemplate,0)) +
    ''" C14="''+ convert(varchar,max(isnull(cctipocalifsub.califSubdesc,''N/A''))) +
    ''" C15="''+convert(varchar(max),isnull(max(d.[Login]),'''')) + ''"/>'')
    from conversationTwitter a
    inner join messageOutTwitter b on a.conversationTwitterId=b.conversationTwitterId
    left outer join ccinbound c on c.inbound_id = a.inboundid
    left outer join ccusers d on d.user_id = b.userid
    left outer join relationMessageDispositionTwit e on e.messageOutTwitterId=b.messageOutTwitterId
    left outer join cctipocalif on cctipocalif.calif_id = e.dispositionId
    left outer join cctipocalifsub on cctipocalifsub.califsub_id = e.subdispositionId and e.subdispositionId <> 0
    where a.conversationTwitterId=@conversationId
    group by a.conversationTwitterId,a.inboundid
end

END'
		EXEC(@sql)


		set @process = 'modifico setting para integracion ISAT'
		set @sql = 'if exists(select * from ccSettings where setting_id=172) begin
			update ccSettings set valor = ''2|4|1|14:26|home289550584.1and1-data.host;22;u53828902-cofetel;$f:LV7YAvk68'' where setting_id = 172
		end'
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
