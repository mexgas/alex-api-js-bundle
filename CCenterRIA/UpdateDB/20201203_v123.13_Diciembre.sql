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

        set @process = 'se quita sp ccsp_GalateaUpdateUser si existe CW-4593-EOMC-Editar_Agentes_en_Admin_Kolob'
        set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUpdateUser'')
            begin
          DROP PROCEDURE ccsp_GalateaUpdateUser;
            end'
        EXEC(@sql)
    
        set @process = 'se agrega sp ccsp_GalateaUpdateUser CW-4593-EOMC-Editar_Agentes_en_Admin_Kolob'
        set @sql ='Create PROCEDURE ccsp_GalateaUpdateUser
@UserId int,
@Login varchar(40),
@Nombres varchar(45),
@LastName varchar(45),
@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
@Password varchar(200),
@Sexo bit,
@canChangeStatus bit
as

Declare @ApellidoMaterno varchar(45)
Declare @ApellidoPaterno varchar(45)
Declare @CurrentPass varchar(200)
--Obtiene el idioma de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

--se acondiciona los apellidos con el nombre opcional dependiendo del idioma
	if @lenguageXion= ''0'' or @lenguageXion= ''2'' --para español y portugues
		begin
			set @ApellidoPaterno = @LastName
			set @ApellidoMaterno = @NombreOpcionalExtra
		end
	else-- es idioma ingles
		begin
			set @ApellidoPaterno = @NombreOpcionalExtra 
			set @ApellidoMaterno = @LastName
		end

-- validaciones	
	if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
		begin
		select -5 as ResponseCode--,''el usuario no existe''
		return(0)
		end

--verificamos si la constrasena ha cambiado
	select @CurrentPass= Password from ccUsers where User_id=@UserId and Login=@Login

	if @Password <> '''' and @Password <> null and @Password <> @CurrentPass -- si la contraseña si cambio actualizamos en base el fecha de actualizacion de pass
		begin 
		Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId
		end

--update
	Update ccUsers set 
	Nombres=@Nombres,
	ApellidoPaterno=@ApellidoPaterno,
	ApellidoMaterno=@ApellidoMaterno,
	Password=case when @Password <> '''' then @Password else Password end,
	Sexo=@Sexo,
	canChangeStatus=@canChangeStatus
	where User_id=@UserId

select 200 as ResponseCode -- indica que se actualizo correctamente el usuario

'
        EXEC(@sql)


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
    
		set @process = 'CW-4599 modificar sp ccsp_GalateaAdminWorkgroups para validacion superusuario'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminWorkgroups] 
	@Option AS SMALLINT,
	@AdminId AS INT = 0,
	@WorkgroupId AS INT = 0,
	@idArea AS INT = NULL,
	@Descripcion AS varchar(40) = null
AS
declare @users as int
declare @camps as int

BEGIN
	IF @Option = 1
	BEGIN 
		if exists (select * from ccUsers_Roles where User_id = @AdminId and Rol_id = (select Rol_id from ccRoles where Level = 7))
		BEGIN
			select  CAST(wg.IDWG as int)  as Id, wg.WGName Name, wg.StatusWorkGroup Status
			from ccRIACat_WorkGroup wg
			where StatusWorkGroup = 1
		END

		ELSE
		BEGIN
			SELECT @AdminId = ISNULL(@AdminId, 0)			
		
			SELECT CAST(wg.IDWG AS INT) AS Id, WGName Name, StatusWorkGroup Status  FROM ccRIAWorkGroupUsers wgu
			JOIN  ccRIACat_WorkGroup wg ON wg.IDWG = wgu.IDWG
			WHERE User_id = @AdminId
		END			
	END
	IF @Option = 2
	BEGIN 
		SELECT @WorkgroupId = ISNULL(@WorkgroupId, 0)			
		
		SELECT CAST(wg.IDWG AS INT) AS Id,
				WGName Name,
				StatusWorkGroup Status  
		FROM 
		ccRIACat_WorkGroup wg 
		WHERE IDWG = @WorkgroupId
					
	END

	IF @Option = 3 --Lista de wg 
	BEGIN 
	
		SELECT cast(IDWG as int) Id, WGName as Name
		FROM ccRIACat_WorkGroup 
					
	END

	IF @Option = 4 --Lista de wg por area
	BEGIN 
		SELECT @idArea = ISNULL(@idArea, 0)	

		SELECT CAST(IDWG as int) IDWG 
		FROM 
		ccRIAAreaWorkGroup
		WHERE IDArea = @idArea
					
	END

	IF @Option = 5 --Delete WG
	BEGIN
		--revisar tablas con relacion de grupos de trabajo
		SELECT @WorkgroupId = ISNULL(@WorkgroupId, 0)
		if  @WorkgroupId = 0
		begin
			SELECT 0
			return (0)
		end

		SELECT @users=count(IdCampEsp) 
		FROM ccRIACampEspWG 
		where IDWG= @WorkgroupId

		SELECT @users=count(User_id) 
		FROM ccRIAWorkGroupUsers 
		where IDWG= @WorkgroupId

		if @users>0 or @camps >0 
		begin
			select -1
		end
		else
		begin
			Update ccRIACat_WorkGroup set StatusWorkGroup = 0 where IDWG =@WorkgroupId 
			select 1
		end
		

	END

	if @option = 6 -- Verifica si existe el grupo
		 begin
		  	select @WorkgroupId = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
			 then 1 else 0 end
		 
		 	if isnull(@IDArea,0)=0
			 begin
				select @WorkgroupId
				return(0)
			 end

		 	if @WorkgroupId=1
			 begin
			 set @WorkgroupId = -1
				select @WorkgroupId
				return(0)
			 end

			insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
			if @@rowcount = 1
				select @WorkgroupId = scope_identity()

			insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@WorkgroupId, @IDArea)
			select @WorkgroupId
			return(0)
		 end

