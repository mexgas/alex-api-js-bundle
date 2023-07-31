/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2022/11/19
Description: Cambios para estados de email

Database: CCenterRia
Required version: 124

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
SET @versionfix = 20
/* Actual version (use your own script to do it)*/
EXEC @actualVersion = ccsp_getVersion 'BD'

EXEC @actualVersionFix = ccsp_getVersion 'BDF'

SELECT @versionALL = valor
FROM ccsettings
WHERE setting_id = 77;

SELECT @actualVersionFix = cast(isnull(max(value), '0') AS INT)
FROM dbo.fn_RIASplitDelimited(@versionALL, '.')
WHERE id = 4;

--- Validaci?n para cuando pasamos a una nueva versi?n LTS
declare @versioMajer int= case when @version > @actualVersion then 1 else 0 end


IF @version > @actualVersion 
BEGIN 
    SET @actualVersionFix = 0
    select @version,@actualVersion,@versioMajer
END

IF @version >= @actualVersion  and @versionfix >= @actualVersionFix 
BEGIN
    BEGIN TRAN

    BEGIN TRY
        -------------------------------------------- BEGIN MARCO GARCÍA K043000 DASHBOARD CHAT ------------------------------
SET @process = 'K043000-Dashboard Chat delete store procedure [ccsp_RIAGetAveTimeEspec]'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIAGetAveTimeEspec'')
	BEGIN
		DROP PROCEDURE ccsp_RIAGetAveTimeEspec
	END'
EXEC(@sql)

SET @process = 'K043000-Dashboard Chat  create store procedure [ccsp_RIAGetAveTimeEspec]'
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAGetAveTimeEspec]
	@CveCamp INT,
	@IsKolob BIT = 0
	AS

	declare @fechaI as datetime, @fechaF as datetime
	declare @Dlgs as int
	declare @DlgsAveTime as int
	declare @Que as int
	declare @QueueAveTime as INT
    declare @QueueMaxTime as int
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
		''Id''=@CveCamp, 
		''AverageServiceTime''=@DlgsAveTime/ (@Dlgs+1), 
		''AverageWaitingTime''=@QueueAveTime / (@Que +1),
		''ServiceLevel'' = case 
			when @SL2 > 0 
			then 100 * @SL1 / @SL2 
			else 0 end, 
		''ServiceLevel2'' = case 
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
			,@acdType as Type
	end

	else if @acdType= 1 begin

	declare @CC int,@CCAb int,@ccme int,@ccma int,@cAs int,@cs int,@cAb int,@cDt int,@cDe int
	select @CC=0,@ccme=0,@ccma=0,@cAs=0,@cs=0,@cAb=1,@cDt=0,@cDe=0,@DlgsAveTime=0

	select
	@CC = count(case when chatStatus=4 and tChatting>=@tresDialog then 1 else null end) ,
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
	@QueueMaxTime = ISNULL (MAX (CASE WHEN onQueue    = 1 THEN  tQueue ELSE NULL END), 0),
	@SL2 = @ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe
	from ccRIAChats 
	where requestDate between @fechaI AND @fechaF
	and inboundId=@CveCamp 
	group by inboundId 

	DECLARE @RESULT DECIMAL(18,2);

		IF(@IsKolob = 1)
		BEGIN
			select 
				@CveCamp as ID, 
				isnull(@DlgsAveTime/ (@CC + 1),0) as AverageServiceTime, 
				isnull(@QueueAveTime / (@Que + 1),0) as AverageWaitingTime,
				ISNULL(CONVERT(BIGINT,@QueueMaxTime),0) AS MaximumWaitingTime,
				case when @SL2>0 then (@CC)*100/(@SL2) else 0 end as ServiceLevel,
				isnull((@CC)*100/nullif(@ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe,0),0) as ServiceLevel2,
				@acdType as acdType,
				ISNULL(@CC+@CCAb,0) as CC,
				ISNULL(@SL2,0) as SumSL
		END
		ELSE 
		BEGIN
			select 
			@CveCamp as ID, 
			isnull(@DlgsAveTime/ (@CC+1),0) as DlgsAveTime, 
			isnull(@QueueAveTime / (@Que +1),0) as QueueAveTime,
			case when @SL2>0 then (@CC+@CCAb)*100/(@SL2) else 0 end as SL,
			isnull((@CC+@CCAb)*100/nullif(@ccme+@ccma+@cAs+@cs+@cAb+@cDt+@cDe,0),0) as Sl2,
			@acdType as acdType,
			ISNULL(@CC+@CCAb,0) as CC,
			ISNULL(@SL2,0) as SumSL
		END
	END'
EXEC(@sql);

	
SET @process = 'K043000-Dashboard Chat delete store procedure [ccsp_RIAADMGetCalifDayForced]'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIAADMGetCalifDayForced'')
	BEGIN
		DROP PROCEDURE ccsp_RIAADMGetCalifDayForced
	END'
