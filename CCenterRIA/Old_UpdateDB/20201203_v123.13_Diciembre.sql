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

  set @process = 'Se modifica el sp ccsp_GalateaLoadUsersForManagement para la carga de usuario en Admin Kolob CW-4632'
  set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaLoadUsersForManagement]
 @option SMALLINT,
 @AreaId SMALLINT,
 @UserType INT,
 @Username VARCHAR(200)=null
as

--Obtiene el idioma de de Centerware
Declare @lenguageXion varchar
select @lenguageXion= valor from ccsettings where setting_id=27 --  0 para español, 1 para ingles, 2 para portugues

IF @option = 1 --Agentes/supervisores de un Area  
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE isnull(IDArea, 0) = isnull(@AreaId, 0) AND TipoUser_id & 2 = CASE @UserType WHEN 1 THEN 0 ELSE 2 END AND STATUS = 1
  ORDER BY LOGIN, Nombres, ApellidoPaterno,Sexo, User_id

  RETURN (0)
END

IF @option = 2 -- obtiene Agente o supervisor en base a su nombre de usuario
BEGIN
  SELECT  TipoUser_id as UserType,
  User_id as UserId,
  LOGIN as Username,
  Nombres as Names,
  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoMaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoPaterno, '''')
  END as LastName,

  CASE 
    WHEN @lenguageXion=''1'' THEN isnull(ApellidoPaterno, '''')-- El sistema esta en ingles
    ELSE isnull(ApellidoMaterno, '''')
  END as OptionalExtraName,

  Password as Password,
  Sexo as IsMan,
  CanChangeStatus as EnableNotReady,
  isnull(IDArea, 0) as AreaId
  FROM ccusers
  WHERE Login=@Username

  RETURN (0)
END'
        EXEC(@sql)

		set @process = 'CW-4634-PinedCampaign_RemoveContraints y CW-4550-Pin_de_campañas create table'
		set @sql = 'if not exists (select * from sys.tables where name = N''PinedCampaigns'')
	    begin
	        CREATE TABLE PinedCampaigns (CampId INT, AdminId INT, Type SMALLINT)
	    end'
		EXEC(@sql)

		set @process = 'CW-4634-PinedCampaign_RemoveContraints y CW-4550-Pin_de_campañas remove contraints'
		set @sql = 'declare @name nvarchar(max),@sql2 nvarchar(max)
		SELECT 
		   @name =   A.CONSTRAINT_NAME
		FROM 
		   INFORMATION_SCHEMA.TABLE_CONSTRAINTS A, 
		   INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE B
		WHERE 
		      CONSTRAINT_TYPE = ''PRIMARY KEY'' 
		   AND A.CONSTRAINT_NAME = B.CONSTRAINT_NAME
		   and A.TABLE_NAME=''PinedCampaigns''
		ORDER BY 
		   A.TABLE_NAME  

		 if @name is not null begin
		set @sql2=''ALTER TABLE PinedCampaigns DROP CONSTRAINT ''+@name
		    exec (@sql2) 
		 end'
		EXEC(@sql)

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

        set @process = 'modifica sp ccsp_GalateaUpdateUser CW-4593-EOMC-Editar_Agentes_en_Admin_Kolob sin contraseña'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateUser]
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
	--select @CurrentPass= Password from ccUsers where User_id=@UserId and Login=@Login

	--if @Password <> '''' and @Password <> null and @Password <> @CurrentPass -- si la contraseña si cambio actualizamos en base el fecha de actualizacion de pass
	--	begin 
	--	Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId
	--	end

--update
	Update ccUsers set 
	Nombres=@Nombres,
	ApellidoPaterno=@ApellidoPaterno,
	ApellidoMaterno=@ApellidoMaterno,
	--Password=case when @Password <> '''' then @Password else Password end,
	Sexo=@Sexo,
	canChangeStatus=@canChangeStatus
	where User_id=@UserId

select 200 as ResponseCode -- indica que se actualizo correctamente el usuario

'
        EXEC(@sql)

        set @process = 'CW-4505 y CW-4634  Delete sp ccsp_RIAGetAveTimeEspec'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAGetAveTimeEspec'')
				    begin
						DROP PROCEDURE ccsp_RIAGetAveTimeEspec;
				    end'
		EXEC(@sql)

        set @process = 'CW-4505 Alter sp ccsp_RIAGetAveTimeEspec y CW-4634 Obtener el nivel de servicio de la base'
        set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAGetAveTimeEspec]
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
		end'
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
	set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminLogin] @Login       VARCHAR(40) = '''', 
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

				DECLARE @Roles Varchar(MAX);
				SELECT @Roles = STUFF(
								(SELECT '', '' + CAST(ur.Rol_id AS varchar)
								FROM ccUsers_Roles ur
								WHERE User_id = @User_id
								FOR XML PATH ('''')),
							1,2,'''')
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
			   ISNULL(@Theme, 0) Theme,
			   ISNULL(@Roles,0) Roles
    END';
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

	set @process = 'CW-4601 CW-4643 Finder Admin Kolob'
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

set @process = 'CW-4643 DROP PROCEDURE [dbo].[ccspGalatea_Finder'
set @sql = 'if exists (select * from sys.procedures where name = N''ccspGalatea_Finder'')
    begin
        DROP PROCEDURE ccspGalatea_Finder;
    end'
EXEC(@sql)

set @process = 'CW-4643 CREATE PROCEDURE [dbo].[ccspGalatea_Finder'
set @sql = 'CREATE PROCEDURE [dbo].[ccspGalatea_Finder]
@action int,
@userId int = 0
AS
if @action = 1 begin--trae el nombre de la base de datos en BX
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
else if @action = 2 begin--trae el nombre de la base de datos en BX
	;
	with WgId as(select IDWG from ccRIAWorkGroupUsers Wguser where Wguser.User_id=@userId)

	select distinct cast(Wguser.User_id as int) as [Value],ccUsers.Login as label from ccRIAWorkGroupUsers  Wguser
	inner join WgId on Wguser.IDWG=WgId.IDWG
	inner join ccUsers on ccUsers.User_id =Wguser.User_id and TipoUser_id=1
end'
EXEC(@sql)

set @process = 'CW-4623 Eliminar sp ccsp_GalateacampaingManager'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateacampaingManager'')
				    begin
						DROP PROCEDURE ccsp_GalateacampaingManager;
				    end'
		EXEC(@sql)

		set @process = 'CW-4623 Creacion del sp ccsp_GalateacampaingManager'
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
                                 @descripcion = @Descripcion, 
                                 @inbound_id = ''0'', 
                                 @idarea = @IDArea, 
                                 @frame = @frame, 
                                 @Prefijo = @Prefijo,
								 @userid = @userId
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

		set @process = 'CW-4623 Eliminar sp ccsp_GalateaRIALog'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaRIALog'')
				    begin
						DROP PROCEDURE ccsp_GalateaRIALog;
				    end'
		EXEC(@sql)

		set @process = 'CW-4623 creacion del sp ccsp_GalateaRIALog'
		set @sql = '-- =============================================
-- Author: UEspinosa
-- Create date: 16/12/2020
-- Description:	Sabe to ccRIALog
-- =============================================
CREATE PROCEDURE ccsp_GalateaRIALog
@userId           SMALLINT,
@OperationType    VARCHAR(MAX)= '''',
@Value			  VARCHAR(40) = '''',
@Module			  SMALLINT,
@target			  VARCHAR(40) = ''''
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID(''tempdb..#OperationType'') IS NOT NULL DROP TABLE #OperationType
	create table #OperationType(
			id smallint IDENTITY(1,1),
			operationType varchar(MAX)
	)
	insert into #OperationType SELECT value FROM fn_RIASplitDelimited(@OperationType, '','')	

	IF OBJECT_ID(''tempdb..#Value'') IS NOT NULL DROP TABLE #Value
	create table #Value(
			id smallint IDENTITY(1,1),
			value varchar(MAX)
	)
	insert into #Value SELECT value FROM fn_RIASplitDelimited(@Value, ''^^'')
	
	IF OBJECT_ID(''tempdb..#Params'') IS NOT NULL DROP TABLE #Params
	select operationType,value 
	into #Params
	from #OperationType o
	inner join #Value v with(nolock) on o.id = v.id


	IF OBJECT_ID(''tempdb..#PreLog'') IS NOT NULL DROP TABLE #PreLog
	create table #PreLog(
			areaName varchar(40),
			operatioDate DATETIME,
			login varchar(40),
			module_id smallint,
			target varchar(40)
	)
	insert into #PreLog
	select AreaName, GETDATE() as operatioDate,u.login,@Module module_id,@target as target
	from ccUsers U
	INNER JOIN ccRIACat_Areas A with(nolock) on u.IDArea = a.IDArea
	where U.User_id = @userId

	Insert into ccRIALog
	select areaName,operatioDate,operationType,login,module_id,value,target
	from #PreLog,#Params

	IF OBJECT_ID(''tempdb..#OperationType'') IS NOT NULL DROP TABLE #OperationType
	IF OBJECT_ID(''tempdb..#Value'') IS NOT NULL DROP TABLE #Value
	IF OBJECT_ID(''tempdb..#Params'') IS NOT NULL DROP TABLE #Params
	IF OBJECT_ID(''tempdb..#PreLog'') IS NOT NULL DROP TABLE #PreLog
	Select 1
	return
END
'
		EXEC(@sql)

		set @process = 'CW-4623 Modificacion de la funcion split para recibir mas de 2 valores como parametro para hecer el split'
		set @sql = 'ALTER FUNCTION [dbo].[fn_RIASplitDelimited]
( 
  @List nvarchar(MAX),
  @SplitOn varchar(3)
)
RETURNS @RtnValue table (
  Id int identity(1,1),
  Value nvarchar(255)
)
AS
BEGIN
  While (Charindex(@SplitOn,@List)>0)
  Begin 
    Insert Into @RtnValue (value)
    Select 
      Value = ltrim(rtrim(Substring(@List,1,Charindex(@SplitOn,@List)-1))) 
    Set @List = Substring(@List,Charindex(@SplitOn,@List)+len(@SplitOn),len(@List))
  End 
  
  Insert Into @RtnValue (Value)
    Select Value = ltrim(rtrim(@List))

    Return
END'
		EXEC(@sql)
		
		
set @process = 'CW-4603 DROP PROCEDURE [dbo].[ccsp_GalateaLoadWorkGroup]'
set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaLoadWorkGroup'')
    begin
        DROP PROCEDURE ccsp_GalateaLoadWorkGroup;
    end'
EXEC(@sql)

set @process = 'CW-4603 CREATE PROCEDURE [dbo].ccsp_GalateaLoadWorkGroup'
set @sql = '
CREATE PROCEDURE [dbo].[ccsp_GalateaLoadWorkGroup]
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

end'
EXEC(@sql)

set @process = 'CW-4657 Se modifica stored ccsp_GalateaAdminCampaigns para agregar nombre de area por campaña
				CW-4611 Modificaciones para Status y Pin de campañas de entrada'
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
										CAST(1 AS SMALLINT) AS Type,
										camps.cam_procesando IsStarted,
										a.AreaName as Area
									FROM ccCamps camps 
									LEFT JOIN ccRIACampsGraph graph ON camps.cam_id = graph.cam_id
									left join ccRIACat_Areas a on a.IDArea = camps.IDArea
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
										CAST(0 AS SMALLINT) AS Type,
										CAST(inb.Status AS BIT) IsStarted,
										a.AreaName as Area
									FROM ccInbound inb
									LEFT JOIN ccRIAInboundGraph graph ON inb.Inbound_id = graph.Inbound_id
									left join ccRIACat_Areas a on a.IDArea = inb.IDArea
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
EXEC(@sql)

		set @process = 'CW-4628-Obtener_las_calificaciones_y_subcalificaciones_de_la_base-ccsp_RIAADMGetCalifDay cambios de nombre'
		set @sql = '
		ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDay]
		@type smallint = null,
		@inbound_id smallint = null,
		@calif_id smallint = null,
		@cam_id smallint = null
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
		else if @type = 2 begin
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
		    else if @typeACD = 1 begin --Chat
		    select @typeACD as tipo, inboundId as Cam_id,[description] as Calificacion,
				  isnull(ctcs.califSubDesc,@nIdiomaSub) as subCalificacion, count(ctcs.califSubDesc) as totales
				  from ccriachats a
				  left join ccTipoCalif b on a.disposition=b.calif_id
				  left join ccTipoCalifSub ctcs on a.subDisposition= ctcs.califSub_id
				  where a.chatDate > @today and
				  a.inboundId=@inbound_id and a.chatStatus=4 and  a.disposition=@calif_id
				  group by inboundId, [description],ctcs.califSubDesc
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
		    select 0 as Type,co.cam_id as CampId,
		    case when co.statuscall_id = 13
		    then case when description is not null
		    then description else @nIdioma end
		    else
		    case when sll.descripcion is not null
		    then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma
		    end
		    end as Calification,
		    isnull(cso.califSubDesc,@nIdiomaSub) as SubCalificationName ,count(cso.califSub_id) Quantity
		    from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
		    left join ccTipoCalifOut ca on co.calif_id = ca.calif_id
		    left join ccTipoCalifSubOUT cso on co.califSub_id = cso.califSub_id 
		    left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
		    left join ccCamps ci on ci.cam_id = co.cam_id
		    where co.cal_inicio > @today
		    and co.cam_id = @inbound_id
		    and co.calif_id = @calif_id
		    group by  co.cam_id, co.statuscall_id,description,descripcion,cso.califSubDesc
		end


		drop table #CalifTemp
		set nocount off'
		EXEC(@sql)

		set @process = 'CW-4628-Obtener_las_calificaciones_y_subcalificaciones_de_la_base-ccsp_RIAADMGetCalifDayForced cambios de nombre'
		set @sql = '
		ALTER Procedure [dbo].[ccsp_RIAADMGetCalifDayForced]
		@type smallint,
		@cam_id smallint,
		@calif_id smallint = null
		AS 
		set nocount on
		create table #CalifTemp (id int identity,
		tipo integer, 
		Cam_id varchar(50), 
		Calificacion varchar(50), 
		subCalificacion varchar(50) null,
		calif_id smallint null,
		Total int ) 

		declare @today datetime
		set @today = convert(datetime, convert (varchar(11), getdate(), 101))
		--set @today =convert(datetime, convert (varchar(11), ''2015-10-01 17:50:20.470'', 101))

		-- Seleccion de idioma -- 
		declare @nIdioma varchar(22),@nIdiomaSub varchar(22)
		select @nIdioma = case valor when 0 then ''Sin calificación Otros'' else ''No disposition Others'' end
		from ccsettings where setting_id = 27 -- 0esp

		select @nIdiomaSub = case valor when 0 then ''Sin Subcalificación'' else ''No Subdisposition'' end
		from ccsettings where setting_id = 27 -- 0 esp

		if @type=0 
		insert into #CalifTemp 
		select 0 as tipo,co.cam_id as cam_id, case when co.statuscall_id = 13
				then case when description is not null 
							then description 
							else @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
							end
		else case when sll.descripcion is not null then ''cw:'' + sll.descripcion else ''cw:'' + @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
		end end as Calificacion,
		case when count(co.califSub_id) > 0 then 1 else 0 end as Subcalificacion,co.calif_id as calif_id,count(*) cantidad
		from ccoCallsOut co with(nolock, index(IX_ccoCallsOut_2))
		left join ccTipoCalifOut ca on co.calif_id = ca.calif_id 
		left join ccTipoCalifSubOUT tcsout on co.califSub_id = tcsout.califSub_id
		left join ccstatusllamada sll on sll.statuscall_id = co.statuscall_id
		left join ccCamps ci on ci.cam_id = co.cam_id 
		where co.cal_inicio > @today
		and co.cam_id = @cam_id
		group by  co.cam_id, co.statuscall_id,description,descripcion,co.calif_id



		if @type=1 
		insert into #CalifTemp 
		select 1 as tipo,cci.inbound_id as cam_id, case when description is not null then description 
		else @nIdioma-- substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
		end as Calificacion,count(ci.califSub_id) as subCalificacion,ci.calif_id,count(*)  as total
		from ccCallsIn ci with(nolock, index(IX_ccCallsIn)) 
		left join ccTipoCalif ca on ci.calif_id = ca.calif_id 
		left join ccInbound cci on cci.inbound_id = ci.inbound_id 
		where ci.cal_inicio > @today
		and ci.inbound_id = @cam_id
		and statuscall_id = 13 
		group by description, cci.inbound_id,ci.califSub_id,ci.calif_id



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
		select tipo as Type, cast(cam_id as varchar) as CampId, calificacion as Calification, cast(subCalificacion as varchar) as SubCalificationQuantity, cast(calif_id as smallint) as CalificationId, sum( total ) as Total from (
			select 1 as tipo, inboundId as Cam_id, case when description is not null then description 
			 else @nIdioma --substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
			 end as Calificacion,0 as subCalificacion ,0 as calif_id,count(disposition) as Total--,0 as iTotal4Campaign
			from ccriachats a left join ccTipoCalif b 
			on a.disposition=b.calif_id 
			where a.chatDate > @today
			and a.inboundId = @cam_id
			group by inboundId, Description
			
			union all
			
			
			select tipo,Cam_id,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
			then calificacion 
			else @nIdioma --substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
			end as Calificacion,
			case when count(subCalificacion) > 0 then 1 else 0 end subCalificacion,calif_id,sum(Total) as Total  --iTotal4Campaign -- para ver total por campaña
			from #CalifTemp 
			group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
			then calificacion 
			else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
			end, Cam_id,calif_id, iTotal4Campaign
		)  as a group by tipo, cam_id, calificacion,subCalificacion,calif_id order by tipo,cam_id 
		if @type=0 

		select tipo as Type,Cam_id as CampId,case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
		then calificacion 
		else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
		end as Calification,subCalificacion as SubCalificationQuantity, calif_id as CalificationId,sum(Total) as Total -- , iTotal4Campaign -- para ver total por campaña
		from #CalifTemp 
		group by tipo, case when total > iTotal4Campaign / 100 or calificacion = @nIdioma--substring(@nIdioma, 1, charindex(''@'', @nIdioma)-1) 
		then calificacion 
		else @nIdioma--substring(@nIdioma, charindex(''@'', @nIdioma)+1, len(@nIdioma)) 
		end, Cam_id,subCalificacion, calif_id, iTotal4Campaign



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


set @process = 'CW-4636 Reorder roles ids';
set @sql = 'if (((select TOP 1 Rol_id from ccRoles where keyjson = ''translate_superusuario'' ORDER BY Rol_id DESC) <> 7) OR (NOT EXISTS(select Rol_id from ccRoles where keyjson = ''translate_superusuario'')))
				BEGIN
	                Declare @Description varchar(50) = ''It Manager'',
					@Id int = 3,
					@Translate varchar(50) = ''translate_it_manager''

					IF OBJECT_ID(''tempdb..#Perm'') IS NOT NULL DROP TABLE #Perm;
					select Permissions_id
					into #Perm
					from ccRoles_Permissions cp
					inner join ccRoles c on c.Rol_id = cp.Rol_Id
					where c.Description = @Description

					IF OBJECT_ID(''tempdb..#User'') IS NOT NULL DROP TABLE #User;
					Select ur.User_id
					into #User
					from ccUsers_Roles ur
					inner join ccRoles r on r.Rol_id = ur.Rol_id
					where r.Description = @Description

					Declare @Rol_id int = (select Top 1 Rol_id from ccRoles where Description = @Description)

					Delete ccUsers_Roles where Rol_id = @Rol_id
					Delete ccRoles_Permissions where Rol_id = @Rol_id
					Delete ccRoles where KeyJson = @Translate

					SET IDENTITY_INSERT ccRoles ON
					INSERT INTO ccRoles 
						(Rol_id, Description, KeyJson,CreateDate,Active,Level)
					VALUES 
						(@Id, @Description, @Translate,GETDATE(),1,@Id)
					SET IDENTITY_INSERT ccRoles OFF

					insert into ccRoles_Permissions 
					select @Id,* from #Perm
					insert into ccUsers_Roles
					select *,@Id from #User


	                Declare @Description1 varchar(50) = ''Manager'',
					@Id1 int = 4,
					@Translate1 varchar(50) = ''translate_manager''

					IF OBJECT_ID(''tempdb..#Perm1'') IS NOT NULL DROP TABLE #Perm1;
					select Permissions_id
					into #Perm1
					from ccRoles_Permissions cp
					inner join ccRoles c on c.Rol_id = cp.Rol_Id
					where c.Description = @Description1

					IF OBJECT_ID(''tempdb..#User1'') IS NOT NULL DROP TABLE #User1;
					Select ur.User_id
					into #User1
					from ccUsers_Roles ur
					inner join ccRoles r on r.Rol_id = ur.Rol_id
					where r.Description = @Description1

					Declare @Rol_id1 int = (select Top 1 Rol_id from ccRoles where Description = @Description1)

					Delete ccUsers_Roles where Rol_id = @Rol_id1
					Delete ccRoles_Permissions where Rol_id = @Rol_id1
					Delete ccRoles where KeyJson = @Translate1

					SET IDENTITY_INSERT ccRoles ON
					INSERT INTO ccRoles 
						(Rol_id, Description, KeyJson,CreateDate,Active,Level)
					VALUES 
						(@Id1, @Description1, @Translate1,GETDATE(),1,@Id1)
					SET IDENTITY_INSERT ccRoles OFF

					insert into ccRoles_Permissions 
					select @Id1,* from #Perm1
					insert into ccUsers_Roles
					select *,@Id1 from #User1

	                Declare @Description2 varchar(50) = ''Room Manager'',
					@Id2 int = 5,
					@Translate2 varchar(50) = ''translate_Room_Manager''

					IF OBJECT_ID(''tempdb..#Perm2'') IS NOT NULL DROP TABLE #Perm2;
					select Permissions_id
					into #Perm2
					from ccRoles_Permissions cp
					inner join ccRoles c on c.Rol_id = cp.Rol_Id
					where c.Description = @Description2

					IF OBJECT_ID(''tempdb..#User2'') IS NOT NULL DROP TABLE #User2;
					Select ur.User_id
					into #User2
					from ccUsers_Roles ur
					inner join ccRoles r on r.Rol_id = ur.Rol_id
					where r.Description = @Description2

					Declare @Rol_id2 int = (select Top 1 Rol_id from ccRoles where Description = @Description2)

					Delete ccUsers_Roles where Rol_id = @Rol_id2
					Delete ccRoles_Permissions where Rol_id = @Rol_id2
					Delete ccRoles where KeyJson = @Translate2

					SET IDENTITY_INSERT ccRoles ON
					INSERT INTO ccRoles 
						(Rol_id, Description, KeyJson,CreateDate,Active,Level)
					VALUES 
						(@Id2, @Description2, @Translate2,GETDATE(),1,@Id2)
					SET IDENTITY_INSERT ccRoles OFF

					insert into ccRoles_Permissions 
					select @Id2,* from #Perm2
					insert into ccUsers_Roles
					select *,@Id2 from #User2

	                Declare @Description3 varchar(50) = ''Supervisor'',
					@Id3 int = 6,
					@Translate3 varchar(50) = ''translate_supervisor''

					IF OBJECT_ID(''tempdb..#Perm3'') IS NOT NULL DROP TABLE #Perm3;
					select Permissions_id
					into #Perm3
					from ccRoles_Permissions cp
					inner join ccRoles c on c.Rol_id = cp.Rol_Id
					where c.Description = @Description3

					IF OBJECT_ID(''tempdb..#User3'') IS NOT NULL DROP TABLE #User3;
					Select ur.User_id
					into #User3
					from ccUsers_Roles ur
					inner join ccRoles r on r.Rol_id = ur.Rol_id
					where r.Description = @Description3

					Declare @Rol_id3 int = (select Top 1 Rol_id from ccRoles where Description = @Description3)

					Delete ccUsers_Roles where Rol_id = @Rol_id3
					Delete ccRoles_Permissions where Rol_id = @Rol_id3
					Delete ccRoles where KeyJson = @Translate3

					SET IDENTITY_INSERT ccRoles ON
					INSERT INTO ccRoles 
						(Rol_id, Description, KeyJson,CreateDate,Active,Level)
					VALUES 
						(@Id3, @Description3, @Translate3,GETDATE(),1,@Id3)
					SET IDENTITY_INSERT ccRoles OFF

					insert into ccRoles_Permissions 
					select @Id3,* from #Perm3
					insert into ccUsers_Roles
					select *,@Id3 from #User3

	                Declare @Description4 varchar(50) = ''Superusuario'',
					@Id4 int = 7,
					@Translate4 varchar(50) = ''translate_superusuario''

					IF OBJECT_ID(''tempdb..#Perm4'') IS NOT NULL DROP TABLE #Perm4;
					select Permissions_id
					into #Perm4
					from ccRoles_Permissions cp
					inner join ccRoles c on c.Rol_id = cp.Rol_Id
					where c.Description = @Description4

					IF OBJECT_ID(''tempdb..#User4'') IS NOT NULL DROP TABLE #User4;
					Select ur.User_id
					into #User4
					from ccUsers_Roles ur
					inner join ccRoles r on r.Rol_id = ur.Rol_id
					where r.Description = @Description4

					Declare @Rol_id4 int = (select Top 1 Rol_id from ccRoles where Description = @Description4)

					Delete ccUsers_Roles where Rol_id = @Rol_id4 or rol_id = 7
					Delete ccRoles_Permissions where Rol_id = @Rol_id4 or Rol_id = 7
					if exists(select * from ccRoles where Rol_id = 7)
					begin
						Delete ccRoles where Rol_id = 7	
					end
					Delete ccRoles where KeyJson = @Translate4

					SET IDENTITY_INSERT ccRoles ON
					INSERT INTO ccRoles 
						(Rol_id, Description, KeyJson,CreateDate,Active,Level)
					VALUES 
						(@Id4, @Description4, @Translate4,GETDATE(),1,@Id4)
					SET IDENTITY_INSERT ccRoles OFF

					insert into ccRoles_Permissions 
					select @Id4,* from #Perm4
					insert into ccUsers_Roles
					select *,@Id4 from #User4


	                declare @elid int 
	                set @elid = (select TOP 1 Rol_id FROM ccRoles ORDER BY Rol_id DESC)
	                DBCC CHECKIDENT (ccRoles, RESEED, @elid)
				END';
EXEC(@sql);


set @process = 'CW-4692 DROP PROCEDURE [dbo].[ccsp_GalateaManageWG]'
set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaManageWG'')
    begin
        DROP PROCEDURE ccsp_GalateaManageWG;
    end'
EXEC(@sql)

set @process = 'CW-4692 CREATE PROCEDURE [dbo].ccsp_GalateaManageWG'
set @sql = '
create  PROCedure [dbo].[ccsp_GalateaManageWG]
@option smallint,
@IDWG smallint,
@Type smallint,
@usersList varchar(max)
as
set nocount on
declare @count int
declare @id int
declare @user int
declare @Assigned  varchar(max)

set @id = 1
set @Assigned = ''''


IF OBJECT_ID(''tempdb..#UsersList'') IS NOT NULL DROP TABLE #UsersList;

select ROW_NUMBER() OVER(ORDER BY value ASC) AS Row,
	value As user_id
	into #UsersList
	FROM fn_RIASplitDelimited(@usersList, '','')

select @count = count(user_id) from #UsersList

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
							select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
							--insert skill media
							exec ccsp_Skills @action= 5,@userId=@user

							insert into cccampsAgente (user_id, cam_id, prioridad, skill, IDWG)
							select @user, idCampEsp, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
							from ccRIACampEspWG where tipo = 1 and IDWG = @IDWG and
							 idCampEsp not in (select cam_id from cccampsAgente where user_id=@user and IDWG=@IDWG)

							insert into ccInboundAgentes(User_id, Inbound_id, cli_id, prioridad, skill, IDWG)
							select @user, idCampEsp, 0, dbo.fn_Calcula_UsrPriority(@user,0), 1, @IDWG
							from ccRIACampEspWG where tipo = 0 and IDWG = @IDWG and
							idCampEsp not in (select inbound_id from ccInboundAgentes where user_id=@user and IDWG=@IDWG)

							if not exists(select * from ccRIAWorkGroupUsersConsulta where IDWG=@IDWG and User_id=@user) begin
								insert into ccRIAWorkGroupUsersConsulta(IDWG, User_id) values(@IDWG,@user)
							end
						end
				 end
				 else if @Type in(2, 6)
				 begin
					-- -Supervisor	@Type in (2,6)
					insert into ccRIAWorkGroupUsers(IDWG, User_id) values (@IDWG, @user)
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
				select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
	 			insert into ccCampsAgenteBackUp(user_id,cam_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.cam_id,A.prioridad,A.skill,A.rel_id,A.IDWG 	from ccCampsAgente A left join ccCampsAgenteBackUp B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
				insert into ccInboundAgentesBackup(user_id,Inbound_id,cli_id,prioridad,skill,rel_id,IDWG) select A.user_id,A.Inbound_id,A.cli_id,A.prioridad,A.skill,A.rel_id,A.IDWG from ccInboundAgentes A left join ccInboundAgentesBackup B on A.user_Id=B.user_id and A.Inbound_id=B.Inbound_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG

	 			delete from cccampsagente where user_id=@user and IDWG=@IDWG
				delete from ccInboundagentes where user_id=@user and IDWG=@IDWG
				
			 end
			 else if @Type in(2, 6) -- Supervisor
			 begin
				select @Assigned = @Assigned+ cast(@user as varchar(5))+'',''
				insert into ccSupervisorCamBackup(user_id,cam_id,tipo,IDWG,monitored) select A.user_id,A.cam_id,A.tipo,A.IDWG,A.monitored from ccSupervisorCam A left join ccSupervisorCam B on A.user_Id=B.user_id and A.cam_id=B.cam_id where B.User_id is null and A.user_id=@user and A.IDWG=@IDWG
				delete ccSupervisorCam where user_id=@user and IDWG=@IDWG
				
			end
		end
		set @id = @id+1
	end
end
if LEN(@Assigned) > 0
		select SUBSTRING(@Assigned,0,Len(@Assigned))
	else
		select @Assigned

return(0)
set nocount off'
EXEC(@sql)

set @process = 'CW-4663 DROP PROCEDURE ccsp_GalateaUpdatePassword'
set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaUpdatePassword'')
    begin
        DROP PROCEDURE ccsp_GalateaUpdatePassword;
    end'
EXEC(@sql)

set @process = 'CW-4663 CREATE PROCEDURE ccsp_GalateaUpdatePassword'
set @sql = 'CREATE PROCEDURE ccsp_GalateaUpdatePassword
@UserId int,
@Login varchar(200),
@Password varchar(200)
as

-- validaciones	
	if not exists(select Login from ccUsers where Login=@Login and User_id=@UserId)
		begin
			select -5 as ResponseCode--el usuario no existe
			return(0)
		end

	if  @Password <> '''' 
		begin 
			Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId	and Login=@Login
			select 200 as ResponseCode -- indica que se actualizo correctamente el usuario
		end
	else
		begin 
			select -6 as ResponseCode -- la nueva contraseña es vacia
		end'
EXEC(@sql)

		SET @process = 'CW-4645 Reordenar los menus de reportes'
		SET @sql = '
delete from ccmenus where menu_id=1000 and type=3
update ccmenus set parent=3130,Nivel=''A'' where type=3 and menu_id=3130 and parent=3000
update ccmenus set Nivel=''B'' where type=3 and parent=3130 and Nivel=''C'' 
update ccmenus set ordengral=3 where type=3 and menu_id =4000
update ccmenus set ordengral=4 where type=3 and menu_id =3130
update ccmenus set ordengral=5 where type=3 and menu_id =10000
update ccmenus set ordengral=6 where type=3 and menu_id =11000

update ccmenus set ordengral=7 where type=3 and menu_id =6000
update ccmenus set ordengral=8 where type=3 and menu_id =8000
update ccmenus set ordengral=9 where type=3 and menu_id =8050
update ccmenus set ordengral=10 where type=3 and menu_id =7000
update ccmenus set ordengral=11 where type=3 and menu_id =9000

update ccmenus set ordengral=3 where type=3 and parent=4000
update ccmenus set ordengral=4 where type=3 and parent=3130
update ccmenus set ordengral=5 where type=3 and parent=10000
update ccmenus set ordengral=6 where type=3 and parent=11000

update ccmenus set ordengral=7 where type=3 and parent=6000

update ccmenus set ordengral=9 where type=3 and parent=8050
update ccmenus set ordengral=9 where type=3 and parent=8060
update ccmenus set ordengral=9 where type=3 and parent=8080

update ccmenus set ordengral=10 where type=3 and parent=7000

update ccmenus set ordengral=11 where type=3 and parent=9000

'
		EXEC(@sql)

        set @process = 'se modifica sp ccsp_GalateaUpdateUser CW-4689-EOMC'
        set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaUpdateUser]
@UserId int,
@Login varchar(40),
@Nombres varchar(45),
@LastName varchar(45),
@NombreOpcionalExtra varchar(45),-- para español es el ap materno, para ingles es un segundo nombre y para portugues es el nombre del padre ya que en portugal  va primero el nombre de la madre
@Sexo bit,
@canChangeStatus bit
as

Declare @ApellidoMaterno varchar(45)
Declare @ApellidoPaterno varchar(45)
Declare @userIdOnDb int
Declare @LoginOnDb varchar(40)
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

--update
	Update ccUsers set 
	Nombres=@Nombres,
	ApellidoPaterno=@ApellidoPaterno,
	ApellidoMaterno=@ApellidoMaterno,
	Sexo=@Sexo,
	canChangeStatus=@canChangeStatus
	where User_id=@UserId

select 200 as ResponseCode -- indica que se actualizo correctamente el usuario

'
        EXEC(@sql)








set @process = 'Se agrega setting para asignacion/des de agentes camps acds'
set @sql = 'ALTER PROCEDURE [dbo].[ccsp_GalateaAdminSettings]
AS
BEGIN
	CREATE TABLE #Settings (setting_id tinyint , valor varchar(300), ip_host tinyint)

	INSERT INTO #Settings 
	EXEC  ccsp_RIAADMLoadSettings @ip_admin =''''

	INSERT INTO #Settings (setting_id,valor) 
	SELECT setting_id, valor 
	FROM ccSettings
	WHERE setting_id in(160, 199, 53, 63, 64)
 
	SELECT distinct setting_id, valor from #Settings ORDER BY setting_id 

	DROP TABLE #Settings;
END
'
EXEC(@sql)

		set @process = 'CW-4732 Eliminar sp ccsp_RIAUpdateEspecConfig'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAUpdateEspecConfig'')
				    begin
						DROP PROCEDURE ccsp_RIAUpdateEspecConfig;
				    end'
		EXEC(@sql)

		set @process = 'CW-4732 Creacion del sp ccsp_RIAUpdateEspecConfig'
		set @sql = '
CREATE PROCEDURE [dbo].[ccsp_RIAUpdateEspecConfig] @inbound_id              SMALLINT, 
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
                                                  @addDataCallBackReminder BIT          = NULL
AS
     SET NOCOUNT ON;
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
           addDataCallBackReminder = ISNULL(@addDataCallBackReminder, addDataCallBackReminder)
     WHERE inbound_id = @inbound_id;
     IF NOT EXISTS
     (
         SELECT inbound_id
         FROM ccinbound
         WHERE inbound_id <> @inbound_id
               AND chatDomain = @chatDomain
               AND chatDomain <> ''''
     )
         BEGIN
             IF @chatDomain IS NOT NULL
                 BEGIN
                     UPDATE ccinbound
                       SET 
                           chatDomain = @chatDomain
                     WHERE inbound_id = @inbound_id;
             END;
     END;
         ELSE
         BEGIN
             UPDATE ccinbound
               SET 
                   chatDomain = ''''
             WHERE inbound_id = @inbound_id;
             RAISERROR(''Domain already in another ACD Group'', 15, 4);
     END;
     IF @ShowCalifWnd = 1
         BEGIN
             IF EXISTS
             (
                 SELECT cam_id
                 FROM ccCalifCamp
                 WHERE cam_id = @inbound_id
                       AND tipo = 0
             )
                 BEGIN
                     UPDATE ccInbound
                       SET 
                           ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd)
                     WHERE inbound_id = @inbound_id;
                     SELECT 1;
                     RETURN(0);
             END;
             SELECT 0;
             RETURN(0);
     END;
         ELSE
         UPDATE ccInbound
           SET 
               ShowCalifWnd = ISNULL(@ShowCalifWnd, ShowCalifWnd)
         WHERE inbound_id = @inbound_id;

	 SELECT 2;
     RETURN(0);
     SET NOCOUNT OFF;
	 '
		EXEC(@sql)

		set @process = 'CW-4732 Eliminar sp ccsp_GalateaRIALog'
		set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaRIALog'')
				    begin
						DROP PROCEDURE ccsp_GalateaRIALog;
				    end'
		EXEC(@sql)

		set @process = 'CW-4732 Creacion del sp ccsp_GalateaRIALog'
		set @sql = '-- =============================================
-- Author: UEspinosa
-- Create date: 16/12/2020
-- Description:	Sabe to ccRIALog
-- =============================================
CREATE PROCEDURE ccsp_GalateaRIALog
@userId           SMALLINT,
@OperationType    VARCHAR(MAX)= '''',
@Value			  VARCHAR(MAX) = '''',
@Module			  SMALLINT,
@target			  VARCHAR(40) = ''''
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID(''tempdb..#OperationType'') IS NOT NULL DROP TABLE #OperationType
	create table #OperationType(
			id smallint IDENTITY(1,1),
			operationType varchar(MAX)
	)
	insert into #OperationType SELECT value FROM fn_RIASplitDelimited(@OperationType, '','')	

	IF OBJECT_ID(''tempdb..#Value'') IS NOT NULL DROP TABLE #Value
	create table #Value(
			id smallint IDENTITY(1,1),
			value varchar(MAX)
	)
	insert into #Value SELECT value FROM fn_RIASplitDelimited(@Value, ''^^'')
	
	IF OBJECT_ID(''tempdb..#Params'') IS NOT NULL DROP TABLE #Params
	select operationType,value 
	into #Params
	from #OperationType o
	inner join #Value v with(nolock) on o.id = v.id


	IF OBJECT_ID(''tempdb..#PreLog'') IS NOT NULL DROP TABLE #PreLog
	create table #PreLog(
			areaName varchar(40),
			operatioDate DATETIME,
			login varchar(40),
			module_id smallint,
			target varchar(40)
	)
	insert into #PreLog
	select AreaName, GETDATE() as operatioDate,u.login,@Module module_id,@target as target
	from ccUsers U
	INNER JOIN ccRIACat_Areas A with(nolock) on u.IDArea = a.IDArea
	where U.User_id = @userId

	Insert into ccRIALog
	select areaName,operatioDate,operationType,login,module_id,value,target
	from #PreLog,#Params

	IF OBJECT_ID(''tempdb..#OperationType'') IS NOT NULL DROP TABLE #OperationType
	IF OBJECT_ID(''tempdb..#Value'') IS NOT NULL DROP TABLE #Value
	IF OBJECT_ID(''tempdb..#Params'') IS NOT NULL DROP TABLE #Params
	IF OBJECT_ID(''tempdb..#PreLog'') IS NOT NULL DROP TABLE #PreLog
	Select 1
	return
END
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
