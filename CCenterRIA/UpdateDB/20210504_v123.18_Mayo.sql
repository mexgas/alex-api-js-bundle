/*******************************/
/***** NUXIBA TECHNOLOGIES *****/
/*******************************/
/*
Author:


Date: 2021/04/06
Description:

Database: CCenterRia
Required version: 123.14

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
SET @versionfix = 18
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

	set @process = 'CW-5216 Check if exists ccsp_GalateaAdminSubdispositions'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSubdispositions'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminSubdispositions;
            end'
    EXEC(@sql)

	set @process = 'CW-5216 Create ccsp_GalateaAdminSubdispositions'	
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSubdispositions]
@command int
AS
set nocount on

if @command=1 -- Load ccTipoCalifSub
begin
  select califSub_id, IsNull(califSubDesc,'''') [califSubDesc], orden, canReprogram, 
  IsNull(EndConversation,0) EndConversation
  from ccTipoCalifSub
  where califSub_Status = 1
  order by 2
  return(0)
end

If @command=2 -- Load ccTipoCalifSubOut
begin
  select califSub_id, IsNull(califSubDesc,'''') [califSubDesc],
  IsNull(canReprogram, 0) [canReprogram],
  IsNull(orden, 0) [orden],
  IsNull(keepDial, 0) [keepDial],
  IsNull(autoCallback, 0) [autoCallback],
  IsNull(contactOwner, 0) [contactOwner]
  from ccTipoCalifSubOut
  where califSubOut_Status = 1
  order by 2
  return(0)
end

set nocount off'
    EXEC(@sql)
	
	set @process = 'CW-5236 Check if exists ccsp_GalateaAdminSubdispositionRelations'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminSubdispositionRelations'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminSubdispositionRelations;
            end'
    EXEC(@sql)

	set @process = 'CW-5236 Create ccsp_GalateaAdminSubdispositionRelations'	
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminSubdispositionRelations]
@command int
AS
set nocount on

If @command = 1
begin
	select cast(0 as int) [type],
		r.calif_id,
		r.califSub_id
	from cctipoSubCalifRel r inner join ccTipoCalifSub t on r.califSub_id = t.califSub_id and r.tipoSubRel = 1
	where t.califSub_Status = 1
	UNION
	select cast(1 as int) [type],
		r.calif_id,
		r.califSub_id
	from cctipoSubCalifRel r inner join ccTipoCalifSubOUT t on r.califSub_id = t.califSub_id and r.tipoSubRel = 0
	where t.califSubOut_Status = 1
	order by [type], calif_id, califSub_id
end

set nocount off'
    EXEC(@sql)


	set @process = 'CW-5084 Desactivar la validaci�n de tel�fono en llamada manual'	
	set @sql = 'UPDATE CCSETTINGs SET detalle =  ''0 - Realiza las validaciones de marcacion normalmente / 1 - marca el numero sin validarlo / 2 Valida solo lista negra'' WHERE SETTING_id = 206'
    EXEC(@sql)

	set @process = 'CW-5084 Desactivar la validaci�n de tel�fono en llamada manual'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_Limpia'')
            begin
          DROP PROCEDURE ccsp_Limpia;
            end'
    EXEC(@sql)
	
	set @process = 'CW-5084 Desactivar la validaci�n de tel�fono en llamada manual'	
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_Limpia] @tel VARCHAR(50), @Camp INT = 0, @calKey VARCHAR(20) = ''''
AS
SET NOCOUNT ON

DECLARE @lon TINYINT, @cldLocal VARCHAR(7), @pais VARCHAR(3), @extLen SMALLINT, @specialDialPlan SMALLINT, @validateTel SMALLINT, @ld VARCHAR(7)
DECLARE @checkLd_In_ANILst SMALLINT = 0
/***
 4  as res lista Negra
 2 as res Digitos incorrectos Prefijo Marcacion 01,044,045,001
 3 as res Number notExists
 1 as res Longitud invalida
 0 as res Numero correcto
 
***/
SELECT @tel = dbo.limpia(@tel)

SELECT @lon = len(@tel)

SELECT @pais = valor
FROM ccSettings WITH (NOLOCK)
WHERE setting_id = 104

SELECT @cldLocal = valor
FROM ccSettings WITH (NOLOCK)
WHERE setting_id = 17

SELECT @extLen = valor
FROM ccsettings WITH (NOLOCK)
WHERE setting_id = 108

SELECT @validateTel = valor
FROM ccsettings WITH (NOLOCK)
WHERE setting_id = 206

SELECT @checkLd_In_ANILst = valor FROM ccsettings WITH (NOLOCK) WHERE setting_id = 213


IF @lon > 1
BEGIN

	IF @validateTel = 2
		BEGIN --Setting 206 only validates blacklist
		
			IF (SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)) = 1
			BEGIN
				SELECT 4 AS res, @tel AS tel --blackList
				RETURN (0)
			END
			SELECT 0 AS res, @tel AS tel

			RETURN (0)
	
	END
	IF @validateTel = 1
	BEGIN --Setting 206 para no validar longitud ni listas negras
		SELECT 0 AS res, @tel AS tel

		RETURN (0)
	END

	IF @extLen = @lon
	BEGIN -- Setting 108 validar el tama�o longitud del telefono
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList

			RETURN (0)
		END

		SELECT 0 AS res, @tel AS tel -- Extension

		RETURN (0)
	END