EXEC(@sql)

SET @process = 'K043000-Dashboard Chat  create store procedure [ccsp_RIAADMGetCalifDayForced]';
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAADMGetCalifDayForced]
	@type smallint,
	@cam_id smallint,
	@calif_id smallint = NULL,
	@isKolob BIT = 0
	AS 
	set nocount on
	create table #CalifTemp (id int identity,
	tipo integer, 
	Cam_id varchar(50), 
	Calificacion varchar(60), 
	subCalificacion varchar(60) null,
	calif_id smallint null,
	Total int,
	GraphColor varchar(15),
	IsSubDisp BIT)

	declare @today datetime
	set @today = convert(datetime, convert (varchar(11), getdate(), 101))
	--set @today =convert(datetime, convert (varchar(11), ''2015-10-01 17:50:20.470'', 101))

	-- Seleccion de idioma -- 
	declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
	select @nIdioma = case valor when 0 then ''Sin calificación'' WHEN 1 THEN ''No disposition''  else ''Sem classificação'' end
	from ccsettings where setting_id = 27 -- 0esp

	select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
	from ccsettings where setting_id = 27 -- 0 esp

	if @type=0 
	BEGIN
		insert into #CalifTemp 
		select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13
				then case when description is not null 
							then description 
							else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
							end
		else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
		end end as Calificacion,
		case when count(co.califSub_id) > 0 then 1 else 0 end as Subcalificacion,co.calif_id as calif_id,count(*) cantidad,
		ISNULL(GraphColor,''1DB4E2'') GraphColor,
		CASE WHEN ISNULL(rel.calif_id, 0) = 0 THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS IsSubDisp
		from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
		left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
		LEFT join cctipoSubCalifRel rel on rel.calif_id = ca.calif_id
		left join ccTipoCalifSubOUT tcsout on co.califSub_id = tcsout.califSub_id
		left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
		left join ccCamps ci on ci.cam_id = co.cam_id 
		where co.cal_inicio > @today
		and co.cam_id = @cam_id
		group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id,GraphColor, rel.calif_id
	END

	if @type=1 
	insert into #CalifTemp 
	select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
	else @nIdioma-- substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	end as Calificacion,count(ci.califSub_id) as subCalificacion,ci.calif_id,count(*)  as total,
	ISNULL(GraphColor,''1DB4E2'') GraphColor,
	0 as IsSubDisp
	from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) 
	left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
	left join ccInbound cci on cci.inbound_id = ci.inbound_id 
	where ci.cal_inicio > @today
	and ci.inbound_id = @cam_id
	and statuscall_id = 13 
	group by description, cci.inbound_id,ci.califSub_id,ci.calif_id,GraphColor

	-- Se corrigio suma de totales -- 
	Alter table #CalifTemp add iTotal4Campaign int null

	if (select valor from ccSettings where setting_id = 78) = 0
	update #CalifTemp set iTotal4Campaign = 0

	else	
	update #CalifTemp set iTotal4Campaign = t.iTotal4Campaign 
	from (select cam_id, sum(A.Total) iTotal4Campaign
	from #CalifTemp A group by cam_id) t join #CalifTemp c
	on t.cam_id = c.cam_id

	if @type=1 
	BEGIN
		IF(@isKolob = 1)
		BEGIN
			select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total, GraphColor from (
			select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
				else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
				end as Calificacion,0 as subCalificacion ,a.disposition as calif_id, COUNT(disposition) as Total,ISNULL(GraphColor,''1DB4E2'') GraphColor--,0 as iTotal4Campaign
			from ccriachats a left join ccTipoCalif b 
			on a.disposition=b.calif_id 
			where a.chatDate > @today
			and a.inboundId = @cam_id
			group by inboundId, Description, GraphColor, a.disposition
			union all
	
	
			select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
			then calificacion 
			else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
			end as Calificacion,
			case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor  --iTotal4Campaign -- para ver total por campaña
			from #CalifTemp 
			group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
			then calificacion 
			else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
			end, Cam_id,calif_id, iTotal4Campaign, GraphColor
			)  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id,GraphColor   order by tipo,cam_id 
		END
		ELSE
		BEGIN
			select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total, GraphColor from (
			select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
				else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
				end as Calificacion,0 as subCalificacion ,0 as calif_id,count(disposition) as Total,ISNULL(GraphColor,''1DB4E2'') GraphColor--,0 as iTotal4Campaign
			from ccriachats a left join ccTipoCalif b 
			on a.disposition=b.calif_id 
			where a.chatDate > @today
			and a.inboundId = @cam_id
			group by inboundId, Description, GraphColor
	
			union all
	
	
			select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
			then calificacion 
			else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
			end as Calificacion,
			case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor  --iTotal4Campaign -- para ver total por campaña
			from #CalifTemp 
			group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
			then calificacion 
			else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
			end, Cam_id,calif_id, iTotal4Campaign, GraphColor
		)  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id,GraphColor order by tipo,cam_id 
		END
	END
		
	if @type=0 

	select tipo as Type,Cam_id as CampId,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	then calificacion 
	else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
	end as Calification,subCalificacion as SubCalificationQuantity, calif_id as CalificationId,sum(Total) as Total, ISNULL(GraphColor,''1DB4E2'') GraphColor -- , iTotal4Campaign -- para ver total por campaña
	,IsSubDisp
	from #CalifTemp 
	group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
	then calificacion 
	else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
	end, Cam_id,subCalificacion, calif_id, iTotal4Campaign, GraphColor, IsSubDisp



	if @type = 3 begin -----entrada acd''s
		select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
		else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
		end as Calificacion,isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(*) as totales 
		from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
		left join ccInbound cci on cci.inbound_id = ci.inbound_id 
		left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
		where ci.cal_inicio > @today
		and ci.inbound_id = @cam_id
		and statuscall_id = 13 
		and ci.calif_id = @calif_id
		group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id 
	end

	if @type = 4 begin --salida campañas
			select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13 
				then case when description is not null 
							then description 
							else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
							end
		else case when sll.descripcion is not null 
		then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
		end end as Calificacion,isnull(cso.califSubDesc,@nIdiomaSub) ,count(*) cantidad 
		from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
		left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
		left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id
		left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
		left join ccCamps ci on ci.cam_id = co.cam_id 
		where co.cal_inicio > @today
		and co.cam_id = @cam_id
		group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
	end 
 

	drop table #CalifTemp 
	set nocount off'
EXEC(@sql)

	
SET @process = 'K043000-Dashboard Chat delete store procedure [ccsp_RIAADMGetCalifDay]'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIAADMGetCalifDay'')
	BEGIN
		DROP PROCEDURE ccsp_RIAADMGetCalifDay
	END'
