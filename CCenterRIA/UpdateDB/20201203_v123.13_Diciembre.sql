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


        set @process = 'CW-4488 Alter SP - ccsp_RIA_ABCAgents'
        set @Sql= '
          ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
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
            return(0)
            end
          set nocount off
          '
        EXEC(@Sql)


        set @process = 'CW-4488 Alter SP - ccsp_RIA_ABCAgents'
        set @Sql= '
          ALTER PROCEDURE [dbo].[ccsp_RIAChecaLogin]
          @Login varchar(40),
          @Password varchar(40),
          @Computer varchar(20),
          @PasswordLwC varchar(40) = null
          AS
          declare @LoginOK tinyint, @PswdOK tinyint, @CompuOK tinyint, @ExtenOK tinyint, @TeclaOK tinyint, @XferAgents tinyint
          declare @Nombre varchar(60), @Extension varchar(15), @UserID smallint, @CCServer varchar(20)

          --Para posiciones ip, by ODC
          declare @ext_id int, @pos_id int, @isIP bit, @ipExtension varchar(15)

          -- Para live connected
          -- Tipo de conexion: 0 normal, 1 liveconnected
          declare @tipoConexion smallint

          SELECT @LoginOK=0, @PswdOK=0, @CompuOK=0, @ExtenOK=0, @TeclaOK=0, @XferAgents=0,
           @Extension='' '', @UserID='' '', @Nombre='' '', @tipoConexion = 0, @ipExtension='''', @isIP=0
          SELECT @CCServer=valor FROM ccSettings WHERE setting_id=7

          IF not exists(select Login from ccUsers Where Login=@Login and status>0 and tipoUser_id=1)
            GOTO Mostrar
          else
            set @LoginOK=1

          IF not exists(select Login from ccUsers Where Login = @Login
           AND (Password=@Password OR Password = dbo.md5(@password) OR dbo.md5(Password)=@Password
           or Password=@PasswordLwC OR Password = dbo.md5(@PasswordLwC) OR dbo.md5(Password)=@PasswordLwC)
           and status > 0 and tipoUser_id = 1)
            GOTO Mostrar
          else
            set @PswdOK=1

          -- Se actualiza a Lower Case
          update ccUsers with(rowlock) set Password=isnull(@PasswordLwC, Password) where Login=@Login and status>0 and tipoUser_id=1

          if not exists (select Computer from ccPosicion Where Status=1 and Computer=@Computer)
            insert ccposicion (computer, ext_id) select @Computer, 0

          set @CompuOK = 1

          if not exists(select Computer from ccPosicion P join ccMonitorExt M on P.ext_id= M.ext_id
           Where p.Status=1 and M.Status=1 and Computer=@Computer)
            GOTO Mostrar
          else
            set @ExtenOK=1

          select @Extension=Extension, @ext_id=p.ext_id, @pos_id=p.pos_id, @tipoConexion=p.tipoConexion, @isIP=isIP
          from ccPosicion P join  ccMonitorExt M on P.ext_id= M.ext_id
          Where Computer = @Computer

          select @TeclaOK=count(*) from ccTeclaExtensionPuerto T join ccMonitorExt M on T.ext_id=M.ext_id where M.Extension=@Extension

          select @UserID=user_id, @Nombre=Nombres + '' '' + isnull(ApellidoPaterno,'''') + '' '' +isnull(ApellidoMaterno,''''), @XferAgents=XferAgents
          from ccUsers Where Login = @Login AND TipoUser_id=1 AND status = 1

          Mostrar:
          --Para posiciones ip, by ODC
          -- No verifica ccTeclaExtensionPuerto, @TeclaOK =1
          -- Regresa un etension ''virtual''.  Debe ser diferente a cualquiera de ccMonitorExt.Extension
          IF @ext_id=0
           BEGIN
            select @TeclaOK =1, @Extension=cast(@pos_id * -1 as varchar(15))
           END

          ---Por OAYC IPExtension, extension, para cuando es posición IP con alguna extension asignada
          IF(@ext_id > 0  and @isIP=1)
           BEGIN
            select @TeclaOK =1, @ipExtension = @Extension, @Extension = cast( @pos_id * -1 as varchar(15))
           END
          -----------

          IF @tipoConexion = 1
            select @TeclaOK =1

          --  CRMx
          DECLARE @crmxActive TINYINT
          SET @crmxActive = 0
          IF (SELECT COUNT(setting_id) FROM ccsettings WHERE setting_id = 168) = 1
            BEGIN
              SELECT @crmxActive = valor FROM ccsettings WHERE setting_id = 168
            END


          declare @passSecure int
          select @passSecure= valor from ccSettings where setting_id=207


          SELECT @LoginOK as [LoginOK], @PswdOK as [PswdOK], @CompuOK as [CompuOK], @ExtenOK as [ExtenOK], @Extension as [Extension],
          @UserID as [UserID], @Nombre as [Nombre], @CCServer as [CCServer], @TeclaOK as TeclaOK, @tipoConexion as TipoConexion, @ipExtension as ipExtension,
          @XferAgents as XferAgents, @crmxActive as [CRMx], @passSecure as [passSecure]
          '
        EXEC(@Sql)


        set @process = 'CW-4488 Alter SP - ccsp_RIA_ABCAgents'
        set @Sql= '
          ALTER PROCEDURE [dbo].[ccsp_RIAADMChecaLogin]
          @Login varchar(40) = '''',
          @Password varchar(40) = '''',
          @PasswordLwC varchar(40) = null,
          @adminId int = 0

          as
          set nocount on

          declare @x int
          set @x=1

          if @adminId <> 0
          begin
          update ccUsers set onLine = 0 where User_id = @adminId
          return(0)
          end

          declare @UserID smallint
          --****
          declare @TipoUser_idx int
          declare @ver int
          declare @changeRecDisposition int
          set @ver = 0
          set @changeRecDisposition = 0

          --****
          select @UserID=User_id,@TipoUser_idx=TipoUser_id from ccUsers Where Login=@Login AND TipoUser_id in(2,6) and status>0

          if(@TipoUser_idx=2 or @TipoUser_idx=6)
          begin
          if exists (SELECT * FROM ccRIAUsr_AdminPermissions WHERE User_id=@UserID and per_id in (2,6))
          begin
          set @ver = 1
          end
          if exists (SELECT * FROM ccRIAUsr_AdminPermissions WHERE User_id=@UserID and per_id=7)
          begin
          set @changeRecDisposition = 1
          end
          end

          if not exists (select Login from ccUsers Where User_id=@UserID
          AND(Password=@Password OR Password = dbo.md5(@password) OR dbo.md5(Password)=@Password
          OR Password=@PasswordLwC OR Password = dbo.md5(@PasswordLwC) OR dbo.md5(Password)=@PasswordLwC))
          begin
          SELECT case when @UserID is null then 0 else 1 end ''LoginOK'', 0 ''PswdOK'', 0 ''UserID'', 0 ''Nombre'', 0 ''ADMServer'', 0 ''AreaId'', 0 ''viewavrs'',0 ''changeRecDisposition'', 0 ''LastPasswordchange''
          return(0)
          end

          update ccUsers set Password=isnull(@PasswordLwC, Password) Where User_id=@UserID and Password<>@PasswordLwC

          update ccUsers set onLine = 1 where User_id = @UserID

          Select 1 ''LoginOK'', 1 ''PswdOK'', User_id ''UserID'',
          Nombres +'' ''+ isnull(ApellidoPaterno,'''') +'' ''+isnull(ApellidoMaterno,'''') ''Nombre'',
          (SELECT valor FROM ccSettings WHERE setting_id=8) [ADMServer],
          isnull(IDArea,0) ''AreaId'',
          @ver  ''ViewAvrs'', @changeRecDisposition  ''changeRecDisposition'',
          CASE when DATEDIFF(DAY,LastPasswordChange ,GETDATE()) >30 THEN 1 ELSE 0 END ''LastPasswordchange''
          From ccUsers Where User_id=@UserID
          return(0)
          set nocount off
          '
        EXEC(@Sql)

        set @process = 'CW-4488 Alter Table - ccUsers'
        set @sql = '
          if exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = ''Login'' and TABLE_NAME = ''ccUsers'') begin
            ALTER TABLE ccUsers ALTER COLUMN Login VARCHAR (40) NOT NULL
          end
        '
        EXEC(@sql)

        set @process = 'CW-4488 Alter Table - ccUsers_Consulta'
        set @sql = '
          if exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = ''Login'' and TABLE_NAME = ''ccUsers_Consulta'') begin
            ALTER TABLE ccUsers_Consulta ALTER COLUMN Login VARCHAR (40) NOT NULL
          end
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
