/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2020/11/10
Description:

Database: CCenterRia
Required version: 123.12

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
SET @version = 123 --**********actualizar a 122 sin fix
SET @versionfix = 13
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


        set @process = 'CW-4505 Alter sp ccsp_RIAGetAveTimeEspec'
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
						ISNULL(@CC+@CCAb,0) as CC,
						ISNULL(@SL2,0) as SumSL
					end
				'
        EXEC(@sql)

        set @process = 'CW-4598 Alter sp ccsp_RIALoadCamps'
        set @sql = '
					ALTER PROCEDURE [dbo].[ccsp_RIALoadCamps] @option SMALLINT, @AreaId SMALLINT = NULL, @Sup SMALLINT = NULL, @WGID SMALLINT = NULL
						AS
						SET NOCOUNT ON

						DECLARE @loginDays INT

						SET @loginDays = 0

						IF @option = 1 -- Todas las campañas
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

						IF @option = 2 -- Campañas de un Area
						BEGIN
							SELECT DISTINCT a1.cam_id, cam_descripcion, frame, cam_procesando, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) relationsWG
							FROM ccCamps a1
							JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
							JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
							WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
							ORDER BY cam_descripcion

							RETURN (0)
						END

						IF @option = 3 -- Campañas por Supervisor
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

						IF @option = 5 -- Campañas por Supervisor
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

						IF @option = 8 -- Campañas de un Agente
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
						IF @option = 9 -- Campañas de un Area
						BEGIN
							(SELECT DISTINCT a1.cam_id as CamID, cam_descripcion as CamDescription, frame as Frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(a1.cam_id, 3) as RelationsWG,1 CamType, ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 1 and IdCampEsp = a1.cam_id and IDWG = @WGID group by IdCampEsp),0) IsAssignedToCurrentWG
							FROM ccCamps a1
							JOIN ccRIACampsGraph a2 ON a1.cam_id = a2.cam_id
							JOIN ccRIAGraphics a3 ON a2.graphic_id = a3.graphic_id
							WHERE a3.type_id = 1 AND isnull(IDArea, 0) = isnull(@AreaId, 0)
							UNION
							SELECT DISTINCT b1.inbound_id, descripcion, frame, isnull(IDArea, 0) IDArea, dbo.fn_CampEspWG(b1.inbound_id, 2) relationsWG, 0 CampType, ISNULL((select  count(IdCampEsp) from ccRIACampEspWG where tipo = 0 and IdCampEsp = b1.inbound_id and IDWG = @WGID group by IdCampEsp),0) isAssignedToCurrentWG--select * from ccRIACampEspWG
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
        EXEC(@sql)
    
        

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