END'
        EXEC(@sql)

		set @process = 'CW-4600 Permisos'
		set @sql = 'If exists(select * from ccPermissions 
where KeyJson in (''RolesPermissionAreasCU'',
''RolesPermissionAreasD'',
''RolesPermissionAreasChange'')
)
	BEGIN
		declare @id int 
		IF OBJECT_ID(''tempdb..#Permisos_id'') IS NOT NULL DROP TABLE #Permisos_id
		select Permissions_id 
		into #Permisos_id
		from ccPermissions 
		where KeyJson in (''RolesPermissionAreasCU'',
		''RolesPermissionAreasD'',
		''RolesPermissionAreasChange'',
		''RolesPermissionAreasManage'')

		IF OBJECT_ID(''tempdb..#Roles_id'') IS NOT NULL DROP TABLE #Roles_id
		SELECT Distinct(Rol_id)
		INTO #ROLES_ID
		FROM ccRoles_Permissions
		WHERE Permissions_id in (select * from #Permisos_id)

		Delete ccRoles_Permissions where Permissions_id in (select * from #Permisos_id)
		Delete ccPermissions where Permissions_id in (select * from #Permisos_id)
		If not exists(select * from ccPermissions where Permissions_id = 10008 )
			Begin
				INSERT INTO ccPermissions 
					(Permissions_Id,Description,KeyJson,Parent,Type,OrderGrl,Release,Active)
				VALUES 
					(10008,''Gestionar de areas'',''RolesPermissionAreasManage'',0,0,0,''N/A'',1)
				Insert into ccPermissions values (10009,''Menu grupos de trabajo'',''RolesPermissionWorkGroup'',0,0,0,''N/A'',1)
				Insert into ccPermissions values (10010,''Gestionar grupos de trabajo'',''RolesPermissionWGManagment'',0,0,0,''N/A'',1)

				insert into ccRoles_permissions values	(1,10009)
				insert into ccRoles_permissions	values (1,10010)

				Insert into ccRoles_Permissions 
				Select *,10008 from #Roles_id
		End
		ElSE
			BEGIN
				SET @id = (select TOP 1 Permissions_Id FROM ccPermissions ORDER BY Permissions_Id DESC)
				Insert into ccPermissions values (@id+1,''Gestionar de areas'',''RolesPermissionAreasManage'',0,0,0,''N/A'',1)

				Insert into ccPermissions values (@id+2,''Menu grupos de trabajo'',''RolesPermissionWorkGroup'',0,0,0,''N/A'',1)
				Insert into ccPermissions values (@id+3,''Gestionar grupos de trabajo'',''RolesPermissionWGManagment'',0,0,0,''N/A'',1)

				Insert into ccRoles_Permissions 
				Select *,SCOPE_IDENTITY() from #Roles_id
			END
end

If exists(select * from ccRoles_permissions where rol_id = 7)
Delete ccRoles_permissions where rol_id = 7'
		EXEC(@sql)

		set @process = 'CW-4574 Delete sp ccsp_GalateaAreas'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAreas'')
				    begin
						DROP PROCEDURE ccsp_GalateaAreas;
				    end'
		EXEC(@sql)


		set @process = 'CW-4574 Campañas en areas'
		set @sql = 'CREATE procedure [dbo].[ccsp_GalateaAreas] 
	@option int = 2,
	@IDArea smallint = 0,
	@Descripcion varchar(40) = NULL,
	@maxMails smallint = 3,
	@maxChats smallint = 3,
	@maxTweets smallint = 3,
	@defCampaing smallint = 0,
	@movesfromArea bit = 0,
	@userId int = NULL,
	@groupAreas varchar (MAX) = NULL
AS

SET NOCOUNT ON;
	
	declare @opt int = @option -1
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
			(	select IDArea, cam_id from ccCamps) as T
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
			maxTweets tinyint
		)
		insert into #Areas
		EXECUTE ccsp_RIA_ABCAreas @option = @opt, @IDArea=@IDArea,@Descripcion=@Descripcion,@maxMails=@maxMails,@maxChats=@maxChats,@maxTweets=@maxTweets,@defCampaing=@defCampaing
		select a.*,rca.CreateDate,Isnull(rca.defCampaing,0) as defCampaing
		from #Areas a
		inner join ccRIACat_Areas rca with(nolock) on a.IDArea = rca.IDArea
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
			@defCampaing=@defCampaing
		if (select result from #InsertAreas) = 1 and @movesfromArea = 1
			begin
				Update ccUsers set IDArea = (select idAreas from #InsertAreas), status = 1 where User_id = @userId
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

			select 1 as result
		END
	end
	if @option = 5 -- update Areas
	begin
		if(@Descripcion is null)
		begin
			Update ccRIACat_Areas set maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=@defCampaing where IDArea=@IDArea
		end
		else 
		if exists(Select AreaName from ccRIACat_Areas where StatusArea=1 and AreaName=@Descripcion)
			begin
				select -1 as result
				return
			end
		else
			begin
				update ccRIACat_Areas set AreaName= isnull(@Descripcion,AreaName),maxMails=isnull(@maxMails,maxMails),maxChats=isnull(@maxChats,maxChats),maxTweets=isnull(@maxTweets,maxTweets),defCampaing=@defCampaing where IDArea=@IDArea	
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
SET NOCOUNT ON;
'
		EXEC(@sql)

		set @process = 'CW-4601 Finder Admin Kolob'
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

end
else if @action = 12 begin--trae el nombre de la base de datos en BX
	select cast( WGCam.IdCampEsp as int) as [Value], cast(WGCam.Tipo as int) as callType, c.cam_descripcion as label
		from ccRIAWorkGroupUsers Wguser
		inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
		inner join ccCamps c on  WGCam.IdCampEsp=c.cam_id and WGCam.Tipo=1		
		where Wguser.User_id=@userId
	union
	select cast( WGCam.IdCampEsp as int) as [Value], cast(WGCam.Tipo as int) as callType, inb.descripcion as label
		from ccRIAWorkGroupUsers Wguser
		inner join ccRIACampEspWG WGCam on WGCam.IDWG=Wguser.IDWG
		inner join ccInbound inb on  WGCam.IdCampEsp=inb.Inbound_id and WGCam.Tipo=0
		where Wguser.User_id=@userId
end
else if @action = 13 begin--trae el nombre de la base de datos en BX
	;
	with WgId as(select IDWG from ccRIAWorkGroupUsers Wguser where Wguser.User_id=@userId)

	select distinct cast(Wguser.User_id as int) as [Value],ccUsers.Login as label from ccRIAWorkGroupUsers  Wguser
	inner join WgId on Wguser.IDWG=WgId.IDWG
	inner join ccUsers on ccUsers.User_id =Wguser.User_id and TipoUser_id=1
end'
		EXEC(@sql)
		 set @process = 'cw-4535 ALTER PROCEDURE ccsp_RIAChecaLogin '
    set @sql = '
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
--update ccUsers with(rowlock) set Password=isnull(@Password, Password) where Login=@Login and status>0 and tipoUser_id=1

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
    exec (@sql)

    set @process = 'CW-4604 Alter sp ccsp_GalateaAdminLogin'
	set @sql = '
	  ALTER PROCEDURE [dbo].[ccsp_GalateaAdminLogin] @Login       VARCHAR(40) = '''', 
	                                                 @Password    VARCHAR(40) = '''', 
	                                                 @PasswordLwC VARCHAR(40) = NULL, 
	                                                 @IPAddress   VARCHAR(20) = '''', 
	                                                 @adminId     INT         = 0
	  AS
	      BEGIN
	          SET NOCOUNT ON;
	          DECLARE @LoginOK BIT= 0, @PswdOK BIT= 0, @User_id SMALLINT, @Nombre VARCHAR(100), @ADMServer VARCHAR(300), @AreaId SMALLINT, @ViewAvrs INT, @changeRecDisposition INT, @PasswordExpired INT= 0, @UsernameMatch BIT= 1, @UserBlocked BIT= 0, @LastPasswordChange DATETIME, @Ext VARCHAR(80), @ViewAgents BIT= 0, @Theme smallint = 0;
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
	               @adminId;
	          SELECT @LoginOK = LoginOK, 
	                 @PswdOK = PswdOK, 
	                 @Nombre = Nombre, 
	                 @ADMServer = ADMServer, 
	                 @AreaId = AreaId, 
	                 @ViewAvrs = ViewAvrs, 
	                 @changeRecDisposition = changeRecDisposition, 
	                 @PasswordExpired = LastPasswordchange
	          FROM #temp;
	          IF @LoginOK = 1
	              BEGIN
	                  SELECT @User_id = User_id, 
	                         @ViewAgents = viewAgents,
	  					   @Theme = theme
	                  FROM ccUsers
	                  WHERE Login = @Login;
	                  DECLARE @LastLoginAttempt DATETIME, @LoginAttempts INT, @MaxAttemptsAllow INT, @TimeBloqued INT, @TimeFromLastAttempt INT;
	                  SELECT @LastLoginAttempt = LastLoginAttempt, 
	                         @LoginAttempts = LoginAttempts, 
	                         @LastPasswordChange = LastPasswordChange
	                  FROM ccUsers
	                  WHERE User_id = @User_id;
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
	                  IF @UserBlocked = 0
	                     AND (@UsernameMatch = 0
	                          OR @PswdOK = 0)
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
	                                                      AND @ExpirationTime > 0
	                                                 THEN 1
	                                                 ELSE 0
	                                             END)
	                  FROM ccUsers;
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
	          END;
	          SELECT @LoginOK UserExists, 
	                 @UserBlocked UserBlocked, 
	                 @UsernameMatch UsernameMatch, 
	                 @PswdOK PasswordMatch, 
	                 CAST(@PasswordExpired AS BIT) PasswordExpired, 
	                 @User_id UserID, 
	                 @Nombre Name, 
	                 @ADMServer ADMServer, 
	                 @AreaId AreaId, 
	                 @ViewAvrs ViewAvrs, 
	                 @changeRecDisposition ChangeRecDisposition, 
	                 @Ext Ext, 
	                 isnull(@ViewAgents,0) ViewAgents,
	  			   ISNULL(@WorkGroup, 0) WorkGroup,
	  			   ISNULL(@Theme, 0) Theme;
	      END;
	  '
	EXEC(@sql)


	 set @process = 'CW-4584 update CCmenus '
        set @sql = '
          update ccMenus set release = ''9e0dc47226f51e50c8da24c1bdf9c28b7791c2539e6df0ef6e1e73f3f035af387c2638cf61c14718f87c94241af6ea9b'' where menu_id = 2100;
        '
        EXEC(@sql)

	set @process = 'CW-4612 modificar sp ccsp_GalateaAdminWorkgroups para quitar validacion superusuario'
    set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminWorkgroups] 
			@Option AS SMALLINT,
			@AdminId AS INT = 0,
			@WorkgroupId AS INT = 0,
			@idArea AS INT = NULL,
			@Descripcion AS varchar(40) = null
		AS
		declare @users as int
		declare @camps as int

		BEGIN
			IF @Option = 1
			BEGIN 
				SELECT @AdminId = ISNULL(@AdminId, 0)			
		
				SELECT CAST(wg.IDWG AS INT) AS Id, WGName Name, StatusWorkGroup Status  FROM ccRIAWorkGroupUsers wgu
				JOIN  ccRIACat_WorkGroup wg ON wg.IDWG = wgu.IDWG
				WHERE User_id = @AdminId		
			END
			IF @Option = 2
			BEGIN 
				SELECT @WorkgroupId = ISNULL(@WorkgroupId, 0)			
		
				SELECT CAST(wg.IDWG AS INT) AS Id,
						WGName Name,
						StatusWorkGroup Status  
				FROM 
				ccRIACat_WorkGroup wg 
				WHERE IDWG = @WorkgroupId
					
			END

			IF @Option = 3 --Lista de wg 
			BEGIN 
	
				SELECT cast(IDWG as int) Id, WGName as Name
				FROM ccRIACat_WorkGroup 
					
			END

			IF @Option = 4 --Lista de wg por area
			BEGIN 
				SELECT @idArea = ISNULL(@idArea, 0)	

				SELECT CAST(IDWG as int) IDWG 
				FROM 
				ccRIAAreaWorkGroup
				WHERE IDArea = @idArea
					
			END

			IF @Option = 5 --Delete WG
			BEGIN
				--revisar tablas con relacion de grupos de trabajo
				SELECT @WorkgroupId = ISNULL(@WorkgroupId, 0)
				if  @WorkgroupId = 0
				begin
					SELECT 0
					return (0)
				end

				SELECT @users=count(IdCampEsp) 
				FROM ccRIACampEspWG 
				where IDWG= @WorkgroupId

				SELECT @users=count(User_id) 
				FROM ccRIAWorkGroupUsers 
				where IDWG= @WorkgroupId

				if @users>0 or @camps >0 
				begin
					select -1
				end
				else
				begin
					Update ccRIACat_WorkGroup set StatusWorkGroup = 0 where IDWG =@WorkgroupId 
					select 1
				end
		

			END

			if @option = 6 -- Verifica si existe el grupo
				 begin
		  			select @WorkgroupId = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
					 then 1 else 0 end
		 
		 			if isnull(@IDArea,0)=0
					 begin
						select @WorkgroupId
						return(0)
					 end

		 			if @WorkgroupId=1
					 begin
					 set @WorkgroupId = -1
						select @WorkgroupId
						return(0)
					 end

					insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
					if @@rowcount = 1
						select @WorkgroupId = scope_identity()

					insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@WorkgroupId, @IDArea)
					select @WorkgroupId
					return(0)
				 end

		END'
        EXEC(@sql)
		
		
        set @process = 'se quita sp ccsp_GalateaAdminWorkgroups si existe CW-4597'
        set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminWorkgroups'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminWorkgroups;
            end'
        EXEC(@sql)
    
        set @process = 'se agrega sp ccsp_GalateaAdminWorkgroups CW-4597'
        set @sql ='
CREATE PROCEDURE [dbo].[ccsp_GalateaAdminWorkgroups] 
	@Option AS SMALLINT,
	@AdminId AS INT = 0,
	@WorkgroupId AS INT = 0,
	@idArea AS INT = NULL,
	@Descripcion AS varchar(40) = null,
	@groupList as varchar (MAX) = NULL

AS
declare @users as int
declare @camps as int
declare @sql as varchar(max)

BEGIN
	IF @Option = 1
	BEGIN 
		SELECT @AdminId = ISNULL(@AdminId, 0)			
		
		SELECT CAST(wg.IDWG AS INT) AS Id, WGName Name, StatusWorkGroup Status  FROM ccRIAWorkGroupUsers wgu
		JOIN  ccRIACat_WorkGroup wg ON wg.IDWG = wgu.IDWG
		WHERE User_id = @AdminId
					
	END
	IF @Option = 2
	BEGIN 
		SELECT @WorkgroupId = ISNULL(@WorkgroupId, 0)			
		
		SELECT CAST(wg.IDWG AS INT) AS Id,
				WGName Name,
				StatusWorkGroup Status  
		FROM 
		ccRIACat_WorkGroup wg 
		WHERE IDWG = @WorkgroupId
					
	END

	IF @Option = 3 --Lista de wg 
	BEGIN 
	
		SELECT cast(IDWG as int) Id, WGName as Name
		FROM ccRIACat_WorkGroup
		WHERE StatusWorkGroup =1
					
	END

	IF @Option = 4 --Lista de wg por area
	BEGIN 
		SELECT @idArea = ISNULL(@idArea, 0)	

		SELECT CAST(IDWG as int) IDWG 
		FROM 
		ccRIAAreaWorkGroup
		WHERE IDArea = @idArea
					
	END

	IF @Option = 5 --Delete WG
	BEGIN
		--revisar tablas con relacion de grupos de trabajo
		IF OBJECT_ID(''tempdb..#WGDelete'') IS NOT NULL DROP TABLE #WGDelete;
		SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, '','')

		SELECT @camps=count(IdCampEsp) 
		FROM ccRIACampEspWG 
		where IDWG in  (select IDwg from #WGDelete)

		SELECT @users=count(User_id) 
		FROM ccRIAWorkGroupUsers 
		where IDWG in (select IDwg from #WGDelete)

		if @users>0 or @camps >0 
		begin
			select -1
		end
		else
		begin
			Delete from ccRIAAreaWorkGroup where IDWG in (select IDwg from #WGDelete)
			Update ccRIACat_WorkGroup set StatusWorkGroup = 0 where IDWG in (select IDwg from #WGDelete)
			select 1
		end
		

	END

	if @option = 6 -- Verifica si existe el grupo
		 begin
		  	select @WorkgroupId = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
			 then 1 else 0 end
		 
		 	if isnull(@IDArea,0)=0
			 begin
				select @WorkgroupId
				return(0)
			 end

		 	if @WorkgroupId=1
			 begin
			 set @WorkgroupId = -1
				select @WorkgroupId
				return(0)
			 end

			insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
			if @@rowcount = 1
				select @WorkgroupId = scope_identity()

			insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@WorkgroupId, @IDArea)
			select @WorkgroupId
			return(0)
		 end

END

'
        EXEC(@sql)

		set @process = 'CW-4588 eliminar sp ccsp_GalateacampaingManager'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateacampaingManager'')
				    begin
						DROP PROCEDURE ccsp_GalateacampaingManager;
				    end'
		EXEC(@sql)

		set @process = 'CW-4588 Crear sp ccsp_GalateacampaingManager'
		set @sql = '-- =============================================
-- Author:		UEspinosa
-- Create date: 26/11/20
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ccsp_GalateacampaingManager] 
--declare
@option           SMALLINT, 
@Activa           SMALLINT     = NULL, 
@Descripcion      VARCHAR(40) = '''', 
@IDArea           SMALLINT, 
@MirrorInbound_Id SMALLINT    = NULL, 
@frame            SMALLINT, 
@Prefijo          VARCHAR(40) = '''', 
@Type             SMALLINT, 
@userId           SMALLINT, 
@moduleId         SMALLINT    = 49
AS
    BEGIN
        IF(@option = 2)
            BEGIN
				IF EXISTS(select top 1 cam_id from ccCamps where cam_descripcion = @Descripcion)
				BEGIN
					Select -1
					return
				END
                IF OBJECT_ID(''tempdb..#Campaing'') IS NOT NULL DROP TABLE #Campaing
                CREATE TABLE #Campaing(IdCampaing INT)
                IF @type = 1
                    BEGIN
                        INSERT INTO #Campaing
                        EXEC ccsp_RIA_ABCCamps 
                             @option = @option, 
                             @Descripcion = @Descripcion, 
                             @Cam_id = ''0'', 
                             @Activa = 1, 
                             @IDArea = @IDArea, 
                             @frame = @frame, 
                             @Prefijo = @Prefijo
                END
                    ELSE
                    IF @type = 0
                        BEGIN
                            INSERT INTO #Campaing
                            EXEC ccsp_RIA_ABCACDGroups 
                                 @option = @option, 
                                 @Descripcion = @Descripcion, 
                                 @Inbound_id = ''0'', 
                                 @IDArea = @IDArea, 
                                 @frame = @frame, 
                                 @Prefijo = @Prefijo
                    END
                IF((SELECT TOP 1 IdCampaing FROM #Campaing ) > 0)
                    BEGIN
                        INSERT INTO ccRIALog
                        VALUES(
                        (SELECT AreaName FROM ccRIACat_Areas WHERE IDArea = @IDArea), 
                        GETDATE(),
                        CASE
                            WHEN @type = 1
                            THEN 25
                            ELSE 26
                        END, 
                        (SELECT Login FROM ccUsers WHERE User_Id = @userId), 
                        @moduleId, 
                        '''', 
                        @Descripcion
                        )
                END
				SELECT TOP 1 IdCampaing FROM #Campaing
				IF OBJECT_ID(''tempdb..#Campaing'') IS NOT NULL DROP TABLE #Campaing
        END
    END
'
		EXEC(@sql)

		set @process = 'CW-4588 eliminar sp ccsp_RIAUpdateCamConfig'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateCamConfig'')
				    begin
						DROP PROCEDURE ccsp_RIAUpdateCamConfig;
				    end'
		EXEC(@sql)

		set @process = 'CW-4588 crear sp ccsp_RIAUpdateCamConfig'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAUpdateCamConfig]
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
				@prefijo varchar(max) = null
				as
				set nocount on
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
				 prefijo = isnull(@prefijo, prefijo)
				Where cam_id = @cam_id

				if @cam_ShowCalifWnd = 1
				 begin
				 If not exists(select cam_id from ccCalifCamp where cam_id = @cam_id and tipo = 1)
				  begin
				  select 0
				  return(0)
				  end

				 UPDATE ccCamps SET cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd, cam_ShowCalifWnd)
				 where cam_id = @cam_id
				 select 1
				 return(0)
				  end

				--else
				UPDATE ccCamps SET
				cam_ShowCalifWnd = isnull(@cam_ShowCalifWnd,cam_ShowCalifWnd)
				where cam_id = @cam_id
				select 2
				return(0)
				set nocount off

        '
		EXEC(@sql)

		
		set @process = 'CW-4622 Se elimina si existe sp ccsp_GalateaAdminPortsManagement'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminPortsManagement'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminPortsManagement;
            end'
		exec (@sql)
		set @process = 'CW-4622 Se agrega sp ccsp_GalateaAdminPortsManagement'
		set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminPortsManagement]
			@action SMALLINT,
			@dialer_id INT = 0,
			@cam_id SMALLINT = 0
			AS
			SET NOCOUNT ON;
			DECLARE @transtate BIT
			IF @@TRANCOUNT = 0
			BEGIN
				SET @transtate = 1
			BEGIN TRANSACTION transtate
			END
			BEGIN TRY
				IF @action = 1 --return all ports
				BEGIN
					SELECT Dialers.dialer_id AS DialerId, Dialers.Descripcion AS PortDescription, Provedor.Descrip AS ProviderDescription, Dialers.Puerto
					FROM [CCenterRia].[dbo].[ccoDialers] AS Dialers INNER JOIN [CCenterRia].[dbo].[cstoProvedor] AS Provedor 
					ON Dialers.provedor_id = Provedor.provedor_id
				END;
				IF @action = 2 --return ports for camp
				BEGIN
					SELECT dialer_id AS DialerId, cam_id AS CampId FROM [CCenterRia].[dbo].[ccoDialerCamp] ORDER BY cam_id
				END;
				IF @action = 3 --insert port
				BEGIN
					IF NOT EXISTS (SELECT dialer_id, cam_id FROM [CCenterRia].[dbo].[ccoDialerCamp]
						WHERE dialer_id=@dialer_id AND cam_id=@cam_id)
					BEGIN
						INSERT INTO [CCenterRia].[dbo].[ccoDialerCamp](dialer_id, cam_id) VALUES (@dialer_id, @cam_id)
					END;
				END;
				IF @action = 4 --delete port
				BEGIN
					DELETE FROM [CCenterRia].[dbo].[ccoDialerCamp] WITH(ROWLOCK) WHERE cam_id = @cam_id AND dialer_id = @dialer_id
				END;
				IF @transtate = 1 AND XACT_STATE() = 1
				BEGIN
					COMMIT TRANSACTION transtate
				END;
			END TRY
			BEGIN CATCH
			DECLARE @error INT, @message VARCHAR(4000), @xstate INT;
			SELECT @error = ERROR_NUMBER(), @message = ERROR_MESSAGE(), @xstate = XACT_STATE();
			IF @xstate = -1
				ROLLBACK;
			IF @xstate = 1
				ROLLBACK
			IF @xstate = 1
				ROLLBACK TRANSACTION ccsp_GalateaAdminPortsManagement;
			RAISERROR (''ccsp_GalateaAdminPortsManagement: %d: %s'', 16, 1, @error, @message) ;
			END CATCH;'
	exec (@sql)

	set @process = 'CW-4622 Se insertan permisos en ccPermissions'
	set @sql = 'if not exists (select * from  [CCenterRia].[dbo].[ccPermissions] where Permissions_Id = 10011) 
		begin
			INSERT INTO [CCenterRia].[dbo].[ccPermissions]([Permissions_Id], [Description], [KeyJson], [Parent], [Type], [OrderGrl] ,[Release] ,[Active])
			VALUES	(10011,''Gestionar campañas'',''RolesPermissionCampManagment'',0,0,0,''N/A'',1), 
			(10012,''Gestionar asignacion de puertos'',''RolesPermissionPortsManagment'',0,0,0,''N/A'',1)
		end'
	exec(@sql)
	set @process = 'CW-4622 Se insertan permisos en super usuario'
	set @sql = ' if not exists ( select * from ccRoles_Permissions where Rol_Id = 1 and Permissions_Id = 10011)
				begin
					INSERT INTO [CCenterRia].[dbo].[ccRoles_Permissions]([Rol_Id], [Permissions_Id]) VALUES	(1,10011),(1,10012)
				end'
	exec(@sql)

	set @process = 'CW-4630 Se modifica sp ccsp_GalateaAdminWorkgroups para validación superusuario'
	set @sql = '
	
	ALTER PROCEDURE [dbo].[ccsp_GalateaAdminWorkgroups] 
	@Option AS SMALLINT,
	@AdminId AS INT = 0,
	@WorkgroupId AS INT = 0,
	@idArea AS INT = NULL,
	@Descripcion AS varchar(40) = null
AS
declare @users as int
declare @camps as int

BEGIN
	IF @Option = 1
	BEGIN 
		if exists (select * from ccUsers_Roles where User_id = @AdminId and Rol_id = (select Rol_id from ccRoles where Level = 7))
		BEGIN
			select  CAST(wg.IDWG as int)  as Id, wg.WGName Name, wg.StatusWorkGroup Status
			from ccRIACat_WorkGroup wg
			where StatusWorkGroup = 1
		END

		ELSE
		BEGIN
			SELECT @AdminId = ISNULL(@AdminId, 0)			
		
			SELECT CAST(wg.IDWG AS INT) AS Id, WGName Name, StatusWorkGroup Status  FROM ccRIAWorkGroupUsers wgu
			JOIN  ccRIACat_WorkGroup wg ON wg.IDWG = wgu.IDWG
			WHERE User_id = @AdminId
		END			
	END
	IF @Option = 2
	BEGIN 
		SELECT @WorkgroupId = ISNULL(@WorkgroupId, 0)			
		
		SELECT CAST(wg.IDWG AS INT) AS Id,
				WGName Name,
				StatusWorkGroup Status  
		FROM 
		ccRIACat_WorkGroup wg 
		WHERE IDWG = @WorkgroupId
					
	END

	IF @Option = 3 --Lista de wg 
	BEGIN 
	
		SELECT cast(IDWG as int) Id, WGName as Name
		FROM ccRIACat_WorkGroup 
					
	END

	IF @Option = 4 --Lista de wg por area
	BEGIN 
		SELECT @idArea = ISNULL(@idArea, 0)	

		SELECT CAST(IDWG as int) IDWG 
		FROM 
		ccRIAAreaWorkGroup
		WHERE IDArea = @idArea
					
	END

	IF @Option = 5 --Delete WG
	BEGIN
		--revisar tablas con relacion de grupos de trabajo
		SELECT @WorkgroupId = ISNULL(@WorkgroupId, 0)
		if  @WorkgroupId = 0
		begin
			SELECT 0
			return (0)
		end

		SELECT @users=count(IdCampEsp) 
		FROM ccRIACampEspWG 
		where IDWG= @WorkgroupId

		SELECT @users=count(User_id) 
		FROM ccRIAWorkGroupUsers 
		where IDWG= @WorkgroupId

		if @users>0 or @camps >0 
		begin
			select -1
		end
		else
		begin
			Update ccRIACat_WorkGroup set StatusWorkGroup = 0 where IDWG =@WorkgroupId 
			select 1
		end
		

	END

	if @option = 6 -- Verifica si existe el grupo
		 begin
		  	select @WorkgroupId = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
			 then 1 else 0 end
		 
		 	if isnull(@IDArea,0)=0
			 begin
				select @WorkgroupId
				return(0)
			 end

		 	if @WorkgroupId=1
			 begin
			 set @WorkgroupId = -1
				select @WorkgroupId
				return(0)
			 end

			insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
			if @@rowcount = 1
				select @WorkgroupId = scope_identity()

			insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@WorkgroupId, @IDArea)
			select @WorkgroupId
			return(0)
		 end

