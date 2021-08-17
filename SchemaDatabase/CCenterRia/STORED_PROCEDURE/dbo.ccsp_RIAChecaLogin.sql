CREATE PROCEDURE dbo.ccsp_RIAChecaLogin
    @login             VARCHAR(40)
,   @password          VARCHAR(40)
,   @computer          VARCHAR(20)
,   @passwordLwC       VARCHAR(40)=NULL
AS
    DECLARE @loginOK TINYINT,@pswdOK TINYINT,@compuOK TINYINT,@extenOK TINYINT,@teclaOK TINYINT,@xferAgents TINYINT

    DECLARE @nombre VARCHAR(60),@extension VARCHAR(15),@userID SMALLINT,@cCServer VARCHAR(20),@dialingMode INT

    DECLARE @passwordDb VARCHAR(33)

    DECLARE @crmxActive TINYINT

    DECLARE @passSecure INT

/*************************
Para posiciones ip, by ODC
*************************/

    DECLARE @ext_id INT,@pos_id INT,@isIP BIT,@ipExtension VARCHAR(15)

    DECLARE @tipoConexion SMALLINT

/***************************************************************
 Para live connected Tipo de conexion: 0 normal, 1 liveconnected
***************************************************************/

    SELECT @loginOK=0,@pswdOK=0,@compuOK=0,@extenOK=0,@teclaOK=0,@xferAgents=0,@extension=' ',@userID=0,@nombre=' ',
    @tipoConexion=0,@ipExtension='',@isIP=0,@cCServer='127.0.0.1',@dialingMode=0,@crmxActive=0,@passSecure=0

    SELECT @userID=User_id,@passwordDb=Password
    FROM ccUsers WITH(NOLOCK)
    WHERE Login = @login AND STATUS > 0 AND tipoUser_id = 1

    IF @userID > 0
    SET @loginOK=1

    IF @loginOK = 1 AND (@passwordDb = @password OR @passwordDb = dbo.md5(@password) OR dbo.md5(@passwordDb) = @password OR
    @passwordDb = @passwordLwC OR @passwordDb = dbo.md5(@passwordLwC) OR dbo.md5(@passwordDb) = @passwordLwC)
    SET @pswdOK=1

    IF @pswdOK = 1 AND NOT EXISTS
                            (
                               SELECT Computer
                               FROM ccPosicion WITH(NOLOCK)
                               WHERE STATUS = '1' AND Computer = @computer
                            )
    INSERT INTO ccposicion(computer,ext_id,user_id,IP)
    VALUES(@computer,0,@userID,@computer)

    SET @compuOK=1

    IF @pswdOK = 1
    BEGIN

        IF EXISTS
               (
                  SELECT Computer
                  FROM ccPosicion AS P
                  JOIN ccMonitorExt AS M ON P.ext_id = M.ext_id
                  WHERE p.STATUS = '1' AND M.STATUS = '1' AND Computer = @computer
               )
        SET @extenOK=1

        SELECT @extension=Extension,@ext_id=p.ext_id,@pos_id=p.pos_id,@tipoConexion=p.tipoConexion,@isIP=isIP
        FROM ccPosicion AS P
        INNER JOIN ccMonitorExt AS M ON P.ext_id = M.ext_id
        WHERE Computer = @computer

        SELECT @teclaOK=COUNT(*)
        FROM ccTeclaExtensionPuerto AS T
        INNER JOIN ccMonitorExt AS M ON T.ext_id = M.ext_id
        WHERE M.Extension = @extension

        SELECT @nombre=Nombres + ' ' + ISNULL(ApellidoPaterno,'') + ' ' + ISNULL(ApellidoMaterno,''),@xferAgents=XferAgents,
        @dialingMode=DialingMode
        FROM ccUsers
        WHERE User_id = @userID

/******************************************************************************************
Para posiciones ip, by ODC
 No verifica ccTeclaExtensionPuerto, @TeclaOK =1
 Regresa un extension 'virtual'.  Debe ser diferente a cualquiera de ccMonitorExt.Extension
******************************************************************************************/

        IF @ext_id = 0
        BEGIN
           SELECT @teclaOK=1,@extension=CAST(@pos_id * -1 AS VARCHAR(15))
        END

/*****************************************************************************************
-Por OAYC IPExtension, extension, para cuando es posición IP con alguna extension asignada
*****************************************************************************************/

        ELSE
        IF @ext_id > 0 AND @isIP = 1
        BEGIN
           SELECT @teclaOK=1,@ipExtension=@extension,@extension=CAST(@pos_id * -1 AS VARCHAR(15))
        END

        IF @tipoConexion = 1
        SET @teclaOK=1

        SELECT @cCServer=valor
        FROM ccSettings
        WHERE setting_id = 7

        SELECT @crmxActive=valor
        FROM ccsettings
        WHERE setting_id = 168

        SELECT @passSecure=valor
        FROM ccSettings
        WHERE setting_id = 207

    END

    SELECT @loginOK AS LoginOK,@pswdOK AS PswdOK,@compuOK AS CompuOK,@extenOK AS ExtenOK,@extension AS Extension,@userID AS
    UserID,@nombre AS Nombre,@cCServer AS CCServer,@teclaOK AS TeclaOK,@tipoConexion AS TipoConexion,@ipExtension AS
    ipExtension,@xferAgents AS XferAgents,@crmxActive AS CRMx,@passSecure AS passSecure,@dialingMode AS dialingMode