END

DECLARE @telTemp AS VARCHAR(15)

SELECT @telTemp = @tel

IF @pais = 1
BEGIN ---Mexico
	IF @lon = 3 AND @tel = ''911''
	BEGIN
		SELECT 4 AS res, @tel AS tel --Lista Negra

		RETURN (0)
	END

	IF (@lon < 10)
	BEGIN
		SELECT 1 AS res, @tel AS tel --Longitud invalida

		RETURN (0)
	END

	IF @lon = 12 AND left(@tel, 2) <> ''01'' OR @lon = 13 AND left(@tel, 3) NOT IN (''044'', ''045'') AND left(@tel, 3) <> ''001''
	BEGIN
		SELECT 2 AS res, @tel AS tel --Digitos incorrectos

		RETURN (0)
	END

	IF left(@tel, 3) = ''001''
	BEGIN
		SELECT 0 AS res, @tel AS tel

		RETURN (0)
	END

	SELECT @tel = right(@tel, 10)

	IF (
			SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
			) = 1
	BEGIN
		SELECT 4 AS res, @tel AS tel --blackList

		RETURN (0)
	END
	
	If (@Camp > 0 AND @checkLd_In_ANILst = 1)
	BEGIN
		If(SELECT len(ani) FROM ccCamps WHERE cam_id = @Camp) > 0  --Permitir todos los telefonos a 10 digitos cuando existe un ani configurado en la campana.	
		BEGIN
			SELECT 0 AS res, @tel AS tel	
			RETURN (0)
		END

		IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
				  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
				  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 3))
		BEGIN
			SELECT 0 AS res, @tel AS tel
			RETURN (0)
		END
		ELSE IF exists (SELECT TOP 1 area FROM ccCamps c WITH (NOLOCK) inner join ccEdoAniList l WITH (NOLOCK) on c.id_anilist = l.id_AniList
				  inner join ccEstadosAni e WITH (NOLOCK) on l.id_AniList = e.id_AniList
				  WHERE cam_id = @Camp and telAni <> '''' and area = left(@tel, 2))
		BEGIN
			SELECT 0 AS res, @tel AS tel
			RETURN (0)
		END
	END


	SELECT @tel = dbo.Verifica2(@tel, 1, @cldLocal)

	IF LEFT(@tel, 1) = ''E''
	BEGIN
		SELECT 3 AS res, @telTemp AS tel --No encontrado

		RETURN (0)
	END

	SELECT 0 AS res, @tel AS tel

	RETURN (0)
END
ELSE IF @pais = 2
BEGIN --Argentina 
	SET @tel = dbo.completa(@tel, @pais, @cldLocal)

	IF left(@tel, 1) = ''E''
	BEGIN
		SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

		RETURN (0)
	END

	SELECT @tel = dbo.fnClearPhoneArg(@tel)

	IF (len(@tel) = 10 OR len(@cldLocal + @tel) = 10) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos      
	END

	RETURN (0)
END
ELSE IF @pais = 3
BEGIN --Colombia  
	IF @lon < 7 OR @lon = 9 OR (@lon = 10 AND left(@telTemp, 1) <> ''3'') OR (@lon = 11 AND left(@telTemp, 2) <> ''03'')
	BEGIN
		SELECT 1 AS res, @telTemp AS tel --Longitud Invalida

		RETURN (0)
	END

	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (8, 10)) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 4
BEGIN --USA 
	EXEC ccsp_LimpiaUsa @tel, @Camp, @calKey

	RETURN (0)
END
ELSE IF @pais = 5
BEGIN --Chile  
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF len(@tel) IN (8, 9) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 6
BEGIN --Venezuela    
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF len(@tel) = 10 AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 7
BEGIN --Reino Unido
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (9, 10)) AND left(@tel, 1) <> ''E''
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais = 8
BEGIN --Arabia saudita   
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF (len(@tel) IN (9, 10, 11))
	BEGIN
		IF (
				SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
				) = 1
		BEGIN
			SELECT 4 AS res, @tel AS tel --blackList      
		END
		ELSE
		BEGIN
			SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

			IF left(@tel, 1) = ''E''
			BEGIN
				SELECT 3 AS res, @telTemp --Not existsFound
			END

			SELECT 0 AS res, @tel AS tel
		END
	END
	ELSE
	BEGIN
		SELECT 2 AS res, @telTemp AS tel --Digitos incorrectos
	END

	RETURN (0)
END
ELSE IF @pais IN (9, 10, 11, 12, 13, 14, 15, 16)
BEGIN --9: Australia, 10:Brasil, 11:Guatemala, 12:Costa Rica, 13:Salvador, 14:Espa�a 15:Peru, 16: Panama 
	SELECT @tel = dbo.Completa_ListaNegra(@tel)

	IF left(@tel, 1) = ''E''
	BEGIN
		SELECT 1 AS res, @telTemp --Longitud Invalida   
	END
	ELSE IF (
			SELECT dbo.ValidateBlackListPhone(@tel, @Camp, @calKey)
			) = 1
	BEGIN
		SELECT 4 AS res, @tel AS tel --blackList      
	END
	ELSE
	BEGIN
		SELECT @tel = dbo.verifica2(@tel, @pais, @cldLocal)

		IF left(@tel, 1) = ''E''
		BEGIN
			SELECT 2 AS res, @telTemp --Digitos Incorrectos ??? debe ser numero no existe
		END

		SELECT 0 AS res, @tel AS tel
	END

	RETURN (0)
END

'
    EXEC(@sql)


	set @process = 'CW-5150 Configuracion en historial de llamadas se agrega setting 255'	
	set @sql = '
	if not exists(select * from [CCenterRIA].[dbo].[ccSettings] where setting_id=255) begin
        insert into [CCenterRIA].[dbo].[ccSettings](setting_id,valor,descripcion,Status,Tipo,detalle,description,bLoadSettings,validate) values(255,''3|200'',''Tiempo para historial de llamadas | maximo numero de llamadas'',''1'',''AGT'',''Para el historial de llamadas, primer valor es el tiempo para buscar el historial, default 3 hrs, maximo 24 | segundo valor top de llamadas a mostrar 0=Muestra todas las llamadas. 100 o 300'',''For call history first value is the time max its going to fetch records from, default 3 hours, max 24 hours, second value is the top records its going to fetch. 0=shows all calls, 100 or 300 '', 0,''\b(0?[1-9]?|1[0-9]|2[0-4])(\|)([0-9]?[0-9]?[0-9])\b'');
  	end
	'
    EXEC(@sql)




	set @process = 'CW-5150 Configuracion en historial de llamadas se modifica SP getLastCalls'	
	set @sql = '
	ALTER PROCEDURE [dbo].[ccspAgent_GetLastCalls] @user_id INT
AS
     SET NOCOUNT ON
     DECLARE @lastCallAgt TABLE
     (id           INT NOT NULL, 
      tipo         VARCHAR(10) NOT NULL, 
      Hora         VARCHAR(19) NOT NULL, 
      Telefono     VARCHAR(55) NOT NULL, 
      EspCamp      VARCHAR(55) NOT NULL, 
      Calificacion VARCHAR(60), 
      Duracion     VARCHAR(10) NOT NULL, 
      CallBack     VARCHAR(60), 
      cal_key      VARCHAR(20), 
      IDCampEsp    SMALLINT NOT NULL, 
      prefijo      VARCHAR(MAX) NULL, 
      GraphicID    INT,
	  HidePhone	   bit
     )

	 declare @pais tinyint;
	 set @pais = (select valor from ccSettings where setting_id = 104);
	 
	 declare @maxHours SMALLINT;
	 declare @topRows SMALLINT;
	 declare @setting varchar(6);
	 set @setting = (select valor from ccSettings where setting_id = 255)
	 
	 set @maxHours = CAST(SUBSTRING(@setting, 1,  (SELECT PATINDEX(''%|%'', @setting))-1) AS SMALLINT);
	 set @topRows = CAST(SUBSTRING(@setting, (SELECT PATINDEX(''%|%'', @setting))+1, LEN(@setting))AS SMALLINT);

	 IF @maxHours = 0
	 BEGIN
	     SELECT *
		 FROM @lastCallAgt
		 ORDER BY hora DESC
		 SET NOCOUNT OFF
		 END

	 ELSE

	 BEGIN 

			 if @topRows = 0
			 begin
				 INSERT INTO @lastCallAgt
						SELECT c.cal_id AS id, 
									  ''IN'' AS Tipo, 
									  CASE WHEN @pais = 4 THEN (CONVERT(VARCHAR(10), cal_inicio, 101) + '' '' + CONVERT(VARCHAR(8), cal_inicio, 108)) ELSE (CONVERT(VARCHAR(10), cal_Inicio, 103) + '' ''  + convert(VARCHAR(8), cal_Inicio, 14))  END AS Hora, 
									  cal_ani AS Telefono, 
									  descripcion AS EspCamp, 
									  ISNULL(cal.Description, '''') AS Calificacion, 
									  CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE
																										WHEN stopRecording = 0
																										THEN ISNULL(t.tDespuesXfer, 0)
																										ELSE 0
																									END, 0), 108) Duracion, 
									  '''' AS CallBack, 
									  cal_key, 
									  c.inbound_id AS IDCampEsp, 
									  ISNULL(ccInbound.prefijo, '''') Prefijo, 
									  graph.graphic_id GraphicID,
									  case when (select valor from ccSettings where setting_id = 223) = ''0'' then 0 else 1 end as HidePhone
						FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
							 JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
							 INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
							 LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
							 LEFT JOIN
						(
							SELECT cal_id, 
								   tipo, 
								   SUM(tAntesXfer) AS tAntesXfer, 
								   SUM(tDespuesXfer) AS tDespuesXfer
							FROM ccLogTransfers
							WHERE tipo = 1
							GROUP BY cal_id, 
									 tipo
						) AS t ON c.cal_id = t.cal_id
						WHERE user_id = @user_id
							  AND cal_inicio > DATEADD(hh, -@maxHours, GETDATE())
						ORDER BY c.cal_inicio DESC
				 INSERT INTO @lastCallAgt
						SELECT c.cal_id AS id, 
									  ''OUT'' AS Tipo, 
									  CASE WHEN @pais = 4 THEN (CONVERT(VARCHAR(10),cal_inicio, 101) + '' '' + CONVERT(VARCHAR(8), cal_inicio, 108)) ELSE (CONVERT(VARCHAR(10), cal_Inicio, 103) + '' ''  + convert(VARCHAR(8), cal_Inicio, 14))  END AS Hora, 
									  cal_telefono AS Telefono, 
									  cam_descripcion AS EspCamp, 
									  ISNULL(cal.Description, '''') AS Calificacion, 
									  CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE
																								   WHEN stopRecording = 0
																								   THEN ISNULL(t.tDespuesXfer, 0)
																								   ELSE 0
																							   END, 0), 114) AS Duracion, 
									  ISNULL(CONVERT(VARCHAR(16), cal_fcallback, 121), '''') AS CallBack, 
									  cal_key, 
									  c.cam_id AS IDCampEsp, 
									  ISNULL(ccCamps.prefijo, '''') Prefijo, 
									  graph.graphic_id GraphicID,
									  case when (select valor from ccSettings where setting_id = 223) = ''0'' then 0 else 1 end as HidePhone
						FROM ccoCallsOut c
							 INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
							 LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
							 LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
							 LEFT JOIN
						(
							SELECT cal_id, 
								   tipo, 
								   SUM(tAntesXfer) AS tAntesXfer, 
								   SUM(tDespuesXfer) AS tDespuesXfer
							FROM ccLogTransfers
							WHERE tipo = 2
							GROUP BY cal_id, 
									 tipo
						) AS t ON c.cal_id = t.cal_id
						WHERE user_id = @user_id
							  AND cal_inicio > DATEADD(hh, -@maxHours, GETDATE())
						ORDER BY c.cal_inicio DESC
			 end

			 ELSE

			 begin
				 INSERT INTO @lastCallAgt
						SELECT top (CAST(@topRows AS INT)) c.cal_id AS id, 
									  ''IN'' AS Tipo, 
									  CASE WHEN @pais = 4 THEN (CONVERT(VARCHAR(10), cal_inicio, 101) + '' '' + CONVERT(VARCHAR(8), cal_inicio, 108)) ELSE (CONVERT(VARCHAR(10), cal_Inicio, 103) + '' ''  + convert(VARCHAR(8), cal_Inicio, 14))  END AS Hora, 
									  cal_ani AS Telefono, 
									  descripcion AS EspCamp, 
									  ISNULL(cal.Description, '''') AS Calificacion, 
									  CONVERT(VARCHAR(14), DATEADD(second, cal_tDialog - cal_tMoh + CASE
																										WHEN stopRecording = 0
																										THEN ISNULL(t.tDespuesXfer, 0)
																										ELSE 0
																									END, 0), 108) Duracion, 
									  '''' AS CallBack, 
									  cal_key, 
									  c.inbound_id AS IDCampEsp, 
									  ISNULL(ccInbound.prefijo, '''') Prefijo, 
									  graph.graphic_id GraphicID,
									  case when (select valor from ccSettings where setting_id = 223) = ''0'' then 0 else 1 end as HidePhone
						FROM ccCallsIn c WITH (NOLOCK INDEX(IX_ccCallsIn_4))
							 JOIN ccRIAInboundGraph graph ON graph.Inbound_id = c.Inbound_id
							 INNER JOIN ccInbound ON ccInbound.Inbound_id = c.Inbound_id
							 LEFT JOIN ccTipoCalif cal ON c.calif_id = cal.calif_id
							 LEFT JOIN
						(
							SELECT cal_id, 
								   tipo, 
								   SUM(tAntesXfer) AS tAntesXfer, 
								   SUM(tDespuesXfer) AS tDespuesXfer
							FROM ccLogTransfers
							WHERE tipo = 1
							GROUP BY cal_id, 
									 tipo
						) AS t ON c.cal_id = t.cal_id
						WHERE user_id = @user_id
							  AND cal_inicio > DATEADD(hh, -@maxHours, GETDATE())
						ORDER BY c.cal_inicio DESC
				 INSERT INTO @lastCallAgt
						SELECT top (CAST(@topRows AS INT)) c.cal_id AS id, 
									  ''OUT'' AS Tipo, 
									  CASE WHEN @pais = 4 THEN (CONVERT(VARCHAR(10), cal_inicio, 101) + '' '' + CONVERT(VARCHAR(8), cal_inicio, 108)) ELSE (CONVERT(VARCHAR(10), cal_Inicio, 103) + '' ''  + convert(VARCHAR(8), cal_Inicio, 14))  END AS Hora, 
									  cal_telefono AS Telefono, 
									  cam_descripcion AS EspCamp, 
									  ISNULL(cal.Description, '''') AS Calificacion, 
									  CONVERT(VARCHAR(8), DATEADD(ss, cal_tDialog - cal_tMoh + CASE
																								   WHEN stopRecording = 0
																								   THEN ISNULL(t.tDespuesXfer, 0)
																								   ELSE 0
																							   END, 0), 114) AS Duracion, 
									  ISNULL(CONVERT(VARCHAR(16), cal_fcallback, 121), '''') AS CallBack, 
									  cal_key, 
									  c.cam_id AS IDCampEsp, 
									  ISNULL(ccCamps.prefijo, '''') Prefijo, 
									  graph.graphic_id GraphicID,
									  case when (select valor from ccSettings where setting_id = 223) = ''0'' then 0 else 1 end as HidePhone
						FROM ccoCallsOut c
							 INNER JOIN ccCamps ON ccCamps.cam_id = c.cam_id
							 LEFT JOIN ccRIACampsGraph graph ON graph.cam_id = c.cam_id
							 LEFT JOIN ccTipoCalifOut cal ON c.calif_id = cal.calif_id
							 LEFT JOIN
						(
							SELECT cal_id, 
								   tipo, 
								   SUM(tAntesXfer) AS tAntesXfer, 
								   SUM(tDespuesXfer) AS tDespuesXfer
							FROM ccLogTransfers
							WHERE tipo = 2
							GROUP BY cal_id, 
									 tipo
						) AS t ON c.cal_id = t.cal_id
						WHERE user_id = @user_id
							  AND cal_inicio > DATEADD(hh, -@maxHours, GETDATE())
						ORDER BY c.cal_inicio DESC
			 end
		SELECT *
		 FROM @lastCallAgt
		 ORDER BY hora DESC
		 SET NOCOUNT OFF
		END
	'
    EXEC(@sql)


    set @process = 'CW-5189 Se elimina sp si existe'	
	set @sql = '
	if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminInbound'')
    begin
        DROP PROCEDURE ccsp_GalateaAdminInbound;
    end
	'
	EXEC(@sql)


    set @process = 'CW-5189 Se creo la consulta para obtener los datos de los ACD del día'	
	set @sql = '
	CREATE PROCEDURE [dbo].[ccsp_GalateaAdminInbound] @Option AS SMALLINT, 
                                                @InboundId AS SMALLINT = 0,
												@User_id AS SMALLINT = 0
	AS
	BEGIN
	    set nocount on;

	    if(@Option = 1) -- Por campaña 
	    begin
	        select 
	            ISNULL(count (*), 0) as Calls,
	            ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
	            ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
	            ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
	            ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
	            ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
	            ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
	            ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
	            ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
	            ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
	            THEN 1 ELSE NULL END), 0) AS Other
	        from ccCallsIn a (nolock)
	        where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) and a.inbound_id = @InboundId

	    end

		if(@Option = 2) -- Todas las campañas 
	    begin
	        select 
				inbound.Inbound_id as IDEspec,
				inbound.descripcion as Name,
	            ISNULL(count (*), 0) as Calls,
	            ISNULL(count (case when statusCall_id = 13 and (cal_tDialog >= 5) then 1 else null end), 0) as Answer,
	            ISNULL(count (CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0) as Abandon,
	            ISNULL(count (case when statusCall_id in (7,8) then 1 else null end), 0) as OverflowedCalls,
	            ISNULL(count (case when statusCall_id = 2 then 1 else null end), 0) as OutOfScheduleCalls,
	            ISNULL(count (case when statusCall_id = 3 then 1 else null end), 0) as OutOfServiceCalls,
	            ISNULL(count (case when statusCall_id = 4 then 1 else null end), 0) as NoAgentsCalls, -- sin agentes firmados
	            ISNULL(count (case when statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) then 1 else null end), 0) as InterruptedCalls,
	            ISNULL(count (case when statusCall_id = 15 OR statusCall_id = 11 then 1 else null end), 0) as NoAnswer,
	            ISNULL(COUNT (CASE WHEN statusCall_id in (2, 3, 4) THEN 1 WHEN statusCall_id = 1 OR statusCall_id = 13 AND (cal_tDialog < 5) 
	            THEN 1 ELSE NULL END), 0) AS Other
	        from ccCallsIn a (nolock)
			left join ccInbound inbound on a.inbound_id = inbound.Inbound_id
	        where cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106)) 
			group by inbound.Inbound_id, inbound.descripcion
	    end

		if(@Option = 3) -- Obtiene los datos de las llamadas de todos los ACD, datos que se muestran en el tablero de información del administrador 
	    begin
			SELECT 
				a.inbound_id, calls = ISNULL(COUNT(*), 0), -- calls
				Dialogs = ISNULL(COUNT (CASE WHEN statusCall_id = 13 THEN 1 ELSE NULL END), 0), -- Answered
				DlgsAveTime = ISNULL(SUM (CASE WHEN statusCall_id = 13 THEN cal_tDialog + cal_tNotas ELSE 0 END), 0),
				QueueAveTime =ISNULL( avg( CASE WHEN cal_que > 0 THEN cal_tWait ELSE NULL END), 0) ,
				abandon = ISNULL(COUNT(CASE WHEN (statuscall_id = 6 AND (cal_que > 0) AND (cal_xfer IS NULL)) THEN 1 ELSE NULL END), 0), -- Abandoned
				OverFlowQueue = ISNULL(COUNT (CASE WHEN statusCall_id =8 THEN 1 ELSE NULL END), 0),
				OverFlowTimeOut = ISNULL(COUNT (CASE WHEN statusCall_id =7 THEN 1 ELSE NULL END), 0), -- OverFlowQueue+OverFlowTimeOut = not answered
				outOfSchedule = ISNULL(COUNT (CASE WHEN statusCall_id =2 THEN 1 ELSE NULL END), 0), -- fuera de horario
				outOfService = ISNULL(COUNT (CASE WHEN statusCall_id =3 THEN 1 ELSE NULL END), 0), -- fuera de servicio
				noAgentsLoggedIn = ISNULL(COUNT (CASE WHEN statusCall_id =4 THEN 1 ELSE NULL END), 0), -- sin agentes firmados
				assigned = ISNULL(COUNT (CASE WHEN statusCall_id =11 THEN 1 ELSE NULL END), 0), -- asignada
				--assignedAndNotAnswered = ISNULL(COUNT (CASE WHEN statusCall_id =15 THEN 1 ELSE NULL END), 0), -- asignada y no contestada
				--assignedAndTookLine = ISNULL(COUNT (CASE WHEN statusCall_id =16 THEN 1 ELSE NULL END), 0), -- asignada y toma linea
				callsQueue = ISNULL(count (case when cal_que > 0 then 1 else null end), 0)
				--onQueue = ISNULL(COUNT(CASE WHEN statusCall_id = 5 THEN 1 ELSE NULL END), 0)
				--initCalls = CAST(ISNULL(COUNT(CASE WHEN statusCall_id = 1 THEN 1 ELSE NULL END), 0) AS varchar(7))+''|''+
				--			ISNULL((SELECT STUFF((SELECT ''|'' + cast(ci.cal_id AS varchar(7))
				--			FROM ccCallsin ci (nolock) WHERE cal_inicio > dateadd(mi,-5,getdate()) AND ci.inbound_id=a.inbound_id
				--			FOR XML PATH('''')) ,1,1,'''')),''0'')
			FROM ccCallsIn a (nolock)
			WHERE cal_inicio > CONVERT(datetime,CONVERT(varchar(20),GETDATE(),106))
					--and a.inbound_id in (select cam_id from ccSupervisorCam where user_id = @User_id and tipo = 0)
			GROUP BY a.inbound_id
		--	SET nocount off
		--	return(0)
		end

		if(@Option = 4) -- Carga los ACD del administrador mandado
	    begin
			SELECT cam_id 
			FROM ccSupervisorCam 
			WHERE user_id = @User_id and tipo = 0
			SET nocount off
			return(0)
		end
	                
	END
	'
	EXEC(@sql)

set @process = 'CW-5229 Insert new Agent Status'	
	set @sql = 'if not exists (select * from ccTipoStatusAgente where TipoStatusAge_id =31)
begin
	insert into ccTipoStatusAgente values (31,''Ready PreviewPro'')
end'
    EXEC(@sql)
	

	set @process = 'CW-5229 Check if exists ccsp_RIAChecaLogin'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_RIAChecaLogin'')
            begin
          DROP PROCEDURE ccsp_RIAChecaLogin;
            end'
    EXEC(@sql)

	set @process = 'CW-5229 Create Procedure ccsp_RIAChecaLogin'	
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_RIAChecaLogin]
@Login varchar(40),
@Password varchar(40),
@Computer varchar(20),
@PasswordLwC varchar(40) = null
AS
declare @LoginOK tinyint, @PswdOK tinyint, @CompuOK tinyint, @ExtenOK tinyint, @TeclaOK tinyint, @XferAgents tinyint
declare @Nombre varchar(60), @Extension varchar(15), @UserID smallint, @CCServer varchar(20), @dialingMode int

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

select @UserID=user_id, @Nombre=Nombres + '' '' + isnull(ApellidoPaterno,'''') + '' '' +isnull(ApellidoMaterno,''''), @XferAgents=XferAgents, @dialingMode = DialingMode
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
@XferAgents as XferAgents, @crmxActive as [CRMx], @passSecure as [passSecure], @dialingMode  as dialingMode
    '
    EXEC(@sql)
	
	set @process = 'CW-5248 Valida si existe campo GraphColor en ccTipoCalif'
    set @sql = 'IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccTipoCalif'' AND COLUMN_NAME = ''GraphColor'')
Begin
ALTER TABLE ccTipoCalif 
ADD GraphColor varchar(15) NOT NULL
CONSTRAINT DF_ccTipoCalif_GraphColor DEFAULT ''1DB4E2''
WITH VALUES
End'
    EXEC(@sql)
		
	set @process = 'CW-5248 Valida si existe campo GraphColor en ccTipoCalifOUT'
	set @sql = 'IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''ccTipoCalifOUT'' AND COLUMN_NAME = ''GraphColor'')
Begin
ALTER TABLE ccTipoCalifOUT 
ADD GraphColor varchar(15) NOT NULL
CONSTRAINT DF_ccTipoCalifOUT_GraphColor DEFAULT ''1DB4E2''
WITH VALUES
End'
    EXEC(@sql)

	set @process = 'CW-5248 Check if exists ccsp_GalateaAdminDispositions'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminDispositions'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminDispositions;
            end'
    EXEC(@sql)


	set @process = 'CW-5248 Se crea sp ccsp_GalateaAdminDispositions'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
@command int,
@califIdLst varchar(8000) = null,
@description varchar(60)=null,
@order tinyint=null,
@canReprogram bit = null,
@graphColor varchar(15) = null,
@endConversation bit=null,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null,
@finishPreview bit = 0
AS
set nocount on

if @command=1 -- Load Inbound Dispositions
begin
  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation
  order by 2
  return(0)
end

If @command=2 -- Load Outbound Dispositions
begin
  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
  IsNull(C.finishPreview,0) as finishPreview
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
  C.contactOwner, C.finishPreview
  order by 2
  return(0)
end

If @command=3 -- New ccTipoCalif
begin
  If exists(select description from ccTipoCalif where Calif_Status=1 and description=@description)
    begin
      select cast(3 as int) [result]
      return(0)
    end

  If exists(select description from ccTipoCalif where Calif_Status=0 and description=@description)
  begin
      update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
	  GraphColor=isnull(@graphColor, ''1DB4E2''), Calif_Status=1
      where description=@description
	  select cast(2 as int) [result]
      return(0)
  end

  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , GraphColor)
  select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalif
  select cast(1 as int) [result]
  return(0)
end

If @command=4 -- New ccTipoCalifOUT
begin
  If exists(select description from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
  begin
  select cast(3 as int) [result]
  return(0)
  end

 If exists(select description from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
 begin
  update ccTipoCalifOut set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0),
  Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
  finishPreview=isnull(@finishPreview,0), GraphColor=isnull(@graphColor, ''1DB4E2'')
  where description=@description
  select cast(2 as int) [result]
  return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, GraphColor)
 select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, @canReprogram, isnull(@keepDial,0), 
 isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalifOut
 select cast(1 as int) [result]
 return(0)
end


set nocount off'
    EXEC(@sql)

	set @process = 'CW-3996 Habilitar captura de los 5 datos en ACD con reprogramación'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_LoadGraphics'')
            begin
          DROP PROCEDURE ccsp_LoadGraphics;
            end'
    EXEC(@sql)	
	
	set @process = 'CW-3996 Habilitar captura de los 5 datos en ACD con reprogramación'	
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_LoadGraphics]
@Id as smallint,
@callType as smallint,
@UserId as smallint
AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	DECLARE @AuthorizationPlayStopRec TABLE(value bit)
	DECLARE @realValue bit

	INSERT INTO @AuthorizationPlayStopRec 
	exec ccsp_AgentGetStartStopPermission @age_id=@UserId, @cam_id=@Id, @call_type=@callType

	select @realValue=value from @AuthorizationPlayStopRec

	
	if (@callType=1)
	begin
		DECLARE @canReprogram bit  
		create table #canReprogram (canReprogram bit)
		insert into #canReprogram
		exec ccsp_AgentGetCampReprogramData @Id, @callType
		select @canReprogram = canReprogram from #canReprogram
		drop table #canReprogram

		select a1.Inbound_id id, a2.descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey, 0 as leaveRecMessage ,
		case when isnull(a4.callsBySurvey,0) > 0 then 1 else 0 end isRelationSurvey ,
		isnull(a2.callBackSurveyAgent,1) callBackSurveyAgent,isnull(a2.callBackSurveyClient,1) callBackSurveyClient,
		a2.ShowCalifWnd as ShowDisposition,
		isnull(a2.startStopRecording,0) as StartStopRecording,
		@realValue as IsStartStopRecording,
		isnull(a2.editableDtmf, 0) as isEditDtmf,
		@canReprogram  CanReprogram
		from ccRIAInboundGraph a1 
		inner join ccInbound a2 on (a1.inbound_id=a2.inbound_id)
		 inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id) 
		 left join ccCamps a4 on a4.cam_id=a2.cam_id  where a1.inbound_id=@Id and type_id in(1,2,3) order by type_id		
	 end	
	 else
	 begin
		select a1.cam_id Id, a2.cam_descripcion description, a1.graphic_id, a3.type_id, a3.frame, a2.EditableCallKey,
		case when msgFile <> '''' and leaveRecMessage = 1 then 1 else 0 end as leaveRecMessage, 
		case when isnull(a2.surveyCamId,0) >0 then 1 else 0 end isRelationSurvey ,
		a2.cam_ShowCalifWnd as ShowDisposition,
		a2.callBackSurveyAgent,a2.callBackSurveyClient,
		isnull(a2.startStopRecording,0) as StartStopRecording,
		@realValue as IsStartStopRecording
		from ccRIACampsGraph a1 
		inner join ccCamps a2 on (a1.cam_id=a2.cam_id)
		inner join ccRIAGraphics a3 on (a1.graphic_id=a3.graphic_id)
		left outer join (select top 1 M.cam_id, coalesce(msgFile+'''','''','''') as msgFile 
		from ccCampsMsgs M join ccMsgFiles T on M.Msg_id=T.msg_id 
		where M.cam_id = @Id and type = 8) b 
		on (a2.cam_id = b.cam_id) 
		where a1.cam_id=@Id and type_id in(1,2,3) order by type_id
	 end	
END
'
    EXEC(@sql)

	set @process = 'CW-5275, 5278, 5286, 5297 Check if exists ccsp_GalateaAdminDispositions'	
	set @sql = 'if exists (select * from sys.procedures where name = N''ccsp_GalateaAdminDispositions'')
            begin
          DROP PROCEDURE ccsp_GalateaAdminDispositions;
            end'
    EXEC(@sql)


	set @process = 'CW-5275, 5278, 5286, 5297 Se crea sp ccsp_GalateaAdminDispositions'
	set @sql = 'CREATE PROCEDURE [dbo].[ccsp_GalateaAdminDispositions]
@command int,
@califIdLst varchar(8000) = null,
@description varchar(60)=null,
@order tinyint=null,
@canReprogram bit = null,
@graphColor varchar(15) = null,
@endConversation bit=null,
@keepDial bit=null,
@autoCB bit=null,
@contactOwner bit=null,
@finishPreview bit = 0
AS
set nocount on
declare @inserted table (ID smallint)

if @command=1 -- Load Inbound Dispositions
begin
  Select C.calif_id, C.Description, C.orden, C.canReprogram, cast(0 as bit) as contactOwner, 
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.EndConversation,0) conversationEnd, graphColor
  from cctipoCalif C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 1
  where C.Calif_Status=1
  group by C.calif_id, C.Description, C.orden, C.canReprogram, C.EndConversation, graphColor
  order by 2
  return(0)
end

If @command=2 -- Load Outbound Dispositions
begin
  Select C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback,  
  cast(count(R.califRel_id)as tinyint) hasSub, IsNull(C.contactOwner,0) as contactOwner, 
  IsNull(C.finishPreview,0) as finishPreview, graphColor
  from cctipoCalifOUT C left join cctipoSubCalifRel R on C.calif_id = R.calif_id and R.tipoSubRel = 0
  where C.CalifOut_Status=1
  group by C.calif_id, C.Description, C.canReprogram, C.orden, C.keepDial, C.autocallback, 
  C.contactOwner, C.finishPreview, graphColor
  order by 2
  return(0)
end

If @command=3 -- New ccTipoCalif
begin
  If exists(select description from ccTipoCalif where Calif_Status=1 and description=@description)
    begin
      select cast(-1 as smallint) [result]
      return(0)
    end

  If exists(select description from ccTipoCalif where Calif_Status=0 and description=@description)
  begin
      update ccTipoCalif set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0), EndConversation=isnull(@endConversation,0), 
	  graphColor=isnull(@graphColor, ''1DB4E2''), Calif_Status=1
	  output inserted.calif_id into @inserted
      where description=@description
	  select ID [result] from @inserted 
      return(0)
  end

  insert into ccTipoCalif (calif_id, description, orden, CanReprogram, EndConversation , graphColor)
  output inserted.calif_id into @inserted
  select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), isnull(@canReprogram,0), isnull(@endConversation,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalif
  select ID [result] from @inserted
  return(0)
end

If @command=4 -- New ccTipoCalifOUT
begin
  If exists(select description from ccTipoCalifOut where CalifOut_Status=1 and description=@description)
  begin
  select cast(-1 as smallint) [result]
  return(0)
  end

 If exists(select description from ccTipoCalifOut where CalifOut_Status=0 and description=@description)
 begin
  update ccTipoCalifOut set orden=isnull(@order,0), CanReprogram=isnull(@canReprogram,0),
  Califout_Status=1, keepDial=isnull(@keepDial,0), autocallback=isnull(@autoCB,0), contactOwner=isnull(@contactOwner,0), 
  finishPreview=isnull(@finishPreview,0), graphColor=isnull(@graphColor, ''1DB4E2'')
  output inserted.calif_id into @inserted
  where description=@description
  select ID [result] from @inserted 
  return(0)
 end

 insert into ccTipoCalifOut (calif_id, description, orden, autoTime, CanReprogram, keepDial, autocallback, contactOwner, finishPreview, graphColor)
 output inserted.calif_id into @inserted
 select isnull(max(calif_id), 0) + 1, @description, isnull(@order,0), 0, isnull(@canReprogram,0), isnull(@keepDial,0), 
 isnull(@autoCB,0), isnull(@contactOwner,0), isnull(@finishPreview,0), isnull(@graphColor, ''1DB4E2'') from ccTipoCalifOut
 select ID [result] from @inserted 
 return(0)
end
If @command=5 -- Delete Inbound Dispositions
begin
    delete from ccCalifCamp where tipo=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    delete from cctipoSubCalifRel where tipoSubRel=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    update ccTipoCalif set Calif_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
    return(0)
end
if @command=6 -- Delete Outbound Disposition
begin
	delete from ccCalifCamp where tipo=1 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	delete from cctipoSubCalifRel where tipoSubRel=0 and calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccTipoCalifOUT set CalifOut_Status=0 where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))
	update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	return(0)
end
if @command=7 -- Update Inbound Disposition
begin
	If exists(select description from ccTipoCalif where Calif_Status=1 and description=@Description)
      set @Description=null

    UPDATE ccTipoCalif set Description=isnull(@Description, Description), orden=isnull(@order, orden),
    canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  
	EndConversation=isnull(@endConversation,EndConversation)
    where calif_id in (select value from dbo.fn_RIASplitDelimited(@califIdLst, '',''))

    delete ccCalifCamp where cam_id in (select inbound_id from ccInbound where cam_id is null) and
    tipo=0 and calif_id in (select calif_id from ccTipoCalif where CanReprogram=1)

    return(0)
end
if @command=8 -- Update Outbound Disposition
begin
	If exists(select Description from ccTipoCalifOUT where CalifOut_Status=1 and Description=@Description)
		set @Description=null

	 UPDATE ccTipoCalifOUT set Description=isnull(@Description, Description), Orden=isnull(@Order, Orden),
	 canReprogram=isnull(@canReprogram, canReprogram), GraphColor = isnull(@graphColor, GraphColor),  keepDial=isnull(@keepDial,keepDial), 
	 autocallback = isnull(@autoCB,autocallback), contactOwner = isnull(@contactOwner,contactOwner), 
	 finishPreview = isnull(@finishPreview,finishPreview)
	 where calif_id=@califIdLst

	 if @keepDial is not null
	  begin
	  update ccCamps set keepDial=dbo.fn_keepDial_Camps(cam_id)
	  end
	 return(0) 
end

set nocount off'
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