END
	'
	exec(@sql)

	set @process = 'CW-4630 Se modifica sp ccsp_GalateaAdminCampaigns para validación superusuario'
	set @sql = ' 
	
	ALTER PROCEDURE [dbo].[ccsp_GalateaAdminCampaigns] @Option AS SMALLINT, 
												   @CampType AS SMALLINT = 0, 
												   @WorkgroupId AS INT = 0, 
												   @Id AS INT = 0,
												   @AdminId AS SMALLINT = 0, 
												   @PinUpdate AS SMALLINT = 0, 
												   @LoadId AS INT = 0,
												   @Type AS SMALLINT = 0
		AS
		BEGIN
			set nocount on
			IF @Option = 1   -- Get Campaigns Ids List Per Workgroup and Campaign Type 
			BEGIN
				IF @CampType = 1 -- Campaigns Out 
				BEGIN
					IF @WorkgroupId IS NOT NULL
					BEGIN
						SELECT CAST(IdCampEsp AS INT) AS Id 
						FROM ccRIACampEspWG 
						WHERE IDWG = @WorkgroupId AND Tipo=1
						ORDER BY IdCampEsp ASC
					END
					ELSE
					BEGIN
						raiserror(''ERROR. No existe una lista de campa?as de salida con el id de grupo de trabajo especificado'', 18, 1)
					END	
				END
				IF @CampType = 0 -- Campaigns In (ACD)
				BEGIN
					IF @WorkgroupId IS NOT NULL
					BEGIN
						SELECT CAST(IdCampEsp AS INT) AS Id 
						FROM ccRIACampEspWG 
						WHERE IDWG = @WorkgroupId AND Tipo=0
						ORDER BY IdCampEsp ASC
					END
					ELSE
					BEGIN
						raiserror(''ERROR. No existe una lista de campa?as de entrada con el id de grupo de trabajo especificado'', 18, 1)
					END	
				END
			END
			
			IF @Option = 2   -- Get Campaign complete information per Campaign Type and Campaign Id 
				BEGIN
					IF @CampType = 1 -- Campaigns Out 
						BEGIN
							IF @Id IS NOT NULL
								BEGIN
									SELECT DISTINCT 
										camps.cam_id AS Id, 
										camps.cam_descripcion AS Name, 
										CAST(graph.graphic_id AS INT) AS Frame, 
										1 AS Type,
										camps.cam_procesando IsStarted
									FROM ccCamps camps 
									LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
									WHERE camps.cam_id = @Id 
									ORDER BY camps.cam_descripcion ASC;
								END
							ELSE
							BEGIN
								raiserror(''ERROR. No existe campa?as de salida con el id especificado'', 18, 1)
							END	
						END
					IF @CampType = 0 -- Campaigns In (ACD)
						BEGIN
							IF @Id IS NOT NULL
								BEGIN
									SELECT DISTINCT 
										inb.Inbound_id AS Id, 
										inb.descripcion AS Name, 
										CAST(graph.graphic_id AS INT) AS Frame,
										0 Pin, 
										0 AS Type,
										CAST(0 AS BIT) IsStarted
									FROM ccInbound inb
									LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
									WHERE inb.Inbound_id = @Id 
									ORDER BY inb.descripcion ASC;
								END
							ELSE
								BEGIN
									raiserror(''ERROR. No existe campa?as de entrada con el id especificado'', 18, 1)
								END	
						END
				END

			IF @Option = 3   -- Update OverallTotalNew By Campaign 
				BEGIN
					IF @Id IS NOT NULL
						BEGIN
							UPDATE ccCampsNvosCB SET OverallTotalNew = ccCampsNvosCB.new WHERE id = @Id
						END
					ELSE
						BEGIN
							raiserror(''ERROR. No existe la campa?as de entrada con el id especificado'', 18, 1)
						END	
				END

			IF @Option = 4	 -- Update Pin from Campaign per Admin
				BEGIN
					IF @Id IS NOT NULL AND @AdminId IS NOT NULL
						BEGIN
							IF @PinUpdate = 1
								BEGIN
									INSERT INTO PinedCampaigns (CampId, AdminId, Type)
										   VALUES (@Id, @AdminId, @Type);
								END;
							IF @PinUpdate = 0
								BEGIN
									DELETE FROM PinedCampaigns
									WHERE CampId = @Id AND AdminId = @AdminId AND Type = @Type;
								END;
						END
					ELSE
						BEGIN
							raiserror(''ERROR. La campa?as o administrador no existen'', 18, 1)
						END	
				END
			
			IF @Option = 5	 -- Get Pin from Campaign Ids per Admin
				BEGIN
					IF @AdminId IS NOT NULL
						BEGIN
							SELECT CampId AS Id FROM PinedCampaigns WHERE AdminId = @AdminId AND Type = @Type
							ORDER BY Id ASC
						END
					ELSE
						BEGIN
							raiserror(''ERROR. El administrador con el id seleccionado no existe'', 18, 1)
						END	
				END

			IF @Option = 6	 -- Get Blacklist Ids by Campaign Id
			BEGIN
				IF @Id IS NOT NULL
					BEGIN
			            DECLARE @BlackListIds VARCHAR(MAX);
			            SELECT @BlackListIds = COALESCE(@BlackListIds + ''|'' + CAST(idtipolista AS VARCHAR(MAX)), CAST(idtipolista AS VARCHAR(MAX)))
			            FROM Camplistanegra
			            WHERE cam_id = @Id AND STATUS = 1;
			            SELECT isnull(@BlackListIds,''0'') AS BlackListIds;
					END
				ELSE
					BEGIN
						raiserror(''ERROR. La campa?as con el id seleccionado no existe'', 18, 1)
					END	
			END

			IF @Option = 7	 -- Get RegistryListIds Ids by Campaign Id
			BEGIN
				IF (@Id IS NOT NULL AND EXISTS(SELECT * FROM cccamps WHERE cam_id = @Id))
					BEGIN
						SELECT TOP 1 list_id FROM ccRIARegistryLists WHERE cam_id = @Id AND status = 2 ORDER BY list_id DESC
					END
				ELSE
					BEGIN
						--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
						raiserror(''ERROR. No existe una campa?a con el id especificado'', 18, 1)			
					END	
			END

			IF @Option = 8	 -- Delete RegistryListIds Ids by LoadId
			BEGIN
				IF (@LoadId IS NOT NULL AND EXISTS(SELECT * FROM ccRIARegistryLists WHERE list_id = @loadID and status <> 0))
					BEGIN
						UPDATE ccoCallsOutSource SET cal_status = ''5'' WHERE list_id = @loadID
						DELETE FROM ccoWorkingTable WHERE list_id = @LoadId 
						exec ccsp_RIARegistryLists @action=6, @list_id = @LoadId 
					END
				ELSE
					BEGIN
						--Si el id de carga es nulo o no se encuentra registro de dicha carga o esta ya ha sido borrada
						raiserror(''ERROR. No existe una carga el id especificado'', 18, 1)
					END		
			END

			 IF @option = 9 -- Get Campaigns by Supervisor, Wg and type when admin eliminated from wg
		         BEGIN
		             DECLARE @table TABLE
		             (camId    INT, 
		              campType TINYINT,
		              PRIMARY KEY(camId, campType)
		             );
		             INSERT INTO @table
		                    SELECT DISTINCT 
		                           IdCampEsp, 
		                           Tipo
		                    FROM ccRIACampEspWG wg
		                    WHERE wg.IDWG IN
		                    (
		                        SELECT IDWG
		                        FROM ccRIAWorkGroupUsers
		                        WHERE IDWG <> @WorkgroupId
		                        AND User_id = @AdminId
		                    );
		             SELECT CAST(B.IdCampEsp AS INT) AS Id, 
		                    B.Tipo AS Type
		             FROM @table A
		                  RIGHT JOIN
		             (
		                 SELECT wg.IdCampEsp, 
		                        wg.Tipo
		                 FROM ccRIACampEspWG wg
		                 WHERE wg.IDWG = @WorkgroupId
		             ) B ON A.camId = B.IdCampEsp
		                    AND A.campType = B.Tipo
		             WHERE A.camId IS NULL
		             ORDER BY IdCampEsp;
		     END;
		END

	'
	exec(@sql)

	set @process = 'CW-4630 Se modifica sp ccsp_GalateaAdminWorkgroups para eliminacion de grupos de trabajo'