EXEC(@sql)

SET @process = 'K043000-Dashboard Chat  create store procedure [ccsp_RIAADMGetCalifDay]';
SET @sql = 'CREATE Procedure [dbo].[ccsp_RIAADMGetCalifDay]
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
				where ci.cal_inicio > @today and statuscall_id = 13	and cci.Inbound_id=@inbound_id
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
		select @typeACD as Type,cci.inbound_id as CampId,  [description] as Calification,
		isnull(ctcs.califSubDesc,@nIdiomaSub) as SubCalificationName, count(ctcs.califSubDesc) as Quantity
		from ccCallsIn ci with(nolock, index(IX_ccCallsIn))
		left join ccTipoCalif ca on ci.calif_id = ca.calif_id
		left join ccInbound cci on cci.inbound_id = ci.inbound_id
		left join ccTipoCalifSub ctcs on ci.califSub_id = ctcs.califSub_id
		where ci.cal_inicio > @today
		and ci.inbound_id = @inbound_id  and statuscall_id = 13  and ci.calif_id = @calif_id
		group by description, cci.inbound_id,ctcs.califSubDesc,ci.calif_id
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
		IF OBJECT_ID(''tempdb..#tempSub'') IS NOT NULL DROP TABLE #tempSub;
		DECLARE @count INT = 0;
		select 0 as Type,co.cam_id as CampId,
		case when co.statuscall_id = 13
		then case when description is not null
		then description else @nIdioma end
		else
		case when sll.descripcion is not null
		then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma
		end
		end as Calification,
		isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(cso.califSub_id) Quantity,
		ISNULL(cso.califSub_id, 0) as [id]
		INTO #tempSub
		from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
		left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
		left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id 
		left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
		left join ccCamps ci on ci.cam_id = co.cam_id
		where co.cal_inicio > @today
		and co.cam_id = @inbound_id
		and co.calif_id = @calif_id
		group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc, cso.califSub_id
		SELECT @count = COUNT(*) FROM #tempSub

		IF (@count > 1)
		BEGIN
			SELECT * FROM #tempSub
			RETURN 0;
		END

		IF NOT EXISTS(SELECT 1 FROM cctipoSubCalifRel WHERE calif_id = @calif_id)
		BEGIN
			DELETE FROM #tempSub WHERE [id] = 0;
		END

		SELECT * FROM #tempSub;
		IF OBJECT_ID(''tempdb..#tempSub'') IS NOT NULL DROP TABLE #tempSub;
		RETURN 0;
	end


	drop table #CalifTemp
	set nocount off'
EXEC(@sql)

	
	
	
SET @process = 'K043000-Dashboard Chat delete store procedure [ccsp_RIAChatGetAllInfoACD]'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_RIAChatGetAllInfoACD'')
	BEGIN
		DROP PROCEDURE ccsp_RIAChatGetAllInfoACD
	END'
EXEC(@sql)

SET @process = 'K043000-Dashboard Chat  create store procedure [ccsp_RIAChatGetAllInfoACD]';
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAChatGetAllInfoACD]
@Option AS SMALLINT,
@User_id AS SMALLINT,
@Date AS DATETIME = NULL,
@inboundID AS INT = NULL
AS
SET NOCOUNT ON

