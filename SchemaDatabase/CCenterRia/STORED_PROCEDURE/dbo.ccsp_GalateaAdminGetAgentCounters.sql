CREATE PROCEDURE [dbo].[ccsp_GalateaAdminGetAgentCounters] @type AS     INT, 
                                                            @sup_id AS   INT = 0, 
                                                            @agent_id AS INT = 0, 
                                                            @WG AS       INT = 0,
                                  @campId AS INT = 0,
                                  @CampType AS SMALLINT = 1
            AS
             SET NOCOUNT ON;
             IF @type = 1
                 BEGIN
                     WITH TableUserAgent(userId)
                          AS (SELECT DISTINCT 
                                   wgAgt.User_id  AS Id --,usr.login 
                              FROM ccriaworkgroupusers wgAdmin
                                   INNER JOIN ccriaworkgroupusers wgAgt ON wgAdmin.IDWG = wgAgt.IDWG
                                   INNER JOIN ccUsers usr ON usr.User_id = wgAgt.User_id
                                                             AND usr.TipoUser_id = 1
                              WHERE wgAdmin.User_id = @sup_id)
                          SELECT CAST(a.User_id AS INT) Id, 
                                 a.login AS Username, 
                                 a.Nombres + ' ' + a.ApellidoPaterno + ' ' + a.ApellidoMaterno AS Name
                          FROM ccusers a(NOLOCK)--, ccGenViewRelsSupsAgent b
                               INNER JOIN TableUserAgent b ON a.User_id = b.userId
                          ORDER BY a.Login ASC;
             END;
             IF @type = 2
                 BEGIN
                     SELECT CAST(User_id AS INT) Id,
                  Login Username, 
                            Nombres + ' ' + ApellidoPaterno + ' ' + ApellidoMaterno Name
                     FROM ccUsers
                     WHERE User_id = @agent_id;
             END;
             IF @type = 3 --Agents by supervisor and WG
                 BEGIN
                     DECLARE @table2 TABLE
                     (userId INT
                      PRIMARY KEY NOT NULL
                     );
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
                     SELECT CAST(B.User_id AS int) AS Id
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
             END;

           IF @type = 4 --Agents IDs by WG
             BEGIN
            SELECT  CAST(wg.User_id AS INT) Id  
            FROM ccRIAWorkGroupUsers wg
            JOIN CCUsers u on u.user_id = wg.user_id AND u.TipoUser_id = 1
            where IDWG = @WG
             END;

           IF @type = 5 --Agents IDs by Campaign
             BEGIN
            SELECT Distinct(CAST(U.User_id AS INT)) Id FROM ccRIACampEspWG camp
            JOIN ccRIAWorkGroupUsers wg ON camp.IDWG = wg.IDWG
            JOIN ccUsers U ON U.User_id = WG.User_id AND U.TipoUser_id = 1
            WHERE IdCampEsp = @campId AND TIPO = @CampType
             END;

            IF @type = 6 -- Get Agent current state
           BEGIN
            WITH UserMaxFecha(User_id,fecha) as(
              SELECT User_id,max(fecha) as fecha from ccLogAgentesDia where fecha>=convert(date,getdate()) group by User_id
            )

            SELECT CASE WHEN CurrentState.currentStatus is null or  CurrentState.currentStatus<0 
                  then 0 else CAST(CurrentState.currentStatus as int) end CurrentState
            from ccUsers u
            left join 
            (
            select A.User_id,B.currentStatus from UserMaxFecha A 
            inner join ccLogAgentesDia  B on A.User_id=B.User_id and A.fecha=B.fecha
            ) CurrentState on u.User_id=CurrentState.User_id
            where u.TipoUser_id=1 and u.User_id = @agent_id
           END

           IF @type = 7 -- Get superuser id's except root
           BEGIN
            declare @superuserId as int
            set @superuserId = (select Rol_id from ccRoles where Level = 7) -- obtenemos el id del rol superusuario

            select CAST(cr.User_id AS INT) User_id 
            from ccUsers_Roles cr
            where Rol_id = @superuserId
            and cr.User_id not in (1) 
           END

           IF @type = 8 -- Get all Agent's ID, Login and Full Names related to a workgroup
           BEGIN
            SELECT DISTINCT 
              Convert(INT,wg.User_id) Id,
              us.Login Username,
              us.Nombres + ' ' + us.ApellidoPaterno + ' ' + us.ApellidoMaterno Name
            FROM ccRIAWorkGroupUsers wg
              LEFT JOIN ccUsers us ON wg.User_id = us.User_id
            WHERE wg.IDWG = @WG
              AND us.TipoUser_id = 1
           END

           SET NOCOUNT ON;