set @sql = '
ALTER PROCEDURE [dbo].[ccsp_GalateaAdminWorkgroups] 
	@Option AS SMALLINT,
	@AdminId AS INT = 0,
	@WorkgroupId AS INT = 0,
	@idArea AS INT = NULL,
	@Descripcion AS varchar(40) = null,
	@groupList as varchar (MAX) = NULL

AS
declare @users as int
declare @camps as int
declare @sql as varchar(max)

BEGIN
	IF @Option = 1
	BEGIN 
		if exists (select * from ccUsers_Roles where User_id = @AdminId and Rol_id = (select Rol_id from ccRoles where Level = 7))
		BEGIN
			select  CAST(wg.IDWG as int)  as Id, wg.WGName Name, wg.StatusWorkGroup Status
			from ccRIACat_WorkGroup wg
			where StatusWorkGroup = 1
		END

		ELSE
		BEGIN
			SELECT @AdminId = ISNULL(@AdminId, 0)			
		
			SELECT CAST(wg.IDWG AS INT) AS Id, WGName Name, StatusWorkGroup Status  FROM ccRIAWorkGroupUsers wgu
			JOIN  ccRIACat_WorkGroup wg ON wg.IDWG = wgu.IDWG
			WHERE User_id = @AdminId
		END		
					
	END
	IF @Option = 2
	BEGIN 
		SELECT @WorkgroupId = ISNULL(@WorkgroupId, 0)			
		
		SELECT CAST(wg.IDWG AS INT) AS Id,
				WGName Name,
				StatusWorkGroup Status  
		FROM 
		ccRIACat_WorkGroup wg 
		WHERE IDWG = @WorkgroupId
					
	END

	IF @Option = 3 --Lista de wg 
	BEGIN 
	
		SELECT cast(IDWG as int) Id, WGName as Name
		FROM ccRIACat_WorkGroup
		WHERE StatusWorkGroup =1
					
	END

	IF @Option = 4 --Lista de wg por area
	BEGIN 
		SELECT @idArea = ISNULL(@idArea, 0)	

		SELECT CAST(IDWG as int) IDWG 
		FROM 
		ccRIAAreaWorkGroup
		WHERE IDArea = @idArea
					
	END

	IF @Option = 5 --Delete WG
	BEGIN
		--revisar tablas con relacion de grupos de trabajo
		IF OBJECT_ID(''tempdb..#WGDelete'') IS NOT NULL DROP TABLE #WGDelete;
		SELECT value As IDwg into #WGDelete FROM fn_RIASplitDelimited(@groupList, '','')

		SELECT @camps=count(IdCampEsp) 
		FROM ccRIACampEspWG 
		where IDWG in  (select IDwg from #WGDelete)

		SELECT @users=count(User_id) 
		FROM ccRIAWorkGroupUsers 
		where IDWG in (select IDwg from #WGDelete)

		if @users>0 or @camps >0 
		begin
			select -1
		end
		else
		begin
			Delete from ccRIAAreaWorkGroup where IDWG in (select IDwg from #WGDelete)
			Update ccRIACat_WorkGroup set StatusWorkGroup = 0 where IDWG in (select IDwg from #WGDelete)
			select 1
		end
		

	END

	if @option = 6 -- Verifica si existe el grupo
		 begin
		  	select @WorkgroupId = case when exists(select WGName from ccRIACat_WorkGroup where StatusWorkGroup=1 and WGName=@Descripcion)
			 then 1 else 0 end
		 
		 	if isnull(@IDArea,0)=0
			 begin
				select @WorkgroupId
				return(0)
			 end

		 	if @WorkgroupId=1
			 begin
			 set @WorkgroupId = -1
				select @WorkgroupId
				return(0)
			 end

			insert into ccRIACat_WorkGroup (WGName) values (@Descripcion)
			if @@rowcount = 1
				select @WorkgroupId = scope_identity()

			insert into ccRIAAreaWorkGroup (IDWG, IDArea) values (@WorkgroupId, @IDArea)
			select @WorkgroupId
			return(0)
		 end

END'

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