DECLARE @dateStart DATETIME
DECLARE @dateEnd   DATETIME
DECLARE @wgID INT


IF @Date IS NULL
BEGIN
	SET @Date = GETDATE()
END

SET @dateStart = CONVERT(DATETIME, DATEDIFF(DAY, 0, @Date))
SET @dateEnd   = DATEADD (DAY, 1, @datestart)

SELECT @wgID = crwgu.IDWG FROM dbo.ccRIAWorkGroupUsers AS crwgu WHERE crwgu.User_id = @User_id;
SET @dateEnd   = DATEADD (SECOND, -1, @dateend)

IF @Option = 1 -- Chats
BEGIN
SELECT
	InboundId,
	Chats             = ISNULL (COUNT(*), 0),
	Request           = ISNULL (COUNT (CASE WHEN chatStatus =  0 THEN 1 ELSE NULL END), 0),
	InactiveDomain    = ISNULL (COUNT (CASE WHEN chatStatus =  1 THEN 1 ELSE NULL END), 0),
	UnavailableAgents = ISNULL (COUNT (CASE WHEN chatStatus =  2 THEN 1 ELSE NULL END), 0),
	Assigned          = ISNULL (COUNT (CASE WHEN chatStatus =  3 THEN 1 ELSE NULL END), 0),
	Connected         = ISNULL (COUNT (CASE WHEN chatStatus =  4 THEN 1 ELSE NULL END), 0),
	OutOfService      = ISNULL (COUNT (CASE WHEN chatStatus =  5 THEN 1 ELSE NULL END), 0),
	OutOfSchedule     = ISNULL (COUNT (CASE WHEN chatStatus =  6 THEN 1 ELSE NULL END), 0),
	NoSignedAgents    = ISNULL (COUNT (CASE WHEN chatStatus =  7 THEN 1 ELSE NULL END), 0),
	Queued            = ISNULL (COUNT (CASE WHEN chatStatus =  8 THEN 1 ELSE NULL END), 0),
	Abandon           = ISNULL (COUNT (CASE WHEN chatStatus =  9 THEN 1 ELSE NULL END), 0),
	QueueOverflow     = ISNULL (COUNT (CASE WHEN chatStatus = 10 THEN 1 ELSE NULL END), 0),
	TimeOverflow      = ISNULL (COUNT (CASE WHEN chatStatus = 11 THEN 1 ELSE NULL END), 0),

	ChattingAveTime   = ISNULL (CONVERT (INT, ROUND (AVG (CASE WHEN chatStatus = 4 THEN (tChatting + tWrapUp) * 1.0 ELSE NULL END), 0)), 0),
	QueueAveTime      = ISNULL (CONVERT (INT, ROUND (AVG (CASE WHEN onQueue    = 1 THEN  tQueue               * 1.0 ELSE NULL END), 0)), 0),
	QueueMaxTime      = ISNULL (                     MAX (CASE WHEN onQueue    = 1 THEN  tQueue                     ELSE NULL END)     , 0)

	FROM ccRIAChats
	WHERE requestDate >= @dateStart AND requestDate <= @dateEnd
	AND InboundId IN (SELECT cam_id FROM ccSupervisorCam WHERE user_id = @User_id AND tipo = 0)
	GROUP BY InboundId
END

IF @Option = 2 --chats  KOLOB
BEGIN
SELECT
	Attended = ISNULL(COUNT(CASE WHEN crc.chatStatus = 4 AND crc.firstMessageTime IS NOT NULL THEN 1 ELSE NULL END) ,0),
	InQueue   = ISNULL(COUNT(CASE WHEN crc.chatStatus = 8  THEN 1 ELSE NULL END) ,0),
	Abandoned   = ISNULL(COUNT(CASE WHEN crc.chatStatus = 9  THEN 1 ELSE NULL END) ,0),
	TotalOverflow = ISNULL(COUNT(CASE WHEN crc.chatStatus = 11 OR crc.chatStatus = 10 THEN 1 ELSE NULL END), 0 ),
	OverFlowByTimeOut = ISNULL(COUNT(CASE WHEN crc.chatStatus = 11 THEN 1 ELSE NULL END), 0 ),
	OverFlowBySize = ISNULL(COUNT(CASE WHEN crc.chatStatus = 10 THEN 1 ELSE NULL END), 0 )
	FROM ccRIAChats AS crc
	WHERE crc.inboundId = @inboundID AND (crc.requestDate between @dateStart AND @dateEnd)
	GROUP BY InboundId
END

