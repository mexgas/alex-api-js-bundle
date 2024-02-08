USE [CCenterRIA]
GO
/****** Object:  StoredProcedure [dbo].[ccsp_RIA_ABCAgents]    Script Date: 2/7/2024 10:32:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ccsp_RIA_ABCAgents]
          @option smallint,
          @UserId int,
          @Login varchar(40)='',
          @Nombres varchar(25)=null,
          @ApellidoPaterno varchar(25)='',
          @ApellidoMaterno varchar(25)='',
          @Password varchar(33)='',
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
            select User_id,Login,ISnull(AREas.AreaName,'')as AreaName

          from ccusers as users with(nolock)
              left join ccRIACat_Areas as areas with(nolock)
              on users.IDArea=areas.IDArea
            return(0)
            end

          if @option=1--selected User
            begin
            select User_id,Login,Nombres,isnull(apellidoPaterno,''),
              isnull(ApellidoMaterno,''),Sexo,canChangeStatus,isnull(IDArea,0),tipouser_id
            from ccusers where User_id=@UserId
            order by IDArea,Nombres,ApellidoPaterno,User_id
            return(0)
            end

          if @option=2--insert
            begin
            if exists(select Login from ccUsers where Login=@Login)
              begin
              select -1--,'Login en Uso'
              return(0)
              end

            if exists(select Login from ccUsers_Consulta where Login = @Login)
            begin
              select -4 -- 'Login habia estado en Uso'
              return(0)
            end

            if exists(select Nombres from ccUsers where Nombres=@Nombres
            and ApellidoPaterno=@ApellidoPaterno and ApellidoMaterno=@ApellidoMaterno)
              begin
              select -2--,'Nombre en Uso'
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

            select @UserId,' Usuario ' + @Login + ' Dado de Alta'
            return(0)
            end

          if @option=3--Update
            begin
            if @Login='' and @Password <> ''
              begin
              Update ccUsers set Password=@Password, LastPasswordChange = GETDATE() where User_id=@UserId
              return(0)
              end

            Update ccUsers
            set Login= case when @Login <> '' then @Login else Login end,
            Nombres=@Nombres,
            ApellidoPaterno=@ApellidoPaterno,ApellidoMaterno=@ApellidoMaterno,
            Password=case when @Password <> '' then @Password else Password end,
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
            if isnull(@UserId, 0) = 0 and CHARINDEX(',', @multipleUsers)=0
              select @UserId = @multipleUsers

                  else if isnull(@UserId, 0) = 0 and CHARINDEX(',', @multipleUsers)>0
                    select @UserId = cast(substring(@multipleUsers, 1,
                    CHARINDEX(',', @multipleUsers)-1) as int)

              select @Type=case when @UserType <> 0 then @UserType else TipoUser_id end,
              @multipleUsers=isnull(@multipleUsers,cast(@Userid as varchar(10)))
            from ccUsers where User_id=@UserId

            Declare @sqlDelete nvarchar(4000)
            if @Type in(1,2,6)--1:Agente / 2,6:Supervisor
              begin
              set @sqlDelete=N'Delete from ' + case @Type when 1 then 'cccampsagente where ' else 'ccSupervisorCam where tipo=0 and ' end
              + 'user_id in('+ isnull(@multipleUsers,'user_id') + ') and IDWG='+cast(@IDWG as varchar(10))
              + ' Delete from ' + case @Type when 1 then 'ccinboundagentes where ' else 'ccSupervisorCam where tipo=1 and ' end
              + 'user_id in('+ isnull(@multipleUsers,'user_id') + ') and IDWG='+cast(@IDWG as varchar(10))
              exec(@sqlDelete)
              end

            if isnull(@UserId, 0) = 0 or isnull(@multipleUsers, '0') = '0'
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
            select @NinOut=case when @inOut <> 1 then '0' else '1' end
            set @sql='delete ' + case @NinOut when '1' then 'ccCampsAgente' else 'ccInboundAgentes' end +
              ' where user_id in(' + isnull(@multipleUsers, '0') +') and ' + case @NinOut when '1' then 'cam_id' else 'inbound_id' end +
              '=' + cast(@IDCampEsp as varchar(10)) + ' and IDWG=' + cast(@IDWG as varchar(10)) +
              ' delete ccRIACampEspWG where tipo=' + @NinOut + ' and IDWG=' + cast(@IDWG as varchar(10)) + ' and IdCampEsp=' + cast(@IDCampEsp as varchar(10))
            exec(@sql)
            --update preview permission
            set @sql = 'update ccusers set 
                AllowChangeDialingMode=(case when assigned is null then 0 else 1 end),
                DialingMode=(case when assigned is null then 0 else 1 end) from ccusers us (nolock) left join (
                select count(1) assigned,user_id from ccCampsAgente ca (nolock) join ccCamps cc (nolock) on cc.cam_id=ca.cam_id
                where progDial=3 and user_id in (' + isnull(@multipleUsers, '0') +') group by user_id)c on us.User_id=c.user_id
                where us.user_id in (' + isnull(@multipleUsers, '0') +')'
            exec(@sql)
          return(0)
            end

          if @option=8--Delete Supervisor from WorkGroup
            begin
            select @NinOut=case when @inOut <> 1 then '0' else '1' end

                  set @sql='delete ccSupervisorCam where tipo=' + @NinOut + ' and user_id in(' + isnull(@multipleUsers, '0') + ') and cam_id='
                    + cast(@IDCampEsp as varchar(10)) + ' and IDWG=' +cast(@IDWG as varchar(10)) + '
                    delete ccRIACampEspWG where tipo=' + @NinOut + ' and IDWG=' + cast(@IDWG as varchar(10)) + ' and IdCampEsp=' + cast(@IDCampEsp as varchar(10))
                  exec(@sql)

            set @sql='delete ccSupervisorCam where tipo=' + @NinOut + ' and cam_id=' + cast(@IDCampEsp as varchar(10)) + 'and ' +
              'user_id in (' + isnull(@multipleUsers, '0') + ') and IDWG=' + cast(@IDWG as varchar(10))
            exec(@sql)
            return(0)
            end

          if @option=9
            begin
	
            update ccusers set NotReadyRestricted=@canChangeStatus where [User_id]=@UserId

			select Login from ccUsers where [User_id]=@UserId
            return(0)
            end
          set nocount off