SET NOCOUNT OFF'
EXEC(@sql)


	
SET @process = 'K043000-Dashboard Chat delete store procedure [ccsp_GalateaAdminCampaigns]'
SET @sql = 'IF EXISTS (SELECT * FROM sys.procedures where name= N''ccsp_GalateaAdminCampaigns'')
	BEGIN
		DROP PROCEDURE ccsp_GalateaAdminCampaigns
	END'
EXEC(@sql)

SET @process = 'K043000-Dashboard Chat  create store procedure [ccsp_GalateaAdminCampaigns]';
SET @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] 
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
	IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type
		BEGIN
			IF @CampType = 1 -- Campaigns Out
				BEGIN
					IF @WorkgroupId IS NOT NULL
						BEGIN
							SELECT CAST(IdCampEsp AS INT) AS Id
							FROM ccRIACampEspWG
							WHERE IDWG = @WorkgroupId
									AND Tipo = 1
									ORDER BY IdCampEsp ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe una lista de campañas de salida con el id de grupo de trabajo especificado'', 18, 1);
					END;
			END;
			IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @WorkgroupId IS NOT NULL
						BEGIN
							SELECT CAST(IdCampEsp AS INT) AS Id
							FROM ccRIACampEspWG
							WHERE IDWG = @WorkgroupId
									AND Tipo = 0
									ORDER BY IdCampEsp ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe una lista de campañas de entrada con el id de grupo de trabajo especificado'', 18, 1);
					END;
			END;
			RETURN 0;
	END;
	IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id
		BEGIN
			IF @CampType = 1 -- Campaigns Out
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
							CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name,
							isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
							camps.cam_procesando IsStarted, a.AreaName AS Area,  
							CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
							ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
							FROM ccCamps camps
							LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
							LEFT JOIN ccRIACat_Areas a ON a.IDArea = camps.IDArea
							LEFT JOIN ccCampsExtend extended ON camps.cam_id = extended.cam_id
							WHERE camps.cam_id = @Id
							ORDER BY camps.cam_descripcion ASC;
					END;
					ELSE
						BEGIN
							RAISERROR(''ERROR. No existe campañas de salida con el id especificado'', 18, 1);
					END;
			END;
			IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							SELECT DISTINCT 
													CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType, 0 as OutboundType
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
	IF @Option = 3   -- Update OverallTotalNew By Campaign
		BEGIN
			IF @Id IS NOT NULL
				BEGIN
					UPDATE ccCampsNvosCB
						SET 
							OverallTotalNew = ccCampsNvosCB.new
					WHERE id = @Id;
			END;
			ELSE
				BEGIN
					RAISERROR(''ERROR. No existe la campañas de entrada con el id especificado'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 4   -- Update Pin from Campaign per Admin
		BEGIN
			IF @Id IS NOT NULL
				AND @AdminId IS NOT NULL
				BEGIN
					IF @PinUpdate = 1
						BEGIN
							INSERT INTO PinedCampaigns(CampId, AdminId, Type)
						VALUES(@Id, @AdminId, @Type);
					END;
					IF @PinUpdate = 0
						BEGIN
							DELETE FROM PinedCampaigns
							WHERE CampId = @Id
									AND AdminId = @AdminId
									AND Type = @Type;
					END;
			END;
			ELSE
				BEGIN
					RAISERROR(''ERROR. La campañas o administrador no existen'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 5   -- Get Pin from Campaign Ids per Admin
		BEGIN
			IF @AdminId IS NOT NULL
				BEGIN
					SELECT CampId AS Id
					FROM PinedCampaigns
					WHERE AdminId = @AdminId
							AND Type = @Type
							ORDER BY Id ASC;
			END;
			ELSE
				BEGIN
					RAISERROR(''ERROR. El administrador con el id seleccionado no existe'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 6   -- Get Blacklist Ids by Campaign Id
		BEGIN
			IF @Id IS NOT NULL
				BEGIN
					DECLARE @BlackListIds VARCHAR(MAX);
					SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
					FROM Camplistanegra
					WHERE cam_id = @Id
							AND STATUS = 1;
					SELECT ISNULL(@BlackListIds, ''0'') AS BlackListIds;
			END;
			ELSE
				BEGIN
					RAISERROR(''ERROR. La campañas con el id seleccionado no existe'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 7   -- Get RegistryListIds Ids by Campaign Id
		BEGIN
			IF(@Id IS NOT NULL
				AND EXISTS
			(
				SELECT *
				FROM cccamps
				WHERE cam_id = @Id
			))
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
					RAISERROR(''ERROR. No existe una campaña con el id especificado'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @Option = 8   -- Delete RegistryListIds Ids by LoadId
		BEGIN
			IF(@LoadId IS NOT NULL
				AND EXISTS
			(
				SELECT *
				FROM ccRIARegistryLists
				WHERE list_id = @loadID
						AND STATUS <> 0
			))
				BEGIN
					UPDATE ccoCallsOutSource
						SET 
							cal_status = ''5''
					WHERE list_id = @loadID;
					DELETE FROM ccoWorkingTable
					WHERE list_id = @LoadId;
					EXEC ccsp_RIARegistryLists 
							@action = 6, 
							@list_id = @LoadId;
			END;
			ELSE
				BEGIN
					--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
					RAISERROR(''ERROR. No existe una carga el id especificado'', 18, 1);
			END;
			RETURN 0;
	END;
	IF @option = 9   -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
		BEGIN
			DECLARE @table TABLE
			(camId    INT, 
				campType TINYINT, 
				PRIMARY KEY(camId, campType)
			);
			INSERT INTO @table
					SELECT DISTINCT 
							IdCampEsp, Tipo
					FROM ccRIACampEspWG wg
					WHERE wg.IDWG IN
					(
						SELECT IDWG
						FROM ccRIAWorkGroupUsers
						WHERE IDWG <> @WorkgroupId
								AND User_id = @AdminId
					);
			SELECT CAST(B.IdCampEsp AS INT) AS Id, B.Tipo AS Type
			FROM @table A
					RIGHT JOIN
			(
				SELECT wg.IdCampEsp, wg.Tipo
				FROM ccRIACampEspWG wg
				WHERE wg.IDWG = @WorkgroupId
			) B ON A.camId = B.IdCampEsp
					AND A.campType = B.Tipo
			WHERE A.camId IS NULL
					ORDER BY IdCampEsp;
			RETURN 0;
	END;
	IF @option = 10  -- Get Agents States with totals per campaign by admin id and campaign type
	BEGIN
	DECLARE @date DATETIME= CONVERT(DATE, DATEADD(hh, -3, GETDATE()));
	DECLARE @AdminWorkgroups TABLE (id INT, PRIMARY KEY(id));
	DECLARE @AgentsList TABLE(id INT, PRIMARY KEY(id));
	DECLARE @tmpCamAgent TABLE(camId INT, userId INT, multimediaType TINYINT, PRIMARY KEY(camId, userId));
	DECLARE @AgentStatus TABLE(CampId SMALLINT, userId INT, CurrentState INT, isCampDialog BIT, campType BIT );
	DECLARE @CurrentStatus TABLE(userId INT, CurrentState INT, IdCampEsp INT, camType INT);
	DECLARE @campDataTotal TABLE(camId INT, CampName VARCHAR(500), Total INT, Area VARCHAR(100), PRIMARY KEY(camId));

	INSERT INTO @AdminWorkgroups SELECT DISTINCT IDWG
	FROM ccRIAWorkGroupUsers WG, 
		ccUsers_Roles R
	WHERE WG.User_id = @AdminId
	OR (R.User_id = @AdminId
	AND R.Rol_id = 7);
					        
	INSERT INTO @AgentsList SELECT DISTINCT A.User_id
	FROM ccRIAWorkGroupUsers A
	INNER JOIN @AdminWorkgroups B ON A.IDWG = B.id
	INNER JOIN ccUsers C ON A.User_id = C.User_id 
	AND C.TipoUser_id = 1
	ORDER BY A.User_id;

					INSERT INTO @tmpCamAgent SELECT DISTINCT campPerWg.IdCampEsp, wgUser.User_id,
	CASE WHEN @Id = 0 AND @CampType = 0 THEN inbound.chat ELSE NULL END
	FROM ccRIACampEspWG campPerWg
	INNER JOIN @AdminWorkgroups wg ON wg.Id = campPerWg.IDWG
	INNER JOIN ccRIAWorkGroupUsers wgUser ON wgUser.IDWG = wg.id
	INNER JOIN ccUsers C ON wgUser.User_id = C.User_id
	left JOIN ccInbound inbound ON inbound.Inbound_id = campPerWg.IdCampEsp and @CampType = 0
	left JOIN ccCamps camps ON camps.cam_id = campPerWg.IdCampEsp and @CampType = 1
	where C.TipoUser_id = 1
	AND campPerWg.Tipo = @CampType
	AND (@Id = 0 OR campPerWg.IdCampEsp = @Id);
					  
	;WITH lastState AS (
	SELECT A.user_id, MAX(A.fecha) AS fecha
	FROM ccLogAgentesDia A
	INNER JOIN @AgentsList B ON A.User_id = B.id
	WHERE fecha >= @date
	GROUP BY user_id)

	INSERT INTO @CurrentStatus 
	SELECT B.User_id,
	CASE WHEN B.currentStatus <= 0 THEN 0 ELSE B.currentStatus END AS currentStatus,
	B.IdCampEsp,
	B.Tipo
	FROM lastState A
	INNER JOIN ccLogAgentesDia B ON A.User_id = B.User_id
	AND A.fecha = B.fecha;

	IF @Id = 0 AND @CampType = 0 
	BEGIN
	DELETE FROM @tmpCamAgent WHERE multimediaType = 5
	END

	DECLARE @MultimediaType SMALLINT, @chatType SMALLINT;
	IF @CampType = 1 BEGIN
	SELECT @MultimediaType = meanContactTypeId FROM contactMeanOut WHERE camp_id = @Id
	END
	ELSE BEGIN
		SELECT @chatType = ci.chat FROM dbo.ccInbound AS ci WHERE ci.Inbound_id = @Id;
		SELECT @MultimediaType = meanContactTypeId FROM contactMeanIn WHERE inboundId = @Id
	END 

	IF(@chatType = 1)
	BEGIN
		SET @MultimediaType = 1
	END
			
	DECLARE @StateIds VARCHAR(100) =(SELECT CASE WHEN @MultimediaType = 5 THEN ''6,34'' WHEN @MultimediaType = 1 THEN ''23'' ELSE ''4,5,6,9'' END)-- Add more for multimediaTypes
			
	INSERT INTO @AgentStatus SELECT A.camId, A.userId, B.CurrentState,
	(CASE 
		WHEN @chatType = 1 THEN 
		CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'',''))  THEN @CampType 
		ELSE 
		CASE WHEN B.CurrentState IN(SELECT value FROM dbo.fn_RIASplitDelimited(@StateIds,'','')) AND B.IdCampEsp = A.camId AND B.camType = @CampType THEN @CampType 
		ELSE null 
		END END END) AS isCampDialog, B.camType
	FROM @tmpCamAgent A
	INNER JOIN @CurrentStatus B ON A.userId = B.userId
	WHERE (@Id = 0 or A.camId = @Id)

	IF @CampType = 1
	BEGIN
	;with  campDataTotal as(
		select camId,count(*) total from @tmpCamAgent A group by camId
	)

	insert into @campDataTotal
	select 
		A.camId,
		B.cam_descripcion as campName 
		,A.Total
		,C.AreaName as Area
		from campDataTotal A
		INNER JOIN ccCamps B ON A.camId= B.cam_id 
		INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
	END
	ELSE
	BEGIN    
	;with  campDataTotal as(
		select camId,count(*) total from @tmpCamAgent A group by camId
	)

	insert into @campDataTotal
	select 
		A.camId,
		B.descripcion as campName 
		,A.Total
		,C.AreaName as Area
		from campDataTotal A
		INNER JOIN ccInbound B ON A.camId = B.Inbound_id 
		INNER JOIN ccRIACat_Areas C ON C.IDArea = B.IDArea
	END

	;WITH stateCamp AS(
	SELECT A.CampId,
	count(CASE WHEN A.CurrentState = 3 THEN 1 ELSE NULL END) AS ready,
	count(CASE WHEN A.CurrentState NOT IN(-2, -1, 0, 3, 4, 5, 6, 9, 30, 34) THEN 1 
			WHEN A.CurrentState IN (6, 34, 4) AND (A.CampId != C.IdCampEsp OR A.campType != @CampType) THEN 1 ELSE NULL END) AS notReady,
	COUNT(isCampDialog) AS dialog, 
	COUNT(CASE WHEN a.CurrentState <= 0 THEN 1 ELSE NULL END) AS disconnected 
	FROM @AgentStatus A
	INNER JOIN @CurrentStatus C ON A.userId = C.userId
	GROUP BY A.CampId
	)

	SELECT 
	A.camId,
	A.campName,
	A.Total,
		ISNULL(B.ready, 0) AS Ready,
	ISNULL(B.notReady, 0 ) AS NotReady, 
	ISNULL(B.dialog, 0) AS Dialog,
	CASE WHEN B.disconnected IS NULL THEN A.Total ELSE A.Total - B.ready - B.dialog - B.notReady END Disconnected,
	A.Area
	FROM @campDataTotal A
	LEFT JOIN stateCamp B ON A.camId = B.CampId
	ORDER BY A.campName

		RETURN 0;
	END;
	IF @Option = 11  -- Get Campaigns Ids List Per Workgroup and Campaign Type
		BEGIN                
			IF Not EXISTS
			(
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
						AND Rol_id = 7
			)
				BEGIN
		print ''xxxx SIn Super''
					;WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS Id
							FROM ccRIACampEspWG A (NOLOCK)
								INNER JOIN wgId ON wgId.IDWG = A.IDWG
													AND A.Tipo = @CampType;
			END;
			ELSE
				BEGIN
		--print ''xxxx Super''
		IF @CampType = 1
		BEGIN
			SELECT DISTINCT 
				CAST(cam_id AS INT) AS Id
						FROM ccCamps (NOLOCK) where IDArea IS NOT NULL
		END
		ELSE
		BEGIN 
			SELECT DISTINCT 
				CAST(Inbound_id AS INT) AS Id
						FROM ccInbound (NOLOCK) where IDArea IS NOT NULL
		END
			END;
			RETURN 0;
	END;
	IF @Option = 12  -- Get All Campaigns complete information per Campaign Type and Campaign Id
		BEGIN
			IF @CampType = 1 -- Campaigns Out
				BEGIN
					SELECT DISTINCT 
					CAST(camps.cam_id AS INT) AS Id, camps.cam_descripcion AS Name, 
					isnull(CAST(graph.graphic_id AS INT),1) AS Frame, CAST(1 AS SMALLINT) AS Type,
					camps.cam_procesando IsStarted, a.AreaName AS Area,  
					CAST(CASE WHEN camps.progDial = 3 THEN 6 ELSE 0 END as [tinyint]) as InboundType, isnull(camps.CampType,0) as OutboundType,
					ISNULL(extended.zipCodeSchedule, 0) AS ZipCodeSchedule
					FROM ccCamps camps (NOLOCK)
					INNER JOIN ccRIACampsGraph graph (NOLOCK) ON camps.cam_id = graph.cam_id
					INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = camps.IDArea
					INNER JOIN ccCampsExtend extended (NOLOCK) ON camps.cam_id = extended.cam_id
					--WHERE camps.cam_id = @Id
					ORDER BY camps.cam_descripcion ASC;
			END;
			ELSE
				BEGIN
					SELECT DISTINCT 
											CAST(inb.Inbound_id AS INT) AS Id, inb.descripcion AS Name,isnull( CAST(graph.graphic_id AS INT),1) AS Frame, CAST(0 AS SMALLINT) AS Type, CAST(inb.STATUS AS BIT) IsStarted, a.AreaName AS Area, inb.chat AS InboundType, 0 as OutboundType
					FROM ccInbound inb (NOLOCK)
							INNER JOIN ccRIAInboundGraph graph (NOLOCK) ON inb.Inbound_id = graph.Inbound_id
							INNER JOIN ccRIACat_Areas a (NOLOCK) ON a.IDArea = inb.IDArea
							ORDER BY inb.descripcion ASC;
			END;
			RETURN 0;
	END;
	IF @Option = 13
	BEGIN
		BEGIN                
			IF NOT EXISTS
			(
				SELECT *
				FROM ccUsers_Roles NOLOCK
				WHERE User_id = @AdminId
						AND Rol_id = 7
			)
				BEGIN
					IF @CampType = 1
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,CAST(-1 AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 1
									INNER JOIN ccCamps ccc (NOLOCK) ON A.IdCampEsp = ccc.cam_id;
						END
					ELSE
						BEGIN
							WITH wgId
								AS (SELECT IDWG
									FROM ccRIAWorkGroupUsers NOLOCK
									WHERE user_id = @AdminId)
								SELECT DISTINCT 
									CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
								FROM ccRIACampEspWG A (NOLOCK)
									INNER JOIN wgId ON wgId.IDWG = A.IDWG
														AND A.Tipo = 0
									INNER JOIN ccInbound cci (NOLOCK) ON A.IdCampEsp = cci.Inbound_id 
									AND ((@multi_type is null AND cci.chat = @InboundType)
										OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))));
						END
			END;
			ELSE
				BEGIN
				IF @CampType = 1
					BEGIN
						SELECT DISTINCT 
								CAST(cam_id AS INT) AS CampId,cam_descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(-1 AS SMALLINT) AS CampaignType,-1 AS RelatedCampId
						FROM ccCamps NOLOCK where IDArea = @AreaId
					END
				ELSE
					BEGIN 
						SELECT DISTINCT 
								CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
						FROM ccInbound cci (NOLOCK) where IDArea = @AreaId
						AND ((@multi_type is null AND cci.chat = @InboundType)
							OR (@multi_type is not null AND cci.chat in (SELECT value from dbo.fn_RIASplitDelimited(@multi_type,'',''))))

					END
			END;
			RETURN 0;
		END;
	END;

	IF @Option = 14
		BEGIN
			IF NOT EXISTS
			(
					SELECT *
					FROM ccUsers_Roles NOLOCK
					WHERE User_id = @AdminId
							AND Rol_id = 7
			)
				BEGIN
					WITH wgId
							AS (SELECT IDWG
								FROM ccRIAWorkGroupUsers NOLOCK
								WHERE user_id = @AdminId)
							SELECT DISTINCT 
								CAST(IdCampEsp AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
							FROM ccRIACampEspWG A (NOLOCK)
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
	IF @Option = 15
		BEGIN
			SELECT DISTINCT 
			CAST(Inbound_id AS INT) AS CampId,descripcion AS Description,isnull(IDArea, -1) AS AreaID,CAST(chat AS SMALLINT) AS CampaignType,CAST(isnull(cam_id,-1) AS INT) AS RelatedCampId
			FROM ccInbound NOLOCK where cam_id = @Id
		END
END;'
EXEC(@sql)
        ----------------------------------------------------------------------------------------------------------------------------
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